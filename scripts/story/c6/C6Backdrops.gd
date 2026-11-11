class_name C6Backdrops
extends RefCounted
## THE ENLIGHTENED CHASE backdrops, painted by HellBackground (static landscape + motes).
##   ROAD:   "golden_dunes" (gold desert at noon, caravan tracks, obelisks with his face),
##           "pilgrim_road" (a paved road between giant golden statues of him, banners),
##           "glass_oasis"  (palms of golden glass, mirror-still water, a mirage road)
##   BOSSES: "prime_sanctum" (The First Prime: a ring of huge gongs, incense smoke, ritual circle)
##           "sky_reliquary" (The Enlightened One: above golden clouds, his hoard floating)

const THEMES := ["golden_dunes", "pilgrim_road", "glass_oasis", "prime_sanctum", "sky_reliquary"]
const GOLD := Color(1.0, 0.82, 0.3)


static func handles(theme: String) -> bool:
	return THEMES.has(theme)


static func paint(p: Control, theme: String, sz: Vector2) -> void:
	match theme:
		"golden_dunes":
			_dunes(p, sz)
		"pilgrim_road":
			_pilgrim_road(p, sz)
		"glass_oasis":
			_oasis(p, sz)
		"prime_sanctum":
			_sanctum(p, sz)
		"sky_reliquary":
			_reliquary(p, sz)


static func embers(n: Node2D, theme: String, sz: Vector2, t: float, data: Array) -> void:
	for i in mini(data.size(), 24):
		var e: Vector3 = data[i]
		var x := e.x * sz.x
		match theme:
			"golden_dunes", "pilgrim_road":                        # Blowing sand
				var y := sz.y * (0.35 + 0.6 * fmod(float(i) * 0.37, 1.0)) + sin(t + float(i)) * 8.0
				var xx := fmod(x + t * e.y * 1.2, sz.x + 40.0) - 20.0
				n.draw_line(Vector2(xx, y), Vector2(xx + 10.0, y + 1.0), Color(1.0, 0.85, 0.55, 0.35), 2.0)
			"glass_oasis":                                          # Glinting light on the water
				var tw := 0.5 + 0.5 * sin(t * 3.0 + float(i) * 1.7)
				n.draw_circle(Vector2(x, sz.y * (0.66 + 0.2 * fmod(float(i) * 0.53, 1.0))), e.z * 0.5 * tw, Color(1, 1, 0.85, 0.6 * tw))
			"prime_sanctum":                                        # Incense smoke drifting up
				var y2 := sz.y - fmod(t * e.y * 0.25 + float(i) * 97.0, sz.y + 40.0)
				n.draw_circle(Vector2(x + sin(t * 0.6 + float(i)) * 24.0, y2), e.z * 1.6, Color(0.9, 0.85, 0.75, 0.10))
			"sky_reliquary":                                        # Golden motes rising
				var y3 := sz.y - fmod(t * e.y * 0.5 + float(i) * 97.0, sz.y + 40.0)
				n.draw_circle(Vector2(x + sin(t * 0.8 + float(i)) * 14.0, y3), e.z * 0.6, Color(1.0, 0.88, 0.45, 0.6))


# ----- helpers -----
static func _sun(p: Control, c: Vector2, r: float) -> void:
	p.draw_circle(c, r * 2.2, Color(1.0, 0.95, 0.7, 0.12))
	p.draw_circle(c, r * 1.4, Color(1.0, 0.93, 0.6, 0.25))
	p.draw_circle(c, r, Color(1.0, 0.97, 0.82))


static func _dune(p: Control, sz: Vector2, base_y: float, amp: float, waves: float, phase: float, col: Color) -> void:
	var pts := PackedVector2Array([Vector2(0, sz.y)])
	for i in 41:
		var x := sz.x * float(i) / 40.0
		pts.append(Vector2(x, base_y - amp * (0.5 + 0.5 * sin(x / sz.x * TAU * waves + phase))))
	pts.append(Vector2(sz.x, sz.y))
	p.draw_colored_polygon(pts, col)


