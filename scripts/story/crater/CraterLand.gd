class_name CraterLand
extends StoryManager
## TERRA CRATERUM - the second OPEN-WORLD Story level (level 67, its own Story part).
## Scene: scenes/CraterLand.tscn (one 16 000 px wide crater). Layout + scenery: CraterWorld.gd.
##
##   * Same rules as DemiLand: SOULS RULES (roll + stamina), CamTons (rest / wake there when you
##     die), camps that wake when you come near, day / night, an accurate MAP, the run is SAVED.
##   * It starts with a CUTSCENE: you shoot out of the last cave and fall into the crater.
##   * Kill the LAVA MELTER (War Front): the magma barrier behind it drains -> the BASALT WALL.
##   * Kill the KHARLEMING LORD (the wreck): it drops the TECHNICIAN'S BREAKER.
##   * DRAG Kharleming corpses (DOWN near one = pick up / drop) to the wall: 3 make a pile.
##   * At the wall with the Breaker + the pile: DOWN = blow the wall up. Walk through = level clear.
##   * NPCs: the VOLCANO SLAVE (mine, main lore) and the KHARLEMING SACRIFICE (on the reactor,
##     mostly screams). Talk = DOWN. A strong move (a power 1/2/3) near one of them (after
##     talking to it) breaks its chains: that one is FREE, the other one DIES. Saved for later parts.

const DAY_TIME := 240.0
const NIGHT_TIME := 120.0
const FADE_TIME := 14.0
const CAMP_WAKE := 950.0
const CAMP_SLEEP := 2700.0
const CORPSES_NEEDED := 3
const MAX_CORPSES := 14
const NPC_RANGE := 230.0
static var test_steer := true

var discovered := {}
var shrines_lit := {}
var last_shrine := 0
var bosses_done := {}
var has_breaker := false
var deaths := 0
var rests := 0
var choice := ""                          # "" / "slave" / "sacrifice" (StoryProgress.crater_choice)

var _shrine_nodes: Array = []
var _camps: Array = []
var _fight: Dictionary = {}
var _gates: Array = []
var _gate: CraterWorld.MagmaGate
var _wall: CraterWorld.BasaltWall
var _reactor: CraterWorld.Reactor
var _mine: CraterWorld.Mine
var _breaker_pickup: CraterWorld.BreakerPickup
var _corpses: Array = []
var _dragging: CraterWorld.Corpse = null
var _talks := {"slave": 0, "sacrifice": 0}
var _last_cd := {}
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
var _map: CraterMap
var _night_mod: CanvasModulate
var _night_sky: ColorRect
var _bg_fade: ColorRect
var _overlay: Control


# ============================================================
# SETUP
# ============================================================
func _ready() -> void:
	super._ready()
	level = level.duplicate(true)
	EnemyAI.leash = 1100.0
	_world_l = wall_left_x
	_world_r = wall_right_x
	StoryProgress.load_progress()
	choice = StoryProgress.crater_choice
	_build_world()
	_build_overlays()
	for i in CraterWorld.CAMPS.size():
		_camps.append({"spawned": false, "cleared": false, "alive": []})


func _exit_tree() -> void:
	super._exit_tree()
	EnemyAI.leash = 0.0


func _setup_arena() -> void:
	var m: Dictionary = (StoryLevels.MAPS["crater_floor"] as Dictionary).duplicate()
	m["half_width"] = CraterWorld.HALF - 60.0
	m["solid"] = true
	_apply_map(m)


func _build_world() -> void:
	var strip: CraterWorld.PropStrip = null
	var strip_x := -INF
	for p in CraterWorld.props():
		if strip == null or float(p["x"]) - strip_x > 1500.0:
			strip = CraterWorld.PropStrip.new()
			strip_x = float(p["x"])
			add_child(strip)
		strip.items.append(p)
	for s in CraterWorld.SHRINES:
		var n := DemiWorld.CamTon.new()
		n.position = Vector2(float(s["x"]), _ground_y)
		add_child(n)
		_shrine_nodes.append(n)
	_gate = CraterWorld.MagmaGate.new()
	_gate.position = Vector2(CraterWorld.MAGMA_GATE_X, _ground_y)
	add_child(_gate)
	_wall = CraterWorld.BasaltWall.new()
	_wall.position = Vector2(CraterWorld.WALL_X, _ground_y)
	add_child(_wall)
	_reactor = CraterWorld.Reactor.new()
	_reactor.position = Vector2(CraterWorld.REACTOR_X, _ground_y)
	add_child(_reactor)
	_mine = CraterWorld.Mine.new()
	_mine.position = Vector2(CraterWorld.MINE_X, _ground_y)
	add_child(_mine)
	_apply_choice_look()


