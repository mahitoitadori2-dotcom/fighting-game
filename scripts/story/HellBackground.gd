class_name HellBackground
extends CanvasLayer
## STORY MODE backdrop (screen space, behind everything).
##   "surface": a burning wasteland - blood-red sky, ash clouds, jagged black mountains,
##              an erupting volcano, a dark spire on a crag, lava rivers on the horizon.
##   "cave":    deep under the ground - stalactites, rock pillars, glowing lava falls.
## The landscape is drawn ONCE (redrawn only on resize); only the drifting embers animate.

##   "geode":   a crystal cavern - giant amethyst geodes, violet glow, amber veins (Rock Golem).
##   "hive":    the Kharleming nest - scrap heaps, hanging cables, egg pods, blinking cyan eyes.
##   "lab":     the Blinded Lord's laboratory - glass chemical chambers with rotted skeletons
##              floating inside, pipes and tubes full of toxic green, shelves of flasks.
## COLOSSEUM 2:
##   "elevator":    the shaft of the Elevator from Hell - girders and warning lamps rushing
##                  DOWN past you (you ride up), hell glowing far below, light far above.
##   "enlightened": Home of the Enlightened Ones - white marble city, golden domes, a huge
##                  sun with rays, floating halos, rising motes of light.
##   "sewer":       the sewers - brick arches, big pipes pouring dirty water, a slime channel,
##                  green fog; animated drips.
##   "blasphemy":   Blasphemy Caeser's arena - a volcanic temple: blood sky, lava falls, a
##                  colossal serpent skeleton coiled around broken columns.
@export_enum("surface", "cave", "geode", "hive", "lab", "elevator", "enlightened", "sewer", "blasphemy") var theme := "surface":
	set(v):
		theme = v
		if _painter != null:
			_painter.queue_redraw()

var _painter: Control
var _embers: Node2D
var _ember_data: Array[Vector3] = []       # x (0..1), speed, size
var _t := 0.0


func _ready() -> void:
	layer = -10
	_painter = Control.new()
	_painter.set_anchors_and_offsets_preset(Control.PRESET_FULL_RECT)
	_painter.mouse_filter = Control.MOUSE_FILTER_IGNORE
	add_child(_painter)
	_painter.draw.connect(_paint)
	_painter.resized.connect(_painter.queue_redraw)
	_embers = Node2D.new()
	add_child(_embers)
	_embers.draw.connect(_paint_embers)
	var rng := RandomNumberGenerator.new()
	rng.seed = 7
	for i in 36:
		_ember_data.append(Vector3(rng.randf(), rng.randf_range(20.0, 70.0), rng.randf_range(1.5, 3.5)))


func _process(delta: float) -> void:
	_t += delta
	_embers.queue_redraw()


# ============================================================
# STATIC LANDSCAPE
# ============================================================
func _paint() -> void:
	var sz := _painter.size
	if sz.x <= 1.0:
		return
	match theme:
		"cave":
			_paint_cave(sz)
		"geode":
			_paint_geode(sz)
		"hive":
			_paint_hive(sz)
		"lab":
			_paint_lab(sz)
		"elevator":
			_paint_elevator(sz)
		"enlightened":
			_paint_enlightened(sz)
		"sewer":
			_paint_sewer(sz)
		"blasphemy":
			_paint_blasphemy(sz)
		_:
			_paint_surface(sz)


func _vgradient(sz: Vector2, top: Color, mid: Color, bottom: Color, mid_at: float) -> void:
	var pts := PackedVector2Array([Vector2(0, 0), Vector2(sz.x, 0), Vector2(sz.x, sz.y * mid_at), Vector2(0, sz.y * mid_at)])
	_painter.draw_polygon(pts, PackedColorArray([top, top, mid, mid]))
	pts = PackedVector2Array([Vector2(0, sz.y * mid_at), Vector2(sz.x, sz.y * mid_at), Vector2(sz.x, sz.y), Vector2(0, sz.y)])
	_painter.draw_polygon(pts, PackedColorArray([mid, mid, bottom, bottom]))


func _ridge(sz: Vector2, base_y: float, amp: float, step: float, col: Color, seed_v: int) -> void:
	var rng := RandomNumberGenerator.new()
	rng.seed = seed_v
	var pts := PackedVector2Array([Vector2(0, sz.y)])
	var x := -20.0
	while x < sz.x + 40.0:
		pts.append(Vector2(x, base_y - rng.randf_range(0.2, 1.0) * amp))
		x += rng.randf_range(step * 0.5, step)
		pts.append(Vector2(x, base_y - rng.randf_range(0.0, 0.35) * amp))
		x += rng.randf_range(step * 0.3, step * 0.7)
	pts.append(Vector2(sz.x + 40.0, sz.y))
	_painter.draw_colored_polygon(pts, col)


