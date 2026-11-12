class_name DemiWorld
extends RefCounted
## DEMILAND: the open world's LAYOUT (one long strip, x = -HALF .. +HALF, the floor at y = 525)
## and its SCENERY. The layout below is the one truth: the game spawns from it and the MAP
## (DemiMap) draws from it, so the map is always accurate.
##
##   WEST  <-  TIGER RAVINE | DEAD PLAINS | ANCIENT DOOR (start) | TRIBE VILLAGE | DEAD GROVE  ->  EAST

const HALF := 9000.0
const FLOOR_Y := 525.0

const REGIONS := [
	{"key": "demi_ravine", "name": "THE TIGER RAVINE", "x0": -9000.0, "x1": -5200.0, "col": Color(0.42, 0.24, 0.12)},
	{"key": "demi_plains", "name": "THE DEAD PLAINS", "x0": -5200.0, "x1": -1000.0, "col": Color(0.24, 0.22, 0.24)},
	{"key": "demi_door", "name": "THE ANCIENT DOOR", "x0": -1000.0, "x1": 1000.0, "col": Color(0.30, 0.28, 0.36)},
	{"key": "demi_village", "name": "THE TRIBE VILLAGE", "x0": 1000.0, "x1": 5000.0, "col": Color(0.40, 0.16, 0.10)},
	{"key": "demi_grove", "name": "THE DEAD GROVE", "x0": 5000.0, "x1": 9000.0, "col": Color(0.16, 0.24, 0.14)},
]
## CAMTONS (checkpoints): old rock pillars that make flames around themselves. Rest = full HP +
## flasks, enemies come back, and you wake at the last CamTon you lit when you die.
const SHRINES := [
	{"x": -420.0, "name": "CamTon of the Door"},
	{"x": -4700.0, "name": "CamTon of the Plains"},
	{"x": -6500.0, "name": "CamTon of the Ravine"},
	{"x": 1500.0, "name": "CamTon of the Village"},
	{"x": 5500.0, "name": "CamTon of the Grove"},
]
## Enemy camps: they wake up when you come near. "night" = one more joins at night.
const CAMPS := [
	{"x": -2100.0, "ids": ["tribe_hunter", "tribe_hunter"], "night": "tribe_hunter"},
	{"x": -3300.0, "ids": ["pelt_cultist", "tiger_cub"], "night": "tiger_cub"},
	{"x": -4200.0, "ids": ["tribe_brute", "tribe_hunter"], "night": "tribe_shaman"},
	{"x": -5800.0, "ids": ["tiger_cub", "tiger_cub", "pelt_cultist"], "night": "tiger_cub"},
	{"x": -6950.0, "ids": ["pelt_cultist", "pelt_cultist", "tiger_cub"], "night": "pelt_cultist"},
	{"x": 2150.0, "ids": ["tribe_hunter", "tribe_brute"], "night": "tribe_hunter"},
	{"x": 2900.0, "ids": ["tribe_shaman", "tribe_hunter", "tribe_hunter"], "night": "tribe_brute"},
	{"x": 6050.0, "ids": ["husk", "sapling", "sapling"], "night": "sapling"},
	{"x": 6750.0, "ids": ["husk", "husk", "sapling"], "night": "sapling"},
]
## The three bosses. Their arena closes with walls of fog when the fight starts.
const BOSSES := [
	{"id": "last_tiger", "x": -8000.0, "half": 850.0, "region": "demi_ravine", "artifact": "fang", "artifact_name": "THE TIGER'S FANG",
		"music": "boss_tiger", "color": Color(1.0, 0.62, 0.2), "sub": "Last of Its Kind", "line": "*it has been waiting a long time for something to hunt*", "entrance": "drop"},
	{"id": "tribe_master", "x": 4100.0, "half": 850.0, "region": "demi_village", "artifact": "crown", "artifact_name": "THE BONE CROWN",
		"music": "boss_tribe", "color": Color(1.0, 0.38, 0.15), "sub": "Chieftain of DemiLand", "line": "You walk on OUR land.", "entrance": "drop"},
	{"id": "tree_lord", "x": 7900.0, "half": 850.0, "region": "demi_grove", "artifact": "heart", "artifact_name": "THE LIVING HEART",
		"music": "boss_treelord", "color": Color(0.5, 1.0, 0.4), "sub": "The Last Living Tree", "line": "*the dead tree in the middle of the grove opens its eyes*", "entrance": "rise"},
]
const DOOR_X := 0.0

