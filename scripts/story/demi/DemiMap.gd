class_name DemiMap
extends CanvasLayer
## The MAP of DemiLand (M / TAB / the MAP button). Drawn from DemiWorld's layout, so it is
## ACCURATE: every hill of scenery, shrine, camp, arena and the door sit where they really are.
## Regions you have not walked into yet stay covered in dark fog. No mission list - only the land.
## The game does NOT pause while the map is open (Souls rules).

var manager: DemiLand
var _paint: Control
var _t := 0.0


func _ready() -> void:
	layer = 30
	visible = false
	_paint = Control.new()
	_paint.set_anchors_and_offsets_preset(Control.PRESET_FULL_RECT)
	_paint.mouse_filter = Control.MOUSE_FILTER_IGNORE
	add_child(_paint)
	_paint.draw.connect(_draw_map)


func toggle() -> void:
	visible = not visible
	SoundManager.play_sfx("whoosh", -10.0)


func _process(delta: float) -> void:
	_t += delta
	if visible:
		_paint.queue_redraw()


func _draw_map() -> void:
	if manager == null or not is_instance_valid(manager):
		return
	var sz := _paint.size
	var c := _paint
	c.draw_rect(Rect2(Vector2.ZERO, sz), Color(0, 0, 0, 0.72))
	# The parchment-like (but dark) map rectangle
	var r := Rect2(Vector2(sz.x * 0.05, sz.y * 0.2), Vector2(sz.x * 0.9, sz.y * 0.56))
	FighterArt.rrect(c, r.grow(10.0), Color(0.16, 0.13, 0.10), Color(0.10, 0.08, 0.06), Color(0.24, 0.20, 0.15), 10.0, 4.0)
	c.draw_rect(r, Color(0.07, 0.065, 0.07))
	FighterArt.label(c, Vector2(sz.x * 0.5, r.position.y - 30.0), "DEMILAND", 40, Color(0.85, 0.80, 0.70))
	var horizon := r.position.y + r.size.y * 0.72                  # The floor line on the map
	# Regions: a coloured band each (fog if undiscovered)
	for reg in DemiWorld.REGIONS:
		var x0 := _mx(r, float(reg["x0"]))
		var x1 := _mx(r, float(reg["x1"]))
		var band := Rect2(x0, r.position.y, x1 - x0, r.size.y)
		var known: bool = manager.discovered.has(String(reg["key"]))
		var col: Color = reg["col"]
		c.draw_rect(band, col.darkened(0.55) if known else Color(0.03, 0.03, 0.04))
		c.draw_line(Vector2(x0, r.position.y), Vector2(x0, r.end.y), Color(0.3, 0.27, 0.22, 0.6), 2.0)
		FighterArt.label(c, Vector2((x0 + x1) * 0.5, r.end.y - 14.0), String(reg["name"]) if known else "? ? ?", 14,
			Color(0.9, 0.85, 0.75) if known else Color(0.4, 0.4, 0.45))
	# Ground line + scenery silhouettes (only in known regions)
	c.draw_line(Vector2(r.position.x, horizon), Vector2(r.end.x, horizon), Color(0.45, 0.40, 0.32), 3.0)
	var k := r.size.x / (DemiWorld.HALF * 2.0)
	for p in DemiWorld.props():
		var px := float(p["x"])
		if not manager.discovered.has(String(DemiWorld.region_at(px)["key"])):
			continue
		var ps := k * 2.2                                   # Scenery a little bigger than true scale (readable)
		c.draw_set_transform(Vector2(_mx(r, px), horizon - (DemiWorld.FLOOR_Y + 4.0) * ps), 0.0, Vector2(ps, ps))
		DemiWorld.draw_prop(c, {"kind": p["kind"], "x": 0.0, "s": p["s"], "v": p["v"]})
		c.draw_set_transform(Vector2.ZERO, 0.0, Vector2.ONE)
	# Camps (red dots) in known regions, while they still have enemies
	for i in DemiWorld.CAMPS.size():
		var cx := float(DemiWorld.CAMPS[i]["x"])
		if manager.discovered.has(String(DemiWorld.region_at(cx)["key"])) and not manager.camp_cleared(i):
			c.draw_circle(Vector2(_mx(r, cx), horizon - 18.0), 5.0, Color(0.85, 0.2, 0.15))
	# Boss arenas: skull + name (crossed out when beaten)
	for b in DemiWorld.BOSSES:
		var bx := _mx(r, float(b["x"]))
		var known: bool = manager.discovered.has(String(b["region"]))
		if not known:
			continue
		var done: bool = manager.bosses_done.has(String(b["id"]))
		var hb := float(b["half"]) * k
		c.draw_rect(Rect2(bx - hb, horizon - 70.0, hb * 2.0, 70.0), Color(0.6, 0.6, 0.7, 0.10), true)
		c.draw_set_transform(Vector2(bx, horizon - 52.0), 0.0, Vector2(0.18, 0.18))
		StoryLevels.draw_portrait(c, String(b["id"]), _t)
		c.draw_set_transform(Vector2.ZERO, 0.0, Vector2.ONE)
		var title: String = {"last_tiger": "THE LAST TIGER", "tribe_master": "THE TRIBE MASTER", "tree_lord": "THE TREE LORD"}.get(String(b["id"]), "BOSS")
		FighterArt.label(c, Vector2(bx, horizon - 110.0), title, 13,
			Color(0.6, 0.6, 0.6) if done else (b["color"] as Color))
		if done:
			c.draw_line(Vector2(bx - 22, horizon - 76), Vector2(bx + 22, horizon - 30), Color(0.9, 0.2, 0.15), 4.0)
			c.draw_line(Vector2(bx + 22, horizon - 76), Vector2(bx - 22, horizon - 30), Color(0.9, 0.2, 0.15), 4.0)
	# CamTons: flame icons (lit) / grey (seen, not lit)
	for i in DemiWorld.SHRINES.size():
		var sx := float(DemiWorld.SHRINES[i]["x"])
		if not manager.discovered.has(String(DemiWorld.region_at(sx)["key"])):
			continue
		var sp := Vector2(_mx(r, sx), horizon - 8.0)
		var lit: bool = manager.shrines_lit.has(i)
		c.draw_circle(sp, 8.0, Color(0, 0, 0))
		c.draw_colored_polygon(PackedVector2Array([sp + Vector2(-5, 3), sp + Vector2(5, 3), sp + Vector2(0, -10)]), Color(1.0, 0.55, 0.15) if lit else Color(0.45, 0.45, 0.5))
		if i == manager.last_shrine:
			c.draw_arc(sp, 13.0, 0.0, TAU, 16, Color(1.0, 0.75, 0.3, 0.6 + 0.4 * sin(_t * 4.0)), 2.0)
	# The Ancient Door (always known: you start there) with its sockets
	var dx := _mx(r, DemiWorld.DOOR_X)
	var door := Rect2(dx - 14.0, horizon - 64.0, 28.0, 64.0)
	c.draw_rect(door, Color(0.30, 0.28, 0.34))
	c.draw_rect(door, Color(0, 0, 0), false, 2.5)
	for i in 3:
		var filled: bool = manager.door_placed().size() > i
		c.draw_circle(Vector2(dx - 8.0 + float(i) * 8.0, horizon - 38.0), 3.0, Color(0.7, 0.6, 1.0) if filled else Color(0.05, 0.05, 0.06))
	FighterArt.label(c, Vector2(dx, horizon - 78.0), "THE ANCIENT DOOR", 13, Color(0.75, 0.7, 0.95))
	# YOU (an arrow pointing the way you face)
	if manager.player != null and is_instance_valid(manager.player):
		var px2 := _mx(r, manager.player.global_position.x)
		var f := float(manager.player.facing)
		var pa := Vector2(px2, horizon - 30.0 + sin(_t * 5.0) * 2.0)
		c.draw_colored_polygon(PackedVector2Array([pa + Vector2(10 * f, 0), pa + Vector2(-6 * f, -8), pa + Vector2(-6 * f, 8)]), Color(1, 1, 1))
		FighterArt.outline(c, PackedVector2Array([pa + Vector2(10 * f, 0), pa + Vector2(-6 * f, -8), pa + Vector2(-6 * f, 8)]), 2.0)
		FighterArt.label(c, pa + Vector2(0, -16), "YOU", 12, Color.WHITE)
	# Carried artifacts + time of day (bottom)
	var by := r.end.y + 46.0
	FighterArt.label(c, Vector2(sz.x * 0.5, by), ("NIGHT" if manager.is_night() else "DAY"), 16, Color(0.8, 0.8, 0.85))
	var carried: Array = manager.carried
	for i in carried.size():
		DemiWorld.draw_artifact(c, String(carried[i]), Vector2(sz.x * 0.5 - 40.0 * float(carried.size() - 1) * 0.5 + 40.0 * float(i), by + 40.0), 0.7, _t)


func _mx(r: Rect2, wx: float) -> float:
	return r.position.x + (wx + DemiWorld.HALF) / (DemiWorld.HALF * 2.0) * r.size.x
