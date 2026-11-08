class_name StoryBoard
extends Control
## STORY MODE BOARD (the Story menu). The levels are SPACES on a board-game path and
## YOUR PAWN (the Warrior) stands on the level you are on.
##
##   * Finish a level -> the game comes back here and the pawn HOPS forward to the next
##     space (StoryBoard.advance_from), then PLAY = fall into the caves to that level.
##   * Tap / click any unlocked space (or Left / Right) -> the pawn hops there.
##   * Locked spaces show a lock. Beyond Colosseum 1 the path fades into fog toward
##     Level 50: THE SUN.
## Everything is drawn in code (one Control); only the pawn / pulses animate.

## Set by StoryManager when a level is cleared: the pawn starts here and hops forward.
static var advance_from := 0

const HOP_TIME := 0.75
const TILE := 74.0
const BOSS_TILE := 96.0
## Space positions on the board (0..1 of the board rect). Index 0 = Level 1.
const SPACES := [Vector2(0.10, 0.80), Vector2(0.26, 0.64), Vector2(0.42, 0.79),
	Vector2(0.56, 0.58), Vector2(0.44, 0.36), Vector2(0.64, 0.24)]
const TEASER := [Vector2(0.78, 0.36), Vector2(0.84, 0.20)]     # next Colosseum fog space, "50 THE SUN"
const BACK_MARK := Vector2(0.04, 0.50)                          # "< COLOSSEUM 1" on later pages
## Size of the mini enemy figure on each space (small enemies drawn bigger).
const FIGURE_SCALE := {"parasite": 0.6, "kharleming": 0.75, "brute": 0.3, "hydra": 0.25, "golem": 0.36, "blinded_lord": 0.27,
	"architect_chorus": 0.1, "guard": 0.3, "follower": 0.34, "crawler": 0.36, "stray": 0.5, "blasphemy_caeser": 0.17}
## Board page per Colosseum: title, zone labels [text, x, y, colour], tile colours by level offset (0-5).
const PAGES := {
	1: {"title": "STORY MODE  -  COLOSSEUM 1: THE ASHEN DEPTHS",
		"zones": [["THE ASHEN WASTES", 0.2, 0.1, Color(1.0, 0.7, 0.4, 0.8)], ["THE CAVES", 0.5, 0.97, Color(0.8, 0.7, 1.0, 0.8)]],
		"tiles": [Color(0.55, 0.22, 0.14), Color(0.55, 0.22, 0.14), Color(0.55, 0.22, 0.14), Color(0.30, 0.20, 0.38), Color(0.30, 0.20, 0.38), Color(0.20, 0.40, 0.12)],
		"board": [Color(0.42, 0.16, 0.08), Color(0.18, 0.10, 0.16)], "boss_label": Color(0.7, 1.0, 0.4)},
	2: {"title": "STORY MODE  -  COLOSSEUM 2: THE ASCENT",
		"zones": [["THE ELEVATOR", 0.12, 0.97, Color(0.7, 0.85, 1.0, 0.8)], ["HOME OF THE ENLIGHTENED", 0.36, 0.1, Color(1.0, 0.9, 0.55, 0.9)],
			["THE SEWERS", 0.56, 0.97, Color(0.6, 1.0, 0.5, 0.8)], ["BLASPHEMY", 0.64, 0.06, Color(1.0, 0.5, 0.3, 0.9)]],
		"tiles": [Color(0.30, 0.32, 0.38), Color(0.75, 0.66, 0.40), Color(0.75, 0.66, 0.40), Color(0.18, 0.32, 0.16), Color(0.18, 0.32, 0.16), Color(0.50, 0.10, 0.08)],
		"board": [Color(0.22, 0.22, 0.28), Color(0.32, 0.10, 0.08)], "boss_label": Color(1.0, 0.6, 0.35)},
}
const PAWN_OFFSET := Vector2(30, 4)                # Pawn stands at the space's right edge

const WOOD := Color(0.30, 0.17, 0.09)
const WOOD_DARK := Color(0.16, 0.09, 0.05)
const GOLD := Color(1.0, 0.8, 0.3)
const PAWN := Color(0.50, 0.30, 0.85)
const PAWN_SHADE := Color(0.28, 0.14, 0.52)

