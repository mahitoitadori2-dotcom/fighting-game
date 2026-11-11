extends Control
## ACHIEVEMENTS menu (Main Menu > ACHIEVEMENTS): a GRID of every achievement's artwork.
## Unlocked = full colour, not unlocked yet = very black. Hover (or keyboard focus) a card to
## see what you did / what you have to do. Tabs filter the grid; the GALAXY SKIN button
## turns the Multiversal reward on / off once it is unlocked.

const CARD := 116.0
const TABS := [["ALL", ""], ["VERSUS", "versus"], ["STORY", "story"], ["CHALLENGES", "challenge"], ["SECRET", "secret"]]

var _grid: GridContainer
var _count: Label
var _info_name: Label
var _info_desc: Label
var _info_state: Label
var _skin_btn: Button
var _tab_btns: Array[Button] = []
var _filter := ""
var _hovered: AchievementCard = null


func _ready() -> void:
	SoundManager.play_music("menu")
	Achievements.load_data()
	_build()
	_fill()


func _build() -> void:
	var bg := ColorRect.new()
	bg.color = Color(0.05, 0.05, 0.09)
	bg.set_anchors_and_offsets_preset(Control.PRESET_FULL_RECT)
	add_child(bg)
	var margin := MarginContainer.new()
	margin.set_anchors_and_offsets_preset(Control.PRESET_FULL_RECT)
	for side in ["margin_left", "margin_right", "margin_top", "margin_bottom"]:
		margin.add_theme_constant_override(side, 18)
	add_child(margin)
	var col := VBoxContainer.new()
	col.add_theme_constant_override("separation", 10)
	margin.add_child(col)

	var header := HBoxContainer.new()
	col.add_child(header)
	var back := UiStyle.make_button("< BACK", Vector2(150, 50), 22)
	back.pressed.connect(_go_back)
	header.add_child(back)
	var title := UiStyle.label("ACHIEVEMENTS", 40)
	title.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	header.add_child(title)
	_count = UiStyle.label("", 20, Color(1.0, 0.8, 0.3), 6)
	_count.custom_minimum_size = Vector2(150, 0)
	header.add_child(_count)

	var tabs := HBoxContainer.new()
	tabs.alignment = BoxContainer.ALIGNMENT_CENTER
	tabs.add_theme_constant_override("separation", 10)
	col.add_child(tabs)
	for tdef in TABS:
		var b := UiStyle.make_button(String(tdef[0]), Vector2(150, 42), 16)
		b.pressed.connect(_set_filter.bind(String(tdef[1])))
		tabs.add_child(b)
		_tab_btns.append(b)
	_skin_btn = UiStyle.make_button("GALAXY SKIN", Vector2(250, 42), 15)
	_skin_btn.pressed.connect(_toggle_skin)
	tabs.add_child(_skin_btn)

	var scroll := ScrollContainer.new()
	scroll.size_flags_vertical = Control.SIZE_EXPAND_FILL
	scroll.horizontal_scroll_mode = ScrollContainer.SCROLL_MODE_DISABLED
	col.add_child(scroll)
	var center := CenterContainer.new()
	center.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	scroll.add_child(center)
	_grid = GridContainer.new()
	_grid.add_theme_constant_override("h_separation", 10)
	_grid.add_theme_constant_override("v_separation", 10)
	_grid.columns = maxi(1, int((get_viewport_rect().size.x - 60.0) / (CARD + 10.0)))
	center.add_child(_grid)

	# Info panel: what you did / what you have to do
	var info := PanelContainer.new()
	info.add_theme_stylebox_override("panel", UiStyle.box(UiStyle.PANEL, UiStyle.INK, 4, 12, 14.0))
	info.custom_minimum_size = Vector2(0, 100)
	col.add_child(info)
	var ic := VBoxContainer.new()
	ic.add_theme_constant_override("separation", 2)
	info.add_child(ic)
	_info_name = UiStyle.label("Hover an achievement to see how to get it.", 22, UiStyle.TEXT, 6)
	ic.add_child(_info_name)
	_info_desc = UiStyle.label("", 16, UiStyle.TEXT_DIM, 4)
	_info_desc.autowrap_mode = TextServer.AUTOWRAP_WORD_SMART
	ic.add_child(_info_desc)
	_info_state = UiStyle.label("", 15, UiStyle.ACCENT_GREEN, 4)
	ic.add_child(_info_state)