## The two NPCs as the saved choice left them.
func _apply_choice_look() -> void:
	match choice:
		"slave":
			_mine.state = "freed"
			_reactor.state = "dead"
		"sacrifice":
			_mine.state = "dead"
			_reactor.state = "freed"


func _build_overlays() -> void:
	_night_mod = CanvasModulate.new()
	add_child(_night_mod)
	var sky_layer := CanvasLayer.new()
	sky_layer.layer = -9
	add_child(sky_layer)
	_night_sky = ColorRect.new()
	_night_sky.set_anchors_and_offsets_preset(Control.PRESET_FULL_RECT)
	_night_sky.mouse_filter = Control.MOUSE_FILTER_IGNORE
	_night_sky.color = Color(0.03, 0.0, 0.0, 0.0)
	sky_layer.add_child(_night_sky)
	_bg_fade = ColorRect.new()
	_bg_fade.set_anchors_and_offsets_preset(Control.PRESET_FULL_RECT)
	_bg_fade.mouse_filter = Control.MOUSE_FILTER_IGNORE
	_bg_fade.color = Color(0, 0, 0, 0)
	sky_layer.add_child(_bg_fade)
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
	_map = CraterMap.new()
	_map.manager = self
	add_child(_map)


# ============================================================
# FLOW
# ============================================================
func _run() -> void:
	await _intro()


func _intro() -> void:
	CombatManager.fight_active = false
	var resumed := _load_run()
	if resumed:
		_place_party(float(CraterWorld.SHRINES[last_shrine]["x"]) + 110.0)
		_light_shrine(last_shrine, false)
		_enter_region(CraterWorld.region_at(player.global_position.x), false)
		await _wait(0.4)
		SoundManager.play_sfx("spawn", -6.0)
		_show_banner("TERRA CRATERUM", "You wake at the %s.\nBosses beaten: %d / 2     Breaker: %s     Corpses at the wall: %d / %d" % [
			CraterWorld.SHRINES[last_shrine]["name"], bosses_done.size(), "YES" if has_breaker else "no", _wall.pile, CORPSES_NEEDED], Color(1.0, 0.6, 0.3))
		await _wait(3.2)
		_hide_banner()
	else:
		await _fall_cutscene()
	CombatManager.fight_active = true
	Effects.popup(player, player.global_position + Vector2(0, -200), "M = MAP     DOWN at a CamTon = REST     DOWN near a corpse = DRAG", Color(0.95, 0.75, 0.55), 18)


## THE FALL: out of the last cave, down into the crater, between the volcanoes.
func _fall_cutscene() -> void:
	var land_x := float(CraterWorld.SHRINES[0]["x"]) + 220.0
	_place_party(land_x)
	_enter_region(CraterWorld.region_at(land_x), false)
	discovered[String(CraterWorld.region_at(land_x)["key"])] = true
	var land := player.global_position
	player.global_position = land + Vector2(-260, -2600)
	player.visuals.rotation = 0.6
	_letterbox(true)
	ArenaCamera.focus = player
	ArenaCamera.focus_zoom = 0.62
	ArenaCamera.focus_offset = Vector2(0, -60)
	SoundManager.play_sfx("whoosh")
	_show_banner("TERRA CRATERUM", "You shoot out of the last cave... and fall into a crater of volcanoes.", Color(1.0, 0.55, 0.25))
	var tw := create_tween()
	tw.tween_property(player, "global_position", land, 2.6).set_trans(Tween.TRANS_QUAD).set_ease(Tween.EASE_IN)
	tw.parallel().tween_property(player.visuals, "rotation", TAU * 2.0, 2.6)
	await tw.finished
	player.visuals.rotation = 0.0
	Effects.shake(self, 20.0)
	Effects.explosion(self, land + Vector2(0, -20), 120.0)
	for i in 3:
		Effects.hit_sparks(player, land + Vector2(randf_range(-80, 80), -10), 10, 1.4)
	SoundManager.play_sfx("slam")
	SoundManager.play_sfx("rumble", -4.0)
	await _wait(1.2)
	_hide_banner()
	ArenaCamera.focus = null
	_letterbox(false)
	_light_shrine(0, false)
	_save_run()


