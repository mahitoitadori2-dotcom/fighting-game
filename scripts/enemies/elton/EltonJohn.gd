class_name EltonJohn
extends SimpleEnemy
## ELTON JOHN (affectionate cartoon parody): sequin suit, giant star glasses, feather
## boa, platform boots, a grand piano on stage. PvE enemy (BaseEnemy + EnemyPattern +
## EnemyHUD), 60 HP.
##
##   Piano Drop        12 dmg, 12 s - a piano falls on you; its SHADOW on the ground warns you
##   Rocket Man Dash    7 dmg, 8 s  - rocket boots, sparkly dash across the stage (armored)
##   Glitter Blast      4 dmg, 6 s  - a cloud of glitter: small damage + BLINDED (short daze)

const DASH_SPEED := 860.0
const DASH_KB := Vector2(480, -260)
const PIANO_KB := Vector2(300, -260)
const GLITTER_KB := Vector2(160, -80)

const SUIT := Color(0.62, 0.25, 0.85)
const SUIT_SHADE := Color(0.42, 0.14, 0.62)
const SUIT_HI := Color(0.82, 0.55, 1.0)
const SEQUIN := Color(1.0, 0.85, 0.3)
const PANTS := Color(0.97, 0.97, 0.97)
const PANTS_SHADE := Color(0.78, 0.78, 0.84)
const SKIN := Color(0.97, 0.82, 0.70)
const SKIN_SHADE := Color(0.80, 0.62, 0.52)
const HAIR := Color(0.55, 0.36, 0.20)
const STAR_PINK := Color(1.0, 0.35, 0.70)
const LENS := Color(0.35, 0.75, 1.0)
const BOA := Color(1.0, 0.55, 0.80)
const GOLD := Color(1.0, 0.82, 0.25)


func _make_data() -> CharacterData:
	keep_min = 140.0
	keep_max = 340.0
	return SimpleEnemy.make_data("Elton John", EnemyManager.ENEMY_HP, Vector2(60, 124), 320.0)


static func make_patterns() -> Array[EnemyPattern]:
	var list: Array[EnemyPattern] = []
	#                          id               name                cd    dmg  min    max    anim      tele  active rec   big    weights   armored
	list.append(EnemyPattern.make("piano_drop", "PIANO DROP!", 12.0, 12, 0.0, 720.0, "piano", 0.45, 0.20, 0.40, true, [1.4, 1.6]))
	list.append(EnemyPattern.make("rocket_dash", "ROCKET MAN DASH!", 8.0, 7, 120.0, 560.0, "dash", 0.40, 0.50, 0.40, true, [1.2, 1.4], true))
	list.append(EnemyPattern.make("glitter_blast", "GLITTER BLAST!", 6.0, 4, 0.0, 300.0, "glitter", 0.30, 0.20, 0.30, false, [1.5, 1.5]))
	list[0].note = "shadow warns you where it lands"
	list[1].note = "armored dash"
	list[2].note = "blinds (short daze)"
	return list


func flavor_lines() -> Array[String]:
	return ["FABULOUS!", "SING IT!", "ENCORE!", "*piano solo*"]


func _attack(p: EnemyPattern) -> void:
	match p.id:
		"piano_drop":
			var pr := spawn_projectile()
			pr.kind = EnemyProjectile.Kind.DROP
			pr.look = "piano"
			pr.damage = dmg(p)
			pr.knockback = PIANO_KB
			pr.delay = 0.85
			pr.radius = 75.0
			pr.move = "piano_drop"
			launch(pr, Vector2(clamp_to_ground(target_x(), 40.0), global_position.y))
			Effects.popup(self, global_position + Vector2(0, -150), "PIANO!", SEQUIN, 20)
		"rocket_dash":
			hitbox.activate(make_hit(dmg(p), Vector2(facing * DASH_KB.x, DASH_KB.y), "rocket_dash"),
				Vector2(facing * 10.0, -62.0), Vector2(84, 120))
			Effects.trail(visuals, Color(1.0, 0.75, 0.95), 34.0, 12)
			Effects.play_hit_sound(self, "rocket_dash", global_position)
		"glitter_blast":
			var g := spawn_projectile()
			g.look = "glitter"
			g.damage = dmg(p)
			g.knockback = GLITTER_KB
			g.dir = float(facing)
			g.speed = 380.0
			g.lifetime = 0.55
			g.size = Vector2(90, 90)
			g.move = "glitter_blast"
			g.on_hit = _blind
			launch(g, global_position + Vector2(facing * 60.0, -78.0))


