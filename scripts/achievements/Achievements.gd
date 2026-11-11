class_name Achievements
extends RefCounted
## ACHIEVEMENTS: every achievement in ONE list (_build), saved to user://achievements.cfg.
## Unlocking one pops the AchievementToast (left side of the screen, with its artwork).
## The ACHIEVEMENTS menu (Main Menu) shows them all as a grid (AchievementsMenu).
##
## Where they come from:
##   VERSUS (MatchManager -> on_versus_win): beat every character / enemy / boss, beat them
##     with Bare Hands (no Powers, no Blocking, no G Gauge), win as each character...
##     Never in SANDBOX mode, never with the CPU playing for you.
##   STORY (StoryManager -> on_story_clear): boss + mini-boss trophies, "Pure Faith" (a boss
##     level without Blocks, Healing, G Gauge AND Powers), hard levels, Colosseum 5 SOLO,
##     whole-Colosseum challenges, and the MULTI-MULTI-MULTIVERSAL LEVEL OF POWER.
##   BADGES: every cleared Story level gives one badge per challenge kept (KINDS + "solo"),
##     saved in StoryProgress.badges and shown on the board.
##
## ADD AN ACHIEVEMENT: one _add(...) line in _build(), then call unlock("its_id") where it
## is earned (or add the check to _check_meta()). The menu and the toast pick it up.

const SAVE_PATH := "user://achievements.cfg"
const ULTIMATE := "multiversal"

## Story challenges (= badges). "solo" is the extra Colosseum 5 badge.
const KINDS := ["no_powers", "no_blocks", "no_healing", "no_gauge"]
const KIND_USE := {"no_powers": "powers", "no_blocks": "blocks", "no_healing": "healing", "no_gauge": "gauge"}
const KIND_NAMES := {"no_powers": "NO POWERS", "no_blocks": "NO BLOCKS", "no_healing": "NO HEALING", "no_gauge": "NO G GAUGE", "solo": "SOLO"}
const KIND_TITLES := {"no_powers": "Powerless", "no_blocks": "Shieldless", "no_healing": "Unhealed", "no_gauge": "Gaugeless"}

## Story bosses + mini-bosses: [level, enemy id (portrait), name, kind]  kind: boss / mini / ext
const BOSSES := [
	[6, "blinded_lord", "The Blinded Lord", "boss"],
	[8, "architect_chorus", "The Architect Chorus", "mini"],
	[15, "blasphemy_caeser", "Blasphemy Caeser", "boss"],
	[17, "atomic", "The Atomic Creation", "mini"],
	[24, "forge_mother", "The Forge Mother", "mini"],
	[26, "arch_golem", "The Architect's Golem", "boss"],
	[28, "escapist", "The Void Escapist", "mini"],
	[31, "masker", "The Hollow Masker", "mini"],
	[34, "void_massacre", "The Void Massacre", "boss"],
	[36, "needle", "Child Wielding Needle", "boss"],
	[39, "brothers", "The Brothers", "boss"],
	[42, "animal_lord", "Animal Lord", "boss"],
	[45, "executor", "Executor", "boss"],
	[47, "mother_nature", "Mother Nature", "boss"],
	[48, "false_god", "The False God", "boss"],
	[49, "satan", "Satan", "boss"],
	[50, "the_sun", "The Sun", "boss"],
	[56, "first_prime", "The Enlightened First Prime", "mini"],
	[62, "enlightened_one", "The Enlightened One", "boss"],
	[103, "caeser_grave", "The Caeser's Grave", "ext"],
	[106, "saint_golem", "The Saint Architect's Golem", "ext"],
	[109, "void_horrid", "The Void Horrids", "ext"],
	[112, "rad_chorus", "The Radioactive Chorus", "ext"],
	[115, "forge_father", "The Forge Father", "ext"],
]
## Harder normal levels: [level, achievement name]
const HARD_LEVELS := [
	[4, "Hive Breaker"], [5, "Through the Burning Tunnels"], [16, "Throne Room Ambush"],
	[21, "Bulwark Breaker"], [33, "Web Cutter"], [46, "Roots of the World"],
	[53, "Caravan Breaker"], [61, "The Gates of Light"],
]
## Story parts 1-5 are Colosseums; part 6 is THE ENLIGHTENED CHASE (not a Colosseum).
const COLOSSEUM_NAMES := ["The Ashen Depths", "The Ascent", "The Burning Crown", "The Void Below", "The Final Ascent", "The Enlightened Chase"]
const PARTS := 6
const C5_FIRST := 35
const C5_LAST := 50

