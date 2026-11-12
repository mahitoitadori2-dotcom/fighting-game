class_name C5Backdrops
extends RefCounted
## COLOSSEUM 5 backdrops, painted by HellBackground (static landscape + a few animated motes).
##   ROAD:   "thornwood" (black thorn forest, red sky), "fallen_ruins" (broken temples, huge pale
##           moon), "foothills" (snowy slopes, the glowing peak far above)
##   BOSSES (one unique arena each):
##     "silk_loom"   Child Wielding Needle - giant spools, silk curtains, moonlight through a window
##     "mirror_hall" The Brothers - a perfectly symmetrical black / white hall, a mirror line down the middle
##     "beast_den"   Animal Lord - hides on hooks, bone piles, stitched carcasses, firelight
##     "gallows"     Executor - gallows, chopping blocks, purple fog, a blood moon
##     "world_tree"  Mother Nature - a giant world tree burning, flooding, crumbling and blowing at once
##     "satan_cave"  Satan - mountain cave, lava rivers, a throne of horns
##     "sun_peak"    The Sun - above the clouds, white-gold sky
##     "sun_collapse" the finale escape - the peak burning orange as The Consumer explodes

const THEMES := ["thornwood", "fallen_ruins", "foothills", "silk_loom", "mirror_hall", "beast_den", "gallows",
	"world_tree", "ash_cathedral", "satan_cave", "sun_peak", "sun_collapse"]


static func handles(theme: String) -> bool:
	return THEMES.has(theme)


static func _grad(p: Control, sz: Vector2, top: Color, mid: Color, bottom: Color, mid_at: float = 0.6) -> void:
	p.draw_polygon(PackedVector2Array([Vector2(0, 0), Vector2(sz.x, 0), Vector2(sz.x, sz.y * mid_at), Vector2(0, sz.y * mid_at)]), PackedColorArray([top, top, mid, mid]))
	p.draw_polygon(PackedVector2Array([Vector2(0, sz.y * mid_at), Vector2(sz.x, sz.y * mid_at), Vector2(sz.x, sz.y), Vector2(0, sz.y)]), PackedColorArray([mid, mid, bottom, bottom]))


static func _ridge(p: Control, sz: Vector2, base_y: float, amp: float, step: float, col: Color, seed_v: int) -> void:
	var rng := RandomNumberGenerator.new()
	rng.seed = seed_v
	var pts := PackedVector2Array([Vector2(0, sz.y)])
	var x := -20.0
	while x < sz.x + 40.0:
		pts.append(Vector2(x, base_y - rng.randf_range(0.2, 1.0) * amp))
		x += rng.randf_range(step * 0.5, step)
	pts.append(Vector2(sz.x + 40.0, sz.y))
	p.draw_colored_polygon(pts, col)


static func paint(p: Control, theme: String, sz: Vector2) -> void:
	match theme:
		"thornwood":
			_thornwood(p, sz)
		"fallen_ruins":
			_ruins(p, sz)
		"foothills":
			_foothills(p, sz)
		"silk_loom":
			_silk_loom(p, sz)
		"mirror_hall":
			_mirror_hall(p, sz)
		"beast_den":
			_beast_den(p, sz)
		"gallows":
			_gallows(p, sz)
		"world_tree":
			_world_tree(p, sz)
		"ash_cathedral":
			_ash_cathedral(p, sz)
		"satan_cave":
			_satan_cave(p, sz)
		"sun_peak":
			_sun_peak(p, sz, false)
		"sun_collapse":
			_sun_peak(p, sz, true)


