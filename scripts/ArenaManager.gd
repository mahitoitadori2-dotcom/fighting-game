class_name ArenaManager
extends Node2D
## Put ONE of these in every arena scene. On start it spawns:
##   P1 = YOUR character (keyboard)      at p1_spawn
##   P2 = the OPPONENT (CPU) or the Dummy at p2_spawn
## The arenas (2 Versus arenas + every Story Mode map) are listed in MapCatalog.entries().

## Survives scene changes (static). An id from MapCatalog ("test", "void", "story_<map>").
static var selected_arena := "test"
## AI vs AI: set true and P1 is also driven by its character's AI.
static var p1_cpu := false

@export var p1_spawn := Vector2(426, 520)
@export var p2_spawn := Vector2(726, 520)

var p1: Fighter
var p2: Fighter


static func arena_entry(id: String) -> Dictionary:
	return MapCatalog.entry(id)


static func selected_arena_entry() -> Dictionary:
	return arena_entry(selected_arena)


func _ready() -> void:
	add_to_group("arena_manager")
	OptimizationManager.clear_pools()        # New match: drop the last match's pools + particle bookkeeping
	p1 = _spawn(CharacterRoster.selected(), 1, p1_spawn)
	p2 = _spawn(CharacterRoster.opponent(), 2, p2_spawn)
	# Music: boss track vs PvE enemies, fight track otherwise (speeds up when you're low on HP)
	# (Fights-mode bosses each have their own track: boss_minos / boss_sisyphus / boss_geyron)
	var opp := CharacterRoster.opponent()
	SoundManager.play_music(String(opp.get("music", "boss")) if opp.get("enemy", false) else "fight")
	SoundManager.play_sfx("spawn")
	# Lives, "ROUND 1 - FIGHT", winner screen
	var mm := MatchManager.new()
	mm.name = "MatchManager"
	add_child(mm)
	mm.setup(p1, p2)
	# Mobile: on-screen joystick + buttons (Match Settings > Touch Controls: AUTO / ON / OFF)
	if MatchSettings.touch_enabled():
		var tc := TouchControls.new()
		tc.name = "TouchControls"
		add_child(tc)
	# Sandbox > FPS Counter
	if MatchSettings.fps_counter_active():
		var fps := FpsCounter.new()
		fps.name = "FpsCounter"
		add_child(fps)


func _spawn(entry: Dictionary, slot: int, pos: Vector2) -> Fighter:
	var script: Script = entry.get("fighter", Dummy)
	var f := script.new() as Fighter
	if f == null:
		push_error("ArenaManager: '%s' is not a Fighter script" % entry.get("id", "?"))
		return null
	f.name = "P%d_%s" % [slot, entry.get("short", "Fighter")]
	f.position = pos
	f.slot = slot
	f.team = slot                     # 1v1: each side is its own team (helpers join their owner's team)
	f.default_facing = 1 if slot == 1 else -1
	f.facing = f.default_facing
	if f is ControlledFighter:
		# P1 = you on the keyboard, P2 = CPU (that character's own AI brain).
		var cpu := slot == 2 or p1_cpu
		if cpu:
			var ai_script: Script = entry.get("ai", BaseAI)
			(f as ControlledFighter).ctl = ai_script.new()
		else:
			(f as ControlledFighter).ctl = FighterInput.new()
	add_child(f)
	return f
