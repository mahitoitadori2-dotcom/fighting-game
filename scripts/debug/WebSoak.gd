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
	return q is String and (String(q).contains("soak=1") or String(q).contains("soak=perf") or String(q).contains("soak=mobile") or String(q).contains("soak=hunt") or String(q).contains("soak=madui") or String(q).contains("soak=netguest") or String(q).contains("soak=shots") or String(q).contains("soak=looks") or String(q).contains("soak=truehunt"))


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
var _spikes: Array = []                 # [frame ms, proc ms, phys ms, draws] of slow frames


func _process(_d: float) -> void:
	if not _rec:
		return
	var now := Time.get_ticks_usec()
	if _last_us > 0:
		var ms := float(now - _last_us) / 1000.0
		_frames.append(ms)
		if ms > 50.0:
			_spikes.append([ms, Performance.get_monitor(Performance.TIME_PROCESS) * 1000.0, Performance.get_monitor(Performance.TIME_PHYSICS_PROCESS) * 1000.0, Performance.get_monitor(Performance.RENDER_TOTAL_DRAW_CALLS_IN_FRAME)])
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
	_spikes.clear()
	_rec = true
	await _w(secs)
	_rec = false
	_perf_report(tag)


func _perf_report(tag: String) -> void:
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
	_spikes.sort_custom(func(a: Array, b: Array) -> bool: return a[0] > b[0])
	for sp in _spikes.slice(0, 3):
		print("PERF    spike %.0f ms: game code %.1f ms, physics %.1f ms, draws %d -> %s" % [sp[0], sp[1], sp[2], sp[3], "RENDER / browser" if sp[1] + sp[2] < sp[0] * 0.5 else "GAME CODE"])


## ?soak=perfth: THE TRUE HUNT only - disaster levels with ledges, and the Monstrosity at a full crowd.
func _run_perf_th() -> void:
	await _w(3.0)
	StoryProgress.load_progress()
	StoryProgress.unlocked_level = 138
	StoryManager.autoplay = true
	StoryProgress.current_level = 82
	StoryManager.boss_retry = 0
	await _perf(StoryManager.ARENA_SCENE, 12.0, "hunt 82 (old, compare)")
	for lv in [113, 116, 119, 122]:
		StoryProgress.current_level = lv
		StoryManager.boss_retry = 0
		await _perf(StoryManager.ARENA_SCENE, 12.0, "true hunt %d" % lv)
	# The Monstrosity at its worst: break it down until MAX_ALIVE golems are out, then measure
	StoryProgress.current_level = 138
	StoryManager.boss_retry = 138
	get_tree().change_scene_to_file(StoryManager.ARENA_SCENE)
	await _w(1.0)
	await _wait_for(func() -> bool: return CombatManager.fight_active and not get_tree().paused, 40.0)
	for i in 80:
		var alive := 0
		var biggest: NightmareMonstrosity = null
		for f in get_tree().get_nodes_in_group("fighters"):
			var g := f as NightmareMonstrosity
			if g != null and not g.is_dead:
				alive += 1
				if biggest == null or g.gen < biggest.gen:
					biggest = g
		if alive >= NightmareMonstrosity.MAX_ALIVE or biggest == null:
			break
		biggest.take_damage(99999)
		await _w(0.25)
	await _w(1.0)
	_frames.clear()
	_proc = 0.0
	_phys = 0.0
	_draws = 0.0
	_prims = 0.0
	_last_us = 0
	_spikes.clear()
	_rec = true
	await _w(12.0)
	_rec = false
	var golems := get_tree().get_nodes_in_group("fighters").filter(func(f: Node) -> bool: return f is NightmareMonstrosity)
	var dead := golems.filter(func(f: Node) -> bool: return (f as NightmareMonstrosity).is_dead).size()
	_perf_report("crowd (%d alive, %d dead kept)" % [golems.size() - dead, dead])
	print("PERF graphics level=%d (0 POTATO, 1 FAST, 2 REGULAR, 3 REAL)" % GraphicsSettings.level)
	var kinds := {}
	for nd in get_tree().current_scene.find_children("*", "", true, false):
		var k := String(nd.get_script().get_global_name()) if nd.get_script() != null and String(nd.get_script().get_global_name()) != "" else nd.get_class()
		kinds[k] = int(kinds.get(k, 0)) + 1
	var top := kinds.keys()
	top.sort_custom(func(a: String, b: String) -> bool: return int(kinds[a]) > int(kinds[b]))
	print("PERF nodes by kind: %s" % ", ".join(top.slice(0, 14).map(func(k: String) -> String: return "%s=%d" % [k, kinds[k]])))
	StoryManager.autoplay = false
	print("SOAK DONE")


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
	for lv in [82, 86, 95, 100, 110]:                    # The Hunt of a Nightmare
		StoryProgress.current_level = lv
		StoryManager.boss_retry = lv if lv != 82 else 0
		await _perf(StoryManager.ARENA_SCENE, 12.0, "hunt %d" % lv)
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


