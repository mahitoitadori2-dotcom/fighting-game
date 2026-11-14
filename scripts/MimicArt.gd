class_name MimicArt
extends RefCounted
## THE MIMIC: a big SKELETON OF PURE STEEL - a metal skull with RED pupils in dark sockets, a
## jointed spine, a ribcage and pelvis, thin steel bones for limbs. Flat cartoon, thick black
## outlines. Drawn facing RIGHT, origin = feet, about 84 x 168 (bigger than the others).
##   Shredding Fist: the front forearm bone becomes a serrated blade (sparks while grinding)
##   Stab Kick:      the front shin bone becomes a long spike
##   Wings of Lies:  steel blade-wings fan out of the spine and spin
##   Eating Fear:    the ribcage splits open into a toothed maw
##   Stolen Skin:    the skull's jaw drops open for the bite

const PORTRAIT_H := 172.0                   # Character Select: fits the card

const STEEL := Color(0.70, 0.74, 0.80)
const STEEL_SHADE := Color(0.36, 0.39, 0.46)
const STEEL_HI := Color(0.95, 0.97, 1.0)
const DARK := Color(0.10, 0.10, 0.12)
const EYE_RED := Color(1.0, 0.07, 0.05)
const MAW := Color(0.30, 0.02, 0.03)
const TOOTH := Color(0.92, 0.93, 0.95)
const BLACK := Color(0, 0, 0)
const BONE_W := 8.0                          # Thin steel bones


static func draw(c: CanvasItem, f: Mimic) -> void:
	_figure(c, {
		"t": f.anim_time, "ph": f.walk_phase, "floor": f.is_on_floor(),
		"punch": f.punch_ext, "block": f.block_amt, "shred": f.shred_ext, "kick": f.kick_ext,
		"wings": f.wings_k, "wrot": f.wings_rot, "stomach": f.stomach_k, "jaw": f.jaw_k, "grind": f.grind_t,
	})


## Idle pose for menus / Character Select.
static func draw_portrait(c: CanvasItem, t: float) -> void:
	_figure(c, {"t": t})