func _paint_surface(sz: Vector2) -> void:
	_vgradient(sz, Color(0.08, 0.02, 0.03), Color(0.55, 0.10, 0.04), Color(0.95, 0.38, 0.08), 0.55)
	# Ash clouds (dark streaks across the sky)
	var rng := RandomNumberGenerator.new()
	rng.seed = 3
	for i in 9:
		var cy := rng.randf_range(0.05, 0.4) * sz.y
		var cx := rng.randf() * sz.x
		_painter.draw_set_transform(Vector2(cx, cy), 0.0, Vector2(1.0, 0.18))
		_painter.draw_circle(Vector2.ZERO, rng.randf_range(160.0, 320.0), Color(0.05, 0.02, 0.02, 0.35))
	_painter.draw_set_transform(Vector2.ZERO, 0.0, Vector2.ONE)
	# Volcano (right) with glowing crater + lava streams
	var vx := sz.x * 0.72
	var vb := sz.y * 0.78
	var volcano := PackedVector2Array([Vector2(vx - 330, vb), Vector2(vx - 60, sz.y * 0.36), Vector2(vx + 50, sz.y * 0.36), Vector2(vx + 340, vb)])
	_painter.draw_colored_polygon(volcano, Color(0.12, 0.05, 0.05))
	_painter.draw_circle(Vector2(vx - 5, sz.y * 0.35), 80.0, Color(1.0, 0.45, 0.1, 0.25))
	_painter.draw_line(Vector2(vx - 55, sz.y * 0.36), Vector2(vx + 45, sz.y * 0.36), Color(1.0, 0.65, 0.2), 6.0)
	for k in 3:
		var sx := vx - 40.0 + float(k) * 35.0
		_painter.draw_polyline(PackedVector2Array([Vector2(sx, sz.y * 0.37), Vector2(sx - 20.0 + float(k) * 10.0, sz.y * 0.5), Vector2(sx - 50.0 + float(k) * 30.0, sz.y * 0.65), Vector2(sx - 80.0 + float(k) * 50.0, vb)]), Color(1.0, 0.4, 0.08, 0.85), 4.0, true)
	# Smoke column
	for k in 6:
		_painter.draw_circle(Vector2(vx + float(k) * 18.0 - 10.0, sz.y * 0.3 - float(k) * 45.0), 40.0 + float(k) * 14.0, Color(0.08, 0.03, 0.03, 0.5))
	# Dark spire on a crag (left)
	var tx := sz.x * 0.16
	var crag := PackedVector2Array([Vector2(tx - 110, vb), Vector2(tx - 40, sz.y * 0.52), Vector2(tx + 40, sz.y * 0.5), Vector2(tx + 120, vb)])
	_painter.draw_colored_polygon(crag, Color(0.06, 0.02, 0.03))
	var spire := PackedVector2Array([Vector2(tx - 26, sz.y * 0.52), Vector2(tx - 14, sz.y * 0.16), Vector2(tx - 30, sz.y * 0.12), Vector2(tx - 4, sz.y * 0.04), Vector2(tx + 22, sz.y * 0.12), Vector2(tx + 8, sz.y * 0.16), Vector2(tx + 24, sz.y * 0.52)])
	_painter.draw_colored_polygon(spire, Color(0.04, 0.01, 0.02))
	for k in 4:                                                   # Lit windows
		_painter.draw_rect(Rect2(tx - 4, sz.y * (0.2 + float(k) * 0.07), 6, 9), Color(1.0, 0.5, 0.1, 0.8))
	# Mountain ranges (back -> front)
	_ridge(sz, sz.y * 0.74, 150.0, 120.0, Color(0.16, 0.05, 0.05), 11)
	_ridge(sz, sz.y * 0.84, 110.0, 90.0, Color(0.08, 0.03, 0.03), 12)
	# Lava river glow on the horizon
	_painter.draw_rect(Rect2(0, sz.y * 0.86, sz.x, 8), Color(1.0, 0.45, 0.1, 0.7))
	_painter.draw_rect(Rect2(0, sz.y * 0.86 + 8, sz.x, sz.y * 0.14), Color(0.05, 0.02, 0.02))


