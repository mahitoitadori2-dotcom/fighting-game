class_name WarriorArt
extends RefCounted
## The Warrior: a body of BLACK living Void (same substance as Void Goo), a
## SILVER helmet with eyeholes, a SILVER pad on one shoulder, and a rough jagged
## metal shard for a sword (no crossguard). Flat cartoon, thick black outlines.
## Drawn facing RIGHT, origin = feet, about 64 x 128.
##
## No draw_set_transform here (the Character Select card scales us with it).

## PALETTE (static vars so a skin can swap them around a draw - GalaxySkin calls
## set_palette(GalaxySkin.WARRIOR) then set_palette(NORMAL_PALETTE) right after).
const NORMAL_PALETTE := {
	"VOID": Color(0.11, 0.09, 0.15), "VOID_SHADE": Color(0.03, 0.02, 0.05), "VOID_HI": Color(0.36, 0.22, 0.52),
	"VOID_GLOW": Color(0.58, 0.32, 0.90), "SILVER": Color(0.82, 0.85, 0.90), "SILVER_SHADE": Color(0.50, 0.54, 0.62),
	"SILVER_HI": Color(0.98, 0.99, 1.0), "BLADE": Color(0.70, 0.72, 0.76), "BLADE_SHADE": Color(0.46, 0.48, 0.53),
	"BLADE_EDGE": Color(0.93, 0.95, 0.98),
}
static var VOID := Color(0.11, 0.09, 0.15)
static var VOID_SHADE := Color(0.03, 0.02, 0.05)
static var VOID_HI := Color(0.36, 0.22, 0.52)
static var VOID_GLOW := Color(0.58, 0.32, 0.90)
static var SILVER := Color(0.82, 0.85, 0.90)
static var SILVER_SHADE := Color(0.50, 0.54, 0.62)
static var SILVER_HI := Color(0.98, 0.99, 1.0)
static var BLADE := Color(0.70, 0.72, 0.76)
static var BLADE_SHADE := Color(0.46, 0.48, 0.53)
static var BLADE_EDGE := Color(0.93, 0.95, 0.98)


static func set_palette(p: Dictionary) -> void:
	VOID = p["VOID"]
	VOID_SHADE = p["VOID_SHADE"]
	VOID_HI = p["VOID_HI"]
	VOID_GLOW = p["VOID_GLOW"]
	SILVER = p["SILVER"]
	SILVER_SHADE = p["SILVER_SHADE"]
	SILVER_HI = p["SILVER_HI"]
	BLADE = p["BLADE"]
	BLADE_SHADE = p["BLADE_SHADE"]
	BLADE_EDGE = p["BLADE_EDGE"]

const GRIP := Color(0.22, 0.17, 0.14)
const ROYAL := Color(1.0, 1.0, 1.0)
const ROYAL_SHADE := Color(0.85, 0.86, 0.80)
const ROYAL_GLOW := Color(1.0, 0.97, 0.80)
const BEAM_OUT := Color(0.38, 0.12, 0.60)
const BEAM_MID := Color(0.16, 0.04, 0.28)
const BEAM_CORE := Color(0.02, 0.0, 0.05)
const BLACK := Color(0, 0, 0)


static func draw(c: CanvasItem, w: Warrior) -> void:
	_draw_figure(c, {
		"t": w.anim_time, "ph": w.walk_phase, "floor": w.is_on_floor(),
		"swing": w.sword_swing, "block": w.block_amt, "perfect": w.perfect_flash,
		"grab_len": w.grab_len, "grab_h": w.wd.grab_height,
		"royal": w.royal_amt, "shadow": w.shadow_amt, "mask_off": w.mask_off,
		"beam_charge": w.beam_charge, "beam_fire": w.beam_fire, "beam_range": w.wd.beam_range,
		"snap": w.snap_t, "waves": w.spike_waves, "onsl": w.onslaught.flash_timer > 0.0,
		"sword_scale": w.sword_scale(), "sword_power": w.sword_power,
	})


## Idle pose for menus / Character Select.
static func draw_portrait(c: CanvasItem, t: float) -> void:
	_draw_figure(c, {"t": t})


