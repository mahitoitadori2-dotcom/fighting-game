class_name LastTiger
extends C5Boss
## THE LAST TIGER - boss of DemiLand's Tiger Ravine. The last big animal alive in DemiLand:
## old, scarred, starving, its ribs showing - and still the most dangerous thing here.
## Drops the TIGER'S FANG (one of the three artifacts for the Ancient Door).
##
##   Claw Swipe   7 dmg   a fast swipe
##   Maul         9 dmg   rears up and crashes down on you
##   Pounce       8 dmg   a huge leap onto you
##   Charge       7 dmg   runs straight through the arena
##   Roar         5 dmg   shockwaves both ways + stuns you if you are close
##   The Last Hunt 7 dmg  ENRAGED: three charges in a row, across the arena and back

const CFG := {"size": 2.0, "old": true, "scars": true, "eye": Color(1.0, 0.75, 0.15)}

var _air := false
var _hunt_left := 0


func boss_forms() -> Array:
	return [{"name": "The Last Tiger", "title": "THE LAST TIGER   -   LAST OF ITS KIND", "hp": 300, "body": Vector2(200, 130), "speed": 290.0}]


func setup_boss() -> void:
	keep_min = 0.0
	keep_max = 320.0
	attack_chance = 0.78
	chain_chance = 0.4
	tags = {"claw": ["close", "counter"], "maul": ["close"], "pounce": ["escape", "close", "anti_air"], "rush": ["ranged"],
		"roar": ["counter", "close"], "hunt": ["ranged"]}
	combos = {"claw": ["maul", "pounce"], "pounce": ["claw"], "rush": ["roar", "pounce"], "roar": ["pounce"]}


static func make_patterns() -> Array[EnemyPattern]:
	var list: Array[EnemyPattern] = []
	#                          id       name              cd    dmg  min    max     anim     tele  active rec   big   weights armored
	list.append(EnemyPattern.make("claw", "CLAW SWIPE", 1.8, 7, 0.0, 230.0, "claw", 0.30, 0.25, 0.40, false, [2.0], true))
	list.append(EnemyPattern.make("maul", "MAUL!", 4.0, 9, 0.0, 200.0, "claw", 0.55, 0.30, 0.55, true, [1.3], true))
	list.append(EnemyPattern.make("pounce", "POUNCE!", 4.0, 8, 180.0, 900.0, "pounce", 0.45, 1.40, 0.50, true, [1.6], true))
	list.append(EnemyPattern.make("rush", "CHARGE!", 5.0, 7, 260.0, 1300.0, "rush", 0.55, 1.10, 0.55, true, [1.3], true))
	list.append(EnemyPattern.make("roar", "ROAR!", 7.0, 5, 0.0, 600.0, "roar", 0.60, 0.50, 0.55, true, [1.0], true))
	list.append(EnemyPattern.make("hunt", "THE LAST HUNT!", 11.0, 7, 0.0, 1600.0, "rush", 0.70, 3.60, 0.70, true, [1.4], true))
	list[4].note = "stuns you if you are close"
	list[5].note = "enraged only: three charges"
	return list


func wants_pattern(p: EnemyPattern) -> bool:
	return p.id != "hunt" or raging


func flavor_lines() -> Array[String]:
	return ["*a low, tired growl*", "*sniffs the air: you smell of other places*", "*its ribs heave*", "*one eye watches you*"]


func _attack(p: EnemyPattern) -> void:
	match p.id:
		"claw":
			swing(dmg(p), Vector2(360, -220), Vector2(130, -70), Vector2(170, 120), "tiger_claw")
			SoundManager.play_sfx("sword_slash", -4.0)
		"maul":
			swing(dmg(p), Vector2(460, -320), Vector2(130, -60), Vector2(200, 160), "tiger_maul")
			Effects.shake(self, 10.0)
			SoundManager.play_sfx("slam")
		"pounce":
			_air = false
			leap_to(target_x(), 0.65, 300.0)
			SoundManager.play_sfx("roar", -8.0)
		"rush":
			velocity.x = float(facing) * 820.0
			_charge_box(p)                                         # ONE hit per charge (the box rides along)
			SoundManager.play_sfx("roar", -6.0)
		"roar":
			for d: float in [-1.0, 1.0]:
				shoot("shock", Vector2(global_position.x + d * 90.0, floor_y() - 30.0), d, 520.0, 1.1, Vector2(50, 60), dmg(p), Vector2(260, -260), Color(1.0, 0.75, 0.3), "tiger_roar", true)
			stun_in_radius(global_position + Vector2(0, -60), 230.0, 0.7)
			Effects.shake(self, 14.0)
			SoundManager.play_sfx("roar")
		"hunt":
			_hunt_left = 3
			velocity.x = float(facing) * 900.0
			_charge_box(p)
			SoundManager.play_sfx("roar")


## The charge hitbox: switched on ONCE per run across the arena. (Switching it on every frame
## reset its "already hit" list, so one charge hit you up to 60 times a second.)
func _charge_box(p: EnemyPattern) -> void:
	swing(dmg(p), Vector2(360, -260), Vector2(90, -60), Vector2(200, 120), "tiger_charge")


func _on_attack_update(p: EnemyPattern, _delta: float) -> void:
	match p.id:
		"pounce":
			if not is_on_floor():
				_air = true
			elif _air:
				_air = false
				hit_in_radius(global_position + Vector2(40.0 * facing, -50), 170.0, dmg(p), Vector2(420, -360), "tiger_pounce")
				Effects.shake(self, 12.0)
				SoundManager.play_sfx("slam")
				velocity.x = 0.0
				state_time = state_len
		"rush", "hunt":
			var spd := 900.0 if p.id == "hunt" else 820.0
			velocity.x = float(facing) * spd
			var wall := (facing > 0 and global_position.x > StoryManager.wall_right_x - 140.0) or (facing < 0 and global_position.x < StoryManager.wall_left_x + 140.0)
			if wall or is_on_wall():
				velocity.x = 0.0
				Effects.shake(self, 8.0)
				if p.id == "hunt" and _hunt_left > 1:
					_hunt_left -= 1
					facing = -facing                              # Turn and charge again (a new hit)
					_charge_box(p)
					SoundManager.play_sfx("roar", -6.0)
				else:
					state_time = state_len


func _on_attack_end(p: EnemyPattern) -> void:
	if p.id in ["pounce", "rush", "hunt"]:
		velocity.x = 0.0
		_hunt_left = 0


func _owns_velocity_x() -> bool:
	return estate == EState.ATTACK and current != null and current.id in ["pounce", "rush", "hunt"]


func draw_model_on(c: CanvasItem) -> void:
	DemiArt.beast(c, art_state(), CFG)


static func draw_portrait(c: CanvasItem, t: float) -> void:
	DemiArt.beast(c, {"t": t, "pose": "idle"}, CFG)
