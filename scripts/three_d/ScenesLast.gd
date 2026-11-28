class_name ScenesLast
extends RefCounted
## THE LAST STRETCH's 3D CUTSCENES (StoryCutscene -> Scenes3D -> here), lore by the user (2026-11-28):
##   ls_capture   (end of 142) Halcyon: the three walk into the advanced Stormist town, the people gather,
##                the guards close in, storm-rods knock them down -> three cells.
##   ls_timestop  (end of 147, "HERE you do the cutscene") the Architect opens his eyes in his cell and
##                STOPS TIME: rain hangs in the air, the bars fly off, he walks through the frozen guards
##                and tears their limbs off, sparks a fire in the square under the Storm's spiral - and
##                when time comes back, HALCYON BURNS.
##   ls_free      (148, after the king) he comes back to the cells and pulls the Warrior and the Nightmare
##                Lord out.
##   ls_bridge    (148, the end) out of the burning town a BRIDGE OF LIGHT builds itself, plank by plank,
##                up into the Storm - and the three of them walk onto it, slowly.
## Everything is built here from Hero3D (the heroes' Blender models; guards, townsfolk, the king and the
## Nightmare Lord from shapes) and Three.* props. Mutable state inside the animators lives in Arrays /
## Dictionaries (lambdas capture plain locals by value).

const KINDS := ["ls_capture", "ls_timestop", "ls_free", "ls_bridge"]
const LEN := {"ls_capture": 13.0, "ls_timestop": 17.0, "ls_free": 8.0, "ls_bridge": 15.0}

const STONE := Color(0.72, 0.72, 0.70)
const GLASS := Color(0.40, 0.64, 0.72)
const COPPER := Color(0.78, 0.50, 0.26)
const STORM_BLUE := Color(0.70, 0.90, 1.0)
const GUARD_COL := Color(0.24, 0.30, 0.48)


static func has(kind: String) -> bool:
	return KINDS.has(kind)


static func build(st: Stage3D, kind: String, hero: String, other: String) -> void:
	match kind:
		"ls_capture":
			_capture(st, hero, other)
		"ls_timestop":
			_timestop(st)
		"ls_free":
			_free(st)
		"ls_bridge":
			_bridge(st)


static func _k(t: float, a: float, b: float) -> float:
	return clampf((t - a) / maxf(b - a, 0.001), 0.0, 1.0)


# ============================================================
# PEOPLE
# ============================================================
## THE NIGHTMARE LORD: red skin, a black suit, a red tie, two small horns, yellow eyes.
static func nightmare_lord(parent: Node3D, pos: Vector3, pose: String = "idle") -> Hero3D:
	var suit := Color(0.14, 0.12, 0.17)
	var skin := Color(0.86, 0.07, 0.08)
	return Hero3D.make_custom(parent, {"leg": suit, "arm": suit, "chest": suit, "belt": Color(0.9, 0.0, 0.04), "foot": Color(0.05, 0.05, 0.06),
		"hand": skin, "head": "plain", "head_col": skin, "eye": Color(1.0, 0.85, 0.2),
		"extras": func(h: Hero3D) -> void:
			Three.box(h.body, Vector3(0.05, 0.42, 0.09), Vector3(0.27, 0.55, 0), Color(0.9, 0.0, 0.04), 0.0, 0.015)       # The red tie
			for z: float in [-0.12, 0.12]:
				var horn := Three.cone(h.head, 0.06, 0.22, Vector3(-0.02, 0.24, z), Color(0.35, 0.02, 0.03), 0.0, 0.02)
				horn.rotation.z = 0.35}, pos, pose)


## A guard of Halcyon: storm-blue armour, a silver helmet, a copper storm-rod (a spear with a glowing tip).
static func guard(parent: Node3D, pos: Vector3, pose: String = "idle") -> Hero3D:
	return Hero3D.make_custom(parent, {"leg": GUARD_COL.darkened(0.2), "arm": GUARD_COL, "chest": GUARD_COL, "belt": COPPER,
		"foot": Color(0.12, 0.12, 0.14), "hand": Color(0.18, 0.18, 0.2), "head": "helm", "head_col": Color(0.80, 0.82, 0.88), "bulk": 1.05,
		"extras": func(h: Hero3D) -> void:
			var rod := Three.cyl(h.hands[0], 0.03, 1.9, Vector3(0.05, -0.35, 0), COPPER, 0.0, 0.015, 6)
			rod.rotation.z = 0.25
			Three.ball(h.hands[0], 0.07, Vector3(0.28, 0.55, 0), STORM_BLUE, 3.0, 0.0)
			Three.ring(h.body, 0.06, 0.09, Vector3(0.3, 0.55, 0), STORM_BLUE, 1.0, 0.0)}, pos, pose)


