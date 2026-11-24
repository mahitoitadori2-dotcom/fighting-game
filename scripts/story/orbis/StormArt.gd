class_name StormArt
extends RefCounted
## THE STORM - its TRUE SHAPE (the user's concept art, 2026-11-15): a colossal flying creature,
## wide and flat like a ray, its whole skin covered in EYES (the all-seeing eye is everywhere) and
## dark ORGAN spots. A long curved NECK rises from its back and ends in a crest of claws; a
## segmented TUBE (a vessel) climbs from its other side. All around it: DEBRIS it lifted from the
## ground - matter it can throw back down. Colours: the Storm's dark blue-grey + pale lightning.
##
##   StormArt.draw(c, center, scale, t)      the whole creature (center = body centre)
##   StormArt.draw_portrait(c, t)            a framed portrait, feet-at-origin like every portrait

const BODY := Color(0.20, 0.22, 0.32)
const BODY_SHADE := Color(0.11, 0.12, 0.19)
const BODY_HI := Color(0.38, 0.42, 0.58)
const SPOT := Color(0.06, 0.06, 0.10)
const EYE := Color(0.82, 0.90, 1.0)
const BOLT := Color(0.80, 0.90, 1.0)
const BLACK := Color(0, 0, 0)


static func draw(c, o: Vector2, s: float, t: float, alpha: float = 1.0) -> void:
	var a := alpha
	var bob := sin(t * 0.6) * 6.0 * s
	o += Vector2(0, bob)
	# Debris orbiting it (rocks, chunks of houses, trees) - behind and in front
	for i in 14:
		var ang := TAU * float(i) / 14.0 + t * 0.12
		var r := Vector2(320.0, 170.0) * s * (0.9 + 0.25 * sin(float(i) * 2.7))
		var p := o + Vector2(cos(ang) * r.x, sin(ang) * r.y)
		_debris(c, p, (10.0 + float(i % 4) * 5.0) * s, ang * 3.0 + float(i), a)
	# The tube / vessel: a segmented chimney climbing from the right side of its back
	var tube := o + Vector2(150, -60) * s
	for k in 7:
		var p0 := tube + Vector2(-float(k) * 9.0, -float(k) * 50.0) * s
		var p1 := tube + Vector2(-float(k + 1) * 9.0, -float(k + 1) * 50.0) * s
		c.draw_line(p0, p1, Color(0, 0, 0, a), 46.0 * s)
		c.draw_line(p0, p1, Color(BODY_SHADE.r, BODY_SHADE.g, BODY_SHADE.b, a), 38.0 * s)
		c.draw_line(p0 + Vector2(-18, 0) * s, p0 + Vector2(18, 0) * s, Color(BODY_HI.r, BODY_HI.g, BODY_HI.b, a), 3.0 * s)
	# The neck: a long hook rising from the left of its back, ending in a crest of claws
	var neck := PackedVector2Array()
	for k in 12:
		var u := float(k) / 11.0
		neck.append(o + Vector2(-90.0 + 110.0 * sin(u * 2.6), -40.0 - u * 400.0 + 110.0 * u * u) * s)
	var head := neck[neck.size() - 1]
	c.draw_polyline(neck, Color(0, 0, 0, a), 66.0 * s)
	c.draw_polyline(neck, Color(BODY.r, BODY.g, BODY.b, a), 56.0 * s)
	c.draw_polyline(neck, Color(BODY_HI.r, BODY_HI.g, BODY_HI.b, 0.5 * a), 10.0 * s)
	for f in 5:                                                    # The claw crest
		var dirv := Vector2.from_angle(-PI * 0.5 + (float(f) - 2.0) * 0.45 + sin(t * 1.5 + float(f)) * 0.08)
		var tip := head + dirv * 80.0 * s
		c.draw_line(head, tip, Color(0, 0, 0, a), 16.0 * s)
		c.draw_line(head, tip, Color(BODY_SHADE.r, BODY_SHADE.g, BODY_SHADE.b, a), 10.0 * s)
	c.draw_circle(head, 30.0 * s, Color(0, 0, 0, a))
	c.draw_circle(head, 24.0 * s, Color(BODY.r, BODY.g, BODY.b, a))
	c.draw_circle(head + Vector2(6, 3) * s, 10.0 * s, Color(EYE.r, EYE.g, EYE.b, a * (0.7 + 0.3 * sin(t * 2.0))))
	# The body: a huge flat ray shape (wing tips pointed), shaded underside
	var body := PackedVector2Array()
	for k in 24:
		var th := TAU * float(k) / 24.0
		var rx := 300.0 * (0.85 + 0.15 * absf(cos(th)))
		var ry := 120.0 * (0.8 + 0.2 * absf(sin(th)))
		var p := Vector2(cos(th) * rx, sin(th) * ry)
		if k == 0 or k == 12:                                      # Pointed wing tips
			p.x *= 1.18
		body.append(o + p * s)
	c.draw_colored_polygon(body, Color(BODY.r, BODY.g, BODY.b, a))
	var under := PackedVector2Array()
	for k in range(0, 13):
		under.append(body[k])
	c.draw_colored_polygon(under, Color(BODY_SHADE.r, BODY_SHADE.g, BODY_SHADE.b, 0.6 * a))
	# Organ spots + eyes all over its skin (seeded, so they never move around)
	for i in 30:
		var px := fmod(float(i) * 97.0, 520.0) - 260.0
		var py := fmod(float(i) * 53.0, 190.0) - 95.0
		if Vector2(px / 300.0, py / 115.0).length() > 0.9:
			continue
		var p := o + Vector2(px, py) * s
		if i % 3 == 0:
			var blink := fmod(t * 0.7 + float(i) * 0.37, 4.0) < 0.15
			c.draw_circle(p, 13.0 * s, Color(0, 0, 0, a))
			if not blink:
				c.draw_circle(p, 10.0 * s, Color(EYE.r, EYE.g, EYE.b, a))
				c.draw_circle(p + Vector2(2, 0) * s, 4.5 * s, Color(0, 0, 0, a))
		else:
			var spot := PackedVector2Array()
			for k in 6:
				var th := TAU * float(k) / 6.0
				spot.append(p + Vector2(cos(th), sin(th)) * (11.0 + float((i + k) % 3) * 5.0) * s)
			c.draw_colored_polygon(spot, Color(SPOT.r, SPOT.g, SPOT.b, a))
	var closed := body.duplicate()
	closed.append(body[0])
	c.draw_polyline(closed, Color(0, 0, 0, a), 5.0 * s)
	# Lightning crawling over it
	for k in 3:
		if fmod(t * 1.3 + float(k) * 0.8, 2.0) < 0.25:
			var x0 := (-180.0 + float(k) * 150.0) * s
			var bolt := PackedVector2Array([o + Vector2(x0, -60 * s), o + Vector2(x0 + 30 * s, -20 * s), o + Vector2(x0 - 10 * s, 20 * s), o + Vector2(x0 + 26 * s, 70 * s)])
			c.draw_polyline(bolt, Color(BOLT.r, BOLT.g, BOLT.b, 0.9 * a), 3.0 * s)


static func _debris(c, p: Vector2, r: float, rot: float, a: float) -> void:
	var pts := PackedVector2Array()
	for k in 5:
		var th := TAU * float(k) / 5.0 + rot
		pts.append(p + Vector2(cos(th), sin(th)) * r * (0.7 + 0.3 * float(k % 2)))
	c.draw_colored_polygon(pts, Color(0.10, 0.10, 0.12, a))


## A portrait (feet at the origin, ~230 px tall at scale 1 - like the other dialogue portraits).
static func draw_portrait(c: CanvasItem, t: float) -> void:
	draw(c, Vector2(0, -90), 0.32, t)
