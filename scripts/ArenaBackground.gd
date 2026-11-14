class_name ArenaBackground
extends CanvasLayer
## Screen-space parallax backdrop drawn behind everything:
## sky gradient, sun, drifting clouds, the distant HEXAGON towers, a mid city
## skyline and rocky spires, separated by layers of valley mist.
## Follows the active Camera2D. With no camera (menus) it auto-scrolls instead.
## Pure visuals: no collision, no gameplay.

@export var auto_scroll_speed := 0.0      # px/s when there is no Camera2D (menus)
@export_range(0.0, 1.0) var dim := 0.0    # Dark overlay (menus use ~0.25)
@export var seed_value := 1337

const OUTLINE := Color(0.0, 0.0, 0.0)
const SKY_TOP := Color(0.22, 0.45, 0.82)
const SKY_MID := Color(0.52, 0.76, 0.97)
const SKY_HORIZON := Color(0.99, 0.87, 0.70)
const MIST := Color(0.70, 0.77, 0.92)
const VALLEY_BOTTOM := Color(0.32, 0.36, 0.55)

const HEX_BODY := Color(0.53, 0.55, 0.80)
const HEX_SIDE := Color(0.42, 0.44, 0.68)
const HEX_LINE := Color(0.20, 0.20, 0.38)
const HEX_GLOW := Color(0.45, 0.95, 1.0)

const CITY_BODY := Color(0.42, 0.48, 0.64)
const CITY_SIDE := Color(0.31, 0.36, 0.51)
const CITY_WINDOW := Color(1.0, 0.86, 0.45)
const CITY_WINDOW_OFF := Color(0.24, 0.28, 0.40)

const ROCK_BODY := Color(0.46, 0.49, 0.63)     # Hazy blue-gray: reads as distant, not as floor obstacles
const ROCK_SIDE := Color(0.38, 0.41, 0.55)
const ROCK_HI := Color(0.58, 0.61, 0.75)
const ROCK_LINE := Color(0.16, 0.17, 0.30)

const HEX_PERIOD := 2600.0
const CITY_PERIOD := 2200.0
const ROCK_PERIOD := 2400.0
const CLOUD_PERIOD := 3000.0

var _t := 0.0
var _hex_towers: Array[Dictionary] = []
var _city: Array[Dictionary] = []
var _rocks: Array[Dictionary] = []
var _clouds_far: Array[Dictionary] = []
var _clouds_near: Array[Dictionary] = []

## LAYERS (2026-11-14 perf pass): the sky, the Hexagon, the city and the rocks are drawn ONCE and only
## SLIDE (parallax = the node's position). Only the small moving parts (clouds, the emblem, antenna
## lights) are redrawn each frame. Before, the whole backdrop (hundreds of windows) was redrawn every
## frame: the Test Arena ran at ~75 FPS where Story maps ran at 130+ (sweep).
var _layers := {}                        # kind -> Layer
var _static_kinds := ["sky", "hex", "city", "rocks", "dim"]
var _last_size := Vector2.ZERO
var _last_level := -1


class Layer extends Node2D:
	var bg: ArenaBackground
	var kind := ""

	func _draw() -> void:
		bg.paint_layer(self, kind)


func _ready() -> void:
	layer = -10
	_generate()
	for k in ["sky", "clouds_far", "hex", "city", "clouds_near", "rocks", "dim"]:
		_layers[k] = _add_layer(self, k)
	_layers["hex_fx"] = _add_layer(_layers["hex"], "hex_fx")          # Moves with its layer
	_layers["city_fx"] = _add_layer(_layers["city"], "city_fx")
	# MENUS (parent is a Control screen): the 3D floating-arena background instead (Menu3D)
	if get_parent() is Control and Three.enabled():
		var screen := String(get_parent().name)
		Menu3D.build(self, dim, screen == "MainMenu" or screen == "PreFight")
		for k in _layers:
			(_layers[k] as Node2D).visible = false
		_menu_3d = true


func _add_layer(parent: Node, kind: String) -> Layer:
	var l := Layer.new()
	l.bg = self
	l.kind = kind
	parent.add_child(l)
	return l


var _menu_3d := false


