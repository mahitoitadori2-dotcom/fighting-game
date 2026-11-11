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
##   * Each Colosseum is a WIDE strip: the spaces are far apart on a long gentle wave (no
##     zig-zag). DRAG the board left / right (mouse or finger; wheel works too) to scroll it.
##     Drag PAST the end of a Colosseum and let go -> the next / previous Colosseum slides in.
## Everything is drawn in code: the frame + scenery on _board, the scrolling path / spaces /
## pawn on _cv (inside _clip, which cuts it off at the board's edge).

## Set by StoryManager when a level is cleared: the pawn starts here and hops forward.
static var advance_from := 0
## Set by StoryManager after a BOSS EXTENSION level: the board reopens that extension's menu.
static var ext_return := ""

const HOP_TIME := 0.75
const TILE := 74.0
const BOSS_TILE := 96.0
## WIDE BOARD: spaces SPACING px apart at least (small Colosseums spread to fill the board),
## on a slow wave (WAVE_* = 0..1 of the board height). The strip scrolls by dragging.
const SPACING := 170.0
const MARGIN_L := 160.0                 # Room for the "< previous Colosseum" mark
const MARGIN_R := 320.0                 # Room for the next-Colosseum fog space + The Sun
const WAVE_MID := 0.56
const WAVE_AMP := 0.25
const WAVE_FREQ := 0.6                  # Radians per space: one full curve every ~10 spaces
const DRAG_START := 8.0                 # px before a press becomes a drag (else it's a click)
const OVER_TURN := 80.0                 # Pulled this far past the end -> turn to the next Colosseum
const OVER_MAX := 150.0                 # (the pull is rubbery: half of the finger movement)
## Tile colour per map (StoryLevels.MAPS key).
const MAP_TILE := {
	"wastes": Color(0.55, 0.22, 0.14), "geode": Color(0.36, 0.22, 0.48), "hive": Color(0.30, 0.26, 0.24),
	"lair": Color(0.45, 0.16, 0.08), "lab": Color(0.20, 0.40, 0.12),
	"elevator": Color(0.30, 0.32, 0.38), "enlightened": Color(0.75, 0.66, 0.40), "sewers": Color(0.18, 0.32, 0.16),
	"blasphemy": Color(0.50, 0.10, 0.08), "magma_stair": Color(0.42, 0.14, 0.08),
	"throne": Color(0.50, 0.18, 0.08), "architectium": Color(0.36, 0.40, 0.36), "workshop": Color(0.45, 0.28, 0.10),
	"golem_hall": Color(0.18, 0.32, 0.45), "rune_gallery": Color(0.18, 0.32, 0.45),
	"dark_cave": Color(0.20, 0.20, 0.23), "void": Color(0.22, 0.12, 0.34), "altar": Color(0.55, 0.48, 0.22),
	"spider_lair": Color(0.35, 0.15, 0.50),
	"thornwood": Color(0.22, 0.10, 0.10), "ruins": Color(0.40, 0.40, 0.46), "foothills": Color(0.45, 0.52, 0.60),
	"silk_loom": Color(0.42, 0.28, 0.48), "mirror_hall": Color(0.55, 0.55, 0.60), "beast_den": Color(0.42, 0.28, 0.16),
	"gallows": Color(0.30, 0.16, 0.38), "world_tree": Color(0.25, 0.45, 0.22), "satan_cave": Color(0.55, 0.12, 0.06),
	"sun_peak": Color(0.85, 0.72, 0.35), "ash_cathedral": Color(0.45, 0.10, 0.10),
	"golden_dunes": Color(0.78, 0.58, 0.28), "pilgrim_road": Color(0.70, 0.62, 0.48), "glass_oasis": Color(0.35, 0.60, 0.70),
	"prime_sanctum": Color(0.55, 0.36, 0.14), "sky_reliquary": Color(0.92, 0.80, 0.45),
}
## Size of the mini enemy figure on each space (small enemies drawn bigger).
const FIGURE_SCALE := {"parasite": 0.6, "kharleming": 0.75, "brute": 0.3, "hydra": 0.25, "golem": 0.36, "blinded_lord": 0.27,
	"architect_chorus": 0.1, "guard": 0.3, "follower": 0.34, "crawler": 0.36, "stray": 0.5, "blasphemy_caeser": 0.17,
	"copper": 0.32, "sparkling": 0.9, "atomic": 0.22, "warrior_a": 0.3, "forge_mother": 0.16, "arch_golem": 0.15,
	"crawling": 0.8, "escapist": 0.5, "void_soul": 0.6, "tentacle": 0.3, "masker": 0.26, "shining": 0.36, "void_massacre": 0.11,
	"ambusher": 0.45, "grin": 0.42, "pained": 0.3, "imp": 0.8, "needle": 0.36, "brothers": 0.3, "animal_lord": 0.13,
	"executor": 0.14, "mother_nature": 0.15, "false_god": 0.12, "satan": 0.1, "the_sun": 0.11,
	"counselor": 0.32, "camel": 0.2, "first_prime": 0.22, "enlightened_one": 0.26}
## Board page per Colosseum: title, board gradient, boss label colour. Tile colours and the
## zone labels come from each level's map (MAP_TILE / StoryLevels.MAPS "zone").
const PAGES := {
	1: {"title": "STORY MODE  -  COLOSSEUM 1: THE ASHEN DEPTHS",
		"board": [Color(0.42, 0.16, 0.08), Color(0.18, 0.10, 0.16)], "boss_label": Color(0.7, 1.0, 0.4)},
	2: {"title": "STORY MODE  -  COLOSSEUM 2: THE ASCENT",
		"board": [Color(0.22, 0.22, 0.28), Color(0.32, 0.10, 0.08)], "boss_label": Color(1.0, 0.6, 0.35)},
	3: {"title": "STORY MODE  -  COLOSSEUM 3: THE BURNING CROWN",
		"board": [Color(0.30, 0.10, 0.05), Color(0.14, 0.18, 0.24)], "boss_label": Color(0.5, 0.85, 1.0)},
	4: {"title": "STORY MODE  -  COLOSSEUM 4: THE VOID BELOW  (YOU ARE THE ARCHITECT)",
		"board": [Color(0.10, 0.10, 0.12), Color(0.12, 0.04, 0.18)], "boss_label": Color(0.8, 0.6, 1.0)},
	5: {"title": "STORY MODE  -  COLOSSEUM 5: THE FINAL ASCENT",
		"board": [Color(0.18, 0.08, 0.08), Color(0.55, 0.42, 0.20)], "boss_label": Color(1.0, 0.85, 0.4)},
	6: {"title": "STORY MODE  -  THE ENLIGHTENED CHASE",
		"board": [Color(0.62, 0.45, 0.20), Color(0.85, 0.70, 0.38)], "boss_label": Color(1.0, 0.95, 0.6)},
}
const PAWN_OFFSET := Vector2(30, 4)                # Pawn stands at the space's right edge

