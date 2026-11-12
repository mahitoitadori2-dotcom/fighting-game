class_name Scenes3D
extends RefCounted
## 3D CUTSCENES (StoryCutscene shows them when Three.enabled(); else the old 2D painting).
## Each kind builds a little 3D scene into a Stage3D: a diorama (Maps3D), the heroes / bosses
## as REAL 3D MODELS (Hero3D / Boss3D - no 2D characters), props, and a camera path. StoryCutscene drives the time and draws the
## captions + fades on top.
##
## STORY CUTSCENES: elevator, sewer_fall, corpse_climb, throne_wake, cave_roll, void_fall,
##   c5_intro, mountain_climb, reach_peak, fall_to_earth, enl_chase, enl_end
## LEVEL INTROS (every level that has no story cutscene - each level gets one of these, so
## level starts look different): intro_walk, intro_fly, intro_fall, intro_gate, intro_boss

const STORY := ["elevator", "sewer_fall", "corpse_climb", "throne_wake", "cave_roll", "void_fall",
	"c5_intro", "mountain_climb", "reach_peak", "fall_to_earth", "enl_chase", "enl_end"]
const INTROS := ["intro_walk", "intro_fly", "intro_fall", "intro_gate", "intro_boss"]
const INTRO_LEN := {"intro_walk": 4.2, "intro_fly": 4.4, "intro_fall": 3.8, "intro_gate": 4.6, "intro_boss": 4.8}


static func has(kind: String) -> bool:
	return STORY.has(kind) or INTROS.has(kind)


## Which intro a level gets: boss levels -> boss reveal; the first level in a new area -> a gate
## opening; the rest alternate between walking in, flying over and falling in.
static func intro_for(n: int) -> String:
	var lv := StoryLevels.get_level(n)
	if String(lv.get("boss", "")) != "":
		return "intro_boss"
	var prev := StoryLevels.get_level(n - 1) if n > 1 and not StoryLevels.is_ext(n) else {}
	if prev.is_empty() or String(prev.get("map", "")) != String(lv.get("map", "")):
		return "intro_gate"
	return ["intro_walk", "intro_fly", "intro_fall"][n % 3]


## ctx: {hero, other, level}
static func build(st: Stage3D, kind: String, ctx: Dictionary) -> void:
	var hero := String(ctx.get("hero", "warrior"))
	var other := String(ctx.get("other", "architect"))
	var n := int(ctx.get("level", 1))
	match kind:
		"elevator":
			_elevator(st, hero)
		"sewer_fall":
			_sewer_fall(st, hero)
		"corpse_climb":
			_corpse_climb(st, hero)
		"throne_wake":
			_throne_wake(st, hero)
		"cave_roll":
			_cave_roll(st, hero)
		"void_fall":
			_void_fall(st, hero)
		"c5_intro":
			_c5_intro(st, hero, other)
		"mountain_climb":
			_mountain_climb(st, hero)
		"reach_peak":
			_reach_peak(st, hero)
		"fall_to_earth":
			_fall_to_earth(st, hero)
		"enl_chase":
			_enl_chase(st, hero, other)
		"enl_end":
			_enl_end(st, hero)
		_:
			_intro(st, kind, hero, n)


static func _k(t: float, a: float, b: float) -> float:
	return clampf((t - a) / maxf(b - a, 0.001), 0.0, 1.0)


