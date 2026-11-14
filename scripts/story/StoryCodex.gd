class_name StoryCodex
extends CanvasLayer
## THE CODEX (Story board > CODEX): every lore item found so far. Left: the list (unfound = "???"),
## right: the item's name and its text. Esc / BACK closes it.

signal closed

var _list: ItemList
var _name: Label
var _text: RichTextLabel


func _ready() -> void:
	layer = 50
	var shade := ColorRect.new()
	shade.color = Color(0, 0, 0, 0.75)
	shade.set_anchors_and_offsets_preset(Control.PRESET_FULL_RECT)
	add_child(shade)
	var panel := PanelContainer.new()
	panel.set_anchors_and_offsets_preset(Control.PRESET_FULL_RECT)
	panel.offset_left = 60
	panel.offset_right = -60
	panel.offset_top = 40
	panel.offset_bottom = -40
	var sb := StyleBoxFlat.new()
	sb.bg_color = Color(0.03, 0.03, 0.04, 0.97)
	sb.border_color = Color(0.78, 0.60, 0.28)
	sb.set_border_width_all(4)
	sb.set_corner_radius_all(6)
	sb.content_margin_left = 24
	sb.content_margin_right = 24
	sb.content_margin_top = 16
	sb.content_margin_bottom = 18
	panel.add_theme_stylebox_override("panel", sb)
	add_child(panel)
	var col := VBoxContainer.new()
	col.add_theme_constant_override("separation", 10)
	panel.add_child(col)
	StoryProgress.load_progress()
	col.add_child(UiStyle.label("CODEX  -  %d / %d ITEMS" % [StoryProgress.lore.size(), StoryLore.count()], 30, Color(1.0, 0.86, 0.5), 8))
	var row := HBoxContainer.new()
	row.size_flags_vertical = Control.SIZE_EXPAND_FILL
	row.add_theme_constant_override("separation", 20)
	col.add_child(row)
	_list = ItemList.new()
	_list.custom_minimum_size = Vector2(380, 0)
	_list.size_flags_vertical = Control.SIZE_EXPAND_FILL
	_list.add_theme_font_size_override("font_size", 17)
	row.add_child(_list)
	var right := VBoxContainer.new()
	right.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	right.add_theme_constant_override("separation", 12)
	row.add_child(right)
	_name = UiStyle.label("", 26, Color(1.0, 0.82, 0.38), 6)
	_name.horizontal_alignment = HORIZONTAL_ALIGNMENT_LEFT
	right.add_child(_name)
	_text = RichTextLabel.new()
	_text.bbcode_enabled = false
	_text.fit_content = false
	_text.size_flags_vertical = Control.SIZE_EXPAND_FILL
	_text.add_theme_font_size_override("normal_font_size", 19)
	_text.add_theme_color_override("default_color", Color(0.9, 0.87, 0.8))
	right.add_child(_text)
	for it in StoryLore.ITEMS:
		var found := StoryLore.has(String(it[0]))
		_list.add_item(String(it[1]) if found else "???")
		_list.set_item_custom_fg_color(_list.item_count - 1, Color(1.0, 0.9, 0.7) if found else Color(0.45, 0.43, 0.4))
	_list.item_selected.connect(_show)
	var back := UiStyle.make_button("< BACK", Vector2(200, 50), 18)
	back.pressed.connect(close)
	col.add_child(back)
	var first := 0
	for i in StoryLore.ITEMS.size():
		if StoryLore.has(String(StoryLore.ITEMS[i][0])):
			first = i
			break
	_list.select(first)
	_show(first)
	_list.grab_focus.call_deferred()


func _show(i: int) -> void:
	var it: Array = StoryLore.ITEMS[i]
	if StoryLore.has(String(it[0])):
		_name.text = String(it[1])
		_text.text = String(it[2])
	else:
		_name.text = "???"
		_text.text = "Not found yet.\n\nSome great enemy still keeps this."


func _unhandled_input(event: InputEvent) -> void:
	if event.is_action_pressed("ui_cancel"):
		get_viewport().set_input_as_handled()
		close()


func close() -> void:
	closed.emit()
	queue_free()
