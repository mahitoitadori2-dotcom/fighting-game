class_name Kokusen
extends FightBoss
## KOKUSEN - Fights-mode boss (Versus / Enemy Test only, not in Story Mode).
## A towering sorcerer: dark CRIMSON head with FOUR glowing eyes and a cruel grin, a long
## flowing BLACK SORCERER ROBE. 2500 HP. He FLIES (switches between ground and air on his
## own) and every MELEE hit is an ONSLAUGHT hit (heavy, fast).
##
##   Sorcerer Strike     melee claw, always Onslaught
##   1 Cut               flings his arm: tens of cutting slashes forward (aimed at you in the air)
##   2 Underground Flame ground: 5 giant rolling fireballs that set the floor on fire
##                       air: many smaller, faster fireballs raining toward you
##   3 Greatest One      ground only GRAB: slams his hand into his chest, lunges, grabs you and
##                       slowly tries to rip you apart - it always fails and you break loose
##   4 Unknown Force     ground: PULLS you to him.  air: REPELS you away (with damage)
##   5 Meteor Rain       CINEMATIC + cutscene over the Earth: debris falls first, then one
##                       giant meteor (a red marker shows where)
##   6 No Fear In Sight  barrage of flame slashes forward (aimed at you in the air)
##   7 Closed World      CINEMATIC: his four eyes open wide, a circle of fire surrounds the arena
##                       and sends slashes, flames and debris everywhere
## Phase 2 (< 50% HP): faster, attacks more often, more slashes.
## During his two cinematics he cannot be hurt; you are frozen only during the wind-up,
## then you can dodge the meteor / the Closed World storm.

const HP := 2500
const PORTRAIT_H := 250.0                    # Art height for Character Select cards
const HOVER := 200.0                         # Flight height above the floor

const ROBE := Color(0.05, 0.04, 0.07)
const ROBE_HI := Color(0.17, 0.14, 0.21)
const ROBE_FOLD := Color(0.10, 0.08, 0.13)
const TRIM := Color(0.55, 0.04, 0.08)
const HEAD := Color(0.45, 0.04, 0.08)
const HEAD_SHADE := Color(0.27, 0.01, 0.04)
const HEAD_HI := Color(0.66, 0.12, 0.14)
const EYE := Color(1.0, 0.80, 0.25)
const EYE_GLOW := Color(1.0, 0.45, 0.10)
const TEETH := Color(0.95, 0.90, 0.80)

var flying := false
var eyes_wide := false
var _floor_y := INF
var _flight_t := 5.0
var _cine := false
var _cine_marker: Node2D
var _letterbox: KokusenFx.Letterbox
var _grab_was_immune := false
var _victim: Fighter = null
var _rips := 0
var _rip_t := 0.0
var _lunged := false
var _shots_n := 0
var _volley: Dictionary = {}                 # Shared by the shots of one attack (KokusenFx.Shot.cap)

## Volley caps: how many shots of ONE attack can hit you (fair "tens of cuts").
const CUT_CAP := 4                           # 4 x 2 = max 8
const NO_FEAR_CAP := 4                       # 4 x 3 = max 12
const FIREBALL_CAP := 2                      # 2 x 6 = max 12 (ground) / 3 x 3 = 9 (air)
const DEBRIS_CAP := 2
const CLOSED_CAP := 6


func _make_data() -> CharacterData:
	keep_min = 140.0
	keep_max = 430.0
	attack_chance = 0.75
	phase2_speed_mult = 1.3
	phase2_cooldown_mult = 0.7
	voice_id = "kokusen"
	voice_pitch = 0.5
	voice_rate = 0.88
	intro_lines = ["Four eyes see your end.", "Kneel. Or burn."]
	attack_lines = {"greatest_one": "Come here.", "meteor": "Let the sky fall.", "closed_world": "This world is closed."}
	rage_line = "You made me open my eyes."
	rage_title = "ALL FOUR EYES OPEN!"
	death_line = "Impossible..."
	roar_sfx = "roar"
	accent = Color(1.0, 0.3, 0.25)
	var d := SimpleEnemy.make_data("Kokusen", HP, Vector2(96, 210), 230.0)
	d.hitstun_time = 0.06
	d.respawn_delay = 3.0
	d.jump_force = 820.0
	return d


