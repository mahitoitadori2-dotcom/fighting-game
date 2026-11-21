class_name TechnicianArt
extends RefCounted
## THE TECHNICIAN: a walking RIG of ship scrap with a GLASS DOME for a head - and inside the dome,
## the little Kharleming engineer that drives it (cyan eye, clicking legs). Piston legs, a riveted
## chest with a cyan core, a WRENCH arm, a CABLE-SPOOL claw arm, a backpack with an antenna.
## The Kharleming ship palette (steel + cyan). Flat cartoon, thick black outlines.
## Drawn facing RIGHT, origin = feet, about 64 x 128.

const PORTRAIT_H := 150.0

const METAL := Color(0.62, 0.66, 0.72)
const METAL_SHADE := Color(0.34, 0.37, 0.43)
const METAL_HI := Color(0.90, 0.93, 0.97)
const RUST := Color(0.55, 0.33, 0.20)
const CYAN := Color(0.35, 1.0, 0.95)
const GLASS := Color(0.70, 0.95, 1.0, 0.35)
const BLACK := Color(0, 0, 0)


static func draw(c: CanvasItem, f: Technician) -> void:
	f.anim_legs = true                                  # This art bends its knees (shared animation)
	_figure(c, {"anim": FighterArt.anim_of(f),"t": f.anim_time, "ph": f.walk_phase, "floor": f.is_on_floor(), "punch": f.punch_ext,
		"block": f.block_amt, "tool": f.tool_k, "coil": f.coil_flash, "heal": f.heal_glow})


static func draw_portrait(c: CanvasItem, t: float) -> void:
	_figure(c, {"t": t})


static func _figure(c: CanvasItem, s: Dictionary) -> void:
	var t: float = s.get("t", 0.0)
	var ph: float = s.get("ph", 0.0)
	var on_floor: bool = s.get("floor", true)
	var punch: float = s.get("punch", 0.0)
	var b: float = s.get("block", 0.0)
	var tool: float = s.get("tool", 0.0)
	var heal: float = s.get("heal", 0.0)
	if heal > 0.0:
		c.draw_circle(Vector2(0, -66), 60.0, Color(0.4, 1.0, 0.85, 0.25 * heal))
	var coil: float = s.get("coil", 0.0)
	if coil > 0.0:                                                 # Spark Coil: an electric ring
		for k in 8:
			var a := TAU * float(k) / 8.0 + t * 8.0
			var p0 := Vector2(0, -60) + Vector2.from_angle(a) * 40.0
			var p1 := Vector2(0, -60) + Vector2.from_angle(a + 0.3) * 150.0 * (1.0 - coil * 1.5)
			c.draw_line(p0, p1, Color(CYAN.r, CYAN.g, CYAN.b, coil * 2.5), 3.0)
	# --- Backpack (behind): a scrap box with an antenna and a cable spool ---
	FighterArt.rrect(c, Rect2(-26, -104, 16, 34), METAL_SHADE, BLACK, METAL, 4.0, 3.0)
	c.draw_line(Vector2(-20, -104), Vector2(-24, -132), BLACK, 3.0)
	c.draw_circle(Vector2(-24, -133), 3.0, CYAN if fmod(t, 1.0) < 0.5 else Color(0.2, 0.5, 0.5))
	c.draw_circle(Vector2(-18, -80), 7.0, BLACK)
	c.draw_circle(Vector2(-18, -80), 5.0, RUST)
	# --- Legs: piston legs with round knee joints and flat clamp feet ---
	var g := FighterArt.gait(s.get("anim", {}), ph, on_floor, -8.0, 8.0, -4.0, 12.0)   # Shared walk / crouch / jump
	_leg(c, Vector2(-6, -54), g[0], true)
	_leg(c, Vector2(6, -54), g[1], false)
	# --- Far arm: the CABLE-SPOOL claw ---
	var claw_hand := Vector2(-10, -58).lerp(Vector2(26, -86), tool)
	_arm(c, Vector2(-6, -92), (Vector2(-6, -92) + claw_hand) * 0.5 + Vector2(-4, 6), claw_hand, true)
	_claw(c, claw_hand)
	# --- Chest: a riveted box, a cyan core, a hazard stripe ---
	var chest := PackedVector2Array([Vector2(-16, -102), Vector2(16, -102), Vector2(18, -66), Vector2(12, -54), Vector2(-12, -54), Vector2(-18, -66)])
	c.draw_colored_polygon(chest, METAL)
	c.draw_colored_polygon(PackedVector2Array([Vector2(-16, -102), Vector2(-6, -102), Vector2(-8, -54), Vector2(-12, -54), Vector2(-18, -66)]), METAL_SHADE)
	for k in 4:                                                    # Hazard stripe
		var x := -12.0 + float(k) * 7.0
		c.draw_colored_polygon(PackedVector2Array([Vector2(x, -62), Vector2(x + 4, -62), Vector2(x + 7, -56), Vector2(x + 3, -56)]), Color(0.95, 0.75, 0.15) if k % 2 == 0 else BLACK)
	for rv: Vector2 in [Vector2(-12, -98), Vector2(12, -98), Vector2(-14, -70), Vector2(14, -70)]:
		c.draw_circle(rv, 1.5, METAL_SHADE)
	var pulse := 0.5 + 0.5 * sin(t * 4.0)
	c.draw_circle(Vector2(2, -84), 9.0 + 2.0 * pulse, Color(CYAN.r, CYAN.g, CYAN.b, 0.2))
	c.draw_circle(Vector2(2, -84), 6.0, BLACK)
	c.draw_circle(Vector2(2, -84), 4.5, CYAN)
	FighterArt.outline(c, chest, 3.0)
	# --- Head: a GLASS DOME with the little Kharleming engineer inside ---
	var hc := Vector2(2, -116)
	c.draw_rect(Rect2(-12, -106, 28, 6), METAL_SHADE)              # Collar ring
	c.draw_rect(Rect2(-12, -106, 28, 6), BLACK, false, 2.0)
	c.draw_set_transform(hc + Vector2(-2, 10), 0.0, Vector2(0.42, 0.42))
	Kharleming.draw_bot(c, {"t": t * 2.0, "pose": "idle", "moving": absf(sin(t * 3.0)) > 0.7})
	c.draw_set_transform(Vector2.ZERO, 0.0, Vector2.ONE)
	c.draw_circle(hc, 17.0, GLASS)
	c.draw_arc(hc, 17.0, PI, TAU, 16, BLACK, 3.0)
	c.draw_arc(hc + Vector2(-5, -5), 9.0, PI * 1.1, PI * 1.6, 8, Color(1, 1, 1, 0.7), 2.5)   # Glass shine
	# --- Near arm: the WRENCH ---
	var e := clampf(punch, 0.0, 1.0)
	var hand := Vector2(14, -58).lerp(Vector2(44, -84), e)
	if punch < 0.0:
		hand = Vector2(14, -58) + Vector2(-10, -22) * (-punch * 2.0)
	hand = hand.lerp(Vector2(22, -92), b)
	_arm(c, Vector2(6, -92), (Vector2(6, -92) + hand) * 0.5 + Vector2(4, 8), hand, false)
	_wrench(c, hand, lerpf(-1.2, 0.1, e) if punch >= 0.0 else -2.2)
	if b > 0.05:
		c.draw_arc(Vector2(10, -70), 50.0, -1.0, 1.0, 20, Color(0, 0, 0, b), 11.0, FighterArt.AA)
		c.draw_arc(Vector2(10, -70), 50.0, -1.0, 1.0, 20, Color(CYAN.r, CYAN.g, CYAN.b, 0.85 * b), 6.0, FighterArt.AA)


