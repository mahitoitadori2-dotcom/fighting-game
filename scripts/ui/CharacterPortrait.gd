class_name CharacterPortrait
extends Control
## Animated idle portrait of a character, drawn with the same code as in-game.
## `art` must be a script with: static func draw_portrait(c: CanvasItem, t: float)

var art: Script
var accent := Color(0.35, 0.8, 1.0)
var art_scale := 1.6
## Height of the art in its own units (0 = from the art's PORTRAIT_H constant, else 135). The
## roster gives the big Story bosses theirs so they fit the card.
var portrait_h := 0.0

## Idle animation on (redrawn every frame). Character Select turns it on only for the hovered /
## picked cards: 50 portraits redrawn every frame dropped the menu to ~25 FPS (sweep 2026-11-14).
var animate := true

var _t := 0.0
## STILL portraits are BAKED into a picture once (one draw call instead of hundreds of shapes
## replayed every frame - Character Select had ~1800 draw calls on phones). Animating = live.
var bake := true
var _baked: Texture2D = null
var _baking := false
static var _queue: Array = []
static var _pumping := false
## PIXEL ART (2026-11-21): portraits are rendered at 1/PIX resolution and shown with hard,
## unfiltered pixels (same 3-unit pixels as the fighters in a fight). pixel = false for the painter.
const PIX := 3
var pixel := true
var _live_vp: SubViewport = null
var _live_painter: CharacterPortrait = null
static var _pix_shader: Shader = null


func _ready() -> void:
	clip_contents = true
	mouse_filter = Control.MOUSE_FILTER_IGNORE
	set_process(animate)
	if pixel and PixelArt.active():
		texture_filter = CanvasItem.TEXTURE_FILTER_NEAREST
		if _pix_shader == null:                      # Hard edges: no half-transparent pixels
			_pix_shader = Shader.new()
			_pix_shader.code = "shader_type canvas_item;\nvoid fragment() {\n\tvec4 c = texture(TEXTURE, UV);\n\tCOLOR = vec4(c.rgb, step(0.5, c.a)) * COLOR;\n}\n"
		var m := ShaderMaterial.new()
		m.shader = _pix_shader
		material = m


func _pixel_on() -> bool:
	return pixel and PixelArt.active()


func set_animate(on: bool) -> void:
	if on == animate:
		return
	animate = on
	set_process(on)
	if not on:
		_drop_live()                                 # The small live viewport only while animating
	queue_redraw()


func _notification(what: int) -> void:
	if what == NOTIFICATION_RESIZED:
		_baked = null                                # Re-bake at the new size


## Queue this portrait for baking (a few per frame, so opening a screen doesn't stall).
func _request_bake() -> void:
	if _baking or size.x < 4.0 or size.y < 4.0:
		return
	_baking = true
	_queue.append(self)
	if not _pumping:
		_pumping = true
		_pump.call_deferred(get_tree())


static func _pump(tree: SceneTree) -> void:
	while not _queue.is_empty():
		# A batch of portraits is drawn side by side on ONE hidden viewport and read back ONCE (one
		# get_image() per portrait stalled a frame each time on the web / phones), then cut apart.
		var batch: Array = []
		var x := 0
		var w_max := 0
		var h_max := 0
		while not _queue.is_empty() and batch.size() < 8:
			var p: CharacterPortrait = _queue.pop_front()
			if p == null or not is_instance_valid(p) or not p.is_inside_tree():
				continue
			var div := PIX if p._pixel_on() else 1
			var sz := Vector2i(maxi(floori(p.size.x / float(div)), 1), maxi(floori(p.size.y / float(div)), 1))
			batch.append([p, Vector2i(x, 0), sz, div])
			x += sz.x
			w_max = x
			h_max = maxi(h_max, sz.y)
		if batch.is_empty():
			break
		var vp := SubViewport.new()
		vp.size = Vector2i(maxi(w_max, 1), maxi(h_max, 1))
		vp.transparent_bg = true
		vp.render_target_update_mode = SubViewport.UPDATE_ONCE
		for e in batch:
			var src: CharacterPortrait = e[0]
			var painter := CharacterPortrait.new()
			painter.art = src.art
			painter.accent = src.accent
			painter.art_scale = src.art_scale
			painter.portrait_h = src.portrait_h
			painter.animate = false
			painter.bake = false
			painter.pixel = false
			painter.position = Vector2(e[1])
			painter.size = Vector2(e[2] * int(e[3]))
			painter.scale = Vector2.ONE / float(e[3])
			vp.add_child(painter)
		tree.root.add_child(vp)
		await RenderingServer.frame_post_draw
		if is_instance_valid(vp):
			var img := vp.get_texture().get_image()                 # ONE readback for the whole batch
			for e in batch:
				var p2: CharacterPortrait = e[0]
				if is_instance_valid(p2):
					p2._baked = ImageTexture.create_from_image(img.get_region(Rect2i(e[1], e[2])))
					p2._baking = false
					p2.queue_redraw()
			vp.queue_free()
		if tree == null or not is_instance_valid(tree.root):
			break
	_pumping = false