const BLACK := Color(0, 0, 0)


static func region_at(x: float) -> Dictionary:
	for r in REGIONS:
		if x >= float(r["x0"]) and x < float(r["x1"]):
			return r
	return REGIONS[0] if x < 0.0 else REGIONS[REGIONS.size() - 1]


static func boss_def(id: String) -> Dictionary:
	for b in BOSSES:
		if String(b["id"]) == id:
			return b
	return {}


# ============================================================
# SCENERY: a fixed (seeded) list of props, per region
# ============================================================
static var _props: Array = []


## Every prop: {kind, x, s (scale), v (variant)}. Never inside a boss arena's middle or on a shrine.
static func props() -> Array:
	if not _props.is_empty():
		return _props
	var rng := RandomNumberGenerator.new()
	rng.seed = 6363
	for r in REGIONS:
		var key := String(r["key"])
		var x := float(r["x0"]) + 120.0
		while x < float(r["x1"]) - 80.0:
			var kind := _pick(rng, key)
			if not _blocked(x):
				_props.append({"kind": kind, "x": x, "s": rng.randf_range(0.75, 1.3), "v": rng.randi() % 7})
			x += rng.randf_range(170.0, 330.0)
	for b in BOSSES:                                          # Each arena gets its landmark
		var bx := float(b["x"])
		match String(b["id"]):
			"last_tiger":
				for d: float in [-620.0, 640.0]:
					_props.append({"kind": "tiger_skull", "x": bx + d, "s": 1.4, "v": 0})
				_props.append({"kind": "cliff", "x": bx - 760.0, "s": 1.6, "v": 1})
			"tribe_master":
				for d: float in [-560.0, -280.0, 300.0, 580.0]:
					_props.append({"kind": "totem", "x": bx + d, "s": 1.5, "v": 2})
				_props.append({"kind": "throne", "x": bx + 720.0, "s": 1.4, "v": 0})
			"tree_lord":
				for d: float in [-700.0, -420.0, 450.0, 720.0]:
					_props.append({"kind": "giant_tree", "x": bx + d, "s": 1.2, "v": 3})
	_props.sort_custom(func(a: Dictionary, b2: Dictionary) -> bool: return float(a["x"]) < float(b2["x"]))
	return _props


static func _pick(rng: RandomNumberGenerator, key: String) -> String:
	var pool: Array
	match key:
		"demi_ravine":
			pool = ["cliff", "rock", "bones", "dead_tree", "tiger_skull", "rock"]
		"demi_village":
			pool = ["hut", "totem", "hut", "campfire", "bones", "dead_tree", "rack"]
		"demi_grove":
			pool = ["giant_tree", "dead_tree", "giant_tree", "stump", "dead_tree", "bones"]
		"demi_door":
			pool = ["pillar", "rock", "dead_tree", "pillar"]
		_:
			pool = ["dead_tree", "dead_tree", "rock", "bones", "stump", "skull_pole"]
	return String(pool[rng.randi() % pool.size()])


## Keep CamTons, the door and the middle of boss arenas clear (no clutter where you fight).
static func _blocked(x: float) -> bool:
	for s in SHRINES:
		if absf(x - float(s["x"])) < 160.0:
			return true
	if absf(x - DOOR_X) < 330.0:
		return true
	for b in BOSSES:
		if absf(x - float(b["x"])) < float(b["half"]) - 180.0:
			return true
	return false


