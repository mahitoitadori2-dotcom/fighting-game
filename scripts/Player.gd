class_name Player
extends ControlledFighter
## "The Mighty Architect". Can be the Player (keyboard) or the Opponent (CPU):
## ArenaManager decides by giving him a FighterInput or an AIInput.
## Every number comes from ArchitectData (res://data/ArchitectData.gd).
## Movement / block / cooldowns / Onslaught / G Gauge live in ControlledFighter.

enum State {
	FREE, PUNCH_STARTUP, PUNCH_ACTIVE, PUNCH_RECOVERY, CAST,
	DRILL_STARTUP, DRILL_LUNGE, DRILL_GRAB, DRILL_RECOVER,
}

var arch: ArchitectData

var state: State = State.FREE
var _state_timer := 0.0
var arsenal_timer := 0.0

var _punch_buffer := 0.0
var _punch_hit: HitData
var _pending_melee_flash := false

var _drill_hit: HitData
var _drill_victim: Fighter
var _drill_ticks_done := 0
var _drill_tick_timer := 0.0

var _last_rocket: Rocket
var _last_bomb: TriangleBomb

# Animation values read by ArchitectArt
var punch_ext := 0.0
var drill_len := 0.0


# ===== SETUP =====
func _ready() -> void:
	arch = data as ArchitectData
	if arch == null:
		arch = ArchitectData.new()
		data = arch
	move_ids = ["rocket", "hnct", "drill"]
	move_names = {"rocket": "Rocket", "hnct": "HNCT", "drill": "Drill"}
	super._ready()
	grab_hold_distance = arch.drill_hold_distance


func draw_model_on(c: CanvasItem) -> void:
	ArchitectArt.draw(c, self)


func _tick_timers(delta: float) -> void:
	super._tick_timers(delta)
	_punch_buffer = maxf(_punch_buffer - delta, 0.0)
	if arsenal_timer > 0.0:
		arsenal_timer -= delta
		if arsenal_timer <= 0.0:
			_end_arsenal(true)


# ===== HOOKS =====
func _is_free() -> bool:
	return state == State.FREE


func is_attacking() -> bool:
	return _is_punching()


func _is_punching() -> bool:
	return state == State.PUNCH_STARTUP or state == State.PUNCH_ACTIVE or state == State.PUNCH_RECOVERY


func _is_drilling() -> bool:
	return state == State.DRILL_STARTUP or state == State.DRILL_LUNGE \
		or state == State.DRILL_GRAB or state == State.DRILL_RECOVER


func _movement_locked() -> bool:
	return _is_drilling()


func _owns_velocity_x() -> bool:
	return state == State.DRILL_LUNGE                 # Lunge sets velocity.x itself


func _speed_multiplier() -> float:
	return arch.arsenal_speed_mult if arsenal_timer > 0.0 else 1.0


func _jump_multiplier() -> float:
	return arch.arsenal_jump_mult if arsenal_timer > 0.0 else 1.0


func _can_turn() -> bool:
	return state == State.FREE or state == State.CAST  # Turning in place while blocking is allowed


# ===== COMBAT: INPUT =====
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
		_press_move("rocket")
	if ctl.just_pressed("move2"):
		_press_move("hnct")
	if ctl.just_pressed("move3"):
		_press_move("drill")
	if ctl.just_pressed("ultimate"):
		_try_ultimate()


# ===== COMBAT: MELEE =====
func _try_punch() -> void:
	is_blocking = false
	_pending_melee_flash = false
	var is_onsl := onslaught.consume_flash("melee", "")   # Pressed during the flash?
	var dmg: int = data.punch_damage
	var kb: Vector2 = data.punch_knockback
	if is_onsl:
		dmg = data.onslaught_melee_damage
		kb = data.onslaught_melee_knockback
		onslaught.start_afterburn()                       # The cost: 10 s of weak melee
		Effects.popup(self, global_position + Vector2(0, -160), "ONSLAUGHT STRIKE!", Color(1.0, 0.55, 0.1), 26)
	else:
		if onslaught.afterburn_timer > 0.0:
			dmg = data.afterburn_melee_damage
		_pending_melee_flash = onslaught.register_melee()  # True on the 4th in a row

	_punch_hit = HitData.new()
	_punch_hit.source = self
	_punch_hit.damage = dmg
	_punch_hit.knockback = Vector2(facing * kb.x, kb.y)   # Directional
	_punch_hit.origin = global_position
	_punch_hit.hit_type = "melee"
	_punch_hit.onslaught = is_onsl
	# During Full Arsenal the mechanical arms deliver the blows (FAOTH part "arms").
	_punch_hit.move = "faoth" if arsenal_timer > 0.0 else "punch"
	_punch_hit.part = "arms" if arsenal_timer > 0.0 else ""
	state = State.PUNCH_STARTUP
	_state_timer = data.punch_startup


