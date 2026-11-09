class_name AnimalLord
extends C5Boss
## ANIMAL LORD - BOSS 3 of Colosseum 5 (Level 42, the Stitched Den).
## A mutated corpse of many animals stitched together: a lion's body and mane, bear forearms
## with huge claws, ram horns, ragged bat wings, a scaled crocodile tail ending in a scorpion
## barb. It fights with every animal's genetics.
##
##   Claw Swipe   7 dmg x2  bear claws, two swipes
##   Bite         9 dmg     lunging lion bite
##   Wing Gust    5 dmg     the wings blast gusts of wind across the floor (they push you back)
##   Horn Charge 10 dmg     ram charge across the arena; hits the wall and is DAZED for a moment
##   Tail Whip    6 dmg     the scaled tail sweeps BEHIND and around it (low: jump it)
##   Pounce       9 dmg     leaps onto you from far away (anti-air too)
##   Feather Storm 4 dmg    ENRAGED only: takes off and rains sharp feathers
##   Primal Roar  -         ENRAGED only: stuns anyone close
## It hunts: when you jump it pounces, when you hit its back it whips its tail.

const FUR := Color(0.62, 0.46, 0.28)
const FUR_SHADE := Color(0.40, 0.28, 0.16)
const FUR_HI := Color(0.78, 0.62, 0.40)
const MANE := Color(0.36, 0.20, 0.10)
const BEAR := Color(0.30, 0.22, 0.18)
const BEAR_HI := Color(0.46, 0.36, 0.30)
const HORN := Color(0.84, 0.78, 0.62)
const WING := Color(0.22, 0.16, 0.18)
const SCALE := Color(0.30, 0.40, 0.24)
const STITCH := Color(0.12, 0.05, 0.05)
const CLAW := Color(0.95, 0.92, 0.84)

const CHARGE_SPEED := 860.0

var _air := false
var _swipes := 0
var _daze := 0.0


func boss_forms() -> Array:
	return [{"name": "Animal Lord", "title": "ANIMAL LORD   -   THE STITCHED BEAST", "hp": 520, "body": Vector2(200, 170), "speed": 240.0}]


func setup_boss() -> void:
	keep_min = 80.0
	keep_max = 260.0
	attack_chance = 0.78
	art_scale = 1.25
	chain_chance = 0.45
	tags = {"pounce": ["anti_air", "ranged", "escape"], "tail": ["counter"], "gust": ["ranged"], "charge": ["ranged"],
		"claw": ["close"], "bite": ["close"], "roar": ["counter"], "feathers": ["anti_air", "ranged"]}
	combos = {"claw": ["bite", "tail"], "bite": ["claw", "gust"], "pounce": ["claw", "roar"], "tail": ["pounce", "claw"],
		"gust": ["charge", "pounce"], "roar": ["claw", "bite"]}


static func make_patterns() -> Array[EnemyPattern]:
	var list: Array[EnemyPattern] = []
	#                          id          name               cd    dmg  min    max     anim       tele  active rec   big   weights armored
	list.append(EnemyPattern.make("claw", "CLAW SWIPE!", 2.0, 7, 0.0, 230.0, "claw", 0.40, 0.55, 0.45, true, [2.2], true))
	list.append(EnemyPattern.make("bite", "BITE!", 2.6, 9, 0.0, 300.0, "bite", 0.45, 0.30, 0.50, true, [1.8], true))
	list.append(EnemyPattern.make("gust", "WING GUST!", 4.5, 5, 150.0, 900.0, "gust", 0.55, 0.80, 0.50, true, [1.4], true))
	list.append(EnemyPattern.make("charge", "HORN CHARGE!", 5.0, 10, 250.0, 1200.0, "charge", 0.65, 1.40, 0.40, true, [1.4], true))
	list.append(EnemyPattern.make("tail", "TAIL WHIP!", 3.0, 6, 0.0, 260.0, "tail", 0.35, 0.30, 0.45, true, [1.3], true))
	list.append(EnemyPattern.make("pounce", "POUNCE!", 4.0, 9, 120.0, 800.0, "pounce", 0.40, 1.30, 0.45, true, [1.5], true))
	list.append(EnemyPattern.make("feathers", "FEATHER STORM!", 7.0, 4, 0.0, 1200.0, "feathers", 0.60, 1.20, 0.60, true, [1.2], true))
	list.append(EnemyPattern.make("roar", "PRIMAL ROAR!", 8.0, 0, 0.0, 260.0, "roar", 0.50, 0.40, 0.50, true, [0.8], true))
	list[2].note = "pushes you back"
	list[3].note = "dazed after it hits the wall: punish it"
	list[4].note = "sweeps behind it, low: jump it"
	return list


