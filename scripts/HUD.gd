extends CanvasLayer

## HUD
## Attach to a CanvasLayer in each arena scene.
## Left side = P1 (you), right side = P2 (opponent / Dummy).
## Reads live values straight from the fighters and from the CombatManager
## scene root (fight timer). Works for ANY character.

const BAR_WIDTH: float = 260.0
const BAR_HEIGHT: float = 18.0

const COLOR_HP_HIGH := Color(0.15, 0.85, 0.25)
const COLOR_HP_MID := Color(1.0, 0.7, 0.1)
const COLOR_HP_LOW := Color(0.9, 0.15, 0.15)

const COLOR_SEG_FULL := Color(0.1, 0.65, 1.0)
const COLOR_SEG_PARTIAL := Color(0.1, 0.35, 0.65)
const COLOR_SEG_EMPTY := Color(0.12, 0.18, 0.25)


## Everything shown for one side of the screen.
class HudSide:
	var fighter: Fighter
	var hp_label: Label
	var hp_bar: HudBar
	var onslaught_bar: HudBar
	var gauge_segments: Array[ColorRect] = []
	var cooldown_label: Label
	var status_label: Label
	var lives_label: Label


## Exact-size bar (ProgressBar has a theme minimum height that made bars overlap).
class HudBar extends Control:
	var value := 100.0
	var max_value := 100.0
	var fill_color := Color(0.15, 0.85, 0.25)
	var bg_color := Color(0.12, 0.12, 0.12)

	func set_bar(v: float, m: float, col: Color) -> void:
		value = v
		max_value = maxf(m, 0.001)
		fill_color = col
		queue_redraw()

	func _draw() -> void:
		var r := Rect2(Vector2.ZERO, size)
		draw_rect(r, Color(0, 0, 0))
		draw_rect(r.grow(-2.0), bg_color)
		var k := clampf(value / max_value, 0.0, 1.0)
		if k > 0.0:
			var fr := Rect2(Vector2(2, 2), Vector2((size.x - 4.0) * k, size.y - 4.0))
			draw_rect(fr, fill_color)
			draw_rect(Rect2(fr.position, Vector2(fr.size.x, fr.size.y * 0.35)), fill_color.lightened(0.3))


var p1 := HudSide.new()
var p2 := HudSide.new()
var combat: CombatManager
var timer_label: Label
var refresh_timer: float = 0.0
var _boss_root: Control
var _boss_name: Label
var _boss_bar: HudBar
var ui_root: Control

var _fill_high: StyleBoxFlat
var _fill_mid: StyleBoxFlat
var _fill_low: StyleBoxFlat


func _ready() -> void:
	_fill_high = _make_fill(COLOR_HP_HIGH)
	_fill_mid = _make_fill(COLOR_HP_MID)
	_fill_low = _make_fill(COLOR_HP_LOW)
	_build_hud()
	_refresh()


func _process(delta: float) -> void:
	refresh_timer += delta
	if refresh_timer >= 0.1:
		refresh_timer = 0.0
		_refresh()


func _refresh() -> void:
	_find_nodes()
	for side in [p1, p2]:
		_update_side(side)
	_update_timer()
	_update_boss_bar()


