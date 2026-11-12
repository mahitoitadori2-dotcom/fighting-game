class_name AlphaShot
extends Node2D
## Projectiles of the APHA ARCHITECT (simple, self-contained):
##   "shock"   Thunderclap: electrified shockwave rolling along the floor (stuns)
##   "tornado" Thunderclap in the air: a compressed wind tornado (stronger, stuns)
##   "laser"   Barrage of Vadis in the air: the clones' lasers
##   "rock" / "shard" / "orb" / "debris"   Portal Manifestation objects (they home in)
##   "rod"     World Implosion Bomb: an energy rod falling from the sky
## Hits every enemy of its owner once (pierce) or explodes on the first hit.

var source: Fighter
var team := 0
var kind := "orb"
var vel := Vector2.ZERO
var damage := 8
var knockback := Vector2(300, -200)
var radius := 30.0
var life := 2.0
var pierce := false
var homing := 0.0                 # 0 = straight; else how fast it turns toward the nearest enemy
var stun := 0.0
var tint := Color.WHITE
var spin := 0.0

var _t := 0.0
var _hit: Array = []


func _ready() -> void:
	z_index = 8
	if source != null:
		team = source.team
	spin = randf() * TAU


func _physics_process(delta: float) -> void:
	if source != null and is_instance_valid(source) and source.is_time_frozen():
		return                                            # Enemy Time Stop freezes his shots too
	_t += delta
	spin += delta * 9.0
	if _t >= life:
		queue_free()
		return
	if homing > 0.0:
		var tgt := _nearest()
		if tgt != null:
			var want := (tgt.global_position + Vector2(0, -tgt.data.body_size.y * 0.5) - global_position).normalized() * vel.length()
			vel = vel.lerp(want, clampf(homing * delta, 0.0, 1.0))
	global_position += vel * delta
	for n in get_tree().get_nodes_in_group("fighters") + get_tree().get_nodes_in_group("helpers"):
		var f := n as Fighter
		if f == null or f.is_dead or _hit.has(f) or f == source or (team != 0 and f.team == team):
			continue
		var c := f.global_position + Vector2(0, -f.data.body_size.y * 0.5)
		if absf(c.x - global_position.x) > radius + f.data.body_size.x * 0.5 or absf(c.y - global_position.y) > radius + f.data.body_size.y * 0.5:
			continue
		_hit.append(f)
		_apply(f)
		if not pierce:
			Effects.explosion(self, global_position, maxf(radius * 1.4, 40.0), true)
			queue_free()
			return
	if not OptimizationManager.on_screen(global_position, 700.0) and _t > 0.3:
		queue_free()
		return
	queue_redraw()


func _nearest() -> Fighter:
	var best: Fighter = null
	var bd := INF
	for n in get_tree().get_nodes_in_group("fighters"):
		var f := n as Fighter
		if f == null or f.is_dead or f == source or (team != 0 and f.team == team):
			continue
		var d := global_position.distance_to(f.global_position)
		if d < bd:
			bd = d
			best = f
	return best


func _apply(f: Fighter) -> void:
	var h := HitData.new()
	h.source = source if source != null and is_instance_valid(source) else null
	h.damage = damage
	var dx := signf(f.global_position.x - global_position.x)
	if dx == 0.0:
		dx = signf(vel.x) if vel.x != 0.0 else 1.0
	h.knockback = Vector2(dx * knockback.x, knockback.y)
	h.origin = global_position
	h.hit_type = "alpha"
	h.move = "alpha_" + kind
	var result := CombatManager.apply_hit(h, f)
	if result == "hit" and stun > 0.0:
		f.stun_timer = maxf(f.stun_timer, stun)
		Effects.popup(f, f.global_position + Vector2(0, -170), "STUNNED!", Color(0.6, 0.9, 1.0), 22)


