class_name ExtBackdrops
extends RefCounted
## BOSS EXTENSION backdrops, painted by HellBackground (static landscape + a few animated motes).
## Each extension has a FIGHT arena and a UNIQUE BOSS arena:
##   BC  "caeser_crypts"  serpent idols, bone niches, candles     "caeser_tomb"   broken coffin under a serpent ribcage
##   AG  "saint_rocks"    floating saint rocks, golden runes, sky  "saint_sanctum" rune circle, Architect metal pillars
##   VM  "deep_void"      webs, hanging cocoons, crawling shapes   "horrid_nest"   web cathedral full of white eyes
##   AC  "reactor_waste"  wrecked reactor, green haze, debris      "reactor_core"  the melted core, glowing green
##   FM  "the_forge"      catwalks, coal chutes, molten rivers     "forge_heart"   a giant crucible of molten metal

const THEMES := ["caeser_crypts", "caeser_tomb", "saint_rocks", "saint_sanctum", "deep_void", "horrid_nest",
	"reactor_waste", "reactor_core", "the_forge", "forge_heart"]


static func handles(theme: String) -> bool:
	return THEMES.has(theme)


static func paint(p: Control, theme: String, sz: Vector2) -> void:
	match theme:
		"caeser_crypts":
			_crypts(p, sz)
		"caeser_tomb":
			_tomb(p, sz)
		"saint_rocks":
			_saint_rocks(p, sz, false)
		"saint_sanctum":
			_saint_rocks(p, sz, true)
		"deep_void":
			_deep_void(p, sz)
		"horrid_nest":
			_horrid_nest(p, sz)
		"reactor_waste":
			_reactor_waste(p, sz)
		"reactor_core":
			_reactor_core(p, sz)
		"the_forge":
			_forge(p, sz)
		"forge_heart":
			_forge_heart(p, sz)


static func embers(n: Node2D, theme: String, sz: Vector2, t: float, data: Array) -> void:
	for i in mini(data.size(), 24):
		var e: Vector3 = data[i]
		var x := e.x * sz.x
		match theme:
			"caeser_crypts", "caeser_tomb":                      # Candle smoke / green soul motes
				var y := sz.y - fmod(t * e.y * 0.35 + float(i) * 97.0, sz.y + 40.0)
				var col := Color(0.6, 1.0, 0.7, 0.45) if theme == "caeser_tomb" else Color(1.0, 0.7, 0.35, 0.4)
				n.draw_circle(Vector2(x + sin(t + float(i)) * 16.0, y), e.z * 0.7, col)
			"saint_rocks", "saint_sanctum":                       # Rising golden rune sparks
				var y2 := sz.y - fmod(t * e.y * 0.4 + float(i) * 97.0, sz.y + 40.0)
				n.draw_rect(Rect2(x + sin(t * 0.7 + float(i)) * 20.0, y2, e.z * 1.4, e.z * 1.4), Color(1.0, 0.85, 0.4, 0.55))
			"deep_void", "horrid_nest":                           # Drifting void dust
				var y3 := fmod(t * e.y * 0.15 + float(i) * 97.0, sz.y + 40.0) - 20.0
				n.draw_circle(Vector2(x + sin(t * 0.4 + float(i)) * 30.0, y3), e.z * 0.6, Color(0.7, 0.55, 1.0, 0.35))
			"reactor_waste", "reactor_core":                      # Radioactive specks
				var y4 := sz.y - fmod(t * e.y * 0.3 + float(i) * 97.0, sz.y + 40.0)
				n.draw_circle(Vector2(x + sin(t * 1.3 + float(i)) * 12.0, y4), e.z * 0.6, Color(0.5, 1.0, 0.3, 0.55))
			"the_forge", "forge_heart":                           # Sparks flying up
				var y5 := sz.y - fmod(t * e.y * 1.2 + float(i) * 97.0, sz.y + 40.0)
				n.draw_line(Vector2(x, y5), Vector2(x + 2.0, y5 + 8.0), Color(1.0, 0.65, 0.2, 0.8), 2.0)