# ============================================================
# DRAWING (origin = ground at the prop's x; facing doesn't matter)
# ============================================================
static func draw_prop(c: CanvasItem, p: Dictionary) -> void:
	var s: float = p["s"]
	var v: int = p["v"]
	var x: float = p["x"]
	var o := Vector2(x, FLOOR_Y + 4.0)
	var dark := Color(0.10, 0.09, 0.10)
	match String(p["kind"]):
		"dead_tree":
			_tree(c, o, 220.0 * s, dark, v)
		"giant_tree":
			_tree(c, o, 420.0 * s, Color(0.08, 0.09, 0.07), v, 2.0)
		"stump":
			var st := PackedVector2Array([o + Vector2(-28, 0) * s, o + Vector2(-20, -50) * s, o + Vector2(22, -46) * s, o + Vector2(30, 0) * s])
			c.draw_colored_polygon(st, dark)
			FighterArt.outline(c, st, 3.0)
		"rock":
			var rp := PackedVector2Array()
			for i in 7:
				var a := PI + PI * float(i) / 6.0
				rp.append(o + Vector2(cos(a) * 60.0, sin(a) * (34.0 + float((v + i) % 3) * 10.0)) * s)
			c.draw_colored_polygon(rp, Color(0.16, 0.15, 0.16))
			FighterArt.outline(c, rp, 3.0)
		"cliff":
			var cp := PackedVector2Array([o + Vector2(-160, 0) * s, o + Vector2(-120, -260) * s, o + Vector2(-40, -330) * s, o + Vector2(60, -280) * s, o + Vector2(150, 0) * s])
			c.draw_colored_polygon(cp, Color(0.13, 0.10, 0.09))
			c.draw_line(o + Vector2(-60, -280) * s, o + Vector2(-20, -60) * s, Color(0.07, 0.05, 0.05), 4.0)
			FighterArt.outline(c, cp, 3.5)
		"bones":
			for i in 3:
				var bp := o + Vector2(float(i) * 22.0 - 22.0, -6.0) * s
				c.draw_line(bp + Vector2(-14, 2), bp + Vector2(14, -2), BLACK, 7.0)
				c.draw_line(bp + Vector2(-14, 2), bp + Vector2(14, -2), DemiArt.BONE.darkened(0.3), 4.0)
			c.draw_circle(o + Vector2(30, -12) * s, 10.0 * s, BLACK)
			c.draw_circle(o + Vector2(30, -12) * s, 8.0 * s, DemiArt.BONE.darkened(0.3))
		"tiger_skull":
			_skull(c, o + Vector2(0, -36) * s, 36.0 * s, true)
		"skull_pole":
			c.draw_line(o, o + Vector2(0, -150) * s, BLACK, 8.0)
			c.draw_line(o, o + Vector2(0, -150) * s, Color(0.30, 0.22, 0.16), 4.0)
			_skull(c, o + Vector2(0, -162) * s, 14.0 * s, false)
		"hut":
			var hb := Rect2(o.x - 70 * s, o.y - 80 * s, 140 * s, 80 * s)
			c.draw_rect(hb, Color(0.18, 0.13, 0.10))
			var roof := PackedVector2Array([o + Vector2(-95, -74) * s, o + Vector2(0, -170) * s, o + Vector2(95, -74) * s])
			c.draw_colored_polygon(roof, Color(0.22, 0.17, 0.11))
			for i in 5:
				c.draw_line(o + Vector2(-80 + float(i) * 40, -78) * s, o + Vector2(0, -165) * s, Color(0.12, 0.09, 0.06), 2.0)
			c.draw_rect(Rect2(o.x - 18 * s, o.y - 54 * s, 36 * s, 54 * s), Color(0.03, 0.02, 0.02))
			c.draw_rect(hb, BLACK, false, 3.0)
			FighterArt.outline(c, roof, 3.0)
		"totem":
			var tw := 26.0 * s
			for i in 3:
				var tr := Rect2(o.x - tw, o.y - (float(i) + 1.0) * 64.0 * s, tw * 2.0, 62.0 * s)
				c.draw_rect(tr, [Color(0.30, 0.18, 0.12), Color(0.24, 0.14, 0.10), Color(0.34, 0.20, 0.12)][(i + v) % 3])
				c.draw_rect(tr, BLACK, false, 3.0)
				c.draw_circle(tr.position + Vector2(tw * 0.6, 20.0 * s), 5.0 * s, Color(0.75, 0.2, 0.1))
				c.draw_circle(tr.position + Vector2(tw * 1.4, 20.0 * s), 5.0 * s, Color(0.75, 0.2, 0.1))
				c.draw_line(tr.position + Vector2(tw * 0.5, 44.0 * s), tr.position + Vector2(tw * 1.5, 44.0 * s), BLACK, 4.0)
			var wing := PackedVector2Array([o + Vector2(-tw - 40, -190) * Vector2(1, s), o + Vector2(tw + 40, -190) * Vector2(1, s), o + Vector2(0, -175) * Vector2(1, s)])
			c.draw_colored_polygon(wing, Color(0.30, 0.18, 0.12))
		"campfire":
			for i in 3:
				c.draw_line(o + Vector2(-26 + float(i) * 18, 0), o + Vector2(-8 + float(i) * 8, -26), Color(0.2, 0.14, 0.1), 5.0)
			c.draw_circle(o + Vector2(0, -18), 16.0, Color(1.0, 0.45, 0.1, 0.5))
			c.draw_circle(o + Vector2(0, -16), 9.0, Color(1.0, 0.7, 0.2, 0.8))
		"rack":
			c.draw_line(o + Vector2(-50, 0), o + Vector2(-50, -110), BLACK, 6.0)
			c.draw_line(o + Vector2(50, 0), o + Vector2(50, -110), BLACK, 6.0)
			c.draw_line(o + Vector2(-60, -100), o + Vector2(60, -100), BLACK, 6.0)
			for i in 3:
				var hp := o + Vector2(-30 + float(i) * 30, -96)
				c.draw_colored_polygon(PackedVector2Array([hp + Vector2(-12, 0), hp + Vector2(12, 0), hp + Vector2(8, 40), hp + Vector2(-8, 40)]), DemiArt.HIDE.darkened(0.2))
		"pillar":
			var pr := Rect2(o.x - 30 * s, o.y - (200.0 + float(v) * 25.0) * s, 60 * s, (200.0 + float(v) * 25.0) * s)
			c.draw_rect(pr, Color(0.20, 0.19, 0.22))
			c.draw_rect(pr, BLACK, false, 3.0)
			if v % 2 == 0:                                        # Broken top
				c.draw_colored_polygon(PackedVector2Array([pr.position, pr.position + Vector2(pr.size.x, 18), pr.position + Vector2(pr.size.x * 0.4, -22)]), Color(0.20, 0.19, 0.22))
			c.draw_line(pr.position + Vector2(20 * s, 30), pr.position + Vector2(30 * s, 110), Color(0.45, 0.35, 0.6, 0.4), 2.0)
		"throne":
			var tb := Rect2(o.x - 60 * s, o.y - 70 * s, 120 * s, 70 * s)
			c.draw_rect(tb, Color(0.24, 0.18, 0.14))
			c.draw_rect(Rect2(o.x - 50 * s, o.y - 210 * s, 100 * s, 140 * s), Color(0.20, 0.14, 0.11))
			for i in 5:
				_skull(c, o + Vector2(-48 + float(i) * 24, -220) * s, 10.0 * s, false)
			c.draw_rect(tb, BLACK, false, 3.0)


