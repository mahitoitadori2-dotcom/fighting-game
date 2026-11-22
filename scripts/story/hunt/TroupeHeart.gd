class_name TroupeHeart
extends C5Boss
## THE TROUPE'S HEART (The Hunt of a Nightmare, level 110 - a 10th level: harder by the milestone rule).
## "Hard to describe": the ART IS A PLACEHOLDER (HuntArt.troupe_heart) until the user sends a sketch.
## It MOVES like a tentacle grab: a tentacle reaches out, grabs the floor, and drags the Heart there.
## A more advanced ranged moveset than the Nightmare Lord, but it can NOT summon bats - it just
## spills its attacks EVERYWHERE.
##
##   Tentacle Grab   8 dmg   a tentacle lashes out far in front of it
##   Spill           6 dmg   burning blood splashes all over the floor around you
##   Burst           6 dmg   red flames fly out to BOTH sides at three heights
##   Tentacle Slam   9 dmg   tentacles burst up out of the floor under you
##   Bleeding Rain   8 dmg   (2nd form) columns of red fire march across the whole arena
##   Flood           6 dmg   (2nd form) everything it has, everywhere at once

const GRAB_EVERY := 2.6
const REACH_TIME := 0.45
const PULL_TIME := 0.5

var _move_t := GRAB_EVERY
var _reach_k := 0.0
var _goal_x := 0.0
var _from_x := 0.0
var _phase_m := 0                  # 0 idle, 1 reaching, 2 pulling
var _pm_t := 0.0


func boss_forms() -> Array:
	return [
		{"name": "The Troupe's Heart", "title": "THE TROUPE'S HEART", "hp": 380, "body": Vector2(180, 250), "speed": 0.0},
		{"name": "The Troupe's Heart", "title": "THE TROUPE'S HEART", "hp": 400, "body": Vector2(180, 250), "speed": 0.0,
			"banner": "IT KEEPS BEATING", "subtitle": "Everything it has, everywhere", "line": "*the beat gets faster*"},
	]


func setup_boss() -> void:
	keep_min = 0.0
	keep_max = 9999.0
	attack_chance = 0.8
	chain_chance = 0.35
	grab_immune = true
	knockback_scale = 0.0
	tags = {"grab": ["close"], "spill": ["ranged"], "burst": ["ranged", "anti_air"], "slam": ["ranged"], "rain": ["ranged"], "flood": ["ranged"]}
	combos = {"grab": ["burst"], "slam": ["spill"], "spill": ["grab"]}


static func make_patterns() -> Array[EnemyPattern]:
	var list: Array[EnemyPattern] = []
	list.append(EnemyPattern.make("grab", "TENTACLE GRAB!", 2.4, 8, 0.0, 380.0, "grab", 0.4, 0.3, 0.45, true, [1.8], true))
	list.append(EnemyPattern.make("spill", "SPILL!", 4.0, 6, 0.0, 2000.0, "spill", 0.5, 0.3, 0.5, true, [1.6], true))
	list.append(EnemyPattern.make("burst", "BURST!", 3.5, 6, 0.0, 2000.0, "spill", 0.45, 0.3, 0.45, false, [1.5], true))
	list.append(EnemyPattern.make("slam", "TENTACLE SLAM!", 4.5, 9, 0.0, 2000.0, "grab", 0.5, 0.4, 0.5, true, [1.4], true))
	list.append(EnemyPattern.make("rain", "BLEEDING RAIN!", 7.0, 8, 0.0, 2000.0, "spill", 0.7, 0.8, 0.6, true, [1.5], true))
	list.append(EnemyPattern.make("flood", "FLOOD!", 9.0, 6, 0.0, 2000.0, "spill", 0.8, 0.6, 0.7, true, [1.4], true))
	list[4].note = "2nd form"
	list[5].note = "2nd form"
	return list


func wants_pattern(p: EnemyPattern) -> bool:
	return (p.id != "rain" and p.id != "flood") or form >= 2


func flavor_lines() -> Array[String]:
	return ["*ba-dum... ba-dum...*", "*the masks pinned into it twitch*"]


