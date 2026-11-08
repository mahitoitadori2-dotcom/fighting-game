class_name Dummy
extends Fighter
## Training dummy: 100 HP, never moves or fights back. Only knockback moves it.
## Used as the opponent when no opponent character is selected.
## Press O to make it mash buttons (to test escaping grabs).

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

	if not is_on_floor():
		velocity.y = minf(velocity.y + data.gravity * delta, data.max_fall_speed)
	var friction := data.hitstun_ground_friction if is_on_floor() else data.hitstun_air_friction
	velocity.x = move_toward(velocity.x, 0.0, friction * delta)
	move_and_slide()
	check_fall_death()
	_update_visuals()


func _update_visuals() -> void:
	visuals.scale = Vector2(facing, 1.0)
	visuals.queue_redraw()


func draw_model_on(c: CanvasItem) -> void:
	draw_portrait(c, 0.0)


## Straw-colored training dummy (also used on menu cards).
static func draw_portrait(c: CanvasItem, _t: float) -> void:
	# Body
	c.draw_rect(Rect2(-18, -100, 36, 75), Color.GOLD)
	# Head
	c.draw_circle(Vector2(0, -115), 15, Color.GOLD)
	# Legs
	c.draw_rect(Rect2(-15, -30, 12, 30), Color.DARK_GOLDENROD)
	c.draw_rect(Rect2(3, -30, 12, 30), Color.DARK_GOLDENROD)
