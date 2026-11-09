class_name AlphaArchitectArt
extends RefCounted
## APHA ARCHITECT: built like the Architect, but darker and more athletic.
##   * BLACK helmet with a pale-green visor slit (not the white Architect helmet)
##   * BLACK METAL chest plate (riveted, with a dim green seam) instead of the white plate
##   * FAINT, DARK green everywhere (legs, trim), darker armour and cloth
##   * slimmer waist, broader shoulders, longer limbs: a faster, athletic silhouette
##   * BOTH hands wear the CREATION GLOVES: black gloves, each with sigils glowing in
##     DIFFERENT colours (near glove: crimson / gold, far glove: cyan / violet)
## Drawn facing RIGHT, origin = feet, about 60 x 132.

const BLACK_METAL := Color(0.10, 0.11, 0.12)
const BLACK_METAL_HI := Color(0.30, 0.32, 0.35)
const BLACK_METAL_SHADE := Color(0.04, 0.04, 0.05)
const GREEN := Color(0.14, 0.42, 0.20)            # Faint, dark green
const GREEN_SHADE := Color(0.06, 0.24, 0.10)
const GREEN_HI := Color(0.30, 0.60, 0.36)
const GREEN_FAR := Color(0.09, 0.30, 0.14)
const GREEN_FAR_SHADE := Color(0.04, 0.16, 0.07)
const DARK := Color(0.14, 0.15, 0.17)
const DARK_SHADE := Color(0.06, 0.06, 0.08)
const DARK_HI := Color(0.28, 0.30, 0.33)
const VISOR_GLOW := Color(0.55, 1.0, 0.65)
const CORE := Color(0.30, 0.95, 0.45)
## Sigil colours per glove (each sigil glows a different colour).
const NEAR_SIGILS := [Color(1.0, 0.25, 0.25), Color(1.0, 0.82, 0.25)]
const FAR_SIGILS := [Color(0.25, 0.9, 1.0), Color(0.75, 0.40, 1.0)]


static func draw(c: CanvasItem, a: AlphaArchitect) -> void:
	_figure(c, {
		"t": a.anim_time, "ph": a.walk_phase, "floor": a.is_on_floor(), "punch": a.punch_ext, "block": a.block_amt,
		"fly": a.flying, "pose": a.pose, "pose_t": a.pose_t, "eyes": a.eyes_closed, "charge": a.is_air_charging(),
	})


static func draw_portrait(c: CanvasItem, t: float) -> void:
	_figure(c, {"t": t, "ph": 0.0, "floor": true, "punch": 0.0, "block": 0.0, "fly": false, "pose": "", "pose_t": 0.0, "eyes": false, "charge": false})


