class_name AtomicCreation
extends SimpleEnemy
## ATOMIC CREATION (Story Mode, Colosseum 3, level 14): a big hulking monster built around a
## glowing green ATOMIC CORE, with electron rings orbiting it, cracked lead-gray armour plates
## and radioactive slime dripping off. Fights in a group with Sparklings (small hovering HP
## bar only: it is not a boss). Goes CRITICAL below 50% HP: faster, shorter cooldowns.
##
##   Atomic Slam        10 dmg + shockwaves   BIG: both fists into the floor
##   Radiation Burst    5 dmg + toxic puddles a pulse of radiation around it
##   Atomic Explosion   14 dmg                BIG, long wind-up: the core blows, huge radius

const SLAM_KB := Vector2(420, -360)
const BURST_R := 230.0
const BURST_KB := Vector2(260, -200)
const BOOM_R := 300.0
const BOOM_KB := Vector2(560, -420)

const LEAD := Color(0.36, 0.38, 0.36)
const LEAD_SHADE := Color(0.20, 0.22, 0.20)
const LEAD_HI := Color(0.55, 0.58, 0.55)
const ATOM := Color(0.45, 1.0, 0.25)
const ATOM_HI := Color(0.88, 1.0, 0.70)
const CRIT := Color(1.0, 0.9, 0.2)


func _make_data() -> CharacterData:
	keep_min = 0.0
	keep_max = 140.0
	attack_chance = 0.6
	phase2_threshold = 0.5
	phase2_speed_mult = 1.3
	phase2_cooldown_mult = 0.75
	knockback_scale = 0.4
	var d := SimpleEnemy.make_data("Atomic Creation", 110, Vector2(130, 200), 90.0)
	d.hitstun_time = 0.1
	return d


static func make_patterns() -> Array[EnemyPattern]:
	var list: Array[EnemyPattern] = []
	#                          id        name                cd    dmg  min   max    anim       tele  active rec   big   weights   armored
	list.append(EnemyPattern.make("slam", "ATOMIC SLAM!", 3.0, 10, 0.0, 170.0, "slam", 0.70, 0.20, 0.70, true, [2.0, 2.0], true))
	list.append(EnemyPattern.make("burst", "RADIATION BURST!", 5.0, 5, 0.0, 280.0, "burst", 0.55, 0.30, 0.50, true, [1.3, 1.6], true))
	list.append(EnemyPattern.make("boom", "ATOMIC EXPLOSION!", 10.0, 14, 0.0, 420.0, "boom", 1.30, 0.25, 1.00, true, [0.7, 1.2], true))
	return list


func _on_respawn() -> void:
	super._on_respawn()
	knockback_scale = 0.4


func boss_title() -> String:
	return enemy_name.to_upper() + ("   -   CRITICAL MASS" if enraged else "")


func flavor_lines() -> Array[String]:
	return ["*geiger clicking*", "*HUUUMMM*", "...unstable..."]


func _on_phase_changed(_p: int) -> void:
	Effects.popup(self, global_position + Vector2(0, -260), "CRITICAL!", CRIT, 30)
	SoundManager.play_sfx("roar", -4.0)


func _attack(p: EnemyPattern) -> void:
	match p.id:
		"slam":
			hitbox.activate(make_hit(dmg(p), Vector2(facing * SLAM_KB.x, SLAM_KB.y), "atomic_slam"),
				Vector2(facing * 90.0, -50.0), Vector2(150, 100))
			for d in [-1.0, 1.0]:
				var s := spawn_projectile()
				s.kind = EnemyProjectile.Kind.LINEAR
				s.look = "shock"
				s.tint = ATOM
				s.dir = d
				s.speed = 480.0
				s.lifetime = 0.9
				s.size = Vector2(44, 34)
				s.damage = maxi(1, dmg(p) / 2)
				s.knockback = Vector2(200, -260)
				s.move = "atomic_shock"
				launch(s, global_position + Vector2(facing * 90.0 + d * 60.0, -12.0))
			Effects.shake(self, 12.0)
			SoundManager.play_sfx("slam")
		"burst":
			hit_in_radius(global_position + Vector2(0, -90), BURST_R, dmg(p), BURST_KB, "radiation_burst")
			for off in [-150.0, 150.0]:
				var g: Variant = Effects.ground_below(self, Vector2(global_position.x + off, global_position.y - 40.0), 200.0)
				if g != null:
					ChemicalPool.spawn(self, g, 110.0, 4.0)       # Radioactive puddles
			Effects.shake(self, 6.0)
			SoundManager.play_sfx("beam", -4.0)
		"boom":
			hit_in_radius(global_position + Vector2(0, -90), BOOM_R, dmg(p), BOOM_KB, "atomic_explosion")
			Effects.explosion(self, global_position + Vector2(0, -100), BOOM_R, false, true)
			Effects.shake(self, 18.0)
			SoundManager.play_sfx("explosion")
			SoundManager.play_sfx("ultimate", -6.0)


# ============================================================
# ART (facing right, origin = feet, ~170 x 230)
# ============================================================
func draw_model_on(c: CanvasItem) -> void:
	draw_atomic(c, art_state())


static func draw_portrait(c: CanvasItem, t: float) -> void:
	draw_atomic(c, {"t": t, "pose": "idle"})


