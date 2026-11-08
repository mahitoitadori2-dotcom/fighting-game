class_name FetchBall
extends Node2D
## Rotor's Fetch Bomb: a red ball with a lit fuse. Thrown in an arc, bounces on the
## floor, explodes 1 s after the throw (EXPLOSION damage type).
## POOLED: spawn with OptimizationManager.take(FetchBall); it recycles itself.

var pool_gen := 0
var source: Fighter
var damage := 12
var velocity := Vector2(420, -520)
var fuse := 1.0
var radius := 95.0
var knockback := Vector2(420, -360)

const GRAVITY := 1500.0
const BALL_R := 11.0

var _age := 0.0
var _done := false
var _started := false


func _init() -> void:
	z_index = 8


func _enter_tree() -> void:
	_age = 0.0
	_done = false
	_started = false
	set_physics_process(true)
	set_process(true)


func _physics_process(delta: float) -> void:
	if _done:
		return
	if source != null and is_instance_valid(source) and source.is_time_frozen():
		return
	if not _started:
		_started = true
		Effects.trail(self, Color(0.9, 0.15, 0.15, 0.7), 10.0, 10)
	_age += delta
	if _age >= fuse:
		_explode()
		return
	velocity.y += GRAVITY * delta
	var next := global_position + velocity * delta
	var floor_pos: Variant = Effects.ground_below(self, Vector2(next.x, global_position.y - 4.0), 60.0)
	if floor_pos != null and next.y + BALL_R >= floor_pos.y and velocity.y > 0.0:
		next.y = floor_pos.y - BALL_R                 # Bounce
		velocity.y = -absf(velocity.y) * 0.55
		velocity.x *= 0.8
	global_position = next


func _explode() -> void:
	_done = true
	Effects.explosion(self, global_position, radius, false, true)
	Effects.shake(self, 8.0)
	for n in get_tree().get_nodes_in_group("fighters") + get_tree().get_nodes_in_group("helpers"):
		var f := n as Fighter
		if f == null or f.is_dead:
			continue
		if source != null and is_instance_valid(source) and CombatManager.are_allies(source, f):
			continue
		var fc := f.global_position + Vector2(0, -f.data.body_size.y * 0.5)
		if fc.distance_to(global_position) > radius + 30.0:
			continue
		var dx := signf(f.global_position.x - global_position.x)
		if dx == 0.0:
			dx = 1.0
		var h := HitData.new()
		h.source = source if is_instance_valid(source) else null
		h.damage = damage
		h.knockback = Vector2(dx * knockback.x, knockback.y)
		h.origin = global_position
		h.hit_type = "enemy"
		h.move = "fetch_bomb"
		h.damage_kind = HitData.KIND_EXPLOSION
		CombatManager.apply_hit(h, f)
	set_physics_process(false)
	set_process(false)
	source = null
	damage = 12
	velocity = Vector2(420, -520)
	fuse = 1.0
	radius = 95.0
	knockback = Vector2(420, -360)
	OptimizationManager.release(self)


func _process(_delta: float) -> void:
	queue_redraw()


func _draw() -> void:
	var blink := fmod(_age * (6.0 + 20.0 * _age), 1.0) < 0.5
	FighterArt.ball(self, Vector2.ZERO, BALL_R, Color(0.95, 0.15, 0.15), Color(0.6, 0.05, 0.08), Color(1, 0.6, 0.6))
	draw_arc(Vector2.ZERO, BALL_R * 0.7, 0.4, 2.6, 10, Color(1, 1, 1, 0.8), 2.0)        # Ball seam
	var top := Vector2(3, -BALL_R)
	var tip := top + Vector2(5, -8)
	draw_line(top, tip, Color(0, 0, 0), 3.0)
	draw_circle(tip, 4.0 if blink else 2.5, Color(1.0, 0.85, 0.2))
	draw_circle(tip, 2.0, Color.WHITE)
