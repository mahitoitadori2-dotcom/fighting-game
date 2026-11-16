extends Node
## TEMPORARY: baseline matches - Warrior and Architect vs the other four (delete after use).


func _ready() -> void:
	if get_parent() != get_tree().root or name != "BaseBal":
		var s := Node.new()
		s.set_script(get_script())
		s.name = "BaseBal"
		get_tree().root.add_child.call_deferred(s)
		return
	process_mode = Node.PROCESS_MODE_ALWAYS
	get_tree().create_timer(2400.0, true, false, true).timeout.connect(func() -> void: print("PROBE TIMEOUT"); get_tree().quit())
	_run.call_deferred()


func _w(s: float) -> void:
	await get_tree().create_timer(s, true, false, true).timeout


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
		await _w(1.0)
		t += 1.0
		var alive: Array = []
		for f in fs:
			if is_instance_valid(f) and not (f as Fighter).is_dead:
				alive.append(f)
		if alive.size() <= 1:
			return String((alive[0] as Node).get_script().get_global_name()) if alive.size() == 1 else "draw"
	return "time"


func _run() -> void:
	ArenaManager.p1_cpu = true
	ArenaManager.selected_arena = "test"
	var cls := {"warrior": "Warrior", "architect": "Player"}
	for hero in ["warrior", "architect"]:
		var wins := 0
		for opp in ["firelord", "enlightened", "mimic", "anti"]:
			for side in 2:
				var w: String = await _match(hero, opp) if side == 0 else await _match(opp, hero)
				var won: bool = w == String(cls[hero]) and not (opp == "anti" and w == "Player" and false)
				if won:
					wins += 1
				print("P %s vs %s (side %d) -> %s" % [hero, opp, side, w])
		print("P BASELINE %s won %d / 8 vs the other four" % [hero, wins])
	get_tree().quit()