class_name Effects
extends RefCounted
## THE EFFECTS MANAGER. Static helpers for every visual / feel effect:
##   explosion, popup, bursts, sparks, trails, death decals...
##   GAME FEEL: on_hit() = hitstop + screen shake + hit sparks + attacker impact
##   flash + hit sound hook.
##
## PERFORMANCE: every effect here is POOLED (OptimizationManager.take / release)
## and counts toward the 200-particle cap. Bursts, popups and explosions DRAW ONCE
## and then only animate their transform / modulate (no per-frame redraw).
## Usage: Effects.explosion(self, pos, radius, orange)  /  Effects.popup(self, pos, "text")

static func _root(ctx: Node) -> Node:
	return ctx.get_tree().current_scene


static func _spawn(_ctx: Node, script: Script, pos: Vector2) -> Node2D:
	var n := OptimizationManager.take(script) as Node2D
	n.position = pos
	return n


static func _add(ctx: Node, n: Node) -> void:
	if ctx == null or not ctx.is_inside_tree():
		return
	_root(ctx).add_child(n)


# ============================================================
# GAME FEEL
# ============================================================
const HIT_TICK := 0          # Damage-over-time ticks: sparks only
const HIT_NORMAL := 1
const HIT_HEAVY := 2         # Onslaught / Gorilla punches
const HIT_ULT := 3           # Ultimates

const HITSTOP := [0.0, 0.06, 0.1, 0.2]
const SHAKE := [0.0, 3.0, 9.0, 14.0]
const ULT_MOVES := ["triple_rocket", "faoth", "mini_eternal", "shadow_swarm", "double_trouble",
	"volatile_nightmare", "ritual", "godly_light", "throne"]


static func hit_strength(hit: HitData) -> int:
	if hit.is_tick:
		return HIT_TICK
	if hit.move in ULT_MOVES:
		return HIT_ULT
	if hit.onslaught or hit.move == "gorilla":
		return HIT_HEAVY
	return HIT_NORMAL


## Called by CombatManager for every hit that deals damage.
static func on_hit(hit: HitData, victim: Fighter) -> void:
	var s := hit_strength(hit)
	var pos := victim.global_position + Vector2(randf_range(-8.0, 8.0), -70.0 + randf_range(-10.0, 10.0))
	hit_sparks(victim, pos, 4 + s * 4, 1.0 + 0.35 * s)
	play_hit_sound(victim, ["hit_tick", "hit", "hit_heavy", "hit_ultimate"][s], pos)
	if s == HIT_TICK:
		return
	hitstop(victim, HITSTOP[s])
	shake(victim, SHAKE[s])
	if hit.source != null and is_instance_valid(hit.source) and hit.source.visuals != null:
		hit.source._flash(Color(6, 6, 6), 0.07)          # Impact frame: attacker flashes white


## Called by CombatManager when a hit is blocked.
static func on_block(victim: Fighter, perfect: bool) -> void:
	hit_sparks(victim, victim.global_position + Vector2(victim.facing * 26.0, -76.0), 6 if perfect else 4, 0.8)
	play_hit_sound(victim, "block_perfect" if perfect else "block", victim.global_position)
	shake(victim, 2.0)
	if perfect:
		hitstop(victim, 0.08)


# ----- Hitstop: brief global slow-down (real-time watcher restores it) -----
static var _hitstop_until := 0
static var _watcher: Node = null


static func hitstop(ctx: Node, seconds: float) -> void:
	if seconds <= 0.0 or ctx == null or not ctx.is_inside_tree():
		return
	var until := Time.get_ticks_msec() + int(seconds * 1000.0)
	if until <= _hitstop_until:
		return
	_hitstop_until = until
	Engine.time_scale = 0.05
	if _watcher == null or not is_instance_valid(_watcher):
		_watcher = HitstopWatcher.new()
		ctx.get_tree().root.add_child.call_deferred(_watcher)
	_watcher.set_process(true)


## Restores normal speed once the hitstop's REAL time is up. Sleeps when idle.
class HitstopWatcher extends Node:
	func _ready() -> void:
		process_mode = Node.PROCESS_MODE_ALWAYS

	func _process(_delta: float) -> void:
		if Time.get_ticks_msec() >= Effects._hitstop_until:
			Engine.time_scale = 1.0
			set_process(false)                   # Nothing to do until the next hitstop


