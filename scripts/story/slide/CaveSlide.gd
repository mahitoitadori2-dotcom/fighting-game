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
##
## THE MAGMA RUN (Story part 10, levels 68-70) uses the same slide with more:
##   J / ATTACK          smash the cracked basalt WALLS in the way (you cannot jump them)
##   A LAVA FLOOD with a Kharleming swarm HUNTS you from behind. A crash no longer sends you back:
##   you tumble and lose ground. If the flood CATCHES you, you restart at the last crystal.
##   Level 70 stops halfway: 3 WAVES of Craterum enemies (a normal Story fight in StoryArena),
##   then back here for the last slide.
## Every slide level ends at a WHITE WALL (the screen goes white = level clear).

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
	# ----- THE MAGMA RUN (hunted; walls to smash) -----
	4: {"len": 36000.0, "speed": 640.0, "sky": [Color(0.12, 0.03, 0.02), Color(0.30, 0.09, 0.03)], "rock": Color(0.16, 0.10, 0.09),
		"glow": Color(1.0, 0.5, 0.15), "music": "story_magma", "run": true, "pool": ["rock", "wall", "gap", "ceil", "wall", "spikes", "double"]},
	5: {"len": 42000.0, "speed": 690.0, "sky": [Color(0.05, 0.06, 0.08), Color(0.20, 0.08, 0.05)], "rock": Color(0.14, 0.13, 0.15),
		"glow": Color(0.35, 1.0, 0.95), "music": "story_wreck", "run": true, "pool": ["rock", "wall", "gap", "ceil", "wall_ceil", "rock_ceil", "gap", "wall"]},
	6: {"len": 46000.0, "speed": 720.0, "sky": [Color(0.14, 0.02, 0.02), Color(0.38, 0.10, 0.02)], "rock": Color(0.12, 0.08, 0.08),
		"glow": Color(1.0, 0.4, 0.1), "music": "boss_kharleming_lord", "run": true, "fight": true,
		"pool": ["rock", "wall", "gap", "ceil", "wall_ceil", "gap_ceil", "rock_ceil", "wall", "long_ceil"]},
	# Level 80, phase 3: sliding down through the mountain - THE STORM chases you (like the Magma Run).
	11: {"len": 30000.0, "speed": 660.0, "sky": [Color(0.04, 0.05, 0.09), Color(0.10, 0.12, 0.20)], "rock": Color(0.16, 0.16, 0.20),
		"glow": Color(0.6, 0.8, 1.0), "music": "boss_storm_finger", "run": true, "storm": true,
		"pool": ["rock", "wall", "gap", "ceil", "spikes", "rock_ceil", "wall"]},
}
## THE ROAD TO PEACE (Story part 12, levels 72-74): RUN up the bridge from Orbis Terrarum. No S.
## The Storm throws particles: jump them or hit them (J). The Architect carries a SWORD here
## (green blade, silver crossguard and handle) - only on the bridge.
const ROAD_TIERS := {
	7: {"len": 34000.0, "speed": 600.0, "sky": [Color(0.10, 0.11, 0.18), Color(0.28, 0.30, 0.42)], "rock": Color(0.85, 0.78, 0.55),
		"glow": Color(1.0, 0.92, 0.6), "music": "story_road", "road": true, "pool": ["orb", "orb", "spark", "orb"]},
	8: {"len": 40000.0, "speed": 650.0, "sky": [Color(0.08, 0.08, 0.15), Color(0.22, 0.24, 0.36)], "rock": Color(0.85, 0.78, 0.55),
		"glow": Color(1.0, 0.92, 0.6), "music": "story_road", "road": true, "pool": ["orb", "spark", "pair", "spark", "orb"]},
	9: {"len": 46000.0, "speed": 700.0, "sky": [Color(0.05, 0.05, 0.10), Color(0.18, 0.18, 0.30)], "rock": Color(0.85, 0.78, 0.55),
		"glow": Color(1.0, 0.92, 0.6), "music": "boss_storm_finger", "road": true, "pool": ["orb", "spark", "pair", "mix", "spark", "mix"]},
	# Level 80, phase 1: RUN DOWN the bridge as it breaks apart (gaps!) - with the other two.
	10: {"len": 26000.0, "speed": 660.0, "sky": [Color(0.03, 0.03, 0.07), Color(0.12, 0.12, 0.22)], "rock": Color(0.85, 0.78, 0.55),
		"glow": Color(0.8, 0.9, 1.0), "music": "boss_storm_finger", "road": true, "down": true, "gaps": true,
		"pool": ["orb", "gap", "spark", "gap", "pair", "gap"]},
}
const ROAD_SLOPE := 0.10
const ATTACK_REACH := 170.0           # Smash a wall this close in front of you
const ATTACK_CD := 0.32
const HUNT_START := 1000.0            # The flood starts this far behind
const HUNT_MAX := 1500.0
const HUNT_SPEED := 0.93              # x the slide speed: clean sliding slowly pulls away
## Level 70: set by StoryManager after the 3 waves are beaten -> the slide resumes after the fight.
static var resume_after_fight := 0

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
var run_time := 0.0                   # Seconds of sliding (stops while paused): best time per cave
var _t := 0.0
var _cam := Vector2.ZERO
var _shake := 0.0
var _dust: Array = []                 # [pos, vel, life]
var _touch_duck := {}                 # touch index -> true (left half held)
var run := false                      # THE MAGMA RUN tier (walls + the hunt)
var road := false                     # THE ROAD TO PEACE tier (running up the bridge, storm particles)
var _parts: Array = []                # Road: {kind, x0, x, v, on, gone}
## Level 74 (the last bridge level): the OTHER hero runs with you - the one who chased the
## Enlightened One; he sent them to the bridge (lore by the user). "" = alone.
var partner := ""
var _partner_h := 0.0
var _reunion := false                 # Level 74: the reunion talk at the start
var _down := false                    # Level 80: running DOWN the breaking bridge
var _trainer_runs := false            # Level 80: the Trainer runs with you too
var gap := HUNT_START                 # How far behind the flood is
var caught := 0
var smashed := 0
var _atk_t := 0.0                     # Swing animation
var _atk_cd := 0.0
var _fight_x := -1.0                  # Level 70: the slide stops here for the waves
var _resumed := false
var _white := 0.0                     # The white wall: the screen fades to white

