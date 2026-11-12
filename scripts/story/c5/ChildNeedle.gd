class_name ChildNeedle
extends C5Boss
## CHILD WIELDING NEEDLE - BOSS 1 of Colosseum 5 (Level 36, the Silk Loom).
## A small, fast child in a long plum coat, a cracked porcelain face with a stitched smile,
## braids of silver silk, and a NEEDLE twice her size trailing silk thread. She darts in and
## out, never stands still, and punishes every jump and every wild swing.
##
##   Silk Spear       7 dmg   a fast long thrust of the needle
##   Lunge            8 dmg   shoots across the arena needle-first
##   Silk Tornado     4 dmg x  spins in place: a tornado of silk hits again and again
##   Needle Combo     5 dmg x3 three quick slashes stepping forward
##   Needle Throw     6 dmg   throws the needle on its thread (it flies out and comes BACK)
##   Silk Dive        8 dmg   leaps up and dives down at you (anti-air, escapes corners)
##   Backstep         -        hops away when you swing at her
##   Silk Trap        6 dmg   ENRAGED only: silk spikes stab up out of the floor under you
## Combos: Thrust -> Combo / Backstep, Backstep -> Throw / Lunge / Dive, Combo -> Lunge / Tornado...

const COAT := Color(0.34, 0.16, 0.36)
const COAT_SHADE := Color(0.20, 0.08, 0.22)
const COAT_HI := Color(0.52, 0.28, 0.54)
const PORCELAIN := Color(0.96, 0.94, 0.90)
const PORCELAIN_SHADE := Color(0.78, 0.75, 0.72)
const SILK := Color(0.86, 0.88, 0.95)
const NEEDLE := Color(0.82, 0.84, 0.90)
const STITCH := Color(0.55, 0.10, 0.14)

const LUNGE_SPEED := 980.0
## VOICE LINES: pattern -> [recording key in res://audio/voice/, text]. With no recording the
## system text-to-speech says it in a high child's voice; the line always pops up on screen.
const VOICE := {"thrust": ["needle_shaw", "Shaw!"], "combo": ["needle_shaw", "Shaw!"], "lunge": ["needle_adino", "Adino!"],
	"dive": ["needle_adino", "Adino!"], "tornado": ["needle_guarana", "Guarana!"], "throw": ["needle_shaw", "Shaw!"]}
const GET_GOOD := ["needle_getgood", "Get Good"]

var _voice_cd := 0.0

var _dive_air := false
var _hits := 0
var _spin_t := 0.0
var _needle_out := false


func boss_forms() -> Array:
	return [{"name": "Child Wielding Needle", "title": "CHILD WIELDING NEEDLE", "hp": 380, "body": Vector2(56, 118), "speed": 330.0}]


func setup_boss() -> void:
	keep_min = 140.0
	keep_max = 300.0
	attack_chance = 0.8
	art_scale = 1.15
	chain_chance = 0.5
	tags = {"dive": ["anti_air", "escape"], "tornado": ["counter", "anti_air"], "backstep": ["evade"],
		"throw": ["ranged"], "lunge": ["ranged", "close"], "combo": ["close"], "thrust": ["close"]}
	combos = {"thrust": ["combo", "backstep"], "combo": ["lunge", "tornado"], "backstep": ["throw", "lunge", "dive"],
		"dive": ["tornado", "combo"], "lunge": ["thrust", "tornado"], "throw": ["lunge"], "trap": ["dive"]}


static func make_patterns() -> Array[EnemyPattern]:
	var list: Array[EnemyPattern] = []
	#                          id          name              cd    dmg  min    max    anim        tele  active rec   big    weights  armored
	list.append(EnemyPattern.make("thrust", "SILK SPEAR!", 1.6, 7, 0.0, 230.0, "thrust", 0.30, 0.16, 0.35, true, [2.2], false))
	list.append(EnemyPattern.make("lunge", "LUNGE!", 3.0, 8, 160.0, 900.0, "lunge", 0.40, 0.55, 0.40, true, [1.8], true))
	list.append(EnemyPattern.make("tornado", "SILK TORNADO!", 5.0, 4, 0.0, 200.0, "tornado", 0.45, 1.10, 0.50, true, [1.4], true))
	list.append(EnemyPattern.make("combo", "NEEDLE COMBO!", 2.6, 5, 0.0, 150.0, "combo", 0.28, 0.75, 0.40, true, [2.0], false))
	list.append(EnemyPattern.make("throw", "NEEDLE THROW!", 3.6, 6, 220.0, 900.0, "throw", 0.40, 1.10, 0.30, true, [1.6], false))
	list.append(EnemyPattern.make("dive", "SILK DIVE!", 4.2, 8, 0.0, 700.0, "dive", 0.30, 1.40, 0.40, true, [1.2], true))
	list.append(EnemyPattern.make("backstep", "BACKSTEP", 2.4, 0, 0.0, 160.0, "backstep", 0.05, 0.30, 0.10, false, [0.6], false))
	list.append(EnemyPattern.make("trap", "SILK TRAP!", 6.5, 6, 0.0, 1200.0, "trap", 0.50, 0.30, 0.40, true, [1.4], false))
	list[2].note = "spins: stay out until it stops"
	list[4].note = "the needle comes back on its thread"
	list[7].note = "enraged only: silk spikes under you"
	return list


