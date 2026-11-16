class_name TechnicianData
extends CharacterData
## THE TECHNICIAN (Versus): Claude's own character (2026-11-16), canon to Terra Craterum - an
## engineer of the ancient Kharleming ship (the caste that built the Technician's Breaker). A small
## Kharleming driving a walking RIG it built from the wreck's scrap. A ZONER / TRAPPER: strong at
## range, weaker up close. Can NOT Onslaught. Every number of the kit lives here.
## Balance target: Architect / Warrior (100 HP, ~10-20 dmg moves on 6-12 s cooldowns).
## Tuned 2026-11-16 after 12 CPU matches (4 / 12 wins = too weak): HP 95 -> 100, wrench 4 -> 5,
## bolts 3 -> 4, hook 5 -> 6, coil 8 -> 9 dmg and 12 -> 10 s.

@export_group("Scrap Turret (1)")
@export var turret_cooldown := 9.0
@export var turret_life := 6.0
@export var turret_fire_every := 0.9
@export var turret_range := 620.0
@export var turret_bolt_damage := 4             # ~6 bolts if you stand in front of it = ~24
@export var turret_bolt_speed := 720.0
@export var turret_hp := 12                     # It can be smashed (any hit in reach breaks it)

@export_group("Cable Hook (2)")
@export var hook_cooldown := 7.0
@export var hook_startup := 0.18
@export var hook_range := 400.0
@export var hook_speed := 1500.0
@export var hook_damage := 6
@export var hook_pull := 760.0                  # Pulled TOWARD the Technician

@export_group("Spark Coil (3)")
@export var coil_cooldown := 10.0
@export var coil_startup := 0.3
@export var coil_radius := 150.0
@export var coil_damage := 9
@export var coil_stun := 0.6
@export var coil_knockback := Vector2(320, -220)

@export_group("G1: Repair Protocol")
@export var repair_ticks := 3
@export var repair_heal := 6                    # Per tick (1 s apart): 18 total

@export_group("G2: Colony Drones")
@export var drone_count := 3
@export var drone_damage := 6
@export var drone_speed := 430.0
@export var drone_life := 4.0

@export_group("G3: The Technician's Breaker")
@export var breaker_fuse := 1.5                 # Three beeps
@export var breaker_radius := 250.0
@export var breaker_damage := 30
@export var breaker_knockback := Vector2(820, -520)
@export var breaker_throw := 260.0              # Lands this far in front of him


func _init() -> void:
	character_name = "The Technician"
	body_size = Vector2(64, 128)
	max_hp = 100
	move_speed = 320.0
	acceleration = 2300.0
	jump_force = 720.0
	punch_damage = 5
	punch_startup = 0.13
	punch_recovery = 0.2
	punch_size = Vector2(62, 34)
	punch_offset = Vector2(46, -78)
	punch_knockback = Vector2(260, -120)
	grab_escape_presses = 8
	# Can NOT Onslaught: no punch chain, no move upgrades (one of the three rules)
	onslaught_melee_enabled = false
	onslaught_projectile_enabled = false
	onslaught_trap_enabled = false
	onslaught_move_types = {"turret": "", "hook": "", "coil": ""}
	gauge_enabled = true
	ai_move_ranges = {"turret": Vector2(180, 700), "hook": Vector2(140, 400), "coil": Vector2(0, 150)}
