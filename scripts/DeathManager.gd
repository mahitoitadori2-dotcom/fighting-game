class_name DeathManager
extends RefCounted
## Decides HOW a fighter dies from the LAST HIT they took (Fighter.last_hit),
## then plays that death animation. Animations draw the real character art
## (Fighter.draw_model_on) through clip masks, so halves / pieces are the actual fighter.
##
## EVERY death: 0.2 s hitstop, particles, corpse settles ON the floor, clean fade-out
## before the 1.5 s respawn (and the fighter fades back in: no instant pop).
##
##   NORMAL   fall over flat + dust + fade   (punch, sword, rocket, HNCT, triple rocket,
##                                            ClingingGrab, Eternal Grasp, Mini Eternal Grasp,
##                                            FAOTH rocket / HNCT / arms, anything else)
##   SPLIT    Armaggedon Drill: split in half + droplets + blood puddle (until respawn)
##   EXPLODE  ANY Onslaught version: bursts into pieces + sparks
##   DROWN    Void Goo (also FAOTH goo): slow sink into goo, bubbles + black wisps
##   IMPLODE  Shadow Swarm: head spirals inward, dark particles, body falls
##   FIRE     Nightmare Lord moves: burns to ash in PURE RED flames + scorch mark (until respawn)
##   GOLDEN   Enlightened One moves: shatters into golden armor shards + light particles
##   FALL     fell off the island: no corpse

const NORMAL := "normal"
const SPLIT := "split"
const EXPLODE := "explode"
const DROWN := "drown"
const IMPLODE := "implode"
const FIRE := "fire"
const GOLDEN := "golden"
const DOG := "dog"                 # Rotor: flips onto his back, legs up, swirly eyes, tongue out
const FALL := "fall"

const FIRE_MOVES := ["bloodflame", "launch_spikes", "double_trouble", "volatile_nightmare", "ritual"]
const GOLDEN_MOVES := ["beam_blast", "godly_light", "throne", "gorilla"]

const MOVE_NAMES := {
	"punch": "Punch", "rocket": "Rocket Delivery", "hnct": "HNCT Triangle Bomb",
	"drill": "Armaggedon Drill", "void_goo": "Void Goo", "triple_rocket": "Triple Rocket Delivery",
	"faoth": "Full Arsenal of the Hexagon", "sword": "Sword", "grab": "ClingingGrab",
	"eternal": "Eternal Grasp", "mini_eternal": "Mini Eternal Grasp", "shadow_swarm": "Shadow Swarm",
	"time_stop_penalty": "Time Stop backfire", "drill_miss": "own Drill",
	"bloodflame": "BloodFlame Spit", "bat_escape": "Bat Escape", "launch_spikes": "Launch O' Spikes",
	"double_trouble": "Double Trouble", "volatile_nightmare": "Volatile Nightmare", "oil": "Burning Oil",
	"ritual": "The Ritual of the Troupe",
	"gloves": "Bronze Gloves", "beam_blast": "Beam Blast", "helpers": "Helpers!",
	"godly_light": "Godly O' Light", "throne": "Throne", "gorilla": "Enlightened Gorilla Form",
	"rotor_bite": "Rotor's Bite", "spin_dash": "Spin Dash", "bark_wave": "Bark Wave",
	"tail_whip": "Tail Whip", "fetch_bomb": "Fetch Bomb",
}
const PART_NAMES := {"rocket": "Rocket", "goo": "Void Goo", "hnct": "HNCT", "arms": "Mechanical Arms"}


## The death type for the hit that dealt the final damage.
static func death_type(hit: HitData) -> String:
	if hit == null:
		return NORMAL
	if hit.onslaught:
		return EXPLODE                      # Onslaught Punch / Rocket / HNCT / ClingingGrab
	match hit.hit_type:
		"drill", "drill_tick":
			return SPLIT
		"goo":
			return DROWN                    # Void Goo, including FAOTH's goo part
		"beam":
			return IMPLODE
	if hit.move in FIRE_MOVES:
		return FIRE
	if hit.move in GOLDEN_MOVES:
		return GOLDEN
	return NORMAL                           # FAOTH rocket / hnct / arms land here too