## A tall obelisk / statue of HIM: robe, halo, face-mask (silhouette with gold details).
static func _statue(p: Control, base: Vector2, h: float, col: Color, gold: Color) -> void:
	var w := h * 0.22
	p.draw_colored_polygon(PackedVector2Array([base + Vector2(-w, 0), base + Vector2(-w * 0.6, -h * 0.75), base + Vector2(w * 0.6, -h * 0.75), base + Vector2(w, 0)]), col)
	p.draw_circle(base + Vector2(0, -h * 0.82), w * 0.45, col)
	p.draw_arc(base + Vector2(0, -h * 0.84), w * 0.75, 0.0, TAU, 20, gold, maxf(h * 0.02, 2.0))
	p.draw_rect(Rect2(base.x - w * 1.2, base.y - h * 0.06, w * 2.4, h * 0.06), col.darkened(0.2))
	p.draw_line(base + Vector2(-w * 0.15, -h * 0.84), base + Vector2(w * 0.25, -h * 0.84), gold, maxf(h * 0.012, 1.5))


# ============================================================
# ROAD MAPS
# ============================================================
static func _dunes(p: Control, sz: Vector2) -> void:
	C5Backdrops._grad(p, sz, Color(0.98, 0.78, 0.45), Color(1.0, 0.90, 0.65), Color(0.85, 0.62, 0.32), 0.55)
	_sun(p, Vector2(sz.x * 0.72, sz.y * 0.18), 46.0)
	_dune(p, sz, sz.y * 0.58, 50.0, 1.3, 0.4, Color(0.92, 0.70, 0.40))
	for i in 3:                                                    # Obelisks with his face, far away
		_statue(p, Vector2(sz.x * (0.18 + 0.3 * float(i)), sz.y * 0.56), 110.0 + 30.0 * float(i % 2), Color(0.78, 0.58, 0.30), GOLD)
	_dune(p, sz, sz.y * 0.70, 40.0, 2.1, 2.0, Color(0.86, 0.62, 0.32))
	# Caravan tracks + a lost banner
	for k in 9:
		p.draw_circle(Vector2(sz.x * (0.05 + 0.1 * float(k)), sz.y * 0.80 + sin(float(k)) * 6.0), 5.0, Color(0.70, 0.50, 0.25, 0.6))
	_dune(p, sz, sz.y * 0.86, 30.0, 1.6, 4.0, Color(0.80, 0.56, 0.28))


static func _pilgrim_road(p: Control, sz: Vector2) -> void:
	C5Backdrops._grad(p, sz, Color(0.55, 0.65, 0.92), Color(1.0, 0.88, 0.62), Color(0.80, 0.70, 0.52), 0.6)
	_sun(p, Vector2(sz.x * 0.5, sz.y * 0.30), 38.0)
	# The road going away into the distance
	p.draw_colored_polygon(PackedVector2Array([Vector2(sz.x * 0.47, sz.y * 0.55), Vector2(sz.x * 0.53, sz.y * 0.55), Vector2(sz.x * 0.85, sz.y), Vector2(sz.x * 0.15, sz.y)]), Color(0.88, 0.82, 0.70))
	for k in 6:
		var y := sz.y * (0.58 + 0.07 * float(k) * float(k) * 0.3 + 0.05 * float(k))
		p.draw_line(Vector2(sz.x * 0.5, y), Vector2(sz.x * 0.5, y + 6.0 + float(k) * 3.0), Color(1.0, 0.85, 0.4, 0.8), 2.0 + float(k))
	# Giant golden statues of him lining the road (smaller = farther), banners between
	for side: float in [-1.0, 1.0]:
		for k in 4:
			var d := float(k) / 3.0
			var x := sz.x * (0.5 + side * (0.08 + 0.36 * d))
			var base := Vector2(x, sz.y * (0.56 + 0.34 * d))
			_statue(p, base, 60.0 + 200.0 * d, Color(0.90, 0.72, 0.34), Color(1.0, 0.95, 0.65))
			p.draw_line(base + Vector2(side * 30.0 * (0.4 + d), -40.0 - 120.0 * d), base + Vector2(side * 30.0 * (0.4 + d), 0), Color(0.5, 0.35, 0.2), 3.0)
			p.draw_rect(Rect2(base.x + side * 30.0 * (0.4 + d) - 8.0 * (0.5 + d), base.y - 40.0 - 120.0 * d, 16.0 * (0.5 + d), 40.0 * (0.5 + d)), Color(0.30, 0.25, 0.65, 0.9))


