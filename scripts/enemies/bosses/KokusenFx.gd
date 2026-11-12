class_name KokusenFx
extends RefCounted
## Visual + hitting pieces of KOKUSEN (Fights-mode boss). Each inner class is a small node
## that frees itself. Self-contained on purpose: nothing here is shared with other fighters.
##   Shot            every projectile: cut, flame_slash, fireball (+ burning ground), ember,
##                   burn, debris, meteor, pillar
##   Letterbox       cinematic black bars + crimson move title
##   MeteorCutscene  METEOR RAIN: Kokusen over the Earth, meteors burn up, one stays intact
##   FlameRing       CLOSED WORLD: the circle of fire around the arena
##   ForceWave       UNKNOWN FORCE: rings pulling in (ground) or blasting out (air)
##   Marker          red warning circle on the floor (where the meteor will land)

const CRIMSON := Color(0.75, 0.06, 0.10)
const FLAME := Color(1.0, 0.45, 0.10)
const FLAME_HI := Color(1.0, 0.85, 0.35)
const ROCK := Color(0.30, 0.24, 0.22)
const ROCK_HI := Color(0.48, 0.38, 0.32)


# ============================================================
# PROJECTILES
# ============================================================
class Shot extends Node2D:
	var source: Fighter
	var kind := "cut"
	var vel := Vector2.ZERO
	var gravity := 0.0
	var damage := 2
	var knockback := Vector2(220, -160)
	var radius := 24.0
	var half_h := -1.0                  # Hit box half height (-1 = radius)
	var life := 1.0
	var pierce := true
	var tick := 0.0                     # > 0: hits the same fighter again every `tick` s (burn)
	var delay := 0.0                    # No hits before this (pillar warning)
	var floor_y := INF                  # Falling shots: impact when they reach this y
	var impact_radius := 0.0
	var impact_damage := 0
	var unblockable := false
	var burn_trail := false             # Giant fireball: leaves burning ground behind it
	## VOLLEY CAP: all shots of one attack share `volley` (same Dictionary); each fighter can be
	## hit by at most `cap` of them (0 = no cap). Keeps "tens of cuts" fair: max cap x damage.
	var volley: Dictionary = {}
	var cap := 0

	var _t := 0.0
	var _last := {}                     # Fighter -> time of its last hit
	var _trail_t := 0.0
	var _spin := 0.0

	func _ready() -> void:
		z_index = 8
		_spin = randf() * TAU

	func _physics_process(delta: float) -> void:
		if source != null and is_instance_valid(source) and source.is_time_frozen():
			return
		_t += delta
		_spin += delta * 8.0
		if _t >= life:
			queue_free()
			return
		vel.y += gravity * delta
		global_position += vel * delta
		if burn_trail:
			_trail_t -= delta
			if _trail_t <= 0.0:
				_trail_t = 0.2
				_burn_patch()
		if global_position.y >= floor_y:
			global_position.y = floor_y
			_impact()
			return
		if _t >= delay:
			for n in get_tree().get_nodes_in_group("fighters") + get_tree().get_nodes_in_group("helpers"):
				var f := n as Fighter
				if f == null or f.is_dead or f == source or CombatManager.passes_through(source, f):
					continue
				var c := f.global_position + Vector2(0, -f.data.body_size.y * 0.5)
				var hh := (half_h if half_h > 0.0 else radius)
				if absf(c.x - global_position.x) > radius + f.data.body_size.x * 0.5 or absf(c.y - global_position.y) > hh + f.data.body_size.y * 0.5:
					continue
				if _last.has(f) and (tick <= 0.0 or _t - float(_last[f]) < tick):
					continue
				if not _volley_ok(f):
					continue
				_last[f] = _t
				_apply(f, damage, knockback)
				if not pierce:
					_impact()
					return
		if floor_y == INF and _t > 0.4 and not OptimizationManager.on_screen(global_position, 900.0):
			queue_free()
			return
		queue_redraw()

	## Counts this hit against the volley cap. False = this fighter already took `cap` hits.
	func _volley_ok(f: Fighter) -> bool:
		if cap <= 0:
			return true
		var n := int(volley.get(f, 0))
		if n >= cap:
			return false
		volley[f] = n + 1
		return true

	func _apply(f: Fighter, dmg: int, kb: Vector2) -> void:
		var h := HitData.new()
		h.source = source if source != null and is_instance_valid(source) else null
		h.damage = dmg
		var dx := signf(f.global_position.x - global_position.x)
		if dx == 0.0:
			dx = signf(vel.x) if vel.x != 0.0 else 1.0
		h.knockback = Vector2(dx * kb.x, kb.y)
		h.origin = global_position
		h.hit_type = "enemy"
		h.move = "kokusen_" + kind
		h.blockable = not unblockable
		if kind in ["fireball", "ember", "meteor", "debris"]:
			h.damage_kind = HitData.KIND_EXPLOSION
		if kind == "burn":
			h.is_tick = true
			h.causes_hitstun = false
		CombatManager.apply_hit(h, f)

	func _impact() -> void:
		if impact_radius > 0.0:
			Effects.explosion(self, global_position + Vector2(0, -20), impact_radius, true, true)
			for n in get_tree().get_nodes_in_group("fighters") + get_tree().get_nodes_in_group("helpers"):
				var f := n as Fighter
				if f == null or f.is_dead or f == source or CombatManager.passes_through(source, f) or _last.has(f):
					continue
				var c := f.global_position + Vector2(0, -f.data.body_size.y * 0.5)
				if absf(c.x - global_position.x) <= impact_radius + f.data.body_size.x * 0.5 and absf(c.y - global_position.y) <= impact_radius + f.data.body_size.y:
					if kind == "meteor" or _volley_ok(f):
						_apply(f, impact_damage, Vector2(620, -560) if kind == "meteor" else knockback)
			if kind == "meteor":
				Effects.shake(self, 34.0)
				KokusenFx.flash(self, Color(1.0, 0.6, 0.3, 0.9), 0.8)
				SoundManager.play_sfx("explosion")
				SoundManager.play_sfx("rumble")
			else:
				SoundManager.play_sfx("stone", -8.0)
		elif kind in ["fireball", "ember", "flame_slash"]:
			Effects.explosion(self, global_position, maxf(radius * 1.2, 30.0), true, true)
		queue_free()

	func _burn_patch() -> void:
		var g: Variant = Effects.ground_below(self, global_position, 200.0)
		if g == null:
			return
		var b := KokusenFx.Shot.new()
		b.source = source
		b.kind = "burn"
		b.damage = 1
		b.knockback = Vector2.ZERO
		b.radius = 34.0
		b.half_h = 30.0
		b.life = 2.2
		b.tick = 0.5
		get_parent().add_child(b)
		b.global_position = (g as Vector2) + Vector2(0, -26)

	func _draw() -> void:
		var a := 1.0 - clampf((_t - life + 0.2) / 0.2, 0.0, 1.0)
		var ang := vel.angle() if vel.length() > 1.0 else 0.0
		match kind:
			"cut":
				draw_set_transform(Vector2.ZERO, ang, Vector2.ONE)
				draw_arc(Vector2(-8, 0), radius, -1.15, 1.15, 12, Color(CRIMSON.r, CRIMSON.g, CRIMSON.b, 0.55 * a), 9.0, FighterArt.AA)
				draw_arc(Vector2(-8, 0), radius, -1.0, 1.0, 12, Color(1, 1, 1, a), 3.0, FighterArt.AA)
				draw_set_transform(Vector2.ZERO, 0.0, Vector2.ONE)
			"flame_slash":
				draw_set_transform(Vector2.ZERO, ang, Vector2.ONE)
				draw_arc(Vector2(-10, 0), radius, -1.25, 1.25, 14, Color(FLAME.r, FLAME.g, FLAME.b, 0.35 * a), 22.0, FighterArt.AA)
				draw_arc(Vector2(-10, 0), radius, -1.15, 1.15, 14, Color(FLAME.r, FLAME.g, FLAME.b, a), 10.0, FighterArt.AA)
				draw_arc(Vector2(-10, 0), radius, -0.9, 0.9, 14, Color(FLAME_HI.r, FLAME_HI.g, FLAME_HI.b, a), 4.0, FighterArt.AA)
				draw_set_transform(Vector2.ZERO, 0.0, Vector2.ONE)
			"fireball", "ember":
				var back := -vel.normalized() if vel.length() > 1.0 else Vector2.LEFT
				for i in 4:                                    # Flame tongues trailing behind
					var off := back * radius * (0.8 + float(i) * 0.45) + back.orthogonal() * sin(_spin * 2.0 + float(i)) * radius * 0.3
					draw_circle(off, radius * (0.75 - float(i) * 0.15), Color(FLAME.r, FLAME.g, FLAME.b, (0.6 - float(i) * 0.12) * a))
				draw_circle(Vector2.ZERO, radius * 1.25, Color(FLAME.r, FLAME.g, FLAME.b, 0.3 * a))
				draw_circle(Vector2.ZERO, radius, Color(CRIMSON.r, CRIMSON.g, CRIMSON.b, a))
				draw_circle(Vector2.ZERO, radius * 0.78, Color(FLAME.r, FLAME.g, FLAME.b, a))
				draw_circle(Vector2(-radius * 0.15, -radius * 0.15), radius * 0.42, Color(FLAME_HI.r, FLAME_HI.g, FLAME_HI.b, a))
				if kind == "fireball":                         # Rolling: dark swirl lines
					for i in 3:
						var s0 := _spin + float(i) * TAU / 3.0
						draw_arc(Vector2.ZERO, radius * 0.6, s0, s0 + 1.2, 8, Color(CRIMSON.r, CRIMSON.g, CRIMSON.b, 0.8 * a), 3.0, FighterArt.AA)
			"burn":
				var fade := clampf((life - _t) / 0.5, 0.0, 1.0)
				for i in 5:
					var x := -28.0 + float(i) * 14.0
					var h := 22.0 + 12.0 * sin(_spin * 1.6 + float(i) * 1.7)
					draw_colored_polygon(PackedVector2Array([Vector2(x - 8, 26), Vector2(x + 8, 26), Vector2(x, 26 - h)]),
						Color(FLAME.r, FLAME.g, FLAME.b, 0.8 * fade))
					draw_colored_polygon(PackedVector2Array([Vector2(x - 4, 26), Vector2(x + 4, 26), Vector2(x, 26 - h * 0.55)]),
						Color(FLAME_HI.r, FLAME_HI.g, FLAME_HI.b, 0.9 * fade))
			"debris", "meteor":
				var r := radius
				var up := -vel.normalized() if vel.length() > 1.0 else Vector2.UP
				draw_line(Vector2.ZERO, up * r * 4.5, Color(FLAME.r, FLAME.g, FLAME.b, 0.25 * a), r * 1.6, FighterArt.AA)   # Burning trail
				draw_line(Vector2.ZERO, up * r * 3.0, Color(FLAME_HI.r, FLAME_HI.g, FLAME_HI.b, 0.4 * a), r * 0.8, FighterArt.AA)
				draw_circle(Vector2.ZERO, r * 1.35, Color(FLAME.r, FLAME.g, FLAME.b, 0.35 * a))
				var pts := PackedVector2Array()
				for k in 8:
					pts.append(Vector2.from_angle(_spin * 0.4 + float(k) * TAU / 8.0) * r * (0.82 + 0.2 * sin(float(k) * 2.7)))
				draw_colored_polygon(pts, Color(ROCK.r, ROCK.g, ROCK.b, a))
				draw_circle(Vector2(-r * 0.25, -r * 0.25), r * 0.35, Color(ROCK_HI.r, ROCK_HI.g, ROCK_HI.b, a))
				draw_circle(Vector2(r * 0.2, r * 0.25), r * 0.22, Color(FLAME.r, FLAME.g, FLAME.b, 0.8 * a))   # Glowing crack
				FighterArt.outline(self, pts, 3.0 if kind == "debris" else 5.0, Color(0, 0, 0, a))
			"pillar":
				var hh := half_h if half_h > 0.0 else 120.0
				if _t < delay:                                 # Warning on the floor
					var p := 0.5 + 0.5 * sin(_t * 30.0)
					draw_set_transform(Vector2(0, hh), 0.0, Vector2(1.0, 0.25))
					draw_circle(Vector2.ZERO, radius + 6.0, Color(1.0, 0.2, 0.1, 0.25 + 0.3 * p))
					draw_arc(Vector2.ZERO, radius + 6.0, 0.0, TAU, 20, Color(1.0, 0.3, 0.1, 0.9), 4.0, FighterArt.AA)
					draw_set_transform(Vector2.ZERO, 0.0, Vector2.ONE)
				else:
					var k := clampf((_t - delay) / 0.12, 0.0, 1.0) * a
					draw_rect(Rect2(-radius, -hh, radius * 2.0, hh * 2.0), Color(FLAME.r, FLAME.g, FLAME.b, 0.75 * k))
					draw_rect(Rect2(-radius * 0.5, -hh, radius, hh * 2.0), Color(FLAME_HI.r, FLAME_HI.g, FLAME_HI.b, 0.85 * k))
					for i in 4:
						var x := -radius + float(i) * radius * 0.66
						draw_colored_polygon(PackedVector2Array([Vector2(x, -hh), Vector2(x + radius * 0.6, -hh), Vector2(x + radius * 0.3, -hh - 30.0 - 14.0 * sin(_spin + float(i)))]),
							Color(FLAME.r, FLAME.g, FLAME.b, 0.8 * k))