static func _draw_figure(c: CanvasItem, s: Dictionary) -> void:
	var t: float = s.get("t", 0.0)
	var ph: float = s.get("ph", 0.0)
	var on_floor: bool = s.get("floor", true)
	var swing: float = s.get("swing", 0.0)
	var b: float = s.get("block", 0.0)
	var royal: float = s.get("royal", 0.0)
	var shadow: float = s.get("shadow", 0.0)
	var snap: float = s.get("snap", 0.0)

	# --- Behind the body: aura, Onslaught ring, spike bursts ---
	if royal > 0.0:
		var p := 0.5 + 0.5 * sin(t * 6.0)
		c.draw_circle(Vector2(0, -66), 64.0 + 6.0 * p, Color(ROYAL_GLOW.r, ROYAL_GLOW.g, ROYAL_GLOW.b, 0.16 * royal))
	if s.get("onsl", false):
		var pulse := 0.5 + 0.5 * sin(t * 40.0)
		c.draw_arc(Vector2(4, -78), 46.0 + 4.0 * pulse, 0.0, TAU, 40, Color(1.0, 0.55, 0.1, 0.5 + 0.5 * pulse), 6.0, true)
	for wv in s.get("waves", []):
		_spike_wave(c, wv)
	if shadow > 0.0:
		_shadow_aura(c, t, shadow)

	# --- Legs ---
	var sw := sin(ph) * 13.0
	var lift_f := maxf(0.0, cos(ph)) * 7.0
	var lift_b := maxf(0.0, -cos(ph)) * 7.0
	if not on_floor:
		sw = 7.0
		lift_f = 12.0
		lift_b = 4.0
	_leg(c, Vector2(-6, -52), Vector2(-8.0 - sw, -5.0 - lift_b), true, royal)
	_leg(c, Vector2(6, -52), Vector2(8.0 + sw, -5.0 - lift_f), false, royal)

	# --- Far arm (empty hand) ---
	var arm_sw := sin(ph) * 8.0 * (1.0 - maxf(absf(swing), b))
	var b_el := Vector2(-10.0 + arm_sw * 0.5, -74).lerp(Vector2(10, -72), b)
	var b_hand := Vector2(-9.0 + arm_sw, -55).lerp(Vector2(20, -80), b)
	_arm(c, Vector2(-4, -92), b_el, b_hand, true, royal)

	# --- Torso: void body with drips ---
	FighterArt.rrect(c, Rect2(-16, -100, 32, 48), VOID, VOID_SHADE, VOID_HI, 9.0, 4.0)
	c.draw_arc(Vector2(2, -80), 9.0, -2.4 + t * 1.5, -0.4 + t * 1.5, 10, VOID_GLOW, 2.0, true)   # Swirl
	c.draw_arc(Vector2(2, -80), 4.0, 0.6 - t * 2.0, 2.6 - t * 2.0, 8, VOID_HI, 2.0, true)
	for i in 3:
		var dx := -9.0 + float(i) * 8.0
		var dl := 5.0 + 4.0 * (0.5 + 0.5 * sin(t * 3.0 + float(i) * 2.1))
		_drip(c, Vector2(dx, -53), dl)
	if royal > 0.0:   # Royal Destiny: white shining chest armor
		var a := royal
		FighterArt.rrect(c, Rect2(-15, -99, 30, 32), Color(ROYAL.r, ROYAL.g, ROYAL.b, a), Color(ROYAL_SHADE.r, ROYAL_SHADE.g, ROYAL_SHADE.b, a), Color(1, 1, 1, a), 8.0, 3.5)
		c.draw_rect(Rect2(-15, -60, 30, 7), Color(ROYAL_SHADE.r, ROYAL_SHADE.g, ROYAL_SHADE.b, a))
		c.draw_line(Vector2(-4, -94), Vector2(-4, -72), Color(1, 0.95, 0.7, a), 2.0)

	# --- Head: SILVER helmet with eyeholes, or the bare void face (Shadow Swarm) ---
	if s.get("mask_off", false):
		_void_face(c, t, s.get("beam_charge", 0.0))
	else:
		_helmet(c, t)

	# --- Near arm + sword ---
	var shoulder := Vector2(4, -92)
	var hand: Vector2
	var blade_ang: float
	var idle_hand := Vector2(14.0 - arm_sw, -60)
	var idle_ang := -1.05
	if swing < 0.0:         # Wind-up: raise the sword back over the head
		var k := -swing
		hand = idle_hand.lerp(Vector2(-6, -116), k)
		blade_ang = lerpf(idle_ang, -2.3, k)
	else:                   # Swing through / recover
		hand = idle_hand.lerp(Vector2(38, -82), swing)
		blade_ang = lerpf(idle_ang, 0.25, swing)
	hand = hand.lerp(Vector2(22, -88), b)
	blade_ang = lerpf(blade_ang, -1.5, b)
	if snap > 0.0:          # Snap: hand up, sword lowered
		hand = hand.lerp(Vector2(16, -122), minf(snap * 2.0, 1.0))
		blade_ang = lerpf(blade_ang, 0.9, minf(snap * 2.0, 1.0))
	var elbow := (shoulder + hand) * 0.5 + Vector2(4, 8)
	if swing > 0.6:
		_swing_trail(c, swing)
	var power: int = s.get("sword_power", 0)
	if power > 0:                                   # Empowered blade: void glow around it
		var tip := hand + Vector2(66.0 * float(s.get("sword_scale", 1.0)), 0).rotated(blade_ang)
		var pulse := 0.6 + 0.4 * sin(t * 8.0)
		c.draw_line(hand, tip, Color(0.6, 0.3, 1.0, 0.25 * pulse), 18.0 + 6.0 * float(power), true)
		c.draw_line(hand, tip, Color(0.85, 0.7, 1.0, 0.35 * pulse), 8.0, true)
	_sword(c, hand, blade_ang, float(s.get("sword_scale", 1.0)))
	_arm(c, shoulder, elbow, hand, false, royal)
	_shoulder_pad(c, royal)
	if snap > 0.5:
		_snap_sparks(c, hand, t)

	# --- Shadow form overlay (Eternal Grasp) ---
	if shadow > 0.0:
		_shadow_body(c, t, shadow)

	# --- Clinging Grab tentacle ---
	var gl: float = s.get("grab_len", 0.0)
	if gl > 1.0:
		_tentacle(c, t, Vector2(12, -82), Vector2(24.0 + gl, s.get("grab_h", -80.0)))

	# --- Shadow Swarm beam ---
	var bf: float = s.get("beam_fire", 0.0)
	if bf > 0.0:
		_beam(c, t, bf, s.get("beam_range", 900.0))

	# --- Block (purple arc in front) ---
	if b > 0.05:
		var col := Color(0.70, 0.45, 1.0, 0.85 * b)
		if s.get("perfect", 0.0) > 0.0:
			col = Color(1, 1, 1, 1)
		c.draw_arc(Vector2(10, -70), 50.0, -1.0, 1.0, 20, Color(0, 0, 0, b), 11.0, true)
		c.draw_arc(Vector2(10, -70), 50.0, -1.0, 1.0, 20, col, 6.0, true)


