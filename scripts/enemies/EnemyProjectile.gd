class_name EnemyProjectile
extends Area2D
## ONE pooled projectile for every PvE enemy attack. Never .new() / queue_free():
##     var p := enemy.spawn_projectile()      # OptimizationManager.take(EnemyProjectile)
##     p.kind = EnemyProjectile.Kind.BOOMERANG; p.look = "axe"; p.damage = 8 ...
##     enemy.launch(p, start_pos)              # add_child + position
## When it is done it goes back to the pool (config reset to defaults).
##
## KINDS
##   LINEAR     flies along dir (waves, wind, glitter, lasers). pierce = hits each target once.
##   BOOMERANG  flies out range_px, then homes back to its thrower (axe, top hat).
##   DROP       shadow on the ground for `delay` s (telegraph), then falls and hits a radius
##              (piano, missiles).
## LOOKS (drawn here, all vector art, no textures): croak, frost, wind, glitter, laser,
##   shock (harmless ground ring), axe, hat, piano, missile.
## OPTIMIZATION: pooled, one collision shape reused, culled when off-screen,
##   redraws only while on screen.

enum Kind { LINEAR, BOOMERANG, DROP, ARC }
##   ARC        thrown with arc_velocity + gravity; on landing hits `radius` and calls
##              on_land(world_pos) (Blinded Lord's chemical globs -> chemical pools).

const ARC_GRAVITY := 1500.0

var pool_gen := 0

# ----- Config (reset to these defaults every time it returns to the pool) -----
var source: Fighter
var kind := Kind.LINEAR
var look := "croak"
var tint := Color.WHITE
var damage := 5
var knockback := Vector2(250, -150)
var move := "enemy_shot"
var dir := 1.0                         # LINEAR / BOOMERANG: -1 left, 1 right
var speed := 520.0
var lifetime := 1.0
var size := Vector2(40, 60)            # Collision box (LINEAR / BOOMERANG)
var pierce := true                     # false = vanish on the first hit
var harmless := false                  # Pure visual (shockwave rings, stress test)
var range_px := 380.0                  # BOOMERANG: distance before it turns back
var delay := 0.8                       # DROP: shadow warning time
var fall_height := 640.0               # DROP: starts this high above the floor
var radius := 70.0                     # DROP: impact radius
var exclude: Array = []                # Fighters this one must NOT hit (shared array, by reference)
var on_hit: Callable = Callable()      # Extra effect per victim, called with (victim: Fighter)
var arc_velocity := Vector2.ZERO       # ARC: launch velocity
var on_land: Callable = Callable()     # ARC: called with (world_pos: Vector2) when it lands

# ----- Runtime -----
var _age := 0.0
var _done := false
var _started := false
var _returning := false
var _start_x := 0.0
var _ground_y := 0.0
var _seed := 0
var _hit: Array[Fighter] = []
var _shape: RectangleShape2D
var _col: CollisionShape2D

const DROP_FALL_TIME := 0.32


func _init() -> void:
	collision_layer = 0
	collision_mask = CombatManager.HURTBOX_LAYER
	monitoring = true
	monitorable = false
	z_index = 8
	_shape = RectangleShape2D.new()
	_col = CollisionShape2D.new()
	_col.shape = _shape
	add_child(_col)


func _enter_tree() -> void:
	_age = 0.0
	_done = false
	_started = false
	_returning = false
	_hit.clear()
	_seed = randi()
	_shape.size = size
	_col.set_deferred("disabled", harmless or kind == Kind.DROP)
	set_physics_process(true)
	set_process(true)


## Back to the pool with the default config (the next user starts clean).
func recycle() -> void:
	if _done:
		return
	_done = true
	set_physics_process(false)
	set_process(false)
	_reset_config()
	OptimizationManager.release(self)


func _reset_config() -> void:
	source = null
	kind = Kind.LINEAR
	look = "croak"
	tint = Color.WHITE
	damage = 5
	knockback = Vector2(250, -150)
	move = "enemy_shot"
	dir = 1.0
	speed = 520.0
	lifetime = 1.0
	size = Vector2(40, 60)
	pierce = true
	harmless = false
	range_px = 380.0
	delay = 0.8
	fall_height = 640.0
	radius = 70.0
	exclude = []
	on_hit = Callable()
	arc_velocity = Vector2.ZERO
	on_land = Callable()
	scale = Vector2.ONE
	rotation = 0.0


