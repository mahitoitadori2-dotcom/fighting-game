class_name CharacterCard
extends PanelContainer
## One fighter in the Character Select grid: portrait, name and its own move
## list underneath. Built entirely from a CharacterRoster entry.
## LEFT click = pick as YOU.  RIGHT click = pick as OPPONENT.

signal chosen(id: String)            # Left click
signal chosen_opponent(id: String)   # Right click

const CARD_WIDTH := 340.0
const YOU_COLOR := Color(0.30, 0.90, 0.35)
const OPP_COLOR := Color(1.0, 0.38, 0.32)
const BOTH_COLOR := Color(1.0, 0.82, 0.25)

var character_id := ""
var _entry: Dictionary
var _accent := UiStyle.ACCENT_BLUE
var _selectable := false
var _is_you := false
var _is_opp := false
var _hover := false
var _badge: Label
var _style_normal: StyleBoxFlat
var _style_hover: StyleBoxFlat


func setup(entry: Dictionary) -> void:
	_entry = entry
	character_id = entry["id"]
	_accent = entry.get("accent", UiStyle.ACCENT_BLUE)
	_selectable = entry.get("selectable", false)

	custom_minimum_size = Vector2(CARD_WIDTH, 0)
	mouse_filter = Control.MOUSE_FILTER_PASS       # PASS: dragging on a card still scrolls the list (touch)
	focus_mode = Control.FOCUS_ALL if _selectable else Control.FOCUS_NONE
	if _selectable:
		mouse_default_cursor_shape = Control.CURSOR_POINTING_HAND
		tooltip_text = ("Click: fight %s (boss)" % entry["name"]) if entry.get("enemy", false) else ("Left click: play as %s\nRight click: fight against %s" % [entry["name"], entry["name"]])

	_style_normal = UiStyle.box(UiStyle.PANEL, UiStyle.INK, 5, 18, 16.0)
	_style_hover = UiStyle.box(UiStyle.PANEL_LIGHT, UiStyle.INK, 5, 18, 16.0)

	var v := VBoxContainer.new()
	v.add_theme_constant_override("separation", 8)
	v.mouse_filter = Control.MOUSE_FILTER_IGNORE
	add_child(v)

	# --- Portrait ---
	var frame := PanelContainer.new()
	frame.mouse_filter = Control.MOUSE_FILTER_IGNORE
	var frame_style := UiStyle.box(Color(0.30, 0.42, 0.62), UiStyle.INK, 4, 12, 0.0)
	frame_style.shadow_size = 0
	frame.add_theme_stylebox_override("panel", frame_style)
	var portrait := CharacterPortrait.new()
	portrait.art = entry.get("art", null)
	portrait.portrait_h = float(entry.get("portrait_h", 0.0))
	portrait.accent = _accent
	portrait.custom_minimum_size = Vector2(0, 200)
	frame.add_child(portrait)
	v.add_child(frame)

	# --- Name + selection badge ---
	v.add_child(UiStyle.label(String(entry["name"]).to_upper(), 24))
	var bar := ColorRect.new()
	bar.color = _accent
	bar.custom_minimum_size = Vector2(0, 4)
	bar.mouse_filter = Control.MOUSE_FILTER_IGNORE
	v.add_child(bar)
	_badge = UiStyle.label("", 16, UiStyle.TEXT_DIM, 5)
	v.add_child(_badge)

	# --- Moves list ---
	var moves := VBoxContainer.new()
	moves.add_theme_constant_override("separation", 7)
	moves.mouse_filter = Control.MOUSE_FILTER_IGNORE
	v.add_child(moves)
	for m in entry.get("moves", []):
		moves.add_child(_move_row(m))

	if not _selectable:
		modulate = Color(0.55, 0.55, 0.6)
		_badge.text = "LOCKED"

	mouse_entered.connect(_set_hover.bind(true))
	mouse_exited.connect(_set_hover.bind(false))
	focus_entered.connect(_set_hover.bind(true))     # Controller: the focused card is highlighted
	focus_exited.connect(_set_hover.bind(false))
	_apply_style()


func _set_hover(on: bool) -> void:
	_hover = on
	_apply_style()