func _blind(victim: Fighter) -> void:
	if is_instance_valid(victim) and not victim.is_dead:
		victim.stun_timer = maxf(victim.stun_timer, 0.45)
		Effects.popup(victim, victim.global_position + Vector2(0, -170), "BLINDED!", STAR_PINK, 22)


func _on_attack_update(p: EnemyPattern, _delta: float) -> void:
	if p.id == "rocket_dash":
		velocity.x = facing * DASH_SPEED * phase_speed_mult
		if int(state_time * 20.0) % 2 == 0:
			Effects.hit_sparks(self, global_position + Vector2(-facing * 30.0, -10.0), 2, 0.5)
		if not ground_ahead(50.0):
			state_time = state_len                    # Never dash off the stage


func _on_attack_end(p: EnemyPattern) -> void:
	if p.id == "rocket_dash":
		velocity.x *= 0.3


func _owns_velocity_x() -> bool:
	return estate == EState.ATTACK and current != null and current.id == "rocket_dash"


# ============================================================
# ART (facing right, origin = feet, ~70 x 130)
# ============================================================
func draw_model_on(c: CanvasItem) -> void:
	draw_elton(c, art_state())


static func draw_portrait(c: CanvasItem, t: float) -> void:
	draw_elton(c, {"t": t, "pose": "idle", "piano": true})