var _board: Control
var _t := 0.0
var _pawn_space := 1               # Space the pawn stands on (level number)
var _hop_from := 1
var _hop_to := 1
var _hop_t := -1.0                 # < 0 = not hopping
var _land_t := 10.0                # Time since landing (squash + dust)
var _celebrate := false
var _play: Button
var _info: Label
var _title: Label
var _page := 1                     # Colosseum shown on the board
var _busy := false                 # Falling into a level: ignore input


func _ready() -> void:
	SoundManager.play_music("menu")
	StoryProgress.load_progress()
	_build_ui()
	_pawn_space = clampi(StoryProgress.current_level, 1, StoryProgress.unlocked_level)
	_page = StoryLevels.colosseum_of(_pawn_space)
	if advance_from > 0:
		var from := advance_from
		advance_from = 0
		_pawn_space = from
		_page = StoryLevels.colosseum_of(from)
		_refresh_ui()
		var wait := Timer.new()                            # Dies with this scene (no orphan await)
		wait.one_shot = true
		wait.wait_time = 0.7
		add_child(wait)
		wait.start()
		await wait.timeout
		if from < StoryProgress.AVAILABLE_LEVELS:
			_hop(from + 1)                                # (Boss beaten: hops on to the next Colosseum's page)
		else:
			_celebrate = true                             # Last available Colosseum beaten
			SoundManager.play_sfx("ultimate")
			_refresh_ui()
	else:
		_refresh_ui()
	_play.grab_focus.call_deferred()


# ============================================================
# UI
# ============================================================
func _build_ui() -> void:
	_board = Control.new()
	_board.set_anchors_and_offsets_preset(Control.PRESET_FULL_RECT)
	_board.mouse_filter = Control.MOUSE_FILTER_STOP
	add_child(_board)
	_board.draw.connect(_draw_board)
	_board.gui_input.connect(_on_board_input)

	var top := VBoxContainer.new()
	top.set_anchors_and_offsets_preset(Control.PRESET_TOP_WIDE)
	top.offset_top = 10
	top.mouse_filter = Control.MOUSE_FILTER_IGNORE
	add_child(top)
	_title = UiStyle.label("", 32, Color(1.0, 0.65, 0.3), 12)
	top.add_child(_title)
	_info = UiStyle.label("", 17, UiStyle.TEXT, 6)
	top.add_child(_info)

	var row := HBoxContainer.new()
	row.set_anchors_and_offsets_preset(Control.PRESET_CENTER_BOTTOM)
	row.offset_top = -74
	row.offset_bottom = -14
	row.offset_left = -420
	row.offset_right = 420
	row.alignment = BoxContainer.ALIGNMENT_CENTER
	row.add_theme_constant_override("separation", 14)
	add_child(row)
	var back := UiStyle.make_button("< BACK", Vector2(150, 56), 20)
	back.pressed.connect(_go_back)
	row.add_child(back)
	_play = UiStyle.make_button("PLAY", Vector2(330, 56), 22)
	_play.pressed.connect(_on_play)
	row.add_child(_play)
	var reset := UiStyle.make_button("RESET", Vector2(150, 56), 16)
	reset.pressed.connect(_reset.bind(reset))
	row.add_child(reset)


func _refresh_ui() -> void:
	var lv := StoryLevels.get_level(_pawn_space)
	_title.text = String(_page_data().get("title", "STORY MODE"))
	if _celebrate:
		var boss_names := {1: "The Blinded Lord", 2: "Blasphemy Caeser"}
		_info.text = "COLOSSEUM %d COMPLETE!  %s has fallen.  Colosseum %d coming soon...  (Level 50: The Sun)" % [
			_page, boss_names.get(_page, "The boss"), _page + 1]
		_info.add_theme_color_override("font_color", GOLD)
		_play.text = "REPLAY BOSS"
	else:
		_info.add_theme_color_override("font_color", UiStyle.TEXT)
		var boss := String(lv.get("boss", "")) != ""
		_info.text = "Level %d: %s%s    |    Warrior only    |    R = Flask (2 per level)" % [_pawn_space, lv["title"], "  (BOSS)" if boss else ""]
		_play.text = "PLAY LEVEL %d" % _pawn_space


