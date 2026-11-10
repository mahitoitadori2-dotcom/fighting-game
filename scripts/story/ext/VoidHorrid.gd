class_name VoidHorrid
extends C5Boss
## THE VOID HORRIDS - final boss of the Void Massacre extension (VM4, the Horrid Nest).
## THREE smaller Void Massacres fought AT ONCE: black void bodies, clusters of WHITE eyes,
## long spider legs. Each has its own big HP bar (StoryManager boss group). They split up:
## one stays close, one at mid range, one hangs back - attacking from different sides.
##
##   Leg Stab    5 dmg   stabs with a front leg
##   Pounce      6 dmg   leaps at you
##   Eye Beam    5 dmg   a white beam from its eyes
##   Void Web    3 dmg   spits void goo: a slowing void puddle where it lands

const BODY := Color(0.06, 0.04, 0.09)
const MARK := Color(0.45, 0.20, 0.75)
const EYE := Color(0.95, 0.95, 1.0)
const VOID := Color(0.55, 0.25, 0.95)
const ROLE_RANGE := [Vector2(0, 160), Vector2(200, 380), Vector2(380, 620)]   # Close / mid / far

## Which of the three (0 = the leader that StoryManager spawned).
var index := 0
var _air := false


func boss_forms() -> Array:
	return [{"name": "Void Horrid", "title": "VOID HORRID", "hp": 170, "body": Vector2(130, 90), "speed": 230.0}]


func setup_boss() -> void:
	var r: Vector2 = ROLE_RANGE[clampi(index, 0, 2)]
	keep_min = r.x
	keep_max = r.y
	attack_chance = 0.55
	chain_chance = 0.2
	art_scale = 1.0
	tags = {"stab": ["close"], "pounce": ["anti_air"], "beam": ["ranged"], "web": ["ranged"]}
	combos = {"stab": ["pounce"], "beam": ["web"], "pounce": ["stab"]}


## Called by StoryManager right after the leader appears: the other two drop in on the far side.
func spawn_group() -> Array:
	var out: Array = []
	for i in [1, 2]:
		var h := VoidHorrid.new()
		h.index = i
		h.slot = 2
		h.team = team
		h.respawn_enabled = false
		var side := -1.0 if i == 1 else 1.0
		h.position = Vector2(clamp_arena(arena_center() + side * 380.0), global_position.y - 400.0)
		h.default_facing = -int(side)
		h.facing = h.default_facing
		get_parent().add_child(h)
		Effects.void_burst(h, h.position + Vector2(0, -40), 80.0)
		out.append(h)
	return out


func boss_title() -> String:
	return "VOID HORRID %s" % ["I", "II", "III"][clampi(index, 0, 2)] + ("   -   ENRAGED" if raging else "")


static func make_patterns() -> Array[EnemyPattern]:
	var list: Array[EnemyPattern] = []
	# Three of them at once: each one hits softer and less often than a solo boss would
	list.append(EnemyPattern.make("stab", "LEG STAB!", 2.4, 5, 0.0, 170.0, "stab", 0.4, 0.2, 0.45, true, [2.0, 2.2]))
	list.append(EnemyPattern.make("pounce", "POUNCE!", 4.5, 6, 140.0, 460.0, "pounce", 0.5, 0.8, 0.5, true, [1.4, 1.6]))
	list.append(EnemyPattern.make("beam", "EYE BEAM!", 5.5, 5, 180.0, 900.0, "beam", 0.65, 0.3, 0.5, true, [1.6, 1.8]))
	list.append(EnemyPattern.make("web", "VOID WEB!", 7.0, 3, 120.0, 900.0, "beam", 0.55, 0.2, 0.45, true, [1.0, 1.3]))
	list[3].note = "leaves a slowing void puddle"
	return list


func flavor_lines() -> Array[String]:
	return ["*clicking*", "*chittering*", "*eight white eyes blink at once*"]