static func _leg(c: CanvasItem, hip: Vector2, foot: Vector2, far: bool) -> void:
	var col := METAL_SHADE if far else METAL
	var knee := FighterArt.knee(hip, foot, FighterArt.leg_seg(50.0, 6.0))   # Real knee bend
	FighterArt.limb(c, hip, knee, 10.0, col, METAL_SHADE, METAL_HI)
	FighterArt.limb(c, knee, foot + Vector2(0, -4), 7.0, METAL_SHADE if far else RUST.lerp(METAL, 0.5), METAL_SHADE, METAL_HI)
	FighterArt.ball(c, knee, 5.0, METAL_SHADE, BLACK, METAL)
	c.draw_circle(knee, 1.8, CYAN)
	FighterArt.rrect(c, Rect2(foot.x - 9.0, foot.y - 5.0, 22, 8), METAL_SHADE if far else METAL, BLACK, METAL_HI, 2.0, 3.0)


static func _arm(c: CanvasItem, shoulder: Vector2, elbow: Vector2, hand: Vector2, far: bool) -> void:
	var col := METAL_SHADE if far else METAL
	FighterArt.limb(c, shoulder, elbow, 8.0, col, METAL_SHADE, METAL_HI)
	FighterArt.limb(c, elbow, hand, 7.0, col, METAL_SHADE, METAL_HI)
	FighterArt.ball(c, elbow, 4.0, METAL_SHADE, BLACK, METAL)


## PIXEL ART wrench (hand-pixelled): long handle, open jaw head. Pivot = the hand.
const _WRENCH_PX := [
	"...........KKKK.",
	"..........KMMMMK",
	".KKKKKKKKKMMMKKK",
	"KhhhhhhhhhMMK...",
	".KKKKKKKKKMMMKKK",
	"..........KMMMMK",
	"...........KKKK.",
]


static func _wrench(c: CanvasItem, hand: Vector2, ang: float) -> void:
	PixelSprite.draw_rotated(c, PackedStringArray(_WRENCH_PX), {
		"K": BLACK, "h": METAL_HI.lerp(METAL, 0.4), "M": METAL,
	}, hand, Vector2(1.5, 3.5), ang)

static func _claw(c: CanvasItem, hand: Vector2) -> void:
	c.draw_circle(hand, 7.0, BLACK)
	c.draw_circle(hand, 5.0, RUST)
	for k: float in [-1.0, 1.0]:
		c.draw_line(hand, hand + Vector2(8, k * 6.0), BLACK, 3.0)
