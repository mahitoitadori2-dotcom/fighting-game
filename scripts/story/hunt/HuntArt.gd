class_name HuntArt
extends RefCounted
## THE HUNT OF A NIGHTMARE (levels 82-110, by the user 2026-11-22) - shared drawing.
##
## THE NIGHTMARE BASEPLATE (the user's rule): a RED CREATURE + a CLOAK in a shade of red + a CERAMIC
## MASK of a geometric shape. Every Troupe member is built from it:
##   Troupe Follower        the baseplate (mask: circle / triangle / square / diamond / hexagon / pentagon)
##   Nightmare Trader       the baseplate + a sword + an ancient weight
##   Aristocratic Nightmare FLOATS, and its main shade is a really bright red (not dark red)
##   The Troupe's Jester    a bigger baseplate, THIN legs, a jester cap, flaming red balls
##   Musician of Nightmares a buffer, bigger but NOT taller baseplate + instruments
##   Head Heavy Guards      bigger versions of the Musician + medieval weapons
## All drawn facing RIGHT, origin = feet. body(...) returns the points held items attach to.

const SKIN := Color(0.62, 0.05, 0.06)
const SKIN_SHADE := Color(0.36, 0.02, 0.03)
const CLOAK := Color(0.42, 0.03, 0.05)
const CLOAK_SHADE := Color(0.24, 0.01, 0.03)
const CERAMIC := Color(0.93, 0.90, 0.84)
const CERAMIC_SHADE := Color(0.74, 0.70, 0.64)
const GLOW := Color(1.0, 0.18, 0.12)
const BRIGHT := Color(1.0, 0.12, 0.10)              # The Aristocrats' really bright red
const BRIGHT_SHADE := Color(0.86, 0.04, 0.06)
const GOLD := Color(0.95, 0.76, 0.30)
const STEEL := Color(0.78, 0.80, 0.84)
const STEEL_DARK := Color(0.40, 0.42, 0.46)
const WOOD := Color(0.42, 0.26, 0.14)
const FLAME := Color(1.0, 0.16, 0.06)
const FLAME_HOT := Color(1.0, 0.72, 0.30)
const BLACK := Color(0, 0, 0)
const MASKS := ["circle", "triangle", "square", "diamond", "hexagon", "pentagon"]


