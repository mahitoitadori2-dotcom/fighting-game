class_name CraterWorld
extends RefCounted
## TERRA CRATERUM: the open world's LAYOUT (one long strip, x = -HALF .. +HALF, the floor at
## y = 525) and its SCENERY. The game spawns from it and the MAP draws from it (always accurate).
##
##   WEST  <-  KHARLEMING WRECK | CRATER FLOOR (start) | MAGMA FIELDS | WAR FRONT -> BASALT WALL  ->  EAST
##
## The Lava Melter guards the War Front; when it dies the MAGMA BARRIER behind it drains and the
## BASALT WALL can be reached. The Kharleming Lord (in the wreck) drops the TECHNICIAN'S BREAKER.
## Pile Kharleming corpses at the wall, use the Breaker: the wall blows up = the way on.

const HALF := 8000.0
const FLOOR_Y := 525.0

const REGIONS := [
	{"key": "crater_wreck", "name": "THE KHARLEMING WRECK", "x0": -8000.0, "x1": -3000.0, "col": Color(0.30, 0.31, 0.36)},
	{"key": "crater_floor", "name": "THE CRATER FLOOR", "x0": -3000.0, "x1": 1000.0, "col": Color(0.32, 0.17, 0.11)},
	{"key": "crater_fields", "name": "THE MAGMA FIELDS", "x0": 1000.0, "x1": 4800.0, "col": Color(0.46, 0.16, 0.06)},
	{"key": "crater_front", "name": "THE WAR FRONT", "x0": 4800.0, "x1": 8000.0, "col": Color(0.38, 0.22, 0.16)},
]
## CAMTONS (same old rock pillars as in DemiLand): rest = full HP + flasks, creatures come back.
const SHRINES := [
	{"x": -600.0, "name": "CamTon of the Crater"},
	{"x": -3600.0, "name": "CamTon of the Wreck"},
	{"x": 1700.0, "name": "CamTon of the Fields"},
	{"x": 5000.0, "name": "CamTon of the Front"},
]
## Enemy camps ("night" = one more joins at night). Kharleming kinds leave corpses you can drag.
const CAMPS := [
	{"x": -1700.0, "ids": ["lava_goblin", "kharleming", "kharleming"], "night": "lava_goblin"},
	{"x": 350.0, "ids": ["fragmenter", "lava_goblin"], "night": "fragmenter"},
	{"x": -3200.0, "ids": ["full_kharleming", "kharleming", "kharleming"], "night": "master_kharleming"},
	{"x": -5000.0, "ids": ["master_kharleming", "full_kharleming"], "night": "full_kharleming"},
	{"x": -5700.0, "ids": ["fragmenter", "full_kharleming", "kharleming"], "night": "fragmenter"},
	{"x": 2300.0, "ids": ["lava_golem", "lava_goblin"], "night": "lava_demon"},
	{"x": 3700.0, "ids": ["lava_demon", "lava_demon", "lava_goblin"], "night": "lava_golem"},
	{"x": 5550.0, "ids": ["lava_demon", "full_kharleming", "lava_goblin"], "night": "master_kharleming"},
	{"x": 7350.0, "ids": ["full_kharleming", "master_kharleming", "kharleming"], "night": "full_kharleming"},
]
## The two bosses. Their arena closes with walls of fog when the fight starts.
const BOSSES := [
	{"id": "kharleming_lord", "x": -6950.0, "half": 800.0, "region": "crater_wreck",
		"music": "boss_kharleming_lord", "color": Color(0.55, 0.85, 1.0), "sub": "Lord of the Ancient Ship", "line": "*CLICK. CLICK. CLICK.*", "entrance": "drop"},
	{"id": "lava_melter", "x": 6350.0, "half": 700.0, "region": "crater_front",
		"music": "boss_melter", "color": Color(1.0, 0.5, 0.15), "sub": "The Pillar of the Crater", "line": "*two eyes of rock open in the lava*", "entrance": "rise"},
]
const MAGMA_GATE_X := 7130.0                  # Behind the Melter: drains when it dies
const WALL_X := 7700.0                        # The BASALT WALL (the way on)
const REACTOR_X := -4300.0                    # Kharleming Sacrifice (on top of the energy reactor)
const MINE_X := 2950.0                        # The Volcano Slave (mining a mountain)
const KHARLEMING_IDS := ["kharleming", "full_kharleming", "master_kharleming"]

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
# SCENERY
# ============================================================
static var _props: Array = []


