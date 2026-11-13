class_name EnemyManager
extends RefCounted
## EVERY PvE enemy in one place. CharacterRoster.all() appends entries() and the
## Character Select "ENEMY TEST" section + enemy quick-pick list are built from it.
##
## ADD AN ENEMY:
##   1. class_name MyEnemy extends SimpleEnemy (or BaseEnemy for a big boss like Rotor)
##      with static make_patterns() + static draw_portrait(c, t)
##   2. one _entry(...) line in entries() below.
##
## BALANCE (all light enemies read these):
##   Playable characters: 100 HP.  Enemies: ENEMY_HP, tanky ones TANK_HP.
##   Every enemy pattern's damage is multiplied by DAMAGE_MULT. The numbers written in
##   each enemy's make_patterns() are already the "weaker than a character" values;
##   set DAMAGE_MULT to 0.7 to cut ALL of them by another 30% in one place.

const ENEMY_HP := 60
const TANK_HP := 70
const DAMAGE_MULT := 1.0

## Card names where the telegraph text is not the move name.
const CARD_NAMES := {"speech": "Emancipation Speech", "rocket_dash": "Rocket Man Dash", "hop_slam": "Royal Hop Slam"}


static var _cache: Array[Dictionary] = []


## Built once, then cached (CharacterRoster.all() is called a lot).
static func entries() -> Array[Dictionary]:
	if not _cache.is_empty():
		return _cache
	var list: Array[Dictionary] = []
	list.append(CharacterRoster._rotor())          # The original boss (100 HP, own file)
	list.append(_entry("kingfrog", "King Frog", "King Frog", KingFrog, Color(0.35, 0.80, 0.30)))
	list.append(_entry("frostjarl", "Frost Jarl Hrimgar", "Frost Jarl", FrostJarl, Color(0.35, 0.65, 1.0)))
	list.append(_entry("raphael", "Archangel Raphael", "Raphael", Raphael, Color(1.0, 0.85, 0.40)))
	list.append(_entry("elton", "Elton John", "Elton John", EltonJohn, Color(1.0, 0.40, 0.75)))
	list.append(_entry("lincoln", "Abraham Lincoln", "Lincoln", Lincoln, Color(0.75, 0.75, 0.80)))
	list.append(_entry("cybertrex", "Cyber T-Rex", "Cyber T-Rex", CyberTRex, Color(1.0, 0.25, 0.20)))
	# FIGHTS-MODE BOSSES (FightBoss): big HP, voice lines, their own boss music
	list.append(_entry("minos", "King Minos", "King Minos", KingMinos, Color(0.70, 0.88, 1.0), KingMinos.HP, "boss_minos"))
	list.append(_entry("sisyphus", "Sisyphus", "Sisyphus", Sisyphus, Color(1.0, 0.70, 0.25), Sisyphus.HP, "boss_sisyphus"))
	list.append(_entry("geyron", "Geyron", "Geyron", Geyron, Color(1.0, 0.30, 0.30), Geyron.HP, "boss_geyron"))
	list.append(_entry("kokusen", "Kokusen", "Kokusen", Kokusen, Color(0.85, 0.12, 0.18), Kokusen.HP, "boss_satan"))
	# ----- FROM STORY MODE: the stronger enemies (Versus HP = 1.6x their Story HP, at least 70) -----
	for e in STORY_ENEMIES:
		list.append(_story(e, false))
	# ----- FROM STORY MODE: the bosses that work outside Story (their full Story HP, own music) -----
	for e in STORY_BOSSES:
		list.append(_story(e, true))
	_cache = list
	return list


