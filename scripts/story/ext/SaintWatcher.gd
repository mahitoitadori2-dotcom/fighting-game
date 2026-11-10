class_name SaintWatcher
extends ExtEnemy
## SAINT WATCHER (AG2 / AG3). A tall robed rock figure with one huge glowing eye. It keeps its
## distance and WATCHES you: rune shots, and a long laser stare.
##   Rune Shot   4 dmg   a glowing rune flies at you
##   Watch       7 dmg   charges, then fires a long laser beam from its eye

const BEAM_LEN := 560.0
const BEAM_Y := -168.0                       # Eye height (head of a h=1.3 humanoid)
const RUNE := Color(1.0, 0.85, 0.4)
const CFG := {"head": "rock", "h": 1.3, "robe": true, "skin": Color(0.62, 0.58, 0.52), "cloth": Color(0.48, 0.45, 0.40),
	"cloth_hi": Color(0.62, 0.59, 0.53), "trim": Color(0.9, 0.75, 0.35), "eye": Color(1.0, 0.9, 0.5), "runes": true}


func _make_data() -> CharacterData:
	keep_min = 280.0
	keep_max = 560.0
	attack_chance = 0.6
	phase2_threshold = -1.0
	return SimpleEnemy.make_data("Saint Watcher", 30, Vector2(60, 186), 120.0)


static func make_patterns() -> Array[EnemyPattern]:
	var list: Array[EnemyPattern] = []
	list.append(EnemyPattern.make("rune", "RUNE SHOT", 2.2, 4, 150.0, 850.0, "cast", 0.45, 0.2, 0.35, false, [2.0, 2.0]))
	list.append(EnemyPattern.make("watch", "WATCH!", 5.5, 7, 100.0, 650.0, "watch", 0.8, 0.45, 0.45, true, [1.3, 1.3]))
	list[1].note = "a long laser stare - get out of its line"
	return list


func flavor_lines() -> Array[String]:
	return ["*it watches*", "Seen.", "..."]


func _attack(p: EnemyPattern) -> void:
	match p.id:
		"rune":
			shot("rune", Vector2(40, -150), 500.0, 2.2, Vector2(34, 34), dmg(p), Vector2(180, -120), RUNE, "rune_shot")
			SoundManager.play_sfx("holy", -10.0)
		"watch":
			melee(dmg(p), Vector2(260, -140), Vector2(BEAM_LEN * 0.5 + 30.0, BEAM_Y), Vector2(BEAM_LEN, 36), "watcher_beam")
			SoundManager.play_sfx("beam", -4.0)


func draw_model_on(c: CanvasItem) -> void:
	var s := art_state()
	ExtArt.humanoid(c, s, CFG)
	_eye_fx(c, pose, pose_t)


static func _eye_fx(c: CanvasItem, p: String, pt: float) -> void:
	var eye := Vector2(14, -170)
	if p == "watch_tele":
		c.draw_circle(eye, 6.0 + 10.0 * clampf(pt / 0.8, 0.0, 1.0), Color(RUNE.r, RUNE.g, RUNE.b, 0.6))
	elif p == "watch":
		var fade := 1.0 - clampf((pt - 0.35) / 0.1, 0.0, 1.0)
		FighterArt.beam_gradient(c, Vector2(eye.x + 10.0, BEAM_Y), BEAM_LEN, 14.0 * fade + 1.0, RUNE, Color.WHITE)


static func draw_portrait(c: CanvasItem, t: float) -> void:
	ExtArt.humanoid(c, {"t": t, "pose": "idle"}, CFG)
