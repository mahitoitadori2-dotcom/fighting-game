class_name FireLordArt
extends RefCounted
## The Nightmare Lord: ALL-RED skin with a smirk, an elegant dark suit, white shirt and a
## RED TIE. All his flames are PURE RED (#FF0000). Flat cartoon, thick black outlines.
## Drawn facing RIGHT, origin = feet, about 64 x 128.
##
## PASSIVE LOOK: the suit tears as his G Gauge fills (tear 0..3), revealing red scales.
## BAT FORM: drawn as a small red bat (still wearing the tie).
## No draw_set_transform here (the Character Select card scales us with it).

const SKIN := Color(0.86, 0.07, 0.08)
const SKIN_SHADE := Color(0.55, 0.02, 0.04)
const SKIN_HI := Color(1.0, 0.45, 0.42)
const SUIT := Color(0.14, 0.12, 0.17)
const SUIT_SHADE := Color(0.06, 0.05, 0.08)
const SUIT_HI := Color(0.32, 0.29, 0.38)
const SHIRT := Color(0.96, 0.95, 0.93)
const TIE := Color(0.90, 0.0, 0.04)
const TIE_SHADE := Color(0.55, 0.0, 0.03)
const SCALE := Color(0.78, 0.04, 0.06)
const SCALE_LINE := Color(0.45, 0.0, 0.02)
const FIRE := Color(1.0, 0.0, 0.0)          # PURE RED
const FIRE_DARK := Color(0.6, 0.0, 0.0)
const SHOE := Color(0.05, 0.05, 0.06)
const BLACK := Color(0, 0, 0)


static func draw(c: CanvasItem, f: FireLord) -> void:
	f.anim_legs = true                                  # This art bends its knees (shared animation)
	_draw_figure(c, {
		"anim": FighterArt.anim_of(f),
		"t": f.anim_time, "ph": f.walk_phase, "floor": f.is_on_floor(),
		"punch": f.punch_ext, "block": f.block_amt, "perfect": f.perfect_flash,
		"cast": f.cast_pose, "spike": f.spike_pose, "tear": f.bonus(),
		"bat": f.is_bat(), "bat_time": f.bat_timer,
		"body_spikes": f.body_spike_t, "spike_rot": f.body_spike_rot,
		"spike_range": f.fd.volatile_spike_range,
	})


## Idle pose for menus / Character Select.
static func draw_portrait(c: CanvasItem, t: float) -> void:
	_draw_figure(c, {"t": t})