func _board_rect() -> Rect2:
	var sz := size
	return Rect2(Vector2(40, 96), Vector2(sz.x - 80, sz.y - 190))


## Board position of a level's space (every Colosseum page uses the same 6-space path).
func _space_pos(level: int) -> Vector2:
	var r := _board_rect()
	var n: Vector2 = SPACES[clampi((level - 1) % SPACES.size(), 0, SPACES.size() - 1)]
	return r.position + n * r.size


func _page_data() -> Dictionary:
	return PAGES.get(_page, PAGES[1])


func _page_first() -> int:
	return StoryLevels.first_of(_page)


func _page_last() -> int:
	return mini(_page_first() + SPACES.size() - 1, StoryLevels.count())


func _teaser_pos(i: int) -> Vector2:
	var r := _board_rect()
	var n: Vector2 = TEASER[i]
	return r.position + n * r.size


# ============================================================
# PAWN MOVEMENT
# ============================================================
func _hop(to_level: int) -> void:
	if to_level == _pawn_space or _hop_t >= 0.0:
		return
	if StoryLevels.colosseum_of(to_level) != _page:
		# Other Colosseum: turn the page, the pawn lands on its space
		_page = StoryLevels.colosseum_of(to_level)
		_pawn_space = to_level
		_land_t = 0.0
		SoundManager.play_sfx("whoosh", -6.0)
		SoundManager.play_sfx("spawn", -4.0)
		_refresh_ui()
		if StoryManager.autoplay:
			_autoplay_next()
		return
	_hop_from = _pawn_space
	_hop_to = to_level
	_hop_t = 0.0
	SoundManager.play_sfx("jump")


func _process(delta: float) -> void:
	_t += delta
	_land_t += delta
	if _hop_t >= 0.0:
		_hop_t += delta
		if _hop_t >= HOP_TIME:
			_hop_t = -1.0
			_pawn_space = _hop_to
			_land_t = 0.0
			SoundManager.play_sfx("spawn", -4.0)
			_refresh_ui()
			if StoryManager.autoplay:
				_autoplay_next()                          # Testing: keep going by itself
	_board.queue_redraw()


func _pawn_pos() -> Vector2:
	if _hop_t >= 0.0:
		var k := clampf(_hop_t / HOP_TIME, 0.0, 1.0)
		var e := k * k * (3.0 - 2.0 * k)                  # Smooth step
		var p := _space_pos(_hop_from).lerp(_space_pos(_hop_to), e)
		return p + PAWN_OFFSET + Vector2(0, -sin(k * PI) * 110.0)   # Arc through the air
	return _space_pos(_pawn_space) + PAWN_OFFSET


# ============================================================
# INPUT
# ============================================================
func _on_board_input(event: InputEvent) -> void:
	if _busy:
		return
	var mb := event as InputEventMouseButton
	if mb == null or not mb.pressed or mb.button_index != MOUSE_BUTTON_LEFT:
		return                                              # (Touch arrives as an emulated left click)
	# Page arrows: the fog space leads to the next Colosseum, the left mark back
	if mb.position.distance_to(_teaser_pos(0)) <= 40.0:
		var nxt := _page_first() + SPACES.size()
		if nxt <= StoryProgress.unlocked_level and nxt <= StoryLevels.count():
			_celebrate = false
			_hop(nxt)
		else:
			SoundManager.play_sfx("block")
		return
	if _page > 1 and mb.position.distance_to(_back_pos()) <= 40.0:
		_celebrate = false
		_hop(_page_first() - 1)
		return
	for n in range(_page_first(), _page_last() + 1):
		var half := (BOSS_TILE if _is_boss(n) else TILE) * 0.5 + 6.0
		if mb.position.distance_to(_space_pos(n)) <= half:
			if n > StoryProgress.unlocked_level:
				SoundManager.play_sfx("block")              # Locked
				return
			if n == _pawn_space:
				_on_play()
			else:
				_celebrate = false
				_hop(n)
			return


func _unhandled_input(event: InputEvent) -> void:
	if _busy:
		return
	if event.is_action_pressed("ui_cancel"):
		_go_back()
	elif event.is_action_pressed("ui_right") and _pawn_space < StoryProgress.unlocked_level:
		_celebrate = false
		_hop(_pawn_space + 1)
	elif event.is_action_pressed("ui_left") and _pawn_space > 1:
		_celebrate = false
		_hop(_pawn_space - 1)


