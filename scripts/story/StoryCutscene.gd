class_name StoryCutscene
extends CanvasLayer
## FULL-SCREEN STORY CUTSCENES (drawn in code, like CaveFall). `finished` fires at the end.
## Any key / click / tap skips (after a short moment).
##
##   "elevator"     Colosseum 2 intro: you ride a platform elevator UP out of hell. Girders
##                  rush past, the lava falls away below, light grows above... and far
##                  below, a pair of huge eyes starts to glow (the Architect Chorus).
##   "sewer_fall"   The floor of the Enlightened city breaks: you fall into the sewers -
##                  wet bricks and pipes rushing past, green fog, a splash at the bottom.
##   "corpse_climb" After Blasphemy Caeser: the serpent's corpse crashes down into the chasm
##                  and becomes a stairway; you climb it to a shrine glowing at the top.

signal finished

const DURATION := {"elevator": 6.5, "sewer_fall": 3.4, "corpse_climb": 8.0, "throne_wake": 6.0, "cave_roll": 5.0, "void_fall": 3.6}
const MUSIC := {"elevator": "story_ascent", "sewer_fall": "story_sewers", "corpse_climb": "story_ascent",
	"throne_wake": "story_throne", "cave_roll": "story_darkcave", "void_fall": "story_void"}
## [start, end, title, subtitle]
const CAPTIONS := {
	"elevator": [[0.6, 3.2, "COLOSSEUM 2: THE ASCENT", ""], [3.4, 6.0, "THE ELEVATOR FROM HELL", "Up... out of the depths."]],
	"sewer_fall": [[0.5, 3.0, "THE SEWERS", "Down into the dark and the filth..."]],
	"corpse_climb": [[0.4, 2.8, "THE SERPENT FALLS", ""], [3.4, 7.6, "A STAIRWAY OF BONE", "You climb the corpse to the shrine above."]],
	"throne_wake": [[0.8, 3.0, "COLOSSEUM 3: THE BURNING CROWN", ""], [3.2, 5.6, "THE BURNING THRONE ROOM", "You wake up. The throne is empty... and everything is on fire."]],
	"cave_roll": [[0.6, 2.6, "COLOSSEUM 4: THE VOID BELOW", "You are the ARCHITECT now."], [2.8, 4.6, "THE OVERGROUND DARK CAVE", "Something crawls in the dark..."]],
	"void_fall": [[0.5, 3.2, "INTO THE VOID", "The floor is gone. Bones below. Nothing but dark."]],
}

var kind := "elevator"
var hero_art: Script = WarriorArt              # static draw_portrait(c, t)

var _painter: Control
var _t := 0.0
var _len := 4.0
var _done := false


func _ready() -> void:
	layer = 40
	process_mode = Node.PROCESS_MODE_ALWAYS
	_len = float(DURATION.get(kind, 4.0))
	if StoryManager.autoplay:
		_len = minf(_len, 2.0)                    # Tests: keep it short
	_painter = Control.new()
	_painter.set_anchors_and_offsets_preset(Control.PRESET_FULL_RECT)
	_painter.mouse_filter = Control.MOUSE_FILTER_STOP
	add_child(_painter)
	_painter.draw.connect(_paint)
	var m := String(MUSIC.get(kind, ""))
	if m != "":
		SoundManager.play_music(m)
	match kind:
		"elevator":
			SoundManager.play_sfx("chain", -6.0)
			SoundManager.play_sfx("rumble", -8.0)
		"sewer_fall":
			SoundManager.play_sfx("stone", -2.0)
			SoundManager.play_sfx("dash")
		"corpse_climb":
			SoundManager.play_sfx("rumble")
		"throne_wake":
			SoundManager.play_sfx("flame", -4.0)
		"cave_roll":
			SoundManager.play_sfx("stone", -4.0)
		"void_fall":
			SoundManager.play_sfx("dash")
			SoundManager.play_sfx("void_goo", -4.0)


