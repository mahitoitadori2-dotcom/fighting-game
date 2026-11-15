class_name OrdWorld
extends RefCounted
## TERRA ORDINARIORUM: the open world's LAYOUT and SCENERY (the regular land; lore by the user).
## Unlike DemiLand / Craterum you START ON THE FAR LEFT (the meadow), and explore to the right.
##
##   [SNOW DESERT] # MEADOW (start) | FOREST | TOWN | JUNGLE | DESERT | MOUNTAIN (climb)
##                 ^ the BASALT WALL (secret: the Lightning Candle blows it up)
##
##   * The MOUNTAIN is a climb: rock ledges you jump up, and low CRAWL tunnels (hold DOWN).
##     The LIGHTNING CANDLE waits on the summit.
##   * MAIN ROUTE: take the candle back to the TOWN SQUARE: the Storm opens -> the STORM FINGER.
##   * SECRET: take it back past the meadow to the Basalt Wall -> the SNOW DESERT -> the crystal.

const HALF := 10000.0
const FLOOR_Y := 525.0

const REGIONS := [
	{"key": "ord_snow", "name": "THE SNOW DESERT", "x0": -10000.0, "x1": -8200.0, "col": Color(0.70, 0.80, 0.92), "ground": 24},
	{"key": "ord_meadow", "name": "THE MEADOW", "x0": -8200.0, "x1": -5200.0, "col": Color(0.45, 0.70, 0.30), "ground": 19},
	{"key": "ord_forest", "name": "THE FOREST", "x0": -5200.0, "x1": -2400.0, "col": Color(0.22, 0.45, 0.20), "ground": 19},
	{"key": "ord_town", "name": "THE TOWN", "x0": -2400.0, "x1": 0.0, "col": Color(0.62, 0.50, 0.36), "ground": 11},
	{"key": "ord_jungle", "name": "THE JUNGLE", "x0": 0.0, "x1": 3000.0, "col": Color(0.15, 0.50, 0.25), "ground": 19},
	{"key": "ord_desert", "name": "THE DESERT", "x0": 3000.0, "x1": 6000.0, "col": Color(0.88, 0.72, 0.42), "ground": 26},
	{"key": "ord_mountain", "name": "THE MOUNTAIN", "x0": 6000.0, "x1": 10000.0, "col": Color(0.50, 0.50, 0.56), "ground": 23},
]
const START_X := -7850.0
const WALL_X := -8200.0                        # The Basalt Wall (left of the start)
const SQUARE_X := -1200.0                      # The Town Square: light the candle here
const CRYSTAL_X := -9150.0                     # The floating crystal (Snow Desert)
const CANDLE_X := 9650.0                       # On the summit
const BRIDGE_X := -560.0                       # Where the bridge from Orbis Terrarum touches down

const SHRINES := [
	{"x": -7600.0, "name": "CamTon of the Meadow"},
	{"x": -3800.0, "name": "CamTon of the Forest"},
	{"x": -2000.0, "name": "CamTon of the Town"},
	{"x": 1500.0, "name": "CamTon of the Jungle"},
	{"x": 4500.0, "name": "CamTon of the Desert"},
	{"x": 6250.0, "name": "CamTon of the Mountain"},
]
## Animals (never hostile): where they graze. They come back when you rest.
const HERDS := [
	{"x": -7200.0, "ids": ["rabbit", "rabbit", "sheep"]}, {"x": -6400.0, "ids": ["sheep", "cow", "sheep"]},
	{"x": -5700.0, "ids": ["rabbit", "cow"]},
	{"x": -4700.0, "ids": ["deer", "fox"]}, {"x": -3300.0, "ids": ["boar", "deer", "fox"]},
	{"x": -1600.0, "ids": ["chicken", "chicken", "dog"]}, {"x": -400.0, "ids": ["cat", "chicken"]},
	{"x": 700.0, "ids": ["monkey", "parrot", "frog"]}, {"x": 2300.0, "ids": ["monkey", "frog", "parrot"]},
	{"x": 3600.0, "ids": ["lizard", "scorpion"]}, {"x": 5200.0, "ids": ["fennec", "lizard", "scorpion"]},
	{"x": 6700.0, "ids": ["goat", "marmot"], "y": 90.0}, {"x": 8800.0, "ids": ["goat", "eagle"], "y": 360.0},
]
## The townsfolk (talk = DOWN). look = clothes; name shown on the dialogue box.
const TOWNSFOLK := [
	{"x": -2250.0, "look": 0, "id": "baker"}, {"x": -1850.0, "look": 1, "id": "washerwoman"},
	{"x": -1500.0, "look": 3, "id": "guard"}, {"x": -900.0, "look": 4, "id": "elder"},
	{"x": -650.0, "look": 2, "id": "farmer"}, {"x": -250.0, "look": 5, "id": "child"},
]
## The boss arena (the Town). Fog closes it when the Storm Finger comes down.
const BOSS := {"id": "storm_finger", "x": -1200.0, "half": 820.0, "music": "boss_storm_finger", "color": Color(0.6, 0.8, 1.0)}
const SECRET := {"id": "crystal_swarm", "x": -9150.0, "half": 760.0, "music": "story_snow", "color": Color(0.7, 0.9, 1.0)}
## (Same fields as DemiWorld / CraterWorld for the board + save code. No hostile camps here.)
const BOSSES := [BOSS]
const CAMPS := []

