class_name Dummy
extends Fighter
## Training dummy: 100 HP. Used as the opponent when no opponent character is selected.
## Press O to make it mash buttons (to test escaping grabs).
## TRAINING MODE (F2) picks its behaviour:
##   STAND (never moves) / BLOCK (always) / RANDOM BLOCK / JUMP (hops every ~1.5 s) /
##   FIGHT BACK (a telegraphed jab when you are close - block it, or Perfect Block it on the ring)

const BEHAVIOURS := ["stand", "block", "random block", "jump", "fight back"]

static var behaviour := 0

var _beh_t := 0.0
var _attack_cd := 1.5


func _ready() -> void:
	data = CharacterData.dummy()
	default_facing = -1
	super._ready()
	facing = default_facing


func _physics_process(delta: float) -> void:
	if is_dead:
		return
	if not CombatManager.fight_active:   # Match intro / winner screen
		return
	if is_time_frozen():                 # Enemy Time Stop: frozen in place
		visuals.modulate = Color(0.55, 0.5, 0.7)
		queue_redraw()
		return
	if visuals.modulate == Color(0.55, 0.5, 0.7):
		visuals.modulate = Color.WHITE
	tick_status(delta)
	if grabbed_update(delta):
		if Input.is_action_just_pressed("dummy_mash"):
			grab_mash()
		_update_visuals()
		return
	if forced_update(delta):             # Flung by Clinging Grab
		check_fall_death()
		_update_visuals()
		return
	_behave(delta)
	if not is_on_floor():
		velocity.y = minf(velocity.y + data.gravity * delta, data.max_fall_speed)
	var friction := data.hitstun_ground_friction if is_on_floor() else data.hitstun_air_friction
	velocity.x = move_toward(velocity.x, 0.0, friction * delta)
	move_and_slide()
	check_fall_death()
	_update_visuals()


func _behave(delta: float) -> void:
	var b := String(BEHAVIOURS[behaviour])
	_beh_t -= delta
	is_blocking = false
	match b:
		"block":
			is_blocking = stun_timer <= 0.0
		"random block":
			if _beh_t <= 0.0:
				_beh_t = randf_range(0.5, 1.3)
				set_meta("rb", randf() < 0.5)
			is_blocking = bool(get_meta("rb", false)) and stun_timer <= 0.0
		"jump":
			if _beh_t <= 0.0 and is_on_floor() and stun_timer <= 0.0:
				_beh_t = randf_range(1.2, 1.8)
				velocity.y = -620.0
		"fight back":
			_attack_cd -= delta
			var foe := CombatManager.find_enemy(self)
			if foe != null and _attack_cd <= 0.0 and stun_timer <= 0.0 \
					and absf(foe.global_position.x - global_position.x) < 150.0:
				_attack_cd = 1.6
				facing = 1 if foe.global_position.x > global_position.x else -1
				_jab(foe)


## A telegraphed jab: the ring closes on you, then it hits (blockable, Perfect Block on the ring).
func _jab(target: Fighter) -> void:
	Effects.telegraph(target, 0.45, target.data.perfect_block_window)
	await get_tree().create_timer(0.45).timeout
	if is_dead or not is_instance_valid(target) or target.is_dead or stun_timer > 0.0:
		return
	if absf(target.global_position.x - global_position.x) > 190.0:
		return                               # Stepped out of reach
	var hit := HitData.new()
	hit.source = self
	hit.damage = 4
	hit.knockback = Vector2(float(facing) * 260.0, -120.0)
	hit.origin = global_position + Vector2(float(facing) * 40.0, -64.0)
	hit.hit_type = "melee"
	hit.move = "dummy_jab"
	CombatManager.apply_hit(hit, target)


func _update_visuals() -> void:
	visuals.scale = Vector2(facing, 1.0)
	visuals.queue_redraw()


func draw_model_on(c: CanvasItem) -> void:
	draw_portrait(c, 0.0)
	if is_blocking:                          # Show it is guarding
		c.draw_arc(Vector2(-14, -70), 40.0, PI * 0.6, PI * 1.4, 16, Color(0.6, 0.85, 1.0, 0.9), 5.0)


## Straw-colored training dummy (also used on menu cards).
static func draw_portrait(c: CanvasItem, _t: float) -> void:
	# Body
	c.draw_rect(Rect2(-18, -100, 36, 75), Color.GOLD)
	# Head
	c.draw_circle(Vector2(0, -115), 15, Color.GOLD)
	# Legs
	c.draw_rect(Rect2(-15, -30, 12, 30), Color.DARK_GOLDENROD)
	c.draw_rect(Rect2(3, -30, 12, 30), Color.DARK_GOLDENROD)
