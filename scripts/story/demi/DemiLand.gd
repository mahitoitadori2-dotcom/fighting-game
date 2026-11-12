class_name DemiLand
extends StoryManager
## DEMILAND - the OPEN-WORLD Story level (level 63, its own Story part). 5-15 minutes, not 1-3.
## Scene: scenes/DemiLand.tscn (one 18 000 px wide land). Layout + scenery: DemiWorld.gd.
##
##   * You play the hero who did NOT chase the Enlightened One (StoryLevels.hero_of: "demi").
##   * SOULS RULES are on (roll instead of block, stamina) - SoulsRules.gd. Deep Faith applies.
##   * Walk where you like. Enemy CAMPS wake up when you come near (one more enemy at night).
##   * CAMTONS (old rock pillars that make flames around themselves): walk to one to wake it, press DOWN to rest = full HP + flasks, but every camp
##     comes back. When you DIE you wake at the last CamTon you woke (artifacts are kept).
##   * Three BOSSES - Tribe Master (village), Last Tiger (ravine), LIVING Tree Lord (grove). Walk
##     into their arena and walls of fog close behind you. Each drops an ARTIFACT.
##   * Bring the three artifacts to the ANCIENT DOOR (where you start): it opens = level clear.
##   * DAY / NIGHT: a dark day, a darker-than-dark night. The MAP (M / TAB / MAP button) is
##     accurate and fills in as you explore. NO mission list.

const DAY_TIME := 240.0
const NIGHT_TIME := 120.0
const FADE_TIME := 14.0
const CAMP_WAKE := 950.0                  # Camps spawn when you are this close (one camp at a time)
## TESTING: the autoplay CPU walks to the next boss by itself (off when a test moves it).
static var test_steer := true
const CAMP_SLEEP := 2700.0                # ...and are put away again when you are this far

var discovered := {}                      # region key -> true
var shrines_lit := {}                     # shrine index -> true
var last_shrine := 0
var bosses_done := {}                     # boss id -> true
var carried: Array = []                   # Artifact ids picked up, not yet put in the door
var deaths := 0
var rests := 0

var _door: DemiWorld.Door
var _shrine_nodes: Array = []
var _camps: Array = []                    # [{spawned, cleared, alive: Array}]
var _fight: Dictionary = {}               # The boss arena you are fighting in ({} = none)
var _gates: Array = []
var _pickups: Array = []
var _region := ""
var _time := 0.0
var _night_k := 0.0
var _was_night := false
var _tick := 0.0
var _dying := false
var _ending := false
var _prompt_cd := 0.0
var _world_l := 0.0
var _world_r := 0.0
var _map: DemiMap
var _night_mod: CanvasModulate
var _night_sky: ColorRect
var _bg_fade: ColorRect
var _died_label: Label
var _overlay: Control


# ============================================================
# SETUP
# ============================================================
func _ready() -> void:
	super._ready()
	level = level.duplicate(true)                        # Boss music etc. are set per fight
	EnemyAI.leash = 1100.0                               # Enemies only notice you when you are near
	_world_l = wall_left_x
	_world_r = wall_right_x
	_build_world()
	_build_overlays()
	for i in DemiWorld.CAMPS.size():
		_camps.append({"spawned": false, "cleared": false, "alive": []})
	if not InputMap.has_action("demi_map"):
		InputMap.add_action("demi_map")
		for key in [KEY_M, KEY_TAB]:
			var e := InputEventKey.new()
			e.physical_keycode = key
			InputMap.action_add_event("demi_map", e)
		var b := InputEventJoypadButton.new()
		b.button_index = JOY_BUTTON_RIGHT_STICK
		b.device = -1
		InputMap.action_add_event("demi_map", b)


func _exit_tree() -> void:
	super._exit_tree()
	EnemyAI.leash = 0.0


## The whole land: one wide floor between the two world walls (solid ground, no void below).
func _setup_arena() -> void:
	var m: Dictionary = (StoryLevels.MAPS["demi_door"] as Dictionary).duplicate()
	m["half_width"] = DemiWorld.HALF - 60.0
	m["solid"] = true
	_apply_map(m)