# ===== MOBILE UI MODE (?soak=mobile): a phone test driven from OUTSIDE by real touches =====
# The test tool taps / swipes the screen. This only sets the scenes up and REPORTS: where to tap
# ("MOBILE target <name> <x> <y>" in device pixels) and what the game sees ("MOBILE ..." lines).
func _target(tag: String, base_pos: Vector2) -> void:
	var p := get_viewport().get_final_transform() * base_pos
	print("MOBILE target %s %d %d" % [tag, int(p.x), int(p.y)])


func _ctl_target(tag: String, c: Control) -> void:
	_target(tag, c.get_global_rect().get_center())


func _find_button(root: Node, text: String) -> Button:
	for b in root.find_children("*", "Button", true, false):
		if (b as Button).text == text and (b as Button).is_visible_in_tree():
			return b as Button
	return null


func _wait_for(cond: Callable, secs: float) -> bool:
	var t := 0.0
	while t < secs:
		if cond.call():
			return true
		await _w(0.2)
		t += 0.2
	return false


func _run_mobile() -> void:
	await _run_mobile_inner()


## ?soak=shots: a few backdrops on screen (screenshots by the driver) - for checking how maps look.
func _run_shots() -> void:
	await _w(2.0)
	StoryManager.autoplay = true
	for lv in [6, 26, 48, 62]:
		StoryProgress.current_level = lv
		StoryManager.boss_retry = lv
		get_tree().change_scene_to_file(StoryManager.ARENA_SCENE)
		await _w(7.0)
		print("MOBILE shot bg_%d" % lv)
		await _w(0.5)
	StoryManager.autoplay = false
	StoryProgress.current_level = 63
	get_tree().change_scene_to_file("res://scenes/DemiLand.tscn")
	await _w(8.0)
	print("MOBILE shot bg_demi")
	await _w(0.5)
	print("MOBILE done")


## ?soak=netguest&code=XXXXX&server=ws://...: the WEB build joins an online room as the guest (cross-play test).
func _run_netguest(q: String) -> void:
	await _w(2.0)
	var code := ""
	var server := NetLink.DEFAULT_URL
	for part in q.trim_prefix("?").split("&"):
		if part.begins_with("code="):
			code = part.trim_prefix("code=")
		elif part.begins_with("server="):
			server = part.trim_prefix("server=").uri_decode()
	CharacterRoster.selected_id = "architect"
	var link := NetLink.get_link()
	link.connect_and(server, func() -> void: link.join_room(code))
	await _wait_for(func() -> bool: return NetLink.peer_here, 15.0)
	print("MOBILE web guest joined=%s mode=%s" % [NetLink.peer_here, NetLink.mode])
	await _wait_for(func() -> bool: return get_tree().get_first_node_in_group("net_guest") != null, 20.0)
	print("MOBILE web guest sees the host's fight=%s" % (get_tree().get_first_node_in_group("net_guest") != null))
	await _w(3.0)
	Input.action_press("move_left")
	await _w(1.2)
	Input.action_release("move_left")
	for i in 8:
		Input.action_press("punch")
		await _w(0.25)
		Input.action_release("punch")
		await _w(0.25)
	print("MOBILE shot netguest")
	await _w(1.0)
	var am := get_tree().get_first_node_in_group("arena_manager") as ArenaManager
	print("MOBILE web guest: P2 puppet at %s  P1 hp %s" % [str(am.p2.global_position.round()) if am and am.p2 else "?", str(am.p1.hp) if am and am.p1 else "?"])
	print("MOBILE done")


## ?soak=madui: the XANXXE puzzles, the ghost and Madness' presence on screen (screenshots by the driver).
func _run_madui() -> void:
	await _w(2.5)
	var xp := XanxxePanel.open(get_tree())
	await _w(1.0)
	for i in 3:
		xp._select(i)
		await _w(2.0 if i == 0 else 1.0)
		print("MOBILE shot puzzle_%d" % i)
		await _w(0.3)
		for c in xp.get_children():
			if c is XanxxePuzzle:
				c.queue_free()
		await _w(0.4)
	xp.queue_free()
	Madness.unlock()
	await _w(2.0)
	var mp := get_tree().root.get_node_or_null("MadnessPresence") as MadnessPresence
	if mp != null:
		mp._next_msg = 0.0
		mp._next_ctl = 0.0
		await _w(1.5)
		print("MOBILE shot presence")
	GhostRefusal.open(get_tree())
	await _w(3.6)
	print("MOBILE shot ghost")
	await _w(4.0)
	Madness.unlocked = false
	Madness.save_data()
	print("MOBILE done")


