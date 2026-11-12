class_name RotorArt
extends RefCounted
## ROTOR: blue merle Australian Shepherd. Flat cartoon, thick wavy black outline.
## Blue-grey fur with black merle patches, white chest + blaze + paws, copper cheeks,
## one BLUE eye and one BROWN eye, floppy ears, wagging tail, tongue out.
## Drawn facing RIGHT, origin = feet centre, about 76 x 64.
## Poses: idle / bite / spin_tele / spin / bark_tele / bark / tail_tele / tail /
##        fetch_tele / fetch. ENRAGED = glowing fur. DEAD = swirly eyes + tongue out.
## No draw_set_transform (death animations / cards scale us).

const FUR := Color(0.63, 0.69, 0.79)
const FUR_SHADE := Color(0.42, 0.47, 0.59)
const FUR_HI := Color(0.86, 0.90, 0.96)
const MERLE := Color(0.15, 0.17, 0.23)
const WHITE := Color(0.98, 0.98, 0.96)
const WHITE_SHADE := Color(0.80, 0.82, 0.86)
const COPPER := Color(0.80, 0.50, 0.26)
const TONGUE := Color(0.98, 0.45, 0.56)
const TONGUE_SHADE := Color(0.80, 0.25, 0.38)
const EYE_BLUE := Color(0.30, 0.68, 1.0)
const EYE_BROWN := Color(0.45, 0.25, 0.10)
const BALL := Color(0.95, 0.15, 0.15)
const BLACK := Color(0, 0, 0)


static func draw(c: CanvasItem, r: Rotor) -> void:
	_draw_dog(c, {
		"t": r.anim_time, "walk": r.walk_phase, "floor": r.is_on_floor(), "moving": absf(r.velocity.x) > 30.0,
		"pose": r.pose, "pose_t": r.pose_t, "enraged": r.enraged, "dead": r.is_dead,
	})


static func draw_portrait(c: CanvasItem, t: float) -> void:
	_draw_dog(c, {"t": t, "pose": "idle"})


static func _draw_dog(c: CanvasItem, s: Dictionary) -> void:
	var t: float = s.get("t", 0.0)
	var pose: String = s.get("pose", "idle")
	var pt: float = s.get("pose_t", 0.0)
	var enraged: bool = s.get("enraged", false)
	var dead: bool = s.get("dead", false)

	if enraged:   # Glowing fur aura
		var p := 0.5 + 0.5 * sin(t * 10.0)
		c.draw_circle(Vector2(4, -34), 50.0 + 5.0 * p, Color(0.55, 0.8, 1.0, 0.18 + 0.1 * p))

	# --- SPIN: a blurry spinning rotor disc ---
	if pose == "spin" or (pose == "spin_tele" and pt > 0.15):
		_spin_disc(c, t, 1.0 if pose == "spin" else clampf((pt - 0.15) / 0.35, 0.3, 1.0), enraged)
		return

	var crouch := 8.0 if pose.ends_with("_tele") else 0.0
	var body_c := Vector2(2, -30 + crouch)

	# --- Far legs ---
	var ph: float = s.get("walk", 0.0)
	var moving: bool = s.get("moving", false)
	var on_floor: bool = s.get("floor", true)
	var stride := 10.0 if moving else 0.0
	if not on_floor:
		stride = 0.0
	_leg(c, body_c + Vector2(-20, 6), sin(ph) * stride, true, crouch, dead)
	_leg(c, body_c + Vector2(20, 6), -sin(ph) * stride, true, crouch, dead)

	# --- Tail (wagging; whirling for Tail Whip) ---
	_tail(c, body_c + Vector2(-28, -6), t, pose, pt, enraged)

	# --- Body ---
	var body := PackedVector2Array()
	var cols := PackedColorArray()
	for i in 28:
		var a := TAU * float(i) / 28.0
		var p := body_c + Vector2(cos(a) * 31.0, sin(a) * 16.0)
		body.append(p)
		cols.append(FUR.lerp(FUR_SHADE, clampf((p.y - body_c.y + 4.0) / 18.0, 0.0, 1.0)))
	c.draw_polygon(body, cols)
	# Merle patches
	for m in [[Vector2(-14, -7), 8.0], [Vector2(-2, -10), 6.0], [Vector2(-22, 2), 5.0], [Vector2(8, -4), 4.0]]:
		_patch(c, body_c + m[0], m[1])
	# White chest
	var chest := PackedVector2Array()
	for i in 14:
		var a := TAU * float(i) / 14.0
		chest.append(body_c + Vector2(22, 3) + Vector2(cos(a) * 10.0, sin(a) * 11.0))
	c.draw_colored_polygon(chest, WHITE)
	if enraged:
		c.draw_arc(body_c, 26.0, -2.6, -0.6, 12, Color(0.8, 0.95, 1.0, 0.7), 2.0, FighterArt.AA)
	FighterArt.outline(c, body, 4.0)

	# --- Near legs ---
	_leg(c, body_c + Vector2(-26, 8), -sin(ph) * stride, false, crouch, dead)
	_leg(c, body_c + Vector2(14, 8), sin(ph) * stride, false, crouch, dead)

	# --- Head ---
	_head(c, body_c + Vector2(32, -14), t, pose, pt, dead)


