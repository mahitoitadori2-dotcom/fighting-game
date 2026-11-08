class_name VoidGoo
extends Area2D
## Black goo on the ground. Enemies standing in it are slowed, take extra damage,
## and take a small damage tick (so the goo itself can finish someone off:
## that triggers the Void Goo "drown" death).

var source: Fighter
var width := 360.0
var height := 44.0
var duration := 6.0
var slow := 0.4
var def_down := 0.4
var tick_damage := 1             # Damage per tick while standing in the goo
var tick_interval := 0.5
var move := "void_goo"           # Damage source: void_goo / faoth
var part := ""                   # FAOTH sub-part ("goo")

var _age := 0.0
var _spread := 0.0
var _shape: RectangleShape2D
var _tick_timers := {}           # Fighter -> seconds until next tick


func _ready() -> void:
	add_to_group("void_goo")
	z_index = -1                     # Ground layer: above the island, below fighters
	collision_layer = 0
	collision_mask = CombatManager.BODY_LAYER
	monitoring = true
	monitorable = false
	_shape = RectangleShape2D.new()
	_shape.size = Vector2(1.0, height)
	var col := CollisionShape2D.new()
	col.shape = _shape
	col.position = Vector2(0, -height / 2.0)
	add_child(col)


func _physics_process(delta: float) -> void:
	if source != null and is_instance_valid(source) and source.is_time_frozen():
		return                                         # Time Stop freezes the goo too
	_age += delta
	_spread = minf(_spread + delta * 3.0, 1.0)         # Spreads out over ~0.33 s
	_shape.size.x = maxf(width * _spread, 1.0)
	if _age >= duration:
		queue_free()
		return
	for b in get_overlapping_bodies():
		var f := b as Fighter
		if f != null and f != source and not f.is_dead:
			f.apply_goo(0.2, slow, def_down)           # Refreshed every frame while inside
			_tick(f, delta)
	queue_redraw()


func _tick(f: Fighter, delta: float) -> void:
	if tick_damage <= 0:
		return
	var t: float = _tick_timers.get(f, tick_interval) - delta
	if t > 0.0:
		_tick_timers[f] = t
		return
	_tick_timers[f] = tick_interval
	var h := HitData.new()
	h.source = source if is_instance_valid(source) else null
	h.damage = tick_damage
	h.blockable = false
	h.causes_hitstun = false
	h.knockback = Vector2.ZERO
	h.origin = global_position
	h.hit_type = "goo"
	h.is_tick = true
	h.move = move
	h.part = part
	CombatManager.apply_hit(h, f)


func _draw() -> void:
	var a := 1.0
	if _age > duration - 1.0:
		a = clampf(duration - _age, 0.0, 1.0)          # Fade out in the last second
	var w := width * _spread * 0.5
	var n := 24
	var pts := PackedVector2Array()
	pts.append(Vector2(-w, 0))
	for i in n + 1:
		var u := float(i) / float(n)
		var edge := sin(u * PI)
		var bump := 0.55 + 0.45 * sin(u * 14.0 + _age * 3.0)
		pts.append(Vector2(lerpf(-w, w, u), -height * edge * bump))
	pts.append(Vector2(w, 0))
	# Purple (surface) -> black (bottom) gradient, organic wavy top edge
	var cols := PackedColorArray()
	for p in pts:
		var k := clampf(-p.y / height, 0.0, 1.0)
		cols.append(Color(0.02, 0.0, 0.04, 0.97 * a).lerp(Color(0.34, 0.14, 0.48, 0.95 * a), k))
	if w > 2.0:
		draw_polygon(pts, cols)
	draw_polyline(FighterArt.wobble(pts.slice(1, n + 2), Vector2(0, 0), 1.2), Color(0.6, 0.32, 0.85, a), 3.0, true)
	for i in 5:
		var bx := sin(float(i) * 2.3 + _age * 0.7) * w * 0.8
		var by := -height * (0.25 + 0.55 * fmod(_age * 0.6 + float(i) * 0.37, 1.0))
		draw_circle(Vector2(bx, by), 3.0 + float(i % 3), Color(0.55, 0.3, 0.8, 0.8 * a))
