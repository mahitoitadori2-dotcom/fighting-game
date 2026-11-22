class_name XanxxePanel
extends CanvasLayer
## SECRET CODE "XANXXE 1NT3GR1T13S: % 100.00" (PC: SSSDDDAAADDDWWWSAWD on the Main Menu).
## A CONTROL PANEL over the WHOLE screen, in pixel art (3-px grid, like the fighters): red lines
## instead of green, scanlines, a stepped pixel frame. Three things to select:
##     EXTRACT REALITY     READY INFECTION     ENGAGE MADNESS
## Selecting one opens its PUZZLE (XanxxePuzzle, 2026-11-22); only a solved puzzle starts the percent bar
## next to it. All three at 100% -> the WHOLE SCREEN CORRUPTS (glitch blocks, torn slices, noise) ->
## "MADNESS UNLOCKED" stays on a black screen for a few seconds -> MADNESS is unlocked -> back to the game.

const PX := 3.0
const RED := Color(0.95, 0.08, 0.06)
const RED_DIM := Color(0.40, 0.03, 0.03)
const ITEMS := ["EXTRACT REALITY", "READY INFECTION", "ENGAGE MADNESS"]
const FILL_TIME := 2.4
const PUZZLES := ["sequence", "infect", "align"]
const END_TIME := 7.5                                # The corruption + "MADNESS UNLOCKED" on black (was 2.8 s)
var _puzzle: XanxxePuzzle = null

var _canvas: Control
var _buttons: Array[Button] = []
var _pct := [0.0, 0.0, 0.0]
var _running := [false, false, false]
var _t := 0.0
var _corrupt := -1.0                                 # >= 0: the corruption is playing
var _rng := RandomNumberGenerator.new()


static func open(tree: SceneTree) -> XanxxePanel:
	var p := XanxxePanel.new()
	p.name = "XanxxePanel"
	tree.root.add_child(p)
	return p


func _ready() -> void:
	layer = 210
	process_mode = Node.PROCESS_MODE_ALWAYS
	_rng.randomize()
	_canvas = Control.new()
	_canvas.set_anchors_and_offsets_preset(Control.PRESET_FULL_RECT)
	_canvas.mouse_filter = Control.MOUSE_FILTER_STOP
	_canvas.draw.connect(_draw_panel)
	add_child(_canvas)
	var col := VBoxContainer.new()
	col.set_anchors_and_offsets_preset(Control.PRESET_FULL_RECT)
	col.offset_left = 120.0
	col.offset_top = 210.0
	col.add_theme_constant_override("separation", 34)
	add_child(col)
	for i in ITEMS.size():
		var b := Button.new()
		b.text = "  >  " + String(ITEMS[i])
		b.flat = true
		b.alignment = HORIZONTAL_ALIGNMENT_LEFT
		b.custom_minimum_size = Vector2(430, 64)
		b.size_flags_horizontal = Control.SIZE_SHRINK_BEGIN
		b.add_theme_font_size_override("font_size", 30)
		for k in ["font_color", "font_hover_color", "font_focus_color", "font_pressed_color"]:
			b.add_theme_color_override(k, RED if k != "font_color" else Color(0.8, 0.1, 0.08))
		var sb := StyleBoxFlat.new()
		sb.bg_color = Color(0.08, 0.0, 0.0, 0.9)
		sb.border_color = RED_DIM
		sb.set_border_width_all(3)
		var sbf := sb.duplicate() as StyleBoxFlat
		sbf.border_color = RED
		sbf.bg_color = Color(0.18, 0.0, 0.0, 0.95)
		b.add_theme_stylebox_override("normal", sb)
		b.add_theme_stylebox_override("hover", sbf)
		b.add_theme_stylebox_override("focus", sbf)
		b.add_theme_stylebox_override("pressed", sbf)
		b.pressed.connect(_select.bind(i))
		col.add_child(b)
		_buttons.append(b)
	SoundManager.set_madness(true)
	tree_exiting.connect(func() -> void: SoundManager.set_madness(false))
	SoundManager.play_sfx("rumble", -6.0)
	_buttons[0].grab_focus.call_deferred()


