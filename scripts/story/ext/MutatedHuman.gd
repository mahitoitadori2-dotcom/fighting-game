class_name MutatedHuman
extends ExtEnemy
## MUTATED HUMAN (AC2, the radioactive wasteland around the exploded reactor - also summoned by
## the Radioactive Chorus). A worker twisted by radiation: sickly green skin, a swollen head, one
## HUGE mutated arm, a faint green glow. Fast.
##   Radiation Punch  6 dmg   a swing of the huge arm
##   Leap Punch       7 dmg   jumps at you, arm first
##   Scream           3 dmg   screams: everyone close is hit and STUNNED for a moment

const GLOW := Color(0.45, 1.0, 0.3)
const CFG := {"head": "mutant", "skin": Color(0.55, 0.68, 0.40), "cloth": Color(0.42, 0.40, 0.25),
	"cloth_hi": Color(0.55, 0.52, 0.32), "trim": Color(0.75, 0.6, 0.15), "eye": Color(0.6, 1.0, 0.3),
	"weapon": "claw", "big_arm": true, "glow": Color(0.45, 1.0, 0.3)}

var _air := false


func _make_data() -> CharacterData:
	keep_min = 0.0
	keep_max = 150.0
	attack_chance = 0.75
	phase2_threshold = -1.0
	return SimpleEnemy.make_data("Mutated Human", 30, Vector2(60, 140), 260.0)


static func make_patterns() -> Array[EnemyPattern]:
	var list: Array[EnemyPattern] = []
	list.append(EnemyPattern.make("punch", "RADIATION PUNCH", 1.6, 6, 0.0, 110.0, "punch", 0.3, 0.15, 0.35, false, [2.0, 2.0]))
	list.append(EnemyPattern.make("leap", "LEAP PUNCH!", 3.5, 7, 120.0, 320.0, "punch", 0.4, 0.7, 0.4, true, [1.4, 1.4]))
	list.append(EnemyPattern.make("scream", "SCREAM!", 6.0, 3, 0.0, 170.0, "scream", 0.5, 0.3, 0.4, true, [1.0, 1.0]))
	list[2].note = "stuns you if you are close"
	return list


func flavor_lines() -> Array[String]:
	return ["*gurgling*", "It BURNS...", "*twitching*"]


func _attack(p: EnemyPattern) -> void:
	match p.id:
		"punch":
			melee(dmg(p), Vector2(320, -220), Vector2(56, -80), Vector2(90, 100), "radiation_punch")
			Effects.hit_sparks(self, global_position + Vector2(facing * 60.0, -80.0), 4, 0.8)
			SoundManager.play_sfx("punch", -4.0)
		"leap":
			var dx := absf(target_x() - global_position.x)
			velocity = Vector2(facing * clampf(dx * 2.0, 300.0, 620.0), -420.0)
			_air = false
			melee(dmg(p), Vector2(340, -260), Vector2(40, -70), Vector2(90, 110), "leap_punch")
		"scream":
			hit_in_radius(global_position + Vector2(0, -90), 160.0, dmg(p), Vector2(200, -160), "mutant_scream")
			stun_in_radius(global_position + Vector2(0, -90), 160.0, 0.5)
			Effects.red_burst(self, global_position + Vector2(0, -110), 90.0)
			SoundManager.play_sfx("roar", -6.0, 0.3)


func _on_attack_update(p: EnemyPattern, _delta: float) -> void:
	if p.id != "leap":
		return
	if not is_on_floor():
		_air = true
	elif _air:
		state_time = state_len


func _owns_velocity_x() -> bool:
	return estate == EState.ATTACK and current != null and current.id == "leap"


func draw_model_on(c: CanvasItem) -> void:
	ExtArt.humanoid(c, art_state(), CFG)
	if pose == "scream":
		for i in 3:
			c.draw_arc(Vector2(20, -136), 20.0 + float(i) * 18.0 + pose_t * 120.0, -0.8, 0.8, 10, Color(GLOW.r, GLOW.g, GLOW.b, maxf(0.0, 0.7 - pose_t * 2.0)), 4.0, true)


static func draw_portrait(c: CanvasItem, t: float) -> void:
	ExtArt.humanoid(c, {"t": t, "pose": "idle"}, CFG)
