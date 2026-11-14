class_name VoidFog
extends Node2D
## Void Arena FOREGROUND layer (world space, drawn in front of the fighters):
## low green fog rolling along the island surface + sparks drifting upward.
## Kept faint so it never hides the fight. Place it at the ArenaGround position.

@export var width := 2800.0
@export var fog_height := 70.0
@export var spark_count := 50
@export var seed_value := 7

const FOG := Color(0.30, 0.85, 0.38)
const SPARK := Color(0.70, 1.0, 0.60)

var _t := 0.0
var _blobs: Array[Vector3] = []     # x, radius, speed
var _sparks: Array[Vector4] = []    # x, y, speed, phase


func _ready() -> void:
	z_index = 20
	var rng := RandomNumberGenerator.new()
	rng.seed = seed_value
	for i in int(width / 90.0):
		_blobs.append(Vector3(rng.randf_range(-width * 0.5, width * 0.5), rng.randf_range(40.0, 90.0), rng.randf_range(10.0, 30.0)))
	for i in spark_count:
		_sparks.append(Vector4(rng.randf_range(-width * 0.5, width * 0.5), rng.randf_range(0.0, 1.0), rng.randf_range(0.08, 0.2), rng.randf() * TAU))


func _process(delta: float) -> void:
	_t += delta
	queue_redraw()


func _draw() -> void:
	var hw := width * 0.5
	# Fog blobs hugging the floor (y = 0 is the walkable surface)
	for b in _blobs:
		var x := fposmod(b.x + _t * b.z + hw, width) - hw
		var bob := sin(_t * 0.7 + b.x) * 6.0                # (Dots: batched into one draw call)
		Dots.circle(self, Vector2(x, -b.y * 0.25 + bob), b.y, Color(FOG.r, FOG.g, FOG.b, 0.06))
		Dots.circle(self, Vector2(x + b.y * 0.5, -b.y * 0.1 + bob), b.y * 0.7, Color(FOG.r, FOG.g, FOG.b, 0.05))
	# Sparks rising from the ground
	for s in _sparks:
		var life := fposmod(s.y + _t * s.z, 1.0)
		var p := Vector2(s.x + sin(_t * 1.5 + s.w) * 14.0, -life * 360.0)
		var a := sin(life * PI) * (0.6 + 0.4 * sin(_t * 9.0 + s.w))
		Dots.circle(self, p, 5.0, Color(FOG.r, FOG.g, FOG.b, 0.18 * a))
		Dots.circle(self, p, 1.8, Color(SPARK.r, SPARK.g, SPARK.b, a))
