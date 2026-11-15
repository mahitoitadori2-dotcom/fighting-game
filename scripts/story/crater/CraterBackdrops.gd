class_name CraterBackdrops
extends RefCounted
## TERRA CRATERUM backdrops, painted by HellBackground (far landscape behind the open world; each
## is also a Versus map). Inside a giant crater: a smoky red-brown sky, the crater rim all around,
## volcanoes glowing.
##   "crater_floor"   the Crater Floor: the rim, three erupting volcanoes, ash falling
##   "crater_wreck"   the Kharleming Wreck: the broken hull of the ancient ship against the sky
##   "crater_fields"  the Magma Fields: rivers of lava winding to the horizon
##   "crater_front"   the War Front: fires on the rim, smoke columns, war banners

const THEMES := ["crater_floor", "crater_wreck", "crater_fields", "crater_front"]
const SKY_TOP := Color(0.10, 0.05, 0.05)
const SKY_LOW := Color(0.42, 0.16, 0.08)


static func handles(theme: String) -> bool:
	return THEMES.has(theme)


static func paint(p: Control, theme: String, sz: Vector2) -> void:
	# Sky: dark at the top, glowing red at the rim
	for i in 10:
		var k := float(i) / 9.0
		p.draw_rect(Rect2(0, sz.y * 0.07 * float(i), sz.x, sz.y * 0.07 + 1.0), SKY_TOP.lerp(SKY_LOW, k))
	p.draw_rect(Rect2(0, sz.y * 0.70, sz.x, sz.y * 0.30), SKY_LOW.darkened(0.3))
	# The crater RIM (far, all the way across)
	var rim := PackedVector2Array([Vector2(0, sz.y)])
	for i in 13:
		var x := sz.x * float(i) / 12.0
		rim.append(Vector2(x, sz.y * (0.50 + 0.06 * sin(float(i) * 1.7) + 0.03 * sin(float(i) * 4.1))))
	rim.append(Vector2(sz.x, sz.y))
	p.draw_colored_polygon(rim, Color(0.14, 0.07, 0.06))
	match theme:
		"crater_floor":
			for i in 3:
				_volcano(p, Vector2(sz.x * (0.18 + 0.32 * float(i)), sz.y * 0.62), 150.0 + float(i % 2) * 70.0, i)
			_ash(p, sz, 3)
		"crater_wreck":
			_volcano(p, Vector2(sz.x * 0.82, sz.y * 0.6), 160.0, 1)
			# The broken hull of the ancient ship: a long tilted shape with ribs, half buried
			var hull := PackedVector2Array([Vector2(sz.x * 0.05, sz.y * 0.70), Vector2(sz.x * 0.12, sz.y * 0.38), Vector2(sz.x * 0.46, sz.y * 0.30),
				Vector2(sz.x * 0.66, sz.y * 0.44), Vector2(sz.x * 0.70, sz.y * 0.72)])
			p.draw_colored_polygon(hull, Color(0.12, 0.12, 0.14))
			for k in 6:
				var rx := sz.x * (0.14 + 0.09 * float(k))
				p.draw_line(Vector2(rx, sz.y * 0.36), Vector2(rx + 20.0, sz.y * 0.70), Color(0.07, 0.07, 0.08), 6.0)
			for k in 5:                                            # Cyan lights still blinking in the hull
				p.draw_circle(Vector2(sz.x * (0.18 + 0.1 * float(k)), sz.y * (0.42 + 0.03 * float(k % 2))), 4.0, Color(0.35, 1.0, 1.0, 0.6))
			for k in 4:                                            # Smoke rising from the crash
				p.draw_circle(Vector2(sz.x * 0.4 + float(k) * 20.0, sz.y * (0.26 - 0.06 * float(k))), 30.0 + float(k) * 16.0, Color(0.16, 0.14, 0.14, 0.35))
		"crater_fields":
			_volcano(p, Vector2(sz.x * 0.5, sz.y * 0.58), 210.0, 2)
			for k in 3:                                            # Rivers of lava winding to the horizon
				var river := PackedVector2Array()
				for i in 9:
					var u := float(i) / 8.0
					river.append(Vector2(sz.x * (0.1 + 0.3 * float(k)) + sin(u * 6.0 + float(k)) * 60.0, sz.y * (0.62 + 0.38 * u)))
				p.draw_polyline(river, Color(1.0, 0.4, 0.1, 0.8), 6.0 + float(k) * 3.0)
				p.draw_polyline(river, Color(1.0, 0.8, 0.3, 0.7), 2.0)
			_ash(p, sz, 5)
		"crater_front":
			for i in 2:
				_volcano(p, Vector2(sz.x * (0.25 + 0.5 * float(i)), sz.y * 0.6), 170.0, i + 1)
			for k in 6:                                            # Fires along the rim + smoke columns
				var fx := sz.x * (0.08 + 0.17 * float(k))
				var fy := sz.y * (0.52 + 0.04 * sin(float(k) * 2.0))
				p.draw_circle(Vector2(fx, fy), 18.0, Color(1.0, 0.45, 0.1, 0.45))
				for s in 4:
					p.draw_circle(Vector2(fx + float(s) * 6.0, fy - 30.0 - float(s) * 34.0), 12.0 + float(s) * 7.0, Color(0.15, 0.12, 0.12, 0.25))
			for k in 4:                                            # War banners on the near slope
				var bx := sz.x * (0.12 + 0.25 * float(k))
				var by := sz.y * 0.74
				p.draw_line(Vector2(bx, by), Vector2(bx, by - 110.0), Color(0.05, 0.03, 0.03), 4.0)
				p.draw_colored_polygon(PackedVector2Array([Vector2(bx, by - 108), Vector2(bx + 40, by - 96), Vector2(bx, by - 80)]),
					Color(0.5, 0.1, 0.05) if k % 2 == 0 else Color(0.2, 0.22, 0.26))
	# Near ground
	p.draw_rect(Rect2(0, sz.y * 0.82, sz.x, sz.y * 0.18), Color(0.08, 0.04, 0.04))


static func _volcano(p: Control, base: Vector2, h: float, i: int) -> void:
	var w := h * 1.4
	var cone := PackedVector2Array([base + Vector2(-w, 0), base + Vector2(-w * 0.18, -h), base + Vector2(w * 0.18, -h), base + Vector2(w, 0)])
	p.draw_colored_polygon(cone, Color(0.11, 0.06, 0.06))
	var top := base + Vector2(0, -h)
	p.draw_circle(top, h * 0.5, Color(1.0, 0.35, 0.1, 0.10))
	p.draw_circle(top, h * 0.22, Color(1.0, 0.5, 0.15, 0.25))
	p.draw_polyline(PackedVector2Array([top + Vector2(-8, 4), top + Vector2(-30, h * 0.4), top + Vector2(-14, h * 0.75)]), Color(1.0, 0.45, 0.1, 0.8), 4.0)
	for k in 4:                                                    # Smoke from the top
		p.draw_circle(top + Vector2(float(k) * 14.0 - 10.0, -30.0 - float(k) * 40.0), 24.0 + float(k) * 14.0, Color(0.16, 0.12, 0.12, 0.28 - 0.04 * float(i)))


static func _ash(p: Control, sz: Vector2, seed_v: int) -> void:
	for k in 40:                                                   # Falling ash (static flecks)
		var x := fmod(float(k * 97 + seed_v * 31), sz.x)
		var y := fmod(float(k * 53 + seed_v * 17), sz.y * 0.8)
		p.draw_rect(Rect2(x, y, 2, 2), Color(0.6, 0.5, 0.45, 0.4))