## ?soak=hunt: THE HUNT OF A NIGHTMARE picture check - each map + each boss on screen (screenshots by the driver).
## ?soak=truehunt: THE TRUE HUNT picture check - disasters + ledges on a few maps, the Monstrosity
## splitting, and the Nightmare Lord's offer (the Volcano Slave path and the goblin path).
func _run_truehunt() -> void:
	await _w(2.0)
	StoryProgress.load_progress()
	StoryProgress.unlocked_level = 138
	StoryManager.autoplay = true
	for n in [111, 113, 116, 119, 122]:
		StoryProgress.current_level = n
		StoryManager.boss_retry = 0
		get_tree().change_scene_to_file(StoryManager.ARENA_SCENE)
		await _w(1.0)
		await _wait_for(func() -> bool: return CombatManager.fight_active and not get_tree().paused, 40.0)
		await _w(6.0)
		print("MOBILE shot th_%d" % n)
		await _w(2.6)
		print("MOBILE shot th_%db" % n)
		await _w(1.0)
	for path in ["slave", "goblins"]:
		NightmareOffer.test_path = path
		StoryProgress.current_level = 138
		StoryManager.boss_retry = 138
		get_tree().change_scene_to_file(StoryManager.ARENA_SCENE)
		await _w(1.0)
		await _wait_for(func() -> bool: return CombatManager.fight_active and not get_tree().paused, 40.0)
		await _w(2.0)
		if path == "slave":
			print("MOBILE shot th_boss")
		var split_shot := false
		for i in 900:                                     # Kill golems one by one until the offer starts
			await _w(0.25)
			var m := get_tree().get_first_node_in_group("story_manager") as StoryManager
			if m != null and m.boss != null and NightmareMonstrosity.remaining() == 0 and i > 20:
				break
			if m == null or not CombatManager.fight_active:
				continue
			var alive := 0
			for f in get_tree().get_nodes_in_group("fighters"):
				var g := f as NightmareMonstrosity
				if g != null and not g.is_dead:
					alive += 1
					if alive == 1:
						g.take_damage(99999)
			if path == "slave" and not split_shot and alive >= 6:
				split_shot = true
				await _w(0.6)
				print("MOBILE shot th_split")
			if alive == 0 and NightmareMonstrosity.remaining() == 0:
				break
		await _w(12.0)                                    # The death cutscene, then he walks in
		print("MOBILE shot th_offer_%s" % path)
		var t := 0.0
		while t < 120.0:                                  # Wait for the outcome scene (after the lore)
			await _w(0.5)
			t += 0.5
			var m2 := get_tree().get_first_node_in_group("story_manager") as StoryManager
			if m2 == null:
				break
			var lt := ""
			for b in get_tree().current_scene.get_children():
				if not (b is DialogueBox):
					continue
				var ln: Array = (b as DialogueBox).lines
				var i: int = (b as DialogueBox).get("_i")
				if i >= 0 and i < ln.size():
					lt = String(ln[i][1])
			if lt.begins_with("Slow footsteps") or lt.begins_with("Goblins?!"):
				await _w(2.0)
				print("MOBILE shot th_outcome_%s" % path)
				break
		await _w(6.0)
		print("MOBILE shot th_end_%s" % path)
		await _w(4.0)
	NightmareOffer.test_path = ""
	StoryManager.autoplay = false
	print("MOBILE done")


## ?soak=looks: the three OUTLINE families on screen (buttons / a notification / a dialogue choice).
func _run_looks() -> void:
	await _w(2.0)
	get_tree().change_scene_to_file("res://scenes/MainMenu.tscn")
	await _w(2.5)
	AchievementToast.show_achievement(Achievements.get_def(Achievements.ULTIMATE))
	Daily._toast("+20 MARKS")
	await _w(1.2)
	print("MOBILE shot notice")
	await _w(4.0)
	DialogueBox.play(get_tree().current_scene, [["warrior", "Which way now?", ["LEFT PATH", "RIGHT PATH"]]])
	await _w(3.5)
	print("MOBILE shot dialogue")
	await _w(1.5)
	get_tree().paused = false
	# Models + attack wind-up (2026-11-24)
	ArenaManager.p1_cpu = true
	ArenaManager.selected_arena = "test"
	CharacterRoster.selected_id = "warrior"
	CharacterRoster.opponent_id = "technician"
	get_tree().change_scene_to_file("res://Main.tscn")
	await _w(2.0)
	print("MOBILE shot models")
	await _w(1.0)
	var shots := 0
	for i in 1200:
		await get_tree().physics_frame
		for f in get_tree().get_nodes_in_group("fighters"):
			if f is Fighter and (f as Fighter).startup_progress() > 0.8 and shots < 2:
				Engine.time_scale = 0.0
				print("MOBILE shot windup_%d" % shots)
				await _w(1.2)
				Engine.time_scale = 1.0
				shots += 1
				await _w(1.0)
				break
		if shots >= 2:
			break
	print("MOBILE done")


