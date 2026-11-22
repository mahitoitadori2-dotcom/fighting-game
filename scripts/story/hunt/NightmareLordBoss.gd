class_name NightmareLordBoss
extends C5Boss
## THE NIGHTMARE LORD (The Hunt of a Nightmare, level 100 - a 50th level: SUPER BOSS by the milestone
## rule). The same Nightmare Lord as the playable fighter (FireLordArt: red skin, suit, red tie, pure
## red flames), bigger, with his moves EXTENDED (the user's rule): Oil Spills, Bat Attacks, BloodFlame,
## and Throwing Knives - but the knives only rarely.
##
##   Punch             6 dmg   a quick jab
##   BloodFlame Spit   6 dmg   a spread of red flames
##   Bat Swarm         6 dmg   red bats fly at you in waves
##   Launch O' Spikes  8 dmg   leaps onto you; red spikes burst out of the floor around him
##   Oil Spill         4 dmg   black oil splashes across the floor (it BURNS once fire touches it)
##   BloodFlame        8 dmg   columns of red fire erupt under you - and light every oil puddle near them
##   Throwing Knives   6 dmg   RARE: three knives in a fan
## After he dies, the next level is THE NIGHTMARE'S LORD (NightmaresLord.gd).

const ART_K := 1.7
var _oil: Array = []
var _leap_x := 0.0


func boss_forms() -> Array:
	return [{"name": "The Nightmare Lord", "title": "THE NIGHTMARE LORD", "hp": 380, "body": Vector2(100, 210), "speed": 260.0}]


func setup_boss() -> void:
	keep_min = 120.0
	keep_max = 440.0
	attack_chance = 0.78
	chain_chance = 0.4
	art_scale = ART_K
	tags = {"punch": ["close"], "spit": ["ranged"], "bats": ["ranged", "anti_air"], "spikes": ["close", "escape"],
		"oil": ["ranged"], "bloodflame": ["ranged"], "knives": ["ranged"]}
	combos = {"oil": ["bloodflame"], "punch": ["spikes"], "spit": ["bats"]}


static func make_patterns() -> Array[EnemyPattern]:
	var list: Array[EnemyPattern] = []
	#                          id           name                 cd    dmg  min    max     anim      tele  active rec   big   weights armored
	list.append(EnemyPattern.make("punch", "PUNCH", 1.6, 6, 0.0, 150.0, "punch", 0.22, 0.15, 0.35, false, [1.8], true))
	list.append(EnemyPattern.make("spit", "BLOODFLAME SPIT!", 3.0, 6, 120.0, 2000.0, "cast", 0.4, 0.25, 0.45, false, [1.6], true))
	list.append(EnemyPattern.make("bats", "BAT SWARM!", 4.5, 6, 0.0, 2000.0, "cast", 0.5, 0.6, 0.45, false, [1.4], true))
	list.append(EnemyPattern.make("spikes", "LAUNCH O' SPIKES!", 6.0, 8, 0.0, 900.0, "spikes", 0.5, 0.8, 0.6, true, [1.3], true))
	list.append(EnemyPattern.make("oil", "OIL SPILL!", 7.0, 4, 0.0, 2000.0, "cast", 0.45, 0.25, 0.45, false, [1.2], true))
	list.append(EnemyPattern.make("bloodflame", "BLOODFLAME!", 5.0, 8, 0.0, 2000.0, "cast", 0.55, 0.3, 0.5, true, [1.3], true))
	list.append(EnemyPattern.make("knives", "THROWING KNIVES", 12.0, 6, 150.0, 2000.0, "cast", 0.3, 0.2, 0.4, false, [0.35], true))
	return list


func flavor_lines() -> Array[String]:
	return ["*he straightens his red tie*", "*a smirk*"]


