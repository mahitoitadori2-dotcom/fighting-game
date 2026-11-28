class_name RedConsole
extends CanvasLayer
## THE RED CONSOLE (2026-11-21, by the user): press F12 during ANY level (Versus, Training, Story,
## The Abandoned Town, Madness) to open it; type a SPECIAL COMMAND, ENTER runs it. F12 / Esc closes.
## The game is FROZEN while it is open. Opened by GraphicsSettings (the always-there autoload).
## Looks like the XANXXE panel: black, red grid + scanlines, red text, a blinking cursor.
##
## ADDING A COMMAND: one line in COMMANDS ("name": [method, "help text"]) + a func _cmd_<name>(args).
## Names may have spaces ("what time is it"); typing ignores capitals, "?" and "!".
##
## SPECIAL COMMANDS (by the user, 2026-11-21):
##   #s001       BLACK GHOST: you turn into a black ghost, every move that has an Onslaught version
##               goes off as its Onslaught (Fighter.console_onslaught)
##   #s002       a CPU CLONE of you fights beside you
##   #s003       CORRUPTED + IMMORTAL, but BLINDED: the screen is gone, your inputs still work
##   normalize   turns off Madness and every code + console effect that is active
##   rotor       a picture of Rotor, the game paused behind it for 3 seconds
##   jumpscare   Rotor. Suddenly. Loudly.
##   boo         closes the panel (same as exit)
##   hi / what time is it (a random country) / + small talk: ping, coin, dice, joke, whoami, date...
##   cutscene <capture|timestop|free|bridge>   watch a cutscene of THE LAST STRETCH right now (2026-11-28)
##   level <139-148>                           jump straight into a level of THE LAST STRETCH (no unlocking)

## While MADNESS is on (2026-11-22, by the user) the console refuses most commands. Only these get through -
## normalize (the way out), rotor + jumpscare (they SCARE XANXXE: MadnessPresence.scare), and closing.
const MADNESS_ALLOWS := ["normalize", "rotor", "jumpscare", "exit", "boo", "clear"]
const REFUSALS := ["XANXXE> no.", "XANXXE> I don't take orders.", "XANXXE> access denied, mortal.",
	"XANXXE> that command belongs to me now.", "XANXXE> try again. it won't help.", "XANXXE> ...no."]
const COMMANDS := {
	"help": ["_cmd_help", "list the commands"],
	"cutscene": ["_cmd_cutscene", "cutscene <capture|timestop|free|bridge>  -  watch a Last Stretch cutscene"],
	"level": ["_cmd_level", "level <139-148>  -  jump into a Last Stretch level"],
	"#s001": ["_cmd_s001", "BLACK GHOST: every move with an Onslaught goes off as its Onslaught"],
	"#s002": ["_cmd_s002", "a CPU clone of you joins the fight"],
	"#s003": ["_cmd_s003", "CORRUPTED + IMMORTAL... but blind"],
	"normalize": ["_cmd_normalize", "turn off Madness and every active code / effect"],
	"rotor": ["_cmd_rotor", "a picture of Rotor (the game pauses 3 s)"],
	"jumpscare": ["_cmd_jumpscare", "don't"],
	"boo": ["_cmd_exit", "close the panel"],
	"hi": ["_cmd_hi", "say hi"],
	"hello": ["_cmd_hi", "say hello"],
	"what time is it": ["_cmd_time", "the time somewhere in the world"],
	"ping": ["_cmd_ping", "pong"],
	"coin": ["_cmd_coin", "flip a coin"],
	"dice": ["_cmd_dice", "roll a die"],
	"joke": ["_cmd_joke", "a joke (a bad one)"],
	"whoami": ["_cmd_whoami", "who you are right now"],
	"who are you": ["_cmd_whoareyou", "who the console is"],
	"date": ["_cmd_date", "today's date"],
	"version": ["_cmd_version", "the game version"],
	"fps": ["_cmd_fps", "frames per second right now"],
	"thanks": ["_cmd_thanks", "you're welcome"],
	"sudo": ["_cmd_sudo", "nice try"],
	"status": ["_cmd_status", "where you are + your fighter's health"],
	"echo": ["_cmd_echo", "echo <text>  -  repeats the text"],
	"clear": ["_cmd_clear", "clear the screen"],
	"exit": ["_cmd_exit", "close the console (also F12 / Esc / boo)"],
}
## "what time is it": a random place + its UTC offset (standard time).
const PLACES := [["Tokyo", "Japan", 9.0], ["Warsaw", "Poland", 1.0], ["New York", "USA", -5.0], ["London", "the UK", 0.0],
	["Sydney", "Australia", 10.0], ["Rio de Janeiro", "Brazil", -3.0], ["Cairo", "Egypt", 2.0], ["Mumbai", "India", 5.5],
	["Moscow", "Russia", 3.0], ["Los Angeles", "USA", -8.0], ["Reykjavik", "Iceland", 0.0], ["Kathmandu", "Nepal", 5.75],
	["Auckland", "New Zealand", 12.0], ["Mexico City", "Mexico", -6.0], ["Seoul", "South Korea", 9.0], ["Nairobi", "Kenya", 3.0]]
