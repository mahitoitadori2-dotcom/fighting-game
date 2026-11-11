class_name FpsCounter
extends CanvasLayer
## Performance overlay (SETTINGS > Graphics > FPS Counter; Versus and Story Mode).
## Shows FPS, frame time, nodes, live particles (cap) and pooled objects.
## Updates 4x per second from a Timer: it costs nothing between updates.
##
## F4 = STRESS TEST: fires 50 harmless pooled enemy projectiles across the arena
## (target: 60 FPS with 1 player + 1 enemy + 50 projectiles).

const STRESS_COUNT := 50

var _label: Label


func _ready() -> void:
	layer = 20
	process_mode = Node.PROCESS_MODE_ALWAYS
	_label = Label.new()
	_label.position = Vector2(12, 132)                 # Under the P1 HUD + cooldown list
	_label.add_theme_font_size_override("font_size", 15)
	_label.add_theme_constant_override("outline_size", 6)
	_label.add_theme_color_override("font_outline_color", Color(0, 0, 0))
	_label.mouse_filter = Control.MOUSE_FILTER_IGNORE
	add_child(_label)
	var timer := Timer.new()
	timer.wait_time = 0.25
	timer.autostart = true
	timer.timeout.connect(_update)
	add_child(timer)
	_update()


func _update() -> void:
	var fps := Engine.get_frames_per_second()
	var ms := Performance.get_monitor(Performance.TIME_PROCESS) * 1000.0
	var col := Color(0.4, 1.0, 0.45) if fps >= 58 else (Color(1.0, 0.85, 0.3) if fps >= 45 else Color(1.0, 0.35, 0.3))
	_label.add_theme_color_override("font_color", col)
	_label.text = "FPS %d  (%.1f ms)\nnodes %d   particles %d / %d   pooled %d  (reused %d / new %d)\nF4 = +%d test projectiles" % [
		fps, ms, int(Performance.get_monitor(Performance.OBJECT_NODE_COUNT)),
		OptimizationManager.live_particles, OptimizationManager.MAX_PARTICLES,
		OptimizationManager.pooled_count(), OptimizationManager.reused, OptimizationManager.created, STRESS_COUNT]


func _unhandled_input(event: InputEvent) -> void:
	if event is InputEventKey and event.pressed and not event.echo and event.physical_keycode == KEY_F4:
		_stress_test()


func _stress_test() -> void:
	var scene := get_tree().current_scene
	var cam := get_viewport().get_camera_2d()
	var center := cam.get_screen_center_position() if cam != null else Vector2(576, 400)
	var looks := ["croak", "wind", "laser", "glitter", "frost"]
	for i in STRESS_COUNT:
		var p := OptimizationManager.take(EnemyProjectile) as EnemyProjectile
		p.harmless = true
		p.look = looks[i % looks.size()]
		p.dir = 1.0 if i % 2 == 0 else -1.0
		p.speed = randf_range(220.0, 420.0)
		p.lifetime = 3.0
		scene.add_child(p)
		p.global_position = center + Vector2(-p.dir * 520.0, randf_range(-260.0, 120.0))