# ----- ROAD -----
static func _thornwood(p: Control, sz: Vector2) -> void:
	_grad(p, sz, Color(0.12, 0.02, 0.03), Color(0.45, 0.08, 0.05), Color(0.20, 0.05, 0.04), 0.6)
	var rng := RandomNumberGenerator.new()
	rng.seed = 501
	for layer in 2:
		var col := Color(0.10, 0.03, 0.04) if layer == 0 else Color(0.04, 0.01, 0.02)
		for i in 9:
			var x := rng.randf() * sz.x
			var h := sz.y * rng.randf_range(0.5, 0.85)
			var w := rng.randf_range(10.0, 22.0) * (1.0 + float(layer) * 0.6)
			p.draw_colored_polygon(PackedVector2Array([Vector2(x - w, sz.y), Vector2(x - w * 0.3, sz.y - h), Vector2(x + w * 0.3, sz.y - h), Vector2(x + w, sz.y)]), col)
			for k in 6:                                          # Thorns sticking out of the trunk
				var y := sz.y - h * rng.randf_range(0.2, 0.95)
				var s := -1.0 if k % 2 == 0 else 1.0
				p.draw_colored_polygon(PackedVector2Array([Vector2(x, y - 6), Vector2(x + s * rng.randf_range(30.0, 70.0), y - rng.randf_range(10.0, 40.0)), Vector2(x, y + 6)]), col)
	_ridge(p, sz, sz.y * 0.92, 30.0, 50.0, Color(0.05, 0.01, 0.02), 502)


static func _ruins(p: Control, sz: Vector2) -> void:
	_grad(p, sz, Color(0.05, 0.06, 0.12), Color(0.18, 0.20, 0.30), Color(0.25, 0.25, 0.32), 0.6)
	p.draw_circle(Vector2(sz.x * 0.7, sz.y * 0.25), 110.0, Color(0.92, 0.92, 0.85, 0.85))     # Huge pale moon
	p.draw_circle(Vector2(sz.x * 0.7, sz.y * 0.25), 170.0, Color(0.9, 0.9, 1.0, 0.08))
	var rng := RandomNumberGenerator.new()
	rng.seed = 511
	for i in 8:                                                   # Broken columns
		var x := sz.x * (0.05 + 0.12 * float(i)) + rng.randf_range(-20.0, 20.0)
		var h := sz.y * rng.randf_range(0.2, 0.55)
		p.draw_rect(Rect2(x - 22, sz.y * 0.85 - h, 44, h), Color(0.30, 0.31, 0.36))
		p.draw_colored_polygon(PackedVector2Array([Vector2(x - 24, sz.y * 0.85 - h), Vector2(x + 24, sz.y * 0.85 - h - rng.randf_range(-10.0, 20.0)), Vector2(x + 10, sz.y * 0.85 - h - 22.0)]), Color(0.30, 0.31, 0.36))
		for k in 3:
			p.draw_line(Vector2(x - 12 + float(k) * 12.0, sz.y * 0.85 - h), Vector2(x - 12 + float(k) * 12.0, sz.y * 0.85), Color(0.22, 0.23, 0.28), 2.0)
	# Aqueduct arches in the distance
	for i in 7:
		var ax := sz.x * (0.1 + 0.13 * float(i))
		p.draw_arc(Vector2(ax, sz.y * 0.55), 50.0, PI, TAU, 14, Color(0.14, 0.15, 0.22), 14.0)
	p.draw_rect(Rect2(0, sz.y * 0.47, sz.x, 16), Color(0.14, 0.15, 0.22))
	_ridge(p, sz, sz.y * 0.9, 30.0, 60.0, Color(0.10, 0.10, 0.14), 512)


static func _foothills(p: Control, sz: Vector2) -> void:
	_grad(p, sz, Color(0.25, 0.32, 0.50), Color(0.62, 0.68, 0.80), Color(0.85, 0.88, 0.92), 0.6)
	var peak := Vector2(sz.x * 0.62, sz.y * 0.06)
	p.draw_circle(peak, 80.0, Color(1, 0.95, 0.75, 0.3))
	p.draw_circle(peak, 18.0, Color(1, 1, 0.9))
	p.draw_colored_polygon(PackedVector2Array([Vector2(sz.x * 0.2, sz.y), peak + Vector2(-30, 30), peak + Vector2(30, 34), Vector2(sz.x * 1.05, sz.y)]), Color(0.38, 0.40, 0.48))
	p.draw_colored_polygon(PackedVector2Array([peak + Vector2(-30, 30), peak + Vector2(30, 34), peak + Vector2(90, 150), peak + Vector2(-100, 140)]), Color(0.95, 0.96, 1.0))
	_ridge(p, sz, sz.y * 0.75, 120.0, 140.0, Color(0.48, 0.52, 0.60), 521)
	_ridge(p, sz, sz.y * 0.88, 70.0, 90.0, Color(0.30, 0.33, 0.40), 522)


