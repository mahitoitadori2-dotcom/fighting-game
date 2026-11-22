class_name HeadGuard
extends C5Boss
## HEAD HEAVY NIGHTMARE GUARDS (The Hunt of a Nightmare, level 95) - by the user:
##   * There are SIX of them, and they SPLIT their health (one shared bar: HP_EACH x 6).
##   * Bigger versions of the Musician, but no instruments: MEDIEVAL WEAPONS (HuntArt.WEAPONS, from the
##     user's weapon list). A heavy iron helm over the mask (the "head heavy").
##   * They can set their weapon AFLAME and send it at you - then for 10 SECONDS they have nothing
##     in their hands until they grab ANOTHER one (a different weapon each time).
##   * The fight starts with ONE guard, then there are TWO, then they REPLACE each other: when one
##     dies the next one CRASHES FROM THE CEILING (making a hole in it) - until all six are dead.
##
##   Strike        9 dmg   a swing of whatever weapon it holds
##   Heavy Blow   13 dmg   a slow overhead blow (armored)
##   Flame Throw  11 dmg   the weapon bursts into flame and is thrown at you -> 10 s unarmed
##   (unarmed)    Punch 6 dmg, Shove 7 dmg

const TOTAL := 6
const HP_EACH := 115
const UNARMED_TIME := 10.0
const K := 1.45
const WIDE := 2.1
const SECOND_AFTER := 9.0                 # The 2nd guard drops in after this long (or when the 1st falls)

## The fight's state (shared by all six). Reset when the first one appears.
static var spawned := 0
static var guards: Array = []

var index := 0
var weapon_name := ""
var _unarmed := 0.0
var _crashing := false


func boss_forms() -> Array:
	return [{"name": "Head Heavy Nightmare Guard", "title": "HEAD HEAVY NIGHTMARE GUARDS", "hp": HP_EACH, "body": Vector2(120, 170), "speed": 210.0}]


func setup_boss() -> void:
	keep_min = 0.0
	keep_max = 220.0
	attack_chance = 0.7
	chain_chance = 0.25
	grab_immune = true
	weapon_name = _new_weapon("")
	tags = {"strike": ["close"], "heavy": ["close", "counter"], "flame": ["ranged"], "punch": ["close"], "shove": ["close", "anti_air"]}
	combos = {"strike": ["heavy"], "punch": ["shove"]}
	if index == 0:
		spawned = 1
		guards = [self]
		_start_director.call_deferred()


## The director lives in the ARENA (not in this guard): it keeps working after this one dies.
func _start_director() -> void:
	var d := Director.new()
	d.name = "GuardDirector"
	d.floor_y_v = floor_y()
	d.team_v = team
	d.left = clamp_arena(-99999.0, 90.0)
	d.right = clamp_arena(99999.0, 90.0)
	get_parent().add_child(d)


static func _new_weapon(old: String) -> String:
	var names := HuntArt.weapon_names()
	var w := old
	while w == old:
		w = String(names[randi() % names.size()])
	return w


## "Disarmed": hit while its hands are empty.
func take_hit(amount: int, hit: HitData) -> void:
	if _unarmed > 0.0 and amount > 0 and hit != null and hit.source != null and hit.source.team == 1 and not StoryManager.autoplay:
		Achievements.unlock("hunt_disarmed")
	super.take_hit(amount, hit)


## Story manager: a group boss, but the others are not here yet (they crash in later).
func spawn_group() -> Array:
	return []


static func make_patterns() -> Array[EnemyPattern]:
	var list: Array[EnemyPattern] = []
	list.append(EnemyPattern.make("strike", "STRIKE!", 1.8, 9, 0.0, 190.0, "strike", 0.35, 0.25, 0.45, true, [1.8], true))
	list.append(EnemyPattern.make("heavy", "HEAVY BLOW!", 4.0, 13, 0.0, 200.0, "heavy", 0.7, 0.3, 0.6, true, [1.3], true))
	list.append(EnemyPattern.make("flame", "FLAME THROW!", 6.0, 11, 160.0, 1400.0, "flame", 0.9, 0.2, 0.5, true, [1.4], true))
	list.append(EnemyPattern.make("punch", "PUNCH", 1.4, 6, 0.0, 120.0, "punch", 0.25, 0.15, 0.35, false, [1.8], true))
	list.append(EnemyPattern.make("shove", "SHOVE!", 3.0, 7, 0.0, 160.0, "heavy", 0.4, 0.25, 0.45, false, [1.2], true))
	return list


func wants_pattern(p: EnemyPattern) -> bool:
	if _unarmed > 0.0:
		return p.id == "punch" or p.id == "shove"
	return p.id == "strike" or p.id == "heavy" or p.id == "flame"


