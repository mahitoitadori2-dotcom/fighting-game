class_name CopperCorpse
extends SimpleEnemy
## COPPER CORPSE (Story Mode, Colosseum 3 - the Burning Throne Room): a dead soldier still
## standing in green-stained copper armour. Gray dead skin, dim orange eyes. SLOW and heavy.
##
##   Heavy Punch    8 dmg, 2.6 s - BIG wind-up, a crushing armoured punch
##   Shoulder Ram   5 dmg, 3.5 s - a short lumbering charge

const PUNCH_KB := Vector2(420, -240)
const RAM_KB := Vector2(320, -160)
const RAM_SPEED := 420.0

const COPPER := Color(0.78, 0.45, 0.22)
const COPPER_SHADE := Color(0.50, 0.26, 0.12)
const COPPER_HI := Color(0.95, 0.68, 0.42)
const PATINA := Color(0.35, 0.68, 0.55)
const SKIN := Color(0.55, 0.56, 0.52)
const SKIN_SHADE := Color(0.36, 0.37, 0.34)
const EYE := Color(1.0, 0.6, 0.2)


func _make_data() -> CharacterData:
	keep_min = 0.0
	keep_max = 100.0
	attack_chance = 0.55
	phase2_threshold = -1.0
	knockback_scale = 0.6
	var d := SimpleEnemy.make_data("Copper Corpse", 34, Vector2(64, 140), 110.0)
	d.hitstun_time = 0.14
	return d


static func make_patterns() -> Array[EnemyPattern]:
	var list: Array[EnemyPattern] = []
	#                          id       name            cd    dmg  min   max    anim     tele  active rec   big    weights
	list.append(EnemyPattern.make("punch", "HEAVY PUNCH!", 2.6, 8, 0.0, 115.0, "punch", 0.60, 0.15, 0.60, true, [2.0, 2.0]))
	list.append(EnemyPattern.make("ram", "SHOULDER RAM", 3.5, 5, 60.0, 240.0, "ram", 0.40, 0.40, 0.50, false, [1.0, 1.0]))
	return list


func _on_respawn() -> void:
	super._on_respawn()
	knockback_scale = 0.6


func flavor_lines() -> Array[String]:
	return ["*creak of copper*", "...for the throne...", "*rasp*"]


func _attack(p: EnemyPattern) -> void:
	match p.id:
		"punch":
			hitbox.activate(make_hit(dmg(p), Vector2(facing * PUNCH_KB.x, PUNCH_KB.y), "copper_punch"),
				Vector2(facing * 62.0, -84.0), Vector2(74, 64))
			velocity.x = facing * 160.0
			Effects.shake(self, 4.0)
			SoundManager.play_sfx("punch")
		"ram":
			hitbox.activate(make_hit(dmg(p), Vector2(facing * RAM_KB.x, RAM_KB.y), "copper_ram"),
				Vector2(facing * 34.0, -76.0), Vector2(60, 120))
			SoundManager.play_sfx("dash", -6.0)


func _on_attack_update(p: EnemyPattern, _delta: float) -> void:
	if p.id == "ram":
		velocity.x = facing * RAM_SPEED
		if is_on_wall() or not ground_ahead(50.0):
			state_time = state_len


func _owns_velocity_x() -> bool:
	return estate == EState.ATTACK and current != null and current.id == "ram"


# ============================================================
# ART (facing right, origin = feet, ~80 x 160)
# ============================================================
func draw_model_on(c: CanvasItem) -> void:
	draw_corpse(c, art_state())


static func draw_portrait(c: CanvasItem, t: float) -> void:
	draw_corpse(c, {"t": t, "pose": "idle"})


static func draw_corpse(c: CanvasItem, s: Dictionary) -> void:
	var t: float = s.get("t", 0.0)
	var pose: String = s.get("pose", "idle")
	var dead: bool = s.get("dead", false)
	var slump := sin(t * 1.2) * 2.0
	EnemyArt.legs(c, s, -60.0, 11.0, 12.0, COPPER, COPPER_SHADE, COPPER_HI, COPPER_SHADE.darkened(0.3), 20.0)
	var chest := Vector2(2 + (10.0 if pose == "ram" else 0.0), -96 + slump)
	# Far arm (dangling)
	EnemyArt.arm(c, chest + Vector2(-14, -18), chest + Vector2(-20, 34), 10.0, COPPER_SHADE, COPPER_SHADE.darkened(0.2), COPPER, SKIN_SHADE, 7.0)
	# Breastplate with patina streaks and dents
	var plate := PackedVector2Array([chest + Vector2(-24, -28), chest + Vector2(26, -26), chest + Vector2(22, 36), chest + Vector2(-22, 36)])
	c.draw_polygon(plate, PackedColorArray([COPPER_HI, COPPER, COPPER_SHADE, COPPER_SHADE]))
	for k in 3:
		c.draw_line(chest + Vector2(-14 + float(k) * 12.0, -22), chest + Vector2(-16 + float(k) * 12.0, 10), Color(PATINA.r, PATINA.g, PATINA.b, 0.7), 3.0)
	c.draw_arc(chest + Vector2(8, 8), 7.0, 0.0, PI, 8, COPPER_SHADE.darkened(0.3), 2.0)     # Dent
	c.draw_line(chest + Vector2(-24, 34), chest + Vector2(22, 34), Color(0.25, 0.15, 0.1), 5.0)  # Belt
	FighterArt.outline(c, plate, 4.0)
	FighterArt.ball(c, chest + Vector2(-20, -24), 12.0, COPPER, COPPER_SHADE, COPPER_HI)  # Pauldron
	# Head: gray dead face under a copper helm
	var head := chest + Vector2(6, -46)
	FighterArt.ball(c, head, 15.0, SKIN, SKIN_SHADE, SKIN.lightened(0.15))
	var helm := PackedVector2Array([head + Vector2(-18, 0), head + Vector2(-16, -16), head + Vector2(0, -22), head + Vector2(16, -16), head + Vector2(18, -2), head + Vector2(14, -4), head + Vector2(-14, -4)])
	c.draw_colored_polygon(helm, COPPER)
	c.draw_line(head + Vector2(0, -22), head + Vector2(-6, -32), PATINA, 4.0)                    # Crest stub
	FighterArt.outline(c, helm, 3.0)
	if dead:
		EnemyArt.ko_eye(c, head + Vector2(8, 2), 3.0, t)
	else:
		c.draw_circle(head + Vector2(8, 2), 4.0, Color(EYE.r, EYE.g, EYE.b, 0.35))
		c.draw_circle(head + Vector2(8, 2), 2.0, EYE)
	c.draw_line(head + Vector2(2, 9), head + Vector2(12, 8), SKIN_SHADE.darkened(0.4), 2.0)
	# Punching arm
	var hand := chest + Vector2(24, 26)
	match pose:
		"punch_tele":
			hand = chest + Vector2(-16, -10)
		"punch":
			hand = chest + Vector2(62, 6)
		"ram", "ram_tele":
			hand = chest + Vector2(18, 4)
	EnemyArt.arm(c, chest + Vector2(14, -18), hand, 11.0, COPPER, COPPER_SHADE, COPPER_HI, COPPER_SHADE, 9.0)
	if pose == "punch":
		c.draw_arc(hand + Vector2(10, 0), 22.0, -1.2, 1.2, 10, Color(1, 0.9, 0.7, 0.7), 4.0, true)
