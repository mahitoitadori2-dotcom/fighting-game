class_name TribeMaster
extends C5Boss
## THE TRIBE MASTER - boss of DemiLand's Tribe Village. The chieftain of the primitive people:
## a giant in a crown of black feathers and bones, a skull mask, a club made of a mammoth bone.
## Drops the BONE CROWN (one of the three artifacts for the Ancient Door).
##
##   War Club         8 dmg   a huge two-handed swing
##   Spear Volley     6 dmg   throws three spears high: they rain down around you
##   Chieftain Leap   9 dmg   leaps onto you; the landing sends shockwaves both ways
##   Totem Fire       6 dmg   fire bursts from the ground under you and beside you
##   War Cry          -       calls two hunters to fight with him
##   Drums of War     7 dmg   ENRAGED: spears burst up across the whole arena in a sweep

const CFG := {"h": 1.45, "w": 1.45, "weapon": "hammer", "metal": Color(0.88, 0.84, 0.72), "mask": true, "headdress": true,
	"teeth": true, "big_arm": true, "paint": Color(0.95, 0.85, 0.75), "eye": Color(1.0, 0.35, 0.1)}

var _air := false


func boss_forms() -> Array:
	return [{"name": "The Tribe Master", "title": "THE TRIBE MASTER   -   CHIEFTAIN OF DEMILAND", "hp": 330, "body": Vector2(100, 220), "speed": 200.0}]


func setup_boss() -> void:
	keep_min = 120.0
	keep_max = 380.0
	attack_chance = 0.72
	chain_chance = 0.35
	max_minions = 3
	tags = {"club": ["close", "counter"], "spears": ["ranged", "anti_air"], "leap": ["escape", "close"], "totems": ["ranged", "anti_air"],
		"cry": ["ranged"], "drums": ["ranged"]}
	combos = {"club": ["leap", "totems"], "leap": ["club"], "spears": ["totems"], "totems": ["club"]}


static func make_patterns() -> Array[EnemyPattern]:
	var list: Array[EnemyPattern] = []
	#                          id        name                 cd    dmg  min    max     anim    tele  active rec   big   weights armored
	list.append(EnemyPattern.make("club", "WAR CLUB!", 2.6, 8, 0.0, 260.0, "smash", 0.45, 0.30, 0.50, true, [2.0], true))
	list.append(EnemyPattern.make("spears", "SPEAR VOLLEY!", 4.5, 6, 160.0, 1200.0, "throw", 0.50, 0.30, 0.45, true, [1.5], true))
	list.append(EnemyPattern.make("leap", "CHIEFTAIN LEAP!", 5.0, 9, 140.0, 900.0, "smash", 0.50, 1.40, 0.55, true, [1.3], true))
	list.append(EnemyPattern.make("totems", "TOTEM FIRE!", 5.5, 6, 0.0, 1200.0, "cast", 0.55, 0.40, 0.45, true, [1.2], true))
	list.append(EnemyPattern.make("cry", "WAR CRY!", 12.0, 0, 0.0, 1400.0, "cast", 0.70, 0.40, 0.50, true, [0.9], true))
	list.append(EnemyPattern.make("drums", "DRUMS OF WAR!", 10.0, 7, 0.0, 1600.0, "cast", 0.75, 0.60, 0.60, true, [1.3], true))
	list[2].note = "shockwaves on landing: jump them"
	list[5].note = "enraged only"
	return list


func wants_pattern(p: EnemyPattern) -> bool:
	if p.id == "drums":
		return raging
	if p.id == "cry":
		_prune_minions()
		return minions.size() < 2
	return true


func flavor_lines() -> Array[String]:
	return ["This land is OURS.", "*beats his chest*", "Your bones for my crown.", "The tribe does not forget."]


func _attack(p: EnemyPattern) -> void:
	var tx := target_x()
	match p.id:
		"club":
			swing(dmg(p), Vector2(440, -320), Vector2(110, -120), Vector2(210, 220), "war_club")
			Effects.shake(self, 8.0)
			SoundManager.play_sfx("slam")
		"spears":
			for k in 3:
				lob("arrow", global_position + Vector2(facing * 40.0, -260.0), clamp_arena(tx + float(k - 1) * 140.0), 0.8 + 0.1 * float(k), dmg(p),
					Vector2(220, -180), 34.0, DemiArt.HIDE, "spear_volley")
			SoundManager.play_sfx("whoosh")
		"leap":
			_air = false
			leap_to(tx, 0.75, 320.0)
			SoundManager.play_sfx("jump")
			SoundManager.play_sfx("roar", -8.0)
		"totems":
			for k in 3:
				hazard("geyser", tx + float(k - 1) * 160.0, 0.55 + 0.15 * float(k), dmg(p), Vector2(200, -440))
			SoundManager.play_sfx("flame", -4.0)
		"cry":
			for k in 2:
				summon("tribe_hunter", Vector2(clamp_arena(global_position.x + float(k * 2 - 1) * 260.0), floor_y() - 260.0))
			stun_in_radius(global_position + Vector2(0, -80), 200.0, 0.4)
			Effects.shake(self, 10.0)
			SoundManager.play_sfx("roar")
		"drums":
			var from := StoryManager.arena_left() + 100.0 if global_position.x > arena_center() else StoryManager.arena_right() - 100.0
			var dir := 1.0 if from < arena_center() else -1.0
			for k in 8:
				hazard("spear", from + dir * float(k) * 170.0, 0.7 + 0.14 * float(k), dmg(p), Vector2(200, -460))
			Effects.shake(self, 14.0)
			SoundManager.play_sfx("slam")
			SoundManager.play_sfx("roar", -4.0)


func _on_attack_update(p: EnemyPattern, _delta: float) -> void:
	if p.id != "leap":
		return
	if not is_on_floor():
		_air = true
	elif _air:
		_air = false
		hit_in_radius(global_position + Vector2(0, -60), 190.0, dmg(p), Vector2(420, -400), "chieftain_leap")
		for d: float in [-1.0, 1.0]:
			shoot("shock", Vector2(global_position.x + d * 80.0, floor_y() - 20.0), d, 520.0, 1.2, Vector2(50, 44), dmg(p) - 2, Vector2(240, -320), Color(0.7, 0.5, 0.3), "leap_wave", true)
		Effects.shake(self, 16.0)
		SoundManager.play_sfx("slam")
		velocity.x = 0.0
		state_time = state_len


func _on_attack_end(p: EnemyPattern) -> void:
	if p.id == "leap":
		velocity.x = 0.0


func _owns_velocity_x() -> bool:
	return estate == EState.ATTACK and current != null and current.id == "leap"


func draw_model_on(c: CanvasItem) -> void:
	DemiArt.tribal(c, art_state(), CFG)


static func draw_portrait(c: CanvasItem, t: float) -> void:
	DemiArt.tribal(c, {"t": t, "pose": "idle"}, CFG)