static func make_patterns() -> Array[EnemyPattern]:
	var list: Array[EnemyPattern] = []
	#                          id               name                  cd    dmg  min    max      anim       tele  active rec   big    weights      armored
	list.append(EnemyPattern.make("strike", "SORCERER STRIKE", 1.9, 5, 0.0, 150.0, "strike", 0.16, 0.14, 0.25, false, [2.0, 2.4]))
	list.append(EnemyPattern.make("cut", "CUT!", 3.2, 2, 0.0, 760.0, "cut", 0.3, 0.6, 0.3, true, [1.6, 1.8]))
	list.append(EnemyPattern.make("underground_flame", "UNDERGROUND FLAME!", 6.5, 6, 0.0, 900.0, "flame", 0.5, 0.5, 0.4, true, [1.3, 1.5]))
	list.append(EnemyPattern.make("greatest_one", "GREATEST ONE!", 9.0, 3, 0.0, 380.0, "grab", 0.45, 3.0, 0.5, true, [1.2, 1.4], true))
	list.append(EnemyPattern.make("unknown_force", "UNKNOWN FORCE!", 7.0, 6, 200.0, 1000.0, "force", 0.4, 0.3, 0.35, true, [1.0, 1.2]))
	list.append(EnemyPattern.make("meteor", "METEOR RAIN!", 34.0, 20, 0.0, 99999.0, "meteor", 0.6, 0.2, 0.3, true, [0.6, 0.9], true))
	list.append(EnemyPattern.make("no_fear", "NO FEAR IN SIGHT!", 5.5, 3, 0.0, 700.0, "nofear", 0.35, 1.0, 0.35, true, [1.4, 1.6]))
	list.append(EnemyPattern.make("closed_world", "CLOSED WORLD!", 45.0, 4, 0.0, 99999.0, "closed", 0.6, 0.2, 0.3, true, [0.4, 0.8], true))
	list[0].note = "melee, always an ONSLAUGHT hit"
	list[1].note = "tens of slashes, 2 each (max 4 hit you)"
	list[2].note = "ground: 5 giant rolling fireballs + burning floor; air: many small ones"
	list[3].note = "ground-only GRAB, 6 rips (mash to escape), always fails to tear you"
	list[4].note = "ground: pulls you in; air: repels you"
	list[5].note = "CINEMATIC: debris, then one giant meteor (dodge the red mark)"
	list[6].note = "barrage of flame slashes, 3 each (max 4 hit you)"
	list[7].note = "CINEMATIC: circle of fire, attacks from everywhere"
	return list


func _ready() -> void:
	super._ready()
	knockback_scale = 0.3
	_delay_cinematics()


func _on_respawn() -> void:
	super._on_respawn()
	knockback_scale = 0.3
	_set_flying(false, true)
	_victim = null
	_delay_cinematics()


## The two cinematics are never used in the first seconds of the fight.
func _delay_cinematics() -> void:
	if pattern("meteor") != null:
		pattern("meteor").cooldown_left = 14.0
	if pattern("closed_world") != null:
		pattern("closed_world").cooldown_left = 26.0


# ============================================================
# FLIGHT
# ============================================================
func can_act() -> bool:
	return not _cine and super.can_act()


func _physics_process(delta: float) -> void:
	if not _cine and CombatManager.fight_active and not is_dead and not is_time_frozen() and can_act():
		_flight_t -= delta
		var tgt: Fighter = brain.target if brain != null else null
		var high := tgt != null and is_instance_valid(tgt) and tgt.global_position.y < global_position.y - 170.0
		if high and not flying:
			_set_flying(true)                           # You went up: he follows you into the air
		elif _flight_t <= 0.0:
			_set_flying(not flying)
	super._physics_process(delta)


func _set_flying(on: bool, quiet: bool = false) -> void:
	_flight_t = randf_range(4.0, 7.0) if enraged else randf_range(5.0, 9.0)
	if flying == on:
		return
	flying = on
	if quiet:
		return
	SoundManager.play_sfx("whoosh", -4.0)
	Effects.red_burst(self, global_position + Vector2(0, -20), 70.0)


## The AI's "hop" = take off instead.
func jump(_force_mult: float = 1.0) -> void:
	if not flying and can_act():
		_set_flying(true)


func _movement(delta: float) -> void:
	if _cine:
		velocity = Vector2.ZERO
		return
	super._movement(delta)
	if is_on_floor() and not flying:
		_floor_y = global_position.y
	if flying and _floor_y != INF:
		var goal := _floor_y - HOVER + sin(anim_time * 2.2) * 10.0
		velocity.y = (goal - global_position.y) * 4.0


func _ground_y() -> float:
	return _floor_y if _floor_y != INF else global_position.y


func _target() -> Fighter:
	var t: Fighter = brain.target if brain != null else null
	if t == null or not is_instance_valid(t) or t.is_dead:
		t = CombatManager.find_enemy(self)
	return t


func _target_dy() -> float:
	var t := _target()
	return (t.global_position.y - global_position.y) if t != null else 0.0


## Ground / air rules for the AI.
func wants_pattern(p: EnemyPattern) -> bool:
	match p.id:
		"greatest_one":
			return not flying and absf(_target_dy()) < 140.0
		"strike":
			return absf(_target_dy()) < 160.0
		"meteor", "closed_world":
			return not CombatManager.is_time_stopped()
	return true


# ============================================================
# ATTACKS
# ============================================================
func _hand_pos() -> Vector2:
	return global_position + Vector2(facing * 70.0, -125.0)


## Direction for the "forward" moves: straight ahead on the ground, at you in the air.
func _aim_dir() -> Vector2:
	var fwd := Vector2(float(facing), 0.0)
	if not flying:
		return fwd
	var t := _target()
	if t == null:
		return fwd
	var to := (t.global_position + Vector2(0, -60) - _hand_pos())
	if to.x * float(facing) <= 0.0:
		return fwd
	return to.normalized()


