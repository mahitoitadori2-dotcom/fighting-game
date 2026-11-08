class_name Warrior
extends ControlledFighter
## The Warrior: a body of living Void with a silver helmet and shoulder pad.
## Can be the Player (keyboard) or the Opponent (CPU). Same 64x128 body as everyone.
## Every number comes from WarriorData (res://data/WarriorData.gd).
##
##   Click  Sword swing (3 dmg, punch range). NO Onslaught, NO Afterburn trigger.
##   1      Clinging Grab   - void tentacle, grabs + flings enemy to you. Onslaught-able.
##   2      Royal Destiny  - 8 s white armor: -40% damage taken, slower swings.
##   3      Eternal Grasp  - shadow form, spike bursts all around (4 dmg each).
##   G x1   Mini Eternal Grasp - homing spikes (3 dmg each)
##   G x2   Shadow Swarm       - mask off, face beam (one big hit)
##   G x3   The Fall of the Physic - snap, TIME STOP 5 s

enum State {
	FREE, SWORD_STARTUP, SWORD_ACTIVE, SWORD_RECOVERY, CAST,
	GRAB_OUT, GRAB_LATCH, GRAB_RETURN,
	ETERNAL, BEAM_CHARGE, BEAM_FIRE, BEAM_RECOVER, SNAP,
}

var wd: WarriorData
var state: State = State.FREE
var _state_timer := 0.0

var grab_box: Hitbox
var beam_box: Hitbox

var _sword_hit: HitData
var _grab_hit: HitData
var _grab_victim: Fighter
var _grab_onslaught := false
var _wave_timer := 0.0

var royal_timer := 0.0

# Animation values read by WarriorArt
var sword_swing := 0.0          # -1 = raised back, 0 = idle, 1 = swung through
var grab_len := 0.0
var royal_amt := 0.0
var shadow_amt := 0.0
var mask_off := false
var beam_charge := 0.0          # 0..1 while charging
var beam_fire := 0.0            # 1 -> 0 while the beam is out
var snap_t := 0.0               # > 0 while snapping
var spike_waves: Array[Dictionary] = []   # {"age", "range", "rot", "count"}


# ===== SETUP =====
func _ready() -> void:
	wd = data as WarriorData
	if wd == null:
		wd = WarriorData.new()
		data = wd
	move_ids = ["grab", "royal", "eternal"]
	move_names = {"grab": "Clinging Grab", "royal": "Royal Destiny", "eternal": "Eternal Grasp"}
	super._ready()

	grab_box = Hitbox.new()
	grab_box.name = "GrabBox"
	add_child(grab_box)
	grab_box.setup(self)
	grab_box.hit_landed.connect(_on_grab_hit)

	beam_box = Hitbox.new()
	beam_box.name = "BeamBox"
	add_child(beam_box)
	beam_box.setup(self)
	beam_box.hit_landed.connect(_on_beam_hit)


func draw_model_on(c: CanvasItem) -> void:
	WarriorArt.draw(c, self)


func _tick_timers(delta: float) -> void:
	super._tick_timers(delta)
	if royal_timer > 0.0:
		royal_timer -= delta
		if royal_timer <= 0.0:
			_end_royal()


# ===== HOOKS =====
func _is_free() -> bool:
	return state == State.FREE


func is_attacking() -> bool:
	return state == State.SWORD_STARTUP or state == State.SWORD_ACTIVE or state == State.SWORD_RECOVERY


func _movement_locked() -> bool:
	return state in [State.GRAB_OUT, State.GRAB_LATCH, State.ETERNAL,
		State.BEAM_CHARGE, State.BEAM_FIRE, State.BEAM_RECOVER, State.SNAP]


func _can_turn() -> bool:
	return state == State.FREE or state == State.CAST


## Ultimate wind-ups can't be cancelled by hits (the gauge is already spent).
func _super_armor() -> bool:
	return state == State.SNAP or state == State.BEAM_CHARGE or state == State.BEAM_FIRE


func _swing_mult() -> float:
	return wd.royal_swing_slow if royal_timer > 0.0 else 1.0     # Royal Destiny = slower swings


