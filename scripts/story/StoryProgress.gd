class_name StoryProgress
extends RefCounted
## STORY MODE save data (user://story.cfg - on Web it lives in the browser).
##   current_level   the level being played (1..AVAILABLE_LEVELS)
##   unlocked_level  highest level you may start
##   colosseums_done how many Colosseums are beaten (their sizes are in StoryLevels.COLOSSEUM_SIZES)
##   shining_choice  Colosseum 4's optional level: "" (never played = skipped), "killed" or "spared"
##   optional_done   optional levels that were played (board check marks)
##
## LAYOUT 2 (Colosseums of 6 / 9 / 11 / 8 levels). Saves from layout 1 (four Colosseums of 6)
## are moved to the matching level of the new layout when they load.

const SAVE_PATH := "user://story.cfg"
const TOTAL_LEVELS := 50                 # Level 50 = The Sun
const AVAILABLE_LEVELS := 50             # Colosseums 1-5: the whole story, up to The Sun
const LAYOUT := 2
## Layout 1 level (index) -> the same content in layout 2.
const OLD_TO_NEW := [0, 1, 2, 2, 3, 4, 6, 8, 9, 10, 12, 13, 15, 16, 17, 19, 20, 24, 26, 27, 28, 29, 30, 31, 34]

static var current_level := 1
static var unlocked_level := 1
static var colosseums_done := 0
static var shining_choice := ""
static var optional_done: Array = []
## Colosseum 5: the hero you picked ("warrior" / "architect"); the other one is your CPU partner.
static var c5_hero := ""
static var _loaded := false


static func load_progress() -> void:
	if _loaded:
		return
	_loaded = true
	var cfg := ConfigFile.new()
	if cfg.load(SAVE_PATH) != OK:
		return
	unlocked_level = maxi(int(cfg.get_value("story", "unlocked_level", 1)), 1)
	colosseums_done = int(cfg.get_value("story", "colosseums_done", 0))
	shining_choice = String(cfg.get_value("story", "shining_choice", ""))
	optional_done = cfg.get_value("story", "optional_done", [])
	c5_hero = String(cfg.get_value("story", "c5_hero", ""))
	if int(cfg.get_value("story", "layout", 1)) < LAYOUT:
		# Old save: the next level after the last one beaten, in the new numbering
		var last_beaten: int = OLD_TO_NEW[clampi(unlocked_level - 1, 0, OLD_TO_NEW.size() - 1)]
		unlocked_level = last_beaten + 1
	# Every beaten Colosseum unlocks the first level of the next one
	unlocked_level = clampi(maxi(unlocked_level, StoryLevels.first_of(colosseums_done + 1)), 1, AVAILABLE_LEVELS)
	current_level = unlocked_level
	save_progress()


static func save_progress() -> void:
	var cfg := ConfigFile.new()
	cfg.set_value("story", "layout", LAYOUT)
	cfg.set_value("story", "unlocked_level", unlocked_level)
	cfg.set_value("story", "colosseums_done", colosseums_done)
	cfg.set_value("story", "shining_choice", shining_choice)
	cfg.set_value("story", "optional_done", optional_done)
	cfg.set_value("story", "c5_hero", c5_hero)
	cfg.save(SAVE_PATH)


## Level beaten: unlock the next one (an OPTIONAL next level also unlocks the one after it,
## so it can be skipped) and mark the Colosseum done after its boss.
static func complete_level(level: int) -> void:
	var nxt := level + 1
	if StoryLevels.is_optional(nxt):
		nxt += 1
	unlocked_level = clampi(maxi(unlocked_level, nxt), 1, AVAILABLE_LEVELS)
	if StoryLevels.is_optional(level) and not optional_done.has(level):
		optional_done.append(level)
	var c := StoryLevels.colosseum_of(level)
	if level == StoryLevels.last_of(c):
		colosseums_done = maxi(colosseums_done, c)
	save_progress()


## True once a level is beaten (board check marks).
static func level_cleared(level: int) -> bool:
	if StoryLevels.is_optional(level):
		return optional_done.has(level)
	if level < unlocked_level:
		return true
	var c := StoryLevels.colosseum_of(level)
	return level == StoryLevels.last_of(c) and colosseums_done >= c


static func set_shining_choice(choice: String) -> void:
	shining_choice = choice
	save_progress()


static func set_c5_hero(hero: String) -> void:
	c5_hero = hero
	save_progress()


static func reset() -> void:
	current_level = 1
	unlocked_level = 1
	colosseums_done = 0
	shining_choice = ""
	optional_done = []
	c5_hero = ""
	save_progress()
