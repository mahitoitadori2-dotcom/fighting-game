class_name ArenaManager
extends Node2D
## Put ONE of these in every arena scene. On start it spawns:
##   P1 = YOUR character (keyboard)      at p1_spawn
##   P2 = the OPPONENT (CPU) or the Dummy at p2_spawn
## The arenas (2 Versus arenas + every Story Mode map) are listed in MapCatalog.entries().

## Survives scene changes (static). An id from MapCatalog ("test", "void", "story_<map>").
static var selected_arena := "test"
## AI vs AI: set true and P1 is also driven by its character's AI.
static var p1_cpu := false

@export var p1_spawn := Vector2(426, 520)
@export var p2_spawn := Vector2(726, 520)

var p1: Fighter
var p2: Fighter


static func arena_entry(id: String) -> Dictionary:
	return MapCatalog.entry(id)


static func selected_arena_entry() -> Dictionary:
	return arena_entry(selected_arena)


func _ready() -> void:
	add_to_group("arena_manager")
	OptimizationManager.clear_pools()        # New match: drop the last match's pools + particle bookkeeping
	if not Replay.pending.is_empty():
		_play_replay()                        # WATCH REPLAY: puppets instead of a match
		return
	if NetLink.is_guest():                    # ONLINE GUEST: the host runs the fight, this only shows it
		add_to_group("net_world")
		var ng := NetGuest.new()
		ng.name = "NetGuest"
		add_child(ng)
		if MatchSettings.touch_enabled():
			var tcg := TouchControls.new()
			tcg.name = "TouchControls"
			add_child(tcg)
		SoundManager.play_music("fight")
		return
	if NetLink.is_host() and NetLink.mode == "versus":
		p1_cpu = false
		CharacterRoster.opponent_id = NetLink.guest_fighter      # P2 = the guest's pick, the guest's buttons
	QoL.save_picks()
	SecretCodes.load_codes()
	var p1_entry := CharacterRoster.selected()
	var p1_id := CharacterRoster.selected_id
	if SecretCodes.rotor_mode and not p1_cpu:      # SECRET CODE R0t0rMode: you can ONLY be Rotor
		p1_entry = CharacterRoster.get_entry("rotor")
		p1_id = "rotor"
	p1 = _spawn(p1_entry, 1, p1_spawn)
	p2 = _spawn(CharacterRoster.opponent(), 2, p2_spawn)
	if not p1_cpu:
		Daily.apply_palette(p1)                              # SHOP palette on your fighter
	# REPLAYS: every fight is recorded (watch / save it from the winner screen)
	var rec := ReplayRecorder.new()
	rec.name = "ReplayRecorder"
	add_child(rec)
	rec.track(p1, p1_id)
	rec.track(p2, CharacterRoster.opponent_id if CharacterRoster.has_opponent() else CharacterRoster.DUMMY_ID)
	# Music: boss track vs PvE enemies, fight track otherwise (speeds up when you're low on HP)
	# (Fights-mode bosses each have their own track: boss_minos / boss_sisyphus / boss_geyron)
	var opp := CharacterRoster.opponent()
	SoundManager.play_music(String(opp.get("music", "boss")) if opp.get("enemy", false) else "fight")
	SoundManager.play_sfx("spawn")
	# Lives, "ROUND 1 - FIGHT", winner screen
	var mm := MatchManager.new()
	mm.name = "MatchManager"
	add_child(mm)
	mm.setup(p1, p2)
	# Mobile: on-screen joystick + buttons (Match Settings > Touch Controls: AUTO / ON / OFF)
	if MatchSettings.touch_enabled():
		var tc := TouchControls.new()
		tc.name = "TouchControls"
		add_child(tc)
	# TRAINING MODE: every Dummy fight gets the training panel + keys (F1-F6)
	if p2 is Dummy and p1 != null:
		var tm := TrainingMode.new()
		tm.name = "TrainingMode"
		add_child(tm)
		tm.bind(p1, p2 as Dummy)
	# SETTINGS > FPS Counter
	if MatchSettings.fps_counter_active():
		var fps := FpsCounter.new()
		fps.name = "FpsCounter"
		add_child(fps)
	if NetLink.is_host() and NetLink.mode == "versus":           # ONLINE: stream this fight to the guest
		add_to_group("net_world")
		var nh := NetHost.new()
		nh.name = "NetHost"
		nh.start_msg = {"k": "start", "kind": "versus", "scene": get_tree().current_scene.scene_file_path if get_tree().current_scene else "res://Main.tscn",
			"arena": selected_arena, "p1": CharacterRoster.selected_id, "p2": CharacterRoster.opponent_id}
		add_child(nh)
	# WEAPON PICKUPS (2026-11-23): medieval weapons drop into the arena (not vs the training Dummy)
	if MatchSettings.weapon_drops and not p2 is Dummy:
		var wd := WeaponDrops.new()
		wd.name = "WeaponDrops"
		add_child(wd)


