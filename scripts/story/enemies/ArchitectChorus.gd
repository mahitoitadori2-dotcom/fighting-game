class_name ArchitectChorus
extends SimpleEnemy
## ARCHITECT CHORUS - MINI-BOSS of Colosseum 2 (Level 7, the Elevator from Hell).
## A towering iron colossus that climbs the elevator shaft after you and GRABS the platform.
## Cathedral-like head with three singing grille-mouths (the "chorus"), organ-pipe
## shoulders venting steam, a huge GLOWING CORE in its chest and two giant metal HANDS.
##
## It never walks: it rises behind the middle of the elevator (drawn BEHIND the floor),
## and fights with its hands. HIT THE CORE (its body) or HIT A HAND while it rests on
## the platform after a slam.
##
##   Hand Slam         10 dmg + shockwaves   a hand hovers over you (shadow), then SLAMS
##   Double Hand Slam  11 dmg + shockwaves   both hands at once, then both rest (hit them!)
##   Rock Throw        5 dmg per rock        tears rocks from the shaft and throws them (block / dodge)
##   Elevator Shake    2 dmg per jolt        shakes the platform: be IN THE AIR when it jolts;
##                                           rocks shaken loose fall from above
## PHASE 2 (< 50%): core burns red, shorter cooldowns, more rocks, more debris.

const GRIP_X := 600.0
const HOVER_Y := -400.0
const HAND_W := 190.0                  # Slam width
const SLAM_HEIGHT := 150.0             # Fighters lower than this above the floor get crushed
const SLAM_KB := Vector2(380, -420)
const SHOCK_KB := Vector2(240, -300)
const ROCK_FLIGHT := 0.95
const ROCK_KB := Vector2(220, -200)
const JOLT_EVERY := 0.6
const JOLT_KB := Vector2(400, -140)
const HAND_BOX := Vector2(170, 96)

# The Mighty Architect's colours (ArchitectArt): white plates, green trim + hands,
# dark-gray machinery and visor, blue core.
const IRON := Color(0.95, 0.96, 0.98)          # White body plates
const IRON_SHADE := Color(0.78, 0.82, 0.88)
const IRON_HI := Color(1.0, 1.0, 1.0)
const BRASS := Color(0.22, 0.86, 0.28)         # Green trim / pipes
const BRASS_SHADE := Color(0.08, 0.52, 0.15)
const GREEN_HI := Color(0.72, 1.0, 0.62)
const DARK := Color(0.25, 0.27, 0.31)          # Arms, visor, grilles
const DARK_SHADE := Color(0.12, 0.13, 0.16)
const DARK_HI := Color(0.46, 0.49, 0.55)
const CORE := Color(0.18, 0.68, 1.0)
const CORE_HI := Color(0.78, 0.95, 1.0)
const RAGE := Color(1.0, 0.35, 0.12)
const RAGE_HI := Color(1.0, 0.85, 0.5)

## Hands, in boss-local space (NOT mirrored by facing). 0 = left hand, 1 = right hand.
var _hand := [Vector2(-GRIP_X, -30), Vector2(GRIP_X, -30)]
var _goal := [Vector2(-GRIP_X, -30), Vector2(GRIP_X, -30)]
var _hand_speed := [8.0, 8.0]
var _resting := [false, false]          # Flat on the platform after a slam: can be hit
var _slam_x := [0.0, 0.0]
var _slam_hand := -1                    # Single slam: which hand (-1 = both)
var _boxes: Array[Hurtbox] = []
var _front: Node2D
var _t := 0.0
var _jolt_t := 0.0
var _jolt_dir := 1.0
var _letting_go := false


func _make_data() -> CharacterData:
	keep_min = 0.0
	keep_max = 99999.0                  # Never walks
	attack_chance = 0.7
	phase2_threshold = 0.5
	phase2_speed_mult = 1.0
	phase2_cooldown_mult = 0.7
	knockback_scale = 0.0
	grab_immune = true
	var d := SimpleEnemy.make_data("Architect Chorus", 150, Vector2(150, 300), 0.0)
	d.hitstun_time = 0.0
	d.respawn_delay = 99.0
	return d