static func _patch(c: CanvasItem, center: Vector2, r: float) -> void:
	var pts := PackedVector2Array()
	for i in 9:
		var a := TAU * float(i) / 9.0
		pts.append(center + Vector2(cos(a), sin(a) * 0.7) * r * (0.7 + 0.3 * sin(float(i) * 2.3 + r)))
	c.draw_colored_polygon(pts, MERLE)


static func _leg(c: CanvasItem, hip: Vector2, swing: float, far: bool, crouch: float, dead: bool) -> void:
	var foot := Vector2(hip.x + swing, -3.0)
	if dead:
		foot = Vector2(hip.x + swing, hip.y + 18.0)       # Stiff straight legs (they point up when flipped)
	var knee := hip.lerp(foot, 0.5) + Vector2(3, -crouch * 0.4)
	var base := FUR_SHADE if far else FUR
	FighterArt.limb(c, hip, knee, 9.0, base, FUR_SHADE, FUR_HI)
	FighterArt.limb(c, knee, foot, 8.0, base, FUR_SHADE, FUR_HI)
	c.draw_circle(foot + Vector2(2, 0), 6.5, BLACK)
	c.draw_circle(foot + Vector2(2, 0), 4.5, WHITE_SHADE if far else WHITE)     # White paws


static func _tail(c: CanvasItem, base: Vector2, t: float, pose: String, pt: float, enraged: bool) -> void:
	if pose == "tail" or pose == "tail_tele":
		# Tail Whip: tail whirls all the way around, white motion ring
		var spin := (pt * (30.0 if pose == "tail" else 12.0))
		var whip_tip := base + Vector2.from_angle(spin) * 46.0
		if pose == "tail":
			c.draw_arc(base + Vector2(30, 0), 92.0, 0.0, TAU, 48, Color(1, 1, 1, 0.45), 10.0, FighterArt.AA)
			c.draw_arc(base + Vector2(30, 0), 92.0, spin, spin + 2.0, 16, Color(0.8, 0.9, 1.0, 0.9), 6.0, FighterArt.AA)
		FighterArt.limb(c, base, base.lerp(whip_tip, 0.55), 11.0, FUR, FUR_SHADE, FUR_HI)
		FighterArt.limb(c, base.lerp(whip_tip, 0.55), whip_tip, 10.0, WHITE, WHITE_SHADE, WHITE)
		return
	var wag := sin(t * (26.0 if enraged else 18.0)) * 0.45
	var mid := base + Vector2.from_angle(-2.4 + wag) * 18.0
	var tip := mid + Vector2.from_angle(-1.9 + wag * 1.5) * 14.0
	FighterArt.limb(c, base, mid, 12.0, FUR, FUR_SHADE, FUR_HI)
	FighterArt.limb(c, mid, tip, 10.0, WHITE, WHITE_SHADE, WHITE)      # Fluffy white tip


static func _head(c: CanvasItem, hc: Vector2, t: float, pose: String, pt: float, dead: bool) -> void:
	var bark_open := 0.0
	if pose == "bark_tele":
		bark_open = clampf(pt / 0.3, 0.0, 1.0)
	elif pose == "bark":
		bark_open = 1.0
	elif pose == "bite":
		bark_open = 0.6 * (1.0 - clampf(pt / 0.12, 0.0, 1.0))
	# Far ear (behind)
	_ear(c, hc + Vector2(-6, -12), t, true)
	# Skull
	FighterArt.ball(c, hc, 15.0, FUR, FUR_SHADE, FUR_HI)
	_patch(c, hc + Vector2(-5, -6), 7.0)                       # Merle mask
	c.draw_colored_polygon(PackedVector2Array([hc + Vector2(2, -15), hc + Vector2(6, -15), hc + Vector2(9, 2), hc + Vector2(3, 2)]), WHITE)   # Blaze
	c.draw_circle(hc + Vector2(6, 6), 5.0, COPPER)              # Copper cheek
	# Snout + jaw
	var snout := hc + Vector2(15, 5)
	if bark_open > 0.0:
		var jaw := PackedVector2Array([snout + Vector2(-6, 2), snout + Vector2(10, 2 + 10.0 * bark_open), snout + Vector2(-2, 8 + 10.0 * bark_open)])
		c.draw_colored_polygon(PackedVector2Array([snout + Vector2(-6, 0), snout + Vector2(11, -1), snout + Vector2(10, 2 + 10.0 * bark_open), snout + Vector2(-4, 6 + 9.0 * bark_open)]), Color(0.45, 0.05, 0.1))
		c.draw_colored_polygon(jaw, WHITE)
		FighterArt.outline(c, jaw, 2.5)
		c.draw_line(snout + Vector2(2, 1), snout + Vector2(3, 4), Color.WHITE, 2.0)            # Fang
	FighterArt.ball(c, snout, 8.5, WHITE, WHITE_SHADE, WHITE)
	c.draw_circle(snout + Vector2(8, -2), 4.2, BLACK)           # Nose
	c.draw_circle(snout + Vector2(7, -3.2), 1.3, Color(0.6, 0.6, 0.65))
	if bark_open <= 0.0:
		c.draw_polyline(PackedVector2Array([snout + Vector2(-2, 5), snout + Vector2(3, 7), snout + Vector2(8, 5)]), BLACK, 2.0, FighterArt.AA)
	# Tongue out (happy pant) - long and limp when dead
	if (pose == "idle" or dead) and bark_open <= 0.0:
		var pant := 2.5 * sin(t * 14.0)
		var tl := 14.0 if dead else 9.0 + pant
		var tg := FighterArt.rrect_points(Rect2(snout + Vector2(0, 5), Vector2(7, tl)), 3.5)
		c.draw_colored_polygon(tg, TONGUE)
		c.draw_line(snout + Vector2(3.5, 7), snout + Vector2(3.5, 4.0 + tl), TONGUE_SHADE, 1.5)
		FighterArt.outline(c, tg, 2.0)
	# Fetch: ball in mouth
	if pose == "fetch_tele":
		FighterArt.ball(c, snout + Vector2(9, 6), 9.0, BALL, Color(0.6, 0.05, 0.08), Color(1, 0.6, 0.6))
		c.draw_line(snout + Vector2(12, -2), snout + Vector2(16, -9), BLACK, 2.5)
		c.draw_circle(snout + Vector2(16, -9), 2.5 + sin(t * 30.0), Color(1, 0.85, 0.2))
	# Eyes: one BLUE, one BROWN (or swirly when K.O.)
	var e1 := hc + Vector2(3, -4)
	var e2 := hc + Vector2(10, -5)
	if dead:
		_swirl(c, e1, t)
		_swirl(c, e2, t + 1.0)
	else:
		_eye(c, e1, EYE_BLUE)
		_eye(c, e2, EYE_BROWN)
	# Near ear (floppy, bouncing)
	_ear(c, hc + Vector2(2, -13), t, false)


