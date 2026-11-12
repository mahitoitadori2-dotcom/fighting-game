class_name Sisyphus
extends FightBoss
## SISYPHUS - Fights-mode boss. Massive muscular soul in glowing gold and red armor,
## cracked stone skin, huge fists, a radiant halo, chains on his arms, a floating boulder
## on his back and angry glowing eyes.
##
##   Boulder Throw     11 dmg  hurls his boulder in an arc; rocks burst where it lands
##   Chain Slam         8 dmg  whips his chains down in front of him (long reach)
##   Sisyphus Punch    12 dmg  armored, super fast dash punch that BREAKS GUARD (unblockable)
##   Ground Shatter     7 dmg  stomp: the floor cracks and rocks blast up on both sides
##   RAGE MODE (< 50% HP): much faster, shorter cooldowns, red aura.

const HP := 200
const PORTRAIT_H := 290.0                  # Art height for Character Select cards
const PUNCH_SPEED := 1050.0
const PUNCH_KB := Vector2(700, -320)
const CHAIN_KB := Vector2(380, -260)
const BOULDER_FLIGHT := 0.85
const GUARD_BREAK_STUN := 0.8

const STONE := Color(0.62, 0.56, 0.50)
const STONE_SHADE := Color(0.40, 0.35, 0.31)
const GOLD := Color(1.0, 0.78, 0.25)
const GOLD_SHADE := Color(0.72, 0.48, 0.10)
const RED := Color(0.80, 0.12, 0.10)
const RED_SHADE := Color(0.48, 0.05, 0.05)
const EYE := Color(1.0, 0.55, 0.15)
const CHAIN := Color(0.68, 0.68, 0.72)
const RAGE := Color(1.0, 0.15, 0.1)

var _boulder_gone := 0.0                   # > 0: the boulder is flying (not on his back)


func _make_data() -> CharacterData:
	keep_min = 140.0
	keep_max = 340.0
	attack_chance = 0.7
	phase2_speed_mult = 1.7
	phase2_cooldown_mult = 0.55
	voice_id = "sisyphus"
	voice_pitch = 0.45
	voice_rate = 1.0
	accent = Color(1.0, 0.75, 0.3)
	intro_lines = ["You dare challenge ME?!", "I will crush you!"]
	attack_lines = {"boulder_throw": "I will crush you!", "sisyphus_punch": "I will crush you!",
		"ground_shatter": "My punishment never ends!"}
	rage_line = "My punishment never ends!"
	rage_title = "RAGE MODE!"
	death_line = "The boulder... rolls... again..."
	var d := SimpleEnemy.make_data("Sisyphus", HP, Vector2(110, 195), 240.0)
	d.hitstun_time = 0.1
	d.respawn_delay = 3.0
	return d


static func make_patterns() -> Array[EnemyPattern]:
	var list: Array[EnemyPattern] = []
	#                          id                name                  cd    dmg  min    max     anim      tele  active rec   big   weights   armored
	list.append(EnemyPattern.make("boulder_throw", "BOULDER THROW!", 5.0, 11, 200.0, 99999.0, "throw", 0.6, 0.3, 0.55, true, [1.6, 1.6], true))
	list.append(EnemyPattern.make("chain_slam", "CHAIN SLAM!", 4.0, 8, 0.0, 360.0, "chain", 0.45, 0.3, 0.45, true, [1.8, 1.8]))
	list.append(EnemyPattern.make("sisyphus_punch", "SISYPHUS PUNCH!", 4.0, 12, 110.0, 680.0, "punch", 0.4, 0.4, 0.5, true, [1.5, 2.2], true))
	list.append(EnemyPattern.make("ground_shatter", "GROUND SHATTER!", 6.0, 7, 0.0, 520.0, "stomp", 0.55, 0.3, 0.55, true, [1.2, 1.6], true))
	list[0].note = "rocks burst where it lands"
	list[1].note = "long reach"
	list[2].note = "BREAKS GUARD (unblockable), armored dash"
	list[3].note = "rocks blast up on both sides"
	return list


func _on_phase_changed(new_phase: int) -> void:
	super._on_phase_changed(new_phase)
	attack_chance = 0.85


