class_name MadnessFX
extends RefCounted
## MADNESS - the gritty, ominous look (2026-11-21, user: "more ominous", in the spirit of grim flash-
## animation fights): a bleak world drained to GREY where the only colour left is BLOOD RED.
##   Filter    the whole screen: grey with hard contrast, reds kept vivid, heavy film GRAIN, a dark
##             VIGNETTE, a projector FLICKER and now and then a one-frame jolt (under the HUD)
##   Blood     red droplets on every hit + SPLATS that stay on the floor (capped)
##   Whispers  a line flashes faintly on the screen every so often
## Installed by StoryManager for Madness levels and by the Madness board (filter + whispers only).

const SPLAT_MAX := 48
const WHISPERS := ["IT IS WATCHING", "KEEP GOING", "NOBODY IS COMING", "YOU WERE HERE BEFORE", "DON'T LOOK UP",
	"IT LIKES THE NOISE", "COUNT THEM", "THE CHAINS ARE LONGER TODAY", "SMILE", "ONE MORE", "IT REMEMBERS YOUR NAME",
	"WHY ARE YOU STILL HERE", "THE MUSIC NEVER STOPS"]

const FILTER_CODE := """
shader_type canvas_item;
render_mode unshaded;

uniform sampler2D screen_texture : hint_screen_texture, filter_linear_mipmap;
uniform float jolt = 0.0;

float hash(vec2 p) {
	return fract(sin(dot(p, vec2(12.9898, 78.233))) * 43758.5453);
}

void fragment() {
	vec2 uv = SCREEN_UV + vec2(jolt * 0.006, 0.0);
	vec3 c = textureLod(screen_texture, uv, 0.0).rgb;
	float l = dot(c, vec3(0.299, 0.587, 0.114));
	float red = clamp((c.r - max(c.g, c.b)) * 2.6, 0.0, 1.0);          // How RED this pixel is
	vec3 grey = vec3(clamp((l - 0.5) * 1.45 + 0.46, 0.0, 1.0));        // Hard-contrast grey
	vec3 blood = vec3(clamp(l * 1.5 + 0.28, 0.0, 1.0), 0.02, 0.02);
	vec3 o = mix(grey, blood, red);
	float d = distance(SCREEN_UV, vec2(0.5));
	o *= smoothstep(0.82, 0.30, d);                                      // Vignette
	float g = hash(floor(SCREEN_UV / SCREEN_PIXEL_SIZE / 2.0) + floor(TIME * 24.0));
	o += (g - 0.5) * 0.10;                                               // Film grain
	o *= 0.93 + 0.07 * sin(TIME * 31.0) * sin(TIME * 7.0);               // Projector flicker
	if (fract(SCREEN_UV.y * 3.0 + TIME * 0.31) < 0.004) {
		o *= 0.6;                                                         // A scratch line rolling down
	}
	COLOR = vec4(o, 1.0);
}
"""

static var _shader: Shader


## A Madness level: the filter, the whispers, blood on the hero.
static func install_level(m: StoryManager) -> void:
	if not GraphicsSettings.level == GraphicsSettings.POTATO:
		m.add_child(Filter.new())
	m.add_child(Whispers.new())
	if m.player != null:
		m.player.damaged.connect(func(amount: int, _hit: HitData) -> void: bleed(m.player, amount))


## The Madness board: the filter + whispers (no blood).
static func install_board(n: Node) -> void:
	if not GraphicsSettings.level == GraphicsSettings.POTATO:
		n.add_child(Filter.new())
	n.add_child(Whispers.new())


## Blood on a hit: droplets flying + a splat on the floor below.
static func bleed(f: Fighter, amount: int) -> void:
	if f == null or not f.is_inside_tree() or amount <= 0:
		return
	var host := f.get_parent()
	if host == null:
		return
	var spray := Spray.new()
	spray.count = clampi(4 + amount, 5, 22)
	host.add_child(spray)
	spray.global_position = f.global_position + Vector2(0, -f.data.body_size.y * 0.6)
	var floor_y: Variant = Effects.ground_below(f, f.global_position + Vector2(0, -10), 400.0)
	if floor_y != null:
		var sp := Splat.new()
		sp.r = clampf(10.0 + float(amount) * 2.5, 12.0, 46.0)
		host.add_child(sp)
		sp.global_position = floor_y as Vector2
		var all := host.get_tree().get_nodes_in_group("madness_splat")
		if all.size() > SPLAT_MAX:
			(all[0] as Node).queue_free()


