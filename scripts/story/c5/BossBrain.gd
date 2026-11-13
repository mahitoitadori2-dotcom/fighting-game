class_name BossBrain
extends EnemyAI
## HARD BOSS BRAIN (Colosseum 5). Much smarter than SimpleEnemyAI:
##   * fast reactions (decides every 0.1-0.18 s)
##   * FOCUS: goes for the human player unless the CPU partner is much closer
##   * ANTI-AIR: you jump -> it uses a pattern tagged "anti_air"
##   * EVADE / COUNTER: you swing close -> it dodges or counters ("evade" / "counter")
##   * CORNER ESCAPE: pinned against a wall -> "escape" pattern (leaps over you)
##   * PUNISH: you are low on HP or far away -> picks "ranged" / "close" patterns that fit
##   * FEINTS: steps in and out at mid range instead of standing still
## Patterns are tagged by the boss (C5Boss.tags).

var _feint := 0.0


func _init() -> void:
	super._init()
	think_min = 0.1
	think_max = 0.18


func update(enemy: BaseEnemy, delta: float) -> void:
	e = enemy
	_feint = maxf(_feint - delta, 0.0)
	_think -= delta
	if _think > 0.0:
		_edge_safety()
		return
	_think = rng.randf_range(think_min, think_max)
	target = _pick_target()
	if target == null:
		e.move_dir = 0.0
		return
	var d := target.global_position - e.global_position
	dist = absf(d.x)
	dir = 1.0 if d.x >= 0.0 else -1.0
	dy = d.y
	think()
	_edge_safety()


## The human player, unless the partner is much closer.
func _pick_target() -> Fighter:
	var nearest := CombatManager.find_enemy(e)
	var human: Fighter = null
	for n in e.get_tree().get_nodes_in_group("fighters"):
		var f := n as ControlledFighter
		if f != null and not f.is_dead and f.slot == 1 and not CombatManager.are_allies(e, f):
			human = f
	if human == null or nearest == null:
		return nearest
	var dh := e.global_position.distance_to(human.global_position)
	var dn := e.global_position.distance_to(nearest.global_position)
	return nearest if dn < dh * 0.45 else human


func think() -> void:
	if not e.can_act():
		return
	var b := e as C5Boss
	if b == null or b.is_transforming():
		return
	face_target()
	var t_cf := target as ControlledFighter
	var airborne := not target.is_on_floor() and dy < -70.0
	var swinging := t_cf != null and t_cf.is_attacking()
	var p: EnemyPattern = null

	if airborne and chance(0.7):
		p = _tagged(b, "anti_air")
	if p == null and swinging and dist < 190.0 and chance(0.6):
		p = _tagged(b, "counter")
		if p == null:
			p = _tagged(b, "evade")
	if p == null and _cornered() and dist < 240.0 and chance(0.65):
		p = _tagged(b, "escape")
	if p == null and dist > 420.0 and chance(0.6):
		p = _tagged(b, "ranged")
	if p == null and float(target.hp) / maxf(float(target.data.max_hp), 1.0) < 0.35 and dist < 260.0 and chance(0.5):
		p = _tagged(b, "close")                      # Smells blood: go in for the kill
	if p == null and chance(b.attack_chance + (0.15 if b.raging else 0.0)):
		p = pick_pattern()
	if p != null:
		e.start_pattern(p)
		return

	# Spacing + feints
	if _feint > 0.0:
		return
	if dist > b.keep_max:
		approach()
	elif dist < b.keep_min:
		retreat()
	elif chance(0.35):
		_feint = rng.randf_range(0.15, 0.35)
		if chance(0.5):
			retreat()
		else:
			approach()
	else:
		hold()
	if dy < -150.0 and chance(0.3):
		e.jump()


func _tagged(b: C5Boss, tag: String) -> EnemyPattern:
	return pick_pattern(func(pp: EnemyPattern) -> bool: return (b.tags.get(pp.id, []) as Array).has(tag))


func _cornered() -> bool:
	if not StoryManager.has_walls:
		return false
	var x := e.global_position.x
	return x < StoryManager.arena_left() + 160.0 or x > StoryManager.arena_right() - 160.0