func _process(delta: float) -> void:
	_t += delta
	queue_redraw()


## Animated + pixel art: the live portrait is drawn into a small viewport (1 / PIX size) every frame.
func _live_texture() -> Texture2D:
	if _live_vp == null:
		_live_vp = SubViewport.new()
		_live_vp.transparent_bg = true
		_live_vp.render_target_update_mode = SubViewport.UPDATE_ALWAYS
		add_child(_live_vp)
		_live_painter = CharacterPortrait.new()
		_live_painter.pixel = false
		_live_painter.bake = false
		_live_painter.animate = true
		_live_painter.scale = Vector2.ONE / float(PIX)
		_live_vp.add_child(_live_painter)
	var want := Vector2i(maxi(floori(size.x / float(PIX)), 1), maxi(floori(size.y / float(PIX)), 1))
	if _live_vp.size != want:
		_live_vp.size = want
	_live_painter.art = art
	_live_painter.accent = accent
	_live_painter.art_scale = art_scale
	_live_painter.portrait_h = portrait_h
	_live_painter.size = size
	return _live_vp.get_texture()


func _drop_live() -> void:
	if _live_vp != null:
		_live_vp.queue_free()
		_live_vp = null
		_live_painter = null


func _draw() -> void:
	if bake and not animate:
		if _baked != null:
			draw_texture_rect(_baked, Rect2(Vector2.ZERO, size), false)
			return
		_request_bake()                              # Live this frame, baked from the next ones
	elif animate and _pixel_on():
		draw_texture_rect(_live_texture(), Rect2(Vector2.ZERO, size), false)
		return
	var center := Vector2(size.x * 0.5, size.y * 0.5)
	var r := minf(size.x, size.y) * 0.42

	# Glow + hexagon emblem behind the fighter
	draw_circle(center, r * 1.1, Color(accent.r, accent.g, accent.b, 0.14))
	var hex := PackedVector2Array()
	for i in 6:
		var a := TAU * float(i) / 6.0 + _t * 0.15
		hex.append(center + Vector2(cos(a), sin(a)) * r)
	draw_colored_polygon(hex, Color(0.08, 0.10, 0.15, 0.85))
	var closed := hex.duplicate()
	closed.append(hex[0])
	draw_polyline(closed, Color(0, 0, 0), 9.0, FighterArt.AA)
	draw_polyline(closed, accent, 4.0, FighterArt.AA)

	# Ground shadow
	var feet := Vector2(size.x * 0.5, size.y - 16.0)
	draw_set_transform(feet, 0.0, Vector2(1.0, 0.22))
	draw_circle(Vector2.ZERO, 70.0, Color(0, 0, 0, 0.35))

	# The fighter
	# Big art (the Fights-mode bosses) declares const PORTRAIT_H so it still fits the card
	var art_h := 135.0
	if art != null:
		art_h = maxf(art_h, float(art.get_script_constant_map().get("PORTRAIT_H", 135.0)))
	if portrait_h > 0.0:
		art_h = maxf(art_h, portrait_h)
	var s := minf(art_scale, (size.y - 30.0) / art_h)
	draw_set_transform(feet + Vector2(0, -4), 0.0, Vector2(s, s))
	if art != null:
		art.call("draw_portrait", self, _t)
	else:
		draw_string(ThemeDB.fallback_font, Vector2(-10, -50), "?", HORIZONTAL_ALIGNMENT_CENTER, -1, 60)
	draw_set_transform(Vector2.ZERO, 0.0, Vector2.ONE)
