class_name StoryModeSwitch
extends RefCounted
## The STORY | MADNESS switch at the top of the Story board and the Madness board (only once
## MADNESS is unlocked with the XANXXE code). Changes the whole map.

static func make(tree: SceneTree, current: String) -> HBoxContainer:
	var row := HBoxContainer.new()
	row.alignment = BoxContainer.ALIGNMENT_CENTER
	row.add_theme_constant_override("separation", 8)
	row.mouse_filter = Control.MOUSE_FILTER_PASS
	for id in ["story", "madness"]:
		var b := UiStyle.make_button("STORY" if id == "story" else "MADNESS", Vector2(170, 44), 20)
		var on: bool = id == current
		if id == "madness":
			b.add_theme_color_override("font_color", Madness.RED_HI if not on else Color(1.0, 0.85, 0.8))
		if on:
			b.disabled = true
			b.modulate = Color(1.0, 0.75, 0.6) if id == "madness" else Color(1.0, 0.95, 0.7)
		else:
			b.pressed.connect(func() -> void:
				SoundManager.play_sfx("ui_confirm")
				tree.change_scene_to_file(Madness.BOARD_SCENE if id == "madness" else StoryManager.STORY_MENU))
		row.add_child(b)
	return row