func _run_hunt() -> void:
	await _w(2.0)
	StoryProgress.load_progress()
	StoryManager.autoplay = true
	for n in [82, 93, 86, 90, 95, 96, 100, 101, 110]:
		StoryProgress.unlocked_level = maxi(StoryProgress.unlocked_level, n)
		StoryProgress.current_level = n
		var has_boss := String(StoryLevels.get_level(n).get("boss", "")) != ""
		StoryManager.boss_retry = n if has_boss and not (StoryLevels.get_level(n).get("waves", []) as Array).is_empty() else 0
		get_tree().change_scene_to_file(StoryManager.ARENA_SCENE)
		await _w(9.0 if has_boss else 6.0)
		print("MOBILE shot hunt_%d" % n)
		await _w(4.0 if n == 95 else 1.0)
		if n == 95:
			print("MOBILE shot hunt_95b")
		await _w(1.0)
	StoryManager.autoplay = false
	print("MOBILE done")


## Solves a XANXXE puzzle the way a player does: real taps on its pieces.
func _solve_by_taps(pz: XanxxePuzzle) -> void:
	match pz.kind:
		"sequence":
			while is_instance_valid(pz) and pz._show_i >= 0:
				await _w(0.3)
			for g in pz._seq.duplicate():
				_ctl_target("PIECE", pz._btns[g])
				await _w(1.0)
		"infect":
			var start: Array[bool] = pz._cells.duplicate()
			for mask in 512:
				var cells: Array[bool] = start.duplicate()
				for i in 9:
					if mask & (1 << i):
						var r := floori(i / 3.0)
						var c := i % 3
						for d: Vector2i in [Vector2i(0, 0), Vector2i(1, 0), Vector2i(-1, 0), Vector2i(0, 1), Vector2i(0, -1)]:
							if r + d.y >= 0 and r + d.y < 3 and c + d.x >= 0 and c + d.x < 3:
								cells[(r + d.y) * 3 + c + d.x] = not cells[(r + d.y) * 3 + c + d.x]
				if not (false in cells):
					for i in 9:
						if mask & (1 << i):
							_ctl_target("PIECE", pz._btns[i])
							await _w(1.0)
					return
		"align":
			for i in 3:
				var n := (4 - pz._dial[i]) % 4
				for k in n:
					_ctl_target("PIECE", pz._btns[i])
					await _w(1.0)


## The XANXXE code typed in the CODE box -> the red panel: tap its 3 items -> corruption -> Madness.
func _mobile_xanxxe() -> void:
	await _w(2.0)
	var code := _find_button(get_tree().current_scene, "CODE")
	if code == null:
		print("MOBILE xanxxe: no CODE button")
		return
	_ctl_target("CODE", code)
	if not await _wait_for(func() -> bool: return get_tree().current_scene.find_children("*", "CodePanel", true, false).size() > 0, 15.0):
		return
	var cp := get_tree().current_scene.find_children("*", "CodePanel", true, false)[0] as CodePanel
	_ctl_target("CODEFIELD", cp._edit)
	if not await _wait_for(func() -> bool: return get_tree().root.get_node_or_null("XanxxePanel") != null, 20.0):
		print("MOBILE xanxxe panel: NOT OPENED")
		return
	await _w(0.8)
	print("MOBILE shot xanxxe")
	var xp := get_tree().root.get_node_or_null("XanxxePanel") as XanxxePanel
	for b in xp._buttons:                                       # Each line opens a PUZZLE: solve it with taps
		_ctl_target("XITEM", b)
		await _w(1.4)
		var pz: XanxxePuzzle = null
		for c in xp.get_children():
			if c is XanxxePuzzle:
				pz = c
		if pz == null:
			print("MOBILE xanxxe: no puzzle opened")
			continue
		var kind := pz.kind
		print("MOBILE puzzle %s open" % kind)
		await _solve_by_taps(pz)
		await _w(1.5)
		print("MOBILE puzzle %s solved=%s" % [kind, not is_instance_valid(pz)])
	await _w(4.0)
	print("MOBILE shot xanxxe_corrupt")
	await _wait_for(func() -> bool: return Madness.unlocked, 15.0)
	print("MOBILE xanxxe -> madness unlocked=%s" % Madness.unlocked)


