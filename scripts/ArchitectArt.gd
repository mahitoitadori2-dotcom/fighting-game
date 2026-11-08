class_name ArchitectArt
extends RefCounted
## The Mighty Architect: cyborg with PURE WHITE helmet + chest plate, GREEN hands
## and legs, dark gray / black armor details and a glowing BLUE chest core.
## Drawn facing RIGHT, origin = feet, about 64 x 128.
##
## draw(c, player)        -> in-game, animated from the Player's state
## draw_portrait(c, t)    -> idle pose for menus / Character Select cards

# --- PURE WHITE: helmet + chest plate ---
const WHITE := Color(1.0, 1.0, 1.0, 1.0)
const WHITE_SHADE := Color(0.80, 0.84, 0.90, 1.0)     # Thin cartoon shade strip only
# --- GREEN: hands + legs ---
const GREEN := Color(0.22, 0.86, 0.28, 1.0)
const GREEN_SHADE := Color(0.08, 0.52, 0.15, 1.0)
const GREEN_HI := Color(0.72, 1.0, 0.62, 1.0)
const GREEN_FAR := Color(0.13, 0.62, 0.19, 1.0)        # Far-side limbs (slightly darker)
const GREEN_FAR_SHADE := Color(0.05, 0.36, 0.10, 1.0)
# --- Dark gray / black armor details ---
const DARK := Color(0.25, 0.27, 0.31, 1.0)
const DARK_SHADE := Color(0.12, 0.13, 0.16, 1.0)
const DARK_HI := Color(0.46, 0.49, 0.55, 1.0)
const VISOR := Color(0.07, 0.08, 0.11, 1.0)
# --- Glowing BLUE core ---
const CORE := Color(0.18, 0.68, 1.0, 1.0)
const CORE_HI := Color(0.78, 0.95, 1.0, 1.0)
# --- Drill metal ---
const DRILL := Color(0.56, 0.60, 0.67, 1.0)
const DRILL_SHADE := Color(0.34, 0.37, 0.43, 1.0)


static func draw(c: CanvasItem, p: Player) -> void:
	_draw_figure(c, p.anim_time, p.walk_phase, p.is_on_floor(), p.punch_ext, p.block_amt,
		p.drill_len, p.perfect_flash, p.arsenal_timer > 0.0, p.onslaught.flash_timer > 0.0)


## Idle pose with no Player needed (Character Select / Main Menu).
static func draw_portrait(c: CanvasItem, t: float) -> void:
	_draw_figure(c, t, 0.0, true, 0.0, 0.0, 0.0, 0.0, false, false)


