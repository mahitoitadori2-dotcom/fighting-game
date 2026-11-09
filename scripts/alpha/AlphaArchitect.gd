class_name AlphaArchitect
extends ControlledFighter
## APHA ARCHITECT - a powerful, complicated playable character (Versus). 2500 HP, NO G Gauge.
##   Punch       every punch is an ONSLAUGHT punch (heavy, fast). In FLIGHT: an AIR CHARGE (dash).
##   E           Flight ON / OFF. Flying: Jump = up, Crouch = down. Powers switch to air variants.
##   1 THUNDERCLAP          ground: electrified shockwave (stuns) | air: compressed wind tornado
##   2 GODLY TOUCH          ground only: a light touch = 3 random debuffs
##   3 BARRAGE OF VADIS     ground: clones throw a barrage of fists | air: the clones shoot lasers
##   4 PORTAL MANIFESTATION a portal throws rocks, shards, orbs and debris at enemies (both)
##   5 PURE IMPLOSION OF DECAY  CINEMATIC: flies up, gathers gas into a ball, throws it down: implosion + decay
##   6 WORLD IMPLOSION BOMB     CINEMATIC + CUTSCENE: energy rods, hovering over the Earth, pierce it
##   7 WORLD OPENING            CINEMATIC: eyes close, a barrier, giant hands tear everything apart
## The cinematic powers (5-7) freeze everyone else, zoom the camera, slow time and show black bars;
## he can't be hurt while they play. All numbers are in AlphaArchitectData.

enum State { FREE, PUNCH_STARTUP, PUNCH_ACTIVE, PUNCH_RECOVERY, AIR_CHARGE, CAST, BARRAGE, CINEMATIC }

const GROUND_NAMES := {"clap": "Thunderclap", "touch": "Godly Touch", "vadis": "Barrage of Vadis", "portal": "Portal Manifestation",
	"decay": "Pure Implosion of Decay", "rod": "World Implosion Bomb", "opening": "World Opening"}
const AIR_NAMES := {"clap": "Wind Tornado", "touch": "Godly Touch (ground only)", "vadis": "Vadis Lasers", "portal": "Portal Manifestation",
	"decay": "Pure Implosion of Decay", "rod": "World Implosion Bomb", "opening": "World Opening"}

var ad: AlphaArchitectData
var state: State = State.FREE
var flying := false
var pose := ""                       # Art pose: clap / touch / barrage / portal / decay / rod / throw / opening
var pose_t := 0.0
var eyes_closed := false
var punch_ext := 0.0

var _timer := 0.0
var _punch_buffer := 0.0
var _hit: HitData
var _barrage_left := 0
var _barrage_t := 0.0
var _cine_marker: Node2D
var _letterbox: AlphaFx.Letterbox


func _ready() -> void:
	ad = data as AlphaArchitectData
	if ad == null:
		ad = AlphaArchitectData.new()
		data = ad
	move_ids = ["clap", "touch", "vadis", "portal", "decay", "rod", "opening"]
	move_names = GROUND_NAMES.duplicate()
	super._ready()


func draw_model_on(c: CanvasItem) -> void:
	AlphaArchitectArt.draw(c, self)


func is_air_charging() -> bool:
	return state == State.AIR_CHARGE


# ===== HOOKS =====
func _is_free() -> bool:
	return state == State.FREE


func is_attacking() -> bool:
	return state in [State.PUNCH_STARTUP, State.PUNCH_ACTIVE, State.PUNCH_RECOVERY, State.AIR_CHARGE, State.BARRAGE]


func _movement_locked() -> bool:
	return state == State.CINEMATIC or state == State.BARRAGE


func _owns_velocity_x() -> bool:
	return state == State.AIR_CHARGE or state == State.CINEMATIC


func _super_armor() -> bool:
	return state == State.CINEMATIC or state == State.BARRAGE


func _can_turn() -> bool:
	return state == State.FREE


func _tick_timers(delta: float) -> void:
	super._tick_timers(delta)
	_punch_buffer = maxf(_punch_buffer - delta, 0.0)
	pose_t += delta


# ===== MAIN LOOP: cinematics take over completely =====
func _physics_process(delta: float) -> void:
	if state == State.CINEMATIC and not is_dead:
		_tick_timers(delta)
		_update_visuals(delta)
		return
	super._physics_process(delta)