## The Story board's STORY | MADNESS switch -> the Madness board -> tap level 1 -> it plays.
func _mobile_madness() -> void:
	get_tree().change_scene_to_file(StoryManager.STORY_MENU)
	await _w(3.0)
	var sw := _find_button(get_tree().current_scene, "MADNESS")
	print("MOBILE madness switch on the Story board=%s" % (sw != null))
	if sw == null:
		return
	_ctl_target("MADSWITCH", sw)
	if not await _wait_for(func() -> bool: return get_tree().current_scene != null and get_tree().current_scene.scene_file_path == Madness.BOARD_SCENE, 15.0):
		print("MOBILE madness board: NOT OPENED")
		return
	await _w(1.5)
	print("MOBILE shot madness_board")
	var tiles: Array = get_tree().current_scene.get("_tiles")
	_ctl_target("MADLEVEL1", tiles[0])
	var ok: bool = await _wait_for(func() -> bool:
		var sm := get_tree().get_first_node_in_group("story_manager") as StoryManager
		return sm != null and sm.level_number == Madness.FIRST, 20.0)
	await _w(5.0)
	var tinted := false
	for f in get_tree().get_nodes_in_group("fighters"):
		if f is BaseEnemy and (f as BaseEnemy).pixel_group != null and (f as BaseEnemy).pixel_group.modulate == Madness.TINT:
			tinted = true
	print("MOBILE madness level 1 playing=%s  enemies black+red=%s  dark sound=%s  glitch filter=%s" % [ok, tinted,
		SoundManager.madness, get_tree().get_nodes_in_group("madness_filter").size() > 0])
	print("MOBILE shot madness_level")
	await _w(1.0)


## More console commands, each typed through the phone's input box.
func _mobile_console_cmds(rc: RedConsole) -> void:
	var me: Fighter = null
	for f in get_tree().get_nodes_in_group("fighters"):
		if (f as Fighter).slot == 1:
			me = f
	print("MOBILE console under Madness refused 'hi'=%s" % (is_instance_valid(rc) and rc._log.get_parsed_text().contains("XANXXE>")))
	for cmd in ["normalize", "#s001", "#s002", "#s003", "normalize"]:
		if not is_instance_valid(rc):
			return
		var seen := rc._log.get_parsed_text().count("> " + cmd)          # (Wait for THIS one: normalize runs twice)
		_ctl_target("CONSOLEFIELD", rc._edit)
		await _wait_for(func() -> bool: return is_instance_valid(rc) and rc._log.get_parsed_text().count("> " + cmd) > seen, 20.0)
		await _w(0.15)
		print("MOBILE %s sounds playing: %s" % [cmd, ", ".join(_playing_sounds())])
		await _w(0.35)
		match cmd:
			"#s001":
				print("MOBILE #s001 black ghost=%s" % (me is ControlledFighter and (me as ControlledFighter).console_onslaught))
			"#s002":
				print("MOBILE #s002 clones=%d" % get_tree().get_nodes_in_group("console_clone").size())
			"#s003":
				print("MOBILE #s003 blind=%s" % (get_tree().root.get_node_or_null("ConsoleBlind") != null))
				print("MOBILE shot blind")
			"normalize":
				print("MOBILE after typing 5 commands: pause menu popped up by itself=%s" % PauseMenu.is_open)
				print("MOBILE normalize: clones=%d blind=%s madness=%s" % [get_tree().get_nodes_in_group("console_clone").size(),
					get_tree().root.get_node_or_null("ConsoleBlind") != null, Madness.unlocked])
	if is_instance_valid(rc):
		_ctl_target("CONSOLEFIELD", rc._edit)                     # 'rotor': the picture
		if await _wait_for(func() -> bool: return get_tree().root.get_node_or_null("RotorPicture") != null, 20.0):
			await _w(1.0)
			print("MOBILE rotor picture up=true")
			print("MOBILE shot rotor")
			await _w(3.0)


## Names of the sound files playing right now (SoundManager's players), e.g. "console_gunshot".
func _playing_sounds() -> PackedStringArray:
	var out: PackedStringArray = []
	for n in SoundManager.find_children("*", "AudioStreamPlayer", true, false):
		var ap := n as AudioStreamPlayer
		if ap.playing and ap.stream != null and ap.stream.resource_path != "":
			out.append(ap.stream.resource_path.get_file().get_basename())
	return out


