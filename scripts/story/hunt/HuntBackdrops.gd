class_name HuntBackdrops
extends RefCounted
## THE HUNT OF A NIGHTMARE backdrops (painted by HellBackground - RECORDED INTO ONE MESH (MeshCanvas) there:
## /nolags 2026-11-22, ~70 lanterns x 6 shapes cost ~450 draw calls per frame. So p is a CanvasItem OR a MeshCanvas). By the user: ROCKY LANDS with RED
## LANTERNS, some BIG RED TENTS, and - inside those tents, UNIQUE to the 3 final fights - a CAVE with
## a BIG RED CRUCIBLE in the background.
##   hunt_rocks     rocky lands at dusk, strings of red lanterns between crooked poles
##   hunt_tents     the same lands, and the Troupe's big red tents
##   hunt_hollow    a rocky hollow under a stone ceiling, lanterns on chains (the Head Guards crash through it)
##   hunt_crucible  the cave inside the tents: a giant crucible of glowing red, chains, smoke (final 3 fights)

const THEMES := ["hunt_rocks", "hunt_tents", "hunt_hollow", "hunt_crucible"]
const LANTERN := Color(1.0, 0.16, 0.10)
const LANTERN_HOT := Color(1.0, 0.62, 0.36)


static func handles(theme: String) -> bool:
	return THEMES.has(theme)


static func paint(p, theme: String, sz: Vector2) -> void:
	var rng := RandomNumberGenerator.new()
	rng.seed = 8282
	match theme:
		"hunt_rocks":
			_sky(p, sz)
			_ridges(p, sz, rng, 3)
			_lantern_lines(p, sz, rng, 3)
		"hunt_tents":
			_sky(p, sz)
			_ridges(p, sz, rng, 2)
			for i in 4:
				_tent(p, Vector2(sz.x * (0.12 + 0.26 * float(i)) + rng.randf_range(-30.0, 30.0), sz.y * 0.80), rng.randf_range(0.8, 1.25) * sz.y * 0.32, i)
			_lantern_lines(p, sz, rng, 2)
		"hunt_hollow":
			_cave_dark(p, sz, Color(0.10, 0.02, 0.02), Color(0.30, 0.05, 0.04))
			_ridges(p, sz, rng, 2)
			_ceiling(p, sz, rng)
			for i in 7:                                                    # Lanterns hanging on chains from the stone
				var x := sz.x * (0.07 + 0.14 * float(i))
				var drop := sz.y * rng.randf_range(0.12, 0.30)
				p.draw_line(Vector2(x, sz.y * 0.10), Vector2(x, sz.y * 0.10 + drop), Color(0.2, 0.18, 0.18), 2.0)
				_lantern(p, Vector2(x, sz.y * 0.10 + drop + 10.0), 1.0)
		"hunt_crucible":
			_cave_dark(p, sz, Color(0.06, 0.0, 0.0), Color(0.42, 0.04, 0.03))
			_crucible(p, sz, rng)
			_ceiling(p, sz, rng)
			for i in 5:                                                    # The tent's red canvas seen through the cave mouth
				var x2 := sz.x * (0.05 + 0.22 * float(i))
				p.draw_colored_polygon(PackedVector2Array([Vector2(x2, 0), Vector2(x2 + sz.x * 0.11, 0), Vector2(x2 + sz.x * 0.06, sz.y * 0.07)]), Color(0.55, 0.04, 0.05, 0.6))


static func _sky(p, sz: Vector2) -> void:
	for i in 12:
		var k := float(i) / 11.0
		p.draw_rect(Rect2(0, sz.y * 0.07 * float(i), sz.x, sz.y * 0.07 + 1.0), Color(0.07, 0.02, 0.04).lerp(Color(0.40, 0.08, 0.06), k))
	p.draw_rect(Rect2(0, sz.y * 0.77, sz.x, sz.y * 0.23), Color(0.40, 0.08, 0.06))
	p.draw_circle(Vector2(sz.x * 0.78, sz.y * 0.20), sz.y * 0.07, Color(0.95, 0.75, 0.62, 0.85))        # A pale moon
	p.draw_circle(Vector2(sz.x * 0.78, sz.y * 0.20), sz.y * 0.12, Color(1.0, 0.5, 0.4, 0.08))


static func _cave_dark(p, sz: Vector2, top: Color, bottom: Color) -> void:
	for i in 12:
		var k := float(i) / 11.0
		p.draw_rect(Rect2(0, sz.y * 0.084 * float(i), sz.x, sz.y * 0.084 + 1.0), top.lerp(bottom, k))


