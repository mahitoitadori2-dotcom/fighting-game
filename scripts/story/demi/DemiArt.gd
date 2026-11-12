class_name DemiArt
extends RefCounted
## DEMILAND drawing kit (same flat cartoon style: thick black outlines, facing RIGHT, origin = feet).
##   tribal(c, s, cfg)   a PRIMITIVE person: bare dark skin, hide loincloth, war paint, bone mask,
##                       feathers, a necklace of teeth, a tiger pelt (cultists)...
##   beast(c, s, cfg)    a big cat on four legs (the Last Tiger, its cubs)
##   treant(c, s, cfg)   a walking dead tree (husks, saplings, the Tree Lord)

const BLACK := Color(0, 0, 0)
const BONE := Color(0.86, 0.82, 0.70)
const HIDE := Color(0.42, 0.30, 0.20)
const SKIN := Color(0.40, 0.30, 0.24)
const PAINT := Color(0.75, 0.18, 0.12)
const BARK := Color(0.22, 0.17, 0.13)
const TIGER := Color(0.78, 0.42, 0.14)


## cfg (all optional, plus every ExtArt.humanoid key):
##   mask: true (bone skull mask)   feathers: int   paint: Color (war stripes)   teeth: true
##   pelt: true (tiger pelt hood + cape)   headdress: true (the chieftain's big feather crown)
static func tribal(c: CanvasItem, s: Dictionary, cfg: Dictionary) -> void:
	var t: float = s.get("t", 0.0)
	var h: float = cfg.get("h", 1.0)
	var w: float = cfg.get("w", 1.0)
	var bob := sin(t * 3.0) * 1.5
	var head := Vector2(4 * w, -132 * h + bob)
	var hr := 14.0 * w
	if cfg.get("pelt", false):                              # Tiger pelt cape (behind)
		var cape := PackedVector2Array([Vector2(-8 * w, -124 * h), Vector2(10 * w, -124 * h), Vector2(-14 * w, -40 * h), Vector2(-34 * w - sin(t * 2.0) * 4.0, -46 * h)])
		c.draw_colored_polygon(cape, TIGER)
		for k in 3:
			var y := -110.0 * h + float(k) * 22.0 * h
			c.draw_line(Vector2(-6 * w, y), Vector2(-24 * w, y + 8.0), BLACK, 3.0)
		FighterArt.outline(c, cape, 3.0)
	var base := cfg.duplicate()
	if not base.has("skin"):
		base["skin"] = SKIN
	if not base.has("cloth"):
		base["cloth"] = SKIN.darkened(0.08)
		base["cloth_hi"] = SKIN.lightened(0.12)
		base["trim"] = HIDE
	ExtArt.humanoid(c, s, base)
	# Hide loincloth over the hips
	var hip := -60.0 * h
	var loin := PackedVector2Array([Vector2(-17 * w, hip - 6), Vector2(17 * w, hip - 6), Vector2(12 * w, hip + 18), Vector2(0, hip + 26), Vector2(-14 * w, hip + 18)])
	c.draw_colored_polygon(loin, HIDE)
	FighterArt.outline(c, loin, 3.0)
	# War paint stripes across the chest
	var paint: Color = cfg.get("paint", PAINT)
	for k in 3:
		var y := -106.0 * h + float(k) * 12.0 + bob
		c.draw_line(Vector2(-12 * w, y), Vector2(12 * w, y + 4.0), paint, 3.0)
	if cfg.get("teeth", false):                              # Necklace of teeth
		for k in 7:
			var a := PI * (0.15 + 0.7 * float(k) / 6.0)
			var p := Vector2(2 * w, -116 * h + bob) + Vector2(cos(a) * 14.0 * w, sin(a) * 8.0)
			c.draw_colored_polygon(PackedVector2Array([p + Vector2(-2, 0), p + Vector2(2, 0), p + Vector2(0, 7)]), BONE)
	if cfg.get("mask", false):                               # Bone skull mask over the face
		var m := PackedVector2Array([head + Vector2(-hr * 0.6, -hr * 0.9), head + Vector2(hr * 1.1, -hr * 0.7), head + Vector2(hr * 1.15, hr * 0.5),
			head + Vector2(hr * 0.5, hr * 1.0), head + Vector2(-hr * 0.4, hr * 0.6)])
		c.draw_colored_polygon(m, BONE)
		FighterArt.outline(c, m, 2.5)
		c.draw_circle(head + Vector2(hr * 0.55, -hr * 0.15), 3.5, BLACK)
		c.draw_circle(head + Vector2(hr * 0.55, -hr * 0.15), 1.6, cfg.get("eye", Color(1.0, 0.4, 0.2)))
		for k in 3:
			c.draw_line(head + Vector2(hr * (0.2 + 0.25 * float(k)), hr * 0.55), head + Vector2(hr * (0.2 + 0.25 * float(k)), hr * 0.85), BLACK, 1.5)
	if cfg.get("pelt", false):                               # Tiger head as a hood (ears + stripes)
		var hood := EnemyArt.ellipse_points(head + Vector2(-2, -hr * 0.7), hr * 1.2, hr * 0.7, 14)
		c.draw_colored_polygon(hood, TIGER)
		for e: float in [-0.6, 0.6]:
			c.draw_colored_polygon(PackedVector2Array([head + Vector2(hr * e - 5, -hr * 1.2), head + Vector2(hr * e + 5, -hr * 1.2), head + Vector2(hr * e, -hr * 1.8)]), TIGER)
		c.draw_line(head + Vector2(-6, -hr * 1.3), head + Vector2(-2, -hr * 0.6), BLACK, 3.0)
		c.draw_line(head + Vector2(6, -hr * 1.3), head + Vector2(4, -hr * 0.6), BLACK, 3.0)
		FighterArt.outline(c, hood, 3.0)
	var feathers := int(cfg.get("feathers", 0))
	for k in feathers:                                       # Feathers stuck in the hair
		var a := -1.9 + float(k) * 0.35
		var root := head + Vector2(-hr * 0.2, -hr * 0.8)
		var tip := root + Vector2.from_angle(a) * 26.0
		c.draw_line(root, tip, BLACK, 6.0)
		c.draw_line(root, tip, Color(0.15, 0.12, 0.10) if k % 2 == 0 else Color(0.55, 0.15, 0.10), 3.5)
	if cfg.get("headdress", false):                          # The chieftain's crown of black feathers + bones
		for k in 9:
			var a := -PI * 0.5 + (float(k) - 4.0) * 0.22
			var root := head + Vector2(0, -hr * 0.6)
			var tip := root + Vector2.from_angle(a) * (52.0 + 10.0 * sin(float(k) * 1.7))
			c.draw_line(root, tip, BLACK, 9.0)
			c.draw_line(root, tip, Color(0.10, 0.08, 0.08) if k % 2 == 0 else Color(0.62, 0.16, 0.10), 5.0)
			c.draw_circle(tip, 3.5, BONE)
		c.draw_rect(Rect2(head.x - hr, head.y - hr * 0.9, hr * 2.0, 6.0), BONE)


