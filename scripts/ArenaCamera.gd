class_name ArenaCamera
extends Camera2D
## Fighting-game camera: frames every living fighter, zooms out as they spread
## apart and never follows a falling fighter into the void.

@export var min_zoom := 0.6               # Furthest zoom-out
@export var max_zoom := 0.8               # Closest zoom-in (shows a good chunk of the arena)
@export var padding := Vector2(700, 420)  # Extra space around the fighters
@export var follow_speed := 4.0
@export var vertical_offset := -150.0     # Look above the fighters' feet (more sky, less rock)
@export var max_follow_y := 420.0         # Camera centre never goes lower than this


var _shake := 0.0

## CUTSCENES: while set, the camera frames this node instead of the fighters.
static var focus: Node2D = null
static var focus_zoom := 1.0
static var focus_offset := Vector2(0, -110)


func _ready() -> void:
	make_current()


## Screen shake (Effects.shake). Strength in px; strongest request wins, then decays.
func add_shake(strength: float) -> void:
	_shake = maxf(_shake, strength)


func _update_shake(delta: float) -> void:
	if _shake <= 0.05:
		_shake = 0.0
		offset = Vector2.ZERO
		return
	offset = Vector2(randf_range(-1.0, 1.0), randf_range(-1.0, 1.0)) * _shake
	_shake = move_toward(_shake, 0.0, (_shake * 9.0 + 6.0) * delta)


func _process(delta: float) -> void:
	_update_shake(delta)
	if focus != null and is_instance_valid(focus) and focus.is_inside_tree():
		var kf := 1.0 - exp(-3.0 * delta)
		global_position = global_position.lerp(focus.global_position + focus_offset, kf)
		zoom = zoom.lerp(Vector2(focus_zoom, focus_zoom), kf)
		return
	var lo := Vector2(INF, INF)
	var hi := Vector2(-INF, -INF)
	var count := 0
	for n in get_tree().get_nodes_in_group("fighters"):
		var f := n as Fighter
		if f == null or f.is_dead:
			continue
		lo = lo.min(f.global_position)
		hi = hi.max(f.global_position)
		count += 1
	if count == 0:
		return

	var target := (lo + hi) * 0.5 + Vector2(0, vertical_offset)
	target.y = minf(target.y, max_follow_y)
	var span := (hi - lo) + padding
	var vp := get_viewport_rect().size
	var z := clampf(minf(vp.x / span.x, vp.y / span.y), min_zoom, max_zoom)

	var k := 1.0 - exp(-follow_speed * delta)
	global_position = global_position.lerp(target, k)
	zoom = zoom.lerp(Vector2(z, z), k)
