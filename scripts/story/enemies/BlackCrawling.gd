class_name BlackCrawling
extends SimpleEnemy
## BLACK CRAWLING (Story Mode, Colosseum 4 - the Overground Dark Cave): a small pitch-black
## crawling thing, all legs and teeth, with two pin-prick white eyes. FAST crawler.
##
##   Bite     3 dmg, 1.2 s - snaps when close
##   Pounce   4 dmg, 2.4 s - springs at you from a distance

const POUNCE_SPEED := Vector2(640, -320)
const POUNCE_KB := Vector2(240, -150)
const BITE_KB := Vector2(150, -80)

const BODY := Color(0.06, 0.06, 0.08)
const BODY_HI := Color(0.20, 0.20, 0.25)
const EYE := Color(0.95, 0.95, 1.0)

var _air := false


func _make_data() -> CharacterData:
	keep_min = 0.0
	keep_max = 220.0
	attack_chance = 0.75
	phase2_threshold = -1.0
	var d := SimpleEnemy.make_data("Black Crawling", 10, Vector2(54, 30), 300.0)
	d.respawn_delay = 1.0
	return d


static func make_patterns() -> Array[EnemyPattern]:
	var list: Array[EnemyPattern] = []
	#                          id        name      cd    dmg  min   max    anim      tele  active rec   big    weights
	list.append(EnemyPattern.make("bite", "BITE", 1.2, 3, 0.0, 70.0, "bite", 0.12, 0.12, 0.30, false, [1.6, 1.6]))
	list.append(EnemyPattern.make("pounce", "POUNCE", 2.4, 4, 70.0, 260.0, "pounce", 0.35, 0.60, 0.45, false, [2.0, 2.0]))
	return list


func flavor_lines() -> Array[String]:
	return ["*click click*", "*skitter*"]


func _attack(p: EnemyPattern) -> void:
	match p.id:
		"bite":
			hitbox.activate(make_hit(dmg(p), Vector2(facing * BITE_KB.x, BITE_KB.y), "crawling_bite"),
				Vector2(facing * 34.0, -16.0), Vector2(40, 30))
			SoundManager.play_sfx("bite", -8.0)
		"pounce":
			var dx := absf(target_x() - global_position.x)
			velocity = Vector2(facing * clampf(dx * 2.3, 320.0, POUNCE_SPEED.x), POUNCE_SPEED.y)
			_air = false
			hitbox.activate(make_hit(dmg(p), Vector2(facing * POUNCE_KB.x, POUNCE_KB.y), "crawling_pounce"),
				Vector2(facing * 16.0, -18.0), Vector2(56, 36))


func _on_attack_update(p: EnemyPattern, _delta: float) -> void:
	if p.id != "pounce":
		return
	if not is_on_floor():
		_air = true
	elif _air:
		state_time = state_len


func _owns_velocity_x() -> bool:
	return estate == EState.ATTACK and current != null and current.id == "pounce"


# ============================================================
# ART (facing right, origin = feet, ~70 x 36)
# ============================================================
func draw_model_on(c: CanvasItem) -> void:
	draw_crawling(c, art_state())


static func draw_portrait(c: CanvasItem, t: float) -> void:
	draw_crawling(c, {"t": t, "pose": "idle"})


static func draw_crawling(c: CanvasItem, s: Dictionary) -> void:
	var t: float = s.get("t", 0.0)
	var pose_v: String = s.get("pose", "idle")
	var dead: bool = s.get("dead", false)
	var ph: float = s.get("walk", 0.0) * 2.5
	var body_c := Vector2(0, -14 + sin(t * 8.0))
	# 6 spindly legs
	for i in 6:
		var side := -1.0 if i < 3 else 1.0
		var k := float(i % 3)
		var hip := body_c + Vector2(-12 + k * 12.0, 2)
		var lift := maxf(0.0, sin(ph + float(i) * 1.7)) * 6.0
		var knee := hip + Vector2(-6 + k * 6.0, -10 - lift) + Vector2(side * 4.0, 0)
		var foot := Vector2(hip.x - 10 + k * 10.0 + side * 6.0, -1)
		c.draw_polyline(PackedVector2Array([hip, knee, foot]), EnemyArt.BLACK, 4.0, FighterArt.AA)
		c.draw_polyline(PackedVector2Array([hip, knee, foot]), BODY_HI, 2.0, FighterArt.AA)
	var body := EnemyArt.ellipse_points(body_c, 22.0, 10.0, 16)
	c.draw_colored_polygon(body, BODY)
	c.draw_colored_polygon(EnemyArt.ellipse_points(body_c + Vector2(-4, -4), 14.0, 3.0, 10), BODY_HI)
	FighterArt.outline(c, body, 2.5)
	var head := body_c + Vector2(22, -2)
	FighterArt.ball(c, head, 9.0, BODY, EnemyArt.BLACK, BODY_HI)
	var open := 1.0 if pose_v == "bite" or pose_v == "pounce" else (0.4 if pose_v.ends_with("_tele") else 0.1)
	c.draw_colored_polygon(PackedVector2Array([head + Vector2(4, 0), head + Vector2(14, -2 - open * 5.0), head + Vector2(14, 2 + open * 5.0)]), Color(0.3, 0.0, 0.05))
	for k in 3:
		c.draw_line(head + Vector2(7 + float(k) * 3.0, -1 - open * 3.0), head + Vector2(7 + float(k) * 3.0, 1 - open * 1.0), Color.WHITE, 1.5)
	if dead:
		EnemyArt.ko_eye(c, head + Vector2(0, -3), 2.0, t)
	else:
		c.draw_circle(head + Vector2(0, -3), 2.0, EYE)
		c.draw_circle(head + Vector2(5, -4), 1.5, EYE)