func _build_world() -> void:
	# Scenery strips (each a separate canvas item: off-screen strips are not drawn)
	var strip: DemiWorld.PropStrip = null
	var strip_x := -INF
	for p in DemiWorld.props():
		if strip == null or float(p["x"]) - strip_x > 1500.0:
			strip = DemiWorld.PropStrip.new()
			strip_x = float(p["x"])
			add_child(strip)
		strip.items.append(p)
	for s in DemiWorld.SHRINES:
		var n := DemiWorld.CamTon.new()
		n.position = Vector2(float(s["x"]), _ground_y)
		add_child(n)
		_shrine_nodes.append(n)
	_door = DemiWorld.Door.new()
	_door.position = Vector2(DemiWorld.DOOR_X, _ground_y)
	add_child(_door)


func _build_overlays() -> void:
	# Night: the world darkens (CanvasModulate) and the sky behind it too (a layer over the backdrop)
	_night_mod = CanvasModulate.new()
	add_child(_night_mod)
	var sky_layer := CanvasLayer.new()
	sky_layer.layer = -9
	add_child(sky_layer)
	_night_sky = ColorRect.new()
	_night_sky.set_anchors_and_offsets_preset(Control.PRESET_FULL_RECT)
	_night_sky.mouse_filter = Control.MOUSE_FILTER_IGNORE
	_night_sky.color = Color(0.0, 0.0, 0.03, 0.0)
	sky_layer.add_child(_night_sky)
	_bg_fade = ColorRect.new()                          # Short fade when the backdrop changes region
	_bg_fade.set_anchors_and_offsets_preset(Control.PRESET_FULL_RECT)
	_bg_fade.mouse_filter = Control.MOUSE_FILTER_IGNORE
	_bg_fade.color = Color(0, 0, 0, 0)
	sky_layer.add_child(_bg_fade)
	# Small HUD: artifacts carried, prompt, MAP button, YOU DIED
	var ui := CanvasLayer.new()
	ui.layer = 14
	add_child(ui)
	_overlay = Control.new()
	_overlay.set_anchors_and_offsets_preset(Control.PRESET_FULL_RECT)
	_overlay.mouse_filter = Control.MOUSE_FILTER_IGNORE
	ui.add_child(_overlay)
	_overlay.draw.connect(_draw_overlay)
	var btn := UiStyle.make_button("MAP")
	btn.custom_minimum_size = Vector2(120, 48)
	btn.anchor_left = 1.0
	btn.anchor_right = 1.0
	btn.grow_horizontal = Control.GROW_DIRECTION_BEGIN
	btn.offset_left = -140.0
	btn.offset_right = -20.0
	btn.offset_top = 20.0
	btn.offset_bottom = 68.0
	btn.focus_mode = Control.FOCUS_NONE
	btn.pressed.connect(func() -> void: _map.toggle())
	ui.add_child(btn)
	_died_label = UiStyle.label("YOU DIED", 110, Color(0.75, 0.08, 0.06), 10)
	_died_label.set_anchors_and_offsets_preset(Control.PRESET_FULL_RECT)
	_died_label.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	_died_label.vertical_alignment = VERTICAL_ALIGNMENT_CENTER
	_died_label.modulate.a = 0.0
	ui.add_child(_died_label)
	_map = DemiMap.new()
	_map.manager = self
	add_child(_map)


# ============================================================
# FLOW
# ============================================================
func _run() -> void:
	await _intro()


func _intro() -> void:
	CombatManager.fight_active = false
	_place_party(float(DemiWorld.SHRINES[0]["x"]) + 110.0)
	_light_shrine(0, false)
	_enter_region(DemiWorld.region_at(player.global_position.x), false)
	await _wait(0.4)
	SoundManager.play_sfx("spawn", -6.0)
	var who := StoryLevels.hero_name(hero)
	_show_banner("DEMILAND", "%s\nYou are the %s - the one who did NOT chase the Enlightened One." % [level.get("intro", ""), who],
		Color(0.80, 0.72, 0.60))
	await _wait(3.4)
	_hide_banner()
	CombatManager.fight_active = true
	Effects.popup(player, player.global_position + Vector2(0, -200), "M = MAP     DOWN at a CamTon (rock pillar) = REST", Color(0.85, 0.8, 0.7), 18)


