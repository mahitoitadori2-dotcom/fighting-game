class_name ExtEnemy
extends SimpleEnemy
## Base for the BOSS EXTENSION regular enemies (Story Mode BC / AG / VM / AC / FM levels).
## Same system as every other Story enemy (SimpleEnemy + EnemyPattern + SimpleEnemyAI); this
## only adds short attack helpers so each enemy file stays small.


## Patterns during which hits from the FRONT are blocked (shield block / guard).
var guard_ids: Array = []
## < 1 while a damage-reduction move runs (fire shield...). Set / reset by the enemy.
var shield_mult := 1.0


func guarding() -> bool:
	return current != null and guard_ids.has(current.id) and (estate == EState.TELEGRAPH or estate == EState.ATTACK)


func take_hit(amount: int, hit: HitData) -> void:
	if amount > 0 and hit != null and guarding():
		var from := signf(hit.origin.x - global_position.x)
		if from == 0.0 or int(from) == facing:
			Effects.popup(self, global_position + Vector2(0, -data.body_size.y - 30.0), "BLOCKED", Color(0.8, 0.85, 1.0), 18)
			Effects.hit_sparks(self, global_position + Vector2(facing * 26.0, -data.body_size.y * 0.6), 5, 0.8)
			SoundManager.play_sfx("block", -6.0)
			return
	if amount > 0 and shield_mult < 1.0:
		amount = maxi(1, roundi(float(amount) * shield_mult))
	super.take_hit(amount, hit)


## Melee box in front of us (offset x mirrored by facing).
func melee(damage: int, kb: Vector2, off: Vector2, size: Vector2, move: String) -> void:
	hitbox.activate(make_hit(damage, Vector2(facing * kb.x, kb.y), move), Vector2(facing * off.x, off.y), size)


## Straight projectile from an offset (x mirrored by facing).
func shot(look: String, off: Vector2, spd: float, life: float, size: Vector2, damage: int, kb: Vector2,
		tint: Color = Color.WHITE, move: String = "ext_shot", pierce: bool = false) -> EnemyProjectile:
	var p := spawn_projectile()
	p.kind = EnemyProjectile.Kind.LINEAR
	p.look = look
	p.tint = tint
	p.dir = float(facing)
	p.speed = spd
	p.lifetime = life
	p.size = size
	p.damage = damage
	p.knockback = kb
	p.pierce = pierce
	p.move = move
	launch(p, global_position + Vector2(facing * off.x, off.y))
	return p


## Lobbed projectile that lands on to_x after `flight` seconds.
func lob(look: String, off: Vector2, to_x: float, flight: float, damage: int, kb: Vector2, radius: float,
		tint: Color = Color.WHITE, move: String = "ext_lob", on_land: Callable = Callable()) -> EnemyProjectile:
	var g := spawn_projectile()
	g.kind = EnemyProjectile.Kind.ARC
	g.look = look
	g.tint = tint
	g.damage = damage
	g.knockback = kb
	g.radius = radius
	g.pierce = false
	g.size = Vector2(radius, radius)
	g.lifetime = flight + 2.0
	g.move = move
	var from := global_position + Vector2(facing * off.x, off.y)
	var drop := global_position.y - from.y
	g.arc_velocity = Vector2((to_x - from.x) / flight, (drop - 0.5 * EnemyProjectile.ARC_GRAVITY * flight * flight) / flight)
	if on_land.is_valid():
		g.on_land = on_land
	launch(g, from)
	return g


## Puddle on the floor under x: "poison" (green), "fire" (lava) or "void".
func pool_at(x: float, width: float, life: float, kind: String = "poison") -> void:
	var g: Variant = Effects.ground_below(self, Vector2(clamp_to_ground(x, 40.0), global_position.y - 40.0), 300.0)
	if g == null:
		return
	match kind:
		"fire":
			ChemicalPool.spawn_lava(self, g as Vector2, width, life)
		"void":
			ChemicalPool.spawn_void(self, g as Vector2, width, life)
		_:
			ChemicalPool.spawn(self, g as Vector2, width, life)


## Dash forward (call every frame from _on_attack_update). Stops at walls / ledges.
func dash_step(spd: float) -> void:
	velocity.x = facing * spd
	if is_on_wall() or not ground_ahead(50.0):
		velocity.x = 0.0
		state_time = state_len


## Short teleport to a spot near x (stays on the island).
func blink_to(x: float) -> void:
	Effects.void_burst(self, global_position + Vector2(0, -50), 50.0)
	global_position.x = clamp_to_ground(x, 60.0)
	if StoryManager.has_walls:
		global_position.x = clampf(global_position.x, StoryManager.arena_left() + 50.0, StoryManager.arena_right() - 50.0)
	Effects.void_burst(self, global_position + Vector2(0, -50), 50.0)
	SoundManager.play_sfx("whoosh", -6.0)
