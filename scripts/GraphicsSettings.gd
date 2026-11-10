class_name GraphicsSettings
extends Node
## GRAPHICS QUALITY (autoload "Graphics" applies it on boot; saved in user://graphics.cfg).
##
##   POTATO   really bad, for microwaves: low-res render, 30 FPS cap, tiny particle cap,
##            no trails / embers, plain backgrounds redrawn at 20 FPS.
##   FAST     mobiles + old computers (iPhone 11 target: 40+ FPS): base-res render
##            (no hi-DPI fill cost), 60 FPS cap, fewer sparks, short trails,
##            backgrounds redrawn every other frame, lighter backgrounds.
##   REGULAR  the original graphics (default).
##   REAL     good PCs: glow / bloom on bright things, more sparks, longer trails,
##            bigger particle cap, uncapped frame rate.
##
## Gameplay code reads the static helpers:
##   GraphicsSettings.level                 -> POTATO / FAST / REGULAR / REAL
##   GraphicsSettings.fx_count(n)           -> scaled spark / particle count
##   GraphicsSettings.trail_length(n)       -> scaled trail length (0 = no trail)
##   GraphicsSettings.bg_should_redraw()    -> throttled per-frame background redraws
##   GraphicsSettings.bg_detail()           -> false = skip background decoration

const POTATO := 0
const FAST := 1
const REGULAR := 2
const REAL := 3
const NAMES := ["POTATO", "FAST", "REGULAR", "REAL"]
const DESCS := [
	"Really bad. For microwaves.",
	"For mobiles and old computers.",
	"For normal PCs. The original look.",
	"Way better. For good PCs.",
]
const PATH := "user://graphics.cfg"

const _FX_MULT := [0.35, 0.6, 1.0, 1.6]
const _TRAIL_MULT := [0.0, 0.6, 1.0, 1.5]
const _BG_EVERY := [3, 2, 1, 1]               # Animated backgrounds redraw every N frames
const _MAX_FPS := [30, 60, 0, 0]
const _PARTICLES := [40, 90, -1, 320]          # -1 = original cap (110 phones / 200 PCs)

static var level := REGULAR
static var _loaded := false


func _ready() -> void:
	process_mode = Node.PROCESS_MODE_ALWAYS
	load_settings()
	apply(get_tree())


static func load_settings() -> void:
	if _loaded:
		return
	_loaded = true
	var cfg := ConfigFile.new()
	if cfg.load(PATH) == OK:
		level = clampi(int(cfg.get_value("graphics", "level", REGULAR)), POTATO, REAL)


static func save_settings() -> void:
	var cfg := ConfigFile.new()
	cfg.set_value("graphics", "level", level)
	cfg.save(PATH)


static func set_level(new_level: int, tree: SceneTree) -> void:
	level = clampi(new_level, POTATO, REAL)
	save_settings()
	apply(tree)


## Engine / window side of the preset. Safe to call any time (changes are live).
static func apply(tree: SceneTree) -> void:
	if tree == null:
		return
	var root := tree.root
	# Low presets render at the 1280x720 base size and upscale: on hi-DPI phones that is
	# ~half the pixels to fill. Regular / Real render at full screen resolution.
	root.content_scale_mode = Window.CONTENT_SCALE_MODE_VIEWPORT if level <= FAST else Window.CONTENT_SCALE_MODE_CANVAS_ITEMS
	# (2D MSAA and FXAA are not supported by the Compatibility renderer: REAL uses glow instead.)
	_apply_glow(root)
	Engine.max_fps = _MAX_FPS[level]
	var cap: int = _PARTICLES[level]
	if cap < 0:
		cap = 110 if (OS.has_feature("web_ios") or OS.has_feature("web_android")) else 200
	OptimizationManager.MAX_PARTICLES = cap


## REAL only: soft bloom on bright things (fire, lights, sparks, impact flashes).
static var _glow_env: WorldEnvironment


static func _apply_glow(root: Window) -> void:
	if level == REAL:
		if _glow_env == null or not is_instance_valid(_glow_env):
			var env := Environment.new()
			env.background_mode = Environment.BG_CANVAS
			env.glow_enabled = true
			env.glow_intensity = 0.45
			env.glow_strength = 0.9
			env.glow_bloom = 0.0
			env.glow_hdr_threshold = 0.85
			env.glow_blend_mode = Environment.GLOW_BLEND_MODE_SCREEN
			_glow_env = WorldEnvironment.new()
			_glow_env.name = "RealGlow"
			_glow_env.environment = env
			root.add_child.call_deferred(_glow_env)
	elif _glow_env != null and is_instance_valid(_glow_env):
		_glow_env.queue_free()
		_glow_env = null


# ============================================================
# HELPERS FOR EFFECTS / BACKGROUNDS
# ============================================================
static func fx_count(n: int) -> int:
	return maxi(1, roundi(float(n) * _FX_MULT[level]))


static func trail_length(n: int) -> int:
	return roundi(float(n) * _TRAIL_MULT[level])


## Per-frame animated backgrounds: true on the frames they should redraw.
static func bg_should_redraw() -> bool:
	var every: int = _BG_EVERY[level]
	return every <= 1 or Engine.get_process_frames() % every == 0


## false on POTATO: skip clouds, lit windows, embers and other decoration.
static func bg_detail() -> bool:
	return level >= FAST


## true on REGULAR and up: the full original backdrop detail.
static func bg_full() -> bool:
	return level >= REGULAR