# ============================================================
# LEVEL INTROS
# ============================================================
static func _intro(st: Stage3D, kind: String, hero: String, n: int) -> void:
	var theme := Maps3D.theme_of_level(n)
	var tile: Color = StoryBoard.MAP_TILE.get(String(StoryLevels.get_level(n).get("map", "wastes")), Color(0.5, 0.4, 0.3))
	Maps3D.build(st, theme, tile)
	match kind:
		"intro_walk":                                            # You walk in from the left
			var h := Hero3D.make(st, hero, Vector3(-9, 0, 0), "run")
			h.face(Vector3.RIGHT)
			st.animate(func(t: float) -> void:
				h.position.x = lerpf(-9.0, 0.0, _k(t, 0.0, 3.0))
				h.pose = "run" if t < 3.0 else "idle")
			st.cam_key(0.0, Vector3(-9, 1.6, 6), Vector3(-8, 1.2, 0))
			st.cam_key(3.0, Vector3(0, 1.8, 6.5), Vector3(0, 1.2, 0))
			st.cam_key(4.2, Vector3(3, 3.0, 8), Vector3(0, 1.0, -6))
		"intro_fly":                                             # The camera flies over the area to you
			var hf := Hero3D.make(st, hero, Vector3(0, 0, 0))
			hf.face(Vector3(0.4, 0, 1))
			st.cam_key(0.0, Vector3(0, 18, -40), Vector3(0, 0, -10))
			st.cam_key(2.6, Vector3(4, 7, -6), Vector3(0, 1, 0))
			st.cam_key(4.4, Vector3(1, 2, 6), Vector3(0, 1.2, 0))
		"intro_fall":                                            # You drop in from the sky
			var h2 := Hero3D.make(st, hero, Vector3(0, 14, 0), "fall")
			h2.face(Vector3(0.3, 0, 1))
			var dust := Three.ring(st, 0.3, 0.6, Vector3(0, 0.1, 0), Color(0.9, 0.85, 0.75, 0.6), 0.0, 0.0)
			dust.visible = false
			st.animate(func(t: float) -> void:
				var k := _k(t, 0.3, 1.5)
				h2.position.y = 14.0 * (1.0 - k * k)
				h2.pose = "fall" if k < 1.0 else "idle"
				dust.visible = t > 1.5 and t < 2.4
				dust.scale = Vector3.ONE * (1.0 + _k(t, 1.5, 2.4) * 5.0) * Vector3(1, 0.2, 1))
			st.cam_key(0.0, Vector3(0, 1.0, 7), Vector3(0, 9, 0))
			st.cam_key(1.5, Vector3(0, 1.0, 7), Vector3(0, 1, 0))
			st.cam_key(3.8, Vector3(-3, 2.2, 7.5), Vector3(0, 1.2, -3))
		"intro_gate":                                            # A giant gate opens onto the new area
			var gz := -4.0
			for side: float in [-1.0, 1.0]:
				Three.box(st, Vector3(1.2, 9, 1.2), Vector3(side * 3.6, 4.5, gz), Color(0.35, 0.3, 0.28))
			Three.box(st, Vector3(9, 1.2, 1.4), Vector3(0, 9.4, gz), Color(0.4, 0.35, 0.32))
			var dl := Three.box(st, Vector3(3.0, 8, 0.4), Vector3(-1.5, 4, gz), Color(0.45, 0.32, 0.18))
			var dr := Three.box(st, Vector3(3.0, 8, 0.4), Vector3(1.5, 4, gz), Color(0.45, 0.32, 0.18))
			var light := Three.plane(st, Vector2(6, 8), Vector3(0, 4, gz - 0.4), Color(1.0, 0.95, 0.8), 3.0)
			light.rotation = Vector3(PI * 0.5, 0, 0)
			var h3 := Hero3D.make(st, hero, Vector3(0, 0, 4), "idle")
			h3.face(Vector3.FORWARD)
			st.animate(func(t: float) -> void:
				var o := _k(t, 0.8, 2.4)
				dl.position.x = -1.5 - o * 2.6
				dr.position.x = 1.5 + o * 2.6
				h3.position.z = lerpf(4.0, gz - 2.0, _k(t, 1.8, 4.4))
				h3.pose = "run" if t > 1.8 else "idle")
			st.cam_key(0.0, Vector3(0, 2, 10), Vector3(0, 3, gz))
			st.cam_key(2.4, Vector3(0, 2, 8), Vector3(0, 2.5, gz))
			st.cam_key(4.6, Vector3(0, 2.2, gz + 2.0), Vector3(0, 2.0, gz - 10.0))
		_:                                                       # intro_boss: the boss ARRIVES (Boss3D.ENTRANCE)
			var boss := String(StoryLevels.get_level(n).get("boss", "parasite"))
			var how := Boss3D.entrance(boss)                         # rise / fall / walk / there
			var spot := Vector3(0, 0, -12)
			var b := Boss3D.make(st, boss, spot, 6.5)
			b.face(Vector3(0.55, 0, 1))                              # Three-quarter view, facing you
			var hb := Hero3D.make(st, hero, Vector3(-1.5, 0, 2))
			hb.face(Vector3(0.2, 0, -1))
			var flash_l := Three.light_point(st, Vector3(0, 6, -8), Color(1.0, 0.95, 0.85), 0.0, 30.0)
			var dust := Three.ring(st, 0.5, 1.0, spot + Vector3(0, 0.1, 0), Color(0.85, 0.8, 0.7, 0.6), 0.0, 0.0)
			dust.visible = false
			st.env.ambient_light_energy = 0.25
			st.animate(func(t: float) -> void:
				match how:
					"rise":                                      # Blasphemy Caeser: up out of the magma
						var rise := _k(t, 1.8, 2.8)
						b.position.y = -8.0 + 8.0 * (1.0 - (1.0 - rise) * (1.0 - rise))
					"fall":                                      # Drops from the sky - and the ground shakes
						var f := _k(t, 1.6, 2.4)
						b.position.y = 18.0 * (1.0 - f * f)
						dust.visible = t > 2.4 and t < 3.4
						dust.scale = Vector3.ONE * (1.0 + _k(t, 2.4, 3.4) * 7.0) * Vector3(1, 0.15, 1)
						if t > 2.4 and t < 2.9:
							st.camera.position += Vector3(sin(t * 80.0), cos(t * 70.0), 0) * 0.12 * (1.0 - _k(t, 2.4, 2.9))
					"walk":                                      # Walks in from the side
						var w := _k(t, 0.2, 2.7)
						b.position.x = lerpf(-15.0, 0.0, w)
						b.set_pose("walk" if w < 1.0 else "menace")
						b.face(Vector3(1, 0, 0.2) if w < 1.0 else Vector3(0.55, 0, 1))
					_:                                           # Already there, waiting in the dark
						b.set_pose("menace")
				var flash := 1.0 - _k(t, 2.7, 3.6)
				flash_l.light_energy = 8.0 * flash * _k(t, 2.6, 2.75)
				st.env.ambient_light_energy = 0.25 + 0.8 * _k(t, 2.6, 3.0))
			st.cam_key(0.0, Vector3(-3, 1.6, 6), Vector3(-1.5, 1.4, 0))
			st.cam_key(2.6, Vector3(-1, 2.2, 5), Vector3(0, 3, -12))
			st.cam_key(4.8, Vector3(2.0, 3.2, 8.0), Vector3(0, 3.5, -12))    # Keeps its distance from you