## Townsfolk of Halcyon (look 0..5: shirt / skin colours).
static func townsperson(parent: Node3D, pos: Vector3, look: int) -> Hero3D:
	var shirts := [Color(0.30, 0.45, 0.70), Color(0.70, 0.30, 0.25), Color(0.35, 0.55, 0.30), Color(0.75, 0.65, 0.35), Color(0.45, 0.35, 0.55), Color(0.55, 0.55, 0.58)]
	var skins := [Color(0.95, 0.80, 0.66), Color(0.80, 0.60, 0.45), Color(0.62, 0.44, 0.30), Color(0.98, 0.86, 0.74)]
	var sh: Color = shirts[look % shirts.size()]
	var sk: Color = skins[look % skins.size()]
	var h := Hero3D.make_custom(parent, {"leg": Color(0.24, 0.22, 0.26), "arm": sh, "chest": sh, "belt": sh.darkened(0.3),
		"foot": Color(0.2, 0.15, 0.1), "hand": sk, "head": "plain", "head_col": sk, "bulk": 0.85, "limb": 0.85}, pos, "idle")
	h.scale = Vector3.ONE * (0.92 if look != 5 else 0.7)
	return h


## THE KING OF HALCYON: long storm-blue robes, a white beard, a crown of copper lightning rods.
static func king(parent: Node3D, pos: Vector3) -> Hero3D:
	return Hero3D.make_custom(parent, {"leg": GUARD_COL.darkened(0.3), "arm": GUARD_COL, "chest": GUARD_COL, "belt": Color(0.80, 0.82, 0.88),
		"foot": GUARD_COL.darkened(0.3), "hand": Color(0.86, 0.72, 0.6), "head": "plain", "head_col": Color(0.86, 0.72, 0.6),
		"extras": func(h: Hero3D) -> void:
			var robe := Three.cone(h.body, 0.42, 1.2, Vector3(0, -0.4, 0), GUARD_COL.darkened(0.15), 0.0, 0.02, 14)
			robe.rotation.x = PI
			var beard := Three.cone(h.head, 0.16, 0.34, Vector3(0.16, -0.22, 0), Color(0.9, 0.9, 0.92), 0.0, 0.015)
			beard.rotation.z = PI
			Three.ring(h.head, 0.2, 0.25, Vector3(0, 0.2, 0), COPPER, 0.4, 0.015)
			for i in 5:
				var a := TAU * float(i) / 5.0
				Three.cyl(h.head, 0.015, 0.22, Vector3(cos(a) * 0.22, 0.32, sin(a) * 0.22), COPPER, 0.0, 0.0, 5)
				Three.ball(h.head, 0.03, Vector3(cos(a) * 0.22, 0.45, sin(a) * 0.22), STORM_BLUE, 3.0, 0.0)}, pos, "idle")