func is_night() -> bool:
	return _night_k > 0.5


func door_placed() -> Array:
	return _door.placed if _door != null else []


func camp_cleared(i: int) -> bool:
	return i < _camps.size() and bool(_camps[i]["cleared"])


func _process(delta: float) -> void:
	super._process(delta)                                # Flasks (R)
	_overlay.queue_redraw()
	if player == null or not is_instance_valid(player) or _ending:
		return
	if Input.is_action_just_pressed("demi_map"):
		_map.toggle()
	_day_night(delta)
	_prompt_cd = maxf(_prompt_cd - delta, 0.0)
	if _dying or player.is_dead:
		return
	var px := player.global_position.x
	var reg := DemiWorld.region_at(px)
	if String(reg["key"]) != _region:
		_enter_region(reg, true)
	_tick -= delta
	if _tick <= 0.0:
		_tick = 0.25
		_update_camps(px)
	_update_shrines(px)
	if _fight.is_empty():
		_check_boss_arenas(px)
	_update_pickups(px)
	_update_door(px)
	if autoplay and test_steer and _fight.is_empty():
		_autoplay_steer()


# ============================================================
# REGIONS + DAY / NIGHT
# ============================================================
func _enter_region(reg: Dictionary, announce: bool) -> void:
	var key := String(reg["key"])
	_region = key
	var bg := get_parent().get_node_or_null("Background") as HellBackground
	if bg != null:
		var theme := String(StoryLevels.MAPS[key]["bg"])
		if announce:
			var tw := create_tween()
			tw.tween_property(_bg_fade, "color:a", 1.0, 0.35)
			tw.tween_callback(func() -> void: bg.theme = theme)
			tw.tween_property(_bg_fade, "color:a", 0.0, 0.45)
		else:
			bg.theme = theme
	if not discovered.has(key):
		discovered[key] = true
		if announce:
			_show_banner(String(reg["name"]), "", Color(0.85, 0.78, 0.62))       # Souls area title
			SoundManager.play_sfx("holy", -10.0)
			get_tree().create_timer(2.2).timeout.connect(_hide_banner)
		if discovered.size() == DemiWorld.REGIONS.size():
			Achievements.unlock("demi_explorer")


func _day_night(delta: float) -> void:
	_time += delta
	var cyc := fmod(_time, DAY_TIME + NIGHT_TIME)
	var k := 0.0
	if cyc > DAY_TIME - FADE_TIME:
		k = clampf((cyc - (DAY_TIME - FADE_TIME)) / FADE_TIME, 0.0, 1.0)
		if cyc > DAY_TIME + NIGHT_TIME - FADE_TIME:
			k = clampf((DAY_TIME + NIGHT_TIME - cyc) / FADE_TIME, 0.0, 1.0)
	_night_k = k
	_night_mod.color = Color(1, 1, 1).lerp(Color(0.40, 0.40, 0.52), k)
	_night_sky.color.a = 0.62 * k
	var night := is_night()
	if night != _was_night:
		_was_night = night
		if player != null and not player.is_dead:
			Effects.popup(player, player.global_position + Vector2(0, -230), "NIGHT FALLS... it gets darker than dark" if night else "A grey dawn",
				Color(0.6, 0.6, 0.85) if night else Color(0.85, 0.8, 0.7), 22)
		if _fight.is_empty() and not _ending:
			SoundManager.play_music("story_demiland_night" if night else "story_demiland")