# ===== FLIGHT (E) =====
func _toggle_flight() -> void:
	if state != State.FREE and state != State.CAST:
		return
	flying = not flying
	move_names = (AIR_NAMES if flying else GROUND_NAMES).duplicate()
	if flying:
		velocity.y = -260.0
		Effects.popup(self, global_position + Vector2(0, -170), "FLIGHT ON", Color(0.5, 1.0, 0.6), 22)
		SoundManager.play_sfx("whoosh", -4.0)
	else:
		Effects.popup(self, global_position + Vector2(0, -170), "FLIGHT OFF", Color(0.8, 0.8, 0.8), 20)


func _floor_y() -> float:
	var g := get_tree().get_first_node_in_group("arena_ground") as ArenaGround
	return g.global_position.y if g != null else spawn_position.y


func _handle_movement(delta: float) -> void:
	if not flying:
		super._handle_movement(delta)
		return
	var stunned := stun_timer > 0.0
	var locked := _movement_locked()
	var ax := 0.0 if stunned or locked else ctl.axis()
	var ay := 0.0
	if not stunned and not locked:
		if ctl.pressed("jump"):
			ay = -1.0
		elif ctl.pressed("crouch"):
			ay = 1.0
	is_crouching = false
	if not _owns_velocity_x():
		velocity.x = move_toward(velocity.x, ax * ad.flight_speed * speed_mult(), 3200.0 * delta)
	velocity.y = move_toward(velocity.y, ay * ad.flight_vertical_speed, 2800.0 * delta)
	var top := _floor_y() - ad.flight_max_height
	if global_position.y < top and velocity.y < 0.0:
		velocity.y = 0.0
	if ax != 0.0 and _can_turn():
		facing = 1 if ax > 0.0 else -1


# ===== INPUT =====
func _handle_actions() -> void:
	if stun_timer > 0.0:
		return
	if ctl.just_pressed("fly"):
		_toggle_flight()
	if ctl.just_pressed("attack"):
		if state == State.FREE:
			_try_punch()
		elif state == State.PUNCH_ACTIVE or state == State.PUNCH_RECOVERY:
			_punch_buffer = 0.2
	if state == State.FREE and _punch_buffer > 0.0:
		_punch_buffer = 0.0
		_try_punch()
	for i in move_ids.size():
		if ctl.just_pressed("move%d" % (i + 1)):
			_press_move(move_ids[i])
	if ctl.just_pressed("ultimate") and is_human():
		Effects.popup(self, global_position + Vector2(0, -160), "NO G GAUGE  -  USE 1-7", Color(0.7, 0.9, 0.7), 18)


# ===== PUNCH: always Onslaught (ground) / Air Charge (flight) =====
func _try_punch() -> void:
	is_blocking = false
	_hit = HitData.new()
	_hit.source = self
	_hit.onslaught = true                               # EVERY punch is an Onslaught punch
	_hit.hit_type = "melee"
	_hit.origin = global_position
	if flying:
		_hit.damage = ad.air_charge_damage
		_hit.knockback = Vector2(facing * ad.air_charge_knockback.x, ad.air_charge_knockback.y)
		_hit.move = "air_charge"
		state = State.AIR_CHARGE
		_timer = ad.air_charge_time
		velocity = Vector2(facing * ad.air_charge_speed, 0.0)
		hitbox.activate(_hit, Vector2(facing * 40.0, -70.0), Vector2(110, 110))
		SoundManager.play_sfx("dash")
		Effects.trail(self, Color(0.4, 1.0, 0.55, 0.8), 14.0, 10)
		return
	_hit.damage = data.punch_damage
	_hit.knockback = Vector2(facing * data.punch_knockback.x, data.punch_knockback.y)
	_hit.move = "onslaught_punch"
	state = State.PUNCH_STARTUP
	_timer = data.punch_startup


func _on_hit_landed(victim: Fighter, hit: HitData, result: String) -> void:
	if result == "ignored":
		return
	if hit.hit_type == "melee" and result == "hit":
		Effects.explosion(self, victim.global_position + Vector2(-facing * 20.0, -88.0), 70.0, true)   # Orange Onslaught blast


