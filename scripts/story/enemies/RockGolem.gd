class_name RockGolem
extends SimpleEnemy
## ROCK GOLEM (Story Mode, Colosseum 1): a living GEODE - a boulder of black rock
## cracked open over glowing crystals. Very heavy (barely knocked back).
##
##   Roll   10 dmg, 5 s - curls into a ball (rumbling telegraph) and ROLLS at you.
##                        If it crashes into a cave wall it is DIZZY for 1.4 s: punish it!
##   Pound   8 dmg, 4 s - two-fisted ground pound when you're close

const ROLL_SPEED := 760.0
const ROLL_KB := Vector2(520, -300)
const POUND_KB := Vector2(380, -260)
const DIZZY_TIME := 1.4

const ROCK := Color(0.36, 0.31, 0.30)
const ROCK_SHADE := Color(0.22, 0.19, 0.19)
const ROCK_HI := Color(0.52, 0.46, 0.44)
const GEODE := Color(0.70, 0.35, 1.0)
const GEODE_HI := Color(0.95, 0.80, 1.0)
const AMBER := Color(1.0, 0.65, 0.15)

var _hit_wall := false
var _roll_dir := 1.0
var roll_angle := 0.0


func _make_data() -> CharacterData:
	keep_min = 140.0
	keep_max = 420.0
	attack_chance = 0.55
	phase2_threshold = -1.0
	knockback_scale = 0.3
	return SimpleEnemy.make_data("Rock Golem", 60, Vector2(110, 110), 120.0)


static func make_patterns() -> Array[EnemyPattern]:
	var list: Array[EnemyPattern] = []
	#                          id      name      cd    dmg  min    max    anim     tele  active rec   big   weights   armored
	list.append(EnemyPattern.make("roll", "ROLL!", 5.0, 10, 120.0, 900.0, "roll", 0.70, 1.50, 0.60, true, [2.0, 2.0], true))
	list.append(EnemyPattern.make("pound", "POUND!", 4.0, 8, 0.0, 150.0, "pound", 0.50, 0.15, 0.60, true, [1.5, 1.5], true))
	list[0].note = "dizzy if it hits a wall"
	return list


func _on_respawn() -> void:
	super._on_respawn()
	knockback_scale = 0.3


func flavor_lines() -> Array[String]:
	return ["*RUMBLE*", "*grinding stone*"]


func _attack(p: EnemyPattern) -> void:
	match p.id:
		"roll":
			_hit_wall = false
			_roll_dir = float(facing)
			hitbox.activate(make_hit(dmg(p), Vector2(_roll_dir * ROLL_KB.x, ROLL_KB.y), "golem_roll"),
				Vector2(0, -55), Vector2(110, 100))
			SoundManager.play_sfx("dash")
		"pound":
			hit_in_radius(global_position + Vector2(facing * 60.0, -30.0), 110.0, dmg(p), POUND_KB, "golem_pound")
			Effects.shake(self, 9.0)
			Effects.hit_sparks(self, global_position + Vector2(facing * 70.0, -8), 10, 1.2)
			SoundManager.play_sfx("explosion", -6.0)


func _on_attack_update(p: EnemyPattern, delta: float) -> void:
	if p.id != "roll":
		return
	velocity.x = _roll_dir * ROLL_SPEED
	roll_angle += _roll_dir * ROLL_SPEED * delta / 50.0
	if int(state_time * 12.0) % 3 == 0:
		Effects.hit_sparks(self, global_position + Vector2(-_roll_dir * 40.0, -6.0), 1, 0.6)
	if is_on_wall() and state_time > 0.1:
		_hit_wall = true
		state_time = state_len                              # Crashed: stop
	elif not ground_ahead(60.0):
		state_time = state_len                              # Never roll into the void


func _on_attack_end(p: EnemyPattern) -> void:
	if p.id != "roll":
		return
	velocity.x = -_roll_dir * (220.0 if _hit_wall else 0.0)
	if _hit_wall:
		stun_timer = DIZZY_TIME                             # Free hits for the player
		Effects.shake(self, 12.0)
		Effects.popup(self, global_position + Vector2(0, -150), "DIZZY!", AMBER, 24)
		SoundManager.play_sfx("explosion", -3.0)


func _owns_velocity_x() -> bool:
	return estate == EState.ATTACK and current != null and current.id == "roll"


# ============================================================
# ART (facing right, origin = feet, ~120 x 120)
# ============================================================
func draw_model_on(c: CanvasItem) -> void:
	var s := art_state()
	s["roll"] = roll_angle
	draw_golem(c, s)


static func draw_portrait(c: CanvasItem, t: float) -> void:
	draw_golem(c, {"t": t, "pose": "idle"})


