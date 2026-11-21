class_name TownArt
extends RefCounted
## THE ABANDONED TOWN (level 81) - the art. Flat cartoon + thick black outlines like every other
## character (the PixelArt group around them turns it into pixel art in the level).
## Everything is drawn feet-at-origin, facing RIGHT, ~125 units tall for a person.

const BLACK := Color(0, 0, 0)
const SKIN := Color(0.93, 0.78, 0.64)
const SKIN_OLD := Color(0.88, 0.74, 0.62)
const SUN_GOLD := Color(1.0, 0.80, 0.30)
const SUN_BLUE := Color(0.22, 0.30, 0.55)
const WOOD := Color(0.42, 0.28, 0.16)
const WOOD_DARK := Color(0.26, 0.17, 0.10)
const PLASTER := Color(0.86, 0.80, 0.68)
const ROOF := Color(0.56, 0.22, 0.16)
const BLOOD := Color(0.30, 0.04, 0.04)
const CHARCOAL := Color(0.10, 0.09, 0.09)
const ASH := Color(0.32, 0.30, 0.29)
const IRON := Color(0.36, 0.36, 0.40)


# ============================================================
# THE THREE WHO KNOW THE LORE
# ============================================================
static func npc(c: CanvasItem, id: String, t: float) -> void:
	match id:
		"judge":
			judge(c, t)
		"shopkeeper":
			shopkeeper(c, t)
		"young_guard":
			young_guard(c, t)


## THE OLDEST JUDGE: a very old man in ordinary clothes - hunched, a long white beard, a brown
## waistcoat over a cream shirt, grey trousers, a crooked cane.
static func judge(c: CanvasItem, t: float) -> void:
	var br := sin(t * 1.4) * 0.8
	var pants := Color(0.40, 0.40, 0.43)
	for d: float in [-1.0, 1.0]:
		FighterArt.limb(c, Vector2(d * 5.0, -44), Vector2(d * 7.0 + 2.0, -2), 8.0, pants, BLACK, pants.lightened(0.15))
		c.draw_rect(Rect2(d * 7.0 - 3.0, -6, 12, 6), WOOD_DARK)
	# Hunched body: the torso leans forward
	var shirt := Color(0.90, 0.86, 0.74)
	var vest := Color(0.45, 0.30, 0.18)
	var torso := PackedVector2Array([Vector2(-14, -46), Vector2(12, -46), Vector2(18, -78 + br), Vector2(4, -92 + br), Vector2(-12, -84 + br)])
	c.draw_colored_polygon(torso, shirt)
	var vpts := PackedVector2Array([Vector2(-13, -48), Vector2(10, -48), Vector2(14, -76 + br), Vector2(6, -82 + br), Vector2(1, -60), Vector2(-4, -82 + br), Vector2(-11, -80 + br)])
	c.draw_colored_polygon(vpts, vest)
	FighterArt.outline(c, torso, 2.5)
	for k in 3:
		c.draw_circle(Vector2(0.5 + float(k) * 0.5, -70 + float(k) * 7.0), 1.3, Color(0.85, 0.70, 0.35))
	# Arm on the cane
	FighterArt.limb(c, Vector2(8, -82 + br), Vector2(22, -52), 6.0, shirt, BLACK, shirt.lightened(0.1))
	c.draw_line(Vector2(24, -54), Vector2(27, 0), BLACK, 5.0)
	c.draw_line(Vector2(24, -54), Vector2(27, 0), WOOD, 3.0)
	c.draw_line(Vector2(18, -56), Vector2(26, -54), WOOD, 4.0)                       # The crook
	c.draw_circle(Vector2(22, -52), 4.0, SKIN_OLD)
	# Head (forward, low), bald top, white hair on the sides, bushy brows, the long beard
	var hc := Vector2(10, -100 + br)
	FighterArt.ball(c, hc, 12.0, SKIN_OLD, SKIN_OLD.darkened(0.15), SKIN_OLD.lightened(0.1))
	c.draw_colored_polygon(PackedVector2Array([hc + Vector2(-12, -2), hc + Vector2(-9, -10), hc + Vector2(-4, -6), hc + Vector2(-6, 4)]), Color(0.92, 0.92, 0.94))
	var beard := PackedVector2Array([hc + Vector2(-2, 4), hc + Vector2(12, 2), hc + Vector2(10, 18), hc + Vector2(4, 34), hc + Vector2(0, 20)])
	c.draw_colored_polygon(beard, Color(0.95, 0.95, 0.96))
	FighterArt.outline(c, beard, 2.0)
	c.draw_line(hc + Vector2(3, -5), hc + Vector2(10, -6), Color(0.95, 0.95, 0.96), 3.0)  # Brow
	c.draw_line(hc + Vector2(5, -2), hc + Vector2(9, -2), BLACK, 1.5)                  # Squinting eye
	c.draw_circle(hc + Vector2(12, 1), 2.4, SKIN_OLD.darkened(0.1))                     # Nose


