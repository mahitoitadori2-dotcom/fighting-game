class_name BlasphemyFollowerWizard
extends ExtEnemy
## BLASPHEMY FOLLOWER - WIZARD TYPE (BC2). A robed cult sorcerer with a serpent-skull staff.
## Keeps its distance, shoots blasphemy bolts and TELEPORTS a short way when you get close.
##   Blasphemy Bolt   4 dmg   a crimson magic bolt
##   Bolt Volley      3 x3    three bolts at different heights
##   Teleport         -       blinks away from you

const MAGIC := Color(1.0, 0.25, 0.25)
const CFG := {"head": "hood", "skin": Color(0.55, 0.42, 0.36), "cloth": Color(0.22, 0.04, 0.06),
	"cloth_hi": Color(0.4, 0.08, 0.1), "trim": Color(0.75, 0.62, 0.35), "eye": Color(1.0, 0.3, 0.3),
	"weapon": "staff", "robe": true, "magic": Color(1.0, 0.25, 0.25)}


func _make_data() -> CharacterData:
	keep_min = 260.0
	keep_max = 520.0
	attack_chance = 0.65
	phase2_threshold = -1.0
	return SimpleEnemy.make_data("Blasphemy Wizard", 22, Vector2(54, 136), 170.0)


static func make_patterns() -> Array[EnemyPattern]:
	var list: Array[EnemyPattern] = []
	list.append(EnemyPattern.make("bolt", "BLASPHEMY BOLT", 2.2, 4, 140.0, 800.0, "cast", 0.45, 0.2, 0.35, false, [2.0, 2.0]))
	list.append(EnemyPattern.make("volley", "BOLT VOLLEY!", 5.0, 3, 140.0, 800.0, "cast", 0.6, 0.3, 0.4, true, [1.2, 1.2]))
	list.append(EnemyPattern.make("teleport", "TELEPORT", 3.5, 0, 0.0, 200.0, "cast", 0.25, 0.1, 0.2, false, [2.5, 2.5]))
	list[2].note = "blinks away when you get close"
	return list


func flavor_lines() -> Array[String]:
	return ["*whispers in a dead tongue*", "Burn, heretic.", "Sssss..."]


func _attack(p: EnemyPattern) -> void:
	match p.id:
		"bolt":
			shot("void_bolt", Vector2(40, -110), 520.0, 2.0, Vector2(34, 34), dmg(p), Vector2(180, -120), MAGIC, "blasphemy_bolt")
			SoundManager.play_sfx("void_goo", -8.0)
		"volley":
			for k in 3:
				shot("void_bolt", Vector2(40, -150 + float(k) * 50.0), 480.0 + float(k) * 40.0, 2.0, Vector2(30, 30), dmg(p), Vector2(160, -100), MAGIC, "blasphemy_bolt")
			SoundManager.play_sfx("void_goo", -6.0)
		"teleport":
			var away := -signf(target_x() - global_position.x)
			if away == 0.0:
				away = -float(facing)
			blink_to(global_position.x + away * 340.0)


func draw_model_on(c: CanvasItem) -> void:
	ExtArt.humanoid(c, art_state(), CFG)


static func draw_portrait(c: CanvasItem, t: float) -> void:
	ExtArt.humanoid(c, {"t": t, "pose": "idle"}, CFG)
