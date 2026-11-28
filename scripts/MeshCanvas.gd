class_name MeshCanvas
extends RefCounted
## RECORDS 2D drawing into ONE vertex-coloured mesh: draw code written for a CanvasItem
## (draw_rect / draw_colored_polygon / draw_polygon / draw_polyline / draw_line / draw_circle)
## runs against this instead, and the result is drawn with a single draw_mesh() = ONE draw call.
## Godot replays every recorded canvas command each frame and can't batch rects with polygons
## with lines, so a static backdrop of hundreds of shapes cost hundreds of draw calls per frame on
## phones. Same look, one draw call.
# KEEP A REFERENCE to the built mesh (a member var) until the next redraw: draw_mesh only stores the
# mesh's RID, and a mesh freed at the end of _draw renders nothing ("Parameter mesh is null").

var verts := PackedVector2Array()
var cols := PackedColorArray()
var view_size := Vector2(1280, 720)        # Answer for get_viewport_rect() during recording
var xf := Transform2D.IDENTITY               # draw_set_transform (applied to every point)


func get_viewport_rect() -> Rect2:
	return Rect2(Vector2.ZERO, view_size)


func _tri(a: Vector2, b: Vector2, c: Vector2, ca: Color, cb: Color, cc: Color) -> void:
	verts.append(xf * a)
	verts.append(xf * b)
	verts.append(xf * c)
	cols.append(ca)
	cols.append(cb)
	cols.append(cc)


func _quad(a: Vector2, b: Vector2, c: Vector2, d: Vector2, col: Color) -> void:
	_tri(a, b, c, col, col, col)
	_tri(a, c, d, col, col, col)


func draw_rect(r: Rect2, col: Color, filled: bool = true, width: float = -1.0, _aa: bool = false) -> void:
	if filled:
		_quad(r.position, Vector2(r.end.x, r.position.y), r.end, Vector2(r.position.x, r.end.y), col)
		return
	var w := maxf(width, 1.0)
	var p := r.position
	var e := r.end
	var hw := w * 0.5
	_quad(Vector2(p.x - hw, p.y - hw), Vector2(e.x + hw, p.y - hw), Vector2(e.x + hw, p.y + hw), Vector2(p.x - hw, p.y + hw), col)
	_quad(Vector2(p.x - hw, e.y - hw), Vector2(e.x + hw, e.y - hw), Vector2(e.x + hw, e.y + hw), Vector2(p.x - hw, e.y + hw), col)
	_quad(Vector2(p.x - hw, p.y + hw), Vector2(p.x + hw, p.y + hw), Vector2(p.x + hw, e.y - hw), Vector2(p.x - hw, e.y - hw), col)
	_quad(Vector2(e.x - hw, p.y + hw), Vector2(e.x + hw, p.y + hw), Vector2(e.x + hw, e.y - hw), Vector2(e.x - hw, e.y - hw), col)


func draw_colored_polygon(pts: PackedVector2Array, col: Color, _uvs: PackedVector2Array = PackedVector2Array(), _tex: Texture2D = null) -> void:
	var idx := Geometry2D.triangulate_polygon(pts)
	for i in range(0, idx.size(), 3):
		_tri(pts[idx[i]], pts[idx[i + 1]], pts[idx[i + 2]], col, col, col)


func draw_polygon(pts: PackedVector2Array, colors: PackedColorArray, _uvs: PackedVector2Array = PackedVector2Array(), _tex: Texture2D = null) -> void:
	var idx := Geometry2D.triangulate_polygon(pts)
	for i in range(0, idx.size(), 3):
		var a := idx[i]
		var b := idx[i + 1]
		var c := idx[i + 2]
		var ca := colors[a] if colors.size() > a else colors[0]
		var cb := colors[b] if colors.size() > b else colors[0]
		var cc := colors[c] if colors.size() > c else colors[0]
		_tri(pts[a], pts[b], pts[c], ca, cb, cc)


func draw_line(a: Vector2, b: Vector2, col: Color, width: float = -1.0, _aa: bool = false) -> void:
	var w := maxf(width, 1.0) * 0.5
	var d := b - a
	if d.length() < 0.001:
		return
	var n := d.normalized().orthogonal() * w
	var ext := d.normalized() * w * 0.5                 # Slight overlap so joints close
	_quad(a + n - ext, b + n + ext, b - n + ext, a - n - ext, col)


func draw_polyline(pts: PackedVector2Array, col: Color, width: float = -1.0, _aa: bool = false) -> void:
	for i in range(1, pts.size()):
		draw_line(pts[i - 1], pts[i], col, width)


func draw_circle(p: Vector2, r: float, col: Color, filled: bool = true, width: float = -1.0, _aa: bool = false) -> void:
	var seg := clampi(int(r * 0.6), 12, 48)
	if not filled:
		for i in seg:
			var a0 := TAU * float(i) / float(seg)
			var a1 := TAU * float(i + 1) / float(seg)
			draw_line(p + Vector2(cos(a0), sin(a0)) * r, p + Vector2(cos(a1), sin(a1)) * r, col, width)
		return
	for i in seg:
		var a0 := TAU * float(i) / float(seg)
		var a1 := TAU * float(i + 1) / float(seg)
		_tri(p, p + Vector2(cos(a0), sin(a0)) * r, p + Vector2(cos(a1), sin(a1)) * r, col, col, col)


## Like CanvasItem.draw_set_transform: everything drawn after it is moved / rotated / scaled.
func draw_set_transform(pos: Vector2, rot: float = 0.0, scl: Vector2 = Vector2.ONE) -> void:
	xf = Transform2D(rot, scl, 0.0, pos)


func draw_set_transform_matrix(m: Transform2D) -> void:
	xf = m


## Like CanvasItem.draw_arc (an outline along part of a circle).
func draw_arc(center: Vector2, radius: float, start: float, end: float, point_count: int, col: Color, width: float = -1.0, _aa: bool = false) -> void:
	var n := maxi(point_count, 2)
	var pts := PackedVector2Array()
	for i in n:
		var a := lerpf(start, end, float(i) / float(n - 1))
		pts.append(center + Vector2(cos(a), sin(a)) * radius)
	draw_polyline(pts, col, width)


## The recorded drawing as one mesh (null if nothing was drawn).
func build() -> ArrayMesh:
	if verts.is_empty():
		return null
	var arrays := []
	arrays.resize(Mesh.ARRAY_MAX)
	arrays[Mesh.ARRAY_VERTEX] = verts
	arrays[Mesh.ARRAY_COLOR] = cols
	var m := ArrayMesh.new()
	m.add_surface_from_arrays(Mesh.PRIMITIVE_TRIANGLES, arrays)
	return m
