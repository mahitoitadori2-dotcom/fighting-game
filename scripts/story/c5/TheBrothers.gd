class_name TheBrothers
extends C5Boss
## THE BROTHERS - BOSS 2 of Colosseum 5 (Level 39, the Mirror Hall).
## Twin knights: one in black armour with white trim, one in white with black trim, a
## half-sun / half-moon visor each and a long curved blade. They move PERFECTLY SYMMETRICAL
## (mirror images across the middle of the arena), share ONE health bar, and DON'T TAKE AGGRO:
## no matter where you stand, they run their set attacks in a random order, together.
##
##   Cross Slash     9 dmg   both dash through the middle and swap sides, blades out
##   Twin Leap       8 dmg   both leap to the middle and slam down: shockwaves roll out (jump)
##   Mirror Waves    5 dmg   blade waves fly toward the middle - low, high, low (jump / duck)
##   Pincer          8 dmg   both charge to mirrored points and slash
##   Blade Rain      7 dmg   blades of light fall in mirrored pairs across the arena
##   Twin Spin       5 dmg   both spin, throwing waves to both sides
## One body is the LEADER (it thinks); the other is the TWIN (it copies the leader, mirrored).
## Hitting either one hurts the shared HP bar.

const REST := 330.0
const DASH_SPEED := 980.0
const BLACK := Color(0.12, 0.12, 0.15)
const BLACK_HI := Color(0.30, 0.30, 0.36)
const WHITE := Color(0.92, 0.92, 0.95)
const WHITE_SHADE := Color(0.66, 0.66, 0.72)
const SUN := Color(1.0, 0.82, 0.3)
const MOON := Color(0.72, 0.82, 1.0)

var is_twin := false
var leader: TheBrothers = null
var twin: TheBrothers = null
var _air := false
var _wave_n := 0
var _dash_to := 0.0


func boss_forms() -> Array:
	return [{"name": "The Brothers", "title": "THE BROTHERS   -   ONE BLADE, TWO HANDS", "hp": 560, "body": Vector2(66, 150), "speed": 260.0}]


func setup_boss() -> void:
	keep_min = 0.0
	keep_max = 9999.0
	art_scale = 1.1
	chain_chance = 0.35
	combos = {"cross": ["leap", "waves"], "leap": ["waves", "spin"], "waves": ["pincer", "cross"], "pincer": ["spin"], "rain": ["cross"], "spin": ["leap"]}


static func make_patterns() -> Array[EnemyPattern]:
	var list: Array[EnemyPattern] = []
	#                          id        name              cd    dmg  min  max     anim      tele  active rec   big   weights armored
	list.append(EnemyPattern.make("cross", "CROSS SLASH!", 4.5, 9, 0.0, 9999.0, "cross", 0.60, 0.90, 0.60, true, [1.6], true))
	list.append(EnemyPattern.make("leap", "TWIN LEAP!", 5.0, 8, 0.0, 9999.0, "leap", 0.55, 1.60, 0.60, true, [1.4], true))
	list.append(EnemyPattern.make("waves", "MIRROR WAVES!", 4.0, 5, 0.0, 9999.0, "waves", 0.55, 1.20, 0.50, true, [1.6], true))
	list.append(EnemyPattern.make("pincer", "PINCER!", 4.5, 8, 0.0, 9999.0, "pincer", 0.50, 0.80, 0.60, true, [1.3], true))
	list.append(EnemyPattern.make("rain", "BLADE RAIN!", 7.0, 7, 0.0, 9999.0, "rain", 0.70, 0.40, 0.50, true, [1.0], true))
	list.append(EnemyPattern.make("spin", "TWIN SPIN!", 5.5, 5, 0.0, 9999.0, "spin", 0.50, 0.90, 0.50, true, [1.1], true))
	list[1].note = "shockwaves roll along the floor: jump them"
	list[2].note = "low, high, low: jump or duck"
	return list


func _make_brain() -> EnemyAI:
	return BrothersBrain.new()


func flavor_lines() -> Array[String]:
	return ["As one.", "*steel rings twice*", "Neither of us. Both of us."]


func _ready() -> void:
	super._ready()
	if is_twin:
		hud.visible = false
		set_process(false)
	else:
		_spawn_twin.call_deferred()


