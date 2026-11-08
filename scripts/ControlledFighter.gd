class_name ControlledFighter
extends Fighter
## Shared base for every PLAYABLE character (Architect, Warrior, future ones).
## Owns: input source (human or CPU), movement + jump feel, block, cooldowns,
## Onslaught system, G Gauge, attack hitbox, death/respawn resets.
## Subclasses add their moves by overriding the hooks at the bottom.

var ctl: FighterInput                 # Set by ArenaManager. Defaults to the keyboard.
var onslaught: OnslaughtSystem
var hitbox: Hitbox

## Cooldown ids in key order: move_ids[0] = key 1, [1] = key 2, [2] = key 3.
var move_ids: Array[String] = []
## Cooldown id -> display name (HUD).
var move_names := {}
var cooldowns := {}
var cooldown_totals := {}

var _coyote_timer := 0.0
var _jump_buffer_timer := 0.0

# Shared animation values
var anim_time := 0.0
var walk_phase := 0.0
var block_amt := 0.0
var perfect_flash := 0.0


# ===== SETUP =====
func _ready() -> void:
	super._ready()
	if ctl == null:
		ctl = FighterInput.new()
	for id in move_ids:
		cooldowns[id] = 0.0
		cooldown_totals[id] = 1.0

	hitbox = Hitbox.new()
	hitbox.name = "Hitbox"
	add_child(hitbox)
	hitbox.setup(self)
	hitbox.hit_landed.connect(_on_hit_landed)

	onslaught = OnslaughtSystem.new(data)
	if data.gauge_enabled:
		gauge = GGauge.new()
		gauge.segment_size = data.gauge_segment_size
		gauge.segment_count = data.gauge_segments
	blocked.connect(_on_blocked_base)


func is_human() -> bool:
	return ctl != null and ctl.is_human()


# ===== MAIN LOOP =====
func _physics_process(delta: float) -> void:
	if is_dead:
		return
	if not CombatManager.fight_active:   # Match intro / winner screen
		return
	if is_time_frozen():                 # Enemy Time Stop: completely frozen
		visuals.modulate = Color(0.55, 0.5, 0.7)
		queue_redraw()
		return
	if visuals.modulate == Color(0.55, 0.5, 0.7):
		visuals.modulate = Color.WHITE
	ctl.update(self, delta)
	tick_status(delta)
	_tick_timers(delta)
	if grabbed_update(delta):
		if not _is_free():
			_interrupt()
		if ctl.any_mash():
			grab_mash()
		_update_visuals(delta)
		return
	if forced_update(delta):
		check_fall_death()
		_update_visuals(delta)
		return
	if is_human():
		_handle_debug_input()
	if stun_timer > 0.0 and not _is_free() and not _super_armor():
		_interrupt()
	_handle_block()
	_handle_actions()
	_handle_state(delta)
	_handle_movement(delta)
	move_and_slide()
	check_fall_death()
	_update_visuals(delta)


func _tick_timers(delta: float) -> void:
	for k in cooldowns:
		cooldowns[k] = maxf(cooldowns[k] - delta, 0.0)
	perfect_flash = maxf(perfect_flash - delta, 0.0)
	onslaught.tick(delta)


func _handle_debug_input() -> void:
	if Input.is_action_just_pressed("debug_damage"):
		take_damage(data.punch_damage)
	if Input.is_action_just_pressed("debug_sim_front"):
		CombatManager.simulate_attack(self, true)
	if Input.is_action_just_pressed("debug_sim_back"):
		CombatManager.simulate_attack(self, false)
	if Input.is_action_just_pressed("debug_gauge") and gauge != null:
		gauge.add_raw(gauge.segment_size)
	if Input.is_action_just_pressed("debug_toggle_boxes"):
		CombatManager.debug_boxes = not CombatManager.debug_boxes


# ===== BLOCK =====
func _handle_block() -> void:
	var can := data.block_enabled and _is_free() and stun_timer <= 0.0 and is_on_floor()
	if can and ctl.just_pressed("block"):
		block_press_time = now()          # Used for the 0.15 s Perfect Block window
	is_blocking = can and ctl.pressed("block")


func _on_blocked_base(_hit: HitData, perfect: bool) -> void:
	if perfect:
		perfect_flash = 0.25
		_flash(Color(0.6, 1.0, 1.0), 0.2)


# ===== COOLDOWNS =====
## Every cooldown goes through here, so the Sandbox Cooldown Multiplier (0x-2x) applies to all.
func _start_cooldown(id: String, seconds: float) -> void:
	seconds *= MatchSettings.cooldown_multiplier()
	cooldowns[id] = seconds
	cooldown_totals[id] = maxf(seconds, 0.001)


func _cooldown_popup(id: String) -> void:
	Effects.popup(self, global_position + Vector2(0, -150), "%s %.1fs" % [String(move_names.get(id, id)).to_upper(), cooldowns[id]], Color(0.8, 0.8, 0.8), 16)


## Pressing a move: Onslaught upgrade first, then a normal cast.
func _press_move(id: String) -> void:
	var kind: String = data.onslaught_move_types.get(id, "")
	if kind != "" and onslaught.consume_flash(kind, id):
		_upgrade_move(id)
		var extra: float = cooldown_totals[id] * (data.onslaught_move_cooldown_mult - 1.0)   # +50% cooldown
		cooldowns[id] += extra
		cooldown_totals[id] += extra
		Effects.popup(self, global_position + Vector2(0, -160), "ONSLAUGHT!", Color(1.0, 0.55, 0.1), 26)
		return
	if not _is_free():
		return
	if cooldowns.get(id, 0.0) > 0.0:
		_cooldown_popup(id)
		return
	is_blocking = false
	SoundManager.play_move_sfx(id)          # drill / void_goo / flame / beam ... (SoundManager.MOVE_SFX)
	_cast_move(id)


