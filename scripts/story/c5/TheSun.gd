class_name TheSun
extends C5Boss
## THE SUN - FINAL BOSS (Level 50, the Sun Peak). No pre-fight: you reach the peak and she is
## there. A glowing white MOTH-LIKE GOD: four huge radiant wings with golden eye-spots, a soft
## white body, feathered antennae, a glowing crown, floating in a blinding aura of white and gold.
##
## PHASE 1 - THE SUN
##   Sky Beams       9 dmg   beams of light from the sky (one aimed right at you)
##   Light Swords    8 dmg   swords of light fall in a line that walks toward you
##   Light Pillars   8 dmg   pillars of light march outward from her, both sides
##   Wing Slash     10 dmg   the wings slash in front + two blade waves
##   Light Orbs      6 dmg   a fan of orbs
##   Radiance        7 dmg   a burst of light around her (when you get close)
##   Judgment        8 dmg   ENRAGED: swords and beams over the whole peak
## PHASE 2 - THE CONSUMER: the orange glow takes her. A bloated, burning monster: torn wings,
## a melted crown of spikes, a MAW in its chest.
##   Consume        12 dmg   lunges, maw first
##   Solar Flare    10 dmg   explodes around itself; shockwaves roll out (jump them)
##   Solar Columns  10 dmg   columns of molten light erupt under you
##   Sword Storm     8 dmg   a storm of falling swords
##   Burning Orbs    7 dmg   orange orbs rain down
## At 0 HP The Consumer does NOT die: it starts to collapse (finale_started). StoryManager runs
## the FINALE (SunFinale): throw the solar bomb into it, then escape across falling platforms
## while it explodes behind you.

signal finale_started

const WHITE := Color(1.0, 1.0, 0.97)
const PEARL := Color(0.90, 0.90, 0.86)
const GOLD := Color(1.0, 0.82, 0.35)
const GLOW := Color(1.0, 0.95, 0.75)
const ORANGE := Color(1.0, 0.5, 0.1)
const EMBER := Color(0.75, 0.18, 0.04)
const HOVER := 46.0
## NERF (2026-11-12): all her damage x this (every attack goes through dmg(), which applies it).
const DAMAGE_NERF := 0.62                               # (0.7 before 2026-11-14)

var finale := false
var _bomb_hit := 0.0
var _dash := false


func boss_forms() -> Array:
	return [
		# NERFED 2026-11-12: HP 760 -> 540 and 860 -> 620; again 2026-11-14 (user: "a big difficulty
		# spike"): 540 -> 450 and 620 -> 520 (x1.35 Story boss buff on top)
		{"name": "The Sun", "title": "THE SUN", "hp": 450, "body": Vector2(130, 250), "speed": 200.0},
		{"name": "The Consumer", "title": "THE CONSUMER", "hp": 520, "body": Vector2(190, 300), "speed": 250.0,
			"banner": "THE ORANGE GLOW SWALLOWS HER WHOLE", "subtitle": "PHASE 2  -  THE CONSUMER",
			"line": "I WILL EAT THE WORLD... AND YOU FIRST.", "music": "boss_consumer"},
	]


func setup_boss() -> void:
	keep_min = 160.0
	keep_max = 420.0
	attack_chance = 0.9
	art_scale = 1.25
	chain_chance = 0.4                                  # (0.6 before 2026-11-14: fewer combos)
	rage_at = 0.45                                      # Enrages a bit later than before (0.6)
	cooldown_mult = 1.0                                 # (0.8 before: no extra speed-up on top of the Story boss buff)
	damage_mult = DAMAGE_NERF                           # NERF: every attack of both forms hits ~38% softer
	tags = {"beams": ["anti_air", "ranged"], "swords": ["ranged"], "pillars": ["counter", "ranged"], "wing": ["close", "counter"],
		"orbs": ["ranged", "anti_air"], "radiance": ["counter"], "judgment": ["ranged"], "eclipse": ["escape", "close", "evade"],
		"halo": ["anti_air", "ranged"], "blind": ["ranged", "anti_air"],
		"consume": ["close", "ranged"], "flare": ["counter", "anti_air"], "columns": ["anti_air", "ranged"], "storm": ["ranged"],
		"burning": ["ranged"], "devour": ["close", "counter"], "supernova": ["ranged"]}
	combos = {"wing": ["radiance", "beams", "eclipse"], "beams": ["swords", "orbs", "blind"], "radiance": ["pillars", "eclipse"], "orbs": ["wing", "halo"],
		"eclipse": ["wing", "radiance"], "halo": ["beams", "eclipse"], "blind": ["swords"],
		"consume": ["flare", "consume", "devour"], "flare": ["columns", "consume"], "columns": ["storm", "devour"], "burning": ["consume"],
		"devour": ["flare"], "storm": ["consume"]}