## Moves ONLY by grabbing: reach -> grab the floor -> drag itself there.
func _movement(delta: float) -> void:
	velocity.x = 0.0
	velocity.y = minf(velocity.y + data.gravity * delta, data.max_fall_speed)
	if estate == EState.ATTACK or estate == EState.TELEGRAPH or not CombatManager.fight_active:
		return
	match _phase_m:
		0:
			_move_t -= delta
			if _move_t <= 0.0:
				var tx := target_x()
				_goal_x = clamp_arena(global_position.x + (tx - global_position.x) * 0.6, 120.0)   # Most of the way to you
				if absf(_goal_x - global_position.x) < 80.0:
					_move_t = 0.8
				else:
					_from_x = global_position.x
					_phase_m = 1
					_pm_t = 0.0
					facing = 1 if _goal_x > global_position.x else -1
		1:
			_pm_t += delta
			_reach_k = clampf(_pm_t / REACH_TIME, 0.0, 1.0)
			if _pm_t >= REACH_TIME:
				_phase_m = 2
				_pm_t = 0.0
				SoundManager.play_sfx("void_goo", -8.0)
		2:
			_pm_t += delta
			var k := clampf(_pm_t / PULL_TIME, 0.0, 1.0)
			global_position.x = lerpf(_from_x, _goal_x, k * k * (3.0 - 2.0 * k))
			_reach_k = 1.0 - k * 0.6
			if k >= 1.0:
				_phase_m = 0
				_reach_k = 0.0
				_move_t = GRAB_EVERY * (0.7 if form >= 2 else 1.0)


func _attack(p: EnemyPattern) -> void:
	face_target()
	match p.id:
		"grab":
			swing(dmg(p), Vector2(300, -200), Vector2(210, -60), Vector2(300, 100), "heart_grab")
			SoundManager.play_sfx("void_goo")
		"spill":
			for i in 7:
				var tx := target_x() + float(i - 3) * 120.0 + randf_range(-30.0, 30.0)
				lob("magma", global_position + Vector2(0, -170), tx, 0.7 + randf() * 0.4, dmg(p), Vector2(200, -220), 46.0, Color(0.85, 0.05, 0.05), "heart_spill")
			SoundManager.play_sfx("splash", -4.0)
		"burst":
			for dir: float in [-1.0, 1.0]:
				for i in 3:
					shoot("fireball", global_position + Vector2(dir * 80.0, -60.0 - float(i) * 70.0), dir, 520.0 + float(i) * 60.0, 2.0, Vector2(36, 30), dmg(p), Vector2(220, -160), HuntArt.FLAME, "heart_burst")
			SoundManager.play_sfx("flame")
		"slam":
			for i in 3:
				hazard("tendril", target_x() + float(i - 1) * 150.0, 0.5 + float(i) * 0.1, dmg(p))
			SoundManager.play_sfx("void_goo")
		"rain":
			var l := clamp_arena(-99999.0, 60.0)
			var r := clamp_arena(99999.0, 60.0)
			var n := 9
			for i in n:
				hazard("hellfire", lerpf(l, r, float(i) / float(n - 1)) if facing > 0 else lerpf(r, l, float(i) / float(n - 1)), 0.4 + float(i) * 0.16, dmg(p))
			SoundManager.play_sfx("flame")
		"flood":
			var l2 := clamp_arena(-99999.0, 60.0)
			var r2 := clamp_arena(99999.0, 60.0)
			for i in 12:
				lob("magma", global_position + Vector2(0, -200), randf_range(l2, r2), 0.8 + randf() * 0.6, dmg(p), Vector2(200, -220), 46.0, Color(0.85, 0.05, 0.05), "heart_flood")
			for dir2: float in [-1.0, 1.0]:
				shoot("fireball", global_position + Vector2(dir2 * 80.0, -120.0), dir2, 600.0, 2.0, Vector2(36, 30), dmg(p), Vector2(220, -160), HuntArt.FLAME, "heart_flood")
			Effects.shake(self, 10.0)
			SoundManager.play_sfx("roar", -4.0)


func draw_model_on(c: CanvasItem) -> void:
	var s := art_state()
	s["reach_k"] = _reach_k
	s["reach"] = Vector2((_goal_x - global_position.x) * float(facing), 0.0)
	HuntArt.troupe_heart(c, s)


static func draw_portrait(c: CanvasItem, t: float) -> void:
	c.draw_set_transform(Vector2(0, 30), 0.0, Vector2(0.7, 0.7))
	HuntArt.troupe_heart(c, {"t": t})
	c.draw_set_transform(Vector2.ZERO, 0.0, Vector2.ONE)
