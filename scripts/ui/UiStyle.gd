class_name UiStyle
extends RefCounted
## Shared look for menus: chunky cartoon buttons with thick black borders and
## outlined text, matching the in-game art style.

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
	b.add_theme_stylebox_override("normal", box(Color(0.20, 0.24, 0.33)))
	b.add_theme_stylebox_override("hover", box(Color(0.22, 0.52, 0.95)))
	b.add_theme_stylebox_override("pressed", box(Color(0.18, 0.70, 0.28)))
	b.add_theme_stylebox_override("hover_pressed", box(Color(0.18, 0.70, 0.28)))
	var focus := box(Color(0, 0, 0, 0), ACCENT_GREEN, 4)
	focus.draw_center = false
	focus.shadow_size = 0
	b.add_theme_stylebox_override("focus", focus)
	return b


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
