class_name SunFinale
extends Node2D
## THE FINAL SEQUENCE (Level 50), started when The Consumer hits 0 HP:
##   1. THE BOMB: a glowing SOLAR BOMB drops next to you. Walk over it to pick it up, then press
##      ATTACK to throw it into The Consumer's maw. It swells, cracks... and starts to explode.
##   2. THE ESCAPE: run! Jump across a chain of crumbling platforms (each one falls a moment after
##      you land on it) while a wall of exploding fire chases you from behind. Falling costs HP
##      and puts you back on the last safe platform; the fire hurts and pushes you on. Reach the
##      far ledge to escape. (The CPU partner already ran ahead: this part is yours alone.)
## `done` fires when you made it; StoryManager then plays the "fall_to_earth" cutscene.

signal done

const PLATFORMS := 12
const WALL_SPEED := 210.0
const WALL_SPEED_MAX := 330.0
const FALL_DAMAGE := 12
const FIRE_DAMAGE := 8
const COURSE_X := 4200.0                 # The escape course is built far to the right of the arena

var manager: StoryManager
var boss: TheSun

var _bomb: Node2D
var _carry := false
var _thrown := false
var _t := 0.0
var _plats: Array = []                   # [{body, rect, fall_t, art}]
var _safe := Vector2.ZERO
var _wall_x := 0.0
var _wall: Node2D
var _fire_cd := 0.0
var _escaping := false
var _goal_x := 0.0
var _base_y := 525.0


func _ready() -> void:
	_run.call_deferred()


func _player() -> ControlledFighter:
	return manager.player as ControlledFighter


func _run() -> void:
	var p := _player()
	_base_y = p.global_position.y if p.is_on_floor() else manager.ground_y()
	# ---------------- 1. THE BOMB ----------------
	CombatManager.fight_active = true
	manager.show_banner("IT IS COLLAPSING!", "Grab the SOLAR BOMB and THROW it into its maw!   (ATTACK = throw)", Color(1.0, 0.7, 0.3))
	SoundManager.play_sfx("rumble")
	_bomb = BombArt.new()
	add_child(_bomb)
	var bx := clampf(p.global_position.x + (160.0 if p.global_position.x < boss.global_position.x else -160.0), StoryManager.wall_left_x + 60.0, StoryManager.wall_right_x - 60.0)
	_bomb.global_position = Vector2(bx, _base_y - 500.0)
	var tw := create_tween()
	tw.tween_property(_bomb, "global_position:y", _base_y - 16.0, 0.6).set_trans(Tween.TRANS_BOUNCE).set_ease(Tween.EASE_OUT)
	await tw.finished
	await _wait(1.0)
	manager.hide_banner()
	while not _thrown and is_inside_tree():
		await get_tree().physics_frame
		if p.is_dead:
			return                                         # Died: StoryManager shows YOU DIED
		if not _carry and p.global_position.distance_to(_bomb.global_position) < 70.0:
			_carry = true
			SoundManager.play_sfx("heal", -4.0)
			Effects.popup(p, p.global_position + Vector2(0, -200), "SOLAR BOMB!  PRESS ATTACK TO THROW", Color(1.0, 0.85, 0.4), 22)
		if _carry:
			_bomb.global_position = p.global_position + Vector2(0, -150)
			var throw_now := StoryManager.autoplay or (p.ctl != null and p.ctl.just_pressed("attack"))
			if throw_now:
				await _throw_bomb()
	if not is_inside_tree():
		return
	# ---------------- 2. THE ESCAPE ----------------
	await _escape()


func _throw_bomb() -> void:
	_thrown = true
	SoundManager.play_sfx("whoosh")
	var target := boss.global_position + Vector2(0, -190)
	var from := _bomb.global_position
	var tw := create_tween()
	tw.tween_method(func(k: float) -> void:
		_bomb.global_position = from.lerp(target, k) + Vector2(0, -sin(k * PI) * 220.0), 0.0, 1.0, 0.7)
	await tw.finished
	_bomb.queue_free()
	boss.bomb_hit()
	Effects.explosion(boss, target, 180.0, true, true)
	Effects.shake(self, 20.0)
	SoundManager.play_sfx("explosion")
	SoundManager.play_sfx("roar")
	manager.show_banner("IT'S GOING TO BLOW!", "RUN!  Jump across the platforms before the explosion catches you!", Color(1.0, 0.5, 0.2))
	for i in 4:
		Effects.explosion(boss, boss.global_position + Vector2(randf_range(-160.0, 160.0), randf_range(-320.0, -60.0)), 120.0, true, true)
		Effects.shake(self, 10.0 + float(i) * 3.0)
		await _wait(0.4)
	manager.hide_banner()


