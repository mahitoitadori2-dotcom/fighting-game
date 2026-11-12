class_name EnlightenedFollower
extends SimpleEnemy
## ENLIGHTENED FOLLOWER (Story Mode, Colosseum 2 - Home of the Enlightened Ones): a hooded
## acolyte in white robes with a blank golden mask and a halo. Stays BEHIND the guards and
## sends rings of light at you; up close it pushes you away with a radiant palm.
##
##   Halo Wave      4 dmg, 2.6 s - a ring of golden light that flies across the arena
##   Radiant Palm   3 dmg, 1.6 s - a short burst of light from the palm

const WAVE_KB := Vector2(220, -150)
const PALM_KB := Vector2(320, -180)

const ROBE := Color(0.95, 0.94, 0.90)
const ROBE_SHADE := Color(0.72, 0.70, 0.66)
const ROBE_HI := Color(1.0, 1.0, 1.0)
const GOLD := Color(0.95, 0.75, 0.25)
const GOLD_SHADE := Color(0.65, 0.45, 0.10)
const GLOW := Color(1.0, 0.92, 0.55)


func _make_data() -> CharacterData:
	keep_min = 220.0
	keep_max = 420.0
	attack_chance = 0.55
	phase2_threshold = -1.0
	return SimpleEnemy.make_data("Enlightened Follower", 16, Vector2(54, 120), 170.0)


static func make_patterns() -> Array[EnemyPattern]:
	var list: Array[EnemyPattern] = []
	#                          id      name            cd    dmg  min    max    anim    tele  active rec   big    weights
	list.append(EnemyPattern.make("halo", "HALO WAVE", 2.6, 4, 140.0, 650.0, "halo", 0.50, 0.20, 0.50, false, [2.0, 2.0]))
	list.append(EnemyPattern.make("palm", "RADIANT PALM", 1.6, 3, 0.0, 85.0, "palm", 0.20, 0.12, 0.35, false, [1.5, 1.5]))
	return list


func flavor_lines() -> Array[String]:
	return ["~ Glory to the Light ~", "You are not enlightened.", "~ hmmmmm ~"]


func _attack(p: EnemyPattern) -> void:
	match p.id:
		"halo":
			var w := spawn_projectile()
			w.kind = EnemyProjectile.Kind.LINEAR
			w.look = "croak"
			w.tint = GLOW
			w.dir = float(facing)
			w.speed = 430.0
			w.lifetime = 1.5
			w.size = Vector2(50, 70)
			w.damage = dmg(p)
			w.knockback = WAVE_KB
			w.pierce = false
			w.move = "halo_wave"
			launch(w, global_position + Vector2(facing * 40.0, -70.0))
			SoundManager.play_sfx("holy", -8.0)
		"palm":
			hitbox.activate(make_hit(dmg(p), Vector2(facing * PALM_KB.x, PALM_KB.y), "radiant_palm"),
				Vector2(facing * 44.0, -70.0), Vector2(56, 70))
			Effects.gold_burst(self, global_position + Vector2(facing * 48.0, -70.0), 34.0)
			SoundManager.play_sfx("holy", -9.0)


# ============================================================
# ART (facing right, origin = feet, ~70 x 150)
# ============================================================
func draw_model_on(c: CanvasItem) -> void:
	draw_follower(c, art_state())


static func draw_portrait(c: CanvasItem, t: float) -> void:
	draw_follower(c, {"t": t, "pose": "idle"})


