extends Control
## THE MADNESS BOARD (scenes/MadnessBoard.tscn) - the Story board's other map. Opened with the
## STORY | MADNESS switch at the top of the Story board (only after the XANXXE code).
## Black and red, red chains hanging from hell. Pick your fighter (any but APHA Architect), then one
## of the 20 levels (they open one after another). Level 20 = THE XX0XN.

var _hero_lbl: Label
var _tiles: Array[Button] = []
var _t := 0.0
var _art: Control


func _ready() -> void:
	Madness.load_data()
	StoryProgress.load_progress()
	SoundManager.set_madness(true)                         # Dark, deep-fried sound on the board too
	SoundManager.play_music("madness_level")
	tree_exiting.connect(func() -> void: SoundManager.set_madness(false))
	MadnessFX.install_board.call_deferred(self)
	var bg := Control.new()
	bg.set_anchors_and_offsets_preset(Control.PRESET_FULL_RECT)
	bg.mouse_filter = Control.MOUSE_FILTER_IGNORE
	bg.draw.connect(func() -> void: MadnessBackdrops.paint(bg, "madness", bg.size))
	add_child(bg)
	var shade := ColorRect.new()
	shade.color = Color(0, 0, 0, 0.35)
	shade.set_anchors_and_offsets_preset(Control.PRESET_FULL_RECT)
	shade.mouse_filter = Control.MOUSE_FILTER_IGNORE
	add_child(shade)
	var col := VBoxContainer.new()
	col.set_anchors_and_offsets_preset(Control.PRESET_FULL_RECT)
	col.offset_left = 40.0
	col.offset_right = -40.0
	col.offset_top = 16.0
	col.offset_bottom = -16.0
	col.add_theme_constant_override("separation", 12)
	add_child(col)
	col.add_child(StoryModeSwitch.make(get_tree(), "madness"))
	col.add_child(UiStyle.label("M A D N E S S", 46, Madness.RED_HI, 12))
	col.add_child(UiStyle.label("Black and red. No names - only health. Every 10th level is harder.", 16, Color(0.85, 0.6, 0.55), 5))
	# Hero picker
	var hero_row := HBoxContainer.new()
	hero_row.alignment = BoxContainer.ALIGNMENT_CENTER
	hero_row.add_theme_constant_override("separation", 14)
	col.add_child(hero_row)
	var prev := UiStyle.make_button("<", Vector2(60, 52), 24)
	prev.pressed.connect(_cycle.bind(-1))
	hero_row.add_child(prev)
	_art = Control.new()
	_art.custom_minimum_size = Vector2(110, 120)
	_art.draw.connect(_draw_hero)
	hero_row.add_child(_art)
	_hero_lbl = UiStyle.label("", 22, UiStyle.TEXT, 6)
	_hero_lbl.custom_minimum_size = Vector2(320, 0)
	hero_row.add_child(_hero_lbl)
	var nxt := UiStyle.make_button(">", Vector2(60, 52), 24)
	nxt.pressed.connect(_cycle.bind(1))
	hero_row.add_child(nxt)
	_refresh_hero()
	# The 20 levels (two rows of 10)
	var grid := GridContainer.new()
	grid.columns = 10
	grid.size_flags_horizontal = Control.SIZE_SHRINK_CENTER
	grid.add_theme_constant_override("h_separation", 10)
	grid.add_theme_constant_override("v_separation", 10)
	col.add_child(grid)
	for i in Madness.COUNT:
		var n := i + 1
		var b := Button.new()
		b.custom_minimum_size = Vector2(96, 96)
		b.flat = true
		b.focus_mode = Control.FOCUS_ALL
		b.pressed.connect(_play.bind(n))
		b.draw.connect(_draw_tile.bind(b, n))
		grid.add_child(b)
		_tiles.append(b)
	var back := UiStyle.make_button("BACK", Vector2(220, 52), 20)
	back.size_flags_horizontal = Control.SIZE_SHRINK_CENTER
	back.pressed.connect(func() -> void: get_tree().change_scene_to_file(CharacterRoster.MAIN_MENU))
	col.add_child(back)
	UiStyle.focus_later(_tiles[clampi(Madness.cleared, 0, Madness.COUNT - 1)])