# ============================================================
# BC - the Caeser's crypts / tomb
# ============================================================
static func _crypts(p: Control, sz: Vector2) -> void:
	C5Backdrops._grad(p, sz, Color(0.06, 0.03, 0.03), Color(0.20, 0.08, 0.05), Color(0.12, 0.05, 0.04), 0.65)
	# Stone vaults (arches)
	for i in 6:
		var x := sz.x * (float(i) + 0.5) / 6.0
		var w := sz.x / 6.0 * 0.42
		var top := sz.y * 0.22
		p.draw_rect(Rect2(x - w, top, w * 2.0, sz.y * 0.6), Color(0.10, 0.05, 0.04))
		p.draw_arc(Vector2(x, top), w, PI, TAU, 18, Color(0.30, 0.18, 0.12), 10.0)
		p.draw_rect(Rect2(x - w - 10, top, 10, sz.y * 0.6), Color(0.26, 0.15, 0.10))
		# Bone niches with skulls
		for k in 3:
			var ny := top + 40.0 + float(k) * 70.0
			p.draw_rect(Rect2(x - 20, ny, 40, 26), Color(0.04, 0.02, 0.02))
			p.draw_circle(Vector2(x, ny + 16), 9.0, Color(0.80, 0.76, 0.62))
			p.draw_circle(Vector2(x - 3, ny + 15), 2.0, Color(0.1, 0.05, 0.05))
			p.draw_circle(Vector2(x + 3, ny + 15), 2.0, Color(0.1, 0.05, 0.05))
	# Serpent idol in the middle
	var c := Vector2(sz.x * 0.5, sz.y * 0.55)
	for k in 10:
		var u := float(k) / 9.0
		p.draw_circle(c + Vector2(sin(u * TAU * 1.5) * 50.0, -u * 200.0), 18.0 - u * 8.0, Color(0.35, 0.28, 0.18))
	p.draw_circle(c + Vector2(0, -210), 22.0, Color(0.40, 0.32, 0.20))
	p.draw_circle(c + Vector2(8, -214), 4.0, Color(1.0, 0.5, 0.15))
	# Candles
	for k in 8:
		var cx := sz.x * (0.08 + float(k) * 0.12)
		var cy := sz.y * 0.78
		p.draw_rect(Rect2(cx - 4, cy - 26, 8, 26), Color(0.82, 0.78, 0.66))
		p.draw_circle(Vector2(cx, cy - 32), 5.0, Color(1.0, 0.7, 0.25))
		p.draw_circle(Vector2(cx, cy - 32), 14.0, Color(1.0, 0.6, 0.2, 0.15))


static func _tomb(p: Control, sz: Vector2) -> void:
	C5Backdrops._grad(p, sz, Color(0.02, 0.04, 0.03), Color(0.08, 0.14, 0.10), Color(0.04, 0.06, 0.05), 0.65)
	# A giant serpent RIBCAGE arching over the tomb
	var c := Vector2(sz.x * 0.5, sz.y * 0.92)
	for k in 9:
		var a := PI + 0.25 + float(k) * (PI - 0.5) / 8.0
		var r := sz.y * 0.75
		var tip := c + Vector2.from_angle(a) * r
		p.draw_line(c + Vector2.from_angle(a) * r * 0.55, tip, Color(0.62, 0.62, 0.52), 14.0)
		p.draw_line(c + Vector2.from_angle(a) * r * 0.55, tip, Color(0.78, 0.78, 0.66), 7.0)
	p.draw_arc(c, sz.y * 0.75, PI + 0.2, TAU - 0.2, 40, Color(0.55, 0.55, 0.46), 22.0)      # Spine
	# Green soul light in the middle (where the coffin is)
	p.draw_circle(Vector2(sz.x * 0.5, sz.y * 0.62), sz.y * 0.28, Color(0.5, 1.0, 0.6, 0.10))
	p.draw_circle(Vector2(sz.x * 0.5, sz.y * 0.62), sz.y * 0.14, Color(0.5, 1.0, 0.6, 0.12))
	# Broken pillars
	for k in 4:
		var x: float = sz.x * float([0.1, 0.24, 0.76, 0.9][k])
		var h := sz.y * (0.35 + 0.1 * float(k % 2))
		p.draw_rect(Rect2(x - 22, sz.y * 0.82 - h, 44, h), Color(0.22, 0.24, 0.20))
		p.draw_colored_polygon(PackedVector2Array([Vector2(x - 22, sz.y * 0.82 - h), Vector2(x + 22, sz.y * 0.82 - h - 18), Vector2(x + 22, sz.y * 0.82 - h + 10)]), Color(0.02, 0.04, 0.03))


