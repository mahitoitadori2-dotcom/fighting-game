class_name Executor
extends C5Boss
## EXECUTOR - BOSS 4 of Colosseum 5 (Level 45, the Execution Ground).
## A towering executioner: black iron hood-helm with one violet slit, a leather apron, chains
## across the chest, and a huge two-handed GRINDING BLADE whose serrated teeth spin.
##
## PHASE 1
##   Cleaver Swing    9 dmg    a wide swing (twice in phase 2)
##   Execution       13 dmg    raises the blade high and brings it down; small shockwaves
##   Stomp            7 dmg    stomps: shockwaves roll both ways (jump them)
##   Grinding Throw  2 x6 +10  GRABS you, grinds you on the spinning blade, then hurls you
##                             across the arena (mash any key to break free early)
## PHASE 2 (below 50% HP: the MEMORY FOG leaks out of the helm)
##   Memory Fog       4 dmg    slow purple fog clouds: a hit CONFUSES you (left / right reversed)
##   Fog Rain         4 dmg    fog drops onto the floor around you (confuses too)
##   Saw Sweep        8 dmg    a low spinning sweep around it (jump it)
##   + Stomp becomes a triple stomp, swings come in pairs

const IRON := Color(0.16, 0.16, 0.18)
const IRON_HI := Color(0.34, 0.34, 0.38)
const LEATHER := Color(0.32, 0.20, 0.14)
const LEATHER_SHADE := Color(0.20, 0.12, 0.08)
const SKIN := Color(0.62, 0.52, 0.48)
const STEEL := Color(0.62, 0.62, 0.66)
const FOG := Color(0.65, 0.30, 0.95)
const CONFUSE_TIME := 3.5

var _victim: Fighter = null
var _grind_t := 0.0
var _grinds := 0
var _swings := 0
var _stomps := 0
var _air := false


func boss_forms() -> Array:
	return [{"name": "Executor", "title": "EXECUTOR", "hp": 600, "body": Vector2(120, 230), "speed": 170.0}]


func setup_boss() -> void:
	keep_min = 60.0
	keep_max = 220.0
	attack_chance = 0.75
	art_scale = 1.3
	chain_chance = 0.4
	tags = {"grind": ["close", "counter"], "stomp": ["counter", "anti_air"], "overhead": ["close"], "fog_bolt": ["ranged"],
		"fog_rain": ["ranged", "anti_air"], "sweep": ["counter"], "swing": ["close"]}
	combos = {"swing": ["grind", "stomp", "overhead"], "stomp": ["swing", "fog_bolt"], "overhead": ["stomp", "sweep"],
		"fog_bolt": ["fog_rain", "swing"], "sweep": ["grind", "swing"], "fog_rain": ["overhead"]}


static func make_patterns() -> Array[EnemyPattern]:
	var list: Array[EnemyPattern] = []
	#                          id          name                 cd    dmg  min    max     anim       tele  active rec   big   weights      armored
	list.append(EnemyPattern.make("swing", "CLEAVER SWING!", 2.2, 9, 0.0, 280.0, "swing", 0.50, 0.70, 0.55, true, [2.2, 2.2], true))
	list.append(EnemyPattern.make("overhead", "EXECUTION!", 4.0, 13, 0.0, 300.0, "overhead", 0.85, 0.25, 0.80, true, [1.4, 1.4], true))
	list.append(EnemyPattern.make("stomp", "STOMP!", 3.6, 7, 0.0, 700.0, "stomp", 0.50, 1.10, 0.50, true, [1.3, 1.4], true))
	list.append(EnemyPattern.make("grind", "GRINDING THROW!", 5.5, 10, 0.0, 200.0, "grind", 0.45, 2.00, 0.60, true, [1.3, 1.6], true))
	list.append(EnemyPattern.make("fog_bolt", "MEMORY FOG!", 4.5, 4, 150.0, 1000.0, "fog", 0.55, 0.30, 0.50, true, [0.0, 1.7], true))
	list.append(EnemyPattern.make("fog_rain", "FOG RAIN!", 7.0, 4, 0.0, 1200.0, "fog", 0.60, 0.30, 0.50, true, [0.0, 1.2], true))
	list.append(EnemyPattern.make("sweep", "SAW SWEEP!", 4.0, 8, 0.0, 320.0, "sweep", 0.50, 0.50, 0.55, true, [0.0, 1.3], true))
	list[2].note = "shockwaves: jump them"
	list[3].note = "a grab: mash any key to break free"
	list[4].note = "phase 2: reverses your controls for a few seconds"
	return list


