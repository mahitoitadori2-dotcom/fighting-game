class_name OrbisArt
extends RefCounted
## ORBIS TERRARUM art: THE TRAINER (a Learner at the Trainer level: FULLY BLUE, head to toe, NO EYES), the
## island, the closed HUT with its ancient spells, the table with one free seat.

const BLACK := Color(0, 0, 0)
const SKIN := Color(0.32, 0.52, 0.95)
const SKIN_SHADE := Color(0.20, 0.34, 0.72)
const SKIN_HI := Color(0.55, 0.72, 1.0)
const ROBE := Color(0.16, 0.30, 0.70)
const ROBE_SHADE := Color(0.09, 0.18, 0.48)
const ROBE_HI := Color(0.30, 0.48, 0.90)
const HAIR := Color(0.10, 0.18, 0.45)
const WOOD := Color(0.48, 0.32, 0.18)
const WOOD_DARK := Color(0.30, 0.19, 0.10)


## The Trainer. mood: "calm" / "happy" / "upset". seated = only what shows above a table edge
## matters (the legs are bent under it).
static func trainer(c: CanvasItem, t: float, mood: String = "calm", seated: bool = false) -> void:
	# CONCEPT ART (2026-11-15): a SLIM body and very long limbs that TAPER TO POINTS (no hands, no
	# feet - blades of blue), dark marks at the joints, a small round head. Still all blue, no eyes.
	var breathe := sin(t * 1.8) * 1.2
	var o := Vector2(0, 0)
	if seated:
		o = Vector2(0, 34)                                         # Sitting: everything lower
		_spike_limb(c, Vector2(-6, -40) + o, Vector2(20, -42) + o, 9.0, ROBE_SHADE)
		_spike_limb(c, Vector2(18, -42) + o, Vector2(22, 0), 7.0, ROBE_SHADE)
	else:
		for d: float in [-1.0, 1.0]:
			_spike_limb(c, Vector2(d * 6.0, -50), Vector2(d * 16.0, 2), 9.0, ROBE_SHADE if d < 0.0 else ROBE)
	# Slim torso: narrow at the waist, a pale-blue band across it
	var body := PackedVector2Array([Vector2(-13, -98 + breathe) + o, Vector2(13, -98 + breathe) + o, Vector2(9, -70) + o,
		Vector2(8, -48) + o, Vector2(-8, -48) + o, Vector2(-9, -70) + o])
	c.draw_colored_polygon(body, ROBE)
	c.draw_line(Vector2(0, -96 + breathe) + o, Vector2(0, -50) + o, ROBE_HI, 2.0)
	c.draw_line(Vector2(-9, -62) + o, Vector2(9, -62) + o, Color(0.55, 0.75, 1.0), 3.0)
	FighterArt.outline(c, body, 2.5)
	for jp: Vector2 in [Vector2(-12, -94), Vector2(12, -94), Vector2(-6, -50), Vector2(6, -50)]:   # Dark joint marks
		c.draw_circle(jp + o + Vector2(0, breathe if jp.y < -90.0 else 0.0), 3.5, HAIR)
	# Arms: long blades of blue (one resting, one gesturing when happy / upset)
	var hand := Vector2(34, -62 + breathe) + o
	match mood:
		"happy":
			hand = Vector2(30, -128 + sin(t * 6.0) * 6.0) + o
		"upset":
			hand = Vector2(14, -50) + o
	_spike_limb(c, Vector2(12, -94 + breathe) + o, hand, 7.0, ROBE)
	_spike_limb(c, Vector2(-12, -94 + breathe) + o, Vector2(-30, -50) + o, 7.0, ROBE_SHADE)
	# Head: small and round, blue skin, darker blue hair
	var hp := Vector2(2, -112 + breathe) + o
	FighterArt.ball(c, hp, 12.0, SKIN, SKIN_SHADE, SKIN_HI)
	c.draw_colored_polygon(PackedVector2Array([hp + Vector2(-12, -2), hp + Vector2(-10, -11), hp + Vector2(0, -15), hp + Vector2(10, -12), hp + Vector2(12, -3), hp + Vector2(5, -9)]), HAIR)
	# NO EYES (the user's design): only smooth blue skin where eyes would be. The mood shows in
	# the mouth alone - a darker blue line.
	var mouth := SKIN_SHADE.darkened(0.35)
	match mood:
		"happy":
			c.draw_arc(hp + Vector2(6, 4), 5.0, 0.2, PI - 0.2, 8, mouth, 2.0)
		"upset":
			c.draw_arc(hp + Vector2(6, 9), 5.0, PI + 0.3, TAU - 0.3, 8, mouth, 2.0)
		_:
			c.draw_line(hp + Vector2(3, 6), hp + Vector2(10, 6), mouth, 2.0)


