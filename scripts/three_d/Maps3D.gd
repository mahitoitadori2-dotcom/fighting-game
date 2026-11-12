class_name Maps3D
extends RefCounted
## 3D DIORAMAS of the Story maps, used by the 3D cutscenes (level intros) and - for the
## IMPORTANT maps - as the 3D background behind the 2D fight (Backdrop3D).
## Coordinates: x = left / right along the road, y = up, z = depth (the fight / road is at
## z = 0, scenery goes into negative z). The floor is at y = 0.
##
##   IMPORTANT (detailed, also 3D fight backdrops - key = HellBackground theme):
##     lab, blasphemy, golem_hall, spider_lair, world_tree, satan_cave, sun_peak,
##     prime_sanctum, sky_reliquary
##   Every other map: a diorama from its FAMILY (cave, lava, holy, void, forest, snow,
##   metal, desert, sewer) coloured with its board tile colour.

const IMPORTANT := ["lab", "blasphemy", "golem_hall", "spider_lair", "world_tree", "satan_cave", "sun_peak", "prime_sanctum", "sky_reliquary"]
const FAMILY := {
	"surface": "lava", "cave": "cave", "geode": "cave", "hive": "metal", "lab": "metal",
	"elevator": "metal", "enlightened": "holy", "sewer": "sewer", "blasphemy": "lava",
	"throne": "lava", "architectium": "metal", "workshop": "lava", "golem_hall": "holy",
	"dark_cave": "cave", "void": "void", "altar": "holy", "spider_lair": "void",
	"thornwood": "forest", "fallen_ruins": "holy", "foothills": "snow", "silk_loom": "holy",
	"mirror_hall": "holy", "beast_den": "cave", "gallows": "void", "world_tree": "forest",
	"ash_cathedral": "lava", "satan_cave": "lava", "sun_peak": "snow",
	"caeser_crypts": "cave", "caeser_tomb": "void", "saint_rocks": "holy", "saint_sanctum": "holy",
	"deep_void": "void", "horrid_nest": "void", "reactor_waste": "metal", "reactor_core": "metal",
	"the_forge": "lava", "forge_heart": "lava",
	"golden_dunes": "desert", "pilgrim_road": "desert", "glass_oasis": "desert",
	"prime_sanctum": "holy", "sky_reliquary": "holy",
	"demi_plains": "forest", "demi_village": "forest", "demi_ravine": "cave", "demi_grove": "forest", "demi_door": "void",
}


static func important(theme: String) -> bool:
	return IMPORTANT.has(theme)


## Theme (HellBackground name) of a level's map.
static func theme_of_level(n: int, boss_map: bool = false) -> String:
	var lv := StoryLevels.get_level(n)
	var key := String(lv.get("boss_map", "")) if boss_map and String(lv.get("boss_map", "")) != "" else String(lv.get("map", "wastes"))
	return String(StoryLevels.MAPS.get(key, {}).get("bg", "surface"))


## Builds the diorama for `theme` into the stage (sky, lights, ground, scenery).
static func build(st: Stage3D, theme: String, tile: Color = Color(0.5, 0.4, 0.3)) -> void:
	match theme:
		"lab":
			_lab(st)
		"blasphemy":
			_blasphemy(st)
		"golem_hall":
			_golem_hall(st)
		"spider_lair":
			_spider_lair(st)
		"world_tree":
			_world_tree(st)
		"satan_cave":
			_satan_cave(st)
		"sun_peak":
			_sun_peak(st)
		"prime_sanctum":
			_prime_sanctum(st)
		"sky_reliquary":
			_sky_reliquary(st)
		_:
			_family(st, String(FAMILY.get(theme, "cave")), tile)


## NO CLIPPING: scenery never goes where the action is. The middle corridor (heroes walk in,
## cameras fly) and the band where the boss stands / walks in (around z = -12) stay empty.
static func free_spot(p: Vector3) -> bool:
	if absf(p.x) < 6.5 and p.z > -21.0:
		return false
	if p.z > -17.0 and p.z < -7.0 and absf(p.x) < 21.0:
		return false
	return true