const JOKES := ["Why did the Warrior bring a ladder? The boss was on the next level.",
	"Rotor tried to fetch the Fetch Bomb. Once.", "The Architect builds everything. Except confidence.",
	"I would tell you a UDP joke, but you might not get it.", "XX0XN asked for a dance. Nobody said yes. Nobody survived."]
const RED := Color(0.95, 0.10, 0.07)
const RED_DIM := Color(0.40, 0.03, 0.03)

static var history: Array[String] = []           # Commands typed this session (UP / DOWN)
var _log: RichTextLabel
var _edit: LineEdit
var _canvas: Control
var _was_paused := false
var _hist_i := -1
var _t := 0.0


## F12: open in a level, close if open. Returns true if it did something.
static func toggle(tree: SceneTree) -> bool:
	var open := tree.root.get_node_or_null("RedConsole") as RedConsole
	if open != null:
		open.close()
		return true
	if not in_level(tree):
		return false
	var c := RedConsole.new()
	c.name = "RedConsole"
	tree.root.add_child(c)
	return true


## A level = a scene with a fight director (Versus / Training: ArenaManager, Story / Madness: StoryManager).
static func in_level(tree: SceneTree) -> bool:
	return tree.get_first_node_in_group("arena_manager") != null or tree.get_first_node_in_group("story_manager") != null


func _ready() -> void:
	layer = 220
	process_mode = Node.PROCESS_MODE_ALWAYS
	_was_paused = get_tree().paused
	get_tree().paused = true
	_canvas = Control.new()
	_canvas.set_anchors_preset(Control.PRESET_TOP_WIDE)
	_canvas.anchor_bottom = 0.55
	_canvas.mouse_filter = Control.MOUSE_FILTER_STOP
	_canvas.draw.connect(_draw_bg)
	add_child(_canvas)
	var col := VBoxContainer.new()
	col.set_anchors_and_offsets_preset(Control.PRESET_FULL_RECT)
	col.offset_left = 22.0
	col.offset_right = -22.0
	col.offset_top = 16.0
	col.offset_bottom = -14.0
	_canvas.add_child(col)
	_log = RichTextLabel.new()
	_log.size_flags_vertical = Control.SIZE_EXPAND_FILL
	_log.scroll_following = true
	_log.bbcode_enabled = false
	_log.add_theme_font_size_override("normal_font_size", 18)
	_log.add_theme_color_override("default_color", RED)
	_log.mouse_filter = Control.MOUSE_FILTER_IGNORE
	col.add_child(_log)
	var row := HBoxContainer.new()
	col.add_child(row)
	var prompt := Label.new()
	prompt.text = "XANXXE://> "
	prompt.add_theme_font_size_override("font_size", 20)
	prompt.add_theme_color_override("font_color", RED)
	row.add_child(prompt)
	_edit = LineEdit.new()
	_edit.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	_edit.add_theme_font_size_override("font_size", 20)
	_edit.add_theme_color_override("font_color", Color(1.0, 0.35, 0.3))
	_edit.add_theme_color_override("caret_color", RED)
	var sb := StyleBoxFlat.new()
	sb.bg_color = Color(0.08, 0.0, 0.0, 0.9)
	sb.border_color = RED_DIM
	sb.set_border_width_all(2)
	_edit.add_theme_stylebox_override("normal", sb)
	_edit.add_theme_stylebox_override("focus", sb)
	_edit.text_submitted.connect(_submit)
	TextEntry.hook(_edit, "XANXXE://>", _submit)                    # Web phones: the browser's own input
	row.add_child(_edit)
	say("XANXXE 1NT3GR1T13S :: RED CONSOLE")
	_edit.grab_focus.call_deferred()
	SoundManager.play_sfx("ui_confirm", -6.0)


