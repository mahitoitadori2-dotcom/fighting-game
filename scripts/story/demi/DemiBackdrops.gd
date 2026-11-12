class_name DemiBackdrops
extends RefCounted
## DEMILAND backdrops, painted by HellBackground (far landscape behind the open world; each
## is also a Versus map). A DARK land: an ash-grey sky with a dim hidden sun, dead trees.
## The night (darker than dark) is laid on top by DemiLand.
##   "demi_plains"   the Dead Plains: flat ash fields, far dead forests, broken mountains
##   "demi_village"  the Tribe Village: huts on a hill, smoke columns, totems, fire glow
##   "demi_ravine"   the Tiger Ravine: cliff walls, a giant tiger skull on the rocks, orange dust
##   "demi_grove"    the Dead Grove: colossal dead trunks in mist, ONE faintly alive (green)
##   "demi_door"     the Ancient Door: a colossal ruined monolith, faint violet runes

const THEMES := ["demi_plains", "demi_village", "demi_ravine", "demi_grove", "demi_door"]
const SKY_TOP := Color(0.10, 0.10, 0.12)
const SKY_LOW := Color(0.26, 0.24, 0.25)


static func handles(theme: String) -> bool:
	return THEMES.has(theme)


static func paint(p: Control, theme: String, sz: Vector2) -> void:
	_sky(p, sz, theme)
	match theme:
		"demi_plains":
			_mountains(p, sz, sz.y * 0.55, 90.0, Color(0.13, 0.12, 0.14), 11)
			_forest(p, sz, sz.y * 0.68, 70.0, Color(0.09, 0.085, 0.10), 31, 26)
			_ground(p, sz, sz.y * 0.74, Color(0.11, 0.10, 0.11))
			_forest(p, sz, sz.y * 0.80, 130.0, Color(0.05, 0.05, 0.06), 47, 9)
		"demi_village":
			_mountains(p, sz, sz.y * 0.56, 70.0, Color(0.14, 0.12, 0.13), 5)
			var hill := sz.y * 0.70
			p.draw_colored_polygon(PackedVector2Array([Vector2(0, sz.y), Vector2(0, hill), Vector2(sz.x * 0.3, hill - 60.0), Vector2(sz.x * 0.62, hill - 40.0),
				Vector2(sz.x, hill + 10.0), Vector2(sz.x, sz.y)]), Color(0.09, 0.08, 0.08))
			for i in 7:                                            # Huts + smoke columns + fire glow
				var hx := sz.x * (0.12 + 0.12 * float(i))
				var hy := hill - 50.0 + sin(float(i) * 1.3) * 12.0
				p.draw_circle(Vector2(hx, hy), 40.0, Color(1.0, 0.4, 0.1, 0.06))
				p.draw_colored_polygon(PackedVector2Array([Vector2(hx - 34, hy), Vector2(hx, hy - 46), Vector2(hx + 34, hy)]), Color(0.06, 0.05, 0.05))
				p.draw_rect(Rect2(hx - 26, hy, 52, 22), Color(0.06, 0.05, 0.05))
				for k in 6:
					p.draw_circle(Vector2(hx + 4.0 + float(k) * 6.0, hy - 60.0 - float(k) * 34.0), 10.0 + float(k) * 5.0, Color(0.20, 0.19, 0.19, 0.18))
			for i in 4:
				var tx := sz.x * (0.08 + 0.28 * float(i))
				p.draw_rect(Rect2(tx - 8, hill - 150.0, 16, 120), Color(0.07, 0.05, 0.05))
				p.draw_rect(Rect2(tx - 26, hill - 150.0, 52, 10), Color(0.07, 0.05, 0.05))
			_ground(p, sz, sz.y * 0.80, Color(0.07, 0.06, 0.06))
		"demi_ravine":
			for side: float in [0.0, 1.0]:                        # Cliff walls
				var e := sz.x * side
				var d := 1.0 - 2.0 * side
				var cl := PackedVector2Array([Vector2(e, 0), Vector2(e + d * sz.x * 0.30, 0), Vector2(e + d * sz.x * 0.24, sz.y * 0.3),
					Vector2(e + d * sz.x * 0.28, sz.y * 0.55), Vector2(e + d * sz.x * 0.18, sz.y), Vector2(e, sz.y)])
				p.draw_colored_polygon(cl, Color(0.13, 0.09, 0.07))
				for k in 5:
					p.draw_line(Vector2(e + d * sz.x * (0.05 + 0.04 * float(k)), sz.y * 0.1), Vector2(e + d * sz.x * (0.07 + 0.04 * float(k)), sz.y * 0.9), Color(0.08, 0.05, 0.04), 3.0)
			var sk := Vector2(sz.x * 0.5, sz.y * 0.42)               # The giant tiger skull on the far rocks
			p.draw_colored_polygon(PackedVector2Array([Vector2(sz.x * 0.36, sz.y * 0.62), Vector2(sz.x * 0.44, sz.y * 0.45), Vector2(sz.x * 0.58, sz.y * 0.46), Vector2(sz.x * 0.66, sz.y * 0.62)]), Color(0.12, 0.08, 0.06))
			p.draw_set_transform(sk, 0.0, Vector2(1.0, 0.75))
			p.draw_circle(Vector2.ZERO, 70.0, Color(0.42, 0.38, 0.32))
			p.draw_set_transform(Vector2.ZERO, 0.0, Vector2.ONE)
			p.draw_circle(sk + Vector2(-26, -6), 15.0, Color(0.05, 0.04, 0.03))
			p.draw_circle(sk + Vector2(26, -6), 15.0, Color(0.05, 0.04, 0.03))
			for d2: float in [-22.0, 22.0]:
				p.draw_colored_polygon(PackedVector2Array([sk + Vector2(d2 - 8, 30), sk + Vector2(d2 + 8, 30), sk + Vector2(d2, 86)]), Color(0.48, 0.44, 0.38))
			p.draw_rect(Rect2(0, sz.y * 0.5, sz.x, sz.y * 0.5), Color(0.55, 0.30, 0.12, 0.08))     # Orange dust
			_ground(p, sz, sz.y * 0.82, Color(0.08, 0.06, 0.05))
		"demi_grove":
			p.draw_rect(Rect2(0, sz.y * 0.4, sz.x, sz.y * 0.6), Color(0.35, 0.38, 0.36, 0.10))     # Mist
			for i in 6:                                            # Colossal dead trunks
				var x := sz.x * (0.06 + 0.17 * float(i))
				var w := 50.0 + 20.0 * sin(float(i) * 2.1)
				var col := Color(0.07, 0.08, 0.07) if i != 4 else Color(0.08, 0.11, 0.07)
				p.draw_colored_polygon(PackedVector2Array([Vector2(x - w, sz.y), Vector2(x - w * 0.5, 0), Vector2(x + w * 0.5, 0), Vector2(x + w, sz.y)]), col)
				for k in 3:
					var by := sz.y * (0.15 + 0.2 * float(k))
					var dd := 1.0 if (i + k) % 2 == 0 else -1.0
					p.draw_line(Vector2(x, by), Vector2(x + dd * 150.0, by - 70.0), col, 12.0)
				if i == 4:                                         # The one that is still alive
					p.draw_circle(Vector2(x, sz.y * 0.35), 120.0, Color(0.45, 1.0, 0.35, 0.06))
					for k in 5:
						p.draw_circle(Vector2(x + sin(float(k) * 2.0) * 40.0, sz.y * (0.2 + 0.1 * float(k))), 4.0, Color(0.5, 1.0, 0.4, 0.5))
			_ground(p, sz, sz.y * 0.80, Color(0.05, 0.06, 0.05))
		"demi_door":
			_mountains(p, sz, sz.y * 0.6, 60.0, Color(0.12, 0.11, 0.14), 23)
			var m := Rect2(sz.x * 0.36, sz.y * 0.08, sz.x * 0.28, sz.y * 0.66)      # The colossal monolith
			p.draw_rect(m, Color(0.11, 0.10, 0.13))
			p.draw_rect(Rect2(m.position.x + m.size.x * 0.32, m.position.y + m.size.y * 0.35, m.size.x * 0.36, m.size.y * 0.65), Color(0.04, 0.035, 0.05))
			for k in 8:
				p.draw_arc(Vector2(m.position.x + m.size.x * (0.15 + 0.1 * float(k)), m.position.y + 40.0), 9.0, 0.0, TAU, 8, Color(0.55, 0.45, 0.8, 0.35), 2.0)
			for k in 3:                                             # Broken arches either side
				var ax := sz.x * (0.08 + 0.1 * float(k))
				p.draw_rect(Rect2(ax, sz.y * 0.45, 18, sz.y * 0.3), Color(0.10, 0.09, 0.11))
				p.draw_rect(Rect2(sz.x - ax - 18, sz.y * 0.45, 18, sz.y * 0.3), Color(0.10, 0.09, 0.11))
			_ground(p, sz, sz.y * 0.80, Color(0.08, 0.075, 0.09))