func _on_play() -> void:
	if _busy or _hop_t >= 0.0:
		return
	_busy = true
	StoryProgress.current_level = _pawn_space
	var cs := String(StoryLevels.get_level(_pawn_space).get("cutscene_in", ""))
	if cs != "":
		# Level with its own intro cutscene (Elevator from Hell, falling into the Sewers)
		var scene := StoryCutscene.new()
		scene.kind = cs
		add_child(scene)
		await scene.finished
	else:
		var fall := CaveFall.new()
		fall.hero_art = WarriorArt
		fall.caption = "LEVEL %d:  %s" % [_pawn_space, StoryLevels.get_level(_pawn_space)["title"]]
		add_child(fall)
		await fall.finished
	get_tree().change_scene_to_file(StoryManager.ARENA_SCENE)


func _autoplay_next() -> void:
	var t := Timer.new()
	t.one_shot = true
	t.wait_time = 1.2
	add_child(t)
	t.start()
	await t.timeout
	_on_play()


func _reset(b: Button) -> void:
	if b.text != "SURE?":
		b.text = "SURE?"
		return
	StoryProgress.reset()
	get_tree().reload_current_scene()


func _go_back() -> void:
	get_tree().change_scene_to_file(CharacterRoster.MAIN_MENU)


func _is_boss(n: int) -> bool:
	return String(StoryLevels.get_level(n).get("boss", "")) != ""


# ============================================================
# DRAWING
# ============================================================
func _draw_board() -> void:
	var r := _board_rect()
	var c := _board
	# Wooden frame + painted board surface
	var frame := FighterArt.rrect_points(r.grow(16.0), 22.0)
	c.draw_colored_polygon(frame, WOOD)
	FighterArt.outline(c, frame, 5.0)
	var inner := FighterArt.rrect_points(r, 14.0)
	var cols := PackedColorArray()
	var board_cols: Array = _page_data()["board"]
	for p in inner:
		var k := clampf((p.x - r.position.x) / r.size.x, 0.0, 1.0)
		cols.append((board_cols[0] as Color).lerp(board_cols[1], k))     # C1: wastes -> caves, C2: shaft -> magma
	c.draw_polygon(inner, cols)
	c.draw_polyline(_closed(inner), WOOD_DARK, 4.0, true)
	for i in 4:                                            # Frame corner studs
		var corner: Vector2 = [r.position, Vector2(r.end.x, r.position.y), r.end, Vector2(r.position.x, r.end.y)][i]
		c.draw_circle(corner, 7.0, GOLD.darkened(0.3))
		c.draw_circle(corner, 4.0, GOLD)

	if _page == 2:
		_draw_scenery_2(r)
	else:
		_draw_scenery(r)

	# Zone labels
	for z in _page_data()["zones"]:
		FighterArt.label(c, r.position + Vector2(r.size.x * float(z[1]), r.size.y * float(z[2])), String(z[0]), 20, z[3])

	# Path (dotted road) between the spaces, then fading toward the next Colosseum / The Sun
	var first := _page_first()
	var last := _page_last()
	for n in range(first, last):
		_road(_space_pos(n), _space_pos(n + 1), n < StoryProgress.unlocked_level)
	var next_open := last + 1 <= StoryProgress.unlocked_level and last + 1 <= StoryLevels.count()
	_road(_space_pos(last), _teaser_pos(0), next_open, 1.0 if next_open else 0.5)
	_road(_teaser_pos(0), _teaser_pos(1), false, 0.25)
	if _page > 1:
		_road(_back_pos(), _space_pos(first), true, 0.7)

	# Spaces
	for n in range(first, last + 1):
		_space(n)
	_teasers()

	# Pawn (+ shadow)
	var pp := _pawn_pos()
	var ground := _space_pos(_hop_to if _hop_t >= 0.0 else _pawn_space)
	if _hop_t >= 0.0:
		ground = _space_pos(_hop_from).lerp(_space_pos(_hop_to), clampf(_hop_t / HOP_TIME, 0.0, 1.0))
	ground += PAWN_OFFSET
	c.draw_set_transform(ground + Vector2(0, 14), 0.0, Vector2(1.0, 0.3))
	c.draw_circle(Vector2.ZERO, 24.0, Color(0, 0, 0, 0.35))
	c.draw_set_transform(Vector2.ZERO, 0.0, Vector2.ONE)
	_pawn(pp + Vector2(0, -6))
	if _land_t < 0.35:                                     # Landing dust ring
		var k := _land_t / 0.35
		c.draw_set_transform(ground + Vector2(0, 12), 0.0, Vector2(1.0, 0.35))
		c.draw_arc(Vector2.ZERO, 20.0 + 50.0 * k, 0.0, TAU, 24, Color(1, 0.9, 0.7, 1.0 - k), 5.0, true)
		c.draw_set_transform(Vector2.ZERO, 0.0, Vector2.ONE)
	if _celebrate:
		for i in 14:                                       # Confetti / sparks around the boss space
			var a := TAU * float(i) / 14.0 + _t * 1.5
			var rr := 70.0 + 14.0 * sin(_t * 4.0 + float(i))
			c.draw_circle(_space_pos(_page_last()) + Vector2.from_angle(a) * rr, 4.0, Color.from_hsv(fmod(float(i) / 14.0 + _t * 0.2, 1.0), 0.6, 1.0))