# ----- BOSS ARENAS -----
static func _silk_loom(p: Control, sz: Vector2) -> void:
	_grad(p, sz, Color(0.06, 0.04, 0.10), Color(0.16, 0.10, 0.22), Color(0.10, 0.07, 0.12), 0.6)
	# Moonlight through a round window
	var w := Vector2(sz.x * 0.5, sz.y * 0.22)
	p.draw_colored_polygon(PackedVector2Array([w + Vector2(-60, 0), w + Vector2(60, 0), w + Vector2(260, sz.y * 0.75), w + Vector2(-260, sz.y * 0.75)]), Color(0.8, 0.85, 1.0, 0.07))
	p.draw_circle(w, 70.0, Color(0.75, 0.80, 0.95, 0.8))
	p.draw_line(w + Vector2(-70, 0), w + Vector2(70, 0), Color(0.1, 0.07, 0.12), 6.0)
	p.draw_line(w + Vector2(0, -70), w + Vector2(0, 70), Color(0.1, 0.07, 0.12), 6.0)
	# Giant spools of thread
	for s: Vector3 in [Vector3(0.14, 0.7, 1.0), Vector3(0.86, 0.66, 1.2), Vector3(0.3, 0.8, 0.7)]:
		var c := Vector2(s.x * sz.x, s.y * sz.y)
		var r := 90.0 * s.z
		p.draw_rect(Rect2(c.x - r * 0.7, c.y - r, r * 1.4, r * 2.0), Color(0.55, 0.30, 0.55))
		for k in 8:
			p.draw_line(Vector2(c.x - r * 0.7, c.y - r + float(k) * r * 0.25), Vector2(c.x + r * 0.7, c.y - r + float(k) * r * 0.25 + 4.0), Color(0.7, 0.45, 0.7), 2.0)
		p.draw_rect(Rect2(c.x - r, c.y - r - 16.0, r * 2.0, 16.0), Color(0.35, 0.22, 0.14))
		p.draw_rect(Rect2(c.x - r, c.y + r, r * 2.0, 16.0), Color(0.35, 0.22, 0.14))
	# Silk curtains hanging from the rafters
	for i in 9:
		var x := sz.x * (0.04 + 0.115 * float(i))
		var pts := PackedVector2Array()
		for k in 9:
			var u := float(k) / 8.0
			pts.append(Vector2(x + sin(u * 4.0 + float(i)) * 14.0, u * sz.y * 0.55))
		p.draw_polyline(pts, Color(0.9, 0.9, 0.97, 0.35), 3.0, FighterArt.AA)
	p.draw_rect(Rect2(0, 0, sz.x, 24), Color(0.2, 0.12, 0.08))


static func _mirror_hall(p: Control, sz: Vector2) -> void:
	var cx := sz.x * 0.5
	p.draw_rect(Rect2(0, 0, cx, sz.y), Color(0.08, 0.08, 0.10))
	p.draw_rect(Rect2(cx, 0, cx, sz.y), Color(0.86, 0.86, 0.90))
	for i in 6:                                                   # Mirrored columns (inverted colours)
		var off := 80.0 + float(i) * 95.0
		p.draw_rect(Rect2(cx - off - 22.0, sz.y * 0.15, 44, sz.y * 0.75), Color(0.85, 0.85, 0.9))
		p.draw_rect(Rect2(cx + off - 22.0, sz.y * 0.15, 44, sz.y * 0.75), Color(0.10, 0.10, 0.12))
	for i in 5:                                                   # Mirrored arches
		var r := 60.0 + float(i) * 70.0
		p.draw_arc(Vector2(cx, sz.y * 0.15), r, PI, PI * 1.5, 16, Color(0.85, 0.85, 0.9), 6.0)
		p.draw_arc(Vector2(cx, sz.y * 0.15), r, PI * 1.5, TAU, 16, Color(0.1, 0.1, 0.12), 6.0)
	p.draw_line(Vector2(cx, 0), Vector2(cx, sz.y), Color(1.0, 0.85, 0.4, 0.8), 4.0)        # The mirror line
	p.draw_circle(Vector2(cx - 220, sz.y * 0.3), 40.0, Color(1.0, 0.82, 0.3, 0.8))          # A sun ...
	p.draw_arc(Vector2(cx + 220, sz.y * 0.3), 40.0, -PI * 0.5, PI * 0.5, 16, Color(0.4, 0.5, 0.8, 0.9), 12.0)   # ... and a moon


