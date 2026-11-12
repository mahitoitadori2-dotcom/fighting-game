class_name MotherNature
extends C5Boss
## MOTHER NATURE - BOSS 5 of Colosseum 5 (Level 47, the Heart of Nature). Unlocked after the
## Child Wielding Needle, the Brothers, the Animal Lord and the Executor are beaten (the board
## path). FOUR element forms, each with its OWN full HP bar:
##
## 1. FIRE    Fire Blast (3 fireballs), Fire Wave (rolls both ways: jump), Flame Pillars, Flame Whip
## 2. WATER   Water Wave (low wave: jump), Bubbles (float down on you), Water Spouts, Tide Slam
## 3. EARTH   Rock Throw (3 boulders), Ground Slam (leaps on you + rock spikes), Rock Spikes, Stone Fist
## 4. WIND    Gusts (push you back), Tornadoes, Air Dash (through you), Cyclone (spinning, close)
## When she falls, THE FALSE GOD crawls out of her ashes - a separate boss (FalseGod.gd, Level 48).

const FIRE := Color(1.0, 0.45, 0.1)
const WATER := Color(0.25, 0.6, 1.0)
const EARTH := Color(0.55, 0.42, 0.28)
const MOSS := Color(0.35, 0.55, 0.22)
const WIND := Color(0.80, 0.95, 0.90)
const SKIN := Color(0.92, 0.86, 0.78)

var _air := false
var _hits := 0
var _dash_to := 0.0


func boss_forms() -> Array:
	return [
		{"name": "Mother Nature", "title": "MOTHER NATURE   -   I. FIRE", "hp": 250, "body": Vector2(90, 240), "speed": 200.0},
		{"name": "Mother Nature", "title": "MOTHER NATURE   -   II. WATER", "hp": 250, "body": Vector2(90, 240), "speed": 210.0,
			"banner": "THE FLAMES DIE... THE TIDE RISES", "subtitle": "THE SECOND ELEMENT  -  WATER", "line": "Drown, little thing."},
		{"name": "Mother Nature", "title": "MOTHER NATURE   -   III. EARTH", "hp": 270, "body": Vector2(110, 250), "speed": 170.0,
			"banner": "THE WATER SINKS INTO STONE", "subtitle": "THE THIRD ELEMENT  -  EARTH", "line": "The mountain does not move for you."},
		{"name": "Mother Nature", "title": "MOTHER NATURE   -   IV. WIND", "hp": 250, "body": Vector2(90, 240), "speed": 280.0,
			"banner": "THE STONE CRUMBLES TO DUST... AND THE DUST FLIES", "subtitle": "THE FOURTH ELEMENT  -  WIND", "line": "You cannot hit the sky."},
	]


func setup_boss() -> void:
	keep_min = 150.0
	keep_max = 420.0
	attack_chance = 0.78
	art_scale = 1.2
	chain_chance = 0.4
	tags = {"fire_blast": ["ranged"], "fire_wave": ["counter"], "pillars": ["anti_air"], "whip": ["close", "counter"],
		"water_wave": ["counter", "ranged"], "bubbles": ["anti_air", "ranged"], "spouts": ["anti_air"], "tide": ["close"],
		"rock_throw": ["ranged", "anti_air"], "slam": ["escape", "close"], "spikes": ["ranged"], "fist": ["close", "counter"],
		"gust": ["ranged", "counter"], "tornadoes": ["anti_air"], "air_dash": ["escape", "ranged"], "cyclone": ["close", "counter"]}
	combos = {"fire_blast": ["pillars", "whip"], "whip": ["fire_wave"], "water_wave": ["bubbles"], "tide": ["spouts", "water_wave"],
		"fist": ["slam", "spikes"], "rock_throw": ["slam"], "gust": ["tornadoes", "air_dash"], "cyclone": ["air_dash"]}