# ============================================================
# STORY CUTSCENES
# ============================================================
static func _elevator(st: Stage3D, hero: String) -> void:
	st.sky(Color(0.05, 0.04, 0.05), Color(0.30, 0.10, 0.06), Color(0.4, 0.08, 0.02))
	st.fog(Color(0.25, 0.08, 0.04), 0.03)
	st.sun(Vector3(-70, 20, 0), Color(1.0, 0.6, 0.4), 0.9)
	var rig := Node3D.new()                                      # Everything that rises
	st.add_child(rig)
	Three.box(rig, Vector3(7, 0.6, 5), Vector3(0, 0, 0), Color(0.35, 0.36, 0.40))
	for i in 7:
		Three.box(rig, Vector3(0.9, 0.62, 5.05), Vector3(-3.0 + float(i) * 1.0, 0, 0), Color(0.95, 0.75, 0.1) if i % 2 == 0 else Color(0.1, 0.1, 0.1), 0.0, 0.0)
	for sx: float in [-3.2, 3.2]:
		Three.cyl(rig, 0.08, 60.0, Vector3(sx, 30, 0), Color(0.5, 0.5, 0.55), 0.0, 0.0, 6)
	Hero3D.make(rig, hero, Vector3(0, 0.3, 0)).face(Vector3(0.3, 0, 1))
	for side: float in [-1.0, 1.0]:                             # The shaft walls with girders (static)
		Three.box(st, Vector3(1, 200, 12), Vector3(side * 7.0, 60, 0), Color(0.12, 0.12, 0.14), 0.0, 0.0)
		for k in 30:
			Three.box(st, Vector3(1.5, 0.6, 12), Vector3(side * 6.4, float(k) * 6.0 - 20.0, 0), Color(0.24, 0.22, 0.22))
			Three.ball(st, 0.2, Vector3(side * 5.6, float(k) * 6.0 - 19.4, 3.0), Color(1.0, 0.5, 0.15), 2.5, 0.0)
	Three.plane(st, Vector2(40, 40), Vector3(0, -25, 0), Color(1.0, 0.35, 0.05), 3.0)      # Lava far below
	var eyes: Array = []
	for ex: float in [-2.5, -0.8, 0.8, 2.5]:
		var e := Three.ball(st, 0.5, Vector3(ex, -22, -2), Color(0.5, 1.0, 1.0), 4.0, 0.0)
		e.visible = false
		eyes.append(e)
	st.animate(func(t: float) -> void:
		rig.position.y = t * 3.2
		for e in eyes:
			(e as Node3D).visible = t > 4.2)
	st.cam_key(0.0, Vector3(5, 3, 8), Vector3(0, 1.2, 0))
	st.cam_key(4.0, Vector3(4, 15, 7), Vector3(0, 13, 0))
	st.cam_key(6.5, Vector3(2, 18, 3), Vector3(0, 0, 0))       # Looks down: the eyes below


