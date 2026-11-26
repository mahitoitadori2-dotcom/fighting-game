class_name Fighter
extends CharacterBody2D
## Shared base for Player, Dummy and every future fighter.
## Owns: body collision, Hurtbox, health, knockback, statuses, death / respawn.
## Origin of this node = the fighter's FEET (center-bottom).

signal health_changed(current: int, maximum: int)
signal died
signal respawned
signal damaged(amount: int, hit: HitData)
@warning_ignore("unused_signal")
signal dealt_damage(amount: int, victim: Fighter)
signal blocked(hit: HitData, perfect: bool)

var data: CharacterData
var gauge: GGauge = null              # Only characters with a G Gauge create one
var hp := 0
var facing := 1                       # 1 = right, -1 = left
var default_facing := 1
var is_dead := false
var is_blocking := false
var is_crouching := false
var spawn_position := Vector2.ZERO
var fall_death_y := 800.0
var knockback_scale := 1.0            # < 1 = knockback resistance
var grab_immune := false              # Giant bosses: grabs still damage them but never move them
var damage_taken_mult := 1.0          # < 1 = damage reduction (Warrior's Royal Destiny)
var outgoing_damage_mult := 1.0       # < 1 = this fighter's hits are weaker (APHA Architect: Godly Touch "Weakened")
var story_power := 1.0                # Hidden Story buff (StoryBuff.gd): damage dealt x this. Never reset.
var story_defense := 1.0              # Hidden Story buff (StoryBuff.gd): damage taken x this. Never reset.
var grab_hold_distance := 70.0
var slot := 0                         # 1 = you, 2 = opponent (set by ArenaManager)
var respawn_enabled := true           # MatchManager turns this off when lives run out
var team := 0                         # Same team = allies (no damage, shared heals). 0 = no team.
var weakness_carry := 0.0             # Fractional bonus damage from weaknesses, carried to the next hit
## ACHIEVEMENTS: what this fighter used in this fight / Story level ("powers", "blocks",
## "gauge", "healing" -> true). Fresh for every fight (a new fighter is spawned each time).
var used := {}

# Last damage source (what killed us decides the death animation)
var last_hit: HitData = null
var last_damage_source := {}          # {attacker, move, part, type, onslaught} for debugging / UI
var last_death_type := ""

# Forced movement (pulled by Clinging Grab, etc.)
var _force_target := Vector2.ZERO
var _force_timer := 0.0

# Status effects
var stun_timer := 0.0
var goo_timer := 0.0
var burn_timer := 0.0                 # > 0 right after fire damage (status icon)
var confuse_timer := 0.0              # > 0 = left / right are REVERSED for a human (Executor's memory fog)
var goo_slow := 1.0
var goo_def_down := 0.0
var grabbed_by: Fighter = null
var grab_progress := 0.0
var block_press_time := -10.0

var hurtbox: Hurtbox
var visuals: Node2D
var _flash_tween: Tween

# ===== SHARED ANIMATION LAYER (2026-11-21: better walk / crouch / jump / attack for everyone) =====
# Fighter -> pixel_group (PixelArt) -> anim_pose (these offsets) -> visuals (the art, untouched by this).
# anim_legs = the art bends its knees: it lifts its feet by anim_drop (FighterArt.gait), so the body
# can sink (crouch, landing, walk bob) while the feet stay on the floor. Other art gets squash instead.
var pixel_group: PixelArt
var anim_pose: Node2D
var anim_legs := false
var anim_drop := 0.0                  # Body lowered by this many units (knees bend)
var anim_crouch := 0.0                # 0..1, smooth
var anim_air := 0.0                   # -1 rising fast .. +1 falling fast (0 on the floor)
var anim_attack := 0.0                # 0 idle, < 0 wind-up, > 0 strike (shared lean / lunge)
var anim_walk := 0.0                  # 0 standing .. 1 walking (stride size: feet settle when you stop)
var _pose_was_floor := true
var _pose_air_t := 0.0
var _pose_fall_vy := 0.0
var _pose_land := 0.0
var _pose_takeoff := 0.0
var _pose_atk_t := -1.0
var _pose_bob_ph := 0.0
var _pose_lean := 0.0
var _pose_lunge := 0.0
var _pose_squash := Vector2.ONE
# MODELS + ATTACK STARTUP (2026-11-24): a soft shadow at the feet, idle breathing, a wind-up that lasts
# the move's REAL startup (heavier moves coil deeper) and a glint right before the hit.
static var _state_names := {}          # script path -> {state int: "NAME"} (from the class's State enum)
var _pose_shadow: Node2D
var _pose_glint: Node2D
var _pose_glint_a := 0.0
var _pose_breath_t := randf() * TAU
var _su_state := -999
var _su_total := 0.0
var _su_known := false
# REACTIONS (2026-11-24): a hit snaps the body away from the blow (harder hits = bigger), hitstun
# staggers, blocking braces (and a blocked hit shoves), turning around squeezes the body for a moment.
var _pose_hit := 0.0
var _pose_hit_dir := 0.0
var _pose_block := 0.0
var _pose_block_kick := 0.0
var _pose_turn := 0.0
var _pose_last_facing := 0


