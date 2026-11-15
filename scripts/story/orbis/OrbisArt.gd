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
	var breathe := sin(t * 1.8) * 1.2
	var o := Vector2(0, 0)
	if seated:
		o = Vector2(0, 34)                                         # Sitting: everything lower
		FighterArt.limb(c, Vector2(-6, -40) + o, Vector2(18, -40) + o, 10.0, ROBE_SHADE, BLACK, ROBE)
		FighterArt.limb(c, Vector2(18, -40) + o, Vector2(20, -2), 9.0, ROBE_SHADE, BLACK, ROBE)
	else:
		for d: float in [-1.0, 1.0]:
			FighterArt.limb(c, Vector2(d * 7.0, -50), Vector2(d * 9.0, -2), 9.0, ROBE_SHADE, BLACK, ROBE)
	# A long robe
	var robe := PackedVector2Array([Vector2(-18, -98 + breathe) + o, Vector2(18, -98 + breathe) + o, Vector2(22, -40) + o, Vector2(-22, -40) + o])
	c.draw_colored_polygon(robe, ROBE)
	c.draw_line(Vector2(0, -96 + breathe) + o, Vector2(0, -42) + o, ROBE_HI, 2.0)
	c.draw_line(Vector2(-20, -60) + o, Vector2(20, -60) + o, Color(0.55, 0.75, 1.0), 4.0)          # A pale-blue sash
	FighterArt.outline(c, robe, 2.5)
	# Arms (one resting, one gesturing when happy / upset)
	var hand := Vector2(26, -66 + breathe) + o
	match mood:
		"happy":
			hand = Vector2(28, -104 + sin(t * 6.0) * 6.0) + o
		"upset":
			hand = Vector2(10, -58) + o
	FighterArt.limb(c, Vector2(16, -92 + breathe) + o, hand, 7.0, ROBE, BLACK, ROBE_HI)
	c.draw_circle(hand, 5.5, SKIN)
	FighterArt.limb(c, Vector2(-16, -92 + breathe) + o, Vector2(-18, -60) + o, 7.0, ROBE_SHADE, BLACK, ROBE)
	c.draw_circle(Vector2(-18, -58) + o, 5.5, SKIN_SHADE)
	# Head: blue skin, darker blue hair
	var hp := Vector2(2, -114 + breathe) + o
	FighterArt.ball(c, hp, 15.0, SKIN, SKIN_SHADE, SKIN_HI)
	c.draw_colored_polygon(PackedVector2Array([hp + Vector2(-15, -2), hp + Vector2(-12, -14), hp + Vector2(0, -19), hp + Vector2(12, -15), hp + Vector2(15, -4), hp + Vector2(6, -11)]), HAIR)
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
