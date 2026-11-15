class_name OrdArt
extends RefCounted
## TERRA ORDINARIORUM art: the real-life ANIMALS of every biome, the TOWNSFOLK, the CRYSTAL SWARM,
## the STORM FINGER, the LIGHTNING CANDLE, the TICKET and the frozen statues. All static, drawn
## from the feet (origin), facing right, like every other model.

const BLACK := Color(0, 0, 0)
const ICE := Color(0.70, 0.88, 1.0)
const ICE_HI := Color(0.95, 1.0, 1.0)
const ICE_SHADE := Color(0.38, 0.58, 0.82)
const STORM := Color(0.20, 0.22, 0.32)
const STORM_HI := Color(0.45, 0.50, 0.68)
const STORM_SHADE := Color(0.10, 0.11, 0.18)
const BOLT := Color(0.75, 0.90, 1.0)

## Four-legged animals: [body w, body h, leg len, colour, shade, head r, extras...]
const QUAD := {
	"rabbit": {"bw": 26.0, "bh": 18.0, "leg": 6.0, "col": Color(0.62, 0.52, 0.42), "head": 9.0, "ears": "long", "tail": "puff"},
	"sheep": {"bw": 50.0, "bh": 32.0, "leg": 18.0, "col": Color(0.94, 0.93, 0.88), "head": 10.0, "wool": true, "face": Color(0.18, 0.16, 0.15)},
	"cow": {"bw": 74.0, "bh": 38.0, "leg": 26.0, "col": Color(0.95, 0.94, 0.92), "head": 14.0, "spots": true, "horns": "small"},
	"deer": {"bw": 54.0, "bh": 26.0, "leg": 34.0, "col": Color(0.66, 0.44, 0.26), "head": 10.0, "antlers": true, "tail": "short"},
	"fox": {"bw": 40.0, "bh": 18.0, "leg": 14.0, "col": Color(0.88, 0.45, 0.16), "head": 10.0, "ears": "point", "tail": "bushy"},
	"boar": {"bw": 54.0, "bh": 30.0, "leg": 14.0, "col": Color(0.36, 0.27, 0.22), "head": 14.0, "tusks": true, "tail": "short"},
	"dog": {"bw": 42.0, "bh": 22.0, "leg": 18.0, "col": Color(0.78, 0.60, 0.36), "head": 11.0, "ears": "flop", "tail": "up"},
	"cat": {"bw": 32.0, "bh": 16.0, "leg": 13.0, "col": Color(0.30, 0.30, 0.32), "head": 9.0, "ears": "point", "tail": "up"},
	"goat": {"bw": 44.0, "bh": 26.0, "leg": 22.0, "col": Color(0.85, 0.82, 0.76), "head": 10.0, "horns": "curl", "beard": true},
	"fennec": {"bw": 30.0, "bh": 15.0, "leg": 12.0, "col": Color(0.93, 0.80, 0.56), "head": 8.0, "ears": "huge", "tail": "bushy"},
	"marmot": {"bw": 30.0, "bh": 20.0, "leg": 6.0, "col": Color(0.52, 0.40, 0.28), "head": 9.0, "ears": "round", "tail": "short"},
}


static func animal(c: CanvasItem, kind: String, st: Dictionary) -> void:
	var t: float = st.get("t", 0.0)
	var moving: bool = st.get("moving", false)
	var dead: bool = st.get("dead", false)
	if dead:
		c.draw_set_transform(Vector2(0, -4), PI * 0.5, Vector2.ONE)       # Lying on its side
	if QUAD.has(kind):
		_quad(c, QUAD[kind], t, moving)
	else:
		match kind:
			"chicken":
				_bird(c, t, moving, Color(0.97, 0.95, 0.90), Color(0.9, 0.15, 0.1), 0.9, false)
			"parrot":
				_bird(c, t, moving, Color(0.15, 0.75, 0.30), Color(0.95, 0.25, 0.15), 0.85, true)
			"eagle":
				_bird(c, t, moving, Color(0.38, 0.27, 0.18), Color(0.98, 0.98, 0.96), 1.25, true)
			"frog":
				_frog(c, t, moving)
			"lizard":
				_lizard(c, t, moving)
			"scorpion":
				_scorpion(c, t, moving)
			"monkey":
				_monkey(c, t, moving)
	if dead:
		c.draw_set_transform(Vector2.ZERO, 0.0, Vector2.ONE)