func is_night() -> bool:
	return _night_k > 0.5


func camp_cleared(i: int) -> bool:
	return i < _camps.size() and bool(_camps[i]["cleared"])


func wall_pile() -> int:
	return _wall.pile if _wall != null else 0


func wall_broken() -> bool:
	return _wall != null and _wall.broken


func _process(delta: float) -> void:
	super._process(delta)
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
	var reg := CraterWorld.region_at(px)
	if String(reg["key"]) != _region:
		_enter_region(reg, true)
	_tick -= delta
	if _tick <= 0.0:
		_tick = 0.25
		_update_camps(px)
	_update_npcs(px)
	_update_shrines(px)
	if _fight.is_empty():
		_check_boss_arenas(px)
	_update_breaker(px)
	_update_corpses(px)
	_update_wall(px)
	_track_strong_moves()
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
	if _fight.is_empty() and not _ending:
		SoundManager.play_music(String(StoryLevels.MAPS[key].get("music", "story_magma")))
	if not discovered.has(key):
		discovered[key] = true
		if announce:
			_show_banner(String(reg["name"]), "", Color(1.0, 0.65, 0.4))
			SoundManager.play_sfx("holy", -10.0)
			get_tree().create_timer(2.2).timeout.connect(_hide_banner)
		if discovered.size() == CraterWorld.REGIONS.size():
			Achievements.unlock("crater_explorer")


func _day_night(delta: float) -> void:
	_time += delta
	var cyc := fmod(_time, DAY_TIME + NIGHT_TIME)
	var k := 0.0
	if cyc > DAY_TIME - FADE_TIME:
		k = clampf((cyc - (DAY_TIME - FADE_TIME)) / FADE_TIME, 0.0, 1.0)
		if cyc > DAY_TIME + NIGHT_TIME - FADE_TIME:
			k = clampf((DAY_TIME + NIGHT_TIME - cyc) / FADE_TIME, 0.0, 1.0)
	_night_k = k
	_night_mod.color = Color(1, 1, 1).lerp(Color(0.55, 0.38, 0.38), k)      # Night here glows red
	_night_sky.color.a = 0.55 * k
	var night := is_night()
	if night != _was_night:
		_was_night = night
		if player != null and not player.is_dead:
			Effects.popup(player, player.global_position + Vector2(0, -230), "NIGHT: only the lava gives light" if night else "Smoky dawn over the crater",
				Color(1.0, 0.5, 0.35) if night else Color(0.95, 0.75, 0.6), 22)


# ============================================================
# CAMPS (+ Kharleming corpses)
# ============================================================
func _update_camps(px: float) -> void:
	for i in _camps.size():
		var st: Dictionary = _camps[i]
		if st["cleared"]:
			continue
		var cx := float(CraterWorld.CAMPS[i]["x"])
		var d := absf(px - cx)
		if not st["spawned"]:
			if d < CAMP_WAKE and _fight.is_empty() and _camp_reachable(cx):
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
				(e as Node).queue_free()
			st["alive"] = []
			st["spawned"] = false


## The camp behind the magma barrier only wakes once the barrier is gone.
func _camp_reachable(cx: float) -> bool:
	return cx < CraterWorld.MAGMA_GATE_X or _gate.drained


func _spawn_camp(i: int) -> void:
	var def: Dictionary = CraterWorld.CAMPS[i]
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
		e.died.connect(_on_camp_enemy_died.bind(e, String(ids[j])))
		(st["alive"] as Array).append(e)


