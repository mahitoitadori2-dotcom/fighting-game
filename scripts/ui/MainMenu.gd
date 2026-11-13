extends Control
## Title screen: UNIVERSAL BEATDOWN.
##   Arena: the picked map + CHANGE ARENA (opens the Map Catalogue: Versus + every Story map)
##   Play               -> pre-fight screen (START / MATCH SETTINGS) for the picked arena
##   Buttons in TWO columns: PLAY / STORY MODE / SWITCH CHARACTERS (left) and
##   MAP CATALOGUE / ACHIEVEMENTS / SETTINGS (right), EXIT under them (not on Web)
##   Settings           -> graphics, FPS counter, controls, touch UI size, audio (Match Settings live on the pre-fight screen)

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

	# Buttons: TWO columns side by side (left / right of the middle), EXIT centred under them
	var split := HBoxContainer.new()
	split.alignment = BoxContainer.ALIGNMENT_CENTER
	split.add_theme_constant_override("separation", 22)
	col.add_child(split)
	var left := VBoxContainer.new()
	left.add_theme_constant_override("separation", 10)
	split.add_child(left)
	var right := VBoxContainer.new()
	right.add_theme_constant_override("separation", 10)
	split.add_child(right)

	_play = UiStyle.make_button("PLAY")
	_play.pressed.connect(_on_play)
	left.add_child(_play)

	var story_btn := UiStyle.make_button("STORY MODE")
	story_btn.add_theme_color_override("font_color", Color(1.0, 0.65, 0.3))
	story_btn.pressed.connect(func() -> void: get_tree().change_scene_to_file(StoryManager.STORY_MENU))
	left.add_child(story_btn)

	var switch_btn := UiStyle.make_button("SWITCH CHARACTERS")
	switch_btn.pressed.connect(_on_switch)
	left.add_child(switch_btn)

	var cat_btn := UiStyle.make_button("MAP CATALOGUE")
	cat_btn.pressed.connect(_on_catalogue)
	right.add_child(cat_btn)

	var ach_btn := UiStyle.make_button("ACHIEVEMENTS  %d/%d" % [Achievements.unlocked_count(), Achievements.defs().size()])
	ach_btn.add_theme_color_override("font_color", Color(1.0, 0.82, 0.3))
	ach_btn.pressed.connect(func() -> void: get_tree().change_scene_to_file(CharacterRoster.ACHIEVEMENTS))
	right.add_child(ach_btn)

	var settings_btn := UiStyle.make_button("SETTINGS")
	settings_btn.pressed.connect(_on_settings)
	right.add_child(settings_btn)

	# EXIT (quits the game; a browser tab can't be closed by the game, so not on Web)
	if not OS.has_feature("web"):
		var exit_btn := UiStyle.make_button("EXIT", Vector2(240, 56), 24)
		exit_btn.size_flags_horizontal = Control.SIZE_SHRINK_CENTER
		exit_btn.add_theme_color_override("font_color", Color(1.0, 0.55, 0.5))
		exit_btn.pressed.connect(func() -> void: get_tree().quit())
		col.add_child(exit_btn)


func _add_portrait(entry: Dictionary, left: bool) -> void:
	var portrait := CharacterPortrait.new()
	portrait.art = entry.get("art", null)
	portrait.portrait_h = float(entry.get("portrait_h", 0.0))
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
