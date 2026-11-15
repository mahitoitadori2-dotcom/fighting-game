class_name CraterArt
extends RefCounted
## TERRA CRATERUM art: the lava creatures, the Kharlemings of the crashed ship and their two
## bosses. Flat cartoon, thick black outlines, drawn facing RIGHT, origin = feet.
##   golem      LAVA GOLEM         black basalt boulders, glowing cracks, a magma core
##   demon      LAVA DEMON         horned magma skin, claws, a dripping tail
##   goblin     LAVA GOBLIN        a small hunched goblin with a magma bomb
##   fragmenter ANCIENT FRAGMENTER rusted hull plates of the ship orbiting a cyan core
##   kharleming FULL / MASTER       a big ten-legged Kharleming (Master: wings + a void-goo sac)
##   melter     LAVA MELTER        a giant pillar of lava with rock plates and two rock eyes
##   lord       KHARLEMING LORD    all of them in one: horns, feathers, a scorpion tail

const BLACK := Color(0, 0, 0)
const BASALT := Color(0.13, 0.12, 0.13)
const BASALT_HI := Color(0.26, 0.24, 0.25)
const LAVA := Color(1.0, 0.45, 0.08)
const LAVA_HOT := Color(1.0, 0.82, 0.30)
const LAVA_DARK := Color(0.62, 0.12, 0.04)
const METAL := Kharleming.METAL
const METAL_SHADE := Kharleming.METAL_SHADE
const METAL_HI := Kharleming.METAL_HI
const RUST := Kharleming.RUST
const KEYE := Kharleming.EYE
const GOO := Color(0.55, 0.25, 0.85)
const CYAN := Color(0.35, 0.95, 1.0)


static func _pose(s: Dictionary) -> String:
	return String(s.get("pose", "idle"))


static func _glow_crack(c: CanvasItem, pts: PackedVector2Array, t: float, w: float = 3.0) -> void:
	var a := 0.75 + 0.25 * sin(t * 4.0)
	c.draw_polyline(pts, Color(LAVA.r, LAVA.g, LAVA.b, a), w + 2.0)
	c.draw_polyline(pts, Color(LAVA_HOT.r, LAVA_HOT.g, LAVA_HOT.b, a), w * 0.5)


static func _rock(c: CanvasItem, center: Vector2, r: Vector2, seed_v: int, col: Color = BASALT) -> void:
	var pts := PackedVector2Array()
	for i in 9:
		var a := TAU * float(i) / 9.0
		var j := 0.82 + 0.18 * sin(float(seed_v) * 1.7 + float(i) * 2.3)
		pts.append(center + Vector2(cos(a) * r.x, sin(a) * r.y) * j)
	c.draw_colored_polygon(pts, col)
	c.draw_line(center + Vector2(-r.x * 0.4, -r.y * 0.5), center + Vector2(r.x * 0.1, -r.y * 0.7), BASALT_HI, 3.0)
	FighterArt.outline(c, pts, 3.5)


# ============================================================
# LAVA GOLEM (~150 tall)
# ============================================================
static func golem(c: CanvasItem, s: Dictionary) -> void:
	var t: float = s.get("t", 0.0)
	var pose := _pose(s)
	var walk: float = s.get("walk", 0.0)
	var bob := absf(sin(walk * 0.5)) * 3.0
	var slam := pose == "slam"
	var lift := pose == "slam_tele"
	# Legs: two short boulder stumps
	var step := sin(walk * 0.5) * 8.0
	_rock(c, Vector2(-20 + step, -22), Vector2(22, 24), 1)
	_rock(c, Vector2(22 - step, -22), Vector2(22, 24), 2)
	# Body: a big boulder with a magma core
	var body := Vector2(0, -88 - bob)
	_rock(c, body, Vector2(52, 50), 3)
	c.draw_circle(body + Vector2(8, 4), 18.0, Color(LAVA.r, LAVA.g, LAVA.b, 0.4 + 0.2 * sin(t * 3.0)))
	c.draw_circle(body + Vector2(8, 4), 11.0, LAVA_HOT)
	_glow_crack(c, PackedVector2Array([body + Vector2(-30, -30), body + Vector2(-12, -8), body + Vector2(-22, 20), body + Vector2(-8, 38)]), t)
	_glow_crack(c, PackedVector2Array([body + Vector2(26, -36), body + Vector2(16, -14), body + Vector2(30, 10)]), t)
	# Head: a small rock with two lava eyes
	var head := body + Vector2(6, -60)
	_rock(c, head, Vector2(24, 18), 4)
	for ex: float in [2.0, 14.0]:
		c.draw_circle(head + Vector2(ex, -2), 4.0, LAVA_HOT)
	# Arms: huge fists (raised for the slam)
	var fy := -150.0 if lift else (-30.0 if slam else -70.0)
	_rock(c, Vector2(-54, fy - bob), Vector2(22, 22), 5)
	_rock(c, Vector2(56, fy - bob), Vector2(24, 24), 6)
	if slam:
		for i in 5:
			c.draw_circle(Vector2(56 + float(i) * 18.0, -4), 8.0 - float(i), Color(LAVA.r, LAVA.g, LAVA.b, 0.6))