func _attack(p: EnemyPattern) -> void:
	match p.id:
		"strike":
			var h := make_hit(dmg(p), Vector2(facing * 520.0, -300.0), "sorcerer_strike")
			h.onslaught = true                              # Every melee hit is an Onslaught
			hitbox.activate(h, Vector2(facing * 80.0, -110.0), Vector2(150, 150))
			velocity.x = facing * 260.0
			SoundManager.play_sfx("sword_slash", -2.0)
			SoundManager.play_sfx("punch", -4.0)
		"cut":
			_shots_n = 0
			_volley = {}
			SoundManager.play_sfx("whoosh")
		"underground_flame":
			_underground_flame(p)
		"greatest_one":
			_lunged = false
			_victim = null
			_rips = 0
			SoundManager.play_sfx("slam", -4.0)
			Effects.red_burst(self, global_position + Vector2(facing * 8.0, -130.0), 60.0)
		"unknown_force":
			_unknown_force(p)
		"meteor":
			_meteor_rain(p)
		"no_fear":
			_shots_n = 0
			_volley = {}
			SoundManager.play_sfx("flame", -2.0)
		"closed_world":
			_closed_world(p)


func _on_attack_update(p: EnemyPattern, delta: float) -> void:
	match p.id:
		"cut":
			var n := 16 if enraged else 12                  # "Tens of cuts"
			while _shots_n < n and state_time >= float(_shots_n) * (p.active_time / float(n)):
				_shots_n += 1
				var d := _aim_dir().rotated(randf_range(-0.22, 0.22))
				var s := KokusenFx.shot(self, "cut", _hand_pos() + Vector2(0, randf_range(-50.0, 50.0)), d * randf_range(820.0, 980.0), dmg(p), 22.0, 0.9, true)
				s.knockback = Vector2(120, -90)
				s.volley = _volley
				s.cap = CUT_CAP
				if _shots_n % 3 == 0:
					SoundManager.play_sfx("swing", -10.0)
		"no_fear":
			var n := 12 if enraged else 8
			while _shots_n < n and state_time >= float(_shots_n) * (p.active_time / float(n)):
				_shots_n += 1
				var d := _aim_dir().rotated(randf_range(-0.12, 0.12))
				var s := KokusenFx.shot(self, "flame_slash", _hand_pos() + Vector2(0, randf_range(-35.0, 35.0)), d * 760.0, dmg(p), 34.0, 1.1, true)
				s.knockback = Vector2(180, -140)
				s.volley = _volley
				s.cap = NO_FEAR_CAP
				SoundManager.play_sfx("sword_slash" if _shots_n % 2 == 0 else "flame", -8.0)
		"greatest_one":
			_greatest_one_update(p, delta)


func _owns_velocity_x() -> bool:
	return _cine or (estate == EState.ATTACK and current != null and current.id == "greatest_one")


# ----- 2. UNDERGROUND FLAME -----
func _underground_flame(p: EnemyPattern) -> void:
	SoundManager.play_sfx("flame")
	Effects.shake(self, 6.0)
	var volley := {}
	if not flying:
		# 5 GIANT fireballs rolling along the floor, burning it
		for i in 5:
			var s := KokusenFx.shot(self, "fireball", Vector2(global_position.x + facing * (70.0 + float(i) * 16.0), _ground_y() - 46.0),
				Vector2(facing * (340.0 + float(i) * 75.0), 0.0), dmg(p), 44.0, 2.6, true)
			s.knockback = Vector2(380, -320)
			s.burn_trail = i == 4                               # One burning trail (no stacked burns)
			s.volley = volley
			s.cap = FIREBALL_CAP
	else:
		# In the air: many smaller, faster fireballs raining toward you
		var t := _target()
		var aim := Vector2(float(facing), 0.6).normalized()
		if t != null:
			aim = (t.global_position + Vector2(0, -50) - _hand_pos()).normalized()
		var n := 14 if enraged else 11
		for i in n:
			var d := aim.rotated(randf_range(-0.45, 0.45))
			var s := KokusenFx.shot(self, "ember", _hand_pos(), d * randf_range(620.0, 820.0), maxi(1, dmg(p) / 2), 16.0, 1.8, false)
			s.knockback = Vector2(200, -160)
			s.floor_y = _ground_y() - 12.0
			s.volley = volley
			s.cap = FIREBALL_CAP + 1


# ----- 3. GREATEST ONE (grab) -----
func _greatest_one_update(p: EnemyPattern, delta: float) -> void:
	if _victim == null:
		if state_time < 0.4:
			dash_step(900.0)                                    # The lunge
			var t := _target()
			if t != null and not t.is_dead and t.grabbed_by == null:
				var dx := (t.global_position.x - global_position.x) * float(facing)
				if dx > -20.0 and dx < 150.0 and absf(t.global_position.y - global_position.y) < 140.0:
					_grab(t, p)
		elif not _lunged:
			_lunged = true
			velocity.x = 0.0
			SoundManager.play_sfx("whoosh", -4.0)                # Grabbed at nothing
			state_time = maxf(state_time, state_len - 0.1)
		return
	velocity.x = 0.0
	if not is_instance_valid(_victim) or _victim.is_dead or _victim.grabbed_by != self:
		_victim = null                                          # Broke free by mashing
		state_time = state_len
		return
	_rip_t -= delta
	if _rip_t <= 0.0 and _rips < 6:
		_rip_t = 0.4                                            # SLOWLY tries to rip you apart
		_rips += 1
		var h := make_hit(dmg(p), Vector2.ZERO, "greatest_one")
		h.blockable = false
		h.causes_hitstun = false
		h.onslaught = true
		CombatManager.apply_hit(h, _victim)
		Effects.shake(self, 5.0 + float(_rips) * 1.5)
		Effects.hit_sparks(self, _victim.global_position + Vector2(0, -70), 8, 1.2)
		SoundManager.play_sfx("bite" if _rips % 2 == 0 else "punch", -4.0)
	elif _rips >= 6 and _rip_t <= 0.0:
		_rip_fails()
		state_time = state_len