func flavor_lines() -> Array[String]:
	if phase == 2:
		return ["Forget...", "You never came here.", "*the blade grinds*", "Who... are you?"]
	return ["*the blade grinds*", "Kneel.", "The sentence is DEATH."]


func on_rage() -> void:
	phase = 2                                            # Memory fog unlocked
	Effects.popup(self, global_position + Vector2(0, -320), "THE MEMORY FOG LEAKS OUT...", FOG.lightened(0.3), 26)
	SoundManager.play_sfx("void_goo")


func _attack(p: EnemyPattern) -> void:
	match p.id:
		"swing":
			_swings = 0
			_swing(p)
		"overhead":
			swing(dmg(p), Vector2(420, -420), Vector2(170, -60), Vector2(200, 160), "execution")
			for d: float in [-1.0, 1.0]:
				shoot("shock", Vector2(global_position.x + facing * 200.0 + d * 40.0, floor_y() - 20.0), d, 460.0, 0.6, Vector2(46, 36), 5, Vector2(220, -300), STEEL, "execution_wave", true)
			Effects.shake(self, 18.0)
			Effects.hit_sparks(self, global_position + Vector2(facing * 200.0, -10.0), 14, 1.6)
			SoundManager.play_sfx("slam")
			SoundManager.play_sfx("stone", -3.0)
		"stomp":
			_stomps = 0
			_stomp(p)
		"grind":
			_grind_start(p)
		"fog_bolt":
			for k in 3:
				var s := shoot("fog", global_position + Vector2(facing * 90.0, -150.0 + float(k) * 50.0), float(facing), 260.0 + float(k) * 70.0,
					3.2, Vector2(60, 60), dmg(p), Vector2(160, -120), FOG, "memory_fog", false)
				s.on_hit = _confuse
			SoundManager.play_sfx("void_goo", -2.0)
		"fog_rain":
			var tx := target_x()
			for k in 4:
				var g := lob("fog", global_position + Vector2(0, -280), clamp_arena(tx + float(k) * 130.0 - 195.0), 0.8 + 0.12 * float(k),
					dmg(p), Vector2(140, -160), 70.0, FOG, "fog_rain")
				g.on_hit = _confuse
			SoundManager.play_sfx("void_goo")
		"sweep":
			hitbox.activate(make_hit(dmg(p), Vector2(facing * 300.0, -380.0), "saw_sweep"), Vector2(0, -26), Vector2(520, 52))
			Effects.shake(self, 6.0)
			SoundManager.play_sfx("drill", -4.0)


func _swing(p: EnemyPattern) -> void:
	_swings += 1
	pose_t = 0.0
	swing(dmg(p), Vector2(400, -260), Vector2(150, -110), Vector2(260, 200), "cleaver_swing")
	velocity.x = facing * 180.0
	Effects.shake(self, 6.0)
	SoundManager.play_sfx("sword_slash")


func _stomp(p: EnemyPattern) -> void:
	_stomps += 1
	pose_t = 0.0
	for d: float in [-1.0, 1.0]:
		shoot("shock", Vector2(global_position.x + d * 80.0, floor_y() - 20.0), d, 540.0, 1.0, Vector2(54, 44), dmg(p), Vector2(240, -340), FOG if phase == 2 else STEEL, "stomp_wave", true)
	hit_in_radius(global_position + Vector2(0, -20), 120.0, dmg(p), Vector2(300, -300), "stomp")
	Effects.shake(self, 12.0)
	SoundManager.play_sfx("slam", -2.0)


func _confuse(f: Fighter) -> void:
	if f == null or not is_instance_valid(f) or f.is_dead:
		return
	f.confuse_timer = maxf(f.confuse_timer, CONFUSE_TIME)
	Effects.popup(f, f.global_position + Vector2(0, -190), "CONFUSED!  CONTROLS REVERSED", FOG.lightened(0.4), 22)