## THE MOUNTAIN: solid rock LEDGES [x0, x1, height above the floor] (each step <= 90 px: jumpable)
const LEDGES := [
	[6600.0, 7000.0, 90.0], [7000.0, 7400.0, 180.0], [7400.0, 8700.0, 270.0],
	[8700.0, 9050.0, 360.0], [9050.0, 9350.0, 450.0], [9350.0, 10000.0, 540.0],
]
## CRAWL tunnels [x0, x1, height of the floor there]: a low roof, hold DOWN to crawl through.
const CRAWLS := [[6280.0, 6520.0, 0.0], [7750.0, 8250.0, 270.0], [9420.0, 9560.0, 540.0]]
const CRAWL_GAP := 70.0

const BLACK := Color(0, 0, 0)


static func region_at(x: float) -> Dictionary:
	for r in REGIONS:
		if x >= float(r["x0"]) and x < float(r["x1"]):
			return r
	return REGIONS[0] if x < 0.0 else REGIONS[REGIONS.size() - 1]


## Height of the walkable ground at x (mountain ledges).
static func ledge_h(x: float) -> float:
	for l in LEDGES:
		if x >= float(l[0]) and x < float(l[1]):
			return float(l[2])
	return 0.0


# ============================================================
# SCENERY
# ============================================================
static var _props: Array = []


static func props() -> Array:
	if not _props.is_empty():
		return _props
	var rng := RandomNumberGenerator.new()
	rng.seed = 7171
	for r in REGIONS:
		var key := String(r["key"])
		var x := float(r["x0"]) + 120.0
		while x < float(r["x1"]) - 80.0:
			if not _blocked(x):
				_props.append({"kind": _pick(rng, key), "x": x, "s": rng.randf_range(0.8, 1.3), "v": rng.randi() % 7, "y": ledge_h(x)})
			x += rng.randf_range(150.0, 300.0) if key != "ord_town" else rng.randf_range(260.0, 360.0)
	_props.sort_custom(func(a: Dictionary, b: Dictionary) -> bool: return float(a["x"]) < float(b["x"]))
	return _props


static func _pick(rng: RandomNumberGenerator, key: String) -> String:
	var pool: Array
	match key:
		"ord_meadow":
			pool = ["flowers", "grass", "tree", "flowers", "fence", "grass"]
		"ord_forest":
			pool = ["pine", "oak", "pine", "mushroom", "log", "oak"]
		"ord_town":
			pool = ["house", "lamp", "house", "stall", "house", "barrel"]
		"ord_jungle":
			pool = ["palm", "fern", "palm", "vine_tree", "fern", "flowers"]
		"ord_desert":
			pool = ["cactus", "dune_rock", "cactus", "bones", "dune_rock"]
		"ord_mountain":
			pool = ["snow_pine", "boulder", "snow_pine", "boulder"]
		_:
			pool = ["snow_mound", "ice_spike", "snow_mound", "ice_spike"]
	return String(pool[rng.randi() % pool.size()])


