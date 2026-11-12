class_name ArchitectianWarrior
extends ArmedSoldier
## ARCHITECTIAN WARRIOR (Story Mode, Colosseum 3 - the Minor Architectium): a soldier of the
## Architect's people. White plate armour with green trim, a dark visor, a big engineer's
## HAMMER and a round SHIELD with a gear on it. Fights as a unit.
##
##   Hammer Swing   6 dmg, 2.0 s - an overhead hammer blow
##   Shield Block   -            - raises the shield: takes almost no damage for a moment
##   Formation      6 dmg, 7.0 s - BIG: shield charge, and nearby warriors charge WITH it

const SWING_KB := Vector2(320, -220)
const CHARGE_KB := Vector2(380, -180)
const CHARGE_SPEED := 520.0
const FORMATION_RANGE := 380.0

const WHITE := Color(0.94, 0.95, 0.97)
const WHITE_SHADE := Color(0.70, 0.74, 0.80)
const GREEN := Color(0.22, 0.86, 0.28)
const GREEN_SHADE := Color(0.08, 0.52, 0.15)
const DARK := Color(0.25, 0.27, 0.31)
const DARK_SHADE := Color(0.12, 0.13, 0.16)
const STEEL := Color(0.62, 0.65, 0.70)
const WOOD := Color(0.48, 0.32, 0.18)

## Other weapons (ArmedSoldier kit). The plain "warrior_a" keeps hammer + gear shield.
const WEAPON_NAMES := {"short_sword": "Architectian Swordsman", "spear": "Architectian Lancer",
	"greatshield": "Architectian Bulwark", "bow": "Architectian Archer"}

var _blocking := false


func native_weapon() -> String:
	return "hammer"


func weapon_names() -> Dictionary:
	return WEAPON_NAMES


static func palette() -> Dictionary:
	return {"arm": WHITE, "arm_shade": WHITE_SHADE, "arm_hi": Color.WHITE, "hand": GREEN_SHADE,
		"metal": STEEL, "accent": GREEN, "dark": DARK, "wood": WOOD}


func _make_data() -> CharacterData:
	if not is_native():
		return weapon_data(32)
	keep_min = 50.0
	keep_max = 130.0
	attack_chance = 0.6
	phase2_threshold = -1.0
	return SimpleEnemy.make_data("Architectian Warrior", 32, Vector2(62, 140), 170.0)


static func make_patterns() -> Array[EnemyPattern]:
	var list: Array[EnemyPattern] = []
	#                          id           name            cd    dmg  min    max    anim        tele  active rec   big    weights
	list.append(EnemyPattern.make("swing", "HAMMER SWING", 2.0, 6, 0.0, 135.0, "swing", 0.40, 0.18, 0.45, false, [2.0, 2.0]))
	list.append(EnemyPattern.make("block", "SHIELD BLOCK", 4.5, 0, 0.0, 260.0, "block", 0.10, 1.30, 0.20, false, [1.0, 1.0]))
	list.append(EnemyPattern.make("formation", "FORMATION!", 7.0, 6, 100.0, 520.0, "formation", 0.55, 0.60, 0.50, true, [1.0, 1.0]))
	list[1].note = "takes almost no damage while the shield is up"
	return list


func flavor_lines() -> Array[String]:
	return ["HOLD THE LINE!", "For the Architect!", "Shields up!"]


func _attack(p: EnemyPattern) -> void:
	if not is_native():
		_weapon_attack(p)
		return
	match p.id:
		"swing":
			hitbox.activate(make_hit(dmg(p), Vector2(facing * SWING_KB.x, SWING_KB.y), "architectian_hammer"),
				Vector2(facing * 70.0, -70.0), Vector2(90, 110))
			velocity.x = facing * 120.0
			SoundManager.play_sfx("punch", -3.0)
		"block":
			_set_block(true)
		"formation":
			hitbox.activate(make_hit(dmg(p), Vector2(facing * CHARGE_KB.x, CHARGE_KB.y), "architectian_formation"),
				Vector2(facing * 34.0, -70.0), Vector2(60, 130))
			SoundManager.play_sfx("dash", -5.0)
			_call_formation()