## [id, full name, short name, script, accent, music]. Left out on purpose: The Sun (her death is
## the Story finale), Blasphemy Caeser (transforms in a Story cutscene), Architect Chorus (needs the
## elevator), Void Massacre (climbs cave walls), the Void Horrids (a 3-boss group), The Shining (altar).
const STORY_ENEMIES := [
	["s_hydra", "Hydra Mutant", "Hydra", "HydraMutant", Color(0.45, 0.85, 0.35), "story_cave"],
	["s_golem", "Rock Golem", "Rock Golem", "RockGolem", Color(0.65, 0.45, 0.95), "story_geode"],
	["s_atomic", "The Atomic Creation", "Atomic Creation", "AtomicCreation", Color(0.45, 1.0, 0.35), "story_workshop"],
	["s_masker", "The Hollow Masker", "Hollow Masker", "HollowMasker", Color(0.85, 0.85, 0.95), "story_void"],
	["s_pained", "The Pained One", "Pained One", "PainedOne", Color(0.75, 0.30, 0.30), "story_darkcave", "duo"],
	["s_grin", "The Devilish Grin", "Devilish Grin", "DevilishGrin", Color(0.95, 0.30, 0.20), "story_darkcave", "duo"],
	["s_ambusher", "Ambusher", "Ambusher", "Ambusher", Color(0.55, 0.45, 0.35), "story_throne", "duo"],
	["s_camel", "Enlightened Camel Rider", "Camel Rider", "EnlightenedCamel", Color(0.95, 0.80, 0.40), "story_chase", "faith"],
	["s_saint", "Saint Warrior", "Saint Warrior", "SaintWarrior", Color(0.95, 0.85, 0.55), "story_altar"],
	["s_oven", "Oven Owner", "Oven Owner", "OvenOwner", Color(1.0, 0.50, 0.15), "story_workshop"],
	["s_brute", "Tribe Brute", "Tribe Brute", "TribeBrute", Color(0.75, 0.55, 0.40), "story_demiland", "faith"],
	["s_cultist", "Pelt Cultist", "Pelt Cultist", "PeltCultist", Color(0.95, 0.60, 0.20), "story_demiland", "faith"],
	["s_husk", "Husk", "Husk", "HuskTreant", Color(0.45, 0.35, 0.25), "story_demiland_night", "faith"],
	["s_serpent", "Humane Serpent", "Humane Serpent", "HumaneSerpent", Color(0.45, 0.75, 0.35), "story_cave"],
]
const STORY_BOSSES := [
	["s_blinded", "The Blinded Lord", "Blinded Lord", "BlindedLord", Color(0.45, 1.0, 0.35), "boss"],
	["s_forgemother", "The Forge Mother", "Forge Mother", "ForgeMother", Color(1.0, 0.55, 0.15), "boss_forge_father"],
	["s_archgolem", "The Architect's Golem", "Architect's Golem", "ArchitectsGolem", Color(0.40, 0.80, 1.0), "boss_golem"],
	["s_needle", "Child Wielding Needle", "Needle", "ChildNeedle", Color(0.90, 0.85, 1.0), "boss_needle", "duo"],
	["s_brothers", "The Brothers", "The Brothers", "TheBrothers", Color(0.92, 0.92, 0.95), "boss_brothers", "duo"],
	["s_animal", "Animal Lord", "Animal Lord", "AnimalLord", Color(0.80, 0.55, 0.30), "boss_animal", "duo"],
	["s_executor", "Executor", "Executor", "Executor", Color(0.65, 0.30, 0.95), "boss_executor", "duo"],
	["s_nature", "Mother Nature", "Mother Nature", "MotherNature", Color(0.45, 1.0, 0.45), "boss_nature", "duo"],
	["s_falsegod", "The False God", "False God", "FalseGod", Color(1.0, 0.30, 0.20), "boss_falsegod", "duo+faith"],
	["s_satan", "Satan", "Satan", "Satan", Color(1.0, 0.25, 0.10), "boss_satan", "duo+faith"],
	["s_prime", "The Enlightened First Prime", "First Prime", "FirstPrime", Color(1.0, 0.85, 0.40), "boss_prime", "faith"],
	["s_enlightened", "The Enlightened One", "Enlightened One", "EnlightenedOneBoss", Color(1.0, 0.90, 0.55), "boss_enlightened", "faith"],
	["s_grave", "The Caeser's Grave", "Caeser's Grave", "CaesersGrave", Color(0.60, 0.55, 0.45), "boss_grave"],
	["s_saintgolem", "The Saint Architect's Golem", "Saint Golem", "SaintGolem", Color(1.0, 0.90, 0.60), "boss_saint_golem"],
	["s_forgefather", "The Forge Father", "Forge Father", "ForgeFather", Color(1.0, 0.45, 0.10), "boss_forge_father"],
	["s_radchorus", "The Radioactive Chorus", "Radioactive Chorus", "RadioactiveChorus", Color(0.50, 1.0, 0.30), "boss_reactor"],
	["s_tribemaster", "The Tribe Master", "Tribe Master", "TribeMaster", Color(1.0, 0.40, 0.15), "boss_tribe", "faith"],
	["s_tiger", "The Last Tiger", "Last Tiger", "LastTiger", Color(1.0, 0.62, 0.20), "boss_tiger", "faith"],
	["s_treelord", "The LIVING Tree Lord", "Tree Lord", "TreeLord", Color(0.50, 1.0, 0.40), "boss_treelord", "faith"],
]


