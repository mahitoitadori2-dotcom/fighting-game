@tool
class_name ArenaGround
extends StaticBody2D
## Big floating rock island for the arena.
## Origin = centre of the WALKABLE TOP SURFACE (place it where the floor should be).
## Builds its own collision at runtime and draws a flat-cartoon stone texture:
## paving slabs on top, strata bands, cracks, embedded pebbles and glowing hex
## crystals, all with thick black outlines. Walking off either edge = fall death.

@export var width := 2400.0:
	set(v):
		width = maxf(v, 200.0)
		_regenerate()
@export var depth := 300.0:                       # How far the rock hangs below the surface (visual)
	set(v):
		depth = maxf(v, 80.0)
		_regenerate()
@export var collision_depth := 60.0
@export var seed_value := 42:
	set(v):
		seed_value = v
		_regenerate()
## Stone = Test Arena (gray rock, blue crystals). Void = Void Arena (black rock, glowing green cracks).
## Hell = Story Mode (black basalt, glowing lava cracks). Geode = purple crystal cavern
## (Rock Golem). Scrap = rusted metal hive floor with cyan light seams (Kharlemings).
## Lab = the Blinded Lord's laboratory (dark tiles, toxic green seams).
## Colosseum 2: Elevator = steel platform with hazard stripes and cables up the shaft.
## Marble = white marble with gold seams (Enlightened Ones). Sewer = wet mossy stone with
## slime seams. Blasphemy = obsidian with magma veins.
## Colosseum 3: Burnt = scorched throne-room stone with ember cracks. Cobble = Architectium
## paving with rune seams. Foundry = iron floor plates with molten seams.
## Colosseum 4: DarkRock = dim cave rock. Bones = dark bone-pile floor of the void.
@export_enum("Stone", "Void", "Hell", "Geode", "Scrap", "Lab", "Elevator", "Marble", "Sewer", "Blasphemy",
	"Burnt", "Cobble", "Foundry", "DarkRock", "Bones",
	"Loom", "Mirror", "Den", "Gallows", "Garden", "Hellrock", "SunStone", "Thorn", "Ruin", "Snow", "Cathedral",
	"Sand") var ground_theme := 0:
	set(v):
		ground_theme = v
		_apply_theme()
		queue_redraw()

## Underground maps (caves, sewers): solid rock fills everything under the floor instead of a
## floating island with a hanging underside (StoryLevels.MAPS "solid").
@export var solid := false:
	set(v):
		solid = v
		queue_redraw()

const CAP := 26.0                                 # Thickness of the paved top layer
const SOLID_DEPTH := 2600.0                       # How far the solid rock reaches down
const SOLID_SIDE := 1600.0                        # ...and past each edge (hidden by the cave walls)
const OUTLINE := Color(0.0, 0.0, 0.0)

# Palette (set by _apply_theme)
var CRACK := Color(0.14, 0.12, 0.12)
var CRACK_WIDTH := 2.5
var STONE_TOP := Color(0.72, 0.70, 0.66)
var STONE_TOP_HI := Color(0.86, 0.84, 0.80)
var STONE_TOP_SHADE := Color(0.60, 0.58, 0.55)
var STONE := Color(0.56, 0.53, 0.51)
var STONE_DARK := Color(0.45, 0.42, 0.41)
var STONE_DEEP := Color(0.35, 0.33, 0.33)
var PEBBLE_LIGHT := Color(0.66, 0.63, 0.60)
var CRYSTAL := Color(0.35, 0.85, 1.0)
var CRYSTAL_HI := Color(0.85, 0.98, 1.0)
var CRYSTAL_SHADE := Color(0.18, 0.55, 0.85)