static func _quad(c: CanvasItem, q: Dictionary, t: float, moving: bool) -> void:
	var bw: float = q["bw"]
	var bh: float = q["bh"]
	var leg: float = q["leg"]
	var col: Color = q["col"]
	var shade := col.darkened(0.3)
	var hi := col.lightened(0.25)
	var ph := t * (14.0 if moving else 0.0)
	var by := -leg - bh * 0.5                                     # Body centre
	# Tail (behind)
	match String(q.get("tail", "")):
		"puff":
			FighterArt.ball(c, Vector2(-bw * 0.5, by - 2), 6.0, Color(0.95, 0.95, 0.95), Color(0.75, 0.75, 0.75), Color.WHITE)
		"bushy":
			c.draw_line(Vector2(-bw * 0.45, by), Vector2(-bw * 0.95, by + 4 + sin(t * 3.0) * 3.0), BLACK, 14.0)
			c.draw_line(Vector2(-bw * 0.45, by), Vector2(-bw * 0.95, by + 4 + sin(t * 3.0) * 3.0), col, 10.0)
			c.draw_circle(Vector2(-bw * 0.95, by + 4 + sin(t * 3.0) * 3.0), 4.0, Color(0.98, 0.96, 0.92))
		"up":
			c.draw_line(Vector2(-bw * 0.45, by - 2), Vector2(-bw * 0.62, by - bh * 0.9 + sin(t * 4.0) * 3.0), BLACK, 7.0)
			c.draw_line(Vector2(-bw * 0.45, by - 2), Vector2(-bw * 0.62, by - bh * 0.9 + sin(t * 4.0) * 3.0), col, 4.0)
		"short":
			c.draw_line(Vector2(-bw * 0.48, by - 4), Vector2(-bw * 0.6, by + 2), col.darkened(0.2), 4.0)
	# Legs (far pair darker, near pair in front)
	for k in 2:
		for side in 2:
			var lx := (bw * 0.32) * (1.0 if side == 0 else -1.0)
			var sw := sin(ph + float(side) * PI + float(k) * PI * 0.5) * 6.0
			var lc := shade if k == 0 else col
			FighterArt.limb(c, Vector2(lx + float(k) * 3.0, by + bh * 0.3), Vector2(lx + sw + float(k) * 3.0, 0), maxf(4.0, leg * 0.22), lc, BLACK, lc.lightened(0.2))
	# Body
	var body := EnemyArt.ellipse_points(Vector2(0, by), bw * 0.5, bh * 0.5, 16)
	if bool(q.get("wool", false)):                                # Sheep: a cloud of wool
		for i in 7:
			var a := TAU * float(i) / 7.0
			FighterArt.ball(c, Vector2(cos(a) * bw * 0.36, by + sin(a) * bh * 0.32), bh * 0.36, col, col.darkened(0.12), Color.WHITE)
	else:
		c.draw_colored_polygon(body, col)
		c.draw_colored_polygon(EnemyArt.ellipse_points(Vector2(0, by + bh * 0.18), bw * 0.42, bh * 0.22, 12), shade.lerp(col, 0.4))
		FighterArt.outline(c, body, 2.5)
	if bool(q.get("spots", false)):
		for p: Vector2 in [Vector2(-14, -4), Vector2(10, 4), Vector2(22, -6)]:
			c.draw_circle(Vector2(p.x, by + p.y), 7.0, Color(0.12, 0.1, 0.1))
	# Head
	var hr: float = q["head"]
	var hp := Vector2(bw * 0.5 + hr * 0.4, by - bh * 0.35 + (sin(t * 2.0) * 1.5 if not moving else 0.0))
	var face: Color = q.get("face", col)
	match String(q.get("ears", "")):
		"long":
			for d: float in [-3.0, 3.0]:
				c.draw_colored_polygon(EnemyArt.ellipse_points(hp + Vector2(d - 2.0, -hr * 1.5), 3.5, hr * 0.9, 8), col)
				FighterArt.outline(c, EnemyArt.ellipse_points(hp + Vector2(d - 2.0, -hr * 1.5), 3.5, hr * 0.9, 8), 1.5)
		"point", "huge":
			var ez := 1.8 if String(q["ears"]) == "huge" else 1.0
			for d: float in [-4.0, 4.0]:
				var e := PackedVector2Array([hp + Vector2(d - 4.0, -hr * 0.5), hp + Vector2(d, -hr * (1.1 + 0.9 * ez)), hp + Vector2(d + 4.0, -hr * 0.5)])
				c.draw_colored_polygon(e, col)
				FighterArt.outline(c, e, 1.5)
		"flop":
			c.draw_colored_polygon(EnemyArt.ellipse_points(hp + Vector2(-hr * 0.4, -hr * 0.1), 4.0, hr * 0.7, 8), col.darkened(0.3))
		"round":
			c.draw_circle(hp + Vector2(-2, -hr * 0.85), 3.5, col.darkened(0.2))
	match String(q.get("horns", "")):
		"small":
			c.draw_line(hp + Vector2(-4, -hr * 0.8), hp + Vector2(-8, -hr * 1.4), Color(0.9, 0.85, 0.7), 3.0)
			c.draw_line(hp + Vector2(4, -hr * 0.8), hp + Vector2(6, -hr * 1.4), Color(0.9, 0.85, 0.7), 3.0)
		"curl":
			c.draw_arc(hp + Vector2(-4, -hr * 0.9), hr * 0.7, PI, TAU * 0.95, 10, Color(0.6, 0.55, 0.45), 4.0)
	if bool(q.get("antlers", false)):
		for d: float in [-3.0, 3.0]:
			var a0 := hp + Vector2(d, -hr * 0.8)
			c.draw_polyline(PackedVector2Array([a0, a0 + Vector2(-6, -18), a0 + Vector2(-14, -26)]), Color(0.45, 0.32, 0.2), 3.0)
			c.draw_line(a0 + Vector2(-5, -14), a0 + Vector2(4, -24), Color(0.45, 0.32, 0.2), 3.0)
	FighterArt.ball(c, hp, hr, face, face.darkened(0.3), face.lightened(0.25))
	c.draw_colored_polygon(EnemyArt.ellipse_points(hp + Vector2(hr * 0.8, hr * 0.25), hr * 0.55, hr * 0.42, 10), face.lightened(0.08))   # Snout
	c.draw_circle(hp + Vector2(hr * 1.25, hr * 0.15), 1.8, BLACK)
	c.draw_circle(hp + Vector2(hr * 0.25, -hr * 0.2), 2.0, BLACK)
	if bool(q.get("tusks", false)):
		c.draw_line(hp + Vector2(hr * 0.9, hr * 0.5), hp + Vector2(hr * 1.2, -hr * 0.1), Color(0.95, 0.92, 0.85), 3.0)
	if bool(q.get("beard", false)):
		c.draw_colored_polygon(PackedVector2Array([hp + Vector2(hr * 0.6, hr * 0.6), hp + Vector2(hr * 1.0, hr * 0.6), hp + Vector2(hr * 0.75, hr * 1.4)]), Color(0.95, 0.94, 0.9))


