class_name BlasphemyCaeser
extends SimpleEnemy
## BLASPHEMY CAESER - BOSS of Colosseum 2 (Level 12, the Blasphemy Arena).
## A colossal GRAY-SCALED serpent that ate the gods of the old city, magma glowing between
## its scales. Drawn 1.6x bigger than the art units (ART_SCALE). Two phases, each with its
## OWN full HP bar:
##
## PHASE 1 - THE GOD-DEVOURING SERPENT (no crown): coils piled on the arena floor.
##     Fire Breath    3 dmg per fireball   a stream of fire along the floor (block / get out of range)
##     Serpent Bite   9 dmg                lunges forward jaws first
##     Tail Swipe     7 dmg                low sweep on BOTH sides (jump it)
##     Magma Spit     4 dmg + lava pools   globs of magma arc onto you and stay burning
##
## When the serpent's HP hits 0 it does NOT die: TRANSFORM cutscene (StoryManager). The
## serpent GROWS ARMS, a FACE (wearing a burning laurel) pushes out of its NECK, and it
## reaches into its own THROAT and pulls out the BLASPHEMY BLADE - a giant sword covered
## in flesh. PHASE 2 - THE BLASPHEMY BLADE, HP bar refills:
##     Blade Slash       7 dmg x2              two huge swings of the flesh blade
##     Serpent Head Bite 9 dmg                 the serpent head shoots far forward
##     Magma Geysers     8 dmg each            columns of magma erupt under you (watch the cracks)
##     Magma Spit        4 dmg + lava pools    5 globs
##     Lava Pools        burning ground        magma wells up around you
##     Ground Slam       10 dmg + lava pools   heaves itself at you and crashes down
##     Lava Wave         9 dmg                 the blade slams down, a wave of lava rolls along
##                                             the floor (jump it); below half HP a second wave
##                                             rolls the other way
## The Warrior's sword grows during this fight (StoryLevels "sword_power").
## ARENA: StoryLevels map "blasphemy". Death: sinks into the magma (StoryManager "sink").

signal transform_started

const ART_SCALE := 1.6                 # The whole drawing is scaled up this much
## NERFED 2026-11-11: was 280 + 340 (x1.35 Story boss buff = ~840 HP in total, more than some
## Colosseum 5 bosses). Now 210 + 260 (x1.35 = ~635 in total).
const P1_HP := 210
const P2_HP := 260
const P1_BODY := Vector2(260, 320)
const P2_BODY := Vector2(280, 360)
const P1_SPEED := 100.0
const P2_SPEED := 160.0
const DRAW_BLADE_TIME := 1.4           # Pulling the blade out of the throat (phase 2 start)

const BREATH_EVERY := 0.11
const BITE_SPEED := 720.0
const SPIT_FLIGHT := 0.85
const LEAP_TIME := 0.7

const SCALE := Color(0.42, 0.42, 0.45)          # GRAY scales
const SCALE_SHADE := Color(0.24, 0.24, 0.27)
const SCALE_HI := Color(0.64, 0.64, 0.67)
const BELLY := Color(0.80, 0.76, 0.66)
const MAGMA := Color(1.0, 0.45, 0.08)
const MAGMA_HI := Color(1.0, 0.88, 0.45)
const OBSIDIAN := Color(0.13, 0.11, 0.13)
const OBSIDIAN_HI := Color(0.30, 0.26, 0.30)
const SKIN := Color(0.66, 0.60, 0.58)           # The face + arms: pale gray flesh
const SKIN_SHADE := Color(0.44, 0.38, 0.38)
const SKIN_HI := Color(0.80, 0.75, 0.72)
const FLESH := Color(0.72, 0.26, 0.26)          # Blasphemy Blade
const FLESH_SHADE := Color(0.45, 0.10, 0.12)
const FLESH_HI := Color(0.90, 0.50, 0.46)
const VEIN := Color(0.32, 0.04, 0.08)
const BONE := Color(0.92, 0.88, 0.76)
const GOLD := Color(1.0, 0.78, 0.25)

var form := 1
var phase2_subtitle := "PHASE 2  -  THE BLASPHEMY BLADE"
var phase2_line := "Behold...  the BLASPHEMY BLADE."
var transform_banner := "IT GROWS ARMS...  AND A FACE"

var _transforming := false
var _tf_t := 0.0
var _draw_t := 99.0                             # Time since phase 2 began (blade being drawn)
var _breath_t := 0.0
var _swing_n := 0
var _air := false


func _make_data() -> CharacterData:
	keep_min = 180.0
	keep_max = 480.0
	attack_chance = 0.65
	phase2_threshold = -1.0                       # Phases are FORMS here (see take_hit)
	knockback_scale = 0.2
	grab_immune = true
	var d := SimpleEnemy.make_data("Blasphemy Caeser", P1_HP, P1_BODY, P1_SPEED)
	d.hitstun_time = 0.08
	d.respawn_delay = 99.0
	return d


