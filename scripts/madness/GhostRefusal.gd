class_name GhostRefusal
extends CanvasLayer
## Typing the XANXXE code AGAIN while Madness is already on (2026-11-22, by the user): the screen goes dark,
## the BLACK GHOST of #s001 (your own fighter, pitch black, red eyes) rises out of the dark and says, in
## a low voice: "THAT WONT WORK MORTAL" (audio/voice/ghost_mortal.wav, deep fried). Then it is gone.

const TEXT := "THAT WONT WORK MORTAL"
const LIFE := 7.0
const K := 3.2

var _t := 0.0
var _canvas: Control
var _ghost: Control
var _art: Script
var _rng := RandomNumberGenerator.new()


static func open(tree: SceneTree) -> GhostRefusal:
	var g := GhostRefusal.new()
	g.name = "GhostRefusal"
	tree.root.add_child(g)
	return g


func _ready() -> void:
	layer = 220
	process_mode = Node.PROCESS_MODE_ALWAYS
	_rng.randomize()
	_art = CharacterRoster.selected().get("art", WarriorArt)
	_canvas = Control.new()
	_canvas.set_anchors_and_offsets_preset(Control.PRESET_FULL_RECT)
	_canvas.mouse_filter = Control.MOUSE_FILTER_STOP
	_canvas.draw.connect(_draw_back)
	add_child(_canvas)
	_ghost = Control.new()                                    # The fighter, drawn PITCH BLACK (like #s001)
	_ghost.set_anchors_and_offsets_preset(Control.PRESET_FULL_RECT)
	_ghost.mouse_filter = Control.MOUSE_FILTER_IGNORE
	_ghost.modulate = Color(0.05, 0.04, 0.06, 0.92)
	_ghost.draw.connect(_draw_ghost)
	add_child(_ghost)
	var front := Control.new()
	front.set_anchors_and_offsets_preset(Control.PRESET_FULL_RECT)
	front.mouse_filter = Control.MOUSE_FILTER_IGNORE
	front.draw.connect(_draw_front.bind(front))
	add_child(front)
	SoundManager.play_sfx("rumble", -2.0)
	MadnessFX.glitch(get_tree(), 1.0)


func _feet() -> Vector2:
	var sz := _canvas.size
	var rise := clampf(_t / 1.4, 0.0, 1.0)
	rise = 1.0 - pow(1.0 - rise, 3.0)
	return Vector2(sz.x * 0.5 + sin(_t * 1.7) * 6.0, sz.y + 420.0 - rise * (sz.y * 0.18 + 420.0) + sin(_t * 2.3) * 5.0)


func _process(delta: float) -> void:
	var before := _t
	_t += delta
	if before < 1.1 and _t >= 1.1:
		SoundManager.say("ghost_mortal", TEXT, 0.4, 0.8)
		MadnessFX.glitch(get_tree(), 0.9)
	if _t >= LIFE:
		queue_free()
		return
	for c in get_children():
		(c as Control).queue_redraw()


func _unhandled_input(event: InputEvent) -> void:
	get_viewport().set_input_as_handled()                     # Nothing behind it reacts
	if event.is_action_pressed("ui_cancel") and _t > 2.5:
		queue_free()


func _fade() -> float:
	return clampf(_t / 0.6, 0.0, 1.0) * clampf((LIFE - _t) / 0.8, 0.0, 1.0)


func _draw_back() -> void:
	var sz := _canvas.size
	_canvas.draw_rect(Rect2(Vector2.ZERO, sz), Color(0, 0, 0, 0.88 * _fade()))
	_canvas.draw_circle(_feet() + Vector2(0, -180), 300.0, Color(0.5, 0.0, 0.0, 0.10 * _fade()))


func _draw_ghost() -> void:
	_ghost.modulate.a = 0.92 * _fade()
	_ghost.draw_set_transform(_feet(), 0.0, Vector2(K, K))
	if _art != null:
		_art.call("draw_portrait", _ghost, _t)
	_ghost.draw_set_transform(Vector2.ZERO, 0.0, Vector2.ONE)


func _draw_front(c: Control) -> void:
	var a := _fade()
	var f := _feet()
	# Black smoke curling off it
	for i in 14:
		var ph := fmod(_t * 0.4 + float(i) * 0.137, 1.0)
		var p := f + Vector2(sin(float(i) * 2.1 + _t) * 90.0, -60.0 - ph * 420.0)
		c.draw_circle(p, 18.0 + ph * 30.0, Color(0.02, 0.0, 0.02, 0.35 * (1.0 - ph) * a))
	# Red eyes
	var glow := (0.7 + 0.3 * sin(_t * 5.0)) * a
	for ex: float in [6.0, 16.0]:
		var e := f + Vector2(ex, -104.0) * K
		c.draw_circle(e, 9.0, Color(1.0, 0.05, 0.03, 0.35 * glow))
		c.draw_circle(e, 4.0, Color(1.0, 0.15, 0.1, glow))
	# The words, letter by letter, heavy and red
	if _t > 1.1:
		var font := ThemeDB.fallback_font
		var n := clampi(int((_t - 1.1) * 7.0), 0, TEXT.length())
		var shown := TEXT.substr(0, n)
		var size_f := 56
		var w := font.get_string_size(TEXT, HORIZONTAL_ALIGNMENT_LEFT, -1, size_f).x
		var pos := Vector2((c.size.x - w) * 0.5 + _rng.randf_range(-2.0, 2.0), c.size.y * 0.2)
		c.draw_string_outline(font, pos, shown, HORIZONTAL_ALIGNMENT_LEFT, -1, size_f, 10, Color(0, 0, 0, a))
		c.draw_string(font, pos, shown, HORIZONTAL_ALIGNMENT_LEFT, -1, size_f, Color(0.9, 0.05, 0.03, a))