static func _figure(c: CanvasItem, s: Dictionary) -> void:
	var t: float = s.get("t", 0.0)
	var ph: float = s.get("ph", 0.0)
	var on_floor: bool = s.get("floor", true)
	var punch: float = s.get("punch", 0.0)
	var e := clampf(punch, 0.0, 1.0)
	var block: float = s.get("block", 0.0)
	var shred: float = s.get("shred", 0.0)
	var kick: float = s.get("kick", 0.0)
	var wings: float = s.get("wings", 0.0)
	var stomach: float = s.get("stomach", 0.0)
	var jaw: float = s.get("jaw", 0.0)
	var br := sin(t * 1.6) * 1.2                     # Breathing (even a skeleton sways)

	# --- Wings of Lies: out of the spine, behind everything ---
	if wings > 0.01:
		_wings(c, wings, s.get("wrot", 0.0))

	# --- Legs (thigh + shin bones, knee joints, bony feet) ---
	var sw := sin(ph) * 12.0
	var lift_f := maxf(0.0, cos(ph)) * 7.0
	var lift_b := maxf(0.0, -cos(ph)) * 7.0
	if not on_floor:
		sw = 6.0
		lift_f = 12.0
		lift_b = 5.0
	_leg(c, Vector2(-8, -72), Vector2(-10.0 - sw, -6.0 - lift_b), 0.0)
	var front_foot := Vector2(10.0 + sw, -6.0 - lift_f)
	if kick > 0.0:
		front_foot = front_foot.lerp(Vector2(48, -60), kick)          # Kicks out at hip height
	elif kick < 0.0:
		front_foot = front_foot.lerp(Vector2(-6, -42), -kick)        # Chambered
	_leg(c, Vector2(8, -72), front_foot, maxf(kick, 0.0))

	# --- Back arm ---
	var swing := sin(ph) * 7.0 * (1.0 - maxf(e, block))
	_arm(c, Vector2(-16, -128 + br), Vector2(-21.0 + swing * 0.5, -102), Vector2(-19.0 + swing, -80), 0.0, false, 0.0)

	# --- Pelvis ---
	var pelvis := PackedVector2Array([Vector2(-16, -80), Vector2(16, -80), Vector2(12, -66), Vector2(4, -62), Vector2(-4, -62), Vector2(-12, -66)])
	c.draw_colored_polygon(pelvis, STEEL_SHADE)
	FighterArt.outline(c, pelvis, 3.5)
	c.draw_circle(Vector2(-7, -72), 3.0, DARK)
	c.draw_circle(Vector2(7, -72), 3.0, DARK)

	# --- Spine: a stack of steel vertebrae from pelvis to skull ---
	for i in 9:
		var y := -84.0 - float(i) * 7.6 + br * float(i) / 8.0
		var v := Rect2(-5.0, y - 3.0, 10.0, 6.0)
		c.draw_rect(v.grow(1.5), BLACK)
		c.draw_rect(v, STEEL if i % 2 == 0 else STEEL_SHADE)

	# --- Ribcage (splits open for Eating Fear) ---
	_ribcage(c, Vector2(0, -122 + br), stomach, t)

	# --- Collar bones / shoulders ---
	var sh_f := Vector2(16, -128 + br)
	c.draw_line(Vector2(-16, -128 + br), sh_f, BLACK, 7.0, FighterArt.AA)
	c.draw_line(Vector2(-16, -128 + br), sh_f, STEEL, 4.0, FighterArt.AA)

	# --- Skull ---
	_skull(c, Vector2(3, -152 + br), jaw, t)

	# --- Front arm (punch / shredding blade / block) ---
	var el := Vector2(19.0 - swing * 0.5, -102).lerp(Vector2(40, -118), e)
	var hand := Vector2(21.0 - swing, -80).lerp(Vector2(66, -116), e)
	if punch < 0.0:
		hand = hand.lerp(Vector2(4, -108), -punch)
		el = el.lerp(Vector2(6, -100), -punch)
	if block > 0.0:
		el = el.lerp(Vector2(28, -122), block)
		hand = hand.lerp(Vector2(26, -146), block)
	if shred > 0.0:
		el = el.lerp(Vector2(38, -114), shred)
		hand = hand.lerp(Vector2(60, -112), shred)
	elif shred < 0.0:
		el = el.lerp(Vector2(-2, -104), -shred)
		hand = hand.lerp(Vector2(-6, -118), -shred)
	_arm(c, sh_f, el, hand, maxf(shred, 0.0), true, s.get("grind", 0.0))


## One steel bone: dark outline, steel body, a thin highlight, knobbed ends.
static func _bone(c: CanvasItem, a: Vector2, b: Vector2, w: float = BONE_W) -> void:
	c.draw_line(a, b, BLACK, w + 5.0, FighterArt.AA)
	c.draw_line(a, b, STEEL_SHADE, w, FighterArt.AA)
	var n := (b - a).normalized().orthogonal() * (w * 0.2)
	c.draw_line(a + n, b + n, STEEL, w * 0.55, FighterArt.AA)
	for p: Vector2 in [a, b]:
		c.draw_circle(p, w * 0.75 + 2.5, BLACK)
		c.draw_circle(p, w * 0.75, STEEL)


static func _leg(c: CanvasItem, hip: Vector2, foot: Vector2, spike: float) -> void:
	var knee := hip.lerp(foot, 0.5) + Vector2(4, -2)
	_bone(c, hip, knee, BONE_W + 1.0)
	_bone(c, knee, foot)
	if spike > 0.05:
		# Stab Kick: the shin bone ends in a long steel spike
		var dir := (foot - knee).normalized()
		FighterArt.curved_spike(c, foot - dir * 4.0, foot + dir * (20.0 + 46.0 * spike), 7.0, STEEL, STEEL_HI, 0.05, 3.0)
	else:
		# Bony foot: a few toe bones
		for k in 3:
			_bone(c, foot, foot + Vector2(10.0 + float(k) * 3.0, 2.0 + float(k) * 1.5), 4.0)


