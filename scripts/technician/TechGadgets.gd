class_name TechGadgets
extends RefCounted
## THE TECHNICIAN's gadgets. Simple self-contained nodes that check their targets by DISTANCE
## (no physics layers): a scrap BOLT, the SCRAP TURRET, a COLONY DRONE and THE BREAKER bomb.
## They hit with CombatManager.apply_hit, so blocking, damage numbers, K.O.s all work as usual,
## and they freeze during a Time Stop like everything else of their owner.

const CYAN := Color(0.35, 1.0, 0.95)
const METAL := Color(0.62, 0.66, 0.72)
const METAL_SHADE := Color(0.34, 0.37, 0.43)
const BLACK := Color(0, 0, 0)


static func _foes(owner: Fighter) -> Array:
	var out: Array = []
	if owner == null or not is_instance_valid(owner) or not owner.is_inside_tree():
		return out
	for n in owner.get_tree().get_nodes_in_group("fighters"):
		var f := n as Fighter
		if f != null and f != owner and not f.is_dead and not CombatManager.are_allies(owner, f):
			out.append(f)
	return out


static func hit(owner: Fighter, f: Fighter, dmg: int, kb: Vector2, move: String, hit_type: String = "melee", stun := 0.0) -> void:
	var h := HitData.new()
	h.source = owner
	h.damage = dmg
	h.knockback = kb
	h.origin = owner.global_position if is_instance_valid(owner) else f.global_position
	h.hit_type = hit_type
	h.move = move
	CombatManager.apply_hit(h, f)
	if stun > 0.0 and is_instance_valid(f) and not f.is_dead:
		f.stun_timer = maxf(f.stun_timer, stun)


## A scrap bolt flying in a straight line.
class Bolt extends Node2D:
	var owner_f: Fighter
	var dir := 1.0
	var speed := 700.0
	var damage := 3
	var life := 1.2
	var move := "scrap_bolt"

	func _ready() -> void:
		z_index = 6

	func _process(delta: float) -> void:
		if owner_f == null or not is_instance_valid(owner_f):
			queue_free()
			return
		if owner_f.is_time_frozen():
			return
		life -= delta
		if life <= 0.0:
			queue_free()
			return
		global_position.x += dir * speed * delta
		for f in TechGadgets._foes(owner_f):
			var fc: Vector2 = (f as Fighter).global_position + Vector2(0, -60)
			if absf(fc.x - global_position.x) < 26.0 and absf(fc.y - global_position.y) < 64.0:
				TechGadgets.hit(owner_f, f, damage, Vector2(dir * 140.0, -80.0), move, "projectile")
				Effects.hit_sparks(self, global_position, 5, 0.8)
				queue_free()
				return
		queue_redraw()

	func _draw() -> void:
		draw_line(Vector2(-dir * 18.0, 0), Vector2.ZERO, Color(TechGadgets.CYAN.r, TechGadgets.CYAN.g, TechGadgets.CYAN.b, 0.4), 4.0)
		var pts := PackedVector2Array([Vector2(-6 * dir, -4), Vector2(8 * dir, 0), Vector2(-6 * dir, 4)])
		draw_colored_polygon(pts, TechGadgets.METAL)
		draw_polyline(pts + PackedVector2Array([pts[0]]), TechGadgets.BLACK, 1.5)


