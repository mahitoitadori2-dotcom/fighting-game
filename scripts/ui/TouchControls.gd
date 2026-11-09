class_name TouchControls
extends CanvasLayer
## MOBILE CONTROLS (multi-touch). Presses the SAME input actions as keyboard /
## controller, so every character works with no extra code.
##
##   LEFT  : floating joystick - touch anywhere in the bottom-left area.
##           left/right = move, down = crouch / fast-fall, flick up = jump.
##   RIGHT : compact see-through button cluster in the bottom-right corner:
##           ATK (big), JUMP, BLOCK and G (ultimate) around it, the moves 3 - 2 - 1 on an
##           outer arc (1 is the rightmost). Move buttons show a cooldown sweep, G glows
##           when the gauge has a bar.
##   SIZE  : Settings > Touch UI Size (MatchSettings.touch_ui_scale) scales the buttons + joystick.
##   TOP   : small MENU button (double tap = back to Main Menu).
## Everything stays in the corners and is semi-transparent: the middle of the
## screen (the fight) is never covered. Sizes scale with the screen height.
##
## Shown when MatchSettings.touch_enabled() (AUTO = touchscreens only).
## On PC with "ON", the left mouse button acts as one finger (for testing).

const BASE_H := 648.0
const IDLE_ALPHA := 0.38
const PRESS_ALPHA := 0.8
const STICK_DEADZONE := 0.22

var _ui: Control
var _scale := 1.0
var _ui_size := 1.0                       # MatchSettings.touch_ui_scale the layout was built with
var _extended := false                    # Layout has the APHA Architect's extra buttons (4-7 + FLY)
var _buttons: Array[Dictionary] = []     # {id, action, label, center, r, finger, pressed}
var _stick := {"home": Vector2.ZERO, "center": Vector2.ZERO, "knob": Vector2.ZERO, "r": 60.0, "finger": -999}
var _stick_jump := false
var _menu_tap_time := -10.0
var _saved_punch_events: Array[InputEvent] = []
var _player: ControlledFighter


func _ready() -> void:
	layer = 12
	_ui = Control.new()
	_ui.set_anchors_and_offsets_preset(Control.PRESET_FULL_RECT)
	_ui.mouse_filter = Control.MOUSE_FILTER_IGNORE      # We read raw touches; menus underneath still work
	add_child(_ui)
	_ui.draw.connect(_draw_ui)
	_ui.resized.connect(_layout)
	# On phones every touch ALSO arrives as a left mouse click, and left click = punch.
	# Unbind the mouse from "punch" while touch controls are active (restored on exit).
	if InputMap.has_action("punch"):
		for ev in InputMap.action_get_events("punch"):
			if ev is InputEventMouseButton:
				_saved_punch_events.append(ev)
				InputMap.action_erase_event("punch", ev)
	_layout()


func _exit_tree() -> void:
	_release_all()
	for ev in _saved_punch_events:
		if InputMap.has_action("punch"):
			InputMap.action_add_event("punch", ev)


