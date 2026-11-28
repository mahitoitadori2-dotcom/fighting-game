class_name LastBackdrops
extends RefCounted
## THE LAST STRETCH backdrops (painted by HellBackground, which RECORDS them into one mesh - so p is a
## CanvasItem OR a MeshCanvas: only draw_rect / draw_colored_polygon / draw_polygon / draw_line /
## draw_polyline / draw_circle / draw_arc).
##   ls_plains     green rolling plains and a dirt road; the Storm's wall of cloud behind you (left)
##   ls_farms      golden fields, a windmill, a farmhouse, a scarecrow; the Storm on the horizon
##   ls_gate       HALCYON on the horizon: towers of glass and copper with lightning rods, a spiral
##                 Storm emblem over the gate (they worship it), the clouds right above the town
##   ls_soul       inside the Architect: a violet void, blueprint lines, slow floating gears
##   ls_soul_dark  deeper: chains, broken cage bars, pale faces in the dark
##   ls_soul_core  the core: a huge glowing blue core, rings of light, mirror shards
##   ls_throne     the king's hall of Halcyon in flames: pillars, burning Storm banners

const THEMES := ["ls_plains", "ls_farms", "ls_gate", "ls_soul", "ls_soul_dark", "ls_soul_core", "ls_throne"]


static func handles(theme: String) -> bool:
	return THEMES.has(theme)


static func paint(p, theme: String, sz: Vector2) -> void:
	var rng := RandomNumberGenerator.new()
	rng.seed = 13913
	match theme:
		"ls_plains":
			_sky(p, sz, Color(0.38, 0.52, 0.72), Color(0.78, 0.82, 0.80))
			_storm_wall(p, sz, rng, 0.0, 0.42)
			_hills(p, sz, rng, Color(0.42, 0.58, 0.34), 0.64, 60.0)
			_trees(p, sz, rng, 9, sz.y * 0.66)
			_hills(p, sz, rng, Color(0.32, 0.50, 0.26), 0.74, 40.0)
			_road(p, sz)
			_fence(p, sz, rng)
		"ls_farms":
			_sky(p, sz, Color(0.45, 0.58, 0.76), Color(0.95, 0.86, 0.66))
			_storm_wall(p, sz, rng, 0.0, 0.28)
			_hills(p, sz, rng, Color(0.50, 0.60, 0.36), 0.62, 50.0)
			_fields(p, sz)
			_windmill(p, Vector2(sz.x * 0.72, sz.y * 0.70), sz.y * 0.30)
			_farmhouse(p, Vector2(sz.x * 0.30, sz.y * 0.74), sz.y * 0.16)
			_scarecrow(p, Vector2(sz.x * 0.52, sz.y * 0.80), sz.y * 0.10)
			_fence(p, sz, rng)
		"ls_gate":
			_sky(p, sz, Color(0.16, 0.22, 0.32), Color(0.48, 0.66, 0.72))
			_halcyon(p, sz, rng)
			_storm_wall(p, sz, rng, 0.15, 0.85, 0.20)
			_hills(p, sz, rng, Color(0.30, 0.36, 0.34), 0.80, 26.0)
		"ls_soul":
			_soul_sky(p, sz, Color(0.06, 0.03, 0.12), Color(0.26, 0.14, 0.42))
			_blueprint(p, sz, Color(0.55, 0.70, 1.0, 0.10))
			_gears(p, sz, rng, 9, Color(0.60, 0.55, 0.85, 0.35))
			_fragments(p, sz, rng, 14, Color(0.80, 0.78, 0.95, 0.20))
		"ls_soul_dark":
			_soul_sky(p, sz, Color(0.02, 0.01, 0.05), Color(0.14, 0.06, 0.20))
			_blueprint(p, sz, Color(0.55, 0.40, 0.80, 0.06))
			_bars(p, sz, rng)
			_chains(p, sz, rng)
			_faces(p, sz, rng)
		"ls_soul_core":
			_soul_sky(p, sz, Color(0.10, 0.08, 0.20), Color(0.56, 0.50, 0.80))
			_core(p, sz)
			_mirrors(p, sz, rng)
		"ls_throne":
			_throne_hall(p, sz, rng)


