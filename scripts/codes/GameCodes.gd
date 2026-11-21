class_name SecretCodes
extends RefCounted
## SECRET CODES (2026-11-21, by the user). (File name GameCodes.gd: the push script skips files named like "secret".) Every version of the game (PC builds + the web).
##
##   PHONES / TABLETS: a small CODE button in the corner of the Main Menu -> type the code.
##   PC (keyboard / controller): no button - press WASD or the ARROW keys (or the D-pad) in the
##   code's order while on the MAIN MENU.
##
##   CODE              PC ORDER    WHAT IT DOES
##   B0gT3ster         WDWDSASA    BUG TESTER: FPS, frame ms, process / physics ms, draw calls,
##                                 nodes and memory in the corner of the screen (on / off, saved)
##   R0t0rMode         DDWSDAWS    ROTOR MODE: you can ONLY play as Rotor in Versus fights (his own
##                                 code, hitbox and sprite; your controls drive his moves). On / off.
##   Fu11 lOO percen7  ASDWSDWA    100%: unlocks EVERY achievement, every enemy, and marks every
##                                 Story level beaten (asks first - it can't be undone)
##   XANXXE 1NT3GR1T13S: % 100.00  SSSDDDAAADDDWWWSAWD   THE BIGGEST ONE: the red control panel
##                                 (XanxxePanel) -> MADNESS (Madness.gd)
##
## Typed codes ignore capital letters and spaces. Toggles are saved in user://codes.cfg.

const PATH := "user://codes.cfg"
## Typed code (lowercase, no spaces) -> code id
const TYPED := {"b0gt3ster": "bug_tester", "r0t0rmode": "rotor_mode", "fu11loopercen7": "full_100",
	"xanxxe1nt3gr1t13s:%100.00": "xanxxe"}
## PC order (U = W / Up, L = A / Left, D = S / Down, R = D / Right) -> code id
const ORDERS := {"URURDLDL": "bug_tester", "RRUDRLUD": "rotor_mode", "LDRUDRUL": "full_100",
	"DDDRRRLLLRRRUUUDLUR": "xanxxe"}
const NAMES := {"bug_tester": "BUG TESTER", "rotor_mode": "ROTOR MODE", "full_100": "100% COMPLETE", "xanxxe": "XANXXE 1NT3GR1T13S"}

static var bug_tester := false
static var rotor_mode := false
static var _loaded := false
static var _keys := ""                              # The last directions pressed on the Main Menu


static func load_codes() -> void:
	if _loaded:
		return
	_loaded = true
	var c := ConfigFile.new()
	if c.load(PATH) != OK:
		return
	bug_tester = bool(c.get_value("codes", "bug_tester", false))
	rotor_mode = bool(c.get_value("codes", "rotor_mode", false))


static func save_codes() -> void:
	var c := ConfigFile.new()
	c.set_value("codes", "bug_tester", bug_tester)
	c.set_value("codes", "rotor_mode", rotor_mode)
	c.save(PATH)


## At start-up (GraphicsSettings): the Bug Tester overlay comes back if it was on.
static func boot(tree: SceneTree) -> void:
	load_codes()
	DebugOverlay.set_shown(tree, bug_tester)


## A typed code -> its id ("" = not a code).
static func match_typed(text: String) -> String:
	return String(TYPED.get(text.to_lower().replace(" ", "").strip_edges(), ""))


## Main Menu: one direction pressed ("U" / "D" / "L" / "R"). Returns a code id when an order is complete.
static func feed(dir: String) -> String:
	_keys = (_keys + dir).right(24)
	for order in ORDERS:                                 # (Orders have different lengths: the end must match)
		if _keys.ends_with(String(order)):
			_keys = ""
			return String(ORDERS[order])
	return ""


## Switch a toggle code (Bug Tester / Rotor Mode). Returns the message to show.
static func toggle(id: String, tree: SceneTree) -> String:
	load_codes()
	match id:
		"bug_tester":
			bug_tester = not bug_tester
			DebugOverlay.set_shown(tree, bug_tester)
			save_codes()
			return "BUG TESTER: " + ("ON  -  stats in the top-left corner" if bug_tester else "OFF")
		"rotor_mode":
			rotor_mode = not rotor_mode
			save_codes()
			return "ROTOR MODE: " + ("ON  -  you are Rotor in every Versus fight!" if rotor_mode else "OFF")
	return ""


## FU11 LOO PERCEN7: every achievement, every enemy met, every Story level beaten. Saved.
## SKINS: only GALAXY comes with it (it is an achievement reward). Frozen Expedition (the Crystal Swarm)
## and Assassin (The XX0XN) must still be earned in the game - this code never sets them.
static func unlock_everything() -> void:
	# Achievements (silently: no 300 toasts)
	Achievements.load_data()
	var now := int(Time.get_unix_time_from_system())
	for d in Achievements.defs():
		if not Achievements.unlocked.has(d["id"]):
			Achievements.unlocked[d["id"]] = now
	Achievements.save_data()
	# Every enemy met (they appear in Versus / Enemy Test). Entries without a story class are always there.
	StoryProgress.load_progress()
	for e in EnemyManager.entries():
		var cls := String(e.get("class", ""))
		if cls != "":
			StoryProgress.seen[cls] = true
	# Every Story level beaten: all parts, the optional levels, the lessons, the Boss Extensions
	StoryProgress.unlocked_level = StoryProgress.AVAILABLE_LEVELS
	StoryProgress.colosseums_done = maxi(StoryProgress.colosseums_done, StoryLevels.colosseum_of(StoryLevels.count()))
	for n in range(1, StoryLevels.count() + 1):
		if StoryLevels.is_optional(n) and not StoryProgress.optional_done.has(n):
			StoryProgress.optional_done.append(n)
		if StoryLevels.is_lesson(n) and not StoryProgress.lessons_done.has(n):
			StoryProgress.lessons_done.append(n)
	for k in StoryLevels.EXTENSIONS:
		StoryProgress.ext_done[k] = 3
	StoryProgress.current_level = StoryProgress.AVAILABLE_LEVELS
	StoryProgress.save_progress()