# ===== STATE MACHINE =====
func _handle_state(delta: float) -> void:
	match state:
		State.PUNCH_STARTUP:
			_timer -= delta
			if _timer <= 0.0:
				state = State.PUNCH_ACTIVE
				_timer = data.punch_active
				_hit.origin = global_position
				hitbox.activate(_hit, Vector2(facing * data.punch_offset.x, data.punch_offset.y), data.punch_size)
				if is_on_floor():
					velocity.x += facing * data.punch_lunge_speed
				SoundManager.play_sfx("punch")
				_flash(Color(1.6, 1.0, 0.4), 0.08)
		State.PUNCH_ACTIVE:
			_timer -= delta
			if _timer <= 0.0:
				hitbox.deactivate()
				state = State.PUNCH_RECOVERY
				_timer = data.punch_recovery
		State.AIR_CHARGE:
			velocity = Vector2(facing * ad.air_charge_speed, 0.0)
			_timer -= delta
			if _timer <= 0.0:
				hitbox.deactivate()
				velocity.x *= 0.25
				state = State.PUNCH_RECOVERY
				_timer = 0.12
		State.PUNCH_RECOVERY, State.CAST:
			_timer -= delta
			if _timer <= 0.0:
				state = State.FREE
				pose = ""
		State.BARRAGE:
			_barrage_t -= delta
			velocity.x = move_toward(velocity.x, 0.0, 2000.0 * delta)
			if _barrage_t <= 0.0 and _barrage_left > 0:
				_barrage_t = 0.09
				_barrage_left -= 1
				_barrage_tick(_barrage_left == 0)
			if _barrage_left <= 0:
				state = State.CAST
				_timer = 0.2


func _interrupt() -> void:
	hitbox.deactivate()
	if state == State.CINEMATIC:
		return                                          # Cinematics can't be interrupted
	state = State.FREE
	pose = ""


func _begin_cast(lock: float, p: String) -> void:
	state = State.CAST
	_timer = lock
	pose = p
	pose_t = 0.0


# ===== POWERS (1-7) =====
func _cast_move(id: String) -> void:
	if flying and id == "touch":
		Effects.popup(self, global_position + Vector2(0, -160), "GODLY TOUCH: NOT IN FLIGHT", Color(1.0, 0.6, 0.5), 20)
		return
	match id:
		"clap":
			_thunderclap()
		"touch":
			_godly_touch()
		"vadis":
			_barrage()
		"portal":
			_portal()
		"decay":
			_decay()
		"rod":
			_world_bomb()
		"opening":
			_world_opening()


func _shot(kind: String, pos: Vector2, vel: Vector2, dmg: int, radius: float, life: float, kb: Vector2, pierce: bool, stun: float = 0.0) -> AlphaShot:
	var s := AlphaShot.new()
	s.source = self
	s.kind = kind
	s.vel = vel
	s.damage = dmg
	s.radius = radius
	s.life = life
	s.knockback = kb
	s.pierce = pierce
	s.stun = stun
	get_parent().add_child(s)
	s.global_position = pos
	return s


## 1. THUNDERCLAP / air: compressed WIND TORNADO
func _thunderclap() -> void:
	_start_cooldown("clap", ad.clap_cooldown)
	_begin_cast(0.32, "clap")
	if flying:
		_shot("tornado", global_position + Vector2(facing * 70.0, -70.0), Vector2(facing * 640.0, 0), ad.tornado_damage, 62.0, 1.3,
			Vector2(620, -380), true, ad.tornado_stun)
		SoundManager.play_sfx("whoosh")
	else:
		_shot("shock", Vector2(global_position.x + facing * 60.0, _floor_y() - 30.0), Vector2(facing * 760.0, 0), ad.clap_damage, 46.0, 0.95,
			Vector2(420, -300), true, ad.clap_stun)
		Effects.shake(self, 8.0)
		SoundManager.play_sfx("block")
		SoundManager.play_sfx("spark")
	Effects.hit_sparks(self, global_position + Vector2(facing * 40.0, -88.0), 12, 1.4)