## A random spot (x in +-xr, z between z0 and z1) that is free of the action (or null).
static func spot(rng: RandomNumberGenerator, xr: float, z0: float, z1: float, y: float = 0.0) -> Variant:
	for i in 24:
		var p := Vector3(rng.randf_range(-xr, xr), y, -rng.randf_range(z0, z1))
		if free_spot(p):
			return p
	return null


static func _ground(st: Stage3D, col: Color, size: float = 160.0) -> void:
	Three.plane(st, Vector2(size, size), Vector3(0, 0, -size * 0.35), col)


# ============================================================
# GENERIC FAMILIES
# ============================================================
static func _family(st: Stage3D, fam: String, tile: Color) -> void:
	var rng := RandomNumberGenerator.new()
	rng.seed = hash(fam) + int(tile.r * 1000.0)
	match fam:
		"lava":
			st.sky(Color(0.15, 0.03, 0.02), Color(0.75, 0.25, 0.08), Color(0.1, 0.02, 0.02))
			st.fog(Color(0.5, 0.15, 0.05), 0.02)
			st.sun(Vector3(-35, 30, 0), Color(1.0, 0.6, 0.4), 1.0)
			_ground(st, tile.darkened(0.3))
			for i in 6:                                         # Lava rivers
				Three.box(st, Vector3(rng.randf_range(3.0, 7.0), 0.05, 0.8), Vector3(rng.randf_range(-14.0, 14.0), 0.03, -rng.randf_range(4.0, 26.0)), Color(1.0, 0.45, 0.1), 2.5, 0.0)
			for i in 14:
				var rp: Variant = spot(rng, 24.0, 3.0, 34.0, 0.4)
				if rp != null:
					Three.rock(st, rng.randf_range(0.6, 2.2), rp, tile.darkened(0.5), i)
			Three.cone(st, 9.0, 12.0, Vector3(6, 6, -45), Color(0.18, 0.07, 0.05))      # Volcano
			Three.ball(st, 1.5, Vector3(6, 12.5, -45), Color(1.0, 0.5, 0.1), 3.0, 0.0)
		"cave":
			st.sky(Color(0.03, 0.03, 0.05), Color(0.12, 0.10, 0.14), Color(0.02, 0.02, 0.03))
			st.fog(Color(0.08, 0.07, 0.10), 0.05)
			st.sun(Vector3(-60, 20, 0), Color(0.7, 0.7, 0.9), 0.6)
			_ground(st, tile.darkened(0.2))
			for i in 16:                                        # Stalagmites + crystals
				var cp: Variant = spot(rng, 22.0, 3.0, 30.0)
				if cp != null:
					var hh := rng.randf_range(1.5, 4.5)
					Three.cone(st, rng.randf_range(0.4, 1.0), hh, (cp as Vector3) + Vector3(0, hh * 0.5, 0), tile.darkened(0.4))
			for i in 6:
				var kp: Variant = spot(rng, 18.0, 4.0, 26.0, 0.9)
				if kp != null:
					Three.prism(st, Vector3(0.6, 1.8, 0.6), kp, Color(0.7, 0.45, 1.0), 1.5)
			Three.light_point(st, Vector3(0, 3, -6), Color(0.7, 0.5, 1.0), 2.0, 14.0)
		"holy":
			st.sky(Color(0.35, 0.55, 0.95), Color(1.0, 0.92, 0.75), Color(0.6, 0.55, 0.45))
			st.fog(Color(1.0, 0.95, 0.85), 0.012)
			st.sun(Vector3(-40, 40, 0), Color(1.0, 0.95, 0.8), 1.3)
			_ground(st, tile.lightened(0.1))
			for i in 10:                                        # White columns with gold caps (a colonnade behind)
				var x := -22.5 + float(i) * 5.0
				Three.cyl(st, 0.6, 7.0, Vector3(x, 3.5, -23.0), Color(0.95, 0.93, 0.88))
				Three.box(st, Vector3(1.6, 0.4, 1.6), Vector3(x, 7.2, -23.0), Color(1.0, 0.8, 0.3))
			Three.box(st, Vector3(48, 0.8, 2.0), Vector3(0, 7.8, -23.0), Color(0.92, 0.9, 0.85))
			for i in 3:                                         # Gold domes far away
				Three.ball(st, 3.0 + float(i), Vector3(-14.0 + float(i) * 14.0, 2.0, -34.0), Color(1.0, 0.8, 0.3), 0.4)
		"void":
			st.sky(Color(0.02, 0.0, 0.05), Color(0.12, 0.04, 0.20), Color(0.01, 0.0, 0.02))
			st.fog(Color(0.10, 0.03, 0.18), 0.045)
			st.sun(Vector3(-50, -20, 0), Color(0.6, 0.4, 1.0), 0.7)
			_ground(st, Color(0.12, 0.10, 0.15))
			for i in 22:                                        # Bones + spikes
				var vp: Variant = spot(rng, 24.0, 2.0, 32.0)
				if vp == null:
					continue
				var p: Vector3 = vp
				if i % 2 == 0:
					Three.cone(st, 0.3, rng.randf_range(2.0, 6.0), p + Vector3(0, 1.5, 0), Color(0.85, 0.82, 0.75))
				else:
					var b := Three.cyl(st, 0.15, 2.0, p + Vector3(0, 0.15, 0), Color(0.85, 0.82, 0.75))
					b.rotation = Vector3(0, rng.randf() * 3.0, PI * 0.5)
			Three.light_point(st, Vector3(0, 4, -8), Color(0.6, 0.3, 1.0), 3.0, 18.0)
		"forest":
			st.sky(Color(0.15, 0.02, 0.03), Color(0.55, 0.12, 0.06), Color(0.08, 0.02, 0.02))
			st.fog(Color(0.35, 0.08, 0.05), 0.03)
			st.sun(Vector3(-25, 30, 0), Color(1.0, 0.5, 0.4), 0.9)
			_ground(st, tile.darkened(0.2))
			for i in 18:                                        # Thorn trees
				var fp: Variant = spot(rng, 26.0, 4.0, 34.0)
				if fp == null:
					continue
				var p: Vector3 = fp
				var h := rng.randf_range(5.0, 11.0)
				Three.cone(st, 0.5, h, p + Vector3(0, h * 0.5, 0), Color(0.08, 0.03, 0.04))
				for k in 3:
					var th := Three.cone(st, 0.15, 2.0, p + Vector3(0, h * (0.3 + 0.2 * float(k)), 0), Color(0.08, 0.03, 0.04))
					th.rotation = Vector3(0, float(k) * 2.0, 1.2)
		"snow":
			st.sky(Color(0.35, 0.5, 0.8), Color(0.85, 0.9, 1.0), Color(0.7, 0.75, 0.85))
			st.fog(Color(0.85, 0.9, 1.0), 0.02)
			st.sun(Vector3(-35, 30, 0), Color(1.0, 0.98, 0.95), 1.3)
			_ground(st, Color(0.92, 0.94, 0.98))
			for i in 7:                                         # Mountains
				var h := rng.randf_range(10.0, 22.0)
				Three.cone(st, h * 0.7, h, Vector3(-30.0 + float(i) * 10.0, h * 0.5, -rng.randf_range(30.0, 50.0)), Color(0.55, 0.58, 0.68), 0.0, 0.08, 6)
				Three.cone(st, h * 0.25, h * 0.36, Vector3(-30.0 + float(i) * 10.0, h * 0.82, -rng.randf_range(30.0, 50.0)), Color(1, 1, 1), 0.0, 0.0, 6)
			for i in 10:
				var sp: Variant = spot(rng, 22.0, 3.0, 24.0, 0.4)
				if sp != null:
					Three.rock(st, rng.randf_range(0.5, 1.5), sp, Color(0.6, 0.62, 0.7), i)
		"metal":
			st.sky(Color(0.05, 0.07, 0.10), Color(0.25, 0.30, 0.36), Color(0.05, 0.05, 0.06))
			st.fog(Color(0.18, 0.22, 0.26), 0.03)
			st.sun(Vector3(-45, 30, 0), Color(0.8, 0.9, 1.0), 1.0)
			_ground(st, tile.darkened(0.2))
			for i in 14:                                        # Scrap piles + gears
				var mp: Variant = spot(rng, 22.0, 3.0, 30.0)
				if mp == null:
					continue
				var bh := rng.randf_range(0.5, 2.5)
				Three.box(st, Vector3(rng.randf_range(1.0, 3.0), bh, rng.randf_range(1.0, 3.0)), (mp as Vector3) + Vector3(0, bh * 0.5, 0), Color(0.35, 0.36, 0.40))
			for i in 4:
				var g := Three.ring(st, 1.0, 1.8, Vector3(-9.0 + float(i) * 6.0, 5.0, -24.0), Color(0.55, 0.58, 0.62))
				g.rotation = Vector3(PI * 0.5, 0, 0)
				st.animate(func(t: float) -> void: g.rotation.y = t * (0.6 if i % 2 == 0 else -0.6))
			Three.light_point(st, Vector3(0, 3, -6), Color(0.3, 0.9, 1.0), 2.0, 14.0)
		"desert":
			st.sky(Color(0.95, 0.70, 0.40), Color(1.0, 0.92, 0.70), Color(0.85, 0.65, 0.40))
			st.fog(Color(1.0, 0.88, 0.65), 0.014)
			st.sun(Vector3(-45, 20, 0), Color(1.0, 0.95, 0.8), 1.4)
			_ground(st, Color(0.90, 0.72, 0.42))
			for i in 8:                                         # Dunes
				var d := Three.ball(st, rng.randf_range(4.0, 9.0), Vector3(rng.randf_range(-30.0, 30.0), -1.5, -rng.randf_range(32.0, 50.0)), Color(0.88, 0.68, 0.38), 0.0, 0.0)
				d.scale = Vector3(1.6, 0.4, 1.0)
			for i in 3:                                         # Obelisks with his halo
				var x := -12.0 + float(i) * 12.0
				Three.box(st, Vector3(1.2, 7.0, 1.2), Vector3(x, 3.5, -26.0), Color(0.80, 0.62, 0.32))
				Three.ring(st, 0.6, 0.9, Vector3(x, 7.8, -26.0), Color(1.0, 0.85, 0.35), 1.2)
		"sewer":
			st.sky(Color(0.03, 0.05, 0.03), Color(0.10, 0.16, 0.10), Color(0.02, 0.03, 0.02))
			st.fog(Color(0.15, 0.3, 0.12), 0.06)
			st.sun(Vector3(-60, 0, 0), Color(0.6, 0.9, 0.6), 0.6)
			_ground(st, Color(0.15, 0.20, 0.14))
			Three.box(st, Vector3(40, 0.05, 3.0), Vector3(0, 0.02, -5.0), Color(0.3, 0.5, 0.2), 0.6, 0.0)   # Dirty water
			for i in 6:                                         # Pipes
				var p := Three.cyl(st, 0.5, 30.0, Vector3(0, 9.0 + float(i) * 1.4, -22.0 - float(i) * 2.0), Color(0.28, 0.32, 0.26))
				p.rotation = Vector3(0, 0, PI * 0.5)
			for i in 7:                                         # Brick arches (behind the action)
				Three.box(st, Vector3(1.0, 8.0, 1.0), Vector3(-15.0 + float(i) * 5.0, 4.0, -22.0), Color(0.30, 0.22, 0.18))
	# A few drifting motes everywhere (cheap life)
	for i in 6:
		var m := Three.ball(st, 0.08, Vector3(rng.randf_range(-12.0, 12.0), rng.randf_range(0.5, 4.0), -rng.randf_range(22.0, 30.0)), Color(1, 1, 1, 0.6), 1.0, 0.0)
		var base := m.position
		st.animate(func(t: float) -> void: m.position = base + Vector3(sin(t * 0.5 + float(i)) * 0.6, fmod(t * 0.3 + float(i) * 0.7, 3.0), 0))


