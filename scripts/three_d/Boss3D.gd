class_name Boss3D
extends Node3D
## 3D MODELS OF THE BOSSES for the 3D cutscenes (no 2D characters in cutscenes). Every Story
## boss / mini-boss / extension boss, built from rounded shapes with the thick black outline in
## its own colours, with a little life (breathing, swaying, legs, wings, orbiting things).
## Humanoids use the Hero3D rig (make_custom); the rest (spiders, serpent, beast, moth, coffin)
## are built here.
##
##   Boss3D.make(parent, id, pos, height)   id = the Story enemy id (StoryLevels)
## Origin = feet, faces +x; `height` = how tall it stands in the 3D world.

## How each boss ENTERS its level-intro cutscene: "rise" (only Blasphemy Caeser, out of the
## magma), "fall" (drops from the sky), "walk" (walks in), "there" (already standing there,
## revealed by a flash of light).
const ENTRANCE := {
	"blasphemy_caeser": "rise",
	"blinded_lord": "walk", "executor": "walk", "forge_father": "walk", "brothers": "walk", "needle": "walk",
	"void_massacre": "fall", "forge_mother": "fall", "animal_lord": "fall", "false_god": "fall", "the_sun": "fall",
	"enlightened_one": "fall", "void_horrid": "fall",
	"architect_chorus": "there", "arch_golem": "there", "saint_golem": "there", "mother_nature": "there", "satan": "there",
	"first_prime": "there", "caeser_grave": "there", "rad_chorus": "there",
}

var humans: Array[Hero3D] = []         # The humanoid rigs inside (poses go to them)
var _anims: Array[Callable] = []
var _t := 0.0


static func entrance(id: String) -> String:
	return String(ENTRANCE.get(id, "there"))


## Pose for the humanoid parts ("walk" while walking in, "menace" when there).
func set_pose(p: String) -> void:
	for h in humans:
		h.pose = p


static func make(parent: Node3D, id: String, pos: Vector3, height: float = 6.0) -> Boss3D:
	var b := Boss3D.new()
	b.position = pos
	parent.add_child(b)
	Three.char_mode = true
	var natural := b._build(id)                                   # Its own height in model units
	Three.char_mode = false
	b.scale = Vector3.ONE * (height / maxf(natural, 0.1))
	return b


func face(dir: Vector3) -> void:
	if dir.length() > 0.001:
		rotation.y = atan2(-dir.z, dir.x)


func _process(delta: float) -> void:
	_t += delta
	for fn in _anims:
		fn.call(_t)


func _on(fn: Callable) -> void:
	_anims.append(fn)


# ============================================================
# HELPERS
# ============================================================
func _human(cfg: Dictionary, pose: String = "menace") -> Hero3D:
	var h := Hero3D.make_custom(self, cfg, Vector3.ZERO, pose)
	h.speed = 0.8
	humans.append(h)
	return h


## A spider: body + head + `legs` legs per side (animated), many white eyes.
func _spider(at: Vector3, size: float, legs: int, body_col: Color, sheen: Color, eyes: int) -> Node3D:
	var root := Node3D.new()
	root.position = at
	add_child(root)
	var abd := Three.ball(root, 0.9 * size, Vector3(-0.9 * size, 1.1 * size, 0), body_col, 0.0, 0.04)
	abd.scale = Vector3(1.3, 0.9, 1.0)
	Three.ball(root, 0.3 * size, Vector3(-1.0 * size, 1.5 * size, 0), sheen, 0.6, 0.0)        # Violet sheen
	var hd := Three.ball(root, 0.55 * size, Vector3(0.35 * size, 1.0 * size, 0), body_col, 0.0, 0.04)
	for e in eyes:                                                                             # Cluster of white eyes
		var a := float(e) * 2.4
		Three.ball(hd, 0.07, Vector3(0.45, 0.15 + 0.25 * sin(a), cos(a) * 0.3), Color(1, 1, 1), 2.5, 0.0)
	for side: float in [-1.0, 1.0]:
		for i in legs:
			var hip := Node3D.new()
			hip.position = Vector3((0.4 - float(i) * 0.25) * size, 1.15 * size, side * 0.4 * size)
			root.add_child(hip)
			var up := Three.cyl(hip, 0.07 * size, 1.3 * size, Vector3(0, 0.45 * size, side * 0.45 * size), body_col.lightened(0.1), 0.0, 0.03, 6)
			up.rotation = Vector3(side * 0.9, 0, 0)
			var low := Three.cyl(hip, 0.06 * size, 1.6 * size, Vector3(0, -0.2 * size, side * 1.25 * size), body_col.lightened(0.1), 0.0, 0.03, 6)
			low.rotation = Vector3(-side * 0.35, 0, 0)
			var ph := float(i) * 1.3 + (0.0 if side > 0.0 else PI)
			_on(func(t: float) -> void: hip.rotation.z = sin(t * 3.0 + ph) * 0.18)
	_on(func(t: float) -> void: abd.scale = Vector3(1.3, 0.9 + 0.04 * sin(t * 2.0), 1.0))
	return root