func _apply_theme() -> void:
	if ground_theme >= 6:
		_apply_theme_c2()
		return
	if ground_theme == 5:   # LAB: dark green-grey tiles, toxic green seams
		CRACK = Color(0.45, 1.0, 0.2)
		CRACK_WIDTH = 2.0
		STONE_TOP = Color(0.30, 0.34, 0.32)
		STONE_TOP_HI = Color(0.52, 0.58, 0.54)
		STONE_TOP_SHADE = Color(0.18, 0.21, 0.20)
		STONE = Color(0.15, 0.17, 0.16)
		STONE_DARK = Color(0.11, 0.13, 0.12)
		STONE_DEEP = Color(0.10, 0.18, 0.08)
		PEBBLE_LIGHT = Color(0.30, 0.33, 0.30)
		CRYSTAL = Color(0.45, 1.0, 0.2)
		CRYSTAL_HI = Color(0.85, 1.0, 0.7)
		CRYSTAL_SHADE = Color(0.20, 0.55, 0.08)
		return
	if ground_theme == 3:   # GEODE: dark violet stone, glowing amethyst
		CRACK = Color(0.75, 0.40, 1.0)
		CRACK_WIDTH = 2.5
		STONE_TOP = Color(0.26, 0.20, 0.30)
		STONE_TOP_HI = Color(0.50, 0.40, 0.60)
		STONE_TOP_SHADE = Color(0.15, 0.11, 0.18)
		STONE = Color(0.17, 0.13, 0.21)
		STONE_DARK = Color(0.12, 0.09, 0.15)
		STONE_DEEP = Color(0.20, 0.10, 0.28)
		PEBBLE_LIGHT = Color(0.34, 0.27, 0.40)
		CRYSTAL = Color(0.78, 0.45, 1.0)
		CRYSTAL_HI = Color(0.96, 0.85, 1.0)
		CRYSTAL_SHADE = Color(0.45, 0.18, 0.75)
		return
	if ground_theme == 4:   # SCRAP: rusted metal plates, cyan light seams
		CRACK = Color(0.30, 0.95, 0.95)
		CRACK_WIDTH = 2.0
		STONE_TOP = Color(0.36, 0.30, 0.26)
		STONE_TOP_HI = Color(0.58, 0.50, 0.42)
		STONE_TOP_SHADE = Color(0.22, 0.18, 0.16)
		STONE = Color(0.20, 0.18, 0.18)
		STONE_DARK = Color(0.30, 0.17, 0.10)
		STONE_DEEP = Color(0.12, 0.11, 0.12)
		PEBBLE_LIGHT = Color(0.45, 0.42, 0.40)
		CRYSTAL = Color(0.30, 0.95, 0.95)
		CRYSTAL_HI = Color(0.85, 1.0, 1.0)
		CRYSTAL_SHADE = Color(0.10, 0.50, 0.55)
		return
	if ground_theme == 2:   # HELL (Story Mode): basalt + lava
		CRACK = Color(1.0, 0.42, 0.08)
		CRACK_WIDTH = 3.0
		STONE_TOP = Color(0.20, 0.15, 0.14)
		STONE_TOP_HI = Color(0.42, 0.28, 0.22)
		STONE_TOP_SHADE = Color(0.11, 0.08, 0.08)
		STONE = Color(0.13, 0.10, 0.10)
		STONE_DARK = Color(0.09, 0.07, 0.07)
		STONE_DEEP = Color(0.22, 0.07, 0.04)
		PEBBLE_LIGHT = Color(0.26, 0.19, 0.17)
		CRYSTAL = Color(1.0, 0.45, 0.08)
		CRYSTAL_HI = Color(1.0, 0.88, 0.45)
		CRYSTAL_SHADE = Color(0.70, 0.15, 0.03)
	elif ground_theme == 1:   # VOID
		CRACK = Color(0.25, 1.0, 0.38)
		CRACK_WIDTH = 3.0
		STONE_TOP = Color(0.13, 0.15, 0.13)
		STONE_TOP_HI = Color(0.30, 0.42, 0.30)
		STONE_TOP_SHADE = Color(0.07, 0.08, 0.07)
		STONE = Color(0.08, 0.09, 0.08)
		STONE_DARK = Color(0.05, 0.06, 0.05)
		STONE_DEEP = Color(0.10, 0.16, 0.10)
		PEBBLE_LIGHT = Color(0.17, 0.21, 0.17)
		CRYSTAL = Color(0.30, 1.0, 0.42)
		CRYSTAL_HI = Color(0.85, 1.0, 0.85)
		CRYSTAL_SHADE = Color(0.10, 0.55, 0.20)
	else:                   # STONE
		CRACK = Color(0.14, 0.12, 0.12)
		CRACK_WIDTH = 2.5
		STONE_TOP = Color(0.72, 0.70, 0.66)
		STONE_TOP_HI = Color(0.86, 0.84, 0.80)
		STONE_TOP_SHADE = Color(0.60, 0.58, 0.55)
		STONE = Color(0.56, 0.53, 0.51)
		STONE_DARK = Color(0.45, 0.42, 0.41)
		STONE_DEEP = Color(0.35, 0.33, 0.33)
		PEBBLE_LIGHT = Color(0.66, 0.63, 0.60)
		CRYSTAL = Color(0.35, 0.85, 1.0)
		CRYSTAL_HI = Color(0.85, 0.98, 1.0)
		CRYSTAL_SHADE = Color(0.18, 0.55, 0.85)

