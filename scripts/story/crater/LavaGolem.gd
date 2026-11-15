class_name LavaGolem
extends ExtEnemy
## LAVA GOLEM (Terra Craterum): a slow mountain of black basalt with a magma core. Tough.
##   Ground Slam   8 dmg   both fists into the ground: hits around it + a lava pool
##   Magma Hurl    6 dmg   throws a glob of magma that leaves burning lava


func _make_data() -> CharacterData:
	keep_min = 0.0
	keep_max = 260.0
	attack_chance = 0.5
	phase2_threshold = -1.0
	knockback_scale = 0.35
	return SimpleEnemy.make_data("Lava Golem", 70, Vector2(100, 150), 110.0)


static func make_patterns() -> Array[EnemyPattern]:
	var list: Array[EnemyPattern] = []
	list.append(EnemyPattern.make("slam", "GROUND SLAM", 4.0, 8, 0.0, 170.0, "slam", 0.65, 0.25, 0.6, true, [1.6, 1.6]))
	list.append(EnemyPattern.make("hurl", "MAGMA HURL", 4.5, 6, 200.0, 700.0, "throw", 0.55, 0.3, 0.5, false, [1.2, 1.2]))
	return list


func flavor_lines() -> Array[String]:
	return ["*rumble*", "*stone grinds on stone*"]


func _attack(p: EnemyPattern) -> void:
	match p.id:
		"slam":
			melee(dmg(p), Vector2(260, -360), Vector2(70, -40), Vector2(200, 90), "golem_slam")
			pool_at(global_position.x + facing * 90.0, 140.0, 3.0, "fire")
			Effects.shake(self, 9.0)
			SoundManager.play_sfx("slam")
		"hurl":
			var tx := target_x()
			lob("magma", Vector2(50, -150), tx, 0.9, dmg(p), Vector2(180, -200), 40.0, Color(1, 0.5, 0.1), "magma_hurl",
				func(pos: Vector2) -> void: pool_at(pos.x, 110.0, 3.0, "fire"))
			SoundManager.play_sfx("geyser", -8.0)


func draw_model_on(c: CanvasItem) -> void:
	CraterArt.golem(c, art_state())


static func draw_portrait(c: CanvasItem, t: float) -> void:
	CraterArt.golem(c, {"t": t, "pose": "idle"})
