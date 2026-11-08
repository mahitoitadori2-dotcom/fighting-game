class_name EnemyAI
extends RefCounted
## Base brain for PvE enemies. Every enemy gets a subclass (RotorAI, ...) that only
## overrides think(). Unlike BaseAI (which presses buttons for playable characters),
## an enemy brain picks PATTERNS and sets a move direction.
##
## Called every physics frame by BaseEnemy while it can act; decides every 0.2-0.3 s.

var think_min := 0.2
var think_max := 0.3
var rng := RandomNumberGenerator.new()

# Perception (fresh before every think)
var e: BaseEnemy
var target: Fighter
var dist := 9999.0
var dir := 1.0
var dy := 0.0

var _think := 0.0
var _ground: ArenaGround


func _init() -> void:
	rng.randomize()


func update(enemy: BaseEnemy, delta: float) -> void:
	e = enemy
	_think -= delta
	if _think > 0.0:
		_edge_safety()
		return
	_think = rng.randf_range(think_min, think_max)
	target = CombatManager.find_enemy(e)
	if target == null:
		e.move_dir = 0.0
		return
	var d := target.global_position - e.global_position
	dist = absf(d.x)
	dir = 1.0 if d.x >= 0.0 else -1.0
	dy = d.y
	think()
	_edge_safety()


## OVERRIDE: decide what to do. Default: walk in, use any pattern in range.
func think() -> void:
	if not e.can_act():
		return
	face_target()
	var p := pick_pattern()
	if p != null:
		e.start_pattern(p)
	elif dist > 80.0:
		approach()
	else:
		hold()


# ============================================================
# HELPERS
# ============================================================
func approach() -> void:
	e.move_dir = dir


func retreat() -> void:
	e.move_dir = -dir


func hold() -> void:
	e.move_dir = 0.0


func face_target() -> void:
	e.facing = int(dir)


func chance(p: float) -> bool:
	return rng.randf() < p


## Weighted random pick among patterns that are ready, in range and allowed this phase.
func pick_pattern(extra_filter: Callable = Callable()) -> EnemyPattern:
	var pool: Array[EnemyPattern] = []
	var total := 0.0
	for p in e.patterns:
		var w := p.weight(e.phase)
		if w <= 0.0 or not p.is_ready() or not p.in_range(dist):
			continue
		if extra_filter.is_valid() and not extra_filter.call(p):
			continue
		pool.append(p)
		total += w
	if pool.is_empty():
		return null
	var roll := rng.randf() * total
	for p in pool:
		roll -= p.weight(e.phase)
		if roll <= 0.0:
			return p
	return pool[pool.size() - 1]


## Never walk off the island.
func _edge_safety() -> void:
	if _ground == null or not is_instance_valid(_ground):
		_ground = e.get_tree().get_first_node_in_group("arena_ground") as ArenaGround
		if _ground == null:
			return
	var x := e.global_position.x
	if x < _ground.left_edge() + 90.0 and e.move_dir < 0.0:
		e.move_dir = 1.0
	elif x > _ground.right_edge() - 90.0 and e.move_dir > 0.0:
		e.move_dir = -1.0
