class_name TownLand
extends StoryManager
## THE ABANDONED TOWN - level 81, its own Story part (lore by the user, 2026-11-21).
## Scene: scenes/TownLand.tscn. Layout + objects: TownWorld.gd, art: TownArt.gd, words: StoryDialogue.ABANDONED.
##
##   1. After the Storm you fall out of the sky onto the east side of a walled town.
##   2. PURE LORE: talk (DOWN) to the OLDEST JUDGE, the SHOPKEEPER and the YOUNGEST GUARD (and a few
##      townsfolk). All three heard -> a big "GO   TO   LEFT" across the screen.
##   3. Out through the LEFT GATE (the town's border) to a CAVE MOUTH -> LOADING SCREEN -> THE
##      NIGHTMARE'S CAVE: old blood and burned charcoal everywhere. At the end: THE NIGHTMARE LORD,
##      asleep in chains. A CHOICE (DialogueBox options), saved as StoryProgress.town_choice:
##        "woke"    Cut him and wake him -> he thanks you and walks out. Outside: the whole town is
##                  dead and burning in red flames. The Strong Wind lifts you into the sky.
##        "carried" Unchain him, let him sleep -> he falls; you carry him out on your shoulder. The
##                  town is alive - but before you reach it, the Strong Wind takes you up.
##        "left"    Leave him be -> the same as "carried", without him.
##   4. The Strong Wind = LEVEL CLEAR.
## No fights in this level.

const NPC_RANGE := 110.0
static var test_steer := true

var talks := {}                                   # person id -> times talked to
var lore_heard := {}                              # judge / shopkeeper / young_guard -> true
var lore_done := false
var in_cave := false
var choice := ""
var _busy := false
var _ending := false
var _prompt_cd := 0.0
var _people := {}                                 # id -> TownWorld.Npc
var _sleeper: TownWorld.Sleeper
var _sleeper_group: Node2D
var _carry: TownWorld.Carry
var _tint: ColorRect
var _wind: TownWorld.WindFx
var _go_label: Label
var _hint: Label
var _warned_border := false


# ============================================================
# SETUP
# ============================================================
func _ready() -> void:
	TownWorld.burning = false
	super._ready()
	level = level.duplicate(true)
	_build_world()
	_build_overlays()
	for id in TownWorld.LORE:
		talks[id] = 0


func _exit_tree() -> void:
	super._exit_tree()
	TownWorld.burning = false


func _setup_arena() -> void:
	var m: Dictionary = (StoryLevels.MAPS["town"] as Dictionary).duplicate()
	m["half_width"] = 3300.0
	m["solid"] = true
	_apply_map(m)
	_set_area("town")


## Switch the playable area: "town" (the town + outside its gate) or "cave" (the Nightmare's cave).
func _set_area(area: String) -> void:
	in_cave = area == "cave"
	var key := "nightmare_cave" if in_cave else "town"
	var map: Dictionary = StoryLevels.MAPS[key]
	var bg := get_parent().get_node_or_null("Background") as HellBackground
	if bg != null:
		bg.theme = String(map["bg"])
	var ground := get_parent().get_node_or_null("ArenaGround") as ArenaGround
	if ground != null:
		ground.ground_theme = int(map["ground"])
	var wl := get_parent().get_node_or_null("WallLeft") as CaveWall
	var wr := get_parent().get_node_or_null("WallRight") as CaveWall
	if wl != null and wr != null:
		wl.global_position.x = TownWorld.CAVE_L if in_cave else TownWorld.TOWN_L
		wr.global_position.x = TownWorld.CAVE_R if in_cave else TownWorld.TOWN_R
		wl.style = String(map["walls"])
		wr.style = wl.style
		wall_left_x = wl.inner_x()
		wall_right_x = wr.inner_x()
		has_walls = true
	if not _ending:
		SoundManager.play_music("story_nightmare_cave" if in_cave or TownWorld.burning else "story_abandoned_town")


func _build_world() -> void:
	for d in TownWorld.PROPS:
		var p := TownWorld.Prop.new()
		p.def = d
		var g := TownWorld.pixel_wrap(p, Vector2(float(d["x"]), _ground_y))
		g.z_index = -2 if String(d["kind"]) in ["house", "gate", "shrine", "stall", "cave_mouth"] else -1
		add_child(g)
	for d in TownWorld.PEOPLE:
		var n := TownWorld.Npc.new()
		n.id = String(d["id"])
		n.look = int(d["look"])
		add_child(TownWorld.pixel_wrap(n, Vector2(float(d["x"]), _ground_y)))
		_people[n.id] = n
	_sleeper = TownWorld.Sleeper.new()
	_sleeper_group = TownWorld.pixel_wrap(_sleeper, Vector2(TownWorld.SLEEPER_X, _ground_y))
	add_child(_sleeper_group)