static func _figure(c: CanvasItem, s: Dictionary) -> void:
	var t: float = s["t"]
	var ph: float = s["ph"]
	var fly: bool = s["fly"]
	var pose: String = s["pose"]
	var pt: float = s["pose_t"]
	var b: float = s["block"]
	var bob := sin(t * 3.0) * 3.0 if fly else 0.0
	var o := Vector2(0, bob)
	# Flight aura + trail
	if fly:
		c.draw_circle(Vector2(0, -70) + o, 58.0 + 4.0 * sin(t * 6.0), Color(0.3, 1.0, 0.5, 0.10))
		for i in 4:
			var y := -40.0 + float(i) * 14.0
			c.draw_line(Vector2(-20, y) + o, Vector2(-60.0 - float(i) * 12.0, y + 6.0) + o, Color(0.4, 1.0, 0.6, 0.25), 3.0)
	if bool(s["charge"]):                                      # Air charge: streak
		c.draw_rect(Rect2(-110, -110, 90, 70), Color(0.4, 1.0, 0.6, 0.18))

	# --- Legs: long, athletic. Flying = trailing pose ---
	var sw := sin(ph) * 15.0
	var lf := maxf(0.0, cos(ph)) * 8.0
	var lb := maxf(0.0, -cos(ph)) * 8.0
	var far_foot := Vector2(-8.0 - sw, -4.0 - lb)
	var near_foot := Vector2(8.0 + sw, -4.0 - lf)
	if fly:
		far_foot = Vector2(-22, -14)
		near_foot = Vector2(-10, -8)
	elif not bool(s["floor"]):
		far_foot = Vector2(-10, -16)
		near_foot = Vector2(12, -8)
	_leg(c, Vector2(-5, -58) + o, far_foot + o, true)
	_leg(c, Vector2(5, -58) + o, near_foot + o, false)

	# --- Arm poses (both hands = Creation Gloves) ---
	var e := clampf(float(s["punch"]), 0.0, 1.0)
	var swing := sin(ph) * 9.0 * (1.0 - maxf(e, b))
	var hand := Vector2(14.0 - swing, -58).lerp(Vector2(60, -94), e)
	var el := Vector2(10.0 - swing * 0.5, -78).lerp(Vector2(32, -95), e)
	var bh := Vector2(-10.0 + swing, -58)
	var bel := Vector2(-10.0 + swing * 0.5, -78)
	if float(s["punch"]) < 0.0:
		hand = Vector2(-2, -86)
		el = Vector2(4, -84)
	match pose:
		"clap":                                                  # Hands come together in front
			var k := clampf(pt / 0.25, 0.0, 1.0)
			hand = Vector2(lerpf(56.0, 36.0, k), -88)
			bh = Vector2(lerpf(10.0, 32.0, k), -88)
			el = Vector2(24, -90)
			bel = Vector2(10, -90)
		"touch":
			hand = Vector2(54, -78)
			el = Vector2(30, -84)
		"barrage", "portal":
			hand = Vector2(58, -96)
			el = Vector2(30, -96)
			bh = Vector2(40, -104)
			bel = Vector2(16, -96)
		"decay", "rod":                                          # Both hands raised over the head
			hand = Vector2(14, -150)
			el = Vector2(14, -120)
			bh = Vector2(-6, -150)
			bel = Vector2(-6, -120)
		"throw":
			hand = Vector2(50, -60)
			el = Vector2(30, -80)
		"opening":                                               # Arms open, palms out
			hand = Vector2(46, -110)
			el = Vector2(26, -104)
			bh = Vector2(-34, -110)
			bel = Vector2(-20, -104)
	hand = hand.lerp(Vector2(26, -96), b)
	el = el.lerp(Vector2(20, -76), b)
	_arm(c, Vector2(-6, -98) + o, bel + o, bh + o, true, t)

	# --- Torso: dark undersuit, BLACK METAL chest, narrow waist ---
	var torso := PackedVector2Array([Vector2(-19, -104), Vector2(21, -104), Vector2(14, -58), Vector2(-12, -58)])
	for i in torso.size():
		torso[i] += o
	c.draw_colored_polygon(torso, DARK)
	FighterArt.outline(c, torso, 4.0)
	var plate := PackedVector2Array([Vector2(-20, -106), Vector2(22, -106), Vector2(18, -74), Vector2(2, -66), Vector2(-15, -74)])
	for i in plate.size():
		plate[i] += o
	c.draw_polygon(plate, PackedColorArray([BLACK_METAL_HI, BLACK_METAL, BLACK_METAL_SHADE, BLACK_METAL_SHADE, BLACK_METAL]))
	FighterArt.outline(c, plate, 4.0)
	c.draw_line(Vector2(2, -104) + o, Vector2(2, -68) + o, Color(GREEN_HI.r, GREEN_HI.g, GREEN_HI.b, 0.6), 2.0)   # Dim green seam
	for r in [Vector2(-14, -100), Vector2(17, -100), Vector2(-11, -78), Vector2(14, -78)]:
		c.draw_circle(r + o, 2.0, BLACK_METAL_HI)                                                        # Rivets
	var pulse := 0.5 + 0.5 * sin(t * 4.0)
	c.draw_circle(Vector2(4, -88) + o, 9.0 + 2.0 * pulse, Color(CORE.r, CORE.g, CORE.b, 0.18))
	c.draw_circle(Vector2(4, -88) + o, 5.0, Color(CORE.r, CORE.g, CORE.b, 0.7))
	FighterArt.rrect(c, Rect2(-13, -62 + bob, 26, 7), DARK_SHADE, BLACK_METAL_SHADE, DARK, 3.0, 3.0)   # Belt
	FighterArt.ball(c, Vector2(16, -100) + o, 9.0, BLACK_METAL, BLACK_METAL_SHADE, BLACK_METAL_HI)    # Broad shoulder

	# --- Head: BLACK helmet, glowing pale-green slit (closed eyes = dim) ---
	var head := Vector2(4, -120) + o
	FighterArt.ball(c, head, 14.0, BLACK_METAL, BLACK_METAL_SHADE, BLACK_METAL_HI)
	c.draw_colored_polygon(PackedVector2Array([head + Vector2(-6, -16), head + Vector2(2, -26), head + Vector2(4, -14)]), BLACK_METAL)   # Fin crest
	FighterArt.rrect(c, Rect2(head.x + 3, head.y - 6, 14, 8), Color(0.02, 0.02, 0.03), Color(0.02, 0.02, 0.03), DARK, 3.0, 3.0)
	var eyes_closed: bool = s["eyes"]
	var glow := Color(VISOR_GLOW.r, VISOR_GLOW.g, VISOR_GLOW.b, 0.25 if eyes_closed else 1.0)
	c.draw_rect(Rect2(head.x + 5, head.y - 3, 10, 2.5 if eyes_closed else 3.5), glow)
	if not eyes_closed:
		c.draw_rect(Rect2(head.x + 3, head.y - 5, 14, 7), Color(VISOR_GLOW.r, VISOR_GLOW.g, VISOR_GLOW.b, 0.18))

	_arm(c, Vector2(8, -98) + o, el + o, hand + o, false, t)

	# --- Block shield ---
	if b > 0.05:
		c.draw_arc(Vector2(14, -76), 52.0, -1.0, 1.0, 20, Color(0, 0, 0, b), 11.0, true)
		c.draw_arc(Vector2(14, -76), 52.0, -1.0, 1.0, 20, Color(0.4, 1.0, 0.55, 0.85 * b), 6.0, true)


