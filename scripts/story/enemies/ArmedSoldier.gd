class_name ArmedSoldier
extends SimpleEnemy
## Shared WEAPON KIT for the Story soldiers (Enlightened Guard, Architectian Warrior).
## A soldier is spawned with a `weapon` (StoryLevels.make_enemy sets it). The class's own
## weapon ("" / native_weapon()) keeps its original moves; every other weapon uses the
## shared moves below, so one soldier class can field five different fighters:
##
##   short_sword  fast + fragile   Quick Slash, Lunge (dashes in from range)
##   hammer       slow + heavy     Hammer Smash, Ground Pound (shockwave along the floor: jump it)
##   greatshield  the tank         a tower shield that blocks most damage from the FRONT while
##                                 it is not attacking: hit it from behind, or right after its
##                                 Shield Bash / Shield Slam
##   spear        reach            Spear Thrust, Low Sweep (jump it)
##   bow          stays far away   Arrow, Arrow Volley (3 arrows rain down on you), Kick (pushes you off)

const FRONT_GUARD := 0.2            # Greatshield: share of the damage that gets through from the front
const LUNGE_SPEED := 560.0

## OVERRIDE: the class's own weapon ("spear" for the Guard, "hammer" for the Warrior).
func native_weapon() -> String:
	return ""

## OVERRIDE: display names per weapon ({"bow": "Enlightened Archer", ...}).
func weapon_names() -> Dictionary:
	return {}

## OVERRIDE: weapon colours {"arm", "arm_shade", "arm_hi", "hand", "metal", "accent", "dark", "wood"}.
static func palette() -> Dictionary:
	return {}

var weapon := ""                    # "" = the native weapon
var _clang_cd := 0.0


func is_native() -> bool:
	return weapon == "" or weapon == native_weapon()


# ============================================================
# STATS + PATTERNS
# ============================================================
## Stat block + AI distances of a non-native weapon.
func weapon_data(base_hp: int) -> CharacterData:
	var nm := String(weapon_names().get(weapon, "Soldier"))
	phase2_threshold = -1.0
	attack_chance = 0.6
	match weapon:
		"short_sword":
			keep_min = 30.0
			keep_max = 95.0
			attack_chance = 0.7
			return SimpleEnemy.make_data(nm, base_hp - 8, Vector2(58, 136), 245.0)
		"hammer":
			keep_min = 40.0
			keep_max = 115.0
			return SimpleEnemy.make_data(nm, base_hp + 8, Vector2(66, 142), 140.0)
		"greatshield":
			keep_min = 30.0
			keep_max = 100.0
			attack_chance = 0.5
			return SimpleEnemy.make_data(nm, base_hp + 12, Vector2(70, 142), 120.0)
		"bow":
			keep_min = 320.0
			keep_max = 560.0
			attack_chance = 0.55
			return SimpleEnemy.make_data(nm, base_hp - 10, Vector2(56, 134), 200.0)
	# spear (on a class whose native weapon is something else)
	keep_min = 60.0
	keep_max = 140.0
	return SimpleEnemy.make_data(nm, base_hp, Vector2(60, 140), 180.0)


