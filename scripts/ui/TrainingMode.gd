class_name TrainingMode
extends CanvasLayer
## TRAINING MODE: active in every Dummy fight (no opponent picked).
## A stats panel: last hit (move, damage, type, TRUE combo or not), combo counter + combo damage,
## best combo, damage per second, measured STARTUP (your button press -> the hit landing).
## Keys (shown on screen):
##   F1  hitboxes / hurtboxes (the existing debug view)
##   F2  Dummy behaviour: STAND / BLOCK / RANDOM BLOCK / JUMP / FIGHT BACK
##   F3  infinite resources (no cooldowns, full G Gauge)
##   F4  reset positions + HP
##   F5  Dummy auto-heal on / off
##   F6  hide / show this panel

const COMBO_GAP := 1.1
const ACTIONS := ["punch", "move_rocket", "move_hnct", "move_drill", "ultimate", "move_4", "move_5", "move_6", "move_7"]

static var infinite := false
static var auto_heal := true

var p1: Fighter
var dummy: Dummy
var _panel: PanelContainer
var _lbl: Label
var _keys: Label
var _combo := 0
var _combo_dmg := 0
var _best_combo := 0
var _best_combo_dmg := 0
var _last_hit_t := -10.0
var _last := "-"
var _true_combo := false
var _startup := -1.0
var _press_t := -1.0
var _press_name := ""
var _hits: Array = []            # [time, damage] for DPS
var _total := 0


func _ready() -> void:
	layer = 6
	_panel = PanelContainer.new()
	_panel.add_theme_stylebox_override("panel", UiStyle.box(Color(0.05, 0.06, 0.1, 0.82), UiStyle.INK, 3, 10, 12.0))
	_panel.anchor_left = 1.0
	_panel.anchor_right = 1.0
	_panel.anchor_top = 0.0
	_panel.offset_left = -330
	_panel.offset_right = -14
	_panel.offset_top = 140
	_panel.mouse_filter = Control.MOUSE_FILTER_IGNORE
	add_child(_panel)
	var v := VBoxContainer.new()
	_panel.add_child(v)
	var title := UiStyle.label("TRAINING", 22, UiStyle.ACCENT_GREEN, 6)
	title.horizontal_alignment = HORIZONTAL_ALIGNMENT_LEFT
	v.add_child(title)
	_lbl = UiStyle.label("", 16, UiStyle.TEXT, 5)
	_lbl.horizontal_alignment = HORIZONTAL_ALIGNMENT_LEFT
	v.add_child(_lbl)
	_keys = UiStyle.label("", 13, UiStyle.TEXT_DIM, 4)
	_keys.visible = false                                  # (No key list on screen; the F-keys still work)
	_keys.horizontal_alignment = HORIZONTAL_ALIGNMENT_LEFT
	v.add_child(_keys)


func bind(player: Fighter, d: Dummy) -> void:
	p1 = player
	dummy = d
	dummy.damaged.connect(_on_dummy_damaged)


func now() -> float:
	return Time.get_ticks_msec() / 1000.0


func _on_dummy_damaged(amount: int, hit: HitData) -> void:
	var t := now()
	if t - _last_hit_t > COMBO_GAP:
		_combo = 0
		_combo_dmg = 0
	_combo += 1
	_combo_dmg += amount
	_true_combo = _combo > 1 and dummy.stun_timer > 0.0
	_last_hit_t = t
	_total += amount
	_hits.append([t, amount])
	if _combo > _best_combo or (_combo == _best_combo and _combo_dmg > _best_combo_dmg):
		_best_combo = _combo
		_best_combo_dmg = _combo_dmg
	var mv := hit.move if hit != null and hit.move != "" else "?"
	var kind := hit.hit_type if hit != null else "?"
	_last = "%s  %d dmg  (%s%s)" % [mv.replace("_", " ").to_upper(), amount, kind, ", ONSLAUGHT" if hit != null and hit.onslaught else ""]
	if _press_t > 0.0:
		_startup = t - _press_t
		_press_t = -1.0


