class_name LoadingScreen
extends CanvasLayer
## LOADING SCREENS (2026-11-21, user: "IMPORTANT FOR YOU TO IMPLEMENT LOADING SCREENS IN OTHER LEVELS").
##
##   LoadingScreen.goto(get_tree(), "res://scenes/StoryArena.tscn", "LEVEL 12", "COLOSSEUM 2")
##       Covers the screen, loads the scene IN THE BACKGROUND (a real progress bar), switches to it,
##       then fades away once the new scene is up. Used for every Story level, Versus fights and the
##       Map Catalogue fights.
##   var ls := LoadingScreen.cover(self, "THE CAVE", "...")   ...   await ls.done()
##       The same screen for a transition INSIDE a level (The Abandoned Town -> the cave): you move
##       the player / swap the area while it is up, then call done() to fade it out.
##
## Look: black, a slow ember glow, the title + subtitle, a pixel progress bar, a TIP at the bottom.
## Shown for at least MIN_TIME so it never just flickers.

const MIN_TIME := 0.7
const FADE := 0.25
const TIPS := [
	"Hold DOWN near a person to TALK. Some only tell you everything the second time.",
	"A perfect BLOCK right before a hit takes no damage at all.",
	"Rest at a CamTon to refill your flasks - and to save your run.",
	"The Story board remembers your choices. So does the world.",
	"Every 10th level is harder. Every 25th, even harder. Every 50th hides something far worse.",
	"Settings > Comfort: less screen shake, fewer flashes, faster dialogue.",
	"Hold the confirm button to skip a conversation - a choice is never skipped.",
	"Some walls break. Some candles burn more than wax.",
	"Boss Rush: every boss you have beaten, one after another, two flasks for all of them.",
	"Watch your replays from the winner screen - or save them for later.",
	"The Sun was worshipped long after it went dark.",
	"Nobody has left the Abandoned Town in five hundred years.",
]

var title := ""
var sub := ""
var _path := ""
var _t := 0.0
var _progress := 0.0
var _alpha := 0.0
var _closing := false
var _switched := false
var _tip := ""
var _canvas: Control


## Load + switch to a scene behind a loading screen.
static func goto(tree: SceneTree, path: String, p_title: String = "", p_sub: String = "") -> void:
	var old := tree.root.get_node_or_null("LoadingScreen")
	if old != null:
		old.queue_free()
	var ls := LoadingScreen.new()
	ls.name = "LoadingScreen"
	ls.title = p_title
	ls.sub = p_sub
	ls._path = path
	tree.root.add_child(ls)


## Cover the screen inside a level (no scene change). Fade it out with `await ls.done()`.
static func cover(host: Node, p_title: String, p_sub: String = "") -> LoadingScreen:
	var ls := LoadingScreen.new()
	ls.name = "LoadingCover"
	ls.title = p_title
	ls.sub = p_sub
	host.get_tree().root.add_child(ls)
	return ls


func _ready() -> void:
	layer = 200
	process_mode = Node.PROCESS_MODE_ALWAYS
	_tip = String(TIPS[randi() % TIPS.size()])
	_canvas = Control.new()
	_canvas.set_anchors_and_offsets_preset(Control.PRESET_FULL_RECT)
	_canvas.mouse_filter = Control.MOUSE_FILTER_STOP              # Nothing behind it gets clicked
	_canvas.draw.connect(_draw_screen)
	add_child(_canvas)
	if _path != "":
		if ResourceLoader.load_threaded_request(_path) != OK:
			_switch(null)                                         # Could not start: plain change


## Fade out an in-level cover (cover()). Waits for the minimum time first.
## (It frees itself HERE, at the very end: freeing it while this function waits would mean the
## caller's `await ls.done()` never returns.)
func done() -> void:
	var tree := get_tree()
	while _t < MIN_TIME:
		await tree.process_frame
	_closing = true
	while _alpha > 0.0:
		await tree.process_frame
	queue_free()


