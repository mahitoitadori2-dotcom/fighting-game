class_name HuskTreant
extends ExtEnemy
## HUSK (DemiLand, the Dead Grove). A dead tree that got up and walked. Slow, tough.
##   Branch Sweep   7 dmg   a wide swing of its branches
##   Root Spike     6 dmg   roots burst out of the ground under you (watch the crack)

const CFG := {"h": 1.0, "branches": 3}


func _make_data() -> CharacterData:
	keep_min = 0.0
	keep_max = 150.0
	attack_chance = 0.55
	phase2_threshold = -1.0
	knockback_scale = 0.5
	return SimpleEnemy.make_data("Husk", 60, Vector2(70, 160), 90.0)


static func make_patterns() -> Array[EnemyPattern]:
	var list: Array[EnemyPattern] = []
	list.append(EnemyPattern.make("sweep", "BRANCH SWEEP", 2.6, 7, 0.0, 200.0, "sweep", 0.55, 0.25, 0.5, false, [2.0, 2.0], true))
	list.append(EnemyPattern.make("roots", "ROOT SPIKE", 4.5, 6, 150.0, 800.0, "slam", 0.5, 0.2, 0.5, true, [1.4, 1.4]))
	list[1].note = "roots burst under you"
	return list


func flavor_lines() -> Array[String]:
	return ["*creaks*", "*bark cracks*", "...", "*leaves that aren't there rustle*"]


func _attack(p: EnemyPattern) -> void:
	match p.id:
		"sweep":
			melee(dmg(p), Vector2(320, -220), Vector2(70, -100), Vector2(170, 120), "branch_sweep")
			SoundManager.play_sfx("whoosh", -4.0)
		"roots":
			BossHazard.spawn(self, "tendril", Vector2(clamp_to_ground(target_x(), 40.0), global_position.y), 0.7, dmg(p), Vector2(160, -380))
			SoundManager.play_sfx("rumble", -8.0)


func draw_model_on(c: CanvasItem) -> void:
	DemiArt.treant(c, art_state(), CFG)


static func draw_portrait(c: CanvasItem, t: float) -> void:
	DemiArt.treant(c, {"t": t, "pose": "idle"}, CFG)
