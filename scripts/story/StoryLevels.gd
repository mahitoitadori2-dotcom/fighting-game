class_name StoryLevels
extends RefCounted
## STORY MODE level list (Level 50 = The Sun). Colosseums have DIFFERENT sizes (COLOSSEUM_SIZES):
##   COLOSSEUM 1 = levels 1-6    (The Ashen Depths, boss: the Blinded Lord)
##   COLOSSEUM 2 = levels 7-15   (The Ascent, mini-boss: Architect Chorus, boss: Blasphemy Caeser)
##   COLOSSEUM 3 = levels 16-26  (The Burning Crown, mini-boss: Architectian Titan, boss: Architect's Golem)
##   COLOSSEUM 4 = levels 27-34  (The Void Below, OPTIONAL level 32: The Shining, boss: Void Massacre)
## A level = waves of enemy GROUPS, then (boss levels) intro cutscene -> boss -> death cutscene.
##
##   waves        Array of groups; each group = Array of enemy ids (see make_enemy()).
##   boss         enemy id, or "" for a normal level
##   map          key of MAPS (backdrop, floor, walls, music)
## Optional keys (all have defaults, so most levels need none of them):
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
##   optional     true = may be skipped: beating the level before it also unlocks the one after
##   altar        true = The Shining's altar (kill it or leave through the dark gate)
##   void_mod     true = void enemies are weakened / the Massacre strengthened by the Shining choice
##   tile         enemy shown on the board tile (default: the boss / the toughest enemy)

const PLAYER_CHARACTER := "warrior"      # Story Mode is Warrior only (Colosseums 1-3)
## Levels per Colosseum. Colosseums past this list (not made yet) use DEFAULT_SIZE.
const COLOSSEUM_SIZES := [6, 9, 11, 8]
const DEFAULT_SIZE := 6

## Weapon variants of the soldier enemies (ArmedSoldier kit): id -> [base id, weapon].
const VARIANTS := {
	"guard_sword": ["guard", "short_sword"], "guard_hammer": ["guard", "hammer"],
	"guard_shield": ["guard", "greatshield"], "guard_bow": ["guard", "bow"],
	"warrior_a_sword": ["warrior_a", "short_sword"], "warrior_a_spear": ["warrior_a", "spear"],
	"warrior_a_shield": ["warrior_a", "greatshield"], "warrior_a_bow": ["warrior_a", "bow"],
}

