class_name VoidMassacre
extends SimpleEnemy
## THE VOID MASSACRE - BOSS of Colosseum 4 (Level 24, the Spider Lair).
## A huge spider made of void: a glossy black body with violet sheen, SIXTEEN white eyes
## clustered on its head and SIXTEEN long spider legs. Below 50% HP it goes into a FRENZY.
##
##   Ceiling Drop    12 dmg              BIG: climbs the wall, crawls along the ceiling above you,
##                                       then DROPS (watch the shadow on the floor)
##   Void Goo Spit   4 dmg + goo pools   arcs globs of void goo; the pools hurt and slow you
##   Leg Slam        10 dmg              BIG: rears its front legs and slams them down
##   Eye Beam        7 dmg               beams of white light from its eyes along the floor
##   Void Charge     11 dmg              BIG: charges across the whole arena
##
## THE SHINING CHOICE (StoryManager._apply_void_mod -> apply_void_mod):
##   "weak"   (you killed The Shining): less HP and damage, slower, less aggressive
##   "strong" (you left it):            more HP and damage, faster, VIGOROUS: more goo, triple
##                                       eye beams, and it charges back after hitting a wall

const CEILING_UP := 520.0               # How high the "ceiling" is above the floor
const WALL_GAP := 140.0                 # Distance kept from the wall while climbing
const CHARGE_SPEED := 820.0
const GOO_FLIGHT := 0.8

const BODY := Color(0.06, 0.04, 0.09)
const BODY_HI := Color(0.30, 0.16, 0.48)
const SHEEN := Color(0.55, 0.30, 0.90)
const EYE := Color(0.97, 0.97, 1.0)
const LEG := Color(0.08, 0.06, 0.11)

var vigor := ""                          # "", "weak" or "strong" (The Shining choice)
var _spd_mod := 1.0
var _cd_mod := 1.0
var _climbing := false
var _climb_start := Vector2.ZERO
var _climb_wall_x := 0.0
var _floor_y := 0.0
var _shadow: Node2D
var _beams_fired := 0
var _turned := false


func _make_data() -> CharacterData:
	keep_min = 0.0
	keep_max = 200.0
	attack_chance = 0.7
	phase2_threshold = 0.5
	phase2_speed_mult = 1.25
	phase2_cooldown_mult = 0.75
	knockback_scale = 0.05
	grab_immune = true
	var d := SimpleEnemy.make_data("The Void Massacre", 320, Vector2(240, 150), 150.0)
	d.hitstun_time = 0.04
	d.respawn_delay = 99.0
	return d


static func make_patterns() -> Array[EnemyPattern]:
	var list: Array[EnemyPattern] = []
	#                          id         name               cd    dmg  min    max     anim       tele  active rec   big   weights [P1,P2] armored
	list.append(EnemyPattern.make("ceiling", "CEILING DROP!", 7.0, 12, 0.0, 99999.0, "ceiling", 0.40, 2.40, 0.80, true, [1.0, 1.4], true))
	list.append(EnemyPattern.make("goo", "VOID GOO SPIT!", 4.5, 4, 150.0, 1100.0, "goo", 0.55, 0.30, 0.50, true, [1.5, 1.4], true))
	list.append(EnemyPattern.make("legs", "LEG SLAM!", 2.6, 10, 0.0, 270.0, "legs", 0.55, 0.25, 0.55, true, [2.0, 2.0], true))
	list.append(EnemyPattern.make("beam", "EYE BEAM!", 4.0, 7, 100.0, 1200.0, "beam", 0.60, 0.70, 0.50, true, [1.3, 1.5], true))
	list.append(EnemyPattern.make("charge", "VOID CHARGE!", 6.0, 11, 200.0, 1400.0, "charge", 0.60, 1.40, 0.60, true, [1.1, 1.4], true))
	list[0].note = "climbs the wall and ceiling, then drops on you: watch the shadow"
	return list