static func shot(src: Fighter, p_kind: String, pos: Vector2, v: Vector2, dmg: int, r: float, p_life: float, p_pierce: bool) -> Shot:
	var s := Shot.new()
	s.source = src
	s.kind = p_kind
	s.vel = v
	s.damage = dmg
	s.radius = r
	s.life = p_life
	s.pierce = p_pierce
	src.get_parent().add_child(s)
	s.global_position = pos
	return s


# ============================================================
# SCREEN FLASH + CINEMATIC BARS
# ============================================================
class Flash extends CanvasLayer:
	var col := Color.WHITE
	var dur := 0.6
	var _t := 0.0
	var _rect: ColorRect

	func _ready() -> void:
		layer = 29
		process_mode = Node.PROCESS_MODE_ALWAYS
		_rect = ColorRect.new()
		_rect.set_anchors_and_offsets_preset(Control.PRESET_FULL_RECT)
		_rect.mouse_filter = Control.MOUSE_FILTER_IGNORE
		add_child(_rect)

	func _process(delta: float) -> void:
		_t += delta / maxf(Engine.time_scale, 0.01)
		_rect.color = Color(col.r, col.g, col.b, col.a * (1.0 - clampf(_t / dur, 0.0, 1.0)))
		if _t >= dur:
			queue_free()


