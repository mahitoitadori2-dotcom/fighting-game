class_name StoryLevels
extends RefCounted
## STORY MODE level list (50 levels total; Level 50 = The Sun).
##   COLOSSEUM 1 = levels 1-6   (The Ashen Depths, boss: the Blinded Lord)
##   COLOSSEUM 2 = levels 7-12  (The Ascent, mini-boss: Architect Chorus, boss: Blasphemy Caeser)
## A level = waves of enemy GROUPS, then (boss levels) intro cutscene -> boss -> death cutscene.
##
##   waves        Array of groups; each group = Array of enemy ids (see make_enemy()).
##   boss         enemy id, or "" for a normal level
##   map          key of MAPS (backdrop, floor, walls, music)
## Optional keys (all have defaults, so Colosseum 1 needs none of them):
##   cutscene_in  full-screen StoryCutscene played from the board instead of the cave fall
##   arrive       "drop" (default: you fall in from above) or "stand" (you are already there)
##   boss_map / boss_map_title / boss_map_sub   switch to the boss arena at the boss intro
##   boss_intro   "drop" (default: lands from above) or "rise" (climbs up from below)
##   boss_pos     "right" (default: in front of you) or "center" (middle of the arena)
##   boss_music, boss_sub, boss_line, boss_color      intro title card
##   boss_death   "explode" (default), "fall" (drops out of sight) or "sink" (sinks into lava)
##   boss_death_title / boss_death_sub                death banner
##   cutscene_out full-screen StoryCutscene after the boss died (before LEVEL CLEAR)
##   sword_power  true = the Warrior's sword grows when the boss fight starts and again in phase 2

const PLAYER_CHARACTER := "warrior"      # Story Mode is Warrior only
const LEVELS_PER_COLOSSEUM := 6

## MAPS: what the arena looks / sounds like. StoryManager applies it on level start.
##   bg          HellBackground theme
##   ground      ArenaGround theme (2 Hell, 3 Geode, 4 Scrap, 5 Lab, 6 Elevator, 7 Marble, 8 Sewer, 9 Blasphemy)
##   walls       CaveWall style
##   half_width  distance from the arena centre to each wall (smaller = tighter arena)
##   music       SoundManager track for the group battles ("none" = silence)
##   fog         true = drifting green fog in front of the floor (sewers)
const MAPS := {
	# ----- Colosseum 1 -----
	"wastes": {"bg": "surface", "ground": 2, "walls": "lava", "half_width": 850.0, "music": "story_surface"},
	"geode":  {"bg": "geode", "ground": 3, "walls": "crystal", "half_width": 560.0, "music": "story_geode"},
	"hive":   {"bg": "hive", "ground": 4, "walls": "metal", "half_width": 700.0, "music": "story_hive"},
	"lair":   {"bg": "cave", "ground": 2, "walls": "lava", "half_width": 850.0, "music": "story_cave"},
	# The Blinded Lord's LABORATORY (boss arena): chemical tubes, glass chambers with
	# rotted skeletons. The level switches to it when the boss intro starts.
	"lab":    {"bg": "lab", "ground": 5, "walls": "lab", "half_width": 800.0, "music": "boss"},
	# ----- Colosseum 2 -----
	# A steel platform elevator rising up a shaft out of hell (Architect Chorus).
	"elevator":    {"bg": "elevator", "ground": 6, "walls": "shaft", "half_width": 640.0, "music": "story_ascent"},
	# HOME OF THE ENLIGHTENED ONES: bright white marble city, gold domes, halos.
	"enlightened": {"bg": "enlightened", "ground": 7, "walls": "marble", "half_width": 820.0, "music": "story_enlightened"},
	# THE SEWERS: dark brick tunnels, pipes, dirty water, green fog.
	"sewers":      {"bg": "sewer", "ground": 8, "walls": "sewer", "half_width": 760.0, "music": "story_sewers", "fog": true},
	# BLASPHEMY ARENA: volcanic temple of Blasphemy Caeser, lava falls, serpent bones.
	"blasphemy":   {"bg": "blasphemy", "ground": 9, "walls": "blasphemy", "half_width": 840.0, "music": "none"},
	# ----- Colosseum 3 -----
	# BURNING THRONE ROOM: an empty throne on fire, broken pillars, smoke and falling embers.
	"throne":       {"bg": "throne", "ground": 10, "walls": "burnt", "half_width": 780.0, "music": "story_throne"},
	# MINOR ARCHITECTIUM LAND: stone buildings, architect workshops, cranes and gears.
	"architectium": {"bg": "architectium", "ground": 11, "walls": "stone", "half_width": 840.0, "music": "story_architectium"},
	# BLAST WORKSHOP (Architectian Titan): blast furnaces, molten metal, sparks, a big open floor.
	"workshop":     {"bg": "workshop", "ground": 12, "walls": "foundry", "half_width": 840.0, "music": "story_workshop"},
	# THE GOLEM'S HALL (Architect's Golem): a vast stone hall of the Architect, glowing runes.
	"golem_hall":   {"bg": "golem_hall", "ground": 11, "walls": "rune", "half_width": 840.0, "music": "none"},
}