## One of the Trainer's limbs: wide at the joint, tapering to a sharp point (concept art).
static func _spike_limb(c: CanvasItem, a: Vector2, b: Vector2, w: float, col: Color) -> void:
	var d := b - a
	if d.length() < 2.0:
		return
	var side := d.normalized().orthogonal() * (w * 0.5)
	var mid := a.lerp(b, 0.55)
	var pts := PackedVector2Array([a + side, mid + side * 0.75, b, mid - side * 0.75, a - side])
	c.draw_colored_polygon(pts, col)
	c.draw_line(a + side * 0.2, mid + side * 0.2, col.lightened(0.2), 1.5)
	FighterArt.outline(c, pts, 2.2)


## THE STORM HAND (boss of level 80): the Storm's whole HAND reaching down out of the sky - a
## palm of dark cloud, five fingers, lightning crawling over it. The wrist goes up off the screen.
## pose: idle / slam(_tele) / sweep(_tele) / fist(_tele) / zap(_tele). "short" = portraits.
static func storm_hand(c: CanvasItem, st: Dictionary) -> void:
	var t: float = st.get("t", 0.0)
	var pose: String = st.get("pose", "idle")
	var tele := pose.ends_with("_tele")
	var base := pose.trim_suffix("_tele")
	var dark := OrdArt.STORM
	var hi := OrdArt.STORM_HI
	var shade := OrdArt.STORM_SHADE
	var lift := 0.0
	if tele and (base == "slam" or base == "fist"):
		lift = 150.0 + 20.0 * sin(t * 10.0)
	var palm := Vector2(0, -150 - lift)
	# The wrist, up and out of the screen
	if not bool(st.get("short", false)):
		c.draw_line(palm + Vector2(0, -40), palm + Vector2(-60, -2400), BLACK, 150.0)
		c.draw_line(palm + Vector2(0, -40), palm + Vector2(-60, -2400), dark, 136.0)
	# Fingers: spread for a slam / sweep, curled into a fist, pointed for a zap
	var fist := base == "fist"
	for i in 5:
		var ang := PI * 0.5 + (float(i) - 2.0) * (0.22 if not fist else 0.08)
		var ln := 120.0 + 25.0 * float(2 - absi(i - 2)) - (70.0 if fist else 0.0)
		if base == "zap" and i == 1:
			ln += 40.0
		var root := palm + Vector2((float(i) - 2.0) * 26.0, 40.0)
		var mid := root + Vector2.from_angle(ang) * ln * 0.55
		var tip := root + Vector2.from_angle(ang + (0.25 if base == "sweep" else 0.0)) * ln
		if i == 4:                                                 # The thumb, off to the side
			mid = palm + Vector2(70, 10)
			tip = palm + Vector2(110, -20 + (40.0 if fist else 0.0))
		c.draw_polyline(PackedVector2Array([root, mid, tip]), BLACK, 40.0)
		c.draw_polyline(PackedVector2Array([root, mid, tip]), dark, 32.0)
		c.draw_line(root + Vector2(-6, 0), mid + Vector2(-6, 0), hi.lerp(dark, 0.5), 7.0)
		c.draw_circle(mid, 17.0, shade)
		c.draw_colored_polygon(EnemyArt.ellipse_points(tip + Vector2.from_angle(ang) * -6.0, 10, 13, 10), shade)
	# The palm
	var p := EnemyArt.ellipse_points(palm, 90, 70, 24)
	c.draw_colored_polygon(p, dark)
	c.draw_colored_polygon(EnemyArt.ellipse_points(palm + Vector2(-14, -12), 52, 34, 18), hi.lerp(dark, 0.6))
	FighterArt.outline(c, p, 4.0)
	# A storm-eye in the middle of the palm + lightning over the hand
	c.draw_circle(palm + Vector2(0, 6), 18.0, Color(0, 0, 0))
	c.draw_circle(palm + Vector2(0, 6), 12.0, Color(0.75, 0.88, 1.0, 0.6 + 0.4 * sin(t * 4.0)))
	for k in 3:
		var y0 := -40.0 - fmod(t * 240.0 + float(k) * 90.0, 260.0)
		var b := PackedVector2Array([palm + Vector2(-60 + float(k) * 50.0, y0 + 130.0), palm + Vector2(-44 + float(k) * 50.0, y0 + 100.0),
			palm + Vector2(-58 + float(k) * 50.0, y0 + 80.0), palm + Vector2(-40 + float(k) * 50.0, y0 + 50.0)])
		c.draw_polyline(b, Color(OrdArt.BOLT.r, OrdArt.BOLT.g, OrdArt.BOLT.b, 0.7), 2.5)
	if tele:
		c.draw_circle(palm, 130.0, Color(0.7, 0.85, 1.0, 0.10 + 0.08 * sin(t * 12.0)))
	if lift > 0.0:
		c.draw_colored_polygon(EnemyArt.ellipse_points(Vector2(0, -2), 120.0, 10.0, 16), Color(0, 0, 0, 0.35))