# ============================================================
# BUILD HUD
# ============================================================
func _build_hud() -> void:
	ui_root = Control.new()
	ui_root.set_anchors_and_offsets_preset(Control.PRESET_FULL_RECT)
	ui_root.mouse_filter = Control.MOUSE_FILTER_IGNORE
	add_child(ui_root)

	_build_side(p1, false)
	_build_side(p2, true)

	timer_label = _make_label(Vector2(-100, 18), Vector2(200, 30), "00:00", 21)
	timer_label.set_anchors_preset(Control.PRESET_CENTER_TOP, true)
	timer_label.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER

	# Bottom hint: keyboard / controller (hidden with touch controls so the corners stay clear)
	var hint_text := "Esc = Main Menu   F1 = hitboxes"
	if not Input.get_connected_joypads().is_empty():
		hint_text = "Stick move  A jump  X attack  RB/LT block  Y/B/LB moves  RT ultimate  Start menu"
	var hint := _make_label(Vector2(-330, -30), Vector2(660, 24), hint_text, 13)
	hint.set_anchors_preset(Control.PRESET_CENTER_BOTTOM, true)
	hint.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	hint.modulate = Color(1, 1, 1, 0.6)
	hint.visible = not MatchSettings.touch_enabled()

	# BOSS BAR (only when the opponent is a PvE enemy)
	_boss_root = Control.new()
	_boss_root.mouse_filter = Control.MOUSE_FILTER_IGNORE
	_boss_root.set_anchors_preset(Control.PRESET_CENTER_TOP)
	_boss_root.position = Vector2(-230, 76)
	_boss_root.size = Vector2(460, 50)
	_boss_root.visible = false
	ui_root.add_child(_boss_root)
	_boss_name = Label.new()
	_boss_name.position = Vector2(0, 0)
	_boss_name.size = Vector2(460, 24)
	_boss_name.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	_boss_name.add_theme_font_size_override("font_size", 18)
	_boss_name.add_theme_constant_override("outline_size", 6)
	_boss_name.add_theme_color_override("font_outline_color", Color(0, 0, 0))
	_boss_root.add_child(_boss_name)
	_boss_bar = HudBar.new()
	_boss_bar.position = Vector2(0, 26)
	_boss_bar.size = Vector2(460, 16)
	_boss_bar.custom_minimum_size = Vector2(460, 16)
	_boss_bar.mouse_filter = Control.MOUSE_FILTER_IGNORE
	_boss_root.add_child(_boss_bar)

	# SANDBOX tag (only when Sandbox is ON): you are not in a normal match
	if MatchSettings.sandbox:
		var parts: PackedStringArray = ["SANDBOX"]
		parts.append("DMG " + MatchSettings._mult_text(MatchSettings.damage_multiplier()))
		parts.append("G " + MatchSettings._mult_text(-1.0 if MatchSettings.gauge_instant() else MatchSettings.gauge_multiplier()))
		parts.append("CD " + MatchSettings._mult_text(MatchSettings.cooldown_multiplier()))
		if MatchSettings.god_mode_active():
			parts.append("GOD MODE")
		var sb := _make_label(Vector2(-260, 48), Vector2(520, 24), "  |  ".join(parts), 15)
		sb.set_anchors_preset(Control.PRESET_CENTER_TOP, true)
		sb.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
		sb.add_theme_color_override("font_color", Color(1.0, 0.85, 0.2))


func _build_side(side: HudSide, right: bool) -> void:
	var x := -285.0 if right else 25.0
	var align := HORIZONTAL_ALIGNMENT_RIGHT if right else HORIZONTAL_ALIGNMENT_LEFT
	var nodes: Array[Control] = []

	side.hp_label = _make_label(Vector2(x - 120.0 if right else x, 18), Vector2(BAR_WIDTH + 120.0, 25), "-- HP", 16)
	side.hp_label.horizontal_alignment = align
	nodes.append(side.hp_label)
	side.hp_bar = _make_bar(Vector2(x, 46), Vector2(BAR_WIDTH, BAR_HEIGHT))
	nodes.append(side.hp_bar)
	side.onslaught_bar = _make_bar(Vector2(x, 70), Vector2(BAR_WIDTH, 8))
	side.onslaught_bar.set_bar(0.0, 1.0, Color(0.3, 0.3, 0.3))
	nodes.append(side.onslaught_bar)

	# G Gauge: 3 segments under the bars
	var g_label := _make_label(Vector2(x, 84), Vector2(70, 22), "G GAUGE", 12)
	nodes.append(g_label)
	for i in range(3):
		var seg := ColorRect.new()
		seg.position = Vector2(x + 70.0 + i * 34.0, 88)
		seg.size = Vector2(30, 14)
		seg.color = COLOR_SEG_EMPTY
		ui_root.add_child(seg)
		side.gauge_segments.append(seg)
		nodes.append(seg)

	side.lives_label = _make_label(Vector2(x + 176.0, 84), Vector2(90, 22), "", 13)
	side.lives_label.add_theme_color_override("font_color", Color(1.0, 0.85, 0.3))
	nodes.append(side.lives_label)

	side.cooldown_label = _make_label(Vector2(x, 110), Vector2(BAR_WIDTH, 70), "", 14)
	side.cooldown_label.horizontal_alignment = align
	nodes.append(side.cooldown_label)
	side.status_label = _make_label(Vector2(x, 178), Vector2(BAR_WIDTH, 44), "", 14)
	side.status_label.horizontal_alignment = align
	side.status_label.modulate = Color(1.0, 0.5, 0.15)
	nodes.append(side.status_label)

	if right:
		for n in nodes:
			n.set_anchors_preset(Control.PRESET_TOP_RIGHT, true)


