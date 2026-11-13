class_name StoryBuff
extends RefCounted
## STORY BUFF: a small, HIDDEN buff for every character you play in Story Mode (you and your
## Colosseum 5 CPU partner). Never shown anywhere in the game, never used in Versus.
## Stacks with the per-character Story buffs (WarriorData / ArchitectData.apply_story_buff) and
## with Deep Faith Payoff. Applied by StoryManager._story_buff() on the fighter's own data copy.

const HP_MULT := 1.10                     # +10% max HP
const POWER := 1.10                       # +10% damage dealt (Fighter.story_power)
const DEFENSE := 0.90                     # -10% damage taken (Fighter.story_defense)
const SPEED_MULT := 1.05                  # +5% walk speed
const COOLDOWN_MULT := 0.92               # Every move cooldown 8% shorter
const GAUGE_MULT := 1.15                  # The G Gauge fills 15% faster on its own


static func apply(f: Fighter) -> void:
	if f == null or f.data == null or f.has_meta("story_buff"):
		return
	f.set_meta("story_buff", true)                          # Never twice on the same fighter
	var d := f.data
	d.max_hp = roundi(float(d.max_hp) * HP_MULT)
	f.hp = d.max_hp
	d.move_speed *= SPEED_MULT
	for prop in d.get_property_list():
		var n := String(prop["name"])
		if n.contains("cooldown") and not n.ends_with("_mult") and int(prop["type"]) == TYPE_FLOAT:
			d.set(n, float(d.get(n)) * COOLDOWN_MULT)
	if "gauge_auto_base_rate" in d:
		d.gauge_auto_base_rate *= GAUGE_MULT
	f.story_power = POWER
	f.story_defense = DEFENSE
	f.health_changed.emit(f.hp, d.max_hp)