## Colosseum 2 palettes: [crack, crack_w, top, top_hi, top_shade, stone, dark, deep, pebble, crystal, crystal_hi, crystal_shade]
const C2_THEMES := {
	6: [Color(0.95, 0.75, 0.1), 2.0, Color(0.36, 0.37, 0.40), Color(0.58, 0.60, 0.64), Color(0.22, 0.22, 0.25), Color(0.20, 0.20, 0.23),
		Color(0.15, 0.15, 0.17), Color(0.11, 0.11, 0.13), Color(0.40, 0.40, 0.44), Color(1.0, 0.5, 0.1), Color(1.0, 0.85, 0.5), Color(0.6, 0.25, 0.05)],
	7: [Color(0.95, 0.75, 0.3), 2.0, Color(0.95, 0.93, 0.88), Color(1.0, 1.0, 0.97), Color(0.80, 0.77, 0.70), Color(0.86, 0.83, 0.77),
		Color(0.78, 0.74, 0.67), Color(0.70, 0.64, 0.55), Color(0.98, 0.96, 0.90), Color(1.0, 0.85, 0.35), Color(1.0, 0.97, 0.75), Color(0.8, 0.6, 0.15)],
	8: [Color(0.45, 0.8, 0.35), 2.0, Color(0.22, 0.27, 0.21), Color(0.36, 0.44, 0.33), Color(0.13, 0.17, 0.12), Color(0.13, 0.16, 0.12),
		Color(0.09, 0.12, 0.08), Color(0.08, 0.14, 0.07), Color(0.26, 0.32, 0.24), Color(0.45, 0.85, 0.35), Color(0.8, 1.0, 0.7), Color(0.2, 0.45, 0.12)],
	9: [Color(1.0, 0.38, 0.06), 3.0, Color(0.16, 0.10, 0.11), Color(0.36, 0.20, 0.20), Color(0.09, 0.05, 0.06), Color(0.11, 0.06, 0.07),
		Color(0.07, 0.04, 0.05), Color(0.30, 0.06, 0.03), Color(0.24, 0.14, 0.14), Color(1.0, 0.4, 0.06), Color(1.0, 0.86, 0.45), Color(0.7, 0.12, 0.03)],
	10: [Color(1.0, 0.5, 0.12), 2.5, Color(0.30, 0.20, 0.16), Color(0.48, 0.34, 0.26), Color(0.18, 0.11, 0.09), Color(0.20, 0.13, 0.10),
		Color(0.14, 0.09, 0.07), Color(0.28, 0.10, 0.04), Color(0.36, 0.26, 0.20), Color(1.0, 0.5, 0.12), Color(1.0, 0.85, 0.5), Color(0.6, 0.2, 0.04)],
	11: [Color(0.35, 0.80, 1.0), 2.0, Color(0.62, 0.60, 0.55), Color(0.80, 0.78, 0.72), Color(0.46, 0.44, 0.40), Color(0.45, 0.43, 0.40),
		Color(0.36, 0.34, 0.32), Color(0.26, 0.28, 0.30), Color(0.68, 0.66, 0.60), Color(0.22, 0.86, 0.28), Color(0.72, 1.0, 0.62), Color(0.08, 0.52, 0.15)],
	12: [Color(1.0, 0.55, 0.12), 2.5, Color(0.30, 0.30, 0.33), Color(0.48, 0.48, 0.52), Color(0.18, 0.18, 0.20), Color(0.16, 0.16, 0.18),
		Color(0.11, 0.11, 0.13), Color(0.25, 0.12, 0.05), Color(0.38, 0.38, 0.40), Color(1.0, 0.55, 0.12), Color(1.0, 0.9, 0.5), Color(0.6, 0.25, 0.05)],
	13: [Color(0.30, 0.32, 0.36), 2.0, Color(0.15, 0.15, 0.17), Color(0.26, 0.26, 0.29), Color(0.09, 0.09, 0.10), Color(0.09, 0.09, 0.10),
		Color(0.06, 0.06, 0.07), Color(0.05, 0.05, 0.06), Color(0.20, 0.20, 0.22), Color(0.45, 0.50, 0.60), Color(0.8, 0.85, 0.95), Color(0.2, 0.22, 0.3)],
	14: [Color(0.55, 0.28, 0.95), 2.0, Color(0.24, 0.21, 0.27), Color(0.40, 0.37, 0.43), Color(0.14, 0.12, 0.17), Color(0.10, 0.08, 0.13),
		Color(0.07, 0.05, 0.10), Color(0.12, 0.05, 0.18), Color(0.34, 0.31, 0.37), Color(0.55, 0.28, 0.95), Color(0.85, 0.7, 1.0), Color(0.25, 0.1, 0.45)],
	# ----- Colosseum 5 -----
	15: [Color(0.85, 0.85, 0.95), 1.5, Color(0.42, 0.28, 0.20), Color(0.58, 0.42, 0.30), Color(0.28, 0.18, 0.12), Color(0.26, 0.16, 0.12),   # Loom: floorboards, silk
		Color(0.20, 0.12, 0.09), Color(0.16, 0.10, 0.12), Color(0.45, 0.32, 0.24), Color(0.85, 0.80, 0.95), Color(1.0, 1.0, 1.0), Color(0.55, 0.45, 0.65)],
	16: [Color(1.0, 0.85, 0.4), 2.0, Color(0.50, 0.50, 0.54), Color(0.92, 0.92, 0.95), Color(0.12, 0.12, 0.14), Color(0.30, 0.30, 0.33),       # Mirror: black / white
		Color(0.18, 0.18, 0.20), Color(0.10, 0.10, 0.12), Color(0.70, 0.70, 0.74), Color(1.0, 0.85, 0.4), Color(1.0, 0.97, 0.8), Color(0.6, 0.45, 0.15)],
	17: [Color(0.75, 0.15, 0.10), 2.0, Color(0.36, 0.26, 0.18), Color(0.50, 0.38, 0.26), Color(0.22, 0.15, 0.10), Color(0.24, 0.16, 0.10),      # Den: dirt, bones
		Color(0.17, 0.11, 0.07), Color(0.20, 0.08, 0.05), Color(0.78, 0.72, 0.60), Color(0.80, 0.74, 0.62), Color(1.0, 0.96, 0.85), Color(0.5, 0.42, 0.3)],
	18: [Color(0.65, 0.30, 0.95), 2.0, Color(0.24, 0.20, 0.24), Color(0.38, 0.33, 0.38), Color(0.14, 0.11, 0.14), Color(0.13, 0.10, 0.14),      # Gallows: dark stone, fog
		Color(0.09, 0.07, 0.10), Color(0.16, 0.06, 0.20), Color(0.30, 0.26, 0.30), Color(0.65, 0.30, 0.95), Color(0.9, 0.75, 1.0), Color(0.3, 0.1, 0.45)],
	19: [Color(0.55, 0.95, 0.45), 2.0, Color(0.32, 0.50, 0.22), Color(0.48, 0.68, 0.32), Color(0.20, 0.34, 0.14), Color(0.34, 0.24, 0.14),      # Garden: grass, roots
		Color(0.26, 0.18, 0.10), Color(0.18, 0.12, 0.06), Color(0.44, 0.34, 0.22), Color(0.55, 0.95, 0.45), Color(0.9, 1.0, 0.85), Color(0.2, 0.5, 0.15)],
	20: [Color(1.0, 0.40, 0.06), 3.0, Color(0.14, 0.08, 0.08), Color(0.32, 0.16, 0.14), Color(0.08, 0.04, 0.04), Color(0.10, 0.05, 0.05),      # Hellrock: obsidian, lava
		Color(0.06, 0.03, 0.03), Color(0.35, 0.08, 0.02), Color(0.22, 0.12, 0.10), Color(1.0, 0.40, 0.06), Color(1.0, 0.85, 0.45), Color(0.7, 0.15, 0.03)],
	21: [Color(1.0, 0.85, 0.40), 2.0, Color(0.95, 0.92, 0.82), Color(1.0, 1.0, 0.95), Color(0.80, 0.74, 0.60), Color(0.85, 0.80, 0.68),        # SunStone: white-gold
		Color(0.75, 0.68, 0.54), Color(0.68, 0.60, 0.45), Color(0.98, 0.95, 0.86), Color(1.0, 0.85, 0.40), Color(1.0, 0.98, 0.8), Color(0.8, 0.6, 0.2)],
	22: [Color(0.80, 0.18, 0.12), 2.0, Color(0.20, 0.12, 0.10), Color(0.34, 0.22, 0.18), Color(0.12, 0.07, 0.06), Color(0.12, 0.07, 0.06),      # Thorn: dark forest soil
		Color(0.08, 0.05, 0.04), Color(0.14, 0.04, 0.04), Color(0.26, 0.17, 0.14), Color(0.80, 0.18, 0.12), Color(1.0, 0.6, 0.5), Color(0.4, 0.08, 0.06)],
	23: [Color(0.70, 0.80, 1.0), 2.0, Color(0.46, 0.46, 0.50), Color(0.62, 0.62, 0.68), Color(0.32, 0.32, 0.36), Color(0.34, 0.34, 0.38),      # Ruin: old pale stone
		Color(0.26, 0.26, 0.30), Color(0.20, 0.20, 0.26), Color(0.54, 0.54, 0.58), Color(0.70, 0.80, 1.0), Color(0.95, 0.97, 1.0), Color(0.35, 0.45, 0.7)],
	24: [Color(0.60, 0.80, 1.0), 2.0, Color(0.92, 0.94, 0.98), Color(1.0, 1.0, 1.0), Color(0.74, 0.78, 0.86), Color(0.44, 0.46, 0.52),         # Snow over mountain rock
		Color(0.34, 0.36, 0.42), Color(0.26, 0.28, 0.34), Color(0.60, 0.62, 0.68), Color(0.60, 0.80, 1.0), Color(0.95, 0.98, 1.0), Color(0.3, 0.45, 0.65)],
	25: [Color(1.0, 0.35, 0.10), 2.5, Color(0.16, 0.12, 0.12), Color(0.30, 0.24, 0.22), Color(0.09, 0.06, 0.06), Color(0.10, 0.07, 0.07),      # Cathedral: black stone, embers
		Color(0.07, 0.05, 0.05), Color(0.22, 0.06, 0.03), Color(0.24, 0.20, 0.20), Color(1.0, 0.35, 0.10), Color(1.0, 0.8, 0.5), Color(0.6, 0.12, 0.04)],
	# ----- The Enlightened Chase -----
	26: [Color(1.0, 0.82, 0.35), 1.5, Color(0.88, 0.72, 0.42), Color(0.98, 0.86, 0.56), Color(0.70, 0.55, 0.30), Color(0.74, 0.58, 0.34),     # Sand: golden desert
		Color(0.60, 0.46, 0.26), Color(0.50, 0.38, 0.20), Color(0.92, 0.80, 0.52), Color(1.0, 0.85, 0.35), Color(1.0, 0.97, 0.75), Color(0.75, 0.55, 0.15)],
}


