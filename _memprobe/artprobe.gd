extends Control
## TEMPORARY (delete after use): Architect vs Anti Architect side by side.

var _t := 0.0


func _process(delta: float) -> void:
	_t += delta
	queue_redraw()


func _draw() -> void:
	draw_rect(Rect2(Vector2.ZERO, size), Color(0.35, 0.45, 0.6))
	draw_set_transform(Vector2(420, 620), 0.0, Vector2(4, 4))
	ArchitectArt.draw_portrait(self, _t)
	draw_set_transform(Vector2(860, 620), 0.0, Vector2(4, 4))
	AntiArchitectArt.draw_portrait(self, _t)
	draw_set_transform(Vector2.ZERO, 0.0, Vector2.ONE)
