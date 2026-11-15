class_name FullKharleming
extends ExtEnemy
## FULL KHARLEMING (Terra Craterum): a fully grown Kharleming - much bigger, ten legs.
## Its corpse can be DRAGGED (Terra Craterum: the Basalt Wall needs a pile of them).
##   Bite     4 dmg   a hard snap of its mandibles
##   Pounce   6 dmg   leaps onto you

const POUNCE_SPEED := 600.0

var _air := false


func _make_data() -> CharacterData:
	keep_min = 0.0
	keep_max = 120.0
	attack_chance = 0.6
	phase2_threshold = -1.0
	var d := SimpleEnemy.make_data("Full Kharleming", 32, Vector2(90, 62), 270.0)
	d.acceleration = 3000.0
	return d


static func make_patterns() -> Array[EnemyPattern]:
	var list: Array[EnemyPattern] = []
	list.append(EnemyPattern.make("bite", "BITE", 1.4, 4, 0.0, 100.0, "bite", 0.18, 0.15, 0.35, false, [1.6, 1.6]))
	list.append(EnemyPattern.make("pounce", "POUNCE!", 3.6, 6, 120.0, 520.0, "pounce", 0.4, 0.7, 0.45, false, [1.4, 1.4]))
	return list


func flavor_lines() -> Array[String]:
	return ["*CLICK-CLICK-CLICK*", "*bzzzt*", "*ten legs drum the rock*"]


func _attack(p: EnemyPattern) -> void:
	match p.id:
		"bite":
			melee(dmg(p), Vector2(180, -100), Vector2(52, -34), Vector2(70, 46), "full_kharleming_bite")
		"pounce":
			var to := target_x() - global_position.x
			facing = 1 if to >= 0.0 else -1
			velocity = Vector2(clampf(to * 1.6, -POUNCE_SPEED, POUNCE_SPEED), -460.0)
			_air = false
			melee(dmg(p), Vector2(260, -180), Vector2(0, -30), Vector2(96, 60), "full_kharleming_pounce")
			SoundManager.play_sfx("jump", -8.0)


func _on_attack_update(p: EnemyPattern, _delta: float) -> void:
	if p.id != "pounce":
		return
	if not is_on_floor():
		_air = true
	elif _air:
		state_time = state_len


func _owns_velocity_x() -> bool:
	return estate == EState.ATTACK and current != null and current.id == "pounce"


func draw_model_on(c: CanvasItem) -> void:
	CraterArt.kharleming(c, art_state(), false)


static func draw_portrait(c: CanvasItem, t: float) -> void:
	CraterArt.kharleming(c, {"t": t, "pose": "idle"}, false)
