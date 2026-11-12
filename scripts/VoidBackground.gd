class_name VoidBackground
extends CanvasLayer
## Void Arena backdrop (screen space, behind everything), GREEN + BLACK theme:
## dark green sky, a pale void moon, black jagged mountains, giant void
## tentacles swaying out of the ground, rolling green fog and floating sparks.
## Follows the active Camera2D with parallax. Pure visuals.

@export var auto_scroll_speed := 0.0
@export_range(0.0, 1.0) var dim := 0.0
@export var seed_value := 666

const SKY_TOP := Color(0.01, 0.02, 0.01)
const SKY_MID := Color(0.03, 0.10, 0.05)
const SKY_HORIZON := Color(0.14, 0.42, 0.18)
const FOG := Color(0.25, 0.75, 0.32)
const GLOW := Color(0.35, 1.0, 0.45)
const VOID := Color(0.03, 0.04, 0.03)
const VOID_HI := Color(0.10, 0.22, 0.12)
const MOUNTAIN := Color(0.04, 0.07, 0.05)
const SPARK := Color(0.65, 1.0, 0.55)

const MOUNTAIN_PERIOD := 2400.0
const TENTACLE_PERIOD := 2600.0

var _t := 0.0
var _painter: Painter
var _mountains: Array[Dictionary] = []
var _tentacles_far: Array[Dictionary] = []
var _tentacles_near: Array[Dictionary] = []
var _sparks: Array[Vector4] = []      # x, y, speed, phase (normalised screen coords)
var _fog_blobs: Array[Vector4] = []   # x, y, radius, speed


class Painter extends Node2D:
	var bg: VoidBackground

	func _draw() -> void:
		bg.paint(self)


func _ready() -> void:
	layer = -10
	_generate()
	_painter = Painter.new()
	_painter.bg = self
	add_child(_painter)


func _process(delta: float) -> void:
	_t += delta
	if GraphicsSettings.bg_should_redraw():
		_painter.queue_redraw()


func _camera_pos() -> Vector2:
	var cam := get_viewport().get_camera_2d()
	if cam != null:
		return cam.get_screen_center_position()
	return Vector2(_t * auto_scroll_speed, 300.0)


func _generate() -> void:
	var rng := RandomNumberGenerator.new()
	rng.seed = seed_value

	var x := 0.0
	while x < MOUNTAIN_PERIOD - 100.0:
		var w := rng.randf_range(220.0, 420.0)
		var pts := PackedVector2Array([Vector2(0, 0)])
		var steps := rng.randi_range(5, 8)
		for i in range(1, steps):
			var px := w * float(i) / float(steps) + rng.randf_range(-8.0, 8.0)
			var peak := sin(PI * float(i) / float(steps))
			pts.append(Vector2(px, -peak * rng.randf_range(90.0, 230.0) - rng.randf_range(0.0, 30.0)))
		pts.append(Vector2(w, 0))
		_mountains.append({"x": x, "pts": pts})
		x += w * rng.randf_range(0.5, 0.85)

	for i in 9:
		_tentacles_far.append({"x": TENTACLE_PERIOD * float(i) / 9.0 + rng.randf_range(-80.0, 80.0),
			"h": rng.randf_range(160.0, 300.0), "w": rng.randf_range(16.0, 26.0),
			"phase": rng.randf() * TAU, "curl": rng.randf_range(-1.0, 1.0)})
	for i in 5:
		_tentacles_near.append({"x": TENTACLE_PERIOD * float(i) / 5.0 + rng.randf_range(-150.0, 150.0),
			"h": rng.randf_range(260.0, 420.0), "w": rng.randf_range(28.0, 40.0),
			"phase": rng.randf() * TAU, "curl": rng.randf_range(-1.0, 1.0)})

	for i in 70:
		_sparks.append(Vector4(rng.randf(), rng.randf(), rng.randf_range(0.02, 0.07), rng.randf() * TAU))
	for i in 14:
		_fog_blobs.append(Vector4(rng.randf(), rng.randf_range(0.55, 0.95), rng.randf_range(90.0, 200.0), rng.randf_range(8.0, 22.0)))