# ===== INPUT =====
func _handle_actions() -> void:
	if stun_timer > 0.0:
		return
	if ctl.just_pressed("attack") and state == State.FREE:
		_try_sword()
	if ctl.just_pressed("move1"):
		_press_move("grab")
	if ctl.just_pressed("move2"):
		_press_move("royal")
	if ctl.just_pressed("move3"):
		_press_move("eternal")
	if ctl.just_pressed("ultimate"):
		_try_ultimate()


# ===== SWORD (basic attack) =====
## Same damage + range as the Architect's punch. Never touches the Onslaught
## system: no combo count, no flash, no Afterburn.
func _try_sword() -> void:
	is_blocking = false
	var dmg: int = data.punch_damage
	if onslaught.afterburn_timer > 0.0:          # Only possible from the Time Stop penalty
		dmg = data.afterburn_melee_damage
	_sword_hit = HitData.new()
	_sword_hit.source = self
	_sword_hit.damage = dmg
	_sword_hit.knockback = Vector2(facing * data.punch_knockback.x, data.punch_knockback.y)
	_sword_hit.origin = global_position
	_sword_hit.hit_type = "sword"
	_sword_hit.move = "sword"
	_sword_hit.onslaught = false
	state = State.SWORD_STARTUP
	_state_timer = data.punch_startup * _swing_mult()


func _enter_sword_active() -> void:
	SoundManager.play_sfx("sword_slash")
	state = State.SWORD_ACTIVE
	_state_timer = data.punch_active * _swing_mult()
	_sword_hit.origin = global_position
	hitbox.activate(_sword_hit, Vector2(facing * wd.sword_offset.x, wd.sword_offset.y), wd.sword_size)
	if is_on_floor():
		velocity.x += facing * wd.sword_lunge_speed


func _on_hit_landed(victim: Fighter, hit: HitData, result: String) -> void:
	if hit.hit_type == "sword" and result == "hit":
		Effects.explosion(self, victim.global_position + Vector2(-facing * 20.0, -minf(88.0, victim.data.body_size.y * 0.6)), 30.0)


# ===== STATE MACHINE =====
func _handle_state(delta: float) -> void:
	match state:
		State.SWORD_STARTUP:
			_state_timer -= delta
			if _state_timer <= 0.0:
				_enter_sword_active()
		State.SWORD_ACTIVE:
			_state_timer -= delta
			if _state_timer <= 0.0:
				hitbox.deactivate()
				state = State.SWORD_RECOVERY
				_state_timer = data.punch_recovery * _swing_mult()
		State.SWORD_RECOVERY, State.CAST, State.BEAM_RECOVER:
			_state_timer -= delta
			if _state_timer <= 0.0:
				state = State.FREE
		State.GRAB_OUT:
			grab_len = minf(grab_len + wd.grab_extend_speed * delta, wd.grab_range)
			grab_box.position = _grab_tip_local()
			if grab_len >= wd.grab_range:
				grab_box.deactivate()                     # MISS: tentacle comes back
				state = State.GRAB_RETURN
		State.GRAB_LATCH:
			_update_grab_latch()
		State.GRAB_RETURN:
			grab_len = maxf(grab_len - wd.grab_return_speed * delta, 0.0)
			if grab_len <= 0.0:
				state = State.FREE
		State.ETERNAL:
			_wave_timer -= delta
			if _wave_timer <= 0.0:
				_wave_timer = wd.eternal_wave_interval
				_spike_wave(wd.eternal_range, wd.eternal_spike_damage, wd.eternal_spike_count)
			_state_timer -= delta
			if _state_timer <= 0.0:
				state = State.CAST
				_state_timer = 0.2
		State.BEAM_CHARGE:
			_state_timer -= delta
			if _state_timer <= 0.0:
				_fire_beam()
		State.BEAM_FIRE:
			_state_timer -= delta
			if _state_timer <= 0.0:
				beam_box.deactivate()
				state = State.BEAM_RECOVER
				_state_timer = wd.beam_recovery
		State.SNAP:
			_state_timer -= delta
			if _state_timer <= 0.0:
				_start_time_stop()


