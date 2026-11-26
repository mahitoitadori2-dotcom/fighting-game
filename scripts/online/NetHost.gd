class_name NetHost
extends Node
## ONLINE, the HOST side: added to the arena (ArenaManager / StoryManager) while a guest is connected.
## Sends "start" (which scene to load), then 20x a second a "snap" with:
##   sp  new things in the arena (script + its plain variables): fighters, projectiles, effects...
##   fs  each fighter's CHANGED state (Replay.capture deltas)
##   mv  where every other thing is now (pos, rotation, scale, colour, visible)
##   rm  things that are gone
## Things are tracked when they are added DIRECTLY to the arena (not fighters' own parts).

const HZ := 20.0
## While true nothing new is tracked (StoryManager._apply_map: the guest builds its own map).
static var mute := false

var start_msg := {}
var _mgr: Node
var _tracked := {}                     # id -> Node
var _pending: Array = []               # ids to send as spawns on the next tick
var _last := {}                        # fighter id -> last sent capture
var _removed: Array = []
var _acc := 0.0


func _ready() -> void:
	add_to_group("net_host")
	process_mode = Node.PROCESS_MODE_ALWAYS
	_mgr = get_parent()
	get_tree().node_added.connect(_on_added)
	get_tree().node_removed.connect(_on_removed)
	NetLink.get_link().peer_joined.connect(resync)
	resync()


func _exit_tree() -> void:
	if NetLink.role == "host":
		NetLink.get_link().send({"k": "end", "text": String(start_msg.get("end_text", "THE HOST LEFT THE FIGHT"))})


## Everything again from scratch (a guest arrived / this scene started).
func resync() -> void:
	NetLink.get_link().send(start_msg)
	_tracked.clear()
	_last.clear()
	_pending.clear()
	for f in get_tree().get_nodes_in_group("fighters"):
		_track(f as Node)


func _world_parent(n: Node) -> bool:
	var p := n.get_parent()
	return p != null and (p == _mgr or p == get_tree().current_scene or p.is_in_group("net_world"))


func _on_added(n: Node) -> void:
	if mute or not n is Node2D or n.get_script() == null or n == self or n.name == "Ghost":
		return
	if not _world_parent(n) and not (n.get("net_sync") == true and _tracked.has(n.get_parent().get_instance_id())):
		return                                            # (Fighters' own parts stay local - unless they ask: net_sync)
	_track(n)


func _track(n: Node) -> void:
	var id := n.get_instance_id()
	if _tracked.has(id):
		return
	_tracked[id] = n
	_pending.append(id)


func _on_removed(n: Node) -> void:
	var id := n.get_instance_id()
	if _tracked.has(id):
		_tracked.erase(id)
		_last.erase(id)
		_pending.erase(id)
		_removed.append(id)


func _physics_process(delta: float) -> void:
	_acc += delta
	if _acc < 1.0 / HZ:
		return
	_acc = 0.0
	var sp: Array = []
	for id in _pending:
		var n: Node = _tracked.get(id)
		if n == null or not is_instance_valid(n) or not n.is_inside_tree():
			continue
		var p: Dictionary = Replay.capture(n as Fighter) if n is Fighter else NetHost.props(n)
		if n is Fighter:
			_last[id] = p
		var spawn := {"i": id, "s": (n.get_script() as Script).resource_path, "p": p, "x": _xform(n as Node2D), "n": String(n.name)}
		if n.get("net_sync") == true:
			spawn["pp"] = n.get_parent().get_instance_id()     # Inside a fighter (a held weapon)
		sp.append(spawn)
	_pending.clear()
	var fs := {}
	var mv := {}
	for id in _tracked:
		var n: Node = _tracked[id]
		if not is_instance_valid(n):
			continue
		if n is Fighter:
			var cap := Replay.capture(n as Fighter)
			var prev: Dictionary = _last.get(id, {})
			var delta_d := {}
			for k in cap:
				if not prev.has(k) or prev[k] != cap[k]:
					delta_d[k] = cap[k]
			if not delta_d.is_empty():
				fs[id] = delta_d
			_last[id] = cap
		else:
			mv[id] = _xform(n as Node2D)
	var msg := {"k": "snap"}
	if not sp.is_empty():
		msg["sp"] = sp
	if not fs.is_empty():
		msg["fs"] = fs
	if not mv.is_empty():
		msg["mv"] = mv
	if not _removed.is_empty():
		msg["rm"] = _removed.duplicate()
		_removed.clear()
	if msg.size() > 1:
		NetLink.get_link().send(msg)


static func _xform(n: Node2D) -> Array:
	return [n.global_position, n.global_rotation, n.scale, n.modulate, n.visible]


## The plain script variables of any node (what a fresh copy on the guest needs to look the same).
static func props(n: Object) -> Dictionary:
	var out := {}
	for p in n.get_property_list():
		if not (int(p["usage"]) & PROPERTY_USAGE_SCRIPT_VARIABLE):
			continue
		var v: Variant = n.get(String(p["name"]))
		if v == null or v is Object or v is Callable or v is Signal:
			continue
		if (v is Array or v is Dictionary) and not Replay._plain(v, 1):
			continue
		out[String(p["name"])] = v
	return out


## Story / Versus events for the guest (map switches, banners).
static func event(msg: Dictionary) -> void:
	if NetLink.is_host():
		NetLink.get_link().send(msg)
