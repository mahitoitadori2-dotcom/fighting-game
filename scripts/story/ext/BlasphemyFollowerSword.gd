class_name BlasphemyFollowerSword
extends ExtEnemy
## BLASPHEMY FOLLOWER - SWORD TYPE (BC2, the Caeser's crypts). A hooded zealot of the
## serpent cult: crimson robe, bone-gold trim, a curved sword and a round shield.
##   Slash         5 dmg   sword slash
##   Zealot Lunge  6 dmg   dashes in with the blade
##   Shield Block  -       raises the shield: blocks hits from the front

const CFG := {"head": "hood", "skin": Color(0.62, 0.48, 0.40), "cloth": Color(0.38, 0.06, 0.07),
	"cloth_hi": Color(0.55, 0.12, 0.12), "trim": Color(0.75, 0.62, 0.35), "eye": Color(1.0, 0.5, 0.2),
	"weapon": "sword", "shield": Color(0.45, 0.10, 0.08), "metal": Color(0.8, 0.75, 0.6)}


func _make_data() -> CharacterData:
	keep_min = 0.0
	keep_max = 140.0
	attack_chance = 0.7
	phase2_threshold = -1.0
	guard_ids = ["block"]
	return SimpleEnemy.make_data("Blasphemy Follower", 34, Vector2(58, 140), 190.0)


static func make_patterns() -> Array[EnemyPattern]:
	var list: Array[EnemyPattern] = []
	list.append(EnemyPattern.make("slash", "SLASH", 1.6, 5, 0.0, 110.0, "slash", 0.30, 0.15, 0.35, false, [2.0, 2.0]))
	list.append(EnemyPattern.make("lunge", "ZEALOT LUNGE!", 4.0, 6, 120.0, 280.0, "slash", 0.40, 0.35, 0.40, true, [1.2, 1.2]))
	list.append(EnemyPattern.make("block", "BLOCK", 4.5, 0, 0.0, 220.0, "block", 0.05, 1.3, 0.2, false, [1.0, 1.0]))
	list[2].note = "blocks hits from the front"
	return list


func flavor_lines() -> Array[String]:
	return ["For the Serpent!", "Blasphemer...", "The Caeser sleeps. You will not."]


func _attack(p: EnemyPattern) -> void:
	match p.id:
		"slash":
			melee(dmg(p), Vector2(260, -160), Vector2(50, -70), Vector2(80, 100), "follower_slash")
			SoundManager.play_sfx("sword_slash", -4.0)
		"lunge":
			melee(dmg(p), Vector2(320, -200), Vector2(40, -70), Vector2(80, 100), "follower_lunge")
			SoundManager.play_sfx("dash", -4.0)


func _on_attack_update(p: EnemyPattern, _delta: float) -> void:
	if p.id == "lunge":
		dash_step(560.0)


func _owns_velocity_x() -> bool:
	return estate == EState.ATTACK and current != null and current.id == "lunge"


func draw_model_on(c: CanvasItem) -> void:
	ExtArt.humanoid(c, art_state(), CFG)


static func draw_portrait(c: CanvasItem, t: float) -> void:
	ExtArt.humanoid(c, {"t": t, "pose": "idle"}, CFG)
