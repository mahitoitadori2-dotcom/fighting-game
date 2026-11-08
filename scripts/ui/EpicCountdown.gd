class_name EpicCountdown
extends CanvasLayer
## EPIC match start:  3 ... 2 ... 1 ... GO!
## Each number SLAMS in from huge to normal size (zoom + screen shake + white flash +
## speed lines + a heavy drum hit), then GO! EXPLODES: big flash, shockwave rings,
## light rays, camera shake and a crash sound. Emits `go` the moment GO! hits
## (MatchManager unfreezes the fighters there).
## Runs on REAL time (ignores hitstop / Engine.time_scale), draws in screen space.

signal go
signal finished

const STEP := 0.72                       # Seconds per number
const SLAM := 0.17                       # Zoom-in time of a number
const GO_HOLD := 0.75
const GO_OUT := 0.35
const COLORS := [Color(1.0, 0.25, 0.2), Color(1.0, 0.6, 0.15), Color(1.0, 0.9, 0.2)]
const GO_COLOR := Color(1.0, 0.85, 0.25)

var _painter: Node2D
var _t := 0.0
var _running := false
var _index := -1                         # 0,1,2 = 3,2,1   3 = GO!
var _go_fired := false
var _font: Font


func _ready() -> void:
	layer = 16
	process_mode = Node.PROCESS_MODE_ALWAYS
	_font = ThemeDB.fallback_font
	_painter = Node2D.new()
	add_child(_painter)
	_painter.draw.connect(_paint)
	set_process(false)


func start() -> void:
	_t = 0.0
	_index = -1
	_running = true
	set_process(true)


func _process(_delta: float) -> void:
	if not _running:
		return
	_t += get_process_delta_time() / maxf(Engine.time_scale, 0.0001)   # Real seconds
	var idx := mini(int(_t / STEP), 3)
	if idx != _index:
		_index = idx
		_on_beat(idx)
	if _index == 3 and _t - 3.0 * STEP > GO_HOLD + GO_OUT:
		_running = false
		finished.emit()
		queue_free()
		return
	_painter.queue_redraw()


func _on_beat(idx: int) -> void:
	if idx < 3:
		SoundManager.play_sfx("count_tick", 0.0, 0.0)
		_shake(7.0 + float(idx) * 3.0)
	else:
		SoundManager.play_sfx("count_go", 2.0, 0.0)
		_shake(22.0)
		if not _go_fired:
			_go_fired = true
			go.emit()


func _shake(s: float) -> void:
	var p := get_parent()
	if p != null and p.is_inside_tree():
		Effects.shake(p, s)


# ============================================================
# DRAW
# ============================================================
func _paint() -> void:
	var vp := _painter.get_viewport_rect().size
	var c := vp * 0.5
	if _index < 0:
		return
	var lt := _t - float(_index) * STEP           # Time inside this beat
	if _index < 3:
		_paint_number(vp, c, lt)
	else:
		_paint_go(vp, c, lt)


func _paint_number(vp: Vector2, c: Vector2, lt: float) -> void:
	var col: Color = COLORS[_index]
	var txt := str(3 - _index)
	var k := clampf(lt / SLAM, 0.0, 1.0)
	var ease_k := 1.0 - pow(1.0 - k, 3.0)
	var zoom := lerpf(3.4, 1.0, ease_k)
	if k >= 1.0:
		zoom = 1.0 - 0.08 * clampf((lt - SLAM) / (STEP - SLAM), 0.0, 1.0)   # Slow push back
	var alpha := clampf(lt / 0.06, 0.0, 1.0) * (1.0 - clampf((lt - (STEP - 0.12)) / 0.12, 0.0, 1.0))
	# Dark band across the screen (Smash-style stage card)
	var band_h := 230.0 * minf(1.0, lt / 0.1)
	_painter.draw_rect(Rect2(0, c.y - band_h * 0.5, vp.x, band_h), Color(0, 0, 0, 0.45 * alpha))
	_painter.draw_rect(Rect2(0, c.y - band_h * 0.5, vp.x, 4), Color(col.r, col.g, col.b, 0.8 * alpha))
	_painter.draw_rect(Rect2(0, c.y + band_h * 0.5 - 4, vp.x, 4), Color(col.r, col.g, col.b, 0.8 * alpha))
	# Speed lines rushing to the centre while the number slams in
	if k < 1.0:
		for i in 18:
			var a := TAU * float(i) / 18.0 + float(_index)
			var r0 := vp.length() * 0.6 * (1.0 - ease_k) + 160.0
			_painter.draw_line(c + Vector2.from_angle(a) * r0, c + Vector2.from_angle(a) * (r0 + 220.0), Color(1, 1, 1, 0.5 * (1.0 - k)), 6.0)
	# Impact flash + ring right when it lands
	var since := lt - SLAM
	if since >= 0.0 and since < 0.25:
		var f := 1.0 - since / 0.25
		_painter.draw_rect(Rect2(Vector2.ZERO, vp), Color(1, 1, 1, 0.28 * f))
		_painter.draw_arc(c, 120.0 + since * 1400.0, 0.0, TAU, 64, Color(col.r, col.g, col.b, f), 12.0 * f + 2.0, true)
	_big_text(c, txt, 190, zoom, col, alpha)


