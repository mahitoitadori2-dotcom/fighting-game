class_name RadioactiveChorus
extends C5Boss
## RADIOACTIVE GIANT METALLIC ARCHITECTS CHORUS - final boss of the Atomic Creation extension
## (AC4, the Reactor Core). The Architect Chorus, but GIANT, metallic and mutated by the reactor
## blast: a towering iron body with three singing masks for faces, green radiation leaking from
## every seam, and an exposed REACTOR CORE pulsing in its chest. It barely walks; it sings.
##
##   Radioactive Slam   9 dmg   slams both fists down: radioactive puddles where they hit
##   Radiation Wave     6 dmg   two rings of radiation roll along the floor both ways
##   Atomic Explosion  10 dmg   three blasts erupt around you (warning glow first)
##   Chorus Scream      3 dmg   all three masks scream: stuns you if you are close and calls
##                              MUTATED HUMANS out of the waste

const IRON := Color(0.34, 0.36, 0.38)
const IRON_SHADE := Color(0.20, 0.22, 0.24)
const IRON_HI := Color(0.55, 0.58, 0.60)
const RAD := Color(0.45, 1.0, 0.30)
const MASK := Color(0.78, 0.80, 0.76)


func boss_forms() -> Array:
	return [{"name": "Radioactive Chorus", "title": "RADIOACTIVE GIANT METALLIC ARCHITECTS CHORUS", "hp": 520, "body": Vector2(200, 340), "speed": 55.0}]


func setup_boss() -> void:
	keep_min = 0.0
	keep_max = 420.0
	attack_chance = 0.75
	max_minions = 3
	chain_chance = 0.35
	tags = {"slam": ["close", "counter"], "wave": ["counter", "anti_air"], "atomic": ["ranged"], "scream": ["counter"]}
	combos = {"slam": ["wave"], "wave": ["atomic"], "atomic": ["slam"]}


static func make_patterns() -> Array[EnemyPattern]:
	var list: Array[EnemyPattern] = []
	list.append(EnemyPattern.make("slam", "RADIOACTIVE SLAM!", 3.4, 9, 0.0, 300.0, "slam", 0.65, 0.25, 0.6, true, [2.0, 2.2], true))
	list.append(EnemyPattern.make("wave", "RADIATION WAVE!", 5.0, 6, 0.0, 1200.0, "sing", 0.55, 0.6, 0.5, true, [1.6, 1.8], true))
	list.append(EnemyPattern.make("atomic", "ATOMIC EXPLOSION!", 7.5, 10, 0.0, 1200.0, "sing", 0.6, 0.3, 0.5, true, [1.3, 1.6], true))
	list.append(EnemyPattern.make("scream", "CHORUS SCREAM!", 11.0, 3, 0.0, 1200.0, "scream", 0.7, 0.4, 0.5, true, [1.0, 1.2], true))
	list[1].note = "rings along the floor: jump them"
	list[2].note = "three blasts around you"
	list[3].note = "stuns up close + calls Mutated Humans"
	return list


func flavor_lines() -> Array[String]:
	return ["WE... ARE... MELTING...", "*a choir of static*", "SING... WITH... US..."]


