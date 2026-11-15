class_name OrdMap
extends CanvasLayer
## The MAP of TERRA ORDINARIORUM (M / TAB / the MAP button). Drawn from OrdWorld's layout.
## Biomes you have not walked into stay in fog (the Snow Desert stays a mystery until you find it).

var manager: OrdLand
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


func _known(x: float) -> bool:
	return manager.discovered.has(String(OrdWorld.region_at(x)["key"]))


func _draw_map() -> void:
	if manager == null or not is_instance_valid(manager):
		return
	var sz := _paint.size
	var c := _paint
	c.draw_rect(Rect2(Vector2.ZERO, sz), Color(0, 0, 0, 0.72))
	var r := Rect2(Vector2(sz.x * 0.05, sz.y * 0.2), Vector2(sz.x * 0.9, sz.y * 0.56))
	FighterArt.rrect(c, r.grow(10.0), Color(0.55, 0.47, 0.34), Color(0.36, 0.30, 0.20), Color(0.70, 0.62, 0.46), 10.0, 4.0)
	c.draw_rect(r, Color(0.86, 0.80, 0.66))                        # Parchment: the regular land
	FighterArt.label(c, Vector2(sz.x * 0.5, r.position.y - 30.0), "TERRA ORDINARIORUM", 40, Color(0.95, 0.92, 0.82))
	var horizon := r.position.y + r.size.y * 0.78
	var k := r.size.x / (OrdWorld.HALF * 2.0)
	for reg in OrdWorld.REGIONS:
		var x0 := _mx(r, float(reg["x0"]))
		var x1 := _mx(r, float(reg["x1"]))
		var known: bool = manager.discovered.has(String(reg["key"]))
		c.draw_rect(Rect2(x0, r.position.y, x1 - x0, r.size.y), (reg["col"] as Color).lerp(Color(0.86, 0.80, 0.66), 0.45) if known else Color(0.30, 0.28, 0.26))
		c.draw_line(Vector2(x0, r.position.y), Vector2(x0, r.end.y), Color(0.45, 0.38, 0.28, 0.6), 2.0)
		FighterArt.label(c, Vector2((x0 + x1) * 0.5, r.end.y - 14.0), String(reg["name"]) if known else "? ? ?", 13,
			Color(0.20, 0.16, 0.12) if known else Color(0.55, 0.52, 0.5))
	c.draw_line(Vector2(r.position.x, horizon), Vector2(r.end.x, horizon), Color(0.35, 0.28, 0.2), 3.0)
	for l in OrdWorld.LEDGES:                                       # The mountain profile
		if not _known(float(l[0])):
			continue
		var lx0 := _mx(r, float(l[0]))
		var lx1 := _mx(r, float(l[1]))
		var lh := float(l[2]) * k * 2.5
		c.draw_rect(Rect2(lx0, horizon - lh, lx1 - lx0, lh), Color(0.45, 0.45, 0.5))
	for p in OrdWorld.props():
		var px := float(p["x"])
		if not _known(px):
			continue
		var ps := k * 2.2
		c.draw_set_transform(Vector2(_mx(r, px), horizon - (OrdWorld.FLOOR_Y + 4.0) * ps - float(p.get("y", 0.0)) * k * 2.5 + float(p.get("y", 0.0)) * ps), 0.0, Vector2(ps, ps))
		OrdWorld.draw_prop(c, {"kind": p["kind"], "x": 0.0, "s": p["s"], "v": p["v"], "y": p.get("y", 0.0)})
		c.draw_set_transform(Vector2.ZERO, 0.0, Vector2.ONE)
	# Places
	if _known(OrdWorld.SQUARE_X):
		var sx := _mx(r, OrdWorld.SQUARE_X)
		c.draw_circle(Vector2(sx, horizon - 30.0), 8.0, Color(0.3, 0.45, 0.85) if not manager.finger_done else Color(0.55, 0.55, 0.55))
		FighterArt.label(c, Vector2(sx, horizon - 52.0), "TOWN SQUARE" + ("  (light the candle)" if manager.has_candle and not manager.finger_done else ""), 12, Color(0.15, 0.2, 0.45))
	if _known(OrdWorld.CANDLE_X):
		var cxp := _mx(r, OrdWorld.CANDLE_X)
		var cy := horizon - OrdWorld.ledge_h(OrdWorld.CANDLE_X) * k * 2.5
		if not manager.has_candle:
			OrdArt.candle(c, Vector2(cxp, cy - 4.0), 0.6, _t)
		FighterArt.label(c, Vector2(cxp, cy - 40.0), "SUMMIT", 12, Color(0.2, 0.2, 0.3))
	if _known(OrdWorld.WALL_X + 100.0):
		var wx := _mx(r, OrdWorld.WALL_X)
		if not manager.wall_broken:
			c.draw_rect(Rect2(wx - 5.0, horizon - 50.0, 10.0, 50.0), Color(0.1, 0.1, 0.12))
	if manager.wall_broken and not manager.crystal_done and _known(OrdWorld.CRYSTAL_X):
		c.draw_circle(Vector2(_mx(r, OrdWorld.CRYSTAL_X), horizon - 40.0), 7.0, Color(0.6, 0.85, 1.0))
	if manager.finger_done:
		var bx := _mx(r, OrdWorld.BRIDGE_X)
		c.draw_line(Vector2(bx, horizon), Vector2(bx + 30.0, r.position.y + 10.0), Color(1.0, 0.92, 0.6), 4.0)
		FighterArt.label(c, Vector2(bx + 30.0, r.position.y + 26.0), "THE BRIDGE", 12, Color(0.45, 0.35, 0.1))
	# CamTons
	for i in OrdWorld.SHRINES.size():
		var shx := float(OrdWorld.SHRINES[i]["x"])
		if not _known(shx):
			continue
		var sp := Vector2(_mx(r, shx), horizon - OrdWorld.ledge_h(shx) * k * 2.5 - 8.0)
		var lit: bool = manager.shrines_lit.has(i)
		c.draw_circle(sp, 8.0, Color(0, 0, 0))
		c.draw_colored_polygon(PackedVector2Array([sp + Vector2(-5, 3), sp + Vector2(5, 3), sp + Vector2(0, -10)]), Color(1.0, 0.55, 0.15) if lit else Color(0.45, 0.45, 0.5))
		if i == manager.last_shrine:
			c.draw_arc(sp, 13.0, 0.0, TAU, 16, Color(1.0, 0.6, 0.2, 0.6 + 0.4 * sin(_t * 4.0)), 2.0)
	if manager.player != null and is_instance_valid(manager.player):
		var pl := manager.player
		var f := float(pl.facing)
		var ph := (manager._ground_y - pl.global_position.y) * k * 2.5
		var pa := Vector2(_mx(r, pl.global_position.x), horizon - 30.0 - maxf(ph, 0.0) + sin(_t * 5.0) * 2.0)
		var tri := PackedVector2Array([pa + Vector2(10 * f, 0), pa + Vector2(-6 * f, -8), pa + Vector2(-6 * f, 8)])
		c.draw_colored_polygon(tri, Color(0.9, 0.2, 0.15))
		FighterArt.outline(c, tri, 2.0)
		FighterArt.label(c, pa + Vector2(0, -16), "YOU", 12, Color(0.6, 0.1, 0.08))
	var by := r.end.y + 46.0
	FighterArt.label(c, Vector2(sz.x * 0.5, by), "THE LIGHTNING CANDLE: CARRIED" if manager.has_candle else "Somewhere high up, a light flickers on a mountain.", 16, Color(0.85, 0.9, 1.0))


func _mx(r: Rect2, wx: float) -> float:
	return r.position.x + (wx + OrdWorld.HALF) / (OrdWorld.HALF * 2.0) * r.size.x
