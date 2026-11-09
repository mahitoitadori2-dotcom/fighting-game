class_name AlphaFx
extends RefCounted
## Visual pieces + helpers of the APHA ARCHITECT's powers. Each inner class is a small node
## the fighter spawns (they free themselves).
##   Letterbox      cinematic black bars + big move title (screen space)
##   Flash          full-screen white / coloured flash
##   Clones         Barrage of Vadis: 3 shadow clones + a storm of fists (or laser muzzles)
##   Portal         Portal Manifestation: a swirling portal that throws objects at enemies
##   GasBall        Pure Implosion of Decay: gas gathers and is encased in a ball
##   DecayField     ...the lingering decay after the implosion (damages over time)
##   Rods           World Implosion Bomb: energy rods forming above his hands
##   EarthCutscene  World Implosion Bomb: hovering over the Earth, the rods pierce it
##   Barrier        World Opening: the barrier dome + the GIANT HANDS tearing everything apart
##   Debuffs        Godly Touch: 3 random debuffs on the victim (ticks, icons, effects)

const GREEN := Color(0.35, 1.0, 0.5)
const DECAY := Color(0.45, 0.85, 0.25)
const VOID := Color(0.55, 0.25, 0.95)


# ============================================================
# CINEMATIC BARS + TITLE
# ============================================================
class Letterbox extends CanvasLayer:
	var title := ""
	var sub := ""
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
			FighterArt.label(_painter, Vector2(sz.x * 0.5, sz.y - h * 0.45), title, 34, Color(0.6, 1.0, 0.7, a))
			if sub != "":
				FighterArt.label(_painter, Vector2(sz.x * 0.5, h * 0.62), sub, 18, Color(1, 1, 1, 0.8 * a))


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
	var f := Flash.new()
	f.col = col
	f.dur = dur
	ctx.get_tree().current_scene.add_child(f)


# ============================================================
# BARRAGE OF VADIS: shadow clones
# ============================================================
class Clones extends Node2D:
	var facing := 1
	var lasers := false
	var life := 1.3
	var _t := 0.0
	const OFFS := [Vector2(-50, -40), Vector2(-30, 26), Vector2(-80, -6)]

	func _ready() -> void:
		z_index = 4

	func _process(delta: float) -> void:
		_t += delta
		if _t >= life:
			queue_free()
			return
		queue_redraw()

	func _draw() -> void:
		var a := clampf(_t / 0.15, 0.0, 1.0) * (1.0 - clampf((_t - life + 0.25) / 0.25, 0.0, 1.0))
		for i in OFFS.size():
			var o: Vector2 = OFFS[i]
			draw_set_transform(Vector2(o.x * facing, o.y), 0.0, Vector2(facing * 0.95, 0.95))
			AlphaArchitectArt.draw_portrait(self, _t * 3.0 + float(i))
			draw_set_transform(Vector2.ZERO, 0.0, Vector2.ONE)
			draw_circle(Vector2(o.x * facing, o.y - 70.0), 50.0, Color(0.2, 0.9, 0.4, 0.12 * a))
		modulate = Color(0.55, 1.0, 0.65, 0.55 * a)
		# The barrage: dozens of fists flying forward (or muzzle flashes for lasers)
		for k in 22:
			var ph := fmod(_t * 7.0 + float(k) * 0.37, 1.0)
			var x := facing * (40.0 + ph * 300.0)
			var y := -40.0 - fmod(float(k) * 37.0, 110.0)
			if lasers:
				draw_circle(Vector2(facing * 40.0, y), 6.0 * (1.0 - ph), Color(0.6, 1.0, 0.7, a))
			else:
				draw_circle(Vector2(x, y), 9.0, Color(0.02, 0.02, 0.03, a))
				draw_circle(Vector2(x, y), 6.0, Color([0.9, 0.3, 0.3, 0.9][k % 4], 0.6, [0.9, 1.0, 0.4, 0.6][k % 4], a))


