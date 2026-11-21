class_name AssassinSkin
extends RefCounted
## ASSASSIN skins for the Warrior and the Architect (Story Mode): the reward for beating THE XX0XN
## (Madness level 20). Assassin-style clothes (charcoal and black, a dark sash), a RED BANDANA tied
## around the head with its tails flying, RED GOGGLES. The Warrior also gets a MEAT TENTACLE ARM.
## Looks only - no change in damage. Picked in the STORY SKINS catalogue (StoryProgress.story_skin == "assassin").

const ARCHITECT := {
	"WHITE": Color(0.20, 0.20, 0.22), "WHITE_SHADE": Color(0.12, 0.12, 0.14),                    # Charcoal coat
	"GREEN": Color(0.16, 0.15, 0.17), "GREEN_SHADE": Color(0.07, 0.07, 0.08), "GREEN_HI": Color(0.32, 0.30, 0.34),
	"GREEN_FAR": Color(0.12, 0.11, 0.13), "GREEN_FAR_SHADE": Color(0.05, 0.05, 0.06),
	"DARK": Color(0.42, 0.06, 0.06), "DARK_SHADE": Color(0.24, 0.03, 0.03), "DARK_HI": Color(0.62, 0.12, 0.10),   # The red sash
	"VISOR": Color(0.04, 0.04, 0.05), "CORE": Color(1.0, 0.18, 0.12), "CORE_HI": Color(1.0, 0.65, 0.55),
	"DRILL": Color(0.48, 0.48, 0.52), "DRILL_SHADE": Color(0.26, 0.26, 0.30),
}
const WARRIOR := {
	"VOID": Color(0.14, 0.13, 0.15), "VOID_SHADE": Color(0.05, 0.05, 0.06), "VOID_HI": Color(0.36, 0.08, 0.08),
	"VOID_GLOW": Color(1.0, 0.2, 0.15), "SILVER": Color(0.24, 0.23, 0.26), "SILVER_SHADE": Color(0.12, 0.12, 0.14),
	"SILVER_HI": Color(0.45, 0.44, 0.48), "BLADE": Color(0.66, 0.66, 0.70), "BLADE_SHADE": Color(0.40, 0.40, 0.44),
	"BLADE_EDGE": Color(1.0, 0.35, 0.3),
}
const BANDANA := Color(0.80, 0.06, 0.05)
const BANDANA_SHADE := Color(0.48, 0.03, 0.03)
const LENS := Color(1.0, 0.12, 0.08)
const MEAT := Color(0.72, 0.30, 0.30)
const MEAT_SHADE := Color(0.45, 0.14, 0.15)


## Is this fighter wearing it? (Story Mode - Madness too - your heroes, earned + picked.)
static func worn_by(f: Fighter) -> bool:
	if f == null or not StoryManager.active or f.team != 1:
		return false
	Madness.load_data()
	return Madness.skin and StoryProgress.story_skin == "assassin"


static func draw_architect(c: CanvasItem, p: Player) -> void:
	ArchitectArt.set_palette(ARCHITECT)
	ArchitectArt.draw(c, p)
	ArchitectArt.set_palette(ArchitectArt.NORMAL_PALETTE)
	_head_gear(c, p.anim_time, Vector2(3, -117), 12.5)


static func draw_warrior(c: CanvasItem, w: Warrior) -> void:
	_tentacle_arm(c, w.anim_time, w.anim_attack)
	WarriorArt.set_palette(WARRIOR)
	WarriorArt.draw(c, w)
	WarriorArt.set_palette(WarriorArt.NORMAL_PALETTE)
	_head_gear(c, w.anim_time, Vector2(3, -113), 15.0)


