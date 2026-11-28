class_name StoryHUD
extends CanvasLayer
## STORY MODE HUD.
##   Top-left:   YOUR HP bar, G Gauge, move cooldowns, FLASKS (R)
##   Top-centre: Colosseum / level title, wave + enemies left
##   Boss bar:   ONLY during the boss fight (normal enemies only have their small
##               hovering EnemyHUD bars - no big bar at the top).
## Redrawn 10x per second (not every frame).

var manager: StoryManager
var _painter: Control
var _acc := 0.0


func _ready() -> void:
	layer = 10
	_painter = Control.new()
	_painter.set_anchors_and_offsets_preset(Control.PRESET_FULL_RECT)
	_painter.mouse_filter = Control.MOUSE_FILTER_IGNORE
	add_child(_painter)
	_painter.draw.connect(_paint)


func _process(delta: float) -> void:
	_acc += delta
	if _acc >= 0.1:
		_acc = 0.0
		_painter.queue_redraw()


## PERFORMANCE (/nolags 2026-11-26): every shape of the HUD (bars, gauge, flasks) is recorded into ONE
## mesh (one draw call instead of ~50: Godot can't batch rects with polygons with text), then every
## text is drawn after it: all outlines first, then all letters, so they batch too. (No text sits on a
## shape, so the order change looks the same.)
var _mc: MeshCanvas
var _mesh: ArrayMesh
var _labels: Array = []


func _paint() -> void:
	_mc = MeshCanvas.new()
	_labels.clear()
	_paint_parts()
	_mesh = _mc.build()                     # (Kept in a member: the renderer uses it after _paint returns)
	if _mesh != null:
		_painter.draw_mesh(_mesh, null)
	var font := ThemeDB.fallback_font
	for pass_i in 2:
		for l in _labels:
			var p: Vector2 = l[0]
			var s: String = l[1]
			var size: int = l[2]
			var col: Color = l[3]
			var w := -1.0
			if bool(l[4]):
				w = maxf(320.0, font.get_string_size(s, HORIZONTAL_ALIGNMENT_LEFT, -1, size).x + 12.0)
				p -= Vector2(w * 0.5, 0.0)
			var al := HORIZONTAL_ALIGNMENT_CENTER if bool(l[4]) else HORIZONTAL_ALIGNMENT_LEFT
			if pass_i == 0:
				_painter.draw_string_outline(font, p, s, al, w, size, 5, Color(0, 0, 0, col.a))
			else:
				_painter.draw_string(font, p, s, al, w, size, col)


## Same as FighterArt.label, drawn after the shapes (see above).
func _label(pos: Vector2, s: String, size: int = 14, col: Color = Color.WHITE, center: bool = true) -> void:
	_labels.append([pos, s, size, col, center])


func _bar(r: Rect2, k: float, col: Color) -> void:
	_mc.draw_rect(r, Color(0, 0, 0))
	_mc.draw_rect(r.grow(-2.0), Color(0.12, 0.10, 0.10))
	k = clampf(k, 0.0, 1.0)
	if k > 0.0:
		var fr := Rect2(r.position + Vector2(2, 2), Vector2((r.size.x - 4.0) * k, r.size.y - 4.0))
		_mc.draw_rect(fr, col)
		_mc.draw_rect(Rect2(fr.position, Vector2(fr.size.x, fr.size.y * 0.35)), col.lightened(0.3))