static func _bird(c: CanvasItem, t: float, moving: bool, col: Color, accent: Color, s: float, flap: bool) -> void:
	var hop := absf(sin(t * 12.0)) * 6.0 if moving else 0.0
	var o := Vector2(0, -hop)
	for d: float in [-3.0, 3.0]:
		c.draw_line(o + Vector2(d, -10 * s), o + Vector2(d, 0), Color(0.9, 0.6, 0.15), 2.5)
	var body := EnemyArt.ellipse_points(o + Vector2(0, -20 * s), 14.0 * s, 11.0 * s, 14)
	c.draw_colored_polygon(body, col)
	FighterArt.outline(c, body, 2.0)
	var wing_a := (sin(t * 18.0) * 0.6) if flap and moving else 0.0
	var wing := PackedVector2Array([o + Vector2(-4, -22) * s, o + Vector2(-20 * s, -24 * s - 8.0 * wing_a), o + Vector2(-6, -14) * s])
	c.draw_colored_polygon(wing, col.darkened(0.2))
	FighterArt.ball(c, o + Vector2(11, -33) * s, 7.0 * s, col, col.darkened(0.2), col.lightened(0.2))
	c.draw_colored_polygon(PackedVector2Array([o + Vector2(16, -35) * s, o + Vector2(24, -32) * s, o + Vector2(16, -30) * s]), Color(0.95, 0.75, 0.2))
	c.draw_circle(o + Vector2(13, -35) * s, 1.5, BLACK)
	c.draw_circle(o + Vector2(9, -41) * s, 3.0 * s, accent)                     # Comb / crest