func _draw_scenery(r: Rect2) -> void:
	var c := _board
	# Lava river across the wastes
	var river := PackedVector2Array()
	for i in 12:
		var k := float(i) / 11.0
		river.append(r.position + Vector2(k * r.size.x * 0.5, r.size.y * (0.45 + 0.08 * sin(k * 7.0))))
	c.draw_polyline(river, Color(1.0, 0.45, 0.1, 0.35), 14.0, true)
	c.draw_polyline(river, Color(1.0, 0.65, 0.2, 0.7), 4.0, true)
	# Little mountains + a smoking volcano (wastes)
	for m in [Vector3(0.05, 0.3, 40.0), Vector3(0.14, 0.26, 55.0), Vector3(0.36, 0.3, 45.0)]:
		var b := r.position + Vector2(m.x * r.size.x, m.y * r.size.y)
		c.draw_colored_polygon(PackedVector2Array([b + Vector2(-m.z, 0), b + Vector2(0, -m.z * 1.1), b + Vector2(m.z, 0)]), Color(0.18, 0.07, 0.05))
	var v := r.position + Vector2(0.27 * r.size.x, 0.3 * r.size.y)
	c.draw_colored_polygon(PackedVector2Array([v + Vector2(-60, 0), v + Vector2(-14, -70), v + Vector2(14, -70), v + Vector2(60, 0)]), Color(0.12, 0.05, 0.04))
	c.draw_line(v + Vector2(-12, -70), v + Vector2(12, -70), Color(1.0, 0.6, 0.2), 4.0)
	for k in 3:
		c.draw_circle(v + Vector2(6.0 * float(k) + sin(_t + float(k)) * 4.0, -86.0 - 18.0 * float(k)), 9.0 + 4.0 * float(k), Color(0.1, 0.05, 0.05, 0.6))
	# Cave mouth between the wastes and the caves (where you fall in)
	var cm := r.position + Vector2(0.5 * r.size.x, 0.68 * r.size.y)
	c.draw_set_transform(cm, 0.0, Vector2(1.0, 0.6))
	c.draw_circle(Vector2.ZERO, 46.0, Color(0.05, 0.02, 0.03))
	c.draw_arc(Vector2.ZERO, 46.0, PI, TAU, 20, Color(0.35, 0.22, 0.18), 6.0, true)
	c.draw_set_transform(Vector2.ZERO, 0.0, Vector2.ONE)
	# Crystals + cables in the caves
	for cr in [Vector2(0.62, 0.8), Vector2(0.7, 0.72), Vector2(0.36, 0.5)]:
		var p: Vector2 = r.position + cr * r.size
		c.draw_colored_polygon(PackedVector2Array([p + Vector2(-6, 0), p + Vector2(0, -22), p + Vector2(6, 0)]), Color(0.7, 0.4, 1.0, 0.8))
	var sun := _teaser_pos(1)                               # Glow of The Sun far away
	c.draw_circle(sun, 70.0 + 6.0 * sin(_t * 2.0), Color(1.0, 0.8, 0.3, 0.10))