func _process(_d: float) -> void:
	if p1 == null or not is_instance_valid(p1) or dummy == null or not is_instance_valid(dummy):
		return
	for a in ACTIONS:
		if InputMap.has_action(a) and Input.is_action_just_pressed(a):
			_press_t = now()
			_press_name = a
	if _press_t > 0.0 and now() - _press_t > 2.5:
		_press_t = -1.0                                 # That press never hit
	if infinite and p1 is ControlledFighter:
		(p1 as ControlledFighter).cooldowns.clear()
		if p1.gauge != null:
			p1.gauge.add_raw(p1.gauge.max_value())
	if auto_heal and now() - _last_hit_t > 2.2 and dummy.hp < dummy.data.max_hp and not dummy.is_dead:
		dummy.hp = dummy.data.max_hp
		dummy.health_changed.emit(dummy.hp, dummy.data.max_hp)
	var t := now()
	while not _hits.is_empty() and t - float(_hits[0][0]) > 5.0:
		_hits.pop_front()
	var recent := 0
	for h in _hits:
		recent += int(h[1])
	var combo_live := t - _last_hit_t <= COMBO_GAP and _combo > 1
	_lbl.text = "LAST HIT  %s\nCOMBO  %s\nBEST  %d hits / %d dmg\nDPS (5 s)  %.1f      TOTAL  %d\nSTARTUP  %s\nDUMMY  %s" % [
		_last,
		("%d hits / %d dmg%s" % [_combo, _combo_dmg, "  TRUE" if _true_combo else ""]) if combo_live else "-",
		_best_combo, _best_combo_dmg, float(recent) / 5.0, _total,
		("%.2f s  (%s)" % [_startup, _press_name.replace("move_", "").to_upper()]) if _startup >= 0.0 else "-",
		Dummy.BEHAVIOURS[Dummy.behaviour].to_upper(),
	]
	_keys.text = "F1 hitboxes %s   F2 dummy behaviour\nF3 infinite %s   F4 reset   F5 auto-heal %s   F6 hide" % [
		"ON" if CombatManager.debug_boxes else "OFF", "ON" if infinite else "OFF", "ON" if auto_heal else "OFF"]


func _unhandled_input(event: InputEvent) -> void:
	var k := event as InputEventKey
	if k == null or not k.pressed or k.echo:
		return
	match k.physical_keycode:
		KEY_F2:
			Dummy.behaviour = (Dummy.behaviour + 1) % Dummy.BEHAVIOURS.size()
			_toast("DUMMY: %s" % Dummy.BEHAVIOURS[Dummy.behaviour].to_upper())
		KEY_F3:
			infinite = not infinite
			_toast("INFINITE RESOURCES %s" % ("ON" if infinite else "OFF"))
		KEY_F4:
			_reset()
		KEY_F5:
			auto_heal = not auto_heal
			_toast("AUTO-HEAL %s" % ("ON" if auto_heal else "OFF"))
		KEY_F6:
			_panel.visible = not _panel.visible
		_:
			return
	get_viewport().set_input_as_handled()


func _reset() -> void:
	var am := get_tree().get_first_node_in_group("arena_manager") as ArenaManager
	for f: Fighter in [p1, dummy]:
		if f == null or not is_instance_valid(f):
			continue
		if f.is_dead:
			f.respawn()
		f.global_position = am.p1_spawn if f == p1 and am else (am.p2_spawn if am else f.global_position)
		f.velocity = Vector2.ZERO
		f.hp = f.data.max_hp
		f.health_changed.emit(f.hp, f.data.max_hp)
		f.facing = f.default_facing
	_combo = 0
	_combo_dmg = 0
	_toast("RESET")


func _toast(text: String) -> void:
	if p1 and is_instance_valid(p1):
		Effects.popup(p1, p1.global_position + Vector2(0, -190), text, UiStyle.ACCENT_GREEN, 20)
	SoundManager.play_sfx("count_tick")