static func now() -> float:
	return Time.get_ticks_msec() / 1000.0


# ===== SETUP =====
func _ready() -> void:
	if data == null:
		data = CharacterData.dummy()
	if spawn_position == Vector2.ZERO:
		spawn_position = global_position
	collision_layer = CombatManager.BODY_LAYER
	collision_mask = CombatManager.WORLD_LAYER
	add_to_group("fighters")

	# Body collision: fixed size from data. Never changes with art.
	var shape := RectangleShape2D.new()
	shape.size = data.body_size
	var col := CollisionShape2D.new()
	col.name = "CollisionShape2D"
	col.shape = shape
	col.position = Vector2(0, -data.body_size.y / 2.0)
	add_child(col)

	hurtbox = Hurtbox.new()
	hurtbox.name = "Hurtbox"
	add_child(hurtbox)
	hurtbox.setup(self, data.body_size)

	_pose_shadow = Node2D.new()                         # Under the model (added before it)
	_pose_shadow.name = "Shadow"
	add_child(_pose_shadow)
	_pose_shadow.draw.connect(_draw_pose_shadow)
	pixel_group = PixelArt.new()
	pixel_group.name = "PixelArt"
	add_child(pixel_group)
	anim_pose = Node2D.new()
	anim_pose.name = "Pose"
	pixel_group.add_child(anim_pose)
	visuals = Node2D.new()
	visuals.name = "Visuals"
	anim_pose.add_child(visuals)
	visuals.draw.connect(_draw_model)
	_pose_glint = Node2D.new()                          # Over the model
	_pose_glint.name = "Glint"
	add_child(_pose_glint)
	_pose_glint.draw.connect(_draw_pose_glint)

	hp = data.max_hp
	health_changed.emit(hp, data.max_hp)


func _draw_model() -> void:
	draw_model_on(visuals)


