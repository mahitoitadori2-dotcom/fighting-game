class_name SaintGolem
extends C5Boss
## SAINT ARCHITECT'S GOLEM - final boss of the Architect's Golem extension (AG4, the Saint
## Sanctum). The Architect's Golem rebuilt with ARCHITECT METAL: saint-rock body, white-silver
## metal plates bolted over it, glowing RUNES, and the Architect's hexagon with a blue core in
## its chest. It combines the runes with the Architectian powers.
##
##   Golem Slam           9 dmg   fists into the floor: shockwaves both ways (jump them)
##   Rune Blast           5 dmg   three runes fly at you at different heights
##   Architectian Power   7 dmg   a huge wave of power rolls along the floor + a pillar under you
##   Metal Shard Throw    5 dmg   rips off metal shards and throws them
##   Rune Shield          -       runes surround it: 75% less damage for a few seconds

const ROCK := Color(0.60, 0.57, 0.52)
const ROCK_SHADE := Color(0.42, 0.40, 0.37)
const METAL := Color(0.90, 0.92, 0.95)
const METAL_SHADE := Color(0.62, 0.66, 0.72)
const RUNE := Color(0.45, 0.95, 1.0)
const CORE := Color(0.25, 0.70, 1.0)
const GREEN := Color(0.3, 0.9, 0.4)

var _shield := false


func boss_forms() -> Array:
	return [{"name": "Saint Architect's Golem", "title": "SAINT ARCHITECT'S GOLEM", "hp": 500, "body": Vector2(170, 300), "speed": 95.0}]


func setup_boss() -> void:
	keep_min = 60.0
	keep_max = 320.0
	attack_chance = 0.75
	chain_chance = 0.4
	tags = {"slam": ["close", "counter"], "runes": ["ranged"], "power": ["ranged", "anti_air"], "shards": ["ranged"], "shield": ["counter"]}
	combos = {"slam": ["power", "runes"], "runes": ["shards"], "shards": ["slam"], "power": ["runes"]}


static func make_patterns() -> Array[EnemyPattern]:
	var list: Array[EnemyPattern] = []
	list.append(EnemyPattern.make("slam", "GOLEM SLAM!", 3.0, 9, 0.0, 260.0, "slam", 0.6, 0.25, 0.55, true, [2.0, 2.2], true))
	list.append(EnemyPattern.make("runes", "RUNE BLAST!", 4.0, 5, 150.0, 1100.0, "cast", 0.5, 0.3, 0.45, true, [1.6, 1.8], true))
	list.append(EnemyPattern.make("power", "ARCHITECTIAN POWER!", 6.0, 7, 0.0, 1100.0, "power", 0.7, 0.4, 0.55, true, [1.2, 1.6], true))
	list.append(EnemyPattern.make("shards", "METAL SHARDS!", 5.0, 5, 120.0, 900.0, "cast", 0.5, 0.3, 0.45, true, [1.3, 1.5], true))
	list.append(EnemyPattern.make("shield", "RUNE SHIELD!", 11.0, 0, 0.0, 1200.0, "shield", 0.4, 3.0, 0.4, true, [0.8, 1.2], true))
	list[0].note = "shockwaves: jump them"
	list[2].note = "a wave along the floor + a pillar under you"
	list[4].note = "75% less damage for 3 s"
	return list


func flavor_lines() -> Array[String]:
	return ["...SANCTIFIED.", "...THE ARCHITECT... REBUILT ME.", "*runes hum*"]