static func _beast_den(p: Control, sz: Vector2) -> void:
	_grad(p, sz, Color(0.06, 0.03, 0.02), Color(0.25, 0.12, 0.05), Color(0.12, 0.06, 0.03), 0.65)
	var rng := RandomNumberGenerator.new()
	rng.seed = 541
	for i in 7:                                                   # Hides hanging on hooks
		var x := sz.x * (0.06 + 0.14 * float(i))
		p.draw_line(Vector2(x, 0), Vector2(x, sz.y * 0.2), Color(0.2, 0.18, 0.16), 3.0)
		var hide := PackedVector2Array([Vector2(x - 30, sz.y * 0.22), Vector2(x + 30, sz.y * 0.22), Vector2(x + 40, sz.y * 0.4), Vector2(x + 14, sz.y * 0.48), Vector2(x - 20, sz.y * 0.46), Vector2(x - 38, sz.y * 0.38)])
		p.draw_colored_polygon(hide, Color(0.45, 0.30, 0.18) if i % 2 == 0 else Color(0.32, 0.26, 0.24))
		for k in 3:
			p.draw_line(Vector2(x - 20, sz.y * (0.26 + 0.06 * float(k))), Vector2(x + 20, sz.y * (0.28 + 0.06 * float(k))), Color(0.12, 0.05, 0.05), 2.0)
	for i in 20:                                                  # Bone piles
		var bc := Vector2(rng.randf() * sz.x, sz.y * rng.randf_range(0.7, 0.9))
		var a := rng.randf() * PI
		var d := Vector2.from_angle(a) * rng.randf_range(16.0, 30.0)
		p.draw_line(bc - d, bc + d, Color(0.75, 0.70, 0.60), 6.0)
		p.draw_circle(bc - d, 5.0, Color(0.75, 0.70, 0.60))
		p.draw_circle(bc + d, 5.0, Color(0.75, 0.70, 0.60))
	p.draw_circle(Vector2(sz.x * 0.5, sz.y * 0.85), 160.0, Color(1.0, 0.5, 0.15, 0.12))    # Firelight
	_ridge(p, sz, sz.y * 0.92, 40.0, 60.0, Color(0.08, 0.04, 0.02), 542)


static func _gallows(p: Control, sz: Vector2) -> void:
	_grad(p, sz, Color(0.08, 0.02, 0.06), Color(0.25, 0.08, 0.18), Color(0.18, 0.10, 0.22), 0.6)
	p.draw_circle(Vector2(sz.x * 0.25, sz.y * 0.22), 90.0, Color(0.75, 0.10, 0.10, 0.9))       # Blood moon
	p.draw_circle(Vector2(sz.x * 0.25, sz.y * 0.22), 140.0, Color(0.8, 0.1, 0.1, 0.12))
	for g: float in [0.55, 0.85]:                                        # Gallows
		var x := sz.x * g
		var col := Color(0.08, 0.05, 0.06)
		p.draw_rect(Rect2(x - 8, sz.y * 0.3, 16, sz.y * 0.6), col)
		p.draw_rect(Rect2(x - 8, sz.y * 0.3, 140, 14), col)
		p.draw_line(Vector2(x + 110, sz.y * 0.3), Vector2(x + 110, sz.y * 0.45), Color(0.3, 0.25, 0.2), 3.0)
		p.draw_arc(Vector2(x + 110, sz.y * 0.47), 14.0, 0.0, TAU, 12, Color(0.3, 0.25, 0.2), 3.0)
	for i in 3:                                                   # Chopping blocks
		var bx := sz.x * (0.12 + 0.3 * float(i))
		p.draw_rect(Rect2(bx - 34, sz.y * 0.82, 68, 40), Color(0.25, 0.15, 0.10))
		p.draw_line(Vector2(bx - 20, sz.y * 0.82), Vector2(bx + 14, sz.y * 0.76), Color(0.6, 0.6, 0.65), 6.0)
	for i in 8:                                                   # Purple fog banks
		p.draw_set_transform(Vector2(sz.x * (0.06 + 0.13 * float(i)), sz.y * 0.88), 0.0, Vector2(1.0, 0.3))
		p.draw_circle(Vector2.ZERO, 140.0, Color(0.55, 0.25, 0.8, 0.18))
	p.draw_set_transform(Vector2.ZERO, 0.0, Vector2.ONE)


