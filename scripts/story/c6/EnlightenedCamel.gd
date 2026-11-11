class_name EnlightenedCamel
extends ExtEnemy
## ENLIGHTENED CAMEL RIDER (The Enlightened Chase). A big desert camel in gold-tasselled
## harness, an Enlightened SPEAR WARRIOR riding on its hump. Tanky and fast.
##   Camel Charge   9 dmg   gallops straight through you (jump it / get out of the way)
##   Spear Thrust   7 dmg   the rider stabs far ahead
##   Camel Spit     4 dmg   ...exactly what it sounds like
##   Trample        8 dmg   rears up and stomps: shockwaves roll out both ways (jump them)

const FUR := Color(0.80, 0.62, 0.38)
const FUR_SHADE := Color(0.60, 0.44, 0.24)
const FUR_HI := Color(0.92, 0.78, 0.54)
const GOLD := Color(1.0, 0.8, 0.3)
const BLANKET := Color(0.30, 0.25, 0.65)
const RIDER := {"head": "helm", "skin": Color(0.80, 0.64, 0.48), "cloth": Color(0.95, 0.92, 0.84),
	"cloth_hi": Color(1.0, 1.0, 0.96), "trim": Color(1.0, 0.78, 0.25), "eye": Color(0.3, 0.6, 1.0),
	"weapon": "spear", "metal": Color(1.0, 0.85, 0.4), "robe": true}

var _dash_to := 0.0


func _make_data() -> CharacterData:
	keep_min = 0.0
	keep_max = 260.0
	attack_chance = 0.65
	phase2_threshold = -1.0
	knockback_scale = 0.5
	grab_immune = true
	return SimpleEnemy.make_data("Enlightened Camel Rider", 55, Vector2(150, 190), 230.0)


static func make_patterns() -> Array[EnemyPattern]:
	var list: Array[EnemyPattern] = []
	list.append(EnemyPattern.make("charge", "CAMEL CHARGE!", 4.5, 9, 200.0, 900.0, "charge", 0.6, 0.8, 0.5, true, [1.6, 1.6], true))
	list.append(EnemyPattern.make("thrust", "SPEAR THRUST", 2.2, 7, 0.0, 200.0, "thrust", 0.4, 0.2, 0.45, false, [2.0, 2.0]))
	list.append(EnemyPattern.make("spit", "CAMEL SPIT", 3.5, 4, 150.0, 700.0, "spit", 0.4, 0.2, 0.4, false, [1.2, 1.2]))
	list.append(EnemyPattern.make("trample", "TRAMPLE!", 5.5, 8, 0.0, 260.0, "trample", 0.65, 0.3, 0.55, true, [1.3, 1.3], true))
	list[0].note = "gallops through you"
	list[3].note = "shockwaves both ways: jump them"
	return list


func flavor_lines() -> Array[String]:
	return ["*the camel grumbles*", "For the Enlightened One!", "*spits*", "HYAH!"]


func _attack(p: EnemyPattern) -> void:
	match p.id:
		"charge":
			_dash_to = clamp_to_ground(target_x() + float(facing) * 300.0, 60.0)
			facing = 1 if _dash_to > global_position.x else -1
			melee(dmg(p), Vector2(420, -280), Vector2(70, -90), Vector2(130, 150), "camel_charge")
			SoundManager.play_sfx("dash")
		"thrust":
			melee(dmg(p), Vector2(300, -200), Vector2(150, -150), Vector2(170, 50), "camel_spear")
			SoundManager.play_sfx("swing", -4.0)
		"spit":
			lob("chem_glob", Vector2(100, -150), clamp_to_ground(target_x(), 40.0), 0.6, dmg(p), Vector2(120, -120), 36.0, Color(0.85, 0.95, 0.7), "camel_spit")
			SoundManager.play_sfx("chem_spill", -6.0)
		"trample":
			Effects.shake(self, 9.0)
			hit_in_radius(global_position + Vector2(0, -40), 130.0, dmg(p), Vector2(300, -320), "camel_trample")
			for d: float in [-1.0, 1.0]:
				var w := spawn_projectile()
				w.kind = EnemyProjectile.Kind.LINEAR
				w.look = "shock"
				w.tint = GOLD
				w.dir = d
				w.speed = 480.0
				w.lifetime = 1.0
				w.size = Vector2(50, 40)
				w.damage = 5
				w.knockback = Vector2(220, -320)
				w.pierce = true
				w.move = "trample_wave"
				launch(w, global_position + Vector2(d * 80.0, -20.0))
			SoundManager.play_sfx("slam", -2.0)


func _on_attack_update(p: EnemyPattern, delta: float) -> void:
	if p.id == "charge":
		var step := 900.0 * delta
		if absf(_dash_to - global_position.x) <= step:
			velocity.x = 0.0
			state_time = state_len
		else:
			dash_step(900.0)


func _on_attack_end(p: EnemyPattern) -> void:
	if p.id == "charge":
		velocity.x = 0.0


func _owns_velocity_x() -> bool:
	return estate == EState.ATTACK and current != null and current.id == "charge"


# ============================================================
# ART (facing right, origin = feet, ~190 x 230)
# ============================================================
func draw_model_on(c: CanvasItem) -> void:
	draw_camel(c, art_state())


static func draw_portrait(c: CanvasItem, t: float) -> void:
	draw_camel(c, {"t": t, "pose": "idle"})


