class_name VoidSpider
extends ExtEnemy
## VOID SPIDERS (VM3, the deep Void). One class, three kinds (set `kind` before adding it):
##   "shooter"   Shooter Spider: keeps its distance, shoots web / void bolts (3 dmg)
##   "biter"     Biter Spider: fast, bites (4) and lunges (5)
##   "venom"     Venomous Spider: poison bite (4) that leaves a poison pool, venom spit (3 + pool)

const KINDS := {
	"shooter": {"name": "Shooter Spider", "hp": 18, "speed": 200.0, "keep": Vector2(280, 520),
		"art": {"body": Color(0.14, 0.10, 0.20), "mark": Color(0.7, 0.75, 1.0), "eyes": Color(0.8, 0.85, 1.0), "size": 0.9}},
	"biter": {"name": "Biter Spider", "hp": 16, "speed": 320.0, "keep": Vector2(0, 160),
		"art": {"body": Color(0.10, 0.05, 0.08), "mark": Color(0.85, 0.15, 0.2), "eyes": Color(1.0, 0.2, 0.2), "size": 0.85}},
	"venom": {"name": "Venomous Spider", "hp": 22, "speed": 230.0, "keep": Vector2(60, 300),
		"art": {"body": Color(0.08, 0.14, 0.06), "mark": Color(0.45, 0.95, 0.2), "eyes": Color(0.6, 1.0, 0.3), "size": 1.0, "sac": true}},
}
const WEB := Color(0.85, 0.85, 1.0)
const VENOM := Color(0.5, 1.0, 0.25)

var kind := "biter"
var _air := false


func _make_data() -> CharacterData:
	var k: Dictionary = KINDS.get(kind, KINDS["biter"])
	keep_min = (k["keep"] as Vector2).x
	keep_max = (k["keep"] as Vector2).y
	attack_chance = 0.7
	phase2_threshold = -1.0
	var d := SimpleEnemy.make_data(String(k["name"]), int(k["hp"]), Vector2(70, 40), float(k["speed"]))
	d.respawn_delay = 1.0
	return d


## All three kinds' moves (each kind only uses its own: wants_pattern).
static func make_patterns() -> Array[EnemyPattern]:
	var list: Array[EnemyPattern] = []
	list.append(EnemyPattern.make("web_bolt", "WEB BOLT", 2.0, 3, 150.0, 750.0, "spit", 0.4, 0.2, 0.35, false, [2.0, 2.0]))
	list.append(EnemyPattern.make("bite", "BITE", 1.2, 4, 0.0, 70.0, "bite", 0.15, 0.12, 0.3, false, [1.6, 1.6]))
	list.append(EnemyPattern.make("lunge", "LUNGE", 2.4, 5, 70.0, 260.0, "bite", 0.35, 0.6, 0.45, false, [2.0, 2.0]))
	list.append(EnemyPattern.make("poison_bite", "POISON BITE", 1.6, 4, 0.0, 80.0, "bite", 0.2, 0.15, 0.35, false, [1.6, 1.6]))
	list.append(EnemyPattern.make("venom_spit", "VENOM SPIT", 3.2, 3, 120.0, 600.0, "spit", 0.45, 0.2, 0.4, false, [1.4, 1.4]))
	list[3].note = "leaves a poison pool"
	list[4].note = "the spit leaves a poison pool"
	return list


func wants_pattern(p: EnemyPattern) -> bool:
	match kind:
		"shooter":
			return p.id == "web_bolt"
		"venom":
			return p.id == "poison_bite" or p.id == "venom_spit"
	return p.id == "bite" or p.id == "lunge"


func _attack(p: EnemyPattern) -> void:
	match p.id:
		"web_bolt":
			shot("void_bolt", Vector2(30, -26), 540.0, 1.8, Vector2(28, 28), dmg(p), Vector2(140, -100), WEB, "web_bolt")
			SoundManager.play_sfx("splash", -10.0)
		"bite", "poison_bite":
			melee(dmg(p), Vector2(160, -90), Vector2(36, -18), Vector2(46, 34), "spider_bite")
			SoundManager.play_sfx("bite", -8.0)
			if p.id == "poison_bite":
				pool_at(global_position.x + facing * 40.0, 80.0, 3.0, "poison")
		"lunge":
			var dx := absf(target_x() - global_position.x)
			velocity = Vector2(facing * clampf(dx * 2.3, 320.0, 660.0), -300.0)
			_air = false
			melee(dmg(p), Vector2(220, -140), Vector2(18, -20), Vector2(60, 36), "spider_lunge")
		"venom_spit":
			lob("chem_glob", Vector2(24, -30), clamp_to_ground(target_x(), 40.0), 0.7, dmg(p), Vector2(120, -120), 40.0, VENOM, "venom_spit",
				func(pos: Vector2) -> void: pool_at(pos.x, 110.0, 3.5, "poison"))
			SoundManager.play_sfx("splash", -8.0)


func _on_attack_update(p: EnemyPattern, _delta: float) -> void:
	if p.id != "lunge":
		return
	if not is_on_floor():
		_air = true
	elif _air:
		state_time = state_len


func _owns_velocity_x() -> bool:
	return estate == EState.ATTACK and current != null and current.id == "lunge"


func draw_model_on(c: CanvasItem) -> void:
	ExtArt.spider(c, art_state(), (KINDS.get(kind, KINDS["biter"]) as Dictionary)["art"])


static func draw_portrait(c: CanvasItem, t: float) -> void:
	ExtArt.spider(c, {"t": t, "pose": "idle"}, KINDS["venom"]["art"])


static func draw_kind(c: CanvasItem, t: float, k: String) -> void:
	ExtArt.spider(c, {"t": t, "pose": "idle"}, KINDS[k]["art"])