func _process(delta: float) -> void:
	if _menu_3d:
		return                                   # The 3D view animates itself
	_t += delta
	var size := get_viewport().get_visible_rect().size
	var cam := _camera_pos()
	var dy := cam.y - 300.0
	# Static layers: redrawn only when the screen size or the graphics level changes
	if size != _last_size or GraphicsSettings.level != _last_level:
		_last_size = size
		_last_level = GraphicsSettings.level
		for k in _static_kinds:
			(_layers[k] as Node2D).queue_redraw()
	(_layers["sky"] as Node2D).position.y = -dy * 0.03
	(_layers["hex"] as Node2D).position = Vector2(fposmod(-cam.x * 0.05, HEX_PERIOD) - HEX_PERIOD, -dy * 0.03)
	(_layers["city"] as Node2D).position = Vector2(fposmod(-cam.x * 0.15, CITY_PERIOD) - CITY_PERIOD, -dy * 0.07)
	(_layers["rocks"] as Node2D).position = Vector2(fposmod(-cam.x * 0.32, ROCK_PERIOD) - ROCK_PERIOD, -dy * 0.11)
	if GraphicsSettings.bg_should_redraw():
		for k in ["clouds_far", "clouds_near", "hex_fx", "city_fx"]:
			(_layers[k] as Node2D).queue_redraw()


func _camera_pos() -> Vector2:
	var cam := get_viewport().get_camera_2d()
	if cam != null:
		return cam.get_screen_center_position()
	return Vector2(_t * auto_scroll_speed, 300.0)


# ============================================================
# GENERATION
# ============================================================
func _generate() -> void:
	var rng := RandomNumberGenerator.new()
	rng.seed = seed_value

	# --- Hexagon towers: flanking spires + the giant HQ tower (drawn last) ---
	for hx in [180.0, 430.0, 640.0, 1160.0, 1390.0, 1830.0, 2220.0]:
		_hex_towers.append({"x": hx, "w": rng.randf_range(46.0, 80.0), "h": rng.randf_range(150.0, 280.0), "main": false})
	_hex_towers.append({"x": 900.0, "w": 130.0, "h": 400.0, "main": true})

	# --- City skyline ---
	var x := 0.0
	while x < CITY_PERIOD - 60.0:
		var w := rng.randf_range(70.0, 150.0)
		var h := rng.randf_range(90.0, 230.0)
		var lit: Array[bool] = []
		for i in 80:
			lit.append(rng.randf() < 0.35)
		_city.append({"x": x, "w": w, "h": h, "roof": rng.randi_range(0, 3), "lit": lit})
		x += w + rng.randf_range(8.0, 40.0)

	# --- Rocky spires ---
	x = 0.0
	while x < ROCK_PERIOD - 100.0:
		var w := rng.randf_range(180.0, 340.0)
		var pts := PackedVector2Array([Vector2(0, 0)])
		var steps := rng.randi_range(4, 7)
		for i in range(1, steps):
			var px := w * float(i) / float(steps)
			var peak := sin(PI * float(i) / float(steps))
			pts.append(Vector2(px + rng.randf_range(-10.0, 10.0), -peak * rng.randf_range(70.0, 190.0)))
		pts.append(Vector2(w, 0))
		_rocks.append({"x": x, "pts": pts})
		x += w * rng.randf_range(0.55, 0.9)

	# --- Clouds ---
	for i in 7:
		_clouds_far.append(_make_cloud(rng, CLOUD_PERIOD * float(i) / 7.0 + rng.randf_range(-80.0, 80.0), rng.randf_range(0.08, 0.34), rng.randf_range(0.55, 0.9)))
	for i in 4:
		_clouds_near.append(_make_cloud(rng, CLOUD_PERIOD * float(i) / 4.0 + rng.randf_range(-150.0, 150.0), rng.randf_range(0.04, 0.24), rng.randf_range(1.1, 1.5)))


func _make_cloud(rng: RandomNumberGenerator, x: float, y_frac: float, s: float) -> Dictionary:
	var puffs: Array[Dictionary] = []
	var n := rng.randi_range(4, 6)
	for i in n:
		var px := lerpf(-70.0, 70.0, float(i) / float(n - 1)) + rng.randf_range(-8.0, 8.0)
		var r := rng.randf_range(24.0, 38.0) * (1.0 - absf(px) / 140.0 * 0.5)
		puffs.append({"o": Vector2(px, -r * 0.6 + rng.randf_range(-5.0, 5.0)), "r": r})
	return {"x": x, "y": y_frac, "s": s, "puffs": puffs}