# ============================================================
# LAVA DEMON (~130 tall)
# ============================================================
static func demon(c: CanvasItem, s: Dictionary) -> void:
	var t: float = s.get("t", 0.0)
	var pose := _pose(s)
	var walk: float = s.get("walk", 0.0)
	var sw := sin(walk) * 10.0
	# Tail (dripping)
	var tail := PackedVector2Array([Vector2(-12, -62), Vector2(-40, -54), Vector2(-58, -70 + sin(t * 3.0) * 6.0), Vector2(-66, -88)])
	c.draw_polyline(tail, BLACK, 10.0)
	c.draw_polyline(tail, LAVA_DARK, 6.0)
	c.draw_circle(tail[3], 6.0, LAVA)
	# Legs (digitigrade)
	for d: float in [-1.0, 1.0]:
		var hip := Vector2(d * 8.0, -58)
		var knee := Vector2(d * 6.0 + sw * d * 0.5 + 8.0, -32)
		var foot := Vector2(d * 10.0 + sw * d, -2)
		FighterArt.limb(c, hip, knee, 11.0, LAVA_DARK, LAVA_DARK.darkened(0.4), LAVA)
		FighterArt.limb(c, knee, foot, 9.0, LAVA_DARK, LAVA_DARK.darkened(0.4), LAVA)
	# Torso
	var torso := Rect2(-18, -104, 36, 50)
	FighterArt.rrect(c, torso, Color(0.78, 0.20, 0.06), LAVA_DARK, LAVA_HOT, 10.0, 4.0)
	_glow_crack(c, PackedVector2Array([Vector2(-8, -98), Vector2(0, -84), Vector2(-6, -68)]), t, 2.5)
	# Head with horns
	var head := Vector2(4, -118)
	FighterArt.ball(c, head, 15.0, Color(0.80, 0.22, 0.07), LAVA_DARK, LAVA_HOT)
	for d: float in [-1.0, 1.0]:
		FighterArt.curved_spike(c, head + Vector2(d * 8.0, -10), head + Vector2(d * 18.0 + 4.0, -34), 5.0, BASALT, BASALT_HI, 0.3 * d, 2.5)
	c.draw_circle(head + Vector2(8, -2), 3.0, LAVA_HOT)
	c.draw_line(head + Vector2(2, 6), head + Vector2(12, 6), BLACK, 2.0)
	# Arms with claws (swipe pose)
	var swipe := pose.begins_with("claw")
	var hand := Vector2(34, -96) if swipe else Vector2(20, -64)
	FighterArt.limb(c, Vector2(12, -96), hand, 9.0, Color(0.78, 0.20, 0.06), LAVA_DARK, LAVA)
	for k in 3:
		var a := -0.5 + float(k) * 0.5
		c.draw_line(hand, hand + Vector2.from_angle(a) * 14.0, BLACK, 4.0)
		c.draw_line(hand, hand + Vector2.from_angle(a) * 14.0, LAVA_HOT, 2.0)
	if pose == "spit":
		c.draw_circle(head + Vector2(20, 4), 9.0, Color(LAVA.r, LAVA.g, LAVA.b, 0.7))