# ============================================================
# CAMPS
# ============================================================
func _update_camps(px: float) -> void:
	for i in _camps.size():
		var st: Dictionary = _camps[i]
		if st["cleared"]:
			continue
		var cx := float(DemiWorld.CAMPS[i]["x"])
		var d := absf(px - cx)
		if not st["spawned"]:
			if d < CAMP_WAKE and _fight.is_empty():
				_spawn_camp(i)
			continue
		var alive: Array = []
		for e in st["alive"]:
			if e != null and is_instance_valid(e) and not (e as BaseEnemy).is_dead:
				alive.append(e)
		st["alive"] = alive
		if alive.is_empty():
			st["cleared"] = true
		elif d > CAMP_SLEEP:
			for e in alive:
				(e as Node).queue_free()                       # Far away: put them back to sleep
			st["alive"] = []
			st["spawned"] = false


func _spawn_camp(i: int) -> void:
	var def: Dictionary = DemiWorld.CAMPS[i]
	var ids: Array = (def["ids"] as Array).duplicate()
	if is_night():
		ids.append(String(def["night"]))
	var st: Dictionary = _camps[i]
	st["spawned"] = true
	st["alive"] = []
	for j in ids.size():
		var x := float(def["x"]) + (float(j) - float(ids.size() - 1) * 0.5) * 120.0
		var e := StoryLevels.make_enemy(String(ids[j]))
		e.slot = 2
		e.team = 2
		e.default_facing = -1 if x > player.global_position.x else 1
		e.facing = e.default_facing
		e.respawn_enabled = false
		e.position = Vector2(x, _ground_y - 10.0)
		add_child(e)
		e.died.connect(_free_later.bind(e))
		(st["alive"] as Array).append(e)


## Corpses go away after a while (the level is long: they would pile up).
func _free_later(e: Node) -> void:
	await _wait(4.0)
	if is_instance_valid(e):
		e.queue_free()


func _reset_camps() -> void:
	for st in _camps:
		for e in st["alive"]:
			if e != null and is_instance_valid(e):
				(e as Node).queue_free()
		st["alive"] = []
		st["spawned"] = false
		st["cleared"] = false


# ============================================================
# CAMTONS
# ============================================================
func _update_shrines(px: float) -> void:
	for i in DemiWorld.SHRINES.size():
		if absf(px - float(DemiWorld.SHRINES[i]["x"])) > 110.0:
			continue
		if not shrines_lit.has(i):
			_light_shrine(i, true)
		elif _prompt_cd <= 0.0:
			_prompt_cd = 3.0
			Effects.popup(player, player.global_position + Vector2(0, -190), "DOWN = REST", Color(1.0, 0.75, 0.4), 18)
		if player.ctl != null and player.ctl.just_pressed("crouch"):
			_rest(i)
		return


func _light_shrine(i: int, announce: bool) -> void:
	shrines_lit[i] = true
	last_shrine = i
	(_shrine_nodes[i] as DemiWorld.CamTon).lit = true
	if announce:
		Effects.popup(player, player.global_position + Vector2(0, -210), "CAMTON WOKEN: %s" % DemiWorld.SHRINES[i]["name"], Color(1.0, 0.7, 0.3), 24)
		SoundManager.play_sfx("flame", -6.0)
		Effects.gold_burst(_shrine_nodes[i], (_shrine_nodes[i] as Node2D).global_position + Vector2(0, -60), 90.0)


func _rest(i: int) -> void:
	for n in get_tree().get_nodes_in_group("fighters"):
		var f := n as BaseEnemy
		if f != null and not f.is_dead and absf(f.global_position.x - player.global_position.x) < 700.0:
			Effects.popup(player, player.global_position + Vector2(0, -190), "YOU CANNOT REST: ENEMIES ARE NEAR", Color(1.0, 0.4, 0.3), 18)
			return
	last_shrine = i
	rests += 1
	player.hp = player.data.max_hp                     # Set directly: resting does not count as "healing" for badges
	player.health_changed.emit(player.hp, player.data.max_hp)
	flasks = max_flasks
	_reset_camps()
	SoundManager.play_sfx("heal")
	Effects.gold_burst(player, player.global_position + Vector2(0, -80), 120.0)
	_show_banner("RESTED", "%s\nHP and flasks restored. The land's creatures have returned." % DemiWorld.SHRINES[i]["name"], Color(1.0, 0.75, 0.4))
	get_tree().create_timer(2.0).timeout.connect(_hide_banner)


