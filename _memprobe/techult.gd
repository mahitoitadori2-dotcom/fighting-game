extends Node

func _ready() -> void:
	if get_parent() != get_tree().root or name != "TechUlt":
		var s := Node.new()
		s.set_script(get_script())
		s.name = "TechUlt"
		get_tree().root.add_child.call_deferred(s)
		return
	process_mode = Node.PROCESS_MODE_ALWAYS
	get_tree().create_timer(120.0, true, false, true).timeout.connect(func() -> void: get_tree().quit())
	_run.call_deferred()


func _w(s: float) -> void:
	await get_tree().create_timer(s, true, false, true).timeout


func _run() -> void:
	ArenaManager.p1_cpu = true
	ArenaManager.selected_arena = "test"
	CharacterRoster.selected_id = "technician"
	CharacterRoster.opponent_id = "warrior"
	get_tree().change_scene_to_file("res://Main.tscn")
	await _w(6.0)
	var tech: Technician = null
	var foe: Fighter = null
	for n in get_tree().get_nodes_in_group("fighters"):
		if n is Technician:
			tech = n
		elif n is ControlledFighter:
			foe = n
	print("P gauge=%s segs=%d ai=%s" % [tech.gauge, tech.gauge.segments() if tech.gauge else -1, tech.ctl])
	for tier in [1, 2, 3]:
		tech.state = Technician.State.FREE
		foe.global_position = tech.global_position + Vector2(tech.facing * 200.0, 0)
		var hp0 := foe.hp
		var mhp := tech.hp
		tech.gauge.call("add", 999.0) if tech.gauge.has_method("add") else null
		var segs := tech.gauge.segments()
		while tech.gauge.segments() > tier:
			tech.gauge.consume_segments(1)
		print("P tier %d: segs before=%d now=%d" % [tier, segs, tech.gauge.segments()])
		tech.hp = 50
		tech._try_ultimate()
		await _w(4.5)
		print("P   tier %d: foe hp %d -> %d, tech hp 50 -> %d" % [tier, hp0, foe.hp, tech.hp])
	get_tree().quit()