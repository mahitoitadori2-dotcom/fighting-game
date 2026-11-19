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
	return q is String and (String(q).contains("soak=1") or String(q).contains("soak=perf"))


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


# ===== PERF MODE (?soak=perf): per-scene frame stats =====
var _rec := false
var _frames: Array[float] = []
var _proc := 0.0
var _phys := 0.0
var _draws := 0.0
var _prims := 0.0
var _last_us := 0


func _process(_d: float) -> void:
	if not _rec:
		return
	var now := Time.get_ticks_usec()
	if _last_us > 0:
		_frames.append(float(now - _last_us) / 1000.0)
	_last_us = now
	_proc += Performance.get_monitor(Performance.TIME_PROCESS) * 1000.0
	_phys += Performance.get_monitor(Performance.TIME_PHYSICS_PROCESS) * 1000.0
	_draws += Performance.get_monitor(Performance.RENDER_TOTAL_DRAW_CALLS_IN_FRAME)
	_prims += Performance.get_monitor(Performance.RENDER_TOTAL_PRIMITIVES_IN_FRAME)


func _perf(path: String, secs: float, tag: String) -> void:
	get_tree().change_scene_to_file(path)
	await _w(1.5)                                   # Let it load / settle (not measured)
	_frames.clear()
	_proc = 0.0
	_phys = 0.0
	_draws = 0.0
	_prims = 0.0
	_last_us = 0
	_rec = true
	await _w(secs)
	_rec = false
	var n := maxi(_frames.size(), 1)
	var sorted := _frames.duplicate()
	sorted.sort()
	var total := 0.0
	var over33 := 0
	var over50 := 0
	for f in _frames:
		total += f
		over33 += 1 if f > 33.4 else 0
		over50 += 1 if f > 50.0 else 0
	print("PERF %-26s fps=%5.1f p95=%5.1fms max=%6.1fms >33ms=%3d >50ms=%3d proc=%5.2fms phys=%5.2fms draws=%6.0f prims=%7.0f nodes=%5d" % [tag,
		1000.0 * float(n) / maxf(total, 1.0), sorted[int(n * 0.95)] if not sorted.is_empty() else 0.0, sorted[-1] if not sorted.is_empty() else 0.0,
		over33, over50, _proc / n, _phys / n, _draws / n, _prims / n, Performance.get_monitor(Performance.OBJECT_NODE_COUNT)])


func _run_perf() -> void:
	await _w(3.0)
	await _perf("res://scenes/MainMenu.tscn", 4.0, "main menu")
	await _perf("res://scenes/CharacterSelect.tscn", 4.0, "character select")
	await _perf("res://scenes/AchievementsMenu.tscn", 4.0, "achievements")
	await _perf("res://scenes/MapCatalogue.tscn", 4.0, "map catalogue")
	await _perf("res://scenes/StoryMenu.tscn", 4.0, "story board")
	ArenaManager.p1_cpu = true
	ArenaManager.selected_arena = "test"
	for pair in [["warrior", "architect"], ["firelord", "enlightened"], ["mimic", "anti"], ["technician", "warrior"]]:
		CharacterRoster.selected_id = pair[0]
		CharacterRoster.opponent_id = pair[1]
		await _perf("res://Main.tscn", 10.0, "vs %s-%s" % [pair[0].left(5), pair[1].left(5)])
	ArenaManager.p1_cpu = false
	StoryManager.autoplay = true
	for lv in [6, 15, 26, 34, 45, 48, 50, 56, 62]:
		StoryProgress.current_level = lv
		StoryManager.boss_retry = lv                 # Straight to the boss
		await _perf(StoryManager.ARENA_SCENE, 12.0, "boss level %d" % lv)
	StoryManager.autoplay = false
	StoryProgress.current_level = 63
	await _perf("res://scenes/DemiLand.tscn", 10.0, "DemiLand")
	StoryProgress.current_level = 67
	await _perf("res://scenes/CraterLand.tscn", 10.0, "Terra Craterum")
	StoryProgress.current_level = 71
	await _perf("res://scenes/OrdLand.tscn", 10.0, "Terra Ordinariorum")
	StoryProgress.current_level = 68
	await _perf("res://scenes/CaveSlide.tscn", 8.0, "Magma Run slide")
	StoryProgress.current_level = 75
	await _perf("res://scenes/OrbisTalk.tscn", 6.0, "Orbis Terrarum")
	print("SOAK DONE")


func _run() -> void:
	var q: Variant = JavaScriptBridge.eval("window.location.search", true)
	if q is String and String(q).contains("soak=perf"):
		await _run_perf()
		return
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
