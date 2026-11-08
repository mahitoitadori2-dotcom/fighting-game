class_name TheShining
extends SimpleEnemy
## THE SHINING (Story Mode, Colosseum 4, the Altar): a ghost of LIGHT - a glowing white and
## gold figure in a flowing robe of light, with a halo and no face, floating above the altar.
##
## OPTIONAL: it is PEACEFUL until you hit it. Fight it or walk past it (StoryManager shows the
## choice). Killing it weakens the Void for the rest of Colosseum 4; leaving it alive makes
## the Void Massacre much stronger.
##
##   Light Beam    6 dmg, 2.4 s - a beam of white light straight along the floor
##   Light Blast   7 dmg each, 5.0 s - BIG: pillars of light burst up under you

const HOVER := 80.0

const LIGHT := Color(1.0, 0.97, 0.85)
const GOLD := Color(1.0, 0.82, 0.35)

var _angry := false
var _floor := INF
var _home_x := INF


func _make_data() -> CharacterData:
	keep_min = 200.0
	keep_max = 420.0
	attack_chance = 0.0                         # Peaceful until hit
	phase2_threshold = -1.0
	knockback_scale = 0.3
	return SimpleEnemy.make_data("The Shining", 70, Vector2(60, 110), 150.0)


static func make_patterns() -> Array[EnemyPattern]:
	var list: Array[EnemyPattern] = []
	#                          id      name           cd    dmg  min    max     anim     tele  active rec   big    weights
	list.append(EnemyPattern.make("beam", "LIGHT BEAM", 2.4, 6, 80.0, 900.0, "beam", 0.50, 0.25, 0.45, false, [2.0, 2.0]))
	list.append(EnemyPattern.make("blast", "LIGHT BLAST!", 5.0, 7, 0.0, 1200.0, "blast", 0.60, 0.40, 0.50, true, [1.2, 1.2]))
	return list


func wants_pattern(_p: EnemyPattern) -> bool:
	return _angry


func flavor_lines() -> Array[String]:
	if _angry:
		return ["Why...?", "You chose the dark.", "*a ringing like glass*"]
	return ["...peace...", "*soft humming*", "You may pass."]


func jump(_force_mult: float = 1.0) -> void:
	pass


func take_hit(amount: int, hit: HitData) -> void:
	super.take_hit(amount, hit)
	if amount > 0 and not _angry and not is_dead:
		_angry = true
		attack_chance = 0.6
		Effects.popup(self, global_position + Vector2(0, -170), "THE SHINING FIGHTS BACK!", GOLD, 24)
		SoundManager.play_sfx("holy")


func _owns_velocity_x() -> bool:
	if _angry:
		return false
	# Peaceful: drifts slowly around the spot it appeared at
	if _home_x == INF:
		_home_x = global_position.x
	velocity.x = ((_home_x + sin(anim_time * 0.6) * 60.0) - global_position.x) * 1.5
	return true


func _movement(delta: float) -> void:
	super._movement(delta)
	if _floor == INF:
		if is_on_floor():
			_floor = global_position.y
		return
	velocity.y = ((_floor - HOVER + sin(anim_time * 1.8) * 12.0) - global_position.y) * 5.0


func _attack(p: EnemyPattern) -> void:
	match p.id:
		"beam":
			var b := spawn_projectile()
			b.kind = EnemyProjectile.Kind.LINEAR
			b.look = "eye_beam"
			b.dir = float(facing)
			b.speed = 760.0
			b.lifetime = 1.3
			b.size = Vector2(70, 26)
			b.damage = dmg(p)
			b.knockback = Vector2(260, -160)
			b.pierce = false
			b.move = "light_beam"
			launch(b, Vector2(global_position.x + facing * 30.0, (_floor if _floor != INF else global_position.y) - 60.0))
			SoundManager.play_sfx("beam", -5.0)
		"blast":
			var tx := target_x()
			var gy := _floor if _floor != INF else global_position.y
			for off in [0.0, -150.0, 150.0]:
				BossHazard.spawn(self, "pillar", Vector2(clamp_to_ground(tx + off), gy), 0.8, dmg(p), Vector2(220, -420))
			SoundManager.play_sfx("holy", -3.0)


