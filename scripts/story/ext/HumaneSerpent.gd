class_name HumaneSerpent
extends ExtEnemy
## HUMANE SERPENT (BC3). A tall, upright serpent-man: snake head, scaled torso, arms holding a
## long bronze spear, and a thick tail instead of legs.
##   Spear Thrust  6 dmg   long reach
##   Tail Swipe    5 dmg   sweeps the tail around itself (hits behind too)
##   Spear Rush    7 dmg   slithers forward, spear first

const CFG := {"head": "serpent", "tail": true, "h": 1.2, "w": 1.1, "skin": Color(0.36, 0.52, 0.26),
	"cloth": Color(0.30, 0.44, 0.20), "cloth_hi": Color(0.48, 0.62, 0.30), "trim": Color(0.75, 0.55, 0.25),
	"eye": Color(1.0, 0.85, 0.2), "weapon": "spear", "metal": Color(0.8, 0.6, 0.3)}


func _make_data() -> CharacterData:
	keep_min = 60.0
	keep_max = 170.0
	attack_chance = 0.7
	phase2_threshold = -1.0
	return SimpleEnemy.make_data("Humane Serpent", 45, Vector2(66, 168), 160.0)


static func make_patterns() -> Array[EnemyPattern]:
	var list: Array[EnemyPattern] = []
	list.append(EnemyPattern.make("thrust", "SPEAR THRUST", 1.9, 6, 0.0, 180.0, "thrust", 0.35, 0.15, 0.4, false, [2.0, 2.0]))
	list.append(EnemyPattern.make("tail", "TAIL SWIPE!", 3.5, 5, 0.0, 130.0, "tail", 0.4, 0.2, 0.4, true, [1.4, 1.4]))
	list.append(EnemyPattern.make("rush", "SPEAR RUSH!", 5.0, 7, 180.0, 420.0, "thrust", 0.5, 0.45, 0.45, true, [1.0, 1.0]))
	list[1].note = "hits behind it too"
	return list


func flavor_lines() -> Array[String]:
	return ["Ssssstay...", "The Caeser'sss children...", "*hiss*"]


func _attack(p: EnemyPattern) -> void:
	match p.id:
		"thrust":
			melee(dmg(p), Vector2(300, -140), Vector2(100, -90), Vector2(150, 40), "serpent_spear")
			SoundManager.play_sfx("swing", -4.0)
		"tail":
			hit_in_radius(global_position + Vector2(0, -40), 120.0, dmg(p), Vector2(320, -260), "tail_swipe")
			Effects.shake(self, 4.0)
			SoundManager.play_sfx("whoosh", -4.0)
		"rush":
			melee(dmg(p), Vector2(360, -220), Vector2(90, -90), Vector2(140, 50), "spear_rush")
			SoundManager.play_sfx("dash", -4.0)


func _on_attack_update(p: EnemyPattern, _delta: float) -> void:
	if p.id == "rush":
		dash_step(520.0)


func _owns_velocity_x() -> bool:
	return estate == EState.ATTACK and current != null and current.id == "rush"


func draw_model_on(c: CanvasItem) -> void:
	var s := art_state()
	if pose.begins_with("tail"):
		s["pose"] = "idle"                                  # The tail does the work
	ExtArt.humanoid(c, s, CFG)
	if pose == "tail":
		c.draw_arc(Vector2(0, -40), 110.0, 0.2, PI - 0.2, 16, Color(1, 1, 1, maxf(0.0, 0.7 - pose_t * 3.0)), 6.0, true)


static func draw_portrait(c: CanvasItem, t: float) -> void:
	ExtArt.humanoid(c, {"t": t, "pose": "idle"}, CFG)