## THE SHOPKEEPER: stout and cheerful - a flat cap, a big moustache, sleeves rolled up and a
## green-and-white striped apron.
static func shopkeeper(c: CanvasItem, t: float) -> void:
	var br := sin(t * 2.2) * 1.0
	var pants := Color(0.30, 0.26, 0.24)
	for d: float in [-1.0, 1.0]:
		FighterArt.limb(c, Vector2(d * 8.0, -44), Vector2(d * 9.0, -2), 10.0, pants, BLACK, pants.lightened(0.15))
	var shirt := Color(0.82, 0.55, 0.40)
	var belly := FighterArt.rrect_points(Rect2(-20, -94 + br, 40, 52), 16.0)
	c.draw_colored_polygon(belly, shirt)
	FighterArt.outline(c, belly, 2.5)
	# Striped apron
	var apron := Rect2(-14, -78 + br, 30, 40)
	c.draw_rect(apron, Color(0.92, 0.94, 0.90))
	for k in 5:
		c.draw_rect(Rect2(apron.position.x + float(k) * 6.0, apron.position.y, 3, apron.size.y), Color(0.28, 0.55, 0.32))
	c.draw_rect(apron, BLACK, false, 2.0)
	c.draw_line(Vector2(-12, -78 + br), Vector2(-4, -94 + br), BLACK, 1.5)            # Apron strings
	c.draw_line(Vector2(14, -78 + br), Vector2(6, -94 + br), BLACK, 1.5)
	# Rolled-up sleeves, arms on the hips
	for d: float in [-1.0, 1.0]:
		FighterArt.limb(c, Vector2(d * 18.0, -88 + br), Vector2(d * 26.0, -66), 8.0, shirt, BLACK, shirt.lightened(0.15))
		FighterArt.limb(c, Vector2(d * 26.0, -66), Vector2(d * 16.0, -54), 7.0, SKIN, BLACK, SKIN.lightened(0.1))
	# Head: round face, rosy cheeks, the moustache, a flat cap
	var hc := Vector2(2, -108 + br)
	FighterArt.ball(c, hc, 14.0, SKIN, SKIN.darkened(0.15), SKIN.lightened(0.1))
	c.draw_circle(hc + Vector2(8, 3), 3.5, Color(0.95, 0.55, 0.50, 0.6))
	c.draw_circle(hc + Vector2(6, -3), 1.8, BLACK)
	var stache := PackedVector2Array([hc + Vector2(2, 5), hc + Vector2(16, 4), hc + Vector2(18, 9), hc + Vector2(9, 7), hc + Vector2(3, 10)])
	c.draw_colored_polygon(stache, Color(0.35, 0.22, 0.12))
	c.draw_arc(hc + Vector2(8, 9), 4.0, 0.2, 2.6, 6, BLACK, 1.5)                         # The smile
	var cap := PackedVector2Array([hc + Vector2(-15, -6), hc + Vector2(-12, -15), hc + Vector2(4, -17), hc + Vector2(16, -11), hc + Vector2(22, -8), hc + Vector2(-14, -4)])
	c.draw_colored_polygon(cap, Color(0.38, 0.34, 0.30))
	FighterArt.outline(c, cap, 2.0)


