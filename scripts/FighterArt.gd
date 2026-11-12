class_name FighterArt
extends RefCounted
## Drawing helpers for the flat cartoon look: thick black HAND-DRAWN outlines
## (slightly wavy, never ruler-straight), soft gradient shading (lit side /
## shaded side) and highlights. Pure visuals: hitboxes never depend on this.

const BLACK := Color(0.0, 0.0, 0.0, 1.0)
const WOBBLE := 0.9              # Outline waviness in px
## Smooth (antialiased) lines? A smoothed line costs THREE GPU draw calls, a plain one costs one
## (and plain lines/rects batch together). Every art script passes this instead of `true`.
## GraphicsSettings: off on FAST / POTATO (phones), on for REGULAR / REAL.
static var AA := true


## Deterministic "hand-drawn" offset for a point (stable, so lines don't jitter randomly).
static func _noise(p: Vector2) -> float:
	return sin(p.x * 0.37 + p.y * 0.23) * 0.6 + sin(p.x * 0.11 - p.y * 0.41) * 0.4


## Push every point a little along its outward direction from `center`.
static func wobble(pts: PackedVector2Array, center: Vector2, amp: float = WOBBLE) -> PackedVector2Array:
	var out := PackedVector2Array()
	for p in pts:
		var d := (p - center)
		var n := d.normalized() if d.length() > 0.01 else Vector2.UP
		out.append(p + n * _noise(p) * amp)
	return out


## Closed wavy outline.
static func outline(c: CanvasItem, pts: PackedVector2Array, width: float = 4.0, col: Color = BLACK) -> void:
	if pts.size() < 2:
		return
	var center := Vector2.ZERO
	for p in pts:
		center += p
	center /= float(pts.size())
	var w := wobble(pts, center)
	w.append(w[0])
	c.draw_polyline(w, col, width, FighterArt.AA)


static func rrect_points(rect: Rect2, r: float) -> PackedVector2Array:
	r = minf(r, minf(rect.size.x, rect.size.y) * 0.5)
	var pts := PackedVector2Array()
	var corners := [
		[rect.position + Vector2(rect.size.x - r, r), -PI / 2.0],
		[rect.position + Vector2(rect.size.x - r, rect.size.y - r), 0.0],
		[rect.position + Vector2(r, rect.size.y - r), PI / 2.0],
		[rect.position + Vector2(r, r), PI],
	]
	for c in corners:
		var center: Vector2 = c[0]
		var a0: float = c[1]
		for i in 5:
			var a := a0 + (PI / 2.0) * float(i) / 4.0
			pts.append(center + Vector2(cos(a), sin(a)) * r)
	return pts


## Rounded body part with GRADIENT shading: lit side (top-left) = base,
## far side (bottom-right) fades into shade; highlight streak; wavy black outline.
static func rrect(c: CanvasItem, rect: Rect2, base: Color, shade: Color, hi: Color, radius: float = 6.0, outline_w: float = 4.0) -> void:
	radius = maxf(radius, minf(rect.size.x, rect.size.y) * 0.3)      # Never a sharp box
	var outer := rrect_points(rect, radius)
	var cols := PackedColorArray()
	for p in outer:
		var u := (p.x - rect.position.x) / maxf(rect.size.x, 1.0) * 0.7 + (p.y - rect.position.y) / maxf(rect.size.y, 1.0) * 0.3
		cols.append(base.lerp(shade, smoothstep(0.35, 1.0, u)))
	c.draw_polygon(outer, cols)
	var h := Rect2(rect.position + rect.size * Vector2(0.14, 0.1), Vector2(maxf(rect.size.x * 0.14, 2.5), rect.size.y * 0.3))
	c.draw_colored_polygon(rrect_points(h, 2.0), Color(hi.r, hi.g, hi.b, hi.a * 0.9))
	outline(c, outer, outline_w)


## Soft round blob with a wavy outline, shaded side and highlight.
static func ball(c: CanvasItem, center: Vector2, r: float, base: Color, shade: Color, hi: Color) -> void:
	var rim := PackedVector2Array()
	for i in 20:
		var a := TAU * float(i) / 20.0
		rim.append(center + Vector2(cos(a), sin(a)) * (r + 2.5))
	c.draw_colored_polygon(wobble(rim, center, 0.8), BLACK)
	c.draw_circle(center, r, shade)
	c.draw_circle(center + Vector2(-r * 0.12, -r * 0.12), r * 0.82, base)
	c.draw_circle(center + Vector2(-r * 0.38, -r * 0.4), r * 0.22, hi)


