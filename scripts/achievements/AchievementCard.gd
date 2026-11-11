class_name AchievementCard
extends Control
## One achievement's artwork as a Control (AchievementArt). animate = redraw every frame
## (the toast, the hovered card); otherwise it is drawn once (a grid of 100+ cards stays cheap).

var def: Dictionary = {}
var locked := false
var animate := false

var _t := 0.0


func _ready() -> void:
	clip_contents = true
	set_process(animate)


func set_animate(on: bool) -> void:
	animate = on
	set_process(on)
	if not on:
		_t = 0.0
	queue_redraw()


func _process(delta: float) -> void:
	_t += delta
	queue_redraw()


func _draw() -> void:
	if def.is_empty():
		return
	AchievementArt.draw(self, def, Rect2(Vector2.ZERO, size).grow(-3.0), _t, locked)