func _move_row(m: Dictionary) -> Control:
	var row := VBoxContainer.new()
	row.add_theme_constant_override("separation", 0)
	row.mouse_filter = Control.MOUSE_FILTER_IGNORE

	var top := HBoxContainer.new()
	top.mouse_filter = Control.MOUSE_FILTER_IGNORE
	var name_label := UiStyle.label(m.get("name", ""), 18, UiStyle.TEXT, 5)
	name_label.horizontal_alignment = HORIZONTAL_ALIGNMENT_LEFT
	name_label.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	top.add_child(name_label)
	var key := String(m.get("key", ""))
	if key != "":
		top.add_child(UiStyle.label("[%s]" % key, 15, _accent, 5))
	row.add_child(top)

	var info := UiStyle.label(m.get("info", ""), 14, UiStyle.TEXT_DIM, 4)
	info.horizontal_alignment = HORIZONTAL_ALIGNMENT_LEFT
	info.autowrap_mode = TextServer.AUTOWRAP_WORD_SMART
	row.add_child(info)
	return row


func set_selection(is_you: bool, is_opp: bool) -> void:
	_is_you = is_you
	_is_opp = is_opp
	if _selectable and _entry.get("enemy", false):
		_badge.text = "OPPONENT (BOSS)" if is_opp else "BOSS - click to fight"
		_badge.add_theme_color_override("font_color", OPP_COLOR if is_opp else Color(0.45, 0.70, 1.0))
	elif _selectable:
		if is_you and is_opp:
			_badge.text = "YOU + OPPONENT (mirror match)"
			_badge.add_theme_color_override("font_color", BOTH_COLOR)
		elif is_you:
			_badge.text = "YOU"
			_badge.add_theme_color_override("font_color", YOU_COLOR)
		elif is_opp:
			_badge.text = "OPPONENT"
			_badge.add_theme_color_override("font_color", OPP_COLOR)
		else:
			_badge.text = " "                 # Instructions live in the screen header, not on cards
			_badge.add_theme_color_override("font_color", UiStyle.TEXT_DIM)
	_apply_style()


func _apply_style() -> void:
	var s := _style_normal
	if _is_you or _is_opp:
		var col := BOTH_COLOR if (_is_you and _is_opp) else (YOU_COLOR if _is_you else OPP_COLOR)
		s = UiStyle.box(UiStyle.PANEL_LIGHT, col, 6, 18, 16.0)
	elif _hover and _selectable:
		s = _style_hover
	add_theme_stylebox_override("panel", s)


## Mouse:      left click = YOU, right click = OPPONENT
## Touch:      tap = YOU, press and HOLD 0.45 s = OPPONENT (no right click on phones).
##             Dragging to scroll the list never selects anything.
## Controller: A = YOU, Y = OPPONENT (D-pad / stick moves between cards)
const HOLD_TIME := 450
var _press_ms := -1
var _press_pos := Vector2.ZERO
var _hold_hint := false


func _gui_input(event: InputEvent) -> void:
	if not _selectable:
		return
	if event is InputEventMouseButton:
		if event.button_index == MOUSE_BUTTON_LEFT:
			if event.pressed:
				_press_ms = Time.get_ticks_msec()
				_press_pos = event.global_position               # Screen position: stays right even if the list moves
			elif _press_ms >= 0:
				var held: int = Time.get_ticks_msec() - _press_ms
				var moved: bool = event.global_position.distance_to(_press_pos) > 14.0
				_press_ms = -1
				_set_hold_hint(false)
				if not moved:
					if held >= HOLD_TIME:
						chosen_opponent.emit(character_id)
					else:
						chosen.emit(character_id)
				accept_event()
		elif event.button_index == MOUSE_BUTTON_RIGHT and event.pressed:
			chosen_opponent.emit(character_id)
			accept_event()
	elif event is InputEventMouseMotion and _press_ms >= 0 and event.global_position.distance_to(_press_pos) > 14.0:
		_press_ms = -1                              # It's a scroll drag, not a pick
		_set_hold_hint(false)
	elif event is InputEventJoypadButton and event.pressed and event.button_index == JOY_BUTTON_Y:
		chosen_opponent.emit(character_id)
		accept_event()
	elif event.is_action_pressed("ui_accept"):
		chosen.emit(character_id)
		accept_event()


func _process(_delta: float) -> void:
	# Touch feedback: after holding long enough, tell the player releasing picks the OPPONENT
	if _press_ms >= 0 and not _hold_hint and Time.get_ticks_msec() - _press_ms >= HOLD_TIME:
		_set_hold_hint(true)


func _set_hold_hint(on: bool) -> void:
	_hold_hint = on
	if on:
		_badge.text = "RELEASE = OPPONENT"
		_badge.add_theme_color_override("font_color", OPP_COLOR)
	else:
		set_selection(_is_you, _is_opp)