static func _sewer_fall(st: Stage3D, hero: String) -> void:
	st.sky(Color(0.02, 0.04, 0.02), Color(0.1, 0.18, 0.1), Color(0.02, 0.03, 0.02))
	st.fog(Color(0.12, 0.25, 0.10), 0.05)
	st.sun(Vector3(-80, 0, 0), Color(0.7, 1.0, 0.7), 0.8)
	for k in 26:                                                 # A brick shaft (rings of blocks)
		for i in 8:
			var a := float(i) * TAU / 8.0
			var b := Three.box(st, Vector3(2.6, 1.2, 0.8), Vector3(cos(a) * 4.0, -float(k) * 1.6, sin(a) * 4.0), Color(0.30, 0.22, 0.18).lerp(Color(0.2, 0.3, 0.18), float(k % 3) * 0.2), 0.0, 0.02)
			b.rotation.y = -a + PI * 0.5
	Three.plane(st, Vector2(12, 12), Vector3(0, -42, 0), Color(0.3, 0.5, 0.2), 0.8)
	var h := Hero3D.make(st, hero, Vector3(0, 0, 0), "fall")
	var splash := Three.ring(st, 0.4, 0.8, Vector3(0, -41.8, 0), Color(0.6, 0.9, 0.5, 0.7), 0.5, 0.0)
	st.animate(func(t: float) -> void:
		h.position.y = -40.0 * _k(t, 0.0, 2.6)
		h.spin = t * 3.0
		splash.visible = t > 2.6
		splash.scale = Vector3.ONE * (1.0 + _k(t, 2.6, 3.4) * 4.0) * Vector3(1, 0.2, 1))
	st.animate(func(t: float) -> void:
		st.camera.position = Vector3(0, h.position.y + 6.0, 0.5)
		st.camera.look_at(h.position, Vector3.FORWARD))


