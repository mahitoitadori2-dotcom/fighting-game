class_name DialogueBox
extends CanvasLayer
## STORY DIALOGUE (Undertale / Deltarune style). While it plays the GAME IS FROZEN (tree paused;
## the music keeps going). The arena is covered by a soft vignette; at the bottom a black box with
## an ANCIENT gold frame; the speaker's NAME on a plate in its top-left corner; the speaker's
## PORTRAIT stands above the frame on a lit pedestal (1st speaker on the left, 2nd on the right,
## 3rd left again...); the text TYPES OUT with that character's voice BLIP (Blips.gd).
##
##   var box := DialogueBox.play(self, [["warrior", "Hello."], ["satan", "..."]])
##   await box.finished
##
## CHOICES: a line with a 3rd element [speaker, text, ["I Agree", "I Don't Want That"]] waits for
## you to PICK an option (A / D or arrows + ATTACK / JUMP / ENTER, or click / tap one). The pick
## is in `box.choice` (index) once `finished` fires. Put a choice on the LAST line of a box.
##
## Controls: ATTACK / JUMP / ENTER / click / tap = finish the line, then next line.
## HOLD it (0.8 s) = SKIP to the next choice or to the end (a choice is never skipped).
## Typing speed: SETTINGS > Dialogue Speed (QoL.text_speed: normal / fast / instant).
## (2026-11-15: the look was upgraded - vignette, pedestals + speaker light, gradient box,
## ornate corners with gems, a light sweeping over the gold, a sliding entrance.)

signal finished

const CPS := 42.0                          # Letters per second
const GOLD := Color(0.78, 0.60, 0.28)
const GOLD_HI := Color(1.0, 0.86, 0.50)
const GOLD_DARK := Color(0.42, 0.30, 0.12)
const STONE := Color(0.16, 0.13, 0.10)
const GEM := Color(0.75, 0.14, 0.10)
const INK_TOP := Color(0.035, 0.035, 0.05)
const INK_LOW := Color(0.01, 0.01, 0.015)

static var auto_pick := 0                  # Tests (autoplay): which option is picked

var lines: Array = []                      # [[speaker id, text(, options)], ...]
var choice := -1                           # Picked option index (choice lines)
var _i := -1
var _shown := 0.0                          # Letters typed so far (float)
var _wait := 0.0                           # Pause after punctuation
var _blip_count := 0
var _sides := {}                           # speaker id -> 0 (left) / 1 (right)
var _slot_speaker := ["", ""]              # Who stands in the left / right slot
var _t := 0.0
var _fade := 0.0
var _line_t := 0.0                         # Time since the current line began (name plate pop)
var _sel := 0                              # Highlighted option
var _was_paused := false
var _text: Label
var _paint: Control
var _shade: Control
var _slots: Array[Control] = []
var _players: Array[AudioStreamPlayer] = []
var _player_i := 0
const HOLD_SKIP := 0.8
var _hold := 0.0
var _touch_down := false
var _skip_lbl: Label


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
	_shade.draw.connect(_draw_shade)
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
	_text.add_theme_color_override("font_shadow_color", Color(0, 0, 0, 0.8))
	_text.add_theme_constant_override("shadow_offset_x", 2)
	_text.add_theme_constant_override("shadow_offset_y", 2)
	_text.add_theme_constant_override("line_spacing", 6)
	_text.mouse_filter = Control.MOUSE_FILTER_IGNORE
	add_child(_text)
	_skip_lbl = Label.new()
	_skip_lbl.add_theme_font_size_override("font_size", 15)
	_skip_lbl.add_theme_color_override("font_color", Color(0.85, 0.8, 0.7, 0.75))
	_skip_lbl.mouse_filter = Control.MOUSE_FILTER_IGNORE
	add_child(_skip_lbl)
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
	var h := 196.0
	var rise := (1.0 - _ease(_fade)) * 60.0                   # Slides up as it appears
	return Rect2(Vector2((sz.x - w) * 0.5, sz.y - h - 26.0 + rise), Vector2(w, h))


func _ease(x: float) -> float:
	return 1.0 - pow(1.0 - clampf(x, 0.0, 1.0), 3.0)


func _options() -> Array:
	if _i < 0 or _i >= lines.size() or (lines[_i] as Array).size() < 3:
		return []
	return lines[_i][2]


func _typed() -> bool:
	return _i >= 0 and _i < lines.size() and _shown >= float(String(lines[_i][1]).length())