# ============================================================
# SKY + LAND
# ============================================================
static func _sky(p, sz: Vector2, top: Color, bottom: Color) -> void:
	p.draw_polygon(PackedVector2Array([Vector2.ZERO, Vector2(sz.x, 0), Vector2(sz.x, sz.y), Vector2(0, sz.y)]),
		PackedColorArray([top, top, bottom, bottom]))


## The STORM: a wall of dark cloud between x0 and x1 (screen fractions), lightning frozen in it.
static func _storm_wall(p, sz: Vector2, rng: RandomNumberGenerator, x0: float, x1: float, top_y: float = 0.0) -> void:
	var dark := Color(0.12, 0.10, 0.18)
	var x := sz.x * x0 - 60.0
	while x < sz.x * x1:
		var r := rng.randf_range(60.0, 130.0)
		var k := (x - sz.x * x0) / maxf(sz.x * (x1 - x0), 1.0)
		var y := sz.y * (top_y + 0.10 + 0.30 * k * k) + rng.randf_range(-30.0, 30.0)
		p.draw_circle(Vector2(x, y), r, dark.lerp(Color(0.30, 0.28, 0.40), k * 0.6))
		p.draw_circle(Vector2(x + r * 0.3, y - r * 0.4), r * 0.6, dark.lightened(0.12))
		x += r * 0.9
	p.draw_rect(Rect2(sz.x * x0 - 60.0, 0, sz.x * (x1 - x0) * 0.6 + 60.0, sz.y * (top_y + 0.12)), dark)
	for i in 3:                                                         # Frozen bolts in the cloud
		var bx := sz.x * lerpf(x0, x1, rng.randf_range(0.1, 0.7))
		var pts := PackedVector2Array([Vector2(bx, sz.y * (top_y + 0.12))])
		var by := sz.y * (top_y + 0.12)
		for s in 5:
			bx += rng.randf_range(-26.0, 26.0)
			by += sz.y * 0.06
			pts.append(Vector2(bx, by))
		p.draw_polyline(pts, Color(0.80, 0.88, 1.0, 0.7), 3.0)


static func _hills(p, sz: Vector2, rng: RandomNumberGenerator, col: Color, base: float, amp: float) -> void:
	var pts := PackedVector2Array([Vector2(0, sz.y)])
	var x := 0.0
	var ph := rng.randf() * TAU
	while x <= sz.x + 40.0:
		pts.append(Vector2(x, sz.y * base - amp * (0.5 + 0.5 * sin(x * 0.006 + ph)) - rng.randf_range(0.0, amp * 0.2)))
		x += 40.0
	pts.append(Vector2(sz.x, sz.y))
	p.draw_colored_polygon(pts, col)


static func _trees(p, sz: Vector2, rng: RandomNumberGenerator, n: int, y: float) -> void:
	for i in n:
		var x := rng.randf_range(0.30, 1.0) * sz.x                 # (Not under the Storm wall)
		var h := rng.randf_range(40.0, 80.0)
		p.draw_rect(Rect2(x - 4.0, y - h * 0.4, 8.0, h * 0.4 + 6.0), Color(0.30, 0.20, 0.12))
		p.draw_circle(Vector2(x, y - h * 0.55), h * 0.35, Color(0.20, 0.38, 0.18))
		p.draw_circle(Vector2(x - h * 0.15, y - h * 0.65), h * 0.22, Color(0.26, 0.46, 0.22))


static func _road(p, sz: Vector2) -> void:
	p.draw_colored_polygon(PackedVector2Array([Vector2(sz.x * 0.46, sz.y * 0.70), Vector2(sz.x * 0.54, sz.y * 0.70),
		Vector2(sz.x * 0.80, sz.y), Vector2(sz.x * 0.20, sz.y)]), Color(0.55, 0.44, 0.30))
	p.draw_line(Vector2(sz.x * 0.5, sz.y * 0.72), Vector2(sz.x * 0.5, sz.y), Color(0.62, 0.52, 0.36), 3.0)


static func _fence(p, sz: Vector2, rng: RandomNumberGenerator) -> void:
	var y := sz.y * 0.86
	var x := sz.x * 0.04
	while x < sz.x:
		if absf(x - sz.x * 0.5) > sz.x * 0.16:
			p.draw_rect(Rect2(x, y - 30.0, 7.0, 34.0), Color(0.36, 0.25, 0.15))
		x += rng.randf_range(60.0, 80.0)
	p.draw_line(Vector2(0, y - 20.0), Vector2(sz.x * 0.34, y - 20.0), Color(0.42, 0.30, 0.18), 3.0)
	p.draw_line(Vector2(sz.x * 0.66, y - 20.0), Vector2(sz.x, y - 20.0), Color(0.42, 0.30, 0.18), 3.0)


