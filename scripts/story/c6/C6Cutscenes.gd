class_name C6Cutscenes
extends RefCounted
## THE ENLIGHTENED CHASE cutscenes, painted by StoryCutscene (full screen, drawn in code):
##   "enl_chase"  the start: the Enlightened One RUNS across the golden dunes, your hero (the one
##                you picked) runs after him, the other hero lies injured behind and can't follow
##   "enl_end"    after his defeat: he points at the sky, and everything he threw (barrels,
##                grenades, relics) rises off the ground and spirals up into a DARK CLOUD

const KINDS := ["enl_chase", "enl_end"]


static func paint(p: Control, kind: String, sz: Vector2, k: float, t: float) -> void:
	match kind:
		"enl_chase":
			_chase(p, sz, k, t)
		"enl_end":
			_end(p, sz, k, t)


## Your hero ("warrior" / "architect" / "anti") and the other, injured one.
static func _heroes() -> Array:
	var h := StoryLevels.hero_of(StoryProgress.current_level)
	var other := "architect" if h == "warrior" else "warrior"
	return [h, other]


## A hero RUNNING (real walk-cycle legs from the in-game art), facing right, origin = feet.
static func _run(p: Control, hero: String, pos: Vector2, s: float, t: float, ph: float) -> void:
	p.draw_set_transform(pos, 0.08, Vector2(s, s))
	match hero:
		"warrior":
			WarriorArt._draw_figure(p, {"t": t, "ph": ph, "floor": true})
		"anti":
			ArchitectArt.set_palette(ArchitectArt.ANTI_PALETTE)
			ArchitectArt._draw_figure(p, t, ph, true, 0.0, 0.0, 0.0, 0.0, false, false)
			ArchitectArt.set_palette(ArchitectArt.NORMAL_PALETTE)
		_:
			ArchitectArt._draw_figure(p, t, ph, true, 0.0, 0.0, 0.0, 0.0, false, false)
	p.draw_set_transform(Vector2.ZERO, 0.0, Vector2.ONE)


static func _dust(p: Control, pos: Vector2, t: float, seed_v: float) -> void:
	for i in 4:
		var a := fmod(t * 2.5 + float(i) * 0.25 + seed_v, 1.0)
		p.draw_circle(pos + Vector2(-a * 60.0, -a * 18.0), 6.0 + a * 10.0, Color(0.95, 0.82, 0.55, 0.5 * (1.0 - a)))


# ============================================================
# THE CHASE BEGINS
# ============================================================
static func _chase(p: Control, sz: Vector2, k: float, t: float) -> void:
	C6Backdrops._dunes(p, sz)
	var ground := sz.y * 0.82
	p.draw_rect(Rect2(0, ground, sz.x, sz.y - ground), Color(0.86, 0.66, 0.36))
	for i in 14:                                                 # Ground rushing by (we run)
		var x := fmod(float(i) * 140.0 - t * 420.0, sz.x + 140.0)
		if x < -20.0:
			x += sz.x + 140.0
		p.draw_line(Vector2(x, ground + 18.0), Vector2(x + 40.0, ground + 18.0), Color(0.72, 0.52, 0.26), 4.0)
	var hs := _heroes()
	# The injured hero, left behind (first, then the camera leaves him)
	var inj_x := sz.x * 0.16 - maxf(k - 2.5, 0.0) * 220.0
	if inj_x > -150.0:
		var ip := Vector2(inj_x, ground + 4.0)
		p.draw_set_transform(ip, -1.25, Vector2(1.25, 1.25))      # Lying on his side
		StoryLevels.hero_art(String(hs[1])).call("draw_portrait", p, t * 0.3)
		p.draw_set_transform(Vector2.ZERO, 0.0, Vector2.ONE)
		for j in 3:                                                # Hurt
			p.draw_circle(ip + Vector2(30.0 + float(j) * 22.0, -26.0 + float(j) * 5.0), 6.0, Color(0.75, 0.05, 0.05, 0.8))
		if k > 0.8 and k < 3.6:
			FighterArt.label(p, ip + Vector2(80, -120), "GO...!  CATCH HIM!", 22, Color(1, 1, 1))
	# The Enlightened One, running away (far ahead)
	var ex := sz.x * (0.62 + 0.04 * sin(t * 0.7)) + minf(k, 4.0) * 30.0
	p.draw_set_transform(Vector2(ex, ground), 0.1, Vector2(1.5, 1.5))
	EnlightenedOneArt._draw_figure(p, {"t": t, "ph": t * 14.0, "floor": true})
	p.draw_set_transform(Vector2.ZERO, 0.0, Vector2.ONE)
	_dust(p, Vector2(ex - 20.0, ground), t, 0.0)
	if k > 1.2 and k < 4.2:
		FighterArt.label(p, Vector2(ex + 40.0, ground - 260.0), "You'll never catch me!", 20, Color(1.0, 0.9, 0.5))
	# Your hero, running after him
	var hx := sz.x * 0.38 + clampf(k - 1.0, 0.0, 4.0) * 40.0
	_run(p, String(hs[0]), Vector2(hx, ground), 1.6, t, t * 15.0)
	_dust(p, Vector2(hx - 20.0, ground), t, 0.5)
	# Speed lines
	for i in 10:
		var y := sz.y * (0.3 + 0.05 * float(i))
		var x := fmod(float(i) * 233.0 - t * 900.0, sz.x + 200.0)
		if x < -100.0:
			x += sz.x + 200.0
		p.draw_line(Vector2(x, y), Vector2(x + 90.0, y), Color(1, 1, 1, 0.25), 2.0)


