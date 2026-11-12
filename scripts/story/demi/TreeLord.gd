class_name TreeLord
extends C5Boss
## THE LIVING TREE LORD - boss of DemiLand's Dead Grove. Every tree in DemiLand is dead...
## except this one. It first stands as THE DEAD TREE LORD; break it and it wakes up, glowing
## green, as THE LIVING TREE LORD. Drops the LIVING HEART (one of the three artifacts).
##
##   Branch Sweep   8 dmg   a huge sweep of its branches
##   Root Spikes    6 dmg   roots burst out of the ground in a line toward you
##   Uproot Slam    7 dmg   slams its roots down: shockwaves both ways
##   Seed Rain      5 dmg   hard seeds rain down around you
##   Saplings       -       wakes up two Rot Saplings (living form)
##   Thorn Storm    6 dmg   ENRAGED (living form): thorns burst across the whole arena

const DEAD_CFG := {"h": 1.9, "branches": 4, "eye": Color(1.0, 0.6, 0.25)}
const LIVE_CFG := {"h": 2.1, "branches": 5, "glow": Color(0.45, 1.0, 0.35, 1.0), "eye": Color(0.6, 1.0, 0.4),
	"bark": Color(0.26, 0.20, 0.14)}


func boss_forms() -> Array:
	return [
		{"name": "The Dead Tree Lord", "title": "THE DEAD TREE LORD", "hp": 240, "body": Vector2(150, 280), "speed": 80.0},
		{"name": "The LIVING Tree Lord", "title": "THE LIVING TREE LORD", "hp": 300, "body": Vector2(160, 310), "speed": 110.0,
			"banner": "IT IS ALIVE", "subtitle": "The last living tree in DemiLand", "line": "...you... broke... my... SLEEP."},
	]


func setup_boss() -> void:
	keep_min = 0.0
	keep_max = 320.0
	attack_chance = 0.72
	chain_chance = 0.3
	max_minions = 3
	knockback_scale = 0.1
	tags = {"sweep": ["close", "counter"], "roots": ["ranged", "anti_air"], "slam": ["close", "counter"], "seeds": ["ranged", "anti_air"],
		"saplings": ["ranged"], "thorns": ["ranged"]}
	combos = {"sweep": ["slam", "roots"], "roots": ["seeds"], "slam": ["roots"], "seeds": ["sweep"]}


static func make_patterns() -> Array[EnemyPattern]:
	var list: Array[EnemyPattern] = []
	#                          id         name              cd    dmg  min    max     anim     tele  active rec   big   weights      armored
	list.append(EnemyPattern.make("sweep", "BRANCH SWEEP!", 2.6, 8, 0.0, 320.0, "sweep", 0.55, 0.30, 0.55, true, [2.0, 2.0], true))
	list.append(EnemyPattern.make("roots", "ROOT SPIKES!", 4.5, 6, 120.0, 1300.0, "slam", 0.55, 0.40, 0.50, true, [1.6, 1.6], true))
	list.append(EnemyPattern.make("slam", "UPROOT SLAM!", 5.0, 7, 0.0, 420.0, "slam", 0.65, 0.30, 0.60, true, [1.2, 1.4], true))
	list.append(EnemyPattern.make("seeds", "SEED RAIN!", 5.5, 5, 0.0, 1300.0, "cast", 0.55, 0.30, 0.50, true, [1.0, 1.3], true))
	list.append(EnemyPattern.make("saplings", "WAKE, MY SAPLINGS!", 12.0, 0, 0.0, 1400.0, "cast", 0.70, 0.40, 0.50, true, [0.0, 1.0], true))
	list.append(EnemyPattern.make("thorns", "THORN STORM!", 10.0, 6, 0.0, 1600.0, "slam", 0.75, 0.60, 0.65, true, [0.0, 1.3], true))
	list[1].note = "roots burst in a line toward you"
	list[4].note = "living form only"
	list[5].note = "living form, enraged only"
	return list


func wants_pattern(p: EnemyPattern) -> bool:
	if p.id == "thorns":
		return raging and form == 2
	if p.id == "saplings":
		_prune_minions()
		return form == 2 and minions.size() < 2
	return true


func on_form_changed(_new_form: int) -> void:
	Effects.gold_burst(self, global_position + Vector2(0, -200), 220.0)
	SoundManager.play_sfx("roar")


func flavor_lines() -> Array[String]:
	if form == 2:
		return ["*leaves grow where there were none*", "...alive... I am... ALIVE...", "*the whole grove groans*"]
	return ["*creak*", "...", "*dry bark cracks*"]


func _attack(p: EnemyPattern) -> void:
	var tx := target_x()
	match p.id:
		"sweep":
			swing(dmg(p), Vector2(460, -300), Vector2(150, -150), Vector2(280, 220), "branch_sweep")
			Effects.shake(self, 8.0)
			SoundManager.play_sfx("whoosh")
		"roots":
			var d := signf(tx - global_position.x) if tx != global_position.x else float(facing)
			for k in 5:
				hazard("tendril", global_position.x + d * (160.0 + float(k) * 150.0), 0.45 + 0.13 * float(k), dmg(p), Vector2(180, -420))
			SoundManager.play_sfx("rumble")
		"slam":
			for d: float in [-1.0, 1.0]:
				shoot("shock", Vector2(global_position.x + d * 110.0, floor_y() - 20.0), d, 480.0, 1.3, Vector2(54, 50), dmg(p), Vector2(260, -320), Color(0.45, 0.35, 0.2), "uproot_wave", true)
			hit_in_radius(global_position + Vector2(0, -60), 170.0, dmg(p), Vector2(380, -380), "uproot_slam")
			Effects.shake(self, 16.0)
			SoundManager.play_sfx("slam")
		"seeds":
			for k in 5:
				lob("light_orb", global_position + Vector2(0, -330), clamp_arena(tx + (float(k) - 2.0) * 120.0), 0.7 + 0.08 * float(k), dmg(p),
					Vector2(180, -200), 34.0, Color(0.45, 0.35, 0.15), "seed_rain")
			SoundManager.play_sfx("whoosh", -4.0)
		"saplings":
			for k in 2:
				summon("sapling", Vector2(clamp_arena(global_position.x + float(k * 2 - 1) * 220.0), floor_y() - 60.0))
			SoundManager.play_sfx("spawn")
		"thorns":
			var l := StoryManager.wall_left_x + 80.0
			var r := StoryManager.wall_right_x - 80.0
			for k in 9:
				hazard("spear", lerpf(l, r, float(k) / 8.0), 0.6 + (0.45 if k % 2 == 1 else 0.0), dmg(p), Vector2(200, -460))
			Effects.shake(self, 14.0)
			SoundManager.play_sfx("rumble")


func draw_model_on(c: CanvasItem) -> void:
	DemiArt.treant(c, art_state(), LIVE_CFG if form == 2 else DEAD_CFG)


static func draw_portrait(c: CanvasItem, t: float) -> void:
	DemiArt.treant(c, {"t": t, "pose": "idle"}, LIVE_CFG)
