class_name FirstPrime
extends C5Boss
## THE ENLIGHTENED FIRST PRIME - MINI-BOSS of The Enlightened Chase (Level 56, the Gong Sanctum).
## The Enlightened One's first warrior-mage: white-and-gold plate, a long cape, a STAFF of holy
## spells (a little sun on top) in one hand and the HOLY BLADE in the other, which sends GOLDEN
## ARCS through the air. No pre-fight: he is waiting for you. Music: gongs + choir (boss_prime).
##
##   Holy Blade        7 dmg   a big two-step slash
##   Golden Arc        5 dmg   one golden arc flies along the floor
##   Triple Arc        5 dmg   three arcs: low, middle, high (jump / duck between them)
##   Holy Smite        6 dmg   pillars of light erupt where you stand and next to you
##   Staff Nova        5 dmg   slams the staff: light bursts around him + orbs rain down
##   Blink Strike      7 dmg   vanishes and slashes from behind you
##   Gong of Judgment  6 dmg   ENRAGED: a giant gong rings, shockwaves + a sweep of pillars

const GOLD := Color(1.0, 0.82, 0.3)
const ARC_GOLD := Color(1.0, 0.85, 0.35)
const CFG := {"h": 1.35, "w": 1.25, "head": "helm", "skin": Color(0.84, 0.70, 0.55), "cloth": Color(0.95, 0.93, 0.86),
	"cloth_hi": Color(1.0, 0.98, 0.9), "trim": Color(1.0, 0.75, 0.2), "eye": Color(0.4, 0.75, 1.0),
	"weapon": "sword", "metal": Color(1.0, 0.86, 0.4), "glow": Color(1.0, 0.85, 0.4), "runes": true}

var _blink_done := false


func boss_forms() -> Array:
	return [{"name": "The Enlightened First Prime", "title": "THE ENLIGHTENED FIRST PRIME", "hp": 300, "body": Vector2(80, 190), "speed": 230.0}]


func setup_boss() -> void:
	keep_min = 140.0
	keep_max = 420.0
	attack_chance = 0.65
	chain_chance = 0.25
	art_scale = 1.0
	tags = {"blade": ["close", "counter"], "arc": ["ranged"], "arcs": ["ranged", "anti_air"], "smite": ["anti_air", "ranged"],
		"nova": ["counter", "close"], "blink": ["escape", "evade"], "gong": ["ranged"]}
	combos = {"blade": ["arc", "blink"], "arc": ["arcs", "smite"], "blink": ["blade"], "nova": ["arc", "smite"], "smite": ["arc"]}


static func make_patterns() -> Array[EnemyPattern]:
	var list: Array[EnemyPattern] = []
	#                          id       name                cd    dmg  min    max     anim     tele  active rec   big   weights armored
	list.append(EnemyPattern.make("blade", "HOLY BLADE!", 2.8, 7, 0.0, 240.0, "slash", 0.40, 0.35, 0.45, true, [2.0], true))
	list.append(EnemyPattern.make("arc", "GOLDEN ARC!", 3.2, 5, 160.0, 1200.0, "slash", 0.40, 0.25, 0.40, true, [1.8], true))
	list.append(EnemyPattern.make("arcs", "TRIPLE ARC!", 5.5, 5, 120.0, 1200.0, "slash", 0.55, 0.50, 0.45, true, [1.4], true))
	list.append(EnemyPattern.make("smite", "HOLY SMITE!", 6.0, 6, 0.0, 1200.0, "cast", 0.50, 0.40, 0.45, true, [1.3], true))
	list.append(EnemyPattern.make("nova", "STAFF NOVA!", 6.0, 5, 0.0, 380.0, "cast", 0.50, 0.35, 0.50, true, [1.2], true))
	list.append(EnemyPattern.make("blink", "BLINK STRIKE!", 7.0, 7, 0.0, 1200.0, "slash", 0.35, 0.60, 0.40, true, [1.1], true))
	list.append(EnemyPattern.make("gong", "GONG OF JUDGMENT!", 10.0, 6, 0.0, 1400.0, "cast", 0.70, 0.60, 0.55, true, [1.2], true))
	list[2].note = "low / middle / high: jump or duck between"
	list[6].note = "enraged only"
	return list


func wants_pattern(p: EnemyPattern) -> bool:
	return p.id != "gong" or raging


func flavor_lines() -> Array[String]:
	return ["*a gong rings far away*", "The Light chose HIM. Not you.", "Kneel, and it ends quickly.", "My blade is a prayer."]