static func _oasis(p: Control, sz: Vector2) -> void:
	C5Backdrops._grad(p, sz, Color(0.45, 0.70, 0.95), Color(0.98, 0.90, 0.70), Color(0.85, 0.70, 0.45), 0.55)
	_sun(p, Vector2(sz.x * 0.25, sz.y * 0.2), 34.0)
	# Mirage road shimmering in the sky
	for k in 5:
		p.draw_line(Vector2(sz.x * 0.55, sz.y * (0.30 + 0.02 * float(k))), Vector2(sz.x * 0.95, sz.y * (0.27 + 0.02 * float(k))), Color(1.0, 0.95, 0.75, 0.15), 3.0)
	_dune(p, sz, sz.y * 0.58, 30.0, 1.0, 1.0, Color(0.90, 0.74, 0.46))
	# The mirror-still water
	var water := Rect2(sz.x * 0.15, sz.y * 0.64, sz.x * 0.7, sz.y * 0.16)
	p.draw_colored_polygon(EnemyArt.ellipse_points(water.get_center(), water.size.x * 0.5, water.size.y * 0.5, 30), Color(0.55, 0.80, 0.95))
	p.draw_colored_polygon(EnemyArt.ellipse_points(water.get_center() + Vector2(0, -4), water.size.x * 0.4, water.size.y * 0.25, 30), Color(0.80, 0.93, 1.0, 0.6))
	# Palms of golden glass
	for k in 5:
		var x := sz.x * (0.08 + 0.21 * float(k))
		var base := Vector2(x, sz.y * (0.66 + 0.04 * float(k % 2)))
		var top := base + Vector2(14.0 * (1.0 if k % 2 == 0 else -1.0), -150.0 - 20.0 * float(k % 3))
		p.draw_line(base, top, Color(0.95, 0.75, 0.30, 0.9), 8.0)
		for f in 6:
			var a := -PI * 0.5 + (float(f) - 2.5) * 0.55
			var tip := top + Vector2.from_angle(a) * 70.0 + Vector2(0, 30)
			p.draw_colored_polygon(PackedVector2Array([top, tip + Vector2(0, -6), tip + Vector2(0, 6)]), Color(1.0, 0.86, 0.45, 0.75))
	_dune(p, sz, sz.y * 0.88, 20.0, 2.0, 3.0, Color(0.82, 0.62, 0.34))


