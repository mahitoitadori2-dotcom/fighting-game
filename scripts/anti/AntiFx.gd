class_name AntiFx
extends RefCounted
## Pieces of the ANTI ARCHITECT's moves (small self-freeing nodes):
##   Fly     Workflies / BattleFlies: home in on the nearest enemy; with no target they fly
##           straight ahead and come back to him
##   Beam    the Anti Laser's visual (the damage is instant, done by the fighter)
##   Pool    Energy Pool: orange energy juice on the floor, damage over time
##   Shard   Never Out Of Plans: metal / energy shards flying out in all directions
##   Clump   Never Out Of Plans: the metal clump that forms, shakes and explodes

const ORANGE := Color(1.0, 0.45, 0.05)
const ORANGE_HI := Color(1.0, 0.82, 0.45)
const MAGENTA := Color(0.85, 0.2, 0.8)
const METAL := Color(0.55, 0.52, 0.48)


## Hit `f` for `src` (respects allies / dead). Returns the CombatManager result.
static func hit(src: Fighter, f: Fighter, dmg: int, kb: Vector2, origin: Vector2, move: String, kind: String = "", onsl: bool = false) -> String:
	var h := HitData.new()
	h.source = src if src != null and is_instance_valid(src) else null
	h.damage = dmg
	var dx := signf(f.global_position.x - origin.x)
	if dx == 0.0:
		dx = 1.0
	h.knockback = Vector2(dx * kb.x, kb.y)
	h.origin = origin
	h.hit_type = "projectile"
	h.move = move
	h.damage_kind = kind
	h.onslaught = onsl
	return CombatManager.apply_hit(h, f)


static func enemies_of(src: Fighter) -> Array:
	var out: Array = []
	if src == null or not is_instance_valid(src) or not src.is_inside_tree():
		return out
	for n in src.get_tree().get_nodes_in_group("fighters") + src.get_tree().get_nodes_in_group("helpers"):
		var f := n as Fighter
		if f != null and not f.is_dead and not CombatManager.passes_through(src, f):
			out.append(f)
	return out


# ============================================================
# FLIES
# ============================================================
class Fly extends Node2D:
	var source: Fighter
	var damage := 3
	var hits := 1                      # Hits before it pops (BattleFlies: 2)
	var speed := 560.0
	var life := 3.0
	var battle := false                # BattleFly look (bigger, red-orange, faster wings)
	var dir := 1.0
	var onslaught := false
	var vel := Vector2.ZERO
	var _t := 0.0
	var _cool := 0.0                   # Short pause between two hits on the same target
	var _returning := false

	func _ready() -> void:
		z_index = 9
		if vel == Vector2.ZERO:
			vel = Vector2(dir * speed, randf_range(-60.0, 60.0))

	func make_onslaught() -> void:
		onslaught = true
		damage = roundi(float(damage) * 1.5)
		speed *= 1.25
		hits += 1

	func _physics_process(delta: float) -> void:
		if source != null and is_instance_valid(source) and source.is_time_frozen():
			return
		_t += delta
		_cool = maxf(_cool - delta, 0.0)
		if _t >= life or source == null or not is_instance_valid(source):
			_pop()
			return
		var tgt := _nearest()
		var want: Vector2
		if tgt != null:
			want = (tgt.global_position + Vector2(0, -60) - global_position).normalized() * speed
		elif _t > 0.7 or _returning:
			_returning = true                       # Nothing to hunt: come back home
			var home := source.global_position + Vector2(0, -80)
			want = (home - global_position).normalized() * speed
			if global_position.distance_to(home) < 30.0:
				queue_free()
				return
		else:
			want = Vector2(dir * speed, 0.0)        # Straight ahead first
		vel = vel.lerp(want, clampf(delta * (7.0 if battle else 5.0), 0.0, 1.0))
		global_position += vel * delta + Vector2(0, sin(_t * 30.0) * 1.5)
		if tgt != null and _cool <= 0.0:
			var c := tgt.global_position + Vector2(0, -tgt.data.body_size.y * 0.5)
			if absf(c.x - global_position.x) < 14.0 + tgt.data.body_size.x * 0.5 and absf(c.y - global_position.y) < 14.0 + tgt.data.body_size.y * 0.5:
				AntiFx.hit(source, tgt, damage, Vector2(90, -60), global_position, "battleflies" if battle else "workflies", "", onslaught)
				Effects.hit_sparks(self, global_position, 3, 0.6)
				hits -= 1
				_cool = 0.25
				vel = -vel * 0.6                    # Bounce off for the second hit
				if hits <= 0:
					_pop()
					return
		queue_redraw()

	func _nearest() -> Fighter:
		var best: Fighter = null
		var bd := 900.0
		for f in AntiFx.enemies_of(source):
			var d := (f as Fighter).global_position.distance_to(global_position)
			if d < bd:
				bd = d
				best = f
		return best

	func _pop() -> void:
		Effects.explosion(self, global_position, 14.0 if not battle else 20.0, true)
		queue_free()

	func _draw() -> void:
		var body := ORANGE if not battle else Color(1.0, 0.25, 0.1)
		if onslaught:
			draw_circle(Vector2.ZERO, 12.0, Color(1.0, 0.55, 0.1, 0.35))
		var flap := sin(_t * 60.0) * 5.0
		for s: float in [-1.0, 1.0]:                # Wings
			draw_colored_polygon(PackedVector2Array([Vector2(-2, -2), Vector2(-8, -8 + s * flap - 4), Vector2(4, -6 + s * flap)]), Color(0.9, 0.9, 1.0, 0.6))
		var r := 5.0 if not battle else 6.5
		draw_circle(Vector2.ZERO, r + 2.0, Color(0, 0, 0))
		draw_circle(Vector2.ZERO, r, body)
		draw_circle(Vector2(r * 0.6, -1), r * 0.45, Color(0.1, 0.1, 0.12))       # Head
		draw_circle(Vector2(r * 0.8, -2), 1.3, ORANGE_HI)
		if battle:                                  # Stinger
			draw_colored_polygon(PackedVector2Array([Vector2(-r, -2), Vector2(-r, 2), Vector2(-r - 6, 0)]), Color(0.1, 0.1, 0.1))


