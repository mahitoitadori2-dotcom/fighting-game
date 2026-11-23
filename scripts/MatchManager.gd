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
# Match stats for the results screen: Fighter -> {dealt, hits, combo, best_combo, blocks, perfect, ults}
var stats := {}
var _last_hit_t := {}
var _start_ms := 0
var _gauge_prev := {}


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
			stats[f] = {"dealt": 0, "hits": 0, "combo": 0, "best_combo": 0, "blocks": 0, "perfect": 0, "ults": 0}
			f.damaged.connect(_on_damaged.bind(f))
			f.blocked.connect(_on_blocked.bind(f))
			if f.gauge != null:
				_gauge_prev[f] = f.gauge.value
				f.gauge.changed.connect(_on_gauge.bind(f))
	_start_ms = Time.get_ticks_msec()
	CombatManager.fight_active = false       # Frozen until "GO!"
	_build_banner()
	_intro()


# ===== Stats =====
func _other(f: Fighter) -> Fighter:
	return p2 if f == p1 else p1


func _on_damaged(amount: int, _hit: HitData, victim: Fighter) -> void:
	var att := _other(victim)
	if att == null or not stats.has(att) or _over:
		return
	var st: Dictionary = stats[att]
	st["dealt"] += amount
	st["hits"] += 1
	var now := Time.get_ticks_msec()
	st["combo"] = st["combo"] + 1 if now - int(_last_hit_t.get(att, -10000)) < 1100 else 1
	st["best_combo"] = maxi(st["best_combo"], st["combo"])
	_last_hit_t[att] = now


func _on_blocked(_hit: HitData, perfect: bool, f: Fighter) -> void:
	if stats.has(f) and not _over:
		stats[f]["blocks"] += 1
		if perfect:
			stats[f]["perfect"] += 1


## A whole G bar (or more) gone at once = an ultimate was used.
func _on_gauge(value: float, f: Fighter) -> void:
	var prev := float(_gauge_prev.get(f, value))
	_gauge_prev[f] = value
	if stats.has(f) and not _over and f.gauge != null and prev - value >= f.gauge.segment_size * 0.95:
		stats[f]["ults"] += 1


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
	NetHost.event({"k": "end", "text": "YOU WIN!" if winner == p2 else "THE HOST WINS"})   # ONLINE
	if winner == p1 and p1 != null:
		Achievements.on_versus_win(CharacterRoster.selected_id, CharacterRoster.opponent_id, p1.used)
		if not ArenaManager.p1_cpu:                                  # DAILY challenges (you, not a CPU P1)
			Daily.progress("vs_win")
			if CharacterRoster.selected_id == String(Daily.target_fighter().get("id", "")):
				Daily.progress("vs_win_as")
	await get_tree().create_timer(WINNER_DELAY).timeout
	if is_inside_tree():
		_show_winner()


# ============================================================
# WINNER SCREEN
# ============================================================
func _stats_table() -> Control:
	var grid := GridContainer.new()
	grid.columns = 3
	grid.size_flags_horizontal = Control.SIZE_SHRINK_CENTER
	grid.add_theme_constant_override("h_separation", 36)
	grid.add_theme_constant_override("v_separation", 2)
	var a: Dictionary = stats.get(p1, {})
	var b: Dictionary = stats.get(p2, {})
	var secs := float(Time.get_ticks_msec() - _start_ms) / 1000.0
	var rows := [["TIME", StoryManager.time_text(secs), ""],
		["DAMAGE DEALT", str(a.get("dealt", 0)), str(b.get("dealt", 0))],
		["HITS LANDED", str(a.get("hits", 0)), str(b.get("hits", 0))],
		["BEST COMBO", str(a.get("best_combo", 0)), str(b.get("best_combo", 0))],
		["BLOCKS (PERFECT)", "%d (%d)" % [a.get("blocks", 0), a.get("perfect", 0)], "%d (%d)" % [b.get("blocks", 0), b.get("perfect", 0)]],
		["ULTIMATES", str(a.get("ults", 0)), str(b.get("ults", 0))]]
	grid.add_child(UiStyle.label("", 16, UiStyle.TEXT_DIM, 4))
	grid.add_child(UiStyle.label("YOU", 18, CharacterCard.YOU_COLOR, 5))
	grid.add_child(UiStyle.label("OPPONENT", 18, CharacterCard.OPP_COLOR, 5))
	var i := 0
	for r in rows:
		var cells := [UiStyle.label(r[0], 18, UiStyle.TEXT_DIM, 5), UiStyle.label(r[1], 20, UiStyle.TEXT, 5), UiStyle.label(r[2], 20, UiStyle.TEXT, 5)]
		for c: Label in cells:
			c.modulate.a = 0.0
			grid.add_child(c)
			var tw := c.create_tween()
			tw.tween_interval(0.35 + i * 0.12)
			tw.tween_property(c, "modulate:a", 1.0, 0.25)
		i += 1
	return grid