func wants_pattern(p: EnemyPattern) -> bool:
	return p.id != "trap" or raging


func flavor_lines() -> Array[String]:
	return ["Will you play with me?", "*giggles*", "Get Good", "Stay STILL!"]


func _voice(line: Array, force: bool = false) -> void:
	if _voice_cd > 0.0 and not force:
		return
	_voice_cd = 1.6
	SoundManager.say(String(line[0]), String(line[1]), 1.8, 1.25)
	Effects.popup(self, global_position + Vector2(0, -data.body_size.y * art_scale - 50.0), String(line[1]), Color(0.95, 0.85, 1.0), 26)


## She taunts you when she lands a hit (always when it knocks you out).
func _on_hit_landed(victim: Fighter, _hit: HitData, result: String) -> void:
	if result != "hit" or victim == null:
		return
	if victim.is_dead:
		_voice(GET_GOOD, true)
	elif randf() < 0.3:
		_voice(GET_GOOD)


func _update_visuals(delta: float) -> void:
	_voice_cd -= delta
	super._update_visuals(delta)


func _attack(p: EnemyPattern) -> void:
	_hits = 0
	if VOICE.has(p.id) and randf() < 0.75:
		_voice(VOICE[p.id])
	match p.id:
		"thrust":
			swing(dmg(p), Vector2(380, -180), Vector2(120, -62), Vector2(220, 40), "silk_spear")
			velocity.x = facing * 240.0
			SoundManager.play_sfx("sword_slash", -3.0)
		"lunge":
			swing(dmg(p), Vector2(420, -200), Vector2(70, -60), Vector2(150, 60), "needle_lunge")
			SoundManager.play_sfx("dash")
			Effects.trail(self, Color(SILK.r, SILK.g, SILK.b, 0.7), 10.0, 12)
		"tornado":
			_spin_t = 0.0
			SoundManager.play_sfx("whoosh")
		"combo":
			_combo_hit(p)
		"throw":
			_needle_out = true
			var n := spawn_projectile()
			n.kind = EnemyProjectile.Kind.BOOMERANG
			n.look = "needle"
			n.tint = SILK
			n.dir = float(facing)
			n.speed = 860.0
			n.range_px = clampf(absf(target_x() - global_position.x) + 120.0, 260.0, 720.0)
			n.lifetime = 2.6
			n.size = Vector2(70, 26)
			n.damage = dmg(p)
			n.knockback = Vector2(260, -180)
			n.move = "needle_throw"
			launch(n, global_position + Vector2(facing * 40.0, -66.0))
			SoundManager.play_sfx("whoosh", -2.0)
		"dive":
			_dive_air = false
			var tx := clamp_arena(target_x())
			velocity = Vector2((tx - global_position.x) * 0.9, -980.0)
			SoundManager.play_sfx("jump")
		"backstep":
			velocity = Vector2(-facing * 520.0, -380.0)
			SoundManager.play_sfx("dash", -6.0)
		"trap":
			var tx := target_x()
			for k in 3:
				hazard("silk", tx + float(k - 1) * 150.0, 0.6 + 0.15 * float(k), dmg(p), Vector2(200, -460))
			SoundManager.play_sfx("whoosh", -4.0)


func _combo_hit(p: EnemyPattern) -> void:
	_hits += 1
	pose_t = 0.0
	swing(dmg(p), Vector2(240 + 60 * _hits, -150), Vector2(64, -60), Vector2(120, 90), "needle_combo")
	velocity.x = facing * 260.0
	SoundManager.play_sfx("sword_slash", -4.0)


