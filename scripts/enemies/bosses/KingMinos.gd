class_name KingMinos
extends FightBoss
## KING MINOS - Fights-mode boss. Giant pale corpse king with a huge serpent body, a
## glowing white crown, long skeletal arms, blue glowing eyes and tattered royal robes.
## He FLOATS above the ground on his coiled serpent tail.
##
##   Serpent Slam      10 dmg  both arms slam down + shockwaves along the floor (both ways)
##   Judgment Kick      9 dmg  armored, very fast dash strike
##   Ghost Serpent      7 dmg  3 ghost serpent heads burst out of the floor and bite
##   Prime Combo      5 x3     fast 3-hit punch combo
##   Ground Eruption    8 dmg  pillars of light erupt under you (3 in phase 2)
## Phase 2 (< 50% HP): faster, shorter cooldowns.

const HP := 180
const PORTRAIT_H := 270.0                  # Art height for Character Select cards
const KICK_SPEED := 980.0
const SLAM_KB := Vector2(420, -380)
const KICK_KB := Vector2(620, -300)
const COMBO_KB := Vector2(180, -120)
const COMBO_FINAL_KB := Vector2(480, -260)

const SKIN := Color(0.86, 0.87, 0.84)
const SKIN_SHADE := Color(0.60, 0.62, 0.62)
const BONE := Color(0.93, 0.92, 0.86)
const ROBE := Color(0.22, 0.17, 0.42)
const ROBE_SHADE := Color(0.12, 0.09, 0.25)
const ROBE_TRIM := Color(0.85, 0.75, 0.35)
const GLOW := Color(0.45, 0.80, 1.0)
const CROWN := Color(1.0, 1.0, 0.96)

var _combo_n := 0


func _make_data() -> CharacterData:
	keep_min = 130.0
	keep_max = 320.0
	attack_chance = 0.7
	phase2_speed_mult = 1.4
	phase2_cooldown_mult = 0.65
	voice_id = "minos"
	voice_pitch = 0.55
	voice_rate = 0.9
	accent = Color(0.75, 0.9, 1.0)
	intro_lines = ["I am King Minos!", "Judgment is upon thee!"]
	attack_lines = {"serpent_slam": "Thy flesh is weak!", "judgment_kick": "Judgment is upon thee!",
		"ground_eruption": "Judgment is upon thee!", "prime_combo": "Thy flesh is weak!"}
	rage_line = "I am King Minos!"
	rage_title = "JUDGMENT RAGE!"
	death_line = "My judgment... has failed..."
	var d := SimpleEnemy.make_data("King Minos", HP, Vector2(100, 220), 230.0)
	d.hitstun_time = 0.1
	d.respawn_delay = 3.0
	return d


static func make_patterns() -> Array[EnemyPattern]:
	var list: Array[EnemyPattern] = []
	#                          id               name                 cd    dmg  min    max     anim      tele  active rec   big   weights   armored
	list.append(EnemyPattern.make("serpent_slam", "SERPENT SLAM!", 5.0, 10, 0.0, 230.0, "slam", 0.55, 0.25, 0.55, true, [1.6, 1.6], true))
	list.append(EnemyPattern.make("judgment_kick", "JUDGMENT KICK!", 4.0, 9, 150.0, 760.0, "kick", 0.35, 0.45, 0.45, true, [1.5, 2.0], true))
	list.append(EnemyPattern.make("ghost_serpent", "GHOST SERPENT!", 7.0, 7, 0.0, 99999.0, "summon", 0.6, 0.3, 0.5, true, [1.2, 1.5]))
	list.append(EnemyPattern.make("prime_combo", "PRIME COMBO!", 3.0, 5, 0.0, 170.0, "combo", 0.25, 0.9, 0.4, true, [2.2, 2.6]))
	list.append(EnemyPattern.make("ground_eruption", "GROUND ERUPTION!", 6.0, 8, 180.0, 99999.0, "erupt", 0.5, 0.3, 0.5, true, [1.3, 1.8]))
	list[0].note = "shockwaves along the floor"
	list[1].note = "armored dash"
	list[2].note = "3 ghost serpents bite from the floor"
	list[3].note = "3 hits"
	list[4].note = "light pillars under you (3 when enraged)"
	return list


