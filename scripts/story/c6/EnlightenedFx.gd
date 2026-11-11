class_name EnlightenedFx
extends RefCounted
## THE ENLIGHTENED CHASE (Story part after Colosseum 5) effects, drawn in code:
##   draw_object()   explosive BARREL, HOLY HAND GRENADE, falling RELICS (vase, candelabra,
##                   tablet, bell, statue head) - used by EnemyProjectile looks "barrel",
##                   "holy_grenade", "relic", "relic_bomb" and by the cutscenes
##   Thrower         the Enlightened One flying over the arena, throwing barrels + grenades
##                   (start / end of every Enlightened Chase level except the last: StoryManager)
##   Laser           "Enlightened Laser": a warning line, then a beam across the arena

const GOLD := Color(1.0, 0.82, 0.3)
const GOLD_HI := Color(1.0, 0.96, 0.7)
const WOOD := Color(0.50, 0.30, 0.15)
const RED := Color(0.85, 0.15, 0.1)
const BLACK := Color(0, 0, 0)

## Looks that explode (barrel / grenade / exploding relic): EnemyProjectile uses this.
const EXPLOSIVE := ["barrel", "holy_grenade", "relic_bomb"]


## Draw object `look` centred at p, rotated by rot. seed picks the relic type.
static func draw_object(c: CanvasItem, look: String, p: Vector2, rot: float, seed_v: int, t: float) -> void:
	c.draw_set_transform(p, rot, Vector2.ONE)
	match look:
		"barrel":
			_barrel(c, t)
		"holy_grenade":
			_grenade(c, t)
		"relic_bomb":
			if seed_v % 2 == 0:
				_barrel(c, t)
			else:
				_grenade(c, t)
		_:
			_relic(c, seed_v % 5, t)
	c.draw_set_transform(Vector2.ZERO, 0.0, Vector2.ONE)


static func _barrel(c: CanvasItem, t: float) -> void:
	var body := PackedVector2Array([Vector2(-14, -20), Vector2(14, -20), Vector2(18, 0), Vector2(14, 20), Vector2(-14, 20), Vector2(-18, 0)])
	c.draw_colored_polygon(body, WOOD)
	for y: float in [-12.0, 12.0]:
		c.draw_line(Vector2(-17, y), Vector2(17, y), Color(0.3, 0.3, 0.32), 4.0)
	c.draw_rect(Rect2(-16, -5, 32, 10), RED)
	# Flame mark (explosive!)
	c.draw_colored_polygon(PackedVector2Array([Vector2(-5, 4), Vector2(0, -5), Vector2(5, 4)]), Color(1.0, 0.8, 0.2))
	FighterArt.outline(c, body, 3.0)
	# Burning fuse
	c.draw_line(Vector2(0, -20), Vector2(4, -28), BLACK, 2.0)
	c.draw_circle(Vector2(4, -29), 3.0 + sin(t * 30.0), Color(1.0, 0.6, 0.15))


static func _grenade(c: CanvasItem, t: float) -> void:
	c.draw_circle(Vector2(0, 2), 16.0, Color(1.0, 0.85, 0.3, 0.25 + 0.15 * sin(t * 12.0)))
	c.draw_circle(Vector2(0, 2), 13.0, BLACK)
	c.draw_circle(Vector2(0, 2), 10.5, GOLD)
	c.draw_circle(Vector2(-3, -1), 4.0, GOLD_HI)
	c.draw_line(Vector2(-10, 4), Vector2(10, 4), Color(0.6, 0.15, 0.2), 3.0)       # Jewelled band
	c.draw_line(Vector2(0, -10), Vector2(0, -24), BLACK, 5.0)                        # Cross on top
	c.draw_line(Vector2(-6, -18), Vector2(6, -18), BLACK, 5.0)
	c.draw_line(Vector2(0, -10), Vector2(0, -24), GOLD, 2.5)
	c.draw_line(Vector2(-6, -18), Vector2(6, -18), GOLD, 2.5)