# ============================================================
# IMPORTANT MAPS
# ============================================================
## The Blinded Lord's laboratory: glass tanks with skeletons, toxic green tubes.
static func _lab(st: Stage3D) -> void:
	st.sky(Color(0.03, 0.06, 0.04), Color(0.12, 0.20, 0.14), Color(0.02, 0.03, 0.02))
	st.fog(Color(0.10, 0.22, 0.10), 0.035)
	st.sun(Vector3(-50, 20, 0), Color(0.7, 1.0, 0.7), 0.8)
	_ground(st, Color(0.22, 0.28, 0.24))
	for i in 6:                                                 # Glass chambers (left and right, clear of the action)
		var x: float = [-19.0, -14.0, -9.0, 9.0, 14.0, 19.0][i]
		var z := -22.0 - float(i % 2) * 5.0
		Three.cyl(st, 1.4, 6.0, Vector3(x, 3.0, z), Color(0.5, 1.0, 0.6, 0.25), 0.4, 0.04, 16)
		Three.cyl(st, 1.6, 0.6, Vector3(x, 0.3, z), Color(0.3, 0.33, 0.35))
		Three.cyl(st, 1.6, 0.6, Vector3(x, 6.2, z), Color(0.3, 0.33, 0.35))
		Three.ball(st, 0.45, Vector3(x, 3.6, z), Color(0.9, 0.88, 0.8))          # Skull inside
		Three.cyl(st, 0.12, 1.6, Vector3(x, 2.6, z), Color(0.9, 0.88, 0.8))
	for i in 4:                                                 # Toxic tubes overhead
		var tube := Three.cyl(st, 0.35, 40.0, Vector3(0, 10.0 + float(i), -20.0 - float(i) * 3.0), Color(0.4, 1.0, 0.3), 1.5)
		tube.rotation = Vector3(0, 0, PI * 0.5)
	Three.light_point(st, Vector3(0, 4, -8), Color(0.4, 1.0, 0.4), 3.0, 20.0)


