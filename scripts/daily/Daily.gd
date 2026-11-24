class_name Daily
extends RefCounted
## DAILY CHALLENGES + THE SHOP (2026-11-23, picked by the user). Saved in user://daily.cfg.
##   * THREE small challenges a day (picked by the date). Each one done = 30 MARKS, all three = +30 more.
##   * Every unlocked achievement is worth 10 MARKS (also the ones you already had).
##   * The SHOP sells PALETTES for your Versus fighter (a colour over the whole fighter); equip one or none.
## Progress comes from hooks: MatchManager (Versus wins), StoryManager (Story clears), BossRush (bosses),
## WeaponDrops (weapon hits), PhotoMode (pictures).

const SAVE_PATH := "user://daily.cfg"
const PER_CHALLENGE := 30
const ALL_BONUS := 30
const PER_ACHIEVEMENT := 10
## id: [text (%d = goal, %s = fighter), goal]
const POOL := {
	"vs_win": ["Win %d Versus fights", 3],
	"vs_win_as": ["Win a Versus fight as %s", 1],
	"story_clear": ["Clear %d Story levels", 2],
	"no_flask": ["Clear a Story level without a flask", 1],
	"weapon_hits": ["Land %d hits with weapon pickups", 10],
	"rush_boss": ["Beat %d bosses in Boss Rush", 3],
	"photo": ["Save a picture in Photo Mode", 1],
}
## Palettes: id -> [name, colour, price]
const PALETTES := {
	"crimson": ["CRIMSON", Color(1.0, 0.55, 0.55), 60],
	"frost": ["FROST", Color(0.62, 0.85, 1.0), 60],
	"gold": ["GOLD", Color(1.0, 0.88, 0.45), 80],
	"toxic": ["TOXIC", Color(0.62, 1.0, 0.5), 80],
	"royal": ["ROYAL", Color(0.8, 0.62, 1.0), 100],
	"shadow": ["SHADOW", Color(0.42, 0.40, 0.52), 120],
}

static var marks := 0
static var owned: Array = []
static var equipped := ""
static var _date := ""
static var _progress := {}                 # id -> count (today)
static var _claimed: Array = []            # ids paid out today (+ "all")
static var _ach_paid := 0
static var _loaded := false


static func load_data() -> void:
	if _loaded:
		return
	_loaded = true
	var c := ConfigFile.new()
	c.load(SAVE_PATH)
	marks = int(c.get_value("daily", "marks", 0))
	owned = c.get_value("daily", "owned", [])
	equipped = String(c.get_value("daily", "equipped", ""))
	_date = String(c.get_value("daily", "date", ""))
	_progress = c.get_value("daily", "progress", {})
	_claimed = c.get_value("daily", "claimed", [])
	_ach_paid = int(c.get_value("daily", "ach_paid", 0))
	_roll_day()


static func save_data() -> void:
	var c := ConfigFile.new()
	c.set_value("daily", "marks", marks)
	c.set_value("daily", "owned", owned)
	c.set_value("daily", "equipped", equipped)
	c.set_value("daily", "date", _date)
	c.set_value("daily", "progress", _progress)
	c.set_value("daily", "claimed", _claimed)
	c.set_value("daily", "ach_paid", _ach_paid)
	c.save(SAVE_PATH)


## A new day: new challenges, fresh progress.
static func _roll_day() -> void:
	var today := Time.get_date_string_from_system()
	if _date != today:
		_date = today
		_progress = {}
		_claimed = []
		save_data()


## Today's three challenges: [{id, text, goal, done (count)}].
static func challenges() -> Array:
	load_data()
	_roll_day()
	var rng := RandomNumberGenerator.new()
	rng.seed = hash("ub_challenges_" + _date)
	var ids: Array = POOL.keys()
	for i in range(ids.size() - 1, 0, -1):
		var j := rng.randi() % (i + 1)
		var tmp: Variant = ids[i]
		ids[i] = ids[j]
		ids[j] = tmp
	var out: Array = []
	for i in 3:
		var id := String(ids[i])
		var spec: Array = POOL[id]
		var goal := int(spec[1])
		var text := String(spec[0])
		if id == "vs_win_as":
			text = text % String(target_fighter()["name"]).to_upper()
		elif text.contains("%d"):
			text = text % goal
		out.append({"id": id, "text": text, "goal": goal, "done": mini(int(_progress.get(id, 0)), goal)})
	return out


