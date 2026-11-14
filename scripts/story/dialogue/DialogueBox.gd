class_name DialogueBox
extends CanvasLayer
## STORY DIALOGUE (Undertale / Deltarune style). While it plays the GAME IS FROZEN (tree paused;
## the music keeps going). The arena is covered by a shade; at the bottom a black box with an
## ANCIENT gold frame; the speaker's NAME on a plate in its top-left corner; the speaker's
## PORTRAIT stands above the frame (1st speaker on the left, 2nd on the right, 3rd left again...);
## the text TYPES OUT with that character's voice BLIP (Blips.gd).
##
##   var box := DialogueBox.play(self, [["warrior", "Hello."], ["satan", "..."]])
##   await box.finished
##
## Controls: ATTACK / JUMP / ENTER / click / tap = finish the line, then next line.

signal finished

const CPS := 42.0                          # Letters per second
const GOLD := Color(0.78, 0.60, 0.28)
const GOLD_HI := Color(1.0, 0.86, 0.50)
const STONE := Color(0.20, 0.16, 0.12)

var lines: Array = []                      # [[speaker id, text], ...]
var _i := -1
var _shown := 0.0                          # Letters typed so far (float)
var _wait := 0.0                           # Pause after punctuation
var _blip_count := 0
var _sides := {}                           # speaker id -> 0 (left) / 1 (right)
var _slot_speaker := ["", ""]              # Who stands in the left / right slot
var _t := 0.0
var _fade := 0.0
var _was_paused := false
var _text: Label
var _paint: Control
var _shade: Control
var _slots: Array[Control] = []
var _players: Array[AudioStreamPlayer] = []
var _player_i := 0


static func play(host: Node, p_lines: Array) -> DialogueBox:
	var box := DialogueBox.new()
	box.lines = p_lines
	host.get_tree().current_scene.add_child(box)
	return box


func _ready() -> void:
	layer = 90                                     # Above the HUD: the whole screen goes into the shade
	process_mode = Node.PROCESS_MODE_ALWAYS
	_was_paused = get_tree().paused
	get_tree().paused = true                       # The fight is FROZEN while people talk
	_shade = _canvas()
	_shade.draw.connect(func() -> void: _shade.draw_rect(Rect2(Vector2.ZERO, _shade.size), Color(0, 0, 0, 0.38 * _fade)))
	for side in 2:                                 # Portraits: own nodes so the listener can be DIMMED
		var s := _canvas()
		s.draw.connect(_draw_slot.bind(s, side))
		_slots.append(s)
	_paint = Control.new()
	_paint.set_anchors_and_offsets_preset(Control.PRESET_FULL_RECT)
	_paint.mouse_filter = Control.MOUSE_FILTER_IGNORE
	add_child(_paint)
	_paint.draw.connect(_draw_all)
	_text = Label.new()
	_text.autowrap_mode = TextServer.AUTOWRAP_WORD_SMART
	_text.add_theme_font_size_override("font_size", 26)
	_text.add_theme_color_override("font_color", Color(0.97, 0.95, 0.90))
	_text.add_theme_constant_override("line_spacing", 6)
	_text.mouse_filter = Control.MOUSE_FILTER_IGNORE
	add_child(_text)
	for k in 3:
		var p := AudioStreamPlayer.new()
		p.bus = "SFX"
		p.process_mode = Node.PROCESS_MODE_ALWAYS
		add_child(p)
		_players.append(p)
	_next()


func _box_rect() -> Rect2:
	var sz := _paint.size
	var w := minf(sz.x - 60.0, 1100.0)
	var h := 190.0
	return Rect2(Vector2((sz.x - w) * 0.5, sz.y - h - 26.0), Vector2(w, h))


func _process(delta: float) -> void:
	if PauseMenu.is_open:
		return                                      # Typing waits while the game is paused
	_t += delta
	_fade = minf(_fade + delta * 4.0, 1.0)
	var r := _box_rect()
	_text.position = r.position + Vector2(40, 36)
	_text.size = Vector2(r.size.x - 80, r.size.y - 56)
	if _i >= 0 and _i < lines.size():
		var full := String(lines[_i][1])
		if _shown < float(full.length()):
			if _wait > 0.0:
				_wait -= delta
			else:
				var before := int(_shown)
				_shown = minf(_shown + CPS * delta, float(full.length()))
				for c in range(before, int(_shown)):
					_on_letter(full, c)
			_text.visible_characters = int(_shown)
		if StoryManager.autoplay and _shown >= float(full.length()) and not PauseMenu.is_open:
			_advance()                                  # Tests: never stop for dialogue
	_paint.queue_redraw()
	_shade.queue_redraw()
	var who := String(lines[_i][0]) if _i >= 0 and _i < lines.size() else ""
	for side in 2:
		var on: bool = _slot_speaker[side] == who
		_slots[side].modulate = _slots[side].modulate.lerp(Color(1, 1, 1, _fade) if on else Color(0.38, 0.36, 0.40, _fade), minf(delta * 10.0, 1.0))
		_slots[side].queue_redraw()


func _canvas() -> Control:
	var c := Control.new()
	c.set_anchors_and_offsets_preset(Control.PRESET_FULL_RECT)
	c.mouse_filter = Control.MOUSE_FILTER_IGNORE
	add_child(c)
	return c