static func _draw_figure(c: CanvasItem, s: Dictionary) -> void:
	var t: float = s.get("t", 0.0)
	if s.get("bat", false):
		_bat_form(c, t, s.get("bat_time", 5.0))
		return
	var ph: float = s.get("ph", 0.0)
	var on_floor: bool = s.get("floor", true)
	var b: float = s.get("block", 0.0)
	var e := clampf(s.get("punch", 0.0), 0.0, 1.0)
	var punch: float = s.get("punch", 0.0)
	var cast: float = s.get("cast", 0.0)
	var spike: float = s.get("spike", 0.0)
	var tear: int = s.get("tear", 0)

	# --- Passive aura (stronger with every bar) ---
	if tear > 0:
		var p := 0.5 + 0.5 * sin(t * 5.0)
		c.draw_circle(Vector2(0, -66), 50.0 + 8.0 * tear + 4.0 * p, Color(FIRE.r, 0.0, 0.0, 0.05 + 0.05 * tear))

	# --- Volatile Nightmare: spikes out of his body (behind) ---
	var bs: float = s.get("body_spikes", 0.0)
	if bs > 0.0:
		_body_spikes(c, bs, s.get("spike_rot", 0.0), s.get("spike_range", 140.0))

	# --- Legs (suit trousers) ---
	var g := FighterArt.gait(s.get("anim", {}), ph, on_floor, -8.0, 8.0, -5.0)   # Shared walk / crouch / jump
	if spike < -0.3:          # Slam: legs together, landing
		g = [Vector2(-11, -5), Vector2(11, -5)]
	_leg(c, Vector2(-6, -52), g[0], true, tear)
	_leg(c, Vector2(6, -52), g[1], false, tear)

	# --- Arm targets ---
	var swing := sin(ph) * 8.0 * (1.0 - maxf(e, b))
	var rest_el := Vector2(10.0 - swing * 0.5, -74)
	var rest_hand := Vector2(13.0 - swing, -55)
	var el := rest_el.lerp(Vector2(30, -91), e)
	var hand := rest_hand.lerp(Vector2(56, -91), e)
	if punch < 0.0:
		var w := -punch * 2.0
		el = rest_el + Vector2(-8, -6) * w
		hand = rest_hand + Vector2(-10, -18) * w
	if cast > 0.0:            # Throw: arm thrust forward
		el = el.lerp(Vector2(26, -84), cast)
		hand = hand.lerp(Vector2(46, -82), cast)
	el = el.lerp(Vector2(18, -72), b)
	hand = hand.lerp(Vector2(24, -92), b)
	var b_el := Vector2(-10.0 + swing * 0.5, -74).lerp(Vector2(14, -70), b)
	var b_hand := Vector2(-9.0 + swing, -55).lerp(Vector2(22, -86), b)
	if spike > 0.0:           # Rising: both arms up
		el = el.lerp(Vector2(14, -112), spike)
		hand = hand.lerp(Vector2(18, -134), spike)
		b_el = b_el.lerp(Vector2(-12, -110), spike)
		b_hand = b_hand.lerp(Vector2(-14, -132), spike)
	elif spike < 0.0:         # Slam: fists driven down
		var k := -spike
		el = el.lerp(Vector2(22, -64), k)
		hand = hand.lerp(Vector2(30, -40), k)
		b_el = b_el.lerp(Vector2(-6, -64), k)
		b_hand = b_hand.lerp(Vector2(4, -40), k)
	_arm(c, Vector2(-4, -92), b_el, b_hand, true, tear)

	# --- Torso: jacket, shirt, RED TIE ---
	FighterArt.rrect(c, Rect2(-17, -100, 34, 50), SUIT, SUIT_SHADE, SUIT_HI, 8.0, 4.0)
	var shirt := PackedVector2Array([Vector2(-7, -100), Vector2(10, -100), Vector2(2, -76)])
	c.draw_colored_polygon(shirt, SHIRT)
	# Lapels
	c.draw_polyline(PackedVector2Array([Vector2(-9, -100), Vector2(2, -74), Vector2(12, -100)]), BLACK, 3.0, FighterArt.AA)
	c.draw_line(Vector2(-12, -96), Vector2(-4, -82), SUIT_HI, 2.0)
	# Tie
	var tie := PackedVector2Array([Vector2(-1, -95), Vector2(4, -95), Vector2(6, -76), Vector2(1.5, -70), Vector2(-3, -76)])
	c.draw_colored_polygon(tie, TIE)
	c.draw_colored_polygon(PackedVector2Array([Vector2(1.5, -95), Vector2(4, -95), Vector2(6, -76), Vector2(1.5, -70)]), TIE_SHADE)
	var tc := tie.duplicate()
	tc.append(tie[0])
	c.draw_polyline(tc, BLACK, 2.0, FighterArt.AA)
	c.draw_rect(Rect2(-2, -99, 7, 5), TIE)                       # Knot
	c.draw_rect(Rect2(-2, -99, 7, 5), BLACK, false, 1.5)
	# Buttons + pocket square + a belt (concept art)
	c.draw_circle(Vector2(8, -66), 1.8, SUIT_HI)
	c.draw_rect(Rect2(-17, -58, 34, 4), BLACK)
	c.draw_rect(Rect2(-1, -58, 6, 4), Color(0.75, 0.72, 0.66))
	c.draw_colored_polygon(PackedVector2Array([Vector2(-14, -88), Vector2(-8, -88), Vector2(-11, -84)]), TIE)
	# Passive: torn jacket shows red scales
	if tear >= 1:
		_tear_hole(c, Vector2(-8, -64), 6.0, 1)
	if tear >= 2:
		_tear_hole(c, Vector2(10, -84), 7.0, 2)
		_tear_hole(c, Vector2(-11, -95), 5.0, 3)
	if tear >= 3:
		_tear_hole(c, Vector2(-4, -76), 9.0, 4)
		_tear_hole(c, Vector2(12, -58), 6.5, 5)
		_jagged_hem(c)

	# --- Head: red, slicked hair, smirk ---
	_head(c, t, tear)

	_arm(c, Vector2(4, -92), el, hand, false, tear)

	if tear >= 3:             # Pure red flames dancing on his shoulders
		for sx in [-12.0, 12.0]:
			var h := 12.0 + 5.0 * sin(t * 12.0 + sx)
			var base := Vector2(sx, -100)
			c.draw_polygon(PackedVector2Array([base + Vector2(-5, 0), base + Vector2(5, 0), base + Vector2(1, -h)]), PackedColorArray([FIRE, FIRE, FIRE_DARK]))

	# --- Block (red arc) ---
	if b > 0.05:
		var col := Color(1.0, 0.25, 0.25, 0.85 * b)
		if s.get("perfect", 0.0) > 0.0:
			col = Color(1, 1, 1, 1)
		c.draw_arc(Vector2(10, -70), 50.0, -1.0, 1.0, 20, Color(0, 0, 0, b), 11.0, FighterArt.AA)
		c.draw_arc(Vector2(10, -70), 50.0, -1.0, 1.0, 20, col, 6.0, FighterArt.AA)


