class_name XX0XN
extends SimpleEnemy
## THE XX0XN (Madness, level 20 boss): a BIGGER Weird Creature - ROT over its whole body, a
## SINISTER GRIN, and a CHAINSAW. More agile than the small ones.
##
## PHASE 1 (chainsaw + basic melee)
##   Saw Slash    9 dmg, 1.2 s - a wide chainsaw swing
##   Punch        6 dmg, 0.8 s - a quick jab with its little floating fist
##   Saw Charge  12 dmg, 4.0 s - revs up, then charges across the arena saw first
## PHASE 2 - ENGAGED (not enraged!): it takes off and FLIES around the arena with TWO chainsaws
##   Dive        12 dmg, 2.2 s - swoops down at you from the air - then he is STUCK on the ground 1.4 s
##   Twin Spin   10 dmg, 3.5 s - both saws spinning around it
## Beating it: achievement "MadMan of the Dance Party" + the ASSASSIN Story skin (Madness.complete()).

const K := 1.9                                     # Size versus a Weird Creature
const FLY_H := 130.0                             # Low enough for a jumping attack
const STUCK_TIME := 1.4                          # After a Dive the saws bite into the ground: hit him NOW
const ROT := Color(0.40, 0.46, 0.20)
const SAW := Color(0.72, 0.74, 0.78)
const SAW_DARK := Color(0.30, 0.30, 0.33)
const GRIN := Color(0.95, 0.92, 0.85)

var _floor := INF
var _dive_from := Vector2.ZERO
var _dive_to := Vector2.ZERO
var _stuck := 0.0


func _make_data() -> CharacterData:
	keep_min = 60.0
	keep_max = 220.0
	attack_chance = 0.85
	phase2_threshold = 0.5
	rage_word = "ENGAGED"
	var d := SimpleEnemy.make_data("The XX0XN", 380, Vector2(84, 176), 470.0)
	d.acceleration = 3600.0
	d.deceleration = 3600.0
	d.jump_force = 820.0
	return d


static func make_patterns() -> Array[EnemyPattern]:
	var list: Array[EnemyPattern] = []
	#                          id           name           cd   dmg  min    max    anim     tele  active rec   big   weights [P1, P2]
	list.append(EnemyPattern.make("saw_slash", "SAW SLASH!", 1.2, 9, 0.0, 170.0, "slash", 0.35, 0.25, 0.35, true, [3.0, 0.0]))
	list.append(EnemyPattern.make("punch", "PUNCH", 0.8, 6, 0.0, 110.0, "punch", 0.14, 0.12, 0.25, false, [2.0, 0.0]))
	list.append(EnemyPattern.make("saw_charge", "SAW CHARGE!", 4.0, 12, 160.0, 700.0, "charge", 0.6, 0.7, 0.5, true, [1.6, 0.0], true))
	list.append(EnemyPattern.make("dive", "DIVE!", 2.2, 12, 0.0, 900.0, "dive", 0.45, 0.55, 0.45, true, [0.0, 3.0], true))
	list.append(EnemyPattern.make("twin_spin", "TWIN SPIN!", 3.5, 10, 0.0, 200.0, "spin", 0.4, 0.6, 0.4, true, [0.0, 2.0], true))
	return list


func wants_pattern(p: EnemyPattern) -> bool:
	return p.weight(phase) > 0.0


func _on_phase_changed(_new_phase: int) -> void:
	SoundManager.play_sfx("roar")
	Effects.shake(self, 14.0)
	Effects.popup(self, global_position + Vector2(0, -260), "ENGAGED", Color(1.0, 0.2, 0.15), 34)


func jump(force_mult: float = 1.0) -> void:
	if not enraged:
		super.jump(force_mult)