## 2. GODLY TOUCH: a light touch = 3 random debuffs (ground only)
func _godly_touch() -> void:
	_start_cooldown("touch", ad.touch_cooldown)
	_begin_cast(0.4, "touch")
	var best: Fighter = null
	for n in get_tree().get_nodes_in_group("fighters"):
		var f := n as Fighter
		if f == null or f.is_dead or CombatManager.are_allies(self, f):
			continue
		var dx := (f.global_position.x - global_position.x) * float(facing)
		if dx > -10.0 and dx < 130.0 and absf(f.global_position.y - global_position.y) < 120.0:
			best = f
	SoundManager.play_sfx("holy", -4.0)
	if best == null:
		Effects.popup(self, global_position + Vector2(0, -160), "TOUCHED NOTHING", Color(0.8, 0.8, 0.8), 18)
		return
	var h := HitData.new()
	h.source = self
	h.damage = ad.touch_damage
	h.knockback = Vector2(facing * 120.0, -80.0)
	h.origin = global_position
	h.hit_type = "alpha"
	h.move = "godly_touch"
	if CombatManager.apply_hit(h, best) != "hit":
		return
	var old := best.get_node_or_null("GodlyTouch")
	if old != null:
		old.call("_end")
	var deb := AlphaFx.Debuffs.new()
	deb.name = "GodlyTouch"
	deb.source = self
	deb.victim = best
	deb.data = ad
	best.add_child(deb)
	Effects.gold_burst(self, best.global_position + Vector2(0, -80), 90.0)


## 3. BARRAGE OF VADIS: clones (fists on the ground, lasers in the air)
func _barrage() -> void:
	_start_cooldown("vadis", ad.barrage_cooldown)
	var clones := AlphaFx.Clones.new()
	clones.facing = facing
	clones.lasers = flying
	add_child(clones)
	if flying:
		_begin_cast(0.5, "barrage")
		for k in ad.laser_count:
			var y := -40.0 - float(k % 3) * 40.0 + float(k / 3) * 6.0
			var start := global_position + Vector2(facing * (30.0 - float(k % 3) * 30.0), y)
			_shot("laser", start, Vector2(facing * 1150.0, (float(k % 3) - 1.0) * 60.0), ad.laser_damage, 22.0, 1.0, Vector2(280, -120), false)
		SoundManager.play_sfx("laser")
		return
	state = State.BARRAGE
	pose = "barrage"
	pose_t = 0.0
	_barrage_left = ad.barrage_hits
	_barrage_t = 0.12


func _barrage_tick(last: bool) -> void:
	for n in get_tree().get_nodes_in_group("fighters") + get_tree().get_nodes_in_group("helpers"):
		var f := n as Fighter
		if f == null or f.is_dead or CombatManager.are_allies(self, f):
			continue
		var dx := (f.global_position.x - global_position.x) * float(facing)
		if dx < 0.0 or dx > ad.barrage_range or absf(f.global_position.y - global_position.y) > 140.0:
			continue
		var h := HitData.new()
		h.source = self
		h.damage = ad.barrage_hit_damage
		h.knockback = Vector2(facing * (520.0 if last else 60.0), -320.0 if last else -40.0)
		h.origin = global_position
		h.hit_type = "melee"
		h.onslaught = last
		h.causes_hitstun = true
		h.move = "barrage_of_vadis"
		CombatManager.apply_hit(h, f)
	SoundManager.play_sfx("punch", -6.0)


## 4. PORTAL MANIFESTATION (same on the ground and in the air)
func _portal() -> void:
	_start_cooldown("portal", ad.portal_cooldown)
	_begin_cast(0.35, "portal")
	var p := AlphaFx.Portal.new()
	p.source = self
	p.duration = ad.portal_duration
	p.every = ad.portal_shot_every
	p.damage = ad.portal_shot_damage
	get_parent().add_child(p)
	p.global_position = global_position + Vector2(-facing * 70.0, -190.0)


# ============================================================
# CINEMATICS (5-7)
# ============================================================
func _cine_begin(title: String, zoom: float, focus_off: Vector2 = Vector2(0, -90)) -> void:
	state = State.CINEMATIC
	is_blocking = false
	hitbox.deactivate()
	velocity = Vector2.ZERO
	damage_taken_mult = 0.0                             # Can't be hurt during the cinematic
	CombatManager.time_stop_owner = self                # Everyone else (and their shots) freezes
	CombatManager.time_stop_left = 999.0
	_cine_marker = Node2D.new()
	get_parent().add_child(_cine_marker)
	_cine_marker.global_position = global_position + focus_off
	ArenaCamera.focus = _cine_marker
	ArenaCamera.focus_zoom = zoom
	ArenaCamera.focus_offset = Vector2.ZERO
	_letterbox = AlphaFx.Letterbox.new()
	_letterbox.title = title
	get_tree().current_scene.add_child(_letterbox)
	announce_move(title + "!", Color(0.5, 1.0, 0.6))