static func draw_atomic(c: CanvasItem, s: Dictionary) -> void:
	var t: float = s.get("t", 0.0)
	var pose: String = s.get("pose", "idle")
	var pt: float = s.get("pose_t", 0.0)
	var dead: bool = s.get("dead", false)
	var crit: bool = s.get("enraged", false)
	var glow := CRIT if crit else ATOM
	var charge := clampf(pt / 1.3, 0.0, 1.0) if pose == "boom_tele" else 0.0
	var breathe := sin(t * 2.4) * 3.0
	# Radiation aura
	var pulse := 0.5 + 0.5 * sin(t * (10.0 if crit else 5.0))
	c.draw_circle(Vector2(0, -110), 120.0 + 40.0 * charge + 8.0 * pulse, Color(glow.r, glow.g, glow.b, 0.10 + 0.2 * charge))
	# Stumpy legs
	EnemyArt.legs(c, s, -70.0, 26.0, 22.0, LEAD, LEAD_SHADE, LEAD_HI, LEAD_SHADE, 30.0)
	# Hulking body
	var body := EnemyArt.ellipse_points(Vector2(0, -122 + breathe), 74.0, 66.0, 26)
	c.draw_colored_polygon(body, LEAD)
	c.draw_colored_polygon(EnemyArt.ellipse_points(Vector2(-10, -150 + breathe), 52.0, 26.0, 18), LEAD_HI)
	FighterArt.outline(c, body, 5.0)
	# Armour plates with cracks leaking glow
	for k in 4:
		var a := -PI * 0.5 + (float(k) - 1.5) * 0.9
		var pp := Vector2(0, -122 + breathe) + Vector2.from_angle(a) * 52.0
		var plate := FighterArt.rrect_points(Rect2(pp.x - 16, pp.y - 12, 32, 24), 5.0)
		c.draw_colored_polygon(plate, LEAD_SHADE)
		FighterArt.outline(c, plate, 2.5)
	for k in 3:
		var cx := -40.0 + float(k) * 40.0
		c.draw_polyline(PackedVector2Array([Vector2(cx, -170 + breathe), Vector2(cx + 8, -150 + breathe), Vector2(cx - 4, -130 + breathe)]), glow, 3.0, true)
	# THE CORE: nucleus + orbiting electrons
	var core := Vector2(6, -118 + breathe)
	c.draw_circle(core, 34.0 + 10.0 * charge, Color(glow.r, glow.g, glow.b, 0.35))
	c.draw_circle(core, 24.0, EnemyArt.BLACK)
	c.draw_circle(core, 21.0, glow)
	for k in 5:                                        # Nucleus "protons"
		c.draw_circle(core + Vector2.from_angle(float(k) * 1.3 + t) * 7.0, 6.0, ATOM_HI if k % 2 == 0 else glow.darkened(0.2))
	for k in 3:                                        # Electron rings
		var rot := float(k) * PI / 3.0 + t * 0.4
		var ring := PackedVector2Array()
		for i in 25:
			var a := TAU * float(i) / 24.0
			ring.append(core + Vector2(cos(a) * 58.0, sin(a) * 18.0).rotated(rot))
		c.draw_polyline(ring, Color(glow.r, glow.g, glow.b, 0.6), 2.5, true)
		var ea := t * (3.0 + float(k)) + float(k)
		c.draw_circle(core + Vector2(cos(ea) * 58.0, sin(ea) * 18.0).rotated(rot), 5.0, ATOM_HI)
	# Small head with glowing slits
	var head := Vector2(30, -196 + breathe)
	FighterArt.ball(c, head, 20.0, LEAD, LEAD_SHADE, LEAD_HI)
	if dead:
		EnemyArt.ko_eye(c, head + Vector2(8, -2), 4.0, t)
	else:
		c.draw_line(head + Vector2(0, -3), head + Vector2(16, -4), glow, 4.0)
	# Arms: huge fists
	var fist := Vector2(80, -80 + breathe)
	match pose:
		"slam_tele":
			fist = Vector2(40, -230)
		"slam":
			fist = Vector2(96, -16)
		"burst_tele", "boom_tele":
			fist = Vector2(70, -150)
	EnemyArt.arm(c, Vector2(-50, -140 + breathe), Vector2(-74, -60), 16.0, LEAD_SHADE, LEAD_SHADE.darkened(0.2), LEAD, LEAD_SHADE, 18.0)
	EnemyArt.arm(c, Vector2(48, -150 + breathe), fist, 18.0, LEAD, LEAD_SHADE, LEAD_HI, LEAD, 22.0)
	# Radioactive drips
	for k in 3:
		var fall := fmod(t * 1.2 + float(k) * 0.33, 1.0)
		c.draw_circle(Vector2(-40 + float(k) * 40.0, -70 + fall * 64.0), 4.0 * (1.0 - fall), glow)
	if pose == "slam" and pt < 0.25:
		c.draw_arc(Vector2(96, 0), 30.0 + pt * 300.0, PI, TAU, 18, Color(glow.r, glow.g, glow.b, 1.0 - pt * 4.0), 6.0, true)
	if pose == "burst" and pt < 0.3:
		c.draw_arc(core, 40.0 + pt * 700.0, 0.0, TAU, 32, Color(glow.r, glow.g, glow.b, 0.8 - pt * 2.6), 8.0, true)