func _attack(p: EnemyPattern) -> void:
	match p.id:
		"slam":
			hit_in_radius(global_position + Vector2(facing * 100.0, -40.0), 160.0, dmg(p), Vector2(380, -360), "golem_slam")
			for d: float in [-1.0, 1.0]:
				shoot("shock", Vector2(global_position.x + d * 130.0, floor_y() - 20.0), d, 540.0, 1.0, Vector2(56, 44), dmg(p) - 3, Vector2(260, -340), RUNE, "golem_wave", true)
			Effects.shake(self, 16.0)
			SoundManager.play_sfx("slam")
			SoundManager.play_sfx("stone", -3.0)
		"runes":
			for k in (4 if raging else 3):
				shoot("rune", global_position + Vector2(facing * 90.0, -240.0 + float(k) * 70.0), float(facing), 520.0 + float(k) * 50.0, 2.4, Vector2(40, 40), dmg(p), Vector2(200, -140), RUNE, "rune_blast")
			SoundManager.play_sfx("holy", -4.0)
		"power":
			for d: float in [-1.0, 1.0]:
				shoot("shock", Vector2(global_position.x + d * 100.0, floor_y() - 30.0), d, 620.0, 1.3, Vector2(80, 70), dmg(p), Vector2(300, -380), GREEN, "architectian_power", true)
			hazard("pillar", target_x(), 0.7, dmg(p))
			Effects.shake(self, 10.0)
			Effects.gold_burst(self, global_position + Vector2(0, -150), 120.0)
			SoundManager.play_sfx("beam")
		"shards":
			var tx := target_x()
			for k in (4 if raging else 3):
				lob("scrap", global_position + Vector2(facing * 60.0, -260.0), clamp_arena(tx + float(k - 1) * 110.0), 0.7 + 0.1 * float(k), dmg(p), Vector2(200, -200), 44.0, METAL, "metal_shard")
			SoundManager.play_sfx("swing")
		"shield":
			_shield = true
			SoundManager.play_sfx("holy")
			Effects.popup(self, global_position + Vector2(0, -340), "RUNE SHIELD", RUNE, 24)


func _on_attack_end(p: EnemyPattern) -> void:
	if p.id == "shield":
		_shield = false


func _cancel_pattern() -> void:
	_shield = false
	super._cancel_pattern()


func take_hit(amount: int, hit: HitData) -> void:
	if _shield and amount > 0:
		amount = maxi(1, roundi(float(amount) * 0.25))
	super.take_hit(amount, hit)


# ============================================================
# ART (facing right, origin = feet, ~220 x 320)
# ============================================================
func art_state() -> Dictionary:
	var s := super.art_state()
	s["shield"] = _shield
	return s


func draw_model_on(c: CanvasItem) -> void:
	draw_golem(c, art_state())


static func draw_portrait(c: CanvasItem, t: float) -> void:
	draw_golem(c, {"t": t, "pose": "idle"})


