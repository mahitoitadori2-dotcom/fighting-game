class_name EnemyPattern
extends Resource
## One attack an enemy can perform. Every enemy is just a list of these + code
## that says what happens on telegraph / attack start / attack update / attack end.
##
## Flow driven by BaseEnemy:  TELEGRAPH (telegraph_time) -> ATTACK (active_time) -> RECOVER (recover_time)

@export var id := ""                         # Code id ("spin_dash")
@export var display_name := ""               # Shown above the enemy while telegraphing ("SPIN DASH!")
@export var cooldown := 0.0                  # Seconds before it can be used again
@export var damage := 0
@export var min_range := 0.0                 # Distance to the target where the AI may use it
@export var max_range := 100.0
@export var animation := ""                  # Pose id the enemy's art plays
@export var telegraph_time := 0.2            # Wind-up the player can react to
@export var active_time := 0.2
@export var recover_time := 0.3
@export var big := false                     # Big attack: name + "!" + flashing during telegraph
@export var armored := false                 # Hits do NOT interrupt it
@export var phase_weights: Array[float] = [1.0, 1.0]   # How often the AI picks it, per phase
@export var note := ""                       # Extra text for the Character Select card ("Heals 15 HP")

var cooldown_left := 0.0                     # Runtime (each enemy instance builds its own patterns)


static func make(p_id: String, p_name: String, p_cooldown: float, p_damage: int,
		p_min: float, p_max: float, p_anim: String, p_tele: float, p_active: float,
		p_recover: float, p_big: bool, p_weights: Array, p_armored: bool = false) -> EnemyPattern:
	var p := EnemyPattern.new()
	p.id = p_id
	p.display_name = p_name
	p.cooldown = p_cooldown
	p.damage = p_damage
	p.min_range = p_min
	p.max_range = p_max
	p.animation = p_anim
	p.telegraph_time = p_tele
	p.active_time = p_active
	p.recover_time = p_recover
	p.big = p_big
	p.phase_weights.assign(p_weights)
	p.armored = p_armored
	return p


func is_ready() -> bool:
	return cooldown_left <= 0.0


func in_range(dist: float) -> bool:
	return dist >= min_range and dist <= max_range


func weight(phase: int) -> float:
	if phase_weights.is_empty():
		return 1.0
	return phase_weights[clampi(phase - 1, 0, phase_weights.size() - 1)]
