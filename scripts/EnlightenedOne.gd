class_name EnlightenedOne
extends ControlledFighter
## The Enlightened One: golden-armored masked pilgrim who fights with bronze gauntlets.
## Can be the Player (keyboard) or the Opponent (EnlightenedOneAI). Same 64x128 body.
## Every number comes from EnlightenedOneData (res://data/EnlightenedOneData.gd).
##
##   Click  Bronze Gloves punch (4 dmg, Architect range). NOT Onslaught-able.
##   1      Beam Blast    - 2 thin golden beams, 5 dmg each
##   2      Lord's Heal   - heals 40% max HP to every ally in radius (1v1: himself)
##   3      Helpers!      - 2 cocooned blade helpers (5 dmg slashes, 20 HP, 10 s)
##   G x1   Godly O' Light  - one huge wide beam, 25 dmg, big knockback
##   G x2   Throne          - golden throne hurled at the opponent, 30 dmg
##   G x3   Enlightened Gorilla Form - 20 s: bigger, M1 ONLY, 9 dmg, faster, longer reach
##   WEAKNESS: x1.25 damage from EXPLOSION and VOID damage (see EnlightenedOneData).

enum State {
	FREE, PUNCH_STARTUP, PUNCH_ACTIVE, PUNCH_RECOVERY, CAST,
	LIGHT_CHARGE, LIGHT_FIRE, LIGHT_RECOVER,
}

var ed: EnlightenedOneData
var state: State = State.FREE
var _state_timer := 0.0
var _punch_hit: HitData
var light_box: Hitbox

var gorilla_timer := 0.0

# Animation values read by EnlightenedOneArt
var punch_ext := 0.0
var cast_pose := 0.0
var heal_t := 0.0                # > 0 while the heal ring plays
var light_charge := 0.0
var light_fire := 0.0


# ===== SETUP =====
func _ready() -> void:
	ed = data as EnlightenedOneData
	if ed == null:
		ed = EnlightenedOneData.new()
		data = ed
	move_ids = ["beam", "heal", "helpers"]
	move_names = {"beam": "Beam Blast", "heal": "Lord's Heal", "helpers": "Helpers!"}
	super._ready()
	light_box = Hitbox.new()
	light_box.name = "LightBox"
	add_child(light_box)
	light_box.setup(self)
	light_box.hit_landed.connect(_on_light_hit)


func draw_model_on(c: CanvasItem) -> void:
	EnlightenedOneArt.draw(c, self)


func is_gorilla() -> bool:
	return gorilla_timer > 0.0


func _tick_timers(delta: float) -> void:
	super._tick_timers(delta)
	heal_t = maxf(heal_t - delta, 0.0)
	cast_pose = move_toward(cast_pose, 0.0, delta * 3.0)
	if gorilla_timer > 0.0:
		gorilla_timer -= delta
		if gorilla_timer <= 0.0:
			_end_gorilla()


# ===== HOOKS =====
func _is_free() -> bool:
	return state == State.FREE


func is_attacking() -> bool:
	return state == State.PUNCH_STARTUP or state == State.PUNCH_ACTIVE or state == State.PUNCH_RECOVERY


func _movement_locked() -> bool:
	return state == State.LIGHT_CHARGE or state == State.LIGHT_FIRE or state == State.LIGHT_RECOVER


func _speed_multiplier() -> float:
	return ed.gorilla_move_mult if is_gorilla() else 1.0


func _can_turn() -> bool:
	return state == State.FREE or state == State.CAST


func _super_armor() -> bool:
	return state == State.LIGHT_CHARGE or state == State.LIGHT_FIRE


func _timing_mult() -> float:
	return ed.gorilla_speed_mult if is_gorilla() else 1.0


# ===== INPUT =====
func _handle_actions() -> void:
	if stun_timer > 0.0:
		return
	if ctl.just_pressed("attack") and state == State.FREE:
		_try_punch()
	if is_gorilla():
		return                                   # Gorilla Form: ONLY M1s
	if ctl.just_pressed("move1"):
		_press_move("beam")
	if ctl.just_pressed("move2"):
		_press_move("heal")
	if ctl.just_pressed("move3"):
		_press_move("helpers")
	if ctl.just_pressed("ultimate"):
		_try_ultimate()


# ===== M1: BRONZE GLOVES (no Onslaught) =====
func _try_punch() -> void:
	SoundManager.play_sfx("punch")
	is_blocking = false
	_punch_hit = HitData.new()
	_punch_hit.source = self
	_punch_hit.damage = ed.gorilla_damage if is_gorilla() else data.punch_damage
	var kb := data.punch_knockback * (1.4 if is_gorilla() else 1.0)
	_punch_hit.knockback = Vector2(facing * kb.x, kb.y)
	_punch_hit.origin = global_position
	_punch_hit.hit_type = "melee"
	_punch_hit.move = "gorilla" if is_gorilla() else "gloves"
	state = State.PUNCH_STARTUP
	_state_timer = data.punch_startup * _timing_mult()


