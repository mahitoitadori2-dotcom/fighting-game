class_name StoryProgress
extends RefCounted
## STORY MODE save data (user://story.cfg - on Web it lives in the browser).
##   current_level   the level being played (1..TOTAL_LEVELS)
##   unlocked_level  highest level you may start
##   colosseums_done how many Colosseums are beaten (Colosseum 1 = levels 1-6)

const SAVE_PATH := "user://story.cfg"
const TOTAL_LEVELS := 50                 # Level 50 = The Sun
const AVAILABLE_LEVELS := 6              # Only Colosseum 1 exists so far

static var current_level := 1
static var unlocked_level := 1
static var colosseums_done := 0
static var _loaded := false


static func load_progress() -> void:
	if _loaded:
		return
	_loaded = true
	var cfg := ConfigFile.new()
	if cfg.load(SAVE_PATH) != OK:
		return
	unlocked_level = clampi(int(cfg.get_value("story", "unlocked_level", 1)), 1, AVAILABLE_LEVELS)
	colosseums_done = int(cfg.get_value("story", "colosseums_done", 0))
	current_level = unlocked_level


static func save_progress() -> void:
	var cfg := ConfigFile.new()
	cfg.set_value("story", "unlocked_level", unlocked_level)
	cfg.set_value("story", "colosseums_done", colosseums_done)
	cfg.save(SAVE_PATH)


## Level beaten: unlock the next one (and mark Colosseum 1 done after its boss).
static func complete_level(level: int) -> void:
	unlocked_level = clampi(maxi(unlocked_level, level + 1), 1, AVAILABLE_LEVELS)
	if level == AVAILABLE_LEVELS:
		colosseums_done = maxi(colosseums_done, 1)
	save_progress()


static func reset() -> void:
	current_level = 1
	unlocked_level = 1
	colosseums_done = 0
	save_progress()
