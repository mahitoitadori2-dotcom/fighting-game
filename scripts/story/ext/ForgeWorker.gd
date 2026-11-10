class_name ForgeWorker
extends ExtEnemy
## FORGE WORKER (FM2, The Forge). A sooty smith of the Forge: leather apron, goggles, a heavy
## forge hammer, buckets of HOT METAL.
##   Hammer Swing     6 dmg   a heavy swing
##   Hot Metal Throw  5 dmg   lobs molten metal: it splashes into a small fire pool

const HOT := Color(1.0, 0.55, 0.15)
const CFG := {"head": "worker", "skin": Color(0.70, 0.52, 0.42), "cloth": Color(0.40, 0.28, 0.18),
	"cloth_hi": Color(0.55, 0.40, 0.26), "trim": Color(0.25, 0.22, 0.22), "eye": Color(1.0, 0.6, 0.2),
	"weapon": "hammer", "metal": Color(0.35, 0.34, 0.36)}


func _make_data() -> CharacterData:
	keep_min = 0.0
	keep_max = 220.0
	attack_chance = 0.65
	phase2_threshold = -1.0
	return SimpleEnemy.make_data("Forge Worker", 32, Vector2(62, 140), 170.0)


static func make_patterns() -> Array[EnemyPattern]:
	var list: Array[EnemyPattern] = []
	list.append(EnemyPattern.make("hammer", "HAMMER SWING", 2.0, 6, 0.0, 120.0, "hammer", 0.45, 0.2, 0.45, false, [2.0, 2.0]))
	list.append(EnemyPattern.make("throw", "HOT METAL!", 3.8, 5, 140.0, 620.0, "throw", 0.5, 0.2, 0.4, true, [1.5, 1.5]))
	list[1].note = "leaves a small fire pool"
	return list


func flavor_lines() -> Array[String]:
	return ["Back to work!", "*clang clang*", "The Forge needs more metal..."]


func _attack(p: EnemyPattern) -> void:
	match p.id:
		"hammer":
			melee(dmg(p), Vector2(280, -260), Vector2(56, -70), Vector2(100, 110), "forge_hammer")
			Effects.hit_sparks(self, global_position + Vector2(facing * 70.0, -20.0), 6, 1.0)
			SoundManager.play_sfx("slam", -6.0)
		"throw":
			lob("magma", Vector2(20, -120), clamp_to_ground(target_x(), 40.0), 0.75, dmg(p), Vector2(160, -160), 42.0, HOT, "hot_metal",
				func(pos: Vector2) -> void: pool_at(pos.x, 90.0, 2.5, "fire"))
			SoundManager.play_sfx("swing", -6.0)


func draw_model_on(c: CanvasItem) -> void:
	ExtArt.humanoid(c, art_state(), CFG)


static func draw_portrait(c: CanvasItem, t: float) -> void:
	ExtArt.humanoid(c, {"t": t, "pose": "idle"}, CFG)
