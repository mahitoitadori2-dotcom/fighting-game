class_name RotorAI
extends EnemyAI
## Rotor's brain (EnemyAI): hyper, fast, keeps medium distance.
##   - Chases if the player is far, backs away if the player is spamming attacks
##   - Phase 1: Bite / Spin Dash / Bark Wave at random (pattern weights)
##   - Phase 2: Tail Whip + Fetch Bomb much more often (pattern weights) and acts more
##   - Darts in for quick Bites, hops if the player is above him

const MEDIUM_MIN := 140.0
const MEDIUM_MAX := 320.0

var _spam_hits: Array[float] = []      # Times the player started an attack recently
var _was_attacking := false
var _retreat_left := 0.0
var _time := 0.0


func update(enemy: BaseEnemy, delta: float) -> void:
	_time += delta
	_retreat_left = maxf(_retreat_left - delta, 0.0)
	_track_spam()
	super.update(enemy, delta)


func think() -> void:
	if not e.can_act():
		return
	face_target()

	# Backing off from a button-masher
	if _retreat_left > 0.0 or (_player_spamming() and dist < 170.0):
		if _retreat_left <= 0.0:
			_retreat_left = 0.6
		retreat()
		if chance(0.25):
			var bark := e.pattern("bark_wave")
			if bark != null and bark.is_ready():
				e.start_pattern(bark)               # Bark them away
		return

	# Use a pattern (more aggressive when enraged)
	if chance(0.75 if e.enraged else 0.55):
		var p := pick_pattern()
		if p != null:
			e.start_pattern(p)
			return

	# Movement: chase / medium distance / dart in to bite
	if dist > MEDIUM_MAX + 80.0:
		approach()                                  # Chase
	elif dist > MEDIUM_MAX:
		if chance(0.7):
			approach()
		else:
			hold()
	elif dist < MEDIUM_MIN:
		if dist < 75.0:
			hold()                                  # In bite range: bite next think
		elif chance(0.6):
			approach()                              # Commit to the bite
		else:
			retreat()
	else:
		var ranged_ready := false
		for id in ["spin_dash", "bark_wave", "fetch_bomb"]:
			var rp := e.pattern(id)
			if rp != null and rp.is_ready() and rp.weight(e.phase) > 0.0:
				ranged_ready = true
		if chance(0.3 if ranged_ready else 0.65):
			approach()                              # Dart in for a bite (more when ranged moves are cooling down)
		elif chance(0.3):
			retreat()
		else:
			hold()
	if dy < -90.0 and chance(0.3):
		e.jump()


func _track_spam() -> void:
	if target == null or not is_instance_valid(target):
		return
	var cf := target as ControlledFighter
	var attacking := cf != null and cf.is_attacking()
	if attacking and not _was_attacking:
		_spam_hits.append(_time)
	_was_attacking = attacking
	while not _spam_hits.is_empty() and _time - _spam_hits[0] > 1.4:
		_spam_hits.pop_front()


func _player_spamming() -> bool:
	return _spam_hits.size() >= 3