static func make_patterns() -> Array[EnemyPattern]:
	var list: Array[EnemyPattern] = []
	#                          id        name                 cd    dmg  min  max      anim      tele  active rec   big   weights [P1,P2] armored
	list.append(EnemyPattern.make("slam", "HAND SLAM!", 2.6, 10, 0.0, 99999.0, "slam", 0.85, 0.15, 1.20, true, [2.2, 2.0], true))
	list.append(EnemyPattern.make("double", "DOUBLE HAND SLAM!", 6.5, 11, 0.0, 99999.0, "double", 1.00, 0.15, 1.50, true, [0.9, 1.6], true))
	list.append(EnemyPattern.make("rocks", "ROCK THROW!", 4.5, 5, 0.0, 99999.0, "rocks", 0.60, 0.45, 0.50, true, [1.4, 1.4], true))
	list.append(EnemyPattern.make("shake", "ELEVATOR SHAKE!", 9.0, 2, 0.0, 99999.0, "shake", 0.70, 2.40, 0.60, true, [0.9, 1.2], true))
	list[3].note = "jump when it jolts: grounded = knocked off balance"
	return list


func _ready() -> void:
	super._ready()
	_front = Node2D.new()
	_front.name = "Hands"
	_front.z_index = 4                     # Boss body sits behind the floor (z -3): hands over the fighters
	_front.visible = false                 # Shown when the hands grab the elevator (intro)
	add_child(_front)
	_front.draw.connect(_draw_hands)
	for i in 2:
		var hb := Hurtbox.new()
		hb.name = "HandHurtbox%d" % i
		add_child(hb)
		hb.setup(self, HAND_BOX)
		hb.set_deferred("monitorable", false)
		_boxes.append(hb)


## Keeps z_index -3 after the rise intro (StoryManager checks for this method).
func stays_behind_floor() -> bool:
	return true


func boss_title() -> String:
	return enemy_name.to_upper() + ("   -   PHASE 2: OVERHEATED" if enraged else "")


func custom_death_type(_hit: HitData) -> String:
	return DeathManager.CUTSCENE


func flavor_lines() -> Array[String]:
	if enraged:
		return ["DOWN... YOU... GO...", "*grinding metal*", "BACK... INTO... HELL..."]
	return ["~ AAAAAAAAH ~", "*hissing steam*", "WE... SING... YOU... DOWN..."]


func _owns_velocity_x() -> bool:
	velocity.x = 0.0
	return true                            # Never walks, never gets pushed


func jump(_force_mult: float = 1.0) -> void:
	pass                                   # A colossus does not hop


## Rise intro finished: both hands come down HARD on the edges of the elevator.
func on_intro_landed() -> void:
	_front.visible = true
	for i in 2:
		_hand[i] = Vector2((-1.0 if i == 0 else 1.0) * GRIP_X, -420.0)
		_goal[i] = Vector2((-1.0 if i == 0 else 1.0) * GRIP_X, -30.0)
		_hand_speed[i] = 14.0


## Death: it lets go of the elevator (StoryManager then drops the body down the shaft).
func on_death_cutscene() -> void:
	_letting_go = true
	_front.z_index = 0                     # Falls behind the floor with the body
	for i in 2:
		_resting[i] = false
		_goal[i] = Vector2((-1.0 if i == 0 else 1.0) * (GRIP_X + 80.0), -500.0)
		_hand_speed[i] = 3.0
	_update_boxes()


func _on_phase_changed(_new_phase: int) -> void:
	Effects.popup(self, global_position + Vector2(0, -520), "OVERHEATING!", RAGE, 34)
	Effects.shake(self, 14.0)
	SoundManager.play_sfx("roar")
	SoundManager.play_sfx("ultimate", -4.0)


func _on_respawn() -> void:
	super._on_respawn()
	knockback_scale = 0.0


# ============================================================
# ATTACKS
# ============================================================
func _local_target_x() -> float:
	return clampf(target_x() - global_position.x, -GRIP_X + 90.0, GRIP_X - 90.0)


