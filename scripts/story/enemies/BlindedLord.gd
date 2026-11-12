class_name BlindedLord
extends SimpleEnemy
## THE BLINDED LORD - BOSS of Colosseum 1 (Level 6).
## A gaunt, hunched alchemist with a bandaged blindfold, a giant jug of glowing chemicals
## and a belt of bubbling vials. He fights by SPILLING CHEMICALS: every glob that lands
## leaves a CHEMICAL POOL (ChemicalPool) that hurts you while you stand in it.
##
## PHASE 1 (100% - 50%): slow and methodical. Keeps his distance, throws globs in arcs,
##                       pours puddles in front of himself.
## PHASE 2 (< 50%): CRAZED. Blindfold tears, eyes GLOW, animation speeds up. Much faster,
##                  shorter cooldowns and he goes MELEE: JUG SMASH, WILD SWINGS and CHARGES
##                  (toxic trail). Chemicals only when you keep your distance.
## ARENA: his LABORATORY (StoryLevels map "lab") - the level switches to it at the boss intro.
##
##   Chemical Spill   4 dmg per glob + pools   3 globs (P1) / 5 globs (P2) in arcs in front
##   Pour             pools only               a wide puddle in front of him + at his feet
##   Charge (P2)      9 dmg                    armored dash, leaves pools behind him
##   Wild Swings (P2) 4 dmg x3                 three frenzied jug swings

const GLOB_FLIGHT := 0.8
const GLOB_KB := Vector2(160, -100)
const CHARGE_SPEED := 780.0
const CHARGE_KB := Vector2(520, -280)
const SWING_KB := Vector2(260, -150)
const SMASH_KB := Vector2(480, -300)

const ROBE := Color(0.24, 0.16, 0.30)
const ROBE_SHADE := Color(0.13, 0.08, 0.17)
const ROBE_HI := Color(0.38, 0.27, 0.46)
const SKIN := Color(0.70, 0.70, 0.66)
const SKIN_SHADE := Color(0.48, 0.48, 0.46)
const BANDAGE := Color(0.88, 0.84, 0.72)
const CHEM := Color(0.45, 0.95, 0.15)
const CHEM_HI := Color(0.85, 1.0, 0.6)
const GLASS := Color(0.75, 0.95, 0.95, 0.55)
const CRAZED := Color(1.0, 0.95, 0.25)

var _trail_t := 0.0
var _swing_n := 0


func _make_data() -> CharacterData:
	keep_min = 240.0
	keep_max = 460.0
	attack_chance = 0.6
	phase2_threshold = 0.5
	phase2_speed_mult = 2.0                         # Crazed: MUCH faster
	phase2_cooldown_mult = 0.7
	knockback_scale = 0.5
	var d := SimpleEnemy.make_data("The Blinded Lord", 140, Vector2(80, 170), 120.0)
	d.hitstun_time = 0.12
	d.respawn_delay = 3.0
	return d


static func make_patterns() -> Array[EnemyPattern]:
	var list: Array[EnemyPattern] = []
	#                          id             name               cd    dmg  min    max    anim      tele  active rec   big   weights [P1,P2]  armored
	# Phase 1 = chemicals from a distance. Phase 2 (ENRAGED) = MELEE: smashes, swings, charges.
	list.append(EnemyPattern.make("spill", "CHEMICAL SPILL!", 3.6, 4, 90.0, 700.0, "throw", 0.65, 0.30, 0.50, true, [2.0, 0.6]))
	list.append(EnemyPattern.make("pour", "POUR!", 6.5, 0, 0.0, 240.0, "pour", 0.50, 0.60, 0.40, true, [1.4, 0.3]))
	list.append(EnemyPattern.make("charge", "CHARGE!", 4.0, 9, 140.0, 900.0, "charge", 0.45, 0.80, 0.50, true, [0.0, 2.2], true))
	list.append(EnemyPattern.make("swings", "WILD SWINGS!", 2.4, 4, 0.0, 150.0, "swings", 0.25, 0.90, 0.45, true, [0.0, 3.0]))
	list.append(EnemyPattern.make("smash", "JUG SMASH!", 3.0, 8, 0.0, 160.0, "smash", 0.35, 0.15, 0.45, true, [0.0, 2.6]))
	list[4].note = "enraged only: overhead melee smash + chemical splash"
	return list


