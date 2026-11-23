class_name NetLink
extends Node
## ONLINE PLAY (2026-11-23, picked by the user): ROOM CODES through a small relay server (server/relay.js),
## Versus + Story, web + PC cross-play (WebSockets work everywhere).
##
## HOW IT WORKS - the HOST runs the real game; the GUEST is a window into it:
##   guest -> host   its buttons every frame ("in")                    -> NetInput drives the guest's fighter
##   host  -> guest  "start" (which scene / arena / level), then 20x a second a "snap": every fighter's
##                   state (Replay format) + everything spawned in the arena (projectiles, effects...),
##                   + "map" / "banner" / "end" events                 -> NetGuest draws it all as puppets
## So only the host decides hits and damage - the two players never disagree about what happened.
## One NetLink lives on the scene tree root while you are online (NetLink.get_link()).

signal status(text: String)
signal room_made(code: String)
signal joined(mode: String, host_name: String)
signal peer_joined
signal peer_left
signal failed(msg: String)
signal message(msg: Dictionary)

const DEFAULT_URL := "ws://127.0.0.1:8787"
const CFG := "user://online.cfg"
const BUTTONS := ["left", "right", "jump", "crouch", "attack", "block", "move1", "move2", "move3", "ultimate",
	"move4", "move5", "move6", "move7", "fly"]

static var role := ""                      # "host" / "guest" / "" (offline)
static var mode := ""                      # "versus" / "story"
static var code := ""
static var peer_here := false
static var guest_fighter := "warrior"      # The guest's pick (Versus)
static var net_input: NetInput = NetInput.new()   # The guest's buttons, on the host
static var inbox: Array = []               # Messages for the guest scene that is not loaded yet

var url := DEFAULT_URL
var _ws := WebSocketPeer.new()
var _was_open := false
var _on_open: Callable = Callable()


static func get_link() -> NetLink:
	var tree := Engine.get_main_loop() as SceneTree
	var l := tree.root.get_node_or_null("NetLink") as NetLink
	if l == null:
		l = NetLink.new()
		l.name = "NetLink"
		tree.root.add_child(l)
	return l


static func is_host() -> bool:
	return role == "host" and peer_here


static func is_guest() -> bool:
	return role == "guest"


static func saved_url() -> String:
	var c := ConfigFile.new()
	c.load(CFG)
	return String(c.get_value("online", "url", DEFAULT_URL))


static func save_url(u: String) -> void:
	var c := ConfigFile.new()
	c.load(CFG)
	c.set_value("online", "url", u)
	c.save(CFG)


func _ready() -> void:
	process_mode = Node.PROCESS_MODE_ALWAYS


func connect_and(u: String, then: Callable) -> void:
	url = u.strip_edges()
	if _ws.get_ready_state() == WebSocketPeer.STATE_OPEN:
		then.call()
		return
	_on_open = then
	_ws = WebSocketPeer.new()
	_ws.inbound_buffer_size = 4 * 1024 * 1024
	_ws.outbound_buffer_size = 4 * 1024 * 1024
	var err := _ws.connect_to_url(url)
	status.emit("CONNECTING..." if err == OK else "CAN'T REACH THE SERVER")
	if err != OK:
		failed.emit("CAN'T REACH THE SERVER")


func host_room(p_mode: String) -> void:
	role = "host"
	mode = p_mode
	peer_here = false
	_text({"t": "host", "mode": p_mode, "name": CharacterRoster.selected().get("short", "PLAYER")})


func join_room(p_code: String) -> void:
	role = "guest"
	_text({"t": "join", "code": p_code.to_upper().strip_edges()})


func quick(p_mode: String) -> void:
	role = "guest"
	_text({"t": "quick", "mode": p_mode})


func leave() -> void:
	if _ws.get_ready_state() == WebSocketPeer.STATE_OPEN:
		_text({"t": "leave"})
		_ws.close()
	role = ""
	mode = ""
	code = ""
	peer_here = false
	inbox.clear()
	queue_free()


## Game data to the other player (binary frame).
func send(msg: Dictionary) -> void:
	if _ws.get_ready_state() == WebSocketPeer.STATE_OPEN:
		_ws.send(var_to_bytes(msg), WebSocketPeer.WRITE_MODE_BINARY)


func _text(obj: Dictionary) -> void:
	if _ws.get_ready_state() == WebSocketPeer.STATE_OPEN:
		_ws.send_text(JSON.stringify(obj))


func _process(_delta: float) -> void:
	_ws.poll()
	var st := _ws.get_ready_state()
	if st == WebSocketPeer.STATE_OPEN and not _was_open:
		_was_open = true
		status.emit("CONNECTED")
		if _on_open.is_valid():
			var cb := _on_open
			_on_open = Callable()
			cb.call()
	elif st == WebSocketPeer.STATE_CLOSED and _was_open:
		_was_open = false
		peer_here = false
		failed.emit("DISCONNECTED")
	elif st == WebSocketPeer.STATE_CLOSED and _on_open.is_valid():
		_on_open = Callable()
		failed.emit("CAN'T REACH THE SERVER")
	while _ws.get_available_packet_count() > 0:
		var pkt := _ws.get_packet()
		if _ws.was_string_packet():
			_control(JSON.parse_string(pkt.get_string_from_utf8()))
		else:
			var v: Variant = bytes_to_var(pkt)
			if v is Dictionary:
				_game(v as Dictionary)


func _control(m: Variant) -> void:
	if not m is Dictionary:
		return
	var d := m as Dictionary
	match String(d.get("t", "")):
		"room":
			code = String(d["code"])
			room_made.emit(code)
		"joined":
			code = String(d.get("code", ""))
			mode = String(d.get("mode", "versus"))
			peer_here = true
			joined.emit(mode, String(d.get("host", "")))
			send({"k": "hello", "fighter": CharacterRoster.selected_id})
		"peer":
			peer_here = true
			peer_joined.emit()
		"left":
			peer_here = false
			peer_left.emit()
		"error":
			failed.emit(String(d.get("msg", "ERROR")))


func _game(d: Dictionary) -> void:
	match String(d.get("k", "")):
		"in":                                             # Host: the guest's buttons
			net_input.feed(float(d.get("a", 0.0)), int(d.get("b", 0)))
		"start":                                          # Guest: the host started a fight / level
			if role == "guest":
				NetGuest.handle_start(d)
			message.emit(d)
		"hello":                                          # Host: the guest's fighter pick
			guest_fighter = String(d.get("fighter", "warrior"))
			message.emit(d)
		_:
			if role == "guest" and String(d.get("k", "")) != "start" and get_tree().get_first_node_in_group("net_guest") == null:
				inbox.append(d)                           # (The guest scene is still loading)
				if inbox.size() > 400:
					inbox.pop_front()
			message.emit(d)
