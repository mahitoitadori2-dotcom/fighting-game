class_name StoryManager
extends Node2D
## STORY MODE director. Put ONE in the Story arena scene (instead of ArenaManager).
## Runs the current level (StoryProgress.current_level) from StoryLevels:
##
##   intro (you drop in, level title)
##   -> GROUP BATTLES: each wave of enemies drops in; next wave when all are dead
##   -> (boss level) BOSS INTRO cutscene (letterbox, camera on the boss, title card,
##      FLASKS REFILLED) -> BOSS FIGHT (big HP bar at the top) -> BOSS DEATH cutscene
##   -> LEVEL CLEAR: progress saved, then you FALL into the caves to the next level.
##   You die -> YOU DIED (retry the level / menus).
##
## FLASKS (Story only): FLASKS_PER_LEVEL per level, each heals FLASK_HEAL of max HP.
## R key / controller Back / touch "+" button. Refilled after the boss intro.
## GROUP AI: at most MAX_ATTACKERS enemies attack at the same time (may_attack()).

signal wave_cleared
signal boss_defeated

const FLASKS_PER_LEVEL := 2
const FLASK_HEAL := 0.5
const MAX_ATTACKERS := 2
const ARENA_SCENE := "res://scenes/StoryArena.tscn"
const STORY_MENU := "res://scenes/StoryMenu.tscn"

## Static so enemies / touch controls can ask without a reference.
static var active := false
static var has_walls := false
static var wall_left_x := -100000.0
static var wall_right_x := 100000.0
## TESTING ONLY: the Warrior is played by its CPU brain and takes 25% damage,
## so a whole Colosseum can run by itself. Never on in normal play.
static var autoplay := false

@export var player_spawn := Vector2(330, 525)

var level_number := 1
var level: Dictionary = {}
var player: ControlledFighter               # Warrior (Colosseums 1-3) or Architect (Colosseum 4)
var hero := "warrior"
var flasks := FLASKS_PER_LEVEL
## Colosseum 4, level 24: "" = undecided, "killed" = The Shining died (Void weaker),
## "spared" = you walked past it (Void Massacre stronger).
var shining_choice := ""
var boss: BaseEnemy
var boss_bar_visible := false
var wave_text := ""

var _alive := 0
var _wave_index := 0
var _center_x := 576.0
var _fog: StoryFog
var _over := false
var _saved_sandbox := false
var _ground_y := 525.0
var _hud: StoryHUD
var _ui: CanvasLayer
var _banner: Label
var _sub: Label
var _bar_top: ColorRect
var _bar_bottom: ColorRect


# ============================================================
# GROUP BATTLE RULE
# ============================================================
## True if this enemy may start an attack now (Versus / Enemy Test: always true).
static func may_attack(e: BaseEnemy) -> bool:
	if not active or e == null or not e.is_inside_tree():
		return true
	var busy := 0
	for n in e.get_tree().get_nodes_in_group("fighters"):
		var o := n as BaseEnemy
		if o == null or o == e or o.is_dead:
			continue
		if o.estate == BaseEnemy.EState.TELEGRAPH or o.estate == BaseEnemy.EState.ATTACK:
			busy += 1
	return busy < MAX_ATTACKERS


# ============================================================
# SETUP
# ============================================================
func _ready() -> void:
	active = true
	add_to_group("story_manager")
	StoryProgress.load_progress()
	level_number = clampi(StoryProgress.current_level, 1, StoryLevels.count())
	level = StoryLevels.get_level(level_number)
	_saved_sandbox = MatchSettings.sandbox
	MatchSettings.sandbox = false                  # Story is always played with normal rules
	OptimizationManager.clear_pools()
	Effects.clear_hitstop()
	CombatManager.fight_active = false
	ArenaCamera.focus = null
	_register_input()
	_setup_arena()
	_spawn_player()
	_hud = StoryHUD.new()
	_hud.manager = self
	add_child(_hud)
	if MatchSettings.touch_enabled():
		var tc := TouchControls.new()
		tc.name = "TouchControls"
		add_child(tc)
	_build_ui()
	SoundManager.play_music(String(StoryLevels.map_of(level_number).get("music", "fight")))   # Fits the area
	if autoplay:
		print("STORY autoplay: level %d start" % level_number)
	_run.call_deferred()


func _exit_tree() -> void:
	active = false
	has_walls = false
	MatchSettings.sandbox = _saved_sandbox
	ArenaCamera.focus = null
	Engine.time_scale = 1.0


func _register_input() -> void:
	if not InputMap.has_action("use_flask"):
		InputMap.add_action("use_flask")
		var k := InputEventKey.new()
		k.physical_keycode = KEY_R
		InputMap.action_add_event("use_flask", k)
		var b := InputEventJoypadButton.new()
		b.button_index = JOY_BUTTON_BACK
		b.device = -1
		InputMap.action_add_event("use_flask", b)