static func props() -> Array:
	if not _props.is_empty():
		return _props
	var rng := RandomNumberGenerator.new()
	rng.seed = 6767
	for r in REGIONS:
		var key := String(r["key"])
		var x := float(r["x0"]) + 140.0
		while x < float(r["x1"]) - 80.0:
			var kind := _pick(rng, key)
			if not _blocked(x):
				_props.append({"kind": kind, "x": x, "s": rng.randf_range(0.75, 1.3), "v": rng.randi() % 7})
			x += rng.randf_range(180.0, 340.0)
	for d: float in [-650.0, 640.0]:                               # The wreck arena: giant hull ribs
		_props.append({"kind": "hull_rib", "x": float(BOSSES[0]["x"]) + d, "s": 1.5, "v": 1})
	for d: float in [-560.0, 560.0]:                               # The Melter's arena: basalt columns
		_props.append({"kind": "basalt", "x": float(BOSSES[1]["x"]) + d, "s": 1.6, "v": 3})
	_props.sort_custom(func(a: Dictionary, b2: Dictionary) -> bool: return float(a["x"]) < float(b2["x"]))
	return _props


static func _pick(rng: RandomNumberGenerator, key: String) -> String:
	var pool: Array
	match key:
		"crater_wreck":
			pool = ["wreck_plate", "wreck_pipe", "nest", "wreck_plate", "rock", "hull_rib"]
		"crater_fields":
			pool = ["vent", "basalt", "obsidian", "vent", "rock", "volcano"]
		"crater_front":
			pool = ["banner", "wreck_plate", "vent", "basalt", "obsidian", "rock"]
		_:
			pool = ["rock", "obsidian", "vent", "basalt", "wreck_plate", "volcano"]
	return String(pool[rng.randi() % pool.size()])


static func _blocked(x: float) -> bool:
	for s in SHRINES:
		if absf(x - float(s["x"])) < 170.0:
			return true
	for b in BOSSES:
		if absf(x - float(b["x"])) < float(b["half"]) - 160.0:
			return true
	for sx: float in [REACTOR_X, MINE_X, MAGMA_GATE_X, WALL_X]:
		if absf(x - sx) < 260.0:
			return true
	return x > WALL_X - 120.0


