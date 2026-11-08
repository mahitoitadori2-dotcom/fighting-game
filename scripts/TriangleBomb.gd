class_name TriangleBomb
extends Area2D
## HNCT bomb. Sits on the ground until an enemy steps on it, then explodes.

var source: Fighter
var damage := 20
var knockback := Vector2(300, -320)
var blast_radius := 120.0
var arm_time := 0.4
var triggers_on_owner := false
var is_onslaught := false
var move := "hnct"               # Damage source: hnct / faoth
var part := ""                   # FAOTH sub-part ("hnct")

var _age := 0.0
var _done := false


func _ready() -> void:
	add_to_group("hnct")
	collision_layer = 0
	collision_mask = CombatManager.BODY_LAYER
	monitoring = true
	monitorable = false
	z_index = 1
	var shape := RectangleShape2D.new()
	shape.size = Vector2(56, 30)
	var col := CollisionShape2D.new()
	col.shape = shape
	col.position = Vector2(0, -15)
	add_child(col)


func make_onslaught(dmg_mult: float, kb_mult: float) -> void:
	if is_onslaught:
		return
	is_onslaught = true
	damage = roundi(damage * dmg_mult)
	knockback *= kb_mult
	blast_radius *= 1.25


func _physics_process(delta: float) -> void:
	if _done:
		return
	_age += delta
	if _age < arm_time:
		return
	for b in get_overlapping_bodies():
		var f := b as Fighter
		if f != null and not f.is_dead and (f != source or triggers_on_owner):
			# COUNTERPLAY: the Time Stop user stepping on an HNCT bomb shatters the
			# time stop and pays the penalty (handled by the fighter) instead of normal damage.
			if CombatManager.is_time_stopped() and f == CombatManager.time_stop_owner and f.has_method("break_time_stop"):
				f.break_time_stop()
				_done = true
				Effects.explosion(self, global_position + Vector2(0, -20), blast_radius, true, true)
				queue_free()
				return
			_explode()
			return


func _explode() -> void:
	_done = true
	var center := global_position + Vector2(0, -20)
	for n in get_tree().get_nodes_in_group("fighters"):
		var f := n as Fighter
		if f == null or f == source or f.is_dead:
			continue
		var fc := f.global_position + Vector2(0, -64)
		if fc.distance_to(center) > blast_radius + 32.0:
			continue
		var dx := signf(f.global_position.x - global_position.x)
		if dx == 0.0:
			dx = float(source.facing) if source != null else 1.0
		var h := HitData.new()
		h.source = source
		h.damage = damage
		h.knockback = Vector2(dx * knockback.x, knockback.y)
		h.origin = global_position
		h.hit_type = "trap"
		h.onslaught = is_onslaught
		h.move = move
		h.part = part
		CombatManager.apply_hit(h, f)
	Effects.explosion(self, center, blast_radius, is_onslaught, true)   # fire = true
	queue_free()


func _process(_delta: float) -> void:
	queue_redraw()


func _draw() -> void:
	var armed := _age >= arm_time
	if is_onslaught:
		draw_circle(Vector2(0, -20), 40.0, Color(1.0, 0.5, 0.1, 0.28))
	# Yellow warning triangle (3 tones + thick outline)
	var tri := PackedVector2Array([Vector2(-28, 0), Vector2(28, 0), Vector2(0, -46)])
	draw_colored_polygon(tri, Color(0.78, 0.52, 0.08))
	draw_colored_polygon(PackedVector2Array([Vector2(-28, 0), Vector2(16, 0), Vector2(-2, -41)]), Color(0.98, 0.80, 0.20))
	draw_colored_polygon(PackedVector2Array([Vector2(-20, -3), Vector2(-8, -3), Vector2(-5, -20), Vector2(-12, -14)]), Color(1.0, 0.95, 0.65))
	var closed: PackedVector2Array = tri.duplicate()
	closed.append(tri[0])
	draw_polyline(closed, FighterArt.BLACK, 4.0, true)
	# "!" mark
	draw_line(Vector2(0, -33), Vector2(0, -16), FighterArt.BLACK, 4.0)
	draw_circle(Vector2(0, -9), 2.8, FighterArt.BLACK)
	# Blinking light: fast red when armed
	var blink := 0.5 + 0.5 * sin(_age * (18.0 if armed else 6.0))
	draw_circle(Vector2(0, -50), 5.0, FighterArt.BLACK)
	draw_circle(Vector2(0, -50), 3.5, Color(1.0, 0.15 + 0.2 * blink, 0.1) if armed else Color(0.5, 0.5, 0.5))
