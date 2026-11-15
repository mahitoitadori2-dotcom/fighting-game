class_name MasterKharleming
extends ExtEnemy
## MASTER KHARLEMING (Terra Craterum): a Full Kharleming with WINGS and a sac of VOID GOO.
## Its corpse can be DRAGGED like the others.
##   Bite        4 dmg   a snap of its mandibles
##   Goo Spit    3 dmg   spits a glob of Void Goo that leaves a goo pool (slows, weakens)
##   Wing Hop    5 dmg   a short buzzing flight that lands on you


func _make_data() -> CharacterData:
	keep_min = 140.0
	keep_max = 420.0
	attack_chance = 0.6
	phase2_threshold = -1.0
	return SimpleEnemy.make_data("Master Kharleming", 38, Vector2(90, 62), 250.0)


static func make_patterns() -> Array[EnemyPattern]:
	var list: Array[EnemyPattern] = []
	list.append(EnemyPattern.make("spit", "VOID GOO SPIT", 3.0, 3, 120.0, 620.0, "spit", 0.4, 0.2, 0.4, false, [1.8, 1.8]))
	list.append(EnemyPattern.make("bite", "BITE", 1.6, 4, 0.0, 100.0, "bite", 0.18, 0.15, 0.35, false, [1.2, 1.2]))
	list.append(EnemyPattern.make("hop", "WING HOP", 5.0, 5, 160.0, 520.0, "hop", 0.35, 0.8, 0.4, false, [1.0, 1.0]))
	return list


func flavor_lines() -> Array[String]:
	return ["*bzzzzzz*", "*the goo sac gurgles*", "*CLICK*"]


var _air := false


func _attack(p: EnemyPattern) -> void:
	match p.id:
		"spit":
			lob("chem_glob", Vector2(40, -40), target_x(), 0.8, dmg(p), Vector2(120, -120), 34.0, Kharleming.EYE.lerp(CraterArt.GOO, 0.8), "void_goo",
				func(pos: Vector2) -> void: pool_at(pos.x, 110.0, 4.0, "void"))
			SoundManager.play_sfx("void_goo", -6.0)
		"bite":
			melee(dmg(p), Vector2(180, -100), Vector2(52, -34), Vector2(70, 46), "master_kharleming_bite")
		"hop":
			var to := target_x() - global_position.x
			facing = 1 if to >= 0.0 else -1
			velocity = Vector2(clampf(to * 1.4, -520.0, 520.0), -620.0)
			_air = false
			melee(dmg(p), Vector2(220, -160), Vector2(0, -30), Vector2(96, 60), "master_kharleming_hop")
			SoundManager.play_sfx("whoosh", -8.0)


func _on_attack_update(p: EnemyPattern, _delta: float) -> void:
	if p.id != "hop":
		return
	if not is_on_floor():
		_air = true
	elif _air:
		state_time = state_len


func _owns_velocity_x() -> bool:
	return estate == EState.ATTACK and current != null and current.id == "hop"


func draw_model_on(c: CanvasItem) -> void:
	CraterArt.kharleming(c, art_state(), true)


static func draw_portrait(c: CanvasItem, t: float) -> void:
	CraterArt.kharleming(c, {"t": t, "pose": "idle"}, true)