func _cine_end() -> void:
	Engine.time_scale = 1.0
	damage_taken_mult = 1.0
	if CombatManager.time_stop_owner == self:
		CombatManager.end_time_stop()
	ArenaCamera.focus = null
	ArenaCamera.focus_offset = Vector2(0, -110)
	if _cine_marker != null and is_instance_valid(_cine_marker):
		_cine_marker.queue_free()
	if _letterbox != null and is_instance_valid(_letterbox):
		_letterbox.close()
	eyes_closed = false
	pose = ""
	state = State.CAST
	_timer = 0.25


func _exit_tree() -> void:
	if state == State.CINEMATIC:                        # Scene changed mid-cinematic: never leave the world frozen
		Engine.time_scale = 1.0
		if CombatManager.time_stop_owner == self:
			CombatManager.end_time_stop()
		ArenaCamera.focus = null


## Real-time wait (ignores slow motion); returns false if we were removed meanwhile.
func _wait(seconds: float) -> bool:
	if not is_inside_tree():
		return false
	await get_tree().create_timer(seconds, true, false, true).timeout
	return is_inside_tree() and not is_dead


func _move_to(pos: Vector2, seconds: float) -> void:
	var tw := create_tween().set_ignore_time_scale(true)
	tw.tween_property(self, "global_position", pos, seconds).set_trans(Tween.TRANS_SINE).set_ease(Tween.EASE_IN_OUT)


func _enemies_in(center: Vector2, rx: float, ry: float) -> Array:
	var out: Array = []
	for n in get_tree().get_nodes_in_group("fighters") + get_tree().get_nodes_in_group("helpers"):
		var f := n as Fighter
		if f == null or f.is_dead or CombatManager.are_allies(self, f):
			continue
		if absf(f.global_position.x - center.x) <= rx and absf(f.global_position.y - center.y) <= ry:
			out.append(f)
	return out


func _big_hit(f: Fighter, dmg: int, kb: Vector2, origin: Vector2, move: String) -> void:
	var h := HitData.new()
	h.source = self
	h.damage = dmg
	var dx := signf(f.global_position.x - origin.x)
	h.knockback = Vector2((dx if dx != 0.0 else float(facing)) * kb.x, kb.y)
	h.origin = origin
	h.blockable = false
	h.hit_type = "alpha"
	h.onslaught = true
	h.move = move
	h.damage_kind = HitData.KIND_EXPLOSION
	CombatManager.apply_hit(h, f)


func _target_x() -> float:
	var e := CombatManager.find_enemy(self)
	return e.global_position.x if e != null else global_position.x + facing * 300.0


## 5. PURE IMPLOSION OF DECAY
func _decay() -> void:
	_start_cooldown("decay", ad.decay_cooldown)
	var start := global_position
	_cine_begin("PURE IMPLOSION OF DECAY", 1.15)
	pose = "decay"
	pose_t = 0.0
	SoundManager.play_sfx("whoosh")
	_move_to(start + Vector2(0, -230), 0.6)              # Flies up
	if not await _wait(0.6):
		return
	var ball := AlphaFx.GasBall.new()
	add_child(ball)
	ball.position = Vector2(4, -170)
	Engine.time_scale = 0.6                             # Slow motion while the gas gathers
	SoundManager.play_sfx("void_goo")
	for i in 12:
		ball.grow = float(i + 1) / 12.0
		_cine_marker.global_position = global_position + Vector2(0, -150)
		if not await _wait(0.1):
			_abort_cinematic()
			return
	Engine.time_scale = 1.0
	pose = "throw"
	var target := Vector2(_target_x(), _floor_y())
	var from := ball.global_position
	remove_child(ball)
	get_parent().add_child(ball)
	ball.global_position = from
	var tw := create_tween().set_ignore_time_scale(true)
	tw.tween_property(ball, "global_position", target + Vector2(0, -30), 0.45).set_trans(Tween.TRANS_QUAD).set_ease(Tween.EASE_IN)
	_cine_marker.global_position = target + Vector2(0, -120)
	ArenaCamera.focus_zoom = 0.8
	SoundManager.play_sfx("whoosh")
	if not await _wait(0.45):
		_abort_cinematic()
		return
	# IMPLOSION: everything is sucked in... then it blows outward
	for f in _enemies_in(target, ad.decay_radius * 1.6, 260.0):
		(f as Fighter).force_move_to(Vector2(target.x + signf((f as Fighter).global_position.x - target.x) * 30.0, (f as Fighter).global_position.y), 0.35)
	ball.queue_free()
	Effects.void_burst(self, target + Vector2(0, -40), ad.decay_radius)
	SoundManager.play_sfx("rumble")
	Engine.time_scale = 0.35
	if not await _wait(0.4):
		_abort_cinematic()
		return
	Engine.time_scale = 1.0
	AlphaFx.flash(self, Color(0.6, 1.0, 0.5, 0.8), 0.6)
	Effects.explosion(self, target + Vector2(0, -50), ad.decay_radius, true, true)
	Effects.shake(self, 26.0)
	SoundManager.play_sfx("explosion")
	for f in _enemies_in(target, ad.decay_radius, 220.0):
		_big_hit(f, ad.decay_damage, Vector2(560, -520), target, "pure_implosion_of_decay")
	var field := AlphaFx.DecayField.new()
	field.source = self
	field.radius = ad.decay_radius * 0.9
	field.life = ad.decay_field_time
	field.tick = ad.decay_tick
	get_parent().add_child(field)
	field.global_position = target
	if not await _wait(0.9):
		_abort_cinematic()
		return
	if not flying:
		_move_to(start, 0.35)                           # Lands back where it started
		await _wait(0.35)
	_cine_end()


