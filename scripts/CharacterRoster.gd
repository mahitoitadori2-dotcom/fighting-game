class_name CharacterRoster
extends RefCounted
## Every character, in one place. The Character Select grid is built from
## all(), and ArenaManager spawns fighters from these entries.
## Adding a character = adding ONE entry function + one line in all().
##
## Entry fields:
##   id          unique string id
##   name        display name
##   selectable  false = shows as a locked card
##   hidden      true = never shown in the grid (the Dummy)
##   accent      card highlight colour
##   art         script with a static draw_portrait(canvas, time) function
##   fighter     script to spawn (must extend Fighter; playable ones extend ControlledFighter)
##   ai          BaseAI subclass that controls this character as a CPU. EVERY playable
##               character MUST have one (never make Player-only characters).
##   moves       Array of {"key", "name", "info"} shown under the card

const MAIN_MENU := "res://scenes/MainMenu.tscn"
const CHARACTER_SELECT := "res://scenes/CharacterSelect.tscn"
const ARENA := "res://Main.tscn"              # Kept for old code: the Test Arena
const PRE_FIGHT := "res://scenes/PreFight.tscn"
const MATCH_SETTINGS := "res://scenes/MatchSettings.tscn"
const DUMMY_ID := "dummy"

## YOUR character. Always set. Survives scene changes (static).
static var selected_id := "architect"
## The OPPONENT. "" = nobody picked = the Dummy.
static var opponent_id := ""


static func all() -> Array[Dictionary]:
	var list: Array[Dictionary] = []
	list.append(_architect())
	list.append(_warrior())
	list.append(_fire_lord())
	list.append(_enlightened_one())
	# Add future characters here, e.g.:
	# list.append(_some_new_fighter())
	# PvE enemies ("enemy": true) - Character Select shows them in ENEMY TEST.
	# Rotor + every other enemy come from EnemyManager (one list, one place).
	list.append_array(EnemyManager.entries())
	return list


## Characters shown in the Character Select grid.
static func playable() -> Array[Dictionary]:
	var list: Array[Dictionary] = []
	for e in all():
		if not e.get("hidden", false) and not e.get("enemy", false):
			list.append(e)
	return list


## PvE enemies / bosses (opponent only).
static func enemies() -> Array[Dictionary]:
	var list: Array[Dictionary] = []
	for e in all():
		if e.get("enemy", false):
			list.append(e)
	return list


static func get_entry(id: String) -> Dictionary:
	if id == DUMMY_ID or id == "":
		return _dummy()
	for e in all():
		if e["id"] == id:
			return e
	return all()[0]


static func selected() -> Dictionary:
	return get_entry(selected_id)


## Opponent entry: the Dummy when nothing is picked.
static func opponent() -> Dictionary:
	return get_entry(opponent_id)


static func has_opponent() -> bool:
	return opponent_id != ""


# ============================================================
# CHARACTERS
# ============================================================
static func _architect() -> Dictionary:
	# Numbers are read from ArchitectData so this list never goes out of sync.
	var d := ArchitectData.new()
	var drill_total := d.drill_grab_damage + d.drill_tick_damage * d.drill_tick_count
	return {
		"id": "architect",
		"name": "The Mighty Architect",
		"short": "Architect",
		"selectable": true,
		"accent": Color(0.30, 0.90, 0.35),
		"art": ArchitectArt,
		"fighter": Player,
		"ai": ArchitectAI,
		"moves": [
			{"key": "LMB", "name": "Punch",
				"info": "%d damage" % d.punch_damage},
			{"key": "1", "name": "Rocket Delivery",
				"info": "%d damage, %ss cooldown" % [d.rocket_damage, _num(d.rocket_cooldown)]},
			{"key": "2", "name": "HNCT Triangle Bomb",
				"info": "%d damage, %ss cooldown" % [d.hnct_damage, _num(d.hnct_cooldown)]},
			{"key": "3", "name": "Armaggedon Drill",
				"info": "%d total damage, %ss hit / %ss miss cooldown" % [drill_total, _num(d.drill_cooldown_hit), _num(d.drill_cooldown_miss)]},
			{"key": "G", "name": "Void Goo",
				"info": "2 Bar Ultimate, slow + %d%% defense decrease" % roundi(d.goo_extra_damage * 100.0)},
			{"key": "G", "name": "Full Arsenal of the Hexagon",
				"info": "3 Bar Ultimate"},
		],
	}