## Blasphemy Caeser's volcanic temple: lava sea, serpent skeleton coiled around it.
static func _blasphemy(st: Stage3D) -> void:
	st.sky(Color(0.10, 0.02, 0.02), Color(0.65, 0.20, 0.06), Color(0.08, 0.02, 0.02))
	st.fog(Color(0.45, 0.12, 0.04), 0.022)
	st.sun(Vector3(-30, 30, 0), Color(1.0, 0.55, 0.35), 1.0)
	Three.plane(st, Vector2(200, 200), Vector3(0, -0.4, -60), Color(1.0, 0.4, 0.08), 2.0)   # Lava sea
	Three.box(st, Vector3(30, 1.0, 12), Vector3(0, -0.2, -2), Color(0.18, 0.12, 0.12))
	# The temple
	Three.box(st, Vector3(14, 6, 8), Vector3(0, 3, -26), Color(0.20, 0.10, 0.10))
	Three.prism(st, Vector3(16, 4, 9), Vector3(0, 8, -26), Color(0.28, 0.12, 0.10))
	# Serpent skeleton: a spiral of vertebra balls + ribs around the temple
	for i in 34:
		var a := float(i) * 0.35
		var p := Vector3(cos(a) * 11.0, 1.0 + float(i) * 0.35, -26.0 + sin(a) * 7.0)
		Three.ball(st, 0.7, p, Color(0.88, 0.84, 0.72))
		if i % 2 == 0:
			var rib := Three.cyl(st, 0.12, 2.4, p, Color(0.88, 0.84, 0.72))
			rib.rotation = Vector3(0, -a, 0.9)
	Three.ball(st, 1.8, Vector3(cos(34.0 * 0.35) * 11.0, 13.5, -26.0 + sin(34.0 * 0.35) * 7.0), Color(0.88, 0.84, 0.72))   # Skull
	Three.light_point(st, Vector3(0, 2, -10), Color(1.0, 0.5, 0.15), 3.0, 25.0)