func _paint_cave(sz: Vector2) -> void:
	_vgradient(sz, Color(0.03, 0.02, 0.02), Color(0.10, 0.05, 0.04), Color(0.30, 0.09, 0.03), 0.6)
	var rng := RandomNumberGenerator.new()
	rng.seed = 21
	# Lava falls in the distance
	for i in 3:
		var fx := sz.x * (0.18 + 0.32 * float(i)) + rng.randf_range(-40.0, 40.0)
		var w := rng.randf_range(16.0, 28.0)
		_painter.draw_rect(Rect2(fx - w * 2.0, 0, w * 4.0, sz.y), Color(1.0, 0.35, 0.05, 0.08))
		_painter.draw_rect(Rect2(fx - w * 0.5, 0, w, sz.y * 0.85), Color(1.0, 0.45, 0.1, 0.55))
		_painter.draw_rect(Rect2(fx - w * 0.15, 0, w * 0.3, sz.y * 0.85), Color(1.0, 0.85, 0.4, 0.6))
	# Rock pillars
	for i in 5:
		var px := rng.randf() * sz.x
		var pw := rng.randf_range(50.0, 110.0)
		var pts := PackedVector2Array([Vector2(px - pw * 0.6, 0), Vector2(px + pw * 0.6, 0), Vector2(px + pw * 0.35, sz.y * 0.45), Vector2(px + pw * 0.7, sz.y), Vector2(px - pw * 0.7, sz.y), Vector2(px - pw * 0.35, sz.y * 0.45)])
		_painter.draw_colored_polygon(pts, Color(0.07, 0.04, 0.04))
	# Stalactites from the ceiling
	var x := -20.0
	while x < sz.x + 20.0:
		var w := rng.randf_range(30.0, 80.0)
		var l := rng.randf_range(60.0, 220.0)
		_painter.draw_colored_polygon(PackedVector2Array([Vector2(x, -2), Vector2(x + w, -2), Vector2(x + w * 0.5 + rng.randf_range(-8.0, 8.0), l)]), Color(0.05, 0.03, 0.03))
		x += w * rng.randf_range(0.6, 1.0)
	# Floor rubble silhouette + lava glow
	_ridge(sz, sz.y * 0.88, 70.0, 70.0, Color(0.04, 0.02, 0.02), 31)
	_painter.draw_rect(Rect2(0, sz.y * 0.9, sz.x, 6), Color(1.0, 0.4, 0.08, 0.5))


func _shard(p: Vector2, ang: float, len: float, w: float, col: Color, hi: Color) -> void:
	var d := Vector2.from_angle(ang)
	var n := d.orthogonal() * w
	var pts := PackedVector2Array([p + n, p + n + d * len * 0.8, p + d * len, p - n + d * len * 0.8, p - n])
	_painter.draw_colored_polygon(pts, col)
	_painter.draw_colored_polygon(PackedVector2Array([p + n * 0.15, p + n * 0.15 + d * len * 0.8, p + d * len, p]), hi)


func _paint_geode(sz: Vector2) -> void:
	_vgradient(sz, Color(0.04, 0.02, 0.07), Color(0.13, 0.06, 0.20), Color(0.22, 0.10, 0.30), 0.55)
	var rng := RandomNumberGenerator.new()
	rng.seed = 51
	# Giant geode openings with crystal rings
	for g in [Vector3(0.22, 0.38, 150.0), Vector3(0.78, 0.30, 190.0), Vector3(0.52, 0.62, 110.0)]:
		var c := Vector2(g.x * sz.x, g.y * sz.y)
		_painter.draw_circle(c, g.z * 1.3, Color(0.6, 0.3, 0.9, 0.10))
		_painter.draw_circle(c, g.z, Color(0.10, 0.05, 0.14))
		for i in 18:
			var a := TAU * float(i) / 18.0 + rng.randf_range(-0.1, 0.1)
			_shard(c + Vector2.from_angle(a) * g.z, a + PI, g.z * rng.randf_range(0.35, 0.6), g.z * 0.08,
				Color(0.55, 0.30, 0.85, 0.85), Color(0.85, 0.70, 1.0, 0.85))
		_painter.draw_circle(c, g.z * 0.25, Color(1.0, 0.75, 0.35, 0.25))           # Amber heart
	# Crystal spikes from ceiling and floor silhouettes
	var x := -20.0
	while x < sz.x + 20.0:
		_shard(Vector2(x, -4), PI * 0.5 + rng.randf_range(-0.2, 0.2), rng.randf_range(50.0, 160.0), rng.randf_range(10.0, 22.0), Color(0.12, 0.07, 0.17), Color(0.25, 0.15, 0.35))
		x += rng.randf_range(40.0, 90.0)
	_ridge(sz, sz.y * 0.9, 60.0, 60.0, Color(0.06, 0.03, 0.09), 52)
	_painter.draw_rect(Rect2(0, sz.y * 0.9, sz.x, 5), Color(0.75, 0.45, 1.0, 0.45))


