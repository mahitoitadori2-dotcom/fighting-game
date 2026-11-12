class_name Kharleming
extends SimpleEnemy
## KHARLEMING (Story Mode, Colosseum 1): small six-legged spider ROBOT (scrap-metal dome,
## one glowing eye). Fast and fragile. They run to the cave WALLS, CLIMB them and
## POUNCE down on you from above.
##
##   Bite     2 dmg, 1 s   - quick nip up close
##   Pounce   4 dmg, 3.5 s - leaps at you (from the floor OR from a wall)
## Climbing uses StoryManager.wall_left_x / wall_right_x (Story arenas have cave walls).

const CLIMB_SPEED := 230.0
const CLIMB_HEIGHT_MIN := 150.0
const CLIMB_HEIGHT_MAX := 260.0
const POUNCE_SPEED := 560.0
const BITE_KB := Vector2(120, -60)
const POUNCE_KB := Vector2(240, -160)

const METAL := Color(0.56, 0.60, 0.64)
const METAL_SHADE := Color(0.32, 0.35, 0.40)
const METAL_HI := Color(0.82, 0.86, 0.90)
const RUST := Color(0.62, 0.36, 0.20)
const EYE := Color(0.35, 1.0, 0.95)

var climbing := false
var wall_side := 0.0                 # -1 = left wall, 1 = right wall
var climb_cooldown := 0.6               # Soon after spawning, some run for the walls
var _climb_top := 0.0
var _cling := 0.0
var _air := false


func _make_data() -> CharacterData:
	keep_min = 0.0
	keep_max = 90.0
	attack_chance = 0.65
	phase2_threshold = -1.0
	var d := SimpleEnemy.make_data("Kharleming", 8, Vector2(44, 30), 300.0)
	d.acceleration = 3200.0
	return d


static func make_patterns() -> Array[EnemyPattern]:
	var list: Array[EnemyPattern] = []
	#                          id        name        cd    dmg  min    max    anim      tele  active rec   big    weights
	list.append(EnemyPattern.make("bite", "BITE", 1.0, 2, 0.0, 60.0, "bite", 0.12, 0.10, 0.30, false, [1.5, 1.5]))
	list.append(EnemyPattern.make("pounce", "POUNCE!", 3.5, 4, 90.0, 460.0, "pounce", 0.35, 0.70, 0.40, false, [1.6, 1.6]))
	return list


func _make_brain() -> EnemyAI:
	return KharlemingAI.new()


func flavor_lines() -> Array[String]:
	return ["*click-click*", "*bzzt*"]


# ============================================================
# CLIMBING
# ============================================================
func can_climb() -> bool:
	return StoryManager.active and StoryManager.has_walls and climb_cooldown <= 0.0 and not climbing and is_on_floor()


## Nearest wall's inner face x and its side (-1 left / 1 right).
func nearest_wall() -> Vector2:
	var l := StoryManager.wall_left_x
	var r := StoryManager.wall_right_x
	if absf(global_position.x - l) < absf(global_position.x - r):
		return Vector2(l, -1.0)
	return Vector2(r, 1.0)


func start_climb(side: float, wall_x: float) -> void:
	climbing = true
	wall_side = side
	global_position.x = wall_x - side * (data.body_size.x * 0.5 + 1.0)
	_climb_top = global_position.y - randf_range(CLIMB_HEIGHT_MIN, CLIMB_HEIGHT_MAX)
	_cling = randf_range(0.5, 1.4)
	velocity = Vector2.ZERO
	move_dir = 0.0
	Effects.popup(self, global_position + Vector2(0, -50), "*skitter*", Color(0.4, 1.0, 0.95), 13)
	if StoryManager.autoplay:
		print("STORY autoplay: Kharleming climbs a wall")


func stop_climb() -> void:
	climbing = false
	wall_side = 0.0
	climb_cooldown = randf_range(4.0, 7.0)


func _movement(delta: float) -> void:
	climb_cooldown = maxf(climb_cooldown - delta, 0.0)
	if climbing and not (estate == EState.ATTACK):
		if stun_timer > 0.0:
			stop_climb()                                     # Knocked off the wall
		else:
			velocity.x = 0.0
			if global_position.y > _climb_top:
				velocity.y = -CLIMB_SPEED
			else:
				velocity.y = 0.0
				_cling -= delta
				if _cling <= 0.0:
					var p := pattern("pounce")
					if p != null and p.is_ready():
						start_pattern(p)                     # Leap off the wall at the player
					else:
						stop_climb()                         # Just drop down
			return
	super._movement(delta)


# ============================================================
# ATTACKS
# ============================================================
func _attack(p: EnemyPattern) -> void:
	match p.id:
		"bite":
			hitbox.activate(make_hit(dmg(p), Vector2(facing * BITE_KB.x, BITE_KB.y), "kharleming_bite"),
				Vector2(facing * 28.0, -14.0), Vector2(34, 26))
		"pounce":
			var target := Vector2(target_x(), global_position.y)
			if brain != null and brain.target != null and is_instance_valid(brain.target):
				target = brain.target.global_position + Vector2(0, -30)
			var to := target - global_position
			facing = 1 if to.x >= 0.0 else -1
			if climbing:
				stop_climb()
				velocity = to.normalized() * POUNCE_SPEED + Vector2(0, -60)   # Dive off the wall
			else:
				velocity = Vector2(clampf(to.x * 1.6, -POUNCE_SPEED, POUNCE_SPEED), -430.0)
			_air = false
			hitbox.activate(make_hit(dmg(p), Vector2(facing * POUNCE_KB.x, POUNCE_KB.y), "kharleming_pounce"),
				Vector2(0, -16), Vector2(50, 36))
			SoundManager.play_sfx("jump", -8.0)