func _on_camp_enemy_died(e: Node, id: String) -> void:
	if CraterWorld.KHARLEMING_IDS.has(id) and is_instance_valid(e):
		_spawn_corpse((e as Node2D).global_position.x, id == "master_kharleming")
	_free_later(e)


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
# CORPSES: DRAG them to the Basalt Wall
# ============================================================
func _spawn_corpse(x: float, master: bool) -> void:
	_corpses = _corpses.filter(func(c: Variant) -> bool: return is_instance_valid(c))
	if _corpses.size() >= MAX_CORPSES:
		var old: CraterWorld.Corpse = _corpses.pop_front()
		if old != _dragging:
			old.queue_free()
	var c := CraterWorld.Corpse.new()
	c.master = master
	c.position = Vector2(x, _ground_y)
	add_child(c)
	_corpses.append(c)


func _update_corpses(px: float) -> void:
	var down := player.ctl != null and player.ctl.just_pressed("crouch")
	if _dragging != null:
		if not is_instance_valid(_dragging):
			_dragging = null
			return
		_dragging.global_position = Vector2(px - float(player.facing) * 70.0, _ground_y)
		if player.is_attacking():
			_drop_corpse()                                         # Swinging lets go
			return
		# At the wall: it joins the pile
		if not _wall.broken and _gate.drained and px > CraterWorld.WALL_X - 300.0:
			_corpses.erase(_dragging)
			_dragging.queue_free()
			_dragging = null
			_wall.pile += 1
			SoundManager.play_sfx("stone", -4.0)
			Effects.popup(player, player.global_position + Vector2(0, -200), "CORPSE PILED  (%d / %d)" % [mini(_wall.pile, CORPSES_NEEDED), CORPSES_NEEDED], Color(1.0, 0.75, 0.4), 24)
			_save_run()
			return
		if down:
			_drop_corpse()
		return
	if not down:
		return
	for c in _corpses:
		if is_instance_valid(c) and absf((c as Node2D).global_position.x - px) < 90.0:
			_dragging = c
			_dragging.dragged = true
			SoundManager.play_sfx("chain", -8.0)
			Effects.popup(player, player.global_position + Vector2(0, -200), "DRAGGING A KHARLEMING CORPSE  (DOWN = drop)", Color(0.85, 0.9, 1.0), 20)
			return


func _drop_corpse() -> void:
	if _dragging != null and is_instance_valid(_dragging):
		_dragging.dragged = false
	_dragging = null


# ============================================================
# THE BASALT WALL + THE MAGMA BARRIER
# ============================================================
func _update_wall(px: float) -> void:
	if _wall.broken:
		if px > CraterWorld.WALL_X + 90.0:
			_finish()
		return
	if not _gate.drained or px < CraterWorld.WALL_X - 320.0:
		return
	var can_blow := has_breaker and _wall.pile >= CORPSES_NEEDED
	if can_blow and player.ctl != null and player.ctl.just_pressed("crouch") and _dragging == null:
		_use_breaker()
		return
	if _prompt_cd > 0.0:
		return
	_prompt_cd = 4.0
	var msg := ""
	if can_blow:
		msg = "DOWN = USE THE TECHNICIAN'S BREAKER"
	elif not has_breaker:
		msg = "A wall of black basalt. Only the Kharlemings' Breaker could crack it.  (Corpses: %d / %d)" % [_wall.pile, CORPSES_NEEDED]
	else:
		msg = "Pile Kharleming corpses here: %d / %d. Drag them (DOWN near one)." % [_wall.pile, CORPSES_NEEDED]
	Effects.popup(player, player.global_position + Vector2(0, -210), msg, Color(1.0, 0.75, 0.5), 18)


func _use_breaker() -> void:
	CombatManager.fight_active = false
	_clear_hazards()
	_letterbox(true)
	var mark := Node2D.new()
	add_child(mark)
	mark.global_position = Vector2(CraterWorld.WALL_X - 120.0, _ground_y - 220.0)
	ArenaCamera.focus = mark
	ArenaCamera.focus_zoom = 0.75
	ArenaCamera.focus_offset = Vector2.ZERO
	_show_banner("THE TECHNICIAN'S BREAKER", "It clicks... and every Kharleming corpse begins to glow.", Color(0.4, 1.0, 1.0))
	_wall.glow = 1.0
	for i in 4:
		SoundManager.play_sfx("count_tick")
		await _wait(0.45 - float(i) * 0.08)
	_hide_banner()
	for i in 7:                                                    # The chain reaction
		Effects.explosion(self, Vector2(CraterWorld.WALL_X - 140.0 + randf_range(-80, 140), _ground_y - randf_range(20, 420)), 110.0)
		Effects.shake(self, 10.0 + float(i) * 2.0)
		SoundManager.play_sfx("explosion" if i % 2 == 0 else "stone")
		await _wait(0.18)
	_wall.shatter()
	_wall.glow = 0.0
	Effects.shake(self, 24.0)
	SoundManager.play_sfx("slam")
	Achievements.unlock("crater_wall")
	_show_banner("THE BASALT WALL FALLS", "The way on is open.", Color(1.0, 0.7, 0.3))
	await _wait(2.4)
	_hide_banner()
	mark.queue_free()
	ArenaCamera.focus = null
	_letterbox(false)
	_save_run()
	CombatManager.fight_active = true


