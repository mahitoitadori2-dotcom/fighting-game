class_name ArchitectArt
extends RefCounted
## The Mighty Architect: cyborg with PURE WHITE helmet + chest plate, GREEN hands
## and legs, dark gray / black armor details and a glowing BLUE chest core.
## Drawn facing RIGHT, origin = feet, about 64 x 128.
##
## draw(c, player)        -> in-game, animated from the Player's state
## draw_portrait(c, t)    -> idle pose for menus / Character Select cards

## PALETTE (static vars, not consts, so the ANTI ARCHITECT can draw the very same model with
## an inverted palette: AntiArchitectArt calls set_palette(ANTI_PALETTE) around a draw).
const NORMAL_PALETTE := {
	"WHITE": Color(1.0, 1.0, 1.0), "WHITE_SHADE": Color(0.80, 0.84, 0.90),
	"GREEN": Color(0.22, 0.86, 0.28), "GREEN_SHADE": Color(0.08, 0.52, 0.15), "GREEN_HI": Color(0.72, 1.0, 0.62),
	"GREEN_FAR": Color(0.13, 0.62, 0.19), "GREEN_FAR_SHADE": Color(0.05, 0.36, 0.10),
	"DARK": Color(0.25, 0.27, 0.31), "DARK_SHADE": Color(0.12, 0.13, 0.16), "DARK_HI": Color(0.46, 0.49, 0.55),
	"VISOR": Color(0.07, 0.08, 0.11), "CORE": Color(0.18, 0.68, 1.0), "CORE_HI": Color(0.78, 0.95, 1.0),
	"DRILL": Color(0.56, 0.60, 0.67), "DRILL_SHADE": Color(0.34, 0.37, 0.43),
}
## Negative / reverse colours: black armor plate, ORANGE limbs, pale grey details, orange core.
const ANTI_PALETTE := {
	"WHITE": Color(0.10, 0.10, 0.12), "WHITE_SHADE": Color(0.22, 0.18, 0.12),
	"GREEN": Color(1.0, 0.50, 0.10), "GREEN_SHADE": Color(0.66, 0.28, 0.04), "GREEN_HI": Color(1.0, 0.78, 0.45),
	"GREEN_FAR": Color(0.82, 0.38, 0.06), "GREEN_FAR_SHADE": Color(0.50, 0.20, 0.03),
	"DARK": Color(0.75, 0.73, 0.69), "DARK_SHADE": Color(0.55, 0.53, 0.50), "DARK_HI": Color(0.92, 0.90, 0.86),
	"VISOR": Color(0.93, 0.92, 0.89), "CORE": Color(1.0, 0.45, 0.05), "CORE_HI": Color(1.0, 0.82, 0.45),
	"DRILL": Color(0.44, 0.40, 0.33), "DRILL_SHADE": Color(0.66, 0.63, 0.57),
}

# --- PURE WHITE: helmet + chest plate ---
static var WHITE := Color(1.0, 1.0, 1.0, 1.0)
static var WHITE_SHADE := Color(0.80, 0.84, 0.90, 1.0)     # Thin cartoon shade strip only
# --- GREEN: hands + legs ---
static var GREEN := Color(0.22, 0.86, 0.28, 1.0)
static var GREEN_SHADE := Color(0.08, 0.52, 0.15, 1.0)
static var GREEN_HI := Color(0.72, 1.0, 0.62, 1.0)
static var GREEN_FAR := Color(0.13, 0.62, 0.19, 1.0)        # Far-side limbs (slightly darker)
static var GREEN_FAR_SHADE := Color(0.05, 0.36, 0.10, 1.0)
# --- Dark gray / black armor details ---
static var DARK := Color(0.25, 0.27, 0.31, 1.0)
static var DARK_SHADE := Color(0.12, 0.13, 0.16, 1.0)
static var DARK_HI := Color(0.46, 0.49, 0.55, 1.0)
static var VISOR := Color(0.07, 0.08, 0.11, 1.0)
# --- Glowing BLUE core ---
static var CORE := Color(0.18, 0.68, 1.0, 1.0)
static var CORE_HI := Color(0.78, 0.95, 1.0, 1.0)
# --- Drill metal ---
static var DRILL := Color(0.56, 0.60, 0.67, 1.0)
static var DRILL_SHADE := Color(0.34, 0.37, 0.43, 1.0)


