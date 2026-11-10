class_name OvenOwner
extends ExtEnemy
## OVEN OWNER (FM3, The Forge). A huge, slow brute carrying a burning iron OVEN on his back.
##   Oven Blast   6 dmg   opens the oven: a big fireball flies forward
##   Fire Shield  -       the oven roars: for 2.5 s he takes 70% less damage and burns
##                        everyone who stands next to him (2 per tick)
##   Body Slam    7 dmg   throws his weight at you

const HOT := Color(1.0, 0.5, 0.12)
const CFG := {"head": "worker", "oven": true, "w": 1.35, "h": 1.1, "skin": Color(0.68, 0.48, 0.38),
	"cloth": Color(0.36, 0.26, 0.20), "cloth_hi": Color(0.50, 0.36, 0.26), "trim": Color(0.22, 0.2, 0.2),
	"eye": Color(1.0, 0.55, 0.2), "weapon": "none"}

var _burn_t := 0.0


func _make_data() -> CharacterData:
	keep_min = 0.0
	keep_max = 260.0
	attack_chance = 0.6
	phase2_threshold = -1.0
	var d := SimpleEnemy.make_data("Oven Owner", 55, Vector2(84, 160), 110.0)
	d.hitstun_time = 0.1
	return d


func _ready() -> void:
	super._ready()
	knockback_scale = 0.6


static func make_patterns() -> Array[EnemyPattern]:
	var list: Array[EnemyPattern] = []
	list.append(EnemyPattern.make("blast", "OVEN BLAST!", 3.0, 6, 0.0, 520.0, "blast", 0.55, 0.2, 0.45, true, [2.0, 2.0]))
	list.append(EnemyPattern.make("shield", "FIRE SHIELD!", 8.0, 2, 0.0, 300.0, "guard", 0.3, 2.5, 0.3, true, [1.2, 1.2], true))
	list.append(EnemyPattern.make("slam", "BODY SLAM", 3.5, 7, 0.0, 120.0, "slam", 0.45, 0.25, 0.5, false, [1.4, 1.4]))
	list[1].note = "70% less damage + burns you when you are next to him"
	return list


func flavor_lines() -> Array[String]:
	return ["*the oven roars*", "Bread's done. YOU'RE next.", "HOT!"]


func _attack(p: EnemyPattern) -> void:
	match p.id:
		"blast":
			shot("fireball", Vector2(50, -100), 460.0, 1.6, Vector2(60, 60), dmg(p), Vector2(300, -220), HOT, "oven_blast", true)
			Effects.explosion(self, global_position + Vector2(facing * 50.0, -100.0), 40.0, true, true)
			SoundManager.play_sfx("flame", -2.0)
		"shield":
			shield_mult = 0.3
			_burn_t = 0.0
			SoundManager.play_sfx("flame")
		"slam":
			melee(dmg(p), Vector2(380, -240), Vector2(40, -60), Vector2(110, 120), "body_slam")
			velocity.x = facing * 300.0
			Effects.shake(self, 5.0)
			SoundManager.play_sfx("slam", -4.0)


func _on_attack_update(p: EnemyPattern, delta: float) -> void:
	if p.id == "shield":
		_burn_t -= delta
		if _burn_t <= 0.0:
			_burn_t = 0.5
			hit_in_radius(global_position + Vector2(0, -70), 95.0, dmg(p), Vector2(120, -100), "fire_shield")


func _on_attack_end(p: EnemyPattern) -> void:
	if p.id == "shield":
		shield_mult = 1.0


func _cancel_pattern() -> void:
	shield_mult = 1.0
	super._cancel_pattern()


func draw_model_on(c: CanvasItem) -> void:
	ExtArt.humanoid(c, art_state(), CFG)
	if pose == "guard":                                   # The fire shield
		var a := 0.35 + 0.15 * sin(anim_time * 20.0)
		c.draw_circle(Vector2(0, -80), 90.0, Color(HOT.r, HOT.g, HOT.b, a * 0.4))
		c.draw_arc(Vector2(0, -80), 90.0, 0.0, TAU, 28, Color(HOT.r, HOT.g, HOT.b, a + 0.3), 5.0, true)


static func draw_portrait(c: CanvasItem, t: float) -> void:
	ExtArt.humanoid(c, {"t": t, "pose": "idle"}, CFG)
