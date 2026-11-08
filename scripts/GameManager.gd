
extends Node

## GAME MANAGER
## Add this script as an Autoload named "GameManager".

signal gauge_changed(value: float, maximum: float)
signal fight_timer_changed(seconds: float)
signal onslaught_changed(fighter: Node, attack_type: String, active: bool, time_left: float)
signal fighter_registered(fighter: Node)
signal fighter_died(fighter: Node)
signal ultimate_activated(fighter: Node, level: int)

const MAX_GAUGE: float = 3.0
const ONSLAUGHT_WINDOW: float = 0.4
const AFTERBURN_DURATION: float = 10.0

# One gauge segment requires 100 damage dealt.
const GAUGE_PER_DAMAGE: float = 0.01
const GAUGE_PER_PERFECT_BLOCK: float = 0.25

var gauge: float = 0.0
var fight_time: float = 0.0
var death_count: int = 0
var survival_time: float = 0.0

var fighters: Array[Node] = []
var fighter_states: Dictionary = {}

var _timer_update: float = 0.0


func _ready() -> void:
	process_mode = Node.PROCESS_MODE_ALWAYS


func _process(delta: float) -> void:
	fight_time += delta
	survival_time += delta

	_timer_update += delta

	if _timer_update >= 0.1:
		_timer_update = 0.0
		fight_timer_changed.emit(fight_time)

	_update_fighter_states(delta)
	_update_survival_gauge(delta)


# ============================================================
# FIGHTER REGISTRATION
# ============================================================

func register_fighter(fighter: Node) -> void:
	if not is_instance_valid(fighter):
		return

	if fighters.has(fighter):
		return

	fighters.append(fighter)

	fighter_states[fighter.get_instance_id()] = {
		"fighter": fighter,
		"melee_chain": 0,
		"onslaught_type": "",
		"onslaught_timer": 0.0,
		"afterburn_timer": 0.0,
		"cooldowns": {}
	}

	fighter_registered.emit(fighter)


func unregister_fighter(fighter: Node) -> void:
	if not is_instance_valid(fighter):
		return

	fighters.erase(fighter)
	fighter_states.erase(fighter.get_instance_id())


func _get_state(fighter: Node) -> Dictionary:
	if not is_instance_valid(fighter):
		return {}

	var id := fighter.get_instance_id()

	if not fighter_states.has(id):
		register_fighter(fighter)

	return fighter_states.get(id, {})


# ============================================================
# G GAUGE
# ============================================================

func add_gauge(amount: float) -> void:
	gauge = clampf(gauge + amount, 0.0, MAX_GAUGE)
	gauge_changed.emit(gauge, MAX_GAUGE)


func report_damage_dealt(amount: int) -> void:
	if amount <= 0:
		return

	add_gauge(float(amount) * GAUGE_PER_DAMAGE)


func report_perfect_block() -> void:
	add_gauge(GAUGE_PER_PERFECT_BLOCK)


func can_use_ultimate() -> bool:
	return gauge >= 1.0


# Returns the strongest available ultimate:
# 1 segment = Triple Rocket
# 2 segments = Void Goo
# 3 segments = Full Arsenal of the Hexagon

func spend_gauge_for_ultimate(fighter: Node) -> int:
	var level: int = 0

	if gauge >= 3.0:
		gauge -= 3.0
		level = 3
	elif gauge >= 2.0:
		gauge -= 2.0
		level = 2
	elif gauge >= 1.0:
		gauge -= 1.0
		level = 1
	else:
		return 0

	gauge_changed.emit(gauge, MAX_GAUGE)
	ultimate_activated.emit(fighter, level)

	return level


func get_gauge() -> float:
	return gauge


func _update_survival_gauge(delta: float) -> void:
	if survival_time < 300.0:
		return

	# Slowly accelerates as the fighter survives longer.
	var elapsed := survival_time - 300.0
	var rate := 0.0005 + elapsed * 0.00001

	add_gauge(rate * delta)


# ============================================================
# GLOBAL ONSLAUGHT SYSTEM
# ============================================================

# attack_type must be:
# "melee", "projectile", or "trap".
#
# Returns TRUE if this attack successfully activates Onslaught.
# Returns FALSE if it only starts the flashing window.

func request_onslaught(
	fighter: Node,
	attack_type: String
) -> bool:

	var state := _get_state(fighter)

	if state.is_empty():
		return false

	if not _onslaught_enabled(fighter, attack_type):
		return false

	# A second matching input during the flash activates Onslaught.
	if state["onslaught_timer"] > 0.0:
		if state["onslaught_type"] == attack_type:
			state["onslaught_timer"] = 0.0
			state["onslaught_type"] = ""

			if attack_type == "melee":
				state["afterburn_timer"] = AFTERBURN_DURATION

			onslaught_changed.emit(
				fighter, attack_type, false, 0.0
			)

			return true

	# A different attack cancels the previous flash.
	state["onslaught_timer"] = 0.0
	state["onslaught_type"] = ""

	if attack_type == "melee":
		state["melee_chain"] += 1

		# Fourth consecutive melee opens the flash window.
		if state["melee_chain"] >= 4:
			state["melee_chain"] = 0
			_start_onslaught_window(fighter, state, attack_type)

	elif attack_type == "projectile":
		state["melee_chain"] = 0
		_start_onslaught_window(fighter, state, attack_type)

	elif attack_type == "trap":
		state["melee_chain"] = 0
		_start_onslaught_window(fighter, state, attack_type)

	else:
		return false

	return false