## ENGAGED: it flies - hovering high, darting after you.
func _movement(delta: float) -> void:
	if _floor == INF and is_on_floor():
		_floor = global_position.y
	if _stuck > 0.0:
		_stuck -= delta                                   # Saws stuck in the ground: he can't fly
		velocity.x = 0.0
		velocity.y = minf(velocity.y + data.gravity * delta, data.max_fall_speed)
		return
	if not enraged or _floor == INF:
		super._movement(delta)
		return
	if estate == EState.ATTACK and current != null and current.id == "dive":
		return                                           # The dive moves it itself
	var goal_y := _floor - FLY_H + sin(anim_time * 2.6) * 30.0
	velocity.y = (goal_y - global_position.y) * 6.0
	var tx := target_x() + sin(anim_time * 1.3) * 160.0
	velocity.x = move_toward(velocity.x, clampf((tx - global_position.x) * 3.0, -620.0, 620.0), 2600.0 * delta)
	facing = 1 if target_x() > global_position.x else -1


func _attack(p: EnemyPattern) -> void:
	match p.id:
		"saw_slash":
			hitbox.activate(make_hit(dmg(p), Vector2(facing * 380.0, -220.0), "xx0xn_saw"), Vector2(facing * 80.0, -100.0), Vector2(120, 110))
			SoundManager.play_sfx("drill", -4.0)
		"punch":
			hitbox.activate(make_hit(dmg(p), Vector2(facing * 220.0, -120.0), "xx0xn_punch"), Vector2(facing * 70.0, -110.0), Vector2(60, 50))
			SoundManager.play_sfx("punch", -4.0)
		"saw_charge":
			SoundManager.play_sfx("drill")
			hitbox.activate(make_hit(dmg(p), Vector2(facing * 480.0, -260.0), "xx0xn_charge"), Vector2(facing * 50.0, -90.0), Vector2(130, 150))
		"dive":
			_dive_from = global_position
			_dive_to = Vector2(target_x(), (_floor if _floor != INF else global_position.y) - 10.0)
			hitbox.activate(make_hit(dmg(p), Vector2(facing * 360.0, -300.0), "xx0xn_dive"), Vector2(0, -90.0), Vector2(130, 150))
			SoundManager.play_sfx("whoosh")
		"twin_spin":
			hit_in_radius(global_position + Vector2(0, -90), 190.0, dmg(p), Vector2(420, -260), "xx0xn_spin")
			SoundManager.play_sfx("drill")
			Effects.shake(self, 8.0)


func _on_attack_update(p: EnemyPattern, delta: float) -> void:
	match p.id:
		"saw_charge":
			velocity.x = facing * 900.0
			if not ground_ahead(80.0):
				state_time = state_len
		"dive":
			var k := clampf(state_time / maxf(state_len, 0.01), 0.0, 1.0)
			global_position = _dive_from.lerp(_dive_to, k * k)
			velocity = Vector2.ZERO
			if k >= 1.0:
				Effects.shake(self, 10.0)
		"twin_spin":
			if fmod(state_time, 0.2) < delta:
				hit_in_radius(global_position + Vector2(0, -90), 190.0, maxi(1, floori(dmg(p) / 4.0)), Vector2(260, -160), "xx0xn_spin")


func _on_attack_end(p: EnemyPattern) -> void:
	if p.id == "dive":
		_stuck = STUCK_TIME
		Effects.popup(self, global_position + Vector2(0, -220), "STUCK!", Color(1.0, 0.85, 0.3), 24)
		Effects.shake(self, 10.0)


func can_act() -> bool:
	return super.can_act() and _stuck <= 0.0


func _owns_velocity_x() -> bool:
	return estate == EState.ATTACK and current != null and (current.id == "saw_charge" or current.id == "dive")


func flavor_lines() -> Array[String]:
	return ["*the chainsaw idles*", "hehehehe", "DANCE WITH ME"]


# ============================================================
# ART (facing right, origin = feet, ~160 x 200)
# ============================================================
func draw_model_on(c: CanvasItem) -> void:
	var s := art_state()
	s["engaged"] = enraged
	draw_boss(c, s)


static func draw_portrait(c: CanvasItem, t: float) -> void:
	draw_boss(c, {"t": t, "pose": "idle"})


const PORTRAIT_H := 220.0