## SHARED ANIMATION: call once per physics frame AFTER the subclass updated its visuals.
## attacking = mid-attack (ControlledFighter.is_attacking). Never touches `visuals` itself (rolls,
## death tilts and replays own visuals.position / rotation / scale).
func update_pose(delta: float, attacking: bool) -> void:
	if anim_pose == null:
		return
	var on_floor := is_on_floor()
	var vx := velocity.x
	# --- Crouch: smooth, real knee bend (anim_legs art) ---
	anim_crouch = move_toward(anim_crouch, 1.0 if is_crouching and on_floor else 0.0, delta * 9.0)
	# --- Take-off / air / landing ---
	if on_floor:
		if not _pose_was_floor and _pose_air_t > 0.10:
			_pose_land = clampf(_pose_fall_vy / 900.0, 0.35, 1.0)      # Harder fall = deeper landing
		_pose_air_t = 0.0
		anim_air = move_toward(anim_air, 0.0, delta * 8.0)
	else:
		if _pose_was_floor and velocity.y < -60.0:
			_pose_takeoff = 1.0
		_pose_air_t += delta
		_pose_fall_vy = maxf(velocity.y, 0.0)
		anim_air = lerpf(anim_air, clampf(velocity.y / 520.0, -1.0, 1.0), minf(delta * 14.0, 1.0))
	_pose_was_floor = on_floor
	_pose_land = move_toward(_pose_land, 0.0, delta * 6.5)
	_pose_takeoff = move_toward(_pose_takeoff, 0.0, delta * 7.0)
	# --- Attack: the WIND-UP lasts the move's real startup (coil back + dip, deeper for slower moves,
	# a tremble and a glint at the end), then the strike SNAPS forward (lean in, lunge, a smear) ---
	var sp := startup_progress()
	var atk := 0.0
	if sp >= 0.0:
		var depth := 0.7 + 0.6 * clampf(_su_total / 0.30, 0.0, 1.0)
		atk = -(1.0 - (1.0 - sp) * (1.0 - sp)) * depth
		_pose_atk_t = 0.0
	elif attacking:
		_pose_atk_t = 0.0 if _pose_atk_t < 0.0 else _pose_atk_t + delta
		if _su_known:
			atk = clampf(1.25 - _pose_atk_t * 2.8, 0.45, 1.25)
		else:                                       # Art without a known startup: the old quick wind-up
			atk = -1.0 if _pose_atk_t < 0.06 else clampf(1.0 - (_pose_atk_t - 0.06) * 2.5, 0.45, 1.0)
	else:
		_pose_atk_t = -1.0
	anim_attack = lerpf(anim_attack, atk, minf(delta * (40.0 if atk > anim_attack else 18.0), 1.0))
	var glint := clampf((sp - 0.70) / 0.30, 0.0, 1.0) if sp >= 0.0 and _su_total >= 0.10 else 0.0
	if glint > 0.0 or _pose_glint_a > 0.0:
		_pose_glint_a = glint if glint > 0.0 else move_toward(_pose_glint_a, 0.0, delta * 9.0)
		_pose_glint.queue_redraw()
	# --- Walk bob: the body dips as the legs spread (twice per stride) ---
	var walking := on_floor and absf(vx) > 25.0 and anim_crouch < 0.5
	var ph: float = float(get("walk_phase")) if "walk_phase" in self else _pose_bob_ph
	if not ("walk_phase" in self) and on_floor:
		_pose_bob_ph += absf(vx) * delta * 0.045
	var bob := absf(sin(ph)) * 3.2 * clampf(absf(vx) / 260.0, 0.0, 1.0) if walking else 0.0
	anim_walk = move_toward(anim_walk, clampf(absf(vx) / 120.0, 0.0, 1.0) if walking else 0.0, delta * 6.0)
	# --- Combine ---
	var land_curve := sin(_pose_land * PI * 0.5)
	var dip := maxf(-anim_attack, 0.0) * 5.5
	var target_drop := anim_crouch * 18.0 + land_curve * 12.0 + bob + dip
	if not on_floor:
		target_drop = 0.0
	anim_drop = lerpf(anim_drop, target_drop, minf(delta * 30.0, 1.0))
	var fwd := clampf(vx * float(facing) / 320.0, -1.0, 1.0) if on_floor else 0.0
	var lean := 0.055 * fwd + 0.07 * maxf(anim_attack, 0.0) - 0.085 * maxf(-anim_attack, 0.0)
	if not on_floor:
		lean += 0.05 * clampf(vx * float(facing) / 320.0, -1.0, 1.0)
	_pose_lean = lerpf(_pose_lean, lean, minf(delta * 14.0, 1.0))
	_pose_lunge = lerpf(_pose_lunge, 7.0 * maxf(anim_attack, 0.0) - 5.0 * maxf(-anim_attack, 0.0), minf(delta * 20.0, 1.0))
	# Squash & stretch: stretch on take-off and fast vertical moves; no-knee art also squashes on landing
	var stretch := 0.07 * _pose_takeoff + 0.035 * absf(anim_air)
	var squash := 0.0 if anim_legs else 0.10 * land_curve + 0.05 * maxf(-anim_attack, 0.0)
	var smear := 0.07 * maxf(anim_attack - 0.6, 0.0)                 # The strike stretches forward
	var breath := 0.0                                                 # Idle breathing
	if on_floor and not attacking and absf(vx) < 10.0 and anim_crouch < 0.1:
		_pose_breath_t += delta * 2.3
		breath = sin(_pose_breath_t) * 0.012
	var sq := Vector2(1.0 - stretch * 0.6 + squash + smear - breath * 0.5, 1.0 + stretch - squash - smear * 0.5 + breath)
	_pose_squash = _pose_squash.lerp(sq, minf(delta * 20.0, 1.0))
	# --- Reactions: hit recoil, hitstun stagger, block brace + shove, turn-around squeeze ---
	_pose_hit = move_toward(_pose_hit, 0.0, delta * 4.0)
	_pose_block = move_toward(_pose_block, 1.0 if is_blocking and not is_dead else 0.0, delta * 12.0)
	_pose_block_kick = move_toward(_pose_block_kick, 0.0, delta * 5.0)
	if _pose_last_facing != 0 and facing != _pose_last_facing and on_floor:
		_pose_turn = 1.0
	_pose_last_facing = facing
	_pose_turn = move_toward(_pose_turn, 0.0, delta * 7.0)
	var hit_curve := sin(minf(_pose_hit, 1.0) * PI * 0.5)
	var hit_x := _pose_hit_dir * 7.0 * hit_curve - float(facing) * 5.0 * _pose_block_kick
	var hit_rot := _pose_hit_dir * 0.17 * hit_curve - float(facing) * 0.06 * _pose_block_kick
	if stun_timer > 0.0 and not is_dead:
		hit_rot += sin(float(Time.get_ticks_msec()) * 0.028) * 0.035          # Stagger wobble
	var brace := _pose_block * (1.0 - _pose_block_kick * 0.5)
	var tremble := sin(float(Time.get_ticks_msec()) * 0.09) * 0.9 if sp > 0.75 else 0.0
	var drop_y := (anim_drop + brace * 6.0 + hit_curve * 4.0) * absf(visuals.scale.y) if anim_legs else 0.0
	anim_pose.position = Vector2(_pose_lunge * float(facing) + tremble + hit_x, drop_y)
	if _pose_shadow != null:                                               # Shadow: only on the floor
		_pose_shadow.modulate.a = move_toward(_pose_shadow.modulate.a, 0.0 if (not on_floor or is_dead) else 1.0, delta * 8.0)
	anim_pose.rotation = (_pose_lean - 0.06 * brace) * float(facing) + hit_rot
	var react := Vector2(1.0 + 0.09 * hit_curve + 0.05 * brace - 0.22 * _pose_turn, 1.0 - 0.09 * hit_curve - 0.05 * brace + 0.04 * _pose_turn)
	anim_pose.scale = _pose_squash * react


