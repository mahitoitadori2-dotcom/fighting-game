class_name AlphaAI
extends BaseAI
## CPU brain for the APHA ARCHITECT (medium difficulty, like every CPU):
##   - Onslaught punches up close, Godly Touch when touching distance
##   - Barrage of Vadis at mid range, Thunderclap to stun from further away
##   - Portal Manifestation when far
##   - Cinematics (5-7) now and then when they are ready
##   - Takes off (E) once in a while: in the air punches become Air Charges


func think() -> void:
	var a := f as AlphaArchitect
	if a == null:
		super.think()
		return
	if try_block(160.0):
		return
	# Flight now and then (and land again)
	if chance(0.03):
		press_now("fly")
		return
	if a.flying and enemy.global_position.y > f.global_position.y + 60.0:
		_cur["crouch"] = true                          # Come down toward the enemy
	# Cinematic powers
	if cd_ready("opening") and dist < 520.0 and chance(0.12):
		press("move7")
		return
	if cd_ready("rod") and chance(0.08):
		press("move6")
		return
	if cd_ready("decay") and dist < 700.0 and chance(0.12):
		press("move5")
		return
	# Normal powers
	if cd_ready("touch") and not a.flying and dist < 120.0 and chance(0.4):
		press("move2")
		return
	if cd_ready("vadis") and dist < 330.0 and chance(0.4):
		press("move3")
		return
	if cd_ready("clap") and dist > 150.0 and dist < 700.0 and chance(0.45):
		press("move1")
		return
	if cd_ready("portal") and dist > 300.0 and chance(0.35):
		press("move4")
		return
	# Punch / Air Charge
	if dist < (260.0 if a.flying else 96.0):
		if chance(0.6):
			press("attack")
	else:
		approach()
	if not a.flying and enemy.global_position.y < f.global_position.y - 80.0 and chance(0.3):
		press_now("jump")
