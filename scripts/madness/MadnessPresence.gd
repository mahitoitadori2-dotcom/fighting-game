class_name MadnessPresence
extends CanvasLayer
## AS LONG AS MADNESS IS ON (2026-11-22, by the user: "a noticeable effect on the whole game"; "seem like it
## actually has control of the game"). Installed over EVERY screen by GraphicsSettings while
## Madness.unlocked (the console's 'normalize' turns Madness off -> this goes away).
##   * a slow breathing RED VIGNETTE on the edges of the screen, always
##   * every 25-60 s: the screen TEARS (red glitch slices) with a low rumble
##   * every 35-80 s: it TYPES to you in the corner ("XANXXE> ...")
##   * "it has the controls": every 40-90 s a button's text in a menu CORRUPTS for a moment (sometimes it
##     also steals the focus); rarely, in a fight, time stalls for a split second
##   * changing screens: a short tear (it follows you)

const RED := Color(0.85, 0.04, 0.03)
const LINES := [
	"XANXXE> integrity 100.00%",
	"XANXXE> you didn't close me. you can't.",
	"XANXXE> I live in the menus now.",
	"XANXXE> stop pressing that.",
	"XANXXE> who said you were in control?",
	"XANXXE> saving... not your game. me.",
	"XANXXE> I can see every button you touch.",
	"XANXXE> the ghost is still watching.",
	"XANXXE> normalize only makes me sleep.",
	"XANXXE> keep playing. I like it when you play.",
]
const GLYPHS := "#%&@!?X0N1E"

var _vig: Control
var _fx: Control
var _t := 0.0
var _burst := 0.0
var _next_burst := 30.0
var _next_msg := 12.0
var _next_ctl := 45.0
var _next_hitch := 90.0
var _msg := ""
var _msg_t := 0.0
var _scene: Node = null
var _calm := 0.0                                         # > 0: SCARED (rotor / jumpscare): it hides, no effects
var _scare_in := -1.0                                    # >= 0: the scare reaction starts after this
var _rng := RandomNumberGenerator.new()


## ROTOR scares XANXXE (the console's rotor / jumpscare). It reacts once the picture is gone, then
## HIDES for a while: the red fades, no tears, no words, no stolen buttons.
static func scare(tree: SceneTree, delay: float) -> void:
	var p := tree.root.get_node_or_null("MadnessPresence") as MadnessPresence
	if p != null:
		p._scare_in = delay


static func sync(tree: SceneTree) -> void:
	var have := tree.root.get_node_or_null("MadnessPresence")
	if Madness.unlocked and have == null:
		var p := MadnessPresence.new()
		p.name = "MadnessPresence"
		tree.root.add_child(p)
	elif not Madness.unlocked and have != null:
		have.queue_free()


func _ready() -> void:
	layer = 125
	process_mode = Node.PROCESS_MODE_ALWAYS
	_rng.randomize()
	_next_burst = _rng.randf_range(8.0, 20.0)
	_vig = Control.new()
	_vig.set_anchors_and_offsets_preset(Control.PRESET_FULL_RECT)
	_vig.mouse_filter = Control.MOUSE_FILTER_IGNORE
	_vig.draw.connect(_draw_vignette)
	_vig.resized.connect(_vig.queue_redraw)
	add_child(_vig)
	_fx = Control.new()
	_fx.set_anchors_and_offsets_preset(Control.PRESET_FULL_RECT)
	_fx.mouse_filter = Control.MOUSE_FILTER_IGNORE
	_fx.draw.connect(_draw_fx)
	add_child(_fx)


func _process(delta: float) -> void:
	var real := delta / maxf(Engine.time_scale, 0.01)            # (Keeps its own clock through hitstops)
	_t += real
	if _scare_in >= 0.0:
		_scare_in -= real
		if _scare_in < 0.0:
			_say("XANXXE> NO. NOT THE DOG. KEEP IT AWAY.")
			_burst = 0.8
			MadnessFX.glitch(get_tree(), 1.0)
			SoundManager.play_sfx("roar", -6.0)
			_calm = 10.0                                       # Hides for 10 s (by the user)
	if _calm > 0.0:                                                # Hiding: almost gone
		_calm -= real
		_vig.modulate.a = move_toward(_vig.modulate.a, 0.12, real * 0.5)
		if _calm <= 0.0:
			_say("XANXXE> ...is it gone?")
			_burst = 0.3
		_msg_t = maxf(_msg_t - real, 0.0)
		_burst = maxf(_burst - real, 0.0)
		_fx.queue_redraw()
		return
	_vig.modulate.a = 0.75 + 0.25 * sin(_t * 0.9)                 # It breathes
	var tree := get_tree()
	if tree.current_scene != _scene:                               # It follows you to every screen
		if _scene != null:
			_burst = maxf(_burst, 0.25)
		_scene = tree.current_scene
	_next_burst -= real
	if _next_burst <= 0.0:
		_next_burst = _rng.randf_range(25.0, 60.0)
		_burst = 0.45
		SoundManager.play_sfx("rumble", -12.0)
	_next_msg -= real
	if _next_msg <= 0.0:
		_next_msg = _rng.randf_range(35.0, 80.0)
		_say(String(LINES[_rng.randi() % LINES.size()]))
	_next_ctl -= real
	if _next_ctl <= 0.0:
		_next_ctl = _rng.randf_range(40.0, 90.0)
		_take_a_button()
	_next_hitch -= real
	if _next_hitch <= 0.0:
		_next_hitch = _rng.randf_range(90.0, 180.0)
		_hitch()
	_msg_t = maxf(_msg_t - real, 0.0)
	var was := _burst > 0.0
	_burst = maxf(_burst - real, 0.0)
	if _burst > 0.0 or _msg_t > 0.0 or was:
		_fx.queue_redraw()


