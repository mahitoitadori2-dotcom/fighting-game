class_name ForgeMother
extends SimpleEnemy
## FORGE MOTHER (renamed from Architectian Titan) - MINI-BOSS of Colosseum 3 (Level 17, the Blast Workshop).
## A huge forge-guardian in dark iron armour with brass plates and a FURNACE glowing in its
## chest, swinging a giant smithing hammer. Below 50% the furnace overheats (phase 2).
##
##   Hammer Slam          11 dmg + blast + shockwaves   BIG: the hammer comes down, the floor blasts
##   Hammer Sweep          8 dmg                         wide low sweep (jump it)
##   Workshop Explosion    8 dmg each                    BIG: the workshop blows up under you
##                                                       (glowing vents on the floor, then blasts)
##   Scrap Throw           5 dmg each                    hurls gears and metal plates in arcs

const SLAM_KB := Vector2(460, -420)
const SWEEP_KB := Vector2(420, -200)
const SCRAP_FLIGHT := 0.85

const IRON := Color(0.22, 0.22, 0.25)
const IRON_SHADE := Color(0.12, 0.12, 0.14)
const IRON_HI := Color(0.40, 0.40, 0.45)
const BRASS := Color(0.80, 0.60, 0.26)
const BRASS_SHADE := Color(0.50, 0.36, 0.12)
const FURNACE := Color(1.0, 0.55, 0.12)
const FURNACE_HI := Color(1.0, 0.9, 0.5)
const WOOD := Color(0.42, 0.28, 0.16)


func _make_data() -> CharacterData:
	keep_min = 0.0
	keep_max = 170.0
	attack_chance = 0.65
	phase2_threshold = 0.5
	phase2_speed_mult = 1.3
	phase2_cooldown_mult = 0.7
	knockback_scale = 0.1
	grab_immune = true
	var d := SimpleEnemy.make_data("Forge Mother", 210, Vector2(150, 290), 85.0)
	d.hitstun_time = 0.05
	d.respawn_delay = 99.0
	return d


static func make_patterns() -> Array[EnemyPattern]:
	var list: Array[EnemyPattern] = []
	#                          id          name                    cd    dmg  min   max     anim        tele  active rec   big   weights [P1,P2] armored
	list.append(EnemyPattern.make("slam", "HAMMER SLAM!", 3.2, 11, 0.0, 240.0, "slam", 0.75, 0.25, 0.75, true, [2.0, 2.0], true))
	list.append(EnemyPattern.make("sweep", "HAMMER SWEEP!", 3.6, 8, 0.0, 230.0, "sweep", 0.55, 0.30, 0.55, true, [1.4, 1.4], true))
	list.append(EnemyPattern.make("workshop", "WORKSHOP EXPLOSION!", 7.5, 8, 0.0, 1400.0, "workshop", 0.60, 1.00, 0.50, true, [1.0, 1.6], true))
	list.append(EnemyPattern.make("scrap", "SCRAP THROW!", 4.5, 5, 180.0, 1000.0, "scrap", 0.55, 0.30, 0.50, true, [1.4, 1.4], true))
	list[1].note = "low sweep: jump it"
	return list


func boss_title() -> String:
	return enemy_name.to_upper() + ("   -   PHASE 2: OVERHEATED FORGE" if enraged else "")


func custom_death_type(_hit: HitData) -> String:
	return DeathManager.EXPLODE


func flavor_lines() -> Array[String]:
	if enraged:
		return ["THE FORGE... BURNS... HOTTER!", "*roaring furnace*"]
	return ["*CLANG*", "THE FORGE... NEVER... COOLS.", "*hiss of steam*"]


func jump(_force_mult: float = 1.0) -> void:
	pass


func _on_phase_changed(_p: int) -> void:
	Effects.popup(self, global_position + Vector2(0, -360), "OVERHEATED!", FURNACE, 32)
	Effects.explosion(self, global_position + Vector2(0, -180), 120.0, true, true)
	SoundManager.play_sfx("roar")


