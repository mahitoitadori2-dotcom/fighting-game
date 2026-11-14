class_name CaveSlide
extends Node2D
## THE CAVES (Story part 8, levels 64-66): NO COMBAT. You slide down a cave tunnel on your own -
## no enemies, no attacks, A / D do nothing.
##   W (jump)            jump over rocks and chasms                       (all three caves)
##   S (crouch)          on the ground: duck flat under low rock         (caves 2 and 3)
##                       in the air:    dive down fast ("dodge downwards")
## Touch: right half = jump, left half = duck / dive.
## Hitting something: a tumble, then you start again from the last glowing crystal (checkpoint).
## The layout is the same every time (seeded), so you can learn it.

const G := 2700.0                     # Gravity (px/s^2)
const JUMP_V := 1000.0                # Jump speed: ~185 px high, ~0.74 s in the air
const DIVE_V := -1700.0               # S in the air: straight down
const SLOPE := 0.16                   # The tunnel runs downhill
const STAND_H := 110.0
const DUCK_H := 44.0
const CEIL_GAP := 72.0                # Low rock: its bottom is this high above the floor
const HALF_W := 24.0
const TUNNEL_H := 420.0               # Floor to the cave roof
const COYOTE := 0.09
const BUFFER := 0.13

## Per cave: length (px), speed (px/s), colours, what can appear.
const TIERS := {
	1: {"len": 30000.0, "speed": 560.0, "sky": [Color(0.10, 0.06, 0.04), Color(0.20, 0.11, 0.06)], "rock": Color(0.24, 0.16, 0.11),
		"glow": Color(1.0, 0.62, 0.25), "music": "story_cave", "pool": ["rock", "rock", "spikes", "gap", "gap", "double"]},
	2: {"len": 38000.0, "speed": 620.0, "sky": [Color(0.03, 0.06, 0.10), Color(0.06, 0.12, 0.18)], "rock": Color(0.13, 0.17, 0.23),
		"glow": Color(0.35, 0.85, 1.0), "music": "story_darkcave", "pool": ["rock", "spikes", "gap", "ceil", "ceil", "rock_ceil", "double"]},
	3: {"len": 46000.0, "speed": 690.0, "sky": [Color(0.08, 0.02, 0.08), Color(0.18, 0.04, 0.10)], "rock": Color(0.17, 0.09, 0.15),
		"glow": Color(1.0, 0.35, 0.55), "music": "story_void", "pool": ["rock", "spikes", "gap", "ceil", "long_ceil", "gap_ceil", "rock_ceil", "double"]},
}

var level_n := 64
var tier := 1
var hero := "warrior"
var _cfg: Dictionary
var _len := 30000.0
var _obs: Array = []                  # {kind: "rock" / "spikes" / "gap" / "ceil", x, w, h}
var _checks: Array = []               # Checkpoint x (crystals)
var _check_i := -1                    # Last crystal passed

var px := 0.0                         # Distance down the tunnel
var h := 0.0                          # Height above the floor
var vy := 0.0
var speed := 0.0
var ducking := false
var _duck_t := 0.0
var _air_t := 0.0                     # Time since leaving the ground (coyote)
var _jump_buf := 0.0
var _crash := -1.0                    # >= 0: tumbling after a hit
var _invuln := 0.0
var _started := false
var _done := false
var hits := 0
var _t := 0.0
var _cam := Vector2.ZERO
var _shake := 0.0
var _dust: Array = []                 # [pos, vel, life]
var _touch_duck := {}                 # touch index -> true (left half held)

var _ui: CanvasLayer
var _hud: Control
var _banner: Label
var _sub: Label


func _ready() -> void:
	StoryProgress.load_progress()
	level_n = clampi(StoryProgress.current_level, StoryLevels.first_of(StoryLevels.CAVES_PART), StoryLevels.last_of(StoryLevels.CAVES_PART))
	tier = clampi(level_n - StoryLevels.first_of(StoryLevels.CAVES_PART) + 1, 1, 3)
	hero = StoryLevels.hero_of(level_n)
	_cfg = TIERS[tier]
	_len = float(_cfg["len"])
	_build_layout()
	_build_ui()
	SoundManager.play_music(String(_cfg["music"]))
	_intro()