# ============================================================
# BODY PARTS
# ============================================================
static func _leg(c: CanvasItem, hip: Vector2, foot: Vector2, far: bool, royal: float) -> void:
	var base := VOID_SHADE if far else VOID
	var knee := (hip + foot) * 0.5 + Vector2(7, 0)
	FighterArt.limb(c, hip, knee, 12.0, base, VOID_SHADE, VOID_HI)
	FighterArt.limb(c, knee, foot + Vector2(0, -4), 11.0, base, VOID_SHADE, VOID_HI)
	c.draw_circle(knee, 2.0, VOID_GLOW)
	# Void "foot": a puddle-like blob
	var fp := foot + Vector2(4, -1)
	c.draw_circle(fp, 9.5, BLACK)
	c.draw_circle(fp, 7.0, base)
	c.draw_circle(fp + Vector2(-2, -2), 2.0, VOID_HI)
	if royal > 0.0:   # White shin guard
		var mid := knee.lerp(foot, 0.5)
		c.draw_circle(mid, 8.0, Color(0, 0, 0, royal))
		c.draw_circle(mid, 6.0, Color(ROYAL.r, ROYAL.g, ROYAL.b, royal))


static func _arm(c: CanvasItem, shoulder: Vector2, elbow: Vector2, hand: Vector2, far: bool, royal: float) -> void:
	var base := VOID_SHADE if far else VOID
	FighterArt.limb(c, shoulder, elbow, 9.0, base, VOID_SHADE, VOID_HI)
	FighterArt.limb(c, elbow, hand, 10.0, base, VOID_SHADE, VOID_HI)
	c.draw_circle(elbow, 1.8, VOID_GLOW)
	c.draw_circle(hand, 8.5, BLACK)
	c.draw_circle(hand, 6.0, base)
	if royal > 0.0:   # White gauntlet
		c.draw_circle(hand, 9.0, Color(0, 0, 0, royal))
		c.draw_circle(hand, 6.5, Color(ROYAL.r, ROYAL.g, ROYAL.b, royal))
		c.draw_circle(hand + Vector2(-2, -2), 2.0, Color(ROYAL_GLOW.r, ROYAL_GLOW.g, ROYAL_GLOW.b, royal))


