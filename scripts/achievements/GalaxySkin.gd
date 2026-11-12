class_name GalaxySkin
extends RefCounted
## GALAXY SKINS for the Architect and the Warrior: the reward of the achievement
## "Multi-Multi-Multiversal Level Of Power". Same models and animations, drawn in deep-space
## colours (indigo, violet, nebula pink, starlight), with a soft nebula aura behind them and
## twinkling stars on the body. Worn in Versus AND Story Mode (Achievements.galaxy_for), and
## can be turned off in the ACHIEVEMENTS menu.

const ARCHITECT := {
	"WHITE": Color(0.17, 0.11, 0.40), "WHITE_SHADE": Color(0.09, 0.05, 0.25),
	"GREEN": Color(0.66, 0.30, 0.98), "GREEN_SHADE": Color(0.38, 0.12, 0.64), "GREEN_HI": Color(0.96, 0.72, 1.0),
	"GREEN_FAR": Color(0.50, 0.21, 0.82), "GREEN_FAR_SHADE": Color(0.27, 0.08, 0.48),
	"DARK": Color(0.10, 0.13, 0.34), "DARK_SHADE": Color(0.04, 0.05, 0.15), "DARK_HI": Color(0.32, 0.45, 0.88),
	"VISOR": Color(0.02, 0.02, 0.07), "CORE": Color(1.0, 0.50, 0.90), "CORE_HI": Color(1.0, 0.92, 1.0),
	"DRILL": Color(0.36, 0.48, 0.90), "DRILL_SHADE": Color(0.20, 0.26, 0.58),
}
const WARRIOR := {
	"VOID": Color(0.08, 0.05, 0.24), "VOID_SHADE": Color(0.02, 0.01, 0.09), "VOID_HI": Color(0.40, 0.26, 0.90),
	"VOID_GLOW": Color(0.95, 0.45, 1.0), "SILVER": Color(0.72, 0.82, 1.0), "SILVER_SHADE": Color(0.40, 0.44, 0.88),
	"SILVER_HI": Color(1.0, 1.0, 1.0), "BLADE": Color(0.58, 0.46, 1.0), "BLADE_SHADE": Color(0.32, 0.22, 0.72),
	"BLADE_EDGE": Color(0.98, 0.86, 1.0),
}
## Star spots on the body (origin = feet, facing right, ~64 x 128 model).
const STARS := [Vector2(-7, -114), Vector2(8, -106), Vector2(-3, -92), Vector2(10, -80), Vector2(-11, -72),
	Vector2(3, -64), Vector2(-6, -40), Vector2(8, -28), Vector2(-8, -16), Vector2(1, -50)]


static func draw_architect(c: CanvasItem, p: Player) -> void:
	_aura(c, p.anim_time)
	ArchitectArt.set_palette(ARCHITECT)
	ArchitectArt.draw(c, p)
	ArchitectArt.set_palette(ArchitectArt.NORMAL_PALETTE)
	_stars(c, p.anim_time)


static func draw_warrior(c: CanvasItem, w: Warrior) -> void:
	_aura(c, w.anim_time)
	WarriorArt.set_palette(WARRIOR)
	WarriorArt.draw(c, w)
	WarriorArt.set_palette(WarriorArt.NORMAL_PALETTE)
	_stars(c, w.anim_time)


## Soft nebula behind the body.
static func _aura(c: CanvasItem, t: float) -> void:
	var p := 0.5 + 0.5 * sin(t * 1.6)
	c.draw_circle(Vector2(0, -66), 62.0 + 4.0 * p, Color(0.35, 0.15, 0.75, 0.10))
	c.draw_circle(Vector2(10, -84), 34.0, Color(0.95, 0.30, 0.80, 0.08 + 0.04 * p))
	c.draw_circle(Vector2(-12, -46), 30.0, Color(0.25, 0.55, 1.0, 0.08 + 0.04 * (1.0 - p)))


## Twinkling 4-point stars on the body.
static func _stars(c: CanvasItem, t: float) -> void:
	for i in STARS.size():
		var tw := 0.5 + 0.5 * sin(t * 3.2 + float(i) * 1.9)
		var pos: Vector2 = STARS[i]
		var r := 1.2 + 2.2 * tw
		var col := Color(1.0, 0.95, 1.0, 0.45 + 0.55 * tw)
		c.draw_line(pos + Vector2(-r * 1.6, 0), pos + Vector2(r * 1.6, 0), col, 1.2, FighterArt.AA)
		c.draw_line(pos + Vector2(0, -r * 1.6), pos + Vector2(0, r * 1.6), col, 1.2, FighterArt.AA)
		c.draw_circle(pos, r * 0.5, col)
