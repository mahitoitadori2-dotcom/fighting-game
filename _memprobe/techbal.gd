extends Node
## TEMPORARY: Technician balance probe (delete after use).

var _moves := {}
var _winner := ""


func _ready() -> void:
	if get_parent() != get_tree().root or name != "TechBal":
		var s := Node.new()
		s.set_script(get_script())
		s.name = "TechBal"
		get_tree().root.add_child.call_deferred(s)
		return
	process_mode = Node.PROCESS_MODE_ALWAYS
	get_tree().create_timer(1500.0, true, false, true).timeout.connect(func() -> void: print("PROBE TIMEOUT"); get_tree().quit())
	_run.call_deferred()


func _w(s: float) -> void:
	await get_tree().create_timer(s, true, false, true).timeout


func _on_damaged(amount: int, hit: HitData, victim: Fighter) -> void:
	if hit != null and hit.source is Technician and victim != hit.source:
		_moves[hit.move] = int(_moves.get(hit.move, 0)) + amount


func _match(p1: String, p2: String) -> String:
	CharacterRoster.selected_id = p1
	CharacterRoster.opponent_id = p2
	get_tree().change_scene_to_file("res://Main.tscn")
	await _w(1.5)
	var fs: Array = []
	for n in get_tree().get_nodes_in_group("fighters"):
		if n is ControlledFighter:
			fs.append(n)
			(n as Fighter).damaged.connect(_on_damaged.bind(n))
	var t := 0.0
	while t < 120.0:
		await _w(1.0)
		t += 1.0
		var alive: Array = []
		for f in fs:
			if is_instance_valid(f) and not (f as Fighter).is_dead:
				alive.append(f)
		if alive.size() <= 1:
			return (alive[0] as Fighter).data.character_name if alive.size() == 1 else "draw"
	# Time: more HP left wins
	var best: Fighter = null
	for f in fs:
		if is_instance_valid(f) and (best == null or float((f as Fighter).hp) / float((f as Fighter).data.max_hp) > float(best.hp) / float(best.data.max_hp)):
			best = f
	return (best.data.character_name + " (time)") if best else "draw"


func _run() -> void:
	ArenaManager.p1_cpu = true
	ArenaManager.selected_arena = "test"
	for hero in ["warrior", "architect"]:
		var wins := 0
		for opp in ["firelord", "enlightened", "mimic", "anti"]:
			for side in 2:
				var w := await _match(hero, opp) if side == 0 else await _match(opp, hero)
				var won := w.to_lower().contains(hero) or (hero == "architect" and w.begins_with("The Mighty"))
				if won:
					wins += 1
				print("P %s vs %s (side %d) -> %s" % [hero, opp, side, w])
		print("P BASELINE %s won %d / 8 vs the other four" % [hero, wins])
	print("P damage by move: %s" % str(_moves))
	get_tree().quit()