# ============================================================
# HALCYON (the town)
# ============================================================
static func _town(st: Stage3D, night: bool, seed_v: int) -> void:
	if night:
		st.sky(Color(0.04, 0.04, 0.08), Color(0.28, 0.16, 0.14), Color(0.05, 0.04, 0.05))
		st.fog(Color(0.30, 0.14, 0.10), 0.018)
		st.sun(Vector3(-40, 25, 0), Color(1.0, 0.7, 0.5), 0.5)
		st.env.ambient_light_energy = 0.45
	else:
		st.sky(Color(0.16, 0.20, 0.30), Color(0.50, 0.62, 0.68), Color(0.25, 0.27, 0.28))
		st.fog(Color(0.45, 0.52, 0.58), 0.016)
		st.sun(Vector3(-50, 35, 0), Color(0.90, 0.95, 1.0), 1.0)
	Three.plane(st, Vector2(140, 140), Vector3(0, 0, -30), STONE.darkened(0.35))
	Three.box(st, Vector3(60, 0.06, 4.0), Vector3(0, 0.03, 0), STONE, 0.0, 0.0)            # The main street
	var rng := RandomNumberGenerator.new()
	rng.seed = seed_v
	for i in 16:                                                                            # Towers of glass + copper
		var x := -30.0 + float(i) * 4.0 + rng.randf_range(-0.8, 0.8)
		var z := -9.0 - rng.randf_range(0.0, 8.0)
		var h := rng.randf_range(6.0, 16.0)
		var w := rng.randf_range(2.0, 3.2)
		Three.box(st, Vector3(w, h, w), Vector3(x, h * 0.5, z), GLASS.lerp(COPPER, rng.randf() * 0.4).darkened(0.15))
		Three.cone(st, w * 0.6, 1.6, Vector3(x, h + 0.8, z), COPPER, 0.0, 0.03, 8)
		Three.cyl(st, 0.05, 1.6, Vector3(x, h + 2.4, z), COPPER, 0.0, 0.0, 5)                # Lightning rod
		Three.ball(st, 0.12, Vector3(x, h + 3.2, z), STORM_BLUE, 2.5, 0.0)
	for i in 6:                                                                             # Low houses on the near side
		var x2 := -26.0 + float(i) * 10.0
		Three.box(st, Vector3(3.4, 2.6, 2.6), Vector3(x2, 1.3, 6.5), STONE.lerp(Color(0.85, 0.78, 0.66), 0.5))
		Three.prism(st, Vector3(3.8, 1.2, 2.8), Vector3(x2, 3.2, 6.5), COPPER.darkened(0.2))


## The square: a pillar with the Storm's spiral on top (what Halcyon prays to).
static func _storm_pillar(st: Stage3D, pos: Vector3) -> void:
	Three.cyl(st, 0.6, 4.0, pos + Vector3(0, 2.0, 0), STONE.lightened(0.1), 0.0, 0.03, 12)
	for i in 10:
		var a := float(i) * 0.7
		var r := 0.2 + float(i) * 0.09
		Three.ball(st, 0.12, pos + Vector3(cos(a) * r, 4.4 + float(i) * 0.12, sin(a) * r), STORM_BLUE, 2.0, 0.0)


## The three cells: [left, middle, right] cages. Returns {"front": [bars Array per cell], "door": [...]}.
static func _cells(st: Stage3D, at: Vector3) -> Dictionary:
	var fronts: Array = []
	for c in 3:
		var cx := at.x + float(c) * 2.6
		var bars: Array = []
		Three.box(st, Vector3(2.4, 0.2, 2.2), Vector3(cx, 3.0, at.z), Color(0.25, 0.25, 0.28))           # Roof
		Three.box(st, Vector3(2.4, 3.0, 0.15), Vector3(cx, 1.5, at.z - 1.1), Color(0.30, 0.30, 0.34))     # Back wall
		for side: float in [-1.0, 1.0]:
			Three.box(st, Vector3(0.15, 3.0, 2.2), Vector3(cx + side * 1.2, 1.5, at.z), Color(0.30, 0.30, 0.34))
		for b in 7:                                                                              # Front bars
			var bar := Three.cyl(st, 0.04, 3.0, Vector3(cx - 1.05 + float(b) * 0.35, 1.5, at.z + 1.1), Color(0.55, 0.55, 0.6), 0.0, 0.015, 6)
			bars.append(bar)
		fronts.append(bars)
	return {"front": fronts}


## A fire: flickering cones + a light. Returned hidden (scale 0); grow it with its "scale".
static func _fire(st: Stage3D, pos: Vector3, size: float) -> Node3D:
	var f := Node3D.new()
	f.position = pos
	st.add_child(f)
	for i in 5:
		var a := TAU * float(i) / 5.0
		var c := Three.cone(f, 0.35 * size, 1.4 * size, Vector3(cos(a) * 0.3 * size, 0.7 * size, sin(a) * 0.3 * size),
			Color(1.0, 0.45, 0.08) if i % 2 == 0 else Color(1.0, 0.75, 0.2), 2.5, 0.0, 8)
		c.rotation.z = sin(a) * 0.2
	Three.cone(f, 0.25 * size, 2.0 * size, Vector3(0, 1.0 * size, 0), Color(1.0, 0.9, 0.5), 3.0, 0.0, 8)
	Three.light_point(f, Vector3(0, 1.2 * size, 0), Color(1.0, 0.55, 0.2), 3.0, 6.0 * size)
	f.scale = Vector3.ZERO
	return f


