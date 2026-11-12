class_name ArchitectsGolem
extends SimpleEnemy
## ARCHITECT'S GOLEM - BOSS of Colosseum 3 (Level 18, the Golem's Hall).
## A massive golem of carved stone blocks bolted together with white-and-green metal plates,
## built by the Architect. Blue RUNES glow along its body, an architect's mark (gear + compass)
## shines on its chest, and its fists are as big as a man. Below 50% the runes burn orange
## (phase 2: faster, more blocks, a triple rune blast).
##
##   Golem Slam        12 dmg              BIG: both fists come down in front of it
##   Rock Throw        6 dmg per block     hurls stone blocks in arcs (block / dodge)
##   Rune Blast        8 dmg               shoots rune energy straight along the floor (P2: 3 high/low)
##   Stomp Shockwave   7 dmg               BIG: stomps, shockwaves roll both ways (jump them)

const SLAM_KB := Vector2(480, -440)
const BLOCK_FLIGHT := 0.9

const STONE := Color(0.58, 0.56, 0.52)
const STONE_SHADE := Color(0.38, 0.36, 0.34)
const STONE_HI := Color(0.74, 0.72, 0.68)
const PLATE := Color(0.94, 0.95, 0.97)
const GREEN := Color(0.22, 0.86, 0.28)
const RUNE := Color(0.35, 0.80, 1.0)
const RUNE_HOT := Color(1.0, 0.55, 0.15)


func _make_data() -> CharacterData:
	keep_min = 60.0
	keep_max = 220.0
	attack_chance = 0.65
	phase2_threshold = 0.5
	phase2_speed_mult = 1.3
	phase2_cooldown_mult = 0.7
	knockback_scale = 0.05
	grab_immune = true
	var d := SimpleEnemy.make_data("The Architect's Golem", 280, Vector2(190, 320), 90.0)
	d.hitstun_time = 0.04
	d.respawn_delay = 99.0
	return d


static func make_patterns() -> Array[EnemyPattern]:
	var list: Array[EnemyPattern] = []
	#                          id       name                 cd    dmg  min    max     anim     tele  active rec   big   weights [P1,P2] armored
	list.append(EnemyPattern.make("slam", "GOLEM SLAM!", 3.4, 12, 0.0, 260.0, "slam", 0.80, 0.25, 0.80, true, [2.0, 2.0], true))
	list.append(EnemyPattern.make("rocks", "ROCK THROW!", 4.2, 6, 200.0, 1100.0, "rocks", 0.60, 0.30, 0.50, true, [1.6, 1.6], true))
	list.append(EnemyPattern.make("rune", "RUNE BLAST!", 3.8, 8, 0.0, 1100.0, "rune", 0.60, 0.40, 0.50, true, [1.4, 1.8], true))
	list.append(EnemyPattern.make("stomp", "STOMP SHOCKWAVE!", 5.0, 7, 0.0, 700.0, "stomp", 0.65, 0.20, 0.60, true, [1.2, 1.5], true))
	list[3].note = "shockwaves along the floor: jump them"
	return list


func boss_title() -> String:
	return enemy_name.to_upper() + ("   -   PHASE 2: RUNES ABLAZE" if enraged else "")


func custom_death_type(_hit: HitData) -> String:
	return DeathManager.CUTSCENE


func flavor_lines() -> Array[String]:
	if enraged:
		return ["...PROTOCOL: DESTROY...", "*grinding stone*"]
	return ["...INTRUDER...", "*the runes hum*", "...DISMANTLE..."]


func jump(_force_mult: float = 1.0) -> void:
	pass


func _on_phase_changed(_p: int) -> void:
	Effects.popup(self, global_position + Vector2(0, -380), "RUNES ABLAZE!", RUNE_HOT, 32)
	Effects.shake(self, 14.0)
	SoundManager.play_sfx("roar")
	SoundManager.play_sfx("ultimate", -4.0)