## Enraged: when you're close he fights with his hands, not his chemicals.
func wants_pattern(p: EnemyPattern) -> bool:
	if enraged and (p.id == "spill" or p.id == "pour") and brain != null and brain.dist < 200.0:
		return false
	return true


func _on_respawn() -> void:
	super._on_respawn()
	knockback_scale = 0.5
	keep_min = 240.0
	keep_max = 460.0
	attack_chance = 0.6


func flavor_lines() -> Array[String]:
	if enraged:
		return ["HAHAHAHA!", "BURN! MELT!", "I SMELL YOU!"]
	return ["I hear your heartbeat...", "Step closer, little one.", "*sloshing*"]


func boss_title() -> String:
	return enemy_name.to_upper() + ("   -   PHASE 2: CRAZED" if enraged else "")


func custom_death_type(_hit: HitData) -> String:
	return DeathManager.IMPLODE


func _on_phase_changed(_new_phase: int) -> void:
	keep_min = 0.0                                  # Crazed: in your face
	keep_max = 110.0
	attack_chance = 0.85
	Effects.popup(self, global_position + Vector2(0, -230), "CRAZED!", CRAZED, 34)
	Effects.shake(self, 12.0)
	SoundManager.play_sfx("roar")                   # Boss roar
	SoundManager.play_sfx("ultimate", -4.0)
	for i in 4:                                     # Splashes in every direction
		_throw_glob(float(i - 2) * 120.0 + 60.0, 4)


# ============================================================
# ATTACKS
# ============================================================
func _attack(p: EnemyPattern) -> void:
	match p.id:
		"spill":
			var n := 5 if enraged else 3
			var spacing := 115.0 if enraged else 90.0
			var base := 150.0
			if brain != null and brain.target != null and is_instance_valid(brain.target):
				base = clampf(absf(brain.target.global_position.x - global_position.x) - spacing, 110.0, 520.0)
			for i in n:
				_throw_glob(float(facing) * (base + float(i) * spacing + randf_range(-20.0, 20.0)), dmg(p))
			SoundManager.play_sfx("void_goo", -2.0)
		"pour":
			_pool_at(global_position.x + facing * 120.0, 210.0 if enraged else 170.0, 5.5)
			_pool_at(global_position.x - facing * 20.0, 110.0, 4.0)
			SoundManager.play_sfx("void_goo")
		"charge":
			_trail_t = 0.0
			hitbox.activate(make_hit(dmg(p), Vector2(facing * CHARGE_KB.x, CHARGE_KB.y), "lord_charge"),
				Vector2(facing * 20.0, -90.0), Vector2(100, 170))
			Effects.trail(visuals, CHEM, 30.0, 12)
			SoundManager.play_sfx("dash")
		"swings":
			_swing_n = 0
			_swing(p)
		"smash":
			hitbox.activate(make_hit(dmg(p), Vector2(facing * SMASH_KB.x, SMASH_KB.y), "lord_smash"),
				Vector2(facing * 70.0, -60.0), Vector2(110, 120))
			_pool_at(global_position.x + facing * 90.0, 120.0, 3.5)          # Jug shatters: splash
			Effects.shake(self, 10.0)
			Effects.hit_sparks(self, global_position + Vector2(facing * 90.0, -10), 10, 1.3)
			SoundManager.play_sfx("explosion", -4.0)


func _swing(p: EnemyPattern) -> void:
	_swing_n += 1
	hitbox.activate(make_hit(dmg(p), Vector2(facing * SWING_KB.x, SWING_KB.y), "lord_swing"),
		Vector2(facing * 62.0, -100.0), Vector2(100, 90))
	velocity.x += facing * 120.0
	SoundManager.play_sfx("sword_slash", -2.0)