# ============================================================
# PAINTING
# ============================================================
func paint(c: CanvasItem) -> void:
	var size := get_viewport().get_visible_rect().size
	var cam := _camera_pos()
	var w := size.x
	var h := size.y
	var horizon := h * 0.62 - (cam.y - 300.0) * 0.03

	_grad(c, 0.0, horizon * 0.5, w, SKY_TOP, SKY_MID)
	_grad(c, horizon * 0.5, horizon, w, SKY_MID, SKY_HORIZON)
	_grad(c, horizon, h, w, SKY_HORIZON, Color(0.02, 0.06, 0.03))

	_draw_moon(c, Vector2(w * 0.22 - cam.x * 0.01, h * 0.22))

	# Far mountains
	var m_base := horizon + 30.0
	for start in _starts(-cam.x * 0.05, MOUNTAIN_PERIOD, w):
		for m in _mountains:
			_draw_mountain(c, Vector2(start + float(m["x"]), m_base), m["pts"], h)
	_fog_band(c, horizon - 40.0, h, w, 0.45)

	# Far tentacles
	var tf_base := horizon + 90.0 - (cam.y - 300.0) * 0.05
	for start in _starts(-cam.x * 0.12, TENTACLE_PERIOD, w):
		if not GraphicsSettings.bg_full():
			break                                    # Far tentacles: Regular / Real only
		for tt in _tentacles_far:
			_draw_tentacle(c, Vector2(start + float(tt["x"]), tf_base), tt, 0.75, w)
	_fog_band(c, tf_base - 70.0, h, w, 0.5)

	# Near tentacles
	var tn_base := horizon + 200.0 - (cam.y - 300.0) * 0.1
	for start in _starts(-cam.x * 0.25, TENTACLE_PERIOD, w):
		for tt in _tentacles_near:
			_draw_tentacle(c, Vector2(start + float(tt["x"]), tn_base), tt, 1.0, w)

	# Rolling fog blobs + sparks: skipped on Potato
	var deco: Array = _fog_blobs if GraphicsSettings.bg_detail() else []
	for f in deco:
		var fx := fposmod(f.x * (w + 400.0) + _t * f.w - cam.x * 0.15, w + 400.0) - 200.0
		c.draw_circle(Vector2(fx, f.y * h), f.z, Color(FOG.r, FOG.g, FOG.b, 0.10))
		c.draw_circle(Vector2(fx + f.z * 0.6, f.y * h + 10.0), f.z * 0.7, Color(FOG.r, FOG.g, FOG.b, 0.08))
	_fog_band(c, tn_base - 40.0, h, w, 0.55)

	# Floating sparks (rise, flicker, wrap)
	for s in (_sparks if GraphicsSettings.bg_detail() else []):
		var sx := fposmod(s.x * w - cam.x * 0.3 + sin(_t * 0.8 + s.w) * 20.0, w)
		var sy := fposmod(s.y - _t * s.z, 1.0) * h
		var flick := 0.5 + 0.5 * sin(_t * 6.0 + s.w * 3.0)
		c.draw_circle(Vector2(sx, sy), 5.0, Color(GLOW.r, GLOW.g, GLOW.b, 0.15 * flick))
		c.draw_circle(Vector2(sx, sy), 1.8, Color(SPARK.r, SPARK.g, SPARK.b, 0.5 + 0.5 * flick))

	if dim > 0.0:
		c.draw_rect(Rect2(0, 0, w, h), Color(0, 0, 0, dim))


func _starts(shift: float, period: float, w: float) -> Array[float]:
	var out: Array[float] = []
	var s := fposmod(shift, period) - period
	while s < w + 300.0:
		out.append(s)
		s += period
	return out


func _grad(c: CanvasItem, y0: float, y1: float, w: float, a: Color, b: Color) -> void:
	if y1 <= y0:
		return
	c.draw_polygon(
		PackedVector2Array([Vector2(0, y0), Vector2(w, y0), Vector2(w, y1), Vector2(0, y1)]),
		PackedColorArray([a, a, b, b]))


