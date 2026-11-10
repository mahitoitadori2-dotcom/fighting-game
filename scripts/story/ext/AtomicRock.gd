class_name AtomicRock
extends ExtEnemy
## ATOMIC ROCK (AC3, the radioactive wasteland). A living chunk of the reactor, glowing green
## through its cracks. It rolls, pulses radiation - and EXPLODES when it dies.
##   Roll              5 dmg   rolls at you
##   Radiation Burst   4 dmg   a green pulse around it
##   On death:         6 dmg   ATOMIC EXPLOSION around it + a radioactive puddle (get away!)

const GLOW := Color(0.45, 1.0, 0.3)
const CFG := {"rock": Color(0.30, 0.34, 0.28), "crack": Color(0.45, 1.0, 0.3), "size": 0.95, "glow": Color(0.45, 1.0, 0.3)}
const BLAST_R := 140.0
const BLAST_DMG := 6

var _spin := 0.0
var _boomed := false


func _make_data() -> CharacterData:
	keep_min = 60.0
	keep_max = 380.0
	attack_chance = 0.65
	phase2_threshold = -1.0
	return SimpleEnemy.make_data("Atomic Rock", 24, Vector2(58, 58), 140.0)


static func make_patterns() -> Array[EnemyPattern]:
	var list: Array[EnemyPattern] = []
	list.append(EnemyPattern.make("roll", "ROLL", 3.0, 5, 90.0, 600.0, "roll", 0.45, 0.9, 0.45, false, [2.0, 2.0]))
	list.append(EnemyPattern.make("burst", "RADIATION BURST!", 4.5, 4, 0.0, 130.0, "burst", 0.55, 0.2, 0.4, true, [1.4, 1.4]))
	list[1].note = "explodes when it dies (6 dmg around it)"
	return list


func _attack(p: EnemyPattern) -> void:
	match p.id:
		"roll":
			melee(dmg(p), Vector2(300, -240), Vector2(10, -30), Vector2(66, 60), "atomic_roll")
			SoundManager.play_sfx("stone", -4.0)
		"burst":
			hit_in_radius(global_position + Vector2(0, -30), 130.0, dmg(p), Vector2(240, -220), "radiation_burst")
			Effects.explosion(self, global_position + Vector2(0, -30), 110.0, false, false)
			SoundManager.play_sfx("spark", -4.0)


func _on_attack_update(p: EnemyPattern, delta: float) -> void:
	if p.id == "roll":
		dash_step(560.0)
		_spin += facing * delta * 12.0


func _owns_velocity_x() -> bool:
	return estate == EState.ATTACK and current != null and current.id == "roll"


func _on_death() -> void:
	super._on_death()
	if _boomed or not is_inside_tree():
		return
	_boomed = true
	# ATOMIC EXPLOSION when it dies
	var h := BLAST_DMG
	hit_in_radius(global_position + Vector2(0, -30), BLAST_R, h, Vector2(380, -360), "atomic_explosion", HitData.KIND_EXPLOSION)
	Effects.explosion(self, global_position + Vector2(0, -30), BLAST_R, true, false)
	Effects.shake(self, 10.0)
	SoundManager.play_sfx("explosion", -2.0)
	pool_at(global_position.x, 120.0, 3.5, "poison")


func _update_visuals(delta: float) -> void:
	_spin += velocity.x * delta * 0.03
	super._update_visuals(delta)


func draw_model_on(c: CanvasItem) -> void:
	var cfg := CFG.duplicate()
	cfg["spin"] = _spin * float(facing)
	ExtArt.rock_ball(c, art_state(), cfg)
	if pose == "burst_tele":
		c.draw_circle(Vector2(0, -30), 30.0 + 60.0 * clampf(pose_t / 0.55, 0.0, 1.0), Color(GLOW.r, GLOW.g, GLOW.b, 0.25))


static func draw_portrait(c: CanvasItem, t: float) -> void:
	ExtArt.rock_ball(c, {"t": t, "pose": "idle"}, CFG)
