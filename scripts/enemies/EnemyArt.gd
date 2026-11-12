class_name EnemyArt
extends RefCounted
## Small drawing helpers shared by the PvE enemies (same flat cartoon style as the
## fighters: thick black outline via FighterArt). Everything is vector drawing, no
## textures, so nothing needs importing / compressing. No draw_set_transform here:
## death animations and Character Select cards scale us from outside.

const BLACK := Color(0, 0, 0)


## Two walking legs (far leg darker). hip_y < 0, feet end on y = 0.
static func legs(c: CanvasItem, s: Dictionary, hip_y: float, spread: float, w: float,
		col: Color, shade: Color, hi: Color, shoe: Color, shoe_len: float = 14.0) -> void:
	var stride := 0.0
	if s.get("moving", false) and s.get("floor", true):
		stride = 12.0
	var ph: float = s.get("walk", 0.0)
	for i in 2:
		var far := i == 0
		var hip := Vector2(-spread if far else spread, hip_y)
		var swing := sin(ph + (PI if far else 0.0)) * stride
		var foot := Vector2(hip.x + swing, -6.0)
		var knee := hip.lerp(foot, 0.5) + Vector2(4, 0)
		var base := shade if far else col
		FighterArt.limb(c, hip, knee, w, base, shade, hi)
		FighterArt.limb(c, knee, foot, w * 0.92, base, shade, hi)
		var sh := FighterArt.rrect_points(Rect2(foot.x - 6.0, -9.0, shoe_len, 9.0), 4.0)
		c.draw_colored_polygon(sh, shoe.darkened(0.25) if far else shoe)
		FighterArt.outline(c, sh, 3.0)


static func arm(c: CanvasItem, shoulder: Vector2, hand: Vector2, w: float, col: Color, shade: Color, hi: Color,
		hand_col: Color, hand_r: float = 6.5) -> void:
	var elbow := shoulder.lerp(hand, 0.5) + Vector2(-3, 4)
	FighterArt.limb(c, shoulder, elbow, w, col, shade, hi)
	FighterArt.limb(c, elbow, hand, w * 0.9, col, shade, hi)
	FighterArt.ball(c, hand, hand_r, hand_col, hand_col.darkened(0.3), hand_col.lightened(0.3))


static func eye(c: CanvasItem, p: Vector2, r: float, iris: Color, look: Vector2 = Vector2(0.8, 0.2)) -> void:
	c.draw_circle(p, r + 1.2, BLACK)
	c.draw_circle(p, r, Color.WHITE)
	c.draw_circle(p + look, r * 0.6, iris)
	c.draw_circle(p + look * 1.2, r * 0.3, BLACK)
	c.draw_circle(p + Vector2(-r * 0.3, -r * 0.35), r * 0.2, Color.WHITE)


static func star_points(center: Vector2, r: float, n: int = 5, inner: float = 0.45, rot: float = -PI * 0.5) -> PackedVector2Array:
	var pts := PackedVector2Array()
	for i in n * 2:
		var a := rot + PI * float(i) / float(n)
		pts.append(center + Vector2.from_angle(a) * (r if i % 2 == 0 else r * inner))
	return pts


static func star(c: CanvasItem, center: Vector2, r: float, col: Color, outline_w: float = 2.5) -> void:
	var pts := star_points(center, r)
	c.draw_colored_polygon(pts, col)
	FighterArt.outline(c, pts, outline_w)


static func ellipse_points(center: Vector2, rx: float, ry: float, n: int = 24) -> PackedVector2Array:
	var pts := PackedVector2Array()
	for i in n:
		var a := TAU * float(i) / float(n)
		pts.append(center + Vector2(cos(a) * rx, sin(a) * ry))
	return pts


static func ellipse(c: CanvasItem, center: Vector2, rx: float, ry: float, col: Color, outline_w: float = 4.0) -> void:
	var pts := ellipse_points(center, rx, ry)
	c.draw_colored_polygon(pts, col)
	if outline_w > 0.0:
		FighterArt.outline(c, pts, outline_w)


## Soft pulsing glow (enraged aura, holy light...).
static func aura(c: CanvasItem, center: Vector2, r: float, col: Color, t: float) -> void:
	var p := 0.5 + 0.5 * sin(t * 8.0)
	c.draw_circle(center, r + 5.0 * p, Color(col.r, col.g, col.b, 0.14 + 0.08 * p))
	c.draw_circle(center, r * 0.7, Color(col.r, col.g, col.b, 0.1))


## Swirly K.O. eye.
static func ko_eye(c: CanvasItem, p: Vector2, r: float, t: float) -> void:
	c.draw_circle(p, r + 1.0, BLACK)
	c.draw_circle(p, r, Color.WHITE)
	var pts := PackedVector2Array()
	for i in 12:
		pts.append(p + Vector2.from_angle(float(i) * 0.8 + t * 6.0) * (r * 0.08 * float(i)))
	c.draw_polyline(pts, BLACK, 1.5, FighterArt.AA)