static func _corpse_climb(st: Stage3D, hero: String) -> void:
	Maps3D.build(st, "blasphemy")
	var path: Array = []                                          # The serpent's corpse: a stairway
	for i in 26:
		var p := Vector3(-14.0 + float(i) * 1.1, float(i) * 0.6, -6.0 + sin(float(i) * 0.3) * 1.5)
		Three.ball(st, 1.0, p, Color(0.85, 0.82, 0.70))
		path.append(p + Vector3(0, 1.0, 0))
	var shrine: Vector3 = path[path.size() - 1] + Vector3(2, 0, 0)
	Three.box(st, Vector3(3, 0.5, 3), shrine, Color(1.0, 0.85, 0.45), 1.5)
	var glow := Three.ball(st, 1.2, shrine + Vector3(0, 2, 0), Color(1.0, 0.95, 0.6), 4.0, 0.0)
	var h := Hero3D.make(st, hero, path[0], "run")
	st.animate(func(t: float) -> void:
		var u := _k(t, 2.4, 7.6) * float(path.size() - 1)
		var i := mini(int(u), path.size() - 2)
		h.position = (path[i] as Vector3).lerp(path[i + 1], u - float(i))
		h.face((path[i + 1] as Vector3) - (path[i] as Vector3))
		h.pose = "run" if t > 2.4 and t < 7.6 else "idle"
		glow.scale = Vector3.ONE * (1.0 + 0.2 * sin(t * 4.0)))
	st.cam_key(0.0, Vector3(0, 10, 18), Vector3(0, 4, -10))
	st.cam_key(2.4, Vector3(-10, 4, 8), Vector3(-12, 2, -6))
	st.cam_key(7.6, Vector3(14, 18, 6), Vector3(14, 15, -6))
	st.cam_key(8.0, Vector3(14, 18, 6), Vector3(14, 15, -6))


static func _throne_wake(st: Stage3D, hero: String) -> void:
	Maps3D.build(st, "throne", Color(0.5, 0.2, 0.1))
	Three.box(st, Vector3(3, 2, 2), Vector3(0, 1, -10), Color(0.35, 0.15, 0.08))
	Three.box(st, Vector3(3, 6, 0.6), Vector3(0, 3, -11), Color(0.35, 0.15, 0.08))
	var flames: Array = []
	for i in 14:
		var f := Three.cone(st, 0.5, 1.6, Vector3(-8.0 + float(i) * 1.2, 0.8, -9.0 + sin(float(i)) * 1.5), Color(1.0, 0.5, 0.1), 2.5, 0.0)
		flames.append(f)
	var h := Hero3D.make(st, hero, Vector3(0, 0, 0), "lie")
	h.face(Vector3(0.3, 0, 1))
	st.animate(func(t: float) -> void:
		h.pose = "lie" if t < 2.2 else "idle"                          # Wakes up and stands
		for i in flames.size():
			(flames[i] as Node3D).scale = Vector3(1, 0.7 + 0.4 * absf(sin(t * 6.0 + float(i))), 1))
	st.cam_key(0.0, Vector3(0, 6, 3), Vector3(0, 0, 0))          # Waking: looking down at you
	st.cam_key(2.5, Vector3(2, 2, 5), Vector3(0, 1, 0))
	st.cam_key(6.0, Vector3(-3, 3, 7), Vector3(0, 2, -10))       # ...the burning throne


static func _cave_roll(st: Stage3D, hero: String) -> void:
	Maps3D.build(st, "dark_cave", Color(0.2, 0.2, 0.23))
	var slope := Three.box(st, Vector3(40, 1, 6), Vector3(0, 6, -2), Color(0.25, 0.25, 0.28))
	slope.rotation.z = -0.32
	var h := Hero3D.make(st, hero, Vector3(-16, 12.5, -2), "roll")
	st.animate(func(t: float) -> void:
		var k := _k(t, 0.0, 3.6)
		h.position = Vector3(lerpf(-16.0, 16.0, k), lerpf(12.5, 0.0, k), -2.0)
		h.pose = "roll" if t < 3.6 else "idle"
		h.spin = -t * 7.0 if t < 3.6 else 0.0)
	st.cam_key(0.0, Vector3(-10, 12, 12), Vector3(-14, 11, -2))
	st.cam_key(3.6, Vector3(10, 4, 10), Vector3(15, 1, -2))
	st.cam_key(5.0, Vector3(12, 3, 8), Vector3(16, 1, -6))