const WOOD := Color(0.30, 0.17, 0.09)
const WOOD_DARK := Color(0.16, 0.09, 0.05)
const GOLD := Color(1.0, 0.8, 0.3)
const PAWN := Color(0.50, 0.30, 0.85)
const PAWN_SHADE := Color(0.28, 0.14, 0.52)

var _board: Control
var _clip: Control                 # Cuts the scrolling content off at the board's edge
var _cv: Control                   # The scrolling content (same coordinates as _board)
var _scroll := 0.0                 # px the current Colosseum strip is scrolled to the left
var _scroll_target := 0.0
var _over := 0.0                   # Overscroll while dragging past an end (< 0 left, > 0 right)
var _slide := 0.0                  # Page-turn slide offset (eases back to 0)
var _press_pos := Vector2.ZERO
var _press_scroll := 0.0
var _pressed := false
var _dragging := false
var _t := 0.0
var _pawn_space := 1               # Space the pawn stands on (level number)
var _hop_from := 1
var _hop_to := 1
var _hop_t := -1.0                 # < 0 = not hopping
var _land_t := 10.0                # Time since landing (squash + dust)
var _celebrate := false
var _play: Button
var _switch: Button
var _ext_btn: Button
var _anti_btn: Button
var _solo_btn: Button
## Badge colours on the tiles (AchievementArt.draw_icon draws the icon).
const BADGE_COLORS := {"no_powers": Color(0.95, 0.75, 0.15), "no_blocks": Color(0.30, 0.55, 1.0),
	"no_healing": Color(0.25, 0.80, 0.35), "no_gauge": Color(0.10, 0.75, 0.90), "solo": Color(0.70, 0.35, 1.0)}
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
	if ext_return != "":
		# Back from a boss extension level: stand on its boss and reopen the extension menu
		var key := ext_return
		ext_return = ""
		advance_from = 0
		_pawn_space = clampi(int(StoryLevels.EXTENSIONS[key]["parent"]), 1, StoryProgress.unlocked_level)
		_page = StoryLevels.colosseum_of(_pawn_space)
		_refresh_ui()
		_open_extensions.call_deferred(key)
		return
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
	# Scrolling content: _clip (board-sized, clips) > _cv (screen-sized, same coords as _board)
	_clip = Control.new()
	_clip.clip_contents = true
	_clip.mouse_filter = Control.MOUSE_FILTER_IGNORE
	_board.add_child(_clip)
	_cv = Control.new()
	_cv.mouse_filter = Control.MOUSE_FILTER_IGNORE
	_clip.add_child(_cv)
	_cv.draw.connect(_draw_content)

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
	row.offset_left = -500
	row.offset_right = 500
	row.alignment = BoxContainer.ALIGNMENT_CENTER
	row.add_theme_constant_override("separation", 14)
	add_child(row)
	var back := UiStyle.make_button("< BACK", Vector2(150, 56), 20)
	back.pressed.connect(_go_back)
	row.add_child(back)
	_play = UiStyle.make_button("PLAY", Vector2(280, 56), 22)
	_play.pressed.connect(_on_play)
	row.add_child(_play)
	# Colosseum 5 only: swap which hero you play (the other one is your CPU partner)
	_switch = UiStyle.make_button("SWITCH HERO", Vector2(230, 56), 18)
	_switch.pressed.connect(_switch_hero)
	_switch.visible = false
	row.add_child(_switch)
	# Colosseum 5 only: SOLO mode (no CPU partner) - achievements + the SOLO badge
	_solo_btn = UiStyle.make_button("SOLO: OFF", Vector2(170, 56), 18)
	_solo_btn.pressed.connect(_toggle_solo)
	_solo_btn.visible = false
	row.add_child(_solo_btn)
	# Anti Architect run: play every Story level SOLO as the Anti Architect (saved toggle).
	# Own spot in the top-left corner, left of the title (the bottom row is full on C5 / extension pages).
	_anti_btn = UiStyle.make_button("HERO: STORY HEROES", Vector2(220, 40), 14)
	_anti_btn.set_anchors_and_offsets_preset(Control.PRESET_TOP_LEFT)
	_anti_btn.offset_left = 12
	_anti_btn.offset_right = 232
	_anti_btn.offset_top = 12
	_anti_btn.offset_bottom = 52
	_anti_btn.pressed.connect(_toggle_anti)
	add_child(_anti_btn)
	# Boss extensions of this page (BC, AG, VM, AC, FM)
	_ext_btn = UiStyle.make_button("BOSS EXTENSIONS", Vector2(230, 56), 17)
	_ext_btn.pressed.connect(func() -> void: _open_extensions(""))
	_ext_btn.visible = false
	row.add_child(_ext_btn)
	var reset := UiStyle.make_button("RESET", Vector2(150, 56), 16)
	reset.pressed.connect(_reset.bind(reset))
	row.add_child(reset)


