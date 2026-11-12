class_name CharacterPortrait
extends Control
## Animated idle portrait of a character, drawn with the same code as in-game.
## `art` must be a script with: static func draw_portrait(c: CanvasItem, t: float)

var art: Script
var accent := Color(0.35, 0.8, 1.0)
var art_scale := 1.6

var _t := 0.0


func _ready() -> void:
	clip_contents = true
	mouse_filter = Control.MOUSE_FILTER_IGNORE


func _process(delta: float) -> void:
	_t += delta
	queue_redraw()


func _draw() -> void:
	var center := Vector2(size.x * 0.5, size.y * 0.5)
	var r := minf(size.x, size.y) * 0.42

	# Glow + hexagon emblem behind the fighter
	draw_circle(center, r * 1.1, Color(accent.r, accent.g, accent.b, 0.14))
	var hex := PackedVector2Array()
	for i in 6:
		var a := TAU * float(i) / 6.0 + _t * 0.15
		hex.append(center + Vector2(cos(a), sin(a)) * r)
	draw_colored_polygon(hex, Color(0.08, 0.10, 0.15, 0.85))
	var closed := hex.duplicate()
	closed.append(hex[0])
	draw_polyline(closed, Color(0, 0, 0), 9.0, FighterArt.AA)
	draw_polyline(closed, accent, 4.0, FighterArt.AA)

	# Ground shadow
	var feet := Vector2(size.x * 0.5, size.y - 16.0)
	draw_set_transform(feet, 0.0, Vector2(1.0, 0.22))
	draw_circle(Vector2.ZERO, 70.0, Color(0, 0, 0, 0.35))

	# The fighter
	# Big art (the Fights-mode bosses) declares const PORTRAIT_H so it still fits the card
	var art_h := 135.0
	if art != null:
		art_h = maxf(art_h, float(art.get_script_constant_map().get("PORTRAIT_H", 135.0)))
	var s := minf(art_scale, (size.y - 30.0) / art_h)
	draw_set_transform(feet + Vector2(0, -4), 0.0, Vector2(s, s))
	if art != null:
		art.call("draw_portrait", self, _t)
	else:
		draw_string(ThemeDB.fallback_font, Vector2(-10, -50), "?", HORIZONTAL_ALIGNMENT_CENTER, -1, 60)
	draw_set_transform(Vector2.ZERO, 0.0, Vector2.ONE)
