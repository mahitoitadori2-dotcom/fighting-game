class_name TechnicianAI
extends BaseAI
## CPU brain for THE TECHNICIAN: a zoner. Keeps its distance, drops the turret, hooks foes into
## the turret's line of fire, and sparks the coil when they get close.
##   G Gauge: 3 bars = the Breaker (when the foe is at mid range), 2 = drones, 1 = repair when hurt


func think() -> void:
	if try_block(150.0):
		return
	var b := bars()
	var hurt := hp_ratio() < 0.55
	# --- Ultimates ---
	if b >= 3 and dist > 120.0 and dist < 380.0 and chance(0.5):
		press("ultimate")                         # The Breaker lands near them
		return
	if b == 2 and chance(0.35):
		press("ultimate")                         # Colony Drones
		return
	if b == 1 and hurt and chance(0.4):
		press("ultimate")                         # Repair Protocol
		return
	# --- Spark Coil: they are on top of him ---
	if cd_ready("coil") and dist < 140.0 and chance(0.55):
		press("move3")
		return
	# --- Scrap Turret: at range ---
	if cd_ready("turret") and dist > 200.0 and chance(0.4):
		press("move1")
		return
	# --- Cable Hook: pull them in (into the turret / the coil) ---
	if cd_ready("hook") and dist > 150.0 and dist < 390.0 and chance(0.3):
		press("move2")
		return
	# --- Wrench up close, otherwise keep a little distance ---
	if dist < 90.0:
		if chance(0.5):
			press("attack")
		elif chance(0.4):
			retreat()
		return
	if dist > 420.0:
		approach()
	elif dist < 220.0 and chance(0.4):
		retreat()
	if chance(0.02):
		press_now("jump")
