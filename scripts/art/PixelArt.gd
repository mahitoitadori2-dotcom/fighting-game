class_name PixelArt
extends CanvasGroup
## PIXEL ART (2026-11-21, user: "Pixel Art", hybrid style, medium 3 px pixels).
## Every Fighter (heroes, enemies, bosses, minions, replay puppets) is drawn inside one of these:
##     Fighter -> PixelArt (this CanvasGroup) -> Pose (shared animation offsets) -> Visuals (the art)
## The group renders the vector art, then this shader snaps it to a grid of PX game units: one
## colour per cell (sampled at the cell centre), hard edges, see-through parts DITHERED (no soft
## alpha), colours posterized a little. The grid is anchored to the fighter's feet, so the pixels
## move WITH the fighter and never "swim" over its body.
## The important parts of the 7 playable fighters are also hand-pixelled (PixelSprite).
## Off: Settings > Graphics POTATO (phones that need every frame), or PixelArt.enabled = false.

const PX := 3.0                          # Pixel size in game units (fighters are ~64 x 128)
static var enabled := true
static var rim_on := true                # Edge light / shade (8 extra screen reads per pixel; REGULAR+ only)

const SHADER_CODE := """
shader_type canvas_item;
render_mode unshaded;

uniform sampler2D screen_texture : hint_screen_texture, repeat_disable, filter_nearest;
uniform float px = 3.0;                  // Cell size in SCREEN pixels
uniform vec2 origin = vec2(0.0);         // Grid anchor (the feet) in screen pixels
uniform float levels = 14.0;             // Colour steps per channel
uniform float rim = 1.0;                 // MODEL SHADING (2026-11-24): light on top edges, shade on bottom edges

float bayer2(vec2 a) {
	a = floor(a);
	return fract(a.x / 2.0 + a.y * a.y * 0.75);
}

float bayer4(vec2 a) {                   // 4x4 ordered dither threshold, 0..1
	return bayer2(0.5 * a) * 0.25 + bayer2(a);
}

float alpha_at(vec2 cl, vec2 o, float p, vec2 sps) {
	return textureLod(screen_texture, ((cl + 0.5) * p + o) * sps, 0.0).a;
}

void fragment() {
	vec2 sp = SCREEN_UV / SCREEN_PIXEL_SIZE;
	vec2 cell = floor((sp - origin) / px);
	vec2 uv = ((cell + 0.5) * px + origin) * SCREEN_PIXEL_SIZE;
	vec4 c = textureLod(screen_texture, uv, 0.0);
	if (c.a > 0.0001) {
		c.rgb /= c.a;
	}
	float a = c.a > bayer4(cell) * 0.96 + 0.02 ? 1.0 : 0.0;   // Dithered transparency, hard edges
	vec3 rgb = floor(c.rgb * levels + 0.5) / levels;           // Gentle posterize
	// Shading: the cells just inside the TOP / LEFT edge catch the light, the BOTTOM / RIGHT edge
	// is in shade. The black outline itself is left alone (it stays crisp).
	if (a > 0.5 && rim > 0.0 && dot(rgb, vec3(0.3, 0.59, 0.11)) > 0.07) {
		float up = min(alpha_at(cell + vec2(0.0, -1.0), origin, px, SCREEN_PIXEL_SIZE), alpha_at(cell + vec2(0.0, -2.0), origin, px, SCREEN_PIXEL_SIZE));
		float lf = min(alpha_at(cell + vec2(-1.0, 0.0), origin, px, SCREEN_PIXEL_SIZE), alpha_at(cell + vec2(-2.0, 0.0), origin, px, SCREEN_PIXEL_SIZE));
		float dn = min(alpha_at(cell + vec2(0.0, 1.0), origin, px, SCREEN_PIXEL_SIZE), alpha_at(cell + vec2(0.0, 2.0), origin, px, SCREEN_PIXEL_SIZE));
		float rt = min(alpha_at(cell + vec2(1.0, 0.0), origin, px, SCREEN_PIXEL_SIZE), alpha_at(cell + vec2(2.0, 0.0), origin, px, SCREEN_PIXEL_SIZE));
		if (up < 0.3 || lf < 0.3) {
			rgb = mix(rgb, vec3(1.0, 0.97, 0.90), 0.34 * rim);
		} else if (dn < 0.3 || rt < 0.3) {
			rgb *= 1.0 - 0.26 * rim;
		}
	}
	COLOR = vec4(rgb, a) * COLOR;
}
"""

static var _shader: Shader


static func shader() -> Shader:
	if _shader == null:
		_shader = Shader.new()
		_shader.code = SHADER_CODE
	return _shader


## Is pixel art on right now? (POTATO graphics turn it off: it costs one extra pass per fighter.)
static func active() -> bool:
	return enabled and GraphicsSettings.level != GraphicsSettings.POTATO


var _mat: ShaderMaterial


func _ready() -> void:
	fit_margin = 12.0
	clear_margin = 12.0
	texture_filter = CanvasItem.TEXTURE_FILTER_NEAREST
	_mat = ShaderMaterial.new()
	_mat.shader = shader()
	_apply()


func _apply() -> void:
	material = _mat if active() else null


func _process(_delta: float) -> void:
	if (material != null) != active():
		_apply()                                  # Graphics setting changed
	if material == null:
		return
	# Cell size + grid anchor in window pixels (camera zoom and the window stretch included)
	var vp := get_viewport()
	if vp == null:
		return
	var xf := vp.get_final_transform() * get_global_transform_with_canvas()
	var s := absf(xf.get_scale().y)
	_mat.set_shader_parameter("px", maxf(PX * s, 1.0))
	# Edge shading costs 8 extra screen reads per pixel: PC graphics levels only (phones start on FAST,
	# where it was barely visible anyway - /nolags 2026-11-25: 11.5 -> 17.3 fps in the golem crowd)
	_mat.set_shader_parameter("rim", 1.0 if rim_on and GraphicsSettings.level >= GraphicsSettings.REGULAR else 0.0)
	_mat.set_shader_parameter("origin", xf.origin)
