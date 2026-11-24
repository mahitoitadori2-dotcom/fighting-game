class_name LevelsJourney
extends RefCounted
## Story levels 51-81: THE ENLIGHTENED CHASE ... THE ABANDONED TOWN (split out of StoryLevels.gd, 2026-11-24).

const LEVELS := {
	# ======================= THE ENLIGHTENED CHASE (levels 51-62) =======================
	# Its own Story part (after Colosseum 5): SOLO with the hero you picked ("chase"); the other
	# one was injured. The Enlightened One runs - at the start and end of every level except
	# the last he flies over and throws explosive barrels + holy hand grenades ("bombard").
	# Mini-boss halfway (The Enlightened First Prime), final boss The Enlightened One.
	# No pre-fight before either boss (quick_boss).
	51: {"title": "THE CHASE BEGINS", "theme": "golden_dunes", "map": "golden_dunes", "hero": "chase", "bombard": true,
		"cutscene_in": "enl_chase", "arrive": "stand",
		"intro": "He saw everything. He is RUNNING. After him!",
		"waves": [["guard", "guard"], ["counselor", "guard_sword"]], "boss": ""},
	52: {"title": "SANDS OF FAITH", "theme": "golden_dunes", "map": "golden_dunes", "hero": "chase", "bombard": true,
		"intro": "Hoofbeats in the dunes. His riders are coming back for you.",
		"waves": [["camel", "guard"], ["counselor", "camel", "guard_bow"]], "boss": ""},
	53: {"title": "THE CARAVAN", "theme": "golden_dunes", "map": "golden_dunes", "hero": "chase", "bombard": true,
		"intro": "A whole caravan blocks the road. Spears, shields, and too many camels.",
		"waves": [["camel", "camel"], ["guard_shield", "counselor", "guard_hammer"], ["camel", "counselor", "guard_bow"]], "boss": ""},
	54: {"title": "THE PILGRIM ROAD", "theme": "pilgrim_road", "map": "pilgrim_road", "hero": "chase", "bombard": true,
		"intro": "A road of golden statues. Every statue has his face.",
		"waves": [["counselor", "counselor", "guard"], ["camel", "guard_sword", "guard_bow"]], "boss": ""},
	55: {"title": "THE STATUE MILE", "theme": "pilgrim_road", "map": "pilgrim_road", "hero": "chase", "bombard": true,
		"intro": "The road narrows. Gongs ring somewhere ahead.",
		"waves": [["guard_shield", "guard_bow", "counselor"], ["camel", "camel", "counselor"]], "boss": ""},
	56: {"title": "THE ENLIGHTENED FIRST PRIME", "theme": "prime_sanctum", "map": "prime_sanctum", "hero": "chase", "bombard": true,
		"quick_boss": true, "arrive": "stand",
		"intro": "He left his First Prime behind to stop you.",
		"waves": [], "boss": "first_prime",
		"boss_music": "boss_prime", "boss_color": Color(1.0, 0.85, 0.4),
		"boss_sub": "Mini-Boss  -  Warrior Mage of the Holy Gong", "boss_line": "Turn back. The Light does not forgive.",
		"boss_death_title": "THE FIRST PRIME FALLS", "boss_death_sub": "His gong rings one last time... the road is open."},
	57: {"title": "THE GLASS OASIS", "theme": "glass_oasis", "map": "glass_oasis", "hero": "chase", "bombard": true,
		"intro": "An oasis of golden glass. The water shows a road that isn't there.",
		"waves": [["counselor", "camel", "guard"], ["guard_sword", "guard_sword", "counselor"]], "boss": ""},
	58: {"title": "MIRAGE", "theme": "glass_oasis", "map": "glass_oasis", "hero": "chase", "bombard": true,
		"intro": "Is he here? Or is it a mirage? The riders are real enough.",
		"waves": [["camel", "camel", "guard_bow"], ["counselor", "counselor", "guard_shield", "guard_hammer"]], "boss": ""},
	59: {"title": "THE BURNING CARAVAN", "theme": "golden_dunes", "map": "golden_dunes", "hero": "chase", "bombard": true,
		"intro": "He set his own caravan on fire to slow you down.",
		"waves": [["camel", "guard_hammer", "camel"], ["counselor", "guard_bow", "guard_bow", "camel"]], "boss": ""},
	60: {"title": "THE LAST ROAD", "theme": "pilgrim_road", "map": "pilgrim_road", "hero": "chase", "bombard": true,
		"intro": "The statues end. The sky above the road is turning gold.",
		"waves": [["guard_shield", "guard_shield", "counselor"], ["camel", "camel", "guard_sword", "counselor"]], "boss": ""},
	61: {"title": "THE GATES OF LIGHT", "theme": "glass_oasis", "map": "glass_oasis", "hero": "chase", "bombard": true,
		"intro": "His last guard. Behind the gates, a stairway into the sky.",
		"waves": [["camel", "counselor", "guard_hammer"], ["guard_shield", "guard_bow", "camel", "counselor"], ["camel", "camel", "counselor", "guard_sword"]], "boss": ""},
	62: {"title": "THE ENLIGHTENED ONE", "theme": "sky_reliquary", "map": "sky_reliquary", "hero": "chase",
		"quick_boss": true, "finale": true, "arrive": "stand",
		"intro": "No more running. He turns around.",
		"waves": [], "boss": "enlightened_one", "boss_pos": "center",
		"boss_music": "boss_enlightened", "boss_color": Color(1.0, 0.9, 0.5),
		"boss_sub": "No More Running", "boss_line": "You want me? Then CATCH EVERYTHING I OWN.",
		"cutscene_out": "enl_end"},

	# ======================= DEMILAND (level 63) =======================
	# Its own Story part: ONE OPEN-WORLD level (5-15 minutes, DemiLand.gd). You play the hero who
	# did NOT chase the Enlightened One. Souls rules (roll + stamina), shrines, day / night, a map.
	# 3 bosses (Tribe Master, Last Tiger, LIVING Tree Lord), each drops an ARTIFACT; put all three
	# into the Ancient Door to open it and finish.
	63: {"title": "DEMILAND", "theme": "demi_door", "map": "demi_door", "hero": "demi", "open_world": true,
		"world_maps": ["demi_plains", "demi_village", "demi_ravine", "demi_grove", "demi_door"],
		"intro": "A dark land. Dead trees. Primitive people. Everything else is extinct.",
		"waves": [], "boss": "", "tile": "tribe_master"},

	# ======================= THE CAVES (levels 64-66) =======================
	# Its own Story part after DemiLand: beyond the Ancient Door the ground drops into caves and you
	# SLIDE down them (CaveSlide.gd). NO combat, NO enemies: W jumps (all three), S ducks / dives
	# down (64 has no S). Same hero as DemiLand.
	64: {"title": "BEYOND THE DOOR", "theme": "dark_cave", "map": "dark_cave", "hero": "demi", "slide": true,
		"intro": "Behind the Ancient Door the floor drops away. You slide into the dark.",
		"waves": [], "boss": ""},
	65: {"title": "THE CRYSTAL CHUTE", "theme": "dark_cave", "map": "dark_cave", "hero": "demi", "slide": true,
		"intro": "Blue crystals light a chute of low rock. Duck under it.",
		"waves": [], "boss": ""},
	66: {"title": "THE DEEP THROAT", "theme": "dark_cave", "map": "dark_cave", "hero": "demi", "slide": true,
		"intro": "The deepest cave. Fast, red, and very, very low.",
		"waves": [], "boss": ""},

	# ======================= TERRA CRATERUM (level 67) =======================
	# Its own Story part: an OPEN-WORLD level (like DemiLand: Souls rules, CamTons, a map, run saved).
	# You shoot out of the last cave and fall into a crater full of volcanoes. Lava creatures and
	# Kharlemings at eternal war. Kill the LAVA MELTER (the magma barrier drains), kill the
	# KHARLEMING LORD (the TECHNICIAN'S BREAKER), pile Kharleming corpses at the BASALT WALL and blow
	# it up = the way on. Two NPCs: the Volcano Slave and the Kharleming Sacrifice (free one: the
	# other dies; saved for later parts).
	67: {"title": "TERRA CRATERUM", "theme": "crater_floor", "map": "crater_floor", "hero": "demi", "open_world": true, "crater": true,
		"world_maps": ["crater_floor", "crater_wreck", "crater_fields", "crater_front"],
		"intro": "A crater of volcanoes. Lava and Kharlemings at war - forever.",
		"waves": [], "boss": "", "tile": "kharleming_lord"},

	# ======================= THE MAGMA RUN (levels 68-70) =======================
	# Sliding out of Terra Craterum down lava tunnels. NEW: ATTACK breaks walls; a LAVA FLOOD with a
	# Kharleming swarm hunts you from behind (crash too often and it catches you). Level 70 stops
	# halfway for 3 WAVES of Craterum enemies (a normal Story fight: cooldowns reset, flasks
	# refilled), then the last slide. Every slide level ends at a WHITE WALL.
	68: {"title": "THE LAVA CHUTE", "theme": "dark_cave", "map": "dark_cave", "hero": "demi", "slide": true,
		"intro": "Out of the crater, down a tunnel of lava. Something is coming behind you.",
		"waves": [], "boss": "", "tile": "lava_goblin"},
	69: {"title": "THE SWARM TUNNEL", "theme": "dark_cave", "map": "dark_cave", "hero": "demi", "slide": true,
		"intro": "The Kharlemings have joined the hunt. Break the walls. Do not slow down.",
		"waves": [], "boss": "", "tile": "full_kharleming"},
	70: {"title": "THE LAST DESCENT", "theme": "lair", "map": "lair", "hero": "demi", "slide": true, "slide_fight": true,
		"intro": "The tunnel ends in a cavern. They caught up. Fight - then slide for your life.",
		"waves": [["lava_goblin", "kharleming", "kharleming"], ["lava_demon", "full_kharleming", "lava_goblin"], ["fragmenter", "master_kharleming", "lava_demon"]],
		"boss": "", "tile": "master_kharleming", "music": "boss_melter"},

	# ======================= TERRA ORDINARIORUM (level 71) =======================
	# The regular land (lore by the user). Slide down a ramp onto a meadow; start on the FAR LEFT.
	# Weak real-life animals (they never attack), a Town of ordinary people who think you are crazy
	# when you mention the Storm, a Mountain to climb (ledges + crawl tunnels) for the LIGHTNING
	# CANDLE. Main route: light it in the Town -> the STORM FINGER -> the ORDINARIORUM TICKET -> the
	# bridge from Orbis Terrarum. Secret: the candle on the Basalt Wall -> the SNOW DESERT.
	71: {"title": "TERRA ORDINARIORUM", "theme": "ord_meadow", "map": "ord_meadow", "hero": "demi", "open_world": true, "ord": true,
		"intro": "The regular land. Blue sky. And the Storm, waiting on the horizon.",
		"waves": [], "boss": "", "tile": "storm_finger"},

	# ======================= THE ROAD TO PEACE (levels 72-74) =======================
	# Not a slide: a RUN. You are forced to run up the bridge from Orbis Terrarum while the Storm
	# throws its particles at you: W jumps them, J hits them (no S). The Architect carries a sword
	# here (green blade, silver crossguard + handle) - only on the bridge. Ends at a white wall.
	72: {"title": "THE FIRST STEPS", "theme": "ord_mountain", "map": "ord_mountain", "hero": "demi", "slide": true, "road": true,
		"intro": "The bridge from Orbis Terrarum. The Storm does not want you on it.",
		"waves": [], "boss": "", "tile": "storm_finger"},
	73: {"title": "THROUGH THE STORM", "theme": "ord_mountain", "map": "ord_mountain", "hero": "demi", "slide": true, "road": true,
		"intro": "Halfway up. Lightning on every side.",
		"waves": [], "boss": "", "tile": "storm_finger"},
	74: {"title": "THE ROAD TO PEACE", "theme": "ord_mountain", "map": "ord_mountain", "hero": "demi", "slide": true, "road": true,
		"intro": "The island is right above you. One last run.",
		"waves": [], "boss": "", "tile": "storm_finger"},

	# ======================= ORBIS TERRARUM (levels 75-79) =======================
	# PURE LORE: only dialogue (OrbisTalk.tscn). 75 = the arrival + the Trainer's question (a CHOICE:
	# refusing fails the level). 76-79 = the LESSONS: side by side on the board, any order, all needed.
	75: {"title": "THE TRAINER", "theme": "ord_meadow", "map": "orbis", "hero": "demi", "orbis": true,
		"intro": "An island above the Storm. A table with one free seat.", "waves": [], "boss": ""},
	76: {"title": "LESSON: THE STORM", "theme": "ord_meadow", "map": "orbis", "hero": "demi", "orbis": true, "lesson": true,
		"intro": "What the Storm really is.", "waves": [], "boss": ""},
	77: {"title": "LESSON: THE ORGANS", "theme": "ord_meadow", "map": "orbis", "hero": "demi", "orbis": true, "lesson": true,
		"intro": "The Organs of the Storm.", "waves": [], "boss": ""},
	78: {"title": "LESSON: ITS RANGE", "theme": "ord_meadow", "map": "orbis", "hero": "demi", "orbis": true, "lesson": true,
		"intro": "How far the Storm can reach.", "waves": [], "boss": ""},
	79: {"title": "LESSON: WEAK POINTS", "theme": "ord_meadow", "map": "orbis", "hero": "demi", "orbis": true, "lesson": true,
		"intro": "Where the Storm can be hurt.", "waves": [], "boss": ""},
	# THE STORM ATTACKS (lore by the user): the Trainer is cut off as he is about to say who created the
	# Storm - it breaks into Orbis Terrarum. Run down the breaking bridge with the other two, the dead
	# villagers, a fall into the mountain, a slide with the Storm behind you, then this FIGHT: waves of
	# CORPSES the Storm controls (only regular enemies) and THE STORM HAND. The other hero AND the
	# Trainer fight beside you.
	80: {"title": "THE STORM ATTACKS", "theme": "dark_cave", "map": "storm_cave", "hero": "demi", "partner": true, "trainer_ally": true,
		"storm_attack": true, "possessed": true, "intro": "The Storm has found you. Its corpses come first.",
		"waves": [["guard", "tribe_hunter", "kharleming"], ["warrior_a", "lava_goblin", "tribe_brute", "full_kharleming"],
			["guard_shield", "lava_demon", "master_kharleming", "fragmenter"]],
		"boss": "storm_hand", "boss_sub": "The Storm reaches into the mountain", "boss_music": "boss_storm_hand", "boss_color": Color(0.6, 0.8, 1.0)},

	# ======================= THE ABANDONED TOWN (level 81) =======================
	# Lore by the user (2026-11-21). After the Storm you land in a town that walled itself off from the
	# world 500 years ago. PURE LORE (no fights): talk to the OLDEST JUDGE, the SHOPKEEPER and the
	# YOUNGEST GUARD -> "GO TO LEFT" -> out of the town's borders to a cave -> (loading screen) the
	# cave of old blood and charcoal -> THE NIGHTMARE LORD, asleep in chains -> a CHOICE (kept for
	# later: StoryProgress.town_choice) -> the Strong Wind lifts you into the sky. TownLand.gd.
	81: {"title": "THE ABANDONED TOWN", "theme": "town", "map": "town", "hero": "demi", "town": true,
		"intro": "After the Storm: a quiet town behind a wooden wall. Nobody has left it in 500 years.",
		"waves": [], "boss": "", "tile": "nightmare_lord"},
}