static func weapon_patterns(w: String) -> Array[EnemyPattern]:
	var list: Array[EnemyPattern] = []
	#                                  id         name              cd   dmg  min    max    anim       tele  active rec   big    weights
	match w:
		"short_sword":
			list.append(EnemyPattern.make("w_slash", "QUICK SLASH", 1.3, 4, 0.0, 105.0, "w_slash", 0.28, 0.14, 0.32, false, [2.0, 2.0]))
			list.append(EnemyPattern.make("w_lunge", "LUNGE", 4.0, 6, 120.0, 330.0, "w_lunge", 0.42, 0.30, 0.45, true, [1.0, 1.0]))
		"hammer":
			list.append(EnemyPattern.make("w_smash", "HAMMER SMASH", 2.8, 9, 0.0, 130.0, "w_smash", 0.62, 0.18, 0.60, true, [2.0, 2.0]))
			list.append(EnemyPattern.make("w_pound", "GROUND POUND", 6.0, 5, 0.0, 460.0, "w_pound", 0.70, 0.20, 0.70, true, [1.0, 1.0]))
			list[1].note = "sends a shockwave along the floor: jump it"
		"greatshield":
			list.append(EnemyPattern.make("w_bash", "SHIELD BASH", 2.4, 5, 0.0, 110.0, "w_bash", 0.35, 0.22, 0.55, false, [2.0, 2.0]))
			list.append(EnemyPattern.make("w_slam", "SHIELD SLAM", 5.5, 7, 0.0, 150.0, "w_slam", 0.60, 0.18, 0.80, true, [1.0, 1.0]))
			list[0].note = "blocks most damage from the front: hit it from behind or right after it attacks"
		"spear":
			list.append(EnemyPattern.make("w_thrust", "SPEAR THRUST", 2.2, 6, 0.0, 175.0, "w_thrust", 0.45, 0.18, 0.45, false, [2.0, 2.0]))
			list.append(EnemyPattern.make("w_sweep", "LOW SWEEP", 4.2, 5, 0.0, 150.0, "w_sweep", 0.50, 0.20, 0.50, true, [1.0, 1.0]))
			list[1].note = "hits low: jump it"
		"bow":
			list.append(EnemyPattern.make("w_shoot", "ARROW", 2.2, 4, 180.0, 760.0, "w_shoot", 0.50, 0.12, 0.40, false, [2.0, 2.0]))
			list.append(EnemyPattern.make("w_volley", "ARROW VOLLEY", 6.5, 3, 200.0, 760.0, "w_volley", 0.80, 0.20, 0.60, true, [1.0, 1.0]))
			list.append(EnemyPattern.make("w_kick", "KICK", 2.5, 2, 0.0, 95.0, "w_kick", 0.20, 0.14, 0.35, false, [1.5, 1.5]))
			list[1].note = "three arrows rain down where you stand"
	return list


func build_patterns() -> Array[EnemyPattern]:
	if is_native():
		return super.build_patterns()
	return weapon_patterns(weapon)


