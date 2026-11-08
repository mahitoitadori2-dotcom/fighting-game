extends Control
## Character Select: a scrollable grid of CharacterCards built from
## CharacterRoster.playable(). Columns adapt to the window width, so 30+
## characters just wrap into more rows.
##
##   LEFT click a card  = YOUR character (you always have one)
##   RIGHT click a card = the OPPONENT (right-click it again to clear)
##   No opponent picked = the Dummy (100 HP, does not fight)
## Back button / Esc returns to the Main Menu.

const GRID_GAP := 24

var _scroll: ScrollContainer
var _grid: GridContainer
var _enemy_grid: GridContainer
var _enemy_cards: Array[CharacterCard] = []
var _enemy_buttons := {}                  # enemy id -> quick-pick Button
var _cards: Array[CharacterCard] = []
var _you_label: Label
var _opp_label: Label
var _back: Button


func _ready() -> void:
	SoundManager.play_music("menu")
	_build()
	_populate()
	_scroll.resized.connect(_update_columns)
	_update_columns.call_deferred()
	_back.grab_focus.call_deferred()


func _build() -> void:
	var margin := MarginContainer.new()
	margin.set_anchors_and_offsets_preset(Control.PRESET_FULL_RECT)
	for side in ["margin_left", "margin_right", "margin_top", "margin_bottom"]:
		margin.add_theme_constant_override(side, 22)
	add_child(margin)

	var col := VBoxContainer.new()
	col.add_theme_constant_override("separation", 10)
	margin.add_child(col)

	# Header: Back | title | spacer (keeps the title centred)
	var header := HBoxContainer.new()
	col.add_child(header)
	_back = UiStyle.make_button("< BACK", Vector2(150, 52), 22)
	_back.pressed.connect(_go_back)
	header.add_child(_back)
	var title := UiStyle.label("SELECT YOUR FIGHTER", 42)
	title.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	header.add_child(title)
	var spacer := Control.new()
	spacer.custom_minimum_size = Vector2(150, 0)
	header.add_child(spacer)

	# Instructions
	var how := HBoxContainer.new()
	how.alignment = BoxContainer.ALIGNMENT_CENTER
	how.add_theme_constant_override("separation", 30)
	how.add_child(UiStyle.label("LEFT CLICK / TAP / (A) = YOU", 18, CharacterCard.YOU_COLOR, 6))
	how.add_child(UiStyle.label("RIGHT CLICK / HOLD / (Y) = OPPONENT", 18, CharacterCard.OPP_COLOR, 6))
	col.add_child(how)

	# Selection bar: YOU / OPPONENT / clear
	var sel := HBoxContainer.new()
	sel.alignment = BoxContainer.ALIGNMENT_CENTER
	sel.add_theme_constant_override("separation", 26)
	col.add_child(sel)
	_you_label = UiStyle.label("", 24, CharacterCard.YOU_COLOR, 8)
	sel.add_child(_you_label)
	sel.add_child(UiStyle.label("VS", 24, UiStyle.TEXT, 8))
	_opp_label = UiStyle.label("", 24, CharacterCard.OPP_COLOR, 8)
	sel.add_child(_opp_label)
	var clear := UiStyle.make_button("FIGHT DUMMY", Vector2(170, 40), 16)
	clear.tooltip_text = "Clear the opponent: you will face the training Dummy"
	clear.pressed.connect(_clear_opponent)
	sel.add_child(clear)

	# Grid inside a vertical scroll
	_scroll = ScrollContainer.new()
	_scroll.size_flags_vertical = Control.SIZE_EXPAND_FILL
	_scroll.horizontal_scroll_mode = ScrollContainer.SCROLL_MODE_DISABLED
	_scroll.follow_focus = true                       # Controller: list scrolls to the focused card
	col.add_child(_scroll)

	var sections := VBoxContainer.new()
	sections.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	sections.add_theme_constant_override("separation", 18)
	_scroll.add_child(sections)

	var center := CenterContainer.new()
	center.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	sections.add_child(center)
	_grid = GridContainer.new()
	_grid.add_theme_constant_override("h_separation", GRID_GAP)
	_grid.add_theme_constant_override("v_separation", GRID_GAP)
	center.add_child(_grid)

	# ENEMY TEST: PvE enemies / bosses (opponent only)
	sections.add_child(UiStyle.label("ENEMY TEST  -  PvE BOSSES", 30, Color(0.45, 0.70, 1.0), 8))
	sections.add_child(UiStyle.label("Click an enemy to fight it (enemies can only be the OPPONENT)", 15, UiStyle.TEXT_DIM, 5))
	# Quick-pick list: any playable character vs ANY enemy, one tap
	var pick := HFlowContainer.new()
	pick.alignment = FlowContainer.ALIGNMENT_CENTER
	pick.add_theme_constant_override("h_separation", 10)
	pick.add_theme_constant_override("v_separation", 10)
	pick.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	sections.add_child(pick)
	for entry in CharacterRoster.enemies():
		var b := UiStyle.make_button(String(entry["short"]).to_upper(), Vector2(150, 42), 16)
		b.toggle_mode = true
		b.pressed.connect(_pick_enemy.bind(String(entry["id"])))
		pick.add_child(b)
		_enemy_buttons[entry["id"]] = b
	var ecenter := CenterContainer.new()
	ecenter.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	sections.add_child(ecenter)
	_enemy_grid = GridContainer.new()
	_enemy_grid.add_theme_constant_override("h_separation", GRID_GAP)
	_enemy_grid.add_theme_constant_override("v_separation", GRID_GAP)
	ecenter.add_child(_enemy_grid)

	col.add_child(UiStyle.label("Right-click the opponent again (or FIGHT DUMMY) to face the Dummy     |     Esc = back", 15, UiStyle.TEXT_DIM, 6))