static func draw_boss(c: CanvasItem, s: Dictionary) -> void:
	var t: float = s.get("t", 0.0)
	var pose_v: String = s.get("pose", "idle")
	var engaged: bool = s.get("engaged", false)
	var dead: bool = s.get("dead", false)
	WeirdCreature.draw_creature(c, s, K, true)
	var torso_c := Vector2(0, -56.0) * K
	# ROT: green-brown blotches over the whole body
	for i in 7:
		var rp := torso_c + Vector2(sin(float(i) * 2.3) * 18.0, -20.0 + float(i) * 8.0) * K
		c.draw_colored_polygon(EnemyArt.ellipse_points(rp, (5.0 + float(i % 3) * 2.0) * K, 4.0 * K, 10), Color(ROT.r, ROT.g, ROT.b, 0.85))
	# The SINISTER GRIN across the skull
	var hc := torso_c + Vector2(4, -42) * K + Vector2(0, sin(t * 3.0) * 2.0)
	if not dead:
		var grin := PackedVector2Array()
		for i in 9:
			var a := 0.15 + PI * 0.7 * float(i) / 8.0
			grin.append(hc + Vector2(cos(a) * 12.0, 4.0 + sin(a) * 6.0) * K)
		c.draw_polyline(grin, EnemyArt.BLACK, 5.0)
		c.draw_polyline(grin, GRIN, 2.5)
		for i in 6:
			var gx := hc.x + (-8.0 + float(i) * 3.4) * K
			c.draw_line(Vector2(gx, hc.y + 5.0 * K), Vector2(gx, hc.y + 9.0 * K), EnemyArt.BLACK, 1.5)
	# The CHAINSAW (two when ENGAGED)
	var swing := 0.0
	match pose_v:
		"slash_tele":
			swing = -1.0
		"slash":
			swing = 1.0
		"charge", "charge_tele":
			swing = 0.3
	_chainsaw(c, torso_c + Vector2(44, -6) * K, lerpf(-0.4, 0.9, (swing + 1.0) * 0.5) + (t * 14.0 if pose_v == "spin" else 0.0), t)
	if engaged:
		_chainsaw(c, torso_c + Vector2(-40, -6) * K, PI + 0.4 - (t * 14.0 if pose_v == "spin" else 0.0), t)
		for side: float in [-1.0, 1.0]:                                     # Ragged wings of flesh: it flies
			var wb := torso_c + Vector2(side * 14.0, -18.0) * K
			c.draw_colored_polygon(PackedVector2Array([wb, wb + Vector2(side * 70.0, -50.0 + sin(t * 12.0) * 14.0) * K, wb + Vector2(side * 50.0, 10.0) * K]), Color(0.3, 0.12, 0.12, 0.85))


static func _chainsaw(c: CanvasItem, grip: Vector2, ang: float, t: float) -> void:
	var d := Vector2.from_angle(ang)
	var n := d.orthogonal()
	var body := PackedVector2Array([grip - n * 12.0, grip + n * 12.0, grip + n * 12.0 + d * 30.0, grip - n * 12.0 + d * 30.0])
	c.draw_colored_polygon(body, Color(0.55, 0.12, 0.10))
	FighterArt.outline(c, body, 3.0)
	var b0 := grip + d * 30.0
	var b1 := grip + d * 120.0
	var blade := PackedVector2Array([b0 - n * 9.0, b1 - n * 7.0, b1 + d * 8.0, b1 + n * 7.0, b0 + n * 9.0])
	c.draw_colored_polygon(blade, SAW)
	FighterArt.outline(c, blade, 3.0)
	var off := fmod(t * 160.0, 10.0)                                             # Running teeth
	for i in 9:
		var p := b0 + d * (float(i) * 10.0 + off)
		c.draw_colored_polygon(PackedVector2Array([p - n * 9.0, p - n * 14.0 + d * 3.0, p - n * 9.0 + d * 6.0]), SAW_DARK)
		c.draw_colored_polygon(PackedVector2Array([p + n * 9.0, p + n * 14.0 + d * 3.0, p + n * 9.0 + d * 6.0]), SAW_DARK)
