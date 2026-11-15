class_name TrainerAlly
extends SimpleEnemy
## THE TRAINER as a fighter ON YOUR SIDE (level 80, the user's choice: he fights with you). A CPU
## ally (team 1) built on the enemy system: he goes after the Storm's corpses and the Storm Hand.
## He is tough (takes 30% damage) and gets back up after a few seconds if he falls.
##   Blue Palm     7 dmg   a quick open-palm strike
##   Learner's Orb 6 dmg   a ball of blue light
##   Lesson        5 dmg   a blue shockwave around him that stuns for a moment


func _make_data() -> CharacterData:
	keep_min = 60.0
	keep_max = 260.0
	attack_chance = 0.7
	phase2_threshold = -1.0
	var d := SimpleEnemy.make_data("The Trainer", 160, Vector2(46, 120), 300.0)
	d.respawn_delay = 4.0
	return d


func _ready() -> void:
	super._ready()
	damage_taken_mult = 0.3
	respawn_enabled = true


static func make_patterns() -> Array[EnemyPattern]:
	var list: Array[EnemyPattern] = []
	list.append(EnemyPattern.make("palm", "BLUE PALM!", 1.4, 7, 0.0, 110.0, "palm", 0.2, 0.15, 0.3, false, [1.6]))
	list.append(EnemyPattern.make("orb", "LEARNER'S ORB!", 2.6, 6, 150.0, 700.0, "palm", 0.3, 0.2, 0.3, false, [1.3]))
	list.append(EnemyPattern.make("lesson", "LESSON!", 7.0, 5, 0.0, 200.0, "palm", 0.4, 0.3, 0.4, false, [1.0]))
	return list


func flavor_lines() -> Array[String]:
	return ["Stay close, Student!", "Not my island!", "Watch its hand!"]


func _attack(p: EnemyPattern) -> void:
	match p.id:
		"palm":
			hitbox.activate(make_hit(dmg(p), Vector2(facing * 220.0, -160.0), "trainer_palm"), Vector2(facing * 40.0, -64.0), Vector2(80, 60))
			SoundManager.play_sfx("punch", -4.0)
		"orb":
			var s := spawn_projectile()
			s.kind = EnemyProjectile.Kind.LINEAR
			s.look = "light_orb"
			s.tint = Color(0.45, 0.65, 1.0)
			s.dir = float(facing)
			s.speed = 620.0
			s.lifetime = 1.6
			s.size = Vector2(30, 30)
			s.damage = dmg(p)
			s.knockback = Vector2(160, -140)
			s.move = "trainer_orb"
			launch(s, global_position + Vector2(facing * 30.0, -76.0))
			SoundManager.play_sfx("beam", -8.0)
		"lesson":
			stun_in_radius(global_position + Vector2(0, -60), 200.0, 0.8)
			Effects.explosion(self, global_position + Vector2(0, -50), 120.0)
			SoundManager.play_sfx("holy", -6.0)


func draw_model_on(c: CanvasItem) -> void:
	OrbisArt.trainer(c, anim_time, "happy" if pose.begins_with("palm") else "calm")


static func draw_portrait(c: CanvasItem, t: float) -> void:
	OrbisArt.trainer(c, t, "calm")
