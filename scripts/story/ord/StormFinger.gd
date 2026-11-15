class_name StormFinger
extends C5Boss
## THE STORM FINGER - the boss of Terra Ordinariorum. Light the Lightning Candle in the Town: a
## hole opens in the Storm, the Storm reaches down with its HAND and attacks the town... and then
## fights you with ONE FINGER (the user's rule). A simple fight about DODGING the finger.
## It drops the ORDINARIORUM TICKET.
##
##   Press        8 dmg   it lifts (shadow on the ground), then crushes down where you stand
##   Tap-Tap      6 dmg   three quick taps walking toward you
##   Sweep        7 dmg   it drags itself along the ground - JUMP it
##   Flick        6 dmg   flicks a rock of the town at you
##   Lightning    7 dmg   ENRAGED: bolts strike down along the street

func boss_forms() -> Array:
	return [{"name": "The Storm Finger", "title": "THE STORM FINGER", "hp": 320, "body": Vector2(70, 200), "speed": 220.0}]


func setup_boss() -> void:
	keep_min = 60.0
	keep_max = 420.0
	attack_chance = 0.75
	art_scale = 1.0
	chain_chance = 0.3
	grab_immune = true
	knockback_scale = 0.0
	tags = {"press": ["close", "anti_air"], "taps": ["close"], "sweep": ["close", "counter"], "flick": ["ranged"], "bolts": ["ranged"]}
	combos = {"press": ["taps"], "flick": ["press"], "sweep": ["flick"]}


static func make_patterns() -> Array[EnemyPattern]:
	var list: Array[EnemyPattern] = []
	#                          id       name          cd    dmg  min    max     anim     tele  active rec   big   weights armored
	list.append(EnemyPattern.make("press", "PRESS!", 3.0, 8, 0.0, 900.0, "press", 0.75, 0.3, 0.6, true, [1.8], true))
	list.append(EnemyPattern.make("taps", "TAP-TAP-TAP!", 4.0, 6, 0.0, 500.0, "press", 0.5, 1.0, 0.5, false, [1.3], true))
	list.append(EnemyPattern.make("sweep", "SWEEP!", 4.5, 7, 0.0, 600.0, "sweep", 0.7, 0.5, 0.6, true, [1.3], true))
	list.append(EnemyPattern.make("flick", "FLICK!", 3.0, 6, 250.0, 2000.0, "sweep", 0.45, 0.2, 0.4, false, [1.2], true))
	list.append(EnemyPattern.make("bolts", "STORM BOLTS!", 8.0, 7, 0.0, 2000.0, "press", 0.8, 0.5, 0.6, true, [1.5], true))
	list[4].note = "enraged only"
	return list


func wants_pattern(p: EnemyPattern) -> bool:
	return p.id != "bolts" or raging


func flavor_lines() -> Array[String]:
	return ["*thunder rolls far above*", "*the finger curls... and points at you*"]


func _attack(p: EnemyPattern) -> void:
	match p.id:
		"press":
			global_position.x = clamp_arena(target_x())                 # It came down right on your shadow
			swing(dmg(p), Vector2(240, -380), Vector2(0, -60), Vector2(150, 130), "finger_press")
			Effects.shake(self, 12.0)
			Effects.hit_sparks(self, global_position + Vector2(0, -10), 12, 1.4)
			SoundManager.play_sfx("slam")
		"taps":
			_taps(dmg(p))
		"sweep":
			face_target()
			swing(dmg(p), Vector2(300, -260), Vector2(140, -30), Vector2(320, 60), "finger_sweep")
			velocity.x = facing * 900.0
			SoundManager.play_sfx("whoosh")
		"flick":
			face_target()
			shoot("debris", global_position + Vector2(facing * 50.0, -40), float(facing), 640.0, 2.2, Vector2(40, 40), dmg(p),
				Vector2(260, -220), Color.WHITE, "finger_flick")
			SoundManager.play_sfx("stone")
		"bolts":
			var x0 := target_x()
			for i in 5:
				hazard("pillar", x0 + float(i - 2) * 160.0, 0.5 + float(i) * 0.12, dmg(p))
			SoundManager.play_sfx("rumble")


func _taps(d: int) -> void:
	for i in 3:
		if is_dead:
			return
		face_target()
		global_position.x = clamp_arena(global_position.x + float(facing) * 110.0)
		swing(d, Vector2(200, -260), Vector2(0, -50), Vector2(120, 110), "finger_tap")
		Effects.shake(self, 6.0)
		SoundManager.play_sfx("stone", -4.0)
		await get_tree().create_timer(0.3).timeout


func draw_model_on(c: CanvasItem) -> void:
	OrdArt.storm_finger(c, art_state())


static func draw_portrait(c: CanvasItem, t: float) -> void:
	OrdArt.storm_finger(c, {"t": t, "short": true})