# ============================================================
# PORTAL MANIFESTATION
# ============================================================
class Portal extends Node2D:
	var source: Fighter
	var duration := 2.6
	var every := 0.14
	var damage := 9
	var _t := 0.0
	var _next := 0.3

	func _ready() -> void:
		z_index = 3
		SoundManager.play_sfx("void_goo")

	func _process(delta: float) -> void:
		if source != null and is_instance_valid(source) and source.is_time_frozen():
			queue_redraw()
			return
		_t += delta
		_next -= delta
		if _next <= 0.0 and _t < duration and source != null and is_instance_valid(source) and not source.is_dead:
			_next = every
			_shoot()
		if _t >= duration + 0.5:
			queue_free()
			return
		queue_redraw()

	func _shoot() -> void:
		var s := AlphaShot.new()
		s.source = source
		var kinds := ["rock", "shard", "orb", "debris"]
		s.kind = kinds[randi() % kinds.size()]
		s.tint = [Color(0.4, 1.0, 0.5), Color(0.75, 0.4, 1.0), Color(1.0, 0.8, 0.3)][randi() % 3]
		s.damage = damage
		s.radius = 20.0 if s.kind != "debris" else 26.0
		s.knockback = Vector2(260, -200)
		s.homing = 3.0
		s.life = 2.4
		s.vel = Vector2.from_angle(randf_range(-PI, PI)) * 700.0
		get_parent().add_child(s)
		s.global_position = global_position + Vector2(randf_range(-20.0, 20.0), randf_range(-20.0, 20.0))
		SoundManager.play_sfx("whoosh", -14.0)

	func _draw() -> void:
		var open := clampf(_t / 0.3, 0.0, 1.0) * (1.0 - clampf((_t - duration) / 0.5, 0.0, 1.0))
		draw_set_transform(Vector2.ZERO, 0.0, Vector2(0.6, 1.0))
		draw_circle(Vector2.ZERO, 74.0 * open, Color(0.3, 0.9, 0.45, 0.25))
		for i in 6:
			var r := (66.0 - float(i) * 10.0) * open
			draw_arc(Vector2.ZERO, r, _t * (4.0 + float(i)), _t * (4.0 + float(i)) + 4.4, 20, Color(0.4, 1.0, 0.55, 0.9) if i % 2 == 0 else Color(0.7, 0.4, 1.0, 0.9), 5.0, true)
		draw_circle(Vector2.ZERO, 26.0 * open, Color(0.02, 0.0, 0.04))
		draw_set_transform(Vector2.ZERO, 0.0, Vector2.ONE)


# ============================================================
# PURE IMPLOSION OF DECAY
# ============================================================
class GasBall extends Node2D:
	var grow := 0.0                       # 0..1: gas gathering into the ball
	var _t := 0.0

	func _ready() -> void:
		z_index = 9
		process_mode = Node.PROCESS_MODE_ALWAYS

	func _process(delta: float) -> void:
		_t += delta / maxf(Engine.time_scale, 0.01)
		queue_redraw()

	func _draw() -> void:
		# Streams of gas spiralling inward
		for i in 30:
			var a := float(i) * 0.7 + _t * 3.0
			var dist := 240.0 * (1.0 - fmod(_t * 0.8 + float(i) * 0.05, 1.0)) * (1.0 - grow * 0.6)
			var p := Vector2.from_angle(a) * dist
			draw_circle(p, 10.0 + 6.0 * sin(float(i)), Color(DECAY.r, DECAY.g, DECAY.b, 0.25) if i % 2 == 0 else Color(VOID.r, VOID.g, VOID.b, 0.25))
		var r := 10.0 + 34.0 * grow
		draw_circle(Vector2.ZERO, r * 1.8, Color(DECAY.r, DECAY.g, DECAY.b, 0.2))
		draw_circle(Vector2.ZERO, r, Color(0.08, 0.12, 0.05))
		for i in 5:                                        # The casing: glass-like shell lines
			draw_arc(Vector2.ZERO, r, _t * 2.0 + float(i) * 1.2, _t * 2.0 + float(i) * 1.2 + 0.9, 8, Color(0.85, 1.0, 0.8, 0.9), 3.0, true)
		draw_circle(Vector2(sin(_t * 9.0), cos(_t * 7.0)) * r * 0.3, r * 0.45, Color(DECAY.r, DECAY.g, DECAY.b, 0.9))