func _attack(p: EnemyPattern) -> void:
	match p.id:
		"slam":
			var hx := global_position.x + facing * 150.0
			hit_in_radius(Vector2(hx, global_position.y - 50.0), 120.0, dmg(p), SLAM_KB, "forge_slam")
			Effects.explosion(self, Vector2(hx, global_position.y - 30.0), 130.0, true, true)
			for d in [-1.0, 1.0]:
				var s := spawn_projectile()
				s.kind = EnemyProjectile.Kind.LINEAR
				s.look = "shock"
				s.tint = FURNACE
				s.dir = d
				s.speed = 540.0
				s.lifetime = 1.0
				s.size = Vector2(46, 34)
				s.damage = maxi(1, dmg(p) / 2)
				s.knockback = Vector2(220, -300)
				s.move = "forge_shock"
				launch(s, Vector2(hx + d * 70.0, global_position.y - 12.0))
			Effects.shake(self, 16.0)
			SoundManager.play_sfx("slam")
			SoundManager.play_sfx("explosion", -4.0)
		"sweep":
			hitbox.activate(make_hit(dmg(p), Vector2(facing * SWEEP_KB.x, SWEEP_KB.y), "forge_sweep"),
				Vector2(facing * 110.0, -36.0), Vector2(240, 64))
			SoundManager.play_sfx("whoosh")
		"workshop":
			var tx := target_x()
			var n := 6 if enraged else 4
			for k in n:
				var off := (float(k) - float(n - 1) * 0.5) * 160.0 + randf_range(-30.0, 30.0)
				var x := clamp_to_ground(tx + off)
				if StoryManager.has_walls:
					x = clampf(x, StoryManager.wall_left_x + 60.0, StoryManager.wall_right_x - 60.0)
				BossHazard.spawn(self, "blast", Vector2(x, global_position.y), 0.8 + 0.12 * float(k), dmg(p), Vector2(260, -480))
			SoundManager.play_sfx("rumble", -3.0)
		"scrap":
			var n2 := 4 if enraged else 3
			for k in n2:
				var spread := (float(k) - float(n2 - 1) * 0.5) * 120.0 + randf_range(-20.0, 20.0)
				_throw_scrap(target_x() + spread, dmg(p))
			SoundManager.play_sfx("whoosh", -4.0)


func _throw_scrap(to_x: float, damage: int) -> void:
	var r := spawn_projectile()
	r.kind = EnemyProjectile.Kind.ARC
	r.look = "scrap"
	r.dir = signf(to_x - global_position.x) if to_x != global_position.x else 1.0
	r.damage = damage
	r.knockback = Vector2(220, -200)
	r.radius = 40.0
	r.pierce = false
	r.size = Vector2(44, 44)
	r.lifetime = 3.0
	r.move = "forge_scrap"
	var from := global_position + Vector2(facing * 60.0, -260.0)
	var drop := global_position.y - from.y
	var t := SCRAP_FLIGHT
	r.arc_velocity = Vector2((to_x - from.x) / t, (drop - 0.5 * EnemyProjectile.ARC_GRAVITY * t * t) / t)
	launch(r, from)


# ============================================================
# ART (facing right, origin = feet, ~200 x 320)
# ============================================================
func draw_model_on(c: CanvasItem) -> void:
	draw_forge_mother(c, art_state())


static func draw_portrait(c: CanvasItem, t: float) -> void:
	draw_forge_mother(c, {"t": t, "pose": "idle"})