# ============================================================
# BOSSES
# ============================================================
func _check_boss_arenas(px: float) -> void:
	for b in DemiWorld.BOSSES:
		if bosses_done.has(String(b["id"])):
			continue
		if absf(px - float(b["x"])) < float(b["half"]) - 220.0:
			_start_boss(b)
			return


func _start_boss(b: Dictionary) -> void:
	_fight = b
	var bx := float(b["x"])
	var hw := float(b["half"])
	# NO ONE INTERRUPTS: every other creature in the land goes back to sleep (no camp wakes during
	# the fight), their shots vanish, and the arena closes with walls of rock + fog on both sides.
	_reset_camps()
	_clear_hazards()
	for n in get_tree().get_nodes_in_group("fighters"):
		var f := n as BaseEnemy
		if f != null and not f.is_dead:
			f.queue_free()
	for k in 2:
		var g := DemiWorld.FogGate.new()
		g.side = -1.0 if k == 0 else 1.0
		g.position = Vector2(bx - hw if k == 0 else bx + hw, _ground_y)
		add_child(g)
		_gates.append(g)
	# If you stand outside the walls when they rise (a big jump in), you are put inside
	player.global_position.x = clampf(player.global_position.x, bx - hw + 120.0, bx + hw - 120.0)
	wall_left_x = bx - hw + 40.0
	wall_right_x = bx + hw - 40.0
	level["boss_music"] = String(b["music"])
	level["boss_color"] = b["color"]
	CombatManager.fight_active = false
	_letterbox(true)
	SoundManager.stop_music()
	SoundManager.play_sfx("rumble")
	var side := 1.0 if bx >= player.global_position.x else -1.0
	var land := Vector2(clampf(player.global_position.x + side * 520.0, wall_left_x + 160.0, wall_right_x - 160.0), _ground_y)
	boss = StoryLevels.make_enemy(String(b["id"]))
	boss.slot = 2
	boss.team = 2
	boss.default_facing = -1 if land.x > player.global_position.x else 1
	boss.facing = boss.default_facing
	boss.respawn_enabled = false
	var rise := String(b["entrance"]) == "rise"
	boss.position = land + (Vector2(0, 700) if rise else Vector2(0, -640))
	var z0 := boss.z_index
	if rise:
		boss.z_index = -3
	add_child(boss)
	buff_boss(boss)
	boss.died.connect(_on_demi_boss_died)
	if boss.has_signal("transform_started"):
		boss.connect("transform_started", _on_boss_transform)
	ArenaCamera.focus = boss
	ArenaCamera.focus_zoom = 0.8
	ArenaCamera.focus_offset = Vector2(0, -150)
	await _wait(0.7)
	var tw := create_tween()
	tw.tween_property(boss, "global_position", land, 1.4 if rise else 0.6).set_trans(Tween.TRANS_SINE if rise else Tween.TRANS_QUAD).set_ease(Tween.EASE_OUT if rise else Tween.EASE_IN)
	await tw.finished
	if not is_instance_valid(boss):
		return
	boss.z_index = z0
	Effects.shake(self, 16.0)
	Effects.hit_sparks(boss, land + Vector2(0, -10), 14, 1.6)
	SoundManager.play_sfx("slam")
	SoundManager.play_music(String(b["music"]))
	SoundManager.play_sfx("roar")
	_show_banner(boss.enemy_name.to_upper(), String(b["sub"]), b["color"])
	Effects.popup(boss, boss.global_position + Vector2(0, -boss.data.body_size.y - 60.0), String(b["line"]), (b["color"] as Color).lightened(0.5), 20)
	await _wait(2.4)
	_hide_banner()
	ArenaCamera.focus = null
	_letterbox(false)
	if _dying or _fight.is_empty():
		return
	boss_bar_visible = true
	CombatManager.fight_active = true