static func _void_fall(st: Stage3D, hero: String) -> void:
	st.sky(Color(0.0, 0.0, 0.0), Color(0.06, 0.02, 0.10), Color(0.0, 0.0, 0.0))
	st.fog(Color(0.05, 0.0, 0.08), 0.04)
	st.sun(Vector3(-90, 0, 0), Color(0.6, 0.4, 1.0), 0.8)
	var rng := RandomNumberGenerator.new()
	rng.seed = 29
	var bones: Array = []
	for i in 40:                                                  # Bones rushing UP past you
		var ba := rng.randf() * TAU                                  # A ring around you: never through you / the camera
		var br := rng.randf_range(3.0, 7.0)
		var b := Three.cyl(st, 0.15, rng.randf_range(1.0, 2.0), Vector3(cos(ba) * br, -rng.randf_range(0.0, 60.0), sin(ba) * br - 1.5), Color(0.85, 0.82, 0.75))
		b.rotation = Vector3(rng.randf() * 3.0, rng.randf() * 3.0, rng.randf() * 3.0)
		bones.append([b, b.position])
	var h := Hero3D.make(st, hero, Vector3(0, 0, 0), "fall")
	st.animate(func(t: float) -> void:
		h.spin = sin(t * 3.0) * 0.6
		for e in bones:                                            # They rush up (you fall)
			var base: Vector3 = e[1]
			(e[0] as Node3D).position.y = fmod(base.y + 60.0 + t * 18.0, 60.0) - 50.0)
	st.cam_key(0.0, Vector3(0, -6, 3), Vector3(0, 1, 0))          # Below you, looking up
	st.cam_key(3.6, Vector3(2, -4, 4), Vector3(0, 1, 0))


static func _c5_intro(st: Stage3D, hero: String, other: String) -> void:
	Maps3D.build(st, "thornwood", Color(0.22, 0.1, 0.1))
	Three.cone(st, 30.0, 50.0, Vector3(0, 25, -110), Color(0.25, 0.12, 0.12), 0.0, 0.1, 8)   # The mountain
	var peak := Three.ball(st, 3.0, Vector3(0, 52, -110), Color(1.0, 0.95, 0.7), 5.0, 0.0)
	var a := Hero3D.make(st, hero, Vector3(-1.2, 0, 4), "run")
	var b := Hero3D.make(st, other, Vector3(1.2, 0, 4), "run")
	a.face(Vector3.FORWARD)
	b.face(Vector3.FORWARD)
	st.animate(func(t: float) -> void:
		a.position.z = 4.0 - t * 2.4
		b.position.z = 4.0 - t * 2.4
		peak.scale = Vector3.ONE * (1.0 + 0.2 * sin(t * 2.0)))
	st.cam_key(0.0, Vector3(0, 1.6, 9), Vector3(0, 1.5, 0))
	st.cam_key(3.2, Vector3(0, 3, 2), Vector3(0, 8, -60))
	st.cam_key(6.5, Vector3(0, 8, -4), Vector3(0, 40, -110))