static func make_patterns() -> Array[EnemyPattern]:
	var list: Array[EnemyPattern] = []
	#                          id            name               cd    dmg  min    max     anim       tele  active rec   big   weights [fire, water, earth, wind, god]  armored
	# ----- I. FIRE -----
	list.append(EnemyPattern.make("fire_blast", "FIRE BLAST!", 2.6, 6, 120.0, 1000.0, "cast", 0.45, 0.60, 0.45, true, [2.0, 0.0, 0.0, 0.0, 0.0], true))
	list.append(EnemyPattern.make("fire_wave", "FIRE WAVE!", 4.0, 8, 0.0, 900.0, "slam", 0.55, 0.30, 0.55, true, [1.5, 0.0, 0.0, 0.0, 0.0], true))
	list.append(EnemyPattern.make("pillars", "FLAME PILLARS!", 5.0, 8, 0.0, 1200.0, "raise", 0.55, 0.40, 0.45, true, [1.4, 0.0, 0.0, 0.0, 0.0], true))
	list.append(EnemyPattern.make("whip", "FLAME WHIP!", 2.2, 7, 0.0, 260.0, "whip", 0.35, 0.30, 0.45, true, [1.8, 0.0, 0.0, 0.0, 0.0], true))
	# ----- II. WATER -----
	list.append(EnemyPattern.make("water_wave", "WATER WAVE!", 3.6, 7, 0.0, 1000.0, "slam", 0.50, 0.30, 0.50, true, [0.0, 1.8, 0.0, 0.0, 0.0], true))
	list.append(EnemyPattern.make("bubbles", "BUBBLES!", 4.2, 5, 0.0, 1100.0, "cast", 0.50, 0.40, 0.45, true, [0.0, 1.6, 0.0, 0.0, 0.0], true))
	list.append(EnemyPattern.make("spouts", "WATER SPOUTS!", 5.0, 7, 0.0, 1200.0, "raise", 0.55, 0.40, 0.45, true, [0.0, 1.4, 0.0, 0.0, 0.0], true))
	list.append(EnemyPattern.make("tide", "TIDE SLAM!", 2.4, 8, 0.0, 260.0, "whip", 0.40, 0.30, 0.45, true, [0.0, 1.8, 0.0, 0.0, 0.0], true))
	# ----- III. EARTH -----
	list.append(EnemyPattern.make("rock_throw", "ROCK THROW!", 3.0, 8, 150.0, 1100.0, "cast", 0.55, 0.50, 0.50, true, [0.0, 0.0, 1.8, 0.0, 0.0], true))
	list.append(EnemyPattern.make("slam", "GROUND SLAM!", 4.5, 10, 100.0, 800.0, "leap", 0.50, 1.40, 0.60, true, [0.0, 0.0, 1.5, 0.0, 0.0], true))
	list.append(EnemyPattern.make("spikes", "ROCK SPIKES!", 4.0, 7, 0.0, 1100.0, "slam", 0.50, 0.40, 0.50, true, [0.0, 0.0, 1.6, 0.0, 0.0], true))
	list.append(EnemyPattern.make("fist", "STONE FIST!", 2.4, 9, 0.0, 250.0, "whip", 0.45, 0.25, 0.55, true, [0.0, 0.0, 1.8, 0.0, 0.0], true))
	# ----- IV. WIND -----
	list.append(EnemyPattern.make("gust", "GUSTS!", 2.8, 5, 0.0, 1000.0, "cast", 0.40, 0.60, 0.40, true, [0.0, 0.0, 0.0, 1.8, 0.0], true))
	list.append(EnemyPattern.make("tornadoes", "TORNADOES!", 5.0, 7, 0.0, 1200.0, "raise", 0.50, 0.40, 0.45, true, [0.0, 0.0, 0.0, 1.5, 0.0], true))
	list.append(EnemyPattern.make("air_dash", "AIR DASH!", 3.2, 8, 0.0, 1000.0, "dash", 0.35, 0.60, 0.40, true, [0.0, 0.0, 0.0, 1.6, 0.0], true))
	list.append(EnemyPattern.make("cyclone", "CYCLONE!", 3.6, 6, 0.0, 240.0, "spin", 0.40, 0.90, 0.45, true, [0.0, 0.0, 0.0, 1.4, 0.0], true))
	return list