var _ui: CanvasLayer
var _hud: Control
var _banner: Label
var _sub: Label


func _ready() -> void:
	StoryProgress.load_progress()
	level_n = StoryProgress.current_level
	if level_n == StoryLevels.STORM_LEVEL:                    # Level 80: the bridge (phase 1) or the cave (phase 3)
		tier = 11 if OrbisTalk.storm_phase >= 3 else 10
	elif StoryLevels.colosseum_of(level_n) == StoryLevels.ROAD_PART:
		tier = clampi(level_n - StoryLevels.first_of(StoryLevels.ROAD_PART) + 7, 7, 9)
	elif StoryLevels.colosseum_of(level_n) == StoryLevels.RUN_PART:
		tier = clampi(level_n - StoryLevels.first_of(StoryLevels.RUN_PART) + 4, 4, 6)
	else:
		level_n = clampi(level_n, StoryLevels.first_of(StoryLevels.CAVES_PART), StoryLevels.last_of(StoryLevels.CAVES_PART))
		tier = clampi(level_n - StoryLevels.first_of(StoryLevels.CAVES_PART) + 1, 1, 3)
	hero = StoryLevels.hero_of(level_n)
	_cfg = ROAD_TIERS[tier] if ROAD_TIERS.has(tier) else TIERS[tier]
	_len = float(_cfg["len"])
	run = bool(_cfg.get("run", false))
	road = bool(_cfg.get("road", false))
	_down = bool(_cfg.get("down", false))
	if road:
		_build_road()
		if level_n == StoryLevels.last_of(StoryLevels.ROAD_PART):
			partner = "architect" if hero == "warrior" else "warrior"
			_reunion = true
		elif level_n == StoryLevels.STORM_LEVEL:
			partner = "architect" if hero == "warrior" else "warrior"
			_trainer_runs = true
	else:
		_build_layout()
	if bool(_cfg.get("fight", false)):
		_fight_x = float(_checks[1]) - 60.0
		if resume_after_fight == level_n:               # Back from the 3 waves: the last slide
			resume_after_fight = 0
			_resumed = true
			_check_i = 1
			px = float(_checks[1])
			gap = HUNT_START * 0.7
	_build_ui()
	SoundManager.play_music(String(_cfg["music"]))
	_intro()


# ============================================================
# LAYOUT (seeded: the same cave every time)
# ============================================================
func floor_y(x: float) -> float:
	if road:                                                     # The bridge climbs UP into the sky (level 80: runs DOWN)
		return (x if _down else -x) * ROAD_SLOPE + 18.0 * sin(x / 900.0)
	return x * SLOPE + 70.0 * sin(x / 950.0) + 26.0 * sin(x / 330.0 + 1.3)


## THE ROAD TO PEACE: no obstacles on the bridge itself - the STORM throws PARTICLES at you.
##   "orb"     a ball of storm rolling down the bridge          jump it or hit it
##   "spark"   a shard of lightning flying at head height       hit it (or jump high over it)
##   "pair"    two orbs close together
##   "mix"     a spark right after an orb
func _build_road() -> void:
	var rng := RandomNumberGenerator.new()
	rng.seed = 9100 + tier * 77
	var v := float(_cfg["speed"])
	_checks = [_len * 0.25, _len * 0.5, _len * 0.75]
	var pool: Array = _cfg["pool"]
	var x := 1800.0
	var step := 0
	while x < _len - 1400.0:
		var near := false
		for c in _checks:
			if x > c - 400.0 and x < c + 900.0:
				near = true
		if near:
			x += 400.0
			continue
		var kind: String = pool[rng.randi() % pool.size()] if step > 1 else ["orb", "spark"][step]
		step += 1
		var pv := rng.randf_range(240.0, 380.0) + 30.0 * float(tier - 7)
		match kind:
			"orb", "spark":
				_parts.append(_particle(kind, x, pv))
			"gap":                                          # Level 80: the bridge has broken here - jump it
				_obs.append({"kind": "gap", "x": x, "w": rng.randf_range(170.0, 230.0), "h": 0.0})
			"pair":
				_parts.append(_particle("orb", x, pv))
				_parts.append(_particle("orb", x + (v + pv) * 0.75, pv))
			"mix":
				_parts.append(_particle("orb", x, pv))
				_parts.append(_particle("spark", x + (v + pv) * 0.7, pv))
		x += (v + pv) * rng.randf_range(1.05, 1.6) * (0.85 if tier == 9 else 1.0) + (v + pv) * (0.75 if kind == "pair" or kind == "mix" else 0.0)


