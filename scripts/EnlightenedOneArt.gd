class_name EnlightenedOneArt
extends RefCounted
## The Enlightened One (original design): a walking pilgrim in GOLDEN ARMOR over
## deep indigo cloth, an ivory face-mask with glowing gold eye slits and a gold
## circlet, a slowly turning halo of light behind the head, and heavy METAL
## BRONZE GAUNTLETS. Flat cartoon, thick black outlines. Facing RIGHT, origin = feet.
##
## GORILLA FORM: hunched stance, knuckles near the ground, glowing armor
## (the 1.25x size comes from the Visuals scale, not from here).
## Also draws the white cocooned blade Helpers.
## No draw_set_transform here (the Character Select card scales us with it).

const CLOTH := Color(0.20, 0.17, 0.30)
const CLOTH_SHADE := Color(0.10, 0.08, 0.16)
const CLOTH_HI := Color(0.38, 0.33, 0.52)
const GOLD := Color(0.97, 0.77, 0.24)
const GOLD_SHADE := Color(0.68, 0.48, 0.12)
const GOLD_HI := Color(1.0, 0.95, 0.68)
const BRONZE := Color(0.74, 0.46, 0.20)
const BRONZE_SHADE := Color(0.46, 0.26, 0.10)
const BRONZE_HI := Color(0.96, 0.72, 0.42)
const IVORY := Color(0.96, 0.93, 0.84)
const IVORY_SHADE := Color(0.76, 0.72, 0.62)
const LIGHT := Color(1.0, 0.86, 0.35)
const BLACK := Color(0, 0, 0)


static func draw(c: CanvasItem, e: EnlightenedOne) -> void:
	_draw_figure(c, {
		"t": e.anim_time, "ph": e.walk_phase, "floor": e.is_on_floor(),
		"punch": e.punch_ext, "block": e.block_amt, "perfect": e.perfect_flash,
		"cast": e.cast_pose, "gorilla": e.is_gorilla(), "heal": e.heal_t,
		"heal_r": e.ed.heal_radius, "charge": e.light_charge, "fire": e.light_fire,
		"range": e.ed.light_range,
	})


static func draw_portrait(c: CanvasItem, t: float) -> void:
	_draw_figure(c, {"t": t})


