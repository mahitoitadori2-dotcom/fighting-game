class_name AntiArchitectAI
extends BaseAI
## CPU brain for the ANTI ARCHITECT: a RUSHER.
##   - Always walks in; punches up close (2 punches = Onslaught flash, BaseAI repeats it often)
##   - Workflies at mid range, Anti Laser down a long line, Overcharge when you are next to him
##   - G: 1 bar BattleFlies (any range) / 2 bars Energy Pool (close) / 3 bars Never Out Of Plans (close)


func _init() -> void:
	super._init()
	onslaught_chance = 0.75                       # He LOVES Onslaught
	block_chance = 0.15


func think() -> void:
	if try_block(140.0):
		return
	var b := bars()
	if b == 1 and dist < 700.0 and chance(0.45):
		press("ultimate")                         # BattleFlies
		return
	if b == 2 and dist < 180.0 and chance(0.45):
		press("ultimate")                         # Energy Pool under you both
		return
	if b >= 3 and dist < 260.0 and chance(0.45):
		press("ultimate")                         # Never Out Of Plans
		return
	if cd_ready("overcharge") and dist < 130.0 and chance(0.35) and hp_ratio() > 0.1:
		press("move3")
		return
	if cd_ready("laser") and dist > 150.0 and dist < 880.0 and absf(enemy.global_position.y - f.global_position.y) < 80.0 and chance(0.45):
		press("move2")
		return
	if cd_ready("workflies") and dist > 110.0 and dist < 700.0 and chance(0.5):
		press("move1")
		return
	if dist > 80.0:
		approach()                                # Rushdown: always closing in
		if enemy.global_position.y < f.global_position.y - 120.0 and chance(0.3):
			press_now("jump")
	elif chance(0.75):
		press("attack")