## Colosseum 2 page: the elevator shaft (bottom left), the white city of the Enlightened
## (top), the sewer pipes (bottom middle) and the magma temple of Blasphemy (right).
func _draw_scenery_2(r: Rect2) -> void:
	var c := _board
	# Elevator shaft rising out of a lava glow
	var sx := r.position.x + r.size.x * 0.10
	c.draw_rect(Rect2(sx - 34.0, r.position.y + r.size.y * 0.25, 68.0, r.size.y * 0.75), Color(0.12, 0.12, 0.15, 0.8))
	c.draw_rect(Rect2(sx - 50.0, r.end.y - 30.0, 100.0, 30.0), Color(1.0, 0.4, 0.1, 0.35))
	for k in 6:
		var gy := r.position.y + r.size.y * 0.3 + float(k) * r.size.y * 0.11 + fmod(_t * 20.0, r.size.y * 0.11)
		c.draw_line(Vector2(sx - 34.0, gy), Vector2(sx + 34.0, gy), Color(0.3, 0.3, 0.34, 0.8), 3.0)
	# White city with gold domes
	for i in 6:
		var bx := r.position.x + r.size.x * (0.22 + 0.06 * float(i))
		var bh := 40.0 + 26.0 * float((i * 7) % 3)
		var by := r.position.y + r.size.y * 0.32
		c.draw_rect(Rect2(bx - 14.0, by - bh, 28.0, bh), Color(0.92, 0.9, 0.84, 0.85))
		c.draw_circle(Vector2(bx, by - bh), 14.0, Color(0.95, 0.75, 0.3, 0.9))
	c.draw_circle(r.position + Vector2(r.size.x * 0.36, r.size.y * 0.16), 26.0 + 3.0 * sin(_t * 2.0), Color(1.0, 0.9, 0.5, 0.35))
	# Sewer pipes dripping slime (bottom middle)
	for i in 3:
		var py := r.position.y + r.size.y * (0.86 + 0.04 * float(i))
		c.draw_line(Vector2(r.position.x + r.size.x * 0.38, py), Vector2(r.position.x + r.size.x * 0.74, py), Color(0.2, 0.3, 0.18, 0.9), 10.0)
	for i in 4:
		var dx := r.position.x + r.size.x * (0.42 + 0.09 * float(i))
		var k := fmod(_t * 0.8 + float(i) * 0.3, 1.0)
		c.draw_circle(Vector2(dx, r.position.y + r.size.y * 0.9 + k * 20.0), 3.0, Color(0.5, 0.9, 0.4, 1.0 - k))
	# Magma temple + serpent coil (right)
	var tx := r.position.x + r.size.x * 0.74
	var ty := r.position.y + r.size.y * 0.42
	c.draw_colored_polygon(PackedVector2Array([Vector2(tx - 80, ty + 60), Vector2(tx - 50, ty - 30), Vector2(tx + 50, ty - 30), Vector2(tx + 80, ty + 60)]), Color(0.18, 0.05, 0.05, 0.9))
	c.draw_arc(Vector2(tx, ty - 50.0), 36.0, PI * 0.9, PI * 2.6, 20, Color(0.55, 0.08, 0.08), 12.0, true)
	c.draw_arc(Vector2(tx, ty - 50.0), 36.0, PI * 0.9, PI * 2.6, 20, Color(1.0, 0.45, 0.1, 0.5 + 0.3 * sin(_t * 3.0)), 3.0, true)
	var sun := _teaser_pos(1)                               # Glow of The Sun far away
	c.draw_circle(sun, 70.0 + 6.0 * sin(_t * 2.0), Color(1.0, 0.8, 0.3, 0.10))


func _road(a: Vector2, b: Vector2, lit: bool, alpha: float = 1.0) -> void:
	var mid := (a + b) * 0.5 + (b - a).orthogonal().normalized() * 26.0
	var steps := 14
	for i in steps:
		var k := (float(i) + 0.5) / float(steps)
		var p := a.lerp(mid, k).lerp(mid.lerp(b, k), k)       # Quadratic curve
		c_dot(p, lit, alpha)


