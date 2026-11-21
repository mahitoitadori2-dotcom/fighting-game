class_name TownWorld
extends RefCounted
## THE ABANDONED TOWN (level 81) - layout + the scene objects. TownLand.gd runs the level.
##
##   x:  -12000 ......... -9400   |   -3700 ...... -3300 ........ -1650 .................. 2900
##       THE NIGHTMARE'S CAVE         outside       CAVE MOUTH     LEFT GATE    THE TOWN        east wall
##       (sleeper at -11500)          (a separate area: entered through a LOADING SCREEN)
##
## You land on the EAST side of the town. The three who know the lore: the Oldest Judge (by the
## courthouse), the Shopkeeper (market stall), the Youngest Guard (at the left gate).

const GROUND_W := 26000.0
# The town area
const TOWN_L := -3700.0
const TOWN_R := 2900.0
const START_X := 2300.0
const GATE_X := -1650.0
const CAVE_MOUTH_X := -3300.0
const SHRINE_X := 1950.0
const WIND_ALIVE_X := -2350.0                   # Coming back: the Strong Wind takes you before the gate
const WIND_DEAD_X := -1850.0                    # (burning town: you get close enough to see it)
# The cave area
const CAVE_L := -12000.0
const CAVE_R := -9400.0
const CAVE_ENTRY_X := -9620.0
const SLEEPER_X := -11500.0

const LORE := ["judge", "shopkeeper", "young_guard"]
## People: id, x, look (OrdArt villager look for townsfolk; -1 = one of the three).
const PEOPLE := [
	{"id": "young_guard", "x": -1560.0, "look": -1},
	{"id": "tw_baker", "x": -820.0, "look": 0},
	{"id": "judge", "x": -170.0, "look": -1},
	{"id": "tw_woman", "x": 330.0, "look": 1},
	{"id": "shopkeeper", "x": 760.0, "look": -1},
	{"id": "tw_farmer", "x": 1260.0, "look": 2},
	{"id": "tw_child", "x": 1700.0, "look": 5},
]
## Props: kind, x, (w, h for houses), y = height above the floor (wall stains).
const PROPS := [
	{"kind": "cave_mouth", "x": -3300.0},
	{"kind": "gate", "x": -1650.0},
	{"kind": "house", "x": -1220.0, "w": 230.0, "h": 170.0, "v": 1},
	{"kind": "house", "x": -560.0, "w": 210.0, "h": 160.0, "v": 2},
	{"kind": "house", "x": -230.0, "w": 300.0, "h": 230.0, "v": 0},      # The courthouse
	{"kind": "house", "x": 220.0, "w": 200.0, "h": 150.0, "v": 3},
	{"kind": "stall", "x": 680.0},
	{"kind": "house", "x": 1080.0, "w": 240.0, "h": 180.0, "v": 4},
	{"kind": "house", "x": 1480.0, "w": 190.0, "h": 150.0, "v": 5},
	{"kind": "shrine", "x": 1950.0},
	{"kind": "house", "x": 2560.0, "w": 260.0, "h": 190.0, "v": 2},
	# --- The Nightmare's cave: old blood, burned charcoal, scorched bones ---
	{"kind": "blood", "x": -9800.0, "r": 60.0, "y": 0.0, "v": 1},
	{"kind": "charcoal", "x": -9950.0, "w": 90.0, "v": 2},
	{"kind": "blood", "x": -10150.0, "r": 45.0, "y": 170.0, "v": 3},
	{"kind": "bones", "x": -10300.0, "v": 1},
	{"kind": "charcoal", "x": -10480.0, "w": 140.0, "v": 4},
	{"kind": "blood", "x": -10600.0, "r": 80.0, "y": 0.0, "v": 5},
	{"kind": "blood", "x": -10760.0, "r": 60.0, "y": 230.0, "v": 6},
	{"kind": "bones", "x": -10900.0, "v": 2},
	{"kind": "charcoal", "x": -11050.0, "w": 120.0, "v": 7},
	{"kind": "blood", "x": -11200.0, "r": 55.0, "y": 140.0, "v": 8},
	{"kind": "blood", "x": -11380.0, "r": 95.0, "y": 0.0, "v": 9},
	{"kind": "blood", "x": -11640.0, "r": 70.0, "y": 260.0, "v": 10},
	{"kind": "charcoal", "x": -11760.0, "w": 160.0, "v": 11},
]

## The town burns (the "woke" choice): houses, the shrine and the people redraw for it.
static var burning := false


## Wraps a drawing node in a PixelArt group (pixel art, like the fighters). Returns the group.
static func pixel_wrap(n: Node2D, pos: Vector2) -> Node2D:
	var g := PixelArt.new()
	g.position = pos
	g.add_child(n)
	return g