## 2026-11-23 features, by taps: DAILY (+ buying a palette), PLAY ONLINE, Boss Rush DAILY RUN.
func _mobile_new_menus() -> void:
	get_tree().change_scene_to_file(CharacterRoster.MAIN_MENU)
	await _w(3.0)
	Daily.load_data()
	Daily.marks = 200
	Daily.save_data()
	var db := _find_button(get_tree().current_scene, "DAILY")
	print("MOBILE daily button=%s" % (db != null))
	if db != null:
		_ctl_target("DAILY", db)
		if await _wait_for(func() -> bool: return get_tree().current_scene.scene_file_path.ends_with("DailyMenu.tscn"), 10.0):
			await _w(1.5)
			print("MOBILE shot daily")
			var buy: Button = null
			for b in get_tree().current_scene.find_children("*", "Button", true, false):
				if (b as Button).text.begins_with("CRIMSON"):
					buy = b
			if buy != null:
				_ctl_target("BUY", buy)
				await _wait_for(func() -> bool: return Daily.owned.has("crimson"), 8.0)
			print("MOBILE daily shop: bought crimson=%s marks left=%d" % [Daily.owned.has("crimson"), Daily.marks])
			_ctl_target("BACK", _find_button(get_tree().current_scene, "BACK"))
			await _wait_for(func() -> bool: return get_tree().current_scene.scene_file_path == CharacterRoster.MAIN_MENU, 8.0)
	await _w(1.5)
	var ob := _find_button(get_tree().current_scene, "PLAY ONLINE")
	print("MOBILE play online button=%s" % (ob != null))
	if ob != null:
		_ctl_target("ONLINE", ob)
		var ok: bool = await _wait_for(func() -> bool: return get_tree().current_scene.scene_file_path.ends_with("OnlineMenu.tscn"), 10.0)
		await _w(1.5)
		print("MOBILE online menu open=%s  quickplay button=%s" % [ok, _find_button(get_tree().current_scene, "QUICKPLAY VERSUS") != null])
		print("MOBILE shot online")
		_ctl_target("BACK", _find_button(get_tree().current_scene, "BACK"))
		await _wait_for(func() -> bool: return get_tree().current_scene.scene_file_path == CharacterRoster.MAIN_MENU, 8.0)
	await _w(1.5)
	var rb := _find_button(get_tree().current_scene, "BOSS RUSH")
	if rb != null:
		_ctl_target("RUSH", rb)
		await _wait_for(func() -> bool: return get_tree().current_scene.scene_file_path == BossRush.MENU_SCENE, 10.0)
		await _w(1.5)
		print("MOBILE boss rush DAILY RUN button=%s" % (_find_button(get_tree().current_scene, "DAILY RUN") != null))
		print("MOBILE shot rush")


## A weapon pickup used with the touch ATTACK button, then PHOTO MODE from the pause menu.
func _mobile_weapons_photo() -> void:
	ArenaManager.p1_cpu = false
	ArenaManager.selected_arena = "test"
	CharacterRoster.selected_id = "warrior"
	CharacterRoster.opponent_id = "architect"
	get_tree().change_scene_to_file("res://Main.tscn")
	await _w(4.0)
	var am := get_tree().get_first_node_in_group("arena_manager") as ArenaManager
	var tc := get_tree().current_scene.find_child("TouchControls", true, false)
	if am == null or tc == null:
		print("MOBILE weapons: no fight / no touch controls")
		return
	var pk := WeaponDrops.Pickup.new()
	pk.weapon = "HALBERD"
	am.add_child(pk)
	pk.floor_y = am.p1.global_position.y
	pk.global_position = Vector2(am.p1.global_position.x, pk.floor_y - 30.0)
	await _w(1.2)
	var held := am.p1.get_node_or_null("HeldWeapon")
	print("MOBILE weapon picked up=%s" % (held != null))
	print("MOBILE shot weapon")
	var atk := Vector2.ZERO
	for btn in tc.get("_buttons"):
		if String(btn["action"]) == "punch":
			atk = btn["center"]
	for i in 5:
		_target("ATTACKBTN", atk)
		await _w(1.3)
	print("MOBILE after 5 ATK taps: weapon thrown (hand empty)=%s" % (am.p1.get_node_or_null("HeldWeapon") == null))
	for btn in tc.get("_buttons"):
		if String(btn["id"]) == "menu":
			_target("PAUSE", btn["center"])
	if not await _wait_for(func() -> bool: return PauseMenu.is_open, 10.0):
		print("MOBILE photo: pause menu did not open")
		return
	await _w(0.6)
	var ph := _find_button(get_tree().root, "PHOTO")
	print("MOBILE pause PHOTO button=%s" % (ph != null))
	if ph == null:
		return
	_ctl_target("PHOTO", ph)
	if not await _wait_for(func() -> bool: return get_tree().root.get_node_or_null("PhotoMode") != null, 10.0):
		print("MOBILE photo mode: NOT OPENED")
		return
	await _w(0.8)
	var pm := get_tree().root.get_node_or_null("PhotoMode") as PhotoMode
	var cam := get_viewport().get_camera_2d()
	var z0 := cam.zoom.x
	_ctl_target("ZOOMIN", _find_button(pm, "+"))
	await _w(1.2)
	_ctl_target("HUD", _find_button(pm, "HUD"))
	await _w(1.2)
	print("MOBILE photo mode: zoom %.2f -> %.2f  hud hidden=%s" % [z0, cam.zoom.x, pm._hud_hidden])
	print("MOBILE shot photo")
	_ctl_target("SAVE", _find_button(pm, "SAVE"))
	await _w(2.0)
	print("MOBILE photo saved=%s" % Achievements.is_unlocked("photo_first"))
	_ctl_target("EXIT", _find_button(pm, "EXIT"))
	await _w(1.5)
	print("MOBILE photo mode closed=%s game running=%s" % [get_tree().root.get_node_or_null("PhotoMode") == null, not get_tree().paused])


