class_name MimicData
extends CharacterData
## THE MIMIC (Versus only): a big fighter of pure steel with red pupils. Heavier and slower than
## everyone, hits hard. His punch can NOT be Onslaughted and none of his moves can either.
## Every number of his kit lives here.

@export_group("Steel body")
@export var knockback_resist := 0.8             # Takes 80% knockback (heavy)

@export_group("Shredding Fist (1)")
@export var shred_cooldown := 6.0
@export var shred_startup := 0.16
@export var shred_active := 0.12
@export var shred_lunge_speed := 520.0
@export var shred_damage := 5                   # The stab
@export var shred_size := Vector2(90, 34)
@export var shred_offset := Vector2(62, -104)
@export var shred_grind_ticks := 4              # On hit: a small GRIND
@export var shred_grind_damage := 2
@export var shred_grind_interval := 0.14
@export var shred_release_knockback := Vector2(320, -160)

@export_group("Stab Kick (2)")
@export var kick_cooldown := 8.0
@export var kick_startup := 0.24
@export var kick_active := 0.12
@export var kick_recovery := 0.3
@export var kick_damage := 9
@export var kick_size := Vector2(96, 36)
@export var kick_offset := Vector2(66, -58)
@export var kick_knockback := Vector2(780, -360)  # HIGH knockback

@export_group("Wings of Lies (3)")
@export var wings_cooldown := 14.0
@export var wings_open_time := 0.25
@export var wings_spin_time := 1.0
@export var wings_radius := 150.0
@export var wings_tick := 0.16
@export var wings_damage := 2                   # Per tick (~6 ticks + the final hit = ~18)
@export var wings_knockback := Vector2(160, -120)
@export var wings_final_damage := 6
@export var wings_final_knockback := Vector2(560, -380)

@export_group("G1: Recital of Steel (Shredding Fist, Fist, Shredding Kick)")
@export var recital_step_time := 0.28
@export var recital_damage := [7, 5, 11]
@export var recital_knockback := [Vector2(40, -20), Vector2(60, -30), Vector2(700, -420)]   # Keeps them close for the kick
@export var recital_lunge := 360.0

@export_group("G2: Eating Fear")
@export var fear_startup := 0.2
@export var fear_lunge_time := 0.22
@export var fear_lunge_speed := 640.0
@export var fear_grab_damage := 4
@export var fear_chew_ticks := 6
@export var fear_chew_damage := 3
@export var fear_chew_interval := 0.28
@export var fear_spit_knockback := Vector2(600, -420)

@export_group("G3: Stolen Skin")
@export var bite_startup := 0.22
@export var bite_active := 0.14
@export var bite_damage := 8
@export var bite_damage_no_copy := 16           # A boss / enemy can't be copied: a harder bite instead
@export var bite_size := Vector2(70, 50)
@export var bite_offset := Vector2(52, -130)
@export var skin_duration := 30.0              # Turned into the bitten opponent


func _init() -> void:
	character_name = "The Mimic"
	body_size = Vector2(84, 160)                 # BIGGER than everyone (64 x 128)
	max_hp = 130
	move_speed = 285.0
	acceleration = 2100.0
	jump_force = 700.0
	punch_damage = 4
	punch_startup = 0.17
	punch_recovery = 0.24
	punch_size = Vector2(66, 36)
	punch_offset = Vector2(50, -106)
	punch_knockback = Vector2(300, -130)
	grab_escape_presses = 10
	# Can NOT Onslaught: no punch chain, no move upgrades
	onslaught_melee_enabled = false
	onslaught_projectile_enabled = false
	onslaught_trap_enabled = false
	onslaught_move_types = {"shred": "", "kick": "", "wings": ""}
	gauge_enabled = true
	ai_move_ranges = {"shred": Vector2(0, 150), "kick": Vector2(0, 130), "wings": Vector2(0, 160)}
