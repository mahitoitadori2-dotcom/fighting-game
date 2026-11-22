class_name NightmaresLord
extends C5Boss
## THE NIGHTMARE'S LORD (The Hunt of a Nightmare, level 101): the level after you kill the Nightmare
## Lord, he becomes BIGGER and TEARS HIS SUIT OFF (the red scales under it). Most of his ranged attacks
## are replaced by KICKS, STOMPS and SLAMS - but he is similar in difficulty.
##
##   Kick           8 dmg   a fast front kick
##   Roundhouse    10 dmg   spins: hits both sides (armored)
##   Stomp          9 dmg   the floor cracks under you
##   Marching Stomp 8 dmg   cracks run along the floor toward you
##   Slam          12 dmg   leaps up and slams down on you
##   BloodFlame Spit 6 dmg  rarely - the last of his flames

const ART_K := 2.1
var _slam_x := 0.0


func boss_forms() -> Array:
	return [{"name": "The Nightmare's Lord", "title": "THE NIGHTMARE'S LORD", "hp": 480, "body": Vector2(130, 260), "speed": 300.0}]


func setup_boss() -> void:
	keep_min = 0.0
	keep_max = 260.0
	attack_chance = 0.8
	chain_chance = 0.4
	art_scale = ART_K
	grab_immune = true
	tags = {"kick": ["close"], "roundhouse": ["close", "counter"], "stomp": ["ranged", "anti_air"], "march": ["ranged"],
		"slam": ["escape", "anti_air"], "spit": ["ranged"]}
	combos = {"kick": ["roundhouse"], "stomp": ["slam"], "march": ["kick"]}


static func make_patterns() -> Array[EnemyPattern]:
	var list: Array[EnemyPattern] = []
	list.append(EnemyPattern.make("kick", "KICK!", 1.6, 8, 0.0, 190.0, "kick", 0.25, 0.2, 0.4, false, [1.9], true))
	list.append(EnemyPattern.make("roundhouse", "ROUNDHOUSE!", 3.6, 10, 0.0, 230.0, "roundhouse", 0.45, 0.35, 0.5, true, [1.4], true))
	list.append(EnemyPattern.make("stomp", "STOMP!", 3.0, 9, 0.0, 2000.0, "stomp", 0.45, 0.3, 0.5, true, [1.5], true))
	list.append(EnemyPattern.make("march", "MARCHING STOMP!", 4.5, 8, 0.0, 2000.0, "stomp", 0.5, 0.6, 0.5, true, [1.3], true))
	list.append(EnemyPattern.make("slam", "SLAM!", 5.5, 12, 0.0, 1000.0, "slam", 0.55, 0.8, 0.6, true, [1.3], true))
	list.append(EnemyPattern.make("spit", "BLOODFLAME SPIT!", 7.0, 6, 200.0, 2000.0, "cast", 0.4, 0.2, 0.4, false, [0.4], true))
	return list


func flavor_lines() -> Array[String]:
	return ["*the last scraps of his suit fall away*", "*he breathes out red smoke*"]


func _attack(p: EnemyPattern) -> void:
	face_target()
	match p.id:
		"kick":
			swing(dmg(p), Vector2(380, -240), Vector2(100, -70), Vector2(150, 100), "nslord_kick")
			SoundManager.play_sfx("punch")
		"roundhouse":
			hit_in_radius(global_position + Vector2(0, -110), 220.0, dmg(p), Vector2(420, -280), "nslord_roundhouse")
			SoundManager.play_sfx("whoosh")
		"stomp":
			hazard("rock", target_x(), 0.45, dmg(p), Vector2(240, -460))
			Effects.shake(self, 10.0)
			SoundManager.play_sfx("slam")
		"march":
			for i in 6:
				hazard("rock", global_position.x + float(facing) * (130.0 + float(i) * 120.0), 0.2 + float(i) * 0.14, dmg(p), Vector2(220, -420))
			Effects.shake(self, 8.0)
			SoundManager.play_sfx("rumble")
		"slam":
			_slam_x = target_x()
			leap_to(_slam_x, 0.65, 380.0)
			SoundManager.play_sfx("whoosh")
		"spit":
			for i in 3:
				shoot("fireball", global_position + Vector2(facing * 70.0, -220.0 + float(i) * 50.0), float(facing), 560.0, 1.8,
					Vector2(36, 30), dmg(p), Vector2(220, -160), HuntArt.FLAME, "nslord_spit")
			SoundManager.play_sfx("flame")


func _on_attack_update(p: EnemyPattern, _delta: float) -> void:
	if p.id == "slam" and is_on_floor() and state_time > 0.3:
		hit_in_radius(global_position + Vector2(0, -50), 230.0, dmg(p), Vector2(360, -380), "nslord_slam")
		hazard("rock", global_position.x - 200.0, 0.1, maxi(1, dmg(p) - 4))
		hazard("rock", global_position.x + 200.0, 0.1, maxi(1, dmg(p) - 4))
		Effects.shake(self, 16.0)
		Effects.hit_sparks(self, global_position, 18, 1.8)
		SoundManager.play_sfx("slam")
		state_time = state_len


func _owns_velocity_x() -> bool:
	return estate == EState.ATTACK and current != null and current.id == "slam"


func draw_model_on(c: CanvasItem) -> void:
	NightmareLordBoss.draw_lord(c, art_state(), 3)


static func draw_portrait(c: CanvasItem, t: float) -> void:
	FireLordArt._draw_figure(c, {"t": t, "tear": 3})