func _escape() -> void:
	var p := _player()
	await manager.fade(true)
	# The boss is gone from the camera's view (the explosion is behind you now)
	boss.visible = false
	boss.remove_from_group("fighters")
	var partner := manager.partner
	if partner != null and is_instance_valid(partner):
		partner.visible = false
		partner.set_physics_process(false)
		partner.remove_from_group("fighters")
	_build_course()
	p.global_position = Vector2(COURSE_X + 80.0, _base_y)
	p.velocity = Vector2.ZERO
	p.facing = 1
	p.fall_death_y = _base_y + 5000.0                    # Falling here costs HP, it doesn't kill
	_safe = p.global_position
	_wall_x = COURSE_X - 420.0
	_wall = FireWall.new()
	add_child(_wall)
	_wall.global_position = Vector2(_wall_x, _base_y)
	var bg := manager.get_parent().get_node_or_null("Background") as HellBackground
	if bg != null:
		bg.theme = "sun_collapse"
	await manager.fade(false)
	manager.show_banner("ESCAPE!", "Jump!  The platforms fall after you land on them!", Color(1.0, 0.6, 0.25))
	_escaping = true
	await _wait(1.6)
	manager.hide_banner()
	while _escaping and is_inside_tree():
		await get_tree().physics_frame
		if p.is_dead:
			return
	if not is_inside_tree():
		return
	manager.show_banner("YOU ESCAPED!", "Behind you, The Consumer explodes...", Color(1.0, 0.9, 0.5))
	for i in 5:
		Effects.explosion(self, Vector2(_wall_x + randf_range(-200.0, 100.0), _base_y - randf_range(80.0, 400.0)), 160.0, true, true)
		Effects.shake(self, 14.0)
		await _wait(0.3)
	SoundManager.play_sfx("explosion")
	await _wait(1.2)
	manager.hide_banner()
	done.emit()


func _build_course() -> void:
	var rng := RandomNumberGenerator.new()
	rng.seed = 5050
	var x := COURSE_X
	var y := _base_y
	_add_platform(Rect2(x - 200.0, y, 420.0, 40.0), false)          # Start
	x += 220.0
	for i in PLATFORMS:
		var gap := rng.randf_range(100.0, 150.0) + float(i) * 3.0
		var w := rng.randf_range(150.0, 230.0) - float(i) * 4.0
		y = clampf(y + rng.randf_range(-55.0, 45.0), _base_y - 140.0, _base_y + 50.0)
		x += gap
		_add_platform(Rect2(x, y, w, 34.0), true)
		x += w
	x += 130.0
	_goal_x = x + 60.0
	_add_platform(Rect2(x, _base_y - 40.0, 520.0, 60.0), false)     # The ledge
	var flag := LedgeArt.new()
	add_child(flag)
	flag.global_position = Vector2(x + 260.0, _base_y - 40.0)


func _add_platform(r: Rect2, crumbles: bool) -> void:
	var body := StaticBody2D.new()
	body.collision_layer = CombatManager.WORLD_LAYER
	body.collision_mask = 0
	var col := CollisionShape2D.new()
	var shape := RectangleShape2D.new()
	shape.size = r.size
	col.shape = shape
	col.position = r.size * 0.5
	body.add_child(col)
	var art := PlatformArt.new()
	art.size = r.size
	art.crumbles = crumbles
	body.add_child(art)
	add_child(body)
	body.global_position = r.position
	_plats.append({"body": body, "rect": r, "fall_t": -1.0, "crumbles": crumbles, "art": art})


func _physics_process(delta: float) -> void:
	_t += delta
	if not _escaping:
		return
	var p := _player()
	if p == null or p.is_dead:
		return
	# --- Platforms you stand on crumble ---
	for pl in _plats:
		var body: StaticBody2D = pl["body"]
		if not is_instance_valid(body):
			continue
		var r: Rect2 = pl["rect"]
		var on := p.is_on_floor() and p.global_position.x >= r.position.x - 10.0 and p.global_position.x <= r.end.x + 10.0 \
			and absf(p.global_position.y - r.position.y) < 12.0
		if on:
			_safe = Vector2(clampf(p.global_position.x, r.position.x + 30.0, r.end.x - 30.0), r.position.y)
			if pl["crumbles"] and float(pl["fall_t"]) < 0.0:
				pl["fall_t"] = 0.0
				SoundManager.play_sfx("stone", -8.0)
		if float(pl["fall_t"]) >= 0.0:
			pl["fall_t"] = float(pl["fall_t"]) + delta
			(pl["art"] as PlatformArt).shake = float(pl["fall_t"])
			if float(pl["fall_t"]) > 1.0:
				body.global_position.y += 900.0 * delta * (float(pl["fall_t"]) - 0.9) * 3.0
				if body.global_position.y > r.position.y + 1200.0:
					body.queue_free()
		elif pl["crumbles"] and r.end.x < _wall_x + 20.0:
			pl["fall_t"] = 0.6                                # The fire reaches it
	# --- Falling = back to the last safe platform, minus HP ---
	if p.global_position.y > _base_y + 380.0:
		p.global_position = _safe + Vector2(0, -60)
		p.velocity = Vector2.ZERO
		p.take_damage(FALL_DAMAGE)
		Effects.popup(p, p.global_position + Vector2(0, -180), "FELL!  -%d" % FALL_DAMAGE, Color(1.0, 0.5, 0.4), 22)
	# --- The fire wall advances ---
	var spd := lerpf(WALL_SPEED, WALL_SPEED_MAX, clampf(_t / 40.0, 0.0, 1.0))
	if p.global_position.x - _wall_x > 900.0:
		spd *= 2.2                                            # It catches up if you are far ahead
	_wall_x += spd * delta
	_wall.global_position.x = _wall_x
	_fire_cd -= delta
	if p.global_position.x < _wall_x + 30.0 and _fire_cd <= 0.0:
		_fire_cd = 0.45
		p.take_damage(FIRE_DAMAGE, Vector2(520, -420))
		Effects.explosion(self, p.global_position + Vector2(-20, -60), 70.0, true, true)
	# --- Goal ---
	if p.global_position.x >= _goal_x and p.is_on_floor():
		_escaping = false
	if StoryManager.autoplay:
		_escaping = false                                     # Tests: the CPU can't platform