## The baseplate. cfg keys (all optional):
##   k (size), wide (x stretch: buffer, not taller), leg (leg thickness), float (no legs: hovers),
##   skin / skin_shade / cloak / cloak_shade, mask (shape), hood (true), arm_f / arm_b (0..1 swing)
static func body(c: CanvasItem, s: Dictionary, cfg: Dictionary) -> Dictionary:
	var k: float = cfg.get("k", 1.0)
	var wide: float = cfg.get("wide", 1.0)
	var leg_w: float = cfg.get("leg", 7.0)
	var floating: bool = cfg.get("float", false)
	var skin: Color = cfg.get("skin", SKIN)
	var skin_shade: Color = cfg.get("skin_shade", SKIN_SHADE)
	var cloak: Color = cfg.get("cloak", CLOAK)
	var cloak_shade: Color = cfg.get("cloak_shade", CLOAK_SHADE)
	var mask: String = cfg.get("mask", "circle")
	var arm_f: float = cfg.get("arm_f", 0.0)
	var arm_b: float = cfg.get("arm_b", 0.0)
	var t: float = s.get("t", 0.0)
	var moving: bool = s.get("moving", false)
	var dead: bool = s.get("dead", false)
	var sway := sin(t * (10.0 if moving else 2.2)) * (1.0 if moving else 0.25)
	var lift := (24.0 + sin(t * 2.4) * 6.0) * k if floating else 0.0
	var hip := Vector2(0, -42.0 * k - lift)
	var neck := Vector2(2.0 * k, -88.0 * k - lift)
	var sh_w := 15.0 * k * wide
	# --- Legs (or a trailing wisp when floating) ---
	if floating:
		var wisp := PackedVector2Array([hip + Vector2(-12, 0) * k * wide, hip + Vector2(12, 0) * k * wide, Vector2(sin(t * 3.0) * 8.0, -8.0 * k)])
		c.draw_colored_polygon(wisp, Color(cloak.r, cloak.g, cloak.b, 0.7))
	else:
		for side: float in [-1.0, 1.0]:
			var step := sway * side * 16.0 * k
			var knee := hip + Vector2(side * 5.0 * k * wide + step * 0.6, 21.0 * k)
			var foot := Vector2(side * 7.0 * k * wide + step, 0.0)
			c.draw_line(hip + Vector2(side * 5.0 * k * wide, 0), knee, BLACK, leg_w * k + 4.0)
			c.draw_line(knee, foot, BLACK, leg_w * k + 4.0)
			c.draw_line(hip + Vector2(side * 5.0 * k * wide, 0), knee, skin_shade if side < 0.0 else skin, leg_w * k)
			c.draw_line(knee, foot, skin_shade if side < 0.0 else skin, leg_w * k)
			var shoe := EnemyArt.ellipse_points(foot + Vector2(3.0 * k, -2.0 * k), 7.0 * k, 4.0 * k, 10)
			c.draw_colored_polygon(shoe, skin_shade)
			FighterArt.outline(c, shoe, 2.0)
	# --- Back arm ---
	var sh_b := neck + Vector2(-sh_w * 0.6, 8.0 * k)
	var hand_b := sh_b + Vector2(-8.0 * k + 30.0 * k * arm_b, 34.0 * k - 26.0 * k * arm_b)
	_limb(c, sh_b, hand_b, 7.0 * k * sqrt(wide), skin_shade)
	# --- Torso ---
	var torso := PackedVector2Array([neck + Vector2(-sh_w, 6.0 * k), neck + Vector2(sh_w, 6.0 * k),
		hip + Vector2(sh_w * 0.75, 0), hip + Vector2(-sh_w * 0.75, 0)])
	c.draw_colored_polygon(torso, skin)
	FighterArt.outline(c, torso, 3.0)
	# --- The CLOAK: hood behind the head, falling from the shoulders past the hips, ragged hem ---
	var hem_y := hip.y + 26.0 * k
	# (A simple outline: shoulder -> neck -> down to the hem -> along the ragged hem -> back up)
	var cl := PackedVector2Array([neck + Vector2(-sh_w - 3.0 * k, 2.0 * k), neck + Vector2(-4.0 * k, -2.0 * k)])
	var n := 7
	for i in range(n, -1, -1):
		var fx := lerpf(-sh_w - 8.0 * k, -2.0 * k, float(i) / float(n))
		cl.append(Vector2(fx + sway * 4.0 * k, hem_y + (6.0 * k if i % 2 == 0 else -4.0 * k)))
	c.draw_colored_polygon(cl, cloak)
	FighterArt.outline(c, cl, 2.5)
	var drape := PackedVector2Array([neck + Vector2(-sh_w - 2.0 * k, 4.0 * k), neck + Vector2(sh_w + 2.0 * k, 4.0 * k), neck + Vector2(sh_w * 0.8, 16.0 * k), neck + Vector2(-sh_w * 0.9, 18.0 * k)])
	c.draw_colored_polygon(drape, cloak_shade)
	FighterArt.outline(c, drape, 2.0)
	# --- Head + hood + CERAMIC MASK ---
	var head := neck + Vector2(2.0 * k, -14.0 * k + sin(t * 2.0) * 1.0)
	if cfg.get("hood", true):
		var hood := EnemyArt.ellipse_points(head + Vector2(-3.0 * k, -1.0 * k), 17.0 * k, 18.0 * k, 16)
		c.draw_colored_polygon(hood, cloak_shade)
		FighterArt.outline(c, hood, 2.5)
	c.draw_circle(head, 12.0 * k, skin)
	ceramic_mask(c, head + Vector2(3.0 * k, 0), 13.0 * k, mask, t, dead)
	# --- Front arm ---
	var sh_f := neck + Vector2(sh_w * 0.6, 8.0 * k)
	var hand_f := sh_f + Vector2(10.0 * k + 30.0 * k * arm_f, 32.0 * k - 30.0 * k * arm_f)
	_limb(c, sh_f, hand_f, 7.0 * k * sqrt(wide), skin)
	return {"hand_f": hand_f, "hand_b": hand_b, "head": head, "neck": neck, "hip": hip, "k": k, "wide": wide}


