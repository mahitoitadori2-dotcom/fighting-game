class_name CombatManager
extends Node
## Resolves every hit (block, perfect block, defense, damage, gauge), owns the
## fight timer (G Gauge auto-fill) and registers the input actions.

const WORLD_LAYER := 1
const BODY_LAYER := 2
const HURTBOX_LAYER := 4
const FIRE_LAYER := 8            # Nightmare Lord's flames / bats / spikes / burning oil (ignites oil)

static var debug_boxes := false       # Hitbox / hurtbox outlines. Toggle in-game with F1.

@export var fight_time_start := 0.0     # Set to ~295 in the Inspector to test auto-fill quickly

var fight_time := 0.0
var fighters: Array[Fighter] = []

# ===== TIME STOP (Warrior: The Fall of the Physic) =====
## While set, EVERY fighter except this one is frozen, and so are their projectiles.
static var time_stop_owner: Fighter = null
static var time_stop_left := 0.0
static var time_stop_total := 5.0

## False during the "ROUND 1 / FIGHT!" intro and after the match ends: nobody acts.
static var fight_active := true


static func start_time_stop(by: Fighter, duration: float) -> void:
	time_stop_owner = by
	time_stop_left = duration
	time_stop_total = duration
	Effects.time_stop_overlay(by)


static func end_time_stop() -> void:
	time_stop_owner = null
	time_stop_left = 0.0


static func is_time_stopped() -> bool:
	return time_stop_owner != null and is_instance_valid(time_stop_owner) and time_stop_left > 0.0


## True if `f` (or anything owned by `f`) must be frozen right now.
## The owner's ALLIES are not frozen (Story Colosseum 5: you and your CPU partner).
static func is_frozen(f: Fighter) -> bool:
	return is_time_stopped() and not are_allies(f, time_stop_owner)


func _ready() -> void:
	end_time_stop()               # Static state: never carry a time stop into a new match
	Effects.clear_hitstop()
	fight_time = fight_time_start
	register_inputs()
	# Children are ready before their parent, so every fighter in the scene
	# has already joined the "fighters" group by now.
	for n in get_tree().get_nodes_in_group("fighters"):
		if n is Fighter:
			register(n)

## Esc / controller Start returns to the Main Menu.
## (Not ui_cancel: that includes the controller B button, which is Move 2 in a fight.)
func _unhandled_input(event: InputEvent) -> void:
	if event.is_action_pressed("pause_menu"):
		quit_to_menu(get_tree())


static func quit_to_menu(tree: SceneTree) -> void:
	end_time_stop()
	Effects.clear_hitstop()
	tree.change_scene_to_file(CharacterRoster.MAIN_MENU)


## Fighters spawned later at runtime must call this themselves.
func register(f: Fighter) -> void:
	if f in fighters:
		return
	fighters.append(f)
	f.died.connect(_on_fighter_died)

func _on_fighter_died() -> void:
	fight_time = 0.0           # "no death" condition: timer restarts


# ===== G GAUGE AUTO-FILL =====
func _physics_process(delta: float) -> void:
	if not fight_active:
		return
	fight_time += delta
	if time_stop_owner != null:
		if not is_instance_valid(time_stop_owner) or time_stop_owner.is_dead:
			end_time_stop()
		else:
			time_stop_left -= delta
			if time_stop_left <= 0.0:
				end_time_stop()
	for f in fighters:
		if f.gauge != null and MatchSettings.gauge_instant():
			f.gauge.value = f.gauge.max_value()        # Sandbox INSTANT: always full
		if f.is_dead or f.gauge == null or not f.data.gauge_enabled or is_frozen(f):
			continue
		var over := fight_time - f.data.gauge_auto_start_time
		if over > 0.0:
			var rate := f.data.gauge_auto_base_rate + over * f.data.gauge_auto_growth
			f.gauge.add(rate * delta)


func auto_fill_rate(f: Fighter) -> float:
	var over := fight_time - f.data.gauge_auto_start_time
	if over <= 0.0:
		return 0.0
	return f.data.gauge_auto_base_rate + over * f.data.gauge_auto_growth


