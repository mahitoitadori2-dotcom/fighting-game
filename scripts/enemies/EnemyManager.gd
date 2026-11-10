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
	_cache = list
	return list


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
