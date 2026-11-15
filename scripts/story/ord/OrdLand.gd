class_name OrdLand
extends StoryManager
## TERRA ORDINARIORUM - the third OPEN-WORLD Story level (level 71, its own Story part).
## Scene: scenes/OrdLand.tscn. Layout + scenery: OrdWorld.gd. Lore by the user (2026-11-15).
##
##   * Starts with a CUTSCENE: you slide down a ramp out of the sky and fall onto a meadow.
##   * You start on the FAR LEFT and explore right: Meadow, Forest, Town, Jungle, Desert, Mountain.
##   * Real-life ANIMALS in every biome: REALLY weak and they never attack (they run away).
##   * The TOWN: ordinary people (talk = DOWN). Ask about the Storm and they think you are crazy.
##   * The MOUNTAIN: jump up the ledges, crawl (hold DOWN) through low tunnels; the LIGHTNING
##     CANDLE waits on the summit.
##   * MAIN ROUTE: light the candle in the Town Square -> the Storm opens, its hand attacks the
##     town -> THE STORM FINGER -> the ORDINARIORUM TICKET -> a bridge comes down from Orbis
##     Terrarum -> walk onto it = level clear.
##   * SECRET: take the candle back past the start to the BASALT WALL -> it blows up -> THE SNOW
##     DESERT (frozen Craterum creatures) -> touch the floating crystal -> THE CRYSTAL SWARM
##     (you cannot die; 10 crystals, then one hit) -> the Frozen Scroll + Frozen Expedition skins.
##   * Same rules as DemiLand: Souls rules, CamTons, a map, the run is saved.

const HERD_WAKE := 1500.0
const HERD_SLEEP := 3000.0
const NPC_RANGE := 110.0
const CRYSTAL_HP_FLOOR := 12
static var test_steer := true

var discovered := {}
var shrines_lit := {}
var last_shrine := 0
var has_candle := false
var wall_broken := false
var crystal_done := false
var finger_done := false
var hurt_animal := false
var deaths := 0
var talks := {}

var _shrine_nodes: Array = []
var _herds: Array = []
var _villagers := {}
var _fight := ""                          # "" / "storm_finger" / "crystal_swarm"
var _gates: Array = []
var _wall: CraterWorld.BasaltWall
var _summit: OrdWorld.Pedestal
var _well: OrdWorld.Well
var _crystal: OrdWorld.Crystal
var _sky: OrdWorld.StormSky
var _region := ""
var _tick := 0.0
var _dying := false
var _ending := false
var _busy := false
var _prompt_cd := 0.0
var _world_l := 0.0
var _world_r := 0.0
var _map: OrdMap
var _bg_fade: ColorRect


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
	_build_world()
	_build_overlays()
	for i in OrdWorld.HERDS.size():
		_herds.append({"spawned": false, "alive": []})


func _exit_tree() -> void:
	super._exit_tree()
	EnemyAI.leash = 0.0


func _setup_arena() -> void:
	var m: Dictionary = (StoryLevels.MAPS["ord_meadow"] as Dictionary).duplicate()
	m["half_width"] = OrdWorld.HALF - 60.0
	m["solid"] = true
	_apply_map(m)