static func draw_prop(c: CanvasItem, p: Dictionary) -> void:
	var s: float = p["s"]
	var v: int = p["v"]
	var o := Vector2(float(p["x"]), FLOOR_Y + 4.0)
	match String(p["kind"]):
		"rock":
			var rp := PackedVector2Array()
			for i in 7:
				var a := PI + PI * float(i) / 6.0
				rp.append(o + Vector2(cos(a) * 60.0, sin(a) * (34.0 + float((v + i) % 3) * 10.0)) * s)
			c.draw_colored_polygon(rp, CraterArt.BASALT)
			FighterArt.outline(c, rp, 3.0)
		"obsidian":                                                # Shards of black glass
			for i in 3:
				var bx := o.x + (float(i) - 1.0) * 26.0 * s
				var tip := Vector2(bx + float(i - 1) * 10.0, o.y - (90.0 + float((v + i) % 3) * 40.0) * s)
				var shard := PackedVector2Array([Vector2(bx - 14 * s, o.y), tip, Vector2(bx + 14 * s, o.y)])
				c.draw_colored_polygon(shard, Color(0.06, 0.05, 0.08))
				c.draw_line(Vector2(bx - 4 * s, o.y - 10), tip + Vector2(-2, 12), Color(0.4, 0.3, 0.5, 0.6), 2.0)
				FighterArt.outline(c, shard, 2.5)
		"basalt":                                                  # Hexagonal basalt columns
			for i in 4:
				var bh := (140.0 + float((v + i * 3) % 5) * 40.0) * s
				var bx2 := o.x + (float(i) - 1.5) * 34.0 * s
				var col := Rect2(bx2 - 16 * s, o.y - bh, 32 * s, bh)
				c.draw_rect(col, CraterArt.BASALT.lightened(0.04 * float(i % 2)))
				c.draw_rect(col, BLACK, false, 3.0)
				c.draw_line(col.position + Vector2(6, 10), col.position + Vector2(6, bh - 10), CraterArt.BASALT_HI, 2.0)
		"vent":                                                    # A glowing fissure in the floor
			c.draw_circle(o + Vector2(0, -6), 60.0 * s, Color(1.0, 0.4, 0.1, 0.10))
			c.draw_polyline(PackedVector2Array([o + Vector2(-60, -2) * s, o + Vector2(-20, -6) * s, o + Vector2(10, -1) * s, o + Vector2(60, -5) * s]), CraterArt.LAVA, 6.0)
			c.draw_polyline(PackedVector2Array([o + Vector2(-60, -2) * s, o + Vector2(-20, -6) * s, o + Vector2(10, -1) * s, o + Vector2(60, -5) * s]), CraterArt.LAVA_HOT, 2.0)
			for k in 3:                                            # Smoke
				c.draw_circle(o + Vector2(float(k) * 8.0, -40.0 - float(k) * 40.0) * s, (14.0 + float(k) * 8.0) * s, Color(0.2, 0.18, 0.18, 0.18))
		"volcano":                                                 # A small volcano cone, glowing top
			var cone := PackedVector2Array([o + Vector2(-220, 0) * s, o + Vector2(-50, -300) * s, o + Vector2(50, -300) * s, o + Vector2(220, 0) * s])
			c.draw_colored_polygon(cone, Color(0.12, 0.09, 0.09))
			c.draw_polyline(PackedVector2Array([o + Vector2(-20, -296) * s, o + Vector2(-40, -200) * s, o + Vector2(-20, -110) * s]), CraterArt.LAVA, 4.0)
			c.draw_circle(o + Vector2(0, -300) * s, 60.0 * s, Color(1.0, 0.4, 0.1, 0.12))
			FighterArt.outline(c, cone, 3.5)
		"wreck_plate":                                             # Hull plating of the ship
			var pl := PackedVector2Array([o + Vector2(-70, 0) * s, o + Vector2(-50, -150) * s, o + Vector2(40, -170) * s, o + Vector2(80, 0) * s])
			c.draw_colored_polygon(pl, CraterArt.METAL_SHADE.darkened(0.3))
			for k in 4:
				c.draw_circle(o + Vector2(-40 + float(k) * 26.0, -120) * s, 3.0 * s, CraterArt.METAL)
			c.draw_line(o + Vector2(-46, -80) * s, o + Vector2(70, -90) * s, CraterArt.RUST.darkened(0.3), 4.0)
			FighterArt.outline(c, pl, 3.0)
		"wreck_pipe":
			c.draw_line(o + Vector2(-90, -30) * s, o + Vector2(80, -140) * s, BLACK, 26.0 * s)
			c.draw_line(o + Vector2(-90, -30) * s, o + Vector2(80, -140) * s, CraterArt.METAL_SHADE, 18.0 * s)
			c.draw_circle(o + Vector2(80, -140) * s, 14.0 * s, BLACK)
			c.draw_circle(o + Vector2(80, -140) * s, 9.0 * s, Color(0.35, 0.95, 1.0, 0.5))
		"hull_rib":                                                # A giant curved rib of the ship's hull
			var rib := PackedVector2Array()
			for i in 9:
				var k := float(i) / 8.0
				rib.append(o + Vector2(sin(k * PI * 0.9) * 140.0, -k * 520.0) * s)
			c.draw_polyline(rib, BLACK, 30.0 * s)
			c.draw_polyline(rib, CraterArt.METAL_SHADE.darkened(0.2), 22.0 * s)
		"nest":                                                    # A Kharleming nest mound of scrap
			var nm := PackedVector2Array()
			for i in 9:
				var a := PI + PI * float(i) / 8.0
				nm.append(o + Vector2(cos(a) * 80.0, sin(a) * 50.0) * s)
			c.draw_colored_polygon(nm, Color(0.20, 0.20, 0.22))
			FighterArt.outline(c, nm, 3.0)
			for k in 3:
				c.draw_circle(o + Vector2(-30 + float(k) * 30.0, -24) * s, 5.0 * s, Color(0.35, 1.0, 0.95, 0.6))
		"banner":                                                  # A war banner on a spear (the front)
			c.draw_line(o, o + Vector2(0, -200) * s, BLACK, 6.0)
			c.draw_line(o, o + Vector2(0, -200) * s, Color(0.3, 0.22, 0.16), 3.0)
			var flag := PackedVector2Array([o + Vector2(0, -196) * s, o + Vector2(70, -180) * s, o + Vector2(0, -150) * s])
			c.draw_colored_polygon(flag, CraterArt.LAVA_DARK if v % 2 == 0 else CraterArt.METAL_SHADE)
			FighterArt.outline(c, flag, 2.5)