func _apply_theme_c2() -> void:
	var t: Array = C2_THEMES.get(ground_theme, C2_THEMES[6])
	CRACK = t[0]
	CRACK_WIDTH = t[1]
	STONE_TOP = t[2]
	STONE_TOP_HI = t[3]
	STONE_TOP_SHADE = t[4]
	STONE = t[5]
	STONE_DARK = t[6]
	STONE_DEEP = t[7]
	PEBBLE_LIGHT = t[8]
	CRYSTAL = t[9]
	CRYSTAL_HI = t[10]
	CRYSTAL_SHADE = t[11]


var _poly := PackedVector2Array()
var _strata: Array[PackedVector2Array] = []
var _deep: Array[PackedVector2Array] = []
var _cap_polys: Array[PackedVector2Array] = []
var _joints: Array[PackedVector2Array] = []
var _chips: Array[PackedVector2Array] = []
var _cracks: Array[PackedVector2Array] = []
var _pebbles: Array[Vector3] = []                 # x, y, radius
var _crystals: Array[Vector3] = []                # x, y, radius (embedded hexagons)
var _drips: Array[Dictionary] = []                # crystal spikes on the underside
var _speckles: Array[Vector3] = []                # x, y, shade (-1 dark .. +1 light): subtle rock grain


func _ready() -> void:
	z_index = -2                                  # Ground layer: decals (-1) and fighters (0) draw on top
	_apply_theme()
	_regenerate()
	if Engine.is_editor_hint():
		return
	add_to_group("arena_ground")
	collision_layer = CombatManager.WORLD_LAYER
	var shape := RectangleShape2D.new()
	shape.size = Vector2(width, collision_depth)
	var col := CollisionShape2D.new()
	col.name = "CollisionShape2D"
	col.shape = shape
	col.position = Vector2(0, collision_depth * 0.5)
	add_child(col)