func _attack(p: EnemyPattern) -> void:
	face_target()
	match p.id:
		"punch":
			swing(dmg(p), Vector2(260, -180), Vector2(70, -130), Vector2(110, 90), "nlord_punch")
			SoundManager.play_sfx("punch", -4.0)
		"spit":
			for i in 3:
				shoot("fireball", global_position + Vector2(facing * 60.0, -170.0 + float(i) * 45.0), float(facing), 520.0 + float(i) * 70.0, 2.0,
					Vector2(36, 30), dmg(p), Vector2(220, -160), HuntArt.FLAME, "nlord_spit")
			for i in 2:
				lob("fireball", global_position + Vector2(facing * 50.0, -180.0), target_x() + float(i * 2 - 1) * 90.0, 0.7, dmg(p), Vector2(200, -220), 40.0, HuntArt.FLAME, "nlord_spit")
			SoundManager.play_sfx("flame")
		"bats":
			_bat_waves(dmg(p), 3 if not raging else 5)
		"spikes":
			_leap_x = target_x()
			leap_to(_leap_x, 0.55, 300.0)
			SoundManager.play_sfx("whoosh")
		"oil":
			for i in 3:
				var tx := target_x() + float(i - 1) * 190.0
				lob("chem_glob", global_position + Vector2(facing * 40.0, -160.0), tx, 0.7 + 0.1 * float(i), dmg(p), Vector2(160, -160), 50.0,
					Color(0.08, 0.06, 0.1), "nlord_oil", _spill)
			SoundManager.play_sfx("void_goo", -4.0)
		"bloodflame":
			var x0 := target_x()
			for i in 3:
				var hx := x0 + float(i - 1) * 150.0
				hazard("hellfire", hx, 0.55, dmg(p))
				_ignite_near.call_deferred(hx)
			SoundManager.play_sfx("flame")
		"knives":
			for i in 3:
				var k := shoot("nm_weapon", global_position + Vector2(facing * 40.0, -190.0 + float(i) * 50.0), float(facing), 700.0, 1.6, Vector2(44, 18), dmg(p), Vector2(200, -120), Color.WHITE, "nlord_knife")
				k.art_id = "dagger"
				k.burning = false
			SoundManager.play_sfx("whoosh")


func _bat_waves(d: int, n: int) -> void:
	for i in n:
		if is_dead:
			return
		face_target()
		shoot("fire_bat", global_position + Vector2(facing * 40.0, -220.0 + float(i % 3) * 60.0), float(facing), 480.0, 2.6, Vector2(44, 34), d, Vector2(200, -180), HuntArt.FLAME, "nlord_bat")
		SoundManager.play_sfx("whoosh", -8.0)
		await get_tree().create_timer(0.22).timeout


## Oil lands: a black puddle that burns once fire touches it.
func _spill(pos: Vector2) -> void:
	var o := OilPuddle.new()
	o.source = self
	o.width = 200.0
	o.duration = 10.0
	o.burn_damage = 4
	o.burn_time = 4.0
	o.move = "nlord_oil_burn"
	get_parent().add_child(o)
	o.global_position = Vector2(pos.x, floor_y())
	_oil.append(o)


## BloodFlame lights the oil it touches.
func _ignite_near(x: float) -> void:
	await get_tree().create_timer(0.55).timeout
	for o in _oil:
		if o != null and is_instance_valid(o) and absf((o as OilPuddle).global_position.x - x) < 200.0:
			(o as OilPuddle).ignite()


func _on_attack_update(p: EnemyPattern, _delta: float) -> void:
	if p.id == "spikes" and is_on_floor() and state_time > 0.3:
		hit_in_radius(global_position + Vector2(0, -50), 170.0, dmg(p), Vector2(300, -320), "nlord_slam")
		for i in 4:
			hazard("hellfire", global_position.x + float(i - 2) * 120.0 + 60.0, 0.15 + 0.08 * float(i), dmg(p))
		Effects.shake(self, 12.0)
		SoundManager.play_sfx("slam")
		state_time = state_len


func _owns_velocity_x() -> bool:
	return estate == EState.ATTACK and current != null and current.id == "spikes"


func draw_model_on(c: CanvasItem) -> void:
	draw_lord(c, art_state(), 1)


static func draw_portrait(c: CanvasItem, t: float) -> void:
	FireLordArt.draw_portrait(c, t)


## Shared with The Nightmare's Lord (tear 3 = the suit torn off).
static func draw_lord(c: CanvasItem, s: Dictionary, tear: int) -> void:
	var pose_v: String = s.get("pose", "idle")
	var pt: float = s.get("pose_t", 0.0)
	var punch := 0.0
	var cast := 0.0
	var spike := 0.0
	match pose_v:
		"punch", "kick":
			punch = clampf(pt * 8.0, 0.0, 1.0)
		"cast", "cast_tele":
			cast = 1.0 if pose_v == "cast" else 0.5
		"spikes_tele", "slam_tele":
			spike = 1.0
		"spikes", "slam":
			spike = -1.0
		"stomp", "roundhouse":
			punch = 0.8
	FireLordArt._draw_figure(c, {"t": s.get("t", 0.0), "ph": s.get("walk", 0.0), "floor": s.get("floor", true),
		"punch": punch, "cast": cast, "spike": spike, "tear": tear})
