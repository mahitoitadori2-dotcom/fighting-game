class_name CaveWall
extends StaticBody2D
## A tall basalt cliff that closes the Story arena on one side (no falling into the void).
## Kharlemings climb it. Origin = bottom of the wall's INNER face, at floor level.
## side = -1: wall on the LEFT (rock extends left), 1: wall on the RIGHT.

@export var side := -1
@export var height := 900.0
@export var thickness := 900.0                    # Thick enough to fill the screen edge at any zoom
## "lava" = basalt with lava veins, "crystal" = geode wall with amethyst clusters,
## "metal" = rusted scrap plates with cyan light seams (Kharleming hive).
@export var style := "lava":
	set(v):
		style = v
		queue_redraw()

var _poly := PackedVector2Array()
var _veins: Array[PackedVector2Array] = []


func _ready() -> void:
	z_index = -1                                  # Behind fighters (climbing Kharlemings stay visible)
	collision_layer = CombatManager.WORLD_LAYER
	collision_mask = 0
	var shape := RectangleShape2D.new()
	shape.size = Vector2(thickness, height + 200.0)
	var col := CollisionShape2D.new()
	col.shape = shape
	col.position = Vector2(side * thickness * 0.5, -height * 0.5 + 100.0)
	add_child(col)
	_build()


func inner_x() -> float:
	return global_position.x


func _build() -> void:
	var rng := RandomNumberGenerator.new()
	rng.seed = 40 + side
	# Reaches far below the floor so a narrower map hides the ground's underside behind it
	_poly = PackedVector2Array([Vector2(side * thickness, 700)])
	var y := 700.0
	while y > -height:
		_poly.append(Vector2(-side * rng.randf_range(0.0, 14.0), y))     # Jagged inner face
		y -= rng.randf_range(40.0, 90.0)
	_poly.append(Vector2(0, -height))
	_poly.append(Vector2(side * thickness, -height))
	_veins.clear()
	for i in 6:
		var p := Vector2(side * rng.randf_range(30.0, thickness - 30.0), -rng.randf_range(40.0, height - 60.0))
		var line := PackedVector2Array([p])
		for j in 4:
			p += Vector2(rng.randf_range(-20.0, 20.0), rng.randf_range(16.0, 34.0))
			line.append(p)
		_veins.append(line)
	queue_redraw()


func _draw() -> void:
	var near := Color(0.16, 0.11, 0.10)
	var far := Color(0.07, 0.05, 0.05)
	if style == "crystal":
		near = Color(0.22, 0.17, 0.28)
		far = Color(0.09, 0.06, 0.12)
	elif style == "metal":
		near = Color(0.30, 0.25, 0.22)
		far = Color(0.12, 0.11, 0.11)
	elif style == "lab":
		near = Color(0.24, 0.28, 0.26)
		far = Color(0.10, 0.12, 0.11)
	var cols := PackedColorArray()
	for p in _poly:
		cols.append(near.lerp(far, clampf(absf(p.x) / thickness, 0.0, 1.0)))
	draw_polygon(_poly, cols)
	match style:
		"crystal":
			_draw_crystals()
		"metal":
			_draw_plates()
		"lab":
			_draw_lab()
		_:
			for v in _veins:                        # Lava veins
				draw_polyline(v, Color(1.0, 0.45, 0.1, 0.25), 7.0, true)
				draw_polyline(v, Color(1.0, 0.5, 0.12), 2.5, true)
	var edge := PackedVector2Array()
	for i in range(1, _poly.size() - 1):
		edge.append(_poly[i])
	draw_polyline(edge, Color(0, 0, 0), 6.0, true)
	var rim := {"lava": Color(0.35, 0.22, 0.18), "crystal": Color(0.6, 0.4, 0.85), "metal": Color(0.3, 0.9, 0.9), "lab": Color(0.45, 1.0, 0.2)}
	draw_polyline(edge, rim.get(style, Color(0.35, 0.22, 0.18)), 2.0, true)


