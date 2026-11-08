class_name NightmareHeart
extends Node2D
## The Ritual of the Troupe: a dark red Nightmare Heart appears, pulses and grows,
## then EXPLODES: big area damage + knockback, and flings flames, bats and oil
## everywhere. Spawned and configured by FireLord.

const RED := Color(0.391, 0.0, 0.0, 1.0)
const HEART := Color(0.326, 0.0, 0.02, 1.0)
const HEART_HI := Color(0.986, 0.141, 0.171, 1.0)

var source: FireLord
var grow_time := 1.3
var radius := 290.0
var damage := 22
var knockback := Vector2(700, -480)
var flame_count := 14
var bat_count := 6
var oil_count := 4
var oil_spread := 430.0
var bonus := 0                       # Passive bonus captured when cast
var move := "ritual"

var _age := 0.0
var _exploded := false


func _ready() -> void:
	add_to_group("nightmare_heart")
	z_index = 12


func _physics_process(delta: float) -> void:
	if _exploded:
		return
	if source != null and is_instance_valid(source) and source.is_time_frozen():
		return
	_age += delta
	if _age >= grow_time:
		_explode()


func _explode() -> void:
	_exploded = true
	Effects.red_burst(self, global_position, radius * 0.9)
	Effects.red_burst(self, global_position, radius * 0.5)
	var src: Fighter = source if is_instance_valid(source) else null
	# Area damage
	for n in get_tree().get_nodes_in_group("fighters"):
		var f := n as Fighter
		if f == null or f == src or f.is_dead:
			continue
		if (f.global_position + Vector2(0, -64)).distance_to(global_position) > radius + 32.0:
			continue
		var dx := signf(f.global_position.x - global_position.x)
		if dx == 0.0:
			dx = 1.0
		var h := HitData.new()
		h.source = src
		h.damage = damage
		h.knockback = Vector2(dx * knockback.x, knockback.y)
		h.origin = global_position
		h.hit_type = "fire"
		h.move = move
		h.damage_kind = HitData.KIND_EXPLOSION      # The heart blast is an explosion
		CombatManager.apply_hit(h, f)
	if src != null:
		var fl := src as FireLord
		# Flames everywhere
		for i in flame_count:
			fl.spawn_flame(global_position, Vector2.from_angle(TAU * float(i) / float(flame_count)), move, bonus)
		# Bats everywhere
		for i in bat_count:
			var a := TAU * (float(i) + 0.5) / float(bat_count)
			fl.spawn_bat(global_position, Vector2.from_angle(a), move, bonus)
		# Oil splashed around
		for i in oil_count:
			var x := global_position.x + lerpf(-oil_spread, oil_spread, (float(i) + 0.5) / float(oil_count))
			fl.spawn_oil(x, 160.0, move, bonus)
	queue_free()


func _process(_delta: float) -> void:
	queue_redraw()


func _draw() -> void:
	var k := clampf(_age / grow_time, 0.0, 1.0)
	var beat := 1.0 + 0.12 * absf(sin(_age * (6.0 + 10.0 * k)))
	var s := (0.35 + 0.85 * k) * beat
	# Aura
	draw_circle(Vector2.ZERO, 70.0 * s, Color(RED.r, 0.0, 0.0, 0.18 + 0.2 * k))
	# Heart shape (two lobes + point)
	var pts := PackedVector2Array()
	for i in 40:
		var t := TAU * float(i) / 40.0
		var x := 16.0 * pow(sin(t), 3.0)
		var y := -(13.0 * cos(t) - 5.0 * cos(2.0 * t) - 2.0 * cos(3.0 * t) - cos(4.0 * t))
		pts.append(Vector2(x, y) * 2.6 * s)
	draw_colored_polygon(pts, HEART)
	draw_circle(Vector2(-14, -12) * s, 9.0 * s, HEART_HI)
	var closed := pts.duplicate()
	closed.append(pts[0])
	draw_polyline(closed, Color(0, 0, 0), 4.0, true)
	# Veins
	draw_polyline(PackedVector2Array([Vector2(0, -20) * s, Vector2(6, -2) * s, Vector2(-4, 14) * s, Vector2(2, 30) * s]), RED, 3.0, true)
	draw_polyline(PackedVector2Array([Vector2(-20, -10) * s, Vector2(-10, 4) * s, Vector2(-16, 18) * s]), RED, 2.0, true)
	# Warning ring shows the blast radius
	draw_arc(Vector2.ZERO, radius * k, 0.0, TAU, 64, Color(1.0, 0.0, 0.0, 0.25 + 0.35 * k), 3.0, true)