static func make_patterns() -> Array[EnemyPattern]:
	var list: Array[EnemyPattern] = []
	#                          id          name                  cd    dmg  min    max     anim        tele  active rec   big   weights [P1,P2] armored
	# ----- PHASE 1: the serpent -----
	list.append(EnemyPattern.make("breath", "FIRE BREATH!", 4.5, 3, 0.0, 640.0, "breath", 0.70, 1.10, 0.60, true, [1.6, 0.0], true))
	list.append(EnemyPattern.make("bite", "SERPENT BITE!", 2.8, 9, 0.0, 440.0, "bite", 0.55, 0.40, 0.60, true, [2.0, 0.0], true))
	list.append(EnemyPattern.make("tail", "TAIL SWIPE!", 3.5, 7, 0.0, 380.0, "tail", 0.50, 0.30, 0.50, true, [1.6, 0.0], true))
	list.append(EnemyPattern.make("spit", "MAGMA SPIT!", 4.0, 4, 200.0, 1000.0, "spit", 0.60, 0.30, 0.50, true, [1.5, 1.0], true))
	# ----- PHASE 2: arms, a face and the Blasphemy Blade -----
	list.append(EnemyPattern.make("slash", "BLADE SLASH!", 2.6, 6, 0.0, 330.0, "slash", 0.45, 0.60, 0.50, true, [0.0, 2.6], true))
	list.append(EnemyPattern.make("headbite", "SERPENT HEAD BITE!", 3.2, 9, 180.0, 560.0, "headbite", 0.60, 0.35, 0.60, true, [0.0, 1.8], true))
	list.append(EnemyPattern.make("geysers", "MAGMA GEYSERS!", 6.0, 8, 0.0, 1400.0, "geysers", 0.60, 1.20, 0.50, true, [0.0, 1.5], true))
	list.append(EnemyPattern.make("pools", "LAVA POOLS!", 8.0, 0, 0.0, 1000.0, "geysers", 0.50, 0.40, 0.40, true, [0.0, 0.9], true))
	list.append(EnemyPattern.make("slam", "GROUND SLAM!", 5.5, 8, 150.0, 700.0, "slam", 0.50, 1.00, 0.60, true, [0.0, 1.5], true))
	list.append(EnemyPattern.make("wave", "LAVA WAVE!", 5.0, 8, 0.0, 1000.0, "wave", 0.65, 0.30, 0.60, true, [0.0, 1.6], true))
	list[2].note = "low sweep on both sides: jump it"
	list[9].note = "phase 2: rolls along the floor, jump it"
	return list


func _ready() -> void:
	super._ready()
	visuals.scale = Vector2(facing * ART_SCALE, ART_SCALE)


func boss_title() -> String:
	if form == 1:
		return "BLASPHEMY CAESER   -   THE GOD-DEVOURING SERPENT"
	return "BLASPHEMY CAESER   -   PHASE 2: THE BLASPHEMY BLADE"


func custom_death_type(_hit: HitData) -> String:
	return DeathManager.CUTSCENE


func flavor_lines() -> Array[String]:
	if form == 1:
		return ["*hisssss*", "I can smell the god in you...", "*the coils grind*"]
	return ["KNEEL before your emperor!", "Every god I ate screams in this blade.", "BURN!"]


func jump(_force_mult: float = 1.0) -> void:
	pass                                          # Only the Ground Slam leaves the floor


# ============================================================
# TRANSFORMATION (phase 1 HP 0 -> phase 2)
# ============================================================
func take_hit(amount: int, hit: HitData) -> void:
	if _transforming:
		return
	if form == 1 and amount >= hp:
		super.take_hit(maxi(hp - 1, 0), hit)       # The serpent never dies here: it CHANGES
		_begin_transform()
		return
	super.take_hit(amount, hit)


func _begin_transform() -> void:
	if _transforming or is_dead:
		return
	_transforming = true
	_tf_t = 0.0
	_cancel_pattern()
	move_dir = 0.0
	velocity = Vector2.ZERO
	hurtbox.set_deferred("monitorable", false)
	ChemicalPool.dry_all()
	if transform_started.get_connections().is_empty():
		finish_transform()                         # No cutscene director (testing): just change
	else:
		transform_started.emit()