func can_act() -> bool:
	return super.can_act() and not _crashing


func _long_weapon() -> bool:
	return String(HuntArt.WEAPONS.get(weapon_name, "")) in ["greatsword", "halberd", "glaive", "spear", "lance", "scythe", "greataxe", "anchor"]


func _attack(p: EnemyPattern) -> void:
	face_target()
	var reach := 1.35 if _long_weapon() else 1.0
	match p.id:
		"strike":
			swing(dmg(p), Vector2(320, -220), Vector2(90.0 * reach, -90), Vector2(150.0 * reach, 130), "guard_strike")
			SoundManager.play_sfx("sword_slash", -4.0)
		"heavy":
			swing(dmg(p), Vector2(420, -320), Vector2(80.0 * reach, -60), Vector2(160.0 * reach, 160), "guard_heavy")
			Effects.shake(self, 9.0)
			SoundManager.play_sfx("slam")
		"flame":
			var w := shoot("nm_weapon", global_position + Vector2(facing * 60.0, -140.0), float(facing), 620.0, 2.2, Vector2(90, 60), dmg(p), Vector2(300, -240), Color.WHITE, "guard_flame_throw")
			w.art_id = weapon_name
			Effects.popup(self, global_position + Vector2(0, -260), "UNARMED", Color(1.0, 0.8, 0.6), 20)
			_unarmed = UNARMED_TIME
			SoundManager.play_sfx("flame")
		"punch":
			swing(dmg(p), Vector2(240, -160), Vector2(70, -100), Vector2(90, 80), "guard_punch")
			SoundManager.play_sfx("punch", -4.0)
		"shove":
			hit_in_radius(global_position + Vector2(facing * 50.0, -90.0), 150.0, dmg(p), Vector2(facing * 460.0, -240.0), "guard_shove")
			SoundManager.play_sfx("slam", -6.0)


func _update_visuals(delta: float) -> void:
	if _unarmed > 0.0 and CombatManager.fight_active:
		_unarmed -= delta
		if _unarmed <= 0.0:                                   # Grabs ANOTHER weapon
			weapon_name = _new_weapon(weapon_name)
			Effects.popup(self, global_position + Vector2(0, -260), weapon_name + "!", Color(1.0, 0.85, 0.5), 22)
			SoundManager.play_sfx("spawn", -6.0)
	if _crashing and is_on_floor():                           # Landed after crashing through the ceiling
		_crashing = false
		hit_in_radius(global_position + Vector2(0, -40), 170.0, 6, Vector2(300, -300), "guard_crash")
		Effects.shake(self, 14.0)
		Effects.hit_sparks(self, global_position, 16, 1.6)
		SoundManager.play_sfx("slam")
	super._update_visuals(delta)


## Drop in from above (a hole is torn in the ceiling over it).
func crash_in() -> void:
	_crashing = true
	velocity = Vector2(0, 300.0)
	var hole := CeilingHole.new()
	get_parent().add_child(hole)
	hole.global_position = Vector2(global_position.x, global_position.y - 40.0)
	SoundManager.play_sfx("explosion", -4.0)
	Effects.popup(self, global_position + Vector2(0, 80), "CRASH!", Color(1.0, 0.6, 0.4), 26)


## ONE shared bar for all six: what is left of their split health (0..1).
static func bar_k() -> float:
	var left := 0.0
	var each := float(HP_EACH)
	for g in guards:
		if g != null and is_instance_valid(g):
			var hg := g as HeadGuard
			each = float(hg.data.max_hp)
			if not hg.is_dead:
				left += float(hg.hp)
	left += float(TOTAL - spawned) * each
	return clampf(left / (each * float(TOTAL)), 0.0, 1.0)


static func alive_count() -> int:
	var n := 0
	for g in guards:
		if g != null and is_instance_valid(g) and not (g as HeadGuard).is_dead:
			n += 1
	return n


func draw_model_on(c: CanvasItem) -> void:
	var s := art_state()
	s["weapon"] = weapon_name if _unarmed <= 0.0 else ""
	draw_guard(c, s)


static func draw_portrait(c: CanvasItem, t: float) -> void:
	draw_guard(c, {"t": t, "weapon": "GREATAXE"})