## Applies this level's MAP (StoryLevels.MAPS): backdrop, floor, wall style, arena width.
func _setup_arena() -> void:
	_apply_map(StoryLevels.map_of(level_number))


func _apply_map(map: Dictionary) -> void:
	var bg := get_parent().get_node_or_null("Background") as HellBackground
	if bg != null:
		bg.theme = map.get("bg", "surface")
	var ground := get_tree().get_first_node_in_group("arena_ground") as ArenaGround
	var center_x := 576.0
	if ground != null:
		_ground_y = ground.global_position.y
		center_x = ground.global_position.x
		ground.ground_theme = int(map.get("ground", 2))
	_center_x = center_x
	# Sewers: drifting green fog in front of the floor
	if bool(map.get("fog", false)):
		if _fog == null:
			_fog = StoryFog.new()
			add_child(_fog)
		_fog.global_position = Vector2(center_x, _ground_y)
		_fog.half_width = float(map.get("half_width", 850.0))
	elif _fog != null:
		_fog.queue_free()
		_fog = null
	var wl := get_parent().get_node_or_null("WallLeft") as CaveWall
	var wr := get_parent().get_node_or_null("WallRight") as CaveWall
	has_walls = wl != null and wr != null
	if has_walls:
		var hw: float = map.get("half_width", 850.0)
		wl.global_position.x = center_x - hw                # Tighter maps just move the walls in
		wr.global_position.x = center_x + hw
		wl.style = map.get("walls", "lava")
		wr.style = wl.style
		wall_left_x = wl.inner_x()
		wall_right_x = wr.inner_x()
		player_spawn.x = clampf(player_spawn.x, wall_left_x + 120.0, wall_right_x - 120.0)


func _spawn_player() -> void:
	hero = StoryLevels.hero_of(level_number)
	if hero == "architect":
		player = Player.new()                    # The Mighty Architect: own moves, look, animations
		player.name = "P1_Architect"
	else:
		player = Warrior.new()
		player.name = "P1_Warrior"
	player.position = player_spawn
	player.spawn_position = player_spawn
	player.slot = 1
	player.team = 1
	player.default_facing = 1
	player.facing = 1
	player.respawn_enabled = false               # Story: death = retry the level
	if autoplay:
		player.ctl = ArchitectAI.new() if hero == "architect" else WarriorAI.new()
	else:
		player.ctl = FighterInput.new()
	add_child(player)
	if hero == "architect":
		# Story only (own data copy, Versus unchanged): the punch box reaches head to toes,
		# like the Warrior's sword, so it also hits short enemies (Black Crawlings...).
		player.data.punch_offset = Vector2(44, -58)
		player.data.punch_size = Vector2(70, 114)
	if autoplay:
		player.damage_taken_mult = 0.25
	player.died.connect(_on_player_died)


# ============================================================
# LEVEL FLOW
# ============================================================
func _run() -> void:
	await _intro()
	if bool(level.get("altar", false)):
		await _altar_stage()                       # Colosseum 4: the optional Shining
		if _over:
			return
		var sm := String(level.get("stage_map", ""))
		if sm != "":
			await _switch_map(sm, String(level.get("stage_title", "")), String(level.get("stage_sub", "")), Color(0.75, 0.6, 1.0))
	var waves: Array = level.get("waves", [])
	for i in waves.size():
		_wave_index = i
		await _spawn_wave(waves[i], i, waves.size())
		await wave_cleared
		if _over:
			return
		if i < waves.size() - 1:
			_show_banner("WAVE CLEARED", "", Color(0.6, 1.0, 0.6))
			await _wait(1.3)
			_hide_banner()
	if String(level.get("boss", "")) != "":
		await _boss_intro()
		await boss_defeated
		if _over:
			return
		await _boss_death_cutscene()
	elif String(level.get("cutscene_out", "")) != "":
		# Normal level that ends in a cutscene (Colosseum 4: the floor breaks, you fall into the void)
		if bool(level.get("floor_break", false)):
			await _floor_break()
		await _play_cutscene(String(level["cutscene_out"]))
	await _level_clear()


func _play_cutscene(kind: String) -> void:
	var cs := StoryCutscene.new()
	cs.kind = kind
	cs.hero_art = ArchitectArt if hero == "architect" else WarriorArt
	add_child(cs)
	await cs.finished
	cs.queue_free()


