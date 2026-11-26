class_name NightmareMonstrosity
extends ExtEnemy
## THE NIGHTMARE MONSTROSITY (The True Hunt, level 138): a stone golem the Nightmare Nourmish Clan
## tried to fuse with nightmare flame. It did not go well: the flame never took, it only leaks out of
## the cracks and sputters. It looks weak... but it does not die. It BREAKS IN TWO.
## The Monstrosity is GENERATION 0. Every golem that falls splits into two smaller, faster ones of the
## next generation, down to the 6th generation: those die for good (1 + 2 + 4 + ... + 64 = 127 golems).
## At most MAX_ALIVE are out at once; the rest climb out of the forge as the others fall.
## The StoryManager counts every golem as part of the boss (add_boss_member): the level ends with the last.
##
##   Slam        10 dmg   both fists down (all generations)
##   Boulder      8 dmg   a burning rock lobbed at you (generations 0-3)
##   Flame Leak   7 dmg   the failed flame bursts out all around it (generations 0-2)
##   Bash         5 dmg   a quick head-butt (generations 3-6)

const LAST_GEN := 6
const MAX_ALIVE := 14
const BASE_HP := 300                      # Every generation together has about this much HP again
const STONE := Color(0.17, 0.14, 0.14)
const STONE_LIT := Color(0.32, 0.26, 0.24)
const FLAME := Color(1.0, 0.32, 0.12)
const FLAME_HOT := Color(1.0, 0.78, 0.35)

var gen := 0
var _launch := Vector2.ZERO               # Thrown out of its parent when it splits

static var _living := 0                   # Golems in the arena (or about to land)
static var _waiting: Array = []           # Born, but waiting for room (MAX_ALIVE)
static var _members: Array = []           # Every golem of this fight (for the "LEFT" counter)


func _ready() -> void:
	if gen == 0:
		_living = 1                           # A new fight: forget the last one
		clear_waiting()
		_members = [self]
	super._ready()
	if _launch != Vector2.ZERO:
		velocity = _launch


## Frees golems that never got their turn (level left / retried).
static func clear_waiting() -> void:
	for c in _waiting:
		if c != null and is_instance_valid(c) and not (c as Node).is_inside_tree():
			(c as Node).free()
	_waiting.clear()


func size_mult() -> float:
	return pow(0.78, float(gen))


func _make_data() -> CharacterData:
	var s := size_mult()
	keep_min = 0.0
	keep_max = 70.0 + 60.0 * s
	attack_chance = 0.5 + 0.05 * float(gen)
	var nm := "Nightmare Monstrosity" if gen == 0 else "Monstrosity  -  Generation %d" % gen
	var d := SimpleEnemy.make_data(nm, maxi(5, roundi(float(BASE_HP) * pow(0.5, float(gen)))), Vector2(140.0, 200.0) * s, 85.0 + 30.0 * float(gen))
	d.hitstun_time = 0.12 + 0.03 * float(gen)
	return d


static func make_patterns() -> Array[EnemyPattern]:
	return _patterns_for(0)


func build_patterns() -> Array[EnemyPattern]:
	return _patterns_for(gen)


static func _patterns_for(g: int) -> Array[EnemyPattern]:
	var s := pow(0.78, float(g))
	var quick := 1.0 - 0.08 * float(g)                # Smaller = quicker wind-ups
	var list: Array[EnemyPattern] = []
	list.append(EnemyPattern.make("slam", "SLAM!", 3.0, 10, 0.0, 70.0 + 90.0 * s, "slam", 0.6 * quick, 0.2, 0.6 * quick, g <= 1, [1.4, 1.6]))
	if g <= 3:
		list.append(EnemyPattern.make("hurl", "BOULDER", 4.6, 8, 200.0, 760.0, "hurl", 0.55 * quick, 0.2, 0.5, false, [1.0, 1.2]))
	if g <= 2:
		list.append(EnemyPattern.make("flare", "FLAME LEAK!", 6.0, 7, 0.0, 120.0 + 90.0 * s, "flare", 0.7, 0.3, 0.6, true, [0.8, 1.2]))
	else:
		list.append(EnemyPattern.make("bash", "BASH", 1.5, 5, 0.0, 50.0 + 50.0 * s, "bash", 0.25, 0.15, 0.35, false, [1.6, 1.8]))
	return list


