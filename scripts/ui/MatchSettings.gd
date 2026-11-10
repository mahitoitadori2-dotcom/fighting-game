class_name MatchSettings
extends Control
## MATCH SETTINGS screen + the settings themselves (static, survive scene changes).
##
## Gameplay code only uses the static helpers at the top:
##   MatchSettings.lives                  -> lives per player (1-5)
##   MatchSettings.damage_multiplier()    -> 1.0 unless Sandbox is ON
##   MatchSettings.gauge_multiplier()     -> 1.0 unless Sandbox is ON
##   MatchSettings.gauge_instant()        -> G Gauge always full
##   MatchSettings.cooldown_multiplier()  -> 1.0 unless Sandbox is ON
##   MatchSettings.god_mode_active()      -> nobody can die
##
## To add Timer / Rounds later: add a static var + a _stepper() row in _build_match_section().

# ============================================================
# SETTINGS (static)
# ============================================================
const LIVES_MIN := 1
const LIVES_MAX := 5
const DAMAGE_OPTIONS := [0.0, 0.5, 1.0, 2.0, 5.0, 10.0, 100.0]
const GAUGE_OPTIONS := [0.0, 0.5, 1.0, 2.0, 5.0, 10.0, -1.0]     # -1 = INSTANT
const COOLDOWN_OPTIONS := [0.0, 0.5, 1.0, 2.0]
const DEFAULT_INDEX := 2                                        # 1x in every list

static var lives := 1
## Touch controls: 0 = AUTO (only on touchscreens), 1 = ON (also for testing on PC), 2 = OFF
static var touch_mode := 0
const TOUCH_NAMES := ["AUTO", "ON", "OFF"]
## MOBILE UI SCALER: size of the touch buttons + joystick (1.0 = default). Saved on the device.
static var touch_ui_scale := 1.0
const TOUCH_SCALE_MIN := 0.6
const TOUCH_SCALE_MAX := 1.6
const CONTROLS_PATH := "user://controls.cfg"
static var _controls_loaded := false


static func load_controls() -> void:
	if _controls_loaded:
		return
	_controls_loaded = true
	var cfg := ConfigFile.new()
	if cfg.load(CONTROLS_PATH) != OK:
		return
	touch_mode = clampi(int(cfg.get_value("touch", "mode", touch_mode)), 0, 2)
	touch_ui_scale = clampf(float(cfg.get_value("touch", "ui_scale", 1.0)), TOUCH_SCALE_MIN, TOUCH_SCALE_MAX)


static func save_controls() -> void:
	var cfg := ConfigFile.new()
	cfg.set_value("touch", "mode", touch_mode)
	cfg.set_value("touch", "ui_scale", touch_ui_scale)
	cfg.save(CONTROLS_PATH)
static var enemy_lives := 1           # PvE enemies / bosses (Rotor...): 1 = one HP bar

static var sandbox := false
static var damage_idx := DEFAULT_INDEX
static var gauge_idx := DEFAULT_INDEX
static var cooldown_idx := DEFAULT_INDEX
static var god_mode := false
static var show_fps := false          # Sandbox: FPS / performance counter in the fight
## Where BACK goes (Main Menu > SETTINGS sets it to the Main Menu; reset after use).
static var return_scene := CharacterRoster.PRE_FIGHT
## Which screen this scene shows: "match" = MATCH SETTINGS (Lives, Enemy Lives, Sandbox), from the
## pre-fight screen; "general" = SETTINGS (Touch controls, Touch UI Size, Audio), from the Main Menu.
static var screen_mode := "match"


static func fps_counter_active() -> bool:
	return sandbox and show_fps


static func touch_enabled() -> bool:
	load_controls()
	if touch_mode == 1:
		return true
	if touch_mode == 2:
		return false
	if OS.has_feature("web"):
		return _web_is_touch_device()
	return DisplayServer.is_touchscreen_available()


## WEB: phones / tablets get touch controls, PCs and Macs don't - even touchscreen
## laptops (there "AUTO" would otherwise hide the controls' mouse fallback and unbind
## left-click punch). iPad Safari pretends to be a Mac, so ask the browser for a
## coarse (finger) primary pointer instead of trusting the platform name.
static var _web_touch_cache := -1