static func _ridges(p, sz: Vector2, rng: RandomNumberGenerator, n: int) -> void:
	for layer in n:
		var base := sz.y * (0.66 + 0.08 * float(layer))
		var col := Color(0.16, 0.06, 0.06).darkened(0.25 * float(layer))
		var pts := PackedVector2Array([Vector2(0, sz.y)])
		var x := 0.0
		while x <= sz.x + 80.0:
			pts.append(Vector2(x, base - rng.randf_range(20.0, 110.0 - float(layer) * 25.0)))
			x += rng.randf_range(50.0, 130.0)
		pts.append(Vector2(sz.x, sz.y))
		p.draw_colored_polygon(pts, col)
		for i in 4:                                                          # Boulders
			var bx := rng.randf_range(0.0, sz.x)
			p.draw_colored_polygon(EnemyArt.ellipse_points(Vector2(bx, base + 6.0), rng.randf_range(20.0, 46.0), rng.randf_range(12.0, 24.0), 10), col.darkened(0.2))


static func _lantern(p, c: Vector2, s: float) -> void:
	p.draw_circle(c, 22.0 * s, Color(LANTERN.r, LANTERN.g, LANTERN.b, 0.16))
	var body := EnemyArt.ellipse_points(c, 8.0 * s, 11.0 * s, 12)
	p.draw_colored_polygon(body, LANTERN)
	p.draw_polyline(body + PackedVector2Array([body[0]]), Color(0.2, 0.02, 0.02), 1.5)
	p.draw_circle(c, 3.5 * s, LANTERN_HOT)
	p.draw_rect(Rect2(c + Vector2(-4, -13) * s, Vector2(8, 3) * s), Color(0.15, 0.1, 0.08))
	p.draw_rect(Rect2(c + Vector2(-4, 10) * s, Vector2(8, 3) * s), Color(0.15, 0.1, 0.08))


## Crooked poles with sagging strings of red lanterns between them.
static func _lantern_lines(p, sz: Vector2, rng: RandomNumberGenerator, rows: int) -> void:
	for r in rows:
		var y0 := sz.y * (0.36 + 0.12 * float(r))
		var s := 0.7 + 0.25 * float(r)
		var x := -40.0
		var prev := Vector2.ZERO
		var first := true
		while x < sz.x + 80.0:
			var top := Vector2(x + rng.randf_range(-10.0, 10.0), y0 + rng.randf_range(-20.0, 20.0))
			p.draw_line(top, Vector2(top.x - 6.0, sz.y * 0.86), Color(0.12, 0.06, 0.05), 5.0 * s)
			if not first:
				var n := 6
				var last := prev
				for i in range(1, n + 1):
					var f := float(i) / float(n)
					var q := prev.lerp(top, f) + Vector2(0, sin(f * PI) * 46.0 * s)
					p.draw_line(last, q, Color(0.10, 0.05, 0.05), 1.5)
					last = q
					if i < n:
						_lantern(p, q + Vector2(0, 12.0 * s), s)
			prev = top
			first = false
			x += rng.randf_range(220.0, 320.0)


## A big red Troupe tent: striped canvas, a peak with a black pennant, the flap half open.
static func _tent(p, base: Vector2, h: float, idx: int) -> void:
	var w := h * 1.25
	var peak := base + Vector2(0, -h)
	var stripes := 8
	for i in stripes:
		var a := base + Vector2(-w * 0.5 + w * float(i) / float(stripes), 0)
		var b := base + Vector2(-w * 0.5 + w * float(i + 1) / float(stripes), 0)
		p.draw_colored_polygon(PackedVector2Array([peak, a, b]), Color(0.62, 0.05, 0.07) if (i + idx) % 2 == 0 else Color(0.30, 0.02, 0.04))
	p.draw_polyline(PackedVector2Array([base + Vector2(-w * 0.5, 0), peak, base + Vector2(w * 0.5, 0)]), Color(0.08, 0.0, 0.01), 3.0)
	p.draw_colored_polygon(PackedVector2Array([base + Vector2(-w * 0.08, 0), base + Vector2(w * 0.08, 0), base + Vector2(0, -h * 0.35)]), Color(0.04, 0.0, 0.0))
	p.draw_line(peak, peak + Vector2(0, -h * 0.18), Color(0.1, 0.06, 0.05), 3.0)
	p.draw_colored_polygon(PackedVector2Array([peak + Vector2(0, -h * 0.18), peak + Vector2(h * 0.14, -h * 0.15), peak + Vector2(0, -h * 0.11)]), Color(0.06, 0.0, 0.02))
	for k in 3:                                                               # Little lanterns along the hem
		_lantern(p, base + Vector2(-w * 0.32 + w * 0.32 * float(k), -h * 0.12), 0.6)