static func _warrior() -> Dictionary:
	var d := WarriorData.new()
	return {
		"id": "warrior",
		"name": "Warrior",
		"short": "Warrior",
		"selectable": true,
		"accent": Color(0.70, 0.45, 1.00),
		"art": WarriorArt,
		"fighter": Warrior,
		"ai": WarriorAI,
		"moves": [
			{"key": "LMB", "name": "Sword",
				"info": "%d damage, can't be Onslaughted" % d.punch_damage},
			{"key": "1", "name": "Clinging Grab",
				"info": "%d damage, pulls enemy to you, %ss cooldown. Onslaught: pulls YOU, %d damage" % [d.grab_damage, _num(d.grab_cooldown), d.grab_onslaught_damage]},
			{"key": "2", "name": "Royal Destiny",
				"info": "%ss white armor, -%d%% damage taken, slower swings, %ss cooldown" % [_num(d.royal_duration), roundi(d.royal_damage_reduction * 100.0), _num(d.royal_cooldown)]},
			{"key": "3", "name": "Eternal Grasp",
				"info": "Shadow spikes all around, %d damage each, %ss cooldown" % [d.eternal_spike_damage, _num(d.eternal_cooldown)]},
			{"key": "G", "name": "Mini Eternal Grasp",
				"info": "1 Bar Ultimate, homing spikes, %d damage each" % d.mini_spike_damage},
			{"key": "G", "name": "Shadow Swarm",
				"info": "2 Bar Ultimate, face beam, %d damage" % d.beam_damage},
			{"key": "G", "name": "The Fall of the Physic",
				"info": "3 Bar Ultimate, TIME STOP %ss. Stepping on an HNCT bomb breaks it: -%d HP, all moves on cooldown, Afterburn" % [_num(d.timestop_duration), d.timestop_bomb_penalty_hp]},
		],
	}


static func _fire_lord() -> Dictionary:
	var d := FireLordData.new()
	return {
		"id": "firelord",
		"name": "Nightmare Lord",
		"short": "Nightmare Lord",
		"selectable": true,
		"accent": Color(1.0, 0.15, 0.15),
		"art": FireLordArt,
		"fighter": FireLord,
		"ai": FireLordAI,
		"moves": [
			{"key": "LMB", "name": "Punch",
				"info": "%d damage, can't be Onslaughted" % d.punch_damage},
			{"key": "1", "name": "BloodFlame Spit",
				"info": "%d red flames, %d damage each, %ss cooldown" % [d.flame_count, d.flame_damage, _num(d.flame_cooldown)]},
			{"key": "2", "name": "Bat Escape",
				"info": "%d bats, %d damage each, %ss cooldown. Hit during it: bat form %ss" % [d.bat_count, d.bat_damage, _num(d.bat_cooldown), _num(d.bat_form_duration)]},
			{"key": "3", "name": "Launch O' Spikes",
				"info": "Jump + %d flames (%d dmg), slam + floor spikes (%d dmg), %ss cooldown" % [d.spikes_burst_count, d.spikes_burst_damage, d.spikes_floor_damage, _num(d.spikes_cooldown)]},
			{"key": "G", "name": "Passive",
				"info": "+1 damage to ALL attacks per G bar (max +3), suit tears"},
			{"key": "G", "name": "Double Trouble",
				"info": "1 Bar Ultimate, %d flames + %d bats" % [d.double_flame_count, d.double_bat_count]},
			{"key": "G", "name": "Volatile Nightmare",
				"info": "2 Bar Ultimate, body spikes (%d dmg) + oil that ignites (%d dmg/s)" % [d.volatile_spike_damage, d.oil_burn_damage]},
			{"key": "G", "name": "The Ritual of the Troupe",
				"info": "3 Bar Ultimate, Nightmare Heart explodes: %d dmg + flames, bats, oil" % d.ritual_damage},
		],
	}


