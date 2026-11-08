class_name FireLord
extends ControlledFighter
## The Nightmare Lord: elegant red villain in a suit with a red tie. All flames PURE RED.
## Can be the Player (keyboard) or the Opponent (FireLordAI). Same 64x128 body as everyone.
## Every number comes from FireLordData (res://data/FireLordData.gd).
##
##   Click  Punch (3 dmg, Architect range). NOT Onslaught-able.
##   1      BloodFlame Spit   - 5 red flames in a spread, 5 dmg each
##   2      Bat Escape        - 3 red bats, 9 dmg each. Hit during it -> agile bat form 5 s
##   3      Launch O' Spikes  - jump, 6-flame burst (4 each), slam, floor spikes (7 each)
##   G x1   Double Trouble        - 8 flames + 5 bats (+ bat form on hit)
##   G x2   Volatile Nightmare    - body spikes (7 each) + oil puddle (ignites on fire)
##   G x3   The Ritual of the Troupe - Nightmare Heart explodes: flames, bats, oil everywhere
##   PASSIVE: +1 damage to ALL attacks per full G bar (max +3). Suit tears as he charges.

enum State {
	FREE, PUNCH_STARTUP, PUNCH_ACTIVE, PUNCH_RECOVERY, CAST,
	SPIKE_RISE, SPIKE_SLAM, HEART_CAST,
}

var fd: FireLordData
var state: State = State.FREE
var _state_timer := 0.0
var _punch_hit: HitData
var _spike_bonus := 0

var bat_guard_timer := 0.0       # > 0: getting hit turns him into a bat
var bat_timer := 0.0             # > 0: bat form (move only)
var _bat_pending := false

# Animation values read by FireLordArt
var punch_ext := 0.0
var cast_pose := 0.0             # Throwing arm (flames / bats / heart)
var spike_pose := 0.0            # 1 = arms up (rising), -1 = slam
var body_spike_t := 0.0          # Volatile Nightmare body spikes
var body_spike_rot := 0.0


# ===== SETUP =====
func _ready() -> void:
	fd = data as FireLordData
	if fd == null:
		fd = FireLordData.new()
		data = fd
	move_ids = ["flame", "bat", "spikes"]
	move_names = {"flame": "BloodFlame Spit", "bat": "Bat Escape", "spikes": "Launch O' Spikes"}
	super._ready()
	damaged.connect(_on_damaged)


func draw_model_on(c: CanvasItem) -> void:
	FireLordArt.draw(c, self)


## PASSIVE: +1 damage per full G Gauge bar (0..3).
func bonus() -> int:
	return gauge.segments() if gauge != null else 0


func is_bat() -> bool:
	return bat_timer > 0.0


func _tick_timers(delta: float) -> void:
	super._tick_timers(delta)
	bat_guard_timer = maxf(bat_guard_timer - delta, 0.0)
	body_spike_t = maxf(body_spike_t - delta, 0.0)
	cast_pose = move_toward(cast_pose, 0.0, delta * 3.0)
	if _bat_pending:
		_bat_pending = false
		_enter_bat_form()
	if bat_timer > 0.0:
		bat_timer -= delta
		if bat_timer <= 0.0:
			_exit_bat_form()


# ===== HOOKS =====
func _is_free() -> bool:
	return state == State.FREE


func is_attacking() -> bool:
	return state == State.PUNCH_STARTUP or state == State.PUNCH_ACTIVE or state == State.PUNCH_RECOVERY


func _movement_locked() -> bool:
	return state == State.SPIKE_RISE or state == State.SPIKE_SLAM or state == State.HEART_CAST


func _speed_multiplier() -> float:
	return fd.bat_form_speed_mult if is_bat() else 1.0


func _jump_multiplier() -> float:
	return fd.bat_form_jump_mult if is_bat() else 1.0


func _can_turn() -> bool:
	return state == State.FREE or state == State.CAST


func _super_armor() -> bool:
	return state == State.HEART_CAST or state == State.SPIKE_RISE or state == State.SPIKE_SLAM


# ===== INPUT =====
func _handle_actions() -> void:
	if stun_timer > 0.0 or is_bat():          # Bat form: can ONLY move
		return
	if ctl.just_pressed("attack") and state == State.FREE:
		_try_punch()
	if ctl.just_pressed("move1"):
		_press_move("flame")
	if ctl.just_pressed("move2"):
		_press_move("bat")
	if ctl.just_pressed("move3"):
		_press_move("spikes")
	if ctl.just_pressed("ultimate"):
		_try_ultimate()


