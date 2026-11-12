class_name Geyron
extends FightBoss
## GEYRON - Fights-mode boss. A huge WHITE DRAGON soaked in BLOOD: white scales with
## blood stains and drips, torn white wings, bone horns, red eyes, and a tail that ends
## in a long BLADE OF LIGHT. He does not talk: he ROARS (intro, rage, death).
##
##   Light Sword Slash   7 dmg  sweeps his light-blade tail in front of him
##   Holy Beam           9 dmg  breathes a long beam of holy light
##   Wing Dash           8 dmg  armored wing-powered dash + a wind slash at the end
##   Judgment Spears     7 dmg  spears of light fall from the sky around you
##   Angel Flurry      4 x5     rapid claw + tail-blade combo
## Phase 2 (< 50% HP): faster, more spears.

const HP := 190
const PORTRAIT_H := 260.0                  # Art height for Character Select cards
const BEAM_LEN := 620.0
const BEAM_Y := -118.0
const DASH_SPEED := 1000.0
const SLASH_KB := Vector2(360, -260)
const BEAM_KB := Vector2(300, -160)
const DASH_KB := Vector2(560, -300)
const FLURRY_KB := Vector2(140, -100)

const SCALE := Color(0.96, 0.95, 0.93)
const SCALE_SHADE := Color(0.74, 0.72, 0.74)
const BELLY := Color(0.90, 0.86, 0.78)
const BLOOD := Color(0.70, 0.02, 0.04)
const BLOOD_DARK := Color(0.40, 0.0, 0.02)
const HORN := Color(0.88, 0.84, 0.70)
const WING_SKIN := Color(0.92, 0.88, 0.88)
const LIGHT := Color(1.0, 0.95, 0.75)
const EYE := Color(1.0, 0.1, 0.1)

var _flurry_n := 0


func _make_data() -> CharacterData:
	keep_min = 120.0
	keep_max = 360.0
	attack_chance = 0.72
	phase2_speed_mult = 1.45
	phase2_cooldown_mult = 0.6
	voice_id = ""                       # No voice lines: Geyron only roars
	roar_sfx = "dragon_roar"
	accent = Color(1.0, 0.35, 0.3)
	rage_title = "BLOOD FRENZY!"
	var d := SimpleEnemy.make_data("Geyron", HP, Vector2(150, 160), 270.0)
	d.hitstun_time = 0.1
	d.respawn_delay = 3.0
	return d


static func make_patterns() -> Array[EnemyPattern]:
	var list: Array[EnemyPattern] = []
	#                          id                 name                    cd    dmg  min    max     anim      tele  active rec   big   weights   armored
	list.append(EnemyPattern.make("light_slash", "LIGHT SWORD SLASH!", 2.6, 7, 0.0, 230.0, "slash", 0.3, 0.25, 0.35, true, [2.0, 2.2]))
	list.append(EnemyPattern.make("holy_beam", "HOLY BEAM!", 6.0, 9, 140.0, 680.0, "beam", 0.55, 0.45, 0.45, true, [1.5, 1.6]))
	list.append(EnemyPattern.make("wing_dash", "WING DASH!", 4.5, 8, 160.0, 800.0, "dash", 0.35, 0.4, 0.45, true, [1.4, 1.8], true))
	list.append(EnemyPattern.make("judgment_spears", "JUDGMENT SPEARS!", 7.0, 7, 0.0, 99999.0, "spears", 0.6, 0.3, 0.55, true, [1.2, 1.6]))
	list.append(EnemyPattern.make("angel_flurry", "ANGEL FLURRY!", 4.0, 4, 0.0, 180.0, "flurry", 0.3, 1.0, 0.45, true, [1.6, 2.0]))
	list[0].note = "light-blade tail sweep"
	list[1].note = "long holy breath beam"
	list[2].note = "armored dash + wind slash"
	list[3].note = "spears of light from the sky"
	list[4].note = "5 rapid hits"
	return list


