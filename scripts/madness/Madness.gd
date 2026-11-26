class_name Madness
extends RefCounted
## MADNESS (2026-11-21, the biggest secret code: "XANXXE 1NT3GR1T13S: % 100.00", PC SSSDDDAAADDDWWWSAWD).
##
## The code opens a red control panel (XanxxePanel): Extract Reality / Ready Infection / Engage Madness.
## All three at 100% -> the screen corrupts -> MADNESS is unlocked: the Story board gets a
## STORY | MADNESS switch at the top. MADNESS is a separate 20-level campaign (MadnessBoard.gd):
##   * everything BLACK and RED (enemies tinted, the hell map, the HUD)
##   * enemy NAMES are hidden - you only see their health
##   * WEIRD CREATURES every level (a torso, a skull head, tiny floating hands and feet - very fast),
##     SKULL SERPENTS (bone serpents), BROKEN GHOSTS (broken halos), and in the later levels
##     CORRUPTED versions of the main world's enemies
##   * level 20: THE XX0XN (a big Weird Creature with a chainsaw; phase 2 ENGAGED: flies + two chainsaws)
##     -> achievement "MadMan of the Dance Party" + the ASSASSIN skin for the Story heroes
##   * play as ANY character except APHA Architect
##   * custom hell music, rock maps with red chains hanging from hell
## Levels are numbered FIRST..FIRST+19 internally (501-520), shown as "MADNESS 1-20".
## The milestone rule (StoryDifficulty) counts them as 1-20: levels 10 and 20 are HARDER.

const PATH := "user://madness.cfg"
const FIRST := 501
const COUNT := 20
const PART := 99                                  # StoryLevels.colosseum_of() of a Madness level
const BOARD_SCENE := "res://scenes/MadnessBoard.tscn"
## Every enemy in Madness is drawn through this (black stays black, everything else turns red).
const TINT := Color(1.0, 0.16, 0.14)
const RED := Color(0.85, 0.05, 0.05)
const RED_HI := Color(1.0, 0.25, 0.2)
const BLACK := Color(0.02, 0.0, 0.0)

static var unlocked := false
static var cleared := 0                            # Levels beaten (1..20 unlock in order)
static var hero := "warrior"                       # Who you play in Madness (any but APHA)
static var skin := false                           # Assassin skin earned (beat The XX0XN)
static var _loaded := false


static func load_data() -> void:
	if _loaded:
		return
	_loaded = true
	var c := ConfigFile.new()
	if c.load(PATH) != OK:
		return
	unlocked = bool(c.get_value("madness", "unlocked", false))
	cleared = clampi(int(c.get_value("madness", "cleared", 0)), 0, COUNT)
	hero = String(c.get_value("madness", "hero", "warrior"))
	skin = bool(c.get_value("madness", "skin", false))
	if not hero_allowed(hero):
		hero = "warrior"


static func save_data() -> void:
	var c := ConfigFile.new()
	c.set_value("madness", "unlocked", unlocked)
	c.set_value("madness", "cleared", cleared)
	c.set_value("madness", "hero", hero)
	c.set_value("madness", "skin", skin)
	c.save(PATH)


static func unlock() -> void:
	load_data()
	unlocked = true
	save_data()
	Achievements.unlock("madness_unlocked")


static func is_madness(n: int) -> bool:
	return n >= FIRST and n < FIRST + COUNT


## Is a Madness level being played right now?
static func active() -> bool:
	return StoryManager.active and is_madness(StoryProgress.current_level)


static func local(n: int) -> int:
	return n - FIRST + 1


static func label(n: int) -> String:
	return "MADNESS %d" % local(n)


## Any playable roster fighter except APHA Architect.
static func hero_allowed(id: String) -> bool:
	if id == "apha" or id == "":
		return false
	for e in CharacterRoster.playable():
		if String(e["id"]) == id:
			return bool(e.get("selectable", true))        # (Not a LOCKED fighter)
	return false


static func heroes() -> Array[Dictionary]:
	var out: Array[Dictionary] = []
	for e in CharacterRoster.playable():
		if String(e["id"]) != "apha" and bool(e.get("selectable", true)):
			out.append(e)
	return out


static func set_hero(id: String) -> void:
	load_data()
	if hero_allowed(id):
		hero = id
		save_data()