func _grab(t: Fighter, _p: EnemyPattern) -> void:
	_victim = t
	_lunged = true
	_rip_t = 0.5
	grab_hold_distance = 120.0
	velocity.x = 0.0
	t.begin_grab(self)
	Effects.popup(t, t.global_position + Vector2(0, -180), "GRABBED!", Color(1.0, 0.4, 0.35), 24)
	SoundManager.play_sfx("chain")


## He always FAILS to tear you apart: you break loose and he staggers.
func _rip_fails() -> void:
	if _victim != null and is_instance_valid(_victim) and _victim.grabbed_by == self:
		_victim.release_grab()
		var away := Vector2(_victim.global_position.x + float(facing) * 150.0, _victim.global_position.y)
		_victim.force_move_to(Vector2(clamp_to_ground(away.x, 60.0), away.y), 0.3)
		Effects.popup(self, global_position + Vector2(0, -data.body_size.y - 70.0), "...IT WILL NOT TEAR!", accent, 24)
	_victim = null
	stun_timer = maxf(stun_timer, 0.5)                          # Staggers: your opening
	SoundManager.play_sfx("roar", -6.0, 0.2)


## Untouchable during his cinematics (damage_taken_mult 0 would still let 1-damage hits through).
func take_hit(amount: int, hit: HitData) -> void:
	if _cine:
		return
	super.take_hit(amount, hit)


func _on_attack_end(p: EnemyPattern) -> void:
	if p.id == "greatest_one" and _victim != null:
		_rip_fails()
	if p.id == "strike" or p.id == "greatest_one":
		velocity.x *= 0.2


func _cancel_pattern() -> void:
	if _victim != null and is_instance_valid(_victim) and _victim.grabbed_by == self:
		_victim.release_grab()
	_victim = null
	super._cancel_pattern()


# ----- 4. UNKNOWN FORCE -----
func _unknown_force(p: EnemyPattern) -> void:
	var wave := KokusenFx.ForceWave.new()
	wave.pull = not flying
	wave.reach = 520.0
	get_parent().add_child(wave)
	wave.global_position = global_position + Vector2(0, -100)
	SoundManager.play_sfx("void_goo")
	Effects.shake(self, 8.0)
	for n in get_tree().get_nodes_in_group("fighters"):
		var f := n as Fighter
		if f == null or f.is_dead or CombatManager.are_allies(self, f):
			continue
		if f.global_position.distance_to(global_position) > 1000.0:
			continue
		var side := signf(f.global_position.x - global_position.x)
		if side == 0.0:
			side = float(facing)
		if not flying:
			# GROUND: pulled in right in front of him (and briefly stunned)
			f.force_move_to(Vector2(global_position.x + side * 110.0, f.global_position.y), 0.45)
			f.stun_timer = maxf(f.stun_timer, 0.35)
			Effects.popup(f, f.global_position + Vector2(0, -170), "PULLED!", Color(1.0, 0.4, 0.35), 22)
		else:
			# AIR: repelled far away, with damage
			var h := make_hit(dmg(p), Vector2(side * 200.0, -200.0), "unknown_force")
			h.origin = global_position
			CombatManager.apply_hit(h, f)
			f.force_move_to(Vector2(clamp_to_ground(f.global_position.x + side * 340.0, 60.0), f.global_position.y), 0.4)
			Effects.popup(f, f.global_position + Vector2(0, -170), "REPELLED!", Color(1.0, 0.4, 0.35), 22)


# ============================================================
# CINEMATICS (5 Meteor Rain, 7 Closed World)
# ============================================================
func _cine_begin(title: String, zoom: float, focus_off: Vector2 = Vector2(0, -120)) -> void:
	_cine = true
	hitbox.deactivate()
	velocity = Vector2.ZERO
	damage_taken_mult = 0.0                                     # Can't be hurt during the cinematic
	_grab_was_immune = grab_immune
	grab_immune = true
	CombatManager.time_stop_owner = self                        # You freeze while he winds up
	CombatManager.time_stop_left = 999.0
	_cine_marker = Node2D.new()
	get_parent().add_child(_cine_marker)
	_cine_marker.global_position = global_position + focus_off
	ArenaCamera.focus = _cine_marker
	ArenaCamera.focus_zoom = zoom
	ArenaCamera.focus_offset = Vector2.ZERO
	_letterbox = KokusenFx.Letterbox.new()
	_letterbox.title = title
	get_tree().current_scene.add_child(_letterbox)


## Unfreeze everyone (the dodgeable part of a cinematic starts).
func _cine_release() -> void:
	Engine.time_scale = 1.0
	if CombatManager.time_stop_owner == self:
		CombatManager.end_time_stop()


