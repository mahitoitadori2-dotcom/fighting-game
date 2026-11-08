class_name OptimizationManager
extends RefCounted
## PERFORMANCE TOOLS (static, used everywhere):
##
##   OBJECT POOLING   take(Script) / release(node)
##     Projectiles, bats, flames, spikes, sparks, bursts, popups and trails are
##     REUSED instead of instantiated + freed every time. A pooled node is removed
##     from the tree (not freed) and handed out again later. Pooled scripts reset
##     themselves in _enter_tree(); `pool_gen` changes on every reuse so anything
##     still pointing at an old incarnation (e.g. a trail) can tell.
##
##   PARTICLE CAP     claim_particles(node, n) / free_particles(node)
##     At most MAX_PARTICLES live at once. Over the cap, the OLDEST effect is
##     recycled first. Death animations ask particles_available() before spawning.
##
##   CULLING          on_screen(world_pos, margin)
##     ArenaCamera publishes the visible world rect every frame. Projectiles that
##     leave it (plus a margin) are recycled; off-screen enemies skip redraws.

## Phones in a browser get a lower cap so big ultimates stay at 60 FPS.
static var MAX_PARTICLES: int = 110 if (OS.has_feature("web_ios") or OS.has_feature("web_android")) else 200
const POOL_MAX_PER_TYPE := 96

static var _pools := {}                       # Script -> Array[Node]
static var _owners: Array[Dictionary] = []    # FIFO of {node, count}
static var live_particles := 0
static var screen_rect := Rect2(-10000, -10000, 20000, 20000)   # World rect the camera sees
static var reused := 0
static var created := 0


# ============================================================
# POOLING
# ============================================================
## A ready-to-configure node of this script (reused if one is waiting in the pool).
## Configure it, THEN add_child it: its _enter_tree() resets per-spawn state.
static func take(script: Script) -> Node:
	var arr: Array = _pools.get(script, [])
	while not arr.is_empty():
		var n: Node = arr.pop_back()
		if is_instance_valid(n) and n.get_parent() == null:
			reused += 1
			if "pool_gen" in n:
				n.pool_gen += 1
			return n
	created += 1
	return script.new()


## Recycle instead of queue_free(). Safe to call from physics callbacks.
static func release(n: Node) -> void:
	if n == null or not is_instance_valid(n) or n.is_queued_for_deletion():
		return
	free_particles(n)
	var script: Script = n.get_script()
	if not _pools.has(script):
		_pools[script] = []
	var arr: Array = _pools[script]
	if n.has_meta("_pooled"):
		return                                  # Already on its way back
	if arr.size() >= POOL_MAX_PER_TYPE:
		n.queue_free()
		return
	n.set_meta("_pooled", true)
	arr.append(n)
	var parent := n.get_parent()
	if parent != null:
		parent.remove_child.call_deferred(n)
	_clear_meta.call_deferred(n)


static func _clear_meta(n: Node) -> void:
	if is_instance_valid(n):
		n.remove_meta("_pooled")


## Pooled nodes are not in the tree, so scene changes don't free them. Call on a new match.
static func clear_pools() -> void:
	for script in _pools:
		for n in _pools[script]:
			if is_instance_valid(n) and n.get_parent() == null:
				n.free()
	_pools.clear()
	_owners.clear()
	live_particles = 0


static func pooled_count() -> int:
	var c := 0
	for script in _pools:
		c += (_pools[script] as Array).size()
	return c


# ============================================================
# PARTICLE CAP
# ============================================================
static func claim_particles(owner: Node, count: int) -> void:
	_owners.append({"node": owner, "count": count})
	live_particles += count
	while live_particles > MAX_PARTICLES and not _owners.is_empty():
		var oldest: Dictionary = _owners.pop_front()
		live_particles -= int(oldest["count"])
		var n: Variant = oldest["node"]         # Untyped: may be a freed node (scene changed)
		if is_instance_valid(n) and n != owner and n.has_method("recycle"):
			n.recycle()                         # Oldest effect goes first


static func free_particles(owner: Node) -> void:
	for i in range(_owners.size() - 1, -1, -1):
		if _owners[i]["node"] == owner:
			live_particles -= int(_owners[i]["count"])
			_owners.remove_at(i)


static func particles_available(n: int = 1) -> bool:
	return live_particles + n <= MAX_PARTICLES


# ============================================================
# CULLING
# ============================================================
static func on_screen(world_pos: Vector2, margin: float = 0.0) -> bool:
	return screen_rect.grow(margin).has_point(world_pos)