static func _frog(c: CanvasItem, t: float, moving: bool) -> void:
	var hop := absf(sin(t * 8.0)) * 10.0 if moving else 0.0
	var o := Vector2(0, -hop)
	var col := Color(0.30, 0.70, 0.25)
	var body := EnemyArt.ellipse_points(o + Vector2(0, -10), 14, 10, 14)
	c.draw_colored_polygon(body, col)
	FighterArt.outline(c, body, 2.0)
	for d: float in [-6.0, 6.0]:
		FighterArt.ball(c, o + Vector2(d + 4.0, -20), 4.5, col, col.darkened(0.3), col.lightened(0.3))
		c.draw_circle(o + Vector2(d + 5.0, -21), 2.0, BLACK)


static func _lizard(c: CanvasItem, t: float, moving: bool) -> void:
	var col := Color(0.62, 0.55, 0.32)
	var w := sin(t * (16.0 if moving else 2.0)) * 4.0
	var pts := PackedVector2Array([Vector2(-34, -4 + w * 0.5), Vector2(-18, -6 - w * 0.3), Vector2(0, -8), Vector2(14, -7), Vector2(22, -6)])
	c.draw_polyline(pts, BLACK, 10.0)
	c.draw_polyline(pts, col, 7.0)
	for x: float in [-10.0, 8.0]:
		c.draw_line(Vector2(x, -6), Vector2(x + w, 0), col.darkened(0.3), 3.0)
	c.draw_circle(Vector2(20, -8), 1.5, BLACK)


static func _scorpion(c: CanvasItem, t: float, moving: bool) -> void:
	var col := Color(0.55, 0.38, 0.18)
	var body := EnemyArt.ellipse_points(Vector2(0, -8), 14, 6, 12)
	for i in 3:
		var lx := -8.0 + float(i) * 8.0
		var sw := sin(t * (18.0 if moving else 1.0) + float(i)) * 3.0
		c.draw_line(Vector2(lx, -6), Vector2(lx + sw - 4.0, 0), col.darkened(0.3), 2.0)
	c.draw_colored_polygon(body, col)
	FighterArt.outline(c, body, 2.0)
	var tail := PackedVector2Array([Vector2(-12, -8), Vector2(-22, -18), Vector2(-18, -30), Vector2(-8, -32)])
	c.draw_polyline(tail, BLACK, 6.0)
	c.draw_polyline(tail, col, 4.0)
	c.draw_circle(Vector2(-6, -30), 3.0, Color(0.2, 0.1, 0.05))
	for d: float in [-3.0, 3.0]:
		c.draw_circle(Vector2(16, -8 + d), 3.5, col.darkened(0.2))


static func _monkey(c: CanvasItem, t: float, moving: bool) -> void:
	var col := Color(0.45, 0.30, 0.18)
	var face := Color(0.85, 0.70, 0.55)
	var ph := t * (12.0 if moving else 0.0)
	c.draw_arc(Vector2(-14, -20), 16.0, PI * 0.5, PI * 1.6, 10, col, 4.0)          # Curled tail
	for d: float in [-1.0, 1.0]:
		FighterArt.limb(c, Vector2(d * 6.0, -18), Vector2(d * 8.0 + sin(ph + d) * 5.0, 0), 5.0, col, BLACK, col.lightened(0.2))
	var torso := EnemyArt.ellipse_points(Vector2(0, -26), 12, 14, 12)
	c.draw_colored_polygon(torso, col)
	FighterArt.outline(c, torso, 2.0)
	FighterArt.limb(c, Vector2(6, -34), Vector2(14, -24 + sin(t * 3.0) * 4.0), 4.0, col, BLACK, col.lightened(0.2))
	FighterArt.ball(c, Vector2(3, -46), 9.0, col, col.darkened(0.3), col.lightened(0.2))
	c.draw_colored_polygon(EnemyArt.ellipse_points(Vector2(6, -45), 6, 5, 10), face)
	c.draw_circle(Vector2(8, -47), 1.5, BLACK)
	for d: float in [-9.0, 9.0]:
		c.draw_circle(Vector2(3 + d, -47), 3.5, face.darkened(0.2))


