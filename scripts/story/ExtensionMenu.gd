class_name ExtensionMenu
extends CanvasLayer
## BOSS EXTENSIONS menu (opened from the Story board: the BOSS EXTENSIONS button or a boss's
## extension sign). Lists the extensions of the current Colosseum page; each has 3 levels
## (2 enemy levels + 1 final boss, e.g. BC2 / BC3 / BC4). Pick WARRIOR or ARCHITECT, then a level.
## Not duo mode: you fight alone with the hero you pick (duo is only Colosseum 5).
## Mouse / touch: click. Keyboard / controller: arrows + Enter (button focus), Esc closes.

signal chosen(level: int)
signal closed

var keys: Array = []               # Extension keys shown ("BC"...)
var focus_key := ""                # Highlight / focus this one

var _hero_btns: Array[Button] = []
var _first: Button


func _ready() -> void:
	layer = 36
	if StoryProgress.ext_hero == "":
		StoryProgress.ext_hero = "warrior"
	var dim := ColorRect.new()
	dim.color = Color(0, 0, 0, 0.82)
	dim.set_anchors_and_offsets_preset(Control.PRESET_FULL_RECT)
	add_child(dim)
	var scroll := ScrollContainer.new()
	scroll.set_anchors_and_offsets_preset(Control.PRESET_FULL_RECT)
	scroll.horizontal_scroll_mode = ScrollContainer.SCROLL_MODE_DISABLED
	add_child(scroll)
	var center := CenterContainer.new()
	center.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	center.size_flags_vertical = Control.SIZE_EXPAND_FILL
	scroll.add_child(center)
	var col := VBoxContainer.new()
	col.add_theme_constant_override("separation", 10)
	center.add_child(col)
	col.add_child(UiStyle.label("BOSS EXTENSIONS", 40, Color(1.0, 0.75, 0.35), 10))
	var sub := UiStyle.label("Beat a boss to open its extension: 2 enemy levels + 1 final boss.  Solo - pick your hero below.", 16, UiStyle.TEXT_DIM, 4)
	col.add_child(sub)

	for k in keys:
		var e: Dictionary = StoryLevels.EXTENSIONS[k]
		var open := StoryProgress.ext_open(k)
		var done := StoryProgress.ext_cleared(k)
		var head := "%s  -  %s EXTENSION   (%s)" % [k, e["name"], e["place"]]
		col.add_child(UiStyle.label(head, 21, Color(1.0, 0.85, 0.4) if open else Color(0.6, 0.6, 0.65), 6))
		if not open:
			var parent := int(e["parent"])
			col.add_child(UiStyle.label("LOCKED  -  beat Level %d (%s) first" % [parent, StoryLevels.get_level(parent)["title"]], 15, Color(0.7, 0.7, 0.75), 4))
			continue
		var row := HBoxContainer.new()
		row.alignment = BoxContainer.ALIGNMENT_CENTER
		row.add_theme_constant_override("separation", 12)
		col.add_child(row)
		var first := int(e["first"])
		for i in 3:
			var n := first + i
			var lv := StoryLevels.get_level(n)
			var label := "%s%d   %s" % [k, i + 2, String(lv["title"])]
			if i == 2:
				label += "   (BOSS)"
			if i < done:
				label += "   - CLEARED"
			var b := UiStyle.make_button(label, Vector2(330, 52), 15)
			b.disabled = not StoryProgress.ext_level_unlocked(n)
			if b.disabled:
				b.text = "%s%d   LOCKED" % [k, i + 2]
			b.pressed.connect(_pick.bind(n))
			row.add_child(b)
			if not b.disabled and (_first == null or (k == focus_key and i == mini(done, 2))):
				_first = b

	# Hero choice (solo)
	var hero_row := HBoxContainer.new()
	hero_row.alignment = BoxContainer.ALIGNMENT_CENTER
	hero_row.add_theme_constant_override("separation", 14)
	col.add_child(hero_row)
	hero_row.add_child(UiStyle.label("PLAY AS:", 20, UiStyle.TEXT, 6))
	for h in ["warrior", "architect"]:
		var hb := UiStyle.make_button(h.to_upper(), Vector2(200, 50), 18)
		hb.pressed.connect(_set_hero.bind(h))
		hero_row.add_child(hb)
		_hero_btns.append(hb)
	_refresh_hero()
	var close := UiStyle.make_button("CLOSE", Vector2(200, 50), 18)
	close.size_flags_horizontal = Control.SIZE_SHRINK_CENTER
	close.pressed.connect(_close)
	col.add_child(close)
	(_first if _first != null else close).grab_focus.call_deferred()


func _set_hero(h: String) -> void:
	StoryProgress.set_ext_hero(h)
	SoundManager.play_sfx("spawn", -6.0)
	_refresh_hero()


func _refresh_hero() -> void:
	for i in _hero_btns.size():
		var h := "warrior" if i == 0 else "architect"
		var on := StoryProgress.ext_hero == h
		_hero_btns[i].text = (">  %s  <" % h.to_upper()) if on else h.to_upper()
		_hero_btns[i].modulate = Color(1.0, 1.0, 0.75) if on else Color(0.75, 0.75, 0.8)


func _pick(n: int) -> void:
	SoundManager.play_sfx("spawn")
	chosen.emit(n)
	queue_free()


func _close() -> void:
	closed.emit()
	queue_free()


func _unhandled_input(event: InputEvent) -> void:
	if event.is_action_pressed("ui_cancel"):
		get_viewport().set_input_as_handled()
		_close()