# ============================================================
# LAYOUT (seeded: the same cave every time)
# ============================================================
func floor_y(x: float) -> float:
	return x * SLOPE + 70.0 * sin(x / 950.0) + 26.0 * sin(x / 330.0 + 1.3)


func _build_layout() -> void:
	var rng := RandomNumberGenerator.new()
	rng.seed = 7700 + tier * 131
	var v := float(_cfg["speed"])
	_checks = [_len * 0.25, _len * 0.5, _len * 0.75]
	var pool: Array = _cfg["pool"]
	var x := 1500.0
	var step := 0
	while x < _len - 1400.0:
		# Keep the ground clear around the crystals (you restart there)
		var near := false
		for c in _checks:
			if x > c - 250.0 and x < c + 700.0:
				near = true
		if near:
			x += 300.0
			continue
		# The first few obstacles of a cave are the easy ones
		var kind: String = pool[rng.randi() % pool.size()] if step > 2 else ["rock", "gap", "ceil" if tier > 1 else "rock"][step]
		step += 1
		var end := x
		match kind:
			"rock":
				var w := rng.randf_range(60.0, 110.0)
				_obs.append({"kind": "rock", "x": x, "w": w, "h": rng.randf_range(48.0, 92.0)})
				end = x + w
			"spikes":
				var w2 := rng.randf_range(90.0, 170.0)
				_obs.append({"kind": "spikes", "x": x, "w": w2, "h": 46.0})
				end = x + w2
			"gap":
				var w3 := rng.randf_range(150.0, 230.0 + 30.0 * float(tier))
				_obs.append({"kind": "gap", "x": x, "w": w3, "h": 0.0})
				end = x + w3
			"double":                                        # Two rocks: two quick jumps
				_obs.append({"kind": "rock", "x": x, "w": 70.0, "h": 60.0})
				var x2 := x + v * 0.95
				_obs.append({"kind": "rock", "x": x2, "w": 80.0, "h": 70.0})
				end = x2 + 80.0
			"ceil":                                          # Low rock: duck under it
				var w4 := rng.randf_range(160.0, 300.0)
				_obs.append({"kind": "ceil", "x": x, "w": w4, "h": CEIL_GAP})
				end = x + w4
			"long_ceil":                                     # Hold S through a long crawl
				var w5 := rng.randf_range(600.0, 900.0)
				_obs.append({"kind": "ceil", "x": x, "w": w5, "h": CEIL_GAP})
				end = x + w5
			"rock_ceil":                                     # Jump a rock, then duck right away
				_obs.append({"kind": "rock", "x": x, "w": 70.0, "h": 58.0})
				var cx := x + v * 1.05
				_obs.append({"kind": "ceil", "x": cx, "w": 220.0, "h": CEIL_GAP})
				end = cx + 220.0
			"gap_ceil":                                      # Jump a chasm, DIVE down (S) before the low rock
				var gw := 170.0
				_obs.append({"kind": "gap", "x": x, "w": gw, "h": 0.0})
				var c2 := x + v * 0.66
				_obs.append({"kind": "ceil", "x": c2, "w": 260.0, "h": CEIL_GAP})
				end = c2 + 260.0
		x = end + v * rng.randf_range(0.95, 1.55) * (0.85 if tier == 3 else 1.0)


func _in_gap(x: float) -> bool:
	for o in _obs:
		if o["kind"] == "gap" and x > float(o["x"]) and x < float(o["x"]) + float(o["w"]):
			return true
	return false


# ============================================================
# FLOW
# ============================================================
func _intro() -> void:
	var title := String(StoryLevels.get_level(level_n).get("title", "THE CAVES"))
	var keys := "W  -  JUMP" if tier == 1 else "W  -  JUMP        S  -  DUCK / DIVE DOWN"
	_show("LEVEL %d:  %s" % [level_n, title], keys + "\nNo enemies.  Just slide.")
	await get_tree().create_timer(2.8).timeout
	_hide()
	_started = true