func _on_attack_update(p: EnemyPattern, delta: float) -> void:
	match p.id:
		"lunge":
			velocity.x = facing * LUNGE_SPEED
			if is_on_wall() or absf(global_position.x - clamp_arena(global_position.x, 80.0)) > 1.0:
				state_time = state_len
		"tornado":
			_spin_t -= delta
			velocity.x = facing * 90.0
			if _spin_t <= 0.0:
				_spin_t = 0.22
				hitbox.activate(make_hit(dmg(p), Vector2(facing * 180.0, -260.0), "silk_tornado"), Vector2(0, -70), Vector2(240, 170))
				SoundManager.play_sfx("swing", -8.0)
		"combo":
			if _hits < 3 and state_time >= float(_hits) * 0.25:
				_combo_hit(p)
		"dive":
			if not is_on_floor():
				_dive_air = true
				if velocity.y > -100.0 and velocity.y < 400.0:
					velocity = Vector2((target_x() - global_position.x) * 2.2, 1400.0)   # Dives at you
					swing(dmg(p), Vector2(300, -320), Vector2(0, -40), Vector2(120, 100), "silk_dive")
			elif _dive_air:
				hit_in_radius(global_position + Vector2(0, -30), 120.0, dmg(p), Vector2(320, -300), "silk_dive")
				hazard("silk", global_position.x - 90.0, 0.05, 3, Vector2(160, -380))
				hazard("silk", global_position.x + 90.0, 0.05, 3, Vector2(160, -380))
				Effects.shake(self, 7.0)
				state_time = state_len


func _on_attack_end(p: EnemyPattern) -> void:
	if p.id == "lunge" or p.id == "dive" or p.id == "tornado":
		velocity.x = 0.0


func _owns_velocity_x() -> bool:
	return estate == EState.ATTACK and current != null and current.id in ["lunge", "dive", "backstep", "tornado"]


func on_projectile_returned(_look: String) -> void:
	_needle_out = false


# ============================================================
# ART (facing right, origin = feet, ~70 x 130 art units)
# ============================================================
func draw_model_on(c: CanvasItem) -> void:
	var s := art_state()
	s["needle_out"] = _needle_out
	draw_child(c, s)


static func draw_portrait(c: CanvasItem, t: float) -> void:
	draw_child(c, {"t": t, "pose": "idle"})