static func _mountain_climb(st: Stage3D, hero: String) -> void:
	st.sky(Color(0.15, 0.10, 0.20), Color(0.70, 0.40, 0.30), Color(0.2, 0.1, 0.1))
	st.fog(Color(0.5, 0.3, 0.25), 0.02)
	st.sun(Vector3(-30, 40, 0), Color(1.0, 0.8, 0.7), 1.1)
	Three.box(st, Vector3(30, 60, 4), Vector3(0, 30, -3), Color(0.32, 0.26, 0.24))   # The cliff face
	var rng := RandomNumberGenerator.new()
	rng.seed = 49
	for i in 30:
		var rx := rng.randf_range(2.0, 9.0) * (1.0 if i % 2 == 0 else -1.0)   # Never on your climbing line
		Three.rock(st, rng.randf_range(0.4, 1.0), Vector3(rx, rng.randf_range(0.0, 50.0), -0.8), Color(0.40, 0.33, 0.30), i)
	var cave := Three.ball(st, 3.0, Vector3(2, 46, -1.0), Color(1.0, 0.3, 0.1), 3.0, 0.0)   # The red cave near the top
	cave.scale = Vector3(1.2, 0.8, 0.3)
	var h := Hero3D.make(st, hero, Vector3(0, 0, -0.4), "climb")
	h.face(Vector3.FORWARD)
	st.animate(func(t: float) -> void: h.position.y = 40.0 * _k(t, 0.0, 7.0) + absf(sin(t * 5.0)) * 0.3)
	st.cam_key(0.0, Vector3(0, 2, 12), Vector3(0, 2, 0))
	st.cam_key(7.0, Vector3(4, 42, 14), Vector3(1, 44, 0))
	st.cam_key(8.0, Vector3(4, 44, 12), Vector3(2, 46, 0))


static func _reach_peak(st: Stage3D, hero: String) -> void:
	Maps3D.build(st, "sun_peak")
	var h := Hero3D.make(st, hero, Vector3(-6, 0, 0), "run")      # Walks onto the peak
	var sun := Boss3D.make(st, "the_sun", Vector3(0, 20, -14), 7.0)
	sun.face(Vector3(0, 0, 1))
	st.animate(func(t: float) -> void:
		h.position.x = lerpf(-6.0, 0.0, _k(t, 0.0, 1.6))
		h.pose = "run" if t < 1.6 else "idle"
		h.face(Vector3.RIGHT if t < 1.6 else Vector3(0.2, 0, -1))
		sun.position.y = lerpf(20.0, 1.0, _k(t, 2.4, 5.4)))
	st.cam_key(0.0, Vector3(0, 1, 6), Vector3(0, 0.5, 0))
	st.cam_key(2.4, Vector3(-4, 3, 7), Vector3(0, 6, -14))
	st.cam_key(6.0, Vector3(-2, 2.5, 9), Vector3(0, 3, -10))


static func _fall_to_earth(st: Stage3D, hero: String) -> void:
	st.sky(Color(0.02, 0.02, 0.08), Color(0.25, 0.30, 0.60), Color(0.4, 0.6, 1.0))
	st.sun(Vector3(-40, 30, 0), Color(1, 1, 1), 1.2)
	var boom := Three.ball(st, 2.0, Vector3(0, 30, -20), Color(1.0, 0.55, 0.15), 5.0, 0.0)    # The Consumer explodes
	var earth := Three.ball(st, 40.0, Vector3(0, -120, -10), Color(0.25, 0.5, 0.85), 0.2, 0.0)
	for i in 6:                                                   # Continents
		Three.ball(st, 9.0, Vector3(cos(float(i)) * 30.0, -95.0 + sin(float(i) * 2.0) * 8.0, -10.0 + sin(float(i)) * 25.0), Color(0.3, 0.6, 0.25), 0.0, 0.0)
	var clouds: Array = []
	for i in 20:
		var cx := randf_range(4.5, 15.0) * (1.0 if i % 2 == 0 else -1.0)   # Never through you
		var c := Three.ball(st, 3.0, Vector3(cx, -20.0 - float(i) * 3.0, randf_range(-12.0, -4.0)), Color(1, 1, 1, 0.85), 0.3, 0.0)
		c.scale = Vector3(1.5, 0.5, 1.0)
		clouds.append(c)
	var h := Hero3D.make(st, hero, Vector3(0, 20, 0), "fall")
	st.animate(func(t: float) -> void:
		boom.scale = Vector3.ONE * (1.0 + _k(t, 0.0, 3.0) * 12.0)
		boom.visible = t < 3.6
		h.position.y = 20.0 - t * 8.0
		h.spin = t * 1.5
		earth.rotation.y = t * 0.05)
	st.animate(func(t: float) -> void:
		st.camera.position = h.position + Vector3(2, 4, 8)
		st.camera.look_at(h.position + Vector3(0, -4, 0), Vector3.UP))