## 0..1 through an attack's STARTUP (the wind-up), -1 when not winding up. Read from the class's
## State enum (any state named *_STARTUP) and its countdown timer (_state_timer / _timer).
func startup_progress() -> float:
	if not ("state" in self):
		return -1.0
	var scr := get_script() as Script
	if scr == null:
		return -1.0
	var key := scr.resource_path
	if not _state_names.has(key):
		var rev := {}
		var s := scr
		while s != null and rev.is_empty():
			var m: Variant = s.get_script_constant_map().get("State")
			if m is Dictionary:
				for k: Variant in (m as Dictionary):
					rev[int((m as Dictionary)[k])] = String(k)
			s = s.get_base_script()
		_state_names[key] = rev
	var names: Dictionary = _state_names[key]
	if names.is_empty():
		return -1.0
	_su_known = true
	var st := int(get("state"))
	var t := float(get("_state_timer")) if "_state_timer" in self else (float(get("_timer")) if "_timer" in self else -1.0)
	if st != _su_state:
		_su_state = st
		_su_total = maxf(t, 0.001)
	if t < 0.0 or not String(names.get(st, "")).ends_with("STARTUP"):
		return -1.0
	return clampf(1.0 - t / _su_total, 0.0, 1.0)


## Soft oval shadow at the feet (drawn once; update_pose fades it in the air).
func _draw_pose_shadow() -> void:
	if data == null:
		return
	var w := data.body_size.x * 0.62 + 10.0
	var pts := PackedVector2Array()
	for i in 20:
		var a := TAU * float(i) / 20.0
		pts.append(Vector2(cos(a) * w, 2.0 + sin(a) * w * 0.16))
	_pose_shadow.draw_colored_polygon(pts, Color(0, 0, 0, 0.28))