func _build_overlays() -> void:
	var tint_layer := CanvasLayer.new()
	tint_layer.layer = -8                                    # Over the sky, under the world
	add_child(tint_layer)
	_tint = ColorRect.new()
	_tint.set_anchors_and_offsets_preset(Control.PRESET_FULL_RECT)
	_tint.mouse_filter = Control.MOUSE_FILTER_IGNORE
	_tint.color = Color(0.8, 0.05, 0.02, 0.0)
	tint_layer.add_child(_tint)
	var ui := CanvasLayer.new()
	ui.layer = 14
	add_child(ui)
	_wind = TownWorld.WindFx.new()
	ui.add_child(_wind)
	_go_label = Label.new()
	_go_label.text = "GO        TO      LEFT"
	_go_label.set_anchors_and_offsets_preset(Control.PRESET_CENTER)
	_go_label.grow_horizontal = Control.GROW_DIRECTION_BOTH
	_go_label.grow_vertical = Control.GROW_DIRECTION_BOTH
	_go_label.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	_go_label.add_theme_font_size_override("font_size", 78)
	_go_label.add_theme_color_override("font_color", Color(1.0, 0.86, 0.55))
	_go_label.add_theme_color_override("font_outline_color", Color(0, 0, 0))
	_go_label.add_theme_constant_override("outline_size", 16)
	_go_label.modulate.a = 0.0
	ui.add_child(_go_label)
	_hint = Label.new()
	_hint.text = "<<<   GO TO LEFT"
	_hint.set_anchors_and_offsets_preset(Control.PRESET_CENTER_TOP)
	_hint.grow_horizontal = Control.GROW_DIRECTION_BOTH
	_hint.offset_top = 96.0
	_hint.add_theme_font_size_override("font_size", 24)
	_hint.add_theme_color_override("font_color", Color(1.0, 0.86, 0.55))
	_hint.add_theme_color_override("font_outline_color", Color(0, 0, 0))
	_hint.add_theme_constant_override("outline_size", 8)
	_hint.visible = false
	ui.add_child(_hint)


# ============================================================
# FLOW
# ============================================================
func _run() -> void:
	CombatManager.fight_active = false
	# THE ARRIVAL: the Storm spits you out above the town; you fall onto the east road
	var land := Vector2(TownWorld.START_X, _ground_y)
	_place_party(land.x)
	player.facing = -1
	player.global_position = land + Vector2(260, -1100)
	_letterbox(true)
	ArenaCamera.focus = player
	ArenaCamera.focus_zoom = 0.6
	ArenaCamera.focus_offset = Vector2(0, -80)
	SoundManager.play_sfx("whoosh")
	_show_banner("THE ABANDONED TOWN", "After the Storm: a quiet town behind a wooden wall.\nNobody has left it in five hundred years.", Color(1.0, 0.86, 0.55))
	var tw := create_tween()
	tw.tween_property(player, "global_position", land, 1.3).set_trans(Tween.TRANS_QUAD).set_ease(Tween.EASE_IN)
	tw.parallel().tween_property(player.visuals, "rotation", -TAU, 1.3)
	await tw.finished
	player.visuals.rotation = 0.0
	Effects.shake(self, 10.0)
	Effects.hit_sparks(player, land + Vector2(0, -8), 10, 1.2)
	SoundManager.play_sfx("slam", -4.0)
	await _wait(1.6)
	_hide_banner()
	ArenaCamera.focus = null
	_letterbox(false)
	CombatManager.fight_active = true
	Effects.popup(player, player.global_position + Vector2(0, -200), "DOWN near someone = TALK", Color(1.0, 0.9, 0.75), 18)


func _process(delta: float) -> void:
	super._process(delta)
	if player == null or not is_instance_valid(player) or _ending or _busy:
		return
	_prompt_cd = maxf(_prompt_cd - delta, 0.0)
	var px := player.global_position.x
	for id in _people:                                       # People turn to look at you
		var n: TownWorld.Npc = _people[id]
		n.face = 1 if px > n.get_parent().position.x else -1
	if autoplay and test_steer:
		_autoplay_steer()
		return
	if in_cave:
		_update_cave(px)
	else:
		_update_people(px)
		_update_border(px)
		_update_mouth(px)
		_update_wind(px)