func _cine_end() -> void:
	_cine_release()
	damage_taken_mult = 1.0
	grab_immune = _grab_was_immune
	ArenaCamera.focus = null
	ArenaCamera.focus_offset = Vector2(0, -110)
	if _cine_marker != null and is_instance_valid(_cine_marker):
		_cine_marker.queue_free()
	_cine_marker = null
	if _letterbox != null and is_instance_valid(_letterbox):
		_letterbox.close()
	_letterbox = null
	eyes_wide = false
	_cine = false
	pose = "idle"


func _exit_tree() -> void:
	if _cine:                                                   # Scene changed mid-cinematic: never leave the world frozen
		Engine.time_scale = 1.0
		if CombatManager.time_stop_owner == self:
			CombatManager.end_time_stop()
		ArenaCamera.focus = null
		ArenaCamera.focus_offset = Vector2(0, -110)


## Real-time wait (ignores slow motion); false if he was removed / died meanwhile.
func _wait(seconds: float) -> bool:
	if not is_inside_tree():
		return false
	await get_tree().create_timer(seconds, true, false, true).timeout
	return is_inside_tree() and not is_dead


func _abort() -> void:
	if is_inside_tree() and _cine:
		_cine_end()


func _move_to(pos: Vector2, seconds: float) -> void:
	var tw := create_tween().set_ignore_time_scale(true)
	tw.tween_property(self, "global_position", pos, seconds).set_trans(Tween.TRANS_SINE).set_ease(Tween.EASE_IN_OUT)


## Unblockable area hit on everyone inside a box.
func _area_hit(center: Vector2, rx: float, ry: float, damage: int, kb: Vector2, move: String) -> void:
	for n in get_tree().get_nodes_in_group("fighters") + get_tree().get_nodes_in_group("helpers"):
		var f := n as Fighter
		if f == null or f.is_dead or CombatManager.are_allies(self, f):
			continue
		if absf(f.global_position.x - center.x) > rx or absf(f.global_position.y - center.y) > ry:
			continue
		var side := signf(f.global_position.x - center.x)
		if side == 0.0:
			side = float(facing)
		var h := make_hit(damage, Vector2(side * kb.x, kb.y), move)
		h.origin = center
		h.blockable = false
		h.damage_kind = HitData.KIND_EXPLOSION
		CombatManager.apply_hit(h, f)


# ----- 5. METEOR RAIN -----
func _meteor_rain(p: EnemyPattern) -> void:
	var start := global_position
	_cine_begin("METEOR RAIN", 1.3)
	pose = "meteor"
	pose_t = 0.0
	eyes_wide = true
	Engine.time_scale = 0.7
	SoundManager.play_sfx("flame")
	Effects.red_burst(self, global_position + Vector2(0, -200), 90.0)
	if not await _wait(0.7):
		_abort()
		return
	Engine.time_scale = 1.0
	_move_to(start + Vector2(0, -900), 0.5)                     # Flies up, out of sight
	ArenaCamera.focus_zoom = 0.7
	SoundManager.play_sfx("whoosh")
	if not await _wait(0.5):
		_abort()
		return
	var cut := KokusenFx.MeteorCutscene.new()
	get_tree().current_scene.add_child(cut)
	await cut.finished
	if not is_inside_tree() or is_dead:
		return
	# Back in the arena: everyone can move again - dodge it!
	global_position = start
	_cine_release()
	var fy := _ground_y()
	var tgt := _target()
	var tx := clamp_to_ground(tgt.global_position.x if tgt != null else global_position.x + facing * 300.0, 80.0)
	_cine_marker.global_position = Vector2(tx, fy - 170.0)
	ArenaCamera.focus_zoom = 0.7
	var mark := KokusenFx.Marker.new()
	mark.r = 240.0
	mark.life = 2.0
	get_parent().add_child(mark)
	mark.global_position = Vector2(tx, fy)
	# The DEBRIS falls first...
	var volley := {}
	for i in 10:
		var dx := randf_range(-460.0, 460.0)
		var d := KokusenFx.shot(self, "debris", Vector2(tx + dx, fy - 900.0 - randf_range(0.0, 400.0)), Vector2(randf_range(-60.0, 60.0), 1500.0),
			4, 24.0, 2.0, false)
		d.floor_y = fy - 10.0
		d.impact_radius = 50.0
		d.impact_damage = 4
		d.volley = volley
		d.cap = DEBRIS_CAP
	SoundManager.play_sfx("rumble")
	if not await _wait(1.3):
		_abort()
		return
	# ...then the one meteor that survived the atmosphere
	var m := KokusenFx.shot(self, "meteor", Vector2(tx, fy - 1100.0), Vector2(0, 2000.0), 0, 80.0, 2.0, true)
	m.floor_y = fy - 10.0
	m.impact_radius = 240.0
	m.impact_damage = dmg(p)
	m.unblockable = true
	SoundManager.play_sfx("whoosh")
	if not await _wait(1.4):
		_abort()
		return
	_cine_end()