func _interrupt() -> void:
	hitbox.deactivate()
	grab_box.deactivate()
	beam_box.deactivate()
	if _grab_victim != null and is_instance_valid(_grab_victim) and _grab_victim.grabbed_by == self:
		_grab_victim.release_grab()
	_grab_victim = null
	if state == State.GRAB_OUT or state == State.GRAB_LATCH:
		state = State.GRAB_RETURN                    # Tentacle snaps back
		return
	if state != State.GRAB_RETURN:
		state = State.FREE


func _begin_cast(lock: float) -> void:
	state = State.CAST
	_state_timer = lock


# ===== MOVES =====
func _cast_move(id: String) -> void:
	match id:
		"grab":
			_cast_grab()
		"royal":
			_cast_royal()
		"eternal":
			_cast_eternal()


func _upgrade_move(id: String) -> void:
	if id == "grab":
		_grab_onslaught = true                      # Resolved when the tentacle connects


# --- 1: Clinging Grab ---
func _grab_tip_local() -> Vector2:
	return Vector2(facing * (24.0 + grab_len), wd.grab_height)


func _cast_grab() -> void:
	state = State.GRAB_OUT
	grab_len = 0.0
	_grab_onslaught = false
	_grab_victim = null
	_grab_hit = HitData.new()
	_grab_hit.source = self
	_grab_hit.damage = 0                            # Damage is dealt when the pull happens
	_grab_hit.is_grab = true
	_grab_hit.blockable = wd.grab_blockable
	_grab_hit.causes_hitstun = false
	_grab_hit.hit_type = "grab"
	_grab_hit.move = "grab"
	_grab_hit.origin = global_position
	grab_box.activate(_grab_hit, _grab_tip_local(), wd.grab_tip_size)
	_start_cooldown("grab", wd.grab_cooldown)
	# Onslaught Bar flashes for 0.4 s: press 1 again to upgrade.
	onslaught.start_flash("projectile", "grab")


func _on_grab_hit(victim: Fighter, _hit: HitData, result: String) -> void:
	if state != State.GRAB_OUT:
		return
	grab_box.deactivate()
	if result != "hit":
		state = State.GRAB_RETURN                    # Blocked: tentacle bounces back
		return
	_grab_victim = victim
	grab_hold_distance = 24.0 + grab_len
	victim.begin_grab(self)                         # Latched on the tentacle tip
	state = State.GRAB_LATCH


func _update_grab_latch() -> void:
	var v := _grab_victim
	if v == null or not is_instance_valid(v) or v.is_dead or v.grabbed_by != self:
		_grab_victim = null
		state = State.GRAB_RETURN
		return
	# Hold until the Onslaught window is over, so a 2nd press of 1 can still upgrade it.
	if onslaught.flash_timer > 0.0 and onslaught.flash_move == "grab":
		return
	v.release_grab()
	_grab_victim = null

	var h := HitData.new()
	h.source = self
	h.damage = wd.grab_onslaught_damage if _grab_onslaught else wd.grab_damage
	h.blockable = false
	h.causes_hitstun = false
	h.knockback = Vector2.ZERO
	h.origin = global_position
	h.hit_type = "grab"
	h.move = "grab"
	h.onslaught = _grab_onslaught
	CombatManager.apply_hit(h, v)

	if _grab_onslaught:
		# ONSLAUGHT: the Warrior is pulled to the opponent + orange explosion.
		Effects.explosion(self, v.global_position + Vector2(0, -70), wd.grab_onslaught_blast, true)
		announce_move("ONSLAUGHT CLINGING GRAB!", Color(1.0, 0.55, 0.1))
		v.stun_timer = maxf(v.stun_timer, wd.grab_hitstun + wd.grab_pull_time)
		force_move_to(Vector2(v.global_position.x - facing * wd.grab_pull_distance, v.global_position.y), wd.grab_pull_time)
		grab_len = 0.0
		state = State.FREE
	else:
		# NORMAL: the opponent is flung to the Warrior.
		v.stun_timer = maxf(v.stun_timer, wd.grab_hitstun + wd.grab_pull_time)
		v.force_move_to(Vector2(global_position.x + facing * wd.grab_pull_distance, global_position.y), wd.grab_pull_time)
		state = State.GRAB_RETURN
	_grab_onslaught = false