## Rotor Mode on a phone: P1 is Rotor, the touch ATTACK button = Bite.
func _mobile_rotor_mode() -> void:
	SecretCodes.toggle("rotor_mode", get_tree())
	ArenaManager.p1_cpu = false
	CharacterRoster.opponent_id = ""
	get_tree().change_scene_to_file("res://Main.tscn")
	await _w(4.0)
	var am := get_tree().get_first_node_in_group("arena_manager") as ArenaManager
	var tc := get_tree().current_scene.find_child("TouchControls", true, false)
	print("MOBILE rotor mode: P1 is Rotor=%s" % (am != null and am.p1 is Rotor))
	if tc != null and am != null and am.p1 is Rotor:
		for btn in tc.get("_buttons"):
			if String(btn["action"]) == "punch":
				_target("ATTACKBTN", btn["center"])
		var bit: bool = await _wait_for(func() -> bool: return (am.p1 as BaseEnemy).current != null and (am.p1 as BaseEnemy).current == (am.p1 as BaseEnemy).patterns[0], 10.0)
		print("MOBILE rotor mode: touch ATTACK -> Bite=%s" % bit)
	SecretCodes.toggle("rotor_mode", get_tree())


## The Abandoned Town (level 81) loads on a phone, through the loading screen.
func _mobile_town() -> void:
	StoryProgress.current_level = 81
	LoadingScreen.goto(get_tree(), "res://scenes/TownLand.tscn", "LEVEL 81", "THE ABANDONED TOWN")
	var ok: bool = await _wait_for(func() -> bool: return get_tree().current_scene != null and get_tree().current_scene.scene_file_path.ends_with("TownLand.tscn"), 30.0)
	await _w(6.0)
	var people := 0
	if ok:
		for n in [get_tree().current_scene] + get_tree().current_scene.find_children("*", "", true, false):
			var pp: Variant = n.get("_people")
			if pp is Dictionary:
				people = (pp as Dictionary).size()
				break
	print("MOBILE abandoned town loaded=%s  people=%d  pause menu popped up by itself=%s" % [ok, people, PauseMenu.is_open])
	if not ok:
		return
	print("MOBILE shot town")
	await _w(1.0)


