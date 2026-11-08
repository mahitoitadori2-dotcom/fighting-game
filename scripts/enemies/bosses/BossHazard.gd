class_name BossHazard
extends Node2D
## Ground hazard for the Fights-mode bosses. WARNING marker on the floor for `delay`
## seconds (dodge it!), then it STRIKES once (hits everyone of the other team inside
## its box) and plays its strike animation, then frees itself.
##   pillar   Minos  - Ground Eruption: pillar of white light erupts from the floor
##   serpent  Minos  - Ghost Serpent: a glowing ghost serpent head bursts up and bites
##   spear    Geyron - Judgment Spears: a spear of light falls from the sky
##   rock     Sisyphus - Ground Shatter / boulder impact: rocks blast up out of the floor
##   chain    Sisyphus - Chain Slam: a chain whips down onto the floor
## Few at a time (max ~6 per attack), so these are plain nodes (not pooled).
##
##   BossHazard.spawn(boss, "pillar", Vector2(x, floor_y), delay, damage, knockback)

const LOOKS := {
	"pillar": {"w": 70.0, "h": 420.0, "life": 0.5, "col": Color(0.75, 0.9, 1.0), "sfx": "holy"},
	"serpent": {"w": 80.0, "h": 170.0, "life": 0.45, "col": Color(0.45, 0.85, 1.0), "sfx": "bite"},
	"spear": {"w": 44.0, "h": 200.0, "life": 0.5, "col": Color(1.0, 0.95, 0.7), "sfx": "holy"},
	"rock": {"w": 70.0, "h": 120.0, "life": 0.55, "col": Color(0.55, 0.45, 0.38), "sfx": "stone"},
	"chain": {"w": 60.0, "h": 90.0, "life": 0.35, "col": Color(0.7, 0.7, 0.75), "sfx": "chain"},
	# Blasphemy Caeser (Story, Colosseum 2): a column of magma bursts out of the floor
	"geyser": {"w": 84.0, "h": 320.0, "life": 0.7, "col": Color(1.0, 0.42, 0.08), "sfx": "geyser"},
}

var source: BaseEnemy
var kind := "pillar"
var delay := 0.8
var damage := 6
var knockback := Vector2(200, -380)
var move := "boss_hazard"
var half_w := 35.0
var height := 400.0
var life := 0.5
var col := Color.WHITE
var _age := 0.0
var _struck := false
var _seed := 0.0


static func spawn(src: BaseEnemy, p_kind: String, ground_pos: Vector2, p_delay: float, dmg: int,
		kb: Vector2 = Vector2(220, -420)) -> BossHazard:
	if src == null or not src.is_inside_tree():
		return null
	var h := BossHazard.new()
	h.source = src
	h.kind = p_kind
	h.delay = p_delay
	h.damage = dmg
	h.knockback = kb
	h.move = "boss_" + p_kind
	var look: Dictionary = LOOKS.get(p_kind, LOOKS["pillar"])
	h.half_w = float(look["w"]) * 0.5
	h.height = float(look["h"])
	h.life = float(look["life"])
	h.col = look["col"]
	src.get_tree().current_scene.add_child(h)
	h.global_position = ground_pos
	return h


func _ready() -> void:
	z_index = 9
	_seed = randf() * 100.0


func _process(delta: float) -> void:
	if source != null and is_instance_valid(source) and source.is_time_frozen():
		queue_redraw()
		return                                          # Time Stop freezes boss hazards too
	_age += delta
	if not _struck and _age >= delay:
		_strike()
	if _age >= delay + life:
		queue_free()
		return
	if OptimizationManager.on_screen(global_position, 300.0):
		queue_redraw()


func _strike() -> void:
	_struck = true
	SoundManager.play_sfx(String(LOOKS.get(kind, {}).get("sfx", "hit")), -3.0)
	Effects.shake(self, 6.0 if kind != "chain" else 4.0)
	Effects.hit_sparks(self, global_position + Vector2(0, -10), 6, 1.0)
	if source == null or not is_instance_valid(source) or source.is_dead:
		return
	var top := global_position.y - height
	for n in get_tree().get_nodes_in_group("fighters") + get_tree().get_nodes_in_group("helpers"):
		var f := n as Fighter
		if f == null or f.is_dead or CombatManager.are_allies(source, f):
			continue
		var hw := f.data.body_size.x * 0.5
		if absf(f.global_position.x - global_position.x) > half_w + hw:
			continue
		if f.global_position.y < top or f.global_position.y - f.data.body_size.y > global_position.y + 10.0:
			continue
		var dx := signf(f.global_position.x - global_position.x)
		if dx == 0.0:
			dx = 1.0
		var h := source.make_hit(damage, Vector2(dx * knockback.x, knockback.y), move)
		h.origin = global_position + Vector2(0, -40)
		CombatManager.apply_hit(h, f)