static var unlocked := {}                 # id -> unix time it was unlocked
static var galaxy_skin := true            # The Multiversal reward is worn (toggle in the menu)
static var _defs: Array[Dictionary] = []
static var _by_id := {}
static var _loaded := false


# ============================================================
# THE LIST
# ============================================================
## def = {id, name, desc, cat, art}. cat: "versus" / "story" / "challenge" / "secret".
## art (AchievementArt): script (portrait art) or enemy (Story enemy id) or hero, plus
## frame (gold / silver / bronze / purple / red / galaxy), emblem (corner icon),
## big (centre icon when there is no portrait), bg (background colour).
static func defs() -> Array[Dictionary]:
	if _defs.is_empty():
		_build()
	return _defs


static func get_def(id: String) -> Dictionary:
	defs()
	return _by_id.get(id, {})


static func _add(id: String, nm: String, desc: String, cat: String, art: Dictionary) -> void:
	var d := {"id": id, "name": nm, "desc": desc, "cat": cat, "art": art}
	_defs.append(d)
	_by_id[id] = d


static func _build() -> void:
	# ---------------- VERSUS ----------------
	_add("vs_first", "First Blood", "Win your first Versus fight.", "versus",
		{"big": "sword", "frame": "bronze", "bg": Color(0.45, 0.12, 0.10)})
	_add("vs_no_powers", "Powerless Victory", "Win a Versus fight without using a single Power (moves 1 / 2 / 3).", "versus",
		{"big": "no_powers", "frame": "silver", "bg": Color(0.20, 0.16, 0.40)})
	_add("vs_no_blocks", "Shieldless Victory", "Win a Versus fight without blocking even once.", "versus",
		{"big": "no_blocks", "frame": "silver", "bg": Color(0.16, 0.26, 0.40)})
	_add("vs_no_gauge", "Gaugeless Victory", "Win a Versus fight without using the G Gauge.", "versus",
		{"big": "no_gauge", "frame": "silver", "bg": Color(0.10, 0.30, 0.42)})
	for e in CharacterRoster.playable():
		var id := String(e["id"])
		var acc: Color = e.get("accent", Color.WHITE)
		_add("vs_beat_" + id, "%s Trophy" % e["short"], "Defeat %s in a Versus fight." % e["name"], "versus",
			{"script": e["art"], "frame": "gold", "emblem": "trophy", "bg": acc.darkened(0.6)})
		_add("vs_pure_" + id, "%s: Bare Hands" % e["short"], "Defeat %s without using Powers, Blocking or the G Gauge." % e["name"], "versus",
			{"script": e["art"], "frame": "silver", "emblem": "fist", "bg": acc.darkened(0.75)})
		_add("vs_as_" + id, "%s Main" % e["short"], "Win a Versus fight playing as %s." % e["name"], "versus",
			{"script": e["art"], "frame": "bronze", "emblem": "star", "bg": acc.darkened(0.45)})
	for e in CharacterRoster.enemies():
		var id := String(e["id"])
		var acc: Color = e.get("accent", Color.WHITE)
		var boss := bool(e.get("boss", false))
		_add("vs_beat_" + id, "%s Trophy" % e["short"], "Defeat %s%s in a Versus fight." % [e["name"], " (Fights-mode BOSS)" if boss else ""], "versus",
			{"script": e["art"], "frame": "red" if boss else "gold", "emblem": "trophy", "bg": acc.darkened(0.6)})
		_add("vs_pure_" + id, "%s: Bare Hands" % e["short"], "Defeat %s without using Powers, Blocking or the G Gauge." % e["name"], "versus",
			{"script": e["art"], "frame": "silver", "emblem": "fist", "bg": acc.darkened(0.75)})
	_add("vs_all_chars", "Roster Breaker", "Defeat EVERY playable character in Versus.", "versus",
		{"big": "crown", "frame": "gold", "bg": Color(0.35, 0.10, 0.30)})
	_add("vs_all_enemies", "Monster Hunter", "Defeat EVERY Versus enemy and Fights-mode boss.", "versus",
		{"big": "skull", "frame": "red", "bg": Color(0.35, 0.06, 0.06)})

	# ---------------- STORY: bosses, mini-bosses, extension bosses ----------------
	for b in BOSSES:
		var n: int = b[0]
		var where := "Level %d" % n if n < StoryLevels.EXT_BASE else StoryLevels.ext_code(n)
		var kind: String = b[3]
		var what := "the mini-boss " if kind == "mini" else ("the extension boss " if kind == "ext" else "")
		_add(_trophy_id(n), "%s Trophy" % _short(b[2]), "Defeat %s%s (%s)." % [what, b[2], where], "story",
			{"enemy": b[1], "frame": "gold" if kind != "mini" else "bronze", "emblem": "trophy", "bg": _level_bg(n)})
		_add(_pure_id(n), "%s: Pure Faith" % _short(b[2]), "Beat %s (%s) without Blocking, Healing, the G Gauge or Powers - all in the same run." % [b[2], where], "challenge",
			{"enemy": b[1], "frame": "silver", "emblem": "halo", "bg": _level_bg(n).darkened(0.35)})
		if n >= C5_FIRST and n <= C5_LAST:
			_add(_solo_id(n), "%s: Solo" % _short(b[2]), "Beat %s in Colosseum 5 SOLO mode (no CPU partner)." % b[2], "challenge",
				{"enemy": b[1], "frame": "purple", "emblem": "solo", "bg": Color(0.22, 0.08, 0.34)})
	for h in HARD_LEVELS:
		var n: int = h[0]
		_add("hard_%d" % n, String(h[1]), "Clear Level %d: %s." % [n, StoryLevels.get_level(n).get("title", "?")], "story",
			{"enemy": StoryLevels.tile_enemy(n), "frame": "bronze", "emblem": "sword", "bg": _level_bg(n)})
	_add("shining_killed", "Light Extinguished", "Destroy The Shining on its altar (optional Level 32).", "story",
		{"enemy": "shining", "frame": "red", "emblem": "skull", "bg": Color(0.30, 0.28, 0.10)})
	_add("shining_spared", "Mercy in the Dark", "Leave The Shining alive (optional Level 32).", "story",
		{"enemy": "shining", "frame": "gold", "emblem": "halo", "bg": Color(0.36, 0.34, 0.16)})

	# ---------------- STORY: Colosseums ----------------
	for c in range(1, PARTS + 1):
		var part := _part(c)
		var full := part if c == StoryLevels.CHASE_PART else "%s: %s" % [part, COLOSSEUM_NAMES[c - 1]]
		var art := {"big": "crown", "frame": "gold", "bg": _col_bg(c)}
		if c < StoryLevels.CHASE_PART:
			art["num"] = c
		_add("col_%d" % c, "%s Conquered" % part, "Beat %s." % full, "story", art)
		for k in KINDS:
			var cart := {"big": k, "frame": "silver" if k != "no_powers" else "gold", "bg": _col_bg(c).darkened(0.3)}
			if c < StoryLevels.CHASE_PART:
				cart["num"] = c
			_add("col_%d_%s" % [c, k], "%s: %s" % [part, KIND_TITLES[k]],
				"Earn the %s badge on every level of %s (optional levels not needed)." % [KIND_NAMES[k], part], "challenge", cart)
	_add("deep_faith", "Deep Faith", "Defeat Mother Nature to earn DEEP FAITH PAYOFF: +20% HP, +1 flask and shorter cooldowns for the Warrior and the Architect in Story Mode.", "story",
		{"enemy": "mother_nature", "frame": "gold", "emblem": "halo", "bg": Color(0.20, 0.40, 0.18)})
	_add("chase_warrior", "The Warrior's Pursuit", "Catch and beat The Enlightened One as the Warrior.", "story",
		{"hero": "warrior", "frame": "gold", "emblem": "sword", "bg": Color(0.45, 0.32, 0.12)})
	_add("chase_architect", "The Architect's Pursuit", "Catch and beat The Enlightened One as the Architect.", "story",
		{"hero": "architect", "frame": "gold", "emblem": "sword", "bg": Color(0.45, 0.32, 0.12)})
	_add("c5_solo_all", "One Hero, One Road", "Clear EVERY level of Colosseum 5 in SOLO mode.", "challenge",
		{"big": "solo", "frame": "purple", "bg": Color(0.25, 0.08, 0.40), "num": 5})
	_add("ext_all", "Deep Explorer", "Beat the final boss of all 5 Boss Extensions.", "story",
		{"big": "crown", "frame": "silver", "bg": Color(0.10, 0.22, 0.30)})

	# ---------------- BADGES / heroes ----------------
	_add("badge_1", "First Badge", "Earn your first Story challenge badge.", "challenge",
		{"big": "badge", "frame": "bronze", "bg": Color(0.30, 0.22, 0.10)})
	_add("badge_25", "Badge Collector", "Earn 25 Story challenge badges.", "challenge",
		{"big": "badge", "frame": "silver", "bg": Color(0.22, 0.24, 0.30)})
	_add("badge_100", "Badge Hoarder", "Earn 100 Story challenge badges.", "challenge",
		{"big": "badge", "frame": "gold", "bg": Color(0.35, 0.26, 0.05)})
	_add("anti_level", "The Negative", "Clear a Story level as the Anti Architect.", "story",
		{"hero": "anti", "frame": "bronze", "emblem": "star", "bg": Color(0.35, 0.16, 0.04)})
	_add("anti_sun", "Eclipse of the Anti", "Beat The Sun as the Anti Architect.", "story",
		{"hero": "anti", "frame": "gold", "emblem": "sun", "bg": Color(0.45, 0.22, 0.02)})

	# ---------------- THE ULTIMATE ONE ----------------
	_add(ULTIMATE, "Multi-Multi-Multiversal Level Of Power",
		"Clear EVERY level of Colosseum 5 in SOLO mode with all four challenges: No Powers, No Blocks, No Healing and No G Gauge (can be different runs per challenge).  REWARD: GALAXY skins for the Architect and the Warrior.", "secret",
		{"big": "galaxy", "frame": "galaxy", "bg": Color(0.06, 0.02, 0.16)})


