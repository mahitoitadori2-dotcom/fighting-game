class_name Mimic
extends ControlledFighter
## THE MIMIC (Versus only): a big fighter of pure steel with red pupils. Heavier than everyone
## (bigger body, more HP, less knockback), slower. His punch can NOT be Onslaughted.
## Every number comes from MimicData (res://data/MimicData.gd).
##
##   Click  Punch (4 dmg). NOT Onslaught-able.
##   1      Shredding Fist  - stabs forward; on hit it holds them and GRINDS (4 x 2 dmg)
##   2      Stab Kick       - his leg becomes a spike, kicks forward: HIGH knockback
##   3      Wings of Lies   - steel wings come out of his back, he SPINS (hits all around)
##   G x1   Recital of Steel - 3-hit combo: Shredding Fist, Fist, Shredding Kick
##   G x2   Eating Fear      - grabs forward; on grab his stomach opens and tries to EAT them
##                             (only damage: chewing ticks, then spits them out)
##   G x3   Stolen Skin      - bites forward; on hit he BECOMES the bitten fighter for 30 s:
##                             their body, their moves, their CPU / your keys. Damage to the copy
##                             is his own HP. Bosses / enemies can't be copied (a harder bite).

enum State {
	FREE, PUNCH_STARTUP, PUNCH_ACTIVE, PUNCH_RECOVERY, CAST,
	SHRED_STARTUP, SHRED_LUNGE, SHRED_GRIND,
	KICK_STARTUP, KICK_ACTIVE, KICK_RECOVERY,
	WINGS_OPEN, WINGS_SPIN,
	RECITAL,
	FEAR_STARTUP, FEAR_LUNGE, FEAR_CHEW,
	BITE_STARTUP, BITE_ACTIVE,
}

var md: MimicData
var state: State = State.FREE
var _state_timer := 0.0
var _hit: HitData
var _held: Fighter = null
var _ticks := 0
var _tick_timer := 0.0
var _recital_step := 0
var _wings_hits := {}                     # fighter -> ticks landed (this spin)

## STOLEN SKIN: the copy of the bitten fighter he is wearing (null = himself)
var skin: ControlledFighter = null
var skin_left := 0.0
var _skin_victim: Fighter = null

# Animation values read by MimicArt
var punch_ext := 0.0
var shred_ext := 0.0                      # Arm turned into a blade, stabbing
var kick_ext := 0.0                       # Leg turned into a spike
var wings_k := 0.0                        # 0 = folded in, 1 = fully out
var wings_rot := 0.0                      # Spin angle
var stomach_k := 0.0                      # 0 = closed, 1 = jaws wide open
var jaw_k := 0.0                          # Head bite
var grind_t := 0.0                        # > 0 while grinding (sparks)


# ===== SETUP =====
func _ready() -> void:
	md = data as MimicData
	if md == null:
		md = MimicData.new()
		data = md
	move_ids = ["shred", "kick", "wings"]
	move_names = {"shred": "Shredding Fist", "kick": "Stab Kick", "wings": "Wings of Lies"}
	super._ready()
	knockback_scale = md.knockback_resist


func draw_model_on(c: CanvasItem) -> void:
	MimicArt.draw(c, self)


## Name tag / status text: hidden while he wears a stolen skin (the copy shows its own).
func _draw() -> void:
	if skin != null:
		return
	super._draw()


func _tick_timers(delta: float) -> void:
	super._tick_timers(delta)
	grind_t = maxf(grind_t - delta, 0.0)


# ===== HOOKS =====
func _is_free() -> bool:
	return state == State.FREE


func is_attacking() -> bool:
	return state != State.FREE and state != State.CAST


func _movement_locked() -> bool:
	return state in [State.SHRED_GRIND, State.WINGS_OPEN, State.RECITAL, State.FEAR_STARTUP, State.FEAR_LUNGE,
		State.FEAR_CHEW, State.BITE_STARTUP, State.BITE_ACTIVE, State.KICK_STARTUP, State.KICK_ACTIVE]


func _owns_velocity_x() -> bool:
	return state in [State.SHRED_LUNGE, State.FEAR_LUNGE, State.SHRED_GRIND, State.FEAR_CHEW]


func _can_turn() -> bool:
	return state == State.FREE or state == State.CAST


