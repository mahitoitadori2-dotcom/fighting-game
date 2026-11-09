class_name C5Cutscenes
extends RefCounted
## COLOSSEUM 5 full-screen cutscenes (painted by StoryCutscene, which owns timing + captions):
##   "c5_intro"       the Warrior and the Architect side by side at a crossroads of ash; far away
##                    a mountain with a light on its peak
##   "mountain_climb" after Mother Nature: you climb the cliff, the cave near the top glows red
##                    (Satan's cave)
##   "reach_peak"     you pull yourself onto the peak above the clouds: The Sun descends
##   "fall_to_earth"  the end: The Consumer explodes in the sky, you fall through the clouds
##                    back down to Earth, the sky goes quiet

const KINDS := ["c5_intro", "mountain_climb", "reach_peak", "fall_to_earth"]


static func paint(p: Control, kind: String, sz: Vector2, k: float, t: float) -> void:
	match kind:
		"c5_intro":
			_intro(p, sz, k, t)
		"mountain_climb":
			_climb(p, sz, k, t)
		"reach_peak":
			_peak(p, sz, k, t)
		"fall_to_earth":
			_fall(p, sz, k, t)


static func _grad(p: Control, r: Rect2, top: Color, bottom: Color) -> void:
	p.draw_polygon(PackedVector2Array([r.position, Vector2(r.end.x, r.position.y), r.end, Vector2(r.position.x, r.end.y)]),
		PackedColorArray([top, top, bottom, bottom]))


static func _heroes(p: Control, pos: Vector2, s: float, t: float, rot: float = 0.0) -> void:
	p.draw_set_transform(pos + Vector2(-46.0 * s, 0), rot, Vector2(s, s))
	WarriorArt.draw_portrait(p, t)
	p.draw_set_transform(pos + Vector2(46.0 * s, 0), rot, Vector2(s, s))
	ArchitectArt.draw_portrait(p, t)
	p.draw_set_transform(Vector2.ZERO, 0.0, Vector2.ONE)


static func _mountain(p: Control, sz: Vector2, base_y: float, peak: Vector2, col: Color) -> void:
	p.draw_colored_polygon(PackedVector2Array([Vector2(peak.x - sz.x * 0.5, base_y), Vector2(peak.x - 120.0, peak.y + 140.0), peak,
		Vector2(peak.x + 90.0, peak.y + 120.0), Vector2(peak.x + sz.x * 0.45, base_y)]), col)


static func _intro(p: Control, sz: Vector2, k: float, t: float) -> void:
	_grad(p, Rect2(Vector2.ZERO, sz), Color(0.10, 0.02, 0.03), Color(0.65, 0.18, 0.06))
	var peak := Vector2(sz.x * 0.72, sz.y * 0.18)
	p.draw_circle(peak, 90.0 + 10.0 * sin(t * 2.0), Color(1.0, 0.95, 0.7, 0.18))
	p.draw_circle(peak, 22.0, Color(1.0, 0.97, 0.85, 0.9))
	_mountain(p, sz, sz.y * 0.8, peak + Vector2(0, 20), Color(0.12, 0.05, 0.05))
	for i in 7:                                                 # Thorn trees + the crossroads
		var x := sz.x * (0.05 + 0.14 * float(i))
		p.draw_line(Vector2(x, sz.y * 0.82), Vector2(x + sin(float(i)) * 20.0, sz.y * 0.55 - float(i % 3) * 30.0), Color(0.05, 0.02, 0.02), 7.0)
	p.draw_rect(Rect2(0, sz.y * 0.8, sz.x, sz.y * 0.2), Color(0.12, 0.08, 0.07))
	p.draw_colored_polygon(PackedVector2Array([Vector2(sz.x * 0.42, sz.y * 0.8), Vector2(sz.x * 0.58, sz.y * 0.8), Vector2(sz.x * 0.75, sz.y), Vector2(sz.x * 0.25, sz.y)]), Color(0.22, 0.16, 0.12))
	for i in 24:                                               # Falling ash
		var ax := fmod(float(i) * 97.0 + t * 12.0, sz.x)
		var ay := fmod(float(i) * 53.0 + t * 40.0, sz.y)
		p.draw_circle(Vector2(ax, ay), 2.0, Color(0.7, 0.65, 0.6, 0.5))
	var walk := clampf(k / 5.0, 0.0, 1.0)
	_heroes(p, Vector2(sz.x * (0.28 + 0.1 * walk), sz.y * 0.86), 1.4, t)