static func flash(ctx: Node, col: Color, dur: float) -> void:
	if ctx == null or not ctx.is_inside_tree():
		return
	var f := Flash.new()
	f.col = col
	f.dur = dur
	ctx.get_tree().current_scene.add_child(f)


class Letterbox extends CanvasLayer:
	var title := ""
	var _k := 0.0
	var _want := 1.0
	var _t := 0.0
	var _painter: Control

	func _ready() -> void:
		layer = 30
		process_mode = Node.PROCESS_MODE_ALWAYS
		_painter = Control.new()
		_painter.set_anchors_and_offsets_preset(Control.PRESET_FULL_RECT)
		_painter.mouse_filter = Control.MOUSE_FILTER_IGNORE
		add_child(_painter)
		_painter.draw.connect(_paint)

	func close() -> void:
		_want = 0.0

	func _process(delta: float) -> void:
		var real := delta / maxf(Engine.time_scale, 0.01)
		_t += real
		_k = move_toward(_k, _want, real * 3.0)
		if _want == 0.0 and _k <= 0.0:
			queue_free()
			return
		_painter.queue_redraw()

	func _paint() -> void:
		var sz := _painter.size
		var h := sz.y * 0.12 * _k
		_painter.draw_rect(Rect2(0, 0, sz.x, h), Color(0, 0, 0))
		_painter.draw_rect(Rect2(0, sz.y - h, sz.x, h), Color(0, 0, 0))
		if title != "" and _k > 0.5:
			var a := clampf((_k - 0.5) * 2.0, 0.0, 1.0) * clampf(_t / 0.4, 0.0, 1.0)
			FighterArt.label(_painter, Vector2(sz.x * 0.5, sz.y - h * 0.45), title, 34, Color(1.0, 0.35, 0.3, a))