func _finish() -> void:
	if _ending:
		return
	_ending = true
	CombatManager.fight_active = false
	_clear_hazards()
	SoundManager.stop_music()
	await _fade(true)
	StoryProgress.clear_crater()
	Achievements.unlock("crater_clear")
	if deaths == 0:
		Achievements.unlock("crater_deathless")
	await _fade(false)
	await _level_clear()


# ============================================================
# CAMTONS
# ============================================================
func _update_shrines(px: float) -> void:
	for i in CraterWorld.SHRINES.size():
		if absf(px - float(CraterWorld.SHRINES[i]["x"])) > 110.0:
			continue
		if not shrines_lit.has(i):
			_light_shrine(i, true)
		elif _prompt_cd <= 0.0:
			_prompt_cd = 3.0
			Effects.popup(player, player.global_position + Vector2(0, -190), "DOWN = REST", Color(1.0, 0.75, 0.4), 18)
		if player.ctl != null and player.ctl.just_pressed("crouch") and _dragging == null:
			_rest(i)
		return


func _light_shrine(i: int, announce: bool) -> void:
	shrines_lit[i] = true
	last_shrine = i
	(_shrine_nodes[i] as DemiWorld.CamTon).lit = true
	if announce:
		Effects.popup(player, player.global_position + Vector2(0, -210), "CAMTON WOKEN: %s" % CraterWorld.SHRINES[i]["name"], Color(1.0, 0.7, 0.3), 24)
		SoundManager.play_sfx("flame", -6.0)
		Effects.gold_burst(_shrine_nodes[i], (_shrine_nodes[i] as Node2D).global_position + Vector2(0, -60), 90.0)
		_save_run()


func _rest(i: int) -> void:
	for n in get_tree().get_nodes_in_group("fighters"):
		var f := n as BaseEnemy
		if f != null and not f.is_dead and absf(f.global_position.x - player.global_position.x) < 700.0:
			Effects.popup(player, player.global_position + Vector2(0, -190), "YOU CANNOT REST: ENEMIES ARE NEAR", Color(1.0, 0.4, 0.3), 18)
			return
	last_shrine = i
	rests += 1
	player.hp = player.data.max_hp
	player.health_changed.emit(player.hp, player.data.max_hp)
	flasks = max_flasks
	_reset_camps()
	SoundManager.play_sfx("heal")
	Effects.gold_burst(player, player.global_position + Vector2(0, -80), 120.0)
	_show_banner("RESTED", "%s\nHP and flasks restored. The crater's creatures have returned.  (Progress saved)" % CraterWorld.SHRINES[i]["name"], Color(1.0, 0.75, 0.4))
	get_tree().create_timer(2.0).timeout.connect(_hide_banner)
	_save_run()


# ============================================================
# NPCs: the VOLCANO SLAVE and the KHARLEMING SACRIFICE
# ============================================================
func _update_npcs(px: float) -> void:
	if not _fight.is_empty():
		return
	for who: String in ["slave", "sacrifice"]:
		var x := CraterWorld.MINE_X - 40.0 if who == "slave" else CraterWorld.REACTOR_X
		if absf(px - x) > NPC_RANGE or not _npc_there(who):
			continue
		if _prompt_cd <= 0.0:
			_prompt_cd = 3.5
			var hint := "DOWN = TALK"
			if int(_talks[who]) > 0 and choice == "":
				hint += "     (a POWER - 1 / 2 / 3 - here breaks the chains)"
			Effects.popup(player, player.global_position + Vector2(0, -190), hint, Color(0.9, 0.85, 1.0), 18)
		if player.ctl != null and player.ctl.just_pressed("crouch") and _dragging == null:
			_talk(who)
		return


