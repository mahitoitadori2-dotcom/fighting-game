extends Control
## Title screen: UNIVERSAL BEATDOWN.
##   Arena picker (Test Arena / Void Arena)
##   Play               -> loads the picked arena: YOU vs OPPONENT (or Dummy)
##   Switch Characters  -> Character Select

var _play: Button
var _arena_desc: Label


func _ready() -> void:
	SoundManager.play_music("menu")              # Keeps playing if it already is
	_build()
	_play.grab_focus.call_deferred()


func _build() -> void:
	var you := CharacterRoster.selected()
	var opp := CharacterRoster.opponent()

	# Portraits: you bottom-left, opponent bottom-right
	_add_portrait(you, true)
	_add_portrait(opp, false)

	var col := VBoxContainer.new()
	col.set_anchors_and_offsets_preset(Control.PRESET_FULL_RECT)
	col.alignment = BoxContainer.ALIGNMENT_CENTER
	col.add_theme_constant_override("separation", 10)
	add_child(col)

	col.add_child(UiStyle.label("UNIVERSAL BEATDOWN", 72, UiStyle.TEXT, 16))
	var matchup := HBoxContainer.new()
	matchup.alignment = BoxContainer.ALIGNMENT_CENTER
	matchup.add_theme_constant_override("separation", 18)
	matchup.add_child(UiStyle.label("YOU: %s" % you["short"], 24, CharacterCard.YOU_COLOR, 8))
	matchup.add_child(UiStyle.label("VS", 24, UiStyle.TEXT, 8))
	matchup.add_child(UiStyle.label("OPPONENT: %s" % opp["short"], 24, CharacterCard.OPP_COLOR, 8))
	col.add_child(matchup)

	var gap := Control.new()
	gap.custom_minimum_size = Vector2(0, 10)
	col.add_child(gap)

	# --- Arena picker ---
	col.add_child(UiStyle.label("ARENA", 20, UiStyle.TEXT_DIM, 6))
	var arenas := HBoxContainer.new()
	arenas.alignment = BoxContainer.ALIGNMENT_CENTER
	arenas.add_theme_constant_override("separation", 14)
	col.add_child(arenas)
	var group := ButtonGroup.new()
	for a in ArenaManager.ARENAS:
		var b := UiStyle.make_button(String(a["name"]).to_upper(), Vector2(200, 50), 20)
		b.toggle_mode = true
		b.button_group = group
		b.button_pressed = a["id"] == ArenaManager.selected_arena
		b.add_theme_stylebox_override("pressed", UiStyle.box(Color(0.18, 0.62, 0.30), UiStyle.ACCENT_GREEN, 4))
		b.toggled.connect(_on_arena_toggled.bind(a["id"]))
		arenas.add_child(b)
	_arena_desc = UiStyle.label(ArenaManager.selected_arena_entry()["desc"], 15, UiStyle.TEXT_DIM, 5)
	col.add_child(_arena_desc)

	var gap2 := Control.new()
	gap2.custom_minimum_size = Vector2(0, 8)
	col.add_child(gap2)

	_play = UiStyle.make_button("PLAY")
	_play.size_flags_horizontal = Control.SIZE_SHRINK_CENTER
	_play.pressed.connect(_on_play)
	col.add_child(_play)

	var story_btn := UiStyle.make_button("STORY MODE")
	story_btn.size_flags_horizontal = Control.SIZE_SHRINK_CENTER
	story_btn.add_theme_color_override("font_color", Color(1.0, 0.65, 0.3))
	story_btn.pressed.connect(func() -> void: get_tree().change_scene_to_file(StoryManager.STORY_MENU))
	col.add_child(story_btn)

	var switch_btn := UiStyle.make_button("SWITCH CHARACTERS")
	switch_btn.size_flags_horizontal = Control.SIZE_SHRINK_CENTER
	switch_btn.pressed.connect(_on_switch)
	col.add_child(switch_btn)

	var settings_btn := UiStyle.make_button("SETTINGS")
	settings_btn.size_flags_horizontal = Control.SIZE_SHRINK_CENTER
	settings_btn.pressed.connect(_on_settings)
	col.add_child(settings_btn)

	var hint := UiStyle.label(
		"A/D move   W jump   S crouch   Click attack   F block   1/2/3 moves   G ultimate   Esc menu" if Input.get_connected_joypads().is_empty() else "Controller: Stick move  A jump  X attack  RB/LT block  Y/B/LB moves  RT ultimate  Start menu",
		15, UiStyle.TEXT_DIM, 5)
	hint.set_anchors_and_offsets_preset(Control.PRESET_CENTER_BOTTOM)
	hint.offset_top = -36
	hint.offset_bottom = -12
	hint.offset_left = -500
	hint.offset_right = 500
	add_child(hint)


func _add_portrait(entry: Dictionary, left: bool) -> void:
	var portrait := CharacterPortrait.new()
	portrait.art = entry.get("art", null)
	portrait.accent = CharacterCard.YOU_COLOR if left else CharacterCard.OPP_COLOR
	if left:
		portrait.set_anchors_and_offsets_preset(Control.PRESET_BOTTOM_LEFT)
		portrait.offset_left = 10
		portrait.offset_right = 250
	else:
		portrait.set_anchors_and_offsets_preset(Control.PRESET_BOTTOM_RIGHT)
		portrait.offset_left = -250
		portrait.offset_right = -10
	portrait.offset_top = -300
	portrait.offset_bottom = -30
	add_child(portrait)
	if not left:
		portrait.scale = Vector2(-1, 1)          # Opponent faces the player
		portrait.pivot_offset = Vector2(120, 135)


func _on_arena_toggled(on: bool, id: String) -> void:
	if on:
		ArenaManager.selected_arena = id
		_arena_desc.text = ArenaManager.arena_entry(id)["desc"]


func _on_play() -> void:
	get_tree().change_scene_to_file(CharacterRoster.PRE_FIGHT)      # START / MATCH SETTINGS screen


func _on_settings() -> void:
	MatchSettings.return_scene = CharacterRoster.MAIN_MENU      # BACK comes here, not to the pre-fight screen
	get_tree().change_scene_to_file(CharacterRoster.MATCH_SETTINGS)


func _on_switch() -> void:
	get_tree().change_scene_to_file(CharacterRoster.CHARACTER_SELECT)
