class_name FrostJarl
extends SimpleEnemy
## FROST JARL HRIMGAR: bald northern berserker, blue rune tattoos, braided beard,
## fur mantle and a frost-runed axe. PvE enemy (BaseEnemy + EnemyPattern + EnemyHUD).
## TANKY: 70 HP and 20% knockback resistance.
## (An original character standing in for the requested "Kratos", which belongs to
##  the God of War series: same role and moves, original look and name.)
##
##   Axe Throw    8 dmg, 7 s  - throws the axe forward, it comes back like a boomerang
##   Rage Punch  10 dmg, 10 s - heavy armored punch with big knockback
##   Frost Slam   7 dmg, 12 s - slams the axe into the ground: frost waves both ways (slows)

const AXE_KB := Vector2(260, -150)
const PUNCH_KB := Vector2(720, -380)
const FROST_KB := Vector2(260, -220)

const SKIN := Color(0.86, 0.80, 0.72)
const SKIN_SHADE := Color(0.66, 0.58, 0.50)
const SKIN_HI := Color(0.96, 0.92, 0.86)
const RUNE := Color(0.25, 0.60, 1.0)
const BEARD := Color(0.36, 0.22, 0.12)
const FUR := Color(0.50, 0.42, 0.34)
const FUR_SHADE := Color(0.34, 0.27, 0.20)
const LEATHER := Color(0.36, 0.24, 0.16)
const LEATHER_SHADE := Color(0.22, 0.14, 0.09)
const ICE := Color(0.72, 0.90, 1.0)

var axe_in_hand := true


func _make_data() -> CharacterData:
	keep_min = 0.0
	keep_max = 140.0
	attack_chance = 0.55
	knockback_scale = 0.8
	return SimpleEnemy.make_data("Frost Jarl", EnemyManager.TANK_HP, Vector2(64, 132), 300.0)


static func make_patterns() -> Array[EnemyPattern]:
	var list: Array[EnemyPattern] = []
	#                          id            name           cd    dmg  min    max    anim     tele  active rec   big   weights   armored
	list.append(EnemyPattern.make("axe_throw", "AXE THROW!", 7.0, 8, 130.0, 620.0, "throw", 0.35, 0.20, 0.30, true, [1.4, 1.4]))
	list.append(EnemyPattern.make("rage_punch", "RAGE PUNCH!", 10.0, 10, 0.0, 115.0, "punch", 0.45, 0.15, 0.45, true, [1.6, 1.8], true))
	list.append(EnemyPattern.make("frost_slam", "FROST SLAM!", 12.0, 7, 0.0, 480.0, "slam", 0.50, 0.20, 0.50, true, [1.0, 1.3]))
	list[0].note = "boomerang, can hit twice"
	list[1].note = "armored, huge knockback"
	list[2].note = "waves both ways, slows"
	return list


func wants_pattern(p: EnemyPattern) -> bool:
	return axe_in_hand or p.id == "rage_punch"      # No axe = only fists until it comes back


func flavor_lines() -> Array[String]:
	return ["HRAAA!", "FOR THE NORTH!", "BOY..."]


func on_projectile_returned(look: String) -> void:
	if look == "axe":
		axe_in_hand = true
		Effects.hit_sparks(self, global_position + Vector2(facing * 30.0, -84), 4, 0.6)


func _on_respawn() -> void:
	super._on_respawn()
	axe_in_hand = true
	knockback_scale = 0.8                          # Fighter.respawn() resets it to 1.0


func _attack(p: EnemyPattern) -> void:
	match p.id:
		"axe_throw":
			var a := spawn_projectile()
			a.kind = EnemyProjectile.Kind.BOOMERANG
			a.look = "axe"
			a.damage = dmg(p)
			a.knockback = AXE_KB
			a.dir = float(facing)
			a.speed = 720.0
			a.range_px = 420.0
			a.lifetime = 2.4
			a.size = Vector2(46, 46)
			a.move = "axe_throw"
			launch(a, global_position + Vector2(facing * 40.0, -86.0))
			axe_in_hand = false
		"rage_punch":
			hitbox.activate(make_hit(dmg(p), Vector2(facing * PUNCH_KB.x, PUNCH_KB.y), "rage_punch"),
				Vector2(facing * 58.0, -82.0), Vector2(74, 52))
			velocity.x += facing * 360.0
			Effects.shake(self, 4.0)
		"frost_slam":
			Effects.shake(self, 7.0)
			Effects.hit_sparks(self, global_position + Vector2(facing * 50.0, -6), 8, 1.0)
			for side in [-1.0, 1.0]:
				var w := spawn_projectile()
				w.look = "frost"
				w.damage = dmg(p)
				w.knockback = FROST_KB
				w.dir = side
				w.speed = 560.0
				w.lifetime = 0.8
				w.size = Vector2(40, 52)
				w.move = "frost_slam"
				w.on_hit = _frost_slow
				launch(w, global_position + Vector2(side * 50.0, -26.0))