# ----- Grinding throw (a grab like a giant's) -----
func _grind_start(_p: EnemyPattern) -> void:
	_victim = null
	_grinds = 0
	_grind_t = 0.0
	var tgt := brain.target if brain != null else null
	if tgt == null or not is_instance_valid(tgt) or tgt.is_dead or tgt.grabbed_by != null:
		return
	var dx := (tgt.global_position.x - global_position.x) * float(facing)
	if dx < -20.0 or dx > 230.0 or absf(tgt.global_position.y - global_position.y) > 140.0:
		SoundManager.play_sfx("whoosh", -4.0)                 # Grabbed at nothing
		return
	_victim = tgt
	grab_hold_distance = 150.0
	tgt.begin_grab(self)
	Effects.popup(tgt, tgt.global_position + Vector2(0, -180), "GRABBED!  MASH TO ESCAPE", Color(1.0, 0.5, 0.4), 22)
	SoundManager.play_sfx("chain")


func _on_attack_update(p: EnemyPattern, delta: float) -> void:
	match p.id:
		"swing":
			if phase == 2 and _swings < 2 and state_time >= 0.35:
				_swing(p)
		"stomp":
			if phase == 2 and _stomps < 3 and state_time >= float(_stomps) * 0.35:
				_stomp(p)
		"grind":
			if _victim == null:
				state_time = maxf(state_time, state_len - 0.2)
				return
			if not is_instance_valid(_victim) or _victim.is_dead or _victim.grabbed_by != self:
				_victim = null                                 # Broke free
				state_time = state_len
				return
			_grind_t -= delta
			if _grind_t <= 0.0 and _grinds < 6:
				_grind_t = 0.22
				_grinds += 1
				var h := make_hit(2, Vector2.ZERO, "grinding_throw")
				h.blockable = false
				h.causes_hitstun = false
				CombatManager.apply_hit(h, _victim)
				Effects.hit_sparks(self, _victim.global_position + Vector2(0, -70), 6, 1.0)
				SoundManager.play_sfx("drill", -6.0)
			elif _grinds >= 6:
				_throw(p)
				state_time = state_len


func _throw(p: EnemyPattern) -> void:
	if _victim == null or not is_instance_valid(_victim):
		return
	_victim.release_grab()
	var h := make_hit(dmg(p), Vector2(facing * 760.0, -520.0), "grinding_throw")
	h.blockable = false
	h.origin = global_position
	CombatManager.apply_hit(h, _victim)
	Effects.shake(self, 14.0)
	SoundManager.play_sfx("slam")
	_victim = null


func _on_attack_end(p: EnemyPattern) -> void:
	if p.id == "grind" and _victim != null and is_instance_valid(_victim) and _victim.grabbed_by == self:
		_throw(p)
	if p.id == "swing":
		velocity.x = 0.0


func _cancel_pattern() -> void:
	if _victim != null and is_instance_valid(_victim) and _victim.grabbed_by == self:
		_victim.release_grab()
	_victim = null
	super._cancel_pattern()


# ============================================================
# ART (facing right, origin = feet, ~150 x 250 art units)
# ============================================================
func draw_model_on(c: CanvasItem) -> void:
	var s := art_state()
	s["fog"] = phase == 2
	draw_executor(c, s)


static func draw_portrait(c: CanvasItem, t: float) -> void:
	draw_executor(c, {"t": t, "pose": "idle"})