# ===== PUNCH (no Onslaught, no flash, no Afterburn trigger) =====
func _try_punch() -> void:
	SoundManager.play_sfx("punch")
	is_blocking = false
	_punch_hit = HitData.new()
	_punch_hit.source = self
	_punch_hit.damage = data.punch_damage + bonus()
	_punch_hit.knockback = Vector2(facing * data.punch_knockback.x, data.punch_knockback.y)
	_punch_hit.origin = global_position
	_punch_hit.hit_type = "melee"
	_punch_hit.move = "punch"
	state = State.PUNCH_STARTUP
	_state_timer = data.punch_startup


func _on_hit_landed(victim: Fighter, hit: HitData, result: String) -> void:
	if hit.move == "punch" and result == "hit":
		Effects.red_burst(self, victim.global_position + Vector2(-facing * 20.0, -88.0), 26.0)


# ===== STATE MACHINE =====
func _handle_state(delta: float) -> void:
	match state:
		State.PUNCH_STARTUP:
			_state_timer -= delta
			if _state_timer <= 0.0:
				state = State.PUNCH_ACTIVE
				_state_timer = data.punch_active
				_punch_hit.origin = global_position
				hitbox.activate(_punch_hit, Vector2(facing * data.punch_offset.x, data.punch_offset.y), data.punch_size)
				if is_on_floor():
					velocity.x += facing * data.punch_lunge_speed
		State.PUNCH_ACTIVE:
			_state_timer -= delta
			if _state_timer <= 0.0:
				hitbox.deactivate()
				state = State.PUNCH_RECOVERY
				_state_timer = data.punch_recovery
		State.PUNCH_RECOVERY, State.CAST, State.HEART_CAST:
			_state_timer -= delta
			if _state_timer <= 0.0:
				state = State.FREE
		State.SPIKE_RISE:
			_state_timer -= delta
			if _state_timer <= 0.0 or velocity.y >= -40.0:
				_spike_flame_burst()
				state = State.SPIKE_SLAM
				_state_timer = 1.5                    # Safety: never stuck mid-air
				velocity.y = data.max_fall_speed
		State.SPIKE_SLAM:
			velocity.y = maxf(velocity.y, data.max_fall_speed)
			_state_timer -= delta
			if is_on_floor() or _state_timer <= 0.0:
				_spike_slam()
				state = State.CAST
				_state_timer = 0.3


func _interrupt() -> void:
	hitbox.deactivate()
	state = State.FREE


func _begin_cast(lock: float) -> void:
	state = State.CAST
	_state_timer = lock


# ===== SPAWNERS (also used by the Nightmare Heart) =====
func _throw_origin() -> Vector2:
	return global_position + Vector2(facing * fd.flame_spawn_offset.x, fd.flame_spawn_offset.y)


func spawn_flame(pos: Vector2, dir: Vector2, move: String, bonus_dmg: int,
		dmg: int = -1, speed: float = -1.0, life: float = -1.0) -> FireProjectile:
	var p := OptimizationManager.take(FireProjectile) as FireProjectile     # Pooled
	p.source = self
	p.kind = "flame"
	p.damage = (fd.flame_damage if dmg < 0 else dmg) + bonus_dmg
	p.speed = fd.flame_speed if speed < 0.0 else speed
	p.lifetime = fd.flame_lifetime if life < 0.0 else life
	p.knockback = fd.flame_knockback
	p.dir = dir.normalized()
	p.move = move
	get_parent().add_child(p)
	p.global_position = pos
	return p


func spawn_bat(pos: Vector2, dir: Vector2, move: String, bonus_dmg: int) -> FireProjectile:
	var p := OptimizationManager.take(FireProjectile) as FireProjectile     # Pooled
	p.source = self
	p.kind = "bat"
	p.hit_type = "bat"
	p.damage = fd.bat_damage + bonus_dmg
	p.speed = fd.bat_speed * randf_range(0.92, 1.08)
	p.lifetime = fd.bat_lifetime
	p.knockback = fd.bat_knockback
	p.dir = dir.normalized()
	p.wave = 70.0
	p.move = move
	get_parent().add_child(p)
	p.global_position = pos
	return p