## MAPS: what the arena looks / sounds like. StoryManager applies it on level start.
##   bg          HellBackground theme
##   ground      ArenaGround theme (2 Hell, 3 Geode, 4 Scrap, 5 Lab, 6 Elevator, 7 Marble, 8 Sewer, 9 Blasphemy)
##   walls       CaveWall style
##   half_width  distance from the arena centre to each wall (smaller = tighter arena)
##   music       SoundManager track for the group battles ("none" = silence)
##   fog         true = drifting green fog in front of the floor (sewers)
##   solid       true = underground: solid rock fills the space under the floor (no floating island)
##   zone        name of the area on the board
const MAPS := {
	# ----- Colosseum 1 -----
	"wastes": {"bg": "surface", "ground": 2, "walls": "lava", "half_width": 850.0, "music": "story_surface", "zone": "THE ASHEN WASTES"},
	"geode":  {"bg": "geode", "ground": 3, "walls": "crystal", "half_width": 560.0, "music": "story_geode", "solid": true, "zone": "THE GEODE CAVERN"},
	"hive":   {"bg": "hive", "ground": 4, "walls": "metal", "half_width": 700.0, "music": "story_hive", "solid": true, "zone": "THE HIVE"},
	"lair":   {"bg": "cave", "ground": 2, "walls": "lava", "half_width": 850.0, "music": "story_cave", "solid": true, "zone": "THE LAVA LAIR"},
	# The Blinded Lord's LABORATORY (boss arena): chemical tubes, glass chambers with
	# rotted skeletons. The level switches to it when the boss intro starts.
	"lab":    {"bg": "lab", "ground": 5, "walls": "lab", "half_width": 800.0, "music": "boss", "solid": true, "zone": "THE LABORATORY"},
	# ----- Colosseum 2 -----
	# A steel platform elevator rising up a shaft out of hell (Architect Chorus).
	"elevator":    {"bg": "elevator", "ground": 6, "walls": "shaft", "half_width": 640.0, "music": "story_ascent", "zone": "THE ELEVATOR"},
	# HOME OF THE ENLIGHTENED ONES: bright white marble city, gold domes, halos.
	"enlightened": {"bg": "enlightened", "ground": 7, "walls": "marble", "half_width": 820.0, "music": "story_enlightened", "zone": "HOME OF THE ENLIGHTENED"},
	# THE SEWERS: dark brick tunnels, pipes, dirty water, green fog.
	"sewers":      {"bg": "sewer", "ground": 8, "walls": "sewer", "half_width": 760.0, "music": "story_sewers", "fog": true, "solid": true, "zone": "THE SEWERS"},
	# BLASPHEMY ARENA: volcanic temple of Blasphemy Caeser, lava falls, serpent bones.
	"blasphemy":   {"bg": "blasphemy", "ground": 9, "walls": "blasphemy", "half_width": 840.0, "music": "none", "zone": "BLASPHEMY"},
	# The same temple before the serpent wakes (group battles need music).
	"magma_stair": {"bg": "blasphemy", "ground": 9, "walls": "blasphemy", "half_width": 840.0, "music": "story_cave", "zone": "BLASPHEMY"},
	# ----- Colosseum 3 -----
	# BURNING THRONE ROOM: an empty throne on fire, broken pillars, smoke and falling embers.
	"throne":       {"bg": "throne", "ground": 10, "walls": "burnt", "half_width": 780.0, "music": "story_throne", "zone": "THE BURNING THRONE"},
	# MINOR ARCHITECTIUM LAND: stone buildings, architect workshops, cranes and gears.
	"architectium": {"bg": "architectium", "ground": 11, "walls": "stone", "half_width": 840.0, "music": "story_architectium", "zone": "MINOR ARCHITECTIUM"},
	# BLAST WORKSHOP (Architectian Titan): blast furnaces, molten metal, sparks, a big open floor.
	"workshop":     {"bg": "workshop", "ground": 12, "walls": "foundry", "half_width": 840.0, "music": "story_workshop", "zone": "BLAST WORKSHOP"},
	# THE GOLEM'S HALL (Architect's Golem): a vast stone hall of the Architect, glowing runes.
	"golem_hall":   {"bg": "golem_hall", "ground": 11, "walls": "rune", "half_width": 840.0, "music": "none", "zone": "THE GOLEM'S HALL"},
	# The same hall, guarded (group battles need music).
	"rune_gallery": {"bg": "golem_hall", "ground": 11, "walls": "rune", "half_width": 840.0, "music": "story_architectium", "zone": "THE GOLEM'S HALL"},
	# ----- Colosseum 4 (you play as the ARCHITECT) -----
	# OVERGROUND DARK CAVE: dark cave, rocks, dim light from the entrance.
	"dark_cave":    {"bg": "dark_cave", "ground": 13, "walls": "dark", "half_width": 800.0, "music": "story_darkcave", "solid": true, "zone": "THE DARK CAVE"},
	# THE VOID: dark nothing, the floor is a pile of dark bones, bones everywhere.
	"void":         {"bg": "void", "ground": 14, "walls": "bone", "half_width": 820.0, "music": "story_void", "zone": "THE VOID"},
	# THE ALTAR: a glowing altar of light in the dark void (The Shining).
	"altar":        {"bg": "altar", "ground": 14, "walls": "bone", "half_width": 820.0, "music": "story_altar", "zone": "THE ALTAR"},
	# THE SPIDER LAIR: webs everywhere, victims hanging from the ceiling in cocoons.
	"spider_lair":  {"bg": "spider_lair", "ground": 14, "walls": "web", "half_width": 840.0, "music": "story_void", "zone": "THE SPIDER LAIR"},
}