## The Shining choice (called by StoryManager after HP / damage were already scaled).
func apply_void_mod(mode: String) -> void:
	vigor = mode
	if mode == "weak":
		_spd_mod = 0.8
		_cd_mod = 1.3
		attack_chance = 0.5
	elif mode == "strong":
		_spd_mod = 1.35
		_cd_mod = 0.65
		attack_chance = 0.92
	phase_speed_mult *= _spd_mod
	cooldown_mult *= _cd_mod


func boss_title() -> String:
	var t := enemy_name.to_upper()
	if vigor == "weak":
		t += "   -   WEAKENED BY THE SHINING"
	elif vigor == "strong":
		t += "   -   VIGOROUS"
	if enraged:
		t += "   -   FRENZY"
	return t


func custom_death_type(_hit: HitData) -> String:
	return DeathManager.EXPLODE


func flavor_lines() -> Array[String]:
	return ["*sixteen eyes blink*", "*clicking mandibles*", "*legs scrape the bones*"]


func jump(_force_mult: float = 1.0) -> void:
	pass


func _on_phase_changed(_p: int) -> void:
	cooldown_mult = phase2_cooldown_mult * _cd_mod      # Keep the Shining choice in phase 2
	phase_speed_mult = phase2_speed_mult * _spd_mod
	Effects.popup(self, global_position + Vector2(0, -260), "FRENZY!", SHEEN, 32)
	Effects.shake(self, 14.0)
	SoundManager.play_sfx("roar")


# ============================================================
# ATTACKS
# ============================================================
func _attack(p: EnemyPattern) -> void:
	match p.id:
		"ceiling":
			_climbing = true
			_climb_start = global_position
			_floor_y = global_position.y
			var left := StoryManager.arena_left() if StoryManager.has_walls else global_position.x - 700.0
			var right := StoryManager.arena_right() if StoryManager.has_walls else global_position.x + 700.0
			_climb_wall_x = left + WALL_GAP if absf(global_position.x - left) < absf(global_position.x - right) else right - WALL_GAP
			SoundManager.play_sfx("dash", -4.0)
		"goo":
			var n := 3
			if vigor == "strong" or enraged:
				n = 5
			for k in n:
				var spread := (float(k) - float(n - 1) * 0.5) * 130.0 + randf_range(-25.0, 25.0)
				_spit(target_x() + spread, dmg(p))
			SoundManager.play_sfx("void_goo")
		"legs":
			var hx := global_position.x + facing * 170.0
			hit_in_radius(Vector2(hx, global_position.y - 50.0), 130.0, dmg(p), Vector2(420, -380), "massacre_legs")
			@warning_ignore("integer_division")
			BossHazard.spawn(self, "tendril", Vector2(hx + facing * 120.0, global_position.y), 0.25, maxi(1, dmg(p) / 2), Vector2(220, -400))
			Effects.shake(self, 14.0)
			SoundManager.play_sfx("slam")
		"beam":
			_beams_fired = 0
			_fire_beam(p)
		"charge":
			_turned = false
			hitbox.activate(make_hit(dmg(p), Vector2(facing * 480.0, -300.0), "massacre_charge"),
				Vector2(facing * 90.0, -70.0), Vector2(150, 130))
			Effects.trail(visuals, SHEEN, 30.0, 12)
			SoundManager.play_sfx("dash")


func _on_attack_update(p: EnemyPattern, delta: float) -> void:
	match p.id:
		"ceiling":
			_update_climb(p)
		"beam":
			var extra := 2 if (vigor == "strong" or enraged) else 0
			if _beams_fired <= extra and state_time >= float(_beams_fired) * 0.25:
				_fire_beam(p)
		"charge":
			velocity.x = facing * CHARGE_SPEED
			if is_on_wall() or not ground_ahead(140.0):
				if vigor == "strong" and not _turned:
					_turned = true                                   # VIGOROUS: bounces off and charges back
					facing = -facing
					hitbox.activate(make_hit(dmg(p), Vector2(facing * 480.0, -300.0), "massacre_charge"),
						Vector2(facing * 90.0, -70.0), Vector2(150, 130))
					Effects.shake(self, 10.0)
				else:
					state_time = state_len
					Effects.shake(self, 12.0)
	if delta < 0.0:
		pass