# ============================================================
# UI HELPERS
# ============================================================
func _make_label(pos: Vector2, dimensions: Vector2, initial_text: String, font_size: int) -> Label:
	var label := Label.new()
	label.position = pos
	label.size = dimensions
	label.text = initial_text
	label.add_theme_font_size_override("font_size", font_size)
	label.add_theme_constant_override("outline_size", 6)
	label.add_theme_color_override("font_outline_color", Color(0, 0, 0))
	ui_root.add_child(label)
	return label


func _make_bar(pos: Vector2, dimensions: Vector2) -> HudBar:
	var bar := HudBar.new()
	bar.position = pos
	bar.size = dimensions
	bar.custom_minimum_size = dimensions
	bar.mouse_filter = Control.MOUSE_FILTER_IGNORE
	bar.set_bar(100.0, 100.0, COLOR_HP_HIGH)
	ui_root.add_child(bar)
	return bar


func _make_fill(color: Color) -> StyleBoxFlat:
	var fill := StyleBoxFlat.new()
	fill.bg_color = color
	fill.set_corner_radius_all(3)
	return fill


# ============================================================
# NODE DETECTION
# ============================================================
func _find_nodes() -> void:
	if not is_instance_valid(p1.fighter) or not is_instance_valid(p2.fighter):
		for n in get_tree().get_nodes_in_group("fighters"):
			var f := n as Fighter
			if f == null:
				continue
			if f.slot == 2 or (f.slot == 0 and f is Dummy):
				p2.fighter = f
			else:
				p1.fighter = f
	if not is_instance_valid(combat):
		combat = get_tree().current_scene as CombatManager