## THE YOUNGEST GUARD: a skinny boy in a helmet two sizes too big, a spear much taller than him,
## and a blue tabard with the golden SUN of the town's faith.
static func young_guard(c: CanvasItem, t: float) -> void:
	var br := sin(t * 2.6) * 0.8
	var pants := Color(0.34, 0.30, 0.26)
	for d: float in [-1.0, 1.0]:
		FighterArt.limb(c, Vector2(d * 5.0, -46), Vector2(d * 6.0, -2), 7.0, pants, BLACK, pants.lightened(0.15))
		c.draw_rect(Rect2(d * 6.0 - 4.0, -8, 11, 8), WOOD_DARK)
	# Spear (behind the near arm)
	c.draw_line(Vector2(20, 2), Vector2(20, -150), BLACK, 6.0)
	c.draw_line(Vector2(20, 2), Vector2(20, -150), WOOD, 3.5)
	var tip := PackedVector2Array([Vector2(15, -150), Vector2(25, -150), Vector2(20, -170)])
	c.draw_colored_polygon(tip, IRON.lightened(0.3))
	FighterArt.outline(c, tip, 2.0)
	# Tabard with the Sun
	var tab := PackedVector2Array([Vector2(-12, -90 + br), Vector2(12, -90 + br), Vector2(13, -40), Vector2(-13, -40)])
	c.draw_colored_polygon(tab, SUN_BLUE)
	FighterArt.outline(c, tab, 2.5)
	var sc := Vector2(0, -68 + br)
	for i in 8:
		var a := TAU * float(i) / 8.0
		c.draw_line(sc + Vector2.from_angle(a) * 6.0, sc + Vector2.from_angle(a) * 10.0, SUN_GOLD, 2.0)
	c.draw_circle(sc, 5.0, SUN_GOLD)
	c.draw_rect(Rect2(-12, -46, 24, 4), WOOD_DARK)                                     # Belt
	# Arms (near one holds the spear)
	FighterArt.limb(c, Vector2(-11, -86 + br), Vector2(-14, -56), 5.5, SUN_BLUE, BLACK, SUN_BLUE.lightened(0.2))
	FighterArt.limb(c, Vector2(11, -86 + br), Vector2(19, -64), 5.5, SUN_BLUE, BLACK, SUN_BLUE.lightened(0.2))
	c.draw_circle(Vector2(20, -64), 4.0, SKIN)
	# Head + the far-too-big helmet sliding over his eyes
	var hc := Vector2(1, -102 + br)
	FighterArt.ball(c, hc, 11.0, SKIN, SKIN.darkened(0.15), SKIN.lightened(0.1))
	c.draw_circle(hc + Vector2(6, 2), 1.6, BLACK)
	c.draw_arc(hc + Vector2(6, 6), 3.0, 0.3, 2.4, 6, BLACK, 1.2)
	var helm := PackedVector2Array([hc + Vector2(-17, -1), hc + Vector2(-14, -16), hc + Vector2(0, -22), hc + Vector2(14, -16), hc + Vector2(18, -1)])
	c.draw_colored_polygon(helm, IRON)
	c.draw_line(hc + Vector2(-19, -1), hc + Vector2(20, -1), IRON.darkened(0.3), 4.0)  # Brim
	FighterArt.outline(c, helm, 2.5)
	c.draw_line(hc + Vector2(0, -22), hc + Vector2(0, -28), SUN_GOLD, 3.0)             # A tiny golden plume


# ============================================================
# THE DEAD TOWN (if you woke him): a charred body on the ground
# ============================================================
static func dead_body(c: CanvasItem, look: int) -> void:
	var col := Color(0.16, 0.12, 0.11)
	var flip := -1.0 if look % 2 == 0 else 1.0
	var body := PackedVector2Array([Vector2(-34 * flip, -4), Vector2(-30 * flip, -14), Vector2(10 * flip, -16), Vector2(26 * flip, -12), Vector2(30 * flip, -3)])
	c.draw_colored_polygon(body, col)
	FighterArt.outline(c, body, 2.0)
	c.draw_circle(Vector2(36 * flip, -9), 8.0, col)
	c.draw_line(Vector2(0, -14), Vector2(8 * flip, -26), col, 5.0)                     # A reaching arm
	c.draw_circle(Vector2(-10 * flip, -6), 6.0, Color(0.9, 0.3, 0.05, 0.35))           # Embers
	c.draw_colored_polygon(EnemyArt.ellipse_points(Vector2(0, 0), 44.0, 5.0, 12), Color(BLOOD.r, BLOOD.g, BLOOD.b, 0.5))


