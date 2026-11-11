class_name AchievementArt
extends RefCounted
## ACHIEVEMENT ARTWORK, drawn with code like the rest of the game (no image files):
## a rounded card in the achievement's colour with turning light rays, the SUBJECT in the
## middle (the real portrait of the character / boss / enemy, or a big icon), a metal FRAME
## (gold / silver / bronze / purple / red / galaxy) and a corner EMBLEM saying what kind of
## achievement it is. Locked ones are painted almost black (very dark silhouette + lock).
## Used by AchievementToast, the ACHIEVEMENTS menu and the Story board badges (draw_icon).

const FRAMES := {
	"gold": [Color(1.0, 0.80, 0.30), Color(0.55, 0.36, 0.06), Color(1.0, 0.95, 0.70)],
	"silver": [Color(0.84, 0.88, 0.94), Color(0.40, 0.45, 0.54), Color(1.0, 1.0, 1.0)],
	"bronze": [Color(0.88, 0.55, 0.27), Color(0.45, 0.24, 0.09), Color(1.0, 0.80, 0.58)],
	"purple": [Color(0.78, 0.48, 1.0), Color(0.34, 0.12, 0.56), Color(0.96, 0.86, 1.0)],
	"red": [Color(1.0, 0.34, 0.26), Color(0.52, 0.07, 0.05), Color(1.0, 0.76, 0.66)],
	"galaxy": [Color(0.60, 0.78, 1.0), Color(0.30, 0.08, 0.55), Color(1.0, 0.92, 1.0)],
}
## Figure scale for Story enemies at a 100 px card (the board's FIGURE_SCALE is used for
## the rest; these are the extension bosses and a few that need their own size).
const ENEMY_SCALE := {"caeser_grave": 0.17, "saint_golem": 0.15, "void_horrid": 0.36, "rad_chorus": 0.12,
	"forge_father": 0.15, "atomic": 0.26, "escapist": 0.55, "masker": 0.30, "shining": 0.42}
const BLACK := Color(0, 0, 0)
const SLASH := Color(0.95, 0.18, 0.15)


