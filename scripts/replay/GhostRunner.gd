class_name GhostRunner
extends Node
## BOSS RUSH GHOST: a see-through puppet of your BEST run, replaying that boss fight next to you.
## It can't hit or be hit, the camera and the bosses ignore it.

const GHOST_FILE := "user://bossrush_ghost_%s.ubr"

var puppet: Fighter
var frames: Array = []
var _i := 0
var _acc := 0.0


## Spawns the ghost for the current Boss Rush fight, if your best run has one for it.
static func spawn_for(manager: Node, hero: String, boss_index: int, order: Array[int]) -> GhostRunner:
	var path := GHOST_FILE % hero
	if not FileAccess.file_exists(path):
		return null
	var d := Replay.load_file(path)
	if d.is_empty() or Array(d.get("levels", [])) != Array(order):
		return null                                  # Different boss list (Story went on): no ghost
	var tracks: Array = d.get("tracks", [])
	if boss_index >= tracks.size() or (tracks[boss_index] as Array).is_empty():
		return null
	var f: Fighter
	if hero == "architect":
		f = Player.new()
	else:
		f = Warrior.new()
	f.name = "Ghost"
	f.slot = 9
	f.team = 1
	if f is ControlledFighter:
		(f as ControlledFighter).ctl = FighterInput.new()
	manager.add_child(f)
	for g in f.get_groups():
		if not String(g).begins_with("_"):
			f.remove_from_group(g)                   # Not a fighter for the camera / AI / HUD
	Replay.make_puppet(f)
	f.modulate = Color(0.55, 0.8, 1.0, 0.38)
	f.z_index = -1
	var gr := GhostRunner.new()
	gr.puppet = f
	gr.frames = tracks[boss_index]
	manager.add_child(gr)
	return gr


func _ready() -> void:
	process_mode = Node.PROCESS_MODE_PAUSABLE


func _physics_process(delta: float) -> void:
	if puppet == null or not is_instance_valid(puppet) or _i >= frames.size():
		if puppet != null and is_instance_valid(puppet) and _i >= frames.size():
			puppet.visible = false                    # Your best run had already won this fight
		return
	_acc += delta
	while _acc >= 1.0 / Replay.HZ and _i < frames.size():
		_acc -= 1.0 / Replay.HZ
		var fr: Dictionary = frames[_i]
		if fr.has(0):
			Replay.apply(puppet, fr[0])
		_i += 1
	puppet.modulate.a = 0.38


## Saves the ghost of a finished run (one track per boss).
static func save_best(hero: String, order: Array[int], tracks: Array) -> void:
	var f := FileAccess.open_compressed(GHOST_FILE % hero, FileAccess.WRITE, FileAccess.COMPRESSION_ZSTD)
	if f == null:
		return
	f.store_var({"version": Replay.VERSION, "levels": Array(order), "tracks": tracks})
	f.close()