# ============================================================
# ATTACKS (non-native weapons)
# ============================================================
func _weapon_attack(p: EnemyPattern) -> void:
	var f := float(facing)
	var pal := palette_of()
	match p.id:
		"w_slash":
			hitbox.activate(make_hit(dmg(p), Vector2(f * 240.0, -150.0), "soldier_slash"), Vector2(f * 58.0, -76.0), Vector2(84, 80))
			velocity.x = f * 160.0
			SoundManager.play_sfx("sword_slash", -4.0)
		"w_lunge":
			hitbox.activate(make_hit(dmg(p), Vector2(f * 360.0, -170.0), "soldier_lunge"), Vector2(f * 50.0, -76.0), Vector2(80, 70))
			SoundManager.play_sfx("dash", -4.0)
		"w_smash":
			hitbox.activate(make_hit(dmg(p), Vector2(f * 380.0, -320.0), "soldier_smash"), Vector2(f * 80.0, -50.0), Vector2(110, 110))
			Effects.shake(self, 6.0)
			Effects.hit_sparks(self, global_position + Vector2(f * 90.0, -6.0), 8, 1.1)
			SoundManager.play_sfx("slam", -4.0)
		"w_pound":
			hitbox.activate(make_hit(dmg(p), Vector2(f * 260.0, -300.0), "soldier_pound"), Vector2(f * 70.0, -40.0), Vector2(110, 80))
			var w := spawn_projectile()
			w.kind = EnemyProjectile.Kind.LINEAR
			w.look = "shock"
			w.tint = pal.get("accent", Color.WHITE)
			w.damage = maxi(1, dmg(p) - 1)
			w.knockback = Vector2(240, -300)
			w.dir = f
			w.speed = 520.0
			w.lifetime = 0.9
			w.size = Vector2(50, 40)
			w.move = "soldier_shockwave"
			launch(w, global_position + Vector2(f * 80.0, -20.0))
			Effects.shake(self, 9.0)
			SoundManager.play_sfx("slam")
		"w_bash":
			hitbox.activate(make_hit(dmg(p), Vector2(f * 460.0, -160.0), "soldier_bash"), Vector2(f * 46.0, -74.0), Vector2(66, 120))
			velocity.x = f * 420.0
			SoundManager.play_sfx("block", -4.0)
		"w_slam":
			hitbox.activate(make_hit(dmg(p), Vector2(f * 300.0, -380.0), "soldier_slam"), Vector2(f * 70.0, -50.0), Vector2(120, 100))
			Effects.shake(self, 8.0)
			Effects.hit_sparks(self, global_position + Vector2(f * 70.0, -6.0), 8, 1.1)
			SoundManager.play_sfx("slam", -3.0)
		"w_thrust":
			hitbox.activate(make_hit(dmg(p), Vector2(f * 300.0, -160.0), "soldier_thrust"), Vector2(f * 100.0, -78.0), Vector2(160, 40))
			velocity.x = f * 140.0
			SoundManager.play_sfx("sword_slash", -5.0)
		"w_sweep":
			hitbox.activate(make_hit(dmg(p), Vector2(f * 200.0, -360.0), "soldier_sweep"), Vector2(f * 70.0, -18.0), Vector2(160, 36))
			SoundManager.play_sfx("swing", -4.0)
		"w_shoot":
			_arrow(dmg(p), pal)
			SoundManager.play_sfx("whoosh", -5.0)
		"w_volley":
			for i in 3:
				_volley_arrow(dmg(p), i, pal)
			SoundManager.play_sfx("whoosh", -3.0)
		"w_kick":
			hitbox.activate(make_hit(dmg(p), Vector2(f * 480.0, -200.0), "soldier_kick"), Vector2(f * 44.0, -50.0), Vector2(60, 60))
			SoundManager.play_sfx("punch", -4.0)


func _arrow(d: int, pal: Dictionary) -> void:
	var a := spawn_projectile()
	a.kind = EnemyProjectile.Kind.LINEAR
	a.look = "arrow"
	a.tint = pal.get("accent", Color.WHITE)
	a.dir = float(facing)
	a.speed = 760.0
	a.lifetime = 1.3
	a.size = Vector2(46, 14)
	a.damage = d
	a.knockback = Vector2(200, -120)
	a.pierce = false
	a.move = "soldier_arrow"
	launch(a, global_position + Vector2(facing * 44.0, -84.0))


## One of three arrows shot up that rain down around the target.
func _volley_arrow(d: int, i: int, pal: Dictionary) -> void:
	var a := spawn_projectile()
	a.kind = EnemyProjectile.Kind.ARC
	a.look = "arrow"
	a.tint = pal.get("accent", Color.WHITE)
	a.damage = d
	a.knockback = Vector2(160, -200)
	a.radius = 34.0
	a.size = Vector2(30, 30)
	a.lifetime = 3.0
	a.pierce = false
	a.move = "soldier_volley"
	var start := global_position + Vector2(facing * 30.0, -110.0)
	var tx := clamp_to_ground(target_x() + float(i - 1) * 110.0, 40.0)
	var flight := 1.05 + 0.12 * float(i)
	a.arc_velocity = Vector2((tx - start.x) / flight, -0.5 * EnemyProjectile.ARC_GRAVITY * flight)
	launch(a, start)


func _on_attack_update(p: EnemyPattern, _delta: float) -> void:
	if p.id == "w_lunge":
		velocity.x = facing * LUNGE_SPEED
		if is_on_wall() or not ground_ahead(50.0):
			state_time = state_len


func _on_attack_end(p: EnemyPattern) -> void:
	if p.id == "w_lunge" or p.id == "w_bash":
		velocity.x *= 0.2


func _owns_velocity_x() -> bool:
	return estate == EState.ATTACK and current != null and current.id == "w_lunge"


