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


func _ready() -> void:
	clip_contents = true
	mouse_filter = Control.MOUSE_FILTER_IGNORE
	set_process(animate)


func set_animate(on: bool) -> void:
	if on == animate:
		return
	animate = on
	set_process(on)
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
		var batch: Array = []
		while not _queue.is_empty() and batch.size() < 6:
			var p: CharacterPortrait = _queue.pop_front()
			if p == null or not is_instance_valid(p) or not p.is_inside_tree():
				continue
			var vp := SubViewport.new()
			vp.size = Vector2i(int(p.size.x), int(p.size.y))
			vp.transparent_bg = true
			vp.render_target_update_mode = SubViewport.UPDATE_ONCE
			var painter := CharacterPortrait.new()
			painter.art = p.art
			painter.accent = p.accent
			painter.art_scale = p.art_scale
			painter.portrait_h = p.portrait_h
			painter.animate = false
			painter.bake = false
			painter.size = p.size
			vp.add_child(painter)
			p.add_child(vp)
			batch.append([p, vp])
		if batch.is_empty():
			break
		await RenderingServer.frame_post_draw
		for b in batch:
			var p2: CharacterPortrait = b[0]
			var vp2: SubViewport = b[1]
			if is_instance_valid(p2) and is_instance_valid(vp2):
				p2._baked = ImageTexture.create_from_image(vp2.get_texture().get_image())
				p2._baking = false
				p2.queue_redraw()
			if is_instance_valid(vp2):
				vp2.queue_free()
		if tree == null or not is_instance_valid(tree.root):
			break
	_pumping = false


func _process(delta: float) -> void:
	_t += delta
	queue_redraw()


func _draw() -> void:
	if bake and not animate:
		if _baked != null:
			draw_texture(_baked, Vector2.ZERO)
			return
		_request_bake()                              # Live this frame, baked from the next ones
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