func _finish() -> void:
	_done = true
	SoundManager.play_sfx("count_go")
	var flawless := hits == 0
	_show("CAVE CLEARED!", ("NOT A SCRATCH!" if flawless else "Crashes: %d" % hits) + "    |    Progress saved")
	StoryProgress.complete_level(level_n)
	Achievements.unlock("cave_%d" % tier)
	if flawless:
		Achievements.unlock("cave_flawless_%d" % tier)
	if hits >= 15:
		Achievements.unlock("cave_crash")
	if level_n == StoryLevels.last_of(StoryLevels.CAVES_PART):
		Achievements.unlock("col_%d" % StoryLevels.CAVES_PART)
	if StoryManager.autoplay:
		print("CAVES autoplay: level %d CLEAR, crashes %d" % [level_n, hits])
	await get_tree().create_timer(2.2).timeout
	StoryBoard.advance_from = level_n
	if level_n < StoryProgress.AVAILABLE_LEVELS:
		StoryProgress.current_level = level_n + 1
	get_tree().change_scene_to_file(StoryManager.STORY_MENU)


func _crash_now(why: String) -> void:
	if _crash >= 0.0 or _invuln > 0.0 or _done:
		return
	_crash = 0.0
	hits += 1
	_shake = 14.0
	SoundManager.play_sfx("stone")
	SoundManager.play_sfx("slam", -6.0)
	for i in 14:
		_dust.append([Vector2(px, floor_y(px) - h - 40.0), Vector2(randf_range(-260, 260), randf_range(-420, -60)), 0.7])
	if StoryManager.autoplay:
		print("CAVES autoplay: crash at %d (%s)" % [int(px), why])


func _respawn() -> void:
	_crash = -1.0
	px = float(_checks[_check_i]) if _check_i >= 0 else 300.0
	h = 0.0
	vy = 0.0
	speed = float(_cfg["speed"]) * 0.5
	ducking = false
	_invuln = 1.0
	SoundManager.play_sfx("spawn", -6.0)


# ============================================================
# INPUT
# ============================================================
func _unhandled_input(event: InputEvent) -> void:
	if event.is_action_pressed("ui_cancel"):
		get_tree().change_scene_to_file(StoryManager.STORY_MENU)
		return
	if event.is_action_pressed("jump"):
		_jump_buf = BUFFER
	if event.is_action_pressed("crouch"):
		_press_down()
	var st := event as InputEventScreenTouch
	if st != null:
		var left := st.position.x < get_viewport_rect().size.x * 0.5
		if st.pressed:
			if left:
				_touch_duck[st.index] = true
				_press_down()
			else:
				_jump_buf = BUFFER
		else:
			_touch_duck.erase(st.index)


func _down_held() -> bool:
	return Input.is_action_pressed("crouch") or not _touch_duck.is_empty()


## S: dive in the air, duck on the ground (only from the 2nd cave on).
func _press_down() -> void:
	if tier < 2 or not _started or _crash >= 0.0:
		return
	if h > 0.5:
		vy = DIVE_V
		SoundManager.play_sfx("whoosh", -8.0)
	else:
		_duck_t = 0.35
		SoundManager.play_sfx("whoosh", -10.0)


## Autoplay (tests only): looks ahead and presses the keys.
func _bot() -> void:
	var v := maxf(speed, 1.0)
	for o in _obs:
		var ox := float(o["x"])
		var ow := float(o["w"])
		if ox + ow < px - HALF_W:
			continue
		var dist := ox - px
		if dist > v * 0.9:
			break
		match String(o["kind"]):
			"rock", "spikes":
				if dist < v * 0.16 + 30.0 and h <= 0.5:
					_jump_buf = BUFFER
			"gap":
				if dist < 40.0 and dist > -20.0 and h <= 0.5:
					_jump_buf = BUFFER
			"ceil":
				if h > 0.5 and dist < v * 0.35 and not _in_gap(px + v * 0.08):
					if vy > DIVE_V * 0.5:
						vy = DIVE_V
				elif h <= 0.5 and dist < v * 0.12:
					_duck_t = maxf(_duck_t, (ow + 2.0 * HALF_W) / v + 0.05)
		return


