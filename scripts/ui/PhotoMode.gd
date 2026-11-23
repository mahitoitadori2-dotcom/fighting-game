class_name PhotoMode
extends CanvasLayer
## PHOTO MODE (2026-11-23, picked by the user): freeze any fight or replay, then move the camera, zoom,
## hide the HUD and save a picture.
##   open:  F9 in a fight / replay, or PHOTO in the pause menu (phones too)
##   move:  drag (finger / mouse), WASD / arrows      zoom: wheel, pinch, + / -, Q / E, the buttons
##   HUD:   hides every other layer of the screen     SAVE: PNG in user://photos (PC) / a download (web)
##   EXIT / Esc: everything goes back as it was and the fight carries on

const ZOOM_MIN := 0.25
const ZOOM_MAX := 3.0
const PAN_SPEED := 900.0

var _cam: Camera2D
var _cam_pos := Vector2.ZERO
var _cam_zoom := Vector2.ONE
var _cam_offset := Vector2.ZERO
var _was_paused := false
var _bar: HBoxContainer
var _hud_hidden := false
var _hidden_layers: Array = []
var _drag := false
var _touches := {}                                     # index -> position (pinch)
var _pinch_d := 0.0
var _toast: Label
var _toast_t := 0.0


static func open(tree: SceneTree) -> void:
	if tree.root.get_node_or_null("PhotoMode") != null or tree.root.get_viewport().get_camera_2d() == null:
		return
	var p := PhotoMode.new()
	p.name = "PhotoMode"
	tree.root.add_child(p)


func _ready() -> void:
	layer = 200
	process_mode = Node.PROCESS_MODE_ALWAYS
	var tree := get_tree()
	_was_paused = tree.paused
	tree.paused = true
	_cam = get_viewport().get_camera_2d()
	_cam_pos = _cam.global_position
	_cam_zoom = _cam.zoom
	_cam_offset = _cam.offset
	_cam.offset = Vector2.ZERO
	var catcher := Control.new()                        # Drags anywhere on the picture
	catcher.set_anchors_and_offsets_preset(Control.PRESET_FULL_RECT)
	catcher.mouse_filter = Control.MOUSE_FILTER_STOP
	catcher.gui_input.connect(_on_input)
	add_child(catcher)
	_bar = HBoxContainer.new()
	_bar.set_anchors_and_offsets_preset(Control.PRESET_CENTER_BOTTOM)
	_bar.offset_top = -86.0
	_bar.offset_bottom = -20.0
	_bar.grow_horizontal = Control.GROW_DIRECTION_BOTH
	_bar.alignment = BoxContainer.ALIGNMENT_CENTER
	_bar.add_theme_constant_override("separation", 12)
	add_child(_bar)
	for spec in [["-", _zoom_by.bind(1.0 / 1.25)], ["+", _zoom_by.bind(1.25)], ["HUD", _toggle_hud], ["SAVE", _save], ["EXIT", close]]:
		var b := UiStyle.make_button(String(spec[0]), Vector2(110 if String(spec[0]).length() > 1 else 70, 58), 22)
		b.pressed.connect(spec[1])
		_bar.add_child(b)
	_toast = UiStyle.label("", 22, Color(1.0, 0.95, 0.7), 6)
	_toast.set_anchors_and_offsets_preset(Control.PRESET_CENTER_TOP)
	_toast.offset_top = 24.0
	_toast.grow_horizontal = Control.GROW_DIRECTION_BOTH
	add_child(_toast)
	_show("PHOTO MODE")


func close() -> void:
	if _hud_hidden:
		_toggle_hud()
	if is_instance_valid(_cam):
		_cam.global_position = _cam_pos
		_cam.zoom = _cam_zoom
		_cam.offset = _cam_offset
	get_tree().paused = _was_paused
	queue_free()


func _show(text: String) -> void:
	_toast.text = text
	_toast_t = 2.0


func _process(delta: float) -> void:
	_toast_t = maxf(_toast_t - delta, 0.0)
	_toast.modulate.a = clampf(_toast_t, 0.0, 1.0)
	var mv := Vector2(Input.get_axis("ui_left", "ui_right"), Input.get_axis("ui_up", "ui_down"))
	if Input.is_physical_key_pressed(KEY_A):
		mv.x -= 1.0
	if Input.is_physical_key_pressed(KEY_D):
		mv.x += 1.0
	if Input.is_physical_key_pressed(KEY_W):
		mv.y -= 1.0
	if Input.is_physical_key_pressed(KEY_S):
		mv.y += 1.0
	if mv != Vector2.ZERO and is_instance_valid(_cam):
		_cam.global_position += mv.limit_length(1.0) * PAN_SPEED * delta / _cam.zoom.x