func _refresh_ui() -> void:
	var lv := StoryLevels.get_level(_pawn_space)
	# Colosseum 5 ("choice") and The Enlightened Chase ("chase"): you can switch your hero
	var choice := String(lv.get("hero", "")) in ["choice", "chase"] and not _celebrate and not StoryProgress.anti_story
	_switch.visible = choice
	_solo_btn.visible = choice and bool(lv.get("partner", false))       # SOLO only matters with a partner
	_solo_btn.text = "SOLO: %s" % ("ON" if StoryProgress.c5_solo else "OFF")
	_solo_btn.modulate = Color(0.85, 0.6, 1.0) if StoryProgress.c5_solo else Color(1, 1, 1)
	_anti_btn.text = "HERO: ANTI ARCHITECT" if StoryProgress.anti_story else "HERO: STORY HEROES"
	_anti_btn.modulate = Color(1.0, 0.65, 0.3) if StoryProgress.anti_story else Color(1, 1, 1)
	_ext_btn.visible = not StoryLevels.exts_on_page(_page).is_empty()
	if choice:
		_switch.text = "PLAY AS %s" % ("WARRIOR" if StoryLevels.hero_of(_pawn_space) == "architect" else "ARCHITECT")
	_title.text = String(_page_data().get("title", "STORY MODE"))
	if _celebrate:
		var boss_names := {1: "The Blinded Lord", 2: "Blasphemy Caeser", 3: "The Architect's Golem", 4: "The Void Massacre", 5: "The Sun", 6: "The Enlightened One"}
		if _final_page():
			_info.text = "TO BE CONTINUED...  The Enlightened One has fallen, but his hoard rose into a dark cloud."
		else:
			_info.text = "%s COMPLETE!  %s has fallen.  Next: %s" % [
				StoryLevels.part_name(_page), boss_names.get(_page, "The boss"), StoryLevels.part_name(_page + 1)]
		_info.add_theme_color_override("font_color", GOLD)
		_play.text = "REPLAY BOSS"
	else:
		_info.add_theme_color_override("font_color", UiStyle.TEXT)
		var boss := String(lv.get("boss", "")) != ""
		var hero_name := "You play as the ARCHITECT" if StoryLevels.hero_of(_pawn_space) == "architect" else "Warrior only"
		if StoryProgress.anti_story:
			hero_name = "You play as the ANTI ARCHITECT (solo)"
		elif StoryLevels.is_solo(_pawn_space):
			hero_name = "YOU: %s  -  SOLO (no partner)" % StoryLevels.hero_of(_pawn_space).to_upper()
		elif bool(lv.get("partner", false)):
			var h := StoryLevels.hero_of(_pawn_space)
			hero_name = "YOU: %s  +  CPU partner: %s" % [h.to_upper(), "ARCHITECT" if h == "warrior" else "WARRIOR"]
		elif String(lv.get("hero", "")) == "chase":
			hero_name = "YOU: %s  -  alone (your partner is hurt)" % StoryLevels.hero_of(_pawn_space).to_upper()
		var tag := "  (BOSS)" if boss else ""
		if String(lv.get("boss_sub", "")).begins_with("Mini-Boss"):
			tag = "  (MINI-BOSS)"
		if StoryLevels.is_optional(_pawn_space):
			tag = "  (OPTIONAL - skip it with Right)"
		var nf := StoryManager.FLASKS_PER_LEVEL
		if StoryLevels.hero_of(_pawn_space) != "anti":
			nf += StoryManager.DEEP_FAITH_EXTRA_FLASKS          # Deep Faith Payoff (Warrior / Architect)
		_info.text = "Level %d: %s%s    |    %s    |    R = Flask (%d per level)" % [_pawn_space, lv["title"], tag, hero_name, nf]
		_play.text = "PLAY LEVEL %d" % _pawn_space


func _board_rect() -> Rect2:
	var sz := size
	return Rect2(Vector2(40, 96), Vector2(sz.x - 80, sz.y - 190))


## Distance between two spaces of Colosseum c (small Colosseums spread out to fill the board).
func _spacing(c: int) -> float:
	var r := _board_rect()
	var n := StoryLevels.size_of(c)
	return maxf(SPACING, (r.size.x - MARGIN_L - MARGIN_R) / float(maxi(n - 1, 1)))


## Width of Colosseum c's whole strip (wider than the board = it scrolls).
func _content_w(c: int) -> float:
	return MARGIN_L + float(StoryLevels.size_of(c) - 1) * _spacing(c) + MARGIN_R


func _max_scroll() -> float:
	return maxf(_content_w(_page) - _board_rect().size.x, 0.0)


## Strip position (x along the strip, y 0..1) of the i-th space: a slow wave.
func _strip_point(c: int, i: float) -> Vector2:
	return Vector2(MARGIN_L + i * _spacing(c), WAVE_MID + WAVE_AMP * sin(i * WAVE_FREQ + 0.3))


## Strip x / height-fraction -> board (screen) position, with the current scroll.
func _to_board(p: Vector2) -> Vector2:
	var r := _board_rect()
	return r.position + Vector2(p.x - _scroll - _over + _slide, p.y * r.size.y)


## Board position of a level's space (on its own Colosseum's strip, scrolled).
func _space_pos(level: int) -> Vector2:
	var c := StoryLevels.colosseum_of(level)
	return _to_board(_strip_point(c, float(level - StoryLevels.first_of(c))))


## Scroll so that a level's space is comfortably on screen (instant = no glide).
func _focus(level: int, instant: bool = false) -> void:
	if StoryLevels.colosseum_of(level) != _page:
		return
	var r := _board_rect()
	var x := _strip_point(_page, float(level - _page_first())).x
	var target := clampf(_scroll_target, x - r.size.x * 0.72, x - r.size.x * 0.28)
	_scroll_target = clampf(target, 0.0, _max_scroll())
	if instant:
		_scroll = _scroll_target


func _page_data() -> Dictionary:
	return PAGES.get(_page, PAGES[1])


func _page_first() -> int:
	return StoryLevels.first_of(_page)


func _page_last() -> int:
	return mini(StoryLevels.last_of(_page), StoryLevels.count())


## 0 = the fog space leading to the next part, 1 = the very last level far away (strip end).
func _teaser_pos(i: int) -> Vector2:
	var last_i := float(StoryLevels.size_of(_page) - 1)
	var x := _strip_point(_page, last_i).x + (125.0 if i == 0 else 225.0)
	return _to_board(Vector2(x, 0.40 if i == 0 else 0.20))