func _exit_tree() -> void:
	if get_tree() != null:
		get_tree().paused = _was_paused


func close() -> void:
	queue_free()


func say(text: String) -> void:
	_log.append_text(text + "\n")


func _process(delta: float) -> void:
	_t += delta
	_canvas.queue_redraw()


func _input(event: InputEvent) -> void:
	var k := event as InputEventKey
	if k == null or not k.pressed or k.echo:
		return
	match k.physical_keycode:
		KEY_ESCAPE:
			get_viewport().set_input_as_handled()
			close()
		KEY_UP, KEY_DOWN:
			if history.is_empty():
				return
			get_viewport().set_input_as_handled()
			_hist_i = clampi((_hist_i if _hist_i >= 0 else history.size()) + (-1 if k.physical_keycode == KEY_UP else 1), 0, history.size() - 1)
			_edit.text = history[_hist_i]
			_edit.caret_column = _edit.text.length()


## Runs one line (also used by tests).
func run(line: String) -> void:
	_submit(line)


func _submit(line: String) -> void:
	line = line.strip_edges()
	_edit.text = ""
	if line == "":
		return
	history.append(line)
	_hist_i = -1
	say("> " + line)
	var parts := line.split(" ", false)
	var cmd := parts[0].to_lower()
	var args := parts.slice(1)
	var whole := line.to_lower().replace("?", "").replace("!", "").strip_edges()
	if COMMANDS.has(whole):                              # Multi-word commands ("what time is it")
		cmd = whole
		args = PackedStringArray()
	Madness.load_data()
	if Madness.unlocked and not MADNESS_ALLOWS.has(cmd):    # MADNESS has the console now: it refuses
		say("  " + String(REFUSALS[randi() % REFUSALS.size()]))
		MadnessFX.glitch(get_tree(), 0.7)
		SoundManager.play_sfx("rumble", -8.0)
		return
	if not COMMANDS.has(cmd):
		say("  unknown command '%s'." % cmd)
		SoundManager.play_sfx("ui_back", -6.0)
		return
	if Madness.unlocked and cmd == "normalize":
		say("  XANXXE> ...fine. sleep. for now.")
	call(String(COMMANDS[cmd][0]), args)


# ============================================================
# COMMANDS
# ============================================================
func _cmd_help(_args: PackedStringArray) -> void:
	for n in COMMANDS:
		say("  %-8s %s" % [n, COMMANDS[n][1]])


func _cmd_clear(_args: PackedStringArray) -> void:
	_log.clear()