# ============================================================
# DRAW (origin = floor point)
# ============================================================
func _draw() -> void:
	if not _struck:
		_draw_warning()
		return
	var k := clampf((_age - delay) / life, 0.0, 1.0)
	match kind:
		"pillar":
			_draw_pillar(k)
		"serpent":
			_draw_serpent(k)
		"spear":
			_draw_spear(k)
		"rock":
			_draw_rock(k)
		"chain":
			_draw_chain(k)
		"geyser":
			_draw_geyser(k)


func _draw_geyser(k: float) -> void:
	var up := minf(1.0, k / 0.15)
	var fade := 1.0 - clampf((k - 0.65) / 0.35, 0.0, 1.0)
	var h := height * up
	var w := half_w * (1.0 + 0.1 * sin(k * 40.0))
	# Column of magma: dark crust edge, orange body, white-hot core
	var col_pts := PackedVector2Array([Vector2(-w, 0), Vector2(-w * 0.7, -h * 0.6), Vector2(-w * 0.45, -h), Vector2(w * 0.45, -h), Vector2(w * 0.7, -h * 0.6), Vector2(w, 0)])
	draw_colored_polygon(col_pts, Color(0.75, 0.15, 0.03, fade))
	var mid := PackedVector2Array()
	for p in col_pts:
		mid.append(Vector2(p.x * 0.65, p.y))
	draw_colored_polygon(mid, Color(col.r, col.g, col.b, fade))
	draw_rect(Rect2(-w * 0.18, -h, w * 0.36, h), Color(1.0, 0.92, 0.55, fade))
	# Spray of blobs at the top + splash ring at the floor
	var rng := RandomNumberGenerator.new()
	rng.seed = int(_seed * 1000.0)
	for i in 7:
		var v := Vector2(rng.randf_range(-220.0, 220.0), rng.randf_range(-260.0, -80.0))
		var t := k * life
		var p := Vector2(0, -h) + v * t + Vector2(0, 900.0 * t * t)
		draw_circle(p, rng.randf_range(5.0, 10.0) * fade, Color(1.0, 0.55, 0.12, fade))
	draw_set_transform(Vector2.ZERO, 0.0, Vector2(1.0, 0.3))
	draw_circle(Vector2.ZERO, w * 1.8, Color(1.0, 0.5, 0.1, 0.45 * fade))
	draw_set_transform(Vector2.ZERO, 0.0, Vector2.ONE)


func _draw_warning() -> void:
	var w := clampf(_age / maxf(delay, 0.01), 0.0, 1.0)
	var blink := 0.5 + 0.5 * sin(_age * 28.0)
	draw_set_transform(Vector2.ZERO, 0.0, Vector2(1.0, 0.25))
	draw_circle(Vector2.ZERO, half_w * (0.4 + 0.6 * w), Color(col.r, col.g, col.b, 0.25 + 0.25 * w))
	draw_arc(Vector2.ZERO, half_w + 6.0, 0.0, TAU, 28, Color(1.0, 0.3, 0.2, 0.5 + 0.4 * blink), 6.0, true)
	draw_set_transform(Vector2.ZERO, 0.0, Vector2.ONE)
	match kind:
		"spear":                                        # Thin light line from the sky
			draw_line(Vector2(0, -900), Vector2.ZERO, Color(col.r, col.g, col.b, 0.15 + 0.25 * w), 2.0 + 4.0 * w)
		"pillar":                                       # Light leaking out of cracks
			for i in 3:
				var x := (float(i) - 1.0) * half_w * 0.5
				draw_line(Vector2(x, 0), Vector2(x + sin(_seed + float(i)) * 6.0, -14.0 * w), Color(1, 1, 1, 0.7 * w), 3.0)
		"rock", "serpent":                              # Ground cracks
			for i in 4:
				var a := PI + PI * (float(i) + 0.5) / 4.0
				draw_line(Vector2.ZERO, Vector2.from_angle(a) * Vector2(half_w, 8.0) * w, Color(0.1, 0.05, 0.02, 0.9), 3.0)
		"geyser":                                       # Glowing cracks + bubbling magma
			for i in 5:
				var a := PI + PI * (float(i) + 0.5) / 5.0
				draw_line(Vector2.ZERO, Vector2.from_angle(a) * Vector2(half_w, 10.0) * w, Color(1.0, 0.55, 0.1, 0.9), 3.0)
			for i in 3:
				var ph := fmod(_age * 3.0 + float(i) * 0.33, 1.0)
				draw_circle(Vector2((float(i) - 1.0) * half_w * 0.4, -ph * 24.0 * w), 4.0 * (1.0 - ph), Color(1.0, 0.6, 0.15, 0.8))


func _draw_pillar(k: float) -> void:
	var grow := minf(1.0, k / 0.15)
	var fade := 1.0 - clampf((k - 0.6) / 0.4, 0.0, 1.0)
	var h := height * grow
	var w := half_w * (1.0 - 0.4 * k)
	draw_rect(Rect2(-w * 1.6, -h, w * 3.2, h), Color(col.r, col.g, col.b, 0.25 * fade))
	draw_rect(Rect2(-w, -h, w * 2.0, h), Color(col.r, col.g, col.b, 0.75 * fade))
	draw_rect(Rect2(-w * 0.4, -h, w * 0.8, h), Color(1, 1, 1, fade))
	draw_set_transform(Vector2.ZERO, 0.0, Vector2(1.0, 0.3))
	draw_circle(Vector2.ZERO, w * 2.2, Color(1, 1, 1, 0.6 * fade))
	draw_set_transform(Vector2.ZERO, 0.0, Vector2.ONE)


