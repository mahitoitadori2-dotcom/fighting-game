class_name StoryLevels
extends RefCounted
## STORY MODE level list (Level 50 = The Sun). Colosseums have DIFFERENT sizes (COLOSSEUM_SIZES):
##   COLOSSEUM 1 = levels 1-6    (The Ashen Depths, boss: the Blinded Lord)
##   COLOSSEUM 2 = levels 7-15   (The Ascent, mini-boss: Architect Chorus, boss: Blasphemy Caeser)
##   COLOSSEUM 3 = levels 16-26  (The Burning Crown, mini-boss: Forge Mother, boss: Architect's Golem)
##   COLOSSEUM 4 = levels 27-34  (The Void Below, OPTIONAL level 32: The Shining, boss: Void Massacre)
##   COLOSSEUM 5 = levels 35-50  (The Final Ascent: pick Warrior or Architect, the other is your CPU
##                               partner; a COIN FLIP adds enemies every level; 7 bosses up to THE SUN)
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
##   hero         "warrior" (default), "architect", or "choice" (Colosseum 5: the hero you picked)
##   partner      true = the other hero fights beside you as a CPU partner (revives when it falls)
##   coin_flip    true = coin flip at the start: HEADS 2 Ambushers / TAILS Devilish Grin + Pained One
##   quick_boss   true = NO pre-fight: straight into the boss (The Sun)
##   finale       true = the boss ends in the SunFinale sequence instead of a death cutscene