# ============================================================
# LAYOUT (bottom corners only)
# ============================================================
func _layout() -> void:
	var size := _ui.get_viewport_rect().size
	MatchSettings.load_controls()
	_ui_size = MatchSettings.touch_ui_scale
	var screen := clampf(size.y / BASE_H, 0.6, 2.5)
	_scale = screen * _ui_size                            # Mobile UI scaler (Settings > Touch UI Size)
	var s := _scale
	_stick["r"] = 58.0 * s
	_stick["home"] = Vector2(105.0 * s, size.y - 105.0 * s)
	if _stick["finger"] == -999:
		_stick["center"] = _stick["home"]
		_stick["knob"] = _stick["home"]

	# Right cluster: big ATK in the corner; JUMP, BLOCK and G on the inner arc, and the
	# moves on the outer arc ordered 1, 2, 3 from RIGHT to LEFT (1 nearest the right edge).
	var a := Vector2(size.x - 82.0 * s, size.y - 82.0 * s)
	var inner := 92.0 * s
	var outer := 160.0 * s
	_buttons.clear()
	_add_button("attack", "punch", "ATK", a, 40.0 * s)
	_add_button("jump", "jump", "JUMP", a + Vector2.from_angle(deg_to_rad(180.0)) * inner, 27.0 * s)
	_add_button("block", "block", "BLK", a + Vector2.from_angle(deg_to_rad(216.0)) * inner, 25.0 * s)
	_add_button("ult", "ultimate", "G", a + Vector2.from_angle(deg_to_rad(254.0)) * inner, 27.0 * s)
	_add_button("m1", "move_rocket", "1", a + Vector2.from_angle(deg_to_rad(268.0)) * outer, 25.0 * s)
	_add_button("m2", "move_hnct", "2", a + Vector2.from_angle(deg_to_rad(245.0)) * outer, 25.0 * s)
	_add_button("m3", "move_drill", "3", a + Vector2.from_angle(deg_to_rad(222.0)) * outer, 25.0 * s)
	# APHA Architect (7 powers + Flight): moves 4-7 on a third ring (right to left), FLY on the left
	_extended = _player != null and is_instance_valid(_player) and _player.move_ids.size() > 3
	if _extended:
		var third := 228.0 * s
		var angs := [280.0, 258.0, 236.0, 214.0]
		for i in range(3, mini(_player.move_ids.size(), 7)):
			_add_button("m%d" % (i + 1), "move_%d" % (i + 1), str(i + 1), a + Vector2.from_angle(deg_to_rad(angs[i - 3])) * third, 22.0 * s)
		if InputMap.has_action("flight"):
			_add_button("fly", "flight", "FLY", Vector2(64.0 * s, size.y - 240.0 * s), 24.0 * s)
	# Small menu button at the top, left of the fight timer (only the screen scale: it is tiny on purpose)
	_add_button("menu", "", "II", Vector2(size.x * 0.5 - 92.0 * screen, 32.0 * screen), 17.0 * screen)
	# Story Mode: healing FLASK button above the joystick (same as the R key)
	if StoryManager.active and InputMap.has_action("use_flask"):
		_add_button("flask", "use_flask", "+", Vector2(64.0 * s, size.y - 240.0 * s), 24.0 * s)
	# Big sizes on small screens: keep every button fully on screen
	for b in _buttons:
		var r: float = b["r"]
		b["center"] = Vector2(clampf(b["center"].x, r + 4.0, size.x - r - 4.0), clampf(b["center"].y, r + 4.0, size.y - r - 4.0))


func _add_button(id: String, action: String, text: String, center: Vector2, r: float) -> void:
	_buttons.append({"id": id, "action": action, "label": text, "center": center, "r": r, "finger": -999, "pressed": false})


# ============================================================
# INPUT
# ============================================================
func _input(event: InputEvent) -> void:
	if not _ui.visible:
		return
	if event is InputEventScreenTouch:
		_touch(event.index, event.position, event.pressed)
	elif event is InputEventScreenDrag:
		_drag(event.index, event.position)
	elif not DisplayServer.is_touchscreen_available():
		# PC testing: the left mouse button is "finger -1"
		if event is InputEventMouseButton and event.button_index == MOUSE_BUTTON_LEFT:
			_touch(-1, event.position, event.pressed)
		elif event is InputEventMouseMotion and (event.button_mask & MOUSE_BUTTON_MASK_LEFT) != 0:
			_drag(-1, event.position)


func _touch(finger: int, pos: Vector2, pressed: bool) -> void:
	if pressed:
		for b in _buttons:
			if b["finger"] == -999 and pos.distance_to(b["center"]) <= b["r"] * 1.3:   # Forgiving hit area
				b["finger"] = finger
				_press(b)
				get_viewport().set_input_as_handled()
				return
		var size := _ui.get_viewport_rect().size
		if _stick["finger"] == -999 and pos.x < size.x * 0.45 and pos.y > size.y * 0.35:
			# Floating stick: centre where the thumb lands (kept fully on screen)
			var r: float = _stick["r"]
			_stick["finger"] = finger
			_stick["center"] = Vector2(clampf(pos.x, r + 8.0, size.x * 0.45), clampf(pos.y, size.y * 0.35, size.y - r - 8.0))
			_stick["knob"] = pos
			_update_stick()
			get_viewport().set_input_as_handled()
		return
	# Released
	for b in _buttons:
		if b["finger"] == finger:
			_release(b)
	if _stick["finger"] == finger:
		_reset_stick()


