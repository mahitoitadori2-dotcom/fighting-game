class_name Three
extends RefCounted
## 3D TOOLKIT (cutscenes, important-map backdrops, menus - the FIGHTS stay 2D).
## Everything is built in code from simple shapes with a thick black cartoon OUTLINE (inverted
## hull), so it matches the game's flat 2D look. Characters are BILLBOARDS: their real 2D art
## drawn live into a small SubViewport and shown as a Sprite3D facing the camera.
##
##   Three.enabled()        3D on? (off on the POTATO graphics level: the old 2D versions run)
##   Three.view(parent)     a full-rect SubViewportContainer with its own 3D world -> Stage3D
##   box / cyl / cone / ball / ring / plane / prism   shapes (+ outline)
##   billboard()            a character / enemy / prop drawn by a 2D draw callable

const OUTLINE := 0.035


static func enabled() -> bool:
	return GraphicsSettings.level >= GraphicsSettings.FAST


## Render scale for 3D views (FAST renders at a lower resolution).
static func scale() -> float:
	return 0.6 if GraphicsSettings.level == GraphicsSettings.FAST else 1.0


# ============================================================
# VIEW
# ============================================================
## A full-rect 3D view inside `parent` (a Control or CanvasLayer). Returns its Stage3D.
static func view(parent: Node) -> Stage3D:
	var box := SubViewportContainer.new()
	box.name = "View3D"
	box.stretch = true
	box.stretch_shrink = 1 if scale() >= 1.0 else 2
	box.mouse_filter = Control.MOUSE_FILTER_IGNORE
	box.set_anchors_and_offsets_preset(Control.PRESET_FULL_RECT)
	parent.add_child(box)
	var vp := SubViewport.new()
	vp.own_world_3d = true
	vp.msaa_3d = Viewport.MSAA_DISABLED
	vp.render_target_update_mode = SubViewport.UPDATE_ALWAYS
	box.add_child(vp)
	var st := Stage3D.new()
	vp.add_child(st)
	return st


# ============================================================
# MATERIALS
# ============================================================
## While true (building a character / boss), materials keep their true colours: not hidden by
## the fog and a little self-lit, so they read like the flat 2D art in any light.
static var char_mode := false


static func mat(col: Color, glow: float = 0.0, unshaded: bool = false) -> StandardMaterial3D:
	var m := StandardMaterial3D.new()
	m.albedo_color = col
	m.roughness = 0.85
	if char_mode:
		m.disable_fog = true
		if glow <= 0.0:
			m.emission_enabled = true
			m.emission = col
			m.emission_energy_multiplier = 0.35
	if unshaded:
		m.shading_mode = BaseMaterial3D.SHADING_MODE_UNSHADED
	if glow > 0.0:
		m.emission_enabled = true
		m.emission = col
		m.emission_energy_multiplier = glow
	if col.a < 1.0:
		m.transparency = BaseMaterial3D.TRANSPARENCY_ALPHA
	return m


## Thick black outline (inverted hull) added as the material's next pass.
static func outlined(m: StandardMaterial3D, width: float = OUTLINE) -> StandardMaterial3D:
	if width <= 0.0:
		return m
	var o := StandardMaterial3D.new()
	o.shading_mode = BaseMaterial3D.SHADING_MODE_UNSHADED
	o.albedo_color = Color(0, 0, 0)
	o.cull_mode = BaseMaterial3D.CULL_FRONT
	o.grow = true
	o.grow_amount = width
	m.next_pass = o
	return m


# ============================================================
# SHAPES  (pos = centre; every one returns its MeshInstance3D)
# ============================================================
static func _mesh(parent: Node3D, mesh: Mesh, pos: Vector3, col: Color, glow: float, outline: float) -> MeshInstance3D:
	var mi := MeshInstance3D.new()
	mi.mesh = mesh
	mi.material_override = outlined(mat(col, glow), outline)
	mi.position = pos
	mi.cast_shadow = GeometryInstance3D.SHADOW_CASTING_SETTING_OFF
	parent.add_child(mi)
	return mi


static func box(parent: Node3D, size: Vector3, pos: Vector3, col: Color, glow: float = 0.0, outline: float = OUTLINE) -> MeshInstance3D:
	var m := BoxMesh.new()
	m.size = size
	return _mesh(parent, m, pos, col, glow, outline)