func _build_world() -> void:
	var strip: OrdWorld.PropStrip = null
	var strip_x := -INF
	for p in OrdWorld.props():
		if strip == null or float(p["x"]) - strip_x > 1500.0:
			strip = OrdWorld.PropStrip.new()
			strip_x = float(p["x"])
			add_child(strip)
		strip.items.append(p)
	for l in OrdWorld.LEDGES:
		var n := OrdWorld.Ledge.new()
		n.w = float(l[1]) - float(l[0])
		n.h = float(l[2])
		n.position = Vector2(float(l[0]), _ground_y)
		add_child(n)
	for cr in OrdWorld.CRAWLS:
		var c := OrdWorld.Crawl.new()
		c.w = float(cr[1]) - float(cr[0])
		c.position = Vector2(float(cr[0]), _ground_y - float(cr[2]))
		add_child(c)
	for s in OrdWorld.SHRINES:
		var cn := DemiWorld.CamTon.new()
		cn.position = Vector2(float(s["x"]), _ground_y - OrdWorld.ledge_h(float(s["x"])))
		add_child(cn)
		_shrine_nodes.append(cn)
	for v in OrdWorld.TOWNSFOLK:
		var vn := OrdWorld.Villager.new()
		vn.look = int(v["look"])
		vn.position = Vector2(float(v["x"]), _ground_y)
		add_child(vn)
		_villagers[String(v["id"])] = vn
		talks[String(v["id"])] = 0
	_summit = OrdWorld.Pedestal.new()
	_summit.position = Vector2(OrdWorld.CANDLE_X, _ground_y - OrdWorld.ledge_h(OrdWorld.CANDLE_X))
	add_child(_summit)
	_well = OrdWorld.Well.new()
	_well.position = Vector2(OrdWorld.SQUARE_X, _ground_y)
	_well.z_index = -1
	add_child(_well)
	_wall = CraterWorld.BasaltWall.new()
	_wall.position = Vector2(OrdWorld.WALL_X - 110.0, _ground_y)
	add_child(_wall)
	_crystal = OrdWorld.Crystal.new()
	_crystal.position = Vector2(OrdWorld.CRYSTAL_X, _ground_y)
	add_child(_crystal)
	var fx := [-9700.0, -9450.0, -8850.0, -8600.0, -9900.0]
	for i in fx.size():
		var fz := OrdWorld.Frozen.new()
		fz.kind = "kharleming" if i % 2 == 0 else "golem"
		fz.position = Vector2(fx[i], _ground_y)
		add_child(fz)
	_sky = OrdWorld.StormSky.new()
	_sky.position = Vector2(OrdWorld.SQUARE_X, _ground_y)
	add_child(_sky)


func _build_overlays() -> void:
	var sky_layer := CanvasLayer.new()
	sky_layer.layer = -9
	add_child(sky_layer)
	_bg_fade = ColorRect.new()
	_bg_fade.set_anchors_and_offsets_preset(Control.PRESET_FULL_RECT)
	_bg_fade.mouse_filter = Control.MOUSE_FILTER_IGNORE
	_bg_fade.color = Color(0, 0, 0, 0)
	sky_layer.add_child(_bg_fade)
	var ui := CanvasLayer.new()
	ui.layer = 14
	add_child(ui)
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
	_map = OrdMap.new()
	_map.manager = self
	add_child(_map)


# ============================================================
# FLOW
# ============================================================
func _run() -> void:
	await _intro()


func _intro() -> void:
	CombatManager.fight_active = false
	if _load_run():
		_place_party(float(OrdWorld.SHRINES[last_shrine]["x"]) + 110.0)
		_snap_to_ledge()
		_light_shrine(last_shrine, false)
		_enter_region(OrdWorld.region_at(player.global_position.x), false)
		await _wait(0.4)
		SoundManager.play_sfx("spawn", -6.0)
		_show_banner("TERRA ORDINARIORUM", "You wake at the %s.\nLightning Candle: %s" % [OrdWorld.SHRINES[last_shrine]["name"], "CARRIED" if has_candle else "not found"], Color(0.8, 0.92, 1.0))
		await _wait(3.0)
		_hide_banner()
	else:
		await _ramp_cutscene()
	CombatManager.fight_active = true
	Effects.popup(player, player.global_position + Vector2(0, -200), "M = MAP     DOWN at a CamTon = REST     DOWN near someone = TALK", Color(0.9, 0.95, 1.0), 18)


## THE ARRIVAL: you slide down a long ramp out of the sky and tumble onto the meadow.
func _ramp_cutscene() -> void:
	var land := Vector2(OrdWorld.START_X, _ground_y)
	_place_party(land.x)
	_enter_region(OrdWorld.region_at(land.x), false)
	discovered[String(OrdWorld.region_at(land.x)["key"])] = true
	land = player.global_position
	var ramp_top := land + Vector2(-700, -900)
	var ramp_end := land + Vector2(-120, -260)
	var ramp := Line2D.new()
	ramp.points = PackedVector2Array([ramp_top + Vector2(-400, -400), ramp_end])
	ramp.width = 22.0
	ramp.default_color = Color(0.55, 0.42, 0.30)
	add_child(ramp)
	player.global_position = ramp_top
	player.visuals.rotation = 0.5
	_letterbox(true)
	ArenaCamera.focus = player
	ArenaCamera.focus_zoom = 0.6
	ArenaCamera.focus_offset = Vector2(0, -60)
	SoundManager.play_sfx("whoosh")
	_show_banner("TERRA ORDINARIORUM", "A ramp out of the dark... and then, for the first time in a long time: blue sky.", Color(0.8, 0.92, 1.0))
	var tw := create_tween()
	tw.tween_property(player, "global_position", ramp_end, 1.6).set_trans(Tween.TRANS_QUAD).set_ease(Tween.EASE_IN)
	tw.tween_property(player, "global_position", land, 0.55).set_trans(Tween.TRANS_QUAD).set_ease(Tween.EASE_IN)
	tw.parallel().tween_property(player.visuals, "rotation", TAU, 0.55)
	await tw.finished
	player.visuals.rotation = 0.0
	Effects.shake(self, 10.0)
	Effects.hit_sparks(player, land + Vector2(0, -8), 10, 1.2)
	SoundManager.play_sfx("slam", -4.0)
	await _wait(0.8)
	var fade := create_tween()
	fade.tween_property(ramp, "modulate:a", 0.0, 1.0)
	fade.tween_callback(ramp.queue_free)
	_show_banner("THE MEADOW", "Grass. Flowers. Animals that run from you. The regular land.", Color(0.7, 1.0, 0.6))
	await _wait(2.2)
	_hide_banner()
	ArenaCamera.focus = null
	_letterbox(false)
	_light_shrine(0, false)
	_save_run()