static func draw_guard(c: CanvasItem, s: Dictionary) -> void:
	var t: float = s.get("t", 0.0)
	var pose_v: String = s.get("pose", "idle")
	var wpn: String = s.get("weapon", "")
	var arm := 0.2
	var ang := -1.0
	match pose_v:
		"strike_tele", "heavy_tele":
			arm = 1.3
			ang = -2.2
		"strike", "heavy":
			arm = 0.9
			ang = 0.5
		"flame_tele":
			arm = 1.4
			ang = -2.6
		"punch":
			arm = 1.0
	var pts := HuntArt.body(c, s, {"k": K, "wide": WIDE, "leg": 11.0, "mask": "square", "arm_f": arm, "arm_b": 0.3, "cloak": Color(0.30, 0.02, 0.04)})
	var head: Vector2 = pts["head"]
	# THE HEAVY HELM: an iron bucket over the mask, far too big for the head, rivets + a red slit
	var helm := PackedVector2Array([head + Vector2(-24, -30), head + Vector2(26, -30), head + Vector2(30, 18), head + Vector2(-28, 18)])
	c.draw_colored_polygon(helm, HuntArt.STEEL_DARK)
	FighterArt.outline(c, helm, 3.5)
	c.draw_rect(Rect2(head + Vector2(-22, -6), Vector2(50, 7)), HuntArt.BLACK)
	c.draw_rect(Rect2(head + Vector2(-16, -4), Vector2(38, 3)), Color(1.0, 0.15, 0.1, 0.8 + 0.2 * sin(t * 5.0)))
	for i in 5:
		c.draw_circle(head + Vector2(-18.0 + float(i) * 11.0, -24), 2.5, HuntArt.STEEL)
	c.draw_line(head + Vector2(-26, 8), head + Vector2(28, 8), HuntArt.STEEL, 3.0)
	if wpn != "":
		HuntArt.weapon(c, wpn, pts["hand_f"], ang, K * 0.9, t, pose_v == "flame_tele")


# ============================================================
# THE DIRECTOR: brings the other five in, one by one, through the ceiling
# ============================================================
class Director extends Node:
	var _t := 0.0
	var floor_y_v := 0.0
	var team_v := 2
	var left := -600.0
	var right := 600.0

	func _process(delta: float) -> void:
		if not CombatManager.fight_active:
			return
		_t += delta
		if HeadGuard.spawned >= HeadGuard.TOTAL:
			return
		var alive := HeadGuard.alive_count()
		var want := 2 if (_t >= HeadGuard.SECOND_AFTER or HeadGuard.spawned >= 2 or alive == 0) else 1
		if alive < want:
			_spawn_next()

	func _spawn_next() -> void:
		var sm := get_tree().get_first_node_in_group("story_manager") as StoryManager
		if sm == null:
			return
		var px := (left + right) * 0.5
		if sm.player != null and is_instance_valid(sm.player):
			px = sm.player.global_position.x
		var g := StoryLevels.make_enemy("head_guard") as HeadGuard
		g.index = HeadGuard.spawned
		g.slot = 2
		g.team = team_v
		g.respawn_enabled = false
		var tx := px + (randf_range(-260.0, -150.0) if randf() < 0.5 else randf_range(150.0, 260.0))
		g.position = Vector2(clampf(tx, left, right), floor_y_v - 640.0)
		get_parent().add_child(g)
		HeadGuard.spawned += 1
		HeadGuard.guards.append(g)
		sm.buff_boss(g)
		g.died.connect(sm._on_boss_died)
		sm.boss_group.append(g)
		g.crash_in()

# ============================================================
# A HOLE IN THE CEILING (where a guard crashed through): torn rock, red light pouring down
# ============================================================
class CeilingHole extends Node2D:
	var _t := 0.0
	var _seed := 0

	func _ready() -> void:
		_seed = randi()
		z_index = -2

	func _process(delta: float) -> void:
		_t += delta
		queue_redraw()

	func _draw() -> void:
		var top := -560.0
		var rng := RandomNumberGenerator.new()
		rng.seed = _seed
		var beam_a := clampf(1.0 - _t * 0.15, 0.25, 1.0)
		draw_colored_polygon(PackedVector2Array([Vector2(-50, top), Vector2(50, top), Vector2(110, 0), Vector2(-110, 0)]), Color(1.0, 0.12, 0.08, 0.10 * beam_a))
		var hole := PackedVector2Array()
		for i in 12:
			var a := TAU * float(i) / 12.0
			hole.append(Vector2(0, top) + Vector2(cos(a) * rng.randf_range(50.0, 80.0), sin(a) * rng.randf_range(18.0, 34.0)))
		draw_colored_polygon(hole, Color(0.05, 0.0, 0.0))
		draw_polyline(hole + PackedVector2Array([hole[0]]), Color(0.55, 0.08, 0.06), 4.0)
		for i in 6:                                                     # Dust still falling out of it
			var dx := rng.randf_range(-60.0, 60.0)
			var dy := fmod(_t * 220.0 + float(i) * 90.0, 560.0)
			draw_circle(Vector2(dx, top + dy), 3.0, Color(0.4, 0.3, 0.28, clampf(1.0 - _t * 0.12, 0.0, 0.7)))
