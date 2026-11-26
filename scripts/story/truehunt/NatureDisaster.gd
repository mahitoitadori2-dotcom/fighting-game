class_name NatureDisaster
extends Node2D
## NATURAL DISASTERS of THE TRUE HUNT (levels 111-138, the level's "disasters" list). While the fight
## is on, every few seconds one of them strikes. They are NATURE: they hurt EVERYONE (you, your
## partner AND the enemies), and every strike is shown a moment before it lands.
##   quake      the ground shakes; rock spikes burst out of the floor in a row
##   meteors    burning stones fall out of the sky (a shadow + a red ring marks the spot)
##   lightning  the Storm strikes: a thin line of light first, then the bolt
##   eruption   magma bursts out of glowing cracks
##   rockfall   stones drop from the cave ceiling (dust trickles down first)
##   gale       a gust of wind blows everybody sideways for a few seconds
## StoryManager starts one per level (start()) and stops it when the waves / boss end.

const LOOKS := {
	"quake": {"w": 70.0, "h": 130.0, "col": Color(0.55, 0.42, 0.34), "sfx": "stone", "dmg": 7},
	"meteors": {"w": 90.0, "h": 900.0, "col": Color(1.0, 0.45, 0.12), "sfx": "explosion", "dmg": 9},
	"lightning": {"w": 54.0, "h": 900.0, "col": Color(0.75, 0.88, 1.0), "sfx": "beam", "dmg": 8},
	"eruption": {"w": 80.0, "h": 300.0, "col": Color(1.0, 0.42, 0.08), "sfx": "geyser", "dmg": 8},
	"rockfall": {"w": 60.0, "h": 900.0, "col": Color(0.45, 0.40, 0.36), "sfx": "stone", "dmg": 7},
}
const BANNERS := {"quake": "THE GROUND SHAKES", "meteors": "STONES FALL FROM THE SKY", "lightning": "THE STORM STRIKES",
	"eruption": "THE GROUND ERUPTS", "rockfall": "THE CEILING CRUMBLES", "gale": "A GALE IS COMING"}

var manager: StoryManager
var kinds: Array = []
var player_hits := 0                      # Disaster hits on YOU this level (achievement: none)
var _t := 4.0                             # First strike a few seconds into the fight
var _gust_t := 0.0                        # > 0 while the wind blows
var _gust_dir := 1.0
var _streaks: Array = []                  # Wind streaks: [x, y, speed]
var _announced := {}                      # Kinds already named this level


static func start(m: StoryManager, p_kinds: Array) -> NatureDisaster:
	var d := NatureDisaster.new()
	d.name = "NatureDisaster"
	d.manager = m
	d.kinds = p_kinds.duplicate()
	m.add_child(d)
	return d


func _ready() -> void:
	z_index = 8


## Seconds between two strikes: a bit faster deeper in the hunt and with more kinds at once.
func _interval() -> float:
	var deep := clampf(float(manager.level_number - StoryLevels.TRUE_FIRST) / 27.0, 0.0, 1.0)
	return randf_range(4.6, 6.4) - 1.4 * deep


func _process(delta: float) -> void:
	if manager == null or not is_instance_valid(manager) or manager.player == null:
		return
	_update_gust(delta)
	if not CombatManager.fight_active or manager._over or kinds.is_empty() or CombatManager.is_time_stopped():
		return
	_t -= delta
	if _t > 0.0:
		return
	_t = _interval()
	_strike(String(kinds.pick_random()))


