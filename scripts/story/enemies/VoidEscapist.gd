class_name VoidEscapist
extends SimpleEnemy
## VOID ESCAPIST (Story Mode, Colosseum 4): a crawling black GHOST - a smoky black body that
## trails off into wisps, long clawed arms, hollow white eyes. It can PHASE THROUGH THE
## GROUND: it sinks into the floor (can't be hit), slides under you, and bursts up biting.
##
##   Ghost Bite    5 dmg, 1.6 s - bites when close
##   Phase         6 dmg, 5.0 s - sinks into the ground, slides to you, erupts with a bite

const PHASE_SPEED := 420.0
const BITE_KB := Vector2(200, -140)
const ERUPT_KB := Vector2(260, -380)

const BODY := Color(0.05, 0.04, 0.08)
const WISP := Color(0.25, 0.15, 0.40)
const EYE := Color(0.95, 0.95, 1.0)

var _phased := false


func _make_data() -> CharacterData:
	keep_min = 0.0
	keep_max = 110.0
	attack_chance = 0.65
	phase2_threshold = -1.0
	return SimpleEnemy.make_data("Void Escapist", 22, Vector2(60, 90), 220.0)


static func make_patterns() -> Array[EnemyPattern]:
	var list: Array[EnemyPattern] = []
	#                          id       name          cd    dmg  min    max    anim     tele  active rec   big    weights
	list.append(EnemyPattern.make("bite", "GHOST BITE", 1.6, 5, 0.0, 90.0, "bite", 0.30, 0.15, 0.40, false, [1.6, 1.6]))
	list.append(EnemyPattern.make("phase", "PHASE!", 5.0, 6, 140.0, 800.0, "phase", 0.35, 1.30, 0.50, true, [1.6, 1.6]))
	list[1].note = "sinks into the ground: can't be hit, erupts under you"
	return list


func flavor_lines() -> Array[String]:
	return ["*hhhhhhh*", "...out... out...", "*whisper*"]


func _attack(p: EnemyPattern) -> void:
	match p.id:
		"bite":
			hitbox.activate(make_hit(dmg(p), Vector2(facing * BITE_KB.x, BITE_KB.y), "escapist_bite"),
				Vector2(facing * 44.0, -40.0), Vector2(54, 56))
			SoundManager.play_sfx("bite", -6.0)
		"phase":
			_set_phased(true)
			SoundManager.play_sfx("void_goo", -6.0)


func _on_attack_update(p: EnemyPattern, _delta: float) -> void:
	if p.id != "phase":
		return
	var dx := target_x() - global_position.x
	if absf(dx) > 20.0 and state_time < state_len - 0.25:
		facing = 1 if dx > 0.0 else -1
		velocity.x = facing * PHASE_SPEED
	else:
		velocity.x = 0.0


func _on_attack_end(p: EnemyPattern) -> void:
	if p.id == "phase":
		_set_phased(false)
		hit_in_radius(global_position + Vector2(0, -40), 70.0, dmg(p), ERUPT_KB, "escapist_erupt")
		Effects.void_burst(self, global_position + Vector2(0, -30), 70.0)
		Effects.shake(self, 6.0)
		SoundManager.play_sfx("bite")


func _cancel_pattern() -> void:
	_set_phased(false)
	super._cancel_pattern()


func _on_death() -> void:
	_set_phased(false)
	super._on_death()


func _set_phased(on: bool) -> void:
	_phased = on
	hurtbox.set_deferred("monitorable", not on and not is_dead)


func _owns_velocity_x() -> bool:
	return _phased


func art_state() -> Dictionary:
	var s := super.art_state()
	s["phased"] = _phased
	return s


# ============================================================
# ART (facing right, origin = feet, ~80 x 100)
# ============================================================
func draw_model_on(c: CanvasItem) -> void:
	draw_escapist(c, art_state())


static func draw_portrait(c: CanvasItem, t: float) -> void:
	draw_escapist(c, {"t": t, "pose": "idle"})


static func draw_escapist(c: CanvasItem, s: Dictionary) -> void:
	var t: float = s.get("t", 0.0)
	var pose: String = s.get("pose", "idle")
	var dead: bool = s.get("dead", false)
	if s.get("phased", false):
		# Under the ground: only a dark ripple and two eyes sliding along the floor
		var ripple := EnemyArt.ellipse_points(Vector2(0, -2), 44.0, 8.0, 16)
		c.draw_colored_polygon(ripple, Color(0.1, 0.05, 0.18, 0.8))
		c.draw_arc(Vector2(0, -2), 30.0 + 10.0 * sin(t * 12.0), PI, TAU, 12, Color(0.6, 0.3, 1.0, 0.6), 2.0)
		c.draw_circle(Vector2(6, -6), 2.5, EYE)
		c.draw_circle(Vector2(16, -6), 2.5, EYE)
		return
	var crouch := 10.0 if pose.ends_with("_tele") else 0.0
	var body_c := Vector2(0, -50 + crouch + sin(t * 3.0) * 3.0)
	# Wispy tail trailing behind and down into the floor
	for i in 5:
		var k := float(i) / 4.0
		var wp := body_c + Vector2(-20.0 - k * 34.0, 20.0 + k * 22.0 + sin(t * 5.0 + k * 4.0) * 6.0)
		c.draw_circle(wp, 16.0 - k * 10.0, Color(BODY.r, BODY.g, BODY.b, 0.85 - k * 0.5))
	# Smoky body
	var body := PackedVector2Array()
	for i in 18:
		var a := TAU * float(i) / 18.0
		var r := 26.0 + 5.0 * sin(t * 6.0 + float(i) * 1.9)
		body.append(body_c + Vector2(cos(a) * r * 1.1, sin(a) * r))
	c.draw_colored_polygon(body, BODY)
	c.draw_polyline(body + PackedVector2Array([body[0]]), Color(WISP.r, WISP.g, WISP.b, 0.8), 3.0, true)
	# Long clawed arms crawling forward
	var reach := 26.0 if pose == "bite" else 0.0
	for i in 2:
		var sh := body_c + Vector2(10, -4 + float(i) * 12.0)
		var hand := Vector2(36 + reach + float(i) * 6.0 + sin(t * 4.0 + float(i) * 2.0) * 4.0, -6.0 - float(i) * 4.0)
		var elbow := sh.lerp(hand, 0.5) + Vector2(0, -14)
		c.draw_polyline(PackedVector2Array([sh, elbow, hand]), BODY, 7.0, true)
		for f in 3:
			c.draw_line(hand, hand + Vector2.from_angle(-0.4 + float(f) * 0.4) * 9.0, BODY, 2.0)
	# Hollow white eyes + ghost mouth
	if dead:
		EnemyArt.ko_eye(c, body_c + Vector2(12, -8), 4.0, t)
	else:
		c.draw_colored_polygon(EnemyArt.ellipse_points(body_c + Vector2(6, -8), 4.0, 6.0, 10), EYE)
		c.draw_colored_polygon(EnemyArt.ellipse_points(body_c + Vector2(18, -8), 4.0, 6.0, 10), EYE)
	var open := 1.0 if pose == "bite" else 0.3
	c.draw_colored_polygon(EnemyArt.ellipse_points(body_c + Vector2(13, 8), 6.0, 2.0 + 6.0 * open, 12), Color(0.0, 0.0, 0.0))