## Fade to another map in the middle of a level (boss arena, the Spider Lair after the altar).
func _switch_map(map_key: String, title: String, sub: String, col: Color) -> void:
	CombatManager.fight_active = false
	ChemicalPool.dry_all()
	await _fade(true)
	_apply_map(StoryLevels.MAPS.get(map_key, {}))
	player.global_position = Vector2(player_spawn.x, _ground_y)
	player.velocity = Vector2.ZERO
	player.facing = 1
	for n in get_tree().get_nodes_in_group("fighters"):
		var f := n as BaseEnemy
		if f != null and f.is_dead:
			f.visible = false                          # Corpses stay behind
	if title != "":
		_show_banner(title, sub, col)
	await _fade(false)
	await _wait(1.8)
	_hide_banner()
	CombatManager.fight_active = true


## The last Void Escapist breaks the floor under you (Colosseum 4, level 20).
func _floor_break() -> void:
	CombatManager.fight_active = false
	_show_banner("THE FLOOR BREAKS!", "The last Void Escapist tore the ground open...", Color(0.75, 0.55, 1.0))
	SoundManager.play_sfx("rumble")
	SoundManager.play_sfx("stone")
	for i in 4:
		Effects.shake(self, 8.0 + float(i) * 4.0)
		Effects.void_burst(self, player.global_position + Vector2(randf_range(-160.0, 160.0), -10.0), 90.0)
		await _wait(0.35)
	SoundManager.play_sfx("explosion")
	_hide_banner()
	var tw := create_tween()
	tw.tween_property(player, "global_position", player.global_position + Vector2(0, 700), 0.7).set_trans(Tween.TRANS_QUAD).set_ease(Tween.EASE_IN)
	await tw.finished


# ============================================================
# COLOSSEUM 4: THE ALTAR (optional fight against The Shining)
# ============================================================
## TESTING ONLY (autoplay): force the altar choice ("killed" / "spared").
static var test_shining_choice := ""


func _altar_stage() -> void:
	shining_choice = ""
	var right := (wall_right_x if has_walls else player.global_position.x + 900.0)
	var gate := AltarGate.new()
	add_child(gate)
	gate.global_position = Vector2(right - 70.0, _ground_y)
	var shining := _spawn_enemy("shining", Vector2(_center_x + 120.0, _ground_y - 200.0))
	_alive = 0                                     # The Shining is optional: it doesn't block the level
	_show_banner("THE SHINING", "Kill The Shining to weaken the Void?\nOr leave it and face a stronger Void Massacre?", Color(1.0, 0.9, 0.5))
	SoundManager.play_sfx("holy")
	await _wait(3.4)
	_hide_banner()
	wave_text = "KILL IT = weaker Void   |   DARK GATE -> = stronger Massacre"
	while not _over:
		if test_shining_choice == "spared" or (not autoplay and player.global_position.x >= gate.global_position.x - 50.0):
			shining_choice = "spared"
			break
		if shining == null or not is_instance_valid(shining) or shining.is_dead:
			shining_choice = "killed"
			break
		await _wait(0.1)
	wave_text = ""
	if _over:
		return
	if shining_choice == "killed":
		Effects.gold_burst(self, player.global_position + Vector2(0, -80), 160.0)
		SoundManager.play_sfx("ultimate")
		_show_banner("THE SHINING IS GONE", "Its light poured into the Void.  The Void is WEAKER now.", Color(1.0, 0.9, 0.5))
	else:
		if shining != null and is_instance_valid(shining) and not shining.is_dead:
			var tw := create_tween()
			tw.tween_property(shining, "modulate:a", 0.0, 0.8)
			tw.tween_callback(shining.queue_free)
		SoundManager.play_sfx("roar", -4.0)
		_show_banner("YOU LEFT THE SHINING", "Somewhere below, the Void Massacre grows STRONGER...", Color(1.0, 0.35, 0.35))
	await _wait(2.6)
	_hide_banner()
	gate.queue_free()


## Weaken / strengthen void enemies after the altar choice (Colosseum 4 only).
func _apply_void_mod(e: BaseEnemy, id: String) -> void:
	if shining_choice == "" or not (id in ["void_soul", "tentacle", "masker", "void_massacre", "escapist", "crawling"]):
		return
	var mode := "weak" if shining_choice == "killed" else ("strong" if id == "void_massacre" else "")
	if mode == "":
		return                                       # Skipping The Shining only empowers the Massacre
	var hp_mult := 0.7 if mode == "weak" else 1.35
	e.data.max_hp = roundi(float(e.data.max_hp) * hp_mult)
	e.hp = e.data.max_hp
	e.damage_mult = 0.7 if mode == "weak" else 1.25
	if e.has_method("apply_void_mod"):
		e.call("apply_void_mod", mode)              # Speed / aggression (the Massacre)
	e.health_changed.emit(e.hp, e.data.max_hp)


