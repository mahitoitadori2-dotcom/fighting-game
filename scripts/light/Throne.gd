class_name Throne
extends Area2D
## G2 Throne: a giant golden throne hurled at the opponent. Hits ONCE, big knockback,
## bursts on impact (counts as an EXPLOSION damage type).

const GOLD := Color(0.98, 0.78, 0.26)
const GOLD_SHADE := Color(0.70, 0.50, 0.12)
const GOLD_HI := Color(1.0, 0.95, 0.65)
const CUSHION := Color(0.62, 0.10, 0.22)
const BLACK := Color(0, 0, 0)

var source: Fighter
var target: Fighter
var damage := 30
var knockback := Vector2(720, -420)
var speed := 650.0
var turn_rate := 1.2
var lifetime := 2.6
var dir := Vector2.RIGHT

var _age := 0.0
var _done := false


func _ready() -> void:
	collision_layer = 0
	collision_mask = CombatManager.HURTBOX_LAYER
	monitoring = true
	monitorable = false
	z_index = 9
	var shape := RectangleShape2D.new()
	shape.size = Vector2(80, 100)
	var col := CollisionShape2D.new()
	col.shape = shape
	add_child(col)
	target = CombatManager.find_enemy(source)
	Effects.trail(self, Color(1.0, 0.85, 0.35), 34.0, 14)


func _physics_process(delta: float) -> void:
	if _done:
		return
	if source != null and is_instance_valid(source) and source.is_time_frozen():
		return
	_age += delta
	if _age >= lifetime:
		_burst()
		return
	if is_instance_valid(target) and not target.is_dead and _age > 0.15:
		var to_t := target.global_position + Vector2(0, -64) - global_position
		var diff := wrapf(to_t.angle() - dir.angle(), -PI, PI)
		dir = dir.rotated(clampf(diff, -turn_rate * delta, turn_rate * delta))
	global_position += dir * speed * delta
	for area in get_overlapping_areas():
		var hb := area as Hurtbox
		if hb == null or hb.fighter.is_dead or (source != null and CombatManager.are_allies(source, hb.fighter)):
			continue
		var h := HitData.new()
		h.source = source
		h.damage = damage
		var dx := signf(dir.x)
		if dx == 0.0:
			dx = 1.0
		h.knockback = Vector2(dx * knockback.x, knockback.y)
		h.origin = global_position - dir * 50.0
		h.hit_type = "throne"
		h.move = "throne"
		h.damage_kind = HitData.KIND_EXPLOSION
		CombatManager.apply_hit(h, hb.fighter)
		_burst()
		return


func _burst() -> void:
	_done = true
	Effects.gold_burst(self, global_position, 90.0)
	queue_free()


func _process(_delta: float) -> void:
	queue_redraw()


func _draw() -> void:
	var s := Vector2(signf(dir.x) if dir.x != 0.0 else 1.0, 1.0)
	var wob := sin(_age * 10.0) * 0.08
	draw_set_transform(Vector2.ZERO, wob, s)
	# Speed lines behind
	for i in 3:
		var y := -30.0 + float(i) * 30.0
		draw_line(Vector2(-70, y), Vector2(-110 - float(i) * 12.0, y), Color(1, 0.9, 0.5, 0.6), 4.0)
	# High back with sun emblem
	var back := PackedVector2Array([Vector2(-40, 20), Vector2(-40, -42), Vector2(-30, -62), Vector2(-14, -70),
		Vector2(0, -60), Vector2(14, -70), Vector2(30, -62), Vector2(40, -42), Vector2(40, 20)])
	draw_colored_polygon(back, GOLD)
	draw_rect(Rect2(22, -50, 18, 70), GOLD_SHADE)
	_outline(back, 5.0)
	# Sun emblem: circle + rays
	var ec := Vector2(0, -30)
	for i in 12:
		var a := TAU * float(i) / 12.0
		draw_line(ec + Vector2.from_angle(a) * 10.0, ec + Vector2.from_angle(a) * 18.0, GOLD_SHADE, 3.0)
	draw_circle(ec, 10.0, BLACK)
	draw_circle(ec, 8.0, GOLD_HI)
	draw_circle(ec, 3.5, GOLD_SHADE)
	# Seat + cushion
	var seat := Rect2(-46, 18, 92, 16)
	draw_rect(seat, GOLD_SHADE)
	draw_rect(Rect2(-40, 8, 80, 12), CUSHION)
	draw_rect(Rect2(-40, 8, 80, 12), BLACK, false, 3.0)
	draw_rect(seat, BLACK, false, 4.0)
	# Legs
	for lx in [-40.0, 32.0]:
		draw_rect(Rect2(lx, 34, 8, 22), GOLD)
		draw_rect(Rect2(lx, 34, 8, 22), BLACK, false, 3.0)
	# Arm rests
	draw_rect(Rect2(-50, -6, 12, 26), GOLD)
	draw_rect(Rect2(-50, -6, 12, 26), BLACK, false, 3.0)
	draw_line(Vector2(-34, -38), Vector2(-34, 4), GOLD_HI, 3.0)
	draw_set_transform(Vector2.ZERO, 0.0, Vector2.ONE)


func _outline(pts: PackedVector2Array, w: float) -> void:
	var c := pts.duplicate()
	c.append(pts[0])
	draw_polyline(c, BLACK, w, true)
