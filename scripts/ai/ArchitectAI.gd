class_name ArchitectAI
extends BaseAI
## CPU brain for The Mighty Architect: a zoner.
##   - Keeps MEDIUM distance, walks in if too far, backs off if crowded
##   - Punch when close
##   - Rocket Delivery at mid/far range
##   - HNCT in front when the enemy rushes in
##   - Armaggedon Drill when close (sometimes whiffs on purpose for balance)
##   - Blocks sometimes
##   - G: 1 bar Triple Rocket (far) / 2 bars Void Goo (close) / 3 bars Full Arsenal (close)
##   - Onslaught 50% of the time (handled by BaseAI)

const PREFERRED_MIN := 200.0
const PREFERRED_MAX := 380.0


func think() -> void:
	if try_block(170.0):
		return

	# --- Ultimates (G uses the highest tier you have, so check the bar count) ---
	var b := bars()
	if b == 1 and dist > 400.0 and chance(0.4):
		press("ultimate")                         # Triple Rocket from far away
		return
	if b == 2 and dist < 200.0 and chance(0.4):
		press("ultimate")                         # Void Goo under a close enemy
		return
	if b >= 3 and dist < 260.0 and chance(0.4):
		press("ultimate")                         # Full Arsenal of the Hexagon
		return

	# --- HNCT: enemy rushing in -> drop a bomb in front ---
	if cd_ready("hnct") and enemy_rushing() and dist > 90.0 and dist < 340.0 and chance(0.45):
		press("move2")
		return

	# --- Drill: close range. Sometimes fired from too far = a deliberate miss. ---
	if cd_ready("drill"):
		if dist < 130.0 and chance(0.3):
			press("move3")
			return
		if dist > 190.0 and dist < 260.0 and chance(0.06):
			press("move3")                        # On purpose: lunge falls short
			return

	# --- Rocket Delivery: mid / far ---
	if cd_ready("rocket") and dist > 260.0 and chance(0.45):
		press("move1")
		return

	# --- Punch when close ---
	if dist < 90.0:
		if chance(0.45):
			press("attack")
		elif chance(0.3):
			retreat()                             # Make space again
		return

	# --- Spacing: stay at medium distance ---
	if dist > PREFERRED_MAX:
		approach()
	elif dist < PREFERRED_MIN and chance(0.5):
		retreat()
	elif chance(0.3):
		approach()                                # Drift in a little
	if chance(0.03):
		press_now("jump")