## The GLINT at the end of a wind-up: a 4-point star in front of the chest.
func _draw_pose_glint() -> void:
	if _pose_glint_a <= 0.01 or data == null:
		return
	var p := Vector2(data.body_size.x * 0.6 * float(facing), -data.body_size.y * 0.62)
	var r := 6.0 + 10.0 * _pose_glint_a
	var k := r * 0.2
	var col := Color(1.0, 0.98, 0.85, _pose_glint_a)
	_pose_glint.draw_colored_polygon(PackedVector2Array([p + Vector2(0, -r), p + Vector2(k, -k), p + Vector2(r, 0), p + Vector2(k, k),
		p + Vector2(0, r), p + Vector2(-k, k), p + Vector2(-r, 0), p + Vector2(-k, -k)]), col)
	_pose_glint.draw_circle(p, r * 0.28, Color(1, 1, 1, _pose_glint_a))


## Straight back to the neutral anim_pose (respawn, cutscenes).
func reset_pose() -> void:
	anim_drop = 0.0
	anim_crouch = 0.0
	anim_air = 0.0
	anim_attack = 0.0
	anim_walk = 0.0
	_pose_land = 0.0
	_pose_takeoff = 0.0
	_pose_atk_t = -1.0
	_pose_lean = 0.0
	_pose_lunge = 0.0
	_pose_squash = Vector2.ONE
	_pose_hit = 0.0
	_pose_block = 0.0
	_pose_block_kick = 0.0
	_pose_turn = 0.0
	if anim_pose != null:
		anim_pose.position = Vector2.ZERO
		anim_pose.rotation = 0.0
		anim_pose.scale = Vector2.ONE


## Override in subclasses: draw the character onto ANY canvas item.
## Drawn facing RIGHT, origin = feet. Death animations reuse this.
func draw_model_on(_c: CanvasItem) -> void:
	pass


# ===== STATUS =====
func tick_status(delta: float) -> void:
	stun_timer = maxf(stun_timer - delta, 0.0)
	burn_timer = maxf(burn_timer - delta, 0.0)
	confuse_timer = maxf(confuse_timer - delta, 0.0)
	if goo_timer > 0.0:
		goo_timer -= delta
		if goo_timer <= 0.0:
			goo_slow = 1.0
			goo_def_down = 0.0
	queue_redraw()


func speed_mult() -> float:
	return goo_slow if goo_timer > 0.0 else 1.0


func apply_goo(duration: float, slow: float, def_down: float) -> void:
	goo_timer = maxf(goo_timer, duration)
	goo_slow = slow
	goo_def_down = def_down


func can_block_now() -> bool:
	return is_blocking and not is_dead


func time_since_block_press() -> float:
	return now() - block_press_time


# ===== GRAB =====
func begin_grab(by: Fighter) -> void:
	grabbed_by = by
	grab_progress = 0.0
	stun_timer = 0.0
	velocity = Vector2.ZERO


func release_grab() -> void:
	grabbed_by = null
	grab_progress = 0.0
	velocity = Vector2.ZERO          # No knockback when a grab ends


func grab_mash() -> void:
	if grabbed_by == null:
		return
	grab_progress += 1.0
	if grab_progress >= data.grab_escape_presses:
		release_grab()
		Effects.popup(self, global_position + Vector2(0, -150), "ESCAPED!", Color(1, 0.95, 0.3), 26)


## True while an enemy's Time Stop has this fighter frozen.
func is_time_frozen() -> bool:
	return CombatManager.is_frozen(self)


## Slide this fighter to `target` (feet position) over `duration` seconds.
func force_move_to(target: Vector2, duration: float) -> void:
	if grab_immune:
		return
	_force_target = target
	_force_timer = maxf(duration, 0.01)


## Call near the top of _physics_process. Returns true while being moved (skip normal logic).
func forced_update(delta: float) -> bool:
	if _force_timer <= 0.0:
		return false
	velocity = (_force_target - global_position) / maxf(_force_timer, delta)
	_force_timer -= delta
	move_and_slide()
	if _force_timer <= 0.0:
		velocity = Vector2.ZERO
	return true


## Call at the top of _physics_process. Returns true while held (skip normal logic).
func grabbed_update(delta: float) -> bool:
	if grabbed_by == null or grab_immune:
		return false
	if not is_instance_valid(grabbed_by) or grabbed_by.is_dead:
		grabbed_by = null
		return false
	grab_progress = maxf(grab_progress - data.grab_escape_decay * delta, 0.0)
	velocity = Vector2.ZERO
	# Glide into the grab position (no teleport snap)
	var hold := grabbed_by.global_position + Vector2(grabbed_by.facing * grabbed_by.grab_hold_distance, 0.0)
	global_position = global_position.lerp(hold, 1.0 - exp(-22.0 * delta))
	return true