# ===== HIT RESOLUTION =====
## Returns "hit", "blocked", "perfect" or "ignored".
static func apply_hit(hit: HitData, victim: Fighter) -> String:
	if victim == null or victim.is_dead:
		return "ignored"
	var attacker: Fighter = hit.source
	if attacker != null and is_instance_valid(attacker) and are_allies(attacker, victim):
		return "ignored"                         # Never hurt your own team (helpers, future team modes)

	# --- BLOCK: only works against attacks from the side the victim FACES ---
	if hit.blockable and victim.can_block_now():
		var from_dir := signf(hit.origin.x - victim.global_position.x)
		if from_dir == 0.0:
			from_dir = float(victim.facing)
		if int(from_dir) == victim.facing:
			var perfect := victim.time_since_block_press() <= victim.data.perfect_block_window
			var push := Vector2.ZERO
			if not perfect:
				push = Vector2(hit.knockback.x * victim.data.block_knockback_multiplier, 0.0)
			victim.apply_knockback(push, false)
			if perfect and victim.gauge != null:
				victim.gauge.add(victim.data.perfect_block_gauge)
			victim.on_blocked(hit, perfect)
			Effects.on_block(victim, perfect)
			return "perfect" if perfect else "blocked"

	# --- DAMAGE (Void Goo = defense down, Royal Destiny = damage reduction) ---
	var dmg := float(hit.damage)
	if attacker != null and is_instance_valid(attacker):
		dmg *= attacker.outgoing_damage_mult           # Weakened attacker (Godly Touch debuff); 1.0 normally
	if victim.goo_timer > 0.0:
		dmg *= 1.0 + victim.goo_def_down
	dmg *= victim.damage_taken_mult
	# Weakness (Enlightened One: explosion / void x1.25). The fractional extra damage is
	# carried over so small hits (1-dmg goo ticks) still add up to exactly +25%.
	var weak := float(victim.data.damage_kind_taken.get(hit.get_kind(), 1.0))
	if weak != 1.0:
		var extra := dmg * (weak - 1.0) + victim.weakness_carry
		var whole := floorf(extra)
		victim.weakness_carry = extra - whole
		dmg += whole
	var base_damage := maxi(roundi(dmg), 1) if hit.damage > 0 else 0   # Before Sandbox (used for G Gauge)
	var sandbox_mult := MatchSettings.damage_multiplier()                # Sandbox: 0x .. 100x, applies to EVERYTHING
	var final_damage := roundi(dmg * sandbox_mult)
	if hit.damage > 0 and sandbox_mult > 0.0:
		final_damage = maxi(final_damage, 1)
	victim.take_hit(final_damage, hit)
	if final_damage > 0:
		Effects.on_hit(hit, victim)                # Hitstop, shake, sparks, impact flash, sound

	# --- GAUGE from dealing damage ---
	if attacker != null:
		if hit.gauge_gain and base_damage > 0 and attacker.gauge != null and attacker.data.gauge_enabled:
			attacker.gauge.add(base_damage * attacker.data.gauge_per_damage)
		attacker.dealt_damage.emit(final_damage, victim)
	return "hit"


## Same team (team 0 = no team: only allied with itself).
## True if an attack or projectile from `source` must pass THROUGH `f` (f is source itself
## or on source's team): it neither hits nor stops there. Used by every hitbox / projectile
## contact check, so your rockets fly through your Story partner to the enemy behind it.
static func passes_through(source: Fighter, f: Fighter) -> bool:
	if f == null:
		return true
	if source == null or not is_instance_valid(source):
		return false
	return are_allies(source, f)


static func are_allies(a: Fighter, b: Fighter) -> bool:
	if a == b:
		return true
	return a.team != 0 and a.team == b.team


static func find_enemy(of: Fighter) -> Fighter:
	if of == null:
		return null
	var best: Fighter = null
	var best_d := INF
	for n in of.get_tree().get_nodes_in_group("fighters"):
		var f := n as Fighter
		if f == null or f.is_dead or are_allies(of, f):
			continue
		var d := of.global_position.distance_to(f.global_position)
		if d < best_d:
			best_d = d
			best = f
	return best


# ===== DEBUG: simulated enemy attack (P / L keys) =====
## A ring closes on the target; the hit lands when it closes.
## Tap F inside the last 0.15 s (white ring) = PERFECT BLOCK.
static func simulate_attack(target: Fighter, from_front: bool, delay: float = 0.6) -> void:
	var side := target.facing if from_front else -target.facing
	var origin := target.global_position + Vector2(side * 90.0, -64.0)
	Effects.telegraph(target, delay, target.data.perfect_block_window)
	Effects.popup(target, target.global_position + Vector2(side * 60.0, -150.0), "INCOMING!", Color(1, 0.9, 0.2), 20)
	await target.get_tree().create_timer(delay).timeout
	if not is_instance_valid(target) or target.is_dead:
		return
	var hit := HitData.new()
	hit.source = null
	hit.damage = 8
	hit.knockback = Vector2(-side * 320.0, -160.0)    # Pushes away from the attacker's side
	hit.origin = origin
	hit.hit_type = "sim"
	apply_hit(hit, target)