## A Story enemy / boss as a Versus roster entry. Reads its real HP and size from the enemy itself.
static func _story(e: Array, boss: bool) -> Dictionary:
	var script: Script = _script_named(String(e[3]))
	var inst := script.new() as BaseEnemy
	var d: CharacterData = inst.call("_make_data")
	var hp := d.max_hp
	if inst.has_method("boss_forms"):                       # Bosses with several forms: all of them
		hp = 0
		for f in inst.call("boss_forms"):
			hp += int(f.get("hp", 0))
	var scale_k: float = float(inst.get("art_scale")) if "art_scale" in inst else 1.0
	var art_h := d.body_size.y * scale_k * 1.2 + 20.0         # So the card shows the whole body
	inst.free()
	# SCALING for a 1-v-1 against a normal Versus hero:
	#   "duo"   = fought WITH the CPU partner in Story (Colosseum 5): HP x DUO_HP, damage x DUO_DMG
	#   "faith" = fought with DEEP FAITH active (+20% HP, +1 flask): HP x FAITH_HP, damage x FAITH_DMG
	var tag := String(e[6]) if e.size() > 6 else ""
	var hp_mult := 1.0
	var dmg_mult := 1.0
	if tag.contains("duo"):
		hp_mult *= DUO_HP
		dmg_mult *= DUO_DMG
	if tag.contains("faith"):
		hp_mult *= FAITH_HP
		dmg_mult *= FAITH_DMG
	var versus_hp := roundi(float(hp) * hp_mult) if boss else maxi(70, roundi(float(hp) * 1.6 * hp_mult))
	var entry := _entry(String(e[0]), String(e[1]), String(e[2]), script, e[4], versus_hp if boss else 0, String(e[5]))
	if boss:
		entry["hp_mult"] = hp_mult                             # Applied to EVERY form (ArenaManager)
	else:
		entry["versus_hp"] = versus_hp
	entry["dmg_mult"] = dmg_mult
	entry["portrait_h"] = art_h
	entry["story"] = true
	entry["class"] = String(e[3])                              # Shown in Versus only once met in Story (StoryProgress.seen)
	var why := ""
	if tag.contains("duo"):
		why += ", scaled for 1-v-1 (it was fought with a partner)"
	if tag.contains("faith"):
		why += ", scaled down (it was fought with Deep Faith)"
	var moves: Array = entry["moves"]
	moves[moves.size() - 1] = {"key": "!", "name": ("BOSS: %d HP" if boss else "%d HP") % versus_hp,
		"info": "From STORY MODE" + why}
	return entry


## Versus scaling of Story enemies / bosses (see _story()).
const DUO_HP := 0.70
const DUO_DMG := 0.85
const FAITH_HP := 0.85
const FAITH_DMG := 0.88


static func _script_named(class_id: String) -> Script:
	for c in ProjectSettings.get_global_class_list():
		if String(c["class"]) == class_id:
			return load(String(c["path"]))
	push_error("EnemyManager: no class " + class_id)
	return Parasite


## Roster entry (same format as the playable characters). The card's move list is
## built from the enemy's real patterns, so it can never go out of date.
## boss_hp > 0 = a Fights-mode boss (card says BOSS), music = its fight track.
static func _entry(id: String, full_name: String, short: String, script: Script, accent: Color,
		boss_hp: int = 0, music: String = "boss") -> Dictionary:
	var moves: Array = []
	var patterns: Array = script.call("make_patterns")
	for p: EnemyPattern in patterns:
		var info := ""
		if p.damage > 0:
			info = "%d damage" % maxi(1, roundi(p.damage * DAMAGE_MULT))
		else:
			info = "no damage"
		info += ", %ss cooldown" % CharacterRoster._num(p.cooldown)
		if p.note != "":
			info += ", " + p.note
		var nm: String = CARD_NAMES.get(p.id, String(p.display_name).trim_suffix("!").capitalize())
		moves.append({"key": "", "name": nm, "info": info})
	if boss_hp > 0:
		moves.append({"key": "!", "name": "BOSS: %d HP" % boss_hp, "info": "Enraged below 50% HP, voice lines, own boss music"})
	else:
		var hp := TANK_HP if script in [FrostJarl, CyberTRex] else ENEMY_HP
		moves.append({"key": "!", "name": "%d HP" % hp, "info": "PvE enemy: weaker than a playable character"})
	return {
		"id": id,
		"name": full_name,
		"short": short,
		"selectable": true,
		"enemy": true,
		"boss": boss_hp > 0,
		"music": music,
		"accent": accent,
		"art": script,                 # Enemy scripts have static draw_portrait(c, t)
		"fighter": script,
		"moves": moves,
	}