func _cmd_status(_args: PackedStringArray) -> void:
	var cs := get_tree().current_scene
	say("  scene: %s" % (cs.scene_file_path.get_file() if cs != null else "?"))
	var sm := get_tree().get_first_node_in_group("story_manager") as StoryManager
	if sm != null:
		say("  level: %s  -  %s" % [StoryLevels.level_label(sm.level_number), String(sm.level.get("title", ""))])
	for n in get_tree().get_nodes_in_group("fighters"):
		var f := n as Fighter
		if f != null and f.slot == 1 and f.data != null:
			say("  you: %s  HP %d / %d" % [f.data.character_name, f.hp, f.data.max_hp])


## THE LAST STRETCH: watch one of its cutscenes now, on top of whatever is running (nothing is saved).
func _cmd_cutscene(args: PackedStringArray) -> void:
	var which := args[0].to_lower() if args.size() > 0 else ""
	var lv := {"capture": 142, "timestop": 147, "free": 148, "bridge": 148}
	if not lv.has(which):
		say("  cutscene capture | timestop | free | bridge")
		return
	say("  playing ls_%s..." % which)
	close()
	var cs := StoryCutscene.new()
	cs.kind = "ls_" + which
	cs.level = int(lv[which])
	cs.hero_art = ArchitectArt
	var was := get_tree().paused
	get_tree().paused = true                                  # The fight behind it waits (the cutscene always runs)
	get_tree().root.add_child(cs)
	await cs.finished
	cs.queue_free()
	get_tree().paused = was


## THE LAST STRETCH: start one of its levels directly (no unlocking; clearing it saves like any level).
func _cmd_level(args: PackedStringArray) -> void:
	var n := int(args[0]) if args.size() > 0 else 0
	if n < LevelsLastStretch.FIRST or n > LevelsLastStretch.LAST:
		say("  level %d-%d" % [LevelsLastStretch.FIRST, LevelsLastStretch.LAST])
		return
	say("  to level %d..." % n)
	close()
	get_tree().paused = false
	StoryProgress.current_level = n
	StoryManager.boss_retry = 0
	get_tree().change_scene_to_file(StoryManager.ARENA_SCENE)


func _cmd_echo(args: PackedStringArray) -> void:
	say("  " + " ".join(args))


func _cmd_exit(_args: PackedStringArray) -> void:
	close()


# ---------------- SPECIAL COMMANDS ----------------
func _player() -> Fighter:
	for n in get_tree().get_nodes_in_group("fighters"):
		var f := n as Fighter
		if f != null and f.slot == 1 and not f.is_dead:
			return f
	return null


func _cmd_s001(_args: PackedStringArray) -> void:
	var f := _player()
	if f == null:
		say("  no fighter to haunt.")
		return
	var on := not bool(f.get_meta("console_ghost", false))
	f.set_meta("console_ghost", on)
	if f is ControlledFighter:
		(f as ControlledFighter).console_onslaught = on
	if f.pixel_group != null:
		f.pixel_group.modulate = Color(0.05, 0.04, 0.06, 0.85) if on else Color.WHITE
	say("  #s001  BLACK GHOST: " + ("ON. every move with an Onslaught goes off as one." if on else "OFF."))
	SoundManager.play_sfx("console_pierce", 0.0, 0.0)          # Deep-fried PIERCING stab (tools/make_console_sfx.js)


func _cmd_s002(_args: PackedStringArray) -> void:
	var f := _player() as ControlledFighter
	if f == null:
		say("  nothing to clone.")
		return
	var script: Script = f.get_script()
	var clone := script.new() as ControlledFighter
	var ai: Script = WarriorAI
	for e in CharacterRoster.all():
		if e.get("fighter", null) == script:
			ai = e.get("ai", WarriorAI)
	if script == Player:
		ai = ArchitectAI
	clone.ctl = ai.new()
	clone.name = "ConsoleClone"
	clone.slot = 3
	clone.team = f.team
	clone.respawn_enabled = false
	clone.default_facing = f.facing
	clone.facing = f.facing
	clone.position = f.position + Vector2(-90.0 * float(f.facing), -10.0)
	clone.add_to_group("console_clone")
	f.get_parent().add_child(clone)
	Effects.gold_burst(clone, clone.global_position + Vector2(0, -60), 80.0)
	say("  #s002  a clone of you joins the fight. (CPU)")
	SoundManager.play_sfx("console_gunshot", 0.0, 0.0)         # Deep-fried GUNSHOT