class DecayField extends Node2D:
	var source: Fighter
	var radius := 240.0
	var life := 3.0
	var tick := 6
	var _t := 0.0
	var _next := 0.3

	func _ready() -> void:
		z_index = 6

	func _process(delta: float) -> void:
		_t += delta
		_next -= delta
		if _next <= 0.0:
			_next = 0.3
			_damage()
		if _t >= life:
			queue_free()
			return
		queue_redraw()

	func _damage() -> void:
		if source == null or not is_instance_valid(source):
			return
		for n in get_tree().get_nodes_in_group("fighters"):
			var f := n as Fighter
			if f == null or f.is_dead or CombatManager.are_allies(source, f):
				continue
			if absf(f.global_position.x - global_position.x) > radius or absf(f.global_position.y - global_position.y) > 160.0:
				continue
			var h := HitData.new()
			h.source = source
			h.damage = tick
			h.blockable = false
			h.causes_hitstun = false
			h.is_tick = true
			h.origin = global_position
			h.hit_type = "alpha"
			h.move = "pure_implosion_of_decay"
			CombatManager.apply_hit(h, f)
			f.apply_goo(0.5, 0.7, 0.0)

	func _draw() -> void:
		var a := 1.0 - clampf((_t - life + 0.6) / 0.6, 0.0, 1.0)
		for i in 14:
			var x := -radius + fmod(float(i) * 61.0 + _t * 30.0, radius * 2.0)
			var y := -20.0 - fmod(float(i) * 23.0 + _t * 40.0, 120.0)
			draw_circle(Vector2(x, y), 28.0, Color(DECAY.r * 0.5, DECAY.g * 0.6, DECAY.b * 0.3, 0.3 * a))
		draw_set_transform(Vector2.ZERO, 0.0, Vector2(1.0, 0.18))
		draw_circle(Vector2.ZERO, radius, Color(0.15, 0.25, 0.05, 0.45 * a))
		draw_set_transform(Vector2.ZERO, 0.0, Vector2.ONE)


# ============================================================
# WORLD IMPLOSION BOMB
# ============================================================
class Rods extends Node2D:
	var count := 1
	var charge := 0.0                    # 0..1 energy gathering
	var _t := 0.0

	func _ready() -> void:
		z_index = 9
		process_mode = Node.PROCESS_MODE_ALWAYS

	func _process(delta: float) -> void:
		_t += delta / maxf(Engine.time_scale, 0.01)
		queue_redraw()

	func _draw() -> void:
		for i in 18:                                       # Energy streaming in
			var a := float(i) * 0.35 + _t * 4.0
			var p := Vector2.from_angle(a) * (160.0 * (1.0 - charge) + 20.0)
			draw_line(p, p * 0.8, Color(0.5, 1.0, 0.6, 0.6), 3.0)
		for k in count:
			var x := (float(k) - float(count - 1) * 0.5) * 30.0
			var l := 30.0 + 110.0 * charge
			draw_line(Vector2(x, -l * 0.5), Vector2(x, l * 0.5), Color(0.4, 1.0, 0.5, 0.3), 26.0, true)
			draw_line(Vector2(x, -l * 0.5), Vector2(x, l * 0.5), Color(0.7, 1.0, 0.75), 10.0, true)
			draw_line(Vector2(x, -l * 0.5), Vector2(x, l * 0.5), Color.WHITE, 3.0, true)