func _strike(kind: String) -> void:
	if not _announced.has(kind):                       # The first of each kind is named out loud
		_announced[kind] = true
		Effects.popup(manager.player, manager.player.global_position + Vector2(0, -230), String(BANNERS.get(kind, "")), Color(1.0, 0.75, 0.45), 24)
		SoundManager.play_sfx("rumble", -6.0)
	if kind == "gale":
		_gust_dir = -1.0 if randf() < 0.5 else 1.0
		_gust_t = 3.2
		Effects.popup(manager.player, manager.player.global_position + Vector2(0, -190), "%s" % ("<<<" if _gust_dir < 0.0 else ">>>"), Color(0.8, 0.92, 1.0), 28)
		SoundManager.play_sfx("whoosh")
		return
	var count := int({"quake": 4, "meteors": 3, "lightning": 2, "eruption": 3, "rockfall": 3}.get(kind, 2))
	var xs := _targets(count, kind == "quake")
	if kind == "quake":
		Effects.shake(manager, 10.0)
		SoundManager.play_sfx("rumble", -2.0)
	for i in xs.size():
		var s := Strike.new()
		s.kind = kind
		s.owner_d = self
		s.delay = (1.05 if kind != "lightning" else 0.8) + (0.18 * float(i) if kind == "quake" else randf_range(0.0, 0.35))
		var look: Dictionary = LOOKS[kind]
		s.half_w = float(look["w"]) * 0.5
		s.height = float(look["h"])
		s.col = look["col"]
		s.damage = int(look["dmg"])
		manager.add_child(s)
		s.global_position = Vector2(xs[i], manager._ground_y)


## Where to strike: mostly near you / your partner, some anywhere. A quake runs in a row.
func _targets(n: int, row: bool) -> Array:
	var lo := (StoryManager.wall_left_x if StoryManager.has_walls else manager.player.global_position.x - 800.0) + 60.0
	var hi := (StoryManager.wall_right_x if StoryManager.has_walls else manager.player.global_position.x + 800.0) - 60.0
	var px := manager.player.global_position.x
	var out: Array = []
	if row:
		var dir := 1.0 if randf() < 0.5 else -1.0
		var x0 := px - dir * 260.0
		for i in n:
			out.append(clampf(x0 + dir * 150.0 * float(i), lo, hi))
		return out
	for i in n:
		var near := i == 0 or randf() < 0.45
		var x := px + randf_range(-220.0, 220.0) if near else randf_range(lo, hi)
		out.append(clampf(x, lo, hi))
	return out


## The GALE: everybody on the ground slides with the wind (you can walk against it, slowly).
func _update_gust(delta: float) -> void:
	if _gust_t > 0.0 and CombatManager.fight_active and not manager._over:
		_gust_t -= delta
		var lo := StoryManager.wall_left_x + 40.0 if StoryManager.has_walls else -100000.0
		var hi := StoryManager.wall_right_x - 40.0 if StoryManager.has_walls else 100000.0
		for n in get_tree().get_nodes_in_group("fighters"):
			var f := n as Fighter
			if f == null or f.is_dead or f.grabbed_by != null:
				continue
			var push := 150.0 if f.is_on_floor() else 230.0
			if f is BaseEnemy and (f as BaseEnemy).boss_hp_mult > 1.0:
				push *= 0.3                              # Bosses barely move
			f.global_position.x = clampf(f.global_position.x + _gust_dir * push * delta, lo, hi)
		if randf() < 0.6:
			var vp := get_viewport_rect().size
			var cam := get_viewport().get_camera_2d()
			var c := cam.get_screen_center_position() if cam != null else manager.player.global_position
			_streaks.append([c.x - _gust_dir * vp.x * 0.7, c.y + randf_range(-vp.y * 0.45, vp.y * 0.35), randf_range(1300.0, 1900.0)])
	var alive: Array = []
	for s in _streaks:
		s[0] += _gust_dir * float(s[2]) * delta
		if absf(float(s[0]) - manager.player.global_position.x) < 1600.0:
			alive.append(s)
	_streaks = alive
	if not _streaks.is_empty() or _gust_t > 0.0:
		queue_redraw()


func _draw() -> void:
	for s in _streaks:
		var p := Vector2(float(s[0]), float(s[1]))
		draw_line(p, p - Vector2(_gust_dir * 120.0, 0), Color(0.85, 0.92, 1.0, 0.35), 3.0)