# ============================================================
# DRAW
# ============================================================
func _draw() -> void:
	var a := 1.0 - clampf((_t - life + 0.25) / 0.25, 0.0, 1.0)
	var d := signf(vel.x) if vel.x != 0.0 else 1.0
	match kind:
		"shock":                                            # Electrified shockwave
			for i in 3:
				var r := 26.0 + float(i) * 14.0
				var a0 := -0.9 if d > 0.0 else PI - 0.9
				draw_arc(Vector2(-d * float(i) * 12.0, 0), r, a0 - 0.6, a0 + 1.2, 16, Color(0, 0, 0, a), 8.0, FighterArt.AA)
				draw_arc(Vector2(-d * float(i) * 12.0, 0), r, a0 - 0.6, a0 + 1.2, 16, Color(0.55, 0.85, 1.0, a), 4.0, FighterArt.AA)
			var pts := PackedVector2Array()                 # Lightning crackling over it
			for k in 7:
				pts.append(Vector2(-d * float(k) * 9.0, -50.0 + float(k) * 7.0 + randf_range(-8.0, 8.0)))
			draw_polyline(pts, Color(1, 1, 1, a), 2.5)
			draw_polyline(pts, Color(0.5, 0.8, 1.0, 0.5 * a), 7.0)
		"tornado":                                          # Compressed wind tornado
			for i in 8:
				var u := float(i) / 7.0
				var w := 14.0 + u * 46.0
				draw_set_transform(Vector2(sin(spin + u * 4.0) * 6.0, 60.0 - u * 120.0), 0.0, Vector2(1.0, 0.28))
				draw_arc(Vector2.ZERO, w, spin * 2.0, spin * 2.0 + 4.6, 14, Color(0.75, 1.0, 0.85, 0.75 * a), 8.0, FighterArt.AA)
				draw_arc(Vector2.ZERO, w, spin * 2.0, spin * 2.0 + 4.6, 14, Color(1, 1, 1, 0.6 * a), 3.0, FighterArt.AA)
			draw_set_transform(Vector2.ZERO, 0.0, Vector2.ONE)
		"laser":
			draw_line(Vector2(-d * 50.0, 0), Vector2(d * 30.0, 0), Color(0.4, 1.0, 0.5, 0.35 * a), 16.0, FighterArt.AA)
			draw_line(Vector2(-d * 50.0, 0), Vector2(d * 30.0, 0), Color(0.5, 1.0, 0.6, a), 6.0, FighterArt.AA)
			draw_line(Vector2(-d * 46.0, 0), Vector2(d * 26.0, 0), Color(1, 1, 1, a), 2.0, FighterArt.AA)
		"rock":
			var pts2 := PackedVector2Array()
			for k in 7:
				pts2.append(Vector2.from_angle(spin + float(k) * TAU / 7.0) * (radius * (0.8 + 0.25 * sin(float(k) * 2.3))))
			draw_colored_polygon(pts2, Color(0.45, 0.40, 0.36, a))
			FighterArt.outline(self, pts2, 3.0, Color(0, 0, 0, a))
		"shard":
			var dir := vel.normalized()
			var n := dir.orthogonal()
			var sh := PackedVector2Array([dir * radius * 1.4, n * radius * 0.4, -dir * radius, -n * radius * 0.4])
			draw_colored_polygon(sh, Color(0.75, 0.78, 0.85, a))
			draw_line(-dir * radius, dir * radius * 1.4, Color(1, 1, 1, 0.7 * a), 2.0)
			FighterArt.outline(self, sh, 2.5, Color(0, 0, 0, a))
		"orb":
			draw_circle(Vector2.ZERO, radius * 1.6, Color(tint.r, tint.g, tint.b, 0.2 * a))
			draw_circle(Vector2.ZERO, radius, Color(tint.r, tint.g, tint.b, 0.9 * a))
			draw_circle(Vector2.ZERO, radius * 0.45, Color(1, 1, 1, a))
		"debris":
			for k in 3:
				var p := Vector2.from_angle(spin + float(k) * 2.1) * radius * 0.6
				draw_rect(Rect2(p - Vector2(8, 5), Vector2(16, 10)), Color(0.35, 0.33, 0.30, a))
				draw_rect(Rect2(p - Vector2(8, 5), Vector2(16, 10)), Color(0, 0, 0, a), false, 2.0)
		"rod":                                              # Falling energy rod
			draw_line(Vector2(0, -260), Vector2(0, 0), Color(0.4, 1.0, 0.5, 0.25 * a), 40.0, FighterArt.AA)
			draw_line(Vector2(0, -220), Vector2(0, 0), Color(0.6, 1.0, 0.7, a), 16.0, FighterArt.AA)
			draw_line(Vector2(0, -220), Vector2(0, 0), Color(1, 1, 1, a), 6.0, FighterArt.AA)
			draw_colored_polygon(PackedVector2Array([Vector2(-14, -10), Vector2(14, -10), Vector2(0, 30)]), Color(1, 1, 1, a))