func flavor_lines() -> Array[String]:
	match form:
		1:
			return ["Everything burns in time.", "*the air shimmers*"]
		2:
			return ["Be still... like the deep.", "*waves crash*"]
		3:
			return ["I am the mountain.", "*the ground groans*"]
		4:
			return ["Catch me.", "*the wind howls*"]
	return ["*the earth shakes*"]


func element() -> Color:
	return [FIRE, WATER, EARTH, WIND][clampi(form - 1, 0.0, 3)]


func _attack(p: EnemyPattern) -> void:
	_hits = 0
	var tx := target_x()
	var f := float(facing)
	match p.id:
		# ---------- FIRE ----------
		"fire_blast":
			for k in 3:
				shoot("fireball", global_position + Vector2(f * 70.0, -150.0 + float(k) * 50.0), f, 560.0 + float(k) * 70.0, 1.8, Vector2(44, 44), dmg(p), Vector2(240, -160), Color.WHITE, "fire_blast")
			SoundManager.play_sfx("flame")
		"fire_wave":
			for d: float in [-1.0, 1.0]:
				var w := shoot("lava_wave", Vector2(global_position.x + d * 90.0, floor_y()), d, 520.0, 1.8, Vector2(60, 84), dmg(p), Vector2(300, -380), Color.WHITE, "fire_wave", true)
				w.dir = d
			Effects.shake(self, 10.0)
			SoundManager.play_sfx("slam")
		"pillars":
			for k in 3:
				hazard("hellfire", tx + float(k - 1) * 200.0, 0.55 + 0.15 * float(k), dmg(p))
			SoundManager.play_sfx("flame")
		"whip":
			swing(dmg(p), Vector2(380, -240), Vector2(140, -120), Vector2(240, 120), "flame_whip")
			SoundManager.play_sfx("flame", -3.0)
		# ---------- WATER ----------
		"water_wave":
			for d: float in [-1.0, 1.0]:
				shoot("bubble", Vector2(global_position.x + d * 80.0, floor_y() - 40.0), d, 480.0, 2.0, Vector2(80, 80), dmg(p), Vector2(320, -360), WATER, "water_wave", true)
			Effects.shake(self, 8.0)
			SoundManager.play_sfx("splash")
		"bubbles":
			for k in 5:
				lob("bubble", global_position + Vector2(0, -260), clamp_arena(tx + float(k - 2) * 110.0), 1.1 + 0.1 * float(k), dmg(p), Vector2(200, -200), 50.0, WATER, "bubbles")
			SoundManager.play_sfx("splash", -4.0)
		"spouts":
			for k in 4:
				hazard("water", tx + float(k) * 150.0 - 225.0, 0.5 + 0.12 * float(k), dmg(p), Vector2(200, -560))
			SoundManager.play_sfx("splash")
		"tide":
			swing(dmg(p), Vector2(420, -280), Vector2(140, -90), Vector2(240, 160), "tide_slam")
			SoundManager.play_sfx("splash", -2.0)
		# ---------- EARTH ----------
		"rock_throw":
			for k in 3:
				lob("stone_block", global_position + Vector2(f * 60.0, -260), clamp_arena(tx + float(k - 1) * 140.0), 0.8 + 0.1 * float(k), dmg(p), Vector2(260, -260), 54.0, Color.WHITE, "rock_throw")
			SoundManager.play_sfx("stone")
		"slam":
			_air = false
			leap_to(tx, 0.7, 320.0)
			SoundManager.play_sfx("jump")
		"spikes":
			for k in 5:
				hazard("rock", global_position.x + f * (150.0 + float(k) * 130.0), 0.35 + 0.12 * float(k), dmg(p), Vector2(200, -480))
			Effects.shake(self, 8.0)
			SoundManager.play_sfx("rumble")
		"fist":
			swing(dmg(p), Vector2(460, -300), Vector2(130, -90), Vector2(200, 150), "stone_fist")
			Effects.shake(self, 8.0)
			SoundManager.play_sfx("slam", -3.0)
		# ---------- WIND ----------
		"gust":
			for k in 4:
				shoot("wind", global_position + Vector2(f * 80.0, -40.0 - float(k) * 55.0), f, 500.0 + float(k) * 70.0, 1.8, Vector2(60, 70), dmg(p), Vector2(560, -140), Color.WHITE, "gust", true)
			SoundManager.play_sfx("whoosh")
		"tornadoes":
			for k in 3:
				hazard("tornado", tx + float(k - 1) * 230.0, 0.55 + 0.2 * float(k), dmg(p), Vector2(260, -620))
			SoundManager.play_sfx("whoosh")
		"air_dash":
			_dash_to = clamp_arena(tx + f * 260.0)
			facing = 1 if _dash_to > global_position.x else -1
			swing(dmg(p), Vector2(360, -300), Vector2(40, -120), Vector2(140, 200), "air_dash")
			SoundManager.play_sfx("dash")
		"cyclone":
			SoundManager.play_sfx("whoosh", -2.0)