func _input(event: InputEvent) -> void:
	if _done or _t < 0.6:
		return
	var skip: bool = (event is InputEventKey and event.pressed and not event.echo) \
		or (event is InputEventMouseButton and event.pressed) \
		or (event is InputEventJoypadButton and event.pressed) \
		or (event is InputEventScreenTouch and event.pressed)
	if skip:
		get_viewport().set_input_as_handled()
		_finish()


func _process(delta: float) -> void:
	_last_t = _t
	_t += delta
	_painter.queue_redraw()
	# One-shot sounds along the way
	match kind:
		"sewer_fall":
			if _cross(2.6):
				SoundManager.play_sfx("splash")
				SoundManager.play_sfx("explosion", -10.0)
		"corpse_climb":
			if _cross(1.6):
				SoundManager.play_sfx("slam")
				SoundManager.play_sfx("explosion", -6.0)
			if _cross(6.6):
				SoundManager.play_sfx("holy")
		"elevator":
			if _cross(4.6):
				SoundManager.play_sfx("rumble", -4.0)
	if _t >= _len:
		_finish()


var _last_t := 0.0


## True on the frame the cutscene time passes `at` (scaled when shortened for tests).
func _cross(at: float) -> bool:
	var scaled := at * _len / float(DURATION.get(kind, _len))
	return _last_t < scaled and _t >= scaled


func _finish() -> void:
	if _done:
		return
	_done = true
	set_process(false)
	finished.emit()


func _paint() -> void:
	var sz := _painter.size
	var k := _t * float(DURATION.get(kind, _len)) / _len          # Story time (tests run it faster)
	match kind:
		"sewer_fall":
			_paint_sewer_fall(sz, k)
		"corpse_climb":
			_paint_corpse_climb(sz, k)
		"throne_wake":
			_paint_throne_wake(sz, k)
		"cave_roll":
			_paint_cave_roll(sz, k)
		"void_fall":
			_paint_void_fall(sz, k)
		_:
			_paint_elevator(sz, k)
	# Captions
	for cap in CAPTIONS.get(kind, []):
		var a := clampf((k - float(cap[0])) / 0.4, 0.0, 1.0) * (1.0 - clampf((k - float(cap[1]) + 0.4) / 0.4, 0.0, 1.0))
		if a <= 0.0:
			continue
		FighterArt.label(_painter, Vector2(sz.x * 0.5, sz.y * 0.16), String(cap[2]), 44, Color(1.0, 0.85, 0.5, a))
		if String(cap[3]) != "":
			FighterArt.label(_painter, Vector2(sz.x * 0.5, sz.y * 0.16 + 40.0), String(cap[3]), 22, Color(1, 1, 1, 0.85 * a))
	if _t > 0.8 and not StoryManager.autoplay:
		FighterArt.label(_painter, Vector2(sz.x - 120.0, sz.y - 18.0), "any key = skip", 13, Color(1, 1, 1, 0.35))
	# Fade in / out
	var total := float(DURATION.get(kind, _len))
	var fade := maxf(1.0 - clampf(k / 0.4, 0.0, 1.0), clampf((k - (total - 0.6)) / 0.6, 0.0, 1.0))
	if fade > 0.0:
		_painter.draw_rect(Rect2(Vector2.ZERO, sz), Color(0, 0, 0, fade))


func _hero(p: Vector2, scale_v: float, rot: float = 0.0) -> void:
	_painter.draw_set_transform(p, rot, Vector2(scale_v, scale_v))
	hero_art.call("draw_portrait", _painter, _t)
	_painter.draw_set_transform(Vector2.ZERO, 0.0, Vector2.ONE)


func _vgrad(r: Rect2, top: Color, bottom: Color) -> void:
	_painter.draw_polygon(PackedVector2Array([r.position, Vector2(r.end.x, r.position.y), r.end, Vector2(r.position.x, r.end.y)]),
		PackedColorArray([top, top, bottom, bottom]))


