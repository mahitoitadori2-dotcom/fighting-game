class_name Lincoln
extends SimpleEnemy
## ABRAHAM LINCOLN: very tall, black frock coat, bow tie, chinstrap beard, stovepipe
## top hat, rail-splitter axe. PvE enemy (BaseEnemy + EnemyPattern + EnemyHUD), 60 HP.
##
##   Top Hat Throw          6 dmg, 6 s  - hat flies out and comes back like a boomerang
##   Axe Chop              10 dmg, 9 s  - overhead chop in front of him
##   Emancipation Speech    0 dmg, 15 s - "FOUR SCORE..." over his head, then everyone
##                                        nearby is STUNNED for 1 s (armored wind-up)

const HAT_KB := Vector2(220, -120)
const CHOP_KB := Vector2(380, -260)
const SPEECH_RADIUS := 250.0
const SPEECH_STUN := 1.0

const COAT := Color(0.12, 0.12, 0.14)
const COAT_SHADE := Color(0.05, 0.05, 0.06)
const COAT_HI := Color(0.28, 0.28, 0.32)
const SKIN := Color(0.90, 0.76, 0.64)
const SKIN_SHADE := Color(0.72, 0.58, 0.48)
const BEARD := Color(0.14, 0.10, 0.08)
const WOOD := Color(0.55, 0.36, 0.18)
const STEEL := Color(0.78, 0.80, 0.84)

var hat_on := true


func _make_data() -> CharacterData:
	keep_min = 60.0
	keep_max = 260.0
	return SimpleEnemy.make_data("Abraham Lincoln", EnemyManager.ENEMY_HP, Vector2(60, 150), 280.0)


static func make_patterns() -> Array[EnemyPattern]:
	var list: Array[EnemyPattern] = []
	#                          id           name               cd    dmg  min    max    anim      tele  active rec   big    weights   armored
	list.append(EnemyPattern.make("hat_throw", "TOP HAT THROW!", 6.0, 6, 100.0, 560.0, "hat", 0.30, 0.20, 0.30, false, [1.5, 1.5]))
	list.append(EnemyPattern.make("axe_chop", "AXE CHOP!", 9.0, 10, 0.0, 130.0, "chop", 0.45, 0.15, 0.45, true, [1.6, 1.8]))
	list.append(EnemyPattern.make("speech", "FOUR SCORE...", 15.0, 0, 0.0, 240.0, "speech", 1.00, 0.20, 0.50, true, [1.0, 1.3], true))
	list[0].note = "boomerang"
	list[2].note = "stuns 1 s in a radius, no damage"
	return list


func wants_pattern(p: EnemyPattern) -> bool:
	return hat_on or p.id != "hat_throw"


func flavor_lines() -> Array[String]:
	return ["HONEST!", "A HOUSE DIVIDED...", "GOOD DAY, SIR."]


func on_projectile_returned(look: String) -> void:
	if look == "hat":
		hat_on = true


func _on_respawn() -> void:
	super._on_respawn()
	hat_on = true


func _attack(p: EnemyPattern) -> void:
	match p.id:
		"hat_throw":
			var h := spawn_projectile()
			h.kind = EnemyProjectile.Kind.BOOMERANG
			h.look = "hat"
			h.damage = dmg(p)
			h.knockback = HAT_KB
			h.dir = float(facing)
			h.speed = 640.0
			h.range_px = 380.0
			h.lifetime = 2.2
			h.size = Vector2(44, 34)
			h.move = "hat_throw"
			launch(h, global_position + Vector2(facing * 30.0, -150.0))
			hat_on = false
		"axe_chop":
			hitbox.activate(make_hit(dmg(p), Vector2(facing * CHOP_KB.x, CHOP_KB.y), "axe_chop"),
				Vector2(facing * 64.0, -62.0), Vector2(84, 116))
			Effects.shake(self, 4.0)
		"speech":
			stun_in_radius(global_position + Vector2(0, -75), SPEECH_RADIUS, SPEECH_STUN)
			Effects.shake(self, 5.0)
			Effects.popup(self, global_position + Vector2(0, -200), "...AND SEVEN YEARS AGO!", Color(1.0, 0.95, 0.75), 18)
			for side in [-1.0, 1.0]:                       # Visible speech waves (harmless)
				var w := spawn_projectile()
				w.look = "croak"
				w.harmless = true
				w.tint = Color(1.0, 0.95, 0.75)
				w.dir = side
				w.speed = 520.0
				w.lifetime = 0.45
				launch(w, global_position + Vector2(side * 40.0, -110.0))


