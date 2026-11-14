extends Node

func _ready() -> void:
	StoryProgress.load_progress()
	var s := Node.new()
	s.set_script(load("res://_memprobe/sweeper.gd"))
	s.name = "Sweeper"
	get_tree().root.add_child.call_deferred(s)