func _cmd_s003(_args: PackedStringArray) -> void:
	var f := _player()
	if f == null:
		say("  nobody to corrupt.")
		return
	f.set_meta("console_corrupt", true)
	f.damage_taken_mult = 0.0
	if f.pixel_group != null:
		f.pixel_group.modulate = Madness.TINT
	if get_tree().root.get_node_or_null("ConsoleBlind") == null:
		var b := Blind.new()
		b.name = "ConsoleBlind"
		get_tree().root.add_child(b)
	say("  #s003  CORRUPTED. IMMORTAL. ...where did the screen go?")
	SoundManager.say("xx0xn_hank", "HAAAANK")                   # The deep-fried XX0XN yell
	say("  (type 'normalize' to see again)")


func _cmd_normalize(_args: PackedStringArray) -> void:
	# Madness off (its progress is kept: the XANXXE code turns it back on)
	Madness.load_data()
	Madness.unlocked = false
	Madness.save_data()
	SoundManager.set_madness(false)
	for g in ["madness_filter", "madness_hack"]:
		for n in get_tree().get_nodes_in_group(g):
			n.queue_free()
	# The other codes
	SecretCodes.load_codes()
	SecretCodes.bug_tester = false
	SecretCodes.rotor_mode = false
	SecretCodes.save_codes()
	DebugOverlay.set_shown(get_tree(), false)
	# Console effects
	for n in get_tree().get_nodes_in_group("console_clone"):
		n.queue_free()
	var blind := get_tree().root.get_node_or_null("ConsoleBlind")
	if blind != null:
		blind.queue_free()
	for n in get_tree().get_nodes_in_group("fighters"):
		var f := n as Fighter
		if f == null or not (f.has_meta("console_ghost") or f.has_meta("console_corrupt")):
			continue
		f.remove_meta("console_ghost")
		f.remove_meta("console_corrupt")
		f.damage_taken_mult = 1.0
		if f is ControlledFighter:
			(f as ControlledFighter).console_onslaught = false
		if f.pixel_group != null:
			f.pixel_group.modulate = Color.WHITE
	say("  NORMALIZED. Madness off, every code off, every effect gone.")
	SoundManager.play_sfx("holy", -6.0)


func _cmd_rotor(_args: PackedStringArray) -> void:
	RotorPicture.show_picture(get_tree(), false)
	MadnessPresence.scare(get_tree(), 3.3)                # XANXXE is afraid of him
	close()


func _cmd_jumpscare(_args: PackedStringArray) -> void:
	RotorPicture.show_picture(get_tree(), true)
	MadnessPresence.scare(get_tree(), 1.6)
	close()


# ---------------- SMALL TALK ----------------
func _cmd_hi(_args: PackedStringArray) -> void:
	say("  Hi")


func _cmd_time(_args: PackedStringArray) -> void:
	var p: Array = PLACES[randi() % PLACES.size()]
	var t := Time.get_unix_time_from_system() + float(p[2]) * 3600.0
	var d := Time.get_datetime_dict_from_unix_time(int(t))
	say("  in %s, %s it is %02d:%02d." % [p[0], p[1], int(d["hour"]), int(d["minute"])])


func _cmd_ping(_args: PackedStringArray) -> void:
	say("  pong")


func _cmd_coin(_args: PackedStringArray) -> void:
	say("  " + ("HEADS" if randf() < 0.5 else "TAILS"))


func _cmd_dice(_args: PackedStringArray) -> void:
	say("  you rolled a %d" % (randi() % 6 + 1))


func _cmd_joke(_args: PackedStringArray) -> void:
	say("  " + String(JOKES[randi() % JOKES.size()]))