## Called by StoryManager in the middle of the transform cutscene.
func finish_transform() -> void:
	form = 2
	phase = 2
	enraged = true
	_draw_t = 0.0                                  # Starts pulling the blade out of its throat
	data.max_hp = roundi(float(P2_HP) * boss_hp_mult)   # Story boss buff carries over
	hp = data.max_hp
	data.body_size = P2_BODY
	data.move_speed = P2_SPEED
	speed = P2_SPEED
	hurtbox.resize(P2_BODY)
	var col := get_node_or_null("CollisionShape2D") as CollisionShape2D
	if col != null and col.shape is RectangleShape2D:
		(col.shape as RectangleShape2D).size = P2_BODY
		col.position = Vector2(0, -P2_BODY.y * 0.5)
	if hud != null:
		hud.position = Vector2(0, -P2_BODY.y - 34.0)
	keep_min = 0.0
	keep_max = 260.0
	attack_chance = 0.75
	cooldown_mult = 0.9
	knockback_scale = 0.3
	for p in patterns:
		p.cooldown_left = 0.8
	health_changed.emit(hp, data.max_hp)
	hurtbox.set_deferred("monitorable", true)
	_transforming = false
	pose = "idle"
	SoundManager.play_sfx("bite", -2.0)
	SoundManager.play_sfx("sword_slash", -2.0)


## Transform + blade-drawing animations run even while the fight is paused (cutscene).
func _process(delta: float) -> void:
	if _transforming:
		_tf_t += delta
		visuals.queue_redraw()
	if _draw_t < DRAW_BLADE_TIME + 0.2:
		_draw_t += delta
		visuals.queue_redraw()


# ============================================================
# ATTACKS (art units x ART_SCALE = world pixels)
# ============================================================
func _floor_y() -> float:
	return global_position.y


func _attack(p: EnemyPattern) -> void:
	match p.id:
		# ---------- phase 1 ----------
		"breath":
			_breath_t = 0.0
			SoundManager.play_sfx("flame")
		"bite":
			hitbox.activate(make_hit(dmg(p), Vector2(facing * 420.0, -260.0), "caeser_bite"),
				Vector2(facing * 210.0, -140.0), Vector2(200, 170))
			SoundManager.play_sfx("bite")
		"tail":
			hitbox.activate(make_hit(dmg(p), Vector2(facing * 380.0, -300.0), "caeser_tail"),
				Vector2(0, -40.0), Vector2(820, 80))
			Effects.shake(self, 10.0)
			SoundManager.play_sfx("whoosh")
		"spit":
			var n := 5 if form == 2 else 3
			for k in n:
				var spread := (float(k) - float(n - 1) * 0.5) * 120.0 + randf_range(-20.0, 20.0)
				_spit_glob(target_x() + spread, dmg(p))
			SoundManager.play_sfx("void_goo", -3.0)
		# ---------- phase 2 ----------
		"slash":
			_swing_n = 0
			_slash(p)
		"headbite":
			hitbox.activate(make_hit(dmg(p), Vector2(facing * 420.0, -240.0), "caeser_headbite"),
				Vector2(facing * 360.0, -220.0), Vector2(320, 130))
			SoundManager.play_sfx("bite")
			SoundManager.play_sfx("dash", -6.0)
		"geysers":
			var tx := target_x()
			var order := [0.0, -170.0, 170.0, -340.0, 340.0]
			for k in order.size():
				var x := _clamp_arena(tx + float(order[k]))
				BossHazard.spawn(self, "geyser", Vector2(x, _floor_y()), 0.75 + 0.18 * float(k), dmg(p), Vector2(240, -520))
			Effects.shake(self, 8.0)
			SoundManager.play_sfx("rumble", -3.0)
		"pools":
			var tx := target_x()
			for off in [0.0, -240.0, 240.0]:
				_lava_pool(_clamp_arena(tx + off), 170.0, 5.5)
			Effects.shake(self, 6.0)
			SoundManager.play_sfx("rumble", -4.0)
		"slam":
			var dx := clampf(target_x() - global_position.x, -560.0, 560.0)
			velocity = Vector2(dx / LEAP_TIME, -760.0)
			_air = false
			SoundManager.play_sfx("whoosh")
		"wave":
			_lava_wave(float(facing), dmg(p))
			if hp <= data.max_hp * 0.5:
				_lava_wave(-float(facing), dmg(p))
			Effects.shake(self, 14.0)
			SoundManager.play_sfx("slam")
			SoundManager.play_sfx("geyser", -4.0)


func _on_attack_update(p: EnemyPattern, delta: float) -> void:
	match p.id:
		"breath":
			_breath_t -= delta
			if _breath_t <= 0.0:
				_breath_t = BREATH_EVERY
				_fireball(dmg(p))
		"bite":
			velocity.x = facing * BITE_SPEED * (1.0 - state_time / maxf(state_len, 0.01))
			if is_on_wall() or not ground_ahead(120.0):
				velocity.x = 0.0
		"slash":
			if _swing_n < 2 and state_time >= 0.3:
				_slash(p)
		"slam":
			if not is_on_floor():
				_air = true
			elif _air:
				_land_slam(p)
				state_time = state_len


func _on_attack_end(p: EnemyPattern) -> void:
	if p.id == "bite" or p.id == "slam":
		velocity.x = 0.0


func _owns_velocity_x() -> bool:
	return estate == EState.ATTACK and current != null and (current.id == "bite" or current.id == "slam")


