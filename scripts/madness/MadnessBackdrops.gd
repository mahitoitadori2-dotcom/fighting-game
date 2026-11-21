class_name MadnessBackdrops
extends RefCounted
## MADNESS backdrop (painted by HellBackground, theme "madness"): black rock under a sky the colour
## of an old wound, and RED CHAINS hanging down out of hell above - dozens of them, some broken,
## some with hooks. Black and red only.

static func handles(theme: String) -> bool:
	return theme == "madness"


static func paint(p: Control, _theme: String, sz: Vector2) -> void:
	# Sky: black at the top (hell above) -> deep red at the horizon
	for i in 12:
		var k := float(i) / 11.0
		p.draw_rect(Rect2(0, sz.y * 0.07 * float(i), sz.x, sz.y * 0.07 + 1.0), Color(0.02, 0.0, 0.0).lerp(Color(0.38, 0.03, 0.02), k))
	p.draw_rect(Rect2(0, sz.y * 0.77, sz.x, sz.y * 0.23), Color(0.38, 0.03, 0.02))
	# Far glow of hell's fire low on the horizon
	for k in 5:
		p.draw_circle(Vector2(sz.x * (0.1 + 0.2 * float(k)), sz.y * 0.9), sz.x * 0.16, Color(0.8, 0.06, 0.02, 0.10))
	var rng := RandomNumberGenerator.new()
	rng.seed = 666
	# RED CHAINS out of the black above (back layer: thin + dark, front layer: thick + bright, random lengths)
	for layer in 2:
		var n := 16 if layer == 0 else 9
		for i in n:
			var x := rng.randf_range(0.0, sz.x)
			var chain_len := sz.y * rng.randf_range(0.25, 0.72)
			var w := 5.0 if layer == 0 else 9.0
			var col := Color(0.35, 0.02, 0.02) if layer == 0 else Color(0.70, 0.05, 0.04)
			var sway := rng.randf_range(-30.0, 30.0)
			_chain(p, Vector2(x, -10.0), Vector2(x + sway, chain_len), w, col)
			if rng.randf() < 0.4:                                         # A hook at the end
				var e := Vector2(x + sway, chain_len)
				p.draw_arc(e + Vector2(0, w * 2.0), w * 2.0, -PI * 0.2, PI * 1.1, 10, col, w * 0.6)
	# Black rock: three ridges of jagged stone in front of the red horizon
	for layer in 3:
		var base := sz.y * (0.70 + 0.09 * float(layer))
		var col := Color(0.10, 0.01, 0.01).darkened(0.25 * float(layer))
		var pts := PackedVector2Array([Vector2(0, sz.y)])
		var x := 0.0
		while x <= sz.x + 60.0:
			pts.append(Vector2(x, base - rng.randf_range(10.0, 90.0 - float(layer) * 20.0)))
			x += rng.randf_range(40.0, 110.0)
		pts.append(Vector2(sz.x, sz.y))
		p.draw_colored_polygon(pts, col)
	# Spikes of rock jutting up, and a few hanging skulls of chain victims
	for i in 7:
		var bx := rng.randf_range(0.0, sz.x)
		var bh := rng.randf_range(60.0, 160.0)
		p.draw_colored_polygon(PackedVector2Array([Vector2(bx - 18, sz.y * 0.86), Vector2(bx + 18, sz.y * 0.86), Vector2(bx + 4, sz.y * 0.86 - bh)]), Color(0.05, 0.0, 0.0))


static func _chain(p: Control, a: Vector2, b: Vector2, w: float, col: Color) -> void:
	var n := int(a.distance_to(b) / (w * 1.4))
	for i in n:
		var c := a.lerp(b, (float(i) + 0.5) / float(maxi(n, 1)))
		var vert := i % 2 == 0
		var r := Rect2(c - (Vector2(w * 0.45, w * 0.8) if vert else Vector2(w * 0.8, w * 0.45)), Vector2(w * 0.9, w * 1.6) if vert else Vector2(w * 1.6, w * 0.9))
		p.draw_rect(r, col, false, maxf(w * 0.3, 1.5))