func c_dot(p: Vector2, lit: bool, alpha: float) -> void:
	_board.draw_circle(p, 6.0, Color(0, 0, 0, 0.8 * alpha))
	_board.draw_circle(p, 4.0, Color(GOLD.r, GOLD.g, GOLD.b, alpha) if lit else Color(0.55, 0.45, 0.4, alpha))


func _space(n: int) -> void:
	var c := _board
	var p := _space_pos(n)
	var boss := _is_boss(n)
	var s := BOSS_TILE if boss else TILE
	var unlocked := n <= StoryProgress.unlocked_level
	var cleared := StoryProgress.level_cleared(n)
	var here := n == _pawn_space and _hop_t < 0.0
	var rect := Rect2(p - Vector2(s, s) * 0.5, Vector2(s, s))
	# Base (raised board-game tile)
	var base := FighterArt.rrect_points(rect.grow(4.0), 14.0)
	c.draw_colored_polygon(base, WOOD_DARK)
	var top := FighterArt.rrect_points(Rect2(rect.position + Vector2(0, -6), rect.size), 12.0)
	var tiles: Array = _page_data()["tiles"]
	var fill: Color = tiles[(n - 1) % tiles.size()]
	if not unlocked:
		fill = Color(0.25, 0.23, 0.23)
	c.draw_colored_polygon(top, fill)
	if here:
		c.draw_polyline(_closed(top), Color(1, 1, 1, 0.5 + 0.5 * sin(_t * 5.0)), 6.0, true)
	c.draw_polyline(_closed(top), GOLD if cleared else Color(0, 0, 0), 3.5, true)
	# Mini enemy figure on the tile
	var center := rect.get_center() + Vector2(0, -6)
	if unlocked:
		var art := StoryLevels.enemy_script(StoryLevels.tile_enemy(n))
		var sc: float = FIGURE_SCALE.get(StoryLevels.tile_enemy(n), 0.3)
		c.draw_set_transform(center + Vector2(0, s * 0.32), 0.0, Vector2(sc, sc))
		art.call("draw_portrait", c, _t)
		c.draw_set_transform(Vector2.ZERO, 0.0, Vector2.ONE)
	else:
		_lock(center)
	# Number badge
	var badge := rect.position + Vector2(6, -2)
	c.draw_circle(badge, 14.0, Color(0, 0, 0))
	c.draw_circle(badge, 11.5, GOLD if unlocked else Color(0.5, 0.5, 0.5))
	FighterArt.label(c, badge + Vector2(0, 6), str(n), 16, Color(0.1, 0.05, 0.02))
	if boss:
		var mini_boss := String(StoryLevels.get_level(n).get("boss_sub", "")).begins_with("Mini-Boss")
		FighterArt.label(c, rect.get_center() + Vector2(0, s * 0.5 + 18.0), "MINI-BOSS" if mini_boss else "BOSS", 16, _page_data()["boss_label"])
	if cleared:                                            # Check mark
		var ck := rect.end + Vector2(-8, -12)
		c.draw_circle(ck, 12.0, Color(0, 0, 0))
		c.draw_circle(ck, 9.5, Color(0.3, 0.8, 0.3))
		c.draw_polyline(PackedVector2Array([ck + Vector2(-5, 0), ck + Vector2(-1, 4), ck + Vector2(5, -4)]), Color.WHITE, 2.5, true)


func _back_pos() -> Vector2:
	var r := _board_rect()
	return r.position + BACK_MARK * r.size