func _on_attack_end(p: EnemyPattern) -> void:
	match p.id:
		"ceiling":
			_end_climb()
		"charge":
			velocity.x *= 0.1


func _cancel_pattern() -> void:
	_end_climb()
	super._cancel_pattern()


func _owns_velocity_x() -> bool:
	return _climbing or (estate == EState.ATTACK and current != null and current.id == "charge")


func _movement(delta: float) -> void:
	if _climbing:
		velocity = Vector2.ZERO
		return
	super._movement(delta)


## The climb: leap to the wall, up the wall, along the ceiling over you, hang, DROP.
func _update_climb(p: EnemyPattern) -> void:
	var t := state_time
	var wall_base := Vector2(_climb_wall_x, _floor_y - 160.0)
	var wall_top := Vector2(_climb_wall_x, _floor_y - CEILING_UP)
	var wall_side := -1.0 if _climb_wall_x < _climb_start.x else 1.0
	if t < 0.45:
		var k := t / 0.45
		global_position = _climb_start.lerp(wall_base, k) + Vector2(0, -sin(k * PI) * 80.0)
		visuals.rotation = lerpf(0.0, wall_side * -PI * 0.5, k)
	elif t < 0.8:
		global_position = wall_base.lerp(wall_top, (t - 0.45) / 0.35)
		visuals.rotation = wall_side * -PI * 0.5
	elif t < 1.8:
		# Along the ceiling, tracking you
		var tx := target_x()
		var nx := move_toward(global_position.x, tx, 900.0 * get_physics_process_delta_time())
		global_position = Vector2(nx, _floor_y - CEILING_UP)
		visuals.rotation = PI
		if _shadow == null:
			_shadow = DropShadow.new()
			get_parent().add_child(_shadow)
		_shadow.global_position = Vector2(global_position.x, _floor_y)
	elif t < 2.05:
		global_position = Vector2(global_position.x + sin(t * 80.0) * 2.0, _floor_y - CEILING_UP)   # Shudders...
		if _shadow != null:
			_shadow.set("danger", true)
	elif t < 2.25:
		var k := (t - 2.05) / 0.2
		global_position = Vector2(global_position.x, lerpf(_floor_y - CEILING_UP, _floor_y, k * k))
		visuals.rotation = lerpf(PI, TAU, k)
	else:
		global_position = Vector2(global_position.x, _floor_y)
		_land_drop(p)
		state_time = state_len


func _land_drop(p: EnemyPattern) -> void:
	visuals.rotation = 0.0
	hit_in_radius(global_position + Vector2(0, -50), 180.0, dmg(p), Vector2(480, -420), "massacre_drop")
	var g: Variant = Effects.ground_below(self, global_position + Vector2(0, -40), 200.0)
	if g != null:
		ChemicalPool.spawn_void(self, g, 200.0, 4.5)
	Effects.void_burst(self, global_position + Vector2(0, -40), 180.0)
	Effects.shake(self, 20.0)
	SoundManager.play_sfx("slam")
	SoundManager.play_sfx("explosion", -4.0)
	if _shadow != null:
		_shadow.queue_free()
		_shadow = null


func _end_climb() -> void:
	if _climbing and is_inside_tree():
		if global_position.y < _floor_y - 20.0:
			global_position = Vector2(global_position.x, _floor_y)      # Never left hanging in the air
	_climbing = false
	visuals.rotation = 0.0
	if _shadow != null:
		_shadow.queue_free()
		_shadow = null


func _on_death() -> void:
	_end_climb()
	super._on_death()


func _fire_beam(p: EnemyPattern) -> void:
	_beams_fired += 1
	var heights := [-60.0, -110.0, -30.0]
	var b := spawn_projectile()
	b.kind = EnemyProjectile.Kind.LINEAR
	b.look = "eye_beam"
	b.dir = float(facing)
	b.speed = 900.0
	b.lifetime = 1.3
	b.size = Vector2(80, 26)
	b.damage = dmg(p)
	b.knockback = Vector2(280, -160)
	b.pierce = false
	b.move = "eye_beam"
	launch(b, global_position + Vector2(facing * 150.0, float(heights[(_beams_fired - 1) % 3])))
	SoundManager.play_sfx("laser", -4.0)


