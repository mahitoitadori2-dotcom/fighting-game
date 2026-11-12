class_name ExtArt
extends RefCounted
## Shared drawing for the BOSS EXTENSION enemies (Story Mode: BC / AG / VM / AC / FM levels).
## Same flat cartoon style as every other enemy (FighterArt / EnemyArt, thick black outline).
## Facing RIGHT, origin = feet. Poses come from SimpleEnemy: "idle", "<anim>_tele", "<anim>".
##
##   humanoid(c, s, cfg)   a standing figure; cfg picks head, weapon, shield, robe, size...
##   spider(c, s, cfg)     an 8-legged spider (shooter / biter / venomous, Void Horrid legs)
##   serpent(c, s, cfg)    a small serpent (body tube + head)
##   rock_ball(c, s, cfg)  a round rock (Saint Roller, Atomic Rock)

const BLACK := Color(0, 0, 0)


## Wind-up (0..1) / strike flags for a pose.
static func phase_of(pose: String) -> int:
	if pose == "idle" or pose == "":
		return 0
	return 1 if pose.ends_with("_tele") else 2


## cfg keys (all optional):
##   h (height scale, 1 = ~140 px), w (bulk), skin, cloth, cloth_hi, trim, eye
##   head: "hood" | "helm" | "serpent" | "mutant" | "rock" | "worker" | "crown" | "plain"
##   weapon: "sword" | "staff" | "spear" | "hammer" | "coal" | "none" | "claw"
##   shield: Color (draws a shield on the far arm) | null
##   robe: true = long robe instead of legs     tail: true = serpent tail instead of legs
##   oven: true = carries a burning oven on its back     glow: Color aura (radioactive...)
##   big_arm: true = one huge mutated arm      runes: true = glowing rune marks
static func humanoid(c: CanvasItem, s: Dictionary, cfg: Dictionary) -> void:
	var t: float = s.get("t", 0.0)
	var pose: String = s.get("pose", "idle")
	var pt: float = s.get("pose_t", 0.0)
	var dead: bool = s.get("dead", false)
	var h: float = cfg.get("h", 1.0)
	var w: float = cfg.get("w", 1.0)
	var skin: Color = cfg.get("skin", Color(0.7, 0.55, 0.45))
	var cloth: Color = cfg.get("cloth", Color(0.3, 0.3, 0.35))
	var cloth_hi: Color = cfg.get("cloth_hi", cloth.lightened(0.25))
	var trim: Color = cfg.get("trim", cloth.darkened(0.4))
	var eye: Color = cfg.get("eye", Color(1, 1, 1))
	var ph := phase_of(pose)
	var bob := sin(t * 3.0) * 1.5
	if cfg.has("glow"):
		var g: Color = cfg["glow"]
		c.draw_circle(Vector2(0, -70 * h), 60.0 * h, Color(g.r, g.g, g.b, 0.12 + 0.06 * sin(t * 4.0)))

	# --- Oven on the back (Oven Owner) ---
	if cfg.get("oven", false):
		var ov := Rect2(-46 * w, -118 * h, 44 * w, 60 * h)
		FighterArt.rrect(c, ov, Color(0.25, 0.24, 0.26), Color(0.15, 0.14, 0.16), Color(0.4, 0.38, 0.4), 6.0, 4.0)
		var fire := 0.6 + 0.4 * sin(t * 12.0)
		c.draw_rect(Rect2(ov.position.x + 8, ov.position.y + 18 * h, ov.size.x - 16, 20 * h), Color(1.0, 0.45 * fire + 0.2, 0.05))
		c.draw_rect(Rect2(ov.position.x + ov.size.x * 0.4, ov.position.y - 22 * h, 10, 24 * h), Color(0.2, 0.19, 0.2))
		c.draw_circle(Vector2(ov.position.x + ov.size.x * 0.4 + 5, ov.position.y - 28 * h), 7.0 + 3.0 * sin(t * 5.0), Color(0.4, 0.4, 0.4, 0.5))

	# --- Lower body: legs / robe / serpent tail ---
	var hip_y := -60.0 * h
	if cfg.get("robe", false):
		var robe := PackedVector2Array([Vector2(-16 * w, hip_y - 30 * h), Vector2(18 * w, hip_y - 30 * h), Vector2(28 * w, -2), Vector2(-30 * w, -2)])
		c.draw_colored_polygon(robe, cloth)
		c.draw_line(Vector2(0, hip_y - 26 * h), Vector2(2, -6), trim, 3.0)
		c.draw_line(Vector2(-30 * w, -4), Vector2(28 * w, -4), trim, 4.0)
		FighterArt.outline(c, robe, 4.0)
	elif cfg.get("tail", false):
		var pts := PackedVector2Array()
		for i in 7:
			var k := float(i) / 6.0
			pts.append(Vector2(-8.0 - 40.0 * k * w + sin(t * 3.0 + k * 4.0) * 5.0, hip_y + 10.0 - (hip_y + 4.0) * k))
		for i in pts.size():
			c.draw_circle(pts[i], (16.0 - float(i) * 1.6) * w + 3.0, BLACK)
		for i in pts.size():
			c.draw_circle(pts[i], (16.0 - float(i) * 1.6) * w, skin if i % 2 == 0 else skin.darkened(0.12))
	else:
		EnemyArt.legs(c, s, hip_y, 9.0 * w, 12.0 * w, cloth, cloth.darkened(0.3), cloth_hi, trim, 15.0)

	# --- Far arm (+ shield) ---
	var sh_far := Vector2(-10 * w, -112 * h + bob)
	var sh_near := Vector2(12 * w, -112 * h + bob)
	var far_hand := Vector2(-14 * w, -70 * h)
	var near_hand := Vector2(22 * w, -68 * h)
	match ph:
		1:
			near_hand = Vector2(-8 * w, -140 * h)
		2:
			near_hand = Vector2(58 * w, -96 * h)
	if pose.begins_with("block") or pose.begins_with("guard"):
		far_hand = Vector2(30 * w, -96 * h)
	if pose.begins_with("cast") or pose.begins_with("beam") or pose.begins_with("watch"):
		near_hand = Vector2(40 * w, -130 * h) if ph >= 1 else near_hand
	var shield_col = cfg.get("shield", null)
	if shield_col != null and ph == 0 and not pose.begins_with("block"):
		far_hand = Vector2(16 * w, -92 * h)
	EnemyArt.arm(c, sh_far, far_hand, 10.0 * w, skin.darkened(0.25), skin.darkened(0.45), skin.darkened(0.1), skin.darkened(0.3), 6.0 * w)
	if shield_col != null:
		var sc: Color = shield_col
		var shp := EnemyArt.ellipse_points(far_hand + Vector2(10 * w, 0), 13.0 * w, 30.0 * h, 16)
		c.draw_colored_polygon(shp, sc)
		c.draw_circle(far_hand + Vector2(10 * w, 0), 5.0 * w, sc.lightened(0.4))
		FighterArt.outline(c, shp, 3.5)

	# --- Torso ---
	var torso := Rect2(-17 * w, -118 * h + bob, 34 * w, 62 * h)
	FighterArt.rrect(c, torso, cloth, cloth.darkened(0.3), cloth_hi, 10.0, 4.0)
	c.draw_line(Vector2(-15 * w, -64 * h + bob), Vector2(15 * w, -64 * h + bob), trim, 5.0)
	if cfg.get("runes", false):
		var rc := Color(0.4, 0.9, 1.0, 0.6 + 0.4 * sin(t * 4.0))
		c.draw_line(Vector2(-6 * w, -104 * h), Vector2(6 * w, -88 * h), rc, 3.0)
		c.draw_line(Vector2(6 * w, -104 * h), Vector2(-6 * w, -88 * h), rc, 3.0)
		c.draw_arc(Vector2(0, -96 * h), 11.0 * w, 0.0, TAU, 14, rc, 2.0)

	# --- Head ---
	var head := Vector2(4 * w, -132 * h + bob)
	var hr := 14.0 * w
	match String(cfg.get("head", "plain")):
		"hood":
			var hood := PackedVector2Array([head + Vector2(-hr - 4, 10), head + Vector2(-hr, -8), head + Vector2(0, -hr - 10), head + Vector2(hr + 2, -6), head + Vector2(hr + 4, 12)])
			c.draw_colored_polygon(hood, cloth.darkened(0.2))
			FighterArt.outline(c, hood, 3.5)
			c.draw_circle(head + Vector2(4, 2), hr * 0.75, Color(0.04, 0.02, 0.03))
			if not dead:
				c.draw_circle(head + Vector2(8, 0), 2.6, eye)
				c.draw_circle(head + Vector2(1, 0), 2.6, eye)
		"helm":
			FighterArt.ball(c, head, hr, cloth_hi, cloth.darkened(0.2), cloth_hi.lightened(0.2))
			c.draw_rect(Rect2(head.x - 2, head.y - 3, hr + 2, 5), Color(0.05, 0.05, 0.05))
			if not dead:
				c.draw_rect(Rect2(head.x + 4, head.y - 2, 6, 3), eye)
			c.draw_colored_polygon(PackedVector2Array([head + Vector2(-4, -hr), head + Vector2(4, -hr), head + Vector2(-2, -hr - 12)]), trim)
		"serpent":
			var sn := PackedVector2Array([head + Vector2(-hr, -6), head + Vector2(0, -hr), head + Vector2(hr + 12, -4), head + Vector2(hr + 12, 4), head + Vector2(-hr + 2, 8)])
			c.draw_colored_polygon(sn, skin)
			FighterArt.outline(c, sn, 3.5)
			if not dead:
				c.draw_circle(head + Vector2(4, -5), 3.2, eye)
				c.draw_line(head + Vector2(4, -8), head + Vector2(4, -2), BLACK, 1.5)
			c.draw_line(head + Vector2(hr + 12, 1), head + Vector2(hr + 22, 1 + sin(t * 20.0) * 3.0), Color(0.8, 0.1, 0.15), 2.0)
		"mutant":
			FighterArt.ball(c, head + Vector2(-3, 0), hr * 1.1, skin, skin.darkened(0.3), skin.lightened(0.15))
			c.draw_circle(head + Vector2(-10, -6), hr * 0.55, skin.darkened(0.1))       # Swollen lump
			FighterArt.outline(c, EnemyArt.ellipse_points(head + Vector2(-10, -6), hr * 0.55, hr * 0.55, 12), 2.5)
			if not dead:
				c.draw_circle(head + Vector2(6, -2), 3.4, eye)
				c.draw_circle(head + Vector2(-2, 0), 2.0, eye)
			var mo := 6.0 if ph == 2 or pose.begins_with("scream") else 2.0
			c.draw_colored_polygon(EnemyArt.ellipse_points(head + Vector2(6, 8), 5.0, mo, 10), Color(0.15, 0.02, 0.02))
		"rock":
			var rp := PackedVector2Array()
			for k in 7:
				rp.append(head + Vector2.from_angle(float(k) * TAU / 7.0) * hr * (0.85 + 0.2 * sin(float(k) * 2.2)))
			c.draw_colored_polygon(rp, skin)
			FighterArt.outline(c, rp, 3.5)
			if not dead:
				c.draw_rect(Rect2(head.x - 2, head.y - 3, hr + 2, 4), eye)
		"worker":
			FighterArt.ball(c, head, hr, skin, skin.darkened(0.3), skin.lightened(0.2))
			var cap := PackedVector2Array([head + Vector2(-hr, -2), head + Vector2(-hr + 2, -hr + 2), head + Vector2(hr - 2, -hr + 2), head + Vector2(hr + 6, -2)])
			c.draw_colored_polygon(cap, trim)
			FighterArt.outline(c, cap, 3.0)
			c.draw_rect(Rect2(head.x + 1, head.y - 4, 12, 6), Color(0.15, 0.15, 0.18))      # Goggles
			if not dead:
				c.draw_rect(Rect2(head.x + 3, head.y - 3, 8, 3), eye)
		"crown":
			FighterArt.ball(c, head, hr, skin, skin.darkened(0.3), skin.lightened(0.2))
			for k in 3:
				var bx := head + Vector2(-8 + float(k) * 8, -hr + 2)
				c.draw_colored_polygon(PackedVector2Array([bx + Vector2(-4, 0), bx + Vector2(4, 0), bx + Vector2(0, -10)]), trim)
			if not dead:
				c.draw_circle(head + Vector2(6, -2), 2.6, eye)
		_:
			FighterArt.ball(c, head, hr, skin, skin.darkened(0.3), skin.lightened(0.2))
			if not dead:
				c.draw_circle(head + Vector2(6, -2), 2.6, eye)
	if dead:
		EnemyArt.ko_eye(c, head + Vector2(6, -2), 3.0, t)

	# --- Near arm + weapon ---
	var big := bool(cfg.get("big_arm", false))
	EnemyArt.arm(c, sh_near, near_hand, (16.0 if big else 11.0) * w, skin, skin.darkened(0.3), skin.lightened(0.15), skin.darkened(0.1), (11.0 if big else 6.5) * w)
	_weapon(c, String(cfg.get("weapon", "none")), near_hand, ph, pt, t, cfg)