func _on_attack_update(p: EnemyPattern, delta: float) -> void:
	match p.id:
		"slam":
			if not is_on_floor():
				_air = true
			elif _air:
				_air = false
				hit_in_radius(global_position + Vector2(0, -50), 170.0, dmg(p), Vector2(400, -380), "ground_slam")
				hazard("rock", global_position.x - 200.0, 0.1, 6, Vector2(200, -460))
				hazard("rock", global_position.x + 200.0, 0.1, 6, Vector2(200, -460))
				Effects.shake(self, 16.0)
				SoundManager.play_sfx("slam")
				velocity.x = 0.0
				state_time = state_len
		"air_dash":
			var step := 1050.0 * delta
			if absf(_dash_to - global_position.x) <= step:
				velocity.x = 0.0
				state_time = state_len
			else:
				velocity.x = signf(_dash_to - global_position.x) * 1050.0
		"cyclone":
			if _hits < 4 and state_time >= float(_hits) * 0.22:
				_hits += 1
				hitbox.activate(make_hit(dmg(p), Vector2(facing * 300.0, -360.0), "cyclone"), Vector2(0, -110), Vector2(260, 220))
				SoundManager.play_sfx("whoosh", -6.0)


func _on_attack_end(p: EnemyPattern) -> void:
	if p.id in ["slam", "air_dash"]:
		velocity.x = 0.0


func _owns_velocity_x() -> bool:
	return estate == EState.ATTACK and current != null and current.id in ["slam", "air_dash"]


# ============================================================
# ART (facing right, origin = feet)
# ============================================================
func draw_model_on(c: CanvasItem) -> void:
	draw_nature(c, art_state())


static func draw_portrait(c: CanvasItem, t: float) -> void:
	draw_nature(c, {"t": t, "pose": "idle", "form": 1})