## A dead tree: trunk + bare, crooked branches (silhouette).
static func _tree(c: CanvasItem, o: Vector2, h: float, col: Color, v: int, wmul: float = 1.0) -> void:
	var w := h * 0.06 * wmul
	var lean := float(v % 3 - 1) * h * 0.05
	var top := o + Vector2(lean, -h)
	var trunk := PackedVector2Array([o + Vector2(-w * 1.4, 0), o + Vector2(-w * 0.6, -h * 0.5), top + Vector2(-w * 0.3, 0), top + Vector2(w * 0.3, 0), o + Vector2(w * 0.6, -h * 0.5), o + Vector2(w * 1.5, 0)])
	c.draw_colored_polygon(trunk, col)
	FighterArt.outline(c, trunk, 3.0)
	var rng := RandomNumberGenerator.new()
	rng.seed = v * 31 + int(o.x)
	for i in 6:
		var k := 0.35 + 0.1 * float(i)
		var root := o.lerp(top, k)
		var side := -1.0 if i % 2 == 0 else 1.0
		var a := -PI * 0.5 + side * rng.randf_range(0.5, 1.1)
		var len := h * rng.randf_range(0.18, 0.32) * (1.2 - k * 0.6)
		var mid := root + Vector2.from_angle(a) * len * 0.6
		var tip := mid + Vector2.from_angle(a + side * 0.4) * len * 0.5
		c.draw_line(root, mid, BLACK, w * 0.9 + 3.0, true)
		c.draw_line(mid, tip, BLACK, w * 0.5 + 2.5, true)
		c.draw_line(root, mid, col, w * 0.9, true)
		c.draw_line(mid, tip, col, w * 0.5, true)
		c.draw_line(mid, mid + Vector2.from_angle(a - side * 0.7) * len * 0.3, col, w * 0.35, true)


