class_name EnlightenedGuard
extends ArmedSoldier
## ENLIGHTENED GUARD (Story Mode, Colosseum 2 - Home of the Enlightened Ones): a tall
## sentinel in white armour with gold trim, a faceless golden helm, a floating halo,
## a long spear and a sun shield. Holds the line and keeps you at spear's length.
##
##   Spear Thrust   6 dmg, 2.2 s - a long poke straight ahead
##   Shield Bash    4 dmg, 3.0 s - steps in and shoves you with the sun shield

const THRUST_KB := Vector2(300, -160)
const BASH_KB := Vector2(420, -140)

const WHITE := Color(0.93, 0.92, 0.88)
const WHITE_SHADE := Color(0.70, 0.68, 0.64)
const WHITE_HI := Color(1.0, 1.0, 0.98)
const GOLD := Color(0.95, 0.75, 0.25)
const GOLD_SHADE := Color(0.65, 0.45, 0.10)
const GOLD_HI := Color(1.0, 0.92, 0.6)
const SHAFT := Color(0.55, 0.40, 0.22)
const GLOW := Color(1.0, 0.95, 0.65)
## Other weapons (ArmedSoldier kit): id suffix -> name. The plain "guard" keeps spear + sun shield.
const WEAPON_NAMES := {"short_sword": "Enlightened Blade", "hammer": "Enlightened Smiter",
	"greatshield": "Enlightened Bulwark", "bow": "Enlightened Archer"}


func native_weapon() -> String:
	return "spear"


func weapon_names() -> Dictionary:
	return WEAPON_NAMES


static func palette() -> Dictionary:
	return {"arm": WHITE, "arm_shade": WHITE_SHADE, "arm_hi": WHITE_HI, "hand": GOLD,
		"metal": Color(0.96, 0.9, 0.7), "accent": GOLD, "dark": GOLD_SHADE, "wood": SHAFT}


func _make_data() -> CharacterData:
	if not is_native():
		return weapon_data(30)
	keep_min = 60.0
	keep_max = 130.0
	attack_chance = 0.6
	phase2_threshold = -1.0
	return SimpleEnemy.make_data("Enlightened Guard", 30, Vector2(60, 140), 190.0)


static func make_patterns() -> Array[EnemyPattern]:
	var list: Array[EnemyPattern] = []
	#                          id        name             cd    dmg  min   max    anim      tele  active rec   big    weights
	list.append(EnemyPattern.make("thrust", "SPEAR THRUST", 2.2, 6, 0.0, 165.0, "thrust", 0.45, 0.18, 0.45, false, [2.0, 2.0]))
	list.append(EnemyPattern.make("bash", "SHIELD BASH", 3.0, 4, 0.0, 95.0, "bash", 0.25, 0.25, 0.40, false, [1.0, 1.0]))
	return list


func flavor_lines() -> Array[String]:
	return ["Turn back, unclean one.", "The Light forbids you.", "Kneel."]


func _attack(p: EnemyPattern) -> void:
	if not is_native():
		_weapon_attack(p)
		return
	match p.id:
		"thrust":
			hitbox.activate(make_hit(dmg(p), Vector2(facing * THRUST_KB.x, THRUST_KB.y), "guard_thrust"),
				Vector2(facing * 95.0, -78.0), Vector2(150, 40))
			velocity.x = facing * 140.0
			SoundManager.play_sfx("sword_slash", -5.0)
		"bash":
			hitbox.activate(make_hit(dmg(p), Vector2(facing * BASH_KB.x, BASH_KB.y), "guard_bash"),
				Vector2(facing * 42.0, -70.0), Vector2(60, 110))
			velocity.x = facing * 380.0
			SoundManager.play_sfx("block", -6.0)


# ============================================================
# ART (facing right, origin = feet, ~80 x 170)
# ============================================================
func draw_model_on(c: CanvasItem) -> void:
	draw_guard(c, art_state())


static func draw_portrait(c: CanvasItem, t: float) -> void:
	draw_guard(c, {"t": t, "pose": "idle"})


## Board tile / roster portrait of a weapon variant ("bow", "greatshield"...).
static func draw_portrait_weapon(c: CanvasItem, t: float, w: String) -> void:
	draw_guard(c, {"t": t, "pose": "idle", "weapon": w})


