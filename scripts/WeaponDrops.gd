class_name WeaponDrops
extends Node
## WEAPON PICKUPS IN VERSUS (2026-11-23, picked by the user). Weapons from the user's medieval list
## (HuntArt.WEAPONS) drop into the arena. Walk over one to pick it up (CPU fighters too):
##   ATTACK  swings it instead of your punch - 4 swings
##   the 5th ATTACK sets it AFLAME and THROWS it (like the Head Heavy Nightmare Guards)
## Light blades: quick, 8 dmg. Heavy weapons: slow, 12 dmg. Polearms: long reach, 10 dmg.
## Versus only (not Story, not replays); Match Settings > WEAPON DROPS turns it off.

const EVERY := Vector2(14.0, 22.0)            # Seconds between drops
const MAX_ON_FLOOR := 2
const SWINGS := 4
const HEAVY := ["greatsword", "greataxe", "axe", "hammer", "mace", "club", "flail", "anchor", "pick"]
const POLE := ["halberd", "glaive", "spear", "lance", "scythe"]

var _next := 8.0
var _rng := RandomNumberGenerator.new()


func _ready() -> void:
	_rng.randomize()


func _process(delta: float) -> void:
	if not CombatManager.fight_active:
		return
	_next -= delta
	if _next > 0.0:
		return
	_next = _rng.randf_range(EVERY.x, EVERY.y)
	if get_tree().get_nodes_in_group("weapon_pickup").size() >= MAX_ON_FLOOR:
		return
	var g := get_tree().get_first_node_in_group("arena_ground") as ArenaGround
	if g == null:
		return
	var p := Pickup.new()
	p.weapon = String(HuntArt.weapon_names()[_rng.randi() % HuntArt.weapon_names().size()])
	get_parent().add_child(p)
	var x := _rng.randf_range(g.left_edge() + 120.0, g.right_edge() - 120.0)
	var ground: Variant = Effects.ground_below(p, Vector2(x, -600.0), 3000.0)
	p.floor_y = (ground as Vector2).y if ground != null else 500.0
	p.global_position = Vector2(x, p.floor_y - 700.0)


static func family(weapon: String) -> String:
	return String(HuntArt.WEAPONS.get(weapon, "sword"))


static func stats(weapon: String) -> Dictionary:
	var fam := family(weapon)
	if HEAVY.has(fam):
		return {"dmg": 12, "reach": 150.0, "cd": 0.75, "kb": Vector2(520, -320)}
	if POLE.has(fam):
		return {"dmg": 10, "reach": 190.0, "cd": 0.55, "kb": Vector2(420, -240)}
	return {"dmg": 8, "reach": 120.0, "cd": 0.38, "kb": Vector2(300, -200)}


## Called by ControlledFighter before its own actions. true = the weapon took this ATTACK press.
static func try_attack(f: ControlledFighter) -> bool:
	var h := f.get_node_or_null("HeldWeapon") as Held
	if h == null or not f.ctl.just_pressed("attack"):
		return false
	h.use()
	return true


# ============================================================
# A WEAPON LYING IN THE ARENA
# ============================================================
class Pickup extends Node2D:
	var weapon := "SWORD"
	var floor_y := 0.0
	var _t := 0.0
	var _vy := 0.0

	func _ready() -> void:
		add_to_group("weapon_pickup")
		z_index = 2

	func _process(delta: float) -> void:
		_t += delta
		if global_position.y < floor_y - 30.0:                     # Falling in
			_vy += 1800.0 * delta
			global_position.y = minf(global_position.y + _vy * delta, floor_y - 30.0)
			if global_position.y >= floor_y - 30.0:
				SoundManager.play_sfx("stone", -6.0)
		elif _t > 0.3:
			for n in get_tree().get_nodes_in_group("fighters"):
				var f := n as ControlledFighter
				if f == null or f.is_dead or f.get_node_or_null("HeldWeapon") != null:
					continue
				if absf(f.global_position.x - global_position.x) < 60.0 and absf(f.global_position.y - floor_y) < 90.0:
					var h := Held.new()
					h.name = "HeldWeapon"
					h.weapon = weapon
					f.add_child(h)
					Effects.popup(f, f.global_position + Vector2(0, -f.data.body_size.y - 50.0), weapon + "!", Color(1.0, 0.85, 0.5), 22)
					SoundManager.play_sfx("spawn", -6.0)
					queue_free()
					return
		queue_redraw()

	func _draw() -> void:
		var bob := sin(_t * 3.0) * 5.0
		draw_circle(Vector2(0, 20), 30.0, Color(1.0, 0.85, 0.4, 0.12 + 0.06 * sin(_t * 4.0)))
		HuntArt.weapon(self, weapon, Vector2(-40, bob), -0.35, 0.8, _t)
		if fmod(_t, 1.6) < 0.2:                                        # A glint
			draw_line(Vector2(-6, bob - 26), Vector2(6, bob - 14), Color(1, 1, 1, 0.9), 2.0)


