class_name RoadFolk
extends Node2D
## THE LAST STRETCH: the PEOPLE and ANIMALS who live along the road (levels with "folk"). They are
## scenery, not fighters: they stroll back and forth behind the fight, stop to look around, and
## nobody can hit them. Travellers, farmers, children, and sheep, cows, chickens, dogs, goats...
## Drawn behind the fighters (z_index -1), a little darker so they read as background.

const HUMANS := 4
const ANIMALS := ["sheep", "cow", "chicken", "dog", "goat", "rabbit", "deer", "fox"]

var left_x := -800.0
var right_x := 800.0
var floor_y := 0.0
var _walkers: Array = []                  # [x, dir, speed, pause, kind, look, t, scale]


## Adds the folk for a level to `host` (the StoryManager), between left and right on the floor.
static func spawn(host: Node, left: float, right: float, ground_y: float, seed_v: int) -> RoadFolk:
	var f := RoadFolk.new()
	f.name = "RoadFolk"
	f.left_x = left
	f.right_x = right
	f.floor_y = ground_y
	f.z_index = -1
	f.modulate = Color(0.78, 0.78, 0.80)
	var rng := RandomNumberGenerator.new()
	rng.seed = seed_v
	for i in HUMANS:
		f._walkers.append([rng.randf_range(left, right), 1.0 if rng.randf() < 0.5 else -1.0, rng.randf_range(40.0, 70.0),
			rng.randf_range(0.0, 3.0), "human", rng.randi_range(0, 5), rng.randf() * 10.0, 0.62])
	for i in 4:
		f._walkers.append([rng.randf_range(left, right), 1.0 if rng.randf() < 0.5 else -1.0, rng.randf_range(30.0, 80.0),
			rng.randf_range(0.0, 3.0), ANIMALS[rng.randi_range(0, ANIMALS.size() - 1)], 0, rng.randf() * 10.0, 0.7])
	host.add_child(f)
	return f


func _process(delta: float) -> void:
	for w: Array in _walkers:
		w[6] = float(w[6]) + delta
		if float(w[3]) > 0.0:                               # Standing still for a moment
			w[3] = float(w[3]) - delta
			continue
		w[0] = float(w[0]) + float(w[1]) * float(w[2]) * delta
		if float(w[0]) < left_x or float(w[0]) > right_x:
			w[1] = -float(w[1])
			w[0] = clampf(float(w[0]), left_x, right_x)
		if randf() < delta * 0.25:                          # Now and then: stop and look around
			w[3] = randf_range(1.0, 3.5)
			if randf() < 0.4:
				w[1] = -float(w[1])
	if GraphicsSettings.bg_should_redraw():
		queue_redraw()


func _draw() -> void:
	for w: Array in _walkers:
		var moving := float(w[3]) <= 0.0
		var s := float(w[7])
		var bob := absf(sin(float(w[6]) * 9.0)) * 2.0 if moving and String(w[4]) == "human" else 0.0
		draw_set_transform(Vector2(float(w[0]), floor_y - bob), 0.0, Vector2(float(w[1]) * s, s))
		if String(w[4]) == "human":
			OrdArt.villager(self, int(w[5]), float(w[6]))
		else:
			OrdArt.animal(self, String(w[4]), {"t": float(w[6]), "moving": moving, "pose": "walk" if moving else "idle"})
	draw_set_transform(Vector2.ZERO, 0.0, Vector2.ONE)