# ============================================================
# PARTS
# ============================================================
## PIXEL ART head (hand-pixelled, top-left -18, -150): red face, slicked hair, pointed ear, angry
## brows, the smirk, and the tall top hat with the red band and the round emblem.
const _HEAD_PX := [
	".............",
	"....KKKKKKK..",
	"....KTTTTtK..",
	"....KTTEttK..",
	"....KTTTttK..",
	"....KTTTttK..",
	"....KBBBBBK..",
	"....KTTTttK..",
	"..KtttttttttK",
	"...KrrRRRRRK.",
	".KRRRRRRKRRK.",
	".KRRRRRRWRRWK",
	"..KRRRRRRRRRK",
	"..KhRRRRRRRKK",
	"...KRRRRKKKRK",
	"....KrRRRRRK.",
	"......KKKK...",
]


static func _head(c: CanvasItem, t: float, tear: int) -> void:
	var glint := 0.0 if tear < 3 else 0.5 + 0.5 * sin(t * 8.0)
	PixelSprite.draw(c, PackedStringArray(_HEAD_PX), {
		"K": BLACK, "R": SKIN, "r": SKIN_SHADE, "h": SKIN_HI, "T": SUIT, "t": SUIT_SHADE, "B": TIE, "E": SKIN,
		"W": Color(1.0, 1.0 - glint * 0.6, 1.0 - glint * 0.6),
	}, Vector2(-18, -150))

static func _leg(c: CanvasItem, hip: Vector2, foot: Vector2, far: bool, tear: int) -> void:
	var base := SUIT_SHADE if far else SUIT
	var knee := FighterArt.knee(hip, foot, FighterArt.leg_seg(47.0, 7.0))   # Real knee bend
	FighterArt.limb(c, hip, knee, 12.0, base, SUIT_SHADE, SUIT_HI)
	FighterArt.limb(c, knee, foot + Vector2(0, -4), 11.0, base, SUIT_SHADE, SUIT_HI)
	_shag(c, hip, knee, 11.0)                                             # Concept art: shaggy, frayed cloth
	_shag(c, knee, foot + Vector2(0, -4), 10.0)
	if not far and tear >= 2:
		_tear_hole(c, knee + Vector2(-1, 2), 4.5, 6)
	# Pointed shoe (concept art: long, pointed toes)
	var shoe := PackedVector2Array([foot + Vector2(-8, -5), foot + Vector2(10, -5), foot + Vector2(22, 1), foot + Vector2(18, 4), foot + Vector2(-8, 4)])
	c.draw_colored_polygon(shoe, SHOE)
	c.draw_line(foot + Vector2(-4, -3), foot + Vector2(10, -3), Color(0.5, 0.5, 0.55), 1.5)
	c.draw_polyline(shoe + PackedVector2Array([shoe[0]]), BLACK, 2.0, FighterArt.AA)


