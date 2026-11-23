extends Control
## BOSS RUSH menu: pick the hero, see the bosses in the run, your last run and the TOP 10.

var _hero := "warrior"
var _right: VBoxContainer
var _start: Button


func _ready() -> void:
	SoundManager.play_music("menu")
	var bg := ColorRect.new()
	bg.color = Color(0.06, 0.05, 0.08)
	bg.set_anchors_and_offsets_preset(Control.PRESET_FULL_RECT)
	add_child(bg)
	var col := VBoxContainer.new()
	col.set_anchors_and_offsets_preset(Control.PRESET_FULL_RECT)
	col.alignment = BoxContainer.ALIGNMENT_CENTER
	col.add_theme_constant_override("separation", 12)
	add_child(col)
	col.add_child(UiStyle.label("BOSS RUSH", 64, Color(1.0, 0.55, 0.3), 14))
	var bosses := BossRush.boss_levels()
	var all := BossRush.boss_levels(false)
	col.add_child(UiStyle.label("%d / %d BOSSES" % [bosses.size(), all.size()], 18, UiStyle.TEXT_DIM, 6))
	var split := HBoxContainer.new()
	split.alignment = BoxContainer.ALIGNMENT_CENTER
	split.add_theme_constant_override("separation", 40)
	col.add_child(split)
	var left := VBoxContainer.new()
	left.add_theme_constant_override("separation", 10)
	split.add_child(left)
	left.add_child(UiStyle.label("HERO", 22, UiStyle.ACCENT_BLUE, 6))
	var first: Button = null
	for h in [["warrior", "WARRIOR"], ["architect", "THE MIGHTY ARCHITECT"]]:
		var b := UiStyle.make_button(h[1], Vector2(340, 56), 22)
		var id: String = h[0]
		b.pressed.connect(func() -> void:
			_hero = id
			_refresh())
		b.focus_entered.connect(func() -> void:
			_hero = id
			_refresh())
		left.add_child(b)
		if first == null:
			first = b
	_start = UiStyle.make_button("START RUN", Vector2(340, 64), 28)
	_start.add_theme_color_override("font_color", Color(1.0, 0.7, 0.35))
	_start.pressed.connect(_on_start)
	_start.disabled = bosses.is_empty()
	left.add_child(_start)
	var daily := UiStyle.make_button("DAILY RUN", Vector2(340, 58), 24)    # 2026-11-23: one seeded run a day
	daily.add_theme_color_override("font_color", Color(0.6, 0.85, 1.0))
	daily.pressed.connect(_on_daily)
	daily.disabled = (BossRush.daily_plan()[0] as Array).size() < 3
	left.add_child(daily)
	var back := UiStyle.make_button("BACK", Vector2(340, 52), 22)
	back.pressed.connect(_back)
	left.add_child(back)
	_right = VBoxContainer.new()
	_right.custom_minimum_size = Vector2(460, 380)
	_right.add_theme_constant_override("separation", 4)
	split.add_child(_right)
	if bosses.is_empty():
		col.add_child(UiStyle.label("Beat a boss in Story Mode first.", 20, Color(1.0, 0.6, 0.5), 6))
	if not BossRush.last_result.is_empty():
		_hero = String(BossRush.last_result.get("hero", "warrior"))
	_refresh()
	UiStyle.focus_later(_start if not _start.disabled else first)


func _refresh() -> void:
	for c in _right.get_children():
		c.queue_free()
	var r := BossRush.last_result
	if not r.is_empty() and String(r.get("hero", "")) == _hero:
		var done: bool = r.get("completed", false)
		var txt := "%s  %s   %d / %d bosses   %s" % [("DAILY (" + String(r.get("mod", "")) + "):") if r.get("daily", false) else "LAST RUN:",
			"COMPLETE" if done else "FELL", int(r["beaten"]), int(r["total"]), StoryManager.time_text(float(r["time"]))]
		if r.get("daily_best", false):
			txt += "\nTODAY'S BEST - it is now today's GHOST"
		if int(r.get("rank", -1)) >= 0:
			txt += "   #%d" % (int(r["rank"]) + 1)
		if r.get("ghost", false):
			txt += "\nNEW BEST - it is now your GHOST on the next run"
		_right.add_child(UiStyle.label(txt, 18, Color(0.6, 1.0, 0.6) if done else Color(1.0, 0.6, 0.5), 6))
	var plan := BossRush.daily_plan()
	var dl: Array = plan[0]
	if dl.size() >= 3:
		var names: PackedStringArray = []
		for n in dl:
			names.append(String(StoryLevels.get_level(int(n)).get("title", "?")))
		var best := BossRush.daily_best(_hero)
		_right.add_child(UiStyle.label("DAILY  %s  -  %s" % [BossRush.today(), String(plan[1])], 22, Color(0.6, 0.85, 1.0), 6))
		_right.add_child(UiStyle.label(String(BossRush.DAILY_MOD_TEXT.get(String(plan[1]), "")), 16, UiStyle.TEXT_DIM, 4))
		var nl := UiStyle.label(", ".join(names), 15, UiStyle.TEXT, 4)
		nl.autowrap_mode = TextServer.AUTOWRAP_WORD_SMART
		nl.custom_minimum_size = Vector2(440, 0)
		_right.add_child(nl)
		_right.add_child(UiStyle.label("TODAY'S BEST:  " + (StoryManager.time_text(best) if best > 0.0 else "-"), 18, Color(1.0, 0.82, 0.3), 5))
	_right.add_child(UiStyle.label("TOP %d  -  %s" % [BossRush.TOP_N, "WARRIOR" if _hero == "warrior" else "ARCHITECT"], 22, Color(1.0, 0.82, 0.3), 6))
	var list := BossRush.top(_hero)
	if list.is_empty():
		_right.add_child(UiStyle.label("No finished runs yet.", 18, UiStyle.TEXT_DIM, 5))
	for i in list.size():
		var e: Dictionary = list[i]
		_right.add_child(UiStyle.label("%2d.   %s     %d bosses     %s" % [i + 1, StoryManager.time_text(float(e["time"])), int(e["bosses"]), String(e.get("date", ""))], 18, UiStyle.TEXT, 5))


func _on_daily() -> void:
	if BossRush.start_daily(_hero):
		LoadingScreen.goto(get_tree(), StoryManager.ARENA_SCENE, "DAILY RUN  -  " + BossRush.daily_mod, BossRush.progress_text())


func _on_start() -> void:
	if BossRush.start(_hero):
		LoadingScreen.goto(get_tree(), StoryManager.ARENA_SCENE, "BOSS RUSH", BossRush.progress_text())


func _back() -> void:
	BossRush.cancel()
	get_tree().change_scene_to_file(CharacterRoster.MAIN_MENU)


func _unhandled_input(event: InputEvent) -> void:
	if event.is_action_pressed("ui_cancel") or event.is_action_pressed("pause_menu"):
		get_viewport().set_input_as_handled()
		_back()
