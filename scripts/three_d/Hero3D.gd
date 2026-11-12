class_name Hero3D
extends Node3D
## REAL 3D CHARACTERS for the 3D cutscenes (and the 3D menus): the WARRIOR, the ARCHITECT
## (+ ANTI ARCHITECT and the Galaxy skin), THE ENLIGHTENED ONE - and, through make_custom(),
## the humanoid BOSSES (Boss3D). Rounded shapes with the game's thick black outline, true
## colours (Three.char_mode). A small rig with ANIMATED limbs:
##   pose = "idle" | "run" | "fall" | "lie" | "climb" | "roll" | "kneel_point" | "menace"
##   face(dir)      turn to look along a direction (the model faces +x by default)
##   spin           extra roll of the whole body around its middle (tumbling / rolling)
## Origin = feet, about 2.2 units tall (scale the node for bigger bosses).

var pose := "idle"
var spin := 0.0
var hunch := 0.0                       # Permanent forward bend (hunched bosses)
var speed := 1.0                       # Animation speed

var body: Node3D                       # Pivot at the hips (spin / lean happen here)
var head: Node3D
var hands: Array[Node3D] = []          # Lower-arm pivots [near, far] (props go here)
var _legs: Array[Node3D] = []          # [near, far] hip pivots
var _knees: Array[Node3D] = []
var _arms: Array[Node3D] = []          # [near, far] shoulder pivots
var _t := 0.0


## Make a hero: "warrior" / "architect" / "anti" / "enlightened".
static func make(parent: Node3D, who: String, pos: Vector3, p_pose: String = "idle") -> Hero3D:
	var cfg := _palette(who)
	cfg["who"] = who
	return make_custom(parent, cfg, pos, p_pose)


## Any humanoid from a colour config: leg, arm, chest, belt, foot, hand (Colors), head
## ("helm" / "visor" / "mask" / "hood" / "skull" / "plain"), head_col, and optional
## "bulk" (torso size), "limb" (limb thickness), "extras": Callable(h: Hero3D) for props.
static func make_custom(parent: Node3D, cfg: Dictionary, pos: Vector3, p_pose: String = "idle") -> Hero3D:
	var h := Hero3D.new()
	h.position = pos
	h.pose = p_pose
	parent.add_child(h)
	Three.char_mode = true
	h._build(cfg)
	if cfg.has("extras"):
		(cfg["extras"] as Callable).call(h)
	Three.char_mode = false
	return h


func face(dir: Vector3) -> void:
	if dir.length() > 0.001:
		rotation.y = atan2(-dir.z, dir.x)


# ============================================================
# BUILD
# ============================================================
func cap(parent: Node3D, r: float, seg_len: float, pos: Vector3, col: Color, glow: float = 0.0) -> MeshInstance3D:
	var m := CapsuleMesh.new()
	m.radius = r
	m.height = maxf(seg_len, r * 2.0)
	m.radial_segments = 10
	m.rings = 3
	var mi := MeshInstance3D.new()
	mi.mesh = m
	mi.material_override = Three.outlined(Three.mat(col, glow), 0.025)
	mi.position = pos
	parent.add_child(mi)
	return mi


func _pivot(parent: Node3D, pos: Vector3) -> Node3D:
	var p := Node3D.new()
	p.position = pos
	parent.add_child(p)
	return p


## A leg / arm: pivot at the joint, upper part, lower pivot + lower part + foot / hand.
func _limb(parent: Node3D, at: Vector3, seg_len: float, r: float, upper: Color, lower: Color, end_col: Color, end_r: float) -> Array:
	var top := _pivot(parent, at)
	cap(top, r, seg_len * 0.55, Vector3(0, -seg_len * 0.25, 0), upper)
	var mid := _pivot(top, Vector3(0, -seg_len * 0.5, 0))
	cap(mid, r * 0.9, seg_len * 0.55, Vector3(0, -seg_len * 0.25, 0), lower)
	Three.ball(mid, end_r, Vector3(0.03, -seg_len * 0.5, 0), end_col, 0.0, 0.025)
	return [top, mid]