## A big cat on four legs. cfg: size (1 = cub ~110 px long), coat, stripes, eye, scars (bool),
## old (bool: grey muzzle, ribs). Poses: idle / bite / claw / pounce / roar / rush (+ _tele).
static func beast(c: CanvasItem, s: Dictionary, cfg: Dictionary) -> void:
	var t: float = s.get("t", 0.0)
	var pose: String = s.get("pose", "idle")
	var dead: bool = s.get("dead", false)
	var k: float = cfg.get("size", 1.0)
	var coat: Color = cfg.get("coat", TIGER)
	var stripe: Color = cfg.get("stripes", Color(0.08, 0.05, 0.04))
	var eye: Color = cfg.get("eye", Color(1.0, 0.85, 0.2))
	var walk: float = s.get("walk", 0.0) * 4.0
	var tele := pose.ends_with("_tele")
	var base := pose.trim_suffix("_tele")
	var crouch := 10.0 * k if tele and base in ["pounce", "rush"] else 0.0
	var rear := -16.0 * k if base == "claw" and not tele else 0.0
	var body_c := Vector2(-6 * k, -52 * k + crouch)
	var head := Vector2(46 * k, -66 * k + crouch + rear)
	if base == "roar":
		head += Vector2(4 * k, -6 * k)
	# Tail
	var tail := PackedVector2Array()
	for i in 8:
		var u := float(i) / 7.0
		tail.append(body_c + Vector2(-48 * k - u * 46 * k, -6 * k - u * 30 * k + sin(t * 3.0 + u * 4.0) * 8.0 * k * u))
	c.draw_polyline(tail, BLACK, 11.0 * k, true)
	c.draw_polyline(tail, coat, 6.5 * k, true)
	c.draw_circle(tail[tail.size() - 1], 4.0 * k, stripe)
	# Legs (far pair darker, then near pair)
	for far in [true, false]:
		for front in [false, true]:
			var hip := body_c + Vector2((34.0 if front else -38.0) * k, 6 * k)
			var ph := walk + (0.0 if front else PI) + (PI * 0.5 if far else 0.0)
			var foot := Vector2(hip.x + sin(ph) * 12.0 * k, 0)
			if front and base == "claw" and not far and not tele:
				foot = hip + Vector2(34 * k, -10 * k)                  # Swiping paw
			if base == "pounce" and not tele:
				foot = hip + Vector2((26.0 if front else -26.0) * k, 26 * k)
			var col := coat.darkened(0.3) if far else coat
			c.draw_line(hip, foot, BLACK, 15.0 * k, true)
			c.draw_line(hip, foot, col, 10.0 * k, true)
			c.draw_circle(foot, 7.0 * k, BLACK)
			c.draw_circle(foot, 5.0 * k, col)
	# Body
	var body := EnemyArt.ellipse_points(body_c, 56 * k, 25 * k, 22)
	c.draw_colored_polygon(body, coat)
	c.draw_colored_polygon(EnemyArt.ellipse_points(body_c + Vector2(4 * k, 12 * k), 40 * k, 10 * k, 14), coat.lightened(0.35))
	for i in 6:                                              # Stripes
		var x := body_c.x - 40.0 * k + float(i) * 15.0 * k
		c.draw_line(Vector2(x, body_c.y - 24 * k), Vector2(x + 6 * k, body_c.y - 4 * k), stripe, 4.0 * k)
	if cfg.get("old", false):                                # Ribs showing: starving, the last of its kind
		for i in 3:
			c.draw_arc(body_c + Vector2(float(i) * 9.0 * k - 6 * k, 4 * k), 10.0 * k, 0.3, 2.4, 6, coat.darkened(0.4), 2.0)
	if cfg.get("scars", false):
		c.draw_line(body_c + Vector2(-10 * k, -18 * k), body_c + Vector2(14 * k, -2 * k), Color(0.95, 0.75, 0.70), 2.5)
		c.draw_line(body_c + Vector2(-4 * k, -20 * k), body_c + Vector2(20 * k, -6 * k), Color(0.95, 0.75, 0.70), 2.5)
	FighterArt.outline(c, body, 3.5 * k + 0.5)
	# Head: round face, ears, muzzle, jaw
	var hd := EnemyArt.ellipse_points(head, 22 * k, 19 * k, 18)
	c.draw_colored_polygon(hd, coat)
	for e: float in [-1.0, 1.0]:
		var ear := PackedVector2Array([head + Vector2(e * 9 * k - 6 * k, -14 * k), head + Vector2(e * 9 * k + 4 * k, -16 * k), head + Vector2(e * 9 * k - 2 * k, -27 * k)])
		c.draw_colored_polygon(ear, coat)
		FighterArt.outline(c, ear, 2.5)
	c.draw_line(head + Vector2(-8 * k, -16 * k), head + Vector2(-4 * k, -6 * k), stripe, 3.0 * k)
	c.draw_line(head + Vector2(2 * k, -18 * k), head + Vector2(4 * k, -8 * k), stripe, 3.0 * k)
	var muzzle := head + Vector2(16 * k, 6 * k)
	c.draw_circle(muzzle, 10.0 * k, Color(0.9, 0.86, 0.78) if not cfg.get("old", false) else Color(0.75, 0.74, 0.72))
	c.draw_circle(muzzle + Vector2(6 * k, -4 * k), 3.5 * k, BLACK)
	var jaw := 10.0 * k if base in ["roar", "bite", "rush"] and not tele else (5.0 * k if tele else 0.0)
	if jaw > 0.0:                                            # Open jaws + fangs
		var mouth := PackedVector2Array([muzzle + Vector2(-6 * k, 4 * k), muzzle + Vector2(12 * k, 2 * k), muzzle + Vector2(10 * k, 4 * k + jaw), muzzle + Vector2(-4 * k, 6 * k + jaw * 0.7)])
		c.draw_colored_polygon(mouth, Color(0.35, 0.05, 0.05))
		c.draw_line(muzzle + Vector2(2 * k, 4 * k), muzzle + Vector2(3 * k, 9 * k), Color.WHITE, 2.5 * k)
		c.draw_line(muzzle + Vector2(9 * k, 3 * k), muzzle + Vector2(9 * k, 8 * k), Color.WHITE, 2.5 * k)
	FighterArt.outline(c, hd, 3.0 * k + 0.5)
	if dead:
		EnemyArt.ko_eye(c, head + Vector2(6 * k, -4 * k), 4.0 * k, t)
	else:
		c.draw_circle(head + Vector2(6 * k, -4 * k), 4.5 * k, BLACK)
		c.draw_circle(head + Vector2(6 * k, -4 * k), 3.2 * k, eye)
		c.draw_line(head + Vector2(6 * k, -7 * k), head + Vector2(6 * k, -1 * k), BLACK, 1.5 * k)
		if base == "roar" or s.get("enraged", false):
			c.draw_circle(head + Vector2(6 * k, -4 * k), 9.0 * k, Color(eye.r, eye.g, eye.b, 0.25))


