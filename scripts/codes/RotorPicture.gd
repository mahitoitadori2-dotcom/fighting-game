class_name RotorPicture
extends CanvasLayer
## RED CONSOLE "rotor" / "jumpscare" (2026-11-21, by the user).
##   rotor       a picture of Rotor in the middle of the screen; the game is PAUSED behind it for 3 s
##   jumpscare   Rotor fills the whole screen, suddenly, with a loud roar and a shaking screen (1.3 s)
## PICTURES: any .png / .jpg / .webp in res://art/rotor/ (one is picked at random). Until the user's
## pictures are there, the game's own Rotor drawing (RotorArt) is used.

const DIR := "res://art/rotor/"
const SHOW_TIME := 3.0
const SCARE_TIME := 1.3

var scare := false
var _tex: Texture2D = null
var _c: Control
var _t := 0.0


static func show_picture(tree: SceneTree, p_scare: bool) -> void:
	var old := tree.root.get_node_or_null("RotorPicture")
	if old != null:
		old.queue_free()
	var r := RotorPicture.new()
	r.name = "RotorPicture"
	r.scare = p_scare
	tree.root.add_child(r)


## A random picture from res://art/rotor/ (works in exported builds too), or null.
static func random_picture() -> Texture2D:
	if not DirAccess.dir_exists_absolute(DIR):
		return null
	var files: Array[String] = []
	for f in ResourceLoader.list_directory(DIR):
		var ext := f.get_extension().to_lower()
		if ext in ["png", "jpg", "jpeg", "webp"]:
			files.append(DIR + f)
	if files.is_empty():
		return null
	return load(files[randi() % files.size()]) as Texture2D


func _ready() -> void:
	layer = 230
	process_mode = Node.PROCESS_MODE_ALWAYS
	get_tree().paused = true
	_tex = random_picture()
	_c = Control.new()
	_c.set_anchors_and_offsets_preset(Control.PRESET_FULL_RECT)
	_c.mouse_filter = Control.MOUSE_FILTER_STOP
	_c.draw.connect(_draw_pic)
	add_child(_c)
	if scare:
		SoundManager.play_sfx("roar", 6.0, 0.0)
		SoundManager.play_sfx("explosion", 4.0, 0.0)
		SoundManager.play_sfx("bark", 6.0, 0.0)
	else:
		SoundManager.play_sfx("bark", -2.0)


func _exit_tree() -> void:
	if get_tree() != null:                               # Paused again only if the console is (still) open
		get_tree().paused = get_tree().root.get_node_or_null("RedConsole") != null


func _process(delta: float) -> void:
	_t += delta
	get_tree().paused = true                             # (The console closing must not un-pause it)
	_c.queue_redraw()
	if _t >= (SCARE_TIME if scare else SHOW_TIME):
		queue_free()


func _draw_pic() -> void:
	var sz := _c.size
	var a := 1.0 if scare else clampf(minf(_t / 0.2, (SHOW_TIME - _t) / 0.3), 0.0, 1.0)
	_c.draw_rect(Rect2(Vector2.ZERO, sz), Color(0, 0, 0, (0.95 if scare else 0.7) * a))
	var shake := Vector2(randf_range(-18.0, 18.0), randf_range(-18.0, 18.0)) if scare else Vector2.ZERO
	if _tex != null:
		var ts := _tex.get_size()
		var fit := minf(sz.x / ts.x, sz.y / ts.y) * (1.15 if scare else 0.7)
		var d := ts * fit
		_c.draw_texture_rect(_tex, Rect2((sz - d) * 0.5 + shake, d), false, Color(1, 1, 1, a))
	else:
		var k := sz.y / 120.0 * (1.1 if scare else 0.55)              # The Rotor drawing (~120 tall)
		_c.draw_set_transform(Vector2(sz.x * 0.5, sz.y * (0.92 if scare else 0.72)) + shake, 0.0, Vector2(k, k))
		RotorArt.draw_portrait(_c, _t * 3.0)
		_c.draw_set_transform(Vector2.ZERO, 0.0, Vector2.ONE)
	if scare:
		if fmod(_t * 10.0, 1.0) < 0.5:
			_c.draw_rect(Rect2(Vector2.ZERO, sz), Color(1.0, 0.0, 0.0, 0.18))
	else:
		var f := ThemeDB.fallback_font
		var msg := "ROTOR."
		var mw := f.get_string_size(msg, HORIZONTAL_ALIGNMENT_LEFT, -1, 40).x
		_c.draw_string(f, Vector2((sz.x - mw) * 0.5, sz.y * 0.92), msg, HORIZONTAL_ALIGNMENT_LEFT, -1, 40, Color(1, 1, 1, a))