# ============================================================
# ANTI LASER (visual)
# ============================================================
class Beam extends Node2D:
	var length := 900.0
	var height := 22.0
	var dir := 1.0
	var big := false
	var _t := 0.0
	const LEN := 0.35

	func _ready() -> void:
		z_index = 9

	func _process(delta: float) -> void:
		_t += delta
		if _t >= LEN:
			queue_free()
			return
		queue_redraw()

	func _draw() -> void:
		var k := 1.0 - _t / LEN
		var h := height * (1.6 if big else 1.0) * (0.4 + 0.6 * k)
		var end := Vector2(dir * length, 0)
		draw_line(Vector2.ZERO, end, Color(ORANGE.r, ORANGE.g, ORANGE.b, 0.3 * k), h * 2.2, true)
		draw_line(Vector2.ZERO, end, Color(ORANGE.r, ORANGE.g, ORANGE.b, 0.9 * k), h, true)
		draw_line(Vector2.ZERO, end, Color(ORANGE_HI.r, ORANGE_HI.g, ORANGE_HI.b, k), h * 0.35, true)
		draw_circle(Vector2.ZERO, h * 0.9, Color(ORANGE_HI.r, ORANGE_HI.g, ORANGE_HI.b, k))


# ============================================================
# ENERGY POOL
# ============================================================
class Pool extends Node2D:
	var source: Fighter
	var width := 320.0
	var duration := 5.0
	var tick := 0.5
	var tick_damage := 2
	var _t := 0.0
	var _next := {}                    # Fighter -> time of its next tick

	func _ready() -> void:
		z_index = -1

	func _physics_process(delta: float) -> void:
		if source != null and is_instance_valid(source) and source.is_time_frozen():
			return
		_t += delta
		if _t >= duration:
			queue_free()
			return
		for f in AntiFx.enemies_of(source):
			var ff := f as Fighter
			if absf(ff.global_position.x - global_position.x) > width * 0.5 or absf(ff.global_position.y - global_position.y) > 40.0:
				continue
			if _t < float(_next.get(ff, 0.0)):
				continue
			_next[ff] = _t + tick
			var h := HitData.new()
			h.source = source if source != null and is_instance_valid(source) else null
			h.damage = tick_damage
			h.knockback = Vector2.ZERO
			h.origin = global_position
			h.hit_type = "energy_pool"
			h.move = "energy_pool"
			h.is_tick = true
			h.causes_hitstun = false
			h.blockable = false
			CombatManager.apply_hit(h, ff)
		queue_redraw()

	func _draw() -> void:
		var grow := clampf(_t / 0.3, 0.0, 1.0)
		var fade := clampf((duration - _t) / 0.6, 0.0, 1.0)
		var w := width * 0.5 * grow
		var pts := PackedVector2Array()
		for i in 17:
			var u := float(i) / 16.0
			pts.append(Vector2(-w + u * w * 2.0, -4.0 - sin(u * PI) * 10.0 - sin(_t * 4.0 + u * 9.0) * 2.0))
		pts.append(Vector2(w, 2))
		pts.append(Vector2(-w, 2))
		draw_colored_polygon(pts, Color(ORANGE.r, ORANGE.g, ORANGE.b, 0.75 * fade))
		for k in 5:                                  # Bubbles
			var bx := -w * 0.8 + fmod(float(k) * 71.0 + _t * 30.0, w * 1.6)
			draw_circle(Vector2(bx, -8.0 - fmod(_t * 20.0 + float(k) * 7.0, 14.0)), 3.0, Color(ORANGE_HI.r, ORANGE_HI.g, ORANGE_HI.b, 0.8 * fade))
		draw_polyline(pts.slice(0, 17), Color(ORANGE_HI.r, ORANGE_HI.g, ORANGE_HI.b, fade), 3.0)


