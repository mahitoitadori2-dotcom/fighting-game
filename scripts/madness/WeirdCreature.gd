class_name WeirdCreature
extends SimpleEnemy
## WEIRD CREATURE (Madness, every level): a TORSO with a SKULL-like head floating just above it and
## only small HANDS and FEET floating beside / under it - no arms, no legs. EXTREMELY fast.
## (Drawn bone-white and dark flesh; Madness tints everything black and red.)
##
##   Claw     3 dmg, 0.7 s - the little hands swipe, very quick
##   Pounce   5 dmg, 2.0 s - a sudden dash-leap at you
##   Frenzy   6 dmg, 4.5 s - it blurs and hits three times on the way through

const POUNCE := Vector2(820, -300)
const BONE := Color(0.90, 0.86, 0.80)
const BONE_SHADE := Color(0.62, 0.56, 0.50)
const FLESH := Color(0.45, 0.30, 0.30)
const FLESH_SHADE := Color(0.26, 0.15, 0.15)
const EYE := Color(1.0, 0.95, 0.9)

var _air := false
var _frenzy_hits := 0


func _make_data() -> CharacterData:
	keep_min = 40.0
	keep_max = 160.0
	attack_chance = 0.8
	phase2_threshold = -1.0
	var d := SimpleEnemy.make_data("Weird Creature", 22, Vector2(48, 92), 560.0)
	d.acceleration = 4200.0
	d.deceleration = 4200.0
	d.respawn_delay = 1.0
	return d


static func make_patterns() -> Array[EnemyPattern]:
	var list: Array[EnemyPattern] = []
	#                          id        name       cd    dmg  min    max    anim      tele  active rec   big    weights
	list.append(EnemyPattern.make("claw", "CLAW", 0.7, 3, 0.0, 80.0, "claw", 0.10, 0.12, 0.22, false, [3.0, 3.0]))
	list.append(EnemyPattern.make("pounce", "POUNCE!", 2.0, 5, 90.0, 380.0, "pounce", 0.22, 0.50, 0.35, false, [2.0, 2.0]))
	list.append(EnemyPattern.make("frenzy", "FRENZY!", 4.5, 6, 0.0, 200.0, "frenzy", 0.30, 0.55, 0.40, true, [1.0, 1.0]))
	return list


func _attack(p: EnemyPattern) -> void:
	match p.id:
		"claw":
			hitbox.activate(make_hit(dmg(p), Vector2(facing * 180.0, -90.0), "weird_claw"), Vector2(facing * 38.0, -52.0), Vector2(50, 40))
			SoundManager.play_sfx("swing", -10.0)
		"pounce":
			var dx := absf(target_x() - global_position.x)
			velocity = Vector2(facing * clampf(dx * 2.6, 420.0, POUNCE.x), POUNCE.y)
			_air = false
			hitbox.activate(make_hit(dmg(p), Vector2(facing * 300.0, -180.0), "weird_pounce"), Vector2(facing * 20.0, -50.0), Vector2(60, 80))
		"frenzy":
			_frenzy_hits = 0
			velocity.x = facing * 900.0
			Effects.trail(visuals, Color(0.9, 0.1, 0.1), 40.0, 8)


func _on_attack_update(p: EnemyPattern, _delta: float) -> void:
	match p.id:
		"pounce":
			if not is_on_floor():
				_air = true
			elif _air:
				state_time = state_len
		"frenzy":
			velocity.x = facing * 900.0
			var step := int(state_time / (state_len / 3.0))
			if step >= _frenzy_hits and _frenzy_hits < 3:
				_frenzy_hits += 1
				hitbox.activate(make_hit(maxi(1, floori(dmg(p) / 3.0)), Vector2(facing * 140.0, -60.0), "weird_frenzy"), Vector2(facing * 30.0, -50.0), Vector2(64, 70))
			if not ground_ahead(50.0):
				state_time = state_len


func _owns_velocity_x() -> bool:
	return estate == EState.ATTACK and current != null and (current.id == "pounce" or current.id == "frenzy")


func flavor_lines() -> Array[String]:
	return ["*click click*", "...", "*giggling*"]


# ============================================================
# ART (facing right, origin = feet, ~50 x 100)
# ============================================================
func draw_model_on(c: CanvasItem) -> void:
	draw_creature(c, art_state(), 1.0, false)


static func draw_portrait(c: CanvasItem, t: float) -> void:
	draw_creature(c, {"t": t, "pose": "idle"}, 1.0, false)


