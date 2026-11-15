class_name CraterMap
extends CanvasLayer
## The MAP of TERRA CRATERUM (M / TAB / the MAP button). Drawn from CraterWorld's layout, so it is
## accurate. Undiscovered regions stay in dark fog. The game does NOT pause (Souls rules).

var manager: CraterLand
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
	return manager.discovered.has(String(CraterWorld.region_at(x)["key"]))


func _draw_map() -> void:
	if manager == null or not is_instance_valid(manager):
		return
	var sz := _paint.size
	var c := _paint
	c.draw_rect(Rect2(Vector2.ZERO, sz), Color(0, 0, 0, 0.72))
	var r := Rect2(Vector2(sz.x * 0.05, sz.y * 0.2), Vector2(sz.x * 0.9, sz.y * 0.56))
	FighterArt.rrect(c, r.grow(10.0), Color(0.18, 0.10, 0.08), Color(0.10, 0.06, 0.05), Color(0.28, 0.16, 0.12), 10.0, 4.0)
	c.draw_rect(r, Color(0.08, 0.05, 0.05))
	FighterArt.label(c, Vector2(sz.x * 0.5, r.position.y - 30.0), "TERRA CRATERUM", 40, Color(1.0, 0.7, 0.5))
	var horizon := r.position.y + r.size.y * 0.72
	for reg in CraterWorld.REGIONS:
		var x0 := _mx(r, float(reg["x0"]))
		var x1 := _mx(r, float(reg["x1"]))
		var known: bool = manager.discovered.has(String(reg["key"]))
		var col: Color = reg["col"]
		c.draw_rect(Rect2(x0, r.position.y, x1 - x0, r.size.y), col.darkened(0.5) if known else Color(0.03, 0.03, 0.04))
		c.draw_line(Vector2(x0, r.position.y), Vector2(x0, r.end.y), Color(0.35, 0.22, 0.18, 0.6), 2.0)
		FighterArt.label(c, Vector2((x0 + x1) * 0.5, r.end.y - 14.0), String(reg["name"]) if known else "? ? ?", 14,
			Color(0.95, 0.8, 0.7) if known else Color(0.4, 0.4, 0.45))
	c.draw_line(Vector2(r.position.x, horizon), Vector2(r.end.x, horizon), Color(0.5, 0.32, 0.25), 3.0)
	var k := r.size.x / (CraterWorld.HALF * 2.0)
	for p in CraterWorld.props():
		var px := float(p["x"])
		if not _known(px):
			continue
		var ps := k * 2.2
		c.draw_set_transform(Vector2(_mx(r, px), horizon - (CraterWorld.FLOOR_Y + 4.0) * ps), 0.0, Vector2(ps, ps))
		CraterWorld.draw_prop(c, {"kind": p["kind"], "x": 0.0, "s": p["s"], "v": p["v"]})
		c.draw_set_transform(Vector2.ZERO, 0.0, Vector2.ONE)
	for i in CraterWorld.CAMPS.size():
		var cx := float(CraterWorld.CAMPS[i]["x"])
		if _known(cx) and not manager.camp_cleared(i):
			c.draw_circle(Vector2(_mx(r, cx), horizon - 18.0), 5.0, Color(0.85, 0.2, 0.15))
	# Bosses
	for b in CraterWorld.BOSSES:
		if not manager.discovered.has(String(b["region"])):
			continue
		var bx := _mx(r, float(b["x"]))
		var done: bool = manager.bosses_done.has(String(b["id"]))
		var hb := float(b["half"]) * k
		c.draw_rect(Rect2(bx - hb, horizon - 70.0, hb * 2.0, 70.0), Color(1.0, 0.6, 0.4, 0.10), true)
		c.draw_set_transform(Vector2(bx, horizon - 52.0), 0.0, Vector2(0.18, 0.18))
		StoryLevels.draw_portrait(c, String(b["id"]), _t)
		c.draw_set_transform(Vector2.ZERO, 0.0, Vector2.ONE)
		var title := "THE LAVA MELTER" if String(b["id"]) == "lava_melter" else "THE KHARLEMING LORD"
		FighterArt.label(c, Vector2(bx, horizon - 110.0), title, 13, Color(0.6, 0.6, 0.6) if done else (b["color"] as Color))
		if done:
			c.draw_line(Vector2(bx - 22, horizon - 76), Vector2(bx + 22, horizon - 30), Color(0.9, 0.2, 0.15), 4.0)
			c.draw_line(Vector2(bx + 22, horizon - 76), Vector2(bx - 22, horizon - 30), Color(0.9, 0.2, 0.15), 4.0)
	# NPCs
	for npc in [[CraterWorld.MINE_X, "VOLCANO SLAVE", manager.choice != "sacrifice"], [CraterWorld.REACTOR_X, "SACRIFICE", manager.choice != "slave"]]:
		var nx := float(npc[0])
		if not _known(nx):
			continue
		var np := Vector2(_mx(r, nx), horizon - 40.0)
		c.draw_circle(np, 6.0, Color(0.9, 0.85, 1.0) if npc[2] else Color(0.35, 0.3, 0.3))
		FighterArt.label(c, np + Vector2(0, -16), String(npc[1]) + ("" if npc[2] else " (dead)"), 11, Color(0.85, 0.8, 0.95) if npc[2] else Color(0.5, 0.45, 0.45))
	# CamTons
	for i in CraterWorld.SHRINES.size():
		var sx := float(CraterWorld.SHRINES[i]["x"])
		if not _known(sx):
			continue
		var sp := Vector2(_mx(r, sx), horizon - 8.0)
		var lit: bool = manager.shrines_lit.has(i)
		c.draw_circle(sp, 8.0, Color(0, 0, 0))
		c.draw_colored_polygon(PackedVector2Array([sp + Vector2(-5, 3), sp + Vector2(5, 3), sp + Vector2(0, -10)]), Color(1.0, 0.55, 0.15) if lit else Color(0.45, 0.45, 0.5))
		if i == manager.last_shrine:
			c.draw_arc(sp, 13.0, 0.0, TAU, 16, Color(1.0, 0.75, 0.3, 0.6 + 0.4 * sin(_t * 4.0)), 2.0)
	# Magma barrier + Basalt wall (once the front is known)
	if _known(CraterWorld.WALL_X):
		var gx := _mx(r, CraterWorld.MAGMA_GATE_X)
		if not manager._gate.drained:
			c.draw_rect(Rect2(gx - 3.0, horizon - 60.0, 6.0, 60.0), Color(1.0, 0.45, 0.1))
		var wx := _mx(r, CraterWorld.WALL_X)
		if not manager.wall_broken():
			c.draw_rect(Rect2(wx - 6.0, horizon - 70.0, 12.0, 70.0), Color(0.12, 0.12, 0.14))
			c.draw_rect(Rect2(wx - 6.0, horizon - 70.0, 12.0, 70.0), Color(0, 0, 0), false, 2.0)
		FighterArt.label(c, Vector2(wx, horizon - 84.0), "BASALT WALL  %d/%d" % [mini(manager.wall_pile(), CraterLand.CORPSES_NEEDED), CraterLand.CORPSES_NEEDED], 12, Color(1.0, 0.75, 0.5))
	if manager.player != null and is_instance_valid(manager.player):
		var px2 := _mx(r, manager.player.global_position.x)
		var f := float(manager.player.facing)
		var pa := Vector2(px2, horizon - 30.0 + sin(_t * 5.0) * 2.0)
		var tri := PackedVector2Array([pa + Vector2(10 * f, 0), pa + Vector2(-6 * f, -8), pa + Vector2(-6 * f, 8)])
		c.draw_colored_polygon(tri, Color(1, 1, 1))
		FighterArt.outline(c, tri, 2.0)
		FighterArt.label(c, pa + Vector2(0, -16), "YOU", 12, Color.WHITE)
	var by := r.end.y + 46.0
	FighterArt.label(c, Vector2(sz.x * 0.5, by), ("NIGHT" if manager.is_night() else "DAY") + ("     THE TECHNICIAN'S BREAKER: CARRIED" if manager.has_breaker else ""), 16, Color(0.85, 0.8, 0.8))


func _mx(r: Rect2, wx: float) -> float:
	return r.position.x + (wx + CraterWorld.HALF) / (CraterWorld.HALF * 2.0) * r.size.x