static func _trophy_id(n: int) -> String: return "trophy_%d" % n
static func _pure_id(n: int) -> String: return "pure_%d" % n
static func _solo_id(n: int) -> String: return "solo_%d" % n


static func _short(nm: String) -> String:
	return nm.trim_prefix("The ")


static func _col_bg(c: int) -> Color:
	return [Color(0.40, 0.12, 0.06), Color(0.32, 0.28, 0.10), Color(0.40, 0.20, 0.06), Color(0.14, 0.08, 0.26), Color(0.42, 0.32, 0.10),
		Color(0.55, 0.42, 0.16)][clampi(c - 1, 0, 5)]


## "Colosseum 3" / "The Enlightened Chase" (the 6th part is NOT a Colosseum).
static func _part(c: int) -> String:
	return "The Enlightened Chase" if c == StoryLevels.CHASE_PART else "Colosseum %d" % c


static func _level_bg(n: int) -> Color:
	if n >= StoryLevels.EXT_BASE:
		return Color(0.16, 0.20, 0.24)
	return _col_bg(StoryLevels.colosseum_of(n))


# ============================================================
# SAVE / LOAD
# ============================================================
static func load_data() -> void:
	if _loaded:
		return
	_loaded = true
	var cfg := ConfigFile.new()
	if cfg.load(SAVE_PATH) != OK:
		return
	unlocked = cfg.get_value("achievements", "unlocked", {})
	galaxy_skin = bool(cfg.get_value("achievements", "galaxy_skin", true))