## Nearby warriors that are free join the charge (side by side, same direction).
func _call_formation() -> void:
	for n in get_tree().get_nodes_in_group("fighters"):
		var o := n as ArchitectianWarrior
		if o == null or o == self or o.is_dead or not o.can_act():
			continue
		if absf(o.global_position.x - global_position.x) > FORMATION_RANGE:
			continue
		var fp := o.pattern("formation")
		if fp == null:
			continue
		fp.cooldown_left = 0.0
		o.facing = facing
		o.start_pattern(fp)
		Effects.popup(o, o.global_position + Vector2(0, -180), "IN FORMATION!", GREEN, 16)


func _on_attack_update(p: EnemyPattern, delta: float) -> void:
	if p.id == "formation":
		velocity.x = facing * CHARGE_SPEED
		if is_on_wall() or not ground_ahead(50.0):
			state_time = state_len
	else:
		super._on_attack_update(p, delta)


func _on_attack_end(p: EnemyPattern) -> void:
	if p.id == "block":
		_set_block(false)
	elif p.id == "formation":
		velocity.x *= 0.2
	else:
		super._on_attack_end(p)


func _cancel_pattern() -> void:
	_set_block(false)
	super._cancel_pattern()


func _set_block(on: bool) -> void:
	_blocking = on
	damage_taken_mult = 0.15 if on else 1.0
	if on:
		Effects.popup(self, global_position + Vector2(0, -170), "SHIELD UP", Color(0.8, 0.9, 1.0), 16)
		SoundManager.play_sfx("block", -6.0)


func _owns_velocity_x() -> bool:
	return (estate == EState.ATTACK and current != null and current.id == "formation") or super._owns_velocity_x()


func art_state() -> Dictionary:
	var s := super.art_state()
	s["blocking"] = _blocking
	return s


# ============================================================
# ART (facing right, origin = feet, ~90 x 160)
# ============================================================
func draw_model_on(c: CanvasItem) -> void:
	draw_warrior(c, art_state())


static func draw_portrait(c: CanvasItem, t: float) -> void:
	draw_warrior(c, {"t": t, "pose": "idle"})


## Board tile / roster portrait of a weapon variant ("bow", "greatshield"...).
static func draw_portrait_weapon(c: CanvasItem, t: float, w: String) -> void:
	draw_warrior(c, {"t": t, "pose": "idle", "weapon": w})