# ============================================================
# UPDATE
# ============================================================
func _first_frame() -> void:
	_started = true
	_start_x = global_position.x
	if kind == Kind.DROP:
		# Sit ON the floor under the drop point (the shadow is the telegraph)
		var g: Variant = Effects.ground_below(self, global_position + Vector2(0, -260), 900.0)
		_ground_y = g.y if g != null else global_position.y
		global_position.y = _ground_y
	match look:
		"axe":
			Effects.trail(self, Color(0.55, 0.85, 1.0, 0.8), 10.0, 10)
		"hat":
			Effects.trail(self, Color(0.2, 0.2, 0.25, 0.6), 8.0, 8)
		"laser":
			Effects.trail(self, Color(1.0, 0.15, 0.1), 6.0, 8)


func _physics_process(delta: float) -> void:
	if _done:
		return
	if source != null and is_instance_valid(source) and source.is_time_frozen():
		return                                             # Time Stop freezes enemy shots too
	if not _started:
		_first_frame()
	_age += delta
	match kind:
		Kind.LINEAR:
			if _age >= lifetime:
				recycle()
				return
			global_position.x += dir * speed * delta
		Kind.BOOMERANG:
			if not _update_boomerang(delta):
				return
		Kind.DROP:
			_update_drop()
			return
		Kind.ARC:
			if not _update_arc(delta):
				return
	# Culling: anything that leaves the camera view (plus a margin) is recycled
	if not OptimizationManager.on_screen(global_position, 260.0):
		recycle()
		return
	if harmless:
		return
	for area in get_overlapping_areas():
		var hb := area as Hurtbox
		if hb == null or hb.fighter == null or hb.fighter.is_dead or _hit.has(hb.fighter) or exclude.has(hb.fighter):
			continue
		if source != null and is_instance_valid(source) and CombatManager.are_allies(source, hb.fighter):
			continue
		_hit_fighter(hb.fighter, global_position - Vector2(_move_dir() * 50.0, 0))
		if not pierce:
			Effects.hit_sparks(self, global_position, 5, 0.8)
			recycle()
			return


func _move_dir() -> float:
	if kind == Kind.BOOMERANG and _returning and source != null and is_instance_valid(source):
		return signf(source.global_position.x - global_position.x)
	return dir


## Returns false when the boomerang was caught / lost (already recycled).
func _update_boomerang(delta: float) -> bool:
	if _age >= lifetime or source == null or not is_instance_valid(source):
		_caught()
		return false
	if not _returning:
		global_position.x += dir * speed * delta
		if absf(global_position.x - _start_x) >= range_px:
			_returning = true
			_hit.clear()                                   # It can hit again on the way back
	else:
		var home := source.global_position + Vector2(0, -80)
		var to := home - global_position
		if to.length() < 40.0 or source.is_dead:
			_caught()
			return false
		global_position += to.normalized() * speed * 1.1 * delta
	rotation += dir * 18.0 * delta
	return true


func _caught() -> void:
	if source != null and is_instance_valid(source) and source.has_method("on_projectile_returned"):
		source.on_projectile_returned(look)
	recycle()


func _update_drop() -> void:
	if _age < delay + DROP_FALL_TIME:
		return
	# Impact
	_hit_radius(global_position + Vector2(0, -24), radius)
	Effects.shake(self, 9.0 if look == "piano" else 4.0)
	if look == "piano":
		Effects.hit_sparks(self, global_position + Vector2(0, -20), 10, 1.4)
		Effects.popup(self, global_position + Vector2(0, -90), "CRASH!", Color(1.0, 0.85, 0.3), 26)
		Effects.play_hit_sound(self, "piano_crash", global_position)
	else:
		Effects.explosion(self, global_position + Vector2(0, -20), radius * 0.8)
	recycle()


