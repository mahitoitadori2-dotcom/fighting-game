class_name TroupeFollower
extends ExtEnemy
## TROUPE FOLLOWER (The Hunt of a Nightmare): the NIGHTMARE BASEPLATE - a red creature in a red
## cloak, its face hidden behind a CERAMIC MASK of a geometric shape (random for each one).
## In almost every level of the Hunt.
##
##   Claw        5 dmg   a swipe of its red claws
##   Lunge       7 dmg   dashes at you, claws first
##   Knife Toss  4 dmg   a thrown red knife

var mask := "circle"


func _make_data() -> CharacterData:
	keep_min = 0.0
	keep_max = 320.0
	attack_chance = 0.65
	mask = String(HuntArt.MASKS[randi() % HuntArt.MASKS.size()])
	return SimpleEnemy.make_data("Troupe Follower", 46, Vector2(50, 118), 270.0)


static func make_patterns() -> Array[EnemyPattern]:
	var list: Array[EnemyPattern] = []
	#                          id       name          cd   dmg  min    max    anim     tele  active rec   big    weights
	list.append(EnemyPattern.make("claw", "CLAW", 1.6, 5, 0.0, 120.0, "claw", 0.24, 0.2, 0.35, false, [1.8, 1.8]))
	list.append(EnemyPattern.make("lunge", "LUNGE!", 3.4, 7, 120.0, 420.0, "lunge", 0.4, 0.45, 0.45, false, [1.3, 1.5]))
	list.append(EnemyPattern.make("knife", "KNIFE", 3.0, 4, 200.0, 700.0, "throw", 0.35, 0.15, 0.4, false, [1.0, 1.2]))
	return list


func _attack(p: EnemyPattern) -> void:
	match p.id:
		"claw":
			melee(dmg(p), Vector2(260, -160), Vector2(48, -66), Vector2(80, 70), "follower_claw")
			SoundManager.play_sfx("whoosh", -8.0)
		"lunge":
			melee(dmg(p), Vector2(360, -200), Vector2(40, -60), Vector2(90, 80), "follower_lunge")
			SoundManager.play_sfx("whoosh", -4.0)
		"knife":
			var k := shot("nm_weapon", Vector2(30, -80), 640.0, 1.4, Vector2(40, 18), dmg(p), Vector2(200, -120), Color.WHITE, "follower_knife")
			k.art_id = "dagger"
			SoundManager.play_sfx("whoosh", -8.0)


func _on_attack_update(p: EnemyPattern, _delta: float) -> void:
	if p.id == "lunge":
		dash_step(760.0)


func _owns_velocity_x() -> bool:
	return estate == EState.ATTACK and current != null and current.id == "lunge"


func draw_model_on(c: CanvasItem) -> void:
	draw_follower(c, art_state(), mask)


static func draw_portrait(c: CanvasItem, t: float) -> void:
	draw_follower(c, {"t": t}, "triangle")


static func draw_follower(c: CanvasItem, s: Dictionary, p_mask: String) -> void:
	var pose_v: String = s.get("pose", "idle")
	var arm := 0.0
	match pose_v:
		"claw_tele", "lunge_tele", "throw_tele":
			arm = -0.4
		"claw", "lunge", "throw":
			arm = 1.0
	var pts := HuntArt.body(c, s, {"mask": p_mask, "arm_f": arm})
	var hf: Vector2 = pts["hand_f"]
	for f in 3:                                                    # Red claws
		c.draw_line(hf, hf + Vector2.from_angle(-0.5 + float(f) * 0.45) * 12.0, HuntArt.SKIN_SHADE, 3.0)
