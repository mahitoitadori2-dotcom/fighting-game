class_name ChemicalPool
extends Node2D
## Blinded Lord's CHEMICAL POOL: a bubbling toxic puddle on the floor. Anyone of the
## other team STANDING in it takes small damage ticks (no knockback, no hitstun).
## POOLED (OptimizationManager.take / release). Max MAX_POOLS at once: the oldest
## dries up first. Spawn with ChemicalPool.spawn(source, ground_pos, width, lifetime).

const MAX_POOLS := 12
const TICK := 0.7
const TICK_DAMAGE := 2
const FADE_IN := 0.25
const FADE_OUT := 0.6

const GREEN := Color(0.45, 0.95, 0.15)
const GREEN_DARK := Color(0.18, 0.50, 0.06)
const GREEN_HI := Color(0.85, 1.0, 0.6)

static var _live: Array[ChemicalPool] = []

var pool_gen := 0
var source: Fighter
var width := 130.0
var lifetime := 5.0
var _age := 0.0
var _tick := 0.0
var _done := false
var _seed := 0


static func spawn(src: Fighter, ground_pos: Vector2, w: float, life: float) -> ChemicalPool:
	if src == null or not src.is_inside_tree():
		return null
	# Too many puddles: the oldest one starts drying up right away
	var alive: Array[ChemicalPool] = []
	for p in _live:
		if is_instance_valid(p) and p.is_inside_tree() and not p._done:
			alive.append(p)
	_live = alive
	if _live.size() >= MAX_POOLS:
		_live[0].dry_up()
	var pool := OptimizationManager.take(ChemicalPool) as ChemicalPool
	pool.source = src
	pool.width = w
	pool.lifetime = life
	src.get_tree().current_scene.add_child(pool)
	pool.global_position = ground_pos
	_live.append(pool)
	SoundManager.play_sfx("chem_spill", -5.0)           # Splat + bubbles (same-sound gap stops stacking)
	return pool


## Every puddle starts drying up (boss intro / boss death).
static func dry_all() -> void:
	for p in _live:
		if is_instance_valid(p) and p.is_inside_tree() and not p._done:
			p.dry_up()


func _enter_tree() -> void:
	z_index = -1                                    # On the floor, under the fighters
	_age = 0.0
	_tick = TICK * 0.5
	_done = false
	_seed = randi()
	set_process(true)


func dry_up() -> void:
	lifetime = minf(lifetime, _age + FADE_OUT)


func _process(delta: float) -> void:
	if source != null and is_instance_valid(source) and source.is_time_frozen():
		return
	_age += delta
	if _age >= lifetime:
		_recycle()
		return
	_tick -= delta
	if _tick <= 0.0 and _age > FADE_IN and CombatManager.fight_active:     # No damage during cutscenes
		_tick = TICK
		_damage_standing()
	if OptimizationManager.on_screen(global_position, width):
		queue_redraw()


func _damage_standing() -> void:
	for n in get_tree().get_nodes_in_group("fighters"):
		var f := n as Fighter
		if f == null or f.is_dead:
			continue
		if source != null and is_instance_valid(source) and CombatManager.are_allies(source, f):
			continue
		if absf(f.global_position.x - global_position.x) > width * 0.5 + f.data.body_size.x * 0.3:
			continue
		if absf(f.global_position.y - global_position.y) > 18.0:
			continue                                    # Jumping over it is safe
		var h := HitData.new()
		h.source = source if source != null and is_instance_valid(source) else null
		h.damage = TICK_DAMAGE
		h.blockable = false
		h.causes_hitstun = false
		h.is_tick = true
		h.gauge_gain = false
		h.hit_type = "enemy"
		h.move = "chemicals"
		h.origin = global_position
		CombatManager.apply_hit(h, f)


func _recycle() -> void:
	_done = true
	set_process(false)
	source = null
	OptimizationManager.release(self)


func _draw() -> void:
	var k := clampf(_age / FADE_IN, 0.0, 1.0) * (1.0 - clampf((_age - (lifetime - FADE_OUT)) / FADE_OUT, 0.0, 1.0))
	if k <= 0.0:
		return
	var hw := width * 0.5 * (0.4 + 0.6 * k)
	# Glow + puddle
	draw_set_transform(Vector2(0, -2), 0.0, Vector2(1.0, 0.22))
	draw_circle(Vector2.ZERO, hw * 1.15, Color(GREEN.r, GREEN.g, GREEN.b, 0.18 * k))
	draw_set_transform(Vector2.ZERO, 0.0, Vector2.ONE)
	var pts := PackedVector2Array()
	for i in 18:
		var a := TAU * float(i) / 18.0
		var wob := 1.0 + 0.08 * sin(float(i) * 2.3 + _age * 3.0)
		pts.append(Vector2(cos(a) * hw * wob, -3.0 + sin(a) * 9.0 * wob))
	draw_colored_polygon(pts, Color(GREEN_DARK.r, GREEN_DARK.g, GREEN_DARK.b, 0.9 * k))
	var inner := PackedVector2Array()
	for p in pts:
		inner.append(p * 0.72 + Vector2(0, -1))
	draw_colored_polygon(inner, Color(GREEN.r, GREEN.g, GREEN.b, 0.9 * k))
	# Bubbles popping
	var rng := RandomNumberGenerator.new()
	rng.seed = _seed
	for i in 5:
		var bx := rng.randf_range(-hw * 0.7, hw * 0.7)
		var ph := fmod(_age * rng.randf_range(0.8, 1.6) + rng.randf(), 1.0)
		var br := 2.0 + ph * 4.0
		draw_arc(Vector2(bx, -4.0 - ph * 10.0), br, 0.0, TAU, 10, Color(GREEN_HI.r, GREEN_HI.g, GREEN_HI.b, (1.0 - ph) * k), 1.5)
	# Rising fumes
	for i in 3:
		var fx := -hw * 0.5 + float(i) * hw * 0.5
		var fy := -12.0 - fmod(_age * 20.0 + float(i) * 13.0, 40.0)
		draw_circle(Vector2(fx + sin(_age * 2.0 + float(i)) * 6.0, fy), 5.0, Color(0.6, 1.0, 0.3, 0.12 * k))
