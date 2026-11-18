class_name BossRush
extends RefCounted
## BOSS RUSH (Main Menu): every Story boss you have already beaten, back to back, in Story order.
##   - One hero for the whole run (Warrior or Architect), with the Story buff.
##   - HP carries over; between bosses a short breather heals BREATHER_HEAL of max HP.
##   - ONE stock of flasks for the whole run (RUSH_FLASKS), no refills.
##   - No waves, cutscenes or dialogue: the boss drops in and the fight starts.
##   - A run timer; finished runs go into a local TOP 10 per hero (user://bossrush.cfg).
## StoryManager reads `active` and calls boss_beaten() / player_died().

const SAVE_PATH := "user://bossrush.cfg"
const RUSH_FLASKS := 5
const BREATHER_HEAL := 0.3
const MENU_SCENE := "res://scenes/BossRushMenu.tscn"
const TOP_N := 10

static var active := false
static var hero := "warrior"
static var order: Array[int] = []
static var index := 0
static var total_time := 0.0
static var flasks := RUSH_FLASKS
static var flasks_used := 0
static var hp_carry := -1
static var damage_taken := 0
static var last_result := {}            # Shown by the menu after a run
static var _story_level := -1
static var run_tracks: Array = []       # One recorded fight per boss (the ghost of a new best run)            # Story's own current level, restored after the run


## Story boss fights that can be rushed: arena levels with a boss that you have cleared.
static func boss_levels(only_cleared: bool = true) -> Array[int]:
	StoryProgress.load_progress()
	var out: Array[int] = []
	for n in range(1, StoryLevels.count() + 1):
		var lv := StoryLevels.get_level(n)
		if String(lv.get("boss", "")) == "":
			continue
		if StoryLevels.is_open_world(n) or StoryLevels.is_slide(n) or StoryLevels.is_orbis(n) \
				or StoryLevels.is_lesson(n) or StoryLevels.is_storm(n):
			continue
		if only_cleared and not StoryProgress.level_cleared(n):
			continue
		out.append(n)
	return out


static func start(p_hero: String) -> bool:
	order = boss_levels()
	if order.is_empty():
		return false
	hero = p_hero
	if not active:
		_story_level = StoryProgress.current_level
	active = true
	index = 0
	total_time = 0.0
	flasks = RUSH_FLASKS
	flasks_used = 0
	hp_carry = -1
	damage_taken = 0
	run_tracks = []
	last_result = {}
	StoryProgress.current_level = order[0]
	return true


static func current_level() -> int:
	return order[clampi(index, 0, order.size() - 1)]


static func progress_text() -> String:
	return "BOSS RUSH  %d / %d" % [index + 1, order.size()]


## A boss is down. Returns the next level number, or 0 when the run is complete.
static func boss_beaten(fight_time: float, hp_left: int, max_hp: int, flasks_left: int, dmg: int) -> int:
	total_time += fight_time
	damage_taken += dmg
	flasks = flasks_left
	index += 1
	if index >= order.size():
		_finish(true)
		return 0
	hp_carry = mini(max_hp, hp_left + roundi(float(max_hp) * BREATHER_HEAL))
	StoryProgress.current_level = order[index]
	return order[index]


static func player_died(fight_time: float, dmg: int) -> void:
	total_time += fight_time
	damage_taken += dmg
	_finish(false)


static func _restore_story() -> void:
	if _story_level > 0:
		StoryProgress.current_level = _story_level
	_story_level = -1


static func _finish(completed: bool) -> void:
	active = false
	_restore_story()
	last_result = {"completed": completed, "beaten": index if not completed else order.size(), "total": order.size(),
		"time": total_time, "hero": hero, "flasks_used": flasks_used, "damage": damage_taken, "rank": -1}
	if completed:
		last_result["rank"] = _record(total_time, order.size())
		if int(last_result["rank"]) == 0 and run_tracks.size() == order.size():
			GhostRunner.save_best(hero, order, run_tracks)          # New best: it becomes the ghost
			last_result["ghost"] = true
		Achievements.unlock("rush_complete")
		if flasks_used == 0:
			Achievements.unlock("rush_no_flask")
	if int(last_result["beaten"]) >= 3:
		Achievements.unlock("rush_three")


## Saves a finished run; returns its place in the top 10 (0 = first) or -1.
static func _record(t: float, bosses: int) -> int:
	var c := ConfigFile.new()
	c.load(SAVE_PATH)
	var list: Array = c.get_value("top", hero, [])
	var entry := {"time": t, "bosses": bosses, "date": Time.get_date_string_from_system()}
	list.append(entry)
	# More bosses first (the list grows as Story goes on), then the faster time
	list.sort_custom(func(a: Dictionary, b: Dictionary) -> bool:
		if int(a["bosses"]) != int(b["bosses"]):
			return int(a["bosses"]) > int(b["bosses"])
		return float(a["time"]) < float(b["time"]))
	if list.size() > TOP_N:
		list.resize(TOP_N)
	c.set_value("top", hero, list)
	c.save(SAVE_PATH)
	return list.find(entry)


static func top(p_hero: String) -> Array:
	var c := ConfigFile.new()
	c.load(SAVE_PATH)
	return c.get_value("top", p_hero, [])


static func cancel() -> void:
	active = false
	_restore_story()