# --- 2: Royal Destiny ---
func _cast_royal() -> void:
	royal_timer = wd.royal_duration
	damage_taken_mult = 1.0 - wd.royal_damage_reduction
	_start_cooldown("royal", wd.royal_cooldown)
	_begin_cast(0.3)
	_flash(Color(2.0, 2.0, 2.0), 0.35)
	announce_move("ROYAL DESTINY!", Color(1.0, 1.0, 0.85))


func _end_royal() -> void:
	royal_timer = 0.0
	damage_taken_mult = 1.0


# --- 3: Eternal Grasp ---
func _cast_eternal() -> void:
	state = State.ETERNAL
	_state_timer = wd.eternal_duration
	_wave_timer = 0.0                               # First burst immediately
	velocity.x = 0.0
	_start_cooldown("eternal", wd.eternal_cooldown)
	announce_move("ETERNAL GRASP!", Color(0.75, 0.5, 1.0))


## One burst of spikes in all directions. Anyone close enough is hit once per burst,
## so staying close = hit again by the next burst.
func _spike_wave(spike_range: float, dmg: int, count: int, move_id: String = "eternal") -> void:
	spike_waves.append({"age": 0.0, "range": spike_range, "rot": randf() * TAU, "count": count})
	var center := global_position + Vector2(0, -64)
	for n in get_tree().get_nodes_in_group("fighters"):
		var f := n as Fighter
		if f == null or f == self or f.is_dead:
			continue
		if (f.global_position + Vector2(0, -64)).distance_to(center) > spike_range + 32.0:
			continue
		var dx := signf(f.global_position.x - global_position.x)
		if dx == 0.0:
			dx = float(facing)
		var h := HitData.new()
		h.source = self
		h.damage = dmg
		h.knockback = Vector2(dx * wd.eternal_knockback.x, wd.eternal_knockback.y)
		h.origin = global_position
		h.hit_type = "spike"
		h.move = move_id
		CombatManager.apply_hit(h, f)


# ===== ULTIMATE (G) =====
func _try_ultimate() -> void:
	if gauge == null or state != State.FREE:
		return
	var tier := gauge.segments()
	if tier <= 0:
		if is_human():
			Effects.popup(self, global_position + Vector2(0, -150), "G GAUGE EMPTY", Color(0.8, 0.8, 0.8), 18)
		return
	if tier >= 3 and CombatManager.is_time_stopped():
		tier = 2                                    # Can't stack time stops
	is_blocking = false
	gauge.consume_segments(tier)
	match tier:
		1:
			_ult_mini_eternal()
		2:
			_ult_shadow_swarm()
		_:
			_ult_fall_of_the_physic()


# --- G1: Unstable Expulsion: homing spikes ---
func _ult_mini_eternal() -> void:
	announce_move("UNSTABLE EXPULSION!", Color(0.75, 0.5, 1.0))
	spike_waves.append({"age": 0.0, "range": 70.0, "rot": 0.0, "count": 8})
	for i in wd.mini_spike_count:
		var s := OptimizationManager.take(ShadowSpike) as ShadowSpike        # Pooled
		s.source = self
		s.damage = wd.mini_spike_damage
		s.speed = wd.mini_spike_speed
		s.turn_rate = wd.mini_spike_turn
		s.lifetime = wd.mini_spike_lifetime
		var a := -PI * 0.5 + (float(i) - float(wd.mini_spike_count - 1) * 0.5) * 0.45
		s.dir = Vector2.from_angle(a)
		get_parent().add_child(s)
		s.global_position = global_position + Vector2(0, -70) + s.dir * 30.0
	_begin_cast(0.3)


# --- G2: Shadow Swarm: mask off, face beam ---
func _ult_shadow_swarm() -> void:
	announce_move("SHADOW SWARM!", Color(0.6, 0.3, 0.9))
	state = State.BEAM_CHARGE
	_state_timer = wd.beam_charge
	velocity.x = 0.0


func _fire_beam() -> void:
	SoundManager.play_sfx("beam")
	state = State.BEAM_FIRE
	_state_timer = wd.beam_duration
	var h := HitData.new()
	h.source = self
	h.damage = wd.beam_damage                       # One big hit
	h.knockback = Vector2(facing * wd.beam_knockback.x, wd.beam_knockback.y)
	h.origin = global_position
	h.hit_type = "beam"
	h.move = "shadow_swarm"
	beam_box.activate(h, Vector2(facing * (30.0 + wd.beam_range * 0.5), -112.0), Vector2(wd.beam_range, wd.beam_height))