# ============================================================
# LAVA GOBLIN (~80 tall)
# ============================================================
static func goblin(c: CanvasItem, s: Dictionary) -> void:
	var t: float = s.get("t", 0.0)
	var pose := _pose(s)
	var walk: float = s.get("walk", 0.0)
	var sw := sin(walk * 1.4) * 7.0
	for d: float in [-1.0, 1.0]:
		FighterArt.limb(c, Vector2(d * 6.0, -34), Vector2(d * 8.0 + sw * d, -2), 7.0, BASALT, BLACK, BASALT_HI)
	var body := EnemyArt.ellipse_points(Vector2(0, -46), 16, 18, 14)
	c.draw_colored_polygon(body, Color(0.22, 0.12, 0.08))
	FighterArt.outline(c, body, 3.0)
	_glow_crack(c, PackedVector2Array([Vector2(-6, -58), Vector2(0, -46), Vector2(-4, -34)]), t, 2.0)
	var head := Vector2(6, -68)
	FighterArt.ball(c, head, 12.0, Color(0.30, 0.16, 0.10), Color(0.16, 0.08, 0.05), Color(0.5, 0.3, 0.2))
	for d: float in [-1.0, 1.0]:                                   # Big pointed ears
		var ear := PackedVector2Array([head + Vector2(d * 8.0, -4), head + Vector2(d * 26.0, -14), head + Vector2(d * 10.0, 4)])
		c.draw_colored_polygon(ear, Color(0.30, 0.16, 0.10))
		FighterArt.outline(c, ear, 2.5)
	c.draw_circle(head + Vector2(5, -2), 2.8, LAVA_HOT)
	c.draw_line(head + Vector2(0, 6), head + Vector2(12, 4), BLACK, 2.0)
	# The magma bomb in its hand (raised to throw)
	var bomb := Vector2(18, -84) if pose.begins_with("throw") else Vector2(16, -46)
	FighterArt.limb(c, Vector2(8, -54), bomb, 5.0, Color(0.30, 0.16, 0.10), BLACK, BASALT_HI)
	c.draw_circle(bomb, 8.0, BLACK)
	c.draw_circle(bomb, 6.0, LAVA)
	c.draw_circle(bomb + Vector2(-2, -2), 2.5, LAVA_HOT)


# ============================================================
# ANCIENT FRAGMENTER (~110, floating)
# ============================================================
static func fragmenter(c: CanvasItem, s: Dictionary) -> void:
	var t: float = s.get("t", 0.0)
	var pose := _pose(s)
	var spread := 1.6 if pose == "burst" else (0.7 if pose == "burst_tele" else 1.0)
	var core := Vector2(0, -70 + sin(t * 2.0) * 6.0)
	c.draw_colored_polygon(EnemyArt.ellipse_points(Vector2(0, -2), 26, 5, 12), Color(0, 0, 0, 0.3))
	# Cables hanging from the core
	for i in 3:
		var cx := -10.0 + float(i) * 10.0
		c.draw_polyline(PackedVector2Array([core + Vector2(cx, 10), core + Vector2(cx + sin(t * 3.0 + float(i)) * 6.0, 34), core + Vector2(cx, 52)]), BLACK, 3.0)
	# Hull plates orbiting the core
	for i in 6:
		var a := t * 0.9 + TAU * float(i) / 6.0
		var p := core + Vector2(cos(a) * 34.0, sin(a) * 22.0) * spread
		var plate := PackedVector2Array([p + Vector2(-12, -8).rotated(a), p + Vector2(12, -10).rotated(a), p + Vector2(10, 9).rotated(a), p + Vector2(-11, 7).rotated(a)])
		c.draw_colored_polygon(plate, METAL_SHADE if i % 2 == 0 else RUST.darkened(0.2))
		FighterArt.outline(c, plate, 2.5)
		c.draw_circle(p, 1.6, METAL_HI)
	# The cyan core (an old ship engine cell)
	c.draw_circle(core, 20.0, Color(CYAN.r, CYAN.g, CYAN.b, 0.18 + 0.1 * sin(t * 5.0)))
	c.draw_circle(core, 12.0, BLACK)
	c.draw_circle(core, 9.0, CYAN)
	c.draw_circle(core + Vector2(-3, -3), 3.0, Color.WHITE)