func _make_brain() -> EnemyAI:
	var b := BossBrain.new()
	b.think_min = 0.11                                  # Still the quickest boss, a bit more human (was 0.07-0.12)
	b.think_max = 0.18
	return b


static func make_patterns() -> Array[EnemyPattern]:
	var list: Array[EnemyPattern] = []
	#                          id          name               cd    dmg  min    max     anim       tele  active rec   big   weights       armored
	list.append(EnemyPattern.make("beams", "SKY BEAMS!", 3.6, 9, 0.0, 1400.0, "raise", 0.50, 0.40, 0.40, true, [1.8, 0.0], true))
	list.append(EnemyPattern.make("swords", "LIGHT SWORDS!", 4.2, 8, 0.0, 1400.0, "raise", 0.50, 0.40, 0.45, true, [1.6, 0.0], true))
	list.append(EnemyPattern.make("pillars", "LIGHT PILLARS!", 4.8, 8, 0.0, 1400.0, "spread", 0.55, 0.40, 0.45, true, [1.4, 0.0], true))
	list.append(EnemyPattern.make("wing", "WING SLASH!", 2.4, 10, 0.0, 320.0, "wing", 0.40, 0.30, 0.45, true, [2.0, 1.4], true))
	list.append(EnemyPattern.make("orbs", "LIGHT ORBS!", 3.2, 6, 150.0, 1200.0, "spread", 0.45, 0.30, 0.40, true, [1.6, 0.0], true))
	list.append(EnemyPattern.make("radiance", "RADIANCE!", 4.0, 7, 0.0, 230.0, "spread", 0.40, 0.25, 0.45, true, [1.4, 0.0], true))
	list.append(EnemyPattern.make("judgment", "JUDGMENT!", 10.0, 8, 0.0, 1600.0, "raise", 0.70, 0.50, 0.60, true, [1.4, 0.0], true))
	list.append(EnemyPattern.make("consume", "CONSUME!", 2.6, 12, 0.0, 700.0, "consume", 0.45, 0.60, 0.50, true, [0.0, 2.0], true))
	list.append(EnemyPattern.make("flare", "SOLAR FLARE!", 4.5, 10, 0.0, 400.0, "spread", 0.55, 0.30, 0.55, true, [0.0, 1.6], true))
	list.append(EnemyPattern.make("columns", "SOLAR COLUMNS!", 4.2, 10, 0.0, 1400.0, "raise", 0.50, 0.40, 0.45, true, [0.0, 1.6], true))
	list.append(EnemyPattern.make("storm", "SWORD STORM!", 6.0, 8, 0.0, 1600.0, "raise", 0.60, 0.50, 0.55, true, [0.0, 1.3], true))
	list.append(EnemyPattern.make("burning", "BURNING ORBS!", 4.0, 7, 0.0, 1400.0, "spread", 0.50, 0.40, 0.45, true, [0.0, 1.5], true))
	# ----- harder: new moves -----
	list.append(EnemyPattern.make("eclipse", "ECLIPSE!", 4.5, 11, 0.0, 900.0, "wing", 0.30, 0.30, 0.40, true, [1.5, 1.2], true))
	list.append(EnemyPattern.make("halo", "HALO!", 5.0, 6, 0.0, 1200.0, "spread", 0.45, 0.30, 0.45, true, [1.4, 0.0], true))
	list.append(EnemyPattern.make("blind", "BLINDING LIGHT!", 6.0, 9, 0.0, 1400.0, "raise", 0.50, 1.30, 0.45, true, [1.3, 0.0], true))
	list.append(EnemyPattern.make("devour", "DEVOUR!", 5.0, 9, 0.0, 260.0, "consume", 0.40, 1.50, 0.50, true, [0.0, 1.5], true))
	list.append(EnemyPattern.make("supernova", "SUPERNOVA!", 10.0, 12, 0.0, 1600.0, "spread", 0.90, 0.60, 0.70, true, [0.0, 1.4], true))
	list[6].note = "enraged only"
	list[12].note = "she teleports behind you"
	list[13].note = "orbs at four heights, both ways"
	list[14].note = "beams of light follow you"
	list[15].note = "a grab: mash to break free"
	list[16].note = "enraged only: fire everywhere except two gaps"
	return list