# ============================================================
# PAWN MOVEMENT
# ============================================================
func _hop(to_level: int) -> void:
	if to_level == _pawn_space or _hop_t >= 0.0:
		return
	if StoryLevels.colosseum_of(to_level) != _page:
		# Other Colosseum: its strip SLIDES in (from the right going forward), the pawn lands on its space
		var forward := StoryLevels.colosseum_of(to_level) > _page
		_page = StoryLevels.colosseum_of(to_level)
		_pawn_space = to_level
		_land_t = 0.0
		_over = 0.0
		_slide = _board_rect().size.x * (0.7 if forward else -0.7)
		_scroll_target = 0.0 if forward else _max_scroll()
		_focus(to_level, true)
		SoundManager.play_sfx("whoosh", -6.0)
		SoundManager.play_sfx("spawn", -4.0)
		_refresh_ui()
		if StoryManager.autoplay:
			_autoplay_next()
		return
	_hop_from = _pawn_space
	_hop_to = to_level
	_hop_t = 0.0
	_focus(to_level)                                    # Glide along so the pawn stays in view
	SoundManager.play_sfx("jump")


var _snapped := false


func _process(delta: float) -> void:
	_t += delta
	_land_t += delta
	var r := _board_rect()
	_clip.position = r.position
	_clip.size = r.size
	_cv.position = -r.position
	_cv.size = size
	if not _snapped:                                    # First frame (sizes are known now)
		_snapped = true
		_focus(_pawn_space, true)
	if not _dragging:
		_scroll = lerpf(_scroll, _scroll_target, clampf(delta * 10.0, 0.0, 1.0))
		_over = lerpf(_over, 0.0, clampf(delta * 12.0, 0.0, 1.0))
	_slide = lerpf(_slide, 0.0, clampf(delta * 9.0, 0.0, 1.0))
	_cv.queue_redraw()
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
## DRAG the board to scroll its strip; drag past an end + let go = next / previous Colosseum.
## A press that doesn't move (less than DRAG_START px) is a CLICK on a space / extension sign.
## (Touch arrives as emulated mouse events.) Mouse wheel scrolls too.
func _on_board_input(event: InputEvent) -> void:
	if _busy:
		return
	var mb := event as InputEventMouseButton
	if mb != null:
		if mb.pressed and mb.button_index in [MOUSE_BUTTON_WHEEL_UP, MOUSE_BUTTON_WHEEL_LEFT]:
			_scroll_target = clampf(_scroll_target - 90.0, 0.0, _max_scroll())
			return
		if mb.pressed and mb.button_index in [MOUSE_BUTTON_WHEEL_DOWN, MOUSE_BUTTON_WHEEL_RIGHT]:
			_scroll_target = clampf(_scroll_target + 90.0, 0.0, _max_scroll())
			return
		if mb.button_index != MOUSE_BUTTON_LEFT:
			return
		if mb.pressed:
			_pressed = true
			_dragging = false
			_press_pos = mb.position
			_press_scroll = _scroll
			return
		if not _pressed:
			return
		_pressed = false
		if _dragging:
			_dragging = false
			_end_drag()
		else:
			_click(mb.position)
		return
	var mm := event as InputEventMouseMotion
	if mm != null and _pressed:
		var dx := mm.position.x - _press_pos.x
		if not _dragging and absf(dx) > DRAG_START:
			_dragging = true
		if _dragging and _hop_t < 0.0:
			var raw := _press_scroll - dx
			_scroll = clampf(raw, 0.0, _max_scroll())
			_scroll_target = _scroll
			_over = clampf((raw - _scroll) * 0.5, -OVER_MAX, OVER_MAX)   # Rubbery pull past the ends


## Let go after a drag: pulled far enough past an end -> turn to that Colosseum.
func _end_drag() -> void:
	if _over <= -OVER_TURN:
		if _page > 1:
			_celebrate = false
			_hop(_page_first() - 1)
	elif _over >= OVER_TURN:
		var nxt := _page_last() + 1
		if nxt <= StoryProgress.unlocked_level and nxt <= StoryLevels.count():
			_celebrate = false
			_hop(nxt)
		else:
			SoundManager.play_sfx("block")                  # Next Colosseum still locked


func _click(pos: Vector2) -> void:
	if not _board_rect().has_point(pos):
		return
	for k in StoryLevels.exts_on_page(_page):               # Boss extension signs
		if pos.distance_to(_ext_badge_pos(k)) <= 34.0:
			_open_extensions(k)
			return
	for n in range(_page_first(), _page_last() + 1):
		var half := (BOSS_TILE if _is_boss(n) else TILE) * 0.5 + 6.0
		if pos.distance_to(_space_pos(n)) <= half:
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
	# Colosseum 5: pick your hero the first time (later: the SWITCH / PLAY AS button on the board)
	if String(StoryLevels.get_level(_pawn_space).get("hero", "")) in ["choice", "chase"] and StoryProgress.c5_hero == "" and not StoryProgress.anti_story:
		var pick := HeroSelect.new()
		add_child(pick)
		await pick.chosen
		_refresh_ui()
	var cs := String(StoryLevels.get_level(_pawn_space).get("cutscene_in", ""))
	var art: Script = StoryLevels.hero_art(StoryLevels.hero_of(_pawn_space))
	if cs != "":
		# Level with its own intro cutscene (Elevator from Hell, falling into the Sewers)
		var scene := StoryCutscene.new()
		scene.kind = cs
		scene.hero_art = art
		add_child(scene)
		await scene.finished
	else:
		var fall := CaveFall.new()
		fall.hero_art = art
		fall.caption = "LEVEL %d:  %s" % [_pawn_space, StoryLevels.get_level(_pawn_space)["title"]]
		add_child(fall)
		await fall.finished
	get_tree().change_scene_to_file(StoryManager.ARENA_SCENE)