const LEVELS := {
	# ======================= COLOSSEUM 1: THE ASHEN DEPTHS =======================
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
		"boss_map_title": "THE LABORATORY", "boss_map_sub": "Glass chambers... and what is left of the others.",
		"intro": "The air burns. The Blinded Lord's lair.",
		"waves": [["parasite", "brute", "parasite"], ["kharleming", "kharleming", "brute"]], "boss": "blinded_lord",
		"boss_sub": "Keeper of the First Colosseum", "boss_line": "Who dares crawl into MY pit...?",
		"boss_death_sub": "The first Colosseum is yours."},

	# ======================= COLOSSEUM 2: THE ASCENT =======================
	7: {"title": "THE ELEVATOR FROM HELL", "theme": "elevator", "map": "elevator",
		"cutscene_in": "elevator", "arrive": "stand",
		"intro": "Rising out of hell... but something huge is climbing after you.",
		"waves": [], "boss": "architect_chorus",
		"boss_intro": "rise", "boss_pos": "center", "boss_music": "boss_architect",
		"boss_sub": "Mini-Boss  -  The Iron Hymn of the Shaft", "boss_color": Color(0.55, 0.9, 1.0),
		"boss_line": "WE... ARE... THE CHORUS.  YOU... DO NOT... LEAVE.",
		"boss_death": "fall", "boss_death_title": "THE ARCHITECT CHORUS LETS GO",
		"boss_death_sub": "It falls back into the dark. The elevator keeps rising..."},
	8: {"title": "HOME OF THE ENLIGHTENED ONES", "theme": "enlightened", "map": "enlightened", "arrive": "stand",
		"intro": "The elevator stops. White stone, golden light... and they do not want you here.",
		"waves": [["guard", "follower", "guard"], ["follower", "guard", "follower", "guard"]], "boss": ""},
	9: {"title": "THE GOLDEN COURT", "theme": "enlightened", "map": "enlightened",
		"intro": "Deeper into the city. The followers sing as they march.",
		"waves": [["guard", "guard", "follower"], ["follower", "follower", "guard", "guard"]], "boss": ""},
	10: {"title": "THE SEWERS", "theme": "sewer", "map": "sewers", "cutscene_in": "sewer_fall",
		"intro": "The floor of the city broke. You fell into the sewers...",
		"waves": [["crawler", "stray", "stray"]], "boss": ""},
	11: {"title": "THE ROT CHANNEL", "theme": "sewer", "map": "sewers",
		"intro": "Something old crawls in the filth. The strays smell you.",
		"waves": [["crawler", "stray", "crawler", "stray", "stray"]], "boss": ""},
	12: {"title": "BLASPHEMY CAESER", "theme": "blasphemy", "map": "blasphemy",
		"intro": "Bones of gods. Rivers of magma. A throne of serpents.",
		"waves": [], "boss": "blasphemy_caeser", "sword_power": true,
		"boss_intro": "rise", "boss_music": "boss_caeser", "boss_color": Color(1.0, 0.45, 0.2),
		"boss_map_title": "THE BLASPHEMY ARENA", "boss_map_sub": "Something enormous coils beneath the magma...",
		"boss_sub": "The God-Devouring Serpent  -  Keeper of the Second Colosseum",
		"boss_line": "I have devoured GODS.  You are barely a morsel.",
		"boss_death": "sink", "boss_death_title": "BLASPHEMY CAESER HAS FALLEN",
		"boss_death_sub": "The second Colosseum is yours.", "cutscene_out": "corpse_climb"},

	# ======================= COLOSSEUM 3: THE BURNING CROWN =======================
	13: {"title": "THE BURNING THRONE", "theme": "throne", "map": "throne",
		"cutscene_in": "throne_wake", "arrive": "stand", "ambush": true,
		"intro": "You wake in an empty throne room. It is on fire... and something moves above you.",
		"waves": [["copper", "sparkling", "sparkling"], ["copper", "sparkling", "copper", "sparkling", "sparkling"]], "boss": ""},
	14: {"title": "THE ATOMIC CREATION", "theme": "throne", "map": "throne",
		"intro": "A blinding green light behind the throne... the Atomic Creation wakes.",
		"waves": [["sparkling", "atomic", "sparkling", "sparkling"]], "boss": ""},
	15: {"title": "MINOR ARCHITECTIUM", "theme": "architectium", "map": "architectium",
		"intro": "Beyond the throne: the land of the Minor Architectium. Workshops, gears... and its warriors.",
		"waves": [["warrior_a", "warrior_a"], ["warrior_a", "warrior_a", "warrior_a"]], "boss": ""},
	16: {"title": "THE GEARWORKS", "theme": "architectium", "map": "architectium",
		"intro": "Deeper into the Architectium. The warriors form ranks.",
		"waves": [["warrior_a", "warrior_a", "warrior_a"], ["warrior_a", "warrior_a", "warrior_a", "warrior_a"]], "boss": ""},
	17: {"title": "THE BLAST WORKSHOP", "theme": "workshop", "map": "workshop",
		"intro": "Blast furnaces roar. Something enormous hammers the anvil.",
		"waves": [], "boss": "titan",
		"boss_music": "boss_titan", "boss_color": Color(1.0, 0.6, 0.2),
		"boss_sub": "Mini-Boss  -  Forge-Guardian of the Architectium",
		"boss_line": "THE FORGE...  NEVER...  COOLS.",
		"boss_death_title": "THE ARCHITECTIAN TITAN HAS FALLEN", "boss_death_sub": "The furnaces go quiet."},
	18: {"title": "THE ARCHITECT'S GOLEM", "theme": "golem_hall", "map": "golem_hall",
		"intro": "A hall of the Architect himself. Runes glow in the stone floor.",
		"waves": [], "boss": "arch_golem",
		"boss_intro": "rise", "boss_music": "boss_golem", "boss_color": Color(0.4, 0.85, 1.0),
		"boss_map_title": "THE GOLEM'S HALL", "boss_map_sub": "The runes in the floor light up one by one...",
		"boss_sub": "Built by the Architect  -  Keeper of the Third Colosseum",
		"boss_line": "...INTRUDER.   ...DISMANTLE.",
		"boss_death": "sink", "boss_death_title": "THE ARCHITECT'S GOLEM CRUMBLES",
		"boss_death_sub": "The runes go dark. The third Colosseum is yours."},
}


