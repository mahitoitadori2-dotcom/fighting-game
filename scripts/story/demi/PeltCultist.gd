class_name PeltCultist
extends ExtEnemy
## PELT CULTIST (DemiLand, the Tiger Ravine). A primitive who worships the Last Tiger and wears
## the skin of its dead mate. Throws bone darts, then leaps in with stone claws.
##   Bone Darts   4 dmg   two bone darts, one high one low
##   Leap Slash   6 dmg   jumps at you and slashes

const CFG := {"weapon": "claw", "pelt": true, "teeth": true, "paint": Color(0.95, 0.85, 0.75), "eye": Color(1.0, 0.8, 0.2)}

var _leaping := false


func _make_data() -> CharacterData:
	keep_min = 160.0
	keep_max = 420.0
	attack_chance = 0.6
	phase2_threshold = -1.0
	return SimpleEnemy.make_data("Pelt Cultist", 38, Vector2(56, 140), 210.0)


static func make_patterns() -> Array[EnemyPattern]:
	var list: Array[EnemyPattern] = []
	list.append(EnemyPattern.make("darts", "BONE DARTS", 2.8, 4, 160.0, 800.0, "throw", 0.40, 0.25, 0.4, false, [2.0, 2.0]))
	list.append(EnemyPattern.make("leap", "LEAP SLASH!", 4.5, 6, 120.0, 460.0, "slash", 0.45, 0.6, 0.45, true, [1.4, 1.4]))
	return list


func flavor_lines() -> Array[String]:
	return ["The Tiger sees you.", "*purrs, badly*", "Its skin keeps me warm.", "The LAST one. Ours."]


func _owns_velocity_x() -> bool:
	return _leaping


func _attack(p: EnemyPattern) -> void:
	match p.id:
		"darts":
			shot("needle", Vector2(30, -120), 560.0, 1.6, Vector2(40, 10), dmg(p), Vector2(180, -120), DemiArt.BONE, "bone_dart")
			shot("needle", Vector2(30, -40), 520.0, 1.6, Vector2(40, 10), dmg(p), Vector2(180, -120), DemiArt.BONE, "bone_dart")
			SoundManager.play_sfx("whoosh", -8.0)
		"leap":
			_leaping = true
			velocity = Vector2(float(facing) * clampf(absf(target_x() - global_position.x) * 1.5, 260.0, 620.0), -520.0)
			melee(dmg(p), Vector2(280, -220), Vector2(50, -80), Vector2(100, 120), "leap_slash")


func _on_attack_end(p: EnemyPattern) -> void:
	if p.id == "leap":
		_leaping = false


func draw_model_on(c: CanvasItem) -> void:
	DemiArt.tribal(c, art_state(), CFG)


static func draw_portrait(c: CanvasItem, t: float) -> void:
	DemiArt.tribal(c, {"t": t, "pose": "idle"}, CFG)
