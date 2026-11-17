extends Node
## TEMPORARY: balance diagnosis (delete after use).

var dmg := {}
var heal := {}
var _last_hp := {}


func _ready() -> void:
	if get_parent() != get_tree().root or name != "BalDiag":
		var s := Node.new()
		s.set_script(get_script())
		s.name = "BalDiag"
		get_tree().root.add_child.call_deferred(s)
		return
	process_mode = Node.PROCESS_MODE_ALWAYS
	get_tree().create_timer(2400.0, true, false, true).timeout.connect(func() -> void: print("PROBE TIMEOUT"); get_tree().quit())
	_run.call_deferred()


func _w(s: float) -> void:
	await get_tree().create_timer(s, true, false, true).timeout


func _cls(n: Object) -> String:
	return String(n.get_script().get_global_name()) if n and n.get_script() else "?"


func _on_damaged(amount: int, hit: HitData, _victim: Fighter) -> void:
	var src := "?"
	if hit != null and is_instance_valid(hit.source):
		src = _cls(hit.source)
	var k := "%s:%s" % [src, hit.move if hit else "?"]
	dmg[k] = int(dmg.get(k, 0)) + amount


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
			_last_hp[n] = (n as Fighter).hp
	var t := 0.0
	while t < 120.0:
		await _w(0.25)
		t += 0.25
		for f in fs:
			if is_instance_valid(f):
				var d: int = (f as Fighter).hp - int(_last_hp.get(f, 0))
				if d > 0 and not (f as Fighter).is_dead:
					heal[_cls(f)] = int(heal.get(_cls(f), 0)) + d
				_last_hp[f] = (f as Fighter).hp
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
	var cls := {"warrior": "Warrior", "architect": "Player"}
	for hero in ["warrior", "architect"]:
		var wins := 0
		for opp in ["firelord", "enlightened", "mimic", "anti"]:
			for side in 2:
				var r: String = await _match(hero, opp) if side == 0 else await _match(opp, hero)
				if r.begins_with(String(cls[hero]) + " "):
					wins += 1
				print("P %s vs %s (side %d) -> %s" % [hero, opp, side, r])
		print("P RESULT %s won %d / 8" % [hero, wins])
	var keys := dmg.keys()
	keys.sort()
	for k in keys:
		print("P DMG %s = %d" % [k, dmg[k]])
	print("P HEAL %s" % str(heal))
	get_tree().quit()