# ============================================================
# WORLD NODES
# ============================================================
class PropStrip extends Node2D:
	var items: Array = []

	func _ready() -> void:
		z_index = -1

	func _draw() -> void:
		for p in items:
			CraterWorld.draw_prop(self, p)


## The MAGMA BARRIER behind the Lava Melter: a wall of falling magma (solid) until it dies.
class MagmaGate extends StaticBody2D:
	var drained := false
	var _t := 0.0
	var _k := 1.0

	func _ready() -> void:
		collision_layer = CombatManager.WORLD_LAYER
		collision_mask = 0
		var shape := RectangleShape2D.new()
		shape.size = Vector2(80, 2400)
		var col := CollisionShape2D.new()
		col.name = "Col"
		col.shape = shape
		col.position = Vector2(0, -1100)
		add_child(col)
		z_index = 1

	func drain() -> void:
		drained = true
		(get_node("Col") as CollisionShape2D).set_deferred("disabled", true)

	func _process(delta: float) -> void:
		_t += delta
		if drained:
			_k = maxf(_k - delta * 0.5, 0.0)
		if OptimizationManager.on_screen(global_position, 400.0):
			queue_redraw()

	func _draw() -> void:
		if _k <= 0.0:
			return
		var h := 760.0 * _k
		for i in 7:                                              # Columns of falling magma
			var x := -40.0 + float(i) * 13.0
			var col := CraterArt.LAVA if i % 2 == 0 else CraterArt.LAVA_DARK
			draw_line(Vector2(x, -h), Vector2(x + sin(_t * 3.0 + float(i)) * 4.0, 0), col, 14.0)
		draw_circle(Vector2(0, -20), 90.0, Color(1.0, 0.4, 0.1, 0.18 * _k))
		for i in 6:
			var y := -fmod(_t * 220.0 + float(i) * 130.0, h)
			draw_circle(Vector2(sin(float(i) * 2.0) * 30.0, y), 7.0, CraterArt.LAVA_HOT)