func _drag(finger: int, pos: Vector2) -> void:
	if _stick["finger"] == finger:
		_stick["knob"] = pos
		_update_stick()


func _press(b: Dictionary) -> void:
	b["pressed"] = true
	if b["id"] == "menu":
		var now := Time.get_ticks_msec() / 1000.0
		if now - _menu_tap_time < 0.6:
			_release_all()
			CombatManager.quit_to_menu(get_tree())
		else:
			_menu_tap_time = now
			if _player != null:
				Effects.popup(_player, _player.global_position + Vector2(0, -190), "TAP AGAIN FOR MENU", Color(1, 1, 1), 18)
		return
	Input.action_press(b["action"])


func _release(b: Dictionary) -> void:
	b["finger"] = -999
	b["pressed"] = false
	if b["action"] != "":
		Input.action_release(b["action"])


func _update_stick() -> void:
	var r: float = _stick["r"]
	var v: Vector2 = (_stick["knob"] - _stick["center"]) / r
	if v.length() > 1.0:
		v = v.normalized()
		_stick["knob"] = _stick["center"] + v * r
	# Left / right with analog strength
	if v.x < -STICK_DEADZONE:
		Input.action_press("move_left", clampf(-v.x, 0.0, 1.0))
		Input.action_release("move_right")
	elif v.x > STICK_DEADZONE:
		Input.action_press("move_right", clampf(v.x, 0.0, 1.0))
		Input.action_release("move_left")
	else:
		Input.action_release("move_left")
		Input.action_release("move_right")
	# Down = crouch / fast-fall
	if v.y > 0.6:
		Input.action_press("crouch")
	else:
		Input.action_release("crouch")
	# Flick up = jump (the JUMP button works too)
	if v.y < -0.72 and not _stick_jump:
		_stick_jump = true
		Input.action_press("jump")
	elif v.y > -0.5 and _stick_jump:
		_stick_jump = false
		Input.action_release("jump")


func _reset_stick() -> void:
	_stick["finger"] = -999
	_stick["center"] = _stick["home"]
	_stick["knob"] = _stick["home"]
	for a in ["move_left", "move_right", "crouch"]:
		Input.action_release(a)
	if _stick_jump:
		_stick_jump = false
		Input.action_release("jump")


func _release_all() -> void:
	for b in _buttons:
		if b["pressed"]:
			_release(b)
	_reset_stick()


# ============================================================
# UPDATE + DRAW
# ============================================================
func _process(_delta: float) -> void:
	var show := CombatManager.fight_active
	if not is_equal_approx(_ui_size, MatchSettings.touch_ui_scale) and _stick["finger"] == -999:
		_release_all()
		_layout()                                 # Touch UI Size changed
	if _ui.visible and not show:
		_release_all()                            # Intro / winner screen: let go of everything
	_ui.visible = show
	if _player == null or not is_instance_valid(_player):
		for n in get_tree().get_nodes_in_group("fighters"):
			var cf := n as ControlledFighter
			if cf != null and cf.slot == 1 and cf.is_human():
				_player = cf
		if _player != null and _player.move_ids.size() > 3 and not _extended:
			_layout()                             # Found a 7-power fighter: add buttons 4-7 + FLY
	_ui.queue_redraw()


