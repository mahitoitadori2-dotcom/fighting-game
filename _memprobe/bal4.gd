extends Node
## TEMPORARY: balance round 3 (headless). Delete after use.


func _ready() -> void:
	if get_parent() != get_tree().root or name != "Bal4":
		var s := Node.new()
		s.set_script(get_script())
		s.name = "Bal4"
		get_tree().root.add_child.call_deferred(s)
		return
	process_mode = Node.PROCESS_MODE_ALWAYS
	get_tree().create_timer(3000.0, true, false, true).timeout.connect(func() -> void: print("PROBE TIMEOUT"); get_tree().quit())
	_run.call_deferred()


func _w(s: float) -> void:
	await get_tree().create_timer(s, true, false, true).timeout


func _cls(n: Object) -> String:
	return String(n.get_script().get_global_name()) if n and n.get_script() else "?"


func _match(p1: String, p2: String) -> String:
	CharacterRoster.selected_id = p1
	CharacterRoster.opponent_id = p2
	get_tree().change_scene_to_file("res://Main.tscn")
	await _w(1.5)
	var fs: Array = []
	for n in get_tree().get_nodes_in_group("fighters"):
		if n is ControlledFighter:
			fs.append(n)
	var t := 0.0
	while t < 120.0:
		await _w(0.5)
		t += 0.5
		var alive: Array = []
		for f in fs:
			if is_instance_valid(f) and not (f as Fighter).is_dead:
				alive.append(f)
		if alive.size() <= 1:
			return "%s in %ds" % [_cls(alive[0]) if alive.size() == 1 else "draw", int(t)]
	return "time"


func _run() -> void:
	ArenaManager.p1_cpu = true
	ArenaManager.selected_arena = "test"
	var cls := {"architect": "Player", "technician": "Technician"}
	var plan := {"architect": ["firelord", "enlightened", "mimic", "anti"], "technician": ["firelord", "enlightened", "mimic", "anti", "warrior", "architect"]}
	for hero in ["architect", "technician"]:
		var wins := 0
		var games := 0
		for opp in plan[hero]:
			for side in 2:
				var r: String = await _match(hero, opp) if side == 0 else await _match(opp, hero)
				games += 1
				if r.begins_with(String(cls[hero]) + " "):
					wins += 1
				print("P %s vs %s (side %d) -> %s" % [hero, opp, side, r])
		print("P RESULT %s won %d / %d" % [hero, wins, games])
	get_tree().quit()