## World-space x range of the walkable floor.
func left_edge() -> float:
	return global_position.x - width * 0.5


func right_edge() -> float:
	return global_position.x + width * 0.5


# ============================================================
# GENERATION (deterministic: same seed = same rock)
# ============================================================
func _regenerate() -> void:
	var rng := RandomNumberGenerator.new()
	rng.seed = seed_value
	var hw := width * 0.5

	# --- Island outline: flat top, chamfered lips, jagged tapering underside ---
	_poly = PackedVector2Array()
	_poly.append(Vector2(-hw, 12))
	_poly.append(Vector2(-hw + 12, 0))
	_poly.append(Vector2(hw - 12, 0))
	_poly.append(Vector2(hw, 12))
	_poly.append(Vector2(hw - 8, CAP + 22))
	var x := hw - 40.0
	var flip := 1.0
	while x > -hw + 40.0:
		var k := absf(x) / hw
		var profile := pow(maxf(1.0 - k * k, 0.0), 0.65)
		var y := CAP + 30.0 + (depth - CAP - 30.0) * profile
		y += rng.randf_range(4.0, 22.0) * flip
		flip = -flip
		_poly.append(Vector2(x, y))
		x -= rng.randf_range(70.0, 130.0)
	_poly.append(Vector2(-hw + 8, CAP + 22))

	# --- Strata bands (wavy darker layers, clipped to the island) ---
	_strata.clear()
	_deep.clear()
	var band_y := CAP + 40.0
	var band_i := 0
	while band_y < depth:
		var band := _wavy_band(rng, -hw - 40.0, hw + 40.0, band_y, rng.randf_range(16.0, 30.0))
		for piece in Geometry2D.intersect_polygons(band, _poly):
			if band_i % 2 == 0:
				_strata.append(piece)
			else:
				_deep.append(piece)
		band_y += rng.randf_range(44.0, 70.0)
		band_i += 1

	# --- Paved cap: the walkable layer on top ---
	_cap_polys.clear()
	var cap_rect := PackedVector2Array([
		Vector2(-hw - 5, -5), Vector2(hw + 5, -5), Vector2(hw + 5, CAP), Vector2(-hw - 5, CAP)])
	for piece in Geometry2D.intersect_polygons(cap_rect, _poly):
		_cap_polys.append(piece)

	# Slab joints + chipped corners
	_joints.clear()
	_chips.clear()
	_cracks.clear()
	x = -hw + rng.randf_range(60.0, 140.0)
	while x < hw - 30.0:
		var jx := x + rng.randf_range(-4.0, 4.0)
		_joints.append(PackedVector2Array([Vector2(x, 3), Vector2(jx, CAP * 0.5), Vector2(x + rng.randf_range(-3.0, 3.0), CAP)]))
		if rng.randf() < 0.5:
			var s := rng.randf_range(5.0, 9.0)
			_chips.append(PackedVector2Array([Vector2(x + 2, CAP), Vector2(x + 2 + s * 1.6, CAP), Vector2(x + 2, CAP - s)]))
		if rng.randf() < 0.35:                                       # Hairline crack in the slab
			var cx := x + rng.randf_range(20.0, 60.0)
			_cracks.append(PackedVector2Array([Vector2(cx, 4), Vector2(cx + 6, 10), Vector2(cx + 2, 16)]))
		x += rng.randf_range(90.0, 170.0)

	# --- Cracks running through the body ---
	var tries := int(width / 55.0)
	for i in tries:
		var p := Vector2(rng.randf_range(-hw + 30.0, hw - 30.0), rng.randf_range(CAP + 10.0, depth))
		if not Geometry2D.is_point_in_polygon(p, _poly):
			continue
		var line := PackedVector2Array([p])
		var ang := rng.randf_range(0.6, 2.5)                       # Mostly downward
		for j in rng.randi_range(3, 6):
			ang += rng.randf_range(-0.7, 0.7)
			var nxt := p + Vector2.from_angle(ang) * rng.randf_range(10.0, 24.0)
			if not Geometry2D.is_point_in_polygon(nxt, _poly):
				break
			line.append(nxt)
			if rng.randf() < 0.25:                                    # Small branch
				var br := nxt + Vector2.from_angle(ang + rng.randf_range(-1.4, 1.4)) * rng.randf_range(8.0, 14.0)
				if Geometry2D.is_point_in_polygon(br, _poly):
					_cracks.append(PackedVector2Array([nxt, br]))
			p = nxt
		if line.size() >= 2:
			_cracks.append(line)

	# --- Embedded pebbles / boulders ---
	_pebbles.clear()
	for i in int(width / 30.0):
		var r := rng.randf_range(3.5, 10.0)
		var p := Vector2(rng.randf_range(-hw + 20.0, hw - 20.0), rng.randf_range(CAP + 12.0, depth - 10.0))
		if _inside_with_margin(p, r + 4.0):
			_pebbles.append(Vector3(p.x, p.y, r))

	# --- Glowing hex crystals (Hexagon theme) ---
	_crystals.clear()
	for i in int(width / 260.0):
		var r := rng.randf_range(6.0, 11.0)
		var p := Vector2(rng.randf_range(-hw + 60.0, hw - 60.0), rng.randf_range(CAP + 40.0, depth - 20.0))
		if _inside_with_margin(p, r + 6.0):
			_crystals.append(Vector3(p.x, p.y, r))

	# Crystal spikes hanging from the underside
	# Subtle rock grain (tiny light / dark flecks)
	_speckles.clear()
	for i in int(width * depth / 900.0):
		var sp := Vector2(rng.randf_range(-hw, hw), rng.randf_range(2.0, depth))
		if Geometry2D.is_point_in_polygon(sp, _poly):
			_speckles.append(Vector3(sp.x, sp.y, rng.randf_range(-1.0, 1.0)))

	_drips.clear()
	for i in range(5, _poly.size() - 1, 3):
		if rng.randf() < 0.45:
			var base: Vector2 = _poly[i]
			_drips.append({"pos": base + Vector2(0, -6), "len": rng.randf_range(18.0, 36.0), "w": rng.randf_range(7.0, 11.0)})

	queue_redraw()