# ============================================================
# GREATSHIELD: blocks from the front while it is not attacking
# ============================================================
func guarding() -> bool:
	return weapon == "greatshield" and not is_dead and estate != EState.ATTACK and estate != EState.RECOVER


func take_hit(amount: int, hit: HitData) -> void:
	if amount > 0 and hit != null and guarding():
		var from := signf(hit.origin.x - global_position.x)
		if from == 0.0 or int(from) == facing:
			amount = maxi(1, roundi(float(amount) * FRONT_GUARD))
			if _clang_cd <= 0.0:
				_clang_cd = 0.5
				Effects.popup(self, global_position + Vector2(0, -170), "BLOCKED!", Color(0.85, 0.9, 1.0), 18)
				SoundManager.play_sfx("block", -4.0)
	super.take_hit(amount, hit)


func _update_visuals(delta: float) -> void:
	_clang_cd -= delta
	super._update_visuals(delta)


func art_state() -> Dictionary:
	var s := super.art_state()
	s["weapon"] = "" if is_native() else weapon
	s["guarding"] = guarding()
	return s


func palette_of() -> Dictionary:
	return get_script().call("palette")


# ============================================================
# ART (shared weapons; facing right, origin = feet, chest ~ (0, -95))
# ============================================================
## Weapon arm + weapon, drawn BEHIND the body.
static func draw_weapon_back(c: CanvasItem, s: Dictionary, chest: Vector2, pal: Dictionary) -> void:
	var w: String = s.get("weapon", "")
	var pose: String = s.get("pose", "idle")
	var arm: Color = pal.get("arm", Color.WHITE)
	var arm_shade: Color = pal.get("arm_shade", Color.GRAY)
	var arm_hi: Color = pal.get("arm_hi", Color.WHITE)
	var hand_c: Color = pal.get("hand", Color.WHITE)
	var shoulder := chest + Vector2(-8, -18)
	match w:
		"short_sword":
			var hand := chest + Vector2(22, 22)
			var ang := -1.2
			match pose:
				"w_slash_tele":
					hand = chest + Vector2(-10, -30)
					ang = -2.4
				"w_slash":
					hand = chest + Vector2(40, 4)
					ang = 0.3
				"w_lunge_tele":
					hand = chest + Vector2(-14, 10)
					ang = 0.0
				"w_lunge":
					hand = chest + Vector2(50, -4)
					ang = 0.0
			EnemyArt.arm(c, shoulder, hand, 9.0, arm_shade, arm_shade.darkened(0.2), arm, hand_c, 6.0)
			_sword(c, hand, Vector2.from_angle(ang), pal)
			if pose == "w_slash":
				c.draw_arc(chest + Vector2(20, -10), 62.0, -1.4, 0.9, 14, Color(1, 1, 1, 0.45), 4.0, FighterArt.AA)
		"hammer":
			var hand := chest + Vector2(18, 26)
			var ang := -1.9
			match pose:
				"w_smash_tele":
					hand = chest + Vector2(-14, -40)
					ang = -2.5
				"w_smash":
					hand = chest + Vector2(46, 6)
					ang = 0.6
				"w_pound_tele":
					hand = chest + Vector2(0, -46)
					ang = -PI * 0.5
				"w_pound":
					hand = chest + Vector2(36, 20)
					ang = 1.2
			EnemyArt.arm(c, shoulder, hand, 9.5, arm_shade, arm_shade.darkened(0.2), arm, hand_c, 6.5)
			_hammer(c, hand, Vector2.from_angle(ang), pal)
		"spear":
			var hand := chest + Vector2(24, 18)
			var d := Vector2(0.08, -1.0).normalized()          # Held upright
			var back := 70.0
			match pose:
				"w_thrust_tele":
					hand = chest + Vector2(-6, 12)
					d = Vector2.RIGHT
				"w_thrust":
					hand = chest + Vector2(54, 12)
					d = Vector2.RIGHT
				"w_sweep_tele":
					hand = chest + Vector2(0, 20)
					d = Vector2.from_angle(2.6)
				"w_sweep":
					hand = chest + Vector2(40, 40)
					d = Vector2.from_angle(0.35)
			if not pose.begins_with("w_sweep") and not pose.begins_with("w_thrust"):
				back = 92.0                                    # Upright: the butt rests near the feet
			EnemyArt.arm(c, shoulder, hand, 9.0, arm_shade, arm_shade.darkened(0.2), arm, hand_c, 6.0)
			_spear(c, hand - d * back, hand + d * 84.0, pal)
			if pose == "w_sweep":
				c.draw_arc(Vector2(40, -20), 90.0, -0.3, 0.6, 10, Color(1, 1, 1, 0.4), 4.0, FighterArt.AA)
		"bow":
			# Quiver on the back + the drawing hand
			var q := chest + Vector2(-24, -6)
			var quiver := PackedVector2Array([q + Vector2(-8, -30), q + Vector2(8, -34), q + Vector2(10, 22), q + Vector2(-6, 24)])
			c.draw_colored_polygon(quiver, pal.get("wood", Color(0.5, 0.35, 0.2)))
			FighterArt.outline(c, quiver, 2.5)
			for k in 3:
				var top := q + Vector2(-4.0 + float(k) * 5.0, -34.0 - float(k % 2) * 6.0)
				c.draw_line(top, top + Vector2(2, 14), EnemyArt.BLACK, 3.0)
				c.draw_colored_polygon(PackedVector2Array([top + Vector2(-4, 0), top + Vector2(0, -8), top + Vector2(4, 0)]), pal.get("accent", Color.WHITE))
			var pull := chest + Vector2(14, 22)
			if pose == "w_shoot_tele":
				pull = chest + Vector2(2, -6)
			elif pose == "w_volley_tele":
				pull = chest + Vector2(6, -16)
			EnemyArt.arm(c, shoulder, pull, 8.5, arm_shade, arm_shade.darkened(0.2), arm, hand_c, 6.0)
		"greatshield":
			EnemyArt.arm(c, shoulder, chest + Vector2(-6, 30), 9.0, arm_shade, arm_shade.darkened(0.2), arm, hand_c, 6.0)


