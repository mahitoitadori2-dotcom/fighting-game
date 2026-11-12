class_name VoidSoul
extends SimpleEnemy
## VOID SOUL (Story Mode, Colosseum 4 - the Void): a floating lost soul - a dark violet flame
## with a pale face and a wispy tail. It HOVERS above the bones and keeps its distance,
## shooting VOID BOLTS.
##
##   Void Bolt    4 dmg, 2.2 s - a slow orb of void flying straight at you
##   Soul Burst   5 dmg, 4.5 s - when you get close: a burst of void around it

const HOVER := 70.0                      # Height above the floor
const BOLT_KB := Vector2(200, -150)
const BURST_R := 90.0

const FLAME := Color(0.30, 0.10, 0.55)
const FLAME_HI := Color(0.60, 0.35, 0.95)
const FACE := Color(0.85, 0.82, 0.92)

var _floor := INF


func _make_data() -> CharacterData:
	keep_min = 240.0
	keep_max = 460.0
	attack_chance = 0.55
	phase2_threshold = -1.0
	return SimpleEnemy.make_data("Void Soul", 16, Vector2(50, 60), 160.0)


static func make_patterns() -> Array[EnemyPattern]:
	var list: Array[EnemyPattern] = []
	#                          id       name          cd    dmg  min    max    anim     tele  active rec   big    weights
	list.append(EnemyPattern.make("bolt", "VOID BOLT", 2.2, 4, 100.0, 750.0, "bolt", 0.45, 0.20, 0.45, false, [2.0, 2.0]))
	list.append(EnemyPattern.make("burst", "SOUL BURST!", 4.5, 5, 0.0, 110.0, "burst", 0.50, 0.15, 0.45, true, [1.4, 1.4]))
	return list


func flavor_lines() -> Array[String]:
	return ["...cold...", "*soft wailing*", "...lost..."]


func jump(_force_mult: float = 1.0) -> void:
	pass                                   # It floats


func _movement(delta: float) -> void:
	super._movement(delta)
	if _floor == INF:
		if is_on_floor():
			_floor = global_position.y         # Landed once: from now on it hovers
		return
	var goal := _floor - HOVER + sin(anim_time * 2.0) * 10.0
	velocity.y = (goal - global_position.y) * 5.0


func _attack(p: EnemyPattern) -> void:
	match p.id:
		"bolt":
			var b := spawn_projectile()
			b.kind = EnemyProjectile.Kind.LINEAR
			b.look = "void_bolt"
			b.dir = float(facing)
			b.speed = 380.0
			b.lifetime = 2.2
			b.size = Vector2(30, 30)
			b.damage = dmg(p)
			b.knockback = BOLT_KB
			b.pierce = false
			b.move = "void_bolt"
			var y := (_floor if _floor != INF else global_position.y) - 60.0
			launch(b, Vector2(global_position.x + facing * 30.0, y))
			SoundManager.play_sfx("void_goo", -9.0)
		"burst":
			hit_in_radius(global_position + Vector2(0, -30), BURST_R, dmg(p), Vector2(240, -200), "soul_burst")
			Effects.void_burst(self, global_position + Vector2(0, -30), BURST_R)


# ============================================================
# ART (facing right, origin = "feet" = bottom of the flame, ~60 x 80)
# ============================================================
func draw_model_on(c: CanvasItem) -> void:
	draw_soul(c, art_state())


static func draw_portrait(c: CanvasItem, t: float) -> void:
	draw_soul(c, {"t": t, "pose": "idle"})


static func draw_soul(c: CanvasItem, s: Dictionary) -> void:
	var t: float = s.get("t", 0.0)
	var pose_v: String = s.get("pose", "idle")
	var dead: bool = s.get("dead", false)
	var center := Vector2(0, -36)
	c.draw_circle(center, 36.0, Color(FLAME_HI.r, FLAME_HI.g, FLAME_HI.b, 0.15))
	# Flame body flickering upward, wispy tail below
	var pts := PackedVector2Array()
	for i in 20:
		var a := TAU * float(i) / 20.0
		var r := 20.0 + 3.0 * sin(t * 9.0 + float(i) * 2.3)
		var stretch := 1.8 if sin(a) < 0.0 else 1.0
		pts.append(center + Vector2(cos(a) * r, sin(a) * r * stretch))
	c.draw_colored_polygon(pts, FLAME)
	var inner := PackedVector2Array()
	for p in pts:
		inner.append(center + (p - center) * 0.6 + Vector2(0, 4))
	c.draw_colored_polygon(inner, FLAME_HI)
	for i in 3:
		var k := float(i) / 2.0
		c.draw_circle(center + Vector2(-6.0 + sin(t * 4.0 + k * 3.0) * 6.0, 22.0 + k * 12.0), 6.0 - k * 2.0, Color(FLAME.r, FLAME.g, FLAME.b, 0.7 - k * 0.3))
	# Pale face
	var face := center + Vector2(4, 0)
	c.draw_colored_polygon(EnemyArt.ellipse_points(face, 9.0, 11.0, 14), FACE)
	if dead:
		EnemyArt.ko_eye(c, face + Vector2(2, -3), 2.5, t)
	else:
		c.draw_circle(face + Vector2(-2, -3), 2.2, EnemyArt.BLACK)
		c.draw_circle(face + Vector2(5, -3), 2.2, EnemyArt.BLACK)
	var open := 4.0 if pose_v == "bolt" or pose_v == "burst" else 2.0
	c.draw_colored_polygon(EnemyArt.ellipse_points(face + Vector2(1, 5), 2.5, open, 8), EnemyArt.BLACK)
	if pose_v == "bolt_tele":
		c.draw_circle(center + Vector2(26, 0), 8.0, Color(0.7, 0.4, 1.0, 0.8))
