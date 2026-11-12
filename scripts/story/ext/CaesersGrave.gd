class_name CaesersGrave
extends C5Boss
## THE CAESER'S GRAVE - final boss of the Blasphemy Caeser extension (BC4, the Caeser's Tomb).
## The serpent-god's last remains: a ROTTEN OLD BODY propped up in a BROKEN STONE COFFIN -
## decaying grey-green flesh, exposed ribs and skull, a cracked golden crown, serpents
## writhing out of its chest. It barely moves; everything comes OUT of it.
##
##   Grave Slam        8 dmg   the coffin lid crashes down: shockwaves roll both ways
##   Restless Souls    4 dmg   3 souls fly out and CHASE you for a few seconds
##   Soul Burst        4 dmg   a ring of souls bursts out in every direction
##   Serpent Swarm     6 dmg   serpents burst out of the floor under you
##   Serpents of the Grave     small serpents crawl out of its body (helpers)

const FLESH := Color(0.46, 0.50, 0.40)
const FLESH_SHADE := Color(0.30, 0.34, 0.26)
const BONE := Color(0.85, 0.82, 0.70)
const STONE := Color(0.42, 0.38, 0.36)
const STONE_HI := Color(0.58, 0.54, 0.50)
const GOLD := Color(0.85, 0.68, 0.25)
const SOUL := Color(0.65, 1.0, 0.75)
const SERPENT := Color(0.42, 0.50, 0.20)


func boss_forms() -> Array:
	return [{"name": "The Caeser's Grave", "title": "THE CAESER'S GRAVE", "hp": 440, "body": Vector2(160, 210), "speed": 45.0}]


func setup_boss() -> void:
	keep_min = 0.0
	keep_max = 420.0
	attack_chance = 0.8
	max_minions = 4
	chain_chance = 0.35
	tags = {"slam": ["close", "counter"], "souls": ["ranged"], "burst": ["counter", "anti_air"], "swarm": ["ranged", "anti_air"]}
	combos = {"slam": ["burst", "swarm"], "souls": ["swarm"], "burst": ["slam"], "swarm": ["souls"]}


static func make_patterns() -> Array[EnemyPattern]:
	var list: Array[EnemyPattern] = []
	list.append(EnemyPattern.make("slam", "GRAVE SLAM!", 3.4, 8, 0.0, 280.0, "slam", 0.6, 0.25, 0.55, true, [2.0, 2.2], true))
	list.append(EnemyPattern.make("souls", "RESTLESS SOULS!", 5.0, 4, 0.0, 1200.0, "souls", 0.5, 0.3, 0.45, true, [1.6, 1.8], true))
	list.append(EnemyPattern.make("burst", "SOUL BURST!", 6.0, 4, 0.0, 600.0, "souls", 0.55, 0.3, 0.45, true, [1.2, 1.6], true))
	list.append(EnemyPattern.make("swarm", "SERPENT SWARM!", 7.0, 6, 0.0, 1200.0, "swarm", 0.6, 0.6, 0.5, true, [1.2, 1.5], true))
	list.append(EnemyPattern.make("serpents", "SERPENTS OF THE GRAVE!", 9.0, 0, 0.0, 1200.0, "swarm", 0.5, 0.3, 0.4, true, [1.0, 1.3], true))
	list[0].note = "shockwaves: jump them"
	list[1].note = "souls that chase you"
	list[4].note = "small serpents crawl out of its body"
	return list


func flavor_lines() -> Array[String]:
	return ["*rattling breath*", "I... devoured... gods...", "Ssssleep... with me..."]


func _attack(p: EnemyPattern) -> void:
	match p.id:
		"slam":
			hit_in_radius(global_position + Vector2(facing * 80.0, -30.0), 170.0, dmg(p), Vector2(360, -340), "grave_slam")
			for d: float in [-1.0, 1.0]:
				shoot("shock", Vector2(global_position.x + d * 120.0, floor_y() - 20.0), d, 500.0, 1.0, Vector2(50, 40), dmg(p) - 2, Vector2(240, -320), BONE, "grave_wave", true)
			Effects.shake(self, 14.0)
			SoundManager.play_sfx("slam")
			SoundManager.play_sfx("stone", -3.0)
		"souls":
			for k in (4 if raging else 3):
				_soul(global_position + Vector2(randf_range(-40.0, 40.0), -130.0), Vector2.from_angle(-PI * 0.5 + randf_range(-1.0, 1.0)) * 260.0, dmg(p), 4.0, 2.4)
			SoundManager.play_sfx("void_goo", -2.0)
		"burst":
			var n := 12 if raging else 9
			for k in n:
				_soul(global_position + Vector2(0, -110), Vector2.from_angle(-PI + float(k) * PI / float(n - 1)) * 420.0, dmg(p), 0.0, 1.6)
			Effects.void_burst(self, global_position + Vector2(0, -110), 100.0)
			SoundManager.play_sfx("holy", -6.0)
		"swarm":
			var tx := target_x()
			for k in (4 if raging else 3):
				hazard("serpent", tx + float(k - 1) * 140.0 + randf_range(-20.0, 20.0), 0.6 + float(k) * 0.18, dmg(p))
			SoundManager.play_sfx("rumble", -4.0)
		"serpents":
			for k in (3 if raging else 2):
				var side := -1.0 if k % 2 == 0 else 1.0
				summon("serpent_small", global_position + Vector2(side * (90.0 + float(k) * 20.0), -40.0))
			SoundManager.play_sfx("roar", -6.0, 0.3)