func _process(delta: float) -> void:
	if PauseMenu.is_open:
		return                                      # Typing waits while the game is paused
	_t += delta
	_line_t += delta
	_fade = minf(_fade + delta * 3.5, 1.0)
	var r := _box_rect()
	_text.position = r.position + Vector2(44, 38)
	_text.size = Vector2(r.size.x - 88, r.size.y - 60)
	_text.modulate.a = _fade
	if _i >= 0 and _i < lines.size():
		var full := String(lines[_i][1])
		if _shown < float(full.length()):
			if _wait > 0.0:
				_wait -= delta * QoL.text_mult()
			else:
				var before := int(_shown)
				_shown = minf(_shown + CPS * QoL.text_mult() * delta, float(full.length()))
				for c in range(before, int(_shown)):
					_on_letter(full, c)
			_text.visible_characters = int(_shown)
		if StoryManager.autoplay and _typed() and not PauseMenu.is_open:
			if not _options().is_empty():
				_sel = clampi(auto_pick, 0, _options().size() - 1)
				_pick()
			else:
				_advance()                                  # Tests: never stop for dialogue
	_paint.queue_redraw()
	_shade.queue_redraw()
	_update_hold_skip(delta, r)
	var who := String(lines[_i][0]) if _i >= 0 and _i < lines.size() else ""
	for side in 2:
		var on: bool = _slot_speaker[side] == who
		_slots[side].modulate = _slots[side].modulate.lerp(Color(1, 1, 1, _fade) if on else Color(0.34, 0.33, 0.38, _fade), minf(delta * 10.0, 1.0))
		_slots[side].queue_redraw()


func _canvas() -> Control:
	var c := Control.new()
	c.set_anchors_and_offsets_preset(Control.PRESET_FULL_RECT)
	c.mouse_filter = Control.MOUSE_FILTER_IGNORE
	add_child(c)
	return c


## A soft vignette: the edges darker than the middle, a little deeper at the bottom (the box).
func _draw_shade() -> void:
	var sz := _shade.size
	var a := 0.30 * _fade
	_shade.draw_rect(Rect2(Vector2.ZERO, sz), Color(0, 0, 0, a))
	for i in 6:
		var k := float(i) / 6.0
		var band := 26.0 + 10.0 * float(i)
		var col := Color(0, 0, 0, 0.07 * _fade * (1.0 - k))
		_shade.draw_rect(Rect2(0, 0, sz.x, band), col)
		_shade.draw_rect(Rect2(0, sz.y - band * 2.4, sz.x, band * 2.4), col)
		_shade.draw_rect(Rect2(0, 0, band, sz.y), col)
		_shade.draw_rect(Rect2(sz.x - band, 0, band, sz.y), col)


## One portrait above the frame (left slot faces right, right slot faces left), standing on a
## lit pedestal; the one speaking gets a soft light behind it.
func _draw_slot(c: Control, side: int) -> void:
	var sp: String = _slot_speaker[side]
	if sp == "" or _i < 0 or _i >= lines.size():
		return
	var r := _box_rect()
	var active := sp == String(lines[_i][0])
	var feet := Vector2(r.position.x + 150.0 if side == 0 else r.end.x - 150.0, r.position.y - 16.0)
	if active:
		var glow := 0.5 + 0.5 * sin(_t * 2.0)
		c.draw_circle(feet + Vector2(0, -110), 150.0, Color(1.0, 0.85, 0.5, 0.05 + 0.02 * glow))
		c.draw_circle(feet + Vector2(0, -110), 95.0, Color(1.0, 0.9, 0.6, 0.05 + 0.02 * glow))
	# Pedestal: a stone ellipse with a gold rim
	c.draw_colored_polygon(EnemyArt.ellipse_points(feet + Vector2(0, 4), 92, 15, 24), STONE)
	c.draw_colored_polygon(EnemyArt.ellipse_points(feet + Vector2(0, 0), 86, 11, 24), STONE.lightened(0.12))
	c.draw_polyline(EnemyArt.ellipse_points(feet, 86, 11, 24), GOLD if active else GOLD_DARK, 2.0)
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
			p.stream = Blips.syllable(StoryDialogue.blip_of(String(lines[_i][0])), ch)       # Babbles vowels in their voice
			p.pitch_scale = randf_range(0.93, 1.07)
			p.volume_db = -6.0
			p.play()


func _input(event: InputEvent) -> void:
	var tch := event as InputEventScreenTouch
	if tch != null:
		_touch_down = tch.pressed                   # For HOLD TO SKIP on phones
	if PauseMenu.is_open:
		return                                      # The pause menu's buttons get the clicks
	var opts := _options()
	if not opts.is_empty() and _typed():
		_choice_input(event, opts)
		return
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