func _spit(to_x: float, damage: int) -> void:
	var g := spawn_projectile()
	g.kind = EnemyProjectile.Kind.ARC
	g.look = "void_bolt"
	g.damage = damage
	g.knockback = Vector2(170, -110)
	g.radius = 36.0
	g.pierce = false
	g.size = Vector2(28, 28)
	g.lifetime = 3.0
	g.move = "void_goo_spit"
	var from := global_position + Vector2(facing * 140.0, -130.0)
	var drop := global_position.y - from.y
	var t := GOO_FLIGHT
	g.arc_velocity = Vector2((to_x - from.x) / t, (drop - 0.5 * EnemyProjectile.ARC_GRAVITY * t * t) / t)
	g.on_land = _on_goo_landed
	launch(g, from)


func _on_goo_landed(pos: Vector2) -> void:
	if is_instance_valid(self) and not is_dead:
		ChemicalPool.spawn_void(self, pos, 130.0, 5.0)


## Shadow + warning ring on the floor under the spider while it hangs from the ceiling.
class DropShadow extends Node2D:
	var danger := false
	var _t := 0.0

	func _ready() -> void:
		z_index = -1

	func _process(delta: float) -> void:
		_t += delta
		queue_redraw()

	func _draw() -> void:
		draw_set_transform(Vector2.ZERO, 0.0, Vector2(1.0, 0.25))
		draw_circle(Vector2.ZERO, 150.0, Color(0, 0, 0, 0.45))
		var blink := 0.5 + 0.5 * sin(_t * (30.0 if danger else 12.0))
		draw_arc(Vector2.ZERO, 180.0, 0.0, TAU, 32, Color(1.0, 0.25, 0.2, 0.4 + 0.5 * blink), 8.0, FighterArt.AA)
		draw_set_transform(Vector2.ZERO, 0.0, Vector2.ONE)


# ============================================================
# ART (facing right, origin = feet, ~500 x 240)
# ============================================================
func draw_model_on(c: CanvasItem) -> void:
	var s := art_state()
	s["climbing"] = _climbing
	draw_massacre(c, s)


static func draw_portrait(c: CanvasItem, t: float) -> void:
	draw_massacre(c, {"t": t, "pose": "idle"})


