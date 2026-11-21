extends Control
## REPLAYS: every saved replay (newest first) - WATCH or DELETE.

var _list: VBoxContainer


func _ready() -> void:
	SoundManager.play_music("menu")
	Replay.pending = {}
	var bg := ColorRect.new()
	bg.color = Color(0.05, 0.06, 0.09)
	bg.set_anchors_and_offsets_preset(Control.PRESET_FULL_RECT)
	add_child(bg)
	var col := VBoxContainer.new()
	col.set_anchors_and_offsets_preset(Control.PRESET_FULL_RECT)
	col.offset_top = 30
	col.offset_bottom = -20
	col.add_theme_constant_override("separation", 10)
	add_child(col)
	col.add_child(UiStyle.label("REPLAYS", 60, UiStyle.ACCENT_BLUE, 12))
	col.add_child(UiStyle.label("Save a replay from the winner screen after a Versus fight.", 17, UiStyle.TEXT_DIM, 5))
	var scroll := ScrollContainer.new()
	scroll.size_flags_vertical = Control.SIZE_EXPAND_FILL
	scroll.horizontal_scroll_mode = ScrollContainer.SCROLL_MODE_DISABLED
	col.add_child(scroll)
	var center := CenterContainer.new()
	center.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	scroll.add_child(center)
	_list = VBoxContainer.new()
	_list.add_theme_constant_override("separation", 8)
	center.add_child(_list)
	var back := UiStyle.make_button("BACK", Vector2(260, 54), 22)
	back.size_flags_horizontal = Control.SIZE_SHRINK_CENTER
	back.pressed.connect(_back)
	col.add_child(back)
	_fill()
	var first := _first_button()
	UiStyle.focus_later(first if first else back)


func _fill() -> void:
	for c in _list.get_children():
		c.queue_free()
	var files := Replay.list_files()
	if files.is_empty():
		_list.add_child(UiStyle.label("No saved replays yet.", 20, UiStyle.TEXT_DIM, 6))
		return
	for path in files:
		var info := Replay.info(path)
		if info.is_empty():
			continue
		var row := HBoxContainer.new()
		row.add_theme_constant_override("separation", 10)
		var l := UiStyle.label("%s     %s     %s" % [info["title"], StoryManager.time_text(float(info["seconds"])), info["date"]], 18, UiStyle.TEXT, 5)
		l.custom_minimum_size.x = 620
		l.horizontal_alignment = HORIZONTAL_ALIGNMENT_LEFT
		row.add_child(l)
		var w := UiStyle.make_button("WATCH", Vector2(150, 46), 18)
		var p: String = path
		w.pressed.connect(func() -> void: _watch(p))
		row.add_child(w)
		var d := UiStyle.make_button("DELETE", Vector2(150, 46), 18)
		d.add_theme_color_override("font_color", Color(1.0, 0.55, 0.5))
		d.pressed.connect(func() -> void:
			DirAccess.remove_absolute(p)
			_fill()
			UiStyle.focus_later(_first_button()))
		row.add_child(d)
		_list.add_child(row)


func _first_button() -> Button:
	for row in _list.get_children():
		for c in row.get_children():
			if c is Button and not c.is_queued_for_deletion():
				return c
	return null


func _watch(path: String) -> void:
	var d := Replay.load_file(path)
	if d.is_empty():
		return
	d["return_scene"] = "res://scenes/ReplaysMenu.tscn"
	Replay.pending = d
	LoadingScreen.goto(get_tree(), String(ArenaManager.arena_entry(String(d.get("arena", "test")))["scene"]), "REPLAY", "")


func _back() -> void:
	get_tree().change_scene_to_file(CharacterRoster.MAIN_MENU)


func _unhandled_input(event: InputEvent) -> void:
	if event.is_action_pressed("ui_cancel") or event.is_action_pressed("pause_menu"):
		get_viewport().set_input_as_handled()
		_back()
