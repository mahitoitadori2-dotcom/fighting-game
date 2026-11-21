class_name SkullSerpent
extends SimpleEnemy
## SKULL SERPENT (Madness): a long serpent made of BONES - a chain of vertebrae with ribs, a
## horned skull for a head. It slithers low and fast; its body follows the head's path.
##
##   Strike     6 dmg, 1.8 s - rears back, then shoots forward jaws first
##   Bone Lash  5 dmg, 3.5 s - whips its tail around: hits everything near it

const SEGMENTS := 9
const SEG_GAP := 14.0
const BONE := Color(0.90, 0.86, 0.78)
const BONE_SHADE := Color(0.60, 0.55, 0.48)


func _make_data() -> CharacterData:
	keep_min = 80.0
	keep_max = 260.0
	attack_chance = 0.65
	phase2_threshold = -1.0
	var d := SimpleEnemy.make_data("Skull Serpent", 34, Vector2(110, 40), 330.0)
	d.respawn_delay = 1.2
	return d


static func make_patterns() -> Array[EnemyPattern]:
	var list: Array[EnemyPattern] = []
	list.append(EnemyPattern.make("strike", "STRIKE!", 1.8, 6, 60.0, 280.0, "strike", 0.35, 0.30, 0.40, false, [2.0, 2.0]))
	list.append(EnemyPattern.make("lash", "BONE LASH!", 3.5, 5, 0.0, 120.0, "lash", 0.40, 0.25, 0.40, true, [1.2, 1.2]))
	return list


func _attack(p: EnemyPattern) -> void:
	match p.id:
		"strike":
			velocity.x = facing * 760.0
			hitbox.activate(make_hit(dmg(p), Vector2(facing * 300.0, -150.0), "serpent_strike"), Vector2(facing * 70.0, -26.0), Vector2(60, 40))
			SoundManager.play_sfx("bite", -6.0)
		"lash":
			hit_in_radius(global_position + Vector2(0, -20), 120.0, dmg(p), Vector2(320, -220), "serpent_lash")
			SoundManager.play_sfx("whoosh", -6.0)


func _on_attack_update(p: EnemyPattern, _delta: float) -> void:
	if p.id == "strike":
		velocity.x = move_toward(velocity.x, 0.0, 2400.0 * get_physics_process_delta_time())
		if not ground_ahead(40.0):
			velocity.x = 0.0


func _owns_velocity_x() -> bool:
	return estate == EState.ATTACK and current != null and current.id == "strike"


func flavor_lines() -> Array[String]:
	return ["*rattle*", "*hiss*"]


# ============================================================
# ART (facing right, origin = under the skull, the body trails to the left)
# ============================================================
func draw_model_on(c: CanvasItem) -> void:
	draw_serpent(c, art_state())


static func draw_portrait(c: CanvasItem, t: float) -> void:
	draw_serpent(c, {"t": t, "pose": "idle"})


static func draw_serpent(c: CanvasItem, s: Dictionary) -> void:
	var t: float = s.get("t", 0.0)
	var pose_v: String = s.get("pose", "idle")
	var dead: bool = s.get("dead", false)
	var rear := 14.0 if pose_v == "strike_tele" else 0.0
	var lash := pose_v == "lash"
	# Vertebrae from the tail to the head, slithering in a sine wave
	for i in range(SEGMENTS, 0, -1):
		var x := -float(i) * SEG_GAP - (8.0 if pose_v == "strike_tele" else 0.0)
		var y := -14.0 + sin(t * 8.0 - float(i) * 0.8) * 7.0
		if lash:
			y -= sin(float(i) / float(SEGMENTS) * PI) * 26.0 * sin(t * 18.0)
		var r := 9.0 - float(i) * 0.5
		c.draw_circle(Vector2(x, y), r + 2.0, EnemyArt.BLACK)
		c.draw_circle(Vector2(x, y), r, BONE if i % 2 == 0 else BONE_SHADE)
		if i % 2 == 0 and i < SEGMENTS - 1:                                         # Ribs
			c.draw_line(Vector2(x, y), Vector2(x - 4, y + r + 6), BONE_SHADE, 2.5)
			c.draw_line(Vector2(x, y), Vector2(x - 4, y - r - 6), BONE_SHADE, 2.5)
	# The horned skull head
	var hc := Vector2(12, -24 - rear)
	var skull := PackedVector2Array([hc + Vector2(-14, -10), hc + Vector2(6, -14), hc + Vector2(26, -6), hc + Vector2(28, 4), hc + Vector2(8, 10), hc + Vector2(-12, 8)])
	c.draw_colored_polygon(skull, BONE)
	FighterArt.outline(c, skull, 3.0)
	var open := 10.0 if pose_v == "strike" else (4.0 if pose_v == "strike_tele" else 0.0)
	var jaw := PackedVector2Array([hc + Vector2(-8, 8), hc + Vector2(24, 6 + open), hc + Vector2(20, 12 + open), hc + Vector2(-6, 14)])
	c.draw_colored_polygon(jaw, BONE_SHADE)
	FighterArt.outline(c, jaw, 2.5)
	for k in 4:
		var tx := hc.x + 2.0 + float(k) * 5.0
		c.draw_colored_polygon(PackedVector2Array([Vector2(tx, hc.y + 7), Vector2(tx + 3, hc.y + 7), Vector2(tx + 1.5, hc.y + 12)]), Color(1, 1, 1))
	c.draw_colored_polygon(PackedVector2Array([hc + Vector2(-8, -10), hc + Vector2(-20, -28), hc + Vector2(-2, -12)]), BONE_SHADE)   # Horn
	c.draw_circle(hc + Vector2(10, -4), 4.5, EnemyArt.BLACK)
	if dead:
		EnemyArt.ko_eye(c, hc + Vector2(10, -4), 3.0, t)
	else:
		c.draw_circle(hc + Vector2(11, -4), 1.6, Color(1, 0.95, 0.9))
