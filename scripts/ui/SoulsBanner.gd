class_name SoulsBanner
extends CanvasLayer
## The SOULS-STYLE BANNERS: a dark band across the middle of the screen, a big serif title that
## slowly fades in (and slightly grows), holds, then fades out.
##   SoulsBanner.died(host)                       "YOU DIED" (dark red)
##   SoulsBanner.felled(host, great, sub)         "GREAT ENEMY FELLED" / "ENEMY FELLED" (gold)
##   await banner.finished
## The title uses a serif system font when there is one (Windows / Mac / Linux); the web build
## falls back to the game font.

signal finished

const FADE_IN := 1.1
const FADE_OUT := 0.9

var title := "YOU DIED"
var sub := ""
var color := Color(0.72, 0.08, 0.06)
var hold := 2.2
var _t := 0.0
var _paint: Control
var _font: Font


static func died(host: Node) -> SoulsBanner:
	SoundManager.play_sfx("death", -2.0)
	SoundManager.play_sfx("rumble", -8.0)
	return _make(host, "YOU DIED", "", Color(0.72, 0.08, 0.06), 2.0)


static func felled(host: Node, great: bool, sub_text: String = "") -> SoulsBanner:
	SoundManager.play_sfx("holy", -2.0)
	SoundManager.play_sfx("slam", -8.0)
	return _make(host, "GREAT ENEMY FELLED" if great else "ENEMY FELLED", sub_text, Color(1.0, 0.82, 0.38), 2.4)


static func _make(host: Node, t: String, s: String, c: Color, h: float) -> SoulsBanner:
	var b := SoulsBanner.new()
	b.title = t
	b.sub = s
	b.color = c
	b.hold = h
	host.get_tree().root.add_child(b)
	return b


func _ready() -> void:
	layer = 60
	process_mode = Node.PROCESS_MODE_ALWAYS
	var sf := SystemFont.new()
	sf.font_names = PackedStringArray(["Cinzel", "Trajan Pro", "Garamond", "Georgia", "Times New Roman", "Liberation Serif", "DejaVu Serif", "serif"])
	_font = sf
	_paint = Control.new()
	_paint.set_anchors_and_offsets_preset(Control.PRESET_FULL_RECT)
	_paint.mouse_filter = Control.MOUSE_FILTER_IGNORE
	add_child(_paint)
	_paint.draw.connect(_draw_banner)
	# A scene change takes the banner away with it
	get_tree().node_removed.connect(func(n: Node) -> void:
		if is_inside_tree() and n == get_tree().current_scene:
			queue_free())


func _process(delta: float) -> void:
	_t += delta
	if _t > FADE_IN + hold + FADE_OUT:
		finished.emit()
		queue_free()
		return
	_paint.queue_redraw()


func _alpha() -> float:
	if _t < FADE_IN:
		return _t / FADE_IN
	if _t < FADE_IN + hold:
		return 1.0
	return clampf(1.0 - (_t - FADE_IN - hold) / FADE_OUT, 0.0, 1.0)


func _draw_banner() -> void:
	var c := _paint
	var sz := c.size
	var a := _alpha()
	var mid := sz.y * 0.5
	var band := 150.0
	# Dark band, soft at the top and bottom edges
	for i in 12:
		var k := float(i) / 11.0
		var h := band * (1.0 - k * 0.5)
		c.draw_rect(Rect2(0, mid - h * 0.5, sz.x, h), Color(0, 0, 0, 0.11 * a))
	# Title: big, letter-spaced, growing a little while it shows
	var fs := int(clampf(sz.y * 0.11, 48.0, 96.0) * (1.0 + 0.04 * clampf(_t / (FADE_IN + hold), 0.0, 1.0)))
	var spaced := " ".join(title.split(""))                 # Wide letter spacing
	var w := _font.get_string_size(spaced, HORIZONTAL_ALIGNMENT_LEFT, -1, fs).x
	if w > sz.x * 0.9:                                      # Narrow screens (phones): shrink to fit
		fs = int(float(fs) * sz.x * 0.9 / w)
		w = _font.get_string_size(spaced, HORIZONTAL_ALIGNMENT_LEFT, -1, fs).x
	var pos := Vector2((sz.x - w) * 0.5, mid + fs * 0.32)
	c.draw_string(_font, pos + Vector2(0, 3), spaced, HORIZONTAL_ALIGNMENT_LEFT, -1, fs, Color(0, 0, 0, 0.6 * a))
	c.draw_string(_font, pos, spaced, HORIZONTAL_ALIGNMENT_LEFT, -1, fs, Color(color.r, color.g, color.b, a))
	if sub != "":
		var ss := 20
		var sw := _font.get_string_size(sub, HORIZONTAL_ALIGNMENT_LEFT, -1, ss).x
		c.draw_string(_font, Vector2((sz.x - sw) * 0.5, mid + band * 0.42), sub, HORIZONTAL_ALIGNMENT_LEFT, -1, ss, Color(0.9, 0.86, 0.78, 0.9 * a))