# ===== MOVEMENT =====
func _handle_movement(delta: float) -> void:
	var on_floor := is_on_floor()
	var stunned := stun_timer > 0.0
	var locked := _movement_locked()
	var raw_dir := ctl.axis()
	if stunned or locked:
		raw_dir = 0.0
	is_crouching = on_floor and ctl.pressed("crouch") and not locked and not stunned

	# --- Coyote time + jump buffer ---
	if on_floor:
		_coyote_timer = data.coyote_time
	else:
		_coyote_timer = maxf(_coyote_timer - delta, 0.0)
	if ctl.just_pressed("jump"):
		_jump_buffer_timer = data.jump_buffer_time
	else:
		_jump_buffer_timer = maxf(_jump_buffer_timer - delta, 0.0)

	# --- Gravity (+ fast-fall with S) ---
	if not on_floor:
		var g := data.gravity
		if velocity.y > 0.0:
			g *= data.fall_gravity_multiplier
		velocity.y += g * delta
		var max_fall := data.max_fall_speed
		if ctl.pressed("crouch") and velocity.y > 0.0 and not stunned:
			velocity.y += data.fast_fall_extra_gravity * delta
			max_fall = data.fast_fall_speed
		velocity.y = minf(velocity.y, max_fall)

	# --- Jump ---
	var can_jump := not stunned and not locked and not is_blocking
	if can_jump and _jump_buffer_timer > 0.0 and _coyote_timer > 0.0:
		velocity.y = -data.jump_force * _jump_multiplier()
		SoundManager.play_sfx("jump", -4.0)
		_jump_buffer_timer = 0.0
		_coyote_timer = 0.0
	if ctl.just_released("jump") and velocity.y < 0.0:
		velocity.y *= data.jump_cut_multiplier

	# --- Horizontal (accel / decel) ---
	var move_dir := raw_dir
	if is_blocking or (is_attacking() and on_floor) or _rooted():
		move_dir = 0.0
	if not _owns_velocity_x():
		var speed := data.move_speed * speed_mult() * _speed_multiplier()
		if is_crouching:
			speed *= data.crouch_speed_multiplier
		var rate: float
		if stunned:
			rate = data.hitstun_ground_friction if on_floor else data.hitstun_air_friction
		elif move_dir == 0.0:
			rate = data.deceleration if on_floor else data.air_deceleration
			if is_attacking():
				rate *= data.attack_friction_multiplier
		elif on_floor:
			rate = data.deceleration if signf(velocity.x) == -signf(move_dir) else data.acceleration
		else:
			rate = data.air_acceleration
		var goal := 0.0 if stunned else move_dir * speed
		velocity.x = move_toward(velocity.x, goal, rate * delta)

	# --- Facing ---
	if raw_dir != 0.0 and not stunned and _can_turn():
		facing = 1 if raw_dir > 0.0 else -1


# ===== DEATH / RESPAWN =====
func _on_death() -> void:
	hitbox.deactivate()
	_interrupt()
	onslaught.cancel_flash()
	onslaught.clear_afterburn()
	onslaught.melee_count = 0
	is_blocking = false
	block_amt = 0.0
	_on_death_extra()


func _on_respawn() -> void:
	_coyote_timer = 0.0
	_jump_buffer_timer = 0.0
	for k in cooldowns:
		cooldowns[k] = 0.0
	_on_respawn_extra()


## Raycast straight down to find the island surface at x. Returns Vector2 or null.
func _find_ground(x: float) -> Variant:
	var space := get_world_2d().direct_space_state
	var q := PhysicsRayQueryParameters2D.create(
		Vector2(x, global_position.y - 120.0), Vector2(x, global_position.y + 400.0),
		CombatManager.WORLD_LAYER)
	var res := space.intersect_ray(q)
	if res.is_empty():
		return null
	return res["position"]


# ============================================================
# HOOKS - override in each character
# ============================================================
func _is_free() -> bool: return true                 ## Not in the middle of any action
func is_attacking() -> bool: return false            ## Mid-swing (CPU blocks this)
func _super_armor() -> bool: return false            ## Hits don't cancel the current action (ultimate wind-ups)
func _movement_locked() -> bool: return false        ## No walking AND no jumping
func _rooted() -> bool: return false                 ## No walking (can still be shoved)
func _owns_velocity_x() -> bool: return false        ## Move sets velocity.x itself (lunges)
func _speed_multiplier() -> float: return 1.0
func _jump_multiplier() -> float: return 1.0
func _can_turn() -> bool: return _is_free()
func _handle_actions() -> void: pass
func _handle_state(_delta: float) -> void: pass
func _interrupt() -> void: pass
func _cast_move(_id: String) -> void: pass
func _upgrade_move(_id: String) -> void: pass
func _on_hit_landed(_victim: Fighter, _hit: HitData, _result: String) -> void: pass
func _update_visuals(_delta: float) -> void: pass
func _on_death_extra() -> void: pass
func _on_respawn_extra() -> void: pass
