class_name FireLordData
extends CharacterData
## The Nightmare Lord: elegant red villain. Every number of his kit lives here.
## Body size / HP / movement / block are inherited from CharacterData (same as everyone).
## PASSIVE: every full G Gauge bar adds +1 damage to ALL his attacks (max +3).

@export_group("Punch (basic attack)")
## Uses CharacterData punch_* values: 3 damage, same range as the Architect. NOT Onslaught-able.

@export_group("BloodFlame Spit (1)")
@export var flame_cooldown := 7.0
@export var flame_count := 5
@export var flame_damage := 5
@export var flame_spread_deg := 7.0             # Angle between neighbouring flames
@export var flame_speed := 620.0
@export var flame_lifetime := 0.85
@export var flame_knockback := Vector2(150, -90)
@export var flame_spawn_offset := Vector2(30, -82)

@export_group("Bat Escape (2)")
@export var bat_cooldown := 14.0
@export var bat_count := 3
@export var bat_damage := 9
@export var bat_speed := 430.0
@export var bat_lifetime := 1.7
@export var bat_knockback := Vector2(240, -160)
@export var bat_guard_time := 1.7               # Hit during this window -> bat form
@export var bat_form_duration := 5.0
@export var bat_form_speed_mult := 1.6
@export var bat_form_jump_mult := 1.25
@export var bat_form_hurtbox := Vector2(44, 40)  # Smaller = harder to hit

@export_group("Launch O' Spikes (3)")
@export var spikes_cooldown := 24.0
@export var spikes_jump_force := 780.0
@export var spikes_rise_time := 0.32
@export var spikes_burst_count := 6
@export var spikes_burst_damage := 4
@export var spikes_burst_speed := 460.0
@export var spikes_burst_lifetime := 0.45
@export var spikes_floor_count := 4
@export var spikes_floor_damage := 7
@export var spikes_floor_first := 70.0          # Distance of the first spike in front of him
@export var spikes_floor_spacing := 62.0
@export var spikes_floor_interval := 0.06       # Ripple delay between spikes
@export var spikes_floor_knockback := Vector2(180, -380)

@export_group("G1: Double Trouble")
@export var double_flame_count := 8
@export var double_flame_spread_deg := 6.0
@export var double_bat_count := 5

@export_group("G2: Volatile Nightmare")
@export var volatile_spike_count := 14
@export var volatile_spike_damage := 7          # Same as Launch O' Spikes spikes
@export var volatile_spike_range := 140.0
@export var volatile_knockback := Vector2(220, -200)
@export var oil_width := 280.0
@export var oil_offset := 260.0                 # Puddle centre in front of him
@export var oil_duration := 9.0
@export var oil_burn_damage := 5                # Per second while standing in BURNING oil
@export var oil_burn_time := 5.0                # How long oil burns once ignited

@export_group("G3: The Ritual of the Troupe")
@export var ritual_grow_time := 1.3
@export var ritual_radius := 290.0
@export var ritual_damage := 22
@export var ritual_knockback := Vector2(700, -480)
@export var ritual_flames := 14
@export var ritual_bats := 6
@export var ritual_oil_count := 4
@export var ritual_oil_spread := 430.0


func _init() -> void:
	character_name = "Nightmare Lord"
	# Punch can NOT be Onslaughted. No move is Onslaught-able (for now).
	onslaught_melee_enabled = false
	onslaught_projectile_enabled = false
	onslaught_trap_enabled = false
	onslaught_move_types = {"flame": "", "bat": "", "spikes": ""}
	gauge_enabled = true
	ai_move_ranges = {"flame": Vector2(150, 600), "bat": Vector2(0, 320), "spikes": Vector2(0, 160)}