func _paint_hive(sz: Vector2) -> void:
	_vgradient(sz, Color(0.02, 0.03, 0.04), Color(0.07, 0.08, 0.09), Color(0.13, 0.10, 0.08), 0.6)
	var rng := RandomNumberGenerator.new()
	rng.seed = 61
	# Hanging cables
	for i in 10:
		var cx := rng.randf() * sz.x
		var sag := rng.randf_range(60.0, 220.0)
		var pts := PackedVector2Array()
		for k in 9:
			var t := float(k) / 8.0
			pts.append(Vector2(cx + (t - 0.5) * 240.0, sin(t * PI) * sag))
		_painter.draw_polyline(pts, Color(0.03, 0.03, 0.04), 4.0, true)
	# Scrap heaps (silhouettes of plates, pipes, gears)
	for i in 7:
		var hx := rng.randf() * sz.x
		var hw := rng.randf_range(120.0, 260.0)
		var hy := sz.y * rng.randf_range(0.62, 0.8)
		_painter.draw_colored_polygon(PackedVector2Array([Vector2(hx - hw, sz.y), Vector2(hx - hw * 0.4, hy + 20.0), Vector2(hx, hy), Vector2(hx + hw * 0.5, hy + 30.0), Vector2(hx + hw, sz.y)]), Color(0.08, 0.08, 0.09))
		_painter.draw_arc(Vector2(hx + hw * 0.2, hy + 10.0), 22.0, 0.0, TAU, 12, Color(0.12, 0.12, 0.13), 6.0)   # Gear
		_painter.draw_line(Vector2(hx - hw * 0.5, hy + 30.0), Vector2(hx + hw * 0.1, hy - 30.0), Color(0.12, 0.12, 0.13), 7.0)  # Pipe
	# Egg pods (glowing cyan cocoons) on the far wall
	for i in 8:
		var p := Vector2(rng.randf() * sz.x, sz.y * rng.randf_range(0.2, 0.55))
		_painter.draw_set_transform(p, rng.randf_range(-0.3, 0.3), Vector2(0.7, 1.0))
		_painter.draw_circle(Vector2.ZERO, 24.0, Color(0.2, 0.9, 0.9, 0.08))
		_painter.draw_circle(Vector2.ZERO, 14.0, Color(0.10, 0.16, 0.17))
		_painter.draw_circle(Vector2.ZERO, 6.0, Color(0.3, 0.95, 0.95, 0.35))
	_painter.draw_set_transform(Vector2.ZERO, 0.0, Vector2.ONE)
	_ridge(sz, sz.y * 0.9, 50.0, 50.0, Color(0.05, 0.05, 0.06), 62)
	_painter.draw_rect(Rect2(0, sz.y * 0.9, sz.x, 4), Color(0.3, 0.95, 0.95, 0.35))


## Glass chamber rects of the lab (shared by the static painter and the bubbles).
func _lab_chambers(sz: Vector2) -> Array[Rect2]:
	var list: Array[Rect2] = []
	for fx in [0.10, 0.29, 0.71, 0.90]:
		var w := 120.0
		list.append(Rect2(sz.x * fx - w * 0.5, sz.y * 0.16, w, sz.y * 0.62))
	return list


func _paint_lab(sz: Vector2) -> void:
	_vgradient(sz, Color(0.03, 0.05, 0.05), Color(0.07, 0.10, 0.09), Color(0.10, 0.14, 0.10), 0.6)
	var p := _painter
	# Tiled back wall
	var tile := 64.0
	var y := 0.0
	while y < sz.y:
		p.draw_line(Vector2(0, y), Vector2(sz.x, y), Color(0.12, 0.16, 0.14), 2.0)
		y += tile
	var x := 0.0
	while x < sz.x:
		p.draw_line(Vector2(x, 0), Vector2(x, sz.y), Color(0.12, 0.16, 0.14), 2.0)
		x += tile
	# Shelves of flasks in the middle
	for row in 3:
		var sy := sz.y * (0.3 + 0.14 * float(row))
		p.draw_rect(Rect2(sz.x * 0.4, sy, sz.x * 0.2, 6), Color(0.22, 0.15, 0.10))
		for k in 7:
			var fx := sz.x * 0.41 + float(k) * sz.x * 0.027
			var col: Color = [Color(0.45, 1.0, 0.2), Color(0.9, 0.8, 0.2), Color(0.3, 0.8, 1.0), Color(0.8, 0.3, 0.9)][(k + row) % 4]
			p.draw_circle(Vector2(fx, sy - 9.0), 7.0, Color(col.r, col.g, col.b, 0.55))
			p.draw_rect(Rect2(fx - 2.0, sy - 22.0, 4, 8), Color(0.6, 0.7, 0.7, 0.5))
	# Pipes across the ceiling, dropping into each chamber
	var chambers := _lab_chambers(sz)
	p.draw_line(Vector2(0, sz.y * 0.07), Vector2(sz.x, sz.y * 0.07), Color(0, 0, 0), 26.0)
	p.draw_line(Vector2(0, sz.y * 0.07), Vector2(sz.x, sz.y * 0.07), Color(0.25, 0.30, 0.28), 20.0)
	p.draw_line(Vector2(0, sz.y * 0.07 - 4.0), Vector2(sz.x, sz.y * 0.07 - 4.0), Color(0.40, 0.46, 0.42), 4.0)
	for ch in chambers:
		var px := ch.get_center().x
		p.draw_line(Vector2(px, sz.y * 0.07), Vector2(px, ch.position.y), Color(0, 0, 0), 16.0)
		p.draw_line(Vector2(px, sz.y * 0.07), Vector2(px, ch.position.y), Color(0.25, 0.30, 0.28), 11.0)
		p.draw_line(Vector2(px, sz.y * 0.07), Vector2(px, ch.position.y), Color(0.45, 1.0, 0.2, 0.6), 3.0)   # Chemical flowing in
		p.draw_circle(Vector2(px, sz.y * 0.07), 12.0, Color(0.5, 0.15, 0.12))                              # Valve
	# Glass chambers with rotted skeletons floating in green liquid
	var rng := RandomNumberGenerator.new()
	rng.seed = 13
	for ch in chambers:
		var r := ch
		p.draw_rect(r.grow(10.0), Color(0, 0, 0))
		p.draw_rect(Rect2(r.position.x - 8, r.position.y - 16, r.size.x + 16, 18), Color(0.30, 0.34, 0.32))  # Cap
		p.draw_rect(Rect2(r.position.x - 8, r.end.y - 2, r.size.x + 16, 22), Color(0.30, 0.34, 0.32))        # Base
		p.draw_rect(r, Color(0.20, 0.55, 0.12, 0.55))                                                          # Liquid
		p.draw_rect(Rect2(r.position, Vector2(r.size.x, 18)), Color(0.10, 0.25, 0.08, 0.6))                    # Air gap
		_skeleton(r.get_center() + Vector2(rng.randf_range(-8, 8), rng.randf_range(-10, 30)), rng.randf_range(-0.35, 0.35), 0.9 + rng.randf() * 0.2)
		p.draw_rect(r, Color(0.7, 1.0, 0.7, 0.12))                                                             # Glass tint
		p.draw_line(r.position + Vector2(14, 24), Vector2(r.position.x + 14, r.end.y - 14), Color(1, 1, 1, 0.35), 5.0)  # Glare
		p.draw_rect(r.grow(10.0), Color(0, 0, 0), false, 4.0)
	# Floor glow strip
	p.draw_rect(Rect2(0, sz.y * 0.9, sz.x, 5), Color(0.45, 1.0, 0.2, 0.4))