func _select(i: int) -> void:
	if _running[i] or _corrupt >= 0.0 or _puzzle != null:
		return
	SoundManager.play_sfx("ui_confirm")
	_puzzle = XanxxePuzzle.make(String(PUZZLES[i]))
	for b in _buttons:
		b.focus_mode = Control.FOCUS_NONE                    # (Keys / pad stay inside the puzzle)
	_puzzle.solved.connect(func() -> void:
		_running[i] = true)
	_puzzle.tree_exited.connect(func() -> void:
		_puzzle = null
		for b in _buttons:
			b.focus_mode = Control.FOCUS_ALL
		if is_inside_tree() and _corrupt < 0.0:
			_buttons[i].grab_focus())
	add_child(_puzzle)


func _process(delta: float) -> void:
	_t += delta
	if _corrupt >= 0.0:
		_corrupt += delta
		if _corrupt > END_TIME:
			_finish()
		_canvas.queue_redraw()
		return
	var all := true
	for i in 3:
		if _running[i] and _pct[i] < 100.0:
			_pct[i] = minf(_pct[i] + delta / FILL_TIME * 100.0 * _rng.randf_range(0.2, 1.8), 100.0)   # Jittery, like a real job
			if _pct[i] >= 100.0:
				SoundManager.play_sfx("spark", -4.0)
		if _pct[i] < 100.0:
			all = false
	if all:
		_start_corruption()
	_canvas.queue_redraw()


func _start_corruption() -> void:
	_corrupt = 0.0
	for b in _buttons:
		b.visible = false
	SoundManager.play_sfx("roar")
	SoundManager.play_sfx("explosion", -4.0)


func _finish() -> void:
	Madness.unlock()
	set_process(false)
	var tree := get_tree()
	queue_free()
	if tree.current_scene != null and tree.current_scene.scene_file_path.ends_with("MainMenu.tscn"):
		tree.reload_current_scene()


func _unhandled_input(event: InputEvent) -> void:
	get_viewport().set_input_as_handled()                    # Nothing behind it reacts
	if event.is_action_pressed("ui_cancel") and _corrupt < 0.0 and not (true in _running) and _puzzle == null:
		queue_free()


# ============================================================
# DRAWING (pixel art: everything on a 3-px grid)
# ============================================================
func _px(r: Rect2, col: Color) -> void:
	var p := (r.position / PX).floor() * PX
	var e := (r.end / PX).ceil() * PX
	_canvas.draw_rect(Rect2(p, e - p), col)