func _paint_go(vp: Vector2, c: Vector2, lt: float) -> void:
	var k := clampf(lt / 0.15, 0.0, 1.0)
	var zoom := lerpf(0.3, 1.25, 1.0 - pow(1.0 - k, 3.0))
	if k >= 1.0:
		zoom = lerpf(1.25, 1.1, clampf((lt - 0.15) / 0.25, 0.0, 1.0))
	var alpha := 1.0
	if lt > GO_HOLD:
		var o := clampf((lt - GO_HOLD) / GO_OUT, 0.0, 1.0)
		zoom += o * 1.4                              # Blows out toward the camera
		alpha = 1.0 - o
	# Huge white flash
	if lt < 0.35:
		_painter.draw_rect(Rect2(Vector2.ZERO, vp), Color(1, 0.97, 0.85, 0.75 * (1.0 - lt / 0.35)))
	# Light rays bursting out
	var ray_a := alpha * (1.0 - clampf(lt / (GO_HOLD + GO_OUT), 0.0, 1.0) * 0.6)
	for i in 24:
		var a := TAU * float(i) / 24.0 + lt * 0.6
		var w := 0.06 if i % 2 == 0 else 0.03
		var r := vp.length() * (0.3 + 0.7 * minf(1.0, lt / 0.25))
		_painter.draw_colored_polygon(PackedVector2Array([c, c + Vector2.from_angle(a - w) * r, c + Vector2.from_angle(a + w) * r]),
			Color(GO_COLOR.r, GO_COLOR.g, GO_COLOR.b, 0.22 * ray_a))
	# Double shockwave
	for j in 2:
		var st := lt - float(j) * 0.08
		if st > 0.0 and st < 0.6:
			var f := 1.0 - st / 0.6
			_painter.draw_arc(c, 60.0 + st * 1800.0, 0.0, TAU, 72, Color(1, 1, 1, f), 18.0 * f + 2.0, true)
	# Sparks
	for i in 16:
		var a := TAU * float(i) / 16.0 + 0.3
		var d := 140.0 + lt * 900.0
		var p := c + Vector2.from_angle(a) * d
		_painter.draw_line(p, p + Vector2.from_angle(a) * 40.0, Color(1.0, 0.9, 0.5, alpha * clampf(1.0 - lt / 0.6, 0.0, 1.0)), 6.0)
	_big_text(c, "GO!", 230, zoom, GO_COLOR, alpha)


## Centered outlined text drawn at `size`, scaled around the screen centre.
func _big_text(c: Vector2, txt: String, size: int, zoom: float, col: Color, alpha: float) -> void:
	if alpha <= 0.0:
		return
	var w := _font.get_string_size(txt, HORIZONTAL_ALIGNMENT_LEFT, -1, size).x
	var asc := _font.get_ascent(size)
	var desc := _font.get_descent(size)
	var origin := Vector2(-w * 0.5, (asc - desc) * 0.5)
	_painter.draw_set_transform(c + Vector2(10, 12) * zoom, 0.0, Vector2.ONE * zoom)
	_painter.draw_string(_font, origin, txt, HORIZONTAL_ALIGNMENT_LEFT, -1, size, Color(0, 0, 0, 0.55 * alpha))   # Drop shadow
	_painter.draw_set_transform(c, 0.0, Vector2.ONE * zoom)
	_painter.draw_string_outline(_font, origin, txt, HORIZONTAL_ALIGNMENT_LEFT, -1, size, 26, Color(0, 0, 0, alpha))
	_painter.draw_string_outline(_font, origin, txt, HORIZONTAL_ALIGNMENT_LEFT, -1, size, 10, Color(1, 1, 1, alpha))
	_painter.draw_string(_font, origin, txt, HORIZONTAL_ALIGNMENT_LEFT, -1, size, Color(col.r, col.g, col.b, alpha))
	_painter.draw_set_transform(Vector2.ZERO, 0.0, Vector2.ONE)
