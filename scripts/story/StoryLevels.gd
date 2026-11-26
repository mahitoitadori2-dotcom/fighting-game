class_name StoryLevels
extends RefCounted
## STORY MODE level list (Level 50 = The Sun). Colosseums have DIFFERENT sizes (COLOSSEUM_SIZES):
##   COLOSSEUM 1 = levels 1-6    (The Ashen Depths, boss: the Blinded Lord)
##   COLOSSEUM 2 = levels 7-15   (The Ascent, mini-boss: Architect Chorus, boss: Blasphemy Caeser)
##   COLOSSEUM 3 = levels 16-26  (The Burning Crown, mini-boss: Forge Mother, boss: Architect's Golem)
##   COLOSSEUM 4 = levels 27-34  (The Void Below, OPTIONAL level 32: The Shining, boss: Void Massacre)
##   COLOSSEUM 5 = levels 35-50  (The Final Ascent: pick Warrior or Architect, the other is your CPU
##                               partner; a COIN FLIP adds enemies every level; 7 bosses up to THE SUN)
##   THE ENLIGHTENED CHASE = levels 51-62 (its own part, not a Colosseum: solo with your pick,
##                               mini-boss The Enlightened First Prime, boss The Enlightened One)
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
##   hero         "warrior" (default), "architect", or "choice" (Colosseum 5: the hero you picked),
##                "demi" (DemiLand: the hero who did NOT chase the Enlightened One)
##   open_world   true = an OPEN WORLD level (DemiLand: DemiLand.tscn, Souls rules, 5-15 minutes)
##   world_maps   open world: the map keys of its regions (Map Catalogue, region backdrops)
##   partner      true = the other hero fights beside you as a CPU partner (revives when it falls)
##   coin_flip    true = coin flip at the start: HEADS 2 Ambushers / TAILS Devilish Grin + Pained One
##   quick_boss   true = NO pre-fight: straight into the boss (The Sun)
##   finale       true = the boss ends in the SunFinale sequence instead of a death cutscene

const PLAYER_CHARACTER := "warrior"      # Story Mode is Warrior only (Colosseums 1-3)
## Levels per Colosseum. Colosseums past this list (not made yet) use DEFAULT_SIZE.
const COLOSSEUM_SIZES := [6, 9, 11, 8, 16, 12, 1, 3, 1, 3, 1, 3, 6, 1, 29, 28] # 16th = THE TRUE HUNT (111-138) - 15th = THE HUNT OF A NIGHTMARE (82-110) - 14th = THE ABANDONED TOWN (81) - 13th = ORBIS TERRARUM (75-80) - 12th = THE ROAD TO PEACE (72-74) - 11th = TERRA ORDINARIORUM (71) - 6th = THE ENLIGHTENED CHASE (51-62), 7th = DEMILAND (63), 8th = THE CAVES (64-66), 9th = TERRA CRATERUM (67), 10th = THE MAGMA RUN (68-70)
const DEFAULT_SIZE := 6

## Weapon variants of the soldier enemies (ArmedSoldier kit): id -> [base id, weapon].
const VARIANTS := {
	"guard_sword": ["guard", "short_sword"], "guard_hammer": ["guard", "hammer"],
	"guard_shield": ["guard", "greatshield"], "guard_bow": ["guard", "bow"],
	"warrior_a_sword": ["warrior_a", "short_sword"], "warrior_a_spear": ["warrior_a", "spear"],
	"warrior_a_shield": ["warrior_a", "greatshield"], "warrior_a_bow": ["warrior_a", "bow"],
}

## MAPS (what each arena looks / sounds like): data in scripts/story/levels/StoryMaps.gd.
const MAPS := StoryMaps.MAPS


# ======================= BOSS EXTENSION LEVELS (data: scripts/story/levels/StoryExtensions.gd) =======================
const EXT_BASE := StoryExtensions.EXT_BASE
const EXT_ORDER := StoryExtensions.EXT_ORDER
const EXTENSIONS := StoryExtensions.EXTENSIONS
const EXT_LEVELS := StoryExtensions.EXT_LEVELS


## Every Story level, merged from the part files in scripts/story/levels/ (Levels*.gd).
static var LEVELS: Dictionary = _all_levels()