func _process(delta: float) -> void:
	_t += delta
	if _closing:
		_alpha = maxf(_alpha - delta / FADE, 0.0)
		if _alpha <= 0.0 and _path != "":
			queue_free()                                          # (A cover is freed by done())
	else:
		_alpha = minf(_alpha + delta / 0.12, 1.0)
	if _path != "" and not _switched:
		var prog := []
		var st := ResourceLoader.load_threaded_get_status(_path, prog)
		if not prog.is_empty():
			_progress = maxf(_progress, float(prog[0]))
		match st:
			ResourceLoader.THREAD_LOAD_LOADED:
				_progress = 1.0
				if _t >= MIN_TIME:
					_switch(ResourceLoader.load_threaded_get(_path) as PackedScene)
			ResourceLoader.THREAD_LOAD_FAILED, ResourceLoader.THREAD_LOAD_INVALID_RESOURCE:
				_switch(null)
	elif _path == "" and not _closing:
		_progress = minf(_progress + delta * 1.4, 0.95)          # In-level cover: a calm fake bar
	_canvas.queue_redraw()


func _switch(scene: PackedScene) -> void:
	_switched = true
	if scene != null:
		get_tree().change_scene_to_packed(scene)
	else:
		get_tree().change_scene_to_file(_path)
	await get_tree().process_frame
	await get_tree().process_frame                                # The new scene has run its _ready
	if is_instance_valid(self):
		_closing = true


func _draw_screen() -> void:
	var c := _canvas
	var sz := c.size
	var a := _alpha
	c.draw_rect(Rect2(Vector2.ZERO, sz), Color(0.02, 0.015, 0.02, a))
	# A slow ember glow + drifting sparks
	var mid := Vector2(sz.x * 0.5, sz.y * 0.46)
	var pulse := 0.5 + 0.5 * sin(_t * 1.6)
	c.draw_circle(mid, minf(sz.x, sz.y) * (0.30 + 0.03 * pulse), Color(0.45, 0.12, 0.04, 0.10 * a))
	c.draw_circle(mid, minf(sz.x, sz.y) * 0.16, Color(0.75, 0.25, 0.06, 0.08 * a))
	for i in 18:
		var fx := fmod(float(i) * 137.0 + _t * (12.0 + float(i % 5) * 4.0), sz.x)
		var fy := sz.y - fmod(float(i) * 61.0 + _t * (30.0 + float(i % 4) * 9.0), sz.y)
		var s := 3.0 if i % 3 == 0 else 2.0
		c.draw_rect(Rect2(Vector2(floorf(fx / 3.0) * 3.0, floorf(fy / 3.0) * 3.0), Vector2(s, s)), Color(1.0, 0.55, 0.2, 0.55 * a))
	# Title + subtitle
	var font := ThemeDB.fallback_font
	if title != "":
		var fs := 46
		var w := font.get_string_size(title, HORIZONTAL_ALIGNMENT_LEFT, -1, fs).x
		c.draw_string_outline(font, Vector2(mid.x - w * 0.5, sz.y * 0.42), title, HORIZONTAL_ALIGNMENT_LEFT, -1, fs, 10, Color(0, 0, 0, a))
		c.draw_string(font, Vector2(mid.x - w * 0.5, sz.y * 0.42), title, HORIZONTAL_ALIGNMENT_LEFT, -1, fs, Color(1.0, 0.86, 0.55, a))
	if sub != "":
		var fs2 := 22
		var w2 := font.get_string_size(sub, HORIZONTAL_ALIGNMENT_LEFT, -1, fs2).x
		c.draw_string(font, Vector2(mid.x - w2 * 0.5, sz.y * 0.42 + 40.0), sub, HORIZONTAL_ALIGNMENT_LEFT, -1, fs2, Color(0.85, 0.78, 0.70, 0.9 * a))
	# Pixel progress bar (3 px steps)
	var bw := minf(sz.x * 0.5, 560.0)
	var bar := Rect2(mid.x - bw * 0.5, sz.y * 0.56, bw, 18.0)
	c.draw_rect(bar.grow(3.0), Color(0, 0, 0, a))
	c.draw_rect(bar, Color(0.16, 0.10, 0.08, a))
	var fill := floorf(bar.size.x * clampf(_progress, 0.0, 1.0) / 6.0) * 6.0
	c.draw_rect(Rect2(bar.position, Vector2(fill, bar.size.y)), Color(0.95, 0.55, 0.18, a))
	c.draw_rect(Rect2(bar.position, Vector2(fill, 6.0)), Color(1.0, 0.8, 0.45, a))
	var dots := ".".repeat(1 + int(_t * 3.0) % 3)
	c.draw_string(font, Vector2(bar.position.x, bar.end.y + 30.0), "LOADING" + dots, HORIZONTAL_ALIGNMENT_LEFT, -1, 18, Color(0.85, 0.80, 0.72, 0.85 * a))
	# The tip
