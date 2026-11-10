class_name CoalThrower
extends ExtEnemy
## COAL THROWER (FM3, The Forge). A wiry stoker with a sack of BURNING COAL. Stays back and
## throws coal that bursts into fire pools.
##   Coal Throw    4 dmg   one burning coal (fire pool where it lands)
##   Coal Volley   3 x3    three coals spread around you

const HOT := Color(1.0, 0.45, 0.1)
const CFG := {"head": "worker", "skin": Color(0.55, 0.42, 0.35), "cloth": Color(0.22, 0.20, 0.20),
	"cloth_hi": Color(0.32, 0.30, 0.30), "trim": Color(0.6, 0.25, 0.1), "eye": Color(1.0, 0.5, 0.2),
	"weapon": "coal", "w": 0.9}


func _make_data() -> CharacterData:
	keep_min = 240.0
	keep_max = 520.0
	attack_chance = 0.65
	phase2_threshold = -1.0
	return SimpleEnemy.make_data("Coal Thrower", 24, Vector2(56, 136), 190.0)


static func make_patterns() -> Array[EnemyPattern]:
	var list: Array[EnemyPattern] = []
	list.append(EnemyPattern.make("coal", "COAL THROW", 2.2, 4, 120.0, 700.0, "throw", 0.4, 0.2, 0.35, false, [2.0, 2.0]))
	list.append(EnemyPattern.make("volley", "COAL VOLLEY!", 5.5, 3, 120.0, 700.0, "throw", 0.55, 0.3, 0.45, true, [1.2, 1.2]))
	list[0].note = "fire pool where it lands"
	return list


func flavor_lines() -> Array[String]:
	return ["Hot coal! HOT COAL!", "*cough cough*", "Feed the fire!"]


func _attack(p: EnemyPattern) -> void:
	match p.id:
		"coal":
			_coal(p, target_x(), 0.75)
		"volley":
			var tx := target_x()
			for k in 3:
				_coal(p, tx + float(k - 1) * 120.0, 0.65 + float(k) * 0.12)
	SoundManager.play_sfx("swing", -6.0)


func _coal(p: EnemyPattern, x: float, flight: float) -> void:
	lob("magma", Vector2(20, -120), clamp_to_ground(x, 40.0), flight, dmg(p), Vector2(140, -150), 34.0, Color(0.25, 0.18, 0.15), "burning_coal",
		func(pos: Vector2) -> void: pool_at(pos.x, 80.0, 2.5, "fire"))


func draw_model_on(c: CanvasItem) -> void:
	ExtArt.humanoid(c, art_state(), CFG)


static func draw_portrait(c: CanvasItem, t: float) -> void:
	ExtArt.humanoid(c, {"t": t, "pose": "idle"}, CFG)