## A Madness level is beaten (StoryManager._level_clear).
static func complete(n: int) -> void:
	load_data()
	cleared = maxi(cleared, local(n))
	if local(n) == 10:
		Achievements.unlock("madness_10")
	if local(n) == COUNT:
		skin = true
		Achievements.unlock("madness_boss")
	save_data()


static func level_open(local_n: int) -> bool:
	load_data()
	return local_n <= cleared + 1


# ============================================================
# THE 20 LEVELS (StoryLevels.get_level() hands these to StoryManager)
# ============================================================
## Corrupted main-world enemies join from level 8 on.
const _WAVES := {
	1: [["weird", "weird"], ["weird", "weird", "weird"]],
	2: [["weird", "skull_serpent"], ["weird", "weird", "weird"]],
	3: [["broken_ghost", "weird"], ["skull_serpent", "weird", "weird"]],
	4: [["weird", "weird", "broken_ghost"], ["skull_serpent", "skull_serpent"]],
	5: [["broken_ghost", "broken_ghost", "weird"], ["weird", "weird", "skull_serpent", "weird"]],
	6: [["skull_serpent", "weird", "weird"], ["broken_ghost", "skull_serpent", "weird"]],
	7: [["weird", "weird", "weird", "weird"], ["broken_ghost", "broken_ghost", "skull_serpent"]],
	8: [["weird", "stray", "weird"], ["guard", "broken_ghost", "weird"]],
	9: [["skull_serpent", "crawler", "weird"], ["warrior_a", "weird", "broken_ghost"]],
	10: [["weird", "weird", "skull_serpent"], ["golem", "broken_ghost", "weird"], ["weird", "weird", "weird", "skull_serpent"]],
	11: [["guard_sword", "weird", "weird"], ["skull_serpent", "brute", "weird"]],
	12: [["broken_ghost", "warrior_a_spear", "weird"], ["hydra", "weird", "weird"]],
	13: [["weird", "lava_goblin", "weird"], ["skull_serpent", "kharleming", "broken_ghost"]],
	14: [["guard_shield", "weird", "skull_serpent"], ["weird", "weird", "golem", "broken_ghost"]],
	15: [["escapist", "weird", "weird"], ["masker", "skull_serpent", "weird"]],
	16: [["weird", "weird", "weird", "weird"], ["lava_demon", "broken_ghost", "skull_serpent"]],
	17: [["tribe_brute", "weird", "broken_ghost"], ["full_kharleming", "weird", "skull_serpent"]],
	18: [["skull_serpent", "skull_serpent", "weird"], ["fragmenter", "weird", "broken_ghost", "weird"]],
	19: [["weird", "weird", "weird"], ["master_kharleming", "guard_hammer", "weird"], ["broken_ghost", "skull_serpent", "weird", "weird"]],
	20: [["weird", "weird", "broken_ghost"]],
}
const _TITLES := ["THE FIRST CRACK", "BONES THAT CRAWL", "A HALO, BROKEN", "THE CHAIN FIELD", "WHERE THE SKY BLEEDS",
	"TEETH IN THE ROCK", "FAST, SO FAST", "THEY CAME FROM ABOVE", "THE WORLD, INFECTED", "HALF OF NOTHING",
	"RUST AND RED", "SPEARS OF RIBS", "LAVA GONE BLACK", "SHIELDS OF SKIN", "THE GRINNING DARK",
	"FOUR AT ONCE", "THE TRIBE REMEMBERS NOTHING", "SERPENT NEST", "THE LAST QUIET", "THE DANCE PARTY"]


static func level(n: int) -> Dictionary:
	var k := clampi(local(n), 1, COUNT)
	var lv := {"title": _TITLES[k - 1], "theme": "madness", "map": "madness", "hero": "madness",
		"intro": "MADNESS %d.  It is very quiet. Then it is not." % k, "waves": _WAVES[k], "boss": "",
		"music": "madness_level", "madness": true}
	if k == COUNT:
		lv["boss"] = "xx0xn"
		lv["boss_music"] = "boss_xx0xn"
		lv["boss_color"] = RED_HI
		lv["boss_sub"] = ""
		lv["intro"] = "MADNESS 20.  Somewhere a chainsaw starts.  Somewhere music starts."
	return lv