func _fog_band(c: CanvasItem, y: float, h: float, w: float, strength: float) -> void:
	_grad(c, y, y + 70.0, w, Color(FOG.r, FOG.g, FOG.b, 0.0), Color(FOG.r * 0.5, FOG.g * 0.5, FOG.b * 0.5, strength))
	_grad(c, y + 70.0, h + 2.0, w, Color(FOG.r * 0.5, FOG.g * 0.5, FOG.b * 0.5, strength), Color(0.02, 0.07, 0.03, strength + 0.2))


func _draw_moon(c: CanvasItem, p: Vector2) -> void:
	c.draw_circle(p, 110.0, Color(GLOW.r, GLOW.g, GLOW.b, 0.07))
	c.draw_circle(p, 76.0, Color(GLOW.r, GLOW.g, GLOW.b, 0.12))
	c.draw_circle(p, 50.0, Color(0, 0, 0))
	c.draw_circle(p, 46.0, Color(0.72, 0.95, 0.70))
	c.draw_circle(p + Vector2(12, -6), 38.0, Color(0.55, 0.85, 0.55))      # Crescent shadow
	c.draw_circle(p + Vector2(-16, -14), 7.0, Color(0.85, 1.0, 0.82))


func _draw_mountain(c: CanvasItem, base: Vector2, pts: PackedVector2Array, h: float) -> void:
	var last: Vector2 = pts[pts.size() - 1]
	if base.x + last.x < -40.0 or base.x > c.get_viewport_rect().size.x + 40.0:
		return
	var poly := PackedVector2Array([Vector2(base.x, h + 10.0)])
	for p in pts:
		poly.append(base + p)
	poly.append(Vector2(base.x + last.x, h + 10.0))
	c.draw_colored_polygon(poly, MOUNTAIN)
	# Green rim light on the peaks
	var rim := PackedVector2Array()
	for p in pts:
		rim.append(base + p)
	c.draw_polyline(rim, Color(GLOW.r, GLOW.g, GLOW.b, 0.35), 3.0, FighterArt.AA)


## A void tentacle rising out of the ground, swaying, with glowing suckers.
func _draw_tentacle(c: CanvasItem, base: Vector2, tt: Dictionary, scale_k: float, w: float) -> void:
	if base.x < -260.0 or base.x > w + 260.0:
		return
	var height: float = tt["h"] * scale_k
	var width: float = tt["w"] * scale_k
	var phase: float = tt["phase"]
	var curl: float = tt["curl"]
	var n := 14
	var center := PackedVector2Array()
	for i in n + 1:
		var u := float(i) / float(n)
		var sway := sin(_t * 1.3 + phase + u * 3.0) * 26.0 * u + curl * 50.0 * u * u
		center.append(base + Vector2(sway, -height * u))
	var left := PackedVector2Array()
	var right := PackedVector2Array()
	for i in center.size():
		var u := float(i) / float(n)
		var dir: Vector2
		if i < center.size() - 1:
			dir = (center[i + 1] - center[i]).normalized()
		else:
			dir = (center[i] - center[i - 1]).normalized()
		var perp := Vector2(-dir.y, dir.x)
		var half := width * (1.0 - u * 0.92)
		left.append(center[i] + perp * half)
		right.append(center[i] - perp * half)
	right.reverse()
	var body := left.duplicate()
	body.append_array(right)
	c.draw_colored_polygon(body, VOID)
	c.draw_rect(Rect2(base.x - width, base.y, width * 2.0, 400.0), VOID)
	# Highlight + outline
	var hl := PackedVector2Array()
	for i in left.size():
		hl.append(left[i].lerp(center[i], 0.45))
	c.draw_polyline(hl, VOID_HI, 3.0 * scale_k, FighterArt.AA)
	var outline := body.duplicate()
	outline.append(body[0])
	c.draw_polyline(outline, Color(GLOW.r * 0.4, GLOW.g * 0.4, GLOW.b * 0.4), 3.0, FighterArt.AA)
	# Glowing suckers
	for i in range(2, n - 1, 2):
		var u := float(i) / float(n)
		var p := center[i].lerp(right[right.size() - 1 - i], 0.45)
		var pulse := 0.5 + 0.5 * sin(_t * 3.0 + phase + float(i))
		c.draw_circle(p, 4.5 * scale_k * (1.0 - u * 0.6), Color(GLOW.r, GLOW.g, GLOW.b, 0.35 + 0.5 * pulse))