static func _blocked(x: float) -> bool:
	for s in SHRINES:
		if absf(x - float(s["x"])) < 160.0:
			return true
	for sx: float in [SQUARE_X, CRYSTAL_X, WALL_X, CANDLE_X, BRIDGE_X]:
		if absf(x - sx) < 200.0:
			return true
	for c in CRAWLS:
		if x > float(c[0]) - 60.0 and x < float(c[1]) + 60.0:
			return true
	for l in LEDGES:                                              # Not right on a ledge's edge
		if absf(x - float(l[0])) < 70.0:
			return true
	return false


static func draw_prop(c: CanvasItem, p: Dictionary) -> void:
	var s: float = p["s"]
	var v: int = p["v"]
	var o := Vector2(float(p["x"]), FLOOR_Y + 4.0 - float(p.get("y", 0.0)))
	match String(p["kind"]):
		"flowers":
			for i in 5:
				var fx := o.x + (float(i) - 2.0) * 14.0 * s
				c.draw_line(Vector2(fx, o.y), Vector2(fx + 2, o.y - 22 * s), Color(0.25, 0.55, 0.2), 2.0)
				c.draw_circle(Vector2(fx + 2, o.y - 24 * s), 5.0 * s, [Color(1.0, 0.85, 0.2), Color(0.95, 0.4, 0.5), Color(0.6, 0.5, 1.0), Color(1, 1, 1)][(v + i) % 4])
		"grass":
			for i in 7:
				var gx := o.x + (float(i) - 3.0) * 7.0 * s
				c.draw_line(Vector2(gx, o.y), Vector2(gx + float(i % 3 - 1) * 6.0, o.y - (16.0 + float((v + i) % 3) * 6.0) * s), Color(0.30, 0.62, 0.22), 3.0)
		"tree", "oak":
			var big := 1.3 if String(p["kind"]) == "oak" else 1.0
			c.draw_line(o, o + Vector2(0, -120) * s * big, BLACK, 18.0 * s)
			c.draw_line(o, o + Vector2(0, -120) * s * big, Color(0.42, 0.28, 0.16), 12.0 * s)
			var leaf := Color(0.30, 0.58, 0.22) if String(p["kind"]) == "tree" else Color(0.20, 0.42, 0.16)
			for k: Vector2 in [Vector2(-34, -130), Vector2(30, -134), Vector2(0, -170), Vector2(-14, -150), Vector2(20, -160)]:
				FighterArt.ball(c, o + k * s * big, 34.0 * s * big, leaf, leaf.darkened(0.3), leaf.lightened(0.2))
		"pine", "snow_pine":
			c.draw_line(o, o + Vector2(0, -40) * s, Color(0.35, 0.22, 0.12), 10.0 * s)
			var green := Color(0.13, 0.33, 0.20)
			for k in 3:
				var w := (60.0 - float(k) * 14.0) * s
				var y0 := o.y - (30.0 + float(k) * 50.0) * s
				var tri := PackedVector2Array([Vector2(o.x - w, y0), Vector2(o.x, y0 - 80.0 * s), Vector2(o.x + w, y0)])
				c.draw_colored_polygon(tri, green)
				if String(p["kind"]) == "snow_pine":
					c.draw_colored_polygon(PackedVector2Array([Vector2(o.x - w * 0.45, y0 - 44.0 * s), Vector2(o.x, y0 - 80.0 * s), Vector2(o.x + w * 0.45, y0 - 44.0 * s)]), Color(0.95, 0.97, 1.0))
				FighterArt.outline(c, tri, 2.5)
		"mushroom":
			c.draw_rect(Rect2(o.x - 5 * s, o.y - 24 * s, 10 * s, 24 * s), Color(0.95, 0.92, 0.85))
			var cap := EnemyArt.ellipse_points(o + Vector2(0, -26) * s, 20.0 * s, 12.0 * s, 12)
			c.draw_colored_polygon(cap, Color(0.85, 0.2, 0.15))
			for d: Vector2 in [Vector2(-8, -30), Vector2(6, -32), Vector2(0, -24)]:
				c.draw_circle(o + d * s, 3.0 * s, Color(1, 1, 1))
			FighterArt.outline(c, cap, 2.0)
		"log":
			var lg := Rect2(o.x - 50 * s, o.y - 24 * s, 100 * s, 24 * s)
			FighterArt.rrect(c, lg, Color(0.42, 0.28, 0.16), Color(0.28, 0.18, 0.1), Color(0.55, 0.38, 0.22), 10.0, 2.5)
			c.draw_circle(Vector2(lg.end.x - 4, o.y - 12 * s), 10.0 * s, Color(0.75, 0.6, 0.4))
		"fence":
			for i in 4:
				c.draw_rect(Rect2(o.x - 60 * s + float(i) * 40 * s, o.y - 46 * s, 8 * s, 46 * s), Color(0.6, 0.45, 0.28))
			for yy: float in [-36.0, -18.0]:
				c.draw_rect(Rect2(o.x - 64 * s, o.y + yy * s, 136 * s, 6 * s), Color(0.55, 0.40, 0.25))
		"house":
			var hw := 150.0 * s
			var hh := 130.0 * s
			var wallc: Color = [Color(0.85, 0.78, 0.65), Color(0.78, 0.62, 0.48), Color(0.70, 0.72, 0.75)][v % 3]
			var wall := Rect2(o.x - hw * 0.5, o.y - hh, hw, hh)
			FighterArt.rrect(c, wall, wallc, wallc.darkened(0.2), wallc.lightened(0.1), 3.0, 3.0)
			var roof := PackedVector2Array([Vector2(wall.position.x - 16, wall.position.y), Vector2(o.x, wall.position.y - 70 * s), Vector2(wall.end.x + 16, wall.position.y)])
			c.draw_colored_polygon(roof, [Color(0.65, 0.22, 0.15), Color(0.32, 0.30, 0.36), Color(0.45, 0.30, 0.18)][v % 3])
			FighterArt.outline(c, roof, 3.0)
			c.draw_rect(Rect2(o.x - 16 * s, o.y - 56 * s, 32 * s, 56 * s), Color(0.38, 0.24, 0.14))
			for d: float in [-1.0, 1.0]:
				var win := Rect2(o.x + d * 46 * s - 14 * s, o.y - 100 * s, 28 * s, 26 * s)
				c.draw_rect(win, Color(1.0, 0.86, 0.5))
				c.draw_rect(win, BLACK, false, 2.0)
		"lamp":
			c.draw_line(o, o + Vector2(0, -150) * s, Color(0.15, 0.15, 0.17), 5.0)
			c.draw_rect(Rect2(o.x - 9 * s, o.y - 172 * s, 18 * s, 22 * s), Color(1.0, 0.9, 0.55))
			c.draw_circle(o + Vector2(0, -160) * s, 30.0 * s, Color(1.0, 0.9, 0.5, 0.12))
		"stall":
			c.draw_rect(Rect2(o.x - 60 * s, o.y - 50 * s, 120 * s, 50 * s), Color(0.55, 0.38, 0.22))
			for i in 6:
				c.draw_rect(Rect2(o.x - 66 * s + float(i) * 22 * s, o.y - 110 * s, 22 * s, 24 * s), Color(0.9, 0.25, 0.2) if i % 2 == 0 else Color(0.97, 0.95, 0.9))
			for d: float in [-56.0, 52.0]:
				c.draw_line(o + Vector2(d, 0) * s, o + Vector2(d, -88) * s, Color(0.35, 0.24, 0.14), 4.0)
			for i in 4:
				c.draw_circle(o + Vector2(-36 + float(i) * 22, -56) * s, 8.0 * s, [Color(0.9, 0.3, 0.2), Color(1.0, 0.8, 0.2), Color(0.4, 0.75, 0.25)][i % 3])
		"barrel":
			FighterArt.rrect(c, Rect2(o.x - 18 * s, o.y - 46 * s, 36 * s, 46 * s), Color(0.55, 0.36, 0.2), Color(0.38, 0.24, 0.12), Color(0.68, 0.48, 0.28), 6.0, 2.5)
		"palm":
			var top := o + Vector2(20, -200) * s
			c.draw_polyline(PackedVector2Array([o, o + Vector2(12, -100) * s, top]), BLACK, 16.0 * s)
			c.draw_polyline(PackedVector2Array([o, o + Vector2(12, -100) * s, top]), Color(0.55, 0.40, 0.24), 11.0 * s)
			for k in 6:
				var a := -PI * 0.5 + (float(k) - 2.5) * 0.55
				var tip := top + Vector2(cos(a), sin(a) + 0.9) * 80.0 * s
				c.draw_polyline(PackedVector2Array([top, top + (tip - top) * 0.5 + Vector2(0, -16) * s, tip]), Color(0.18, 0.55, 0.22), 10.0 * s)
		"fern":
			for k in 5:
				var a := -PI * 0.5 + (float(k) - 2.0) * 0.45
				c.draw_line(o, o + Vector2(cos(a), sin(a)) * 60.0 * s, Color(0.15, 0.48, 0.20), 7.0 * s)
		"vine_tree":
			c.draw_line(o, o + Vector2(0, -230) * s, Color(0.30, 0.22, 0.14), 24.0 * s)
			FighterArt.ball(c, o + Vector2(0, -240) * s, 70.0 * s, Color(0.12, 0.40, 0.18), Color(0.06, 0.25, 0.1), Color(0.25, 0.6, 0.3))
			for k in 3:
				var vx := o.x + (float(k) - 1.0) * 40.0 * s
				c.draw_line(Vector2(vx, o.y - 220 * s), Vector2(vx + 6, o.y - 80 * s), Color(0.2, 0.5, 0.2), 3.0)
		"cactus":
			var cc := Color(0.30, 0.55, 0.30)
			FighterArt.rrect(c, Rect2(o.x - 12 * s, o.y - 110 * s, 24 * s, 110 * s), cc, cc.darkened(0.3), cc.lightened(0.2), 12.0, 2.5)
			FighterArt.rrect(c, Rect2(o.x + 12 * s, o.y - 70 * s, 26 * s, 12 * s), cc, cc.darkened(0.3), cc.lightened(0.2), 6.0, 2.0)
			FighterArt.rrect(c, Rect2(o.x + 28 * s, o.y - 92 * s, 12 * s, 34 * s), cc, cc.darkened(0.3), cc.lightened(0.2), 6.0, 2.0)
		"dune_rock", "boulder":
			var rp := PackedVector2Array()
			for i in 7:
				var a := PI + PI * float(i) / 6.0
				rp.append(o + Vector2(cos(a) * 50.0, sin(a) * (30.0 + float((v + i) % 3) * 8.0)) * s)
			c.draw_colored_polygon(rp, Color(0.72, 0.56, 0.36) if String(p["kind"]) == "dune_rock" else Color(0.48, 0.48, 0.52))
			FighterArt.outline(c, rp, 2.5)
		"bones":
			c.draw_arc(o + Vector2(0, -10) * s, 26.0 * s, PI, TAU, 10, Color(0.95, 0.92, 0.85), 6.0 * s)
			c.draw_circle(o + Vector2(30, -8) * s, 10.0 * s, Color(0.95, 0.92, 0.85))
		"snow_mound":
			c.draw_colored_polygon(EnemyArt.ellipse_points(o + Vector2(0, 0), 80.0 * s, 30.0 * s, 16), Color(0.94, 0.97, 1.0))
		"ice_spike":
			var sp := PackedVector2Array([o + Vector2(-16, 0) * s, o + Vector2(0, -120 - float(v) * 10.0) * s, o + Vector2(16, 0) * s])
			c.draw_colored_polygon(sp, Color(0.70, 0.88, 1.0, 0.9))
			FighterArt.outline(c, sp, 2.0)


