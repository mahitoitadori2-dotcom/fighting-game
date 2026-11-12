class_name AntiArchitect
extends Player
## THE ANTI ARCHITECT - playable. The Architect's model and animations with REVERSED colours
## (AntiArchitectArt). An aggressive rusher that ONSLAUGHTS a lot (flash after only 2 punches;
## Workflies and Anti Laser can be Onslaughted too). Numbers: AntiArchitectData.
##
##   M1  Punch (inherited from the Architect)
##   1   Workflies        2 flies home in on the enemy (none: straight ahead, then back)
##   2   Anti Laser       an orange laser that PIERCES: hits every enemy in a long line
##   3   Overcharge       charges a moment, then explodes around him (tiny self-damage)
##   G1  BattleFlies      3 faster flies that hit twice each, chasing the nearest enemies
##   G2  Energy Pool      spills energy juice around him: damage over time
##   G3  Never Out Of Plans   welds metal into a clump that explodes: energy pools, battle
##                        flies, metal shards and energy shards in every direction

var anti: AntiArchitectData
var charge_amt := 0.0              # Overcharge glow (AntiArchitectArt)
var _charge_t := -1.0              # > 0 while Overcharge charges
var _last_flies: Array = []
var _plans_clump: AntiFx.Clump = null
var _plans_t := -1.0


func _ready() -> void:
	if data == null or not (data is AntiArchitectData):
		data = AntiArchitectData.new()
	super._ready()
	anti = data as AntiArchitectData
	move_ids = ["workflies", "laser", "overcharge"]
	move_names = {"workflies": "Workflies", "laser": "Anti Laser", "overcharge": "Overcharge"}
	cooldowns.clear()
	cooldown_totals.clear()
	for id in move_ids:
		cooldowns[id] = 0.0
		cooldown_totals[id] = 1.0


func draw_model_on(c: CanvasItem) -> void:
	AntiArchitectArt.draw(c, self)


func _tick_timers(delta: float) -> void:
	super._tick_timers(delta)
	if _charge_t > 0.0:
		_charge_t -= delta
		charge_amt = 1.0 - clampf(_charge_t / anti.overcharge_charge_time, 0.0, 1.0)
		if _charge_t <= 0.0:
			_overcharge_blast()
	elif charge_amt > 0.0:
		charge_amt = move_toward(charge_amt, 0.0, delta * 4.0)
	if _plans_t > 0.0:
		_plans_t -= delta
		if _plans_clump != null and is_instance_valid(_plans_clump):
			_plans_clump.grow = 1.0 - clampf(_plans_t / anti.plans_delay, 0.0, 1.0)
		if _plans_t <= 0.0:
			_plans_explode()


# ===== INPUT (same keys as the Architect, his own moves) =====
func _handle_actions() -> void:
	if stun_timer > 0.0:
		return
	if ctl.just_pressed("attack"):
		if state == State.FREE:
			_try_punch()
		elif state == State.PUNCH_ACTIVE or state == State.PUNCH_RECOVERY:
			_punch_buffer = 0.25
	if state == State.FREE and _punch_buffer > 0.0:
		_punch_buffer = 0.0
		_try_punch()
	if ctl.just_pressed("move1"):
		_press_move("workflies")
	if ctl.just_pressed("move2"):
		_press_move("laser")
	if ctl.just_pressed("move3"):
		_press_move("overcharge")
	if ctl.just_pressed("ultimate"):
		_try_ultimate()


func _cast_move(id: String) -> void:
	match id:
		"workflies":
			_cast_workflies()
		"laser":
			_fire_laser(false)
			_start_cooldown("laser", anti.laser_cooldown)
			_begin_cast(0.22)
			onslaught.start_flash("projectile", "laser")
		"overcharge":
			_start_cooldown("overcharge", anti.overcharge_cooldown)
			_charge_t = anti.overcharge_charge_time
			_begin_cast(anti.overcharge_charge_time + 0.15)
			SoundManager.play_sfx("spark", -4.0)