func _cmd_whoami(_args: PackedStringArray) -> void:
	var f := _player()
	say("  " + (f.data.character_name if f != null and f.data != null else "nobody. yet."))


func _cmd_whoareyou(_args: PackedStringArray) -> void:
	say("  the red console. I read everything you type.")


func _cmd_date(_args: PackedStringArray) -> void:
	say("  " + Time.get_date_string_from_system())


func _cmd_version(_args: PackedStringArray) -> void:
	say("  Universal Beatdown " + String(preload("res://scripts/ui/MainMenu.gd").VERSION))


func _cmd_fps(_args: PackedStringArray) -> void:
	say("  %d fps" % Engine.get_frames_per_second())


func _cmd_thanks(_args: PackedStringArray) -> void:
	say("  you're welcome.")


func _cmd_sudo(_args: PackedStringArray) -> void:
	say("  permission denied. nice try.")


## #s003: the screen is gone - only static and red noise. Inputs still reach the game.
class Blind extends CanvasLayer:
	var _c: Control
	var _t := 0.0

	func _ready() -> void:
		layer = 150                                          # Over the HUD, under the console (220)
		process_mode = Node.PROCESS_MODE_ALWAYS
		_c = Control.new()
		_c.set_anchors_and_offsets_preset(Control.PRESET_FULL_RECT)
		_c.mouse_filter = Control.MOUSE_FILTER_IGNORE
		_c.draw.connect(_draw_static)
		add_child(_c)

	func _process(delta: float) -> void:
		_t += delta
		_c.queue_redraw()

	func _draw_static() -> void:
		var sz := _c.size
		_c.draw_rect(Rect2(Vector2.ZERO, sz), Color(0, 0, 0))
		var rng := RandomNumberGenerator.new()
		rng.seed = int(_t * 30.0)
		for i in 160:
			var w := rng.randf_range(4.0, 60.0)
			_c.draw_rect(Rect2(rng.randf_range(0.0, sz.x), rng.randf_range(0.0, sz.y), w, rng.randf_range(2.0, 6.0)),
				Color(0.5, 0.0, 0.0, rng.randf_range(0.1, 0.5)) if rng.randf() < 0.5 else Color(0.2, 0.2, 0.2, rng.randf_range(0.05, 0.3)))
		var f := ThemeDB.fallback_font
		var msg := "S I G N A L   L O S T" if fmod(_t, 1.0) < 0.75 else ""
		var mw := f.get_string_size(msg, HORIZONTAL_ALIGNMENT_LEFT, -1, 42).x
		_c.draw_string(f, Vector2((sz.x - mw) * 0.5 + rng.randf_range(-6.0, 6.0), sz.y * 0.5), msg, HORIZONTAL_ALIGNMENT_LEFT, -1, 42, Color(0.9, 0.05, 0.04))


# ============================================================
# LOOK
# ============================================================
func _draw_bg() -> void:
	var c := _canvas
	var sz := c.size
	c.draw_rect(Rect2(Vector2.ZERO, sz), Color(0.0, 0.0, 0.0, 0.92))
	var g := 40.0
	var x := fmod(_t * 5.0, g)
	while x < sz.x:
		c.draw_rect(Rect2(floorf(x / 3.0) * 3.0, 0, 3, sz.y), Color(RED_DIM.r, RED_DIM.g, RED_DIM.b, 0.3))
		x += g
	var y := fmod(_t * 5.0, g)
	while y < sz.y:
		c.draw_rect(Rect2(0, floorf(y / 3.0) * 3.0, sz.x, 3), Color(RED_DIM.r, RED_DIM.g, RED_DIM.b, 0.3))
		y += g
	for sy in range(0, int(sz.y), 6):
		c.draw_rect(Rect2(0, sy, sz.x, 2), Color(0, 0, 0, 0.25))
	c.draw_rect(Rect2(0, sz.y - 3.0, sz.x, 3.0), RED)                    # The bottom edge
