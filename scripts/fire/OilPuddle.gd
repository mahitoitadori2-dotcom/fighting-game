class_name OilPuddle
extends Area2D
## Black oil on the floor (Volatile Nightmare / Ritual of the Troupe).
## Harmless until ANY fire touches it (flames, bats, floor spikes, other burning oil),
## then it IGNITES: enemies standing in it take burn damage every second.
## The Nightmare Lord himself is never burned by his own oil.

const RED := Color(1.0, 0.0, 0.0)
const RED_DARK := Color(0.6, 0.0, 0.0)
const OIL := Color(0.04, 0.03, 0.05)
const OIL_SHINE := Color(0.30, 0.26, 0.36)
const IGNITE_HEIGHT := 150.0         # Fire this far above the puddle lights it

var source: Fighter
var width := 280.0
var duration := 9.0
var burn_damage := 5                 # Per tick
var burn_interval := 1.0             # = 5 damage per second
var burn_time := 5.0
var move := "oil"

var burning := false
var _age := 0.0
var _burn_age := 0.0
var _spread := 0.0
var _shape: RectangleShape2D
var _tick := {}                      # Fighter -> seconds until next burn tick


func _ready() -> void:
	collision_layer = 0
	collision_mask = CombatManager.BODY_LAYER
	monitoring = true
	monitorable = false
	z_index = -1                     # Ground layer: above the island, below fighters
	_shape = RectangleShape2D.new()
	_shape.size = Vector2(1, 22)
	var col := CollisionShape2D.new()
	col.shape = _shape
	col.position = Vector2(0, -11)
	add_child(col)


func ignite() -> void:
	if burning:
		return
	burning = true
	_burn_age = 0.0
	add_to_group("fire")                             # Burning oil lights other oil next to it
	Effects.red_burst(self, global_position + Vector2(0, -16), width * 0.25)


func _physics_process(delta: float) -> void:
	if source == null or not is_instance_valid(source) or source.is_dead:
		queue_free()                                   # Owner died: the board is cleaned before respawn
		return
	if source.is_time_frozen():
		return
	_age += delta
	_spread = minf(_spread + delta * 4.0, 1.0)
	_shape.size.x = maxf(width * _spread, 1.0)
	if burning:
		_burn_age += delta
		if _burn_age >= burn_time:
			queue_free()
			return
	elif _age >= duration:
		queue_free()
		return

	if not burning:
		# Any fire passing OVER the puddle ignites it (flames fly ~80 px above the floor).
		var half := width * _spread * 0.5
		for n in get_tree().get_nodes_in_group("fire"):
			var fire := n as Node2D
			if fire == null or fire == self:
				continue
			var p := fire.global_position - global_position
			var reach := half + 10.0
			if fire is OilPuddle:                     # Burning puddles touching each other
				reach = half + (fire as OilPuddle).width * 0.5
			if absf(p.x) <= reach and p.y > -IGNITE_HEIGHT and p.y < 12.0:
				ignite()
				break
		return

	for b in get_overlapping_bodies():
		var f := b as Fighter
		if f == null or f == source or f.is_dead:
			continue
		var t: float = _tick.get(f, 0.0) - delta
		if t > 0.0:
			_tick[f] = t
			continue
		_tick[f] = burn_interval
		var h := HitData.new()
		h.source = source if is_instance_valid(source) else null
		h.damage = burn_damage
		h.blockable = false
		h.causes_hitstun = false
		h.knockback = Vector2.ZERO
		h.origin = global_position
		h.hit_type = "fire"
		h.is_tick = true
		h.move = move
		CombatManager.apply_hit(h, f)


func _process(_delta: float) -> void:
	queue_redraw()


func _draw() -> void:
	var w := width * _spread * 0.5
	if w < 2.0:
		return
	var a := 1.0
	if not burning and _age > duration - 1.0:
		a = clampf(duration - _age, 0.0, 1.0)
	if burning and _burn_age > burn_time - 0.6:
		a = clampf((burn_time - _burn_age) / 0.6, 0.0, 1.0)
	# Puddle
	var pts := PackedVector2Array()
	for i in 20:
		var u := float(i) / 19.0
		pts.append(Vector2(lerpf(-w, w, u), -4.0 * sin(u * PI) - 2.0 * sin(u * 11.0)))
	for i in 20:
		var u := 1.0 - float(i) / 19.0
		pts.append(Vector2(lerpf(-w, w, u), 2.0))
	draw_colored_polygon(pts, Color(OIL.r, OIL.g, OIL.b, a))
	var closed := pts.duplicate()
	closed.append(pts[0])
	draw_polyline(closed, Color(0, 0, 0, a), 3.0, true)
	draw_line(Vector2(-w * 0.5, -3), Vector2(-w * 0.1, -4), Color(OIL_SHINE.r, OIL_SHINE.g, OIL_SHINE.b, a), 2.0)
	# Pure red fire on top
	if burning:
		var n := int(w / 16.0)
		for i in n:
			var x := lerpf(-w + 10.0, w - 10.0, float(i) / maxf(float(n - 1), 1.0))
			var h := (22.0 + 12.0 * sin(_burn_age * 14.0 + float(i) * 1.9)) * a
			var fl := PackedVector2Array([Vector2(x - 9, 0), Vector2(x + 9, 0), Vector2(x + 2, -h)])
			if h > 2.0:
				draw_polygon(fl, PackedColorArray([RED, RED, RED_DARK]))     # Pure red -> dark red