## The SCRAP TURRET: stands where it was dropped, fires bolts at the nearest foe in range.
## Breaks when its time is up - or when a foe hits it (any attack in reach smashes it).
class Turret extends Node2D:
	var owner_f: Fighter
	var data: TechnicianData
	var life := 6.0
	var hp := 12
	var _cd := 0.6
	var _t := 0.0
	var _aim := 1.0

	func _ready() -> void:
		z_index = 1

	func _process(delta: float) -> void:
		if owner_f == null or not is_instance_valid(owner_f) or owner_f.is_dead:
			_break()
			return
		_t += delta
		if owner_f.is_time_frozen():
			return
		life -= delta
		if life <= 0.0:
			_break()
			return
		# Smashed by a foe's attack in reach (their hitbox is near it while they attack)
		for f in TechGadgets._foes(owner_f):
			var cf := f as ControlledFighter
			if cf != null and cf.is_attacking() and absf(f.global_position.x - global_position.x) < 80.0:
				hp -= 4
				Effects.hit_sparks(self, global_position + Vector2(0, -30), 4, 0.8)
		if hp <= 0:
			_break()
			return
		var best: Fighter = null
		var bd := data.turret_range
		for f in TechGadgets._foes(owner_f):
			var d := absf((f as Fighter).global_position.x - global_position.x)
			if d < bd and absf((f as Fighter).global_position.y - global_position.y) < 220.0:
				bd = d
				best = f
		if best != null:
			_aim = signf(best.global_position.x - global_position.x)
			_cd -= delta
			if _cd <= 0.0:
				_cd = data.turret_fire_every
				var b := TechGadgets.Bolt.new()
				b.owner_f = owner_f
				b.dir = _aim
				b.speed = data.turret_bolt_speed
				b.damage = data.turret_bolt_damage
				b.life = data.turret_range / data.turret_bolt_speed
				get_parent().add_child(b)
				b.global_position = global_position + Vector2(_aim * 26.0, -34.0)
				SoundManager.play_sfx("laser", -12.0)
		queue_redraw()

	func _break() -> void:
		Effects.explosion(self, global_position + Vector2(0, -24), 40.0)
		SoundManager.play_sfx("stone", -8.0)
		queue_free()

	func _draw() -> void:
		# Tripod legs, a scrap box, a barrel aimed at the target, a cyan eye; blinks when expiring
		if life < 1.0 and fmod(_t, 0.2) < 0.1:
			return
		for d: float in [-1.0, 0.0, 1.0]:
			draw_line(Vector2(0, -20), Vector2(d * 18.0, 0), TechGadgets.BLACK, 5.0)
			draw_line(Vector2(0, -20), Vector2(d * 18.0, 0), TechGadgets.METAL_SHADE, 3.0)
		var box := Rect2(-14, -42, 28, 22)
		FighterArt.rrect(self, box, TechGadgets.METAL, TechGadgets.METAL_SHADE, Color(0.9, 0.92, 0.95), 4.0, 2.5)
		draw_line(Vector2(0, -34), Vector2(_aim * 28.0, -34), TechGadgets.BLACK, 8.0)
		draw_line(Vector2(0, -34), Vector2(_aim * 28.0, -34), TechGadgets.METAL_SHADE, 5.0)
		draw_circle(Vector2(-_aim * 5.0, -32), 4.0, TechGadgets.CYAN)
		draw_circle(Vector2(-_aim * 5.0, -32), 7.0, Color(TechGadgets.CYAN.r, TechGadgets.CYAN.g, TechGadgets.CYAN.b, 0.25))


## A COLONY DRONE: a little winged Kharleming that homes in on the nearest foe and explodes.
class Drone extends Node2D:
	var owner_f: Fighter
	var damage := 6
	var speed := 430.0
	var life := 4.0
	var _vel := Vector2.ZERO
	var _t := 0.0

	func _ready() -> void:
		z_index = 7

	func _process(delta: float) -> void:
		if owner_f == null or not is_instance_valid(owner_f):
			queue_free()
			return
		_t += delta
		if owner_f.is_time_frozen():
			return
		life -= delta
		var target: Fighter = null
		var bd := INF
		for f in TechGadgets._foes(owner_f):
			var d := (f as Fighter).global_position.distance_to(global_position)
			if d < bd:
				bd = d
				target = f
		if target != null:
			var want := (target.global_position + Vector2(0, -70) - global_position).normalized() * speed
			_vel = _vel.lerp(want, minf(delta * 3.5, 1.0))
			if (target.global_position + Vector2(0, -70)).distance_to(global_position) < 40.0:
				_boom(target)
				return
		global_position += _vel * delta
		if life <= 0.0:
			_boom(null)
			return
		queue_redraw()

	func _boom(target: Fighter) -> void:
		if target != null:
			TechGadgets.hit(owner_f, target, damage, Vector2(signf(_vel.x) * 260.0, -220.0), "colony_drone", "projectile")
		Effects.explosion(self, global_position, 50.0)
		SoundManager.play_sfx("explosion", -8.0)
		queue_free()

	func _draw() -> void:
		var flap := sin(_t * 30.0) * 6.0
		for d: float in [-1.0, 1.0]:
			draw_colored_polygon(PackedVector2Array([Vector2(0, -2), Vector2(d * 16.0, -8.0 - flap), Vector2(d * 12.0, 2)]), Color(0.75, 0.9, 1.0, 0.8))
		draw_circle(Vector2.ZERO, 9.0, TechGadgets.BLACK)
		draw_circle(Vector2.ZERO, 7.0, TechGadgets.METAL)
		draw_circle(Vector2(3, -1), 2.5, Color(1.0, 0.25, 0.2) if fmod(_t, 0.4) < 0.2 else TechGadgets.CYAN)


