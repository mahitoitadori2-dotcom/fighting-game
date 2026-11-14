class_name Dots
extends RefCounted
## Cheap circles: draw_circle() costs one draw call EACH, but textured rects that share one texture
## are BATCHED into a single call. Use these for crowds of circles (clouds, sparks, fog puffs).
##   Dots.circle(canvas, pos, radius, color)   a solid disc (soft 1-px edge)
##   Dots.glow(canvas, pos, radius, color)     a soft round glow (fades out to the edge)
## Keep calls of the same kind together: a different texture or another draw type in between
## starts a new batch.

const SIZE := 128

static var _disc: Texture2D
static var _soft: Texture2D


static func circle(c: CanvasItem, p: Vector2, r: float, col: Color) -> void:
	c.draw_texture_rect(_disc_tex(), Rect2(p - Vector2(r, r), Vector2(r, r) * 2.0), false, col)


static func glow(c: CanvasItem, p: Vector2, r: float, col: Color) -> void:
	c.draw_texture_rect(_soft_tex(), Rect2(p - Vector2(r, r), Vector2(r, r) * 2.0), false, col)


static func _disc_tex() -> Texture2D:
	if _disc == null:
		_disc = _make(func(d: float) -> float: return clampf((float(SIZE) * 0.5 - d) / 1.5, 0.0, 1.0))
	return _disc


static func _soft_tex() -> Texture2D:
	if _soft == null:
		_soft = _make(func(d: float) -> float:
			var k := clampf(1.0 - d / (float(SIZE) * 0.5), 0.0, 1.0)
			return k * k)
	return _soft


static func _make(alpha: Callable) -> Texture2D:
	var img := Image.create(SIZE, SIZE, false, Image.FORMAT_RGBA8)
	var c := Vector2(SIZE, SIZE) * 0.5
	for y in SIZE:
		for x in SIZE:
			var a: float = alpha.call(Vector2(float(x) + 0.5, float(y) + 0.5).distance_to(c))
			img.set_pixel(x, y, Color(1, 1, 1, a))
	return ImageTexture.create_from_image(img)
