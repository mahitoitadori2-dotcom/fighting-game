class_name RotStray
extends SimpleEnemy
## ROT STRAY (Story Mode, Colosseum 2 - the Sewers): a rotting stray dog. Patchy fur,
## bare ribs, a torn ear and sick green eyes. FAST: circles you, then LUNGES and bites.
##
##   Lunge   5 dmg, 2.2 s - crouches (telegraph), then leaps at you jaws first
##   Bite    3 dmg, 1.1 s - quick snap when already close

const LUNGE_SPEED := Vector2(700, -330)
const LUNGE_KB := Vector2(280, -170)
const BITE_KB := Vector2(170, -90)

const FUR := Color(0.40, 0.34, 0.24)
const FUR_SHADE := Color(0.24, 0.20, 0.14)
const FUR_HI := Color(0.55, 0.48, 0.34)
const ROT := Color(0.45, 0.55, 0.22)
const FLESH := Color(0.62, 0.22, 0.22)
const BONE := Color(0.92, 0.88, 0.74)
const EYE := Color(0.6, 1.0, 0.3)

var _air := false


func _make_data() -> CharacterData:
	keep_min = 60.0
	keep_max = 240.0
	attack_chance = 0.75
	phase2_threshold = -1.0                      # Grunts don't enrage
	var d := SimpleEnemy.make_data("Rot Stray", 14, Vector2(78, 50), 330.0)
	d.respawn_delay = 1.2
	return d


static func make_patterns() -> Array[EnemyPattern]:
	var list: Array[EnemyPattern] = []
	#                          id       name      cd    dmg  min    max    anim     tele  active rec   big    weights
	list.append(EnemyPattern.make("lunge", "LUNGE!", 2.2, 5, 80.0, 320.0, "lunge", 0.35, 0.60, 0.50, false, [2.0, 2.0]))
	list.append(EnemyPattern.make("bite", "BITE", 1.1, 3, 0.0, 80.0, "bite", 0.12, 0.12, 0.30, false, [1.5, 1.5]))
	return list


func flavor_lines() -> Array[String]:
	return ["*growl*", "*snarl*", "*wet cough*"]


func _attack(p: EnemyPattern) -> void:
	match p.id:
		"lunge":
			var dx := absf(target_x() - global_position.x)
			velocity = Vector2(facing * clampf(dx * 2.3, 340.0, LUNGE_SPEED.x), LUNGE_SPEED.y)
			_air = false
			hitbox.activate(make_hit(dmg(p), Vector2(facing * LUNGE_KB.x, LUNGE_KB.y), "stray_lunge"),
				Vector2(facing * 26.0, -30.0), Vector2(74, 46))
			SoundManager.play_sfx("bark", -4.0)
		"bite":
			hitbox.activate(make_hit(dmg(p), Vector2(facing * BITE_KB.x, BITE_KB.y), "stray_bite"),
				Vector2(facing * 46.0, -30.0), Vector2(46, 36))
			SoundManager.play_sfx("bite", -6.0)


func _on_attack_update(p: EnemyPattern, _delta: float) -> void:
	if p.id != "lunge":
		return
	if not is_on_floor():
		_air = true
	elif _air:
		state_time = state_len                        # Landed: lunge over


func _owns_velocity_x() -> bool:
	return estate == EState.ATTACK and current != null and current.id == "lunge"


# ============================================================
# ART (facing right, origin = feet, ~90 x 60)
# ============================================================
func draw_model_on(c: CanvasItem) -> void:
	draw_stray(c, art_state())


static func draw_portrait(c: CanvasItem, t: float) -> void:
	draw_stray(c, {"t": t, "pose": "idle"})


