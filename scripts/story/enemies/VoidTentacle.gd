class_name VoidTentacle
extends SimpleEnemy
## VOID TENTACLE (Story Mode, Colosseum 4 - the Void): a huge void tentacle growing out of the
## bone floor. It does not walk, it sways in place - but it reaches FAR.
##
##   Whip    6 dmg, 2.0 s - lashes out in front of it
##   Grab    4 + 4 dmg, 5.0 s - BIG: wraps around you, PULLS you in and squeezes (mash to struggle)

const WHIP_KB := Vector2(320, -200)
const GRAB_HOLD := 0.9

const FLESH := Color(0.16, 0.06, 0.26)
const FLESH_HI := Color(0.36, 0.18, 0.55)
const SUCKER := Color(0.70, 0.45, 0.90)

var _squeeze_t := -1.0
var _victim: Fighter


func _make_data() -> CharacterData:
	keep_min = 0.0
	keep_max = 99999.0                      # Rooted: never walks
	attack_chance = 0.6
	phase2_threshold = -1.0
	knockback_scale = 0.0
	var d := SimpleEnemy.make_data("Void Tentacle", 24, Vector2(50, 150), 0.0)
	d.hitstun_time = 0.1
	return d


static func make_patterns() -> Array[EnemyPattern]:
	var list: Array[EnemyPattern] = []
	#                          id      name     cd    dmg  min   max    anim    tele  active rec   big    weights
	list.append(EnemyPattern.make("whip", "WHIP", 2.0, 6, 0.0, 230.0, "whip", 0.40, 0.20, 0.50, false, [2.0, 2.0]))
	list.append(EnemyPattern.make("grab", "GRAB!", 5.0, 4, 0.0, 280.0, "grab", 0.55, 0.30, 0.70, true, [1.2, 1.2]))
	return list


func flavor_lines() -> Array[String]:
	return ["*wet slithering*", "*bones rattle*"]


func jump(_force_mult: float = 1.0) -> void:
	pass


func _owns_velocity_x() -> bool:
	velocity.x = 0.0
	return true


func _attack(p: EnemyPattern) -> void:
	match p.id:
		"whip":
			hitbox.activate(make_hit(dmg(p), Vector2(facing * WHIP_KB.x, WHIP_KB.y), "tentacle_whip"),
				Vector2(facing * 130.0, -70.0), Vector2(200, 60))
			SoundManager.play_sfx("chain", -8.0)
		"grab":
			hitbox.activate(make_hit(dmg(p), Vector2.ZERO, "tentacle_grab"),
				Vector2(facing * 150.0, -60.0), Vector2(250, 90))
			SoundManager.play_sfx("void_goo", -4.0)


func _on_hit_landed(victim: Fighter, hit: HitData, result: String) -> void:
	if hit.move != "tentacle_grab" or result != "hit":
		return
	# Wrapped up: pulled right next to the tentacle and held, then squeezed
	_victim = victim
	victim.force_move_to(global_position + Vector2(facing * 56.0, 0.0), 0.25)
	victim.stun_timer = maxf(victim.stun_timer, GRAB_HOLD)
	_squeeze_t = GRAB_HOLD
	Effects.popup(victim, victim.global_position + Vector2(0, -180), "GRABBED!", Color(0.8, 0.5, 1.0), 22)


func _update_visuals(delta: float) -> void:
	if _squeeze_t > 0.0:
		_squeeze_t -= delta
		if _squeeze_t <= 0.0 and _victim != null and is_instance_valid(_victim) and not _victim.is_dead and not is_dead:
			var h := make_hit(maxi(1, roundi(4.0 * damage_mult)), Vector2(facing * 260.0, -260.0), "tentacle_squeeze")
			h.blockable = false
			CombatManager.apply_hit(h, _victim)
			SoundManager.play_sfx("bite", -4.0)
	super._update_visuals(delta)


# ============================================================
# ART (origin = where it comes out of the floor, ~60 x 200)
# ============================================================
func draw_model_on(c: CanvasItem) -> void:
	var s := art_state()
	s["squeeze"] = _squeeze_t > 0.0
	draw_tentacle(c, s)


static func draw_portrait(c: CanvasItem, t: float) -> void:
	draw_tentacle(c, {"t": t, "pose": "idle"})


static func draw_tentacle(c: CanvasItem, s: Dictionary) -> void:
	var t: float = s.get("t", 0.0)
	var pose: String = s.get("pose", "idle")
	var pt: float = s.get("pose_t", 0.0)
	var dead: bool = s.get("dead", false)
	# Where the tip points
	var tip := Vector2(30 + sin(t * 1.7) * 18.0, -190 + cos(t * 2.1) * 10.0)
	match pose:
		"whip_tele", "grab_tele":
			tip = Vector2(-40, -200)
		"whip":
			tip = Vector2(lerpf(60.0, 220.0, clampf(pt / 0.15, 0.0, 1.0)), -70)
		"grab":
			tip = Vector2(250, -60)
	if s.get("squeeze", false):
		tip = Vector2(64, -70)
	if dead:
		tip = Vector2(80, -20)
	# Curved body from the floor to the tip, thick -> thin
	var mid := Vector2(-10, -110)
	var pts := PackedVector2Array()
	for i in 13:
		var u := float(i) / 12.0
		pts.append(Vector2.ZERO.lerp(mid, u).lerp(mid.lerp(tip, u), u) + Vector2(sin(u * 8.0 + t * 3.0) * 6.0 * u, 0))
	for i in pts.size() - 1:
		var w := lerpf(22.0, 6.0, float(i) / 12.0)
		c.draw_line(pts[i], pts[i + 1], EnemyArt.BLACK, w * 2.0 + 6.0, FighterArt.AA)
	for i in pts.size() - 1:
		var w := lerpf(22.0, 6.0, float(i) / 12.0)
		c.draw_line(pts[i], pts[i + 1], FLESH, w * 2.0, FighterArt.AA)
		c.draw_line(pts[i] + Vector2(-w * 0.4, 0), pts[i + 1] + Vector2(-w * 0.4, 0), FLESH_HI, w * 0.5, FighterArt.AA)
		if i % 2 == 0:
			c.draw_circle(pts[i] + Vector2(w * 0.5, 0), w * 0.3, SUCKER)
	# Broken bones at the base where it burst out
	for k in 4:
		var a := PI + PI * (float(k) + 0.5) / 4.0
		c.draw_line(Vector2.ZERO, Vector2.from_angle(a) * 30.0, Color(0.36, 0.33, 0.40), 5.0)