func _super_armor() -> bool:
	return state in [State.WINGS_OPEN, State.WINGS_SPIN, State.RECITAL, State.FEAR_STARTUP, State.FEAR_LUNGE,
		State.FEAR_CHEW, State.BITE_STARTUP, State.BITE_ACTIVE]


# ===== MAIN LOOP (while wearing a stolen skin, the copy does everything) =====
func _physics_process(delta: float) -> void:
	if skin != null:
		_skin_update(delta)
		return
	super._physics_process(delta)


# ===== INPUT =====
func _handle_actions() -> void:
	if stun_timer > 0.0:
		return
	if ctl.just_pressed("attack") and state == State.FREE:
		_try_punch()
	if ctl.just_pressed("move1"):
		_press_move("shred")
	if ctl.just_pressed("move2"):
		_press_move("kick")
	if ctl.just_pressed("move3"):
		_press_move("wings")
	if ctl.just_pressed("ultimate"):
		_try_ultimate()


func _new_hit(dmg: int, kb: Vector2, move: String, hit_type: String = "melee") -> HitData:
	var h := HitData.new()
	h.source = self
	h.damage = dmg
	h.knockback = Vector2(facing * kb.x, kb.y)
	h.origin = global_position
	h.hit_type = hit_type
	h.move = move
	return h


# ===== PUNCH (no Onslaught) =====
func _try_punch() -> void:
	SoundManager.play_sfx("punch")
	is_blocking = false
	_hit = _new_hit(data.punch_damage, data.punch_knockback, "punch")
	state = State.PUNCH_STARTUP
	_state_timer = data.punch_startup


func _on_hit_landed(victim: Fighter, hit: HitData, result: String) -> void:
	if result != "hit":
		return
	match hit.move:
		"shred":
			_begin_hold(victim, State.SHRED_GRIND, 92.0)
			_ticks = 0
			_tick_timer = md.shred_grind_interval
			Effects.popup(self, global_position + Vector2(0, -190), "GRIND!", Color(0.85, 0.9, 1.0), 22)
		"eating_fear":
			_begin_hold(victim, State.FEAR_CHEW, 34.0)
			_ticks = 0
			_tick_timer = 0.35
			Effects.popup(self, global_position + Vector2(0, -200), "EATING FEAR!", Color(1.0, 0.25, 0.2), 26)
			SoundManager.play_sfx("bite")
		"stolen_skin":
			hitbox.deactivate()
			_try_steal_skin(victim)
		"kick", "recital":
			Effects.hit_sparks(self, victim.global_position + Vector2(0, -80), 10, 1.3)
		_:
			Effects.hit_sparks(self, victim.global_position + Vector2(-facing * 20.0, -96.0), 6, 1.0)


func _begin_hold(victim: Fighter, st: State, hold_dist: float) -> void:
	hitbox.deactivate()
	_held = victim
	grab_hold_distance = hold_dist
	victim.begin_grab(self)
	velocity.x = 0.0
	state = st


func _release_held(kb: Vector2) -> void:
	if _held != null and is_instance_valid(_held) and _held.grabbed_by == self:
		_held.release_grab()
		if kb != Vector2.ZERO and not _held.is_dead:
			_held.apply_knockback(Vector2(facing * kb.x, kb.y), true)
	_held = null


func _held_ok() -> bool:
	return _held != null and is_instance_valid(_held) and not _held.is_dead and _held.grabbed_by == self


