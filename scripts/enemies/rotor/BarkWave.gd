class_name BarkWave
extends Area2D
## Rotor's Bark Wave: visible sound-wave rings rolling forward. Hits each target once.
## POOLED: spawn with OptimizationManager.take(BarkWave); it recycles itself.

var pool_gen := 0
var source: Fighter
var damage := 6
var knockback := Vector2(320, -150)
var dir := 1.0
var speed := 520.0
var lifetime := 0.9

var _age := 0.0
var _done := false
var _started := false
var _hit: Array[Fighter] = []


func _init() -> void:
	collision_layer = 0
	collision_mask = CombatManager.HURTBOX_LAYER
	monitoring = true
	monitorable = false
	z_index = 8
	var shape := RectangleShape2D.new()
	shape.size = Vector2(46, 96)
	var col := CollisionShape2D.new()
	col.shape = shape
	add_child(col)


func _enter_tree() -> void:
	_age = 0.0
	_done = false
	_started = false
	_hit.clear()
	set_physics_process(true)
	set_process(true)


func _physics_process(delta: float) -> void:
	if _done:
		return
	if source != null and is_instance_valid(source) and source.is_time_frozen():
		return
	if not _started:
		_started = true
		Effects.trail(self, Color(1, 1, 1, 0.5), 22.0, 8)
	_age += delta
	if _age >= lifetime or not OptimizationManager.on_screen(global_position, 200.0):
		_recycle()
		return
	global_position.x += dir * speed * delta
	for area in get_overlapping_areas():
		var hb := area as Hurtbox
		if hb == null or hb.fighter.is_dead or _hit.has(hb.fighter):
			continue
		if source != null and is_instance_valid(source) and CombatManager.are_allies(source, hb.fighter):
			continue
		_hit.append(hb.fighter)
		var h := HitData.new()
		h.source = source if is_instance_valid(source) else null
		h.damage = damage
		h.knockback = Vector2(dir * knockback.x, knockback.y)
		h.origin = global_position - Vector2(dir * 60.0, 0)
		h.hit_type = "enemy"
		h.move = "bark_wave"
		CombatManager.apply_hit(h, hb.fighter)


func _recycle() -> void:
	_done = true
	set_physics_process(false)
	set_process(false)
	source = null
	damage = 6
	knockback = Vector2(320, -150)
	dir = 1.0
	speed = 520.0
	lifetime = 0.9
	OptimizationManager.release(self)


func _process(_delta: float) -> void:
	queue_redraw()


func _draw() -> void:
	var a := 1.0 - clampf((_age - lifetime * 0.6) / (lifetime * 0.4), 0.0, 1.0)
	for i in 3:
		var r := 22.0 + float(i) * 14.0 + _age * 30.0
		var off := Vector2(-dir * float(i) * 10.0, 0)
		var a0 := -0.9 if dir > 0.0 else PI - 0.9
		draw_arc(off, r, a0, a0 + 1.8, 18, Color(0, 0, 0, a), 7.0, true)
		draw_arc(off, r, a0, a0 + 1.8, 18, Color(1, 1, 1, a), 4.0, true)
		draw_arc(off, r - 3.0, a0 + 0.2, a0 + 1.6, 14, Color(0.6, 0.85, 1.0, a * 0.7), 2.0, true)