# ============================================================
# AG - the Saint Rocks sanctuary / sanctum
# ============================================================
static func _saint_rocks(p: Control, sz: Vector2, sanctum: bool) -> void:
	if sanctum:
		C5Backdrops._grad(p, sz, Color(0.12, 0.16, 0.24), Color(0.35, 0.42, 0.52), Color(0.24, 0.26, 0.30), 0.6)
	else:
		C5Backdrops._grad(p, sz, Color(0.45, 0.62, 0.85), Color(0.95, 0.88, 0.70), Color(0.62, 0.55, 0.46), 0.6)
	var rng := RandomNumberGenerator.new()
	rng.seed = 4242
	# Floating saint rocks with golden runes
	for k in 7:
		var cx := rng.randf() * sz.x
		var cy := sz.y * rng.randf_range(0.12, 0.5)
		var r := rng.randf_range(30.0, 70.0)
		var pts := PackedVector2Array()
		for j in 8:
			pts.append(Vector2(cx, cy) + Vector2.from_angle(float(j) * TAU / 8.0) * r * (0.75 + 0.3 * sin(float(j) * 2.3 + float(k))) * Vector2(1.3, 0.8))
		p.draw_colored_polygon(pts, Color(0.62, 0.58, 0.52) if not sanctum else Color(0.42, 0.42, 0.46))
		p.draw_line(Vector2(cx - r * 0.4, cy), Vector2(cx + r * 0.4, cy), Color(1.0, 0.85, 0.4, 0.8), 3.0)
		p.draw_colored_polygon(PackedVector2Array([Vector2(cx - r * 0.6, cy + r * 0.5), Vector2(cx + r * 0.6, cy + r * 0.5), Vector2(cx, cy + r * 1.3)]), Color(0.5, 0.46, 0.42) if not sanctum else Color(0.32, 0.32, 0.36))
	# Temple columns
	for k in 6:
		var x := sz.x * (0.05 + float(k) * 0.18)
		var col := Color(0.78, 0.74, 0.66) if not sanctum else Color(0.55, 0.58, 0.62)
		p.draw_rect(Rect2(x - 16, sz.y * 0.42, 32, sz.y * 0.5), col)
		p.draw_rect(Rect2(x - 24, sz.y * 0.40, 48, 14), col.lightened(0.15))
		if sanctum:                                           # Architect metal bands + cyan runes
			p.draw_rect(Rect2(x - 18, sz.y * 0.58, 36, 12), Color(0.9, 0.92, 0.95))
			p.draw_line(Vector2(x, sz.y * 0.46), Vector2(x, sz.y * 0.56), Color(0.45, 0.95, 1.0, 0.8), 3.0)
	if sanctum:
		# The rune circle in the sky + the Architect's hexagon
		var c := Vector2(sz.x * 0.5, sz.y * 0.3)
		p.draw_arc(c, sz.y * 0.2, 0.0, TAU, 48, Color(0.45, 0.95, 1.0, 0.6), 5.0)
		p.draw_arc(c, sz.y * 0.16, 0.0, TAU, 48, Color(1.0, 0.85, 0.4, 0.5), 3.0)
		var hex := PackedVector2Array()
		for j in 7:
			hex.append(c + Vector2.from_angle(float(j) * TAU / 6.0 + PI / 6.0) * sz.y * 0.1)
		p.draw_polyline(hex, Color(0.9, 0.95, 1.0, 0.8), 4.0)
		p.draw_circle(c, sz.y * 0.035, Color(0.25, 0.7, 1.0, 0.8))