## Smaller generations hit a little softer.
func dmg(p: EnemyPattern) -> int:
	var d := super.dmg(p)
	return maxi(1, roundi(float(d) * (1.0 - 0.09 * float(gen)))) if d > 0 else 0


func _attack(p: EnemyPattern) -> void:
	var s := size_mult()
	match p.id:
		"slam":
			melee(dmg(p), Vector2(300, -300), Vector2(55.0 * s + 20.0, -45.0 * s), Vector2(130.0 * s + 50.0, 110.0 * s + 30.0), "mon_slam")
			Effects.shake(self, 4.0 + 8.0 * s)
			Effects.hit_sparks(self, global_position + Vector2(facing * (70.0 * s + 20.0), -6.0), 6, 0.6 + 0.8 * s)
			SoundManager.play_sfx("slam" if gen <= 2 else "stone", -4.0)
		"hurl":
			lob("boulder", Vector2(30.0 * s, -170.0 * s), clamp_to_ground(target_x()), 0.95, dmg(p), Vector2(240, -280), 40.0 * s + 20.0, FLAME, "mon_hurl")
			SoundManager.play_sfx("whoosh", -5.0)
		"flare":
			hit_in_radius(global_position + Vector2(0, -100.0 * s), 120.0 + 90.0 * s, dmg(p), Vector2(320, -320), "mon_flare")
			Effects.explosion(self, global_position + Vector2(0, -100.0 * s), 80.0 + 80.0 * s, true, true)
			SoundManager.play_sfx("flame")
		"bash":
			melee(dmg(p), Vector2(220, -180), Vector2(30.0 * s + 10.0, -data.body_size.y * 0.6), Vector2(70.0 * s + 30.0, 60.0 * s + 20.0), "mon_bash")
			SoundManager.play_sfx("punch", -6.0)


# ============================================================
# SPLITTING
# ============================================================
func _on_death() -> void:
	super._on_death()
	_living = maxi(_living - 1, 0)
	if gen < LAST_GEN:
		_split()
	elif StoryManager.active and not StoryManager.autoplay and remaining() == 0:
		Achievements.unlock("monstrosity_down")
	_release()
	if remaining() > 0:
		# PERFORMANCE (127 golems!): a fallen piece leaves once its death animation (1.45 s) is over,
		# instead of staying as a corpse with its own render pass. The very last one stays (death cutscene).
		get_tree().create_timer(2.0, false).timeout.connect(queue_free)
	var m := _manager()
	if m != null:
		m.wave_text = "THE MONSTROSITY  -  %d LEFT" % remaining() if remaining() > 0 else ""


func _manager() -> StoryManager:
	return get_tree().get_first_node_in_group("story_manager") as StoryManager if is_inside_tree() else null


## Two halves of the next generation, thrown out left and right. They join the boss group at once
## (so the level does not end), and land when there is room.
func _split() -> void:
	var m := _manager()
	Effects.explosion(self, global_position + Vector2(0, -data.body_size.y * 0.5), 50.0 + 70.0 * size_mult(), true, true)
	Effects.shake(self, 5.0 + 6.0 * size_mult())
	SoundManager.play_sfx("stone")
	if gen <= 1:
		Effects.popup(self, global_position + Vector2(0, -data.body_size.y - 40.0), "IT BREAKS IN TWO!", FLAME_HOT, 24 if gen == 0 else 20)
	for side: float in [-1.0, 1.0]:
		var c := NightmareMonstrosity.new()
		c.gen = gen + 1
		c.compact_hud = true                          # 14 name tags at once would be a wall of text
		c.slot = 2
		c.team = team
		c.respawn_enabled = false
		c.default_facing = facing
		c.facing = facing
		c.position = position + Vector2(side * 24.0, -data.body_size.y * 0.4)
		c._launch = Vector2(side * randf_range(220.0, 320.0), -randf_range(380.0, 480.0))
		_members.append(c)
		if m != null:
			m.add_boss_member(c)                      # Before our own `died` fires: the level goes on
		_waiting.append(c)


