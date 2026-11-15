class_name OrdBackdrops
extends RefCounted
## TERRA ORDINARIORUM backdrops (painted by HellBackground; each is also a Versus map). The
## regular land: blue skies at last. Far away on the horizon, always, the dark wall of THE STORM.

const THEMES := ["ord_meadow", "ord_forest", "ord_town", "ord_jungle", "ord_desert", "ord_mountain", "ord_snow"]


static func handles(theme: String) -> bool:
	return THEMES.has(theme)


static func paint(p: Control, theme: String, sz: Vector2) -> void:
	var top := Color(0.38, 0.62, 0.92)
	var low := Color(0.78, 0.88, 0.98)
	match theme:
		"ord_desert":
			top = Color(0.45, 0.62, 0.88)
			low = Color(0.98, 0.88, 0.66)
		"ord_jungle":
			top = Color(0.35, 0.58, 0.78)
			low = Color(0.70, 0.86, 0.80)
		"ord_mountain":
			top = Color(0.42, 0.55, 0.78)
			low = Color(0.86, 0.90, 0.96)
		"ord_snow":
			top = Color(0.60, 0.68, 0.80)
			low = Color(0.92, 0.95, 1.0)
	for i in 10:
		var k := float(i) / 9.0
		p.draw_rect(Rect2(0, sz.y * 0.075 * float(i), sz.x, sz.y * 0.075 + 1.0), top.lerp(low, k))
	p.draw_rect(Rect2(0, sz.y * 0.74, sz.x, sz.y * 0.26), low)
	if theme != "ord_snow":
		p.draw_circle(Vector2(sz.x * 0.8, sz.y * 0.16), 46.0, Color(1.0, 0.98, 0.85))      # The sun
		p.draw_circle(Vector2(sz.x * 0.8, sz.y * 0.16), 80.0, Color(1.0, 0.95, 0.7, 0.2))
	_storm(p, sz)
	for k in 4:                                                    # Soft clouds
		var cx := sz.x * (0.12 + 0.24 * float(k))
		var cy := sz.y * (0.12 + 0.05 * float(k % 2))
		for j in 3:
			p.draw_circle(Vector2(cx + float(j) * 34.0, cy + float(j % 2) * 6.0), 26.0, Color(1, 1, 1, 0.75))
	match theme:
		"ord_meadow":
			_hills(p, sz, Color(0.48, 0.72, 0.36), 0.62)
			_hills(p, sz, Color(0.38, 0.62, 0.28), 0.72)
		"ord_forest":
			_hills(p, sz, Color(0.30, 0.48, 0.30), 0.60)
			for i in 22:                                           # A wall of far pines
				var x := sz.x * float(i) / 21.0
				var h := 90.0 + 40.0 * absf(sin(float(i) * 1.9))
				p.draw_colored_polygon(PackedVector2Array([Vector2(x - 30, sz.y * 0.78), Vector2(x, sz.y * 0.78 - h), Vector2(x + 30, sz.y * 0.78)]), Color(0.14, 0.30, 0.18))
		"ord_town":
			_hills(p, sz, Color(0.50, 0.66, 0.40), 0.66)
			for i in 9:                                            # Far roofs + a church tower
				var x := sz.x * (0.05 + 0.11 * float(i))
				var y := sz.y * 0.74
				p.draw_rect(Rect2(x, y - 50, 70, 50), Color(0.72, 0.64, 0.54))
				p.draw_colored_polygon(PackedVector2Array([Vector2(x - 6, y - 50), Vector2(x + 35, y - 80), Vector2(x + 76, y - 50)]), Color(0.62, 0.28, 0.20))
			p.draw_rect(Rect2(sz.x * 0.52, sz.y * 0.74 - 160, 40, 160), Color(0.66, 0.62, 0.58))
			p.draw_colored_polygon(PackedVector2Array([Vector2(sz.x * 0.52 - 6, sz.y * 0.74 - 160), Vector2(sz.x * 0.52 + 20, sz.y * 0.74 - 220), Vector2(sz.x * 0.52 + 46, sz.y * 0.74 - 160)]), Color(0.32, 0.30, 0.36))
		"ord_jungle":
			_hills(p, sz, Color(0.18, 0.45, 0.28), 0.58)
			for i in 12:                                           # Canopy blobs
				p.draw_circle(Vector2(sz.x * float(i) / 11.0, sz.y * (0.66 + 0.03 * sin(float(i) * 2.0))), 70.0, Color(0.12, 0.38, 0.20))
			p.draw_rect(Rect2(0, sz.y * 0.72, sz.x, sz.y * 0.28), Color(0.10, 0.32, 0.16))
		"ord_desert":
			_hills(p, sz, Color(0.92, 0.78, 0.52), 0.66)
			_hills(p, sz, Color(0.86, 0.70, 0.44), 0.74)
			p.draw_colored_polygon(PackedVector2Array([Vector2(sz.x * 0.62, sz.y * 0.68), Vector2(sz.x * 0.70, sz.y * 0.52), Vector2(sz.x * 0.78, sz.y * 0.68)]), Color(0.80, 0.66, 0.42))
		"ord_mountain":
			for i in 4:                                            # Snowy peaks
				var bx := sz.x * (0.1 + 0.27 * float(i))
				var ph := sz.y * (0.30 + 0.08 * float(i % 2))
				p.draw_colored_polygon(PackedVector2Array([Vector2(bx - 220, sz.y * 0.8), Vector2(bx, ph), Vector2(bx + 220, sz.y * 0.8)]), Color(0.46, 0.48, 0.56))
				p.draw_colored_polygon(PackedVector2Array([Vector2(bx - 60, ph + 70), Vector2(bx, ph), Vector2(bx + 60, ph + 70)]), Color(0.96, 0.97, 1.0))
		"ord_snow":
			for i in 3:
				var bx2 := sz.x * (0.2 + 0.3 * float(i))
				p.draw_colored_polygon(PackedVector2Array([Vector2(bx2 - 260, sz.y * 0.8), Vector2(bx2, sz.y * 0.42), Vector2(bx2 + 260, sz.y * 0.8)]), Color(0.86, 0.90, 0.97))
			for k in 60:                                           # Falling snow (static flecks)
				p.draw_circle(Vector2(fmod(float(k * 131), sz.x), fmod(float(k * 71), sz.y * 0.8)), 2.0, Color(1, 1, 1, 0.8))
	p.draw_rect(Rect2(0, sz.y * 0.84, sz.x, sz.y * 0.16), low.darkened(0.15))


