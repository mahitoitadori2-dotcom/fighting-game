class_name MimicAI
extends BaseAI
## CPU brain for THE MIMIC: a heavy close-range bruiser.
##   - Walks in (he wants to be close), punches up close
##   - Shredding Fist to open (it grinds on hit), Stab Kick to launch when they are close
##   - Wings of Lies when the enemy rushes or crowds him
##   - G Gauge: 3 bars = Stolen Skin (bite) when close, 2 = Eating Fear (grab) close,
##     1 = Recital of Steel when close
## (While wearing a stolen skin, the COPY is driven by its own character's AI.)


func think() -> void:
	if try_block(150.0):
		return
	var b := bars()
	# --- Ultimates ---
	if b >= 3 and dist < 120.0 and chance(0.5):
		press("ultimate")                         # Stolen Skin
		return
	if b == 2 and dist < 110.0 and chance(0.35):
		press("ultimate")                         # Eating Fear
		return
	if b == 1 and dist < 130.0 and chance(0.25):
		press("ultimate")                         # Recital of Steel
		return
	# --- Wings of Lies: crowded / rushed ---
	if cd_ready("wings") and dist < 150.0 and (enemy_rushing() or enemy_attacking()) and chance(0.4):
		press("move3")
		return
	# --- Stab Kick: launch them ---
	if cd_ready("kick") and dist < 120.0 and chance(0.3):
		press("move2")
		return
	# --- Shredding Fist: lunging stab ---
	if cd_ready("shred") and dist > 60.0 and dist < 170.0 and chance(0.35):
		press("move1")
		return
	# --- Punch up close ---
	if dist < 96.0:
		if chance(0.55):
			press("attack")
		return
	# --- Close the distance (slow but relentless) ---
	approach()
	if chance(0.02):
		press_now("jump")
