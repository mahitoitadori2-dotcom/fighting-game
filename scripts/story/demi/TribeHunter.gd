class_name TribeHunter
extends ExtEnemy
## TRIBE HUNTER (DemiLand, the Tribe Village). A wiry primitive hunter: war paint, two feathers,
## a stone-tipped spear. Keeps his distance and throws.
##   Spear Throw   5 dmg   a spear flies at you
##   Spear Stab    5 dmg   a quick stab if you get close

const CFG := {"weapon": "spear", "feathers": 2, "metal": Color(0.55, 0.52, 0.48), "eye": Color(1.0, 0.85, 0.5)}


func _make_data() -> CharacterData:
	keep_min = 220.0
	keep_max = 520.0
	attack_chance = 0.6
	phase2_threshold = -1.0
	return SimpleEnemy.make_data("Tribe Hunter", 34, Vector2(56, 140), 190.0)


static func make_patterns() -> Array[EnemyPattern]:
	var list: Array[EnemyPattern] = []
	list.append(EnemyPattern.make("throw", "SPEAR THROW", 2.8, 5, 180.0, 850.0, "throw", 0.45, 0.2, 0.45, false, [2.0, 2.0]))
	list.append(EnemyPattern.make("stab", "SPEAR STAB", 1.8, 5, 0.0, 150.0, "stab", 0.30, 0.2, 0.35, false, [1.5, 1.5]))
	return list


func flavor_lines() -> Array[String]:
	return ["*clicks his tongue*", "HAA! HAA!", "*sniffs the air*", "Fresh meat walks."]


func _attack(p: EnemyPattern) -> void:
	match p.id:
		"throw":
			shot("arrow", Vector2(30, -110), 620.0, 1.6, Vector2(46, 12), dmg(p), Vector2(220, -120), Color(0.55, 0.40, 0.25), "spear_throw")
			SoundManager.play_sfx("whoosh", -6.0)
		"stab":
			melee(dmg(p), Vector2(260, -160), Vector2(60, -90), Vector2(110, 60), "spear_stab")


func draw_model_on(c: CanvasItem) -> void:
	DemiArt.tribal(c, art_state(), CFG)


static func draw_portrait(c: CanvasItem, t: float) -> void:
	DemiArt.tribal(c, {"t": t, "pose": "idle"}, CFG)