# ============================================================
# PAINTING
# ============================================================
## One layer. Static layers are drawn in their own space: x from 0 to `span` (whole periods), the
## horizon as if the camera were at y = 300; _process slides them.
func paint_layer(c: CanvasItem, kind: String) -> void:
	var size := get_viewport().get_visible_rect().size
	var w := size.x
	var h := size.y
	var hb := h + 260.0                                # Bottom edge with room for the vertical slide
	var horizon := h * 0.62
	var cam := _camera_pos()
	_cull = false
	match kind:
		"sky":
			_grad(c, -200.0, horizon * 0.55, w, SKY_TOP, SKY_MID)
			_grad(c, horizon * 0.55, horizon, w, SKY_MID, SKY_HORIZON)
			_grad(c, horizon, hb, w, SKY_HORIZON, VALLEY_BOTTOM)
			_draw_sun(c, Vector2(w * 0.8, h * 0.2))
		"clouds_far":
			if GraphicsSettings.bg_full():
				_draw_clouds(c, _clouds_far, -cam.x * 0.03 - _t * 6.0, w, h, 0.85)
		"clouds_near":
			if GraphicsSettings.bg_detail():
				_draw_clouds(c, _clouds_near, -cam.x * 0.2 - _t * 12.0, w, h, 0.95)
		"hex":
			var span := _span(HEX_PERIOD, w)
			for start in _tile_starts(HEX_PERIOD, span):
				for tw in _hex_towers:
					_draw_hex_tower(c, Vector2(start + float(tw["x"]), horizon + 20.0), tw, hb)
			_mist(c, horizon - 10.0, hb, span, 0.75)
		"hex_fx":
			for start in _tile_starts(HEX_PERIOD, _span(HEX_PERIOD, w)):
				for tw in _hex_towers:
					if tw["main"]:
						_draw_hex_emblem(c, Vector2(start + float(tw["x"]), horizon + 20.0), tw)
		"city":
			var span2 := _span(CITY_PERIOD, w)
			var city_base := horizon + 45.0
			for start in _tile_starts(CITY_PERIOD, span2):
				for b in _city:
					_draw_building(c, Vector2(start + float(b["x"]), city_base), b, hb)
			_mist(c, city_base - 25.0, hb, span2, 0.6)
		"city_fx":
			for start in _tile_starts(CITY_PERIOD, _span(CITY_PERIOD, w)):
				for b in _city:
					if int(b["roof"]) == 1:                  # Blinking antenna lights
						var bx := start + float(b["x"]) + float(b["w"]) * 0.4
						var top := horizon + 45.0 - float(b["h"])
						var blink := 1.0 if fmod(_t + (start + float(b["x"])) * 0.01, 1.6) < 0.8 else 0.3
						Dots.circle(c, Vector2(bx, top - 36.0), 4.0, Color(1.0, 0.25, 0.2, blink))
		"rocks":
			var span3 := _span(ROCK_PERIOD, w)
			var rock_base := horizon + 150.0
			for start in _tile_starts(ROCK_PERIOD, span3):
				for r in _rocks:
					_draw_rock(c, Vector2(start + float(r["x"]), rock_base), r["pts"], hb)
			_mist(c, rock_base + 30.0, hb, span3, 0.5)
		"dim":
			if dim > 0.0:
				c.draw_rect(Rect2(0, -300, w, h + 600), Color(0, 0, 0, dim))
	_cull = true


var _cull := true                        # Off while drawing a whole static layer


## Width a sliding layer must cover: the screen + one period on each side.
func _span(period: float, w: float) -> float:
	return period * (ceilf((w + 300.0) / period) + 1.0)


func _tile_starts(period: float, span: float) -> Array[float]:
	var out: Array[float] = []
	var s := 0.0
	while s < span:
		out.append(s)
		s += period
	return out


## Start offsets for a layer that repeats every `period` pixels.
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


func _mist(c: CanvasItem, y: float, h: float, w: float, strength: float) -> void:
	var clear := Color(MIST.r, MIST.g, MIST.b, 0.0)
	var thick := Color(MIST.r, MIST.g, MIST.b, strength)
	_grad(c, y, y + 60.0, w, clear, thick)
	_grad(c, y + 60.0, h + 2.0, w, thick, Color(VALLEY_BOTTOM.r, VALLEY_BOTTOM.g, VALLEY_BOTTOM.b, strength))


func _draw_sun(c: CanvasItem, p: Vector2) -> void:
	c.draw_circle(p, 120.0, Color(1.0, 0.95, 0.75, 0.12))
	c.draw_circle(p, 82.0, Color(1.0, 0.93, 0.70, 0.22))
	c.draw_circle(p, 50.0, Color(0.95, 0.62, 0.28))
	c.draw_circle(p, 46.0, Color(1.0, 0.92, 0.62))
	c.draw_circle(p + Vector2(-14, -14), 14.0, Color(1.0, 0.98, 0.85))