static func _draw_figure(c: CanvasItem, t: float, ph: float, on_floor: bool, punch_ext: float,
		b: float, drill_len: float, perfect_flash: float, arsenal: bool, onslaught_flash: bool) -> void:
	if arsenal:
		_tentacles(c, t)
	if onslaught_flash:                                   # Orange pulse ring while Onslaught is available
		var pulse := 0.5 + 0.5 * sin(t * 40.0)
		c.draw_arc(Vector2(4, -78), 46.0 + 4.0 * pulse, 0.0, TAU, 40, Color(1.0, 0.55, 0.1, 0.5 + 0.5 * pulse), 6.0, true)

	# --- Legs (GREEN) - walk cycle / air tuck ---
	var s := sin(ph) * 13.0
	var lift_f := maxf(0.0, cos(ph)) * 7.0
	var lift_b := maxf(0.0, -cos(ph)) * 7.0
	if not on_floor:
		s = 7.0
		lift_f = 12.0
		lift_b = 4.0
	_leg(c, Vector2(-6, -52), Vector2(-8.0 - s, -5.0 - lift_b), true)
	_leg(c, Vector2(6, -52), Vector2(8.0 + s, -5.0 - lift_f), false)

	# --- Arm poses ---
	var e := clampf(punch_ext, 0.0, 1.0)
	var swing := sin(ph) * 8.0 * (1.0 - maxf(e, b))
	var rest_el := Vector2(10.0 - swing * 0.5, -74)
	var rest_hand := Vector2(13.0 - swing, -55)
	var el := rest_el.lerp(Vector2(30, -91), e)
	var hand := rest_hand.lerp(Vector2(56, -91), e)
	if punch_ext < 0.0:                                   # Wind-up: pull the fist back
		var w := -punch_ext * 2.0
		el = rest_el + Vector2(-8, -6) * w
		hand = rest_hand + Vector2(-10, -18) * w
	el = el.lerp(Vector2(18, -72), b)
	hand = hand.lerp(Vector2(24, -92), b)
	var b_el := Vector2(-10.0 + swing * 0.5, -74).lerp(Vector2(14, -70), b)
	var b_hand := Vector2(-9.0 + swing, -55).lerp(Vector2(22, -86), b)
	_arm(c, Vector2(-4, -92), b_el, b_hand, true)         # Far arm (darker)

	# --- Torso: dark undersuit + PURE WHITE chest plate ---
	FighterArt.rrect(c, Rect2(-17, -100, 34, 48), DARK, DARK_SHADE, DARK_HI, 8.0, 4.0)
	FighterArt.rrect(c, Rect2(-18, -101, 36, 39), WHITE, WHITE_SHADE, WHITE, 9.0, 4.0)
	c.draw_line(Vector2(-11, -70), Vector2(11, -70), DARK_SHADE, 2.5)       # Plate seam
	c.draw_line(Vector2(-14, -94), Vector2(-14, -74), WHITE_SHADE, 2.0)     # Plate edge detail
	FighterArt.rrect(c, Rect2(-17, -57, 34, 9), DARK_SHADE, VISOR, DARK, 3.0, 3.0)   # Belt
	c.draw_rect(Rect2(-3, -55, 6, 5), CORE)                                  # Belt buckle light

	# --- Glowing BLUE core ---
	var pulse2 := 0.5 + 0.5 * sin(t * 4.0)
	var cc := Vector2(5, -82)
	c.draw_circle(cc, 15.0 + 3.0 * pulse2, Color(CORE.r, CORE.g, CORE.b, 0.22 + 0.15 * pulse2))
	c.draw_circle(cc, 10.5, FighterArt.BLACK)
	c.draw_circle(cc, 8.0, CORE)
	c.draw_circle(cc + Vector2(-1.5, -1.5), 4.5, CORE_HI)
	c.draw_circle(cc + Vector2(-3.0, -3.0), 1.6, Color.WHITE)
	FighterArt.ball(c, Vector2(2, -95), 8.0, DARK, DARK_SHADE, DARK_HI)   # Shoulder joint

	# --- Head: PURE WHITE helmet, black visor with glowing blue slit ---
	FighterArt.ball(c, Vector2(3, -113), 15.0, WHITE, WHITE_SHADE, WHITE)
	FighterArt.rrect(c, Rect2(6, -120, 14, 9), VISOR, VISOR, DARK, 3.0, 3.0)
	c.draw_rect(Rect2(9, -117, 9, 3), CORE)
	c.draw_circle(Vector2(-7, -113), 4.0, FighterArt.BLACK)                 # Ear bolt
	c.draw_circle(Vector2(-7, -113), 2.6, CORE)

	_drill(c, t, drill_len)
	_arm(c, Vector2(4, -92), el, hand, false)             # Near arm

	# --- Block shield (blue arc in front) ---
	if b > 0.05:
		var col := Color(0.35, 0.85, 1.0, 0.85 * b)
		if perfect_flash > 0.0:
			col = Color(1, 1, 1, 1)
		c.draw_arc(Vector2(10, -70), 50.0, -1.0, 1.0, 20, Color(0, 0, 0, b), 11.0, true)
		c.draw_arc(Vector2(10, -70), 50.0, -1.0, 1.0, 20, col, 6.0, true)