# ============================================================
# THE NIGHTMARE LORD, asleep in his chains / carried on your shoulder
# ============================================================
## Asleep, slumped against the rock, chained at the wrists and the chest (chains = false: on the floor).
static func sleeping_lord(c: CanvasItem, t: float, chains: bool, on_floor: bool) -> void:
	var br := sin(t * 0.9) * 1.5
	if on_floor:
		# Lying on the cave floor (fallen, still asleep)
		c.draw_set_transform(Vector2(-60, -10), -PI * 0.5, Vector2(0.95, 0.95))
		FireLordArt.draw_portrait(c, 0.0)
		c.draw_set_transform(Vector2.ZERO, 0.0, Vector2.ONE)
	else:
		c.draw_set_transform(Vector2(0, br * 0.5), 0.06, Vector2(1.0, 1.0 + br * 0.004))
		FireLordArt.draw_portrait(c, 0.0)
		c.draw_set_transform(Vector2.ZERO, 0.0, Vector2.ONE)
	if chains:
		for p: Array in [[Vector2(-60, -150), Vector2(-14, -84)], [Vector2(70, -150), Vector2(18, -84)], [Vector2(-70, -70), Vector2(70, -74)]]:
			_chain(c, p[0], p[1])
		for ap: Vector2 in [Vector2(-60, -150), Vector2(70, -150), Vector2(-70, -70), Vector2(70, -74)]:
			c.draw_circle(ap, 7.0, BLACK)
			c.draw_circle(ap, 5.0, IRON)
	# Zzz and smoke from his nose
	var zt := fmod(t * 0.5, 1.0)
	var zp := Vector2(30, -140) + Vector2(14, -40) * zt
	FighterArt.label(c, zp, "z", int(14 + 10 * zt), Color(1, 1, 1, 1.0 - zt))
	var st := fmod(t * 0.35, 1.0)
	c.draw_circle(Vector2(24, -112) + Vector2(10, -30) * st, 4.0 + 8.0 * st, Color(0.4, 0.4, 0.4, 0.4 * (1.0 - st)))


static func _chain(c: CanvasItem, a: Vector2, b: Vector2) -> void:
	var n := int(a.distance_to(b) / 9.0)
	for i in n:
		var p := a.lerp(b, (float(i) + 0.5) / float(maxi(n, 1)))
		var vert := i % 2 == 0
		var r := Rect2(p - (Vector2(3, 5) if vert else Vector2(5, 3)), Vector2(6, 10) if vert else Vector2(10, 6))
		c.draw_rect(r.grow(1.0), BLACK)
		c.draw_rect(r, IRON)


## Lying over your shoulders (the "carried" choice). Drawn in the carrier's space (feet = 0, 0).
static func carried_lord(c: CanvasItem, t: float, facing: int) -> void:
	c.draw_set_transform(Vector2(-58.0 * float(facing), -128 + sin(t * 4.0) * 1.0), PI * 0.5 * float(facing), Vector2(0.8 * float(facing), 0.8))
	FireLordArt.draw_portrait(c, 0.0)
	c.draw_set_transform(Vector2.ZERO, 0.0, Vector2.ONE)


# ============================================================
# PROPS
# ============================================================
## A timber-and-plaster house. burning = red flames on the roof, black windows.
static func house(c: CanvasItem, w: float, h: float, v: int, burning: bool, t: float) -> void:
	var wall := Rect2(-w * 0.5, -h, w, h)
	c.draw_rect(wall, PLASTER.darkened(0.15 * float(v % 3)) if not burning else Color(0.25, 0.18, 0.15))
	for k in 3:                                                         # Timber frame
		var x := wall.position.x + wall.size.x * float(k) / 2.0
		c.draw_line(Vector2(x, -h), Vector2(x, 0), WOOD_DARK, 6.0)
	c.draw_line(Vector2(-w * 0.5, -h * 0.5), Vector2(w * 0.5, -h * 0.5), WOOD_DARK, 5.0)
	c.draw_rect(wall, BLACK, false, 3.0)
	var roof := PackedVector2Array([Vector2(-w * 0.5 - 18, -h), Vector2(0, -h - w * 0.45), Vector2(w * 0.5 + 18, -h)])
	c.draw_colored_polygon(roof, ROOF.darkened(0.1 * float(v % 2)) if not burning else Color(0.12, 0.08, 0.07))
	FighterArt.outline(c, roof, 3.0)
	for k in 2:                                                         # Windows (warm light / dark)
		var wr := Rect2(-w * 0.5 + w * (0.2 + 0.45 * float(k)), -h * 0.85, w * 0.16, h * 0.22)
		c.draw_rect(wr, Color(1.0, 0.82, 0.45) if not burning else Color(0.05, 0.03, 0.03))
		c.draw_rect(wr, BLACK, false, 2.0)
	c.draw_rect(Rect2(-12, -46, 24, 46), WOOD)                         # Door
	c.draw_rect(Rect2(-12, -46, 24, 46), BLACK, false, 2.0)
	if burning:
		flames(c, Vector2(0, -h - w * 0.2), w * 0.9, t, float(v))
		flames(c, Vector2(-w * 0.3, -h * 0.85), w * 0.3, t, float(v) + 3.0)


