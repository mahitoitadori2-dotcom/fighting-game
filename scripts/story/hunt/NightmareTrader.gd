class_name NightmareTrader
extends ExtEnemy
## NIGHTMARE TRADER (The Hunt of a Nightmare, in about 70% of its levels): a Troupe member that
## wields a SWORD and an ANCIENT WEIGHT on a chain.
##
##   Sword Cut      7 dmg   a quick cut
##   Weight Swing  11 dmg   SLOW: the ancient weight swings round in a wide arc (armored)
##   Weight Drop    8 dmg   throws the weight high: it lands where you stand

var mask := "square"


func _make_data() -> CharacterData:
	keep_min = 0.0
	keep_max = 380.0
	attack_chance = 0.6
	mask = String(HuntArt.MASKS[randi() % HuntArt.MASKS.size()])
	return SimpleEnemy.make_data("Nightmare Trader", 74, Vector2(60, 126), 210.0)


static func make_patterns() -> Array[EnemyPattern]:
	var list: Array[EnemyPattern] = []
	list.append(EnemyPattern.make("cut", "SWORD CUT", 1.8, 7, 0.0, 140.0, "cut", 0.28, 0.2, 0.4, false, [1.8, 1.8]))
	list.append(EnemyPattern.make("swing", "WEIGHT SWING!", 4.5, 11, 0.0, 190.0, "swing", 0.7, 0.35, 0.6, true, [1.3, 1.5], true))
	list.append(EnemyPattern.make("drop", "WEIGHT DROP!", 5.0, 8, 160.0, 800.0, "drop", 0.5, 0.2, 0.6, true, [1.1, 1.3]))
	return list


func _attack(p: EnemyPattern) -> void:
	match p.id:
		"cut":
			melee(dmg(p), Vector2(280, -180), Vector2(70, -70), Vector2(110, 70), "trader_cut")
			SoundManager.play_sfx("sword_slash", -6.0)
		"swing":
			hit_in_radius(global_position + Vector2(facing * 30.0, -60.0), 170.0, dmg(p), Vector2(facing * 480.0, -300.0), "trader_weight")
			Effects.shake(self, 7.0)
			SoundManager.play_sfx("slam", -4.0)
		"drop":
			lob("boulder", Vector2(-20, -110), target_x(), 0.9, dmg(p), Vector2(260, -320), 70.0, Color(0.85, 0.62, 0.30), "trader_drop")
			SoundManager.play_sfx("whoosh", -6.0)


func draw_model_on(c: CanvasItem) -> void:
	draw_trader(c, art_state(), mask)


static func draw_portrait(c: CanvasItem, t: float) -> void:
	draw_trader(c, {"t": t}, "square")


static func draw_trader(c: CanvasItem, s: Dictionary, p_mask: String) -> void:
	var t: float = s.get("t", 0.0)
	var pose_v: String = s.get("pose", "idle")
	var arm_f := 0.0
	var arm_b := 0.0
	var swing := 0.3 + sin(t * 2.0) * 0.2
	match pose_v:
		"cut_tele":
			arm_f = -0.5
		"cut":
			arm_f = 1.0
		"swing_tele":
			arm_b = -0.4
			swing = 2.6
		"swing":
			arm_b = 1.0
			swing = -2.2 + s.get("pose_t", 0.0) * 9.0
		"drop_tele":
			arm_b = 1.2
			swing = 3.1
	var pts := HuntArt.body(c, s, {"mask": p_mask, "k": 1.08, "wide": 1.15, "arm_f": arm_f, "arm_b": arm_b, "cloak": Color(0.50, 0.06, 0.06)})
	var kk: float = pts["k"]
	if pose_v != "drop":
		HuntArt.ancient_weight(c, pts["hand_b"], kk, swing, t)
	HuntArt.weapon(c, "STRAIGHT SWORD", pts["hand_f"], -0.6 + arm_f * 0.9, kk, t)