## 0 vase, 1 candelabra, 2 stone tablet, 3 bell, 4 statue head.
static func _relic(c: CanvasItem, kind: int, _t: float) -> void:
	match kind:
		0:
			var v := PackedVector2Array([Vector2(-8, -20), Vector2(8, -20), Vector2(6, -14), Vector2(14, 2), Vector2(9, 18), Vector2(-9, 18), Vector2(-14, 2), Vector2(-6, -14)])
			c.draw_colored_polygon(v, GOLD)
			c.draw_line(Vector2(-12, 2), Vector2(12, 2), Color(0.3, 0.45, 0.85), 3.0)
			FighterArt.outline(c, v, 3.0)
		1:
			c.draw_line(Vector2(0, 18), Vector2(0, -6), BLACK, 6.0)
			c.draw_line(Vector2(0, 18), Vector2(0, -6), GOLD, 3.0)
			c.draw_arc(Vector2(0, -6), 14.0, 0.0, PI, 12, BLACK, 6.0)
			c.draw_arc(Vector2(0, -6), 14.0, 0.0, PI, 12, GOLD, 3.0)
			for x: float in [-14.0, 0.0, 14.0]:
				c.draw_rect(Rect2(x - 3, -18, 6, 10), Color(0.96, 0.93, 0.84))
				c.draw_circle(Vector2(x, -21), 3.0, Color(1.0, 0.7, 0.2))
			c.draw_rect(Rect2(-10, 16, 20, 5), GOLD)
		2:
			var tb := FighterArt.rrect_points(Rect2(-13, -20, 26, 38), 8.0)
			c.draw_colored_polygon(tb, Color(0.72, 0.70, 0.66))
			for k in 4:
				c.draw_line(Vector2(-8, -10 + k * 7), Vector2(8, -10 + k * 7), Color(0.4, 0.38, 0.35), 2.0)
			FighterArt.outline(c, tb, 3.0)
		3:
			var bl := PackedVector2Array([Vector2(-6, -18), Vector2(6, -18), Vector2(10, -4), Vector2(16, 14), Vector2(-16, 14), Vector2(-10, -4)])
			c.draw_colored_polygon(bl, Color(0.85, 0.62, 0.25))
			FighterArt.outline(c, bl, 3.0)
			c.draw_circle(Vector2(0, 16), 4.0, Color(0.5, 0.35, 0.12))
		_:
			FighterArt.ball(c, Vector2(0, 0), 16.0, Color(0.92, 0.90, 0.84), Color(0.70, 0.66, 0.58), Color(1, 1, 1))
			c.draw_rect(Rect2(2, -4, 10, 3), Color(0.3, 0.28, 0.25))
			c.draw_line(Vector2(-14, -10), Vector2(14, -16), GOLD, 4.0)                 # Golden circlet


# ============================================================
# THE THROWER: the Enlightened One flying over the arena
# ============================================================
## Flies from one side to the other above the floor and lobs `throws` barrels / holy hand
## grenades at the player. `done` fires when he is gone and everything has landed.
class Thrower extends Node2D:
	signal done
	var target: Node2D
	var floor_y := 520.0
	var from_x := 0.0
	var to_x := 0.0
	var throws := 8
	var damage := 6
	var time := 4.2
	var _t := 0.0
	var _thrown := 0
	var _finished := false

	func _ready() -> void:
		z_index = 6
		global_position = Vector2(from_x, floor_y - 330.0)
		SoundManager.play_sfx("holy", -4.0)

	func _process(delta: float) -> void:
		_t += delta
		var k := clampf(_t / time, 0.0, 1.0)
		global_position = Vector2(lerpf(from_x, to_x, k), floor_y - 330.0 + sin(_t * 3.0) * 18.0)
		# Only throws while on screen (shots that start off screen are culled at once)
		if _thrown < throws and _t >= 0.5 + float(_thrown) * (time - 1.0) / float(throws) and OptimizationManager.on_screen(global_position, 40.0):
			_throw()
		if k >= 1.0 and not _finished:
			_finished = true
			visible = false
			var tm := get_tree().create_timer(1.3)              # Let the last ones land
			tm.timeout.connect(func() -> void:
				done.emit()
				queue_free())
		queue_redraw()

	func _throw() -> void:
		_thrown += 1
		var tx := global_position.x
		if target != null and is_instance_valid(target):
			tx = target.global_position.x + randf_range(-240.0, 240.0)
		var look := "barrel" if _thrown % 2 == 1 else "holy_grenade"
		var p := OptimizationManager.take(EnemyProjectile) as EnemyProjectile
		p.source = null
		p.kind = EnemyProjectile.Kind.ARC
		p.look = look
		p.damage = damage
		p.knockback = Vector2(260, -300)
		p.radius = 70.0
		p.pierce = false
		p.size = Vector2(70, 70)
		var flight := 1.0
		p.lifetime = flight + 2.0
		p.move = "enlightened_bombard"
		var from := global_position + Vector2(0, 30)
		var drop := floor_y - from.y
		p.arc_velocity = Vector2((tx - from.x) / flight, (drop - 0.5 * EnemyProjectile.ARC_GRAVITY * flight * flight) / flight)
		var holy := look == "holy_grenade"
		p.on_land = func(pos: Vector2) -> void:
			EnlightenedFx.blast(get_parent(), pos, holy)
		get_parent().add_child(p)
		p.global_position = from
		SoundManager.play_sfx("swing", -6.0)

	func _draw() -> void:
		if not visible:
			return
		draw_circle(Vector2(0, -60), 70.0, Color(1.0, 0.85, 0.35, 0.12))
		for i in 3:                                              # Golden wake behind him
			draw_circle(Vector2(-signf(to_x - from_x) * (30.0 + float(i) * 26.0), -50.0), 14.0 - float(i) * 3.0, Color(1.0, 0.85, 0.4, 0.35 - float(i) * 0.1))
		var f := signf(to_x - from_x)
		draw_set_transform(Vector2.ZERO, 0.0, Vector2(f, 1.0))
		EnlightenedOneArt._draw_figure(self, {"t": _t, "floor": false, "cast": 0.6 + 0.4 * sin(_t * 8.0)})
		draw_set_transform(Vector2.ZERO, 0.0, Vector2.ONE)