static func _flicker(f: Node3D, t: float, grow: float) -> void:
	f.scale = Vector3.ONE * grow * (1.0 + 0.08 * sin(t * 17.0 + f.position.x)) * Vector3(1, 1.0 + 0.12 * sin(t * 11.0 + f.position.z), 1)


# ============================================================
# ls_capture  (end of level 142)
# ============================================================
static func _capture(st: Stage3D, hero: String, other: String) -> void:
	_town(st, false, 142)
	_storm_pillar(st, Vector3(8, 0, -4))
	var cells := _cells(st, Vector3(40, 0, 0))                                      # Far off-screen: the cut at the end
	var h := Hero3D.make(st, hero, Vector3(-16, 0, 0.6), "run")
	var o := Hero3D.make(st, other, Vector3(-17.5, 0, -0.6), "run")
	var nl := nightmare_lord(st, Vector3(-19, 0, 0), "run")
	for p: Hero3D in [h, o, nl]:
		p.face(Vector3.RIGHT)
	var folk: Array = []                                                            # The people gather on both sides
	for i in 10:
		var side := 1.0 if i % 2 == 0 else -1.0
		var tp := townsperson(st, Vector3(-6.0 + float(i) * 1.6, 0, side * 3.2), i)
		tp.face(Vector3(0, 0, -side))
		tp.visible = false
		folk.append(tp)
	var guards: Array = []                                                          # Then the guards circle them
	for i in 6:
		var a := TAU * float(i) / 6.0
		var g := guard(st, Vector3(2.0 + cos(a) * 9.0, 0, sin(a) * 9.0), "run")
		g.visible = false
		guards.append([g, a])
	var bolts: Array = []
	for i in 3:
		var b := Three.cyl(st, 0.06, 6.0, Vector3.ZERO, STORM_BLUE, 4.0, 0.0, 6)
		b.visible = false
		bolts.append(b)
	var in_cells: Array = []                                                        # The last shot: each one in a cell
	for i in 3:
		var who := [hero, other, "nl"][i] as String
		var cp := Vector3(40.0 + float(i) * 2.6, 0, 0.2)
		var p: Hero3D = nightmare_lord(st, cp, "kneel_point") if who == "nl" else Hero3D.make(st, who, cp, "idle")
		p.face(Vector3(0, 0, 1))
		in_cells.append(p)
	in_cells[2].pose = "idle"
	in_cells[0].pose = "idle"
	var down := [false]
	st.animate(func(t: float) -> void:
		var walk := _k(t, 0.0, 4.0)
		var party: Array = [h, o, nl]
		for i in 3:
			var hp: Hero3D = party[i]
			if t < 6.6:
				hp.position.x = lerpf([-16.0, -17.5, -19.0][i], [1.5, 0.0, -1.5][i], walk)
				hp.pose = "run" if walk < 0.6 else ("walk" if walk < 1.0 else "idle")
				hp.speed = 1.0 if walk < 0.6 else 0.7
		for i in folk.size():
			var tp: Hero3D = folk[i]
			tp.visible = t > 2.0 + float(i) * 0.12
		for gi in guards.size():
			var e: Array = guards[gi]
			var g: Hero3D = e[0]
			g.visible = t > 4.4
			var close := _k(t, 4.4, 6.4)
			var a: float = e[1]
			g.position = Vector3(0.0 + cos(a) * lerpf(9.0, 2.6, close), 0, sin(a) * lerpf(9.0, 2.6, close))
			g.face(-g.position)
			g.pose = "run" if close < 1.0 else "menace"
		for i in 3:                                                                  # Storm-rods: lightning into all three
			var b: MeshInstance3D = bolts[i]
			var target: Hero3D = party[i]
			b.visible = t > 6.6 + float(i) * 0.15 and t < 7.2 + float(i) * 0.15
			b.position = target.position + Vector3(0, 3.5, 0)
		if t > 7.0 and not down[0]:
			down[0] = true
			for hp2: Hero3D in party:
				hp2.pose = "lie"
				hp2.speed = 0.0
		if t > 9.6:                                                                  # Cut to the cells
			for hp3: Hero3D in party:
				hp3.visible = false
		var fronts: Array = cells["front"]
		for c in 3:
			var slam := _k(t, 10.2 + float(c) * 0.5, 10.4 + float(c) * 0.5)
			for bar: MeshInstance3D in fronts[c]:
				bar.position.y = lerpf(5.0, 1.5, slam)
		st.env.ambient_light_energy = 0.7 if t < 6.6 else (1.6 if t < 7.4 else 0.55))
	st.cam_key(0.0, Vector3(-18, 2.2, 7), Vector3(-14, 1.4, 0))
	st.cam_key(3.5, Vector3(-4, 2.6, 8), Vector3(2, 1.6, 0))
	st.cam_key(6.0, Vector3(2, 6.5, 9), Vector3(1, 0.5, 0))
	st.cam_key(9.4, Vector3(4, 3.0, 5), Vector3(0, 0.3, 0))
	st.cam_key(9.6, Vector3(42.6, 1.8, 7.5), Vector3(42.6, 1.4, 0))
	st.cam_key(13.0, Vector3(42.6, 1.6, 5.5), Vector3(42.6, 1.2, 0))