## Safety reset (scene changes).
static func clear_hitstop() -> void:
	_hitstop_until = 0
	Engine.time_scale = 1.0


# ----- Screen shake (ArenaCamera.add_shake) -----
static func shake(ctx: Node, strength: float) -> void:
	if ctx == null or not ctx.is_inside_tree():
		return
	var cam := ctx.get_viewport().get_camera_2d()
	if cam != null and cam.has_method("add_shake"):
		cam.add_shake(strength)


# ----- Sound hook (safe when no sound files exist yet) -----
## Kept for all the existing calls: forwards to the SoundManager autoload, which maps
## the name (hit, block, rotor_bark, frog_croak...) to a file in res://audio/sfx/.
## Missing files are silent. ctx / pos are unused (non-positional AudioStreamPlayers).
static func play_hit_sound(_ctx: Node, kind: String = "hit", _pos: Vector2 = Vector2.INF) -> void:
	SoundManager.play_sfx(kind)


# ----- Ground helpers (decals sit ON the floor, never float) -----
## World position of the floor under `pos`, or null if there is none (off the island).
static func ground_below(ctx: Node2D, pos: Vector2, max_drop: float = 600.0) -> Variant:
	if ctx == null or not ctx.is_inside_tree():
		return null
	var q := PhysicsRayQueryParameters2D.create(pos + Vector2(0, -20), pos + Vector2(0, max_drop), CombatManager.WORLD_LAYER)
	var res := ctx.get_world_2d().direct_space_state.intersect_ray(q)
	return null if res.is_empty() else res["position"]


# ============================================================
# SPAWNERS
# ============================================================
static func hit_sparks(ctx: Node, pos: Vector2, count: int = 6, size_mult: float = 1.0) -> void:
	var s := _spawn(ctx, HitSparkFx, pos) as HitSparkFx
	s.count = GraphicsSettings.fx_count(count)         # Fewer on Potato / Fast, more on Real
	s.size_mult = size_mult
	_add(ctx, s)


## Comic star-burst explosion. orange = Onslaught version, fire = lingering flames.
static func explosion(ctx: Node, pos: Vector2, radius: float, orange: bool = false, fire: bool = false) -> void:
	SoundManager.play_sfx("explosion")
	var e := _spawn(ctx, ExplosionFx, pos) as ExplosionFx
	e.radius = radius
	e.orange = orange
	e.fire = fire
	_add(ctx, e)


## Floating text (damage numbers, "PERFECT BLOCK!", ...).
static func popup(ctx: Node, pos: Vector2, text: String, color: Color = Color.WHITE, font_size: int = 22) -> void:
	var p := _spawn(ctx, PopupFx, pos) as PopupFx
	p.text = text
	p.color = color
	p.font_size = font_size
	_add(ctx, p)


## BIG move / ultimate name across the SCREEN (screen space, never cut off: the font
## shrinks until the whole name fits the window). side: 1 = you (upper), 2 = opponent
## (a bit lower), 0 = centre. Replaces the small world popups for move names.
static func announce(ctx: Node, text: String, color: Color = Color.WHITE, side: int = 0) -> void:
	if ctx == null or not ctx.is_inside_tree():
		return
	var root := _root(ctx)
	if root == null:
		return
	var layer := root.get_node_or_null("AnnounceLayer") as AnnounceLayer
	if layer == null:
		layer = AnnounceLayer.new()
		layer.name = "AnnounceLayer"
		root.add_child(layer)
	layer.show_text(text, color, side)