func _down() -> bool:
	return player.ctl != null and player.ctl.just_pressed("crouch")


func _popup(text: String, col: Color = Color(1.0, 0.9, 0.75), cd: float = 3.0, size: int = 18) -> void:
	if _prompt_cd > 0.0:
		return
	_prompt_cd = cd
	Effects.popup(player, player.global_position + Vector2(0, -200), text, col, size)


# ============================================================
# THE PEOPLE
# ============================================================
func _update_people(px: float) -> void:
	if choice != "":
		return                                               # (After the cave you never reach them)
	for d in TownWorld.PEOPLE:
		var id := String(d["id"])
		if absf(px - float(d["x"])) > NPC_RANGE:
			continue
		var lore := TownWorld.LORE.has(id) and not lore_heard.has(id)
		_popup("DOWN = TALK" + ("   (!)" if lore else ""))
		if _down():
			_talk(id)
		return


func _talk(id: String) -> void:
	_busy = true
	var visit := int(talks.get(id, 0))
	talks[id] = visit + 1
	var lines: Array = (StoryDialogue.npc_talk(StoryDialogue.ABANDONED[id], visit) as Array).duplicate(true)
	for l in lines:
		if String(l[0]) == "H":
			l[0] = hero
	for l in [_banner, _sub]:
		l.modulate.a = 0.0
	var box := DialogueBox.play(self, lines)
	await box.finished
	if TownWorld.LORE.has(id) and visit == 0:
		lore_heard[id] = true
		var left := TownWorld.LORE.size() - lore_heard.size()
		if left > 0 and not lore_done:
			Effects.popup(player, player.global_position + Vector2(0, -220), "%d MORE TO HEAR" % left, Color(1.0, 0.86, 0.55), 20)
	if lore_heard.size() >= TownWorld.LORE.size() and not lore_done:
		lore_done = true
		Achievements.unlock("town_lore")
		await _go_left()
	_busy = false


## All three told their part: "GO   TO   LEFT" across the whole screen.
func _go_left() -> void:
	SoundManager.play_sfx("holy")
	Effects.shake(self, 6.0)
	_go_label.pivot_offset = _go_label.size * 0.5
	var tw := create_tween()
	tw.tween_property(_go_label, "modulate:a", 1.0, 0.5)
	tw.parallel().tween_property(_go_label, "scale", Vector2.ONE, 0.5).from(Vector2(1.4, 1.4))
	await tw.finished
	await _wait(3.2)
	var tw2 := create_tween()
	tw2.tween_property(_go_label, "modulate:a", 0.0, 0.8)
	await tw2.finished
	_hint.visible = true


# ============================================================
# THE BORDER + THE CAVE MOUTH
# ============================================================
func _update_border(px: float) -> void:
	if _warned_border or px > TownWorld.GATE_X - 60.0:
		return
	_warned_border = true
	var g: TownWorld.Npc = _people["young_guard"]
	Effects.popup(g, g.global_position + Vector2(0, -190), "W-wait! Nobody goes past the wall!", Color(0.75, 0.85, 1.0), 18)


func _update_mouth(px: float) -> void:
	if absf(px - TownWorld.CAVE_MOUTH_X) > 130.0 or choice != "":
		return
	if not lore_done:
		_popup("A cave mouth. Cold, old air... and the smell of smoke.\nLearn more about this town first.", Color(0.85, 0.8, 0.75), 4.0, 16)
		return
	_popup("DOWN = ENTER THE CAVE", Color(1.0, 0.7, 0.5), 3.0, 20)
	if _down():
		_enter_cave()


func _enter_cave() -> void:
	_busy = true
	CombatManager.fight_active = false
	_hint.visible = false
	var ls := LoadingScreen.cover(self, "THE NIGHTMARE'S CAVE", "Blood and charcoal. Very, very old.")
	await _wait(0.4)
	_set_area("cave")
	player.global_position = Vector2(TownWorld.CAVE_ENTRY_X, _ground_y)
	player.velocity = Vector2.ZERO
	player.facing = -1
	await ls.done()
	_show_banner("THE NIGHTMARE'S CAVE", "The walls are black with old blood. Heaps of charcoal everywhere.\nWhatever burned here, burned a long time ago.", Color(1.0, 0.55, 0.45))
	await _wait(2.8)
	_hide_banner()
	CombatManager.fight_active = true
	_busy = false