# ============================================================
# METEOR RAIN cutscene: Kokusen above the Earth summons the shower
# ============================================================
class MeteorCutscene extends CanvasLayer:
	signal finished
	const LEN := 4.4
	const COUNT := 9
	const INTACT := 4                    # The one meteor that survives the atmosphere
	var _t := 0.0
	var _painter: Control
	var _rumbled := false

	func _ready() -> void:
		layer = 31
		process_mode = Node.PROCESS_MODE_ALWAYS
		_painter = Control.new()
		_painter.set_anchors_and_offsets_preset(Control.PRESET_FULL_RECT)
		_painter.mouse_filter = Control.MOUSE_FILTER_IGNORE
		add_child(_painter)
		_painter.draw.connect(_paint)
		SoundManager.play_sfx("whoosh")

	func _process(delta: float) -> void:
		_t += delta / maxf(Engine.time_scale, 0.01)
		if _t >= 2.2 and not _rumbled:
			_rumbled = true
			SoundManager.play_sfx("rumble")
			SoundManager.play_sfx("flame", -4.0)
		_painter.queue_redraw()
		if _t >= LEN:
			finished.emit()
			queue_free()

	func _paint() -> void:
		var p := _painter
		var sz := p.size
		p.draw_rect(Rect2(Vector2.ZERO, sz), Color(0.01, 0.0, 0.03))
		for i in 90:                                           # Stars
			p.draw_circle(Vector2(fmod(float(i) * 137.0, sz.x), fmod(float(i) * 71.0, sz.y)), 1.0 + float(i % 3) * 0.6, Color(1, 1, 1, 0.7))
		# The Earth: big planet curving across the bottom, with a thin atmosphere glow
		var ec := Vector2(sz.x * 0.5, sz.y * 1.85)
		var er := sz.y * 1.1
		p.draw_circle(ec, er + 40.0, Color(0.35, 0.6, 1.0, 0.18))
		p.draw_circle(ec, er + 16.0, Color(0.45, 0.7, 1.0, 0.25))
		p.draw_circle(ec, er, Color(0.12, 0.30, 0.66))
		for l: Vector3 in [Vector3(-0.32, 0.95, 0.06), Vector3(-0.1, 0.97, 0.045), Vector3(0.08, 0.94, 0.07), Vector3(0.28, 0.96, 0.05)]:
			var cp := ec + Vector2.from_angle(-PI * 0.5 + l.x) * er * l.y
			p.draw_set_transform(cp, l.x, Vector2(1.6, 0.8))
			p.draw_circle(Vector2.ZERO, er * l.z, Color(0.22, 0.5, 0.24))
		p.draw_set_transform(Vector2.ZERO, 0.0, Vector2.ONE)
		var atmo := ec.y - er - 30.0                           # Where the meteors start to burn
		# Kokusen hovering high above, arms raised
		var hover := Vector2(sz.x * 0.5, sz.y * 0.62 + sin(_t * 2.0) * 6.0)      # Feet; the art is ~300 px tall
		var glow := clampf(_t / 0.8, 0.0, 1.0)
		p.draw_circle(hover + Vector2(0, -150), 60.0 + 20.0 * sin(_t * 6.0), Color(1.0, 0.3, 0.1, 0.25 * glow))
		p.draw_set_transform(hover, 0.0, Vector2(1.25, 1.25))
		Kokusen.draw_kokusen(p, {"t": _t, "pose": "meteor", "flying": true, "eyes_wide": true})
		p.draw_set_transform(Vector2.ZERO, 0.0, Vector2.ONE)
		# The shower: meteors streak down toward the Earth, burn up in the atmosphere
		for i in COUNT:
			var start_t := 0.6 + float(i) * 0.12
			var k := clampf((_t - start_t) / 2.0, 0.0, 1.0)
			if k <= 0.0:
				continue
			var from := Vector2(sz.x * (0.08 + 0.1 * float(i)), -40.0)
			var to := Vector2(sz.x * (0.25 + 0.06 * float(i)), atmo + 60.0)
			var pos := from.lerp(to, k)
			var dirv := (to - from).normalized()
			var burning := pos.y > atmo - 120.0
			var r := (26.0 if i == INTACT else 13.0) * (1.0 + (0.6 * k if i == INTACT else 0.0))
			if i != INTACT and k > 0.82:
				# Broken apart: debris scattering, fading
				var b := clampf((k - 0.82) / 0.18, 0.0, 1.0)
				for j in 5:
					var d := pos + Vector2.from_angle(float(j) * 1.3 + float(i)) * 30.0 * b
					p.draw_circle(d, 4.0 * (1.0 - b) + 1.0, Color(1.0, 0.55, 0.2, 1.0 - b))
				continue
			p.draw_line(pos, pos - dirv * (40.0 + (140.0 if burning else 60.0)), Color(1.0, 0.45, 0.1, 0.35 if burning else 0.15), r * 1.6)
			if burning:
				p.draw_line(pos, pos - dirv * 70.0, Color(1.0, 0.85, 0.4, 0.6), r * 0.7)
				p.draw_circle(pos, r * 1.5, Color(1.0, 0.45, 0.1, 0.35))
			p.draw_circle(pos, r, Color(0.3, 0.24, 0.22))
			p.draw_circle(pos + Vector2(-r * 0.3, -r * 0.3), r * 0.35, Color(0.5, 0.4, 0.34))
		if _t >= 3.4:                                         # Orange flash as it slams through
			p.draw_rect(Rect2(Vector2.ZERO, sz), Color(1.0, 0.55, 0.25, clampf((_t - 3.4) / 1.0, 0.0, 1.0)))
		FighterArt.label(p, Vector2(sz.x * 0.5, sz.y * 0.1), "METEOR RAIN", 44, Color(1.0, 0.4, 0.3, clampf(_t / 0.4, 0.0, 1.0)))