static func _draw_figure(c: CanvasItem, s: Dictionary) -> void:
	var t: float = s.get("t", 0.0)
	var ph: float = s.get("ph", 0.0)
	var on_floor: bool = s.get("floor", true)
	var b: float = s.get("block", 0.0)
	var punch: float = s.get("punch", 0.0)
	var e := clampf(punch, 0.0, 1.0)
	var cast: float = s.get("cast", 0.0)
	var gor: bool = s.get("gorilla", false)
	var u := Vector2(7, 18) if gor else Vector2.ZERO        # Gorilla hunch: upper body forward + down

	if gor:   # Glowing armor aura
		var p := 0.5 + 0.5 * sin(t * 6.0)
		c.draw_circle(Vector2(6, -56), 62.0 + 6.0 * p, Color(LIGHT.r, LIGHT.g, LIGHT.b, 0.16))

	# --- Halo of light behind the head ---
	_halo(c, Vector2(1, -116) + u, t)

	# --- Legs: cloth + gold greaves ---
	var sw := sin(ph) * 13.0
	var lift_f := maxf(0.0, cos(ph)) * 7.0
	var lift_b := maxf(0.0, -cos(ph)) * 7.0
	if not on_floor:
		sw = 7.0
		lift_f = 12.0
		lift_b = 4.0
	var wide := 6.0 if gor else 0.0                       # Wider stance
	_leg(c, Vector2(-6, -52), Vector2(-8.0 - sw - wide, -5.0 - lift_b), true)
	_leg(c, Vector2(6, -52), Vector2(8.0 + sw + wide, -5.0 - lift_f), false)

	# --- Arm targets ---
	var swing := sin(ph) * 8.0 * (1.0 - maxf(e, b))
	var rest_el := Vector2(10.0 - swing * 0.5, -74) + u
	var rest_hand := Vector2(13.0 - swing, -55) + u
	var b_el := Vector2(-10.0 + swing * 0.5, -74) + u
	var b_hand := Vector2(-9.0 + swing, -55) + u
	if gor:   # Knuckle-walk: fists close to the ground
		rest_el = Vector2(26.0 - swing * 0.5, -46)
		rest_hand = Vector2(32.0 - swing, -14)
		b_el = Vector2(4.0 + swing * 0.5, -46)
		b_hand = Vector2(6.0 + swing, -14)
	var reach := 1.3 if gor else 1.0
	var el := rest_el.lerp(Vector2(30, -91) + u, e)
	var hand := rest_hand.lerp(Vector2(56.0 * reach, -91) + u, e)
	if punch < 0.0:
		var w := -punch * 2.0
		el = rest_el + Vector2(-8, -6) * w
		hand = rest_hand + Vector2(-10, -18) * w
	if cast > 0.0:
		el = el.lerp(Vector2(26, -86), cast)
		hand = hand.lerp(Vector2(46, -86), cast)
	el = el.lerp(Vector2(18, -72) + u, b)
	hand = hand.lerp(Vector2(24, -92) + u, b)
	b_el = b_el.lerp(Vector2(14, -70) + u, b)
	b_hand = b_hand.lerp(Vector2(22, -86) + u, b)
	_arm(c, Vector2(-4, -92) + u, b_el, b_hand, true, gor)

	# --- Torso: cloth, gold breastplate, tabard ---
	FighterArt.rrect(c, Rect2(Vector2(-17, -100) + u, Vector2(34, 50)), CLOTH, CLOTH_SHADE, CLOTH_HI, 8.0, 4.0)
	FighterArt.rrect(c, Rect2(Vector2(-16, -99) + u, Vector2(32, 30)), GOLD, GOLD_SHADE, GOLD_HI, 8.0, 3.5)
	# Sun emblem on the chest
	var ec := Vector2(1, -85) + u
	for i in 8:
		var a := TAU * float(i) / 8.0
		c.draw_line(ec + Vector2.from_angle(a) * 4.0, ec + Vector2.from_angle(a) * 8.0, GOLD_SHADE, 2.0)
	c.draw_circle(ec, 4.0, BLACK)
	c.draw_circle(ec, 2.8, GOLD_HI)
	# Belt + tabard
	FighterArt.rrect(c, Rect2(Vector2(-17, -58) + u, Vector2(34, 8)), GOLD_SHADE, CLOTH_SHADE, GOLD, 3.0, 3.0)
	var tab := PackedVector2Array([Vector2(-6, -51) + u, Vector2(8, -51) + u, Vector2(6, -32) + u, Vector2(1, -28) + u, Vector2(-4, -32) + u])
	c.draw_colored_polygon(tab, CLOTH_HI)
	c.draw_polyline(tab, BLACK, 2.0, true)
	c.draw_line(Vector2(1, -50) + u, Vector2(1, -31) + u, GOLD, 2.0)
	# Pauldron
	FighterArt.ball(c, Vector2(2, -95) + u, 9.0, GOLD, GOLD_SHADE, GOLD_HI)

	# --- Head: ivory mask + gold circlet ---
	_head(c, Vector2(3, -113) + u, t, gor)

	# --- Light beam (Godly O' Light) ---
	var fire: float = s.get("fire", 0.0)
	var charge: float = s.get("charge", 0.0)
	if charge > 0.0:
		var cc := Vector2(30, -84) + u
		c.draw_circle(cc, 10.0 + 26.0 * charge, Color(LIGHT.r, LIGHT.g, LIGHT.b, 0.35 * charge))
		c.draw_circle(cc, 5.0 + 8.0 * charge, Color(1, 1, 1, charge))
	if fire > 0.0:
		_light_beam(c, Vector2(30, -84) + u, s.get("range", 1100.0), fire, t)

	_arm(c, Vector2(4, -92) + u, el, hand, false, gor)

	# --- Lord's Heal ring + floating pluses ---
	var heal: float = s.get("heal", 0.0)
	if heal > 0.0:
		var k := 1.0 - heal / 0.8
		var r: float = float(s.get("heal_r", 240.0)) * (1.0 - pow(1.0 - k, 2.0))
		c.draw_arc(Vector2(0, -64), r, 0.0, TAU, 48, Color(0, 0, 0, 1.0 - k), 8.0, true)
		c.draw_arc(Vector2(0, -64), r, 0.0, TAU, 48, Color(LIGHT.r, LIGHT.g, LIGHT.b, 1.0 - k), 5.0, true)
		c.draw_circle(Vector2(0, -64), 60.0, Color(LIGHT.r, LIGHT.g, LIGHT.b, 0.25 * (1.0 - k)))
		for i in 6:
			var px := sin(float(i) * 2.4) * 36.0
			var py := -40.0 - 90.0 * k - float(i) * 10.0
			var pc := Vector2(px, py)
			var col := Color(1.0, 0.95, 0.5, 1.0 - k)
			c.draw_line(pc + Vector2(-5, 0), pc + Vector2(5, 0), col, 3.0)
			c.draw_line(pc + Vector2(0, -5), pc + Vector2(0, 5), col, 3.0)

	# --- Block (gold arc) ---
	if b > 0.05:
		var bc := Color(1.0, 0.85, 0.35, 0.85 * b)
		if s.get("perfect", 0.0) > 0.0:
			bc = Color(1, 1, 1, 1)
		c.draw_arc(Vector2(10, -70) + u, 50.0, -1.0, 1.0, 20, Color(0, 0, 0, b), 11.0, true)
		c.draw_arc(Vector2(10, -70) + u, 50.0, -1.0, 1.0, 20, bc, 6.0, true)


