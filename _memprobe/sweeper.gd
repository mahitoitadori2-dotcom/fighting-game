extends Node
## WHOLE-GAME SWEEP: every menu, every Versus map, every opponent, every fighter, every Story level,
## every extension level, DemiLand and The Caves. The CPU plays. Per test it prints one RESULT line:
## RESULT|name|load ms|avg fps|1% low fps|worst frame ms|frames > 33 ms|max draw calls|max nodes|static MB|note
## Errors land in the log between the "### TEST" markers.

const SKIP_WARMUP := 1.0                 # Ignore the first second of a test (loading spike)

var _times: PackedFloat32Array = []
var _draw_max := 0
var _nodes_max := 0
var _t := 0.0
var _measuring := false
var _first_frame_ms := -1.0
var _start_ms := 0


func _process(delta: float) -> void:
	if not _measuring:
		return
	if _first_frame_ms < 0.0:
		_first_frame_ms = float(Time.get_ticks_msec() - _start_ms)
	_t += delta
	if _t < SKIP_WARMUP:
		return
	_times.append(delta * 1000.0)
	_draw_max = maxi(_draw_max, int(Performance.get_monitor(Performance.RENDER_TOTAL_DRAW_CALLS_IN_FRAME)))
	_nodes_max = maxi(_nodes_max, int(Performance.get_monitor(Performance.OBJECT_NODE_COUNT)))


func _wait(s: float) -> void:
	await get_tree().create_timer(s, true, false, true).timeout


## Runs one test: change scene, measure `secs`, print the RESULT line.
func _test(name: String, scene: String, secs: float) -> void:
	print("### TEST %s" % name)
	if PauseMenu.is_open:
		var pm := get_tree().root.get_node_or_null("PauseMenu")
		if pm != null:
			pm.queue_free()
	get_tree().paused = false
	Engine.time_scale = 1.0
	_times = PackedFloat32Array()
	_draw_max = 0
	_nodes_max = 0
	_t = 0.0
	_first_frame_ms = -1.0
	_start_ms = Time.get_ticks_msec()
	var err := get_tree().change_scene_to_file(scene)
	if err != OK:
		print("RESULT|%s|0|0|0|0|0|0|0|0|SCENE LOAD FAILED (%d)" % [name, err])
		return
	_measuring = true
	await _wait(secs)
	_measuring = false
	var note := ""
	var cur := get_tree().current_scene
	if cur != null and cur.scene_file_path != scene:
		note = "ended early -> %s" % cur.scene_file_path.get_file()
	_report(name, note)


func _report(name: String, note: String) -> void:
	var n := _times.size()
	if n == 0:
		print("RESULT|%s|%d|0|0|0|0|%d|%d|%d|no frames %s" % [name, int(_first_frame_ms), _draw_max, _nodes_max, int(OS.get_static_memory_usage() / 1048576), note])
		return
	var sum := 0.0
	var worst := 0.0
	var slow := 0
	for v in _times:
		sum += v
		worst = maxf(worst, v)
		if v > 33.3:
			slow += 1
	var sorted := _times.duplicate()
	sorted.sort()
	var p99: float = sorted[mini(n - 1, int(float(n) * 0.99))]
	print("RESULT|%s|%d|%.0f|%.0f|%.1f|%d|%d|%d|%d|%s" % [name, int(_first_frame_ms), 1000.0 * float(n) / sum, 1000.0 / maxf(p99, 0.001),
		worst, slow, _draw_max, _nodes_max, int(OS.get_static_memory_usage() / 1048576), note])