# ============================================================
# WORLD NODES
# ============================================================
class PropStrip extends Node2D:
	var items: Array = []

	func _ready() -> void:
		z_index = -1

	func _draw() -> void:
		for p in items:
			OrdWorld.draw_prop(self, p)


## A solid rock LEDGE of the mountain (you land on top of it).
class Ledge extends StaticBody2D:
	var w := 400.0
	var h := 90.0

	func _ready() -> void:
		collision_layer = CombatManager.WORLD_LAYER
		collision_mask = 0
		var shape := RectangleShape2D.new()
		shape.size = Vector2(w, h)
		var col := CollisionShape2D.new()
		col.shape = shape
		col.position = Vector2(w * 0.5, -h * 0.5)
		add_child(col)
		z_index = -1

	func _draw() -> void:
		var r := Rect2(0, -h, w, h + 6.0)
		draw_rect(r, Color(0.36, 0.36, 0.40))
		draw_rect(Rect2(0, -h, w, 14.0), Color(0.94, 0.96, 1.0))                     # Snow on top
		for i in int(w / 60.0):
			var x := 20.0 + float(i) * 60.0
			draw_line(Vector2(x, -h + 30.0), Vector2(x + 18.0, -h + 60.0 + float(i % 3) * 10.0), Color(0.26, 0.26, 0.30), 3.0)
		draw_rect(r, BLACK, false, 3.0)