static func draw_golem(c: CanvasItem, s: Dictionary) -> void:
	var t: float = s.get("t", 0.0)
	var pose: String = s.get("pose", "idle")
	var pt: float = s.get("pose_t", 0.0)
	var dead: bool = s.get("dead", false)

	if pose == "roll" or (pose == "roll_tele" and pt > 0.25):
		var shake := sin(t * 60.0) * 2.0 if pose == "roll_tele" else 0.0
		_ball(c, Vector2(shake, -55), float(s.get("roll", 0.0)) + (t * 3.0 if pose == "roll_tele" else 0.0))
		return

	var bob := sin(t * 1.6) * 1.5
	# Stubby legs
	for side in [-1.0, 1.0]:
		var lp := Vector2(side * 26.0, -14)
		FighterArt.rrect(c, Rect2(lp.x - 14, lp.y - 8, 28, 22), ROCK_SHADE, ROCK_SHADE.darkened(0.3), ROCK, 6.0, 3.5)

	# Boulder body
	var body_c := Vector2(0, -62 + bob)
	var body := PackedVector2Array()
	for i in 14:
		var a := TAU * float(i) / 14.0
		body.append(body_c + Vector2(cos(a) * 54.0, sin(a) * 46.0) * (0.92 + 0.08 * sin(float(i) * 2.7)))
	c.draw_polygon(body, _grad(body, body_c))
	# Geode crack (open crystal cavity)
	var cav := PackedVector2Array([body_c + Vector2(-6, -20), body_c + Vector2(20, -26), body_c + Vector2(32, 0), body_c + Vector2(16, 22), body_c + Vector2(-8, 12)])
	c.draw_colored_polygon(cav, Color(0.15, 0.05, 0.2))
	for k in 5:
		var cp := body_c + Vector2(4 + float(k % 3) * 9.0, -14 + float(k / 3) * 16.0)
		var glow := 0.7 + 0.3 * sin(t * 3.0 + float(k))
		c.draw_colored_polygon(PackedVector2Array([cp + Vector2(-4, 6), cp + Vector2(0, -8), cp + Vector2(4, 6)]), GEODE.lerp(GEODE_HI, glow * 0.4))
	FighterArt.outline(c, cav, 3.0)
	FighterArt.outline(c, body, 5.0)
	# Cracks + amber veins
	c.draw_polyline(PackedVector2Array([body_c + Vector2(-40, -10), body_c + Vector2(-28, -4), body_c + Vector2(-30, 10)]), AMBER, 2.5, true)
	# Face: two glowing eye slits under a heavy brow
	var face := body_c + Vector2(30, -24)
	if dead:
		EnemyArt.ko_eye(c, face, 4.0, t)
	else:
		c.draw_line(face + Vector2(-8, 0), face + Vector2(2, 1), AMBER, 4.0)
		c.draw_line(face + Vector2(6, 1), face + Vector2(14, 0), AMBER, 4.0)
		c.draw_line(face + Vector2(-10, -6), face + Vector2(16, -6), EnemyArt.BLACK, 4.0)

	# Arms (fists); pound = both fists slam down in front
	for side in [-1.0, 1.0]:
		var sh := body_c + Vector2(side * 40.0, -10)
		var fist := sh + Vector2(side * 14.0 + 10.0, 40)
		if pose == "pound_tele":
			fist = body_c + Vector2(side * 16.0 + 10.0, -70)
		elif pose == "pound":
			fist = Vector2(62 + side * 14.0, -14)
		var far: bool = side < 0.0
		FighterArt.limb(c, sh, fist, 20.0, ROCK_SHADE if far else ROCK, ROCK_SHADE, ROCK_HI)
		FighterArt.ball(c, fist, 15.0, ROCK_SHADE if far else ROCK, ROCK_SHADE, ROCK_HI)
	if pose == "pound":
		c.draw_arc(Vector2(64, 0), 30.0 + pt * 200.0, PI, TAU, 18, Color(GEODE_HI.r, GEODE_HI.g, GEODE_HI.b, maxf(0.0, 1.0 - pt * 4.0)), 6.0, true)


static func _ball(c: CanvasItem, center: Vector2, angle: float) -> void:
	var pts := PackedVector2Array()
	for i in 14:
		var a := TAU * float(i) / 14.0
		pts.append(center + Vector2.from_angle(a + angle) * 52.0 * (0.93 + 0.07 * sin(float(i) * 2.7)))
	c.draw_polygon(pts, _grad(pts, center))
	for k in 4:                                                   # Crystal flashes spinning around
		var cp := center + Vector2.from_angle(angle + float(k) * TAU / 4.0) * 30.0
		c.draw_circle(cp, 6.0, GEODE)
		c.draw_circle(cp, 3.0, GEODE_HI)
	FighterArt.outline(c, pts, 5.0)
	for k in 3:                                                   # Dust behind
		c.draw_circle(center + Vector2(-60 - float(k) * 14.0, 40 - float(k) * 6.0), 10.0 - float(k) * 2.0, Color(0.5, 0.4, 0.35, 0.4))


static func _grad(pts: PackedVector2Array, center: Vector2) -> PackedColorArray:
	var cols := PackedColorArray()
	for p in pts:
		cols.append(ROCK_HI.lerp(ROCK_SHADE, clampf((p.y - center.y + 40.0) / 80.0, 0.0, 1.0)))
	return cols
