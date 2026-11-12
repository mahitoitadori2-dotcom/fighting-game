class_name FalseGod
extends C5Boss
## THE FALSE GOD - BOSS of Colosseum 5 (Level 48, the Ashen Cathedral). When Mother Nature
## falls, something that was hiding inside her crawls out of the ashes: a towering figure in a
## vast CRIMSON CLOAK with a burning hem, long thin arms with flame claws, a crown of BURNING
## ANTLERS over a void face with two ember eyes. A nightmare made of fire.
##
##   Fire Bats       6 dmg   a flock of bats made of fire (7 when enraged)
##   Fire Dash      10 dmg   dashes through you, leaving pillars of fire behind
##   Pillar Sweep    9 dmg   pillars of fire march across the whole cathedral
##   Cloak Slash    10 dmg   the cloak becomes a huge blade
##   Nightmare Dive 12 dmg   vanishes and falls on you from above (shockwaves)
##   Flame Spiral    6 dmg   fire spirals out of the cloak and rains around it
##   Firestorm       6 dmg   ENRAGED: bats rain down + fire pillars at once
## Enraged it chains almost everything and dives TWICE in a row.

const CRIMSON := Color(0.62, 0.05, 0.08)
const CRIMSON_HI := Color(0.85, 0.15, 0.12)
const FIRE := Color(1.0, 0.45, 0.1)

var _hits := 0
var _dash_to := 0.0
var _hidden := false
var _dives := 0


func boss_forms() -> Array:
	return [{"name": "The False God", "title": "THE FALSE GOD", "hp": 680, "body": Vector2(150, 330), "speed": 250.0}]


func setup_boss() -> void:
	keep_min = 120.0
	keep_max = 360.0
	attack_chance = 0.85
	art_scale = 1.0
	chain_chance = 0.55
	cooldown_mult = 0.9
	tags = {"bats": ["ranged", "anti_air"], "fire_dash": ["escape", "ranged"], "sweep": ["ranged"], "cloak": ["close", "counter"],
		"dive": ["anti_air", "escape"], "storm": ["ranged"], "spiral": ["counter", "anti_air"]}
	combos = {"cloak": ["bats", "fire_dash", "dive"], "fire_dash": ["cloak", "sweep"], "dive": ["cloak", "spiral"], "bats": ["dive"],
		"sweep": ["fire_dash"], "spiral": ["cloak", "fire_dash"]}


static func make_patterns() -> Array[EnemyPattern]:
	var list: Array[EnemyPattern] = []
	#                          id          name               cd    dmg  min    max     anim     tele  active rec   big   weights armored
	list.append(EnemyPattern.make("bats", "FIRE BATS!", 3.0, 6, 0.0, 1200.0, "cast", 0.45, 0.50, 0.40, true, [1.8], true))
	list.append(EnemyPattern.make("fire_dash", "FIRE DASH!", 3.4, 10, 0.0, 1200.0, "dash", 0.40, 0.70, 0.40, true, [1.6], true))
	list.append(EnemyPattern.make("sweep", "PILLAR SWEEP!", 5.5, 9, 0.0, 1400.0, "raise", 0.55, 0.40, 0.45, true, [1.3], true))
	list.append(EnemyPattern.make("cloak", "CLOAK SLASH!", 2.0, 10, 0.0, 300.0, "whip", 0.38, 0.35, 0.40, true, [2.0], true))
	list.append(EnemyPattern.make("dive", "NIGHTMARE DIVE!", 4.6, 12, 0.0, 1200.0, "dive", 0.32, 1.60, 0.50, true, [1.4], true))
	list.append(EnemyPattern.make("spiral", "FLAME SPIRAL!", 4.0, 6, 0.0, 600.0, "raise", 0.45, 0.40, 0.45, true, [1.3], true))
	list.append(EnemyPattern.make("storm", "FIRESTORM!", 8.0, 6, 0.0, 1400.0, "raise", 0.65, 0.50, 0.55, true, [1.3], true))
	list[4].note = "watch for its shadow: it lands where you stand"
	list[6].note = "enraged only"
	return list


func wants_pattern(p: EnemyPattern) -> bool:
	return p.id != "storm" or raging


func flavor_lines() -> Array[String]:
	return ["*laughter like crackling fire*", "KNEEL.", "There was never a goddess. Only ME.", "Burn... and BELIEVE."]


