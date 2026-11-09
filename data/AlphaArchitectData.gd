class_name AlphaArchitectData
extends CharacterData
## APHA ARCHITECT - the dark, powerful version of the Architect. Every number of his kit lives
## here. 2500 HP, NO G Gauge, every punch is an ONSLAUGHT punch, and his powers hit REALLY hard.


func _init() -> void:
	character_name = "APHA Architect"
	max_hp = 2500
	body_size = Vector2(60, 128)
	move_speed = 420.0                 # Faster than the Architect
	acceleration = 3400.0
	deceleration = 4000.0
	air_acceleration = 2400.0
	jump_force = 800.0
	gauge_enabled = false               # NO G Gauge: no ultimates (his 7 powers are on keys 1-7)
	onslaught_melee_enabled = false     # No Onslaught FLASH: every punch already IS an Onslaught punch
	punch_damage = 18
	punch_startup = 0.06
	punch_active = 0.08
	punch_recovery = 0.12
	punch_size = Vector2(76, 90)
	punch_offset = Vector2(46, -76)
	punch_knockback = Vector2(560, -300)
	punch_lunge_speed = 320.0
	hitstun_time = 0.18


@export_group("Flight (E)")
@export var flight_speed := 520.0
@export var flight_vertical_speed := 460.0
@export var flight_max_height := 460.0          # Above the floor
@export var air_charge_damage := 24
@export var air_charge_speed := 1100.0
@export var air_charge_time := 0.24
@export var air_charge_knockback := Vector2(620, -260)

@export_group("1 - Thunderclap")
@export var clap_cooldown := 4.0
@export var clap_damage := 30
@export var clap_stun := 1.0
@export var tornado_damage := 45                # Air variant: compressed wind tornado
@export var tornado_stun := 0.6

@export_group("2 - Godly Touch (ground only)")
@export var touch_cooldown := 9.0
@export var touch_damage := 25
@export var debuff_duration := 6.0
@export var debuff_count := 3
@export var burn_tick := 6                      # every 0.5 s
@export var poison_tick := 4
@export var drain_tick := 5                     # heals the APHA Architect

@export_group("3 - Barrage of Vadis")
@export var barrage_cooldown := 9.0
@export var barrage_hits := 12
@export var barrage_hit_damage := 7
@export var barrage_range := 340.0
@export var laser_count := 9                    # Air variant: the clones shoot lasers
@export var laser_damage := 10

@export_group("4 - Portal Manifestation")
@export var portal_cooldown := 12.0
@export var portal_duration := 2.6
@export var portal_shot_every := 0.14
@export var portal_shot_damage := 9

@export_group("5 - Pure Implosion of Decay")
@export var decay_cooldown := 22.0
@export var decay_damage := 70
@export var decay_radius := 260.0
@export var decay_tick := 6                     # Decay field, every 0.3 s for 3 s
@export var decay_field_time := 3.0

@export_group("6 - World Implosion Bomb")
@export var bomb_cooldown := 35.0
@export var bomb_damage := 130                  # Per rod (2 rods)
@export var bomb_radius := 330.0

@export_group("7 - World Opening")
@export var opening_cooldown := 40.0
@export var opening_radius := 620.0
@export var opening_hand_hits := 8
@export var opening_hand_damage := 16
@export var opening_final_damage := 80
