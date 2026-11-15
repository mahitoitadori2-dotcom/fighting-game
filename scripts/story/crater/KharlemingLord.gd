class_name KharlemingLord
extends C5Boss
## THE KHARLEMING LORD - second boss of Terra Craterum, in the wreck of the ancient ship. A
## combination of everything in the crater: a giant Kharleming body, basalt plates with lava in
## the cracks, demon HORNS, black FEATHERED wings and a SCORPION TAIL that drips Void Goo.
## Drops the TECHNICIAN'S BREAKER.
##
##   Mandible Crush  8 dmg   a huge bite
##   Horn Charge     8 dmg   runs straight through the arena
##   Tail Sting      9 dmg   the scorpion tail stabs far in front of it (leaves Void Goo)
##   Goo Barrage     4 dmg   three globs of Void Goo
##   Wing Dive       9 dmg   flies up and crashes down on you
##   Brood Call      -       ENRAGED: two Full Kharlemings crawl out of the wreck


func boss_forms() -> Array:
	return [{"name": "The Kharleming Lord", "title": "THE KHARLEMING LORD", "hp": 400, "body": Vector2(220, 200), "speed": 240.0}]


func setup_boss() -> void:
	keep_min = 60.0
	keep_max = 360.0
	attack_chance = 0.75
	art_scale = 1.0
	chain_chance = 0.4
	max_minions = 2
	tags = {"crush": ["close", "counter"], "charge": ["ranged"], "sting": ["close"], "goo": ["ranged", "anti_air"],
		"dive": ["escape", "anti_air", "ranged"], "brood": ["ranged"]}
	combos = {"crush": ["sting"], "sting": ["goo"], "charge": ["crush", "dive"], "dive": ["crush"]}


static func make_patterns() -> Array[EnemyPattern]:
	var list: Array[EnemyPattern] = []
	#                          id       name               cd    dmg  min    max     anim     tele  active rec   big   weights armored
	list.append(EnemyPattern.make("crush", "MANDIBLE CRUSH!", 2.2, 8, 0.0, 240.0, "bite", 0.4, 0.25, 0.45, false, [2.0], true))
	list.append(EnemyPattern.make("charge", "HORN CHARGE!", 5.0, 8, 260.0, 1300.0, "charge", 0.55, 1.1, 0.55, true, [1.3], true))
	list.append(EnemyPattern.make("sting", "TAIL STING!", 3.6, 9, 120.0, 380.0, "sting", 0.5, 0.3, 0.5, true, [1.5], true))
	list.append(EnemyPattern.make("goo", "GOO BARRAGE!", 4.5, 4, 150.0, 900.0, "spit", 0.5, 0.4, 0.5, false, [1.3], true))
	list.append(EnemyPattern.make("dive", "WING DIVE!", 6.0, 9, 150.0, 900.0, "dive", 0.55, 1.4, 0.55, true, [1.2], true))
	list.append(EnemyPattern.make("brood", "BROOD CALL!", 14.0, 0, 0.0, 2000.0, "spit", 0.6, 0.4, 0.6, true, [1.2], true))
	list[5].note = "enraged only: summons Full Kharlemings"
	return list


func wants_pattern(p: EnemyPattern) -> bool:
	return p.id != "brood" or raging


func flavor_lines() -> Array[String]:
	return ["*CLICK. CLICK. CLICK.*", "*the wreck answers with a thousand clicks*", "*its feathers rattle like metal*"]


var _air := false


func _attack(p: EnemyPattern) -> void:
	match p.id:
		"crush":
			swing(dmg(p), Vector2(380, -260), Vector2(170, -110), Vector2(160, 120), "lord_crush")
			SoundManager.play_sfx("bite")
		"charge":
			velocity.x = float(facing) * 780.0
			swing(dmg(p), Vector2(380, -280), Vector2(120, -90), Vector2(220, 150), "lord_charge")   # ONE hit per charge
			SoundManager.play_sfx("roar", -6.0)
		"sting":
			swing(dmg(p), Vector2(300, -200), Vector2(260, -150), Vector2(170, 90), "lord_sting")
			var gx := global_position.x + float(facing) * 280.0
			ChemicalPool.spawn_void(self, Vector2(clamp_arena(gx, 60.0), floor_y()), 120.0, 4.0)
			SoundManager.play_sfx("sword_slash")
		"goo":
			for i in 3:
				lob("chem_glob", global_position + Vector2(facing * 140.0, -140.0), target_x() + float(i - 1) * 120.0, 0.8 + float(i) * 0.1,
					dmg(p), Vector2(140, -140), 40.0, CraterArt.GOO, "void_goo",
					func(pos: Vector2) -> void: ChemicalPool.spawn_void(self, Vector2(pos.x, floor_y()), 110.0, 4.0))
			SoundManager.play_sfx("void_goo")
		"dive":
			_air = false
			leap_to(target_x(), 0.8, 420.0)
			SoundManager.play_sfx("whoosh")
		"brood":
			for d: float in [-1.0, 1.0]:
				summon("full_kharleming", Vector2(clamp_arena(global_position.x + d * 260.0, 80.0), floor_y() - 10.0))
			SoundManager.play_sfx("roar")
			Effects.shake(self, 10.0)


func _on_attack_update(p: EnemyPattern, _delta: float) -> void:
	match p.id:
		"charge":
			velocity.x = float(facing) * 780.0
			var wall := (facing > 0 and global_position.x > StoryManager.arena_right() - 160.0) or (facing < 0 and global_position.x < StoryManager.arena_left() + 160.0)
			if wall or is_on_wall():
				velocity.x = 0.0
				Effects.shake(self, 10.0)
				state_time = state_len
		"dive":
			if not is_on_floor():
				_air = true
			elif _air:
				_air = false
				hit_in_radius(global_position + Vector2(0, -60), 210.0, dmg(p), Vector2(420, -380), "lord_dive")
				Effects.shake(self, 14.0)
				SoundManager.play_sfx("slam")
				velocity.x = 0.0
				state_time = state_len


func _on_attack_end(p: EnemyPattern) -> void:
	if p.id in ["charge", "dive"]:
		velocity.x = 0.0


func _owns_velocity_x() -> bool:
	return estate == EState.ATTACK and current != null and current.id in ["charge", "dive"]


func draw_model_on(c: CanvasItem) -> void:
	CraterArt.lord(c, art_state())


static func draw_portrait(c: CanvasItem, t: float) -> void:
	CraterArt.lord(c, {"t": t, "pose": "idle"})