func _process(delta: float) -> void:
	super._process(delta)
	if player == null or not is_instance_valid(player) or _ending:
		return
	if Input.is_action_just_pressed("demi_map"):
		_map.toggle()
	_prompt_cd = maxf(_prompt_cd - delta, 0.0)
	if _fight == "crystal_swarm" and player.hp < CRYSTAL_HP_FLOOR:
		player.hp = CRYSTAL_HP_FLOOR                                # You cannot die to the Crystal Swarm
		player.health_changed.emit(player.hp, player.data.max_hp)
	if _dying or player.is_dead or _busy:
		return
	var px := player.global_position.x
	var reg := OrdWorld.region_at(px)
	if String(reg["key"]) != _region:
		_enter_region(reg, true)
	_tick -= delta
	if _tick <= 0.0:
		_tick = 0.3
		_update_herds(px)
	_update_crawls(px)
	if _fight == "":
		_update_shrines(px)
		_update_people(px)
		_update_candle(px)
		_update_wall(px)
		_update_crystal(px)
		_update_square(px)
		_update_bridge(px)
	if autoplay and test_steer and _fight == "":
		_autoplay_steer()


func is_night() -> bool:
	return false


# ============================================================
# REGIONS (backdrop, ground, music)
# ============================================================
func _enter_region(reg: Dictionary, announce: bool) -> void:
	var key := String(reg["key"])
	_region = key
	var bg := get_parent().get_node_or_null("Background") as HellBackground
	var ground := get_parent().get_node_or_null("ArenaGround") as ArenaGround
	var theme := String(StoryLevels.MAPS[key]["bg"])
	if announce:
		var tw := create_tween()
		tw.tween_property(_bg_fade, "color:a", 1.0, 0.35)
		tw.tween_callback(func() -> void:
			if bg != null:
				bg.theme = theme
			if ground != null:
				ground.ground_theme = int(reg["ground"]))
		tw.tween_property(_bg_fade, "color:a", 0.0, 0.45)
	else:
		if bg != null:
			bg.theme = theme
		if ground != null:
			ground.ground_theme = int(reg["ground"])
	if _fight == "" and not _ending:
		SoundManager.play_music(String(StoryLevels.MAPS[key].get("music", "story_meadow")))
	if not discovered.has(key):
		discovered[key] = true
		if announce:
			_show_banner(String(reg["name"]), "", Color(0.85, 0.95, 1.0))
			SoundManager.play_sfx("holy", -10.0)
			get_tree().create_timer(2.2).timeout.connect(_hide_banner)
		if discovered.size() == OrdWorld.REGIONS.size():
			Achievements.unlock("ord_explorer")


# ============================================================
# ANIMALS (never hostile; they come back when you rest)
# ============================================================
func _update_herds(px: float) -> void:
	for i in _herds.size():
		var st: Dictionary = _herds[i]
		var hx := float(OrdWorld.HERDS[i]["x"])
		var d := absf(px - hx)
		if not st["spawned"]:
			if d < HERD_WAKE and (hx > OrdWorld.WALL_X or wall_broken) and _fight == "" and not _busy:
				_spawn_herd(i)
			continue
		if d > HERD_SLEEP:
			for e in st["alive"]:
				if is_instance_valid(e):
					(e as Node).queue_free()
			st["alive"] = []
			st["spawned"] = false