## The dark gate out of the altar: walk into it to leave The Shining alive.
class AltarGate extends Node2D:
	var _t := 0.0

	func _ready() -> void:
		z_index = -1

	func _process(delta: float) -> void:
		_t += delta
		queue_redraw()

	func _draw() -> void:
		var pulse := 0.5 + 0.5 * sin(_t * 3.0)
		draw_rect(Rect2(-46, -220, 92, 220), Color(0.02, 0.0, 0.05))
		draw_circle(Vector2(0, -110), 70.0 + 8.0 * pulse, Color(0.5, 0.2, 0.9, 0.15))
		draw_rect(Rect2(-46, -220, 92, 220), Color(0.55, 0.3, 0.95, 0.6 + 0.4 * pulse), false, 5.0)
		for i in 6:
			var k := fmod(_t * 0.6 + float(i) / 6.0, 1.0)
			draw_circle(Vector2(sin(float(i) * 2.0) * 28.0, -20.0 - k * 180.0), 3.0 * (1.0 - k), Color(0.8, 0.6, 1.0, 1.0 - k))
		FighterArt.label(self, Vector2(0, -236), "LEAVE  ->", 18, Color(0.85, 0.7, 1.0))


func _intro() -> void:
	CombatManager.fight_active = false
	if String(level.get("arrive", "drop")) == "stand":
		await _wait(0.4)                               # Already here (rode the elevator up)
		SoundManager.play_sfx("spawn", -6.0)
	else:
		# Drop in from above
		var land := player.global_position
		player.global_position = land + Vector2(0, -520)
		var tw := create_tween()
		tw.tween_property(player, "global_position", land, 0.55).set_trans(Tween.TRANS_QUAD).set_ease(Tween.EASE_IN)
		await tw.finished
		Effects.shake(self, 9.0)
		Effects.hit_sparks(player, land + Vector2(0, -8), 10, 1.2)
		SoundManager.play_sfx("spawn")
	_show_banner("LEVEL %d" % level_number, "%s\n%s" % [level.get("title", ""), level.get("intro", "")], Color(1.0, 0.7, 0.3))
	await _wait(2.4)
	_hide_banner()
	CombatManager.fight_active = true


func _spawn_wave(group: Array, idx: int, total: int) -> void:
	var ambush := bool(level.get("ambush", false)) and idx == 0
	if ambush:
		# They fall from the ceiling (Colosseum 3: the Burning Throne Room)
		_show_banner("AMBUSH!", "They drop from the ceiling!", Color(1.0, 0.35, 0.2))
		SoundManager.play_sfx("rumble", -4.0)
		Effects.shake(self, 8.0)
	else:
		_show_banner("WAVE %d / %d" % [idx + 1, total] if total > 1 else "FIGHT!", "", Color(1.0, 0.45, 0.3))
	await _wait(0.8)
	_hide_banner()
	_alive = 0
	var lo := (wall_left_x if has_walls else player.global_position.x - 700.0) + 70.0
	var hi := (wall_right_x if has_walls else player.global_position.x + 700.0) - 70.0
	for j in group.size():
		# Spread around the player: mostly in front, every 3rd one behind
		var behind := j % 3 == 2
		var x := player.global_position.x + (-1.0 if behind else 1.0) * (300.0 + float(j) * 85.0)
		if x > hi or x < lo:
			x = player.global_position.x - signf(x - player.global_position.x) * (300.0 + float(j) * 60.0)
		x = clampf(x, lo, hi)
		var drop_h := 680.0 if ambush else 280.0
		_spawn_enemy(String(group[j]), Vector2(x, _ground_y - drop_h - float(j) * 30.0))
	_update_wave_text()


func _spawn_enemy(id: String, pos: Vector2) -> BaseEnemy:
	var e := StoryLevels.make_enemy(id)
	e.slot = 2
	e.team = 2
	e.default_facing = -1 if pos.x > player.global_position.x else 1
	e.facing = e.default_facing
	e.respawn_enabled = false
	e.position = pos
	add_child(e)
	_apply_void_mod(e, id)
	Effects.hit_sparks(e, pos + Vector2(0, -40), 8, 1.0)
	e.died.connect(_on_enemy_died.bind(e))
	_alive += 1
	return e


func _on_enemy_died(_e: BaseEnemy) -> void:
	if _over:
		return
	_alive = maxi(_alive - 1, 0)
	_update_wave_text()
	if _alive == 0:
		await _wait(0.6)                           # Let the last death animation breathe
		wave_cleared.emit()


func _update_wave_text() -> void:
	var waves: Array = level.get("waves", [])
	wave_text = "WAVE %d / %d     ENEMIES LEFT: %d" % [_wave_index + 1, waves.size(), _alive] if _alive > 0 else ""