static func draw_follower(c: CanvasItem, s: Dictionary) -> void:
	var t: float = s.get("t", 0.0)
	var pose: String = s.get("pose", "idle")
	var pt: float = s.get("pose_t", 0.0)
	var dead: bool = s.get("dead", false)
	var float_y := sin(t * 2.2) * 2.5
	var head := Vector2(4, -112 + float_y)
	EnemyArt.aura(c, head + Vector2(0, 30), 34.0, GLOW, t)

	# Long robe that hides the feet (sways)
	var sway := sin(t * 2.0) * 3.0
	var robe := PackedVector2Array([head + Vector2(-16, 10), head + Vector2(16, 10), Vector2(24 + sway, -4), Vector2(14, 0),
		Vector2(4 + sway, -4), Vector2(-6, 0), Vector2(-18 + sway, -4), Vector2(-26, -2)])
	var cols := PackedColorArray()
	for p in robe:
		cols.append(ROBE_HI.lerp(ROBE_SHADE, clampf((p.y - head.y) / 112.0, 0.0, 1.0)))
	c.draw_polygon(robe, cols)
	c.draw_line(Vector2(-22, -10), Vector2(22, -10), GOLD, 3.0)                     # Gold hem
	c.draw_line(head + Vector2(0, 14), Vector2(0, -12), GOLD, 3.0)                    # Gold stole
	FighterArt.outline(c, robe, 3.5)

	# Hands: praying, raised for the wave, thrust for the palm
	var l_hand := head + Vector2(10, 46)
	var r_hand := head + Vector2(16, 44)
	match pose:
		"halo_tele":
			l_hand = head + Vector2(-6, -16)
			r_hand = head + Vector2(14, -18)
		"halo":
			l_hand = head + Vector2(28, 18)
			r_hand = head + Vector2(34, 22)
		"palm_tele":
			r_hand = head + Vector2(0, 40)
		"palm":
			r_hand = head + Vector2(42, 42)
	EnemyArt.arm(c, head + Vector2(-8, 24), l_hand, 7.0, ROBE_SHADE, ROBE_SHADE.darkened(0.2), ROBE, Color(0.95, 0.85, 0.7), 5.0)
	EnemyArt.arm(c, head + Vector2(10, 24), r_hand, 7.0, ROBE, ROBE_SHADE, ROBE_HI, Color(0.95, 0.85, 0.7), 5.0)
	if pose == "halo_tele":                                                            # Light gathering overhead
		c.draw_circle(head + Vector2(4, -26), 10.0 + pt * 18.0, Color(GLOW.r, GLOW.g, GLOW.b, 0.5))
	if pose == "palm" and pt < 0.2:
		c.draw_circle(r_hand + Vector2(10, 0), 16.0, Color(1, 1, 0.8, 0.7))

	# Hood + blank golden mask
	var hood := PackedVector2Array([head + Vector2(-20, 14), head + Vector2(-20, -10), head + Vector2(-4, -22), head + Vector2(14, -18), head + Vector2(22, 0), head + Vector2(16, 16)])
	c.draw_colored_polygon(hood, ROBE)
	FighterArt.outline(c, hood, 3.0)
	var mask := EnemyArt.ellipse_points(head + Vector2(6, 0), 10.0, 13.0, 16)
	c.draw_colored_polygon(mask, GOLD)
	FighterArt.outline(c, mask, 2.5)
	if dead:
		EnemyArt.ko_eye(c, head + Vector2(9, -3), 2.6, t)
	else:
		for ex in [3.0, 11.0]:
			c.draw_circle(head + Vector2(ex, -3), 2.6, Color(1, 1, 0.9))
	c.draw_line(head + Vector2(3, 6), head + Vector2(11, 6), GOLD_SHADE, 1.5)

	# Halo
	c.draw_set_transform(head + Vector2(0, -26), 0.0, Vector2(1.0, 0.3))
	c.draw_arc(Vector2.ZERO, 16.0, 0.0, TAU, 24, Color(GLOW.r, GLOW.g, GLOW.b, 0.4), 8.0, FighterArt.AA)
	c.draw_arc(Vector2.ZERO, 16.0, 0.0, TAU, 24, GOLD, 3.0, FighterArt.AA)
	c.draw_set_transform(Vector2.ZERO, 0.0, Vector2.ONE)