## The BASALT WALL: columns of black basalt, solid. Corpses piled at its foot; the Breaker blows it up.
class BasaltWall extends StaticBody2D:
	var pile := 0                                                  # Kharleming corpses piled here
	var broken := false
	var glow := 0.0                                                # The Breaker is ticking (corpses glow)
	var _t := 0.0

	func _ready() -> void:
		collision_layer = CombatManager.WORLD_LAYER
		collision_mask = 0
		var shape := RectangleShape2D.new()
		shape.size = Vector2(140, 2400)
		var col := CollisionShape2D.new()
		col.name = "Col"
		col.shape = shape
		col.position = Vector2(40, -1100)
		add_child(col)
		z_index = 1

	func shatter() -> void:
		broken = true
		pile = 0
		(get_node("Col") as CollisionShape2D).set_deferred("disabled", true)
		queue_redraw()

	func _process(delta: float) -> void:
		_t += delta
		if OptimizationManager.on_screen(global_position, 500.0):
			queue_redraw()

	func _draw() -> void:
		if broken:                                                 # Rubble on both sides of the hole
			for i in 7:
				var rx := -120.0 + float(i) * 50.0
				var rr := PackedVector2Array([Vector2(rx - 20, 4), Vector2(rx - 12, -26 - float(i % 3) * 12.0), Vector2(rx + 14, -20), Vector2(rx + 20, 4)])
				draw_colored_polygon(rr, CraterArt.BASALT)
				FighterArt.outline(self, rr, 2.5)
			return
		for i in 7:                                                # Hexagonal columns, tall and black
			var h := 640.0 + float((i * 5) % 3) * 50.0
			var r := Rect2(-30.0 + float(i) * 26.0, -h, 26.0, h)
			draw_rect(r, CraterArt.BASALT.lightened(0.05 * float(i % 2)))
			draw_rect(r, BLACK, false, 3.0)
			draw_line(r.position + Vector2(6, 14), r.position + Vector2(6, h - 10), CraterArt.BASALT_HI, 2.0)
		# Corpses piled at its foot (left side)
		for i in pile:
			var cp := Vector2(-80.0 - float(i % 3) * 46.0, -float(i / 3) * 34.0)
			draw_set_transform(cp, 0.3 * float(i % 2) - 0.15, Vector2(0.75, 0.75))
			CraterArt.kharleming(self, {"t": 0.0, "pose": "idle", "dead": true}, false)
			draw_set_transform(Vector2.ZERO, 0.0, Vector2.ONE)
			if glow > 0.0:
				draw_circle(cp + Vector2(0, -30), 40.0, Color(1.0, 0.15, 0.1, 0.25 * glow * (0.5 + 0.5 * sin(_t * 12.0))))


## A Kharleming CORPSE you can DRAG (DOWN to pick it up / drop it).
class Corpse extends Node2D:
	var master := false
	var dragged := false
	var _t := 0.0

	func _ready() -> void:
		z_index = -1

	func _process(delta: float) -> void:
		_t += delta
		if OptimizationManager.on_screen(global_position, 200.0):
			queue_redraw()

	func _draw() -> void:
		draw_set_transform(Vector2(0, 4), 0.25 if dragged else 0.0, Vector2(0.85, 0.85))
		CraterArt.kharleming(self, {"t": _t, "pose": "idle", "dead": true}, master)
		draw_set_transform(Vector2.ZERO, 0.0, Vector2.ONE)
		if not dragged:
			draw_circle(Vector2(0, -26), 30.0 + 3.0 * sin(_t * 3.0), Color(1.0, 0.85, 0.4, 0.08))


## The TECHNICIAN'S BREAKER lying on the ground (an ancient Kharleming device).
class BreakerPickup extends Node2D:
	var _t := 0.0

	func _process(delta: float) -> void:
		_t += delta
		queue_redraw()

	func _draw() -> void:
		draw_line(Vector2(0, -20), Vector2(0, -360), Color(0.4, 1.0, 1.0, 0.10 + 0.05 * sin(_t * 2.0)), 26.0)
		CraterWorld.draw_breaker(self, Vector2(0, -60 + sin(_t * 2.5) * 8.0), 1.4, _t)


