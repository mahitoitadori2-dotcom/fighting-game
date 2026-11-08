class_name FireLordAI
extends BaseAI
## CPU brain for the Nightmare Lord: a zoner that values his passive.
##   - Keeps MID distance and zones with BloodFlame Spit
##   - Bat Escape when the enemy rushes him, or to escape at low HP
##   - Launch O' Spikes when the enemy is close
##   - Punch when close
##   - In BAT FORM (can only move): flees, then comes back when it ends
##   - G Gauge: HOLDS it for the passive damage bonus. Spends early only when in trouble:
##       1 bar Double Trouble (mid range) / 2 bars Volatile Nightmare (close) /
##       3 bars The Ritual of the Troupe (close)

const PREFERRED_MIN := 210.0
const PREFERRED_MAX := 380.0


func think() -> void:
	var fl := f as FireLord
	if fl != null and fl.is_bat():
		# Bat form: only movement. Stay away, flutter.
		if dist < 380.0:
			retreat()
		if chance(0.15):
			press_now("jump")
		return

	if try_block(170.0):
		return

	var low := hp_ratio() < 0.35

	# --- Ultimates: hold the gauge for the passive; spend early only when low ---
	var b := bars()
	if b >= 3 and dist < 240.0 and chance(0.45):
		press("ultimate")                         # The Ritual of the Troupe (max power)
		return
	if b == 2 and dist < 170.0 and chance(0.4 if low else 0.06):
		press("ultimate")                         # Volatile Nightmare
		return
	if b == 1 and dist > 200.0 and dist < 450.0 and chance(0.35 if low else 0.04):
		press("ultimate")                         # Double Trouble
		return

	# --- Bat Escape: enemy rushing in, or escaping at low HP ---
	if cd_ready("bat") and ((enemy_rushing() and dist < 320.0) or (low and dist < 220.0)) and chance(0.45):
		press("move2")
		return

	# --- Launch O' Spikes: enemy close ---
	if cd_ready("spikes") and dist < 160.0 and chance(0.3):
		press("move3")
		return

	# --- Punch up close ---
	if dist < 88.0:
		if chance(0.45):
			press("attack")
		elif chance(0.35):
			retreat()                             # Back to zoning range
		return

	# --- BloodFlame Spit to zone ---
	if cd_ready("flame") and dist > 150.0 and dist < 600.0 and chance(0.4):
		press("move1")
		return

	# --- Spacing: mid distance ---
	if dist > PREFERRED_MAX:
		approach()
	elif dist < PREFERRED_MIN and chance(0.5):
		retreat()
	elif chance(0.25):
		approach()
	if chance(0.03):
		press_now("jump")
