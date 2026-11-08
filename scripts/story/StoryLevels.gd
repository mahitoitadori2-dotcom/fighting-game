class_name StoryLevels
extends RefCounted
## STORY MODE level list. COLOSSEUM 1 = levels 1-6 (of 50; Level 50 = The Sun).
## A level = waves of enemy GROUPS, then (boss levels) intro cutscene -> boss -> death cutscene.
##
##   waves   Array of groups; each group = Array of enemy ids (see make_enemy()).
##   boss    enemy id, or "" for a normal level
##   theme   "surface" (lava wastes under a burning sky) or "cave" (after the fall)

const PLAYER_CHARACTER := "warrior"      # Story Mode is Warrior only

## MAPS: what the arena looks / sounds like. StoryManager applies it on level start.
##   bg          HellBackground theme ("surface", "cave", "geode", "hive")
##   ground      ArenaGround theme (2 Hell, 3 Geode, 4 Scrap)
##   walls       CaveWall style ("lava", "crystal", "metal")
##   half_width  distance from the arena centre to each wall (smaller = tighter arena)
##   music       SoundManager track for the group battles
const MAPS := {
	"wastes": {"bg": "surface", "ground": 2, "walls": "lava", "half_width": 850.0, "music": "story_surface"},
	"geode":  {"bg": "geode", "ground": 3, "walls": "crystal", "half_width": 560.0, "music": "story_geode"},
	"hive":   {"bg": "hive", "ground": 4, "walls": "metal", "half_width": 700.0, "music": "story_hive"},
	"lair":   {"bg": "cave", "ground": 2, "walls": "lava", "half_width": 850.0, "music": "story_cave"},
	# The Blinded Lord's LABORATORY (boss arena): chemical tubes, glass chambers with
	# rotted skeletons. The level switches to it when the boss intro starts.
	"lab":    {"bg": "lab", "ground": 5, "walls": "lab", "half_width": 800.0, "music": "boss"},
}

const LEVELS := {
	1: {"title": "THE ASHEN GATE", "theme": "surface", "map": "wastes",
		"intro": "Something stirs in the ash...",
		"waves": [["parasite"]], "boss": ""},
	2: {"title": "BRUTE MARCH", "theme": "surface", "map": "wastes",
		"intro": "Parasites and Demon Brutes block the road.",
		"waves": [["parasite", "parasite", "brute"], ["parasite", "brute", "parasite"]], "boss": ""},
	3: {"title": "THE MUTANT PIT", "theme": "surface", "map": "wastes",
		"intro": "Something big is breathing in the dark.",
		"waves": [["brute", "brute"], ["brute", "hydra"]], "boss": ""},
	4: {"title": "THE GEODE CAVERN", "theme": "cave", "map": "geode",
		"intro": "The ground gave way. You fell into a cavern of crystal.",
		"waves": [["golem"]], "boss": ""},
	5: {"title": "THE KHARLEMING HIVE", "theme": "cave", "map": "hive",
		"intro": "Rusted scrap, blinking eyes, clicking legs on the walls...",
		"waves": [["kharleming", "kharleming", "kharleming"], ["kharleming", "kharleming", "kharleming", "kharleming"]], "boss": ""},
	6: {"title": "THE BLINDED LORD", "theme": "cave", "map": "lair", "boss_map": "lab",
		"intro": "The air burns. The Blinded Lord's lair.",
		"waves": [["parasite", "brute", "parasite"], ["kharleming", "kharleming", "brute"]], "boss": "blinded_lord"},
}


static func get_level(n: int) -> Dictionary:
	return LEVELS.get(clampi(n, 1, LEVELS.size()), LEVELS[1])


static func map_of(n: int) -> Dictionary:
	return MAPS.get(String(get_level(n).get("map", "wastes")), MAPS["wastes"])


static func count() -> int:
	return LEVELS.size()


static func colosseum_of(n: int) -> int:
	return (n - 1) / 6 + 1


## Art script of an enemy id (static draw_portrait), used by the board tiles.
static func enemy_script(id: String) -> Script:
	match id:
		"brute":
			return DemonBrute
		"hydra":
			return HydraMutant
		"golem":
			return RockGolem
		"kharleming":
			return Kharleming
		"blinded_lord":
			return BlindedLord
	return Parasite


## The enemy shown on a level's board tile: the boss, else the toughest one in it.
static func tile_enemy(n: int) -> String:
	var lv := get_level(n)
	if String(lv.get("boss", "")) != "":
		return String(lv["boss"])
	var rank := ["parasite", "kharleming", "brute", "golem", "hydra"]
	var best := "parasite"
	for wave in lv.get("waves", []):
		for id in wave:
			if rank.find(String(id)) > rank.find(best):
				best = String(id)
	return best


## Enemy factory (all are BaseEnemy / SimpleEnemy: same system as Rotor & co).
static func make_enemy(id: String) -> BaseEnemy:
	match id:
		"parasite":
			return Parasite.new()
		"brute":
			return DemonBrute.new()
		"hydra":
			return HydraMutant.new()
		"golem":
			return RockGolem.new()
		"kharleming":
			return Kharleming.new()
		"blinded_lord":
			return BlindedLord.new()
	push_error("StoryLevels: unknown enemy '%s'" % id)
	return Parasite.new()
