class_name TigerCub
extends ExtEnemy
## TIGER CUB (DemiLand, the Tiger Ravine). The Last Tiger's starving young - small, fast, angry.
##   Bite     4 dmg   a quick bite
##   Pounce   5 dmg   leaps at you from a distance

const CFG := {"size": 0.7, "old": true}

var _leaping := false


func _make_data() -> CharacterData:
	keep_min = 0.0
	keep_max = 80.0
	attack_chance = 0.7
	phase2_threshold = -1.0
	return SimpleEnemy.make_data("Tiger Cub", 26, Vector2(90, 70), 270.0)


static func make_patterns() -> Array[EnemyPattern]:
	var list: Array[EnemyPattern] = []
	list.append(EnemyPattern.make("bite", "BITE", 1.4, 4, 0.0, 110.0, "bite", 0.25, 0.2, 0.35, false, [2.0, 2.0]))
	list.append(EnemyPattern.make("pounce", "POUNCE", 3.5, 5, 140.0, 420.0, "pounce", 0.35, 0.55, 0.4, false, [1.5, 1.5]))
	return list


func flavor_lines() -> Array[String]:
	return ["*growls*", "*hisses*", "Rrrr...", "*sniffs*"]


func _owns_velocity_x() -> bool:
	return _leaping


func _attack(p: EnemyPattern) -> void:
	match p.id:
		"bite":
			melee(dmg(p), Vector2(200, -140), Vector2(50, -36), Vector2(80, 50), "cub_bite")
			SoundManager.play_sfx("punch", -8.0)
		"pounce":
			_leaping = true
			velocity = Vector2(float(facing) * clampf(absf(target_x() - global_position.x) * 1.6, 300.0, 640.0), -460.0)
			melee(dmg(p), Vector2(220, -200), Vector2(40, -40), Vector2(90, 70), "cub_pounce")


func _on_attack_end(p: EnemyPattern) -> void:
	if p.id == "pounce":
		_leaping = false


func draw_model_on(c: CanvasItem) -> void:
	DemiArt.beast(c, art_state(), CFG)


static func draw_portrait(c: CanvasItem, t: float) -> void:
	DemiArt.beast(c, {"t": t, "pose": "idle"}, CFG)