static func _weapon(c: CanvasItem, kind: String, hand: Vector2, ph: int, pt: float, t: float, cfg: Dictionary) -> void:
	var metal: Color = cfg.get("metal", Color(0.75, 0.75, 0.8))
	var aim := Vector2(1, -1).normalized() if ph == 1 else (Vector2(1, 0.2).normalized() if ph == 2 else Vector2(0.3, -1).normalized())
	match kind:
		"sword":
			var tip := hand + aim * 52.0
			c.draw_line(hand, tip, BLACK, 9.0, FighterArt.AA)
			c.draw_line(hand, tip, metal, 5.0, FighterArt.AA)
			c.draw_line(hand - aim.orthogonal() * 8.0, hand + aim.orthogonal() * 8.0, BLACK, 5.0)
			if ph == 2 and pt < 0.2:
				c.draw_arc(hand, 54.0, -1.2, 0.8, 12, Color(1, 1, 1, 0.7 - pt * 3.0), 6.0, FighterArt.AA)
		"spear":
			var a2 := Vector2(1, -0.15).normalized() if ph == 2 else Vector2(0.2, -1).normalized()
			c.draw_line(hand - a2 * 30.0, hand + a2 * 70.0, BLACK, 7.0, FighterArt.AA)
			c.draw_line(hand - a2 * 30.0, hand + a2 * 70.0, Color(0.45, 0.3, 0.2), 3.5, FighterArt.AA)
			c.draw_colored_polygon(PackedVector2Array([hand + a2 * 70.0 + a2.orthogonal() * 6.0, hand + a2 * 92.0, hand + a2 * 70.0 - a2.orthogonal() * 6.0]), metal)
		"hammer":
			var top := hand + aim * 44.0
			c.draw_line(hand, top, BLACK, 8.0, FighterArt.AA)
			c.draw_line(hand, top, Color(0.42, 0.3, 0.2), 4.0, FighterArt.AA)
			var hd := PackedVector2Array([top + aim.orthogonal() * 16.0 - aim * 8.0, top + aim.orthogonal() * 16.0 + aim * 10.0, top - aim.orthogonal() * 16.0 + aim * 10.0, top - aim.orthogonal() * 16.0 - aim * 8.0])
			c.draw_colored_polygon(hd, metal)
			FighterArt.outline(c, hd, 3.0)
		"staff":
			var st := hand + Vector2(4, -60)
			c.draw_line(hand + Vector2(0, 30), st, BLACK, 7.0, FighterArt.AA)
			c.draw_line(hand + Vector2(0, 30), st, Color(0.25, 0.15, 0.1), 3.5, FighterArt.AA)
			var orb: Color = cfg.get("magic", Color(1.0, 0.4, 0.1))
			c.draw_circle(st, 9.0 + (4.0 * sin(t * 10.0) if ph >= 1 else 0.0), Color(orb.r, orb.g, orb.b, 0.4))
			c.draw_circle(st, 6.0, orb)
		"coal":
			c.draw_circle(hand + Vector2(4, -4), 9.0, BLACK)
			c.draw_circle(hand + Vector2(4, -4), 7.0, Color(0.15, 0.12, 0.12))
			c.draw_circle(hand + Vector2(6, -6), 3.5, Color(1.0, 0.45 + 0.2 * sin(t * 9.0), 0.1))
		"claw":
			for k in 3:
				var a := aim.angle() + (float(k) - 1.0) * 0.4
				c.draw_line(hand, hand + Vector2.from_angle(a) * 16.0, BLACK, 4.0, FighterArt.AA)