# ----- 7. CLOSED WORLD -----
func _closed_world(p: EnemyPattern) -> void:
	_cine_begin("CLOSED WORLD", 1.9, Vector2(6, -190))         # Close-up on his face
	pose = "closed"
	pose_t = 0.0
	eyes_wide = true
	Engine.time_scale = 0.5
	SoundManager.play_sfx("void_goo", -2.0)
	SoundManager.play_sfx("roar", -4.0, 0.2)
	if not await _wait(1.1):
		_abort()
		return
	_cine_release()                                             # The storm can be dodged / blocked
	var center := Vector2(global_position.x, _ground_y())
	var ring := KokusenFx.FlameRing.new()
	get_parent().add_child(ring)
	ring.global_position = center
	var big_r := 760.0
	ArenaCamera.focus_zoom = 0.55
	_cine_marker.global_position = center + Vector2(0, -220.0)
	SoundManager.play_sfx("flame")
	for i in 10:
		ring.radius = big_r * float(i + 1) / 10.0
		if not await _wait(0.04):
			ring.queue_free()
			_abort()
			return
	# Slashes, flames and debris from EVERYWHERE
	var waves := 18 if enraged else 14
	var volley := {}                                            # The whole storm can hit you CLOSED_CAP times
	for w in waves:
		var tgt := _target()
		var aim := tgt.global_position + Vector2(0, -60) if tgt != null else center + Vector2(randf_range(-400.0, 400.0), -60.0)
		match w % 3:
			0:                                                  # Slashes flying in from the ring
				for k in 2:
					var a := PI + randf_range(0.15, PI - 0.15)
					var from := center + Vector2.from_angle(a) * big_r
					var to := aim + Vector2(randf_range(-80.0, 80.0), randf_range(-40.0, 40.0))
					var s := KokusenFx.shot(self, "flame_slash", from, (to - from).normalized() * 900.0, 3, 30.0, 1.6, true)
					s.knockback = Vector2(160, -120)
					s.volley = volley
					s.cap = CLOSED_CAP
			1:                                                  # Flame pillars (one right under you)
				for k in 2:
					var x := aim.x if k == 0 else center.x + randf_range(-big_r * 0.8, big_r * 0.8)
					var pl := KokusenFx.shot(self, "pillar", Vector2(clamp_to_ground(x, 40.0), center.y - 110.0), Vector2.ZERO, dmg(p), 40.0, 1.0, true)
					pl.half_h = 110.0
					pl.delay = 0.45
					pl.knockback = Vector2(120, -420)
					pl.volley = volley
					pl.cap = CLOSED_CAP
			2:                                                  # Debris raining down
				for k in 3:
					var x := center.x + randf_range(-big_r * 0.85, big_r * 0.85)
					var d := KokusenFx.shot(self, "debris", Vector2(x, center.y - 700.0 - randf_range(0.0, 200.0)), Vector2(randf_range(-40.0, 40.0), 1300.0), 3, 20.0, 1.8, false)
					d.floor_y = center.y - 10.0
					d.impact_radius = 40.0
					d.impact_damage = 3
					d.volley = volley
					d.cap = CLOSED_CAP
		Effects.shake(self, 5.0)
		if not await _wait(0.25):
			ring.queue_free()
			_abort()
			return
	# The circle closes: everything inside burns
	Engine.time_scale = 0.4
	SoundManager.play_sfx("roar")
	if not await _wait(0.3):
		ring.queue_free()
		_abort()
		return
	Engine.time_scale = 1.0
	KokusenFx.flash(self, Color(1.0, 0.45, 0.2, 0.85), 0.7)
	Effects.explosion(self, center + Vector2(0, -150), 320.0, true, true)
	Effects.shake(self, 30.0)
	SoundManager.play_sfx("explosion")
	_area_hit(center, big_r, 600.0, dmg(p) * 2, Vector2(520, -480), "closed_world")
	var tw := create_tween().set_ignore_time_scale(true)
	tw.tween_property(ring, "fade", 0.0, 0.6)
	tw.tween_callback(ring.queue_free)
	if not await _wait(0.7):
		_abort()
		return
	_cine_end()


# ============================================================
# ART (facing right, origin = feet, ~150 x 230)
# ============================================================
## Keep the cinematic pose (SimpleEnemy resets the pose to idle when no pattern runs).
func _update_visuals(delta: float) -> void:
	var keep := pose
	super._update_visuals(delta)
	if _cine:
		pose = keep


func art_state() -> Dictionary:
	var s := super.art_state()
	s["flying"] = flying
	s["eyes_wide"] = eyes_wide
	s["grabbing"] = _victim != null
	return s


func draw_model_on(c: CanvasItem) -> void:
	draw_kokusen(c, art_state())


static func draw_portrait(c: CanvasItem, t: float) -> void:
	draw_kokusen(c, {"t": t, "pose": "idle"})


