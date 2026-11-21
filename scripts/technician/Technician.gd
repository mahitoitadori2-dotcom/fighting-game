class_name Technician
extends ControlledFighter
## THE TECHNICIAN (Versus): Claude's own character (2026-11-16). Canon to Terra Craterum: the
## Kharleming TECHNICIANS were the engineers of the ancient ship (the Technician's Breaker carries
## their name). One survived the crash - a small Kharleming inside a walking RIG it built from the
## wreck's scrap. It never took a side in the war between the lava and the Kharlemings.
## A ZONER / TRAPPER: strong at range, weaker up close. Can NOT Onslaught.
## Every number comes from TechnicianData (res://data/TechnicianData.gd).
##
##   Click  Wrench (4 dmg). NOT Onslaught-able.
##   1      Scrap Turret  - drops a turret that fires scrap bolts at the nearest foe for 6 s
##   2      Cable Hook    - fires a cable forward: the first foe hit is hurt and YANKED to you
##   3      Spark Coil    - slams a coil: an electric ring around him, damage + a short stun
##   G x1   Repair Protocol   - heals 3 x 6 HP over 3 seconds
##   G x2   Colony Drones     - 3 little winged drones home in on foes and explode
##   G x3   The Technician's Breaker - thrown; beeps three times, then a HUGE unblockable blast
##                                     (run out of the red circle!)

enum State { FREE, PUNCH_STARTUP, PUNCH_ACTIVE, PUNCH_RECOVERY, CAST, HOOK_STARTUP, COIL_STARTUP }

var td: TechnicianData
var state: State = State.FREE
var _state_timer := 0.0
var _hit: HitData
var _turret: Node = null
var _repair_left := 0
var _repair_t := 0.0

# Animation values read by TechnicianArt
var punch_ext := 0.0
var tool_k := 0.0                          # Turret drop / hook aim / coil slam pose
var coil_flash := 0.0
var heal_glow := 0.0


func _ready() -> void:
	td = data as TechnicianData
	if td == null:
		td = TechnicianData.new()
		data = td
	move_ids = ["turret", "hook", "coil"]
	move_names = {"turret": "Scrap Turret", "hook": "Cable Hook", "coil": "Spark Coil"}
	super._ready()


func draw_model_on(c: CanvasItem) -> void:
	TechnicianArt.draw(c, self)


func _tick_timers(delta: float) -> void:
	super._tick_timers(delta)
	coil_flash = maxf(coil_flash - delta, 0.0)
	heal_glow = maxf(heal_glow - delta, 0.0)
	if _repair_left > 0 and not is_dead and not is_time_frozen():
		_repair_t -= delta
		if _repair_t <= 0.0:
			_repair_t = 1.0
			_repair_left -= 1
			hp = mini(hp + td.repair_heal, data.max_hp)
			health_changed.emit(hp, data.max_hp)
			heal_glow = 0.5
			Effects.popup(self, global_position + Vector2(0, -170), "+%d" % td.repair_heal, Color(0.5, 1.0, 0.9), 20)
			SoundManager.play_sfx("heal", -8.0)


func _is_free() -> bool:
	return state == State.FREE


func is_attacking() -> bool:
	return state != State.FREE and state != State.CAST


func _movement_locked() -> bool:
	return state in [State.HOOK_STARTUP, State.COIL_STARTUP]


func _can_turn() -> bool:
	return state == State.FREE or state == State.CAST


func _handle_actions() -> void:
	if stun_timer > 0.0:
		return
	if ctl.just_pressed("attack") and state == State.FREE:
		_try_punch()
	if ctl.just_pressed("move1"):
		_press_move("turret")
	if ctl.just_pressed("move2"):
		_press_move("hook")
	if ctl.just_pressed("move3"):
		_press_move("coil")
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


# ===== WRENCH (no Onslaught) =====
func _try_punch() -> void:
	SoundManager.play_sfx("swing", -4.0)
	is_blocking = false
	_hit = _new_hit(data.punch_damage, data.punch_knockback, "wrench")
	state = State.PUNCH_STARTUP
	_state_timer = data.punch_startup


func _handle_state(delta: float) -> void:
	match state:
		State.PUNCH_STARTUP:
			_state_timer -= delta
			if _state_timer <= 0.0:
				state = State.PUNCH_ACTIVE
				_state_timer = data.punch_active
				_hit.origin = global_position
				hitbox.activate(_hit, Vector2(facing * data.punch_offset.x, data.punch_offset.y), data.punch_size)
		State.PUNCH_ACTIVE:
			_state_timer -= delta
			if _state_timer <= 0.0:
				hitbox.deactivate()
				state = State.PUNCH_RECOVERY
				_state_timer = data.punch_recovery
		State.PUNCH_RECOVERY, State.CAST:
			_state_timer -= delta
			if _state_timer <= 0.0:
				state = State.FREE
		State.HOOK_STARTUP:
			_state_timer -= delta
			if _state_timer <= 0.0:
				var hk := TechGadgets.Hook.new()
				hk.owner_f = self
				hk.data = td
				hk.dir = float(facing)
				get_parent().add_child(hk)
				hk.global_position = global_position + Vector2(facing * 30.0, -84)
				SoundManager.play_sfx("whoosh")
				state = State.CAST
				_state_timer = 0.25
		State.COIL_STARTUP:
			_state_timer -= delta
			if _state_timer <= 0.0:
				_spark_coil()
				state = State.CAST
				_state_timer = 0.3