## 8-legged spider. cfg: body (Color), mark (Color), size (1 = ~70 px wide), eyes (Color),
## sac (bool, venom sac on the back), fang (Color).
static func spider(c: CanvasItem, s: Dictionary, cfg: Dictionary) -> void:
	var t: float = s.get("t", 0.0)
	var pose: String = s.get("pose", "idle")
	var dead: bool = s.get("dead", false)
	var k: float = cfg.get("size", 1.0)
	var body: Color = cfg.get("body", Color(0.12, 0.08, 0.14))
	var mark: Color = cfg.get("mark", Color(0.6, 0.2, 0.8))
	var ph := phase_of(pose)
	var walk: float = s.get("walk", 0.0) * 3.0
	var lift := -6.0 * k if ph == 1 else 0.0
	var ab := Vector2(-22 * k, -26 * k + lift)
	var ce := Vector2(10 * k, -24 * k + lift)
	for i in 8:                                        # Legs: 4 per side, far side darker
		var far := i < 4
		var j := float(i % 4)
		var hip := ce + Vector2(-8 * k + j * 6 * k, 2 * k)
		var knee := hip + Vector2((-30 + j * 18) * k, -24 * k + sin(walk + j + (PI if far else 0.0)) * 5.0)
		var foot := Vector2(hip.x + (-40 + j * 26) * k, 0)
		var col := body.darkened(0.35) if far else body
		c.draw_line(hip, knee, BLACK, 7.0 * k, FighterArt.AA)
		c.draw_line(knee, foot, BLACK, 6.0 * k, FighterArt.AA)
		c.draw_line(hip, knee, col, 3.5 * k, FighterArt.AA)
		c.draw_line(knee, foot, col, 3.0 * k, FighterArt.AA)
	var abd := EnemyArt.ellipse_points(ab, 26 * k, 20 * k, 18)
	c.draw_colored_polygon(abd, body)
	if cfg.get("sac", false):
		c.draw_circle(ab + Vector2(-6 * k, -8 * k), 10.0 * k, Color(0.4, 0.95, 0.2, 0.85))
	c.draw_colored_polygon(EnemyArt.ellipse_points(ab + Vector2(-2, -4) * k, 10 * k, 6 * k, 10), mark)
	FighterArt.outline(c, abd, 3.5)
	var hd := EnemyArt.ellipse_points(ce, 16 * k, 13 * k, 16)
	c.draw_colored_polygon(hd, body.lightened(0.08))
	FighterArt.outline(c, hd, 3.5)
	var eyes: Color = cfg.get("eyes", Color(1.0, 0.2, 0.2))
	if dead:
		EnemyArt.ko_eye(c, ce + Vector2(8 * k, -4 * k), 3.0 * k, t)
	else:
		for e in 4:
			c.draw_circle(ce + Vector2((4 + float(e % 2) * 7) * k, (-6 + float(e / 2) * 5) * k), 2.2 * k, eyes)
	var fang: Color = cfg.get("fang", Color(0.9, 0.9, 0.85))
	var open := 5.0 * k if ph >= 1 else 1.0
	c.draw_line(ce + Vector2(14 * k, 4 * k), ce + Vector2(18 * k, 12 * k + open), fang, 3.0 * k)
	c.draw_line(ce + Vector2(10 * k, 5 * k), ce + Vector2(12 * k, 13 * k + open), fang, 3.0 * k)