static func _eye(c: CanvasItem, p: Vector2, iris: Color) -> void:
	c.draw_circle(p, 4.2, BLACK)
	c.draw_circle(p, 3.2, Color.WHITE)
	c.draw_circle(p + Vector2(0.6, 0.2), 2.2, iris)
	c.draw_circle(p + Vector2(0.8, 0.3), 1.1, BLACK)
	c.draw_circle(p + Vector2(-0.4, -0.9), 0.7, Color.WHITE)


static func _swirl(c: CanvasItem, p: Vector2, t: float) -> void:
	var pts := PackedVector2Array()
	for i in 14:
		var a := float(i) * 0.75 + t * 6.0
		pts.append(p + Vector2.from_angle(a) * (0.4 * float(i) * 0.4 + 0.3))
	c.draw_circle(p, 4.5, Color.WHITE)
	c.draw_polyline(pts, BLACK, 1.5, FighterArt.AA)


static func _ear(c: CanvasItem, root: Vector2, t: float, far: bool) -> void:
	var flop := sin(t * 9.0) * 2.0
	var ear := PackedVector2Array([root + Vector2(-5, 0), root + Vector2(6, -2), root + Vector2(10, 7 + flop), root + Vector2(4, 11 + flop)])
	c.draw_colored_polygon(ear, MERLE if not far else Color(0.08, 0.09, 0.13))
	FighterArt.outline(c, ear, 2.5)


static func _spin_disc(c: CanvasItem, t: float, k: float, enraged: bool) -> void:
	var center := Vector2(0, -32)
	var rot := t * 40.0
	c.draw_circle(center, 36.0, Color(0, 0, 0))
	c.draw_circle(center, 33.0, FUR_SHADE)
	# Blurred fur bands
	for i in 6:
		var a := rot + TAU * float(i) / 6.0
		c.draw_arc(center, 24.0, a, a + 0.7, 8, MERLE if i % 2 == 0 else WHITE, 10.0 * k, FighterArt.AA)
		c.draw_arc(center, 12.0, a + 0.4, a + 1.0, 6, FUR_HI, 6.0 * k, FighterArt.AA)
	# Blur rings
	c.draw_arc(center, 40.0, rot, rot + 4.0, 24, Color(1, 1, 1, 0.5 * k), 5.0, FighterArt.AA)
	c.draw_arc(center, 46.0, -rot, -rot + 3.0, 24, Color(0.75, 0.85, 1.0, 0.35 * k), 4.0, FighterArt.AA)
	if enraged:
		c.draw_circle(center, 50.0, Color(0.55, 0.8, 1.0, 0.15))
	# Glimpse of the face (blue + brown eye) whizzing round
	var face := center + Vector2.from_angle(rot * 0.5) * 14.0
	c.draw_circle(face, 3.0, EYE_BLUE)
	c.draw_circle(face + Vector2(6, 0).rotated(rot * 0.5), 3.0, EYE_BROWN)
	# Speed lines behind
	for i in 3:
		var y := -48.0 + float(i) * 16.0
		c.draw_line(Vector2(-44, y), Vector2(-70 - float(i) * 8.0, y), Color(1, 1, 1, 0.7 * k), 3.0)