func _spawn_herd(i: int) -> void:
	var def: Dictionary = OrdWorld.HERDS[i]
	var ids: Array = def["ids"]
	var st: Dictionary = _herds[i]
	st["spawned"] = true
	st["alive"] = []
	var y := float(def.get("y", 0.0))
	for j in ids.size():
		var x := float(def["x"]) + (float(j) - float(ids.size() - 1) * 0.5) * 110.0
		var a := StoryLevels.make_enemy(String(ids[j]))
		a.slot = 2
		a.team = 2
		a.default_facing = -1 if j % 2 == 0 else 1
		a.facing = a.default_facing
		a.respawn_enabled = false
		a.position = Vector2(x, _ground_y - y - 10.0)
		add_child(a)
		a.damaged.connect(func(_amt: int, _hit: HitData) -> void: hurt_animal = true)
		a.died.connect(_free_later.bind(a))
		(st["alive"] as Array).append(a)


func _free_later(e: Node) -> void:
	await _wait(3.0)
	if is_instance_valid(e):
		e.queue_free()


func _reset_herds() -> void:
	for st in _herds:
		for e in st["alive"]:
			if is_instance_valid(e):
				(e as Node).queue_free()
		st["alive"] = []
		st["spawned"] = false


# ============================================================
# THE MOUNTAIN: crawl tunnels (stand up inside = pushed back out)
# ============================================================
func _update_crawls(px: float) -> void:
	if autoplay and test_steer:
		return                                                        # (Tests: the steering bot slides through)
	for cr in OrdWorld.CRAWLS:
		var x0 := float(cr[0])
		var x1 := float(cr[1])
		if px < x0 - 120.0 or px > x1 + 40.0:
			continue
		var floor_here := _ground_y - float(cr[2])
		if absf(player.global_position.y - floor_here) > 60.0:
			continue
		if px > x0 - 10.0 and px < x1 + 10.0:
			if not player.is_crouching:
				# Too tall to stand in here: back out to the nearest opening
				player.global_position.x = x0 - 12.0 if px - x0 < x1 - px else x1 + 12.0
				player.velocity.x = 0.0
				if _prompt_cd <= 0.0:
					_prompt_cd = 2.0
					Effects.popup(player, player.global_position + Vector2(0, -180), "TOO LOW: HOLD DOWN TO CRAWL", Color(0.85, 0.92, 1.0), 18)
			elif player.velocity.y < 0.0:
				player.velocity.y = 0.0                                  # No jumping inside
		elif _prompt_cd <= 0.0 and px < x0:
			_prompt_cd = 3.0
			Effects.popup(player, player.global_position + Vector2(0, -180), "HOLD DOWN TO CRAWL THROUGH", Color(0.85, 0.92, 1.0), 16)


func _snap_to_ledge() -> void:
	var h := OrdWorld.ledge_h(player.global_position.x)
	if h > 0.0:
		player.global_position.y = _ground_y - h - 4.0


# ============================================================
# CAMTONS
# ============================================================
func _update_shrines(px: float) -> void:
	for i in OrdWorld.SHRINES.size():
		var sx := float(OrdWorld.SHRINES[i]["x"])
		if absf(px - sx) > 110.0 or absf(player.global_position.y - (_ground_y - OrdWorld.ledge_h(sx))) > 80.0:
			continue
		if not shrines_lit.has(i):
			_light_shrine(i, true)
		elif _prompt_cd <= 0.0:
			_prompt_cd = 3.0
			Effects.popup(player, player.global_position + Vector2(0, -190), "DOWN = REST", Color(1.0, 0.75, 0.4), 18)
		if _down():
			_rest(i)
		return


func _down() -> bool:
	return player.ctl != null and player.ctl.just_pressed("crouch")


func _light_shrine(i: int, announce: bool) -> void:
	shrines_lit[i] = true
	last_shrine = i
	(_shrine_nodes[i] as DemiWorld.CamTon).lit = true
	if announce:
		Effects.popup(player, player.global_position + Vector2(0, -210), "CAMTON WOKEN: %s" % OrdWorld.SHRINES[i]["name"], Color(1.0, 0.7, 0.3), 24)
		SoundManager.play_sfx("flame", -6.0)
		_save_run()


