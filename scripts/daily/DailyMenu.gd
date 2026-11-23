extends Control
## DAILY + SHOP screen (Main Menu > DAILY): today's three challenges, your MARKS, and the palette shop.

var _marks: Label
var _shop: VBoxContainer
var _first: Button
var _focus_id := ""                                    # Keeps the focus on the palette you just pressed


func _ready() -> void:
	SoundManager.play_music("menu")
	var earned := Daily.pay_achievements()
	var bg := ColorRect.new()
	bg.color = Color(0.05, 0.06, 0.09)
	bg.set_anchors_and_offsets_preset(Control.PRESET_FULL_RECT)
	add_child(bg)
	var col := VBoxContainer.new()
	col.set_anchors_and_offsets_preset(Control.PRESET_FULL_RECT)
	col.alignment = BoxContainer.ALIGNMENT_CENTER
	col.add_theme_constant_override("separation", 14)
	add_child(col)
	col.add_child(UiStyle.label("DAILY", 60, Color(0.6, 0.85, 1.0), 14))
	_marks = UiStyle.label("", 26, Color(1.0, 0.85, 0.4), 8)
	col.add_child(_marks)
	if earned > 0:
		col.add_child(UiStyle.label("+%d MARKS FROM ACHIEVEMENTS" % earned, 18, Color(0.6, 1.0, 0.6), 5))
	var split := HBoxContainer.new()
	split.alignment = BoxContainer.ALIGNMENT_CENTER
	split.add_theme_constant_override("separation", 50)
	col.add_child(split)
	# --- Today's challenges ---
	var left := VBoxContainer.new()
	left.add_theme_constant_override("separation", 10)
	left.custom_minimum_size = Vector2(460, 0)
	split.add_child(left)
	left.add_child(UiStyle.label("TODAY  " + Time.get_date_string_from_system(), 22, UiStyle.ACCENT_BLUE, 6))
	for ch: Dictionary in Daily.challenges():
		var done := int(ch["done"]) >= int(ch["goal"])
		var row := VBoxContainer.new()
		var l := UiStyle.label(("DONE   " if done else "") + String(ch["text"]), 20, Color(0.6, 1.0, 0.6) if done else UiStyle.TEXT, 6)
		l.horizontal_alignment = HORIZONTAL_ALIGNMENT_LEFT
		row.add_child(l)
		var bar := ProgressBar.new()
		bar.max_value = float(ch["goal"])
		bar.value = float(ch["done"])
		bar.show_percentage = false
		bar.custom_minimum_size = Vector2(440, 12)
		row.add_child(bar)
		left.add_child(row)
	# --- The shop ---
	var right := VBoxContainer.new()
	right.add_theme_constant_override("separation", 8)
	split.add_child(right)
	right.add_child(UiStyle.label("PALETTES", 22, Color(1.0, 0.82, 0.3), 6))
	_shop = VBoxContainer.new()
	_shop.add_theme_constant_override("separation", 6)
	right.add_child(_shop)
	var back := UiStyle.make_button("BACK", Vector2(300, 52), 22)
	back.pressed.connect(_back)
	col.add_child(back)
	_refresh()
	UiStyle.focus_later(_first if _first != null else back)


func _refresh() -> void:
	Daily.load_data()
	_marks.text = "%d MARKS" % Daily.marks
	for c in _shop.get_children():
		c.queue_free()
	_first = null
	var none := UiStyle.make_button(("> " if Daily.equipped == "" else "") + "NO PALETTE", Vector2(360, 44), 18)
	none.pressed.connect(func() -> void:
		Daily.equip("")
		SoundManager.play_sfx("ui_confirm")
		_refresh())
	_shop.add_child(none)
	for id in Daily.PALETTES:
		var spec: Array = Daily.PALETTES[id]
		var have := Daily.owned.has(id)
		var text := String(spec[0])
		if Daily.equipped == id:
			text = "> " + text + "   (ON)"
		elif have:
			text += "   (OWNED)"
		else:
			text += "   %d MARKS" % int(spec[2])
		var b := UiStyle.make_button(text, Vector2(360, 44), 18)
		b.add_theme_color_override("font_color", spec[1])
		var pid := String(id)
		if pid == _focus_id:
			UiStyle.focus_later(b)
		b.pressed.connect(func() -> void:
			_focus_id = pid
			if Daily.owned.has(pid):
				Daily.equip(pid)
				SoundManager.play_sfx("ui_confirm")
			elif Daily.buy(pid):
				SoundManager.play_sfx("holy")
			else:
				SoundManager.play_sfx("ui_back")
			_refresh())
		_shop.add_child(b)
		if _first == null:
			_first = b


func _back() -> void:
	get_tree().change_scene_to_file(CharacterRoster.MAIN_MENU)


func _unhandled_input(event: InputEvent) -> void:
	if event.is_action_pressed("ui_cancel"):
		get_viewport().set_input_as_handled()
		_back()