# ===== STATE MACHINE =====
func _handle_state(delta: float) -> void:
	match state:
		State.PUNCH_STARTUP:
			_state_timer -= delta
			if _state_timer <= 0.0:
				state = State.PUNCH_ACTIVE
				_state_timer = data.punch_active
				_hit.origin = global_position
				hitbox.activate(_hit, Vector2(facing * data.punch_offset.x, data.punch_offset.y), data.punch_size)
				if is_on_floor():
					velocity.x += facing * data.punch_lunge_speed
		State.PUNCH_ACTIVE:
			_state_timer -= delta
			if _state_timer <= 0.0:
				hitbox.deactivate()
				state = State.PUNCH_RECOVERY
				_state_timer = data.punch_recovery
		State.PUNCH_RECOVERY, State.CAST, State.KICK_RECOVERY:
			_state_timer -= delta
			if _state_timer <= 0.0:
				state = State.FREE
		# --- Shredding Fist ---
		State.SHRED_STARTUP:
			_state_timer -= delta
			if _state_timer <= 0.0:
				state = State.SHRED_LUNGE
				_state_timer = md.shred_active
				_hit.origin = global_position
				hitbox.activate(_hit, Vector2(facing * md.shred_offset.x, md.shred_offset.y), md.shred_size)
				velocity.x = facing * md.shred_lunge_speed
		State.SHRED_LUNGE:
			velocity.x = move_toward(velocity.x, 0.0, 2400.0 * delta)
			_state_timer -= delta
			if _state_timer <= 0.0:
				hitbox.deactivate()
				state = State.CAST
				_state_timer = 0.22
		State.SHRED_GRIND:
			velocity.x = 0.0
			if not _held_ok():
				_release_held(Vector2.ZERO)
				state = State.CAST
				_state_timer = 0.15
				return
			grind_t = 0.2
			_tick_timer -= delta
			if _tick_timer <= 0.0:
				_tick(md.shred_grind_damage, "shred")
				SoundManager.play_sfx("drill", -10.0)
				_ticks += 1
				_tick_timer = md.shred_grind_interval
				if _ticks >= md.shred_grind_ticks:
					_release_held(md.shred_release_knockback)
					state = State.CAST
					_state_timer = 0.2
		# --- Stab Kick ---
		State.KICK_STARTUP:
			_state_timer -= delta
			if _state_timer <= 0.0:
				state = State.KICK_ACTIVE
				_state_timer = md.kick_active
				_hit.origin = global_position
				hitbox.activate(_hit, Vector2(facing * md.kick_offset.x, md.kick_offset.y), md.kick_size)
				SoundManager.play_sfx("swing")
		State.KICK_ACTIVE:
			_state_timer -= delta
			if _state_timer <= 0.0:
				hitbox.deactivate()
				state = State.KICK_RECOVERY
				_state_timer = md.kick_recovery
		# --- Wings of Lies ---
		State.WINGS_OPEN:
			_state_timer -= delta
			if _state_timer <= 0.0:
				state = State.WINGS_SPIN
				_state_timer = md.wings_spin_time
				_tick_timer = 0.0
				_wings_hits.clear()
				SoundManager.play_sfx("whoosh")
		State.WINGS_SPIN:
			wings_rot += delta * 14.0
			_state_timer -= delta
			_tick_timer -= delta
			if _tick_timer <= 0.0:
				_tick_timer = md.wings_tick
				_wings_hit_all(false)
			if _state_timer <= 0.0:
				_wings_hit_all(true)                  # Last turn throws them away
				state = State.CAST
				_state_timer = 0.3
		# --- G1: Recital of Steel ---
		State.RECITAL:
			_state_timer -= delta
			if _state_timer <= 0.0:
				hitbox.deactivate()
				_recital_step += 1
				if _recital_step >= 3:
					state = State.CAST
					_state_timer = 0.3
				else:
					_recital_strike()
		# --- G2: Eating Fear ---
		State.FEAR_STARTUP:
			_state_timer -= delta
			if _state_timer <= 0.0:
				state = State.FEAR_LUNGE
				_state_timer = md.fear_lunge_time
				_hit.origin = global_position
				hitbox.activate(_hit, Vector2(facing * 56.0, -90.0), Vector2(80, 90))
				velocity.x = facing * md.fear_lunge_speed
		State.FEAR_LUNGE:
			velocity.x = facing * md.fear_lunge_speed
			_state_timer -= delta
			if _state_timer <= 0.0:
				hitbox.deactivate()
				velocity.x = 0.0
				state = State.CAST
				_state_timer = 0.4                       # Missed: a moment of shame
		State.FEAR_CHEW:
			velocity.x = 0.0
			if not _held_ok():
				_release_held(Vector2.ZERO)
				state = State.CAST
				_state_timer = 0.3
				return
			_tick_timer -= delta
			if _tick_timer <= 0.0:
				_tick(md.fear_chew_damage, "eating_fear")
				SoundManager.play_sfx("bite", -6.0)
				Effects.hit_sparks(self, global_position + Vector2(facing * 30.0, -84.0), 5, 0.9)
				_ticks += 1
				_tick_timer = md.fear_chew_interval
				if _ticks >= md.fear_chew_ticks:
					_release_held(md.fear_spit_knockback)   # Spits them out: it never actually eats
					Effects.popup(self, global_position + Vector2(0, -200), "SPAT OUT!", Color(1.0, 0.5, 0.4), 22)
					state = State.CAST
					_state_timer = 0.35
		# --- G3: Stolen Skin (the bite) ---
		State.BITE_STARTUP:
			_state_timer -= delta
			if _state_timer <= 0.0:
				state = State.BITE_ACTIVE
				_state_timer = md.bite_active
				_hit.origin = global_position
				hitbox.activate(_hit, Vector2(facing * md.bite_offset.x, md.bite_offset.y), md.bite_size)
				velocity.x = facing * 260.0
		State.BITE_ACTIVE:
			_state_timer -= delta
			if _state_timer <= 0.0:
				hitbox.deactivate()
				state = State.CAST
				_state_timer = 0.35