func _particle(kind: String, x: float, pv: float) -> Dictionary:
	return {"kind": kind, "x0": x, "x": x, "v": pv, "on": false, "gone": false}


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
		var kind: String = pool[rng.randi() % pool.size()] if step > 2 else (["wall", "rock", "gap"] if run else ["rock", "gap", "ceil" if tier > 1 else "rock"])[step]
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
			"wall":                                          # Cracked basalt: SMASH it (ATTACK)
				_obs.append({"kind": "wall", "x": x, "w": 56.0, "h": TUNNEL_H, "broken": false})
				end = x + 56.0
			"wall_ceil":                                     # Smash a wall, then duck right away
				_obs.append({"kind": "wall", "x": x, "w": 56.0, "h": TUNNEL_H, "broken": false})
				var c3 := x + v * 0.9
				_obs.append({"kind": "ceil", "x": c3, "w": 240.0, "h": CEIL_GAP})
				end = c3 + 240.0
		x = end + v * rng.randf_range(0.95, 1.55) * (0.85 if tier == 3 or tier == 6 else 1.0)


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
	var line := "No enemies.  Just slide."
	if road:
		keys = "W  -  JUMP        J  -  HIT"
		line = "Run up the bridge. The Storm throws everything it has at you."
		if _down:
			title = "THE BREAKING BRIDGE"
			line = "RUN! The bridge is falling apart - jump the gaps!"
	if bool(_cfg.get("storm", false)):
		title = "INTO THE MOUNTAIN"
	if run:
		keys += "        J  -  SMASH WALLS"
		line = "The STORM followed you into the mountain.  Do not slow down." if bool(_cfg.get("storm", false)) else "The lava and the Kharlemings are HUNTING you.  Do not slow down."
		if _resumed:
			title = "THE LAST SLIDE"
			line = "They keep coming.  Reach the white wall!"
	_show("LEVEL %d:  %s" % [level_n, title], keys + "\n" + line)
	await get_tree().create_timer(2.8).timeout
	_hide()
	if _reunion:                                             # Level 74: the other hero catches up
		var lines: Array = StoryDialogue.ROAD_REUNION.duplicate(true)
		for l in lines:
			l[0] = hero if String(l[0]) == "H" else partner
		var box := DialogueBox.play(self, lines)
		await box.finished
	_started = true


func _finish() -> void:
	_done = true
	# The WHITE WALL: slide into the light, the screen goes white
	SoundManager.play_sfx("holy")
	var tw := create_tween()
	tw.tween_property(self, "_white", 1.0, 0.9)
	await tw.finished
	if level_n == StoryLevels.STORM_LEVEL:                   # Level 80: on to the next scene
		OrbisTalk.storm_phase = 2 if tier == 10 else 4
		StoryProgress.current_level = level_n
		if StoryManager.autoplay:
			print("CAVES autoplay: level 80 -> phase %d" % OrbisTalk.storm_phase)
		get_tree().change_scene_to_file("res://scenes/OrbisTalk.tscn" if tier == 10 else StoryManager.ARENA_SCENE)
		return
	SoundManager.play_sfx("count_go")
	var flawless := hits == 0
	var old := StoryProgress.best_time(level_n)
	var best := ""
	if StoryProgress.record_time(level_n, run_time):
		best = "     NEW BEST TIME!" if old > 0.0 else ""
	else:
		best = "     BEST %s" % StoryManager.time_text(old)
	_show("BRIDGE CLIMBED!" if road else ("TUNNEL ESCAPED!" if run else "CAVE CLEARED!"), "TIME %s     %s%s%s\nProgress saved" % [StoryManager.time_text(run_time),
		"NOT A SCRATCH!" if flawless else "CRASHES %d" % hits, ("     CAUGHT %d" % caught) if run else "", best])
	StoryProgress.complete_level(level_n)
	if road:
		var kr := tier - 6
		Achievements.unlock("road_%d" % kr)
		if flawless:
			Achievements.unlock("road_flawless_%d" % kr)
		if smashed >= 40:
			Achievements.unlock("road_swordsman")
		if level_n == StoryLevels.last_of(StoryLevels.ROAD_PART):
			Achievements.unlock("col_%d" % StoryLevels.ROAD_PART)
	elif run:
		var k := tier - 3
		Achievements.unlock("run_%d" % k)
		if flawless and caught == 0:
			Achievements.unlock("run_flawless_%d" % k)
		if caught >= 5:
			Achievements.unlock("run_caught")
		if level_n == StoryLevels.last_of(StoryLevels.RUN_PART):
			Achievements.unlock("col_%d" % StoryLevels.RUN_PART)
	else:
		Achievements.unlock("cave_%d" % tier)
		if flawless:
			Achievements.unlock("cave_flawless_%d" % tier)
			if StoryDifficulty.is_hard():
				Achievements.unlock("hard_caves")
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
	if run:
		# The Magma Run: you get up WHERE you crashed (and lost ground to the flood)
		for o in _obs:
			if o["kind"] == "gap" and px > float(o["x"]) - HALF_W and px < float(o["x"]) + float(o["w"]) + HALF_W:
				px = float(o["x"]) + float(o["w"]) + HALF_W + 4.0
		h = 0.0
		vy = 0.0
		speed = float(_cfg["speed"]) * 0.5
		ducking = false
		_invuln = 1.0
		SoundManager.play_sfx("spawn", -6.0)
		return
	px = float(_checks[_check_i]) if _check_i >= 0 else 300.0
	h = 0.0
	vy = 0.0
	speed = float(_cfg["speed"]) * 0.5
	ducking = false
	_invuln = 1.0
	if road:                                                     # The Storm throws them all again
		for p in _parts:
			if float(p["x0"]) > px:
				p["x"] = p["x0"]
				p["on"] = false
				p["gone"] = false
	SoundManager.play_sfx("spawn", -6.0)


