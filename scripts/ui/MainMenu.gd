extends Control
## Title screen: UNIVERSAL BEATDOWN.
##   Arena: the picked map + CHANGE ARENA (opens the Map Catalogue: Versus + every Story map)
##   Play               -> pre-fight screen (START / MATCH SETTINGS) for the picked arena
##   Buttons in TWO columns: PLAY / STORY MODE / SWITCH CHARACTERS (left) and
##   MAP CATALOGUE / ACHIEVEMENTS / SETTINGS (right), EXIT under them (not on Web)
##   Settings           -> graphics, FPS counter, controls, touch UI size, audio (Match Settings live on the pre-fight screen)

const VERSION := "v0.3.3"

var _play: Button
var _arena_desc: Label
var _rows: Array[Control] = []
var _title: Label
var _glow: Label
var _title_y := 0.0


## WEB: the page's loading bar (web_shell/shell.html) fills up and disappears only when this is called -
## after the menu has drawn its first frame, so the game shows up exactly when the bar is full.
func _tell_page_ready() -> void:
	if not OS.has_feature("web"):
		return
	await RenderingServer.frame_post_draw
	JavaScriptBridge.eval("if (window.ubReady) { window.ubReady(); }", true)


func _ready() -> void:
	SoundManager.play_music("menu")              # Keeps playing if it already is
	BossRush.cancel()                             # Left a Boss Rush through the pause menu
	QoL.save_picks()                              # Your fighter / opponent / arena come back next time
	_build()
	UiStyle.focus_later(_play)
	_tell_page_ready.call_deferred()
	_add_code_button()


# ============================================================
# SECRET CODES (class SecretCodes, scripts/codes/GameCodes.gd): phones get a CODE button, PC types arrow / WASD orders
# ============================================================
var _code_panel: CodePanel = null


## Phones / tablets only: a small CODE button in the top-right corner.
func _add_code_button() -> void:
	if not _is_touch_device():
		return
	var b := UiStyle.make_button("CODE", Vector2(110, 46), 18)
	b.anchor_left = 1.0
	b.anchor_right = 1.0
	b.offset_left = -126.0
	b.offset_right = -16.0
	b.offset_top = 14.0
	b.offset_bottom = 60.0
	b.focus_mode = Control.FOCUS_NONE
	b.modulate.a = 0.75
	b.pressed.connect(func() -> void: _open_codes(""))
	add_child(b)


static func _is_touch_device() -> bool:
	return OS.has_feature("mobile") or OS.has_feature("web_android") or OS.has_feature("web_ios") or DisplayServer.is_touchscreen_available()


func _open_codes(preset: String) -> void:
	if _code_panel != null and is_instance_valid(_code_panel):
		return
	_code_panel = CodePanel.open(self, preset)
	_code_panel.closed.connect(func() -> void:
		_code_panel = null
		_refresh_after_code.call_deferred())


## A code may change who you are (Rotor Mode) or the achievement count: rebuild the menu.
func _refresh_after_code() -> void:
	if is_inside_tree():
		get_tree().reload_current_scene()


## PC: arrow keys / WASD / D-pad on the Main Menu feed the code orders (they still move the focus too).
func _input(event: InputEvent) -> void:
	if _code_panel != null and is_instance_valid(_code_panel):
		return
	if get_tree().root.get_node_or_null("XanxxePanel") != null:
		return
	var d := ""
	var k := event as InputEventKey
	if k != null and k.pressed and not k.echo:
		match k.physical_keycode:
			KEY_W, KEY_UP:
				d = "U"
			KEY_S, KEY_DOWN:
				d = "D"
			KEY_A, KEY_LEFT:
				d = "L"
			KEY_D, KEY_RIGHT:
				d = "R"
	var jb := event as InputEventJoypadButton
	if jb != null and jb.pressed:
		match jb.button_index:
			JOY_BUTTON_DPAD_UP:
				d = "U"
			JOY_BUTTON_DPAD_DOWN:
				d = "D"
			JOY_BUTTON_DPAD_LEFT:
				d = "L"
			JOY_BUTTON_DPAD_RIGHT:
				d = "R"
	if d == "":
		return
	var id := SecretCodes.feed(d)
	if id == "xanxxe":
		if get_tree().root.get_node_or_null("XanxxePanel") == null:
			XanxxePanel.open(get_tree())
	elif id != "":
		_open_codes(id)