## A CRAWL tunnel: a low slab of rock. Not solid (OrdLand pushes you back if you stand up).
class Crawl extends Node2D:
	var w := 300.0
	var _t := 0.0

	func _ready() -> void:
		z_index = 2

	func _process(delta: float) -> void:
		_t += delta
		if OptimizationManager.on_screen(global_position, 400.0):
			queue_redraw()

	func _draw() -> void:
		var slab := Rect2(-10, -CRAWL_GAP - 900.0, w + 20.0, 900.0)              # An overhang of the cliff
		draw_rect(slab, Color(0.30, 0.30, 0.34))
		for i in int(w / 30.0):
			var x := float(i) * 30.0 + 10.0
			draw_colored_polygon(PackedVector2Array([Vector2(x - 8, -CRAWL_GAP - 1), Vector2(x + 8, -CRAWL_GAP - 1), Vector2(x, -CRAWL_GAP + 10)]), Color(0.30, 0.30, 0.34))
		draw_rect(slab, BLACK, false, 3.0)
		draw_line(Vector2(-10, -CRAWL_GAP), Vector2(w + 10, -CRAWL_GAP), Color(0.8, 0.9, 1.0, 0.35 + 0.2 * sin(_t * 4.0)), 2.0)


## A pedestal (summit: the Lightning Candle; town square: the well where you light it).
class Pedestal extends Node2D:
	var has_candle := true
	var _t := 0.0

	func _process(delta: float) -> void:
		_t += delta
		if OptimizationManager.on_screen(global_position, 300.0):
			queue_redraw()

	func _draw() -> void:
		var r := Rect2(-30, -60, 60, 60)
		FighterArt.rrect(self, r, Color(0.55, 0.55, 0.6), Color(0.35, 0.35, 0.4), Color(0.75, 0.75, 0.8), 4.0, 3.0)
		if has_candle:
			draw_line(Vector2(0, -60), Vector2(0, -420), Color(0.6, 0.85, 1.0, 0.10 + 0.05 * sin(_t * 3.0)), 30.0)
			OrdArt.candle(self, Vector2(0, -64 + sin(_t * 2.0) * 3.0), 1.4, _t)