func _on_respawn() -> void:
	super._on_respawn()
	attack_chance = 0.7
	_boulder_gone = 0.0


# ============================================================
# ATTACKS
# ============================================================
func _attack(p: EnemyPattern) -> void:
	match p.id:
		"boulder_throw":
			var b := spawn_projectile()
			b.kind = EnemyProjectile.Kind.ARC
			b.look = "boulder"
			b.damage = dmg(p)
			b.knockback = Vector2(420, -360)
			b.radius = 60.0
			b.pierce = false
			b.size = Vector2(60, 60)
			b.lifetime = 3.0
			b.move = "boulder_throw"
			var dx := clampf(target_x() - global_position.x, -900.0, 900.0)
			b.arc_velocity = Vector2(dx / BOULDER_FLIGHT, -0.5 * EnemyProjectile.ARC_GRAVITY * BOULDER_FLIGHT)
			b.on_land = _on_boulder_landed
			launch(b, global_position + Vector2(-facing * 10.0, -230.0))
			_boulder_gone = 2.0
			SoundManager.play_sfx("swing", 0.0)
		"chain_slam":
			hitbox.activate(make_hit(dmg(p), Vector2(facing * CHAIN_KB.x, CHAIN_KB.y), "chain_slam"),
				Vector2(facing * 190.0, -40.0), Vector2(320, 80))
			hazard("chain", global_position.x + facing * 190.0, 0.0, 0)
			hazard("chain", global_position.x + facing * 290.0, 0.0, 0)
			Effects.shake(self, 8.0)
			SoundManager.play_sfx("chain")
		"sisyphus_punch":
			var h := make_hit(dmg(p), Vector2(facing * PUNCH_KB.x, PUNCH_KB.y), "sisyphus_punch")
			h.blockable = false                                          # GUARD BREAK
			hitbox.activate(h, Vector2(facing * 60.0, -110.0), Vector2(130, 120))
			Effects.trail(visuals, RAGE if enraged else GOLD, 36.0, 14)
			SoundManager.play_sfx("dash")
		"ground_shatter":
			Effects.shake(self, 16.0)
			SoundManager.play_sfx("slam")
			hit_in_radius(global_position + Vector2(0, -30), 110.0, dmg(p), Vector2(300, -420), "ground_shatter")
			var n := 5 if enraged else 4
			for i in n:
				for d in [-1.0, 1.0]:
					hazard("rock", global_position.x + d * (150.0 + float(i) * 105.0), 0.15 + float(i) * 0.12, dmg(p), Vector2(200, -560))


func _on_hit_landed(victim: Fighter, _hit: HitData, _result: String) -> void:
	if current != null and current.id == "sisyphus_punch" and victim.is_blocking:
		victim.stun_timer = maxf(victim.stun_timer, GUARD_BREAK_STUN)
		Effects.popup(victim, victim.global_position + Vector2(0, -180), "GUARD BREAK!", Color(1.0, 0.35, 0.2), 30)
		Effects.announce(self, "GUARD BREAK!", Color(1.0, 0.35, 0.2), 2)
		SoundManager.play_sfx("stone")


func _on_boulder_landed(pos: Vector2) -> void:
	if not is_instance_valid(self) or is_dead:
		return
	Effects.shake(self, 14.0)
	SoundManager.play_sfx("slam")
	for i in 3:
		hazard("rock", pos.x + float(i - 1) * 90.0, 0.05 + float(i % 2) * 0.08, 5, Vector2(160, -480))


func _on_attack_update(p: EnemyPattern, _delta: float) -> void:
	if p.id == "sisyphus_punch":
		dash_step(PUNCH_SPEED * (1.2 if enraged else 1.0))


func _on_attack_end(p: EnemyPattern) -> void:
	if p.id == "sisyphus_punch":
		velocity.x *= 0.2


func _owns_velocity_x() -> bool:
	return estate == EState.ATTACK and current != null and current.id == "sisyphus_punch"


func _update_visuals(delta: float) -> void:
	_boulder_gone = maxf(_boulder_gone - delta, 0.0)
	if enraged:
		anim_time += delta * 0.6
	super._update_visuals(delta)