func _tick(dmg: int, move: String) -> void:
	var h := HitData.new()
	h.source = self
	h.damage = dmg
	h.blockable = false
	h.causes_hitstun = false
	h.knockback = Vector2.ZERO
	h.origin = global_position
	h.hit_type = "drill_tick"
	h.is_tick = true
	h.move = move
	CombatManager.apply_hit(h, _held)


func _interrupt() -> void:
	hitbox.deactivate()
	_release_held(Vector2.ZERO)
	state = State.FREE


# ===== MOVES (1 / 2 / 3) =====
func _cast_move(id: String) -> void:
	match id:
		"shred":
			_hit = _new_hit(md.shred_damage, Vector2(80, -40), "shred", "sword")
			_hit.is_grab = true
			_hit.causes_hitstun = false
			state = State.SHRED_STARTUP
			_state_timer = md.shred_startup
			_start_cooldown("shred", md.shred_cooldown)
		"kick":
			_hit = _new_hit(md.kick_damage, md.kick_knockback, "kick", "spike")
			state = State.KICK_STARTUP
			_state_timer = md.kick_startup
			_start_cooldown("kick", md.kick_cooldown)
		"wings":
			state = State.WINGS_OPEN
			_state_timer = md.wings_open_time
			_start_cooldown("wings", md.wings_cooldown)


## Wings of Lies: every enemy in range takes a hit (the last turn throws them away).
func _wings_hit_all(final: bool) -> void:
	var center := global_position + Vector2(0, -90)
	for n in get_tree().get_nodes_in_group("fighters"):
		var f := n as Fighter
		if f == null or f == self or f.is_dead or CombatManager.are_allies(self, f):
			continue
		if (f.global_position + Vector2(0, -64)).distance_to(center) > md.wings_radius + 32.0:
			continue
		var dx := signf(f.global_position.x - global_position.x)
		if dx == 0.0:
			dx = float(facing)
		var h := HitData.new()
		h.source = self
		h.damage = md.wings_final_damage if final else md.wings_damage
		var kb: Vector2 = md.wings_final_knockback if final else md.wings_knockback
		h.knockback = Vector2(dx * kb.x, kb.y)
		h.origin = global_position
		h.hit_type = "sword"
		h.move = "wings"
		CombatManager.apply_hit(h, f)


# ===== ULTIMATE (G) =====
func _try_ultimate() -> void:
	if gauge == null or state != State.FREE or skin != null:
		return
	var tier := gauge.segments()
	if tier <= 0:
		if is_human():
			Effects.popup(self, global_position + Vector2(0, -170), "G GAUGE EMPTY", Color(0.8, 0.8, 0.8), 18)
		return
	is_blocking = false
	gauge.consume_segments(tier)
	match tier:
		1:
			announce_move("RECITAL OF STEEL!", Color(0.8, 0.88, 1.0))
			_recital_step = 0
			state = State.RECITAL
			_recital_strike()
		2:
			announce_move("EATING FEAR!", Color(1.0, 0.25, 0.2))
			_hit = _new_hit(md.fear_grab_damage, Vector2.ZERO, "eating_fear", "grab")
			_hit.is_grab = true
			_hit.blockable = false
			_hit.causes_hitstun = false
			state = State.FEAR_STARTUP
			_state_timer = md.fear_startup
		_:
			announce_move("STOLEN SKIN!", Color(1.0, 0.1, 0.1))
			_hit = _new_hit(md.bite_damage, Vector2(60, -40), "stolen_skin", "melee")
			state = State.BITE_STARTUP
			_state_timer = md.bite_startup