# ============================================================
# UPDATE
# ============================================================
func _process(delta: float) -> void:
	_t += delta
	_shake = maxf(_shake - delta * 40.0, 0.0)
	_jump_buf = maxf(_jump_buf - delta, 0.0)
	_invuln = maxf(_invuln - delta, 0.0)
	_duck_t = maxf(_duck_t - delta, 0.0)
	for d in _dust:
		d[0] += d[1] * delta
		d[1].y += 900.0 * delta
		d[2] -= delta
	_dust = _dust.filter(func(d: Array) -> bool: return d[2] > 0.0)
	if _started and not _done:
		if _crash >= 0.0:
			_crash += delta
			px += speed * 0.25 * delta
			speed = lerpf(speed, 0.0, delta * 3.0)
			if _crash > 1.0:
				_respawn()
		else:
			_run(delta)
	var target := Vector2(px - get_viewport_rect().size.x * 0.32, floor_y(px) - get_viewport_rect().size.y * 0.60)
	_cam = target if _t < 0.1 else _cam.lerp(target, minf(delta * 6.0, 1.0))
	queue_redraw()
	_hud.queue_redraw()


func _run(delta: float) -> void:
	if StoryManager.autoplay:
		_bot()
	var top_speed := float(_cfg["speed"]) * (1.0 + 0.10 * px / _len)
	speed = move_toward(speed, top_speed, 500.0 * delta)
	px += speed * delta
	var grounded := h <= 0.0 and not _in_gap(px)
	_air_t = 0.0 if grounded else _air_t + delta
	ducking = tier >= 2 and grounded and (_duck_t > 0.0 or _down_held())
	if _jump_buf > 0.0 and (grounded or _air_t < COYOTE) and vy <= 0.0 and h > -20.0:
		vy = JUMP_V
		h = maxf(h, 0.0) + 1.0
		_jump_buf = 0.0
		ducking = false
		SoundManager.play_sfx("jump", -4.0)
	if not grounded or vy > 0.0:
		vy -= G * delta
		h += vy * delta
		if h <= 0.0 and not _in_gap(px):
			if vy < -900.0:
				_shake = 4.0
			h = 0.0
			vy = 0.0
	if h < -70.0:
		_crash_now("fell")                              # Into the chasm
	# Sparks from the feet while sliding
	if h <= 0.0 and randf() < 0.6:
		_dust.append([Vector2(px - 20.0, floor_y(px) - 4.0), Vector2(randf_range(-240, -60), randf_range(-160, -40)), 0.35])
	# Hits
	var top := h + (DUCK_H if ducking else STAND_H)
	for o in _obs:
		var ox := float(o["x"])
		if ox > px + HALF_W:
			break
		if ox + float(o["w"]) < px - HALF_W:
			continue
		match String(o["kind"]):
			"rock", "spikes":
				if h < float(o["h"]) - 6.0:
					_crash_now(String(o["kind"]))
			"ceil":
				if top > float(o["h"]) + 4.0:
					_crash_now("ceil")
	# Crystals (checkpoints)
	while _check_i + 1 < _checks.size() and px >= float(_checks[_check_i + 1]):
		_check_i += 1
		SoundManager.play_sfx("holy", -6.0)
	if px >= _len:
		_finish()


