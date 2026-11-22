class_name TroupeJester
extends C5Boss
## THE TROUPE'S JESTER (The Hunt of a Nightmare, level 86): a BIGGER Troupe Follower with THIN legs,
## a JESTER CAP, and BALLS that are AFLAME and red - he juggles them all fight long.
##
##   Juggle       6 dmg   throws his three flaming balls at you (they leave fire where they land)
##   Cartwheel    9 dmg   cartwheels across the arena (armored)
##   Bell Jingle  5 dmg   the cap's bells ring: a short stun around him
##   Pratfall    10 dmg   leaps up and belly-flops where you stand
##   Ball Rain    6 dmg   ENRAGED: every ball he has rains down at once

const K := 1.6
var _flop_x := 0.0


func boss_forms() -> Array:
	return [{"name": "The Troupe's Jester", "title": "THE TROUPE'S JESTER", "hp": 380, "body": Vector2(80, 190), "speed": 300.0}]


func setup_boss() -> void:
	keep_min = 120.0
	keep_max = 420.0
	attack_chance = 0.75
	chain_chance = 0.35
	art_scale = 1.0
	tags = {"juggle": ["ranged"], "cartwheel": ["close", "escape"], "bell": ["close", "counter"], "flop": ["anti_air"], "rain": ["ranged"]}
	combos = {"bell": ["cartwheel"], "juggle": ["flop"], "flop": ["bell"]}


static func make_patterns() -> Array[EnemyPattern]:
	var list: Array[EnemyPattern] = []
	#                          id          name            cd   dmg  min    max     anim      tele  active rec   big   weights armored
	list.append(EnemyPattern.make("juggle", "JUGGLE!", 2.6, 6, 140.0, 2000.0, "juggle", 0.45, 0.3, 0.45, false, [1.8], true))
	list.append(EnemyPattern.make("cartwheel", "CARTWHEEL!", 4.0, 9, 0.0, 900.0, "cartwheel", 0.5, 0.8, 0.5, true, [1.4], true))
	list.append(EnemyPattern.make("bell", "BELL JINGLE!", 5.0, 5, 0.0, 200.0, "bell", 0.5, 0.25, 0.5, false, [1.2], true))
	list.append(EnemyPattern.make("flop", "PRATFALL!", 5.0, 10, 0.0, 900.0, "flop", 0.6, 0.6, 0.6, true, [1.3], true))
	list.append(EnemyPattern.make("rain", "BALL RAIN!", 8.0, 6, 0.0, 2000.0, "juggle", 0.7, 0.4, 0.6, true, [1.6], true))
	list[4].note = "enraged only"
	return list


func wants_pattern(p: EnemyPattern) -> bool:
	return p.id != "rain" or raging


func flavor_lines() -> Array[String]:
	return ["*bells jingle*", "*he juggles... and laughs without a sound*"]


func _attack(p: EnemyPattern) -> void:
	match p.id:
		"juggle":
			face_target()
			for i in 3:
				var tx := target_x() + float(i - 1) * 110.0
				lob("fireball", global_position + Vector2(facing * 30.0, -230.0), tx, 0.7 + 0.12 * float(i), dmg(p), Vector2(220, -260), 50.0,
					HuntArt.FLAME, "jester_ball", _burn_at)
			SoundManager.play_sfx("flame", -4.0)
		"cartwheel":
			face_target()
			swing(dmg(p), Vector2(380, -260), Vector2(20, -100), Vector2(150, 190), "jester_cartwheel")
			SoundManager.play_sfx("whoosh")
		"bell":
			hit_in_radius(global_position + Vector2(0, -120), 190.0, dmg(p), Vector2(260, -200), "jester_bell")
			stun_in_radius(global_position + Vector2(0, -120), 190.0, 0.7)
			Effects.hit_sparks(self, global_position + Vector2(0, -250), 10, 1.2)
			SoundManager.play_sfx("holy", -4.0)
		"flop":
			_flop_x = target_x()
			leap_to(_flop_x, 0.6, 340.0)
			SoundManager.play_sfx("whoosh")
		"rain":
			var x0 := arena_center()
			for i in 9:
				var tx2 := x0 + float(i - 4) * 150.0
				lob("fireball", global_position + Vector2(0, -260.0), tx2, 0.9 + randf() * 0.4, dmg(p), Vector2(200, -240), 50.0,
					HuntArt.FLAME, "jester_rain", _burn_at)
			SoundManager.play_sfx("flame")