static func _drip(c: CanvasItem, top: Vector2, length: float) -> void:
	var tip := top + Vector2(0, length)
	c.draw_colored_polygon(PackedVector2Array([top + Vector2(-3, 0), top + Vector2(3, 0), tip]), VOID_SHADE)
	c.draw_circle(tip, 2.4, VOID_SHADE)
	c.draw_circle(tip + Vector2(-0.8, -0.8), 0.9, VOID_HI)


static func _helmet(c: CanvasItem, t: float) -> void:
	var hc := Vector2(3, -113)
	FighterArt.ball(c, hc, 15.0, SILVER, SILVER_SHADE, SILVER_HI)
	# Crest ridge
	c.draw_line(Vector2(-9, -124), Vector2(8, -127), SILVER_SHADE, 3.0)
	# Eyeholes (black slots with a faint void glow inside)
	var glow := 0.55 + 0.45 * sin(t * 3.0)
	for ex in [7.0, 14.0]:
		var r := Rect2(ex, -118, 5, 6)
		c.draw_colored_polygon(FighterArt.rrect_points(r.grow(1.5), 2.0), BLACK)
		c.draw_colored_polygon(FighterArt.rrect_points(r, 1.5), VOID_SHADE)
		c.draw_circle(r.get_center(), 1.4, Color(VOID_GLOW.r, VOID_GLOW.g, VOID_GLOW.b, glow))
	# Nose guard + rim
	c.draw_rect(Rect2(12.0, -119, 2, 11), SILVER_SHADE)
	c.draw_arc(hc, 15.0, 0.35, 2.6, 12, SILVER_SHADE, 3.0, true)


static func _void_face(c: CanvasItem, t: float, charge: float) -> void:
	var hc := Vector2(3, -113)
	c.draw_circle(hc, 17.5, BLACK)
	c.draw_circle(hc, 15.0, VOID)
	c.draw_circle(hc + Vector2(-4, -4), 4.0, VOID_HI)
	var g := 0.6 + 0.4 * sin(t * 18.0)
	c.draw_circle(Vector2(9, -116), 2.6, Color(0.85, 0.65, 1.0, g))
	c.draw_circle(Vector2(15, -116), 2.6, Color(0.85, 0.65, 1.0, g))
	c.draw_line(Vector2(7, -107), Vector2(17, -108), Color(0.7, 0.4, 1.0, g), 2.5)
	if charge > 0.0:   # Shadow Swarm charging in the face
		var fc := Vector2(17, -112)
		c.draw_circle(fc, 8.0 + 22.0 * charge, Color(BEAM_OUT.r, BEAM_OUT.g, BEAM_OUT.b, 0.35 * charge))
		c.draw_circle(fc, 4.0 + 8.0 * charge, Color(0.8, 0.6, 1.0, 0.8 * charge))
		for i in 6:
			var a := TAU * float(i) / 6.0 + t * 6.0
			var o := Vector2.from_angle(a) * (40.0 * (1.0 - charge) + 10.0)
			c.draw_line(fc + o, fc + o * 0.6, Color(0.75, 0.5, 1.0, charge), 2.0)