func _on_telegraph(p: EnemyPattern) -> void:
	super._on_telegraph(p)
	var tx := _local_target_x()
	match p.id:
		"slam":
			_slam_hand = 0 if tx < 0.0 else 1
			_slam_x[_slam_hand] = tx
			_goal[_slam_hand] = Vector2(tx, HOVER_Y)
			_hand_speed[_slam_hand] = 6.0
			SoundManager.play_sfx("chain", -8.0)
		"double":
			_slam_hand = -1
			var other := -tx if absf(tx) > 160.0 else tx + (300.0 if tx < 0.0 else -300.0)
			var a := minf(tx, other)
			var b := maxf(tx, other)
			_slam_x = [a, b]
			for i in 2:
				_goal[i] = Vector2(_slam_x[i], HOVER_Y)
				_hand_speed[i] = 5.0
			SoundManager.play_sfx("chain", -6.0)
		"rocks":
			var i := 1 if tx < 0.0 else 0               # The far hand scoops rocks from the shaft wall
			_slam_hand = i
			_goal[i] = Vector2((-1.0 if i == 0 else 1.0) * 380.0, -520.0)
			_hand_speed[i] = 7.0
			SoundManager.play_sfx("stone", -6.0)
		"shake":
			for i in 2:
				_goal[i] = Vector2((-1.0 if i == 0 else 1.0) * GRIP_X, -10.0)
				_hand_speed[i] = 10.0
			SoundManager.play_sfx("rumble", -4.0)


## The hovering hand follows you for most of the wind-up, then locks (dodge window).
func _process(delta: float) -> void:
	_t += delta
	if not _front.visible and CombatManager.fight_active and not is_dead:
		_front.visible = true              # Safety: spawned without the rise intro
	var tracking := is_telegraphing() and current != null and (current.id == "slam" or current.id == "double") \
		and state_time < state_len * 0.6 and CombatManager.fight_active
	if tracking:
		var tx := _local_target_x()
		if current.id == "slam" and _slam_hand >= 0:
			_slam_x[_slam_hand] = lerpf(_slam_x[_slam_hand], tx, 1.0 - exp(-4.0 * delta))
			_goal[_slam_hand] = Vector2(_slam_x[_slam_hand], HOVER_Y)
	for i in 2:
		var g: Vector2 = _goal[i]
		if not _resting[i] and not _letting_go and CombatManager.fight_active and (estate == EState.IDLE or estate == EState.MOVE):
			g += Vector2(0, sin(_t * 1.6 + float(i) * 2.0) * 6.0)        # Gripping hands flex a little
		_hand[i] = (_hand[i] as Vector2).lerp(g, 1.0 - exp(-float(_hand_speed[i]) * delta))
	_front.modulate = visuals.modulate
	if OptimizationManager.on_screen(global_position + Vector2(0, -250), 900.0):
		_front.queue_redraw()


func _attack(p: EnemyPattern) -> void:
	match p.id:
		"slam":
			_slam(_slam_hand, dmg(p))
		"double":
			_slam(0, dmg(p))
			_slam(1, dmg(p))
		"rocks":
			var n := 5 if enraged else 3
			var from: Vector2 = global_position + (_hand[_slam_hand] as Vector2)
			for k in n:
				var spread := (float(k) - float(n - 1) * 0.5) * 110.0 + randf_range(-25.0, 25.0)
				_throw_rock(from, target_x() + spread, dmg(p))
			_goal[_slam_hand] = Vector2((-1.0 if _slam_hand == 0 else 1.0) * 200.0, -460.0)   # Follow-through
			SoundManager.play_sfx("whoosh", -3.0)
		"shake":
			_jolt_t = 0.0
			_jolt_dir = 1.0 if randf() < 0.5 else -1.0


func _on_attack_update(p: EnemyPattern, delta: float) -> void:
	if p.id == "shake":
		_jolt_t -= delta
		if _jolt_t <= 0.0:
			_jolt_t = JOLT_EVERY
			_jolt(p)


func _on_attack_end(p: EnemyPattern) -> void:
	match p.id:
		"slam", "double":
			pass                                   # Hands stay down while RECOVERING (hit them!)
		"rocks":
			_return_hands()


## RECOVER -> IDLE: BaseEnemy clears `current`; the resting hands go back to the edges.
func _run_state(delta: float) -> void:
	var was_recover := estate == EState.RECOVER
	super._run_state(delta)
	if was_recover and estate == EState.IDLE:
		_return_hands()