# ===== HEALTH =====
## Called by CombatManager after block / defense maths.
func take_hit(amount: int, hit: HitData) -> void:
	if is_dead:
		return
	if has_meta("console_corrupt"):
		amount = 0                                       # RED CONSOLE #s003: corrupted = IMMORTAL (all damage)
	# Remember WHAT hit us last: DeathManager picks the death animation from it.
	if amount > 0:
		last_hit = hit
		last_damage_source = {
			"attacker": hit.source.data.character_name if hit.source != null and is_instance_valid(hit.source) else "",
			"move": hit.move, "part": hit.part, "type": hit.hit_type, "onslaught": hit.onslaught,
		}
	if hit.hit_type == "fire" and amount > 0:
		burn_timer = 1.5
	hp = maxi(hp - amount, 0)
	if MatchSettings.god_mode_active():
		hp = data.max_hp                     # Sandbox God Mode: HP never drops
	health_changed.emit(hp, data.max_hp)
	damaged.emit(amount, hit)
	if amount > 0:
		var col := Color(1.0, 0.55, 0.1) if hit.onslaught else Color.WHITE
		Effects.popup(self, global_position + Vector2(randf_range(-14.0, 14.0), -140), "-%d" % amount, col, 28 if hit.onslaught else 22)
		_flash(Color(1.0, 0.3, 0.3), 0.15)
		_pose_hit = clampf(float(amount) / 22.0, 0.45, 1.0)          # Recoil: away from the blow
		if hit.knockback.x != 0.0:
			_pose_hit_dir = signf(hit.knockback.x)
		elif hit.source != null and is_instance_valid(hit.source):
			_pose_hit_dir = signf(global_position.x - hit.source.global_position.x)
		else:
			_pose_hit_dir = -float(facing)
	if hit.knockback != Vector2.ZERO:
		apply_knockback(hit.knockback, hit.causes_hitstun)
	if hp <= 0:
		die()


## Restore HP (Lord's Heal). Returns how much was actually healed.
func heal(amount: int) -> int:
	if is_dead or amount <= 0:
		return 0
	var before := hp
	hp = mini(hp + amount, data.max_hp)
	var healed := hp - before
	health_changed.emit(hp, data.max_hp)
	if healed > 0:
		used["healing"] = true                       # Achievements: "no healing" challenges
		SoundManager.play_sfx("heal")
		Effects.popup(self, global_position + Vector2(randf_range(-10.0, 10.0), -150), "+%d HP" % healed, Color(1.0, 0.88, 0.3), 24)
	return healed


## Direct damage (T key, drill miss, etc.). Unblockable, no hitstun.
## Sandbox Damage Multiplier applies here too.
func take_damage(amount: int, knockback: Vector2 = Vector2.ZERO, move: String = "") -> void:
	amount = roundi(amount * MatchSettings.damage_multiplier())
	var h := HitData.new()
	h.move = move
	h.damage = amount
	h.knockback = knockback
	h.blockable = false
	h.causes_hitstun = false
	h.hit_type = "self"
	take_hit(amount, h)


func apply_knockback(kb: Vector2, stun: bool = true) -> void:
	if grabbed_by != null or kb == Vector2.ZERO:
		return
	# Smooth: blend into the new launch instead of snapping (keeps a bit of momentum)
	velocity = velocity.lerp(kb * knockback_scale, 0.85)
	if stun:
		stun_timer = data.hitstun_time


func on_blocked(hit: HitData, perfect: bool) -> void:
	_pose_block_kick = 0.5 if perfect else 1.0                 # The guard gets shoved back
	if perfect:
		Effects.popup(self, global_position + Vector2(0, -150), "PERFECT BLOCK!", Color(0.4, 1.0, 1.0), 28)
	else:
		Effects.popup(self, global_position + Vector2(0, -150), "BLOCKED", Color(0.8, 0.85, 0.9), 22)
	blocked.emit(hit, perfect)


# ===== DEATH / RESPAWN =====
func check_fall_death() -> void:
	if global_position.y > fall_death_y:
		if MatchSettings.god_mode_active() or has_meta("console_corrupt"):
			respawn()                        # God Mode / console #s003: no death, just put us back
			return
		die(DeathManager.FALL)