static func draw_nature(c: CanvasItem, s: Dictionary) -> void:
	var f: int = s.get("form", 1)
	var t: float = s.get("t", 0.0)
	var pose: String = s.get("pose", "idle")
	var dead: bool = s.get("dead", false)
	var el: Color = [FIRE, WATER, EARTH, WIND][clampi(f - 1, 0.0, 3)]
	var robe: Color = [Color(0.55, 0.12, 0.06), Color(0.10, 0.28, 0.55), Color(0.30, 0.36, 0.18), Color(0.70, 0.82, 0.78)][clampi(f - 1, 0.0, 3)]
	var hover := (14.0 + sin(t * 2.0) * 6.0) if f == 4 else 0.0
	var base := Vector2(0, -hover)
	# Elemental aura
	EnemyArt.aura(c, base + Vector2(0, -150), 90.0, el, t)
	for i in 10:
		var a := t * (1.2 if f != 3 else 0.4) + float(i) * 0.63
		var p := base + Vector2(cos(a) * 80.0, -150.0 + sin(a * 1.3) * 110.0)
		match f:
			1:
				c.draw_colored_polygon(PackedVector2Array([p + Vector2(-5, 0), p + Vector2(0, -16), p + Vector2(5, 0)]), Color(1.0, 0.6, 0.15, 0.8))
			2:
				c.draw_circle(p, 5.0, Color(0.5, 0.8, 1.0, 0.7))
			3:
				c.draw_rect(Rect2(p - Vector2(5, 5), Vector2(10, 10)), Color(0.45, 0.36, 0.26, 0.9))
			_:
				c.draw_arc(p, 9.0, a, a + 3.5, 8, Color(1, 1, 1, 0.6), 2.0)
	# Long robe flowing down (no feet: she glides)
	var sway := sin(t * 1.6) * 8.0
	var robe_pts := PackedVector2Array([base + Vector2(-26, -190), base + Vector2(28, -190), base + Vector2(56 + sway, -4), base + Vector2(20, 0),
		base + Vector2(-10 + sway, -6), base + Vector2(-50, 0), base + Vector2(-60 + sway, -6)])
	var cols := PackedColorArray()
	for p in robe_pts:
		cols.append(robe.lightened(0.15).lerp(robe.darkened(0.3), clampf((p.y + 190.0) / 190.0, 0.0, 1.0)))
	c.draw_polygon(robe_pts, cols)
	FighterArt.outline(c, robe_pts, 4.0)
	if f == 3:                                                 # Earth: stone plates + moss
		for k in 4:
			var pp := base + Vector2(-20.0 + float(k % 2) * 30.0, -150.0 + float(k) * 34.0)
			var plate := FighterArt.rrect_points(Rect2(pp, Vector2(30, 22)), 5.0)
			c.draw_colored_polygon(plate, Color(0.48, 0.44, 0.40))
			FighterArt.outline(c, plate, 2.5)
			c.draw_circle(pp + Vector2(6, 2), 5.0, MOSS)
	# Arms (casting)
	var hand := base + Vector2(40, -120)
	match pose:
		"cast", "cast_tele":
			hand = base + Vector2(70, -170)
		"raise", "raise_tele":
			hand = base + Vector2(30, -250)
		"whip":
			hand = base + Vector2(110, -110)
		"slam", "slam_tele":
			hand = base + Vector2(60, -40)
		"spin":
			hand = base + Vector2(cos(t * 20.0) * 70.0, -140)
	EnemyArt.arm(c, base + Vector2(14, -176), hand, 9.0, SKIN, SKIN.darkened(0.2), Color.WHITE, SKIN, 7.0)
	c.draw_circle(hand, 16.0, Color(el.r, el.g, el.b, 0.45))
	c.draw_circle(hand, 8.0, el.lightened(0.4))
	if pose == "whip":
		c.draw_arc(base + Vector2(60, -110), 90.0, -1.2, 0.8, 14, Color(el.r, el.g, el.b, 0.8), 8.0, FighterArt.AA)
	# Head: long elemental hair, a crown of branches
	var head := base + Vector2(6, -214)
	for strand in 3:                                           # Long flowing hair (thick strands)
		var hair := PackedVector2Array()
		for i in 8:
			var u := float(i) / 7.0
			hair.append(head + Vector2(-10.0 - float(strand) * 8.0 - u * 30.0 + sin(t * 2.0 + u * 4.0 + float(strand)) * 8.0, -8.0 + u * 118.0))
		c.draw_polyline(hair, EnemyArt.BLACK, 16.0, FighterArt.AA)
		c.draw_polyline(hair, el.darkened(0.15), 11.0, FighterArt.AA)
	FighterArt.ball(c, head, 18.0, SKIN, SKIN.darkened(0.2), Color.WHITE)
	for k in 5:                                                # Crown of branches
		var a := -PI * 0.5 + (float(k) - 2.0) * 0.4
		c.draw_line(head + Vector2.from_angle(a) * 14.0, head + Vector2.from_angle(a) * 34.0, Color(0.35, 0.25, 0.15), 4.0)
		c.draw_circle(head + Vector2.from_angle(a) * 34.0, 4.0, MOSS)
	if dead:
		EnemyArt.ko_eye(c, head + Vector2(8, -2), 3.0, t)
	else:
		c.draw_circle(head + Vector2(5, -2), 3.0, el.lightened(0.5))
		c.draw_circle(head + Vector2(13, -2), 3.0, el.lightened(0.5))