# ============================================================
# ATTACKS
# ============================================================
func _attack(p: EnemyPattern) -> void:
	match p.id:
		"light_slash":
			hitbox.activate(make_hit(dmg(p), Vector2(facing * SLASH_KB.x, SLASH_KB.y), "light_slash"),
				Vector2(facing * 110.0, -70.0), Vector2(200, 130))
			SoundManager.play_sfx("sword_slash")
			SoundManager.play_sfx("holy", -10.0)
		"holy_beam":
			hitbox.activate(make_hit(dmg(p), Vector2(facing * BEAM_KB.x, BEAM_KB.y), "holy_beam"),
				Vector2(facing * (BEAM_LEN * 0.5 + 90.0), BEAM_Y), Vector2(BEAM_LEN, 44))
			SoundManager.play_sfx("beam")
			Effects.shake(self, 6.0)
		"wing_dash":
			hitbox.activate(make_hit(dmg(p), Vector2(facing * DASH_KB.x, DASH_KB.y), "wing_dash"),
				Vector2(facing * 50.0, -80.0), Vector2(170, 140))
			Effects.trail(visuals, Color(1, 1, 1, 0.9), 40.0, 14)
			SoundManager.play_sfx("dash")
		"judgment_spears":
			var tx := target_x()
			var n := 7 if enraged else 5
			for i in n:
				var off := float(i - n / 2) * 95.0 + randf_range(-15.0, 15.0)
				hazard("spear", tx + off, 0.55 + float(i) * 0.09, dmg(p), Vector2(140, -360))
			SoundManager.play_sfx("holy", -4.0)
		"angel_flurry":
			_flurry_n = 0
			_flurry_hit(p)


func _flurry_hit(p: EnemyPattern) -> void:
	_flurry_n += 1
	var last := _flurry_n >= 5
	var kb := Vector2(420, -280) if last else FLURRY_KB
	hitbox.activate(make_hit(dmg(p), Vector2(facing * kb.x, kb.y), "angel_flurry"),
		Vector2(facing * 95.0, -80.0), Vector2(150, 110))
	velocity.x += facing * 80.0
	SoundManager.play_sfx("swing" if _flurry_n % 2 == 1 else "sword_slash", -3.0)


func _on_attack_update(p: EnemyPattern, _delta: float) -> void:
	match p.id:
		"wing_dash":
			dash_step(DASH_SPEED)
		"angel_flurry":
			if _flurry_n < 5 and state_time >= float(_flurry_n) * 0.19:
				_flurry_hit(p)


func _on_attack_end(p: EnemyPattern) -> void:
	if p.id == "wing_dash":
		velocity.x *= 0.2
		# Wind slash flies on from where the dash ended
		var w := spawn_projectile()
		w.look = "wind"
		w.damage = maxi(1, dmg(p) / 2)
		w.knockback = Vector2(380, -200)
		w.dir = float(facing)
		w.speed = 720.0
		w.lifetime = 0.6
		w.size = Vector2(60, 120)
		w.move = "wind_slash"
		launch(w, global_position + Vector2(facing * 80.0, -80.0))


func _owns_velocity_x() -> bool:
	return estate == EState.ATTACK and current != null and current.id == "wing_dash"


func _on_phase_changed(new_phase: int) -> void:
	super._on_phase_changed(new_phase)
	Effects.red_burst(self, global_position + Vector2(0, -90), 120.0)


# ============================================================
# ART (facing right, origin = feet, ~260 x 220 with wings and tail)
# ============================================================
func draw_model_on(c: CanvasItem) -> void:
	draw_dragon(c, art_state())


static func draw_portrait(c: CanvasItem, t: float) -> void:
	draw_dragon(c, {"t": t, "pose": "idle"})