## The Architect's Golem hall: a vast rune hall, glowing rune circles, huge pillars.
static func _golem_hall(st: Stage3D) -> void:
	st.sky(Color(0.05, 0.08, 0.14), Color(0.15, 0.25, 0.38), Color(0.04, 0.05, 0.08))
	st.fog(Color(0.12, 0.2, 0.32), 0.03)
	st.sun(Vector3(-55, 25, 0), Color(0.7, 0.85, 1.0), 0.9)
	_ground(st, Color(0.40, 0.42, 0.45))
	for side: float in [-1.0, 1.0]:
		for i in 5:
			var z := -6.0 - float(i) * 7.0
			Three.box(st, Vector3(2.4, 14, 2.4), Vector3(side * 12.0, 7, z), Color(0.48, 0.48, 0.46))
			Three.box(st, Vector3(0.3, 10, 0.3), Vector3(side * 10.7, 6, z), Color(0.3, 0.8, 1.0), 2.0, 0.0)
	for i in 3:                                                 # Rune circles on the floor + far wall
		var rc := Three.ring(st, 2.2 + float(i), 2.5 + float(i), Vector3(0, 0.05, -20.0), Color(0.3, 0.85, 1.0), 2.0, 0.0)
		rc.scale = Vector3(1, 0.05, 1)
		st.animate(func(t: float) -> void: rc.rotation.y = t * (0.2 + 0.1 * float(i)))
	var wall := Three.ring(st, 5.0, 5.6, Vector3(0, 9, -40), Color(0.3, 0.85, 1.0), 2.5, 0.0)
	wall.rotation = Vector3(PI * 0.5, 0, 0)
	st.animate(func(t: float) -> void: wall.rotation.y = t * 0.15)
	Three.light_point(st, Vector3(0, 5, -18), Color(0.3, 0.8, 1.0), 3.0, 25.0)