## Returns false once it has landed (already recycled).
func _update_arc(delta: float) -> bool:
	if _age >= lifetime:
		recycle()
		return false
	arc_velocity.y += ARC_GRAVITY * delta
	var nxt := global_position + arc_velocity * delta
	if arc_velocity.y > 0.0:
		var g: Variant = Effects.ground_below(self, Vector2(nxt.x, global_position.y - 4.0), 80.0)
		if g != null and nxt.y >= g.y - 4.0:
			global_position = Vector2(nxt.x, g.y)
			_hit_radius(global_position + Vector2(0, -20), radius)
			Effects.hit_sparks(self, global_position + Vector2(0, -8), 6, 0.9)
			if on_land.is_valid():
				on_land.call(global_position)
			recycle()
			return false
	global_position = nxt
	rotation = arc_velocity.angle()
	return true


func _hit_radius(center: Vector2, r: float) -> void:
	if harmless:
		return
	for n in get_tree().get_nodes_in_group("fighters") + get_tree().get_nodes_in_group("helpers"):
		var f := n as Fighter
		if f == null or f.is_dead or exclude.has(f):
			continue
		if source != null and is_instance_valid(source) and CombatManager.are_allies(source, f):
			continue
		var fc := f.global_position + Vector2(0, -f.data.body_size.y * 0.5)
		if absf(fc.x - center.x) > r + f.data.body_size.x * 0.5 or absf(fc.y - center.y) > r + f.data.body_size.y * 0.5:
			continue
		_hit_fighter(f, center)


func _hit_fighter(f: Fighter, origin: Vector2) -> void:
	_hit.append(f)
	var dx := signf(f.global_position.x - origin.x)
	if dx == 0.0:
		dx = dir
	var h := HitData.new()
	h.source = source if source != null and is_instance_valid(source) else null
	h.damage = damage
	h.knockback = Vector2(dx * knockback.x, knockback.y)
	h.origin = origin
	h.hit_type = "enemy"
	h.move = move
	if look == "missile":
		h.damage_kind = HitData.KIND_EXPLOSION
	var result := CombatManager.apply_hit(h, f)
	if result == "hit" and on_hit.is_valid():
		on_hit.call(f)


# ============================================================
# DRAW (only while on screen)
# ============================================================
func _process(_delta: float) -> void:
	if OptimizationManager.on_screen(global_position, 120.0):
		queue_redraw()


func _draw() -> void:
	var a := 1.0
	if kind == Kind.LINEAR:
		a = 1.0 - clampf((_age - lifetime * 0.65) / (lifetime * 0.35), 0.0, 1.0)
	match look:
		"croak":
			_draw_rings(Color(0.45, 0.95, 0.35) if tint == Color.WHITE else tint, a)
		"frost":
			_draw_frost(a)
		"wind":
			_draw_wind(a)
		"glitter":
			_draw_glitter(a)
		"laser":
			_draw_laser()
		"shock":
			_draw_shock(a)
		"axe":
			_draw_axe()
		"hat":
			_draw_hat()
		"piano", "missile":
			_draw_drop()
		"chem_glob":
			_draw_glob()


func _draw_rings(col: Color, a: float) -> void:
	for i in 3:
		var r := 20.0 + float(i) * 13.0 + _age * 34.0
		var off := Vector2(-dir * float(i) * 10.0, 0)
		var a0 := -0.9 if dir > 0.0 else PI - 0.9
		draw_arc(off, r, a0, a0 + 1.8, 18, Color(0, 0, 0, a), 7.0, true)
		draw_arc(off, r, a0, a0 + 1.8, 18, Color(col.r, col.g, col.b, a), 4.0, true)


func _draw_frost(a: float) -> void:
	# Ice spikes bursting out of the ground along the wave (origin = ground level centre)
	var base_y := size.y * 0.5
	for i in 4:
		var x := -dir * float(i) * 13.0
		var h := (34.0 - float(i) * 6.0) * (0.75 + 0.25 * sin(_age * 30.0 + float(i)))
		var pts := PackedVector2Array([Vector2(x - 8, base_y), Vector2(x + 2 * dir, base_y - h), Vector2(x + 8, base_y)])
		draw_colored_polygon(pts, Color(0.6, 0.88, 1.0, a))
		FighterArt.outline(self, pts, 2.5, Color(0.05, 0.12, 0.25, a))
		draw_line(Vector2(x, base_y - 3), Vector2(x + dir, base_y - h * 0.6), Color(1, 1, 1, a * 0.8), 2.0)
	draw_circle(Vector2(0, base_y - 6), 20.0, Color(0.8, 0.95, 1.0, 0.25 * a))