# ============================================================
# ls_timestop  (end of level 147: THE cutscene)
# ============================================================
static func _timestop(st: Stage3D) -> void:
	_town(st, true, 147)
	_storm_pillar(st, Vector3(10, 0, -3))
	var cells := _cells(st, Vector3(-20.6, 0, 0))                                  # The Architect's cell is the left one
	var arch := Hero3D.make(st, "architect", Vector3(-20.6, 0, -0.2), "kneel_point")
	arch.face(Vector3(0, 0, 1))
	arch.pose = "idle"
	var war := Hero3D.make(st, "warrior", Vector3(-18.0, 0, -0.2), "lie")
	war.face(Vector3(0, 0, 1))
	var nl := nightmare_lord(st, Vector3(-15.4, 0, -0.2), "idle")
	nl.face(Vector3(0, 0, 1))
	var core := Three.ball(arch.body, 0.14, Vector3(0.28, 0.6, 0), Color(0.3, 0.8, 1.0), 4.0, 0.0)
	var wave := Three.ring(st, 0.2, 0.35, Vector3(-20.6, 1.2, 0), Color(0.75, 0.9, 1.0, 0.7), 3.0, 0.0)
	wave.visible = false
	# The guards along the street (frozen when time stops); which limb each one loses
	var guards: Array = []
	var gx := [-14.0, -10.5, -7.0, -3.5, 0.0, 3.5, 7.0]
	for i in gx.size():
		var g := guard(st, Vector3(float(gx[i]), 0, 1.3 if i % 2 == 0 else -1.3), "walk" if i % 3 != 0 else "menace")
		g.face(Vector3(-1, 0, 0.2 * (1.0 if i % 2 == 0 else -1.0)))
		guards.append(g)
	# Rain (it hangs in the air while time is stopped)
	var rain: Array = []
	var rng := RandomNumberGenerator.new()
	rng.seed = 1470
	for i in 70:
		var d := Three.box(st, Vector3(0.02, 0.35, 0.02), Vector3(rng.randf_range(-26.0, 14.0), 0, rng.randf_range(-3.0, 4.0)), Color(0.7, 0.8, 1.0, 0.6), 0.5, 0.0)
		rain.append([d, rng.randf_range(0.0, 8.0)])
	var fire_square := _fire(st, Vector3(10, 0, -1.0), 1.6)
	var fires: Array = []                                                             # The whole town catches
	for i in 14:
		fires.append(_fire(st, Vector3(-28.0 + float(i) * 3.4 + rng.randf_range(-1.0, 1.0), rng.randf_range(0.0, 6.0), -8.0 - rng.randf_range(0.0, 6.0)), rng.randf_range(1.2, 2.4)))
	for i in 6:
		fires.append(_fire(st, Vector3(-26.0 + float(i) * 10.0, 2.6, 6.5), 1.3))
	var torn: Array = []                                                              # [limb, velocity, spin] once ripped off
	var state := {"stopped": false, "out": false, "torn_upto": -1, "resumed": false}
	var tear_at := [7.0, 7.5, 8.0, 8.5, 9.0, 9.5, 10.0]
	st.animate(func(t: float) -> void:
		# --- Time: runs until 3.4, stopped until 12.4, then runs again ---
		var stop_k := _k(t, 3.2, 3.8) * (1.0 - _k(t, 12.2, 12.8))
		st.env.adjustment_enabled = true
		st.env.adjustment_saturation = lerpf(1.0, 0.12, stop_k)
		st.env.adjustment_brightness = lerpf(1.0, 0.92, stop_k)
		if t > 3.4 and not state["stopped"]:
			state["stopped"] = true
			for g: Hero3D in guards:
				g.speed = 0.0
			nl.speed = 0.0
			war.speed = 0.0
		var rt := t if t < 3.4 else (3.4 if t < 12.4 else t - 9.0)                    # Rain clock (stops with time)
		for e: Array in rain:
			var d: MeshInstance3D = e[0]
			d.position.y = 9.0 - fmod(rt * 9.0 + float(e[1]), 9.0)
		# --- He wakes: the core blazes, the time wave rolls out ---
		core.scale = Vector3.ONE * (1.0 + 1.5 * _k(t, 1.0, 3.2))
		wave.visible = t > 3.2 and t < 5.0
		wave.scale = Vector3.ONE * (1.0 + 120.0 * _k(t, 3.2, 5.0))
		# --- The bars fly off; he walks out and down the street ---
		var fronts: Array = cells["front"]
		for b in fronts[0].size():
			var bar: MeshInstance3D = fronts[0][b]
			var fly := _k(t, 4.4, 5.2)
			bar.position = Vector3(-21.65 + float(b) * 0.35, 1.5, 1.1) + Vector3(float(b - 3) * 0.6, 1.5 * fly, 4.0) * fly
			bar.rotation = Vector3(fly * 2.0 + float(b), 0, fly * 1.5)
		if t > 5.0 and t < 12.6:
			var w := _k(t, 5.0, 11.4)
			arch.position = Vector3(lerpf(-20.6, 8.6, w), 0, 0.2 if t < 5.6 else 0.0)
			arch.face(Vector3.RIGHT if t > 5.4 else Vector3(0, 0, 1))
			arch.pose = "walk" if w < 1.0 else "kneel_point"
			arch.speed = 0.8
		# --- Each guard he passes: the limbs come off and HANG in the air ---
		for i in guards.size():
			if t > float(tear_at[i]) and int(state["torn_upto"]) < i:
				state["torn_upto"] = i
				var g2: Hero3D = guards[i]
				var limbs: Array = [g2._arms[0], g2._arms[1]] if i % 2 == 0 else [g2._arms[0], g2._legs[1], g2.head]
				for limb: Node3D in limbs:
					limb.reparent(st, true)
					var dir := Vector3(randf_range(0.6, 1.6), randf_range(0.8, 1.8), randf_range(-1.2, 1.2))
					torn.append([limb, dir, Vector3(randf_range(-6, 6), randf_range(-6, 6), randf_range(-6, 6)), t])
					var blood := Three.ball(st, 0.07, limb.global_position, Color(0.55, 0.02, 0.03), 0.0, 0.0)
					torn.append([blood, dir * 1.2, Vector3.ZERO, t])
		for e2: Array in torn:
			var n: Node3D = e2[0]
			var since := minf(t, 12.4) - float(e2[3])
			var after := maxf(t - 12.4, 0.0)
			var v: Vector3 = e2[1]
			if not n.has_meta("start"):
				n.set_meta("start", n.position)
			var start: Vector3 = n.get_meta("start")
			var hang := start + v * clampf(since, 0.0, 0.5) * 1.2                     # Ripped off... then frozen mid-air
			n.position = hang + Vector3(v.x * after * 2.0, -minf(after * after * 9.8, hang.y), v.z * after * 2.0)
			n.rotation = (e2[2] as Vector3) * (clampf(since, 0.0, 0.5) + after)
		# --- The spark in the square, then time comes back and everything burns ---
		_flicker(fire_square, t, _k(t, 11.4, 12.0) * (0.5 if t < 12.4 else 1.0 + 0.4 * _k(t, 12.4, 13.4)))
		for i in fires.size():
			_flicker(fires[i], t, _k(t, 12.6 + float(i) * 0.12, 13.4 + float(i) * 0.12))
		if t > 12.4 and not state["resumed"]:
			state["resumed"] = true
			for g3: Hero3D in guards:
				g3.speed = 1.0
				g3.pose = "lie"
			nl.speed = 1.0
			war.speed = 1.0
		if t > 12.6:
			arch.pose = "idle"
			arch.face(Vector3(0.3, 0, 1))
		st.env.ambient_light_energy = 0.45 + 0.5 * _k(t, 12.4, 14.0)
		st.env.fog_light_color = Color(0.30, 0.14, 0.10).lerp(Color(0.85, 0.35, 0.10), _k(t, 12.4, 15.0)))
	st.cam_key(0.0, Vector3(-20.6, 1.6, 3.2), Vector3(-20.6, 1.4, 0))                  # Close on him in the cell
	st.cam_key(3.0, Vector3(-20.6, 1.7, 2.4), Vector3(-20.6, 1.6, 0))
	st.cam_key(4.6, Vector3(-17.0, 2.6, 7.5), Vector3(-19.5, 1.2, 0))                  # The bars fly
	st.cam_key(7.0, Vector3(-12.0, 2.4, 6.0), Vector3(-13.5, 1.4, 0))                  # Down the frozen street
	st.cam_key(10.0, Vector3(-1.0, 3.0, 6.5), Vector3(-3.0, 1.6, 0))
	st.cam_key(11.6, Vector3(6.0, 2.2, 4.0), Vector3(9.5, 1.0, -1.0))                  # The spark
	st.cam_key(12.6, Vector3(5.0, 3.0, 7.0), Vector3(8.0, 1.4, -1.0))
	st.cam_key(17.0, Vector3(-6.0, 13.0, 24.0), Vector3(0.0, 3.0, -6.0))                # HALCYON BURNS


