class_name LavaDemon
extends ExtEnemy
## LAVA DEMON (Terra Craterum): a horned demon of magma skin. Fast, aggressive.
##   Molten Claws  5 dmg   two quick slashes
##   Fire Spit     5 dmg   a fireball straight at you


func _make_data() -> CharacterData:
	keep_min = 0.0
	keep_max = 380.0
	attack_chance = 0.65
	phase2_threshold = -1.0
	return SimpleEnemy.make_data("Lava Demon", 44, Vector2(60, 130), 240.0)


static func make_patterns() -> Array[EnemyPattern]:
	var list: Array[EnemyPattern] = []
	list.append(EnemyPattern.make("claw", "MOLTEN CLAWS", 1.8, 5, 0.0, 130.0, "claw", 0.25, 0.25, 0.35, false, [1.6, 1.6]))
	list.append(EnemyPattern.make("spit", "FIRE SPIT", 3.2, 5, 160.0, 700.0, "spit", 0.4, 0.2, 0.4, false, [1.4, 1.4]))
	return list


func flavor_lines() -> Array[String]:
	return ["*hisses like a kettle*", "Burn... BURN...", "*drip... sizzle*"]


func _attack(p: EnemyPattern) -> void:
	match p.id:
		"claw":
			melee(dmg(p), Vector2(260, -180), Vector2(56, -80), Vector2(90, 70), "demon_claw")
			SoundManager.play_sfx("sword_slash", -6.0)
		"spit":
			shot("fireball", Vector2(30, -112), 560.0, 1.4, Vector2(34, 22), dmg(p), Vector2(200, -150), Color(1, 0.5, 0.1), "demon_spit")
			SoundManager.play_sfx("flame", -8.0)


func draw_model_on(c: CanvasItem) -> void:
	CraterArt.demon(c, art_state())


static func draw_portrait(c: CanvasItem, t: float) -> void:
	CraterArt.demon(c, {"t": t, "pose": "idle"})