# ============================================================
# TOWNSFOLK (humans)
# ============================================================
## look: 0..5 picks clothes / hair. Simple, friendly villagers.
static func villager(c: CanvasItem, look: int, t: float) -> void:
	var shirts := [Color(0.30, 0.45, 0.70), Color(0.70, 0.30, 0.25), Color(0.35, 0.55, 0.30), Color(0.75, 0.65, 0.35), Color(0.45, 0.35, 0.55), Color(0.55, 0.55, 0.58)]
	var hairs := [Color(0.25, 0.16, 0.10), Color(0.85, 0.70, 0.35), Color(0.10, 0.08, 0.07), Color(0.60, 0.30, 0.15), Color(0.75, 0.75, 0.78), Color(0.40, 0.28, 0.18)]
	var skins := [Color(0.95, 0.80, 0.66), Color(0.80, 0.60, 0.45), Color(0.62, 0.44, 0.30), Color(0.98, 0.86, 0.74)]
	var shirt: Color = shirts[look % shirts.size()]
	var hair: Color = hairs[(look * 2 + 1) % hairs.size()]
	var skin: Color = skins[look % skins.size()]
	var pants := Color(0.24, 0.22, 0.26)
	var breathe := sin(t * 2.0) * 1.0
	for d: float in [-1.0, 1.0]:
		FighterArt.limb(c, Vector2(d * 6.0, -48), Vector2(d * 8.0, -2), 8.0, pants, BLACK, pants.lightened(0.2))
	var dress := look % 3 == 1
	var torso := Rect2(-15, -92 + breathe, 30, 46)
	if dress:
		var skirt := PackedVector2Array([Vector2(-14, -60), Vector2(14, -60), Vector2(22, -16), Vector2(-22, -16)])
		c.draw_colored_polygon(skirt, shirt)
		FighterArt.outline(c, skirt, 2.5)
	FighterArt.rrect(c, torso, shirt, shirt.darkened(0.3), shirt.lightened(0.25), 8.0, 2.5)
	for d: float in [-1.0, 1.0]:
		FighterArt.limb(c, Vector2(d * 15.0, -86 + breathe), Vector2(d * 18.0, -54), 6.0, shirt, BLACK, shirt.lightened(0.2))
		c.draw_circle(Vector2(d * 18.0, -52), 4.5, skin)
	FighterArt.ball(c, Vector2(1, -106 + breathe), 13.0, skin, skin.darkened(0.15), skin.lightened(0.1))
	var hair_pts := PackedVector2Array([Vector2(-13, -104), Vector2(-12, -117), Vector2(0, -122), Vector2(12, -118), Vector2(14, -108), Vector2(4, -112)])
	if look % 3 == 1:
		hair_pts = PackedVector2Array([Vector2(-14, -90), Vector2(-14, -116), Vector2(0, -123), Vector2(13, -117), Vector2(14, -106), Vector2(2, -114), Vector2(-6, -96)])
	c.draw_colored_polygon(hair_pts, hair)
	c.draw_circle(Vector2(6, -107 + breathe), 1.8, BLACK)
	c.draw_line(Vector2(5, -99 + breathe), Vector2(10, -100 + breathe), BLACK, 1.5)
	if look % 6 == 4:                                              # Old one: a walking stick
		c.draw_line(Vector2(22, -52), Vector2(26, 0), Color(0.4, 0.28, 0.16), 4.0)