static func embers(n: Node2D, theme: String, sz: Vector2, t: float, data: Array) -> void:
	for i in mini(data.size(), 28):
		var e: Vector3 = data[i]
		var x := e.x * sz.x
		match theme:
			"demi_grove":                                            # Drifting spores (green near the living tree)
				var y := sz.y - fmod(t * e.y * 0.3 + float(i) * 97.0, sz.y + 40.0)
				n.draw_circle(Vector2(x + sin(t * 0.7 + float(i)) * 20.0, y), e.z * 0.6, Color(0.55, 0.9, 0.45, 0.35))
			"demi_village":                                          # Sparks rising from the fires
				var y2 := sz.y * 0.75 - fmod(t * e.y * 0.8 + float(i) * 61.0, sz.y * 0.6)
				n.draw_circle(Vector2(x + sin(t * 2.0 + float(i)) * 6.0, y2), e.z * 0.5, Color(1.0, 0.5, 0.15, 0.6))
			_:                                                       # Falling ash
				var y3 := fmod(t * e.y * 0.6 + float(i) * 83.0, sz.y + 20.0) - 10.0
				n.draw_circle(Vector2(x + sin(t * 0.5 + float(i)) * 30.0, y3), e.z * 0.7, Color(0.65, 0.62, 0.62, 0.35))