# ============================================================
# ELEVATOR FROM HELL
# ============================================================
func _paint_elevator(sz: Vector2, k: float) -> void:
	var p := _painter
	var rise := k / float(DURATION["elevator"])                      # 0 -> 1 over the ride
	# Shaft: hell-red below, cold darkness above, light growing at the top
	_vgrad(Rect2(Vector2.ZERO, sz), Color(0.03, 0.03, 0.05).lerp(Color(0.2, 0.18, 0.22), rise), Color(0.35, 0.06, 0.03).lerp(Color(0.05, 0.03, 0.04), rise))
	p.draw_circle(Vector2(sz.x * 0.5, -sz.y * 0.3), sz.y * (0.4 + 0.5 * rise), Color(0.9, 0.9, 1.0, 0.06 + 0.12 * rise))
	# Lava far below, falling away
	var lava_y := sz.y * 0.82 + rise * sz.y * 1.2
	if lava_y < sz.y + 40.0:
		p.draw_rect(Rect2(0, lava_y, sz.x, sz.y), Color(0.9, 0.3, 0.05))
		for i in 10:
			p.draw_circle(Vector2(fmod(float(i) * 173.0 + k * 30.0, sz.x), lava_y + 6.0), 20.0, Color(1.0, 0.6, 0.15, 0.7))
	# The two shaft walls with girders rushing DOWN (we go up)
	var speed := 260.0 + 140.0 * rise
	for side in [0, 1]:
		var x0 := 0.0 if side == 0 else sz.x * 0.8
		p.draw_rect(Rect2(x0, 0, sz.x * 0.2, sz.y), Color(0.10, 0.10, 0.12))
		var gap := 160.0
		for i in int(sz.y / gap) + 2:
			var y := fmod(float(i) * gap + k * speed, sz.y + gap) - gap
			p.draw_rect(Rect2(x0, y, sz.x * 0.2, 22.0), Color(0.22, 0.20, 0.20))
			p.draw_line(Vector2(x0, y), Vector2(x0 + sz.x * 0.2, y + gap), Color(0.16, 0.15, 0.15), 6.0)       # Cross brace
			p.draw_circle(Vector2(x0 + sz.x * (0.17 if side == 0 else 0.03), y + 11.0), 5.0, Color(1.0, 0.5, 0.15, 0.8))   # Warning lamp
		p.draw_line(Vector2(sz.x * (0.2 if side == 0 else 0.8), 0), Vector2(sz.x * (0.2 if side == 0 else 0.8), sz.y), Color(0, 0, 0), 6.0)
	# Embers / sparks falling past
	for i in 24:
		var ex := sz.x * (0.22 + 0.56 * fmod(float(i) * 0.618, 1.0))
		var ey := fmod(float(i) * 97.0 + k * speed * 1.6, sz.y + 60.0) - 30.0
		p.draw_line(Vector2(ex, ey), Vector2(ex, ey - 16.0), Color(1.0, 0.6, 0.25, 0.5 * (1.0 - rise * 0.6)), 2.0)
	# THE EYES far below (foreshadowing the Architect Chorus)
	if k > 4.2:
		var e := clampf((k - 4.2) / 1.2, 0.0, 1.0)
		for ex in [-60.0, -20.0, 20.0, 60.0]:
			p.draw_circle(Vector2(sz.x * 0.5 + ex * 1.6, sz.y * 0.97), 16.0 * e, Color(0.35, 0.9, 1.0, 0.25 * e))
			p.draw_circle(Vector2(sz.x * 0.5 + ex * 1.6, sz.y * 0.97), 6.0 * e, Color(0.85, 1.0, 1.0, e))
	# The platform (static on screen) with its cables
	var py := sz.y * 0.68 + sin(k * 3.0) * 3.0
	var pw := sz.x * 0.46
	var px := sz.x * 0.5 - pw * 0.5
	for cx in [px + 20.0, px + pw - 20.0]:
		p.draw_line(Vector2(cx, py), Vector2(cx, -10.0), Color(0, 0, 0), 7.0)
		p.draw_line(Vector2(cx, py), Vector2(cx, -10.0), Color(0.45, 0.45, 0.5), 3.0)
	p.draw_rect(Rect2(px, py, pw, 34.0), Color(0.32, 0.33, 0.36))
	p.draw_rect(Rect2(px, py + 34.0, pw, 18.0), Color(0.18, 0.18, 0.2))
	var stripe := 0.0
	while stripe < pw:                                               # Hazard stripes on the lip
		p.draw_colored_polygon(PackedVector2Array([Vector2(px + stripe, py + 34.0), Vector2(px + stripe + 16.0, py + 34.0),
			Vector2(px + stripe + 8.0, py + 52.0), Vector2(px + stripe - 8.0, py + 52.0)]), Color(0.95, 0.75, 0.1))
		stripe += 32.0
	p.draw_rect(Rect2(px, py, pw, 52.0), Color(0, 0, 0), false, 4.0)
	_hero(Vector2(sz.x * 0.5, py), 1.5)