# ============================================================
# INPUT
# ============================================================
func _unhandled_input(event: InputEvent) -> void:
	if event.is_action_pressed("jump"):
		_jump_buf = BUFFER
	if event.is_action_pressed("crouch"):
		_press_down()
	if event.is_action_pressed("punch"):
		_attack()
	var st := event as InputEventScreenTouch
	if st != null:
		var left := st.position.x < get_viewport_rect().size.x * 0.5
		if st.pressed and (run or road) and st.position.y < get_viewport_rect().size.y * 0.4:
			_attack()                                      # Touch: the top of the screen = SMASH
		elif st.pressed:
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
	if tier < 2 or road or not _started or _crash >= 0.0:          # (The Road to Peace: no S)
		return
	if h > 0.5:
		vy = DIVE_V
		SoundManager.play_sfx("whoosh", -8.0)
	else:
		_duck_t = 0.35
		SoundManager.play_sfx("whoosh", -10.0)


## J / ATTACK (The Magma Run): smash the first cracked wall right in front of you.
func _attack() -> void:
	if not (run or road) or not _started or _crash >= 0.0 or _done or _atk_cd > 0.0:
		return
	_atk_cd = ATTACK_CD
	_atk_t = 0.22
	SoundManager.play_sfx("sword_slash" if road else "swing", -4.0)
	if road:                                                     # Cut the first storm particle in reach
		for p in _parts:
			if bool(p["gone"]) or not bool(p["on"]):
				continue
			var d := float(p["x"]) - px
			if d > -HALF_W - 20.0 and d < ATTACK_REACH:
				p["gone"] = true
				smashed += 1
				_shake = 5.0
				SoundManager.play_sfx("spark", -4.0)
				var py := floor_y(float(p["x"])) - _part_h(p)
				for i in 14:
					_dust.append([Vector2(float(p["x"]), py), Vector2(randf_range(-300, 300), randf_range(-360, 160)), 0.6])
				return
		return
	for o in _obs:
		if o["kind"] != "wall" or bool(o["broken"]):
			continue
		var d := float(o["x"]) - px
		if d > ATTACK_REACH:
			break
		if d > -HALF_W - float(o["w"]):
			o["broken"] = true
			smashed += 1
			_shake = 8.0
			SoundManager.play_sfx("stone")
			SoundManager.play_sfx("explosion", -10.0)
			var wx := float(o["x"]) + 28.0
			for i in 18:
				_dust.append([Vector2(wx, floor_y(wx) - randf_range(20.0, TUNNEL_H - 40.0)), Vector2(randf_range(80, 520), randf_range(-420, 120)), 0.8])
			return


## The flood caught you: restart at the last crystal, the flood far behind again.
func _caught() -> void:
	caught += 1
	_crash = -1.0
	_shake = 18.0
	SoundManager.play_sfx("roar")
	SoundManager.play_sfx("flame", -4.0)
	_show("CAUGHT!", "Back to the last crystal.")
	get_tree().create_timer(1.4).timeout.connect(_hide)
	var back := float(_checks[_check_i]) if _check_i >= 0 else 300.0
	if _resumed and back < float(_checks[1]):
		back = float(_checks[1])
	px = back
	h = 0.0
	vy = 0.0
	speed = float(_cfg["speed"]) * 0.5
	ducking = false
	_invuln = 1.2
	gap = HUNT_START
	if StoryManager.autoplay:
		print("CAVES autoplay: CAUGHT at %d" % int(px))


## Level 70: the slide stops; the 3 waves are a normal Story fight (StoryArena).
func _stop_for_fight() -> void:
	_done = true
	SoundManager.stop_music()
	SoundManager.play_sfx("roar")
	_shake = 16.0
	_show("THEY CAUGHT UP!", "The tunnel opens into a cavern.  FIGHT!")
	if StoryManager.autoplay:
		print("CAVES autoplay: level %d stops for the waves" % level_n)
	await get_tree().create_timer(2.0).timeout
	StoryProgress.current_level = level_n
	get_tree().change_scene_to_file(StoryManager.ARENA_SCENE)


## Autoplay (tests only): looks ahead and presses the keys.
func _bot() -> void:
	var v := maxf(speed, 1.0)
	if road:
		for o in _obs:                                       # Level 80: jump the broken parts of the bridge
			var gd := float(o["x"]) - px
			if o["kind"] == "gap" and gd < 40.0 and gd > -20.0 and h <= 0.5:
				_jump_buf = BUFFER
		for p in _parts:
			if bool(p["gone"]) or not bool(p["on"]) or float(p["x"]) < px - HALF_W:
				continue
			var dist := float(p["x"]) - px
			var closing := v + float(p["v"])
			if p["kind"] == "spark" or int(float(p["x0"])) % 2 == 0:
				if dist < 130.0:
					_attack()
			elif dist < closing * 0.2 + 30.0 and h <= 0.5:
				_jump_buf = BUFFER
			return
		return
	for o in _obs:
		var ox := float(o["x"])
		var ow := float(o["w"])
		if ox + ow < px - HALF_W:
			continue
		var dist := ox - px
		if dist > v * 0.9:
			break
		match String(o["kind"]):
			"wall":
				if bool(o["broken"]):
					continue
				if dist < 120.0:
					_attack()
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
	_atk_t = maxf(_atk_t - delta, 0.0)
	_atk_cd = maxf(_atk_cd - delta, 0.0)
	for d in _dust:
		d[0] += d[1] * delta
		d[1].y += 900.0 * delta
		d[2] -= delta
	_dust = _dust.filter(func(d: Array) -> bool: return d[2] > 0.0)
	if _started and not _done:
		run_time += delta
		if _crash >= 0.0:
			_crash += delta
			px += speed * 0.25 * delta
			speed = lerpf(speed, 0.0, delta * 3.0)
			if _crash > 1.0:
				_respawn()
		else:
			_run(delta)
		if run and not _done:
			_hunt(delta)
	var target := Vector2(px - get_viewport_rect().size.x * 0.32, floor_y(px) - get_viewport_rect().size.y * 0.60)
	_cam = target if _t < 0.1 else _cam.lerp(target, minf(delta * 6.0, 1.0))
	queue_redraw()
	_hud.queue_redraw()


