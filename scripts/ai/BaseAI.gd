class_name BaseAI
extends FighterInput
## MODULAR CPU BRAIN. Every playable character gets a subclass of this
## (ArchitectAI, WarriorAI, ...) and only overrides think().
## It presses the SAME logical buttons a human does (left/right/jump/attack/
## block/move1-3/ultimate), so it works for P1 or P2: Player vs AI and AI vs AI.
##
## Shared behaviour handled here:
##   - Reaction delay: decisions happen every 0.2-0.3 s (medium difficulty)
##   - Random mistakes: some presses are dropped, some moves wander
##   - Turning to face the enemy before a directional move fires
##   - Onslaught: when its own bar flashes, repeats the input 50% of the time
##   - Mashing out of grabs, staying away from the island edges
##
## HOW TO MAKE AI FOR A NEW CHARACTER:
##   1. class_name NewGuyAI extends BaseAI
##   2. override think(): read dist / bars() / cd_ready("move_id") / enemy_attacking()...
##      and call approach() / retreat() / press("attack") / block_for(0.4)...
##   3. put  "ai": NewGuyAI  in the character's CharacterRoster entry.

# ----- Difficulty (MEDIUM, deliberately beatable) -----
var reaction_min := 0.2          # Seconds between decisions = reaction delay
var reaction_max := 0.3
var mistake_chance := 0.18       # Chance a decided press is simply dropped
var wander_chance := 0.08        # Chance to walk the wrong way for one decision
var block_chance := 0.25         # Chance to block when the enemy swings nearby
var onslaught_chance := 0.5      # Chance to use Onslaught when the bar flashes

# ----- Perception (refreshed before every think()) -----
var f: ControlledFighter
var enemy: Fighter
var dist := 9999.0               # Horizontal distance to the enemy
var dir := 1.0                   # +1 enemy is to the right, -1 to the left
var facing_enemy := false
var rng := RandomNumberGenerator.new()

# ----- Output state -----
var _cur := {}
var _prev := {}
var _taps: Array[String] = []
var _queued := ""                # A press waiting until we face the enemy
var _queued_timer := 0.0
var _move_dir := 0.0
var _block_timer := 0.0
var _think_timer := 0.0
var _ground: ArenaGround

# ----- Onslaught -----
var _seen_flash := false
var _onslaught_press := ""
var _onslaught_timer := 0.0


func _init() -> void:
	rng.randomize()


func is_human() -> bool:
	return false


func pressed(button: String) -> bool:
	return _cur.get(button, false)


func just_pressed(button: String) -> bool:
	return _cur.get(button, false) and not _prev.get(button, false)


func just_released(button: String) -> bool:
	return _prev.get(button, false) and not _cur.get(button, false)


func axis() -> float:
	return (1.0 if pressed("right") else 0.0) - (1.0 if pressed("left") else 0.0)


# ============================================================
# MAIN LOOP (called every physics frame by the fighter)
# ============================================================
func update(fighter: Fighter, delta: float) -> void:
	_prev = _cur.duplicate()
	_cur.clear()
	f = fighter as ControlledFighter
	if f == null or f.is_dead:
		return

	# Grabbed: mash random buttons to escape
	if f.grabbed_by != null:
		if rng.randf() < 0.35:
			_cur[["left", "right", "jump", "attack"].pick_random()] = true
		return

	_perceive()
	_block_timer = maxf(_block_timer - delta, 0.0)
	_queued_timer = maxf(_queued_timer - delta, 0.0)
	if _queued_timer <= 0.0:
		_queued = ""

	_update_onslaught(delta)

	_think_timer -= delta
	if _think_timer <= 0.0:
		_think_timer = rng.randf_range(reaction_min, reaction_max)
		_move_dir = 0.0
		if enemy != null:
			think()
			if rng.randf() < wander_chance:
				_move_dir = -dir if _move_dir == 0.0 else -_move_dir     # Mistake: wrong way

	# Every-frame reactions (dodging, etc.). Can override the decision above.
	if enemy != null:
		react(delta)

	# A queued directional press fires once we face the enemy
	if _queued != "":
		if facing_enemy:
			_taps.append(_queued)
			_queued = ""
		elif _move_dir == 0.0:
			_move_dir = dir                                       # Turn around first

	_edge_safety()

	if _move_dir < 0.0:
		_cur["left"] = true
	elif _move_dir > 0.0:
		_cur["right"] = true
	if _block_timer > 0.0:
		_cur["block"] = true
	for t in _taps:
		_cur[t] = true
	_taps.clear()


func _perceive() -> void:
	enemy = CombatManager.find_enemy(f)
	if enemy == null:
		return
	var dx := enemy.global_position.x - f.global_position.x
	dist = absf(dx)
	dir = 1.0 if dx >= 0.0 else -1.0
	facing_enemy = f.facing == int(dir)