## The cutscene: the APHA Architect hovering over the Earth throws the rods; they pierce it.
class EarthCutscene extends CanvasLayer:
	signal finished
	const LEN := 3.4
	var _t := 0.0
	var _painter: Control
	var _boomed := false

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
		if _t >= 2.0 and not _boomed:
			_boomed = true
			SoundManager.play_sfx("explosion")
			SoundManager.play_sfx("rumble")
		_painter.queue_redraw()
		if _t >= LEN:
			finished.emit()
			queue_free()

	func _paint() -> void:
		var p := _painter
		var sz := p.size
		p.draw_rect(Rect2(Vector2.ZERO, sz), Color(0.0, 0.0, 0.03))
		for i in 80:                                       # Stars
			p.draw_circle(Vector2(fmod(float(i) * 137.0, sz.x), fmod(float(i) * 71.0, sz.y)), 1.0 + float(i % 3) * 0.6, Color(1, 1, 1, 0.7))
		# The Earth: a big blue-green planet curving across the bottom
		var ec := Vector2(sz.x * 0.5, sz.y * 1.75)
		var er := sz.y * 1.05
		p.draw_circle(ec, er + 18.0, Color(0.4, 0.7, 1.0, 0.25))
		p.draw_circle(ec, er, Color(0.12, 0.32, 0.7))
		var land := [Vector3(-0.30, 0.95, 0.06), Vector3(-0.12, 0.97, 0.04), Vector3(0.05, 0.93, 0.07), Vector3(0.22, 0.96, 0.05), Vector3(0.36, 0.94, 0.045)]
		for l: Vector3 in land:                            # Continents (patches, not one big ring)
			var cp := ec + Vector2.from_angle(-PI * 0.5 + l.x) * er * l.y
			p.draw_set_transform(cp, l.x, Vector2(1.6, 0.8))
			p.draw_circle(Vector2.ZERO, er * l.z, Color(0.2, 0.55, 0.25))
		p.draw_set_transform(Vector2.ZERO, 0.0, Vector2.ONE)
		for k in 3:                                        # Clouds over it
			var cl := ec + Vector2.from_angle(-PI * 0.5 + (float(k) - 1.0) * 0.28) * er * 0.985
			p.draw_set_transform(cl, 0.0, Vector2(2.2, 0.35))
			p.draw_circle(Vector2.ZERO, 30.0, Color(1, 1, 1, 0.6))
		p.draw_set_transform(Vector2.ZERO, 0.0, Vector2.ONE)
		# The APHA Architect hovering above it, rods in his hands
		var hover := Vector2(sz.x * 0.5, sz.y * 0.5 + sin(_t * 2.0) * 6.0)
		p.draw_set_transform(hover, 0.0, Vector2(1.6, 1.6))
		AlphaArchitectArt.draw_portrait(p, _t)
		p.draw_set_transform(Vector2.ZERO, 0.0, Vector2.ONE)
		var throw_k := clampf((_t - 1.0) / 1.0, 0.0, 1.0)
		var impact := Vector2(sz.x * 0.5, ec.y - er)
		for i in 2:
			var start := hover + Vector2((float(i) - 0.5) * 40.0, -60.0)
			var at := start.lerp(impact + Vector2((float(i) - 0.5) * 30.0, 0), throw_k)
			p.draw_line(at + Vector2(0, -60), at, Color(0.5, 1.0, 0.6, 0.5), 14.0)
			p.draw_line(at + Vector2(0, -60), at, Color.WHITE, 4.0)
		if _t >= 2.0:                                      # Pierced: light bursting out of the planet
			var k := clampf((_t - 2.0) / 1.2, 0.0, 1.0)
			p.draw_circle(impact, 40.0 + 600.0 * k, Color(0.6, 1.0, 0.7, 0.45 * (1.0 - k)))
			for j in 10:
				var a := -PI + float(j) * PI / 9.0
				p.draw_line(impact, impact + Vector2.from_angle(a) * (80.0 + 500.0 * k), Color(0.7, 1.0, 0.75, 0.8 * (1.0 - k)), 6.0)
			p.draw_rect(Rect2(Vector2.ZERO, sz), Color(1, 1, 1, clampf((_t - 2.6) / 0.8, 0.0, 1.0)))
		FighterArt.label(p, Vector2(sz.x * 0.5, sz.y * 0.1), "WORLD IMPLOSION BOMB", 44, Color(0.6, 1.0, 0.7, clampf(_t / 0.4, 0.0, 1.0)))


