class_name TribeBrute
extends ExtEnemy
## TRIBE BRUTE (DemiLand). A huge primitive warrior in a bone mask with a club made of a whole
## bone. Slow, hits hard.
##   Club Smash     7 dmg   a heavy overhead smash
##   Ground Pound   6 dmg   slams the ground: shockwaves roll out both ways (jump them)

const CFG := {"h": 1.2, "w": 1.35, "weapon": "hammer", "metal": Color(0.86, 0.82, 0.70), "mask": true, "teeth": true, "big_arm": true}


func _make_data() -> CharacterData:
	keep_min = 0.0
	keep_max = 120.0
	attack_chance = 0.55
	phase2_threshold = -1.0
	knockback_scale = 0.6
	return SimpleEnemy.make_data("Tribe Brute", 58, Vector2(74, 170), 120.0)


static func make_patterns() -> Array[EnemyPattern]:
	var list: Array[EnemyPattern] = []
	list.append(EnemyPattern.make("club", "CLUB SMASH", 2.4, 7, 0.0, 170.0, "smash", 0.50, 0.25, 0.5, false, [2.0, 2.0], true))
	list.append(EnemyPattern.make("pound", "GROUND POUND!", 6.0, 6, 0.0, 320.0, "smash", 0.65, 0.25, 0.6, true, [1.2, 1.2], true))
	list[1].note = "shockwaves both ways: jump"
	return list


func flavor_lines() -> Array[String]:
	return ["HRRRNG.", "*drags the club*", "SMASH.", "*breathes through the mask*"]


func _attack(p: EnemyPattern) -> void:
	match p.id:
		"club":
			melee(dmg(p), Vector2(360, -260), Vector2(70, -90), Vector2(130, 140), "club_smash")
			Effects.shake(self, 6.0)
			SoundManager.play_sfx("slam", -6.0)
		"pound":
			for d: float in [-1.0, 1.0]:
				var s := spawn_projectile()
				s.kind = EnemyProjectile.Kind.LINEAR
				s.look = "shock"
				s.tint = Color(0.6, 0.45, 0.3)
				s.dir = d
				s.speed = 430.0
				s.lifetime = 1.1
				s.size = Vector2(46, 40)
				s.damage = dmg(p)
				s.knockback = Vector2(220, -300)
				s.pierce = true
				s.move = "ground_pound"
				launch(s, global_position + Vector2(d * 50.0, -20.0))
			Effects.shake(self, 10.0)
			SoundManager.play_sfx("slam")


func draw_model_on(c: CanvasItem) -> void:
	DemiArt.tribal(c, art_state(), CFG)


static func draw_portrait(c: CanvasItem, t: float) -> void:
	DemiArt.tribal(c, {"t": t, "pose": "idle"}, CFG)
