extends Control
## Shown after PLAY on the Main Menu (the fight does NOT start instantly).
##   START           -> loads the picked arena with the current settings
##   MATCH SETTINGS  -> Lives + Sandbox
##   BACK            -> Main Menu

var _start: Button


func _ready() -> void:
	SoundManager.play_music("menu")
	var col := VBoxContainer.new()
	col.set_anchors_and_offsets_preset(Control.PRESET_FULL_RECT)
	col.alignment = BoxContainer.ALIGNMENT_CENTER
	col.add_theme_constant_override("separation", 14)
	add_child(col)

	col.add_child(UiStyle.label("READY TO FIGHT?", 56, UiStyle.TEXT, 14))

	var matchup := HBoxContainer.new()
	matchup.alignment = BoxContainer.ALIGNMENT_CENTER
	matchup.add_theme_constant_override("separation", 18)
	matchup.add_child(UiStyle.label("YOU: %s" % CharacterRoster.selected()["short"], 24, CharacterCard.YOU_COLOR, 8))
	matchup.add_child(UiStyle.label("VS", 24, UiStyle.TEXT, 8))
	matchup.add_child(UiStyle.label("OPPONENT: %s" % CharacterRoster.opponent()["short"], 24, CharacterCard.OPP_COLOR, 8))
	col.add_child(matchup)

	var lives_txt := "INF. (Dummy fight)" if not CharacterRoster.has_opponent() else str(MatchSettings.lives)
	var info := "ARENA: %s    |    LIVES: %s" % [ArenaManager.selected_arena_entry()["name"], lives_txt]
	if MatchSettings.sandbox:
		info += "    |    SANDBOX ON"
	col.add_child(UiStyle.label(info, 20, UiStyle.TEXT_DIM, 6))

	var gap := Control.new()
	gap.custom_minimum_size = Vector2(0, 16)
	col.add_child(gap)

	_start = UiStyle.make_button("START")
	_start.size_flags_horizontal = Control.SIZE_SHRINK_CENTER
	_start.pressed.connect(_on_start)
	col.add_child(_start)

	var settings := UiStyle.make_button("MATCH SETTINGS")
	settings.size_flags_horizontal = Control.SIZE_SHRINK_CENTER
	settings.pressed.connect(func() -> void: get_tree().change_scene_to_file(CharacterRoster.MATCH_SETTINGS))
	col.add_child(settings)

	var back := UiStyle.make_button("BACK", Vector2(200, 50), 20)
	back.size_flags_horizontal = Control.SIZE_SHRINK_CENTER
	back.pressed.connect(_go_back)
	col.add_child(back)

	_start.grab_focus.call_deferred()


func _on_start() -> void:
	get_tree().change_scene_to_file(ArenaManager.selected_arena_entry()["scene"])


func _unhandled_input(event: InputEvent) -> void:
	if event.is_action_pressed("ui_cancel"):
		_go_back()


func _go_back() -> void:
	get_tree().change_scene_to_file(CharacterRoster.MAIN_MENU)
