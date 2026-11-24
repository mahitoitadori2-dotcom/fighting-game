class_name StoryExtensions
extends RefCounted
## BOSS EXTENSION data (split out of StoryLevels.gd, 2026-11-24). Read it as StoryLevels.EXTENSIONS / EXT_LEVELS.

# ======================= BOSS EXTENSION LEVELS =======================
## After a boss is beaten, 3 extra levels unlock that go DOWN or UP from its arena: 2 enemy
## levels + 1 final boss. Code = boss initials + number (BC2, BC3, BC4...). Played with the
## Warrior OR the Architect (picked in the extension menu; NOT duo - duo is Colosseum 5 only).
## Internal level numbers start at EXT_BASE so they never collide with Colosseum levels.
##   parent   the Colosseum level whose boss unlocks it      page   board page it is shown on
##   dir      "down" / "up" / "beyond" (where it leads)       first  internal number of the 1st level
const EXT_BASE := 301                           # (Was 101 until 2026-11-22: The Hunt of a Nightmare needs 101-110)
const EXT_ORDER := ["BC", "AC", "FM", "AG", "VM"]
const EXTENSIONS := {
	"BC": {"name": "BLASPHEMY CAESER", "parent": 15, "page": 2, "dir": "down", "first": 301,
		"place": "Down into the Caeser's crypts", "boss": "THE CAESER'S GRAVE"},
	"AG": {"name": "ARCHITECT'S GOLEM", "parent": 26, "page": 3, "dir": "up", "first": 304,
		"place": "Up into the Saint Rocks sanctuary", "boss": "SAINT ARCHITECT'S GOLEM"},
	"VM": {"name": "VOID MASSACRE", "parent": 34, "page": 4, "dir": "down", "first": 307,
		"place": "Deeper into the Void", "boss": "THE VOID HORRIDS"},
	"AC": {"name": "ATOMIC CREATION", "parent": 17, "page": 3, "dir": "down", "first": 310,
		"place": "The nuclear reactor, after the explosion", "boss": "RADIOACTIVE CHORUS"},
	"FM": {"name": "FORGE MOTHER", "parent": 24, "page": 3, "dir": "beyond", "first": 313,
		"place": "Into The Forge, beyond the Blast Workshop", "boss": "THE FORGE FATHER"},
}