## A soul: flies out, then (homing > 0) chases the target for a while.
func _soul(pos: Vector2, vel: Vector2, damage: int, homing: float, life: float) -> void:
	var s := Soul.new()
	s.source = self
	s.vel = vel
	s.damage = damage
	s.homing = homing
	s.life = life
	get_parent().add_child(s)
	s.global_position = pos


class Soul extends Node2D:
	var source: Fighter
	var vel := Vector2.ZERO
	var damage := 4
	var homing := 0.0
	var life := 2.0
	var _t := 0.0

	func _ready() -> void:
		z_index = 8

	func _physics_process(delta: float) -> void:
		if source != null and is_instance_valid(source) and source.is_time_frozen():
			return
		_t += delta
		if _t >= life or source == null or not is_instance_valid(source) or source.is_dead:
			queue_free()
			return
		if homing > 0.0 and _t > 0.35:
			var tgt := CombatManager.find_enemy(source)
			if tgt != null:
				var want := (tgt.global_position + Vector2(0, -60) - global_position).normalized() * 300.0
				vel = vel.lerp(want, clampf(homing * delta * 0.5, 0.0, 1.0))
		global_position += vel * delta
		for n in get_tree().get_nodes_in_group("fighters"):
			var f := n as Fighter
			if f == null or f.is_dead or f == source or CombatManager.passes_through(source, f):
				continue
			var c := f.global_position + Vector2(0, -f.data.body_size.y * 0.5)
			if absf(c.x - global_position.x) > 22.0 + f.data.body_size.x * 0.5 or absf(c.y - global_position.y) > 22.0 + f.data.body_size.y * 0.5:
				continue
			var h := HitData.new()
			h.source = source
			h.damage = damage
			h.knockback = Vector2(signf(vel.x if vel.x != 0.0 else 1.0) * 160.0, -140.0)
			h.origin = global_position
			h.hit_type = "enemy"
			h.move = "grave_soul"
			CombatManager.apply_hit(h, f)
			Effects.void_burst(self, global_position, 30.0)
			queue_free()
			return
		queue_redraw()

	func _draw() -> void:
		var a := 1.0 - clampf((_t - life + 0.3) / 0.3, 0.0, 1.0)
		var back := -vel.normalized() if vel.length() > 1.0 else Vector2.DOWN
		for i in 4:
			draw_circle(back * float(i) * 9.0, 12.0 - float(i) * 2.5, Color(SOUL.r, SOUL.g, SOUL.b, (0.45 - float(i) * 0.1) * a))
		draw_circle(Vector2.ZERO, 11.0, Color(SOUL.r, SOUL.g, SOUL.b, 0.85 * a))
		draw_circle(Vector2(-3, -2), 2.2, Color(0.05, 0.1, 0.05, a))
		draw_circle(Vector2(3, -2), 2.2, Color(0.05, 0.1, 0.05, a))
		draw_circle(Vector2(0, 4), 2.6, Color(0.05, 0.1, 0.05, a))


# ============================================================
# ART (facing right, origin = feet, ~180 x 230)
# ============================================================
func draw_model_on(c: CanvasItem) -> void:
	draw_grave(c, art_state())


static func draw_portrait(c: CanvasItem, t: float) -> void:
	draw_grave(c, {"t": t, "pose": "idle"})


