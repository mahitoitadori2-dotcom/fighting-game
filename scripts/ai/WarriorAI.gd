class_name WarriorAI
extends BaseAI
## CPU brain for the Warrior: aggressive rushdown.
##   - Walks toward the enemy constantly
##   - Sword when close
##   - Clinging Grab when the enemy is far (inside tentacle range)
##   - Royal Destiny when below 50% HP
##   - Eternal Grasp when the enemy is very close
##   - G: 1 bar Mini Eternal Grasp (close) / 2 bars Shadow Swarm (in front, mid range)
##        / 3 bars The Fall of the Physic (close)
##   - Onslaught Clinging Grab 50% of the time (handled by BaseAI)


func _init() -> void:
	super._init()
	block_chance = 0.15                           # Rushdown: blocks less than the Architect


func think() -> void:
	var wd := f.data as WarriorData
	var grab_range := wd.grab_range if wd != null else 380.0

	if try_block(150.0):
		return

	# --- Royal Destiny: below half HP ---
	if hp_ratio() < 0.5 and cd_ready("royal") and chance(0.6):
		press("move2")
		return

	# --- Ultimates ---
	var b := bars()
	if b == 1 and dist < 160.0 and chance(0.4):
		press("ultimate")                         # Mini Eternal Grasp
		return
	if b == 2 and dist > 200.0 and dist < 700.0 and chance(0.4):
		press("ultimate")                         # Shadow Swarm (press() faces first)
		return
	if b >= 3 and dist < 220.0 and chance(0.4):
		press("ultimate")                         # The Fall of the Physic
		return

	# --- Eternal Grasp: very close ---
	if cd_ready("eternal") and dist < 85.0 and chance(0.35):
		press("move3")
		return

	# --- Clinging Grab: enemy far, but inside tentacle range ---
	if cd_ready("grab") and dist > 220.0 and dist < grab_range - 20.0 and chance(0.4):
		press("move1")
		return

	# --- Sword when close, otherwise keep walking in ---
	if dist < 88.0:
		if chance(0.5):
			press("attack")
	else:
		approach()
	if enemy.global_position.y < f.global_position.y - 80.0 and chance(0.35):
		press_now("jump")
