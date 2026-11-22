class_name NightmareMusician
extends C5Boss
## MUSICIAN OF NIGHTMARES (The Hunt of a Nightmare, level 90): a BUFFER, BIGGER but NOT TALLER
## version of the Nightmare baseplate. In his FIRST PHASE he plays an ACCORDION; in his LATER phase
## he CONSTANTLY SWITCHES instruments (every few seconds).
##
## PHASE 1 - ACCORDION
##   Wheeze       7 dmg   a wave of sound rolls out of the bellows
##   Squeeze      9 dmg   slams the accordion shut on you
##   Drone        8 dmg   a held chord: red light bursts up under you
## PHASE 2 - THE WHOLE TROUPE'S BAND (switching every 5 s)
##   Violin       bow slashes fly (7) / a screech of red pillars (8)
##   Drum         booms along the floor (8) / a drumroll stomp (9)
##   Trumpet      a blast that blows you across the arena (9)
##   Cymbals      a crash that stuns (7)
##   Harp         notes fall from above (6)

const K := 1.12
const WIDE := 1.9
const SWITCH_EVERY := 5.0
const BAND := ["violin", "drum", "trumpet", "cymbals", "harp", "accordion"]
const PREFIX := {"accordion": "acc_", "violin": "vio_", "drum": "drm_", "trumpet": "tru_", "cymbals": "cym_", "harp": "hrp_"}

var instrument := "accordion"
var _switch_t := SWITCH_EVERY


func boss_forms() -> Array:
	return [
		{"name": "Musician of Nightmares", "title": "MUSICIAN OF NIGHTMARES", "hp": 320, "body": Vector2(110, 150), "speed": 200.0},
		{"name": "Musician of Nightmares", "title": "MUSICIAN OF NIGHTMARES", "hp": 340, "body": Vector2(110, 150), "speed": 230.0,
			"banner": "THE WHOLE BAND", "subtitle": "He will not stop changing the song", "line": "*every instrument starts at once*"},
	]


func setup_boss() -> void:
	keep_min = 120.0
	keep_max = 460.0
	attack_chance = 0.75
	chain_chance = 0.3
	tags = {"acc_wheeze": ["ranged"], "acc_squeeze": ["close"], "acc_drone": ["ranged", "anti_air"], "vio_slash": ["ranged"],
		"vio_screech": ["ranged"], "drm_boom": ["ranged"], "drm_roll": ["close"], "tru_blast": ["close", "ranged"],
		"cym_crash": ["close", "counter"], "hrp_notes": ["ranged", "anti_air"]}


func on_form_changed(new_form: int) -> void:
	if new_form >= 2:
		_switch_to(BAND[randi() % (BAND.size() - 1)])


static func make_patterns() -> Array[EnemyPattern]:
	var list: Array[EnemyPattern] = []
	list.append(EnemyPattern.make("acc_wheeze", "WHEEZE!", 2.4, 7, 120.0, 2000.0, "play", 0.45, 0.3, 0.45, false, [1.8], true))
	list.append(EnemyPattern.make("acc_squeeze", "SQUEEZE!", 3.0, 9, 0.0, 190.0, "squeeze", 0.5, 0.3, 0.5, true, [1.6], true))
	list.append(EnemyPattern.make("acc_drone", "DRONE!", 5.0, 8, 0.0, 2000.0, "play", 0.6, 0.5, 0.5, true, [1.2], true))
	list.append(EnemyPattern.make("vio_slash", "BOW SLASH!", 2.0, 7, 100.0, 2000.0, "play", 0.35, 0.3, 0.4, false, [1.8], true))
	list.append(EnemyPattern.make("vio_screech", "SCREECH!", 4.0, 8, 0.0, 2000.0, "play", 0.55, 0.4, 0.5, true, [1.3], true))
	list.append(EnemyPattern.make("drm_boom", "BOOM!", 2.6, 8, 0.0, 2000.0, "play", 0.45, 0.6, 0.45, true, [1.8], true))
	list.append(EnemyPattern.make("drm_roll", "DRUMROLL!", 3.4, 9, 0.0, 220.0, "squeeze", 0.5, 0.5, 0.5, true, [1.4], true))
	list.append(EnemyPattern.make("tru_blast", "FANFARE!", 3.0, 9, 0.0, 900.0, "play", 0.55, 0.4, 0.5, true, [1.8], true))
	list.append(EnemyPattern.make("cym_crash", "CRASH!", 3.2, 7, 0.0, 240.0, "play", 0.5, 0.25, 0.5, true, [1.8], true))
	list.append(EnemyPattern.make("hrp_notes", "FALLING NOTES!", 3.0, 6, 0.0, 2000.0, "play", 0.5, 0.4, 0.5, false, [1.8], true))
	return list


func wants_pattern(p: EnemyPattern) -> bool:
	return p.id.begins_with(String(PREFIX[instrument]))