## Colosseum 5: play as the other hero from now on (saved). The one you leave becomes
## your CPU partner.
func _switch_hero() -> void:
	if _busy or _hop_t >= 0.0:
		return
	var now := StoryLevels.hero_of(_pawn_space)
	StoryProgress.set_c5_hero("warrior" if now == "architect" else "architect")
	SoundManager.play_sfx("spawn")
	_refresh_ui()


## Colosseum 5 SOLO mode on / off (saved): fight without the CPU partner.
func _toggle_solo() -> void:
	if _busy or _hop_t >= 0.0:
		return
	StoryProgress.set_c5_solo(not StoryProgress.c5_solo)
	SoundManager.play_sfx("spawn")
	_refresh_ui()


## Anti Architect run on / off (saved). On: every main Story level is played solo as him.
func _toggle_anti() -> void:
	if _busy or _hop_t >= 0.0:
		return
	StoryProgress.set_anti_story(not StoryProgress.anti_story)
	SoundManager.play_sfx("spawn")
	_refresh_ui()
	queue_redraw()
	if _board != null:
		_board.queue_redraw()


## BOSS EXTENSIONS menu for this page (focus = an extension key to highlight, or "").
func _open_extensions(focus: String) -> void:
	if _busy or _hop_t >= 0.0:
		return
	var keys := StoryLevels.exts_on_page(_page)
	if keys.is_empty():
		return
	var menu := ExtensionMenu.new()
	menu.keys = keys
	menu.focus_key = focus
	add_child(menu)
	menu.chosen.connect(_play_ext)
	menu.closed.connect(func() -> void: _play.grab_focus.call_deferred())


## Fall into a boss extension level with the hero picked in the menu.
func _play_ext(n: int) -> void:
	if _busy:
		return
	_busy = true
	StoryProgress.current_level = n
	var fall := CaveFall.new()
	fall.hero_art = StoryLevels.hero_art(StoryLevels.hero_of(n))
	fall.caption = "%s:  %s" % [StoryLevels.ext_code(n), StoryLevels.get_level(n)["title"]]
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
	elif _page >= 3:
		_draw_scenery_n(r)
	else:
		_draw_scenery(r)
	# Drag hint along the bottom edge of the frame
	var hint := "<  DRAG THE BOARD  >"
	if _page > 1 or _page_last() < StoryLevels.count():
		hint += "      (drag past the end for the %s part)" % ("next / previous" if _page > 1 and not _final_page() else ("previous" if _final_page() else "next"))
	FighterArt.label(c, Vector2(r.get_center().x, r.end.y + 12.0), hint, 12, Color(1.0, 0.9, 0.7, 0.75))


## The SCROLLING part of the board (on _cv, clipped to the board): zone names, the path,
## the spaces, the page marks, the extension signs and the pawn.
func _draw_content() -> void:
	var r := _board_rect()
	var c := _cv
	# Zone labels: one per run of levels in the same area, alternating top / bottom
	_zone_labels(r)

	# Path (dotted road) between the spaces, then fading toward the next Colosseum / The Sun
	var first := _page_first()
	var last := _page_last()
	for n in range(first, last):
		_road(_space_pos(n), _space_pos(n + 1), n < StoryProgress.unlocked_level)
	var next_open := last + 1 <= StoryProgress.unlocked_level and last + 1 <= StoryLevels.count()
	if not _final_page():
		_road(_space_pos(last), _teaser_pos(0), next_open, 1.0 if next_open else 0.5)
		_road(_teaser_pos(0), _teaser_pos(1), false, 0.25)
	if _page > 1:
		_road(_back_pos(), _space_pos(first), true, 0.7)

	# Spaces
	for n in range(first, last + 1):
		_space(n)
	_teasers()
	_ext_badges()

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


func _ext_badge_pos(k: String) -> Vector2:
	var e: Dictionary = StoryLevels.EXTENSIONS[k]
	var dir := String(e["dir"])
	var off := Vector2(0, 66) if dir == "down" else (Vector2(0, -70) if dir == "up" else Vector2(62, -50))
	return _space_pos(int(e["parent"])) + off


## BOSS EXTENSIONS: a small sign next to each boss space that has one ("BC" + arrow down / up),
## locked until that boss is beaten, with check marks for the cleared levels.
func _ext_badges() -> void:
	var c := _cv
	for k in StoryLevels.exts_on_page(_page):
		var e: Dictionary = StoryLevels.EXTENSIONS[k]
		var base := _space_pos(int(e["parent"]))
		var dir := String(e["dir"])
		var p := _ext_badge_pos(k)
		var off := p - base
		var open := StoryProgress.ext_open(k)
		var done := StoryProgress.ext_cleared(k)
		var col := GOLD if open else Color(0.55, 0.55, 0.6)
		c.draw_line(base + off * 0.45, p - off.normalized() * 18.0, Color(col.r, col.g, col.b, 0.8), 4.0)
		var box := Rect2(p - Vector2(30, 16), Vector2(60, 32))
		FighterArt.rrect(c, box, Color(0.12, 0.08, 0.06), Color(0.08, 0.05, 0.04), col.darkened(0.3), 8.0, 3.0)
		FighterArt.label(c, p + Vector2(0, 6), k, 16, col)
		var arrow := "v" if dir == "down" else ("^" if dir == "up" else ">")
		FighterArt.label(c, p + Vector2(22, 6), arrow, 14, col)
		for i in 3:                                          # Progress pips
			var pip := p + Vector2(-14 + float(i) * 14.0, 22)
			c.draw_circle(pip, 4.5, EnemyArt.BLACK)
			c.draw_circle(pip, 3.2, Color(0.4, 1.0, 0.4) if i < done else Color(0.3, 0.3, 0.32))
		if not open:
			FighterArt.label(c, p + Vector2(0, -22), "LOCKED", 11, Color(0.8, 0.8, 0.85, 0.8))


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


