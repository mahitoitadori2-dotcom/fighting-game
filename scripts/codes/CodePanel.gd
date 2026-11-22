class_name CodePanel
extends CanvasLayer
## The SECRET CODE window (Main Menu). Phones: opened by the CODE button - type a code, ENTER.
## PC: opened by a finished arrow / WASD order with `preset` = the code id (no typing needed).
## "Fu11 lOO percen7" asks YES / NO first: it can't be undone.

signal closed

var preset := ""
var _edit: LineEdit
var _msg: Label
var _title: Label
var _enter: Button
var _close: Button
var _yes: Button
var _no: Button
var _pending := ""


static func open(host: Node, p_preset: String = "") -> CodePanel:
	var p := CodePanel.new()
	p.preset = p_preset
	host.add_child(p)
	return p


func _ready() -> void:
	layer = 60
	var dim := ColorRect.new()
	dim.color = Color(0, 0, 0, 0.6)
	dim.set_anchors_and_offsets_preset(Control.PRESET_FULL_RECT)
	add_child(dim)
	var center := CenterContainer.new()
	center.set_anchors_and_offsets_preset(Control.PRESET_FULL_RECT)
	add_child(center)
	var panel := PanelContainer.new()
	panel.add_theme_stylebox_override("panel", UiStyle.box(Color(0.08, 0.07, 0.12), UiStyle.ACCENT_BLUE, 4, 16, 24))
	panel.custom_minimum_size = Vector2(560, 0)
	center.add_child(panel)
	var col := VBoxContainer.new()
	col.add_theme_constant_override("separation", 14)
	panel.add_child(col)
	_title = UiStyle.label("SECRET CODE", 34, Color(1.0, 0.86, 0.4), 8)
	col.add_child(_title)
	_edit = LineEdit.new()
	_edit.placeholder_text = ""
	_edit.custom_minimum_size = Vector2(480, 60)
	_edit.add_theme_font_size_override("font_size", 28)
	_edit.alignment = HORIZONTAL_ALIGNMENT_CENTER
	_edit.text_submitted.connect(func(_t: String) -> void: _submit())
	TextEntry.hook(_edit, "Type a code:", func(_t: String) -> void: _submit())   # Web phones: the browser's own input
	col.add_child(_edit)
	_msg = UiStyle.label("", 20, UiStyle.TEXT, 5)
	_msg.autowrap_mode = TextServer.AUTOWRAP_WORD_SMART
	_msg.custom_minimum_size = Vector2(480, 0)
	col.add_child(_msg)
	var row := HBoxContainer.new()
	row.alignment = BoxContainer.ALIGNMENT_CENTER
	row.add_theme_constant_override("separation", 16)
	col.add_child(row)
	_enter = UiStyle.make_button("ENTER", Vector2(200, 58), 24)
	_enter.pressed.connect(_submit)
	row.add_child(_enter)
	_yes = UiStyle.make_button("YES", Vector2(160, 58), 24)
	_yes.pressed.connect(_confirm)
	row.add_child(_yes)
	_no = UiStyle.make_button("NO", Vector2(160, 58), 24)
	_no.pressed.connect(_cancel_confirm)
	row.add_child(_no)
	_close = UiStyle.make_button("CLOSE", Vector2(200, 58), 24)
	_close.pressed.connect(_done)
	row.add_child(_close)
	for b in [_enter, _yes, _no, _close]:
		UiStyle.ui_sounds(b)
	_yes.visible = false
	_no.visible = false
	if preset != "":
		_edit.visible = false
		_enter.visible = false
		_run(preset)
	else:
		_edit.grab_focus()


func _unhandled_input(event: InputEvent) -> void:
	if event.is_action_pressed("ui_cancel"):
		get_viewport().set_input_as_handled()
		_done()


func _submit() -> void:
	var id := SecretCodes.match_typed(_edit.text)
	if id == "":
		_msg.text = "Nothing happens. That is not a code."
		_msg.add_theme_color_override("font_color", Color(1.0, 0.5, 0.45))
		SoundManager.play_sfx("ui_back")
		_edit.select_all()
		return
	_run(id)


func _run(id: String) -> void:
	if id == "xanxxe":                                  # The biggest one: its own full-screen panel
		XanxxePanel.open(get_tree())
		_done()
		return
	_title.text = "CODE: " + String(SecretCodes.NAMES.get(id, id))
	if id == "full_100":
		_pending = id
		_msg.text = "Unlock EVERY achievement and every enemy, and mark EVERY Story level as beaten?\nThis can't be undone."
		_msg.add_theme_color_override("font_color", Color(1.0, 0.86, 0.55))
		_edit.visible = false
		_enter.visible = false
		_close.visible = false
		_yes.visible = true
		_no.visible = true
		UiStyle.focus_later(_no)
		return
	_accepted(SecretCodes.toggle(id, get_tree()))


func _confirm() -> void:
	if _pending == "full_100":
		SecretCodes.unlock_everything()
		_pending = ""
		_yes.visible = false
		_no.visible = false
		_close.visible = true
		_accepted("100% COMPLETE: every achievement, every enemy and every Story level are yours.")


func _cancel_confirm() -> void:
	_pending = ""
	_done()


func _accepted(text: String) -> void:
	print("CODE accepted: " + text)                        # (Visible in the browser console: phone tests)
	_msg.text = text
	_msg.add_theme_color_override("font_color", Color(0.6, 1.0, 0.6))
	SoundManager.play_sfx("holy")
	_edit.visible = false
	_enter.visible = false
	_close.visible = true
	UiStyle.focus_later(_close)


func _done() -> void:
	closed.emit()
	queue_free()