## Amethyst clusters growing out of the wall (Geode Cavern).
func _draw_crystals() -> void:
	var rng := RandomNumberGenerator.new()
	rng.seed = 77 + side
	for i in 9:
		var base := Vector2(side * rng.randf_range(8.0, 70.0), -rng.randf_range(30.0, height - 80.0))
		draw_circle(base, 34.0, Color(0.7, 0.4, 1.0, 0.10))
		for k in 3:
			var ang := -PI * 0.5 + side * rng.randf_range(0.3, 1.3)
			var len := rng.randf_range(22.0, 48.0)
			var tip := base + Vector2.from_angle(ang) * len
			var n := Vector2.from_angle(ang).orthogonal() * rng.randf_range(5.0, 9.0)
			var shard := PackedVector2Array([base + n, base + n + (tip - base) * 0.8, tip, base - n + (tip - base) * 0.8, base - n])
			draw_colored_polygon(shard, Color(0.66, 0.38, 0.95))
			draw_colored_polygon(PackedVector2Array([base + n * 0.2, base + n * 0.2 + (tip - base) * 0.8, tip, base]), Color(0.9, 0.78, 1.0))
			var closed := shard.duplicate()
			closed.append(shard[0])
			draw_polyline(closed, Color(0, 0, 0), 2.5, true)


## Lab wall: tiled panels + a tall glass tube of bubbling chemicals with valves.
func _draw_lab() -> void:
	var y := 100.0
	while y > -height:                                  # Wall tiles
		draw_line(Vector2(0, y), Vector2(side * thickness, y), Color(0.14, 0.17, 0.16), 2.0)
		y -= 60.0
	var tx := side * 46.0                               # Chemical tube along the inner face
	var tube := Rect2(minf(tx, tx + side * 34.0), -height + 60.0, 34.0, height + 30.0)
	draw_rect(tube.grow(4.0), Color(0, 0, 0))
	draw_rect(tube, Color(0.25, 0.65, 0.12, 0.85))
	draw_rect(Rect2(tube.position.x + 5.0, tube.position.y, 6.0, tube.size.y), Color(1, 1, 1, 0.3))   # Glass glare
	for k in 6:                                         # Brass bands + valves
		var by := -height + 120.0 + float(k) * (height - 120.0) / 6.0
		draw_rect(Rect2(tube.position.x - 6.0, by, tube.size.x + 12.0, 10.0), Color(0.55, 0.42, 0.18))
		if k % 2 == 0:
			draw_circle(Vector2(tube.get_center().x + side * 34.0, by + 5.0), 9.0, Color(0.5, 0.12, 0.10))
			draw_line(Vector2(tube.get_center().x, by + 5.0), Vector2(tube.get_center().x + side * 34.0, by + 5.0), Color(0.3, 0.32, 0.3), 6.0)


## Rusted scrap plates, rivets, cyan light seams and hanging cables (Kharleming hive).
func _draw_plates() -> void:
	var rng := RandomNumberGenerator.new()
	rng.seed = 91 + side
	var y := 100.0
	while y > -height:
		var h := rng.randf_range(70.0, 130.0)
		var x0 := side * rng.randf_range(4.0, 20.0)
		var w := side * rng.randf_range(120.0, thickness - 10.0)
		var r := Rect2(minf(x0, x0 + w), y - h, absf(w), h - 6.0)
		draw_rect(r, Color(0.36, 0.30, 0.26) if int(y) % 3 != 0 else Color(0.42, 0.24, 0.14))
		draw_rect(r, Color(0, 0, 0), false, 2.5)
		for c in [r.position + Vector2(6, 6), Vector2(r.end.x - 6, r.position.y + 6), Vector2(r.position.x + 6, r.end.y - 6), r.end - Vector2(6, 6)]:
			draw_circle(c, 2.2, Color(0.15, 0.13, 0.12))
		draw_line(Vector2(r.position.x, r.end.y + 3.0), Vector2(r.end.x, r.end.y + 3.0), Color(0.3, 0.95, 0.95, 0.6), 2.0)   # Light seam
		y -= h
	for k in 3:                                         # Hanging cables
		var cx := side * (30.0 + float(k) * 50.0)
		var pts := PackedVector2Array()
		for j in 8:
			pts.append(Vector2(cx + sin(float(j) * 0.9 + float(k)) * 8.0, -height + 40.0 + float(j) * 45.0))
		draw_polyline(pts, Color(0, 0, 0), 5.0, true)
		draw_polyline(pts, Color(0.2, 0.2, 0.22), 2.5, true)
