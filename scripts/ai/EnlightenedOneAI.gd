class_name EnlightenedOneAI
extends BaseAI
## CPU brain for The Enlightened One: a careful zoner who knows his WEAKNESS.
##   - Keeps distance and zones with Beam Blast
##   - Lord's Heal when below 60% HP
##   - Helpers! when the enemy is mid-range
##   - G: 1 bar Godly O' Light when the enemy is in line / 2 bars Throne when far /
##        3 bars Gorilla Form when close, then RUSHES and spams M1s
##   - WEAKNESS-AWARE: actively dodges explosions and void (HNCT bombs, Void Goo,
##     incoming rockets, Shadow Swarm, Eternal Grasp, the Nightmare Heart)

const PREFERRED_MIN := 260.0
const PREFERRED_MAX := 420.0

var dodge_chance := 0.75         # Much higher than a normal reaction: he respects his weakness
var _dodge_timer := 0.0
var _dodge_dir := 0.0
var _dodge_hold := 0.0


func think() -> void:
	var eo := f as EnlightenedOne
	if eo != null and eo.is_gorilla():
		# GORILLA FORM: only M1s. Rush in and spam.
		if dist > 80.0:
			approach()
		if dist < 115.0 and chance(0.75):
			press("attack")
		return

	if try_block(170.0):
		return

	# --- Lord's Heal under 60% HP ---
	if hp_ratio() < 0.6 and cd_ready("heal") and chance(0.55):
		press_now("move2")
		return

	# --- Ultimates ---
	var b := bars()
	var in_line := absf(enemy.global_position.y - f.global_position.y) < 60.0
	if b == 1 and in_line and dist < 1000.0 and chance(0.4):
		press("ultimate")                         # Godly O' Light
		return
	if b == 2 and dist > 350.0 and chance(0.4):
		press("ultimate")                         # Throne
		return
	if b >= 3 and dist < 220.0 and chance(0.45):
		press("ultimate")                         # Gorilla Form
		return

	# --- Helpers! at mid range ---
	if cd_ready("helpers") and dist > 200.0 and dist < 520.0 and chance(0.4):
		press("move3")
		return

	# --- Beam Blast to zone ---
	if cd_ready("beam") and dist > 150.0 and dist < 750.0 and chance(0.45):
		press("move1")
		return

	# --- Punch when close, otherwise keep the distance ---
	if dist < 90.0:
		if chance(0.4):
			press("attack")
		elif chance(0.45):
			retreat()
		return
	if dist > PREFERRED_MAX:
		approach()
	elif dist < PREFERRED_MIN and chance(0.6):
		retreat()
	elif chance(0.2):
		approach()


# ============================================================
# DODGING (every frame): explosions + void hurt him x1.25
# ============================================================
func react(delta: float) -> void:
	var eo := f as EnlightenedOne
	if eo != null and eo.is_gorilla():
		return                                    # Gorilla: no fear
	if _dodge_hold > 0.0:
		_dodge_hold -= delta
		_move_dir = _dodge_dir
		return
	_dodge_timer -= delta
	if _dodge_timer > 0.0:
		return
	_dodge_timer = 0.12                           # Small reaction delay
	var d := _find_danger()
	if d == 0.0 or not chance(dodge_chance):
		return
	_dodge_dir = d
	_dodge_hold = 0.8 if f.goo_timer > 0.0 else 0.35   # Slowed by goo: commit to walking out
	_move_dir = d


## Returns the direction to move to escape danger (-1 / +1), or 0 if safe.
func _find_danger() -> float:
	var me := f.global_position
	var tree := f.get_tree()

	# Standing in / walking into enemy Void Goo
	for n in tree.get_nodes_in_group("void_goo"):
		var g := n as VoidGoo
		if g == null or g.source == f:
			continue
		var half := g.width * 0.5 + 40.0
		var dx := me.x - g.global_position.x
		if absf(dx) < half and absf(me.y - g.global_position.y) < 80.0:
			return 1.0 if dx >= 0.0 else -1.0     # Out the nearest side

	# Armed HNCT bombs close by (explosion)
	for n in tree.get_nodes_in_group("hnct"):
		var bmb := n as TriangleBomb
		if bmb == null or bmb.source == f:
			continue
		var dx := me.x - bmb.global_position.x
		if absf(dx) < 110.0 and absf(me.y - bmb.global_position.y) < 80.0:
			if f.is_on_floor() and absf(dx) < 70.0 and chance(0.5):
				press_now("jump")                 # Hop over it
			return 1.0 if dx >= 0.0 else -1.0

	# Incoming rockets (explosion): jump or back off
	for n in tree.get_nodes_in_group("rockets"):
		var r := n as Rocket
		if r == null or r.source == f:
			continue
		var to_me := me + Vector2(0, -64) - r.global_position
		if to_me.length() < 260.0 and r.dir.dot(to_me.normalized()) > 0.5:
			if f.is_on_floor():
				press_now("jump")
			return 1.0 if to_me.x >= 0.0 else -1.0

	# The Nightmare Heart about to explode
	for n in tree.get_nodes_in_group("nightmare_heart"):
		var h := n as Node2D
		var dx := me.x - h.global_position.x
		if absf(dx) < 360.0:
			return 1.0 if dx >= 0.0 else -1.0

	# Warrior void attacks: Shadow Swarm charging in front of us / Eternal Grasp nearby
	var w := enemy as Warrior
	if w != null:
		var dx := me.x - w.global_position.x
		if w.state == Warrior.State.ETERNAL and absf(dx) < 220.0:
			return 1.0 if dx >= 0.0 else -1.0
		if w.state == Warrior.State.BEAM_CHARGE and signf(dx) == float(w.facing) and absf(dx) < 900.0:
			block_for(0.6)                        # The beam is blockable from the front
			return 0.0
	return 0.0
