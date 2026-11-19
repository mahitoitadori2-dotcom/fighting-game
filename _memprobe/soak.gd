extends Node
## TEMPORARY: memory soak test (headless). Delete after use.

var _base := 0


func _ready() -> void:
	if get_parent() != get_tree().root or name != "Soak":
		var s := Node.new()
		s.set_script(get_script())
		s.name = "Soak"
		get_tree().root.add_child.call_deferred(s)
		return
	process_mode = Node.PROCESS_MODE_ALWAYS
	get_tree().create_timer(2400.0, true, false, true).timeout.connect(func() -> void: print("PROBE TIMEOUT"); get_tree().quit())
	_run.call_deferred()


func _w(s: float) -> void:
	await get_tree().create_timer(s, true, false, true).timeout


func _mem(tag: String) -> void:
	await _w(0.5)
	var mb := OS.get_static_memory_usage() / 1048576.0
	print("P %-28s mem %7.1f MB  objects %6d  resources %5d  nodes %5d  orphans %4d  music_cache %d  ach_cache %d  shots %d" % [tag, mb,
		Performance.get_monitor(Performance.OBJECT_COUNT), Performance.get_monitor(Performance.OBJECT_RESOURCE_COUNT),
		Performance.get_monitor(Performance.OBJECT_NODE_COUNT), Performance.get_monitor(Performance.OBJECT_ORPHAN_NODE_COUNT),
		SoundManager._cache.size(), AchievementCard._cache.size(), MapCatalog._shots.size()])


func _scene(path: String, secs: float, tag: String) -> void:
	get_tree().change_scene_to_file(path)
	await _w(secs)
	await _mem(tag)


func _run() -> void:
	await _mem("start")
	var musics := ["menu", "fight", "boss", "story_magma", "story_meadow", "story_forest", "story_town", "boss_storm_hand", "story_orbis", "boss_melter"]
	var fighters := ["warrior", "architect", "firelord", "enlightened", "mimic", "anti", "technician"]
	for lap in 4:
		print("P ---- lap %d ----" % (lap + 1))
		await _scene("res://scenes/MainMenu.tscn", 2.0, "main menu")
		await _scene("res://scenes/CharacterSelect.tscn", 2.0, "character select")
		await _scene("res://scenes/AchievementsMenu.tscn", 4.0, "achievements")
		await _scene("res://scenes/MapCatalogue.tscn", 6.0, "map catalogue")
		ArenaManager.p1_cpu = true
		ArenaManager.selected_arena = "test"
		CharacterRoster.selected_id = fighters[(lap * 2) % fighters.size()]
		CharacterRoster.opponent_id = fighters[(lap * 2 + 1) % fighters.size()]
		await _scene("res://Main.tscn", 15.0, "versus fight")
		ArenaManager.p1_cpu = false
		await _scene("res://scenes/StoryMenu.tscn", 3.0, "story board")
		StoryManager.autoplay = true
		StoryProgress.current_level = [6, 26, 45, 62][lap]
		await _scene(StoryManager.ARENA_SCENE, 15.0, "story level")
		StoryManager.autoplay = false
		StoryProgress.current_level = 63
		await _scene("res://scenes/DemiLand.tscn", 8.0, "demiland")
		await _scene("res://scenes/BossRushMenu.tscn", 1.5, "boss rush menu")
		for m in musics:
			SoundManager.play_music(m)
			await _w(0.1)
		await _mem("after 10 music tracks")
	print_orphan_nodes()
	get_tree().quit()