func _npc_there(who: String) -> bool:
	if who == "slave":
		return _mine.state == "chained"
	return _reactor.state == "chained"


func _talk(who: String) -> void:
	var visit := int(_talks[who])
	_talks[who] = visit + 1
	var src: Array = StoryDialogue.SLAVE if who == "slave" else StoryDialogue.SACRIFICE
	var lines: Array = (StoryDialogue.npc_talk(src, visit) as Array).duplicate(true)
	for l in lines:
		if String(l[0]) == "H":
			l[0] = hero
	for l in [_banner, _sub]:
		l.modulate.a = 0.0
	if who == "slave" and visit >= 2:
		Achievements.unlock("crater_lore")
	var box := DialogueBox.play(self, lines)
	await box.finished


## A power or the ultimate used next to a chained NPC (after talking to it) breaks its chains.
func _track_strong_moves() -> void:
	var fired := false
	for k in player.cooldowns:
		var v: float = player.cooldowns[k]
		if v > float(_last_cd.get(k, 0.0)) + 0.5:
			fired = true
		_last_cd[k] = v
	if not fired or choice != "" or not _fight.is_empty():
		return
	var px := player.global_position.x
	if absf(px - (CraterWorld.MINE_X - 40.0)) < NPC_RANGE and _npc_there("slave") and int(_talks["slave"]) > 0:
		_free("slave")
	elif absf(px - CraterWorld.REACTOR_X) < NPC_RANGE and _npc_there("sacrifice") and int(_talks["sacrifice"]) > 0:
		_free("sacrifice")


func _free(who: String) -> void:
	choice = who
	StoryProgress.set_crater_choice(who)
	Effects.shake(self, 10.0)
	SoundManager.play_sfx("chain")
	SoundManager.play_sfx("explosion", -6.0)
	if who == "slave":
		Effects.hit_sparks(_mine, _mine.global_position + Vector2(-40, -40), 14, 1.4)
		_mine.state = "freed"
		_reactor.state = "dead"
		Achievements.unlock("crater_free_slave")
		_show_banner("THE CHAIN BREAKS", "The Volcano Slave runs for the rim.\nFar away, in the wreck, the reactor screams... then goes silent.", Color(1.0, 0.7, 0.4))
	else:
		Effects.hit_sparks(_reactor, _reactor.global_position + Vector2(0, -300), 14, 1.4)
		_reactor.state = "freed"
		_mine.state = "dead"
		Achievements.unlock("crater_free_sacrifice")
		_show_banner("THE CHAINS SNAP", "The Kharleming Sacrifice flees into the wreck.\nFar away, a mountain cracks... and falls.", Color(0.5, 1.0, 1.0))
	get_tree().create_timer(3.6).timeout.connect(_hide_banner)
	_save_run()


# ============================================================
# BOSSES
# ============================================================
func _check_boss_arenas(px: float) -> void:
	for b in CraterWorld.BOSSES:
		if bosses_done.has(String(b["id"])):
			continue
		if absf(px - float(b["x"])) < float(b["half"]) - 220.0:
			_start_boss(b)
			return