# ============================================================
# AFTER HIS DEFEAT (to be continued): everything rises into a dark cloud
# ============================================================
static func _end(p: Control, sz: Vector2, k: float, t: float) -> void:
	C6Backdrops._reliquary(p, sz)
	var dark := clampf((k - 1.0) / 3.0, 0.0, 1.0)
	p.draw_rect(Rect2(Vector2.ZERO, sz), Color(0.05, 0.02, 0.1, 0.55 * dark))   # The sky darkens
	var ground := sz.y * 0.80
	p.draw_rect(Rect2(0, ground, sz.x, sz.y - ground), Color(0.85, 0.75, 0.55).darkened(0.5 * dark))
	# The DARK CLOUD forming above
	var cc := Vector2(sz.x * 0.5, sz.y * 0.16)
	var cr := 40.0 + 200.0 * dark
	for i in 12:
		var a := TAU * float(i) / 12.0 + t * 0.4
		p.draw_circle(cc + Vector2(cos(a) * cr * 0.9, sin(a) * cr * 0.35), cr * 0.45, Color(0.10, 0.04, 0.16, 0.85 * dark))
	p.draw_circle(cc, cr * 0.6, Color(0.04, 0.0, 0.08, 0.9 * dark))
	if dark > 0.5 and fmod(t, 1.7) < 0.08:                         # Lightning
		var lx := cc.x + sin(t * 9.0) * cr * 0.6
		p.draw_polyline(PackedVector2Array([Vector2(lx, cc.y), Vector2(lx + 20, cc.y + 60), Vector2(lx - 10, cc.y + 110), Vector2(lx + 15, cc.y + 170)]), Color(0.8, 0.6, 1.0), 4.0)
	# Everything he threw rises up and spirals into the cloud
	for i in 16:
		var start := Vector2(sz.x * (0.06 + 0.88 * fmod(float(i) * 0.618, 1.0)), ground - 10.0)
		var u := clampf((k - 1.5 - float(i) * 0.12) / 3.2, 0.0, 1.0)
		if u >= 1.0:
			continue
		var e := u * u
		var spiral := Vector2(cos(t * 3.0 + float(i)), sin(t * 3.0 + float(i)) * 0.3) * (1.0 - e) * 60.0 * e
		var pos := start.lerp(cc, e) + spiral
		var look: String = ["barrel", "holy_grenade", "relic", "relic", "relic"][i % 5]
		p.draw_set_transform(pos, t * (2.0 + float(i % 3)), Vector2.ONE * (1.0 - 0.7 * e))
		EnlightenedFx.draw_object(p, look, Vector2.ZERO, 0.0, i, t)
		p.draw_set_transform(Vector2.ZERO, 0.0, Vector2.ONE)
	# The Enlightened One on his knees, pointing at the sky
	var ep := Vector2(sz.x * 0.55, ground)
	p.draw_set_transform(ep + Vector2(0, 20), 0.0, Vector2(1.6, 1.4))
	EnlightenedOneArt.draw_portrait(p, t * 0.2)
	p.draw_set_transform(Vector2.ZERO, 0.0, Vector2.ONE)
	var sh := ep + Vector2(10, -150)
	var hand := sh + Vector2(-20, -110)
	p.draw_line(sh, hand, EnlightenedFx.BLACK, 16.0, FighterArt.AA)
	p.draw_line(sh, hand, Color(0.97, 0.77, 0.24), 10.0, FighterArt.AA)
	p.draw_line(hand, hand + Vector2(-4, -30), EnlightenedFx.BLACK, 7.0, FighterArt.AA)              # The pointing finger
	p.draw_line(hand, hand + Vector2(-4, -30), Color(0.74, 0.46, 0.20), 4.0, FighterArt.AA)
	# Your hero, watching
	var hs := _heroes()
	p.draw_set_transform(Vector2(sz.x * 0.22, ground), 0.0, Vector2(1.5, 1.5))
	StoryLevels.hero_art(String(hs[0])).call("draw_portrait", p, t)
	p.draw_set_transform(Vector2.ZERO, 0.0, Vector2.ONE)
