class_name FightBoss
extends SimpleEnemy
## Base for the big FIGHTS-MODE BOSSES (King Minos, Sisyphus, Geyron). Same enemy system
## as every other enemy (BaseEnemy + EnemyPattern + EnemyAI + EnemyHUD), plus:
##   - VOICE LINES: intro (during the 3-2-1 countdown), on some attacks, on rage, on death.
##     SoundManager.say(): a recording in res://audio/voice/<key>.ogg if you add one,
##     otherwise text-to-speech with a deep voice. The line is also shown as big text.
##   - Boss names of attacks BIG on screen (Effects.announce) + a warning sound.
##   - Its own boss MUSIC track, heavy knockback resistance, a roar at phase 2.
## Subclasses fill the voice arrays in _make_data() and write the patterns + art.

var voice_id := ""                         # Recording prefix: "minos" -> audio/voice/minos_intro.ogg
var voice_pitch := 0.6
var voice_rate := 0.92
var intro_lines: Array[String] = []
var attack_lines := {}                     # pattern id -> line
var rage_line := ""
var rage_title := "ENRAGED!"               # Big text when phase 2 starts
var death_line := ""
var roar_sfx := "roar"                     # Played on intro / rage when there is no voice line
var accent := Color(1.0, 0.85, 0.4)

var _voice_cd := 0.0                       # No voice spam: at most one attack line every few s


func _ready() -> void:
	super._ready()
	knockback_scale = 0.45


func _on_respawn() -> void:
	super._on_respawn()
	knockback_scale = 0.45


## Called by MatchManager during the countdown.
func play_intro() -> void:
	if not intro_lines.is_empty():
		speak("intro", intro_lines[randi() % intro_lines.size()])
	else:
		SoundManager.play_sfx(roar_sfx)
		Effects.shake(self, 10.0)


## Voice line: sound (recording / TTS) + the words above the boss.
func speak(key: String, line: String) -> void:
	if line == "":
		return
	SoundManager.say(voice_id + "_" + key if voice_id != "" else "", line, voice_pitch, voice_rate)
	Effects.popup(self, global_position + Vector2(0, -data.body_size.y - 90.0), line.to_upper(), accent, 26)
	_voice_cd = 4.0


func _physics_process(delta: float) -> void:
	_voice_cd = maxf(_voice_cd - delta, 0.0)
	super._physics_process(delta)


# ============================================================
# BaseEnemy hooks
# ============================================================
func _on_telegraph(p: EnemyPattern) -> void:
	super._on_telegraph(p)
	if p.big:
		Effects.announce(self, p.display_name, accent, 2)          # BIG attack name on screen (BaseEnemy beeps)
	if attack_lines.has(p.id) and _voice_cd <= 0.0 and randf() < 0.6:
		speak(p.id, String(attack_lines[p.id]))


func _on_phase_changed(_new_phase: int) -> void:
	SoundManager.play_sfx(roar_sfx)
	Effects.shake(self, 14.0)
	Effects.announce(self, rage_title, Color(1.0, 0.25, 0.2), 2)
	if rage_line != "":
		speak("rage", rage_line)


func _on_death() -> void:
	super._on_death()
	if death_line != "":
		speak("death", death_line)
	else:
		SoundManager.play_sfx(roar_sfx, 2.0)


func custom_death_type(_hit: HitData) -> String:
	return DeathManager.IMPLODE


# ============================================================
# HELPERS for the bosses
# ============================================================
## Floor point under x (or the boss' own floor height).
func floor_at(x: float) -> Vector2:
	var g: Variant = Effects.ground_below(self, Vector2(x, global_position.y - 60.0), 400.0)
	return g if g != null else Vector2(x, global_position.y)


## Ground hazard (pillar / serpent / spear / rock / chain) at world x.
func hazard(kind: String, x: float, delay: float, damage: int, kb: Vector2 = Vector2(220, -420)) -> void:
	BossHazard.spawn(self, kind, floor_at(clamp_to_ground(x, 30.0)), delay, damage, kb)


## Armored dash: call from _on_attack_update. Stops at walls / ledges.
func dash_step(spd: float) -> void:
	velocity.x = facing * spd
	if is_on_wall() or not ground_ahead(70.0):
		velocity.x = 0.0
		state_time = state_len
