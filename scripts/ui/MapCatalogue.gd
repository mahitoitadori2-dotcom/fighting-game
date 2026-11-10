extends Control
## MAP CATALOGUE: every map in the game as a clickable card (still-picture thumbnail, name,
## where it comes from). Click / tap a card (or Enter on it) to SHOW the map: a big still
## picture with its description, and buttons to pick it for Versus:
##   SELECT ARENA   - it becomes the Versus arena, back to the Main Menu
##   FIGHT HERE     - pick it and go straight to the pre-fight screen
##   CLOSE          - back to the catalogue
## Opened from the Main Menu (MAP CATALOGUE, or the arena's CHANGE button).

const CARD := Vector2i(224, 126)

var _grid: GridContainer
var _detail: Control
var _first: Button


func _ready() -> void:
	SoundManager.play_music("menu")
	_build()
	if _first != null:
		_first.grab_focus.call_deferred()


func _build() -> void:
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
	var title := UiStyle.label("MAP CATALOGUE", 40)
	title.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	header.add_child(title)
	var count := UiStyle.label("%d MAPS" % MapCatalog.entries().size(), 18, UiStyle.TEXT_DIM, 4)
	count.custom_minimum_size = Vector2(150, 0)
	header.add_child(count)
	var sub := UiStyle.label("Every map from Versus and Story Mode (Colosseums 1-5). Click a map to see it - and fight on it.", 16, UiStyle.TEXT_DIM, 4)
	sub.autowrap_mode = TextServer.AUTOWRAP_WORD_SMART
	col.add_child(sub)

	var scroll := ScrollContainer.new()
	scroll.size_flags_vertical = Control.SIZE_EXPAND_FILL
	scroll.horizontal_scroll_mode = ScrollContainer.SCROLL_MODE_DISABLED
	col.add_child(scroll)
	var center := CenterContainer.new()
	center.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	scroll.add_child(center)
	_grid = GridContainer.new()
	_grid.add_theme_constant_override("h_separation", 14)
	_grid.add_theme_constant_override("v_separation", 14)
	center.add_child(_grid)
	_grid.columns = maxi(1, int((get_viewport_rect().size.x - 40.0) / float(CARD.x + 30)))
	for e in MapCatalog.entries():
		var card := _card(e)
		_grid.add_child(card)
		if _first == null:
			_first = card


## One map card: a button with the thumbnail, the name and where the map comes from.
func _card(e: Dictionary) -> Button:
	var b := Button.new()
	b.custom_minimum_size = Vector2(CARD.x + 16, CARD.y + 66)
	b.focus_mode = Control.FOCUS_ALL
	b.mouse_default_cursor_shape = Control.CURSOR_POINTING_HAND
	var picked := String(e["id"]) == ArenaManager.selected_arena
	b.add_theme_stylebox_override("normal", UiStyle.box(UiStyle.PANEL, UiStyle.ACCENT_GREEN if picked else UiStyle.INK, 4, 8))
	b.add_theme_stylebox_override("hover", UiStyle.box(UiStyle.PANEL.lightened(0.12), UiStyle.ACCENT_BLUE, 4, 8))
	b.add_theme_stylebox_override("focus", UiStyle.box(UiStyle.PANEL.lightened(0.12), UiStyle.ACCENT_BLUE, 4, 8))
	b.add_theme_stylebox_override("pressed", UiStyle.box(UiStyle.PANEL.lightened(0.2), UiStyle.ACCENT_GREEN, 4, 8))
	var v := VBoxContainer.new()
	v.mouse_filter = Control.MOUSE_FILTER_IGNORE
	v.set_anchors_and_offsets_preset(Control.PRESET_FULL_RECT)
	v.offset_left = 8
	v.offset_top = 8
	v.offset_right = -8
	v.offset_bottom = -6
	v.add_theme_constant_override("separation", 2)
	b.add_child(v)
	v.add_child(MapCatalog.make_preview(e, CARD))
	var nm := UiStyle.label(String(e["name"]).to_upper() + ("   (SELECTED)" if picked else ""), 15, UiStyle.ACCENT_GREEN if picked else UiStyle.TEXT, 3)
	nm.mouse_filter = Control.MOUSE_FILTER_IGNORE
	nm.clip_text = true
	v.add_child(nm)
	var src := UiStyle.label(String(e["source"]), 12, UiStyle.TEXT_DIM, 2)
	src.mouse_filter = Control.MOUSE_FILTER_IGNORE
	v.add_child(src)
	b.pressed.connect(_show_map.bind(e))
	return b


