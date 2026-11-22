class_name AristocraticNightmare
extends ExtEnemy
## ARISTOCRATIC NIGHTMARE (The Hunt of a Nightmare): appears after you kill the Head Heavy Nightmare
## Guards. It FLOATS, and its main shade is NOT dark red like the others but a really, REALLY bright
## red. A high collar, a little top hat, a diamond mask.
##
##   Red Bolt     6 dmg   a bright red bolt of fire
##   Swoop        8 dmg   glides straight through you
##   Court Flare  7 dmg   a ring of bright red fire bursts around it

func _on_death() -> void:
	super._on_death()
	if StoryManager.active and not StoryManager.autoplay:
		Achievements.unlock("hunt_aristocrat")


func _make_data() -> CharacterData:
	keep_min = 140.0
	keep_max = 460.0
	attack_chance = 0.6
	return SimpleEnemy.make_data("Aristocratic Nightmare", 62, Vector2(50, 130), 260.0)


static func make_patterns() -> Array[EnemyPattern]:
	var list: Array[EnemyPattern] = []
	list.append(EnemyPattern.make("bolt", "RED BOLT", 2.4, 6, 140.0, 800.0, "cast", 0.35, 0.2, 0.4, false, [1.6, 1.8]))
	list.append(EnemyPattern.make("swoop", "SWOOP!", 4.0, 8, 0.0, 460.0, "swoop", 0.45, 0.5, 0.45, false, [1.2, 1.4]))
	list.append(EnemyPattern.make("flare", "COURT FLARE!", 5.5, 7, 0.0, 170.0, "flare", 0.55, 0.25, 0.5, true, [1.0, 1.3]))
	return list


func _attack(p: EnemyPattern) -> void:
	match p.id:
		"bolt":
			shot("fireball", Vector2(30, -110), 560.0, 1.6, Vector2(40, 34), dmg(p), Vector2(240, -160), HuntArt.BRIGHT, "aristo_bolt")
			SoundManager.play_sfx("flame", -6.0)
		"swoop":
			melee(dmg(p), Vector2(320, -220), Vector2(20, -70), Vector2(90, 90), "aristo_swoop")
			SoundManager.play_sfx("whoosh", -4.0)
		"flare":
			hit_in_radius(global_position + Vector2(0, -80), 170.0, dmg(p), Vector2(360, -260), "aristo_flare")
			Effects.hit_sparks(self, global_position + Vector2(0, -80), 14, 1.4)
			SoundManager.play_sfx("flame")


func _on_attack_update(p: EnemyPattern, _delta: float) -> void:
	if p.id == "swoop":
		dash_step(820.0)


func _owns_velocity_x() -> bool:
	return estate == EState.ATTACK and current != null and current.id == "swoop"


func draw_model_on(c: CanvasItem) -> void:
	draw_aristocrat(c, art_state())


static func draw_portrait(c: CanvasItem, t: float) -> void:
	draw_aristocrat(c, {"t": t})


static func draw_aristocrat(c: CanvasItem, s: Dictionary) -> void:
	var t: float = s.get("t", 0.0)
	var pose_v: String = s.get("pose", "idle")
	var arm := 1.0 if pose_v in ["cast", "swoop"] else (-0.4 if pose_v.ends_with("_tele") else 0.15)
	var pts := HuntArt.body(c, s, {"mask": "diamond", "float": true, "arm_f": arm, "arm_b": 0.3,
		"skin": HuntArt.BRIGHT, "skin_shade": HuntArt.BRIGHT_SHADE, "cloak": HuntArt.BRIGHT, "cloak_shade": HuntArt.BRIGHT_SHADE, "hood": false})
	var neck: Vector2 = pts["neck"]
	var head: Vector2 = pts["head"]
	# A high ruffled collar
	for i in 7:
		var a := PI + float(i) * PI / 6.0
		c.draw_colored_polygon(PackedVector2Array([neck + Vector2(0, 4), neck + Vector2.from_angle(a) * 20.0 + Vector2(0, 2), neck + Vector2.from_angle(a + 0.25) * 16.0]), Color(1.0, 0.85, 0.85))
	# A small top hat, tilted
	var hb := head + Vector2(2, -13)
	var hat := PackedVector2Array([hb + Vector2(-9, 0), hb + Vector2(9, -2), hb + Vector2(8, -22), hb + Vector2(-8, -20)])
	c.draw_colored_polygon(hat, Color(0.10, 0.02, 0.03))
	FighterArt.outline(c, hat, 2.0)
	c.draw_line(hb + Vector2(-14, 1), hb + Vector2(14, -2), HuntArt.BLACK, 4.0)
	c.draw_line(hb + Vector2(-8, -4), hb + Vector2(8, -6), HuntArt.BRIGHT, 3.0)
	if pose_v == "flare" or pose_v == "flare_tele":
		c.draw_arc(Vector2(0, -80), 60.0 + 30.0 * sin(t * 20.0), 0.0, TAU, 24, Color(1.0, 0.2, 0.15, 0.6), 4.0)