func _rest(i: int) -> void:
	last_shrine = i
	player.hp = player.data.max_hp
	player.health_changed.emit(player.hp, player.data.max_hp)
	flasks = max_flasks
	_reset_herds()
	SoundManager.play_sfx("heal")
	Effects.gold_burst(player, player.global_position + Vector2(0, -80), 120.0)
	_show_banner("RESTED", "%s\nHP and flasks restored. The animals have wandered back.  (Progress saved)" % OrdWorld.SHRINES[i]["name"], Color(1.0, 0.75, 0.4))
	get_tree().create_timer(2.0).timeout.connect(_hide_banner)
	_save_run()


# ============================================================
# THE TOWNSFOLK
# ============================================================
func _update_people(px: float) -> void:
	for v in OrdWorld.TOWNSFOLK:
		var id := String(v["id"])
		var vn: OrdWorld.Villager = _villagers[id]
		if vn.fled or absf(px - float(v["x"])) > NPC_RANGE:
			continue
		if _prompt_cd <= 0.0:
			_prompt_cd = 3.0
			Effects.popup(player, player.global_position + Vector2(0, -190), "DOWN = TALK", Color(0.95, 0.9, 0.8), 18)
		if _down():
			_talk(id)
		return


func _talk(id: String) -> void:
	_busy = true
	var visit := int(talks.get(id, 0))
	talks[id] = visit + 1
	var lines: Array = (StoryDialogue.npc_talk(StoryDialogue.TOWN[id], visit) as Array).duplicate(true)
	for l in lines:
		if String(l[0]) == "H":
			l[0] = hero
	for l in [_banner, _sub]:
		l.modulate.a = 0.0
	var box := DialogueBox.play(self, lines)
	await box.finished
	_busy = false
	var all := true
	for k in StoryDialogue.TOWN:
		if int(talks.get(k, 0)) < 2:
			all = false
	if all:
		Achievements.unlock("ord_crazy")
	_save_run()


# ============================================================
# THE LIGHTNING CANDLE (summit)
# ============================================================
func _update_candle(px: float) -> void:
	if has_candle or not _summit.has_candle:
		return
	if absf(px - OrdWorld.CANDLE_X) > 80.0 or player.global_position.y > _ground_y - OrdWorld.ledge_h(OrdWorld.CANDLE_X) + 40.0:
		return
	has_candle = true
	_summit.has_candle = false
	SoundManager.play_sfx("holy")
	SoundManager.play_sfx("beam", -8.0)
	Effects.gold_burst(player, player.global_position + Vector2(0, -80), 140.0)
	Achievements.unlock("ord_candle")
	var ln := StoryLore.collect("lightning_candle")
	_show_banner("THE LIGHTNING CANDLE", "Its flame is living lightning. It was made to open the Storm.\nTake it to the TOWN SQUARE." + ("\n(Lore item: read it in the CODEX)" if ln != "" else ""), Color(0.75, 0.9, 1.0))
	get_tree().create_timer(3.6).timeout.connect(_hide_banner)
	_save_run()


# ============================================================
# SECRET: THE BASALT WALL + THE SNOW DESERT + THE CRYSTAL SWARM
# ============================================================
func _update_wall(px: float) -> void:
	if wall_broken or px > OrdWorld.WALL_X + 300.0:
		return
	if has_candle and _down():
		_blow_wall()
		return
	if _prompt_cd <= 0.0:
		_prompt_cd = 4.0
		var msg := "DOWN = HOLD UP THE LIGHTNING CANDLE" if has_candle else "A wall of black basalt. Something about it feels... cold."
		Effects.popup(player, player.global_position + Vector2(0, -200), msg, Color(0.8, 0.9, 1.0), 18)


func _blow_wall() -> void:
	_busy = true
	CombatManager.fight_active = false
	_letterbox(true)
	_show_banner("THE LIGHTNING CANDLE", "The flame leaps from the wick... into the basalt.", Color(0.75, 0.9, 1.0))
	for i in 3:
		Effects.explosion(self, Vector2(OrdWorld.WALL_X - 40.0, _ground_y - 100.0 - float(i) * 140.0), 90.0)
		SoundManager.play_sfx("beam" if i == 0 else "explosion")
		await _wait(0.35)
	_wall.shatter()
	Effects.shake(self, 22.0)
	SoundManager.play_sfx("slam")
	wall_broken = true
	Achievements.unlock("ord_snow")
	_show_banner("THE WALL FALLS", "Behind it: snow. Cold wind. Something glittering far away.", Color(0.85, 0.95, 1.0))
	await _wait(2.4)
	_hide_banner()
	_letterbox(false)
	CombatManager.fight_active = true
	_busy = false
	_save_run()


