class_name KeyBindings
extends RefCounted
## REBINDABLE KEYBOARD CONTROLS (Settings > CONTROLS). Each action has ONE main keyboard key
## (or mouse button) that the player can change; saved to user://keys.cfg and applied at start.
## The extra keys (arrow keys, Space) and the controller buttons always stay as they are.

const PATH := "user://keys.cfg"
## [action, name shown in Settings, default key (or "mouse_left")]
const ACTIONS := [
	["move_left", "Move Left", KEY_A],
	["move_right", "Move Right", KEY_D],
	["jump", "Jump", KEY_W],
	["crouch", "Crouch / Fast Fall", KEY_S],
	["punch", "Attack", "mouse_left"],
	["block", "Block  (Roll in DemiLand)", KEY_F],
	["move_rocket", "Power 1", KEY_1],
	["move_hnct", "Power 2", KEY_2],
	["move_drill", "Power 3", KEY_3],
	["ultimate", "Ultimate", KEY_G],
	["use_flask", "Drink Flask  (Story)", KEY_R],
	["demi_map", "Map  (DemiLand)", KEY_M],
]

static var _keys := {}                  # action -> current main binding (int keycode or "mouse_left"/"mouse_right")
static var _loaded := false


## Makes sure every action exists (also the Story-only ones), then applies the saved keys.
static func apply_saved() -> void:
	_load()
	_ensure_story_actions()
	for a in ACTIONS:
		var action := String(a[0])
		_set_main(action, _default(action), current(action))


static func current(action: String) -> Variant:
	_load()
	return _keys.get(action, _default(action))


## Text for a binding: "A", "Left Mouse", "Space"...
static func key_name(b: Variant) -> String:
	if b is String:
		return {"mouse_left": "Left Mouse", "mouse_right": "Right Mouse", "mouse_middle": "Middle Mouse"}.get(b, String(b))
	return OS.get_keycode_string(int(b))


## Rebind: the new key / mouse button becomes this action's main binding. If another action
## used it, that one gets this action's old key (a swap), so nothing is left without a key.
static func rebind(action: String, ev: InputEvent) -> void:
	_load()
	var nb: Variant = null
	if ev is InputEventKey:
		nb = int((ev as InputEventKey).physical_keycode)
		if nb == 0:
			nb = int((ev as InputEventKey).keycode)
	elif ev is InputEventMouseButton:
		nb = {MOUSE_BUTTON_LEFT: "mouse_left", MOUSE_BUTTON_RIGHT: "mouse_right", MOUSE_BUTTON_MIDDLE: "mouse_middle"}.get((ev as InputEventMouseButton).button_index, null)
	if nb == null:
		return
	var old: Variant = current(action)
	for a in ACTIONS:                                       # Swap with whoever had it
		var other := String(a[0])
		if other != action and _same(current(other), nb):
			_set_main(other, current(other), old)
			_keys[other] = old
	_set_main(action, old, nb)
	_keys[action] = nb
	_save()


static func reset_all() -> void:
	_load()
	for a in ACTIONS:
		var action := String(a[0])
		_set_main(action, current(action), _default(action))
	_keys.clear()
	_save()


# ----- internals -----
## Same binding? (a key code is an int, a mouse button a String: never compare across types)
static func _same(a: Variant, b: Variant) -> bool:
	return typeof(a) == typeof(b) and a == b


static func _default(action: String) -> Variant:
	for a in ACTIONS:
		if String(a[0]) == action:
			return a[2]
	return null


static func _event(b: Variant) -> InputEvent:
	if b is String:
		var m := InputEventMouseButton.new()
		m.button_index = {"mouse_left": MOUSE_BUTTON_LEFT, "mouse_right": MOUSE_BUTTON_RIGHT, "mouse_middle": MOUSE_BUTTON_MIDDLE}.get(b, MOUSE_BUTTON_LEFT)
		return m
	var k := InputEventKey.new()
	k.physical_keycode = int(b) as Key
	return k


## Replace the action's main binding `from` with `to` (other keys / controller untouched).
static func _set_main(action: String, from: Variant, to: Variant) -> void:
	if not InputMap.has_action(action):
		InputMap.add_action(action)
	for e in InputMap.action_get_events(action):
		var hit := false
		if from is String and e is InputEventMouseButton:
			hit = (e as InputEventMouseButton).button_index == (_event(from) as InputEventMouseButton).button_index
		elif not (from is String) and e is InputEventKey:
			hit = int((e as InputEventKey).physical_keycode) == int(from)
		if hit:
			InputMap.action_erase_event(action, e)
	var ne := _event(to)
	if not InputMap.action_has_event(action, ne):
		InputMap.action_add_event(action, ne)


## The Story-only actions exist from the start (so they can be rebound in Settings).
static func _ensure_story_actions() -> void:
	if not InputMap.has_action("use_flask"):
		InputMap.add_action("use_flask")
		InputMap.action_add_event("use_flask", _event(KEY_R))
		var b := InputEventJoypadButton.new()
		b.button_index = JOY_BUTTON_BACK
		b.device = -1
		InputMap.action_add_event("use_flask", b)
	if not InputMap.has_action("demi_map"):
		InputMap.add_action("demi_map")
		InputMap.action_add_event("demi_map", _event(KEY_M))
		InputMap.action_add_event("demi_map", _event(KEY_TAB))
		var r3 := InputEventJoypadButton.new()
		r3.button_index = JOY_BUTTON_RIGHT_STICK
		r3.device = -1
		InputMap.action_add_event("demi_map", r3)


static func _load() -> void:
	if _loaded:
		return
	_loaded = true
	var cfg := ConfigFile.new()
	if cfg.load(PATH) != OK:
		return
	for a in ACTIONS:
		var action := String(a[0])
		if cfg.has_section_key("keys", action):
			_keys[action] = cfg.get_value("keys", action)


static func _save() -> void:
	var cfg := ConfigFile.new()
	for k in _keys:
		cfg.set_value("keys", k, _keys[k])
	cfg.save(PATH)
