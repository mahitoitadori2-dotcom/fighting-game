class_name HollowMasker
extends SimpleEnemy
## HOLLOW MASKER (Story Mode, Colosseum 4): a tall, thin, hollow creature in a tattered black
## shroud, with a cracked WHITE MASK for a face - two empty eye holes and a frozen smile.
## Long arms that hang to its knees. Creepy and slow until it strikes.
##
##   Mask Slam   9 dmg, 3.0 s - BIG: it rears up and slams its masked head down in front
##   Mask Dash   7 dmg, 4.0 s - BIG: glides at you, mask first

const SLAM_KB := Vector2(380, -320)
const DASH_KB := Vector2(360, -200)
const DASH_SPEED := 640.0

const SHROUD := Color(0.06, 0.05, 0.08)
const SHROUD_HI := Color(0.18, 0.16, 0.22)
const MASK := Color(0.95, 0.94, 0.90)
const MASK_SHADE := Color(0.72, 0.70, 0.66)


func _make_data() -> CharacterData:
	keep_min = 40.0
	keep_max = 160.0
	attack_chance = 0.6
	phase2_threshold = -1.0
	knockback_scale = 0.7
	var d := SimpleEnemy.make_data("Hollow Masker", 46, Vector2(60, 190), 150.0)
	d.hitstun_time = 0.15
	return d


static func make_patterns() -> Array[EnemyPattern]:
	var list: Array[EnemyPattern] = []
	#                          id      name          cd    dmg  min   max    anim    tele  active rec   big    weights
	list.append(EnemyPattern.make("slam", "MASK SLAM!", 3.0, 9, 0.0, 150.0, "slam", 0.60, 0.20, 0.60, true, [2.0, 2.0]))
	list.append(EnemyPattern.make("dash", "MASK DASH!", 4.0, 7, 120.0, 520.0, "dash", 0.50, 0.50, 0.50, true, [1.6, 1.6]))
	return list


func _on_respawn() -> void:
	super._on_respawn()
	knockback_scale = 0.7


func flavor_lines() -> Array[String]:
	return ["...", "*hollow giggle*", "...stay..."]


func _attack(p: EnemyPattern) -> void:
	match p.id:
		"slam":
			hitbox.activate(make_hit(dmg(p), Vector2(facing * SLAM_KB.x, SLAM_KB.y), "mask_slam"),
				Vector2(facing * 80.0, -50.0), Vector2(110, 100))
			Effects.shake(self, 8.0)
			SoundManager.play_sfx("slam", -4.0)
		"dash":
			hitbox.activate(make_hit(dmg(p), Vector2(facing * DASH_KB.x, DASH_KB.y), "mask_dash"),
				Vector2(facing * 36.0, -140.0), Vector2(70, 110))
			Effects.trail(visuals, Color(0.9, 0.9, 1.0, 0.5), 14.0, 10)
			SoundManager.play_sfx("dash", -4.0)


func _on_attack_update(p: EnemyPattern, _delta: float) -> void:
	if p.id == "dash":
		velocity.x = facing * DASH_SPEED
		if is_on_wall() or not ground_ahead(50.0):
			state_time = state_len


func _on_attack_end(p: EnemyPattern) -> void:
	if p.id == "dash":
		velocity.x *= 0.2


func _owns_velocity_x() -> bool:
	return estate == EState.ATTACK and current != null and current.id == "dash"


# ============================================================
# ART (facing right, origin = feet, ~70 x 220)
# ============================================================
func draw_model_on(c: CanvasItem) -> void:
	draw_masker(c, art_state())


static func draw_portrait(c: CanvasItem, t: float) -> void:
	draw_masker(c, {"t": t, "pose": "idle"})


static func draw_masker(c: CanvasItem, s: Dictionary) -> void:
	var t: float = s.get("t", 0.0)
	var pose: String = s.get("pose", "idle")
	var pt: float = s.get("pose_t", 0.0)
	var dead: bool = s.get("dead", false)
	var sway := sin(t * 1.3) * 4.0
	var lean := 0.0
	var head := Vector2(10 + sway, -196)
	match pose:
		"slam_tele":
			head = Vector2(-10, -226)
		"slam":
			head = Vector2(70, -60)
			lean = 1.0
		"dash_tele":
			head = Vector2(-6, -180)
		"dash":
			head = Vector2(34, -170)
	# Tattered shroud: tall thin cone with a ragged hem, no visible feet
	var neck := head + Vector2(-6, 22)
	var shroud := PackedVector2Array([neck + Vector2(-12, 0), neck + Vector2(12, 0), Vector2(26, -8), Vector2(18, 0), Vector2(8, -10),
		Vector2(-2, 0), Vector2(-12, -10), Vector2(-22, 0), Vector2(-28, -8)])
	var cols := PackedColorArray()
	for p in shroud:
		cols.append(SHROUD_HI.lerp(SHROUD, clampf((p.y - neck.y) / 160.0, 0.0, 1.0)))
	c.draw_polygon(shroud, cols)
	FighterArt.outline(c, shroud, 3.5)
	# Long thin arms hanging to the knees (swing forward on the dash)
	for i in 2:
		var sh := neck + Vector2(-4.0 + float(i) * 10.0, 12)
		var hand := Vector2(sh.x + 10.0 + sin(t * 1.6 + float(i)) * 5.0, -58.0)
		if pose == "dash":
			hand = sh + Vector2(70, 10)
		var elbow := sh.lerp(hand, 0.5) + Vector2(-8, 0)
		c.draw_polyline(PackedVector2Array([sh, elbow, hand]), EnemyArt.BLACK, 7.0, true)
		c.draw_polyline(PackedVector2Array([sh, elbow, hand]), SHROUD_HI, 4.0, true)
		for f in 4:
			c.draw_line(hand, hand + Vector2.from_angle(PI * 0.5 + (float(f) - 1.5) * 0.25) * 14.0, SHROUD_HI, 2.0)
	# The WHITE MASK
	var mask := EnemyArt.ellipse_points(head, 18.0, 24.0, 20)
	c.draw_colored_polygon(mask, MASK)
	c.draw_colored_polygon(EnemyArt.ellipse_points(head + Vector2(-5, 6), 10.0, 14.0, 14), Color(MASK_SHADE.r, MASK_SHADE.g, MASK_SHADE.b, 0.35))
	FighterArt.outline(c, mask, 3.0)
	c.draw_polyline(PackedVector2Array([head + Vector2(6, -24), head + Vector2(2, -12), head + Vector2(8, -4)]), Color(0.3, 0.3, 0.3), 1.5, true)   # Crack
	if dead:
		EnemyArt.ko_eye(c, head + Vector2(-2, -6), 4.0, t)
		EnemyArt.ko_eye(c, head + Vector2(10, -6), 4.0, t)
	else:
		for ex in [-3.0, 10.0]:
			c.draw_colored_polygon(EnemyArt.ellipse_points(head + Vector2(ex, -6), 4.0, 6.0, 10), EnemyArt.BLACK)
	c.draw_arc(head + Vector2(4, 8), 8.0, 0.3, PI - 0.3, 10, EnemyArt.BLACK, 2.5)     # Frozen smile
	if pose == "slam" and pt < 0.2:
		c.draw_arc(Vector2(80, 0), 20.0 + pt * 300.0, PI, TAU, 16, Color(0.9, 0.9, 1.0, 1.0 - pt * 5.0), 5.0, true)
