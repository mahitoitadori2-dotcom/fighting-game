class_name DemonBrute
extends SimpleEnemy
## DEMON BRUTE (Story Mode, Colosseum 1): horned demon with a BASALT SWORD
## (black volcanic stone, glowing lava veins).
##
##   Swing   6 dmg, 2.6 s - wide horizontal swing
##   Slam    9 dmg, 6 s   - raises the sword overhead (long telegraph), slams the ground:
##                          shockwave hits BOTH sides around him

const SWING_KB := Vector2(380, -200)
const SLAM_KB := Vector2(420, -340)
const SLAM_RADIUS := 130.0

const SKIN := Color(0.62, 0.14, 0.12)
const SKIN_SHADE := Color(0.40, 0.07, 0.07)
const SKIN_HI := Color(0.82, 0.30, 0.24)
const HORN := Color(0.20, 0.16, 0.14)
const BASALT := Color(0.12, 0.11, 0.12)
const LAVA := Color(1.0, 0.45, 0.08)
const LOIN := Color(0.22, 0.16, 0.12)


func _make_data() -> CharacterData:
	keep_min = 0.0
	keep_max = 120.0
	attack_chance = 0.55
	phase2_threshold = -1.0
	knockback_scale = 0.85
	return SimpleEnemy.make_data("Demon Brute", 28, Vector2(70, 130), 210.0)


static func make_patterns() -> Array[EnemyPattern]:
	var list: Array[EnemyPattern] = []
	#                          id       name       cd    dmg  min   max    anim     tele  active rec   big    weights
	list.append(EnemyPattern.make("swing", "SWING", 2.6, 6, 0.0, 125.0, "swing", 0.45, 0.15, 0.50, false, [2.0, 2.0]))
	list.append(EnemyPattern.make("slam", "SLAM!", 6.0, 9, 0.0, 150.0, "slam", 0.75, 0.20, 0.70, true, [1.0, 1.0], true))
	return list


func _on_respawn() -> void:
	super._on_respawn()
	knockback_scale = 0.85


func flavor_lines() -> Array[String]:
	return ["GRRAAH!", "FLESH!", "*snort*"]


func _attack(p: EnemyPattern) -> void:
	match p.id:
		"swing":
			hitbox.activate(make_hit(dmg(p), Vector2(facing * SWING_KB.x, SWING_KB.y), "brute_swing"),
				Vector2(facing * 62.0, -70.0), Vector2(96, 70))
			velocity.x += facing * 140.0
			SoundManager.play_sfx("sword_slash", -3.0)
		"slam":
			hit_in_radius(global_position + Vector2(facing * 40.0, -30.0), SLAM_RADIUS, dmg(p), SLAM_KB, "brute_slam")
			Effects.shake(self, 8.0)
			Effects.hit_sparks(self, global_position + Vector2(facing * 60.0, -6), 8, 1.1)
			SoundManager.play_sfx("explosion", -6.0)
			for side in [-1.0, 1.0]:
				var w := spawn_projectile()
				w.look = "shock"
				w.harmless = true
				w.tint = LAVA
				w.dir = side
				w.speed = 420.0
				w.lifetime = 0.35
				launch(w, global_position + Vector2(facing * 50.0 + side * 20.0, 0))


# ============================================================
# ART (facing right, origin = feet, ~90 x 150)
# ============================================================
func draw_model_on(c: CanvasItem) -> void:
	draw_brute(c, art_state())


static func draw_portrait(c: CanvasItem, t: float) -> void:
	draw_brute(c, {"t": t, "pose": "idle"})