func _frost_slow(victim: Fighter) -> void:
	if is_instance_valid(victim) and not victim.is_dead:
		victim.apply_goo(1.2, 0.6, 0.0)               # Reuses the SLOW status (icon + speed)
		Effects.popup(victim, victim.global_position + Vector2(0, -170), "FROZEN!", ICE, 20)


# ============================================================
# ART (facing right, origin = feet, ~70 x 140)
# ============================================================
func draw_model_on(c: CanvasItem) -> void:
	var s := art_state()
	s["axe"] = axe_in_hand
	draw_jarl(c, s)


static func draw_portrait(c: CanvasItem, t: float) -> void:
	draw_jarl(c, {"t": t, "pose": "idle", "axe": true})


static func draw_jarl(c: CanvasItem, s: Dictionary) -> void:
	var t: float = s.get("t", 0.0)
	var pose: String = s.get("pose", "idle")
	var pt: float = s.get("pose_t", 0.0)
	var dead: bool = s.get("dead", false)
	var has_axe: bool = s.get("axe", true)

	if s.get("enraged", false):
		EnemyArt.aura(c, Vector2(0, -70), 70.0, RUNE, t)

	var breathe := sin(t * 3.0) * 1.5
	var crouch := 8.0 if pose == "slam_tele" or pose == "punch_tele" else 0.0

	# Legs (leather trousers, fur boots)
	EnemyArt.legs(c, s, -58.0 + crouch, 11.0, 15.0, LEATHER, LEATHER_SHADE, LEATHER.lightened(0.2), FUR_SHADE, 18.0)

	var hip := Vector2(0, -60 + crouch)
	var chest := Vector2(2, -98 + crouch + breathe)

	# Far arm (fist)
	var far_hand := chest + Vector2(-24, 30)
	EnemyArt.arm(c, chest + Vector2(-14, -10), far_hand, 13.0, SKIN_SHADE, SKIN_SHADE.darkened(0.15), SKIN, SKIN_SHADE)

	# Kilt of leather straps
	var kilt := PackedVector2Array([hip + Vector2(-22, -8), hip + Vector2(22, -8), hip + Vector2(26, 14), hip + Vector2(-26, 14)])
	c.draw_colored_polygon(kilt, LEATHER)
	for i in 4:
		c.draw_line(hip + Vector2(-16 + float(i) * 11.0, -6), hip + Vector2(-18 + float(i) * 12.0, 14), LEATHER_SHADE, 2.0)
	FighterArt.outline(c, kilt, 3.5)

	# Bare muscular torso
	var torso := PackedVector2Array([chest + Vector2(-24, -18), chest + Vector2(24, -18), chest + Vector2(20, 30), chest + Vector2(-20, 30)])
	var tcols := PackedColorArray([SKIN_HI, SKIN, SKIN_SHADE, SKIN_SHADE])
	c.draw_polygon(torso, tcols)
	c.draw_line(chest + Vector2(0, -8), chest + Vector2(0, 26), SKIN_SHADE, 2.0)          # Abs line
	c.draw_arc(chest + Vector2(-8, -2), 9.0, 0.3, 2.8, 8, SKIN_SHADE, 2.0)
	c.draw_arc(chest + Vector2(9, -2), 9.0, 0.3, 2.8, 8, SKIN_SHADE, 2.0)
	# Blue rune tattoo down the near side
	c.draw_polyline(PackedVector2Array([chest + Vector2(14, -16), chest + Vector2(10, -4), chest + Vector2(16, 6), chest + Vector2(11, 18)]), RUNE, 3.0, FighterArt.AA)
	c.draw_line(chest + Vector2(8, -2), chest + Vector2(16, -6), RUNE, 2.0)
	FighterArt.outline(c, torso, 4.0)
	# Belt
	FighterArt.rrect(c, Rect2(hip.x - 23, hip.y - 14, 46, 9), LEATHER_SHADE, LEATHER_SHADE.darkened(0.3), LEATHER, 3.0, 3.0)
	c.draw_circle(hip + Vector2(0, -9.5), 4.5, Color(0.75, 0.75, 0.8))

	# Fur mantle on the shoulders
	var mantle := PackedVector2Array([chest + Vector2(-30, -14), chest + Vector2(-20, -26), chest + Vector2(0, -28),
		chest + Vector2(20, -26), chest + Vector2(30, -14), chest + Vector2(18, -8), chest + Vector2(-18, -8)])
	c.draw_colored_polygon(mantle, FUR)
	for i in 5:
		c.draw_line(chest + Vector2(-22 + float(i) * 11.0, -24), chest + Vector2(-24 + float(i) * 11.0, -10), FUR_SHADE, 2.0)
	FighterArt.outline(c, mantle, 3.5)

	# Head: bald, scowl, braided beard
	var head := chest + Vector2(6, -42)
	FighterArt.ball(c, head, 15.0, SKIN, SKIN_SHADE, SKIN_HI)
	c.draw_polyline(PackedVector2Array([head + Vector2(-10, -12), head + Vector2(-4, -2), head + Vector2(-8, 6)]), RUNE, 2.5, FighterArt.AA)   # Head rune
	var beard := PackedVector2Array([head + Vector2(-6, 2), head + Vector2(16, 2), head + Vector2(13, 20), head + Vector2(6, 30), head + Vector2(0, 20)])
	c.draw_colored_polygon(beard, BEARD)
	FighterArt.outline(c, beard, 3.0)
	c.draw_line(head + Vector2(6, 22), head + Vector2(6, 32), BEARD, 5.0)                  # Braid
	c.draw_circle(head + Vector2(6, 26), 2.5, Color(0.75, 0.75, 0.8))                      # Braid ring
	if dead:
		EnemyArt.ko_eye(c, head + Vector2(7, -3), 3.5, t)
	else:
		c.draw_circle(head + Vector2(8, -3), 3.0, Color.WHITE)
		c.draw_circle(head + Vector2(9, -3), 1.6, Color(0.2, 0.45, 0.9))
		c.draw_line(head + Vector2(1, -9), head + Vector2(13, -6), EnemyArt.BLACK, 3.5)     # Angry brow

	# Near arm + axe (or empty fist while the axe is flying)
	var shoulder := chest + Vector2(16, -12)
	var hand := chest + Vector2(30, 22)
	var axe_angle := -1.2
	match pose:
		"throw_tele":
			hand = chest + Vector2(-22, -30)
			axe_angle = -2.4
		"throw":
			hand = chest + Vector2(40, -6)
		"punch_tele":
			hand = chest + Vector2(-6, 6)
		"punch":
			hand = chest + Vector2(54, -2)
		"slam_tele":
			hand = chest + Vector2(6, -48)
			axe_angle = -2.0
		"slam":
			hand = Vector2(46, -20)
			axe_angle = 0.9
	if has_axe and pose != "punch" and pose != "punch_tele":
		_axe(c, hand, axe_angle)
	EnemyArt.arm(c, shoulder, hand, 14.0, SKIN, SKIN_SHADE, SKIN_HI, SKIN, 8.0 if pose == "punch" else 7.0)
	if pose == "punch":
		c.draw_arc(hand, 16.0, -1.2, 1.2, 10, Color(1, 1, 1, 0.7), 4.0, FighterArt.AA)
	if pose == "slam":
		c.draw_arc(Vector2(46, -2), 30.0 + pt * 80.0, PI, TAU, 16, Color(ICE.r, ICE.g, ICE.b, maxf(0.0, 1.0 - pt * 4.0)), 6.0, FighterArt.AA)


static func _axe(c: CanvasItem, hand: Vector2, angle: float) -> void:
	var d := Vector2.from_angle(angle)
	var top := hand + d * 34.0
	var bottom := hand - d * 12.0
	c.draw_line(bottom, top, EnemyArt.BLACK, 8.0)
	c.draw_line(bottom, top, Color(0.45, 0.28, 0.14), 5.0)
	var n := d.orthogonal()
	var blade := PackedVector2Array([top - d * 4.0, top + n * 18.0 - d * 6.0, top + n * 22.0 + d * 8.0, top + n * 10.0 + d * 10.0, top + d * 6.0])
	c.draw_colored_polygon(blade, ICE)
	FighterArt.outline(c, blade, 3.0)
	c.draw_line(top + n * 18.0 - d * 4.0, top + n * 21.0 + d * 6.0, Color.WHITE, 2.0)
	c.draw_circle(top + n * 8.0, 2.5, RUNE)