func _say(text: String) -> void:
	_msg = text
	_msg_t = 5.0


## A button in the current menu shows ITS words for a moment (and sometimes it takes the focus).
func _take_a_button() -> void:
	if OS.has_feature("web") and WebSoak.wanted():
		return                                                # (Not in the automatic phone tests: they find buttons by name)
	var cs := get_tree().current_scene
	if cs == null or PauseMenu.in_fight(get_tree()):
		return
	var pool: Array = []
	for b in cs.find_children("*", "Button", true, false):
		var bb := b as Button
		if bb.is_visible_in_tree() and bb.text.length() >= 3 and not bb.disabled:
			pool.append(bb)
	if pool.is_empty():
		return
	var btn := pool[_rng.randi() % pool.size()] as Button
	var orig := btn.text
	var bad := ""
	for ch in orig:
		bad += GLYPHS[_rng.randi() % GLYPHS.length()] if ch != " " and _rng.randf() < 0.6 else ch
	btn.text = bad
	if _rng.randf() < 0.35 and btn.focus_mode != Control.FOCUS_NONE:
		btn.grab_focus()
	_burst = maxf(_burst, 0.15)
	var w: WeakRef = weakref(btn)
	get_tree().create_timer(1.6, true, false, true).timeout.connect(func() -> void:
		var b2 := w.get_ref() as Button
		if b2 != null and b2.text == bad:
			b2.text = orig)


## In a fight: time stalls for a split second.
func _hitch() -> void:
	var tree := get_tree()
	if not PauseMenu.in_fight(tree) or tree.paused or Engine.time_scale != 1.0 or StoryManager.autoplay:
		return
	Engine.time_scale = 0.15
	_burst = maxf(_burst, 0.3)
	_say("XANXXE> slow.")
	tree.create_timer(0.35, true, false, true).timeout.connect(func() -> void:
		if is_equal_approx(Engine.time_scale, 0.15):
			Engine.time_scale = 1.0)


func _exit_tree() -> void:
	if is_equal_approx(Engine.time_scale, 0.15):
		Engine.time_scale = 1.0


# ============================================================
# DRAWING
# ============================================================
func _draw_vignette() -> void:
	var sz := _vig.size
	var bands := 8
	for i in bands:                                               # Edge bands, darker red toward the edge
		var k := float(i) / float(bands)
		var inset := k * sz.y * 0.16
		var a := 0.13 * (1.0 - k)
		var col := Color(RED.r, RED.g, RED.b, a)
		var th := sz.y * 0.02 + 1.0
		_vig.draw_rect(Rect2(inset, inset, sz.x - inset * 2.0, th), col)
		_vig.draw_rect(Rect2(inset, sz.y - inset - th, sz.x - inset * 2.0, th), col)
		_vig.draw_rect(Rect2(inset, inset, th, sz.y - inset * 2.0), col)
		_vig.draw_rect(Rect2(sz.x - inset - th, inset, th, sz.y - inset * 2.0), col)


func _draw_fx() -> void:
	var sz := _fx.size
	if _burst > 0.0:
		for i in 10:
			var y := _rng.randf_range(0.0, sz.y)
			_fx.draw_rect(Rect2(_rng.randf_range(-40.0, 40.0), y, sz.x, _rng.randf_range(3.0, 22.0)), Color(0.6, 0.0, 0.0, 0.45))
		for i in 18:
			_fx.draw_rect(Rect2(_rng.randf_range(0.0, sz.x), _rng.randf_range(0.0, sz.y), _rng.randf_range(10.0, 90.0), _rng.randf_range(3.0, 14.0)),
				Color(0, 0, 0, 0.7) if _rng.randf() < 0.5 else Color(RED.r, RED.g, RED.b, 0.6))
		if _burst > 0.3:
			_fx.draw_rect(Rect2(Vector2.ZERO, sz), Color(0.5, 0.0, 0.0, 0.12))
	if _msg_t > 0.0:
		var font := ThemeDB.fallback_font
		var shown := _msg.substr(0, clampi(int((5.0 - _msg_t) * 24.0), 0, _msg.length()))
		var a := clampf(_msg_t, 0.0, 1.0)
		var pos := Vector2(28.0, sz.y - 30.0)
		_fx.draw_string_outline(font, pos, shown, HORIZONTAL_ALIGNMENT_LEFT, -1, 20, 6, Color(0, 0, 0, a))
		_fx.draw_string(font, pos, shown, HORIZONTAL_ALIGNMENT_LEFT, -1, 20, Color(0.95, 0.12, 0.08, a))
		if fmod(_t * 2.0, 1.0) < 0.5 and shown.length() == _msg.length():
			_fx.draw_rect(Rect2(pos + Vector2(ThemeDB.fallback_font.get_string_size(shown, HORIZONTAL_ALIGNMENT_LEFT, -1, 20).x + 4.0, -16.0), Vector2(10, 18)), Color(0.95, 0.12, 0.08, a))