func art_state() -> Dictionary:
	var s := super.art_state()
	s["boulder"] = _boulder_gone <= 0.0
	return s


# ============================================================
# ART (facing right, origin = feet, ~150 x 260 with the boulder)
# ============================================================
func draw_model_on(c: CanvasItem) -> void:
	draw_sisyphus(c, art_state())


static func draw_portrait(c: CanvasItem, t: float) -> void:
	draw_sisyphus(c, {"t": t, "pose": "idle", "boulder": true})


static func draw_sisyphus(c: CanvasItem, s: Dictionary) -> void:
	var t: float = s.get("t", 0.0)
	var pose: String = s.get("pose", "idle")
	var pt: float = s.get("pose_t", 0.0)
	var dead: bool = s.get("dead", false)
	var rage: bool = s.get("enraged", false)
	var breathe := sin(t * 2.2) * 2.0
	var lean := 0.0
	match pose:
		"punch":
			lean = 22.0
		"punch_tele":
			lean = -10.0
		"stomp":
			lean = 4.0

	# Aura (gold; RAGE = red, bigger, flickering)
	if rage:
		EnemyArt.aura(c, Vector2(0, -110), 110.0 + 8.0 * sin(t * 18.0), RAGE, t * 2.0)
		for i in 6:
			var x := -60.0 + float(i) * 24.0
			var h := 40.0 + 25.0 * sin(t * 14.0 + float(i) * 1.7)
			c.draw_colored_polygon(PackedVector2Array([Vector2(x - 10, -6), Vector2(x + 10, -6), Vector2(x + sin(t * 9.0 + float(i)) * 6.0, -6 - h)]), Color(1.0, 0.2, 0.1, 0.35))
	else:
		EnemyArt.aura(c, Vector2(0, -110), 85.0, GOLD, t)

	# Floating boulder on his back
	if s.get("boulder", true) and pose != "throw":
		var bp := Vector2(-46 + lean * 0.3, -205 + sin(t * 1.6) * 6.0)
		if pose == "throw_tele":
			bp = Vector2(-10, -265)
		draw_boulder(c, bp, 44.0, t * 0.3)

	# Legs: thick stone legs with gold greaves
	var legs_s := s.duplicate()
	if pose == "stomp_tele":
		legs_s["moving"] = false
	EnemyArt.legs(c, legs_s, -66.0, 18.0, 22.0, STONE, STONE_SHADE, STONE.lightened(0.2), GOLD, 26.0)
	if pose == "stomp_tele":                               # One leg raised high
		var k := clampf(pt / 0.55, 0.0, 1.0)
		FighterArt.limb(c, Vector2(18, -66), Vector2(30, -66 - 40.0 * k), 22.0, STONE, STONE_SHADE, STONE.lightened(0.2))

	var hip := Vector2(lean * 0.3, -70)
	var chest := Vector2(lean, -140 + breathe)

	# Far arm (huge fist, chains)
	var far_hand := chest + Vector2(-46, 50)
	match pose:
		"throw_tele":
			far_hand = chest + Vector2(-30, -80)
		"throw":
			far_hand = chest + Vector2(70, -30)
		"chain_tele":
			far_hand = chest + Vector2(-60, -60)
		"chain":
			far_hand = chest + Vector2(80, 30)
	_arm(c, chest + Vector2(-34, -24), far_hand, true, t)

	# War skirt (red, gold trim)
	var skirt := PackedVector2Array([hip + Vector2(-36, -12), hip + Vector2(36, -12), hip + Vector2(42, 22), hip + Vector2(-42, 22)])
	c.draw_colored_polygon(skirt, RED)
	FighterArt.outline(c, skirt, 4.0)
	for i in 4:
		c.draw_line(hip + Vector2(-30 + float(i) * 20.0, -10), hip + Vector2(-34 + float(i) * 22.0, 20), RED_SHADE, 3.0)
	c.draw_line(hip + Vector2(-42, 20), hip + Vector2(42, 20), GOLD, 4.0)

	# Massive torso: cracked stone skin + gold chest plate with red gem
	var torso := PackedVector2Array([chest + Vector2(-46, -36), chest + Vector2(44, -36), chest + Vector2(34, 54), chest + Vector2(-32, 54)])
	var tc := PackedColorArray()
	for pnt in torso:
		tc.append(STONE.lerp(STONE_SHADE, clampf((pnt.x - chest.x + 46.0) / 90.0 * 0.6 + (pnt.y - chest.y + 36.0) / 90.0 * 0.4, 0.0, 1.0)))
	c.draw_polygon(torso, tc)
	var cracks := [[Vector2(-30, -10), Vector2(-18, 6), Vector2(-24, 24)], [Vector2(20, 14), Vector2(30, 30), Vector2(22, 46)], [Vector2(-6, 34), Vector2(6, 48)]]
	for cr in cracks:
		var line := PackedVector2Array()
		for q in cr:
			line.append(chest + q)
		c.draw_polyline(line, Color(1.0, 0.45, 0.1, 0.9) if rage else STONE_SHADE.darkened(0.4), 2.5)
	var plate := PackedVector2Array([chest + Vector2(-34, -30), chest + Vector2(32, -30), chest + Vector2(24, 4), chest + Vector2(0, 14), chest + Vector2(-24, 4)])
	c.draw_colored_polygon(plate, GOLD)
	FighterArt.outline(c, plate, 3.5)
	c.draw_line(chest + Vector2(-30, -26), chest + Vector2(28, -26), GOLD_SHADE, 3.0)
	FighterArt.ball(c, chest + Vector2(0, -8), 7.0, RED, RED_SHADE, Color(1, 0.6, 0.6))
	FighterArt.outline(c, torso, 4.5)
	# Shoulder pauldrons
	for sx in [-44.0, 40.0]:
		FighterArt.rrect(c, Rect2(chest.x + sx - 16, chest.y - 46, 34, 24), GOLD, GOLD_SHADE, Color(1, 1, 0.8), 10.0, 3.5)

	# Head: small for the body, square stone jaw, ANGRY glowing eyes, halo
	var head := chest + Vector2(8, -60)
	var halo_c := head + Vector2(-4, -30 + sin(t * 3.0) * 2.0)
	var halo := EnemyArt.ellipse_points(halo_c, 30, 9, 24)
	halo.append(halo[0])
	c.draw_circle(halo_c, 34.0, Color(GOLD.r, GOLD.g, GOLD.b, 0.15))
	c.draw_polyline(halo, EnemyArt.BLACK, 8.0, FighterArt.AA)
	c.draw_polyline(halo, RAGE if rage else Color(1.0, 0.92, 0.5), 5.0, FighterArt.AA)
	FighterArt.rrect(c, Rect2(head.x - 18, head.y - 20, 38, 40), STONE, STONE_SHADE, STONE.lightened(0.25), 10.0, 4.0)
	c.draw_line(head + Vector2(-10, -16), head + Vector2(-4, -6), STONE_SHADE.darkened(0.3), 2.0)
	if dead:
		EnemyArt.ko_eye(c, head + Vector2(10, -2), 5.0, t)
	else:
		var ec := RAGE if rage else EYE
		for ex in [2.0, 14.0]:
			c.draw_circle(head + Vector2(ex, -2), 8.0, Color(ec.r, ec.g, ec.b, 0.3))
			c.draw_colored_polygon(PackedVector2Array([head + Vector2(ex - 5, -5), head + Vector2(ex + 5, -1), head + Vector2(ex - 4, 1)]), ec)
		c.draw_line(head + Vector2(-4, -10), head + Vector2(8, -5), EnemyArt.BLACK, 3.0)   # Angry brows
		c.draw_line(head + Vector2(10, -5), head + Vector2(20, -10), EnemyArt.BLACK, 3.0)
		c.draw_line(head + Vector2(2, 12), head + Vector2(16, 12), EnemyArt.BLACK, 3.0)    # Grim mouth

	# Near arm (huge fist, chains)
	var hand := chest + Vector2(46, 46)
	match pose:
		"punch_tele":
			hand = chest + Vector2(-20, -10)
		"punch":
			hand = chest + Vector2(100, -14)
		"throw_tele":
			hand = chest + Vector2(-10, -90)
		"throw":
			hand = chest + Vector2(90, -50)
		"chain_tele":
			hand = chest + Vector2(-40, -70)
		"chain":
			hand = chest + Vector2(100, 40)
		"stomp", "stomp_tele":
			hand = chest + Vector2(56, 20)
	_arm(c, chest + Vector2(36, -24), hand, false, t)
	if pose == "chain" and pt < 0.35:                       # Chain whip down the floor
		var a := 1.0 - pt / 0.35
		var pts := PackedVector2Array()
		for i in 10:
			var k := float(i) / 9.0
			pts.append(hand.lerp(Vector2(320, -10), k) + Vector2(0, sin(k * PI) * -30.0))
		c.draw_polyline(pts, Color(0, 0, 0, a), 10.0, FighterArt.AA)
		c.draw_polyline(pts, Color(CHAIN.r, CHAIN.g, CHAIN.b, a), 6.0, FighterArt.AA)
	if pose == "punch" and pt < 0.3:
		c.draw_arc(hand, 30.0 + pt * 200.0, -1.2, 1.2, 14, Color(1, 0.8, 0.3, 1.0 - pt * 3.3), 8.0, FighterArt.AA)
	if pose == "stomp" and pt < 0.35:
		c.draw_arc(Vector2(0, 0), 40.0 + pt * 500.0, PI, TAU, 24, Color(1.0, 0.6, 0.2, 1.0 - pt / 0.35), 9.0, FighterArt.AA)


