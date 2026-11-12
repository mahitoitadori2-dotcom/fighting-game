class_name DevilishGrin
extends SimpleEnemy
## DEVILISH GRIN (Colosseum 5 coin flip: TAILS, with a Pained One). A floating BLACK CLOUD in
## the shape of a MOUTH: two smoky lips stretched into a huge grin, crooked white teeth, embers
## glowing in the dark between them. No eyes, no body - just the grin, drifting and LAUGHING.
##
##   Grin Bite    4 dmg, 2.3 s - the cloud lunges and the jaws snap shut on you
##   Fire Spit    4 dmg, 3.2 s - spits a fireball out of the dark between its teeth
##   Cackle       3 dmg, 7.5 s - laughs so hard the smoke bursts out around it (heals 2 HP)
## (Nerfed 2026-11-10: was 40 HP, 6 / 5 / 4 dmg, 1.8 / 2.6 / 6.0 s, heal 4, attack chance 0.6.)

const HOVER := 34.0
const SMOKE := Color(0.06, 0.05, 0.07)
const SMOKE_HI := Color(0.20, 0.18, 0.22)
const TEETH := Color(0.98, 0.95, 0.86)
const EMBER := Color(1.0, 0.35, 0.1)

var _floor := INF


func _make_data() -> CharacterData:
	keep_min = 90.0
	keep_max = 300.0
	attack_chance = 0.45
	phase2_threshold = -1.0
	return SimpleEnemy.make_data("Devilish Grin", 30, Vector2(96, 90), 200.0)


static func make_patterns() -> Array[EnemyPattern]:
	var list: Array[EnemyPattern] = []
	#                          id       name            cd    dmg  min    max    anim     tele  active rec   big    weights
	list.append(EnemyPattern.make("gslash", "GRIN BITE", 2.3, 4, 0.0, 130.0, "gslash", 0.38, 0.20, 0.40, false, [2.0, 2.0]))
	list.append(EnemyPattern.make("spit", "FIRE SPIT", 3.2, 4, 140.0, 700.0, "spit", 0.50, 0.15, 0.40, false, [1.8, 1.8]))
	list.append(EnemyPattern.make("cackle", "CACKLE!", 7.5, 3, 0.0, 170.0, "cackle", 0.60, 0.40, 0.40, true, [1.0, 1.0]))
	return list


func flavor_lines() -> Array[String]:
	return ["HEHEHEHEHE!", "Hah! HAH HAH!", "*giggling smoke*", "Such a SAD little hero!"]


func jump(_force_mult: float = 1.0) -> void:
	pass                                              # It drifts


func _movement(delta: float) -> void:
	super._movement(delta)
	if _floor == INF:
		if is_on_floor():
			_floor = global_position.y
		return
	var goal := _floor - HOVER + sin(anim_time * 2.4) * 8.0
	velocity.y = (goal - global_position.y) * 5.0


func _attack(p: EnemyPattern) -> void:
	match p.id:
		"gslash":
			hitbox.activate(make_hit(dmg(p), Vector2(facing * 320.0, -200.0), "grin_bite"), Vector2(facing * 60.0, -50.0), Vector2(100, 80))
			velocity.x = facing * 340.0
			SoundManager.play_sfx("bite", -3.0)
		"spit":
			var f := spawn_projectile()
			f.kind = EnemyProjectile.Kind.LINEAR
			f.look = "fireball"
			f.dir = float(facing)
			f.speed = 520.0
			f.lifetime = 1.4
			f.size = Vector2(36, 36)
			f.damage = dmg(p)
			f.knockback = Vector2(200, -140)
			f.pierce = false
			f.move = "grin_spit"
			launch(f, global_position + Vector2(facing * 50.0, -48.0))
			SoundManager.play_sfx("flame", -6.0)
		"cackle":
			hit_in_radius(global_position + Vector2(0, -45), 120.0, dmg(p), Vector2(300, -260), "cackle")
			Effects.void_burst(self, global_position + Vector2(0, -45), 120.0)
			heal(2)
			Effects.popup(self, global_position + Vector2(0, -130), "HAHAHAHA!", Color(1.0, 0.4, 0.3), 20)
			SoundManager.play_sfx("roar", -10.0, 0.3)


# ============================================================
# ART (facing right, origin = bottom of the cloud, ~140 x 100)
# ============================================================
func draw_model_on(c: CanvasItem) -> void:
	draw_grin(c, art_state())


static func draw_portrait(c: CanvasItem, t: float) -> void:
	draw_grin(c, {"t": t, "pose": "idle"})