func _draw_wind(a: float) -> void:
	for i in 4:
		var y := -42.0 + float(i) * 28.0
		var len := 46.0 + 10.0 * sin(_age * 20.0 + float(i) * 1.3)
		var pts := PackedVector2Array()
		for k in 7:
			var t := float(k) / 6.0
			pts.append(Vector2(-dir * len * 0.5 + dir * len * t, y + sin(t * PI * 2.0 + _age * 18.0) * 5.0))
		draw_polyline(pts, Color(0.75, 0.9, 1.0, 0.5 * a), 7.0, true)
		draw_polyline(pts, Color(1, 1, 1, a), 3.0, true)


func _draw_glitter(a: float) -> void:
	var rng := RandomNumberGenerator.new()
	rng.seed = _seed
	var grow := 0.6 + _age * 1.6
	for i in 18:
		var p := Vector2(rng.randf_range(-40.0, 40.0), rng.randf_range(-40.0, 40.0)) * grow
		var col := Color.from_hsv(rng.randf(), 0.55, 1.0, a)
		var r := rng.randf_range(2.5, 5.0)
		var tw := 0.6 + 0.4 * sin(_age * 25.0 + float(i))
		draw_colored_polygon(PackedVector2Array([p + Vector2(0, -r * 1.8 * tw), p + Vector2(r * 0.5, 0), p + Vector2(0, r * 1.8 * tw), p + Vector2(-r * 0.5, 0)]), col)
		draw_colored_polygon(PackedVector2Array([p + Vector2(-r * 1.8 * tw, 0), p + Vector2(0, r * 0.5), p + Vector2(r * 1.8 * tw, 0), p + Vector2(0, -r * 0.5)]), col)


func _draw_laser() -> void:
	draw_line(Vector2(-34 * dir, 0), Vector2(30 * dir, 0), Color(1.0, 0.2, 0.15, 0.35), 14.0, true)
	draw_line(Vector2(-34 * dir, 0), Vector2(30 * dir, 0), Color(0, 0, 0), 7.0, true)
	draw_line(Vector2(-32 * dir, 0), Vector2(28 * dir, 0), Color(1.0, 0.15, 0.1), 4.0, true)
	draw_line(Vector2(-28 * dir, 0), Vector2(24 * dir, 0), Color(1.0, 0.85, 0.8), 1.5, true)


func _draw_shock(a: float) -> void:
	var w := 26.0 + _age * 40.0
	draw_arc(Vector2(0, 0), w, PI, TAU, 16, Color(0, 0, 0, a), 7.0, true)
	draw_arc(Vector2(0, 0), w, PI, TAU, 16, Color(tint.r, tint.g, tint.b, a), 4.0, true)


func _draw_glob() -> void:
	# Toxic chemical blob stretched along its flight direction (node rotation)
	var wob := 1.0 + 0.12 * sin(_age * 30.0)
	draw_circle(Vector2.ZERO, 16.0, Color(0.55, 1.0, 0.2, 0.25))
	var pts := EnemyArt.ellipse_points(Vector2.ZERO, 13.0 * wob, 9.0 / wob, 14)
	draw_colored_polygon(pts, Color(0.45, 0.95, 0.15))
	FighterArt.outline(self, pts, 3.0)
	draw_circle(Vector2(-12, 0), 5.0, Color(0.35, 0.8, 0.1))           # Trailing drop
	draw_circle(Vector2(4, -3), 3.0, Color(0.9, 1.0, 0.7))             # Shine


func _draw_axe() -> void:
	# Handle + icy blade (rotates with the node)
	draw_line(Vector2(-22, 0), Vector2(18, 0), Color(0, 0, 0), 8.0)
	draw_line(Vector2(-22, 0), Vector2(18, 0), Color(0.45, 0.28, 0.14), 5.0)
	var blade := PackedVector2Array([Vector2(8, -4), Vector2(22, -20), Vector2(30, -6), Vector2(28, 10), Vector2(10, 6)])
	draw_colored_polygon(blade, Color(0.72, 0.9, 1.0))
	FighterArt.outline(self, blade, 3.0)
	draw_line(Vector2(22, -16), Vector2(28, 6), Color(1, 1, 1, 0.9), 2.0)
	draw_circle(Vector2(14, 0), 3.0, Color(0.3, 0.7, 1.0))