func _draw_ui() -> void:
	var s := _scale
	# --- Joystick ---
	var held: bool = _stick["finger"] != -999
	var a := PRESS_ALPHA if held else IDLE_ALPHA
	var c: Vector2 = _stick["center"]
	var r: float = _stick["r"]
	_ui.draw_circle(c, r, Color(0, 0, 0, a * 0.35))
	_ui.draw_arc(c, r, 0.0, TAU, 40, Color(0, 0, 0, a), 4.0 * s, true)
	_ui.draw_arc(c, r - 3.0 * s, 0.0, TAU, 40, Color(1, 1, 1, a * 0.6), 2.0 * s, true)
	for d in [Vector2.LEFT, Vector2.RIGHT, Vector2.DOWN, Vector2.UP]:
		var tip: Vector2 = c + d * (r - 10.0 * s)
		_ui.draw_line(tip - d * 8.0 * s + d.orthogonal() * 5.0 * s, tip, Color(1, 1, 1, a * 0.7), 2.5 * s)
		_ui.draw_line(tip - d * 8.0 * s - d.orthogonal() * 5.0 * s, tip, Color(1, 1, 1, a * 0.7), 2.5 * s)
	var knob: Vector2 = _stick["knob"]
	_ui.draw_circle(knob, r * 0.42 + 3.0 * s, Color(0, 0, 0, a))
	_ui.draw_circle(knob, r * 0.42, Color(0.9, 0.92, 1.0, a))

	# --- Buttons ---
	var font := ThemeDB.fallback_font
	for b in _buttons:
		var bc: Vector2 = b["center"]
		var br: float = b["r"]
		var pressed: bool = b["pressed"]
		var ba := PRESS_ALPHA if pressed else IDLE_ALPHA
		var fill := _button_color(b["id"])
		_ui.draw_circle(bc, br + 3.0 * s, Color(0, 0, 0, ba))
		_ui.draw_circle(bc, br, Color(fill.r, fill.g, fill.b, ba))
		if pressed:
			_ui.draw_circle(bc, br * 0.85, Color(1, 1, 1, 0.25))
		# Cooldown sweep on move buttons
		var cd := _cooldown_fraction(b["id"])
		if cd > 0.0:
			_ui.draw_arc(bc, br * 0.5, -PI * 0.5, -PI * 0.5 + TAU * cd, 24, Color(0, 0, 0, 0.55), br, false)
		# Ultimate: glow when ready + bar count
		if b["id"] == "ult" and _player != null and _player.gauge != null:
			var bars := _player.gauge.segments()
			if bars > 0:
				var p := 0.5 + 0.5 * sin(Time.get_ticks_msec() / 150.0)
				_ui.draw_arc(bc, br + 6.0 * s, 0.0, TAU, 32, Color(0.35, 0.8, 1.0, 0.5 + 0.4 * p), 3.0 * s, true)
				_ui.draw_string(font, bc + Vector2(br * 0.55, -br * 0.55), str(bars), HORIZONTAL_ALIGNMENT_LEFT, -1, int(12 * s), Color(1, 1, 1, 0.9))
		var label: String = b["label"]
		var fs := int((18.0 if label.length() <= 1 else 12.0) * s * (1.25 if b["id"] == "attack" else 1.0))
		var tw := font.get_string_size(label, HORIZONTAL_ALIGNMENT_LEFT, -1, fs).x
		var tp := bc + Vector2(-tw * 0.5, fs * 0.35)
		_ui.draw_string_outline(font, tp, label, HORIZONTAL_ALIGNMENT_LEFT, -1, fs, int(4 * s), Color(0, 0, 0, minf(ba + 0.3, 1.0)))
		_ui.draw_string(font, tp, label, HORIZONTAL_ALIGNMENT_LEFT, -1, fs, Color(1, 1, 1, minf(ba + 0.4, 1.0)))


func _button_color(id: String) -> Color:
	match id:
		"attack":
			return Color(0.95, 0.35, 0.3)
		"jump":
			return Color(0.35, 0.8, 0.4)
		"block":
			return Color(0.35, 0.65, 1.0)
		"ult":
			return Color(0.75, 0.5, 1.0)
		"menu":
			return Color(0.3, 0.3, 0.35)
		"flask":
			return Color(0.35, 0.95, 0.45)
		"fly":
			return Color(0.3, 0.75, 0.45)
	return Color(0.95, 0.75, 0.25)               # Moves 1 / 2 / 3


## 0..1 of the cooldown still remaining for move buttons (reads the player's own move ids).
func _cooldown_fraction(id: String) -> float:
	if _player == null or not is_instance_valid(_player):
		return 0.0
	var idx := ["m1", "m2", "m3", "m4", "m5", "m6", "m7"].find(id)
	if idx < 0 or idx >= _player.move_ids.size():
		return 0.0
	var mid: String = _player.move_ids[idx]
	var left: float = _player.cooldowns.get(mid, 0.0)
	var total: float = _player.cooldown_totals.get(mid, 1.0)
	return clampf(left / maxf(total, 0.001), 0.0, 1.0)
