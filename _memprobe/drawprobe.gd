extends Node

func _ready() -> void:
	if get_parent() != get_tree().root or name != "DrawProbe":
		var s := Node.new()
		s.set_script(get_script())
		s.name = "DrawProbe"
		get_tree().root.add_child.call_deferred(s)
		return
	process_mode = Node.PROCESS_MODE_ALWAYS
	get_tree().create_timer(120.0, true, false, true).timeout.connect(func() -> void: get_tree().quit())
	_run.call_deferred()


func _w(s: float) -> void:
	await get_tree().create_timer(s, true, false, true).timeout


func _measure(label: String) -> void:
	var tot := 0.0
	var fps := 0.0
	for i in 20:
		await get_tree().process_frame
		tot += Performance.get_monitor(Performance.RENDER_TOTAL_DRAW_CALLS_IN_FRAME)
		fps += Performance.get_monitor(Performance.TIME_FPS)
	print("P %-34s draws=%d fps=%d" % [label, int(tot / 20.0), int(fps / 20.0)])


func _set_vis(root: Node, cls: String, on: bool) -> void:
	for n in root.get_children():
		if n.get_script() != null and String(n.get_script().get_global_name()) == "" and n.get_class() == "Node2D" and cls == "strip" and n.has_method("_draw") and "items" in n:
			(n as CanvasItem).visible = on
		elif cls == "animals" and n is Animal:
			(n as CanvasItem).visible = on
		elif cls == "hud" and n is Animal:
			var h = n.get("hud")
			if h != null:
				h.visible = on


func _run() -> void:
	DisplayServer.window_set_vsync_mode(DisplayServer.VSYNC_DISABLED)
	Engine.max_fps = 0
	StoryManager.autoplay = true
	OrdLand.test_steer = false
	StoryProgress.load_progress()
	for spot in [["meadow", -6400.0], ["town", -1500.0], ["jungle", 700.0]]:
		StoryProgress.current_level = 71
		get_tree().change_scene_to_file("res://scenes/OrdLand.tscn")
		await _w(9.0)
		var m := get_tree().current_scene.get_node("StoryManager") as OrdLand
		m.player.global_position.x = float(spot[1])
		await _w(3.0)
		await _measure("%s all" % spot[0])
		_set_vis(m, "strip", false)
		await _measure("%s - props" % spot[0])
		_set_vis(m, "strip", true)
		_set_vis(m, "hud", false)
		await _measure("%s - animal HUDs" % spot[0])
		_set_vis(m, "animals", false)
		await _measure("%s - animals" % spot[0])
		_set_vis(m, "animals", true)
		_set_vis(m, "hud", true)
		var g := get_tree().current_scene.get_node("ArenaGround") as CanvasItem
		g.visible = false
		await _measure("%s - ground" % spot[0])
		g.visible = true
		var bg := get_tree().current_scene.get_node("Background") as CanvasLayer
		bg.visible = false
		await _measure("%s - backdrop" % spot[0])
		bg.visible = true
		var hud := m.get("_hud") as Node
		if hud:
			hud.set("visible", false)
			await _measure("%s - story HUD" % spot[0])
	get_tree().quit()