class_name AchievementCard
extends Control
## One achievement's artwork as a Control (AchievementArt). animate = redraw every frame
## (the toast, the hovered card). Otherwise the artwork is BAKED once into a picture (a hidden
## SubViewport, one card per frame) and drawn as ONE texture: the Achievements grid had ~6500
## draw calls per frame from 200+ clipped vector cards (sweep 2026-11-14). Pictures are cached for
## the session (id + locked + size).

var def: Dictionary = {}
var locked := false
var animate := false

var _t := 0.0
var _tex: Texture2D

static var _cache := {}                  # key -> ImageTexture
static var _queue: Array = []            # Cards waiting to be baked
static var _baking := false


func _ready() -> void:
	clip_contents = true
	set_process(animate)
	resized.connect(_request)
	_request.call_deferred()


func _key() -> String:
	return "%s|%s|%dx%d" % [def.get("id", ""), locked, int(size.x), int(size.y)]


func _request() -> void:
	if animate or def.is_empty() or size.x < 8.0 or size.y < 8.0:
		return
	var k := _key()
	if _cache.has(k):
		_tex = _cache[k]
		queue_redraw()
		return
	_tex = null
	if not _queue.has(self):
		_queue.append(self)
	if not _baking:
		_bake_queue.call_deferred(get_tree())


static func _bake_queue(tree: SceneTree) -> void:
	if _baking or tree == null:
		return
	_baking = true
	while not _queue.is_empty():
		# Up to 12 cards per frame: each gets a hidden viewport, all are read back after one frame
		var batch: Array = []
		while not _queue.is_empty() and batch.size() < 12:
			var card: AchievementCard = _queue.pop_front()
			if card == null or not is_instance_valid(card) or not card.is_inside_tree():
				continue
			var k := card._key()
			if _cache.has(k):
				card._tex = _cache[k]
				card.queue_redraw()
				continue
			var vp := SubViewport.new()
			vp.size = Vector2i(int(card.size.x), int(card.size.y))
			vp.transparent_bg = true
			vp.render_target_update_mode = SubViewport.UPDATE_ONCE
			var painter := Control.new()
			painter.size = card.size
			var d := card.def
			var lk := card.locked
			var r := Rect2(Vector2.ZERO, card.size).grow(-3.0)
			painter.draw.connect(func() -> void: AchievementArt.draw(painter, d, r, 0.0, lk))
			vp.add_child(painter)
			tree.root.add_child(vp)
			batch.append([card, k, vp])
		if batch.is_empty():
			continue
		await RenderingServer.frame_post_draw
		for b in batch:
			var vp2: SubViewport = b[2]
			if is_instance_valid(vp2):
				_cache[b[1]] = ImageTexture.create_from_image(vp2.get_texture().get_image())
				vp2.queue_free()
			var c: AchievementCard = b[0]
			if is_instance_valid(c) and c._key() == b[1]:
				c._tex = _cache.get(b[1])
				c.queue_redraw()
	_baking = false


func set_animate(on: bool) -> void:
	animate = on
	set_process(on)
	if not on:
		_t = 0.0
		_request()
	queue_redraw()


func _process(delta: float) -> void:
	_t += delta
	queue_redraw()


func _draw() -> void:
	if def.is_empty():
		return
	if not animate and _tex != null:
		draw_texture(_tex, Vector2.ZERO)                  # Baked: one draw call
		return
	AchievementArt.draw(self, def, Rect2(Vector2.ZERO, size).grow(-3.0), _t, locked)