func _on_attack_update(p: EnemyPattern, delta: float) -> void:
	match p.id:
		"charge":
			velocity.x = facing * CHARGE_SPEED
			_trail_t -= delta
			if _trail_t <= 0.0:
				_trail_t = 0.18
				_pool_at(global_position.x - facing * 40.0, 90.0, 3.5)       # Toxic trail
			if is_on_wall() or not ground_ahead(60.0):
				state_time = state_len
		"swings":
			if _swing_n < 3 and state_time >= float(_swing_n) * 0.3:
				_swing(p)                                                  # 3 swings: 0.0 / 0.3 / 0.6 s


func _on_attack_end(p: EnemyPattern) -> void:
	if p.id == "charge":
		velocity.x *= 0.2


func _owns_velocity_x() -> bool:
	return estate == EState.ATTACK and current != null and current.id == "charge"


## Throw one glob that lands dx px away (same floor height) and leaves a pool.
func _throw_glob(dx: float, damage: int) -> void:
	var g := spawn_projectile()
	g.kind = EnemyProjectile.Kind.ARC
	g.look = "chem_glob"
	g.damage = damage
	g.knockback = GLOB_KB
	g.radius = 34.0
	g.pierce = false
	g.size = Vector2(26, 26)
	g.lifetime = 3.0
	g.move = "chemical_spill"
	g.arc_velocity = Vector2(dx / GLOB_FLIGHT, -0.5 * EnemyProjectile.ARC_GRAVITY * GLOB_FLIGHT)
	g.on_land = _on_glob_landed
	launch(g, global_position + Vector2(facing * 30.0, -120.0))


func _on_glob_landed(pos: Vector2) -> void:
	if is_instance_valid(self) and not is_dead:
		ChemicalPool.spawn(self, pos, 150.0 if enraged else 120.0, 5.0 if enraged else 6.0)


func _pool_at(x: float, w: float, life: float) -> void:
	var g: Variant = Effects.ground_below(self, Vector2(x, global_position.y - 40.0), 200.0)
	if g != null:
		ChemicalPool.spawn(self, g, w, life)


# ============================================================
# VISUALS: phase 2 = faster animation + twitching
# ============================================================
func _update_visuals(delta: float) -> void:
	if enraged:
		anim_time += delta * 1.2                      # Everything animates ~2x faster
	super._update_visuals(delta)


# ============================================================
# ART (facing right, origin = feet, ~110 x 200)
# ============================================================
func draw_model_on(c: CanvasItem) -> void:
	draw_lord(c, art_state())


static func draw_portrait(c: CanvasItem, t: float) -> void:
	draw_lord(c, {"t": t, "pose": "idle"})