# ----- helpers -----
static func _sky(p: Control, sz: Vector2, theme: String) -> void:
	var top := SKY_TOP
	var low := SKY_LOW
	if theme == "demi_ravine":
		low = Color(0.30, 0.20, 0.14)
	elif theme == "demi_grove":
		low = Color(0.20, 0.23, 0.21)
	elif theme == "demi_door":
		low = Color(0.22, 0.20, 0.26)
	p.draw_polygon(PackedVector2Array([Vector2.ZERO, Vector2(sz.x, 0), sz, Vector2(0, sz.y)]),
		PackedColorArray([top, top, low, low]))
	var sun := Vector2(sz.x * 0.72, sz.y * 0.22)                    # A dim, hidden sun
	p.draw_circle(sun, 90.0, Color(0.6, 0.58, 0.55, 0.05))
	p.draw_circle(sun, 34.0, Color(0.55, 0.53, 0.50, 0.18))
	for i in 5:                                                  # Heavy cloud bands
		var cy := sz.y * (0.08 + 0.07 * float(i))
		p.draw_rect(Rect2(0, cy, sz.x, 18.0 + float(i) * 4.0), Color(0.05, 0.05, 0.06, 0.22))


static func _mountains(p: Control, sz: Vector2, base: float, amp: float, col: Color, seed_v: int) -> void:
	var rng := RandomNumberGenerator.new()
	rng.seed = seed_v
	var pts := PackedVector2Array([Vector2(0, sz.y)])
	var n := 14
	for i in n + 1:
		pts.append(Vector2(sz.x * float(i) / float(n), base - rng.randf_range(0.2, 1.0) * amp))
	pts.append(Vector2(sz.x, sz.y))
	p.draw_colored_polygon(pts, col)


## A row of small dead trees on a line (silhouettes).
static func _forest(p: Control, sz: Vector2, base: float, h: float, col: Color, seed_v: int, count: int) -> void:
	var rng := RandomNumberGenerator.new()
	rng.seed = seed_v
	for i in count:
		var x := sz.x * (float(i) + rng.randf_range(0.0, 0.8)) / float(count)
		var th := h * rng.randf_range(0.6, 1.2)
		p.draw_line(Vector2(x, base), Vector2(x + rng.randf_range(-6.0, 6.0), base - th), col, maxf(th * 0.06, 2.0))
		for k in 3:
			var by := base - th * (0.45 + 0.18 * float(k))
			var d := -1.0 if k % 2 == 0 else 1.0
			p.draw_line(Vector2(x, by), Vector2(x + d * th * 0.3, by - th * 0.2), col, maxf(th * 0.025, 1.5))


static func _ground(p: Control, sz: Vector2, y: float, col: Color) -> void:
	p.draw_rect(Rect2(0, y, sz.x, sz.y - y), col)
