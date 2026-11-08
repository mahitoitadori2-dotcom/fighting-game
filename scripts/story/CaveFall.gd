class_name CaveFall
extends CanvasLayer
## Between levels: the Warrior FALLS deeper into the caves. Full-screen animation:
## rock walls rush upward, embers streak past, the hero tumbles in the middle,
## then the screen goes black and `finished` fires (StoryManager loads the next level).

signal finished

const DURATION := 2.4

var player: Fighter                  # Drawn falling (its own art)
var hero_art: Script                 # ...or an art script with static draw_portrait(c, t) (from the board)
var caption := ""

var _painter: Control
var _t := 0.0
var _rocks: Array[Vector4] = []      # side (-1/1), y, width, length


func _ready() -> void:
	layer = 40
	process_mode = Node.PROCESS_MODE_ALWAYS
	_painter = Control.new()
	_painter.set_anchors_and_offsets_preset(Control.PRESET_FULL_RECT)
	_painter.mouse_filter = Control.MOUSE_FILTER_STOP     # Block clicks while falling
	add_child(_painter)
	_painter.draw.connect(_paint)
	var rng := RandomNumberGenerator.new()
	rng.randomize()
	for i in 26:
		_rocks.append(Vector4(-1.0 if i % 2 == 0 else 1.0, rng.randf() * 1400.0, rng.randf_range(60.0, 220.0), rng.randf_range(40.0, 140.0)))
	SoundManager.play_sfx("dash")


func _process(delta: float) -> void:
	_t += delta
	_painter.queue_redraw()
	if _t >= DURATION:
		set_process(false)
		finished.emit()


func _paint() -> void:
	var sz := _painter.size
	var k := _t / DURATION
	var fade_in := clampf(_t / 0.35, 0.0, 1.0)
	var speed := 900.0 + 1600.0 * k                         # Falling faster and faster
	# Shaft background
	_painter.draw_rect(Rect2(Vector2.ZERO, sz), Color(0.05, 0.02, 0.02, fade_in))
	_painter.draw_rect(Rect2(sz.x * 0.25, 0, sz.x * 0.5, sz.y), Color(0.14, 0.05, 0.03, fade_in))
	# Rock ledges rushing upward on both walls
	for r in _rocks:
		var y := fmod(r.y - _t * speed, 1400.0)
		if y < -200.0:
			y += 1400.0
		var x0 := 0.0 if r.x < 0.0 else sz.x
		var w := sz.x * 0.25 + r.z * 0.5
		var tip := Vector2(x0 + r.x * -w, y + r.w * 0.5)
		_painter.draw_colored_polygon(PackedVector2Array([Vector2(x0, y), tip, Vector2(x0, y + r.w)]), Color(0.10, 0.06, 0.05, fade_in))
		_painter.draw_line(Vector2(x0, y), tip, Color(1.0, 0.45, 0.1, 0.4 * fade_in), 2.0)
	# Speed streaks + embers
	for i in 14:
		var sx := sz.x * (0.28 + 0.44 * fmod(float(i) * 0.618, 1.0))
		var sy := fmod(float(i) * 173.0 - _t * speed * 1.3, sz.y + 200.0)
		if sy < -200.0:
			sy += sz.y + 200.0
		_painter.draw_line(Vector2(sx, sy), Vector2(sx, sy + 80.0), Color(1.0, 0.6, 0.2, 0.5 * fade_in), 2.0)
	# The hero tumbling down the middle
	var has_player := player != null and is_instance_valid(player)
	if has_player or hero_art != null:
		var c := Vector2(sz.x * 0.5, sz.y * 0.45 + sin(_t * 6.0) * 10.0)
		_painter.draw_set_transform(c + Vector2(0, 64), sin(_t * 5.0) * 0.6, Vector2(1.4, 1.4))
		if has_player:
			player.draw_model_on(_painter)
		else:
			hero_art.call("draw_portrait", _painter, _t)
		_painter.draw_set_transform(Vector2.ZERO, 0.0, Vector2.ONE)
	# Caption
	if caption != "":
		FighterArt.label(_painter, Vector2(sz.x * 0.5, sz.y * 0.82), caption, 34, Color(1.0, 0.75, 0.35, fade_in))
	# Fade to black at the end
	var out := clampf((_t - (DURATION - 0.5)) / 0.5, 0.0, 1.0)
	if out > 0.0:
		_painter.draw_rect(Rect2(Vector2.ZERO, sz), Color(0, 0, 0, out))