## One portrait above the frame (left slot faces right, right slot faces left).
func _draw_slot(c: Control, side: int) -> void:
	var sp: String = _slot_speaker[side]
	if sp == "" or _i < 0 or _i >= lines.size():
		return
	var r := _box_rect()
	var active := sp == String(lines[_i][0])
	var feet := Vector2(r.position.x + 150.0 if side == 0 else r.end.x - 150.0, r.position.y - 14.0)
	var s := StoryDialogue.portrait_scale(sp) * (1.0 if active else 0.94)
	var flip := -1.0 if side == 1 else 1.0
	var bob := sin(_t * 2.2) * 2.0 if active else 0.0
	c.draw_set_transform(feet + Vector2(0, bob), 0.0, Vector2(s * flip, s))
	StoryDialogue.draw_portrait(c, sp, _t)
	c.draw_set_transform(Vector2.ZERO, 0.0, Vector2.ONE)


## A letter appeared: blip every 2nd letter, pause after punctuation.
func _on_letter(full: String, c: int) -> void:
	var ch := full[c]
	if ch in [".", "!", "?"]:
		_wait = 0.22
	elif ch == ",":
		_wait = 0.10
	if ch.to_upper() != ch.to_lower() or ch.is_valid_int():
		_blip_count += 1
		if _blip_count % 2 == 1:
			var p := _players[_player_i]
			_player_i = (_player_i + 1) % _players.size()
			p.stream = Blips.stream(StoryDialogue.blip_of(String(lines[_i][0])))
			p.pitch_scale = randf_range(0.93, 1.07)
			p.volume_db = -6.0
			p.play()


func _input(event: InputEvent) -> void:
	if PauseMenu.is_open:
		return                                      # The pause menu's buttons get the clicks
	var go := event.is_action_pressed("punch") or event.is_action_pressed("jump") or event.is_action_pressed("ui_accept")
	var mb := event as InputEventMouseButton
	if mb != null and mb.pressed and mb.button_index == MOUSE_BUTTON_LEFT:
		go = true
	var st := event as InputEventScreenTouch
	if st != null and st.pressed:
		go = true
	if go:
		get_viewport().set_input_as_handled()
		_advance()


func _advance() -> void:
	if _i < 0 or _i >= lines.size():
		return
	var full := String(lines[_i][1])
	if _shown < float(full.length()):
		_shown = float(full.length())                       # First press: show the whole line
		_text.visible_characters = -1
		return
	_next()


func _next() -> void:
	_i += 1
	if _i >= lines.size():
		_close()
		return
	var who := String(lines[_i][0])
	if not _sides.has(who):
		_sides[who] = _sides.size() % 2                    # 1st left, 2nd right, 3rd left...
	_slot_speaker[_sides[who]] = who
	_text.text = String(lines[_i][1])
	_text.visible_characters = 0
	_shown = 0.0
	_wait = 0.08
	_blip_count = 0


func _close() -> void:
	get_tree().paused = _was_paused
	finished.emit()
	queue_free()


# ============================================================
# DRAWING
# ============================================================
func _draw_all() -> void:
	var c := _paint
	if _i < 0 or _i >= lines.size():
		return
	var r := _box_rect()
	var who := String(lines[_i][0])
	_frame(c, r)
	# Name plate in the top-left corner
	var nm := StoryDialogue.name_of(who)
	var plate := Rect2(r.position + Vector2(26, -22), Vector2(maxf(160.0, 16.0 * float(nm.length()) + 40.0), 40))
	c.draw_rect(plate, Color(0.04, 0.03, 0.03))
	c.draw_rect(plate, GOLD, false, 3.0)
	c.draw_rect(plate.grow(-5.0), Color(GOLD.r, GOLD.g, GOLD.b, 0.45), false, 1.5)
	FighterArt.label(c, plate.get_center() + Vector2(0, 8), nm, 20, GOLD_HI)
	# "Next" arrow when the line is done
	var full := String(lines[_i][1])
	if _shown >= float(full.length()):
		var a := r.end - Vector2(40, 26 + absf(sin(_t * 5.0)) * 6.0)
		c.draw_colored_polygon(PackedVector2Array([a + Vector2(-9, -6), a + Vector2(9, -6), a + Vector2(0, 6)]), GOLD_HI)


## The ANCIENT frame: black inside, a double gold border, carved corner diamonds and a rune band.
func _frame(c: Control, r: Rect2) -> void:
	c.draw_rect(r.grow(12.0), STONE)
	c.draw_rect(r, Color(0.02, 0.02, 0.025))
	c.draw_rect(r.grow(12.0), Color(0, 0, 0), false, 3.0)
	c.draw_rect(r.grow(8.0), GOLD, false, 3.0)
	c.draw_rect(r.grow(2.0), GOLD.darkened(0.3), false, 2.0)
	for corner in [r.position, Vector2(r.end.x, r.position.y), r.end, Vector2(r.position.x, r.end.y)]:
		var d := PackedVector2Array([corner + Vector2(0, -16), corner + Vector2(16, 0), corner + Vector2(0, 16), corner + Vector2(-16, 0)])
		c.draw_colored_polygon(d, GOLD)
		c.draw_polyline(PackedVector2Array([d[0], d[1], d[2], d[3], d[0]]), Color(0, 0, 0), 2.0)
		c.draw_circle(corner, 4.0, Color(0.55, 0.12, 0.08))
	# Carved runes along the top and bottom edges
	var n := int(r.size.x / 60.0)
	for k in n:
		var x := r.position.x + 40.0 + float(k) * 60.0
		for y in [r.position.y - 5.0, r.end.y + 5.0]:
			c.draw_line(Vector2(x - 5, y - 2), Vector2(x + 5, y + 2), GOLD.darkened(0.45), 1.5)
			c.draw_line(Vector2(x + 5, y - 2), Vector2(x - 5, y + 2), GOLD.darkened(0.45), 1.5)