# ============================================================
# FULL / MASTER KHARLEMING (big, ten legs; Master: wings + goo sac)
# ============================================================
static func kharleming(c: CanvasItem, s: Dictionary, master: bool) -> void:
	var t: float = s.get("t", 0.0)
	var pose := _pose(s)
	var moving: bool = s.get("moving", false)
	var dead: bool = s.get("dead", false)
	var sk := t * (20.0 if moving else 5.0)
	var body_c := Vector2(0, -36 + (absf(sin(sk)) * 2.0 if moving else 0.0))
	if master:                                                     # Wings (behind)
		var flap := sin(t * 14.0) * 0.4 if not dead else 0.0
		for d: float in [-1.0, 1.0]:
			var root := body_c + Vector2(-6, -18)
			var tip := root + Vector2.from_angle(-PI * 0.5 + d * 0.9 + flap * d) * 64.0
			var wing := PackedVector2Array([root, tip, root + Vector2.from_angle(-PI * 0.5 + d * 1.4 + flap * d) * 44.0])
			c.draw_colored_polygon(wing, Color(0.70, 0.78, 0.86, 0.55))
			FighterArt.outline(c, wing, 2.5)
			c.draw_line(root, tip, METAL_SHADE, 2.0)
	# Ten legs (5 per side)
	for i in 10:
		var side := -1.0 if i < 5 else 1.0
		var k := float(i % 5)
		var hip := body_c + Vector2(-20.0 + k * 10.0, 8)
		var lift := sin(sk + k * 1.7 + (PI if side > 0.0 else 0.0)) * 4.0
		var knee := hip + Vector2((-18.0 + k * 9.0) + side * 4.0, -16.0 + lift)
		var foot := Vector2(hip.x + (-26.0 + k * 13.0), minf(lift, 0.0))
		var col := METAL_SHADE if side < 0.0 else METAL
		c.draw_line(hip, knee, BLACK, 7.0)
		c.draw_line(knee, foot, BLACK, 6.0)
		c.draw_line(hip, knee, col, 4.0)
		c.draw_line(knee, foot, col, 3.0)
		c.draw_circle(knee, 3.0, RUST)
	# Dome
	var dome := EnemyArt.ellipse_points(body_c, 34, 22, 20)
	var cols := PackedColorArray()
	for p in dome:
		cols.append(METAL_HI.lerp(METAL_SHADE, clampf((p.y - body_c.y + 16.0) / 38.0, 0.0, 1.0)))
	c.draw_polygon(dome, cols)
	c.draw_line(body_c + Vector2(-30, 4), body_c + Vector2(30, 4), METAL_SHADE, 3.0)
	for k2 in 5:
		c.draw_circle(body_c + Vector2(-20 + float(k2) * 9.0, -10), 1.8, METAL_SHADE)
	c.draw_circle(body_c + Vector2(-12, 0), 5.0, RUST)
	FighterArt.outline(c, dome, 3.5)
	if master:                                                     # Void-goo sac under the dome
		c.draw_circle(body_c + Vector2(-4, 18), 11.0, BLACK)
		c.draw_circle(body_c + Vector2(-4, 18), 9.0, Color(GOO.r, GOO.g, GOO.b, 0.9))
		c.draw_circle(body_c + Vector2(-7, 15), 3.0, Color(0.85, 0.65, 1.0))
	# Mandibles + eye
	var front := body_c + Vector2(32, 4)
	var open := 6.0 if pose.begins_with("spit") or pose.begins_with("bite") else 0.0
	c.draw_line(front, front + Vector2(12, 8 + open), BLACK, 4.0)
	c.draw_line(front + Vector2(0, -3), front + Vector2(12, -8 - open), BLACK, 4.0)
	var eye := body_c + Vector2(20, -4)
	if dead:
		EnemyArt.ko_eye(c, eye, 6.0, t)
	else:
		c.draw_circle(eye, 11.0, Color(KEYE.r, KEYE.g, KEYE.b, 0.25))
		c.draw_circle(eye, 7.0, BLACK)
		c.draw_circle(eye, 5.0, Color(0.85, 0.4, 1.0) if master else KEYE)
		c.draw_circle(eye + Vector2(-1.5, -1.5), 1.5, Color.WHITE)