## Picking an option: move with A / D / arrows, confirm with ATTACK / JUMP / ENTER, or click / tap.
func _choice_input(event: InputEvent, opts: Array) -> void:
	var n := opts.size()
	if event.is_action_pressed("move_left") or event.is_action_pressed("ui_left") or event.is_action_pressed("ui_up"):
		_sel = (_sel - 1 + n) % n
		SoundManager.play_sfx("count_tick", -10.0)
		get_viewport().set_input_as_handled()
		return
	if event.is_action_pressed("move_right") or event.is_action_pressed("ui_right") or event.is_action_pressed("ui_down"):
		_sel = (_sel + 1) % n
		SoundManager.play_sfx("count_tick", -10.0)
		get_viewport().set_input_as_handled()
		return
	var pos := Vector2(-1, -1)
	var mb := event as InputEventMouseButton
	if mb != null and mb.pressed and mb.button_index == MOUSE_BUTTON_LEFT:
		pos = mb.position
	var st := event as InputEventScreenTouch
	if st != null and st.pressed:
		pos = st.position
	if pos.x >= 0.0:
		var rects := _option_rects(n)
		for k in n:
			if (rects[k] as Rect2).has_point(pos):
				_sel = k
				get_viewport().set_input_as_handled()
				_pick()
				return
		return
	var mm := event as InputEventMouseMotion
	if mm != null:
		var rects2 := _option_rects(n)
		for k in n:
			if (rects2[k] as Rect2).has_point(mm.position):
				_sel = k
		return
	if event.is_action_pressed("punch") or event.is_action_pressed("jump") or event.is_action_pressed("ui_accept"):
		get_viewport().set_input_as_handled()
		_pick()


## HOLD the confirm button / mouse / finger for HOLD_SKIP seconds: skip to the next choice or the end.
func _update_hold_skip(delta: float, r: Rect2) -> void:
	_skip_lbl.position = r.position + Vector2(r.size.x - 260.0, r.size.y - 30.0)
	_skip_lbl.size = Vector2(240, 22)
	_skip_lbl.horizontal_alignment = HORIZONTAL_ALIGNMENT_RIGHT
	_skip_lbl.modulate.a = _fade
	var at_choice := not _options().is_empty() and _typed()
	var held := Input.is_action_pressed("punch") or Input.is_action_pressed("jump") or Input.is_action_pressed("ui_accept") \
		or Input.is_mouse_button_pressed(MOUSE_BUTTON_LEFT) or _touch_down
	if not held or at_choice or PauseMenu.is_open or StoryManager.autoplay:
		_hold = 0.0
		_skip_lbl.text = ""
		return
	_hold += delta
	var k := clampf(_hold / HOLD_SKIP, 0.0, 1.0)
	var bars := int(k * 10.0)
	_skip_lbl.text = "SKIPPING  " + "|".repeat(bars) + ".".repeat(10 - bars)
	if _hold >= HOLD_SKIP:
		_hold = 0.0
		_skip_to_choice()


func _skip_to_choice() -> void:
	while _i >= 0 and _i < lines.size():
		if not _options().is_empty():
			_shown = float(String(lines[_i][1]).length())    # Show the question; you still pick
			_text.visible_characters = -1
			return
		_next()


func _pick() -> void:
	choice = _sel
	SoundManager.play_sfx("holy", -10.0)
	_next()


func _advance() -> void:
	if _i < 0 or _i >= lines.size():
		return
	if not _typed():
		_shown = float(String(lines[_i][1]).length())       # First press: show the whole line
		_text.visible_characters = -1
		return
	if not _options().is_empty():
		return                                              # Wait for a pick
	_next()


func _next() -> void:
	_i += 1
	if _i >= lines.size():
		_close()
		return
	var who := String(lines[_i][0])
	if who != "narrator":                                  # The narrator has no portrait
		if not _sides.has(who):
			_sides[who] = _sides.size() % 2                # 1st left, 2nd right, 3rd left...
		_slot_speaker[_sides[who]] = who
	_text.text = String(lines[_i][1])
	_text.visible_characters = 0
	_shown = 0.0
	_wait = 0.08
	_blip_count = 0
	_line_t = 0.0
	_sel = 0


func _close() -> void:
	get_tree().paused = _was_paused
	_closed = true
	finished.emit()
	queue_free()


## Freed WITHOUT finishing (the scene changed mid-talk: quit, retry, a test): never leave the game frozen.
var _closed := false


func _exit_tree() -> void:
	if not _closed:
		get_tree().paused = _was_paused