## THE HUT: old stone and wood, a CLOSED door, ancient runes glowing on it (the spells that keep
## the Storm away).
static func hut(c: CanvasItem, o: Vector2, t: float) -> void:
	var w := 260.0
	var h := 190.0
	c.draw_circle(o + Vector2(0, -h * 0.6), 220.0, Color(0.6, 0.85, 1.0, 0.06 + 0.03 * sin(t * 1.5)))     # The spell's dome
	c.draw_arc(o + Vector2(0, -h * 0.4), 230.0, PI, TAU, 40, Color(0.7, 0.9, 1.0, 0.18 + 0.08 * sin(t * 1.5)), 3.0)
	var wall := Rect2(o.x - w * 0.5, o.y - h, w, h)
	FighterArt.rrect(c, wall, Color(0.62, 0.58, 0.52), Color(0.44, 0.40, 0.36), Color(0.76, 0.72, 0.66), 6.0, 3.5)
	for i in 4:
		c.draw_line(Vector2(wall.position.x + 6, wall.position.y + 40.0 + float(i) * 38.0), Vector2(wall.end.x - 6, wall.position.y + 40.0 + float(i) * 38.0), Color(0.40, 0.36, 0.32), 2.0)
	var roof := PackedVector2Array([Vector2(wall.position.x - 30, wall.position.y), Vector2(o.x, wall.position.y - 110), Vector2(wall.end.x + 30, wall.position.y)])
	c.draw_colored_polygon(roof, Color(0.38, 0.30, 0.22))
	for i in 5:
		var k := float(i + 1) / 6.0
		c.draw_line(roof[0].lerp(roof[1], k), roof[2].lerp(roof[1], k), Color(0.28, 0.21, 0.15), 3.0)
	FighterArt.outline(c, roof, 3.5)
	var door := Rect2(o.x - 34, o.y - 110, 68, 110)
	c.draw_rect(door, WOOD_DARK)
	c.draw_rect(door, BLACK, false, 3.0)
	c.draw_line(Vector2(o.x, door.position.y), Vector2(o.x, door.end.y), Color(0.2, 0.12, 0.06), 2.0)
	c.draw_line(Vector2(door.position.x, o.y - 70), Vector2(door.end.x, o.y - 70), Color(0.35, 0.35, 0.38), 6.0)   # A bar across: closed
	for i in 6:                                                     # Glowing runes around the door
		var a := PI + PI * float(i) / 5.0
		var p := o + Vector2(0, -70) + Vector2(cos(a), sin(a)) * 74.0
		var g := 0.55 + 0.45 * sin(t * 2.0 + float(i))
		c.draw_arc(p, 6.0, 0.0, TAU, 8, Color(0.6, 0.9, 1.0, g), 2.0)
		c.draw_line(p + Vector2(-3, 0), p + Vector2(3, 0), Color(0.6, 0.9, 1.0, g), 2.0)


## The table with two chairs (left = the Trainer's, right = the free seat).
static func table(c: CanvasItem, o: Vector2) -> void:
	for d: float in [-1.0, 1.0]:                                    # Chairs
		var cx := o.x + d * 120.0
		c.draw_rect(Rect2(cx - 22, o.y - 46, 44, 8), WOOD)
		c.draw_line(Vector2(cx - 18, o.y - 40), Vector2(cx - 18, o.y), WOOD_DARK, 5.0)
		c.draw_line(Vector2(cx + 18, o.y - 40), Vector2(cx + 18, o.y), WOOD_DARK, 5.0)
		var back := cx - d * 22.0
		c.draw_line(Vector2(back, o.y - 46), Vector2(back, o.y - 110), WOOD_DARK, 6.0)
		c.draw_rect(Rect2(cx - 22, o.y - 46, 44, 8), BLACK, false, 2.0)
	var top := Rect2(o.x - 90, o.y - 74, 180, 12)
	c.draw_line(Vector2(o.x - 70, o.y - 64), Vector2(o.x - 70, o.y), WOOD_DARK, 8.0)
	c.draw_line(Vector2(o.x + 70, o.y - 64), Vector2(o.x + 70, o.y), WOOD_DARK, 8.0)
	FighterArt.rrect(c, top, WOOD, WOOD_DARK, WOOD.lightened(0.2), 3.0, 2.5)
	c.draw_circle(o + Vector2(-20, -82), 8.0, Color(0.95, 0.95, 0.92))      # Two cups of tea
	c.draw_circle(o + Vector2(30, -82), 8.0, Color(0.95, 0.95, 0.92))
	c.draw_line(o + Vector2(-20, -92), o + Vector2(-16, -104), Color(1, 1, 1, 0.35), 2.0)