func _draw_hat() -> void:
	var brim := FighterArt.rrect_points(Rect2(-22, 8, 44, 7), 3.0)
	draw_colored_polygon(brim, Color(0.08, 0.08, 0.1))
	FighterArt.outline(self, brim, 2.5)
	var crown := FighterArt.rrect_points(Rect2(-14, -26, 28, 36), 3.0)
	draw_colored_polygon(crown, Color(0.1, 0.1, 0.12))
	FighterArt.outline(self, crown, 2.5)
	draw_rect(Rect2(-14, 0, 28, 6), Color(0.35, 0.35, 0.4))


func _draw_drop() -> void:
	var fall_k := clampf((_age - delay) / DROP_FALL_TIME, 0.0, 1.0)
	var warn_k := clampf(_age / maxf(delay, 0.01), 0.0, 1.0)
	# Ground shadow: grows while the object falls (the telegraph)
	var sw := radius * (0.45 + 0.55 * maxf(warn_k * 0.7, fall_k))
	draw_set_transform(Vector2.ZERO, 0.0, Vector2(1.0, 0.25))
	draw_circle(Vector2.ZERO, sw, Color(0, 0, 0, 0.25 + 0.35 * warn_k))
	draw_arc(Vector2.ZERO, radius, 0.0, TAU, 32, Color(1.0, 0.25, 0.2, 0.5 + 0.4 * sin(_age * 18.0)), 6.0, true)
	draw_set_transform(Vector2.ZERO, 0.0, Vector2.ONE)
	if _age < delay * 0.55:
		return                                             # Only the warning at first
	var y := -fall_height * (1.0 - fall_k * fall_k) - 4.0
	if look == "piano":
		_draw_piano(Vector2(0, y))
	else:
		_draw_missile(Vector2(0, y))


func _draw_piano(p: Vector2) -> void:
	var body := FighterArt.rrect_points(Rect2(p.x - 48, p.y - 52, 96, 46), 6.0)
	draw_colored_polygon(body, Color(0.07, 0.07, 0.09))
	FighterArt.outline(self, body, 4.0)
	draw_rect(Rect2(p.x - 42, p.y - 20, 84, 12), Color(0.97, 0.97, 0.94))
	for i in 7:
		draw_rect(Rect2(p.x - 38 + float(i) * 12.0, p.y - 20, 5, 7), Color(0.05, 0.05, 0.05))
	draw_line(Vector2(p.x - 40, p.y - 6), Vector2(p.x - 40, p.y + 2), Color(0, 0, 0), 5.0)
	draw_line(Vector2(p.x + 40, p.y - 6), Vector2(p.x + 40, p.y + 2), Color(0, 0, 0), 5.0)
	draw_circle(Vector2(p.x - 26, p.y - 40), 5.0, Color(1.0, 0.85, 0.3))            # Gold star decal
	draw_line(Vector2(p.x - 20, p.y - 70), Vector2(p.x - 26, p.y - 90), Color(1, 1, 1, 0.6), 3.0)   # Speed lines
	draw_line(Vector2(p.x + 20, p.y - 70), Vector2(p.x + 26, p.y - 90), Color(1, 1, 1, 0.6), 3.0)


func _draw_missile(p: Vector2) -> void:
	var body := PackedVector2Array([p + Vector2(-6, -26), p + Vector2(6, -26), p + Vector2(6, -4), p + Vector2(0, 6), p + Vector2(-6, -4)])
	draw_colored_polygon(body, Color(0.75, 0.78, 0.82))
	FighterArt.outline(self, body, 2.5)
	draw_colored_polygon(PackedVector2Array([p + Vector2(-6, -4), p + Vector2(6, -4), p + Vector2(0, 6)]), Color(1.0, 0.2, 0.15))
	var fl := 10.0 + 6.0 * sin(_age * 50.0)
	draw_colored_polygon(PackedVector2Array([p + Vector2(-4, -26), p + Vector2(4, -26), p + Vector2(0, -26 - fl)]), Color(1.0, 0.6, 0.15))