# ============================================================
# CLOSED WORLD: the circle of fire
# ============================================================
class FlameRing extends Node2D:
	var radius := 0.0
	var fade := 1.0
	var _t := 0.0

	func _ready() -> void:
		z_index = -1

	func _process(delta: float) -> void:
		_t += delta / maxf(Engine.time_scale, 0.01)
		queue_redraw()

	func _draw() -> void:
		if radius <= 1.0:
			return
		var a := fade
		draw_circle(Vector2(0, -radius * 0.25), radius, Color(0.6, 0.05, 0.05, 0.10 * a))
		draw_arc(Vector2.ZERO, radius, PI, TAU, 64, Color(0, 0, 0, 0.7 * a), 22.0, FighterArt.AA)
		draw_arc(Vector2.ZERO, radius, PI, TAU, 64, Color(FLAME.r, FLAME.g, FLAME.b, 0.85 * a), 14.0, FighterArt.AA)
		draw_arc(Vector2.ZERO, radius, PI, TAU, 64, Color(FLAME_HI.r, FLAME_HI.g, FLAME_HI.b, 0.9 * a), 5.0, FighterArt.AA)
		for i in 36:                                       # Flames licking up along the circle
			var ang := PI + float(i) / 35.0 * PI
			var p := Vector2.from_angle(ang) * radius
			var out := Vector2.from_angle(ang)
			var h := 26.0 + 14.0 * sin(_t * 9.0 + float(i) * 1.3)
			draw_colored_polygon(PackedVector2Array([p - out.orthogonal() * 10.0, p + out.orthogonal() * 10.0, p + out * h]),
				Color(FLAME.r, FLAME.g, FLAME.b, 0.85 * a))