static func draw_kokusen(c: CanvasItem, s: Dictionary) -> void:
	var t: float = s.get("t", 0.0)
	var pose: String = s.get("pose", "idle")
	var pt: float = s.get("pose_t", 0.0)
	var dead: bool = s.get("dead", false)
	var rage: bool = s.get("enraged", false)
	var fly: bool = s.get("flying", false)
	var wide: bool = s.get("eyes_wide", false) or pose == "closed" or pose == "closed_tele"
	var sway := sin(t * 1.8) * 3.0
	var flow := sin(t * (5.0 if fly else 2.6))

	if rage:
		EnemyArt.aura(c, Vector2(0, -115), 125.0, Color(0.8, 0.08, 0.1), t * 1.4)
	if fly:                                                     # Dark energy holding him up
		for i in 3:
			var k := fmod(t * 1.5 + float(i) / 3.0, 1.0)
			c.draw_arc(Vector2(0, 6 + k * 30.0), 30.0 + k * 40.0, PI * 1.1, PI * 1.9, 12, Color(0.75, 0.1, 0.12, 0.5 * (1.0 - k)), 4.0, true)

	# --- Hand positions per pose ---
	var near_sh := Vector2(16, -158)
	var far_sh := Vector2(-18, -156)
	var near := Vector2(36, -96 + sway)
	var far := Vector2(-34, -100 + sway)
	match pose:
		"strike_tele":
			near = Vector2(-14, -150)
		"strike":
			near = Vector2(96, -120)
		"cut_tele":
			near = Vector2(-26, -168)
		"cut":
			near = Vector2(100, -112 + sin(t * 40.0) * 18.0)
		"flame_tele":
			near = Vector2(26, -126)
			far = Vector2(14, -122)
		"flame":
			near = Vector2(88, -96)
			far = Vector2(74, -104)
		"grab_tele":
			near = Vector2(8, -138)                             # Slams his hand into his own chest
		"grab":
			near = Vector2(104, -118)
			if s.get("grabbing", false):
				near = Vector2(86, -128 + sin(t * 30.0) * 6.0)
				far = Vector2(80, -100 - sin(t * 30.0) * 6.0)
		"force_tele", "force":
			near = Vector2(82, -136)
		"meteor_tele", "meteor", "closed_tele", "closed":
			near = Vector2(46, -228)
			far = Vector2(-40, -222)
		"nofear_tele":
			near = Vector2(-20, -160)
		"nofear":
			near = Vector2(96, -126 + sin(t * 36.0) * 34.0)
			far = Vector2(70, -110 - sin(t * 36.0) * 30.0)

	# --- Far sleeve (behind the robe) ---
	_sleeve(c, far_sh, far, true, t)

	# --- The ROBE: long, flowing, widening to a wavy hem ---
	var hem_y := -2.0 if not fly else 12.0
	var robe := PackedVector2Array([Vector2(-26, -164), Vector2(28, -164), Vector2(36, -120)])
	var hem := PackedVector2Array()
	for i in 9:                                                 # Wavy hem, right to left
		var u := float(i) / 8.0
		var x := lerpf(58.0, -66.0, u) + (flow * 10.0 * u if fly else 0.0)
		hem.append(Vector2(x, hem_y + sin(t * 3.0 + u * 7.0) * (7.0 if fly else 3.0) - (10.0 * u if fly else 0.0)))
	robe.append_array(hem)
	robe.append(Vector2(-36, -118))
	c.draw_colored_polygon(robe, ROBE)
	for i in 4:                                                 # Folds
		var x := -34.0 + float(i) * 20.0
		c.draw_line(Vector2(x * 0.4, -140), Vector2(x + flow * 3.0, hem_y - 6.0), ROBE_FOLD, 4.0)
		c.draw_line(Vector2(x * 0.4 + 3.0, -140), Vector2(x + 4.0 + flow * 3.0, hem_y - 6.0), ROBE_HI, 1.5)
	c.draw_polyline(hem, TRIM, 5.0)                             # Crimson trim along the hem
	c.draw_line(Vector2(2, -150), Vector2(4 + flow * 2.0, hem_y - 4.0), TRIM, 3.0)   # Front seam
	FighterArt.outline(c, robe, 4.5)
	# Sash with a glowing crimson sigil
	c.draw_rect(Rect2(-30, -118, 64, 10), Color(0.12, 0.02, 0.04))
	c.draw_circle(Vector2(4, -113), 6.0 + 1.5 * sin(t * 5.0), Color(0.9, 0.15, 0.1, 0.8))
	c.draw_circle(Vector2(4, -113), 3.0, EYE)
	# High collar
	var collar := PackedVector2Array([Vector2(-30, -160), Vector2(-20, -192), Vector2(-6, -168), Vector2(20, -168), Vector2(32, -194), Vector2(36, -158)])
	c.draw_colored_polygon(collar, ROBE_HI)
	c.draw_polyline(PackedVector2Array([Vector2(-20, -192), Vector2(-6, -168), Vector2(20, -168), Vector2(32, -194)]), TRIM, 3.0)
	FighterArt.outline(c, collar, 3.5)

	# --- Head: dark crimson, long skull, FOUR glowing eyes, a cruel grin ---
	var head := Vector2(6, -194 + sway * 0.5)
	var skull := EnemyArt.ellipse_points(head, 22.0, 28.0, 20)
	c.draw_colored_polygon(skull, HEAD)
	c.draw_colored_polygon(EnemyArt.ellipse_points(head + Vector2(-8, 6), 12.0, 18.0, 12), HEAD_SHADE)
	c.draw_circle(head + Vector2(8, -14), 6.0, HEAD_HI)
	for k in 3:                                                 # Crown of bone spikes
		var bx := head + Vector2(-12.0 + float(k) * 12.0, -24.0)
		c.draw_colored_polygon(PackedVector2Array([bx + Vector2(-5, 2), bx + Vector2(5, 2), bx + Vector2(1, -14.0 - float(k % 2) * 6.0)]), Color(0.18, 0.02, 0.04))
	FighterArt.outline(c, skull, 4.0)
	# Deep brow ridges
	c.draw_line(head + Vector2(-6, -12), head + Vector2(22, -8), HEAD_SHADE, 4.0)
	if dead:
		for e in [Vector2(2, -6), Vector2(16, -6), Vector2(4, 4), Vector2(15, 4)]:
			EnemyArt.ko_eye(c, head + e, 2.6, t)
	else:
		var glow := 0.7 + 0.3 * sin(t * (14.0 if rage or wide else 5.0))
		var big := 1.6 if wide else 1.0
		for e: Vector3 in [Vector3(1, -6, 3.6), Vector3(16, -5, 3.6), Vector3(4, 5, 2.8), Vector3(15, 5, 2.8)]:   # 2 rows of 2
			var ep := head + Vector2(e.x, e.y)
			var r := e.z * big
			c.draw_circle(ep, r * 2.4, Color(EYE_GLOW.r, EYE_GLOW.g, EYE_GLOW.b, 0.28 * glow))
			c.draw_circle(ep, r + 1.2, Color(0.08, 0.0, 0.0))
			c.draw_circle(ep, r, Color(EYE.r, EYE.g, EYE.b, glow))
			c.draw_circle(ep, r * 0.35, Color.WHITE)
	# Wide grin full of teeth
	var mouth_open := 6.0 if pose in ["closed", "meteor", "grab", "strike"] else 3.0
	var mouth := PackedVector2Array()
	for i in 7:
		var u := float(i) / 6.0
		mouth.append(head + Vector2(-8.0 + u * 28.0, 12.0 - 1.5 * sin(u * PI) - 4.0 * absf(u - 0.5)))    # Upper lip
	for i in 7:
		var u := 1.0 - float(i) / 6.0
		mouth.append(head + Vector2(-8.0 + u * 28.0, 13.0 + (mouth_open + 1.0) * sin(u * PI) - 4.0 * absf(u - 0.5)))   # Lower lip (always below)
	c.draw_colored_polygon(mouth, Color(0.08, 0.0, 0.02))
	for i in 6:
		var x := -5.0 + float(i) * 4.6
		c.draw_colored_polygon(PackedVector2Array([head + Vector2(x, 13), head + Vector2(x + 3.4, 13), head + Vector2(x + 1.7, 16.5)]), TEETH)
	FighterArt.outline(c, mouth, 2.0)

	# --- Near sleeve (in front) + move effects ---
	_sleeve(c, near_sh, near, false, t)
	match pose:
		"grab_tele":                                            # Crimson flash where the hand hit the chest
			c.draw_circle(Vector2(8, -138), 18.0 + 8.0 * sin(t * 30.0), Color(1.0, 0.2, 0.15, 0.45))
		"cut", "strike":
			c.draw_arc(Vector2(50, -120), 70.0, -1.4, 0.9, 16, Color(1, 1, 1, maxf(0.0, 0.8 - pt * 3.0)), 6.0, true)
		"flame_tele", "flame":
			c.draw_circle(near + Vector2(8, 0), 16.0 + 5.0 * sin(t * 24.0), Color(1.0, 0.45, 0.1, 0.7))
			c.draw_circle(near + Vector2(8, 0), 8.0, Color(1.0, 0.85, 0.4, 0.9))
		"force_tele", "force":
			for i in 3:
				c.draw_arc(near + Vector2(10, 0), 14.0 + float(i) * 10.0 + 6.0 * sin(t * 20.0), 0.0, TAU, 18, Color(0.75, 0.08, 0.12, 0.7 - float(i) * 0.2), 3.0, true)
		"meteor_tele", "meteor":
			c.draw_circle(Vector2(4, -258), 26.0 + 8.0 * sin(t * 8.0), Color(1.0, 0.45, 0.1, 0.6))
			c.draw_circle(Vector2(4, -258), 14.0, Color(0.3, 0.24, 0.22))
		"nofear_tele", "nofear":
			c.draw_circle(near, 12.0, Color(1.0, 0.5, 0.1, 0.7))