## Shared with THE XX0XN (big = rot, the grin and the chainsaw are drawn by the boss).
static func draw_creature(c: CanvasItem, s: Dictionary, k: float, _big: bool) -> void:
	# Colours can be swapped (the Broken Ghost: the same body, fully BLACK with RED eyes)
	var bone: Color = s.get("bone", BONE)
	var bone_shade: Color = s.get("bone_shade", BONE_SHADE)
	var flesh: Color = s.get("flesh", FLESH)
	var eye: Color = s.get("eye", EYE)
	var no_feet: bool = s.get("no_feet", false)
	var t: float = s.get("t", 0.0)
	var pose_v: String = s.get("pose", "idle")
	var moving: bool = s.get("moving", false)
	var dead: bool = s.get("dead", false)
	var jit := Vector2(sin(t * 37.0), cos(t * 29.0)) * (1.5 if not dead else 0.0)       # It never stands still
	var lean := 0.25 if moving or pose_v in ["pounce", "frenzy"] else 0.0
	var torso_c := Vector2(lean * 30.0, -56.0) * k + jit
	# Floating FEET (no legs): two small bony feet that scuttle
	var run := sin(t * (22.0 if moving else 4.0)) * (12.0 if moving else 2.0)
	for side: float in ([] if no_feet else [-1.0, 1.0]):
		var fp := Vector2(side * 10.0 + run * side, -6.0 - absf(run) * 0.3) * k
		c.draw_colored_polygon(EnemyArt.ellipse_points(fp, 9.0 * k, 5.0 * k, 10), bone_shade)
		FighterArt.outline(c, EnemyArt.ellipse_points(fp, 9.0 * k, 5.0 * k, 10), 2.0)
	# TORSO: a ribbed barrel, darker flesh between the ribs
	var torso := PackedVector2Array([torso_c + Vector2(-16, -26) * k, torso_c + Vector2(16, -26) * k, torso_c + Vector2(20, -6) * k,
		torso_c + Vector2(12, 26) * k, torso_c + Vector2(-12, 26) * k, torso_c + Vector2(-20, -6) * k])
	c.draw_colored_polygon(torso, flesh)
	for i in 4:
		var y := (-18.0 + float(i) * 10.0) * k
		c.draw_line(torso_c + Vector2(-15 * k, y), torso_c + Vector2(15 * k, y + 2.0 * k), bone, 3.5 * k)
	c.draw_line(torso_c + Vector2(0, -26) * k, torso_c + Vector2(0, 22) * k, bone_shade, 3.0 * k)
	FighterArt.outline(c, torso, 3.0)
	# Floating HANDS (no arms): small claws that twitch, swipe on Claw (`hand` = its position)
	var swipe := 1.0 if pose_v in ["claw", "frenzy"] else 0.0
	for side: float in [-1.0, 1.0]:
		var hand := torso_c + Vector2(side * 30.0 + (34.0 if side > 0.0 else 10.0) * swipe, -4.0 + sin(t * 9.0 + side) * 4.0 - 10.0 * swipe) * k
		c.draw_circle(hand, 7.0 * k, bone_shade)
		for f in 3:
			var a := -0.7 + float(f) * 0.6
			c.draw_line(hand, hand + Vector2.from_angle(a) * 11.0 * k, bone, 2.5 * k)
		c.draw_arc(hand, 7.0 * k, 0.0, TAU, 10, EnemyArt.BLACK, 2.0)
	# SKULL head floating above the torso (no neck)
	var hc := torso_c + Vector2(4, -42) * k + Vector2(0, sin(t * 3.0) * 2.0)
	var skull := EnemyArt.ellipse_points(hc, 15.0 * k, 16.0 * k, 18)
	c.draw_colored_polygon(skull, bone)
	FighterArt.outline(c, skull, 3.0)
	c.draw_rect(Rect2(hc + Vector2(-8, 10) * k, Vector2(17, 8) * k), bone_shade)                    # Jaw
	for i in 4:
		c.draw_line(hc + Vector2(-6.0 + float(i) * 4.5, 10.0) * k, hc + Vector2(-6.0 + float(i) * 4.5, 17.0) * k, EnemyArt.BLACK, 1.5)
	for ex: float in [-1.0, 7.0]:                                                                    # Sockets + pinprick eyes
		c.draw_circle(hc + Vector2(ex, -2) * k, 5.0 * k, EnemyArt.BLACK)
		if not dead:
			c.draw_circle(hc + Vector2(ex + 1.0, -2) * k, 1.6 * k, eye)
	if dead:
		EnemyArt.ko_eye(c, hc + Vector2(3, -2) * k, 3.0 * k, t)
	if pose_v == "frenzy":                                                                            # Blur streaks
		for i in 3:
			c.draw_line(torso_c + Vector2(-40 - float(i) * 8, -20 + float(i) * 18) * k, torso_c + Vector2(-80 - float(i) * 8, -20 + float(i) * 18) * k, Color(1, 1, 1, 0.5), 3.0)
