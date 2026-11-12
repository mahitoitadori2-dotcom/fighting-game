class_name KingFrog
extends SimpleEnemy
## KING FROG: giant green frog with a golden crown, sitting on a lily pad throne.
## PvE enemy (BaseEnemy + EnemyPattern + EnemyHUD), 60 HP.
##
##   Tongue Grab      6 dmg, 6 s  - long tongue shoots forward, grabs you and pulls you in
##   Royal Hop Slam  10 dmg, 10 s - jumps high toward you, slams down, shockwave all around
##   Croak Wave       5 dmg, 8 s  - throat swells, a sound wave rolls forward

const TONGUE_REACH := 290.0
const TONGUE_KB := Vector2(-60, -40)          # Small: the pull does the work
const SLAM_RADIUS := 150.0
const SLAM_KB := Vector2(380, -320)
const CROAK_KB := Vector2(300, -140)

const GREEN := Color(0.30, 0.72, 0.25)
const GREEN_SHADE := Color(0.16, 0.48, 0.16)
const GREEN_HI := Color(0.55, 0.88, 0.42)
const BELLY := Color(0.93, 0.92, 0.62)
const GOLD := Color(1.0, 0.80, 0.18)
const GOLD_SHADE := Color(0.78, 0.55, 0.08)
const PAD := Color(0.20, 0.58, 0.30)
const PAD_SHADE := Color(0.12, 0.40, 0.20)
const TONGUE := Color(0.95, 0.40, 0.52)

var _hop_vx := 0.0
var _airborne := false


func _make_data() -> CharacterData:
	keep_min = 120.0
	keep_max = 300.0
	return SimpleEnemy.make_data("King Frog", EnemyManager.ENEMY_HP, Vector2(96, 84), 220.0)


static func make_patterns() -> Array[EnemyPattern]:
	var list: Array[EnemyPattern] = []
	#                          id             name               cd    dmg  min    max    anim      tele  active rec   big   weights
	list.append(EnemyPattern.make("tongue_grab", "TONGUE GRAB!", 6.0, 6, 40.0, 300.0, "tongue", 0.35, 0.30, 0.40, true, [1.6, 1.6]))
	list.append(EnemyPattern.make("hop_slam", "ROYAL HOP SLAM!", 10.0, 10, 0.0, 430.0, "hop", 0.40, 1.40, 0.45, true, [1.2, 1.5], true))
	list.append(EnemyPattern.make("croak_wave", "CROAK WAVE!", 8.0, 5, 90.0, 600.0, "croak", 0.40, 0.25, 0.35, true, [1.2, 1.2]))
	list[0].note = "pulls you in"
	list[1].note = "shockwave all around"
	return list


func flavor_lines() -> Array[String]:
	return ["RIBBIT!", "BOW TO THE KING!", "CROAK."]


# ============================================================
# ATTACKS
# ============================================================
func _attack(p: EnemyPattern) -> void:
	match p.id:
		"tongue_grab":
			hitbox.activate(make_hit(dmg(p), Vector2(-facing * absf(TONGUE_KB.x), TONGUE_KB.y), "tongue_grab"),
				Vector2(facing * (TONGUE_REACH * 0.5 + 20.0), -44.0), Vector2(TONGUE_REACH - 20.0, 30))
			Effects.play_hit_sound(self, "frog_tongue", global_position)
		"hop_slam":
			var tx := clamp_to_ground(target_x())
			_hop_vx = clampf((tx - global_position.x) / 0.9, -460.0, 460.0)
			velocity.y = -980.0
			_airborne = false
			Effects.popup(self, global_position + Vector2(0, -120), "HOP!", GOLD, 18)
		"croak_wave":
			var w := spawn_projectile()
			w.look = "croak"
			w.damage = dmg(p)
			w.knockback = CROAK_KB
			w.dir = float(facing)
			w.speed = 480.0
			w.lifetime = 1.0
			w.size = Vector2(46, 90)
			w.move = "croak_wave"
			launch(w, global_position + Vector2(facing * 60.0, -46.0))
			Effects.shake(self, 3.0)
			Effects.play_hit_sound(self, "frog_croak", global_position)


func _on_attack_update(p: EnemyPattern, _delta: float) -> void:
	if p.id != "hop_slam":
		return
	velocity.x = _hop_vx
	if not is_on_floor():
		_airborne = true
	elif _airborne and state_time > 0.12:
		_land_slam(p)
		state_time = state_len                       # Landed: go to recovery