# ============================================================
# ls_free  (148: back to the cells)
# ============================================================
static func _free(st: Stage3D) -> void:
	_town(st, true, 148)
	var cells := _cells(st, Vector3(-2.6, 0, 0))
	for i in 4:
		_flicker(_fire(st, Vector3(-12.0 + float(i) * 8.0, 0, -9.0), 2.0), 0.0, 1.0)
	var war := Hero3D.make(st, "warrior", Vector3(0, 0, -0.2), "idle")
	war.face(Vector3(0, 0, 1))
	var nl := nightmare_lord(st, Vector3(2.6, 0, -0.2), "idle")
	nl.face(Vector3(0, 0, 1))
	var arch := Hero3D.make(st, "architect", Vector3(-10, 0, 3.0), "walk")
	arch.face(Vector3.RIGHT)
	st.animate(func(t: float) -> void:
		var w := _k(t, 0.0, 2.6)
		arch.position = Vector3(lerpf(-10.0, 1.3, w), 0, 3.0)
		arch.pose = "walk" if w < 1.0 else "idle"
		var fronts: Array = cells["front"]
		for c in [1, 2]:                                                          # He pulls the two doors' bars apart
			var pull := _k(t, 3.0 + float(c - 1) * 0.6, 3.6 + float(c - 1) * 0.6)
			for b in fronts[c].size():
				var bar: MeshInstance3D = fronts[c][b]
				var side := -1.0 if b < 3 else (1.0 if b > 3 else 0.0)
				bar.rotation.z = side * pull * 1.2
				bar.position.y = 1.5 + pull * (2.5 if b == 3 else 0.0)
				bar.visible = b != 3 or pull < 0.9
		var out := _k(t, 4.6, 6.2)
		war.position.z = lerpf(-0.2, 2.6, out)
		nl.position.z = lerpf(-0.2, 2.6, _k(t, 5.0, 6.6))
		war.pose = "walk" if out > 0.0 and out < 1.0 else "idle"
		nl.pose = "walk" if t > 5.0 and t < 6.6 else "idle")
	st.cam_key(0.0, Vector3(-6, 2.0, 9), Vector3(-2, 1.4, 1))
	st.cam_key(3.0, Vector3(1.3, 2.0, 7.5), Vector3(1.3, 1.4, 0))
	st.cam_key(8.0, Vector3(1.3, 1.8, 8.5), Vector3(1.3, 1.3, 1.5))