static func cyl(parent: Node3D, r: float, h: float, pos: Vector3, col: Color, glow: float = 0.0, outline: float = OUTLINE, sides: int = 12) -> MeshInstance3D:
	var m := CylinderMesh.new()
	m.top_radius = r
	m.bottom_radius = r
	m.height = h
	m.radial_segments = sides
	m.rings = 1
	return _mesh(parent, m, pos, col, glow, outline)


static func cone(parent: Node3D, r: float, h: float, pos: Vector3, col: Color, glow: float = 0.0, outline: float = OUTLINE, sides: int = 10) -> MeshInstance3D:
	var m := CylinderMesh.new()
	m.top_radius = 0.0
	m.bottom_radius = r
	m.height = h
	m.radial_segments = sides
	m.rings = 1
	return _mesh(parent, m, pos, col, glow, outline)


static func ball(parent: Node3D, r: float, pos: Vector3, col: Color, glow: float = 0.0, outline: float = OUTLINE) -> MeshInstance3D:
	var m := SphereMesh.new()
	m.radius = r
	m.height = r * 2.0
	m.radial_segments = 16
	m.rings = 8
	return _mesh(parent, m, pos, col, glow, outline)


## A capsule lying along x (bodies of beasts / moths).
static func cap_h(parent: Node3D, r: float, len: float, pos: Vector3, col: Color, glow: float = 0.0) -> MeshInstance3D:
	var m := CapsuleMesh.new()
	m.radius = r
	m.height = maxf(len, r * 2.0)
	m.radial_segments = 12
	m.rings = 4
	var mi := _mesh(parent, m, pos, col, glow, OUTLINE)
	mi.rotation.z = PI * 0.5
	return mi


static func ring(parent: Node3D, r_in: float, r_out: float, pos: Vector3, col: Color, glow: float = 0.0, outline: float = OUTLINE) -> MeshInstance3D:
	var m := TorusMesh.new()
	m.inner_radius = r_in
	m.outer_radius = r_out
	m.rings = 24
	m.ring_segments = 8
	return _mesh(parent, m, pos, col, glow, outline)


static func plane(parent: Node3D, size: Vector2, pos: Vector3, col: Color, glow: float = 0.0) -> MeshInstance3D:
	var m := PlaneMesh.new()
	m.size = size
	return _mesh(parent, m, pos, col, glow, 0.0)


static func prism(parent: Node3D, size: Vector3, pos: Vector3, col: Color, glow: float = 0.0, outline: float = OUTLINE) -> MeshInstance3D:
	var m := PrismMesh.new()
	m.size = size
	return _mesh(parent, m, pos, col, glow, outline)


## A rough rock: a squashed, rotated low-poly sphere.
static func rock(parent: Node3D, r: float, pos: Vector3, col: Color, seed_v: int = 0) -> MeshInstance3D:
	var m := SphereMesh.new()
	m.radius = r
	m.height = r * 1.6
	m.radial_segments = 6
	m.rings = 3
	var mi := _mesh(parent, m, pos, col, 0.0, OUTLINE)
	mi.rotation = Vector3(float(seed_v % 7) * 0.4, float(seed_v % 11) * 0.6, float(seed_v % 5) * 0.3)
	mi.scale = Vector3(1.0 + float(seed_v % 3) * 0.2, 1.0, 1.0 + float(seed_v % 4) * 0.15)
	return mi


static func light_point(parent: Node3D, pos: Vector3, col: Color, energy: float = 2.0, rng: float = 8.0) -> OmniLight3D:
	var l := OmniLight3D.new()
	l.light_color = col
	l.light_energy = energy
	l.omni_range = rng
	l.position = pos
	parent.add_child(l)
	return l