## The Storm: a low dark wall of cloud on the horizon, lightning inside it - and, far away above
## it, the STORM ITSELF (its true shape, StormArt), small and faint.
static func _storm(p: Control, sz: Vector2) -> void:
	StormArt.draw(p, Vector2(sz.x * 0.30, sz.y * 0.36), 0.22, 0.0, 0.5)
	var y := sz.y * 0.50
	for i in 26:
		var x := sz.x * float(i) / 25.0
		p.draw_circle(Vector2(x, y + 18.0 * sin(float(i) * 1.3)), 70.0 + 14.0 * sin(float(i) * 2.7), Color(0.20, 0.21, 0.30, 0.55))
	for k in 3:
		var bx := sz.x * (0.2 + 0.3 * float(k))
		p.draw_polyline(PackedVector2Array([Vector2(bx, y - 40), Vector2(bx + 12, y - 10), Vector2(bx - 4, y + 10), Vector2(bx + 10, y + 40)]), Color(0.8, 0.9, 1.0, 0.5), 2.0)


static func _hills(p: Control, sz: Vector2, col: Color, y0: float) -> void:
	var pts := PackedVector2Array([Vector2(0, sz.y)])
	for i in 13:
		var x := sz.x * float(i) / 12.0
		pts.append(Vector2(x, sz.y * (y0 + 0.04 * sin(float(i) * 1.4 + y0 * 10.0))))
	pts.append(Vector2(sz.x, sz.y))
	p.draw_colored_polygon(pts, col)