func wants_pattern(p: EnemyPattern) -> bool:
	if p.id == "judgment" or p.id == "supernova":
		return raging
	return true


func flavor_lines() -> Array[String]:
	if form == 2:
		return ["HUNGRY...", "*the sound of a star collapsing*", "EVERYTHING... MINE..."]
	return ["Little moth... fly to the light.", "*a soft, endless hum*", "Look at me. LOOK."]


func on_form_changed(new_form: int) -> void:
	if new_form == 2:
		art_scale = 1.35
		keep_min = 60.0
		keep_max = 260.0
		attack_chance = 0.88


func custom_death_type(_hit: HitData) -> String:
	return DeathManager.CUTSCENE


# ============================================================
# FINALE (The Consumer at 0 HP)
# ============================================================
func take_hit(amount: int, hit: HitData) -> void:
	if finale:
		return
	if form == forms.size() and amount >= hp and amount > 0 and not _transforming:
		super.take_hit(maxi(hp - 1, 0), hit)
		_start_finale()
		return
	super.take_hit(amount, hit)


func _start_finale() -> void:
	finale = true
	_cancel_pattern()
	velocity = Vector2.ZERO
	move_dir = 0.0
	hurtbox.set_deferred("monitorable", false)
	if finale_started.get_connections().is_empty():
		die()                                          # Tests without a director: just end
	else:
		finale_started.emit()


func can_act() -> bool:
	return not finale and super.can_act()


## The bomb went off inside it (SunFinale): it bloats and burns.
func bomb_hit() -> void:
	_bomb_hit = 0.001


func _physics_process(delta: float) -> void:
	if finale:
		if _bomb_hit > 0.0:
			_bomb_hit += delta
		_update_visuals(delta)
		return
	super._physics_process(delta)


func _movement(delta: float) -> void:
	super._movement(delta)
	if form == 1 and not _dash:
		var goal := _arena_floor() - HOVER + sin(anim_time * 1.6) * 12.0
		velocity.y = (goal - global_position.y) * 4.0


func jump(_force_mult: float = 1.0) -> void:
	pass