## The whole card for achievement d in rect r. t animates rays / portraits.
static func draw(c: CanvasItem, d: Dictionary, r: Rect2, t: float, locked: bool = false) -> void:
	var art: Dictionary = d.get("art", {})
	var fr: Array = FRAMES.get(String(art.get("frame", "gold")), FRAMES["gold"])
	var bg: Color = art.get("bg", Color(0.2, 0.2, 0.3))
	var s := minf(r.size.x, r.size.y)
	var center := r.get_center()
	var shape := FighterArt.rrect_points(r, s * 0.14)

	# Background gradient (light top -> dark bottom)
	var cols := PackedColorArray()
	for p in shape:
		var k := clampf((p.y - r.position.y) / r.size.y, 0.0, 1.0)
		cols.append(bg.lightened(0.28).lerp(bg.darkened(0.55), k))
	c.draw_polygon(shape, cols)
	# Turning light rays + glow behind the subject
	var gold: Color = fr[0]
	for i in 12:
		var a := TAU * float(i) / 12.0 + t * 0.25
		var tri := PackedVector2Array([center, center + Vector2.from_angle(a - 0.11) * s * 0.47, center + Vector2.from_angle(a + 0.11) * s * 0.47])
		c.draw_colored_polygon(tri, Color(gold.r, gold.g, gold.b, 0.10))
	c.draw_circle(center, s * 0.34, Color(gold.r, gold.g, gold.b, 0.16))
	c.draw_circle(center, s * 0.22, Color(1, 1, 1, 0.07))

	# Subject
	if String(art.get("big", "")) == "galaxy":
		_galaxy(c, center, s * 0.40, t)
	elif art.has("script") or art.has("enemy") or art.has("hero"):
		_portrait(c, art, r, t)
	else:
		draw_icon(c, String(art.get("big", "star")), center + Vector2(0, s * 0.03), s * 0.30, fr)
	if art.has("num"):                                      # Colosseum number
		var roman := ["I", "II", "III", "IV", "V"]
		FighterArt.label(c, Vector2(center.x, r.position.y + s * 0.24), String(roman[clampi(int(art["num"]) - 1, 0, 4)]), int(s * 0.17), Color(1, 1, 1))

	# Frame: black outline, metal band, thin shine
	var closed := shape.duplicate()
	closed.append(shape[0])
	c.draw_polyline(closed, BLACK, maxf(s * 0.075, 3.0), true)
	if String(art.get("frame", "")) == "galaxy":
		for i in closed.size() - 1:                         # Rainbow-nebula frame
			var hue := fmod(float(i) / float(closed.size()) + t * 0.15, 1.0)
			c.draw_line(closed[i], closed[i + 1], Color.from_hsv(0.55 + 0.35 * hue, 0.65, 1.0), maxf(s * 0.045, 2.0), true)
	else:
		c.draw_polyline(closed, fr[0], maxf(s * 0.045, 2.0), true)
	var inner := FighterArt.rrect_points(r.grow(-s * 0.06), s * 0.10)
	inner.append(inner[0])
	c.draw_polyline(inner, Color(fr[2].r, fr[2].g, fr[2].b, 0.35), maxf(s * 0.012, 1.0), true)

	# Corner emblem
	if art.has("emblem"):
		var e := r.end - Vector2(s * 0.17, s * 0.17)
		c.draw_circle(e, s * 0.145, BLACK)
		c.draw_circle(e, s * 0.12, fr[1])
		c.draw_arc(e, s * 0.12, 0.0, TAU, 24, fr[0], maxf(s * 0.02, 1.0), true)
		draw_icon(c, String(art["emblem"]), e, s * 0.085, fr)

	if locked:                                              # Very black + a padlock
		c.draw_colored_polygon(shape, Color(0.01, 0.01, 0.02, 0.95))
		c.draw_polyline(closed, Color(0.22, 0.22, 0.26), maxf(s * 0.03, 1.5), true)
		_padlock(c, center, s * 0.13)


static func _portrait(c: CanvasItem, art: Dictionary, r: Rect2, t: float) -> void:
	var feet := Vector2(r.get_center().x, r.end.y - r.size.y * 0.13)
	var box := r.size.y * 0.72                              # Height the figure should reach
	if art.has("script") or art.has("hero"):
		var scr: Script = art["script"] if art.has("script") else StoryLevels.hero_art(String(art["hero"]))
		var h := float(scr.get_script_constant_map().get("PORTRAIT_H", 135.0))
		var sc := box / h
		c.draw_set_transform(feet, 0.0, Vector2(sc, sc))
		scr.call("draw_portrait", c, t)
	else:
		var id := String(art["enemy"])
		var base := StoryLevels.base_id(id)
		var fs: float = ENEMY_SCALE.get(base, StoryBoard.FIGURE_SCALE.get(base, 0.3))
		var sc := fs * box / 62.0
		c.draw_set_transform(feet, 0.0, Vector2(sc, sc))
		StoryLevels.draw_portrait(c, id, t)
	c.draw_set_transform(Vector2.ZERO, 0.0, Vector2.ONE)


