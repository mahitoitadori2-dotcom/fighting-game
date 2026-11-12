class_name LightBolt
extends Area2D
## Beam Blast: a thin, fast golden light beam. Hits the first enemy it touches.
## POOLED: spawn with OptimizationManager.take(LightBolt); it recycles itself.

const GOLD := Color(1.0, 0.82, 0.25)
const GOLD_GLOW := Color(1.0, 0.9, 0.5)

var pool_gen := 0
var source: Fighter
var damage := 5
var knockback := Vector2(120, -60)
var speed := 1300.0
var dir := Vector2.RIGHT
var lifetime := 0.55
var move := "beam_blast"

var _age := 0.0
var _done := false
var _started := false


func _init() -> void:
	collision_layer = 0
	collision_mask = CombatManager.HURTBOX_LAYER | CombatManager.WORLD_LAYER
	monitoring = true
	monitorable = false
	z_index = 8
	var shape := RectangleShape2D.new()
	shape.size = Vector2(60, 8)
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
	rotation = dir.angle()
	Effects.trail(self, Color(1.0, 0.9, 0.5), 6.0, 8)


func _physics_process(delta: float) -> void:
	if _done:
		return
	if source != null and is_instance_valid(source) and source.is_time_frozen():
		return
	if not _started:
		_start()
	_age += delta
	if _age >= lifetime:
		_recycle()
		return
	global_position += dir * speed * delta
	for area in get_overlapping_areas():
		var hb := area as Hurtbox
		if hb == null or hb.fighter.is_dead or (source != null and CombatManager.are_allies(source, hb.fighter)):
			continue
		var h := HitData.new()
		h.source = source
		h.damage = damage
		h.knockback = Vector2(signf(dir.x) * knockback.x, knockback.y)
		h.origin = global_position - dir * 60.0
		h.hit_type = "light"
		h.move = move
		CombatManager.apply_hit(h, hb.fighter)
		_vanish()
		return
	if _age > 0.05 and get_overlapping_bodies().size() > 0:
		_vanish()


func _vanish() -> void:
	Effects.gold_burst(self, global_position, 18.0)
	_recycle()


func _recycle() -> void:
	if _done:
		return
	_done = true
	set_physics_process(false)
	set_process(false)
	source = null
	damage = 5
	knockback = Vector2(120, -60)
	speed = 1300.0
	dir = Vector2.RIGHT
	lifetime = 0.55
	move = "beam_blast"
	rotation = 0.0
	OptimizationManager.release(self)


func _process(_delta: float) -> void:
	if OptimizationManager.on_screen(global_position, 60.0):
		queue_redraw()


func _draw() -> void:
	draw_line(Vector2(-34, 0), Vector2(30, 0), Color(GOLD_GLOW.r, GOLD_GLOW.g, GOLD_GLOW.b, 0.35), 12.0, FighterArt.AA)
	draw_line(Vector2(-34, 0), Vector2(30, 0), Color(0, 0, 0), 6.0, FighterArt.AA)
	FighterArt.beam_gradient(self, Vector2(-32, 0), 60.0, 2.5, GOLD, Color.WHITE)