# ============================================================
# COLOSSEUM 3: WAKING UP IN THE BURNING THRONE ROOM
# ============================================================
func _paint_throne_wake(sz: Vector2, k: float) -> void:
	var p := _painter
	var wake := clampf(k / 2.5, 0.0, 1.0)                           # Eyes opening: the view brightens
	_vgrad(Rect2(Vector2.ZERO, sz), Color(0.12, 0.04, 0.02), Color(0.55, 0.18, 0.04))
	# The empty throne in the back, burning
	var tc := Vector2(sz.x * 0.62, sz.y * 0.72)
	p.draw_rect(Rect2(tc.x - 130, tc.y, 260, 26), Color(0.22, 0.10, 0.06))
	p.draw_colored_polygon(PackedVector2Array([tc + Vector2(-50, 0), tc + Vector2(-50, -170), tc + Vector2(-24, -210), tc + Vector2(0, -186),
		tc + Vector2(24, -210), tc + Vector2(50, -170), tc + Vector2(50, 0)]), Color(0.30, 0.12, 0.06))
	p.draw_rect(Rect2(tc.x - 30, tc.y - 160, 60, 80), Color(0.45, 0.06, 0.06))
	# Flames everywhere (flickering)
	for i in 14:
		var fx := sz.x * (0.04 + 0.07 * float(i))
		var fh := 70.0 + 50.0 * absf(sin(_t * 3.0 + float(i) * 1.7))
		var fy := sz.y * 0.82
		p.draw_colored_polygon(PackedVector2Array([Vector2(fx - 26, fy), Vector2(fx - 8, fy - fh * 0.6), Vector2(fx, fy - fh), Vector2(fx + 10, fy - fh * 0.5), Vector2(fx + 26, fy)]), Color(1.0, 0.35, 0.05, 0.85))
		p.draw_colored_polygon(PackedVector2Array([Vector2(fx - 12, fy), Vector2(fx, fy - fh * 0.55), Vector2(fx + 12, fy)]), Color(1.0, 0.85, 0.35, 0.9))
	# Smoke rolling under the ceiling
	for i in 6:
		var sx := fmod(float(i) * 260.0 + _t * 30.0, sz.x + 300.0) - 150.0
		p.draw_set_transform(Vector2(sx, sz.y * 0.12), 0.0, Vector2(1.0, 0.35))
		p.draw_circle(Vector2.ZERO, 160.0, Color(0.06, 0.04, 0.04, 0.55))
	p.draw_set_transform(Vector2.ZERO, 0.0, Vector2.ONE)
	# Embers falling
	for i in 30:
		var ex := fmod(float(i) * 97.0, sz.x)
		var ey := fmod(float(i) * 53.0 + _t * (40.0 + float(i % 5) * 12.0), sz.y)
		p.draw_circle(Vector2(ex + sin(_t + float(i)) * 10.0, ey), 2.0 + float(i % 3), Color(1.0, 0.6, 0.2, 0.8))
	# The floor + the hero lying down, then getting up
	p.draw_rect(Rect2(0, sz.y * 0.82, sz.x, sz.y * 0.18), Color(0.18, 0.09, 0.06))
	var up := clampf((k - 3.0) / 1.0, 0.0, 1.0)
	_hero(Vector2(sz.x * 0.3, sz.y * 0.82), 1.4, lerpf(-PI * 0.5, 0.0, up))
	# Blinking eyelids at the start
	var lid := (1.0 - wake) * sz.y * 0.5
	if lid > 1.0:
		p.draw_rect(Rect2(0, 0, sz.x, lid), Color(0, 0, 0))
		p.draw_rect(Rect2(0, sz.y - lid, sz.x, lid), Color(0, 0, 0))