func _on_demi_boss_died() -> void:
	if _fight.is_empty():
		return
	var b := _fight
	var where := boss.global_position if boss != null and is_instance_valid(boss) else Vector2(float(b["x"]), _ground_y)
	bosses_done[String(b["id"])] = true
	boss_bar_visible = false
	_clear_hazards()
	SoundManager.stop_music()
	SoundManager.play_sfx("ultimate")
	Effects.shake(self, 14.0)
	_show_banner("%s HAS FALLEN" % boss.enemy_name.to_upper(), "Something it guarded lies on the ground...", Color(1.0, 0.82, 0.35))
	Achievements.unlock("demi_" + String(b["id"]))
	if not player.used.get("healing", false) and not player.used.get("powers", false):
		Achievements.unlock("demi_pure_" + String(b["id"]))
	await _wait(2.4)
	_hide_banner()
	# The artifact drops where it fell
	var pk := DemiWorld.Pickup.new()
	pk.id = String(b["artifact"])
	pk.set_meta("name", String(b["artifact_name"]))
	pk.position = Vector2(clampf(where.x, wall_left_x + 60.0, wall_right_x - 60.0), _ground_y)
	add_child(pk)
	_pickups.append(pk)
	_end_fight()


## The fight is over (boss dead, or you died): fog walls go, the world walls come back.
func _end_fight() -> void:
	for g in _gates:
		if is_instance_valid(g):
			(g as Node).queue_free()
	_gates.clear()
	wall_left_x = _world_l
	wall_right_x = _world_r
	_fight = {}
	boss_bar_visible = false
	if not _ending:
		SoundManager.play_music("story_demiland_night" if is_night() else "story_demiland")


# ============================================================
# ARTIFACTS + THE DOOR
# ============================================================
func _update_pickups(px: float) -> void:
	for pk in _pickups.duplicate():
		if not is_instance_valid(pk):
			_pickups.erase(pk)
			continue
		if absf((pk as Node2D).global_position.x - px) < 80.0:
			carried.append((pk as DemiWorld.Pickup).id)
			_show_banner("ARTIFACT OBTAINED", String((pk as Node).get_meta("name", "")) + "\nIt belongs in a door...", Color(0.8, 0.7, 1.0))
			get_tree().create_timer(2.4).timeout.connect(_hide_banner)
			SoundManager.play_sfx("holy")
			_pickups.erase(pk)
			(pk as Node).queue_free()


func _update_door(px: float) -> void:
	if absf(px - DemiWorld.DOOR_X) > 220.0:
		return
	if not carried.is_empty():
		for id in carried:
			_door.placed.append(id)
			Effects.popup(player, player.global_position + Vector2(0, -200), "ARTIFACT PLACED  (%d / 3)" % _door.placed.size(), Color(0.8, 0.7, 1.0), 24)
		carried.clear()
		SoundManager.play_sfx("slam", -6.0)
		Effects.shake(self, 6.0)
	if _door.placed.size() >= 3:
		_open_door()
	elif _prompt_cd <= 0.0:
		_prompt_cd = 4.0
		Effects.popup(player, player.global_position + Vector2(0, -200), "An ancient door. %d of its 3 sockets are empty." % (3 - _door.placed.size()),
			Color(0.75, 0.7, 0.95), 18)


func _open_door() -> void:
	if _ending:
		return
	_ending = true
	CombatManager.fight_active = false
	_clear_hazards()
	for n in get_tree().get_nodes_in_group("fighters"):
		var f := n as BaseEnemy
		if f != null and not f.is_dead:
			f.queue_free()
	_letterbox(true)
	SoundManager.stop_music()
	var mark := Node2D.new()
	add_child(mark)
	mark.global_position = Vector2(DemiWorld.DOOR_X, _ground_y - 280.0)
	ArenaCamera.focus = mark
	ArenaCamera.focus_zoom = 0.72
	ArenaCamera.focus_offset = Vector2.ZERO
	_show_banner("THE ANCIENT DOOR OPENS", "", Color(0.8, 0.75, 1.0))
	SoundManager.play_sfx("rumble")
	var tw := create_tween()
	tw.tween_property(_door, "open_k", 1.0, 3.2).set_trans(Tween.TRANS_SINE)
	for i in 6:
		Effects.shake(self, 6.0 + float(i) * 2.0)
		await _wait(0.5)
	SoundManager.play_sfx("holy")
	SoundManager.play_sfx("ultimate", -4.0)
	await _wait(0.6)
	_hide_banner()
	await _fade(true)
	ArenaCamera.focus = null
	Achievements.unlock("demi_clear")
	if deaths == 0:
		Achievements.unlock("demi_deathless")
	if rests == 0:
		Achievements.unlock("demi_no_rest")
	if player.dodges >= 25:
		Achievements.unlock("demi_dodges")
	_letterbox(false)
	await _fade(false)
	await _level_clear()