## A skull (tiger = with fangs, bigger and longer).
static func _skull(c: CanvasItem, p: Vector2, r: float, tiger: bool) -> void:
	var sk := EnemyArt.ellipse_points(p, r * (1.3 if tiger else 1.0), r * 0.85, 16)
	c.draw_colored_polygon(sk, DemiArt.BONE.darkened(0.15))
	FighterArt.outline(c, sk, 3.0)
	c.draw_circle(p + Vector2(-r * 0.35, -r * 0.05), r * 0.25, BLACK)
	c.draw_circle(p + Vector2(r * 0.35, -r * 0.05), r * 0.25, BLACK)
	if tiger:
		for d: float in [-0.4, 0.4]:
			c.draw_colored_polygon(PackedVector2Array([p + Vector2(r * d - 4, r * 0.5), p + Vector2(r * d + 4, r * 0.5), p + Vector2(r * d, r * 1.2)]), DemiArt.BONE)


## One of the three ARTIFACTS ("crown" / "fang" / "heart") at p, size s (1 = ~40 px).
static func draw_artifact(c: CanvasItem, id: String, p: Vector2, s: float, t: float, glow: bool = true) -> void:
	var gcol: Color = {"crown": Color(1.0, 0.45, 0.2), "fang": Color(1.0, 0.8, 0.3), "heart": Color(0.5, 1.0, 0.4)}.get(id, Color.WHITE)
	if glow:
		c.draw_circle(p, 34.0 * s + 4.0 * sin(t * 3.0), Color(gcol.r, gcol.g, gcol.b, 0.18))
		c.draw_circle(p, 22.0 * s, Color(gcol.r, gcol.g, gcol.b, 0.22))
	match id:
		"crown":                                              # A crown of bones and black feathers
			var band := Rect2(p.x - 18 * s, p.y - 2 * s, 36 * s, 12 * s)
			c.draw_rect(band, DemiArt.BONE)
			c.draw_rect(band, BLACK, false, 2.5)
			for i in 5:
				var bx := p.x - 16 * s + float(i) * 8 * s
				c.draw_colored_polygon(PackedVector2Array([Vector2(bx - 4 * s, p.y - 2 * s), Vector2(bx + 4 * s, p.y - 2 * s), Vector2(bx, p.y - (16.0 + float(i % 2) * 8.0) * s)]), DemiArt.BONE)
			c.draw_circle(p + Vector2(0, 4 * s), 3.5 * s, Color(0.8, 0.15, 0.1))
		"fang":                                               # A huge curved tiger fang on a cord
			var f := PackedVector2Array([p + Vector2(-8, -18) * s, p + Vector2(8, -18) * s, p + Vector2(6, 2) * s, p + Vector2(-2, 22) * s, p + Vector2(-6, 0) * s])
			c.draw_colored_polygon(f, Color(0.95, 0.92, 0.82))
			FighterArt.outline(c, f, 2.5)
			c.draw_arc(p + Vector2(0, -22 * s), 10.0 * s, PI, TAU, 10, DemiArt.HIDE, 3.0)
		"heart":                                              # A beating heart of living wood
			var beat := 1.0 + 0.08 * sin(t * 6.0)
			var hp := PackedVector2Array()
			for i in 24:
				var a := TAU * float(i) / 24.0
				var hx := 16.0 * pow(sin(a), 3.0)
				var hy := -(13.0 * cos(a) - 5.0 * cos(2.0 * a) - 2.0 * cos(3.0 * a) - cos(4.0 * a))
				hp.append(p + Vector2(hx, hy) * s * beat)
			c.draw_colored_polygon(hp, Color(0.32, 0.22, 0.12))
			c.draw_line(p + Vector2(-4, -6) * s, p + Vector2(2, 8) * s, Color(0.5, 1.0, 0.4), 3.0)
			c.draw_line(p + Vector2(6, -8) * s, p + Vector2(0, 2) * s, Color(0.5, 1.0, 0.4), 2.0)
			FighterArt.outline(c, hp, 2.5)