static func _all_levels() -> Dictionary:
	var all := {}
	for part: Dictionary in [LevelsColosseums.LEVELS, LevelsJourney.LEVELS, LevelsHunt.LEVELS, LevelsTrueHunt.LEVELS]:
		all.merge(part)
	return all


## Display name of a Story PART (board titles, HUD, captions): "COLOSSEUM 3" ... and
## "THE ENLIGHTENED CHASE" for the part after Colosseum 5 (it is NOT called a Colosseum).
const CHASE_PART := 6
## DEMILAND: the part after The Enlightened Chase (one open-world level, 63).
const DEMI_PART := 7
const DEMI_LEVEL := 63
## THE CAVES: the part after DemiLand (three no-combat SLIDE levels, 64-66).
const CAVES_PART := 8
## TERRA CRATERUM: the part after The Caves (one open-world level, 67). CraterLand.gd.
const CRATER_PART := 9
const CRATER_LEVEL := 67
## THE MAGMA RUN: the part after Terra Craterum (three SLIDE levels with attacks, 68-70; hunted from behind).
const RUN_PART := 10
## TERRA ORDINARIORUM: the part after The Magma Run (one open-world level, 71). OrdLand.gd.
const ORD_PART := 11
const ORD_LEVEL := 71
## THE ROAD TO PEACE: the part after Terra Ordinariorum (three RUNNING levels up the bridge, 72-74).
const ROAD_PART := 12
## ORBIS TERRARUM: pure lore (dialogue only). 75 = the arrival, 76-79 = the LESSONS (any order).
const ORBIS_PART := 13
## THE ABANDONED TOWN: the part after Orbis Terrarum (one lore level, 81). TownLand.gd.
const TOWN_PART := 14
const TOWN_LEVEL := 81
## THE HUNT OF A NIGHTMARE: the part after The Abandoned Town (29 arena levels, 82-110; HuntBackdrops, scripts/story/hunt/).
const HUNT_PART := 15
const HUNT_FIRST := 82
const HUNT_LAST := 110
## THE TRUE HUNT: the part after The Hunt of a Nightmare (28 arena levels, 111-138: natural disasters,
## ledges, every regular enemy; boss THE NIGHTMARE MONSTROSITY, then the Nightmare Lord's offer).
const TRUE_HUNT_PART := 16
const TRUE_FIRST := 111
const TRUE_LAST := 138
## Level 80: THE STORM ATTACKS (after all the lessons) - one level in five phases (OrbisTalk / CaveSlide /
## StoryArena chained by OrbisTalk.storm_phase): the table, the breaking bridge, the dead town, the cave
## slide with the Storm behind you, then possessed corpses + THE STORM HAND.
const STORM_LEVEL := 80


static func part_name(c: int) -> String:
	if c == Madness.PART:
		return "MADNESS"
	if c == TRUE_HUNT_PART:
		return "THE TRUE HUNT"
	if c == HUNT_PART:
		return "THE HUNT OF A NIGHTMARE"
	if c == TOWN_PART:
		return "THE ABANDONED TOWN"
	if c == ORBIS_PART:
		return "ORBIS TERRARUM"
	if c == ROAD_PART:
		return "THE ROAD TO PEACE"
	if c == ORD_PART:
		return "TERRA ORDINARIORUM"
	if c == RUN_PART:
		return "THE MAGMA RUN"
	if c == CRATER_PART:
		return "TERRA CRATERUM"
	if c == CAVES_PART:
		return "THE CAVES"
	if c == DEMI_PART:
		return "DEMILAND"
	return "THE ENLIGHTENED CHASE" if c == CHASE_PART else "COLOSSEUM %d" % c


## Is level n an open-world level (DemiLand)?
static func is_open_world(n: int) -> bool:
	return bool(get_level(n).get("open_world", false))


## Is level n TERRA CRATERUM (the second open world: CraterLand / CraterWorld)?
static func is_crater(n: int) -> bool:
	return bool(get_level(n).get("crater", false))


## The world layout script of an open-world level: DemiWorld or CraterWorld (same fields).
static func world_of(n: int) -> Script:
	if is_ord(n):
		return OrdWorld
	return CraterWorld if is_crater(n) else DemiWorld


## Is level n TERRA ORDINARIORUM (the third open world: OrdLand / OrdWorld)?
static func is_ord(n: int) -> bool:
	return bool(get_level(n).get("ord", false))