# ============================================================
# DEATH (Souls: you wake at the last CamTon)
# ============================================================
func _on_player_died() -> void:
	if _ending or _dying:
		return
	_dying = true
	deaths += 1
	if autoplay:
		print("DEMILAND autoplay: player died (%d)" % deaths)
	await _wait(1.0)
	SoundManager.stop_music()
	SoundManager.play_sfx("death")
	var tw := create_tween()
	tw.tween_property(_died_label, "modulate:a", 1.0, 0.8)
	await _wait(2.6)
	await _fade(true)
	_died_label.modulate.a = 0.0
	# A boss fight is lost: the boss goes back to its arena (full HP next time)
	if not _fight.is_empty():
		_clear_hazards()
		if boss != null and is_instance_valid(boss):
			if boss.has_method("_clear_minions"):
				boss.call("_clear_minions")
			boss.queue_free()
		boss = null
		_end_fight()
	_reset_camps()
	var sx := float(DemiWorld.SHRINES[last_shrine]["x"]) + 90.0
	player.spawn_position = Vector2(sx, _ground_y - 10.0)
	player.default_facing = 1
	player.respawn()
	if autoplay:
		player.damage_taken_mult = 0.25
	flasks = max_flasks
	ArenaCamera.focus = null
	CombatManager.fight_active = true
	await _fade(false)
	_dying = false
	SoundManager.play_music("story_demiland_night" if is_night() else "story_demiland")


# ============================================================
# SMALL HUD (artifacts carried + door progress) - the big HUD is StoryHUD
# ============================================================
func _draw_overlay() -> void:
	var c := _overlay
	var sz := c.size
	var x := sz.x - 190.0
	var y := 110.0
	FighterArt.label(c, Vector2(x + 85.0, y), "ARTIFACTS", 14, Color(0.8, 0.75, 0.95))
	var ids := ["fang", "crown", "heart"]
	for i in 3:
		var p := Vector2(x + 30.0 + float(i) * 55.0, y + 34.0)
		c.draw_circle(p, 22.0, Color(0, 0, 0, 0.6))
		var have: bool = carried.has(ids[i]) or door_placed().has(ids[i])
		if have:
			DemiWorld.draw_artifact(c, ids[i], p, 0.6, _time, false)
		else:
			c.draw_arc(p, 18.0, 0.0, TAU, 16, Color(0.5, 0.5, 0.55, 0.6), 2.0)
	FighterArt.label(c, Vector2(x + 85.0, y + 80.0), ("NIGHT" if is_night() else "DAY") + "  -  M = MAP", 13, Color(0.75, 0.75, 0.8, 0.8))


# ============================================================
# TESTING (autoplay): the CPU walks east, then west, then home
# ============================================================
func _autoplay_steer() -> void:
	var ai := player.ctl as BaseAI
	if ai == null or ai.enemy != null and is_instance_valid(ai.enemy) and absf(ai.enemy.global_position.x - player.global_position.x) < 1100.0:
		return
	var goal := DemiWorld.DOOR_X
	for b in [DemiWorld.BOSSES[1], DemiWorld.BOSSES[2], DemiWorld.BOSSES[0]]:
		if not bosses_done.has(String(b["id"])):
			goal = float(b["x"])
			break
	for pk in _pickups:
		if is_instance_valid(pk):
			goal = (pk as Node2D).global_position.x
	var step := signf(goal - player.global_position.x) * 420.0 * get_process_delta_time()
	player.global_position.x += step                      # Testing only: the CPU brain fights, this walks
	player.facing = 1 if step > 0.0 else -1
