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
const TOTAL_LEVELS := 66                 # Level 50 = The Sun, 51-62 = THE ENLIGHTENED CHASE, 63 = DEMILAND, 64-66 = THE CAVES
const AVAILABLE_LEVELS := 66             # Colosseums 1-5 + The Enlightened Chase + DemiLand + The Caves (opening the Ancient Door opens them)
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
## BOSS EXTENSIONS: how many levels of each extension are beaten ("BC" -> 0..3) and the hero
## used for extension levels ("warrior" / "architect").
static var ext_done := {}
static var ext_hero := ""
## Colosseum 5 SOLO mode: no CPU partner (toggled on the board). Achievements + the SOLO badge.
static var c5_solo := false
## CHALLENGE BADGES per level: "level" -> ["no_powers", "no_blocks", "no_healing", "no_gauge",
## "solo", "solo_no_powers"...]. The "solo_" ones = that challenge was done in SOLO mode.
static var badges := {}
## ENEMIES MET in Story Mode (class name -> true). Story enemies / bosses appear in Versus only
## once they are in here (BaseEnemy marks itself the first time it shows up in a Story level).
static var seen := {}
## DEMILAND run in progress (DemiLand._save_run): CamTons, bosses, artifacts... {} = none.
static var demi := {}
## STORY DIFFICULTY: 0 = EASY, 1 = NORMAL, 2 = HARD (StoryDifficulty.gd). Picked on the board.
static var difficulty := 1
## BEST TIMES per level ("level" -> seconds of fighting), shown on the board and on LEVEL CLEAR.
static var best_times := {}
static var _loaded := false


static func best_time(level: int) -> float:
	load_progress()
	return float(best_times.get(str(level), 0.0))


## Saves the time if it beats the old best (or is the first). True = it was saved.
static func record_time(level: int, sec: float) -> bool:
	load_progress()
	var old := best_time(level)
	if sec <= 0.5 or (old > 0.0 and sec >= old):
		return false
	best_times[str(level)] = sec
	save_progress()
	return true


static func set_difficulty(d: int) -> void:
	load_progress()
	difficulty = clampi(d, 0, 2)
	save_progress()


static func save_demi(state: Dictionary) -> void:
	load_progress()
	demi = state
	save_progress()


static func clear_demi() -> void:
	load_progress()
	demi = {}
	save_progress()


## An enemy class was met in a Story level (saved the first time).
static func mark_seen(class_id: String) -> void:
	load_progress()
	if class_id == "" or seen.has(class_id):
		return
	seen[class_id] = true
	save_progress()


static func seen_enemy(class_id: String) -> bool:
	load_progress()
	return seen.has(class_id)


## Old saves: everything in the levels you already CLEARED counts as met (waves, boss, the coin
## flip's extras, cleared Boss Extension levels, DemiLand's camps + bosses).
static func _backfill_seen() -> void:
	var add := func(id: String) -> void:
		if id != "":
			seen[String(StoryLevels.enemy_script(id).get_global_name())] = true
	for n in range(1, StoryLevels.count() + 1):
		if not level_cleared(n):
			continue
		var lv := StoryLevels.get_level(n)
		for wave in lv.get("waves", []):
			for id in wave:
				add.call(String(id))
		add.call(String(lv.get("boss", "")))
		if bool(lv.get("coin_flip", false)):
			for id in ["ambusher", "grin", "pained"]:
				add.call(id)
		if StoryLevels.is_open_world(n):
			for c in DemiWorld.CAMPS:
				for id in c["ids"]:
					add.call(String(id))
			for b in DemiWorld.BOSSES:
				add.call(String(b["id"]))
	for k in StoryLevels.EXTENSIONS:
		var first := int(StoryLevels.EXTENSIONS[k]["first"])
		for i in ext_cleared(k):
			var lv2 := StoryLevels.get_level(first + i)
			for wave in lv2.get("waves", []):
				for id in wave:
					add.call(String(id))
			add.call(String(lv2.get("boss", "")))


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
	ext_done = cfg.get_value("story", "ext_done", {})
	ext_hero = String(cfg.get_value("story", "ext_hero", ""))
	if not ext_hero in ["", "warrior", "architect"]:
		ext_hero = ""                                  # Story Mode is Warrior / Architect only
	c5_solo = bool(cfg.get_value("story", "c5_solo", false))
	badges = cfg.get_value("story", "badges", {})
	seen = cfg.get_value("story", "seen", {})
	demi = cfg.get_value("story", "demi", {})
	difficulty = clampi(int(cfg.get_value("story", "difficulty", 1)), 0, 2)
	best_times = cfg.get_value("story", "best_times", {})
	if int(cfg.get_value("story", "layout", 1)) < LAYOUT:
		# Old save: the next level after the last one beaten, in the new numbering
		var last_beaten: int = OLD_TO_NEW[clampi(unlocked_level - 1, 0, OLD_TO_NEW.size() - 1)]
		unlocked_level = last_beaten + 1
	# Every beaten Colosseum unlocks the first level of the next one
	unlocked_level = clampi(maxi(unlocked_level, StoryLevels.first_of(colosseums_done + 1)), 1, AVAILABLE_LEVELS)
	current_level = unlocked_level
	_backfill_seen()
	save_progress()