static func _fields(p, sz: Vector2) -> void:
	for i in 6:                                                         # Stripes of wheat and green
		var y0 := sz.y * (0.66 + 0.06 * float(i))
		var col := Color(0.86, 0.70, 0.30) if i % 2 == 0 else Color(0.56, 0.66, 0.30)
		p.draw_colored_polygon(PackedVector2Array([Vector2(0, y0), Vector2(sz.x, y0 - 14.0), Vector2(sz.x, y0 + sz.y * 0.06 - 14.0), Vector2(0, y0 + sz.y * 0.06)]), col)
	p.draw_rect(Rect2(0, sz.y * 0.98, sz.x, sz.y * 0.02 + 2.0), Color(0.56, 0.66, 0.30))


static func _windmill(p, base: Vector2, h: float) -> void:
	p.draw_colored_polygon(PackedVector2Array([base + Vector2(-h * 0.14, 0), base + Vector2(h * 0.14, 0), base + Vector2(h * 0.08, -h), base + Vector2(-h * 0.08, -h)]), Color(0.86, 0.82, 0.74))
	p.draw_colored_polygon(PackedVector2Array([base + Vector2(-h * 0.12, -h), base + Vector2(h * 0.12, -h), base + Vector2(0, -h * 1.16)]), Color(0.50, 0.26, 0.18))
	var hub := base + Vector2(0, -h * 0.92)
	for i in 4:                                                         # Sails
		var a := TAU * float(i) / 4.0 + 0.4
		var d := Vector2.from_angle(a)
		var n := d.orthogonal()
		p.draw_colored_polygon(PackedVector2Array([hub + n * 6.0, hub + d * h * 0.55 + n * 6.0, hub + d * h * 0.55 + n * 22.0, hub + d * h * 0.12 + n * 22.0]), Color(0.92, 0.90, 0.84))
		p.draw_line(hub, hub + d * h * 0.55, Color(0.36, 0.24, 0.16), 3.0)
	p.draw_circle(hub, 6.0, Color(0.30, 0.20, 0.12))
	p.draw_rect(Rect2(base + Vector2(-h * 0.04, -h * 0.18), Vector2(h * 0.08, h * 0.18)), Color(0.36, 0.24, 0.16))


static func _farmhouse(p, base: Vector2, h: float) -> void:
	p.draw_rect(Rect2(base + Vector2(-h * 0.8, -h), Vector2(h * 1.6, h)), Color(0.82, 0.72, 0.58))
	p.draw_colored_polygon(PackedVector2Array([base + Vector2(-h * 0.95, -h), base + Vector2(h * 0.95, -h), base + Vector2(0, -h * 1.7)]), Color(0.62, 0.22, 0.16))
	p.draw_rect(Rect2(base + Vector2(-h * 0.15, -h * 0.55), Vector2(h * 0.3, h * 0.55)), Color(0.40, 0.26, 0.16))
	for sx: float in [-0.55, 0.35]:
		p.draw_rect(Rect2(base + Vector2(h * sx, -h * 0.75), Vector2(h * 0.22, h * 0.22)), Color(1.0, 0.86, 0.50))


static func _scarecrow(p, base: Vector2, h: float) -> void:
	p.draw_line(base, base + Vector2(0, -h * 1.6), Color(0.40, 0.28, 0.16), 4.0)
	p.draw_line(base + Vector2(-h * 0.6, -h * 1.15), base + Vector2(h * 0.6, -h * 1.15), Color(0.40, 0.28, 0.16), 4.0)
	p.draw_colored_polygon(PackedVector2Array([base + Vector2(-h * 0.35, -h * 1.25), base + Vector2(h * 0.35, -h * 1.25), base + Vector2(h * 0.25, -h * 0.55), base + Vector2(-h * 0.25, -h * 0.55)]), Color(0.36, 0.42, 0.62))
	p.draw_circle(base + Vector2(0, -h * 1.45), h * 0.2, Color(0.90, 0.80, 0.50))
	p.draw_colored_polygon(PackedVector2Array([base + Vector2(-h * 0.4, -h * 1.55), base + Vector2(h * 0.4, -h * 1.55), base + Vector2(0, -h * 1.95)]), Color(0.45, 0.32, 0.18))