const PLAYER_CHARACTER := "warrior"      # Story Mode is Warrior only (Colosseums 1-3)
## Levels per Colosseum. Colosseums past this list (not made yet) use DEFAULT_SIZE.
const COLOSSEUM_SIZES := [6, 9, 11, 8, 16]
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
	# BLAST WORKSHOP (Forge Mother): blast furnaces, molten metal, sparks, a big open floor.
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
	# ----- Colosseum 5: the road (group battles) -----
	# THE THORNWOOD: a dead forest of black thorns under a blood-red sky.
	"thornwood":    {"bg": "thornwood", "ground": 22, "walls": "thorn", "half_width": 820.0, "music": "story_darkcave", "zone": "THE THORNWOOD"},
	# THE FALLEN RUINS: broken temples and aqueducts under a huge pale moon.
	"ruins":        {"bg": "fallen_ruins", "ground": 23, "walls": "ruin", "half_width": 820.0, "music": "story_throne", "zone": "THE FALLEN RUINS"},
	# THE FOOTHILLS: windy mountain slopes, snow, the peak and its light far above.
	"foothills":    {"bg": "foothills", "ground": 24, "walls": "cliff", "half_width": 820.0, "music": "story_ascent", "zone": "THE FOOTHILLS"},
	# ----- Colosseum 5: one UNIQUE arena per boss -----
	# CHILD WIELDING NEEDLE: the Silk Loom, an attic of giant spools and silk curtains, moonlight.
	"silk_loom":    {"bg": "silk_loom", "ground": 15, "walls": "loom", "half_width": 760.0, "music": "story_altar", "zone": "THE SILK LOOM"},
	# THE BROTHERS: the Mirror Hall, a perfectly symmetrical black-and-white hall.
	"mirror_hall":  {"bg": "mirror_hall", "ground": 16, "walls": "mirror", "half_width": 780.0, "music": "story_enlightened", "zone": "THE MIRROR HALL"},
	# ANIMAL LORD: the Stitched Den, hides, bones and stitched carcasses hanging from hooks.
	"beast_den":    {"bg": "beast_den", "ground": 17, "walls": "den", "half_width": 820.0, "music": "story_hive", "solid": true, "zone": "THE STITCHED DEN"},
	# EXECUTOR: the Execution Ground, gallows, chopping blocks, purple fog, a blood moon.
	"gallows":      {"bg": "gallows", "ground": 18, "walls": "gallows", "half_width": 820.0, "music": "story_void", "zone": "THE EXECUTION GROUND"},
	# MOTHER NATURE: the Heart of Nature, a giant world tree in four seasons at once.
	"world_tree":   {"bg": "world_tree", "ground": 19, "walls": "roots", "half_width": 860.0, "music": "story_geode", "zone": "THE HEART OF NATURE"},
	# THE FALSE GOD: the Ashen Cathedral, black stone, burnt pews, a burning altar, ash falling.
	"ash_cathedral": {"bg": "ash_cathedral", "ground": 25, "walls": "cathedral", "half_width": 840.0, "music": "story_throne", "zone": "THE ASHEN CATHEDRAL"},
	# SATAN: his Mountain Cave, black rock, rivers of lava, a throne of horns.
	"satan_cave":   {"bg": "satan_cave", "ground": 20, "walls": "hellrock", "half_width": 860.0, "music": "story_cave", "solid": true, "zone": "SATAN'S CAVE"},
	# THE SUN: the Sun Peak, above the clouds, white-gold stone, blinding sky.
	"sun_peak":     {"bg": "sun_peak", "ground": 21, "walls": "peak", "half_width": 880.0, "music": "none", "zone": "THE SUN PEAK"},
	# ----- BOSS EXTENSIONS (ExtBackdrops.gd): a fight arena + a UNIQUE boss arena each -----
	# BC: down into Blasphemy Caeser's crypts / his tomb
	"crypts":        {"bg": "caeser_crypts", "ground": 9, "walls": "blasphemy", "half_width": 800.0, "music": "story_cave", "solid": true, "zone": "THE CAESER'S CRYPTS"},
	"caeser_tomb":   {"bg": "caeser_tomb", "ground": 14, "walls": "bone", "half_width": 820.0, "music": "none", "solid": true, "zone": "THE CAESER'S TOMB"},
	# AG: up from the Golem's Hall into the Saint Rocks sanctuary
	"saint_rocks":   {"bg": "saint_rocks", "ground": 11, "walls": "rune", "half_width": 840.0, "music": "story_altar", "zone": "THE SAINT ROCKS"},
	"saint_sanctum": {"bg": "saint_sanctum", "ground": 11, "walls": "rune", "half_width": 860.0, "music": "none", "zone": "THE SAINT SANCTUM"},
	# VM: deeper into the Void
	"deep_void":     {"bg": "deep_void", "ground": 14, "walls": "web", "half_width": 820.0, "music": "story_void", "zone": "THE DEEP VOID"},
	"horrid_nest":   {"bg": "horrid_nest", "ground": 14, "walls": "web", "half_width": 880.0, "music": "none", "zone": "THE HORRID NEST"},
	# AC: the nuclear reactor after the explosion - a radioactive wasteland
	"reactor_waste": {"bg": "reactor_waste", "ground": 5, "walls": "lab", "half_width": 840.0, "music": "story_hive", "zone": "THE REACTOR WASTE"},
	"reactor_core":  {"bg": "reactor_core", "ground": 4, "walls": "metal", "half_width": 860.0, "music": "none", "solid": true, "zone": "THE REACTOR CORE"},
	# FM: The Forge, beyond the Forge Mother's Blast Workshop
	"the_forge":     {"bg": "the_forge", "ground": 12, "walls": "foundry", "half_width": 840.0, "music": "story_workshop", "zone": "THE FORGE"},
	"forge_heart":   {"bg": "forge_heart", "ground": 12, "walls": "foundry", "half_width": 860.0, "music": "none", "zone": "THE HEART OF THE FORGE"},
}

# ======================= BOSS EXTENSION LEVELS =======================
## After a boss is beaten, 3 extra levels unlock that go DOWN or UP from its arena: 2 enemy
## levels + 1 final boss. Code = boss initials + number (BC2, BC3, BC4...). Played with the
## Warrior OR the Architect (picked in the extension menu; NOT duo - duo is Colosseum 5 only).
## Internal level numbers start at EXT_BASE so they never collide with Colosseum levels.
##   parent   the Colosseum level whose boss unlocks it      page   board page it is shown on
##   dir      "down" / "up" / "beyond" (where it leads)       first  internal number of the 1st level
const EXT_BASE := 101
const EXT_ORDER := ["BC", "AC", "FM", "AG", "VM"]
const EXTENSIONS := {
	"BC": {"name": "BLASPHEMY CAESER", "parent": 15, "page": 2, "dir": "down", "first": 101,
		"place": "Down into the Caeser's crypts", "boss": "THE CAESER'S GRAVE"},
	"AG": {"name": "ARCHITECT'S GOLEM", "parent": 26, "page": 3, "dir": "up", "first": 104,
		"place": "Up into the Saint Rocks sanctuary", "boss": "SAINT ARCHITECT'S GOLEM"},
	"VM": {"name": "VOID MASSACRE", "parent": 34, "page": 4, "dir": "down", "first": 107,
		"place": "Deeper into the Void", "boss": "THE VOID HORRIDS"},
	"AC": {"name": "ATOMIC CREATION", "parent": 17, "page": 3, "dir": "down", "first": 110,
		"place": "The nuclear reactor, after the explosion", "boss": "RADIOACTIVE CHORUS"},
	"FM": {"name": "FORGE MOTHER", "parent": 24, "page": 3, "dir": "beyond", "first": 113,
		"place": "Into The Forge, beyond the Blast Workshop", "boss": "THE FORGE FATHER"},
}