# ============================================================
# PARTS
# ============================================================
static func _halo(c: CanvasItem, center: Vector2, t: float) -> void:
	c.draw_circle(center, 26.0, Color(LIGHT.r, LIGHT.g, LIGHT.b, 0.18))
	for i in 12:
		var a := TAU * float(i) / 12.0 + t * 0.4
		var r0 := 19.0
		var r1 := 27.0 if i % 2 == 0 else 23.0
		c.draw_line(center + Vector2.from_angle(a) * r0, center + Vector2.from_angle(a) * r1, Color(0, 0, 0), 5.0)
		c.draw_line(center + Vector2.from_angle(a) * r0, center + Vector2.from_angle(a) * r1, LIGHT, 3.0)
	c.draw_arc(center, 19.0, 0.0, TAU, 32, Color(0, 0, 0), 5.0, true)
	c.draw_arc(center, 19.0, 0.0, TAU, 32, LIGHT, 2.5, true)


static func _head(c: CanvasItem, hc: Vector2, t: float, gor: bool) -> void:
	# Hood (indigo cloth) behind the mask
	c.draw_circle(hc + Vector2(-2, 0), 17.5, BLACK)
	c.draw_circle(hc + Vector2(-2, 0), 15.0, CLOTH)
	# Ivory face-mask: tall rounded plate
	var mask := FighterArt.rrect_points(Rect2(hc + Vector2(-5, -13), Vector2(20, 26)), 9.0)
	c.draw_colored_polygon(mask, IVORY)
	c.draw_colored_polygon(FighterArt.rrect_points(Rect2(hc + Vector2(9, -10), Vector2(6, 22)), 3.0), IVORY_SHADE)
	var mc := mask.duplicate()
	mc.append(mask[0])
	c.draw_polyline(mc, BLACK, 3.0, true)
	# Glowing gold eye slits
	var glow := 0.7 + 0.3 * sin(t * 4.0)
	if gor:
		glow = 1.0
	for ex in [3.0, 10.0]:
		var r := Rect2(hc + Vector2(ex, -5), Vector2(3, 9))
		c.draw_rect(r.grow(1.2), BLACK)
		c.draw_rect(r, Color(LIGHT.r, LIGHT.g, LIGHT.b, glow))
	# Gold circlet with a gem
	c.draw_line(hc + Vector2(-6, -11), hc + Vector2(15, -11), BLACK, 5.0)
	c.draw_line(hc + Vector2(-5, -11), hc + Vector2(14, -11), GOLD, 3.0)
	c.draw_circle(hc + Vector2(5, -12), 3.2, BLACK)
	c.draw_circle(hc + Vector2(5, -12), 2.2, Color(0.4, 0.9, 1.0))


static func _leg(c: CanvasItem, hip: Vector2, foot: Vector2, far: bool) -> void:
	var base := CLOTH_SHADE if far else CLOTH
	var knee := (hip + foot) * 0.5 + Vector2(7, 0)
	FighterArt.limb(c, hip, knee, 12.0, base, CLOTH_SHADE, CLOTH_HI)
	FighterArt.limb(c, knee, foot + Vector2(0, -4), 12.0, GOLD_SHADE if far else GOLD, GOLD_SHADE, GOLD_HI)  # Greave
	FighterArt.ball(c, knee, 5.5, GOLD, GOLD_SHADE, GOLD_HI)
	FighterArt.rrect(c, Rect2(foot.x - 8.0, foot.y - 4.0, 24, 9), GOLD_SHADE if far else GOLD, GOLD_SHADE, GOLD_HI, 3.0, 3.5)