## HALCYON: a wall, a gate under a spiral Storm emblem, towers of glass and copper with lightning rods.
static func _halcyon(p, sz: Vector2, rng: RandomNumberGenerator) -> void:
	var ground := sz.y * 0.80
	for i in 14:                                                        # Towers
		var x := sz.x * (0.08 + 0.065 * float(i)) + rng.randf_range(-12.0, 12.0)
		var w := rng.randf_range(34.0, 64.0)
		var h := sz.y * rng.randf_range(0.26, 0.58)
		var glass := Color(0.36, 0.62, 0.70).lerp(Color(0.72, 0.52, 0.30), rng.randf() * 0.6)
		p.draw_rect(Rect2(x - w * 0.5, ground - h, w, h), glass.darkened(0.25))
		p.draw_rect(Rect2(x - w * 0.5, ground - h, w * 0.3, h), glass)
		p.draw_colored_polygon(PackedVector2Array([Vector2(x - w * 0.55, ground - h), Vector2(x + w * 0.55, ground - h), Vector2(x, ground - h - w * 0.8)]), Color(0.72, 0.46, 0.24))
		p.draw_line(Vector2(x, ground - h - w * 0.8), Vector2(x, ground - h - w * 0.8 - 40.0), Color(0.80, 0.70, 0.50), 2.0)   # Lightning rod
		p.draw_circle(Vector2(x, ground - h - w * 0.8 - 40.0), 4.0, Color(0.70, 0.90, 1.0))
		for k in int(h / 26.0):                                         # Lit windows
			if rng.randf() < 0.6:
				p.draw_rect(Rect2(x - w * 0.3 + rng.randf_range(0.0, w * 0.4), ground - h + 14.0 + float(k) * 26.0, 8.0, 10.0), Color(0.80, 0.95, 1.0, 0.8))
	p.draw_rect(Rect2(0, ground - sz.y * 0.10, sz.x, sz.y * 0.10), Color(0.42, 0.44, 0.48))      # The wall
	for i in int(sz.x / 40.0) + 1:
		p.draw_rect(Rect2(float(i) * 40.0, ground - sz.y * 0.10 - 12.0, 22.0, 12.0), Color(0.42, 0.44, 0.48))
	var gate := Vector2(sz.x * 0.5, ground)
	p.draw_rect(Rect2(gate.x - 60.0, gate.y - sz.y * 0.16, 120.0, sz.y * 0.16), Color(0.50, 0.52, 0.56))
	p.draw_rect(Rect2(gate.x - 38.0, gate.y - sz.y * 0.11, 76.0, sz.y * 0.11), Color(0.10, 0.12, 0.16))
	var em := gate + Vector2(0, -sz.y * 0.22)                          # The Storm emblem: a spiral
	var pts := PackedVector2Array()
	for k in 40:
		var a := float(k) * 0.42
		pts.append(em + Vector2.from_angle(a) * (4.0 + float(k) * 1.1))
	p.draw_circle(em, 52.0, Color(0.20, 0.24, 0.34))
	p.draw_polyline(pts, Color(0.70, 0.90, 1.0), 4.0)


# ============================================================
# THE ARCHITECT'S SOUL
# ============================================================
static func _soul_sky(p, sz: Vector2, top: Color, bottom: Color) -> void:
	_sky(p, sz, top, bottom)
	p.draw_circle(Vector2(sz.x * 0.5, sz.y * 0.55), sz.y * 0.45, Color(bottom.r, bottom.g, bottom.b, 0.18))


static func _blueprint(p, sz: Vector2, col: Color) -> void:
	var x := 0.0
	while x < sz.x:
		p.draw_line(Vector2(x, 0), Vector2(x, sz.y), col, 1.0)
		x += 48.0
	var y := 0.0
	while y < sz.y:
		p.draw_line(Vector2(0, y), Vector2(sz.x, y), col, 1.0)
		y += 48.0


static func _gear(p, c: Vector2, r: float, col: Color, teeth: int) -> void:
	var pts := PackedVector2Array()
	for i in teeth * 2:
		var a := TAU * float(i) / float(teeth * 2)
		pts.append(c + Vector2.from_angle(a) * (r if i % 2 == 0 else r * 0.8))
	p.draw_colored_polygon(pts, col)
	p.draw_circle(c, r * 0.35, Color(0, 0, 0, 0.35))