# ============================================================
# DRAWING
# ============================================================
func _draw() -> void:
	var vs := get_viewport_rect().size
	var shake := Vector2(randf_range(-1, 1), randf_range(-1, 1)) * _shake
	var cam := _cam + shake
	var sky: Array = _cfg["sky"]
	var rock: Color = _cfg["rock"]
	var glow: Color = _cfg["glow"]
	# Background (screen space): dark gradient + far rock columns (parallax)
	for i in 8:                                              # Soft gradient (no hard line)
		draw_rect(Rect2(0, vs.y * float(i) / 8.0, vs.x, vs.y / 8.0 + 1.0), (sky[0] as Color).lerp(sky[1], float(i) / 7.0))
	var par := fmod(cam.x * 0.25, 420.0)
	for i in 6:
		var bx := float(i) * 420.0 - par
		var top := vs.y * (0.10 + 0.08 * sin(float(i) * 1.7 + floor(cam.x * 0.25 / 420.0)))
		draw_colored_polygon(PackedVector2Array([Vector2(bx, -10), Vector2(bx + 150, -10), Vector2(bx + 110, top + 160), Vector2(bx + 70, top + 230), Vector2(bx + 40, top + 150)]), sky[1].darkened(0.4))
		draw_colored_polygon(PackedVector2Array([Vector2(bx + 200, vs.y + 10), Vector2(bx + 260, vs.y * 0.62), Vector2(bx + 300, vs.y * 0.70), Vector2(bx + 360, vs.y + 10)]), sky[0].lightened(0.06))
	# Glowing crystals / worms in the far wall
	var par2 := fmod(cam.x * 0.5, 300.0)
	for i in 8:
		var gx := float(i) * 300.0 - par2 + 80.0
		var gy := vs.y * (0.2 + 0.5 * fmod(float(i) * 0.37 + floor(cam.x * 0.5 / 300.0) * 0.21, 1.0))
		var a := 0.35 + 0.25 * sin(_t * 2.0 + float(i))
		draw_circle(Vector2(gx, gy), 10.0, Color(glow.r, glow.g, glow.b, a * 0.35))
		draw_circle(Vector2(gx, gy), 3.5, Color(glow.r, glow.g, glow.b, a))
	# The world (tunnel)
	draw_set_transform(-cam, 0.0, Vector2.ONE)
	var x0 := cam.x - 60.0
	var x1 := cam.x + vs.x + 60.0
	_draw_rock_bands(x0, x1, rock, glow, vs)
	for o in _obs:
		var ox := float(o["x"])
		if ox > x1 or ox + float(o["w"]) < x0:
			continue
		_draw_obstacle(o, rock, glow)
	for i in _checks.size():
		_draw_crystal(float(_checks[i]), i <= _check_i, glow)
	_draw_exit()
	for d in _dust:
		draw_circle(d[0], 3.0, Color(glow.r, glow.g, glow.b, clampf(float(d[2]) * 2.0, 0.0, 1.0)))
	_draw_hero()
	draw_set_transform(Vector2.ZERO, 0.0, Vector2.ONE)


## Floor and roof: rock polygons following the tunnel, cut at the chasms.
func _draw_rock_bands(x0: float, x1: float, rock: Color, glow: Color, vs: Vector2) -> void:
	var step := 40.0
	var xs := floorf(x0 / step) * step
	var floor_pts := PackedVector2Array()
	var roof := PackedVector2Array()
	var x := xs
	var cuts: Array = []
	for o in _obs:
		if o["kind"] == "gap" and float(o["x"]) < x1 and float(o["x"]) + float(o["w"]) > x0:
			cuts.append([float(o["x"]), float(o["x"]) + float(o["w"])])
	# Roof (one polygon)
	while x <= x1 + step:
		var fy := floor_y(x)
		roof.append(Vector2(x, fy - TUNNEL_H - 18.0 * sin(x / 170.0) - 30.0 * sin(x / 610.0)))
		x += step
	roof.append(Vector2(x1 + step, floor_y(x1) - TUNNEL_H - 900.0))
	roof.append(Vector2(xs, floor_y(xs) - TUNNEL_H - 900.0))
	draw_colored_polygon(roof, rock.darkened(0.25))
	# Stalactites on the roof
	var sx := floorf(x0 / 230.0) * 230.0
	while sx < x1:
		var ry := floor_y(sx) - TUNNEL_H - 18.0 * sin(sx / 170.0) - 30.0 * sin(sx / 610.0)
		var ln := 30.0 + 40.0 * fmod(absf(sin(sx * 0.013)), 1.0)
		draw_colored_polygon(PackedVector2Array([Vector2(sx - 16, ry - 4), Vector2(sx + 16, ry - 4), Vector2(sx + 2, ry + ln)]), rock.darkened(0.25))
		sx += 230.0
	# Floor pieces between chasms
	var seg_start := x0
	var pieces: Array = []
	cuts.sort_custom(func(a: Array, b: Array) -> bool: return a[0] < b[0])
	for c in cuts:
		pieces.append([seg_start, c[0]])
		seg_start = c[1]
	pieces.append([seg_start, x1])
	for p in pieces:
		var a := float(p[0])
		var b := float(p[1])
		if b - a < 1.0:
			continue
		floor_pts = PackedVector2Array()
		var xx := a
		while xx < b:
			floor_pts.append(Vector2(xx, floor_y(xx)))
			xx += step
		floor_pts.append(Vector2(b, floor_y(b)))
		var edge := floor_pts.duplicate()
		floor_pts.append(Vector2(b, floor_y(b) + vs.y))
		floor_pts.append(Vector2(a, floor_y(a) + vs.y))
		draw_colored_polygon(floor_pts, rock)
		draw_polyline(edge, rock.lightened(0.25), 4.0)
	# Chasm glow
	for c in cuts:
		var mx := (float(c[0]) + float(c[1])) * 0.5
		draw_circle(Vector2(mx, floor_y(mx) + 260.0), (float(c[1]) - float(c[0])) * 0.6, Color(glow.r, glow.g, glow.b, 0.08))