static func draw_forge_mother(c: CanvasItem, s: Dictionary) -> void:
	var t: float = s.get("t", 0.0)
	var pose: String = s.get("pose", "idle")
	var pt: float = s.get("pose_t", 0.0)
	var dead: bool = s.get("dead", false)
	var hot: bool = s.get("enraged", false)
	var fire := Color(1.0, 0.35, 0.08) if hot else FURNACE
	var breathe := sin(t * 1.6) * 3.0
	EnemyArt.legs(c, s, -120.0, 34.0, 28.0, IRON, IRON_SHADE, IRON_HI, IRON_SHADE, 40.0)
	var chest := Vector2(0, -200 + breathe)
	# Far arm
	EnemyArt.arm(c, chest + Vector2(-60, -50), chest + Vector2(-80, 50), 22.0, IRON_SHADE, IRON_SHADE.darkened(0.2), IRON, IRON_SHADE, 22.0)
	# Torso: armoured barrel with brass plates and a FURNACE door
	var torso := PackedVector2Array([chest + Vector2(-80, -70), chest + Vector2(80, -70), chest + Vector2(70, 80), chest + Vector2(-70, 80)])
	c.draw_polygon(torso, PackedColorArray([IRON_HI, IRON_HI, IRON, IRON]))
	for k in 3:
		c.draw_line(chest + Vector2(-76, -50 + float(k) * 50.0), chest + Vector2(76, -50 + float(k) * 50.0), BRASS_SHADE, 8.0)
		c.draw_line(chest + Vector2(-76, -52 + float(k) * 50.0), chest + Vector2(76, -52 + float(k) * 50.0), BRASS, 3.0)
	var door := FighterArt.rrect_points(Rect2(chest.x - 34, chest.y - 30, 68, 60), 10.0)
	c.draw_colored_polygon(door, IRON_SHADE)
	var flick := 0.8 + 0.2 * sin(t * 18.0)
	c.draw_colored_polygon(FighterArt.rrect_points(Rect2(chest.x - 26, chest.y - 22, 52, 44), 8.0), Color(fire.r, fire.g * flick, fire.b, 1.0))
	c.draw_circle(chest + Vector2(0, 4), 14.0, FURNACE_HI)
	for k in 4:                                                                     # Grate
		c.draw_line(chest + Vector2(-26 + float(k) * 17.0, -22), chest + Vector2(-26 + float(k) * 17.0, 22), IRON_SHADE, 3.0)
	FighterArt.outline(c, door, 3.0)
	FighterArt.outline(c, torso, 6.0)
	# Chimney stacks on the shoulders, smoking
	for side in [-1.0, 1.0]:
		var base := chest + Vector2(side * 56.0, -70)
		c.draw_rect(Rect2(base.x - 10, base.y - 44, 20, 44), IRON_SHADE)
		c.draw_rect(Rect2(base.x - 10, base.y - 44, 20, 44), EnemyArt.BLACK, false, 3.0)
		var puff := fmod(t * 0.9 + (0.5 if side > 0.0 else 0.0), 1.0)
		c.draw_circle(base + Vector2(sin(t) * 6.0, -54.0 - puff * 60.0), 10.0 + puff * 16.0, Color(0.25, 0.22, 0.22, 0.5 * (1.0 - puff)))
	# Head: small riveted helm with a glowing visor slit
	var head := chest + Vector2(10, -92)
	var helm := FighterArt.rrect_points(Rect2(head.x - 30, head.y - 30, 60, 52), 12.0)
	c.draw_colored_polygon(helm, IRON)
	FighterArt.outline(c, helm, 4.0)
	if dead:
		EnemyArt.ko_eye(c, head + Vector2(10, -4), 5.0, t)
	else:
		c.draw_rect(Rect2(head.x - 6, head.y - 8, 32, 8), fire)
	# Hammer arm + the giant hammer
	var hand := chest + Vector2(80, 40)
	var ang := -1.6
	match pose:
		"slam_tele":
			hand = chest + Vector2(20, -110)
			ang = -2.2
		"slam":
			hand = chest + Vector2(110, 60)
			ang = 0.25
		"sweep_tele":
			hand = chest + Vector2(-60, 60)
			ang = PI
		"sweep":
			var k := clampf(pt / 0.3, 0.0, 1.0)
			hand = chest + Vector2(lerpf(-40.0, 120.0, k), 120)
			ang = lerpf(PI, 0.0, k)
		"workshop_tele", "workshop":
			hand = chest + Vector2(60, 110)
			ang = PI * 0.5
		"scrap_tele":
			hand = chest + Vector2(-50, -60)
		"scrap":
			hand = chest + Vector2(110, -40)
	var d := Vector2.from_angle(ang)
	var n := d.orthogonal()
	var hh := hand + d * 120.0
	c.draw_line(hand - d * 20.0, hh, EnemyArt.BLACK, 14.0)
	c.draw_line(hand - d * 20.0, hh, WOOD, 9.0)
	var block := PackedVector2Array([hh + n * 46.0 - d * 26.0, hh + n * 46.0 + d * 26.0, hh - n * 46.0 + d * 26.0, hh - n * 46.0 - d * 26.0])
	c.draw_colored_polygon(block, IRON_HI)
	c.draw_line(hh + n * 46.0, hh - n * 46.0, BRASS, 6.0)
	c.draw_line(hh + n * 44.0 + d * 24.0, hh - n * 44.0 + d * 24.0, Color(fire.r, fire.g, fire.b, 0.7), 4.0)   # Glowing face
	FighterArt.outline(c, block, 4.0)
	EnemyArt.arm(c, chest + Vector2(62, -50), hand, 24.0, IRON, IRON_SHADE, IRON_HI, IRON, 24.0)
	if pose == "slam" and pt < 0.25:
		c.draw_arc(Vector2(150, 0), 30.0 + pt * 320.0, PI, TAU, 18, Color(fire.r, fire.g, fire.b, 1.0 - pt * 4.0), 7.0, true)
