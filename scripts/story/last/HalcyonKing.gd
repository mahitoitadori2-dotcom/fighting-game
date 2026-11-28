class_name HalcyonKing
extends RefCounted
## THE KING OF HALCYON (The Last Stretch): a tall old man in Stormist robes - storm-blue and silver,
## the Storm's spiral on his chest, a crown of copper lightning rods. Never fights (level 148 is a talk).
## Drawn facing RIGHT, feet at (0, 0), about 135 px tall (the heroes' size).
##   draw_portrait(c, t)        idle (the dialogue portrait, the board tile)
##   draw_king(c, t, hurt)      hurt 0..1: the hand through his chest (level 148)

const ROBE := Color(0.20, 0.26, 0.42)
const ROBE_SHADE := Color(0.12, 0.16, 0.28)
const SILVER := Color(0.80, 0.82, 0.88)
const COPPER := Color(0.78, 0.50, 0.26)
const SKIN := Color(0.86, 0.72, 0.60)
const BEARD := Color(0.88, 0.88, 0.90)
const STORM := Color(0.70, 0.90, 1.0)


static func draw_portrait(c: CanvasItem, t: float) -> void:
	draw_king(c, t, 0.0)


static func draw_king(c: CanvasItem, t: float, hurt: float) -> void:
	var sway := sin(t * 1.6) * 1.5 * (1.0 - hurt)
	var lean := hurt * 10.0
	# Robe (a long bell down to the floor) + silver trim
	c.draw_colored_polygon(PackedVector2Array([Vector2(-30, 0), Vector2(30, 0), Vector2(18 + lean, -92), Vector2(-18 + lean, -92)]), ROBE)
	c.draw_colored_polygon(PackedVector2Array([Vector2(-30, 0), Vector2(-14, 0), Vector2(-8 + lean, -92), Vector2(-18 + lean, -92)]), ROBE_SHADE)
	c.draw_rect(Rect2(-30, -6, 60, 6), SILVER)
	c.draw_line(Vector2(lean * 0.5, -92), Vector2(0, -6), SILVER, 3.0)
	# The Storm's spiral on his chest
	var em := Vector2(4 + lean, -70)
	var sp := PackedVector2Array()
	for k in 16:
		sp.append(em + Vector2.from_angle(float(k) * 0.55 + t * (1.0 - hurt)) * (1.5 + float(k) * 0.7))
	c.draw_polyline(sp, STORM, 2.0)
	# Arms (sleeves) holding a sceptre with a glass orb
	c.draw_line(Vector2(14 + lean, -86), Vector2(26 + lean, -58 + sway), ROBE_SHADE, 9.0)
	c.draw_circle(Vector2(27 + lean, -56 + sway), 5.0, SKIN)
	if hurt < 0.5:
		c.draw_line(Vector2(28 + lean, -110 + sway), Vector2(28 + lean, -20 + sway), COPPER, 3.0)
		c.draw_circle(Vector2(28 + lean, -114 + sway), 7.0, STORM)
	c.draw_line(Vector2(-14 + lean, -86), Vector2(-20 + lean, -54), ROBE_SHADE, 9.0)
	c.draw_circle(Vector2(-20 + lean, -52), 5.0, SKIN)
	# Head: an old face, a long white beard, the crown of lightning rods
	var hp := Vector2(2 + lean * 1.3, -106)
	c.draw_circle(hp, 13.0, SKIN)
	c.draw_colored_polygon(PackedVector2Array([hp + Vector2(-10, 2), hp + Vector2(12, 2), hp + Vector2(4, 30)]), BEARD)
	c.draw_circle(hp + Vector2(5, -2), 2.0, Color(0.1, 0.1, 0.12) if hurt < 0.9 else Color(0.5, 0.5, 0.5))
	c.draw_rect(Rect2(hp.x - 13, hp.y - 16, 26, 6), COPPER)
	for k in 4:
		var x := hp.x - 10.0 + float(k) * 6.6
		c.draw_line(Vector2(x, hp.y - 16), Vector2(x, hp.y - 28 - float(k % 2) * 5.0), COPPER, 2.0)
		c.draw_circle(Vector2(x, hp.y - 29 - float(k % 2) * 5.0), 2.0, STORM)
	if hurt > 0.0:                                         # The wound: the light going out of him
		c.draw_circle(Vector2(4 + lean, -68), 9.0 * hurt, Color(0.65, 0.05, 0.05, hurt))
		c.draw_circle(Vector2(4 + lean, -68), 16.0 * hurt, Color(1.0, 0.85, 0.5, 0.25 * hurt))