static func _limb(c: CanvasItem, a: Vector2, b: Vector2, w: float, col: Color) -> void:
	var elbow := a.lerp(b, 0.5) + Vector2(-4.0, 4.0)
	c.draw_line(a, elbow, BLACK, w + 4.0)
	c.draw_line(elbow, b, BLACK, w + 4.0)
	c.draw_line(a, elbow, col, w)
	c.draw_line(elbow, b, col, w)
	c.draw_circle(b, w * 0.75, col)
	c.draw_arc(b, w * 0.75, 0.0, TAU, 10, BLACK, 2.0)


## A CERAMIC MASK of a geometric shape: off-white glaze, a hairline crack, two eye slits glowing red.
static func ceramic_mask(c: CanvasItem, ctr: Vector2, r: float, shape: String, t: float, dead: bool = false) -> void:
	var pts := shape_points(ctr, r, shape)
	c.draw_colored_polygon(pts, CERAMIC)
	c.draw_arc(ctr + Vector2(0, r * 0.1), r * 0.6, 0.3, PI - 0.3, 10, Color(CERAMIC_SHADE.r, CERAMIC_SHADE.g, CERAMIC_SHADE.b, 0.8), r * 0.25)   # Glaze shade
	FighterArt.outline(c, pts, 2.5)
	c.draw_polyline(PackedVector2Array([ctr + Vector2(-r * 0.2, -r * 0.8), ctr + Vector2(-r * 0.05, -r * 0.35), ctr + Vector2(-r * 0.28, 0.0)]), Color(0.3, 0.25, 0.22), 1.2)
	var glow := 0.0 if dead else 0.7 + 0.3 * sin(t * 6.0)
	for ex: float in [-0.38, 0.32]:
		var e := ctr + Vector2(r * ex, -r * 0.1)
		c.draw_line(e + Vector2(-r * 0.16, 0), e + Vector2(r * 0.16, 0), BLACK, r * 0.2)
		if glow > 0.0:
			c.draw_line(e + Vector2(-r * 0.1, 0), e + Vector2(r * 0.1, 0), Color(GLOW.r, GLOW.g, GLOW.b, glow), r * 0.09)


static func shape_points(ctr: Vector2, r: float, shape: String) -> PackedVector2Array:
	var pts := PackedVector2Array()
	match shape:
		"triangle":
			for i in 3:
				pts.append(ctr + Vector2.from_angle(-PI * 0.5 + TAU * float(i) / 3.0) * r * 1.15)
		"square":
			pts = PackedVector2Array([ctr + Vector2(-r, -r), ctr + Vector2(r, -r), ctr + Vector2(r, r), ctr + Vector2(-r, r)])
			for i in pts.size():
				pts[i] = ctr + (pts[i] - ctr) * 0.85
		"diamond":
			pts = PackedVector2Array([ctr + Vector2(0, -r * 1.2), ctr + Vector2(r, 0), ctr + Vector2(0, r * 1.2), ctr + Vector2(-r, 0)])
		"hexagon":
			for i in 6:
				pts.append(ctr + Vector2.from_angle(TAU * float(i) / 6.0) * r)
		"pentagon":
			for i in 5:
				pts.append(ctr + Vector2.from_angle(-PI * 0.5 + TAU * float(i) / 5.0) * r * 1.05)
		_:
			pts = EnemyArt.ellipse_points(ctr, r, r, 18)
	return pts


## Red flames licking up from a point (thrown burning weapons, the Jester's balls).
static func flames(c: CanvasItem, p: Vector2, r: float, t: float, n: int = 5) -> void:
	for i in n:
		var a := -PI * 0.5 + (float(i) - float(n - 1) * 0.5) * 0.45
		var h := r * (1.4 + 0.5 * sin(t * 13.0 + float(i) * 1.7))
		var base := p + Vector2(cos(a + PI * 0.5) * r * 0.5, 0)
		var tri := PackedVector2Array([base + Vector2(-r * 0.35, 0), base + Vector2(r * 0.35, 0), base + Vector2.from_angle(a) * h])
		c.draw_colored_polygon(tri, FLAME if i % 2 == 0 else FLAME.lightened(0.15))
	c.draw_circle(p, r * 0.45, FLAME_HOT)