const EXT_LEVELS := {
	# ----- BC: BLASPHEMY CAESER - the Caeser's crypts -----
	101: {"title": "THE SERPENT CULT", "theme": "caeser_crypts", "map": "crypts", "hero": "ext",
		"intro": "Below the Blasphemy Arena: the Caeser's crypts. His followers still pray down here.",
		"waves": [["bf_sword", "bf_wizard", "bf_sword"], ["bf_sword", "bf_sword", "bf_wizard", "bf_wizard"]], "boss": ""},
	102: {"title": "THE NEST OF SERPENTS", "theme": "caeser_crypts", "map": "crypts", "hero": "ext",
		"intro": "Deeper down. The walls are moving - serpents, hundreds of them.",
		"waves": [["serpent_small", "serpent_small", "serpent_small", "serpent_humane"], ["serpent_humane", "serpent_small", "serpent_humane", "serpent_small", "serpent_small"]], "boss": ""},
	103: {"title": "THE CAESER'S GRAVE", "theme": "caeser_crypts", "map": "crypts", "hero": "ext",
		"intro": "The last door. Something old is still breathing behind it.",
		"waves": [["bf_wizard", "serpent_small", "serpent_small", "bf_sword"]], "boss": "caeser_grave",
		"boss_map": "caeser_tomb", "boss_map_title": "THE CAESER'S TOMB", "boss_map_sub": "A broken coffin... and it is not empty.",
		"boss_music": "boss_grave", "boss_color": Color(0.65, 1.0, 0.75),
		"boss_sub": "BC4  -  What is left of the God-Devourer", "boss_line": "I... devoured... GODS...  I will devour... YOU...",
		"boss_death_title": "THE CAESER'S GRAVE IS SEALED", "boss_death_sub": "The serpents go still. The Blasphemy Caeser extension is complete."},
	# ----- AG: ARCHITECT'S GOLEM - the Saint Rocks sanctuary -----
	104: {"title": "THE SAINT ROCKS", "theme": "saint_rocks", "map": "saint_rocks", "hero": "ext",
		"intro": "A stair behind the Golem's Hall leads UP, into a sanctuary of living saint-rock.",
		"waves": [["saint_roller", "saint_warrior", "saint_roller"], ["saint_watcher", "saint_warrior", "saint_roller"]], "boss": ""},
	105: {"title": "THE WATCHERS' STAIR", "theme": "saint_rocks", "map": "saint_rocks", "hero": "ext",
		"intro": "Tall shapes watch from every ledge. Their eyes follow you.",
		"waves": [["saint_watcher", "saint_watcher", "saint_warrior"], ["saint_warrior", "saint_roller", "saint_watcher", "saint_warrior"]], "boss": ""},
	106: {"title": "THE SAINT ARCHITECT'S GOLEM", "theme": "saint_rocks", "map": "saint_rocks", "hero": "ext",
		"intro": "The top of the sanctuary. Runes and Architect metal hum in the stone.",
		"waves": [["saint_roller", "saint_warrior", "saint_watcher"]], "boss": "saint_golem", "boss_intro": "rise",
		"boss_map": "saint_sanctum", "boss_map_title": "THE SAINT SANCTUM", "boss_map_sub": "The Golem was REBUILT... with the Architect's own metal.",
		"boss_music": "boss_saint_golem", "boss_color": Color(0.45, 0.95, 1.0),
		"boss_sub": "AG4  -  Runes and Architectian Power", "boss_line": "...SANCTIFIED.   ...REBUILT.   ...DISMANTLE.",
		"boss_death": "sink", "boss_death_title": "THE SAINT GOLEM CRUMBLES",
		"boss_death_sub": "The runes fade. The Architect's Golem extension is complete."},
	# ----- VM: VOID MASSACRE - deeper into the Void -----
	107: {"title": "THE CRAWLING VICTIMS", "theme": "deep_void", "map": "deep_void", "hero": "ext",
		"intro": "Below the Spider Lair the Void goes on. The ones it swallowed are still crawling.",
		"waves": [["victim", "victim", "victim"], ["victim", "victim", "victim", "victim", "victim"]], "boss": ""},
	108: {"title": "THE SPIDER DEEP", "theme": "deep_void", "map": "deep_void", "hero": "ext",
		"intro": "Webs again. Smaller spiders... but so many more of them.",
		"waves": [["spider_biter", "spider_shooter", "spider_biter"], ["spider_venom", "spider_shooter", "spider_biter", "spider_venom"]], "boss": ""},
	109: {"title": "THE VOID HORRIDS", "theme": "deep_void", "map": "deep_void", "hero": "ext",
		"intro": "Something clicks in three places at once.",
		"waves": [["victim", "spider_biter", "victim"]], "boss": "void_horrid", "boss_pos": "center",
		"boss_map": "horrid_nest", "boss_map_title": "THE HORRID NEST", "boss_map_sub": "The Massacre had children.",
		"boss_music": "boss_horrids", "boss_color": Color(0.85, 0.85, 1.0),
		"boss_sub": "VM4  -  Three Void Horrids at once", "boss_line": "*three sets of white eyes open*",
		"boss_death_title": "THE VOID HORRIDS ARE DEAD", "boss_death_sub": "The Void goes quiet. The Void Massacre extension is complete."},
	# ----- AC: ATOMIC CREATION - the reactor after the explosion -----
	110: {"title": "THE REACTOR WASTE", "theme": "reactor_waste", "map": "reactor_waste", "hero": "ext",
		"intro": "Where the Atomic Creation came from: a reactor that blew apart. Nothing here is human anymore.",
		"waves": [["mutant", "mutant"], ["mutant", "mutant", "mutant"]], "boss": ""},
	111: {"title": "THE ATOMIC FIELD", "theme": "reactor_waste", "map": "reactor_waste", "hero": "ext",
		"intro": "The rocks glow. The rocks MOVE. Don't stand next to them when they break.",
		"waves": [["atomic_rock", "atomic_rock", "mutant"], ["atomic_rock", "mutant", "atomic_rock", "atomic_rock"]], "boss": ""},
	112: {"title": "THE RADIOACTIVE CHORUS", "theme": "reactor_waste", "map": "reactor_waste", "hero": "ext",
		"intro": "Singing. From inside the reactor. Many voices, all metal.",
		"waves": [["mutant", "atomic_rock", "mutant"]], "boss": "rad_chorus", "boss_intro": "rise", "boss_pos": "center",
		"boss_map": "reactor_core", "boss_map_title": "THE REACTOR CORE", "boss_map_sub": "The Architect Chorus... melted into the reactor.",
		"boss_music": "boss_reactor", "boss_color": Color(0.45, 1.0, 0.3),
		"boss_sub": "AC4  -  Radioactive Giant Metallic Architects Chorus", "boss_line": "WE... SING... THE... MELTDOWN...",
		"boss_death": "sink", "boss_death_title": "THE CHORUS FALLS SILENT",
		"boss_death_sub": "The core goes dark. The Atomic Creation extension is complete."},
	# ----- FM: FORGE MOTHER - The Forge -----
	113: {"title": "THE FORGE", "theme": "the_forge", "map": "the_forge", "hero": "ext",
		"intro": "Behind the Blast Workshop: The Forge itself. Its workers never stopped.",
		"waves": [["forge_worker", "forge_worker"], ["forge_worker", "forge_worker", "forge_worker"]], "boss": ""},
	114: {"title": "COAL AND OVENS", "theme": "the_forge", "map": "the_forge", "hero": "ext",
		"intro": "Burning coal rains from the catwalks. Something carries an oven on its back.",
		"waves": [["coal_thrower", "forge_worker", "coal_thrower"], ["oven_owner", "coal_thrower", "forge_worker", "coal_thrower"]], "boss": ""},
	115: {"title": "THE FORGE FATHER", "theme": "the_forge", "map": "the_forge", "hero": "ext",
		"intro": "The Forge Mother was only the beginning. Her maker waits in the heart of the fire.",
		"waves": [["forge_worker", "coal_thrower", "oven_owner"]], "boss": "forge_father",
		"boss_map": "forge_heart", "boss_map_title": "THE HEART OF THE FORGE", "boss_map_sub": "Molten metal, coal and fire. And HIM.",
		"boss_music": "boss_forge_father", "boss_color": Color(1.0, 0.55, 0.15),
		"boss_sub": "FM4  -  Maker of the Forge Mother", "boss_line": "THE MOTHER WAS WEAK.   I AM THE FORGE.",
		"boss_death": "sink", "boss_death_title": "THE FORGE FATHER IS MELTED DOWN",
		"boss_death_sub": "The Forge goes cold. The Forge Mother extension is complete."},
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
		"waves": [], "boss": "forge_mother",
		"boss_music": "boss_titan", "boss_color": Color(1.0, 0.6, 0.2),
		"boss_sub": "Mini-Boss  -  Forge-Guardian of the Architectium",
		"boss_line": "THE FORGE...  NEVER...  COOLS.",
		"boss_death_title": "THE FORGE MOTHER HAS FALLEN", "boss_death_sub": "The furnaces go quiet."},
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

	# ======================= COLOSSEUM 5: THE FINAL ASCENT (35-50) =======================
	# You pick the Warrior or the Architect (the other one is your CPU partner) and every level
	# starts with a hidden COIN FLIP. Bosses (each with its own arena + soundtrack): Child Wielding
	# Needle, The Brothers, Animal Lord, Executor, then Mother Nature (once those four are beaten),
	# The False God, Satan and THE SUN.
	35: {"title": "THE CROSSROADS OF ASH", "theme": "thornwood", "map": "thornwood", "hero": "choice", "partner": true, "coin_flip": true,
		"cutscene_in": "c5_intro", "arrive": "stand",
		"intro": "Two heroes, one road. Far away, on top of the mountain, something shines.",
		"waves": [["brute", "parasite", "brute"], ["guard_sword", "warrior_a_spear", "hydra"]], "boss": ""},
	36: {"title": "CHILD WIELDING NEEDLE", "theme": "silk_loom", "map": "silk_loom", "hero": "choice", "partner": true, "coin_flip": true,
		"intro": "Giant spools, silk curtains, moonlight... and a child humming a lullaby.",
		"waves": [], "boss": "needle",
		"boss_music": "boss_needle", "boss_color": Color(0.85, 0.75, 1.0),
		"boss_sub": "The First Keeper of the Ascent", "boss_line": "Will you play with me?  Hold still...",
		"boss_death_title": "THE NEEDLE FALLS", "boss_death_sub": "The silk goes slack. The lullaby stops."},
	37: {"title": "THE THORNWOOD", "theme": "thornwood", "map": "thornwood", "hero": "choice", "partner": true, "coin_flip": true,
		"intro": "Black thorns as tall as towers. Dead things still walk between them.",
		"waves": [["copper", "sparkling", "copper"], ["masker", "guard_bow", "guard_bow"]], "boss": ""},
	38: {"title": "THE WEEPING ROAD", "theme": "ruins", "map": "ruins", "hero": "choice", "partner": true, "coin_flip": true,
		"intro": "A road of broken temples. The statues are crying.",
		"waves": [["stray", "crawler", "stray"], ["warrior_a_shield", "guard_hammer", "warrior_a_bow"]], "boss": ""},
	39: {"title": "THE BROTHERS", "theme": "mirror_hall", "map": "mirror_hall", "hero": "choice", "partner": true, "coin_flip": true,
		"intro": "A hall that is the same on both sides. Two blades are waiting in the middle.",
		"waves": [], "boss": "brothers",
		"boss_music": "boss_brothers", "boss_color": Color(0.9, 0.9, 1.0),
		"boss_sub": "One Blade, Two Hands  -  The Second Keeper", "boss_line": "As one.",
		"boss_death_title": "THE BROTHERS FALL TOGETHER", "boss_death_sub": "Neither first. Neither last."},
	40: {"title": "THE BROKEN AQUEDUCT", "theme": "ruins", "map": "ruins", "hero": "choice", "partner": true, "coin_flip": true,
		"intro": "Water still runs through the cracks. Something ghostly slides under the stones.",
		"waves": [["escapist", "crawling", "crawling"], ["golem", "guard_bow", "guard_bow"]], "boss": ""},
	41: {"title": "THE SILENT CHAPEL", "theme": "ruins", "map": "ruins", "hero": "choice", "partner": true, "coin_flip": true,
		"intro": "An empty chapel. The faithful are still here... sort of.",
		"waves": [["follower", "guard_shield", "follower"], ["masker", "tentacle", "void_soul"]], "boss": ""},
	42: {"title": "ANIMAL LORD", "theme": "beast_den", "map": "beast_den", "hero": "choice", "partner": true, "coin_flip": true,
		"intro": "Hides on hooks. Bones in piles. Something breathes with many lungs.",
		"waves": [], "boss": "animal_lord",
		"boss_music": "boss_animal", "boss_color": Color(1.0, 0.75, 0.45),
		"boss_sub": "Stitched from Every Beast  -  The Third Keeper", "boss_line": "*a roar in a dozen voices*",
		"boss_death_title": "THE ANIMAL LORD COMES APART", "boss_death_sub": "The stitches tear. The den goes quiet."},
	43: {"title": "THE HOWLING PASS", "theme": "foothills", "map": "foothills", "hero": "choice", "partner": true, "coin_flip": true,
		"intro": "The mountain begins. The wind screams through the pass.",
		"waves": [["kharleming", "kharleming", "brute"], ["hydra", "warrior_a_sword", "warrior_a_sword"]], "boss": ""},
	44: {"title": "THE FROZEN STAIR", "theme": "foothills", "map": "foothills", "hero": "choice", "partner": true, "coin_flip": true,
		"intro": "Steps cut into ice. Every step is guarded.",
		"waves": [["guard", "guard_bow", "warrior_a_shield"], ["atomic", "sparkling", "sparkling"]], "boss": ""},
	45: {"title": "EXECUTOR", "theme": "gallows", "map": "gallows", "hero": "choice", "partner": true, "coin_flip": true,
		"intro": "Gallows. Chopping blocks. A purple fog that makes you forget why you came.",
		"waves": [], "boss": "executor",
		"boss_music": "boss_executor", "boss_color": Color(0.8, 0.55, 1.0),
		"boss_sub": "The Grinding Blade  -  The Fourth Keeper", "boss_line": "The sentence... is DEATH.",
		"boss_death_title": "THE EXECUTOR IS EXECUTED", "boss_death_sub": "The fog lifts. You remember everything."},
	46: {"title": "THE ROOTS OF THE WORLD", "theme": "thornwood", "map": "thornwood", "hero": "choice", "partner": true, "coin_flip": true,
		"intro": "Four Keepers fallen. The roots of a giant tree break through the ground.",
		"waves": [["crawler", "brute", "crawler"], ["masker", "masker"]], "boss": ""},
	47: {"title": "MOTHER NATURE", "theme": "world_tree", "map": "world_tree", "hero": "choice", "partner": true, "coin_flip": true,
		"intro": "With the four Keepers dead, the Heart of Nature opens. She is waiting.",
		"waves": [], "boss": "mother_nature", "boss_intro": "rise", "boss_pos": "center",
		"boss_music": "boss_nature", "boss_color": Color(0.6, 1.0, 0.6),
		"boss_map_title": "THE HEART OF NATURE", "boss_map_sub": "Fire, water, earth and wind... all at once.",
		"boss_sub": "Fire, Water, Earth and Wind", "boss_line": "You walked all this way to kill your MOTHER?",
		"boss_death": "sink", "boss_death_title": "MOTHER NATURE RETURNS TO THE EARTH",
		"boss_death_sub": "But something crawls out of her ashes... and runs up the mountain."},
	48: {"title": "THE FALSE GOD", "theme": "ash_cathedral", "map": "ash_cathedral", "hero": "choice", "partner": true, "coin_flip": true,
		"intro": "A cathedral of black stone on the mountainside, full of ash. Something burning sits on the altar.",
		"waves": [], "boss": "false_god",
		"boss_music": "boss_falsegod", "boss_color": Color(1.0, 0.3, 0.2),
		"boss_sub": "It Wore Nature's Skin  -  The Nightmare of Fire", "boss_line": "You prayed to her. You will BURN for ME.",
		"boss_death_title": "THE FALSE GOD BURNS OUT", "boss_death_sub": "Above, near the peak, a cave glows red..."},
	49: {"title": "SATAN", "theme": "satan_cave", "map": "satan_cave", "hero": "choice", "partner": true, "coin_flip": true,
		"cutscene_in": "mountain_climb", "arrive": "stand",
		"intro": "A cave near the top of the mountain. Lava, horns... and a throne.",
		"waves": [], "boss": "satan", "boss_intro": "rise",
		"boss_music": "boss_satan", "boss_color": Color(1.0, 0.35, 0.2),
		"boss_map_title": "SATAN'S MOUNTAIN CAVE", "boss_map_sub": "The lava rises... and so does HE.",
		"boss_sub": "Lord of the Mountain Cave  -  The Last Gate", "boss_line": "So. The little heroes came to my door.",
		"boss_death": "sink", "boss_death_title": "SATAN SINKS INTO THE LAVA", "boss_death_sub": "The way to the peak is open."},
	50: {"title": "THE SUN", "theme": "sun_peak", "map": "sun_peak", "hero": "choice", "partner": true, "quick_boss": true, "finale": true,
		"cutscene_in": "reach_peak", "arrive": "stand",
		"intro": "The peak. She is here.",
		"waves": [], "boss": "the_sun", "boss_pos": "center",
		"boss_music": "boss_sun", "boss_color": Color(1.0, 0.95, 0.7),
		"boss_sub": "The Final Boss", "boss_line": "Little moth... fly to the light.",
		"cutscene_out": "fall_to_earth"},
}