func _build(cfg: Dictionary) -> void:
	var who := String(cfg.get("who", ""))
	var bulk: float = cfg.get("bulk", 1.0)
	var lr: float = cfg.get("limb", 1.0)
	body = _pivot(self, Vector3(0, 0.95, 0))
	# Legs (hips at y = 0.95), the far one slightly darker
	for side: float in [1.0, -1.0]:
		var lc: Color = cfg["leg"] if side > 0.0 else (cfg["leg"] as Color).darkened(0.2)
		var l := _limb(body, Vector3(0, 0, side * 0.16 * bulk), 0.95, 0.13 * lr, lc, lc, cfg.get("foot", lc), 0.15 * lr)
		_legs.append(l[0])
		_knees.append(l[1])
	# Torso (a rounded chest) + belt
	var chest := cap(body, 0.3 * bulk, 0.85, Vector3(0, 0.45, 0), cfg["chest"])
	chest.scale = Vector3(0.85, 1.0, 1.15)
	Three.cyl(body, 0.29 * bulk, 0.14, Vector3(0, 0.12, 0), cfg.get("belt", cfg["chest"]), 0.0, 0.02, 14)
	# Head
	head = _pivot(body, Vector3(0.02, 1.08, 0))
	var hc: Color = cfg.get("head_col", Color(0.9, 0.9, 0.9))
	match String(cfg.get("head", "plain")):
		"helm":                                                    # Warrior: silver helmet with eye holes
			Three.ball(head, 0.25, Vector3.ZERO, hc, 0.0, 0.03)
			for z: float in [-0.07, 0.07]:
				Three.ball(head, 0.045, Vector3(0.22, 0.03, z), Color(0.04, 0.02, 0.06), 0.0, 0.0)
		"visor":                                                   # Architect: helmet + dark visor
			Three.ball(head, 0.25, Vector3.ZERO, hc, 0.0, 0.03)
			var v := Three.box(head, Vector3(0.1, 0.12, 0.3), Vector3(0.19, 0.0, 0), cfg.get("visor", Color(0.07, 0.08, 0.11)), 0.0, 0.0)
			v.rotation.z = 0.15
		"mask":                                                    # Enlightened: ivory mask, gold eye slits
			Three.ball(head, 0.24, Vector3.ZERO, hc, 0.0, 0.03)
			for z: float in [-0.08, 0.08]:
				Three.box(head, Vector3(0.04, 0.03, 0.06), Vector3(0.22, 0.03, z), Color(1.0, 0.85, 0.35), 2.0, 0.0)
		"hood":
			var hd := Three.cone(head, 0.3, 0.6, Vector3(-0.02, 0.1, 0), hc, 0.0, 0.03)
			hd.rotation.z = 0.15
			Three.ball(head, 0.18, Vector3(0.08, -0.02, 0), Color(0.03, 0.02, 0.04), 0.0, 0.0)
			for z: float in [-0.06, 0.06]:
				Three.ball(head, 0.035, Vector3(0.24, 0.0, z), cfg.get("eye", Color(1, 1, 1)), 3.0, 0.0)
		"skull":
			Three.ball(head, 0.24, Vector3.ZERO, hc, 0.0, 0.03)
			for z: float in [-0.08, 0.08]:
				Three.ball(head, 0.06, Vector3(0.2, 0.03, z), Color(0.02, 0.0, 0.0), 0.0, 0.0)
		_:
			Three.ball(head, 0.24, Vector3.ZERO, hc, 0.0, 0.03)
			for z: float in [-0.07, 0.07]:
				Three.ball(head, 0.035, Vector3(0.22, 0.03, z), cfg.get("eye", Color(0.05, 0.05, 0.05)), 1.0, 0.0)
	# Arms (shoulders at the top of the chest)
	for side: float in [1.0, -1.0]:
		var ac: Color = cfg["arm"] if side > 0.0 else (cfg["arm"] as Color).darkened(0.2)
		# Shoulder just outside the chest (chest half-depth + arm radius): arms never cut into the body
		var sz := 0.3 * bulk * 1.15 + 0.105 * lr + 0.03
		var a := _limb(body, Vector3(0, 0.8, side * sz), 0.85, 0.105 * lr, ac, ac, cfg.get("hand", ac), 0.13 * lr)
		_arms.append(a[0])
		hands.append(a[1])
	# The heroes' own details
	match who:
		"warrior":
			Three.ball(body, 0.13, Vector3(-0.02, 0.92, 0.47), cfg["head_col"], 0.0, 0.025)   # Shoulder pad (on top of the shoulder)
			# The jagged sword, held forward-down (its tip never reaches the floor)
			var blade := Three.prism(hands[0], Vector3(0.12, 0.95, 0.05), Vector3(0.45, -0.66, 0), Color(0.75, 0.77, 0.82), 0.0, 0.025)
			blade.rotation = Vector3(0, 0, -PI * 0.65)
		"architect", "anti":
			Three.ball(body, 0.1, Vector3(0.27, 0.55, 0), cfg["core"], 3.0, 0.02)                # Glowing chest core
		"enlightened":
			Three.ring(head, 0.09, 0.11, Vector3(0, 0.14, 0), Color(0.97, 0.77, 0.24), 0.5, 0.0)  # Circlet
			var halo := Three.ring(head, 0.4, 0.46, Vector3(-0.2, 0.05, 0), Color(1.0, 0.86, 0.35), 3.0, 0.0)
			halo.rotation = Vector3(0, 0, PI * 0.5)
			for hnd in hands:                                                                     # Bronze gauntlets
				Three.ball(hnd, 0.16, Vector3(0.03, -0.42, 0), Color(0.74, 0.46, 0.20), 0.0, 0.025)