static func draw_lord(c: CanvasItem, s: Dictionary) -> void:
	var t: float = s.get("t", 0.0)
	var pose_v: String = s.get("pose", "idle")
	var pt: float = s.get("pose_t", 0.0)
	var dead: bool = s.get("dead", false)
	var crazed: bool = s.get("enraged", false)
	var twitch := Vector2(sin(t * 47.0), cos(t * 39.0)) * (2.0 if crazed else 0.0)
	var sway := sin(t * (4.0 if crazed else 1.4)) * 3.0

	# Toxic aura (green; crazed = bright + flickering)
	EnemyArt.aura(c, Vector2(0, -100), 70.0 if crazed else 55.0, CRAZED if crazed else CHEM, t)

	# Legs hidden by the robe: just two pale bony feet
	EnemyArt.legs(c, s, -40.0, 10.0, 9.0, SKIN_SHADE, SKIN_SHADE.darkened(0.2), SKIN, SKIN_SHADE, 16.0)

	var lean := 14.0 if pose_v == "charge" else 0.0
	var chest := Vector2(-4 + lean + sway * 0.3, -124) + twitch

	# Far arm (long, thin) holding a small vial
	var far_hand := chest + Vector2(-26, 40)
	if pose_v == "throw_tele" or pose_v == "pour_tele":
		far_hand = chest + Vector2(-34, 10)
	EnemyArt.arm(c, chest + Vector2(-14, -16), far_hand, 9.0, ROBE_SHADE, ROBE_SHADE.darkened(0.2), ROBE, SKIN_SHADE, 6.0)
	_vial(c, far_hand + Vector2(0, -10), 0.0, t)

	# Tattered robe (hunched, ragged hem)
	var robe := PackedVector2Array([chest + Vector2(-26, -30), chest + Vector2(24, -26), chest + Vector2(34, 60),
		chest + Vector2(30, 92), chest + Vector2(18, 84), chest + Vector2(8, 94), chest + Vector2(-4, 84),
		chest + Vector2(-16, 94), chest + Vector2(-26, 84), chest + Vector2(-34, 92), chest + Vector2(-32, 50)])
	var cols := PackedColorArray()
	for p in robe:
		cols.append(ROBE_HI.lerp(ROBE_SHADE, clampf((p.y - chest.y + 30.0) / 120.0, 0.0, 1.0)))
	c.draw_polygon(robe, cols)
	# Belt of bubbling vials
	c.draw_line(chest + Vector2(-28, 30), chest + Vector2(30, 32), Color(0.3, 0.2, 0.1), 6.0)
	for k in 4:
		_vial(c, chest + Vector2(-18 + float(k) * 13.0, 40), 0.0, t + float(k))
	# Chemical stains / drips on the robe
	for k in 3:
		var dp := chest + Vector2(-14 + float(k) * 16.0, 56 + float(k % 2) * 10.0)
		c.draw_circle(dp, 4.0, Color(CHEM.r, CHEM.g, CHEM.b, 0.6))
	FighterArt.outline(c, robe, 4.5)

	# Head: hood, pale face, BANDAGE BLINDFOLD (phase 2: torn, eyes glowing through)
	var head := chest + Vector2(14, -42)
	var hood := PackedVector2Array([head + Vector2(-24, 14), head + Vector2(-22, -14), head + Vector2(-4, -26), head + Vector2(16, -20), head + Vector2(24, 4), head + Vector2(14, 20)])
	c.draw_colored_polygon(hood, ROBE_SHADE)
	FighterArt.outline(c, hood, 3.5)
	FighterArt.ball(c, head + Vector2(4, 0), 13.0, SKIN, SKIN_SHADE, Color(0.85, 0.85, 0.82))
	var band := PackedVector2Array([head + Vector2(-8, -8), head + Vector2(18, -6), head + Vector2(18, 2), head + Vector2(-8, 0)])
	c.draw_colored_polygon(band, BANDAGE)
	FighterArt.outline(c, band, 2.5)
	c.draw_line(head + Vector2(-8, -2), head + Vector2(-16, 6 + sin(t * 3.0) * 3.0), BANDAGE, 3.0)   # Loose end
	if dead:
		EnemyArt.ko_eye(c, head + Vector2(10, -3), 3.5, t)
	elif crazed:
		var flick := 0.7 + 0.3 * sin(t * 30.0)
		for ex in [6.0, 14.0]:
			c.draw_circle(head + Vector2(ex, -3), 9.0, Color(CRAZED.r, CRAZED.g, CRAZED.b, 0.3 * flick))
			c.draw_circle(head + Vector2(ex, -3), 3.0, Color(1, 1, 0.8, flick))
		c.draw_line(head + Vector2(2, -6), head + Vector2(10, 0), ROBE_SHADE, 2.0)                  # Torn bandage
	else:
		c.draw_line(head + Vector2(-6, -4), head + Vector2(16, -3), BANDAGE.darkened(0.2), 1.5)     # Wrap lines
	# Mouth: thin grin (crazed = wide open grin with teeth)
	if crazed:
		c.draw_colored_polygon(PackedVector2Array([head + Vector2(2, 6), head + Vector2(16, 5), head + Vector2(10, 11)]), Color(0.2, 0.05, 0.05))
		c.draw_line(head + Vector2(3, 6), head + Vector2(15, 5), Color.WHITE, 1.5)
	else:
		c.draw_line(head + Vector2(4, 7), head + Vector2(14, 6), Color(0.3, 0.2, 0.2), 1.5)

	# Near arm + giant chemical JUG
	var shoulder := chest + Vector2(16, -18)
	var hand := chest + Vector2(34, 22)
	var tilt := 0.0
	match pose_v:
		"throw_tele":
			hand = chest + Vector2(-10, -46)
			tilt = -1.0
		"throw":
			hand = chest + Vector2(54, -30)
			tilt = 1.6
		"pour_tele":
			hand = chest + Vector2(46, -8)
			tilt = 0.4
		"pour":
			hand = chest + Vector2(56, 0)
			tilt = 2.0
		"charge", "charge_tele":
			hand = chest + Vector2(-6, 30)
		"swings", "swings_tele":
			var swing_a := sin(t * 18.0)
			hand = chest + Vector2(40 + 16.0 * swing_a, -10 - 30.0 * swing_a)
			tilt = swing_a
		"smash_tele":
			hand = chest + Vector2(4, -70)                  # Jug raised high overhead
			tilt = PI
		"smash":
			hand = chest + Vector2(62, 46)                  # ...slammed down in front
			tilt = 2.4
	EnemyArt.arm(c, shoulder, hand, 10.0, ROBE, ROBE_SHADE, ROBE_HI, SKIN, 7.0)
	_jug(c, hand + Vector2(10, -6), tilt, t, pose_v == "pour")
	if pose_v == "smash":
		c.draw_arc(Vector2(70, 0), 30.0 + pt * 220.0, PI, TAU, 18, Color(CHEM.r, CHEM.g, CHEM.b, maxf(0.0, 1.0 - pt * 4.0)), 7.0, FighterArt.AA)
	if pose_v == "throw" and pt < 0.25:
		c.draw_arc(chest + Vector2(20, -10), 70.0, -2.2, 0.2, 14, Color(CHEM.r, CHEM.g, CHEM.b, 0.8 - pt * 3.0), 7.0, FighterArt.AA)