## Recital of Steel: step 0 Shredding Fist, 1 a Fist, 2 the Shredding Kick.
func _recital_strike() -> void:
	# Face the enemy before every strike, and only lunge when they are out of reach (fighters
	# don't block each other: a blind lunge carried him right THROUGH them and the kick missed)
	var foe := CombatManager.find_enemy(self)
	var lunge := md.recital_lunge
	if foe != null:
		var dx := foe.global_position.x - global_position.x
		if absf(dx) > 4.0:
			facing = 1 if dx > 0.0 else -1
		lunge = 0.0 if absf(dx) < 80.0 else minf(md.recital_lunge, (absf(dx) - 70.0) * 4.0)
	var kb: Vector2 = md.recital_knockback[_recital_step]
	_hit = _new_hit(int(md.recital_damage[_recital_step]), kb, "recital", "sword" if _recital_step != 1 else "melee")
	_hit.part = ["shredding_fist", "fist", "shredding_kick"][_recital_step]
	var off := Vector2(60, -104) if _recital_step < 2 else Vector2(66, -58)
	hitbox.activate(_hit, Vector2(facing * off.x, off.y), Vector2(110, 84))
	velocity.x = facing * lunge
	_state_timer = md.recital_step_time
	SoundManager.play_sfx("sword_slash" if _recital_step != 1 else "punch")


# ============================================================
# STOLEN SKIN (G3): wear the bitten fighter for 30 seconds
# ============================================================
## The roster entry of a fighter (only PLAYABLE characters can be copied).
func _entry_for(victim: Fighter) -> Dictionary:
	if victim == null or victim is BaseEnemy or victim is Mimic or not (victim is ControlledFighter):
		return {}
	for e in CharacterRoster.all():
		if not e.get("enemy", false) and e.get("fighter", null) == victim.get_script():
			return e
	return {}


func _try_steal_skin(victim: Fighter) -> void:
	if skin != null:
		return                                       # Already wearing one
	var entry := _entry_for(victim)
	if entry.is_empty():
		# Bosses, enemies, the Dummy, another Mimic: nothing to copy - a much harder bite instead
		var h := _new_hit(md.bite_damage_no_copy - md.bite_damage, Vector2(300, -200), "stolen_skin")
		CombatManager.apply_hit(h, victim)
		Effects.popup(self, global_position + Vector2(0, -200), "CAN'T COPY THAT!", Color(1.0, 0.4, 0.3), 22)
		return
	var copy := (entry["fighter"] as Script).new() as ControlledFighter
	if copy == null:
		return
	copy.name = "%s_StolenSkin" % name
	copy.slot = slot
	copy.team = team
	copy.default_facing = facing
	copy.facing = facing
	copy.respawn_enabled = false
	copy.position = position
	copy.ctl = FighterInput.new() if is_human() else (entry.get("ai", BaseAI) as Script).new()
	copy.set_meta("mimic", self)
	get_parent().add_child(copy)
	copy.spawn_position = global_position
	copy.damaged.connect(_on_skin_damaged)
	copy.died.connect(_on_skin_died)
	skin = copy
	skin_left = md.skin_duration
	_skin_victim = victim
	if not victim.died.is_connected(_on_victim_died):
		victim.died.connect(_on_victim_died)
	# The steel body goes away while the skin is worn
	state = State.FREE
	velocity = Vector2.ZERO
	visuals.visible = false
	hurtbox.set_deferred("monitorable", false)
	collision_layer = 0
	Effects.explosion(self, global_position + Vector2(0, -80), 70.0)
	SoundManager.play_sfx("ultimate", -2.0)
	announce_move("STOLEN SKIN: %s!" % String(entry["short"]).to_upper(), Color(1.0, 0.1, 0.1))
	if is_human():
		Achievements.unlock("mimic_steal")


func _skin_update(delta: float) -> void:
	if not is_instance_valid(skin):
		_end_skin()
		return
	global_position = skin.global_position
	facing = skin.facing
	if CombatManager.fight_active and not is_time_frozen():
		skin_left -= delta
	if skin_left <= 0.0:
		_end_skin()


## Every hit on the copy is HIS damage (the copy itself never loses HP).
func _on_skin_damaged(amount: int, hit: HitData) -> void:
	if amount <= 0 or is_dead or skin == null:
		return
	last_hit = hit
	hp = maxi(hp - amount, 0)
	if MatchSettings.god_mode_active():
		hp = data.max_hp
	health_changed.emit(hp, data.max_hp)
	damaged.emit(amount, hit)
	if is_instance_valid(skin):
		skin.hp = skin.data.max_hp
	if hp <= 0:
		_end_skin()
		die()