static func _shoulder_pad(c: CanvasItem, royal: float) -> void:
	var pts := PackedVector2Array([
		Vector2(-9, -96), Vector2(-2, -106), Vector2(10, -107), Vector2(19, -99),
		Vector2(18, -89), Vector2(4, -87), Vector2(-8, -90)])
	c.draw_colored_polygon(pts, SILVER_SHADE)
	c.draw_colored_polygon(PackedVector2Array([Vector2(-6, -96), Vector2(-1, -104), Vector2(10, -105), Vector2(16, -99), Vector2(14, -93), Vector2(-4, -93)]), SILVER)
	c.draw_line(Vector2(-1, -102), Vector2(9, -103), SILVER_HI, 2.5)
	c.draw_circle(Vector2(0, -92), 1.6, SILVER_SHADE)
	c.draw_circle(Vector2(12, -92), 1.6, SILVER_SHADE)
	var closed := pts.duplicate()
	closed.append(pts[0])
	c.draw_polyline(closed, BLACK, 3.5, true)
	if royal > 0.0:
		c.draw_polyline(closed, Color(ROYAL_GLOW.r, ROYAL_GLOW.g, ROYAL_GLOW.b, 0.6 * royal), 1.5, true)


# ============================================================
# SWORD: rough jagged metal shard, NO crossguard
# ============================================================
const _BLADE_PTS := [
	Vector2(10, -5), Vector2(19, -6), Vector2(25, -3.5), Vector2(33, -7), Vector2(41, -5),
	Vector2(47, -6.5), Vector2(55, -3), Vector2(66, 0),
	Vector2(56, 3), Vector2(49, 5.5), Vector2(42, 3.5), Vector2(34, 6.5), Vector2(26, 4),
	Vector2(18, 6), Vector2(10, 5)]


static func _xf(pts: Array, origin: Vector2, ang: float) -> PackedVector2Array:
	var out := PackedVector2Array()
	for p in pts:
		out.append(origin + (p as Vector2).rotated(ang))
	return out


static func _sword(c: CanvasItem, hand: Vector2, ang: float, sc: float = 1.0) -> void:
	if sc != 1.0:
		_sword_scaled(c, hand, ang, sc)
		return
	_sword_base(c, hand, ang)


## Bigger blade (Sword Power): same shape stretched along the blade, a bit thicker.
static func _sword_scaled(c: CanvasItem, hand: Vector2, ang: float, sc: float) -> void:
	var k := Vector2(sc, 1.0 + (sc - 1.0) * 0.6)
	var blade := PackedVector2Array()
	for p in _BLADE_PTS:
		blade.append(hand + ((p as Vector2) * k).rotated(ang))
	var g0 := hand + Vector2(-7, 0).rotated(ang)
	var g1 := hand + Vector2(11, 0).rotated(ang)
	c.draw_line(g0, g1, BLACK, 9.0, true)
	c.draw_line(g0, g1, GRIP, 5.0, true)
	c.draw_colored_polygon(blade, BLADE)
	var edge := PackedVector2Array()
	for p in [Vector2(14, -3.5), Vector2(25, -2), Vector2(33, -4.8), Vector2(47, -4.2), Vector2(60, -1)]:
		edge.append(hand + ((p as Vector2) * k).rotated(ang))
	c.draw_polyline(edge, Color(0.85, 0.7, 1.0), 2.5, true)
	var closed := blade.duplicate()
	closed.append(blade[0])
	c.draw_polyline(closed, BLACK, 3.5, true)