# ============================================================
# BOSS
# ============================================================
func _boss_intro() -> void:
	CombatManager.fight_active = false
	wave_text = ""
	ChemicalPool.dry_all()
	_letterbox(true)
	SoundManager.stop_music()
	# The boss has his own arena (Blinded Lord: the LAB): fade out, swap the map, fade in
	var boss_map := String(level.get("boss_map", ""))
	if boss_map != "":
		await _fade(true)
		_apply_map(StoryLevels.MAPS.get(boss_map, {}))
		player.global_position = Vector2(player_spawn.x, _ground_y)
		player.velocity = Vector2.ZERO
		player.facing = 1
		for n in get_tree().get_nodes_in_group("fighters"):
			var f := n as BaseEnemy
			if f != null and f.is_dead:
				f.visible = false                          # Old corpses stay behind in the caves
		_show_banner(String(level.get("boss_map_title", "")), String(level.get("boss_map_sub", "")), Color(0.6, 1.0, 0.4))
		await _fade(false)
		await _wait(1.6)
		_hide_banner()
	elif String(level.get("boss_map_title", "")) != "":
		# Same arena: just name it while the ground starts to shake
		_show_banner(String(level["boss_map_title"]), String(level.get("boss_map_sub", "")), Color(1.0, 0.55, 0.3))
		SoundManager.play_sfx("rumble")
		Effects.shake(self, 6.0)
		await _wait(2.0)
		_hide_banner()
	var bx := 0.0
	if String(level.get("boss_pos", "right")) == "center":
		bx = _center_x                                   # Giant bosses tower over the middle
	else:
		var hi := (wall_right_x if has_walls else player.global_position.x + 600.0) - 120.0
		bx = clampf(player.global_position.x + 460.0, player.global_position.x + 200.0, hi)
		if bx - player.global_position.x < 200.0:
			bx = player.global_position.x - 460.0         # No room on the right: come from the left
	var land := Vector2(bx, _ground_y)
	var rise := String(level.get("boss_intro", "drop")) == "rise"
	boss = StoryLevels.make_enemy(String(level["boss"]))
	boss.slot = 2
	boss.team = 2
	boss.default_facing = -1 if bx > player.global_position.x else 1
	boss.facing = boss.default_facing
	boss.respawn_enabled = false
	boss.position = land + (Vector2(0, 760) if rise else Vector2(0, -620))
	var z_before := boss.z_index
	if rise:
		boss.z_index = -3                                  # Climbs up from BEHIND the floor
	add_child(boss)
	_apply_void_mod(boss, String(level["boss"]))
	boss.died.connect(_on_boss_died)
	if boss.has_signal("transform_started"):
		boss.connect("transform_started", _on_boss_transform)
	var boss_color: Color = level.get("boss_color", Color(0.6, 1.0, 0.3))
	if rise:
		# Camera on the spot it climbs out of (not on the boss far below the floor)
		var mark := Node2D.new()
		add_child(mark)
		mark.global_position = land + Vector2(0, -120)
		ArenaCamera.focus = mark
		ArenaCamera.focus_zoom = 0.72
		ArenaCamera.focus_offset = Vector2(0, -110)
		SoundManager.play_sfx("rumble")
		Effects.shake(self, 8.0)
		await _wait(0.9)
		SoundManager.play_sfx("rumble", -2.0)
		var tw := create_tween()
		tw.tween_property(boss, "global_position", land, 1.6).set_trans(Tween.TRANS_SINE).set_ease(Tween.EASE_OUT)
		for i in 4:
			await _wait(0.4)
			Effects.shake(self, 7.0 + float(i) * 2.0)
		if tw.is_running():
			await tw.finished
		if boss.has_method("on_intro_landed"):
			boss.call("on_intro_landed")                   # Architect Chorus: hands GRAB the elevator
		Effects.shake(self, 18.0)
		SoundManager.play_sfx("slam")
		SoundManager.play_sfx("explosion", -4.0)
		mark.queue_free()
		ArenaCamera.focus = boss
		ArenaCamera.focus_zoom = 0.72
	else:
		ArenaCamera.focus = boss
		ArenaCamera.focus_zoom = 1.05
		SoundManager.play_sfx("rumble")                    # The ground shakes before he drops in
		await _wait(0.8)
		SoundManager.play_sfx("whoosh")
		var tw := create_tween()
		tw.tween_property(boss, "global_position", land, 0.6).set_trans(Tween.TRANS_QUAD).set_ease(Tween.EASE_IN)
		await tw.finished
		Effects.shake(self, 16.0)
		Effects.hit_sparks(boss, land + Vector2(0, -10), 14, 1.6)
		SoundManager.play_sfx("slam")
		SoundManager.play_sfx("explosion", -4.0)
	if rise and boss.z_index == -3 and not boss.has_method("stays_behind_floor"):
		boss.z_index = z_before
	SoundManager.play_music(String(level.get("boss_music", "boss")))
	await _wait(0.3)
	SoundManager.play_sfx("roar")                      # Boss roar
	await _wait(0.2)
	_show_banner(boss.enemy_name.to_upper(), String(level.get("boss_sub", "")), boss_color)
	var line := String(level.get("boss_line", ""))
	if line != "":
		Effects.popup(boss, boss.global_position + Vector2(0, -boss.data.body_size.y - 60.0), line, boss_color.lightened(0.5), 20)
	await _wait(2.6)
	_hide_banner()
	ArenaCamera.focus_offset = Vector2(0, -110)
	# Flasks refill after the boss intro
	flasks = FLASKS_PER_LEVEL
	Effects.popup(player, player.global_position + Vector2(0, -170), "FLASKS REFILLED!", Color(0.5, 1.0, 0.5), 24)
	SoundManager.play_sfx("heal")
	ArenaCamera.focus = null
	_letterbox(false)
	await _wait(0.6)
	boss_bar_visible = true
	SoundManager.play_sfx("count_go")
	Effects.shake(self, 12.0)
	_show_banner("FIGHT!", "", Color(1.0, 0.45, 0.3))
	CombatManager.fight_active = true
	if bool(level.get("sword_power", false)) and player is Warrior:
		(player as Warrior).set_sword_power(1, "YOUR SWORD GROWS!")      # Caeser fight: the blade answers the challenge
	await _wait(0.7)
	_hide_banner()