func _start_onslaught_window(
	fighter: Node,
	state: Dictionary,
	attack_type: String
) -> void:

	state["onslaught_type"] = attack_type
	state["onslaught_timer"] = ONSLAUGHT_WINDOW

	onslaught_changed.emit(
		fighter,
		attack_type,
		true,
		ONSLAUGHT_WINDOW
	)


func _onslaught_enabled(
	fighter: Node,
	attack_type: String
) -> bool:

	if not _has_property(fighter, "data"):
		return false

	var data = fighter.get("data")

	if data == null:
		return false

	var flag_name := ""

	match attack_type:
		"melee":
			flag_name = "onslaught_melee_enabled"

		"projectile":
			flag_name = "onslaught_projectile_enabled"

		"trap":
			flag_name = "onslaught_trap_enabled"

		_:
			return false

	if not _has_property(data, flag_name):
		return false

	return bool(data.get(flag_name))


func _has_property(object: Object, property_name: String) -> bool:
	if not is_instance_valid(object):
		return false

	for property in object.get_property_list():
		if property["name"] == property_name:
			return true

	return false


func _update_fighter_states(delta: float) -> void:
	for id in fighter_states.keys():
		var state: Dictionary = fighter_states[id]
		var fighter: Node = state["fighter"]

		if not is_instance_valid(fighter):
			fighter_states.erase(id)
			continue

		if state["onslaught_timer"] > 0.0:
			state["onslaught_timer"] = maxf(
				0.0,
				state["onslaught_timer"] - delta
			)

			if state["onslaught_timer"] == 0.0:
				state["onslaught_type"] = ""

				onslaught_changed.emit(
					fighter, "", false, 0.0
				)

		if state["afterburn_timer"] > 0.0:
			state["afterburn_timer"] = maxf(
				0.0,
				state["afterburn_timer"] - delta
			)

		for cooldown_id in state["cooldowns"].keys():
			state["cooldowns"][cooldown_id] = maxf(
				0.0,
				state["cooldowns"][cooldown_id] - delta
			)


# ============================================================
# ONSLAUGHT DAMAGE AND COOLDOWNS
# ============================================================

func get_attack_damage(
	fighter: Node,
	attack_type: String,
	base_damage: int,
	is_onslaught: bool = false
) -> int:

	var state := _get_state(fighter)

	if is_onslaught:
		if attack_type == "melee":
			return base_damage * 2

		return int(round(base_damage * 1.5))

	# Afterburn only weakens melee attacks.
	if attack_type == "melee":
		if state.get("afterburn_timer", 0.0) > 0.0:
			return 2

	return base_damage


func get_onslaught_cooldown_multiplier(
	is_onslaught: bool
) -> float:

	return 1.5 if is_onslaught else 1.0


func is_afterburn_active(fighter: Node) -> bool:
	var state := _get_state(fighter)

	return state.get("afterburn_timer", 0.0) > 0.0


func get_afterburn_remaining(fighter: Node) -> float:
	var state := _get_state(fighter)

	return state.get("afterburn_timer", 0.0)


func get_onslaught_flash_remaining(fighter: Node) -> float:
	var state := _get_state(fighter)

	return state.get("onslaught_timer", 0.0)
	
func clear_afterburn(fighter: Node) -> void:
	var state := _get_state(fighter)

	if not state.is_empty():
		state["afterburn_timer"] = 0.0

# ============================================================
# COOLDOWN TRACKING
# ============================================================

func start_cooldown(
	fighter: Node,
	cooldown_id: String,
	duration: float
) -> void:

	var state := _get_state(fighter)

	if state.is_empty():
		return

	state["cooldowns"][cooldown_id] = duration


func get_cooldown_remaining(
	fighter: Node,
	cooldown_id: String
) -> float:

	var state := _get_state(fighter)

	if state.is_empty():
		return 0.0

	return state["cooldowns"].get(cooldown_id, 0.0)


func reset_cooldowns(fighter: Node) -> void:
	var state := _get_state(fighter)

	if state.is_empty():
		return

	state["cooldowns"].clear()


# ============================================================
# DEATH / RESPAWN
# ============================================================

func notify_fighter_death(fighter: Node) -> void:
	if not is_instance_valid(fighter):
		return

	death_count += 1
	survival_time = 0.0

	fighter_died.emit(fighter)


func reset_match() -> void:
	gauge = 0.0
	fight_time = 0.0
	survival_time = 0.0
	death_count = 0

	for id in fighter_states.keys():
		var state: Dictionary = fighter_states[id]

		state["melee_chain"] = 0
		state["onslaught_timer"] = 0.0
		state["onslaught_type"] = ""
		state["afterburn_timer"] = 0.0
		state["cooldowns"].clear()

	gauge_changed.emit(gauge, MAX_GAUGE)
	fight_timer_changed.emit(fight_time)