static func shader() -> Shader:
	if _shader == null:
		_shader = Shader.new()
		_shader.code = FILTER_CODE
	return _shader


## The screen filter (layer 5: over the world, under the HUD at 10).
class Filter extends CanvasLayer:
	var _rect: ColorRect
	var _mat: ShaderMaterial
	var _next_jolt := 3.0
	var _t := 0.0

	func _ready() -> void:
		layer = 5
		_rect = ColorRect.new()
		_rect.set_anchors_and_offsets_preset(Control.PRESET_FULL_RECT)
		_rect.mouse_filter = Control.MOUSE_FILTER_IGNORE
		_mat = ShaderMaterial.new()
		_mat.shader = MadnessFX.shader()
		_rect.material = _mat
		add_child(_rect)

	func _process(delta: float) -> void:
		_t += delta
		var j := 0.0
		if _t > _next_jolt:                                   # A one-frame jolt every few seconds
			j = randf_range(-1.0, 1.0)
			if _t > _next_jolt + 0.06:
				_next_jolt = _t + randf_range(2.5, 7.0)
		_mat.set_shader_parameter("jolt", j)


## Whispers: a line fades in faintly somewhere on the screen, then away.
class Whispers extends CanvasLayer:
	var _lbl: Label
	var _wait := 9.0

	func _ready() -> void:
		layer = 9
		_lbl = Label.new()
		_lbl.add_theme_font_size_override("font_size", 30)
		_lbl.add_theme_color_override("font_color", Color(0.85, 0.05, 0.04))
		_lbl.add_theme_color_override("font_outline_color", Color(0, 0, 0))
		_lbl.add_theme_constant_override("outline_size", 8)
		_lbl.modulate.a = 0.0
		_lbl.mouse_filter = Control.MOUSE_FILTER_IGNORE
		add_child(_lbl)

	func _process(delta: float) -> void:
		_wait -= delta
		if _wait > 0.0:
			return
		_wait = randf_range(14.0, 26.0)
		var vp := get_viewport().get_visible_rect().size
		_lbl.text = String(MadnessFX.WHISPERS[randi() % MadnessFX.WHISPERS.size()])
		_lbl.position = Vector2(randf_range(vp.x * 0.1, vp.x * 0.6), randf_range(vp.y * 0.15, vp.y * 0.6))
		var tw := create_tween()
		tw.tween_property(_lbl, "modulate:a", 0.55, 0.6)
		tw.tween_interval(1.2)
		tw.tween_property(_lbl, "modulate:a", 0.0, 1.0)


## Flying blood droplets (gravity), gone in about a second.
class Spray extends Node2D:
	var count := 8
	var _drops: Array = []                                   # [pos, vel, size]
	var _t := 0.0

	func _ready() -> void:
		z_index = 3
		for i in count:
			var a := randf_range(-PI * 0.95, -PI * 0.05)
			_drops.append([Vector2.ZERO, Vector2.from_angle(a) * randf_range(120.0, 420.0), randf_range(2.0, 5.5)])

	func _process(delta: float) -> void:
		_t += delta
		for d in _drops:
			d[1] = (d[1] as Vector2) + Vector2(0, 1100.0 * delta)
			d[0] = (d[0] as Vector2) + (d[1] as Vector2) * delta
		queue_redraw()
		if _t > 1.0:
			queue_free()

	func _draw() -> void:
		var a := clampf(1.3 - _t, 0.0, 1.0)
		for d in _drops:
			var p: Vector2 = d[0]
			var v: Vector2 = d[1]
			draw_line(p, p - v.normalized() * float(d[2]) * 2.2, Color(0.75, 0.0, 0.0, a), float(d[2]))


## A blood splat on the floor (stays; the oldest go when there are too many).
class Splat extends Node2D:
	var r := 20.0
	var _seed := 0

	func _ready() -> void:
		z_index = -1
		add_to_group("madness_splat")
		_seed = randi()

	func _draw() -> void:
		var rng := RandomNumberGenerator.new()
		rng.seed = _seed
		var pts := PackedVector2Array()
		for i in 16:
			var a := TAU * float(i) / 16.0
			var rr := r * rng.randf_range(0.55, 1.15)
			pts.append(Vector2(cos(a) * rr, sin(a) * rr * 0.2))
		draw_colored_polygon(pts, Color(0.55, 0.0, 0.0, 0.9))
		for k in 3:
			draw_circle(Vector2(rng.randf_range(-r * 1.6, r * 1.6), rng.randf_range(-3.0, 3.0)), rng.randf_range(2.0, 5.0), Color(0.55, 0.0, 0.0, 0.85))