# ============================================================
# MEDIEVAL WEAPONS (the user's list, 2026-11-22 - memory: ub-weapons-list)
# ============================================================
## The weapons the Head Heavy Nightmare Guards pick up: name -> shape family.
## Plain weapon types from the list (no named weapons from other games).
const WEAPONS := {
	"SICKLE": "sickle", "DAGGER": "dagger", "GREAT KNIFE": "dagger", "WAKIZASHI": "katana", "KRIS": "dagger",
	"BROADSWORD": "sword", "LONGSWORD": "sword", "STRAIGHT SWORD": "sword", "SHORT SWORD": "sword",
	"KNIGHT'S SWORD": "sword", "GREATSWORD": "greatsword", "BASTARD SWORD": "greatsword", "FLAMBERGE": "greatsword",
	"ZWEIHANDER": "greatsword", "RAPIER": "thrust", "ESTOC": "thrust", "EPEE": "thrust",
	"CURVED SWORD": "curved", "FALCHION": "curved", "GROSSMESSER": "curved", "SCIMITAR": "curved", "SHAMSHIR": "curved",
	"SHOTEL": "shotel", "CLEAVER": "cleaver", "KATANA": "katana", "TWINBLADE": "twinblade",
	"BATTLE AXE": "axe", "AXE": "axe", "HATCHET": "axe", "HAND AXE": "axe", "HIGHLAND AXE": "axe", "CRESCENT AXE": "greataxe",
	"GREATAXE": "greataxe", "GREAT CLEAVER": "greataxe", "LONGHAFT AXE": "greataxe", "ANCHOR": "anchor",
	"CLUB": "club", "CURVED CLUB": "club", "SPIKED CLUB": "club", "STONE CLUB": "club", "GREATCLUB": "club", "LARGE CLUB": "club",
	"HAMMER": "hammer", "WARPICK": "pick", "PICKAXE": "pick", "BATTLE HAMMER": "hammer", "GREAT HAMMER": "hammer", "BRICK HAMMER": "hammer",
	"MACE": "mace", "GREAT MACE": "mace", "MORNING STAR": "mace", "FLAIL": "flail", "CHAINLINK FLAIL": "flail",
	"HALBERD": "halberd", "GLAIVE": "glaive", "LUCERNE": "halberd", "PARTISAN": "spear", "PIKE": "spear",
	"SPEAR": "spear", "SHORT SPEAR": "spear", "SPIKED SPEAR": "spear", "WAR SPEAR": "spear", "LANCE": "lance",
	"SCYTHE": "scythe", "WAR SICKLE": "scythe", "SAW": "saw", "MILITIA SAW": "saw",
}


static func weapon_names() -> Array:
	return WEAPONS.keys()