func _slash(p: EnemyPattern) -> void:
	_swing_n += 1
	pose_t = 0.0
	hitbox.activate(make_hit(dmg(p), Vector2(facing * 380.0, -240.0), "caeser_slash"),
		Vector2(facing * 190.0, -170.0), Vector2(300, 280))
	velocity.x += facing * 160.0
	Effects.shake(self, 6.0)
	SoundManager.play_sfx("sword_slash")
	SoundManager.play_sfx("bite", -10.0)


func _land_slam(p: EnemyPattern) -> void:
	hit_in_radius(global_position + Vector2(0, -60), 240.0, dmg(p), Vector2(460, -420), "caeser_slam")
	_lava_pool(global_position.x - 200.0, 150.0, 4.5)
	_lava_pool(global_position.x + 200.0, 150.0, 4.5)
	Effects.explosion(self, global_position + Vector2(0, -40), 230.0, true, true)
	Effects.shake(self, 20.0)
	SoundManager.play_sfx("slam")
	SoundManager.play_sfx("explosion", -3.0)


func _fireball(damage: int) -> void:
	var f := spawn_projectile()
	f.kind = EnemyProjectile.Kind.LINEAR
	f.look = "fireball"
	f.dir = float(facing)
	f.speed = 660.0
	f.lifetime = 0.9
	f.size = Vector2(44, 48)
	f.damage = damage
	f.knockback = Vector2(160, -90)
	f.pierce = false
	f.move = "caeser_breath"
	launch(f, global_position + Vector2(facing * 240.0, -84.0 + randf_range(-14.0, 14.0)))


func _spit_glob(to_x: float, damage: int) -> void:
	var g := spawn_projectile()
	g.kind = EnemyProjectile.Kind.ARC
	g.look = "magma"
	g.damage = damage
	g.knockback = Vector2(170, -110)
	g.radius = 36.0
	g.pierce = false
	g.size = Vector2(28, 28)
	g.lifetime = 3.0
	g.move = "magma_spit"
	var from := global_position + Vector2(facing * 180.0, -340.0)
	var drop := _floor_y() - from.y
	var t := SPIT_FLIGHT
	g.arc_velocity = Vector2((to_x - from.x) / t, (drop - 0.5 * EnemyProjectile.ARC_GRAVITY * t * t) / t)
	g.on_land = _on_glob_landed
	launch(g, from)


func _on_glob_landed(pos: Vector2) -> void:
	if is_instance_valid(self) and not is_dead:
		ChemicalPool.spawn_lava(self, pos, 130.0, 5.0)


func _lava_pool(x: float, w: float, life: float) -> void:
	var g: Variant = Effects.ground_below(self, Vector2(x, global_position.y - 40.0), 200.0)
	if g != null:
		ChemicalPool.spawn_lava(self, g, w, life)


func _lava_wave(d: float, damage: int) -> void:
	var w := spawn_projectile()
	w.kind = EnemyProjectile.Kind.LINEAR
	w.look = "lava_wave"
	w.dir = d
	w.speed = 520.0
	w.lifetime = 1.8
	w.size = Vector2(60, 84)
	w.damage = damage
	w.knockback = Vector2(320, -380)
	w.move = "lava_wave"
	launch(w, Vector2(global_position.x + d * 190.0, _floor_y()))


func _clamp_arena(x: float) -> float:
	if StoryManager.has_walls:
		return clampf(x, StoryManager.arena_left() + 60.0, StoryManager.arena_right() - 60.0)
	return clamp_to_ground(x)


func _update_visuals(delta: float) -> void:
	if form == 2:
		anim_time += delta * 0.3                     # Phase 2 moves with fury
	super._update_visuals(delta)
	visuals.scale = Vector2(facing * ART_SCALE, ART_SCALE)   # BaseEnemy resets it to 1


# ============================================================
# ART (facing right, origin = feet; art units, the node is scaled by ART_SCALE)
# ============================================================
func draw_model_on(c: CanvasItem) -> void:
	var s := art_state()
	s["swing"] = _swing_n
	s["tf"] = _tf_t if _transforming else -1.0
	s["armed"] = form == 2
	s["blade_k"] = clampf(_draw_t / DRAW_BLADE_TIME, 0.0, 1.0) if form == 2 else 0.0
	draw_caeser(c, s)


static func draw_portrait(c: CanvasItem, t: float) -> void:
	draw_caeser(c, {"t": t, "pose": "idle", "tf": -1.0})