static func draw_grin(c: CanvasItem, s: Dictionary) -> void:
	var t: float = s.get("t", 0.0)
	var pose_v: String = s.get("pose", "idle")
	var dead: bool = s.get("dead", false)
	var laughing := pose_v.begins_with("cackle")
	var shake := sin(t * (26.0 if laughing else 6.0)) * (4.0 if laughing else 1.5)
	var center := Vector2(0, -48 + shake)
	# Smoke puffs swirling around the mouth (the "cloud")
	for i in 11:
		var a := TAU * float(i) / 11.0 + t * 0.6
		var r := 26.0 + 6.0 * sin(t * 2.0 + float(i) * 1.7)
		var p := center + Vector2(cos(a) * 58.0, sin(a) * 30.0)
		c.draw_circle(p, r + 2.5, EnemyArt.BLACK)
		c.draw_circle(p, r, SMOKE if i % 2 == 0 else SMOKE_HI)
	for i in 4:                                        # Wisps trailing behind
		var wp := center + Vector2(-70.0 - float(i) * 14.0, sin(t * 3.0 + float(i)) * 10.0)
		c.draw_circle(wp, 12.0 - float(i) * 2.5, Color(SMOKE_HI.r, SMOKE_HI.g, SMOKE_HI.b, 0.7 - float(i) * 0.15))
	# The MOUTH: upper lip curve + lower lip curve, open wider when it bites / laughs / spits
	var open := 10.0
	if pose_v == "gslash_tele" or pose_v == "spit_tele":
		open = 26.0
	elif laughing or pose_v == "spit":
		open = 22.0 + absf(shake) * 2.0
	elif pose_v == "gslash":
		open = 2.0                                     # Snap!
	var w := 62.0
	var mouth := PackedVector2Array()
	for i in 17:                                       # Upper edge: the corners curl UP into a grin
		var u := float(i) / 16.0
		var x := -w + u * w * 2.0
		mouth.append(center + Vector2(x, -open * 0.5 * sin(u * PI) - 18.0 * pow(absf(u - 0.5) * 2.0, 3.0)))
	for i in 17:
		var u := 1.0 - float(i) / 16.0
		var x := -w + u * w * 2.0
		mouth.append(center + Vector2(x, open * 0.5 * sin(u * PI) + 14.0 * sin(u * PI) - 18.0 * pow(absf(u - 0.5) * 2.0, 3.0)))
	c.draw_colored_polygon(mouth, Color(0.10, 0.0, 0.02))
	# Embers glowing inside the dark
	c.draw_circle(center + Vector2(0, 4), 18.0 + open * 0.4, Color(EMBER.r, EMBER.g, EMBER.b, 0.25))
	for i in 3:
		c.draw_circle(center + Vector2(-20.0 + float(i) * 20.0, 4.0 + sin(t * 4.0 + float(i)) * 3.0), 2.5, EMBER)
	# Crooked teeth (top row + bottom row)
	for i in 9:
		var u := (float(i) + 0.5) / 9.0
		var x := -w * 0.85 + u * w * 1.7
		var curl := -18.0 * pow(absf(u - 0.5) * 2.0, 3.0)
		var top_y := center.y - open * 0.5 * sin(u * PI) + curl
		var bot_y := center.y + open * 0.5 * sin(u * PI) + 14.0 * sin(u * PI) + curl
		var tw := 5.0
		c.draw_colored_polygon(PackedVector2Array([Vector2(center.x + x - tw, top_y), Vector2(center.x + x + tw, top_y), Vector2(center.x + x + sin(float(i) * 2.3), top_y + 9.0 + float(i % 3) * 2.0)]), TEETH)
		c.draw_colored_polygon(PackedVector2Array([Vector2(center.x + x - tw, bot_y), Vector2(center.x + x + tw, bot_y), Vector2(center.x + x + cos(float(i) * 1.9), bot_y - 8.0 - float((i + 1) % 3) * 2.0)]), TEETH)
	FighterArt.outline(c, mouth, 3.0, Color(0.55, 0.1, 0.1))
	if dead:                                           # Fading out: the grin falls slack
		c.draw_line(center + Vector2(-40, 0), center + Vector2(40, 0), Color(1, 1, 1, 0.6), 3.0)
	if laughing:
		for i in 3:
			FighterArt.label(c, center + Vector2(-50.0 + float(i) * 50.0, -50.0 - float(i % 2) * 14.0 + shake), "HA", 16, Color(1.0, 0.45, 0.35, 0.9))
