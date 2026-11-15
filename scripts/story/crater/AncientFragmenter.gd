class_name AncientFragmenter
extends ExtEnemy
## ANCIENT FRAGMENTER (Terra Craterum): rusted hull plates of the crashed Kharleming ship,
## still orbiting an old cyan engine cell. Floats, flings its plates, falls apart and comes back.
##   Fragment Burst  4 dmg x3   three hull plates fly at you
##   Reassemble      -          falls apart and rebuilds itself somewhere else nearby


func _make_data() -> CharacterData:
	keep_min = 200.0
	keep_max = 480.0
	attack_chance = 0.55
	phase2_threshold = -1.0
	return SimpleEnemy.make_data("Ancient Fragmenter", 38, Vector2(60, 110), 150.0)


static func make_patterns() -> Array[EnemyPattern]:
	var list: Array[EnemyPattern] = []
	list.append(EnemyPattern.make("burst", "FRAGMENT BURST", 3.0, 4, 150.0, 750.0, "burst", 0.5, 0.3, 0.45, false, [1.6, 1.6]))
	list.append(EnemyPattern.make("reform", "REASSEMBLE", 6.0, 0, 0.0, 200.0, "burst", 0.3, 0.2, 0.3, false, [1.0, 1.0]))
	return list


func flavor_lines() -> Array[String]:
	return ["*an old alarm beeps*", "*metal scrapes on metal*", "*a voice in a dead language*"]


func _attack(p: EnemyPattern) -> void:
	match p.id:
		"burst":
			for i in 3:
				shot("scrap", Vector2(20, -100 + float(i) * 24.0), 480.0 + float(i) * 40.0, 1.5, Vector2(30, 20), dmg(p), Vector2(160, -120),
					Color(0.6, 0.62, 0.66), "fragment_burst")
			SoundManager.play_sfx("chain", -8.0)
		"reform":
			blink_to(target_x() + (randf_range(-1.0, 1.0) * 320.0))
			Effects.hit_sparks(self, global_position + Vector2(0, -70), 10, 1.0)


func draw_model_on(c: CanvasItem) -> void:
	CraterArt.fragmenter(c, art_state())


static func draw_portrait(c: CanvasItem, t: float) -> void:
	CraterArt.fragmenter(c, {"t": t, "pose": "idle"})
