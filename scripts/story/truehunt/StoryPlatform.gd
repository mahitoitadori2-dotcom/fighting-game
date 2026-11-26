class_name StoryPlatform
extends StaticBody2D
## A ROCK LEDGE in a Story arena (The True Hunt maps, StoryMaps "platforms"). ONE-WAY: you jump up
## through it from below and stand on it; it never blocks you from the side. Built by
## StoryManager._apply_map, removed again when the map changes.

var width := 200.0
var tint := Color(0.30, 0.16, 0.12)
var _seed := 0


static func build(host: Node, pos: Vector2, w: float, col: Color) -> StoryPlatform:
	var p := StoryPlatform.new()
	p.width = w
	p.tint = col
	p.position = pos
	host.add_child(p)
	return p


func _ready() -> void:
	add_to_group("story_platform")
	collision_layer = CombatManager.WORLD_LAYER
	collision_mask = 0
	z_index = -1
	_seed = int(absf(position.x) * 7.0 + width)
	var shape := RectangleShape2D.new()
	shape.size = Vector2(width, 18.0)
	var cs := CollisionShape2D.new()
	cs.shape = shape
	cs.position = Vector2(0, 9.0)
	cs.one_way_collision = true
	add_child(cs)


func _draw() -> void:
	var rng := RandomNumberGenerator.new()
	rng.seed = _seed
	var hw := width * 0.5
	# The slab: flat top, a ragged underside that tapers to a point (a broken-off rock shelf)
	var pts := PackedVector2Array([Vector2(-hw, 0), Vector2(hw, 0)])
	var steps := 7
	for i in steps + 1:
		var u := 1.0 - float(i) / float(steps)
		var x := lerpf(-hw, hw, u)
		var depth := 16.0 + 30.0 * sin(u * PI) + rng.randf_range(-5.0, 5.0)
		pts.append(Vector2(x * (0.92 if i > 0 and i < steps else 1.0), depth))
	draw_colored_polygon(pts, tint)
	FighterArt.outline(self, pts, 3.0, Color(0.02, 0.01, 0.01))
	draw_line(Vector2(-hw + 3, 2), Vector2(hw - 3, 2), tint.lightened(0.35), 3.0)       # Lit top edge
	for i in 4:                                                                          # Cracks
		var x := rng.randf_range(-hw * 0.7, hw * 0.7)
		draw_line(Vector2(x, 5), Vector2(x + rng.randf_range(-8, 8), 14.0 + rng.randf_range(0, 10)), tint.darkened(0.5), 2.0)