## THE ROAD TO PEACE: the Storm's particles fly down the bridge at you.
func _road_particles(delta: float, top: float) -> void:
	for p in _parts:
		if bool(p["gone"]):
			continue
		var x := float(p["x"])
		if not bool(p["on"]):
			if x - px < 1500.0:
				p["on"] = true
				SoundManager.play_sfx("whoosh", -14.0)
			continue
		x -= float(p["v"]) * delta
		p["x"] = x
		if x < px - 900.0:
			p["gone"] = true
			continue
		if absf(x - px) > HALF_W + 22.0:
			continue
		var ph := _part_h(p)
		var r := 24.0 if p["kind"] == "orb" else 20.0
		if ph + r > h + 4.0 and ph - r < top - 4.0:                 # Overlaps your body
			p["gone"] = true
			_crash_now(String(p["kind"]))


## Height of a particle's centre above the bridge.
func _part_h(p: Dictionary) -> float:
	return 26.0 if p["kind"] == "orb" else 92.0


## The flood behind you: it moves a little slower than a clean slide. Crashes let it close in.
func _hunt(delta: float) -> void:
	var top := float(_cfg["speed"]) * StoryDifficulty.cave_speed() * (1.0 + 0.10 * px / _len)
	var moved := speed if _crash < 0.0 else speed * 0.25
	gap = minf(gap + (moved - top * HUNT_SPEED) * delta, HUNT_MAX)
	if gap <= 0.0:
		_caught()


func _run(delta: float) -> void:
	if StoryManager.autoplay:
		_bot()
	var top_speed := float(_cfg["speed"]) * StoryDifficulty.cave_speed() * (1.0 + 0.10 * px / _len)
	speed = move_toward(speed, top_speed, 500.0 * delta)
	px += speed * delta
	var grounded := h <= 0.0 and not _in_gap(px)
	_air_t = 0.0 if grounded else _air_t + delta
	ducking = tier >= 2 and not road and grounded and (_duck_t > 0.0 or _down_held())
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
			"wall":
				if not bool(o["broken"]):
					_crash_now("wall")
			"rock", "spikes":
				if h < float(o["h"]) - 6.0:
					_crash_now(String(o["kind"]))
			"ceil":
				if top > float(o["h"]) + 4.0:
					_crash_now("ceil")
	if road:
		_road_particles(delta, top)
	# Crystals (checkpoints)
	while _check_i + 1 < _checks.size() and px >= float(_checks[_check_i + 1]):
		_check_i += 1
		SoundManager.play_sfx("holy", -6.0)
	if _fight_x > 0.0 and not _resumed and px >= _fight_x:
		_stop_for_fight()
		return
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
	if road:
		_draw_road(vs, cam)
		return
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
	if run:
		_draw_hunters(x0)
	draw_set_transform(Vector2.ZERO, 0.0, Vector2.ONE)