func _attack(p: EnemyPattern) -> void:
	match p.id:
		"slam":
			var hx := global_position.x + facing * 170.0
			hit_in_radius(Vector2(hx, global_position.y - 60.0), 140.0, dmg(p), SLAM_KB, "golem_slam")
			Effects.hit_sparks(self, Vector2(hx, global_position.y - 10.0), 16, 1.6)
			Effects.shake(self, 18.0)
			SoundManager.play_sfx("slam")
			SoundManager.play_sfx("stone", -2.0)
		"rocks":
			var n := 4 if enraged else 3
			for k in n:
				var spread := (float(k) - float(n - 1) * 0.5) * 130.0 + randf_range(-20.0, 20.0)
				_throw_block(target_x() + spread, dmg(p))
			SoundManager.play_sfx("stone", -4.0)
		"rune":
			var heights := [-60.0, -150.0, -24.0] if enraged else [-60.0]
			for h in heights:
				var r := spawn_projectile()
				r.kind = EnemyProjectile.Kind.LINEAR
				r.look = "rune"
				r.tint = RUNE_HOT if enraged else RUNE
				r.dir = float(facing)
				r.speed = 620.0
				r.lifetime = 1.6
				r.size = Vector2(60, 44)
				r.damage = dmg(p)
				r.knockback = Vector2(300, -200)
				r.pierce = false
				r.move = "rune_blast"
				launch(r, global_position + Vector2(facing * 120.0, float(h)))
			SoundManager.play_sfx("beam", -3.0)
		"stomp":
			for d in [-1.0, 1.0]:
				for wave in (2 if enraged else 1):
					var s := spawn_projectile()
					s.kind = EnemyProjectile.Kind.LINEAR
					s.look = "shock"
					s.tint = RUNE_HOT if enraged else RUNE
					s.dir = d
					s.speed = 520.0 - float(wave) * 160.0
					s.lifetime = 1.3
					s.size = Vector2(50, 36)
					s.damage = dmg(p)
					s.knockback = Vector2(240, -320)
					s.move = "golem_stomp"
					launch(s, global_position + Vector2(d * 110.0, -12.0))
			Effects.shake(self, 16.0)
			SoundManager.play_sfx("slam")


func _throw_block(to_x: float, damage: int) -> void:
	var r := spawn_projectile()
	r.kind = EnemyProjectile.Kind.ARC
	r.look = "stone_block"
	r.dir = signf(to_x - global_position.x) if to_x != global_position.x else 1.0
	r.damage = damage
	r.knockback = Vector2(240, -220)
	r.radius = 48.0
	r.pierce = false
	r.size = Vector2(56, 56)
	r.lifetime = 3.0
	r.move = "golem_block"
	var from := global_position + Vector2(facing * 80.0, -300.0)
	var drop := global_position.y - from.y
	var t := BLOCK_FLIGHT
	r.arc_velocity = Vector2((to_x - from.x) / t, (drop - 0.5 * EnemyProjectile.ARC_GRAVITY * t * t) / t)
	launch(r, from)


# ============================================================
# ART (facing right, origin = feet, ~240 x 340)
# ============================================================
func draw_model_on(c: CanvasItem) -> void:
	draw_golem(c, art_state())


static func draw_portrait(c: CanvasItem, t: float) -> void:
	draw_golem(c, {"t": t, "pose": "idle"})


static func _block(c: CanvasItem, r: Rect2, col: Color) -> void:
	var pts := FighterArt.rrect_points(r, 6.0)
	c.draw_colored_polygon(pts, col)
	c.draw_line(r.position + Vector2(4, 4), Vector2(r.end.x - 4, r.position.y + 4), STONE_HI, 3.0)
	FighterArt.outline(c, pts, 4.0)