## Colosseum 3+ pages: a few landmark doodles per page.
func _draw_scenery_n(r: Rect2) -> void:
	var c := _board
	if _page == 3:
		# Burning throne (bottom left)
		var th := r.position + Vector2(r.size.x * 0.12, r.size.y * 0.62)
		c.draw_rect(Rect2(th.x - 18, th.y - 40, 36, 50), Color(0.35, 0.15, 0.08, 0.9))
		c.draw_rect(Rect2(th.x - 24, th.y + 10, 48, 10), Color(0.35, 0.15, 0.08, 0.9))
		for k in 5:
			var fx := th.x - 30.0 + float(k) * 15.0
			var fh := 20.0 + 10.0 * sin(_t * 6.0 + float(k))
			c.draw_colored_polygon(PackedVector2Array([Vector2(fx - 6, th.y + 20), Vector2(fx + 6, th.y + 20), Vector2(fx, th.y + 20 - fh)]), Color(1.0, 0.5, 0.1, 0.8))
		# Gears of the Architectium (top middle)
		for k in 3:
			var gp := r.position + Vector2(r.size.x * (0.3 + 0.08 * float(k)), r.size.y * 0.26)
			var pts := PackedVector2Array()
			for i in 16:
				var a := TAU * float(i) / 16.0 + _t * (0.6 if k % 2 == 0 else -0.6)
				pts.append(gp + Vector2.from_angle(a) * (22.0 if i % 2 == 0 else 16.0))
			c.draw_colored_polygon(pts, Color(0.55, 0.6, 0.55, 0.7))
		# Furnace glow (bottom right) + rune circle (top right)
		c.draw_circle(r.position + Vector2(r.size.x * 0.6, r.size.y * 0.86), 40.0 + 4.0 * sin(_t * 3.0), Color(1.0, 0.5, 0.1, 0.3))
		c.draw_arc(r.position + Vector2(r.size.x * 0.72, r.size.y * 0.42), 40.0, 0.0, TAU, 24, Color(0.4, 0.85, 1.0, 0.5 + 0.3 * sin(_t * 2.0)), 4.0, true)
	elif _page >= StoryLevels.CHASE_PART:
		# The Enlightened Chase: golden dunes, statues of him, a stairway of light into the sky (right)
		var base6 := r.position.y + r.size.y
		for k in 3:
			var dx := r.position.x + r.size.x * (0.1 + 0.32 * float(k))
			c.draw_colored_polygon(PackedVector2Array([Vector2(dx - 160.0, base6), Vector2(dx, base6 - 60.0 - 20.0 * float(k)), Vector2(dx + 170.0, base6)]), Color(0.95, 0.75, 0.40, 0.35))
		for k in 4:
			var sx := r.position.x + r.size.x * (0.12 + 0.2 * float(k))
			var sy := r.position.y + r.size.y * 0.30
			c.draw_rect(Rect2(sx - 8.0, sy - 40.0, 16.0, 46.0), Color(0.80, 0.60, 0.28, 0.6))
			c.draw_circle(Vector2(sx, sy - 48.0), 9.0, Color(0.80, 0.60, 0.28, 0.6))
			c.draw_arc(Vector2(sx, sy - 50.0), 14.0, 0.0, TAU, 16, Color(1.0, 0.9, 0.5, 0.6), 2.0)
		for k in 8:                                            # Stairway of light (final level)
			var st := r.position + Vector2(r.size.x * (0.80 + 0.02 * float(k)), r.size.y * (0.42 - 0.045 * float(k)))
			c.draw_rect(Rect2(st.x - 22.0, st.y, 44.0, 8.0), Color(1.0, 0.92, 0.6, 0.35 + 0.05 * float(k)))
	elif _page >= 5:
		# Colosseum 5: the mountain rising to the right, its peak glowing (The Sun), a red sky
		var base := r.position.y + r.size.y
		c.draw_colored_polygon(PackedVector2Array([Vector2(r.position.x + r.size.x * 0.30, base), Vector2(r.position.x + r.size.x * 0.62, r.position.y + r.size.y * 0.30),
			Vector2(r.position.x + r.size.x * 0.80, r.position.y + r.size.y * 0.08), Vector2(r.position.x + r.size.x * 0.96, base)]), Color(0.10, 0.06, 0.06, 0.55))
		var peak := r.position + Vector2(r.size.x * 0.80, r.size.y * 0.08)
		c.draw_circle(peak, 60.0 + 6.0 * sin(_t * 2.0), Color(1.0, 0.9, 0.5, 0.25))
		c.draw_circle(peak, 24.0, Color(1.0, 0.95, 0.7, 0.7))
		for k in 3:                                            # Thorn trees on the left
			var tx := r.position.x + r.size.x * (0.05 + 0.08 * float(k))
			c.draw_line(Vector2(tx, base - 10.0), Vector2(tx + 6.0, base - 80.0 - float(k) * 14.0), Color(0.08, 0.03, 0.03, 0.7), 5.0)
	else:
		# Colosseum 4: dark cave (left), void bones (bottom), altar light (middle), spider web (right)
		var cave := r.position + Vector2(r.size.x * 0.1, r.size.y * 0.5)
		c.draw_set_transform(cave, 0.0, Vector2(1.0, 0.7))
		c.draw_circle(Vector2.ZERO, 50.0, Color(0.02, 0.02, 0.03, 0.9))
		c.draw_set_transform(Vector2.ZERO, 0.0, Vector2.ONE)
		for k in 6:
			var bp := r.position + Vector2(r.size.x * (0.3 + 0.07 * float(k)), r.size.y * 0.9)
			c.draw_line(bp + Vector2(-10, -4), bp + Vector2(10, 4), Color(0.8, 0.78, 0.7, 0.6), 4.0)
			c.draw_circle(bp + Vector2(-10, -4), 3.0, Color(0.8, 0.78, 0.7, 0.6))
		c.draw_circle(r.position + Vector2(r.size.x * 0.44, r.size.y * 0.36), 34.0 + 4.0 * sin(_t * 2.0), Color(1.0, 0.9, 0.5, 0.25))
		var web := r.position + Vector2(r.size.x * 0.72, r.size.y * 0.42)
		for i in 8:
			c.draw_line(web, web + Vector2.from_angle(TAU * float(i) / 8.0) * 50.0, Color(0.85, 0.85, 0.9, 0.4), 1.5)
		for k in 3:
			c.draw_arc(web, 15.0 + float(k) * 15.0, 0.0, TAU, 8, Color(0.85, 0.85, 0.9, 0.4), 1.5)
	var sun := _teaser_pos(1)
	c.draw_circle(sun, 70.0 + 6.0 * sin(_t * 2.0), Color(1.0, 0.8, 0.3, 0.10))