static func get_level(n: int) -> Dictionary:
	if EXT_LEVELS.has(n):
		return EXT_LEVELS[n]
	return LEVELS.get(clampi(n, 1, LEVELS.size()), LEVELS[1])


# ----- Boss extensions -----
static func is_ext(n: int) -> bool:
	return EXT_LEVELS.has(n)


## "BC" for levels 101-103 ... "" for normal levels.
static func ext_of(n: int) -> String:
	for k in EXTENSIONS:
		var first := int(EXTENSIONS[k]["first"])
		if n >= first and n < first + 3:
			return String(k)
	return ""


## Position inside its extension: 0, 1, 2 (= BC2, BC3, BC4).
static func ext_index(n: int) -> int:
	var k := ext_of(n)
	return n - int(EXTENSIONS[k]["first"]) if k != "" else 0


## "BC2", "BC3", "BC4"...
static func ext_code(n: int) -> String:
	var k := ext_of(n)
	return "%s%d" % [k, ext_index(n) + 2] if k != "" else ""


## Banner / HUD name of a level: "LEVEL 7" or "BC2".
static func level_label(n: int) -> String:
	return ext_code(n) if is_ext(n) else "LEVEL %d" % n


## The extensions shown on a Colosseum's board page.
static func exts_on_page(page: int) -> Array:
	var out: Array = []
	for k in EXT_ORDER:
		if int(EXTENSIONS[k]["page"]) == page:
			out.append(k)
	return out


