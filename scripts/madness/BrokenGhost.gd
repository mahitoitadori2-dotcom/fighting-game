class_name BrokenGhost
extends SimpleEnemy
## BROKEN GHOST (Madness): a Weird Creature's body, FULLY BLACK, RED EYES and a RED BROKEN HALO (a cracked
## ring, a piece missing, hanging crooked). It floats on a smoky trail and keeps its distance.
##
##   Wail       4 dmg, 2.4 s - a slow screaming wave flies at you
##   Flicker    5 dmg, 5.0 s - it vanishes and appears BEHIND you, then claws

const HOVER := 80.0

var _floor := INF


func _make_data() -> CharacterData:
	keep_min = 220.0
	keep_max = 420.0
	attack_chance = 0.6
	phase2_threshold = -1.0
	return SimpleEnemy.make_data("Broken Ghost", 20, Vector2(48, 110), 200.0)


static func make_patterns() -> Array[EnemyPattern]:
	var list: Array[EnemyPattern] = []
	list.append(EnemyPattern.make("wail", "WAIL", 2.4, 4, 100.0, 700.0, "wail", 0.45, 0.20, 0.45, false, [2.0, 2.0]))
	list.append(EnemyPattern.make("flicker", "FLICKER!", 5.0, 5, 0.0, 600.0, "flicker", 0.55, 0.20, 0.45, true, [1.0, 1.0]))
	return list


func jump(_force_mult: float = 1.0) -> void:
	pass                                                  # It floats


func _movement(delta: float) -> void:
	super._movement(delta)
	if _floor == INF:
		if is_on_floor():
			_floor = global_position.y
		return
	velocity.y = (_floor - HOVER + sin(anim_time * 2.2) * 12.0 - global_position.y) * 5.0


func _attack(p: EnemyPattern) -> void:
	match p.id:
		"wail":
			var b := spawn_projectile()
			b.kind = EnemyProjectile.Kind.LINEAR
			b.look = "void_bolt"
			b.dir = float(facing)
			b.speed = 340.0
			b.lifetime = 2.4
			b.size = Vector2(36, 36)
			b.damage = dmg(p)
			b.knockback = Vector2(200, -140)
			b.pierce = false
			b.move = "ghost_wail"
			launch(b, global_position + Vector2(facing * 30.0, -40.0))
			SoundManager.play_sfx("void_goo", -8.0)
		"flicker":
			var tx := target_x()
			global_position.x = clamp_to_ground(tx + (70.0 if global_position.x < tx else -70.0))   # Behind you
			facing = -1 if global_position.x > tx else 1
			hitbox.activate(make_hit(dmg(p), Vector2(facing * 220.0, -160.0), "ghost_flicker"), Vector2(facing * 34.0, -40.0), Vector2(60, 60))
			Effects.void_burst(self, global_position + Vector2(0, -40), 50.0)


func flavor_lines() -> Array[String]:
	return ["...it hurts...", "*a broken hymn*", "...where is the light..."]


# ============================================================
# ART (facing right, origin = bottom of the sheet, ~60 x 110)
# ============================================================
func draw_model_on(c: CanvasItem) -> void:
	draw_ghost(c, art_state())


static func draw_portrait(c: CanvasItem, t: float) -> void:
	draw_ghost(c, {"t": t, "pose": "idle"})


## (2026-11-21, by the user) The SAME body as a Weird Creature - a torso, a skull head, small floating
## hands - but FULLY BLACK with RED EYES and a RED BROKEN HALO. No feet: it floats on a smoky trail.
static func draw_ghost(c: CanvasItem, s: Dictionary) -> void:
	var t: float = s.get("t", 0.0)
	var pose_v: String = s.get("pose", "idle")
	var flick := 0.3 if pose_v == "flicker_tele" and fmod(t * 14.0, 1.0) < 0.5 else 1.0
	# Smoke trail where the legs would be
	for i in 5:
		var k := float(i) / 4.0
		c.draw_circle(Vector2(sin(t * 4.0 + k * 3.0) * 6.0, -10.0 - k * 26.0), (5.0 + k * 9.0), Color(0.02, 0.0, 0.0, (0.75 - k * 0.4) * flick))
	var st := s.duplicate()
	st["bone"] = Color(0.07, 0.05, 0.05, flick)
	st["bone_shade"] = Color(0.02, 0.01, 0.01, flick)
	st["flesh"] = Color(0.0, 0.0, 0.0, flick)
	st["eye"] = Color(1.0, 0.05, 0.03)
	st["no_feet"] = true
	WeirdCreature.draw_creature(c, st, 1.0, false)
	# Red glow in the sockets (the pinprick eyes alone are too small on a black skull)
	var lean := 0.25 if bool(s.get("moving", false)) or pose_v in ["pounce", "frenzy"] else 0.0   # (Same as the body)
	var hc := Vector2(4.0 + lean * 30.0, -98) + Vector2(0, sin(t * 3.0) * 2.0)
	for ex: float in [-1.0, 7.0]:
		c.draw_circle(hc + Vector2(ex, -2), 4.0, Color(1.0, 0.05, 0.03, 0.5 * flick))
		c.draw_circle(hc + Vector2(ex + 1.0, -2), 2.0, Color(1.0, 0.2, 0.1, flick))
	# The RED BROKEN HALO: a cracked ring, a piece missing, hanging crooked
	var halo := hc + Vector2(-2, -26)
	var tilt := 0.35 + sin(t * 1.3) * 0.08
	c.draw_set_transform(halo, tilt, Vector2(1.0, 0.35))
	c.draw_arc(Vector2.ZERO, 18.0, 0.6, TAU - 0.2, 20, Color(0, 0, 0), 7.0)
	c.draw_arc(Vector2.ZERO, 18.0, 0.6, TAU - 0.2, 20, Color(0.95, 0.06, 0.04), 4.0)
	c.draw_line(Vector2(15, 9), Vector2(19, 4), Color(0, 0, 0), 2.0)
	c.draw_set_transform(Vector2.ZERO, 0.0, Vector2.ONE)
	c.draw_colored_polygon(PackedVector2Array([halo + Vector2(16, 4), halo + Vector2(22, 10), halo + Vector2(18, 14)]), Color(0.6, 0.03, 0.02))