func _populate() -> void:
	for entry in CharacterRoster.playable():
		var card := CharacterCard.new()
		card.setup(entry)
		card.chosen.connect(_on_pick_you)
		card.chosen_opponent.connect(_on_pick_opponent)
		_grid.add_child(card)
		_cards.append(card)
	for entry in CharacterRoster.enemies():
		var card := CharacterCard.new()
		card.setup(entry)
		card.chosen.connect(_on_pick_opponent)          # Left OR right click: enemies are always the opponent
		card.chosen_opponent.connect(_on_pick_opponent)
		_enemy_grid.add_child(card)
		_cards.append(card)
		_enemy_cards.append(card)
	_refresh_selection()


func _update_columns() -> void:
	var fit := int((_scroll.size.x + GRID_GAP) / (CharacterCard.CARD_WIDTH + GRID_GAP))
	_grid.columns = clampi(fit, 1, maxi(_cards.size() - _enemy_cards.size(), 1))
	_enemy_grid.columns = clampi(fit, 1, maxi(_enemy_cards.size(), 1))


func _on_pick_you(id: String) -> void:
	CharacterRoster.selected_id = id           # You ALWAYS have a character
	_refresh_selection()


func _on_pick_opponent(id: String) -> void:
	# Right-clicking the current opponent again clears it (back to the Dummy).
	CharacterRoster.opponent_id = "" if CharacterRoster.opponent_id == id else id
	_refresh_selection()


## Quick-pick list: always SETS the enemy (no toggle-off), so a tap never clears it.
func _pick_enemy(id: String) -> void:
	CharacterRoster.opponent_id = id
	_refresh_selection()


func _clear_opponent() -> void:
	CharacterRoster.opponent_id = ""
	_refresh_selection()


func _refresh_selection() -> void:
	for c in _cards:
		c.set_selection(c.character_id == CharacterRoster.selected_id, c.character_id == CharacterRoster.opponent_id)
	for id in _enemy_buttons:
		(_enemy_buttons[id] as Button).set_pressed_no_signal(id == CharacterRoster.opponent_id)
	_you_label.text = "YOU: %s" % CharacterRoster.selected()["short"]
	_opp_label.text = "OPPONENT: %s" % CharacterRoster.opponent()["short"]


func _unhandled_input(event: InputEvent) -> void:
	if event.is_action_pressed("ui_cancel"):
		_go_back()


func _go_back() -> void:
	get_tree().change_scene_to_file(CharacterRoster.MAIN_MENU)