static func draw_caeser(c: CanvasItem, s: Dictionary) -> void:
	var t: float = s.get("t", 0.0)
	var pose_v: String = s.get("pose", "idle")
	var pt: float = s.get("pose_t", 0.0)
	var dead: bool = s.get("dead", false)
	var tf: float = s.get("tf", -1.0)
	var armed: bool = s.get("armed", false)
	var blade_k: float = s.get("blade_k", 1.0)
	var swing: int = s.get("swing", 0)
	var sway := sin(t * 1.4) * 6.0

	# How far the phase-2 body has grown (arms, face): 0 = plain serpent
	var arms_k := 1.0 if armed else (clampf((tf - 0.3) / 0.9, 0.0, 1.0) if tf >= 0.0 else 0.0)
	var face_k := 1.0 if armed else (clampf((tf - 0.9) / 0.7, 0.0, 1.0) if tf >= 0.0 else 0.0)

	# Head position by pose
	var head := Vector2(96 + sway * 0.5, -196 + sin(t * 2.0) * 5.0)
	var jaw := 0.15
	match pose_v:
		"breath_tele":
			head = Vector2(60, -230)
			jaw = 0.5
		"breath":
			head = Vector2(128, -62)
			jaw = 0.9
		"bite_tele", "headbite_tele":
			head = Vector2(40, -240)
			jaw = 0.6
		"bite":
			head = Vector2(150, -96)
			jaw = 1.0 if pt < 0.12 else 0.05
		"headbite":
			head = Vector2(230, -130)
			jaw = 1.0 if pt < 0.12 else 0.05
		"spit_tele":
			head = Vector2(70, -250)
			jaw = 0.3
		"spit":
			head = Vector2(110, -220)
			jaw = 1.0
		"tail_tele":
			head = Vector2(70, -170)
	if tf >= 0.0:                                                    # Writhing during the transform
		head = Vector2(80 + sin(tf * 14.0) * 20.0, -200 - minf(tf, 2.0) * 20.0)
		jaw = 1.0 if tf > 1.5 else 0.6
	if armed and blade_k < 1.0:
		jaw = 1.0                                                    # Throat wide open: the blade comes out

	# Magma glow under the coils
	c.draw_colored_polygon(EnemyArt.ellipse_points(Vector2(-30, -4), 190.0, 38.0, 24), Color(MAGMA.r, MAGMA.g, MAGMA.b, 0.25))

	# Tail: sweeps out to both sides on the Tail Swipe
	var tail_tip := Vector2(-250, -30 + sin(t * 3.0) * 8.0)
	if pose_v == "tail_tele":
		tail_tip = Vector2(-200, -90)
	elif pose_v == "tail":
		var k := clampf(pt / 0.3, 0.0, 1.0)
		tail_tip = Vector2(-260 + 560.0 * k, -26)
	_body_tube(c, [Vector2(-90, -40), Vector2(-170, -30), tail_tip], 34.0, 8.0, t)

	# Coils piled on the floor (three rings, back to front)
	for k in 3:
		var cy := -38.0 - float(k) * 34.0
		var w := 120.0 - float(k) * 22.0
		var ring := EnemyArt.ellipse_points(Vector2(-40 + float(k) * 6.0, cy), w, 34.0, 26)
		c.draw_colored_polygon(ring, SCALE if k % 2 == 0 else SCALE_SHADE)
		c.draw_colored_polygon(EnemyArt.ellipse_points(Vector2(-40 + float(k) * 6.0, cy - 14.0), w * 0.8, 10.0, 18), SCALE_HI)
		for m in 6:                                                   # Magma between the scales
			var mx := -40.0 + float(k) * 6.0 + (float(m) - 2.5) * w * 0.3
			c.draw_line(Vector2(mx - 6.0, cy + 6.0), Vector2(mx + 6.0, cy + 14.0), Color(MAGMA.r, MAGMA.g, MAGMA.b, 0.6 + 0.4 * sin(t * 4.0 + float(m))), 3.0)
		for m in 8:                                                   # Scale pattern
			var sx := -40.0 + float(k) * 6.0 + (float(m) - 3.5) * w * 0.22
			c.draw_arc(Vector2(sx, cy - 4.0), 7.0, 0.2, PI - 0.2, 6, SCALE_SHADE, 2.0)
		FighterArt.outline(c, ring, 5.0)

	# Neck: from the top coil up to the head
	var neck_base := Vector2(10, -110)
	var mid := neck_base.lerp(head, 0.5) + Vector2(-30, -10)
	_body_tube(c, [neck_base, mid, head + Vector2(-20, 14)], 40.0, 28.0, t)

	# ---- PHASE 2 BODY: the FAR arm (behind the face) ----
	var face := neck_base.lerp(mid, 0.75) + Vector2(10, 0)
	var far_sh := face + Vector2(-22, 14)
	var near_sh := face + Vector2(20, 22)
	if arms_k > 0.0:
		var claw := far_sh + Vector2(46, 34) * arms_k
		if pose_v == "geysers_tele" or pose_v == "geysers":
			claw = far_sh + Vector2(30, 70) * arms_k                 # Hand pressed into the floor
		_flesh_arm(c, far_sh, claw, 11.0 * arms_k, true)

	# Head: wedge skull, horns, molten eyes (NO crown on the serpent head)
	var hd := PackedVector2Array([head + Vector2(-42, -26), head + Vector2(10, -38), head + Vector2(62, -14), head + Vector2(70, 0),
		head + Vector2(30, 6), head + Vector2(-40, 18)])
	c.draw_colored_polygon(hd, SCALE)
	c.draw_colored_polygon(PackedVector2Array([head + Vector2(-34, -20), head + Vector2(10, -32), head + Vector2(50, -14), head + Vector2(0, -10)]), SCALE_HI)
	var jaw_pts := PackedVector2Array([head + Vector2(-30, 14), head + Vector2(28, 8 + jaw * 30.0), head + Vector2(62, 10 + jaw * 40.0),
		head + Vector2(56, 22 + jaw * 42.0), head + Vector2(-26, 30)])
	if jaw > 0.2:                                                     # Fiery throat
		c.draw_colored_polygon(PackedVector2Array([head + Vector2(-10, 6), head + Vector2(66, 2), head + Vector2(60, 12 + jaw * 40.0), head + Vector2(-10, 22)]), MAGMA)
		c.draw_circle(head + Vector2(10, 12 + jaw * 10.0), 8.0 + jaw * 6.0, MAGMA_HI)
	c.draw_colored_polygon(jaw_pts, BELLY)
	FighterArt.outline(c, jaw_pts, 3.5)
	for k in 5:                                                       # Fangs
		var fx := 10.0 + float(k) * 11.0
		c.draw_colored_polygon(PackedVector2Array([head + Vector2(fx, 2 - float(k) * 0.5), head + Vector2(fx + 5, 2 - float(k) * 0.5), head + Vector2(fx + 2, 14 + (8.0 if k == 0 else 0.0))]), Color(1, 0.97, 0.88))
	FighterArt.outline(c, hd, 4.5)
	for hk in 2:                                                      # Horns swept back
		var hb := head + Vector2(-18 + float(hk) * 18.0, -30)
		FighterArt.curved_spike(c, hb, hb + Vector2(-60 + float(hk) * 10.0, -30 - float(hk) * 10.0), 8.0, OBSIDIAN_HI, OBSIDIAN, 0.3)
	if dead:
		EnemyArt.ko_eye(c, head + Vector2(26, -14), 5.0, t)
	else:
		c.draw_circle(head + Vector2(26, -14), 10.0, Color(MAGMA.r, MAGMA.g, MAGMA.b, 0.35))
		c.draw_colored_polygon(EnemyArt.ellipse_points(head + Vector2(26, -14), 7.0, 4.0, 12), MAGMA_HI)
		c.draw_line(head + Vector2(26, -18), head + Vector2(26, -10), EnemyArt.BLACK, 2.0)

	# ---- PHASE 2 BODY: the FACE in the neck (crowned) + the near arm + the BLADE ----
	if face_k > 0.0:
		_neck_face(c, face, face_k, t, dead)
	if arms_k > 0.0:
		var hand := near_sh + Vector2(44, 30) * arms_k
		var ang := -1.1
		var length := 1.0
		if tf >= 0.0 and tf > 1.6:                                    # Reaching into its own throat
			hand = near_sh.lerp(head + Vector2(30, 16), clampf((tf - 1.6) / 0.4, 0.0, 1.0))
			length = 0.0
		elif armed and blade_k < 1.0:                                 # Pulling the blade OUT of the throat
			var mouth := head + Vector2(30, 16)
			hand = mouth.lerp(near_sh + Vector2(60, 10), blade_k)
			ang = lerpf(PI + 0.5, -1.1, blade_k)                       # Blade still inside, then swung out
			length = blade_k
		elif armed:
			match pose_v:
				"slash_tele":
					hand = near_sh + Vector2(-10, -40)
					ang = -2.4
				"slash":
					var k := clampf(pt / 0.18, 0.0, 1.0)
					if swing % 2 == 1:
						hand = near_sh + Vector2(70, 10)
						ang = lerpf(-2.2, 0.6, k)
					else:
						hand = near_sh + Vector2(66, 30)
						ang = lerpf(0.8, -1.0, k)
				"slam_tele", "slam":
					hand = near_sh + Vector2(0, -60)
					ang = -1.7
				"wave_tele":
					hand = near_sh + Vector2(-6, -56)
					ang = -2.0
				"wave":
					hand = near_sh + Vector2(70, 60)
					ang = 0.9
				"geysers_tele", "geysers":
					hand = near_sh + Vector2(40, 70)
					ang = PI * 0.5                                         # Plunged into the floor
		if armed and length > 0.0:
			_blasphemy_blade(c, hand, ang, length, t)
		_flesh_arm(c, near_sh, hand, 12.0 * arms_k, false)
		if armed and pose_v == "slash" and pt < 0.22:                   # Slash arc
			var a0 := -2.2 if swing % 2 == 1 else 0.8
			var a1 := 0.6 if swing % 2 == 1 else -1.0
			c.draw_arc(near_sh + Vector2(40, 10), 200.0, minf(a0, a1), maxf(a0, a1), 18, Color(1.0, 0.5, 0.4, 0.85 - pt * 3.5), 16.0, FighterArt.AA)

	if (pose_v == "bite" or pose_v == "headbite") and pt < 0.2:
		c.draw_arc(head + Vector2(70, 10), 30.0 + pt * 200.0, -1.2, 1.2, 12, Color(1, 0.9, 0.6, 0.8 - pt * 4.0), 5.0, FighterArt.AA)
	if tf >= 0.0:                                                     # Light and heat pouring out
		var k := clampf(tf / 2.2, 0.0, 1.0)
		c.draw_circle(face, 40.0 + 80.0 * k, Color(1.0, 0.6, 0.2, 0.15 + 0.25 * k))