func _on_hit_landed(victim: Fighter, hit: HitData, result: String) -> void:
	if (hit.move == "gloves" or hit.move == "gorilla") and result == "hit":
		Effects.gold_burst(self, victim.global_position + Vector2(-facing * 20.0, -88.0), 40.0 if is_gorilla() else 26.0)


# ===== STATE MACHINE =====
func _handle_state(delta: float) -> void:
	match state:
		State.PUNCH_STARTUP:
			_state_timer -= delta
			if _state_timer <= 0.0:
				state = State.PUNCH_ACTIVE
				_state_timer = data.punch_active * _timing_mult()
				var reach := ed.gorilla_range_mult if is_gorilla() else 1.0
				var off := Vector2(data.punch_offset.x * reach, data.punch_offset.y)
				_punch_hit.origin = global_position
				hitbox.activate(_punch_hit, Vector2(facing * off.x, off.y), Vector2(data.punch_size.x * reach, data.punch_size.y * (1.2 if is_gorilla() else 1.0)))
				if is_on_floor():
					velocity.x += facing * data.punch_lunge_speed
		State.PUNCH_ACTIVE:
			_state_timer -= delta
			if _state_timer <= 0.0:
				hitbox.deactivate()
				state = State.PUNCH_RECOVERY
				_state_timer = data.punch_recovery * _timing_mult()
		State.PUNCH_RECOVERY, State.CAST, State.LIGHT_RECOVER:
			_state_timer -= delta
			if _state_timer <= 0.0:
				state = State.FREE
		State.LIGHT_CHARGE:
			_state_timer -= delta
			if _state_timer <= 0.0:
				_fire_light()
		State.LIGHT_FIRE:
			_state_timer -= delta
			if _state_timer <= 0.0:
				light_box.deactivate()
				state = State.LIGHT_RECOVER
				_state_timer = ed.light_recovery


func _interrupt() -> void:
	hitbox.deactivate()
	light_box.deactivate()
	state = State.FREE


func _begin_cast(lock: float) -> void:
	state = State.CAST
	_state_timer = lock


# ===== MOVES =====
func _cast_move(id: String) -> void:
	match id:
		"beam":
			_beam_blast()
		"heal":
			_lords_heal()
		"helpers":
			_spawn_helpers()


# --- 1: Beam Blast ---
func _beam_blast() -> void:
	for i in ed.beam_count:
		var b := OptimizationManager.take(LightBolt) as LightBolt            # Pooled
		b.source = self
		b.damage = ed.beam_damage
		b.speed = ed.beam_speed
		b.lifetime = ed.beam_lifetime
		b.knockback = ed.beam_knockback
		b.dir = Vector2(facing, 0)
		get_parent().add_child(b)
		var dy := (float(i) - float(ed.beam_count - 1) * 0.5) * ed.beam_spacing
		b.global_position = global_position + Vector2(facing * ed.beam_spawn_offset.x, ed.beam_spawn_offset.y + dy)
	cast_pose = 1.0
	_start_cooldown("beam", ed.beam_cooldown)
	_begin_cast(0.22)


# --- 2: Lord's Heal: 40% max HP to every ally (same team) in radius ---
## Works at full HP too (it just heals nothing).
func _lords_heal() -> void:
	heal_t = 0.8
	var total := 0
	var center := global_position + Vector2(0, -64)
	var allies: Array = get_tree().get_nodes_in_group("fighters") + get_tree().get_nodes_in_group("helpers")
	for n in allies:
		var f := n as Fighter
		if f == null or f.is_dead or not CombatManager.are_allies(self, f):
			continue
		if (f.global_position + Vector2(0, -64)).distance_to(center) > ed.heal_radius:
			continue
		total += f.heal(roundi(f.data.max_hp * ed.heal_percent))
	if total == 0:
		Effects.popup(self, global_position + Vector2(0, -150), "ALREADY FULL HP", Color(1.0, 0.9, 0.6), 16)
	_start_cooldown("heal", ed.heal_cooldown)
	_begin_cast(0.35)