func _wavy_band(rng: RandomNumberGenerator, x0: float, x1: float, y: float, h: float) -> PackedVector2Array:
	var top := PackedVector2Array()
	var bot := PackedVector2Array()
	var x := x0
	while x <= x1:
		top.append(Vector2(x, y + rng.randf_range(-5.0, 5.0)))
		bot.append(Vector2(x, y + h + rng.randf_range(-5.0, 5.0)))
		x += 60.0
	bot.reverse()
	top.append_array(bot)
	return top


func _inside_with_margin(p: Vector2, m: float) -> bool:
	for d in [Vector2.ZERO, Vector2(m, 0), Vector2(-m, 0), Vector2(0, m), Vector2(0, -m)]:
		if not Geometry2D.is_point_in_polygon(p + d, _poly):
			return false
	return true


static func _hex(center: Vector2, r: float, rot: float = 0.0) -> PackedVector2Array:
	var pts := PackedVector2Array()
	for i in 6:
		var a := rot + TAU * float(i) / 6.0
		pts.append(center + Vector2(cos(a), sin(a)) * r)
	return pts


# ============================================================
# DRAWING
# ============================================================
func _draw() -> void:
	if _poly.size() < 3:
		return
	if solid:
		_draw_solid_fill()
	# Underside crystal spikes (behind the rock body)
	for d in _drips:
		if solid:
			break                                         # No hanging underside in solid ground
		var p: Vector2 = d["pos"]
		var w: float = d["w"]
		var l: float = d["len"]
		var spike := PackedVector2Array([p + Vector2(-w, 0), p + Vector2(w, 0), p + Vector2(0, l)])
		draw_colored_polygon(spike, CRYSTAL)
		draw_colored_polygon(PackedVector2Array([p + Vector2(-w * 0.2, 0), p + Vector2(w, 0), p + Vector2(0, l)]), CRYSTAL_SHADE)
		_outline(spike, 3.5)

	# Rock body + strata
	# Rock body: vertical gradient (lit top -> deep bottom) instead of one flat colour
	var cols := PackedColorArray()
	for p in _poly:
		cols.append(STONE.lerp(STONE_DEEP, clampf(p.y / depth, 0.0, 1.0) * 0.8))
	draw_polygon(_poly, cols)
	for sp in _speckles:
		var tint := STONE_TOP_HI if sp.z > 0.0 else STONE_DEEP
		draw_circle(Vector2(sp.x, sp.y), 1.2 + absf(sp.z) * 1.3, Color(tint.r, tint.g, tint.b, 0.22 * absf(sp.z) + 0.08))
	for s in _strata:
		draw_colored_polygon(s, STONE_DARK)
	for s in _deep:
		draw_colored_polygon(s, STONE_DEEP)

	# Pebbles: outline, fill, tiny highlight
	for pb in _pebbles:
		var c := Vector2(pb.x, pb.y)
		draw_circle(c, pb.z + 2.0, OUTLINE)
		draw_circle(c, pb.z, PEBBLE_LIGHT if int(pb.x) % 3 == 0 else STONE_DARK)
		draw_circle(c + Vector2(-pb.z * 0.35, -pb.z * 0.35), pb.z * 0.3, STONE_TOP_HI)

	# Cracks: dark line + light lip below it (Void theme: glowing green)
	for cr in _cracks:
		var lip := PackedVector2Array()
		for q in cr:
			lip.append(q + Vector2(1.5, 2.0))
		if ground_theme >= 1:                                   # Void / Hell: glowing cracks
			draw_polyline(cr, Color(CRACK.r, CRACK.g, CRACK.b, 0.25), CRACK_WIDTH * 3.0, true)
		else:
			draw_polyline(lip, Color(STONE_TOP_HI.r, STONE_TOP_HI.g, STONE_TOP_HI.b, 0.45), 1.5, true)
		draw_polyline(cr, CRACK, CRACK_WIDTH, true)

	# Embedded glowing hexagons
	for cy in _crystals:
		var c := Vector2(cy.x, cy.y)
		draw_circle(c, cy.z * 1.9, Color(CRYSTAL.r, CRYSTAL.g, CRYSTAL.b, 0.18))
		var hex := _hex(c, cy.z, PI / 6.0)
		draw_colored_polygon(hex, CRYSTAL)
		draw_colored_polygon(_hex(c + Vector2(-cy.z * 0.2, -cy.z * 0.2), cy.z * 0.45, PI / 6.0), CRYSTAL_HI)
		_outline(hex, 3.0)

	# Paved top layer
	for cp in _cap_polys:
		draw_colored_polygon(cp, STONE_TOP)
	var hw := width * 0.5
	draw_rect(Rect2(-hw + 10, CAP - 7, width - 20, 7), STONE_TOP_SHADE)
	draw_line(Vector2(-hw + 14, 4), Vector2(hw - 14, 4), STONE_TOP_HI, 4.0)
	for ch in _chips:
		draw_colored_polygon(ch, STONE_DARK)
	for j in _joints:
		draw_polyline(j, CRACK, 3.0, true)
	draw_line(Vector2(-hw + 6, CAP), Vector2(hw - 6, CAP), OUTLINE if ground_theme >= 1 else CRACK, 4.0)
	if ground_theme >= 1:      # Thin glowing rim light along the walkable edge
		draw_line(Vector2(-hw + 14, 2), Vector2(hw - 14, 2), Color(CRACK.r, CRACK.g, CRACK.b, 0.6), 2.0)

	# Thick black cartoon outline (solid ground: only along the walkable top)
	if solid:
		draw_line(Vector2(-hw - SOLID_SIDE, 0), Vector2(hw + SOLID_SIDE, 0), OUTLINE, 7.0)
	else:
		_outline(_poly, 7.0)
	if ground_theme == 14:      # Void: bones and skulls half sunk in the floor
		var bx := -hw + 70.0
		var bi := 0
		while bx < hw - 60.0:
			var by := CAP + 18.0 + float(bi % 3) * 22.0
			if bi % 3 == 0:
				draw_circle(Vector2(bx, by), 11.0, Color(0.36, 0.33, 0.40))
				draw_circle(Vector2(bx - 4, by - 1), 3.0, Color(0, 0, 0))
				draw_circle(Vector2(bx + 4, by - 1), 3.0, Color(0, 0, 0))
			else:
				var a := 0.6 * float(bi % 5) - 1.2
				var d := Vector2.from_angle(a) * 22.0
				draw_line(Vector2(bx, by) - d, Vector2(bx, by) + d, Color(0.36, 0.33, 0.40), 5.0)
				draw_circle(Vector2(bx, by) - d, 4.0, Color(0.36, 0.33, 0.40))
				draw_circle(Vector2(bx, by) + d, 4.0, Color(0.36, 0.33, 0.40))
			bx += 95.0
			bi += 1
	elif ground_theme == 6:
		_draw_elevator_extras()
	elif ground_theme == 16:     # Mirror Hall: the floor is a black / white checkerboard, mirrored
		var tile := 60.0
		var x0 := -hw + 10.0
		var i := 0
		while x0 < hw - 10.0:
			var w := minf(tile, hw - 10.0 - x0)
			draw_rect(Rect2(x0, 2, w, CAP - 8.0), Color(0.12, 0.12, 0.14) if (i % 2 == 0) == (x0 < 0.0) else Color(0.92, 0.92, 0.95))
			x0 += tile
			i += 1
		draw_line(Vector2(0, 0), Vector2(0, CAP), Color(1.0, 0.85, 0.4), 3.0)
	elif ground_theme == 8:      # Sewer: wet sheen + slime drips over the lip
		draw_line(Vector2(-hw + 14, 9), Vector2(hw - 14, 9), Color(0.6, 0.9, 0.55, 0.25), 3.0)
		var x := -hw + 60.0
		while x < hw - 40.0:
			draw_line(Vector2(x, CAP), Vector2(x, CAP + 10.0 + fmod(x * 0.37, 14.0)), Color(0.45, 0.8, 0.35, 0.7), 4.0)
			x += 140.0