# ============================================================
# WORLD NODES
# ============================================================
## A strip of scenery (one per ~1500 px, so off-screen strips are skipped by the renderer).
class PropStrip extends Node2D:
	var items: Array = []

	func _ready() -> void:
		z_index = -1

	func _draw() -> void:
		for p in items:
			DemiWorld.draw_prop(self, p)


## A CAMTON (checkpoint): an OLD ROCK PILLAR, cracked and carved, that makes FLAMES around
## itself once it is woken (lit). Asleep it is cold grey with a few embers deep in its cracks.
class CamTon extends Node2D:
	var lit := false
	var _t := 0.0
	var _wake := 0.0                                          # 0 -> 1 after it is lit (flames grow)

	func _ready() -> void:
		z_index = -1

	func _process(delta: float) -> void:
		_t += delta
		if lit:
			_wake = minf(_wake + delta * 0.8, 1.0)
		if OptimizationManager.on_screen(global_position, 320.0):
			queue_redraw()

	func _draw() -> void:
		var h := 250.0
		var stone := Color(0.24, 0.23, 0.26) if not lit else Color(0.30, 0.25, 0.23)
		if lit:                                               # Warm glow around it
			draw_circle(Vector2(0, -h * 0.5), 150.0 + 8.0 * sin(_t * 2.5), Color(1.0, 0.45, 0.15, 0.07 * _wake))
			draw_circle(Vector2(0, -h * 0.5), 90.0, Color(1.0, 0.55, 0.2, 0.08 * _wake))
		# Flames BEHIND the pillar (back half of their circle)
		if lit:
			_flames(false)
		# The pillar: a weathered, slightly leaning column of old rock with a broken top
		var p := PackedVector2Array([Vector2(-38, 4), Vector2(-34, -h * 0.45), Vector2(-30, -h * 0.85), Vector2(-22, -h),
			Vector2(-4, -h - 14.0), Vector2(10, -h + 6.0), Vector2(26, -h - 4.0), Vector2(30, -h * 0.8), Vector2(34, -h * 0.4), Vector2(40, 4)])
		draw_colored_polygon(p, stone)
		draw_colored_polygon(PackedVector2Array([Vector2(12, 4), Vector2(18, -h * 0.4), Vector2(16, -h * 0.85), Vector2(26, -h - 4.0),
			Vector2(30, -h * 0.8), Vector2(34, -h * 0.4), Vector2(40, 4)]), stone.darkened(0.25))          # Shaded side
		for i in 4:                                            # Strata bands
			var y := -h * (0.2 + 0.2 * float(i))
			draw_line(Vector2(-34, y), Vector2(36, y + 6.0), stone.darkened(0.35), 2.5)
		# Cracks: cold embers when asleep, glowing fire when lit
		var crack := Color(1.0, 0.55, 0.15, 0.35 + 0.6 * _wake) if lit else Color(1.0, 0.35, 0.1, 0.25 + 0.15 * sin(_t * 2.0))
		draw_polyline(PackedVector2Array([Vector2(-10, -20), Vector2(-4, -70), Vector2(-14, -110), Vector2(-6, -160)]), crack, 3.0)
		draw_polyline(PackedVector2Array([Vector2(14, -60), Vector2(8, -120), Vector2(18, -190)]), crack, 2.5)
		# An old carved glyph (a flame in a ring)
		var g := Vector2(0, -h * 0.62)
		draw_arc(g, 16.0, 0.0, TAU, 18, crack if lit else stone.lightened(0.15), 3.0)
		draw_colored_polygon(PackedVector2Array([g + Vector2(-6, 8), g + Vector2(6, 8), g + Vector2(0, -10)]), crack if lit else stone.lightened(0.15))
		FighterArt.outline(self, p, 3.5)
		# Rubble at its foot
		for d: float in [-52.0, 50.0]:
			var r := PackedVector2Array([Vector2(d - 14, 4), Vector2(d - 10, -12), Vector2(d + 8, -16), Vector2(d + 14, 4)])
			draw_colored_polygon(r, stone.darkened(0.2))
			FighterArt.outline(self, r, 2.5)
		# Flames IN FRONT of the pillar (front half of their circle)
		if lit:
			_flames(true)

	## Flames circling the pillar on a tilted ellipse, rising and falling (front or back half).
	func _flames(front: bool) -> void:
		var n := 7
		for i in n:
			var a := _t * 1.3 + TAU * float(i) / float(n)
			var is_front := sin(a) > 0.0
			if is_front != front:
				continue
			var y := -60.0 - 150.0 * (0.5 + 0.5 * sin(_t * 0.9 + float(i) * 1.7))
			var pos := Vector2(cos(a) * 62.0, y + sin(a) * 14.0)
			var s := (0.75 + 0.35 * sin(a)) * _wake                # Nearer = bigger
			var fl := 18.0 + 8.0 * sin(_t * 11.0 + float(i))
			var col := Color(1.0, 0.45, 0.1, 0.85) if is_front else Color(0.85, 0.32, 0.08, 0.55)
			draw_colored_polygon(PackedVector2Array([pos + Vector2(-8, 6) * s, pos + Vector2(8, 6) * s, pos + Vector2(sin(_t * 8.0 + float(i)) * 3.0, -fl) * s]), col)
			draw_circle(pos + Vector2(0, 2) * s, 6.0 * s, Color(1.0, 0.85, 0.4, 0.9 if is_front else 0.5))