func _update_crystal(px: float) -> void:
	if crystal_done or not wall_broken or absf(px - OrdWorld.CRYSTAL_X) > 150.0:
		return
	_start_crystal()


func _start_crystal() -> void:
	_fight = "crystal_swarm"
	_crystal.visible = false
	_close_arena(float(OrdWorld.SECRET["x"]), float(OrdWorld.SECRET["half"]))
	CombatManager.fight_active = false
	SoundManager.play_music(String(OrdWorld.SECRET["music"]))
	boss = StoryLevels.make_enemy("crystal_swarm")
	boss.slot = 2
	boss.team = 2
	boss.respawn_enabled = false
	boss.position = Vector2(OrdWorld.CRYSTAL_X, _ground_y)
	add_child(boss)
	boss.died.connect(_on_crystal_died)
	level["boss_color"] = OrdWorld.SECRET["color"]
	player.global_position.x = OrdWorld.CRYSTAL_X + 420.0
	_show_banner("THE CRYSTAL SWARM", "A crystal of the Great Freezing. It wakes.", Color(0.75, 0.9, 1.0))
	SoundManager.play_sfx("holy")
	await _wait(2.0)
	_hide_banner()
	boss_bar_visible = true
	CombatManager.fight_active = true


func _on_crystal_died() -> void:
	crystal_done = true
	boss_bar_visible = false
	_clear_hazards()
	SoundManager.play_sfx("ultimate")
	Effects.shake(self, 14.0)
	await SoulsBanner.felled(self, true, "The ice cracks... and a scroll falls out.").finished
	StoryLore.collect("crystal_swarm")
	StoryProgress.unlock_frozen_skins()
	Achievements.unlock("ord_crystal")
	_show_banner("THE FROZEN SCROLL", "It tells of the Great Freezing, and of the candle's purpose.  (CODEX)\nFROZEN EXPEDITION SKINS UNLOCKED: pick them in SKINS on the Story board.", Color(0.8, 0.95, 1.0))
	get_tree().create_timer(4.0).timeout.connect(_hide_banner)
	_end_fight()
	_save_run()


# ============================================================
# MAIN ROUTE: THE TOWN SQUARE -> THE STORM FINGER -> THE BRIDGE
# ============================================================
func _update_square(px: float) -> void:
	_well.ready_glow = has_candle and not finger_done
	if finger_done or absf(px - OrdWorld.SQUARE_X) > 140.0:
		return
	if not has_candle:
		if _prompt_cd <= 0.0:
			_prompt_cd = 4.0
			Effects.popup(player, player.global_position + Vector2(0, -200), "The Town Square. People chat, a well creaks.", Color(0.95, 0.9, 0.8), 16)
		return
	if _prompt_cd <= 0.0:
		_prompt_cd = 3.0
		Effects.popup(player, player.global_position + Vector2(0, -200), "DOWN = LIGHT THE LIGHTNING CANDLE", Color(0.75, 0.9, 1.0), 20)
	if _down():
		_storm_opens()


func _storm_opens() -> void:
	_busy = true
	_fight = "storm_finger"
	CombatManager.fight_active = false
	_clear_hazards()
	_reset_herds()
	SoundManager.stop_music()
	_letterbox(true)
	var mark := Node2D.new()
	add_child(mark)
	mark.global_position = Vector2(OrdWorld.SQUARE_X, _ground_y - 520.0)
	ArenaCamera.focus = mark
	ArenaCamera.focus_zoom = 0.42
	ArenaCamera.focus_offset = Vector2.ZERO
	_show_banner("THE LIGHTNING CANDLE", "You hold it up to the sky. The flame leaves the wick... and climbs.", Color(0.75, 0.9, 1.0))
	SoundManager.play_sfx("beam")
	await _wait(1.6)
	_hide_banner()
	SoundManager.play_sfx("rumble")
	var tw := create_tween()
	tw.tween_property(_sky, "open", 1.0, 2.2).set_trans(Tween.TRANS_SINE)
	await tw.finished
	_show_banner("THE STORM OPENS", "A hole in the Storm - and behind it, an island in the sky.\nThen the Storm reaches down.", Color(0.85, 0.92, 1.0))
	SoundManager.play_sfx("roar")
	var tw2 := create_tween()
	tw2.tween_property(_sky, "hand", 1.0, 1.4).set_trans(Tween.TRANS_QUAD).set_ease(Tween.EASE_IN)
	await tw2.finished
	for i in 5:                                                   # It smashes the town; the people flee
		Effects.explosion(self, Vector2(OrdWorld.SQUARE_X + randf_range(-700, 700), _ground_y - randf_range(20, 160)), 90.0)
		Effects.shake(self, 16.0)
		SoundManager.play_sfx("slam" if i % 2 == 0 else "explosion")
		await _wait(0.3)
	for id in _villagers:
		(_villagers[id] as OrdWorld.Villager).fled = true
	_hide_banner()
	var tw3 := create_tween()
	tw3.tween_property(_sky, "hand", 0.0, 0.9)
	await tw3.finished
	mark.queue_free()
	await _start_finger()
	_busy = false