static func _arm(c: CanvasItem, shoulder: Vector2, elbow: Vector2, hand: Vector2, far: bool, tear: int) -> void:
	var base := SUIT_SHADE if far else SUIT
	var sleeve := SCALE if (tear >= 3 and not far) else base   # 3 bars: sleeve torn off
	FighterArt.limb(c, shoulder, elbow, 9.0, sleeve, SUIT_SHADE, SUIT_HI)
	FighterArt.limb(c, elbow, hand, 10.0, sleeve, SUIT_SHADE, SUIT_HI)
	if tear >= 3 and not far:
		for i in 3:
			var p := elbow.lerp(hand, 0.25 + 0.25 * float(i))
			c.draw_arc(p, 2.5, 0.0, PI, 6, SCALE_LINE, 1.5)
	else:
		_shag(c, shoulder, elbow, 8.0)
		_shag(c, elbow, hand, 9.0)
		c.draw_circle(hand + (elbow - hand).normalized() * 6.0, 4.5, SHIRT)   # Cuff
	var sk := SKIN_SHADE if far else SKIN
	c.draw_circle(hand, 8.0, BLACK)
	c.draw_circle(hand, 5.6, sk)
	c.draw_circle(hand + Vector2(-1.5, -1.5), 1.8, SKIN_HI)
	# Concept art: long CLAWED fingers
	var fwd := (hand - elbow).normalized() if (hand - elbow).length() > 1.0 else Vector2.RIGHT
	for k in 4:
		var a := fwd.rotated(-0.7 + float(k) * 0.45)
		var root := hand + a * 4.5
		c.draw_line(root, root + a * 7.0, BLACK, 3.2)
		c.draw_line(root, root + a * 6.0, sk, 1.6)
		c.draw_colored_polygon(PackedVector2Array([root + a * 6.0 + a.orthogonal() * 1.2, root + a * 10.0, root + a * 6.0 - a.orthogonal() * 1.2]), BLACK)


## Frayed, shaggy cloth: short dark strokes along the edges of a limb (concept art).
static func _shag(c: CanvasItem, a: Vector2, b: Vector2, w: float) -> void:
	var d := b - a
	if d.length() < 4.0:
		return
	var dir := d.normalized()
	var side := dir.orthogonal() * (w * 0.5)
	for i in 4:
		var p := a.lerp(b, 0.15 + 0.22 * float(i))
		var s := 1.0 if i % 2 == 0 else -1.0
		c.draw_line(p + side * s, p + side * s * 1.45 + dir * 2.5, SUIT_SHADE, 1.6)


## Ragged tear in the suit with red scales underneath.
static func _tear_hole(c: CanvasItem, center: Vector2, r: float, seed_i: int) -> void:
	var pts := PackedVector2Array()
	for i in 9:
		var a := TAU * float(i) / 9.0
		var j := 0.6 + 0.4 * absf(sin(float(seed_i) * 3.7 + float(i) * 2.3))
		pts.append(center + Vector2(cos(a), sin(a)) * r * j)
	c.draw_colored_polygon(pts, SCALE)
	# Scale pattern
	for k in 3:
		var p := center + Vector2((float(k) - 1.0) * r * 0.45, sin(float(seed_i + k)) * r * 0.25)
		c.draw_arc(p, r * 0.3, 0.0, PI, 6, SCALE_LINE, 1.4)
	var closed := pts.duplicate()
	closed.append(pts[0])
	c.draw_polyline(closed, BLACK, 1.8, FighterArt.AA)