## The Technician's Breaker: a heavy steel cylinder, a ring of cyan cells, one red button.
static func draw_breaker(c: CanvasItem, p: Vector2, s: float, t: float) -> void:
	c.draw_circle(p, 34.0 * s, Color(0.35, 1.0, 1.0, 0.14 + 0.06 * sin(t * 3.0)))
	var body := Rect2(p.x - 13 * s, p.y - 22 * s, 26 * s, 44 * s)
	FighterArt.rrect(c, body, CraterArt.METAL, CraterArt.METAL_SHADE, CraterArt.METAL_HI, 5.0, 3.0)
	for i in 3:
		c.draw_circle(Vector2(p.x, p.y - 12 * s + float(i) * 12 * s), 3.5 * s, CraterArt.CYAN)
	c.draw_rect(Rect2(p.x - 6 * s, p.y - 32 * s, 12 * s, 10 * s), CraterArt.METAL_SHADE)
	c.draw_circle(Vector2(p.x, p.y - 34 * s), 5.0 * s, Color(1.0, 0.15, 0.1) if fmod(t, 1.0) < 0.6 else Color(0.5, 0.05, 0.05))


## The ENERGY REACTOR of the wreck with the KHARLEMING SACRIFICE chained on top.
## state: "chained" / "freed" (gone) / "dead" (the reactor overloaded: a burnt husk).
class Reactor extends Node2D:
	var state := "chained"
	var _t := 0.0

	func _ready() -> void:
		z_index = -1

	func _process(delta: float) -> void:
		_t += delta
		if OptimizationManager.on_screen(global_position, 400.0):
			queue_redraw()

	func _draw() -> void:
		var h := 300.0
		var hot := state == "dead"
		draw_circle(Vector2(0, -h * 0.5), 160.0, Color(0.35, 1.0, 1.0, 0.06) if not hot else Color(1.0, 0.3, 0.1, 0.10))
		# The machine: a fat cylinder of plates, pipes, a glowing core window
		var body := Rect2(-70, -h, 140, h)
		FighterArt.rrect(self, body, CraterArt.METAL_SHADE, CraterArt.BASALT, CraterArt.METAL, 10.0, 4.5)
		for i in 4:
			draw_line(Vector2(-66, -h + 50.0 + float(i) * 60.0), Vector2(66, -h + 50.0 + float(i) * 60.0), CraterArt.BASALT, 3.0)
		var core := Color(0.35, 1.0, 1.0) if state == "chained" else (Color(1.0, 0.35, 0.1) if hot else Color(0.25, 0.4, 0.45))
		draw_circle(Vector2(0, -h * 0.45), 34.0, BLACK)
		draw_circle(Vector2(0, -h * 0.45), 28.0, Color(core.r, core.g, core.b, 0.7 + 0.3 * sin(_t * (6.0 if state == "chained" else 1.0))))
		for d: float in [-1.0, 1.0]:
			draw_line(Vector2(d * 70, -h * 0.3), Vector2(d * 130, 0), BLACK, 14.0)
			draw_line(Vector2(d * 70, -h * 0.3), Vector2(d * 130, 0), CraterArt.METAL_SHADE, 9.0)
		# On top: the Sacrifice in chains (or nothing / a husk)
		var top := Vector2(0, -h)
		if state != "freed":
			for d: float in [-1.0, 1.0]:                         # Chains
				draw_line(top + Vector2(d * 60, 0), top + Vector2(d * 14, -20), Color(0.4, 0.4, 0.42), 3.0)
			draw_set_transform(top, 0.0, Vector2(1.1, 1.1))
			if hot:
				Kharleming.draw_bot(self, {"t": _t, "pose": "idle", "dead": true})
			else:
				Kharleming.draw_bot(self, {"t": _t * 3.0, "pose": "idle", "moving": true})   # Struggling
			draw_set_transform(Vector2.ZERO, 0.0, Vector2.ONE)
			if hot:
				for k in 4:
					draw_circle(top + Vector2(-10 + float(k) * 7.0, -30.0 - float(k) * 18.0), 8.0 + float(k) * 3.0, Color(0.2, 0.18, 0.18, 0.3))