# ============================================================
# COLOSSEUM 4: THE ARCHITECT ROLLS INTO THE CAVE
# ============================================================
func _paint_cave_roll(sz: Vector2, k: float) -> void:
	var p := _painter
	var total := float(DURATION["cave_roll"])
	_vgrad(Rect2(Vector2.ZERO, sz), Color(0.35, 0.40, 0.48), Color(0.20, 0.22, 0.25))
	# Hillside sloping down into a dark cave mouth on the right
	var slope := PackedVector2Array([Vector2(0, sz.y * 0.45), Vector2(sz.x * 0.62, sz.y * 0.82), Vector2(sz.x, sz.y * 0.82), Vector2(sz.x, sz.y), Vector2(0, sz.y)])
	p.draw_colored_polygon(slope, Color(0.16, 0.16, 0.17))
	var mouth := Vector2(sz.x * 0.8, sz.y * 0.82)
	p.draw_colored_polygon(PackedVector2Array([mouth + Vector2(-140, 0), mouth + Vector2(-110, -180), mouth + Vector2(0, -240), mouth + Vector2(120, -190), mouth + Vector2(160, 0)]), Color(0.08, 0.08, 0.09))
	p.draw_colored_polygon(PackedVector2Array([mouth + Vector2(-100, 0), mouth + Vector2(-80, -150), mouth + Vector2(0, -190), mouth + Vector2(90, -150), mouth + Vector2(110, 0)]), Color(0.01, 0.01, 0.015))
	for i in 5:                                                   # Rocks bouncing along
		var rx := fmod(float(i) * 180.0 + k * 220.0, sz.x * 0.7)
		var ry := sz.y * 0.45 + (rx / (sz.x * 0.62)) * sz.y * 0.37
		p.draw_circle(Vector2(rx, ry - 8), 6.0, Color(0.3, 0.3, 0.32))
	# The ARCHITECT tumbling down the slope, spinning, into the cave
	var u := clampf(k / (total * 0.75), 0.0, 1.0)
	var start := Vector2(sz.x * 0.05, sz.y * 0.45)
	var end := mouth + Vector2(-10, 0)
	var hp := start.lerp(end, u) + Vector2(0, -absf(sin(u * PI * 5.0)) * 40.0)
	var into := clampf((k - total * 0.75) / (total * 0.15), 0.0, 1.0)
	if into < 1.0:
		_hero(hp, 1.0 * (1.0 - into * 0.6), u * TAU * 3.0)
	# Dust puffs behind
	for i in 4:
		var du := u - float(i) * 0.05
		if du > 0.0:
			var dp := start.lerp(end, du)
			p.draw_circle(dp, 14.0 + float(i) * 6.0, Color(0.5, 0.5, 0.52, 0.3 - float(i) * 0.06))
	# Darkness swallows the screen at the end
	if into > 0.0:
		p.draw_rect(Rect2(Vector2.ZERO, sz), Color(0, 0, 0, into * 0.9))


