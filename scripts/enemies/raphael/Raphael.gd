class_name Raphael
extends SimpleEnemy
## ARCHANGEL RAPHAEL: angel in white / gold armor, big wings, halo, glowing.
## PvE enemy (BaseEnemy + EnemyPattern + EnemyHUD), 60 HP.
##
##   Light Beam   6 dmg, 6 s  - golden beam straight forward
##   Angel Heal  +15 HP, 15 s - long glowing telegraph (hit him to cancel it!)
##   Wing Gust    4 dmg, 8 s  - flaps his wings, wind pushes you far back

const BEAM_LEN := 480.0
const BEAM_KB := Vector2(220, -90)
const GUST_KB := Vector2(640, -180)
const HEAL_AMOUNT := 15

const ARMOR := Color(0.95, 0.95, 0.98)
const ARMOR_SHADE := Color(0.72, 0.74, 0.82)
const GOLD := Color(1.0, 0.82, 0.28)
const GOLD_SHADE := Color(0.80, 0.58, 0.12)
const SKIN := Color(0.98, 0.86, 0.74)
const SKIN_SHADE := Color(0.82, 0.66, 0.54)
const HAIR := Color(1.0, 0.86, 0.45)
const WING := Color(1.0, 1.0, 1.0)
const WING_SHADE := Color(0.82, 0.86, 0.95)
const HOLY := Color(1.0, 0.92, 0.55)


func _make_data() -> CharacterData:
	keep_min = 150.0
	keep_max = 380.0
	return SimpleEnemy.make_data("Archangel Raphael", EnemyManager.ENEMY_HP, Vector2(60, 130), 260.0)


static func make_patterns() -> Array[EnemyPattern]:
	var list: Array[EnemyPattern] = []
	#                          id            name             cd    dmg  min    max     anim     tele  active rec   big   weights
	list.append(EnemyPattern.make("light_beam", "LIGHT BEAM!", 6.0, 6, 60.0, 520.0, "beam", 0.35, 0.30, 0.35, true, [1.5, 1.5]))
	list.append(EnemyPattern.make("angel_heal", "ANGEL HEAL!", 15.0, 0, 0.0, 99999.0, "heal", 0.80, 0.30, 0.30, true, [2.0, 3.0]))
	list.append(EnemyPattern.make("wing_gust", "WING GUST!", 8.0, 4, 0.0, 260.0, "gust", 0.35, 0.30, 0.35, true, [1.4, 1.4]))
	list[1].note = "heals himself %d HP, hit him to cancel" % HEAL_AMOUNT
	list[2].note = "big wind knockback"
	return list


## Only heal when it actually does something.
func wants_pattern(p: EnemyPattern) -> bool:
	if p.id == "angel_heal":
		return hp <= data.max_hp - 10
	return true


func flavor_lines() -> Array[String]:
	return ["BE NOT AFRAID.", "HALLELUJAH!", "REPENT!"]


func _attack(p: EnemyPattern) -> void:
	match p.id:
		"light_beam":
			hitbox.activate(make_hit(dmg(p), Vector2(facing * BEAM_KB.x, BEAM_KB.y), "light_beam"),
				Vector2(facing * (BEAM_LEN * 0.5 + 30.0), -92.0), Vector2(BEAM_LEN, 26))
			Effects.play_hit_sound(self, "angel_beam", global_position)
		"angel_heal":
			heal(HEAL_AMOUNT)
			Effects.gold_burst(self, global_position + Vector2(0, -70), 70.0)
		"wing_gust":
			var g := spawn_projectile()
			g.look = "wind"
			g.damage = dmg(p)
			g.knockback = GUST_KB
			g.dir = float(facing)
			g.speed = 650.0
			g.lifetime = 0.45
			g.size = Vector2(60, 120)
			g.move = "wing_gust"
			launch(g, global_position + Vector2(facing * 50.0, -66.0))


# ============================================================
# ART (facing right, origin = feet, ~130 x 160 with wings)
# ============================================================
func draw_model_on(c: CanvasItem) -> void:
	draw_angel(c, art_state())


static func draw_portrait(c: CanvasItem, t: float) -> void:
	draw_angel(c, {"t": t, "pose": "idle"})


