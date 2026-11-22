class_name ReplayPlayer
extends Node
## Plays a replay on puppet fighters (spawned by ArenaManager when Replay.pending is set).
## Controls:  Space / A pause   1 / 2 / 3 speed 0.5x / 1x / 2x   Left / Right skip 5 s
##            R restart   Esc / B back to where you came from

var data: Dictionary
var puppets: Array[Fighter] = []
var frame := 0
var speed := 1.0
var paused := false
var return_scene := ""
var _acc := 0.0
var _ui: CanvasLayer
var _lbl: Label
var _bar: ProgressBar


func setup(p_data: Dictionary, p_puppets: Array[Fighter]) -> void:
	data = p_data
	puppets = p_puppets
	for p in puppets:
		Replay.make_puppet(p)
	_seek(0)


func _ready() -> void:
	process_mode = Node.PROCESS_MODE_ALWAYS
	CombatManager.fight_active = false
	_ui = CanvasLayer.new()
	_ui.layer = 15
	add_child(_ui)
	var box := VBoxContainer.new()
	box.anchor_left = 0.5
	box.anchor_right = 0.5
	box.anchor_top = 1.0
	box.anchor_bottom = 1.0
	box.offset_left = -330
	box.offset_right = 330
	box.offset_top = -92
	box.offset_bottom = -12
	_ui.add_child(box)
	_lbl = UiStyle.label("", 18, UiStyle.TEXT, 6)
	box.add_child(_lbl)
	_bar = ProgressBar.new()
	_bar.show_percentage = false
	_bar.custom_minimum_size = Vector2(660, 10)
	_bar.add_theme_stylebox_override("background", UiStyle.box(Color(0, 0, 0, 0.6), UiStyle.INK, 2, 4, 0.0))
	_bar.add_theme_stylebox_override("fill", UiStyle.box(UiStyle.ACCENT_BLUE, UiStyle.INK, 0, 4, 0.0))
	box.add_child(_bar)
	var tag := UiStyle.label("REPLAY", 30, Color(1.0, 0.35, 0.3), 8)
	tag.anchor_left = 0.5
	tag.anchor_right = 0.5
	tag.offset_left = -120
	tag.offset_right = 120
	tag.offset_top = 70
	_ui.add_child(tag)


func total() -> int:
	return (data.get("frames", []) as Array).size()


func _physics_process(delta: float) -> void:
	if puppets.is_empty():
		return
	if not paused and frame < total():
		_acc += delta * speed
		var step := 1.0 / float(data.get("hz", Replay.HZ))
		while _acc >= step and frame < total():
			_acc -= step
			_apply_frame(frame)
			frame += 1
	_bar.max_value = maxi(total(), 1)
	_bar.value = frame
	_lbl.text = "%s / %s   %s  x%s" % [
		StoryManager.time_text(frame / Replay.HZ), StoryManager.time_text(total() / Replay.HZ),
		"PAUSED" if paused else ("END" if frame >= total() else "PLAYING"), str(speed)]


func _apply_frame(i: int) -> void:
	var fr: Dictionary = data["frames"][i]
	for k in fr:
		var idx := int(k)
		if idx >= 0 and idx < puppets.size() and is_instance_valid(puppets[idx]):
			Replay.apply(puppets[idx], fr[k])


## Rebuild the state at frame `to` (deltas from the start).
func _seek(to: int) -> void:
	to = clampi(to, 0, total())
	for i in to:
		_apply_frame(i)
	if to == 0 and total() > 0:
		_apply_frame(0)
	frame = to


func _unhandled_input(event: InputEvent) -> void:
	if event.is_action_pressed("ui_cancel") or event.is_action_pressed("pause_menu"):
		get_viewport().set_input_as_handled()
		Replay.pending = {}
		get_tree().change_scene_to_file(return_scene if return_scene != "" else CharacterRoster.MAIN_MENU)
		return
	var k := event as InputEventKey
	var pressed_accept := event.is_action_pressed("ui_accept") or (k != null and k.pressed and k.physical_keycode == KEY_SPACE)
	if pressed_accept:
		paused = not paused
		if frame >= total():
			_seek(0)
			paused = false
	elif k != null and k.pressed and not k.echo:
		match k.physical_keycode:
			KEY_1:
				speed = 0.5
			KEY_2:
				speed = 1.0
			KEY_3:
				speed = 2.0
			KEY_LEFT:
				_seek(maxi(frame - int(5 * Replay.HZ), 0))
			KEY_RIGHT:
				_seek(mini(frame + int(5 * Replay.HZ), total()))
			KEY_R:
				_seek(0)
				paused = false
			_:
				return
	elif event.is_action_pressed("ui_left"):
		_seek(maxi(frame - int(5 * Replay.HZ), 0))
	elif event.is_action_pressed("ui_right"):
		_seek(mini(frame + int(5 * Replay.HZ), total()))
	else:
		return
	get_viewport().set_input_as_handled()