## OVERRIDE THIS in each character's AI. Called every 0.2-0.3 s with fresh perception.
func think() -> void:
	# Generic fallback: walk in and swing.
	if dist > 85.0:
		approach()
	elif rng.randf() < 0.5:
		press("attack")


## OPTIONAL override: called EVERY frame (after think) for fast reactions like dodging.
func react(_delta: float) -> void:
	pass


# ============================================================
# HELPERS FOR think()
# ============================================================
func approach() -> void:
	_move_dir = dir


func retreat() -> void:
	_move_dir = -dir


func stop() -> void:
	_move_dir = 0.0


## Press a button facing the enemy (turns first if needed). May be dropped (mistake).
func press(button: String) -> void:
	if rng.randf() < mistake_chance:
		return
	if facing_enemy:
		_taps.append(button)
	else:
		_queued = button
		_queued_timer = 0.5


## Press a button right now, any direction (jump, ...).
func press_now(button: String) -> void:
	_taps.append(button)


func block_for(seconds: float) -> void:
	_block_timer = seconds
	_move_dir = 0.0


## Move is off cooldown.
func cd_ready(move_id: String) -> bool:
	return f.cooldowns.get(move_id, 0.0) <= 0.0


func bars() -> int:
	return f.gauge.segments() if f.gauge != null else 0


func hp_ratio() -> float:
	return float(f.hp) / maxf(float(f.data.max_hp), 1.0)


func chance(p: float) -> bool:
	return rng.randf() < p


## Enemy is mid-swing (so blocking now could work).
func enemy_attacking() -> bool:
	var ce := enemy as ControlledFighter
	return ce != null and ce.is_attacking()


## Enemy is running at us.
func enemy_rushing() -> bool:
	return enemy.velocity.x * -dir > 180.0


## SOULS RULES (open world): no blocking - roll THROUGH an attack that is about to land
## (a story enemy's wind-up almost done, or a fighter mid-swing), if there is stamina for it.
func _try_roll(max_range: float) -> bool:
	var cf := f as ControlledFighter
	if cf == null or enemy == null or cf.exhausted or cf.stamina < SoulsRules.ROLL_COST or cf.roll_timer > 0.0:
		return false
	var be := enemy as BaseEnemy
	var incoming := enemy_attacking()
	if be != null and be.is_telegraphing() and be.state_len - be.state_time < 0.25:
		incoming = true
	if not incoming or dist > max_range + 90.0 or not chance(block_chance):
		return false
	_move_dir = signf(enemy.global_position.x - f.global_position.x)   # Roll through them
	if _move_dir == 0.0:
		_move_dir = float(f.facing)
	press("block")
	return true


## Standard "block if they swing at me" check. Returns true if it decided to block.
func try_block(max_range: float = 170.0) -> bool:
	if SoulsRules.active:
		return _try_roll(max_range)
	if enemy_attacking() and dist < max_range and facing_enemy and chance(block_chance):
		block_for(rng.randf_range(0.3, 0.5))
		return true
	return false


# ============================================================
# ONSLAUGHT: repeat the input while the bar flashes (50%)
# ============================================================
func _update_onslaught(delta: float) -> void:
	var o := f.onslaught
	if o == null:
		return
	if o.flash_timer > 0.0 and not _seen_flash:
		_seen_flash = true
		if chance(onslaught_chance):
			_onslaught_press = _button_for_move(o.flash_move)
			_onslaught_timer = rng.randf_range(0.08, 0.22)    # Must land inside the 0.4 s window
	elif o.flash_timer <= 0.0:
		_seen_flash = false
		_onslaught_press = ""
	if _onslaught_press != "":
		_onslaught_timer -= delta
		if _onslaught_timer <= 0.0:
			_taps.append(_onslaught_press)
			_onslaught_press = ""


func _button_for_move(move_id: String) -> String:
	if move_id == "":
		return "attack"                       # Melee flash
	var i := f.move_ids.find(move_id)
	return "move%d" % (i + 1) if i >= 0 else ""


# ============================================================
# SAFETY: never walk off the island; steer back if knocked off
# ============================================================
func _edge_safety() -> void:
	if _ground == null or not is_instance_valid(_ground):
		_ground = f.get_tree().get_first_node_in_group("arena_ground") as ArenaGround
		if _ground == null:
			return
	var x := f.global_position.x
	if x < _ground.left_edge() + 110.0:
		_move_dir = 1.0
		if not f.is_on_floor() and f.velocity.y > 0.0:
			_taps.append("jump")
	elif x > _ground.right_edge() - 110.0:
		_move_dir = -1.0
		if not f.is_on_floor() and f.velocity.y > 0.0:
			_taps.append("jump")