# ============================================================
# ATTACKS
# ============================================================
func _attack(p: EnemyPattern) -> void:
	match p.id:
		"serpent_slam":
			hitbox.activate(make_hit(dmg(p), Vector2(facing * SLAM_KB.x, SLAM_KB.y), "serpent_slam"),
				Vector2(facing * 80.0, -50.0), Vector2(150, 100))
			for d in [-1.0, 1.0]:
				var w := spawn_projectile()
				w.look = "shock"
				w.tint = GLOW
				w.damage = maxi(1, dmg(p) / 2)
				w.knockback = Vector2(260, -300)
				w.dir = d
				w.speed = 620.0
				w.lifetime = 0.9
				w.size = Vector2(50, 40)
				w.move = "serpent_shockwave"
				launch(w, global_position + Vector2(d * 60.0, -20.0))
			Effects.shake(self, 14.0)
			Effects.hit_sparks(self, global_position + Vector2(facing * 80.0, -10), 12, 1.5)
			SoundManager.play_sfx("slam")
		"judgment_kick":
			hitbox.activate(make_hit(dmg(p), Vector2(facing * KICK_KB.x, KICK_KB.y), "judgment_kick"),
				Vector2(facing * 50.0, -80.0), Vector2(130, 150))
			Effects.trail(visuals, GLOW, 34.0, 14)
			SoundManager.play_sfx("dash")
		"ghost_serpent":
			var tx := target_x()
			for i in 3:
				hazard("serpent", tx + float(i - 1) * 120.0 + randf_range(-20.0, 20.0), 0.55 + float(i) * 0.25, dmg(p), Vector2(200, -520))
			SoundManager.play_sfx("void_goo", -2.0)
		"prime_combo":
			_combo_n = 0
			_punch(p)
		"ground_eruption":
			var tx := target_x()
			if enraged:
				for i in 3:
					hazard("pillar", tx + float(i - 1) * 140.0, 0.6 + float(i) * 0.12, dmg(p), Vector2(160, -620))
			else:
				hazard("pillar", tx, 0.65, dmg(p), Vector2(160, -620))
			SoundManager.play_sfx("holy", -4.0)


func _punch(p: EnemyPattern) -> void:
	_combo_n += 1
	var last := _combo_n >= 3
	var kb := COMBO_FINAL_KB if last else COMBO_KB
	hitbox.activate(make_hit(dmg(p) + (2 if last else 0), Vector2(facing * kb.x, kb.y), "prime_combo"),
		Vector2(facing * 75.0, -120.0), Vector2(120, 90))
	velocity.x += facing * 160.0
	SoundManager.play_sfx("punch" if not last else "slam", -2.0 if not last else -6.0)


func _on_attack_update(p: EnemyPattern, _delta: float) -> void:
	match p.id:
		"judgment_kick":
			dash_step(KICK_SPEED * (1.15 if enraged else 1.0))
		"prime_combo":
			if _combo_n < 3 and state_time >= float(_combo_n) * 0.28:
				_punch(p)


func _on_attack_end(p: EnemyPattern) -> void:
	if p.id == "judgment_kick":
		velocity.x *= 0.2


func _owns_velocity_x() -> bool:
	return estate == EState.ATTACK and current != null and current.id == "judgment_kick"


# ============================================================
# ART (facing right, origin = floor under him, ~150 x 250). He floats.
# ============================================================
func draw_model_on(c: CanvasItem) -> void:
	draw_minos(c, art_state())


static func draw_portrait(c: CanvasItem, t: float) -> void:
	draw_minos(c, {"t": t, "pose": "idle"})


