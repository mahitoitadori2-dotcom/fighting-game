class_name LavaGoblin
extends ExtEnemy
## LAVA GOBLIN (Terra Craterum): small, quick, throws magma bombs from a distance.
##   Magma Bomb   4 dmg   a lobbed bomb that leaves a little lava
##   Poke         3 dmg   a quick jab if you get close


func _make_data() -> CharacterData:
	keep_min = 160.0
	keep_max = 460.0
	attack_chance = 0.6
	phase2_threshold = -1.0
	return SimpleEnemy.make_data("Lava Goblin", 22, Vector2(44, 80), 270.0)


static func make_patterns() -> Array[EnemyPattern]:
	var list: Array[EnemyPattern] = []
	list.append(EnemyPattern.make("throw", "MAGMA BOMB", 2.6, 4, 140.0, 650.0, "throw", 0.4, 0.2, 0.4, false, [1.8, 1.8]))
	list.append(EnemyPattern.make("poke", "POKE", 1.4, 3, 0.0, 90.0, "poke", 0.2, 0.15, 0.3, false, [1.2, 1.2]))
	return list


func flavor_lines() -> Array[String]:
	return ["Hee hee hee!", "*juggles a hot rock*", "Mine! MINE!"]


func _attack(p: EnemyPattern) -> void:
	match p.id:
		"throw":
			lob("magma", Vector2(16, -84), target_x(), 0.75, dmg(p), Vector2(160, -180), 30.0, Color(1, 0.5, 0.1), "goblin_bomb",
				func(pos: Vector2) -> void: pool_at(pos.x, 70.0, 2.0, "fire"))
		"poke":
			melee(dmg(p), Vector2(160, -100), Vector2(34, -40), Vector2(60, 40), "goblin_poke")


func draw_model_on(c: CanvasItem) -> void:
	CraterArt.goblin(c, art_state())


static func draw_portrait(c: CanvasItem, t: float) -> void:
	CraterArt.goblin(c, {"t": t, "pose": "idle"})