func _paint_parts() -> void:
	if manager == null or not is_instance_valid(manager):
		return
	var sz := _painter.size
	var p := manager.player

	# ---------------- Player panel ----------------
	if p != null and is_instance_valid(p):
		var x := 24.0
		var y := 20.0
		var k := float(p.hp) / maxf(float(p.data.max_hp), 1.0)
		var who := StoryLevels.hero_name(manager.hero)
		if p.confuse_timer > 0.0:
			who += "   -   CONFUSED (controls reversed) %.1fs" % p.confuse_timer
		_label(Vector2(x, y + 12), "%s   %d / %d" % [who, p.hp, p.data.max_hp], 18, Color.WHITE, false)
		var col := Color(0.15, 0.85, 0.25) if k > 0.5 else (Color(1.0, 0.7, 0.1) if k > 0.25 else Color(0.9, 0.15, 0.15))
		_bar(Rect2(x, y + 24, 300, 22), k, col)
		# STAMINA (Souls rules, open world only): green bar, dark yellow + "EXHAUSTED" when empty
		var gy := 50.0
		if SoulsRules.active and p is ControlledFighter:
			var cp := p as ControlledFighter
			var sr := Rect2(x, y + 49, 240, 8)
			_mc.draw_rect(sr, Color(0, 0, 0))
			var sk := cp.stamina / SoulsRules.MAX_STAMINA
			_mc.draw_rect(Rect2(sr.position + Vector2(1, 1), Vector2((sr.size.x - 2) * sk, sr.size.y - 2)), Color(0.75, 0.65, 0.15) if cp.exhausted else Color(0.3, 0.85, 0.35))
			if cp.exhausted:
				_label(Vector2(x + 248, y + 57), "EXHAUSTED", 12, Color(1.0, 0.85, 0.3), false)
			gy = 61.0
		# G Gauge
		if p.gauge != null:
			var v := p.gauge.value / p.gauge.segment_size
			for i in 3:
				var seg := Rect2(x + float(i) * 100.0, y + gy, 96, 9)
				_mc.draw_rect(seg, Color(0, 0, 0))
				var fill := Color(0.1, 0.65, 1.0) if v >= float(i + 1) else (Color(0.1, 0.35, 0.65) if v > float(i) else Color(0.12, 0.18, 0.25))
				_mc.draw_rect(seg.grow(-1.5), fill)
		# Flasks
		var fy := y + 80
		_label(Vector2(x, fy + 4), "FLASKS", 15, Color(0.75, 1.0, 0.75), false)
		for i in manager.max_flasks:
			_flask(Vector2(x + 86 + float(i) * 30.0, fy), i < manager.flasks)
		var fx := x + 92.0 + float(manager.max_flasks) * 30.0
		var ftxt := "[R]  +%d%% HP" % int(StoryManager.FLASK_HEAL * 100.0)
		_label(Vector2(fx, fy + 4), ftxt, 14, Color(1, 1, 1, 0.7), false)
		if manager.max_flasks > StoryManager.FLASKS_PER_LEVEL:
			# Deep Faith tag next to the HP bar (it used to sit under the boss bar and got cut off)
			_label(Vector2(x + 308.0, y + 40.0), "DEEP FAITH", 12, Color(1.0, 0.85, 0.4, 0.9), false)
		# Cooldowns
		var cf := p as ControlledFighter
		if cf != null:
			for i in cf.move_ids.size():
				var id := cf.move_ids[i]
				var t: float = cf.cooldowns.get(id, 0.0)
				var txt := "[%d] %s: %s" % [i + 1, String(cf.move_names.get(id, id)).to_upper(), "READY" if t <= 0.0 else "%.1fs" % t]
				_label(Vector2(x, fy + 34 + float(i) * 21.0), txt, 16, Color(1, 1, 1, 0.9) if t <= 0.0 else Color(1, 1, 1, 0.55), false)
		# Colosseum 5: your CPU partner
		var pa := manager.partner
		if pa != null and is_instance_valid(pa) and pa.visible:
			var py := fy + 104.0
			var pname := String(pa.data.character_name).to_upper()
			if pa.is_dead:
				_label(Vector2(x, py + 12), "PARTNER  %s:  DOWN - reviving..." % pname, 15, Color(1.0, 0.6, 0.5), false)
			else:
				var pk := float(pa.hp) / maxf(float(pa.data.max_hp), 1.0)
				_label(Vector2(x, py + 12), "PARTNER  %s (CPU)   %d / %d" % [pname, pa.hp, pa.data.max_hp], 15, Color(0.75, 0.9, 1.0), false)
				_bar(Rect2(x, py + 20, 200, 12), pk, Color(0.3, 0.7, 1.0))
				# Its G Gauge (3 small segments) and its flask
				if pa.gauge != null:
					var pv := pa.gauge.value / pa.gauge.segment_size
					for i in 3:
						var seg := Rect2(x + float(i) * 67.0, py + 36, 63, 6)
						_mc.draw_rect(seg, Color(0, 0, 0))
						var fill := Color(0.1, 0.65, 1.0) if pv >= float(i + 1) else (Color(0.1, 0.35, 0.65) if pv > float(i) else Color(0.12, 0.18, 0.25))
						_mc.draw_rect(seg.grow(-1.0), fill)
				for i in manager.max_partner_flasks:
					_flask(Vector2(x + 216 + float(i) * 24.0, py + 26), i < manager.partner_flasks)   # (Beside the bar, under the HP text)

	# ---------------- Level title + wave ----------------
	var cx := sz.x * 0.5
	var head_text := "%s  -  LEVEL %d: %s" % [StoryLevels.part_name(StoryLevels.colosseum_of(manager.level_number)), manager.level_number, manager.level.get("title", "")]
	if StoryLevels.is_ext(manager.level_number):
		var ek := StoryLevels.ext_of(manager.level_number)
		head_text = "%s EXTENSION  -  %s: %s" % [StoryLevels.EXTENSIONS[ek]["name"], StoryLevels.ext_code(manager.level_number), manager.level.get("title", "")]
	_label(Vector2(cx, 26), head_text, 18, Color(1.0, 0.75, 0.4))
	if manager.wave_text != "":
		_label(Vector2(cx, 50), manager.wave_text, 15, Color(1, 1, 1, 0.85))

	# ---------------- Boss bar (boss fight only) ----------------
	var boss := manager.boss
	if String(StoryLevels.get_level(manager.level_number).get("boss", "")) == "head_guard" and manager.boss_bar_visible and HeadGuard.spawned > 0:
		# THE HEAD HEAVY GUARDS: six of them, ONE shared bar (they split their health)
		var bwg := clampf(sz.x - 720.0, 300.0, 560.0)
		var rg := Rect2(cx - bwg * 0.5, 86, bwg, 20)
		_label(Vector2(cx, 76), "HEAD HEAVY NIGHTMARE GUARDS  x%d" % (HeadGuard.TOTAL - HeadGuard.spawned + HeadGuard.alive_count()), 20, Color.WHITE)
		_bar(rg, HeadGuard.bar_k(), Color(0.55, 0.95, 0.2))
		boss = null
	elif not manager.boss_group.is_empty() and manager.boss_bar_visible:
		# GROUP BOSS (Void Horrids): one big bar per member, side by side
		var n := manager.boss_group.size()
		var bw2 := minf(300.0, (sz.x - 80.0) / float(n) - 16.0)
		for i in n:
			var m := manager.boss_group[i] as BaseEnemy
			if m == null or not is_instance_valid(m):
				continue
			var x0 := cx - (float(n) * (bw2 + 16.0)) * 0.5 + float(i) * (bw2 + 16.0) + 8.0
			var r2 := Rect2(x0, 86, bw2, 18)
			var alive := not m.is_dead
			_label(Vector2(r2.get_center().x, 76), m.boss_title() if alive else "DEFEATED", 16,
				(Color(1.0, 0.95, 0.4) if m.enraged else Color.WHITE) if alive else Color(1, 1, 1, 0.45))
			_bar(r2, float(m.hp) / maxf(float(m.data.max_hp), 1.0) if alive else 0.0, Color(0.55, 0.95, 0.2) if not m.enraged else Color(1.0, 0.85, 0.15))
		boss = null                                        # (the single bar below is skipped)
	if boss != null and is_instance_valid(boss) and not boss.is_dead and manager.boss_bar_visible:
		var bw := clampf(sz.x - 720.0, 300.0, 560.0)          # Keeps clear of the player panel (left) and the right corner
		var r := Rect2(cx - bw * 0.5, 86, bw, 20)
		_label(Vector2(cx, 76), boss.boss_title(), 20, Color(1.0, 0.95, 0.4) if boss.enraged else Color.WHITE)
		var bk := float(boss.hp) / maxf(float(boss.data.max_hp), 1.0)
		_bar(r, bk, Color(0.55, 0.95, 0.2) if not boss.enraged else Color(1.0, 0.85, 0.15))
		var mark := boss.phase2_threshold                # (STANCE is hidden on purpose: no meter, like Elden Ring)
		if boss is C5Boss:
			mark = (boss as C5Boss).rage_at              # Colosseum 5: where it gets ENRAGED
			var cb := boss as C5Boss
			if cb.forms.size() > 1:                      # Form counter under the bar
				_label(Vector2(cx, r.end.y + 16), "FORM %d / %d" % [cb.form, cb.forms.size()], 13, Color(1, 1, 1, 0.75))
		if mark > 0.0 and mark < 1.0:                    # Where phase 2 starts (50% for most bosses)
			var mx := r.position.x + r.size.x * mark
			_mc.draw_line(Vector2(mx, r.position.y), Vector2(mx, r.end.y), Color(0, 0, 0, 0.8), 2.0)


func _flask(p: Vector2, full: bool) -> void:
	var body := EnemyArt.ellipse_points(p + Vector2(0, 4), 9, 9, 14)
	_mc.draw_colored_polygon(body, Color(0.75, 0.95, 0.95, 0.5))
	if full:
		_mc.draw_colored_polygon(EnemyArt.ellipse_points(p + Vector2(0, 6), 7, 6, 12), Color(0.3, 1.0, 0.45))
		_mc.draw_circle(p + Vector2(-3, 2), 2.0, Color(0.9, 1.0, 0.9))
	FighterArt.outline(_mc, body, 2.0)
	_mc.draw_rect(Rect2(p.x - 3, p.y - 10, 6, 7), Color(0.75, 0.95, 0.95, 0.6))
	_mc.draw_rect(Rect2(p.x - 4, p.y - 13, 8, 4), Color(0.5, 0.32, 0.15))