static func draw_massacre(c: CanvasItem, s: Dictionary) -> void:
	var t: float = s.get("t", 0.0)
	var pose_v: String = s.get("pose", "idle")
	var pt: float = s.get("pose_t", 0.0)
	var dead: bool = s.get("dead", false)
	var frenzy: bool = s.get("enraged", false)
	var ph: float = s.get("walk", 0.0) * 1.5 + (t * 6.0 if s.get("climbing", false) else 0.0)
	var rear := 0.0
	if pose_v == "legs_tele":
		rear = clampf(pt / 0.55, 0.0, 1.0)
	var head := Vector2(70, -96 - rear * 40.0)
	var abdomen := Vector2(-80, -110)
	# 16 legs: 8 far (darker, behind) then 8 near
	for side in [0, 1]:
		var far: bool = side == 0
		for i in 8:
			var u := float(i) / 7.0
			var hip := head.lerp(abdomen, 0.35) + Vector2(lerpf(50.0, -60.0, u), 10.0)
			var foot_x := lerpf(250.0, -250.0, u) + (12.0 if far else -12.0)
			var step := sin(ph + float(i) * 0.9 + (PI if far else 0.0))
			var foot := Vector2(foot_x + step * 14.0, -2.0 - maxf(0.0, step) * 10.0)
			if (pose_v == "legs_tele" or pose_v == "legs") and i < 2:   # Front legs rear up / slam
				foot = Vector2(220 + float(i) * 20.0, -220.0) if pose_v == "legs_tele" else Vector2(240 + float(i) * 30.0, -4)
			var knee := Vector2((hip.x + foot.x) * 0.5, -210.0 - absf(u - 0.5) * 30.0 + (10.0 if far else 0.0))
			var col := LEG.darkened(0.4) if far else LEG
			c.draw_polyline(PackedVector2Array([hip, knee, foot]), EnemyArt.BLACK, 12.0 if far else 14.0, FighterArt.AA)
			c.draw_polyline(PackedVector2Array([hip, knee, foot]), col, 8.0 if far else 10.0, FighterArt.AA)
			if not far:
				c.draw_line(knee + Vector2(-4, 2), knee.lerp(foot, 0.3), Color(SHEEN.r, SHEEN.g, SHEEN.b, 0.35), 3.0)
				c.draw_circle(knee, 5.0, BODY_HI)
	# Abdomen: big glossy void bulb with violet markings
	var ab := EnemyArt.ellipse_points(abdomen, 120.0, 78.0, 28)
	c.draw_colored_polygon(ab, BODY)
	c.draw_colored_polygon(EnemyArt.ellipse_points(abdomen + Vector2(-10, -30), 80.0, 26.0, 18), Color(BODY_HI.r, BODY_HI.g, BODY_HI.b, 0.6))
	for k in 4:
		var mp := abdomen + Vector2(-60.0 + float(k) * 36.0, 10.0 + sin(float(k)) * 8.0)
		c.draw_colored_polygon(EnemyArt.ellipse_points(mp, 10.0, 6.0, 10), Color(SHEEN.r, SHEEN.g, SHEEN.b, 0.5 + 0.3 * sin(t * 3.0 + float(k))))
	FighterArt.outline(c, ab, 5.0)
	# Cephalothorax / head
	var hd := EnemyArt.ellipse_points(head, 70.0, 52.0, 24)
	c.draw_colored_polygon(hd, BODY)
	c.draw_colored_polygon(EnemyArt.ellipse_points(head + Vector2(-8, -20), 46.0, 16.0, 16), Color(BODY_HI.r, BODY_HI.g, BODY_HI.b, 0.6))
	FighterArt.outline(c, hd, 5.0)
	# Mandibles
	var open := 1.0 if pose_v == "goo" or pose_v == "charge" else 0.3
	for side in [-1.0, 1.0]:
		var mb: Vector2 = head + Vector2(56, 22 + side * 8.0)
		FighterArt.curved_spike(c, mb, mb + Vector2(34, side * (10.0 + 14.0 * open)), 7.0, BODY_HI, BODY, 0.4 * side)
	# SIXTEEN WHITE EYES: 4 rows clustered on the front of the head
	var rows := [[3, 9.0, -30.0], [5, 7.0, -14.0], [5, 6.0, 1.0], [3, 4.5, 14.0]]
	var n := 0
	for r in rows:
		var count: int = r[0]
		var er: float = r[1]
		var ey: float = r[2]
		for i in count:
			var ex := 38.0 + (float(i) - float(count - 1) * 0.5) * er * 2.4
			var ep := head + Vector2(ex, ey)
			if dead:
				c.draw_circle(ep, er * 0.7, Color(0.3, 0.3, 0.35))
			else:
				var glow := 0.7 + 0.3 * sin(t * (9.0 if frenzy else 3.0) + float(n))
				c.draw_circle(ep, er + 2.0, Color(EYE.r, EYE.g, EYE.b, 0.25 * glow))
				c.draw_circle(ep, er, EYE)
				c.draw_circle(ep + Vector2(er * 0.3, -er * 0.3), er * 0.3, Color(0.75, 0.7, 0.9))
			n += 1
	if pose_v == "beam_tele":
		c.draw_circle(head + Vector2(40, -8), 30.0 + pt * 30.0, Color(1, 1, 1, 0.35))
	if pose_v == "legs" and pt < 0.25:
		c.draw_arc(Vector2(240, 0), 30.0 + pt * 320.0, PI, TAU, 18, Color(SHEEN.r, SHEEN.g, SHEEN.b, 1.0 - pt * 4.0), 7.0, FighterArt.AA)