# ============================================================
# COLOSSEUM 4: FALLING INTO THE VOID
# ============================================================
func _paint_void_fall(sz: Vector2, k: float) -> void:
	var p := _painter
	_vgrad(Rect2(Vector2.ZERO, sz), Color(0.0, 0.0, 0.01), Color(0.08, 0.02, 0.14))
	var speed := 700.0 + 900.0 * (k / float(DURATION["void_fall"]))
	# Broken floor chunks falling with you
	for i in 10:
		var cx := sz.x * fmod(float(i) * 0.37 + 0.1, 1.0)
		var cy := fmod(float(i) * 120.0 - k * speed * 0.4, sz.y + 200.0)
		if cy < -100.0:
			cy += sz.y + 200.0
		var r := 16.0 + float(i % 4) * 8.0
		p.draw_colored_polygon(PackedVector2Array([Vector2(cx - r, cy), Vector2(cx, cy - r * 0.8), Vector2(cx + r, cy - r * 0.2), Vector2(cx + r * 0.6, cy + r * 0.7)]), Color(0.12, 0.12, 0.13))
	# Bones and skulls rushing UP past you (you fall fast)
	for i in 16:
		var bx := sz.x * fmod(float(i) * 0.618, 1.0)
		var by := fmod(float(i) * 97.0 - k * speed, sz.y + 120.0)
		if by < -60.0:
			by += sz.y + 120.0
		if i % 3 == 0:
			p.draw_circle(Vector2(bx, by), 10.0, Color(0.32, 0.30, 0.36))
			p.draw_circle(Vector2(bx - 3, by - 1), 2.5, Color(0, 0, 0))
			p.draw_circle(Vector2(bx + 3, by - 1), 2.5, Color(0, 0, 0))
		else:
			p.draw_line(Vector2(bx - 14, by), Vector2(bx + 14, by + 6), Color(0.32, 0.30, 0.36), 5.0)
	# Purple void streaks
	for i in 10:
		var sx := sz.x * (0.2 + 0.6 * fmod(float(i) * 0.41, 1.0))
		var sy := fmod(float(i) * 173.0 - k * speed * 1.3, sz.y + 200.0)
		if sy < -200.0:
			sy += sz.y + 200.0
		p.draw_line(Vector2(sx, sy), Vector2(sx, sy + 90.0), Color(0.6, 0.3, 1.0, 0.4), 2.0)
	_hero(Vector2(sz.x * 0.5, sz.y * 0.45 + sin(k * 6.0) * 10.0 + 64.0), 1.4, sin(k * 4.0) * 0.9)


# ============================================================
# FALLING INTO THE SEWERS
# ============================================================
func _paint_sewer_fall(sz: Vector2, k: float) -> void:
	var p := _painter
	var total := float(DURATION["sewer_fall"])
	var speed := 900.0 + 1300.0 * (k / total)
	_vgrad(Rect2(Vector2.ZERO, sz), Color(0.02, 0.04, 0.03), Color(0.05, 0.12, 0.07))
	# Brick shaft walls rushing up
	for side in [0, 1]:
		var x0 := 0.0 if side == 0 else sz.x * 0.72
		p.draw_rect(Rect2(x0, 0, sz.x * 0.28, sz.y), Color(0.10, 0.13, 0.10))
		var row := 0
		var y := -fmod(k * speed, 40.0)
		while y < sz.y:
			var off := 30.0 if row % 2 == 0 else 0.0
			var bx := x0 - off
			while bx < x0 + sz.x * 0.28:
				p.draw_rect(Rect2(bx + 2.0, y + 2.0, 56.0, 36.0), Color(0.16, 0.20, 0.15))
				bx += 60.0
			y += 40.0
			row += 1
		# Pipes passing by, dripping
		for i in 3:
			var py := fmod(float(i) * 320.0 - k * speed * 0.9, sz.y + 300.0)
			if py < -200.0:
				py += sz.y + 300.0
			var px0 := sz.x * (0.0 if side == 0 else 0.72)
			p.draw_rect(Rect2(px0, py, sz.x * 0.28, 30.0), Color(0.25, 0.30, 0.22))
			p.draw_rect(Rect2(px0, py, sz.x * 0.28, 30.0), Color(0, 0, 0), false, 3.0)
			p.draw_line(Vector2(px0 + sz.x * (0.25 if side == 0 else 0.03), py + 30.0), Vector2(px0 + sz.x * (0.25 if side == 0 else 0.03), py + 60.0), Color(0.5, 0.8, 0.4, 0.7), 4.0)
	# Green fog bands
	for i in 5:
		var fy := fmod(float(i) * 230.0 - k * speed * 0.6, sz.y + 300.0) - 100.0
		p.draw_set_transform(Vector2(sz.x * 0.5, fy), 0.0, Vector2(1.0, 0.25))
		p.draw_circle(Vector2.ZERO, sz.x * 0.4, Color(0.35, 0.7, 0.3, 0.12))
		p.draw_set_transform(Vector2.ZERO, 0.0, Vector2.ONE)
	# Water rushing up at the end, splash
	var water_k := clampf((k - 2.2) / 0.4, 0.0, 1.0)
	var water_y := sz.y * (1.0 - 0.35 * water_k)
	# The hero tumbling down
	var hy := sz.y * 0.42 + sin(k * 6.0) * 10.0
	if water_k < 1.0:
		_hero(Vector2(sz.x * 0.5, hy + 64.0), 1.4, sin(k * 5.0) * 0.8)
	if water_k > 0.0:
		p.draw_rect(Rect2(0, water_y, sz.x, sz.y), Color(0.12, 0.25, 0.14))
		p.draw_line(Vector2(0, water_y), Vector2(sz.x, water_y), Color(0.5, 0.8, 0.45), 4.0)
		if k > 2.6:
			var s := clampf((k - 2.6) / 0.6, 0.0, 1.0)
			for i in 9:                                        # Splash
				var a := PI + PI * (float(i) + 0.5) / 9.0
				var d := Vector2.from_angle(a) * (40.0 + 220.0 * s)
				p.draw_circle(Vector2(sz.x * 0.5, water_y) + d * Vector2(1.0, 1.4), 10.0 * (1.0 - s), Color(0.6, 0.9, 0.55, 1.0 - s))
			p.draw_set_transform(Vector2(sz.x * 0.5, water_y), 0.0, Vector2(1.0, 0.25))
			p.draw_arc(Vector2.ZERO, 40.0 + 260.0 * s, 0.0, TAU, 32, Color(0.7, 1.0, 0.65, 1.0 - s), 6.0, true)
			p.draw_set_transform(Vector2.ZERO, 0.0, Vector2.ONE)


