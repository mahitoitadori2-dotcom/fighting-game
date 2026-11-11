class_name AntiArchitectData
extends ArchitectData
## The ANTI ARCHITECT. Same body / movement as the Architect (inherits ArchitectData), his own
## moves. Built to RUSH: the Onslaught flash comes after only 2 punches, lasts longer, and
## Workflies / Anti Laser can be Onslaughted too; Afterburn is short.

@export_group("1 Workflies")
@export var workfly_count := 2
@export var workfly_damage := 3
@export var workfly_speed := 560.0
@export var workfly_life := 3.0
@export var workfly_cooldown := 2.6

@export_group("2 Anti Laser")
@export var laser_damage := 9
@export var laser_range := 920.0
@export var laser_height := 22.0
@export var laser_cooldown := 5.5
@export var laser_knockback := Vector2(280, -120)

@export_group("3 Overcharge")
@export var overcharge_charge_time := 0.45
@export var overcharge_damage := 11
@export var overcharge_radius := 150.0
@export var overcharge_self_damage := 2          # Tiny; never lethal
@export var overcharge_cooldown := 7.0
@export var overcharge_knockback := Vector2(420, -360)

@export_group("G1 BattleFlies")
@export var battlefly_count := 3
@export var battlefly_damage := 4
@export var battlefly_hits := 2                  # Each fly hits twice, then pops
@export var battlefly_speed := 720.0

@export_group("G2 Energy Pool")
@export var pool_width := 320.0
@export var pool_duration := 5.0
@export var pool_tick := 0.5
@export var pool_tick_damage := 2

@export_group("G3 Never Out Of Plans")
@export var plans_delay := 0.9
@export var plans_damage := 16
@export var plans_radius := 220.0
@export var plans_shards := 8                   # Metal shards AND energy shards (each)
@export var plans_shard_damage := 3
@export var plans_flies := 3
@export var plans_pools := 2


func _init() -> void:
	super._init()
	character_name = "Anti Architect"
	punch_damage = 3
	# ONSLAUGHT A LOT: the flash comes after 2 punches (Architect: 4), lasts longer, cheap afterburn
	onslaught_melee_enabled = true
	onslaught_projectile_enabled = true
	onslaught_trap_enabled = false
	onslaught_combo_hits = 2
	onslaught_combo_window = 1.1
	onslaught_flash_time = 0.6
	onslaught_melee_damage = 7
	afterburn_duration = 4.0
	onslaught_move_cooldown_mult = 1.2
	onslaught_move_types = {"workflies": "projectile", "laser": "projectile", "overcharge": ""}
	move_speed *= 1.08                            # A little faster than the Architect
	gauge_enabled = true
	ai_move_ranges = {"workflies": Vector2(120, 700), "laser": Vector2(150, 900), "overcharge": Vector2(0, 140)}


## STORY MODE buff (Story only, own data copy - Versus keeps the numbers above). Like the
## Warrior / Architect Story buffs: harder hits, shorter cooldowns. Overrides the Architect's.
func apply_story_buff() -> void:
	punch_damage = 5                     # (3)
	onslaught_melee_damage = 10          # (7)
	workfly_damage = 4                   # (3)
	workfly_cooldown = 2.0               # (2.6)
	laser_damage = 13                    # (9)
	laser_cooldown = 4.0                 # (5.5)
	overcharge_damage = 15               # (11)
	overcharge_cooldown = 5.0            # (7.0)
	battlefly_damage = 6                 # (4)
	pool_tick_damage = 3                 # (2)
	plans_damage = 24                    # (16)
	plans_shard_damage = 4               # (3)
