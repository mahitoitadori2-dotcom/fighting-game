class_name TribeShaman
extends ExtEnemy
## TRIBE SHAMAN (DemiLand). An old witch-doctor with a bone mask, a feather staff and a drum.
## Stays back, curses you and keeps the tribe fighting.
##   Curse Fire   5 dmg   a ball of dark fire
##   Bone Rain    4 dmg   throws a handful of bones that rain down around you
##   War Drum     heal    heals every tribesman nearby - kill him first!

const CFG := {"weapon": "staff", "magic": Color(0.75, 0.25, 0.95), "mask": true, "feathers": 4, "robe": true,
	"cloth": Color(0.30, 0.22, 0.16), "cloth_hi": Color(0.42, 0.32, 0.22), "trim": Color(0.6, 0.15, 0.1), "eye": Color(0.8, 0.4, 1.0)}
const HEAL := 9


func _make_data() -> CharacterData:
	keep_min = 280.0
	keep_max = 560.0
	attack_chance = 0.55
	phase2_threshold = -1.0
	return SimpleEnemy.make_data("Tribe Shaman", 30, Vector2(56, 140), 140.0)


static func make_patterns() -> Array[EnemyPattern]:
	var list: Array[EnemyPattern] = []
	list.append(EnemyPattern.make("curse", "CURSE FIRE", 2.8, 5, 150.0, 900.0, "cast", 0.45, 0.2, 0.45, false, [2.0, 2.0]))
	list.append(EnemyPattern.make("bones", "BONE RAIN", 5.0, 4, 0.0, 900.0, "cast", 0.55, 0.2, 0.5, true, [1.3, 1.3]))
	list.append(EnemyPattern.make("drum", "WAR DRUM!", 8.0, 0, 0.0, 2000.0, "cast", 0.7, 0.3, 0.5, true, [1.2, 1.2]))
	list[2].note = "heals the tribe %d HP: kill him first" % HEAL
	return list


func wants_pattern(p: EnemyPattern) -> bool:
	if p.id != "drum":
		return true
	for a in _allies():
		if (a as Fighter).hp < (a as Fighter).data.max_hp:
			return true
	return false


func _allies() -> Array:
	var out: Array = []
	for n in get_tree().get_nodes_in_group("fighters"):
		var f := n as BaseEnemy
		if f != null and f != self and not f.is_dead and CombatManager.are_allies(self, f) and f.global_position.distance_to(global_position) < 600.0:
			out.append(f)
	return out


func flavor_lines() -> Array[String]:
	return ["*mutters to the dead trees*", "The ancestors are hungry.", "*shakes a rattle*", "Your bones will sing."]


func _attack(p: EnemyPattern) -> void:
	match p.id:
		"curse":
			shot("fireball", Vector2(30, -130), 400.0, 2.2, Vector2(30, 30), dmg(p), Vector2(200, -160), Color(0.65, 0.2, 0.95), "curse_fire")
			SoundManager.play_sfx("whoosh", -8.0)
		"bones":
			var tx := target_x()
			for k in 4:
				lob("debris", Vector2(10, -150), clamp_to_ground(tx + (float(k) - 1.5) * 90.0, 40.0), 0.75 + 0.08 * float(k), dmg(p),
					Vector2(160, -200), 32.0, DemiArt.BONE, "bone_rain")
		"drum":
			var healed := 0
			for a in _allies():
				var f := a as Fighter
				healed += f.heal(HEAL)
				Effects.gold_burst(f, f.global_position + Vector2(0, -60), 40.0)
			SoundManager.play_sfx("slam", -10.0)
			if healed > 0:
				Effects.popup(self, global_position + Vector2(0, -190), "WAR DRUM!", Color(0.8, 0.4, 1.0), 20)


func draw_model_on(c: CanvasItem) -> void:
	_draw_shaman(c, art_state())


static func draw_portrait(c: CanvasItem, t: float) -> void:
	_draw_shaman(c, {"t": t, "pose": "idle"})


static func _draw_shaman(c: CanvasItem, s: Dictionary) -> void:
	DemiArt.tribal(c, s, CFG)
	var t: float = s.get("t", 0.0)
	var drum := Vector2(-22, -72)                            # The drum on his hip
	var d := EnemyArt.ellipse_points(drum, 14.0, 18.0, 14)
	c.draw_colored_polygon(d, DemiArt.HIDE)
	c.draw_colored_polygon(EnemyArt.ellipse_points(drum + Vector2(4, 0), 8.0, 14.0, 12), DemiArt.BONE)
	FighterArt.outline(c, d, 3.0)
	if String(s.get("pose", "")).begins_with("cast"):
		c.draw_circle(Vector2(40, -150), 14.0 + 4.0 * sin(t * 10.0), Color(0.65, 0.2, 0.95, 0.3))