static func save_data() -> void:
	var cfg := ConfigFile.new()
	cfg.set_value("achievements", "unlocked", unlocked)
	cfg.set_value("achievements", "galaxy_skin", galaxy_skin)
	cfg.save(SAVE_PATH)


static func is_unlocked(id: String) -> bool:
	load_data()
	return unlocked.has(id)


static func unlocked_count() -> int:
	load_data()
	var n := 0
	for d in defs():
		if unlocked.has(d["id"]):
			n += 1
	return n


## Unlock + show the toast. Does nothing if it's already unlocked or unknown.
static func unlock(id: String) -> void:
	load_data()
	if unlocked.has(id) or get_def(id).is_empty():
		return
	unlocked[id] = int(Time.get_unix_time_from_system())
	save_data()
	AchievementToast.show_achievement(get_def(id))


static func set_galaxy_skin(on: bool) -> void:
	galaxy_skin = on
	save_data()


## Draw this Architect / Warrior in GALAXY colours? (Multiversal reward, worn by YOUR
## heroes: the human player in Versus, you + your partner in Story Mode.)
static func galaxy_for(f: Fighter) -> bool:
	if not galaxy_skin or not is_unlocked(ULTIMATE) or f == null:
		return false
	if StoryManager.active:
		return f.team == 1
	return f is ControlledFighter and (f as ControlledFighter).is_human()


