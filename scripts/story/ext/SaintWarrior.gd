class_name SaintWarrior
extends ExtEnemy
## SAINT WARRIOR (AG2 / AG3). An armored warrior of living saint-rock: stone head with a glowing
## slit, rune-marked chest, a stone hammer and a rock shield.
##   Hammer Swing  7 dmg   heavy overhead swing
##   Shield Bash   4 dmg   shoves you back
##   Rock Guard    -       raises the shield: blocks hits from the front

const CFG := {"head": "rock", "skin": Color(0.66, 0.62, 0.55), "cloth": Color(0.55, 0.52, 0.47),
	"cloth_hi": Color(0.72, 0.69, 0.62), "trim": Color(0.85, 0.7, 0.35), "eye": Color(1.0, 0.85, 0.4),
	"weapon": "hammer", "shield": Color(0.6, 0.57, 0.5), "metal": Color(0.62, 0.6, 0.55), "runes": true, "w": 1.15}


func _make_data() -> CharacterData:
	keep_min = 0.0
	keep_max = 140.0
	attack_chance = 0.65
	phase2_threshold = -1.0
	guard_ids = ["block"]
	var d := SimpleEnemy.make_data("Saint Warrior", 42, Vector2(66, 146), 150.0)
	d.hitstun_time = 0.12
	return d


static func make_patterns() -> Array[EnemyPattern]:
	var list: Array[EnemyPattern] = []
	list.append(EnemyPattern.make("hammer", "HAMMER SWING!", 2.4, 7, 0.0, 130.0, "hammer", 0.5, 0.2, 0.5, true, [2.0, 2.0]))
	list.append(EnemyPattern.make("bash", "SHIELD BASH", 3.0, 4, 0.0, 90.0, "block", 0.25, 0.2, 0.35, false, [1.2, 1.2]))
	list.append(EnemyPattern.make("block", "ROCK GUARD", 4.0, 0, 0.0, 250.0, "block", 0.05, 1.4, 0.2, false, [1.2, 1.2]))
	list[2].note = "blocks hits from the front"
	return list


func flavor_lines() -> Array[String]:
	return ["*grinding stone*", "The sanctuary is sealed.", "Kneel before the Saint Rocks."]


func _attack(p: EnemyPattern) -> void:
	match p.id:
		"hammer":
			melee(dmg(p), Vector2(300, -320), Vector2(60, -60), Vector2(100, 120), "saint_hammer")
			Effects.shake(self, 5.0)
			SoundManager.play_sfx("slam", -4.0)
		"bash":
			melee(dmg(p), Vector2(460, -160), Vector2(40, -70), Vector2(60, 110), "shield_bash")
			velocity.x = facing * 260.0
			SoundManager.play_sfx("block", -4.0)


func draw_model_on(c: CanvasItem) -> void:
	ExtArt.humanoid(c, art_state(), CFG)


static func draw_portrait(c: CanvasItem, t: float) -> void:
	ExtArt.humanoid(c, {"t": t, "pose": "idle"}, CFG)