func _teasers() -> void:
	var c := _board
	var p := _teaser_pos(0)
	var nxt := _page_first() + SPACES.size()
	var open := nxt <= StoryProgress.unlocked_level and nxt <= StoryLevels.count()
	var pulse := 0.5 + 0.5 * sin(_t * 4.0)
	c.draw_circle(p, 34.0, Color(1.0, 0.8, 0.3, 0.35 + 0.25 * pulse) if open else Color(0.5, 0.45, 0.45, 0.25))
	FighterArt.label(c, p + Vector2(0, 8), "%d %s" % [nxt, ">" if open else "..."], 20, Color(1, 1, 1, 0.9 if open else 0.45))
	FighterArt.label(c, p + Vector2(0, 52), "COLOSSEUM %d" % (_page + 1), 13, Color(1, 1, 1, 0.8 if open else 0.4))
	if _page > 1:                                           # Way back to the previous Colosseum
		var b := _back_pos()
		c.draw_circle(b, 30.0, Color(1.0, 0.8, 0.3, 0.3))
		FighterArt.label(c, b + Vector2(0, 7), "< %d" % (_page_first() - 1), 18, Color(1, 1, 1, 0.85))
		FighterArt.label(c, b + Vector2(0, 46), "COLOSSEUM %d" % (_page - 1), 12, Color(1, 1, 1, 0.7))
	var sun := _teaser_pos(1)
	c.draw_circle(sun, 30.0, Color(1.0, 0.75, 0.25, 0.6))
	c.draw_circle(sun, 22.0, Color(1.0, 0.92, 0.5, 0.8))
	for i in 10:
		var a := TAU * float(i) / 10.0 + _t * 0.3
		c.draw_line(sun + Vector2.from_angle(a) * 36.0, sun + Vector2.from_angle(a) * 48.0, Color(1.0, 0.8, 0.3, 0.6), 3.0)
	FighterArt.label(c, sun + Vector2(0, 70), "50: THE SUN", 15, Color(1.0, 0.85, 0.4, 0.8))


func _lock(p: Vector2) -> void:
	var c := _board
	c.draw_arc(p + Vector2(0, -8), 10.0, PI, TAU, 12, Color(0, 0, 0), 6.0)
	c.draw_arc(p + Vector2(0, -8), 10.0, PI, TAU, 12, Color(0.6, 0.6, 0.6), 3.0)
	var body := FighterArt.rrect_points(Rect2(p.x - 14, p.y - 8, 28, 22), 4.0)
	c.draw_colored_polygon(body, Color(0.6, 0.6, 0.6))
	FighterArt.outline(c, body, 3.0)
	c.draw_circle(p + Vector2(0, 2), 3.0, Color(0.2, 0.2, 0.2))


## Classic board-game pawn in the Warrior's purple, with a little void mask.
func _pawn(p: Vector2) -> void:
	var c := _board
	var squash := 1.0
	if _land_t < 0.25:
		squash = 1.0 - 0.25 * sin(_land_t / 0.25 * PI)
	var bob := sin(_t * 3.0) * 3.0 if _hop_t < 0.0 else 0.0
	var h := 70.0 * squash
	var base_c := p + Vector2(0, 0)
	# Base disc
	var base := EnemyArt.ellipse_points(base_c, 24, 9, 18)
	c.draw_colored_polygon(base, PAWN_SHADE)
	FighterArt.outline(c, base, 3.0)
	# Body (cone)
	var top := base_c + Vector2(0, -h * 0.62 + bob)
	var body := PackedVector2Array([base_c + Vector2(-18, -4), top + Vector2(-7, 0), top + Vector2(7, 0), base_c + Vector2(18, -4)])
	c.draw_polygon(body, PackedColorArray([PAWN_SHADE, PAWN, PAWN.lightened(0.2), PAWN_SHADE]))
	FighterArt.outline(c, body, 3.0)
	# Collar
	var collar := EnemyArt.ellipse_points(top, 13, 4.5, 14)
	c.draw_colored_polygon(collar, PAWN.lightened(0.15))
	FighterArt.outline(c, collar, 2.5)
	# Head + void mask
	var head := top + Vector2(0, -15)
	FighterArt.ball(c, head, 15.0, PAWN, PAWN_SHADE, PAWN.lightened(0.45))
	c.draw_colored_polygon(PackedVector2Array([head + Vector2(-8, -3), head + Vector2(10, -4), head + Vector2(8, 4), head + Vector2(-6, 4)]), Color(0.92, 0.92, 0.98))
	c.draw_circle(head + Vector2(4, 0), 2.5, Color(0.55, 0.3, 0.95))
	c.draw_circle(head + Vector2(-5, -6), 3.5, Color(1, 1, 1, 0.5))      # Shine


func _closed(pts: PackedVector2Array) -> PackedVector2Array:
	var cl := pts.duplicate()
	cl.append(pts[0])
	return cl