## death_type "" = decided by DeathManager from the last hit we took.
func die(death_type: String = "") -> void:
	if is_dead:
		return
	if death_type == "":
		death_type = custom_death_type(last_hit)       # Enemies can have their own death (Rotor: dog K.O.)
	if death_type == "":
		death_type = DeathManager.death_type(last_hit)
	last_death_type = death_type
	is_dead = true
	hp = 0
	velocity = Vector2.ZERO
	grabbed_by = null
	stun_timer = 0.0
	for n in get_tree().get_nodes_in_group("fighters"):
		var f := n as Fighter
		if f != null and f.grabbed_by == self:
			f.release_grab()
	_on_death()
	SoundManager.play_sfx("death")
	visuals.visible = false
	hurtbox.set_deferred("monitorable", false)
	DeathManager.play(self, death_type, last_hit)    # Fall over / split / explode / drown / implode
	queue_redraw()
	health_changed.emit(hp, data.max_hp)
	died.emit()                                       # MatchManager removes a life here
	await get_tree().create_timer(data.respawn_delay).timeout
	if respawn_enabled and is_inside_tree():
		respawn()


func respawn() -> void:
	global_position = spawn_position
	velocity = Vector2.ZERO
	hp = data.max_hp
	is_dead = false
	last_hit = null
	last_damage_source = {}
	facing = default_facing
	stun_timer = 0.0
	goo_timer = 0.0
	goo_slow = 1.0
	goo_def_down = 0.0
	confuse_timer = 0.0
	outgoing_damage_mult = 1.0
	grabbed_by = null
	knockback_scale = 1.0
	damage_taken_mult = 1.0
	_force_timer = 0.0
	visuals.visible = true
	# Fade back in (no instant pop) with a soft light burst
	visuals.modulate = Color(1, 1, 1, 0)
	if _flash_tween:
		_flash_tween.kill()
	_flash_tween = create_tween()
	_flash_tween.tween_property(visuals, "modulate", Color.WHITE, 0.3)
	Effects.hit_sparks(self, global_position + Vector2(0, -64), 8, 0.8)
	SoundManager.play_sfx("spawn")
	hurtbox.set_deferred("monitorable", true)
	_on_respawn()
	health_changed.emit(hp, data.max_hp)
	respawned.emit()


func _on_death() -> void:
	pass


## Override to force a death animation for THIS fighter (empty = normal rules).
func custom_death_type(_hit: HitData) -> String:
	return ""


func _on_respawn() -> void:
	pass


# ===== VISUAL HELPERS =====
func _flash(color: Color, duration: float) -> void:
	if _flash_tween:
		_flash_tween.kill()
	visuals.modulate = color
	_flash_tween = create_tween()
	_flash_tween.tween_property(visuals, "modulate", Color.WHITE, duration)


func _status_text() -> String:
	var parts: PackedStringArray = []
	if is_time_frozen():
		parts.append("TIME STOPPED")
	if goo_timer > 0.0:
		parts.append("VOID GOO: SLOWED, DEF -%d%%" % int(goo_def_down * 100.0))
	if grabbed_by != null:
		parts.append("GRABBED! mash (%d/%d)" % [int(grab_progress), data.grab_escape_presses])
	if stun_timer > 0.0:
		parts.append("STUN")
	if confuse_timer > 0.0:
		parts.append("CONFUSED: CONTROLS REVERSED")
	return " | ".join(parts)


## PHOTO MODE "HUD OFF" hides the name tags too.
static var hide_tags := false


## Name tag + status text above the head (not flipped, not part of the art).
func _draw() -> void:
	if is_dead or data == null or hide_tags:
		return
	var top := -data.body_size.y - 20.0
	var tag := data.character_name
	var tag_col := Color.WHITE
	if slot == 1:
		tag = "P1  " + tag
		tag_col = Color(0.55, 1.0, 0.55)
	elif slot == 2:
		tag = ("P2  " if NetLink.role != "" and NetLink.mode == "versus" else "CPU  ") + tag      # ONLINE: P2 is a person
		tag_col = Color(1.0, 0.6, 0.55)
	FighterArt.label(self, Vector2(0, top), tag, 14, tag_col)
	var s := _status_text()
	if s != "":
		FighterArt.label(self, Vector2(0, top - 18.0), s, 13, Color(1.0, 0.9, 0.3))
		