const EXT_LEVELS := {
	# ----- BC: BLASPHEMY CAESER - the Caeser's crypts -----
	301: {"title": "THE SERPENT CULT", "theme": "caeser_crypts", "map": "crypts", "hero": "ext",
		"intro": "Below the Blasphemy Arena: the Caeser's crypts. His followers still pray down here.",
		"waves": [["bf_sword", "bf_wizard", "bf_sword"], ["bf_sword", "bf_sword", "bf_wizard", "bf_wizard"]], "boss": ""},
	302: {"title": "THE NEST OF SERPENTS", "theme": "caeser_crypts", "map": "crypts", "hero": "ext",
		"intro": "Deeper down. The walls are moving - serpents, hundreds of them.",
		"waves": [["serpent_small", "serpent_small", "serpent_small", "serpent_humane"], ["serpent_humane", "serpent_small", "serpent_humane", "serpent_small", "serpent_small"]], "boss": ""},
	303: {"title": "THE CAESER'S GRAVE", "theme": "caeser_crypts", "map": "crypts", "hero": "ext",
		"intro": "The last door. Something old is still breathing behind it.",
		"waves": [["bf_wizard", "serpent_small", "serpent_small", "bf_sword"]], "boss": "caeser_grave",
		"boss_map": "caeser_tomb", "boss_map_title": "THE CAESER'S TOMB", "boss_map_sub": "A broken coffin... and it is not empty.",
		"boss_music": "boss_grave", "boss_color": Color(0.65, 1.0, 0.75),
		"boss_sub": "BC4  -  What is left of the God-Devourer", "boss_line": "I... devoured... GODS...  I will devour... YOU...",
		"boss_death_title": "THE CAESER'S GRAVE IS SEALED", "boss_death_sub": "The serpents go still. The Blasphemy Caeser extension is complete."},
	# ----- AG: ARCHITECT'S GOLEM - the Saint Rocks sanctuary -----
	304: {"title": "THE SAINT ROCKS", "theme": "saint_rocks", "map": "saint_rocks", "hero": "ext",
		"intro": "A stair behind the Golem's Hall leads UP, into a sanctuary of living saint-rock.",
		"waves": [["saint_roller", "saint_warrior", "saint_roller"], ["saint_watcher", "saint_warrior", "saint_roller"]], "boss": ""},
	305: {"title": "THE WATCHERS' STAIR", "theme": "saint_rocks", "map": "saint_rocks", "hero": "ext",
		"intro": "Tall shapes watch from every ledge. Their eyes follow you.",
		"waves": [["saint_watcher", "saint_watcher", "saint_warrior"], ["saint_warrior", "saint_roller", "saint_watcher", "saint_warrior"]], "boss": ""},
	306: {"title": "THE SAINT ARCHITECT'S GOLEM", "theme": "saint_rocks", "map": "saint_rocks", "hero": "ext",
		"intro": "The top of the sanctuary. Runes and Architect metal hum in the stone.",
		"waves": [["saint_roller", "saint_warrior", "saint_watcher"]], "boss": "saint_golem", "boss_intro": "rise",
		"boss_map": "saint_sanctum", "boss_map_title": "THE SAINT SANCTUM", "boss_map_sub": "The Golem was REBUILT... with the Architect's own metal.",
		"boss_music": "boss_saint_golem", "boss_color": Color(0.45, 0.95, 1.0),
		"boss_sub": "AG4  -  Runes and Architectian Power", "boss_line": "...SANCTIFIED.   ...REBUILT.   ...DISMANTLE.",
		"boss_death": "sink", "boss_death_title": "THE SAINT GOLEM CRUMBLES",
		"boss_death_sub": "The runes fade. The Architect's Golem extension is complete."},
	# ----- VM: VOID MASSACRE - deeper into the Void -----
	307: {"title": "THE CRAWLING VICTIMS", "theme": "deep_void", "map": "deep_void", "hero": "ext",
		"intro": "Below the Spider Lair the Void goes on. The ones it swallowed are still crawling.",
		"waves": [["victim", "victim", "victim"], ["victim", "victim", "victim", "victim", "victim"]], "boss": ""},
	308: {"title": "THE SPIDER DEEP", "theme": "deep_void", "map": "deep_void", "hero": "ext",
		"intro": "Webs again. Smaller spiders... but so many more of them.",
		"waves": [["spider_biter", "spider_shooter", "spider_biter"], ["spider_venom", "spider_shooter", "spider_biter", "spider_venom"]], "boss": ""},
	309: {"title": "THE VOID HORRIDS", "theme": "deep_void", "map": "deep_void", "hero": "ext",
		"intro": "Something clicks in three places at once.",
		"waves": [["victim", "spider_biter", "victim"]], "boss": "void_horrid", "boss_pos": "center",
		"boss_map": "horrid_nest", "boss_map_title": "THE HORRID NEST", "boss_map_sub": "The Massacre had children.",
		"boss_music": "boss_horrids", "boss_color": Color(0.85, 0.85, 1.0),
		"boss_sub": "VM4  -  Three Void Horrids at once", "boss_line": "*three sets of white eyes open*",
		"boss_death_title": "THE VOID HORRIDS ARE DEAD", "boss_death_sub": "The Void goes quiet. The Void Massacre extension is complete."},
	# ----- AC: ATOMIC CREATION - the reactor after the explosion -----
	310: {"title": "THE REACTOR WASTE", "theme": "reactor_waste", "map": "reactor_waste", "hero": "ext",
		"intro": "Where the Atomic Creation came from: a reactor that blew apart. Nothing here is human anymore.",
		"waves": [["mutant", "mutant"], ["mutant", "mutant", "mutant"]], "boss": ""},
	311: {"title": "THE ATOMIC FIELD", "theme": "reactor_waste", "map": "reactor_waste", "hero": "ext",
		"intro": "The rocks glow. The rocks MOVE. Don't stand next to them when they break.",
		"waves": [["atomic_rock", "atomic_rock", "mutant"], ["atomic_rock", "mutant", "atomic_rock", "atomic_rock"]], "boss": ""},
	312: {"title": "THE RADIOACTIVE CHORUS", "theme": "reactor_waste", "map": "reactor_waste", "hero": "ext",
		"intro": "Singing. From inside the reactor. Many voices, all metal.",
		"waves": [["mutant", "atomic_rock", "mutant"]], "boss": "rad_chorus", "boss_intro": "rise", "boss_pos": "center",
		"boss_map": "reactor_core", "boss_map_title": "THE REACTOR CORE", "boss_map_sub": "The Architect Chorus... melted into the reactor.",
		"boss_music": "boss_reactor", "boss_color": Color(0.45, 1.0, 0.3),
		"boss_sub": "AC4  -  Radioactive Giant Metallic Architects Chorus", "boss_line": "WE... SING... THE... MELTDOWN...",
		"boss_death": "sink", "boss_death_title": "THE CHORUS FALLS SILENT",
		"boss_death_sub": "The core goes dark. The Atomic Creation extension is complete."},
	# ----- FM: FORGE MOTHER - The Forge -----
	313: {"title": "THE FORGE", "theme": "the_forge", "map": "the_forge", "hero": "ext",
		"intro": "Behind the Blast Workshop: The Forge itself. Its workers never stopped.",
		"waves": [["forge_worker", "forge_worker"], ["forge_worker", "forge_worker", "forge_worker"]], "boss": ""},
	314: {"title": "COAL AND OVENS", "theme": "the_forge", "map": "the_forge", "hero": "ext",
		"intro": "Burning coal rains from the catwalks. Something carries an oven on its back.",
		"waves": [["coal_thrower", "forge_worker", "coal_thrower"], ["oven_owner", "coal_thrower", "forge_worker", "coal_thrower"]], "boss": ""},
	315: {"title": "THE FORGE FATHER", "theme": "the_forge", "map": "the_forge", "hero": "ext",
		"intro": "The Forge Mother was only the beginning. Her maker waits in the heart of the fire.",
		"waves": [["forge_worker", "coal_thrower", "oven_owner"]], "boss": "forge_father",
		"boss_map": "forge_heart", "boss_map_title": "THE HEART OF THE FORGE", "boss_map_sub": "Molten metal, coal and fire. And HIM.",
		"boss_music": "boss_forge_father", "boss_color": Color(1.0, 0.55, 0.15),
		"boss_sub": "FM4  -  Maker of the Forge Mother", "boss_line": "THE MOTHER WAS WEAK.   I AM THE FORGE.",
		"boss_death": "sink", "boss_death_title": "THE FORGE FATHER IS MELTED DOWN",
		"boss_death_sub": "The Forge goes cold. The Forge Mother extension is complete."},
}