# --- 3: Helpers! ---
func _spawn_helpers() -> void:
	for i in ed.helper_count:
		var h := HelperMinion.new()
		h.summoner = self
		h.lifetime = ed.helper_lifetime
		h.speed = ed.helper_speed
		h.max_health = ed.helper_hp
		h.slash_damage = ed.helper_slash_damage
		h.slash_range = ed.helper_slash_range
		h.slash_interval = ed.helper_slash_interval
		h.slash_knockback = ed.helper_knockback
		h.position = global_position + Vector2(facing * (40.0 + 34.0 * float(i)) + randf_range(-10.0, 10.0), -4.0)
		get_parent().add_child(h)
	Effects.gold_burst(self, global_position + Vector2(facing * 55.0, -24.0), 50.0)
	announce_move("HELPERS!", Color(1.0, 0.95, 0.8))
	cast_pose = 1.0
	_start_cooldown("helpers", ed.helpers_cooldown)
	_begin_cast(0.3)


# ===== ULTIMATE (G) - no passive, gauge only fuels these =====
func _try_ultimate() -> void:
	if gauge == null or state != State.FREE or is_gorilla():
		return
	var tier := gauge.segments()
	if tier <= 0:
		if is_human():
			Effects.popup(self, global_position + Vector2(0, -150), "G GAUGE EMPTY", Color(0.8, 0.8, 0.8), 18)
		return
	is_blocking = false
	gauge.consume_segments(tier)
	match tier:
		1:
			_ult_godly_light()
		2:
			_ult_throne()
		_:
			_ult_gorilla()


# --- G1: Godly O' Light ---
func _ult_godly_light() -> void:
	announce_move("GODLY O' LIGHT!", Color(1.0, 0.9, 0.4))
	state = State.LIGHT_CHARGE
	_state_timer = ed.light_charge
	velocity.x = 0.0


func _fire_light() -> void:
	SoundManager.play_sfx("beam")
	state = State.LIGHT_FIRE
	_state_timer = ed.light_duration
	var h := HitData.new()
	h.source = self
	h.damage = ed.light_damage
	h.knockback = Vector2(facing * ed.light_knockback.x, ed.light_knockback.y)
	h.origin = global_position
	h.hit_type = "light"
	h.move = "godly_light"
	light_box.activate(h, Vector2(facing * (30.0 + ed.light_range * 0.5), -84.0), Vector2(ed.light_range, ed.light_height))


func _on_light_hit(victim: Fighter, _hit: HitData, result: String) -> void:
	if result == "hit":
		Effects.gold_burst(self, victim.global_position + Vector2(0, -70), 70.0)


# --- G2: Throne ---
func _ult_throne() -> void:
	announce_move("THRONE!", Color(1.0, 0.85, 0.3))
	var t := Throne.new()
	t.source = self
	t.damage = ed.throne_damage
	t.speed = ed.throne_speed
	t.turn_rate = ed.throne_turn_rate
	t.lifetime = ed.throne_lifetime
	t.knockback = ed.throne_knockback
	t.dir = Vector2(facing, -0.15).normalized()
	get_parent().add_child(t)
	t.global_position = global_position + Vector2(facing * 70.0, -90.0)
	cast_pose = 1.0
	_begin_cast(0.4)


# --- G3: Enlightened Gorilla Form ---
func _ult_gorilla() -> void:
	announce_move("ENLIGHTENED GORILLA FORM!", Color(1.0, 0.85, 0.3))
	Effects.gold_burst(self, global_position + Vector2(0, -64), 110.0)
	gorilla_timer = ed.gorilla_duration
	_begin_cast(0.4)


func _end_gorilla() -> void:
	gorilla_timer = 0.0
	Effects.gold_burst(self, global_position + Vector2(0, -64), 70.0)


# ===== DEATH / RESPAWN =====
func _on_death_extra() -> void:
	gorilla_timer = 0.0
	punch_ext = 0.0
	light_charge = 0.0
	light_fire = 0.0


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
			ext = -0.5 * (1.0 - _state_timer / maxf(data.punch_startup * _timing_mult(), 0.001))
		State.PUNCH_ACTIVE:
			ext = 1.0
		State.PUNCH_RECOVERY:
			ext = clampf(_state_timer / maxf(data.punch_recovery * _timing_mult(), 0.001), 0.0, 1.0)
	punch_ext = ext
	light_charge = 1.0 - clampf(_state_timer / ed.light_charge, 0.0, 1.0) if state == State.LIGHT_CHARGE else 0.0
	light_fire = clampf(_state_timer / ed.light_duration, 0.0, 1.0) if state == State.LIGHT_FIRE else 0.0
	var sc := ed.gorilla_scale if is_gorilla() else 1.0
	sc *= 0.88 if is_crouching else 1.0               # Uniform: never squashed
	visuals.scale = Vector2(facing * sc, sc)
	visuals.queue_redraw()
