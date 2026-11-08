class_name SimpleEnemyAI
extends EnemyAI
## Brain for the light PvE enemies (SimpleEnemy). Simple on purpose (testing / PvE):
##   - Uses a ready pattern that is in range (pattern weights + SimpleEnemy.wants_pattern)
##   - Otherwise keeps the target between keep_min and keep_max (from the enemy)
##   - Hops if the target is clearly above
## Thinks every 0.2-0.3 s (EnemyAI), never every frame.


func think() -> void:
	if not e.can_act():
		return
	face_target()
	var se := e as SimpleEnemy
	var keep_min := se.keep_min if se != null else 0.0
	var keep_max := se.keep_max if se != null else 110.0
	var attack_chance := se.attack_chance if se != null else 0.6

	# GROUP BATTLES (Story Mode): only a couple of enemies attack at the same time
	if chance(attack_chance + (0.15 if e.enraged else 0.0)) and StoryManager.may_attack(e):
		var p := pick_pattern(func(pp: EnemyPattern) -> bool: return se == null or se.wants_pattern(pp))
		if p != null:
			e.start_pattern(p)
			return

	# Don't stack on top of a teammate: step away from the closest one
	var crowd := _closest_ally_dx()
	if absf(crowd) < 30.0 or (absf(crowd) < 60.0 and chance(0.6)):
		e.move_dir = -signf(crowd) if crowd != 0.0 else (1.0 if chance(0.5) else -1.0)
		return

	if dist > keep_max:
		approach()
	elif dist < keep_min:
		retreat()
	elif chance(0.25):
		if chance(0.5):                                     # Small shuffle so they don't stand frozen
			approach()
		else:
			retreat()
	else:
		hold()
	if dy < -110.0 and chance(0.25):
		e.jump()


## Signed x distance to the closest living ally enemy (INF if alone). Few enemies = cheap.
func _closest_ally_dx() -> float:
	var best := INF
	for n in e.get_tree().get_nodes_in_group("fighters"):
		var o := n as BaseEnemy
		if o == null or o == e or o.is_dead or not CombatManager.are_allies(o, e):
			continue
		var dx := o.global_position.x - e.global_position.x
		if absf(dx) < absf(best):
			best = dx
	return best
