class_name MatchManager
extends Node
## Runs one match (created by ArenaManager):
##   EPIC COUNTDOWN 3 - 2 - 1 - GO! (EpicCountdown, fighters frozen until GO)
##   Lives: every death removes 1 life (MatchSettings.lives, 1-5)
##   DUMMY FIGHT: BOTH sides have INFINITE lives (nobody is ever out, no winner screen)
##   Someone hits 0 lives -> Winner Screen (Play Again / Main Menu)

const WINNER_DELAY := 1.4                # Let the death animation play first
const INFINITE := -1                     # lives value = never runs out

var p1: Fighter
var p2: Fighter
var max_lives := 1
var lives := {}                          # Fighter -> lives left (INFINITE = no limit)
var winner: Fighter
var infinite_lives := false              # Dummy fight
var _over := false
var _banner_layer: CanvasLayer
var _banner: Label


func setup(a: Fighter, b: Fighter) -> void:
	add_to_group("match_manager")
	p1 = a
	p2 = b
	max_lives = MatchSettings.lives
	infinite_lives = (p1 is Dummy) or (p2 is Dummy)
	for f in [p1, p2]:
		if f != null:
			lives[f] = INFINITE if infinite_lives else (MatchSettings.enemy_lives if f is BaseEnemy else max_lives)
			f.died.connect(_on_fighter_died.bind(f))
	CombatManager.fight_active = false       # Frozen until "GO!"
	_build_banner()
	_intro()


## Lives left (INFINITE = -1 for Dummy fights).
func lives_of(f: Fighter) -> int:
	return lives.get(f, 0)


func max_lives_of(f: Fighter) -> int:
	if infinite_lives:
		return INFINITE
	return MatchSettings.enemy_lives if f is BaseEnemy else max_lives


## HUD text: "LIVES 2/3" or "LIVES INF."
func lives_text(f: Fighter) -> String:
	if infinite_lives or lives_of(f) == INFINITE:
		return "LIVES INF."
	return "LIVES %d/%d" % [lives_of(f), max_lives_of(f)]


# ============================================================
# INTRO: ROUND 1 -> FIGHT!
# ============================================================
func _build_banner() -> void:
	_banner_layer = CanvasLayer.new()
	_banner_layer.layer = 15
	add_child(_banner_layer)
	_banner = UiStyle.label("", 96, UiStyle.TEXT, 20)
	_banner.set_anchors_and_offsets_preset(Control.PRESET_FULL_RECT)
	_banner.vertical_alignment = VERTICAL_ALIGNMENT_CENTER
	_banner_layer.add_child(_banner)


func _intro() -> void:
	await get_tree().process_frame
	if not is_inside_tree():
		return
	# Boss intro voice line during the countdown (Fights-mode bosses)
	for f in [p1, p2]:
		if f is FightBoss:
			(f as FightBoss).play_intro()
	var cd := EpicCountdown.new()
	add_child(cd)
	cd.go.connect(func() -> void: CombatManager.fight_active = true)
	cd.start()


func _show_banner(text: String, col: Color) -> void:
	_banner.text = text
	_banner.add_theme_color_override("font_color", col)
	_banner.pivot_offset = _banner.size * 0.5
	_banner.scale = Vector2(1.6, 1.6)
	_banner.modulate.a = 0.0
	var tw := create_tween().set_parallel(true)
	tw.tween_property(_banner, "scale", Vector2.ONE, 0.25).set_trans(Tween.TRANS_BACK).set_ease(Tween.EASE_OUT)
	tw.tween_property(_banner, "modulate:a", 1.0, 0.15)


# ============================================================
# LIVES
# ============================================================
func _on_fighter_died(f: Fighter) -> void:
	if _over or not lives.has(f):
		return
	if lives[f] == INFINITE:
		Effects.popup(f, f.global_position + Vector2(0, -190), "INF. LIVES", Color(1, 0.85, 0.3), 22)
		return                                   # Dummy fight: always respawns, never a winner
	lives[f] = maxi(lives[f] - 1, 0)
	var left: int = lives[f]
	if left > 0:
		Effects.popup(f, f.global_position + Vector2(0, -190), "%d %s LEFT" % [left, "LIFE" if left == 1 else "LIVES"], Color(1, 0.85, 0.3), 22)
		return
	# Out of lives: no respawn, match over
	f.respawn_enabled = false
	_over = true
	winner = p2 if f == p1 else p1
	await get_tree().create_timer(WINNER_DELAY).timeout
	if is_inside_tree():
		_show_winner()


# ============================================================
# WINNER SCREEN
# ============================================================
func _show_winner() -> void:
	CombatManager.fight_active = false
	CombatManager.end_time_stop()
	_banner.text = ""

	var layer := CanvasLayer.new()
	layer.layer = 20
	add_child(layer)
	var dim := ColorRect.new()
	dim.color = Color(0, 0, 0, 0.6)
	dim.set_anchors_and_offsets_preset(Control.PRESET_FULL_RECT)
	layer.add_child(dim)

	var col := VBoxContainer.new()
	col.set_anchors_and_offsets_preset(Control.PRESET_FULL_RECT)
	col.alignment = BoxContainer.ALIGNMENT_CENTER
	col.add_theme_constant_override("separation", 14)
	layer.add_child(col)

	var who := "P1" if winner == p1 else ("THE BOSS" if winner is BaseEnemy else ("CPU" if winner is ControlledFighter else "DUMMY"))
	var name_text: String = winner.data.character_name if winner != null and winner.data != null else "?"
	var col_win := CharacterCard.YOU_COLOR if winner == p1 else CharacterCard.OPP_COLOR
	col.add_child(UiStyle.label("WINNER", 40, UiStyle.TEXT_DIM, 10))
	col.add_child(UiStyle.label(name_text.to_upper(), 72, col_win, 16))
	col.add_child(UiStyle.label("%s WINS!" % who, 32, UiStyle.TEXT, 10))

	var gap := Control.new()
	gap.custom_minimum_size = Vector2(0, 20)
	col.add_child(gap)

	var again := UiStyle.make_button("PLAY AGAIN")
	again.size_flags_horizontal = Control.SIZE_SHRINK_CENTER
	again.pressed.connect(func() -> void: get_tree().reload_current_scene())
	col.add_child(again)
	var menu := UiStyle.make_button("MAIN MENU")
	menu.size_flags_horizontal = Control.SIZE_SHRINK_CENTER
	menu.pressed.connect(func() -> void: get_tree().change_scene_to_file(CharacterRoster.MAIN_MENU))
	col.add_child(menu)
	again.grab_focus()