## Oil on the ground near x (looks for the floor below / around search_up px above us).
func spawn_oil(x: float, search_up: float, move: String, bonus_dmg: int) -> OilPuddle:
	var space := get_world_2d().direct_space_state
	var q := PhysicsRayQueryParameters2D.create(
		Vector2(x, global_position.y - search_up - 120.0), Vector2(x, global_position.y + 400.0),
		CombatManager.WORLD_LAYER)
	var res := space.intersect_ray(q)
	if res.is_empty():
		return null
	var o := OilPuddle.new()
	o.source = self
	o.width = fd.oil_width
	o.duration = fd.oil_duration
	o.burn_damage = fd.oil_burn_damage + bonus_dmg
	o.burn_time = fd.oil_burn_time
	o.move = move
	get_parent().add_child(o)
	o.global_position = res["position"]
	return o


func _fan_of_flames(count: int, spread_deg: float, move: String, bonus_dmg: int) -> void:
	var origin := _throw_origin()
	for i in count:
		var a := deg_to_rad((float(i) - float(count - 1) * 0.5) * spread_deg)
		spawn_flame(origin, Vector2(cos(a) * facing, sin(a)), move, bonus_dmg)
	cast_pose = 1.0


func _flock_of_bats(count: int, move: String, bonus_dmg: int) -> void:
	var origin := _throw_origin() + Vector2(0, -6)
	for i in count:
		var off := float(i) - float(count - 1) * 0.5
		var jitter := Vector2(randf_range(-8.0, 8.0), randf_range(-6.0, 6.0))      # Bats never stack perfectly
		spawn_bat(origin + Vector2(0, off * 14.0) + jitter, Vector2(facing, off * 0.14 + randf_range(-0.05, 0.05)), move, bonus_dmg)
	bat_guard_timer = fd.bat_guard_time          # Hit during this -> bat form
	cast_pose = 1.0


# ===== MOVES =====
func _cast_move(id: String) -> void:
	match id:
		"flame":
			_fan_of_flames(fd.flame_count, fd.flame_spread_deg, "bloodflame", bonus())
			_start_cooldown("flame", fd.flame_cooldown)
			_begin_cast(0.25)
		"bat":
			_flock_of_bats(fd.bat_count, "bat_escape", bonus())
			_start_cooldown("bat", fd.bat_cooldown)
			_begin_cast(0.25)
		"spikes":
			_cast_spikes()


# --- 3: Launch O' Spikes ---
func _cast_spikes() -> void:
	_spike_bonus = bonus()
	state = State.SPIKE_RISE
	_state_timer = fd.spikes_rise_time
	velocity.y = -fd.spikes_jump_force
	_start_cooldown("spikes", fd.spikes_cooldown)


func _spike_flame_burst() -> void:
	var center := global_position + Vector2(0, -64)
	for i in fd.spikes_burst_count:
		var d := Vector2.from_angle(TAU * float(i) / float(fd.spikes_burst_count) - PI * 0.5)
		spawn_flame(center + d * 20.0, d, "launch_spikes", _spike_bonus,
			fd.spikes_burst_damage, fd.spikes_burst_speed, fd.spikes_burst_lifetime)
	Effects.red_burst(self, center, 50.0)


func _spike_slam() -> void:
	Effects.red_burst(self, global_position, 60.0)
	for i in fd.spikes_floor_count:
		var x := global_position.x + facing * (fd.spikes_floor_first + float(i) * fd.spikes_floor_spacing)
		var gp: Variant = _find_ground(x)
		if gp == null:
			continue                                 # No floor there (edge of the island)
		var s := OptimizationManager.take(FloorSpike) as FloorSpike          # Pooled
		s.source = self
		s.damage = fd.spikes_floor_damage + _spike_bonus
		s.knockback = Vector2(facing * absf(fd.spikes_floor_knockback.x), fd.spikes_floor_knockback.y)
		s.delay = float(i) * fd.spikes_floor_interval
		s.move = "launch_spikes"
		get_parent().add_child(s)
		s.global_position = gp


# ===== BAT FORM (Bat Escape defensive effect) =====
func _on_damaged(amount: int, hit: HitData) -> void:
	if amount > 0 and bat_guard_timer > 0.0 and not is_bat() and hit.hit_type != "self":
		_bat_pending = true                      # Transform next frame (after knockback)


func _enter_bat_form() -> void:
	if is_dead:
		return
	_interrupt()
	bat_guard_timer = 0.0
	bat_timer = fd.bat_form_duration
	stun_timer = 0.0
	hurtbox.resize(fd.bat_form_hurtbox)          # Smaller = harder to hit
	Effects.red_burst(self, global_position + Vector2(0, -60), 55.0)
	Effects.popup(self, global_position + Vector2(0, -160), "BAT FORM!", Color(1.0, 0.25, 0.25), 24)


func _exit_bat_form() -> void:
	bat_timer = 0.0
	hurtbox.resize(data.body_size)
	Effects.red_burst(self, global_position + Vector2(0, -60), 45.0)