## The fighter of today's "win as" challenge (a playable roster fighter, picked by the date).
static func target_fighter() -> Dictionary:
	var list := CharacterRoster.playable().filter(func(e: Dictionary) -> bool:
		return String(e.get("id", "")) != "apha" and e.get("selectable", true))
	if list.is_empty():
		return {"id": "warrior", "name": "Warrior"}
	var rng := RandomNumberGenerator.new()
	rng.seed = hash("ub_target_" + Time.get_date_string_from_system())
	return list[rng.randi() % list.size()]


## Something happened that a challenge may count. Pays out when a challenge is complete.
static func progress(id: String, amount: int = 1) -> void:
	if StoryManager.autoplay:
		return                                              # CPU test runs never count
	var today := challenges()
	var hit := false
	for ch: Dictionary in today:
		if String(ch["id"]) != id or _claimed.has(id):
			continue
		hit = true
		_progress[id] = int(_progress.get(id, 0)) + amount
		if int(_progress[id]) >= int(ch["goal"]):
			_claimed.append(id)
			marks += PER_CHALLENGE
			_toast("DAILY CHALLENGE DONE  +%d MARKS" % PER_CHALLENGE)
	if not hit:
		return
	var all := true
	for ch: Dictionary in today:
		if not _claimed.has(String(ch["id"])):
			all = false
	if all and not _claimed.has("all"):
		_claimed.append("all")
		marks += ALL_BONUS
		_toast("ALL THREE DONE  +%d MARKS" % ALL_BONUS)
		Achievements.unlock("daily_all")
	save_data()


## Achievements are worth marks too (paid when the shop opens, and after each unlock).
static func pay_achievements() -> int:
	load_data()
	var n := Achievements.unlocked_count()
	var new_ones := maxi(n - _ach_paid, 0)
	if new_ones > 0:
		marks += new_ones * PER_ACHIEVEMENT
		_ach_paid = n
		save_data()
	return new_ones * PER_ACHIEVEMENT


static func buy(id: String) -> bool:
	load_data()
	if owned.has(id) or not PALETTES.has(id) or marks < int(PALETTES[id][2]):
		return false
	marks -= int(PALETTES[id][2])
	owned.append(id)
	equipped = id
	save_data()
	Achievements.unlock("palette_first")
	return true


static func equip(id: String) -> void:
	load_data()
	equipped = id if owned.has(id) else ""
	save_data()


## The equipped palette on your Versus fighter (ArenaManager, human P1 only).
static func apply_palette(f: Fighter) -> void:
	load_data()
	if f == null or equipped == "" or not PALETTES.has(equipped):
		return
	var col: Color = PALETTES[equipped][1]
	if f.pixel_group != null:
		f.pixel_group.modulate = col
	else:
		f.modulate = col


static func _toast(text: String) -> void:
	var tree := Engine.get_main_loop() as SceneTree
	if tree == null:
		return
	var layer := CanvasLayer.new()
	layer.layer = 130
	var l := PanelContainer.new()                    # A NOTIFICATION outline (UiStyle.notice_box)
	l.add_theme_stylebox_override("panel", UiStyle.notice_box(Color(0.6, 0.9, 1.0), 14.0))
	l.mouse_filter = Control.MOUSE_FILTER_IGNORE
	l.add_child(UiStyle.label(text, 26, Color(0.6, 0.9, 1.0), 8))
	l.set_anchors_and_offsets_preset(Control.PRESET_CENTER_TOP)
	l.offset_top = 110.0
	l.grow_horizontal = Control.GROW_DIRECTION_BOTH
	layer.add_child(l)
	tree.root.add_child(layer)
	SoundManager.play_sfx("holy", -4.0)
	var tw := l.create_tween()
	tw.tween_interval(2.4)
	tw.tween_property(l, "modulate:a", 0.0, 0.6)
	tw.tween_callback(layer.queue_free)