## Colours per hero (the same palettes as the 2D art; Galaxy skin when worn).
static func _palette(who: String) -> Dictionary:
	match who:
		"warrior":
			var w := WarriorArt.NORMAL_PALETTE
			if Achievements.galaxy_skin and Achievements.is_unlocked(Achievements.ULTIMATE):
				w = GalaxySkin.WARRIOR
			return {"leg": w["VOID"], "arm": w["VOID"], "chest": w["VOID"], "belt": w["VOID_HI"], "foot": w["VOID_SHADE"],
				"hand": w["VOID_SHADE"], "head": "helm", "head_col": w["SILVER"]}
		"enlightened":
			return {"leg": Color(0.20, 0.17, 0.30), "arm": Color(0.20, 0.17, 0.30), "chest": Color(0.97, 0.77, 0.24),
				"belt": Color(0.68, 0.48, 0.12), "foot": Color(0.97, 0.77, 0.24), "hand": Color(0.74, 0.46, 0.20),
				"head": "mask", "head_col": Color(0.96, 0.93, 0.84)}
		_:
			var a: Dictionary = ArchitectArt.ANTI_PALETTE if who == "anti" else ArchitectArt.NORMAL_PALETTE
			if who != "anti" and Achievements.galaxy_skin and Achievements.is_unlocked(Achievements.ULTIMATE):
				a = GalaxySkin.ARCHITECT
			return {"leg": a["GREEN"], "arm": a["GREEN"], "chest": a["WHITE"], "belt": a["DARK"], "foot": a["DARK_SHADE"],
				"hand": a["GREEN_SHADE"], "head": "visor", "head_col": a["WHITE"], "visor": a["VISOR"], "core": a["CORE"]}


# ============================================================
# ANIMATION
# ============================================================
func _process(delta: float) -> void:
	_t += delta * speed
	var t := _t
	var leg := [0.0, 0.0]
	var knee := [0.0, 0.0]
	var arm := [0.0, 0.0]
	var arm_out := [0.0, 0.0]
	var lean := 0.0
	var bob := 0.0
	var body_rot := Vector3.ZERO
	match pose:
		"walk":                                                     # Heavy, steady boss walk
			var wp := t * 5.0
			leg = [sin(wp) * 0.4, -sin(wp) * 0.4]
			knee = [maxf(0.0, -cos(wp)) * 0.5, maxf(0.0, cos(wp)) * 0.5]
			arm = [-sin(wp) * 0.3 + 0.2, sin(wp) * 0.3 + 0.2]
			lean = -0.05
			bob = absf(sin(wp)) * 0.04
		"run":
			var ph := t * 10.0
			leg = [sin(ph) * 0.6, -sin(ph) * 0.6]
			knee = [maxf(0.0, -cos(ph)) * 0.9, maxf(0.0, cos(ph)) * 0.9]
			arm = [-sin(ph) * 0.7, sin(ph) * 0.7]
			lean = -0.15
			bob = absf(sin(ph)) * 0.06
		"fall":
			leg = [0.4 + sin(t * 9.0) * 0.25, -0.3 + sin(t * 8.0) * 0.25]
			knee = [0.5, 0.35]
			arm = [2.5 + sin(t * 10.0) * 0.3, 2.3 - sin(t * 9.0) * 0.3]
			arm_out = [0.4, 0.4]
		"lie":
			body_rot = Vector3(0, 0, PI * 0.5)
			bob = -0.72
			arm = [0.3, -0.2]
			knee = [0.3, 0.1]
		"climb":
			var cl := t * 5.0
			arm = [2.6 + sin(cl) * 0.4, 2.6 - sin(cl) * 0.4]
			leg = [sin(cl) * 0.4, -sin(cl) * 0.4]
			knee = [0.5 + sin(cl) * 0.3, 0.5 - sin(cl) * 0.3]
		"roll":
			leg = [1.5, 1.5]
			knee = [2.1, 2.1]
			arm = [1.2, 1.2]
			bob = -0.3
		"kneel_point":
			leg = [1.4, -0.3]
			knee = [1.5, 2.1]
			bob = -0.4
			arm = [2.9 + sin(t * 2.0) * 0.05, 0.2]                 # Near arm points at the sky
		"menace":                                                   # Bosses: a slow, heavy sway, arms ready
			bob = sin(t * 1.4) * 0.04
			lean = -0.1 + sin(t * 1.4) * 0.04
			arm = [0.6 + sin(t * 1.4) * 0.15, 0.4 - sin(t * 1.4) * 0.15]
			arm_out = [0.3, 0.3]
		_:                                                          # idle: breathing, a little sway
			bob = sin(t * 2.0) * 0.02
			arm = [0.12 + sin(t * 2.0) * 0.05, -0.08 - sin(t * 2.0) * 0.05]
			arm_out = [0.1, 0.1]
	for i in 2:
		_legs[i].rotation = Vector3(0, 0, leg[i])
		_knees[i].rotation = Vector3(0, 0, -knee[i])
		_arms[i].rotation = Vector3(arm_out[i] * (-1.0 if i == 0 else 1.0), 0, arm[i])
	body.position = Vector3(0, 0.95 + bob, 0)
	body.rotation = body_rot + Vector3(0, 0, lean + spin - hunch)
