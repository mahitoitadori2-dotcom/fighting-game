class_name Satan
extends C5Boss
## SATAN - BOSS 6 of Colosseum 5 (Level 49, his Mountain Cave). After Mother Nature you climb
## the mountain; in a cave of fire and lava near the top, Satan waits on a throne of black rock.
## A giant demon lord: crimson skin, black goat horns, a crown of fire, bat wings folded like a
## cloak, a burning trident.
##
##   Hellfire        8 dmg   pillars of hellfire erupt under you, one after another
##   Fire Breath     3 dmg/  a long stream of fire along the floor
##   Trident Thrust 10 dmg   a long thrust of the burning trident
##   Meteor Rain     6 dmg   balls of magma fall from the cave ceiling (they leave lava)
##   Ground Slam    11 dmg   leaps and crashes down: lava pools around it
##   Summon Imps     -       calls 2 IMPS (small flying demons that swoop at you)
##   Summon Parasites -      calls 3 PARASITES (they crawl and bite)
##   Inferno        7 dmg    ENRAGED only: hellfire across the whole cave + a meteor storm

const RED := Color(0.62, 0.08, 0.06)
const RED_SHADE := Color(0.38, 0.03, 0.03)
const RED_HI := Color(0.85, 0.22, 0.14)
const HORN := Color(0.10, 0.08, 0.08)
const GOLD := Color(1.0, 0.75, 0.2)
const FIRE := Color(1.0, 0.5, 0.1)

var _breath_t := 0.0
var _air := false


func boss_forms() -> Array:
	return [{"name": "Satan", "title": "SATAN   -   LORD OF THE MOUNTAIN CAVE", "hp": 720, "body": Vector2(150, 280), "speed": 170.0}]


func setup_boss() -> void:
	keep_min = 140.0
	keep_max = 380.0
	attack_chance = 0.78
	art_scale = 1.35
	chain_chance = 0.45
	max_minions = 5
	tags = {"hellfire": ["anti_air", "ranged"], "breath": ["ranged", "counter"], "trident": ["close", "counter"],
		"meteors": ["ranged", "anti_air"], "slam": ["escape", "close"], "imps": ["ranged"], "parasites": ["ranged"], "inferno": ["ranged"]}
	combos = {"trident": ["breath", "slam"], "slam": ["hellfire", "trident"], "breath": ["meteors"], "hellfire": ["trident"],
		"imps": ["meteors"], "parasites": ["hellfire"]}


static func make_patterns() -> Array[EnemyPattern]:
	var list: Array[EnemyPattern] = []
	#                          id           name               cd    dmg  min    max     anim       tele  active rec   big   weights armored
	list.append(EnemyPattern.make("hellfire", "HELLFIRE!", 4.0, 8, 0.0, 1400.0, "raise", 0.55, 0.40, 0.45, true, [1.8], true))
	list.append(EnemyPattern.make("breath", "FIRE BREATH!", 4.5, 3, 0.0, 800.0, "breath", 0.60, 1.10, 0.55, true, [1.5], true))
	list.append(EnemyPattern.make("trident", "TRIDENT THRUST!", 2.4, 10, 0.0, 330.0, "thrust", 0.45, 0.25, 0.50, true, [2.0], true))
	list.append(EnemyPattern.make("meteors", "METEOR RAIN!", 5.5, 6, 0.0, 1400.0, "raise", 0.60, 0.40, 0.50, true, [1.3], true))
	list.append(EnemyPattern.make("slam", "GROUND SLAM!", 5.0, 11, 120.0, 800.0, "leap", 0.50, 1.40, 0.60, true, [1.3], true))
	list.append(EnemyPattern.make("imps", "RISE, MY IMPS!", 9.0, 0, 0.0, 1400.0, "summon", 0.70, 0.40, 0.50, true, [1.0], true))
	list.append(EnemyPattern.make("parasites", "CRAWL, MY CHILDREN!", 11.0, 0, 0.0, 1400.0, "summon", 0.70, 0.40, 0.50, true, [0.9], true))
	list.append(EnemyPattern.make("inferno", "INFERNO!", 12.0, 7, 0.0, 1600.0, "raise", 0.80, 0.60, 0.70, true, [1.4], true))
	list[1].note = "a stream of fire along the floor"
	list[3].note = "magma falls and leaves lava pools"
	list[7].note = "enraged only"
	return list