func _zone_labels(r: Rect2) -> void:
	var runs := []                                          # [zone, first level, last level, map]
	for n in range(_page_first(), _page_last() + 1):
		var key := String(StoryLevels.get_level(n).get("map", "wastes"))
		var zone := String(StoryLevels.MAPS.get(key, {}).get("zone", ""))
		if runs.is_empty() or runs[-1][0] != zone:
			runs.append([zone, n, n, key])
		else:
			runs[-1][2] = n
	if runs.size() > 14:
		return                                              # Too many areas to label: the info line names each level
	for i in runs.size():
		var run: Array = runs[i]
		if String(run[0]) == "":
			continue
		var x := (_space_pos(int(run[1])).x + _space_pos(int(run[2])).x) * 0.5
		var y := r.position.y + r.size.y * (0.06 if i % 2 == 1 else 0.98)
		var col: Color = MAP_TILE.get(String(run[3]), Color(0.8, 0.7, 0.6))
		col = col.lightened(0.55)
		col.a = 0.9
		FighterArt.label(_cv, Vector2(x, y), String(run[0]), 18, col)


func _road(a: Vector2, b: Vector2, lit: bool, alpha: float = 1.0) -> void:
	var mid := (a + b) * 0.5 + (b - a).orthogonal().normalized() * 26.0
	var steps := 14
	for i in steps:
		var k := (float(i) + 0.5) / float(steps)
		var p := a.lerp(mid, k).lerp(mid.lerp(b, k), k)       # Quadratic curve
		c_dot(p, lit, alpha)


func c_dot(p: Vector2, lit: bool, alpha: float) -> void:
	_cv.draw_circle(p, 6.0, Color(0, 0, 0, 0.8 * alpha))
	_cv.draw_circle(p, 4.0, Color(GOLD.r, GOLD.g, GOLD.b, alpha) if lit else Color(0.55, 0.45, 0.4, alpha))


func _space(n: int) -> void:
	var c := _cv
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
	var optional := StoryLevels.is_optional(n)
	var fill: Color = MAP_TILE.get(String(StoryLevels.get_level(n).get("map", "wastes")), Color(0.4, 0.3, 0.25))
	if not unlocked:
		fill = Color(0.25, 0.23, 0.23)
	c.draw_colored_polygon(top, fill)
	if here:
		c.draw_polyline(_closed(top), Color(1, 1, 1, 0.5 + 0.5 * sin(_t * 5.0)), 6.0, true)
	if optional and not cleared:                            # Optional: dashed gold border
		var pts := _closed(top)
		for i in pts.size() - 1:
			if i % 2 == 0:
				c.draw_line(pts[i], pts[i + 1], GOLD, 3.5, true)
	else:
		c.draw_polyline(_closed(top), GOLD if cleared else Color(0, 0, 0), 3.5, true)
	# Mini enemy figure on the tile
	var center := rect.get_center() + Vector2(0, -6)
	if unlocked:
		var id := StoryLevels.tile_enemy(n)
		var sc: float = FIGURE_SCALE.get(StoryLevels.base_id(id), 0.3)
		c.draw_set_transform(center + Vector2(0, s * 0.32), 0.0, Vector2(sc, sc))
		StoryLevels.draw_portrait(c, id, _t)
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
	elif optional:
		FighterArt.label(c, rect.get_center() + Vector2(0, s * 0.5 + 18.0), "OPTIONAL", 14, GOLD)
	if cleared:                                            # Check mark
		var ck := rect.end + Vector2(-8, -12)
		c.draw_circle(ck, 12.0, Color(0, 0, 0))
		c.draw_circle(ck, 9.5, Color(0.3, 0.8, 0.3))
		c.draw_polyline(PackedVector2Array([ck + Vector2(-5, 0), ck + Vector2(-1, 4), ck + Vector2(5, -4)]), Color.WHITE, 2.5, true)
	# Challenge BADGES earned on this level (Achievements): a row along the tile's bottom edge
	var got := StoryProgress.badges_of(n)
	if not got.is_empty():
		var step := 19.0
		var x0 := rect.get_center().x - step * float(got.size() - 1) * 0.5
		for i in got.size():
			var k := String(got[i])
			var bp := Vector2(x0 + step * float(i), rect.end.y - 4.0)
			var bc: Color = BADGE_COLORS.get(k, GOLD)
			c.draw_circle(bp, 9.5, Color(0, 0, 0))
			c.draw_circle(bp, 7.5, bc.darkened(0.45))
			AchievementArt.draw_icon(c, k, bp, 5.5, [Color.WHITE, bc.darkened(0.5), Color.WHITE], false)


## "< previous Colosseum" mark at the start of the strip.
func _back_pos() -> Vector2:
	return _to_board(Vector2(MARGIN_L - 108.0, 0.50))


## The last page (The Enlightened Chase, ending with Level 62): no "next part" teaser.
func _final_page() -> bool:
	return _page_last() >= StoryProgress.TOTAL_LEVELS