## "Onslaught Rocket Delivery", "Full Arsenal of the Hexagon (Void Goo)", ...
static func describe(hit: HitData) -> String:
	if hit == null:
		return ""
	var n: String = MOVE_NAMES.get(hit.move, "")
	if n == "":
		return ""
	if hit.part != "":
		n += " (%s)" % PART_NAMES.get(hit.part, hit.part)
	if hit.onslaught:
		n = "Onslaught " + n
	return n


static func play(f: Fighter, type: String, hit: HitData) -> void:
	var desc := describe(hit)
	var text := "RING OUT!" if type == FALL else ("K.O.!" if desc == "" else "K.O. - %s" % desc)
	Effects.popup(f, f.global_position + Vector2(0, -175), text, Color(1.0, 0.35, 0.3), 22)
	Effects.play_hit_sound(f, "death_" + type, f.global_position)
	if type == FALL:
		return
	Effects.hitstop(f, 0.2)                 # Every K.O. lands with a 0.2 s freeze
	Effects.shake(f, 10.0)
	var root := f.get_tree().current_scene
	var floor_pos: Variant = Effects.ground_below(f, f.global_position)
	var fx := DeathFx.new()
	fx.fighter = f
	fx.type = type
	fx.floor_y = floor_pos.y if floor_pos != null else INF
	root.add_child(fx)
	fx.global_position = f.global_position
	# Ground decals: ON the floor (never floating), removed when the fighter respawns
	if floor_pos != null and (type == SPLIT or type == FIRE):
		var decal := GroundDecal.new()
		decal.kind = "blood" if type == SPLIT else "scorch"
		root.add_child(decal)
		decal.global_position = floor_pos
		f.respawned.connect(decal.queue_free, CONNECT_ONE_SHOT)


# ============================================================
# Building blocks
# ============================================================
## Draws a white polygon; its children are clipped to it.
class MaskNode extends Node2D:
	var poly := PackedVector2Array()

	func _ready() -> void:
		clip_children = CanvasItem.CLIP_CHILDREN_ONLY

	func _draw() -> void:
		draw_colored_polygon(poly, Color.WHITE)


## Draws the fighter's own art (optionally with a red cut edge at cut_x).
class ArtNode extends Node2D:
	var fighter: Fighter
	var cut_x := NAN

	func _process(_delta: float) -> void:
		queue_redraw()

	func _draw() -> void:
		if fighter == null or not is_instance_valid(fighter):
			return
		fighter.draw_model_on(self)
		if not is_nan(cut_x):           # Cartoon red cut along the split
			draw_rect(Rect2(cut_x - 5.0, -128, 10, 122), Color(0.86, 0.10, 0.14))
			draw_rect(Rect2(cut_x - 2.0, -126, 4, 118), Color(0.55, 0.03, 0.07))


## Blood puddle (Drill) or scorch mark (Fire). Sits on the floor, behind fighters.
class GroundDecal extends Node2D:
	var kind := "blood"
	var _t := 0.0

	func _ready() -> void:
		z_index = -1                     # Ground layer: above the island, below fighters

	func _process(delta: float) -> void:
		_t += delta
		if _t < 1.2:
			queue_redraw()

	func _draw() -> void:
		var k := clampf((_t - 0.25) / 0.6, 0.0, 1.0)
		if k <= 0.0:
			return
		var w := 64.0 * (1.0 - pow(1.0 - k, 2.0))
		var pts := PackedVector2Array()
		for i in 24:
			var a := TAU * float(i) / 24.0
			var r := w * (0.85 + 0.15 * sin(float(i) * 2.7))
			pts.append(Vector2(cos(a) * r, -1.0 + sin(a) * r * 0.16))
		if kind == "blood":
			draw_colored_polygon(FighterArt.wobble(pts, Vector2(0, -1), 1.5), Color(0, 0, 0))
			var inner := PackedVector2Array()
			for p in pts:
				inner.append(p * 0.92 + Vector2(0, -0.1))
			draw_colored_polygon(inner, Color(0.80, 0.08, 0.12))
			draw_circle(Vector2(-w * 0.3, -3), w * 0.12, Color(1.0, 0.4, 0.42))
			for d in [Vector2(-w - 12.0, -2), Vector2(w + 10.0, -1), Vector2(w * 0.45, 0)]:
				draw_circle(d, 4.5 * k, Color(0, 0, 0))
				draw_circle(d, 3.0 * k, Color(0.80, 0.08, 0.12))
		else:   # Scorch: charred black with a dark-red burnt rim
			draw_colored_polygon(pts, Color(0.35, 0.02, 0.02, 0.8))
			var inner := PackedVector2Array()
			for p in pts:
				inner.append(p * 0.8)
			draw_colored_polygon(inner, Color(0.06, 0.04, 0.04, 0.95))
			for i in 5:
				var x := sin(float(i) * 3.1) * w * 0.6
				draw_circle(Vector2(x, -2), 2.0, Color(0.6, 0.0, 0.0, 0.6 + 0.4 * sin(_t * 6.0 + float(i))))