# ============================================================
# VM - deep Void / Horrid nest
# ============================================================
static func _webs(p: Control, sz: Vector2, n: int, col: Color, seed_v: int) -> void:
	var rng := RandomNumberGenerator.new()
	rng.seed = seed_v
	for k in n:
		var c := Vector2(rng.randf() * sz.x, rng.randf_range(0.0, sz.y * 0.5))
		var r := rng.randf_range(60.0, 140.0)
		for j in 8:
			p.draw_line(c, c + Vector2.from_angle(float(j) * TAU / 8.0) * r, col, 1.5)
		for ring in 3:
			var pts := PackedVector2Array()
			for j in 9:
				pts.append(c + Vector2.from_angle(float(j) * TAU / 8.0) * r * (0.3 + 0.25 * float(ring)))
			p.draw_polyline(pts, col, 1.2)


static func _deep_void(p: Control, sz: Vector2) -> void:
	C5Backdrops._grad(p, sz, Color(0.01, 0.0, 0.02), Color(0.06, 0.02, 0.10), Color(0.03, 0.01, 0.05), 0.6)
	_webs(p, sz, 6, Color(0.6, 0.55, 0.75, 0.35), 77)
	# Hanging cocoons
	var rng := RandomNumberGenerator.new()
	rng.seed = 78
	for k in 9:
		var x := rng.randf() * sz.x
		var y := rng.randf_range(sz.y * 0.15, sz.y * 0.45)
		p.draw_line(Vector2(x, 0), Vector2(x, y - 30), Color(0.6, 0.6, 0.7, 0.4), 2.0)
		p.draw_colored_polygon(EnemyArt.ellipse_points(Vector2(x, y), 14.0, 34.0, 12), Color(0.52, 0.5, 0.58, 0.8))
	# Crawling silhouettes on the far bone pile
	C5Backdrops._ridge(p, sz, sz.y * 0.82, 50.0, 70.0, Color(0.10, 0.07, 0.14), 79)
	for k in 6:
		var x2 := sz.x * (0.1 + float(k) * 0.16)
		p.draw_colored_polygon(EnemyArt.ellipse_points(Vector2(x2, sz.y * 0.8), 24.0, 8.0, 10), Color(0.04, 0.03, 0.06))


static func _horrid_nest(p: Control, sz: Vector2) -> void:
	C5Backdrops._grad(p, sz, Color(0.0, 0.0, 0.01), Color(0.08, 0.03, 0.12), Color(0.03, 0.01, 0.05), 0.55)
	# A web cathedral: big gothic web arches
	for k in 3:
		var c := Vector2(sz.x * (0.2 + float(k) * 0.3), sz.y * 0.85)
		for r: float in [sz.y * 0.6, sz.y * 0.48, sz.y * 0.36]:
			p.draw_arc(c, r, PI, TAU, 30, Color(0.7, 0.65, 0.85, 0.3), 2.5)
		for j in 7:
			p.draw_line(c, c + Vector2.from_angle(PI + float(j) * PI / 6.0) * sz.y * 0.6, Color(0.7, 0.65, 0.85, 0.25), 1.5)
	_webs(p, sz, 4, Color(0.75, 0.7, 0.9, 0.3), 91)
	# White eyes everywhere in the dark
	var rng := RandomNumberGenerator.new()
	rng.seed = 92
	for k in 26:
		var e := Vector2(rng.randf() * sz.x, rng.randf_range(0.05, 0.7) * sz.y)
		p.draw_circle(e, 4.0, Color(0.95, 0.95, 1.0, 0.75))
		p.draw_circle(e + Vector2(10, 1), 3.0, Color(0.95, 0.95, 1.0, 0.6))