func _start_boss(b: Dictionary) -> void:
	_fight = b
	_drop_corpse()
	var bx := float(b["x"])
	var hw := float(b["half"])
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
	player.global_position.x = clampf(player.global_position.x, bx - hw + 120.0, bx + hw - 120.0)
	wall_left_x = bx - hw + 40.0
	wall_right_x = bx + hw - 40.0
	level["boss_music"] = String(b["music"])
	level["boss_color"] = b["color"]
	CombatManager.fight_active = false
	_letterbox(true)
	SoundManager.stop_music()
	SoundManager.play_sfx("rumble")
	var rise := String(b["entrance"]) == "rise"
	var land := Vector2(bx, _ground_y)
	if not rise:
		var side := 1.0 if bx >= player.global_position.x else -1.0
		land = Vector2(clampf(player.global_position.x + side * 520.0, wall_left_x + 180.0, wall_right_x - 180.0), _ground_y)
	elif absf(player.global_position.x - bx) < 300.0:
		player.global_position.x = bx - 420.0                     # Not inside the rising pillar
	boss = StoryLevels.make_enemy(String(b["id"]))
	boss.slot = 2
	boss.team = 2
	boss.default_facing = -1 if land.x > player.global_position.x else 1
	boss.facing = boss.default_facing
	boss.respawn_enabled = false
	boss.position = land + (Vector2(0, 760) if rise else Vector2(0, -640))
	var z0 := boss.z_index
	if rise:
		boss.z_index = -3
	add_child(boss)
	buff_boss(boss)
	boss.died.connect(_on_crater_boss_died)
	ArenaCamera.focus = boss
	ArenaCamera.focus_zoom = 0.7
	ArenaCamera.focus_offset = Vector2(0, -160)
	await _wait(0.7)
	var tw := create_tween()
	tw.tween_property(boss, "global_position", land, 1.6 if rise else 0.6).set_trans(Tween.TRANS_SINE if rise else Tween.TRANS_QUAD).set_ease(Tween.EASE_OUT if rise else Tween.EASE_IN)
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


func _on_crater_boss_died() -> void:
	if _fight.is_empty():
		return
	var b := _fight
	var id := String(b["id"])
	var where := boss.global_position if boss != null and is_instance_valid(boss) else Vector2(float(b["x"]), _ground_y)
	bosses_done[id] = true
	boss_bar_visible = false
	_clear_hazards()
	SoundManager.stop_music()
	SoundManager.play_sfx("ultimate")
	Effects.shake(self, 14.0)
	Achievements.unlock("crater_" + id)
	var lore_name := StoryLore.collect(id)
	await SoulsBanner.felled(self, true, "The magma behind it drains..." if id == "lava_melter" else "Something falls from its claws...").finished
	if lore_name != "":
		Effects.popup(player, player.global_position + Vector2(0, -220), "ITEM FOUND: %s  (CODEX)" % lore_name, Color(1.0, 0.82, 0.38), 20)
	if id == "lava_melter":
		_gate.drain()
		_show_banner("THE MAGMA DRAINS", "Behind it rises a wall of black basalt.", Color(1.0, 0.55, 0.25))
		get_tree().create_timer(2.6).timeout.connect(_hide_banner)
	else:
		_drop_breaker(clampf(where.x, wall_left_x + 60.0, wall_right_x - 60.0))
	_end_fight()
	_save_run()


func _drop_breaker(x: float) -> void:
	if has_breaker or _breaker_pickup != null:
		return
	_breaker_pickup = CraterWorld.BreakerPickup.new()
	_breaker_pickup.position = Vector2(x, _ground_y)
	add_child(_breaker_pickup)


func _update_breaker(px: float) -> void:
	if _breaker_pickup == null or not is_instance_valid(_breaker_pickup):
		return
	if absf(_breaker_pickup.global_position.x - px) < 80.0:
		has_breaker = true
		_breaker_pickup.queue_free()
		_breaker_pickup = null
		var ln := StoryLore.collect("technician_breaker")
		_show_banner("THE TECHNICIAN'S BREAKER", "The Kharlemings use it to blow up a whole colony of themselves.\nTake it to the Basalt Wall." + ("\n(Lore item: read it in the CODEX)" if ln != "" else ""), Color(0.4, 1.0, 1.0))
		get_tree().create_timer(3.4).timeout.connect(_hide_banner)
		SoundManager.play_sfx("holy")
		_save_run()


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
		SoundManager.play_music(String(StoryLevels.MAPS[_region].get("music", "story_magma")) if _region != "" else "story_magma")


# ============================================================
# SAVING A RUN
# ============================================================
func _save_run() -> void:
	if autoplay:
		return
	StoryProgress.save_crater({"lit": shrines_lit.keys(), "last": last_shrine, "bosses": bosses_done.keys(), "breaker": has_breaker,
		"pile": _wall.pile, "broken": _wall.broken, "discovered": discovered.keys(), "deaths": deaths, "rests": rests,
		"time": _time, "talks": _talks.duplicate()})


