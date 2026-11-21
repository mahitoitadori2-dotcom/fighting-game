class_name PlayerEnemyBrain
extends EnemyAI
## SECRET CODE "R0t0rMode": a HUMAN drives an enemy (Rotor) with the normal fighter controls.
## His own code runs everything else (hitbox, sprite, moves, phase 2) - only the decisions are yours:
##   left / right  walk          jump  jump
##   ATTACK        1st move (Rotor: Bite)
##   1 / 2 / 3     2nd-4th moves (Spin Dash, Bark Wave, Tail Whip)
##   G (ultimate)  5th move (Fetch Bomb)
## Touch controls send the same buttons, so it works on phones too.

const BUTTONS := ["attack", "move1", "move2", "move3", "ultimate"]
const KEYS := ["ATTACK", "1", "2", "3", "G"]

var input := FighterInput.new()


func update(enemy: BaseEnemy, delta: float) -> void:
	e = enemy
	input.update(enemy, delta)
	target = CombatManager.find_enemy(e)                     # (Fetch Bomb aims at it)
	if target != null:
		var d := target.global_position - e.global_position
		dist = absf(d.x)
		dir = 1.0 if d.x >= 0.0 else -1.0
		dy = d.y
	e.move_dir = input.axis() if e.can_act() else 0.0
	if input.just_pressed("jump"):
		e.jump()
	for i in BUTTONS.size():
		if i < e.patterns.size() and input.just_pressed(String(BUTTONS[i])):
			e.start_pattern(e.patterns[i])
			break


## The HUD's cooldown lines for the human-driven enemy.
static func cooldown_lines(be: BaseEnemy) -> PackedStringArray:
	var lines: PackedStringArray = []
	for i in mini(be.patterns.size(), BUTTONS.size()):
		var p: EnemyPattern = be.patterns[i]
		lines.append("[%s] %s: %s" % [KEYS[i], p.display_name.trim_suffix("!"),
			"READY" if p.cooldown_left <= 0.0 else "%.1fs" % p.cooldown_left])
	return lines
