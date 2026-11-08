class_name BaseEnemy
extends Fighter
## BASE FOR EVERY PvE ENEMY / BOSS. Extends Fighter, so enemies automatically get:
## HP, hurtbox, knockback, statuses, Time Stop, grabs, lives, deaths, hit effects,
## and every attack / CPU in the game can target them.
##
## Adds: name, speed, damage, a list of EnemyPatterns, an EnemyAI brain, an attack
## Hitbox, a floating EnemyHUD, and the state machine:
##     IDLE -> TELEGRAPH -> ATTACK -> RECOVER -> MOVE -> IDLE
## Big patterns telegraph (flash + "!" + pattern name) so the player can dodge.
## Phase 2 ("ENRAGED") starts below phase2_threshold HP: faster + shorter cooldowns.
##
## HOW TO MAKE A NEW ENEMY:
##   class_name MyBoss extends BaseEnemy
##   override _make_data(), build_patterns(), _make_brain(), draw_model_on(c)
##   and the pattern hooks _on_telegraph / _on_attack_start / _on_attack_update / _on_attack_end.
##   Then add a roster entry with "enemy": true.

enum EState { IDLE, MOVE, TELEGRAPH, ATTACK, RECOVER }

var enemy_name := "Enemy"
var speed := 300.0
var base_damage := 5
var patterns: Array[EnemyPattern] = []
var brain: EnemyAI
var hitbox: Hitbox
var hud: EnemyHUD

var estate: EState = EState.IDLE
var current: EnemyPattern = null
var state_time := 0.0
var state_len := 0.0
var move_dir := 0.0

var phase := 1
var enraged := false
var phase2_threshold := 0.5
var phase2_speed_mult := 1.3
var phase2_cooldown_mult := 0.8          # Cooldowns 20% faster
var cooldown_mult := 1.0
var phase_speed_mult := 1.0

var anim_time := 0.0
var walk_phase := 0.0


# ============================================================
# SETUP
# ============================================================
func _ready() -> void:
	data = _make_data()
	enemy_name = data.character_name
	speed = data.move_speed
	patterns = build_patterns()
	super._ready()
	hitbox = Hitbox.new()
	hitbox.name = "Hitbox"
	add_child(hitbox)
	hitbox.setup(self)
	hitbox.hit_landed.connect(_on_hit_landed)
	brain = _make_brain()
	hud = EnemyHUD.new()
	hud.enemy = self
	add_child(hud)


# ----- Override in each enemy -----
func _make_data() -> CharacterData:
	return CharacterData.new()

func build_patterns() -> Array[EnemyPattern]:
	return []

func _make_brain() -> EnemyAI:
	return EnemyAI.new()

func _on_telegraph(_p: EnemyPattern) -> void: pass
func _on_attack_start(_p: EnemyPattern) -> void: pass
func _on_attack_update(_p: EnemyPattern, _delta: float) -> void: pass
func _on_attack_end(_p: EnemyPattern) -> void: pass
func _on_phase_changed(_new_phase: int) -> void: pass
func _on_hit_landed(_victim: Fighter, _hit: HitData, _result: String) -> void: pass
func _owns_velocity_x() -> bool: return false


# ============================================================
# PATTERNS
# ============================================================
func pattern(id: String) -> EnemyPattern:
	for p in patterns:
		if p.id == id:
			return p
	return null


func can_act() -> bool:
	return (estate == EState.IDLE or estate == EState.MOVE) and stun_timer <= 0.0 and not is_dead


func start_pattern(p: EnemyPattern) -> void:
	if p == null or not can_act() or not p.is_ready():
		return
	current = p
	estate = EState.TELEGRAPH
	state_time = 0.0
	state_len = p.telegraph_time
	move_dir = 0.0
	_on_telegraph(p)


func is_telegraphing() -> bool:
	return estate == EState.TELEGRAPH and current != null


## Text for the HUD while a big pattern winds up ("SPIN DASH!").
func telegraph_text() -> String:
	if is_telegraphing() and current.big:
		return current.display_name
	return ""


func _cancel_pattern() -> void:
	hitbox.deactivate()
	if current != null:
		_on_attack_end(current)
		current.cooldown_left = current.cooldown * cooldown_mult * 0.5
	current = null
	estate = EState.IDLE


# ============================================================
# HIT HELPERS (patterns use these)
# ============================================================
func make_hit(dmg: int, kb: Vector2, move: String, kind: String = "") -> HitData:
	var h := HitData.new()
	h.source = self
	h.damage = dmg
	h.knockback = kb
	h.origin = global_position
	h.hit_type = "enemy"
	h.move = move
	h.damage_kind = kind
	return h


## Hit every enemy fighter whose body centre is within `radius` of `center`.
func hit_in_radius(center: Vector2, radius: float, dmg: int, kb: Vector2, move: String, kind: String = "") -> int:
	var count := 0
	for n in get_tree().get_nodes_in_group("fighters") + get_tree().get_nodes_in_group("helpers"):
		var f := n as Fighter
		if f == null or f.is_dead or CombatManager.are_allies(self, f):
			continue
		var fc := f.global_position + Vector2(0, -f.data.body_size.y * 0.5)
		if fc.distance_to(center) > radius + f.data.body_size.x * 0.5:
			continue
		var dx := signf(f.global_position.x - center.x)
		if dx == 0.0:
			dx = float(facing)
		var h := make_hit(dmg, Vector2(dx * kb.x, kb.y), move, kind)
		h.origin = center
		CombatManager.apply_hit(h, f)
		count += 1
	return count