func _attack(p: EnemyPattern) -> void:
	var f := float(facing)
	match p.id:
		"blade":
			swing(dmg(p), Vector2(380, -280), Vector2(80, -110), Vector2(180, 200), "holy_blade")
			Effects.hit_sparks(self, global_position + Vector2(f * 110.0, -120.0), 8, 1.2)
			SoundManager.play_sfx("sword_slash")
		"arc":
			_golden_arc(f, -60.0, dmg(p))
			SoundManager.play_sfx("sword_slash")
		"arcs":
			for k in 3:
				_golden_arc(f, [-40.0, -120.0, -215.0][k], dmg(p), 520.0 + float(k) * 60.0)
			SoundManager.play_sfx("sword_slash")
			SoundManager.play_sfx("holy", -6.0)
		"smite":
			var tx := target_x()
			for k in 3:
				hazard("pillar", tx + float(k - 1) * 170.0, 0.55 + 0.18 * float(k), dmg(p), Vector2(200, -460))
			SoundManager.play_sfx("holy")
		"nova":
			hit_in_radius(global_position + Vector2(0, -80), 170.0, dmg(p), Vector2(360, -340), "staff_nova")
			Effects.gold_burst(self, global_position + Vector2(0, -80), 170.0)
			Effects.shake(self, 10.0)
			for k in 6:
				lob("light_orb", global_position + Vector2(0, -240), clamp_arena(global_position.x + (float(k) - 2.5) * 130.0),
					0.6 + 0.06 * float(k), dmg(p), Vector2(200, -200), 40.0, ARC_GOLD, "nova_orb")
			SoundManager.play_sfx("slam")
			SoundManager.play_sfx("holy", -4.0)
		"blink":
			_blink_done = false
			Effects.gold_burst(self, global_position + Vector2(0, -90), 80.0)
			SoundManager.play_sfx("whoosh")
		"gong":
			Effects.shake(self, 16.0)
			SoundManager.play_sfx("slam")
			SoundManager.play_sfx("holy")
			for d: float in [-1.0, 1.0]:
				shoot("shock", Vector2(global_position.x + d * 70.0, floor_y() - 20.0), d, 560.0, 1.3, Vector2(54, 48), dmg(p), Vector2(240, -340), GOLD, "gong_wave", true)
			var from := StoryManager.wall_left_x + 120.0 if global_position.x > arena_center() else StoryManager.wall_right_x - 120.0
			var dir := 1.0 if from < arena_center() else -1.0
			for k in 7:
				hazard("pillar", from + dir * float(k) * 190.0, 0.8 + 0.15 * float(k), dmg(p), Vector2(200, -460))


## A golden crescent flying along at height y_off above the floor.
func _golden_arc(dir: float, y_off: float, damage: int, spd: float = 560.0) -> void:
	shoot("crescent", Vector2(global_position.x + dir * 70.0, floor_y() + y_off), dir, spd, 2.2, Vector2(46, 90), damage,
		Vector2(260, -220), ARC_GOLD, "golden_arc", true)


func _on_attack_update(p: EnemyPattern, _delta: float) -> void:
	if p.id == "blink" and not _blink_done and state_time >= 0.25:
		_blink_done = true
		var tx := target_x()
		var side := -1.0 if tx > arena_center() else 1.0                 # Appear on the far side of you
		global_position.x = clamp_arena(tx + side * 110.0)
		face_target()
		Effects.gold_burst(self, global_position + Vector2(0, -90), 80.0)
		swing(dmg(p), Vector2(380, -300), Vector2(70, -110), Vector2(170, 200), "blink_strike")
		SoundManager.play_sfx("sword_slash")


# ============================================================
# ART (facing right, origin = feet, ~120 x 260)
# ============================================================
func draw_model_on(c: CanvasItem) -> void:
	draw_prime(c, art_state())


static func draw_portrait(c: CanvasItem, t: float) -> void:
	draw_prime(c, {"t": t, "pose": "idle"})


static func draw_prime(c: CanvasItem, s: Dictionary) -> void:
	var t: float = s.get("t", 0.0)
	var pose: String = s.get("pose", "idle")
	var casting := pose.begins_with("cast")
	# Long white cape with a gold hem (behind)
	var cape := PackedVector2Array([Vector2(-10, -168), Vector2(10, -168), Vector2(-30, -6), Vector2(-62 - sin(t * 2.5) * 6.0, -12)])
	c.draw_colored_polygon(cape, Color(0.88, 0.86, 0.80))
	c.draw_line(Vector2(-30, -8), Vector2(-62 - sin(t * 2.5) * 6.0, -14), GOLD, 5.0)
	FighterArt.outline(c, cape, 4.0)
	# The holy staff in the far hand (behind the body)
	var top := Vector2(-30, -250) if not casting else Vector2(-6, -276)
	c.draw_line(Vector2(-24, -40), top, EnemyArt.BLACK, 9.0, true)
	c.draw_line(Vector2(-24, -40), top, Color(0.95, 0.85, 0.55), 5.0, true)
	var glow := 0.5 + 0.5 * sin(t * (12.0 if casting else 3.0))
	c.draw_circle(top, 22.0 + 8.0 * glow, Color(1.0, 0.85, 0.35, 0.25 + (0.25 if casting else 0.0)))
	for k in 8:                                                   # Little sun on top
		var a := TAU * float(k) / 8.0 + t
		c.draw_line(top + Vector2.from_angle(a) * 10.0, top + Vector2.from_angle(a) * 18.0, GOLD, 3.0)
	c.draw_circle(top, 10.0, Color(1.0, 0.95, 0.7))
	# The warrior-mage himself (Holy Blade in the near hand)
	ExtArt.humanoid(c, s, CFG)
	# Gold crest + pauldrons
	var head := Vector2(5, -178 + sin(t * 3.0) * 2.0)
	c.draw_colored_polygon(PackedVector2Array([head + Vector2(-4, -18), head + Vector2(4, -18), head + Vector2(10, -44), head + Vector2(-8, -40)]), GOLD)
	for x: float in [-20.0, 16.0]:
		var pd := EnemyArt.ellipse_points(Vector2(x, -150), 15.0, 10.0, 12)
		c.draw_colored_polygon(pd, GOLD)
		FighterArt.outline(c, pd, 3.0)
	if pose == "slash":                                           # Golden swing trail
		c.draw_arc(Vector2(30, -120), 90.0, -1.3, 0.7, 16, Color(1.0, 0.85, 0.35, 0.7), 10.0, true)