## Small serpent: a wavy tube with a head. cfg: skin, belly, size.
static func serpent(c: CanvasItem, s: Dictionary, cfg: Dictionary) -> void:
	var t: float = s.get("t", 0.0)
	var pose: String = s.get("pose", "idle")
	var dead: bool = s.get("dead", false)
	var k: float = cfg.get("size", 1.0)
	var skin: Color = cfg.get("skin", Color(0.35, 0.55, 0.25))
	var belly: Color = cfg.get("belly", Color(0.8, 0.75, 0.45))
	var ph := phase_of(pose)
	var reach := 18.0 * k if ph == 2 else (-8.0 * k if ph == 1 else 0.0)
	var pts := PackedVector2Array()
	for i in 9:
		var u := float(i) / 8.0
		pts.append(Vector2(-50 * k + u * (62 * k + reach), -8 * k - sin(u * PI) * (6.0 + (14.0 if ph == 1 else 0.0)) * k + sin(t * 8.0 + u * 6.0) * 3.0 * (1.0 - u)))
	for i in pts.size():
		c.draw_circle(pts[i], (5.0 + float(i) * 0.7) * k + 2.5, BLACK)
	for i in pts.size():
		c.draw_circle(pts[i], (5.0 + float(i) * 0.7) * k, skin if i % 2 == 0 else skin.darkened(0.15))
		c.draw_circle(pts[i] + Vector2(0, 2 * k), (2.0 + float(i) * 0.3) * k, belly)
	var hd := pts[pts.size() - 1] + Vector2(8 * k, -2 * k)
	var hp := PackedVector2Array([hd + Vector2(-8, -8) * k, hd + Vector2(12, -4) * k, hd + Vector2(14, 3) * k, hd + Vector2(-8, 7) * k])
	c.draw_colored_polygon(hp, skin)
	FighterArt.outline(c, hp, 3.0)
	if dead:
		EnemyArt.ko_eye(c, hd + Vector2(2, -3) * k, 2.5 * k, t)
	else:
		c.draw_circle(hd + Vector2(2, -3) * k, 2.4 * k, Color(1.0, 0.85, 0.2))
	if ph == 2:
		c.draw_colored_polygon(PackedVector2Array([hd + Vector2(10, 0) * k, hd + Vector2(16, -6) * k, hd + Vector2(16, 6) * k]), Color(0.5, 0.05, 0.05))


