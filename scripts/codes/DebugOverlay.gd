class_name DebugOverlay
extends CanvasLayer
## SECRET CODE "B0gT3ster" (PC: WDWDSASA on the Main Menu): the important numbers for an
## efficiency test, in the TOP-LEFT corner on EVERY screen (it lives on the root, not in a scene):
##   FPS (+ the lowest of the last second), frame ms, game-code ms (process), physics ms,
##   draw calls, nodes, objects, memory (static + video).
## Off with the same code again. Updated 4x a second (it must not cost frames itself).

var _lbl: Label
var _acc := 0.0
var _worst := 0.0
var _frames := 0


static func set_shown(tree: SceneTree, on: bool) -> void:
	var old := tree.root.get_node_or_null("DebugOverlay")
	if on and old == null:
		var d := DebugOverlay.new()
		d.name = "DebugOverlay"
		tree.root.add_child.call_deferred(d)
	elif not on and old != null:
		old.queue_free()


func _ready() -> void:
	layer = 190
	process_mode = Node.PROCESS_MODE_ALWAYS
	var bg := PanelContainer.new()
	var sb := StyleBoxFlat.new()
	sb.bg_color = Color(0, 0, 0, 0.62)
	sb.set_corner_radius_all(6)
	sb.content_margin_left = 8
	sb.content_margin_right = 8
	sb.content_margin_top = 4
	sb.content_margin_bottom = 4
	bg.add_theme_stylebox_override("panel", sb)
	bg.position = Vector2(6, 6)
	bg.mouse_filter = Control.MOUSE_FILTER_IGNORE
	add_child(bg)
	_lbl = Label.new()
	_lbl.add_theme_font_size_override("font_size", 14)
	_lbl.add_theme_color_override("font_color", Color(0.6, 1.0, 0.6))
	_lbl.mouse_filter = Control.MOUSE_FILTER_IGNORE
	bg.add_child(_lbl)


func _process(delta: float) -> void:
	_acc += delta
	_frames += 1
	_worst = maxf(_worst, delta)
	if _acc < 0.25:
		return
	var fps := float(_frames) / _acc
	var low := 1.0 / maxf(_worst, 0.0001)
	_acc = 0.0
	_frames = 0
	_worst = 0.0
	var mem := OS.get_static_memory_usage() / 1048576.0
	var vmem := Performance.get_monitor(Performance.RENDER_VIDEO_MEM_USED) / 1048576.0
	_lbl.text = "BUG TESTER\nFPS %d  (low %d)   %.1f ms\nprocess %.1f ms   physics %.1f ms\ndraws %d   nodes %d   objects %d\nmemory %.0f MB   video %.0f MB" % [
		roundi(fps), roundi(low), 1000.0 / maxf(fps, 0.01),
		Performance.get_monitor(Performance.TIME_PROCESS) * 1000.0, Performance.get_monitor(Performance.TIME_PHYSICS_PROCESS) * 1000.0,
		int(Performance.get_monitor(Performance.RENDER_TOTAL_DRAW_CALLS_IN_FRAME)), int(Performance.get_monitor(Performance.OBJECT_NODE_COUNT)),
		int(Performance.get_monitor(Performance.OBJECT_COUNT)), mem, vmem]