func _draw_clouds(c: CanvasItem, clouds: Array[Dictionary], shift: float, w: float, h: float, alpha: float) -> void:
	for start in _starts(shift, CLOUD_PERIOD, w):
		for cl in clouds:
			var base := Vector2(start + float(cl["x"]), h * float(cl["y"]) + 60.0)
			if base.x < -260.0 or base.x > w + 260.0:
				continue
			var s: float = cl["s"]
			var line := Color(0.22, 0.28, 0.45, alpha)
			for p in cl["puffs"]:                          # (Dots: all puffs batch into one draw call)
				Dots.circle(c, base + p["o"] * s, p["r"] * s + 3.5, line)
			for p in cl["puffs"]:
				Dots.circle(c, base + p["o"] * s, p["r"] * s, Color(0.80, 0.87, 0.97, alpha))
			for p in cl["puffs"]:
				var r: float = p["r"] * s
				Dots.circle(c, base + p["o"] * s + Vector2(-r * 0.1, -r * 0.18), r * 0.8, Color(1, 1, 1, alpha))


static func _hex(center: Vector2, r: float, rot: float = 0.0) -> PackedVector2Array:
	var pts := PackedVector2Array()
	for i in 6:
		var a := rot + TAU * float(i) / 6.0
		pts.append(center + Vector2(cos(a), sin(a)) * r)
	return pts


func _closed(c: CanvasItem, pts: PackedVector2Array, col: Color, w: float) -> void:
	var closed := pts.duplicate()
	closed.append(pts[0])
	c.draw_polyline(closed, col, w, FighterArt.AA)


func _draw_hex_tower(c: CanvasItem, base: Vector2, tw: Dictionary, h: float) -> void:
	if _cull and (base.x < -300.0 or base.x > c.get_viewport_rect().size.x + 300.0):
		return
	var w: float = tw["w"]
	var th: float = tw["h"]
	var top := base.y - th
	var body := PackedVector2Array([
		Vector2(base.x - w * 0.5, h + 10.0), Vector2(base.x - w * 0.5, top),
		Vector2(base.x + w * 0.5, top), Vector2(base.x + w * 0.5, h + 10.0)])
	c.draw_colored_polygon(body, HEX_BODY)
	c.draw_rect(Rect2(base.x + w * 0.2, top, w * 0.3, h + 10.0 - top), HEX_SIDE)
	# Hexagonal crown
	var cap_h := w * 0.45
	var crown := PackedVector2Array([
		Vector2(base.x - w * 0.5, top), Vector2(base.x - w * 0.3, top - cap_h),
		Vector2(base.x + w * 0.3, top - cap_h), Vector2(base.x + w * 0.5, top)])
	c.draw_colored_polygon(crown, HEX_SIDE)
	_closed(c, crown, HEX_LINE, 3.0)
	_closed(c, body, HEX_LINE, 3.0)
	# Glowing hexagon windows
	var cols := 2 if w < 70.0 else 3
	var y := top + 18.0
	var row := 0
	while y < base.y - 10.0:
		for i in cols:
			var wx := base.x - w * 0.5 + w * (float(i) + 0.5) / float(cols)
			var on := (row + i + int(tw["x"])) % 3 != 0
			c.draw_colored_polygon(_hex(Vector2(wx, y), 5.0), HEX_GLOW if on else HEX_SIDE)
		y += 26.0
		row += 1


## The Hexagon emblem floating above the HQ tower, slowly rotating (the "hex_fx" layer, every frame).
func _draw_hex_emblem(c: CanvasItem, base: Vector2, tw: Dictionary) -> void:
	var w: float = tw["w"]
	var top := base.y - float(tw["h"])
	var cap_h := w * 0.45
	var ec := Vector2(base.x, top - cap_h - 70.0)
	var pulse := 0.5 + 0.5 * sin(_t * 1.6)
	c.draw_line(Vector2(base.x, top - cap_h), ec, Color(HEX_GLOW.r, HEX_GLOW.g, HEX_GLOW.b, 0.6), 4.0)
	c.draw_circle(ec, 80.0 + 8.0 * pulse, Color(HEX_GLOW.r, HEX_GLOW.g, HEX_GLOW.b, 0.12 + 0.08 * pulse))
	var ring := _hex(ec, 52.0, _t * 0.25)
	_closed(c, ring, HEX_LINE, 12.0)
	_closed(c, ring, HEX_GLOW, 6.0)
	var core := _hex(ec, 20.0, -_t * 0.4)
	c.draw_colored_polygon(core, HEX_GLOW)
	_closed(c, core, HEX_LINE, 3.0)