func _load_run() -> bool:
	var s: Dictionary = StoryProgress.crater
	if s.is_empty() or autoplay:
		return false
	for i in s.get("lit", []):
		shrines_lit[int(i)] = true
		(_shrine_nodes[int(i)] as DemiWorld.CamTon).lit = true
	last_shrine = clampi(int(s.get("last", 0)), 0, CraterWorld.SHRINES.size() - 1)
	for id in s.get("bosses", []):
		bosses_done[String(id)] = true
	for k in s.get("discovered", []):
		discovered[String(k)] = true
	has_breaker = bool(s.get("breaker", false))
	_wall.pile = int(s.get("pile", 0))
	if bool(s.get("broken", false)):
		_wall.shatter()
	deaths = int(s.get("deaths", 0))
	rests = int(s.get("rests", 0))
	_time = float(s.get("time", 0.0))
	var t: Dictionary = s.get("talks", {})
	for k in t:
		_talks[String(k)] = int(t[k])
	if bosses_done.has("lava_melter"):
		_gate.drain()
	if bosses_done.has("kharleming_lord") and not has_breaker:
		_drop_breaker(float(CraterWorld.boss_def("kharleming_lord")["x"]))
	return true


# ============================================================
# DEATH: wake at the last CamTon
# ============================================================
func _on_player_died() -> void:
	if _ending or _dying:
		return
	_dying = true
	deaths += 1
	_drop_corpse()
	await _wait(1.0)
	SoundManager.stop_music()
	await SoulsBanner.died(self).finished
	await _fade(true)
	if not _fight.is_empty():
		_clear_hazards()
		if boss != null and is_instance_valid(boss):
			if boss.has_method("_clear_minions"):
				boss.call("_clear_minions")
			boss.queue_free()
		boss = null
		_end_fight()
	_reset_camps()
	var sx := float(CraterWorld.SHRINES[last_shrine]["x"]) + 90.0
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
	_save_run()


# ============================================================
# SMALL HUD: the Breaker + the pile
# ============================================================
func _draw_overlay() -> void:
	var c := _overlay
	var sz := c.size
	var x := sz.x - 200.0
	var y := 110.0
	if has_breaker:
		CraterWorld.draw_breaker(c, Vector2(x + 30.0, y + 26.0), 0.55, _time)
	else:
		c.draw_arc(Vector2(x + 30.0, y + 26.0), 16.0, 0.0, TAU, 16, Color(0.5, 0.5, 0.55, 0.6), 2.0)
	FighterArt.label(c, Vector2(x + 30.0, y + 66.0), "BREAKER", 12, Color(0.6, 1.0, 1.0) if has_breaker else Color(0.6, 0.6, 0.65))
	FighterArt.label(c, Vector2(x + 120.0, y + 32.0), "%d / %d" % [mini(_wall.pile, CORPSES_NEEDED), CORPSES_NEEDED], 22,
		Color(1.0, 0.75, 0.4) if _wall.pile >= CORPSES_NEEDED else Color(0.9, 0.85, 0.8))
	FighterArt.label(c, Vector2(x + 120.0, y + 66.0), "CORPSES", 12, Color(0.85, 0.8, 0.75))
	if _dragging != null:
		FighterArt.label(c, Vector2(sz.x * 0.5, sz.y - 120.0), "DRAGGING A CORPSE  -  take it to the Basalt Wall (east)", 18, Color(1.0, 0.8, 0.5))
	FighterArt.label(c, Vector2(x + 85.0, y + 92.0), ("NIGHT" if is_night() else "DAY") + "  -  M = MAP", 13, Color(0.8, 0.75, 0.75, 0.8))


# ============================================================
# TESTING (autoplay): walk to the next boss
# ============================================================
func _autoplay_steer() -> void:
	var ai := player.ctl as BaseAI
	if ai == null or ai.enemy != null and is_instance_valid(ai.enemy) and absf(ai.enemy.global_position.x - player.global_position.x) < 1100.0:
		return
	var goal := CraterWorld.WALL_X
	for b in CraterWorld.BOSSES:
		if not bosses_done.has(String(b["id"])):
			goal = float(b["x"])
			break
	var step := signf(goal - player.global_position.x) * 420.0 * get_process_delta_time()
	player.global_position.x += step
	player.facing = 1 if step > 0.0 else -1
