class_name WarriorData
extends CharacterData
## The Warrior: a body of living Void. Every number of his kit lives here.
## Body size / HP / movement / block are inherited from CharacterData (same as Architect).

@export_group("Sword (basic attack)")
## Uses CharacterData punch_damage / timings: 3 damage, same as the Architect's punch.
## STORY MODE BUFF: apply_story_buff() (bottom of this file) - Versus uses these defaults.
@export var sword_lunge_speed := 160.0
## SWORD POWER (Story boss fights, e.g. Blasphemy Caeser): each level makes the sword
## bigger (hitbox + art) and stronger. Level 0 = normal.
@export var sword_power_damage := 0.3             # +30% damage per level (5 -> 7 -> 8)
@export var sword_power_size := 0.35              # +35% blade length / hitbox per level
## The sword's own hitbox (the punch box sat at chest height and missed short enemies:
## Parasites, Kharlemings...). This one covers head to toes in front of him.
@export var sword_offset := Vector2(44, -58)      # Centre, relative to the feet (facing right)
@export var sword_size := Vector2(70, 114)        # -115 .. -1 px: no blind spot at the bottom

@export_group("Clinging Grab (1)")
@export var grab_cooldown := 5.0
@export var grab_damage := 5
@export var grab_onslaught_damage := 7           # 5 x 1.5 rounded DOWN
@export var grab_range := 380.0
@export var grab_extend_speed := 1500.0
@export var grab_return_speed := 1800.0
@export var grab_tip_size := Vector2(40, 88)     # Tall tip: also catches small / low enemies
@export var grab_height := -54.0                 # Tentacle height above the feet
@export var grab_pull_time := 0.22               # Seconds for the fling
@export var grab_pull_distance := 70.0           # Where the victim lands in front of the Warrior
@export var grab_hitstun := 0.35
@export var grab_blockable := false
@export var grab_onslaught_blast := 90.0

@export_group("Royal Destiny (2)")
@export var royal_cooldown := 17.0
@export var royal_duration := 8.0
@export var royal_damage_reduction := 0.4        # Takes 40% less damage
@export var royal_swing_slow := 1.6              # Sword startup/active/recovery x1.6

@export_group("Eternal Grasp (3)")
@export var eternal_cooldown := 20.0
@export var eternal_duration := 1.4
@export var eternal_wave_interval := 0.3         # A new burst of spikes every 0.3 s
@export var eternal_spike_damage := 4
@export var eternal_range := 150.0               # Short range
@export var eternal_spike_count := 12
@export var eternal_knockback := Vector2(110, -60)

@export_group("G1: Unstable Expulsion")
@export var mini_spike_count := 6
@export var mini_spike_damage := 3
@export var mini_spike_speed := 520.0
@export var mini_spike_turn := 7.0
@export var mini_spike_lifetime := 2.2

@export_group("G2: Shadow Swarm")
@export var beam_damage := 25
@export var beam_range := 950.0
@export var beam_height := 50.0
@export var beam_charge := 0.4
@export var beam_duration := 0.45
@export var beam_recovery := 0.3
@export var beam_knockback := Vector2(560, -220)

@export_group("G3: The Fall of the Physic")
@export var timestop_snap_time := 0.35
@export var timestop_duration := 5.0
@export var timestop_bomb_penalty_hp := 25


func _init() -> void:
	character_name = "Warrior"
	# Sword can NOT be Onslaughted and never causes Afterburn.
	onslaught_melee_enabled = false
	# Clinging Grab CAN be Onslaughted (uses the projectile flash).
	onslaught_projectile_enabled = true
	onslaught_trap_enabled = false
	onslaught_move_types = {"grab": "projectile", "royal": "", "eternal": ""}
	gauge_enabled = true
	ai_move_ranges = {"grab": Vector2(130, 370), "royal": Vector2(0, 450), "eternal": Vector2(0, 120)}


## STORY MODE ONLY (StoryManager calls this on the fighter's own data copy; Versus keeps
## the defaults above). The 2026-11-08 Warrior buff: more damage, shorter cooldowns.
func apply_story_buff() -> void:
	punch_damage = 5                     # Sword (Versus 3)
	grab_cooldown = 3.5                  # (5.0)
	grab_damage = 7                      # (5)
	grab_onslaught_damage = 10           # (7)
	royal_cooldown = 12.0                # (17.0)
	eternal_cooldown = 13.0              # (20.0)
	eternal_spike_damage = 5             # (4)
	mini_spike_damage = 4                # (3)
	beam_damage = 30                     # Shadow Swarm (25)
