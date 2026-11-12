class_name CrawlingVictim
extends ExtEnemy
## CRAWLING VICTIM (VM2, deeper into the Void). What is left of a person the Void swallowed:
## grey skin, torn clothes, dragging itself along the bone floor on its arms. Slow, but they come
## in numbers and GRAB your legs.
##   Claw   3 dmg      a weak swipe
##   Grab   2 x3 dmg   grabs you and pulls (mash any key to break free)

const SKIN := Color(0.58, 0.58, 0.62)
const SKIN_SHADE := Color(0.40, 0.40, 0.45)
const CLOTH := Color(0.28, 0.24, 0.30)
const EYE := Color(0.9, 0.9, 1.0)

var _victim: Fighter = null
var _ticks := 0
var _tick_t := 0.0


func _make_data() -> CharacterData:
	keep_min = 0.0
	keep_max = 70.0
	attack_chance = 0.7
	phase2_threshold = -1.0
	return SimpleEnemy.make_data("Crawling Victim", 20, Vector2(90, 40), 90.0)


static func make_patterns() -> Array[EnemyPattern]:
	var list: Array[EnemyPattern] = []
	list.append(EnemyPattern.make("claw", "CLAW", 1.5, 3, 0.0, 80.0, "claw", 0.25, 0.15, 0.35, false, [1.6, 1.6]))
	list.append(EnemyPattern.make("grab", "GRAB!", 4.0, 2, 0.0, 90.0, "grab", 0.35, 1.5, 0.4, true, [1.2, 1.2]))
	list[1].note = "holds you: mash any key to break free"
	return list


func flavor_lines() -> Array[String]:
	return ["...help...", "*dragging*", "...don't leave me here..."]


func _attack(p: EnemyPattern) -> void:
	match p.id:
		"claw":
			melee(dmg(p), Vector2(140, -100), Vector2(50, -20), Vector2(60, 40), "victim_claw")
			SoundManager.play_sfx("swing", -10.0)
		"grab":
			_victim = null
			_ticks = 0
			var t: Fighter = brain.target if brain != null else null
			if t == null or not is_instance_valid(t) or t.is_dead or t.grabbed_by != null:
				return
			var dx := (t.global_position.x - global_position.x) * float(facing)
			if dx < -10.0 or dx > 110.0 or absf(t.global_position.y - global_position.y) > 80.0:
				return
			_victim = t
			_tick_t = 0.3
			grab_hold_distance = 60.0
			t.begin_grab(self)
			Effects.popup(t, t.global_position + Vector2(0, -170), "GRABBED!", Color(0.85, 0.85, 1.0), 20)


func _on_attack_update(p: EnemyPattern, delta: float) -> void:
	if p.id != "grab" or _victim == null:
		return
	if not is_instance_valid(_victim) or _victim.is_dead or _victim.grabbed_by != self:
		_victim = null
		state_time = state_len
		return
	_tick_t -= delta
	if _tick_t <= 0.0 and _ticks < 3:
		_tick_t = 0.4
		_ticks += 1
		var h := make_hit(dmg(p), Vector2.ZERO, "victim_grab")
		h.blockable = false
		h.causes_hitstun = false
		CombatManager.apply_hit(h, _victim)


func _on_attack_end(p: EnemyPattern) -> void:
	if p.id == "grab":
		_release()


func _cancel_pattern() -> void:
	_release()
	super._cancel_pattern()


func _release() -> void:
	if _victim != null and is_instance_valid(_victim) and _victim.grabbed_by == self:
		_victim.release_grab()
	_victim = null


func draw_model_on(c: CanvasItem) -> void:
	draw_victim(c, art_state())


static func draw_portrait(c: CanvasItem, t: float) -> void:
	draw_victim(c, {"t": t, "pose": "idle"})


## A person lying on its belly, head up, pulling itself forward with the arms.
static func draw_victim(c: CanvasItem, s: Dictionary) -> void:
	var t: float = s.get("t", 0.0)
	var pose_v: String = s.get("pose", "idle")
	var dead: bool = s.get("dead", false)
	var crawl := sin(float(s.get("walk", 0.0)) * 1.5 + t * 1.5)
	# Dragging legs
	FighterArt.limb(c, Vector2(-30, -12), Vector2(-62, -6), 9.0, CLOTH.darkened(0.2), CLOTH.darkened(0.4), CLOTH)
	FighterArt.limb(c, Vector2(-28, -10), Vector2(-58, -2), 9.0, CLOTH, CLOTH.darkened(0.3), CLOTH.lightened(0.2))
	# Body lying along the floor
	var body := EnemyArt.ellipse_points(Vector2(-6, -16), 30.0, 12.0, 18)
	c.draw_colored_polygon(body, CLOTH)
	c.draw_line(Vector2(-20, -24), Vector2(6, -6), CLOTH.darkened(0.4), 2.0)          # Tears
	FighterArt.outline(c, body, 3.5)
	# Reaching arms
	var reach := Vector2(48 + crawl * 10.0, -4)
	var far_r := Vector2(40 - crawl * 10.0, -6)
	if pose_v.begins_with("grab") or pose_v.begins_with("claw"):
		reach = Vector2(64, -24) if pose_v.ends_with("_tele") else Vector2(70, -10)
	EnemyArt.arm(c, Vector2(16, -22), far_r, 7.0, SKIN_SHADE, SKIN_SHADE.darkened(0.2), SKIN, SKIN_SHADE, 5.0)
	var head := Vector2(24, -30)
	FighterArt.ball(c, head, 11.0, SKIN, SKIN_SHADE, SKIN.lightened(0.2))
	c.draw_line(head + Vector2(-8, -10), head + Vector2(4, -12), Color(0.2, 0.2, 0.22), 3.0)     # Matted hair
	if dead:
		EnemyArt.ko_eye(c, head + Vector2(5, -2), 2.4, t)
	else:
		c.draw_circle(head + Vector2(5, -2), 2.4, EYE)
		c.draw_colored_polygon(EnemyArt.ellipse_points(head + Vector2(6, 5), 3.0, 2.5, 8), Color(0.1, 0.05, 0.05))
	EnemyArt.arm(c, Vector2(20, -22), reach, 7.5, SKIN, SKIN_SHADE, SKIN.lightened(0.2), SKIN, 5.5)