# ============================================================
# DRAWING
# ============================================================
func _draw_all() -> void:
	var c := _paint
	if _i < 0 or _i >= lines.size():
		return
	var r := _box_rect()
	var who := String(lines[_i][0])
	c.modulate.a = _fade
	_frame(c, r)
	# Name plate in the top-left corner: gold tabs, a gem, pops in on a new speaker
	var nm := StoryDialogue.name_of(who)
	if nm != "":
		var pop := 1.0 + 0.12 * maxf(0.0, 1.0 - _line_t * 6.0)
		var pw := maxf(170.0, 15.0 * float(nm.length()) + 56.0)
		var plate := Rect2(r.position + Vector2(30, -24), Vector2(pw, 42))
		plate = Rect2(plate.get_center() - plate.size * 0.5 * pop, plate.size * pop)
		var tab := PackedVector2Array([plate.position + Vector2(-14, plate.size.y * 0.5), plate.position, Vector2(plate.end.x, plate.position.y),
			Vector2(plate.end.x + 14, plate.position.y + plate.size.y * 0.5), plate.end, Vector2(plate.position.x, plate.end.y)])
		c.draw_colored_polygon(tab, Color(0.05, 0.04, 0.03))
		for i in 4:                                              # Gold gradient band inside
			c.draw_rect(Rect2(plate.position.x + 4, plate.position.y + 4 + float(i) * 8.5, plate.size.x - 8, 8.5), Color(GOLD.r, GOLD.g, GOLD.b, 0.10 - 0.02 * float(i)))
		c.draw_polyline(tab + PackedVector2Array([tab[0]]), GOLD, 3.0)
		c.draw_circle(plate.position + Vector2(-14, plate.size.y * 0.5), 5.0, GEM)
		c.draw_circle(Vector2(plate.end.x + 14, plate.position.y + plate.size.y * 0.5), 5.0, GEM)
		FighterArt.label(c, plate.get_center() + Vector2(0, 8), nm, 20, GOLD_HI)
	var opts := _options()
	if not opts.is_empty() and _typed():
		_draw_options(c, opts)
	elif _typed():                                              # "Next": a bobbing gold diamond
		var a := r.end - Vector2(44, 28 + absf(sin(_t * 5.0)) * 6.0)
		var d := PackedVector2Array([a + Vector2(0, -8), a + Vector2(8, 0), a + Vector2(0, 8), a + Vector2(-8, 0)])
		c.draw_colored_polygon(d, GOLD_HI)
		c.draw_polyline(d + PackedVector2Array([d[0]]), Color(0, 0, 0), 2.0)
	else:                                                       # Typing caret
		if fmod(_t, 0.5) < 0.3:
			c.draw_rect(Rect2(r.end - Vector2(52, 40), Vector2(14, 3)), Color(GOLD_HI.r, GOLD_HI.g, GOLD_HI.b, 0.7))


## Option buttons, centred along the bottom of the box.
func _option_rects(n: int) -> Array:
	var r := _box_rect()
	var w := 300.0
	var gap := 40.0
	var total := float(n) * w + float(n - 1) * gap
	var out: Array = []
	for k in n:
		out.append(Rect2(Vector2(r.get_center().x - total * 0.5 + float(k) * (w + gap), r.end.y - 66.0), Vector2(w, 46.0)))
	return out


func _draw_options(c: Control, opts: Array) -> void:
	var rects := _option_rects(opts.size())
	for k in opts.size():
		var rr: Rect2 = rects[k]
		var on := k == _sel
		var pulse := 0.5 + 0.5 * sin(_t * 6.0)
		var cut := _cut_rect(rr, 12.0)                           # DIALOGUE outline: cut corners + gold
		c.draw_colored_polygon(cut, Color(0.10, 0.08, 0.05) if on else Color(0.04, 0.04, 0.05))
		if on:
			var glow := _cut_rect(rr.grow(5.0), 15.0)
			c.draw_polyline(glow + PackedVector2Array([glow[0]]), Color(GOLD_HI.r, GOLD_HI.g, GOLD_HI.b, 0.15 + 0.15 * pulse), 4.0)
		c.draw_polyline(cut + PackedVector2Array([cut[0]]), GOLD_HI if on else GOLD_DARK, 2.5)
		FighterArt.label(c, rr.get_center() + Vector2(0, 8), String(opts[k]), 20, GOLD_HI if on else Color(0.75, 0.72, 0.66))
		if on:                                                  # A little gold heart / cursor on the left
			var hp := Vector2(rr.position.x + 22.0 + pulse * 3.0, rr.get_center().y)
			c.draw_colored_polygon(PackedVector2Array([hp + Vector2(-7, -6), hp + Vector2(7, 0), hp + Vector2(-7, 6)]), GOLD_HI)