static func _sword_base(c: CanvasItem, hand: Vector2, ang: float) -> void:
	# Grip (wrapped, short) - straight into the blade, no guard
	var g0 := hand + Vector2(-7, 0).rotated(ang)
	var g1 := hand + Vector2(11, 0).rotated(ang)
	c.draw_line(g0, g1, BLACK, 9.0, true)
	c.draw_line(g0, g1, GRIP, 5.0, true)
	for i in 3:
		var p := hand + Vector2(-3.0 + float(i) * 5.0, 0).rotated(ang)
		var n := Vector2(0, 3).rotated(ang)
		c.draw_line(p - n, p + n + Vector2(2, 0).rotated(ang), Color(0.1, 0.08, 0.07), 1.5)
	# Blade
	var blade := _xf(_BLADE_PTS, hand, ang)
	c.draw_colored_polygon(blade, BLADE)
	var lower := _xf([Vector2(10, 0.5), Vector2(66, 0), Vector2(56, 3), Vector2(49, 5.5), Vector2(42, 3.5),
		Vector2(34, 6.5), Vector2(26, 4), Vector2(18, 6), Vector2(10, 5)], hand, ang)
	c.draw_colored_polygon(lower, BLADE_SHADE)
	var edge := _xf([Vector2(14, -3.5), Vector2(25, -2), Vector2(33, -4.8), Vector2(47, -4.2), Vector2(60, -1)], hand, ang)
	c.draw_polyline(edge, BLADE_EDGE, 2.0, true)
	var nick := _xf([Vector2(30, 1), Vector2(36, -1)], hand, ang)        # Scratches
	c.draw_line(nick[0], nick[1], BLADE_SHADE, 1.5)
	var closed := blade.duplicate()
	closed.append(blade[0])
	c.draw_polyline(closed, BLACK, 3.5, true)


static func _swing_trail(c: CanvasItem, swing: float) -> void:
	var a := (swing - 0.6) / 0.4
	c.draw_arc(Vector2(10, -88), 62.0, -1.6, 0.4, 16, Color(1, 1, 1, 0.5 * a), 10.0, true)
	c.draw_arc(Vector2(10, -88), 62.0, -1.2, 0.4, 16, Color(0.75, 0.6, 1.0, 0.6 * a), 4.0, true)


static func _snap_sparks(c: CanvasItem, hand: Vector2, t: float) -> void:
	for i in 6:
		var a := TAU * float(i) / 6.0 + t * 4.0
		c.draw_line(hand + Vector2.from_angle(a) * 10.0, hand + Vector2.from_angle(a) * 22.0, Color(0.85, 0.7, 1.0), 3.0)


# ============================================================
# MOVE VISUALS
# ============================================================
static func _tentacle(c: CanvasItem, t: float, from: Vector2, to: Vector2) -> void:
	var pts := PackedVector2Array()
	var n := 16
	var dir := (to - from).normalized()
	var perp := Vector2(-dir.y, dir.x)
	for i in n + 1:
		var u := float(i) / float(n)
		var wobble := sin(u * 9.0 - t * 22.0) * 7.0 * sin(u * PI)
		pts.append(from.lerp(to, u) + perp * wobble)
	c.draw_polyline(pts, BLACK, 15.0, true)
	c.draw_polyline(pts, VOID, 9.0, true)
	c.draw_polyline(pts, VOID_HI, 2.0, true)
	# Clinging claw at the tip
	for k: float in [-1.0, 0.0, 1.0]:
		var a: float = dir.angle() + k * 0.7
		var hook := to + Vector2.from_angle(a) * 14.0
		var curl := hook + Vector2.from_angle(a + 1.6 * signf(k + 0.01)) * 6.0
		c.draw_polyline(PackedVector2Array([to, hook, curl]), BLACK, 7.0, true)
		c.draw_polyline(PackedVector2Array([to, hook, curl]), VOID_GLOW, 3.0, true)
	c.draw_circle(to, 8.0, BLACK)
	c.draw_circle(to, 5.5, VOID)


