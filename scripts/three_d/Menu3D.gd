class_name Menu3D
extends RefCounted
## 3D MENU BACKGROUND (every menu that uses ArenaBackground: Main Menu, Character Select,
## Pre-fight, Settings, Map Catalogue, Achievements). A floating island ARENA high in the sky:
## a round stone platform ringed by pillars, the glowing HEXAGON towers behind it, floating rocks
## and crystals, drifting clouds - the camera slowly circles it. On the Main Menu / Pre-fight
## your fighter and the opponent stand on the platform (live billboards of their art).

const SKY_TOP := Color(0.22, 0.45, 0.82)
const HORIZON := Color(0.99, 0.87, 0.70)
const STONE := Color(0.62, 0.64, 0.74)
const HEX := Color(0.53, 0.55, 0.80)
const GLOW := Color(0.45, 0.95, 1.0)


## Roster ids that have a real 3D model (Hero3D); everyone else is a live 2D billboard.
const MODELS := {"warrior": "warrior", "architect": "architect", "anti": "anti", "enlightened": "enlightened"}


## A fighter on the platform: 3D model when there is one, else their 2D art as a billboard.
static func _fighter(st: Stage3D, entry: Dictionary, pos: Vector3, right_side: bool) -> void:
	var id := String(entry.get("id", ""))
	if MODELS.has(id):
		var h := Hero3D.make(st, String(MODELS[id]), pos)
		h.face(Vector3.LEFT if right_side else Vector3.RIGHT)        # They face each other
		h.scale = Vector3.ONE * 1.15
		return
	var b := Three.roster(st, entry["art"], pos, 2.6)
	var pp := Three.painter_of(b)
	if pp != null and right_side:
		pp.flip = true


## Builds the 3D background into `layer` (an ArenaBackground). dim = dark overlay 0..1.
static func build(layer: CanvasLayer, dim: float, fighters: bool) -> Stage3D:
	var st := Three.view(layer)
	st.sky(SKY_TOP, HORIZON, Color(0.32, 0.36, 0.55))
	st.fog(Color(0.75, 0.80, 0.92), 0.008)
	st.sun(Vector3(-35, 35, 0), Color(1.0, 0.95, 0.85), 1.25)
	# The floating arena island
	Three.cyl(st, 9.0, 1.6, Vector3(0, 0, 0), STONE, 0.0, 0.06, 32)
	Three.cyl(st, 7.0, 0.1, Vector3(0, 0.85, 0), Color(0.72, 0.74, 0.84), 0.0, 0.0, 32)
	var under := Three.cone(st, 9.0, 9.0, Vector3(0, -5.6, 0), Color(0.40, 0.42, 0.55), 0.0, 0.06, 10)
	under.rotation = Vector3(PI, 0, 0)
	for i in 10:                                             # Ring of pillars with glowing caps
		var a := float(i) * TAU / 10.0
		var p := Vector3(cos(a) * 8.0, 0, sin(a) * 8.0)
		Three.cyl(st, 0.45, 4.5, p + Vector3(0, 3.0, 0), Color(0.78, 0.80, 0.88))
		Three.cyl(st, 0.7, 0.4, p + Vector3(0, 5.4, 0), HEX, 0.0, Three.OUTLINE, 6)
		Three.ball(st, 0.25, p + Vector3(0, 5.9, 0), GLOW, 2.5, 0.0)
	# The HEXAGON towers in the distance
	for i in 6:
		var a2 := PI * 0.9 + float(i) * 0.25
		var r := 34.0 + float(i % 2) * 8.0
		var h := 16.0 + float((i * 7) % 3) * 6.0
		var tp := Vector3(cos(a2) * r, h * 0.5 - 6.0, sin(a2) * r)
		Three.cyl(st, 2.6, h, tp, HEX, 0.0, 0.08, 6)
		Three.cyl(st, 3.2, 0.8, tp + Vector3(0, h * 0.5, 0), HEX.darkened(0.2), 0.0, 0.08, 6)
		for k in 4:
			Three.box(st, Vector3(0.8, 0.8, 0.1), tp + Vector3(0, -h * 0.3 + float(k) * h * 0.18, 2.6), GLOW, 2.0, 0.0)
	# Floating rocks + spinning crystals around the island
	var rng := RandomNumberGenerator.new()
	rng.seed = 1337
	for i in 10:
		var a3 := rng.randf() * TAU
		var p3 := Vector3(cos(a3) * rng.randf_range(14.0, 24.0), rng.randf_range(-3.0, 6.0), sin(a3) * rng.randf_range(14.0, 24.0))
		var rk := Three.rock(st, rng.randf_range(0.8, 2.0), p3, Color(0.46, 0.49, 0.63), i)
		var c := Three.prism(st, Vector3(0.6, 1.4, 0.6), p3 + Vector3(0, 2.4, 0), GLOW, 1.8)
		st.animate(func(t: float) -> void:
			rk.position.y = p3.y + sin(t * 0.6 + float(i)) * 0.5
			c.position.y = p3.y + 2.4 + sin(t * 0.6 + float(i)) * 0.5
			c.rotation.y = t * 1.2)
	# Clouds drifting by
	for i in 12:
		var cl := Three.ball(st, rng.randf_range(2.5, 4.5), Vector3(rng.randf_range(-50.0, 50.0), rng.randf_range(-8.0, 4.0), rng.randf_range(-50.0, 50.0)), Color(1, 1, 1, 0.9), 0.2, 0.0)
		cl.scale = Vector3(1.8, 0.6, 1.0)
		var cp := cl.position
		st.animate(func(t: float) -> void: cl.position.x = fmod(cp.x + t * 1.5 + 60.0, 120.0) - 60.0)
	# Your fighter and the opponent on the platform
	if fighters:
		_fighter(st, CharacterRoster.selected(), Vector3(-2.2, 0.9, 0), false)
		_fighter(st, CharacterRoster.opponent(), Vector3(2.2, 0.9, 0), true)
	# The camera slowly circles the island
	st.animate(func(t: float) -> void:
		var a4 := 0.6 + t * 0.06
		st.camera.position = Vector3(sin(a4) * 18.0, 5.5 + sin(t * 0.2) * 0.8, cos(a4) * 18.0)
		st.camera.look_at(Vector3(0, 2.0, 0), Vector3.UP))
	if dim > 0.0:                                                # Darken under the menu buttons
		var shade := ColorRect.new()
		shade.color = Color(0, 0, 0, dim)
		shade.mouse_filter = Control.MOUSE_FILTER_IGNORE
		shade.set_anchors_and_offsets_preset(Control.PRESET_FULL_RECT)
		layer.add_child(shade)
	return st