func _spawn_twin() -> void:
	if is_dead or not is_inside_tree():
		return
	twin = TheBrothers.new()
	twin.is_twin = true
	twin.leader = self
	twin.slot = slot
	twin.team = team
	twin.respawn_enabled = false
	twin.default_facing = -facing
	twin.facing = -facing
	twin.position = Vector2(mirror_x(global_position.x), global_position.y)
	twin.damage_mult = damage_mult                       # Same scaling as the leader (Story buff / Versus nerf)
	twin.boss_hp_mult = boss_hp_mult
	get_parent().add_child(twin)
	twin.data.max_hp = data.max_hp                       # (The twin's HP is the leader's: it forwards every hit)
	twin.hp = hp


func mirror_x(x: float) -> float:
	var c := leader.arena_center() if is_twin and leader != null else arena_center()
	return 2.0 * c - x


# ============================================================
# THE TWIN: copies the leader (mirrored), forwards damage to the shared HP bar
# ============================================================
func _physics_process(delta: float) -> void:
	if not is_twin:
		super._physics_process(delta)
		return
	if leader == null or not is_instance_valid(leader) or leader.is_dead:
		if not is_dead:
			die()
		return
	if is_dead:
		return
	global_position = Vector2(mirror_x(leader.global_position.x), leader.global_position.y)
	facing = -leader.facing
	pose = leader.pose
	pose_t = leader.pose_t
	estate = leader.estate
	current = leader.current
	anim_time = leader.anim_time
	raging = leader.raging
	enraged = leader.enraged
	if estate != EState.ATTACK and hitbox.active:
		hitbox.deactivate()
	_update_visuals(delta)


func take_hit(amount: int, hit: HitData) -> void:
	if is_twin:
		if leader != null and is_instance_valid(leader) and not leader.is_dead:
			leader.take_hit(amount, hit)
			if amount > 0:
				_flash(Color(1.0, 0.3, 0.3), 0.15)
		return
	super.take_hit(amount, hit)


func _on_death() -> void:
	super._on_death()
	if not is_twin and twin != null and is_instance_valid(twin) and not twin.is_dead:
		twin.die()


## Leader's melee: the same box on the twin, mirrored.
func swing(damage: int, kb: Vector2, off: Vector2, size: Vector2, move: String) -> void:
	super.swing(damage, kb, off, size, move)
	if twin != null and is_instance_valid(twin) and not twin.is_dead:
		twin.hitbox.activate(twin.make_hit(damage, Vector2(twin.facing * kb.x, kb.y), move), Vector2(twin.facing * off.x, off.y), size)


# ============================================================
# ATTACKS (the leader does everything for both)
# ============================================================
func _attack(p: EnemyPattern) -> void:
	var cx := arena_center()
	match p.id:
		"cross":
			_dash_to = mirror_x(global_position.x)
			facing = 1 if _dash_to > global_position.x else -1
			swing(dmg(p), Vector2(360, -220), Vector2(50, -70), Vector2(120, 130), "cross_slash")
			SoundManager.play_sfx("dash")
			SoundManager.play_sfx("sword_slash", -3.0)
		"leap":
			_air = false
			var side := -1.0 if global_position.x < cx else 1.0
			leap_to(cx + side * 150.0, 0.75, 300.0)
			SoundManager.play_sfx("jump")
		"waves":
			_wave_n = 0
			_mirror_wave(p)
		"pincer":
			var tx := target_x()
			var side := -1.0 if global_position.x < cx else 1.0
			_dash_to = clamp_arena(tx if signf(tx - cx) == side else cx + side * 120.0)
			facing = 1 if _dash_to > global_position.x else -1
			SoundManager.play_sfx("dash", -2.0)
		"rain":
			for k in 4:
				var off := 90.0 + float(k) * 140.0
				var dl := 0.55 + 0.18 * float(k)
				hazard("spear", cx - off, dl, dmg(p), Vector2(200, -420))
				hazard("spear", cx + off, dl, dmg(p), Vector2(200, -420))
			hazard("spear", cx, 1.4, dmg(p), Vector2(200, -420))
			SoundManager.play_sfx("holy")
		"spin":
			_wave_n = 0
			SoundManager.play_sfx("whoosh")