func _cancel_pattern() -> void:
	super._cancel_pattern()
	_return_hands()


func _return_hands() -> void:
	for i in 2:
		_resting[i] = false
		_goal[i] = Vector2((-1.0 if i == 0 else 1.0) * GRIP_X, -30.0)
		_hand_speed[i] = 5.0
	_update_boxes()


func _slam(i: int, damage: int) -> void:
	if i < 0:
		return
	var x: float = _slam_x[i]
	_hand[i] = Vector2(x, -10.0)                  # SNAP down (it is fast)
	_goal[i] = Vector2(x, 0.0)
	_hand_speed[i] = 20.0
	_resting[i] = true
	_update_boxes()
	var floor_y := global_position.y
	var wx := global_position.x + x
	# Crush everyone under the hand
	for n in get_tree().get_nodes_in_group("fighters") + get_tree().get_nodes_in_group("helpers"):
		var f := n as Fighter
		if f == null or f.is_dead or CombatManager.are_allies(self, f):
			continue
		if absf(f.global_position.x - wx) > HAND_W * 0.5 + f.data.body_size.x * 0.4:
			continue
		if floor_y - f.global_position.y > SLAM_HEIGHT:
			continue
		var side := signf(f.global_position.x - wx)
		if side == 0.0:
			side = 1.0
		var h := make_hit(damage, Vector2(side * SLAM_KB.x, SLAM_KB.y), "chorus_slam")
		h.origin = Vector2(wx, floor_y - 40.0)
		CombatManager.apply_hit(h, f)
	# Shockwaves rolling out both ways along the floor (JUMP over them)
	for d in [-1.0, 1.0]:
		var s := spawn_projectile()
		s.kind = EnemyProjectile.Kind.LINEAR
		s.look = "shock"
		s.tint = RAGE if enraged else CORE
		s.dir = d
		s.speed = 560.0
		s.lifetime = 1.0
		s.size = Vector2(46, 34)
		s.damage = 5
		s.knockback = SHOCK_KB
		s.move = "chorus_shockwave"
		launch(s, Vector2(wx + d * (HAND_W * 0.5), floor_y - 12.0))
	Effects.shake(self, 16.0)
	Effects.hit_sparks(self, Vector2(wx, floor_y - 10.0), 12, 1.5)
	SoundManager.play_sfx("slam")
	SoundManager.play_sfx("explosion", -8.0)


func _throw_rock(from: Vector2, to_x: float, damage: int) -> void:
	var r := spawn_projectile()
	r.kind = EnemyProjectile.Kind.ARC
	r.look = "boulder"
	r.dir = signf(to_x - from.x) if to_x != from.x else 1.0
	r.damage = damage
	r.knockback = ROCK_KB
	r.radius = 48.0
	r.pierce = false
	r.size = Vector2(60, 60)
	r.lifetime = 3.0
	r.move = "chorus_rock"
	var drop := global_position.y - from.y                          # Height above the floor
	var t := ROCK_FLIGHT
	r.arc_velocity = Vector2((to_x - from.x) / t, (drop - 0.5 * EnemyProjectile.ARC_GRAVITY * t * t) / t)
	launch(r, from)


func _jolt(_p: EnemyPattern) -> void:
	_jolt_dir = -_jolt_dir
	Effects.shake(self, 14.0)
	SoundManager.play_sfx("rumble", -6.0)
	SoundManager.play_sfx("chain", -9.0)
	for n in get_tree().get_nodes_in_group("fighters"):
		var f := n as Fighter
		if f == null or f.is_dead or CombatManager.are_allies(self, f) or not f.is_on_floor():
			continue                                    # In the air = safe
		var h := make_hit(2, Vector2(_jolt_dir * JOLT_KB.x, JOLT_KB.y), "elevator_shake")
		h.blockable = false
		h.origin = f.global_position - Vector2(_jolt_dir * 60.0, 0)
		CombatManager.apply_hit(h, f)
		Effects.popup(f, f.global_position + Vector2(0, -190), "OFF BALANCE!", Color(1.0, 0.8, 0.3), 22)
	# Rocks shaken loose fall from above (shadow on the floor first)
	var count := 2 if enraged else 1
	for k in count:
		var d := spawn_projectile()
		d.kind = EnemyProjectile.Kind.DROP
		d.look = "debris"
		d.delay = 0.75
		d.radius = 52.0
		d.damage = 6
		d.knockback = Vector2(180, -260)
		d.move = "chorus_debris"
		var x := target_x() + randf_range(-160.0, 160.0) if k == 0 else global_position.x + randf_range(-GRIP_X + 80.0, GRIP_X - 80.0)
		x = clampf(x, global_position.x - GRIP_X + 60.0, global_position.x + GRIP_X - 60.0)
		launch(d, Vector2(x, global_position.y - 40.0))