## Screen-space layer for announce(). One label per side, reused.
class AnnounceLayer extends CanvasLayer:
	const MAX_FONT := 64
	const MIN_FONT := 22
	var _labels := {}                       # side -> Label
	var _tweens := {}

	func _ready() -> void:
		layer = 14

	func show_text(text: String, color: Color, side: int) -> void:
		var l: Label = _labels.get(side)
		if l == null:
			l = Label.new()
			l.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
			l.vertical_alignment = VERTICAL_ALIGNMENT_CENTER
			l.mouse_filter = Control.MOUSE_FILTER_IGNORE
			l.add_theme_color_override("font_outline_color", Color(0, 0, 0))
			l.add_theme_color_override("font_shadow_color", Color(0, 0, 0, 0.6))
			l.add_theme_constant_override("shadow_offset_x", 4)
			l.add_theme_constant_override("shadow_offset_y", 4)
			add_child(l)
			_labels[side] = l
		var vp := get_viewport().get_visible_rect().size
		# Fit: biggest font where the WHOLE name fits in 92% of the screen width
		var font := l.get_theme_default_font()
		var fs := MAX_FONT
		while fs > MIN_FONT and font.get_string_size(text, HORIZONTAL_ALIGNMENT_LEFT, -1, fs).x + fs * 0.6 > vp.x * 0.92:
			fs -= 2
		l.text = text
		l.add_theme_font_size_override("font_size", fs)
		@warning_ignore("integer_division")
		l.add_theme_constant_override("outline_size", maxi(6, fs / 5))
		l.add_theme_color_override("font_color", color)
		var y := vp.y * (0.27 if side == 1 else (0.43 if side == 2 else 0.35))   # You above, opponent below: never overlap
		l.size = Vector2(vp.x, fs * 1.6)
		l.position = Vector2(0, y - l.size.y * 0.5)
		l.pivot_offset = l.size * 0.5
		l.scale = Vector2(1.5, 1.5)
		l.modulate = Color(1, 1, 1, 0)
		if _tweens.has(side) and (_tweens[side] as Tween).is_valid():
			(_tweens[side] as Tween).kill()
		var tw := create_tween()
		_tweens[side] = tw
		tw.set_ignore_time_scale(true)             # Hitstop never freezes the name
		tw.set_parallel(true)
		tw.tween_property(l, "scale", Vector2.ONE, 0.18).set_trans(Tween.TRANS_BACK).set_ease(Tween.EASE_OUT)
		tw.tween_property(l, "modulate:a", 1.0, 0.1)
		tw.chain().tween_interval(0.9)
		tw.chain().tween_property(l, "modulate:a", 0.0, 0.3)


static func gold_burst(ctx: Node, pos: Vector2, radius: float) -> void:
	_burst(ctx, pos, radius, BurstFx.GOLD)


## PURE RED fire burst (Nightmare Lord). No orange / yellow anywhere.
static func red_burst(ctx: Node, pos: Vector2, radius: float) -> void:
	_burst(ctx, pos, radius, BurstFx.RED)


## Black + purple void splash (Warrior hits).
static func void_burst(ctx: Node, pos: Vector2, radius: float) -> void:
	_burst(ctx, pos, radius, BurstFx.VOID)


static func _burst(ctx: Node, pos: Vector2, radius: float, style: int) -> void:
	var b := _spawn(ctx, BurstFx, pos) as BurstFx
	b.radius = radius
	b.style = style
	_add(ctx, b)


## Fading ribbon behind a moving node (rockets, beams, bats, throne, spikes...).
static func trail(target: Node2D, color: Color, width: float = 10.0, length: int = 12) -> void:
	if target == null or not target.is_inside_tree():
		return
	length = GraphicsSettings.trail_length(length)    # 0 on Potato = no trail at all
	if length < 2:
		return
	var t := OptimizationManager.take(TrailFx) as TrailFx
	t.target = target
	t.target_gen = target.get("pool_gen") if "pool_gen" in target else 0
	t.color = color
	t.width = width
	t.max_points = length
	t.z_index = target.z_index - 1
	_root(target).add_child(t)


## Closing ring on a fighter (debug attack warning). Inner white ring = perfect-block zone.
static func telegraph(target: Node2D, duration: float, window: float) -> void:
	var r := RingFx.new()
	r.duration = duration
	r.window = window
	r.position = Vector2(0, -64)
	target.add_child(r)


## Full-screen "TIME STOPPED" tint + countdown. Removes itself when time resumes.
static func time_stop_overlay(ctx: Node) -> void:
	_root(ctx).add_child(TimeStopFx.new())


