class_name StoryProgress
extends RefCounted
## STORY MODE save data (user://story.cfg - on Web it lives in the browser).
##   current_level   the level being played (1..TOTAL_LEVELS)
##   unlocked_level  highest level you may start
##   colosseums_done how many Colosseums are beaten (Colosseum 1 = levels 1-6, 2 = 7-12)

const SAVE_PATH := "user://story.cfg"
const TOTAL_LEVELS := 50                 # Level 50 = The Sun
const AVAILABLE_LEVELS := 24             # Colosseums 1-4 exist so far

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
	# Old saves (made when only Colosseum 1 existed) stopped at level 6 even after the
	# Blinded Lord was beaten: every beaten Colosseum unlocks the first level of the next.
	unlocked_level = clampi(maxi(unlocked_level, colosseums_done * StoryLevels.LEVELS_PER_COLOSSEUM + 1), 1, AVAILABLE_LEVELS)
	current_level = unlocked_level


static func save_progress() -> void:
	var cfg := ConfigFile.new()
	cfg.set_value("story", "unlocked_level", unlocked_level)
	cfg.set_value("story", "colosseums_done", colosseums_done)
	cfg.save(SAVE_PATH)


## Level beaten: unlock the next one (and mark the Colosseum done after its boss).
static func complete_level(level: int) -> void:
	unlocked_level = clampi(maxi(unlocked_level, level + 1), 1, AVAILABLE_LEVELS)
	if level % StoryLevels.LEVELS_PER_COLOSSEUM == 0:
		colosseums_done = maxi(colosseums_done, level / StoryLevels.LEVELS_PER_COLOSSEUM)
	save_progress()


## True once the boss level of this level's Colosseum is beaten (board check marks).
static func level_cleared(level: int) -> bool:
	if level < unlocked_level:
		return true
	return level % StoryLevels.LEVELS_PER_COLOSSEUM == 0 and colosseums_done >= level / StoryLevels.LEVELS_PER_COLOSSEUM


static func reset() -> void:
	current_level = 1
	unlocked_level = 1
	colosseums_done = 0
	save_progress()