# ============================================================
# ICONS (also the Story board badges)
# ============================================================
## Icon `kind` centred at p, about 2*size wide. fr = frame colours [main, dark, shine].
## slash = false: the "no_..." icons without the red crossed-out ring (tiny board badges).
static func draw_icon(c: CanvasItem, kind: String, p: Vector2, size: float, fr: Array = FRAMES["gold"], slash: bool = true) -> void:
	var w := maxf(size * 0.16, 1.5)                         # Outline width
	if not slash and kind.begins_with("no_"):
		w = maxf(size * 0.12, 1.0)
	match kind:
		"trophy":
			var cup := PackedVector2Array([p + Vector2(-0.75, -0.8) * size, p + Vector2(0.75, -0.8) * size,
				p + Vector2(0.55, -0.1) * size, p + Vector2(0.15, 0.2) * size, p + Vector2(-0.15, 0.2) * size, p + Vector2(-0.55, -0.1) * size])
			for sd: float in [-1.0, 1.0]:
				c.draw_arc(p + Vector2(sd * 0.72, -0.48) * size, size * 0.3, 0.0, TAU, 14, BLACK, w * 1.6, true)
				c.draw_arc(p + Vector2(sd * 0.72, -0.48) * size, size * 0.3, 0.0, TAU, 14, fr[0], w * 0.8, true)
			_poly(c, cup, Color(1.0, 0.82, 0.3), w)
			_poly(c, _rect(p + Vector2(-0.12, 0.2) * size, Vector2(0.24, 0.4) * size), Color(0.9, 0.7, 0.25), w)
			_poly(c, _rect(p + Vector2(-0.5, 0.58) * size, Vector2(1.0, 0.28) * size), Color(0.75, 0.55, 0.2), w)
			c.draw_line(p + Vector2(-0.45, -0.62) * size, p + Vector2(-0.3, -0.25) * size, Color(1, 1, 0.9, 0.9), w, true)
		"fist":
			_poly(c, _rect(p + Vector2(-0.6, -0.45) * size, Vector2(1.2, 0.95) * size), Color(0.95, 0.78, 0.6), w)
			for i in 3:
				c.draw_line(p + Vector2(-0.6 + 0.4 * float(i + 1), -0.45) * size, p + Vector2(-0.6 + 0.4 * float(i + 1), -0.1) * size, BLACK, w * 0.7, true)
			_poly(c, _rect(p + Vector2(-0.75, -0.05) * size, Vector2(0.4, 0.4) * size), Color(0.88, 0.70, 0.52), w)
			_poly(c, _rect(p + Vector2(-0.35, 0.5) * size, Vector2(0.7, 0.4) * size), Color(0.3, 0.3, 0.36), w)
		"star":
			_poly(c, _star(p, size * 0.95, size * 0.42, 5), fr[0], w)
		"sword":
			_poly(c, PackedVector2Array([p + Vector2(-0.12, 0.25) * size, p + Vector2(-0.12, -0.75) * size, p + Vector2(0, -0.95) * size,
				p + Vector2(0.12, -0.75) * size, p + Vector2(0.12, 0.25) * size]), Color(0.85, 0.88, 0.95), w)
			_poly(c, _rect(p + Vector2(-0.45, 0.22) * size, Vector2(0.9, 0.16) * size), fr[0], w)
			_poly(c, _rect(p + Vector2(-0.09, 0.38) * size, Vector2(0.18, 0.42) * size), Color(0.4, 0.25, 0.15), w)
		"halo":
			c.draw_set_transform(p + Vector2(0, -0.35) * size, 0.0, Vector2(1.0, 0.38))
			c.draw_arc(Vector2.ZERO, size * 0.75, 0.0, TAU, 28, BLACK, w * 2.6, true)
			c.draw_arc(Vector2.ZERO, size * 0.75, 0.0, TAU, 28, Color(1.0, 0.92, 0.5), w * 1.3, true)
			c.draw_set_transform(Vector2.ZERO, 0.0, Vector2.ONE)
			_poly(c, _star(p + Vector2(0, 0.35) * size, size * 0.5, size * 0.18, 4), Color(1, 1, 0.9), w)
		"solo":
			c.draw_circle(p + Vector2(0, -0.5) * size, size * 0.3 + w, BLACK)
			c.draw_circle(p + Vector2(0, -0.5) * size, size * 0.3, fr[0])
			_poly(c, PackedVector2Array([p + Vector2(-0.5, 0.85) * size, p + Vector2(-0.3, -0.1) * size, p + Vector2(0.3, -0.1) * size, p + Vector2(0.5, 0.85) * size]), fr[0], w)
			_poly(c, _star(p + Vector2(0.62, -0.62) * size, size * 0.3, size * 0.13, 5), Color(1, 1, 0.85), w * 0.6)
		"crown":
			_poly(c, PackedVector2Array([p + Vector2(-0.85, 0.5) * size, p + Vector2(-0.85, -0.45) * size, p + Vector2(-0.42, 0.0) * size,
				p + Vector2(0, -0.7) * size, p + Vector2(0.42, 0.0) * size, p + Vector2(0.85, -0.45) * size, p + Vector2(0.85, 0.5) * size]), Color(1.0, 0.82, 0.3), w)
			for k: float in [-0.5, 0.0, 0.5]:
				c.draw_circle(p + Vector2(k, 0.25) * size, size * 0.11, Color(0.9, 0.15, 0.25) if k == 0.0 else Color(0.25, 0.6, 1.0))
		"skull":
			c.draw_circle(p + Vector2(0, -0.15) * size, size * 0.7 + w, BLACK)
			c.draw_circle(p + Vector2(0, -0.15) * size, size * 0.7, Color(0.95, 0.93, 0.85))
			_poly(c, _rect(p + Vector2(-0.38, 0.35) * size, Vector2(0.76, 0.45) * size), Color(0.95, 0.93, 0.85), w)
			for sd: float in [-1.0, 1.0]:
				c.draw_circle(p + Vector2(sd * 0.28, -0.15) * size, size * 0.2, BLACK)
			c.draw_line(p + Vector2(0, 0.5) * size, p + Vector2(0, 0.8) * size, BLACK, w * 0.7)
		"badge":
			_poly(c, PackedVector2Array([p + Vector2(-0.7, -0.85) * size, p + Vector2(0.7, -0.85) * size, p + Vector2(0.7, 0.1) * size,
				p + Vector2(0, 0.9) * size, p + Vector2(-0.7, 0.1) * size]), fr[0], w)
			_poly(c, _star(p + Vector2(0, -0.1) * size, size * 0.45, size * 0.2, 5), Color(1, 1, 1), w * 0.6)
		"sun":
			for i in 10:
				var a := TAU * float(i) / 10.0
				c.draw_line(p + Vector2.from_angle(a) * size * 0.55, p + Vector2.from_angle(a) * size * 0.95, Color(1.0, 0.85, 0.3), w * 1.2, true)
			c.draw_circle(p, size * 0.5 + w, BLACK)
			c.draw_circle(p, size * 0.5, Color(1.0, 0.9, 0.45))
		"galaxy":
			_galaxy(c, p, size, 0.0)
		"no_powers":
			_poly(c, PackedVector2Array([p + Vector2(0.15, -0.95) * size, p + Vector2(-0.5, 0.1) * size, p + Vector2(-0.05, 0.1) * size,
				p + Vector2(-0.2, 0.95) * size, p + Vector2(0.55, -0.15) * size, p + Vector2(0.08, -0.15) * size]), Color(1.0, 0.85, 0.2), w)
			if slash:
				_slash(c, p, size, w)
		"no_blocks":
			_poly(c, PackedVector2Array([p + Vector2(-0.65, -0.75) * size, p + Vector2(0.65, -0.75) * size, p + Vector2(0.6, 0.15) * size,
				p + Vector2(0, 0.85) * size, p + Vector2(-0.6, 0.15) * size]), Color(0.45, 0.7, 1.0), w)
			c.draw_line(p + Vector2(0, -0.6) * size, p + Vector2(0, 0.6) * size, Color(0.85, 0.95, 1.0), w, true)
			if slash:
				_slash(c, p, size, w)
		"no_healing":
			_poly(c, PackedVector2Array([p + Vector2(-0.18, -0.85) * size, p + Vector2(0.18, -0.85) * size, p + Vector2(0.18, -0.3) * size,
				p + Vector2(0.6, 0.25) * size, p + Vector2(0.45, 0.8) * size, p + Vector2(-0.45, 0.8) * size, p + Vector2(-0.6, 0.25) * size,
				p + Vector2(-0.18, -0.3) * size]), Color(0.35, 0.9, 0.4), w)
			c.draw_line(p + Vector2(-0.3, 0.35) * size, p + Vector2(0.3, 0.35) * size, Color(1, 1, 1), w, true)
			c.draw_line(p + Vector2(0, 0.08) * size, p + Vector2(0, 0.62) * size, Color(1, 1, 1), w, true)
			if slash:
				_slash(c, p, size, w)
		"no_gauge":
			for i in 3:
				_poly(c, _rect(p + Vector2(-0.85 + 0.6 * float(i), -0.25) * size, Vector2(0.5, 0.5) * size), Color(0.15, 0.6, 1.0), w)
			if slash:
				_slash(c, p, size, w)
		_:
			_poly(c, _star(p, size * 0.9, size * 0.4, 5), fr[0], w)