func _fill() -> void:
	for ch in _grid.get_children():
		ch.queue_free()
	_hovered = null
	var first: Button = null
	for d in Achievements.defs():
		if _filter != "" and String(d["cat"]) != _filter:
			continue
		var got := Achievements.is_unlocked(String(d["id"]))
		var b := Button.new()
		b.custom_minimum_size = Vector2(CARD, CARD)
		b.focus_mode = Control.FOCUS_ALL
		b.mouse_default_cursor_shape = Control.CURSOR_POINTING_HAND
		b.tooltip_text = "%s\n%s" % [d["name"], d["desc"]]
		var none := StyleBoxEmpty.new()
		for st in ["normal", "pressed", "disabled"]:
			b.add_theme_stylebox_override(st, none)
		var ring := UiStyle.box(Color(0, 0, 0, 0), UiStyle.ACCENT_BLUE, 4, 18, 0.0)
		ring.draw_center = false
		ring.shadow_size = 0
		b.add_theme_stylebox_override("hover", ring)
		b.add_theme_stylebox_override("focus", ring)
		var card := AchievementCard.new()
		card.def = d
		card.locked = not got
		card.mouse_filter = Control.MOUSE_FILTER_IGNORE
		card.set_anchors_and_offsets_preset(Control.PRESET_FULL_RECT)
		card.offset_left = 4
		card.offset_top = 4
		card.offset_right = -4
		card.offset_bottom = -4
		b.add_child(card)
		b.mouse_entered.connect(_show.bind(d, card))
		b.focus_entered.connect(_show.bind(d, card))
		_grid.add_child(b)
		if first == null:
			first = b
	if first != null:
		first.grab_focus.call_deferred()
	_refresh_header()


func _show(d: Dictionary, card: AchievementCard) -> void:
	if _hovered != null and is_instance_valid(_hovered) and _hovered != card:
		_hovered.set_animate(false)
	_hovered = card
	card.set_animate(true)
	var got := Achievements.is_unlocked(String(d["id"]))
	_info_name.text = String(d["name"])
	_info_name.add_theme_color_override("font_color", Color(1.0, 0.82, 0.3) if got else UiStyle.TEXT_DIM)
	_info_desc.text = ("You did it: " if got else "To unlock: ") + String(d["desc"])
	if got:
		var when := Time.get_datetime_string_from_unix_time(int(Achievements.unlocked[d["id"]])).replace("T", "  ")
		_info_state.text = "UNLOCKED  (%s)" % when
		_info_state.add_theme_color_override("font_color", UiStyle.ACCENT_GREEN)
	else:
		_info_state.text = "LOCKED"
		_info_state.add_theme_color_override("font_color", Color(0.6, 0.6, 0.65))


func _set_filter(f: String) -> void:
	_filter = f
	SoundManager.play_sfx("spawn", -8.0)
	_fill()


func _toggle_skin() -> void:
	if not Achievements.is_unlocked(Achievements.ULTIMATE):
		_info_name.text = "GALAXY SKIN: LOCKED"
		_info_desc.text = "Unlock the Multi-Multi-Multiversal Level Of Power to wear Galaxy colours as the Architect and the Warrior."
		_info_state.text = ""
		return
	Achievements.set_galaxy_skin(not Achievements.galaxy_skin)
	SoundManager.play_sfx("spawn")
	_refresh_header()


func _refresh_header() -> void:
	var total := Achievements.defs().size()
	_count.text = "%d / %d" % [Achievements.unlocked_count(), total]
	for i in _tab_btns.size():
		_tab_btns[i].modulate = Color(1.0, 0.85, 0.4) if String(TABS[i][1]) == _filter else Color(1, 1, 1)
	if Achievements.is_unlocked(Achievements.ULTIMATE):
		_skin_btn.text = "GALAXY SKIN: %s" % ("ON" if Achievements.galaxy_skin else "OFF")
		_skin_btn.modulate = Color(0.85, 0.7, 1.0) if Achievements.galaxy_skin else Color(1, 1, 1)
	else:
		_skin_btn.text = "GALAXY SKIN: LOCKED"
		_skin_btn.modulate = Color(0.6, 0.6, 0.65)


func _unhandled_input(event: InputEvent) -> void:
	if event.is_action_pressed("ui_cancel"):
		get_viewport().set_input_as_handled()
		_go_back()


func _go_back() -> void:
	get_tree().change_scene_to_file(CharacterRoster.MAIN_MENU)