func wants_pattern(p: EnemyPattern) -> bool:
	if p.id == "feathers" or p.id == "roar":
		return raging
	return true


func flavor_lines() -> Array[String]:
	return ["*growls in many voices*", "*hisses*", "*a bird's shriek, a wolf's howl*"]


func _attack(p: EnemyPattern) -> void:
	match p.id:
		"claw":
			_swipes = 0
			_claw(p)
		"bite":
			swing(dmg(p), Vector2(420, -240), Vector2(170, -100), Vector2(150, 120), "lion_bite")
			velocity.x = facing * 520.0
			SoundManager.play_sfx("bite")
		"gust":
			for k in 3:
				shoot("wind", global_position + Vector2(facing * 120.0, -40.0 - float(k) * 60.0), float(facing), 520.0 + float(k) * 60.0,
					1.6, Vector2(60, 70), dmg(p), Vector2(520, -120), Color.WHITE, "wing_gust", true)
			SoundManager.play_sfx("whoosh")
		"charge":
			SoundManager.play_sfx("roar", -4.0)
			SoundManager.play_sfx("dash")
		"tail":
			hitbox.activate(make_hit(dmg(p), Vector2(-facing * 380.0, -360.0), "tail_whip"), Vector2(-facing * 120.0, -24.0), Vector2(300, 50))
			SoundManager.play_sfx("whoosh", -2.0)
		"pounce":
			_air = false
			leap_to(target_x(), 0.6, 240.0)
			SoundManager.play_sfx("roar", -6.0)
		"feathers":
			velocity.y = -620.0
			var tx := target_x()
			for k in 7:
				var x := tx + float(k - 3) * 90.0
				lob("arrow", global_position + Vector2(0, -220), clamp_arena(x), 0.7 + 0.08 * float(k), dmg(p), Vector2(160, -160), 30.0, Color(0.3, 0.25, 0.3), "feather_storm")
			SoundManager.play_sfx("whoosh", -2.0)
		"roar":
			stun_in_radius(global_position + Vector2(0, -80), 260.0, 0.9)
			Effects.shake(self, 14.0)
			Effects.red_burst(self, global_position + Vector2(facing * 80.0, -110.0), 160.0)
			SoundManager.play_sfx("roar")


func _claw(p: EnemyPattern) -> void:
	_swipes += 1
	pose_t = 0.0
	swing(dmg(p), Vector2(360, -220), Vector2(150, -90), Vector2(170, 150), "bear_claw")
	velocity.x = facing * 200.0
	SoundManager.play_sfx("sword_slash", -3.0)


func _on_attack_update(p: EnemyPattern, _delta: float) -> void:
	match p.id:
		"claw":
			if _swipes < 2 and state_time >= 0.3:
				_claw(p)
		"charge":
			velocity.x = facing * CHARGE_SPEED
			if not hitbox.active:
				swing(dmg(p), Vector2(560, -320), Vector2(130, -80), Vector2(130, 140), "horn_charge")
			if is_on_wall() or absf(global_position.x - clamp_arena(global_position.x, 110.0)) > 1.0:
				velocity.x = -facing * 200.0
				Effects.shake(self, 16.0)
				Effects.hit_sparks(self, global_position + Vector2(facing * 140.0, -90.0), 12, 1.5)
				SoundManager.play_sfx("slam")
				SoundManager.play_sfx("stone", -2.0)
				_daze = 1.2                                  # Rams the wall: dazed
				stun_timer = 1.2
				state_time = state_len
		"pounce":
			if not is_on_floor():
				_air = true
			elif _air:
				_air = false
				hit_in_radius(global_position + Vector2(facing * 60.0, -60.0), 150.0, dmg(p), Vector2(380, -320), "pounce")
				Effects.shake(self, 10.0)
				SoundManager.play_sfx("slam", -2.0)
				velocity.x = 0.0
				state_time = state_len