## The Void Massacre's spider lair: webs everywhere, cocoons hanging, eyes in the dark.
static func _spider_lair(st: Stage3D) -> void:
	st.sky(Color(0.02, 0.0, 0.04), Color(0.10, 0.04, 0.16), Color(0.01, 0.0, 0.02))
	st.fog(Color(0.08, 0.03, 0.14), 0.05)
	st.sun(Vector3(-60, 0, 0), Color(0.6, 0.4, 0.9), 0.6)
	_ground(st, Color(0.14, 0.12, 0.16))
	var rng := RandomNumberGenerator.new()
	rng.seed = 34
	for i in 14:                                                # Web strands
		var a := Three.cyl(st, 0.03, 30.0, Vector3(rng.randf_range(-10.0, 10.0), 10.0, -rng.randf_range(24.0, 34.0)), Color(0.9, 0.9, 0.95, 0.6), 0.5, 0.0, 4)
		a.rotation = Vector3(rng.randf_range(-1.0, 1.0), 0, rng.randf_range(0.6, 2.4))
	for i in 10:                                                # Cocoons hanging
		var cv: Variant = spot(rng, 22.0, 5.0, 28.0)
		if cv == null:
			continue
		var p: Vector3 = (cv as Vector3) + Vector3(0, rng.randf_range(4.0, 9.0), 0)
		var c := Three.ball(st, 0.7, p, Color(0.85, 0.85, 0.8))
		c.scale = Vector3(0.8, 1.8, 0.8)
		Three.cyl(st, 0.03, 6.0, p + Vector3(0, 3.5, 0), Color(0.9, 0.9, 0.95), 0.0, 0.0, 4)
		st.animate(func(t: float) -> void: c.rotation.z = sin(t * 0.8 + float(i)) * 0.15)
	for i in 8:                                                 # Eyes in the dark
		Three.ball(st, 0.18, Vector3(rng.randf_range(-12.0, 12.0), rng.randf_range(1.0, 6.0), -rng.randf_range(18.0, 28.0)), Color(1, 1, 1), 3.0, 0.0)


## Mother Nature's world tree: a giant tree burning / flooding / crumbling / blowing at once.
static func _world_tree(st: Stage3D) -> void:
	st.sky(Color(0.25, 0.45, 0.75), Color(0.85, 0.85, 0.65), Color(0.3, 0.35, 0.2))
	st.fog(Color(0.75, 0.8, 0.65), 0.015)
	st.sun(Vector3(-40, 30, 0), Color(1.0, 0.95, 0.85), 1.2)
	_ground(st, Color(0.32, 0.50, 0.22))
	Three.cyl(st, 3.0, 22.0, Vector3(0, 11, -30), Color(0.40, 0.26, 0.14), 0.0, 0.06, 10)   # Trunk
	var crowns := [Color(1.0, 0.45, 0.1), Color(0.3, 0.6, 1.0), Color(0.55, 0.42, 0.25), Color(0.85, 0.95, 1.0)]  # Fire / water / earth / wind
	for i in 4:
		var a := float(i) * TAU / 4.0
		var cr := Three.ball(st, 6.0, Vector3(cos(a) * 6.0, 24.0 + sin(a) * 2.0, -30.0 + sin(a) * 4.0), (crowns[i] as Color).lerp(Color(0.25, 0.55, 0.2), 0.4), 0.3)
		st.animate(func(t: float) -> void: cr.scale = Vector3.ONE * (1.0 + 0.04 * sin(t * 1.5 + float(i))))
	for i in 8:                                                 # Roots
		var r := Three.cyl(st, 0.7, 12.0, Vector3(cos(float(i)) * 5.0, 0.4, -30.0 + sin(float(i)) * 5.0), Color(0.40, 0.26, 0.14))
		r.rotation = Vector3(0, -float(i), PI * 0.42)


