extends Node
## Compiles EVERY .gd script of the game and prints "SCRIPT FAIL: <path>" for each one that
## doesn't compile, then "SCRIPT CHECK: <n> failed of <m>" and quits. Run as a SCENE (so the
## autoloads like SoundManager exist, else everything that uses them would look broken):
##
##   godot --headless --path . res://tools/check_scripts.tscn
##
## Used by tools/auto_push.ps1 so a broken script is never pushed (the website would break).

func _ready() -> void:
	var files: Array[String] = []
	_collect("res://", files)
	var failed := 0
	for path in files:
		var s := ResourceLoader.load(path, "GDScript") as GDScript
		if s == null or not s.can_instantiate():
			failed += 1
			print("SCRIPT FAIL: ", path)
	print("SCRIPT CHECK: %d failed of %d" % [failed, files.size()])
	get_tree().quit(1 if failed > 0 else 0)


func _collect(dir: String, out: Array[String]) -> void:
	for d in DirAccess.get_directories_at(dir):
		if d.begins_with(".") or d in ["addons", "build", "web", "web_shell", "vault"]:
			continue
		_collect(dir.path_join(d), out)
	for f in DirAccess.get_files_at(dir):
		if f.ends_with(".gd"):
			out.append(dir.path_join(f))