# ============================================================
# ATTACKS
# ============================================================
func _attack(p: EnemyPattern) -> void:
	var tx := target_x()
	var f := float(facing)
	match p.id:
		"beams":
			hazard("pillar", tx, 0.6, dmg(p), Vector2(200, -460))
			for k in 4:
				hazard("pillar", tx + randf_range(-420.0, 420.0), 0.75 + 0.12 * float(k), dmg(p), Vector2(200, -460))
			SoundManager.play_sfx("holy")
		"swords":
			var from := tx - f * 520.0
			for k in 7:
				hazard("spear", from + f * float(k) * 100.0, 0.45 + 0.1 * float(k), dmg(p), Vector2(200, -420))
			SoundManager.play_sfx("holy", -2.0)
		"pillars":
			for k in 4:
				for d: float in [-1.0, 1.0]:
					hazard("pillar", global_position.x + d * (140.0 + float(k) * 160.0), 0.4 + 0.18 * float(k), dmg(p), Vector2(220, -420))
			SoundManager.play_sfx("holy")
		"wing":
			swing(dmg(p), Vector2(440, -280), Vector2(150, -150), Vector2(280, 220), "wing_slash")
			for k in 2:
				shoot("crescent", global_position + Vector2(f * 120.0, -70.0 - float(k) * 90.0), f, 620.0, 1.3, Vector2(54, 80), maxi(1, dmg(p) - 3),
					Vector2(260, -220), ORANGE if form == 2 else GOLD, "wing_wave", true)
			Effects.shake(self, 6.0)
			SoundManager.play_sfx("whoosh")
			SoundManager.play_sfx("sword_slash", -4.0)
		"orbs":
			for k in 5:
				shoot("light_orb", global_position + Vector2(f * 80.0, -40.0 - float(k) * 55.0), f, 380.0 + float(k) * 60.0, 2.8, Vector2(36, 36), dmg(p),
					Vector2(220, -200), GOLD, "light_orb")
			SoundManager.play_sfx("beam", -4.0)
		"radiance":
			hit_in_radius(global_position + Vector2(0, -130), 230.0, dmg(p), Vector2(420, -300), "radiance")
			Effects.gold_burst(self, global_position + Vector2(0, -130), 230.0)
			SoundManager.play_sfx("holy")
		"judgment":
			var l := StoryManager.arena_left() + 70.0
			var r := StoryManager.arena_right() - 70.0
			for k in 10:
				hazard("spear", lerpf(l, r, float(k) / 9.0), 0.5 + (0.35 if k % 2 == 1 else 0.0), dmg(p), Vector2(200, -420))
			for k in 3:
				hazard("pillar", tx + float(k - 1) * 260.0, 1.3 + 0.15 * float(k), dmg(p), Vector2(200, -460))
			Effects.shake(self, 10.0)
			SoundManager.play_sfx("holy")
			SoundManager.play_sfx("ultimate", -6.0)
		# ---------- THE CONSUMER ----------
		"consume":
			_dash = true
			SoundManager.play_sfx("roar", -2.0)
			SoundManager.play_sfx("dash")
		"flare":
			hit_in_radius(global_position + Vector2(0, -140), 280.0, dmg(p), Vector2(480, -360), "solar_flare")
			for d: float in [-1.0, 1.0]:
				shoot("shock", Vector2(global_position.x + d * 120.0, floor_y() - 20.0), d, 600.0, 1.1, Vector2(56, 46), maxi(1, dmg(p) - 3), Vector2(260, -340), ORANGE, "flare_wave", true)
			Effects.explosion(self, global_position + Vector2(0, -140), 260.0, true, true)
			Effects.shake(self, 16.0)
			SoundManager.play_sfx("explosion")
		"columns":
			for k in 4:
				hazard("geyser", tx + float(k - 1) * 180.0 - 90.0, 0.5 + 0.15 * float(k), dmg(p), Vector2(240, -520))
			SoundManager.play_sfx("rumble")
		"storm":
			for k in 12:
				hazard("spear", tx + randf_range(-560.0, 560.0), 0.45 + 0.07 * float(k), dmg(p), Vector2(200, -420))
			hazard("spear", tx, 0.5, dmg(p), Vector2(200, -420))
			SoundManager.play_sfx("holy")
		"burning":
			for k in 6:
				lob("light_orb", global_position + Vector2(0, -320), clamp_arena(tx + float(k - 3) * 130.0 + 65.0), 0.9 + 0.1 * float(k), dmg(p),
					Vector2(220, -220), 50.0, ORANGE, "burning_orb")
			SoundManager.play_sfx("flame")
		# ---------- harder moves ----------
		"eclipse":
			var side := 1.0 if global_position.x < tx else -1.0
			Effects.gold_burst(self, global_position + Vector2(0, -150), 120.0)
			global_position.x = clamp_arena(tx + side * 170.0, 120.0)           # Appears BEHIND you
			face_target()
			Effects.gold_burst(self, global_position + Vector2(0, -150), 120.0)
			swing(dmg(p), Vector2(460, -300), Vector2(140, -150), Vector2(260, 220), "eclipse")
			SoundManager.play_sfx("whoosh")
			SoundManager.play_sfx("sword_slash", -3.0)
		"halo":
			for d: float in [-1.0, 1.0]:
				for k in 4:
					shoot("light_orb", global_position + Vector2(d * 70.0, -30.0 - float(k) * 80.0), d, 360.0 + float(k) * 40.0, 3.0, Vector2(34, 34),
						dmg(p), Vector2(220, -200), GOLD, "halo")
			SoundManager.play_sfx("holy")
		"blind":
			_hits = 0
			Effects.gold_burst(self, global_position + Vector2(0, -170), 300.0)
			SoundManager.play_sfx("holy")
		"devour":
			_devour_start()
		"supernova":
			var l := StoryManager.arena_left() + 70.0
			var r := StoryManager.arena_right() - 70.0
			var n := int((r - l) / 120.0)
			var gap1 := randi() % n
			@warning_ignore("integer_division")
			var gap2 := (gap1 + n / 2 + randi() % 3) % n
			for k in n:
				if k == gap1 or k == gap2:
					continue                                   # The two safe spots
				hazard("geyser", l + float(k) * 120.0 + 60.0, 0.9, dmg(p), Vector2(260, -560))
			Effects.explosion(self, global_position + Vector2(0, -160), 260.0, true, true)
			Effects.shake(self, 18.0)
			SoundManager.play_sfx("explosion")
			SoundManager.play_sfx("roar")