static func draw_minos(c: CanvasItem, s: Dictionary) -> void:
	var t: float = s.get("t", 0.0)
	var pose: String = s.get("pose", "idle")
	var pt: float = s.get("pose_t", 0.0)
	var dead: bool = s.get("dead", false)
	var rage: bool = s.get("enraged", false)
	var hover := sin(t * 2.0) * 5.0
	var lean := 0.0
	if pose == "kick":
		lean = 26.0
	elif pose == "slam":
		lean = 10.0

	# Ghostly glow (blue; enraged = brighter)
	EnemyArt.aura(c, Vector2(0, -150 + hover), 95.0 if rage else 80.0, GLOW, t)

	# --- Serpent body: coils on the floor behind him and rises up into the waist ---
	var waist := Vector2(lean * 0.4, -112 + hover)
	var tail := PackedVector2Array()
	var whip := 0.0
	if pose == "kick" or pose == "kick_tele":
		whip = 1.0
	for i in 15:
		var k := float(i) / 14.0
		var coil := Vector2(-70.0 + 30.0 * cos(k * 5.0 + t * 1.2) - 40.0 * k * whip, -14.0 - 10.0 * sin(k * 6.0 + t * 1.5))
		tail.append(coil.lerp(waist + Vector2(0, 10), smoothstep(0.35, 1.0, k)))
	_thick(c, tail, 40.0, SKIN_SHADE, SKIN)
	# Tail tip
	c.draw_colored_polygon(PackedVector2Array([tail[0] + Vector2(0, -12), tail[0] + Vector2(-34, 2), tail[0] + Vector2(0, 12)]), SKIN_SHADE)
	# Belly scales
	for i in range(3, 14, 2):
		c.draw_line(tail[i] + Vector2(-7, 6), tail[i] + Vector2(7, 6), SKIN_SHADE.darkened(0.25), 2.0)

	var chest := waist + Vector2(4, -52)

	# --- Far arm (long skeletal) ---
	var far_hand := chest + Vector2(-30, 62)
	match pose:
		"slam_tele":
			far_hand = chest + Vector2(-10, -90)
		"slam":
			far_hand = chest + Vector2(70, 100)
		"summon_tele", "summon", "erupt_tele":
			far_hand = chest + Vector2(-70, -40)
		"combo":
			far_hand = chest + Vector2(60 + 30.0 * sin(t * 30.0), -10)
	_bone_arm(c, chest + Vector2(-20, -18), far_hand, true, rage, t)

	# --- Tattered royal robe at the waist + over the shoulders ---
	var robe := PackedVector2Array([chest + Vector2(-34, -24), chest + Vector2(30, -24), chest + Vector2(44, 52),
		chest + Vector2(34, 66), chest + Vector2(26, 56), chest + Vector2(14, 72), chest + Vector2(2, 58),
		chest + Vector2(-10, 74), chest + Vector2(-22, 58), chest + Vector2(-34, 70), chest + Vector2(-46, 50)])
	var cols := PackedColorArray()
	for pnt in robe:
		cols.append(ROBE.lerp(ROBE_SHADE, clampf((pnt.y - chest.y + 24.0) / 96.0, 0.0, 1.0)))
	c.draw_polygon(robe, cols)
	FighterArt.outline(c, robe, 4.0)
	c.draw_line(chest + Vector2(-34, -22), chest + Vector2(30, -22), ROBE_TRIM, 4.0)
	# Bare corpse chest with ribs (robe open at the front)
	var torso := PackedVector2Array([chest + Vector2(-14, -22), chest + Vector2(16, -22), chest + Vector2(12, 34), chest + Vector2(-10, 34)])
	c.draw_colored_polygon(torso, SKIN)
	for i in 4:
		var y := -12.0 + float(i) * 11.0
		c.draw_arc(chest + Vector2(1, y + 8), 13.0, -2.6, -0.5, 8, SKIN_SHADE, 2.0)
	FighterArt.outline(c, torso, 2.5)

	# --- Head: gaunt pale skull-face, blue glowing eyes, glowing crown ---
	var head := chest + Vector2(6, -46)
	FighterArt.ball(c, head, 22.0, SKIN, SKIN_SHADE, Color(1, 1, 1))
	c.draw_colored_polygon(PackedVector2Array([head + Vector2(-6, 10), head + Vector2(20, 8), head + Vector2(12, 24), head + Vector2(-2, 22)]), SKIN_SHADE)  # Jaw
	FighterArt.outline(c, PackedVector2Array([head + Vector2(-6, 10), head + Vector2(20, 8), head + Vector2(12, 24), head + Vector2(-2, 22)]), 2.5)
	if dead:
		EnemyArt.ko_eye(c, head + Vector2(10, -2), 5.0, t)
	else:
		var flick := 0.8 + 0.2 * sin(t * 12.0)
		for ex in [2.0, 14.0]:
			c.draw_circle(head + Vector2(ex, -2), 7.0, Color(0.05, 0.05, 0.1))         # Sunken sockets
			c.draw_circle(head + Vector2(ex, -2), 10.0, Color(GLOW.r, GLOW.g, GLOW.b, 0.25 * flick))
			c.draw_circle(head + Vector2(ex, -2), 3.5, Color(0.7, 0.95, 1.0, flick))
		c.draw_line(head + Vector2(0, 16), head + Vector2(14, 15), Color(0.2, 0.2, 0.25), 2.0)
	# Crown (glowing white)
	var crown_base := head + Vector2(0, -18)
	var crown := PackedVector2Array([crown_base + Vector2(-22, 4), crown_base + Vector2(-24, -18), crown_base + Vector2(-12, -6),
		crown_base + Vector2(-4, -30), crown_base + Vector2(4, -6), crown_base + Vector2(14, -24), crown_base + Vector2(20, -4),
		crown_base + Vector2(26, -16), crown_base + Vector2(24, 4)])
	c.draw_circle(crown_base + Vector2(0, -10), 34.0, Color(1, 1, 1, 0.12 + 0.06 * sin(t * 5.0)))
	c.draw_colored_polygon(crown, CROWN)
	FighterArt.outline(c, crown, 3.0)
	c.draw_circle(crown_base + Vector2(1, -4), 3.5, GLOW)

	# --- Near arm (long skeletal) ---
	var hand := chest + Vector2(34, 58)
	match pose:
		"slam_tele":
			hand = chest + Vector2(20, -100)
		"slam":
			hand = chest + Vector2(90, 104)
		"kick", "kick_tele":
			hand = chest + Vector2(-40, 30)
		"summon_tele", "summon":
			hand = chest + Vector2(80, -40)
		"erupt_tele", "erupt":
			hand = chest + Vector2(60, -70)
		"combo":
			hand = chest + Vector2(90 + 30.0 * sin(t * 30.0 + PI), -20)
		"combo_tele":
			hand = chest + Vector2(10, -10)
	_bone_arm(c, chest + Vector2(18, -18), hand, false, rage, t)
	if pose in ["summon_tele", "summon", "erupt_tele", "erupt"]:
		var k := clampf(pt / 0.5, 0.0, 1.0) if pose.ends_with("_tele") else 1.0
		c.draw_circle(hand, 10.0 + 14.0 * k, Color(GLOW.r, GLOW.g, GLOW.b, 0.35))
		c.draw_circle(hand, 6.0 + 4.0 * k, Color(1, 1, 1, 0.9))
	if pose == "slam" and pt < 0.3:
		c.draw_arc(Vector2(80, 0), 30.0 + pt * 300.0, PI, TAU, 22, Color(GLOW.r, GLOW.g, GLOW.b, 1.0 - pt * 3.3), 8.0, true)
	if pose == "kick":
		for i in 4:
			var y := -60.0 - float(i) * 30.0
			c.draw_line(Vector2(-60 - float(i) * 20.0, y), Vector2(-140 - float(i) * 20.0, y), Color(GLOW.r, GLOW.g, GLOW.b, 0.6), 4.0)