func _attack(p: EnemyPattern) -> void:
	match p.id:
		"stab":
			swing(dmg(p), Vector2(300, -220), Vector2(90, -50), Vector2(130, 80), "horrid_stab")
			SoundManager.play_sfx("bite", -4.0)
		"pounce":
			var dx := absf(target_x() - global_position.x)
			velocity = Vector2(facing * clampf(dx * 2.0, 320.0, 760.0), -460.0)
			_air = false
			swing(dmg(p), Vector2(320, -260), Vector2(30, -40), Vector2(140, 90), "horrid_pounce")
			SoundManager.play_sfx("whoosh", -4.0)
		"beam":
			shoot("eye_beam", global_position + Vector2(facing * 70.0, -70.0), float(facing), 900.0, 1.0, Vector2(70, 26), dmg(p), Vector2(240, -140), EYE, "horrid_beam", true)
			SoundManager.play_sfx("laser", -4.0)
		"web":
			lob("chem_glob", global_position + Vector2(facing * 50.0, -70.0), clamp_arena(target_x()), 0.8, dmg(p), Vector2(140, -140), 44.0, VOID, "void_web", _web_land)
			SoundManager.play_sfx("splash", -6.0)


func _web_land(pos: Vector2) -> void:
	var g: Variant = Effects.ground_below(self, pos + Vector2(0, -30), 200.0)
	if g != null:
		ChemicalPool.spawn_void(self, g as Vector2, 120.0, 3.5)


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
# ART (facing right, origin = feet, ~200 x 110): a small Void Massacre
# ============================================================
func draw_model_on(c: CanvasItem) -> void:
	draw_horrid(c, art_state())


static func draw_portrait(c: CanvasItem, t: float) -> void:
	draw_horrid(c, {"t": t, "pose": "idle"})


static func draw_horrid(c: CanvasItem, s: Dictionary) -> void:
	var t: float = s.get("t", 0.0)
	var pose: String = s.get("pose", "idle")
	var dead: bool = s.get("dead", false)
	var rage: bool = s.get("raging", false)
	c.draw_circle(Vector2(0, -50), 90.0, Color(VOID.r, VOID.g, VOID.b, 0.10 + (0.08 if rage else 0.0) + 0.04 * sin(t * 3.0)))
	ExtArt.spider(c, s, {"body": BODY, "mark": MARK, "eyes": EYE, "size": 1.9, "fang": Color(0.85, 0.85, 0.95)})
	# Extra WHITE EYES all over the head and back (the Massacre's trademark)
	var lift := -11.0 if pose.ends_with("_tele") else 0.0
	var head := Vector2(19, -46 + lift)
	if not dead:
		var g := 0.75 + 0.25 * sin(t * (10.0 if rage else 4.0))
		for e: Vector2 in [Vector2(-6, -14), Vector2(4, -18), Vector2(14, -14), Vector2(-10, -4), Vector2(22, -6)]:
			c.draw_circle(head + e, 4.2, EnemyArt.BLACK)
			c.draw_circle(head + e, 3.0, Color(EYE.r, EYE.g, EYE.b, g))
		for e: Vector2 in [Vector2(-62, -66), Vector2(-46, -72), Vector2(-30, -66)]:
			c.draw_circle(Vector2(e.x, e.y + lift), 3.6, EnemyArt.BLACK)
			c.draw_circle(Vector2(e.x, e.y + lift), 2.4, Color(EYE.r, EYE.g, EYE.b, g * 0.8))
	# Void tendrils dripping from the abdomen
	for k in 3:
		var b := Vector2(-60 + float(k) * 16.0, -34 + lift)
		c.draw_line(b, b + Vector2(sin(t * 3.0 + float(k)) * 6.0, 18.0 + float(k) * 4.0), Color(VOID.r, VOID.g, VOID.b, 0.7), 3.0)
	if pose == "beam_tele":
		c.draw_circle(head + Vector2(10, -6), 10.0 + 8.0 * sin(t * 25.0), Color(1, 1, 1, 0.5))