# ============================================================
# POOLED EFFECT NODES
# ============================================================
## Short white / yellow spark streaks. Redraws for its 0.22 s life (lines move).
class HitSparkFx extends Node2D:
	var pool_gen := 0
	var count := 6
	var size_mult := 1.0
	var _t := 0.0
	var _sparks: Array[Vector3] = []          # angle, speed, length

	func _ready() -> void:
		z_index = 40

	func _enter_tree() -> void:
		_t = 0.0
		_sparks.clear()
		for i in count:
			_sparks.append(Vector3(randf() * TAU, randf_range(180.0, 380.0) * size_mult, randf_range(8.0, 16.0) * size_mult))
		OptimizationManager.claim_particles(self, count)
		set_process(true)
		queue_redraw()

	func recycle() -> void:
		set_process(false)
		OptimizationManager.release(self)

	func _process(delta: float) -> void:
		_t += delta
		if _t >= 0.22:
			recycle()
			return
		queue_redraw()

	func _draw() -> void:
		var k := _t / 0.22
		var a := 1.0 - k
		draw_circle(Vector2.ZERO, 14.0 * size_mult * (1.0 - k), Color(1, 1, 0.85, 0.8 * a))
		for sp in _sparks:
			var d := Vector2.from_angle(sp.x)
			var p0 := d * sp.y * _t
			var p1 := p0 + d * sp.z * (1.0 - k * 0.5)
			draw_line(p0, p1, Color(1.0, 0.85, 0.3, a), 4.0 * size_mult)
			draw_line(p0, p1, Color(1, 1, 1, a), 2.0 * size_mult)


## Gold / red / void star-burst. Drawn ONCE; growth + fade are transform / modulate only.
class BurstFx extends Node2D:
	const GOLD := 0
	const RED := 1
	const VOID := 2
	var pool_gen := 0
	var radius := 40.0
	var style := GOLD
	var _t := 0.0
	var _dur := 0.35

	func _ready() -> void:
		z_index = 30

	func _enter_tree() -> void:
		_t = 0.0
		_dur = 0.25 + radius * 0.0015 if style == RED else (0.4 if style == VOID else 0.35)
		rotation = randf() * TAU
		scale = Vector2.ONE * 0.3
		modulate = Color.WHITE
		OptimizationManager.claim_particles(self, 6)
		set_process(true)
		queue_redraw()

	func recycle() -> void:
		set_process(false)
		OptimizationManager.release(self)

	func _process(delta: float) -> void:
		_t += delta
		var k := clampf(_t / _dur, 0.0, 1.0)
		if k >= 1.0:
			recycle()
			return
		scale = Vector2.ONE * (0.3 + 0.7 * (1.0 - pow(1.0 - k, 3.0)))
		modulate.a = 1.0 - k * k

	func _draw() -> void:
		var r := radius
		match style:
			GOLD:
				draw_circle(Vector2.ZERO, r, Color(1.0, 0.9, 0.5, 0.35))
				for i in 10:
					var ang := TAU * float(i) / 10.0
					draw_line(Vector2.from_angle(ang) * r * 0.4, Vector2.from_angle(ang) * r * 1.1, Color(1.0, 0.82, 0.25), 4.0)
				draw_arc(Vector2.ZERO, r, 0.0, TAU, 32, Color(0, 0, 0), 3.0)
				draw_circle(Vector2.ZERO, r * 0.3, Color.WHITE)
			RED:
				var pts := _star(24, r, 0.6)
				draw_colored_polygon(pts, Color(1.0, 0.0, 0.0))
				_close(pts, Color(0, 0, 0), 3.0)
				draw_circle(Vector2.ZERO, r * 0.55, Color(0.6, 0.0, 0.0))
				draw_circle(Vector2.ZERO, r * 0.25, Color(1.0, 0.45, 0.45))
			_:
				var pts := _star(16, r, 0.55)
				draw_colored_polygon(pts, Color(0.06, 0.02, 0.10))
				_close(pts, Color(0.65, 0.35, 0.95), 3.0)
				draw_circle(Vector2.ZERO, r * 0.3, Color(0.75, 0.5, 1.0))

	func _star(n: int, r: float, inner: float) -> PackedVector2Array:
		var pts := PackedVector2Array()
		for i in n:
			pts.append(Vector2.from_angle(TAU * float(i) / float(n)) * r * (1.0 if i % 2 == 0 else inner))
		return pts

	func _close(pts: PackedVector2Array, col: Color, w: float) -> void:
		var c := pts.duplicate()
		c.append(pts[0])
		draw_polyline(c, col, w)