func _update_boxes() -> void:
	for i in 2:
		if i >= _boxes.size():
			return
		_boxes[i].position = Vector2(_slam_x[i], 0.0)
		_boxes[i].set_deferred("monitorable", _resting[i] and not is_dead)


# ============================================================
# ART - body (visuals, mirrored by facing, BEHIND the floor) + hands (_front, in front)
# origin = floor point in the middle of the elevator
# ============================================================
func draw_model_on(c: CanvasItem) -> void:
	var s := art_state()
	s["hands"] = _hand
	s["facing"] = facing
	draw_chorus_body(c, s)


static func draw_portrait(c: CanvasItem, t: float) -> void:
	# Compact board figure: body + both hands close to it
	draw_chorus_body(c, {"t": t, "pose": "idle", "hands": [Vector2(-190, -40), Vector2(190, -40)], "facing": 1, "short": true})
	_draw_hand(c, Vector2(-190, -40), t, false, false, true)
	_draw_hand(c, Vector2(190, -40), t, false, false, false)


static func draw_chorus_body(c: CanvasItem, s: Dictionary) -> void:
	var t: float = s.get("t", 0.0)
	var dead: bool = s.get("dead", false)
	var rage: bool = s.get("enraged", false)
	var hands: Array = s.get("hands", [Vector2(-GRIP_X, -30), Vector2(GRIP_X, -30)])
	var fdir := float(s.get("facing", 1))
	var short: bool = s.get("short", false)
	var glow := RAGE if rage else CORE
	var glow_hi := RAGE_HI if rage else CORE_HI
	var hum := sin(t * 1.3) * 4.0
	var base_y := 0.0 if short else 260.0                         # Torso continues below the floor

	# Arms: thick segmented pistons from the shoulders to the hands
	for i in 2:
		var side := -1.0 if i == 0 else 1.0
		var shoulder := Vector2(side * 170.0, -330.0 + hum)
		var hp: Vector2 = hands[i]
		var hand := Vector2(hp.x * fdir, hp.y - 40.0)               # Canvas is mirrored by facing
		var elbow := shoulder.lerp(hand, 0.5) + Vector2(side * 70.0, -60.0)
		for seg in [[shoulder, elbow], [elbow, hand]]:
			var a: Vector2 = seg[0]
			var b: Vector2 = seg[1]
			c.draw_line(a, b, EnemyArt.BLACK, 46.0)
			c.draw_line(a, b, DARK_SHADE, 40.0)
			c.draw_line(a, b, DARK, 26.0)
			c.draw_line(a + Vector2(0, -8), b + Vector2(0, -8), DARK_HI, 6.0)
		FighterArt.ball(c, elbow, 30.0, IRON, IRON_SHADE, IRON_HI)
		c.draw_circle(elbow, 10.0, glow)

	# Torso: tall iron cathedral body, brass ribs
	var torso := PackedVector2Array([Vector2(-150, base_y), Vector2(-175, -250 + hum), Vector2(-120, -360 + hum), Vector2(120, -360 + hum),
		Vector2(175, -250 + hum), Vector2(150, base_y)])
	var cols := PackedColorArray()
	for p in torso:
		cols.append(IRON_HI.lerp(IRON_SHADE, clampf((p.y + 360.0) / 600.0, 0.0, 1.0)))
	c.draw_polygon(torso, cols)
	for k in 5:                                                    # Brass rib bands
		var y := -320.0 + float(k) * 60.0 + hum
		c.draw_line(Vector2(-160 + float(k) * 3.0, y), Vector2(160 - float(k) * 3.0, y), BRASS_SHADE, 8.0)
		c.draw_line(Vector2(-160 + float(k) * 3.0, y - 2.0), Vector2(160 - float(k) * 3.0, y - 2.0), BRASS, 3.0)
	FighterArt.outline(c, torso, 7.0)

	# Organ-pipe shoulders venting steam
	for i in 2:
		var side := -1.0 if i == 0 else 1.0
		for k in 4:
			var px := side * (125.0 + float(k) * 18.0)
			var top := -400.0 - float(3 - k) * 26.0 + hum
			c.draw_rect(Rect2(px - 8.0, top, 16.0, 70.0), BRASS)
			c.draw_rect(Rect2(px - 8.0, top, 16.0, 70.0), EnemyArt.BLACK, false, 3.0)
			c.draw_rect(Rect2(px - 6.0, top + 4.0, 4.0, 60.0), Color(1.0, 0.9, 0.6, 0.6))
			var puff := fmod(t * 0.8 + float(k) * 0.3 + float(i) * 0.5, 1.0)
			c.draw_circle(Vector2(px + sin(t + float(k)) * 6.0, top - 10.0 - puff * 50.0), 8.0 + puff * 14.0, Color(0.85, 0.85, 0.9, 0.35 * (1.0 - puff)))

	# THE CORE: a huge glowing orb with rotating rings
	var core := Vector2(0, -200 + hum)
	var pulse := 0.5 + 0.5 * sin(t * (6.0 if rage else 3.0))
	c.draw_circle(core, 90.0 + pulse * 12.0, Color(glow.r, glow.g, glow.b, 0.16))
	c.draw_circle(core, 62.0, EnemyArt.BLACK)
	c.draw_circle(core, 56.0, IRON_SHADE)
	c.draw_circle(core, 44.0, glow if not dead else IRON)
	c.draw_circle(core + Vector2(-10, -12), 18.0, glow_hi if not dead else IRON_HI)
	for k in 3:
		var a0 := t * (1.5 + float(k) * 0.7) * (1.0 if k % 2 == 0 else -1.0)
		c.draw_arc(core, 52.0 + float(k) * 4.0, a0, a0 + 2.0, 12, BRASS, 4.0, true)

	# Head: gothic arch with three grille mouths (the chorus) and a row of eyes
	var head := Vector2(0, -420 + hum)
	var hood := PackedVector2Array([head + Vector2(-90, 60), head + Vector2(-96, -20), head + Vector2(-40, -90), head + Vector2(0, -110),
		head + Vector2(40, -90), head + Vector2(96, -20), head + Vector2(90, 60)])
	c.draw_colored_polygon(hood, IRON)
	c.draw_colored_polygon(PackedVector2Array([head + Vector2(-70, 50), head + Vector2(-74, -14), head + Vector2(0, -88), head + Vector2(74, -14), head + Vector2(70, 50)]), DARK_SHADE)   # Visor
	FighterArt.outline(c, hood, 6.0)
	c.draw_line(head + Vector2(0, -110), head + Vector2(0, -150), BRASS, 8.0)        # Spire
	c.draw_circle(head + Vector2(0, -154), 9.0, glow)
	for k in 5:                                                                       # Eyes
		var ex := -48.0 + float(k) * 24.0
		if dead:
			c.draw_line(head + Vector2(ex - 6, -26), head + Vector2(ex + 6, -18), EnemyArt.BLACK, 3.0)
		else:
			c.draw_circle(head + Vector2(ex, -22), 7.0, Color(glow.r, glow.g, glow.b, 0.35))
			c.draw_circle(head + Vector2(ex, -22), 4.0, glow_hi)
	for k in 3:                                                                       # Singing grille mouths
		var mx := -46.0 + float(k) * 46.0
		var open := 10.0 + 8.0 * (0.5 + 0.5 * sin(t * 3.0 + float(k) * 2.1))
		var r := Rect2(head.x + mx - 14.0, head.y + 6.0, 28.0, open + 14.0)
		c.draw_rect(r, EnemyArt.BLACK)
		c.draw_rect(r.grow(-3.0), Color(glow.r, glow.g, glow.b, 0.55))
		for g in 3:
			c.draw_line(Vector2(r.position.x + 2.0, r.position.y + 5.0 + float(g) * (r.size.y - 6.0) / 3.0),
				Vector2(r.end.x - 2.0, r.position.y + 5.0 + float(g) * (r.size.y - 6.0) / 3.0), DARK, 2.0)