## Draws a weapon from its grip along angle `ang` (0 = pointing right). burning = on fire.
static func weapon(c: CanvasItem, name_or_family: String, grip: Vector2, ang: float, k: float, t: float, burning: bool = false) -> void:
	var fam: String = String(WEAPONS.get(name_or_family, name_or_family))
	var d := Vector2.from_angle(ang)
	var nv := d.orthogonal()
	var tip := grip
	match fam:
		"dagger", "sickle":
			tip = _blade(c, grip, d, nv, k, 10.0, 34.0, 5.0, fam == "sickle")
		"sword", "thrust", "katana", "curved", "shotel", "cleaver", "saw":
			var blen: float = {"sword": 62.0, "thrust": 70.0, "katana": 66.0, "curved": 58.0, "shotel": 56.0, "cleaver": 46.0, "saw": 56.0}[fam]
			var bw: float = {"sword": 7.0, "thrust": 3.5, "katana": 5.0, "curved": 8.0, "shotel": 5.0, "cleaver": 15.0, "saw": 12.0}[fam]
			tip = _blade(c, grip, d, nv, k, 14.0, blen, bw, fam in ["curved", "shotel", "katana"])
			if fam == "saw":
				for i in 7:
					var p := grip + d * (18.0 + float(i) * 7.0) * k + nv * bw * k
					c.draw_colored_polygon(PackedVector2Array([p, p + d * 4.0 * k, p + nv * 5.0 * k]), STEEL_DARK)
		"greatsword":
			tip = _blade(c, grip, d, nv, k, 20.0, 92.0, 11.0, false)
		"twinblade":
			tip = _blade(c, grip, d, nv, k, 10.0, 50.0, 6.0, false)
			_blade(c, grip, -d, -nv, k, 10.0, 50.0, 6.0, false)
		"axe", "greataxe", "anchor", "pick":
			var hl := 60.0 if fam == "axe" else 88.0
			tip = grip + d * hl * k
			_haft(c, grip - d * 8.0 * k, tip, k)
			var hb := tip - d * 8.0 * k
			var hs := 1.0 if fam == "axe" else 1.6
			var head := PackedVector2Array([hb - d * 12.0 * k * hs, hb + nv * 22.0 * k * hs - d * 16.0 * k * hs, hb + nv * 26.0 * k * hs + d * 8.0 * k, hb + d * 6.0 * k])
			if fam == "pick":
				head = PackedVector2Array([hb - d * 4.0 * k, hb + nv * 30.0 * k - d * 10.0 * k, hb + d * 4.0 * k])
			if fam == "anchor":
				head = PackedVector2Array([hb - nv * 24.0 * k, hb - nv * 30.0 * k - d * 16.0 * k, hb, hb + nv * 30.0 * k - d * 16.0 * k, hb + nv * 24.0 * k, hb + d * 10.0 * k])
			c.draw_colored_polygon(head, STEEL)
			FighterArt.outline(c, head, 2.5)
		"club", "hammer", "mace", "flail":
			var hl2 := 52.0 if fam != "flail" else 30.0
			var end := grip + d * hl2 * k
			_haft(c, grip - d * 6.0 * k, end, k)
			var hc := end
			if fam == "flail":
				hc = end + Vector2(0, 26.0 * k) + d * 10.0 * k
				c.draw_line(end, hc, STEEL_DARK, 2.5 * k)
			match fam:
				"club":
					var clb := EnemyArt.ellipse_points(end - d * 10.0 * k, 22.0 * k, 11.0 * k, 12)
					for i in clb.size():
						clb[i] = end - d * 10.0 * k + (clb[i] - (end - d * 10.0 * k)).rotated(ang)
					c.draw_colored_polygon(clb, WOOD.lightened(0.1))
					FighterArt.outline(c, clb, 2.5)
				"hammer":
					var hh := PackedVector2Array([end - nv * 18.0 * k - d * 10.0 * k, end + nv * 18.0 * k - d * 10.0 * k, end + nv * 18.0 * k + d * 10.0 * k, end - nv * 18.0 * k + d * 10.0 * k])
					c.draw_colored_polygon(hh, STEEL_DARK)
					FighterArt.outline(c, hh, 2.5)
				_:
					c.draw_circle(hc, 12.0 * k, STEEL_DARK)
					for i in 8:
						var sp := Vector2.from_angle(TAU * float(i) / 8.0)
						c.draw_colored_polygon(PackedVector2Array([hc + sp.orthogonal() * 4.0 * k + sp * 10.0 * k, hc - sp.orthogonal() * 4.0 * k + sp * 10.0 * k, hc + sp * 19.0 * k]), STEEL)
					c.draw_arc(hc, 12.0 * k, 0.0, TAU, 14, BLACK, 2.0)
			tip = hc
		"halberd", "glaive", "spear", "lance", "scythe":
			var pl := 110.0 if fam != "lance" else 96.0
			tip = grip + d * (pl - 30.0) * k
			_haft(c, grip - d * 30.0 * k, tip, k)
			match fam:
				"spear":
					var sh := PackedVector2Array([tip - nv * 6.0 * k, tip + d * 26.0 * k, tip + nv * 6.0 * k])
					c.draw_colored_polygon(sh, STEEL)
					FighterArt.outline(c, sh, 2.0)
					tip += d * 26.0 * k
				"lance":
					var ln := PackedVector2Array([tip - nv * 12.0 * k, tip + d * 50.0 * k, tip + nv * 12.0 * k])
					c.draw_colored_polygon(ln, STEEL_DARK)
					FighterArt.outline(c, ln, 2.0)
					tip += d * 50.0 * k
				"halberd":
					var ax := PackedVector2Array([tip - d * 18.0 * k, tip + nv * 22.0 * k - d * 14.0 * k, tip + nv * 24.0 * k + d * 4.0 * k, tip])
					c.draw_colored_polygon(ax, STEEL)
					FighterArt.outline(c, ax, 2.0)
					var sp2 := PackedVector2Array([tip - nv * 4.0 * k, tip + d * 22.0 * k, tip + nv * 4.0 * k])
					c.draw_colored_polygon(sp2, STEEL)
					tip += d * 22.0 * k
				"glaive":
					tip = _blade(c, tip, d, nv, k, 0.0, 40.0, 9.0, true)
				"scythe":
					var arc := PackedVector2Array()
					for i in 9:
						var a2 := float(i) / 8.0
						arc.append(tip + (nv * 46.0 * a2 - d * 18.0 * a2 * a2) * k)
					for i in range(8, -1, -1):
						var a3 := float(i) / 8.0
						arc.append(tip + (nv * 44.0 * a3 - d * 18.0 * a3 * a3 + d * 7.0 * (1.0 - a3)) * k)
					c.draw_colored_polygon(arc, STEEL)
					FighterArt.outline(c, arc, 2.0)
	if burning:
		var steps := 4
		for i in steps:
			flames(c, grip.lerp(tip, (float(i) + 1.0) / float(steps)), 9.0 * k, t + float(i), 3)


