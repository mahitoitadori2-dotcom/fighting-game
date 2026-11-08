class_name FireProjectile
extends Area2D
## Nightmare Lord's projectiles. kind = "flame" (PURE RED fireball) or "bat" (red bat).
## Hits the first enemy hurtbox it touches, once. Lives on the FIRE layer so
## oil puddles it touches catch fire. Freezes during an enemy Time Stop.
## POOLED: spawn with OptimizationManager.take(FireProjectile); it recycles itself.

const RED := Color(1.0, 0.0, 0.0)           # #FF0000: ALL his flames are pure red
const RED_DARK := Color(0.55, 0.0, 0.0)
const RED_LIGHT := Color(1.0, 0.42, 0.42)
const BLACK := Color(0, 0, 0)

var pool_gen := 0
var source: Fighter
var kind := "flame"
var damage := 5
var knockback := Vector2(150, -90)
var speed := 620.0
var dir := Vector2.RIGHT
var lifetime := 0.85
var move := "bloodflame"
var hit_type := "fire"
var wave := 0.0                              # Bats: vertical wobble amplitude

var _age := 0.0
var _done := false
var _started := false
var _phase := 0.0
var _shape: CircleShape2D


func _init() -> void:
	add_to_group("fire")
	collision_layer = CombatManager.FIRE_LAYER
	collision_mask = CombatManager.HURTBOX_LAYER | CombatManager.WORLD_LAYER
	monitoring = true
	monitorable = true
	z_index = 8
	_shape = CircleShape2D.new()
	var col := CollisionShape2D.new()
	col.shape = _shape
	add_child(col)


func _enter_tree() -> void:
	_age = 0.0
	_done = false
	_started = false
	_phase = randf() * TAU
	_shape.radius = 12.0 if kind == "flame" else 16.0
	set_physics_process(true)
	set_process(true)


## First physics frame (the spawner sets global_position AFTER add_child).
func _start() -> void:
	_started = true
	if kind == "bat":
		Effects.trail(self, Color(0.55, 0.0, 0.0), 8.0, 10)
	else:
		Effects.trail(self, Color(1.0, 0.0, 0.0), 12.0, 10)      # Pure red


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
	var v := dir * speed
	if kind == "bat":
		v.y += cos(_age * 9.0 + _phase) * wave
	global_position += v * delta
	if kind == "flame":
		rotation = dir.angle()

	for area in get_overlapping_areas():
		var hb := area as Hurtbox
		if hb != null and hb.fighter != source and not hb.fighter.is_dead:
			var h := HitData.new()
			h.source = source
			h.damage = damage
			var dx := signf(dir.x)
			if dx == 0.0:
				dx = float(source.facing) if source != null and is_instance_valid(source) else 1.0
			h.knockback = Vector2(dx * knockback.x, knockback.y)
			h.origin = global_position - dir * 40.0
			h.hit_type = hit_type
			h.move = move
			CombatManager.apply_hit(h, hb.fighter)
			_vanish()
			return
	if _age > 0.06 and get_overlapping_bodies().size() > 0:
		_vanish()


func _vanish() -> void:
	if _done:
		return
	Effects.red_burst(self, global_position, 22.0 if kind == "flame" else 30.0)
	_recycle()


func _recycle() -> void:
	_done = true
	set_physics_process(false)
	set_process(false)
	source = null
	kind = "flame"
	damage = 5
	knockback = Vector2(150, -90)
	speed = 620.0
	dir = Vector2.RIGHT
	lifetime = 0.85
	move = "bloodflame"
	hit_type = "fire"
	wave = 0.0
	rotation = 0.0
	OptimizationManager.release(self)


func _process(_delta: float) -> void:
	if OptimizationManager.on_screen(global_position, 60.0):
		queue_redraw()                                 # Culling: no redraw off-screen


func _draw() -> void:
	if kind == "bat":
		_draw_bat()
	else:
		_draw_flame()


func _draw_flame() -> void:
	# Teardrop fireball pointing along +X, flickering. Pure red only.
	var f := 1.0 + 0.15 * sin(_age * 40.0 + _phase)
	var tail := -26.0 * f
	var outer := PackedVector2Array([Vector2(13, 0), Vector2(6, -10), Vector2(-6, -11), Vector2(tail * 0.6, -6),
		Vector2(tail, 0), Vector2(tail * 0.6, 6), Vector2(-6, 11), Vector2(6, 10)])
	draw_circle(Vector2.ZERO, 18.0, Color(RED.r, 0.0, 0.0, 0.22))
	var cols := PackedColorArray()
	for p in outer:
		cols.append(RED.lerp(RED_DARK, clampf(-p.x / 26.0, 0.0, 1.0)))   # Head bright, tail dark
	draw_polygon(outer, cols)
	FighterArt.outline(self, outer, 3.0)
	draw_colored_polygon(PackedVector2Array([Vector2(8, 0), Vector2(2, -5), Vector2(tail * 0.45, 0), Vector2(2, 5)]), RED_DARK)
	draw_circle(Vector2(4, -2), 3.5, RED_LIGHT)


func _draw_bat() -> void:
	var flap := sin(_age * 22.0 + _phase)
	var s := Vector2(signf(dir.x) if dir.x != 0.0 else 1.0, 1.0)
	draw_set_transform(Vector2.ZERO, 0.0, s)
	var wy := -14.0 * flap
	for side in [-1.0, 1.0]:
		var wing := PackedVector2Array([
			Vector2(4 * side, -2), Vector2(16 * side, -8 + wy * 0.6), Vector2(28 * side, -4 + wy),
			Vector2(22 * side, 2 + wy * 0.5), Vector2(17 * side, 0 + wy * 0.3), Vector2(12 * side, 6), Vector2(4 * side, 4)])
		draw_colored_polygon(wing, RED_DARK)
		var wc := wing.duplicate()
		wc.append(wing[0])
		draw_polyline(wc, BLACK, 2.5, true)
	draw_circle(Vector2.ZERO, 9.5, BLACK)
	draw_circle(Vector2.ZERO, 7.5, RED)
	draw_colored_polygon(PackedVector2Array([Vector2(-6, -5), Vector2(-4, -12), Vector2(-1, -6)]), RED)   # Ears
	draw_colored_polygon(PackedVector2Array([Vector2(6, -5), Vector2(4, -12), Vector2(1, -6)]), RED)
	draw_circle(Vector2(3, -1), 1.8, Color.WHITE)
	draw_circle(Vector2(-2, -1), 1.8, Color.WHITE)
	draw_set_transform(Vector2.ZERO, 0.0, Vector2.ONE)