# ============================================================
# WORLD OPENING: barrier + giant hands
# ============================================================
class Barrier extends Node2D:
	var radius := 0.0
	var max_radius := 620.0
	var hands: Array = []                # [{from, to, t}] giant hand swipes
	var rip := 0.0                       # 0..1 final tear
	var fade := 1.0
	var _t := 0.0

	func _ready() -> void:
		z_index = 7
		process_mode = Node.PROCESS_MODE_ALWAYS

	func add_hand(from: Vector2, to: Vector2) -> void:
		hands.append({"from": from, "to": to, "t": 0.0})

	func _process(delta: float) -> void:
		var real := delta / maxf(Engine.time_scale, 0.01)
		_t += real
		for h in hands:
			h["t"] = float(h["t"]) + real
		hands = hands.filter(func(h: Dictionary) -> bool: return float(h["t"]) < 0.6)
		queue_redraw()

	func _draw() -> void:
		var a := fade
		# Dark inside, glowing dome edge (a half dome over the floor)
		draw_circle(Vector2.ZERO, radius, Color(0.02, 0.03, 0.04, 0.35 * a))
		draw_arc(Vector2.ZERO, radius, PI, TAU, 64, Color(0.4, 1.0, 0.55, 0.25 * a), 26.0, true)
		draw_arc(Vector2.ZERO, radius, PI, TAU, 64, Color(0.7, 1.0, 0.75, 0.9 * a), 5.0, true)
		for i in 10:                                      # Hexagon cells on the dome
			var ang := PI + PI * (float(i) + 0.5) / 10.0
			draw_arc(Vector2.from_angle(ang) * radius * 0.98, 16.0, 0.0, TAU, 6, Color(0.6, 1.0, 0.7, 0.5 * a), 2.0)
		for h in hands:
			var k := clampf(float(h["t"]) / 0.35, 0.0, 1.0)
			var p: Vector2 = (h["from"] as Vector2).lerp(h["to"], k * k)
			var dir := ((h["to"] as Vector2) - (h["from"] as Vector2)).normalized()
			_giant_hand(p, dir, 1.0 - clampf((float(h["t"]) - 0.4) / 0.2, 0.0, 1.0))
		if rip > 0.0:                                     # Two hands tear the middle apart
			_giant_hand(Vector2(-60.0 - 240.0 * rip, -140), Vector2.LEFT, 1.0)
			_giant_hand(Vector2(60.0 + 240.0 * rip, -140), Vector2.RIGHT, 1.0)
			draw_line(Vector2(0, -400), Vector2(0, 0), Color(1, 1, 1, rip), 30.0 * rip)

	func _giant_hand(p: Vector2, dir: Vector2, a: float) -> void:
		var n := dir.orthogonal()
		var palm := PackedVector2Array([p - dir * 70.0 + n * 60.0, p + dir * 40.0 + n * 70.0, p + dir * 60.0 - n * 60.0, p - dir * 60.0 - n * 70.0])
		draw_colored_polygon(palm, Color(0.05, 0.06, 0.07, a))
		for f in 4:                                       # Fingers (claw-like)
			var base := p + dir * 40.0 + n * (55.0 - float(f) * 36.0)
			var tip := base + dir * 110.0 + n * (10.0 - float(f) * 6.0)
			draw_line(base, tip, Color(0, 0, 0, a), 30.0, true)
			draw_line(base, tip, Color(0.12, 0.14, 0.16, a), 22.0, true)
			draw_circle(tip, 10.0, Color(0.4, 1.0, 0.55, a))
		var th := p - dir * 10.0 + n * 70.0               # Thumb
		draw_line(th, th + n * 60.0 + dir * 40.0, Color(0.12, 0.14, 0.16, a), 22.0, true)
		draw_circle(p, 20.0, Color(0.4, 1.0, 0.55, 0.5 * a))       # Sigil in the palm
		FighterArt.outline(self, palm, 5.0, Color(0, 0, 0, a))