## THE TECHNICIAN'S BREAKER: thrown, it lands, beeps three times - then a huge blast.
## Unblockable; the only way out is to RUN out of its radius.
class Breaker extends Node2D:
	var owner_f: Fighter
	var data: TechnicianData
	var fuse := 1.5
	var _t := 0.0
	var _beeps := 0

	func _ready() -> void:
		z_index = 3

	func _process(delta: float) -> void:
		if owner_f == null or not is_instance_valid(owner_f):
			queue_free()
			return
		_t += delta
		if owner_f.is_time_frozen():
			return
		fuse -= delta
		var beeps_due := int((data.breaker_fuse - fuse) / (data.breaker_fuse / 3.0))
		while _beeps < mini(beeps_due, 3):
			_beeps += 1
			SoundManager.play_sfx("count_tick")
		if fuse <= 0.0:
			_explode()
			return
		queue_redraw()

	func _explode() -> void:
		for f in TechGadgets._foes(owner_f):
			var fc: Vector2 = (f as Fighter).global_position + Vector2(0, -60)
			if fc.distance_to(global_position + Vector2(0, -30)) <= data.breaker_radius:
				var dx := signf(fc.x - global_position.x)
				if dx == 0.0:
					dx = 1.0
				var h := HitData.new()
				h.source = owner_f
				h.damage = data.breaker_damage
				h.knockback = Vector2(dx * data.breaker_knockback.x, data.breaker_knockback.y)
				h.origin = global_position
				h.hit_type = "explosion"
				h.move = "breaker"
				h.blockable = false
				CombatManager.apply_hit(h, f)
		for i in 5:
			Effects.explosion(self, global_position + Vector2(randf_range(-120, 120), randf_range(-160, -10)), 90.0)
		Effects.shake(self, 20.0)
		SoundManager.play_sfx("explosion")
		SoundManager.play_sfx("slam")
		queue_free()

	func _draw() -> void:
		var k := 1.0 - fuse / data.breaker_fuse
		# The danger zone grows as it ticks
		draw_arc(Vector2(0, -30), data.breaker_radius, 0.0, TAU, 48, Color(1.0, 0.2, 0.15, 0.25 + 0.4 * k), 3.0)
		draw_circle(Vector2(0, -30), data.breaker_radius * k, Color(1.0, 0.2, 0.15, 0.08))
		CraterWorld.draw_breaker(self, Vector2(0, -24), 1.2, _t * 3.0)


## The CABLE HOOK: flies forward; the first foe it touches is hurt and YANKED toward the owner.
class Hook extends Node2D:
	var owner_f: Fighter
	var data: TechnicianData
	var dir := 1.0
	var _dist := 0.0
	var _back := false

	func _ready() -> void:
		z_index = 6

	func _process(delta: float) -> void:
		if owner_f == null or not is_instance_valid(owner_f) or owner_f.is_dead:
			queue_free()
			return
		if owner_f.is_time_frozen():
			return
		var step := data.hook_speed * delta
		if not _back:
			_dist += step
			global_position = owner_f.global_position + Vector2(dir * (30.0 + _dist), -84)
			for f in TechGadgets._foes(owner_f):
				var fc: Vector2 = (f as Fighter).global_position + Vector2(0, -64)
				if absf(fc.x - global_position.x) < 30.0 and absf(fc.y - global_position.y) < 70.0:
					TechGadgets.hit(owner_f, f, data.hook_damage, Vector2(-dir * data.hook_pull, -200.0), "cable_hook", "grab")
					Effects.popup(owner_f, owner_f.global_position + Vector2(0, -190), "YANK!", Color(0.6, 1.0, 1.0), 22)
					SoundManager.play_sfx("chain")
					_back = true
					break
			if _dist >= data.hook_range:
				_back = true
		else:
			_dist -= step * 1.4
			global_position = owner_f.global_position + Vector2(dir * (30.0 + _dist), -84)
			if _dist <= 0.0:
				queue_free()
				return
		queue_redraw()

	func _draw() -> void:
		var from := owner_f.global_position + Vector2(dir * 22.0, -84) - global_position
		draw_line(from, Vector2.ZERO, TechGadgets.BLACK, 4.0)
		draw_line(from, Vector2.ZERO, TechGadgets.METAL_SHADE, 2.0)
		var claw := PackedVector2Array([Vector2(-4 * dir, -7), Vector2(10 * dir, 0), Vector2(-4 * dir, 7), Vector2(2 * dir, 0)])
		draw_colored_polygon(claw, TechGadgets.METAL)
		draw_polyline(claw + PackedVector2Array([claw[0]]), TechGadgets.BLACK, 1.5)
