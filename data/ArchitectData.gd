class_name ArchitectData
extends CharacterData
## The Mighty Architect. Every number of his kit lives here.

@export_group("Cast")
@export var cast_lock_time := 0.2

@export_group("Rocket Delivery")
@export var rocket_damage := 10
@export var rocket_cooldown := 6.0
@export var rocket_speed := 540.0
@export var rocket_turn_rate := 4.0              # Homing strength (radians / second)
@export var rocket_lifetime := 4.0
@export var rocket_knockback := Vector2(400, -220)   # High
@export var rocket_blast_radius := 70.0          # Visual only
@export var rocket_launch_angle_deg := -25.0
@export var rocket_spawn_offset := Vector2(36, -90)
@export var triple_rocket_spread_deg := 16.0

@export_group("HNCT Triangle Bomb")
@export var hnct_damage := 20
@export var hnct_cooldown := 12.0
@export var hnct_knockback := Vector2(300, -320)     # Medium
@export var hnct_blast_radius := 120.0
@export var hnct_arm_time := 0.4
@export var hnct_place_offset := 56.0
@export var hnct_triggers_on_owner := false

@export_group("Armaggedon Drill")
@export var drill_cooldown_hit := 15.0
@export var drill_cooldown_miss := 20.0
@export var drill_startup := 0.18
@export var drill_lunge_time := 0.28
@export var drill_lunge_speed := 900.0
@export var drill_hitbox_size := Vector2(90, 44)
@export var drill_hitbox_offset := Vector2(62, -62)
@export var drill_grab_damage := 4
@export var drill_tick_damage := 4
@export var drill_tick_count := 6                # 4 + 6x4 = 28 total
@export var drill_tick_interval := 0.35
@export var drill_miss_self_damage := 7
@export var drill_miss_recovery := 0.5
@export var drill_end_recovery := 0.25
@export var drill_hold_distance := 70.0
@export var drill_blockable := false

@export_group("Void Goo")
@export var goo_width := 360.0
@export var goo_height := 44.0
@export var goo_duration := 6.0
@export var goo_slow_multiplier := 0.4           # Enemy speed x0.4
@export var goo_extra_damage := 0.4              # Enemy takes +40% damage
@export var goo_tick_damage := 1                 # Small damage while standing in it (lets Goo get the kill)
@export var goo_tick_interval := 0.5

@export_group("Full Arsenal of the Hexagon")
@export var arsenal_duration := 8.0
@export var arsenal_goo_count := 2
@export var arsenal_goo_spacing := 170.0
@export var arsenal_hnct_count := 2
@export var arsenal_hnct_spacing := 120.0
@export var arsenal_speed_mult := 1.35           # Mechanical arms = faster
@export var arsenal_jump_mult := 1.12
@export var arsenal_knockback_taken_mult := 0.4  # Hard to knock around


func _init() -> void:
	character_name = "The Mighty Architect"
	# Onslaught flags: turn these on/off per character.
	onslaught_melee_enabled = true
	onslaught_projectile_enabled = true
	onslaught_trap_enabled = true
	onslaught_move_types = {"rocket": "projectile", "hnct": "trap", "drill": ""}
	gauge_enabled = true
	# CPU: distance range (px) where it likes to use each move.
	ai_move_ranges = {"rocket": Vector2(160, 900), "hnct": Vector2(60, 260), "drill": Vector2(0, 150)}


## STORY MODE ONLY (StoryManager calls this on the fighter's own data copy; Versus keeps
## the defaults above). Same idea as the Warrior's Story buff: more damage, shorter cooldowns.
func apply_story_buff() -> void:
	punch_damage = 5                     # Punch (Versus 3)
	rocket_damage = 13                   # Rocket Delivery + Triple Rocket (10)
	rocket_cooldown = 4.5                # (6.0)
	hnct_damage = 26                     # HNCT Triangle Bomb (20)
	hnct_cooldown = 8.5                  # (12.0)
	drill_grab_damage = 5                # Armaggedon Drill: 5 + 6 x 5 = 35 total (4 + 6 x 4 = 28)
	drill_tick_damage = 5
	drill_cooldown_hit = 10.0            # (15.0)
	drill_cooldown_miss = 14.0           # (20.0)
	goo_tick_damage = 2                  # Void Goo (1)