func _enter_punch_active() -> void:
	SoundManager.play_sfx("punch")
	state = State.PUNCH_ACTIVE
	_state_timer = data.punch_active
	_punch_hit.origin = global_position
	hitbox.activate(_punch_hit, Vector2(facing * data.punch_offset.x, data.punch_offset.y), data.punch_size)
	if is_on_floor():
		velocity.x += facing * data.punch_lunge_speed
	_flash(Color(1.6, 1.0, 0.4) if _punch_hit.onslaught else Color(1.5, 1.5, 0.8), 0.08)


func _on_hit_landed(victim: Fighter, hit: HitData, result: String) -> void:
	if result == "ignored":
		return
	if hit.is_grab:
		if result == "hit":
			_begin_drill_grab(victim)
		return
	if hit.hit_type == "melee" and result == "hit":
		var pos := victim.global_position + Vector2(-facing * 20.0, -88.0)
		Effects.explosion(self, pos, 70.0 if hit.onslaught else 34.0, hit.onslaught)   # Orange on Onslaught


# ===== COMBAT: STATE MACHINE =====
func _handle_state(delta: float) -> void:
	match state:
		State.PUNCH_STARTUP:
			_state_timer -= delta
			if _state_timer <= 0.0:
				_enter_punch_active()
		State.PUNCH_ACTIVE:
			_state_timer -= delta
			if _state_timer <= 0.0:
				hitbox.deactivate()
				state = State.PUNCH_RECOVERY
				_state_timer = data.punch_recovery
				if _pending_melee_flash:                   # 4th melee: Onslaught bar flashes
					_pending_melee_flash = false
					onslaught.start_flash("melee", "")
		State.PUNCH_RECOVERY, State.CAST, State.DRILL_RECOVER:
			_state_timer -= delta
			if _state_timer <= 0.0:
				state = State.FREE
		State.DRILL_STARTUP:
			_state_timer -= delta
			if _state_timer <= 0.0:
				state = State.DRILL_LUNGE
				_state_timer = arch.drill_lunge_time
				velocity.x = facing * arch.drill_lunge_speed
				_drill_hit.origin = global_position
				hitbox.activate(_drill_hit, Vector2(facing * arch.drill_hitbox_offset.x, arch.drill_hitbox_offset.y), arch.drill_hitbox_size)
		State.DRILL_LUNGE:
			velocity.x = facing * arch.drill_lunge_speed
			_state_timer -= delta
			if _state_timer <= 0.0:
				_drill_miss()
		State.DRILL_GRAB:
			_update_drill_grab(delta)


func _interrupt() -> void:
	hitbox.deactivate()
	if state == State.DRILL_STARTUP or state == State.DRILL_LUNGE:
		_start_cooldown("drill", arch.drill_cooldown_miss)
	if _drill_victim != null and is_instance_valid(_drill_victim) and _drill_victim.grabbed_by == self:
		_drill_victim.release_grab()
	_drill_victim = null
	_pending_melee_flash = false
	state = State.FREE


# ===== COMBAT: MOVES (keys 1 / 2 / 3) =====
func _cast_move(id: String) -> void:
	match id:
		"rocket":
			_cast_rocket()
		"hnct":
			_cast_hnct()
		"drill":
			_start_drill()


func _begin_cast(lock: float = -1.0) -> void:
	state = State.CAST
	_state_timer = arch.cast_lock_time if lock < 0.0 else lock


func _upgrade_move(id: String) -> void:
	match id:
		"rocket":
			if is_instance_valid(_last_rocket) and _last_rocket.is_inside_tree():     # Pooled: not recycled yet
				_last_rocket.make_onslaught(arch.onslaught_move_damage_mult, arch.onslaught_move_knockback_mult)
		"hnct":
			if is_instance_valid(_last_bomb):
				_last_bomb.make_onslaught(arch.onslaught_move_damage_mult, arch.onslaught_move_knockback_mult)


# --- Rocket Delivery ---
func _cast_rocket() -> void:
	_last_rocket = _spawn_rocket(0.0)
	_start_cooldown("rocket", arch.rocket_cooldown)
	_begin_cast()
	onslaught.start_flash("projectile", "rocket", _last_rocket)