func _attack(p: EnemyPattern) -> void:
	_hits = 0
	var tx := target_x()
	var f := float(facing)
	match p.id:
		"bats":
			var n := 7 if raging else 5
			for k in n:
				shoot("fire_bat", global_position + Vector2(f * 90.0, -260.0 + float(k) * 45.0), f, 420.0 + float(k % 3) * 80.0, 2.6, Vector2(44, 34), dmg(p), Vector2(220, -180), Color.WHITE, "fire_bat")
			SoundManager.play_sfx("flame")
			SoundManager.play_sfx("bark", -8.0, 0.3)
		"fire_dash":
			_dash_to = clamp_arena(tx + f * 320.0)
			facing = 1 if _dash_to > global_position.x else -1
			swing(dmg(p), Vector2(420, -300), Vector2(60, -150), Vector2(180, 260), "fire_dash")
			SoundManager.play_sfx("dash")
			SoundManager.play_sfx("flame", -3.0)
		"sweep":
			var from := StoryManager.wall_left_x + 120.0 if global_position.x > arena_center() else StoryManager.wall_right_x - 120.0
			var dir := 1.0 if from < arena_center() else -1.0
			for k in 9:
				hazard("hellfire", from + dir * float(k) * 160.0, 0.5 + 0.13 * float(k), dmg(p))
			SoundManager.play_sfx("flame")
		"cloak":
			swing(dmg(p), Vector2(440, -300), Vector2(150, -160), Vector2(300, 220), "cloak_slash")
			Effects.shake(self, 8.0)
			SoundManager.play_sfx("sword_slash")
			SoundManager.play_sfx("flame", -5.0)
		"dive":
			_dives = 0
			_vanish()
		"spiral":
			for k in 8:
				var x := global_position.x + (float(k) - 3.5) * 110.0
				lob("fire_bat", global_position + Vector2(0, -300), clamp_arena(x), 0.6 + 0.07 * float(k), dmg(p), Vector2(220, -220), 46.0, Color.WHITE, "flame_spiral")
			Effects.explosion(self, global_position + Vector2(0, -200), 140.0, true, true)
			SoundManager.play_sfx("flame")
		"storm":
			for k in 6:
				lob("fire_bat", global_position + Vector2(0, -320), clamp_arena(tx + float(k - 3) * 140.0 + 70.0), 0.9 + 0.08 * float(k), dmg(p), Vector2(220, -200), 50.0, Color.WHITE, "firestorm")
			for k in 3:
				hazard("hellfire", tx + float(k - 1) * 300.0, 1.0 + 0.2 * float(k), dmg(p))
			SoundManager.play_sfx("roar")
			SoundManager.play_sfx("flame")


func _vanish() -> void:
	_hidden = true
	hurtbox.set_deferred("monitorable", false)
	Effects.explosion(self, global_position + Vector2(0, -160), 120.0, true, true)
	SoundManager.play_sfx("whoosh")


func _on_attack_update(p: EnemyPattern, delta: float) -> void:
	match p.id:
		"fire_dash":
			var step := 1100.0 * delta
			if absf(_dash_to - global_position.x) <= step:
				velocity.x = 0.0
				state_time = state_len
			else:
				velocity.x = signf(_dash_to - global_position.x) * 1100.0
				if _hits < 4 and state_time >= float(_hits) * 0.14:
					_hits += 1
					hazard("hellfire", global_position.x, 0.35, 7)
		"dive":
			if _hidden and state_time >= 0.5:
				_hidden = false
				global_position = Vector2(clamp_arena(target_x()), floor_y() - 520.0)
				velocity = Vector2(0, 1600.0)
				hurtbox.set_deferred("monitorable", true)
			elif not _hidden and state_time >= 0.55 and is_on_floor():
				hit_in_radius(global_position + Vector2(0, -60), 200.0, dmg(p), Vector2(420, -420), "nightmare_dive")
				for d: float in [-1.0, 1.0]:
					shoot("shock", Vector2(global_position.x + d * 80.0, floor_y() - 20.0), d, 560.0, 0.9, Vector2(54, 44), 6, Vector2(240, -320), FIRE, "dive_wave", true)
				Effects.explosion(self, global_position + Vector2(0, -60), 200.0, true, true)
				Effects.shake(self, 18.0)
				SoundManager.play_sfx("slam")
				_dives += 1
				if raging and _dives < 2:
					state_time = 0.0                            # Enraged: dives again at once
					_vanish()
				else:
					state_time = state_len


func _on_attack_end(p: EnemyPattern) -> void:
	if p.id == "fire_dash":
		velocity.x = 0.0
	if p.id == "dive" and _hidden:
		_hidden = false
		hurtbox.set_deferred("monitorable", true)


func _owns_velocity_x() -> bool:
	return estate == EState.ATTACK and current != null and current.id in ["fire_dash", "dive"]


func _update_visuals(delta: float) -> void:
	super._update_visuals(delta)
	if _hidden:
		visuals.modulate.a = 0.0


# ============================================================
# ART (facing right, origin = feet, ~240 x 400)
# ============================================================
func draw_model_on(c: CanvasItem) -> void:
	draw_false_god(c, art_state())