static func draw_golem(c: CanvasItem, s: Dictionary) -> void:
	var t: float = s.get("t", 0.0)
	var pose_v: String = s.get("pose", "idle")
	var pt: float = s.get("pose_t", 0.0)
	var dead: bool = s.get("dead", false)
	var hot: bool = s.get("enraged", false)
	var rune := RUNE_HOT if hot else RUNE
	var pulse := 0.6 + 0.4 * sin(t * (6.0 if hot else 2.5))
	var stomp := 0.0
	if pose_v == "stomp_tele":
		stomp = clampf(pt / 0.65, 0.0, 1.0)
	# Legs: stacked blocks (front leg lifts for the stomp)
	_block(c, Rect2(-70, -110, 56, 110), STONE_SHADE)
	_block(c, Rect2(14, -110 - stomp * 50.0, 56, 110), STONE)
	c.draw_line(Vector2(-42, -90), Vector2(-42, -30), Color(rune.r, rune.g, rune.b, pulse), 3.0)
	# Torso: big stone block with a white/green metal chest plate
	var chest := Vector2(0, -220)
	_block(c, Rect2(chest.x - 100, chest.y - 90, 200, 180), STONE)
	var plate := FighterArt.rrect_points(Rect2(chest.x - 60, chest.y - 64, 120, 100), 10.0)
	c.draw_colored_polygon(plate, PLATE)
	c.draw_line(chest + Vector2(-60, -60), chest + Vector2(60, -60), GREEN, 5.0)
	FighterArt.outline(c, plate, 4.0)
	# The Architect's mark: a gear with a compass inside, glowing
	var mark := chest + Vector2(0, -14)
	c.draw_circle(mark, 40.0, Color(rune.r, rune.g, rune.b, 0.15 * pulse))
	var gear := PackedVector2Array()
	for i in 20:
		var a := TAU * float(i) / 20.0 + t * 0.3
		gear.append(mark + Vector2.from_angle(a) * (30.0 if i % 2 == 0 else 24.0))
	c.draw_colored_polygon(gear, GREEN)
	c.draw_circle(mark, 18.0, Color(0.12, 0.13, 0.16))
	c.draw_polyline(PackedVector2Array([mark + Vector2(-10, 12), mark + Vector2(0, -14), mark + Vector2(10, 12)]), rune, 3.0, FighterArt.AA)   # Compass
	c.draw_circle(mark + Vector2(0, -14), 3.0, rune)
	# Rune lines carved into the stone
	for k in 4:
		var rx := chest.x - 86.0 + float(k) * 56.0
		if k == 1 or k == 2:
			continue
		var pts := PackedVector2Array([Vector2(rx, chest.y - 70), Vector2(rx + 8, chest.y - 40), Vector2(rx, chest.y - 10), Vector2(rx + 8, chest.y + 20), Vector2(rx, chest.y + 50)])
		c.draw_polyline(pts, Color(rune.r, rune.g, rune.b, pulse), 4.0, FighterArt.AA)
	# Head: a smaller block with one long rune visor
	var head := chest + Vector2(16, -130)
	_block(c, Rect2(head.x - 46, head.y - 40, 92, 76), STONE_SHADE)
	if dead:
		c.draw_line(head + Vector2(-30, -4), head + Vector2(36, -4), EnemyArt.BLACK, 5.0)
	else:
		c.draw_rect(Rect2(head.x - 32, head.y - 10, 70, 12), Color(rune.r, rune.g, rune.b, 0.4))
		c.draw_rect(Rect2(head.x - 30, head.y - 7, 66, 6), rune)
	# Arms: segments + HUGE fists
	var far_fist := chest + Vector2(-130, 60)
	var fist := chest + Vector2(130, 70)
	match pose_v:
		"slam_tele":
			far_fist = chest + Vector2(-20, -170)
			fist = chest + Vector2(60, -180)
		"slam":
			far_fist = chest + Vector2(130, 190)
			fist = chest + Vector2(200, 190)
		"rocks_tele":
			fist = chest + Vector2(-60, -140)
		"rocks":
			fist = chest + Vector2(170, -80)
		"rune_tele", "rune":
			fist = chest + Vector2(170, 20)
	for pair in [[chest + Vector2(-96, -60), far_fist, STONE_SHADE], [chest + Vector2(96, -60), fist, STONE]]:
		var sh: Vector2 = pair[0]
		var fp: Vector2 = pair[1]
		var col: Color = pair[2]
		var elbow := sh.lerp(fp, 0.5) + Vector2(0, 20)
		for seg in [[sh, elbow], [elbow, fp]]:
			var a: Vector2 = seg[0]
			var b: Vector2 = seg[1]
			c.draw_line(a, b, EnemyArt.BLACK, 42.0)
			c.draw_line(a, b, col, 34.0)
		FighterArt.ball(c, elbow, 22.0, PLATE, Color(0.7, 0.74, 0.8), Color.WHITE)
		_block(c, Rect2(fp.x - 40, fp.y - 40, 80, 80), col)
		c.draw_line(fp + Vector2(-26, 0), fp + Vector2(26, 0), Color(rune.r, rune.g, rune.b, pulse), 3.0)
	if pose_v == "rune" and pt < 0.3:
		c.draw_circle(fist + Vector2(40, 0), 30.0 + pt * 60.0, Color(rune.r, rune.g, rune.b, 0.7 - pt * 2.0))
	if pose_v == "slam" and pt < 0.25:
		c.draw_arc(Vector2(170, 0), 40.0 + pt * 360.0, PI, TAU, 18, Color(0.85, 0.8, 0.7, 1.0 - pt * 4.0), 8.0, FighterArt.AA)
	if pose_v == "stomp" and pt < 0.25:
		c.draw_arc(Vector2(40, 0), 40.0 + pt * 400.0, PI, TAU, 18, Color(rune.r, rune.g, rune.b, 1.0 - pt * 4.0), 8.0, FighterArt.AA)