## Thick tube along a polyline: black outline, shaded body, lit stripe.
static func _thick(c: CanvasItem, pts: PackedVector2Array, w: float, shade: Color, base: Color) -> void:
	var widths := []
	for i in pts.size():
		widths.append(lerpf(w * 0.45, w, float(i) / float(pts.size() - 1)))
	for i in pts.size():
		c.draw_circle(pts[i], widths[i] * 0.5 + 3.0, EnemyArt.BLACK)
	for i in pts.size():
		c.draw_circle(pts[i], widths[i] * 0.5, shade)
	for i in pts.size():
		c.draw_circle(pts[i] + Vector2(-2, -4), widths[i] * 0.32, base)


## Long skeletal arm: thin bones, knobbly joints, clawed bony hand.
static func _bone_arm(c: CanvasItem, shoulder: Vector2, hand: Vector2, far: bool, rage: bool, t: float) -> void:
	var col := BONE.darkened(0.2) if far else BONE
	var elbow := shoulder.lerp(hand, 0.5) + Vector2(-8, 10)
	FighterArt.limb(c, shoulder, elbow, 9.0, col, col.darkened(0.25), Color.WHITE)
	FighterArt.limb(c, elbow, hand, 8.0, col, col.darkened(0.25), Color.WHITE)
	FighterArt.ball(c, elbow, 6.0, col, col.darkened(0.25), Color.WHITE)
	var dir := (hand - elbow).normalized()
	for k in 4:
		var a := dir.angle() + (float(k) - 1.5) * 0.35
		var tip := hand + Vector2.from_angle(a) * 18.0
		c.draw_line(hand, tip, EnemyArt.BLACK, 6.0, true)
		c.draw_line(hand, tip, col, 3.0, true)
	FighterArt.ball(c, hand, 7.0, col, col.darkened(0.3), Color.WHITE)
	if rage:
		c.draw_circle(hand, 12.0 + 2.0 * sin(t * 20.0), Color(GLOW.r, GLOW.g, GLOW.b, 0.3))