static func _world_tree(p: Control, sz: Vector2) -> void:
	_grad(p, sz, Color(0.20, 0.35, 0.55), Color(0.55, 0.70, 0.55), Color(0.25, 0.35, 0.18), 0.65)
	var cx := sz.x * 0.5
	# Four seasons of the tree's crown: fire (left-top), water (right-top), earth (left), wind (right)
	var crown := [[Vector2(-220, -120), Color(1.0, 0.45, 0.12, 0.8)], [Vector2(220, -120), Color(0.3, 0.6, 1.0, 0.75)],
		[Vector2(-300, 40), Color(0.45, 0.55, 0.22, 0.8)], [Vector2(300, 40), Color(0.85, 0.95, 0.92, 0.75)]]
	for cr in crown:
		var cc: Vector2 = Vector2(cx, sz.y * 0.32) + cr[0]
		for k in 5:
			p.draw_circle(cc + Vector2(cos(float(k) * 1.3) * 70.0, sin(float(k) * 1.7) * 40.0), 90.0, cr[1])
	# The great trunk + roots
	p.draw_colored_polygon(PackedVector2Array([Vector2(cx - 70, sz.y), Vector2(cx - 50, sz.y * 0.3), Vector2(cx + 50, sz.y * 0.3), Vector2(cx + 70, sz.y)]), Color(0.30, 0.20, 0.12))
	for s: float in [-1.0, 1.0]:
		for k in 3:
			p.draw_line(Vector2(cx + s * 40.0, sz.y * 0.85), Vector2(cx + s * (160.0 + float(k) * 90.0), sz.y * (0.92 + 0.02 * float(k))), Color(0.30, 0.20, 0.12), 14.0 - float(k) * 3.0)
	for k in 6:                                                    # Bark lines
		p.draw_line(Vector2(cx - 40 + float(k) * 16.0, sz.y * 0.32), Vector2(cx - 50 + float(k) * 20.0, sz.y), Color(0.2, 0.12, 0.06), 3.0)
	p.draw_circle(Vector2(cx, sz.y * 0.55), 34.0, Color(0.6, 1.0, 0.6, 0.35))       # The heart of nature glowing in the trunk