## Thick stick-style limb with round caps, outline, shaded underside and a highlight.
static func limb(c: CanvasItem, a: Vector2, b: Vector2, w: float, base: Color, shade: Color, hi: Color) -> void:
	var ow := w + 6.0
	c.draw_line(a, b, BLACK, ow, FighterArt.AA)
	c.draw_circle(a, ow * 0.5, BLACK)
	c.draw_circle(b, ow * 0.5, BLACK)
	c.draw_line(a, b, shade, w, FighterArt.AA)
	c.draw_circle(a, w * 0.5, shade)
	c.draw_circle(b, w * 0.5, shade)
	var o1 := Vector2(-w * 0.12, -w * 0.12)
	c.draw_line(a + o1, b + o1, base, w * 0.7, FighterArt.AA)
	c.draw_circle(a + o1, w * 0.35, base)
	c.draw_circle(b + o1, w * 0.35, base)
	var o2 := Vector2(-w * 0.25, -w * 0.25)
	c.draw_line(a.lerp(b, 0.15) + o2, a.lerp(b, 0.8) + o2, hi, maxf(w * 0.2, 1.5), FighterArt.AA)


## Organic CURVED spike from base to tip (sides bow out, tip leans by `bend`).
static func curved_spike_points(base: Vector2, tip: Vector2, half_w: float, bend: float = 0.25) -> PackedVector2Array:
	var d := tip - base
	var n := Vector2(-d.y, d.x).normalized()
	var left := base + n * half_w
	var right := base - n * half_w
	var ctrl_l := base.lerp(tip, 0.5) + n * half_w * 0.9 + n * d.length() * bend * 0.3
	var ctrl_r := base.lerp(tip, 0.5) - n * half_w * 0.4 + n * d.length() * bend * 0.3
	var pts := PackedVector2Array()
	for i in 7:
		var t := float(i) / 6.0
		pts.append(left.lerp(ctrl_l, t).lerp(ctrl_l.lerp(tip, t), t))
	for i in range(1, 7):
		var t := 1.0 - float(i) / 6.0
		pts.append(right.lerp(ctrl_r, t).lerp(ctrl_r.lerp(tip, t), t))
	return pts


## Curved spike with a base->tip GRADIENT and wavy outline.
static func curved_spike(c: CanvasItem, base: Vector2, tip: Vector2, half_w: float, col_base: Color, col_tip: Color, bend: float = 0.25, outline_w: float = 2.5) -> void:
	var pts := curved_spike_points(base, tip, half_w, bend)
	var cols := PackedColorArray()
	var span := maxf((tip - base).length(), 1.0)
	for p in pts:
		cols.append(col_base.lerp(col_tip, clampf((p - base).length() / span, 0.0, 1.0)))
	c.draw_polygon(pts, cols)
	outline(c, pts, outline_w, Color(0, 0, 0, col_base.a))


## Beam with a GRADIENT: edge colour at the rims -> core colour in the middle.
static func beam_gradient(c: CanvasItem, origin: Vector2, length: float, half_h: float, edge: Color, core: Color) -> void:
	var tl := origin + Vector2(0, -half_h)
	var tr := origin + Vector2(length, -half_h)
	var ml := origin
	var mr := origin + Vector2(length, 0)
	var bl := origin + Vector2(0, half_h)
	var br := origin + Vector2(length, half_h)
	c.draw_polygon(PackedVector2Array([tl, tr, mr, ml]), PackedColorArray([edge, edge, core, core]))
	c.draw_polygon(PackedVector2Array([ml, mr, br, bl]), PackedColorArray([core, core, edge, edge]))


## Outlined text. center = centered on pos.x, otherwise left-aligned.
static func label(c: CanvasItem, pos: Vector2, s: String, size: int = 14, col: Color = Color.WHITE, center: bool = true) -> void:
	var font := ThemeDB.fallback_font
	var w := -1.0
	if center:                                   # Wide enough for long lines (never clipped)
		w = maxf(320.0, font.get_string_size(s, HORIZONTAL_ALIGNMENT_LEFT, -1, size).x + 12.0)
	var al := HORIZONTAL_ALIGNMENT_CENTER if center else HORIZONTAL_ALIGNMENT_LEFT
	var p := pos - Vector2(w * 0.5, 0.0) if center else pos
	c.draw_string_outline(font, p, s, al, w, size, 5, Color(0, 0, 0, col.a))
	c.draw_string(font, p, s, al, w, size, col)