## Red flames (the burning town), centred at p, `width` wide.
static func flames(c: CanvasItem, p: Vector2, width: float, t: float, seed_v: float) -> void:
	var n := maxi(int(width / 18.0), 2)
	for i in n:
		var x := p.x - width * 0.5 + width * float(i) / float(n - 1)
		var hgt := 40.0 + 28.0 * (0.5 + 0.5 * sin(t * 7.0 + float(i) * 1.7 + seed_v))
		c.draw_colored_polygon(PackedVector2Array([Vector2(x - 12, p.y), Vector2(x + 12, p.y), Vector2(x + 2, p.y - hgt)]), Color(0.85, 0.08, 0.04, 0.85))
		c.draw_colored_polygon(PackedVector2Array([Vector2(x - 6, p.y), Vector2(x + 6, p.y), Vector2(x + 1, p.y - hgt * 0.55)]), Color(1.0, 0.45, 0.10, 0.9))


## The town's wooden wall + the LEFT GATE (its border).
static func gate(c: CanvasItem, t: float) -> void:
	for k in 9:                                                         # Palisade stakes
		var x := -150.0 + float(k) * 36.0
		if absf(x) < 40.0:
			continue
		var stake := PackedVector2Array([Vector2(x - 14, 0), Vector2(x + 14, 0), Vector2(x + 14, -190), Vector2(x, -214), Vector2(x - 14, -190)])
		c.draw_colored_polygon(stake, WOOD if k % 2 == 0 else WOOD.darkened(0.12))
		FighterArt.outline(c, stake, 3.0)
	c.draw_line(Vector2(-160, -150), Vector2(160, -150), WOOD_DARK, 8.0)
	# The open gateway arch with the Sun above it
	c.draw_line(Vector2(-40, 0), Vector2(-40, -230), WOOD_DARK, 12.0)
	c.draw_line(Vector2(40, 0), Vector2(40, -230), WOOD_DARK, 12.0)
	c.draw_line(Vector2(-52, -230), Vector2(52, -230), WOOD_DARK, 12.0)
	var sc := Vector2(0, -262)
	for i in 12:
		var a := TAU * float(i) / 12.0 + t * 0.2
		c.draw_line(sc + Vector2.from_angle(a) * 16.0, sc + Vector2.from_angle(a) * 26.0, SUN_GOLD, 4.0)
	c.draw_circle(sc, 15.0, BLACK)
	c.draw_circle(sc, 13.0, SUN_GOLD)


## THE SUN SHRINE: a stone pillar with a golden disc; candles and round loaves as offerings.
static func shrine(c: CanvasItem, t: float, dead: bool) -> void:
	c.draw_rect(Rect2(-60, -20, 120, 20), Color(0.55, 0.52, 0.48))
	c.draw_rect(Rect2(-60, -20, 120, 20), BLACK, false, 3.0)
	c.draw_rect(Rect2(-18, -170, 36, 150), Color(0.66, 0.63, 0.58))
	c.draw_rect(Rect2(-18, -170, 36, 150), BLACK, false, 3.0)
	var sc := Vector2(0, -205)
	if not dead:
		c.draw_circle(sc, 60.0 + 4.0 * sin(t * 1.5), Color(1.0, 0.85, 0.4, 0.12))
	for i in 16:
		var a := TAU * float(i) / 16.0
		c.draw_line(sc + Vector2.from_angle(a) * 30.0, sc + Vector2.from_angle(a) * (44.0 if i % 2 == 0 else 38.0), SUN_GOLD.darkened(0.5 if dead else 0.0), 5.0)
	c.draw_circle(sc, 31.0, BLACK)
	c.draw_circle(sc, 28.0, SUN_GOLD.darkened(0.5 if dead else 0.0))
	for k in 4:                                                         # Offerings
		var ox := -48.0 + float(k) * 30.0
		if k % 2 == 0:
			c.draw_circle(Vector2(ox, -26), 7.0, Color(0.80, 0.55, 0.28))
		else:
			c.draw_rect(Rect2(ox - 3, -36, 6, 14), Color(0.95, 0.92, 0.85))
			if not dead:
				c.draw_circle(Vector2(ox, -40), 3.0 + sin(t * 9.0 + float(k)), Color(1.0, 0.7, 0.2))