## THE ROAD TO PEACE: the storm all around, Orbis Terrarum glowing above, the bridge of light.
func _draw_road(vs: Vector2, cam: Vector2) -> void:
	var glow: Color = _cfg["glow"]
	var prog := clampf(px / _len, 0.0, 1.0)
	# Orbis Terrarum: an island in the sky, top right, closer the further you run
	var ip := Vector2(vs.x * 0.78, vs.y * (0.22 - 0.06 * prog))
	var isz := 70.0 + 170.0 * prog
	draw_circle(ip, isz * 1.6, Color(1.0, 0.95, 0.75, 0.10 + 0.08 * prog))
	draw_colored_polygon(PackedVector2Array([ip + Vector2(-isz, 0), ip + Vector2(isz, 0), ip + Vector2(isz * 0.3, isz * 0.7), ip + Vector2(-isz * 0.4, isz * 0.6)]), Color(0.36, 0.28, 0.24))
	draw_colored_polygon(EnemyArt.ellipse_points(ip + Vector2(0, -isz * 0.08), isz, isz * 0.22, 18), Color(0.38, 0.65, 0.34))
	draw_rect(Rect2(ip + Vector2(-isz * 0.12, -isz * 0.42), Vector2(isz * 0.24, isz * 0.34)), Color(0.55, 0.42, 0.28))   # The hut
	# Storm clouds (two parallax layers) + lightning
	for layer in 2:
		var spd := 0.15 + 0.2 * float(layer)
		var par := fmod(cam.x * spd, 260.0)
		for i in 8:
			var cx := float(i) * 260.0 - par
			var cy := vs.y * (0.08 + 0.75 * float(layer)) + 30.0 * sin(float(i) * 1.7 + floor(cam.x * spd / 260.0))
			draw_circle(Vector2(cx, cy), 120.0 + 30.0 * float(layer), Color(0.14, 0.15, 0.24, 0.75 - 0.15 * float(layer)))
	if fmod(_t * 1.3, 3.0) < 0.12:
		var lx := vs.x * fmod(_t * 0.37, 1.0)
		draw_rect(Rect2(Vector2.ZERO, vs), Color(0.8, 0.85, 1.0, 0.10))
		draw_polyline(PackedVector2Array([Vector2(lx, 0), Vector2(lx + 30, vs.y * 0.15), Vector2(lx - 10, vs.y * 0.3), Vector2(lx + 25, vs.y * 0.45)]), Color(0.9, 0.95, 1.0), 3.0)
	# The world: the bridge
	draw_set_transform(-cam, 0.0, Vector2.ONE)
	var x0 := cam.x - 60.0
	var x1 := cam.x + vs.x + 60.0
	# The deck, in pieces between the broken gaps (level 80)
	var cuts: Array = []
	for o in _obs:
		if o["kind"] == "gap" and float(o["x"]) < x1 and float(o["x"]) + float(o["w"]) > x0:
			cuts.append([float(o["x"]), float(o["x"]) + float(o["w"])])
	var pieces: Array = []
	var seg := x0
	for cc in cuts:
		pieces.append([seg, float(cc[0])])
		seg = float(cc[1])
	pieces.append([seg, x1 + 40.0])
	for pc in pieces:
		var a := float(pc[0])
		var b := float(pc[1])
		if b - a < 2.0:
			continue
		var top := PackedVector2Array()
		var xx := a
		while xx < b:
			top.append(Vector2(xx, floor_y(xx)))
			xx += 40.0
		top.append(Vector2(b, floor_y(b)))
		var deck := top.duplicate()
		for i in range(top.size() - 1, -1, -1):
			deck.append(top[i] + Vector2(0, 34))
		draw_colored_polygon(deck, Color(0.92, 0.84, 0.58))
		draw_polyline(top, Color(1.0, 0.98, 0.85), 4.0)
	for cc in cuts:                                             # Planks falling into the Storm below
		for k in 3:
			var fx := float(cc[0]) + (float(cc[1]) - float(cc[0])) * (0.25 + 0.25 * float(k))
			var fy := floor_y(fx) + 60.0 + fmod(_t * 120.0 + float(k) * 70.0, 300.0)
			draw_line(Vector2(fx - 18, fy), Vector2(fx + 18, fy + 6), Color(0.80, 0.70, 0.45, 0.8), 6.0)
	var bx := floorf(x0 / 90.0) * 90.0                         # Planks + glowing posts of the rail
	while bx < x1:
		var fy := floor_y(bx)
		draw_line(Vector2(bx, fy + 2), Vector2(bx, fy + 32), Color(0.70, 0.60, 0.38), 3.0)
		if int(bx / 90.0) % 4 == 0:
			draw_line(Vector2(bx, fy), Vector2(bx, fy - 46), Color(0.85, 0.75, 0.48), 5.0)
			draw_circle(Vector2(bx, fy - 50), 6.0, Color(1.0, 0.95, 0.7, 0.8))
		bx += 90.0
	for i in _checks.size():
		_draw_crystal(float(_checks[i]), i <= _check_i, glow)
	_draw_exit()
	for p in _parts:
		if bool(p["gone"]) or not bool(p["on"]):
			continue
		var ppx := float(p["x"])
		if ppx < x0 or ppx > x1:
			continue
		_draw_particle(p, Vector2(ppx, floor_y(ppx) - _part_h(p)))
	for d in _dust:
		draw_circle(d[0], 3.0, Color(0.85, 0.92, 1.0, clampf(float(d[2]) * 2.0, 0.0, 1.0)))
	if partner != "" and _started:                           # The other hero, running right behind you
		_partner_h = lerpf(_partner_h, maxf(h, 0.0), minf(get_process_delta_time() * 7.0, 1.0))
		var qx := px - 150.0
		var qp := Vector2(qx, floor_y(qx) - _partner_h - absf(sin(_t * 13.0 + 1.0)) * 6.0)
		var lean := atan(ROAD_SLOPE if _down else -ROAD_SLOPE) + 0.1
		draw_set_transform(qp - _cam, lean, Vector2(0.9, 0.9))
		StoryLevels.hero_art(partner).call("draw_portrait", self, _t * 0.3)
		if partner == "architect":                           # The Architect's bridge sword
			_draw_road_sword(Vector2(18, -62), -0.9)
		draw_set_transform(-_cam, 0.0, Vector2.ONE)
		if _trainer_runs:                                    # Level 80: the Trainer, right behind them
			var tx := px - 290.0
			var tp := Vector2(tx, floor_y(tx) - _partner_h - absf(sin(_t * 12.0 + 2.0)) * 6.0)
			draw_set_transform(tp - _cam, lean, Vector2(0.9, 0.9))
			OrbisArt.trainer(self, _t, "upset")
			draw_set_transform(-_cam, 0.0, Vector2.ONE)
	_draw_hero()
	draw_set_transform(Vector2.ZERO, 0.0, Vector2.ONE)