# ============================================================
# ART (facing right, origin = feet, ~60 x 190 with the hat)
# ============================================================
func draw_model_on(c: CanvasItem) -> void:
	var s := art_state()
	s["hat"] = hat_on
	draw_lincoln(c, s)


static func draw_portrait(c: CanvasItem, t: float) -> void:
	draw_lincoln(c, {"t": t, "pose": "idle", "hat": true})


static func draw_lincoln(c: CanvasItem, s: Dictionary) -> void:
	var t: float = s.get("t", 0.0)
	var pose: String = s.get("pose", "idle")
	var pt: float = s.get("pose_t", 0.0)
	var dead: bool = s.get("dead", false)

	if s.get("enraged", false):
		EnemyArt.aura(c, Vector2(0, -90), 70.0, Color(0.9, 0.2, 0.2), t)

	EnemyArt.legs(c, s, -70.0, 8.0, 12.0, COAT, COAT_SHADE, COAT_HI, COAT_SHADE, 16.0)

	var chest := Vector2(0, -112)

	# Far arm
	EnemyArt.arm(c, chest + Vector2(-12, -14), chest + Vector2(-18, 30), 11.0, COAT_SHADE, COAT_SHADE, COAT, SKIN_SHADE)

	# Long frock coat (tails reach the knees)
	var coat := PackedVector2Array([chest + Vector2(-18, -24), chest + Vector2(18, -24), chest + Vector2(22, 44),
		chest + Vector2(6, 52), chest + Vector2(-8, 52), chest + Vector2(-24, 46)])
	c.draw_polygon(coat, PackedColorArray([COAT_HI, COAT, COAT_SHADE, COAT_SHADE, COAT_SHADE, COAT_SHADE]))
	# White shirt + black bow tie + vest
	c.draw_colored_polygon(PackedVector2Array([chest + Vector2(-6, -24), chest + Vector2(6, -24), chest + Vector2(4, 8), chest + Vector2(-4, 8)]), Color(0.96, 0.96, 0.94))
	c.draw_colored_polygon(PackedVector2Array([chest + Vector2(-7, -24), chest + Vector2(0, -20), chest + Vector2(-7, -16)]), EnemyArt.BLACK)
	c.draw_colored_polygon(PackedVector2Array([chest + Vector2(7, -24), chest + Vector2(0, -20), chest + Vector2(7, -16)]), EnemyArt.BLACK)
	c.draw_line(chest + Vector2(-8, -14), chest + Vector2(-2, 30), COAT_HI, 2.0)           # Lapel
	for i in 3:
		c.draw_circle(chest + Vector2(8, -6 + float(i) * 10.0), 1.8, COAT_HI)               # Buttons
	FighterArt.outline(c, coat, 4.0)

	# Head: long face, chinstrap beard (no moustache), sad wise eyes
	var head := chest + Vector2(3, -42)
	var face := EnemyArt.ellipse_points(head, 12, 16, 18)
	c.draw_colored_polygon(face, SKIN)
	FighterArt.outline(c, face, 3.0)
	var beard := PackedVector2Array([head + Vector2(-12, 0), head + Vector2(-10, 12), head + Vector2(0, 22), head + Vector2(12, 14),
		head + Vector2(12, 4), head + Vector2(8, 12), head + Vector2(0, 14), head + Vector2(-6, 8)])
	c.draw_colored_polygon(beard, BEARD)
	FighterArt.outline(c, beard, 2.5)
	c.draw_colored_polygon(PackedVector2Array([head + Vector2(-12, -8), head + Vector2(-6, -16), head + Vector2(8, -15), head + Vector2(-4, -11)]), BEARD)   # Hair
	if dead:
		EnemyArt.ko_eye(c, head + Vector2(6, -3), 3.5, t)
	else:
		c.draw_circle(head + Vector2(6, -3), 2.6, Color.WHITE)
		c.draw_circle(head + Vector2(7, -3), 1.5, Color(0.3, 0.22, 0.12))
		c.draw_line(head + Vector2(2, -8), head + Vector2(10, -7), BEARD, 2.5)
	c.draw_line(head + Vector2(10, -2), head + Vector2(12, 4), SKIN_SHADE, 2.0)            # Nose
	var talking := pose == "speech_tele" and fmod(pt * 8.0, 1.0) < 0.5
	if talking:
		c.draw_circle(head + Vector2(6, 9), 3.0, Color(0.3, 0.05, 0.05))
	else:
		c.draw_line(head + Vector2(3, 9), head + Vector2(9, 9), Color(0.4, 0.2, 0.15), 2.0)

	# Stovepipe top hat
	if s.get("hat", true):
		var hb := head + Vector2(0, -15)
		var brim := FighterArt.rrect_points(Rect2(hb.x - 18, hb.y - 4, 36, 6), 3.0)
		var crown := FighterArt.rrect_points(Rect2(hb.x - 12, hb.y - 40, 24, 38), 2.5)
		c.draw_colored_polygon(crown, COAT)
		FighterArt.outline(c, crown, 3.0)
		c.draw_rect(Rect2(hb.x - 12, hb.y - 10, 24, 6), Color(0.32, 0.32, 0.36))
		c.draw_colored_polygon(brim, COAT_SHADE)
		FighterArt.outline(c, brim, 3.0)

	# Speech: raised fist, glowing words
	if pose == "speech_tele" or pose == "speech":
		var k := clampf(pt / 1.0, 0.0, 1.0)
		c.draw_arc(head + Vector2(20, 6), 12.0 + 10.0 * k, -0.7, 0.7, 10, Color(1, 0.95, 0.75, 0.8), 3.0, true)

	# Near arm + axe
	var shoulder := chest + Vector2(12, -14)
	var hand := chest + Vector2(22, 28)
	var axe_angle := -1.3
	match pose:
		"chop_tele":
			hand = chest + Vector2(-4, -58)
			axe_angle = -2.3
		"chop":
			hand = chest + Vector2(48, 6)
			axe_angle = 0.6
		"hat_tele":
			hand = head + Vector2(4, -26)                      # Grabs his hat
		"hat":
			hand = chest + Vector2(40, -22)
		"speech_tele", "speech":
			hand = chest + Vector2(18, -52)
	if pose != "hat_tele" and pose != "hat":
		_axe(c, hand, axe_angle)
	EnemyArt.arm(c, shoulder, hand, 11.0, COAT, COAT_SHADE, COAT_HI, SKIN)
	if pose == "chop":
		c.draw_arc(chest + Vector2(30, 0), 56.0, -1.6, 0.6, 14, Color(1, 1, 1, maxf(0.0, 0.8 - pt * 4.0)), 6.0, true)


static func _axe(c: CanvasItem, hand: Vector2, angle: float) -> void:
	var d := Vector2.from_angle(angle)
	var top := hand + d * 40.0
	var bottom := hand - d * 14.0
	c.draw_line(bottom, top, EnemyArt.BLACK, 8.0)
	c.draw_line(bottom, top, WOOD, 5.0)
	var n := d.orthogonal()
	var head := PackedVector2Array([top - d * 6.0 - n * 4.0, top - d * 8.0 + n * 16.0, top + d * 8.0 + n * 18.0, top + d * 6.0 - n * 4.0])
	c.draw_colored_polygon(head, STEEL)
	FighterArt.outline(c, head, 3.0)
	c.draw_line(top - d * 8.0 + n * 15.0, top + d * 8.0 + n * 17.0, Color.WHITE, 2.0)