## Shield / bow / kicking leg, drawn IN FRONT of the body.
static func draw_weapon_front(c: CanvasItem, s: Dictionary, chest: Vector2, pal: Dictionary) -> void:
	var w: String = s.get("weapon", "")
	var pose: String = s.get("pose", "idle")
	var t: float = s.get("t", 0.0)
	var metal: Color = pal.get("metal", Color(0.8, 0.8, 0.85))
	var accent: Color = pal.get("accent", Color(1, 0.8, 0.3))
	var dark: Color = pal.get("dark", Color(0.2, 0.2, 0.25))
	var front_shoulder := chest + Vector2(14, -18)
	var arm: Color = pal.get("arm", Color.WHITE)
	var arm_shade: Color = pal.get("arm_shade", Color.GRAY)
	var arm_hi: Color = pal.get("arm_hi", Color.WHITE)
	var hand_c: Color = pal.get("hand", Color.WHITE)
	match w:
		"short_sword", "spear":
			# Small round buckler
			var b := chest + Vector2(22, 12)
			if pose == "w_lunge" or pose == "w_thrust":
				b = chest + Vector2(14, 16)
			c.draw_circle(b, 16.0, EnemyArt.BLACK)
			c.draw_circle(b, 13.0, metal)
			c.draw_circle(b, 6.0, accent)
			c.draw_circle(b + Vector2(-4, -4), 3.0, Color(1, 1, 1, 0.5))
		"hammer":
			# Second hand on the haft
			var hand := chest + Vector2(22, 24)
			match pose:
				"w_smash_tele":
					hand = chest + Vector2(-8, -30)
				"w_smash":
					hand = chest + Vector2(40, 8)
				"w_pound_tele":
					hand = chest + Vector2(2, -34)
				"w_pound":
					hand = chest + Vector2(32, 18)
			EnemyArt.arm(c, front_shoulder, hand, 9.0, arm, arm_shade, arm_hi, hand_c, 6.5)
		"bow":
			var aim := 0.0
			var grip := chest + Vector2(30, 18)
			var drawn := false
			match pose:
				"w_shoot_tele", "w_shoot":
					grip = chest + Vector2(44, -6)
					drawn = pose == "w_shoot_tele"
				"w_volley_tele", "w_volley":
					grip = chest + Vector2(32, -40)
					aim = -0.8
					drawn = pose == "w_volley_tele"
				"idle":
					aim = -1.2
			EnemyArt.arm(c, front_shoulder, grip, 8.5, arm, arm_shade, arm_hi, hand_c, 6.0)
			_bow(c, grip, aim, drawn, chest, pal)
			if pose == "w_kick" or pose == "w_kick_tele":
				var foot := chest + (Vector2(60, 70) if pose == "w_kick" else Vector2(20, 76))
				FighterArt.limb(c, chest + Vector2(4, 40), foot, 10.0, arm, arm_shade, arm_hi)
				c.draw_circle(foot, 8.0, EnemyArt.BLACK)
				c.draw_circle(foot, 6.0, dark)
		"greatshield":
			var sh := chest + Vector2(28, 14)
			match pose:
				"w_bash_tele":
					sh = chest + Vector2(14, 14)
				"w_bash":
					sh = chest + Vector2(48, 10)
				"w_slam_tele":
					sh = chest + Vector2(20, -34)
				"w_slam":
					sh = chest + Vector2(50, 30)
			var r := Rect2(sh - Vector2(24, 60), Vector2(48, 120))
			var tower := FighterArt.rrect_points(r, 12.0)
			c.draw_colored_polygon(tower, metal)
			c.draw_colored_polygon(FighterArt.rrect_points(r.grow(-7.0), 8.0), metal.darkened(0.12))
			c.draw_line(Vector2(sh.x, r.position.y + 10), Vector2(sh.x, r.end.y - 10), accent, 4.0)
			c.draw_line(Vector2(r.position.x + 10, sh.y - 14), Vector2(r.end.x - 10, sh.y - 14), accent, 4.0)
			c.draw_circle(Vector2(sh.x, sh.y - 14), 9.0, accent)
			c.draw_circle(Vector2(sh.x, sh.y - 14), 4.0, dark)
			c.draw_line(Vector2(r.position.x + 6, r.position.y + 8), Vector2(r.position.x + 6, r.end.y - 20), Color(1, 1, 1, 0.35), 3.0)
			FighterArt.outline(c, tower, 4.0)
			if s.get("guarding", false):
				c.draw_arc(sh + Vector2(10, 0), 70.0, -1.1, 1.1, 14, Color(accent.r, accent.g, accent.b, 0.25 + 0.15 * sin(t * 6.0)), 5.0, FighterArt.AA)
			if pose == "w_bash" or pose == "w_slam":
				c.draw_line(Vector2(60, -80), Vector2(120, -80), Color(1, 1, 1, 0.5), 3.0)


