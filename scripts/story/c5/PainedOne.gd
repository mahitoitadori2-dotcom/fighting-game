class_name PainedOne
extends SimpleEnemy
## PAINED ONE (Colosseum 5 coin flip: TAILS, with a Devilish Grin). A huge, hunched, suffering
## creature: grey bloated skin full of stitches and nails, a chain wrapped around its arms, a
## face frozen in a sob. Slow, but every hit is HEAVY.
##
##   Crushing Fist    7 dmg, 3.4 s - a slow overhead smash (longer wind-up: 0.9 s)
##   Agony Scream     4 dmg, 8.0 s - screams: a ring of sound flies out both ways (jump it),
##                                   and anyone right next to it is STUNNED (0.4 s)
## (Nerfed 2026-11-10: was 70 HP, 10 / 5 dmg, 2.8 / 6.5 s, 0.75 s wind-up, 0.7 s stun,
##  attack chance 0.55.)

const SKIN := Color(0.58, 0.56, 0.58)
const SKIN_SHADE := Color(0.38, 0.36, 0.40)
const SKIN_HI := Color(0.74, 0.72, 0.74)
const STITCH := Color(0.25, 0.08, 0.08)
const CHAIN := Color(0.45, 0.45, 0.50)
const TEAR := Color(0.55, 0.75, 1.0)


func _make_data() -> CharacterData:
	keep_min = 30.0
	keep_max = 110.0
	attack_chance = 0.45
	phase2_threshold = -1.0
	var d := SimpleEnemy.make_data("Pained One", 52, Vector2(86, 150), 105.0)
	d.hitstun_time = 0.1
	return d


func _ready() -> void:
	super._ready()
	knockback_scale = 0.5


static func make_patterns() -> Array[EnemyPattern]:
	var list: Array[EnemyPattern] = []
	#                          id       name               cd    dmg  min   max    anim    tele  active rec   big    weights        armored
	list.append(EnemyPattern.make("fist", "CRUSHING FIST!", 3.4, 7, 0.0, 135.0, "fist", 0.90, 0.18, 0.70, true, [2.0, 2.0], true))
	list.append(EnemyPattern.make("scream", "AGONY SCREAM!", 8.0, 4, 0.0, 520.0, "scream", 0.80, 0.60, 0.60, true, [1.2, 1.2], true))
	list[1].note = "a ring of sound rolls out both ways: jump it"
	return list


func flavor_lines() -> Array[String]:
	return ["...it hurts...", "*sobbing*", "make it... stop...", "*groans*"]


func _attack(p: EnemyPattern) -> void:
	match p.id:
		"fist":
			hitbox.activate(make_hit(dmg(p), Vector2(facing * 380.0, -340.0), "crushing_fist"), Vector2(facing * 70.0, -50.0), Vector2(110, 110))
			Effects.shake(self, 7.0)
			Effects.hit_sparks(self, global_position + Vector2(facing * 80.0, -8.0), 8, 1.2)
			SoundManager.play_sfx("slam", -4.0)
		"scream":
			for d: float in [-1.0, 1.0]:
				var w := spawn_projectile()
				w.kind = EnemyProjectile.Kind.LINEAR
				w.look = "shock"
				w.tint = Color(0.75, 0.85, 1.0)
				w.dir = d
				w.speed = 460.0
				w.lifetime = 1.1
				w.size = Vector2(50, 50)
				w.damage = dmg(p)
				w.knockback = Vector2(220, -300)
				w.move = "agony_scream"
				launch(w, global_position + Vector2(d * 50.0, -24.0))
			stun_in_radius(global_position + Vector2(0, -70), 120.0, 0.4)
			Effects.shake(self, 9.0)
			SoundManager.play_sfx("roar", -2.0, 0.2)


# ============================================================
# ART (facing right, origin = feet, ~110 x 160)
# ============================================================
func draw_model_on(c: CanvasItem) -> void:
	draw_pained(c, art_state())