func _attack(p: EnemyPattern) -> void:
	match p.id:
		"slam":
			for d: float in [-1.0, 1.0]:
				var x := global_position.x + facing * 150.0 + d * 70.0
				hit_in_radius(Vector2(x, global_position.y - 30.0), 110.0, dmg(p), Vector2(360, -360), "radioactive_slam")
				var g: Variant = Effects.ground_below(self, Vector2(clamp_arena(x), global_position.y - 40.0), 300.0)
				if g != null:
					ChemicalPool.spawn(self, g as Vector2, 120.0, 4.0)
			Effects.shake(self, 16.0)
			Effects.explosion(self, global_position + Vector2(facing * 150.0, -20.0), 90.0, false, false)
			SoundManager.play_sfx("slam")
		"wave":
			for d: float in [-1.0, 1.0]:
				shoot("shock", Vector2(global_position.x + d * 120.0, floor_y() - 24.0), d, 480.0, 1.6, Vector2(60, 50), dmg(p), Vector2(260, -340), RAD, "radiation_wave", true)
			_wave_two = true
			SoundManager.play_sfx("spark")
		"atomic":
			var tx := target_x()
			for k in (4 if raging else 3):
				hazard("blast", tx + float(k - 1) * 170.0 + randf_range(-30.0, 30.0), 0.7 + float(k) * 0.2, dmg(p))
			SoundManager.play_sfx("rumble")
		"scream":
			hit_in_radius(global_position + Vector2(0, -200), 230.0, dmg(p), Vector2(260, -200), "chorus_scream")
			stun_in_radius(global_position + Vector2(0, -200), 230.0, 0.7)
			for k in (2 if not raging else 3):
				var side := -1.0 if k % 2 == 0 else 1.0
				summon("mutant", Vector2(clamp_arena(global_position.x + side * (240.0 + float(k) * 60.0)), global_position.y - 300.0))
			Effects.shake(self, 10.0)
			SoundManager.play_sfx("roar", -2.0, 0.2)


var _wave_two := false


func _on_attack_update(p: EnemyPattern, _delta: float) -> void:
	if p.id == "wave" and _wave_two and state_time >= 0.4:        # A second ring follows the first
		_wave_two = false
		for d: float in [-1.0, 1.0]:
			shoot("shock", Vector2(global_position.x + d * 120.0, floor_y() - 24.0), d, 480.0, 1.6, Vector2(60, 50), dmg(p), Vector2(260, -340), RAD, "radiation_wave", true)


# ============================================================
# ART (facing right, origin = feet, ~240 x 360)
# ============================================================
func draw_model_on(c: CanvasItem) -> void:
	draw_chorus(c, art_state())


static func draw_portrait(c: CanvasItem, t: float) -> void:
	draw_chorus(c, {"t": t, "pose": "idle"})