# ============================================================
# AC - the reactor after the explosion
# ============================================================
static func _reactor_waste(p: Control, sz: Vector2) -> void:
	C5Backdrops._grad(p, sz, Color(0.10, 0.14, 0.06), Color(0.38, 0.48, 0.18), Color(0.16, 0.18, 0.10), 0.62)
	# The wrecked reactor: a cracked cooling tower + a broken dome
	var tx := sz.x * 0.7
	var tower := PackedVector2Array([Vector2(tx - 110, sz.y * 0.82), Vector2(tx - 70, sz.y * 0.35), Vector2(tx - 40, sz.y * 0.25), Vector2(tx + 10, sz.y * 0.32), Vector2(tx + 30, sz.y * 0.28), Vector2(tx + 70, sz.y * 0.35), Vector2(tx + 110, sz.y * 0.82)])
	p.draw_colored_polygon(tower, Color(0.30, 0.32, 0.28))
	p.draw_line(Vector2(tx - 10, sz.y * 0.3), Vector2(tx + 20, sz.y * 0.7), Color(0.12, 0.14, 0.10), 4.0)
	p.draw_circle(Vector2(tx, sz.y * 0.3), sz.y * 0.12, Color(0.5, 1.0, 0.3, 0.12))      # Green glow leaking out
	var dome := Vector2(sz.x * 0.3, sz.y * 0.75)
	p.draw_arc(dome, 110.0, PI, TAU - 0.9, 20, Color(0.36, 0.38, 0.34), 20.0)
	p.draw_circle(dome + Vector2(40, -60), 40.0, Color(0.5, 1.0, 0.3, 0.15))
	# Debris + bent girders
	C5Backdrops._ridge(p, sz, sz.y * 0.86, 40.0, 50.0, Color(0.18, 0.20, 0.14), 121)
	for k in 5:
		var gx := sz.x * (0.08 + float(k) * 0.2)
		p.draw_line(Vector2(gx, sz.y * 0.86), Vector2(gx + 40, sz.y * 0.62), Color(0.28, 0.24, 0.20), 7.0)
	# Radiation sign
	var s := Vector2(sz.x * 0.12, sz.y * 0.32)
	p.draw_circle(s, 26.0, Color(0.9, 0.8, 0.15))
	for k in 3:
		var a := float(k) * TAU / 3.0 - PI * 0.5
		p.draw_colored_polygon(PackedVector2Array([s, s + Vector2.from_angle(a - 0.45) * 22.0, s + Vector2.from_angle(a + 0.45) * 22.0]), Color(0.08, 0.08, 0.06))
	p.draw_circle(s, 5.0, Color(0.9, 0.8, 0.15))


static func _reactor_core(p: Control, sz: Vector2) -> void:
	C5Backdrops._grad(p, sz, Color(0.02, 0.06, 0.03), Color(0.10, 0.22, 0.08), Color(0.05, 0.08, 0.04), 0.6)
	# The melted core: a huge glowing green pit in the middle, pipes all around
	var c := Vector2(sz.x * 0.5, sz.y * 0.5)
	p.draw_circle(c, sz.y * 0.42, Color(0.45, 1.0, 0.3, 0.08))
	p.draw_circle(c, sz.y * 0.28, Color(0.45, 1.0, 0.3, 0.14))
	p.draw_circle(c, sz.y * 0.16, Color(0.7, 1.0, 0.55, 0.3))
	for k in 8:                                            # Control rods, bent and melted
		var x := sz.x * (0.1 + float(k) * 0.115)
		var bend := sin(float(k) * 1.7) * 30.0
		p.draw_line(Vector2(x, 0), Vector2(x + bend, sz.y * 0.55), Color(0.30, 0.32, 0.30), 18.0)
		p.draw_line(Vector2(x + bend, sz.y * 0.55), Vector2(x + bend, sz.y * 0.55 + 20.0), Color(0.5, 1.0, 0.3, 0.7), 10.0)
	for k in 3:                                            # Pipes across the top
		p.draw_line(Vector2(0, sz.y * (0.08 + float(k) * 0.08)), Vector2(sz.x, sz.y * (0.1 + float(k) * 0.07)), Color(0.22, 0.24, 0.22), 14.0)