const LEVELS := {
	# ======================= COLOSSEUM 1: THE ASHEN DEPTHS (1-6) =======================
	# Wastes x2, Geode x1, Hive x1, Lava Lair x2 (the last one is the boss)
	1: {"title": "THE ASHEN GATE", "theme": "surface", "map": "wastes",
		"intro": "Something stirs in the ash...",
		"waves": [["parasite"], ["parasite", "parasite"]], "boss": ""},
	2: {"title": "THE MUTANT MARCH", "theme": "surface", "map": "wastes",
		"intro": "Parasites, Demon Brutes... and something big breathing behind them.",
		"waves": [["parasite", "brute", "parasite"], ["brute", "hydra"]], "boss": ""},
	3: {"title": "THE GEODE CAVERN", "theme": "cave", "map": "geode",
		"intro": "The ground gave way. You fell into a cavern of crystal.",
		"waves": [["parasite", "parasite"], ["golem"]], "boss": ""},
	4: {"title": "THE KHARLEMING HIVE", "theme": "cave", "map": "hive",
		"intro": "Rusted scrap, blinking eyes, clicking legs on the walls...",
		"waves": [["kharleming", "kharleming", "kharleming"], ["kharleming", "kharleming", "kharleming", "kharleming"]], "boss": ""},
	5: {"title": "THE BURNING TUNNELS", "theme": "cave", "map": "lair",
		"intro": "Lava light at the end of the tunnel. Everything down here wants you dead.",
		"waves": [["kharleming", "brute", "kharleming"], ["parasite", "hydra", "parasite"]], "boss": ""},
	6: {"title": "THE BLINDED LORD", "theme": "cave", "map": "lair", "boss_map": "lab",
		"boss_map_title": "THE LABORATORY", "boss_map_sub": "Glass chambers... and what is left of the others.",
		"intro": "The air burns. The Blinded Lord's lair.",
		"waves": [["parasite", "brute", "parasite"], ["kharleming", "kharleming", "brute"]], "boss": "blinded_lord",
		"boss_sub": "Keeper of the First Colosseum", "boss_line": "Who dares crawl into MY pit...?",
		"boss_death_sub": "The first Colosseum is yours."},

	# ======================= COLOSSEUM 2: THE ASCENT (7-15) =======================
	# Elevator x2, Enlightened city x3, Sewers x2, Blasphemy x2
	7: {"title": "THE ELEVATOR SHAFT", "theme": "elevator", "map": "elevator",
		"cutscene_in": "elevator", "arrive": "stand",
		"intro": "Rising out of hell... and things are climbing the shaft after you.",
		"waves": [["kharleming", "kharleming", "parasite"], ["kharleming", "kharleming", "kharleming"]], "boss": ""},
	8: {"title": "THE ELEVATOR FROM HELL", "theme": "elevator", "map": "elevator", "arrive": "stand",
		"intro": "Halfway up. The whole shaft shakes... something huge is climbing after you.",
		"waves": [], "boss": "architect_chorus",
		"boss_intro": "rise", "boss_pos": "center", "boss_music": "boss_architect",
		"boss_sub": "Mini-Boss  -  The Iron Hymn of the Shaft", "boss_color": Color(0.55, 0.9, 1.0),
		"boss_line": "WE... ARE... THE CHORUS.  YOU... DO NOT... LEAVE.",
		"boss_death": "fall", "boss_death_title": "THE ARCHITECT CHORUS LETS GO",
		"boss_death_sub": "It falls back into the dark. The elevator keeps rising..."},
	9: {"title": "HOME OF THE ENLIGHTENED ONES", "theme": "enlightened", "map": "enlightened", "arrive": "stand",
		"intro": "The elevator stops. White stone, golden light... and they do not want you here.",
		"waves": [["guard", "follower", "guard"], ["guard_sword", "follower", "guard_sword"]], "boss": ""},
	10: {"title": "THE GOLDEN COURT", "theme": "enlightened", "map": "enlightened",
		"intro": "Deeper into the city. Smiters with golden hammers, archers on the steps.",
		"waves": [["guard_hammer", "follower", "guard"], ["guard_bow", "guard_sword", "guard_hammer"]], "boss": ""},
	11: {"title": "THE HALL OF SHIELDS", "theme": "enlightened", "map": "enlightened",
		"intro": "A wall of golden shields. Get behind them - or wait for them to strike.",
		"waves": [["guard_shield", "guard_bow", "guard_bow"], ["guard_shield", "guard_hammer", "follower", "guard_bow"]], "boss": ""},
	12: {"title": "THE SEWERS", "theme": "sewer", "map": "sewers", "cutscene_in": "sewer_fall",
		"intro": "The floor of the city broke. You fell into the sewers...",
		"waves": [["crawler", "stray", "stray"]], "boss": ""},
	13: {"title": "THE ROT CHANNEL", "theme": "sewer", "map": "sewers",
		"intro": "Something old crawls in the filth. The strays smell you.",
		"waves": [["crawler", "stray", "crawler", "stray", "stray"]], "boss": ""},
	14: {"title": "THE MAGMA STAIR", "theme": "blasphemy", "map": "magma_stair",
		"intro": "Out of the sewers, up a stair of black glass. Hell's beasts guard the serpent's temple.",
		"waves": [["brute", "hydra"], ["parasite", "brute", "brute", "parasite"]], "boss": ""},
	15: {"title": "BLASPHEMY CAESER", "theme": "blasphemy", "map": "blasphemy",
		"intro": "Bones of gods. Rivers of magma. A throne of serpents.",
		"waves": [], "boss": "blasphemy_caeser", "sword_power": true,
		"boss_intro": "rise", "boss_music": "boss_caeser", "boss_color": Color(1.0, 0.45, 0.2),
		"boss_map_title": "THE BLASPHEMY ARENA", "boss_map_sub": "Something enormous coils beneath the magma...",
		"boss_sub": "The God-Devouring Serpent  -  Keeper of the Second Colosseum",
		"boss_line": "I have devoured GODS.  You are barely a morsel.",
		"boss_death": "sink", "boss_death_title": "BLASPHEMY CAESER HAS FALLEN",
		"boss_death_sub": "The second Colosseum is yours.", "cutscene_out": "corpse_climb"},

	# ======================= COLOSSEUM 3: THE BURNING CROWN (16-26) =======================
	# Burning Throne x3, Architectium x3, Blast Workshop x3, Golem's Hall x2
	16: {"title": "THE BURNING THRONE", "theme": "throne", "map": "throne",
		"cutscene_in": "throne_wake", "arrive": "stand", "ambush": true,
		"intro": "You wake in an empty throne room. It is on fire... and something moves above you.",
		"waves": [["copper", "sparkling", "sparkling"], ["copper", "sparkling", "copper", "sparkling", "sparkling"]], "boss": ""},
	17: {"title": "THE ATOMIC CREATION", "theme": "throne", "map": "throne",
		"intro": "A blinding green light behind the throne... the Atomic Creation wakes.",
		"waves": [["sparkling", "atomic", "sparkling", "sparkling"]], "boss": ""},
	18: {"title": "THE CINDER GALLERY", "theme": "throne", "map": "throne",
		"intro": "Burning portraits of a forgotten king. His dead guard still stands watch.",
		"waves": [["copper", "sparkling", "copper"], ["sparkling", "sparkling", "copper", "copper"]], "boss": ""},
	19: {"title": "MINOR ARCHITECTIUM", "theme": "architectium", "map": "architectium",
		"intro": "Beyond the throne: the land of the Minor Architectium. Workshops, gears... and its warriors.",
		"waves": [["warrior_a", "warrior_a"], ["warrior_a_sword", "warrior_a", "warrior_a_sword"]], "boss": ""},
	20: {"title": "THE GEARWORKS", "theme": "architectium", "map": "architectium",
		"intro": "Deeper into the Architectium. Lancers and archers join the ranks.",
		"waves": [["warrior_a_spear", "warrior_a", "warrior_a_spear"], ["warrior_a_bow", "warrior_a_sword", "warrior_a"]], "boss": ""},
	21: {"title": "THE BULWARK LINE", "theme": "architectium", "map": "architectium",
		"intro": "Tower shields lock together. Archers fire from behind them.",
		"waves": [["warrior_a_shield", "warrior_a_bow", "warrior_a_bow"], ["warrior_a_shield", "warrior_a_shield", "warrior_a_spear", "warrior_a_bow"]], "boss": ""},
	22: {"title": "THE FORGE FLOOR", "theme": "workshop", "map": "workshop",
		"intro": "Into the furnaces. Sparks fly off the anvils - and some of them are alive.",
		"waves": [["warrior_a", "sparkling", "warrior_a"], ["copper", "warrior_a_spear", "sparkling", "warrior_a"]], "boss": ""},
	23: {"title": "THE SMELTER", "theme": "workshop", "map": "workshop",
		"intro": "Molten metal pours from the ceiling. The forge guard holds the last door.",
		"waves": [["warrior_a_shield", "warrior_a", "sparkling"], ["warrior_a_bow", "warrior_a_bow", "copper", "warrior_a_sword"]], "boss": ""},
	24: {"title": "THE BLAST WORKSHOP", "theme": "workshop", "map": "workshop",
		"intro": "Blast furnaces roar. Something enormous hammers the anvil.",
		"waves": [], "boss": "titan",
		"boss_music": "boss_titan", "boss_color": Color(1.0, 0.6, 0.2),
		"boss_sub": "Mini-Boss  -  Forge-Guardian of the Architectium",
		"boss_line": "THE FORGE...  NEVER...  COOLS.",
		"boss_death_title": "THE ARCHITECTIAN TITAN HAS FALLEN", "boss_death_sub": "The furnaces go quiet."},
	25: {"title": "THE RUNE GALLERY", "theme": "golem_hall", "map": "rune_gallery",
		"intro": "The Architect's own guard watches the hall. The runes hum under your feet.",
		"waves": [["warrior_a_spear", "warrior_a_shield", "warrior_a_spear"], ["warrior_a_bow", "warrior_a", "warrior_a_shield", "warrior_a_sword"]], "boss": ""},
	26: {"title": "THE ARCHITECT'S GOLEM", "theme": "golem_hall", "map": "golem_hall",
		"intro": "A hall of the Architect himself. Runes glow in the stone floor.",
		"waves": [], "boss": "arch_golem",
		"boss_intro": "rise", "boss_music": "boss_golem", "boss_color": Color(0.4, 0.85, 1.0),
		"boss_map_title": "THE GOLEM'S HALL", "boss_map_sub": "The runes in the floor light up one by one...",
		"boss_sub": "Built by the Architect  -  Keeper of the Third Colosseum",
		"boss_line": "...INTRUDER.   ...DISMANTLE.",
		"boss_death": "sink", "boss_death_title": "THE ARCHITECT'S GOLEM CRUMBLES",
		"boss_death_sub": "The runes go dark. The third Colosseum is yours."},

	# ======================= COLOSSEUM 4: THE VOID BELOW (27-34, you are the ARCHITECT) =======================
	# Dark Cave x2, Void x3, Altar x1 (optional), Spider Lair x2
	27: {"title": "THE DARK CAVE", "theme": "dark_cave", "map": "dark_cave", "hero": "architect",
		"cutscene_in": "cave_roll",
		"intro": "You rolled all the way down into a dark cave. Something black crawls on the rocks.",
		"waves": [["crawling", "crawling", "crawling"], ["crawling", "crawling", "crawling", "crawling"]], "boss": ""},
	28: {"title": "THE VOID ESCAPIST", "theme": "dark_cave", "map": "dark_cave", "hero": "architect",
		"intro": "A black ghost slides through the cave floor... the Void Escapist.",
		"waves": [["escapist", "crawling", "crawling"], ["escapist", "escapist", "crawling"]], "boss": "",
		"floor_break": true, "cutscene_out": "void_fall"},
	29: {"title": "THE VOID", "theme": "void", "map": "void", "hero": "architect",
		"intro": "Nothing but dark, and a floor made of bones. Lost souls drift here.",
		"waves": [["void_soul", "tentacle"], ["void_soul", "void_soul", "tentacle"]], "boss": ""},
	30: {"title": "THE BONE SEA", "theme": "void", "map": "void", "hero": "architect",
		"intro": "The bones go on forever. So do the tentacles.",
		"waves": [["tentacle", "void_soul", "tentacle"], ["void_soul", "tentacle", "void_soul", "tentacle"]], "boss": ""},
	31: {"title": "THE HOLLOW MASKER", "theme": "void", "map": "void", "hero": "architect",
		"intro": "A tall thing in a white mask watches you from the dark.",
		"waves": [["masker"], ["masker", "void_soul", "tentacle"]], "boss": ""},
	# OPTIONAL: kill The Shining (the Void gets weaker) or walk out through the dark gate /
	# skip the level (the Void Massacre gets stronger). The choice is saved (StoryProgress).
	32: {"title": "THE SHINING", "theme": "altar", "map": "altar", "hero": "architect",
		"optional": true, "altar": true, "tile": "shining",
		"intro": "OPTIONAL.  A light in the dark: an altar... and something made of light floating above it.",
		"waves": [], "boss": ""},
	33: {"title": "THE WEB TUNNELS", "theme": "spider_lair", "map": "spider_lair", "hero": "architect", "void_mod": true,
		"intro": "Webs thick as rope. The cocoons are still moving.",
		"waves": [["crawling", "crawling", "masker"], ["tentacle", "void_soul", "crawling", "crawling"]], "boss": ""},
	34: {"title": "THE VOID MASSACRE", "theme": "spider_lair", "map": "spider_lair", "hero": "architect", "void_mod": true,
		"intro": "The heart of the lair. Sixteen legs click somewhere above you.",
		"waves": [["masker", "masker"]], "boss": "void_massacre",
		"boss_music": "boss_massacre", "boss_color": Color(0.75, 0.5, 1.0),
		"boss_sub": "Sixteen eyes, sixteen legs  -  Keeper of the Fourth Colosseum",
		"boss_line": "*the clicking of sixteen legs*",
		"boss_death_title": "THE VOID MASSACRE IS DEAD", "boss_death_sub": "The webs go still. The fourth Colosseum is yours."},
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


static func is_optional(n: int) -> bool:
	return LEVELS.has(n) and bool(LEVELS[n].get("optional", false))


static func size_of(colosseum: int) -> int:
	if colosseum >= 1 and colosseum <= COLOSSEUM_SIZES.size():
		return int(COLOSSEUM_SIZES[colosseum - 1])
	return DEFAULT_SIZE


## First level of a Colosseum (1, 7, 16, 27...).
static func first_of(colosseum: int) -> int:
	var n := 1
	for c in range(1, maxi(colosseum, 1)):
		n += size_of(c)
	return n


## Last (boss) level of a Colosseum (6, 15, 26, 34...).
static func last_of(colosseum: int) -> int:
	return first_of(colosseum) + size_of(colosseum) - 1


static func colosseum_of(n: int) -> int:
	var c := 1
	while n > last_of(c):
		c += 1
	return c


## Base enemy id of a weapon variant ("guard_bow" -> "guard"); other ids unchanged.
static func base_id(id: String) -> String:
	return String(VARIANTS[id][0]) if VARIANTS.has(id) else id


## Weapon of a variant id ("guard_bow" -> "bow"), "" for everything else.
static func weapon_of(id: String) -> String:
	return String(VARIANTS[id][1]) if VARIANTS.has(id) else ""


## Art script of an enemy id (static draw_portrait), used by the board tiles.
static func enemy_script(id: String) -> Script:
	match base_id(id):
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
		"crawling":
			return BlackCrawling
		"escapist":
			return VoidEscapist
		"void_soul":
			return VoidSoul
		"tentacle":
			return VoidTentacle
		"masker":
			return HollowMasker
		"shining":
			return TheShining
		"void_massacre":
			return VoidMassacre
	return Parasite


## Draws an enemy's portrait (weapon variants included) at the canvas' current transform.
static func draw_portrait(c: CanvasItem, id: String, t: float) -> void:
	var art := enemy_script(id)
	var w := weapon_of(id)
	if w != "":
		art.call("draw_portrait_weapon", c, t, w)
	else:
		art.call("draw_portrait", c, t)


## The enemy shown on a level's board tile: "tile", else the boss, else the toughest one in it.
static func tile_enemy(n: int) -> String:
	var lv := get_level(n)
	if String(lv.get("tile", "")) != "":
		return String(lv["tile"])
	if String(lv.get("boss", "")) != "":
		return String(lv["boss"])
	var rank := ["parasite", "kharleming", "stray", "sparkling", "follower", "guard_bow", "warrior_a_bow", "brute",
		"guard", "guard_sword", "copper", "warrior_a", "warrior_a_sword", "warrior_a_spear", "guard_hammer", "crawler",
		"guard_shield", "warrior_a_shield", "golem", "hydra", "atomic", "crawling", "void_soul", "escapist", "tentacle", "masker"]
	var best := "parasite"
	for wave in lv.get("waves", []):
		for id in wave:
			if rank.find(String(id)) > rank.find(best):
				best = String(id)
	return best


## Enemy factory (all are BaseEnemy / SimpleEnemy: same system as Rotor & co).
static func make_enemy(id: String) -> BaseEnemy:
	if VARIANTS.has(id):
		var soldier := make_enemy(base_id(id)) as ArmedSoldier
		soldier.weapon = weapon_of(id)
		return soldier
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
		"crawling":
			return BlackCrawling.new()
		"escapist":
			return VoidEscapist.new()
		"void_soul":
			return VoidSoul.new()
		"tentacle":
			return VoidTentacle.new()
		"masker":
			return HollowMasker.new()
		"shining":
			return TheShining.new()
		"void_massacre":
			return VoidMassacre.new()
	push_error("StoryLevels: unknown enemy '%s'" % id)
	return Parasite.new()