## The copy fell off the island: so did he.
func _on_skin_died() -> void:
	if skin == null:
		return
	_end_skin()
	die(DeathManager.FALL)


func _on_victim_died() -> void:
	if skin != null and is_human() and not is_dead:
		Achievements.unlock("mimic_copy_ko")       # K.O. while wearing their skin


func _end_skin() -> void:
	if skin == null:
		return
	var s := skin
	skin = null
	if is_instance_valid(s):
		global_position = s.global_position
		facing = s.facing
		if s.damaged.is_connected(_on_skin_damaged):
			s.damaged.disconnect(_on_skin_damaged)
		if s.died.is_connected(_on_skin_died):
			s.died.disconnect(_on_skin_died)
		for n in get_tree().get_nodes_in_group("fighters"):      # Let go of anything the copy held
			var f := n as Fighter
			if f != null and f.grabbed_by == s:
				f.release_grab()
		s.queue_free()
	skin_left = 0.0
	_skin_victim = null
	velocity = Vector2.ZERO
	collision_layer = CombatManager.BODY_LAYER
	if not is_dead:
		visuals.visible = true
		hurtbox.set_deferred("monitorable", true)
		Effects.explosion(self, global_position + Vector2(0, -80), 60.0)
		Effects.popup(self, global_position + Vector2(0, -200), "THE SKIN TEARS", Color(0.85, 0.9, 1.0), 22)


# ===== DEATH / RESPAWN =====
func _on_death_extra() -> void:
	_end_skin()
	_release_held(Vector2.ZERO)
	punch_ext = 0.0
	shred_ext = 0.0
	kick_ext = 0.0
	wings_k = 0.0
	stomach_k = 0.0
	jaw_k = 0.0


func _on_respawn_extra() -> void:
	state = State.FREE
	knockback_scale = md.knockback_resist


func _exit_tree() -> void:
	if skin != null and is_instance_valid(skin):
		skin.queue_free()


# ===== VISUALS =====
func _update_visuals(delta: float) -> void:
	anim_time += delta
	if is_on_floor():
		walk_phase += absf(velocity.x) * delta * 0.036
	block_amt = move_toward(block_amt, 1.0 if is_blocking else 0.0, delta * 9.0)
	var p := 0.0
	match state:
		State.PUNCH_STARTUP:
			p = -0.5 * (1.0 - _state_timer / data.punch_startup)
		State.PUNCH_ACTIVE:
			p = 1.0
		State.PUNCH_RECOVERY:
			p = clampf(_state_timer / data.punch_recovery, 0.0, 1.0)
	punch_ext = p
	var sh := 0.0
	if state == State.SHRED_STARTUP:
		sh = -0.4
	elif state in [State.SHRED_LUNGE, State.SHRED_GRIND] or (state == State.RECITAL and _recital_step == 0):
		sh = 1.0
	shred_ext = move_toward(shred_ext, sh, delta * 9.0)
	if state == State.RECITAL and _recital_step == 1:
		punch_ext = 1.0
	var k := 0.0
	if state == State.KICK_STARTUP:
		k = -0.4
	elif state == State.KICK_ACTIVE or (state == State.RECITAL and _recital_step == 2):
		k = 1.0
	elif state == State.KICK_RECOVERY:
		k = 0.5
	kick_ext = move_toward(kick_ext, k, delta * 10.0)
	wings_k = move_toward(wings_k, 1.0 if state in [State.WINGS_OPEN, State.WINGS_SPIN] else 0.0, delta * 6.0)
	if wings_k <= 0.0:
		wings_rot = 0.0
	stomach_k = move_toward(stomach_k, 1.0 if state in [State.FEAR_STARTUP, State.FEAR_LUNGE, State.FEAR_CHEW] else 0.0, delta * 6.0)
	jaw_k = move_toward(jaw_k, 1.0 if state in [State.BITE_STARTUP, State.BITE_ACTIVE] else 0.0, delta * 10.0)
	z_index = 2 if state == State.FEAR_CHEW else 0      # Eating Fear: the victim is INSIDE his open ribs
	var cs := 0.9 if is_crouching else 1.0
	visuals.scale = Vector2(facing * cs, cs)
	visuals.queue_redraw()