## Indigo sleeve + big METAL BRONZE GAUNTLET.
static func _arm(c: CanvasItem, shoulder: Vector2, elbow: Vector2, hand: Vector2, far: bool, gor: bool) -> void:
	var base := CLOTH_SHADE if far else CLOTH
	FighterArt.limb(c, shoulder, elbow, 9.0, base, CLOTH_SHADE, CLOTH_HI)
	var br := BRONZE_SHADE if far else BRONZE
	FighterArt.limb(c, elbow, hand, 11.0, br, BRONZE_SHADE, BRONZE_HI)   # Bronze forearm guard
	var size := 18.0 if gor else 15.0
	FighterArt.rrect(c, Rect2(hand - Vector2(size, size) * 0.5, Vector2(size, size)), br, BRONZE_SHADE, BRONZE_HI, 4.0, 3.5)
	c.draw_line(hand + Vector2(-size * 0.3, -size * 0.15), hand + Vector2(size * 0.3, -size * 0.15), BRONZE_SHADE, 2.0)   # Knuckle plate
	c.draw_circle(hand + Vector2(size * 0.25, size * 0.2), 1.6, BRONZE_HI)                                                 # Rivet
	if gor:
		c.draw_circle(hand, size * 0.9, Color(LIGHT.r, LIGHT.g, LIGHT.b, 0.18))


static func _light_beam(c: CanvasItem, o: Vector2, length: float, k: float, t: float) -> void:
	var hh := 48.0 * (0.6 + 0.4 * k)
	var top := PackedVector2Array()
	var bot := PackedVector2Array()
	var x := 0.0
	var i := 0
	while x <= length:
		var j := sin(float(i) * 1.3 + t * 30.0) * 4.0
		top.append(o + Vector2(x, -hh + j))
		bot.append(o + Vector2(x, hh - j))
		x += 40.0
		i += 1
	top.append(o + Vector2(length + 40.0, 0))
	bot.reverse()
	top.append_array(bot)
	c.draw_colored_polygon(top, Color(GOLD.r, GOLD.g, GOLD.b, 0.95))
	var closed := top.duplicate()
	closed.append(top[0])
	c.draw_polyline(closed, BLACK, 4.0, true)
	FighterArt.beam_gradient(c, o, length, hh * 0.85, GOLD, Color(1, 1, 0.95))   # Gold -> white gradient
	for sidx in 12:
		var px := fmod(float(sidx) * 89.0 + t * 1100.0, length)
		c.draw_circle(o + Vector2(px, sin(float(sidx) * 2.7) * hh * 0.8), 3.0, Color.WHITE)
	c.draw_circle(o, hh + 8.0, Color(LIGHT.r, LIGHT.g, LIGHT.b, 0.6))
	c.draw_circle(o, hh * 0.6, Color.WHITE)


# ============================================================
# HELPER: small white cocoon with a blade
# ============================================================
static func draw_helper(c: CanvasItem, t: float, slash_t: float) -> void:
	var step := sin(t * 16.0) * 3.0
	# Little feet
	c.draw_circle(Vector2(-6, -3 - maxf(step, 0.0)), 4.0, BLACK)
	c.draw_circle(Vector2(6, -3 - maxf(-step, 0.0)), 4.0, BLACK)
	# Cocoon body
	var center := Vector2(0, -24)
	var pts := PackedVector2Array()
	for i in 24:
		var a := TAU * float(i) / 24.0
		var r := Vector2(13.0, 20.0)
		var squash := 1.0 + 0.08 * sin(t * 10.0)
		pts.append(center + Vector2(cos(a) * r.x * squash, sin(a) * r.y / squash))
	c.draw_colored_polygon(pts, IVORY)
	# Wrap bands
	for k in 3:
		var y := -34.0 + float(k) * 9.0
		c.draw_line(Vector2(-11, y + 3), Vector2(11, y - 2), IVORY_SHADE, 2.5)
	var closed := pts.duplicate()
	closed.append(pts[0])
	c.draw_polyline(closed, BLACK, 3.0, true)
	# Face holes
	c.draw_circle(Vector2(3, -30), 2.6, BLACK)
	c.draw_circle(Vector2(9, -30), 2.6, BLACK)
	c.draw_circle(Vector2(3.5, -30.5), 0.8, LIGHT)
	c.draw_circle(Vector2(9.5, -30.5), 0.8, LIGHT)
	# Blade (spins during a slash)
	var ang := -0.9
	if slash_t > 0.0:
		ang += (1.0 - slash_t / 0.25) * TAU
		c.draw_arc(center, 34.0, ang - 1.4, ang, 12, Color(1, 1, 1, 0.7), 5.0, true)
	var hand := Vector2(12, -22)
	var tip := hand + Vector2.from_angle(ang) * 26.0
	c.draw_line(hand, tip, BLACK, 6.0, true)
	c.draw_line(hand, tip, Color(0.86, 0.88, 0.92), 3.0, true)
	c.draw_circle(hand, 3.5, BLACK)
	c.draw_circle(hand, 2.2, GOLD)