func _on_attack_update(p: EnemyPattern, _delta: float) -> void:
	if p.id != "pounce":
		return
	if not is_on_floor():
		_air = true
	elif _air:
		state_time = state_len


func _owns_velocity_x() -> bool:
	return climbing or (estate == EState.ATTACK and current != null and current.id == "pounce")


func _on_respawn() -> void:
	super._on_respawn()
	climbing = false


func _update_visuals(delta: float) -> void:
	# On a wall the body turns 90 degrees so the legs grip the wall
	visuals.rotation = (-PI * 0.5 * wall_side) if climbing else 0.0
	super._update_visuals(delta)


# ============================================================
# ART (facing right, origin = feet, ~56 x 36)
# ============================================================
func draw_model_on(c: CanvasItem) -> void:
	draw_bot(c, art_state())


static func draw_portrait(c: CanvasItem, t: float) -> void:
	draw_bot(c, {"t": t, "pose": "idle"})


static func draw_bot(c: CanvasItem, s: Dictionary) -> void:
	var t: float = s.get("t", 0.0)
	var pose_v: String = s.get("pose", "idle")
	var dead: bool = s.get("dead", false)
	var moving: bool = s.get("moving", false)
	var skitter := t * (26.0 if moving else 6.0)
	var body_c := Vector2(0, -18 + (absf(sin(skitter)) * 1.5 if moving else 0.0))
	if pose_v == "pounce_tele":
		body_c.y += 5.0

	# Six thin jointed legs (3 per side), alternating gait
	for i in 6:
		var side := -1.0 if i < 3 else 1.0
		var k := float(i % 3)
		var hip := body_c + Vector2(-8.0 + k * 8.0, 4)
		var lift := sin(skitter + k * 2.1 + (PI if side > 0.0 else 0.0)) * 3.0
		var knee := hip + Vector2((-10.0 + k * 10.0) * 0.8 + side * 3.0, -8.0 + lift)
		var foot := Vector2(hip.x + (-14.0 + k * 14.0), 0.0 + minf(lift, 0.0))
		var col := METAL_SHADE if side < 0.0 else METAL
		c.draw_line(hip, knee, EnemyArt.BLACK, 5.0)
		c.draw_line(knee, foot, EnemyArt.BLACK, 4.0)
		c.draw_line(hip, knee, col, 2.5)
		c.draw_line(knee, foot, col, 2.0)
		c.draw_circle(knee, 2.2, RUST)

	# Dome body
	var dome := EnemyArt.ellipse_points(body_c, 18, 12, 18)
	c.draw_polygon(dome, _grad(dome, body_c))
	c.draw_line(body_c + Vector2(-16, 2), body_c + Vector2(16, 2), METAL_SHADE, 2.0)       # Panel seam
	for k in 3:
		c.draw_circle(body_c + Vector2(-10 + float(k) * 7.0, -6), 1.3, METAL_SHADE)       # Rivets
	c.draw_circle(body_c + Vector2(-6, -2), 3.0, RUST)                                     # Rust patch
	FighterArt.outline(c, dome, 3.0)
	# Antenna
	c.draw_line(body_c + Vector2(-4, -11), body_c + Vector2(-10, -22), EnemyArt.BLACK, 2.0)
	c.draw_circle(body_c + Vector2(-10, -22), 2.5, Color(1, 0.3, 0.2) if fmod(t * 2.0, 1.0) < 0.5 else Color(0.4, 0.1, 0.1))
	# Front mandibles + single glowing eye
	var front := body_c + Vector2(16, 2)
	c.draw_line(front, front + Vector2(8, 6), EnemyArt.BLACK, 3.0)
	c.draw_line(front + Vector2(0, -2), front + Vector2(8, -6), EnemyArt.BLACK, 3.0)
	var eye := body_c + Vector2(10, -2)
	if dead:
		EnemyArt.ko_eye(c, eye, 4.0, t)
	else:
		c.draw_circle(eye, 7.0, Color(EYE.r, EYE.g, EYE.b, 0.25))
		c.draw_circle(eye, 4.5, EnemyArt.BLACK)
		c.draw_circle(eye, 3.2, EYE)
		c.draw_circle(eye + Vector2(-1, -1), 1.0, Color.WHITE)


static func _grad(pts: PackedVector2Array, center: Vector2) -> PackedColorArray:
	var cols := PackedColorArray()
	for p in pts:
		cols.append(METAL_HI.lerp(METAL_SHADE, clampf((p.y - center.y + 10.0) / 22.0, 0.0, 1.0)))
	return cols


# ============================================================
# BRAIN
# ============================================================
class KharlemingAI extends SimpleEnemyAI:
	## Story arenas are walled in: no edge to fall off, and the walls are the goal.
	func _edge_safety() -> void:
		if not StoryManager.has_walls:
			super._edge_safety()

	func think() -> void:
		var k := e as Kharleming
		if k == null:
			super.think()
			return
		if k.climbing:
			face_target()
			return                                          # Movement code handles the wall
		# Sometimes skitter to the nearest wall and climb it
		var w := k.nearest_wall()
		var to_wall := w.x - k.global_position.x
		var heading := k.move_dir != 0.0 and signf(k.move_dir) == signf(to_wall) and k.climb_cooldown <= 0.0
		if k.can_climb() and absf(to_wall) < 700.0 and (heading or chance(0.3)):
			if absf(to_wall) < k.data.body_size.x * 0.5 + 40.0:
				k.start_climb(w.y, w.x)
				return
			k.move_dir = signf(to_wall)
			k.facing = int(k.move_dir)
			return
		super.think()