# ============================================================
# The death animation
# ============================================================
class DeathFx extends Node2D:
	const LIFE := 1.45                       # Respawn happens at 1.5 s
	const HEAD := Vector2(2, -113)
	const NECK_Y := -99.0
	const GRAVITY := 1600.0

	var fighter: Fighter
	var type := DeathManager.NORMAL
	var floor_y := INF                       # World y of the floor (corpse settles there)
	var _vy := 0.0
	var _t := 0.0
	var _body: Node2D
	var _head: Node2D
	var _halves: Array[Node2D] = []
	var _pieces: Array[Dictionary] = []      # {node, vel, spin, grav}
	var _sink_art: Node2D
	var _burn_mask: MaskNode
	var _burn_art: Node2D
	var _particles: Array[Dictionary] = []   # {p, v, life, max, col, r, grav}
	var _top: Node2D
	var _imploded := false
	var _landed_dust := false

	func _ready() -> void:
		z_index = 5
		scale.x = float(fighter.facing)
		match type:
			DeathManager.SPLIT:
				_halves.append(_part(_rect(-90, -190, 90, 200), Vector2.ZERO, 0.0))
				_halves.append(_part(_rect(0, -190, 90, 200), Vector2.ZERO, 0.0))
				for i in 14:   # Cartoon droplets
					_spawn(Vector2(randf_range(-4.0, 4.0), randf_range(-110.0, -30.0)),
						Vector2(randf_range(-160.0, 160.0), randf_range(-260.0, -60.0)), randf_range(0.5, 0.9),
						Color(0.85, 0.08, 0.12), randf_range(2.5, 4.5), 900.0)
			DeathManager.EXPLODE:
				Effects.explosion(fighter, global_position + Vector2(0, -70), 95.0, true)
				Effects.hit_sparks(fighter, global_position + Vector2(0, -70), 16, 1.8)
				_make_pieces(2, 3, Vector2(260.0, 420.0), -320.0, 1400.0, false)
			DeathManager.GOLDEN:
				Effects.gold_burst(fighter, global_position + Vector2(0, -70), 110.0)
				_make_pieces(3, 4, Vector2(90.0, 200.0), -120.0, 260.0, true)
			DeathManager.DROWN:
				var m := _part(_rect(-100, -220, 200, 220), Vector2.ZERO)   # Only what is ABOVE the goo shows
				_sink_art = m.get_child(0)
			DeathManager.FIRE:
				_burn_mask = _part(_rect(-100, -220, 200, 240), Vector2.ZERO)
				_burn_art = _burn_mask.get_child(0)
			DeathManager.DOG:
				_body = _part(_rect(-120, -140, 240, 160), Vector2(0, -32))
			DeathManager.IMPLODE:
				_body = _part(_rect(-100, NECK_Y, 200, 120), Vector2.ZERO)
				_head = _part(_rect(-100, -200, 200, 200 + NECK_Y), HEAD)
			_:
				_body = _part(_rect(-100, -220, 200, 240), Vector2.ZERO)
		_top = Node2D.new()
		add_child(_top)
		_top.draw.connect(_draw_top)

	static func _rect(x: float, y: float, w: float, h: float) -> PackedVector2Array:
		return PackedVector2Array([Vector2(x, y), Vector2(x + w, y), Vector2(x + w, y + h), Vector2(x, y + h)])

	## A clipped copy of the fighter. pivot = the point it rotates / scales around.
	func _part(mask: PackedVector2Array, pivot: Vector2, cut_x: float = NAN) -> MaskNode:
		var m := MaskNode.new()
		for p in mask:
			m.poly.append(p - pivot)
		m.position = pivot
		var a := ArtNode.new()
		a.fighter = fighter
		a.position = -pivot
		a.cut_x = cut_x
		m.add_child(a)
		add_child(m)
		return m

	## Grid of clipped pieces flying outward (explode / golden shatter).
	func _make_pieces(cols: int, rows: int, speed: Vector2, up: float, grav: float, golden: bool) -> void:
		var x0 := -45.0
		var y0 := -150.0
		var cw := 90.0 / float(cols)
		var rh := 162.0 / float(rows)
		for ci in cols:
			for ri in rows:
				var x := x0 + cw * float(ci)
				var y := y0 + rh * float(ri)
				var center := Vector2(x + cw * 0.5, y + rh * 0.5)
				var node := _part(_rect(x, y, cw, rh), center)
				if golden:
					node.get_child(0).modulate = Color(1.25, 1.05, 0.55)     # Gilded shards
				var out := (center - Vector2(0, -70)).normalized()
				_pieces.append({"node": node, "vel": out * randf_range(speed.x, speed.y) + Vector2(0, up),
					"spin": randf_range(-10.0, 10.0) * (0.5 if golden else 1.0), "grav": grav})

	func _spawn(p: Vector2, v: Vector2, life: float, col: Color, r: float, grav: float = 0.0) -> void:
		_particles.append({"p": p, "v": v, "life": 0.0, "max": life, "col": col, "r": r, "grav": grav})

	func _process(delta: float) -> void:
		_t += delta
		# Corpse settles onto the floor (killed mid-air = falls, never floats)
		if type != DeathManager.EXPLODE and type != DeathManager.GOLDEN and floor_y < INF:
			if global_position.y < floor_y:
				_vy += GRAVITY * delta
				global_position.y = minf(global_position.y + _vy * delta, floor_y)
		match type:
			DeathManager.SPLIT:
				var k := _ease_in(_t / 0.55)
				_halves[0].rotation = -1.45 * k
				_halves[0].position.x = -8.0 * k
				_halves[1].rotation = 1.45 * k
				_halves[1].position.x = 8.0 * k
				_dust_on_land(0.55)
			DeathManager.EXPLODE, DeathManager.GOLDEN:
				var floor_local := (floor_y - global_position.y) if floor_y < INF else INF
				for pc in _pieces:
					var n: Node2D = pc["node"]
					pc["vel"] += Vector2(0, pc["grav"]) * delta
					n.position += pc["vel"] * delta
					n.rotation += pc["spin"] * delta
					if n.position.y > floor_local - 8.0:        # Pieces bounce on the floor, never sink through it
						n.position.y = floor_local - 8.0
						pc["vel"] = Vector2(pc["vel"].x * 0.6, -absf(pc["vel"].y) * 0.3)
						pc["spin"] *= 0.6
				if type == DeathManager.GOLDEN and _t < 0.9:
					for i in 2:   # Light particles drifting up
						_spawn(Vector2(randf_range(-40.0, 40.0), randf_range(-140.0, -10.0)),
							Vector2(randf_range(-30.0, 30.0), randf_range(-90.0, -30.0)), randf_range(0.5, 0.9),
							Color(1.0, 0.85, 0.3) if randf() < 0.6 else Color.WHITE, randf_range(2.0, 3.5))
			DeathManager.DROWN:
				# Smoother + slower: ease-in-out sink, wobble, darkening, lots of particles
				var k := smoothstep(0.1, 1.35, _t)
				_sink_art.position.y = 150.0 * k
				_sink_art.position.x = sin(_t * 9.0) * 4.0 * (1.0 - k)
				_sink_art.rotation = sin(_t * 5.0) * 0.06 * (1.0 - k)
				_sink_art.modulate = Color.WHITE.lerp(Color(0.05, 0.0, 0.08), minf(k * 1.3, 1.0))
				for i in 3:
					var black := randf() < 0.6
					_spawn(Vector2(randf_range(-34.0, 34.0), randf_range(-20.0, 0.0)),
						Vector2(randf_range(-20.0, 20.0), randf_range(-140.0, -50.0)), randf_range(0.6, 1.1),
						Color(0.03, 0.0, 0.06) if black else Color(0.55, 0.3, 0.85), randf_range(2.5, 5.5))
			DeathManager.FIRE:
				# 0-0.5 s: blackens in pure red flames. 0.5-1.3 s: crumbles to ash from the top.
				var char_k := clampf(_t / 0.5, 0.0, 1.0)
				_burn_art.modulate = Color.WHITE.lerp(Color(0.12, 0.03, 0.03), char_k)
				var crumble := smoothstep(0.45, 1.3, _t)
				var top_y := -220.0 + 225.0 * crumble
				_burn_mask.poly = _rect(-100, top_y, 200, 20.0 - top_y)
				_burn_mask.queue_redraw()
				if _t < 1.2:
					for i in 2:   # Pure red embers rising
						_spawn(Vector2(randf_range(-26.0, 26.0), randf_range(top_y, 0.0)),
							Vector2(randf_range(-25.0, 25.0), randf_range(-160.0, -70.0)), randf_range(0.35, 0.7),
							Color(1.0, 0.0, 0.0), randf_range(2.0, 4.0))
				if _t > 0.45 and _t < 1.3:
					for i in 2:   # Ash falling / drifting from the crumble line
						_spawn(Vector2(randf_range(-28.0, 28.0), top_y + randf_range(0.0, 10.0)),
							Vector2(randf_range(-50.0, 50.0), randf_range(-30.0, 20.0)), randf_range(0.6, 1.0),
							Color(0.25, 0.23, 0.22) if randf() < 0.7 else Color(0.08, 0.07, 0.07), randf_range(2.0, 4.0), 260.0)
			DeathManager.DOG:
				# Cartoon dog K.O.: little hop, flips onto his back (legs up), lands, dizzy stars
				var k := smoothstep(0.0, 0.45, _t)
				_body.rotation = PI * 0.96 * k
				_body.position.y = -32.0 - sin(k * PI) * 26.0 + 10.0 * k      # Back rests on the floor
				if _t > 0.45 and _t < 1.2 and fmod(_t, 0.12) < 0.02:
					var star_a := _t * 8.0
					_spawn(Vector2(30.0 + cos(star_a) * 18.0, -14.0 + sin(star_a) * 6.0), Vector2(0, -8), 0.5, Color(1.0, 0.9, 0.3), 3.5)
				_dust_on_land(0.45)
			DeathManager.IMPLODE:
				# Smoother + slower: head spirals inward, dark particles swirl in, then the body falls
				var hk := smoothstep(0.0, 0.7, _t)
				_head.scale = Vector2.ONE * (1.0 - hk)
				_head.rotation = hk * 4.0
				if _t < 0.65:
					for i in 2:
						var ang := randf() * TAU
						var off := Vector2.from_angle(ang) * randf_range(45.0, 80.0)
						var swirl := Vector2.from_angle(ang + PI * 0.5) * 120.0
						_spawn(HEAD + off, -off / 0.35 + swirl, 0.35, Color(0.25, 0.05, 0.4) if randf() < 0.6 else Color(0.05, 0.0, 0.08), randf_range(2.0, 4.0))
				if hk >= 1.0 and not _imploded:
					_imploded = true
					_head.visible = false
					Effects.void_burst(fighter, to_global(HEAD), 34.0)
				if _t > 0.45:
					_fall(_body, _t - 0.45)
					_dust_on_land(0.9)
			_:
				_fall(_body, _t)
				_dust_on_land(0.45)

		var alive: Array[Dictionary] = []
		for pt in _particles:
			pt["life"] += delta
			pt["v"] += Vector2(0, pt["grav"]) * delta
			pt["p"] += pt["v"] * delta
			if pt["life"] < pt["max"]:
				alive.append(pt)
		_particles = alive

		# Clean fade-out before the respawn
		if _t > 0.9:
			modulate.a = clampf(1.0 - (_t - 0.9) / (LIFE - 0.9), 0.0, 1.0)
		if _t >= LIFE:
			queue_free()
		queue_redraw()
		_top.queue_redraw()

	## Fall over backwards around the feet (lifted so the body never sinks into the floor).
	func _fall(n: Node2D, t: float) -> void:
		var k := _ease_in(t / 0.45)
		var bounce := sin(clampf((t - 0.45) / 0.2, 0.0, 1.0) * PI) * 0.08
		n.rotation = -PI * 0.5 * k + bounce
		n.position.y = -22.0 * k

	func _dust_on_land(at: float) -> void:
		if _landed_dust or _t < at:
			return
		_landed_dust = true
		for i in 10:
			_spawn(Vector2(randf_range(-60.0, 20.0), -4.0), Vector2(randf_range(-90.0, 90.0), randf_range(-60.0, -15.0)),
				randf_range(0.35, 0.6), Color(0.85, 0.82, 0.75, 0.8), randf_range(3.0, 6.0))

	static func _ease_in(x: float) -> float:
		x = clampf(x, 0.0, 1.0)
		return x * x

	func _draw() -> void:
		if type == DeathManager.DROWN:      # The goo pool he sinks into (purple -> black gradient)
			var k := clampf(_t / 0.3, 0.0, 1.0)
			var pts := PackedVector2Array()
			var cols := PackedColorArray()
			for i in 24:
				var a := TAU * float(i) / 24.0
				var p := Vector2(cos(a) * (60.0 * k + 3.0), -1.0 + sin(a) * (60.0 * k + 3.0) * 0.22)
				pts.append(p)
				cols.append(Color(0.30, 0.12, 0.42) if p.y < -1.0 else Color(0.02, 0.0, 0.04))
			draw_polygon(pts, cols)
			FighterArt.outline(self, pts, 3.0)

	func _draw_top() -> void:
		for pt in _particles:
			var a: float = 1.0 - float(pt["life"]) / float(pt["max"])
			var c: Color = pt["col"]
			_top.draw_circle(pt["p"], float(pt["r"]) * (0.5 + 0.5 * a), Color(c.r, c.g, c.b, c.a * a))
		if type == DeathManager.FIRE and _t < 1.25:
			# Pure red flames licking up the body (gradient red -> dark red)
			var top_y := -220.0 + 225.0 * smoothstep(0.45, 1.3, _t)
			var h_body := -top_y
			var strength := clampf(_t / 0.2, 0.0, 1.0) * (1.0 - clampf((_t - 1.0) / 0.25, 0.0, 1.0))
			for i in 7:
				var x := -26.0 + float(i) * 8.7
				var h := (26.0 + 16.0 * sin(_t * 18.0 + float(i) * 1.7)) * strength * clampf(h_body / 120.0, 0.3, 1.0)
				if h < 2.0:
					continue
				var base_y := lerpf(0.0, top_y + 20.0, 0.5 + 0.5 * sin(float(i) * 2.3))
				var tri := PackedVector2Array([Vector2(x - 8, base_y), Vector2(x + 8, base_y), Vector2(x + 1, base_y - h)])
				_top.draw_polygon(tri, PackedColorArray([Color(1, 0, 0, 0.95), Color(1, 0, 0, 0.95), Color(0.5, 0, 0, 0.9)]))
		if type == DeathManager.DROWN and _t < 1.3:   # Goo bubbles popping on the surface
			for i in 5:
				var bx := sin(float(i) * 2.1 + _t * 2.5) * 38.0
				var by := -2.0 - fmod(_t * 26.0 + float(i) * 7.0, 12.0)
				_top.draw_circle(Vector2(bx, by), 3.4, Color(0, 0, 0, 0.8))
				_top.draw_circle(Vector2(bx, by), 2.4, Color(0.55, 0.3, 0.85, 0.9))