## Solid bedrock under (and beside) the island: same palette, darker the deeper it goes,
## with strata lines and embedded stones, so the floor reads as the cave's real ground.
func _draw_solid_fill() -> void:
	var hw := width * 0.5
	var x0 := -hw - SOLID_SIDE
	var x1 := hw + SOLID_SIDE
	var top_c := STONE
	var mid_c := STONE.lerp(STONE_DEEP, 0.8)
	var deep_c := mid_c.darkened(0.55)
	draw_polygon(PackedVector2Array([Vector2(x0, 0), Vector2(x1, 0), Vector2(x1, depth), Vector2(x0, depth)]),
		PackedColorArray([top_c, top_c, mid_c, mid_c]))
	draw_polygon(PackedVector2Array([Vector2(x0, depth), Vector2(x1, depth), Vector2(x1, SOLID_DEPTH), Vector2(x0, SOLID_DEPTH)]),
		PackedColorArray([mid_c, mid_c, deep_c, deep_c]))
	# Paved cap continues to the walls
	draw_rect(Rect2(x0, 0, SOLID_SIDE, CAP), STONE_TOP)
	draw_rect(Rect2(hw, 0, SOLID_SIDE, CAP), STONE_TOP)
	draw_line(Vector2(x0, CAP), Vector2(x1, CAP), OUTLINE, 4.0)
	var rng := RandomNumberGenerator.new()
	rng.seed = seed_value + 913
	# Strata lines
	var y := CAP + 50.0
	while y < 1100.0:
		var pts := PackedVector2Array()
		var x := x0
		while x <= x1:
			pts.append(Vector2(x, y + rng.randf_range(-6.0, 6.0)))
			x += 80.0
		draw_polyline(pts, Color(STONE_DARK.r, STONE_DARK.g, STONE_DARK.b, 0.8), rng.randf_range(6.0, 14.0), true)
		y += rng.randf_range(60.0, 110.0)
	# Embedded stones + glowing seams of the theme colour
	for i in 70:
		var p := Vector2(rng.randf_range(x0 + 40.0, x1 - 40.0), rng.randf_range(CAP + 30.0, 1000.0))
		var r := rng.randf_range(4.0, 12.0)
		draw_circle(p, r + 2.0, OUTLINE)
		draw_circle(p, r, PEBBLE_LIGHT.darkened(clampf(p.y / 1400.0, 0.0, 0.6)))
	for i in 10:
		var p := Vector2(rng.randf_range(x0 + 60.0, x1 - 60.0), rng.randf_range(CAP + 60.0, 700.0))
		var line := PackedVector2Array([p])
		for j in 4:
			p += Vector2(rng.randf_range(-24.0, 24.0), rng.randf_range(14.0, 30.0))
			line.append(p)
		draw_polyline(line, Color(CRACK.r, CRACK.g, CRACK.b, 0.25), CRACK_WIDTH * 3.0, true)
		draw_polyline(line, CRACK, CRACK_WIDTH, true)