func _start_finger() -> void:
	var b := OrdWorld.BOSS
	_close_arena(float(b["x"]), float(b["half"]))
	level["boss_music"] = String(b["music"])
	level["boss_color"] = b["color"]
	var land := Vector2(clampf(player.global_position.x + 520.0, wall_left_x + 180.0, wall_right_x - 180.0), _ground_y)
	boss = StoryLevels.make_enemy("storm_finger")
	boss.slot = 2
	boss.team = 2
	boss.default_facing = -1 if land.x > player.global_position.x else 1
	boss.facing = boss.default_facing
	boss.respawn_enabled = false
	boss.position = land + Vector2(0, -900)
	add_child(boss)
	buff_boss(boss)
	boss.died.connect(_on_finger_died)
	ArenaCamera.focus = boss
	ArenaCamera.focus_zoom = 0.62
	ArenaCamera.focus_offset = Vector2(0, -160)
	var tw := create_tween()
	tw.tween_property(boss, "global_position", land, 0.6).set_trans(Tween.TRANS_QUAD).set_ease(Tween.EASE_IN)
	await tw.finished
	if not is_instance_valid(boss):
		return
	Effects.shake(self, 18.0)
	Effects.hit_sparks(boss, land + Vector2(0, -10), 14, 1.6)
	SoundManager.play_sfx("slam")
	SoundManager.play_music(String(b["music"]))
	_show_banner("THE STORM FINGER", "One finger of the Storm", b["color"])
	await _wait(2.2)
	_hide_banner()
	ArenaCamera.focus = null
	_letterbox(false)
	if _dying or _fight == "":
		return
	boss_bar_visible = true
	CombatManager.fight_active = true


func _on_finger_died() -> void:
	finger_done = true
	boss_bar_visible = false
	_clear_hazards()
	SoundManager.stop_music()
	SoundManager.play_sfx("ultimate")
	Effects.shake(self, 16.0)
	Achievements.unlock("ord_finger")
	await SoulsBanner.felled(self, true, "The finger withdraws into the Storm... and leaves something behind.").finished
	StoryLore.collect("storm_finger")
	_show_banner("THE ORDINARIORUM TICKET", "No one leaves Terra Ordinariorum without one.\nAnd now, out of the hole in the Storm... a bridge comes down.", Color(1.0, 0.92, 0.6))
	SoundManager.play_sfx("holy")
	var tw := create_tween()
	tw.tween_property(_sky, "bridge", 1.0, 3.0).set_trans(Tween.TRANS_SINE)
	await _wait(3.6)
	_hide_banner()
	_end_fight()
	_save_run()


func _update_bridge(px: float) -> void:
	if not finger_done or _ending:
		return
	if absf(px - OrdWorld.BRIDGE_X) < 90.0:
		_walk_the_bridge()
	elif _prompt_cd <= 0.0:
		_prompt_cd = 4.0
		Effects.popup(player, player.global_position + Vector2(0, -200), "The bridge from Orbis Terrarum touches down in the Town.", Color(1.0, 0.92, 0.6), 18)


func _walk_the_bridge() -> void:
	_ending = true
	CombatManager.fight_active = false
	_letterbox(true)
	var top := _sky.global_position + Vector2(80, -830)
	ArenaCamera.focus = player
	ArenaCamera.focus_zoom = 0.5
	_show_banner("ORBIS TERRARUM", "You step onto the bridge. Up, through the hole in the Storm.", Color(1.0, 0.95, 0.75))
	var tw := create_tween()
	tw.tween_property(player, "global_position", top, 4.0).set_trans(Tween.TRANS_SINE)
	await _wait(2.6)
	await _fade(true)
	ArenaCamera.focus = null
	_hide_banner()
	StoryProgress.clear_ord()
	if deaths == 0:
		Achievements.unlock("ord_deathless")
	if not hurt_animal:
		Achievements.unlock("ord_gentle")
	SoundManager.stop_music()
	await _fade(false)
	await _level_clear()


