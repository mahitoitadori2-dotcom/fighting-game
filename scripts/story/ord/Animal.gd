class_name Animal
extends SimpleEnemy
## A real-life ANIMAL of Terra Ordinariorum. They NEVER attack (the user's rule) and are REALLY
## weak: 1-2 hits. They graze and wander; when you come close they run away.
## Set `kind` before adding it to the tree.

const KINDS := {
	# kind: [name, hp, body, speed]
	"rabbit": ["Rabbit", 3, Vector2(30, 30), 330.0], "sheep": ["Sheep", 6, Vector2(56, 56), 190.0],
	"cow": ["Cow", 8, Vector2(80, 70), 160.0], "deer": ["Deer", 6, Vector2(56, 74), 360.0],
	"fox": ["Fox", 4, Vector2(44, 36), 340.0], "boar": ["Boar", 7, Vector2(60, 50), 240.0],
	"monkey": ["Monkey", 4, Vector2(30, 56), 320.0], "parrot": ["Parrot", 2, Vector2(30, 36), 260.0],
	"frog": ["Frog", 2, Vector2(28, 24), 200.0], "chicken": ["Chicken", 2, Vector2(30, 40), 220.0],
	"dog": ["Dog", 5, Vector2(48, 44), 320.0], "cat": ["Cat", 3, Vector2(36, 32), 340.0],
	"lizard": ["Lizard", 2, Vector2(50, 14), 300.0], "scorpion": ["Scorpion", 2, Vector2(40, 20), 200.0],
	"fennec": ["Fennec Fox", 3, Vector2(34, 30), 360.0], "goat": ["Goat", 6, Vector2(48, 50), 280.0],
	"marmot": ["Marmot", 3, Vector2(32, 28), 260.0], "eagle": ["Eagle", 4, Vector2(40, 50), 280.0],
}

var kind := "rabbit"


func _make_data() -> CharacterData:
	var k: Array = KINDS.get(kind, KINDS["rabbit"])
	keep_min = 0.0
	keep_max = 9999.0
	attack_chance = 0.0
	phase2_threshold = -1.0
	var d := SimpleEnemy.make_data(String(k[0]), int(k[1]), k[2], float(k[3]))
	return d


static func make_patterns() -> Array[EnemyPattern]:
	return []


func _make_brain() -> EnemyAI:
	return AnimalAI.new()


func draw_model_on(c: CanvasItem) -> void:
	OrdArt.animal(c, kind, art_state())


static func draw_portrait(c: CanvasItem, t: float) -> void:
	OrdArt.animal(c, "deer", {"t": t})


## Graze, wander a little, and RUN when you come close.
class AnimalAI extends EnemyAI:
	var _wander := 0.0

	func think() -> void:
		if not e.can_act():
			return
		if target != null and dist < 330.0:
			e.move_dir = -dir                                   # Flee
			e.facing = -int(dir) if dir != 0.0 else e.facing
			if dist < 140.0 and e.is_on_floor() and chance(0.2):
				e.jump()
			return
		_wander -= 0.25
		if _wander <= 0.0:
			_wander = randf_range(1.0, 3.0)
			e.move_dir = 0.0 if chance(0.55) else (1.0 if chance(0.5) else -1.0)
		e.move_dir *= 0.4 if absf(e.move_dir) > 0.0 else 1.0
