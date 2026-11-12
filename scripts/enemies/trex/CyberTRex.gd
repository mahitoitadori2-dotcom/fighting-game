class_name CyberTRex
extends SimpleEnemy
## CYBER T-REX: robot dinosaur, metal plates, red glowing eyes, laser cannon on its back.
## PvE enemy (BaseEnemy + EnemyPattern + EnemyHUD). TANKY: 70 HP, 25% knockback resistance.
##
##   Laser Bite        8 dmg, 7 s  - bites; at range a small laser fires from the jaws
##                                   (bite OR laser, never both on the same target)
##   Tail Swipe        9 dmg, 10 s - giant metal tail sweep: hits in FRONT and BEHIND
##   Missile Barrage   5 dmg each, 14 s - 3 missiles fly up from the back cannon and rain
##                                   down around you (red target circles warn you)

const BITE_KB := Vector2(300, -150)
const LASER_KB := Vector2(180, -80)
const TAIL_RADIUS := 150.0
const TAIL_KB := Vector2(420, -260)
const MISSILE_KB := Vector2(220, -220)

const METAL := Color(0.58, 0.62, 0.68)
const METAL_SHADE := Color(0.36, 0.39, 0.45)
const METAL_HI := Color(0.82, 0.86, 0.92)
const DARK := Color(0.20, 0.22, 0.26)
const RED_EYE := Color(1.0, 0.12, 0.08)
const RED_GLOW := Color(1.0, 0.25, 0.15)

var _bitten: Array = []          # Shared with the laser so a target is hit by bite OR laser


func _make_data() -> CharacterData:
	keep_min = 0.0
	keep_max = 170.0
	attack_chance = 0.55
	knockback_scale = 0.75
	return SimpleEnemy.make_data("Cyber T-Rex", EnemyManager.TANK_HP, Vector2(110, 120), 260.0)


static func make_patterns() -> Array[EnemyPattern]:
	var list: Array[EnemyPattern] = []
	#                          id                name                cd    dmg  min    max    anim       tele  active rec   big   weights
	list.append(EnemyPattern.make("laser_bite", "LASER BITE!", 7.0, 8, 0.0, 520.0, "bite", 0.35, 0.25, 0.35, true, [1.6, 1.6]))
	list.append(EnemyPattern.make("tail_swipe", "TAIL SWIPE!", 10.0, 9, 0.0, 170.0, "tail", 0.40, 0.25, 0.40, true, [1.5, 1.8]))
	list.append(EnemyPattern.make("missile_barrage", "MISSILE BARRAGE!", 14.0, 5, 150.0, 800.0, "missiles", 0.55, 0.30, 0.45, true, [1.1, 1.4]))
	list[0].note = "laser at range"
	list[1].note = "hits front AND behind"
	list[2].note = "x3 missiles, %d each" % 5
	return list


func flavor_lines() -> Array[String]:
	return ["*BZZT* RAWR.EXE", "TARGET ACQUIRED.", "*servo noises*"]


func _on_respawn() -> void:
	super._on_respawn()
	knockback_scale = 0.75                         # Fighter.respawn() resets it to 1.0


func _attack(p: EnemyPattern) -> void:
	match p.id:
		"laser_bite":
			_bitten.clear()
			hitbox.activate(make_hit(dmg(p), Vector2(facing * BITE_KB.x, BITE_KB.y), "laser_bite"),
				Vector2(facing * 82.0, -84.0), Vector2(70, 52))
			var l := spawn_projectile()
			l.look = "laser"
			l.damage = dmg(p)
			l.knockback = LASER_KB
			l.dir = float(facing)
			l.speed = 1100.0
			l.lifetime = 0.6
			l.size = Vector2(60, 12)
			l.pierce = false
			l.exclude = _bitten
			l.on_hit = _laser_hit
			l.move = "laser_bite"
			launch(l, global_position + Vector2(facing * 100.0, -88.0))
			Effects.play_hit_sound(self, "trex_laser", global_position)
		"tail_swipe":
			hit_in_radius(global_position + Vector2(0, -55), TAIL_RADIUS, dmg(p), TAIL_KB, "tail_swipe")
			Effects.shake(self, 6.0)
		"missile_barrage":
			var tx := target_x()
			for i in 3:
				var m := spawn_projectile()
				m.kind = EnemyProjectile.Kind.DROP
				m.look = "missile"
				m.damage = dmg(p)
				m.knockback = MISSILE_KB
				m.delay = 0.7 + float(i) * 0.16
				m.radius = 55.0
				m.move = "missile_barrage"
				launch(m, Vector2(clamp_to_ground(tx + float(i - 1) * 95.0, 30.0), global_position.y))
			Effects.hit_sparks(self, global_position + Vector2(-facing * 20.0, -130), 8, 1.0)
			Effects.popup(self, global_position + Vector2(0, -160), "LOCK ON!", RED_GLOW, 18)