# ============================================================
# ls_bridge  (148: the end - a bridge of light into the Storm)
# ============================================================
static func _bridge(st: Stage3D) -> void:
	st.sky(Color(0.03, 0.02, 0.06), Color(0.40, 0.16, 0.10), Color(0.04, 0.03, 0.04))
	st.fog(Color(0.30, 0.12, 0.10), 0.012)
	st.sun(Vector3(-25, -40, 0), Color(1.0, 0.6, 0.4), 0.6)
	st.env.ambient_light_energy = 0.5
	Three.plane(st, Vector2(60, 60), Vector3(0, 0, 10), Color(0.22, 0.20, 0.20))         # The edge of the town (a cliff at z = -10)
	var rng := RandomNumberGenerator.new()
	rng.seed = 1481
	for i in 10:                                                                          # Halcyon burning behind them
		var x := -24.0 + float(i) * 5.2
		var h := rng.randf_range(5.0, 12.0)
		Three.box(st, Vector3(2.6, h, 2.6), Vector3(x, h * 0.5, 22.0 + rng.randf_range(0.0, 6.0)), GLASS.darkened(0.5))
		_flicker(_fire(st, Vector3(x, h, 22.0), 1.8), 0.0, 1.0)
	var storm: Array = []                                                                 # THE STORM: a ring of black cloud, lightning inside
	for i in 18:
		var a := TAU * float(i) / 18.0
		var c := Three.ball(st, 5.0, Vector3(cos(a) * 14.0, 34.0 + sin(a * 3.0) * 2.0, -60.0 + sin(a) * 8.0), Color(0.06, 0.04, 0.10), 0.0, 0.0)
		storm.append(c)
	var eye := Three.ball(st, 6.0, Vector3(0, 34, -62), Color(0.55, 0.75, 1.0), 2.0, 0.0)   # The light in its middle
	var planks: Array = []                                                                # The bridge, from the cliff up into the Storm
	for i in 40:
		var k := float(i) / 39.0
		var p := Vector3(0, 0.2 + 33.0 * k * k, -10.0 - 50.0 * k)
		var pl := Three.box(st, Vector3(2.4, 0.18, 1.4), p, Color(0.80, 0.92, 1.0), 2.5, 0.02)
		pl.rotation.x = atan2(66.0 * k * 1.0, 50.0) * 0.9
		pl.scale = Vector3.ZERO
		planks.append(pl)
	var arch := Hero3D.make(st, "architect", Vector3(0, 0, 0), "idle")
	var war := Hero3D.make(st, "warrior", Vector3(-1.4, 0, 1.2), "idle")
	var nl := nightmare_lord(st, Vector3(1.4, 0, 1.2), "idle")
	for p2: Hero3D in [arch, war, nl]:
		p2.face(Vector3(0, 0, -1))
	st.animate(func(t: float) -> void:
		for i in planks.size():                                                        # Plank by plank, from the bottom up
			var pl2: MeshInstance3D = planks[i]
			pl2.scale = Vector3.ONE * _k(t, 1.5 + float(i) * 0.09, 1.9 + float(i) * 0.09)
		for i in storm.size():
			var c2: MeshInstance3D = storm[i]
			c2.scale = Vector3.ONE * (1.0 + 0.08 * sin(t * 1.3 + float(i)))
		(eye as MeshInstance3D).scale = Vector3.ONE * (0.6 + 0.4 * _k(t, 2.0, 6.0)) * (1.0 + 0.05 * sin(t * 3.0))
		var party: Array = [arch, war, nl]
		var offs := [Vector3(0, 0, 0), Vector3(-1.1, 0, 1.4), Vector3(1.1, 0, 1.4)]
		for i in 3:                                                                    # They walk onto it, slowly
			var hp: Hero3D = party[i]
			var walk := _k(t, 6.5 + float(i) * 0.35, 15.0)
			var z := lerpf(0.0, -26.0, walk) + (offs[i] as Vector3).z
			var k2 := clampf((-z - 10.0) / 50.0, 0.0, 1.0)
			hp.position = Vector3((offs[i] as Vector3).x * (1.0 - k2 * 0.6), 0.2 + 33.0 * k2 * k2 if -z > 10.0 else 0.0, z)
			hp.pose = "walk" if walk > 0.0 and walk < 1.0 else "idle"
			hp.speed = 0.7)
	st.cam_key(0.0, Vector3(0, 2.2, 7.0), Vector3(0, 2.0, -10.0))
	st.cam_key(5.0, Vector3(-6, 6.0, 9.0), Vector3(0, 14.0, -40.0))                        # Up along the bridge to the Storm
	st.cam_key(8.0, Vector3(0, 2.0, 5.5), Vector3(0, 1.4, -6.0))                           # Behind them as they start
	st.cam_key(15.0, Vector3(4, 6.0, 4.0), Vector3(0, 10.0, -26.0))