## A floating, slowly turning ring of glowing orbs (Mother Nature, The Sun...).
func _orbit(center: Vector3, r: float, cols: Array, orb_r: float, spd: float) -> void:
	var piv := Node3D.new()
	piv.position = center
	add_child(piv)
	for i in cols.size():
		var a := float(i) * TAU / float(cols.size())
		Three.ball(piv, orb_r, Vector3(cos(a) * r, sin(a * 2.0) * 0.3, sin(a) * r), cols[i], 2.5, 0.02)
	_on(func(t: float) -> void: piv.rotation.y = t * spd)


## A giant hammer RESTING ON THE SHOULDER (never through the floor). side = which shoulder.
func _hammer(h: Hero3D, metal: Color, glow: Color = Color(0, 0, 0)) -> void:
	var piv := Node3D.new()
	piv.position = Vector3(-0.05, 1.05, 0.62)
	piv.rotation.z = 0.9                                       # Leaning back over the shoulder
	h.body.add_child(piv)
	Three.cyl(piv, 0.06, 1.7, Vector3(0, 0.1, 0), Color(0.35, 0.22, 0.12), 0.0, 0.02, 6)
	Three.box(piv, Vector3(0.45, 0.4, 0.7), Vector3(0, 0.95, 0), metal, 0.0 if glow.a == 0.0 else 0.6, 0.03)


