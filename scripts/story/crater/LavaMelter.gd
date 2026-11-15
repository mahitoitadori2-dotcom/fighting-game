class_name LavaMelter
extends C5Boss
## THE LAVA MELTER - first boss of Terra Craterum: a GIANT PILLAR OF LAVA with plates of rock
## and two ROCK EYES. It never moves: it rises out of the magma in front of the Basalt Wall and
## spits lava and rocks at you. Killing it drains the magma that hid the wall.
##
##   Lava Spit      6 dmg   three globs of lava that leave burning pools
##   Rock Rain      7 dmg   rocks tear loose from the cavern roof and fall where you stand
##   Magma Wave     6 dmg   a wave of lava rolls out along the floor, both ways
##   Rock Spit      7 dmg   a boulder spat straight at you
##   Eruption       8 dmg   ENRAGED: geysers of magma burst out of the floor in a row


func boss_forms() -> Array:
	return [{"name": "The Lava Melter", "title": "THE LAVA MELTER", "hp": 360, "body": Vector2(220, 380), "speed": 0.0}]


func setup_boss() -> void:
	keep_min = 0.0
	keep_max = 2000.0
	attack_chance = 0.7
	art_scale = 1.0
	chain_chance = 0.35
	grab_immune = true
	knockback_scale = 0.0
	tags = {"spit": ["ranged"], "rain": ["ranged", "anti_air"], "wave": ["close", "counter"], "boulder": ["ranged"], "erupt": ["ranged"]}
	combos = {"spit": ["rain"], "wave": ["boulder"], "rain": ["spit", "wave"]}


static func make_patterns() -> Array[EnemyPattern]:
	var list: Array[EnemyPattern] = []
	#                          id        name            cd    dmg  min    max     anim     tele  active rec   big   weights armored
	list.append(EnemyPattern.make("spit", "LAVA SPIT!", 3.4, 6, 0.0, 2000.0, "spit", 0.55, 0.4, 0.5, true, [1.8], true))
	list.append(EnemyPattern.make("rain", "ROCK RAIN!", 5.0, 7, 0.0, 2000.0, "rocks", 0.6, 0.4, 0.5, true, [1.5], true))
	list.append(EnemyPattern.make("wave", "MAGMA WAVE!", 5.5, 6, 0.0, 600.0, "spit", 0.6, 0.4, 0.5, true, [1.4], true))
	list.append(EnemyPattern.make("boulder", "ROCK SPIT!", 3.0, 7, 200.0, 2000.0, "rocks", 0.45, 0.3, 0.45, false, [1.3], true))
	list.append(EnemyPattern.make("erupt", "ERUPTION!", 9.0, 8, 0.0, 2000.0, "spit", 0.8, 0.6, 0.7, true, [1.6], true))
	list[4].note = "enraged only"
	return list


func wants_pattern(p: EnemyPattern) -> bool:
	return p.id != "erupt" or raging


func flavor_lines() -> Array[String]:
	return ["*BLORP*", "*the rock eyes turn to you*", "*it hisses and steams*"]


func _attack(p: EnemyPattern) -> void:
	var mouth := global_position + Vector2(facing * 30.0, -210.0)
	match p.id:
		"spit":
			for i in 3:
				var tx := target_x() + float(i - 1) * 140.0
				lob("magma", mouth, tx, 0.9 + float(i) * 0.12, dmg(p), Vector2(200, -260), 46.0, Color(1, 0.5, 0.1), "melter_spit",
					func(pos: Vector2) -> void: ChemicalPool.spawn_lava(self, Vector2(pos.x, floor_y()), 120.0, 3.5))
			SoundManager.play_sfx("geyser", -4.0)
		"rain":
			for i in 4:
				hazard("rock", target_x() + float(i - 1.5) * 150.0, 0.7 + float(i) * 0.15, dmg(p))
			Effects.shake(self, 8.0)
			SoundManager.play_sfx("rumble")
		"wave":
			for d: float in [-1.0, 1.0]:
				shoot("lava_wave", Vector2(global_position.x + d * 120.0, floor_y() - 26.0), d, 460.0, 2.2, Vector2(70, 52), dmg(p),
					Vector2(260, -300), Color(1, 0.5, 0.1), "melter_wave", true)
			SoundManager.play_sfx("splash")
		"boulder":
			face_target()
			shoot("boulder", mouth, float(facing), 620.0, 2.0, Vector2(46, 46), dmg(p), Vector2(360, -220), Color.WHITE, "melter_boulder")
			SoundManager.play_sfx("stone")
		"erupt":
			var x0 := target_x()
			for i in 6:
				hazard("geyser", x0 + float(i - 3) * 130.0, 0.5 + float(i) * 0.12, dmg(p))
			Effects.shake(self, 12.0)
			SoundManager.play_sfx("roar", -4.0)


func _owns_velocity_x() -> bool:
	return true                                                   # Rooted: a pillar does not walk


func _physics_process(delta: float) -> void:
	velocity.x = 0.0
	super._physics_process(delta)


func draw_model_on(c: CanvasItem) -> void:
	CraterArt.melter(c, art_state())


static func draw_portrait(c: CanvasItem, t: float) -> void:
	CraterArt.melter(c, {"t": t, "pose": "idle"})
