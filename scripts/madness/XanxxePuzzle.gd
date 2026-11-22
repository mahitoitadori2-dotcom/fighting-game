class_name XanxxePuzzle
extends Control
## THE PUZZLES BEHIND THE XANXXE 1NT3GR1T13S BARS (2026-11-22, by the user). Selecting a line on the
## panel opens its puzzle; only a SOLVED puzzle starts that line's percent bar. Red pixel style like the
## panel. Taps, mouse, keys and controller all work (every piece is a Button). Esc / Back closes it.
##   "sequence"  EXTRACT REALITY   four red glyphs flash a sequence - repeat it (mistake = a new one)
##   "infect"    READY INFECTION   a 3x3 grid: a tap flips a cell AND its neighbours - infect all nine
##   "align"     ENGAGE MADNESS    three dials; turning one also turns the one after it - point all up

signal solved
signal closed

const RED := Color(0.95, 0.08, 0.06)
const RED_DIM := Color(0.40, 0.03, 0.03)
const DARK := Color(0.06, 0.0, 0.0, 0.96)
const GLYPHS := ["X", "A", "N", "E"]
const SEQ_LEN := 5

var kind := "sequence"
var _t := 0.0
var _msg := ""
var _msg_t := 0.0
var _done := false
var _btns: Array[Button] = []
# sequence
var _seq: Array[int] = []
var _pos := 0
var _show_i := -1                                   # >= 0: showing the sequence (index), -1: your turn
var _show_t := 0.0
var _lit := -1
# infect
var _cells: Array[bool] = []
# align
var _dial: Array[int] = [0, 0, 0]
var _rng := RandomNumberGenerator.new()


static func make(p_kind: String) -> XanxxePuzzle:
	var p := XanxxePuzzle.new()
	p.kind = p_kind
	return p


func _ready() -> void:
	_rng.randomize()
	set_anchors_and_offsets_preset(Control.PRESET_FULL_RECT)
	mouse_filter = Control.MOUSE_FILTER_STOP
	process_mode = Node.PROCESS_MODE_ALWAYS
	var center := CenterContainer.new()
	center.set_anchors_and_offsets_preset(Control.PRESET_FULL_RECT)
	center.offset_top = 90.0
	add_child(center)
	match kind:
		"sequence":
			var row := HBoxContainer.new()
			row.add_theme_constant_override("separation", 26)
			center.add_child(row)
			for i in 4:
				var b := _button(String(GLYPHS[i]), Vector2(120, 120), 54)
				b.pressed.connect(_seq_press.bind(i))
				row.add_child(b)
			_new_sequence()
		"infect":
			var grid := GridContainer.new()
			grid.columns = 3
			grid.add_theme_constant_override("h_separation", 12)
			grid.add_theme_constant_override("v_separation", 12)
			center.add_child(grid)
			for i in 9:
				_cells.append(true)
				var b := _button("", Vector2(100, 100), 30)
				b.pressed.connect(_infect_press.bind(i))
				grid.add_child(b)
			for k in 4:                                         # Scramble with real presses: always solvable
				_flip_around(_rng.randi() % 9)
			if not (false in _cells):
				_flip_around(4)
		"align":
			var row2 := HBoxContainer.new()
			row2.add_theme_constant_override("separation", 34)
			center.add_child(row2)
			for i in 3:
				var b := _button("", Vector2(150, 150), 30)
				b.pressed.connect(_align_press.bind(i))
				row2.add_child(b)
			while _aligned():
				for i in 3:
					_dial[i] = _rng.randi() % 4
	_btns[0].grab_focus.call_deferred()


func _button(text: String, sz: Vector2, font: int) -> Button:
	var b := Button.new()
	b.text = text
	b.custom_minimum_size = sz
	b.add_theme_font_size_override("font_size", font)
	for k in ["font_color", "font_hover_color", "font_focus_color", "font_pressed_color"]:
		b.add_theme_color_override(k, RED)
	var sb := StyleBoxFlat.new()
	sb.bg_color = Color(0.08, 0.0, 0.0)
	sb.border_color = RED_DIM
	sb.set_border_width_all(3)
	var sbf := sb.duplicate() as StyleBoxFlat
	sbf.border_color = RED
	b.add_theme_stylebox_override("normal", sb)
	b.add_theme_stylebox_override("hover", sbf)
	b.add_theme_stylebox_override("focus", sbf)
	b.add_theme_stylebox_override("pressed", sbf)
	b.draw.connect(_draw_piece.bind(b, _btns.size()))
	_btns.append(b)
	return b


func _process(delta: float) -> void:
	_t += delta
	_msg_t = maxf(_msg_t - delta, 0.0)
	if kind == "sequence" and _show_i >= 0:
		_show_t += delta
		_lit = _seq[_show_i] if fmod(_show_t, 0.7) < 0.45 else -1
		if _show_t >= 0.7:
			_show_t = 0.0
			_show_i += 1
			if _show_i >= _seq.size():
				_show_i = -1
				_lit = -1
				_say("YOUR TURN")
			else:
				SoundManager.play_sfx("ui_move", -4.0)
	queue_redraw()
	for b in _btns:
		b.queue_redraw()


func _unhandled_input(event: InputEvent) -> void:
	if event.is_action_pressed("ui_cancel") and not _done:
		get_viewport().set_input_as_handled()
		closed.emit()
		queue_free()