static func _web_is_touch_device() -> bool:
	if _web_touch_cache == -1:
		var touch := OS.has_feature("web_ios") or OS.has_feature("web_android")
		if not touch:
			touch = JavaScriptBridge.eval("window.matchMedia('(pointer: coarse)').matches", true) == true
		_web_touch_cache = 1 if touch else 0
	return _web_touch_cache == 1


static func damage_multiplier() -> float:
	return DAMAGE_OPTIONS[damage_idx] if sandbox else 1.0


static func gauge_instant() -> bool:
	return sandbox and GAUGE_OPTIONS[gauge_idx] < 0.0


static func gauge_multiplier() -> float:
	if not sandbox:
		return 1.0
	var g: float = GAUGE_OPTIONS[gauge_idx]
	return 1.0 if g < 0.0 else g


static func cooldown_multiplier() -> float:
	return COOLDOWN_OPTIONS[cooldown_idx] if sandbox else 1.0


static func god_mode_active() -> bool:
	return sandbox and god_mode


static func reset_sandbox() -> void:
	damage_idx = DEFAULT_INDEX
	gauge_idx = DEFAULT_INDEX
	cooldown_idx = DEFAULT_INDEX
	god_mode = false


static func _mult_text(v: float) -> String:
	if v < 0.0:
		return "INSTANT"
	if v == 0.0:
		return "0x"
	return ("%dx" % int(v)) if is_equal_approx(v, roundf(v)) else ("%.1fx" % v)


# ============================================================
# SCREEN
# ============================================================
var _summary: Label
var _values := {}                 # row id -> value Label
var _sandbox_toggle: CheckButton
var _sandbox_box: VBoxContainer
var _god_toggle: CheckButton
var _fps_toggle: CheckButton
var _back: Button


func _ready() -> void:
	SoundManager.play_music("menu")
	load_controls()
	_build()
	_refresh()
	_back.grab_focus.call_deferred()


func _build() -> void:
	var margin := MarginContainer.new()
	margin.set_anchors_and_offsets_preset(Control.PRESET_FULL_RECT)
	for side in ["margin_left", "margin_right", "margin_top", "margin_bottom"]:
		margin.add_theme_constant_override(side, 22)
	add_child(margin)

	var col := VBoxContainer.new()
	col.add_theme_constant_override("separation", 10)
	margin.add_child(col)

	# Header
	var header := HBoxContainer.new()
	col.add_child(header)
	_back = UiStyle.make_button("< BACK", Vector2(150, 50), 22)
	_back.pressed.connect(_go_back)
	header.add_child(_back)
	var general := screen_mode == "general"
	var title := UiStyle.label("SETTINGS" if general else "MATCH SETTINGS", 42)
	title.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	header.add_child(title)
	var spacer := Control.new()
	spacer.custom_minimum_size = Vector2(150, 0)
	header.add_child(spacer)

	# Current selection
	_summary = UiStyle.label("", 18, UiStyle.TEXT, 6)
	_summary.autowrap_mode = TextServer.AUTOWRAP_WORD_SMART
	col.add_child(_summary)

	# Scrollable settings panel
	var scroll := ScrollContainer.new()
	scroll.size_flags_vertical = Control.SIZE_EXPAND_FILL
	scroll.horizontal_scroll_mode = ScrollContainer.SCROLL_MODE_DISABLED
	col.add_child(scroll)
	var center := CenterContainer.new()
	center.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	scroll.add_child(center)
	var panel := PanelContainer.new()
	panel.add_theme_stylebox_override("panel", UiStyle.box(UiStyle.PANEL, UiStyle.INK, 5, 18, 22.0))
	panel.custom_minimum_size = Vector2(620, 0)
	center.add_child(panel)
	var rows := VBoxContainer.new()
	rows.add_theme_constant_override("separation", 12)
	panel.add_child(rows)

	if general:
		# SETTINGS (Main Menu): how the game feels / sounds on this device
		_build_graphics_section(rows)
		rows.add_child(HSeparator.new())
		_build_controls_section(rows)
		rows.add_child(HSeparator.new())
		_build_audio_section(rows)
	else:
		# MATCH SETTINGS (pre-fight screen): rules of the next fight
		_build_match_section(rows)
		rows.add_child(HSeparator.new())
		_build_sandbox_section(rows)


