class_name FloorSpike
extends Area2D
## Red crystal spike that bursts out of the floor (Launch O' Spikes slam).
## Hits each enemy once. Counts as FIRE (ignites oil it touches).
## POOLED: spawn with OptimizationManager.take(FloorSpike); it recycles itself.

const RED := Color(1.0, 0.0, 0.0)
const RED_DARK := Color(0.55, 0.0, 0.0)
const RED_LIGHT := Color(1.0, 0.45, 0.45)

var pool_gen := 0
var source: Fighter
var damage := 7
var knockback := Vector2(180, -380)
var height := 74.0
var width := 38.0
var delay := 0.0                     # Ripple: wait before erupting
var move := "launch_spikes"

var _age := 0.0
var _done := false
var _lean := 0.0
var _hit: Array[Fighter] = []
var _shape: RectangleShape2D
var _col: CollisionShape2D

const RISE := 0.1
const HOLD := 0.45
const SINK := 0.2


func _init() -> void:
	add_to_group("fire")
	collision_layer = CombatManager.FIRE_LAYER
	collision_mask = CombatManager.HURTBOX_LAYER
	monitoring = true
	monitorable = true
	z_index = 3
	_shape = RectangleShape2D.new()
	_col = CollisionShape2D.new()
	_col.shape = _shape
	add_child(_col)


func _enter_tree() -> void:
	_age = 0.0
	_done = false
	_hit.clear()
	_lean = randf_range(-6.0, 6.0)                 # Each spike leans a little differently
	_shape.size = Vector2(width, 1.0)
	_col.position = Vector2.ZERO
	set_physics_process(true)
	set_process(true)


func _grow() -> float:
	var t := _age - delay
	if t <= 0.0:
		return 0.0
	if t < RISE:
		return t / RISE
	if t < RISE + HOLD:
		return 1.0
	return clampf(1.0 - (t - RISE - HOLD) / SINK, 0.0, 1.0)


func _physics_process(delta: float) -> void:
	if _done:
		return
	if source != null and is_instance_valid(source) and source.is_time_frozen():
		return
	_age += delta
	if _age >= delay + RISE + HOLD + SINK:
		_recycle()
		return
	var g := _grow()
	_shape.size = Vector2(width, maxf(height * g, 1.0))
	_col.position = Vector2(0, -height * g * 0.5)
	if g < 0.3:
		return
	for area in get_overlapping_areas():
		var hb := area as Hurtbox
		if hb == null or hb.fighter == source or hb.fighter.is_dead or _hit.has(hb.fighter):
			continue
		_hit.append(hb.fighter)
		var dx := signf(hb.fighter.global_position.x - global_position.x)
		if dx == 0.0:
			dx = 1.0
		var h := HitData.new()
		h.source = source
		h.damage = damage
		h.knockback = Vector2(dx * knockback.x, knockback.y)
		h.origin = global_position + Vector2(0, -10)
		h.hit_type = "spike"
		h.move = move
		CombatManager.apply_hit(h, hb.fighter)


func _recycle() -> void:
	_done = true
	set_physics_process(false)
	set_process(false)
	source = null
	damage = 7
	knockback = Vector2(180, -380)
	height = 74.0
	width = 38.0
	delay = 0.0
	move = "launch_spikes"
	OptimizationManager.release(self)


func _process(_delta: float) -> void:
	if _age >= delay and OptimizationManager.on_screen(global_position, 60.0):
		queue_redraw()                                 # Nothing to draw before it erupts


func _draw() -> void:
	var g := _grow()
	if g <= 0.0:
		return
	var h := height * g
	var w := width * 0.5
	FighterArt.curved_spike(self, Vector2.ZERO, Vector2(_lean, -h), w, RED_DARK, RED, 0.3, 3.5)
	draw_line(Vector2(-w * 0.35, -4), Vector2(_lean * 0.6 - w * 0.05, -h * 0.65), RED_LIGHT, 2.5)
	# Cracked ground ring
	draw_line(Vector2(-w - 8, 0), Vector2(w + 8, 0), Color(0, 0, 0), 4.0)