## Onslaught (repeat the key during the flash): flies get stronger, the laser fires AGAIN, bigger.
func _upgrade_move(id: String) -> void:
	match id:
		"workflies":
			for f in _last_flies:
				if f != null and is_instance_valid(f):
					(f as AntiFx.Fly).make_onslaught()
		"laser":
			_fire_laser(true)


func _interrupt() -> void:
	_charge_t = -1.0                              # Hit while charging: the Overcharge fizzles
	super._interrupt()


# ----- 1 Workflies -----
func _cast_workflies() -> void:
	_last_flies.clear()
	for i in anti.workfly_count:
		_last_flies.append(_spawn_fly(false, anti.workfly_damage, 1, anti.workfly_speed, anti.workfly_life,
			global_position + Vector2(facing * 30.0, -100.0 + float(i) * 30.0)))
	_start_cooldown("workflies", anti.workfly_cooldown)
	_begin_cast(0.18)
	onslaught.start_flash("projectile", "workflies", _last_flies[0] if not _last_flies.is_empty() else null)
	SoundManager.play_sfx("whoosh", -6.0)


func _spawn_fly(battle: bool, dmg: int, hits: int, spd: float, life: float, pos: Vector2, v: Vector2 = Vector2.ZERO) -> AntiFx.Fly:
	var f := AntiFx.Fly.new()
	f.source = self
	f.battle = battle
	f.damage = dmg
	f.hits = hits
	f.speed = spd
	f.life = life
	f.dir = float(facing)
	f.vel = v
	get_parent().add_child(f)
	f.global_position = pos
	return f


# ----- 2 Anti Laser: instant, PIERCING (every enemy in the line) -----
func _fire_laser(big: bool) -> void:
	var origin := global_position + Vector2(facing * 34.0, -86.0)
	var h := anti.laser_height * (1.8 if big else 1.0)
	var dmg := roundi(float(anti.laser_damage) * (anti.onslaught_move_damage_mult if big else 1.0))
	for f in AntiFx.enemies_of(self):
		var ff := f as Fighter
		var dx := (ff.global_position.x - origin.x) * float(facing)
		if dx < -20.0 or dx > anti.laser_range:
			continue
		var cy := ff.global_position.y - ff.data.body_size.y * 0.5
		if absf(cy - origin.y) > h + ff.data.body_size.y * 0.5:
			continue
		AntiFx.hit(self, ff, dmg, anti.laser_knockback * (anti.onslaught_move_knockback_mult if big else 1.0), origin, "anti_laser", "", big)
	var b := AntiFx.Beam.new()
	b.length = anti.laser_range
	b.height = anti.laser_height
	b.dir = float(facing)
	b.big = big
	get_parent().add_child(b)
	b.global_position = origin
	SoundManager.play_sfx("laser", -2.0 if big else -4.0)
	if big:
		Effects.shake(self, 6.0)


# ----- 3 Overcharge -----
func _overcharge_blast() -> void:
	_charge_t = -1.0
	charge_amt = 1.0
	var c := global_position + Vector2(0, -64)
	for f in AntiFx.enemies_of(self):
		var ff := f as Fighter
		if (ff.global_position + Vector2(0, -ff.data.body_size.y * 0.5)).distance_to(c) <= anti.overcharge_radius + ff.data.body_size.x * 0.5:
			AntiFx.hit(self, ff, anti.overcharge_damage, anti.overcharge_knockback, c, "overcharge", HitData.KIND_EXPLOSION)
	Effects.explosion(self, c, anti.overcharge_radius, true, false)
	Effects.shake(self, 9.0)
	SoundManager.play_sfx("explosion", -3.0)
	# The cost: a TINY bit of self-damage (never lethal)
	var self_dmg := mini(anti.overcharge_self_damage, hp - 1)
	if self_dmg > 0:
		take_damage(self_dmg, Vector2.ZERO, "overcharge_self")