func _switch_to(inst: String) -> void:
	instrument = inst
	_switch_t = SWITCH_EVERY
	Effects.popup(self, global_position + Vector2(0, -230), inst.to_upper() + "!", Color(1.0, 0.75, 0.6), 24)
	SoundManager.play_sfx("spawn", -6.0)


func _update_visuals(delta: float) -> void:
	if form >= 2 and CombatManager.fight_active and not is_dead:
		_switch_t -= delta
		if _switch_t <= 0.0 and estate != EState.ATTACK and estate != EState.TELEGRAPH:
			var nxt := instrument
			while nxt == instrument:
				nxt = String(BAND[randi() % BAND.size()])
			_switch_to(nxt)
	super._update_visuals(delta)


func _attack(p: EnemyPattern) -> void:
	face_target()
	match p.id:
		"acc_wheeze":
			shoot("crescent", global_position + Vector2(facing * 70.0, -80.0), float(facing), 460.0, 2.4, Vector2(70, 110), dmg(p), Vector2(300, -200), Color(1.0, 0.3, 0.25), "music_wheeze", true)
			SoundManager.play_sfx("whoosh", -4.0)
		"acc_squeeze":
			hit_in_radius(global_position + Vector2(facing * 40.0, -70.0), 170.0, dmg(p), Vector2(facing * 420.0, -260.0), "music_squeeze")
			Effects.shake(self, 8.0)
			SoundManager.play_sfx("slam", -4.0)
		"acc_drone":
			for i in 3:
				hazard("hellfire", target_x() + float(i - 1) * 170.0, 0.6 + float(i) * 0.15, dmg(p))
			SoundManager.play_sfx("rumble", -4.0)
		"vio_slash":
			for i in 2:
				shoot("crescent", global_position + Vector2(facing * 60.0, -110.0 + float(i) * 60.0), float(facing), 640.0 - float(i) * 120.0, 1.8, Vector2(50, 70), dmg(p), Vector2(240, -180), Color(1.0, 0.85, 0.7), "music_violin")
			SoundManager.play_sfx("sword_slash", -4.0)
		"vio_screech":
			var x0 := target_x()
			for i in 4:
				hazard("hellfire", x0 + float(i) * 140.0 * float(facing) - 140.0 * float(facing), 0.4 + float(i) * 0.18, dmg(p))
			SoundManager.play_sfx("flame", -2.0)
		"drm_boom":
			for i in 5:
				hazard("rock", global_position.x + float(facing) * (140.0 + float(i) * 130.0), 0.25 + float(i) * 0.15, dmg(p))
			Effects.shake(self, 6.0)
			SoundManager.play_sfx("slam", -2.0)
		"drm_roll":
			hit_in_radius(global_position + Vector2(0, -40), 220.0, dmg(p), Vector2(300, -380), "music_drumroll")
			Effects.shake(self, 10.0)
			SoundManager.play_sfx("slam")
		"tru_blast":
			var w := shoot("wind", global_position + Vector2(facing * 80.0, -110.0), float(facing), 900.0, 0.9, Vector2(160, 120), dmg(p), Vector2(900, -260), Color(1.0, 0.45, 0.35), "music_trumpet", true)
			w.scale = Vector2(1.4, 1.4)
			SoundManager.play_sfx("roar", -6.0)
		"cym_crash":
			hit_in_radius(global_position + Vector2(0, -90), 230.0, dmg(p), Vector2(260, -220), "music_cymbals")
			stun_in_radius(global_position + Vector2(0, -90), 230.0, 0.8)
			Effects.hit_sparks(self, global_position + Vector2(0, -120), 14, 1.4)
			SoundManager.play_sfx("block")
		"hrp_notes":
			for i in 6:
				lob("light_orb", global_position + Vector2(0, -200), target_x() + float(i - 3) * 90.0 + randf_range(-20.0, 20.0), 0.8 + float(i) * 0.1, dmg(p), Vector2(180, -200), 40.0, Color(1.0, 0.4, 0.35), "music_harp")
			SoundManager.play_sfx("holy", -6.0)


func draw_model_on(c: CanvasItem) -> void:
	var s := art_state()
	s["instrument"] = instrument
	draw_musician(c, s)


static func draw_portrait(c: CanvasItem, t: float) -> void:
	draw_musician(c, {"t": t, "instrument": "accordion"})


static func draw_musician(c: CanvasItem, s: Dictionary) -> void:
	var t: float = s.get("t", 0.0)
	var inst: String = s.get("instrument", "accordion")
	var pose_v: String = s.get("pose", "idle")
	var play := 1.0 if pose_v in ["play", "squeeze"] else 0.0
	var pts := HuntArt.body(c, s, {"k": K, "wide": WIDE, "leg": 9.0, "mask": "hexagon", "arm_f": 0.5 + 0.3 * play, "arm_b": 0.45,
		"cloak": Color(0.36, 0.02, 0.06)})
	HuntArt.instrument(c, inst, pts, K * 1.2, t, play)