static func _beam(c: CanvasItem, t: float, k: float, length: float) -> void:
	var o := Vector2(16, -112)
	var hh := 26.0 * (0.55 + 0.45 * k)
	var top := PackedVector2Array()
	var bot := PackedVector2Array()
	var x := 0.0
	var i := 0
	while x <= length:
		var j := sin(float(i) * 1.7 + t * 40.0) * 5.0
		top.append(o + Vector2(x, -hh + j))
		bot.append(o + Vector2(x, hh - j))
		x += 30.0
		i += 1
	top.append(o + Vector2(length + 30.0, 0))
	bot.reverse()
	top.append_array(bot)
	c.draw_colored_polygon(top, Color(BEAM_OUT.r, BEAM_OUT.g, BEAM_OUT.b, 0.95))
	var closed := top.duplicate()
	closed.append(top[0])
	c.draw_polyline(closed, BLACK, 4.0, true)
	FighterArt.beam_gradient(c, o, length, hh * 0.8, BEAM_MID, BEAM_CORE)       # Purple -> black gradient
	c.draw_line(o + Vector2(0, -hh * 0.4), o + Vector2(length, -hh * 0.4), Color(0.8, 0.6, 1.0, 0.8), 2.0)
	for s in 10:
		var px := fmod(float(s) * 97.0 + t * 900.0, length)
		c.draw_circle(o + Vector2(px, sin(float(s) * 3.1) * hh * 0.7), 2.5, Color(0.85, 0.7, 1.0))
	c.draw_circle(o, hh + 6.0, Color(BEAM_OUT.r, BEAM_OUT.g, BEAM_OUT.b, 0.6))
	c.draw_circle(o, hh * 0.6, Color(0.85, 0.7, 1.0))


static func _spike_wave(c: CanvasItem, wv: Dictionary) -> void:
	var age: float = wv["age"]
	var k := age / 0.35
	var grow := 1.0 - pow(1.0 - clampf(k / 0.45, 0.0, 1.0), 3.0)
	var alpha := 1.0 - clampf((k - 0.6) / 0.4, 0.0, 1.0)
	var r: float = wv["range"]
	var center := Vector2(0, -64)
	var n: int = wv["count"]
	for i in n:
		var a: float = wv["rot"] + TAU * float(i) / float(n)
		var d := Vector2.from_angle(a)
		var p := Vector2(-d.y, d.x)
		var base := center + d * 14.0
		var tip := center + d * (14.0 + (r - 14.0) * grow)
		if (tip - base).length() > 3.0:
			FighterArt.curved_spike(c, base, tip, 7.0, Color(VOID_HI.r, VOID_HI.g, VOID_HI.b, alpha), Color(VOID.r, VOID.g, VOID.b, alpha), 0.3, 2.5)


static func _shadow_aura(c: CanvasItem, t: float, a: float) -> void:
	var pts := PackedVector2Array()
	for i in 20:
		var ang := TAU * float(i) / 20.0
		var r := 52.0 + (12.0 if i % 2 == 0 else 0.0) + 4.0 * sin(t * 12.0 + float(i))
		pts.append(Vector2(0, -64) + Vector2(cos(ang) * r * 0.8, sin(ang) * r))
	c.draw_colored_polygon(pts, Color(0.02, 0.0, 0.04, 0.55 * a))


static func _shadow_body(c: CanvasItem, t: float, a: float) -> void:
	# Body melts into a solid shadow silhouette with glowing eyes
	var pts := PackedVector2Array()
	for i in 18:
		var ang := TAU * float(i) / 18.0
		var r := 40.0 + (8.0 if i % 2 == 0 else 0.0) + 3.0 * sin(t * 15.0 + float(i) * 1.3)
		pts.append(Vector2(0, -66) + Vector2(cos(ang) * r * 0.62, sin(ang) * r * 1.5))
	c.draw_colored_polygon(pts, Color(0.01, 0.0, 0.03, 0.88 * a))
	var g := 0.6 + 0.4 * sin(t * 20.0)
	c.draw_circle(Vector2(9, -114), 3.0, Color(0.85, 0.6, 1.0, a * g))
	c.draw_circle(Vector2(16, -114), 3.0, Color(0.85, 0.6, 1.0, a * g))