func _spawn_rocket(angle_offset_deg: float, move: String = "rocket", part: String = "") -> Rocket:
	var r := OptimizationManager.take(Rocket) as Rocket      # Pooled (never .new() / queue_free)
	r.source = self
	r.move = move
	r.part = part
	r.damage = arch.rocket_damage
	r.knockback = arch.rocket_knockback
	r.speed = arch.rocket_speed
	r.turn_rate = arch.rocket_turn_rate
	r.lifetime = arch.rocket_lifetime
	r.blast_radius = arch.rocket_blast_radius
	var a := deg_to_rad(arch.rocket_launch_angle_deg + angle_offset_deg)
	r.dir = Vector2(cos(a) * facing, sin(a))
	get_parent().add_child(r)
	r.global_position = global_position + Vector2(facing * arch.rocket_spawn_offset.x, arch.rocket_spawn_offset.y)
	return r


# --- HNCT Triangle Bomb ---
func _cast_hnct() -> void:
	var gp: Variant = _find_ground(global_position.x + facing * arch.hnct_place_offset)
	if gp == null:
		Effects.popup(self, global_position + Vector2(0, -150), "NO GROUND HERE!", Color(1, 0.9, 0.2), 18)
		return
	_last_bomb = _spawn_bomb(gp)
	_start_cooldown("hnct", arch.hnct_cooldown)
	_begin_cast()
	onslaught.start_flash("trap", "hnct", _last_bomb)


func _spawn_bomb(pos: Vector2, move: String = "hnct", part: String = "") -> TriangleBomb:
	var b := TriangleBomb.new()
	b.source = self
	b.move = move
	b.part = part
	b.damage = arch.hnct_damage
	b.knockback = arch.hnct_knockback
	b.blast_radius = arch.hnct_blast_radius
	b.arm_time = arch.hnct_arm_time
	b.triggers_on_owner = arch.hnct_triggers_on_owner
	get_parent().add_child(b)
	b.global_position = pos
	return b


# --- Armaggedon Drill ---
func _start_drill() -> void:
	state = State.DRILL_STARTUP
	_state_timer = arch.drill_startup
	_drill_victim = null
	_drill_hit = HitData.new()
	_drill_hit.source = self
	_drill_hit.damage = arch.drill_grab_damage        # 4 damage on grab
	_drill_hit.is_grab = true
	_drill_hit.blockable = arch.drill_blockable
	_drill_hit.causes_hitstun = false
	_drill_hit.hit_type = "drill"
	_drill_hit.move = "drill"
	_drill_hit.origin = global_position


func _begin_drill_grab(victim: Fighter) -> void:
	hitbox.deactivate()
	_drill_victim = victim
	victim.begin_grab(self)
	_drill_ticks_done = 0
	_drill_tick_timer = arch.drill_tick_interval
	velocity.x = 0.0
	state = State.DRILL_GRAB
	_start_cooldown("drill", arch.drill_cooldown_hit)  # 15 s on hit
	Effects.popup(self, global_position + Vector2(0, -160), "GRABBED!", Color(0.8, 0.85, 1.0), 24)


func _update_drill_grab(delta: float) -> void:
	if _drill_victim == null or not is_instance_valid(_drill_victim) \
			or _drill_victim.is_dead or _drill_victim.grabbed_by != self:
		_end_drill_grab()                              # Victim escaped (mashing) or died
		return
	_drill_tick_timer -= delta
	if _drill_tick_timer > 0.0:
		return
	var h := HitData.new()
	h.source = self
	h.damage = arch.drill_tick_damage                  # 4 per tick x 6 ticks
	h.blockable = false
	h.causes_hitstun = false
	h.knockback = Vector2.ZERO                         # No knockback, ever
	h.origin = global_position
	h.hit_type = "drill_tick"
	h.is_tick = true
	h.move = "drill"
	CombatManager.apply_hit(h, _drill_victim)
	_drill_ticks_done += 1
	_drill_tick_timer = arch.drill_tick_interval
	if _drill_ticks_done >= arch.drill_tick_count:
		_end_drill_grab()


func _end_drill_grab() -> void:
	if _drill_victim != null and is_instance_valid(_drill_victim) and _drill_victim.grabbed_by == self:
		_drill_victim.release_grab()
	_drill_victim = null
	state = State.DRILL_RECOVER
	_state_timer = arch.drill_end_recovery


func _drill_miss() -> void:
	hitbox.deactivate()
	_start_cooldown("drill", arch.drill_cooldown_miss) # 20 s on miss
	state = State.DRILL_RECOVER
	_state_timer = arch.drill_miss_recovery
	Effects.popup(self, global_position + Vector2(0, -160), "DRILL MISSED!", Color(1.0, 0.3, 0.3), 24)
	take_damage(arch.drill_miss_self_damage, Vector2.ZERO, "drill_miss")   # 7 self-damage