## A face pushing out of the serpent's neck: pale gray flesh, hollow glowing eyes,
## screaming mouth, a burning laurel crown. k = how far it has emerged (0..1).
static func _neck_face(c: CanvasItem, p: Vector2, k: float, t: float, dead: bool) -> void:
	var r := Vector2(16.0, 21.0) * (0.4 + 0.6 * k)
	var oval := EnemyArt.ellipse_points(p, r.x, r.y, 18)
	c.draw_colored_polygon(oval, SKIN)
	c.draw_colored_polygon(EnemyArt.ellipse_points(p + Vector2(-3, -5), r.x * 0.6, r.y * 0.5, 12), Color(SKIN_HI.r, SKIN_HI.g, SKIN_HI.b, 0.6))
	FighterArt.outline(c, oval, 3.0)
	if k < 0.4:
		return
	for ex in [-6.0, 7.0]:                                            # Hollow eyes
		c.draw_colored_polygon(EnemyArt.ellipse_points(p + Vector2(ex, -5), 4.5, 3.5, 10), EnemyArt.BLACK)
		if not dead:
			c.draw_circle(p + Vector2(ex, -5), 2.0, MAGMA_HI)
	var open := 4.0 + 3.0 * (0.5 + 0.5 * sin(t * 5.0))
	c.draw_colored_polygon(EnemyArt.ellipse_points(p + Vector2(1, 9), 5.0, open, 10), Color(0.2, 0.02, 0.03))
	c.draw_line(p + Vector2(-2, -1), p + Vector2(0, 4), SKIN_SHADE, 2.0)   # Nose
	if k > 0.8:
		_laurel(c, p + Vector2(0, -r.y - 2.0), 30.0, t)