## One volley: a blade wave from each brother toward the middle (low / high alternate).
func _mirror_wave(p: EnemyPattern) -> void:
	_wave_n += 1
	pose_t = 0.0
	var y := -34.0 if _wave_n % 2 == 1 else -118.0
	var cx := arena_center()
	var d := 1.0 if global_position.x < cx else -1.0
	var col := SUN if _wave_n % 2 == 1 else MOON
	shoot("crescent", global_position + Vector2(d * 50.0, y), d, 560.0, 1.4, Vector2(50, 70), dmg(p), Vector2(240, -200), col, "mirror_wave", true)
	shoot("crescent", Vector2(mirror_x(global_position.x) - d * 50.0, global_position.y + y), -d, 560.0, 1.4, Vector2(50, 70), dmg(p), Vector2(240, -200), col, "mirror_wave", true)
	SoundManager.play_sfx("sword_slash", -4.0)


func _shockwaves(x: float, p: EnemyPattern) -> void:
	for d: float in [-1.0, 1.0]:
		shoot("shock", Vector2(x + d * 50.0, floor_y() - 20.0), d, 520.0, 0.9, Vector2(50, 40), maxi(1, dmg(p) - 2), Vector2(220, -320), MOON, "twin_shockwave", true)


func _on_attack_update(p: EnemyPattern, delta: float) -> void:
	match p.id:
		"cross", "pincer":
			var step := DASH_SPEED * delta
			if absf(_dash_to - global_position.x) <= step:
				velocity.x = 0.0
				if p.id == "pincer" and not hitbox.active:
					swing(dmg(p), Vector2(360, -220), Vector2(60, -70), Vector2(140, 130), "pincer")
					SoundManager.play_sfx("sword_slash", -3.0)
			else:
				velocity.x = signf(_dash_to - global_position.x) * DASH_SPEED
		"leap":
			if not is_on_floor():
				_air = true
			elif _air:
				_air = false
				hit_in_radius(global_position + Vector2(0, -40), 110.0, dmg(p), Vector2(300, -320), "twin_leap")
				_shockwaves(global_position.x, p)
				_shockwaves(mirror_x(global_position.x), p)
				Effects.shake(self, 12.0)
				SoundManager.play_sfx("slam")
				velocity.x = 0.0
		"waves":
			if _wave_n < 3 and state_time >= float(_wave_n) * 0.4:
				_mirror_wave(p)
		"spin":
			if _wave_n < 2 and state_time >= 0.2 + float(_wave_n) * 0.45:
				_wave_n += 1
				swing(dmg(p), Vector2(260, -220), Vector2(0, -70), Vector2(200, 140), "twin_spin")
				for x in [global_position.x, mirror_x(global_position.x)]:
					for d: float in [-1.0, 1.0]:
						shoot("crescent", Vector2(x + d * 40.0, global_position.y - 70.0), d, 480.0, 1.2, Vector2(46, 60), dmg(p), Vector2(220, -200), SUN if d > 0.0 else MOON, "twin_spin_wave", true)
				SoundManager.play_sfx("whoosh", -3.0)


func _on_attack_end(p: EnemyPattern) -> void:
	if p.id in ["cross", "pincer", "leap"]:
		velocity.x = 0.0


func _owns_velocity_x() -> bool:
	return estate == EState.ATTACK and current != null and current.id in ["cross", "pincer", "leap"]


# ============================================================
# ART (facing right, origin = feet, ~90 x 160 art units)
# ============================================================
func draw_model_on(c: CanvasItem) -> void:
	var s := art_state()
	s["twin"] = is_twin
	draw_brother(c, s)


## Board tile / cards: one brother (no draw_set_transform here: the caller's transform must stay).
static func draw_portrait(c: CanvasItem, t: float) -> void:
	draw_brother(c, {"t": t, "pose": "idle"})


