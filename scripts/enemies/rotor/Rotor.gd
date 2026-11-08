class_name Rotor
extends BaseEnemy
## ROTOR: hyper blue merle Australian Shepherd. Test enemy #1 (PvE boss).
## Small (64x64 hitbox), low to the ground, fast. Built on BaseEnemy + EnemyPattern.
##
##   Bite        4 dmg, short range, no cooldown (spammable)
##   Spin Dash  10 dmg, 6 s  - crouch + spin in place 0.5 s, then dash across the arena (armored)
##   Bark Wave   6 dmg, 8 s  - mouth wide + "!", then a sound wave rolls forward
##   Tail Whip   8 dmg, 10 s - tail spins, hits ALL around him
##   Fetch Bomb 12 dmg, 15 s - picks up a ball, throws it; it bounces and explodes after 1 s
## Phase 2 (< 50% HP): ENRAGED - faster, glowing fur, cooldowns 20% faster,
## Tail Whip + Fetch Bomb much more often.

const DASH_SPEED := 900.0
const BITE_KB := Vector2(220, -110)
const SPIN_KB := Vector2(520, -300)
const BARK_KB := Vector2(320, -150)
const TAIL_KB := Vector2(380, -260)
const TAIL_RADIUS := 92.0

# Pose read by RotorArt
var pose := "idle"                 # idle / bite / spin_tele / spin / bark_tele / bark / tail / fetch_tele / fetch
var pose_t := 0.0
var bark_timer := 0.0


func _make_data() -> CharacterData:
	var d := CharacterData.new()
	d.character_name = "Rotor"
	d.max_hp = 100
	d.body_size = Vector2(64, 64)        # Small and low to the ground
	d.move_speed = 400.0
	d.acceleration = 3000.0
	d.deceleration = 3200.0
	d.jump_force = 700.0
	d.hitstun_time = 0.18
	d.gauge_enabled = false
	return d


## The pattern list (also read by the roster to build Rotor's card).
static func make_patterns() -> Array[EnemyPattern]:
	var list: Array[EnemyPattern] = []
	#                         id            name            cd    dmg  min   max    anim     tele  active rec   big    weights [P1, P2]
	list.append(EnemyPattern.make("bite", "BITE", 0.0, 4, 0.0, 85.0, "bite", 0.12, 0.12, 0.28, false, [3.0, 2.0]))
	list.append(EnemyPattern.make("spin_dash", "SPIN DASH!", 6.0, 10, 120.0, 700.0, "spin", 0.5, 0.75, 0.45, true, [2.0, 1.5], true))
	list.append(EnemyPattern.make("bark_wave", "BARK WAVE!", 8.0, 6, 90.0, 600.0, "bark", 0.45, 0.25, 0.35, true, [2.0, 1.2]))
	list.append(EnemyPattern.make("tail_whip", "TAIL WHIP!", 10.0, 8, 0.0, 110.0, "tail", 0.35, 0.3, 0.35, true, [0.0, 3.5]))
	list.append(EnemyPattern.make("fetch_bomb", "FETCH BOMB!", 15.0, 12, 140.0, 650.0, "fetch", 0.5, 0.2, 0.4, true, [0.0, 3.5]))
	return list


func build_patterns() -> Array[EnemyPattern]:
	return make_patterns()


func _make_brain() -> EnemyAI:
	return RotorAI.new()


func draw_model_on(c: CanvasItem) -> void:
	RotorArt.draw(c, self)


## Rotor's K.O. is always the cartoon dog death (unless he fell off the island).
func custom_death_type(_hit: HitData) -> String:
	return DeathManager.DOG


# ============================================================
# PATTERN HOOKS
# ============================================================
func _on_telegraph(p: EnemyPattern) -> void:
	pose = p.animation + "_tele" if p.big else p.animation
	pose_t = 0.0
	if p.id == "bark_wave":
		Effects.play_hit_sound(self, "rotor_bark_windup", global_position)


func _on_attack_start(p: EnemyPattern) -> void:
	pose = p.animation
	pose_t = 0.0
	match p.id:
		"bite":
			hitbox.activate(make_hit(p.damage, Vector2(facing * BITE_KB.x, BITE_KB.y), "rotor_bite"),
				Vector2(facing * 44.0, -30.0), Vector2(46, 32))
			velocity.x += facing * 200.0
		"spin_dash":
			SoundManager.play_sfx("dash")
			hitbox.activate(make_hit(p.damage, Vector2(facing * SPIN_KB.x, SPIN_KB.y), "spin_dash"),
				Vector2(0, -32), Vector2(84, 64))
			Effects.trail(visuals, Color(0.62, 0.68, 0.78), 40.0, 10)
		"bark_wave":
			var w := OptimizationManager.take(BarkWave) as BarkWave              # Pooled
			w.source = self
			w.damage = p.damage
			w.knockback = BARK_KB
			w.dir = float(facing)
			get_parent().add_child(w)
			w.global_position = global_position + Vector2(facing * 50.0, -40.0)
			Effects.play_hit_sound(self, "rotor_bark", global_position)
			Effects.shake(self, 3.0)
		"tail_whip":
			hit_in_radius(global_position + Vector2(0, -30), TAIL_RADIUS, p.damage, TAIL_KB, "tail_whip")
		"fetch_bomb":
			var b := OptimizationManager.take(FetchBall) as FetchBall            # Pooled
			b.source = self
			b.damage = p.damage
			# Aim: land near the target, then bounce once before the 1 s fuse pops
			var tx := float(facing) * 220.0
			if brain != null and brain.target != null and is_instance_valid(brain.target):
				tx = brain.target.global_position.x - global_position.x
			b.velocity = Vector2(clampf(tx / 0.8, -520.0, 520.0), -480.0)
			get_parent().add_child(b)
			b.global_position = global_position + Vector2(facing * 50.0, -44.0)


func _on_attack_update(p: EnemyPattern, _delta: float) -> void:
	if p.id == "spin_dash":
		velocity.x = facing * DASH_SPEED * phase_speed_mult
		if not ground_ahead(50.0):
			state_time = state_len                 # Stop at the island edge instead of flying off


func _on_attack_end(p: EnemyPattern) -> void:
	if p.id == "spin_dash":
		velocity.x *= 0.3


func _owns_velocity_x() -> bool:
	return estate == EState.ATTACK and current != null and current.id == "spin_dash"


func _on_phase_changed(_new_phase: int) -> void:
	Effects.play_hit_sound(self, "rotor_enraged", global_position)


# ============================================================
# VISUALS
# ============================================================
func _update_visuals(delta: float) -> void:
	pose_t += delta
	if estate == EState.IDLE or estate == EState.MOVE:
		pose = "idle"
	# Random happy barks while idle (personality)
	bark_timer -= delta
	if bark_timer <= 0.0:
		bark_timer = randf_range(3.0, 6.0)
		if estate == EState.IDLE or estate == EState.MOVE:
			Effects.popup(self, global_position + Vector2(facing * 30.0, -80), "WOOF!", Color(1, 1, 1, 0.9), 14)
	super._update_visuals(delta)