## A stone ceiling across the top with hanging rock teeth.
static func _ceiling(p, sz: Vector2, rng: RandomNumberGenerator) -> void:
	var pts := PackedVector2Array([Vector2(0, 0), Vector2(sz.x, 0)])
	var x := sz.x
	while x > -40.0:
		pts.append(Vector2(x, sz.y * rng.randf_range(0.06, 0.13)))
		x -= rng.randf_range(40.0, 90.0)
	p.draw_colored_polygon(pts, Color(0.09, 0.03, 0.03))
	for i in 14:
		var tx := rng.randf_range(0.0, sz.x)
		var th := sz.y * rng.randf_range(0.05, 0.14)
		p.draw_colored_polygon(PackedVector2Array([Vector2(tx - 14, sz.y * 0.08), Vector2(tx + 14, sz.y * 0.08), Vector2(tx + 2, sz.y * 0.08 + th)]), Color(0.11, 0.04, 0.04))


## THE BIG RED CRUCIBLE: a giant iron bowl on three legs, brimming with glowing red, chains up into the dark.
static func _crucible(p, sz: Vector2, rng: RandomNumberGenerator) -> void:
	var c := Vector2(sz.x * 0.5, sz.y * 0.50)
	var r := sz.y * 0.26
	p.draw_circle(c, r * 2.2, Color(1.0, 0.1, 0.05, 0.10))
	p.draw_circle(c, r * 1.5, Color(1.0, 0.15, 0.05, 0.12))
	for side: float in [-1.0, 0.0, 1.0]:                                      # Legs
		p.draw_line(c + Vector2(side * r * 0.7, r * 0.3), c + Vector2(side * r * 1.1, r * 1.25), Color(0.08, 0.04, 0.04), 16.0)
	for side2: float in [-1.0, 1.0]:                                          # Chains up into the dark
		var a := c + Vector2(side2 * r * 0.95, -r * 0.1)
		var b := Vector2(c.x + side2 * r * 1.6, 0)
		var n := 18
		for i in n:
			var q := a.lerp(b, float(i) / float(n))
			p.draw_rect(Rect2(q - Vector2(4, 6), Vector2(8, 12)), Color(0.22, 0.12, 0.10), false, 2.0)
	var bowl := PackedVector2Array()
	for i in 21:
		var u := PI * float(i) / 20.0
		bowl.append(c + Vector2(cos(u) * r * 1.05, sin(u) * r * 0.75))
	bowl.append(c + Vector2(-r * 1.05, -r * 0.05))
	p.draw_colored_polygon(bowl, Color(0.14, 0.06, 0.05))
	p.draw_polyline(bowl, Color(0.03, 0.0, 0.0), 4.0)
	for i in 6:                                                                # Iron bands + rivets
		var u2 := PI * (0.15 + 0.14 * float(i))
		p.draw_circle(c + Vector2(cos(u2) * r * 0.95, sin(u2) * r * 0.66), 5.0, Color(0.35, 0.2, 0.15))
	var melt := EnemyArt.ellipse_points(c + Vector2(0, -r * 0.02), r * 1.0, r * 0.18, 24)
	p.draw_colored_polygon(melt, Color(0.95, 0.10, 0.06))
	p.draw_colored_polygon(EnemyArt.ellipse_points(c + Vector2(-r * 0.2, -r * 0.04), r * 0.45, r * 0.07, 16), Color(1.0, 0.55, 0.3))
	for i in 5:                                                                # Drips + smoke
		var dx := c.x + rng.randf_range(-r * 0.9, r * 0.9)
		p.draw_line(Vector2(dx, c.y), Vector2(dx, c.y + rng.randf_range(20.0, r * 0.6)), Color(0.9, 0.08, 0.05), 4.0)
		p.draw_circle(Vector2(c.x + rng.randf_range(-r, r), c.y - r * rng.randf_range(0.4, 1.4)), rng.randf_range(20.0, 50.0), Color(0.3, 0.1, 0.1, 0.12))