# ============================================================
# GODLY TOUCH: 3 random debuffs
# ============================================================
class Debuffs extends Node2D:
	const ALL := ["SLOW", "BURN", "POISON", "WEAKENED", "BLIND", "STUN", "CONFUSION", "DEFENSE DOWN", "LIFE DRAIN"]
	const COLS := {"SLOW": Color(0.5, 0.7, 1.0), "BURN": Color(1.0, 0.45, 0.1), "POISON": Color(0.5, 1.0, 0.3),
		"WEAKENED": Color(0.8, 0.8, 0.8), "BLIND": Color(0.3, 0.3, 0.35), "STUN": Color(1.0, 0.95, 0.4),
		"CONFUSION": Color(0.8, 0.5, 1.0), "DEFENSE DOWN": Color(1.0, 0.3, 0.3), "LIFE DRAIN": Color(0.9, 0.1, 0.3)}
	var source: Fighter
	var victim: Fighter
	var data: AlphaArchitectData
	var active: Array = []
	var left := 6.0
	var _tick := 0.5
	var _blind_layer: CanvasLayer
	var _saved_mistake := -1.0

	func _ready() -> void:
		z_index = 20
		left = data.debuff_duration
		var pool := ALL.duplicate()
		pool.shuffle()
		active = pool.slice(0, data.debuff_count)
		var slow := active.has("SLOW")
		var def := active.has("DEFENSE DOWN")
		if slow or def:
			victim.apply_goo(left, 0.5 if slow else 1.0, 0.5 if def else 0.0)
		if active.has("STUN"):
			victim.stun_timer = maxf(victim.stun_timer, 1.6)
		if active.has("CONFUSION"):
			victim.confuse_timer = maxf(victim.confuse_timer, left)
		if active.has("WEAKENED"):
			victim.outgoing_damage_mult = 0.5
		if active.has("BLIND"):
			var cf := victim as ControlledFighter
			if cf != null and cf.is_human():
				_blind_layer = CanvasLayer.new()
				_blind_layer.layer = 9
				var r := ColorRect.new()
				r.color = Color(0, 0, 0, 0.82)
				r.mouse_filter = Control.MOUSE_FILTER_IGNORE
				r.set_anchors_and_offsets_preset(Control.PRESET_FULL_RECT)
				_blind_layer.add_child(r)
				victim.get_tree().current_scene.add_child(_blind_layer)
			elif cf != null and cf.ctl is BaseAI:
				_saved_mistake = (cf.ctl as BaseAI).mistake_chance
				(cf.ctl as BaseAI).mistake_chance = 0.7      # The CPU can barely see
		Effects.popup(victim, victim.global_position + Vector2(0, -200), "  ".join(PackedStringArray(active)), Color(0.85, 0.7, 1.0), 20)

	func _process(delta: float) -> void:
		if victim == null or not is_instance_valid(victim) or victim.is_dead:
			_end()
			return
		if victim.is_time_frozen():
			return
		left -= delta
		_tick -= delta
		if _tick <= 0.0:
			_tick = 0.5
			if active.has("BURN"):
				_dot(data.burn_tick, "fire")
			if active.has("POISON"):
				_dot(data.poison_tick, "")
			if active.has("LIFE DRAIN"):
				_dot(data.drain_tick, "")
				if source != null and is_instance_valid(source) and not source.is_dead:
					source.heal(data.drain_tick)
		if left <= 0.0:
			_end()
			return
		queue_redraw()

	func _dot(amount: int, kind: String) -> void:
		var h := HitData.new()
		h.source = source if source != null and is_instance_valid(source) else null
		h.damage = amount
		h.blockable = false
		h.causes_hitstun = false
		h.is_tick = true
		h.origin = victim.global_position
		h.hit_type = kind if kind != "" else "alpha"
		h.move = "godly_touch"
		CombatManager.apply_hit(h, victim)

	func _end() -> void:
		if victim != null and is_instance_valid(victim):
			if active.has("WEAKENED"):
				victim.outgoing_damage_mult = 1.0
			var cf := victim as ControlledFighter
			if _saved_mistake >= 0.0 and cf != null and cf.ctl is BaseAI:
				(cf.ctl as BaseAI).mistake_chance = _saved_mistake
		if _blind_layer != null and is_instance_valid(_blind_layer):
			_blind_layer.queue_free()
		queue_free()

	func _draw() -> void:
		var top := -victim.data.body_size.y - 64.0
		for i in active.size():
			var nm := String(active[i])
			var p := Vector2((float(i) - 1.0) * 30.0, top)
			draw_circle(p, 11.0, Color(0, 0, 0, 0.8))
			draw_circle(p, 8.0, COLS.get(nm, Color.WHITE))
		FighterArt.label(self, Vector2(0, top - 18.0), "GODLY TOUCH %.0fs" % maxf(left, 0.0), 12, Color(0.85, 0.7, 1.0))