static func _arm(c: CanvasItem, sh: Vector2, el: Vector2, hand: Vector2, blade: float, front: bool, grind: float) -> void:
	_bone(c, sh, el)
	if front and blade > 0.05:
		# Shredding Fist: the forearm bone IS the serrated blade
		var dir := (hand - el).normalized()
		var n := Vector2(-dir.y, dir.x)
		var tip := hand + dir * (26.0 + 38.0 * blade)
		var pts := PackedVector2Array([el + n * 5.0])
		for i in 6:                                    # Serrated top edge
			var k := float(i + 1) / 7.0
			var p := el.lerp(tip, k)
			pts.append(p + n * (5.0 * (1.0 - k) + 5.0))
			pts.append(p + n * (5.0 * (1.0 - k)))
		pts.append(tip)
		pts.append(el - n * 5.0)
		c.draw_colored_polygon(pts, STEEL_HI)
		FighterArt.outline(c, pts, 3.0)
		c.draw_line(el, tip, STEEL_SHADE, 2.0)
		if grind > 0.0:
			for i in 4:                                # Grinding sparks
				var p0 := tip.lerp(el, 0.3)
				c.draw_line(p0, p0 + Vector2.from_angle(randf() * TAU) * randf_range(8.0, 18.0), Color(1.0, 0.75, 0.3), 2.0)
		return
	_bone(c, el, hand)
	# Skeletal hand: palm knob + finger bones
	c.draw_circle(hand, 5.5, BLACK)
	c.draw_circle(hand, 3.5, STEEL)
	var d := (hand - el).normalized()
	for k in 3:
		var fd := d.rotated((float(k) - 1.0) * 0.45)
		c.draw_line(hand, hand + fd * 9.0, BLACK, 4.5)
		c.draw_line(hand, hand + fd * 9.0, STEEL, 2.0)


## Ribcage: curved rib pairs off the spine; Eating Fear spreads them open around a toothed maw.
static func _ribcage(c: CanvasItem, center: Vector2, open: float, t: float) -> void:
	if open > 0.01:
		var w := 18.0 * open
		var pts := PackedVector2Array()
		for i in 16:
			var a := TAU * float(i) / 16.0
			pts.append(center + Vector2(8, 14) + Vector2(cos(a) * w, sin(a) * 24.0))
		c.draw_colored_polygon(pts, MAW)
		FighterArt.outline(c, pts, 3.0)
		c.draw_circle(center + Vector2(8, 18), w * 0.45, Color(0.6, 0.05, 0.05, 0.8 + 0.2 * sin(t * 9.0)))
	for i in 5:
		var y := center.y - 2.0 + float(i) * 8.0
		var reach := 22.0 - float(i) * 1.6
		var spread := 1.0 + open * 0.9
		for side: float in [-1.0, 1.0]:
			var rib := PackedVector2Array()
			for k in 6:
				var u := float(k) / 5.0
				var x := side * reach * sin(u * PI * 0.5) * (spread if side > 0.0 else 1.0)
				rib.append(Vector2(center.x + x, y + sin(u * PI) * 7.0 - u * 2.0))
			c.draw_polyline(rib, BLACK, 6.0, FighterArt.AA)
			c.draw_polyline(rib, STEEL, 3.0, FighterArt.AA)
			if open > 0.3 and side > 0.0:              # Teeth on the opened ribs
				var tipp := rib[rib.size() - 1]
				c.draw_colored_polygon(PackedVector2Array([tipp, tipp + Vector2(-6, -3), tipp + Vector2(-6, 3)]), TOOTH)
	# Sternum
	c.draw_line(center + Vector2(0, -4), center + Vector2(0, 30), BLACK, 6.0)
	c.draw_line(center + Vector2(0, -4), center + Vector2(0, 30), STEEL, 3.0)