## GREEN legs, dark gray knee caps + boots.
static func _leg(c: CanvasItem, hip: Vector2, foot: Vector2, far: bool) -> void:
	var base := GREEN_FAR if far else GREEN
	var shade := GREEN_FAR_SHADE if far else GREEN_SHADE
	var hi := GREEN if far else GREEN_HI
	var knee := (hip + foot) * 0.5 + Vector2(7, 0)
	FighterArt.limb(c, hip, knee, 12.0, base, shade, hi)
	FighterArt.limb(c, knee, foot + Vector2(0, -4), 11.0, base, shade, hi)
	FighterArt.ball(c, knee, 5.5, DARK_SHADE if far else DARK, DARK_SHADE, DARK_HI)
	c.draw_circle(knee, 1.8, CORE)
	FighterArt.rrect(c, Rect2(foot.x - 8.0, foot.y - 4.0, 24, 9), DARK_SHADE if far else DARK, VISOR, DARK_HI, 3.0, 3.5)


## Dark gray arm segments, GREEN hands.
static func _arm(c: CanvasItem, shoulder: Vector2, elbow: Vector2, hand: Vector2, far: bool) -> void:
	var base := DARK_SHADE if far else DARK
	var shade := VISOR if far else DARK_SHADE
	FighterArt.limb(c, shoulder, elbow, 9.0, base, shade, DARK_HI)
	FighterArt.limb(c, elbow, hand, 10.0, base, shade, DARK_HI)
	FighterArt.ball(c, elbow, 5.0, base, shade, DARK_HI)
	c.draw_circle(elbow, 1.8, CORE)
	var g := GREEN_FAR if far else GREEN
	var gs := GREEN_FAR_SHADE if far else GREEN_SHADE
	FighterArt.rrect(c, Rect2(hand.x - 7.0, hand.y - 7.0, 15, 15), g, gs, GREEN_HI, 3.5, 3.5)


## Armaggedon Drill: extends from the stomach.
static func _drill(c: CanvasItem, t: float, drill_len: float) -> void:
	if drill_len < 0.03:
		return
	var length := 86.0 * drill_len
	c.draw_set_transform(Vector2(8, -60), 0.0, Vector2.ONE)
	FighterArt.rrect(c, Rect2(-4, -13, 12, 26), DARK, DARK_SHADE, DARK_HI, 3.0, 3.5)
	var tip := Vector2(8.0 + length, 0.0)
	var top := Vector2(8, -12)
	var bot := Vector2(8, 12)
	c.draw_colored_polygon(PackedVector2Array([top, bot, tip]), DRILL)
	c.draw_colored_polygon(PackedVector2Array([Vector2(8, 0), bot, tip]), DRILL_SHADE)
	var off := fmod(t * 80.0, 16.0)
	for i in 6:
		var x := 8.0 + off + float(i) * 16.0
		var x2 := x + 6.0
		if x2 > 8.0 + length:
			continue
		var hw1 := 12.0 * (1.0 - (x - 8.0) / length)
		var hw2 := 12.0 * (1.0 - (x2 - 8.0) / length)
		c.draw_line(Vector2(x, -hw1), Vector2(x2, hw2), FighterArt.BLACK, 2.5)
	c.draw_polyline(PackedVector2Array([top, tip, bot]), FighterArt.BLACK, 4.0, true)
	c.draw_set_transform(Vector2.ZERO, 0.0, Vector2.ONE)


## Full Arsenal: mechanical tentacles behind the body.
static func _tentacles(c: CanvasItem, t: float) -> void:
	var bases := [2.3, 2.9, 3.75, 4.35]
	for i in 4:
		var pos := Vector2(-12, -84)
		var ang: float = bases[i]
		for j in 4:
			ang += sin(t * 2.4 + float(i) * 1.3 + float(j) * 0.8) * 0.25
			var nxt := pos + Vector2.from_angle(ang) * 24.0
			nxt.y = minf(nxt.y, -2.0)                 # Tips never go below the ground
			FighterArt.limb(c, pos, nxt, 7.0, DARK, DARK_SHADE, DARK_HI)
			c.draw_circle(nxt, 2.0, CORE)
			pos = nxt
		FighterArt.ball(c, pos, 6.0, DARK, DARK_SHADE, DARK_HI)
		c.draw_circle(pos, 2.5, CORE)