func _interrupt() -> void:
	hitbox.deactivate()
	state = State.FREE


# ===== MOVES (1 / 2 / 3) =====
func _cast_move(id: String) -> void:
	match id:
		"turret":
			if _turret != null and is_instance_valid(_turret):
				_turret.queue_free()                      # One turret at a time
			var turret_node := TechGadgets.Turret.new()
			turret_node.owner_f = self
			turret_node.data = td
			turret_node.life = td.turret_life
			turret_node.hp = td.turret_hp
			get_parent().add_child(turret_node)
			turret_node.global_position = Vector2(global_position.x + facing * 40.0, global_position.y)
			_turret = turret_node
			SoundManager.play_sfx("stone", -4.0)
			state = State.CAST
			_state_timer = 0.25
			_start_cooldown("turret", td.turret_cooldown)
		"hook":
			state = State.HOOK_STARTUP
			_state_timer = td.hook_startup
			_start_cooldown("hook", td.hook_cooldown)
		"coil":
			state = State.COIL_STARTUP
			_state_timer = td.coil_startup
			_start_cooldown("coil", td.coil_cooldown)


func _spark_coil() -> void:
	coil_flash = 0.35
	var center := global_position + Vector2(0, -60)
	for f in TechGadgets._foes(self):
		var fc: Vector2 = (f as Fighter).global_position + Vector2(0, -60)
		if fc.distance_to(center) > td.coil_radius + 30.0:
			continue
		var dx := signf(fc.x - global_position.x)
		if dx == 0.0:
			dx = float(facing)
		TechGadgets.hit(self, f, td.coil_damage, Vector2(dx * td.coil_knockback.x, td.coil_knockback.y), "spark_coil", "shock", td.coil_stun)
	Effects.explosion(self, center, td.coil_radius * 0.6)
	SoundManager.play_sfx("beam", -2.0)


# ===== ULTIMATE (G) =====
func _try_ultimate() -> void:
	if gauge == null or state != State.FREE:
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
			announce_move("REPAIR PROTOCOL!", Color(0.5, 1.0, 0.9))
			_repair_left = td.repair_ticks
			_repair_t = 0.0
		2:
			announce_move("COLONY DRONES!", Color(0.6, 0.9, 1.0))
			for i in td.drone_count:
				var d := TechGadgets.Drone.new()
				d.owner_f = self
				d.damage = td.drone_damage
				d.speed = td.drone_speed
				d.life = td.drone_life
				get_parent().add_child(d)
				d.global_position = global_position + Vector2(-facing * 20.0 + float(i - 1) * 26.0, -130.0 - float(i % 2) * 20.0)
				d._vel = Vector2(facing * 200.0, -120.0 + float(i) * 60.0)
			SoundManager.play_sfx("whoosh")
		_:
			announce_move("THE TECHNICIAN'S BREAKER!", Color(1.0, 0.25, 0.2))
			var b := TechGadgets.Breaker.new()
			b.owner_f = self
			b.data = td
			b.fuse = td.breaker_fuse
			get_parent().add_child(b)
			b.global_position = Vector2(global_position.x + facing * td.breaker_throw, global_position.y)
			SoundManager.play_sfx("chain")
			if is_human():
				Achievements.unlock("tech_breaker")
	state = State.CAST
	_state_timer = 0.3


func _on_death_extra() -> void:
	_repair_left = 0
	punch_ext = 0.0
	tool_k = 0.0


func _on_respawn_extra() -> void:
	state = State.FREE


func _exit_tree() -> void:
	if _turret != null and is_instance_valid(_turret):
		_turret.queue_free()


func _update_visuals(delta: float) -> void:
	anim_time += delta
	if is_on_floor():
		walk_phase += absf(velocity.x) * delta * 0.04
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
	tool_k = move_toward(tool_k, 1.0 if state in [State.HOOK_STARTUP, State.COIL_STARTUP, State.CAST] else 0.0, delta * 8.0)
	var cs := 1.0 if anim_legs else (0.9 if is_crouching else 1.0)   # Crouch: knees bend (shared animation)
	visuals.scale = Vector2(facing * cs, cs)
	visuals.queue_redraw()