func _burn_at(pos: Vector2) -> void:
	ChemicalPool.spawn_lava(self, Vector2(pos.x, floor_y()), 90.0, 2.5)


func _on_attack_update(p: EnemyPattern, delta: float) -> void:
	match p.id:
		"cartwheel":
			velocity.x = facing * 820.0
			if is_on_wall() or absf(global_position.x - clamp_arena(global_position.x)) > 1.0:
				state_time = state_len
			if fmod(state_time, 0.25) < delta:
				swing(dmg(p), Vector2(380, -260), Vector2(20, -100), Vector2(150, 190), "jester_cartwheel")
		"flop":
			if is_on_floor() and state_time > 0.25:
				hit_in_radius(global_position + Vector2(0, -40), 200.0, dmg(p), Vector2(320, -320), "jester_flop")
				Effects.shake(self, 12.0)
				Effects.hit_sparks(self, global_position, 14, 1.4)
				SoundManager.play_sfx("slam")
				state_time = state_len


func _owns_velocity_x() -> bool:
	return estate == EState.ATTACK and current != null and (current.id == "cartwheel" or current.id == "flop")


func draw_model_on(c: CanvasItem) -> void:
	draw_jester(c, art_state())


static func draw_portrait(c: CanvasItem, t: float) -> void:
	draw_jester(c, {"t": t})


static func draw_jester(c: CanvasItem, s: Dictionary) -> void:
	var t: float = s.get("t", 0.0)
	var pose_v: String = s.get("pose", "idle")
	var spin := pose_v == "cartwheel"
	if spin:
		var pivot := Vector2(0, -100.0)                                  # Spin round his middle
		c.draw_set_transform(pivot - pivot.rotated(t * 16.0), t * 16.0, Vector2.ONE)
	var arms := 0.6 + 0.4 * sin(t * 6.0)
	if pose_v in ["juggle", "bell"]:
		arms = 1.2
	var pts := HuntArt.body(c, s if not spin else s.merged({"moving": false}, true), {"k": K, "leg": 3.5, "mask": "triangle", "arm_f": arms, "arm_b": arms * 0.8})
	var head: Vector2 = pts["head"]
	# JESTER CAP: three floppy points in red / black with gold bells
	var cols := [Color(0.75, 0.04, 0.06), Color(0.08, 0.02, 0.03), Color(0.75, 0.04, 0.06)]
	for i in 3:
		var a := -PI * 0.5 + (float(i) - 1.0) * 0.85
		var base := head + Vector2(0, -12.0 * K)
		var tip := base + Vector2.from_angle(a) * 34.0 * K + Vector2(0, 14.0 * K + sin(t * 4.0 + float(i)) * 4.0)
		var flap := PackedVector2Array([base + Vector2(-9, 0) * K, base + Vector2(9, 0) * K, tip])
		c.draw_colored_polygon(flap, cols[i])
		FighterArt.outline(c, flap, 2.5)
		c.draw_circle(tip, 4.5 * K, HuntArt.GOLD)
		c.draw_arc(tip, 4.5 * K, 0.0, TAU, 10, HuntArt.BLACK, 2.0)
	var band := PackedVector2Array([head + Vector2(-14, -10) * K, head + Vector2(14, -10) * K, head + Vector2(13, -15) * K, head + Vector2(-13, -15) * K])
	c.draw_colored_polygon(band, HuntArt.GOLD)
	FighterArt.outline(c, band, 2.0)
	if spin:
		c.draw_set_transform(Vector2.ZERO, 0.0, Vector2.ONE)
	# THE BALLS: three, aflame and red, juggled over his hands
	if pose_v != "juggle" and pose_v != "rain":
		var hf: Vector2 = pts["hand_f"]
		var hb: Vector2 = pts["hand_b"]
		for i in 3:
			var ph := t * 3.2 + float(i) * TAU / 3.0
			var bp := hb.lerp(hf, 0.5 + 0.5 * cos(ph)) + Vector2(0, -60.0 * K * absf(sin(ph)) - 10.0)
			c.draw_circle(bp, 9.0, Color(0.7, 0.02, 0.03))
			c.draw_arc(bp, 9.0, 0.0, TAU, 12, HuntArt.BLACK, 2.0)
			HuntArt.flames(c, bp + Vector2(0, -6), 7.0, t + float(i), 3)
