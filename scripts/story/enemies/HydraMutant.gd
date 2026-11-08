class_name HydraMutant
extends SimpleEnemy
## HYDRA-MUTANT (Story Mode, Colosseum 1): a bigger demon whose head is a long
## serpent HYDRA neck (two smaller heads sprout from its shoulders). Slow, tanky.
##
##   Bite    7 dmg, 3 s - the neck shoots forward: long reach
##   Crush  11 dmg, 8 s - rears up (long telegraph, armored) and crushes down in front:
##                        big hit + screen shake

const BITE_REACH := 190.0
const BITE_KB := Vector2(300, -160)
const CRUSH_KB := Vector2(460, -320)

const SCALE := Color(0.32, 0.50, 0.26)
const SCALE_SHADE := Color(0.18, 0.30, 0.15)
const SCALE_HI := Color(0.50, 0.70, 0.38)
const BELLY := Color(0.78, 0.66, 0.42)
const SKIN := Color(0.52, 0.16, 0.14)
const SKIN_SHADE := Color(0.32, 0.08, 0.08)
const SKIN_HI := Color(0.72, 0.30, 0.24)
const EYE := Color(1.0, 0.9, 0.2)


func _make_data() -> CharacterData:
	keep_min = 60.0
	keep_max = 200.0
	attack_chance = 0.5
	phase2_threshold = -1.0
	knockback_scale = 0.6
	return SimpleEnemy.make_data("Hydra-Mutant", 55, Vector2(100, 160), 160.0)


static func make_patterns() -> Array[EnemyPattern]:
	var list: Array[EnemyPattern] = []
	#                          id       name        cd    dmg  min   max    anim     tele  active rec   big    weights   armored
	list.append(EnemyPattern.make("bite", "BITE!", 3.0, 7, 0.0, 230.0, "bite", 0.45, 0.25, 0.50, true, [2.0, 2.0]))
	list.append(EnemyPattern.make("crush", "CRUSH!", 8.0, 11, 0.0, 170.0, "crush", 0.85, 0.20, 0.80, true, [1.2, 1.2], true))
	return list


func _on_respawn() -> void:
	super._on_respawn()
	knockback_scale = 0.6


func flavor_lines() -> Array[String]:
	return ["HSSSSSS...", "*three heads hiss*"]


func _attack(p: EnemyPattern) -> void:
	match p.id:
		"bite":
			hitbox.activate(make_hit(dmg(p), Vector2(facing * BITE_KB.x, BITE_KB.y), "hydra_bite"),
				Vector2(facing * (BITE_REACH * 0.5 + 50.0), -110.0), Vector2(BITE_REACH, 56))
		"crush":
			hit_in_radius(global_position + Vector2(facing * 90.0, -40.0), 110.0, dmg(p), CRUSH_KB, "hydra_crush")
			Effects.shake(self, 10.0)
			Effects.hit_sparks(self, global_position + Vector2(facing * 100.0, -10), 10, 1.3)
			SoundManager.play_sfx("explosion", -4.0)


# ============================================================
# ART (facing right, origin = feet, ~140 x 190)
# ============================================================
func draw_model_on(c: CanvasItem) -> void:
	draw_hydra(c, art_state())


static func draw_portrait(c: CanvasItem, t: float) -> void:
	draw_hydra(c, {"t": t, "pose": "idle"})