static func draw_chorus(c: CanvasItem, s: Dictionary) -> void:
	var t: float = s.get("t", 0.0)
	var pose: String = s.get("pose", "idle")
	var dead: bool = s.get("dead", false)
	var rage: bool = s.get("raging", false)
	var pulse := 0.6 + 0.4 * sin(t * (9.0 if rage else 4.0))
	var rad := Color(RAD.r, RAD.g, RAD.b, pulse)
	c.draw_circle(Vector2(0, -180), 170.0, Color(RAD.r, RAD.g, RAD.b, 0.07 + 0.05 * pulse))
	# Legs: two iron pillars, green leaking from the joints
	for i in 2:
		var x := -50.0 if i == 0 else 40.0
		FighterArt.rrect(c, Rect2(x - 26, -130, 52, 128), IRON_SHADE if i == 0 else IRON, IRON_SHADE.darkened(0.2), IRON_HI, 8.0, 4.5)
		c.draw_circle(Vector2(x, -70), 9.0, rad)
	# Far arm
	var lh := Vector2(-120, -120)
	var rh := Vector2(120, -120)
	match pose:
		"slam_tele":
			lh = Vector2(-40, -380)
			rh = Vector2(90, -385)
		"slam":
			lh = Vector2(110, -20)
			rh = Vector2(190, -20)
		"sing_tele", "sing", "scream_tele", "scream":
			lh = Vector2(-150, -260)
			rh = Vector2(150, -260)
	FighterArt.limb(c, Vector2(-90, -290), lh, 38.0, IRON_SHADE, IRON_SHADE.darkened(0.2), IRON)
	FighterArt.ball(c, lh, 28.0, IRON_SHADE, IRON_SHADE.darkened(0.25), IRON)
	# Torso: a huge iron barrel with seams leaking green
	var torso := PackedVector2Array([Vector2(-110, -320), Vector2(112, -322), Vector2(96, -128), Vector2(-94, -126)])
	c.draw_colored_polygon(torso, IRON)
	c.draw_colored_polygon(PackedVector2Array([Vector2(-110, -320), Vector2(-70, -321), Vector2(-56, -127), Vector2(-94, -126)]), IRON_SHADE)
	for k in 4:                                           # Rivets + seams with green drips
		var y := -300.0 + float(k) * 48.0
		c.draw_line(Vector2(-100, y), Vector2(100, y + 2), IRON_SHADE.darkened(0.3), 3.0)
		var dx := -60.0 + float(k) * 40.0
		var drip := fmod(t * 0.5 + float(k) * 0.3, 1.0)
		c.draw_line(Vector2(dx, y), Vector2(dx, y + 10.0 + drip * 22.0), rad, 4.0)
	FighterArt.outline(c, torso, 5.0)
	# The REACTOR CORE in the chest
	var core := Vector2(4, -230)
	c.draw_circle(core, 54.0, Color(0.08, 0.1, 0.08))
	c.draw_circle(core, 42.0 + 6.0 * pulse, Color(RAD.r, RAD.g, RAD.b, 0.35))
	c.draw_circle(core, 30.0, RAD)
	c.draw_circle(core, 14.0, Color(0.9, 1.0, 0.85))
	for k in 3:                                           # Radiation trefoil
		var a := t * 0.8 + float(k) * TAU / 3.0
		c.draw_colored_polygon(PackedVector2Array([core, core + Vector2.from_angle(a - 0.4) * 28.0, core + Vector2.from_angle(a + 0.4) * 28.0]), Color(0.1, 0.2, 0.05, 0.7))
	c.draw_arc(core, 54.0, 0.0, TAU, 32, EnemyArt.BLACK, 6.0, true)
	# Three singing MASKS (the chorus) on a wide neck
	FighterArt.rrect(c, Rect2(-90, -372, 180, 56), IRON_SHADE, IRON_SHADE.darkened(0.2), IRON, 10.0, 4.0)
	for k in 3:
		var m := Vector2(-56 + float(k) * 56.0, -360 + (sin(t * 3.0 + float(k)) * 4.0))
		var mask := EnemyArt.ellipse_points(m, 24.0, 30.0, 16)
		c.draw_colored_polygon(mask, MASK)
		c.draw_colored_polygon(EnemyArt.ellipse_points(m + Vector2(-8, 4), 12.0, 20.0, 10), Color(0.6, 0.62, 0.58, 0.6))
		FighterArt.outline(c, mask, 3.5)
		if dead:
			EnemyArt.ko_eye(c, m + Vector2(-8, -6), 3.0, t)
			EnemyArt.ko_eye(c, m + Vector2(8, -6), 3.0, t)
		else:
			for ex: float in [-8.0, 8.0]:
				c.draw_circle(m + Vector2(ex, -8), 4.0, Color(0.05, 0.05, 0.05))
				c.draw_circle(m + Vector2(ex, -8), 2.0, rad)
		var open := 12.0 if pose.begins_with("sing") or pose.begins_with("scream") else 5.0
		c.draw_colored_polygon(EnemyArt.ellipse_points(m + Vector2(0, 12), 8.0, open, 10), Color(0.05, 0.08, 0.04))
		if pose == "scream" or pose == "sing":
			c.draw_arc(m + Vector2(0, 12), 18.0 + fmod(t * 60.0, 30.0), 0.4, PI - 0.4, 8, Color(RAD.r, RAD.g, RAD.b, 0.6), 3.0, true)
	# Near arm
	FighterArt.limb(c, Vector2(96, -292), rh, 40.0, IRON, IRON_SHADE, IRON_HI)
	FighterArt.ball(c, rh, 30.0, IRON, IRON_SHADE, IRON_HI)
	c.draw_circle(rh, 9.0, rad)