## The bite landed: the laser must ignore this target.
func _on_hit_landed(victim: Fighter, hit: HitData, _result: String) -> void:
	if hit.move == "laser_bite":
		_bitten.append(victim)


## The laser landed first: the bite hitbox must skip this target.
func _laser_hit(victim: Fighter) -> void:
	_bitten.append(victim)
	if hitbox != null and hitbox.active:
		hitbox._hit_list.append(victim)


# ============================================================
# ART (facing right, origin = feet, ~190 x 140)
# ============================================================
func draw_model_on(c: CanvasItem) -> void:
	draw_rex(c, art_state())


static func draw_portrait(c: CanvasItem, t: float) -> void:
	draw_rex(c, {"t": t, "pose": "idle"})


static func draw_rex(c: CanvasItem, s: Dictionary) -> void:
	var t: float = s.get("t", 0.0)
	var pose: String = s.get("pose", "idle")
	var pt: float = s.get("pose_t", 0.0)
	var dead: bool = s.get("dead", false)

	if s.get("enraged", false):
		EnemyArt.aura(c, Vector2(0, -70), 80.0, RED_GLOW, t)

	var body_c := Vector2(-6, -74 + sin(t * 3.0) * 1.5)

	# --- Tail (swipes all the way round on Tail Swipe) ---
	var tail_a := PI + 0.25 + sin(t * 2.0) * 0.08
	if pose == "tail_tele":
		tail_a = PI + 0.25 + 0.6 * clampf(pt / 0.4, 0.0, 1.0)
	elif pose == "tail":
		tail_a = PI + 0.85 - TAU * clampf(pt / 0.25, 0.0, 1.0)
		c.draw_arc(body_c, TAIL_RADIUS * 0.9, 0.0, TAU, 40, Color(1, 1, 1, 0.35), 10.0, FighterArt.AA)
	var tail_base := body_c + Vector2(-34, 6)
	var tail_mid := tail_base + Vector2.from_angle(tail_a) * 46.0
	var tail_tip := tail_mid + Vector2.from_angle(tail_a + 0.2) * 44.0
	FighterArt.limb(c, tail_base, tail_mid, 22.0, METAL, METAL_SHADE, METAL_HI)
	FighterArt.limb(c, tail_mid, tail_tip, 13.0, METAL, METAL_SHADE, METAL_HI)
	for k in 3:                                          # Tail plates
		var tp := tail_base.lerp(tail_tip, 0.25 + float(k) * 0.25)
		c.draw_circle(tp, 3.0, DARK)

	# --- Legs (big, digitigrade) ---
	var walk: float = s.get("walk", 0.0)
	var stride := 10.0 if s.get("moving", false) else 0.0
	for i in 2:
		var far := i == 0
		var hip := body_c + Vector2(-8.0 if far else 4.0, 18)
		var sw := sin(walk + (PI if far else 0.0)) * stride
		var knee := hip + Vector2(14 + sw * 0.5, 22)
		var ankle := Vector2(hip.x - 2 + sw, -14)
		var foot := Vector2(ankle.x + 16, -4)
		var base := METAL_SHADE if far else METAL
		FighterArt.limb(c, hip, knee, 24.0, base, METAL_SHADE, METAL_HI)
		FighterArt.limb(c, knee, ankle, 13.0, base, METAL_SHADE, METAL_HI)
		FighterArt.limb(c, ankle, foot, 10.0, DARK, DARK, METAL_SHADE)
		for cl in 3:
			c.draw_line(foot + Vector2(-4 + float(cl) * 5.0, 2), foot + Vector2(0 + float(cl) * 5.0, 6), EnemyArt.BLACK, 3.0)

	# --- Body: armored barrel ---
	var body := EnemyArt.ellipse_points(body_c, 46, 30, 26)
	var cols := PackedColorArray()
	for p in body:
		cols.append(METAL_HI.lerp(METAL_SHADE, clampf((p.y - body_c.y + 24.0) / 48.0, 0.0, 1.0)))
	c.draw_polygon(body, cols)
	for k in 4:                                           # Panel lines + rivets
		var x := body_c.x - 30.0 + float(k) * 18.0
		c.draw_line(Vector2(x, body_c.y - 24), Vector2(x + 4, body_c.y + 24), METAL_SHADE, 2.0)
		c.draw_circle(Vector2(x + 2, body_c.y - 14), 1.8, DARK)
	c.draw_colored_polygon(EnemyArt.ellipse_points(body_c + Vector2(12, 12), 22, 12, 16), DARK)   # Belly armor
	c.draw_circle(body_c + Vector2(12, 12), 5.0 + sin(t * 6.0), RED_GLOW)                   # Power core
	FighterArt.outline(c, body, 4.0)

	# --- Back laser cannon (missile launcher) ---
	var can_base := body_c + Vector2(-10, -28)
	var can_a := -2.0
	if pose == "missiles_tele":
		can_a = -1.6 - 0.1 * sin(pt * 40.0)
	elif pose == "missiles":
		can_a = -1.6
	var can_tip := can_base + Vector2.from_angle(can_a) * 40.0
	FighterArt.limb(c, can_base, can_tip, 14.0, DARK, EnemyArt.BLACK, METAL_SHADE)
	c.draw_circle(can_tip, 6.0, EnemyArt.BLACK)
	if pose == "missiles_tele" or pose == "missiles":
		c.draw_circle(can_tip, 4.0 + 3.0 * sin(t * 30.0), RED_GLOW)
	if pose == "missiles":
		for k in 3:
			c.draw_circle(can_tip + Vector2.from_angle(can_a) * (10.0 + pt * 200.0 + float(k) * 22.0), 5.0, Color(1.0, 0.6, 0.2, 0.8))
	FighterArt.rrect(c, Rect2(can_base.x - 10, can_base.y - 6, 20, 12), METAL, METAL_SHADE, METAL_HI, 4.0, 3.0)

	# --- Tiny arms ---
	FighterArt.limb(c, body_c + Vector2(30, 6), body_c + Vector2(42, 20), 7.0, METAL, METAL_SHADE, METAL_HI)
	c.draw_line(body_c + Vector2(42, 20), body_c + Vector2(47, 24), EnemyArt.BLACK, 3.0)

	# --- Neck + head with opening jaw ---
	var neck := body_c + Vector2(36, -16)
	var head := body_c + Vector2(62, -38)
	var open := 0.0
	if pose == "bite_tele":
		open = clampf(pt / 0.35, 0.0, 1.0)
	elif pose == "bite":
		open = 1.0 - clampf(pt / 0.25, 0.0, 1.0) * 0.8
	FighterArt.limb(c, neck, head + Vector2(-10, 8), 26.0, METAL, METAL_SHADE, METAL_HI)
	# Lower jaw
	var jaw_a := 0.45 * open
	var jaw_root := head + Vector2(-12, 10)
	var jaw := PackedVector2Array([jaw_root, jaw_root + Vector2(46, 2).rotated(jaw_a), jaw_root + Vector2(42, 12).rotated(jaw_a), jaw_root + Vector2(2, 12)])
	c.draw_colored_polygon(jaw, METAL_SHADE)
	FighterArt.outline(c, jaw, 3.5)
	for k in 4:
		var tp := jaw_root + Vector2(10 + float(k) * 9.0, 1).rotated(jaw_a)
		c.draw_colored_polygon(PackedVector2Array([tp, tp + Vector2(3, -6).rotated(jaw_a), tp + Vector2(6, 0).rotated(jaw_a)]), Color.WHITE)
	if open > 0.2:
		c.draw_circle(head + Vector2(26, 12), 6.0 * open, Color(RED_GLOW.r, RED_GLOW.g, RED_GLOW.b, 0.8))   # Laser charge
	# Upper skull
	var skull := PackedVector2Array([head + Vector2(-20, -12), head + Vector2(16, -16), head + Vector2(40, -6), head + Vector2(42, 8), head + Vector2(-14, 12)])
	c.draw_polygon(skull, PackedColorArray([METAL_HI, METAL_HI, METAL, METAL_SHADE, METAL_SHADE]))
	FighterArt.outline(c, skull, 4.0)
	for k in 4:
		var tp := head + Vector2(2 + float(k) * 9.0, 9)
		c.draw_colored_polygon(PackedVector2Array([tp, tp + Vector2(3, 6), tp + Vector2(6, 0)]), Color.WHITE)
	c.draw_line(head + Vector2(-6, -2), head + Vector2(30, -6), METAL_SHADE, 2.0)
	# Glowing red eye
	var eye := head + Vector2(8, -6)
	if dead:
		EnemyArt.ko_eye(c, eye, 5.0, t)
	else:
		c.draw_circle(eye, 9.0 + sin(t * 5.0), Color(RED_GLOW.r, RED_GLOW.g, RED_GLOW.b, 0.3))
		c.draw_circle(eye, 5.5, EnemyArt.BLACK)
		c.draw_circle(eye, 4.0, RED_EYE)
		c.draw_circle(eye + Vector2(-1, -1), 1.3, Color(1, 0.8, 0.8))
		c.draw_line(eye + Vector2(-7, -8), eye + Vector2(7, -5), EnemyArt.BLACK, 3.0)
