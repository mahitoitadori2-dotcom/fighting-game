class_name StormHand
extends C5Boss
## THE STORM HAND - the boss at the end of level 80 (THE STORM ATTACKS). Inside the mountain, the
## Storm reaches down after you with its whole HAND. You fight it with the other hero AND the
## Trainer at your side.
##
##   Palm Slam     9 dmg   it lifts (shadow), then slams its open palm down where you stand
##   Sweep         8 dmg   the fingers drag along the floor - JUMP them
##   Fist          10 dmg  a closed fist pounds the ground: a shockwave rolls out both ways
##   Finger Zap    7 dmg   lightning from the fingertips strikes down in a row
##   Debris        6 dmg   ENRAGED: rocks rain from the cave roof

func boss_forms() -> Array:
	return [{"name": "The Storm Hand", "title": "THE STORM HAND", "hp": 720, "body": Vector2(200, 230), "speed": 170.0}]


func setup_boss() -> void:
	keep_min = 80.0
	keep_max = 500.0
	attack_chance = 0.72
	art_scale = 1.0
	chain_chance = 0.3
	grab_immune = true
	knockback_scale = 0.0
	tags = {"slam": ["close", "anti_air"], "sweep": ["close", "counter"], "fist": ["close"], "zap": ["ranged"], "debris": ["ranged", "anti_air"]}
	combos = {"slam": ["sweep"], "zap": ["slam"], "fist": ["zap"]}


static func make_patterns() -> Array[EnemyPattern]:
	var list: Array[EnemyPattern] = []
	#                          id       name           cd    dmg  min    max     anim     tele  active rec   big   weights armored
	list.append(EnemyPattern.make("slam", "PALM SLAM!", 3.2, 9, 0.0, 900.0, "slam", 0.8, 0.3, 0.7, true, [1.8], true))
	list.append(EnemyPattern.make("sweep", "SWEEP!", 4.0, 8, 0.0, 650.0, "sweep", 0.7, 0.5, 0.6, true, [1.4], true))
	list.append(EnemyPattern.make("fist", "STORM FIST!", 5.0, 10, 0.0, 700.0, "fist", 0.8, 0.4, 0.8, true, [1.3], true))
	list.append(EnemyPattern.make("zap", "FINGER ZAP!", 3.5, 7, 200.0, 2000.0, "zap", 0.6, 0.4, 0.5, false, [1.4], true))
	list.append(EnemyPattern.make("debris", "THE ROOF FALLS!", 8.0, 6, 0.0, 2000.0, "fist", 0.7, 0.5, 0.6, true, [1.5], true))
	list[4].note = "enraged only"
	return list


func wants_pattern(p: EnemyPattern) -> bool:
	return p.id != "debris" or raging


func flavor_lines() -> Array[String]:
	return ["*thunder rolls inside the mountain*", "*the palm's eye turns to you*"]


func _attack(p: EnemyPattern) -> void:
	match p.id:
		"slam":
			global_position.x = clamp_arena(target_x())
			swing(dmg(p), Vector2(260, -420), Vector2(0, -70), Vector2(240, 150), "hand_slam")
			Effects.shake(self, 14.0)
			Effects.hit_sparks(self, global_position + Vector2(0, -10), 16, 1.6)
			SoundManager.play_sfx("slam")
		"sweep":
			face_target()
			swing(dmg(p), Vector2(320, -260), Vector2(160, -30), Vector2(380, 60), "hand_sweep")
			velocity.x = facing * 1000.0
			SoundManager.play_sfx("whoosh")
		"fist":
			swing(dmg(p), Vector2(240, -380), Vector2(0, -60), Vector2(200, 130), "hand_fist")
			for d: float in [-1.0, 1.0]:
				shoot("lava_wave", Vector2(global_position.x + d * 110.0, floor_y() - 26.0), d, 480.0, 2.0, Vector2(70, 50), dmg(p) - 3,
					Vector2(240, -300), Color(0.6, 0.75, 1.0), "hand_wave", true)
			Effects.shake(self, 16.0)
			SoundManager.play_sfx("slam")
			SoundManager.play_sfx("rumble", -4.0)
		"zap":
			var x0 := target_x()
			for i in 4:
				hazard("pillar", x0 + float(i - 1) * 150.0 * float(facing), 0.45 + float(i) * 0.15, dmg(p))
			SoundManager.play_sfx("beam", -4.0)
		"debris":
			for i in 5:
				hazard("rock", target_x() + float(i - 2) * 160.0, 0.6 + float(i) * 0.12, dmg(p))
			Effects.shake(self, 10.0)
			SoundManager.play_sfx("rumble")


func draw_model_on(c: CanvasItem) -> void:
	OrbisArt.storm_hand(c, art_state())


static func draw_portrait(c: CanvasItem, t: float) -> void:
	OrbisArt.storm_hand(c, {"t": t, "short": true})