static func _sword(c: CanvasItem, hand: Vector2, d: Vector2, pal: Dictionary) -> void:
	var n := d.orthogonal()
	var metal: Color = pal.get("metal", Color(0.85, 0.85, 0.9))
	var blade := PackedVector2Array([hand + d * 8.0 + n * 5.0, hand + d * 48.0 + n * 4.0, hand + d * 60.0,
		hand + d * 48.0 - n * 4.0, hand + d * 8.0 - n * 5.0])
	c.draw_colored_polygon(blade, metal)
	c.draw_line(hand + d * 10.0, hand + d * 52.0, metal.lightened(0.4), 1.5)
	FighterArt.outline(c, blade, 2.5)
	c.draw_line(hand + d * 6.0 + n * 11.0, hand + d * 6.0 - n * 11.0, EnemyArt.BLACK, 7.0)
	c.draw_line(hand + d * 6.0 + n * 10.0, hand + d * 6.0 - n * 10.0, pal.get("accent", Color(1, 0.8, 0.3)), 4.0)
	c.draw_line(hand - d * 10.0, hand + d * 3.0, EnemyArt.BLACK, 6.0)
	c.draw_line(hand - d * 10.0, hand + d * 3.0, pal.get("wood", Color(0.5, 0.35, 0.2)), 3.5)


