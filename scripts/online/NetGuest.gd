class_name NetGuest
extends Node
## ONLINE, the GUEST side: added to the arena instead of the game logic. It rebuilds what the host
## sends as frozen PUPPETS (fighters: Replay puppets; everything else: copies that only move where the
## host says), and sends YOUR buttons to the host every frame.

var _nodes := {}                       # host id -> Node
var _scripts := {}                     # path -> Script
var _local := FighterInput.new()       # Your keyboard / pad / touch controls
var _last_sent: Array = []
var _send_t := 0.0
var _overlay: CanvasLayer
var _ov_label: Label
var _banner_t := 0.0


## The host started a fight / a level: load the same scene (the guest builds it without game logic).
static func handle_start(d: Dictionary) -> void:
	var tree := Engine.get_main_loop() as SceneTree
	NetLink.inbox.clear()
	if String(d.get("kind", "")) == "versus":
		ArenaManager.selected_arena = String(d.get("arena", ArenaManager.selected_arena))
		CharacterRoster.selected_id = String(d.get("p1", "warrior"))
		CharacterRoster.opponent_id = String(d.get("p2", ""))
	else:
		StoryProgress.current_level = int(d.get("level", StoryProgress.current_level))
	tree.change_scene_to_file(String(d.get("scene", "res://Main.tscn")))


func _ready() -> void:
	add_to_group("net_guest")
	process_mode = Node.PROCESS_MODE_ALWAYS
	_overlay = CanvasLayer.new()
	_overlay.layer = 60
	add_child(_overlay)
	_ov_label = UiStyle.label("", 30, Color(1.0, 0.9, 0.6), 8)
	_ov_label.set_anchors_and_offsets_preset(Control.PRESET_CENTER_TOP)
	_ov_label.offset_top = 150.0
	_ov_label.grow_horizontal = Control.GROW_DIRECTION_BOTH
	_overlay.add_child(_ov_label)
	NetLink.get_link().message.connect(_on_message)
	NetLink.get_link().peer_left.connect(func() -> void: _show("THE HOST LEFT", 999.0))
	for d in NetLink.inbox.duplicate():
		_on_message(d)
	NetLink.inbox.clear()


func _show(text: String, secs: float) -> void:
	_ov_label.text = text
	_banner_t = secs


func _process(delta: float) -> void:
	_banner_t -= delta
	if _banner_t <= 0.0:
		_ov_label.text = ""


func _physics_process(delta: float) -> void:
	_local.update(null, delta)
	var now := NetInput.read_local(_local)
	_send_t -= delta
	if now != _last_sent or _send_t <= 0.0:
		_last_sent = now
		_send_t = 0.1
		NetLink.get_link().send({"k": "in", "a": now[0], "b": now[1]})


func _on_message(d: Dictionary) -> void:
	match String(d.get("k", "")):
		"snap":
			for s: Dictionary in d.get("sp", []):
				_spawn(s)
			var fs: Dictionary = d.get("fs", {})
			for id in fs:
				var f := _nodes.get(id) as Fighter
				if f != null and is_instance_valid(f):
					Replay.apply(f, fs[id])
			var mv: Dictionary = d.get("mv", {})
			for id in mv:
				var n := _nodes.get(id) as Node2D
				if n != null and is_instance_valid(n):
					_set_xform(n, mv[id])
					n.queue_redraw()
			for id in d.get("rm", []):
				var n2: Node = _nodes.get(id)
				if n2 != null and is_instance_valid(n2):
					n2.queue_free()
				_nodes.erase(id)
		"map":
			var sm := get_parent() as StoryManager
			if sm != null:
				sm._apply_map(d.get("m", {}))
		"banner":
			_show(String(d.get("text", "")), 2.5)
		"end":
			_show(String(d.get("text", "")) + "\nWAITING FOR THE HOST", 999.0)


func _spawn(s: Dictionary) -> void:
	var id: int = s["i"]
	if _nodes.has(id):
		return
	var path := String(s.get("s", ""))
	if not _scripts.has(path):
		_scripts[path] = load(path) if ResourceLoader.exists(path) else null
	var sc := _scripts[path] as Script
	if sc == null or not sc.can_instantiate():
		return
	for m in sc.get_script_method_list():                   # (Only things that can be made without arguments)
		if String(m["name"]) == "_init" and (m["args"] as Array).size() > (m["default_args"] as Array).size():
			return
	var n := sc.new() as Node
	if n == null:
		return
	n.name = String(s.get("n", n.name)).validate_node_name()
	var props: Dictionary = s.get("p", {})
	if n is Fighter:
		if n is ControlledFighter:
			(n as ControlledFighter).ctl = FighterInput.new()
		get_parent().add_child(n)
		Replay.make_puppet(n as Fighter)
		Replay.apply(n as Fighter, props)
		var am := get_parent() as ArenaManager
		if am != null:                                       # The Versus HUD reads p1 / p2
			match (n as Fighter).slot:
				1:
					am.p1 = n as Fighter
				2:
					am.p2 = n as Fighter
	else:
		for k in props:
			n.set(String(k), props[k])
		n.process_mode = Node.PROCESS_MODE_DISABLED        # Only moves where the host says
		var host_parent: Node = _nodes.get(s.get("pp", -1))
		(host_parent if host_parent != null and is_instance_valid(host_parent) else get_parent()).add_child(n)
		if n is CollisionObject2D:
			(n as CollisionObject2D).collision_layer = 0
			(n as CollisionObject2D).collision_mask = 0
		if n is Area2D:
			(n as Area2D).set_deferred("monitoring", false)
			(n as Area2D).set_deferred("monitorable", false)
		_set_xform(n as Node2D, s.get("x", []))
	_nodes[id] = n


static func _set_xform(n: Node2D, x: Array) -> void:
	if x.size() < 5:
		return
	n.global_position = x[0]
	n.global_rotation = x[1]
	n.scale = x[2]
	n.modulate = x[3]
	n.visible = x[4]