func _draw_particle(p: Dictionary, c: Vector2) -> void:
	if p["kind"] == "orb":                                       # A rolling ball of storm
		draw_circle(c, 34.0, Color(0.5, 0.6, 1.0, 0.15))
		draw_circle(c, 24.0, Color(0, 0, 0))
		draw_circle(c, 21.0, Color(0.20, 0.22, 0.34))
		var a := -_t * 8.0
		for k in 3:
			var q := c + Vector2.from_angle(a + float(k) * 2.1) * 12.0
			draw_line(c, q, Color(0.8, 0.9, 1.0, 0.8), 2.0)
	else:                                                        # A shard of lightning flying at you
		draw_circle(c, 26.0, Color(0.7, 0.85, 1.0, 0.18))
		var pts := PackedVector2Array([c + Vector2(-26, -6), c + Vector2(-4, -12), c + Vector2(-8, -2), c + Vector2(26, 4), c + Vector2(2, 10), c + Vector2(6, 2)])
		draw_colored_polygon(pts, Color(0.85, 0.93, 1.0))
		draw_polyline(pts + PackedVector2Array([pts[0]]), Color(0.3, 0.45, 0.9), 2.0)
		draw_line(c + Vector2(26, 4), c + Vector2(70, 2), Color(0.8, 0.9, 1.0, 0.35), 3.0)      # Trail


## The Architect's sword (THE ROAD TO PEACE only): green blade, silver crossguard, silver handle.
func _draw_road_sword(hand: Vector2, ang: float) -> void:
	var dirv := Vector2.from_angle(ang)
	var side := dirv.orthogonal()
	var grip0 := hand - dirv * 12.0
	var guard := hand + dirv * 4.0
	var tip := guard + dirv * 62.0
	draw_line(grip0, guard, Color(0, 0, 0), 7.0)
	draw_line(grip0, guard, Color(0.80, 0.83, 0.88), 4.0)                    # Silver handle
	draw_circle(grip0, 4.0, Color(0.85, 0.88, 0.92))
	var blade := PackedVector2Array([guard + side * 5.0, tip + side * 2.0 - dirv * 10.0, tip, tip - side * 2.0 - dirv * 10.0, guard - side * 5.0])
	draw_colored_polygon(blade, Color(0.22, 0.86, 0.28))                       # Green blade
	draw_line(guard, tip - dirv * 6.0, Color(0.72, 1.0, 0.62), 1.5)
	draw_polyline(blade + PackedVector2Array([blade[0]]), Color(0, 0, 0), 2.0)
	draw_line(guard + side * 13.0, guard - side * 13.0, Color(0, 0, 0), 7.0)
	draw_line(guard + side * 12.0, guard - side * 12.0, Color(0.85, 0.88, 0.93), 4.0)   # Silver crossguard


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
		"wall":                                              # Cracked basalt from floor to roof (or rubble)
			var fy0 := floor_y(ox)
			if bool(o["broken"]):
				for i in 4:
					var rx := ox + float(i) * 18.0
					var rr := PackedVector2Array([Vector2(rx - 10, floor_y(rx) + 4), Vector2(rx - 4, floor_y(rx) - 16 - float(i % 2) * 10.0), Vector2(rx + 10, floor_y(rx) + 4)])
					draw_colored_polygon(rr, rock.lightened(0.1))
				return
			var top_y := fy0 - TUNNEL_H - 60.0
			for i in 3:                                      # Three basalt columns
				var cx := ox + float(i) * 19.0
				var col := Rect2(cx, top_y, 18.0, floor_y(cx + 9.0) - top_y + 4.0)
				draw_rect(col, Color(0.10, 0.09, 0.10).lightened(0.05 * float(i % 2)))
				draw_rect(col, Color(0, 0, 0), false, 2.5)
			# Glowing cracks: smash here
			var cr := PackedVector2Array([Vector2(ox + 6, fy0 - 300), Vector2(ox + 30, fy0 - 240), Vector2(ox + 18, fy0 - 170), Vector2(ox + 44, fy0 - 110), Vector2(ox + 26, fy0 - 40)])
			draw_polyline(cr, Color(glow.r, glow.g, glow.b, 0.6 + 0.3 * sin(_t * 8.0)), 3.0)
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


## The WHITE WALL at the end of every slide level: a wall of pure light across the tunnel.
func _draw_exit() -> void:
	var fy := floor_y(_len)
	var wx := _len + 60.0
	draw_circle(Vector2(wx, fy - 200.0), 420.0, Color(1.0, 1.0, 1.0, 0.08))
	draw_circle(Vector2(wx, fy - 200.0), 260.0, Color(1.0, 1.0, 1.0, 0.12))
	draw_rect(Rect2(wx, fy - TUNNEL_H - 200.0, 2400.0, TUNNEL_H + 600.0), Color(1, 1, 1))
	for i in 6:                                              # Soft glowing edge
		draw_rect(Rect2(wx - 12.0 * float(i + 1), fy - TUNNEL_H - 200.0, 12.0, TUNNEL_H + 600.0), Color(1, 1, 1, 0.5 - 0.08 * float(i)))