static func draw_portrait(c: CanvasItem, hero: String, t: float) -> void:
	if hero == "architect":
		ArchitectArt.set_palette(ARCHITECT)
		ArchitectArt.draw_portrait(c, t)
		ArchitectArt.set_palette(ArchitectArt.NORMAL_PALETTE)
		_head_gear(c, t, Vector2(3, -117), 12.5)
	else:
		_tentacle_arm(c, t, 0.0)
		WarriorArt.set_palette(WARRIOR)
		WarriorArt.draw_portrait(c, t)
		WarriorArt.set_palette(WarriorArt.NORMAL_PALETTE)
		_head_gear(c, t, Vector2(3, -113), 15.0)


## The red bandana (a band around the head, two tails flying behind) + the red goggles.
static func _head_gear(c: CanvasItem, t: float, hc: Vector2, r: float) -> void:
	var band := PackedVector2Array([hc + Vector2(-r - 1.0, -r * 0.55), hc + Vector2(r + 1.0, -r * 0.65), hc + Vector2(r + 1.0, -r * 0.25), hc + Vector2(-r - 1.0, -r * 0.15)])
	c.draw_colored_polygon(band, BANDANA)
	FighterArt.outline(c, band, 2.5)
	var knot := hc + Vector2(-r - 2.0, -r * 0.35)
	for k in 2:                                                       # Tails flutter behind
		var tail := PackedVector2Array([knot, knot + Vector2(-18.0 - 6.0 * float(k), 4.0 + sin(t * 9.0 + float(k)) * 5.0 + 6.0 * float(k)),
			knot + Vector2(-16.0 - 6.0 * float(k), 10.0 + sin(t * 9.0 + float(k) + 0.6) * 5.0 + 6.0 * float(k)), knot + Vector2(0, 5)])
		c.draw_colored_polygon(tail, BANDANA_SHADE if k == 1 else BANDANA)
	c.draw_circle(knot, 4.0, BANDANA_SHADE)
	# Red goggles over the eyes (facing right)
	for gx: float in [r * 0.35, r * 0.95]:
		var g := hc + Vector2(gx, -1.0)
		c.draw_circle(g, r * 0.32 + 2.0, FighterArt.BLACK)
		c.draw_circle(g, r * 0.32, LENS)
		c.draw_circle(g + Vector2(-1.5, -1.5), r * 0.1, Color(1.0, 0.75, 0.7))
	c.draw_line(hc + Vector2(r * 0.35 + r * 0.32, -1.0), hc + Vector2(r * 0.95 - r * 0.32, -1.0), FighterArt.BLACK, 2.0)
	c.draw_line(hc + Vector2(r * 0.03, -1.0), hc + Vector2(-r - 1.0, -2.0), FighterArt.BLACK, 3.0)          # The strap


## The Warrior's MEAT TENTACLE ARM (behind the body, from the far shoulder): raw, segmented, twitching.
static func _tentacle_arm(c: CanvasItem, t: float, attack: float) -> void:
	var base := Vector2(-6, -92)
	var reach := 1.0 + maxf(attack, 0.0) * 0.6
	var pts := PackedVector2Array()
	for i in 9:
		var k := float(i) / 8.0
		pts.append(base + Vector2(-8.0 * k + 30.0 * k * k * reach, 46.0 * k) + Vector2(sin(t * 5.0 + k * 4.0) * 7.0 * k, 0))
	for i in range(pts.size() - 1):
		var w := lerpf(13.0, 5.0, float(i) / float(pts.size() - 1))
		c.draw_line(pts[i], pts[i + 1], FighterArt.BLACK, w + 4.0)
	for i in range(pts.size() - 1):
		var w2 := lerpf(13.0, 5.0, float(i) / float(pts.size() - 1))
		c.draw_line(pts[i], pts[i + 1], MEAT if i % 2 == 0 else MEAT_SHADE, w2)
		c.draw_circle(pts[i], w2 * 0.35, Color(0.9, 0.5, 0.5, 0.6))       # Raw, glistening
	var tip := pts[pts.size() - 1]
	for k in 3:                                                          # Little curling feelers
		c.draw_line(tip, tip + Vector2.from_angle(1.2 + float(k) * 0.6 + sin(t * 6.0) * 0.3) * 10.0, MEAT_SHADE, 3.0)