## Muscular gray-flesh arm with clawed fingers.
static func _flesh_arm(c: CanvasItem, shoulder: Vector2, hand: Vector2, w: float, far: bool) -> void:
	if w <= 1.0:
		return
	var col := SKIN_SHADE if far else SKIN
	var elbow := shoulder.lerp(hand, 0.5) + Vector2(-6, 10)
	FighterArt.limb(c, shoulder, elbow, w, col, SKIN_SHADE, SKIN_HI)
	FighterArt.limb(c, elbow, hand, w * 0.9, col, SKIN_SHADE, SKIN_HI)
	FighterArt.ball(c, hand, w * 0.75, col, SKIN_SHADE, SKIN_HI)
	for f in 3:
		var d := Vector2.from_angle(-0.6 + float(f) * 0.5)
		c.draw_line(hand + d * w * 0.6, hand + d * w * 1.4, OBSIDIAN, 3.0)


## THE BLASPHEMY BLADE: a giant sword wrapped in living flesh - meat, veins, bone
## showing through, teeth along the edge. hand = grip, ang = blade direction,
## length 0..1 (how much of it is out of the throat).
static func _blasphemy_blade(c: CanvasItem, hand: Vector2, ang: float, length: float, t: float) -> void:
	var d := Vector2.from_angle(ang)
	var n := d.orthogonal()
	var L := 230.0 * length
	var guard := hand + d * 16.0
	var tip := guard + d * L
	# Bone grip + a knot of flesh as the guard
	c.draw_line(hand - d * 30.0, guard, EnemyArt.BLACK, 12.0)
	c.draw_line(hand - d * 30.0, guard, BONE, 7.0)
	FighterArt.ball(c, hand - d * 32.0, 8.0, FLESH, FLESH_SHADE, FLESH_HI)
	if L < 6.0:
		return
	# Blade body: bone core under a layer of flesh, slightly lumpy
	var top := PackedVector2Array()
	var bot := PackedVector2Array()
	for i in 9:
		var u := float(i) / 8.0
		var half := lerpf(20.0, 6.0, u) * (1.0 + 0.12 * sin(u * 17.0 + t * 3.0))
		var p := guard + d * L * u
		top.append(p + n * half)
		bot.append(p - n * half * 0.9)
	var poly := top.duplicate()
	poly.append(tip + d * 12.0)
	for i in range(bot.size() - 1, -1, -1):
		poly.append(bot[i])
	c.draw_colored_polygon(poly, FLESH)
	var inner := PackedVector2Array()
	for i in 9:
		var u := float(i) / 8.0
		inner.append(guard + d * L * u + n * lerpf(8.0, 2.0, u))
	for i in range(8, -1, -1):
		var u := float(i) / 8.0
		inner.append(guard + d * L * u - n * lerpf(5.0, 1.0, u))
	c.draw_colored_polygon(inner, FLESH_HI)
	# Bone ridge showing through along the spine of the blade
	c.draw_line(guard + d * 10.0, guard + d * L * 0.9, BONE, 4.0)
	# Veins
	for v in 4:
		var u0 := 0.1 + float(v) * 0.2
		var pts := PackedVector2Array()
		for j in 4:
			var u := u0 + float(j) * 0.04
			pts.append(guard + d * L * u + n * (sin(float(j) * 2.0 + float(v)) * 9.0))
		c.draw_polyline(pts, VEIN, 2.5, FighterArt.AA)
	# Teeth along the lower edge, an eye in the flesh
	for k in 6:
		var u := 0.15 + float(k) * 0.13
		var base := guard + d * L * u - n * lerpf(18.0, 6.0, u) * 0.9
		c.draw_colored_polygon(PackedVector2Array([base + d * 4.0, base - d * 4.0, base - n * 9.0]), BONE)
	var eye := guard + d * L * 0.3 + n * 4.0
	c.draw_colored_polygon(EnemyArt.ellipse_points(eye, 6.0, 4.0, 10), Color(0.95, 0.9, 0.8))
	c.draw_circle(eye + d * (sin(t * 2.0) * 2.0), 2.5, MAGMA)
	FighterArt.outline(c, poly, 4.0)
	# Dripping blood
	for k in 3:
		var dp := guard + d * L * (0.3 + float(k) * 0.25)
		var fall := fmod(t * 1.5 + float(k) * 0.37, 1.0)
		c.draw_circle(dp + Vector2(0, 10.0 + fall * 30.0), 3.5 * (1.0 - fall), FLESH_SHADE)