func _on_boss_died() -> void:
	if _over:
		return
	boss_bar_visible = false
	boss_defeated.emit()


## Phase 1 of a two-form boss hit 0 HP (Blasphemy Caeser): TRANSFORM cutscene, then phase 2.
func _on_boss_transform() -> void:
	if _over or boss == null or not is_instance_valid(boss):
		return
	CombatManager.fight_active = false
	boss_bar_visible = false
	ChemicalPool.dry_all()
	_letterbox(true)
	ArenaCamera.focus = boss
	ArenaCamera.focus_zoom = 0.85
	Engine.time_scale = 0.4                         # The killing blow in slow motion
	SoundManager.play_sfx("roar", 0.0, 0.0)
	await _wait(0.35)
	Engine.time_scale = 1.0
	SoundManager.stop_music()
	SoundManager.play_sfx("rumble")
	var tb = boss.get("transform_banner")
	_show_banner(String(tb) if tb != null else "THE SERPENT SHEDS ITS SKIN", "", Color(1.0, 0.55, 0.25))
	for i in 5:
		Effects.shake(self, 6.0 + float(i) * 3.0)
		Effects.explosion(boss, boss.global_position + Vector2(randf_range(-90.0, 90.0), randf_range(-200.0, -40.0)), 70.0, true, true)
		await _wait(0.35)
	_hide_banner()
	SoundManager.play_sfx("ultimate")
	SoundManager.play_sfx("explosion")
	Effects.shake(self, 20.0)
	Effects.explosion(boss, boss.global_position + Vector2(0, -120), 220.0, true, true)
	if boss.has_method("finish_transform"):
		boss.call("finish_transform")
	await _wait(0.5)
	SoundManager.play_music(String(level.get("boss_music", "boss")))
	SoundManager.play_sfx("roar")
	_show_banner(boss.enemy_name.to_upper(), String(boss.get("phase2_subtitle")) if boss.get("phase2_subtitle") != null else "PHASE 2", Color(1.0, 0.45, 0.2))
	var line = boss.get("phase2_line")
	if line != null and String(line) != "":
		Effects.popup(boss, boss.global_position + Vector2(0, -boss.data.body_size.y - 60.0), String(line), Color(1.0, 0.8, 0.6), 20)
	await _wait(2.6)
	_hide_banner()
	if _over:
		return
	ArenaCamera.focus = null
	_letterbox(false)
	await _wait(0.5)
	boss_bar_visible = true
	SoundManager.play_sfx("count_go")
	Effects.shake(self, 12.0)
	_show_banner("FIGHT!", "", Color(1.0, 0.45, 0.3))
	CombatManager.fight_active = true
	if bool(level.get("sword_power", false)) and player is Warrior:
		(player as Warrior).set_sword_power(2, "YOUR SWORD AWAKENS!")    # Phase 2: even bigger and stronger
	await _wait(0.7)
	_hide_banner()