func _draw_obstacle(o: Dictionary, rock: Color, glow: Color) -> void:
	var ox := float(o["x"])
	var w := float(o["w"])
	var oh := float(o["h"])
	var base := floor_y(ox + w * 0.5)
	match String(o["kind"]):
		"rock":
			var pts := PackedVector2Array([Vector2(ox - 6, floor_y(ox) + 6), Vector2(ox + w * 0.1, base - oh * 0.7), Vector2(ox + w * 0.35, base - oh),
				Vector2(ox + w * 0.7, base - oh * 0.92), Vector2(ox + w + 4, base - oh * 0.35), Vector2(ox + w + 8, floor_y(ox + w) + 6)])
			draw_colored_polygon(pts, rock.lightened(0.12))
			draw_polyline(pts, Color(0, 0, 0, 0.6), 3.0)
			draw_line(Vector2(ox + w * 0.3, base - oh * 0.8), Vector2(ox + w * 0.55, base - oh * 0.5), rock.lightened(0.3), 2.0)
		"spikes":
			var n := maxi(int(w / 26.0), 2)
			for i in n:
				var sx := ox + w * float(i) / float(n)
				var sw := w / float(n)
				var fy := floor_y(sx + sw * 0.5)
				var tri := PackedVector2Array([Vector2(sx, fy + 4), Vector2(sx + sw * 0.5, fy - oh), Vector2(sx + sw, fy + 4)])
				draw_colored_polygon(tri, rock.lightened(0.35))
				draw_polyline(PackedVector2Array([tri[0], tri[1], tri[2]]), Color(0, 0, 0, 0.7), 2.5)
		"ceil":
			# A slab hanging from the roof down to CEIL_GAP above the floor, teeth at its bottom
			var l := floor_y(ox)
			var r := floor_y(ox + w)
			var slab := PackedVector2Array([Vector2(ox, l - TUNNEL_H - 40.0), Vector2(ox + w, r - TUNNEL_H - 40.0), Vector2(ox + w, r - oh), Vector2(ox, l - oh)])
			draw_colored_polygon(slab, rock.darkened(0.05))
			draw_polyline(PackedVector2Array([slab[2], slab[3]]), Color(glow.r, glow.g, glow.b, 0.5 + 0.3 * sin(_t * 6.0)), 3.0)
			var n2 := maxi(int(w / 34.0), 2)
			for i in n2:
				var tx := ox + w * (float(i) + 0.5) / float(n2)
				var ty := floor_y(tx) - oh
				draw_colored_polygon(PackedVector2Array([Vector2(tx - 10, ty - 2), Vector2(tx + 10, ty - 2), Vector2(tx, ty + 14)]), rock.darkened(0.05))


func _draw_crystal(x: float, lit: bool, glow: Color) -> void:
	var fy := floor_y(x)
	var a := 0.9 if lit else 0.35
	draw_circle(Vector2(x, fy - 60.0), 46.0 + 6.0 * sin(_t * 3.0), Color(glow.r, glow.g, glow.b, 0.12 * a + (0.12 if lit else 0.0)))
	var c := PackedVector2Array([Vector2(x, fy - 120.0), Vector2(x + 20, fy - 60.0), Vector2(x, fy), Vector2(x - 20, fy - 60.0)])
	draw_colored_polygon(c, Color(glow.r, glow.g, glow.b, a))
	draw_polyline(PackedVector2Array([c[0], c[1], c[2], c[3], c[0]]), Color(1, 1, 1, 0.6 * a), 2.0)