## Satan's mountain cave: lava rivers, black rock, a throne of horns.
static func _satan_cave(st: Stage3D) -> void:
	st.sky(Color(0.05, 0.01, 0.01), Color(0.35, 0.06, 0.02), Color(0.04, 0.0, 0.0))
	st.fog(Color(0.30, 0.05, 0.02), 0.035)
	st.sun(Vector3(-40, 20, 0), Color(1.0, 0.4, 0.2), 0.9)
	_ground(st, Color(0.14, 0.08, 0.08))
	for i in 5:
		Three.box(st, Vector3(1.2, 0.05, 30.0), Vector3(-12.0 + float(i) * 6.0, 0.03, -18.0), Color(1.0, 0.35, 0.05), 2.5, 0.0)
	Three.box(st, Vector3(5, 3, 3), Vector3(0, 1.5, -22), Color(0.12, 0.05, 0.05))           # Throne
	Three.box(st, Vector3(5, 7, 1), Vector3(0, 5, -23.5), Color(0.12, 0.05, 0.05))
	for side: float in [-1.0, 1.0]:
		for k in 3:
			var horn := Three.cone(st, 0.5, 4.0, Vector3(side * (1.5 + float(k) * 1.2), 9.0 + float(k) * 0.6, -23.5), Color(0.9, 0.85, 0.75))
			horn.rotation = Vector3(0, 0, -side * (0.3 + 0.25 * float(k)))
	for i in 10:                                                # Stalactites
		var st_cone := Three.cone(st, 0.8, 5.0, Vector3(-16.0 + float(i) * 3.5, 14.0, -12.0 - float(i % 3) * 5.0), Color(0.18, 0.08, 0.06))
		st_cone.rotation = Vector3(PI, 0, 0)
	Three.light_point(st, Vector3(0, 3, -16), Color(1.0, 0.35, 0.1), 3.5, 25.0)


## The Sun Peak: above the clouds, white-gold stone, the blinding sky.
static func _sun_peak(st: Stage3D) -> void:
	st.sky(Color(0.95, 0.85, 0.55), Color(1.0, 0.98, 0.9), Color(1.0, 0.95, 0.85))
	st.fog(Color(1.0, 0.97, 0.88), 0.012)
	st.sun(Vector3(-50, 10, 0), Color(1.0, 0.95, 0.8), 1.5)
	_ground(st, Color(0.96, 0.92, 0.82))
	var sun := Three.ball(st, 8.0, Vector3(0, 22, -60), Color(1.0, 0.95, 0.7), 4.0, 0.0)
	st.animate(func(t: float) -> void: sun.scale = Vector3.ONE * (1.0 + 0.03 * sin(t * 2.0)))
	for i in 16:                                                # Clouds below the peak
		var c := Three.ball(st, 4.0, Vector3(-36.0 + float(i) * 5.0, -2.0, -14.0 - float(i % 3) * 8.0), Color(1, 1, 1), 0.2, 0.0)
		c.scale = Vector3(1.4, 0.6, 1.0)
	for side: float in [-1.0, 1.0]:
		Three.cyl(st, 0.7, 9.0, Vector3(side * 9.0, 4.5, -10.0), Color(0.98, 0.95, 0.85))
		Three.ball(st, 1.0, Vector3(side * 9.0, 9.5, -10.0), Color(1.0, 0.85, 0.4), 1.5)