static func draw_golem(c: CanvasItem, s: Dictionary) -> void:
	var t: float = s.get("t", 0.0)
	var pose: String = s.get("pose", "idle")
	var dead: bool = s.get("dead", false)
	var rage: bool = s.get("raging", false)
	var glow := 0.65 + 0.35 * sin(t * (8.0 if rage else 3.0))
	var rune := Color(RUNE.r, RUNE.g, RUNE.b, glow)
	if rage:
		EnemyArt.aura(c, Vector2(0, -160), 150.0, RUNE, t)
	# Legs: thick stone pillars with metal greaves
	for i in 2:
		var x := -40.0 if i == 0 else 30.0
		var col := ROCK_SHADE if i == 0 else ROCK
		FighterArt.rrect(c, Rect2(x - 22, -110, 44, 108), col, ROCK_SHADE.darkened(0.2), ROCK.lightened(0.1), 10.0, 4.5)
		FighterArt.rrect(c, Rect2(x - 25, -70, 50, 32), METAL_SHADE if i == 0 else METAL, METAL_SHADE.darkened(0.2), Color.WHITE, 6.0, 3.5)
		c.draw_line(Vector2(x - 8, -95), Vector2(x + 8, -80), rune, 3.0)
	# Arms by pose
	var lh := Vector2(-96, -110)
	var rh := Vector2(96, -110)
	match pose:
		"slam_tele":
			lh = Vector2(-50, -330)
			rh = Vector2(60, -335)
		"slam":
			lh = Vector2(60, -20)
			rh = Vector2(130, -20)
		"cast_tele", "cast":
			rh = Vector2(120, -230)
		"power_tele", "power":
			lh = Vector2(-120, -250)
			rh = Vector2(120, -250)
		"shield_tele", "shield":
			lh = Vector2(-60, -200)
			rh = Vector2(70, -200)
	FighterArt.limb(c, Vector2(-70, -240), lh, 34.0, ROCK_SHADE, ROCK_SHADE.darkened(0.2), ROCK)
	FighterArt.ball(c, lh, 30.0, METAL_SHADE, METAL_SHADE.darkened(0.25), METAL)
	# Torso: stone core, metal chest plates, the Architect's hexagon + blue core
	var torso := PackedVector2Array([Vector2(-88, -260), Vector2(90, -262), Vector2(76, -120), Vector2(-74, -118)])
	c.draw_colored_polygon(torso, ROCK)
	FighterArt.outline(c, torso, 5.0)
	var plate := PackedVector2Array([Vector2(-70, -250), Vector2(72, -252), Vector2(58, -150), Vector2(-56, -148)])
	c.draw_colored_polygon(plate, METAL)
	c.draw_colored_polygon(PackedVector2Array([Vector2(-70, -250), Vector2(-40, -251), Vector2(-30, -149), Vector2(-56, -148)]), METAL_SHADE)
	FighterArt.outline(c, plate, 4.0)
	for b: Vector2 in [Vector2(-60, -240), Vector2(62, -242), Vector2(-48, -158), Vector2(50, -160)]:
		c.draw_circle(b, 4.0, METAL_SHADE.darkened(0.3))
	var hex := PackedVector2Array()
	for k in 6:
		hex.append(Vector2(4, -200) + Vector2.from_angle(float(k) * TAU / 6.0 + PI / 6.0) * 30.0)
	c.draw_colored_polygon(hex, Color(0.12, 0.14, 0.18))
	FighterArt.outline(c, hex, 3.5, rune)
	c.draw_circle(Vector2(4, -200), 18.0 + 3.0 * glow, Color(CORE.r, CORE.g, CORE.b, 0.35))
	c.draw_circle(Vector2(4, -200), 12.0, CORE)
	c.draw_circle(Vector2(0, -204), 4.0, Color.WHITE)
	# Runes carved down the stone sides
	for k in 3:
		c.draw_line(Vector2(-82, -240 + float(k) * 40.0), Vector2(-74, -222 + float(k) * 40.0), rune, 3.0)
		c.draw_line(Vector2(84, -240 + float(k) * 40.0), Vector2(76, -222 + float(k) * 40.0), rune, 3.0)
	# Head: stone block with a metal crest and a glowing rune visor
	var head := Vector2(6, -292)
	FighterArt.rrect(c, Rect2(head.x - 34, head.y - 30, 68, 56), ROCK, ROCK_SHADE, ROCK.lightened(0.1), 10.0, 4.5)
	c.draw_colored_polygon(PackedVector2Array([head + Vector2(-20, -30), head + Vector2(20, -30), head + Vector2(0, -56)]), METAL)
	FighterArt.outline(c, PackedVector2Array([head + Vector2(-20, -30), head + Vector2(20, -30), head + Vector2(0, -56)]), 3.0)
	if dead:
		EnemyArt.ko_eye(c, head + Vector2(10, -4), 6.0, t)
	else:
		c.draw_rect(Rect2(head.x - 20, head.y - 8, 44, 10), Color(0.05, 0.05, 0.08))
		c.draw_rect(Rect2(head.x - 14, head.y - 6, 32, 6), rune)
	# Front arm
	FighterArt.limb(c, Vector2(76, -244), rh, 36.0, ROCK, ROCK_SHADE, ROCK.lightened(0.15))
	FighterArt.rrect(c, Rect2(Vector2(76, -244).lerp(rh, 0.45) - Vector2(26, 18), Vector2(52, 36)), METAL, METAL_SHADE, Color.WHITE, 8.0, 3.5)
	FighterArt.ball(c, rh, 32.0, METAL, METAL_SHADE, Color.WHITE)
	c.draw_circle(rh, 8.0, rune)
	if pose.begins_with("cast") or pose.begins_with("power"):
		c.draw_circle(rh, 20.0 + 6.0 * sin(t * 20.0), Color(RUNE.r, RUNE.g, RUNE.b, 0.4))
	if s.get("shield", false) or pose == "shield_tele":
		for k in 8:                                         # Ring of runes around it
			var a := t * 1.5 + float(k) * TAU / 8.0
			var p := Vector2(0, -170) + Vector2(cos(a) * 150.0, sin(a) * 180.0)
			c.draw_rect(Rect2(p - Vector2(10, 14), Vector2(20, 28)), Color(RUNE.r, RUNE.g, RUNE.b, 0.55))
			c.draw_line(p - Vector2(6, 8), p + Vector2(6, 8), Color.WHITE, 2.0)