func _teasers() -> void:
	var c := _cv
	if _final_page():
		if _page > 1:
			var bk := _back_pos()
			c.draw_circle(bk, 30.0, Color(1.0, 0.8, 0.3, 0.3))
			FighterArt.label(c, bk + Vector2(0, 7), "< %d" % (_page_first() - 1), 18, Color(1, 1, 1, 0.85))
			FighterArt.label(c, bk + Vector2(0, 46), StoryLevels.part_name(_page - 1), 12, Color(1, 1, 1, 0.7))
			FighterArt.label(c, bk + Vector2(0, 64), "DRAG  >>>", 12, Color(1.0, 0.9, 0.6, 0.7))
		return
	var p := _teaser_pos(0)
	var nxt := _page_last() + 1
	var open := nxt <= StoryProgress.unlocked_level and nxt <= StoryLevels.count()
	var pulse := 0.5 + 0.5 * sin(_t * 4.0)
	c.draw_circle(p, 34.0, Color(1.0, 0.8, 0.3, 0.35 + 0.25 * pulse) if open else Color(0.5, 0.45, 0.45, 0.25))
	FighterArt.label(c, p + Vector2(0, 8), "%d %s" % [nxt, ">" if open else "..."], 20, Color(1, 1, 1, 0.9 if open else 0.45))
	FighterArt.label(c, p + Vector2(0, 52), StoryLevels.part_name(_page + 1), 13, Color(1, 1, 1, 0.8 if open else 0.4))
	FighterArt.label(c, p + Vector2(0, 70), "DRAG  <<<" if open else "LOCKED", 12, Color(1.0, 0.9, 0.6, 0.6 + 0.3 * pulse) if open else Color(1, 1, 1, 0.35))
	if _page > 1:                                           # Way back to the previous Colosseum
		var b := _back_pos()
		c.draw_circle(b, 30.0, Color(1.0, 0.8, 0.3, 0.3))
		FighterArt.label(c, b + Vector2(0, 7), "< %d" % (_page_first() - 1), 18, Color(1, 1, 1, 0.85))
		FighterArt.label(c, b + Vector2(0, 46), StoryLevels.part_name(_page - 1), 12, Color(1, 1, 1, 0.7))
		FighterArt.label(c, b + Vector2(0, 64), "DRAG  >>>", 12, Color(1.0, 0.9, 0.6, 0.7))
	var sun := _teaser_pos(1)
	c.draw_circle(sun, 30.0, Color(1.0, 0.75, 0.25, 0.6))
	c.draw_circle(sun, 22.0, Color(1.0, 0.92, 0.5, 0.8))
	for i in 10:
		var a := TAU * float(i) / 10.0 + _t * 0.3
		c.draw_line(sun + Vector2.from_angle(a) * 36.0, sun + Vector2.from_angle(a) * 48.0, Color(1.0, 0.8, 0.3, 0.6), 3.0)
	FighterArt.label(c, sun + Vector2(0, 70), "%d: %s" % [StoryProgress.TOTAL_LEVELS, String(StoryLevels.get_level(StoryProgress.TOTAL_LEVELS).get("title", ""))], 15, Color(1.0, 0.85, 0.4, 0.8))


func _lock(p: Vector2) -> void:
	var c := _cv
	c.draw_arc(p + Vector2(0, -8), 10.0, PI, TAU, 12, Color(0, 0, 0), 6.0)
	c.draw_arc(p + Vector2(0, -8), 10.0, PI, TAU, 12, Color(0.6, 0.6, 0.6), 3.0)
	var body := FighterArt.rrect_points(Rect2(p.x - 14, p.y - 8, 28, 22), 4.0)
	c.draw_colored_polygon(body, Color(0.6, 0.6, 0.6))
	FighterArt.outline(c, body, 3.0)
	c.draw_circle(p + Vector2(0, 2), 3.0, Color(0.2, 0.2, 0.2))


## Classic board-game pawn in the Warrior's purple, with a little void mask.
func _pawn(p: Vector2) -> void:
	var c := _cv
	var squash := 1.0
	if _land_t < 0.25:
		squash = 1.0 - 0.25 * sin(_land_t / 0.25 * PI)
	var bob := sin(_t * 3.0) * 3.0 if _hop_t < 0.0 else 0.0
	var h := 70.0 * squash
	var base_c := p + Vector2(0, 0)
	# Colosseum 4: you are the ARCHITECT -> white pawn, green trim, dark visor, blue core
	var who := StoryLevels.hero_of(_hop_to if _hop_t >= 0.0 else _pawn_space)
	var arch := who == "architect"
	var pc := Color(0.95, 0.96, 0.98) if arch else StoryBoard.PAWN
	var ps := Color(0.22, 0.86, 0.28) if arch else StoryBoard.PAWN_SHADE
	if who == "anti":                            # Anti Architect: the negative - black pawn, orange trim
		pc = Color(0.12, 0.12, 0.14)
		ps = Color(1.0, 0.45, 0.05)
	# Base disc
	var base := EnemyArt.ellipse_points(base_c, 24, 9, 18)
	c.draw_colored_polygon(base, ps)
	FighterArt.outline(c, base, 3.0)
	# Body (cone)
	var top := base_c + Vector2(0, -h * 0.62 + bob)
	var body := PackedVector2Array([base_c + Vector2(-18, -4), top + Vector2(-7, 0), top + Vector2(7, 0), base_c + Vector2(18, -4)])
	c.draw_polygon(body, PackedColorArray([ps, pc, pc.lightened(0.2), ps]))
	FighterArt.outline(c, body, 3.0)
	# Collar
	var collar := EnemyArt.ellipse_points(top, 13, 4.5, 14)
	c.draw_colored_polygon(collar, pc.lightened(0.15))
	FighterArt.outline(c, collar, 2.5)
	# Head + void mask
	var head := top + Vector2(0, -15)
	FighterArt.ball(c, head, 15.0, pc, ps, pc.lightened(0.45))
	if arch:                                               # Dark visor + blue core
		c.draw_colored_polygon(PackedVector2Array([head + Vector2(-4, -6), head + Vector2(12, -6), head + Vector2(12, 3), head + Vector2(-4, 3)]), Color(0.07, 0.08, 0.11))
		c.draw_circle(top + Vector2(0, 14), 4.0, Color(0.18, 0.68, 1.0))
	else:
		c.draw_colored_polygon(PackedVector2Array([head + Vector2(-8, -3), head + Vector2(10, -4), head + Vector2(8, 4), head + Vector2(-6, 4)]), Color(0.92, 0.92, 0.98))
		c.draw_circle(head + Vector2(4, 0), 2.5, Color(0.55, 0.3, 0.95))
	c.draw_circle(head + Vector2(-5, -6), 3.5, Color(1, 1, 1, 0.5))      # Shine


func _closed(pts: PackedVector2Array) -> PackedVector2Array:
	var cl := pts.duplicate()
	cl.append(pts[0])
	return cl