## A rectangle with its 4 corners cut off (the dialogue's own outline shape).
static func _cut_rect(r: Rect2, k: float) -> PackedVector2Array:
	return PackedVector2Array([r.position + Vector2(k, 0), Vector2(r.end.x - k, r.position.y), Vector2(r.end.x, r.position.y + k),
		Vector2(r.end.x, r.end.y - k), r.end - Vector2(k, 0), Vector2(r.position.x + k, r.end.y), Vector2(r.position.x, r.end.y - k), r.position + Vector2(0, k)])


## The ANCIENT frame: a dark gradient inside, a carved stone border, a double gold rim with a
## light sweeping over it, ornate corners with red gems, a band of runes.
func _frame(c: Control, r: Rect2) -> void:
	c.draw_rect(r.grow(14.0), STONE)
	for i in 6:                                                 # Stone bevel
		c.draw_rect(r.grow(14.0 - float(i)), Color(1, 1, 1, 0.015 * float(6 - i)), false, 1.0)
	for i in 8:                                                 # Ink gradient inside
		var k := float(i) / 8.0
		c.draw_rect(Rect2(r.position.x, r.position.y + r.size.y * k, r.size.x, r.size.y / 8.0 + 1.0), INK_TOP.lerp(INK_LOW, k))
	c.draw_rect(r.grow(14.0), Color(0, 0, 0), false, 3.0)
	c.draw_rect(r.grow(9.0), GOLD, false, 3.0)
	c.draw_rect(r.grow(2.0), GOLD.darkened(0.35), false, 2.0)
	c.draw_rect(r.grow(-6.0), Color(GOLD.r, GOLD.g, GOLD.b, 0.12), false, 1.0)        # Faint inner engraving
	# A light sweeping along the top of the gold rim
	var sweep := fmod(_t * 0.35, 1.4) - 0.2
	if sweep >= 0.0 and sweep <= 1.0:
		var sx := r.position.x + r.size.x * sweep
		for k in 5:
			var w := 60.0 - float(k) * 10.0
			c.draw_line(Vector2(sx - w, r.position.y - 9.0), Vector2(sx + w, r.position.y - 9.0), Color(1, 0.97, 0.85, 0.08 + 0.05 * float(k)), 3.0)
	# Ornate corners: a gold diamond, two curls, a red gem
	var corners := [[r.position, Vector2(1, 1)], [Vector2(r.end.x, r.position.y), Vector2(-1, 1)], [r.end, Vector2(-1, -1)], [Vector2(r.position.x, r.end.y), Vector2(1, -1)]]
	for cc in corners:
		var p: Vector2 = cc[0]
		var dirv: Vector2 = cc[1]
		c.draw_arc(p + Vector2(dirv.x * 22.0, 0), 9.0, 0.0, TAU, 12, GOLD.darkened(0.15), 2.0)
		c.draw_arc(p + Vector2(0, dirv.y * 22.0), 9.0, 0.0, TAU, 12, GOLD.darkened(0.15), 2.0)
		var d := PackedVector2Array([p + Vector2(0, -17), p + Vector2(17, 0), p + Vector2(0, 17), p + Vector2(-17, 0)])
		c.draw_colored_polygon(d, GOLD)
		c.draw_colored_polygon(PackedVector2Array([p + Vector2(0, -17), p + Vector2(17, 0), p]), GOLD_HI)
		c.draw_polyline(d + PackedVector2Array([d[0]]), Color(0, 0, 0), 2.0)
		c.draw_circle(p, 5.0, GEM)
		c.draw_circle(p + Vector2(-1.5, -1.5), 1.8, Color(1, 0.7, 0.6, 0.8 + 0.2 * sin(_t * 3.0)))
	# Carved runes along the top and bottom edges
	var n := int(r.size.x / 60.0)
	for k in n:
		var x := r.position.x + 44.0 + float(k) * 60.0
		for y: float in [r.position.y - 5.5, r.end.y + 5.5]:
			match k % 3:
				0:
					c.draw_line(Vector2(x - 5, y - 2), Vector2(x + 5, y + 2), GOLD.darkened(0.45), 1.5)
					c.draw_line(Vector2(x + 5, y - 2), Vector2(x - 5, y + 2), GOLD.darkened(0.45), 1.5)
				1:
					c.draw_arc(Vector2(x, y), 3.0, 0.0, TAU, 8, GOLD.darkened(0.45), 1.5)
				_:
					c.draw_line(Vector2(x - 5, y), Vector2(x + 5, y), GOLD.darkened(0.45), 1.5)
					c.draw_line(Vector2(x, y - 3), Vector2(x, y + 3), GOLD.darkened(0.45), 1.5)