static func draw_camel(c: CanvasItem, s: Dictionary) -> void:
	var t: float = s.get("t", 0.0)
	var pose: String = s.get("pose", "idle")
	var dead: bool = s.get("dead", false)
	var walk: float = s.get("walk", 0.0)
	var gallop := pose == "charge"
	var rear := -0.22 if pose == "trample_tele" else 0.0
	c.draw_set_transform(Vector2(-50, 0), rear, Vector2.ONE)       # Rears up around the back legs
	var o := Vector2(50, 0)
	var spd := 2.6 if gallop else 1.0
	# Legs (far pair darker)
	for i in 4:
		var far := i % 2 == 0
		var hip := o + Vector2(-48.0 if i < 2 else 42.0, -96.0)
		var sw := sin(walk * spd + float(i) * 1.6 + (0.0 if far else PI)) * (22.0 if gallop else 12.0)
		var knee := hip + Vector2(sw * 0.5, 44.0)
		var foot := Vector2(hip.x + sw, -4.0)
		if rear != 0.0 and i >= 2:
			knee = hip + Vector2(26, 26)
			foot = hip + Vector2(40, 50)
		var col := FUR_SHADE if far else FUR
		c.draw_polyline(PackedVector2Array([hip, knee, foot]), EnemyArt.BLACK, 15.0, true)
		c.draw_polyline(PackedVector2Array([hip, knee, foot]), col, 9.0, true)
		c.draw_circle(foot, 7.0, Color(0.35, 0.25, 0.15))
	# Body + hump
	var body := EnemyArt.ellipse_points(o + Vector2(-4, -110), 70.0, 32.0, 22)
	c.draw_colored_polygon(body, FUR)
	var hump := EnemyArt.ellipse_points(o + Vector2(-8, -140), 30.0, 22.0, 16)
	c.draw_colored_polygon(hump, FUR)
	FighterArt.outline(c, body, 4.0)
	FighterArt.outline(c, hump, 4.0)
	c.draw_line(o + Vector2(-60, -100), o + Vector2(50, -100), FUR_HI, 3.0)
	# Tail
	c.draw_line(o + Vector2(-72, -116), o + Vector2(-84, -84 + sin(t * 5.0) * 6.0), EnemyArt.BLACK, 6.0)
	c.draw_line(o + Vector2(-72, -116), o + Vector2(-84, -84 + sin(t * 5.0) * 6.0), FUR_SHADE, 3.0)
	# Neck + head
	var nb := o + Vector2(58, -124)
	var hd := o + Vector2(98, -180 + sin(t * 2.0) * 3.0)
	if gallop:
		hd = o + Vector2(118, -160)
	c.draw_line(nb, hd + Vector2(-8, 10), EnemyArt.BLACK, 24.0, true)
	c.draw_line(nb, hd + Vector2(-8, 10), FUR, 17.0, true)
	var head := PackedVector2Array([hd + Vector2(-14, -10), hd + Vector2(16, -8), hd + Vector2(30, 2), hd + Vector2(26, 12), hd + Vector2(-12, 12)])
	c.draw_colored_polygon(head, FUR)
	FighterArt.outline(c, head, 3.5)
	c.draw_circle(hd + Vector2(-8, -12), 5.0, FUR_SHADE)                 # Ear
	if dead:
		EnemyArt.ko_eye(c, hd + Vector2(4, -2), 3.0, t)
	else:
		c.draw_circle(hd + Vector2(4, -2), 3.0, EnemyArt.BLACK)
		c.draw_line(hd + Vector2(0, -6), hd + Vector2(8, -5), EnemyArt.BLACK, 2.0)   # Grumpy brow
	if pose == "spit" or pose == "spit_tele":
		c.draw_circle(hd + Vector2(30, 6), 5.0, Color(0.85, 0.95, 0.7))
	# Gold harness + tassels
	c.draw_line(hd + Vector2(-10, 4), nb + Vector2(10, -6), GOLD, 3.0)
	for k in 4:
		var tp := o + Vector2(-50 + float(k) * 32.0, -82)
		c.draw_line(tp, tp + Vector2(0, 14 + sin(t * 6.0 + float(k)) * 3.0), GOLD, 3.0)
		c.draw_circle(tp + Vector2(0, 16), 3.5, GOLD)
	# The rider (spear warrior), sitting on the hump
	var rider_pose := "idle"
	if pose.begins_with("thrust"):
		rider_pose = pose
	# (local point p is drawn at (-50, 0) + p.rotated(rear); rider's feet sit so his hips are on the hump)
	c.draw_set_transform(Vector2(-50, 0) + (o + Vector2(-6, -94)).rotated(rear), rear, Vector2(0.72, 0.72))
	ExtArt.humanoid(c, {"t": t, "pose": rider_pose, "pose_t": s.get("pose_t", 0.0), "dead": dead}, RIDER)
	c.draw_set_transform(Vector2(-50, 0), rear, Vector2.ONE)
	# Saddle blanket over the rider's legs
	var bl := PackedVector2Array([o + Vector2(-44, -150), o + Vector2(28, -150), o + Vector2(36, -104), o + Vector2(-52, -104)])
	c.draw_colored_polygon(bl, BLANKET)
	c.draw_line(o + Vector2(-50, -108), o + Vector2(34, -108), GOLD, 4.0)
	FighterArt.outline(c, bl, 3.5)
	c.draw_set_transform(Vector2.ZERO, 0.0, Vector2.ONE)