static func draw_dragon(c: CanvasItem, s: Dictionary) -> void:
	var t: float = s.get("t", 0.0)
	var pose: String = s.get("pose", "idle")
	var pt: float = s.get("pose_t", 0.0)
	var dead: bool = s.get("dead", false)
	var rage: bool = s.get("enraged", false)
	var breathe := sin(t * 2.4) * 2.5
	var lean := 0.0
	if pose == "dash":
		lean = 20.0
	elif pose == "dash_tele":
		lean = -12.0

	if rage:
		EnemyArt.aura(c, Vector2(0, -100), 110.0, BLOOD, t * 1.5)

	var body := Vector2(-6 + lean, -84 + breathe)

	# --- Wings (behind): torn white membrane on bone fingers ---
	var flap := sin(t * 3.2) * 0.15
	match pose:
		"dash_tele":
			flap = -0.6
		"dash":
			flap = 0.6
		"spears_tele", "spears":
			flap = -0.8 + sin(t * 20.0) * 0.1
	_wing(c, body + Vector2(-14, -30), flap, true, t)
	_wing(c, body + Vector2(0, -28), flap + 0.15, false, t)

	# --- Tail with the LIGHT BLADE ---
	var swing := 0.0
	match pose:
		"slash_tele":
			swing = -1.0
		"slash":
			swing = clampf(pt / 0.12, 0.0, 1.0) * 2.0 - 1.0
		"flurry":
			swing = sin(t * 34.0)
	var tail := PackedVector2Array()
	for i in 9:
		var k := float(i) / 8.0
		tail.append(body + Vector2(-40.0 - 90.0 * k, 30.0 - 60.0 * k * k + sin(t * 2.0 + k * 3.0) * 6.0)
			.lerp(body + Vector2(60.0 + 40.0 * k, 20.0 - 110.0 * k + 60.0 * k * k), clampf(swing, 0.0, 1.0) * k))
	_tube(c, tail, 30.0, 8.0, SCALE_SHADE, SCALE)
	var tip := tail[tail.size() - 1]
	var tdir := (tip - tail[tail.size() - 2]).normalized()
	var blade_end := tip + tdir * 90.0
	c.draw_line(tip, blade_end, Color(LIGHT.r, LIGHT.g, LIGHT.b, 0.35), 22.0, FighterArt.AA)
	c.draw_line(tip, blade_end, LIGHT, 10.0, FighterArt.AA)
	c.draw_line(tip, blade_end, Color.WHITE, 4.0, FighterArt.AA)
	if pose == "slash" and pt < 0.25:                      # Light trail of the sweep
		c.draw_arc(body + Vector2(40, 0), 130.0, -1.6, 0.9, 22, Color(LIGHT.r, LIGHT.g, LIGHT.b, 0.8 - pt * 3.0), 14.0, FighterArt.AA)
	if pose == "flurry":
		c.draw_arc(body + Vector2(70, -10), 90.0, -1.2 + sin(t * 34.0), 0.4 + sin(t * 34.0), 12, Color(LIGHT.r, LIGHT.g, LIGHT.b, 0.6), 9.0, FighterArt.AA)

	# --- Hind legs (thick, clawed) ---
	for i in 2:
		var far := i == 0
		var hx := -30.0 if far else -6.0
		var step := sin(float(s.get("walk", 0.0)) + (PI if far else 0.0)) * (10.0 if s.get("moving", false) else 0.0)
		var col := SCALE_SHADE if far else SCALE
		FighterArt.limb(c, body + Vector2(hx, 20), Vector2(hx - 10 + step, -34), 22.0, col, SCALE_SHADE, Color.WHITE)
		FighterArt.limb(c, Vector2(hx - 10 + step, -34), Vector2(hx + 6 + step, -6), 16.0, col, SCALE_SHADE, Color.WHITE)
		for k in 3:
			c.draw_colored_polygon(PackedVector2Array([Vector2(hx + 2 + step + float(k) * 8.0, -8), Vector2(hx + 8 + step + float(k) * 8.0, -8), Vector2(hx + 12 + step + float(k) * 8.0, 0)]), HORN)

	# --- Body: big white scaled torso + belly plates ---
	var torso := EnemyArt.ellipse_points(body, 62, 44, 22)
	c.draw_colored_polygon(torso, SCALE)
	var belly := EnemyArt.ellipse_points(body + Vector2(18, 16), 38, 24, 16)
	c.draw_colored_polygon(belly, BELLY)
	for i in 4:
		c.draw_line(body + Vector2(-2 + float(i) * 12.0, 4), body + Vector2(6 + float(i) * 12.0, 36), SCALE_SHADE, 2.0)
	# Back spikes
	for i in 5:
		var b := body + Vector2(-40 + float(i) * 18.0, -36 - sin(float(i) * 0.7) * 6.0)
		c.draw_colored_polygon(PackedVector2Array([b + Vector2(-7, 4), b + Vector2(7, 4), b + Vector2(-2, -16)]), HORN)
	# BLOOD: splatters + drips running down
	_blood(c, body + Vector2(10, -10), 14.0, t, 0.0)
	_blood(c, body + Vector2(-34, 8), 10.0, t, 1.7)
	_blood(c, body + Vector2(30, 24), 9.0, t, 3.1)
	FighterArt.outline(c, torso, 4.5)

	# --- Front arm (claw) ---
	var claw := body + Vector2(54, 36)
	match pose:
		"flurry":
			claw = body + Vector2(100 + 26.0 * sin(t * 34.0 + PI), -10 + 20.0 * cos(t * 34.0))
		"flurry_tele", "slash_tele":
			claw = body + Vector2(30, -20)
		"spears_tele", "spears":
			claw = body + Vector2(60, -60)
	FighterArt.limb(c, body + Vector2(40, 6), claw, 14.0, SCALE, SCALE_SHADE, Color.WHITE)
	for k in 3:
		var a := -0.5 + float(k) * 0.5
		var ct := claw + Vector2.from_angle(a) * 16.0
		c.draw_line(claw, ct, EnemyArt.BLACK, 6.0, FighterArt.AA)
		c.draw_line(claw, ct, BLOOD if k == 1 else HORN, 3.0, FighterArt.AA)

	# --- Neck + head ---
	var head := body + Vector2(78, -60 + sin(t * 2.0) * 3.0)
	match pose:
		"beam_tele":
			head = body + Vector2(64, -76)
		"beam":
			head = body + Vector2(92, -38)
		"dash":
			head = body + Vector2(96, -36)
	var neck := PackedVector2Array()
	for i in 6:
		var k := float(i) / 5.0
		neck.append((body + Vector2(40, -16)).lerp(head + Vector2(-16, 6), k) + Vector2(0, -sin(k * PI) * 14.0))
	_tube(c, neck, 26.0, 20.0, SCALE_SHADE, SCALE)
	_blood(c, neck[3], 7.0, t, 4.2)
	_head(c, head, pose, pt, t, dead, rage)

	# Holy beam from the mouth (same line as the hitbox)
	if pose == "beam_tele":
		var k := clampf(pt / 0.55, 0.0, 1.0)
		c.draw_circle(head + Vector2(30, 6), 6.0 + 12.0 * k, Color(LIGHT.r, LIGHT.g, LIGHT.b, 0.8))
	elif pose == "beam":
		var fade := 1.0 - clampf((pt - 0.35) / 0.1, 0.0, 1.0)
		var origin := Vector2(head.x + 30.0, BEAM_Y)
		c.draw_rect(Rect2(origin.x, origin.y - 34.0, BEAM_LEN, 68.0), Color(LIGHT.r, LIGHT.g, LIGHT.b, 0.22 * fade))
		FighterArt.beam_gradient(c, origin, BEAM_LEN, 20.0 * fade + 1.0, Color(1.0, 0.85, 0.4), Color.WHITE)
		c.draw_line(head + Vector2(30, 6), origin, LIGHT, 14.0 * fade, FighterArt.AA)