## A steel SKULL: dome, deep sockets with RED pupils, a nose hole, a jaw that drops for the bite.
static func _skull(c: CanvasItem, hc: Vector2, jaw: float, t: float) -> void:
	# Neck vertebra
	c.draw_rect(Rect2(hc.x - 5, hc.y + 12, 10, 8), BLACK)
	c.draw_rect(Rect2(hc.x - 3.5, hc.y + 13, 7, 6), STEEL_SHADE)
	# Jaw (drops open)
	var drop := 13.0 * jaw
	var jaw_pts := PackedVector2Array([Vector2(hc.x - 9, hc.y + 6 + drop), Vector2(hc.x + 14, hc.y + 6 + drop),
		Vector2(hc.x + 12, hc.y + 15 + drop), Vector2(hc.x - 6, hc.y + 15 + drop)])
	c.draw_colored_polygon(jaw_pts, STEEL_SHADE)
	FighterArt.outline(c, jaw_pts, 3.0)
	if jaw > 0.05:
		c.draw_rect(Rect2(hc.x - 8, hc.y + 7, 21, drop), MAW)
	for i in 5:                                        # Teeth: upper row on the skull, lower on the jaw
		var x := hc.x - 7 + float(i) * 4.6
		c.draw_rect(Rect2(x, hc.y + 5, 3.4, 4.5), TOOTH)
		c.draw_rect(Rect2(x, hc.y + 2.5 + drop, 3.4, 4.5), TOOTH)
	# Cranium
	var dome := PackedVector2Array()
	for i in 18:
		var a := PI + PI * float(i) / 17.0                    # Top half
		dome.append(hc + Vector2(cos(a) * 18.0, sin(a) * 18.0 - 2.0))
	dome.append(hc + Vector2(16, 6))
	dome.append(hc + Vector2(-14, 6))
	c.draw_colored_polygon(dome, STEEL)
	FighterArt.outline(c, dome, 4.0)
	c.draw_arc(hc + Vector2(-6, -10), 7.0, PI * 1.1, PI * 1.6, 6, STEEL_HI, 2.5)          # Shine
	# Eye sockets with RED pupils
	var glow := 0.75 + 0.25 * sin(t * 6.0)
	for ex: float in [hc.x + 1.0, hc.x + 11.0]:
		c.draw_circle(Vector2(ex, hc.y - 2.0), 5.0, DARK)
		c.draw_circle(Vector2(ex, hc.y - 2.0), 4.0, Color(EYE_RED.r, EYE_RED.g, EYE_RED.b, 0.22 * glow))
		c.draw_circle(Vector2(ex + 0.8, hc.y - 2.0), 1.7, Color(EYE_RED.r, EYE_RED.g * glow, EYE_RED.b, 1.0))
	# Nose hole
	c.draw_colored_polygon(PackedVector2Array([Vector2(hc.x + 6, hc.y + 1), Vector2(hc.x + 9, hc.y + 1), Vector2(hc.x + 7.5, hc.y + 4.5)]), DARK)


## Wings of Lies: two fans of steel blades out of the spine, spinning around him.
static func _wings(c: CanvasItem, k: float, rot: float) -> void:
	var center := Vector2(-2, -110)
	for side: float in [0.0, PI]:
		var base_a: float = rot + side - PI * 0.5 + (0.0 if rot != 0.0 else -0.35)
		for i in 4:
			var a: float = base_a + (float(i) - 1.5) * 0.22
			var length := (62.0 + float(i % 2) * 18.0) * k
			var from := center + Vector2.from_angle(a) * 10.0
			var tip := center + Vector2.from_angle(a) * (10.0 + length)
			_bone(c, center, from + (tip - from) * 0.25, 4.0)              # A bone strut per blade
			FighterArt.curved_spike(c, from + (tip - from) * 0.2, tip, 7.0 * k + 2.0, STEEL_SHADE, STEEL_HI, 0.18, 3.0)
	if rot != 0.0:
		c.draw_arc(center, 96.0, rot, rot + 2.4, 18, Color(0.85, 0.9, 1.0, 0.35), 4.0)
		c.draw_arc(center, 96.0, rot + PI, rot + PI + 2.4, 18, Color(0.85, 0.9, 1.0, 0.35), 4.0)