static func draw_guard(c: CanvasItem, s: Dictionary) -> void:
	var t: float = s.get("t", 0.0)
	var pose_v: String = s.get("pose", "idle")
	var dead: bool = s.get("dead", false)
	var w: String = s.get("weapon", "")
	var bob := sin(t * 2.0) * 1.5

	# Halo glow behind
	var head := Vector2(4, -128 + bob)
	EnemyArt.aura(c, head, 26.0, GLOW, t)

	EnemyArt.legs(c, s, -58.0, 10.0, 11.0, WHITE, WHITE_SHADE, WHITE_HI, GOLD_SHADE, 18.0)
	var chest := Vector2(0, -92 + bob)
	if w != "":
		ArmedSoldier.draw_weapon_back(c, s, chest, palette())
		_draw_body(c, chest, head, t, dead)
		ArmedSoldier.draw_weapon_front(c, s, chest, palette())
		return

	# Spear (behind the body when idle, forward on the thrust)
	var hand := Vector2(26, -78 + bob)
	var reach := 0.0
	match pose_v:
		"thrust_tele":
			hand = Vector2(-6, -82 + bob)
			reach = -20.0
		"thrust":
			hand = Vector2(54, -80 + bob)
			reach = 60.0
	var tip := Vector2(hand.x + 84.0 + reach, hand.y - 2.0)
	var butt := Vector2(hand.x - 70.0, hand.y + (10.0 if pose_v == "idle" else 2.0))
	if pose_v == "idle" or pose_v == "bash" or pose_v == "bash_tele":
		tip = Vector2(hand.x + 8.0, -200 + bob)                              # Spear held upright
		butt = Vector2(hand.x - 6.0, -6.0)
	c.draw_line(butt, tip, EnemyArt.BLACK, 7.0)
	c.draw_line(butt, tip, SHAFT, 4.0)
	var d := (tip - butt).normalized()
	var n := d.orthogonal()
	var blade := PackedVector2Array([tip - d * 4.0 + n * 7.0, tip + d * 22.0, tip - d * 4.0 - n * 7.0])
	c.draw_colored_polygon(blade, GOLD)
	FighterArt.outline(c, blade, 2.5)
	c.draw_line(tip - d * 6.0 + n * 9.0, tip - d * 6.0 - n * 9.0, GOLD_SHADE, 4.0)

	# Armoured body: white plate, gold trim, tabard
	_draw_torso(c, chest)

	# Arm holding the spear
	EnemyArt.arm(c, chest + Vector2(14, -18), hand, 9.0, WHITE, WHITE_SHADE, WHITE_HI, GOLD, 6.5)

	_draw_helm(c, head, t, dead)

	# Sun shield on the front arm
	var sh := chest + Vector2(22, 8)
	if pose_v == "bash_tele":
		sh = chest + Vector2(10, 4)
	elif pose_v == "bash":
		sh = chest + Vector2(38, 2)
	var disc := EnemyArt.ellipse_points(sh, 14.0, 28.0, 20)
	c.draw_colored_polygon(disc, WHITE)
	FighterArt.outline(c, disc, 3.5)
	c.draw_colored_polygon(EnemyArt.ellipse_points(sh, 8.0, 18.0, 16), GOLD)
	EnemyArt.star(c, sh, 6.0, GOLD_HI, 1.5)
	if pose_v == "thrust" or pose_v == "bash":                                   # Swoosh
		c.draw_line(Vector2(40, -80), Vector2(110, -80), Color(1, 1, 0.8, 0.5), 3.0)


static func _draw_body(c: CanvasItem, chest: Vector2, head: Vector2, t: float, dead: bool) -> void:
	_draw_torso(c, chest)
	_draw_helm(c, head, t, dead)


static func _draw_torso(c: CanvasItem, chest: Vector2) -> void:
	var torso := PackedVector2Array([chest + Vector2(-22, -26), chest + Vector2(24, -26), chest + Vector2(20, 30), chest + Vector2(-20, 30)])
	c.draw_polygon(torso, PackedColorArray([WHITE_HI, WHITE, WHITE_SHADE, WHITE_SHADE]))
	FighterArt.outline(c, torso, 4.0)
	var tabard := PackedVector2Array([chest + Vector2(-10, 0), chest + Vector2(12, 0), chest + Vector2(10, 46), chest + Vector2(0, 52), chest + Vector2(-8, 46)])
	c.draw_colored_polygon(tabard, GOLD)
	FighterArt.outline(c, tabard, 2.5)
	EnemyArt.star(c, chest + Vector2(1, 14), 6.0, WHITE_HI, 1.5)              # Sun emblem
	c.draw_line(chest + Vector2(-22, -24), chest + Vector2(24, -24), GOLD, 4.0)
	FighterArt.ball(c, chest + Vector2(-20, -22), 11.0, WHITE, WHITE_SHADE, WHITE_HI)   # Pauldron


## Helm: smooth golden mask, glowing eye slit, white plume, halo.
static func _draw_helm(c: CanvasItem, head: Vector2, t: float, dead: bool) -> void:
	c.draw_colored_polygon(PackedVector2Array([head + Vector2(-16, -8), head + Vector2(-30, -22 + sin(t * 3.0) * 2.0), head + Vector2(-12, -18)]), WHITE)
	FighterArt.ball(c, head, 16.0, GOLD, GOLD_SHADE, GOLD_HI)
	if dead:
		EnemyArt.ko_eye(c, head + Vector2(7, -1), 3.0, t)
	else:
		c.draw_line(head + Vector2(0, -2), head + Vector2(14, -2), Color(GLOW.r, GLOW.g, GLOW.b, 0.5), 6.0)
		c.draw_line(head + Vector2(0, -2), head + Vector2(14, -2), Color.WHITE, 2.5)
	c.draw_set_transform(head + Vector2(0, -24), 0.0, Vector2(1.0, 0.3))
	c.draw_arc(Vector2.ZERO, 18.0, 0.0, TAU, 24, Color(GLOW.r, GLOW.g, GLOW.b, 0.35), 8.0, FighterArt.AA)
	c.draw_arc(Vector2.ZERO, 18.0, 0.0, TAU, 24, GOLD_HI, 3.0, FighterArt.AA)
	c.draw_set_transform(Vector2.ZERO, 0.0, Vector2.ONE)