## The shopkeeper's market stall.
static func stall(c: CanvasItem) -> void:
	c.draw_rect(Rect2(-80, -60, 160, 60), WOOD)
	c.draw_rect(Rect2(-80, -60, 160, 60), BLACK, false, 3.0)
	for k in 4:
		var x := -66.0 + float(k) * 40.0
		c.draw_circle(Vector2(x, -68), 9.0, [Color(0.80, 0.55, 0.28), Color(0.85, 0.25, 0.2), Color(0.95, 0.85, 0.4), Color(0.4, 0.65, 0.3)][k])
	c.draw_line(Vector2(-84, 0), Vector2(-84, -150), WOOD_DARK, 6.0)
	c.draw_line(Vector2(84, 0), Vector2(84, -150), WOOD_DARK, 6.0)
	for k in 6:                                                         # Striped awning
		var x0 := -96.0 + float(k) * 32.0
		c.draw_colored_polygon(PackedVector2Array([Vector2(x0, -150), Vector2(x0 + 32, -150), Vector2(x0 + 32, -128), Vector2(x0, -128)]), Color(0.28, 0.55, 0.32) if k % 2 == 0 else Color(0.92, 0.94, 0.90))
	c.draw_rect(Rect2(-96, -150, 192, 22), BLACK, false, 3.0)


## The CAVE MOUTH outside the town (a dark opening in a rock face).
static func cave_mouth(c: CanvasItem, t: float) -> void:
	var rock := PackedVector2Array([Vector2(-260, 0), Vector2(-230, -260), Vector2(-120, -380), Vector2(40, -400), Vector2(190, -320), Vector2(260, -150), Vector2(280, 0)])
	c.draw_colored_polygon(rock, Color(0.30, 0.28, 0.27))
	FighterArt.outline(c, rock, 4.0)
	var mouth := PackedVector2Array([Vector2(-90, 0), Vector2(-80, -130), Vector2(-30, -190), Vector2(40, -196), Vector2(90, -140), Vector2(100, 0)])
	c.draw_colored_polygon(mouth, Color(0.02, 0.01, 0.01))
	FighterArt.outline(c, mouth, 3.0)
	c.draw_circle(Vector2(0, -60), 30.0, Color(0.45, 0.05, 0.03, 0.15 + 0.08 * sin(t * 1.2)))   # A faint red glow inside


## Inside the cave: an old BLOOD stain (floor or wall) / a heap of CHARCOAL / scorched bones.
static func blood(c: CanvasItem, r: float, wall: bool, v: int) -> void:
	var pts := PackedVector2Array()
	for i in 14:
		var a := TAU * float(i) / 14.0
		var rr := r * (0.7 + 0.3 * sin(float(i) * 2.7 + float(v)))
		pts.append(Vector2(cos(a) * rr, sin(a) * rr * (1.0 if wall else 0.18)))
	c.draw_colored_polygon(pts, Color(BLOOD.r, BLOOD.g, BLOOD.b, 0.85))
	if wall:
		for k in 3:                                                     # Old drips
			var dx := (float(k) - 1.0) * r * 0.4
			c.draw_line(Vector2(dx, r * 0.4), Vector2(dx, r * (0.9 + 0.3 * float(k))), Color(BLOOD.r, BLOOD.g, BLOOD.b, 0.8), 3.0)


static func charcoal(c: CanvasItem, w: float, v: int) -> void:
	for k in int(w / 14.0):
		var x := -w * 0.5 + float(k) * 14.0
		var hh := 8.0 + 10.0 * (0.5 + 0.5 * sin(float(k) * 1.9 + float(v)))
		c.draw_colored_polygon(PackedVector2Array([Vector2(x - 9, 0), Vector2(x + 9, 0), Vector2(x + 4, -hh), Vector2(x - 5, -hh * 0.8)]), CHARCOAL)
	c.draw_colored_polygon(EnemyArt.ellipse_points(Vector2.ZERO, w * 0.55, 4.0, 12), ASH)


static func bones(c: CanvasItem, v: int) -> void:
	var bone := Color(0.55, 0.50, 0.44)
	c.draw_line(Vector2(-20, -3), Vector2(16, -6), bone, 5.0)
	c.draw_line(Vector2(-6, -2), Vector2(8, -14), bone, 4.0)
	c.draw_circle(Vector2(24 if v % 2 == 0 else -26, -9), 8.0, bone.darkened(0.3))
	c.draw_circle(Vector2(26 if v % 2 == 0 else -24, -10), 2.0, BLACK)