# ===== ULTIMATE (G) =====
func _try_ultimate() -> void:
	if gauge == null or state != State.FREE or is_bat():
		return
	var tier := gauge.segments()
	if tier <= 0:
		if is_human():
			Effects.popup(self, global_position + Vector2(0, -150), "G GAUGE EMPTY", Color(0.8, 0.8, 0.8), 18)
		return
	var b := bonus()              # The ult itself still gets the passive bonus it was charged with
	is_blocking = false
	gauge.consume_segments(tier)  # Spending the gauge resets the passive + mends the suit
	match tier:
		1:
			_ult_double_trouble(b)
		2:
			_ult_volatile_nightmare(b)
		_:
			_ult_ritual(b)


func _ult_double_trouble(b: int) -> void:
	announce_move("DOUBLE TROUBLE!", Color(1.0, 0.2, 0.2))
	_fan_of_flames(fd.double_flame_count, fd.double_flame_spread_deg, "double_trouble", b)
	_flock_of_bats(fd.double_bat_count, "double_trouble", b)
	_begin_cast(0.35)


func _ult_volatile_nightmare(b: int) -> void:
	announce_move("VOLATILE NIGHTMARE!", Color(1.0, 0.2, 0.2))
	body_spike_t = 0.45
	body_spike_rot = randf() * TAU
	var center := global_position + Vector2(0, -64)
	for n in get_tree().get_nodes_in_group("fighters"):
		var f := n as Fighter
		if f == null or f == self or f.is_dead:
			continue
		if (f.global_position + Vector2(0, -64)).distance_to(center) > fd.volatile_spike_range + 32.0:
			continue
		var dx := signf(f.global_position.x - global_position.x)
		if dx == 0.0:
			dx = float(facing)
		var h := HitData.new()
		h.source = self
		h.damage = fd.volatile_spike_damage + b
		h.knockback = Vector2(dx * fd.volatile_knockback.x, fd.volatile_knockback.y)
		h.origin = global_position
		h.hit_type = "spike"
		h.move = "volatile_nightmare"
		CombatManager.apply_hit(h, f)
	spawn_oil(global_position.x + facing * fd.oil_offset, 0.0, "volatile_nightmare", b)
	_begin_cast(0.4)


func _ult_ritual(b: int) -> void:
	announce_move("THE RITUAL OF THE TROUPE!", Color(1.0, 0.15, 0.15))
	var heart := NightmareHeart.new()
	heart.source = self
	heart.grow_time = fd.ritual_grow_time
	heart.radius = fd.ritual_radius
	heart.damage = fd.ritual_damage + b
	heart.knockback = fd.ritual_knockback
	heart.flame_count = fd.ritual_flames
	heart.bat_count = fd.ritual_bats
	heart.oil_count = fd.ritual_oil_count
	heart.oil_spread = fd.ritual_oil_spread
	heart.bonus = b
	get_parent().add_child(heart)
	heart.global_position = global_position + Vector2(facing * 120.0, -110.0)
	cast_pose = 1.0
	state = State.HEART_CAST
	_state_timer = 0.5


# ===== DEATH / RESPAWN =====
func _on_death_extra() -> void:
	if is_bat():
		_exit_bat_form()
	bat_guard_timer = 0.0
	_bat_pending = false
	punch_ext = 0.0
	body_spike_t = 0.0


func _on_respawn_extra() -> void:
	state = State.FREE


# ===== VISUALS =====
func _update_visuals(delta: float) -> void:
	anim_time += delta
	if is_on_floor():
		walk_phase += absf(velocity.x) * delta * 0.045
	block_amt = move_toward(block_amt, 1.0 if is_blocking else 0.0, delta * 9.0)
	var ext := 0.0
	match state:
		State.PUNCH_STARTUP:
			ext = -0.5 * (1.0 - _state_timer / data.punch_startup)
		State.PUNCH_ACTIVE:
			ext = 1.0
		State.PUNCH_RECOVERY:
			ext = clampf(_state_timer / data.punch_recovery, 0.0, 1.0)
	punch_ext = ext
	var sp := 0.0
	if state == State.SPIKE_RISE:
		sp = 1.0
	elif state == State.SPIKE_SLAM:
		sp = -1.0
	spike_pose = move_toward(spike_pose, sp, delta * 10.0)
	var cs := 0.88 if is_crouching else 1.0             # Crouch: uniform scale, never squashed
	visuals.scale = Vector2(facing * cs, cs)
	visuals.queue_redraw()