## Is level n an ORBIS TERRARUM dialogue level (OrbisTalk.tscn)?
static func is_orbis(n: int) -> bool:
	return bool(get_level(n).get("orbis", false))


## Is level n one of Orbis Terrarum's LESSONS (side by side on the board, any order)?
static func is_lesson(n: int) -> bool:
	return bool(get_level(n).get("lesson", false))


## Is level n THE ABANDONED TOWN (level 81: TownLand.tscn)?
static func is_town(n: int) -> bool:
	return bool(get_level(n).get("town", false))


## Is level n THE STORM ATTACKS (level 80: scenes, a run, a slide, then the fight)?
static func is_storm(n: int) -> bool:
	return bool(get_level(n).get("storm_attack", false))


## Is level n a cave SLIDE level (The Caves: no combat)?
static func is_slide(n: int) -> bool:
	return bool(get_level(n).get("slide", false))


static func get_level(n: int) -> Dictionary:
	if Madness.is_madness(n):                          # MADNESS (secret): its own 20 levels
		return Madness.level(n)
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
	if Madness.is_madness(n):
		return Madness.label(n)
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
	if h == "choice" or h == "chase":                  # Colosseum 5 / The Enlightened Chase: your pick
		return StoryProgress.c5_hero if StoryProgress.c5_hero != "" else PLAYER_CHARACTER
	if h == "demi":                                    # DemiLand: the one who did NOT chase him
		var chased := StoryProgress.c5_hero if StoryProgress.c5_hero != "" else PLAYER_CHARACTER
		return "architect" if chased == "warrior" else "warrior"
	if h == "madness":                                # MADNESS: any roster fighter but APHA (your pick)
		Madness.load_data()
		return Madness.hero
	if h == "ext":                                     # Boss extensions: Warrior OR Architect (picked in the menu)
		return StoryProgress.ext_hero if StoryProgress.ext_hero != "" else PLAYER_CHARACTER
	return h


## Art script (static draw_portrait) of a Story hero id.
static func hero_art(h: String) -> Script:
	match h:
		"architect":
			return ArchitectArt
		"warrior", "":
			return WarriorArt
	var e := CharacterRoster.get_entry(h)                 # MADNESS heroes: any roster fighter
	return e.get("art", WarriorArt) if String(e.get("id", "")) == h else WarriorArt


static func hero_name(h: String) -> String:
	match h:
		"architect":
			return "ARCHITECT"
		"warrior", "":
			return "WARRIOR"
	return String(CharacterRoster.get_entry(h).get("short", "WARRIOR")).to_upper()


## Does level n have a CPU partner? (Colosseum 5 - never in SOLO mode; THE TRUE HUNT's "pal" always)
static func has_partner(n: int) -> bool:
	var lv := get_level(n)
	return bool(lv.get("partner", false)) and (not StoryProgress.c5_solo or bool(lv.get("pal", false)))


## A Colosseum 5 duo level played WITHOUT the partner (Solo mode).
static func is_solo(n: int) -> bool:
	return bool(get_level(n).get("partner", false)) and not has_partner(n)


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
	if Madness.is_madness(n):
		return Madness.PART
	if is_ext(n):                                      # An extension belongs to its parent's Colosseum
		return colosseum_of(int(EXTENSIONS[ext_of(n)]["parent"]))
	var c := 1
	while n > last_of(c):
		c += 1
	return c


## Base enemy id of a weapon variant ("guard_bow" -> "guard"); other ids unchanged.
static func base_id(id: String) -> String:
	if NIGHTMARES.has(id):
		return String(NIGHTMARES[id])
	return String(VARIANTS[id][0]) if VARIANTS.has(id) else id