## Removes every strike still waiting (level over).
func stop() -> void:
	kinds.clear()
	_gust_t = 0.0
	for n in manager.get_children():
		if n is Strike:
			n.queue_free()


# ============================================================
# ONE STRIKE: a warning on the floor for `delay` seconds, then it lands (hits everyone inside)
# ============================================================
class Strike extends Node2D:
	var kind := "quake"
	var owner_d: NatureDisaster
	var delay := 1.0
	var half_w := 35.0
	var height := 120.0
	var col := Color.WHITE
	var damage := 7
	var _age := 0.0
	var _struck := false
	var _seed := 0.0
	const LIFE := 0.6

	func _ready() -> void:
		z_index = 9
		_seed = randf() * 100.0

	func _process(delta: float) -> void:
		if CombatManager.is_time_stopped():
			return
		_age += delta
		if not _struck and _age >= delay:
			_land()
		if _age >= delay + LIFE:
			queue_free()
			return
		queue_redraw()

	func _land() -> void:
		_struck = true
		SoundManager.play_sfx(String(NatureDisaster.LOOKS[kind]["sfx"]), -4.0)
		Effects.shake(self, 7.0 if kind != "lightning" else 5.0)
		Effects.hit_sparks(self, global_position + Vector2(0, -10), 7, 1.1)
		if kind == "meteors" or kind == "eruption":
			Effects.explosion(self, global_position + Vector2(0, -30), 60.0, true, true)
		var reach := 160.0 if kind in ["quake", "eruption"] else 900.0    # How high above the floor it hurts
		for n in get_tree().get_nodes_in_group("fighters"):
			var f := n as Fighter
			if f == null or f.is_dead:
				continue
			if absf(f.global_position.x - global_position.x) > half_w + f.data.body_size.x * 0.5:
				continue
			if f.global_position.y < global_position.y - reach or f.global_position.y - f.data.body_size.y > global_position.y + 10.0:
				continue
			var dx := signf(f.global_position.x - global_position.x)
			var h := HitData.new()
			h.source = null                                # NATURE: nobody's attack, everybody's problem
			h.damage = damage
			h.knockback = Vector2((dx if dx != 0.0 else 1.0) * 260.0, -380.0)
			h.origin = global_position + Vector2(0, -400)   # From above: a block facing sideways doesn't stop it
			h.blockable = false
			h.hit_type = "trap"
			h.move = "disaster_" + kind
			h.gauge_gain = false
			var r := CombatManager.apply_hit(h, f)
			if r == "hit" and owner_d != null and is_instance_valid(owner_d) and f == owner_d.manager.player:
				owner_d.player_hits += 1

	func _draw() -> void:
		if not _struck:
			_draw_warning()
		else:
			_draw_land(clampf((_age - delay) / LIFE, 0.0, 1.0))

	func _draw_warning() -> void:
		var w := clampf(_age / maxf(delay, 0.01), 0.0, 1.0)
		var blink := 0.5 + 0.5 * sin(_age * 26.0)
		draw_set_transform(Vector2.ZERO, 0.0, Vector2(1.0, 0.25))
		draw_circle(Vector2.ZERO, half_w * (0.35 + 0.65 * w), Color(col.r, col.g, col.b, 0.22 + 0.25 * w))
		draw_arc(Vector2.ZERO, half_w + 6.0, 0.0, TAU, 28, Color(1.0, 0.3, 0.2, 0.45 + 0.4 * blink), 6.0)
		draw_set_transform(Vector2.ZERO, 0.0, Vector2.ONE)
		match kind:
			"lightning":                                   # A faint line of light from the clouds
				draw_line(Vector2(0, -900), Vector2.ZERO, Color(col.r, col.g, col.b, 0.12 + 0.3 * w * blink), 2.0 + 3.0 * w)
			"meteors":                                     # The stone, still high up, growing
				var y := -900.0 + 300.0 * w
				draw_circle(Vector2(sin(_seed) * 40.0 * (1.0 - w), y), 6.0 + 10.0 * w, Color(1.0, 0.55, 0.2, 0.5 + 0.5 * w))
			"rockfall":                                    # Dust trickling down
				for i in 5:
					var ph := fmod(_age * 2.5 + float(i) * 0.2, 1.0)
					draw_circle(Vector2((float(i) - 2.0) * 6.0, -500.0 + 480.0 * ph), 2.5, Color(0.6, 0.55, 0.5, 0.7))
			_:                                             # Cracks in the floor
				for i in 5:
					var a := PI + PI * (float(i) + 0.5) / 5.0
					draw_line(Vector2.ZERO, Vector2.from_angle(a) * Vector2(half_w, 10.0) * w, Color(col.r, col.g, col.b, 0.9), 3.0)

	func _draw_land(k: float) -> void:
		var fade := 1.0 - clampf((k - 0.55) / 0.45, 0.0, 1.0)
		match kind:
			"quake":
				var up := minf(1.0, k / 0.12)
				var slab := PackedVector2Array([Vector2(-half_w, 0), Vector2(-half_w * 0.5, -height * 0.7 * up), Vector2(-half_w * 0.05, -height * up),
					Vector2(half_w * 0.55, -height * 0.6 * up), Vector2(half_w, 0)])
				draw_colored_polygon(slab, Color(col.r, col.g, col.b, fade))
				FighterArt.outline(self, slab, 3.0, Color(0, 0, 0, fade))
			"eruption":
				var h := height * minf(1.0, k / 0.15)
				var pts := PackedVector2Array([Vector2(-half_w, 0), Vector2(-half_w * 0.6, -h * 0.6), Vector2(-half_w * 0.4, -h), Vector2(half_w * 0.4, -h), Vector2(half_w * 0.6, -h * 0.6), Vector2(half_w, 0)])
				draw_colored_polygon(pts, Color(0.75, 0.15, 0.03, fade))
				draw_rect(Rect2(-half_w * 0.25, -h, half_w * 0.5, h), Color(1.0, 0.85, 0.4, fade))
			"lightning":
				var pts2 := PackedVector2Array()
				var rng := RandomNumberGenerator.new()
				rng.seed = int(_seed * 1000.0)
				for i in 10:
					pts2.append(Vector2(rng.randf_range(-22.0, 22.0) if i > 0 and i < 9 else 0.0, -900.0 + 100.0 * float(i)))
				draw_polyline(pts2, Color(col.r, col.g, col.b, 0.35 * fade), 18.0)
				draw_polyline(pts2, Color(1, 1, 1, fade), 5.0)
				draw_set_transform(Vector2.ZERO, 0.0, Vector2(1.0, 0.3))
				draw_circle(Vector2.ZERO, half_w * 2.2, Color(col.r, col.g, col.b, 0.45 * fade))
				draw_set_transform(Vector2.ZERO, 0.0, Vector2.ONE)
			"meteors", "rockfall":
				var stone := Color(0.30, 0.18, 0.12) if kind == "meteors" else col
				draw_colored_polygon(EnemyArt.ellipse_points(Vector2(0, -18), 26.0, 20.0, 10), Color(stone.r, stone.g, stone.b, fade))
				if kind == "meteors":
					draw_circle(Vector2(0, -18), 14.0, Color(1.0, 0.55, 0.15, 0.8 * fade))
				for i in 6:
					var v := Vector2(sin(_seed + float(i) * 1.7) * 260.0, -260.0 - float(i) * 30.0)
					var t := k * LIFE
					draw_circle(v * t + Vector2(0, 900.0 * t * t), 5.0 * fade, Color(col.r, col.g, col.b, fade))