## The ANCIENT DOOR: a giant stone door with three sockets. open_k 0..1 = the halves part.
class Door extends Node2D:
	var placed: Array = []                                    # Artifact ids put in, in order
	var open_k := 0.0
	var _t := 0.0

	func _ready() -> void:
		z_index = -1

	func _process(delta: float) -> void:
		_t += delta
		if OptimizationManager.on_screen(global_position, 500.0):
			queue_redraw()

	func _draw() -> void:
		var w := 360.0
		var h := 560.0
		var frame := Rect2(-w * 0.5 - 50, -h - 60, w + 100, h + 60)
		draw_rect(frame, Color(0.14, 0.13, 0.16))
		draw_rect(frame, BLACK, false, 5.0)
		for i in 7:                                           # Carved runes on the frame
			var ry := -h - 30.0 + float(i) * 80.0
			draw_arc(Vector2(-w * 0.5 - 25, ry + 20), 10.0, 0.0, TAU, 8, Color(0.5, 0.4, 0.7, 0.35 + 0.15 * float(placed.size())), 2.0)
			draw_arc(Vector2(w * 0.5 + 25, ry + 20), 10.0, 0.0, TAU, 8, Color(0.5, 0.4, 0.7, 0.35 + 0.15 * float(placed.size())), 2.0)
		# Behind the door: darkness, then a pale light as it opens
		draw_rect(Rect2(-w * 0.5, -h, w, h), Color(0.02, 0.02, 0.03))
		if open_k > 0.0:
			draw_rect(Rect2(-w * 0.5 * open_k, -h, w * open_k, h), Color(0.85, 0.85, 1.0, 0.25 + 0.6 * open_k))
		var slide := w * 0.5 * open_k
		for side: float in [-1.0, 1.0]:                       # The two stone halves
			var half := Rect2(-w * 0.5 if side < 0.0 else 0.0, -h, w * 0.5, h)
			half.position.x += side * slide
			half.size.x = maxf(w * 0.5 - slide * 0.0, 0.0)
			draw_rect(half, Color(0.22, 0.21, 0.24))
			draw_rect(half, BLACK, false, 4.0)
			draw_line(half.position + Vector2(half.size.x * 0.5, 30), half.position + Vector2(half.size.x * 0.5, h - 30), Color(0.15, 0.14, 0.16), 3.0)
		# The three sockets across the middle (they move with the halves)
		var ids := ["fang", "crown", "heart"]
		for i in 3:
			var sp := Vector2(-110.0 + float(i) * 110.0, -h * 0.55)
			sp.x += (-slide if sp.x < 0.0 else (slide if sp.x > 0.0 else 0.0))
			draw_circle(sp, 34.0, BLACK)
			draw_circle(sp, 30.0, Color(0.10, 0.09, 0.11))
			if placed.has(ids[i]):
				DemiWorld.draw_artifact(self, ids[i], sp, 0.9, _t)
		if placed.size() == 3 and open_k <= 0.0:
			draw_circle(Vector2(0, -h * 0.5), 200.0 + 10.0 * sin(_t * 4.0), Color(0.7, 0.6, 1.0, 0.10))