func _draw_panel() -> void:
	var c := _canvas
	var sz := c.size
	var font := ThemeDB.fallback_font
	c.draw_rect(Rect2(Vector2.ZERO, sz), Color(0.0, 0.0, 0.0, 0.97))
	# Red grid + scanlines
	var g := 48.0
	var x := fmod(_t * 6.0, g)
	while x < sz.x:
		c.draw_rect(Rect2(floorf(x / PX) * PX, 0, PX, sz.y), Color(RED_DIM.r, RED_DIM.g, RED_DIM.b, 0.35))
		x += g
	var y := fmod(_t * 6.0, g)
	while y < sz.y:
		c.draw_rect(Rect2(0, floorf(y / PX) * PX, sz.x, PX), Color(RED_DIM.r, RED_DIM.g, RED_DIM.b, 0.35))
		y += g
	for sy in range(0, int(sz.y), 6):
		c.draw_rect(Rect2(0, sy, sz.x, 2), Color(0, 0, 0, 0.25))
	# Stepped pixel frame
	var m := 24.0
	for k in 4:
		var inset := m + float(k) * PX * 2.0
		var col := RED if k == 0 else Color(RED.r, RED.g, RED.b, 0.5 - 0.12 * float(k))
		_px(Rect2(inset, inset, sz.x - inset * 2.0, PX), col)
		_px(Rect2(inset, sz.y - inset - PX, sz.x - inset * 2.0, PX), col)
		_px(Rect2(inset, inset, PX, sz.y - inset * 2.0), col)
		_px(Rect2(sz.x - inset - PX, inset, PX, sz.y - inset * 2.0), col)
	# Title
	var title := "XANXXE 1NT3GR1T13S"
	var flick := 1.0 if fmod(_t * 7.0, 1.0) > 0.08 else 0.4
	c.draw_string(font, Vector2(m + 60.0, m + 92.0), title, HORIZONTAL_ALIGNMENT_LEFT, -1, 54, Color(RED.r, RED.g, RED.b, flick))
	var total := (float(_pct[0]) + float(_pct[1]) + float(_pct[2])) / 3.0
	c.draw_string(font, Vector2(m + 60.0, m + 136.0), "%% %06.2f     SELECT  >  ALL THREE" % total, HORIZONTAL_ALIGNMENT_LEFT, -1, 24, Color(0.85, 0.15, 0.1))
	# Percent bars next to the items
	for i in 3:
		if not _running[i] or _buttons.size() <= i:
			continue
		var b := _buttons[i]
		var r := Rect2(b.global_position + Vector2(b.size.x + 40.0, 18.0), Vector2(minf(sz.x - b.global_position.x - b.size.x - 140.0, 520.0), 30.0))
		_px(r.grow(PX), RED_DIM)
		_px(r, Color(0.05, 0.0, 0.0))
		var w := floorf(r.size.x * float(_pct[i]) / 100.0 / (PX * 3.0)) * PX * 3.0
		_px(Rect2(r.position, Vector2(w, r.size.y)), RED)
		c.draw_string(font, r.position + Vector2(r.size.x + 14.0, 25.0), "%% %06.2f" % float(_pct[i]), HORIZONTAL_ALIGNMENT_LEFT, -1, 22, RED if _pct[i] < 100.0 else Color(1.0, 0.5, 0.4))
	# THE CORRUPTION: blocks, torn slices, noise, an inverted flash
	if _corrupt >= 0.0:
		var k := clampf(_corrupt / 2.2, 0.0, 1.0)
		for i in int(40.0 + 260.0 * k):
			var bw := _rng.randf_range(6.0, 140.0) * (0.4 + k)
			var bh := _rng.randf_range(3.0, 40.0)
			_px(Rect2(_rng.randf_range(0.0, sz.x), _rng.randf_range(0.0, sz.y), bw, bh), RED if _rng.randf() < 0.55 else Color(0, 0, 0))
		for i in 12:
			var sy := _rng.randf_range(0.0, sz.y)
			c.draw_rect(Rect2(_rng.randf_range(-60.0, 60.0), sy, sz.x, _rng.randf_range(4.0, 24.0)), Color(0.6, 0.0, 0.0, 0.6))
		if fmod(_corrupt * 9.0, 1.0) < 0.12:
			c.draw_rect(Rect2(Vector2.ZERO, sz), Color(1.0, 0.1, 0.05, 0.5))
		if _corrupt > 2.2:
			c.draw_rect(Rect2(Vector2.ZERO, sz), Color(0, 0, 0, minf((_corrupt - 2.2) / 0.6, 1.0)))
		var msg := "M A D N E S S   U N L O C K E D"
		var mw := font.get_string_size(msg, HORIZONTAL_ALIGNMENT_LEFT, -1, 40).x
		var held := _corrupt > 2.8                                # On black: it stays, breathing, barely shaking
		var jit := _rng.randf_range(-8.0, 8.0) if not held else _rng.randf_range(-1.5, 1.5)
		var pulse := 1.0 if not held else 0.75 + 0.25 * sin(_corrupt * 3.0)
		c.draw_string(font, Vector2((sz.x - mw) * 0.5 + jit, sz.y * 0.5), msg, HORIZONTAL_ALIGNMENT_LEFT, -1, 40, Color(1.0, 0.2, 0.15, pulse))
		for line in [[3.6, "IT HAS THE CONTROL NOW", 22], [5.0, "XANXXE 1NT3GR1T13S :  % 100.00", 18]]:
			if _corrupt > float(line[0]):
				var lw := font.get_string_size(String(line[1]), HORIZONTAL_ALIGNMENT_LEFT, -1, int(line[2])).x
				var la := clampf((_corrupt - float(line[0])) / 0.8, 0.0, 1.0)
				c.draw_string(font, Vector2((sz.x - lw) * 0.5, sz.y * 0.5 + 50.0 + (34.0 if int(line[2]) == 18 else 0.0)), String(line[1]), HORIZONTAL_ALIGNMENT_LEFT, -1, int(line[2]), Color(0.75, 0.08, 0.06, la))
		if _corrupt > END_TIME - 0.5 and fmod(_corrupt * 11.0, 1.0) < 0.3:    # A last tear before it lets go
			c.draw_rect(Rect2(0, _rng.randf_range(0.0, sz.y), sz.x, _rng.randf_range(6.0, 30.0)), Color(0.7, 0.0, 0.0, 0.7))