# ===== INPUT MAP (so you never touch Project Settings) =====
static func register_inputs() -> void:
	_key("move_left", KEY_A)
	_key("move_right", KEY_D)
	_key("jump", KEY_W)
	_key("crouch", KEY_S)
	_key("block", KEY_F)
	_key("move_rocket", KEY_1)
	_key("move_hnct", KEY_2)
	_key("move_drill", KEY_3)
	_key("ultimate", KEY_G)
	# APHA Architect: powers 4-7 + Flight (other characters simply never read these)
	_key("move_4", KEY_4)
	_key("move_5", KEY_5)
	_key("move_6", KEY_6)
	_key("move_7", KEY_7)
	_key("flight", KEY_E)
	_key("debug_damage", KEY_T)
	_key("debug_sim_front", KEY_P)
	_key("debug_sim_back", KEY_L)
	_key("dummy_mash", KEY_O)
	_key("debug_gauge", KEY_K)
	_key("debug_toggle_boxes", KEY_F1)
	_key("pause_menu", KEY_ESCAPE)
	if not InputMap.has_action("punch"):
		InputMap.add_action("punch")
		var ev := InputEventMouseButton.new()
		ev.button_index = MOUSE_BUTTON_LEFT
		InputMap.action_add_event("punch", ev)
	register_alt_keys()
	register_controller()


## Alternate keyboard layout, added on top of WASD + mouse (nothing removed):
##   Arrow keys  move / jump (Up) / crouch (Down)      Space  attack
static func register_alt_keys() -> void:
	_alt_key("move_left", KEY_LEFT)
	_alt_key("move_right", KEY_RIGHT)
	_alt_key("jump", KEY_UP)
	_alt_key("crouch", KEY_DOWN)
	_alt_key("punch", KEY_SPACE)


## XBOX / any standard controller (P1). Added on top of the keyboard, nothing removed.
##   Left stick / D-pad  move  (down = crouch / fast-fall)
##   A  jump        X  attack (punch / sword / gloves)
##   RB or LT  block (Perfect Block = tap just before the hit)
##   Y  move 1      B  move 2      LB  move 3
##   RT  ultimate (G)      Start  back to Main Menu
static func register_controller() -> void:
	_pad_axis("move_left", JOY_AXIS_LEFT_X, -1.0)
	_pad_axis("move_right", JOY_AXIS_LEFT_X, 1.0)
	_pad_axis("crouch", JOY_AXIS_LEFT_Y, 1.0)
	_pad_btn("move_left", JOY_BUTTON_DPAD_LEFT)
	_pad_btn("move_right", JOY_BUTTON_DPAD_RIGHT)
	_pad_btn("crouch", JOY_BUTTON_DPAD_DOWN)
	_pad_btn("jump", JOY_BUTTON_A)
	_pad_btn("jump", JOY_BUTTON_DPAD_UP)
	_pad_btn("punch", JOY_BUTTON_X)
	_pad_btn("block", JOY_BUTTON_RIGHT_SHOULDER)
	_pad_axis("block", JOY_AXIS_TRIGGER_LEFT, 1.0)
	_pad_btn("move_rocket", JOY_BUTTON_Y)
	_pad_btn("move_hnct", JOY_BUTTON_B)
	_pad_btn("move_drill", JOY_BUTTON_LEFT_SHOULDER)
	_pad_axis("ultimate", JOY_AXIS_TRIGGER_RIGHT, 1.0)
	_pad_btn("pause_menu", JOY_BUTTON_START)
	# Grab escape mashing uses the same actions, so mashing A / X works too.


static func _ensure_action(action: String) -> void:
	if not InputMap.has_action(action):
		InputMap.add_action(action, 0.25)


static func _pad_btn(action: String, button: JoyButton) -> void:
	_ensure_action(action)
	var ev := InputEventJoypadButton.new()
	ev.button_index = button
	ev.device = -1                                   # Any controller
	if not InputMap.action_has_event(action, ev):
		InputMap.action_add_event(action, ev)


static func _pad_axis(action: String, axis: JoyAxis, dir: float) -> void:
	_ensure_action(action)
	var ev := InputEventJoypadMotion.new()
	ev.axis = axis
	ev.axis_value = dir
	ev.device = -1
	if not InputMap.action_has_event(action, ev):
		InputMap.action_add_event(action, ev)


## Extra key for an action that may already exist (project.godot or _key()).
static func _alt_key(action: String, key: Key) -> void:
	_ensure_action(action)
	var ev := InputEventKey.new()
	ev.physical_keycode = key
	if not InputMap.action_has_event(action, ev):
		InputMap.action_add_event(action, ev)


static func _key(action: String, key: Key) -> void:
	if InputMap.has_action(action):
		return
	InputMap.add_action(action)
	var ev := InputEventKey.new()
	ev.physical_keycode = key
	InputMap.action_add_event(action, ev)