## A rotted skeleton floating in a tank (sickly bone colour, missing pieces).
func _skeleton(c: Vector2, tilt: float, s: float) -> void:
	var p := _painter
	var bone := Color(0.78, 0.74, 0.52)
	var dark := Color(0.12, 0.10, 0.06)
	p.draw_set_transform(c, tilt, Vector2(s, s))
	# Skull
	p.draw_circle(Vector2(0, -92), 19.0, dark)
	p.draw_circle(Vector2(0, -92), 17.0, bone)
	p.draw_circle(Vector2(-6, -94), 5.0, dark)
	p.draw_circle(Vector2(7, -94), 5.0, dark)
	p.draw_colored_polygon(PackedVector2Array([Vector2(-2, -86), Vector2(2, -86), Vector2(0, -81)]), dark)
	p.draw_rect(Rect2(-10, -78, 20, 7), bone)
	for k in 4:
		p.draw_line(Vector2(-7 + float(k) * 5.0, -78), Vector2(-7 + float(k) * 5.0, -71), dark, 1.5)
	# Spine + ribs
	p.draw_line(Vector2(0, -70), Vector2(0, 10), dark, 7.0)
	p.draw_line(Vector2(0, -70), Vector2(0, 10), bone, 4.0)
	for k in 5:
		var ry := -60.0 + float(k) * 11.0
		p.draw_arc(Vector2(0, ry + 8.0), 20.0 - float(k) * 1.5, PI * 1.1, PI * 1.9, 10, dark, 5.0)
		p.draw_arc(Vector2(0, ry + 8.0), 20.0 - float(k) * 1.5, PI * 1.1, PI * 1.9, 10, bone, 2.5)
	# Pelvis + dangling limbs (one arm missing)
	p.draw_colored_polygon(PackedVector2Array([Vector2(-14, 8), Vector2(14, 8), Vector2(8, 22), Vector2(-8, 22)]), bone)
	for seg in [[Vector2(-18, -62), Vector2(-26, -30), Vector2(-22, 0)], [Vector2(-6, 22), Vector2(-10, 60), Vector2(-6, 96)], [Vector2(6, 22), Vector2(14, 58), Vector2(10, 92)]]:
		var line := PackedVector2Array(seg)
		p.draw_polyline(line, dark, 6.0, true)
		p.draw_polyline(line, bone, 3.5, true)
	p.draw_set_transform(Vector2.ZERO, 0.0, Vector2.ONE)


# ============================================================
# COLOSSEUM 2 LANDSCAPES
# ============================================================
func _paint_elevator(sz: Vector2) -> void:
	var p := _painter
	_vgradient(sz, Color(0.10, 0.10, 0.13), Color(0.05, 0.04, 0.06), Color(0.35, 0.07, 0.03), 0.55)
	p.draw_circle(Vector2(sz.x * 0.5, -sz.y * 0.4), sz.y * 0.6, Color(0.8, 0.85, 1.0, 0.07))      # Light far above
	# Far shaft wall: riveted panels
	for row in int(sz.y / 90.0) + 1:
		for col in int(sz.x / 140.0) + 1:
			var r := Rect2(float(col) * 140.0 + (70.0 if row % 2 == 0 else 0.0) - 70.0, float(row) * 90.0, 136.0, 86.0)
			p.draw_rect(r, Color(0.09, 0.09, 0.11))
			p.draw_rect(r, Color(0.04, 0.04, 0.05), false, 2.0)
	# Guide rails (the elevator rides on them)
	for rx in [0.3, 0.7]:
		p.draw_rect(Rect2(sz.x * rx - 14.0, 0, 28.0, sz.y), Color(0.16, 0.16, 0.18))
		p.draw_rect(Rect2(sz.x * rx - 4.0, 0, 8.0, sz.y), Color(0.3, 0.3, 0.33))
	# Hell glow far below
	p.draw_rect(Rect2(0, sz.y * 0.88, sz.x, sz.y * 0.12), Color(0.8, 0.25, 0.05, 0.35))