static func draw_brute(c: CanvasItem, s: Dictionary) -> void:
	var t: float = s.get("t", 0.0)
	var pose: String = s.get("pose", "idle")
	var pt: float = s.get("pose_t", 0.0)
	var dead: bool = s.get("dead", false)
	var breathe := sin(t * 2.5) * 1.5
	var crouch := 10.0 if pose == "slam_tele" else 0.0

	EnemyArt.legs(c, s, -56.0 + crouch, 13.0, 17.0, SKIN, SKIN_SHADE, SKIN_HI, HORN, 18.0)
	var chest := Vector2(0, -94 + crouch + breathe)

	# Tail
	c.draw_polyline(PackedVector2Array([chest + Vector2(-20, 34), chest + Vector2(-40, 44), chest + Vector2(-50, 30 + sin(t * 3.0) * 6.0)]), EnemyArt.BLACK, 7.0, true)
	c.draw_polyline(PackedVector2Array([chest + Vector2(-20, 34), chest + Vector2(-40, 44), chest + Vector2(-50, 30 + sin(t * 3.0) * 6.0)]), SKIN_SHADE, 4.0, true)

	# Far arm
	EnemyArt.arm(c, chest + Vector2(-18, -12), chest + Vector2(-24, 28), 14.0, SKIN_SHADE, SKIN_SHADE.darkened(0.2), SKIN, SKIN_SHADE, 8.0)

	# Loincloth + hulking torso
	var hip := Vector2(0, -56 + crouch)
	var loin := PackedVector2Array([hip + Vector2(-24, -8), hip + Vector2(24, -8), hip + Vector2(18, 18), hip + Vector2(-20, 18)])
	c.draw_colored_polygon(loin, LOIN)
	FighterArt.outline(c, loin, 3.5)
	var torso := PackedVector2Array([chest + Vector2(-30, -22), chest + Vector2(30, -22), chest + Vector2(24, 34), chest + Vector2(-24, 34)])
	c.draw_polygon(torso, PackedColorArray([SKIN_HI, SKIN, SKIN_SHADE, SKIN_SHADE]))
	c.draw_arc(chest + Vector2(-10, -6), 11.0, 0.3, 2.8, 8, SKIN_SHADE, 2.5)
	c.draw_arc(chest + Vector2(11, -6), 11.0, 0.3, 2.8, 8, SKIN_SHADE, 2.5)
	for i in 3:
		c.draw_line(chest + Vector2(-8, 8 + float(i) * 8.0), chest + Vector2(8, 8 + float(i) * 8.0), SKIN_SHADE, 2.0)
	FighterArt.outline(c, torso, 4.0)

	# Head: horns, glowing eyes, fangs
	var head := chest + Vector2(8, -38)
	for side in [-1.0, 1.0]:
		var hb := head + Vector2(side * 9.0 - 2.0, -10)
		FighterArt.curved_spike(c, hb, hb + Vector2(side * 16.0 - 6.0, -22), 5.0, HORN, Color(0.55, 0.5, 0.45), 0.4, 2.5)
	FighterArt.ball(c, head, 16.0, SKIN, SKIN_SHADE, SKIN_HI)
	c.draw_colored_polygon(PackedVector2Array([head + Vector2(4, 8), head + Vector2(18, 6), head + Vector2(16, 14), head + Vector2(6, 15)]), SKIN_SHADE)   # Jaw
	c.draw_colored_polygon(PackedVector2Array([head + Vector2(8, 8), head + Vector2(10, 14), head + Vector2(12, 8)]), Color.WHITE)
	c.draw_colored_polygon(PackedVector2Array([head + Vector2(14, 7), head + Vector2(15, 12), head + Vector2(17, 7)]), Color.WHITE)
	if dead:
		EnemyArt.ko_eye(c, head + Vector2(8, -3), 3.5, t)
	else:
		c.draw_circle(head + Vector2(9, -3), 5.0, Color(LAVA.r, LAVA.g, LAVA.b, 0.35))
		c.draw_circle(head + Vector2(9, -3), 3.0, Color(1.0, 0.85, 0.2))
		c.draw_line(head + Vector2(2, -9), head + Vector2(15, -6), EnemyArt.BLACK, 3.5)

	# Near arm + basalt sword
	var shoulder := chest + Vector2(18, -12)
	var hand := chest + Vector2(30, 24)
	var ang := -0.6
	match pose:
		"swing_tele":
			hand = chest + Vector2(-16, -14)
			ang = -2.6
		"swing":
			hand = chest + Vector2(48, 0)
			ang = 0.1
		"slam_tele":
			hand = chest + Vector2(6, -60)
			ang = -1.75
		"slam":
			hand = Vector2(54, -24)
			ang = 1.2
	_sword(c, hand, ang, t)
	EnemyArt.arm(c, shoulder, hand, 15.0, SKIN, SKIN_SHADE, SKIN_HI, SKIN, 8.5)
	if pose == "swing":
		c.draw_arc(chest + Vector2(16, 0), 72.0, -1.3, 0.9, 14, Color(1.0, 0.6, 0.2, maxf(0.0, 0.8 - pt * 5.0)), 7.0, true)
	if pose == "slam":
		c.draw_arc(Vector2(60, 0), 30.0 + pt * 200.0, PI, TAU, 18, Color(LAVA.r, LAVA.g, LAVA.b, maxf(0.0, 1.0 - pt * 4.0)), 6.0, true)


static func _sword(c: CanvasItem, hand: Vector2, angle: float, t: float) -> void:
	var d := Vector2.from_angle(angle)
	var n := d.orthogonal()
	var guard := hand + d * 8.0
	var tip := hand + d * 78.0
	var blade := PackedVector2Array([guard + n * 7.0, tip + n * 2.0, tip + d * 8.0, tip - n * 3.0, guard - n * 7.0])
	c.draw_colored_polygon(blade, BASALT)
	FighterArt.outline(c, blade, 3.0)
	var glow := 0.6 + 0.4 * sin(t * 4.0)
	c.draw_polyline(PackedVector2Array([guard + d * 6.0, guard + d * 26.0 + n * 3.0, guard + d * 44.0 - n * 2.0, guard + d * 64.0 + n * 1.0]), Color(LAVA.r, LAVA.g, LAVA.b, glow), 2.5, true)
	c.draw_line(hand - n * 12.0, hand + n * 12.0, EnemyArt.BLACK, 7.0)
	c.draw_line(hand - n * 11.0, hand + n * 11.0, Color(0.35, 0.3, 0.3), 4.0)
	c.draw_line(hand - d * 12.0, hand, EnemyArt.BLACK, 6.0)