## Comic explosion. Drawn once (transform animation); the lingering-fire version redraws.
class ExplosionFx extends Node2D:
	var pool_gen := 0
	var radius := 80.0
	var orange := false
	var fire := false
	var _t := 0.0
	var _dur := 0.5
	var _flames: Array[Vector2] = []
	var _star: Node2D

	func _init() -> void:
		# Built in _init: _enter_tree (which resets the star) runs BEFORE _ready.
		z_index = 30
		_star = Node2D.new()
		add_child(_star)
		_star.draw.connect(_draw_star)

	func _enter_tree() -> void:
		_t = 0.0
		_dur = 0.25 + radius * 0.003
		_star.rotation = randf() * TAU
		_star.scale = Vector2.ONE * 0.25
		_star.modulate = Color.WHITE
		_star.visible = true
		_flames.clear()
		if fire:
			for i in 8:
				_flames.append(Vector2(randf_range(-0.9, 0.9) * radius, randf_range(-6.0, 6.0)))
		OptimizationManager.claim_particles(self, 10)
		set_process(true)
		_star.queue_redraw()
		queue_redraw()

	func recycle() -> void:
		set_process(false)
		OptimizationManager.release(self)

	func _process(delta: float) -> void:
		_t += delta
		if _t >= (_dur + 0.8 if fire else _dur):
			recycle()
			return
		var k := clampf(_t / _dur, 0.0, 1.0)
		_star.visible = k < 1.0
		_star.scale = Vector2.ONE * (0.25 + 0.75 * (1.0 - pow(1.0 - k, 3.0)))
		_star.modulate.a = 1.0 - k * k
		if fire:
			queue_redraw()

	func _draw_star() -> void:
		var r := radius
		var c_out := Color(1.0, 0.45, 0.05) if orange else Color(0.95, 0.22, 0.10)
		var c_mid := Color(1.0, 0.68, 0.12) if orange else Color(1.0, 0.55, 0.10)
		var pts := PackedVector2Array()
		for i in 24:
			pts.append(Vector2.from_angle(TAU * float(i) / 24.0) * r * (1.0 if i % 2 == 0 else 0.62))
		_star.draw_colored_polygon(pts, c_out)
		var closed := pts.duplicate()
		closed.append(pts[0])
		_star.draw_polyline(closed, Color(0.05, 0.03, 0.03), 4.0)
		_star.draw_circle(Vector2.ZERO, r * 0.62, c_mid)
		_star.draw_circle(Vector2.ZERO, r * 0.34, Color(1.0, 0.96, 0.65))
		if orange:
			_star.draw_arc(Vector2.ZERO, r * 1.3, 0.0, TAU, 40, Color(1.0, 0.55, 0.1), 6.0)

	func _draw() -> void:
		if not fire:
			return
		var life := clampf(_t / (_dur + 0.8), 0.0, 1.0)
		for i in _flames.size():
			var h := (34.0 + 14.0 * sin(_t * 20.0 + float(i) * 1.7)) * (1.0 - life)
			if h <= 1.0:
				continue
			var b := _flames[i] + Vector2(0, 20)
			draw_colored_polygon(PackedVector2Array([b + Vector2(-9, 0), b + Vector2(9, 0), b + Vector2(0, -h)]), Color(1.0, 0.5, 0.1, 1.0 - life * 0.6))
			draw_colored_polygon(PackedVector2Array([b + Vector2(-4, 0), b + Vector2(4, 0), b + Vector2(0, -h * 0.55)]), Color(1.0, 0.92, 0.3, 1.0 - life))


## Floating text. Drawn ONCE; rising + fading are position / modulate only.
class PopupFx extends Node2D:
	var pool_gen := 0
	var text := ""
	var color := Color.WHITE
	var font_size := 22
	var _t := 0.0

	func _ready() -> void:
		z_index = 50

	func _enter_tree() -> void:
		_t = 0.0
		modulate = Color.WHITE
		set_process(true)
		queue_redraw()

	func recycle() -> void:
		set_process(false)
		OptimizationManager.release(self)

	func _process(delta: float) -> void:
		_t += delta
		position.y -= 38.0 * delta
		modulate.a = 1.0 - clampf((_t - 0.5) / 0.4, 0.0, 1.0)
		if _t > 0.9:
			recycle()

	func _draw() -> void:
		FighterArt.label(self, Vector2.ZERO, text, font_size, color)