static func _hammer(c: CanvasItem, hand: Vector2, d: Vector2, pal: Dictionary) -> void:
	var head := hand + d * 58.0
	c.draw_line(hand - d * 12.0, head, EnemyArt.BLACK, 9.0)
	c.draw_line(hand - d * 12.0, head, pal.get("wood", Color(0.5, 0.35, 0.2)), 5.5)
	var n := d.orthogonal()
	var block := PackedVector2Array([head + n * 24.0 - d * 12.0, head + n * 24.0 + d * 12.0, head - n * 24.0 + d * 12.0, head - n * 24.0 - d * 12.0])
	c.draw_colored_polygon(block, pal.get("metal", Color(0.7, 0.7, 0.75)))
	c.draw_line(head + n * 24.0, head - n * 24.0, pal.get("accent", Color(1, 0.8, 0.3)), 4.0)
	FighterArt.outline(c, block, 3.0)


static func _spear(c: CanvasItem, butt: Vector2, tip: Vector2, pal: Dictionary) -> void:
	c.draw_line(butt, tip, EnemyArt.BLACK, 7.0)
	c.draw_line(butt, tip, pal.get("wood", Color(0.5, 0.35, 0.2)), 4.0)
	var d := (tip - butt).normalized()
	var n := d.orthogonal()
	var blade := PackedVector2Array([tip - d * 4.0 + n * 7.0, tip + d * 24.0, tip - d * 4.0 - n * 7.0])
	c.draw_colored_polygon(blade, pal.get("metal", Color(0.85, 0.85, 0.9)))
	FighterArt.outline(c, blade, 2.5)
	c.draw_line(tip - d * 6.0 + n * 9.0, tip - d * 6.0 - n * 9.0, pal.get("accent", Color(1, 0.8, 0.3)), 4.0)


## Bow held at `grip`, aimed along `aim` (radians, 0 = straight ahead).
static func _bow(c: CanvasItem, grip: Vector2, aim: float, drawn: bool, chest: Vector2, pal: Dictionary) -> void:
	var d := Vector2.from_angle(aim)
	var n := d.orthogonal()
	var top := grip + n * 40.0 - d * 10.0
	var bot := grip - n * 40.0 - d * 10.0
	var limb := PackedVector2Array([top, grip + n * 22.0 + d * 6.0, grip + d * 8.0, grip - n * 22.0 + d * 6.0, bot])
	c.draw_polyline(limb, EnemyArt.BLACK, 8.0, FighterArt.AA)
	c.draw_polyline(limb, pal.get("wood", Color(0.5, 0.35, 0.2)), 4.5, FighterArt.AA)
	var string_mid := grip - d * (36.0 if drawn else 10.0)
	c.draw_polyline(PackedVector2Array([top, string_mid, bot]), Color(0.95, 0.95, 0.9, 0.9), 1.5, FighterArt.AA)
	if drawn:                                              # Nocked arrow
		var tip := grip + d * 22.0
		c.draw_line(string_mid, tip, EnemyArt.BLACK, 4.0)
		c.draw_line(string_mid, tip, Color(0.85, 0.8, 0.7), 2.0)
		c.draw_colored_polygon(PackedVector2Array([tip + n * 5.0, tip + d * 12.0, tip - n * 5.0]), pal.get("accent", Color(1, 0.8, 0.3)))
	c.draw_circle(grip, 4.0, pal.get("accent", Color(1, 0.8, 0.3)))