func _ready() -> void:
	process_mode = Node.PROCESS_MODE_ALWAYS
	DisplayServer.window_set_vsync_mode(DisplayServer.VSYNC_DISABLED)
	Engine.max_fps = 0
	StoryManager.autoplay = true                       # CPU plays Story; dialogue advances; no auto-pause
	ArenaManager.p1_cpu = true                         # Versus: AI vs AI
	DemiLand.test_steer = true
	var only := OS.get_environment("UB_SWEEP")         # Optional: run one part (menus/maps/versus/story/ext/demi)
	print("SWEEP START graphics=%s" % GraphicsSettings.NAMES[GraphicsSettings.level])
	# ---- 1. MENUS ----
	if only == "" or only == "menus":
		for sc in ["res://scenes/MainMenu.tscn", "res://scenes/CharacterSelect.tscn", "res://scenes/MatchSettings.tscn",
				"res://scenes/StoryMenu.tscn", "res://scenes/MapCatalogue.tscn", "res://scenes/AchievementsMenu.tscn", "res://scenes/PreFight.tscn"]:
			await _test("menu " + String(sc).get_file().get_basename(), sc, 4.0)
		var base_mem := int(OS.get_static_memory_usage() / 1048576)
		print("MEM after menus: %d MB" % base_mem)
	# ---- 2. EVERY VERSUS MAP (Architect vs Warrior, both CPU) ----
	if only == "" or only == "maps":
		CharacterRoster.selected_id = "architect"
		CharacterRoster.opponent_id = "warrior"
		for e in MapCatalog.entries():
			ArenaManager.selected_arena = String(e["id"])
			await _test("map " + String(e["id"]), String(e["scene"]), 4.0)
	# ---- 3. EVERY OPPONENT (incl. all 33 Story ones) + every fighter as P1 ----
	if only == "" or only == "versus":
		for e in EnemyManager.entries():
			if e.get("story", false):
				StoryProgress.seen[String(e["class"])] = true     # (in memory only)
		ArenaManager.selected_arena = "test"
		CharacterRoster.selected_id = "architect"
		for e in CharacterRoster.all():
			CharacterRoster.opponent_id = String(e["id"])
			await _test("vs " + String(e["id"]), "res://Main.tscn", 7.0)
		CharacterRoster.opponent_id = "warrior"
		for e in CharacterRoster.playable():
			CharacterRoster.selected_id = String(e["id"])
			await _test("p1 " + String(e["id"]), "res://Main.tscn", 7.0)
		CharacterRoster.selected_id = "architect"
	# ---- 4. EVERY STORY LEVEL (CPU) ----
	if only == "" or only == "story":
		for n in range(1, 63):
			StoryProgress.current_level = n
			StoryManager.boss_retry = 0
			await _test("story %d %s" % [n, String(StoryLevels.get_level(n).get("title", ""))], "res://scenes/StoryArena.tscn", 16.0)
			# Boss levels: also start right at the boss (boss intro + fight + stance)
			if String(StoryLevels.get_level(n).get("boss", "")) != "" and not (StoryLevels.get_level(n).get("waves", []) as Array).is_empty():
				StoryManager.boss_retry = n
				await _test("boss %d" % n, "res://scenes/StoryArena.tscn", 16.0)
	# ---- 5. BOSS EXTENSIONS ----
	if only == "" or only == "ext":
		for k in StoryLevels.EXT_ORDER:
			var first := int(StoryLevels.EXTENSIONS[k]["first"])
			for i in 3:
				StoryProgress.current_level = first + i
				await _test("ext %s" % StoryLevels.ext_code(first + i), "res://scenes/StoryArena.tscn", 16.0)
	# ---- 6. DEMILAND + THE CAVES ----
	if only == "" or only == "demi":
		StoryProgress.current_level = 63
		await _test("demiland", "res://scenes/DemiLand.tscn", 45.0)
		for n in [64, 65, 66]:
			StoryProgress.current_level = n
			await _test("cave %d" % n, "res://scenes/CaveSlide.tscn", 20.0)
	# ---- back to the menu: memory after everything ----
	await _test("menu MainMenu (end)", "res://scenes/MainMenu.tscn", 4.0)
	print("MEM at end: %d MB" % int(OS.get_static_memory_usage() / 1048576))
	print("SWEEP DONE")
	get_tree().quit()