func _unhandled_input(event: InputEvent) -> void:
	get_viewport().set_input_as_handled()
	if event.is_action_pressed("ui_cancel") or (event is InputEventKey and (event as InputEventKey).pressed and (event as InputEventKey).physical_keycode == KEY_F9):
		close()
		return
	if event is InputEventKey and (event as InputEventKey).pressed:
		match (event as InputEventKey).physical_keycode:
			KEY_EQUAL, KEY_KP_ADD, KEY_E:
				_zoom_by(1.15)
			KEY_MINUS, KEY_KP_SUBTRACT, KEY_Q:
				_zoom_by(1.0 / 1.15)
			KEY_H:
				_toggle_hud()
			KEY_ENTER, KEY_SPACE:
				_save()


func _on_input(event: InputEvent) -> void:
	if not is_instance_valid(_cam):
		return
	if event is InputEventMouseButton:
		var mb := event as InputEventMouseButton
		if mb.button_index == MOUSE_BUTTON_WHEEL_UP and mb.pressed:
			_zoom_by(1.1)
		elif mb.button_index == MOUSE_BUTTON_WHEEL_DOWN and mb.pressed:
			_zoom_by(1.0 / 1.1)
		elif mb.button_index in [MOUSE_BUTTON_LEFT, MOUSE_BUTTON_RIGHT]:
			_drag = mb.pressed
	elif event is InputEventMouseMotion and _drag:
		_cam.global_position -= (event as InputEventMouseMotion).relative / _cam.zoom.x
	elif event is InputEventScreenTouch:
		var st := event as InputEventScreenTouch
		if st.pressed:
			_touches[st.index] = st.position
		else:
			_touches.erase(st.index)
		_pinch_d = _pinch_distance()
	elif event is InputEventScreenDrag:
		var sd := event as InputEventScreenDrag
		_touches[sd.index] = sd.position
		if _touches.size() >= 2:                              # Two fingers: pinch to zoom
			var d := _pinch_distance()
			if _pinch_d > 1.0 and d > 1.0:
				_zoom_by(d / _pinch_d)
			_pinch_d = d
		else:
			_cam.global_position -= sd.relative / _cam.zoom.x
	elif event is InputEventMagnifyGesture:
		_zoom_by((event as InputEventMagnifyGesture).factor)


func _pinch_distance() -> float:
	var pts: Array = _touches.values()
	return (pts[0] as Vector2).distance_to(pts[1] as Vector2) if pts.size() >= 2 else 0.0


func _zoom_by(f: float) -> void:
	if is_instance_valid(_cam):
		var z := clampf(_cam.zoom.x * f, ZOOM_MIN, ZOOM_MAX)
		_cam.zoom = Vector2(z, z)


## Hides every other layer of the screen (HUD, touch controls, overlays) - not the backdrop.
func _toggle_hud() -> void:
	if _hud_hidden:
		for l in _hidden_layers:
			if is_instance_valid(l):
				(l as CanvasLayer).visible = true
		_hidden_layers.clear()
		_hud_hidden = false
		_show("HUD ON")
		return
	for l in get_tree().root.find_children("*", "CanvasLayer", true, false):
		var cl := l as CanvasLayer
		if cl == self or cl.layer < 0 or not cl.visible:
			continue
		cl.visible = false
		_hidden_layers.append(cl)
	_hud_hidden = true
	_show("HUD OFF")


func _save() -> void:
	_bar.visible = false
	_toast.visible = false
	await RenderingServer.frame_post_draw
	await RenderingServer.frame_post_draw
	var img := get_viewport().get_texture().get_image()
	_bar.visible = true
	_toast.visible = true
	var stamp := Time.get_datetime_string_from_system().replace(":", "-").replace("T", "_")
	var file := "ub_photo_%s.png" % stamp
	if OS.has_feature("web"):
		JavaScriptBridge.download_buffer(img.save_png_to_buffer(), file, "image/png")
		_show("SAVED  -  " + file)
	else:
		DirAccess.make_dir_recursive_absolute("user://photos")
		var err := img.save_png("user://photos/" + file)
		_show(("SAVED  -  " + ProjectSettings.globalize_path("user://photos/" + file)) if err == OK else "COULD NOT SAVE")
	SoundManager.play_sfx("ui_confirm")
	Achievements.unlock("photo_first")
	Daily.progress("photo")