func _draw_serpent(k: float) -> void:
	# Ghost serpent: rises fast, jaws snap shut, sinks back
	var rise := sin(clampf(k, 0.0, 1.0) * PI)
	var top := Vector2(sin(_seed) * 10.0, -height * rise)
	var a := 0.85 * (1.0 - clampf((k - 0.75) / 0.25, 0.0, 1.0))
	var body := PackedVector2Array()
	for i in 9:
		var t := float(i) / 8.0
		body.append(Vector2(sin(t * 5.0 + _seed) * 14.0 * (1.0 - t), 0).lerp(top, t))
	draw_polyline(body, Color(col.r, col.g, col.b, a * 0.35), 46.0, true)
	draw_polyline(body, Color(col.r, col.g, col.b, a * 0.8), 26.0, true)
	draw_polyline(body, Color(1, 1, 1, a * 0.6), 8.0, true)
	var bite := clampf((k - 0.2) / 0.15, 0.0, 1.0)      # 0 = open jaws, 1 = shut
	var jaw := 0.9 * (1.0 - bite)
	var head := top + Vector2(0, -6)
	for s in [-1.0, 1.0]:
		var pts := PackedVector2Array([head, head + Vector2.from_angle(-PI * 0.5 + s * jaw) * 46.0 + Vector2(s * 8.0, 0), head + Vector2(s * 18.0, 4.0)])
		draw_colored_polygon(pts, Color(col.r, col.g, col.b, a))
		draw_polyline(PackedVector2Array([pts[0], pts[1], pts[2]]), Color(1, 1, 1, a), 2.0, true)
	draw_circle(head + Vector2(-8, 6), 4.0, Color(1, 1, 1, a))
	draw_circle(head + Vector2(8, 6), 4.0, Color(1, 1, 1, a))


func _draw_spear(k: float) -> void:
	var fall := minf(1.0, k / 0.12)
	var y := -900.0 * (1.0 - fall)
	var fade := 1.0 - clampf((k - 0.6) / 0.4, 0.0, 1.0)
	var tip := Vector2(0, y)
	var tail := tip + Vector2(0, -height)
	draw_line(tail, tip, Color(col.r, col.g, col.b, 0.35 * fade), 22.0, true)
	draw_line(tail, tip, Color(col.r, col.g, col.b, fade), 9.0, true)
	draw_line(tail, tip, Color(1, 1, 1, fade), 3.0, true)
	draw_colored_polygon(PackedVector2Array([tip + Vector2(-14, -40), tip + Vector2(14, -40), tip + Vector2(0, 6)]), Color(1, 1, 0.9, fade))
	if fall >= 1.0:
		draw_arc(Vector2.ZERO, 20.0 + k * 120.0, PI, TAU, 20, Color(col.r, col.g, col.b, fade), 5.0, true)


func _draw_rock(k: float) -> void:
	var fade := 1.0 - clampf((k - 0.65) / 0.35, 0.0, 1.0)
	var rng := RandomNumberGenerator.new()
	rng.seed = int(_seed * 1000.0)
	# A jagged slab bursting out of the floor + chunks flying up
	var up := minf(1.0, k / 0.12) * (1.0 - clampf((k - 0.6) / 0.4, 0.0, 1.0))
	var slab := PackedVector2Array([Vector2(-half_w, 0), Vector2(-half_w * 0.6, -height * 0.6 * up), Vector2(-half_w * 0.1, -height * up),
		Vector2(half_w * 0.5, -height * 0.7 * up), Vector2(half_w, 0)])
	draw_colored_polygon(slab, Color(col.r, col.g, col.b, fade))
	FighterArt.outline(self, slab, 3.0, Color(0, 0, 0, fade))
	for i in 6:
		var v := Vector2(rng.randf_range(-260.0, 260.0), rng.randf_range(-720.0, -380.0))
		var t := k * life
		var p := v * t + Vector2(0, 1400.0 * t * t)
		var r := rng.randf_range(6.0, 12.0)
		draw_rect(Rect2(p - Vector2(r, r), Vector2(r, r) * 2.0), Color(col.r * 0.8, col.g * 0.8, col.b * 0.8, fade))


func _draw_chain(k: float) -> void:
	var fade := 1.0 - clampf((k - 0.5) / 0.5, 0.0, 1.0)
	for i in 8:
		var p := Vector2(-half_w + float(i) * half_w * 0.28, -6.0 - absf(sin(float(i) * 1.3 + k * 20.0)) * 10.0 * (1.0 - k))
		var link := EnemyArt.ellipse_points(p, 9.0, 5.0, 10)
		link.append(link[0])
		draw_polyline(link, Color(0, 0, 0, fade), 5.0, true)
		draw_polyline(link, Color(col.r, col.g, col.b, fade), 3.0, true)