func _paint_enlightened(sz: Vector2) -> void:
	var p := _painter
	_vgradient(sz, Color(0.98, 0.93, 0.78), Color(1.0, 0.97, 0.88), Color(0.92, 0.86, 0.72), 0.55)
	# The great sun with rays
	var sun := Vector2(sz.x * 0.5, sz.y * 0.28)
	for i in 24:
		var a := TAU * float(i) / 24.0
		p.draw_colored_polygon(PackedVector2Array([sun + Vector2.from_angle(a - 0.04) * 90.0, sun + Vector2.from_angle(a) * sz.x * 0.8, sun + Vector2.from_angle(a + 0.04) * 90.0]),
			Color(1.0, 0.9, 0.55, 0.12 if i % 2 == 0 else 0.06))
	p.draw_circle(sun, 150.0, Color(1.0, 0.92, 0.6, 0.35))
	p.draw_circle(sun, 95.0, Color(1.0, 0.95, 0.75))
	# Floating halos in the sky
	var rng := RandomNumberGenerator.new()
	rng.seed = 71
	for i in 6:
		var hc := Vector2(rng.randf() * sz.x, rng.randf_range(0.08, 0.4) * sz.y)
		p.draw_set_transform(hc, 0.0, Vector2(1.0, 0.3))
		p.draw_arc(Vector2.ZERO, rng.randf_range(20.0, 46.0), 0.0, TAU, 24, Color(1.0, 0.8, 0.3, 0.6), 5.0, true)
	p.draw_set_transform(Vector2.ZERO, 0.0, Vector2.ONE)
	# The white city: towers with golden domes (back row paler)
	for layer_i in 2:
		var base_y := sz.y * (0.78 if layer_i == 0 else 0.88)
		var white := Color(0.88, 0.85, 0.80) if layer_i == 0 else Color(0.97, 0.95, 0.91)
		var gold := Color(0.92, 0.72, 0.28, 0.7 if layer_i == 0 else 1.0)
		var x := -40.0 + float(layer_i) * 70.0
		while x < sz.x + 60.0:
			var w := rng.randf_range(60.0, 120.0)
			var h := rng.randf_range(160.0, 340.0) * (0.75 if layer_i == 1 else 1.0)
			p.draw_rect(Rect2(x, base_y - h, w, h), white)
			p.draw_rect(Rect2(x, base_y - h, w, h), Color(0.6, 0.55, 0.45, 0.6), false, 2.0)
			p.draw_circle(Vector2(x + w * 0.5, base_y - h), w * 0.5, gold)                 # Dome
			p.draw_line(Vector2(x + w * 0.5, base_y - h - w * 0.5), Vector2(x + w * 0.5, base_y - h - w * 0.5 - 30.0), gold, 4.0)
			for wy in int(h / 50.0):                                                          # Arched windows
				p.draw_rect(Rect2(x + w * 0.5 - 6.0, base_y - h + 30.0 + float(wy) * 50.0, 12.0, 22.0), Color(1.0, 0.85, 0.45, 0.6))
			x += w + rng.randf_range(20.0, 90.0)
	# Colonnade along the front
	var cy := sz.y * 0.9
	p.draw_rect(Rect2(0, cy - 140.0, sz.x, 16.0), Color(0.95, 0.92, 0.86))
	var col := 30.0
	while col < sz.x:
		p.draw_rect(Rect2(col - 10.0, cy - 124.0, 20.0, 124.0), Color(0.98, 0.96, 0.92))
		p.draw_rect(Rect2(col - 10.0, cy - 124.0, 20.0, 124.0), Color(0.7, 0.65, 0.55), false, 2.0)
		col += 90.0
	p.draw_rect(Rect2(0, cy, sz.x, sz.y - cy), Color(0.9, 0.86, 0.78))
	p.draw_rect(Rect2(0, cy, sz.x, 4), Color(0.95, 0.78, 0.35))