static func draw_executor(c: CanvasItem, s: Dictionary) -> void:
	var t: float = s.get("t", 0.0)
	var pose: String = s.get("pose", "idle")
	var pt: float = s.get("pose_t", 0.0)
	var dead: bool = s.get("dead", false)
	var fog: bool = s.get("fog", false)
	if fog:                                                    # Memory fog seeping out
		for i in 6:
			var p := Vector2(sin(t * 0.7 + float(i)) * 60.0, -200.0 - fmod(t * 30.0 + float(i) * 40.0, 160.0))
			c.draw_circle(p, 26.0, Color(FOG.r, FOG.g, FOG.b, 0.16))
	EnemyArt.legs(c, s, -90.0, 18.0, 18.0, LEATHER, LEATHER_SHADE, LEATHER.lightened(0.2), IRON, 26.0)
	var chest := Vector2(0, -150 + sin(t * 1.5) * 2.0)
	# The grinding blade (behind the body)
	var hand := chest + Vector2(30, 40)
	var ang := -1.9
	match pose:
		"swing_tele", "overhead_tele":
			hand = chest + Vector2(-30, -60)
			ang = -2.5
		"swing":
			hand = chest + Vector2(60, 0)
			ang = 0.5 - fmod(pt * 4.0, 1.0)
		"overhead":
			hand = chest + Vector2(70, 40)
			ang = 0.9
		"sweep":
			hand = chest + Vector2(40, 90)
			ang = t * 14.0
		"grind":
			hand = chest + Vector2(60, 10)
			ang = 0.0
	var d := Vector2.from_angle(ang)
	var n := d.orthogonal()
	var base := hand + d * 20.0
	var tip := hand + d * 190.0
	var blade := PackedVector2Array([base + n * 18.0, tip + n * 26.0, tip + d * 20.0, tip - n * 22.0, base - n * 16.0])
	c.draw_colored_polygon(blade, STEEL)
	FighterArt.outline(c, blade, 3.5)
	var spin := t * (30.0 if pose == "grind" or pose == "sweep" else 6.0)
	for k in 12:                                              # Spinning saw teeth along the edge
		var u := float(k) / 11.0
		var edge := base.lerp(tip, u) + n * (18.0 + u * 8.0)
		var wob := sin(spin + float(k)) * 4.0
		c.draw_colored_polygon(PackedVector2Array([edge - d * 6.0, edge + n * (10.0 + wob), edge + d * 6.0]), STEEL.lightened(0.3))
	c.draw_circle(base.lerp(tip, 0.25), 12.0, IRON)
	c.draw_line(hand - d * 30.0, hand + d * 20.0, EnemyArt.BLACK, 12.0)
	c.draw_line(hand - d * 30.0, hand + d * 20.0, LEATHER, 8.0)
	EnemyArt.arm(c, chest + Vector2(-30, -40), hand, 20.0, SKIN, SKIN.darkened(0.25), SKIN.lightened(0.15), IRON, 14.0)
	# Body: bare arms, leather apron, chains
	var torso := PackedVector2Array([chest + Vector2(-50, -56), chest + Vector2(50, -56), chest + Vector2(42, 64), chest + Vector2(-42, 64)])
	c.draw_polygon(torso, PackedColorArray([SKIN, SKIN, SKIN.darkened(0.25), SKIN.darkened(0.25)]))
	var apron := PackedVector2Array([chest + Vector2(-38, -20), chest + Vector2(40, -20), chest + Vector2(46, 96), chest + Vector2(-44, 96)])
	c.draw_colored_polygon(apron, LEATHER)
	c.draw_colored_polygon(PackedVector2Array([chest + Vector2(-10, 10), chest + Vector2(20, 30), chest + Vector2(-6, 60)]), Color(0.35, 0.06, 0.06, 0.6))
	FighterArt.outline(c, torso, 5.0)
	FighterArt.outline(c, apron, 4.0)
	for k in 7:                                                # Chain across the chest
		var m := (chest + Vector2(-50, -50)).lerp(chest + Vector2(50, -6), float(k) / 6.0)
		c.draw_arc(m, 8.0, 0.0, TAU, 10, IRON_HI, 3.0)
	# Front arm grabs the blade's haft
	var fh := hand + d * -10.0 + Vector2(0, 10)
	EnemyArt.arm(c, chest + Vector2(36, -40), fh, 20.0, SKIN, SKIN.darkened(0.25), SKIN.lightened(0.15), IRON, 14.0)
	# Iron hood-helm with one violet slit
	var head := chest + Vector2(8, -86)
	var helm := PackedVector2Array([head + Vector2(-34, 30), head + Vector2(-38, -10), head + Vector2(-18, -44), head + Vector2(14, -50), head + Vector2(36, -20), head + Vector2(34, 30)])
	c.draw_colored_polygon(helm, IRON)
	c.draw_colored_polygon(PackedVector2Array([head + Vector2(-30, 26), head + Vector2(-28, -6), head + Vector2(-14, -36), head + Vector2(-10, 26)]), IRON_HI)
	FighterArt.outline(c, helm, 4.0)
	if dead:
		EnemyArt.ko_eye(c, head + Vector2(16, -6), 5.0, t)
	else:
		var glow := FOG if fog else Color(0.75, 0.55, 1.0)
		c.draw_line(head + Vector2(0, -6), head + Vector2(32, -6), Color(glow.r, glow.g, glow.b, 0.4), 12.0)
		c.draw_line(head + Vector2(0, -6), head + Vector2(32, -6), glow, 4.0)