## THE MAGMA RUN: the lava flood + the Kharleming swarm, `gap` behind you.
func _draw_hunters(x0: float) -> void:
	var hx := px - gap
	if hx < x0 - 400.0:
		return
	var storm := bool(_cfg.get("storm", false))                 # Level 80: the STORM itself, not lava
	var lava := Color(0.16, 0.17, 0.27) if storm else Color(1.0, 0.42, 0.08)
	var hot := Color(0.75, 0.88, 1.0) if storm else Color(1.0, 0.85, 0.35)
	var front := PackedVector2Array()
	var back := hx - 2600.0
	front.append(Vector2(back, floor_y(back) + 200.0))
	for i in 15:                                             # The bubbling front, from the floor up to the roof
		var k := float(i) / 14.0
		var y := floor_y(hx) + 10.0 - k * (TUNNEL_H + 20.0)
		front.append(Vector2(hx + 40.0 * sin(k * 9.0 + _t * 7.0) + 30.0 * sin(k * 3.0 - _t * 3.0) - k * 80.0, y))
	front.append(Vector2(back, floor_y(back) - TUNNEL_H - 300.0))
	draw_colored_polygon(front, lava)
	var edge := front.slice(1, front.size() - 1)
	draw_polyline(edge, hot, 6.0)
	draw_circle(Vector2(hx, floor_y(hx) - TUNNEL_H * 0.5), 300.0, Color(0.6, 0.75, 1.0, 0.10) if storm else Color(1.0, 0.4, 0.1, 0.10))
	if storm:                                                # Lightning inside the Storm's front
		for k in 3:
			if fmod(_t * 3.0 + float(k) * 0.7, 1.0) < 0.3:
				var by := floor_y(hx) - 40.0 - float(k) * 120.0
				draw_polyline(PackedVector2Array([Vector2(hx - 120, by), Vector2(hx - 60, by - 30), Vector2(hx - 80, by - 60), Vector2(hx - 10, by - 90)]), hot, 3.0)
		return
	for i in 3:                                              # Kharlemings riding the wave
		var kx := hx + 10.0 - float(i) * 70.0 + 18.0 * sin(_t * 5.0 + float(i))
		var ky := floor_y(kx) - 30.0 - float(i) * 120.0 - 20.0 * absf(sin(_t * 6.0 + float(i) * 2.0))
		draw_set_transform(Vector2(kx, ky) - _cam, 0.0, Vector2(0.9, 0.9))
		Kharleming.draw_bot(self, {"t": _t * 3.0 + float(i), "pose": "idle", "moving": true})
		draw_set_transform(-_cam, 0.0, Vector2.ONE)


func _draw_hero() -> void:
	var fy := floor_y(px)
	var slope_a := atan(SLOPE + (70.0 / 950.0) * cos(px / 950.0) + (26.0 / 330.0) * cos(px / 330.0 + 1.3))
	var pos := Vector2(px, fy - h)
	var rot := slope_a - 0.22                                # Leaning back: sliding
	var sc := Vector2(0.95, 0.95)
	if road:                                                 # RUNNING up the bridge: lean forward, bob
		slope_a = atan((ROAD_SLOPE if _down else -ROAD_SLOPE) + (18.0 / 900.0) * cos(px / 900.0))
		rot = slope_a + 0.1
		if h <= 0.5 and _crash < 0.0:
			pos.y -= absf(sin(_t * 13.0)) * 6.0
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
	if road and hero == "architect":                         # His sword - only on the bridge
		var swing := -0.9
		if _atk_t > 0.0:
			swing = lerpf(-2.2, 0.6, 1.0 - _atk_t / 0.22)
		_draw_road_sword(Vector2(18, -62), swing)
	draw_set_transform(-_cam, 0.0, Vector2.ONE)
	if _atk_t > 0.0:                                         # The smash: a white arc in front
		var k := 1.0 - _atk_t / 0.22
		draw_arc(pos + Vector2(40, -70), 70.0, -1.4 + k * 1.2, 0.2 + k * 1.2, 12, Color(1, 1, 1, 0.8 * (1.0 - k)), 8.0)


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
	# Pause button (top right) for phones; Esc does the same on a keyboard
	var pause := UiStyle.make_button("II", Vector2(64, 56), 22)
	pause.set_anchors_and_offsets_preset(Control.PRESET_TOP_RIGHT)
	pause.offset_left = -80
	pause.offset_right = -16
	pause.offset_top = 12
	pause.offset_bottom = 68
	pause.focus_mode = Control.FOCUS_NONE
	pause.pressed.connect(func() -> void: PauseMenu.toggle(get_tree()))
	_ui.add_child(pause)


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
	FighterArt.label(c, Vector2(c.size.x * 0.5, 62.0), "%s  -  LEVEL %d     CRASHES: %d" % [StoryLevels.part_name(StoryLevels.colosseum_of(level_n)), level_n, hits], 16, Color(0.9, 0.88, 0.82))
	if _fight_x > 0.0 and not _resumed:                      # Level 70: where the fight is
		var fx := r.position.x + r.size.x * _fight_x / _len
		FighterArt.label(c, Vector2(fx, r.position.y - 6.0), "X", 14, Color(1.0, 0.4, 0.3))
	if run:
		# The flood behind you: a red bar that fills as it closes in
		var bw := 260.0
		var br := Rect2(Vector2(40.0, c.size.y - 70.0), Vector2(bw, 14.0))
		var k := 1.0 - clampf(gap / HUNT_MAX, 0.0, 1.0)
		c.draw_rect(br.grow(3.0), Color(0, 0, 0, 0.6))
		c.draw_rect(Rect2(br.position, Vector2(bw * k, br.size.y)), Color(1.0, 0.35 - 0.25 * k, 0.1).lerp(Color(1, 0.1, 0.05), k))
		var warn := gap < 350.0 and fmod(_t, 0.4) < 0.2
		FighterArt.label(c, br.position + Vector2(bw * 0.5, -12.0), "THE FLOOD IS RIGHT BEHIND YOU!" if warn else "THE HUNT: %d m behind" % int(gap / 10.0), 15,
			Color(1.0, 0.4, 0.3) if gap < 350.0 else Color(1.0, 0.8, 0.6))
	if _white > 0.0:
		c.draw_rect(Rect2(Vector2.ZERO, c.size), Color(1, 1, 1, _white))
