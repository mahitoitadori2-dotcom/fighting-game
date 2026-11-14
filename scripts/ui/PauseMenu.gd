class_name PauseMenu
extends CanvasLayer
## PAUSE MENU (Esc / controller Start / the touch MENU button) in every fight scene: Versus, Story,
## DemiLand, The Caves, the Map Catalogue fights. The game is FROZEN while it is open (the music
## keeps playing, quieter).
##   RESUME            back to the fight (Esc again does the same)
##   RESTART           the same level / match from the start (asks first)
##   MUSIC / SOUNDS    volume sliders (saved, same as Settings)
##   QUIT              Story: back to the board / Versus: main menu (asks first)

const FIGHT_SCENES := ["res://scenes/VoidArena.tscn", "res://scenes/StoryArena.tscn", "res://scenes/StoryMapArena.tscn",
	"res://scenes/DemiLand.tscn", "res://scenes/CaveSlide.tscn"]
const STORY_SCENES := ["res://scenes/StoryArena.tscn", "res://scenes/DemiLand.tscn", "res://scenes/CaveSlide.tscn"]

static var is_open := false

var _was_paused := false
var _confirm := ""                          # "" / "restart" / "quit": waiting for the second press
var _restart_btn: Button
var _quit_btn: Button
var _resume_btn: Button
var _music_db := 0.0


## Is the current scene a fight that can be paused?
static func in_fight(tree: SceneTree) -> bool:
	return tree.current_scene != null and FIGHT_SCENES.has(tree.current_scene.scene_file_path)


static func toggle(tree: SceneTree) -> void:
	var open := tree.root.get_node_or_null("PauseMenu") as PauseMenu
	if open != null:
		open.close()
		return
	var m := PauseMenu.new()
	m.name = "PauseMenu"
	tree.root.add_child(m)


func _ready() -> void:
	layer = 120                                 # Above the HUD, the dialogue box and the touch controls
	process_mode = Node.PROCESS_MODE_ALWAYS
	is_open = true
	_was_paused = get_tree().paused
	get_tree().paused = true
	get_tree().node_removed.connect(_on_node_removed)
	_music_db = SoundManager.get_volume("music")
	SoundManager.set_volume("music", _music_db * 0.45)          # Quieter while paused (restored on close)
	_build()
	_resume_btn.grab_focus.call_deferred()


func _exit_tree() -> void:
	is_open = false


## The scene changed under the menu (e.g. a level ended): close without touching the pause state.
func _on_node_removed(n: Node) -> void:
	if n == get_tree().current_scene and is_inside_tree():
		SoundManager.set_volume("music", _music_db)
		queue_free()


func close() -> void:
	SoundManager.set_volume("music", _music_db)
	get_tree().paused = _was_paused             # (Still frozen if a dialogue box was open under it)
	queue_free()


func _unhandled_input(event: InputEvent) -> void:
	if event.is_action_pressed("pause_menu") or event.is_action_pressed("ui_cancel"):
		get_viewport().set_input_as_handled()
		close()