## Lets waiting golems in while there is room.
func _release() -> void:
	var host := get_parent()
	if host == null:
		return
	while not _waiting.is_empty() and _living < MAX_ALIVE:
		var c := _waiting.pop_front() as NightmareMonstrosity
		if c == null or not is_instance_valid(c):
			continue
		_living += 1
		if c.position.distance_to(position) > 400.0:
			c.position.y = position.y - 420.0             # A late one: it drops in from above
		host.add_child.call_deferred(c)


## Golems still to kill: every living / waiting one counts itself and all the halves it will become.
static func remaining() -> int:
	var n := 0
	for c in _members:
		if c == null or not is_instance_valid(c) or (c as NightmareMonstrosity).is_dead:
			continue
		n += (1 << (LAST_GEN - (c as NightmareMonstrosity).gen + 1)) - 1
	return n


# ============================================================
# ART: a lopsided stone golem with a nightmare flame that never caught (feet at 0, 0)
# ============================================================
func draw_model_on(c: CanvasItem) -> void:
	draw_golem(c, art_state(), size_mult(), gen)


static func draw_portrait(c: CanvasItem, t: float) -> void:
	draw_golem(c, {"t": t}, 1.0, 0)


static func draw_golem(c: CanvasItem, s: Dictionary, k: float, g: int) -> void:
	var t: float = s.get("t", 0.0)
	var pose_v: String = s.get("pose", "idle")
	var walk: float = s.get("walk", 0.0)
	c.draw_set_transform(Vector2.ZERO, 0.0, Vector2(k, k))
	var fist_y := -80.0                                  # The big right fist
	if pose_v == "slam_tele":
		fist_y = -230.0
	elif pose_v == "slam":
		fist_y = -14.0
	elif pose_v == "hurl_tele" or pose_v == "hurl":
		fist_y = -210.0 if pose_v == "hurl_tele" else -150.0
	var bob := sin(t * 2.2) * 2.0
	var step := sin(walk) * 6.0 if bool(s.get("moving", false)) else 0.0
	# Legs: two stubby pillars
	for lx: float in [-30.0, 26.0]:
		var sx: float = step * (1.0 if lx < 0.0 else -1.0)
		var leg := PackedVector2Array([Vector2(lx - 20 + sx, 0), Vector2(lx + 20 + sx, 0), Vector2(lx + 16, -60), Vector2(lx - 18, -62)])
		c.draw_colored_polygon(leg, STONE)
		FighterArt.outline(c, leg, 3.0 / k)
	# Body: a heavy, uneven boulder (the right shoulder far bigger - the fusion pulled it out of shape)
	var body := PackedVector2Array([Vector2(-56, -54), Vector2(-66, -120), Vector2(-48, -168 + bob), Vector2(-10, -186 + bob),
		Vector2(40, -196 + bob), Vector2(78, -170 + bob), Vector2(70, -110), Vector2(52, -56)])
	c.draw_colored_polygon(body, STONE)
	FighterArt.outline(c, body, 3.5 / k)
	c.draw_colored_polygon(PackedVector2Array([Vector2(-40, -160 + bob), Vector2(-6, -178 + bob), Vector2(30, -184 + bob), Vector2(10, -150)]), STONE_LIT)
	# The small head, sunk between the shoulders; one eye burns, the other one never lit
	var head_at := Vector2(8, -196 + bob)
	var head := EnemyArt.ellipse_points(head_at, 24.0, 19.0, 12)
	c.draw_colored_polygon(head, STONE)
	FighterArt.outline(c, head, 3.0 / k)
	var flick := 0.6 + 0.4 * absf(sin(t * 9.0 + float(g)))
	c.draw_circle(head_at + Vector2(10, -2), 5.0, Color(FLAME_HOT.r, FLAME_HOT.g, FLAME_HOT.b, flick))
	c.draw_circle(head_at + Vector2(10, -2), 11.0, Color(FLAME.r, FLAME.g, FLAME.b, 0.3 * flick))
	c.draw_circle(head_at + Vector2(-6, -1), 4.0, Color(0.06, 0.04, 0.04))
	# Arms: a small left one, a HUGE right one with a boulder fist
	c.draw_line(Vector2(-52, -150 + bob), Vector2(-74, -96 + bob * 0.5), STONE, 20.0)
	c.draw_circle(Vector2(-76, -90), 14.0, STONE)
	var sh := Vector2(64, -164 + bob)
	var fist := Vector2(96, fist_y)
	c.draw_line(sh, fist, Color(0.03, 0.02, 0.02), 36.0)
	c.draw_line(sh, fist, STONE, 30.0)
	var fpts := EnemyArt.ellipse_points(fist, 30.0, 26.0, 12)
	c.draw_colored_polygon(fpts, STONE)
	FighterArt.outline(c, fpts, 3.0 / k)
	# CRACKS full of nightmare flame that never caught: they flicker, sputter and go dark
	var cracks := [[Vector2(-40, -70), Vector2(-20, -100), Vector2(-30, -130), Vector2(-8, -160)],
		[Vector2(20, -66), Vector2(30, -96), Vector2(50, -120), Vector2(44, -160)],
		[Vector2(70, -150), Vector2(84, -120), Vector2(92, -96)]]
	for i in cracks.size():
		var on := 0.35 + 0.65 * absf(sin(t * (5.0 + float(i) * 1.7) + float(i) * 2.0 + float(g)))
		var heat := clampf(0.55 + 0.08 * float(g), 0.0, 1.0)            # Small ones glow hotter
		var pts := PackedVector2Array(cracks[i])
		c.draw_polyline(pts, Color(FLAME.r, FLAME.g, FLAME.b, 0.35 * on), 9.0)
		c.draw_polyline(pts, Color(FLAME_HOT.r, FLAME_HOT.g, FLAME_HOT.b, heat * on), 3.0)
	# Flame tongues that pop out of the cracks and DIE (the failed fusion)
	for i in 4:
		var ph := fmod(t * 1.3 + float(i) * 0.27 + float(g) * 0.11, 1.0)
		var base: Vector2 = [Vector2(-20, -100), Vector2(30, -96), Vector2(-8, -160), Vector2(84, -120)][i]
		var h := 26.0 * sin(ph * PI)
		var a := (1.0 - ph) * 0.9
		c.draw_colored_polygon(PackedVector2Array([base + Vector2(-6, 0), base + Vector2(6, 0), base + Vector2(sin(t * 11.0 + float(i)) * 4.0, -h)]),
			Color(FLAME.r, FLAME.g, FLAME.b, a))
		c.draw_circle(base + Vector2(0, -h - 10.0 * ph), 4.0 * ph, Color(0.25, 0.2, 0.2, 0.5 * ph))     # ...and turn to smoke
	if pose_v == "flare" or pose_v == "flare_tele":
		var r := 90.0 + 40.0 * sin(t * 18.0)
		c.draw_arc(Vector2(0, -110), r, 0.0, TAU, 28, Color(FLAME.r, FLAME.g, FLAME.b, 0.55), 6.0)
	c.draw_set_transform(Vector2.ZERO, 0.0, Vector2.ONE)