## Lightweight trail: a short buffer of world points drawn as two polylines
## (faint wide + bright core). Detaches when its target is recycled (pool_gen changes).
class TrailFx extends Node2D:
	var pool_gen := 0
	var target: Node2D
	var target_gen := 0
	var color := Color.WHITE
	var width := 10.0
	var max_points := 12
	var _pts := PackedVector2Array()

	func _enter_tree() -> void:
		_pts.clear()
		set_process(true)

	func recycle() -> void:
		set_process(false)
		target = null
		OptimizationManager.release(self)

	func _target_alive() -> bool:
		if target == null or not is_instance_valid(target) or not target.is_inside_tree():
			return false
		return not ("pool_gen" in target) or target.pool_gen == target_gen

	func _process(_delta: float) -> void:
		if _target_alive():
			_pts.append(target.global_position)
			if _pts.size() > max_points:
				_pts.remove_at(0)
		elif _pts.size() > 1:
			_pts.remove_at(0)                     # Target gone: the trail shrinks away
		else:
			recycle()
			return
		queue_redraw()

	func _draw() -> void:
		var n := _pts.size()
		if n < 2:
			return
		var local := PackedVector2Array()
		var cols := PackedColorArray()
		for i in n:
			local.append(to_local(_pts[i]))
			var k := float(i) / float(n - 1)
			cols.append(Color(color.r, color.g, color.b, color.a * 0.8 * k))
		draw_polyline_colors(local, cols, width * 0.9)
		var core := PackedColorArray()
		for c in cols:
			core.append(Color(1, 1, 1, c.a * 0.6))
		draw_polyline_colors(local, core, maxf(width * 0.3, 1.5))


class TimeStopFx extends CanvasLayer:
	var _painter: Node2D
	var _t := 0.0

	func _ready() -> void:
		layer = 5
		_painter = Node2D.new()
		add_child(_painter)
		_painter.draw.connect(_paint)

	func _process(delta: float) -> void:
		_t += delta
		if not CombatManager.is_time_stopped():
			queue_free()
			return
		_painter.queue_redraw()

	func _paint() -> void:
		var size := _painter.get_viewport_rect().size
		var intro := clampf(_t / 0.25, 0.0, 1.0)
		_painter.draw_rect(Rect2(Vector2.ZERO, size), Color(0.18, 0.05, 0.28, 0.28 * intro))
		if _t < 0.5:
			var k := _t / 0.5
			_painter.draw_arc(size * 0.5, size.x * 0.8 * k, 0.0, TAU, 64, Color(0.85, 0.7, 1.0, 1.0 - k), 14.0, FighterArt.AA)
		_painter.draw_rect(Rect2(0, 0, size.x, 26), Color(0, 0, 0, 0.55 * intro))
		_painter.draw_rect(Rect2(0, size.y - 26, size.x, 26), Color(0, 0, 0, 0.55 * intro))
		FighterArt.label(_painter, Vector2(size.x * 0.5, 110), "TIME STOPPED  %.1f" % CombatManager.time_stop_left, 30, Color(0.85, 0.7, 1.0))


class RingFx extends Node2D:
	var duration := 0.6
	var window := 0.15
	var _t := 0.0

	func _ready() -> void:
		z_index = 40

	func _process(delta: float) -> void:
		_t += delta
		if _t >= duration:
			queue_free()
		queue_redraw()

	func _draw() -> void:
		var k := clampf(_t / duration, 0.0, 1.0)
		var zone_r := lerpf(90.0, 18.0, 1.0 - window / duration)
		draw_arc(Vector2.ZERO, zone_r, 0.0, TAU, 40, Color(1, 1, 1, 0.9), 2.0, FighterArt.AA)
		draw_arc(Vector2.ZERO, lerpf(90.0, 18.0, k), 0.0, TAU, 40, Color(1.0, 0.85, 0.15, 0.95), 5.0, FighterArt.AA)
		FighterArt.label(self, Vector2(0, -100), "tap F when ring touches white", 12, Color(1, 1, 1, 0.8))
