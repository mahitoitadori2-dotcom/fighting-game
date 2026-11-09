extends Control
## Title screen: UNIVERSAL BEATDOWN.
##   Arena: the picked map + CHANGE ARENA (opens the Map Catalogue: Versus + every Story map)
##   Play               -> pre-fight screen (START / MATCH SETTINGS) for the picked arena
##   Story Mode, Switch Characters, Map Catalogue
##   Settings           -> controls, touch UI size, audio (Match Settings live on the pre-fight screen)

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

	# --- Arena (pick it in the Map Catalogue) ---
	var arena := ArenaManager.selected_arena_entry()
	var arena_row := HBoxContainer.new()
	arena_row.alignment = BoxContainer.ALIGNMENT_CENTER
	arena_row.add_theme_constant_override("separation", 14)
	col.add_child(arena_row)
	arena_row.add_child(UiStyle.label("ARENA:  %s" % String(arena["name"]).to_upper(), 22, UiStyle.ACCENT_GREEN, 6))
	var change := UiStyle.make_button("CHANGE ARENA", Vector2(220, 46), 18)
	change.pressed.connect(_on_catalogue)
	arena_row.add_child(change)
	_arena_desc = UiStyle.label("%s   (%s)" % [arena["desc"], arena["source"]], 15, UiStyle.TEXT_DIM, 5)
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

	var cat_btn := UiStyle.make_button("MAP CATALOGUE")
	cat_btn.size_flags_horizontal = Control.SIZE_SHRINK_CENTER
	cat_btn.pressed.connect(_on_catalogue)
	col.add_child(cat_btn)

	var settings_btn := UiStyle.make_button("SETTINGS")
	settings_btn.size_flags_horizontal = Control.SIZE_SHRINK_CENTER
	settings_btn.pressed.connect(_on_settings)
	col.add_child(settings_btn)

	var hint := UiStyle.label(
		"A/D or Arrows move   W/Up jump   S/Down crouch   Click/Space attack   F block   1/2/3 moves   G ultimate   Esc menu" if Input.get_connected_joypads().is_empty() else "Controller: Stick move  A jump  X attack  RB/LT block  Y/B/LB moves  RT ultimate  Start menu",
		15, UiStyle.TEXT_DIM, 5)
	hint.set_anchors_and_offsets_preset(Control.PRESET_CENTER_BOTTOM)
	hint.offset_top = -36
	hint.offset_bottom = -12
	hint.offset_left = -620
	hint.offset_right = 620
	hint.grow_horizontal = Control.GROW_DIRECTION_BOTH
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


func _on_catalogue() -> void:
	get_tree().change_scene_to_file(CharacterRoster.MAP_CATALOGUE)


func _on_play() -> void:
	get_tree().change_scene_to_file(CharacterRoster.PRE_FIGHT)      # START / MATCH SETTINGS screen


## General SETTINGS (controls, touch size, audio) - separate from the Match Settings.
func _on_settings() -> void:
	MatchSettings.screen_mode = "general"
	MatchSettings.return_scene = CharacterRoster.MAIN_MENU      # BACK comes here, not to the pre-fight screen
	get_tree().change_scene_to_file(CharacterRoster.MATCH_SETTINGS)


func _on_switch() -> void:
	get_tree().change_scene_to_file(CharacterRoster.CHARACTER_SELECT)