func _draw_exit() -> void:
	var fy := floor_y(_len)
	draw_circle(Vector2(_len + 200.0, fy - 200.0), 320.0, Color(1.0, 0.95, 0.8, 0.10))
	draw_circle(Vector2(_len + 200.0, fy - 200.0), 170.0, Color(1.0, 0.95, 0.8, 0.22))


func _draw_hero() -> void:
	var fy := floor_y(px)
	var slope_a := atan(SLOPE + (70.0 / 950.0) * cos(px / 950.0) + (26.0 / 330.0) * cos(px / 330.0 + 1.3))
	var pos := Vector2(px, fy - h)
	var rot := slope_a - 0.22                                # Leaning back: sliding
	var sc := Vector2(0.95, 0.95)
	if _crash >= 0.0:
		rot = _crash * 9.0
		pos.y -= 30.0 * sin(clampf(_crash, 0.0, 1.0) * PI)
	elif ducking:
		rot = slope_a - 1.25                                 # Flat on the back
		pos.y += 6.0
	elif h > 0.5:
		rot = -0.15 + clampf(-vy / 3000.0, -0.3, 0.3)
	if _invuln > 0.0 and fmod(_t, 0.16) < 0.08:
		return                                               # Blink after a restart
	draw_set_transform(pos - _cam, rot, sc)
	StoryLevels.hero_art(hero).call("draw_portrait", self, _t * 0.3)
	draw_set_transform(-_cam, 0.0, Vector2.ONE)


# ============================================================
# UI
# ============================================================
func _build_ui() -> void:
	_ui = CanvasLayer.new()
	_ui.layer = 10
	add_child(_ui)
	_hud = Control.new()
	_hud.set_anchors_and_offsets_preset(Control.PRESET_FULL_RECT)
	_hud.mouse_filter = Control.MOUSE_FILTER_IGNORE
	_ui.add_child(_hud)
	_hud.draw.connect(_draw_hud)
	var box := VBoxContainer.new()
	box.set_anchors_and_offsets_preset(Control.PRESET_CENTER)
	box.offset_left = -600
	box.offset_right = 600
	box.offset_top = -170
	box.offset_bottom = -40
	box.mouse_filter = Control.MOUSE_FILTER_IGNORE
	_ui.add_child(box)
	_banner = UiStyle.label("", 46, Color(1.0, 0.85, 0.5), 10)
	box.add_child(_banner)
	_sub = UiStyle.label("", 22, Color(0.95, 0.92, 0.85), 4)
	box.add_child(_sub)


func _show(a: String, b: String) -> void:
	_banner.text = a
	_sub.text = b
	for l in [_banner, _sub]:
		l.modulate.a = 0.0
		create_tween().tween_property(l, "modulate:a", 1.0, 0.3)


func _hide() -> void:
	for l in [_banner, _sub]:
		create_tween().tween_property(l, "modulate:a", 0.0, 0.3)


## Progress bar (crystals marked) + crashes.
func _draw_hud() -> void:
	var c := _hud
	var w := minf(c.size.x - 200.0, 700.0)
	var r := Rect2(Vector2((c.size.x - w) * 0.5, 22.0), Vector2(w, 12.0))
	var glow: Color = _cfg["glow"]
	c.draw_rect(r.grow(3.0), Color(0, 0, 0, 0.6))
	c.draw_rect(Rect2(r.position, Vector2(r.size.x * clampf(px / _len, 0.0, 1.0), r.size.y)), glow)
	for i in _checks.size():
		var cx := r.position.x + r.size.x * float(_checks[i]) / _len
		c.draw_colored_polygon(PackedVector2Array([Vector2(cx, r.position.y - 8), Vector2(cx + 6, r.get_center().y), Vector2(cx, r.end.y + 8), Vector2(cx - 6, r.get_center().y)]),
			glow if i <= _check_i else Color(0.4, 0.4, 0.45))
	FighterArt.label(c, Vector2(c.size.x * 0.5, 62.0), "%s  -  LEVEL %d     CRASHES: %d" % [StoryLevels.part_name(StoryLevels.CAVES_PART), level_n, hits], 16, Color(0.9, 0.88, 0.82))