## The False God's arena: a cathedral of black stone, burnt pews, a burning altar, broken
## stained glass glowing red, ash falling.
static func _ash_cathedral(p: Control, sz: Vector2) -> void:
	_grad(p, sz, Color(0.05, 0.02, 0.02), Color(0.16, 0.05, 0.04), Color(0.28, 0.08, 0.04), 0.62)
	var cx := sz.x * 0.5
	# Gothic window of broken red glass behind the altar
	var win := PackedVector2Array([Vector2(cx - 90, sz.y * 0.62), Vector2(cx - 90, sz.y * 0.28), Vector2(cx, sz.y * 0.08), Vector2(cx + 90, sz.y * 0.28), Vector2(cx + 90, sz.y * 0.62)])
	p.draw_colored_polygon(win, Color(0.7, 0.1, 0.06, 0.8))
	for k in 5:
		p.draw_line(Vector2(cx - 90 + float(k) * 45.0, sz.y * 0.62), Vector2(cx - 90 + float(k) * 45.0, sz.y * 0.2), Color(0.05, 0.02, 0.02), 5.0)
	p.draw_polyline(PackedVector2Array([win[0], win[1], win[2], win[3], win[4]]), Color(0.05, 0.02, 0.02), 10.0)
	# Black pillars and pointed arches
	for i in 6:
		var off := 160.0 + float(i) * 120.0
		for s: float in [-1.0, 1.0]:
			var x := cx + s * off
			p.draw_rect(Rect2(x - 20, sz.y * 0.18, 40, sz.y * 0.8), Color(0.08, 0.04, 0.04))
			p.draw_colored_polygon(PackedVector2Array([Vector2(x - 26, sz.y * 0.18), Vector2(x, sz.y * 0.08), Vector2(x + 26, sz.y * 0.18)]), Color(0.08, 0.04, 0.04))
	# The burning altar
	p.draw_rect(Rect2(cx - 110, sz.y * 0.74, 220, 40), Color(0.12, 0.06, 0.05))
	for k in 7:
		var fx := cx - 90.0 + float(k) * 30.0
		p.draw_colored_polygon(PackedVector2Array([Vector2(fx - 14, sz.y * 0.74), Vector2(fx, sz.y * 0.74 - 50.0 - float(k % 3) * 20.0), Vector2(fx + 14, sz.y * 0.74)]), Color(1.0, 0.45, 0.1, 0.85))
	# Rows of burnt pews
	for k in 8:
		var px := sz.x * (0.05 + 0.12 * float(k))
		if absf(px - cx) < 150.0:
			continue
		p.draw_rect(Rect2(px - 40, sz.y * 0.84, 80, 14), Color(0.06, 0.03, 0.02))
		p.draw_rect(Rect2(px - 40, sz.y * 0.78, 10, 34), Color(0.06, 0.03, 0.02))


static func _satan_cave(p: Control, sz: Vector2) -> void:
	_grad(p, sz, Color(0.04, 0.01, 0.01), Color(0.20, 0.04, 0.02), Color(0.55, 0.15, 0.03), 0.62)
	var rng := RandomNumberGenerator.new()
	rng.seed = 571
	for i in 4:                                                    # Lava falls
		var fx := sz.x * (0.1 + 0.27 * float(i))
		p.draw_rect(Rect2(fx - 18, 0, 36, sz.y * 0.85), Color(1.0, 0.45, 0.08, 0.6))
		p.draw_rect(Rect2(fx - 6, 0, 12, sz.y * 0.85), Color(1.0, 0.85, 0.4, 0.7))
	var x := -20.0
	while x < sz.x + 20.0:                                        # Stalactites
		var w := rng.randf_range(30.0, 70.0)
		p.draw_colored_polygon(PackedVector2Array([Vector2(x, -2), Vector2(x + w, -2), Vector2(x + w * 0.5, rng.randf_range(60.0, 200.0))]), Color(0.06, 0.02, 0.02))
		x += w * rng.randf_range(0.7, 1.0)
	# The throne of horns in the back
	var t := Vector2(sz.x * 0.5, sz.y * 0.78)
	p.draw_rect(Rect2(t.x - 120, t.y - 30, 240, 30), Color(0.08, 0.03, 0.03))
	p.draw_rect(Rect2(t.x - 70, t.y - 220, 140, 190), Color(0.10, 0.04, 0.04))
	for k in 7:
		var hx := t.x - 90.0 + float(k) * 30.0
		p.draw_colored_polygon(PackedVector2Array([Vector2(hx - 10, t.y - 220), Vector2(hx + sin(float(k)) * 20.0, t.y - 300 - absf(float(k) - 3.0) * -10.0), Vector2(hx + 10, t.y - 220)]), Color(0.15, 0.10, 0.08))
	_ridge(p, sz, sz.y * 0.9, 50.0, 60.0, Color(0.06, 0.02, 0.02), 572)
	p.draw_rect(Rect2(0, sz.y * 0.9, sz.x, 8), Color(1.0, 0.45, 0.1, 0.6))