# ============================================================
# THE CAVE: the sleeper + the choice
# ============================================================
func _update_cave(px: float) -> void:
	if choice == "":
		if absf(px - TownWorld.SLEEPER_X) < 190.0:
			_confront()
		elif px > TownWorld.CAVE_ENTRY_X + 60.0:
			_popup("Something breathes at the back of the cave.", Color(0.9, 0.7, 0.6), 4.0, 16)
		return
	if px > TownWorld.CAVE_ENTRY_X + 30.0:
		_exit_cave()
	else:
		_popup("Back the way you came  >>>", Color(1.0, 0.86, 0.55), 5.0, 18)


func _confront() -> void:
	_busy = true
	CombatManager.fight_active = false
	player.velocity = Vector2.ZERO
	_letterbox(true)
	ArenaCamera.focus = _sleeper_group
	ArenaCamera.focus_zoom = 0.7
	ArenaCamera.focus_offset = Vector2(60, -110)
	_show_banner("THE NIGHTMARE LORD", "Asleep. Chained to the rock. Five hundred years of dust on his hat.", Color(1.0, 0.35, 0.3))
	SoundManager.play_sfx("rumble", -8.0)
	await _wait(2.6)
	_hide_banner()
	var box := DialogueBox.play(self, _hero_lines(StoryDialogue.NIGHTMARE_FOUND))
	await box.finished
	match box.choice:
		0:
			await _wake_him()
		1:
			await _carry_him()
		_:
			choice = "left"
			Achievements.unlock("town_left")
			await (DialogueBox.play(self, _hero_lines(StoryDialogue.NIGHTMARE_LEFT))).finished
	StoryProgress.set_town_choice(choice)
	if autoplay:
		print("TOWN autoplay: choice = %s" % choice)
	ArenaCamera.focus = null
	_letterbox(false)
	player.facing = 1
	_show_banner("", "Back the way you came.", Color(1.0, 0.86, 0.55))
	get_tree().create_timer(2.0).timeout.connect(_hide_banner)
	CombatManager.fight_active = true
	_busy = false


func _hero_lines(src: Array) -> Array:
	var out := src.duplicate(true)
	for l in out:
		if String(l[0]) == "H":
			l[0] = hero
	return out


## CHOICE 1: cut him and wake him. He thanks you... and walks out of the cave.
func _wake_him() -> void:
	choice = "woke"
	Achievements.unlock("town_woke")
	player.facing = -1
	SoundManager.play_sfx("sword_slash", -2.0)
	Effects.hit_sparks(player, _sleeper_group.global_position + Vector2(0, -90), 18, 1.4)
	Effects.shake(self, 8.0)
	await _wait(0.3)
	SoundManager.play_sfx("chain", -4.0)                   # The chains snap
	_sleeper.state = "awake"
	Effects.explosion(self, _sleeper_group.global_position + Vector2(0, -70), 70.0)
	await _wait(0.9)
	await (DialogueBox.play(self, _hero_lines(StoryDialogue.NIGHTMARE_WOKE))).finished
	# He walks past you, out of the cave - and is gone in a gust of red fire
	var tw := create_tween()
	tw.tween_property(_sleeper_group, "position:x", TownWorld.CAVE_ENTRY_X + 40.0, 2.4).set_trans(Tween.TRANS_SINE)
	await tw.finished
	Effects.explosion(self, _sleeper_group.global_position + Vector2(0, -70), 110.0)
	SoundManager.play_sfx("flame")
	_sleeper_group.visible = false
	_sleeper.state = "gone"
	TownWorld.burning = true                               # ...and outside, the town burns


## CHOICE 2: unchain him without waking him - he falls, and you carry him on your shoulder.
func _carry_him() -> void:
	choice = "carried"
	Achievements.unlock("town_carried")
	SoundManager.play_sfx("chain", -4.0)
	_sleeper.state = "floor"
	Effects.shake(self, 5.0)
	await _wait(0.8)
	await (DialogueBox.play(self, _hero_lines(StoryDialogue.NIGHTMARE_CARRIED))).finished
	_sleeper_group.visible = false
	_sleeper.state = "gone"
	_carry = TownWorld.Carry.new()
	_carry.who = player
	player.add_child(_carry)


