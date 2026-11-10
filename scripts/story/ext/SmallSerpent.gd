class_name SmallSerpent
extends ExtEnemy
## SMALL SERPENT (BC3, the Caeser's crypts - and spat out by the Caeser's Grave). A fast little
## snake that comes in swarms.
##   Bite    3 dmg   snaps when close
##   Strike  4 dmg   springs at you from a distance

const CFG := {"skin": Color(0.42, 0.50, 0.20), "belly": Color(0.85, 0.75, 0.40), "size": 1.0}
var _air := false


func _make_data() -> CharacterData:
	keep_min = 0.0
	keep_max = 200.0
	attack_chance = 0.75
	phase2_threshold = -1.0
	var d := SimpleEnemy.make_data("Small Serpent", 10, Vector2(60, 28), 300.0)
	d.respawn_delay = 1.0
	return d


static func make_patterns() -> Array[EnemyPattern]:
	var list: Array[EnemyPattern] = []
	list.append(EnemyPattern.make("bite", "BITE", 1.2, 3, 0.0, 70.0, "bite", 0.12, 0.12, 0.3, false, [1.6, 1.6]))
	list.append(EnemyPattern.make("strike", "STRIKE", 2.4, 4, 70.0, 250.0, "bite", 0.35, 0.6, 0.45, false, [2.0, 2.0]))
	return list


func _attack(p: EnemyPattern) -> void:
	match p.id:
		"bite":
			melee(dmg(p), Vector2(150, -80), Vector2(34, -14), Vector2(44, 30), "serpent_bite")
			SoundManager.play_sfx("bite", -8.0)
		"strike":
			var dx := absf(target_x() - global_position.x)
			velocity = Vector2(facing * clampf(dx * 2.3, 320.0, 640.0), -280.0)
			_air = false
			melee(dmg(p), Vector2(220, -140), Vector2(18, -16), Vector2(60, 32), "serpent_strike")


func _on_attack_update(p: EnemyPattern, _delta: float) -> void:
	if p.id != "strike":
		return
	if not is_on_floor():
		_air = true
	elif _air:
		state_time = state_len


func _owns_velocity_x() -> bool:
	return estate == EState.ATTACK and current != null and current.id == "strike"


func draw_model_on(c: CanvasItem) -> void:
	ExtArt.serpent(c, art_state(), CFG)


static func draw_portrait(c: CanvasItem, t: float) -> void:
	ExtArt.serpent(c, {"t": t, "pose": "idle"}, CFG)