static func draw_brother(c: CanvasItem, s: Dictionary) -> void:
	var t: float = s.get("t", 0.0)
	var pose_v: String = s.get("pose", "idle")
	var dead: bool = s.get("dead", false)
	var tw: bool = s.get("twin", false)
	var armor := WHITE if tw else BLACK
	var armor_shade := WHITE_SHADE if tw else Color(0.06, 0.06, 0.08)
	var armor_hi := Color.WHITE if tw else BLACK_HI
	var trim := BLACK if tw else WHITE
	var glow := MOON if tw else SUN
	EnemyArt.legs(c, s, -62.0, 10.0, 11.0, armor, armor_shade, armor_hi, trim, 18.0)
	var chest := Vector2(0, -100 + sin(t * 2.0) * 1.5)
	# Tabard split down the middle (the other brother's colour)
	var torso := PackedVector2Array([chest + Vector2(-22, -28), chest + Vector2(24, -28), chest + Vector2(20, 36), chest + Vector2(-20, 36)])
	c.draw_polygon(torso, PackedColorArray([armor_hi, armor, armor_shade, armor_shade]))
	c.draw_colored_polygon(PackedVector2Array([chest + Vector2(0, -10), chest + Vector2(12, -10), chest + Vector2(10, 50), chest + Vector2(0, 56)]), trim)
	FighterArt.outline(c, torso, 4.0)
	c.draw_line(chest + Vector2(-22, -26), chest + Vector2(24, -26), trim, 3.0)
	FighterArt.ball(c, chest + Vector2(-20, -24), 12.0, armor, armor_shade, armor_hi)
	# Curved blade
	var hand := chest + Vector2(26, 12)
	var ang := -1.0
	match pose_v:
		"cross", "pincer":
			hand = chest + Vector2(40, -6)
			ang = 0.1
		"cross_tele", "pincer_tele", "spin_tele":
			hand = chest + Vector2(-20, -20)
			ang = -2.6
		"spin":
			ang = t * 22.0
		"leap":
			hand = chest + Vector2(10, -40)
			ang = -1.57
		"waves":
			hand = chest + Vector2(36, -10)
			ang = 0.3 - fmod(t * 6.0, 1.2)
		"rain", "rain_tele":
			hand = chest + Vector2(6, -56)
			ang = -1.57
	var d := Vector2.from_angle(ang)
	var n := d.orthogonal()
	var blade := PackedVector2Array([hand + n * 3.0, hand + d * 50.0 + n * 9.0, hand + d * 96.0 + n * 2.0, hand + d * 100.0, hand + d * 50.0 - n * 2.0, hand - n * 3.0])
	c.draw_colored_polygon(blade, Color(0.86, 0.87, 0.92))
	c.draw_line(hand + d * 6.0, hand + d * 90.0, Color(glow.r, glow.g, glow.b, 0.7), 2.0)
	FighterArt.outline(c, blade, 2.5)
	c.draw_line(hand - n * 10.0, hand + n * 10.0, trim, 5.0)
	EnemyArt.arm(c, chest + Vector2(14, -18), hand, 9.0, armor, armor_shade, armor_hi, trim, 6.5)
	# Helm: visor shaped like half a sun (black brother) / half a moon (white brother)
	var head := chest + Vector2(4, -46)
	FighterArt.ball(c, head, 17.0, armor, armor_shade, armor_hi)
	if dead:
		EnemyArt.ko_eye(c, head + Vector2(8, -1), 3.0, t)
	elif tw:
		c.draw_arc(head + Vector2(6, -1), 9.0, -PI * 0.5, PI * 0.5, 10, MOON, 4.0)
		c.draw_circle(head + Vector2(10, -2), 2.5, Color.WHITE)
	else:
		for i in 5:
			var a := -PI * 0.5 + PI * float(i) / 4.0
			c.draw_line(head + Vector2(6, -1), head + Vector2(6, -1) + Vector2.from_angle(a) * 11.0, SUN, 2.5)
		c.draw_circle(head + Vector2(6, -1), 4.0, SUN)
	c.draw_line(head + Vector2(-2, -17), head + Vector2(-14, -30), trim, 4.0)          # Crest
	if pose_v == "cross" or pose_v == "pincer":
		c.draw_line(Vector2(-60, -80), Vector2(-150, -80), Color(glow.r, glow.g, glow.b, 0.5), 4.0)


# ============================================================
# BRAIN: no aggro - set attacks in a random order
# ============================================================
class BrothersBrain extends EnemyAI:
	func _init() -> void:
		super._init()
		think_min = 0.3
		think_max = 0.5

	func think() -> void:
		var b := e as TheBrothers
		if b == null or not e.can_act():
			return
		var pool: Array[EnemyPattern] = []
		var total := 0.0
		for p in e.patterns:
			if p.is_ready() and p.weight(e.phase) > 0.0:
				pool.append(p)
				total += p.weight(e.phase)
		if not pool.is_empty() and chance(0.75):
			var roll := rng.randf() * total
			for p in pool:
				roll -= p.weight(e.phase)
				if roll <= 0.0:
					b.face_target()
					e.start_pattern(p)
					return
		# Walk back to the leader's resting spot (left of the middle) - never chases you
		var rest := b.arena_center() - TheBrothers.REST
		var dx := rest - e.global_position.x
		e.move_dir = 0.0 if absf(dx) < 20.0 else signf(dx)