func _say(text: String) -> void:
	_msg = text
	_msg_t = 1.4


func _win() -> void:
	if _done:
		return
	_done = true
	_say("ACCEPTED")
	SoundManager.play_sfx("spark")
	await get_tree().create_timer(0.7, true, false, true).timeout
	solved.emit()
	queue_free()


func _wrong() -> void:
	_say("REJECTED")
	SoundManager.play_sfx("ui_back")
	MadnessFX.glitch(get_tree(), 0.6)


# ----- SEQUENCE -----
func _new_sequence() -> void:
	_seq.clear()
	for i in SEQ_LEN:
		_seq.append(_rng.randi() % 4)
	_pos = 0
	_show_i = 0
	_show_t = -0.6                                        # A short pause first
	_say("WATCH")


func _seq_press(i: int) -> void:
	if _show_i >= 0 or _done:
		return
	_lit = i
	if i != _seq[_pos]:
		_wrong()
		_new_sequence()
		return
	SoundManager.play_sfx("ui_confirm", -6.0)
	_pos += 1
	if _pos >= _seq.size():
		_win()


# ----- INFECT -----
func _flip_around(i: int) -> void:
	var r := floori(i / 3.0)
	var c := i % 3
	for d: Vector2i in [Vector2i(0, 0), Vector2i(1, 0), Vector2i(-1, 0), Vector2i(0, 1), Vector2i(0, -1)]:
		var rr := r + d.y
		var cc := c + d.x
		if rr >= 0 and rr < 3 and cc >= 0 and cc < 3:
			_cells[rr * 3 + cc] = not _cells[rr * 3 + cc]


func _infect_press(i: int) -> void:
	if _done:
		return
	_flip_around(i)
	SoundManager.play_sfx("void_goo", -10.0)
	if not (false in _cells):
		_win()


# ----- ALIGN -----
func _aligned() -> bool:
	return _dial[0] == 0 and _dial[1] == 0 and _dial[2] == 0


func _align_press(i: int) -> void:
	if _done:
		return
	_dial[i] = (_dial[i] + 1) % 4
	if i < 2:
		_dial[i + 1] = (_dial[i + 1] + 1) % 4               # It drags the next one with it
	SoundManager.play_sfx("ui_move", -4.0)
	if _aligned():
		_win()


# ============================================================
# DRAWING
# ============================================================
func _draw() -> void:
	var sz := size
	draw_rect(Rect2(Vector2.ZERO, sz), DARK)
	var font := ThemeDB.fallback_font
	var title := {"sequence": "EXTRACT REALITY", "infect": "READY INFECTION", "align": "ENGAGE MADNESS"}[kind] as String
	var tw := font.get_string_size(title, HORIZONTAL_ALIGNMENT_LEFT, -1, 46).x
	draw_string(font, Vector2((sz.x - tw) * 0.5 + (_rng.randf_range(-3, 3) if fmod(_t, 2.7) < 0.1 else 0.0), sz.y * 0.2), title, HORIZONTAL_ALIGNMENT_LEFT, -1, 46, RED)
	for i in 3:                                                   # Frame
		var inset := 30.0 + float(i) * 6.0
		draw_rect(Rect2(inset, inset, sz.x - inset * 2.0, sz.y - inset * 2.0), Color(RED.r, RED.g, RED.b, 0.6 - 0.18 * float(i)), false, 3.0)
	if _msg_t > 0.0:
		var mw := font.get_string_size(_msg, HORIZONTAL_ALIGNMENT_LEFT, -1, 30).x
		draw_string(font, Vector2((sz.x - mw) * 0.5, sz.y * 0.86), _msg, HORIZONTAL_ALIGNMENT_LEFT, -1, 30, Color(1.0, 0.3, 0.2, minf(_msg_t * 2.0, 1.0)))


func _draw_piece(b: Button, idx: int) -> void:
	var r := Rect2(Vector2.ZERO, b.size)
	var c := r.get_center()
	match kind:
		"sequence":
			if _lit == idx:
				b.draw_rect(r.grow(-6.0), Color(1.0, 0.15, 0.08, 0.85))
		"infect":
			if idx < _cells.size() and _cells[idx]:
				b.draw_rect(r.grow(-8.0), Color(0.75, 0.04, 0.03))
				for k in 5:                                       # Veins
					var a := float(k) * 1.3 + float(idx)
					b.draw_line(c, c + Vector2.from_angle(a) * r.size.x * 0.4, Color(0.3, 0.0, 0.0), 3.0)
			else:
				b.draw_rect(r.grow(-30.0), Color(0.25, 0.25, 0.25), false, 2.0)
		"align":
			if idx < _dial.size():
				var ang := -PI * 0.5 + float(_dial[idx]) * PI * 0.5
				var d := Vector2.from_angle(ang)
				var tip := c + d * r.size.x * 0.34
				b.draw_arc(c, r.size.x * 0.40, 0.0, TAU, 32, RED_DIM, 3.0)
				b.draw_line(c - d * r.size.x * 0.2, tip, RED if _dial[idx] == 0 else Color(0.7, 0.1, 0.08), 8.0)
				b.draw_colored_polygon(PackedVector2Array([tip + d * 16.0, tip + d.orthogonal() * 14.0, tip - d.orthogonal() * 14.0]), RED if _dial[idx] == 0 else Color(0.7, 0.1, 0.08))