static func draw_elton(c: CanvasItem, s: Dictionary) -> void:
	var t: float = s.get("t", 0.0)
	var pose_v: String = s.get("pose", "idle")
	var pt: float = s.get("pose_t", 0.0)
	var dead: bool = s.get("dead", false)
	var dashing := pose_v == "dash"

	if s.get("enraged", false):
		EnemyArt.aura(c, Vector2(0, -64), 60.0, STAR_PINK, t)

	# Grand piano on stage (Character Select card, and while he plays the Piano Drop)
	if s.get("piano", false) or pose_v == "piano_tele" or pose_v == "piano":
		_piano(c, Vector2(-52, 0))

	var lean := 10.0 if dashing else 0.0
	var bob := absf(sin(t * 5.0)) * 2.0 if pose_v == "idle" else 0.0

	# Rocket boot flames
	if pose_v == "dash_tele" or dashing:
		var k := 1.0 if dashing else clampf(pt / 0.4, 0.2, 1.0)
		for fx in [-8.0, 10.0]:
			var fl := (18.0 + 8.0 * sin(t * 50.0 + fx)) * k
			c.draw_colored_polygon(PackedVector2Array([Vector2(fx - 7, -2), Vector2(fx + 7, -2), Vector2(fx - 4 - lean, fl)]), Color(1.0, 0.55, 0.1))
			c.draw_colored_polygon(PackedVector2Array([Vector2(fx - 4, -2), Vector2(fx + 4, -2), Vector2(fx - 2 - lean, fl * 0.6)]), Color(1.0, 0.95, 0.5))

	# Legs: white flares + gold platform boots
	EnemyArt.legs(c, s, -54.0, 9.0, 13.0, PANTS, PANTS_SHADE, Color.WHITE, GOLD, 16.0)
	for bx in [-9.0, 9.0]:
		c.draw_rect(Rect2(bx - 6.0, -6.0, 15.0, 6.0), GOLD.darkened(0.2))               # Platform soles

	var chest := Vector2(lean * 0.5, -86 - bob)

	# Far arm
	EnemyArt.arm(c, chest + Vector2(-14, -10), chest + Vector2(-20, 26), 11.0, SUIT_SHADE, SUIT_SHADE.darkened(0.15), SUIT, SKIN_SHADE)

	# Sequin jacket
	var jacket := PackedVector2Array([chest + Vector2(-20, -20), chest + Vector2(20, -20), chest + Vector2(24, 34), chest + Vector2(-22, 34)])
	c.draw_polygon(jacket, PackedColorArray([SUIT_HI, SUIT, SUIT_SHADE, SUIT_SHADE]))
	for i in 14:                                          # Sparkling sequins
		var sp := chest + Vector2(-16 + float(i * 7 % 34), -14 + float(i * 11 % 44))
		var tw := 0.5 + 0.5 * sin(t * 9.0 + float(i) * 1.7)
		c.draw_circle(sp, 1.4 + tw, Color(SEQUIN.r, SEQUIN.g, SEQUIN.b, 0.5 + 0.5 * tw))
	c.draw_colored_polygon(PackedVector2Array([chest + Vector2(-4, -20), chest + Vector2(4, -20), chest + Vector2(0, 6)]), Color.WHITE)   # Shirt V
	FighterArt.outline(c, jacket, 4.0)

	# Feather boa around the neck
	for i in 9:
		var a := PI * 0.1 + float(i) * 0.35
		var bp := chest + Vector2(cos(a) * 18.0, -18.0 + sin(a) * 8.0 + float(i) * 1.5)
		c.draw_circle(bp, 6.5, EnemyArt.BLACK)
		c.draw_circle(bp, 5.0, BOA)
	c.draw_circle(chest + Vector2(16, 6), 6.0, BOA)

	# Head: hair, giant pink star glasses, big grin
	var head := chest + Vector2(4, -36)
	FighterArt.ball(c, head, 14.0, SKIN, SKIN_SHADE, Color(1, 0.94, 0.88))
	var hair := PackedVector2Array([head + Vector2(-14, -2), head + Vector2(-12, -12), head + Vector2(-2, -16), head + Vector2(10, -14), head + Vector2(14, -6), head + Vector2(4, -10), head + Vector2(-6, -8)])
	c.draw_colored_polygon(hair, HAIR)
	FighterArt.outline(c, hair, 2.5)
	if dead:
		EnemyArt.ko_eye(c, head + Vector2(8, -1), 4.0, t)
	else:
		for gx in [0.0, 14.0]:
			var gc := head + Vector2(gx, -1)
			EnemyArt.star(c, gc, 9.0, STAR_PINK, 2.5)
			c.draw_circle(gc, 3.8, LENS)
			c.draw_circle(gc + Vector2(-1.2, -1.2), 1.2, Color.WHITE)
		c.draw_line(head + Vector2(5, -1), head + Vector2(9, -1), EnemyArt.BLACK, 2.0)     # Bridge
	c.draw_arc(head + Vector2(8, 6), 5.0, 0.2, 2.6, 8, EnemyArt.BLACK, 2.5)                  # Grin

	# Near arm
	var shoulder := chest + Vector2(14, -12)
	var hand := chest + Vector2(24, 26)
	match pose_v:
		"piano_tele", "piano":
			hand = chest + Vector2(18, -44)                     # Points to the sky
		"glitter_tele":
			hand = chest + Vector2(-6, -16)
		"glitter":
			hand = chest + Vector2(40, -14)
		"dash", "dash_tele":
			hand = chest + Vector2(34, -24)                     # Rocket Man pose
	EnemyArt.arm(c, shoulder, hand, 11.0, SUIT, SUIT_SHADE, SUIT_HI, SKIN)
	if pose_v == "glitter_tele":
		for i in 5:
			c.draw_circle(hand + Vector2.from_angle(t * 8.0 + float(i) * 1.25) * 10.0, 2.5, Color.from_hsv(float(i) / 5.0, 0.5, 1.0))


static func _piano(c: CanvasItem, at: Vector2) -> void:
	var lid := PackedVector2Array([at + Vector2(-34, -54), at + Vector2(28, -54), at + Vector2(10, -86)])
	c.draw_colored_polygon(lid, Color(0.1, 0.1, 0.12))
	FighterArt.outline(c, lid, 3.0)
	var body := FighterArt.rrect_points(Rect2(at.x - 36, at.y - 56, 72, 26), 6.0)
	c.draw_colored_polygon(body, Color(0.06, 0.06, 0.08))
	FighterArt.outline(c, body, 3.5)
	c.draw_rect(Rect2(at.x + 6, at.y - 40, 30, 8), Color(0.97, 0.97, 0.94))
	for i in 4:
		c.draw_rect(Rect2(at.x + 9 + float(i) * 7.0, at.y - 40, 3, 5), Color(0.05, 0.05, 0.05))
	for lx in [-28.0, 26.0]:
		c.draw_line(at + Vector2(lx, -30), at + Vector2(lx, -2), EnemyArt.BLACK, 5.0)