func _land_slam(p: EnemyPattern) -> void:
	_airborne = false
	velocity.x = 0.0
	hit_in_radius(global_position + Vector2(0, -30), SLAM_RADIUS, dmg(p), SLAM_KB, "hop_slam")
	Effects.shake(self, 10.0)
	Effects.hit_sparks(self, global_position + Vector2(0, -10), 8, 1.2)
	for side in [-1.0, 1.0]:                          # Visual shockwave rolling both ways
		var s := spawn_projectile()
		s.look = "shock"
		s.harmless = true
		s.tint = GREEN_HI
		s.dir = side
		s.speed = 420.0
		s.lifetime = 0.4
		launch(s, global_position + Vector2(side * 30.0, 0))


func _on_attack_end(p: EnemyPattern) -> void:
	if p.id == "hop_slam":
		_hop_vx = 0.0


func _owns_velocity_x() -> bool:
	return estate == EState.ATTACK and current != null and current.id == "hop_slam"


## Tongue connected: reel the victim in to the frog's mouth.
func _on_hit_landed(victim: Fighter, hit: HitData, result: String) -> void:
	if hit.move == "tongue_grab" and result == "hit" and not victim.is_dead:
		victim.force_move_to(global_position + Vector2(facing * 70.0, 0.0), 0.28)
		Effects.popup(victim, victim.global_position + Vector2(0, -160), "SLURP!", TONGUE, 22)


# ============================================================
# ART  (facing right, origin = feet, about 110 x 95)
# ============================================================
func draw_model_on(c: CanvasItem) -> void:
	draw_frog(c, art_state())


static func draw_portrait(c: CanvasItem, t: float) -> void:
	draw_frog(c, {"t": t, "pose": "idle"})


