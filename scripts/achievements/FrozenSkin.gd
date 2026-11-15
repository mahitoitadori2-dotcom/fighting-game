class_name FrozenSkin
extends RefCounted
## FROZEN EXPEDITION skins for the Warrior and the Architect (Story Mode only): the reward of the
## CRYSTAL SWARM, the secret boss of Terra Ordinariorum's Snow Desert. An Eskimo-style outfit:
## a sealskin-brown parka, cream fur, a fur-lined hood around the face, fur cuffs at the hem.
## Picked in the STORY SKINS catalogue (StoryProgress.story_skin == "frozen").

const ARCHITECT := {
	"WHITE": Color(0.93, 0.89, 0.80), "WHITE_SHADE": Color(0.74, 0.68, 0.58),                    # Cream fur coat
	"GREEN": Color(0.50, 0.34, 0.22), "GREEN_SHADE": Color(0.32, 0.20, 0.12), "GREEN_HI": Color(0.68, 0.50, 0.34),   # Leather
	"GREEN_FAR": Color(0.40, 0.27, 0.17), "GREEN_FAR_SHADE": Color(0.25, 0.15, 0.09),
	"DARK": Color(0.30, 0.20, 0.13), "DARK_SHADE": Color(0.17, 0.11, 0.07), "DARK_HI": Color(0.48, 0.34, 0.22),
	"VISOR": Color(0.07, 0.08, 0.11), "CORE": Color(0.45, 0.85, 1.0), "CORE_HI": Color(0.90, 0.98, 1.0),
	"DRILL": Color(0.70, 0.80, 0.90), "DRILL_SHADE": Color(0.45, 0.55, 0.68),
}
const WARRIOR := {
	"VOID": Color(0.40, 0.27, 0.17), "VOID_SHADE": Color(0.22, 0.14, 0.08), "VOID_HI": Color(0.60, 0.44, 0.30),
	"VOID_GLOW": Color(0.55, 0.85, 1.0), "SILVER": Color(0.93, 0.89, 0.80), "SILVER_SHADE": Color(0.72, 0.66, 0.56),
	"SILVER_HI": Color(1.0, 0.98, 0.94), "BLADE": Color(0.74, 0.86, 0.96), "BLADE_SHADE": Color(0.48, 0.60, 0.74),
	"BLADE_EDGE": Color(0.96, 1.0, 1.0),
}
const FUR := Color(0.96, 0.94, 0.88)
const FUR_SHADE := Color(0.78, 0.74, 0.66)


## Is this fighter wearing it? (Story Mode, your heroes, earned + picked.)
static func worn_by(f: Fighter) -> bool:
	if f == null or not StoryManager.active or f.team != 1:
		return false
	return StoryProgress.frozen_skins and StoryProgress.story_skin == "frozen"


static func draw_architect(c: CanvasItem, p: Player) -> void:
	ArchitectArt.set_palette(ARCHITECT)
	ArchitectArt.draw(c, p)
	ArchitectArt.set_palette(ArchitectArt.NORMAL_PALETTE)
	_fur(c, p.anim_time, Vector2(4, -104))


static func draw_warrior(c: CanvasItem, w: Warrior) -> void:
	WarriorArt.set_palette(WARRIOR)
	WarriorArt.draw(c, w)
	WarriorArt.set_palette(WarriorArt.NORMAL_PALETTE)
	_fur(c, w.anim_time, Vector2(2, -106))


## Portraits (menus, the catalogue): same look, no fighter needed.
static func draw_portrait(c: CanvasItem, hero: String, t: float) -> void:
	if hero == "architect":
		ArchitectArt.set_palette(ARCHITECT)
		ArchitectArt.draw_portrait(c, t)
		ArchitectArt.set_palette(ArchitectArt.NORMAL_PALETTE)
		_fur(c, t, Vector2(4, -104))
	else:
		WarriorArt.set_palette(WARRIOR)
		WarriorArt.draw_portrait(c, t)
		WarriorArt.set_palette(WarriorArt.NORMAL_PALETTE)
		_fur(c, t, Vector2(2, -106))


## The fur-lined hood around the face + a fur hem at the waist.
static func _fur(c: CanvasItem, t: float, head: Vector2) -> void:
	for i in 14:                                                  # Hood rim: fluffy tufts in a ring
		var a := -PI * 0.95 + PI * 1.9 * float(i) / 13.0
		var r := 21.0 + 1.5 * sin(t * 2.0 + float(i))
		var p := head + Vector2(cos(a), sin(a)) * r
		c.draw_circle(p, 5.5, FUR_SHADE)
		c.draw_circle(p + Vector2(-0.8, -0.8), 4.2, FUR)
	for i in 7:                                                   # Hem fur
		var p2 := Vector2(-15.0 + float(i) * 5.0, -54.0 + sin(float(i) * 2.0) * 1.5)
		c.draw_circle(p2, 4.5, FUR_SHADE)
		c.draw_circle(p2 + Vector2(-0.6, -0.6), 3.4, FUR)
