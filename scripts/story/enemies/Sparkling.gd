class_name Sparkling
extends SimpleEnemy
## SPARKLING (Story Mode, Colosseum 3): a tiny ball of living electricity with two bright
## eyes, crackling arcs and little sparking legs. FAST. Zips at you, or charges up and bursts.
##
##   Spark Dash    4 dmg, 1.8 s - zips straight through you
##   Spark Burst   6 dmg, 3.2 s - BIG: glows brighter, then explodes in a ring of sparks

const DASH_SPEED := 760.0
const DASH_KB := Vector2(220, -150)
const BURST_R := 95.0
const BURST_KB := Vector2(300, -260)

const CORE := Color(1.0, 0.95, 0.5)
const GLOW := Color(0.45, 0.8, 1.0)
const ARC_COL := Color(0.8, 0.95, 1.0)


func _make_data() -> CharacterData:
	keep_min = 40.0
	keep_max = 230.0
	attack_chance = 0.7
	phase2_threshold = -1.0
	var d := SimpleEnemy.make_data("Sparkling", 8, Vector2(40, 36), 340.0)
	d.respawn_delay = 1.0
	return d


static func make_patterns() -> Array[EnemyPattern]:
	var list: Array[EnemyPattern] = []
	#                          id      name            cd    dmg  min   max    anim    tele  active rec   big    weights
	list.append(EnemyPattern.make("dash", "SPARK DASH", 1.8, 4, 60.0, 320.0, "dash", 0.30, 0.35, 0.40, false, [2.0, 2.0]))
	list.append(EnemyPattern.make("burst", "SPARK BURST!", 3.2, 6, 0.0, 120.0, "burst", 0.60, 0.15, 0.50, true, [1.4, 1.4]))
	return list


func flavor_lines() -> Array[String]:
	return ["*bzzt*", "*crackle*", "zzZZT!"]


func _attack(p: EnemyPattern) -> void:
	match p.id:
		"dash":
			hitbox.activate(make_hit(dmg(p), Vector2(facing * DASH_KB.x, DASH_KB.y), "spark_dash"),
				Vector2(facing * 10.0, -20.0), Vector2(52, 40))
			Effects.trail(visuals, GLOW, 12.0, 8)
			SoundManager.play_sfx("laser", -9.0)
		"burst":
			hit_in_radius(global_position + Vector2(0, -18), BURST_R, dmg(p), BURST_KB, "spark_burst")
			Effects.hit_sparks(self, global_position + Vector2(0, -18), 14, 1.4)
			Effects.shake(self, 5.0)
			SoundManager.play_sfx("spark")


func _on_attack_update(p: EnemyPattern, _delta: float) -> void:
	if p.id == "dash":
		velocity.x = facing * DASH_SPEED
		if is_on_wall() or not ground_ahead(30.0):
			state_time = state_len


func _owns_velocity_x() -> bool:
	return estate == EState.ATTACK and current != null and current.id == "dash"


# ============================================================
# ART (facing right, origin = feet, ~44 x 44)
# ============================================================
func draw_model_on(c: CanvasItem) -> void:
	draw_sparkling(c, art_state())


static func draw_portrait(c: CanvasItem, t: float) -> void:
	draw_sparkling(c, {"t": t, "pose": "idle"})


static func draw_sparkling(c: CanvasItem, s: Dictionary) -> void:
	var t: float = s.get("t", 0.0)
	var pose_v: String = s.get("pose", "idle")
	var pt: float = s.get("pose_t", 0.0)
	var dead: bool = s.get("dead", false)
	var hop := absf(sin(t * 9.0)) * 4.0
	var charge := clampf(pt / 0.6, 0.0, 1.0) if pose_v == "burst_tele" else 0.0
	var center := Vector2(0, -20 - hop)
	var r := 13.0 + charge * 4.0
	# Sparking legs
	for k in 3:
		var a := PI * 0.5 + (float(k) - 1.0) * 0.6
		c.draw_line(center, Vector2(cos(a) * 10.0, -2.0), ARC_COL, 2.0)
	# Glow + crackling arcs
	c.draw_circle(center, r * 2.0, Color(GLOW.r, GLOW.g, GLOW.b, 0.18 + 0.25 * charge))
	for k in 5:
		var a := t * 7.0 + float(k) * TAU / 5.0
		var p0 := center + Vector2.from_angle(a) * r
		var p1 := center + Vector2.from_angle(a + 0.3) * (r + 9.0 + 4.0 * sin(t * 30.0 + float(k)))
		var p2 := center + Vector2.from_angle(a + 0.1) * (r + 16.0)
		c.draw_polyline(PackedVector2Array([p0, p1, p2]), ARC_COL, 2.0)
	var body := EnemyArt.star_points(center, r + 3.0, 8, 0.7, t * 3.0)
	c.draw_colored_polygon(body, GLOW)
	c.draw_circle(center, r * 0.75, CORE)
	FighterArt.outline(c, body, 2.5)
	if dead:
		EnemyArt.ko_eye(c, center + Vector2(4, -2), 2.5, t)
	else:
		c.draw_circle(center + Vector2(1, -2), 3.0, EnemyArt.BLACK)
		c.draw_circle(center + Vector2(8, -2), 3.0, EnemyArt.BLACK)
		c.draw_circle(center + Vector2(2, -3), 1.0, Color.WHITE)
		c.draw_circle(center + Vector2(9, -3), 1.0, Color.WHITE)
	if pose_v == "burst" and pt < 0.3:
		c.draw_arc(center, 20.0 + pt * 260.0, 0.0, TAU, 24, Color(1, 1, 0.7, 1.0 - pt * 3.3), 5.0, FighterArt.AA)
	if pose_v == "dash":
		for i in 3:
			c.draw_line(Vector2(-18 - float(i) * 8.0, -24 + float(i) * 6.0), Vector2(-40 - float(i) * 8.0, -24 + float(i) * 6.0), Color(GLOW.r, GLOW.g, GLOW.b, 0.7), 3.0)
