class_name StoryMaps
extends RefCounted
## Story MAP data (split out of StoryLevels.gd, 2026-11-24). Read it as StoryLevels.MAPS.

## MAPS: what the arena looks / sounds like. StoryManager applies it on level start.
##   bg          HellBackground theme
##   ground      ArenaGround theme (2 Hell, 3 Geode, 4 Scrap, 5 Lab, 6 Elevator, 7 Marble, 8 Sewer, 9 Blasphemy)
##   walls       CaveWall style
##   half_width  distance from the arena centre to each wall (smaller = tighter arena)
##   music       SoundManager track for the group battles ("none" = silence)
##   fog         true = drifting green fog in front of the floor (sewers)
##   solid       true = underground: solid rock fills the space under the floor (no floating island)
##   zone        name of the area on the board
##   platforms   [[x from the centre, height above the floor, width], ...] one-way rock LEDGES
##               (StoryPlatform; jump up through them, they hold you from above) - The True Hunt
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
	# ----- THE ENLIGHTENED CHASE (C6Backdrops.gd): 3 road maps + 2 boss arenas -----
	# GOLDEN DUNES: a gold desert at noon, his caravan tracks, obelisks with his face.
	"golden_dunes":  {"bg": "golden_dunes", "ground": 26, "walls": "marble", "half_width": 860.0, "music": "story_chase", "zone": "THE GOLDEN DUNES"},
	# THE PILGRIM ROAD: a paved road lined with giant golden statues of him, banners.
	"pilgrim_road":  {"bg": "pilgrim_road", "ground": 7, "walls": "marble", "half_width": 840.0, "music": "story_chase", "zone": "THE PILGRIM ROAD"},
	# THE GLASS OASIS: palms of golden glass, mirror-still water, a mirage of the road.
	"glass_oasis":   {"bg": "glass_oasis", "ground": 21, "walls": "marble", "half_width": 840.0, "music": "story_chase", "zone": "THE GLASS OASIS"},
	# The First Prime's GONG SANCTUM: a ring of huge gongs, incense smoke, a ritual circle.
	"prime_sanctum": {"bg": "prime_sanctum", "ground": 7, "walls": "marble", "half_width": 800.0, "music": "none", "zone": "THE GONG SANCTUM"},
	# The Enlightened One's SKY RELIQUARY: floating above golden clouds, his treasures orbiting.
	"sky_reliquary": {"bg": "sky_reliquary", "ground": 21, "walls": "peak", "half_width": 880.0, "music": "none", "zone": "THE SKY RELIQUARY"},
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
	# ----- DEMILAND (DemiBackdrops.gd): ONE open world, 5 regions (each also a Versus map) -----
	# A dark land under a dark sky (darker than dark at night). Dead trees, primitive people.
	"demi_plains":  {"bg": "demi_plains", "ground": 27, "walls": "thorn", "half_width": 860.0, "music": "story_demiland", "zone": "THE DEAD PLAINS"},
	"demi_village": {"bg": "demi_village", "ground": 27, "walls": "thorn", "half_width": 840.0, "music": "story_demiland", "zone": "THE TRIBE VILLAGE"},
	"demi_ravine":  {"bg": "demi_ravine", "ground": 27, "walls": "thorn", "half_width": 840.0, "music": "story_demiland", "zone": "THE TIGER RAVINE"},
	"demi_grove":   {"bg": "demi_grove", "ground": 27, "walls": "thorn", "half_width": 840.0, "music": "story_demiland", "zone": "THE DEAD GROVE"},
	"demi_door":    {"bg": "demi_door", "ground": 27, "walls": "thorn", "half_width": 840.0, "music": "story_demiland", "zone": "THE ANCIENT DOOR"},
	# ----- Terra Craterum (one open world, four regions) -----
	"crater_floor":  {"bg": "crater_floor", "ground": 20, "walls": "hellrock", "half_width": 840.0, "music": "story_magma", "zone": "THE CRATER FLOOR"},
	"crater_wreck":  {"bg": "crater_wreck", "ground": 20, "walls": "hellrock", "half_width": 840.0, "music": "story_wreck", "zone": "THE KHARLEMING WRECK"},
	"crater_fields": {"bg": "crater_fields", "ground": 20, "walls": "hellrock", "half_width": 840.0, "music": "story_magma", "zone": "THE MAGMA FIELDS"},
	"crater_front":  {"bg": "crater_front", "ground": 20, "walls": "hellrock", "half_width": 840.0, "music": "story_magma", "zone": "THE WAR FRONT"},
	# ----- Terra Ordinariorum (one open world, seven biomes) -----
	"ord_meadow":   {"bg": "ord_meadow", "ground": 19, "walls": "thorn", "half_width": 840.0, "music": "story_meadow", "zone": "THE MEADOW"},
	"ord_forest":   {"bg": "ord_forest", "ground": 19, "walls": "thorn", "half_width": 840.0, "music": "story_forest", "zone": "THE FOREST"},
	"ord_town":     {"bg": "ord_town", "ground": 11, "walls": "thorn", "half_width": 840.0, "music": "story_town", "zone": "THE TOWN"},
	"ord_jungle":   {"bg": "ord_jungle", "ground": 19, "walls": "thorn", "half_width": 840.0, "music": "story_jungle", "zone": "THE JUNGLE"},
	"ord_desert":   {"bg": "ord_desert", "ground": 26, "walls": "thorn", "half_width": 840.0, "music": "story_desert", "zone": "THE DESERT"},
	"ord_mountain": {"bg": "ord_mountain", "ground": 23, "walls": "thorn", "half_width": 840.0, "music": "story_mountain", "zone": "THE MOUNTAIN"},
	"ord_snow":     {"bg": "ord_snow", "ground": 24, "walls": "thorn", "half_width": 840.0, "music": "story_snow", "zone": "THE SNOW DESERT"},
	"storm_cave":   {"bg": "dark_cave", "ground": 13, "walls": "dark", "half_width": 820.0, "music": "boss_storm_finger", "solid": true, "zone": "INSIDE THE MOUNTAIN"},
	"town":         {"bg": "ord_town", "ground": 11, "walls": "thorn", "half_width": 840.0, "music": "story_abandoned_town", "zone": "THE ABANDONED TOWN"},
	"nightmare_cave": {"bg": "dark_cave", "ground": 13, "walls": "dark", "half_width": 820.0, "music": "story_nightmare_cave", "solid": true, "zone": "THE NIGHTMARE'S CAVE"},
	"madness":      {"bg": "madness", "ground": 13, "walls": "lava", "half_width": 860.0, "music": "madness_level", "solid": true, "zone": ""},
	# ----- THE HUNT OF A NIGHTMARE (HuntBackdrops.gd): rocky lands, red lanterns, the Troupe's tents -----
	"hunt_rocks":    {"bg": "hunt_rocks", "ground": 20, "walls": "hellrock", "half_width": 840.0, "music": "story_hunt", "zone": "THE ROCKY LANDS"},
	"hunt_tents":    {"bg": "hunt_tents", "ground": 20, "walls": "hellrock", "half_width": 840.0, "music": "story_hunt", "zone": "THE TROUPE'S TENTS"},
	"hunt_hollow":   {"bg": "hunt_hollow", "ground": 13, "walls": "dark", "half_width": 820.0, "music": "story_hunt", "solid": true, "zone": "THE STONE HOLLOW"},
	# Inside the tents - UNIQUE to the 3 final fights: a cave with a big red crucible
	"hunt_crucible": {"bg": "hunt_crucible", "ground": 20, "walls": "hellrock", "half_width": 860.0, "music": "none", "solid": true, "zone": "THE CRUCIBLE"},
	# ----- THE TRUE HUNT (111-138): the lands of Terra Patria, torn up by disasters, with LEDGES -----
	"th_rocks":    {"bg": "hunt_rocks", "ground": 20, "walls": "hellrock", "half_width": 900.0, "music": "story_true_hunt", "zone": "THE SHAKING ROCKS",
		"platforms": [[-460.0, 120.0, 190.0], [40.0, 165.0, 230.0], [500.0, 115.0, 170.0]]},
	"th_village":  {"bg": "demi_village", "ground": 27, "walls": "thorn", "half_width": 880.0, "music": "story_true_hunt", "zone": "THE EMPTY VILLAGE",
		"platforms": [[-330.0, 125.0, 210.0], [360.0, 125.0, 210.0]]},
	"th_hollow":   {"bg": "hunt_hollow", "ground": 13, "walls": "dark", "half_width": 840.0, "music": "story_true_hunt", "solid": true, "zone": "THE DEEP HOLLOW",
		"platforms": [[-520.0, 110.0, 160.0], [-120.0, 175.0, 170.0], [300.0, 120.0, 200.0]]},
	"th_magma":    {"bg": "crater_fields", "ground": 20, "walls": "hellrock", "half_width": 880.0, "music": "story_true_hunt", "zone": "THE BOILING FIELDS",
		"platforms": [[-420.0, 140.0, 200.0], [0.0, 120.0, 150.0], [430.0, 140.0, 200.0]]},
	"th_reactor":  {"bg": "reactor_waste", "ground": 5, "walls": "lab", "half_width": 860.0, "music": "story_true_hunt", "zone": "THE OLD REACTOR",
		"platforms": [[-260.0, 150.0, 240.0], [420.0, 115.0, 180.0]]},
	"th_mountain": {"bg": "ord_mountain", "ground": 23, "walls": "thorn", "half_width": 900.0, "music": "story_true_hunt", "zone": "THE BROKEN PASS",
		"platforms": [[-540.0, 105.0, 170.0], [-180.0, 150.0, 190.0], [200.0, 195.0, 170.0], [560.0, 120.0, 170.0]]},
	"th_tents":    {"bg": "hunt_tents", "ground": 20, "walls": "hellrock", "half_width": 880.0, "music": "story_true_hunt", "zone": "THE CLAN'S LAST CAMP",
		"platforms": [[-380.0, 130.0, 220.0], [380.0, 130.0, 220.0]]},
	"th_forge":    {"bg": "hunt_crucible", "ground": 20, "walls": "hellrock", "half_width": 900.0, "music": "story_true_hunt", "solid": true, "zone": "THE NIGHTMARE FORGE",
		"platforms": [[-520.0, 130.0, 180.0], [520.0, 130.0, 180.0]]},
	"orbis":        {"bg": "ord_meadow", "ground": 19, "walls": "thorn", "half_width": 840.0, "music": "story_orbis", "zone": "ORBIS TERRARUM"},
}