## A PROP (house, gate, shrine, stall, cave mouth, blood, charcoal, bones).
class Prop extends Node2D:
	var def: Dictionary = {}
	var _t := 0.0

	func _ready() -> void:
		z_index = -2 if String(def.get("kind", "")) in ["house", "gate", "shrine", "stall", "cave_mouth"] else -1

	func _process(delta: float) -> void:
		_t += delta
		var k := String(def.get("kind", ""))
		if (TownWorld.burning or k in ["shrine", "gate", "cave_mouth"]) and OptimizationManager.on_screen(global_position, 500.0):
			queue_redraw()

	func _draw() -> void:
		var v := int(def.get("v", 0))
		match String(def.get("kind", "")):
			"house":
				TownArt.house(self, float(def["w"]), float(def["h"]), v, TownWorld.burning, _t)
			"gate":
				TownArt.gate(self, _t)
				if TownWorld.burning:
					TownArt.flames(self, Vector2(0, -150), 300.0, _t, 9.0)
			"shrine":
				TownArt.shrine(self, _t, TownWorld.burning)
			"stall":
				TownArt.stall(self)
				if TownWorld.burning:
					TownArt.flames(self, Vector2(0, -150), 180.0, _t, 5.0)
			"cave_mouth":
				TownArt.cave_mouth(self, _t)
			"blood":
				var y := float(def.get("y", 0.0))
				draw_set_transform(Vector2(0, -y), 0.0, Vector2.ONE)
				TownArt.blood(self, float(def["r"]), y > 0.0, v)
				draw_set_transform(Vector2.ZERO, 0.0, Vector2.ONE)
			"charcoal":
				TownArt.charcoal(self, float(def["w"]), v)
			"bones":
				TownArt.bones(self, v)


## A PERSON of the town. Turns to face you; `dead` = a charred body (the burning town).
class Npc extends Node2D:
	var id := ""
	var look := -1
	var dead := false
	var face := 1
	var _t := 0.0

	func _ready() -> void:
		_t = float(get_instance_id() % 97) * 0.13

	func _process(delta: float) -> void:
		_t += delta
		if OptimizationManager.on_screen(global_position, 200.0):
			queue_redraw()

	func _draw() -> void:
		if dead:
			TownArt.dead_body(self, absi(look) + id.length())
			return
		draw_set_transform(Vector2.ZERO, 0.0, Vector2(float(face), 1.0))
		if look < 0:
			TownArt.npc(self, id, _t)
		else:
			OrdArt.villager(self, look, _t)
		draw_set_transform(Vector2.ZERO, 0.0, Vector2.ONE)


## THE NIGHTMARE LORD in the cave. state: "chained" (asleep), "awake" (standing), "floor" (fallen,
## asleep), "gone".
class Sleeper extends Node2D:
	var state := "chained"
	var _t := 0.0

	func _process(delta: float) -> void:
		_t += delta
		queue_redraw()

	func _draw() -> void:
		match state:
			"chained":
				TownArt.sleeping_lord(self, _t, true, false)
			"floor":
				TownArt.sleeping_lord(self, _t, false, true)
			"awake":
				draw_set_transform(Vector2.ZERO, 0.0, Vector2(1.0, 1.0))
				FireLordArt.draw_portrait(self, _t)
				draw_set_transform(Vector2.ZERO, 0.0, Vector2.ONE)


## The Nightmare Lord over your shoulders ("carried"). A child of the player.
class Carry extends Node2D:
	var who: Fighter
	var _t := 0.0

	func _ready() -> void:
		z_index = 1

	func _process(delta: float) -> void:
		_t += delta
		queue_redraw()

	func _draw() -> void:
		var f := 1 if who == null else who.facing
		TownArt.carried_lord(self, _t, f)


## THE STRONG WIND: streaks of air across the whole screen (a screen-space layer).
class WindFx extends Control:
	var power := 0.0
	var _t := 0.0

	func _ready() -> void:
		set_anchors_and_offsets_preset(Control.PRESET_FULL_RECT)
		mouse_filter = Control.MOUSE_FILTER_IGNORE

	func _process(delta: float) -> void:
		_t += delta
		queue_redraw()

	func _draw() -> void:
		if power <= 0.0:
			return
		var sz := size
		for i in 40:
			var y := fmod(float(i) * 97.0 + sin(float(i)) * 40.0, sz.y)
			var x := fmod(float(i) * 211.0 + _t * (900.0 + float(i % 7) * 140.0), sz.x + 400.0) - 200.0
			var l := 80.0 + float(i % 5) * 40.0
			draw_line(Vector2(x, y - _t * 30.0 * float(i % 3)), Vector2(x + l, y - 10.0 - _t * 30.0 * float(i % 3)), Color(1, 1, 1, 0.35 * power), 3.0)