static func _jagged_hem(c: CanvasItem) -> void:
	# Jacket bottom ripped into points, scales showing at the waist
	c.draw_rect(Rect2(-16, -56, 32, 6), SCALE)
	var pts := PackedVector2Array([Vector2(-17, -57), Vector2(-12, -51), Vector2(-7, -56), Vector2(-2, -50),
		Vector2(4, -56), Vector2(9, -51), Vector2(14, -56), Vector2(17, -52)])
	c.draw_polyline(pts, BLACK, 2.0, FighterArt.AA)


static func _body_spikes(c: CanvasItem, t_left: float, rot: float, reach: float) -> void:
	var k := 1.0 - clampf(t_left / 0.45, 0.0, 1.0)
	var grow := 1.0 - pow(1.0 - clampf(k / 0.4, 0.0, 1.0), 3.0)
	var alpha := 1.0 - clampf((k - 0.6) / 0.4, 0.0, 1.0)
	var center := Vector2(0, -64)
	for i in 14:
		var a := rot + TAU * float(i) / 14.0
		var d := Vector2.from_angle(a)
		var _p := Vector2(-d.y, d.x)
		var base := center + d * 16.0
		var tip := center + d * (16.0 + (reach - 16.0) * grow)
		if (tip - base).length() > 3.0:
			FighterArt.curved_spike(c, base, tip, 8.0, Color(FIRE_DARK.r, 0.0, 0.0, alpha), Color(FIRE.r, 0.0, 0.0, alpha), 0.3, 2.5)


static func _bat_form(c: CanvasItem, t: float, time_left: float) -> void:
	# Small agile red bat hovering near the floor (the hurtbox is small too).
	var bob := sin(t * 6.0) * 4.0
	var center := Vector2(0, -26 + bob)
	var flap := sin(t * 24.0)
	var blink := time_left < 1.0 and fmod(t * 8.0, 1.0) < 0.5      # Warns that it's ending
	var body := Color(0.95, 0.15, 0.15) if blink else SKIN
	for side in [-1.0, 1.0]:
		var wy := -16.0 * flap
		var wing := PackedVector2Array([
			center + Vector2(6 * side, -4), center + Vector2(22 * side, -14 + wy * 0.6), center + Vector2(40 * side, -8 + wy),
			center + Vector2(33 * side, 2 + wy * 0.5), center + Vector2(25 * side, -1 + wy * 0.3), center + Vector2(18 * side, 7),
			center + Vector2(6 * side, 5)])
		c.draw_colored_polygon(wing, SKIN_SHADE)
		var wc := wing.duplicate()
		wc.append(wing[0])
		c.draw_polyline(wc, BLACK, 3.0, FighterArt.AA)
	c.draw_circle(center, 15.0, BLACK)
	c.draw_circle(center, 12.5, body)
	c.draw_circle(center + Vector2(-4, -4), 3.5, SKIN_HI)
	for ex in [-1.0, 1.0]:
		var ear := PackedVector2Array([center + Vector2(5 * ex, -9), center + Vector2(9 * ex, -22), center + Vector2(1 * ex, -11)])
		c.draw_colored_polygon(ear, body)
		c.draw_polyline(ear, BLACK, 2.0, FighterArt.AA)
	c.draw_circle(center + Vector2(5, -2), 2.2, Color.WHITE)
	c.draw_circle(center + Vector2(-2, -2), 2.2, Color.WHITE)
	c.draw_polyline(PackedVector2Array([center + Vector2(-3, 4), center + Vector2(2, 5), center + Vector2(6, 3)]), BLACK, 2.0, FighterArt.AA)
	# Still wearing the tie
	c.draw_colored_polygon(PackedVector2Array([center + Vector2(-2, 9), center + Vector2(3, 9), center + Vector2(1, 18)]), TIE)