static func _vial(c: CanvasItem, p: Vector2, _tilt: float, t: float) -> void:
	var body := FighterArt.rrect_points(Rect2(p.x - 4, p.y - 6, 8, 12), 3.0)
	c.draw_colored_polygon(body, GLASS)
	c.draw_rect(Rect2(p.x - 3, p.y - 1 + sin(t * 4.0), 6, 6), CHEM)
	FighterArt.outline(c, body, 2.0)
	c.draw_line(p + Vector2(0, -6), p + Vector2(0, -9), Color(0.45, 0.3, 0.15), 3.0)


static func _jug(c: CanvasItem, p: Vector2, tilt: float, t: float, pouring: bool) -> void:
	var d := Vector2.from_angle(tilt - PI * 0.5)       # Up direction of the jug
	var n := d.orthogonal()
	var base := p - d * 18.0
	var pts := PackedVector2Array([base + n * 16.0, base - n * 16.0, base - n * 18.0 + d * 26.0, p + d * 18.0 - n * 6.0, p + d * 24.0 - n * 6.0, p + d * 24.0 + n * 6.0, p + d * 18.0 + n * 6.0, base + n * 18.0 + d * 26.0])
	c.draw_colored_polygon(pts, GLASS)
	var liquid := PackedVector2Array([base + n * 15.0, base - n * 15.0, base - n * 16.0 + d * 20.0, base + n * 16.0 + d * 20.0])
	c.draw_colored_polygon(liquid, CHEM)
	c.draw_circle(base + d * 10.0 + n * (6.0 * sin(t * 5.0)), 3.0, CHEM_HI)
	FighterArt.outline(c, pts, 3.0)
	if pouring:                                         # Stream of chemicals to the floor
		var mouth := p + d * 24.0
		c.draw_line(mouth, Vector2(mouth.x + 6.0, 0.0), CHEM, 8.0)
		c.draw_line(mouth, Vector2(mouth.x + 6.0, 0.0), CHEM_HI, 3.0)