static func _climb(p: Control, sz: Vector2, k: float, t: float) -> void:
	var up := clampf(k / 7.0, 0.0, 1.0)
	_grad(p, Rect2(Vector2.ZERO, sz), Color(0.05, 0.05, 0.10).lerp(Color(0.15, 0.10, 0.18), up), Color(0.35, 0.40, 0.55))
	# The cliff face scrolls down as you climb
	var scroll := up * sz.y * 1.4
	p.draw_rect(Rect2(sz.x * 0.3, 0, sz.x * 0.5, sz.y), Color(0.22, 0.20, 0.22))
	for i in 14:
		var y := fmod(float(i) * 110.0 + scroll, sz.y + 110.0) - 60.0
		p.draw_line(Vector2(sz.x * 0.3, y), Vector2(sz.x * 0.8, y + 30.0), Color(0.12, 0.11, 0.13), 4.0)
		p.draw_rect(Rect2(sz.x * (0.35 + 0.08 * float(i % 5)), y, 26, 10), Color(0.32, 0.30, 0.32))   # Handholds
	# Snow blowing sideways
	for i in 40:
		var sx := fmod(float(i) * 61.0 - t * 220.0, sz.x + 40.0)
		if sx < 0.0:
			sx += sz.x + 40.0
		p.draw_line(Vector2(sx, fmod(float(i) * 37.0, sz.y)), Vector2(sx + 14.0, fmod(float(i) * 37.0, sz.y) + 2.0), Color(1, 1, 1, 0.6), 2.0)
	# The red-glowing cave near the top (appears as you get close)
	if up > 0.55:
		var a := clampf((up - 0.55) / 0.3, 0.0, 1.0)
		var cave := Vector2(sz.x * 0.55, sz.y * 0.18)
		p.draw_set_transform(cave, 0.0, Vector2(1.0, 0.7))
		p.draw_circle(Vector2.ZERO, 110.0, Color(1.0, 0.25, 0.05, 0.3 * a))
		p.draw_circle(Vector2.ZERO, 70.0, Color(0.1, 0.0, 0.0, a))
		p.draw_circle(Vector2.ZERO, 50.0, Color(1.0, 0.35, 0.05, 0.6 * a))
		p.draw_set_transform(Vector2.ZERO, 0.0, Vector2.ONE)
	var bob := sin(t * 6.0) * 6.0
	_heroes(p, Vector2(sz.x * 0.55, sz.y * 0.72 + bob), 1.2, t)


static func _peak(p: Control, sz: Vector2, k: float, t: float) -> void:
	_grad(p, Rect2(Vector2.ZERO, sz), Color(0.55, 0.75, 1.0), Color(1.0, 0.95, 0.85))
	for i in 7:                                                # Sea of clouds below
		var cx := fmod(float(i) * 240.0 + t * 15.0, sz.x + 300.0) - 150.0
		p.draw_set_transform(Vector2(cx, sz.y * 0.85), 0.0, Vector2(1.0, 0.35))
		p.draw_circle(Vector2.ZERO, 180.0, Color(1, 1, 1, 0.85))
	p.draw_set_transform(Vector2.ZERO, 0.0, Vector2.ONE)
	p.draw_colored_polygon(PackedVector2Array([Vector2(sz.x * 0.2, sz.y), Vector2(sz.x * 0.42, sz.y * 0.68), Vector2(sz.x * 0.62, sz.y * 0.7), Vector2(sz.x * 0.85, sz.y)]), Color(0.85, 0.80, 0.70))
	var climb := clampf(k / 2.5, 0.0, 1.0)
	_heroes(p, Vector2(sz.x * 0.5, sz.y * 0.7 + (1.0 - climb) * 120.0), 1.2, t)
	# The Sun descends, blinding
	var d := clampf((k - 2.6) / 2.6, 0.0, 1.0)
	if d > 0.0:
		var sc := Vector2(sz.x * 0.5, lerpf(-200.0, sz.y * 0.3, d))
		p.draw_circle(sc, 260.0 * d, Color(1, 1, 0.9, 0.35 * d))
		p.draw_set_transform(sc + Vector2(0, 170), 0.0, Vector2(0.8, 0.8))
		TheSun.draw_portrait(p, t)
		p.draw_set_transform(Vector2.ZERO, 0.0, Vector2.ONE)
		p.draw_rect(Rect2(Vector2.ZERO, sz), Color(1, 1, 0.95, clampf((k - 5.4) / 0.6, 0.0, 1.0)))


static func _fall(p: Control, sz: Vector2, k: float, t: float) -> void:
	var fall := clampf(k / 9.0, 0.0, 1.0)
	_grad(p, Rect2(Vector2.ZERO, sz), Color(1.0, 0.55, 0.15).lerp(Color(0.05, 0.06, 0.15), fall), Color(1.0, 0.8, 0.4).lerp(Color(0.15, 0.25, 0.45), fall))
	# The explosion above (shrinks as you fall away from it)
	var boom := Vector2(sz.x * 0.5, -sz.y * 0.1 - fall * sz.y * 0.6)
	for i in 5:
		p.draw_circle(boom, (420.0 - float(i) * 70.0) * (1.0 - fall * 0.6), Color(1.0, 0.6 + 0.08 * float(i), 0.2 + 0.1 * float(i), 0.25))
	# Clouds rushing up past you
	for i in 10:
		var cy := fmod(float(i) * 140.0 - k * 380.0, sz.y + 280.0)
		if cy < -140.0:
			cy += sz.y + 280.0
		p.draw_set_transform(Vector2(fmod(float(i) * 197.0, sz.x), cy), 0.0, Vector2(1.0, 0.4))
		p.draw_circle(Vector2.ZERO, 150.0, Color(1, 1, 1, 0.55 * (1.0 - fall * 0.5)))
	p.draw_set_transform(Vector2.ZERO, 0.0, Vector2.ONE)
	# Earth's curve coming up at the end
	if fall > 0.6:
		var e := (fall - 0.6) / 0.4
		p.draw_circle(Vector2(sz.x * 0.5, sz.y * (2.6 - e * 0.9)), sz.x * 1.2, Color(0.15, 0.35, 0.25))
		p.draw_arc(Vector2(sz.x * 0.5, sz.y * (2.6 - e * 0.9)), sz.x * 1.2, PI * 1.1, PI * 1.9, 48, Color(0.5, 0.8, 1.0, 0.6), 8.0)
	# Stars come out
	for i in 30:
		p.draw_circle(Vector2(fmod(float(i) * 131.0, sz.x), fmod(float(i) * 71.0, sz.y * 0.6)), 1.5, Color(1, 1, 1, clampf(fall * 1.5 - 0.5, 0.0, 1.0)))
	var spin := sin(t * 1.5) * 0.4
	_heroes(p, Vector2(sz.x * 0.5, sz.y * 0.52), 1.0, t, spin)
