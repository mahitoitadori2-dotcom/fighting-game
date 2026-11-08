class_name HelperMinion
extends Fighter
## Helpers!: a small white cocooned creature with a blade. Runs at the nearest
## enemy and slashes all around it (5 dmg per slash). Lasts 10 s or until it
## takes 20 damage. On its owner's team (never hurts allies).
## Not in the "fighters" group: cameras, HUD and CPU targeting ignore it,
## but enemy attacks can still hit its hurtbox.

var summoner: Fighter
var lifetime := 10.0
var speed := 250.0
var max_health := 20
var slash_damage := 5
var slash_range := 62.0
var slash_interval := 0.7
var slash_knockback := Vector2(110, -80)

var _age := 0.0
var _slash_cd := 0.4
var slash_t := 0.0               # > 0 while the slash animation plays


func _ready() -> void:
	var d := CharacterData.new()
	d.character_name = "Helper"
	d.max_hp = max_health
	d.body_size = Vector2(30, 44)
	d.hitstun_time = 0.15
	data = d
	super._ready()
	remove_from_group("fighters")
	add_to_group("helpers")
	z_index = -1                          # Helpers draw BEHIND the fighters
	speed *= randf_range(0.9, 1.1)        # Slightly different pace: they never move in lockstep
	if summoner != null:
		team = summoner.team
		facing = summoner.facing


func draw_model_on(c: CanvasItem) -> void:
	EnlightenedOneArt.draw_helper(c, _age, slash_t)


func _physics_process(delta: float) -> void:
	if is_dead or not CombatManager.fight_active:
		return
	if is_time_frozen():
		return
	tick_status(delta)
	_age += delta
	slash_t = maxf(slash_t - delta, 0.0)
	_slash_cd = maxf(_slash_cd - delta, 0.0)
	if _age >= lifetime or summoner == null or not is_instance_valid(summoner) or summoner.is_dead:
		die()
		return

	if not is_on_floor():
		velocity.y = minf(velocity.y + data.gravity * delta, data.max_fall_speed)

	var target := CombatManager.find_enemy(summoner)
	var goal := 0.0
	if target != null and stun_timer <= 0.0:
		var dx := target.global_position.x - global_position.x
		facing = 1 if dx >= 0.0 else -1
		if absf(dx) > slash_range * 0.75:
			goal = facing * speed * speed_mult()
			if not _ground_ahead():
				goal = 0.0                        # Don't run off the island
		elif _slash_cd <= 0.0:
			_slash()
	# Keep a little personal space from other helpers (no perfect stacking)
	for n in get_tree().get_nodes_in_group("helpers"):
		var o := n as Node2D
		if o != self and o != null and absf(o.global_position.x - global_position.x) < 26.0:
			goal += (60.0 if global_position.x >= o.global_position.x else -60.0)
	var rate := data.hitstun_ground_friction if stun_timer > 0.0 else 2400.0
	velocity.x = move_toward(velocity.x, goal, rate * delta)
	move_and_slide()
	check_fall_death()
	visuals.scale = Vector2(facing, 1.0)
	visuals.queue_redraw()
	queue_redraw()


func _ground_ahead() -> bool:
	var x := global_position.x + facing * 30.0
	var q := PhysicsRayQueryParameters2D.create(Vector2(x, global_position.y - 10.0), Vector2(x, global_position.y + 60.0), CombatManager.WORLD_LAYER)
	return not get_world_2d().direct_space_state.intersect_ray(q).is_empty()


## Spin-slash: hits every enemy fighter around it.
func _slash() -> void:
	_slash_cd = slash_interval
	slash_t = 0.25
	var center := global_position + Vector2(0, -22)
	for n in get_tree().get_nodes_in_group("fighters"):
		var f := n as Fighter
		if f == null or f.is_dead or CombatManager.are_allies(self, f):
			continue
		if (f.global_position + Vector2(0, -50)).distance_to(center) > slash_range + 34.0:
			continue
		var dx := signf(f.global_position.x - global_position.x)
		if dx == 0.0:
			dx = float(facing)
		var h := HitData.new()
		h.source = summoner                     # Credit (gauge, K.O.) goes to the Enlightened One
		h.damage = slash_damage
		h.knockback = Vector2(dx * slash_knockback.x, slash_knockback.y)
		h.origin = global_position
		h.hit_type = "slash"
		h.move = "helpers"
		CombatManager.apply_hit(h, f)


## Helpers don't respawn: they burst into light and vanish.
func die(_death_type: String = "") -> void:
	if is_dead:
		return
	is_dead = true
	Effects.gold_burst(self, global_position + Vector2(0, -22), 30.0)
	queue_free()


func _draw() -> void:
	if is_dead:
		return
	# Tiny HP bar instead of a name tag
	var w := 30.0
	var k := clampf(float(hp) / float(max_health), 0.0, 1.0)
	draw_rect(Rect2(-w * 0.5, -58, w, 5), Color(0, 0, 0))
	draw_rect(Rect2(-w * 0.5 + 1, -57, (w - 2) * k, 3), Color(1.0, 0.85, 0.3))