func _run_mobile_inner() -> void:
	await _w(2.5)
	# 0) MAIN MENU: the CODE button -> the code window -> type B0gT3ster (the browser's input)
	var code := _find_button(get_tree().current_scene, "CODE")
	print("MOBILE menu ready  code_button=%s" % (code != null))
	if code != null:
		_ctl_target("CODE", code)
		var opened: bool = await _wait_for(func() -> bool: return get_tree().current_scene.find_children("*", "CodePanel", true, false).size() > 0, 15.0)
		if opened:
			var cp := get_tree().current_scene.find_children("*", "CodePanel", true, false)[0] as CodePanel
			_ctl_target("CODEFIELD", cp._edit)
			await _wait_for(func() -> bool: return SecretCodes.bug_tester, 20.0)
			print("MOBILE code typed -> bug tester %s" % ("ON" if SecretCodes.bug_tester else "OFF"))
			await _w(1.0)
			if is_instance_valid(cp) and cp._close.visible:
				_ctl_target("CLOSE", cp._close)                        # The player taps CLOSE (a tap, not a key)
				var shut: bool = await _wait_for(func() -> bool: return get_tree().current_scene.find_children("*", "CodePanel", true, false).is_empty(), 10.0)
				print("MOBILE code window CLOSE tapped -> closed=%s" % shut)
			if SecretCodes.bug_tester:
				SecretCodes.toggle("bug_tester", get_tree())
	await _mobile_xanxxe()
	await _mobile_madness()
	# 1) VERSUS vs the Dummy with touch controls: tap II -> pause menu -> CONSOLE -> type 'hi'
	ArenaManager.p1_cpu = false
	ArenaManager.selected_arena = "test"
	CharacterRoster.selected_id = "warrior"
	CharacterRoster.opponent_id = ""
	get_tree().change_scene_to_file("res://Main.tscn")
	await _w(4.0)
	var tc := get_tree().current_scene.find_child("TouchControls", true, false)
	print("MOBILE fight ready  touch_controls=%s" % (tc != null))
	if tc != null:
		for btn in tc.get("_buttons"):
			if String(btn["id"]) == "menu":
				print("MOBILE pause button radius=%.0f" % float(btn["r"]))
				_target("PAUSE", btn["center"])
		if await _wait_for(func() -> bool: return PauseMenu.is_open, 15.0):
			print("MOBILE pause menu open")
			await _w(0.6)
			var con := _find_button(get_tree().root, "CONSOLE")
			print("MOBILE console button=%s" % (con != null))
			if con != null:
				_ctl_target("CONSOLEBTN", con)
				if await _wait_for(func() -> bool: return get_tree().root.get_node_or_null("RedConsole") != null, 15.0):
					print("MOBILE console open")
					await _w(0.4)
					var rc := get_tree().root.get_node_or_null("RedConsole") as RedConsole
					_ctl_target("CONSOLEFIELD", rc._edit)
					await _wait_for(func() -> bool: return is_instance_valid(rc) and rc._log.get_parsed_text().contains("> hi"), 20.0)
					await _mobile_console_cmds(rc)
					if is_instance_valid(rc):
						print("MOBILE console log: " + rc._log.get_parsed_text().strip_edges().replace("\n", " | "))
						rc.close()
	await _mobile_rotor_mode()
	await _mobile_town()
	await _mobile_new_menus()
	await _mobile_weapons_photo()
	# 2) THE RESULTS SCREEN: CPU vs CPU, the opponent knocked out -> swipe up -> does it scroll?
	ArenaManager.p1_cpu = true
	CharacterRoster.opponent_id = "architect"
	get_tree().change_scene_to_file("res://Main.tscn")
	await _w(3.0)
	for i in 30:
		for f in get_tree().get_nodes_in_group("fighters"):
			if f is Fighter and (f as Fighter).slot == 2 and not (f as Fighter).is_dead:
				(f as Fighter).take_damage(9999)
		await _w(0.5)
		if get_tree().current_scene.find_child("ResultsScroll", true, false) != null:
			break
	ArenaManager.p1_cpu = false
	var sc := get_tree().current_scene.find_child("ResultsScroll", true, false) as ScrollContainer
	if sc == null:
		print("MOBILE results: NONE")
		return
	await _w(1.5)
	var bar := sc.get_v_scroll_bar()
	print("MOBILE results ready  max_scroll=%d" % int(bar.max_value - bar.page))
	_target("SWIPE", sc.get_global_rect().get_center())
	await _w(8.0)
	print("MOBILE results scroll after swipe=%d" % sc.scroll_vertical)
	var mm := _find_button(get_tree().current_scene, "MAIN MENU")
	if mm != null:
		var r := mm.get_global_rect()
		print("MOBILE main menu button visible=%s" % (r.end.y - float(sc.scroll_vertical) <= get_viewport().get_visible_rect().size.y + 1.0 or r.end.y <= get_viewport().get_visible_rect().size.y))
	print("MOBILE done")

func _run() -> void:
	var q: Variant = JavaScriptBridge.eval("window.location.search", true)
	if q is String and String(q).contains("soak=looks"):
		await _run_looks()
		return
	if q is String and String(q).contains("soak=truehunt"):
		await _run_truehunt()
		return
	if q is String and String(q).contains("soak=mobile"):
		await _run_mobile()
		return
	if q is String and String(q).contains("soak=shots"):
		await _run_shots()
		return
	if q is String and String(q).contains("soak=netguest"):
		await _run_netguest(String(q))
		return
	if q is String and String(q).contains("soak=madui"):
		await _run_madui()
		return
	if q is String and String(q).contains("soak=hunt"):
		await _run_hunt()
		return
	if q is String and String(q).contains("soak=perfth"):
		await _run_perf_th()
		return
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