static func draw_warrior(c: CanvasItem, s: Dictionary) -> void:
	var t: float = s.get("t", 0.0)
	var pose: String = s.get("pose", "idle")
	var dead: bool = s.get("dead", false)
	var blocking: bool = s.get("blocking", false)
	var w: String = s.get("weapon", "")
	var bob := sin(t * 2.0) * 1.5
	EnemyArt.legs(c, s, -60.0, 10.0, 12.0, GREEN, GREEN_SHADE, GREEN.lightened(0.3), DARK, 18.0)
	var chest := Vector2(0, -96 + bob)
	if w != "":
		ArmedSoldier.draw_weapon_back(c, s, chest, palette())
		_draw_body(c, chest, t, dead)
		ArmedSoldier.draw_weapon_front(c, s, chest, palette())
		return
	# Hammer arm (behind)
	var hand := chest + Vector2(-20, 26)
	var ang := -2.0
	match pose:
		"swing_tele":
			hand = chest + Vector2(-16, -44)
			ang = -2.6
		"swing":
			hand = chest + Vector2(40, 0)
			ang = 0.5
		"formation", "formation_tele":
			hand = chest + Vector2(-24, 10)
			ang = -2.4
	var d := Vector2.from_angle(ang)
	var head_pos := hand + d * 58.0
	c.draw_line(hand - d * 8.0, head_pos, EnemyArt.BLACK, 8.0)
	c.draw_line(hand - d * 8.0, head_pos, WOOD, 5.0)
	var hammer := PackedVector2Array()
	var n := d.orthogonal()
	for p in [head_pos + n * 20.0 - d * 10.0, head_pos + n * 20.0 + d * 10.0, head_pos - n * 20.0 + d * 10.0, head_pos - n * 20.0 - d * 10.0]:
		hammer.append(p)
	c.draw_colored_polygon(hammer, STEEL)
	c.draw_line(head_pos + n * 20.0, head_pos - n * 20.0, GREEN, 3.0)
	FighterArt.outline(c, hammer, 3.0)
	EnemyArt.arm(c, chest + Vector2(-10, -18), hand, 9.0, WHITE_SHADE, WHITE_SHADE.darkened(0.2), WHITE, GREEN_SHADE, 6.5)
	_draw_body(c, chest, t, dead)
	# Shield (front)
	var sh := chest + Vector2(24, 10)
	if blocking or pose == "block" or pose == "block_tele":
		sh = chest + Vector2(30, -6)
	elif pose == "formation":
		sh = chest + Vector2(38, 0)
	var disc := EnemyArt.ellipse_points(sh, 13.0, 30.0, 20)
	c.draw_colored_polygon(disc, DARK)
	c.draw_colored_polygon(EnemyArt.ellipse_points(sh, 9.0, 24.0, 18), WHITE_SHADE)
	_gear(c, sh, 8.0, GREEN, t)
	FighterArt.outline(c, disc, 3.5)
	if blocking:
		c.draw_arc(sh + Vector2(10, 0), 34.0, -1.3, 1.3, 12, Color(0.7, 0.9, 1.0, 0.6 + 0.3 * sin(t * 12.0)), 4.0, FighterArt.AA)


## White breastplate with green trim and a gear emblem + helmet (white dome, dark visor, green slit).
static func _draw_body(c: CanvasItem, chest: Vector2, t: float, dead: bool) -> void:
	var plate := PackedVector2Array([chest + Vector2(-22, -28), chest + Vector2(24, -28), chest + Vector2(20, 36), chest + Vector2(-20, 36)])
	c.draw_polygon(plate, PackedColorArray([WHITE, WHITE, WHITE_SHADE, WHITE_SHADE]))
	c.draw_line(chest + Vector2(-22, -26), chest + Vector2(24, -26), GREEN, 4.0)
	c.draw_line(chest + Vector2(-20, 34), chest + Vector2(20, 34), DARK, 5.0)
	_gear(c, chest + Vector2(2, 4), 9.0, GREEN, 0.0)
	FighterArt.outline(c, plate, 4.0)
	FighterArt.ball(c, chest + Vector2(-18, -24), 11.0, WHITE, WHITE_SHADE, Color.WHITE)
	var head := chest + Vector2(4, -44)
	FighterArt.ball(c, head, 16.0, WHITE, WHITE_SHADE, Color.WHITE)
	var visor := FighterArt.rrect_points(Rect2(head.x - 4, head.y - 6, 20, 10), 4.0)
	c.draw_colored_polygon(visor, DARK_SHADE)
	if dead:
		EnemyArt.ko_eye(c, head + Vector2(8, -1), 3.0, t)
	else:
		c.draw_line(head + Vector2(-1, -1), head + Vector2(14, -1), GREEN, 2.5)
	c.draw_line(head + Vector2(0, -16), head + Vector2(-8, -26), GREEN, 4.0)     # Crest


static func _gear(c: CanvasItem, p: Vector2, r: float, col: Color, rot: float) -> void:
	var pts := PackedVector2Array()
	for i in 16:
		var a := rot + TAU * float(i) / 16.0
		pts.append(p + Vector2.from_angle(a) * (r if i % 2 == 0 else r * 0.75))
	c.draw_colored_polygon(pts, col)
	c.draw_circle(p, r * 0.35, DARK)