var _hits := 0
var _victim: Fighter = null
var _bites := 0
var _bite_t := 0.0


func _devour_start() -> void:
	_victim = null
	_bites = 0
	_bite_t = 0.3
	var tgt := brain.target if brain != null else null
	if tgt == null or not is_instance_valid(tgt) or tgt.is_dead or tgt.grabbed_by != null:
		return
	var dx := (tgt.global_position.x - global_position.x) * float(facing)
	if dx < -30.0 or dx > 280.0 or absf(tgt.global_position.y - global_position.y) > 160.0:
		SoundManager.play_sfx("bite", -4.0)                  # Snapped at nothing
		return
	_victim = tgt
	grab_hold_distance = 120.0
	tgt.begin_grab(self)
	Effects.popup(tgt, tgt.global_position + Vector2(0, -180), "DEVOURED!  MASH TO ESCAPE", Color(1.0, 0.6, 0.3), 22)
	SoundManager.play_sfx("roar", -4.0)


func _on_attack_update(p: EnemyPattern, delta: float) -> void:
	if p.id == "blind":
		if _hits < 3 and state_time >= float(_hits) * 0.38:
			_hits += 1
			hazard("pillar", target_x(), 0.45, dmg(p), Vector2(200, -460))     # Follows you
		return
	if p.id == "devour":
		if _victim == null:
			state_time = maxf(state_time, state_len - 0.2)
			return
		if not is_instance_valid(_victim) or _victim.is_dead or _victim.grabbed_by != self:
			_victim = null
			state_time = state_len
			return
		_bite_t -= delta
		if _bite_t <= 0.0 and _bites < 3:
			_bite_t = 0.35
			_bites += 1
			var h := make_hit(5, Vector2.ZERO, "devour")
			h.blockable = false
			h.causes_hitstun = false
			CombatManager.apply_hit(h, _victim)
			Effects.hit_sparks(self, _victim.global_position + Vector2(0, -70), 8, 1.2)
			SoundManager.play_sfx("bite")
		elif _bites >= 3:
			_spit_out(p)
			state_time = state_len
		return
	if p.id == "consume":
		velocity.x = facing * 900.0 * (1.0 - state_time / maxf(state_len, 0.01))
		if not hitbox.active:
			swing(dmg(p), Vector2(480, -320), Vector2(120, -150), Vector2(200, 200), "consume")
		if is_on_wall() or absf(global_position.x - clamp_arena(global_position.x, 120.0)) > 1.0:
			state_time = state_len


func _spit_out(p: EnemyPattern) -> void:
	if _victim == null or not is_instance_valid(_victim):
		return
	_victim.release_grab()
	var h := make_hit(dmg(p), Vector2(facing * 700.0, -520.0), "devour")
	h.blockable = false
	h.origin = global_position
	CombatManager.apply_hit(h, _victim)
	Effects.explosion(self, _victim.global_position + Vector2(0, -60), 90.0, true, true)
	Effects.shake(self, 12.0)
	_victim = null


func _cancel_pattern() -> void:
	if _victim != null and is_instance_valid(_victim) and _victim.grabbed_by == self:
		_victim.release_grab()
	_victim = null
	super._cancel_pattern()