static func save_progress() -> void:
	var cfg := ConfigFile.new()
	cfg.set_value("story", "layout", LAYOUT)
	cfg.set_value("story", "unlocked_level", unlocked_level)
	cfg.set_value("story", "colosseums_done", colosseums_done)
	cfg.set_value("story", "shining_choice", shining_choice)
	cfg.set_value("story", "optional_done", optional_done)
	cfg.set_value("story", "c5_hero", c5_hero)
	cfg.set_value("story", "ext_done", ext_done)
	cfg.set_value("story", "ext_hero", ext_hero)
	cfg.set_value("story", "c5_solo", c5_solo)
	cfg.set_value("story", "badges", badges)
	cfg.set_value("story", "seen", seen)
	cfg.set_value("story", "demi", demi)
	cfg.set_value("story", "difficulty", difficulty)
	cfg.set_value("story", "best_times", best_times)
	cfg.save(SAVE_PATH)


static func set_c5_solo(on: bool) -> void:
	c5_solo = on
	save_progress()


## Adds challenge badges for a beaten level (solo = also the "solo_<kind>" versions). Saved.
static func add_badges(level: int, kinds: Array, solo: bool) -> void:
	var key := str(level)
	var have: Array = badges.get(key, [])
	for k in kinds:
		if not have.has(k):
			have.append(k)
		if solo and k != "solo" and not have.has("solo_" + String(k)):
			have.append("solo_" + String(k))
	badges[key] = have
	save_progress()


static func has_badge(level: int, kind: String) -> bool:
	return (badges.get(str(level), []) as Array).has(kind)


## Badges shown on the board (no "solo_" duplicates).
static func badges_of(level: int) -> Array:
	var out: Array = []
	for k in badges.get(str(level), []):
		if not String(k).begins_with("solo_"):
			out.append(k)
	return out


static func badge_count() -> int:
	var n := 0
	for key in badges:
		for k in badges[key]:
			if not String(k).begins_with("solo_"):
				n += 1
	return n


# ============================================================
# BOSS EXTENSIONS
# ============================================================
## An extension is open once its parent boss level is beaten.
static func ext_open(key: String) -> bool:
	return level_cleared(int(StoryLevels.EXTENSIONS[key]["parent"]))


## How many of the 3 levels of an extension are beaten.
static func ext_cleared(key: String) -> int:
	return int(ext_done.get(key, 0))


## May this extension level (internal number) be played? (open + the one before it beaten)
static func ext_level_unlocked(n: int) -> bool:
	var key := StoryLevels.ext_of(n)
	return key != "" and ext_open(key) and StoryLevels.ext_index(n) <= ext_cleared(key)


## Extension level beaten: SAVED (after every level, so also after each extension boss).
static func complete_ext(n: int) -> void:
	var key := StoryLevels.ext_of(n)
	if key == "":
		return
	ext_done[key] = maxi(ext_cleared(key), StoryLevels.ext_index(n) + 1)
	save_progress()


static func set_ext_hero(hero: String) -> void:
	ext_hero = hero
	save_progress()


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
	ext_done = {}
	ext_hero = ""
	c5_solo = false
	badges = {}
	seen = {}                                          # Story enemies leave Versus again until met
	demi = {}
	save_progress()