# ===== COMBAT: ULTIMATE (G) =====
func _try_ultimate() -> void:
	if gauge == null or state != State.FREE or arsenal_timer > 0.0:
		return
	var tier := gauge.segments()
	if tier <= 0:
		if is_human():
			Effects.popup(self, global_position + Vector2(0, -150), "G GAUGE EMPTY", Color(0.8, 0.8, 0.8), 18)
		return
	is_blocking = false
	if tier == 1:
		gauge.consume_segments(1)
		_ult_triple_rocket(true)
	elif tier == 2:
		var gp: Variant = _find_ground(global_position.x)
		if gp == null:
			Effects.popup(self, global_position + Vector2(0, -150), "NO GROUND FOR GOO!", Color(1, 0.9, 0.2), 18)
			return
		gauge.consume_segments(2)
		Effects.popup(self, global_position + Vector2(0, -160), "VOID GOO!", Color(0.7, 0.4, 1.0), 26)
		_spill_goo(gp)
	else:
		gauge.consume_segments(3)
		_ult_arsenal()
	_begin_cast(0.35)


func _ult_triple_rocket(show_popup: bool, move: String = "triple_rocket", part: String = "") -> void:
	if show_popup:
		Effects.popup(self, global_position + Vector2(0, -160), "TRIPLE ROCKET!", Color(1.0, 0.6, 0.2), 26)
	for off in [-arch.triple_rocket_spread_deg, 0.0, arch.triple_rocket_spread_deg]:
		_spawn_rocket(off, move, part)


func _spill_goo(pos: Vector2, move: String = "void_goo", part: String = "") -> void:
	SoundManager.play_sfx("void_goo")
	var g := VoidGoo.new()
	g.source = self
	g.move = move
	g.part = part
	g.tick_damage = arch.goo_tick_damage
	g.tick_interval = arch.goo_tick_interval
	g.width = arch.goo_width
	g.height = arch.goo_height
	g.duration = arch.goo_duration
	g.slow = arch.goo_slow_multiplier
	g.def_down = arch.goo_extra_damage
	get_parent().add_child(g)
	g.global_position = pos


func _ult_arsenal() -> void:
	arsenal_timer = arch.arsenal_duration
	knockback_scale = arch.arsenal_knockback_taken_mult
	Effects.popup(self, global_position + Vector2(0, -165), "FULL ARSENAL OF THE HEXAGON!", Color(0.4, 0.9, 1.0), 28)
	# Every sub-part is tagged so the kill can be traced to it (death animation).
	_ult_triple_rocket(false, "faoth", "rocket")
	for i in arch.arsenal_goo_count:
		var gg: Variant = _find_ground(global_position.x + facing * i * arch.arsenal_goo_spacing)
		if gg != null:
			_spill_goo(gg, "faoth", "goo")
	for i in arch.arsenal_hnct_count:
		var gb: Variant = _find_ground(global_position.x + facing * (i + 1) * arch.arsenal_hnct_spacing)
		if gb != null:
			_spawn_bomb(gb, "faoth", "hnct")


func _end_arsenal(do_reset: bool) -> void:
	arsenal_timer = 0.0
	knockback_scale = 1.0
	if do_reset:
		for k in cooldowns:
			cooldowns[k] = 0.0                         # ALL cooldowns reset
		onslaught.clear_afterburn()                    # Afterburn cleared
		Effects.popup(self, global_position + Vector2(0, -160), "COOLDOWNS RESET!", Color(0.4, 1.0, 0.6), 24)


# ===== DEATH / RESPAWN =====
func _on_death_extra() -> void:
	arsenal_timer = 0.0
	punch_ext = 0.0
	drill_len = 0.0


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
			ext = -0.5 * (1.0 - _state_timer / data.punch_startup)   # Wind-up
		State.PUNCH_ACTIVE:
			ext = 1.0
		State.PUNCH_RECOVERY:
			ext = clampf(_state_timer / data.punch_recovery, 0.0, 1.0)
	punch_ext = ext
	var drill_target := 0.0
	match state:
		State.DRILL_STARTUP:
			drill_target = 0.5
		State.DRILL_LUNGE, State.DRILL_GRAB:
			drill_target = 1.0
	drill_len = move_toward(drill_len, drill_target, delta * 5.0)
	# Flip / squash only the VISUALS. The hitbox never changes.
	var cs := 0.88 if is_crouching else 1.0             # Crouch: uniform scale, never squashed
	visuals.scale = Vector2(facing * cs, cs)
	visuals.queue_redraw()