func _draw_hands() -> void:
	if not visuals.visible and not is_dead:
		return
	var tele := is_telegraphing() and current != null
	for i in 2:
		var p: Vector2 = _hand[i]
		# Shadow / warning on the floor under a raised hand
		if tele and (current.id == "slam" and i == _slam_hand or current.id == "double"):
			var k := clampf(state_time / maxf(state_len, 0.01), 0.0, 1.0)
			var sx: float = _slam_x[i]
			_front.draw_set_transform(Vector2(sx, 0), 0.0, Vector2(1.0, 0.22))
			_front.draw_circle(Vector2.ZERO, HAND_W * 0.5 * (0.5 + 0.5 * k), Color(0, 0, 0, 0.35 + 0.3 * k))
			_front.draw_arc(Vector2.ZERO, HAND_W * 0.5 + 6.0, 0.0, TAU, 28, Color(1.0, 0.3, 0.2, 0.5 + 0.4 * sin(anim_time * 24.0)), 6.0, true)
			_front.draw_set_transform(Vector2.ZERO, 0.0, Vector2.ONE)
		_draw_hand(_front, p, _t, _resting[i], enraged, i == 0)


## One giant metal hand, palm down. p = bottom-centre of the hand.
static func _draw_hand(c: CanvasItem, p: Vector2, t: float, flat: bool, rage: bool, left: bool) -> void:
	var glow := RAGE if rage else CORE
	var side := -1.0 if left else 1.0
	# Palm block
	var palm := FighterArt.rrect_points(Rect2(p.x - 70.0, p.y - 86.0, 140.0, 64.0), 14.0)
	c.draw_colored_polygon(palm, BRASS)                     # Green hands, like the Architect
	c.draw_colored_polygon(FighterArt.rrect_points(Rect2(p.x - 62.0, p.y - 80.0, 124.0, 18.0), 8.0), GREEN_HI)
	FighterArt.outline(c, palm, 5.0)
	# Wrist cuff (white plate) with a glowing seam
	var cuff := FighterArt.rrect_points(Rect2(p.x - 46.0, p.y - 112.0, 92.0, 30.0), 8.0)
	c.draw_colored_polygon(cuff, IRON)
	FighterArt.outline(c, cuff, 4.0)
	c.draw_line(Vector2(p.x - 40.0, p.y - 97.0), Vector2(p.x + 40.0, p.y - 97.0), glow, 3.0)
	# Four fingers (curled when gripping / flat when slammed) + thumb
	for k in 4:
		var fx := p.x - 54.0 + float(k) * 36.0
		var tip := Vector2(fx, p.y - (2.0 if flat else 10.0 + 6.0 * sin(t * 2.0 + float(k))))
		var knuckle := Vector2(fx, p.y - 28.0)
		c.draw_line(knuckle, tip, EnemyArt.BLACK, 26.0)
		c.draw_line(knuckle, tip, BRASS_SHADE, 20.0)
		c.draw_line(knuckle + Vector2(-4, 0), tip + Vector2(-4, 0), BRASS, 8.0)
		c.draw_circle(knuckle, 7.0, glow)
	var thumb := Vector2(p.x + side * -78.0, p.y - 30.0)
	c.draw_line(Vector2(p.x + side * -56.0, p.y - 60.0), thumb, EnemyArt.BLACK, 28.0)
	c.draw_line(Vector2(p.x + side * -56.0, p.y - 60.0), thumb, BRASS, 20.0)
	if flat:                                                                         # Dust ring when it lands
		c.draw_set_transform(p, 0.0, Vector2(1.0, 0.25))
		c.draw_arc(Vector2.ZERO, 100.0, 0.0, TAU, 24, Color(0.8, 0.75, 0.7, 0.35), 8.0, true)
		c.draw_set_transform(Vector2.ZERO, 0.0, Vector2.ONE)
