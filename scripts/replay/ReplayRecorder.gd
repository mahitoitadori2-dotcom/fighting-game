class_name ReplayRecorder
extends Node
## Records the tracked fighters 30x per second (only what changed) until stop().
## result() = {version, hz, arena, ids, frames}. frames[i] = {fighter_index: delta}.

var fighters: Array[Fighter] = []
var ids: Array[String] = []
var frames: Array = []
var recording := true
var max_seconds := 600.0
var _acc := 0.0
var _step := 1.0 / Replay.HZ
var _prev: Array[Dictionary] = []


func track(f: Fighter, id: String) -> void:
	if f == null:
		return
	fighters.append(f)
	ids.append(id)
	_prev.append({})


func _ready() -> void:
	process_mode = Node.PROCESS_MODE_PAUSABLE
	if OS.has_feature("web"):
		max_seconds = 120.0                 # Phones: keep the in-memory recording small
		_step = 1.0 / 20.0                  # ...and record 20x per second instead of 30 (cheaper)


func _physics_process(delta: float) -> void:
	if not recording:
		return
	_acc += delta
	if _acc < _step:
		return
	_acc -= _step
	var frame := {}
	for i in fighters.size():
		var f := fighters[i]
		if f == null or not is_instance_valid(f):
			continue
		var snap := Replay.capture(f)
		var delta_snap := {}
		var prev := _prev[i]
		for k in snap:
			if not prev.has(k) or prev[k] != snap[k]:
				delta_snap[k] = snap[k]
		if not delta_snap.is_empty():
			frame[i] = delta_snap
			for k in delta_snap:
				prev[k] = delta_snap[k]
	frames.append(frame)
	if frames.size() >= int(max_seconds * Replay.HZ):
		recording = false


func stop() -> void:
	recording = false


func result() -> Dictionary:
	return {"version": Replay.VERSION, "hz": 1.0 / _step, "arena": ArenaManager.selected_arena, "ids": ids.duplicate(), "frames": frames}