func _build_match_section(rows: VBoxContainer) -> void:
	rows.add_child(_section_title("MATCH"))
	rows.add_child(_stepper("lives", "Lives (per player)", _change_lives))
	rows.add_child(_stepper("enemy_lives", "Enemy Lives (PvE bosses)", _change_enemy_lives))
	var later := UiStyle.label("Timer / Rounds: coming soon", 14, UiStyle.TEXT_DIM, 4)
	later.horizontal_alignment = HORIZONTAL_ALIGNMENT_LEFT
	rows.add_child(later)


## GRAPHICS: Potato / Fast / Regular / Real (GraphicsSettings, saved to user://graphics.cfg).
var _graphics_desc: Label


func _build_graphics_section(rows: VBoxContainer) -> void:
	rows.add_child(_section_title("GRAPHICS"))
	rows.add_child(_stepper("graphics", "Graphics Quality", _change_graphics))
	_graphics_desc = UiStyle.label("", 14, UiStyle.TEXT_DIM, 4)
	_graphics_desc.autowrap_mode = TextServer.AUTOWRAP_WORD_SMART
	_graphics_desc.horizontal_alignment = HORIZONTAL_ALIGNMENT_LEFT
	rows.add_child(_graphics_desc)


func _change_graphics(step: int) -> void:
	GraphicsSettings.set_level(clampi(GraphicsSettings.level + step, GraphicsSettings.POTATO, GraphicsSettings.REAL), get_tree())
	_refresh()


func _build_controls_section(rows: VBoxContainer) -> void:
	rows.add_child(_section_title("CONTROLS"))
	rows.add_child(_stepper("touch", "Touch Controls (mobile)", _change_touch))
	rows.add_child(_touch_scale_row())
	var pad := UiStyle.label("Controller: Stick move  A jump  X attack  RB/LT block  Y / B / LB = moves 1 / 2 / 3  RT ultimate  Start menu", 14, UiStyle.TEXT_DIM, 4)
	pad.autowrap_mode = TextServer.AUTOWRAP_WORD_SMART
	pad.horizontal_alignment = HORIZONTAL_ALIGNMENT_LEFT
	rows.add_child(pad)


## AUDIO: Music / SFX volume sliders + Mute (saved by SoundManager to user://audio.cfg).
func _build_audio_section(rows: VBoxContainer) -> void:
	rows.add_child(_section_title("AUDIO"))
	rows.add_child(_volume_row("Music Volume", "music"))
	rows.add_child(_volume_row("SFX Volume", "sfx"))
	var mute_row := HBoxContainer.new()
	var ml := UiStyle.label("Mute All", 20, UiStyle.TEXT, 6)
	ml.horizontal_alignment = HORIZONTAL_ALIGNMENT_LEFT
	ml.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	mute_row.add_child(ml)
	var mute := _make_toggle()
	mute.set_pressed_no_signal(SoundManager.muted)
	mute.text = "ON" if SoundManager.muted else "OFF"
	mute.toggled.connect(func(on: bool) -> void:
		SoundManager.set_muted(on)
		mute.text = "ON" if on else "OFF")
	mute_row.add_child(mute)
	rows.add_child(mute_row)


func _volume_row(text: String, which: String) -> Control:
	var row := HBoxContainer.new()
	row.add_theme_constant_override("separation", 12)
	var name_label := UiStyle.label(text, 20, UiStyle.TEXT, 6)
	name_label.horizontal_alignment = HORIZONTAL_ALIGNMENT_LEFT
	name_label.custom_minimum_size = Vector2(200, 0)
	row.add_child(name_label)
	var slider := HSlider.new()
	slider.min_value = 0
	slider.max_value = 100
	slider.step = 5
	slider.value = roundf(SoundManager.get_volume(which) * 100.0)
	slider.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	slider.size_flags_vertical = Control.SIZE_SHRINK_CENTER
	slider.custom_minimum_size = Vector2(220, 36)            # Big enough for a thumb on phones
	slider.focus_mode = Control.FOCUS_ALL
	row.add_child(slider)
	var value := UiStyle.label("%d%%" % int(slider.value), 20, UiStyle.ACCENT_BLUE, 6)
	value.custom_minimum_size = Vector2(70, 0)
	row.add_child(value)
	slider.value_changed.connect(func(v: float) -> void:
		SoundManager.set_volume(which, v / 100.0)
		value.text = "%d%%" % int(v)
		if which == "sfx":
			SoundManager.play_sfx("hit"))                   # Preview so you hear the new level
	return row


func _change_touch(step: int) -> void:
	touch_mode = wrapi(touch_mode + step, 0, 3)
	save_controls()
	_refresh()