func _on_beam_hit(victim: Fighter, _hit: HitData, result: String) -> void:
	if result == "hit":
		Effects.void_burst(self, victim.global_position + Vector2(0, -80), 80.0)


# --- G3: The Fall of the Physic: TIME STOP ---
func _ult_fall_of_the_physic() -> void:
	announce_move("THE FALL OF PSYCHIC!", Color(0.85, 0.7, 1.0))
	state = State.SNAP
	_state_timer = wd.timestop_snap_time
	velocity.x = 0.0


func _start_time_stop() -> void:
	state = State.FREE
	CombatManager.start_time_stop(self, wd.timestop_duration)
	Effects.void_burst(self, global_position + Vector2(facing * 26.0, -100), 60.0)


## COUNTERPLAY: called by TriangleBomb when the Warrior steps on an HNCT bomb during
## his own Time Stop. Time Stop ends instantly, ALL moves go on cooldown,
## Onslaught Afterburn starts, and he loses 25 HP.
func break_time_stop() -> void:
	if not CombatManager.is_time_stopped() or CombatManager.time_stop_owner != self:
		return
	CombatManager.end_time_stop()
	_start_cooldown("grab", wd.grab_cooldown)
	_start_cooldown("royal", wd.royal_cooldown)
	_start_cooldown("eternal", wd.eternal_cooldown)
	onslaught.start_afterburn()
	Effects.popup(self, global_position + Vector2(0, -175), "W-WHAT THE FU-?!", Color(1.0, 0.35, 0.3), 28)
	take_damage(wd.timestop_bomb_penalty_hp, Vector2.ZERO, "time_stop_penalty")


# ===== DEATH / RESPAWN =====
func _on_death_extra() -> void:
	_end_royal()
	grab_len = 0.0
	mask_off = false
	beam_charge = 0.0
	beam_fire = 0.0
	spike_waves.clear()
	if CombatManager.time_stop_owner == self:
		CombatManager.end_time_stop()


func _on_respawn_extra() -> void:
	state = State.FREE


# ===== VISUALS =====
func _update_visuals(delta: float) -> void:
	anim_time += delta
	if is_on_floor():
		walk_phase += absf(velocity.x) * delta * 0.045
	block_amt = move_toward(block_amt, 1.0 if is_blocking else 0.0, delta * 9.0)

	var swing := 0.0
	match state:
		State.SWORD_STARTUP:
			swing = -clampf(1.0 - _state_timer / maxf(data.punch_startup * _swing_mult(), 0.001), 0.0, 1.0)
		State.SWORD_ACTIVE:
			swing = 1.0
		State.SWORD_RECOVERY:
			swing = clampf(_state_timer / maxf(data.punch_recovery * _swing_mult(), 0.001), 0.0, 1.0)
	sword_swing = swing

	royal_amt = move_toward(royal_amt, 1.0 if royal_timer > 0.0 else 0.0, delta * 4.0)
	shadow_amt = move_toward(shadow_amt, 1.0 if state == State.ETERNAL else 0.0, delta * 6.0)
	mask_off = state == State.BEAM_CHARGE or state == State.BEAM_FIRE or state == State.BEAM_RECOVER
	beam_charge = 1.0 - clampf(_state_timer / wd.beam_charge, 0.0, 1.0) if state == State.BEAM_CHARGE else 0.0
	beam_fire = clampf(_state_timer / wd.beam_duration, 0.0, 1.0) if state == State.BEAM_FIRE else 0.0
	snap_t = 1.0 - clampf(_state_timer / wd.timestop_snap_time, 0.0, 1.0) if state == State.SNAP else 0.0

	var alive: Array[Dictionary] = []
	for w in spike_waves:
		w["age"] += delta
		if w["age"] < 0.35:
			alive.append(w)
	spike_waves = alive

	var cs := 0.88 if is_crouching else 1.0             # Crouch: uniform scale, never squashed
	visuals.scale = Vector2(facing * cs, cs)
	visuals.queue_redraw()