static func _sun_peak(p: Control, sz: Vector2, burning: bool) -> void:
	if burning:
		_grad(p, sz, Color(0.35, 0.05, 0.02), Color(1.0, 0.45, 0.10), Color(1.0, 0.75, 0.35), 0.55)
	else:
		_grad(p, sz, Color(0.45, 0.65, 0.95), Color(0.95, 0.92, 0.80), Color(1.0, 0.97, 0.90), 0.6)
	var sun := Vector2(sz.x * 0.5, sz.y * 0.2)
	for i in 4:
		p.draw_circle(sun, 260.0 - float(i) * 55.0, Color(1.0, 0.95 if not burning else 0.6, 0.8 if not burning else 0.2, 0.10 + 0.05 * float(i)))
	for i in 16:                                                    # Rays
		var a := TAU * float(i) / 16.0
		p.draw_line(sun + Vector2.from_angle(a) * 120.0, sun + Vector2.from_angle(a) * 420.0, Color(1, 1, 0.9, 0.12) if not burning else Color(1, 0.6, 0.2, 0.2), 10.0)
	for i in 8:                                                     # Sea of clouds below the peak
		p.draw_set_transform(Vector2(sz.x * (0.0 + 0.14 * float(i)), sz.y * 0.93), 0.0, Vector2(1.0, 0.3))
		p.draw_circle(Vector2.ZERO, 160.0, Color(1, 1, 1, 0.9) if not burning else Color(1.0, 0.7, 0.4, 0.85))
	p.draw_set_transform(Vector2.ZERO, 0.0, Vector2.ONE)


# ============================================================
# ANIMATED MOTES (drawn every frame on HellBackground's ember layer)
# ============================================================
static func embers(n: Node2D, theme: String, sz: Vector2, t: float, data: Array) -> void:
	for i in mini(data.size(), 24):
		var e: Vector3 = data[i]
		var x := e.x * sz.x
		match theme:
			"thornwood", "beast_den":
				var y := sz.y - fmod(t * e.y * 0.5 + float(i) * 97.0, sz.y + 40.0)
				n.draw_circle(Vector2(x + sin(t + float(i)) * 20.0, y), e.z * 0.7, Color(1.0, 0.5, 0.2, 0.5))
			"fallen_ruins", "mirror_hall", "silk_loom":
				var y2 := fmod(t * e.y * 0.25 + float(i) * 97.0, sz.y + 40.0) - 20.0
				n.draw_circle(Vector2(x + sin(t * 0.5 + float(i)) * 30.0, y2), e.z * 0.6, Color(0.9, 0.92, 1.0, 0.35))
			"foothills":
				var sx := fmod(e.x * sz.x - t * (80.0 + e.y * 2.0), sz.x + 40.0)
				if sx < 0.0:
					sx += sz.x + 40.0
				n.draw_line(Vector2(sx, fmod(float(i) * 41.0 + t * 30.0, sz.y)), Vector2(sx + 10.0, fmod(float(i) * 41.0 + t * 30.0, sz.y) + 2.0), Color(1, 1, 1, 0.6), 2.0)
			"gallows":
				var y3 := sz.y * 0.85 + sin(t * 0.4 + float(i)) * 30.0
				n.draw_circle(Vector2(fmod(x + t * 20.0, sz.x), y3), 30.0, Color(0.6, 0.3, 0.9, 0.08))
			"world_tree":
				var y4 := fmod(t * e.y * 0.3 + float(i) * 97.0, sz.y + 40.0) - 20.0
				var cols := [Color(1.0, 0.5, 0.15, 0.7), Color(0.4, 0.7, 1.0, 0.7), Color(0.45, 0.6, 0.25, 0.8), Color(1, 1, 1, 0.6)]
				n.draw_circle(Vector2(x + sin(t + float(i)) * 40.0, y4), e.z, cols[i % 4])
			"satan_cave", "sun_collapse", "ash_cathedral":
				var y5 := sz.y - fmod(t * e.y + float(i) * 97.0, sz.y + 40.0)
				n.draw_circle(Vector2(x + sin(t * 0.8 + float(i)) * 20.0, y5), e.z, Color(1.0, 0.55, 0.15, 0.7))
			"sun_peak":
				var y6 := sz.y - fmod(t * e.y * 0.3 + float(i) * 97.0, sz.y + 40.0)
				n.draw_circle(Vector2(x + sin(t * 0.6 + float(i)) * 30.0, y6), e.z, Color(1.0, 0.95, 0.7, 0.6))