# ============================================================
# THE CRYSTAL SWARM (secret boss) - a floating crystal and its shards
# ============================================================
static func crystal_swarm(c: CanvasItem, st: Dictionary) -> void:
	var t: float = st.get("t", 0.0)
	var broken: bool = st.get("broken", false)
	var shards: int = int(st.get("shards", 10))
	var bob := sin(t * 1.6) * 10.0
	var core := Vector2(0, -150 + bob)
	c.draw_circle(core, 90.0, Color(0.6, 0.85, 1.0, 0.10 + (0.0 if broken else 0.05 * sin(t * 3.0))))
	# The orbiting shards (one for every crystal it still has to shoot)
	for i in shards:
		var a := TAU * float(i) / maxf(float(shards), 1.0) + t * 1.4
		var p := core + Vector2(cos(a) * 78.0, sin(a) * 34.0)
		_shard(c, p, 0.8, a)
	# The core crystal (cracked + tilted when broken)
	var rot := 0.5 if broken else sin(t * 0.8) * 0.1
	var pts := PackedVector2Array()
	for k: Vector2 in [Vector2(0, -60), Vector2(26, -14), Vector2(18, 40), Vector2(0, 58), Vector2(-18, 40), Vector2(-26, -14)]:
		pts.append(core + k.rotated(rot))
	c.draw_colored_polygon(pts, ICE if not broken else ICE.darkened(0.25))
	c.draw_colored_polygon(PackedVector2Array([pts[0], pts[1], core]), ICE_HI)
	c.draw_colored_polygon(PackedVector2Array([pts[3], pts[4], core]), ICE_SHADE)
	FighterArt.outline(c, pts, 3.0)
	if broken:
		c.draw_polyline(PackedVector2Array([core + Vector2(-10, -40), core + Vector2(6, -10), core + Vector2(-6, 14), core + Vector2(10, 40)]), BLACK, 3.0)
	else:
		c.draw_circle(core, 9.0 + 2.0 * sin(t * 5.0), Color(1, 1, 1, 0.8))


static func _shard(c: CanvasItem, p: Vector2, s: float, rot: float) -> void:
	var pts := PackedVector2Array()
	for k: Vector2 in [Vector2(0, -16), Vector2(7, 0), Vector2(0, 16), Vector2(-7, 0)]:
		pts.append(p + (k * s).rotated(rot))
	c.draw_colored_polygon(pts, ICE)
	FighterArt.outline(c, pts, 2.0)


# ============================================================
# THE STORM FINGER - one giant finger of the Storm, reaching down out of the sky
# ============================================================
static func storm_finger(c: CanvasItem, st: Dictionary) -> void:
	var t: float = st.get("t", 0.0)
	var pose: String = st.get("pose", "idle")
	var lift := 0.0                                                 # How high the fingertip is
	if pose.ends_with("_tele"):
		lift = 120.0 + 20.0 * sin(t * 10.0)
	elif pose == "press":
		lift = -10.0
	var tip := Vector2(0, -lift)
	var curl := 0.0
	if pose == "sweep" or pose == "sweep_tele":
		curl = 0.5
	var w := 52.0
	# The finger: three segments going up off the screen, knuckles, a dark nail
	var seg := [tip]
	var dirv := Vector2(0, -1).rotated(-curl * 0.6)
	var p: Vector2 = tip
	for i in 3:
		p += dirv * (120.0 + 40.0 * float(i))
		seg.append(p)
		dirv = dirv.rotated(curl * 0.3)
	if bool(st.get("short", false)):                                # Portraits: just the finger
		seg.resize(3)
	else:
		seg.append(p + Vector2(0, -2400))
	for i in range(seg.size() - 1):
		var a: Vector2 = seg[i]
		var b: Vector2 = seg[i + 1]
		var ww := w + float(i) * 6.0
		c.draw_line(a, b, BLACK, ww + 8.0)
		c.draw_line(a, b, STORM, ww)
		c.draw_line(a + Vector2(-ww * 0.25, 0), b + Vector2(-ww * 0.25, 0), STORM_HI.lerp(STORM, 0.5), ww * 0.25)
		if i < 3:
			c.draw_circle(b, ww * 0.5 + 4.0, BLACK)
			c.draw_circle(b, ww * 0.5, STORM.lightened(0.05))
			c.draw_arc(b, ww * 0.3, PI * 0.1, PI * 0.9, 8, STORM_SHADE, 3.0)
	c.draw_circle(tip, w * 0.5 + 4.0, BLACK)
	c.draw_circle(tip, w * 0.5, STORM)
	var nail := EnemyArt.ellipse_points(tip + Vector2(10, -16), 14, 20, 12)
	c.draw_colored_polygon(nail, STORM_SHADE)
	FighterArt.outline(c, nail, 2.0)
	# Lightning crawling over it
	for k in 3:
		var y0 := -60.0 - float(k) * 140.0 - fmod(t * 300.0, 140.0)
		var bolt := PackedVector2Array([tip + Vector2(-20, y0), tip + Vector2(6, y0 - 26), tip + Vector2(-8, y0 - 48), tip + Vector2(16, y0 - 80)])
		c.draw_polyline(bolt, Color(BOLT.r, BOLT.g, BOLT.b, 0.6 + 0.4 * sin(t * 20.0 + float(k))), 2.5)
	if lift > 0.0:                                                  # Its shadow on the ground
		c.draw_colored_polygon(EnemyArt.ellipse_points(Vector2(0, -2), 40.0 + lift * 0.1, 8, 12), Color(0, 0, 0, 0.35))