static func draw_hydra(c: CanvasItem, s: Dictionary) -> void:
	var t: float = s.get("t", 0.0)
	var pose: String = s.get("pose", "idle")
	var pt: float = s.get("pose_t", 0.0)
	var dead: bool = s.get("dead", false)

	EnemyArt.legs(c, s, -64.0, 18.0, 22.0, SKIN, SKIN_SHADE, SKIN_HI, SKIN_SHADE, 22.0)
	var chest := Vector2(-6, -110 + sin(t * 2.0) * 2.0)

	# Small side heads (shoulders), swaying
	for side in [-1.0, 1.0]:
		var root := chest + Vector2(side * 30.0, -26)
		var tip := root + Vector2(side * 18.0 + sin(t * 3.0 + side) * 4.0, -24)
		FighterArt.limb(c, root, tip, 10.0, SCALE_SHADE, SCALE_SHADE.darkened(0.2), SCALE)
		FighterArt.ball(c, tip, 8.0, SCALE, SCALE_SHADE, SCALE_HI)
		c.draw_circle(tip + Vector2(3, -2), 1.8, EYE)

	# Far arm (huge claw)
	EnemyArt.arm(c, chest + Vector2(-26, -14), chest + Vector2(-34, 40), 18.0, SKIN_SHADE, SKIN_SHADE.darkened(0.2), SKIN, SKIN_SHADE, 11.0)

	# Massive torso
	var torso := PackedVector2Array([chest + Vector2(-40, -30), chest + Vector2(40, -30), chest + Vector2(34, 50), chest + Vector2(-34, 50)])
	c.draw_polygon(torso, PackedColorArray([SKIN_HI, SKIN, SKIN_SHADE, SKIN_SHADE]))
	for i in 4:                                                 # Scale patches
		c.draw_circle(chest + Vector2(-20 + float(i) * 13.0, -16 + float(i % 2) * 10.0), 5.0, SCALE_SHADE)
	FighterArt.outline(c, torso, 4.5)

	# Main hydra neck + head (extends on bite, rears up on crush)
	var neck_root := chest + Vector2(22, -30)
	var head := neck_root + Vector2(40, -40) + Vector2(sin(t * 2.2) * 4.0, cos(t * 1.8) * 3.0)
	var jaw_open := 0.0
	match pose:
		"bite_tele":
			head = neck_root + Vector2(10, -56)
			jaw_open = clampf(pt / 0.45, 0.0, 1.0)
		"bite":
			var k := sin(PI * clampf(pt / 0.25, 0.0, 1.0))
			head = neck_root + Vector2(40 + 150.0 * k, 10.0 * k)
			jaw_open = 1.0 - k * 0.7
		"crush_tele":
			head = neck_root + Vector2(-6, -80 - 10.0 * clampf(pt / 0.85, 0.0, 1.0))
			jaw_open = 0.6
		"crush":
			head = neck_root + Vector2(80, 70)
	var mid := neck_root.lerp(head, 0.5) + Vector2(-12, -14)
	FighterArt.limb(c, neck_root, mid, 22.0, SCALE, SCALE_SHADE, SCALE_HI)
	FighterArt.limb(c, mid, head, 18.0, SCALE, SCALE_SHADE, SCALE_HI)
	c.draw_line(neck_root + Vector2(4, 6), mid + Vector2(4, 8), BELLY, 6.0)
	# Head: snake skull with jaws
	var upper := PackedVector2Array([head + Vector2(-14, -10), head + Vector2(10, -12), head + Vector2(30, -4).rotated(-0.3 * jaw_open), head + Vector2(26, 2).rotated(-0.3 * jaw_open), head + Vector2(-12, 4)])
	c.draw_colored_polygon(upper, SCALE)
	FighterArt.outline(c, upper, 3.0)
	var lower := PackedVector2Array([head + Vector2(-10, 4), head + Vector2(24, 4).rotated(0.5 * jaw_open), head + Vector2(20, 10).rotated(0.5 * jaw_open), head + Vector2(-8, 10)])
	c.draw_colored_polygon(lower, BELLY)
	FighterArt.outline(c, lower, 3.0)
	for k in 3:
		var fp := head + Vector2(12 + float(k) * 6.0, 2).rotated(-0.3 * jaw_open)
		c.draw_colored_polygon(PackedVector2Array([fp, fp + Vector2(2, 6), fp + Vector2(4, 0)]), Color.WHITE)
	# Spiky frill
	for k in 3:
		var fb := head + Vector2(-10 + float(k) * 6.0, -10)
		FighterArt.curved_spike(c, fb, fb + Vector2(-8, -14), 3.5, SCALE_SHADE, SCALE_HI, 0.3, 2.0)
	if dead:
		EnemyArt.ko_eye(c, head + Vector2(6, -5), 3.5, t)
	else:
		c.draw_circle(head + Vector2(6, -5), 4.0, EnemyArt.BLACK)
		c.draw_circle(head + Vector2(6, -5), 3.0, EYE)
		c.draw_line(head + Vector2(6, -8), head + Vector2(6, -2), EnemyArt.BLACK, 1.5)   # Slit pupil

	# Near arm (claw)
	var hand := chest + Vector2(38, 42)
	if pose == "crush_tele":
		hand = chest + Vector2(30, -50)
	elif pose == "crush":
		hand = Vector2(92, -16)
	EnemyArt.arm(c, chest + Vector2(28, -14), hand, 19.0, SKIN, SKIN_SHADE, SKIN_HI, SKIN, 12.0)
	for k in 3:
		c.draw_line(hand + Vector2(4, -4 + float(k) * 4.0), hand + Vector2(14, -6 + float(k) * 5.0), EnemyArt.BLACK, 3.0)
	if pose == "crush":
		c.draw_arc(Vector2(92, 0), 30.0 + pt * 220.0, PI, TAU, 18, Color(1, 0.8, 0.5, maxf(0.0, 1.0 - pt * 4.0)), 6.0, true)