static func draw_stray(c: CanvasItem, s: Dictionary) -> void:
	var t: float = s.get("t", 0.0)
	var pose: String = s.get("pose", "idle")
	var dead: bool = s.get("dead", false)
	var moving: bool = s.get("moving", false)
	var ph: float = s.get("walk", 0.0) * 1.6
	var crouch := 8.0 if pose == "lunge_tele" else 0.0
	var leap := pose == "lunge"
	var body_y := -34.0 + crouch + sin(t * 3.0) * 1.0

	# Legs: 4 thin legs (far ones darker), trot when moving, stretched when leaping
	var hips := [Vector2(-24, body_y + 6), Vector2(22, body_y + 6)]
	for i in 4:
		var far := i < 2
		var hip: Vector2 = hips[i % 2] + Vector2(-4 if far else 0, 0)
		var swing := sin(ph + (PI if (i % 2 == 0) != far else 0.0)) * (10.0 if moving else 0.0)
		var foot := Vector2(hip.x + swing, -2.0)
		if leap:
			foot = hip + Vector2(-26.0 if i % 2 == 0 else 26.0, 16.0)
		var knee := hip.lerp(foot, 0.5) + Vector2(-5 if i % 2 == 0 else 5, 0)
		var col := FUR_SHADE if far else FUR
		FighterArt.limb(c, hip, knee, 6.0, col, FUR_SHADE, FUR_HI)
		FighterArt.limb(c, knee, foot, 5.0, col, FUR_SHADE, FUR_HI)
		c.draw_circle(foot, 3.5, FUR_SHADE.darkened(0.3))

	# Tail (ragged, half bald)
	var tail_base := Vector2(-34, body_y - 4)
	var tail := PackedVector2Array([tail_base, tail_base + Vector2(-14, -10 + sin(t * 9.0) * 6.0), tail_base + Vector2(-24, -6 + sin(t * 9.0 + 1.0) * 8.0)])
	c.draw_polyline(tail, EnemyArt.BLACK, 7.0, FighterArt.AA)
	c.draw_polyline(tail, FUR_SHADE, 4.0, FighterArt.AA)

	# Body: lean barrel with patches of rot and BARE RIBS
	var body := EnemyArt.ellipse_points(Vector2(-4, body_y - 4), 36.0, 15.0, 20)
	c.draw_colored_polygon(body, FUR)
	c.draw_colored_polygon(EnemyArt.ellipse_points(Vector2(-4, body_y - 10), 30.0, 7.0, 14), FUR_HI)
	c.draw_colored_polygon(EnemyArt.ellipse_points(Vector2(4, body_y - 1), 13.0, 9.0, 12), FLESH)      # Open rot wound
	for k in 4:                                                                                        # Ribs
		var rx := -4.0 + float(k) * 5.0
		c.draw_arc(Vector2(rx, body_y - 6.0), 7.0, 0.3, 2.6, 8, BONE, 2.5)
	c.draw_colored_polygon(EnemyArt.ellipse_points(Vector2(-22, body_y - 6), 8.0, 5.0, 10), ROT)
	FighterArt.outline(c, body, 3.5)

	# Head: long snout, torn ear, drooling jaw
	var head := Vector2(34, body_y - 14 + (6.0 if leap else 0.0))
	var neck := PackedVector2Array([Vector2(18, body_y - 12), head + Vector2(-6, -10), head + Vector2(-2, 8), Vector2(22, body_y + 4)])
	c.draw_colored_polygon(neck, FUR)
	FighterArt.ball(c, head, 13.0, FUR, FUR_SHADE, FUR_HI)
	var open := 0.0
	if pose == "lunge" or pose == "bite":
		open = 1.0
	elif pose == "lunge_tele" or pose == "bite_tele":
		open = 0.4
	var upper := PackedVector2Array([head + Vector2(4, -6), head + Vector2(30, -2 - open * 6.0), head + Vector2(30, 3 - open * 4.0), head + Vector2(6, 4)])
	var lower := PackedVector2Array([head + Vector2(4, 5), head + Vector2(26, 6 + open * 9.0), head + Vector2(24, 11 + open * 9.0), head + Vector2(4, 11)])
	c.draw_colored_polygon(lower, FUR_SHADE)
	FighterArt.outline(c, lower, 2.5)
	c.draw_colored_polygon(upper, FUR)
	FighterArt.outline(c, upper, 2.5)
	for k in 3:                                                                       # Teeth
		var tx := 12.0 + float(k) * 6.0
		c.draw_colored_polygon(PackedVector2Array([head + Vector2(tx, 3 - open * 2.0), head + Vector2(tx + 3, 3 - open * 2.0), head + Vector2(tx + 1.5, 8 - open * 1.0)]), BONE)
	c.draw_circle(head + Vector2(30, -1 - open * 4.0), 3.0, EnemyArt.BLACK)          # Nose
	if open > 0.5 or fmod(t, 2.0) < 1.0:                                              # Drool
		c.draw_line(head + Vector2(18, 10 + open * 9.0), head + Vector2(18, 18 + open * 9.0 + sin(t * 5.0) * 2.0), Color(0.7, 0.9, 0.5, 0.8), 2.0)
	# Torn ear
	c.draw_colored_polygon(PackedVector2Array([head + Vector2(-8, -8), head + Vector2(-4, -26), head + Vector2(0, -18), head + Vector2(2, -9)]), FUR_SHADE)
	# Sick green eye
	if dead:
		EnemyArt.ko_eye(c, head + Vector2(6, -4), 3.0, t)
	else:
		c.draw_circle(head + Vector2(6, -4), 4.5, Color(EYE.r, EYE.g, EYE.b, 0.3))
		c.draw_circle(head + Vector2(6, -4), 2.6, EYE)
	if leap:                                                                          # Speed streaks
		for i in 3:
			c.draw_line(Vector2(-46 - float(i) * 6.0, body_y - 14 + float(i) * 9.0), Vector2(-70 - float(i) * 6.0, body_y - 14 + float(i) * 9.0), Color(1, 1, 1, 0.55), 3.0)