static func _gears(p, sz: Vector2, rng: RandomNumberGenerator, n: int, col: Color) -> void:
	for i in n:
		_gear(p, Vector2(rng.randf_range(0.0, sz.x), rng.randf_range(sz.y * 0.05, sz.y * 0.70)), rng.randf_range(20.0, 70.0), col, rng.randi_range(8, 14))


static func _fragments(p, sz: Vector2, rng: RandomNumberGenerator, n: int, col: Color) -> void:
	for i in n:                                                         # Floating bits of buildings
		var c := Vector2(rng.randf_range(0.0, sz.x), rng.randf_range(sz.y * 0.1, sz.y * 0.75))
		var s := rng.randf_range(14.0, 46.0)
		var a := rng.randf() * TAU
		var d := Vector2.from_angle(a) * s
		var n2 := d.orthogonal() * 0.6
		p.draw_colored_polygon(PackedVector2Array([c - d - n2, c + d - n2, c + d + n2, c - d + n2]), col)


static func _bars(p, sz: Vector2, rng: RandomNumberGenerator) -> void:
	for i in 18:                                                        # Broken cage bars
		var x := sz.x * float(i) / 17.0
		var top := sz.y * rng.randf_range(0.0, 0.25)
		var bot := sz.y * rng.randf_range(0.55, 0.85)
		p.draw_line(Vector2(x, top), Vector2(x + rng.randf_range(-20.0, 20.0), bot), Color(0.30, 0.24, 0.40, 0.55), 6.0)
	p.draw_line(Vector2(0, sz.y * 0.20), Vector2(sz.x, sz.y * 0.24), Color(0.30, 0.24, 0.40, 0.5), 8.0)


static func _chains(p, sz: Vector2, rng: RandomNumberGenerator) -> void:
	for i in 6:
		var x := rng.randf_range(0.0, sz.x)
		var y := 0.0
		var end := sz.y * rng.randf_range(0.3, 0.6)
		while y < end:
			p.draw_arc(Vector2(x, y + 9.0), 7.0, 0.0, TAU, 10, Color(0.42, 0.38, 0.50, 0.7), 3.0)
			y += 14.0


static func _faces(p, sz: Vector2, rng: RandomNumberGenerator) -> void:
	for i in 9:                                                         # Pale faces of the ones he could not save
		var c := Vector2(rng.randf_range(0.0, sz.x), rng.randf_range(sz.y * 0.15, sz.y * 0.65))
		var r := rng.randf_range(16.0, 34.0)
		p.draw_circle(c, r, Color(0.80, 0.78, 0.90, 0.10))
		p.draw_circle(c + Vector2(-r * 0.35, -r * 0.1), r * 0.14, Color(0.0, 0.0, 0.0, 0.35))
		p.draw_circle(c + Vector2(r * 0.35, -r * 0.1), r * 0.14, Color(0.0, 0.0, 0.0, 0.35))
		p.draw_arc(c + Vector2(0, r * 0.45), r * 0.3, PI * 1.15, PI * 1.85, 8, Color(0.0, 0.0, 0.0, 0.3), 2.0)


static func _core(p, sz: Vector2) -> void:
	var c := Vector2(sz.x * 0.5, sz.y * 0.42)
	for i in 6:                                                         # Glow
		p.draw_circle(c, sz.y * (0.40 - 0.05 * float(i)), Color(0.30, 0.70, 1.0, 0.06 + 0.02 * float(i)))
	for i in 4:                                                         # Rings of light
		p.draw_arc(c, sz.y * (0.18 + 0.07 * float(i)), 0.0, TAU, 48, Color(0.75, 0.90, 1.0, 0.35 - 0.06 * float(i)), 3.0)
	var hexp := PackedVector2Array()                                    # The core itself (the Architect's)
	for i in 6:
		hexp.append(c + Vector2.from_angle(TAU * float(i) / 6.0 + PI / 6.0) * sz.y * 0.11)
	p.draw_colored_polygon(hexp, Color(0.18, 0.68, 1.0))
	p.draw_circle(c, sz.y * 0.06, Color(0.78, 0.95, 1.0))