## Long, faint dark-green legs, black knee plates + boots.
static func _leg(c: CanvasItem, hip: Vector2, foot: Vector2, far: bool) -> void:
	var base := GREEN_FAR if far else GREEN
	var shade := GREEN_FAR_SHADE if far else GREEN_SHADE
	var knee := (hip + foot) * 0.5 + Vector2(6, 0)
	FighterArt.limb(c, hip, knee, 10.0, base, shade, GREEN_HI)
	FighterArt.limb(c, knee, foot + Vector2(0, -4), 9.0, base, shade, GREEN_HI)
	FighterArt.ball(c, knee, 5.0, BLACK_METAL, BLACK_METAL_SHADE, BLACK_METAL_HI)
	FighterArt.rrect(c, Rect2(foot.x - 7.0, foot.y - 4.0, 22, 8), BLACK_METAL if not far else BLACK_METAL_SHADE, BLACK_METAL_SHADE, DARK_HI, 3.0, 3.5)


## Dark arm + a black CREATION GLOVE with two sigils glowing in different colours.
static func _arm(c: CanvasItem, shoulder: Vector2, elbow: Vector2, hand: Vector2, far: bool, t: float) -> void:
	var base := DARK_SHADE if far else DARK
	FighterArt.limb(c, shoulder, elbow, 8.5, base, DARK_SHADE, DARK_HI)
	FighterArt.limb(c, elbow, hand, 9.5, base, DARK_SHADE, DARK_HI)
	FighterArt.ball(c, elbow, 4.5, base, DARK_SHADE, DARK_HI)
	var glove := FighterArt.rrect_points(Rect2(hand.x - 8.0, hand.y - 8.0, 17, 17), 4.0)
	c.draw_colored_polygon(glove, Color(0.03, 0.03, 0.04))
	FighterArt.outline(c, glove, 3.0)
	var sig: Array = FAR_SIGILS if far else NEAR_SIGILS
	for i in 2:
		var col: Color = sig[i]
		var p := hand + Vector2(-3.0 + float(i) * 6.0, -2.0 + float(i) * 4.0)
		var g := 0.5 + 0.5 * sin(t * 5.0 + float(i) * 2.0)
		c.draw_circle(p, 5.0 + 2.0 * g, Color(col.r, col.g, col.b, 0.25))
		c.draw_arc(p, 3.0, 0.0, TAU, 8, col, 1.6)
		c.draw_line(p + Vector2(-2, 0), p + Vector2(2, 0), col, 1.4)