## MOBILE UI SCALER: slider for the size of the touch buttons and joystick (60% - 160%).
func _touch_scale_row() -> Control:
	var row := HBoxContainer.new()
	row.add_theme_constant_override("separation", 12)
	var name_label := UiStyle.label("Touch UI Size", 20, UiStyle.TEXT, 6)
	name_label.horizontal_alignment = HORIZONTAL_ALIGNMENT_LEFT
	name_label.custom_minimum_size = Vector2(200, 0)
	row.add_child(name_label)
	var slider := HSlider.new()
	slider.min_value = TOUCH_SCALE_MIN * 100.0
	slider.max_value = TOUCH_SCALE_MAX * 100.0
	slider.step = 10
	slider.value = roundf(touch_ui_scale * 100.0)
	slider.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	slider.size_flags_vertical = Control.SIZE_SHRINK_CENTER
	slider.custom_minimum_size = Vector2(220, 36)
	slider.focus_mode = Control.FOCUS_ALL
	row.add_child(slider)
	var value := UiStyle.label("%d%%" % int(slider.value), 20, UiStyle.ACCENT_BLUE, 6)
	value.custom_minimum_size = Vector2(70, 0)
	row.add_child(value)
	slider.value_changed.connect(func(v: float) -> void:
		touch_ui_scale = v / 100.0
		value.text = "%d%%" % int(v))
	slider.drag_ended.connect(func(_changed: bool) -> void: save_controls())
	slider.focus_exited.connect(func() -> void: save_controls())
	return row


func _build_sandbox_section(rows: VBoxContainer) -> void:
	var head := HBoxContainer.new()
	var t := _section_title("SANDBOX MODE")
	t.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	head.add_child(t)
	_sandbox_toggle = _make_toggle()
	_sandbox_toggle.toggled.connect(_on_sandbox_toggled)
	head.add_child(_sandbox_toggle)
	rows.add_child(head)

	_sandbox_box = VBoxContainer.new()
	_sandbox_box.add_theme_constant_override("separation", 12)
	rows.add_child(_sandbox_box)
	_sandbox_box.add_child(_stepper("damage", "Damage Multiplier", _change_damage))
	_sandbox_box.add_child(_stepper("gauge", "G Gauge Multiplier", _change_gauge))
	_sandbox_box.add_child(_stepper("cooldown", "Cooldown Multiplier", _change_cooldown))

	var god_row := HBoxContainer.new()
	var gl := UiStyle.label("Infinite HP / God Mode", 20, UiStyle.TEXT, 6)
	gl.horizontal_alignment = HORIZONTAL_ALIGNMENT_LEFT
	gl.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	god_row.add_child(gl)
	_god_toggle = _make_toggle()
	_god_toggle.toggled.connect(_on_god_toggled)
	god_row.add_child(_god_toggle)
	_sandbox_box.add_child(god_row)

	var fps_row := HBoxContainer.new()
	var fl := UiStyle.label("FPS Counter (F4 in fight = +50 test projectiles)", 20, UiStyle.TEXT, 6)
	fl.horizontal_alignment = HORIZONTAL_ALIGNMENT_LEFT
	fl.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	fl.autowrap_mode = TextServer.AUTOWRAP_WORD_SMART
	fps_row.add_child(fl)
	_fps_toggle = _make_toggle()
	_fps_toggle.toggled.connect(_on_fps_toggled)
	fps_row.add_child(_fps_toggle)
	_sandbox_box.add_child(fps_row)

	var reset := UiStyle.make_button("RESET SANDBOX", Vector2(260, 46), 18)
	reset.size_flags_horizontal = Control.SIZE_SHRINK_CENTER
	reset.pressed.connect(_on_reset)
	_sandbox_box.add_child(reset)
	var note := UiStyle.label("Applies to BOTH players and the CPU.", 14, UiStyle.TEXT_DIM, 4)
	_sandbox_box.add_child(note)


# ----- Widgets -----
func _section_title(text: String) -> Label:
	var l := UiStyle.label(text, 24, UiStyle.ACCENT_GREEN, 8)
	l.horizontal_alignment = HORIZONTAL_ALIGNMENT_LEFT
	return l