# ============================================================
# BIG PREVIEW ("show the map")
# ============================================================
func _show_map(e: Dictionary) -> void:
	SoundManager.play_sfx("spawn", -6.0)
	if _detail != null:
		_detail.queue_free()
	_detail = Control.new()
	_detail.set_anchors_and_offsets_preset(Control.PRESET_FULL_RECT)
	add_child(_detail)
	var dim := ColorRect.new()
	dim.color = Color(0, 0, 0, 0.82)
	dim.set_anchors_and_offsets_preset(Control.PRESET_FULL_RECT)
	_detail.add_child(dim)
	var col := VBoxContainer.new()
	col.set_anchors_and_offsets_preset(Control.PRESET_FULL_RECT)
	col.alignment = BoxContainer.ALIGNMENT_CENTER
	col.add_theme_constant_override("separation", 8)
	_detail.add_child(col)
	col.add_child(UiStyle.label(String(e["name"]).to_upper(), 36, UiStyle.TEXT, 8))
	col.add_child(UiStyle.label(String(e["source"]), 16, UiStyle.ACCENT_BLUE, 4))
	var vs := get_viewport_rect().size
	var w := int(minf(vs.x - 80.0, (vs.y - 250.0) * 16.0 / 9.0))
	var center := CenterContainer.new()
	col.add_child(center)
	var frame := PanelContainer.new()
	frame.add_theme_stylebox_override("panel", UiStyle.box(UiStyle.INK, UiStyle.ACCENT_GREEN, 4, 4))
	center.add_child(frame)
	frame.add_child(MapCatalog.make_preview(e, Vector2i(w, int(float(w) * 9.0 / 16.0)), true))
	var desc := UiStyle.label(String(e["desc"]), 17, UiStyle.TEXT_DIM, 4)
	desc.autowrap_mode = TextServer.AUTOWRAP_WORD_SMART
	col.add_child(desc)
	var row := HBoxContainer.new()
	row.alignment = BoxContainer.ALIGNMENT_CENTER
	row.add_theme_constant_override("separation", 14)
	col.add_child(row)
	var sel := UiStyle.make_button("SELECT ARENA", Vector2(240, 54), 20)
	sel.pressed.connect(func() -> void:
		ArenaManager.selected_arena = String(e["id"])
		_go_back())
	row.add_child(sel)
	var fight := UiStyle.make_button("FIGHT HERE", Vector2(220, 54), 20)
	fight.pressed.connect(func() -> void:
		ArenaManager.selected_arena = String(e["id"])
		get_tree().change_scene_to_file(CharacterRoster.PRE_FIGHT))
	row.add_child(fight)
	var close := UiStyle.make_button("CLOSE", Vector2(160, 54), 20)
	close.pressed.connect(_close_detail)
	row.add_child(close)
	fight.grab_focus.call_deferred()


func _close_detail() -> void:
	if _detail != null:
		_detail.queue_free()
		_detail = null
	if _first != null:
		_first.grab_focus.call_deferred()


func _unhandled_input(event: InputEvent) -> void:
	if event.is_action_pressed("ui_cancel"):
		if _detail != null:
			_close_detail()
		else:
			_go_back()
		get_viewport().set_input_as_handled()


func _go_back() -> void:
	get_tree().change_scene_to_file(CharacterRoster.MAIN_MENU)