## A walking dead tree. cfg: h (1 = ~150 px), bark, glow (Color: living light in its cracks, or
## none), eye, branches (int), roots (bool: root legs instead of two trunks).
## Poses: idle / sweep / slam / cast / hop / spit (+ _tele).
static func treant(c: CanvasItem, s: Dictionary, cfg: Dictionary) -> void:
	var t: float = s.get("t", 0.0)
	var pose: String = s.get("pose", "idle")
	var dead: bool = s.get("dead", false)
	var h: float = cfg.get("h", 1.0)
	var bark: Color = cfg.get("bark", BARK)
	var glow: Color = cfg.get("glow", Color(0, 0, 0, 0))
	var eye: Color = cfg.get("eye", Color(1.0, 0.75, 0.3))
	var walk: float = s.get("walk", 0.0) * 3.0
	var tele := pose.ends_with("_tele")
	var base := pose.trim_suffix("_tele")
	var sway := sin(t * 1.4) * 3.0 * h
	if glow.a > 0.0:
		c.draw_circle(Vector2(0, -80 * h), 70.0 * h, Color(glow.r, glow.g, glow.b, 0.10 + 0.05 * sin(t * 3.0)))
	# Root legs
	for i in 4:
		var x0 := (-18.0 + float(i) * 12.0) * h
		var root := PackedVector2Array([Vector2(x0, -40 * h), Vector2(x0 + (float(i) - 1.5) * 14.0 * h + sin(walk + float(i)) * 6.0 * h, -2), Vector2(x0 + (float(i) - 1.5) * 22.0 * h, 0)])
		c.draw_polyline(root, BLACK, 12.0 * h, true)
		c.draw_polyline(root, bark.darkened(0.15), 7.0 * h, true)
	# Trunk
	var top := Vector2(sway, -150 * h)
	var trunk := PackedVector2Array([Vector2(-24 * h, -36 * h), Vector2(26 * h, -36 * h), top + Vector2(18 * h, 0), top + Vector2(-16 * h, 0)])
	c.draw_colored_polygon(trunk, bark)
	for k in 4:                                               # Bark lines
		var x := (-14.0 + float(k) * 9.0) * h
		c.draw_line(Vector2(x, -42 * h), Vector2(x + sway * 0.6, -140 * h), bark.darkened(0.35), 2.0)
	if glow.a > 0.0:                                          # Living light in the cracks
		c.draw_line(Vector2(-6 * h, -50 * h), Vector2(4 * h + sway * 0.5, -120 * h), Color(glow.r, glow.g, glow.b, 0.6 + 0.4 * sin(t * 4.0)), 3.0)
		c.draw_line(Vector2(8 * h, -70 * h), Vector2(14 * h + sway * 0.6, -110 * h), Color(glow.r, glow.g, glow.b, 0.5), 2.5)
	FighterArt.outline(c, trunk, 4.0)
	# Hollow face
	var face := Vector2(6 * h + sway * 0.8, -112 * h)
	var mouth_open := 10.0 * h if base in ["slam", "spit", "cast"] and not tele else 4.0 * h
	c.draw_colored_polygon(EnemyArt.ellipse_points(face + Vector2(0, 18 * h), 9 * h, mouth_open, 12), Color(0.05, 0.03, 0.02))
	if dead:
		EnemyArt.ko_eye(c, face + Vector2(-6 * h, 0), 4.0 * h, t)
		EnemyArt.ko_eye(c, face + Vector2(8 * h, 0), 4.0 * h, t)
	else:
		for ex: float in [-6.0, 8.0]:
			c.draw_circle(face + Vector2(ex * h, 0), 6.0 * h, Color(0.05, 0.03, 0.02))
			c.draw_circle(face + Vector2(ex * h, 0), 3.0 * h, eye)
	# Branch arms: up when winding up, swung forward on the attack
	var arm_a := -0.4
	if tele:
		arm_a = -1.6
	elif base in ["sweep", "slam"]:
		arm_a = 0.5
	var branches := int(cfg.get("branches", 3))
	for k in branches:
		var root := top + Vector2((-10.0 + float(k) * 10.0) * h, 12.0 * h)
		var a := arm_a + (float(k) - 1.0) * 0.5 + (0.0 if k == branches - 1 else -0.6 * float(k % 2))
		var mid := root + Vector2.from_angle(a) * 42.0 * h
		var tip := mid + Vector2.from_angle(a - 0.5) * 34.0 * h
		c.draw_line(root, mid, BLACK, 11.0 * h, true)
		c.draw_line(mid, tip, BLACK, 7.0 * h, true)
		c.draw_line(root, mid, bark, 7.0 * h, true)
		c.draw_line(mid, tip, bark, 4.0 * h, true)
		c.draw_line(mid, mid + Vector2.from_angle(a + 0.9) * 16.0 * h, bark.darkened(0.2), 3.0 * h, true)
		if glow.a > 0.0 and k % 2 == 0:                       # A few living leaves
			c.draw_circle(tip, 5.0 * h, Color(glow.r * 0.6, glow.g * 0.8, glow.b * 0.4, 0.9))