static func draw_portrait(c: CanvasItem, t: float) -> void:
	draw_pained(c, {"t": t, "pose": "idle"})


static func draw_pained(c: CanvasItem, s: Dictionary) -> void:
	var t: float = s.get("t", 0.0)
	var pose: String = s.get("pose", "idle")
	var dead: bool = s.get("dead", false)
	var heave := sin(t * 1.6) * 3.0
	EnemyArt.legs(c, s, -46.0, 18.0, 15.0, SKIN, SKIN_SHADE, SKIN_HI, SKIN_SHADE, 22.0)
	var chest := Vector2(0, -88 + heave)
	# Bloated hunched body
	var body := EnemyArt.ellipse_points(chest + Vector2(-4, 4), 46.0, 50.0, 22)
	c.draw_colored_polygon(body, SKIN)
	c.draw_colored_polygon(EnemyArt.ellipse_points(chest + Vector2(-14, 16), 26.0, 30.0, 16), SKIN_SHADE)
	FighterArt.outline(c, body, 4.5)
	for i in 4:                                                       # Stitches + nails
		var a := chest + Vector2(-30.0 + float(i) * 16.0, -20.0 + float(i % 2) * 24.0)
		c.draw_line(a, a + Vector2(14, 10), STITCH, 3.0)
		for k in 3:
			var m := a.lerp(a + Vector2(14, 10), float(k) / 2.0)
			c.draw_line(m + Vector2(-3, 4), m + Vector2(3, -4), STITCH, 2.0)
	c.draw_line(chest + Vector2(20, -10), chest + Vector2(30, -18), CHAIN, 4.0)
	# Arms: the front fist goes up for the smash
	var hand := chest + Vector2(46, 42)
	match pose:
		"fist_tele":
			hand = chest + Vector2(20, -70)
		"fist":
			hand = chest + Vector2(70, 80)
		"scream_tele", "scream":
			hand = chest + Vector2(36, -40)
	EnemyArt.arm(c, chest + Vector2(-30, -20), chest + Vector2(-48, 40), 15.0, SKIN_SHADE, SKIN_SHADE.darkened(0.2), SKIN, SKIN_SHADE, 13.0)
	EnemyArt.arm(c, chest + Vector2(22, -24), hand, 16.0, SKIN, SKIN_SHADE, SKIN_HI, SKIN, 15.0)
	for k in 4:                                                       # Chain coiled on the forearm
		var m := (chest + Vector2(22, -24)).lerp(hand, 0.55 + float(k) * 0.08)
		c.draw_arc(m, 10.0, 0.0, TAU, 10, CHAIN, 3.0)
	# Small sobbing head sunk between the shoulders
	var head := chest + Vector2(14, -50)
	FighterArt.ball(c, head, 18.0, SKIN_HI, SKIN_SHADE, Color.WHITE)
	if dead:
		EnemyArt.ko_eye(c, head + Vector2(6, -2), 3.0, t)
	else:
		for ex: float in [-2.0, 10.0]:
			c.draw_line(head + Vector2(ex - 4, -6), head + Vector2(ex + 4, -2), EnemyArt.BLACK, 2.5)     # Squeezed shut
			var drop := fmod(t * 0.8 + ex * 0.1, 1.0)
			c.draw_circle(head + Vector2(ex, 2.0 + drop * 20.0), 2.5, TEAR)
	var open := 10.0 if pose.begins_with("scream") else 4.0
	c.draw_colored_polygon(EnemyArt.ellipse_points(head + Vector2(5, 9), 7.0, open, 12), Color(0.12, 0.02, 0.04))
	if pose == "scream":
		for i in 3:
			c.draw_arc(head + Vector2(10, 8), 26.0 + float(i) * 18.0, -0.7, 0.7, 10, Color(0.8, 0.9, 1.0, 0.6 - float(i) * 0.15), 3.0, true)