func wants_pattern(p: EnemyPattern) -> bool:
	if p.id == "inferno":
		return raging
	if p.id == "imps" or p.id == "parasites":
		_prune_minions()
		return minions.size() < max_minions - 1
	return true


func flavor_lines() -> Array[String]:
	return ["You climbed all this way... to DIE?", "*a laugh that shakes the cave*", "Burn, little hero.", "The Sun cannot save you."]


func _attack(p: EnemyPattern) -> void:
	var tx := target_x()
	match p.id:
		"hellfire":
			for k in 4:
				hazard("hellfire", tx + float(k) * float(facing) * 130.0 - float(facing) * 130.0, 0.5 + 0.18 * float(k), dmg(p))
			SoundManager.play_sfx("flame")
		"breath":
			_breath_t = 0.0
			SoundManager.play_sfx("flame")
			SoundManager.play_sfx("roar", -8.0)
		"trident":
			swing(dmg(p), Vector2(460, -260), Vector2(230, -150), Vector2(300, 70), "trident")
			velocity.x = facing * 260.0
			SoundManager.play_sfx("sword_slash")
		"meteors":
			for k in 5:
				var x := clamp_arena(tx + float(k - 2) * 160.0 + randf_range(-30.0, 30.0))
				lob("magma", Vector2(x + randf_range(-120.0, 120.0), floor_y() - 900.0), x, 0.7 + 0.12 * float(k), dmg(p), Vector2(220, -220), 60.0, Color.WHITE, "meteor", _on_meteor)
			Effects.shake(self, 8.0)
			SoundManager.play_sfx("rumble")
		"slam":
			_air = false
			leap_to(tx, 0.75, 340.0)
			SoundManager.play_sfx("jump")
		"imps":
			for k in 2:
				summon("imp", global_position + Vector2(float(k * 2 - 1) * 160.0, -280.0))
			SoundManager.play_sfx("spawn")
			SoundManager.play_sfx("roar", -6.0)
		"parasites":
			for k in 3:
				summon("parasite", Vector2(clamp_arena(global_position.x + float(k - 1) * 200.0), floor_y() - 40.0))
			SoundManager.play_sfx("spawn")
		"inferno":
			var l := StoryManager.wall_left_x + 80.0
			var r := StoryManager.wall_right_x - 80.0
			var n := 9
			for k in n:
				hazard("hellfire", lerpf(l, r, float(k) / float(n - 1)), 0.6 + 0.08 * float(k % 3) + (0.5 if k % 2 == 1 else 0.0), dmg(p))
			for k in 4:
				var x := clamp_arena(tx + float(k - 2) * 220.0)
				lob("magma", Vector2(x, floor_y() - 900.0), x, 1.4 + 0.15 * float(k), dmg(p), Vector2(220, -220), 60.0, Color.WHITE, "meteor", _on_meteor)
			Effects.shake(self, 16.0)
			SoundManager.play_sfx("roar")
			SoundManager.play_sfx("flame")


func _on_meteor(pos: Vector2) -> void:
	if is_instance_valid(self) and not is_dead:
		ChemicalPool.spawn_lava(self, pos, 110.0, 4.0)