func _on_attack_end(p: EnemyPattern) -> void:
	if p.id in ["bite", "charge", "pounce"]:
		velocity.x = 0.0


func _owns_velocity_x() -> bool:
	return estate == EState.ATTACK and current != null and current.id in ["charge", "pounce", "bite"]


func _update_visuals(delta: float) -> void:
	_daze = maxf(_daze - delta, 0.0)
	super._update_visuals(delta)


# ============================================================
# ART (facing right, origin = feet, ~240 x 200 art units)
# ============================================================
func draw_model_on(c: CanvasItem) -> void:
	var s := art_state()
	s["daze"] = _daze
	draw_lord(c, s)


static func draw_portrait(c: CanvasItem, t: float) -> void:
	draw_lord(c, {"t": t, "pose": "idle"})


static func draw_lord(c: CanvasItem, s: Dictionary) -> void:
	var t: float = s.get("t", 0.0)
	var pose: String = s.get("pose", "idle")
	var pt: float = s.get("pose_t", 0.0)
	var dead: bool = s.get("dead", false)
	var breathe := sin(t * 2.0) * 2.0
	var body_c := Vector2(-10, -96 + breathe)
	# Ragged bat wings (spread wide for the gust / feathers)
	var spread := 1.0 + (0.6 if pose.begins_with("gust") or pose.begins_with("feathers") else 0.0) + sin(t * 3.0) * 0.08
	for k in 2:
		var base := body_c + Vector2(-10.0 + float(k) * 16.0, -40.0)
		var wing := PackedVector2Array([base, base + Vector2(-90, -90) * spread, base + Vector2(-60, -40) * spread, base + Vector2(-120, -30) * spread,
			base + Vector2(-70, -10) * spread, base + Vector2(-100, 20) * spread, base + Vector2(-30, 6)])
		c.draw_colored_polygon(wing, WING if k == 0 else WING.lightened(0.1))
		for j in range(1, 6, 2):
			c.draw_line(base, wing[j], Color(0.1, 0.07, 0.08), 3.0)
		FighterArt.outline(c, wing, 3.0)
	# Crocodile tail with a scorpion barb
	var swing_k := 0.0
	if pose == "tail":
		swing_k = 1.0
	var tail := PackedVector2Array()
	for i in 10:
		var u := float(i) / 9.0
		var y := -40.0 - sin(u * PI) * 40.0 * (1.0 - swing_k) + u * 30.0 * swing_k
		tail.append(body_c + Vector2(-80.0 - u * (110.0 + 60.0 * swing_k), y + 40.0 + sin(t * 3.0 + u * 4.0) * 6.0))
	c.draw_polyline(tail, EnemyArt.BLACK, 24.0, true)
	c.draw_polyline(tail, SCALE, 18.0, true)
	for i in range(1, 9):
		c.draw_circle(tail[i] + Vector2(0, -6), 3.0, SCALE.lightened(0.2))
	FighterArt.curved_spike(c, tail[9], tail[9] + Vector2(-10, -36), 8.0, Color(0.2, 0.18, 0.16), Color(0.6, 0.1, 0.1), 0.5, 2.5)
	# Back legs (lion) + front legs (bear)
	for i in 2:
		var hip := body_c + Vector2(-60.0 + float(i) * 8.0, 30.0)
		var walk := sin(float(s.get("walk", 0.0)) + float(i) * PI) * (14.0 if s.get("moving", false) else 0.0)
		FighterArt.limb(c, hip, Vector2(hip.x + walk - 10.0, -30), 20.0, FUR_SHADE if i == 0 else FUR, FUR_SHADE, FUR_HI)
		FighterArt.limb(c, Vector2(hip.x + walk - 10.0, -30), Vector2(hip.x + walk, -4), 16.0, FUR_SHADE if i == 0 else FUR, FUR_SHADE, FUR_HI)
	# Lion body with stitched seams
	var body := EnemyArt.ellipse_points(body_c, 96.0, 52.0, 24)
	c.draw_colored_polygon(body, FUR)
	c.draw_colored_polygon(EnemyArt.ellipse_points(body_c + Vector2(-10, 20), 80.0, 26.0, 18), FUR_SHADE)
	FighterArt.outline(c, body, 5.0)
	for seam in [[Vector2(-40, -40), Vector2(-20, 40)], [Vector2(30, -46), Vector2(40, 30)]]:
		var a: Vector2 = body_c + seam[0]
		var b: Vector2 = body_c + seam[1]
		c.draw_line(a, b, STITCH, 3.0)
		for k in 6:
			var m := a.lerp(b, float(k) / 5.0)
			c.draw_line(m + Vector2(-5, -2), m + Vector2(5, 2), STITCH, 2.0)
	# Bear forearm + claws (front)
	var paw := body_c + Vector2(90, 90)
	match pose:
		"claw_tele":
			paw = body_c + Vector2(60, -60)
		"claw":
			paw = body_c + Vector2(160 - fmod(pt * 6.0, 1.0) * 40.0, 30)
		"pounce":
			paw = body_c + Vector2(150, 40)
	FighterArt.limb(c, body_c + Vector2(60, 10), paw, 26.0, BEAR, BEAR.darkened(0.3), BEAR_HI)
	for k in 4:
		FighterArt.curved_spike(c, paw + Vector2(6, -10.0 + float(k) * 7.0), paw + Vector2(36, -16.0 + float(k) * 12.0), 4.0, CLAW, Color.WHITE, 0.3, 2.0)
	if pose == "claw":
		c.draw_arc(paw + Vector2(-20, 0), 90.0, -1.0, 1.0, 12, Color(1, 1, 1, 0.5), 5.0, true)
	# Head: lion mane, ram horns, wolf snout
	var head := body_c + Vector2(100, -40)
	var bite_open := 0.0
	if pose == "bite":
		head += Vector2(40, 10)
		bite_open = 1.0
	elif pose == "charge":
		head += Vector2(20, 24)
	for i in 14:
		var a := TAU * float(i) / 14.0
		c.draw_circle(head + Vector2.from_angle(a) * 40.0, 18.0, MANE)
	FighterArt.ball(c, head, 34.0, FUR, FUR_SHADE, FUR_HI)
	for sgn: float in [-1.0, 1.0]:                                     # Curled ram horns
		var hb := head + Vector2(sgn * 6.0 - 6.0, -26)
		var curl := PackedVector2Array()
		for i in 9:
			var a := -PI * 0.5 + float(i) * 0.6
			curl.append(hb + Vector2(cos(a) * (26.0 - float(i) * 2.0) * -1.0 - 6.0, sin(a) * (26.0 - float(i) * 2.0)))
		c.draw_polyline(curl, EnemyArt.BLACK, 14.0, true)
		c.draw_polyline(curl, HORN, 9.0, true)
	var snout := PackedVector2Array([head + Vector2(16, -8), head + Vector2(56, 0), head + Vector2(54, 14 + bite_open * 10.0), head + Vector2(16, 18)])
	c.draw_colored_polygon(snout, FUR_HI)
	FighterArt.outline(c, snout, 3.0)
	c.draw_circle(head + Vector2(54, 2), 5.0, EnemyArt.BLACK)
	for k in 4:                                                    # Fangs
		c.draw_colored_polygon(PackedVector2Array([head + Vector2(24.0 + float(k) * 8.0, 14), head + Vector2(30.0 + float(k) * 8.0, 14), head + Vector2(27.0 + float(k) * 8.0, 24.0 + bite_open * 6.0)]), CLAW)
	var daze: float = s.get("daze", 0.0)
	if dead:
		EnemyArt.ko_eye(c, head + Vector2(18, -12), 5.0, t)
	elif daze > 0.0:
		for i in 3:
			EnemyArt.star(c, head + Vector2.from_angle(t * 6.0 + float(i) * 2.1) * Vector2(40, 12) + Vector2(0, -60), 7.0, Color(1, 0.9, 0.3), 1.5)
	else:
		c.draw_circle(head + Vector2(18, -12), 7.0, Color(1.0, 0.85, 0.2))
		c.draw_circle(head + Vector2(20, -12), 3.0, EnemyArt.BLACK)
		c.draw_circle(head + Vector2(-2, -14), 5.0, Color(0.6, 0.9, 1.0))     # A different animal's eye
		c.draw_circle(head + Vector2(-1, -14), 2.0, EnemyArt.BLACK)
