class_name DragScroll
extends Node
## FINGER SCROLLING for a ScrollContainer (2026-11-21, user: "no scrolling in the finish screen" on
## phones). Godot's own touch-scroll only works where the finger lands on the ScrollContainer itself
## - on the results screen that is almost always a button or the stats table, which swallow it.
## This listens to EVERY finger drag on the screen and scrolls the target; a swipe that started on a
## button does not press it.

var target: ScrollContainer
var _moved := 0.0


static func attach(sc: ScrollContainer) -> DragScroll:
	var d := DragScroll.new()
	d.target = sc
	sc.add_child(d)
	return d


func _ready() -> void:
	process_mode = Node.PROCESS_MODE_ALWAYS


func _input(event: InputEvent) -> void:
	if target == null or not target.is_visible_in_tree():
		return
	if event is InputEventScreenTouch:
		var st := event as InputEventScreenTouch
		if st.pressed:
			_moved = 0.0
		elif _moved > 12.0:
			get_viewport().set_input_as_handled()            # It was a swipe, not a tap
	elif event is InputEventScreenDrag:
		var dy := (event as InputEventScreenDrag).relative.y
		_moved += absf(dy)
		target.scroll_vertical = int(target.scroll_vertical - dy)