static func draw_frog(c: CanvasItem, s: Dictionary) -> void:
	var t: float = s.get("t", 0.0)
	var pose: String = s.get("pose", "idle")
	var pt: float = s.get("pose_t", 0.0)
	var dead: bool = s.get("dead", false)
	var air: bool = not s.get("floor", true) and pose == "hop"

	if s.get("enraged", false):
		EnemyArt.aura(c, Vector2(0, -40), 58.0, Color(1.0, 0.85, 0.2), t)

	# --- Lily pad throne: big leaf back-rest + pad seat (stays on the ground) ---
	if not air:
		var leaf := EnemyArt.ellipse_points(Vector2(-30, -62), 26, 40, 20)
		c.draw_colored_polygon(leaf, PAD_SHADE)
		FighterArt.outline(c, leaf, 3.5)
		c.draw_line(Vector2(-30, -26), Vector2(-30, -96), PAD.darkened(0.4), 2.5)
		for i in 3:                                    # Cattail reeds
			var rx := -50.0 + float(i) * 8.0
			c.draw_line(Vector2(rx, -6), Vector2(rx - 4, -86 - float(i) * 6.0), Color(0.25, 0.45, 0.15), 3.0)
			c.draw_circle(Vector2(rx - 4, -90 - float(i) * 6.0), 4.0, Color(0.45, 0.28, 0.12))
		var pad := EnemyArt.ellipse_points(Vector2(0, -6), 58, 11, 24)
		c.draw_colored_polygon(pad, PAD)
		FighterArt.outline(c, pad, 3.5)
		c.draw_colored_polygon(PackedVector2Array([Vector2(0, -6), Vector2(40, -14), Vector2(48, -4)]), PAD_SHADE)   # Notch

	var crouch := 6.0 if pose == "hop_tele" else 0.0
	var by := -38.0 + crouch
	if air:
		by = -50.0

	# --- Back legs (folded on the pad, stretched in the air) ---
	for side in [-1.0, 1.0]:
		var hip := Vector2(-22.0 + side * 6.0, by + 18.0)
		if air:
			FighterArt.limb(c, hip, hip + Vector2(-10, 30), 13.0, GREEN, GREEN_SHADE, GREEN_HI)
			FighterArt.limb(c, hip + Vector2(-10, 30), hip + Vector2(-4, 46), 10.0, GREEN, GREEN_SHADE, GREEN_HI)
		else:
			var thigh := EnemyArt.ellipse_points(hip + Vector2(-4, 4), 18, 11, 16)
			c.draw_colored_polygon(thigh, GREEN_SHADE if side < 0.0 else GREEN)
			FighterArt.outline(c, thigh, 3.5)
			c.draw_colored_polygon(EnemyArt.ellipse_points(Vector2(hip.x + 10.0, -10), 12, 5, 12), GREEN_SHADE)   # Webbed foot

	# --- Body ---
	var body := EnemyArt.ellipse_points(Vector2(4, by), 44, 32, 28)
	var cols := PackedColorArray()
	for p in body:
		cols.append(GREEN_HI.lerp(GREEN_SHADE, clampf((p.y - by + 26.0) / 50.0, 0.0, 1.0)))
	c.draw_polygon(body, cols)
	c.draw_colored_polygon(EnemyArt.ellipse_points(Vector2(16, by + 10.0), 24, 18, 20), BELLY)
	for sp in [Vector2(-18, -10), Vector2(-28, 4), Vector2(-6, -20)]:          # Spots
		c.draw_circle(Vector2(4, by) + sp, 5.0, GREEN_SHADE)
	FighterArt.outline(c, body, 4.0)

	# --- Throat sac (Croak Wave) ---
	var sac := 0.0
	if pose == "croak_tele":
		sac = clampf(pt / 0.4, 0.0, 1.0) * 16.0
	elif pose == "croak":
		sac = 16.0 + 3.0 * sin(t * 40.0)
	if sac > 0.0:
		var sp := EnemyArt.ellipse_points(Vector2(34, by + 4.0), sac + 4.0, sac, 18)
		c.draw_colored_polygon(sp, Color(0.98, 0.85, 0.6))
		FighterArt.outline(c, sp, 3.0)

	# --- Front arm ---
	FighterArt.limb(c, Vector2(22, by + 6.0), Vector2(30, -8), 9.0, GREEN, GREEN_SHADE, GREEN_HI)
	c.draw_colored_polygon(EnemyArt.ellipse_points(Vector2(34, -8), 9, 4, 10), GREEN_SHADE)

	# --- Mouth + tongue ---
	var mouth := Vector2(44, by - 4.0)
	var open := 0.0
	if pose == "tongue_tele":
		open = clampf(pt / 0.35, 0.0, 1.0) * 6.0
	elif pose == "tongue" or pose == "croak":
		open = 7.0
	if open > 0.0:
		c.draw_colored_polygon(PackedVector2Array([Vector2(16, by - 6.0), mouth + Vector2(4, -2), mouth + Vector2(4, open), Vector2(18, by - 2.0 + open * 0.5)]), Color(0.45, 0.08, 0.12))
	c.draw_polyline(PackedVector2Array([Vector2(14, by - 8.0), Vector2(30, by - 3.0), mouth]), EnemyArt.BLACK, 3.0, FighterArt.AA)
	if pose == "tongue":
		var k := clampf(pt / 0.3, 0.0, 1.0)
		var reach := TONGUE_REACH * sin(PI * k)
		var tip := mouth + Vector2(reach, 2)
		c.draw_line(mouth, tip, EnemyArt.BLACK, 11.0)
		c.draw_line(mouth, tip, TONGUE, 7.0)
		FighterArt.ball(c, tip, 9.0, TONGUE, TONGUE.darkened(0.3), Color(1, 0.75, 0.8))

	# --- Big bulging eyes ---
	var e1 := Vector2(8, by - 30.0)
	var e2 := Vector2(32, by - 26.0)
	for e in [e1, e2]:
		FighterArt.ball(c, e, 12.0, GREEN, GREEN_SHADE, GREEN_HI)
		if dead:
			EnemyArt.ko_eye(c, e + Vector2(1, -1), 7.5, t)
		else:
			EnemyArt.eye(c, e + Vector2(1, -1), 7.5, Color(0.95, 0.65, 0.1), Vector2(1.6, 0.6))
	# Royal frown-brow
	c.draw_line(e1 + Vector2(-8, -12), e1 + Vector2(6, -9), EnemyArt.BLACK, 3.0)
	c.draw_line(e2 + Vector2(-6, -10), e2 + Vector2(8, -12), EnemyArt.BLACK, 3.0)

	# --- Golden crown between the eyes ---
	var cb := Vector2(19, by - 40.0)
	var crown := PackedVector2Array([cb + Vector2(-16, 6), cb + Vector2(-16, -10), cb + Vector2(-9, -2),
		cb + Vector2(0, -16), cb + Vector2(9, -2), cb + Vector2(16, -10), cb + Vector2(16, 6)])
	var ccols := PackedColorArray()
	for p in crown:
		ccols.append(GOLD.lerp(GOLD_SHADE, clampf((p.y - cb.y + 10.0) / 18.0, 0.0, 1.0)))
	c.draw_polygon(crown, ccols)
	FighterArt.outline(c, crown, 3.0)
	c.draw_circle(cb + Vector2(0, 0), 3.2, Color(0.9, 0.1, 0.2))
	c.draw_circle(cb + Vector2(-9, 2), 2.4, Color(0.2, 0.5, 1.0))
	c.draw_circle(cb + Vector2(9, 2), 2.4, Color(0.2, 0.5, 1.0))
	c.draw_circle(cb + Vector2(0, -16), 2.0, Color.WHITE)