# ============================================================
# ONE SIDE
# ============================================================
func _update_side(side: HudSide) -> void:
	var f := side.fighter
	if not is_instance_valid(f) or f.data == null:
		side.hp_label.text = "NOT FOUND"
		side.hp_bar.set_bar(0.0, 1.0, COLOR_HP_LOW)
		return

	# HP
	var who := "P1" if side == p1 else ("CPU" if f is ControlledFighter else "")
	var hp := float(f.hp)
	var max_hp := maxf(float(f.data.max_hp), 1.0)
	side.hp_label.text = ("%s  %s   %d / %d" % [who, f.data.character_name.to_upper(), int(hp), int(max_hp)]).strip_edges()
	var mm := get_tree().get_first_node_in_group("match_manager") as MatchManager
	side.lives_label.text = "LIVES %d/%d" % [mm.lives_of(f), mm.max_lives_of(f)] if mm != null else ""
	var pct := hp / max_hp
	side.hp_bar.set_bar(clampf(hp, 0.0, max_hp), max_hp, COLOR_HP_HIGH if pct > 0.5 else (COLOR_HP_MID if pct > 0.25 else COLOR_HP_LOW))

	var cf := f as ControlledFighter

	# Onslaught flash bar
	if cf != null and cf.onslaught != null:
		var o := cf.onslaught
		side.onslaught_bar.set_bar(maxf(o.flash_timer, 0.0), maxf(o.flash_duration, 0.01),
			Color(1.0, 0.45, 0.05) if o.flash_timer > 0.0 else Color(0.3, 0.3, 0.3))
	else:
		side.onslaught_bar.set_bar(0.0, 1.0, Color(0.3, 0.3, 0.3))

	# G Gauge
	var value := 0.0
	if f.gauge != null and f.gauge.segment_size > 0.0:
		value = f.gauge.value / f.gauge.segment_size
	for i in range(side.gauge_segments.size()):
		var seg := side.gauge_segments[i]
		seg.visible = f.gauge != null
		if value >= float(i + 1):
			seg.color = COLOR_SEG_FULL
		elif value > float(i):
			seg.color = COLOR_SEG_PARTIAL
		else:
			seg.color = COLOR_SEG_EMPTY

	# Cooldowns
	if cf != null:
		var lines: PackedStringArray = []
		for i in cf.move_ids.size():
			var id := cf.move_ids[i]
			var t: float = cf.cooldowns.get(id, 0.0)
			lines.append("[%d] %s: %s" % [i + 1, String(cf.move_names.get(id, id)).to_upper(), "READY" if t <= 0.0 else "%.1fs" % t])
		side.cooldown_label.text = "\n".join(lines)
	else:
		side.cooldown_label.text = ""

	# Status (Afterburn, Royal Destiny, Time Stop)
	var st: PackedStringArray = []
	if cf != null and cf.onslaught != null and cf.onslaught.afterburn_timer > 0.0:
		st.append("AFTERBURN: %.1fs" % cf.onslaught.afterburn_timer)
	if f is Warrior and (f as Warrior).royal_timer > 0.0:
		st.append("ROYAL DESTINY: %.1fs" % (f as Warrior).royal_timer)
	if f is FireLord:
		var fl := f as FireLord
		if fl.bonus() > 0:
			st.append("PASSIVE: +%d DAMAGE" % fl.bonus())
		if fl.is_bat():
			st.append("BAT FORM: %.1fs" % fl.bat_timer)
	if f is EnlightenedOne and (f as EnlightenedOne).is_gorilla():
		st.append("GORILLA FORM: %.1fs" % (f as EnlightenedOne).gorilla_timer)
	if CombatManager.is_time_stopped() and CombatManager.time_stop_owner == f:
		st.append("TIME STOP: %.1fs" % CombatManager.time_stop_left)
	side.status_label.text = "\n".join(st)


# ============================================================
# FIGHT TIMER
# ============================================================
func _update_timer() -> void:
	var seconds: float = combat.fight_time if is_instance_valid(combat) else 0.0
	var total := int(seconds)
	timer_label.text = "%02d:%02d" % [total / 60, total % 60]


# ============================================================
# BOSS BAR (top of the screen, PvE enemies only)
# ============================================================
func _update_boss_bar() -> void:
	var boss := p2.fighter as BaseEnemy if is_instance_valid(p2.fighter) else null
	_boss_root.visible = boss != null
	if boss == null:
		return
	var label := "%s   %d / %d" % [boss.enemy_name.to_upper(), boss.hp, boss.data.max_hp]
	if boss.enraged:
		label += "   -   PHASE 2: ENRAGED"
	_boss_name.text = label
	_boss_name.add_theme_color_override("font_color", Color(1.0, 0.45, 0.4) if boss.enraged else Color.WHITE)
	var k := float(boss.hp) / maxf(float(boss.data.max_hp), 1.0)
	_boss_bar.set_bar(float(boss.hp), float(boss.data.max_hp), Color(0.9, 0.15, 0.15).lerp(Color(0.2, 0.85, 0.3), k))