func ground_ahead(dist_px: float = 40.0) -> bool:
	var x := global_position.x + facing * dist_px
	var q := PhysicsRayQueryParameters2D.create(Vector2(x, global_position.y - 10.0), Vector2(x, global_position.y + 80.0), CombatManager.WORLD_LAYER)
	return not get_world_2d().direct_space_state.intersect_ray(q).is_empty()


# ============================================================
# MAIN LOOP
# ============================================================
func _physics_process(delta: float) -> void:
	if is_dead or not CombatManager.fight_active:
		return
	if is_time_frozen():
		visuals.modulate = Color(0.55, 0.5, 0.7)
		return
	if visuals.modulate == Color(0.55, 0.5, 0.7):
		visuals.modulate = Color.WHITE
	tick_status(delta)
	anim_time += delta
	for p in patterns:
		p.cooldown_left = maxf(p.cooldown_left - delta, 0.0)
	if grabbed_update(delta):
		if current != null:
			_cancel_pattern()
		_update_visuals(delta)
		return
	if forced_update(delta):
		check_fall_death()
		_update_visuals(delta)
		return
	_check_phase()
	if stun_timer > 0.0 and current != null and not current.armored \
			and (estate == EState.TELEGRAPH or estate == EState.ATTACK):
		_cancel_pattern()                       # Hit out of it
	if stun_timer <= 0.0:
		brain.update(self, delta)
	_run_state(delta)
	_movement(delta)
	move_and_slide()
	check_fall_death()
	_update_visuals(delta)


func _run_state(delta: float) -> void:
	match estate:
		EState.TELEGRAPH:
			state_time += delta
			if state_time >= state_len:
				estate = EState.ATTACK
				state_time = 0.0
				state_len = current.active_time
				_on_attack_start(current)
		EState.ATTACK:
			state_time += delta
			_on_attack_update(current, delta)
			if state_time >= state_len:
				hitbox.deactivate()
				_on_attack_end(current)
				current.cooldown_left = current.cooldown * cooldown_mult
				estate = EState.RECOVER
				state_time = 0.0
				state_len = current.recover_time
		EState.RECOVER:
			state_time += delta
			if state_time >= state_len:
				estate = EState.IDLE
				current = null
		_:
			estate = EState.MOVE if move_dir != 0.0 else EState.IDLE


func _movement(delta: float) -> void:
	var on_floor := is_on_floor()
	if not on_floor:
		velocity.y = minf(velocity.y + data.gravity * delta, data.max_fall_speed)
	if _owns_velocity_x():
		return
	var busy := estate == EState.TELEGRAPH or estate == EState.ATTACK or estate == EState.RECOVER
	var goal := 0.0
	if not busy and stun_timer <= 0.0:
		goal = move_dir * speed * phase_speed_mult * speed_mult()
		if move_dir != 0.0:
			facing = 1 if move_dir > 0.0 else -1
	var rate := data.acceleration if goal != 0.0 else data.deceleration
	if stun_timer > 0.0:
		rate = data.hitstun_ground_friction if on_floor else data.hitstun_air_friction
	velocity.x = move_toward(velocity.x, goal, rate * delta)


func jump(force_mult: float = 1.0) -> void:
	if is_on_floor() and can_act():
		velocity.y = -data.jump_force * force_mult


func _check_phase() -> void:
	if not enraged and hp <= data.max_hp * phase2_threshold:
		enraged = true
		phase = 2
		cooldown_mult = phase2_cooldown_mult
		phase_speed_mult = phase2_speed_mult
		Effects.popup(self, global_position + Vector2(0, -data.body_size.y - 70.0), "ENRAGED!", Color(1.0, 0.3, 0.25), 28)
		Effects.shake(self, 8.0)
		_on_phase_changed(2)


func _update_visuals(delta: float) -> void:
	if is_on_floor():
		walk_phase += absf(velocity.x) * delta * 0.06
	# Telegraph flash on big attacks
	if is_telegraphing() and current.big:
		var pulse := 0.5 + 0.5 * sin(anim_time * 30.0)
		visuals.modulate = Color.WHITE.lerp(Color(2.0, 2.0, 1.5), pulse)
	elif visuals.modulate.r > 1.01 and (_flash_tween == null or not _flash_tween.is_running()):
		visuals.modulate = Color.WHITE
	visuals.scale = Vector2(facing, 1.0)                 # Always uniform: never squashed
	if OptimizationManager.on_screen(global_position, 220.0):
		visuals.queue_redraw()                           # Culling: no redraw while off-screen


# ============================================================
# DEATH / RESPAWN
# ============================================================
func _on_death() -> void:
	_cancel_pattern()
	move_dir = 0.0


func _on_respawn() -> void:
	enraged = false
	phase = 1
	cooldown_mult = 1.0
	phase_speed_mult = 1.0
	estate = EState.IDLE
	current = null
	for p in patterns:
		p.cooldown_left = 0.0


## Enemies show their name in the EnemyHUD instead of the fighter name tag.
func _draw() -> void:
	pass