## The TOWN SQUARE well (light the candle here).
class Well extends Node2D:
	var _t := 0.0
	var ready_glow := false

	func _process(delta: float) -> void:
		_t += delta
		if OptimizationManager.on_screen(global_position, 300.0):
			queue_redraw()

	func _draw() -> void:
		var base := Rect2(-70, -60, 140, 60)
		FighterArt.rrect(self, base, Color(0.62, 0.60, 0.56), Color(0.44, 0.42, 0.38), Color(0.78, 0.76, 0.72), 6.0, 3.0)
		for d: float in [-1.0, 1.0]:
			draw_line(Vector2(d * 60, -60), Vector2(d * 60, -150), Color(0.4, 0.28, 0.16), 7.0)
		var roof := PackedVector2Array([Vector2(-84, -150), Vector2(0, -200), Vector2(84, -150)])
		draw_colored_polygon(roof, Color(0.6, 0.22, 0.16))
		FighterArt.outline(self, roof, 3.0)
		if ready_glow:
			draw_circle(Vector2(0, -90), 80.0 + 6.0 * sin(_t * 4.0), Color(0.6, 0.85, 1.0, 0.15))


## The floating CRYSTAL of the Snow Desert (before the fight starts).
class Crystal extends Node2D:
	var _t := 0.0

	func _process(delta: float) -> void:
		_t += delta
		if OptimizationManager.on_screen(global_position, 400.0):
			queue_redraw()

	func _draw() -> void:
		OrdArt.crystal_swarm(self, {"t": _t, "shards": 10})