func _build() -> void:
	SecretCodes.load_codes()
	var you := CharacterRoster.get_entry("rotor") if SecretCodes.rotor_mode else CharacterRoster.selected()
	var opp := CharacterRoster.opponent()

	# Portraits: you bottom-left, opponent bottom-right
	_add_portrait(you, true)
	_add_portrait(opp, false)

	var col := VBoxContainer.new()
	col.set_anchors_and_offsets_preset(Control.PRESET_FULL_RECT)
	col.alignment = BoxContainer.ALIGNMENT_CENTER
	col.add_theme_constant_override("separation", 10)
	add_child(col)

	# Title: floats gently, with a soft glow copy behind it (both outside the layout, so they can move)
	var title_slot := Control.new()
	title_slot.custom_minimum_size = Vector2(0, 92)
	col.add_child(title_slot)
	_glow = UiStyle.label("UNIVERSAL BEATDOWN", 72, Color(1.0, 0.75, 0.35), 30)
	_glow.set_anchors_and_offsets_preset(Control.PRESET_FULL_RECT)
	title_slot.add_child(_glow)
	_title = UiStyle.label("UNIVERSAL BEATDOWN", 72, UiStyle.TEXT, 16)
	_title.set_anchors_and_offsets_preset(Control.PRESET_FULL_RECT)
	title_slot.add_child(_title)
	_title_y = _title.position.y
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

	# Buttons, by importance: PLAY / the modes / extras / system - each row fades in
	var top := _row(col, 18)                                    # PLAY + PLAY ONLINE: the two big ones
	_play = UiStyle.make_button("PLAY", Vector2(360, 74), 34)
	_play.add_theme_color_override("font_color", Color(0.75, 1.0, 0.7))
	_play.pressed.connect(_on_play)
	top.add_child(_play)
	var online_btn := UiStyle.make_button("PLAY ONLINE", Vector2(360, 74), 32)   # 2026-11-23: rooms by code (NetLink)
	online_btn.add_theme_color_override("font_color", Color(0.5, 0.9, 1.0))
	online_btn.pressed.connect(func() -> void: get_tree().change_scene_to_file("res://scenes/OnlineMenu.tscn"))
	top.add_child(online_btn)

	var modes := _row(col, 16)
	var story_btn := UiStyle.make_button("STORY MODE", Vector2(300, 58), 24)
	story_btn.add_theme_color_override("font_color", Color(1.0, 0.65, 0.3))
	story_btn.pressed.connect(func() -> void: get_tree().change_scene_to_file(StoryManager.STORY_MENU))
	modes.add_child(story_btn)
	var rush_btn := UiStyle.make_button("BOSS RUSH", Vector2(300, 58), 24)
	rush_btn.add_theme_color_override("font_color", Color(1.0, 0.5, 0.35))
	rush_btn.pressed.connect(func() -> void: get_tree().change_scene_to_file(BossRush.MENU_SCENE))
	modes.add_child(rush_btn)

	var extras := _row(col, 12)
	var switch_btn := UiStyle.make_button("SWITCH CHARACTERS", Vector2(260, 50), 19)
	switch_btn.pressed.connect(_on_switch)
	extras.add_child(switch_btn)
	var cat_btn := UiStyle.make_button("MAP CATALOGUE", Vector2(260, 50), 19)
	cat_btn.pressed.connect(_on_catalogue)
	extras.add_child(cat_btn)
	var rep_btn := UiStyle.make_button("REPLAYS", Vector2(260, 50), 19)
	rep_btn.pressed.connect(func() -> void: get_tree().change_scene_to_file("res://scenes/ReplaysMenu.tscn"))
	extras.add_child(rep_btn)

	var sys := _row(col, 12)
	var ach_btn := UiStyle.make_button("ACHIEVEMENTS  %d/%d" % [Achievements.unlocked_count(), Achievements.defs().size()], Vector2(260, 46), 17)
	ach_btn.add_theme_color_override("font_color", Color(1.0, 0.82, 0.3))
	ach_btn.pressed.connect(func() -> void: get_tree().change_scene_to_file(CharacterRoster.ACHIEVEMENTS))
	sys.add_child(ach_btn)
	var daily_btn := UiStyle.make_button("DAILY", Vector2(200, 46), 17)      # 2026-11-23: challenges + shop
	daily_btn.add_theme_color_override("font_color", Color(0.6, 0.85, 1.0))
	daily_btn.pressed.connect(func() -> void: get_tree().change_scene_to_file("res://scenes/DailyMenu.tscn"))
	sys.add_child(daily_btn)
	var settings_btn := UiStyle.make_button("SETTINGS", Vector2(260, 46), 17)
	settings_btn.pressed.connect(_on_settings)
	sys.add_child(settings_btn)
	# EXIT (quits the game; a browser tab can't be closed by the game, so not on Web)
	if not OS.has_feature("web"):
		var exit_btn := UiStyle.make_button("EXIT", Vector2(260, 46), 17)
		exit_btn.add_theme_color_override("font_color", Color(1.0, 0.55, 0.5))
		exit_btn.pressed.connect(func() -> void: get_tree().quit())
		sys.add_child(exit_btn)

	# Version tag (bottom-right corner)
	var ver := UiStyle.label(VERSION, 14, UiStyle.TEXT_DIM, 4)
	ver.set_anchors_and_offsets_preset(Control.PRESET_BOTTOM_RIGHT)
	ver.offset_left = -160
	ver.offset_top = -30
	ver.offset_right = -14
	ver.offset_bottom = -8
	ver.horizontal_alignment = HORIZONTAL_ALIGNMENT_RIGHT
	add_child(ver)
	_animate_in()
	var sys_row: Array = sys.get_children().filter(func(c: Node) -> bool: return c is Button)   # (Every button of that row: DAILY + EXIT too)
	UiStyle.grid_focus.call_deferred([[change], [_play, online_btn], [story_btn, rush_btn], [switch_btn, cat_btn, rep_btn], sys_row])


func _row(parent: Control, sep: int) -> HBoxContainer:
	var r := HBoxContainer.new()
	r.alignment = BoxContainer.ALIGNMENT_CENTER
	r.add_theme_constant_override("separation", sep)
	parent.add_child(r)
	_rows.append(r)
	return r


## Rows fade + rise in one after another; the title floats and glows.
func _animate_in() -> void:
	for i in _rows.size():
		var c: Control = _rows[i]
		c.modulate.a = 0.0
		var tw := c.create_tween()
		tw.tween_interval(0.08 + 0.07 * float(i))
		tw.tween_property(c, "modulate:a", 1.0, 0.3)


func _process(_d: float) -> void:
	if _title == null:
		return
	var t := Time.get_ticks_msec() / 1000.0
	_title.position.y = _title_y + sin(t * 1.4) * 3.0
	if _glow != null:
		_glow.position = _title.position
		_glow.modulate.a = 0.25 + 0.15 * sin(t * 2.1)

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
