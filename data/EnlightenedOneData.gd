class_name EnlightenedOneData
extends CharacterData
## The Enlightened One: golden-armored masked pilgrim with bronze gauntlets.
## Every number of his kit lives here. Body 64x128 / HP / movement / block inherited.
## WEAKNESS: takes x1.25 damage from EXPLOSION and VOID damage (damage_kind_taken).
## No G Gauge passive: the gauge is only for Ultimates.

@export_group("Bronze Gloves (M1)")
## Uses CharacterData punch_* values (damage set to 4 in _init). NOT Onslaught-able.

@export_group("Beam Blast (1)")
@export var beam_cooldown := 7.0
@export var beam_count := 2
@export var beam_damage := 5
@export var beam_speed := 1300.0
@export var beam_lifetime := 0.55
@export var beam_spacing := 16.0                 # Vertical gap between the beams
@export var beam_knockback := Vector2(120, -60)
@export var beam_spawn_offset := Vector2(34, -84)

@export_group("Lord's Heal (2)")
@export var heal_cooldown := 15.0
@export var heal_percent := 0.4                  # 40% of each ally's max HP
@export var heal_radius := 240.0                 # Team heal radius (1v1: just himself)

@export_group("Helpers! (3)")
@export var helpers_cooldown := 20.0
@export var helper_count := 2
@export var helper_hp := 20
@export var helper_lifetime := 10.0
@export var helper_speed := 250.0
@export var helper_slash_damage := 5
@export var helper_slash_range := 62.0
@export var helper_slash_interval := 0.7
@export var helper_knockback := Vector2(110, -80)

@export_group("G1: Godly O' Light")
@export var light_damage := 25
@export var light_range := 1150.0
@export var light_height := 96.0                 # Wide beam
@export var light_charge := 0.35
@export var light_duration := 0.5
@export var light_recovery := 0.3
@export var light_knockback := Vector2(680, -320)

@export_group("G2: Throne")
@export var throne_damage := 30
@export var throne_speed := 650.0
@export var throne_turn_rate := 1.2              # Slight homing
@export var throne_lifetime := 2.6
@export var throne_knockback := Vector2(720, -420)

@export_group("G3: Enlightened Gorilla Form")
@export var gorilla_duration := 20.0
@export var gorilla_damage := 9
@export var gorilla_range_mult := 1.3            # Slightly longer reach
@export var gorilla_speed_mult := 0.65           # Punch timings x0.65 = faster
@export var gorilla_scale := 1.25                # Bigger sprite (hurtbox unchanged)
@export var gorilla_move_mult := 1.15


func _init() -> void:
	character_name = "The Enlightened One"
	punch_damage = 4
	# WEAKNESS: +25% damage taken from explosions and void attacks.
	damage_kind_taken = {"explosion": 1.25, "void": 1.25}
	# M1 can NOT be Onslaughted. No move is Onslaught-able.
	onslaught_melee_enabled = false
	onslaught_projectile_enabled = false
	onslaught_trap_enabled = false
	onslaught_move_types = {"beam": "", "heal": "", "helpers": ""}
	gauge_enabled = true
	ai_move_ranges = {"beam": Vector2(150, 750), "heal": Vector2(0, 9999), "helpers": Vector2(200, 520)}