func _on_attack_update(p: EnemyPattern, delta: float) -> void:
	match p.id:
		"breath":
			_breath_t -= delta
			if _breath_t <= 0.0:
				_breath_t = 0.1
				shoot("fireball", global_position + Vector2(facing * 170.0, -130.0 + randf_range(-16.0, 16.0)), float(facing), 640.0, 1.0,
					Vector2(44, 48), dmg(p), Vector2(160, -90), Color.WHITE, "satan_breath")
		"slam":
			if not is_on_floor():
				_air = true
			elif _air:
				_air = false
				hit_in_radius(global_position + Vector2(0, -60), 220.0, dmg(p), Vector2(460, -420), "satan_slam")
				for off: float in [-220.0, 220.0]:
					var g: Variant = Effects.ground_below(self, Vector2(global_position.x + off, global_position.y - 40.0), 200.0)
					if g != null:
						ChemicalPool.spawn_lava(self, g, 150.0, 4.5)
				Effects.explosion(self, global_position + Vector2(0, -40), 220.0, true, true)
				Effects.shake(self, 18.0)
				SoundManager.play_sfx("slam")
				velocity.x = 0.0
				state_time = state_len


func _on_attack_end(p: EnemyPattern) -> void:
	if p.id == "slam" or p.id == "trident":
		velocity.x = 0.0


func _owns_velocity_x() -> bool:
	return estate == EState.ATTACK and current != null and current.id == "slam"


# ============================================================
# ART (facing right, origin = feet, ~200 x 300 art units)
# ============================================================
func draw_model_on(c: CanvasItem) -> void:
	draw_satan(c, art_state())


static func draw_portrait(c: CanvasItem, t: float) -> void:
	draw_satan(c, {"t": t, "pose": "idle"})