func _process(delta: float) -> void:
	_t += delta
	for b in _tiles:
		b.queue_redraw()
	_art.queue_redraw()


func _unhandled_input(event: InputEvent) -> void:
	if event.is_action_pressed("ui_cancel"):
		get_viewport().set_input_as_handled()
		get_tree().change_scene_to_file(CharacterRoster.MAIN_MENU)


func _cycle(d: int) -> void:
	var list := Madness.heroes()
	var i := 0
	for k in list.size():
		if String(list[k]["id"]) == Madness.hero:
			i = k
	Madness.set_hero(String(list[posmod(i + d, list.size())]["id"]))
	SoundManager.play_sfx("ui_move")
	_refresh_hero()


func _refresh_hero() -> void:
	_hero_lbl.text = "PLAYING AS:  " + String(CharacterRoster.get_entry(Madness.hero).get("name", Madness.hero)).to_upper()


func _draw_hero() -> void:
	var e := CharacterRoster.get_entry(Madness.hero)
	var art: Script = e.get("art", null)
	if art == null:
		return
	_art.draw_set_transform(Vector2(_art.size.x * 0.5, _art.size.y - 4.0), 0.0, Vector2(0.8, 0.8))
	art.call("draw_portrait", _art, _t)
	_art.draw_set_transform(Vector2.ZERO, 0.0, Vector2.ONE)


func _play(n: int) -> void:
	if not Madness.level_open(n):
		SoundManager.play_sfx("block", -6.0)
		return
	SoundManager.play_sfx("ui_confirm")
	var num := Madness.FIRST + n - 1
	StoryProgress.current_level = num
	LoadingScreen.goto(get_tree(), StoryManager.ARENA_SCENE, "%s:  %s" % [Madness.label(num), String(Madness.level(num)["title"])], "MADNESS")


func _draw_tile(b: Button, n: int) -> void:
	var sz := b.size
	var open := Madness.level_open(n)
	var done := n <= Madness.cleared
	var boss := n == Madness.COUNT
	var hard := n % 10 == 0
	var pulse := 0.5 + 0.5 * sin(_t * 3.0 + float(n))
	var fill := Color(0.10, 0.0, 0.0) if open else Color(0.06, 0.05, 0.05)
	if done:
		fill = Color(0.30, 0.02, 0.02)
	b.draw_rect(Rect2(Vector2.ZERO, sz), fill)
	var border := Madness.RED_HI if open else Color(0.25, 0.2, 0.2)
	if b.has_focus():
		border = Color(1.0, 0.7, 0.6).lerp(Madness.RED_HI, pulse)
	b.draw_rect(Rect2(Vector2.ZERO, sz), border, false, 4.0 if b.has_focus() else 2.5)
	FighterArt.label(b, Vector2(sz.x * 0.5, sz.y * 0.5 + 10.0), str(n), 34, Madness.RED_HI if open else Color(0.4, 0.35, 0.35))
	if boss:
		FighterArt.label(b, Vector2(sz.x * 0.5, 18.0), "BOSS", 14, Color(1.0, 0.85, 0.5))
	elif hard:
		FighterArt.label(b, Vector2(sz.x * 0.5, 18.0), "HARDER", 12, Color(1.0, 0.6, 0.4))
	if done:
		b.draw_polyline(PackedVector2Array([Vector2(sz.x - 30, sz.y - 22), Vector2(sz.x - 22, sz.y - 12), Vector2(sz.x - 8, sz.y - 32)]), Color(1.0, 0.4, 0.35), 4.0)
	elif not open:
		b.draw_rect(Rect2(sz * 0.5 + Vector2(-10, 16), Vector2(20, 16)), Color(0.4, 0.35, 0.35))
