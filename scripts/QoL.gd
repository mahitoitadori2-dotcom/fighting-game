class_name QoL
extends RefCounted
## QUALITY OF LIFE settings (saved in user://qol.cfg, loaded at boot by the Graphics autoload):
##   screen shake  FULL / REDUCED / OFF          (Effects.shake)
##   reduce flashes                              (no white impact flash on the attacker)
##   dialogue speed NORMAL / FAST / INSTANT      (DialogueBox typing)
##   fullscreen                                  (desktop: also F11 / Alt+Enter; web: the browser's fullscreen)
## And REMEMBERED PICKS: your fighter, the opponent and the arena come back next time you play.

const PATH := "user://qol.cfg"
const SHAKE_NAMES := ["FULL", "REDUCED", "OFF"]
const SHAKE_MULT := [1.0, 0.4, 0.0]
const SPEED_NAMES := ["NORMAL", "FAST", "INSTANT"]
const SPEED_MULT := [1.0, 2.4, 1000.0]

static var shake := 0
static var reduce_flashes := false
static var text_speed := 0
static var fullscreen := false
static var _loaded := false


static func load_settings() -> void:
	if _loaded:
		return
	_loaded = true
	var c := ConfigFile.new()
	if c.load(PATH) != OK:
		return
	shake = clampi(int(c.get_value("qol", "shake", 0)), 0, 2)
	reduce_flashes = bool(c.get_value("qol", "reduce_flashes", false))
	text_speed = clampi(int(c.get_value("qol", "text_speed", 0)), 0, 2)
	fullscreen = bool(c.get_value("qol", "fullscreen", false))
	# Remembered picks (only if they still exist in this version of the game)
	var you := String(c.get_value("picks", "you", ""))
	var opp := String(c.get_value("picks", "opponent", ""))
	var arena := String(c.get_value("picks", "arena", ""))
	if you != "" and String(CharacterRoster.get_entry(you).get("id", "")) == you:
		CharacterRoster.selected_id = you
	if opp == "" or String(CharacterRoster.get_entry(opp).get("id", "")) == opp:
		CharacterRoster.opponent_id = opp
	if arena != "" and String(MapCatalog.entry(arena).get("id", "")) == arena:
		ArenaManager.selected_arena = arena


static func save_settings() -> void:
	var c := ConfigFile.new()
	c.load(PATH)
	c.set_value("qol", "shake", shake)
	c.set_value("qol", "reduce_flashes", reduce_flashes)
	c.set_value("qol", "text_speed", text_speed)
	c.set_value("qol", "fullscreen", fullscreen)
	c.save(PATH)


## Remember who / where you picked (Main Menu and the start of every Versus fight call this).
static func save_picks() -> void:
	if ArenaManager.p1_cpu or StoryManager.autoplay:
		return                                       # CPU test runs never overwrite your picks
	var c := ConfigFile.new()
	c.load(PATH)
	c.set_value("picks", "you", CharacterRoster.selected_id)
	c.set_value("picks", "opponent", CharacterRoster.opponent_id)
	c.set_value("picks", "arena", ArenaManager.selected_arena)
	c.save(PATH)


static func shake_mult() -> float:
	return SHAKE_MULT[shake]


static func text_mult() -> float:
	return SPEED_MULT[text_speed]


## Fullscreen is offered everywhere except iPhones (Safari can't make a page fullscreen).
static func fullscreen_available() -> bool:
	return not OS.has_feature("web_ios")


static func set_fullscreen(on: bool) -> void:
	fullscreen = on
	save_settings()
	apply_fullscreen()


static func apply_fullscreen() -> void:
	if not fullscreen_available():
		return
	var want := DisplayServer.WINDOW_MODE_FULLSCREEN if fullscreen else DisplayServer.WINDOW_MODE_WINDOWED
	if DisplayServer.window_get_mode() != want:
		DisplayServer.window_set_mode(want)