# ============================================================
# THE BOSSES  (each returns its natural height in model units)
# ============================================================
func _build(id: String) -> float:
	match id:
		"blinded_lord":
			# A gaunt, hunched ALCHEMIST: long stained coat, bandaged blindfold, a giant jug of
			# glowing chemicals in one hand and a belt of bubbling vials
			var coat := Color(0.30, 0.26, 0.22)
			var skin := Color(0.80, 0.74, 0.64)
			var h := _human({"leg": Color(0.22, 0.19, 0.17), "arm": coat, "chest": Color(0.36, 0.40, 0.30),
				"belt": Color(0.35, 0.25, 0.15), "hand": skin, "head": "plain", "head_col": skin, "limb": 0.75, "bulk": 0.8})
			h.hunch = 0.4
			var tails := Three.cone(h.body, 0.42, 1.1, Vector3(-0.05, -0.15, 0), coat, 0.0, 0.03, 10)     # Long coat tails
			tails.scale = Vector3(1.0, 1.0, 1.15)
			var band := Three.ring(h.head, 0.21, 0.27, Vector3(0.02, 0.04, 0), Color(0.92, 0.9, 0.82), 0.0, 0.02)   # Blindfold
			band.scale = Vector3(1, 0.7, 1)
			for k in 3:                                                 # Loose bandage ends at the back
				var tail := Three.box(h.head, Vector3(0.04, 0.25, 0.06), Vector3(-0.27, -0.05 - float(k) * 0.08, -0.05 + float(k) * 0.05), Color(0.92, 0.9, 0.82), 0.0, 0.0)
				tail.rotation.z = 0.4
			Three.ball(h.head, 0.07, Vector3(0.24, -0.08, 0), skin.darkened(0.15), 0.0, 0.0)               # Long nose
			var jug := Three.cyl(h.hands[0], 0.26, 0.65, Vector3(0.2, -0.55, 0), Color(0.45, 1.0, 0.35, 0.85), 1.5, 0.03, 12)   # The giant jug
			Three.cyl(h.hands[0], 0.11, 0.18, Vector3(0.2, -0.16, 0), Color(0.55, 0.45, 0.3), 0.0, 0.02, 8)   # Its neck
			_on(func(t: float) -> void: jug.scale = Vector3(1.0, 1.0 + 0.03 * sin(t * 6.0), 1.0))
			for k in 6:                                                 # Belt of bubbling vials
				var a := float(k) * 0.5 - 1.2
				Three.cyl(h.body, 0.05, 0.14, Vector3(cos(a) * 0.3, 0.12, sin(a) * 0.3), [Color(0.5, 1.0, 0.3), Color(0.3, 0.8, 1.0), Color(1.0, 0.5, 0.2)][k % 3], 2.5, 0.0, 6)
			return 2.0
		"architect_chorus", "rad_chorus":
			var rad := id == "rad_chorus"
			var iron := Color(0.30, 0.31, 0.34) if not rad else Color(0.26, 0.30, 0.24)
			var glow := Color(0.4, 0.95, 1.0) if not rad else Color(0.5, 1.0, 0.3)
			var h2 := _human({"leg": iron, "arm": iron, "chest": iron, "belt": iron.darkened(0.3), "hand": iron.lightened(0.15),
				"head": "plain", "head_col": iron.lightened(0.1), "eye": glow, "bulk": 1.5, "limb": 1.6})
			Three.prism(h2.head, Vector3(0.55, 0.5, 0.55), Vector3(0, 0.45, 0), iron.lightened(0.2))         # Cathedral spire
			for k in 3:                                                 # Three singing grille-mouths / masks
				Three.box(h2.head, Vector3(0.06, 0.12, 0.1), Vector3(0.22, -0.05, -0.15 + float(k) * 0.15), Color(0.05, 0.05, 0.05), 0.0, 0.0)
			Three.ball(h2.body, 0.2, Vector3(0.35, 0.5, 0), glow, 3.5, 0.02)                                 # The core
			for side: float in [-1.0, 1.0]:                             # Organ-pipe shoulders
				for k in 3:
					Three.cyl(h2.body, 0.06, 0.6 + float(k) * 0.15, Vector3(-0.1, 1.1 + float(k) * 0.07, side * (0.45 + float(k) * 0.08)), Color(0.75, 0.62, 0.3), 0.0, 0.02, 8)
			for hnd in h2.hands:                                        # Giant metal hands
				Three.box(hnd, Vector3(0.45, 0.4, 0.4), Vector3(0.05, -0.5, 0), iron.lightened(0.2), 0.0, 0.03)
			if rad:
				for k in 6:
					Three.box(h2.body, Vector3(0.02, 0.5, 0.04), Vector3(0.3, 0.2 + float(k) * 0.12, -0.3 + float(k) * 0.12), glow, 3.0, 0.0)
			return 2.4
		"blasphemy_caeser":
			var scale_c := Color(0.42, 0.42, 0.45)
			for i in 22:                                                # The coiled serpent body
				var a := float(i) * 0.5
				var r := 1.6 - float(i) * 0.04
				Three.ball(self, 0.55 - float(i) * 0.008, Vector3(cos(a) * r, 0.5 + float(i) * 0.12, sin(a) * r), scale_c if i % 2 == 0 else scale_c.darkened(0.15), 0.0, 0.035)
			var neck := Node3D.new()
			neck.position = Vector3(0.6, 3.0, 0)
			add_child(neck)
			for k in 5:
				Three.ball(neck, 0.45, Vector3(float(k) * 0.12, float(k) * 0.35, 0), scale_c, 0.0, 0.03)
			var face_n := Three.ball(neck, 0.5, Vector3(0.75, 1.9, 0), Color(0.66, 0.60, 0.58), 0.0, 0.035)  # The face in the neck
			face_n.scale = Vector3(1.0, 1.1, 0.9)
			var laurel := Three.ring(neck, 0.4, 0.5, Vector3(0.7, 2.3, 0), Color(1.0, 0.55, 0.1), 3.0, 0.0)  # Burning laurel
			laurel.scale = Vector3(1, 0.4, 1)
			for e: float in [-0.15, 0.15]:
				Three.ball(neck, 0.06, Vector3(1.2, 1.95, e), Color(1.0, 0.6, 0.15), 3.0, 0.0)
			var arm := Three.cyl(neck, 0.13, 1.4, Vector3(1.3, 1.2, 0.4), Color(0.66, 0.60, 0.58), 0.0, 0.03, 8)
			arm.rotation.z = -0.9
			var blade := Three.prism(neck, Vector3(0.3, 2.6, 0.12), Vector3(2.1, 2.2, 0.45), Color(0.72, 0.26, 0.26), 0.3, 0.03)   # Blasphemy Blade
			blade.rotation.z = -0.4
			_on(func(t: float) -> void: neck.rotation.z = sin(t * 1.2) * 0.08)
			return 5.2
		"forge_mother", "forge_father":
			var father := id == "forge_father"
			var armor := Color(0.24, 0.24, 0.27) if not father else Color(0.10, 0.09, 0.09)
			var fire := Color(1.0, 0.5, 0.12)
			var h3 := _human({"leg": armor, "arm": armor, "chest": armor, "belt": Color(0.75, 0.55, 0.25), "hand": armor.lightened(0.1),
				"head": "plain", "head_col": armor.lightened(0.1), "eye": fire, "bulk": 1.6 if not father else 1.8, "limb": 1.5 if not father else 1.7})
			var furnace := Three.ball(h3.body, 0.2, Vector3(0.36, 0.5, 0), fire, 3.0, 0.02)                 # Furnace in the chest
			Three.box(h3.body, Vector3(0.06, 0.06, 0.5), Vector3(0.4, 0.72, 0), Color(0.75, 0.55, 0.25), 0.0, 0.02)   # Furnace grate
			for side: float in [-1.0, 1.0]:                             # Brass shoulder plates
				var pl := Three.ball(h3.body, 0.24, Vector3(0, 0.9, side * 0.55), Color(0.75, 0.55, 0.25), 0.0, 0.03)
				pl.scale = Vector3(1, 0.6, 1)
			_on(func(t: float) -> void: furnace.scale = Vector3.ONE * (1.0 + 0.12 * sin(t * 5.0)))
			_hammer(h3, Color(0.45, 0.45, 0.5) if not father else Color(0.2, 0.18, 0.18), fire)
			if father:
				Three.box(h3.head, Vector3(0.1, 0.1, 0.32), Vector3(0.22, -0.05, 0), fire, 3.0, 0.0)          # Furnace face
				for z: float in [-0.2, 0.2]:                             # Chimneys on its back
					Three.cyl(h3.body, 0.09, 0.8, Vector3(-0.35, 1.3, z), Color(0.15, 0.13, 0.13), 0.0, 0.02, 8)
				for k in 8:                                              # Molten cracks
					Three.box(h3.body, Vector3(0.02, 0.3, 0.03), Vector3(0.28, 0.2 + float(k) * 0.1, -0.25 + float(k) * 0.07), fire, 3.0, 0.0)
			return 2.4
		"arch_golem", "saint_golem":
			var saint := id == "saint_golem"
			var stone := Color(0.55, 0.53, 0.50) if not saint else Color(0.85, 0.82, 0.74)
			var rune := Color(0.3, 0.75, 1.0) if not saint else Color(1.0, 0.8, 0.3)
			var h4 := _human({"leg": stone, "arm": stone, "chest": stone, "belt": Color(0.9, 0.92, 0.95), "hand": stone.darkened(0.1),
				"head": "plain", "head_col": stone, "eye": rune, "bulk": 1.8, "limb": 1.9})
			for side: float in [-1.0, 1.0]:                             # Metal plates
				Three.box(h4.body, Vector3(0.12, 0.3, 0.3), Vector3(0.3, 0.75, side * 0.2), Color(0.92, 0.94, 0.96) if saint else Color(0.85, 0.9, 0.85))
			var hexm := Three.cyl(h4.body, 0.17, 0.05, Vector3(0.36, 0.45, 0), Color(0.22, 0.86, 0.28) if not saint else Color(0.18, 0.68, 1.0), 2.5, 0.02, 6)
			for k in 5:                                                 # Glowing runes
				Three.box(h4.body, Vector3(0.02, 0.18, 0.05), Vector3(0.33, 0.15 + float(k) * 0.15, -0.3 + float(k) * 0.15), rune, 3.0, 0.0)
			for hnd in h4.hands:                                        # Fists as big as a man
				Three.ball(hnd, 0.32, Vector3(0.05, -0.5, 0), stone.darkened(0.1), 0.0, 0.03)
			return 2.4
		"void_massacre":
			_spider(Vector3.ZERO, 1.0, 8, Color(0.06, 0.04, 0.08), Color(0.55, 0.3, 0.9), 16)
			return 2.0
		"void_horrid":
			for k in 3:                                                 # Three of them
				_spider(Vector3(float(absi(k - 1)) * -1.6, 0, float(k - 1) * 3.6), 0.6, 4, Color(0.06, 0.04, 0.08), Color(0.6, 0.35, 0.95), 8)
			return 1.6
		"needle":
			# A small child in a long PLUM COAT, cracked porcelain face with a stitched smile, braids
			# of silver silk, and a NEEDLE twice her size trailing silk thread
			var plum := Color(0.45, 0.20, 0.38)
			var porcelain := Color(0.94, 0.92, 0.88)
			var h5 := _human({"leg": Color(0.25, 0.12, 0.2), "arm": plum, "chest": plum, "belt": Color(0.3, 0.12, 0.25),
				"hand": porcelain, "head": "plain", "head_col": porcelain, "eye": Color(0.1, 0.05, 0.1), "bulk": 0.75, "limb": 0.7}, "idle")
			h5.scale = Vector3.ONE * 0.72
			Three.cone(h5.body, 0.45, 1.0, Vector3(0, -0.2, 0), plum, 0.0, 0.03, 12)                        # Long coat
			h5.head.scale = Vector3.ONE * 1.25                                                              # Child: big head
			var smile := Three.box(h5.head, Vector3(0.02, 0.02, 0.16), Vector3(0.23, -0.1, 0), Color(0.5, 0.1, 0.15), 0.0, 0.0)   # Stitched smile
			smile.rotation.x = 0.0
			for k in 4:
				Three.box(h5.head, Vector3(0.02, 0.06, 0.01), Vector3(0.235, -0.1, -0.06 + float(k) * 0.04), Color(0.2, 0.05, 0.08), 0.0, 0.0)
			var crack := Three.box(h5.head, Vector3(0.015, 0.14, 0.015), Vector3(0.22, 0.1, 0.08), Color(0.3, 0.3, 0.32), 0.0, 0.0)   # Crack
			crack.rotation.x = 0.5
			for z: float in [-0.2, 0.2]:                                 # Silver silk braids
				Three.cyl(h5.head, 0.05, 0.75, Vector3(-0.12, -0.35, z), Color(0.85, 0.88, 0.95), 0.6, 0.02, 6)
			var needle := Three.cyl(h5.hands[0], 0.05, 3.2, Vector3(0.45, 0.75, 0), Color(0.85, 0.87, 0.92), 0.6, 0.02, 6)  # Twice her size (held up)
			needle.rotation.z = -0.45
			Three.cone(needle, 0.05, 0.3, Vector3(0, 1.75, 0), Color(0.9, 0.92, 0.96), 0.6, 0.0, 6)        # Sharp tip
			var thread := Three.cyl(needle, 0.008, 2.0, Vector3(0.3, -1.6, 0.2), Color(0.95, 0.95, 1.0), 1.0, 0.0, 4)   # Silk thread
			thread.rotation.z = 0.8
			return 1.8
		"brothers":
			for k in 2:                                                 # Black knight + white knight
				var dark := k == 0
				var main := Color(0.1, 0.1, 0.12) if dark else Color(0.92, 0.92, 0.95)
				var trim := Color(0.92, 0.92, 0.95) if dark else Color(0.1, 0.1, 0.12)
				var hb := Hero3D.make_custom(self, {"leg": main, "arm": main, "chest": main, "belt": trim, "hand": trim,
					"head": "helm", "head_col": main}, Vector3(0, 0, -0.9 + float(k) * 1.8), "menace")
				humans.append(hb)
				# Half-sun (black knight) / half-moon (white knight) visor
				var vis := Three.cyl(hb.head, 0.17, 0.04, Vector3(0.22, 0.02, 0), Color(1.0, 0.82, 0.3) if dark else Color(0.75, 0.82, 0.98), 2.0, 0.015, 16)
				vis.rotation.z = PI * 0.5
				Three.box(hb.head, Vector3(0.05, 0.17, 0.36), Vector3(0.24, -0.08, 0), main, 0.0, 0.0)          # ...cut in half
				for side: float in [-1.0, 1.0]:                          # Trim on the shoulders
					Three.ball(hb.body, 0.12, Vector3(0, 0.86, side * 0.38), trim, 0.0, 0.02)
				var bl := Three.prism(hb.hands[0], Vector3(0.09, 1.4, 0.04), Vector3(0.62, -0.75, 0), Color(0.82, 0.84, 0.9), 0.2, 0.025)   # Long curved blade, forward-down
				bl.rotation.z = -PI * 0.7
			return 2.2
		"animal_lord":
			var tan := Color(0.72, 0.55, 0.32)
			var bod := Three.cap_h(self, 0.6, 2.2, Vector3(0, 1.2, 0), tan)                                  # Lion body
			var mane := Three.ball(self, 0.65, Vector3(1.1, 1.65, 0), Color(0.45, 0.28, 0.12), 0.0, 0.035)
			mane.scale = Vector3(0.8, 1.0, 1.0)
			Three.ball(self, 0.42, Vector3(1.5, 1.7, 0), tan, 0.0, 0.03)                                     # Head
			for z: float in [-0.3, 0.3]:                                 # Ram horns
				var horn := Three.ring(self, 0.12, 0.2, Vector3(1.45, 2.05, z), Color(0.85, 0.8, 0.68), 0.0, 0.02)
				horn.rotation.x = PI * 0.5
				Three.ball(self, 0.06, Vector3(1.85, 1.75, z * 0.5), Color(1.0, 0.7, 0.1), 3.0, 0.0)          # Eyes
			for k in 4:                                                 # Legs (bear forearms at the front, with huge claws)
				var front := k < 2
				var lz := -0.35 + float(k % 2) * 0.7
				Three.cyl(self, 0.2 if front else 0.15, 1.1, Vector3(0.7 if front else -0.7, 0.55, lz), Color(0.35, 0.22, 0.14) if front else tan, 0.0, 0.03, 8)
				if front:
					for c in 3:
						var claw := Three.cone(self, 0.05, 0.25, Vector3(0.88, 0.08, lz - 0.1 + float(c) * 0.1), Color(0.92, 0.9, 0.8), 0.0, 0.0, 6)
						claw.rotation.z = -PI * 0.5
			var wings: Array = []
			for z: float in [-1.0, 1.0]:                                 # Ragged bat wings
				var wpiv := Node3D.new()
				wpiv.position = Vector3(0.2, 1.7, z * 0.45)
				add_child(wpiv)
				var w := Three.prism(wpiv, Vector3(1.6, 1.4, 0.05), Vector3(-0.3, 0.6, z * 0.6), Color(0.25, 0.15, 0.18), 0.0, 0.03)
				w.rotation.x = z * 0.4
				wings.append([wpiv, z])
			for i in 8:                                                 # Crocodile tail + scorpion barb
				Three.ball(self, 0.22 - float(i) * 0.015, Vector3(-1.2 - float(i) * 0.25, 1.1 + float(i) * 0.12, 0), Color(0.3, 0.45, 0.25), 0.0, 0.025)
			var barb := Three.cone(self, 0.12, 0.4, Vector3(-3.1, 2.2, 0), Color(0.15, 0.12, 0.1))
			_on(func(t: float) -> void:
				bod.scale = Vector3(1, 1.0 + 0.04 * sin(t * 2.0), 1)
				for e in wings:
					(e[0] as Node3D).rotation.x = float(e[1]) * sin(t * 2.5) * 0.3)
			return 2.6
		"executor":
			var h6 := _human({"leg": Color(0.15, 0.13, 0.13), "arm": Color(0.55, 0.42, 0.35), "chest": Color(0.42, 0.28, 0.16),
				"belt": Color(0.2, 0.18, 0.18), "hand": Color(0.15, 0.13, 0.13), "head": "hood", "head_col": Color(0.1, 0.1, 0.12),
				"eye": Color(0.7, 0.35, 1.0), "bulk": 1.4, "limb": 1.3})
			for k in 2:                                                 # Chains across the chest
				var ch := Three.ring(h6.body, 0.3, 0.34, Vector3(0.05, 0.5 + float(k) * 0.2, 0), Color(0.5, 0.5, 0.55), 0.0, 0.0)
				ch.rotation = Vector3(0.6 * (1.0 if k == 0 else -1.0), 0, PI * 0.5)
			var apron := Three.box(h6.body, Vector3(0.06, 1.1, 0.5), Vector3(0.3, 0.05, 0), Color(0.45, 0.3, 0.18), 0.0, 0.025)   # Leather apron
			apron.rotation.z = 0.08
			var carry := Node3D.new()                                   # The blade rests on his shoulder
			carry.position = Vector3(-0.05, 1.0, 0.72)
			carry.rotation.z = 1.0
			h6.body.add_child(carry)
			Three.cyl(carry, 0.06, 1.0, Vector3(0, -0.2, 0), Color(0.3, 0.2, 0.12), 0.0, 0.02, 6)
			var blade2 := Three.box(carry, Vector3(1.2, 2.0, 0.08), Vector3(0.3, 1.25, 0), Color(0.55, 0.55, 0.6), 0.0, 0.03)   # Huge grinding blade
			Three.box(blade2, Vector3(1.2, 0.12, 0.1), Vector3(0, 0.95, 0), Color(0.35, 0.35, 0.4), 0.0, 0.0)
			var gear := Three.cyl(blade2, 0.3, 0.12, Vector3(0, 0.2, 0), Color(0.4, 0.4, 0.45), 0.0, 0.02, 10)   # The spinning grinder
			gear.rotation.x = PI * 0.5
			_on(func(t: float) -> void: gear.rotation.y = t * 6.0)
			for k in 8:
				var tooth := Three.cone(blade2, 0.08, 0.2, Vector3(0.62, -0.9 + float(k) * 0.25, 0), Color(0.75, 0.75, 0.8), 0.0, 0.0)
			return 2.4
		"mother_nature":
			var h7 := _human({"leg": Color(0.25, 0.5, 0.22), "arm": Color(0.72, 0.58, 0.45), "chest": Color(0.3, 0.55, 0.25),
				"belt": Color(0.45, 0.3, 0.15), "hand": Color(0.72, 0.58, 0.45), "head": "plain", "head_col": Color(0.78, 0.64, 0.5),
				"eye": Color(0.3, 0.8, 0.3)}, "idle")
			Three.cone(h7.body, 0.7, 1.2, Vector3(0, -0.45, 0), Color(0.25, 0.5, 0.22), 0.0, 0.03)            # Leaf dress
			for k in 7:                                                 # Hair of leaves + branch crown
				Three.ball(h7.head, 0.12, Vector3(-0.1 + sin(float(k)) * 0.1, 0.15 + float(k % 3) * 0.06, -0.24 + float(k) * 0.08), Color(0.3, 0.65, 0.25), 0.0, 0.02)
			_orbit(Vector3(0, 1.4, 0), 1.2, [Color(1.0, 0.45, 0.1), Color(0.3, 0.6, 1.0), Color(0.55, 0.42, 0.25), Color(0.85, 0.95, 1.0)], 0.2, 0.8)
			return 2.2
		"false_god":
			var cloak := Three.cone(self, 1.3, 3.6, Vector3(0, 1.8, 0), Color(0.62, 0.05, 0.08), 0.0, 0.04, 14)   # Crimson cloak
			for k in 9:                                                 # Burning hem
				var a := float(k) * TAU / 9.0
				var fl := Three.cone(self, 0.18, 0.5, Vector3(cos(a) * 1.2, 0.2, sin(a) * 1.2), Color(1.0, 0.45, 0.1), 3.0, 0.0)
				_on(func(t: float) -> void: fl.scale = Vector3(1, 0.7 + 0.4 * absf(sin(t * 6.0 + float(k))), 1))
			var face_f := Three.ball(self, 0.38, Vector3(0.1, 3.7, 0), Color(0.02, 0.0, 0.02), 0.0, 0.04)    # Void face
			face_f.scale = Vector3(0.9, 1.15, 0.9)
			for z: float in [-0.12, 0.12]:
				Three.ball(self, 0.07, Vector3(0.45, 3.75, z), Color(1.0, 0.6, 0.15), 4.0, 0.0)              # Ember eyes
			for z: float in [-1.0, 1.0]:                                 # Burning antlers
				var ant := Three.cyl(self, 0.06, 1.0, Vector3(0, 4.3, z * 0.35), Color(0.25, 0.08, 0.06), 0.0, 0.025, 6)
				ant.rotation.x = z * 0.5
				Three.cone(self, 0.1, 0.3, Vector3(0, 4.85, z * 0.6), Color(1.0, 0.55, 0.12), 3.0, 0.0)
			for z: float in [-1.0, 1.0]:                                 # Long thin arms with flame claws
				var la := Three.cyl(self, 0.07, 1.8, Vector3(0.6, 2.6, z * 0.9), Color(0.12, 0.08, 0.08), 0.0, 0.025, 6)
				la.rotation = Vector3(z * 0.6, 0, -0.5)
			_on(func(t: float) -> void: cloak.scale = Vector3(1.0 + 0.03 * sin(t * 1.5), 1, 1.0 + 0.03 * sin(t * 1.5)))
			return 5.0
		"satan":
			var red := Color(0.72, 0.12, 0.1)
			var h8 := _human({"leg": Color(0.15, 0.08, 0.08), "arm": red, "chest": red, "belt": Color(0.1, 0.05, 0.05),
				"hand": red.darkened(0.2), "head": "plain", "head_col": red, "eye": Color(1.0, 0.85, 0.2), "bulk": 1.5, "limb": 1.4})
			for z: float in [-1.0, 1.0]:                                 # Goat horns
				var horn2 := Three.cone(h8.head, 0.08, 0.5, Vector3(-0.05, 0.3, z * 0.17), Color(0.08, 0.06, 0.06), 0.0, 0.02, 8)
				horn2.rotation = Vector3(z * 0.5, 0, 0.4)
			for k in 5:                                                 # Crown of fire
				Three.cone(h8.head, 0.06, 0.25, Vector3(-0.05, 0.28, -0.14 + float(k) * 0.07), Color(1.0, 0.55, 0.1), 3.0, 0.0)
			for z: float in [-1.0, 1.0]:                                 # Bat wings like a cloak
				var bw := Three.prism(h8.body, Vector3(0.1, 1.6, 1.0), Vector3(-0.4, 0.6, z * 0.55), Color(0.3, 0.05, 0.06), 0.0, 0.03)
				bw.rotation.x = z * 0.25
			var tri := Three.cyl(h8.hands[0], 0.04, 2.4, Vector3(0.05, 0.45, 0), Color(0.3, 0.25, 0.25), 0.0, 0.02, 6)   # Burning trident (held up)
			for k in 3:
				Three.cone(tri, 0.05, 0.3, Vector3(0, 1.25, -0.12 + float(k) * 0.12), Color(1.0, 0.5, 0.1), 2.5, 0.0)
			return 2.4
		"the_sun":
			var bd := Three.cap_h(self, 0.35, 1.4, Vector3(0, 2.0, 0), Color(1.0, 0.98, 0.92), 0.6)        # Soft white body
			bd.rotation.z = 0.0                                         # Upright
			Three.ring(self, 0.25, 0.32, Vector3(0, 2.85, 0), Color(1.0, 0.85, 0.35), 3.0, 0.0)              # Glowing crown
			var wings2: Array = []
			for k in 4:                                                 # Four huge radiant wings with golden eye-spots
				var top := k < 2
				var side := -1.0 if k % 2 == 0 else 1.0
				var wpiv2 := Node3D.new()
				wpiv2.position = Vector3(-0.1, 2.2 if top else 1.8, side * 0.2)
				add_child(wpiv2)
				var wr := 1.3 if top else 0.95
				var wc := Vector3(0, 0.75 if top else -0.5, side * (1.3 if top else 1.0))
				var w2 := Three.ball(wpiv2, wr, wc, Color(1.0, 0.97, 0.88), 1.2, 0.035)
				w2.scale = Vector3(0.08, 1.0, 1.0)
				var rim := Three.ball(wpiv2, wr * 1.06, wc - Vector3(0.02, 0, 0), Color(1.0, 0.82, 0.35), 1.5, 0.0)   # Golden rim
				rim.scale = Vector3(0.05, 1.0, 1.0)
				Three.ball(wpiv2, wr * 0.3, wc + Vector3(0.09, 0.05, side * 0.1), Color(1.0, 0.75, 0.2), 3.0, 0.0)     # Eye-spot
				Three.ball(wpiv2, wr * 0.13, wc + Vector3(0.12, 0.05, side * 0.1), Color(0.35, 0.2, 0.05), 0.0, 0.0)    # ...and its pupil
				wings2.append([wpiv2, side])
			for z: float in [-1.0, 1.0]:                                 # Feathered antennae
				var an := Three.cyl(self, 0.03, 0.8, Vector3(0.2, 3.1, z * 0.15), Color(1.0, 0.95, 0.8), 0.5, 0.0, 4)
				an.rotation = Vector3(z * 0.4, 0, -0.3)
			Three.ball(self, 2.2, Vector3(0, 2.0, 0), Color(1.0, 0.95, 0.75, 0.15), 1.0, 0.0)               # Aura
			_on(func(t: float) -> void:
				position.y = sin(t * 1.5) * 0.15
				for e in wings2:
					(e[0] as Node3D).rotation.x = float(e[1]) * sin(t * 3.0) * 0.25)
			return 3.4
		"first_prime":
			var h9 := _human({"leg": Color(0.95, 0.93, 0.86), "arm": Color(0.95, 0.93, 0.86), "chest": Color(1.0, 0.98, 0.9),
				"belt": Color(1.0, 0.75, 0.2), "hand": Color(1.0, 0.82, 0.3), "head": "helm", "head_col": Color(1.0, 0.82, 0.3), "bulk": 1.2})
			Three.box(h9.body, Vector3(0.08, 1.6, 0.7), Vector3(-0.32, 0.1, 0), Color(0.88, 0.86, 0.8), 0.0, 0.03)       # Cape
			var staff := Three.cyl(h9.hands[1], 0.04, 2.4, Vector3(0.05, 0.5, 0), Color(0.95, 0.85, 0.55), 0.0, 0.02, 6)  # Holy staff
			Three.ball(staff, 0.16, Vector3(0, 1.3, 0), Color(1.0, 0.95, 0.7), 4.0, 0.0)
			Three.ring(staff, 0.18, 0.24, Vector3(0, 1.3, 0), Color(1.0, 0.82, 0.3), 2.0, 0.0)
			var hb2 := Three.prism(h9.hands[0], Vector3(0.12, 1.2, 0.05), Vector3(0.55, -0.7, 0), Color(1.0, 0.86, 0.4), 1.0, 0.025)   # Holy Blade, forward-down
			hb2.rotation.z = -PI * 0.68
			return 2.2
		"enlightened_one":
			Hero3D.make(self, "enlightened", Vector3.ZERO, "idle")
			return 2.2
		"caeser_grave":
			Three.box(self, Vector3(1.0, 0.3, 2.6), Vector3(0, 0.15, 0), Color(0.45, 0.43, 0.40), 0.0, 0.035)    # Broken stone coffin
			Three.box(self, Vector3(1.0, 2.6, 0.2), Vector3(-0.4, 1.4, 0), Color(0.45, 0.43, 0.40), 0.0, 0.035)
			var lid := Three.box(self, Vector3(0.15, 2.4, 1.1), Vector3(0.9, 0.56, 2.25), Color(0.5, 0.48, 0.45), 0.0, 0.035)   # The lid, fallen beside it
			lid.rotation = Vector3(0, 0, -1.2)
			var hc := Hero3D.make_custom(self, {"leg": Color(0.42, 0.48, 0.38), "arm": Color(0.42, 0.48, 0.38), "chest": Color(0.36, 0.42, 0.33),
				"belt": Color(0.3, 0.32, 0.28), "hand": Color(0.42, 0.48, 0.38), "head": "skull", "head_col": Color(0.88, 0.85, 0.75)}, Vector3(0.08, 0.3, 0), "idle")
			humans.append(hc)
			hc.hunch = -0.2
			for k in 4:                                                 # Exposed ribs
				var rib := Three.ring(hc.body, 0.22, 0.25, Vector3(0.05, 0.35 + float(k) * 0.12, 0), Color(0.85, 0.82, 0.72), 0.0, 0.0)
				rib.rotation.z = PI * 0.5
				rib.scale = Vector3(1, 1, 0.8)
			Three.ring(hc.head, 0.18, 0.24, Vector3(0, 0.16, 0), Color(0.9, 0.7, 0.2), 0.5, 0.02)            # Cracked golden crown
			for k in 3:                                                 # Serpents writhing out of its chest
				var sp := Node3D.new()
				sp.position = Vector3(0.3, 0.6, -0.2 + float(k) * 0.2)
				hc.body.add_child(sp)
				for i in 5:
					Three.ball(sp, 0.07, Vector3(float(i) * 0.12, sin(float(i)) * 0.1, 0), Color(0.3, 0.5, 0.25), 0.0, 0.015)
				_on(func(t: float) -> void: sp.rotation.z = sin(t * 4.0 + float(k)) * 0.5)
			return 2.8
	# Anything else: a generic hulking figure in the boss's tile colour
	_human({"leg": Color(0.3, 0.3, 0.35), "arm": Color(0.3, 0.3, 0.35), "chest": Color(0.4, 0.35, 0.4), "head": "hood",
		"head_col": Color(0.2, 0.2, 0.25), "eye": Color(1, 0.3, 0.2), "bulk": 1.3})
	return 2.2