func _boss_death_cutscene() -> void:
	ChemicalPool.dry_all()
	_letterbox(true)
	var style := String(level.get("boss_death", "explode"))
	ArenaCamera.focus = boss
	ArenaCamera.focus_zoom = 1.2 if style == "explode" else 0.8
	await _wait(0.15)
	Engine.time_scale = 0.35                       # Slow motion
	SoundManager.play_sfx("roar", 0.0, 0.0)        # Death cry
	SoundManager.play_sfx("rumble")
	Effects.explosion(boss, boss.global_position + Vector2(0, -90), 150.0)
	Effects.shake(self, 14.0)
	await _wait(0.5)                               # ~1.4 s real time
	Engine.time_scale = 1.0
	CombatManager.fight_active = false
	SoundManager.stop_music()
	if style == "fall" or style == "sink":
		# The body stays (no K.O. animation): it lets go and FALLS away / SINKS into the magma
		var mark := Node2D.new()
		add_child(mark)
		mark.global_position = boss.global_position + Vector2(0, -120)
		ArenaCamera.focus = mark                      # Camera stays put while the body drops away
		boss.visuals.visible = true
		if boss.has_method("on_death_cutscene"):
			boss.call("on_death_cutscene")
		boss.z_index = -3                             # Behind the floor
		var drop := 1100.0 if style == "fall" else 760.0
		var tw := create_tween()
		tw.tween_property(boss, "global_position", boss.global_position + Vector2(0, drop), 2.6 if style == "fall" else 3.0) \
			.set_trans(Tween.TRANS_QUAD).set_ease(Tween.EASE_IN)
		for i in 6:
			Effects.explosion(boss, mark.global_position + Vector2(randf_range(-160.0, 160.0), randf_range(-80.0, 120.0)), 80.0, style == "sink", style == "sink")
			Effects.shake(self, 8.0)
			SoundManager.play_sfx("explosion" if i % 2 == 0 else "stone", -5.0)
			await _wait(0.42)
		if tw.is_running():
			await tw.finished
		boss.visuals.visible = false
		mark.queue_free()
		SoundManager.play_sfx("rumble", -4.0)
	var title := String(level.get("boss_death_title", "%s HAS FALLEN" % boss.enemy_name.to_upper()))
	_show_banner(title, String(level.get("boss_death_sub", "")), Color(1.0, 0.85, 0.3))
	await _wait(3.0)
	_hide_banner()
	ArenaCamera.focus = null
	_letterbox(false)
	# Full-screen ending cutscene (Blasphemy Caeser: climbing the serpent's corpse to the shrine)
	var out := String(level.get("cutscene_out", ""))
	if out != "":
		await _play_cutscene(out)


# ============================================================
# LEVEL END
# ============================================================
func _level_clear() -> void:
	CombatManager.fight_active = false
	wave_text = ""
	StoryProgress.complete_level(level_number)     # SAVED here
	if autoplay:
		print("STORY autoplay: level %d CLEAR (player hp %d, flasks %d)" % [level_number, player.hp, flasks])
	_show_banner("LEVEL CLEAR!", "Progress saved", Color(0.6, 1.0, 0.6))
	SoundManager.play_sfx("ultimate")
	await _wait(1.8)
	_hide_banner()
	# Back to the BOARD: the pawn hops forward to the next space, then (from the board)
	# you fall into the caves to the next level. After the boss: Colosseum complete.
	StoryBoard.advance_from = level_number
	if level_number < StoryProgress.AVAILABLE_LEVELS:
		StoryProgress.current_level = level_number + 1
	get_tree().change_scene_to_file(STORY_MENU)


func _on_player_died() -> void:
	if _over:
		return
	_over = true
	boss_bar_visible = false
	if autoplay:
		print("STORY autoplay: player DIED on level %d" % level_number)
	await _wait(1.6)
	CombatManager.fight_active = false
	Engine.time_scale = 1.0
	var panel := _panel()
	panel.add_child(UiStyle.label("YOU DIED", 80, Color(0.9, 0.2, 0.15), 16))
	panel.add_child(UiStyle.label("Level %d: %s" % [level_number, level.get("title", "")], 22, UiStyle.TEXT_DIM, 8))
	_panel_button(panel, "RETRY LEVEL", func() -> void: get_tree().change_scene_to_file(ARENA_SCENE))
	_panel_button(panel, "STORY MENU", func() -> void: get_tree().change_scene_to_file(STORY_MENU))
	_panel_button(panel, "MAIN MENU", func() -> void: get_tree().change_scene_to_file(CharacterRoster.MAIN_MENU))


# ============================================================
# FLASKS
# ============================================================
func _process(_delta: float) -> void:
	if Input.is_action_just_pressed("use_flask"):
		use_flask()
	elif autoplay and player != null and not player.is_dead and flasks > 0 and player.hp < player.data.max_hp * 0.4:
		use_flask()                                # Testing: the CPU drinks like a player would


func use_flask() -> void:
	if _over or not CombatManager.fight_active or player == null or player.is_dead:
		return
	if flasks <= 0:
		Effects.popup(player, player.global_position + Vector2(0, -170), "NO FLASKS LEFT", Color(0.8, 0.8, 0.8), 20)
		return
	if player.hp >= player.data.max_hp:
		Effects.popup(player, player.global_position + Vector2(0, -170), "HP IS FULL", Color(0.8, 0.8, 0.8), 20)
		return
	flasks -= 1
	SoundManager.play_sfx("flask_drink")             # Glug glug + sparkle
	player.heal(roundi(player.data.max_hp * FLASK_HEAL))
	Effects.gold_burst(player, player.global_position + Vector2(0, -64), 70.0)
	Effects.popup(player, player.global_position + Vector2(0, -200), "FLASK!  (%d LEFT)" % flasks, Color(0.5, 1.0, 0.5), 22)


