class_name UiStyle
extends RefCounted
## Shared look for menus: chunky cartoon buttons with thick black borders and
## outlined text, matching the in-game art style.
##
## THREE OUTLINE FAMILIES, so you can tell them apart at a glance (2026-11-24):
##   BUTTONS        button_box(): capsule shape, a light rim, a deep 3D lip at the bottom
##                  (it sinks when pressed); the focus ring sits OUTSIDE the outline.
##   NOTIFICATIONS  notice_box(): square corners, a thin coloured outline with a thick bar on the
##                  left and a coloured glow (achievements, daily rewards, unlock messages).
##   DIALOGUE       DialogueBox._frame(): carved stone + a double gold rim; its choices have cut corners.

const INK := Color(0.04, 0.04, 0.06)
const PANEL := Color(0.12, 0.14, 0.20, 0.94)
const PANEL_LIGHT := Color(0.18, 0.21, 0.29, 0.96)
const ACCENT_GREEN := Color(0.30, 0.90, 0.35)
const ACCENT_BLUE := Color(0.35, 0.80, 1.00)
const TEXT := Color(0.97, 0.98, 1.0)
const TEXT_DIM := Color(0.74, 0.78, 0.86)


static func box(bg: Color, border: Color = INK, border_w: int = 4, radius: int = 14, pad: float = 16.0) -> StyleBoxFlat:
	var s := StyleBoxFlat.new()
	s.bg_color = bg
	s.border_color = border
	s.set_border_width_all(border_w)
	s.set_corner_radius_all(radius)
	s.content_margin_left = pad
	s.content_margin_right = pad
	s.content_margin_top = pad * 0.6
	s.content_margin_bottom = pad * 0.6
	s.shadow_color = Color(0, 0, 0, 0.35)
	s.shadow_size = 2
	s.shadow_offset = Vector2(0, 5)
	return s


## Give a control the keyboard / pad focus on the next frame - only if it still exists and is
## in the tree then (a screen can be left before that: "Condition !is_inside_tree()" errors).
## BUTTON outline: round, black, with a 3D lip at the bottom (a pressed button sinks: thin lip).
static func button_box(bg: Color, border: Color = Color(0, 0, 0, 0), pressed: bool = false) -> StyleBoxFlat:
	var rim := border if border.a > 0.0 else bg.lightened(0.38)      # A light rim: readable on dark screens
	var s := box(bg, rim, 3, 26, 16.0)                                # Capsule shape
	s.border_width_bottom = 4 if pressed else 9
	s.border_width_top = 6 if pressed else 3
	s.content_margin_top = 16.0 * 0.6 + (3.0 if pressed else 0.0)
	s.shadow_offset = Vector2(0, 2 if pressed else 5)
	return s


## The controller / keyboard FOCUS ring of a button: drawn just outside its outline.
static func focus_ring(col: Color = ACCENT_GREEN) -> StyleBoxFlat:
	var s := StyleBoxFlat.new()
	s.draw_center = false
	s.border_color = col
	s.set_border_width_all(4)
	s.set_corner_radius_all(30)
	s.set_expand_margin_all(6.0)
	return s


## NOTIFICATION outline: square corners, thin coloured line, thick bar on the left, a glow.
static func notice_box(accent: Color, pad: float = 12.0) -> StyleBoxFlat:
	var s := StyleBoxFlat.new()
	s.bg_color = Color(0.035, 0.04, 0.065, 0.94)
	s.border_color = accent
	s.set_border_width_all(2)
	s.border_width_left = 10
	s.set_corner_radius_all(3)
	s.content_margin_left = pad + 8.0
	s.content_margin_right = pad
	s.content_margin_top = pad * 0.7
	s.content_margin_bottom = pad * 0.7
	s.shadow_color = Color(accent.r, accent.g, accent.b, 0.35)
	s.shadow_size = 12
	s.shadow_offset = Vector2.ZERO
	return s