func _paint_sewer(sz: Vector2) -> void:
	var p := _painter
	_vgradient(sz, Color(0.02, 0.03, 0.02), Color(0.05, 0.08, 0.05), Color(0.08, 0.14, 0.08), 0.6)
	# Brick back wall
	var row := 0
	var y := 0.0
	while y < sz.y * 0.9:
		var x := -40.0 if row % 2 == 0 else -10.0
		while x < sz.x:
			p.draw_rect(Rect2(x + 2.0, y + 2.0, 56.0, 26.0), Color(0.09, 0.12, 0.09))
			x += 60.0
		y += 30.0
		row += 1
	# Big tunnel arches (dark openings)
	for ax in [0.2, 0.5, 0.8]:
		var c := Vector2(sz.x * ax, sz.y * 0.62)
		var r := sz.y * 0.26
		p.draw_circle(c, r + 14.0, Color(0.14, 0.18, 0.13))
		p.draw_circle(c, r, Color(0.01, 0.02, 0.01))
		p.draw_rect(Rect2(c.x - r - 14.0, c.y, (r + 14.0) * 2.0, sz.y), Color(0.14, 0.18, 0.13))
		p.draw_rect(Rect2(c.x - r, c.y, r * 2.0, sz.y), Color(0.01, 0.02, 0.01))
		for k in 9:                                                               # Arch bricks
			var a := PI + PI * float(k) / 8.0
			p.draw_line(c + Vector2.from_angle(a) * r, c + Vector2.from_angle(a) * (r + 14.0), Color(0.05, 0.07, 0.05), 3.0)
	# Pipes along the wall, pouring dirty water
	for i in 4:
		var py := sz.y * (0.12 + 0.1 * float(i % 2))
		var px := sz.x * (0.08 + 0.26 * float(i))
		p.draw_rect(Rect2(px - 60.0, py, 160.0, 26.0), Color(0.22, 0.26, 0.18))
		p.draw_rect(Rect2(px - 60.0, py, 160.0, 26.0), Color(0, 0, 0), false, 3.0)
		p.draw_rect(Rect2(px + 76.0, py - 4.0, 22.0, 34.0), Color(0.28, 0.32, 0.22))      # Pipe mouth
		p.draw_rect(Rect2(px + 80.0, py + 30.0, 14.0, sz.y * 0.9 - py - 30.0), Color(0.35, 0.5, 0.3, 0.35))   # Water fall
	# Slime channel at the bottom + fog
	p.draw_rect(Rect2(0, sz.y * 0.88, sz.x, sz.y * 0.12), Color(0.12, 0.22, 0.10))
	p.draw_rect(Rect2(0, sz.y * 0.88, sz.x, 4), Color(0.45, 0.75, 0.35, 0.6))
	for i in 6:
		p.draw_set_transform(Vector2(sz.x * (float(i) + 0.5) / 6.0, sz.y * 0.8), 0.0, Vector2(1.0, 0.25))
		p.draw_circle(Vector2.ZERO, 220.0, Color(0.3, 0.6, 0.25, 0.08))
	p.draw_set_transform(Vector2.ZERO, 0.0, Vector2.ONE)


func _paint_blasphemy(sz: Vector2) -> void:
	var p := _painter
	_vgradient(sz, Color(0.12, 0.02, 0.03), Color(0.45, 0.06, 0.04), Color(0.95, 0.35, 0.08), 0.6)
	var rng := RandomNumberGenerator.new()
	rng.seed = 91
	# Lava falls in the distance
	for i in 4:
		var fx := sz.x * (0.1 + 0.27 * float(i)) + rng.randf_range(-30.0, 30.0)
		p.draw_rect(Rect2(fx - 40.0, 0, 80.0, sz.y), Color(1.0, 0.4, 0.05, 0.08))
		p.draw_rect(Rect2(fx - 10.0, 0, 20.0, sz.y * 0.88), Color(1.0, 0.5, 0.1, 0.6))
	# Broken temple columns
	for i in 5:
		var cx := sz.x * (0.08 + 0.21 * float(i))
		var h := sz.y * rng.randf_range(0.35, 0.6)
		var top := sz.y * 0.88 - h
		p.draw_rect(Rect2(cx - 22.0, top, 44.0, h), Color(0.16, 0.07, 0.07))
		p.draw_colored_polygon(PackedVector2Array([Vector2(cx - 22.0, top), Vector2(cx - 6.0, top - 20.0), Vector2(cx + 10.0, top - 4.0), Vector2(cx + 22.0, top - 12.0), Vector2(cx + 22.0, top)]), Color(0.16, 0.07, 0.07))
		for k in 3:
			p.draw_line(Vector2(cx - 12.0 + float(k) * 12.0, top + 10.0), Vector2(cx - 12.0 + float(k) * 12.0, top + h), Color(0.1, 0.04, 0.04), 2.0)
	# A colossal serpent skeleton coiled through the sky (vertebrae + ribs)
	var spine := PackedVector2Array()
	for i in 40:
		var u := float(i) / 39.0
		spine.append(Vector2(sz.x * (0.05 + 0.9 * u), sz.y * (0.35 + 0.16 * sin(u * TAU * 1.3 + 0.8))))
	for i in spine.size():
		var v := spine[i]
		p.draw_circle(v, 9.0, Color(0.30, 0.22, 0.20))
		if i % 2 == 0 and i > 2 and i < spine.size() - 3:
			p.draw_arc(v + Vector2(0, 26), 26.0, PI * 1.15, PI * 1.85, 8, Color(0.30, 0.22, 0.20), 4.0)
	var skull := spine[0] + Vector2(-10, 0)
	p.draw_colored_polygon(PackedVector2Array([skull + Vector2(60, -30), skull + Vector2(-50, -10), skull + Vector2(-70, 10), skull + Vector2(60, 20)]), Color(0.30, 0.22, 0.20))
	p.draw_circle(skull + Vector2(20, -8), 10.0, Color(1.0, 0.5, 0.1, 0.7))
	# Ground silhouette + magma line
	_ridge(sz, sz.y * 0.9, 60.0, 70.0, Color(0.08, 0.03, 0.03), 92)
	p.draw_rect(Rect2(0, sz.y * 0.9, sz.x, 6), Color(1.0, 0.45, 0.1, 0.6))