static func _head(c: CanvasItem, head: Vector2, pose: String, pt: float, t: float, dead: bool, rage: bool) -> void:
	var open := 0.0
	if pose == "beam_tele" or pose == "beam" or pose == "spears_tele":
		open = 1.0
	# Horns
	c.draw_colored_polygon(PackedVector2Array([head + Vector2(-14, -10), head + Vector2(-6, -14), head + Vector2(-34, -40)]), HORN)
	c.draw_colored_polygon(PackedVector2Array([head + Vector2(-4, -12), head + Vector2(4, -14), head + Vector2(-18, -46)]), HORN)
	FighterArt.outline(c, PackedVector2Array([head + Vector2(-4, -12), head + Vector2(4, -14), head + Vector2(-18, -46)]), 2.5)
	# Skull + snout
	var top := PackedVector2Array([head + Vector2(-20, -12), head + Vector2(8, -18), head + Vector2(40, -6), head + Vector2(42, 2 - 4.0 * open), head + Vector2(-16, 6)])
	c.draw_colored_polygon(top, SCALE)
	FighterArt.outline(c, top, 3.5)
	var jaw := PackedVector2Array([head + Vector2(-14, 6), head + Vector2(38, 6 + 14.0 * open), head + Vector2(34, 14 + 16.0 * open), head + Vector2(-10, 16)])
	c.draw_colored_polygon(jaw, SCALE_SHADE)
	FighterArt.outline(c, jaw, 3.0)
	if open > 0.0:
		c.draw_colored_polygon(PackedVector2Array([head + Vector2(-8, 6), head + Vector2(40, 2), head + Vector2(36, 18)]), BLOOD_DARK)
	for k in 4:                                          # Teeth
		var x := 6.0 + float(k) * 8.0
		c.draw_colored_polygon(PackedVector2Array([head + Vector2(x, 4), head + Vector2(x + 4, 4), head + Vector2(x + 2, 10)]), Color.WHITE)
	# Blood around the mouth
	c.draw_line(head + Vector2(30, 10 + 10.0 * open), head + Vector2(32, 22 + 10.0 * open + sin(t * 2.0) * 2.0), BLOOD, 3.0)
	c.draw_circle(head + Vector2(20, 12 + 8.0 * open), 4.0, Color(BLOOD.r, BLOOD.g, BLOOD.b, 0.8))
	if dead:
		EnemyArt.ko_eye(c, head + Vector2(8, -6), 4.5, t)
	else:
		var f := 0.7 + 0.3 * sin(t * (16.0 if rage else 6.0))
		c.draw_circle(head + Vector2(8, -6), 8.0, Color(EYE.r, EYE.g, EYE.b, 0.3 * f))
		c.draw_colored_polygon(PackedVector2Array([head + Vector2(2, -8), head + Vector2(16, -7), head + Vector2(4, -3)]), EYE)
		c.draw_line(head + Vector2(0, -12), head + Vector2(16, -9), EnemyArt.BLACK, 2.5)