func _show_winner() -> void:
	var rec := get_parent().get_node_or_null("ReplayRecorder") as ReplayRecorder
	if rec != null:
		rec.stop()
		Replay.last = rec.result()
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

	# SCROLLS (2026-11-21): on phones the results + 4 buttons are taller than the screen - drag to scroll
	var scroll := ScrollContainer.new()
	scroll.name = "ResultsScroll"
	scroll.set_anchors_and_offsets_preset(Control.PRESET_FULL_RECT)
	scroll.horizontal_scroll_mode = ScrollContainer.SCROLL_MODE_DISABLED
	scroll.follow_focus = true                              # Controller / keys: the focused button stays in view
	layer.add_child(scroll)
	DragScroll.attach(scroll)                              # A finger swipe anywhere scrolls it
	var col := VBoxContainer.new()
	col.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	col.size_flags_vertical = Control.SIZE_EXPAND_FILL
	col.alignment = BoxContainer.ALIGNMENT_CENTER
	col.add_theme_constant_override("separation", 14)
	scroll.add_child(col)
	var top_pad := Control.new()
	top_pad.custom_minimum_size = Vector2(0, 24)
	col.add_child(top_pad)

	var who := "P1" if winner == p1 else ("THE BOSS" if winner is BaseEnemy else ("CPU" if winner is ControlledFighter else "DUMMY"))
	var name_text: String = winner.data.character_name if winner != null and winner.data != null else "?"
	var col_win := CharacterCard.YOU_COLOR if winner == p1 else CharacterCard.OPP_COLOR
	col.add_child(UiStyle.label("WINNER", 40, UiStyle.TEXT_DIM, 10))
	var name_lbl := UiStyle.label(name_text.to_upper(), 72, col_win, 16)
	col.add_child(name_lbl)
	name_lbl.pivot_offset = Vector2(400, 40)
	name_lbl.scale = Vector2(0.4, 0.4)
	name_lbl.modulate.a = 0.0
	var pop := name_lbl.create_tween().set_parallel()
	pop.tween_property(name_lbl, "scale", Vector2.ONE, 0.45).set_trans(Tween.TRANS_BACK).set_ease(Tween.EASE_OUT)
	pop.tween_property(name_lbl, "modulate:a", 1.0, 0.25)
	col.add_child(UiStyle.label("%s WINS!" % who, 32, UiStyle.TEXT, 10))

	# Results: a stats table that slides in row by row
	var table := _stats_table()
	col.add_child(table)
	var gap := Control.new()
	gap.custom_minimum_size = Vector2(0, 14)
	col.add_child(gap)

	var again := UiStyle.make_button("PLAY AGAIN")
	again.size_flags_horizontal = Control.SIZE_SHRINK_CENTER
	again.pressed.connect(func() -> void: get_tree().reload_current_scene())
	col.add_child(again)
	if not Replay.last.is_empty():
		var watch := UiStyle.make_button("WATCH REPLAY")
		watch.size_flags_horizontal = Control.SIZE_SHRINK_CENTER
		watch.pressed.connect(func() -> void:
			Replay.pending = Replay.last.duplicate()
			Replay.pending["return_scene"] = CharacterRoster.MAIN_MENU
			get_tree().change_scene_to_file(ArenaManager.arena_entry(String(Replay.last["arena"]))["scene"]))
		col.add_child(watch)
		var save := UiStyle.make_button("SAVE REPLAY")
		save.size_flags_horizontal = Control.SIZE_SHRINK_CENTER
		save.pressed.connect(func() -> void:
			var title := "%s vs %s" % [p1.data.character_name if p1 else "?", p2.data.character_name if p2 else "?"]
			var path := Replay.save(Replay.last, title)
			save.text = "SAVED!" if path != "" else "SAVE FAILED"
			save.disabled = true)
		col.add_child(save)
	var menu := UiStyle.make_button("MAIN MENU")
	menu.size_flags_horizontal = Control.SIZE_SHRINK_CENTER
	menu.pressed.connect(func() -> void: get_tree().change_scene_to_file(CharacterRoster.MAIN_MENU))
	col.add_child(menu)
	again.grab_focus()
