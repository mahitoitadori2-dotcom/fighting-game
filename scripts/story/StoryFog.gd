class_name StoryFog
extends Node2D
## Low drifting GREEN FOG in front of the floor (Sewers map). Purely visual: a few big
## translucent blobs that slide sideways and breathe. Origin = arena floor centre.

var half_width := 800.0
var _t := 0.0


func _ready() -> void:
	z_index = 5                       # In front of fighters' feet, under the HUDs
	z_as_relative = false


func _process(delta: float) -> void:
	_t += delta
	queue_redraw()


func _draw() -> void:
	for i in 14:
		var k := float(i) / 13.0
		var x := -half_width + fmod(k * half_width * 2.0 + _t * (18.0 + 9.0 * float(i % 3)) * (1.0 if i % 2 == 0 else -1.0) + half_width * 4.0, half_width * 2.0)
		var y := -18.0 - 26.0 * float(i % 3) + sin(_t * 0.7 + float(i)) * 6.0
		var r := 110.0 + 50.0 * float(i % 4)
		var a := 0.07 + 0.04 * sin(_t * 0.9 + float(i) * 1.7)
		draw_set_transform(Vector2(x, y), 0.0, Vector2(1.0, 0.28))
		draw_circle(Vector2.ZERO, r, Color(0.35, 0.75, 0.30, a))
	draw_set_transform(Vector2.ZERO, 0.0, Vector2.ONE)
