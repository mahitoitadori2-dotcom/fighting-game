class_name SkinCatalogue
extends CanvasLayer
## THE STORY SKINS CATALOGUE (Story board > SKINS): pick what the Warrior and the Architect wear
## in Story Mode. Normal, GALAXY (the Multiversal achievement) or FROZEN EXPEDITION (beat the
## Crystal Swarm in Terra Ordinariorum's Snow Desert). Locked skins show how to earn them.
## Saved in StoryProgress.story_skin. (Versus keeps the Galaxy toggle in the Achievements menu.)

signal closed

const SKINS := [
	{"id": "", "name": "NORMAL", "how": ""},
	{"id": "galaxy", "name": "GALAXY", "how": "Unlock the achievement\n'Multi-Multi-Multiversal Level Of Power'"},
	{"id": "frozen", "name": "FROZEN EXPEDITION", "how": "Find the secret of\nTerra Ordinariorum"},
	{"id": "assassin", "name": "ASSASSIN", "how": "???"},
]

var _cards: Array = []
var _t := 0.0


func _ready() -> void:
	layer = 50
	StoryProgress.load_progress()
	var shade := ColorRect.new()
	shade.color = Color(0, 0, 0, 0.8)
	shade.set_anchors_and_offsets_preset(Control.PRESET_FULL_RECT)
	add_child(shade)
	var col := VBoxContainer.new()
	col.set_anchors_and_offsets_preset(Control.PRESET_FULL_RECT)
	col.offset_left = 50
	col.offset_right = -50
	col.offset_top = 30
	col.offset_bottom = -30
	col.add_theme_constant_override("separation", 14)
	add_child(col)
	col.add_child(UiStyle.label("STORY SKINS", 34, Color(1.0, 0.86, 0.5), 8))
	col.add_child(UiStyle.label("What the Warrior and the Architect wear in Story Mode", 17, UiStyle.TEXT, 4))
	var row := HBoxContainer.new()
	row.size_flags_vertical = Control.SIZE_EXPAND_FILL
	row.alignment = BoxContainer.ALIGNMENT_CENTER
	row.add_theme_constant_override("separation", 24)
	col.add_child(row)
	for s in SKINS:
		var card := Button.new()
		card.custom_minimum_size = Vector2(280, 420)
		card.focus_mode = Control.FOCUS_ALL
		card.flat = true
		card.pressed.connect(_pick.bind(String(s["id"])))
		card.draw.connect(_draw_card.bind(card, s))
		row.add_child(card)
		_cards.append(card)
	var back := UiStyle.make_button("BACK", Vector2(200, 48), 18)
	back.size_flags_horizontal = Control.SIZE_SHRINK_CENTER
	back.pressed.connect(_close)
	col.add_child(back)
	(_cards[0] as Button).grab_focus.call_deferred()


func _unlocked(id: String) -> bool:
	match id:
		"galaxy":
			return Achievements.is_unlocked(Achievements.ULTIMATE)
		"frozen":
			return StoryProgress.frozen_skins
		"assassin":
			Madness.load_data()
			return Madness.skin
	return true


func _pick(id: String) -> void:
	if not _unlocked(id):
		SoundManager.play_sfx("block", -6.0)
		return
	StoryProgress.set_story_skin(id)
	SoundManager.play_sfx("holy", -6.0)


func _process(delta: float) -> void:
	_t += delta
	for c in _cards:
		(c as Control).queue_redraw()


func _unhandled_input(event: InputEvent) -> void:
	if event.is_action_pressed("ui_cancel"):
		get_viewport().set_input_as_handled()
		_close()


func _close() -> void:
	closed.emit()
	queue_free()


func _draw_card(card: Button, s: Dictionary) -> void:
	var id := String(s["id"])
	var sz := card.size
	var open := _unlocked(id)
	var chosen := StoryProgress.story_skin == id
	var bg := Color(0.08, 0.08, 0.10, 0.95)
	if id == "galaxy":
		bg = Color(0.10, 0.06, 0.22, 0.95)
	elif id == "frozen":
		bg = Color(0.10, 0.16, 0.24, 0.95)
	elif id == "assassin":
		bg = Color(0.16, 0.02, 0.02, 0.95)
	card.draw_rect(Rect2(Vector2.ZERO, sz), bg)
	var border := Color(1.0, 0.82, 0.38) if chosen else (Color(0.9, 0.9, 1.0) if card.has_focus() else Color(0.35, 0.35, 0.4))
	card.draw_rect(Rect2(Vector2.ZERO, sz), border, false, 5.0 if chosen else 3.0)
	FighterArt.label(card, Vector2(sz.x * 0.5, 40.0), String(s["name"]), 22, Color(1, 0.92, 0.7) if open else Color(0.55, 0.55, 0.6))
	if open:
		for k in 2:
			var hero := "warrior" if k == 0 else "architect"
			card.draw_set_transform(Vector2(sz.x * (0.3 + 0.4 * float(k)), sz.y - 100.0), 0.0, Vector2(1.6, 1.6))
			_draw_hero(card, id, hero)
			card.draw_set_transform(Vector2.ZERO, 0.0, Vector2.ONE)
		FighterArt.label(card, Vector2(sz.x * 0.5, sz.y - 40.0), "WORN" if chosen else "PICK", 20, Color(1.0, 0.82, 0.38) if chosen else Color(0.85, 0.85, 0.9))
	else:
		card.draw_circle(sz * 0.5, 40.0, Color(0, 0, 0, 0.5))
		card.draw_rect(Rect2(sz * 0.5 + Vector2(-18, -6), Vector2(36, 30)), Color(0.6, 0.6, 0.65))
		card.draw_arc(sz * 0.5 + Vector2(0, -6), 13.0, PI, TAU, 10, Color(0.6, 0.6, 0.65), 5.0)
		var lines := String(s["how"]).split("\n")
		for i in lines.size():
			FighterArt.label(card, Vector2(sz.x * 0.5, sz.y * 0.5 + 80.0 + float(i) * 24.0), lines[i], 15, Color(0.7, 0.7, 0.75))


func _draw_hero(c: CanvasItem, skin: String, hero: String) -> void:
	match skin:
		"assassin":
			AssassinSkin.draw_portrait(c, hero, _t)
		"frozen":
			FrozenSkin.draw_portrait(c, hero, _t)
		"galaxy":
			if hero == "architect":
				ArchitectArt.set_palette(GalaxySkin.ARCHITECT)
				ArchitectArt.draw_portrait(c, _t)
				ArchitectArt.set_palette(ArchitectArt.NORMAL_PALETTE)
			else:
				WarriorArt.set_palette(GalaxySkin.WARRIOR)
				WarriorArt.draw_portrait(c, _t)
				WarriorArt.set_palette(WarriorArt.NORMAL_PALETTE)
		_:
			StoryLevels.hero_art(hero).call("draw_portrait", c, _t)