static func _enl_chase(st: Stage3D, hero: String, other: String) -> void:
	Maps3D.build(st, "golden_dunes")
	var lying := Hero3D.make(st, other, Vector3(-6, 0, 2), "lie")
	lying.face(Vector3(0, 0, 1))
	var one := Hero3D.make(st, "enlightened", Vector3(6, 0, 0), "run")
	one.face(Vector3.RIGHT)
	var h := Hero3D.make(st, hero, Vector3(-3, 0, 0), "run")
	h.face(Vector3.RIGHT)
	st.animate(func(t: float) -> void:
		one.position.x = 6.0 + t * 3.2
		h.position.x = -3.0 + t * 3.1)
	st.animate(func(t: float) -> void:
		var mid := (h.position.x + one.position.x) * 0.5
		st.camera.position = Vector3(mid - (2.0 if t < 2.5 else 0.0), 2.4, 9.0)
		st.camera.look_at(Vector3(mid + 1.0, 1.4, 0), Vector3.UP))


static func _enl_end(st: Stage3D, hero: String) -> void:
	Maps3D.build(st, "sky_reliquary")
	var cloud: Array = []                                          # The DARK CLOUD forming above
	for i in 14:
		var a := float(i) * TAU / 14.0
		var c := Three.ball(st, 3.0, Vector3(cos(a) * 6.0, 16.0 + sin(a * 2.0), -10.0 + sin(a) * 3.0), Color(0.08, 0.03, 0.12), 0.0, 0.0)
		c.scale = Vector3.ZERO
		cloud.append(c)
	var items: Array = []                                          # Everything he threw rises into it
	for i in 16:
		var p := Vector3(-12.0 + float(i) * 1.6, 0.4, -8.0 + sin(float(i)) * 1.5)   # Behind the two of them
		var it: MeshInstance3D
		match i % 3:
			0:
				it = Three.cyl(st, 0.4, 1.0, p, Color(0.5, 0.3, 0.15))
			1:
				it = Three.ball(st, 0.45, p, Color(1.0, 0.82, 0.3), 0.5)
			_:
				it = Three.box(st, Vector3(0.7, 1.0, 0.2), p, Color(0.72, 0.70, 0.66))
		items.append([it, p])
	var one := Hero3D.make(st, "enlightened", Vector3(1, 0, -2), "kneel_point")   # Points at the sky
	one.face(Vector3(-0.3, 0, 1))
	var hw := Hero3D.make(st, hero, Vector3(-4, 0, 1))
	hw.face(Vector3(1, 0, -0.5))
	st.animate(func(t: float) -> void:
		var dark := _k(t, 1.0, 4.0)
		st.env.ambient_light_energy = 0.7 - 0.45 * dark
		for c in cloud:
			(c as Node3D).scale = Vector3.ONE * dark * (1.0 + 0.1 * sin(t * 2.0))
		for i in items.size():
			var e: Array = items[i]
			var u := _k(t, 1.5 + float(i) * 0.12, 5.0 + float(i) * 0.12)
			var start: Vector3 = e[1]
			var spin := Vector3(cos(t * 3.0 + float(i)), 0, sin(t * 3.0 + float(i))) * 2.0 * u * (1.0 - u)
			(e[0] as Node3D).position = start.lerp(Vector3(0, 16, -10), u * u) + spin
			(e[0] as Node3D).scale = Vector3.ONE * (1.0 - 0.8 * u)
			(e[0] as Node3D).rotation = Vector3(t * 2.0, t * 3.0, 0))
	st.cam_key(0.0, Vector3(-2, 2, 9), Vector3(0, 1.5, -2))
	st.cam_key(3.0, Vector3(-4, 1.5, 9), Vector3(0, 8, -6))
	st.cam_key(10.0, Vector3(-6, 3, 13), Vector3(0, 12, -8))