func _build() -> void:
	var shade := ColorRect.new()
	shade.color = Color(0, 0, 0, 0.62)
	shade.set_anchors_and_offsets_preset(Control.PRESET_FULL_RECT)
	add_child(shade)
	var panel := PanelContainer.new()
	panel.set_anchors_and_offsets_preset(Control.PRESET_CENTER)
	panel.custom_minimum_size = Vector2(440, 0)
	panel.offset_left = -220
	panel.offset_right = 220
	panel.offset_top = -250
	panel.offset_bottom = 250
	var sb := StyleBoxFlat.new()
	sb.bg_color = Color(0.03, 0.03, 0.04, 0.96)
	sb.border_color = Color(0.78, 0.60, 0.28)
	sb.set_border_width_all(4)
	sb.set_corner_radius_all(6)
	sb.content_margin_left = 28
	sb.content_margin_right = 28
	sb.content_margin_top = 22
	sb.content_margin_bottom = 26
	panel.add_theme_stylebox_override("panel", sb)
	add_child(panel)
	var box := VBoxContainer.new()
	box.add_theme_constant_override("separation", 12)
	panel.add_child(box)
	box.add_child(UiStyle.label("PAUSED", 40, Color(1.0, 0.86, 0.5), 10))
	var where := _where_text()
	if where != "":
		box.add_child(UiStyle.label(where, 16, Color(0.85, 0.82, 0.76), 4))
	_resume_btn = UiStyle.make_button("RESUME", Vector2(380, 58), 24)
	_resume_btn.pressed.connect(close)
	box.add_child(_resume_btn)
	_restart_btn = UiStyle.make_button("RESTART", Vector2(380, 54), 22)
	_restart_btn.pressed.connect(_on_restart)
	box.add_child(_restart_btn)
	box.add_child(_slider("MUSIC", "music"))
	box.add_child(_slider("SOUNDS", "sfx"))
	_quit_btn = UiStyle.make_button(_quit_text(), Vector2(380, 54), 20)
	_quit_btn.pressed.connect(_on_quit)
	box.add_child(_quit_btn)


func _where_text() -> String:
	var path := get_tree().current_scene.scene_file_path
	if STORY_SCENES.has(path):
		var n := StoryProgress.current_level
		var t := "%s  -  %s" % [StoryLevels.level_label(n), String(StoryLevels.get_level(n).get("title", ""))]
		return t + "\nDifficulty: " + StoryDifficulty.name_of()
	return ""


func _quit_text() -> String:
	return "QUIT TO STORY BOARD" if STORY_SCENES.has(get_tree().current_scene.scene_file_path) else "QUIT TO MAIN MENU"


func _slider(title: String, which: String) -> HBoxContainer:
	var row := HBoxContainer.new()
	row.add_theme_constant_override("separation", 12)
	var l := UiStyle.label(title, 18, Color(0.9, 0.88, 0.82), 4)
	l.custom_minimum_size = Vector2(100, 0)
	row.add_child(l)
	var s := HSlider.new()
	s.min_value = 0.0
	s.max_value = 1.0
	s.step = 0.05
	s.custom_minimum_size = Vector2(260, 30)
	s.size_flags_vertical = Control.SIZE_SHRINK_CENTER
	s.value = _music_db if which == "music" else SoundManager.get_volume(which)
	s.value_changed.connect(func(v: float) -> void:
		if which == "music":
			_music_db = v
			SoundManager.set_volume("music", v * 0.45)
		else:
			SoundManager.set_volume(which, v)
			SoundManager.play_sfx("hit", -6.0))
	row.add_child(s)
	return row


## RESTART / QUIT ask once more ("SURE? PRESS AGAIN") so one wrong tap loses nothing.
func _on_restart() -> void:
	if _confirm != "restart":
		_ask("restart")
		return
	_leave("")


func _on_quit() -> void:
	if _confirm != "quit":
		_ask("quit")
		return
	var story := STORY_SCENES.has(get_tree().current_scene.scene_file_path)
	_leave(StoryManager.STORY_MENU if story else CharacterRoster.MAIN_MENU)


func _ask(what: String) -> void:
	_confirm = what
	_restart_btn.text = "SURE? PRESS AGAIN TO RESTART" if what == "restart" else "RESTART"
	_quit_btn.text = "SURE? PRESS AGAIN TO QUIT" if what == "quit" else _quit_text()


## Leave the fight: scene = "" restarts it, otherwise that scene opens. The calls go to the
## SceneTree itself (this menu is freed right after).
func _leave(scene: String) -> void:
	var tree := get_tree()
	SoundManager.set_volume("music", _music_db)
	CombatManager.end_time_stop()
	Effects.clear_hitstop()
	tree.paused = false
	if scene == "":
		tree.reload_current_scene.call_deferred()
	else:
		tree.change_scene_to_file.call_deferred(scene)
	queue_free()