# ============================================================
# ART (origin = bottom of the robe of light, ~80 x 150)
# ============================================================
func draw_model_on(c: CanvasItem) -> void:
	var s := art_state()
	s["angry"] = _angry
	draw_shining(c, s)


static func draw_portrait(c: CanvasItem, t: float) -> void:
	draw_shining(c, {"t": t, "pose": "idle"})


static func draw_shining(c: CanvasItem, s: Dictionary) -> void:
	var t: float = s.get("t", 0.0)
	var pose: String = s.get("pose", "idle")
	var dead: bool = s.get("dead", false)
	var angry: bool = s.get("angry", false)
	var pulse := 0.5 + 0.5 * sin(t * (6.0 if angry else 2.0))
	var head := Vector2(0, -122 + sin(t * 1.5) * 3.0)
	# Radiance
	for k in 4:
		c.draw_circle(head + Vector2(0, 50), 90.0 - float(k) * 18.0 + 8.0 * pulse, Color(LIGHT.r, LIGHT.g, LIGHT.b, 0.06 + 0.04 * float(k)))
	for i in 12:
		var a := TAU * float(i) / 12.0 + t * 0.3
		c.draw_line(head + Vector2.from_angle(a) * 40.0, head + Vector2.from_angle(a) * (70.0 + 10.0 * pulse), Color(GOLD.r, GOLD.g, GOLD.b, 0.4), 3.0)
	# Flowing robe of light (no feet: fades into wisps)
	var robe := PackedVector2Array([head + Vector2(-14, 14), head + Vector2(14, 14), Vector2(30 + sin(t * 2.0) * 6.0, -14), Vector2(10, -4),
		Vector2(0, -16), Vector2(-10, -4), Vector2(-30 + sin(t * 2.0 + 1.0) * 6.0, -14)])
	c.draw_colored_polygon(robe, Color(LIGHT.r, LIGHT.g, LIGHT.b, 0.85))
	c.draw_line(head + Vector2(0, 16), Vector2(0, -20), Color(GOLD.r, GOLD.g, GOLD.b, 0.8), 3.0)
	# Arms of light (raised when casting)
	var raise := pose.begins_with("blast") or pose.begins_with("beam")
	for side in [-1.0, 1.0]:
		var sh: Vector2 = head + Vector2(side * 12.0, 24)
		var hand: Vector2 = sh + (Vector2(side * 26.0, -30) if raise else Vector2(side * 18.0, 34))
		c.draw_line(sh, hand, Color(LIGHT.r, LIGHT.g, LIGHT.b, 0.9), 7.0, true)
		c.draw_circle(hand, 5.0, GOLD)
	# Faceless glowing head + halo
	c.draw_circle(head, 18.0, LIGHT)
	c.draw_circle(head, 12.0, Color(1, 1, 1))
	if dead:
		EnemyArt.ko_eye(c, head, 4.0, t)
	elif angry:
		c.draw_line(head + Vector2(-8, -2), head + Vector2(-2, 1), GOLD, 3.0)
		c.draw_line(head + Vector2(8, -2), head + Vector2(2, 1), GOLD, 3.0)
	c.draw_set_transform(head + Vector2(0, -24), 0.0, Vector2(1.0, 0.3))
	c.draw_arc(Vector2.ZERO, 20.0, 0.0, TAU, 24, Color(GOLD.r, GOLD.g, GOLD.b, 0.5), 9.0, true)
	c.draw_arc(Vector2.ZERO, 20.0, 0.0, TAU, 24, GOLD, 3.0, true)
	c.draw_set_transform(Vector2.ZERO, 0.0, Vector2.ONE)