## Spawns puppet copies of the recorded fighters and a ReplayPlayer that drives them.
func _play_replay() -> void:
	var data := Replay.pending
	var ids: Array = data.get("ids", [])
	var puppets: Array[Fighter] = []
	for i in ids.size():
		var e := CharacterRoster.get_entry(String(ids[i]))
		var f := _spawn(e, i + 1, p1_spawn if i == 0 else p2_spawn)
		if f != null:
			puppets.append(f)
	p1 = puppets[0] if puppets.size() > 0 else null
	p2 = puppets[1] if puppets.size() > 1 else null
	var rp := ReplayPlayer.new()
	rp.name = "ReplayPlayer"
	rp.return_scene = String(data.get("return_scene", CharacterRoster.MAIN_MENU))
	add_child(rp)
	rp.setup(data, puppets)
	SoundManager.play_music("menu")


func _spawn(entry: Dictionary, slot: int, pos: Vector2) -> Fighter:
	var script: Script = entry.get("fighter", Dummy)
	var f := script.new() as Fighter
	if f == null:
		push_error("ArenaManager: '%s' is not a Fighter script" % entry.get("id", "?"))
		return null
	f.name = "P%d_%s" % [slot, entry.get("short", "Fighter")]
	f.position = pos
	f.slot = slot
	f.team = slot                     # 1v1: each side is its own team (helpers join their owner's team)
	f.default_facing = 1 if slot == 1 else -1
	f.facing = f.default_facing
	if f is ControlledFighter:
		# P1 = you on the keyboard, P2 = CPU (that character's own AI brain).
		var cpu := slot == 2 or p1_cpu
		if slot == 2 and NetLink.is_host() and NetLink.mode == "versus":
			(f as ControlledFighter).ctl = NetLink.net_input          # ONLINE: the guest plays P2
		elif cpu:
			var ai_script: Script = entry.get("ai", BaseAI)
			(f as ControlledFighter).ctl = ai_script.new()
		else:
			(f as ControlledFighter).ctl = FighterInput.new()
	add_child(f)
	if slot == 1 and f is BaseEnemy and not p1_cpu and Replay.pending.is_empty():
		(f as BaseEnemy).brain = PlayerEnemyBrain.new()   # Rotor Mode: YOUR controls drive his moves
	if entry.has("versus_hp"):                    # Story enemies: their Versus HP
		f.data.max_hp = int(entry["versus_hp"])
		f.hp = f.data.max_hp
		f.health_changed.emit(f.hp, f.data.max_hp)
	if entry.has("hp_mult") and f is BaseEnemy:   # Story bosses: scaled HP on EVERY form (finish_transform reads boss_hp_mult)
		var be := f as BaseEnemy
		be.boss_hp_mult = float(entry["hp_mult"])
		be.data.max_hp = roundi(float(be.data.max_hp) * be.boss_hp_mult)
		be.hp = be.data.max_hp
		be.health_changed.emit(be.hp, be.data.max_hp)
	if entry.has("dmg_mult") and f is BaseEnemy:  # Story enemies / bosses: softer hits for a 1-v-1
		(f as BaseEnemy).damage_mult *= float(entry["dmg_mult"])
	return f
