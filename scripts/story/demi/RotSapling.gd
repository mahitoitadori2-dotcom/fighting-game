class_name RotSapling
extends ExtEnemy
## ROT SAPLING (DemiLand, the Dead Grove). A little rotten tree that hops on its roots and spits
## seeds. Weak alone, annoying in a group.
##   Hop Bite    4 dmg   hops at you
##   Seed Spit   4 dmg   spits a hard seed

const CFG := {"h": 0.5, "branches": 2, "eye": Color(0.7, 1.0, 0.4)}

var _leaping := false


func _make_data() -> CharacterData:
	keep_min = 100.0
	keep_max = 360.0
	attack_chance = 0.6
	phase2_threshold = -1.0
	return SimpleEnemy.make_data("Rot Sapling", 22, Vector2(44, 80), 200.0)


static func make_patterns() -> Array[EnemyPattern]:
	var list: Array[EnemyPattern] = []
	list.append(EnemyPattern.make("hop", "HOP BITE", 2.4, 4, 60.0, 360.0, "hop", 0.30, 0.5, 0.4, false, [1.6, 1.6]))
	list.append(EnemyPattern.make("spit", "SEED SPIT", 2.2, 4, 120.0, 700.0, "spit", 0.35, 0.2, 0.4, false, [2.0, 2.0]))
	return list


func _owns_velocity_x() -> bool:
	return _leaping


func _attack(p: EnemyPattern) -> void:
	match p.id:
		"hop":
			_leaping = true
			velocity = Vector2(float(facing) * clampf(absf(target_x() - global_position.x) * 1.4, 200.0, 520.0), -420.0)
			melee(dmg(p), Vector2(180, -160), Vector2(26, -40), Vector2(60, 60), "hop_bite")
		"spit":
			shot("light_orb", Vector2(20, -60), 480.0, 1.6, Vector2(18, 18), dmg(p), Vector2(160, -120), Color(0.45, 0.35, 0.15), "seed_spit")


func _on_attack_end(p: EnemyPattern) -> void:
	if p.id == "hop":
		_leaping = false


func draw_model_on(c: CanvasItem) -> void:
	DemiArt.treant(c, art_state(), CFG)


static func draw_portrait(c: CanvasItem, t: float) -> void:
	DemiArt.treant(c, {"t": t, "pose": "idle"}, CFG)
