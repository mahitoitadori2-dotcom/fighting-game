class_name Imp
extends SimpleEnemy
## IMP (Colosseum 5 - summoned by SATAN): a small flying demon with leathery wings and a
## pitchfork tail. It hovers above the floor and swoops down at you.
##
##   Swoop       5 dmg, 2.6 s - dives at you along a line
##   Ember Shot  3 dmg, 2.2 s - flicks a small fireball

const HOVER := 150.0
const RED := Color(0.62, 0.10, 0.10)
const RED_HI := Color(0.85, 0.30, 0.22)
const WING := Color(0.30, 0.05, 0.06)

var _floor := INF
var _swoop_v := Vector2.ZERO


func _make_data() -> CharacterData:
	keep_min = 120.0
	keep_max = 380.0
	attack_chance = 0.55
	phase2_threshold = -1.0
	return SimpleEnemy.make_data("Imp", 14, Vector2(44, 48), 210.0)


static func make_patterns() -> Array[EnemyPattern]:
	var list: Array[EnemyPattern] = []
	list.append(EnemyPattern.make("swoop", "SWOOP!", 2.6, 5, 60.0, 420.0, "swoop", 0.40, 0.55, 0.40, true, [2.0, 2.0]))
	list.append(EnemyPattern.make("ember", "EMBER SHOT", 2.2, 3, 120.0, 600.0, "ember", 0.30, 0.12, 0.40, false, [1.5, 1.5]))
	return list


func flavor_lines() -> Array[String]:
	return ["Hee hee!", "For the master!", "*buzzing wings*"]


func jump(_force_mult: float = 1.0) -> void:
	pass


func _movement(delta: float) -> void:
	if estate == EState.ATTACK and current != null and current.id == "swoop":
		velocity = _swoop_v
		return
	super._movement(delta)
	if _floor == INF:
		var g := get_tree().get_first_node_in_group("arena_ground") as ArenaGround
		_floor = g.global_position.y if g != null else global_position.y + HOVER
	var goal := _floor - HOVER + sin(anim_time * 3.0) * 14.0
	velocity.y = (goal - global_position.y) * 4.0


func _attack(p: EnemyPattern) -> void:
	match p.id:
		"swoop":
			var to := Vector2(target_x(), _floor - 50.0) - global_position
			_swoop_v = to.normalized() * 620.0
			hitbox.activate(make_hit(dmg(p), Vector2(facing * 260.0, -200.0), "imp_swoop"), Vector2(0, -24), Vector2(60, 50))
			SoundManager.play_sfx("dash", -8.0)
		"ember":
			var f := spawn_projectile()
			f.kind = EnemyProjectile.Kind.ARC
			f.look = "magma"
			f.damage = dmg(p)
			f.knockback = Vector2(140, -120)
			f.radius = 30.0
			f.pierce = false
			f.lifetime = 3.0
			f.move = "imp_ember"
			var flight := 0.7
			var from := global_position + Vector2(0, -20)
			f.arc_velocity = Vector2((target_x() - from.x) / flight, ((_floor - from.y) - 0.5 * EnemyProjectile.ARC_GRAVITY * flight * flight) / flight)
			launch(f, from)
			SoundManager.play_sfx("flame", -10.0)


func _on_attack_end(p: EnemyPattern) -> void:
	if p.id == "swoop":
		velocity = Vector2.ZERO


func _owns_velocity_x() -> bool:
	return estate == EState.ATTACK and current != null and current.id == "swoop"


# ============================================================
# ART (facing right, origin = bottom of the body, ~70 x 60)
# ============================================================
func draw_model_on(c: CanvasItem) -> void:
	draw_imp(c, art_state())


static func draw_portrait(c: CanvasItem, t: float) -> void:
	draw_imp(c, {"t": t, "pose": "idle"})


static func draw_imp(c: CanvasItem, s: Dictionary) -> void:
	var t: float = s.get("t", 0.0)
	var dead: bool = s.get("dead", false)
	var flap := sin(t * 22.0) * 16.0
	var body := Vector2(0, -26)
	for sgn: float in [-1.0, 1.0]:
		var wing := PackedVector2Array([body + Vector2(-4, -8), body + Vector2(-30 * sgn * 0.0 - 30, -24 - flap), body + Vector2(-22, -6), body + Vector2(-38, 2 - flap * 0.4), body + Vector2(-10, 6)])
		if sgn > 0.0:
			for i in wing.size():
				wing[i] = Vector2(-wing[i].x, wing[i].y)
		c.draw_colored_polygon(wing, WING)
		FighterArt.outline(c, wing, 2.0)
	var tail := PackedVector2Array([body + Vector2(-6, 12), body + Vector2(-18, 22), body + Vector2(-24, 14 + sin(t * 5.0) * 4.0)])
	c.draw_polyline(tail, EnemyArt.BLACK, 5.0, true)
	c.draw_polyline(tail, RED, 2.5, true)
	FighterArt.ball(c, body, 16.0, RED, RED.darkened(0.3), RED_HI)
	for sgn: float in [-1.0, 1.0]:
		FighterArt.curved_spike(c, body + Vector2(sgn * 7.0, -12), body + Vector2(sgn * 12.0, -28), 3.5, Color(0.2, 0.15, 0.12), Color(0.4, 0.3, 0.25), 0.3, 2.0)
	if dead:
		EnemyArt.ko_eye(c, body + Vector2(6, -3), 2.5, t)
	else:
		c.draw_circle(body + Vector2(4, -4), 3.0, Color(1.0, 0.9, 0.3))
		c.draw_circle(body + Vector2(11, -4), 3.0, Color(1.0, 0.9, 0.3))
		c.draw_arc(body + Vector2(8, 4), 6.0, 0.2, PI - 0.2, 8, EnemyArt.BLACK, 2.0)