func _draw_building(c: CanvasItem, base: Vector2, b: Dictionary, h: float) -> void:
	var w: float = b["w"]
	if _cull and (base.x + w < -40.0 or base.x > c.get_viewport_rect().size.x + 40.0):
		return
	var bh: float = b["h"]
	var top := base.y - bh
	var rect := Rect2(base.x, top, w, h + 10.0 - top)
	c.draw_rect(rect, CITY_BODY)
	c.draw_rect(Rect2(base.x + w * 0.78, top, w * 0.22, rect.size.y), CITY_SIDE)
	# Windows (dozens of rects per building: skipped on Potato)
	var lit: Array = b["lit"]
	var i := 0
	var wy := top + 14.0
	while wy < base.y - 6.0 and GraphicsSettings.bg_detail():
		var wx := base.x + 9.0
		while wx < base.x + w * 0.78 - 14.0:
			c.draw_rect(Rect2(wx, wy, 8, 11), CITY_WINDOW if lit[i % lit.size()] else CITY_WINDOW_OFF)
			wx += 17.0
			i += 1
		wy += 22.0
	# Roof
	match int(b["roof"]):
		1:  # Antenna (its blinking light is the "city_fx" layer)
			c.draw_line(Vector2(base.x + w * 0.4, top), Vector2(base.x + w * 0.4, top - 34.0), OUTLINE, 3.0)
		2:  # Small hex dome
			var dome := _hex(Vector2(base.x + w * 0.4, top), w * 0.22, PI / 6.0)
			c.draw_colored_polygon(dome, CITY_SIDE)
			c.draw_colored_polygon(_hex(Vector2(base.x + w * 0.4, top - 2.0), w * 0.08, PI / 6.0), HEX_GLOW)
			_closed(c, dome, OUTLINE, 3.0)
		3:  # Slanted roof
			var slant := PackedVector2Array([Vector2(base.x, top), Vector2(base.x + w, top - 22.0), Vector2(base.x + w, top)])
			c.draw_colored_polygon(slant, CITY_SIDE)
			_closed(c, slant, OUTLINE, 3.0)
		_:  # Flat with ledge
			c.draw_rect(Rect2(base.x - 4.0, top - 6.0, w + 8.0, 8.0), CITY_SIDE)
			c.draw_rect(Rect2(base.x - 4.0, top - 6.0, w + 8.0, 8.0), OUTLINE, false, 3.0)
	c.draw_rect(rect, OUTLINE, false, 3.0)


static func _min_y(pts: PackedVector2Array) -> float:
	var m := INF
	for p in pts:
		m = minf(m, p.y)
	return m


func _draw_rock(c: CanvasItem, base: Vector2, pts: PackedVector2Array, h: float) -> void:
	var last: Vector2 = pts[pts.size() - 1]
	if _cull and (base.x + last.x < -40.0 or base.x > c.get_viewport_rect().size.x + 40.0):
		return
	var poly := PackedVector2Array()
	poly.append(Vector2(base.x, h + 10.0))
	for p in pts:
		var q := base + p
		q.y = minf(q.y, h + 9.0)                     # Small views (Map Catalogue thumbnails): never below the bottom edge
		poly.append(q)
	poly.append(Vector2(base.x + last.x, h + 10.0))
	if base.y + _min_y(pts) >= h + 9.0:
		return                                       # Entirely below the view
	c.draw_colored_polygon(poly, ROCK_BODY)
	# Shaded right faces + highlight on left faces of each peak
	for i in range(1, pts.size()):
		var a := base + pts[i - 1]
		var b := base + pts[i]
		a.y = minf(a.y, h + 9.0)
		b.y = minf(b.y, h + 9.0)
		if absf(b.y - a.y) < 0.5 and a.y >= h + 9.0:
			continue
		if b.y > a.y:   # Descending slope = shadow side
			c.draw_colored_polygon(PackedVector2Array([a, b, Vector2(b.x, h + 10.0), Vector2(a.x, h + 10.0)]), ROCK_SIDE)
		else:
			c.draw_line(a + Vector2(4, 4), b + Vector2(4, 6), ROCK_HI, 3.0)
	_closed(c, poly, ROCK_LINE, 3.0)
