class_name GodCrawler
extends SimpleEnemy
## GOD CRAWLER (Story Mode, Colosseum 2 - the Sewers): the remains of a fallen god, still
## crawling. A pale, swollen body dragged on six long human arms, a cracked golden halo
## hanging crooked over a face that is mostly MOUTH. SLOW, but its bite is brutal.
##
##   Devouring Bite   10 dmg, 3.4 s - BIG telegraph: rears up, jaws open wide, then CHOMP
##   Claw             4 dmg, 1.8 s  - a quick swipe with a front hand

const BITE_KB := Vector2(380, -260)
const CLAW_KB := Vector2(200, -110)

const SKIN := Color(0.80, 0.76, 0.66)
const SKIN_SHADE := Color(0.55, 0.50, 0.42)
const SKIN_HI := Color(0.94, 0.91, 0.84)
const BRUISE := Color(0.45, 0.42, 0.48)
const MAW := Color(0.25, 0.03, 0.05)
const TOOTH := Color(0.98, 0.95, 0.80)
const HALO := Color(1.0, 0.82, 0.3)


func _make_data() -> CharacterData:
	keep_min = 0.0
	keep_max = 110.0
	attack_chance = 0.65
	phase2_threshold = -1.0
	knockback_scale = 0.6                         # Heavy: barely pushed around
	var d := SimpleEnemy.make_data("God Crawler", 36, Vector2(120, 72), 85.0)
	d.hitstun_time = 0.14
	d.respawn_delay = 1.4
	return d


static func make_patterns() -> Array[EnemyPattern]:
	var list: Array[EnemyPattern] = []
	#                          id        name                cd    dmg  min   max    anim      tele  active rec   big   weights
	list.append(EnemyPattern.make("devour", "DEVOURING BITE!", 3.4, 10, 0.0, 150.0, "devour", 0.75, 0.20, 0.70, true, [2.0, 2.0]))
	list.append(EnemyPattern.make("claw", "CLAW", 1.8, 4, 0.0, 110.0, "claw", 0.30, 0.15, 0.40, false, [1.2, 1.2]))
	return list


func _on_respawn() -> void:
	super._on_respawn()
	knockback_scale = 0.6


func flavor_lines() -> Array[String]:
	return ["...hungry...", "*wet crawling*", "...pray to me..."]


func _attack(p: EnemyPattern) -> void:
	match p.id:
		"devour":
			hitbox.activate(make_hit(dmg(p), Vector2(facing * BITE_KB.x, BITE_KB.y), "crawler_bite"),
				Vector2(facing * 80.0, -40.0), Vector2(110, 80))
			velocity.x = facing * 260.0                   # Lurches forward
			Effects.shake(self, 6.0)
			SoundManager.play_sfx("bite", -1.0)
		"claw":
			hitbox.activate(make_hit(dmg(p), Vector2(facing * CLAW_KB.x, CLAW_KB.y), "crawler_claw"),
				Vector2(facing * 70.0, -30.0), Vector2(70, 50))
			SoundManager.play_sfx("swing", -6.0)


# ============================================================
# ART (facing right, origin = feet, ~140 x 90)
# ============================================================
func draw_model_on(c: CanvasItem) -> void:
	draw_crawler(c, art_state())


static func draw_portrait(c: CanvasItem, t: float) -> void:
	draw_crawler(c, {"t": t, "pose": "idle"})