# ============================================================
# SHARDS (Never Out Of Plans)
# ============================================================
class Shard extends Node2D:
	var source: Fighter
	var vel := Vector2.ZERO
	var damage := 3
	var energy := false                # Energy shard (glowing orange) vs metal shard (grey)
	var life := 1.2
	var _t := 0.0
	var _hit := []

	func _ready() -> void:
		z_index = 9

	func _physics_process(delta: float) -> void:
		_t += delta
		if _t >= life:
			queue_free()
			return
		vel.y += 700.0 * delta
		global_position += vel * delta
		rotation = vel.angle()
		for f in AntiFx.enemies_of(source):
			var ff := f as Fighter
			if _hit.has(ff):
				continue
			var c := ff.global_position + Vector2(0, -ff.data.body_size.y * 0.5)
			if absf(c.x - global_position.x) < 12.0 + ff.data.body_size.x * 0.5 and absf(c.y - global_position.y) < 12.0 + ff.data.body_size.y * 0.5:
				_hit.append(ff)
				AntiFx.hit(source, ff, damage, Vector2(160, -140), global_position, "never_out_of_plans", HitData.KIND_EXPLOSION)
		queue_redraw()

	func _draw() -> void:
		var a := 1.0 - clampf((_t - life + 0.2) / 0.2, 0.0, 1.0)
		var pts := PackedVector2Array([Vector2(10, 0), Vector2(-4, -4), Vector2(-8, 0), Vector2(-4, 4)])
		var col := Color(ORANGE.r, ORANGE.g, ORANGE.b, a) if energy else Color(METAL.r, METAL.g, METAL.b, a)
		if energy:
			draw_circle(Vector2.ZERO, 9.0, Color(ORANGE.r, ORANGE.g, ORANGE.b, 0.3 * a))
		draw_colored_polygon(pts, col)
		FighterArt.outline(self, pts, 2.0, Color(0, 0, 0, a))


# ============================================================
# THE CLUMP (Never Out Of Plans)
# ============================================================
class Clump extends Node2D:
	var grow := 0.0                    # 0..1 while the metal comes together
	var _t := 0.0

	func _process(delta: float) -> void:
		_t += delta
		queue_redraw()

	func _draw() -> void:
		var shake := Vector2(sin(_t * 70.0), cos(_t * 63.0)) * 3.0 * grow
		var r := 10.0 + 34.0 * grow
		draw_circle(shake, r * 1.6, Color(ORANGE.r, ORANGE.g, ORANGE.b, 0.25 * grow))
		var pts := PackedVector2Array()
		for i in 10:
			pts.append(shake + Vector2.from_angle(float(i) * TAU / 10.0 + _t) * r * (0.8 + 0.25 * sin(float(i) * 2.7)))
		draw_colored_polygon(pts, METAL)
		for k in 4:                                  # Glowing seams between the welded scraps
			var a := float(k) * 1.6 + _t * 2.0
			draw_line(shake + Vector2.from_angle(a) * r * 0.2, shake + Vector2.from_angle(a + 0.5) * r * 0.85, ORANGE_HI, 3.0)
		FighterArt.outline(self, pts, 3.5)
		for k in 6:                                  # Scraps still flying in
			var u := fmod(_t * 2.0 + float(k) / 6.0, 1.0)
			var from := Vector2.from_angle(float(k) * TAU / 6.0) * (90.0 * (1.0 - u) + r)
			draw_rect(Rect2(shake + from - Vector2(4, 3), Vector2(8, 6)), METAL.lightened(0.2))