func _wait(seconds: float) -> void:
	var t := Timer.new()
	t.one_shot = true
	t.wait_time = maxf(seconds, 0.01)
	add_child(t)
	t.start()
	await t.timeout
	t.queue_free()


# ============================================================
# ART
# ============================================================
class BombArt extends Node2D:
	var _t := 0.0
	func _ready() -> void:
		z_index = 12
	func _process(delta: float) -> void:
		_t += delta
		queue_redraw()
	func _draw() -> void:
		var pulse := 0.5 + 0.5 * sin(_t * 8.0)
		draw_circle(Vector2.ZERO, 34.0 + pulse * 8.0, Color(1.0, 0.85, 0.4, 0.25))
		draw_circle(Vector2.ZERO, 20.0, Color(0, 0, 0))
		draw_circle(Vector2.ZERO, 17.0, Color(0.95, 0.75, 0.3))
		draw_circle(Vector2(-5, -5), 6.0, Color(1, 1, 0.9))
		draw_line(Vector2(6, -16), Vector2(14, -28), Color(0.3, 0.25, 0.2), 3.0)
		draw_circle(Vector2(14, -30), 4.0 + pulse * 3.0, Color(1.0, 0.6 + 0.4 * pulse, 0.2))
		FighterArt.label(self, Vector2(0, -48), "SOLAR BOMB", 14, Color(1.0, 0.9, 0.5))


class PlatformArt extends Node2D:
	var size := Vector2(200, 34)
	var crumbles := true
	var shake := 0.0
	func _ready() -> void:
		z_index = -2
	func _process(_delta: float) -> void:
		if shake > 0.0:
			queue_redraw()
	func _draw() -> void:
		var off := Vector2(randf_range(-3.0, 3.0), 0) * clampf(shake * 3.0, 0.0, 1.0) if shake > 0.0 else Vector2.ZERO
		var r := Rect2(off, size)
		var rock := PackedVector2Array([r.position, Vector2(r.end.x, r.position.y), Vector2(r.end.x - 14.0, r.end.y), Vector2(r.position.x + size.x * 0.5, r.end.y + 26.0), Vector2(r.position.x + 14.0, r.end.y)])
		draw_colored_polygon(rock, Color(0.78, 0.72, 0.62) if not crumbles else Color(0.62, 0.55, 0.46))
		draw_rect(Rect2(r.position, Vector2(size.x, 10.0)), Color(1.0, 0.92, 0.7))
		FighterArt.outline(self, rock, 4.0)
		if crumbles and shake > 0.0:
			for i in 4:
				var x := size.x * (0.2 + 0.2 * float(i))
				draw_line(off + Vector2(x, 0), off + Vector2(x + 8.0, size.y), Color(0.2, 0.1, 0.05), 2.0)


class FireWall extends Node2D:
	var _t := 0.0
	func _ready() -> void:
		z_index = 8
	func _process(delta: float) -> void:
		_t += delta
		queue_redraw()
	func _draw() -> void:
		draw_rect(Rect2(-2400, -1400, 2400, 2400), Color(1.0, 0.4, 0.05, 0.85))
		for i in 18:
			var y := -900.0 + float(i) * 70.0
			var r := 60.0 + 30.0 * sin(_t * 7.0 + float(i) * 1.7)
			draw_circle(Vector2(sin(_t * 3.0 + float(i)) * 30.0, y), r, Color(1.0, 0.65 + 0.2 * sin(float(i)), 0.2, 0.8))
			draw_circle(Vector2(-40.0 + sin(_t * 5.0 + float(i)) * 20.0, y + 30.0), r * 0.6, Color(1.0, 0.95, 0.6, 0.8))


class LedgeArt extends Node2D:
	var _t := 0.0
	func _ready() -> void:
		z_index = -1
	func _process(delta: float) -> void:
		_t += delta
		queue_redraw()
	func _draw() -> void:
		draw_line(Vector2(0, 0), Vector2(0, -160), Color(0.3, 0.25, 0.2), 6.0)
		draw_colored_polygon(PackedVector2Array([Vector2(0, -160), Vector2(70 + sin(_t * 4.0) * 6.0, -140), Vector2(0, -120)]), Color(0.3, 0.75, 1.0))
		FighterArt.label(self, Vector2(0, -180), "THE EDGE  -  ESCAPE HERE", 16, Color(1, 1, 1, 0.9))