static func focus_later(c: Control) -> void:
	# A WEAK reference: if the screen closes before next frame, no "Lambda capture was freed" error
	var w: WeakRef = weakref(c)
	(func() -> void:
		var ctl := w.get_ref() as Control
		if ctl != null and ctl.is_inside_tree():
			ctl.grab_focus()).call_deferred()


static func make_button(text: String, min_size: Vector2 = Vector2(340, 62), font_size: int = 26) -> Button:
	var b := Button.new()
	b.text = text
	b.custom_minimum_size = min_size
	b.focus_mode = Control.FOCUS_ALL
	b.mouse_default_cursor_shape = Control.CURSOR_POINTING_HAND
	b.add_theme_font_size_override("font_size", font_size)
	b.add_theme_constant_override("outline_size", 8)
	b.add_theme_color_override("font_outline_color", INK)
	for c in ["font_color", "font_hover_color", "font_pressed_color", "font_focus_color", "font_hover_pressed_color"]:
		b.add_theme_color_override(c, TEXT)
	b.add_theme_stylebox_override("normal", button_box(Color(0.20, 0.24, 0.33)))
	b.add_theme_stylebox_override("hover", button_box(Color(0.22, 0.52, 0.95)))
	b.add_theme_stylebox_override("pressed", button_box(Color(0.18, 0.70, 0.28), Color(0, 0, 0, 0), true))
	b.add_theme_stylebox_override("hover_pressed", button_box(Color(0.18, 0.70, 0.28), Color(0, 0, 0, 0), true))
	b.add_theme_stylebox_override("disabled", button_box(Color(0.14, 0.15, 0.19)))
	b.add_theme_stylebox_override("focus", focus_ring())
	ui_sounds(b)
	return b


## CONTROLLER: explicit D-pad neighbours for rows of buttons (rows = Array of Arrays of Controls).
## Left / right move inside a row (wrapping), up / down jump to the nearest button of the next row.
static func grid_focus(rows: Array) -> void:
	var live: Array = []
	for r in rows:
		var rr: Array = (r as Array).filter(func(c: Variant) -> bool: return c != null and is_instance_valid(c))
		if not rr.is_empty():
			live.append(rr)
	for ri in live.size():
		var row: Array = live[ri]
		for ci in row.size():
			var c: Control = row[ci]
			c.focus_neighbor_left = c.get_path_to(row[(ci - 1 + row.size()) % row.size()])
			c.focus_neighbor_right = c.get_path_to(row[(ci + 1) % row.size()])
			var up: Array = live[(ri - 1 + live.size()) % live.size()]
			var down: Array = live[(ri + 1) % live.size()]
			var k := float(ci) / maxf(float(row.size() - 1), 1.0)
			c.focus_neighbor_top = c.get_path_to(up[roundi(k * float(up.size() - 1))])
			c.focus_neighbor_bottom = c.get_path_to(down[roundi(k * float(down.size() - 1))])
			c.focus_previous = c.focus_neighbor_left
			c.focus_next = c.focus_neighbor_right


## Soft tick when a button gets the focus / hover, a click when it is pressed.
static func ui_sounds(c: Control) -> void:
	c.focus_entered.connect(func() -> void: SoundManager.play_sfx("ui_move", -14.0, 0.02))
	c.mouse_entered.connect(func() -> void: SoundManager.play_sfx("ui_move", -16.0, 0.02))
	if c is BaseButton:
		(c as BaseButton).pressed.connect(func() -> void: SoundManager.play_sfx("ui_select", -8.0, 0.02))


static func label(text: String, font_size: int, color: Color = TEXT, outline: int = 8) -> Label:
	var l := Label.new()
	l.text = text
	l.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	l.add_theme_font_size_override("font_size", font_size)
	l.add_theme_color_override("font_color", color)
	l.add_theme_constant_override("outline_size", outline)
	l.add_theme_color_override("font_outline_color", INK)
	l.mouse_filter = Control.MOUSE_FILTER_IGNORE
	return l