static func draw_grave(c: CanvasItem, s: Dictionary) -> void:
	var t: float = s.get("t", 0.0)
	var pose: String = s.get("pose", "idle")
	var pt: float = s.get("pose_t", 0.0)
	var dead: bool = s.get("dead", false)
	var rage: bool = s.get("raging", false)
	if rage:
		EnemyArt.aura(c, Vector2(0, -110), 120.0, SOUL, t)
	# --- Broken coffin (back half + floor slab) ---
	var back := PackedVector2Array([Vector2(-70, 0), Vector2(-62, -200), Vector2(-20, -224), Vector2(30, -214), Vector2(52, -150), Vector2(64, 0)])
	c.draw_colored_polygon(back, STONE)
	c.draw_line(Vector2(-40, -200), Vector2(-20, -140), STONE.darkened(0.3), 3.0)      # Cracks
	c.draw_line(Vector2(-20, -140), Vector2(-34, -90), STONE.darkened(0.3), 3.0)
	c.draw_line(Vector2(30, -200), Vector2(20, -160), STONE.darkened(0.3), 3.0)
	FighterArt.outline(c, back, 4.5)
	# --- The rotten body, propped up inside ---
	var lean := 0.0
	if pose == "slam_tele":
		lean = -10.0
	elif pose == "slam":
		lean = 12.0
	var chest := Vector2(lean * 0.5, -118)
	var torso := PackedVector2Array([chest + Vector2(-34, -40), chest + Vector2(30, -40), chest + Vector2(26, 50), chest + Vector2(-28, 50)])
	c.draw_colored_polygon(torso, FLESH)
	c.draw_colored_polygon(PackedVector2Array([chest + Vector2(-34, -40), chest + Vector2(-14, -40), chest + Vector2(-10, 50), chest + Vector2(-28, 50)]), FLESH_SHADE)
	for i in 4:                                                      # Exposed ribs
		var y := -26.0 + float(i) * 12.0
		c.draw_arc(chest + Vector2(-2, y + 8), 20.0, -2.6, -0.5, 10, BONE, 4.0)
	c.draw_circle(chest + Vector2(-2, 12), 9.0, Color(0.10, 0.05, 0.05))   # Hole in the chest
	FighterArt.outline(c, torso, 4.0)
	# Serpents writhing out of the chest
	for k in 2:
		var base := chest + Vector2(-6 + float(k) * 10.0, 8)
		var pts := PackedVector2Array()
		for i in 6:
			var u := float(i) / 5.0
			pts.append(base + Vector2((30.0 + float(k) * 10.0) * u * (1.0 if k == 0 else -0.6), -20.0 * u + sin(t * 4.0 + u * 5.0 + float(k)) * 8.0))
		c.draw_polyline(pts, EnemyArt.BLACK, 10.0, FighterArt.AA)
		c.draw_polyline(pts, SERPENT, 6.0, FighterArt.AA)
		c.draw_circle(pts[5], 5.0, SERPENT.lightened(0.1))
		c.draw_circle(pts[5] + Vector2(2, -1), 1.5, Color(1.0, 0.85, 0.2))
	# Arms: bony, one reaching out (souls / swarm) or raised for the slam
	var hand := chest + Vector2(56, 10)
	match pose:
		"souls_tele", "souls", "swarm_tele", "swarm":
			hand = chest + Vector2(64, -50 + sin(t * 10.0) * 6.0)
		"slam_tele":
			hand = chest + Vector2(30, -96)
		"slam":
			hand = chest + Vector2(90, 40)
	FighterArt.limb(c, chest + Vector2(-24, -30), chest + Vector2(-46, 30), 8.0, FLESH_SHADE, FLESH_SHADE.darkened(0.2), FLESH)
	FighterArt.limb(c, chest + Vector2(22, -32), hand, 8.0, FLESH, FLESH_SHADE, BONE)
	for k in 3:
		c.draw_line(hand, hand + Vector2.from_angle(-0.6 + float(k) * 0.5) * 12.0, BONE, 3.0)
	# --- Skull with a cracked golden crown ---
	var head := chest + Vector2(6, -62 + sin(t * 1.5) * 2.0)
	FighterArt.ball(c, head, 22.0, BONE, BONE.darkened(0.25), Color.WHITE)
	c.draw_colored_polygon(EnemyArt.ellipse_points(head + Vector2(-8, 6), 10.0, 14.0, 10), Color(0.62, 0.66, 0.52, 0.6))   # Rotten flesh patch
	for k in 4:
		var bx := head + Vector2(-16 + float(k) * 10.0, -18)
		c.draw_colored_polygon(PackedVector2Array([bx + Vector2(-5, 2), bx + Vector2(5, 2), bx + Vector2(0, -12.0 if k != 2 else -5.0)]), GOLD)
	if dead:
		EnemyArt.ko_eye(c, head + Vector2(8, -2), 4.0, t)
	else:
		var glow := 0.7 + 0.3 * sin(t * (12.0 if rage else 4.0))
		for ex: float in [-2.0, 12.0]:
			c.draw_circle(head + Vector2(ex, -2), 5.5, Color(0.05, 0.02, 0.02))
			c.draw_circle(head + Vector2(ex, -2), 2.6, Color(SOUL.r, SOUL.g, SOUL.b, glow))
	var jaw := 6.0 if pose.begins_with("souls") or pose.begins_with("swarm") else 2.0
	c.draw_rect(Rect2(head.x - 4, head.y + 10, 16, 4 + jaw), Color(0.08, 0.04, 0.04))
	for k in 4:
		c.draw_rect(Rect2(head.x - 3 + float(k) * 4.0, head.y + 10, 2.5, 3), BONE)
	# --- Front of the broken coffin ---
	var front := PackedVector2Array([Vector2(-78, 0), Vector2(-74, -64), Vector2(-30, -78), Vector2(10, -60), Vector2(40, -86), Vector2(74, -70), Vector2(80, 0)])
	c.draw_colored_polygon(front, STONE_HI)
	c.draw_line(Vector2(-60, -30), Vector2(60, -30), GOLD.darkened(0.3), 3.0)      # Old inscription band
	c.draw_line(Vector2(10, -60), Vector2(16, -20), STONE.darkened(0.3), 3.0)
	FighterArt.outline(c, front, 4.5)
	if pose == "slam" and pt < 0.25:
		c.draw_arc(Vector2(60, -10), 120.0, -2.0, -0.2, 16, Color(BONE.r, BONE.g, BONE.b, 0.8 - pt * 3.0), 8.0, FighterArt.AA)