# ============================================================
# LAVA MELTER (boss, ~380 tall): a giant pillar of lava with rock plates + rock eyes
# ============================================================
static func melter(c: CanvasItem, s: Dictionary) -> void:
	var t: float = s.get("t", 0.0)
	var pose := _pose(s)
	var raging: bool = s.get("raging", false)
	var h := 380.0
	var w := 120.0
	var sway := sin(t * 1.2) * 6.0
	# Glow
	c.draw_circle(Vector2(0, -h * 0.5), 180.0 + 10.0 * sin(t * 2.0), Color(LAVA.r, LAVA.g, LAVA.b, 0.10 if not raging else 0.18))
	# The lava pillar (wobbly sides, molten gradient)
	var pts := PackedVector2Array()
	var cols := PackedColorArray()
	for i in 13:                                                    # Left side, bottom -> top
		var k := float(i) / 12.0
		pts.append(Vector2(-w * (1.0 - 0.25 * k) + sin(t * 3.0 + k * 9.0) * 6.0 + sway * k, -h * k))
		cols.append(LAVA_DARK.lerp(LAVA, k))
	for i in 13:                                                    # Right side, top -> bottom
		var k := 1.0 - float(i) / 12.0
		pts.append(Vector2(w * (1.0 - 0.25 * k) + sin(t * 2.6 + k * 8.0 + 1.0) * 6.0 + sway * k, -h * k))
		cols.append(LAVA_DARK.lerp(LAVA_HOT if raging else LAVA, k))
	c.draw_polygon(pts, cols)
	FighterArt.outline(c, pts, 5.0)
	# Drips running down
	for i in 5:
		var dx := -w * 0.6 + float(i) * w * 0.3
		var dy := -h * fmod(t * 0.25 + float(i) * 0.37, 1.0)
		c.draw_circle(Vector2(dx + sway * 0.5, dy), 7.0, LAVA_HOT)
	# Rock plates stuck in the lava
	for i in 4:
		_rock(c, Vector2(-w * 0.55 + float(i % 2) * w * 1.1, -h * (0.18 + 0.2 * float(i))), Vector2(30, 22), 10 + i)
	# Two ROCK EYES with glowing pupils
	var eye_y := -h * 0.74
	for d: float in [-1.0, 1.0]:
		var ec := Vector2(d * 34.0 + 10.0 + sway, eye_y)
		_rock(c, ec, Vector2(26, 22), 20 + int(d))
		var look := Vector2(6, 0) if pose != "idle" else Vector2(3, 0)
		c.draw_circle(ec + look, 9.0, BLACK)
		c.draw_circle(ec + look, 6.0, LAVA_HOT if not raging else Color(1, 1, 1))
	# Mouth vent (opens wide to spit)
	var open := 1.0 if pose.begins_with("spit") or pose.begins_with("rocks") else 0.35
	var mouth := EnemyArt.ellipse_points(Vector2(14 + sway, -h * 0.56), 32, 14 * open + 4, 14)
	c.draw_colored_polygon(mouth, BLACK)
	c.draw_colored_polygon(EnemyArt.ellipse_points(Vector2(14 + sway, -h * 0.56), 22, 9 * open + 2, 12), LAVA_HOT)