## Elevator platform: yellow/black hazard stripes on the lip + steel cables up the shaft.
func _draw_elevator_extras() -> void:
	var hw := width * 0.5
	var y0 := CAP + 2.0
	var x := -hw + 14.0
	while x < hw - 30.0:
		draw_colored_polygon(PackedVector2Array([Vector2(x, y0), Vector2(x + 18.0, y0), Vector2(x + 30.0, y0 + 16.0), Vector2(x + 12.0, y0 + 16.0)]), Color(0.95, 0.75, 0.1))
		x += 36.0
	draw_line(Vector2(-hw + 8, y0 + 17.0), Vector2(hw - 8, y0 + 17.0), OUTLINE, 3.0)
	for cx in [-hw * 0.62, -hw * 0.2, hw * 0.2, hw * 0.62]:
		draw_line(Vector2(cx, 0), Vector2(cx, -2200), OUTLINE, 9.0)
		draw_line(Vector2(cx, 0), Vector2(cx, -2200), Color(0.45, 0.45, 0.5), 4.0)
		draw_circle(Vector2(cx, -4), 9.0, Color(0.3, 0.3, 0.33))
		draw_arc(Vector2(cx, -4), 9.0, 0.0, TAU, 12, OUTLINE, 3.0)


func _outline(pts: PackedVector2Array, w: float) -> void:
	var closed := pts.duplicate()
	closed.append(pts[0])
	draw_polyline(closed, OUTLINE, w, true)
