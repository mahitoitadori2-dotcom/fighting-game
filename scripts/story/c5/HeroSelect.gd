class_name HeroSelect
extends CanvasLayer
## COLOSSEUM 5: CHOOSE YOUR HERO (shown on the Story board when you start Level 35, or any
## Colosseum 5 level before a choice was made). Pick the WARRIOR or the ARCHITECT; the other one
## becomes your CPU PARTNER for the whole Colosseum. Saved in StoryProgress.c5_hero.
## Mouse / touch: tap a PLAY AS button. Keyboard / controller: Left / Right + Enter (button focus).

signal chosen(hero: String)

var _t := 0.0
var _painter: Control
var _buttons: Array[Button] = []


func _ready() -> void:
	layer = 35
	var dim := ColorRect.new()
	dim.color = Color(0, 0, 0, 0.75)
	dim.set_anchors_and_offsets_preset(Control.PRESET_FULL_RECT)
	add_child(dim)
	_painter = Control.new()
	_painter.set_anchors_and_offsets_preset(Control.PRESET_FULL_RECT)
	_painter.mouse_filter = Control.MOUSE_FILTER_IGNORE
	add_child(_painter)
	_painter.draw.connect(_paint)
	var row := HBoxContainer.new()
	row.set_anchors_and_offsets_preset(Control.PRESET_CENTER_BOTTOM)
	row.offset_top = -120
	row.offset_bottom = -40
	row.offset_left = -420
	row.offset_right = 420
	row.alignment = BoxContainer.ALIGNMENT_CENTER
	row.add_theme_constant_override("separation", 60)
	add_child(row)
	for h in ["warrior", "architect"]:
		var b := UiStyle.make_button("PLAY AS " + h.to_upper(), Vector2(320, 64), 22)
		b.pressed.connect(_pick.bind(h))
		row.add_child(b)
		_buttons.append(b)
	var last := StoryProgress.c5_hero if StoryProgress.c5_hero != "" else "warrior"
	_buttons[0 if last == "warrior" else 1].grab_focus.call_deferred()
	if StoryManager.autoplay:
		_pick.call_deferred("warrior")


func _process(delta: float) -> void:
	_t += delta
	_painter.queue_redraw()


func _pick(hero: String) -> void:
	StoryProgress.set_c5_hero(hero)
	SoundManager.play_sfx("spawn")
	chosen.emit(hero)
	queue_free()


func _paint() -> void:
	var sz := _painter.size
	var cx := sz.x * 0.5
	FighterArt.label(_painter, Vector2(cx, 70), "COLOSSEUM 5: THE FINAL ASCENT", 40, Color(1.0, 0.8, 0.4))
	FighterArt.label(_painter, Vector2(cx, 112), "Choose your hero. The other one fights beside you as your CPU partner.", 20, Color(1, 1, 1, 0.85))
	var focus := 0
	for i in _buttons.size():
		if _buttons[i].has_focus():
			focus = i
	for i in 2:
		var x := cx + (-210.0 if i == 0 else 210.0)
		var card := Rect2(x - 150, 150, 300, sz.y - 330)
		var lit := i == focus
		_painter.draw_rect(card, Color(0.12, 0.10, 0.16, 0.95))
		_painter.draw_rect(card, Color(1.0, 0.8, 0.3) if lit else Color(0.4, 0.38, 0.45), false, 5.0 if lit else 3.0)
		var art: Script = WarriorArt if i == 0 else ArchitectArt
		_painter.draw_set_transform(Vector2(x, card.end.y - 40.0), 0.0, Vector2(1.6, 1.6))
		art.call("draw_portrait", _painter, _t)
		_painter.draw_set_transform(Vector2.ZERO, 0.0, Vector2.ONE)
		FighterArt.label(_painter, Vector2(x, card.position.y + 34), "THE WARRIOR" if i == 0 else "THE ARCHITECT", 26, Color.WHITE)
		FighterArt.label(_painter, Vector2(x, card.position.y + 62), "Partner: the Architect" if i == 0 else "Partner: the Warrior", 16, Color(0.7, 0.9, 1.0))