func _stepper(id: String, text: String, on_change: Callable) -> Control:
	var row := HBoxContainer.new()
	row.add_theme_constant_override("separation", 10)
	var name_label := UiStyle.label(text, 20, UiStyle.TEXT, 6)
	name_label.horizontal_alignment = HORIZONTAL_ALIGNMENT_LEFT
	name_label.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	row.add_child(name_label)
	var minus := UiStyle.make_button("-", Vector2(48, 44), 24)
	minus.pressed.connect(on_change.bind(-1))
	row.add_child(minus)
	var value := UiStyle.label("", 22, UiStyle.ACCENT_BLUE, 6)
	value.custom_minimum_size = Vector2(120, 0)
	row.add_child(value)
	var plus := UiStyle.make_button("+", Vector2(48, 44), 24)
	plus.pressed.connect(on_change.bind(1))
	row.add_child(plus)
	_values[id] = value
	return row


func _make_toggle() -> CheckButton:
	var cb := CheckButton.new()
	cb.text = "OFF"
	cb.add_theme_font_size_override("font_size", 20)
	cb.focus_mode = Control.FOCUS_ALL
	cb.mouse_default_cursor_shape = Control.CURSOR_POINTING_HAND
	return cb


# ----- Changes -----
func _change_lives(step: int) -> void:
	lives = clampi(lives + step, LIVES_MIN, LIVES_MAX)
	_refresh()


func _change_enemy_lives(step: int) -> void:
	enemy_lives = clampi(enemy_lives + step, LIVES_MIN, LIVES_MAX)
	_refresh()


func _change_damage(step: int) -> void:
	damage_idx = clampi(damage_idx + step, 0, DAMAGE_OPTIONS.size() - 1)
	_refresh()


func _change_gauge(step: int) -> void:
	gauge_idx = clampi(gauge_idx + step, 0, GAUGE_OPTIONS.size() - 1)
	_refresh()


func _change_cooldown(step: int) -> void:
	cooldown_idx = clampi(cooldown_idx + step, 0, COOLDOWN_OPTIONS.size() - 1)
	_refresh()


func _on_sandbox_toggled(on: bool) -> void:
	sandbox = on
	_refresh()


func _on_god_toggled(on: bool) -> void:
	god_mode = on
	_refresh()


func _on_fps_toggled(on: bool) -> void:
	show_fps = on
	_refresh()


func _on_reset() -> void:
	reset_sandbox()
	_refresh()


func _refresh() -> void:
	if screen_mode == "general":
		_values["touch"].text = TOUCH_NAMES[touch_mode]
		_values["graphics"].text = GraphicsSettings.NAMES[GraphicsSettings.level]
		_graphics_desc.text = GraphicsSettings.DESCS[GraphicsSettings.level]
		_summary.text = "Graphics, controls and sound for this device.  (Lives, Enemy Lives and Sandbox are in MATCH SETTINGS before a fight.)"
		return
	_values["lives"].text = str(lives)
	_values["enemy_lives"].text = str(enemy_lives)
	_values["damage"].text = _mult_text(DAMAGE_OPTIONS[damage_idx])
	_values["gauge"].text = _mult_text(GAUGE_OPTIONS[gauge_idx])
	var cd: float = COOLDOWN_OPTIONS[cooldown_idx]
	_values["cooldown"].text = "0x (NONE)" if cd == 0.0 else _mult_text(cd)

	_sandbox_toggle.set_pressed_no_signal(sandbox)
	_sandbox_toggle.text = "ON" if sandbox else "OFF"
	_god_toggle.set_pressed_no_signal(god_mode)
	_god_toggle.text = "ON" if god_mode else "OFF"
	_fps_toggle.set_pressed_no_signal(show_fps)
	_fps_toggle.text = "ON" if show_fps else "OFF"
	_sandbox_box.visible = sandbox          # OFF = sandbox options hidden

	_summary.text = "YOU: %s    VS    OPPONENT: %s    |    ARENA: %s    |    LIVES: %d%s" % [
		CharacterRoster.selected()["short"], CharacterRoster.opponent()["short"],
		ArenaManager.selected_arena_entry()["name"], lives, "    |    SANDBOX ON" if sandbox else ""]


func _unhandled_input(event: InputEvent) -> void:
	if event.is_action_pressed("ui_cancel"):
		_go_back()


func _go_back() -> void:
	save_controls()
	var target := return_scene
	return_scene = CharacterRoster.PRE_FIGHT
	screen_mode = "match"
	get_tree().change_scene_to_file(target)