# ============================================================
# THE CORPSE CLIMB (after Blasphemy Caeser)
# ============================================================
func _paint_corpse_climb(sz: Vector2, k: float) -> void:
	var p := _painter
	_vgrad(Rect2(Vector2.ZERO, sz), Color(0.10, 0.05, 0.08), Color(0.35, 0.08, 0.04))
	# Chasm cliffs
	p.draw_colored_polygon(PackedVector2Array([Vector2(0, 0), Vector2(sz.x * 0.16, 0), Vector2(sz.x * 0.2, sz.y * 0.5), Vector2(sz.x * 0.12, sz.y), Vector2(0, sz.y)]), Color(0.08, 0.04, 0.05))
	p.draw_colored_polygon(PackedVector2Array([Vector2(sz.x, 0), Vector2(sz.x * 0.72, 0), Vector2(sz.x * 0.70, sz.y * 0.16), Vector2(sz.x * 0.84, sz.y * 0.3),
		Vector2(sz.x * 0.8, sz.y), Vector2(sz.x, sz.y)]), Color(0.08, 0.04, 0.05))
	# Magma at the bottom
	p.draw_rect(Rect2(0, sz.y * 0.9, sz.x, sz.y * 0.1), Color(0.95, 0.4, 0.08))
	for i in 8:
		p.draw_circle(Vector2(fmod(float(i) * 211.0 + k * 20.0, sz.x), sz.y * 0.9), 16.0, Color(1.0, 0.7, 0.25, 0.6))
	# THE SHRINE at the top right (glows brighter as you get close)
	var shrine := Vector2(sz.x * 0.78, sz.y * 0.16)
	var glow := 0.3 + 0.7 * clampf((k - 3.0) / 4.0, 0.0, 1.0)
	p.draw_circle(shrine + Vector2(0, -40), 120.0 * glow + 20.0 * sin(_t * 2.0), Color(1.0, 0.85, 0.4, 0.15 * glow))
	p.draw_circle(shrine + Vector2(0, -40), 50.0, Color(1.0, 0.9, 0.55, 0.3 * glow))
	p.draw_rect(Rect2(shrine.x - 60, shrine.y - 6, 120, 14), Color(0.55, 0.5, 0.45))           # Steps
	for cx in [-40.0, 40.0]:                                                               # Pillars
		p.draw_rect(Rect2(shrine.x + cx - 8, shrine.y - 84, 16, 80), Color(0.75, 0.7, 0.62))
		p.draw_rect(Rect2(shrine.x + cx - 8, shrine.y - 84, 16, 80), Color(0, 0, 0), false, 3.0)
	p.draw_colored_polygon(PackedVector2Array([shrine + Vector2(-60, -84), shrine + Vector2(0, -122), shrine + Vector2(60, -84)]), Color(0.75, 0.7, 0.62))
	p.draw_circle(shrine + Vector2(0, -40), 14.0, Color(1.0, 0.95, 0.7, glow))               # The flame inside
	# The serpent's CORPSE: falls from the top-left and crashes into a slope up to the shrine
	var fall := clampf(k / 1.6, 0.0, 1.0)
	fall = fall * fall
	var low := Vector2(sz.x * 0.18, sz.y * 0.88)
	var high := shrine + Vector2(-80, 6)
	var drop := (1.0 - fall) * sz.y * 1.1
	var body := PackedVector2Array()
	for i in 13:
		var u := float(i) / 12.0
		var pt := low.lerp(high, u) + Vector2(0, sin(u * PI * 2.0) * 26.0 - drop * (1.0 - u * 0.4))
		body.append(pt)
	for i in body.size() - 1:                                     # Outline, scales, belly, magma going cold
		p.draw_line(body[i], body[i + 1], Color(0, 0, 0), 76.0)
	for i in body.size() - 1:
		var u := float(i) / 12.0
		p.draw_line(body[i], body[i + 1], Color(0.45, 0.07, 0.07).lerp(Color(0.3, 0.06, 0.06), u), 66.0)
		p.draw_line(body[i] + Vector2(0, 20), body[i + 1] + Vector2(0, 20), Color(0.75, 0.55, 0.34), 18.0)
		var cool := clampf((k - 2.0) / 3.0, 0.0, 1.0)
		p.draw_circle(body[i] + Vector2(0, -16), 7.0, Color(1.0, 0.45, 0.1, 0.8 * (1.0 - cool)))
	# Dead head lying at the bottom, crown fallen off
	var head := body[0] + Vector2(-40, 10)
	p.draw_colored_polygon(PackedVector2Array([head + Vector2(-70, -10), head + Vector2(0, -40), head + Vector2(50, -6), head + Vector2(0, 30), head + Vector2(-70, 20)]), Color(0.45, 0.07, 0.07))
	p.draw_line(head + Vector2(-50, -6), head + Vector2(-36, 6), Color(0, 0, 0), 4.0)              # X eye
	p.draw_line(head + Vector2(-50, 6), head + Vector2(-36, -6), Color(0, 0, 0), 4.0)
	# Impact dust
	if k > 1.6 and k < 3.2:
		var d := clampf((k - 1.6) / 1.6, 0.0, 1.0)
		for i in 10:
			var a := PI + PI * float(i) / 9.0
			p.draw_circle(low.lerp(high, 0.3) + Vector2.from_angle(a) * (60.0 + 260.0 * d), 30.0 * (1.0 - d), Color(0.4, 0.3, 0.28, 0.5 * (1.0 - d)))
	# The hero climbing the corpse to the shrine
	var climb := clampf((k - 2.8) / 4.2, 0.0, 1.0)
	var idx := climb * 12.0
	var i0 := mini(int(idx), 11)
	var hp := body[i0].lerp(body[i0 + 1], idx - float(i0)) + Vector2(0, -34)
	if climb >= 1.0:
		hp = shrine + Vector2(-30, 0)
	var step := absf(sin(_t * 8.0)) * 4.0 * (1.0 if climb > 0.0 and climb < 1.0 else 0.0)
	_hero(hp + Vector2(0, -step), 0.9)