static func _slash(c: CanvasItem, p: Vector2, size: float, w: float) -> void:
	c.draw_arc(p, size * 0.98, 0.0, TAU, 28, BLACK, w * 2.2, true)
	c.draw_arc(p, size * 0.98, 0.0, TAU, 28, SLASH, w * 1.2, true)
	var d := Vector2(0.7, -0.7) * size * 0.98
	c.draw_line(p - d, p + d, BLACK, w * 2.2, true)
	c.draw_line(p - d, p + d, SLASH, w * 1.2, true)


static func _poly(c: CanvasItem, pts: PackedVector2Array, col: Color, w: float) -> void:
	c.draw_colored_polygon(pts, col)
	FighterArt.outline(c, pts, w)


static func _rect(pos: Vector2, sz: Vector2) -> PackedVector2Array:
	return PackedVector2Array([pos, pos + Vector2(sz.x, 0), pos + sz, pos + Vector2(0, sz.y)])


static func _star(p: Vector2, r1: float, r2: float, n: int) -> PackedVector2Array:
	var pts := PackedVector2Array()
	for i in n * 2:
		var a := -PI * 0.5 + PI * float(i) / float(n)
		pts.append(p + Vector2.from_angle(a) * (r1 if i % 2 == 0 else r2))
	return pts


