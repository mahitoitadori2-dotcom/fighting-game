class_name Stage3D
extends Node3D
## One 3D scene: sky / ambient light / fog, a sun light, a camera that follows KEYFRAMES, and
## per-frame animators. Cutscenes / backdrops / menus build their scene into it with Three.*.
##
##   sky(top, horizon, ground)      background gradient sky (+ ambient light from it)
##   fog(col, density)              depth fog (makes far things fade into the sky colour)
##   sun(dir_deg, col, energy)      the main light
##   cam_key(t, pos, look)          camera keyframe (smooth between keys)
##   animate(callable)              called every frame with the stage time t

var camera: Camera3D
var env: Environment
var t := 0.0
var keys: Array = []                   # [t, pos, look]
var animators: Array[Callable] = []
var auto := true                       # false = the owner drives the time with update() (cutscenes)


func _init() -> void:
	camera = Camera3D.new()
	camera.fov = 55.0
	camera.current = true
	add_child(camera)
	var we := WorldEnvironment.new()
	env = Environment.new()
	env.background_mode = Environment.BG_COLOR
	env.background_color = Color(0.1, 0.1, 0.15)
	env.ambient_light_source = Environment.AMBIENT_SOURCE_COLOR
	env.ambient_light_color = Color(0.6, 0.6, 0.65)
	env.ambient_light_energy = 0.7
	env.tonemap_mode = Environment.TONE_MAPPER_FILMIC
	we.environment = env
	add_child(we)


func sky(top: Color, horizon: Color, ground: Color) -> void:
	var sm := ProceduralSkyMaterial.new()
	sm.sky_top_color = top
	sm.sky_horizon_color = horizon
	sm.ground_horizon_color = horizon.darkened(0.2)
	sm.ground_bottom_color = ground
	sm.sun_angle_max = 1.0
	var s := Sky.new()
	s.sky_material = sm
	env.background_mode = Environment.BG_SKY
	env.sky = s
	env.ambient_light_color = horizon.lerp(Color.WHITE, 0.3)


func fog(col: Color, density: float = 0.02) -> void:
	env.fog_enabled = true
	env.fog_light_color = col
	env.fog_density = density
	env.fog_sky_affect = 0.0


func sun(dir_deg: Vector3, col: Color = Color(1, 0.96, 0.9), energy: float = 1.2) -> DirectionalLight3D:
	var l := DirectionalLight3D.new()
	l.rotation_degrees = dir_deg
	l.light_color = col
	l.light_energy = energy
	l.shadow_enabled = GraphicsSettings.level >= GraphicsSettings.REAL
	add_child(l)
	return l


func cam_key(at: float, pos: Vector3, look: Vector3) -> void:
	keys.append([at, pos, look])


func animate(fn: Callable) -> void:
	animators.append(fn)


func _process(delta: float) -> void:
	if auto:
		update(t + delta)


## Moves everything to stage time `now` (cutscenes drive it from their own clock).
func update(now: float) -> void:
	t = now
	if not keys.is_empty():
		var a: Array = keys[0]
		var b: Array = keys[keys.size() - 1]
		for i in keys.size() - 1:
			if t >= float(keys[i][0]) and t <= float(keys[i + 1][0]):
				a = keys[i]
				b = keys[i + 1]
				break
		if t > float(b[0]):
			a = b
		var k := 0.0
		if float(b[0]) > float(a[0]):
			k = clampf((t - float(a[0])) / (float(b[0]) - float(a[0])), 0.0, 1.0)
			k = k * k * (3.0 - 2.0 * k)
		camera.position = (a[1] as Vector3).lerp(b[1], k)
		var look: Vector3 = (a[2] as Vector3).lerp(b[2], k)
		if camera.position.distance_to(look) > 0.01:
			camera.look_at(look, Vector3.UP)
	for fn in animators:
		fn.call(t)
