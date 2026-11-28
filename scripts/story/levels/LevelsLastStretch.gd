class_name LevelsLastStretch
extends RefCounted
## Story levels 139-148: THE LAST STRETCH (lore by the user, 2026-11-28).
##
## The heroes journey on WITH THE NIGHTMARE LORD. The Storm follows them, and out in the open it will
## kill them, so they look for a village to shelter in. People and animals live along the road
## ("folk": RoadFolk wanders through the background). The NIGHTMARE LORD fights beside you as a third
## ally ("nl_ally"). They find a town - HALCYON, very advanced - but it believes in STORMISM (the Storm
## is a god and its saviour) and knows the Warrior and the Architect are Grade FTE: the three of them
## are captured and thrown into cells (cutscene "ls_capture", end of 142).
##
## 143-147: ONLY THE ARCHITECT. In his cell he turns inward and walks into his own soul, where he has
## to fight every weakness of his life ("soul": ghostly memories) to find his TRUE SELF; level 147's
## boss is his false self, THE HOLLOW ARCHITECT. Then (cutscene "ls_timestop") he STOPS TIME, tears
## the guards apart and sets the town on fire.
## 148: the king of Halcyon (LastStretch.gd): a short talk, the hand through his chest, the Warrior and
## the Nightmare Lord are freed, and a BRIDGE into the Storm appears. The end of this part.
##
## Religions (the user's lore, used in the talks): STORMISM (the Storm is a god and a saviour - Halcyon),
## RALLISM (Egyptian gods + Christian Heaven and Hell + hatred of the Storm), VOIDISM (the Warrior: no
## god at all), ARCHITECTIULUM (the Architect in the Architectium: a god brings supplies and knowledge)
## -> FREPASM (the Architect since he went rogue / Grade 0: peace and freedom for the good, pain and
## enclosure for the evil), THE RITUAL (the Nightmare Lord: the nightmare heart blooms into new Nightmare
## Lords), GODDISM (the Enlightened One: whoever survives his trials is a god).

const FIRST := 139
const LAST := 148

const LEVELS := {
	# ----- THE JOURNEY (you + your partner + the Nightmare Lord) -----
	139: {"title": "THE LAST STRETCH", "map": "ls_plains", "hero": "demi", "partner": true, "pal": true, "nl_ally": true,
		"folk": true, "tile": "tiger_cub", "intro": "Three travellers, one Storm behind them.",
		"waves": [["stray", "stray", "tiger_cub"], ["tribe_hunter", "tiger_cub", "pelt_cultist"]], "boss": ""},
	140: {"title": "THE STORM AT OUR BACKS", "map": "ls_plains", "hero": "demi", "partner": true, "pal": true, "nl_ally": true,
		"folk": true, "tile": "lava_goblin", "disasters": ["lightning"], "intro": "It struck the road behind you. Then a little closer.",
		"waves": [["lava_goblin", "lava_goblin", "lava_goblin"], ["tribe_hunter", "tribe_brute", "lava_goblin"],
			["tribe_shaman", "tiger_cub", "tribe_brute", "lava_goblin"]], "boss": ""},
	141: {"title": "THE FARMLANDS", "map": "ls_farms", "hero": "demi", "partner": true, "pal": true, "nl_ally": true,
		"folk": true, "tile": "guard_bow", "disasters": ["gale"], "intro": "Fences, fields, scarecrows. People live near here.",
		"waves": [["guard_sword", "guard_bow", "follower"], ["counselor", "guard_hammer", "guard_bow"],
			["husk", "sapling", "pelt_cultist", "guard_shield"]], "boss": ""},
	142: {"title": "THE ROAD TO HALCYON", "map": "ls_gate", "hero": "demi", "partner": true, "pal": true, "nl_ally": true,
		"folk": true, "tile": "camel", "disasters": ["lightning"], "intro": "Towers of glass and copper on the horizon. A town!",
		"waves": [["camel", "lava_goblin", "lava_goblin"], ["tribe_brute", "tiger_cub", "tribe_hunter", "stray"],
			["guard_shield", "guard_bow", "camel", "counselor"]], "boss": "", "cutscene_out": "ls_capture"},
	# ----- INSIDE THE ARCHITECT (him alone, his weaknesses) -----
	143: {"title": "OBEDIENCE", "map": "ls_soul", "hero": "architect", "soul": true, "tile": "warrior_a_spear",
		"intro": "The Architectium. You followed every order you were ever given.",
		"waves": [["warrior_a", "warrior_a_sword", "forge_worker"], ["warrior_a_spear", "warrior_a_bow", "warrior_a_shield"],
			["forge_worker", "coal_thrower", "warrior_a_spear", "warrior_a"]], "boss": ""},
	144: {"title": "THE GIFT THAT NEVER CAME", "map": "ls_soul", "hero": "architect", "soul": true, "tile": "saint_watcher",
		"intro": "You waited for a god to bring the supplies. You waited for years.",
		"waves": [["follower", "follower", "counselor"], ["saint_roller", "saint_warrior", "follower"],
			["saint_watcher", "counselor", "saint_warrior", "sparkling"]], "boss": ""},
	145: {"title": "THE DARK BELOW", "map": "ls_soul_dark", "hero": "architect", "soul": true, "tile": "masker",
		"intro": "Alone in the Void. The one place you were truly afraid.",
		"waves": [["crawling", "crawling", "void_soul"], ["escapist", "tentacle", "spider_biter"],
			["masker", "void_soul", "spider_venom", "crawling"]], "boss": ""},
	146: {"title": "THE ONES YOU COULD NOT SAVE", "map": "ls_soul_dark", "hero": "architect", "soul": true, "tile": "pained",
		"intro": "Every challenger the cure turned into an enemy. You remember all their faces.",
		"waves": [["copper", "stray", "victim"], ["mutant", "husk", "copper"], ["pained", "victim", "mutant", "stray"]], "boss": ""},
	147: {"title": "THE HOLLOW ARCHITECT", "map": "ls_soul_core", "hero": "architect", "soul": true,
		"intro": "At the bottom of yourself, someone is wearing your face.",
		"waves": [["warrior_a_sword", "follower", "crawling"], ["copper", "void_soul", "saint_warrior"]],
		"boss": "hollow_architect", "boss_pos": "center", "boss_music": "boss_hollow_architect", "boss_color": Color(0.70, 0.62, 1.0),
		"boss_map_title": "THE CORE", "boss_map_sub": "Everything you were afraid to be.",
		"boss_sub": "Every weakness, wearing your face", "boss_line": "*your own voice, but hollow*",
		"boss_death_title": "THE HOLLOW ARCHITECT IS GONE", "boss_death_sub": "What is left is the TRUE ARCHITECT.",
		"cutscene_out": "ls_timestop"},
	# ----- THE KING OF HALCYON (no fight: LastStretch.play) -----
	148: {"title": "THE KING OF HALCYON", "map": "ls_throne", "hero": "architect", "tile": "king",
		"intro": "The town burns. The king is still on his throne.", "arrive": "stand",
		"waves": [], "boss": "", "ls_end": true},
}