# ============================================================
# BOSS ARENAS
# ============================================================
static func _sanctum(p: Control, sz: Vector2) -> void:
	C5Backdrops._grad(p, sz, Color(0.12, 0.08, 0.06), Color(0.42, 0.28, 0.14), Color(0.22, 0.14, 0.08), 0.6)
	# Ritual circle glowing on the far wall
	var c := Vector2(sz.x * 0.5, sz.y * 0.42)
	p.draw_arc(c, 150.0, 0.0, TAU, 48, Color(1.0, 0.8, 0.35, 0.5), 5.0)
	p.draw_arc(c, 110.0, 0.0, TAU, 48, Color(1.0, 0.8, 0.35, 0.35), 3.0)
	for k in 8:
		var a := TAU * float(k) / 8.0
		p.draw_line(c + Vector2.from_angle(a) * 110.0, c + Vector2.from_angle(a + 2.4) * 110.0, Color(1.0, 0.8, 0.35, 0.3), 2.0)
	# A ring of huge gongs on wooden frames
	for k in 5:
		var x := sz.x * (0.1 + 0.2 * float(k))
		var y := sz.y * (0.50 + (0.06 if k % 2 == 1 else 0.0))
		var r := 56.0 if k == 2 else 40.0
		p.draw_line(Vector2(x - r - 10.0, y + r + 40.0), Vector2(x - r - 10.0, y - r - 16.0), Color(0.35, 0.20, 0.10), 8.0)
		p.draw_line(Vector2(x + r + 10.0, y + r + 40.0), Vector2(x + r + 10.0, y - r - 16.0), Color(0.35, 0.20, 0.10), 8.0)
		p.draw_line(Vector2(x - r - 16.0, y - r - 16.0), Vector2(x + r + 16.0, y - r - 16.0), Color(0.40, 0.24, 0.12), 10.0)
		p.draw_circle(Vector2(x, y), r + 4.0, Color(0.30, 0.18, 0.08))
		p.draw_circle(Vector2(x, y), r, Color(0.85, 0.62, 0.25))
		p.draw_arc(Vector2(x, y), r * 0.6, 0.0, TAU, 24, Color(1.0, 0.85, 0.45), 3.0)
		p.draw_circle(Vector2(x - r * 0.25, y - r * 0.25), r * 0.2, Color(1.0, 0.92, 0.6, 0.6))
	# Incense burners on the floor
	for k in 4:
		var bx := sz.x * (0.2 + 0.2 * float(k))
		p.draw_rect(Rect2(bx - 14.0, sz.y * 0.80, 28.0, 22.0), Color(0.55, 0.40, 0.18))
		p.draw_circle(Vector2(bx, sz.y * 0.80), 8.0, Color(1.0, 0.6, 0.2, 0.7))


static func _reliquary(p: Control, sz: Vector2) -> void:
	C5Backdrops._grad(p, sz, Color(0.95, 0.75, 0.40), Color(1.0, 0.92, 0.70), Color(1.0, 0.96, 0.85), 0.5)
	_sun(p, Vector2(sz.x * 0.5, sz.y * 0.12), 60.0)
	# Rays from the sun
	for k in 12:
		var a := PI * 0.5 + (float(k) - 5.5) * 0.18
		p.draw_colored_polygon(PackedVector2Array([Vector2(sz.x * 0.5, sz.y * 0.12), Vector2(sz.x * 0.5, sz.y * 0.12) + Vector2.from_angle(a - 0.04) * sz.y,
			Vector2(sz.x * 0.5, sz.y * 0.12) + Vector2.from_angle(a + 0.04) * sz.y]), Color(1, 1, 0.9, 0.08))
	# His hoard, floating in the sky (vases, candelabras, tablets, bells, statue heads)
	var rng := RandomNumberGenerator.new()
	rng.seed = 620
	for k in 14:
		var pos := Vector2(rng.randf() * sz.x, sz.y * rng.randf_range(0.15, 0.55))
		p.draw_set_transform(pos, rng.randf_range(-0.6, 0.6), Vector2.ONE * rng.randf_range(0.6, 1.2))
		EnlightenedFx._relic(p, k % 5, 0.0)
		p.draw_set_transform(Vector2.ZERO, 0.0, Vector2.ONE)
	# Golden clouds below
	for k in 9:
		var x := sz.x * (float(k) / 8.0)
		p.draw_circle(Vector2(x, sz.y * 0.80), 90.0, Color(1.0, 0.92, 0.75, 0.85))
		p.draw_circle(Vector2(x + 50.0, sz.y * 0.86), 80.0, Color(1.0, 0.86, 0.60, 0.85))
