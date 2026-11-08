class_name ShadowSpike
extends Area2D
## Warrior's Mini Eternal Grasp spike. Flies out, then HOMES IN on the nearest enemy.
## Freezes during an enemy Time Stop, like every other projectile.
## POOLED: spawn with OptimizationManager.take(ShadowSpike); it recycles itself.

var pool_gen := 0
var source: Fighter
var target: Fighter
var damage := 3
var knockback := Vector2(140, -90)
var speed := 520.0
var turn_rate := 7.0
var lifetime := 2.2
var dir := Vector2.UP

var _age := 0.0
var _done := false
var _started := false


func _init() -> void:
	collision_layer = 0
	collision_mask = CombatManager.HURTBOX_LAYER | CombatManager.WORLD_LAYER
	monitoring = true
	monitorable = false
	z_index = 8
	var shape := CircleShape2D.new()
	shape.radius = 10.0
	var col := CollisionShape2D.new()
	col.shape = shape
	add_child(col)


func _enter_tree() -> void:
	_age = 0.0
	_done = false
	_started = false
	set_physics_process(true)
	set_process(true)


func _start() -> void:
	_started = true
	target = CombatManager.find_enemy(source)
	rotation = dir.angle()
	Effects.trail(self, Color(0.45, 0.2, 0.7), 7.0, 10)


func _physics_process(delta: float) -> void:
	if _done:
		return
	if source != null and is_instance_valid(source) and source.is_time_frozen():
		return
	if not _started:
		_start()
	_age += delta
	if _age >= lifetime:
		_vanish()
		return
	if not is_instance_valid(target) or target.is_dead:
		target = CombatManager.find_enemy(source)
	if is_instance_valid(target) and not target.is_dead and _age > 0.15:
		var to_t := target.global_position + Vector2(0, -64) - global_position
		var diff := wrapf(to_t.angle() - dir.angle(), -PI, PI)
		dir = dir.rotated(clampf(diff, -turn_rate * delta, turn_rate * delta))
	global_position += dir * speed * delta
	rotation = dir.angle()

	for area in get_overlapping_areas():
		var hb := area as Hurtbox
		if hb != null and hb.fighter != source and not hb.fighter.is_dead:
			var h := HitData.new()
			h.source = source
			h.damage = damage
			var dx := signf(dir.x)
			if dx == 0.0:
				dx = 1.0
			h.knockback = Vector2(dx * knockback.x, knockback.y)
			h.origin = global_position - dir * 40.0
			h.hit_type = "projectile"
			h.move = "mini_eternal"
			CombatManager.apply_hit(h, hb.fighter)
			_vanish()
			return
	if _age > 0.25 and get_overlapping_bodies().size() > 0:
		_vanish()


func _vanish() -> void:
	if _done:
		return
	Effects.void_burst(self, global_position, 26.0)
	_done = true
	set_physics_process(false)
	set_process(false)
	source = null
	target = null
	damage = 3
	knockback = Vector2(140, -90)
	speed = 520.0
	turn_rate = 7.0
	lifetime = 2.2
	dir = Vector2.UP
	OptimizationManager.release(self)


func _process(_delta: float) -> void:
	if OptimizationManager.on_screen(global_position, 60.0):
		queue_redraw()


func _draw() -> void:
	# Black spike with a purple rim, pointing along +X
	draw_circle(Vector2(-6, 0), 10.0, Color(0.55, 0.25, 0.85, 0.25))
	FighterArt.curved_spike(self, Vector2(-10, 0), Vector2(18, 0), 7.0, Color(0.30, 0.12, 0.45), Color(0.03, 0.01, 0.06), 0.2, 2.5)