# ============================================================
# KHARLEMING LORD (boss, ~260): a giant Kharleming made of everything in the crater -
# basalt plates + lava cracks, demon HORNS, ship-hull plates, black FEATHERED wings, a SCORPION TAIL
# ============================================================
static func lord(c: CanvasItem, s: Dictionary) -> void:
	var t: float = s.get("t", 0.0)
	var pose := _pose(s)
	var moving: bool = s.get("moving", false)
	var raging: bool = s.get("raging", false)
	var sk := t * (14.0 if moving else 4.0)
	var body_c := Vector2(0, -120)
	# Feathered wings (behind)
	var flap := sin(t * (8.0 if pose.begins_with("dive") else 2.0)) * 0.25
	for d: float in [-1.0, 1.0]:
		var root := body_c + Vector2(-20, -40)
		for f in 6:
			var a := -PI * 0.5 + d * (0.5 + float(f) * 0.17) + flap * d
			var tip := root + Vector2.from_angle(a) * (150.0 - float(f) * 12.0)
			FighterArt.curved_spike(c, root, tip, 12.0, Color(0.10, 0.09, 0.11), Color(0.28, 0.24, 0.30), 0.12 * d, 2.5)
	# Scorpion tail: segments arching over the back, stinger dripping void goo
	var strike := 1.0 if pose.begins_with("sting") else 0.0
	var seg := body_c + Vector2(-70, -10)
	var dirs := [Vector2(-0.7, -1.0), Vector2(-0.2, -1.2), Vector2(0.5, -1.0), Vector2(1.0, -0.4 + strike * 0.9)]
	for i in dirs.size():
		var nxt: Vector2 = seg + (dirs[i] as Vector2).normalized() * (46.0 - float(i) * 4.0)
		FighterArt.limb(c, seg, nxt, 22.0 - float(i) * 3.0, METAL_SHADE, BASALT, METAL_HI)
		c.draw_circle(seg, 5.0, LAVA)
		seg = nxt
	FighterArt.curved_spike(c, seg, seg + Vector2(34, 18 + strike * 20.0), 10.0, BASALT, GOO, 0.3, 3.0)
	c.draw_circle(seg + Vector2(36, 22 + strike * 20.0), 5.0, GOO)
	# Legs: eight heavy jointed legs
	for i in 8:
		var side := -1.0 if i < 4 else 1.0
		var k := float(i % 4)
		var hip := body_c + Vector2(-50.0 + k * 32.0, 30)
		var lift := sin(sk + k * 1.9 + (PI if side > 0.0 else 0.0)) * 8.0
		var knee := hip + Vector2(-30.0 + k * 20.0 + side * 8.0, -40.0 + lift)
		var foot := Vector2(hip.x + (-46.0 + k * 30.0), minf(lift, 0.0))
		FighterArt.limb(c, hip, knee, 13.0, METAL_SHADE if side < 0.0 else METAL, BASALT, METAL_HI)
		FighterArt.limb(c, knee, foot, 10.0, METAL_SHADE if side < 0.0 else METAL, BASALT, METAL_HI)
	# The body: a huge dome of hull plates and basalt, glowing lava cracks
	var dome := EnemyArt.ellipse_points(body_c, 96, 60, 24)
	var cols := PackedColorArray()
	for p in dome:
		cols.append(METAL_HI.lerp(BASALT, clampf((p.y - body_c.y + 40.0) / 100.0, 0.0, 1.0)))
	c.draw_polygon(dome, cols)
	for i in 3:
		_rock(c, body_c + Vector2(-52 + float(i) * 44.0, -30 - float(i % 2) * 10.0), Vector2(22, 16), 30 + i)
	_glow_crack(c, PackedVector2Array([body_c + Vector2(-70, 10), body_c + Vector2(-30, 24), body_c + Vector2(10, 12), body_c + Vector2(60, 28)]), t, 4.0)
	FighterArt.outline(c, dome, 5.0)
	# Head: horns, goblin ears, mandibles, a demon-red eye
	var head := body_c + Vector2(88, -6)
	FighterArt.ball(c, head, 30.0, METAL, METAL_SHADE, METAL_HI)
	for d: float in [-1.0, 1.0]:
		FighterArt.curved_spike(c, head + Vector2(d * 12.0 - 4.0, -24), head + Vector2(d * 30.0 + 6.0, -78), 9.0, BASALT, Color(0.9, 0.85, 0.75), 0.35 * d, 3.0)
	var bite := pose.begins_with("bite") or pose.begins_with("charge")
	for d: float in [-1.0, 1.0]:
		c.draw_line(head + Vector2(26, d * 8.0), head + Vector2(56, d * (16.0 + (12.0 if bite else 0.0))), BLACK, 8.0)
		c.draw_line(head + Vector2(26, d * 8.0), head + Vector2(56, d * (16.0 + (12.0 if bite else 0.0))), METAL_SHADE, 4.0)
	var eye := head + Vector2(12, -6)
	c.draw_circle(eye, 16.0, Color(1.0, 0.2, 0.1, 0.3 if not raging else 0.55))
	c.draw_circle(eye, 10.0, BLACK)
	c.draw_circle(eye, 7.0, LAVA_HOT if raging else Color(1.0, 0.25, 0.1))
