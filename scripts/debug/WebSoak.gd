class_name WebSoak
extends Node
## HIDDEN TEST MODE for the WEB build: open the game with ?soak=1 in the address and it plays
## through the whole game by itself (menus, Versus, Story levels, the open worlds, Boss Rush,
## music changes), lap after lap, logging memory to the browser console ("SOAK ..." lines).
## Used to measure phone memory in headless Chrome. Never active in a normal session.

var laps := 6


static func wanted() -> bool:
	if not OS.has_feature("web"):
		return false
	var q: Variant = JavaScriptBridge.eval("window.location.search", true)
	return q is String and String(q).contains("soak=1")


func _ready() -> void:
	process_mode = Node.PROCESS_MODE_ALWAYS
	_run.call_deferred()


func _w(s: float) -> void:
	await get_tree().create_timer(s, true, false, true).timeout


func _log(tag: String) -> void:
	await _w(0.5)
	var js: Variant = JavaScriptBridge.eval("(performance.memory ? performance.memory.usedJSHeapSize : 0)", true)
	print("SOAK %s | wasm_static_mb=%.1f js_heap_mb=%.1f objects=%d nodes=%d resources=%d" % [tag,
		OS.get_static_memory_usage() / 1048576.0, float(js if js != null else 0) / 1048576.0,
		Performance.get_monitor(Performance.OBJECT_COUNT), Performance.get_monitor(Performance.OBJECT_NODE_COUNT),
		Performance.get_monitor(Performance.OBJECT_RESOURCE_COUNT)])


func _scene(path: String, secs: float, tag: String) -> void:
	get_tree().change_scene_to_file(path)
	await _w(secs)
	await _log(tag)


func _run() -> void:
	await _w(3.0)
	await _log("start")
	var fighters := ["warrior", "architect", "firelord", "enlightened", "mimic", "anti", "technician"]
	var levels := [6, 26, 45, 62, 50, 36]
	for lap in laps:
		print("SOAK ---- lap %d ----" % (lap + 1))
		await _scene("res://scenes/MainMenu.tscn", 3.0, "L%d main menu" % (lap + 1))
		await _scene("res://scenes/CharacterSelect.tscn", 3.0, "L%d character select" % (lap + 1))
		await _scene("res://scenes/AchievementsMenu.tscn", 5.0, "L%d achievements" % (lap + 1))
		await _scene("res://scenes/MapCatalogue.tscn", 8.0, "L%d map catalogue" % (lap + 1))
		ArenaManager.p1_cpu = true
		ArenaManager.selected_arena = "test"
		CharacterRoster.selected_id = fighters[(lap * 2) % fighters.size()]
		CharacterRoster.opponent_id = fighters[(lap * 2 + 1) % fighters.size()]
		await _scene("res://Main.tscn", 25.0, "L%d versus" % (lap + 1))
		ArenaManager.p1_cpu = false
		await _scene("res://scenes/StoryMenu.tscn", 4.0, "L%d story board" % (lap + 1))
		StoryManager.autoplay = true
		StoryProgress.current_level = levels[lap % levels.size()]
		await _scene(StoryManager.ARENA_SCENE, 25.0, "L%d story level %d" % [lap + 1, levels[lap % levels.size()]])
		StoryManager.autoplay = false
		StoryProgress.current_level = [63, 67, 71][lap % 3]
		var world: String = ["res://scenes/DemiLand.tscn", "res://scenes/CraterLand.tscn", "res://scenes/OrdLand.tscn"][lap % 3]
		await _scene(world, 15.0, "L%d open world" % (lap + 1))
		await _scene("res://scenes/BossRushMenu.tscn", 2.0, "L%d boss rush menu" % (lap + 1))
	print("SOAK DONE")