# ============================================================
# A WEAPON IN A FIGHTER'S HAND
# ============================================================
class Held extends Node2D:
	var net_sync := true                   # ONLINE: shown on the guest too (NetHost: a fighter's child)
	var weapon := "SWORD"
	var swings_left := SWINGS
	var _t := 0.0
	var _swing := -1.0                     # >= 0: swinging (seconds)
	var _cd := 0.0
	var _burn := 0.0                       # > 0: about to be thrown (aflame)

	func _ready() -> void:
		z_index = 3

	func _owner_f() -> ControlledFighter:
		return get_parent() as ControlledFighter

	func use() -> void:
		var f := _owner_f()
		if f == null or _cd > 0.0 or _burn > 0.0:
			return
		var st := WeaponDrops.stats(weapon)
		if swings_left <= 0:
			_burn = 0.35                                               # It catches fire... then flies
			SoundManager.play_sfx("flame", -4.0)
			return
		swings_left -= 1
		_swing = 0.0
		_cd = float(st["cd"])
		SoundManager.play_sfx("sword_slash", -4.0)
		var reach: float = st["reach"]
		var h := f.data.body_size.y
		var box := Rect2(f.global_position + Vector2(f.facing * reach * 0.5 - reach * 0.5, -h), Vector2(reach, h))
		for n in f.get_tree().get_nodes_in_group("fighters"):
			var v := n as Fighter
			if v == null or v == f or v.is_dead or CombatManager.are_allies(f, v):
				continue
			if box.has_point(v.global_position + Vector2(0, -v.data.body_size.y * 0.5)):
				var hit := HitData.new()
				hit.source = f
				hit.damage = int(st["dmg"])
				var kb: Vector2 = st["kb"]
				hit.knockback = Vector2(kb.x * f.facing, kb.y)
				hit.origin = f.global_position
				hit.hit_type = "sword"
				hit.move = "weapon_" + WeaponDrops.family(weapon)
				CombatManager.apply_hit(hit, v)
				if f.ctl != null and f.ctl.is_human():
					Daily.progress("weapon_hits")                    # DAILY challenges

	func _throw() -> void:
		var f := _owner_f()
		if f == null:
			queue_free()
			return
		var p := OptimizationManager.take(EnemyProjectile) as EnemyProjectile
		p.source = f
		p.kind = EnemyProjectile.Kind.LINEAR
		p.look = "nm_weapon"
		p.art_id = weapon
		p.burning = true
		p.dir = float(f.facing)
		p.speed = 700.0
		p.lifetime = 1.8
		p.size = Vector2(90, 60)
		p.damage = int(WeaponDrops.stats(weapon)["dmg"]) + 3
		p.knockback = Vector2(360, -260)
		p.pierce = false
		p.move = "weapon_throw"
		f.get_parent().add_child(p)
		p.global_position = f.global_position + Vector2(f.facing * 50.0, -f.data.body_size.y * 0.6)
		SoundManager.play_sfx("whoosh")
		queue_free()

	func _process(delta: float) -> void:
		var f := _owner_f()
		if f == null or f.is_dead:
			queue_free()
			return
		_t += delta
		_cd = maxf(_cd - delta, 0.0)
		if _swing >= 0.0:
			_swing += delta
			if _swing > 0.25:
				_swing = -1.0
		if _burn > 0.0:
			_burn -= delta
			if _burn <= 0.0:
				_throw()
				return
		position = Vector2(f.facing * 26.0, -f.data.body_size.y * 0.55)
		queue_redraw()

	func _draw() -> void:
		var f := _owner_f()
		if f == null:
			return
		var ang := -1.1
		if _swing >= 0.0:
			ang = lerpf(-2.3, 0.7, clampf(_swing / 0.18, 0.0, 1.0))
		elif _burn > 0.0:
			ang = -2.4
		if f.facing < 0:
			ang = PI - ang
		HuntArt.weapon(self, weapon, Vector2.ZERO, ang, 0.75, _t, _burn > 0.0)
		if swings_left < SWINGS and _burn <= 0.0:                     # Little pips: swings left
			for i in swings_left:
				draw_circle(Vector2(-12.0 + float(i) * 8.0, -44.0), 2.5, Color(1.0, 0.85, 0.5, 0.8))