static func _haft(c: CanvasItem, a: Vector2, b: Vector2, k: float) -> void:
	c.draw_line(a, b, BLACK, 7.0 * k + 3.0)
	c.draw_line(a, b, WOOD, 7.0 * k)


static func _blade(c: CanvasItem, grip: Vector2, d: Vector2, nv: Vector2, k: float, hilt: float, blen: float, bw: float, curved: bool) -> Vector2:
	var guard_p := grip + d * 6.0 * k
	c.draw_line(grip - d * hilt * 0.6 * k, guard_p, BLACK, 7.0 * k + 3.0)
	c.draw_line(grip - d * hilt * 0.6 * k, guard_p, WOOD.darkened(0.3), 7.0 * k)
	c.draw_line(guard_p - nv * 10.0 * k, guard_p + nv * 10.0 * k, BLACK, 6.0 * k + 2.0)
	c.draw_line(guard_p - nv * 10.0 * k, guard_p + nv * 10.0 * k, GOLD, 6.0 * k)
	var pts := PackedVector2Array()
	var n := 8
	for i in n + 1:
		var f := float(i) / float(n)
		var bend := nv * (sin(f * PI * 0.9) * 10.0 * k if curved else 0.0)
		pts.append(guard_p + d * blen * k * f - nv * bw * k * (1.0 - f * 0.85) + bend)
	var tipp := guard_p + d * (blen + 8.0) * k + nv * (6.0 * k if curved else 0.0)
	pts.append(tipp)
	for i in range(n, -1, -1):
		var f2 := float(i) / float(n)
		var bend2 := nv * (sin(f2 * PI * 0.9) * 10.0 * k if curved else 0.0)
		pts.append(guard_p + d * blen * k * f2 + nv * bw * k * (1.0 - f2 * 0.85) + bend2)
	c.draw_colored_polygon(pts, STEEL)
	FighterArt.outline(c, pts, 2.0)
	c.draw_line(guard_p + d * 4.0 * k, guard_p + d * blen * 0.85 * k, Color(1, 1, 1, 0.45), 1.5)
	return tipp


## The ANCIENT WEIGHT (the Trader): a heavy bronze weight on a chain, old runes on it.
static func ancient_weight(c: CanvasItem, hand: Vector2, k: float, swing: float, t: float) -> Vector2:
	var w := hand + Vector2(sin(swing) * 34.0 * k, cos(swing) * 34.0 * k)
	var links := 6
	for i in links:
		var p := hand.lerp(w, (float(i) + 0.5) / float(links))
		c.draw_circle(p, 2.5 * k, STEEL_DARK)
	var body_pts := PackedVector2Array([w + Vector2(-12, -6) * k, w + Vector2(12, -6) * k, w + Vector2(17, 16) * k, w + Vector2(-17, 16) * k])
	c.draw_colored_polygon(body_pts, Color(0.55, 0.40, 0.18))
	FighterArt.outline(c, body_pts, 2.5)
	c.draw_rect(Rect2(w + Vector2(-5, -10) * k, Vector2(10, 5) * k), Color(0.4, 0.3, 0.14))
	for i in 3:
		c.draw_line(w + Vector2(-9.0 + float(i) * 7.0, 2.0) * k, w + Vector2(-7.0 + float(i) * 7.0, 10.0) * k, Color(1.0, 0.3, 0.2, 0.5 + 0.3 * sin(t * 3.0 + float(i))), 1.5)
	return w + Vector2(0, 5.0 * k)