static func draw_child(c: CanvasItem, s: Dictionary) -> void:
	var t: float = s.get("t", 0.0)
	var pose_v: String = s.get("pose", "idle")
	var pt: float = s.get("pose_t", 0.0)
	var dead: bool = s.get("dead", false)
	var spin := pose_v == "tornado"
	if spin:                                               # Silk tornado around her
		for i in 6:
			var r := 50.0 + float(i) * 12.0
			var a0 := t * 18.0 + float(i)
			c.draw_set_transform(Vector2(0, -60.0 - float(i) * 8.0), 0.0, Vector2(1.0, 0.35))
			c.draw_arc(Vector2.ZERO, r, a0, a0 + 4.2, 18, Color(SILK.r, SILK.g, SILK.b, 0.65), 4.0, FighterArt.AA)
		c.draw_set_transform(Vector2.ZERO, 0.0, Vector2.ONE)
	EnemyArt.legs(c, s, -40.0, 7.0, 7.0, COAT_SHADE, COAT_SHADE.darkened(0.2), COAT, Color(0.15, 0.1, 0.12), 12.0)
	var lean := 0.0
	if pose_v in ["thrust", "lunge", "combo"]:
		lean = 10.0
	var chest := Vector2(lean * 0.5, -74 + sin(t * 4.0) * 1.5)
	# Long coat with a flared, ragged hem
	var hem := []
	for i in 6:
		hem.append(chest + Vector2(-26.0 + float(i) * 10.0, 38.0 + (6.0 if i % 2 == 0 else 0.0) + sin(t * 5.0 + float(i)) * 3.0))
	var coat := PackedVector2Array([chest + Vector2(-14, -20), chest + Vector2(14, -20)])
	coat.append(chest + Vector2(28, 36))
	for i in range(hem.size() - 1, -1, -1):
		coat.append(hem[i])
	coat.append(chest + Vector2(-30, 34))
	c.draw_colored_polygon(coat, COAT)
	c.draw_colored_polygon(PackedVector2Array([chest + Vector2(-4, -18), chest + Vector2(4, -18), chest + Vector2(6, 38), chest + Vector2(-6, 38)]), COAT_SHADE)
	FighterArt.outline(c, coat, 3.5)
	for k in 3:                                            # Buttons
		c.draw_circle(chest + Vector2(8, -8.0 + float(k) * 12.0), 2.5, SILK)
	# The NEEDLE (unless it was thrown)
	var hand := chest + Vector2(18, 6)
	var ang := -1.25
	match pose_v:
		"thrust_tele", "lunge_tele":
			hand = chest + Vector2(-12, 0)
			ang = 0.0
		"thrust", "lunge":
			hand = chest + Vector2(34, -2)
			ang = 0.0
		"combo":
			hand = chest + Vector2(28, -4)
			ang = -1.6 + fmod(pt * 9.0, 2.6)
		"tornado":
			hand = chest + Vector2(22, -6)
			ang = t * 20.0
		"dive":
			hand = chest + Vector2(10, 18)
			ang = 1.2
		"throw_tele":
			hand = chest + Vector2(-10, -30)
			ang = -0.4
	if not bool(s.get("needle_out", false)):
		var d := Vector2.from_angle(ang)
		var tip := hand + d * 120.0
		var eye := hand - d * 26.0
		c.draw_line(eye, tip, EnemyArt.BLACK, 7.0, FighterArt.AA)
		c.draw_line(eye, tip, NEEDLE, 3.5, FighterArt.AA)
		c.draw_line(hand, hand + d * 100.0, Color(1, 1, 1, 0.7), 1.2, FighterArt.AA)
		c.draw_arc(eye, 5.0, 0.0, TAU, 10, NEEDLE, 2.5)
		var thread := PackedVector2Array()                 # Silk thread from the eye
		for i in 8:
			var u := float(i) / 7.0
			thread.append(eye + Vector2(-u * 60.0, u * 40.0 + sin(u * 6.0 + t * 4.0) * 8.0))
		c.draw_polyline(thread, Color(SILK.r, SILK.g, SILK.b, 0.8), 1.8, FighterArt.AA)
	EnemyArt.arm(c, chest + Vector2(6, -14), hand, 6.0, COAT, COAT_SHADE, COAT_HI, PORCELAIN, 4.5)
	# Head: silver silk braids, porcelain face with button eyes and a stitched smile
	var head := chest + Vector2(4, -34)
	for sgn: float in [-1.0, 1.0]:
		var braid := PackedVector2Array()
		for i in 6:
			var u := float(i) / 5.0
			braid.append(head + Vector2(-6.0 + sgn * 12.0 - u * 6.0, 4.0 + u * 34.0 + sin(t * 3.0 + u * 3.0) * 2.0))
		c.draw_polyline(braid, EnemyArt.BLACK, 8.0, FighterArt.AA)
		c.draw_polyline(braid, SILK, 5.0, FighterArt.AA)
	FighterArt.ball(c, head, 17.0, PORCELAIN, PORCELAIN_SHADE, Color.WHITE)
	c.draw_line(head + Vector2(-10, -14), head + Vector2(-2, -2), Color(0.4, 0.38, 0.36), 1.5)   # Crack in the porcelain
	c.draw_line(head + Vector2(-2, -2), head + Vector2(-6, 6), Color(0.4, 0.38, 0.36), 1.5)
	var hood := PackedVector2Array([head + Vector2(-20, 6), head + Vector2(-18, -14), head + Vector2(-2, -24), head + Vector2(14, -20), head + Vector2(10, -12), head + Vector2(-8, -14), head + Vector2(-12, 8)])
	c.draw_colored_polygon(hood, COAT_SHADE)
	FighterArt.outline(c, hood, 2.5)
	if dead:
		EnemyArt.ko_eye(c, head + Vector2(8, -2), 3.0, t)
	else:
		for ex: float in [3.0, 12.0]:
			c.draw_circle(head + Vector2(ex, -2), 3.6, EnemyArt.BLACK)
			c.draw_circle(head + Vector2(ex - 1.0, -3.0), 1.0, Color(1, 1, 1, 0.8))
	c.draw_arc(head + Vector2(8, 5), 6.0, 0.2, PI - 0.2, 8, STITCH, 1.8)
	for k in 4:
		var m := head + Vector2(3.0 + float(k) * 3.4, 8.0 + sin(float(k)) * 0.5)
		c.draw_line(m + Vector2(0, -2.5), m + Vector2(0, 2.5), STITCH, 1.4)