func _exit_cave() -> void:
	_busy = true
	CombatManager.fight_active = false
	var sub := "Something smells of smoke." if choice == "woke" else "Daylight. The way back to the town."
	var ls := LoadingScreen.cover(self, "THE ABANDONED TOWN", sub)
	await _wait(0.4)
	_set_area("town")
	if choice == "woke":
		_burn_town()
	player.global_position = Vector2(TownWorld.CAVE_MOUTH_X + 150.0, _ground_y)
	player.velocity = Vector2.ZERO
	player.facing = 1
	await ls.done()
	if choice == "woke":
		_show_banner("THE ABANDONED TOWN", "...is silent. Red flames on every roof.\nThere is nobody left to pray to the Sun.", Color(1.0, 0.3, 0.25))
	else:
		_show_banner("THE ABANDONED TOWN", "Smoke from the chimneys. Sun-bread in the air.\nThe town is alive.", Color(1.0, 0.86, 0.55))
	await _wait(3.2)
	_hide_banner()
	CombatManager.fight_active = true
	_busy = false


func _burn_town() -> void:
	TownWorld.burning = true
	for id in _people:
		(_people[id] as TownWorld.Npc).dead = true
	_tint.color = Color(0.85, 0.06, 0.02, 0.32)
	SoundManager.play_music("story_nightmare_cave")


# ============================================================
# THE STRONG WIND (the end of the level)
# ============================================================
func _update_wind(px: float) -> void:
	if choice == "":
		return
	if px > (TownWorld.WIND_DEAD_X if choice == "woke" else TownWorld.WIND_ALIVE_X):
		_strong_wind()


func _strong_wind() -> void:
	_ending = true
	CombatManager.fight_active = false
	player.velocity = Vector2.ZERO
	_letterbox(true)
	ArenaCamera.focus = player
	ArenaCamera.focus_zoom = 0.5
	SoundManager.play_sfx("whoosh")
	SoundManager.play_sfx("rumble", -6.0)
	_show_banner("THE STRONG WIND", "Out of nowhere it tears you off the ground -\nup, over the wall, into the clouds.", Color(0.85, 0.95, 1.0))
	var tw := create_tween()
	tw.tween_property(_wind, "power", 1.0, 0.6)
	var up := create_tween()
	up.tween_property(player, "global_position", player.global_position + Vector2(-500, -1600), 3.6).set_trans(Tween.TRANS_QUAD).set_ease(Tween.EASE_IN)
	up.parallel().tween_property(player.visuals, "rotation", TAU * 1.5, 3.6)
	await _wait(2.8)
	await _fade(true)
	player.visuals.rotation = 0.0
	_hide_banner()
	ArenaCamera.focus = null
	_wind.power = 0.0
	SoundManager.stop_music()
	await _fade(false)
	await _level_clear()


func _on_player_died() -> void:
	pass                                                   # (No fights here)


# ============================================================
# TESTING (autoplay): talk to all three, the cave, the choice (DialogueBox.auto_pick), the wind
# ============================================================
func _autoplay_steer() -> void:
	if not CombatManager.fight_active:
		return
	var px := player.global_position.x
	var goal := px
	if not lore_done:
		for id in TownWorld.LORE:
			if not lore_heard.has(id):
				for d in TownWorld.PEOPLE:
					if String(d["id"]) == id:
						goal = float(d["x"])
				if absf(px - goal) < 60.0:
					_talk(id)
					return
				break
	elif in_cave:
		goal = TownWorld.SLEEPER_X if choice == "" else TownWorld.CAVE_R
		if choice == "" and absf(px - goal) < 180.0:
			_confront()
			return
		if choice != "" and px > TownWorld.CAVE_ENTRY_X + 30.0:
			_exit_cave()
			return
	elif choice == "":
		goal = TownWorld.CAVE_MOUTH_X
		if absf(px - goal) < 60.0:
			_enter_cave()
			return
	else:
		goal = TownWorld.TOWN_R
		if px > (TownWorld.WIND_DEAD_X if choice == "woke" else TownWorld.WIND_ALIVE_X):
			_strong_wind()
			return
	var step := signf(goal - px) * 700.0 * get_process_delta_time()
	player.global_position.x += step
	if absf(step) > 0.0:
		player.facing = 1 if step > 0.0 else -1