# ============================================================
# VERSUS
# ============================================================
## P1 (you) won a Versus fight. MatchManager calls this.
static func on_versus_win(mine_id: String, opp_id: String, used: Dictionary) -> void:
	if MatchSettings.sandbox or ArenaManager.p1_cpu or opp_id == "" or opp_id == CharacterRoster.DUMMY_ID:
		return
	unlock("vs_first")
	if not used.get("powers", false):
		unlock("vs_no_powers")
	if not used.get("blocks", false):
		unlock("vs_no_blocks")
	if not used.get("gauge", false):
		unlock("vs_no_gauge")
	unlock("vs_beat_" + opp_id)
	if not used.get("powers", false) and not used.get("blocks", false) and not used.get("gauge", false):
		unlock("vs_pure_" + opp_id)
	unlock("vs_as_" + mine_id)
	var all_chars := true
	for e in CharacterRoster.playable():
		if not is_unlocked("vs_beat_" + String(e["id"])):
			all_chars = false
	if all_chars:
		unlock("vs_all_chars")
	var all_enemies := true
	for e in CharacterRoster.enemies():
		if not is_unlocked("vs_beat_" + String(e["id"])):
			all_enemies = false
	if all_enemies:
		unlock("vs_all_enemies")


# ============================================================
# STORY
# ============================================================
## Challenges kept in this run (no powers / blocks / healing / gauge).
static func kept_kinds(used: Dictionary) -> Array:
	var out: Array = []
	for k in KINDS:
		if not used.get(KIND_USE[k], false):
			out.append(k)
	return out


## A Story level (or Boss Extension level) was beaten. Gives the BADGES and achievements.
## Returns the badge kinds earned (for the LEVEL CLEAR banner).
static func on_story_clear(n: int, player: Fighter, solo: bool, hero: String) -> Array:
	var kinds := kept_kinds(player.used if player != null else {})
	var earned := kinds.duplicate()
	if solo:
		earned.append("solo")
	StoryProgress.add_badges(n, earned, solo)
	for b in BOSSES:
		if int(b[0]) != n:
			continue
		unlock(_trophy_id(n))
		if kinds.size() == KINDS.size():
			unlock(_pure_id(n))
		if solo and n >= C5_FIRST and n <= C5_LAST:
			unlock(_solo_id(n))
	for h in HARD_LEVELS:
		if int(h[0]) == n:
			unlock("hard_%d" % n)
	if n == 32:
		if StoryProgress.shining_choice == "killed":
			unlock("shining_killed")
		elif StoryProgress.shining_choice == "spared":
			unlock("shining_spared")
	if hero == "anti":
		unlock("anti_level")
		if n == C5_LAST:
			unlock("anti_sun")
	if n == StoryManager.DEEP_FAITH_AFTER:
		unlock("deep_faith")                            # Deep Faith Payoff is now active
	if n == StoryProgress.TOTAL_LEVELS and (hero == "warrior" or hero == "architect"):
		unlock("chase_" + hero)                         # Caught The Enlightened One
	if n < StoryLevels.EXT_BASE:
		var c := StoryLevels.colosseum_of(n)
		if n == StoryLevels.last_of(c):
			unlock("col_%d" % c)
	_check_meta()
	return earned


## Achievements that depend on ALL the badges / trophies so far.
static func _check_meta() -> void:
	var total := StoryProgress.badge_count()
	if total >= 1:
		unlock("badge_1")
	if total >= 25:
		unlock("badge_25")
	if total >= 100:
		unlock("badge_100")
	for c in range(1, PARTS + 1):
		for k in KINDS:
			if _colosseum_has(c, k):
				unlock("col_%d_%s" % [c, k])
	if _colosseum_has(5, "solo"):
		unlock("c5_solo_all")
	var ultimate := true
	for k in KINDS:
		if not _colosseum_has(5, "solo_" + k):
			ultimate = false
	if ultimate:
		unlock(ULTIMATE)
	var ext_done := true
	for b in BOSSES:
		if String(b[3]) == "ext" and not is_unlocked(_trophy_id(int(b[0]))):
			ext_done = false
	if ext_done:
		unlock("ext_all")


## Every (non-optional) level of Colosseum c has badge `kind`.
static func _colosseum_has(c: int, kind: String) -> bool:
	for n in range(StoryLevels.first_of(c), StoryLevels.last_of(c) + 1):
		if StoryLevels.is_optional(n):
			continue
		if not StoryProgress.has_badge(n, kind):
			return false
	return true
