class_name CharacterData
extends Resource
## Base stats shared by EVERY character. Specific characters extend this
## (see architect_data.gd). Scripts only READ from here, nothing is hard-coded.

@export var character_name := "Basic Model"

@export_group("Body")
@export var body_size := Vector2(64, 128)        # Hitbox AND hurtbox size. Never changes with art.

@export_group("Health")
@export var max_hp := 100
## Damage type -> multiplier on damage TAKEN, e.g. {"explosion": 1.25, "void": 1.25}.
@export var damage_kind_taken: Dictionary = {}
@export var respawn_delay := 1.5               # Death animation plays during this

@export_group("Movement")
@export var move_speed := 330.0
@export var acceleration := 2600.0
@export var deceleration := 3400.0
@export var air_acceleration := 1700.0
@export var air_deceleration := 900.0
@export var crouch_speed_multiplier := 0.4

@export_group("Jump")
@export var jump_force := 720.0
@export var gravity := 2000.0
@export var fall_gravity_multiplier := 1.35
@export var jump_cut_multiplier := 0.5
@export var coyote_time := 0.1
@export var jump_buffer_time := 0.1
@export var max_fall_speed := 900.0
@export var fast_fall_speed := 1500.0
@export var fast_fall_extra_gravity := 3500.0

@export_group("Punch")
@export var punch_damage := 3
@export var punch_startup := 0.15
@export var punch_active := 0.10
@export var punch_recovery := 0.20
@export var punch_size := Vector2(56, 32)
@export var punch_offset := Vector2(38, -86)     # Hitbox center relative to feet, facing right
@export var punch_knockback := Vector2(260, -120)
@export var punch_lunge_speed := 200.0
@export var attack_friction_multiplier := 0.25

@export_group("Block")
@export var block_enabled := true
@export var perfect_block_window := 0.15         # F pressed within this many seconds BEFORE impact
@export var block_knockback_multiplier := 0.3
@export var perfect_block_gauge := 50.0          # G Gauge points (100 = one segment)

@export_group("Hit Reaction")
@export var hitstun_time := 0.22
@export var hitstun_ground_friction := 1600.0
@export var hitstun_air_friction := 250.0
@export var grab_escape_presses := 8             # Button presses needed to escape a grab
@export var grab_escape_decay := 1.5             # Progress lost per second

@export_group("Onslaught (GLOBAL system - turn on per character)")
@export var onslaught_melee_enabled := false
@export var onslaught_projectile_enabled := false
@export var onslaught_trap_enabled := false
@export var onslaught_flash_time := 0.4
@export var onslaught_combo_hits := 4            # Consecutive melees that trigger the flash
@export var onslaught_combo_window := 0.9        # Max seconds between punch STARTS to keep the chain
@export var onslaught_melee_damage := 6
@export var onslaught_melee_knockback := Vector2(480, -260)
@export var onslaught_move_damage_mult := 1.5
@export var onslaught_move_knockback_mult := 1.4
@export var onslaught_move_cooldown_mult := 1.5
@export var afterburn_duration := 10.0
@export var afterburn_melee_damage := 2
## move id -> "projectile" / "trap" / "" (empty = that move can NOT be Onslaughted)
@export var onslaught_move_types: Dictionary = {}

@export_group("G Gauge")
@export var gauge_enabled := false
@export var gauge_segment_size := 100.0
@export var gauge_segments := 3
@export var gauge_per_damage := 2.0              # Gauge points per damage dealt
@export var gauge_auto_start_time := 300.0       # Fight seconds before auto-fill begins
@export var gauge_auto_base_rate := 1.0          # Points / second at start
@export var gauge_auto_growth := 0.02            # Extra points/second gained per second after start


@export_group("CPU")
## move id -> Vector2(min_distance, max_distance) where the CPU likes to use it.
@export var ai_move_ranges: Dictionary = {}


static func basic_model() -> CharacterData:
	return CharacterData.new()


static func dummy() -> CharacterData:
	var d := CharacterData.new()
	d.character_name = "Dummy"
	return d