## 6. WORLD IMPLOSION BOMB (with the Earth cutscene)
func _world_bomb() -> void:
	_start_cooldown("rod", ad.bomb_cooldown)
	var start := global_position
	_cine_begin("WORLD IMPLOSION BOMB", 1.3)
	pose = "rod"
	pose_t = 0.0
	var rods := AlphaFx.Rods.new()
	add_child(rods)
	rods.position = Vector2(4, -175)
	SoundManager.play_sfx("beam", -2.0)
	Engine.time_scale = 0.7
	for i in 10:                                         # Energy gathers into a rod
		rods.charge = float(i + 1) / 10.0
		if not await _wait(0.09):
			_abort_cinematic()
			return
	rods.count = 2                                       # ...and it duplicates
	Effects.gold_burst(self, global_position + Vector2(0, -175), 80.0)
	SoundManager.play_sfx("holy")
	if not await _wait(0.5):
		_abort_cinematic()
		return
	Engine.time_scale = 1.0
	_move_to(start + Vector2(0, -900), 0.5)              # Flies up out of sight
	ArenaCamera.focus_zoom = 0.7
	SoundManager.play_sfx("whoosh")
	if not await _wait(0.5):
		_abort_cinematic()
		return
	rods.queue_free()
	var cut := AlphaFx.EarthCutscene.new()
	get_tree().current_scene.add_child(cut)
	await cut.finished
	if not is_inside_tree() or is_dead:
		return
	# Back in the arena: the two rods come down out of the sky on the enemy
	global_position = start
	var tx := _target_x()
	_cine_marker.global_position = Vector2(tx, _floor_y() - 140.0)
	ArenaCamera.focus_zoom = 0.75
	for i in 2:
		var x := tx + (float(i) - 0.5) * 140.0
		var rod := _shot("rod", Vector2(x, _floor_y() - 900.0), Vector2(0, 2600.0), 0, 10.0, 0.34, Vector2.ZERO, true)
		rod.team = team
	if not await _wait(0.34):
		_abort_cinematic()
		return
	AlphaFx.flash(self, Color(1, 1, 1, 1), 0.9)
	for i in 2:
		var x := tx + (float(i) - 0.5) * 140.0
		Effects.explosion(self, Vector2(x, _floor_y() - 60.0), ad.bomb_radius, true, true)
		for f in _enemies_in(Vector2(x, _floor_y()), ad.bomb_radius, 360.0):
			_big_hit(f, ad.bomb_damage, Vector2(700, -680), Vector2(x, _floor_y()), "world_implosion_bomb")
	Effects.shake(self, 34.0)
	SoundManager.play_sfx("explosion")
	SoundManager.play_sfx("rumble")
	if not await _wait(1.0):
		_abort_cinematic()
		return
	_cine_end()