## The First Prime's gong sanctum: a ring of huge gongs, incense, a ritual circle.
static func _prime_sanctum(st: Stage3D) -> void:
	st.sky(Color(0.08, 0.05, 0.03), Color(0.40, 0.26, 0.12), Color(0.06, 0.04, 0.02))
	st.fog(Color(0.35, 0.24, 0.12), 0.03)
	st.sun(Vector3(-50, 20, 0), Color(1.0, 0.8, 0.5), 1.0)
	_ground(st, Color(0.55, 0.45, 0.30))
	var circle := Three.ring(st, 4.0, 4.4, Vector3(0, 0.05, -14), Color(1.0, 0.8, 0.35), 2.0, 0.0)
	circle.scale = Vector3(1, 0.05, 1)
	st.animate(func(t: float) -> void: circle.rotation.y = t * 0.2)
	for i in 7:                                                 # Ring of gongs
		var a := PI * (0.15 + 0.7 * float(i) / 6.0)
		var p := Vector3(cos(a) * 14.0, 0, -14.0 - sin(a) * 9.0)
		var g := Three.cyl(st, 2.2, 0.3, p + Vector3(0, 4.5, 0), Color(0.85, 0.62, 0.25), 0.3, Three.OUTLINE, 20)
		g.rotation = Vector3(PI * 0.5, -a + PI * 0.5, 0)
		st.animate(func(t: float) -> void: g.rotation.z = sin(t * 2.0 + float(i)) * 0.06)
		for side: float in [-1.0, 1.0]:
			Three.box(st, Vector3(0.4, 7.5, 0.4), p + Vector3(side * 2.6 * sin(a), 3.7, side * 2.6 * cos(a)), Color(0.35, 0.2, 0.1))
	for i in 5:                                                 # Incense smoke columns
		var s := Three.cyl(st, 0.4, 10.0, Vector3(-8.0 + float(i) * 4.0, 5.0, -24.0), Color(0.9, 0.85, 0.75, 0.15), 0.0, 0.0, 8)
		st.animate(func(t: float) -> void: s.scale = Vector3(1.0 + 0.3 * sin(t + float(i)), 1, 1.0 + 0.3 * sin(t + float(i))))
	Three.light_point(st, Vector3(0, 3, -12), Color(1.0, 0.7, 0.3), 3.0, 22.0)


## The Enlightened One's sky reliquary: golden clouds, his hoard orbiting in the sky.
static func _sky_reliquary(st: Stage3D) -> void:
	st.sky(Color(0.95, 0.70, 0.35), Color(1.0, 0.93, 0.72), Color(1.0, 0.95, 0.85))
	st.fog(Color(1.0, 0.92, 0.75), 0.012)
	st.sun(Vector3(-40, 20, 0), Color(1.0, 0.92, 0.75), 1.4)
	_ground(st, Color(0.95, 0.88, 0.70))
	Three.ball(st, 7.0, Vector3(0, 24, -55), Color(1.0, 0.95, 0.7), 3.5, 0.0)
	for i in 12:                                                # Golden clouds
		var c := Three.ball(st, 5.0, Vector3(-40.0 + float(i) * 7.0, -3.0, -18.0 - float(i % 2) * 10.0), Color(1.0, 0.9, 0.7), 0.3, 0.0)
		c.scale = Vector3(1.4, 0.5, 1.0)
	var hoard := Node3D.new()                                   # His treasures, orbiting
	hoard.position = Vector3(0, 9, -24)
	st.add_child(hoard)
	for i in 14:
		var a := float(i) * TAU / 14.0
		var p := Vector3(cos(a) * 12.0, sin(float(i) * 1.7) * 3.0, sin(a) * 6.0)
		match i % 4:
			0:
				Three.cyl(hoard, 0.5, 1.2, p, Color(0.5, 0.3, 0.15))       # Barrel
			1:
				Three.ball(hoard, 0.6, p, Color(1.0, 0.82, 0.3), 0.5)        # Holy grenade
			2:
				Three.box(hoard, Vector3(0.9, 1.3, 0.25), p, Color(0.72, 0.70, 0.66))   # Tablet
			_:
				Three.cone(hoard, 0.6, 1.2, p, Color(0.85, 0.62, 0.25))      # Bell
	st.animate(func(t: float) -> void: hoard.rotation.y = t * 0.25)
