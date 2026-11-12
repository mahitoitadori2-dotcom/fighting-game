class_name SimpleEnemy
extends BaseEnemy
## Shared base for the light PvE enemies (King Frog, Frost Jarl, Raphael, Elton John,
## Lincoln, Cyber T-Rex). It is still the SAME system as Rotor:
##     BaseEnemy (state machine, HP, EnemyHUD)  +  EnemyPattern list  +  EnemyAI brain.
## It only adds what all of them share, so each enemy file is just:
##     _make_data()       -> SimpleEnemy.make_data(name, hp, body, speed)
##     make_patterns()    -> 2-3 EnemyPatterns (static: the roster card reads it too)
##     _attack(p)         -> what happens when a pattern fires
##     draw_model_on(c) / draw_portrait(c, t)
##
## BALANCE (EnemyManager): 60 HP (70 for the tanky ones), 2-3 simple moves,
## damage x EnemyManager.DAMAGE_MULT.

var pose := "idle"            # Read by the art: idle / <anim>_tele / <anim>
var pose_t := 0.0
var keep_min := 0.0           # SimpleEnemyAI keeps the target between these distances
var keep_max := 110.0
var attack_chance := 0.6      # Per think (0.2-0.3 s) when a pattern is ready

var _flavor_timer := 4.0


## Standard stat block for a light enemy.
static func make_data(p_name: String, hp_v: int, body: Vector2, move_speed: float) -> CharacterData:
	var d := CharacterData.new()
	d.character_name = p_name
	d.max_hp = hp_v
	d.body_size = body                  # Simple RectangleShape2D body + hurtbox (Fighter)
	d.move_speed = move_speed
	d.acceleration = 2400.0
	d.deceleration = 3000.0
	d.jump_force = 700.0
	d.hitstun_time = 0.2
	d.gauge_enabled = false
	return d


func build_patterns() -> Array[EnemyPattern]:
	return get_script().call("make_patterns")


func _make_brain() -> EnemyAI:
	return SimpleEnemyAI.new()


## Damage of a pattern after the global enemy multiplier (never 0 for damaging moves).
func dmg(p: EnemyPattern) -> int:
	if p.damage <= 0:
		return 0
	return maxi(1, roundi(p.damage * EnemyManager.DAMAGE_MULT * damage_mult))


## OVERRIDE: may the AI use this pattern right now? (Raphael only heals when hurt.)
func wants_pattern(_p: EnemyPattern) -> bool:
	return true


## OVERRIDE: the pattern fires.
func _attack(_p: EnemyPattern) -> void:
	pass


## OVERRIDE: little idle lines ("RIBBIT!"). Empty = none.
func flavor_lines() -> Array[String]:
	return []


# ============================================================
# PROJECTILES (pooled)
# ============================================================
func spawn_projectile() -> EnemyProjectile:
	var p := OptimizationManager.take(EnemyProjectile) as EnemyProjectile
	p.source = self
	return p


func launch(p: EnemyProjectile, world_pos: Vector2) -> void:
	get_parent().add_child(p)
	p.global_position = world_pos


# ============================================================
# HELPERS
# ============================================================
## World X of the current target (or a bit in front of us).
func target_x() -> float:
	if brain != null and brain.target != null and is_instance_valid(brain.target):
		return brain.target.global_position.x
	return global_position.x + facing * 220.0


## Keep an X inside the island (so hops / drops never aim at the void).
func clamp_to_ground(x: float, margin: float = 70.0) -> float:
	var g := get_tree().get_first_node_in_group("arena_ground") as ArenaGround
	if g == null:
		return x
	return clampf(x, g.left_edge() + margin, g.right_edge() - margin)


## Stun every opponent within `r` (no damage). Returns how many.
func stun_in_radius(center: Vector2, r: float, seconds: float) -> int:
	var count := 0
	for n in get_tree().get_nodes_in_group("fighters"):
		var f := n as Fighter
		if f == null or f.is_dead or CombatManager.are_allies(self, f):
			continue
		if (f.global_position + Vector2(0, -f.data.body_size.y * 0.5)).distance_to(center) > r:
			continue
		f.stun_timer = maxf(f.stun_timer, seconds)
		Effects.popup(f, f.global_position + Vector2(0, -170), "STUNNED!", Color(1.0, 0.9, 0.3), 24)
		count += 1
	return count


## Art state shared by all enemy drawings (same dictionary style as RotorArt).
func art_state() -> Dictionary:
	return {
		"t": anim_time, "walk": walk_phase, "floor": is_on_floor(), "moving": absf(velocity.x) > 30.0,
		"pose": pose, "pose_t": pose_t, "enraged": enraged, "dead": is_dead,
	}


# ============================================================
# BaseEnemy hooks
# ============================================================
func _on_telegraph(p: EnemyPattern) -> void:
	pose = p.animation + "_tele"
	pose_t = 0.0


func _on_attack_start(p: EnemyPattern) -> void:
	pose = p.animation
	pose_t = 0.0
	_attack(p)


func _on_respawn() -> void:
	super._on_respawn()
	pose = "idle"
	pose_t = 0.0


func _update_visuals(delta: float) -> void:
	pose_t += delta
	if estate == EState.IDLE or estate == EState.MOVE:
		pose = "idle"
	var lines := flavor_lines()
	if not lines.is_empty():
		_flavor_timer -= delta
		if _flavor_timer <= 0.0:
			_flavor_timer = randf_range(4.0, 7.0)
			if estate == EState.IDLE or estate == EState.MOVE:
				Effects.popup(self, global_position + Vector2(facing * 24.0, -data.body_size.y - 10.0),
					lines[randi() % lines.size()], Color(1, 1, 1, 0.9), 14)
	super._update_visuals(delta)