# ============================================================
# EMBERS (the only animated part)
# ============================================================
func _paint_embers() -> void:
	var sz := _painter.size
	match theme:
		"elevator":
			# Girders + warning lamps rushing DOWN past the camera (the elevator rises)
			var gap := 260.0
			for i in int(sz.y / gap) + 2:
				var y := fmod(float(i) * gap + _t * 220.0, sz.y + gap) - gap
				_embers.draw_rect(Rect2(0, y, sz.x * 0.12, 18.0), Color(0.18, 0.17, 0.18))
				_embers.draw_rect(Rect2(sz.x * 0.88, y, sz.x * 0.12, 18.0), Color(0.18, 0.17, 0.18))
				var on := fmod(_t * 2.0 + float(i), 1.0) < 0.5
				_embers.draw_circle(Vector2(sz.x * 0.12, y + 9.0), 6.0, Color(1.0, 0.5, 0.1, 0.9 if on else 0.3))
				_embers.draw_circle(Vector2(sz.x * 0.88, y + 9.0), 6.0, Color(1.0, 0.5, 0.1, 0.3 if on else 0.9))
			for i in 16:                                            # Sparks falling away
				var e := _ember_data[i]
				var y2 := fmod(_t * (e.y * 4.0) + float(i) * 97.0, sz.y + 40.0) - 20.0
				_embers.draw_line(Vector2(e.x * sz.x, y2), Vector2(e.x * sz.x, y2 - 14.0), Color(1.0, 0.6, 0.25, 0.5), 2.0)
			return
		"enlightened":
			for i in _ember_data.size():                           # Rising motes of golden light
				var e := _ember_data[i]
				var y3 := sz.y - fmod(_t * e.y * 0.6 + float(i) * 97.0, sz.y + 40.0)
				var x3 := e.x * sz.x + sin(_t * 0.6 + float(i)) * 24.0
				_embers.draw_circle(Vector2(x3, y3), e.z + 1.0, Color(1.0, 0.9, 0.5, 0.35 + 0.3 * sin(_t * 2.0 + float(i))))
			return
		"sewer":
			for i in 20:                                            # Drips falling from the ceiling
				var e := _ember_data[i]
				var x4 := e.x * sz.x
				var k := fmod(_t * (0.25 + e.z * 0.08) + float(i) * 0.31, 1.0)
				_embers.draw_line(Vector2(x4, k * sz.y * 0.88), Vector2(x4, k * sz.y * 0.88 + 8.0), Color(0.55, 0.85, 0.5, 0.5), 2.0)
			return
	_paint_embers_default(sz)


func _paint_embers_default(sz: Vector2) -> void:
	if theme == "lab":
		# Bubbles rising inside the chemical chambers
		var chambers := _lab_chambers(sz)
		for i in 28:
			var ch := chambers[i % chambers.size()]
			var k := fmod(_t * (0.12 + 0.05 * float(i % 5)) + float(i) * 0.37, 1.0)
			var bx := ch.position.x + 14.0 + fmod(float(i) * 37.0, ch.size.x - 28.0) + sin(_t * 2.0 + float(i)) * 4.0
			var by := ch.end.y - 10.0 - k * (ch.size.y - 30.0)
			_embers.draw_arc(Vector2(bx, by), 2.0 + float(i % 3), 0.0, TAU, 10, Color(0.8, 1.0, 0.6, 0.7 * (1.0 - k * 0.5)), 1.5)
		return
	for i in _ember_data.size():
		var e := _ember_data[i]
		var y := sz.y - fmod(_t * e.y + float(i) * 97.0, sz.y + 40.0)
		var x := e.x * sz.x + sin(_t * 0.8 + float(i)) * 20.0
		var a := 0.5 + 0.5 * sin(_t * 3.0 + float(i))
		if theme == "hive":
			# Blinking robot eyes in the dark instead of embers
			if i % 3 == 0:
				var ey := sz.y * (0.15 + 0.6 * fmod(float(i) * 0.37, 1.0))
				var on := fmod(_t * 0.7 + float(i) * 0.13, 1.0) < 0.85
				if on:
					_embers.draw_circle(Vector2(e.x * sz.x, ey), 2.5, Color(0.3, 1.0, 0.95, 0.9))
					_embers.draw_circle(Vector2(e.x * sz.x + 9.0, ey), 2.5, Color(0.3, 1.0, 0.95, 0.9))
			continue
		var col := Color(0.8, 0.55, 1.0) if theme == "geode" else Color(1.0, 0.55, 0.15)   # Geode: floating crystal dust
		_embers.draw_circle(Vector2(x, y), e.z, Color(col.r, col.g, col.b, 0.4 + 0.4 * a))