static func get_level(n: int) -> Dictionary:
	return LEVELS.get(clampi(n, 1, LEVELS.size()), LEVELS[1])


static func map_of(n: int) -> Dictionary:
	return MAPS.get(String(get_level(n).get("map", "wastes")), MAPS["wastes"])


static func count() -> int:
	return LEVELS.size()


## Playable character of a level: "warrior" (Colosseums 1-3) or "architect" (Colosseum 4).
static func hero_of(n: int) -> String:
	return String(get_level(n).get("hero", PLAYER_CHARACTER))


static func colosseum_of(n: int) -> int:
	return (n - 1) / LEVELS_PER_COLOSSEUM + 1


## First level of a Colosseum (1, 7, 13...).
static func first_of(colosseum: int) -> int:
	return (colosseum - 1) * LEVELS_PER_COLOSSEUM + 1


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
		"architect_chorus":
			return ArchitectChorus
		"guard":
			return EnlightenedGuard
		"follower":
			return EnlightenedFollower
		"crawler":
			return GodCrawler
		"stray":
			return RotStray
		"blasphemy_caeser":
			return BlasphemyCaeser
		"copper":
			return CopperCorpse
		"sparkling":
			return Sparkling
		"atomic":
			return AtomicCreation
		"warrior_a":
			return ArchitectianWarrior
		"titan":
			return ArchitectianTitan
		"arch_golem":
			return ArchitectsGolem
	return Parasite


## The enemy shown on a level's board tile: the boss, else the toughest one in it.
static func tile_enemy(n: int) -> String:
	var lv := get_level(n)
	if String(lv.get("boss", "")) != "":
		return String(lv["boss"])
	var rank := ["parasite", "kharleming", "stray", "sparkling", "follower", "brute", "guard", "copper", "warrior_a", "crawler",
		"golem", "hydra", "atomic"]
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
		"architect_chorus":
			return ArchitectChorus.new()
		"guard":
			return EnlightenedGuard.new()
		"follower":
			return EnlightenedFollower.new()
		"crawler":
			return GodCrawler.new()
		"stray":
			return RotStray.new()
		"blasphemy_caeser":
			return BlasphemyCaeser.new()
		"copper":
			return CopperCorpse.new()
		"sparkling":
			return Sparkling.new()
		"atomic":
			return AtomicCreation.new()
		"warrior_a":
			return ArchitectianWarrior.new()
		"titan":
			return ArchitectianTitan.new()
		"arch_golem":
			return ArchitectsGolem.new()
	push_error("StoryLevels: unknown enemy '%s'" % id)
	return Parasite.new()
