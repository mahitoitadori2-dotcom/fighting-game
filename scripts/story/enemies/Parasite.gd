class_name Parasite
extends SimpleEnemy
## PARASITE (Story Mode, Colosseum 1): a legless, fleshy crawler with a ring of teeth.
## Slithers close, coils up, then LUNGES through the air at you. Weak alone, nasty in packs.
##
##   Lunge   5 dmg, 2.4 s - coils (telegraph), then leaps at the player
##   Nip     3 dmg, 1.4 s - quick bite when already close

const LUNGE_SPEED := Vector2(620, -360)
const LUNGE_KB := Vector2(260, -160)
const NIP_KB := Vector2(160, -80)

const FLESH := Color(0.78, 0.36, 0.36)
const FLESH_SHADE := Color(0.52, 0.18, 0.22)
const FLESH_HI := Color(0.95, 0.58, 0.55)
const MAW := Color(0.30, 0.02, 0.06)
const BONE := Color(0.95, 0.90, 0.78)
const EYE := Color(1.0, 0.85, 0.1)

var _air := false


func _make_data() -> CharacterData:
	keep_min = 0.0
	keep_max = 200.0
	attack_chance = 0.7
	phase2_threshold = -1.0                      # Grunts don't enrage
	var d := SimpleEnemy.make_data("Parasite", 12, Vector2(56, 36), 190.0)
	d.respawn_delay = 1.2
	return d


static func make_patterns() -> Array[EnemyPattern]:
	var list: Array[EnemyPattern] = []
	#                          id       name       cd    dmg  min    max    anim     tele  active rec   big    weights
	list.append(EnemyPattern.make("lunge", "LUNGE!", 2.4, 5, 70.0, 280.0, "lunge", 0.45, 0.60, 0.55, false, [2.0, 2.0]))
	list.append(EnemyPattern.make("nip", "NIP", 1.4, 3, 0.0, 70.0, "nip", 0.15, 0.12, 0.35, false, [1.5, 1.5]))
	return list


func flavor_lines() -> Array[String]:
	return ["*skrrrch*", "*hiss*"]


func _attack(p: EnemyPattern) -> void:
	match p.id:
		"lunge":
			var dx := absf(target_x() - global_position.x)
			velocity = Vector2(facing * clampf(dx * 2.2, 320.0, LUNGE_SPEED.x), LUNGE_SPEED.y)
			_air = false
			hitbox.activate(make_hit(dmg(p), Vector2(facing * LUNGE_KB.x, LUNGE_KB.y), "parasite_lunge"),
				Vector2(facing * 18.0, -20.0), Vector2(62, 40))
			SoundManager.play_sfx("dash", -6.0)
		"nip":
			hitbox.activate(make_hit(dmg(p), Vector2(facing * NIP_KB.x, NIP_KB.y), "parasite_nip"),
				Vector2(facing * 36.0, -18.0), Vector2(40, 30))


func _on_attack_update(p: EnemyPattern, _delta: float) -> void:
	if p.id != "lunge":
		return
	if not is_on_floor():
		_air = true
	elif _air:
		state_time = state_len                        # Landed: lunge over


func _owns_velocity_x() -> bool:
	return estate == EState.ATTACK and current != null and current.id == "lunge"


# ============================================================
# ART (facing right, origin = feet, ~70 x 40)
# ============================================================
func draw_model_on(c: CanvasItem) -> void:
	draw_parasite(c, art_state())


static func draw_portrait(c: CanvasItem, t: float) -> void:
	draw_parasite(c, {"t": t, "pose": "idle"})


static func draw_parasite(c: CanvasItem, s: Dictionary) -> void:
	var t: float = s.get("t", 0.0)
	var pose_v: String = s.get("pose", "idle")
	var pt: float = s.get("pose_t", 0.0)
	var dead: bool = s.get("dead", false)
	var crawl := sin(float(s.get("walk", 0.0)) * 2.0) * 3.0
	var coil := clampf(pt / 0.45, 0.0, 1.0) if pose_v == "lunge_tele" else 0.0
	var stretch := 1.25 if pose_v == "lunge" else 1.0 - 0.25 * coil

	# Segmented body: 5 blobs from tail to head (front raises when coiling)
	var segs: Array[Vector2] = []
	for i in 5:
		var k := float(i) / 4.0
		var x := (-30.0 + 56.0 * k) * stretch
		var y := -12.0 - sin(k * PI + t * 6.0) * 2.0 - coil * k * k * 16.0 + (crawl if i % 2 == 0 else -crawl) * 0.4
		segs.append(Vector2(x, y))
	for i in 5:
		var r := 9.0 + float(i) * 1.8
		FighterArt.ball(c, segs[i], r, FLESH, FLESH_SHADE, FLESH_HI)
		if i < 4:                                               # Spiky back ridge
			var sp := segs[i] + Vector2(0, -r + 2.0)
			c.draw_colored_polygon(PackedVector2Array([sp + Vector2(-3, 2), sp + Vector2(1, -7), sp + Vector2(4, 2)]), BONE)
	# Head + maw
	var head := segs[4] + Vector2(6, 0)
	FighterArt.ball(c, head, 15.0, FLESH, FLESH_SHADE, FLESH_HI)
	var open := 0.0
	if pose_v == "lunge" or pose_v == "nip":
		open = 1.0
	elif pose_v == "lunge_tele" or pose_v == "nip_tele":
		open = 0.5
	var maw_c := head + Vector2(9, 2)
	c.draw_circle(maw_c, 6.0 + 4.0 * open, EnemyArt.BLACK)
	c.draw_circle(maw_c, 4.5 + 4.0 * open, MAW)
	for i in 8:                                                 # Ring of teeth
		var a := TAU * float(i) / 8.0 + t * 0.5
		var tp := maw_c + Vector2.from_angle(a) * (4.5 + 4.0 * open)
		c.draw_colored_polygon(PackedVector2Array([tp + Vector2.from_angle(a + 1.6) * 2.0, tp - Vector2.from_angle(a) * 4.0, tp + Vector2.from_angle(a - 1.6) * 2.0]), BONE)
	# Eye cluster
	for e in [Vector2(-2, -9), Vector2(5, -11), Vector2(-7, -5)]:
		if dead:
			EnemyArt.ko_eye(c, head + e, 2.6, t)
		else:
			c.draw_circle(head + e, 3.0, EnemyArt.BLACK)
			c.draw_circle(head + e, 2.0, EYE)
	if pose_v == "lunge":                                         # Speed streaks
		for i in 3:
			c.draw_line(Vector2(-40 - float(i) * 6.0, -24 + float(i) * 8.0), Vector2(-62 - float(i) * 6.0, -24 + float(i) * 8.0), Color(1, 1, 1, 0.6), 3.0)