static func draw_angel(c: CanvasItem, s: Dictionary) -> void:
	var t: float = s.get("t", 0.0)
	var pose: String = s.get("pose", "idle")
	var pt: float = s.get("pose_t", 0.0)
	var dead: bool = s.get("dead", false)
	var hover := sin(t * 2.4) * 2.0

	# Holy glow (stronger while healing)
	var glow := 0.0
	if pose == "heal_tele":
		glow = clampf(pt / 0.8, 0.0, 1.0)
	elif pose == "heal":
		glow = 1.0
	EnemyArt.aura(c, Vector2(0, -80), 62.0 + 30.0 * glow, HOLY, t * (1.0 + glow * 2.0))
	if glow > 0.0:
		for i in 8:
			var a := TAU * float(i) / 8.0 + t * 2.0
			c.draw_line(Vector2(0, -80) + Vector2.from_angle(a) * 40.0, Vector2(0, -80) + Vector2.from_angle(a) * (70.0 + 20.0 * glow), Color(HOLY.r, HOLY.g, HOLY.b, 0.6 * glow), 4.0)

	var chest := Vector2(0, -96 + hover)

	# Wings (behind). Gust = big flap forward
	var flap := sin(t * 3.0) * 0.12
	if pose == "gust_tele":
		flap = -0.5 * clampf(pt / 0.35, 0.0, 1.0)
	elif pose == "gust":
		flap = 0.7
	_wing(c, chest + Vector2(-10, -8), flap, true)
	_wing(c, chest + Vector2(-4, -6), flap + 0.12, false)

	EnemyArt.legs(c, s, -58.0 + hover, 9.0, 12.0, ARMOR, ARMOR_SHADE, Color.WHITE, GOLD, 14.0)

	# Armored skirt (gold-trimmed plates)
	var hip := Vector2(0, -58 + hover)
	var skirt := PackedVector2Array([hip + Vector2(-20, -10), hip + Vector2(20, -10), hip + Vector2(26, 14), hip + Vector2(-26, 14)])
	c.draw_colored_polygon(skirt, ARMOR_SHADE)
	c.draw_line(hip + Vector2(-26, 12), hip + Vector2(26, 12), GOLD, 3.0)
	FighterArt.outline(c, skirt, 3.5)

	# Far arm
	EnemyArt.arm(c, chest + Vector2(-14, -10), chest + Vector2(-20, 30), 11.0, ARMOR_SHADE, ARMOR_SHADE.darkened(0.15), ARMOR, SKIN_SHADE)

	# Breastplate
	FighterArt.rrect(c, Rect2(chest.x - 20, chest.y - 22, 40, 48), ARMOR, ARMOR_SHADE, Color.WHITE, 8.0, 4.0)
	c.draw_line(chest + Vector2(0, -18), chest + Vector2(0, 22), GOLD, 3.0)
	EnemyArt.star(c, chest + Vector2(0, -4), 7.0, GOLD, 2.0)
	FighterArt.rrect(c, Rect2(chest.x - 26, chest.y - 26, 18, 14), GOLD, GOLD_SHADE, Color(1, 1, 0.8), 6.0, 3.0)   # Pauldron

	# Head + golden hair + halo
	var head := chest + Vector2(4, -38)
	var hair := EnemyArt.ellipse_points(head + Vector2(-3, -2), 17, 16, 18)
	c.draw_colored_polygon(hair, HAIR)
	FighterArt.outline(c, hair, 3.0)
	FighterArt.ball(c, head + Vector2(2, 2), 13.0, SKIN, SKIN_SHADE, Color(1, 0.95, 0.9))
	c.draw_colored_polygon(PackedVector2Array([head + Vector2(-14, -6), head + Vector2(6, -16), head + Vector2(14, -8), head + Vector2(-6, -2)]), HAIR)
	if dead:
		EnemyArt.ko_eye(c, head + Vector2(8, 0), 3.5, t)
	else:
		c.draw_circle(head + Vector2(8, 0), 3.0, Color.WHITE)
		c.draw_circle(head + Vector2(9, 0), 1.7, Color(0.95, 0.75, 0.2))
		c.draw_line(head + Vector2(5, 8), head + Vector2(11, 7), Color(0.6, 0.35, 0.3), 2.0)   # Calm smile
	var halo_c := head + Vector2(0, -24 + sin(t * 4.0) * 1.5)
	var halo := EnemyArt.ellipse_points(halo_c, 16, 5, 20)
	var halo_closed := halo.duplicate()
	halo_closed.append(halo[0])
	c.draw_polyline(halo_closed, EnemyArt.BLACK, 6.0, FighterArt.AA)
	c.draw_polyline(halo_closed, GOLD, 3.5, FighterArt.AA)
	c.draw_circle(halo_c, 20.0, Color(HOLY.r, HOLY.g, HOLY.b, 0.15))

	# Near arm (+ beam)
	var shoulder := chest + Vector2(14, -12)
	var hand := chest + Vector2(22, 28)
	if pose == "beam_tele":
		hand = chest + Vector2(30, -6)
		c.draw_circle(hand + Vector2(8, 0), 6.0 + 6.0 * clampf(pt / 0.35, 0.0, 1.0), Color(HOLY.r, HOLY.g, HOLY.b, 0.8))
	elif pose == "beam":
		hand = chest + Vector2(34, -4)
		var fade := 1.0 - clampf((pt - 0.2) / 0.12, 0.0, 1.0)
		var origin := Vector2(hand.x + 6.0, -92.0)              # Same height as the beam hitbox
		c.draw_rect(Rect2(origin.x, origin.y - 18.0, BEAM_LEN, 36.0), Color(HOLY.r, HOLY.g, HOLY.b, 0.25 * fade))
		FighterArt.beam_gradient(c, origin, BEAM_LEN, 11.0 * fade + 1.0, GOLD, Color.WHITE)
	elif pose == "heal_tele" or pose == "heal":
		hand = chest + Vector2(16, -40)
	EnemyArt.arm(c, shoulder, hand, 11.0, ARMOR, ARMOR_SHADE, Color.WHITE, SKIN)


static func _wing(c: CanvasItem, root: Vector2, flap: float, far: bool) -> void:
	var base := WING_SHADE if far else WING
	var pts := PackedVector2Array([root])
	for i in 6:
		var a := -2.6 + flap + float(i) * 0.22
		var len := 70.0 - float(i) * 6.0
		pts.append(root + Vector2.from_angle(a) * len + Vector2(-6, 0))
		pts.append(root + Vector2.from_angle(a + 0.11) * (len - 14.0))
	c.draw_colored_polygon(pts, base)
	FighterArt.outline(c, pts, 3.5)
	for i in 4:                                          # Feather lines
		var a := -2.5 + flap + float(i) * 0.3
		c.draw_line(root + Vector2.from_angle(a) * 14.0, root + Vector2.from_angle(a) * 46.0, WING_SHADE.darkened(0.15), 2.0)