## A dropped ARTIFACT lying on the ground (bobbing, glowing). Touch it to take it.
class Pickup extends Node2D:
	var id := "crown"
	var _t := 0.0

	func _process(delta: float) -> void:
		_t += delta
		queue_redraw()

	func _draw() -> void:
		draw_line(Vector2(0, -20), Vector2(0, -360), Color(1, 1, 1, 0.08 + 0.04 * sin(_t * 2.0)), 26.0)
		DemiWorld.draw_artifact(self, id, Vector2(0, -60 + sin(_t * 2.5) * 8.0), 1.4, _t)


## A boss ARENA WALL: a wall of old rock with a curtain of FOG in front of it, closing a boss
## arena on one side (solid both ways until the boss is dead - nothing gets in, you can't leave).
class FogGate extends StaticBody2D:
	var side := 1.0                                           # -1 = left wall of the arena, 1 = right wall
	var _t := 0.0
	var _rise := 0.0                                          # The rock wall rises out of the ground

	func _ready() -> void:
		collision_layer = CombatManager.WORLD_LAYER
		collision_mask = 0
		var shape := RectangleShape2D.new()
		shape.size = Vector2(90, 2200)
		var col := CollisionShape2D.new()
		col.shape = shape
		col.position = Vector2(side * 30.0, -1000)
		add_child(col)
		z_index = 2
		SoundManager.play_sfx("rumble", -6.0)

	func _process(delta: float) -> void:
		_t += delta
		_rise = minf(_rise + delta * 1.6, 1.0)
		queue_redraw()

	func _draw() -> void:
		var h := 700.0 * _rise
		# The rock wall (outside the arena, behind the fog)
		var x0 := side * 20.0
		var x1 := side * 140.0
		var rock := PackedVector2Array([Vector2(x0, 6), Vector2(x0 + side * 8.0, -h * 0.4), Vector2(x0 - side * 6.0, -h * 0.75), Vector2(x0 + side * 10.0, -h),
			Vector2(x1, -h - 30.0), Vector2(x1 + side * 200.0, -h), Vector2(x1 + side * 200.0, 6)])
		draw_colored_polygon(rock, Color(0.15, 0.14, 0.16))
		for i in 6:
			var y := -h * (0.12 + 0.15 * float(i))
			draw_line(Vector2(x0 + side * 6.0, y), Vector2(x1 + side * 120.0, y - 10.0), Color(0.09, 0.08, 0.10), 3.0)
		FighterArt.outline(self, rock, 4.0)
		# The fog curtain in front (the arena side)
		for i in 16:
			var y2 := -float(i) * 46.0 - 20.0
			if -y2 > h + 60.0:
				break
			var x := sin(_t * 1.5 + float(i) * 0.9) * 16.0
			draw_circle(Vector2(x, y2), 50.0 + 8.0 * sin(_t * 2.0 + float(i)), Color(0.78, 0.78, 0.88, 0.20))
			draw_circle(Vector2(-x * 0.6 - side * 20.0, y2 - 22.0), 34.0, Color(0.92, 0.92, 1.0, 0.13))
		draw_line(Vector2(0, 0), Vector2(0, -h), Color(1.0, 1.0, 1.0, 0.10 + 0.05 * sin(_t * 3.0)), 6.0)