static func _padlock(c: CanvasItem, p: Vector2, s: float) -> void:
	var dim := Color(0.30, 0.30, 0.36)
	c.draw_arc(p + Vector2(0, -0.35) * s, s * 0.55, PI, TAU, 16, dim, s * 0.22, true)
	c.draw_colored_polygon(_rect(p + Vector2(-0.85, -0.3) * s, Vector2(1.7, 1.3) * s), dim)
	c.draw_circle(p + Vector2(0, 0.3) * s, s * 0.2, Color(0.05, 0.05, 0.07))


## A spiral galaxy: nebula clouds, two arms of stars, a bright core (the Multiversal art).
static func _galaxy(c: CanvasItem, p: Vector2, size: float, t: float) -> void:
	c.draw_circle(p, size * 1.0, Color(0.30, 0.10, 0.55, 0.45))
	c.draw_circle(p + Vector2(size * 0.25, -size * 0.15), size * 0.6, Color(0.85, 0.25, 0.70, 0.25))
	c.draw_circle(p + Vector2(-size * 0.3, size * 0.2), size * 0.55, Color(0.20, 0.45, 1.0, 0.28))
	for arm in 2:
		for i in 26:
			var k := float(i) / 26.0
			var a := float(arm) * PI + k * 4.2 + t * 0.6
			var rr := size * (0.12 + 0.85 * k)
			var col := Color.from_hsv(fmod(0.62 + 0.3 * k, 1.0), 0.5, 1.0, 0.95 - 0.5 * k)
			c.draw_circle(p + Vector2.from_angle(a) * rr, size * (0.07 - 0.04 * k), col)
	for i in 9:                                                  # Twinkling stars
		var a := float(i) * 2.399
		var rr := size * (0.3 + 0.7 * fmod(float(i) * 0.37, 1.0))
		var tw := 0.5 + 0.5 * sin(t * 3.0 + float(i) * 1.7)
		c.draw_circle(p + Vector2.from_angle(a) * rr, size * 0.035 * (0.6 + tw), Color(1, 1, 1, 0.6 + 0.4 * tw))
	c.draw_circle(p, size * 0.2, Color(1.0, 0.9, 1.0, 0.85))
	c.draw_circle(p, size * 0.1, Color(1, 1, 1))