# ===== ULTIMATES (G) =====
func _try_ultimate() -> void:
	if gauge == null or state != State.FREE or _plans_t > 0.0:
		return
	var tier := gauge.segments()
	if tier <= 0:
		if is_human():
			Effects.popup(self, global_position + Vector2(0, -150), "G GAUGE EMPTY", Color(0.8, 0.8, 0.8), 18)
		return
	is_blocking = false
	if tier == 1:
		gauge.consume_segments(1)
		announce_move("BATTLEFLIES!", Color(1.0, 0.45, 0.1))
		for i in anti.battlefly_count:
			_spawn_fly(true, anti.battlefly_damage, anti.battlefly_hits, anti.battlefly_speed, 4.0,
				global_position + Vector2(facing * 20.0, -110.0 + float(i) * 22.0), Vector2(facing * 300.0, -200.0 + float(i) * 200.0))
		SoundManager.play_sfx("whoosh")
	elif tier == 2:
		var gp: Variant = _find_ground(global_position.x)
		if gp == null:
			Effects.popup(self, global_position + Vector2(0, -150), "NO GROUND FOR THE POOL!", Color(1, 0.9, 0.2), 18)
			return
		gauge.consume_segments(2)
		announce_move("ENERGY POOL!", Color(1.0, 0.55, 0.1))
		_spill_pool(gp as Vector2, anti.pool_width)
	else:
		gauge.consume_segments(3)
		announce_move("NEVER OUT OF PLANS!", Color(1.0, 0.45, 0.05))
		_plans_clump = AntiFx.Clump.new()
		get_parent().add_child(_plans_clump)
		_plans_clump.global_position = global_position + Vector2(facing * 90.0, -90.0)
		_plans_t = anti.plans_delay
		SoundManager.play_sfx("drill", -4.0)
	_begin_cast(0.35)


func _spill_pool(pos: Vector2, width: float) -> void:
	var p := AntiFx.Pool.new()
	p.source = self
	p.width = width
	p.duration = anti.pool_duration
	p.tick = anti.pool_tick
	p.tick_damage = anti.pool_tick_damage
	get_parent().add_child(p)
	p.global_position = pos
	SoundManager.play_sfx("splash", -2.0)


func _plans_explode() -> void:
	_plans_t = -1.0
	var c := global_position + Vector2(facing * 90.0, -90.0)
	if _plans_clump != null and is_instance_valid(_plans_clump):
		c = _plans_clump.global_position
		_plans_clump.queue_free()
	_plans_clump = null
	# The blast itself
	for f in AntiFx.enemies_of(self):
		var ff := f as Fighter
		if (ff.global_position + Vector2(0, -ff.data.body_size.y * 0.5)).distance_to(c) <= anti.plans_radius + ff.data.body_size.x * 0.5:
			AntiFx.hit(self, ff, anti.plans_damage, Vector2(560, -480), c, "never_out_of_plans", HitData.KIND_EXPLOSION)
	Effects.explosion(self, c, anti.plans_radius, true, true)
	Effects.shake(self, 26.0)
	SoundManager.play_sfx("explosion")
	SoundManager.play_sfx("rumble", -4.0)
	# ...and out of it, in every direction: energy pools, battle flies, metal + energy shards
	for i in anti.plans_pools:
		@warning_ignore("integer_division")
		var gp: Variant = _find_ground(c.x + (-1.0 if i % 2 == 0 else 1.0) * (110.0 + 60.0 * float(i / 2)))
		if gp != null:
			_spill_pool(gp as Vector2, anti.pool_width * 0.7)
	for i in anti.plans_flies:
		var a := -PI * 0.5 + (float(i) - float(anti.plans_flies - 1) * 0.5) * 0.9
		_spawn_fly(true, anti.battlefly_damage, anti.battlefly_hits, anti.battlefly_speed, 4.0, c, Vector2.from_angle(a) * 420.0)
	for i in anti.plans_shards * 2:
		var s := AntiFx.Shard.new()
		s.source = self
		s.energy = i % 2 == 1
		s.damage = anti.plans_shard_damage
		s.vel = Vector2.from_angle(float(i) * TAU / float(anti.plans_shards * 2) + randf_range(-0.1, 0.1)) * randf_range(520.0, 680.0)
		get_parent().add_child(s)
		s.global_position = c


func _on_death_extra() -> void:
	super._on_death_extra()
	_charge_t = -1.0
	charge_amt = 0.0
	_plans_t = -1.0
	if _plans_clump != null and is_instance_valid(_plans_clump):
		_plans_clump.queue_free()
	_plans_clump = null