## Wide black bell sleeve from the shoulder, crimson clawed hand at the end.
static func _sleeve(c: CanvasItem, sh: Vector2, hand: Vector2, far: bool, t: float) -> void:
	var col := ROBE.darkened(0.3) if far else ROBE
	var elbow := sh.lerp(hand, 0.5) + Vector2(0, 10)
	FighterArt.limb(c, sh, elbow, 15.0, col, ROBE_FOLD, ROBE_HI)
	var dir := (hand - elbow).normalized()
	var n := dir.orthogonal()
	var cuff := hand - dir * 6.0
	var bell := PackedVector2Array([elbow + n * 8.0, cuff + n * 15.0, cuff - n * 15.0, elbow - n * 8.0])
	c.draw_colored_polygon(bell, col)
	c.draw_line(cuff + n * 15.0, cuff - n * 15.0, TRIM, 3.0)
	FighterArt.outline(c, bell, 3.5)
	var hc := HEAD_SHADE if far else HEAD
	c.draw_circle(hand, 8.0, EnemyArt.BLACK)
	c.draw_circle(hand, 6.0, hc)
	for k in 3:                                                 # Claws
		var a := dir.angle() + (float(k) - 1.0) * 0.45
		var tip := hand + Vector2.from_angle(a) * (13.0 + sin(t * 3.0 + float(k)) * 1.0)
		c.draw_line(hand, tip, EnemyArt.BLACK, 5.0, true)
		c.draw_line(hand, tip, hc.lightened(0.15), 2.5, true)