# ============================================================
# INSTRUMENTS (the Musician of Nightmares)
# ============================================================
static func instrument(c: CanvasItem, kind: String, hands: Dictionary, k: float, t: float, play: float) -> void:
	var hf: Vector2 = hands.get("hand_f", Vector2.ZERO)
	var hb: Vector2 = hands.get("hand_b", Vector2.ZERO)
	match kind:
		"accordion":
			var mid := (hf + hb) * 0.5
			var spread := (hf.x - hb.x) * (0.85 + 0.15 * sin(t * 5.0 + play * 6.0))
			var folds := 6
			for i in folds:
				var x0 := mid.x - spread * 0.5 + spread * float(i) / float(folds)
				var col := Color(0.55, 0.05, 0.08) if i % 2 == 0 else Color(0.30, 0.02, 0.04)
				c.draw_colored_polygon(PackedVector2Array([Vector2(x0, mid.y - 20.0 * k), Vector2(x0 + spread / float(folds), mid.y - 17.0 * k),
					Vector2(x0 + spread / float(folds), mid.y + 17.0 * k), Vector2(x0, mid.y + 20.0 * k)]), col)
			for side: float in [-1.0, 1.0]:
				var box := Rect2(Vector2(mid.x + side * spread * 0.5 - 7.0 * k, mid.y - 22.0 * k), Vector2(14.0 * k, 44.0 * k))
				c.draw_rect(box, Color(0.12, 0.08, 0.06))
				c.draw_rect(box, BLACK, false, 2.0)
				for j in 4:
					c.draw_circle(box.position + Vector2(7.0 * k, (8.0 + float(j) * 9.0) * k), 2.2 * k, CERAMIC)
		"violin":
			var body_c := hb + Vector2(10, -8) * k
			var vb := EnemyArt.ellipse_points(body_c, 16.0 * k, 9.0 * k, 14)
			c.draw_colored_polygon(vb, Color(0.48, 0.18, 0.08))
			FighterArt.outline(c, vb, 2.0)
			c.draw_line(body_c + Vector2(14, -2) * k, body_c + Vector2(40, -10) * k, BLACK, 4.0 * k)
			var bow_a := hf + Vector2(-30, -6) * k + Vector2(sin(t * 8.0 + play * 9.0) * 14.0 * k, 0)
			c.draw_line(bow_a, bow_a + Vector2(56, 12) * k, WOOD, 2.5 * k)
		"drum":
			var dc := Vector2(hf.x + 6.0 * k, hf.y + 14.0 * k)
			var dr := Rect2(dc - Vector2(20, 14) * k, Vector2(40, 28) * k)
			c.draw_rect(dr, Color(0.50, 0.06, 0.08))
			c.draw_rect(dr, BLACK, false, 2.5)
			c.draw_colored_polygon(EnemyArt.ellipse_points(dc - Vector2(0, 14) * k, 20.0 * k, 5.0 * k, 12), CERAMIC)
			for i in 4:
				c.draw_line(dr.position + Vector2(float(i) * 13.0 * k, 0), dr.position + Vector2(float(i) * 13.0 * k + 6.0 * k, 28.0 * k), GOLD, 1.5)
			c.draw_line(hf, hf + Vector2(10, -28 + 20.0 * play) * k, WOOD, 3.0 * k)
		"trumpet":
			var mouth := hf + Vector2(4, -10) * k
			var bell := mouth + Vector2(52, -6) * k
			c.draw_line(mouth, bell, GOLD.darkened(0.2), 6.0 * k)
			var bl := PackedVector2Array([bell + Vector2(0, -5) * k, bell + Vector2(18, -16) * k, bell + Vector2(18, 10) * k, bell + Vector2(0, 5) * k])
			c.draw_colored_polygon(bl, GOLD)
			FighterArt.outline(c, bl, 2.0)
		"cymbals":
			var gap := 6.0 + 26.0 * (0.5 + 0.5 * cos(t * 6.0 + play * 8.0))
			for side: float in [-1.0, 1.0]:
				var cc := (hf + hb) * 0.5 + Vector2(side * gap * k, -6.0 * k)
				c.draw_colored_polygon(EnemyArt.ellipse_points(cc, 4.0 * k, 22.0 * k, 12), GOLD)
				c.draw_arc(cc, 6.0 * k, 0.0, TAU, 10, BLACK, 1.5)
		"harp":
			var hp0 := hb + Vector2(-4, 20) * k
			var frame := PackedVector2Array([hp0, hp0 + Vector2(6, -70) * k, hp0 + Vector2(40, -60) * k, hp0 + Vector2(30, 0) * k])
			c.draw_polyline(frame + PackedVector2Array([hp0]), GOLD, 4.0 * k)
			for i in 6:
				var xx := float(i) * 5.5 + 7.0
				c.draw_line(hp0 + Vector2(xx, -2) * k, hp0 + Vector2(xx, -58.0 + xx * 0.3) * k, Color(1, 0.95, 0.8, 0.8), 1.2)


