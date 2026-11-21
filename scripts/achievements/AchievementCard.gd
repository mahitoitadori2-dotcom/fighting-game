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
const ATLAS_W := 1024                     # Width of the shared bake canvas


## MEMORY: the baked pictures are only needed while the Achievements menu is open (AchievementsMenu
## calls this when it closes). The toast draws live, it never needs them.
static func clear_cache() -> void:
	_cache.clear()
	_queue.clear()


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
		# A batch of cards is drawn side by side on ONE hidden viewport and read back ONCE, then cut into
		# per-card pictures. (One get_image() per card stalled the frame each time on the web / phones.)
		var batch: Array = []
		var x := 0
		var row_h := 0
		var y := 0
		var w_max := 0
		while not _queue.is_empty() and batch.size() < 12:
			var card: AchievementCard = _queue.pop_front()
			if card == null or not is_instance_valid(card) or not card.is_inside_tree():
				continue
			var k := card._key()
			if _cache.has(k):
				card._tex = _cache[k]
				card.queue_redraw()
				continue
			var sz := Vector2i(int(card.size.x), int(card.size.y))
			if x + sz.x > ATLAS_W and x > 0:
				x = 0
				y += row_h
				row_h = 0
			batch.append([card, k, Vector2i(x, y), sz, card.def, card.locked])
			x += sz.x
			row_h = maxi(row_h, sz.y)
			w_max = maxi(w_max, x)
		if batch.is_empty():
			continue
		var vp := SubViewport.new()
		vp.size = Vector2i(maxi(w_max, 1), maxi(y + row_h, 1))
		vp.transparent_bg = true
		vp.render_target_update_mode = SubViewport.UPDATE_ONCE
		for e in batch:
			var painter := Control.new()
			painter.position = Vector2(e[2])
			painter.size = Vector2(e[3])
			painter.clip_contents = true                    # Never bleed into the neighbour cell
			var d: Dictionary = e[4]
			var lk: bool = e[5]
			var r := Rect2(Vector2.ZERO, Vector2(e[3])).grow(-3.0)
			painter.draw.connect(func() -> void: AchievementArt.draw(painter, d, r, 0.0, lk))
			vp.add_child(painter)
		tree.root.add_child(vp)
		await RenderingServer.frame_post_draw
		if is_instance_valid(vp):
			var img := vp.get_texture().get_image()               # ONE readback for the whole batch
			for e in batch:
				_cache[e[1]] = ImageTexture.create_from_image(img.get_region(Rect2i(e[2], e[3])))
				var c: AchievementCard = e[0]
				if is_instance_valid(c) and c._key() == e[1]:
					c._tex = _cache.get(e[1])
					c.queue_redraw()
			vp.queue_free()
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
