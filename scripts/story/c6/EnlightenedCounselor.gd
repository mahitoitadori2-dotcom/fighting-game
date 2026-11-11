class_name EnlightenedCounselor
extends ExtEnemy
## ENLIGHTENED COUNSELOR (The Enlightened Chase). An old adviser in white-and-gold robes, a
## tall gold mitre and a staff topped with a little sun. Stays at range and SUPPORTS:
##   Holy Word       5 dmg   a ball of light flies at you
##   Pillar of Truth 6 dmg   a pillar of light erupts under you (watch the glowing crack)
##   Counsel         heal    heals every Enlightened ally nearby (not himself) - kill him first!

const WHITE := Color(0.95, 0.93, 0.86)
const GOLD := Color(1.0, 0.8, 0.3)
const CFG := {"head": "crown", "skin": Color(0.86, 0.72, 0.58), "cloth": Color(0.95, 0.93, 0.86),
	"cloth_hi": Color(1.0, 1.0, 0.97), "trim": Color(1.0, 0.78, 0.25), "eye": Color(0.3, 0.5, 1.0),
	"weapon": "staff", "magic": Color(1.0, 0.85, 0.3), "robe": true, "glow": Color(1.0, 0.9, 0.5)}
const HEAL := 10


func _make_data() -> CharacterData:
	keep_min = 260.0
	keep_max = 520.0
	attack_chance = 0.6
	phase2_threshold = -1.0
	return SimpleEnemy.make_data("Enlightened Counselor", 30, Vector2(60, 140), 150.0)


static func make_patterns() -> Array[EnemyPattern]:
	var list: Array[EnemyPattern] = []
	list.append(EnemyPattern.make("word", "HOLY WORD", 2.6, 5, 120.0, 900.0, "cast", 0.45, 0.2, 0.45, false, [2.0, 2.0]))
	list.append(EnemyPattern.make("pillar", "PILLAR OF TRUTH!", 4.5, 6, 0.0, 900.0, "cast", 0.55, 0.2, 0.5, true, [1.4, 1.4]))
	list.append(EnemyPattern.make("counsel", "COUNSEL!", 7.0, 0, 0.0, 2000.0, "cast", 0.7, 0.3, 0.5, true, [1.2, 1.2]))
	list[1].note = "light pillar under you"
	list[2].note = "heals his allies %d HP: kill him first" % HEAL
	return list


## Only heals when someone nearby is hurt.
func wants_pattern(p: EnemyPattern) -> bool:
	if p.id != "counsel":
		return true
	for a in _allies():
		if (a as Fighter).hp < (a as Fighter).data.max_hp:
			return true
	return false


func _allies() -> Array:
	var out: Array = []
	for n in get_tree().get_nodes_in_group("fighters"):
		var f := n as BaseEnemy
		if f != null and f != self and not f.is_dead and CombatManager.are_allies(self, f) and f.global_position.distance_to(global_position) < 600.0:
			out.append(f)
	return out


func flavor_lines() -> Array[String]:
	return ["The Light advises... retreat.", "*turns a golden page*", "He is wiser than you.", "Counsel is free. Mercy is not."]


func _attack(p: EnemyPattern) -> void:
	match p.id:
		"word":
			var s := shot("light_orb", Vector2(30, -120), 430.0, 2.2, Vector2(30, 30), dmg(p), Vector2(200, -160), GOLD, "holy_word", false)
			s.scale = Vector2.ONE
			SoundManager.play_sfx("holy", -8.0)
		"pillar":
			BossHazard.spawn(self, "pillar", Vector2(clamp_to_ground(target_x(), 40.0), global_position.y), 0.75, dmg(p), Vector2(180, -380))
			SoundManager.play_sfx("holy", -6.0)
		"counsel":
			var healed := 0
			for a in _allies():
				var f := a as Fighter
				healed += f.heal(HEAL)
				Effects.gold_burst(f, f.global_position + Vector2(0, -60), 50.0)
			Effects.gold_burst(self, global_position + Vector2(0, -150), 70.0)
			if healed > 0:
				Effects.popup(self, global_position + Vector2(0, -190), "COUNSEL!", GOLD, 20)


func draw_model_on(c: CanvasItem) -> void:
	_draw_counselor(c, art_state())


static func draw_portrait(c: CanvasItem, t: float) -> void:
	_draw_counselor(c, {"t": t, "pose": "idle"})


static func _draw_counselor(c: CanvasItem, s: Dictionary) -> void:
	ExtArt.humanoid(c, s, CFG)
	# Tall gold mitre over the crown + an open golden book on a chain at the belt
	var t: float = s.get("t", 0.0)
	var head := Vector2(4, -132 + sin(t * 3.0) * 1.5)
	var mitre := PackedVector2Array([head + Vector2(-12, -10), head + Vector2(0, -42), head + Vector2(12, -10)])
	c.draw_colored_polygon(mitre, WHITE)
	c.draw_line(head + Vector2(0, -40), head + Vector2(0, -12), GOLD, 4.0)
	c.draw_line(head + Vector2(-7, -24), head + Vector2(7, -24), GOLD, 3.0)
	FighterArt.outline(c, mitre, 3.0)
	var book := PackedVector2Array([Vector2(-22, -64), Vector2(-8, -60), Vector2(-8, -44), Vector2(-22, -48)])
	c.draw_colored_polygon(book, GOLD)
	FighterArt.outline(c, book, 2.5)
