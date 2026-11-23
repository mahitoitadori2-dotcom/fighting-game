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
## DAILY RUN (2026-11-23, picked by the user): one run a day, the SAME for everyone - today's date picks
## 5 of your beaten bosses + ONE modifier. Today's best time is kept, and today's best run comes back as
## a ghost. (Normal runs and their TOP 10 are unchanged.)
const DAILY_BOSSES := 5
const DAILY_MODS := ["NO FLASKS", "GLASS CANNON", "FAST BOSSES", "HALF HEALTH"]
const DAILY_MOD_TEXT := {"NO FLASKS": "no flasks at all", "GLASS CANNON": "everyone takes 1.5x damage",
	"FAST BOSSES": "bosses move + attack faster", "HALF HEALTH": "you start at half health"}
static var daily := false
static var daily_mod := ""
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
static var run_hz := 30.0                  # Snapshots per second of run_tracks
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


static func today() -> String:
	return Time.get_date_string_from_system()


## Today's run: [boss levels in order, modifier]. Seeded by the date.
static func daily_plan() -> Array:
	var rng := RandomNumberGenerator.new()
	rng.seed = hash("ub_daily_" + today())
	var pool := boss_levels()
	for i in range(pool.size() - 1, 0, -1):                 # Seeded shuffle
		var j := rng.randi() % (i + 1)
		var tmp := pool[i]
		pool[i] = pool[j]
		pool[j] = tmp
	var picked: Array[int] = []
	for i in mini(DAILY_BOSSES, pool.size()):
		picked.append(pool[i])
	return [picked, String(DAILY_MODS[rng.randi() % DAILY_MODS.size()])]


static func start_daily(p_hero: String) -> bool:
	var plan := daily_plan()
	var picked: Array[int] = plan[0]
	if picked.size() < 3 or not start(p_hero):
		return false
	daily = true
	daily_mod = String(plan[1])
	order = picked
	flasks = 0 if daily_mod == "NO FLASKS" else RUSH_FLASKS
	StoryProgress.current_level = order[0]
	return true


## The ghost's file key: the hero (normal runs) or today's daily run.
static func ghost_key() -> String:
	return "daily_%s_%s" % [today(), hero] if daily else hero


## Today's best daily time for a hero (0 = none yet).
static func daily_best(p_hero: String) -> float:
	var c := ConfigFile.new()
	c.load(SAVE_PATH)
	return float(c.get_value("daily", today() + "_" + p_hero, 0.0))


## DAILY modifiers on the player (StoryManager, after the player spawns) and on each boss (buff_boss).
static func daily_player(p: Fighter) -> void:
	if not (active and daily) or p == null:
		return
	match daily_mod:
		"GLASS CANNON":
			p.damage_taken_mult *= 1.5
		"HALF HEALTH":
			if index == 0:
				p.hp = maxi(1, roundi(float(p.data.max_hp) * 0.5))
				p.health_changed.emit(p.hp, p.data.max_hp)


static func daily_boss(b: BaseEnemy) -> void:
	if not (active and daily) or b == null:
		return
	match daily_mod:
		"GLASS CANNON":
			b.damage_taken_mult *= 1.5
		"FAST BOSSES":
			b.boss_speed_mult *= 1.25
			b.boss_cd_mult *= 0.8


static func current_level() -> int:
	return order[clampi(index, 0, order.size() - 1)]


static func progress_text() -> String:
	return "BOSS RUSH  %d / %d" % [index + 1, order.size()]


## A boss is down. Returns the next level number, or 0 when the run is complete.
static func boss_beaten(fight_time: float, hp_left: int, max_hp: int, flasks_left: int, dmg: int) -> int:
	Daily.progress("rush_boss")                                 # DAILY challenges
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
	if daily:
		last_result["daily"] = true
		last_result["mod"] = daily_mod
		daily = false
		if completed:
			Achievements.unlock("rush_daily")
			var best := daily_best(hero)
			if best <= 0.0 or total_time < best:
				var c := ConfigFile.new()
				c.load(SAVE_PATH)
				var keep := {}
				for k in c.get_section_keys("daily") if c.has_section("daily") else []:
					if String(k).begins_with(today()):
						keep[k] = c.get_value("daily", k)
				if c.has_section("daily"):
					c.erase_section("daily")                   # (Only today's records are kept)
				for k in keep:
					c.set_value("daily", k, keep[k])
				c.set_value("daily", today() + "_" + hero, total_time)
				c.save(SAVE_PATH)
				last_result["daily_best"] = true
				if run_tracks.size() == order.size():
					GhostRunner.save_best(hero, order, run_tracks, ghost_key_for(hero, true))
		return
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


static func ghost_key_for(p_hero: String, is_daily: bool) -> String:
	return "daily_%s_%s" % [today(), p_hero] if is_daily else p_hero


static func cancel() -> void:
	daily = false
	active = false
	_restore_story()