# ============================================================
# UNKNOWN FORCE: pull (rings closing in) / repel (rings blasting out)
# ============================================================
class ForceWave extends Node2D:
	var pull := true
	var reach := 600.0
	var _t := 0.0
	const LEN := 0.6

	func _process(delta: float) -> void:
		_t += delta
		if _t >= LEN:
			queue_free()
			return
		queue_redraw()

	func _draw() -> void:
		var k := _t / LEN
		for i in 4:
			var u := fmod(k + float(i) * 0.25, 1.0)
			var r := reach * ((1.0 - u) if pull else u)
			var a := (1.0 - k) * 0.8
			draw_arc(Vector2.ZERO, maxf(r, 4.0), 0.0, TAU, 40, Color(0.12, 0.0, 0.05, a), 10.0, FighterArt.AA)
			draw_arc(Vector2.ZERO, maxf(r, 4.0), 0.0, TAU, 40, Color(CRIMSON.r, CRIMSON.g, CRIMSON.b, a), 4.0, FighterArt.AA)


# ============================================================
# WARNING MARKER on the floor
# ============================================================
class Marker extends Node2D:
	var r := 200.0
	var life := 1.5
	var _t := 0.0

	func _ready() -> void:
		z_index = 2

	func _process(delta: float) -> void:
		_t += delta / maxf(Engine.time_scale, 0.01)
		if _t >= life:
			queue_free()
			return
		queue_redraw()

	func _draw() -> void:
		var p := 0.5 + 0.5 * sin(_t * 18.0)
		draw_set_transform(Vector2.ZERO, 0.0, Vector2(1.0, 0.22))
		draw_circle(Vector2.ZERO, r, Color(1.0, 0.15, 0.1, 0.15 + 0.2 * p))
		draw_arc(Vector2.ZERO, r, 0.0, TAU, 40, Color(1.0, 0.3, 0.1, 0.9), 6.0, FighterArt.AA)
		draw_set_transform(Vector2.ZERO, 0.0, Vector2.ONE)
		FighterArt.label(self, Vector2(0, -40), "!", 40, Color(1.0, 0.3, 0.2, 0.6 + 0.4 * p))