func _on_attack_end(p: EnemyPattern) -> void:
	if p.id == "devour" and _victim != null and is_instance_valid(_victim) and _victim.grabbed_by == self:
		_spit_out(p)
	if p.id == "consume":
		_dash = false
		velocity.x = 0.0


func _owns_velocity_x() -> bool:
	return estate == EState.ATTACK and current != null and current.id == "consume"


# ============================================================
# ART (facing right, origin = feet / the point under her)
# ============================================================
func draw_model_on(c: CanvasItem) -> void:
	var s := art_state()
	s["bomb"] = _bomb_hit
	s["finale"] = finale
	draw_sun(c, s)


static func draw_portrait(c: CanvasItem, t: float) -> void:
	draw_sun(c, {"t": t, "pose": "idle", "form": 1})


static func draw_sun(c: CanvasItem, s: Dictionary) -> void:
	var t: float = s.get("t", 0.0)
	var f: int = s.get("form", 1)
	var pose_v: String = s.get("pose", "idle")
	var dead: bool = s.get("dead", false)
	var bomb: float = s.get("bomb", 0.0)
	var consumer := f >= 2
	var body_col := ORANGE if consumer else WHITE
	var wing_col := EMBER if consumer else PEARL
	var spot := Color(1.0, 0.25, 0.05) if consumer else GOLD
	var center := Vector2(0, -170)
	# Blinding aura
	for i in 4:
		c.draw_circle(center, 220.0 - float(i) * 40.0 + sin(t * 2.0 + float(i)) * 6.0, Color(body_col.r, body_col.g * (0.9 if consumer else 1.0), body_col.b, 0.06 + 0.03 * float(i)))
	for i in 12:                                               # Rays
		var a := t * 0.3 + TAU * float(i) / 12.0
		c.draw_line(center + Vector2.from_angle(a) * 120.0, center + Vector2.from_angle(a) * (210.0 + 20.0 * sin(t * 3.0 + float(i))), Color(GLOW.r, GLOW.g * (0.6 if consumer else 1.0), GLOW.b * (0.3 if consumer else 1.0), 0.25), 4.0)
	# Four huge wings (moth): upper pair + lower pair, with eye-spots
	var flap := sin(t * (5.0 if consumer else 2.4)) * 0.12
	if pose_v == "wing":
		flap = 0.35
	for side: float in [-1.0, 1.0]:
		for k in 2:
			var upper := k == 0
			var ang := (-0.9 if upper else 0.35) + flap * side * (1.0 if upper else -1.0)
			var seg_len := 190.0 if upper else 140.0
			var root := center + Vector2(side * 10.0, -10.0 if upper else 20.0)
			var tip := root + Vector2(side * cos(ang), sin(ang)) * seg_len
			var mid := root.lerp(tip, 0.55)
			var nrm := (tip - root).orthogonal().normalized() * (70.0 if upper else 55.0)
			var wing := PackedVector2Array([root, mid + nrm, tip + nrm * 0.3, tip, tip - nrm * 0.5, mid - nrm * 0.7])
			if consumer:                                       # Torn, burning edges
				wing[2] = wing[2].lerp(root, 0.2)
				wing[4] = wing[4].lerp(root, 0.25)
			c.draw_colored_polygon(wing, wing_col)
			FighterArt.outline(c, wing, 4.0, Color(0.4, 0.3, 0.15) if not consumer else EnemyArt.BLACK)
			var eye := root.lerp(tip, 0.6)
			c.draw_circle(eye, 20.0 if upper else 14.0, spot)
			c.draw_circle(eye, 10.0 if upper else 7.0, Color(0.15, 0.08, 0.02) if not consumer else Color(1.0, 0.9, 0.5))
			for j in 3:                                        # Wing veins
				c.draw_line(root, wing[1 + j], Color(0.7, 0.6, 0.4, 0.4) if not consumer else Color(0.3, 0.05, 0.0, 0.6), 2.0)
			if consumer:
				for j in 3:
					var fp := wing[2 + j % 3]
					c.draw_colored_polygon(PackedVector2Array([fp + Vector2(-8, 0), fp + Vector2(0, -22.0 - 8.0 * sin(t * 9.0 + float(j))), fp + Vector2(8, 0)]), Color(1.0, 0.6, 0.15, 0.85))
	# Fuzzy body
	var body := EnemyArt.ellipse_points(center + Vector2(0, 30), 48.0 if not consumer else 74.0, 110.0, 24)
	c.draw_colored_polygon(body, body_col)
	for i in 6:                                                # Fur bands
		c.draw_line(center + Vector2(-40, -20.0 + float(i) * 26.0), center + Vector2(40, -14.0 + float(i) * 26.0), Color(0.85, 0.82, 0.7, 0.6) if not consumer else EMBER, 3.0)
	FighterArt.outline(c, body, 4.0)
	if consumer:                                               # The MAW in its chest
		var open := 26.0 + (20.0 if pose_v == "consume" else 0.0) + sin(t * 4.0) * 4.0
		var maw := EnemyArt.ellipse_points(center + Vector2(10, 40), 40.0, open, 18)
		c.draw_colored_polygon(maw, Color(0.15, 0.0, 0.0))
		for i in 8:
			var a := TAU * float(i) / 8.0
			var p := center + Vector2(10, 40) + Vector2(cos(a) * 40.0, sin(a) * open)
			c.draw_colored_polygon(PackedVector2Array([p, p + (center + Vector2(10, 40) - p) * 0.35 + Vector2(4, 0), p + Vector2(-4, 0)]), Color(1.0, 0.95, 0.8))
		c.draw_circle(center + Vector2(10, 40), 12.0, Color(1.0, 0.7, 0.2, 0.8))
	# Head: feathered antennae, glowing crown, serene face (melted spikes on the Consumer)
	var head := center + Vector2(4, -110)
	for sgn: float in [-1.0, 1.0]:
		var ant := PackedVector2Array([head + Vector2(sgn * 8.0, -18), head + Vector2(sgn * 30.0, -60), head + Vector2(sgn * 50.0, -80)])
		c.draw_polyline(ant, EnemyArt.BLACK, 5.0, FighterArt.AA)
		c.draw_polyline(ant, GOLD if not consumer else EMBER, 2.5, FighterArt.AA)
		for j in 5:
			var p := ant[1].lerp(ant[2], float(j) / 4.0)
			c.draw_line(p, p + Vector2(sgn * 10.0, -6.0), GOLD if not consumer else ORANGE, 2.0)
	FighterArt.ball(c, head, 26.0, body_col, body_col.darkened(0.2), Color.WHITE)
	for k in 5:                                                 # Crown
		var a := -PI * 0.5 + (float(k) - 2.0) * 0.35
		var base := head + Vector2.from_angle(a) * 22.0
		var tipc := head + Vector2.from_angle(a) * (44.0 if not consumer else 38.0 + 12.0 * sin(t * 6.0 + float(k)))
		c.draw_colored_polygon(PackedVector2Array([base + Vector2(-5, 0), tipc, base + Vector2(5, 0)]), GOLD if not consumer else Color(1.0, 0.35, 0.05))
	c.draw_circle(head + Vector2(0, -26), 6.0, Color(1, 1, 1) if not consumer else Color(1.0, 0.8, 0.3))
	if dead:
		EnemyArt.ko_eye(c, head + Vector2(8, -2), 4.0, t)
	elif consumer:
		for i in 5:                                             # Many orange eyes
			c.draw_circle(head + Vector2(-14.0 + float(i) * 8.0, -4.0 + float(i % 2) * 8.0), 3.5, Color(1.0, 0.9, 0.3))
	else:
		c.draw_circle(head + Vector2(-4, -2), 4.0, GLOW)
		c.draw_circle(head + Vector2(12, -2), 4.0, GLOW)
		c.draw_arc(head + Vector2(4, 8), 6.0, 0.3, PI - 0.3, 8, Color(0.6, 0.5, 0.3), 1.5)
	if bomb > 0.0:                                             # The bomb inside: it swells and cracks
		for i in 8:
			var a := TAU * float(i) / 8.0 + bomb
			c.draw_line(center, center + Vector2.from_angle(a) * (60.0 + bomb * 80.0), Color(1, 1, 0.8, 0.8), 4.0)
		c.draw_circle(center, 30.0 + bomb * 50.0, Color(1, 1, 0.9, minf(0.3 + bomb * 0.3, 0.9)))
