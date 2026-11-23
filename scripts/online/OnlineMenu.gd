extends Control
## ONLINE (Main Menu > ONLINE): host a room (you get a CODE), join one with its code, or QUICKPLAY
## (join any open room). Versus: the fight starts as soon as someone joins. Story: the host picks the
## levels on the board, the guest plays the other hero.

var _url: LineEdit
var _code: LineEdit
var _status: Label
var _room: Label
var _buttons: Array[Button] = []


func _ready() -> void:
	SoundManager.play_music("menu")
	var bg := ColorRect.new()
	bg.color = Color(0.05, 0.07, 0.10)
	bg.set_anchors_and_offsets_preset(Control.PRESET_FULL_RECT)
	add_child(bg)
	var col := VBoxContainer.new()
	col.set_anchors_and_offsets_preset(Control.PRESET_FULL_RECT)
	col.alignment = BoxContainer.ALIGNMENT_CENTER
	col.add_theme_constant_override("separation", 12)
	add_child(col)
	col.add_child(UiStyle.label("ONLINE", 60, Color(0.5, 0.9, 1.0), 14))
	_room = UiStyle.label("", 44, Color(1.0, 0.9, 0.5), 10)
	col.add_child(_room)
	_status = UiStyle.label("", 22, UiStyle.TEXT, 6)
	col.add_child(_status)
	var row0 := _row(col)
	row0.add_child(UiStyle.label("SERVER", 18, UiStyle.TEXT_DIM, 4))
	_url = LineEdit.new()
	_url.text = NetLink.saved_url()
	_url.custom_minimum_size = Vector2(420, 44)
	TextEntry.hook(_url, "Server address:", func(_t: String) -> void: pass)
	row0.add_child(_url)
	row0.add_child(UiStyle.label("YOU:  " + String(CharacterRoster.selected().get("short", "?")).to_upper(), 18, CharacterCard.YOU_COLOR, 4))
	var row1 := _row(col)
	_add(row1, "HOST VERSUS", func() -> void: _go(func() -> void: NetLink.get_link().host_room("versus")))
	_add(row1, "HOST STORY", func() -> void: _go(func() -> void: NetLink.get_link().host_room("story")))
	var row2 := _row(col)
	_add(row2, "QUICKPLAY VERSUS", func() -> void: _go(func() -> void: NetLink.get_link().quick("versus")))
	_add(row2, "QUICKPLAY STORY", func() -> void: _go(func() -> void: NetLink.get_link().quick("story")))
	var row3 := _row(col)
	_code = LineEdit.new()
	_code.placeholder_text = "CODE"
	_code.max_length = 5
	_code.custom_minimum_size = Vector2(180, 52)
	_code.alignment = HORIZONTAL_ALIGNMENT_CENTER
	_code.add_theme_font_size_override("font_size", 26)
	TextEntry.hook(_code, "Room code:", func(_t: String) -> void: _join())
	_code.text_submitted.connect(func(_t: String) -> void: _join())
	row3.add_child(_code)
	_add(row3, "JOIN", _join)
	var back := UiStyle.make_button("BACK", Vector2(300, 52), 22)
	back.pressed.connect(_back)
	col.add_child(back)
	var link := NetLink.get_link()
	link.status.connect(_on_status)                      # (Methods, not lambdas: they disconnect when this screen goes)
	link.failed.connect(_on_failed)
	link.room_made.connect(_on_room)
	link.joined.connect(_on_joined)
	link.peer_joined.connect(_on_peer)
	if NetLink.code != "":
		_room.text = "ROOM  " + NetLink.code
		_status.text = "WAITING FOR THE HOST" if NetLink.is_guest() else ("A PLAYER IS HERE" if NetLink.peer_here else "WAITING FOR A PLAYER")
	UiStyle.focus_later(_buttons[0])


func _row(col: VBoxContainer) -> HBoxContainer:
	var r := HBoxContainer.new()
	r.alignment = BoxContainer.ALIGNMENT_CENTER
	r.add_theme_constant_override("separation", 14)
	col.add_child(r)
	return r


func _add(row: HBoxContainer, text: String, cb: Callable) -> void:
	var b := UiStyle.make_button(text, Vector2(300, 56), 22)
	b.pressed.connect(cb)
	row.add_child(b)
	_buttons.append(b)


func _on_status(t: String) -> void:
	_status.text = t


func _on_failed(m: String) -> void:
	_status.text = m
	_status.add_theme_color_override("font_color", Color(1.0, 0.5, 0.45))


func _on_room(c: String) -> void:
	_room.text = "ROOM  " + c
	_status.text = "WAITING FOR A PLAYER"


func _on_joined(m: String, h: String) -> void:
	_room.text = "ROOM  " + NetLink.code
	_status.text = "JOINED %s  -  %s  -  WAITING FOR THE HOST" % [h, m.to_upper()]


## Connect (if needed), then do it.
func _go(then: Callable) -> void:
	_status.remove_theme_color_override("font_color")
	NetLink.save_url(_url.text)
	NetLink.get_link().connect_and(_url.text, then)


func _join() -> void:
	var c := _code.text.strip_edges().to_upper()
	if c.length() < 4:
		return
	_go(func() -> void: NetLink.get_link().join_room(c))


## HOST: someone joined -> Versus starts now; Story goes to the board (pick a level).
func _on_peer() -> void:
	SoundManager.play_sfx("holy")
	if NetLink.mode == "versus":
		ArenaManager.p1_cpu = false
		get_tree().change_scene_to_file(ArenaManager.arena_entry(ArenaManager.selected_arena)["scene"])
	else:
		get_tree().change_scene_to_file(StoryManager.STORY_MENU)


func _back() -> void:
	var l := get_tree().root.get_node_or_null("NetLink") as NetLink
	if l != null:
		l.leave()
	get_tree().change_scene_to_file(CharacterRoster.MAIN_MENU)


func _unhandled_input(event: InputEvent) -> void:
	if event.is_action_pressed("ui_cancel"):
		get_viewport().set_input_as_handled()
		_back()