static func draw_satan(c: CanvasItem, s: Dictionary) -> void:
	var t: float = s.get("t", 0.0)
	var pose: String = s.get("pose", "idle")
	var dead: bool = s.get("dead", false)
	var raging: bool = s.get("raging", false)
	# Wings folded like a cloak (spread when summoning / raging)
	var spread := 1.0 + (0.6 if pose.begins_with("summon") or raging else 0.0)
	for sgn: float in [-1.0, 1.0]:
		var base := Vector2(sgn * 20.0 - 10.0, -230)
		var wing := PackedVector2Array([base, base + Vector2(sgn * 80.0 * spread - 40.0, -90), base + Vector2(sgn * 60.0 * spread - 30.0, -30),
			base + Vector2(sgn * 110.0 * spread - 50.0, 10), base + Vector2(sgn * 60.0 * spread - 30.0, 60), base + Vector2(sgn * 70.0 * spread - 30.0, 150), base + Vector2(sgn * 10.0, 160)])
		c.draw_colored_polygon(wing, Color(0.18, 0.03, 0.04))
		FighterArt.outline(c, wing, 3.5)
	EnemyArt.legs(c, s, -110.0, 22.0, 22.0, RED, RED_SHADE, RED_HI, HORN, 30.0)
	var chest := Vector2(0, -180 + sin(t * 1.5) * 2.0)
	# The burning trident (behind)
	var hand := chest + Vector2(40, 40)
	var d := Vector2(0.15, -1.0).normalized()
	match pose:
		"thrust_tele":
			hand = chest + Vector2(-20, 20)
			d = Vector2.RIGHT
		"thrust":
			hand = chest + Vector2(90, 20)
			d = Vector2.RIGHT
		"raise", "raise_tele", "summon":
			hand = chest + Vector2(30, -80)
			d = Vector2(0.1, -1.0).normalized()
	var butt := hand - d * 120.0
	var tip := hand + d * 150.0
	c.draw_line(butt, tip, EnemyArt.BLACK, 10.0, true)
	c.draw_line(butt, tip, Color(0.25, 0.22, 0.2), 6.0, true)
	var n := d.orthogonal()
	for k: float in [-1.0, 0.0, 1.0]:
		var prong := tip + n * k * 20.0
		c.draw_line(tip - d * 10.0 + n * k * 20.0, prong + d * (30.0 if k == 0.0 else 22.0), EnemyArt.BLACK, 7.0)
		c.draw_line(tip - d * 10.0 + n * k * 20.0, prong + d * (30.0 if k == 0.0 else 22.0), GOLD, 4.0)
	c.draw_line(tip - d * 10.0 + n * 20.0, tip - d * 10.0 - n * 20.0, GOLD, 5.0)
	for i in 4:                                                    # Flames licking the prongs
		var fp := tip + d * 30.0 + n * (float(i) - 1.5) * 12.0
		var fh := 18.0 + 10.0 * sin(t * 9.0 + float(i))
		c.draw_colored_polygon(PackedVector2Array([fp - n * 6.0, fp + d * fh, fp + n * 6.0]), Color(1.0, 0.55, 0.1, 0.85))
	EnemyArt.arm(c, chest + Vector2(-40, -50), hand, 22.0, RED, RED_SHADE, RED_HI, RED_SHADE, 15.0)
	# Massive crimson torso
	var torso := PackedVector2Array([chest + Vector2(-62, -66), chest + Vector2(64, -66), chest + Vector2(46, 76), chest + Vector2(-46, 76)])
	c.draw_polygon(torso, PackedColorArray([RED_HI, RED, RED_SHADE, RED_SHADE]))
	FighterArt.outline(c, torso, 5.0)
	for k in 3:                                                    # Muscle lines / runes glowing
		c.draw_line(chest + Vector2(-30.0 + float(k) * 30.0, -30), chest + Vector2(-26.0 + float(k) * 26.0, 40), Color(1.0, 0.5, 0.1, 0.5), 3.0)
	FighterArt.ball(c, chest + Vector2(-56, -60), 20.0, RED, RED_SHADE, RED_HI)
	var front_hand := chest + Vector2(60, 40)
	if pose == "breath" or pose.begins_with("summon"):
		front_hand = chest + Vector2(90, -40)
	EnemyArt.arm(c, chest + Vector2(52, -54), front_hand, 22.0, RED, RED_SHADE, RED_HI, RED_SHADE, 15.0)
	if pose.begins_with("summon"):
		c.draw_circle(front_hand, 30.0, Color(1.0, 0.4, 0.1, 0.5))
	# Head: goat horns, a crown of fire, a wicked grin
	var head := chest + Vector2(10, -104)
	for sgn: float in [-1.0, 1.0]:
		var hb := head + Vector2(sgn * 16.0, -16)
		var curl := PackedVector2Array([hb, hb + Vector2(sgn * 30.0, -30), hb + Vector2(sgn * 34.0, -70), hb + Vector2(sgn * 20.0, -100)])
		c.draw_polyline(curl, EnemyArt.BLACK, 16.0, true)
		c.draw_polyline(curl, HORN.lightened(0.15), 10.0, true)
	for k in 7:
		var x := -36.0 + float(k) * 12.0
		var fh := 26.0 + 14.0 * absf(sin(t * 7.0 + float(k)))
		c.draw_colored_polygon(PackedVector2Array([head + Vector2(x - 8, -24), head + Vector2(x, -24 - fh), head + Vector2(x + 8, -24)]), Color(1.0, 0.6 - float(k % 2) * 0.15, 0.1, 0.9))
	FighterArt.ball(c, head, 32.0, RED, RED_SHADE, RED_HI)
	c.draw_colored_polygon(PackedVector2Array([head + Vector2(-6, 20), head + Vector2(10, 40), head + Vector2(24, 20)]), HORN)     # Goatee
	if dead:
		EnemyArt.ko_eye(c, head + Vector2(14, -6), 5.0, t)
	else:
		for ex: float in [2.0, 20.0]:
			c.draw_colored_polygon(PackedVector2Array([head + Vector2(ex - 7, -8), head + Vector2(ex + 7, -10), head + Vector2(ex + 4, -2)]), GOLD)
	var open := 10.0 if pose == "breath" else 2.0
	c.draw_colored_polygon(PackedVector2Array([head + Vector2(-4, 10), head + Vector2(26, 6), head + Vector2(22, 10 + open), head + Vector2(0, 14 + open)]), Color(0.1, 0.0, 0.0))
	if pose == "breath":
		c.draw_circle(head + Vector2(34, 12), 18.0, Color(1.0, 0.6, 0.15, 0.7))