static func _arm(c: CanvasItem, shoulder: Vector2, hand: Vector2, far: bool, t: float) -> void:
	var col := STONE.darkened(0.15) if far else STONE
	var elbow := shoulder.lerp(hand, 0.5) + Vector2(-6, 8)
	FighterArt.limb(c, shoulder, elbow, 22.0, col, STONE_SHADE, STONE.lightened(0.2))
	FighterArt.limb(c, elbow, hand, 20.0, col, STONE_SHADE, STONE.lightened(0.2))
	# Gold bracer wrapped in chains
	var br := elbow.lerp(hand, 0.55)
	c.draw_circle(br, 14.0, EnemyArt.BLACK)
	c.draw_circle(br, 11.0, GOLD_SHADE if far else GOLD)
	for k in 3:
		var p := elbow.lerp(hand, 0.2 + 0.18 * float(k))
		var link := EnemyArt.ellipse_points(p + Vector2(0, 2), 9.0, 5.0, 10)
		link.append(link[0])
		c.draw_polyline(link, EnemyArt.BLACK, 4.5, FighterArt.AA)
		c.draw_polyline(link, CHAIN, 2.5, FighterArt.AA)
	# Dangling chain end
	var dangle := hand + Vector2(-6, 24 + sin(t * 4.0) * 4.0)
	c.draw_line(hand, dangle, EnemyArt.BLACK, 5.0)
	c.draw_line(hand, dangle, CHAIN, 3.0)
	# HUGE fist
	FighterArt.ball(c, hand, 17.0, col, STONE_SHADE, STONE.lightened(0.3))
	for k in 3:
		c.draw_line(hand + Vector2(4, -8 + float(k) * 7.0), hand + Vector2(14, -8 + float(k) * 7.0), STONE_SHADE.darkened(0.3), 2.0)


static func draw_boulder(c: CanvasItem, p: Vector2, r: float, rot: float) -> void:
	var pts := PackedVector2Array()
	for i in 11:
		var a := TAU * float(i) / 11.0 + rot
		pts.append(p + Vector2.from_angle(a) * r * (0.85 + 0.15 * sin(float(i) * 2.7)))
	c.draw_colored_polygon(pts, Color(0.52, 0.47, 0.42))
	c.draw_circle(p + Vector2(-r * 0.3, -r * 0.3), r * 0.35, Color(0.65, 0.6, 0.55))
	c.draw_line(p + Vector2.from_angle(rot) * r * 0.2, p + Vector2.from_angle(rot + 0.8) * r * 0.7, Color(0.3, 0.27, 0.24), 3.0)
	c.draw_line(p + Vector2.from_angle(rot + 2.5) * r * 0.1, p + Vector2.from_angle(rot + 3.0) * r * 0.6, Color(0.3, 0.27, 0.24), 3.0)
	FighterArt.outline(c, pts, 4.0)