static func _wing(c: CanvasItem, root: Vector2, flap: float, far: bool, t: float) -> void:
	var col := WING_SKIN.darkened(0.15) if far else WING_SKIN
	var tips: Array[Vector2] = []
	for i in 4:
		var a := -2.2 + flap + float(i) * 0.32
		tips.append(root + Vector2.from_angle(a) * (130.0 - float(i) * 18.0))
	var pts := PackedVector2Array([root])
	for i in tips.size():
		pts.append(tips[i])
		if i < tips.size() - 1:                           # Torn scallop between fingers
			pts.append(root.lerp(tips[i].lerp(tips[i + 1], 0.5), 0.72))
	pts.append(root + Vector2(20, 10))
	c.draw_colored_polygon(pts, col)
	# Blood stains on the membrane
	c.draw_circle(root.lerp(tips[1], 0.55), 9.0, Color(BLOOD.r, BLOOD.g, BLOOD.b, 0.55))
	c.draw_circle(root.lerp(tips[2], 0.7) + Vector2(4, 4), 6.0, Color(BLOOD.r, BLOOD.g, BLOOD.b, 0.45))
	FighterArt.outline(c, pts, 3.5)
	for tp in tips:                                      # Bone fingers
		c.draw_line(root, tp, EnemyArt.BLACK, 6.0, FighterArt.AA)
		c.draw_line(root, tp, HORN, 3.0, FighterArt.AA)


## Blood splatter + a drip that slowly runs down.
static func _blood(c: CanvasItem, p: Vector2, r: float, t: float, phase: float) -> void:
	c.draw_circle(p, r, Color(BLOOD.r, BLOOD.g, BLOOD.b, 0.85))
	c.draw_circle(p + Vector2(r * 0.8, -r * 0.4), r * 0.4, Color(BLOOD.r, BLOOD.g, BLOOD.b, 0.85))
	c.draw_circle(p + Vector2(-r * 0.7, r * 0.5), r * 0.3, BLOOD_DARK)
	var drip := fmod(t * 0.6 + phase, 1.0)
	c.draw_line(p, p + Vector2(0, r + 14.0 * drip), BLOOD, 3.0)
	c.draw_circle(p + Vector2(0, r + 14.0 * drip), 2.5, BLOOD)


## Thick tapering tube (tail / neck): outline, body, lit stripe.
static func _tube(c: CanvasItem, pts: PackedVector2Array, w0: float, w1: float, shade: Color, base: Color) -> void:
	var n := pts.size()
	for i in n:
		c.draw_circle(pts[i], lerpf(w0, w1, float(i) / float(n - 1)) * 0.5 + 3.0, EnemyArt.BLACK)
	for i in n:
		c.draw_circle(pts[i], lerpf(w0, w1, float(i) / float(n - 1)) * 0.5, shade)
	for i in n:
		c.draw_circle(pts[i] + Vector2(-1, -3), lerpf(w0, w1, float(i) / float(n - 1)) * 0.3, base)