## Thick scaly tube through points (serpent body / neck), with a belly stripe.
static func _body_tube(c: CanvasItem, pts_in: Array, w0: float, w1: float, t: float) -> void:
	var line := PackedVector2Array()
	for i in pts_in.size() - 1:
		var a: Vector2 = pts_in[i]
		var b: Vector2 = pts_in[i + 1]
		for k in 6:
			line.append(a.lerp(b, float(k) / 6.0))
	line.append(pts_in[pts_in.size() - 1])
	for i in line.size() - 1:
		var k := float(i) / float(line.size() - 1)
		var w := lerpf(w0, w1, k)
		c.draw_line(line[i], line[i + 1], EnemyArt.BLACK, w * 2.0 + 8.0)
	for i in line.size() - 1:
		var k := float(i) / float(line.size() - 1)
		var w := lerpf(w0, w1, k)
		c.draw_line(line[i], line[i + 1], SCALE, w * 2.0)
		c.draw_line(line[i] + Vector2(0, w * 0.45), line[i + 1] + Vector2(0, w * 0.45), BELLY, w * 0.6)
		if i % 2 == 0:
			c.draw_circle(line[i] + Vector2(0, -w * 0.4), w * 0.25, Color(MAGMA.r, MAGMA.g, MAGMA.b, 0.5 + 0.3 * sin(t * 3.0 + float(i))))


## Burning golden laurel crown (worn by the face in the neck, phase 2 only).
static func _laurel(c: CanvasItem, p: Vector2, w: float, t: float) -> void:
	c.draw_arc(p + Vector2(0, 10), w * 0.6, PI * 1.05, PI * 1.95, 12, EnemyArt.BLACK, 7.0, FighterArt.AA)
	c.draw_arc(p + Vector2(0, 10), w * 0.6, PI * 1.05, PI * 1.95, 12, GOLD, 4.0, FighterArt.AA)
	for i in 7:
		var a := PI * (1.1 + 0.8 * float(i) / 6.0)
		var base := p + Vector2(0, 10) + Vector2.from_angle(a) * w * 0.6
		var leaf := EnemyArt.ellipse_points(base + Vector2.from_angle(a) * 6.0, 5.0, 3.0, 8)
		c.draw_colored_polygon(leaf, GOLD)
		var fl := 6.0 + 4.0 * sin(t * 9.0 + float(i) * 1.7)
		c.draw_colored_polygon(PackedVector2Array([base + Vector2(-3, -2), base + Vector2(3, -2), base + Vector2(0, -2 - fl)]), Color(1.0, 0.55, 0.1, 0.85))
