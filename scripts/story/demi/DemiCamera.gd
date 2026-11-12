class_name DemiCamera
extends ArenaCamera
## OPEN-WORLD camera (DemiLand): follows YOU, and only frames enemies that are near you (an
## ArenaCamera would try to fit every enemy in the whole world). Cutscene focus still works.

const NEAR := 900.0                     # Enemies closer than this are kept in the shot


func _process(delta: float) -> void:
	_update_shake(delta)
	if focus != null and is_instance_valid(focus) and focus.is_inside_tree():
		var kf := 1.0 - exp(-3.0 * delta)
		global_position = global_position.lerp(focus.global_position + focus_offset, kf)
		zoom = zoom.lerp(Vector2(focus_zoom, focus_zoom), kf)
		return
	var me: Fighter = null
	for n in get_tree().get_nodes_in_group("fighters"):
		var f := n as Fighter
		if f != null and f.team == 1 and f is ControlledFighter:
			me = f
			break
	if me == null:
		return
	var lo := me.global_position
	var hi := me.global_position
	if not me.is_dead:
		for n in get_tree().get_nodes_in_group("fighters"):
			var f := n as Fighter
			if f == null or f.is_dead or f == me or absf(f.global_position.x - me.global_position.x) > NEAR:
				continue
			lo = lo.min(f.global_position)
			hi = hi.max(f.global_position)
	var target := (lo + hi) * 0.5 + Vector2(0, vertical_offset)
	target.y = minf(target.y, max_follow_y)
	var span := (hi - lo) + padding
	var vp := get_viewport_rect().size
	var z := clampf(minf(vp.x / span.x, vp.y / span.y), min_zoom, max_zoom)
	var k := 1.0 - exp(-follow_speed * delta)
	global_position = global_position.lerp(target, k)
	zoom = zoom.lerp(Vector2(z, z), k)