# ============================================================
# BOSS ARENAS
# ============================================================
func _close_arena(cx: float, hw: float) -> void:
	for k in 2:
		var g := DemiWorld.FogGate.new()
		g.side = -1.0 if k == 0 else 1.0
		g.position = Vector2(cx - hw if k == 0 else cx + hw, _ground_y)
		add_child(g)
		_gates.append(g)
	player.global_position.x = clampf(player.global_position.x, cx - hw + 120.0, cx + hw - 120.0)
	wall_left_x = cx - hw + 40.0
	wall_right_x = cx + hw - 40.0


func _end_fight() -> void:
	for g in _gates:
		if is_instance_valid(g):
			(g as Node).queue_free()
	_gates.clear()
	wall_left_x = _world_l
	wall_right_x = _world_r
	_fight = ""
	boss_bar_visible = false
	if not _ending and _region != "":
		SoundManager.play_music(String(StoryLevels.MAPS[_region].get("music", "story_meadow")))


# ============================================================
# SAVING A RUN
# ============================================================
func _save_run() -> void:
	if autoplay:
		return
	StoryProgress.save_ord({"lit": shrines_lit.keys(), "last": last_shrine, "discovered": discovered.keys(), "candle": has_candle,
		"wall": wall_broken, "crystal": crystal_done, "finger": finger_done, "deaths": deaths, "hurt": hurt_animal, "talks": talks.duplicate()})


func _load_run() -> bool:
	var s: Dictionary = StoryProgress.ord
	if s.is_empty() or autoplay:
		return false
	for i in s.get("lit", []):
		shrines_lit[int(i)] = true
		(_shrine_nodes[int(i)] as DemiWorld.CamTon).lit = true
	last_shrine = clampi(int(s.get("last", 0)), 0, OrdWorld.SHRINES.size() - 1)
	for k in s.get("discovered", []):
		discovered[String(k)] = true
	has_candle = bool(s.get("candle", false))
	_summit.has_candle = not has_candle
	wall_broken = bool(s.get("wall", false))
	if wall_broken:
		_wall.shatter()
	crystal_done = bool(s.get("crystal", false))
	_crystal.visible = not crystal_done
	finger_done = bool(s.get("finger", false))
	if finger_done:
		_sky.open = 1.0
		_sky.bridge = 1.0
		for id in _villagers:
			(_villagers[id] as OrdWorld.Villager).fled = true
	deaths = int(s.get("deaths", 0))
	hurt_animal = bool(s.get("hurt", false))
	var t: Dictionary = s.get("talks", {})
	for k in t:
		talks[String(k)] = int(t[k])
	return true


# ============================================================
# DEATH: wake at the last CamTon
# ============================================================
func _on_player_died() -> void:
	if _ending or _dying:
		return
	_dying = true
	deaths += 1
	await _wait(1.0)
	SoundManager.stop_music()
	await SoulsBanner.died(self).finished
	await _fade(true)
	if _fight != "":
		_clear_hazards()
		if boss != null and is_instance_valid(boss):
			boss.queue_free()
		boss = null
		if _fight == "storm_finger":
			_sky.open = 0.0                                       # The Storm closes again: light it once more
			for id in _villagers:
				(_villagers[id] as OrdWorld.Villager).fled = false
		_end_fight()
	_reset_herds()
	var sx := float(OrdWorld.SHRINES[last_shrine]["x"]) + 90.0
	player.spawn_position = Vector2(sx, _ground_y - OrdWorld.ledge_h(sx) - 10.0)
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
# TESTING (autoplay): the main route
# ============================================================
func _autoplay_steer() -> void:
	var goal := OrdWorld.CANDLE_X if not has_candle else (OrdWorld.SQUARE_X if not finger_done else OrdWorld.BRIDGE_X)
	var step := signf(goal - player.global_position.x) * 520.0 * get_process_delta_time()
	player.global_position.x += step
	player.facing = 1 if step > 0.0 else -1
	var h := OrdWorld.ledge_h(player.global_position.x)
	if player.global_position.y > _ground_y - h + 2.0:
		player.global_position.y = _ground_y - h - 2.0              # (Tests only: lifted onto ledges)
	if has_candle and not finger_done and absf(player.global_position.x - OrdWorld.SQUARE_X) < 100.0:
		_storm_opens()