static func _enlightened_one() -> Dictionary:
	var d := EnlightenedOneData.new()
	return {
		"id": "enlightened",
		"name": "The Enlightened One",
		"short": "Enlightened One",
		"selectable": true,
		"accent": Color(1.0, 0.82, 0.25),
		"art": EnlightenedOneArt,
		"fighter": EnlightenedOne,
		"ai": EnlightenedOneAI,
		"moves": [
			{"key": "LMB", "name": "Bronze Gloves",
				"info": "%d damage, can't be Onslaughted" % d.punch_damage},
			{"key": "1", "name": "Beam Blast",
				"info": "%d golden beams, %d damage each, %ss cooldown" % [d.beam_count, d.beam_damage, _num(d.beam_cooldown)]},
			{"key": "2", "name": "Lord's Heal",
				"info": "Heals %d%% max HP to allies in radius (1v1: himself), %ss cooldown" % [roundi(d.heal_percent * 100.0), _num(d.heal_cooldown)]},
			{"key": "3", "name": "Helpers!",
				"info": "%d cocooned blade helpers, %d dmg slashes, %d HP, %ss, %ss cooldown" % [d.helper_count, d.helper_slash_damage, d.helper_hp, _num(d.helper_lifetime), _num(d.helpers_cooldown)]},
			{"key": "G", "name": "Godly O' Light",
				"info": "1 Bar Ultimate, huge wide beam, %d damage" % d.light_damage},
			{"key": "G", "name": "Throne",
				"info": "2 Bar Ultimate, hurled golden throne, %d damage" % d.throne_damage},
			{"key": "G", "name": "Enlightened Gorilla Form",
				"info": "3 Bar Ultimate, %ss: bigger, M1 only, %d damage, faster" % [_num(d.gorilla_duration), d.gorilla_damage]},
			{"key": "!", "name": "Weakness",
				"info": "Takes x1.25 damage from Explosions and Void attacks"},
		],
	}


## ENEMY: Rotor (BaseEnemy + EnemyPattern). Moves list is built from his real patterns.
static func _rotor() -> Dictionary:
	var moves: Array = []
	for p in Rotor.make_patterns():
		var info := "%d damage" % p.damage
		info += ", no cooldown" if p.cooldown <= 0.0 else ", %ss cooldown" % _num(p.cooldown)
		if p.big:
			info += ", telegraphed"
		if p.phase_weights.size() > 0 and p.phase_weights[0] <= 0.0:
			info += " (Phase 2)"
		moves.append({"key": "", "name": String(p.display_name).trim_suffix("!").capitalize(), "info": info})
	moves.append({"key": "!", "name": "Enraged (below 50% HP)", "info": "Faster, glowing fur, cooldowns 20% faster"})
	return {
		"id": "rotor",
		"name": "Rotor",
		"short": "Rotor",
		"selectable": true,
		"enemy": true,
		"accent": Color(0.45, 0.70, 1.0),
		"art": RotorArt,
		"fighter": Rotor,
		"moves": moves,
	}


static func _dummy() -> Dictionary:
	return {
		"id": DUMMY_ID,
		"name": "Dummy",
		"short": "Dummy",
		"selectable": false,
		"hidden": true,
		"accent": Color(0.95, 0.80, 0.25),
		"art": Dummy,
		"fighter": Dummy,
		"moves": [{"key": "", "name": "Does not fight", "info": "100 HP training dummy, INF. lives for both sides"}],
	}


static func _num(f: float) -> String:
	return str(int(f)) if is_equal_approx(f, roundf(f)) else "%.1f" % f