static func draw_crawler(c: CanvasItem, s: Dictionary) -> void:
	var t: float = s.get("t", 0.0)
	var pose_v: String = s.get("pose", "idle")
	var pt: float = s.get("pose_t", 0.0)
	var dead: bool = s.get("dead", false)
	var ph: float = s.get("walk", 0.0) * 1.2
	var moving: bool = s.get("moving", false)
	var rear := 0.0                                         # Head lifted while winding up the bite
	if pose_v == "devour_tele":
		rear = clampf(pt / 0.75, 0.0, 1.0)
	var breath := sin(t * 2.0) * 2.0

	# Six long human arms dragging the body (3 per side; far side darker)
	for i in 6:
		var far := i % 2 == 0
		var k := floorf(float(i) * 0.5)
		var shoulder := Vector2(-34 + k * 30.0, -44)
		var reach := sin(ph + k * 2.1 + (PI if far else 0.0)) * (14.0 if moving else 3.0)
		var hand := Vector2(shoulder.x + 18.0 + reach, -3.0)
		if pose_v == "claw" and i == 5:
			hand = Vector2(96, -30)                         # Swipe
		var elbow := Vector2((shoulder.x + hand.x) * 0.5 + 6.0, -62.0 + absf(reach) * 0.5)
		var col := SKIN_SHADE if far else SKIN
		FighterArt.limb(c, shoulder, elbow, 7.0, col, SKIN_SHADE, SKIN_HI)
		FighterArt.limb(c, elbow, hand, 6.0, col, SKIN_SHADE, SKIN_HI)
		c.draw_circle(hand, 5.5, col.darkened(0.15))
		for f in 3:                                          # Long fingers
			c.draw_line(hand, hand + Vector2(6.0 + float(f) * 2.0, 2.0 - float(f) * 2.0), col.darkened(0.25), 2.0)

	# Swollen pale body
	var body := EnemyArt.ellipse_points(Vector2(-10, -46 + breath), 54.0, 26.0 + breath * 0.5, 24)
	c.draw_colored_polygon(body, SKIN)
	c.draw_colored_polygon(EnemyArt.ellipse_points(Vector2(-14, -56 + breath), 40.0, 11.0, 16), SKIN_HI)
	for b in [Vector3(-30, -40, 9), Vector3(4, -34, 7), Vector3(-44, -52, 6)]:        # Bruises / decay
		c.draw_colored_polygon(EnemyArt.ellipse_points(Vector2(b.x, b.y + breath), b.z, b.z * 0.6, 10), BRUISE)
	for k in 5:                                                                        # Spine ridges
		c.draw_circle(Vector2(-48 + float(k) * 16.0, -70 + breath + absf(float(k) - 2.0) * 2.0), 4.0, SKIN_SHADE)
	FighterArt.outline(c, body, 4.0)

	# Head: big round face that is mostly mouth, many small eyes
	var head := Vector2(44, -52 - rear * 30.0 + breath)
	FighterArt.ball(c, head, 24.0, SKIN, SKIN_SHADE, SKIN_HI)
	var open := 0.15
	if pose_v == "devour_tele":
		open = 0.3 + 0.7 * rear
	elif pose_v == "devour":
		open = maxf(0.0, 1.0 - pt * 6.0)                    # Snaps shut
	elif pose_v == "claw_tele":
		open = 0.35
	var maw := EnemyArt.ellipse_points(head + Vector2(10, 6), 16.0, 4.0 + 16.0 * open, 16)
	c.draw_colored_polygon(maw, MAW)
	FighterArt.outline(c, maw, 2.5)
	for k in 6:                                                                        # Rows of teeth
		var tx := head.x - 2.0 + float(k) * 5.0
		var top_y := head.y + 6.0 - (4.0 + 16.0 * open) + 1.0
		var bot_y := head.y + 6.0 + (4.0 + 16.0 * open) - 1.0
		c.draw_colored_polygon(PackedVector2Array([Vector2(tx - 2, top_y), Vector2(tx + 2, top_y), Vector2(tx, top_y + 6)]), TOOTH)
		c.draw_colored_polygon(PackedVector2Array([Vector2(tx - 2, bot_y), Vector2(tx + 2, bot_y), Vector2(tx, bot_y - 6)]), TOOTH)
	for e in [Vector2(-8, -14), Vector2(2, -18), Vector2(12, -15), Vector2(-14, -4), Vector2(20, -8)]:
		if dead:
			EnemyArt.ko_eye(c, head + e, 2.6, t)
		else:
			c.draw_circle(head + e, 3.2, EnemyArt.BLACK)
			c.draw_circle(head + e, 2.2, HALO)

	# Cracked golden halo, hanging crooked
	var hc := head + Vector2(-4, -34)
	c.draw_set_transform(hc, -0.35 + sin(t * 1.5) * 0.08, Vector2(1.0, 0.32))
	c.draw_arc(Vector2.ZERO, 24.0, 0.3, TAU - 0.5, 24, Color(HALO.r, HALO.g, HALO.b, 0.3), 9.0, FighterArt.AA)
	c.draw_arc(Vector2.ZERO, 24.0, 0.3, TAU - 0.5, 24, HALO, 4.0, FighterArt.AA)
	c.draw_set_transform(Vector2.ZERO, 0.0, Vector2.ONE)
	if pose_v == "devour" and pt < 0.25:                                                 # CHOMP burst
		c.draw_arc(head + Vector2(40, 6), 20.0 + pt * 160.0, -1.0, 1.0, 12, Color(1, 1, 1, 0.8 - pt * 3.0), 5.0, FighterArt.AA)