## Round rock (Saint Roller / Atomic Rock). cfg: rock, crack (Color glow), size, spin (radians).
static func rock_ball(c: CanvasItem, s: Dictionary, cfg: Dictionary) -> void:
	var t: float = s.get("t", 0.0)
	var dead: bool = s.get("dead", false)
	var k: float = cfg.get("size", 1.0)
	var rock: Color = cfg.get("rock", Color(0.55, 0.52, 0.48))
	var crack: Color = cfg.get("crack", Color(0.4, 0.9, 1.0))
	var spin: float = cfg.get("spin", 0.0)
	var r := 30.0 * k
	var c0 := Vector2(0, -r)
	if cfg.has("glow"):
		var g: Color = cfg["glow"]
		c.draw_circle(c0, r * 1.5, Color(g.r, g.g, g.b, 0.18 + 0.1 * sin(t * 6.0)))
	var pts := PackedVector2Array()
	for i in 9:
		pts.append(c0 + Vector2.from_angle(spin + float(i) * TAU / 9.0) * r * (0.88 + 0.14 * sin(float(i) * 2.9)))
	c.draw_colored_polygon(pts, rock)
	c.draw_circle(c0 + Vector2(-r * 0.3, -r * 0.3), r * 0.35, rock.lightened(0.18))
	for i in 3:                                       # Glowing cracks / runes
		var a := spin + float(i) * 2.1
		c.draw_line(c0 + Vector2.from_angle(a) * r * 0.15, c0 + Vector2.from_angle(a + 0.4) * r * 0.75, Color(crack.r, crack.g, crack.b, 0.6 + 0.4 * sin(t * 5.0 + float(i))), 3.0)
	FighterArt.outline(c, pts, 4.0)
	if dead:
		EnemyArt.ko_eye(c, c0 + Vector2(r * 0.3, -r * 0.2), 3.0, t)
	else:
		c.draw_circle(c0 + Vector2(r * 0.35, -r * 0.15), 4.0 * k, crack)