# ============================================================
# UI: banner, letterbox, panels
# ============================================================
func _build_ui() -> void:
	_ui = CanvasLayer.new()
	_ui.layer = 15
	add_child(_ui)
	_bar_top = ColorRect.new()
	_bar_bottom = ColorRect.new()
	for b in [_bar_top, _bar_bottom]:
		b.color = Color(0, 0, 0)
		b.mouse_filter = Control.MOUSE_FILTER_IGNORE
		_ui.add_child(b)
	_bar_top.set_anchors_and_offsets_preset(Control.PRESET_TOP_WIDE)
	_bar_bottom.set_anchors_and_offsets_preset(Control.PRESET_BOTTOM_WIDE)
	_bar_top.offset_bottom = 0.0
	_bar_bottom.offset_top = 0.0
	var col := VBoxContainer.new()
	col.set_anchors_and_offsets_preset(Control.PRESET_FULL_RECT)
	col.alignment = BoxContainer.ALIGNMENT_CENTER
	col.mouse_filter = Control.MOUSE_FILTER_IGNORE
	_ui.add_child(col)
	_banner = UiStyle.label("", 76, UiStyle.TEXT, 18)
	_sub = UiStyle.label("", 24, UiStyle.TEXT, 8)
	_sub.autowrap_mode = TextServer.AUTOWRAP_WORD_SMART
	col.add_child(_banner)
	col.add_child(_sub)


func _show_banner(text: String, sub: String, col: Color) -> void:
	_banner.text = text
	_banner.add_theme_color_override("font_color", col)
	_sub.text = sub
	for l in [_banner, _sub]:
		l.modulate.a = 0.0
		create_tween().tween_property(l, "modulate:a", 1.0, 0.25)


func _hide_banner() -> void:
	for l in [_banner, _sub]:
		create_tween().tween_property(l, "modulate:a", 0.0, 0.25)


var _black: ColorRect


## Full-screen fade to / from black (arena change).
func _fade(to_black: bool) -> void:
	if _black == null:
		_black = ColorRect.new()
		_black.color = Color(0, 0, 0, 0)
		_black.mouse_filter = Control.MOUSE_FILTER_IGNORE
		_black.set_anchors_and_offsets_preset(Control.PRESET_FULL_RECT)
		_ui.add_child(_black)
		_ui.move_child(_black, 0)                     # Under the banner text
	if to_black:
		SoundManager.play_sfx("whoosh", -4.0)
	var tw := create_tween()
	tw.tween_property(_black, "color:a", 1.0 if to_black else 0.0, 0.6)
	await tw.finished


func _letterbox(on: bool) -> void:
	SoundManager.play_sfx("whoosh", -6.0 if on else -10.0)   # Cutscene bars slide in / out
	var h := 90.0 if on else 0.0
	var tw := create_tween().set_parallel(true)
	tw.tween_property(_bar_top, "offset_bottom", h, 0.4)
	tw.tween_property(_bar_bottom, "offset_top", -h, 0.4)


func _panel() -> VBoxContainer:
	var layer := CanvasLayer.new()
	layer.layer = 25
	add_child(layer)
	var dim := ColorRect.new()
	dim.color = Color(0, 0, 0, 0.7)
	dim.set_anchors_and_offsets_preset(Control.PRESET_FULL_RECT)
	layer.add_child(dim)
	var col := VBoxContainer.new()
	col.set_anchors_and_offsets_preset(Control.PRESET_FULL_RECT)
	col.alignment = BoxContainer.ALIGNMENT_CENTER
	col.add_theme_constant_override("separation", 14)
	layer.add_child(col)
	return col


func _panel_button(panel: VBoxContainer, text: String, action: Callable) -> void:
	var b := UiStyle.make_button(text)
	b.size_flags_horizontal = Control.SIZE_SHRINK_CENTER
	b.pressed.connect(action)
	panel.add_child(b)
	if not panel.has_meta("focused"):              # First button gets keyboard / controller focus
		panel.set_meta("focused", true)
		b.grab_focus.call_deferred()


## A wait that dies with this node (a scene change never resumes a dead coroutine).
func _wait(seconds: float) -> void:
	var t := Timer.new()
	t.one_shot = true
	t.wait_time = maxf(seconds, 0.01)
	add_child(t)
	t.start()
	await t.timeout
	t.queue_free()