## 7. WORLD OPENING
func _world_opening() -> void:
	_start_cooldown("opening", ad.opening_cooldown)
	_cine_begin("WORLD OPENING", 1.7, Vector2(8, -120))  # Close-up on his face
	pose = "opening"
	pose_t = 0.0
	eyes_closed = true
	Engine.time_scale = 0.5
	SoundManager.play_sfx("void_goo", -4.0)
	if not await _wait(1.0):
		_abort_cinematic()
		return
	Engine.time_scale = 1.0
	var bar := AlphaFx.Barrier.new()
	bar.max_radius = ad.opening_radius
	get_parent().add_child(bar)
	bar.global_position = Vector2(global_position.x, _floor_y())
	ArenaCamera.focus_zoom = 0.6                         # Pull back to show the barrier
	_cine_marker.global_position = global_position + Vector2(0, -160)
	SoundManager.play_sfx("holy")
	for i in 12:
		bar.radius = ad.opening_radius * float(i + 1) / 12.0
		if not await _wait(0.04):
			_abort_cinematic()
			return
	# Giant hands come out of the barrier and tear at everything inside it
	for k in ad.opening_hand_hits:
		var victims := _enemies_in(bar.global_position, ad.opening_radius, 500.0)
		var tgt: Vector2 = (victims[0] as Fighter).global_position + Vector2(0, -60) if not victims.is_empty() else bar.global_position + Vector2(randf_range(-300.0, 300.0), -100)
		var ang := PI + randf_range(0.15, PI - 0.15)
		bar.add_hand(Vector2.from_angle(ang) * ad.opening_radius, tgt - bar.global_position)
		if not await _wait(0.2):
			_abort_cinematic()
			bar.queue_free()
			return
		for f in victims:
			if not (f as Fighter).is_dead:
				_big_hit(f, ad.opening_hand_damage, Vector2(160, -140), bar.global_position + Vector2(randf_range(-200.0, 200.0), 0), "world_opening")
		Effects.shake(self, 12.0)
		SoundManager.play_sfx("slam", -4.0)
	# The final tear
	Engine.time_scale = 0.4
	SoundManager.play_sfx("roar")
	for i in 10:
		bar.rip = float(i + 1) / 10.0
		if not await _wait(0.06):
			_abort_cinematic()
			bar.queue_free()
			return
	Engine.time_scale = 1.0
	AlphaFx.flash(self, Color(0.7, 1.0, 0.75, 0.9), 0.7)
	for f in _enemies_in(bar.global_position, ad.opening_radius, 500.0):
		_big_hit(f, ad.opening_final_damage, Vector2(760, -620), bar.global_position, "world_opening")
	Effects.explosion(self, bar.global_position + Vector2(0, -150), 320.0, true, true)
	Effects.shake(self, 30.0)
	SoundManager.play_sfx("explosion")
	eyes_closed = false
	var tw := create_tween().set_ignore_time_scale(true)
	tw.tween_property(bar, "fade", 0.0, 0.6)
	tw.tween_callback(bar.queue_free)
	if not await _wait(0.7):
		_abort_cinematic()
		return
	_cine_end()


func _abort_cinematic() -> void:
	if is_inside_tree() and state == State.CINEMATIC:
		_cine_end()


# ===== DEATH / RESPAWN =====
func _on_death_extra() -> void:
	if state == State.CINEMATIC:
		_cine_end()
	flying = false
	move_names = GROUND_NAMES.duplicate()
	punch_ext = 0.0
	state = State.FREE


func _on_respawn_extra() -> void:
	state = State.FREE
	flying = false
	pose = ""


# ===== VISUALS =====
func _update_visuals(delta: float) -> void:
	anim_time += delta
	if is_on_floor():
		walk_phase += absf(velocity.x) * delta * 0.05
	block_amt = move_toward(block_amt, 1.0 if is_blocking else 0.0, delta * 9.0)
	match state:
		State.PUNCH_STARTUP:
			punch_ext = -0.5
		State.PUNCH_ACTIVE, State.AIR_CHARGE:
			punch_ext = 1.0
		State.PUNCH_RECOVERY:
			punch_ext = clampf(_timer / maxf(data.punch_recovery, 0.01), 0.0, 1.0)
		_:
			punch_ext = 0.0
	var cs := 0.88 if is_crouching else 1.0
	visuals.scale = Vector2(facing * cs, cs)
	visuals.queue_redraw()