# ============================================================
# BILLBOARDS (live 2D art in the 3D world)
# ============================================================
## A billboard drawing `draw.call(canvas, t)` (origin = feet at the bottom middle of a
## px_w x px_h canvas, art scaled by art_scale). world_h = its height in the 3D world.
static func billboard(parent: Node3D, draw: Callable, pos: Vector3, world_h: float = 2.0, px := Vector2i(220, 280), art_scale: float = 1.6) -> Sprite3D:
	var vp := SubViewport.new()
	vp.size = px
	vp.transparent_bg = true
	vp.render_target_update_mode = SubViewport.UPDATE_ALWAYS
	parent.add_child(vp)
	var painter := BillboardPainter.new()
	painter.draw_fn = draw
	painter.art_scale = art_scale
	painter.size = Vector2(px)
	vp.add_child(painter)
	var s := Sprite3D.new()
	s.texture = vp.get_texture()
	s.billboard = BaseMaterial3D.BILLBOARD_FIXED_Y
	s.shaded = false
	s.alpha_cut = SpriteBase3D.ALPHA_CUT_DISCARD
	s.pixel_size = world_h / float(px.y)
	s.offset = Vector2(0, float(px.y) * 0.5)           # Origin at the feet
	s.position = pos
	s.set_meta("painter", painter)
	parent.add_child(s)
	return s


## Billboard of a hero's idle portrait ("warrior" / "architect" / "anti").
static func hero(parent: Node3D, hero_id: String, pos: Vector3, world_h: float = 2.0) -> Sprite3D:
	var art := StoryLevels.hero_art(hero_id)
	return billboard(parent, func(c: CanvasItem, t: float) -> void: art.call("draw_portrait", c, t), pos, world_h)


## Billboard of a hero RUNNING (real walk-cycle legs).
static func hero_running(parent: Node3D, hero_id: String, pos: Vector3, world_h: float = 2.0) -> Sprite3D:
	return billboard(parent, _run_draw.bind(hero_id), pos, world_h)


static func _run_draw(c: CanvasItem, t: float, hero_id: String) -> void:
	match hero_id:
		"warrior":
			WarriorArt._draw_figure(c, {"t": t, "ph": t * 15.0, "floor": true})
		"anti":
			ArchitectArt.set_palette(ArchitectArt.ANTI_PALETTE)
			ArchitectArt._draw_figure(c, t, t * 15.0, true, 0.0, 0.0, 0.0, 0.0, false, false)
			ArchitectArt.set_palette(ArchitectArt.NORMAL_PALETTE)
		_:
			ArchitectArt._draw_figure(c, t, t * 15.0, true, 0.0, 0.0, 0.0, 0.0, false, false)


## Billboard of a Story enemy / boss portrait (StoryLevels id), sized by its figure scale.
static func enemy(parent: Node3D, id: String, pos: Vector3, world_h: float = 2.4) -> Sprite3D:
	var base := StoryLevels.base_id(id)
	var fs: float = AchievementArt.ENEMY_SCALE.get(base, StoryBoard.FIGURE_SCALE.get(base, 0.3))
	var sc := fs * 300.0 / 62.0                             # Same sizing as the achievement art
	return billboard(parent, func(c: CanvasItem, t: float) -> void: StoryLevels.draw_portrait(c, id, t),
		pos, world_h, Vector2i(320, 320), sc)


## Billboard of any roster entry's art (Versus characters / enemies, for the menus).
static func roster(parent: Node3D, art: Script, pos: Vector3, world_h: float = 2.0) -> Sprite3D:
	var h := float(art.get_script_constant_map().get("PORTRAIT_H", 135.0))
	return billboard(parent, func(c: CanvasItem, t: float) -> void: art.call("draw_portrait", c, t),
		pos, world_h, Vector2i(220, 280), 1.6 * 135.0 / h)


## The painter of a billboard (to tilt it: painter_of(sprite).art_rot = ...).
static func painter_of(s: Sprite3D) -> BillboardPainter:
	return s.get_meta("painter", null) as BillboardPainter


## Draws a billboard's art each frame (feet at the bottom centre).
class BillboardPainter extends Control:
	var draw_fn: Callable
	var art_scale := 1.6
	var art_rot := 0.0                    # Tilt the art (lying down / rolling heroes)
	var flip := false                     # Mirror (face left)
	var _t := 0.0

	func _process(delta: float) -> void:
		_t += delta
		queue_redraw()

	func _draw() -> void:
		var pivot := Vector2(size.x * 0.5, size.y - 4.0)
		if art_rot != 0.0:
			pivot = Vector2(size.x * 0.5, size.y * 0.55)       # Tilts around the middle
		draw_set_transform(pivot, art_rot, Vector2(-art_scale if flip else art_scale, art_scale))
		if draw_fn.is_valid():
			draw_fn.call(self, _t)
		draw_set_transform(Vector2.ZERO, 0.0, Vector2.ONE)