## Barrel / grenade landing: the boom (damage was done by the projectile's radius).
static func blast(ctx: Node, pos: Vector2, holy: bool) -> void:
	if ctx == null:
		return
	Effects.explosion(ctx, pos + Vector2(0, -24), 80.0, not holy, not holy)
	if holy:
		Effects.gold_burst(ctx, pos + Vector2(0, -30), 90.0)
		SoundManager.play_sfx("holy", -6.0)
	SoundManager.play_sfx("explosion", -4.0)
	Effects.shake(ctx, 7.0)


# ============================================================
# ENLIGHTENED LASER
# ============================================================
## horizontal: a beam across the whole arena at height `at` (world y); else vertical at x `at`.
class Laser extends Node2D:
	var source: Fighter
	var horizontal := true
	var at := 0.0
	var half_len := 1400.0
	var warn := 0.9
	var fire := 0.45
	var damage := 8
	var thick := 46.0
	var _t := 0.0
	var _hit: Array = []

	func _ready() -> void:
		z_index = 7
		global_position = Vector2(0, at) if horizontal else Vector2(at, 0)
		SoundManager.play_sfx("telegraph", -4.0)

	func _process(delta: float) -> void:
		if source != null and is_instance_valid(source) and source.is_time_frozen():
			return
		var was := _t
		_t += delta
		if was < warn and _t >= warn:
			SoundManager.play_sfx("beam", -2.0)
			Effects.shake(self, 6.0)
		if _t >= warn and _t < warn + fire:
			_hit_band()
		if _t >= warn + fire + 0.25:
			queue_free()
			return
		queue_redraw()

	func _hit_band() -> void:
		for n in get_tree().get_nodes_in_group("fighters"):
			var f := n as Fighter
			if f == null or f.is_dead or _hit.has(f):
				continue
			if source != null and is_instance_valid(source) and CombatManager.are_allies(source, f):
				continue
			var c := f.global_position + Vector2(0, -f.data.body_size.y * 0.5)
			var d := absf(c.y - at) if horizontal else absf(c.x - at)
			var half := (f.data.body_size.y if horizontal else f.data.body_size.x) * 0.5
			if d > thick * 0.5 + half:
				continue
			_hit.append(f)
			var h := HitData.new()
			h.source = source if source != null and is_instance_valid(source) else null
			h.damage = damage
			var dx := signf(f.global_position.x - (source.global_position.x if source != null and is_instance_valid(source) else f.global_position.x - 1.0))
			h.knockback = Vector2(dx * 200.0, -260.0)
			h.origin = c
			h.hit_type = "enemy"
			h.move = "enlightened_laser"
			CombatManager.apply_hit(h, f)

	func _draw() -> void:
		var a := Vector2(-half_len, 0) if horizontal else Vector2(0, -half_len)
		var b := -a
		if horizontal:
			a.x += -global_position.x + _cam_x()
			b.x += -global_position.x + _cam_x()
		if _t < warn:
			var k := _t / warn
			draw_line(a, b, Color(1.0, 0.9, 0.4, 0.25 + 0.5 * k * absf(sin(_t * 20.0))), 3.0 + 4.0 * k)
			return
		var f := 1.0 - clampf((_t - warn - fire) / 0.25, 0.0, 1.0)
		draw_line(a, b, Color(1.0, 0.85, 0.35, 0.35 * f), thick * 1.8)
		draw_line(a, b, Color(1.0, 0.9, 0.5, 0.9 * f), thick)
		draw_line(a, b, Color(1, 1, 1, f), thick * 0.35)

	func _cam_x() -> float:
		var cam := get_viewport().get_camera_2d()
		return cam.get_screen_center_position().x if cam != null else 0.0