# ============================================================
# FM - The Forge / its heart
# ============================================================
static func _forge(p: Control, sz: Vector2) -> void:
	C5Backdrops._grad(p, sz, Color(0.08, 0.04, 0.03), Color(0.40, 0.14, 0.05), Color(0.16, 0.07, 0.04), 0.62)
	# Catwalks + chains
	for k in 2:
		var y := sz.y * (0.25 + float(k) * 0.2)
		p.draw_rect(Rect2(0, y, sz.x, 10), Color(0.18, 0.15, 0.14))
		for j in 12:
			p.draw_line(Vector2(sz.x * float(j) / 12.0, y), Vector2(sz.x * float(j) / 12.0, y + 26.0), Color(0.18, 0.15, 0.14), 3.0)
	# Coal chutes + ovens glowing
	for k in 4:
		var x := sz.x * (0.12 + float(k) * 0.25)
		p.draw_colored_polygon(PackedVector2Array([Vector2(x - 30, 0), Vector2(x + 30, 0), Vector2(x + 14, sz.y * 0.35), Vector2(x - 14, sz.y * 0.35)]), Color(0.14, 0.12, 0.12))
		var ov := Rect2(x - 46, sz.y * 0.55, 92, 90)
		p.draw_rect(ov, Color(0.22, 0.20, 0.20))
		p.draw_rect(Rect2(ov.position.x + 16, ov.position.y + 30, 60, 34), Color(1.0, 0.45, 0.1))
		p.draw_circle(ov.get_center(), 70.0, Color(1.0, 0.45, 0.1, 0.12))
	# Molten river along the bottom
	var river := PackedVector2Array()
	for j in 21:
		river.append(Vector2(sz.x * float(j) / 20.0, sz.y * 0.86 + sin(float(j) * 0.9) * 6.0))
	river.append(Vector2(sz.x, sz.y))
	river.append(Vector2(0, sz.y))
	p.draw_colored_polygon(river, Color(1.0, 0.45, 0.1))
	p.draw_polyline(river.slice(0, 21), Color(1.0, 0.85, 0.4), 4.0)


static func _forge_heart(p: Control, sz: Vector2) -> void:
	C5Backdrops._grad(p, sz, Color(0.10, 0.03, 0.02), Color(0.55, 0.20, 0.05), Color(0.25, 0.08, 0.03), 0.55)
	# The GIANT CRUCIBLE tipping molten metal behind the arena
	var c := Vector2(sz.x * 0.5, sz.y * 0.42)
	var cru := PackedVector2Array([c + Vector2(-220, -120), c + Vector2(220, -120), c + Vector2(170, 90), c + Vector2(-170, 90)])
	p.draw_colored_polygon(cru, Color(0.16, 0.14, 0.14))
	p.draw_rect(Rect2(c.x - 210, c.y - 132, 420, 26), Color(1.0, 0.5, 0.12))
	p.draw_colored_polygon(PackedVector2Array([c + Vector2(200, -120), c + Vector2(260, -100), c + Vector2(270, sz.y * 0.55), c + Vector2(230, sz.y * 0.55)]), Color(1.0, 0.55, 0.15))   # Pour
	p.draw_circle(c, sz.y * 0.45, Color(1.0, 0.45, 0.1, 0.10))
	# Chains holding it + gears
	for x: float in [-180.0, 180.0]:
		p.draw_line(Vector2(c.x + x, 0), c + Vector2(x, -120), Color(0.2, 0.18, 0.17), 8.0)
	for k in 2:
		var g := Vector2(sz.x * (0.1 + float(k) * 0.8), sz.y * 0.28)
		p.draw_circle(g, 60.0, Color(0.18, 0.16, 0.15))
		for j in 10:
			p.draw_rect(Rect2(g + Vector2.from_angle(float(j) * TAU / 10.0) * 60.0 - Vector2(8, 8), Vector2(16, 16)), Color(0.18, 0.16, 0.15))
		p.draw_circle(g, 18.0, Color(0.3, 0.27, 0.25))