## THE HUNT OF A NIGHTMARE: Nightmare versions of the three open worlds' weakest enemies (id -> base).
## (The animals - nm_boar / nm_dog / nm_goat - are NightmareAnimal: the real ones never attack.)
const NIGHTMARES := {
	"nm_kharleming": "full_kharleming", "nm_lava_demon": "lava_demon", "nm_lava_goblin": "lava_goblin",
	"nm_tribe_hunter": "tribe_hunter", "nm_tiger_cub": "tiger_cub", "nm_sapling": "sapling",
}


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
		# ----- The Enlightened Chase -----
		"counselor":
			return EnlightenedCounselor
		"camel":
			return EnlightenedCamel
		"first_prime":
			return FirstPrime
		"enlightened_one":
			return EnlightenedOneBoss
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
		# ----- DemiLand -----
		"tribe_hunter":
			return TribeHunter
		"tribe_brute":
			return TribeBrute
		"tribe_shaman":
			return TribeShaman
		"tiger_cub":
			return TigerCub
		"pelt_cultist":
			return PeltCultist
		"husk":
			return HuskTreant
		"sapling":
			return RotSapling
		"tribe_master":
			return TribeMaster
		"last_tiger":
			return LastTiger
		"tree_lord":
			return TreeLord
		# ----- Terra Craterum -----
		"lava_golem":
			return LavaGolem
		"lava_demon":
			return LavaDemon
		"lava_goblin":
			return LavaGoblin
		"fragmenter":
			return AncientFragmenter
		"full_kharleming":
			return FullKharleming
		"master_kharleming":
			return MasterKharleming
		"lava_melter":
			return LavaMelter
		"kharleming_lord":
			return KharlemingLord
		"crystal_swarm":
			return CrystalSwarm
		"storm_finger":
			return StormFinger
		"storm_hand":
			return StormHand
		"weird":
			return WeirdCreature
		"skull_serpent":
			return SkullSerpent
		"broken_ghost":
			return BrokenGhost
		"xx0xn":
			return XX0XN
		"nightmare_lord":
			return NightmareLordBoss                        # (The Abandoned Town's tile too: draws the Nightmare Lord)
		# ----- The Hunt of a Nightmare -----
		"troupe_follower":
			return TroupeFollower
		"nm_trader":
			return NightmareTrader
		"aristocrat":
			return AristocraticNightmare
		"troupe_jester":
			return TroupeJester
		"nightmare_musician":
			return NightmareMusician
		"head_guard":
			return HeadGuard
		"nightmares_lord":
			return NightmaresLord
		"troupe_heart":
			return TroupeHeart
		"nm_boar", "nm_dog", "nm_goat":
			return NightmareAnimal
		# ----- The True Hunt -----
		"nightmare_monstrosity":
			return NightmareMonstrosity
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
		"ambusher", "grin", "pained", "counselor", "camel"]
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
		# ----- The Enlightened Chase -----
		"counselor":
			return EnlightenedCounselor.new()
		"camel":
			return EnlightenedCamel.new()
		"first_prime":
			return FirstPrime.new()
		"enlightened_one":
			return EnlightenedOneBoss.new()
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
	if id in ["tribe_hunter", "tribe_brute", "tribe_shaman", "tiger_cub", "pelt_cultist", "husk", "sapling",
			"tribe_master", "last_tiger", "tree_lord",
			"lava_golem", "lava_demon", "lava_goblin", "fragmenter", "full_kharleming", "master_kharleming",
			"lava_melter", "kharleming_lord", "crystal_swarm", "storm_finger", "storm_hand",
			"weird", "skull_serpent", "broken_ghost", "xx0xn"]:
		return enemy_script(id).new()                    # DemiLand + Terra Craterum + Ordinariorum enemies + bosses
	# ----- THE HUNT OF A NIGHTMARE -----
	if id in ["troupe_follower", "nm_trader", "aristocrat", "troupe_jester", "nightmare_musician", "head_guard",
			"nightmares_lord", "troupe_heart", "nightmare_lord", "nightmare_monstrosity"]:
		return enemy_script(id).new()
	if id.begins_with("nm_"):                         # NIGHTMARE VERSIONS of the open worlds' weakest enemies
		var nm: BaseEnemy
		var animal := id.trim_prefix("nm_")
		if Animal.KINDS.has(animal):
			var na := NightmareAnimal.new()
			na.kind = animal
			nm = na
		else:
			nm = make_enemy(base_id(id))
		nm.nightmare = true
		if id == "nm_kharleming":
			nm.nightmare_name = "Kharleming"
		return nm
	if Animal.KINDS.has(id):                           # Terra Ordinariorum's animals (never hostile)
		var a := Animal.new()
		a.kind = id
		return a
	push_error("StoryLevels: unknown enemy '%s'" % id)
	return Parasite.new()
