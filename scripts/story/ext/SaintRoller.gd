class_name SaintRoller
extends ExtEnemy
## SAINT ROLLER (AG2 / AG3, the Saint Rocks sanctuary). A holy boulder with glowing runes that
## ROLLS at you.
##   Rock Roll   6 dmg   rolls fast across the floor at you
##   Bump        4 dmg   a short hop when you are close

const CFG := {"rock": Color(0.70, 0.66, 0.58), "crack": Color(1.0, 0.85, 0.4), "size": 1.0}
var _spin := 0.0


func _make_data() -> CharacterData:
	keep_min = 120.0
	keep_max = 420.0
	attack_chance = 0.7
	phase2_threshold = -1.0
	return SimpleEnemy.make_data("Saint Roller", 26, Vector2(60, 60), 150.0)


static func make_patterns() -> Array[EnemyPattern]:
	var list: Array[EnemyPattern] = []
	list.append(EnemyPattern.make("roll", "ROCK ROLL!", 3.2, 6, 100.0, 650.0, "roll", 0.5, 1.0, 0.45, true, [2.0, 2.0]))
	list.append(EnemyPattern.make("bump", "BUMP", 1.6, 4, 0.0, 90.0, "bump", 0.2, 0.25, 0.35, false, [1.5, 1.5]))
	return list


func _attack(p: EnemyPattern) -> void:
	match p.id:
		"roll":
			melee(dmg(p), Vector2(340, -260), Vector2(10, -30), Vector2(70, 62), "saint_roll")
			SoundManager.play_sfx("stone", -4.0)
		"bump":
			velocity = Vector2(facing * 220.0, -320.0)
			melee(dmg(p), Vector2(220, -180), Vector2(20, -30), Vector2(70, 60), "saint_bump")


func _on_attack_update(p: EnemyPattern, delta: float) -> void:
	if p.id == "roll":
		dash_step(640.0)
		_spin += facing * delta * 14.0


func _owns_velocity_x() -> bool:
	return estate == EState.ATTACK and current != null and current.id == "roll"


func _update_visuals(delta: float) -> void:
	_spin += velocity.x * delta * 0.03
	super._update_visuals(delta)


func draw_model_on(c: CanvasItem) -> void:
	var cfg := CFG.duplicate()
	cfg["spin"] = _spin * float(facing)
	ExtArt.rock_ball(c, art_state(), cfg)


static func draw_portrait(c: CanvasItem, t: float) -> void:
	ExtArt.rock_ball(c, {"t": t, "pose": "idle"}, CFG)