static func draw_portrait(c: CanvasItem, t: float) -> void:
	draw_false_god(c, {"t": t, "pose": "idle"})


static func draw_false_god(c: CanvasItem, s: Dictionary) -> void:
	var t: float = s.get("t", 0.0)
	var pose_v: String = s.get("pose", "idle")
	var dead: bool = s.get("dead", false)
	# Burning hem under a vast crimson cloak
	for i in 9:
		var x := -90.0 + float(i) * 22.0
		var fh := 30.0 + 20.0 * absf(sin(t * 6.0 + float(i) * 1.3))
		c.draw_colored_polygon(PackedVector2Array([Vector2(x - 14, 0), Vector2(x, -fh), Vector2(x + 14, 0)]), Color(1.0, 0.45, 0.1, 0.85))
	var spread := 1.0 + (0.35 if pose_v.begins_with("cast") or pose_v.begins_with("raise") else 0.0)
	var cloak := PackedVector2Array([Vector2(-20, -300), Vector2(26, -300), Vector2(110 * spread, -150), Vector2(96 * spread, -6), Vector2(40, -20),
		Vector2(0, -4), Vector2(-40, -20), Vector2(-96 * spread, -6), Vector2(-110 * spread, -150)])
	var cols := PackedColorArray()
	for p in cloak:
		cols.append(CRIMSON_HI.lerp(CRIMSON.darkened(0.4), clampf((p.y + 300.0) / 300.0, 0.0, 1.0)))
	c.draw_polygon(cloak, cols)
	for k in 5:                                                # Folds
		var x := -60.0 + float(k) * 30.0
		c.draw_line(Vector2(x * 0.3, -280), Vector2(x, -10), Color(0.3, 0.02, 0.04), 3.0)
	FighterArt.outline(c, cloak, 5.0)
	# Long thin arms with flame claws
	var hand := Vector2(100, -170)
	match pose_v:
		"whip":
			hand = Vector2(170, -140)
		"cast", "cast_tele":
			hand = Vector2(120, -240)
		"raise", "raise_tele":
			hand = Vector2(60, -360)
		"dash":
			hand = Vector2(150, -200)
	FighterArt.limb(c, Vector2(16, -270), hand, 10.0, Color(0.12, 0.08, 0.08), Color(0.05, 0.03, 0.03), Color(0.25, 0.15, 0.12))
	for k in 4:
		FighterArt.curved_spike(c, hand, hand + Vector2(34, -20.0 + float(k) * 14.0), 4.0, Color(1.0, 0.4, 0.08), Color(1.0, 0.9, 0.5), 0.3, 2.0)
	if pose_v == "whip":
		c.draw_arc(Vector2(80, -170), 150.0, -1.0, 0.9, 16, Color(1.0, 0.4, 0.1, 0.7), 10.0, FighterArt.AA)
	# Void face under a crown of burning antlers
	var head := Vector2(6, -330)
	for sgn: float in [-1.0, 1.0]:
		var a0 := head + Vector2(sgn * 14.0, -20.0)
		var mid := a0 + Vector2(sgn * 30.0, -40.0)
		var top := mid + Vector2(sgn * 10.0, -50.0)
		c.draw_polyline(PackedVector2Array([a0, mid, top]), EnemyArt.BLACK, 12.0, FighterArt.AA)
		c.draw_polyline(PackedVector2Array([a0, mid, top]), Color(0.25, 0.08, 0.06), 7.0, FighterArt.AA)
		c.draw_line(mid, mid + Vector2(sgn * 34.0, -10.0), Color(0.25, 0.08, 0.06), 6.0)
		for tip: Vector2 in [top, mid + Vector2(sgn * 34.0, -10.0)]:
			var fh := 16.0 + 8.0 * sin(t * 9.0 + sgn)
			c.draw_colored_polygon(PackedVector2Array([tip + Vector2(-7, 2), tip + Vector2(0, -fh), tip + Vector2(7, 2)]), Color(1.0, 0.55, 0.12, 0.9))
	var face := EnemyArt.ellipse_points(head, 26.0, 32.0, 18)
	c.draw_colored_polygon(face, Color(0.02, 0.0, 0.02))
	FighterArt.outline(c, face, 4.0, CRIMSON)
	if dead:
		EnemyArt.ko_eye(c, head + Vector2(8, -4), 5.0, t)
	else:
		for ex: float in [-6.0, 14.0]:
			c.draw_circle(head + Vector2(ex, -4), 7.0, Color(1.0, 0.4, 0.05, 0.4))
			c.draw_circle(head + Vector2(ex, -4), 3.5, Color(1.0, 0.85, 0.3))