# ============================================================
# THE TROUPE'S HEART - PLACEHOLDER (the user will send a sketch and it gets imported)
# ============================================================
static func troupe_heart(c: CanvasItem, s: Dictionary) -> void:
	var t: float = s.get("t", 0.0)
	var reach: Vector2 = s.get("reach", Vector2.ZERO)                  # Local point a tentacle grabs
	var reach_k: float = s.get("reach_k", 0.0)
	var beat := 1.0 + 0.08 * maxf(sin(t * 7.0), 0.0) + 0.05 * maxf(sin(t * 7.0 - 0.6), 0.0)
	var hc := Vector2(0, -150)
	# Tentacles: 6 around it, one reaching out to where it grabs
	for i in 6:
		var a := -PI * 0.15 + TAU * float(i) / 6.0 + sin(t * 1.3 + float(i)) * 0.2
		var end := hc + Vector2.from_angle(a) * (140.0 + 20.0 * sin(t * 2.0 + float(i)))
		if i == 1 and reach_k > 0.0:
			end = end.lerp(reach, reach_k)
		var pts := PackedVector2Array()
		for j in 10:
			var f := float(j) / 9.0
			var p := hc.lerp(end, f) + Vector2.from_angle(a + PI * 0.5) * sin(f * 6.0 + t * 4.0 + float(i)) * 14.0 * f
			pts.append(p)
		c.draw_polyline(pts, BLACK, 18.0)
		c.draw_polyline(pts, SKIN_SHADE, 13.0)
		c.draw_polyline(pts, SKIN, 6.0)
	# The heart: two lobes + a point, veins, a crack of fire
	var lobes := PackedVector2Array()
	for i in 40:                                                         # (No repeated end point)
		var u := TAU * (float(i) + 0.5) / 40.0
		var x := 16.0 * pow(sin(u), 3.0)
		var y := -(13.0 * cos(u) - 5.0 * cos(2.0 * u) - 2.0 * cos(3.0 * u) - cos(4.0 * u))
		lobes.append(hc + Vector2(x, y) * 5.2 * beat)
	c.draw_colored_polygon(lobes, Color(0.55, 0.03, 0.05))
	FighterArt.outline(c, lobes, 4.0)
	for i in 5:
		var v0 := hc + Vector2(-40.0 + float(i) * 20.0, -40.0) * beat
		c.draw_polyline(PackedVector2Array([v0, v0 + Vector2(6, 22) * beat, v0 + Vector2(-4, 46) * beat]), Color(0.28, 0.0, 0.02), 4.0)
	c.draw_polyline(PackedVector2Array([hc + Vector2(-10, -30), hc + Vector2(4, -6), hc + Vector2(-6, 14), hc + Vector2(8, 40)]), FLAME, 4.0)
	c.draw_circle(hc + Vector2(0, -6), 10.0 + 4.0 * sin(t * 7.0), Color(1.0, 0.3, 0.15, 0.35))
	# A ring of tiny ceramic masks pinned into it (the Troupe it feeds)
	for i in 5:
		var mp := hc + Vector2.from_angle(-PI * 0.5 + TAU * float(i) / 5.0) * 58.0 * beat
		ceramic_mask(c, mp, 9.0, MASKS[i % MASKS.size()], t + float(i))