static func _mirrors(p, sz: Vector2, rng: RandomNumberGenerator) -> void:
	for i in 12:
		var c := Vector2(rng.randf_range(0.0, sz.x), rng.randf_range(sz.y * 0.08, sz.y * 0.78))
		var s := rng.randf_range(18.0, 50.0)
		var a := rng.randf() * TAU
		var pts := PackedVector2Array([c + Vector2.from_angle(a) * s, c + Vector2.from_angle(a + 2.2) * s * 0.7, c + Vector2.from_angle(a + 4.0) * s * 0.9])
		p.draw_colored_polygon(pts, Color(0.85, 0.88, 1.0, 0.22))
		p.draw_polyline(PackedVector2Array([pts[0], pts[1], pts[2], pts[0]]), Color(1, 1, 1, 0.35), 1.5)


# ============================================================
# HALCYON IN FLAMES
# ============================================================
static func _throne_hall(p, sz: Vector2, rng: RandomNumberGenerator) -> void:
	_sky(p, sz, Color(0.10, 0.04, 0.03), Color(0.55, 0.18, 0.06))
	for i in 4:                                                         # Tall windows full of fire
		var x := sz.x * (0.16 + 0.23 * float(i))
		p.draw_rect(Rect2(x - 34.0, sz.y * 0.14, 68.0, sz.y * 0.40), Color(1.0, 0.52, 0.16))
		p.draw_circle(Vector2(x, sz.y * 0.14), 34.0, Color(1.0, 0.52, 0.16))
		p.draw_rect(Rect2(x - 3.0, sz.y * 0.10, 6.0, sz.y * 0.44), Color(0.14, 0.08, 0.06))
	for i in 6:                                                         # Pillars
		var x2 := sz.x * (0.04 + 0.184 * float(i))
		p.draw_rect(Rect2(x2 - 26.0, sz.y * 0.05, 52.0, sz.y * 0.80), Color(0.18, 0.14, 0.14))
		p.draw_rect(Rect2(x2 - 26.0, sz.y * 0.05, 12.0, sz.y * 0.80), Color(0.26, 0.20, 0.18))
	for i in 5:                                                         # Burning Storm banners
		var x3 := sz.x * (0.13 + 0.184 * float(i))
		var top := sz.y * 0.12
		p.draw_colored_polygon(PackedVector2Array([Vector2(x3 - 24, top), Vector2(x3 + 24, top), Vector2(x3 + 24, top + sz.y * 0.22),
			Vector2(x3, top + sz.y * 0.26), Vector2(x3 - 24, top + sz.y * 0.22)]), Color(0.16, 0.22, 0.38))
		var em := Vector2(x3, top + sz.y * 0.10)
		var sp := PackedVector2Array()
		for k in 18:
			sp.append(em + Vector2.from_angle(float(k) * 0.5) * (2.0 + float(k) * 0.9))
		p.draw_polyline(sp, Color(0.70, 0.88, 1.0), 2.0)
		for f in 3:                                                     # The flames eating them from below
			var fx := x3 - 16.0 + float(f) * 16.0
			p.draw_colored_polygon(PackedVector2Array([Vector2(fx - 9, top + sz.y * 0.25), Vector2(fx + 9, top + sz.y * 0.25),
				Vector2(fx + rng.randf_range(-4.0, 4.0), top + sz.y * rng.randf_range(0.12, 0.18))]), Color(1.0, 0.55, 0.12, 0.85))
	for i in 22:                                                        # Fire along the floor
		var fx2 := sz.x * float(i) / 21.0
		var fh := sz.y * rng.randf_range(0.06, 0.16)
		p.draw_colored_polygon(PackedVector2Array([Vector2(fx2 - 30, sz.y * 0.86), Vector2(fx2 + 30, sz.y * 0.86), Vector2(fx2, sz.y * 0.86 - fh)]), Color(1.0, 0.42, 0.08, 0.9))
		p.draw_colored_polygon(PackedVector2Array([Vector2(fx2 - 14, sz.y * 0.86), Vector2(fx2 + 14, sz.y * 0.86), Vector2(fx2, sz.y * 0.86 - fh * 0.6)]), Color(1.0, 0.82, 0.30, 0.9))
	p.draw_rect(Rect2(0, sz.y * 0.86, sz.x, sz.y * 0.14), Color(0.16, 0.08, 0.06))
