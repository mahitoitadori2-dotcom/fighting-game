class_name Rocket
extends Area2D
## Rocket Delivery projectile. Homes on the nearest enemy, explodes on contact.
## POOLED: spawn with OptimizationManager.take(Rocket); it returns itself to the pool.

var pool_gen := 0
var source: Fighter
var target: Fighter
var damage := 10
var knockback := Vector2(400, -220)
var speed := 540.0
var turn_rate := 4.0
var lifetime := 4.0
var dir := Vector2.RIGHT
var blast_radius := 70.0
var is_onslaught := false
var move := "rocket"             # Damage source: rocket / triple_rocket / faoth
var part := ""                   # FAOTH sub-part ("rocket")

var _age := 0.0
var _done := false
var _started := false


func _init() -> void:
	add_to_group("rockets")
	collision_layer = 0
	collision_mask = CombatManager.HURTBOX_LAYER | CombatManager.WORLD_LAYER
	monitoring = true
	monitorable = false
	z_index = 8
	var shape := CircleShape2D.new()
	shape.radius = 14.0
	var col := CollisionShape2D.new()
	col.shape = shape
	add_child(col)


func _enter_tree() -> void:
	_age = 0.0
	_done = false
	_started = false
	set_physics_process(true)


## First physics frame (the spawner sets global_position AFTER add_child).
func _start() -> void:
	_started = true
	target = CombatManager.find_enemy(source)
	rotation = dir.angle()
	Effects.trail(self, Color(0.95, 0.9, 0.85), 12.0, 16)          # Smoke trail


func _recycle() -> void:
	_done = true
	set_physics_process(false)
	# Back to the defaults so the next spawner starts clean
	source = null
	target = null
	damage = 10
	knockback = Vector2(400, -220)
	speed = 540.0
	turn_rate = 4.0
	lifetime = 4.0
	dir = Vector2.RIGHT
	blast_radius = 70.0
	is_onslaught = false
	move = "rocket"
	part = ""
	scale = Vector2.ONE
	OptimizationManager.release(self)


func make_onslaught(dmg_mult: float, kb_mult: float) -> void:
	if is_onslaught:
		return
	is_onslaught = true
	damage = roundi(damage * dmg_mult)
	knockback *= kb_mult
	blast_radius *= 1.4
	scale = Vector2(1.25, 1.25)


func _physics_process(delta: float) -> void:
	if _done:
		return
	if source != null and is_instance_valid(source) and source.is_time_frozen():
		return                # Time Stop: rocket freezes in mid-air
	if not _started:
		_start()
	_age += delta
	if _age >= lifetime:
		_explode()
		return

	# Homing (limited turn rate so it curves instead of snapping)
	if not is_instance_valid(target) or target.is_dead:
		target = CombatManager.find_enemy(source)
	if is_instance_valid(target) and not target.is_dead and _age > 0.1:
		var to_t := target.global_position + Vector2(0, -64) - global_position
		var diff := wrapf(to_t.angle() - dir.angle(), -PI, PI)
		dir = dir.rotated(clampf(diff, -turn_rate * delta, turn_rate * delta))
	global_position += dir * speed * delta
	rotation = dir.angle()

	for area in get_overlapping_areas():
		var hb := area as Hurtbox
		if hb != null and hb.fighter != source and not hb.fighter.is_dead \
				and not CombatManager.passes_through(source, hb.fighter):     # Flies through allies
			_hit(hb.fighter)
			return
	if get_overlapping_bodies().size() > 0:      # Island / world
		_explode()


func _hit(victim: Fighter) -> void:
	var h := HitData.new()
	h.source = source
	h.damage = damage
	var dx := signf(dir.x)
	if dx == 0.0:
		dx = float(source.facing) if source != null else 1.0
	h.knockback = Vector2(dx * knockback.x, knockback.y)
	h.origin = global_position - dir * 40.0       # Where it CAME from (block direction)
	h.hit_type = "projectile"
	h.onslaught = is_onslaught
	h.move = move
	h.part = part
	CombatManager.apply_hit(h, victim)
	_explode()


func _explode() -> void:
	if _done:
		return
	_done = true
	Effects.explosion(self, global_position, blast_radius, is_onslaught)
	_recycle()


func _process(_delta: float) -> void:
	if not _done and OptimizationManager.on_screen(global_position, 80.0):
		queue_redraw()                                 # Culling: no redraw off-screen


func _draw() -> void:
	var out_col := Color(1.0, 0.5, 0.1) if is_onslaught else Color(1.0, 0.32, 0.15)
	var flame := 16.0 + randf() * 8.0
	draw_colored_polygon(PackedVector2Array([Vector2(-16, -5), Vector2(-16 - flame, 0), Vector2(-16, 5)]), out_col)
	draw_colored_polygon(PackedVector2Array([Vector2(-16, -3), Vector2(-16 - flame * 0.6, 0), Vector2(-16, 3)]), Color(1, 0.92, 0.3))
	# Fins
	var fin := PackedVector2Array([Vector2(-16, -6), Vector2(-24, -14), Vector2(-6, -6)])
	var fin2 := PackedVector2Array([Vector2(-16, 6), Vector2(-24, 14), Vector2(-6, 6)])
	for f in [fin, fin2]:
		draw_colored_polygon(f, Color(0.35, 0.38, 0.45))
		var closed: PackedVector2Array = f.duplicate()
		closed.append(f[0])
		draw_polyline(closed, FighterArt.BLACK, 3.0, FighterArt.AA)
	# Body + nose
	FighterArt.rrect(self, Rect2(-18, -7, 34, 14), Color(0.93, 0.95, 0.97), Color(0.58, 0.62, 0.7), Color.WHITE, 6.0, 3.0)
	var nose := PackedVector2Array([Vector2(14, -7), Vector2(30, 0), Vector2(14, 7)])
	draw_colored_polygon(nose, Color(1.0, 0.45, 0.1) if is_onslaught else Color(0.9, 0.2, 0.2))
	var nose_closed: PackedVector2Array = nose.duplicate()
	nose_closed.append(nose[0])
	draw_polyline(nose_closed, FighterArt.BLACK, 3.0, FighterArt.AA)
	draw_circle(Vector2(2, 0), 3.0, Color(0.25, 0.85, 1.0))