# ============================================================
# ITEMS
# ============================================================
## The LIGHTNING CANDLE: a candle of grey stone wax with a crackling blue lightning flame.
static func candle(c: CanvasItem, p: Vector2, s: float, t: float) -> void:
	c.draw_circle(p + Vector2(0, -34) * s, 30.0 * s, Color(0.5, 0.75, 1.0, 0.16 + 0.06 * sin(t * 9.0)))
	var body := Rect2(p.x - 9 * s, p.y - 28 * s, 18 * s, 28 * s)
	FighterArt.rrect(c, body, Color(0.82, 0.84, 0.88), Color(0.55, 0.58, 0.64), Color(0.98, 0.98, 1.0), 4.0, 2.5)
	c.draw_line(p + Vector2(0, -28) * s, p + Vector2(0, -32) * s, BLACK, 2.0)
	var f := p + Vector2(0, -32) * s
	var bolt := PackedVector2Array([f, f + Vector2(-5, -9) * s, f + Vector2(3, -12) * s, f + Vector2(-3, -22) * s + Vector2(sin(t * 30.0) * 2.0, 0)])
	c.draw_polyline(bolt, BLACK, 5.0)
	c.draw_polyline(bolt, BOLT, 3.0)
	c.draw_circle(f + Vector2(0, -8) * s, 4.0 * s, Color(1, 1, 1, 0.8))


## The ORDINARIORUM TICKET: an old paper ticket with a gold seal.
static func ticket(c: CanvasItem, p: Vector2, s: float, t: float) -> void:
	var r := Rect2(p.x - 26 * s, p.y - 16 * s, 52 * s, 32 * s)
	c.draw_circle(p, 40.0 * s, Color(1.0, 0.9, 0.5, 0.12 + 0.05 * sin(t * 3.0)))
	FighterArt.rrect(c, r, Color(0.93, 0.88, 0.74), Color(0.75, 0.68, 0.52), Color(1, 0.98, 0.9), 3.0, 2.0)
	c.draw_line(Vector2(p.x + 10 * s, r.position.y + 3), Vector2(p.x + 10 * s, r.end.y - 3), Color(0.5, 0.42, 0.3), 1.5)
	c.draw_circle(p + Vector2(-8, 0) * s, 7.0 * s, Color(0.85, 0.65, 0.2))
	c.draw_circle(p + Vector2(-8, 0) * s, 4.0 * s, Color(0.65, 0.2, 0.15))


## A creature of Terra Craterum, FROZEN in a block of ice (the Snow Desert).
static func frozen(c: CanvasItem, kind: String, t: float) -> void:
	c.draw_set_transform(Vector2.ZERO, 0.0, Vector2.ONE)
	if kind == "kharleming":
		CraterArt.kharleming(c, {"t": 0.0, "pose": "idle"}, false)
	else:
		CraterArt.golem(c, {"t": 0.0, "pose": "idle"})
	var h := 120.0 if kind == "kharleming" else 190.0
	var block := PackedVector2Array([Vector2(-60, 4), Vector2(-66, -h * 0.6), Vector2(-48, -h), Vector2(44, -h - 10), Vector2(64, -h * 0.5), Vector2(56, 4)])
	c.draw_colored_polygon(block, Color(0.75, 0.9, 1.0, 0.55))
	c.draw_polyline(PackedVector2Array([block[1], block[2], block[3]]), Color(1, 1, 1, 0.8), 3.0)
	FighterArt.outline(c, block, 2.5)
	c.draw_line(Vector2(-30, -h * 0.8), Vector2(-10, -h * 0.3), Color(1, 1, 1, 0.5 + 0.2 * sin(t)), 2.0)