## Swap the palette (always put NORMAL_PALETTE back right after drawing).
static func set_palette(p: Dictionary) -> void:
	WHITE = p["WHITE"]
	WHITE_SHADE = p["WHITE_SHADE"]
	GREEN = p["GREEN"]
	GREEN_SHADE = p["GREEN_SHADE"]
	GREEN_HI = p["GREEN_HI"]
	GREEN_FAR = p["GREEN_FAR"]
	GREEN_FAR_SHADE = p["GREEN_FAR_SHADE"]
	DARK = p["DARK"]
	DARK_SHADE = p["DARK_SHADE"]
	DARK_HI = p["DARK_HI"]
	VISOR = p["VISOR"]
	CORE = p["CORE"]
	CORE_HI = p["CORE_HI"]
	DRILL = p["DRILL"]
	DRILL_SHADE = p["DRILL_SHADE"]


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
	_leg(c, Vector2(-5, -53), Vector2(-7.0 - s, -5.0 - lift_b), true)
	_leg(c, Vector2(5, -53), Vector2(7.0 + s, -5.0 - lift_f), false)

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

	# --- Torso: ATHLETIC V shape - broad shoulders, chest plate, narrow waist ---
	var torso := PackedVector2Array([Vector2(-19, -101), Vector2(19, -101), Vector2(23, -96),
		Vector2(21, -88), Vector2(13, -70), Vector2(10, -53), Vector2(-10, -53), Vector2(-13, -70),
		Vector2(-21, -88), Vector2(-23, -96)])
	c.draw_colored_polygon(torso, DARK)
	c.draw_colored_polygon(PackedVector2Array([Vector2(-13, -70), Vector2(-10, -53), Vector2(-6, -53),
		Vector2(-8, -70)]), DARK_SHADE)                                             # Shaded flank
	for k in 3:                                                                  # Six-pack under the plate
		var ay := -70.0 + float(k) * 4.5
		c.draw_line(Vector2(-7, ay), Vector2(7, ay), DARK_HI, 1.8)
	c.draw_line(Vector2(0, -72), Vector2(0, -58), DARK_HI, 1.8)
	FighterArt.outline(c, torso, 4.0)
	# PURE WHITE chest plate: shoulder caps + two pecs, ending above the abs
	var plate := PackedVector2Array([Vector2(-20, -103), Vector2(20, -103), Vector2(24, -96),
		Vector2(20, -83), Vector2(9, -75), Vector2(0, -77), Vector2(-9, -75), Vector2(-20, -83),
		Vector2(-24, -96)])
	c.draw_colored_polygon(plate, WHITE)
	c.draw_colored_polygon(PackedVector2Array([Vector2(-24, -96), Vector2(-20, -83), Vector2(-12, -78),
		Vector2(-17, -86), Vector2(-20, -96)]), WHITE_SHADE)                        # Shade strip
	FighterArt.outline(c, plate, 4.0)
	c.draw_line(Vector2(0, -98), Vector2(0, -78), WHITE_SHADE, 2.0)              # Pec split
	c.draw_line(Vector2(-17, -84), Vector2(-3, -80), WHITE_SHADE, 2.0)           # Pec undersides
	c.draw_line(Vector2(17, -84), Vector2(3, -80), WHITE_SHADE, 2.0)
	FighterArt.rrect(c, Rect2(-12, -57, 24, 8), DARK_SHADE, VISOR, DARK, 3.0, 3.0)   # Belt (slim waist)
	c.draw_rect(Rect2(-3, -55, 6, 4), CORE)                                  # Belt buckle light

	# --- Glowing BLUE core ---
	var pulse2 := 0.5 + 0.5 * sin(t * 4.0)
	var cc := Vector2(-6, -90)                                                  # Left pec: not hidden by the arm
	c.draw_circle(cc, 11.0 + 2.5 * pulse2, Color(CORE.r, CORE.g, CORE.b, 0.22 + 0.15 * pulse2))
	c.draw_circle(cc, 9.0, FighterArt.BLACK)
	c.draw_circle(cc, 6.8, CORE)
	c.draw_circle(cc + Vector2(-1.3, -1.3), 3.8, CORE_HI)
	c.draw_circle(cc + Vector2(-2.6, -2.6), 1.4, Color.WHITE)
	FighterArt.ball(c, Vector2(3, -96), 8.5, DARK, DARK_SHADE, DARK_HI)   # Shoulder pad

	# --- Head: PURE WHITE helmet (a bit smaller: athletic proportions), black visor ---
	c.draw_line(Vector2(2, -102), Vector2(3, -110), FighterArt.BLACK, 12.0)   # Neck
	c.draw_line(Vector2(2, -102), Vector2(3, -110), DARK, 7.0)
	FighterArt.ball(c, Vector2(3, -117), 12.5, WHITE, WHITE_SHADE, WHITE)
	FighterArt.rrect(c, Rect2(6, -123, 12, 8), VISOR, VISOR, DARK, 3.0, 3.0)
	c.draw_rect(Rect2(8, -120, 8, 3), CORE)
	c.draw_circle(Vector2(-5, -117), 3.4, FighterArt.BLACK)                 # Ear bolt
	c.draw_circle(Vector2(-5, -117), 2.2, CORE)

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
	var knee := (hip + foot) * 0.5 + Vector2(6, 0)
	FighterArt.limb(c, hip, knee, 10.0, base, shade, hi)                   # Athletic: lean thigh
	FighterArt.limb(c, knee, foot + Vector2(0, -4), 8.0, base, shade, hi)  # Slim shin
	FighterArt.ball(c, knee, 4.5, DARK_SHADE if far else DARK, DARK_SHADE, DARK_HI)
	c.draw_circle(knee, 1.6, CORE)
	FighterArt.rrect(c, Rect2(foot.x - 7.0, foot.y - 4.0, 20, 8), DARK_SHADE if far else DARK, VISOR, DARK_HI, 3.0, 3.5)


## Dark gray arm segments, GREEN hands.
static func _arm(c: CanvasItem, shoulder: Vector2, elbow: Vector2, hand: Vector2, far: bool) -> void:
	var base := DARK_SHADE if far else DARK
	var shade := VISOR if far else DARK_SHADE
	FighterArt.limb(c, shoulder, elbow, 8.5, base, shade, DARK_HI)          # Defined upper arm
	FighterArt.limb(c, elbow, hand, 7.5, base, shade, DARK_HI)              # Lean forearm
	FighterArt.ball(c, elbow, 4.5, base, shade, DARK_HI)
	c.draw_circle(elbow, 1.6, CORE)
	var g := GREEN_FAR if far else GREEN
	var gs := GREEN_FAR_SHADE if far else GREEN_SHADE
	FighterArt.rrect(c, Rect2(hand.x - 6.5, hand.y - 6.5, 13, 13), g, gs, GREEN_HI, 3.5, 3.5)


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