## Frozen creatures of Craterum in the Snow Desert.
class Frozen extends Node2D:
	var kind := "kharleming"

	func _ready() -> void:
		z_index = -1

	func _draw() -> void:
		OrdArt.frozen(self, kind, 0.0)


## A TOWNSPERSON standing in the street (DOWN near one = talk).
class Villager extends Node2D:
	var look := 0
	var fled := false
	var _t := 0.0

	func _ready() -> void:
		_t = float(look) * 1.3

	func _process(delta: float) -> void:
		_t += delta
		if OptimizationManager.on_screen(global_position, 200.0):
			queue_redraw()

	func _draw() -> void:
		if not fled:
			OrdArt.villager(self, look, _t)


## The STORM over the town: a ring of dark cloud; `open` 0..1 tears a hole in it (Orbis Terrarum
## glowing behind). Lives in the world above the Town Square.
class StormSky extends Node2D:
	var open := 0.0
	var hand := 0.0                                  # 0..1: the Storm's hand reaching down
	var bridge := 0.0                                # 0..1: the bridge from Orbis Terrarum lowering
	var _t := 0.0

	func _ready() -> void:
		z_index = -2

	func _process(delta: float) -> void:
		_t += delta
		if open > 0.0 or bridge > 0.0:
			queue_redraw()

	func _draw() -> void:
		if open <= 0.0 and bridge <= 0.0:
			return
		var c := Vector2(0, -950)
		# The hole: light of Orbis Terrarum
		draw_circle(c, 520.0 * open, Color(0.95, 0.92, 0.75, 0.25 * open))
		draw_circle(c, 300.0 * open, Color(1.0, 0.98, 0.85, 0.55 * open))
		for k in (3 if open > 0.05 else 0):            # A green island far away inside
			draw_colored_polygon(EnemyArt.ellipse_points(c + Vector2(-60 + float(k) * 60.0, 40.0), 50.0 * open, 16.0 * open, 12), Color(0.35, 0.6, 0.35, 0.6 * open))
		# The storm wall around the hole
		for i in 24:
			var a := TAU * float(i) / 24.0 + _t * 0.15
			var rr := 520.0 * maxf(open, 0.3) + 60.0 * sin(float(i) * 2.3 + _t)
			draw_circle(c + Vector2(cos(a) * rr, sin(a) * rr * 0.5), 140.0, Color(0.14, 0.15, 0.22, 0.85))
		for k in 4:
			var a2 := _t * 2.0 + float(k) * 1.6
			var p := c + Vector2(cos(a2) * 600.0, sin(a2) * 280.0)
			if fmod(_t * 3.0 + float(k), 2.0) < 0.15:
				draw_polyline(PackedVector2Array([p, p + Vector2(30, 80), p + Vector2(-10, 150), p + Vector2(20, 240)]), Color(0.8, 0.9, 1.0, 0.9), 4.0)
		# The Storm's HAND reaching down out of the hole (cutscene)
		if hand > 0.0:
			var tip := c + Vector2(0, 260.0 + 680.0 * hand)
			draw_line(c + Vector2(0, 200), tip, OrdArt.BLACK, 190.0)
			draw_line(c + Vector2(0, 200), tip, OrdArt.STORM, 170.0)
			for f in 5:
				var fx := tip.x + (float(f) - 2.0) * 40.0
				draw_line(Vector2(fx, tip.y), Vector2(fx + (float(f) - 2.0) * 10.0, tip.y + 120.0 + float(2 - absi(f - 2)) * 30.0), OrdArt.STORM_HI, 30.0)
		# The BRIDGE of light lowering from Orbis Terrarum to the ground
		if bridge > 0.0:
			var top := c + Vector2(80, 120)
			var foot := Vector2(BRIDGE_X - OrdWorld.SQUARE_X, 0)
			var end := top.lerp(foot, bridge)
			draw_line(top, end, Color(1.0, 0.95, 0.75, 0.35), 70.0)
			draw_line(top, end, Color(1.0, 0.98, 0.9, 0.9), 26.0)
			var n := int(18.0 * bridge)
			for i in n:
				var q := top.lerp(end, float(i) / maxf(float(n), 1.0))
				draw_line(q + Vector2(-20, -6), q + Vector2(20, 6), Color(0.85, 0.75, 0.45), 4.0)