## The MOUNTAIN the VOLCANO SLAVE mines (a cave mouth in a rock face) and the slave himself.
## state: "chained" / "freed" (gone) / "dead" (the mine collapsed on him).
class Mine extends Node2D:
	var state := "chained"
	var _t := 0.0

	func _ready() -> void:
		z_index = -1

	func _process(delta: float) -> void:
		_t += delta
		if OptimizationManager.on_screen(global_position, 400.0):
			queue_redraw()

	func _draw() -> void:
		var m := PackedVector2Array([Vector2(-260, 4), Vector2(-180, -260), Vector2(-60, -380), Vector2(60, -340), Vector2(200, -200), Vector2(280, 4)])
		draw_colored_polygon(m, Color(0.14, 0.10, 0.10))
		draw_polyline(PackedVector2Array([Vector2(-60, -370), Vector2(-90, -250), Vector2(-60, -150)]), CraterArt.LAVA, 4.0)
		FighterArt.outline(self, m, 4.0)
		var mouth := EnemyArt.ellipse_points(Vector2(30, -70), 70, 70, 16)
		draw_colored_polygon(mouth, Color(0.03, 0.02, 0.02))
		if state == "dead":                                        # Collapsed: rubble over the mouth
			for i in 6:
				var rx := -30.0 + float(i) * 24.0
				var rr := PackedVector2Array([Vector2(rx - 18, 4), Vector2(rx - 10, -60 - float(i % 3) * 20.0), Vector2(rx + 14, -50), Vector2(rx + 18, 4)])
				draw_colored_polygon(rr, CraterArt.BASALT)
				FighterArt.outline(self, rr, 2.5)
			return
		if state == "chained":
			CraterWorld.draw_slave(self, Vector2(-40, 0), _t, true)


## The VOLCANO SLAVE: a soot-black miner in rags, a pickaxe, an iron chain into the rock.
static func draw_slave(c: CanvasItem, o: Vector2, t: float, chained: bool) -> void:
	var swing := sin(t * 2.2)
	if chained:
		c.draw_polyline(PackedVector2Array([o + Vector2(-10, -6), o + Vector2(30, 10), o + Vector2(70, -4)]), Color(0.38, 0.38, 0.40), 3.0)
	for d: float in [-1.0, 1.0]:
		FighterArt.limb(c, o + Vector2(d * 6.0, -50), o + Vector2(d * 9.0, -2), 8.0, Color(0.22, 0.18, 0.16), BLACK, Color(0.35, 0.3, 0.28))
	var torso := Rect2(o.x - 15, o.y - 92, 30, 44)
	FighterArt.rrect(c, torso, Color(0.30, 0.24, 0.20), Color(0.16, 0.12, 0.10), Color(0.42, 0.36, 0.30), 8.0, 3.5)
	FighterArt.ball(c, o + Vector2(2, -104), 12.0, Color(0.36, 0.30, 0.27), Color(0.2, 0.16, 0.14), Color(0.5, 0.42, 0.38))
	c.draw_circle(o + Vector2(7, -106), 2.0, Color(1.0, 0.75, 0.4))
	# The pickaxe, swinging into the rock
	var hand := o + Vector2(16, -80) + Vector2(10, -8) * swing
	FighterArt.limb(c, o + Vector2(8, -86), hand, 7.0, Color(0.30, 0.24, 0.20), BLACK, Color(0.42, 0.36, 0.30))
	var head := hand + Vector2(18, -28 + swing * 10.0)
	c.draw_line(hand, head, BLACK, 6.0)
	c.draw_line(hand, head, Color(0.45, 0.32, 0.2), 3.0)
	c.draw_line(head + Vector2(-14, 4), head + Vector2(14, -6), BLACK, 7.0)
	c.draw_line(head + Vector2(-14, 4), head + Vector2(14, -6), CraterArt.METAL, 4.0)