static func map_of(n: int) -> Dictionary:
	return MAPS.get(String(get_level(n).get("map", "wastes")), MAPS["wastes"])


static func count() -> int:
	return LEVELS.size()


## Playable character of a level: "warrior" (Colosseums 1-3) or "architect" (Colosseum 4).
static func hero_of(n: int) -> String:
	var h := String(get_level(n).get("hero", PLAYER_CHARACTER))
	if h != "ext" and StoryProgress.anti_story:
		return "anti"                                      # Anti Architect run: solo, every level
	if h == "choice":
		return StoryProgress.c5_hero if StoryProgress.c5_hero != "" else PLAYER_CHARACTER
	if h == "ext":                                     # Boss extensions: Warrior OR Architect (picked in the menu)
		return StoryProgress.ext_hero if StoryProgress.ext_hero != "" else PLAYER_CHARACTER
	return h


## Art script (static draw_portrait) of a Story hero id.
static func hero_art(h: String) -> Script:
	match h:
		"architect":
			return ArchitectArt
		"anti":
			return AntiArchitectArt
	return WarriorArt


static func hero_name(h: String) -> String:
	match h:
		"architect":
			return "ARCHITECT"
		"anti":
			return "ANTI ARCHITECT"
	return "WARRIOR"


## Does level n have a CPU partner? (Colosseum 5 - never on an Anti Architect run: he goes alone)
static func has_partner(n: int) -> bool:
	return bool(get_level(n).get("partner", false)) and hero_of(n) != "anti"


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
	if is_ext(n):                                      # An extension belongs to its parent's Colosseum
		return colosseum_of(int(EXTENSIONS[ext_of(n)]["parent"]))
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
		"forge_mother":
			return ForgeMother
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
		"ambusher":
			return Ambusher
		"grin":
			return DevilishGrin
		"pained":
			return PainedOne
		"imp":
			return Imp
		"needle":
			return ChildNeedle
		"brothers":
			return TheBrothers
		"animal_lord":
			return AnimalLord
		"executor":
			return Executor
		"mother_nature":
			return MotherNature
		"false_god":
			return FalseGod
		"satan":
			return Satan
		"the_sun":
			return TheSun
		# ----- Boss extensions -----
		"bf_sword":
			return BlasphemyFollowerSword
		"bf_wizard":
			return BlasphemyFollowerWizard
		"serpent_small":
			return SmallSerpent
		"serpent_humane":
			return HumaneSerpent
		"saint_roller":
			return SaintRoller
		"saint_warrior":
			return SaintWarrior
		"saint_watcher":
			return SaintWatcher
		"victim":
			return CrawlingVictim
		"spider_shooter", "spider_biter", "spider_venom":
			return VoidSpider
		"mutant":
			return MutatedHuman
		"atomic_rock":
			return AtomicRock
		"forge_worker":
			return ForgeWorker
		"coal_thrower":
			return CoalThrower
		"oven_owner":
			return OvenOwner
		"caeser_grave":
			return CaesersGrave
		"saint_golem":
			return SaintGolem
		"void_horrid":
			return VoidHorrid
		"rad_chorus":
			return RadioactiveChorus
		"forge_father":
			return ForgeFather
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
		"guard_shield", "warrior_a_shield", "golem", "hydra", "atomic", "crawling", "void_soul", "escapist", "tentacle", "masker",
		"ambusher", "grin", "pained"]
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
		"forge_mother":
			return ForgeMother.new()
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
		"ambusher":
			return Ambusher.new()
		"grin":
			return DevilishGrin.new()
		"pained":
			return PainedOne.new()
		"imp":
			return Imp.new()
		"needle":
			return ChildNeedle.new()
		"brothers":
			return TheBrothers.new()
		"animal_lord":
			return AnimalLord.new()
		"executor":
			return Executor.new()
		"mother_nature":
			return MotherNature.new()
		"false_god":
			return FalseGod.new()
		"satan":
			return Satan.new()
		"the_sun":
			return TheSun.new()
		# ----- Boss extensions -----
		"bf_sword":
			return BlasphemyFollowerSword.new()
		"bf_wizard":
			return BlasphemyFollowerWizard.new()
		"serpent_small":
			return SmallSerpent.new()
		"serpent_humane":
			return HumaneSerpent.new()
		"saint_roller":
			return SaintRoller.new()
		"saint_warrior":
			return SaintWarrior.new()
		"saint_watcher":
			return SaintWatcher.new()
		"victim":
			return CrawlingVictim.new()
		"spider_shooter", "spider_biter", "spider_venom":
			var sp := VoidSpider.new()
			sp.kind = id.trim_prefix("spider_")
			return sp
		"mutant":
			return MutatedHuman.new()
		"atomic_rock":
			return AtomicRock.new()
		"forge_worker":
			return ForgeWorker.new()
		"coal_thrower":
			return CoalThrower.new()
		"oven_owner":
			return OvenOwner.new()
		"caeser_grave":
			return CaesersGrave.new()
		"saint_golem":
			return SaintGolem.new()
		"void_horrid":
			return VoidHorrid.new()
		"rad_chorus":
			return RadioactiveChorus.new()
		"forge_father":
			return ForgeFather.new()
	push_error("StoryLevels: unknown enemy '%s'" % id)
	return Parasite.new()
