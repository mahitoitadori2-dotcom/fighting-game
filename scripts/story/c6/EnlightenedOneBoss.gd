class_name EnlightenedOneBoss
extends C5Boss
## THE ENLIGHTENED ONE - FINAL BOSS of The Enlightened Chase (Level 62, the Sky Reliquary).
## (The playable Enlightened One's look, bigger, floating, his halo blazing.) He NEVER attacks
## you himself: he backs away from you and his whole treasure hoard comes down on the arena.
## After every spell he stands still for a moment (recover ~1.1-1.5 s): that is your window.
## No pre-fight. Music: boss_enlightened (chaos - every instrument at once).
##
## ALL FIGHT LONG: random objects fall on the whole arena (shadows warn you) - vases,
## candelabras, tablets, bells, statue heads... and EXPLOSIVE barrels / holy grenades.
##   Rain of Relics      4 dmg   a burst of falling relics around you
##   Explosive Offerings 6 dmg   barrels + holy grenades drop in a row (explosions)
##   The Hoard Falls     5 dmg   everything falls, sweeping across the whole arena
##   Flee!               -       he blinks away to the far side (when you get close / corner him)
## PHASE 2 (second HP bar, "ASCENDED"): everything above, faster, plus
##   Enlightened Lasers  6 dmg   beams across the arena (low: jump it / high: stay down) + one from the sky
##   Light Balls         5 dmg   balls of light fly in from both edges of the screen

const GOLD := Color(1.0, 0.85, 0.35)
const RAIN_EVERY := [3.4, 2.4]            # Ambient falling object, per phase (seconds)

var _rain_t := 1.5
var _blinked := false


func boss_forms() -> Array:
	return [
		{"name": "The Enlightened One", "title": "THE ENLIGHTENED ONE", "hp": 180, "body": Vector2(80, 200), "speed": 200.0},
		{"name": "The Enlightened One", "title": "THE ENLIGHTENED ONE  -  ASCENDED", "hp": 210, "body": Vector2(80, 200), "speed": 230.0,
			"banner": "HE RISES INTO THE LIGHT", "subtitle": "PHASE 2  -  ASCENDED", "line": "LASERS! LIGHT! EVERYTHING!", "music": "boss_enlightened"},
	]


func setup_boss() -> void:
	keep_min = 110.0                       # He backs off a little (you can catch him)
	keep_max = 300.0
	attack_chance = 0.6
	chain_chance = 0.35
	art_scale = 1.4
	max_minions = 0
	tags = {"rain": ["ranged", "anti_air"], "offerings": ["ranged"], "hoard": ["ranged"], "flee": ["escape", "evade", "counter"],
		"lasers": ["ranged", "anti_air"], "orbs": ["ranged"]}
	combos = {"rain": ["offerings"], "flee": ["rain", "orbs"], "lasers": ["rain"], "orbs": ["rain"]}


static func make_patterns() -> Array[EnemyPattern]:
	var list: Array[EnemyPattern] = []
	#                          id           name                    cd    dmg  min   max     anim    tele  active rec   big   weights   armored
	list.append(EnemyPattern.make("rain", "RAIN OF RELICS!", 4.0, 4, 0.0, 2000.0, "cast", 0.45, 0.30, 1.10, true, [1.8, 1.5], true))
	list.append(EnemyPattern.make("offerings", "EXPLOSIVE OFFERINGS!", 6.0, 6, 0.0, 2000.0, "cast", 0.50, 0.30, 1.20, true, [1.4, 1.2], true))
	list.append(EnemyPattern.make("hoard", "THE HOARD FALLS!", 12.0, 5, 0.0, 2000.0, "cast", 0.70, 0.40, 1.50, true, [1.0, 1.0], true))
	list.append(EnemyPattern.make("flee", "FLEE!", 6.0, 0, 0.0, 200.0, "cast", 0.20, 0.20, 0.25, false, [1.6, 1.6], true))
	list.append(EnemyPattern.make("lasers", "ENLIGHTENED LASERS!", 7.0, 6, 0.0, 2000.0, "cast", 0.55, 0.40, 1.20, true, [0.0, 1.7], true))
	list.append(EnemyPattern.make("orbs", "LIGHT BALLS!", 5.5, 5, 0.0, 2000.0, "cast", 0.45, 0.40, 1.10, true, [0.0, 1.6], true))
	list[0].note = "he never attacks himself: watch the shadows"
	list[4].note = "phase 2: low beam = jump, high beam = stay down"
	list[5].note = "phase 2"
	return list


func wants_pattern(p: EnemyPattern) -> bool:
	return p.weight(form) > 0.0


func flavor_lines() -> Array[String]:
	return ["You cannot catch the Light!", "Take it! Take ALL of it!", "*laughs, far too calm*", "Everything I own is a weapon."]


# ============================================================
# THE HAZARDS
# ============================================================
func _attack(p: EnemyPattern) -> void:
	var tx := target_x()
	match p.id:
		"rain":
			var n := 4 if form == 1 else 6
			for k in n:
				var look := "relic_bomb" if randf() < 0.25 else "relic"
				_drop(look, tx + randf_range(-320.0, 320.0), 0.7 + 0.12 * float(k), dmg(p))
			SoundManager.play_sfx("holy", -4.0)
		"offerings":
			var dir := 1.0 if randf() < 0.5 else -1.0
			for k in 5:
				_drop("relic_bomb", tx + dir * (float(k) - 2.0) * 170.0, 0.8 + 0.2 * float(k), dmg(p), 85.0)
			SoundManager.play_sfx("chain", -4.0)
		"hoard":
			var from := StoryManager.wall_left_x + 100.0 if randf() < 0.5 else StoryManager.wall_right_x - 100.0
			var dir := 1.0 if from < arena_center() else -1.0
			for k in 9:
				_drop("relic_bomb" if k % 3 == 1 else "relic", from + dir * float(k) * 140.0, 0.8 + 0.14 * float(k), dmg(p))
			Effects.shake(self, 10.0)
			SoundManager.play_sfx("rumble")
		"flee":
			_blinked = false
		"lasers":
			var fy := floor_y()
			_laser(true, fy - 50.0, dmg(p), 0.9)                       # Low: jump it
			_laser(true, fy - 190.0, dmg(p), 1.7)                      # High: stay on the ground
			_laser(false, target_x(), dmg(p), 1.2)                     # From the sky, where you stand
		"orbs":
			var cam := get_viewport().get_camera_2d()
			var cx := cam.get_screen_center_position().x if cam != null else global_position.x
			var half := get_viewport_rect().size.x * 0.5 / (cam.zoom.x if cam != null else 1.0) - 40.0
			var fy := floor_y()
			for k in 4:
				var side := -1.0 if k % 2 == 0 else 1.0
				var h: float = [60.0, 150.0, 110.0, 220.0][k]
				shoot("light_orb", Vector2(cx + side * half, fy - h), -side, 380.0 + float(k) * 30.0, 4.0, Vector2(36, 36), dmg(p),
					Vector2(220, -220), GOLD, "light_ball", false)
			for k in 3:
				lob("light_orb", global_position + Vector2(0, -260), clamp_arena(target_x() + float(k - 1) * 200.0), 0.9 + 0.1 * float(k),
					dmg(p), Vector2(200, -220), 44.0, GOLD, "light_ball")
			SoundManager.play_sfx("holy")


func _on_attack_update(p: EnemyPattern, _delta: float) -> void:
	if p.id == "flee" and not _blinked and state_time >= 0.1:
		_blinked = true
		Effects.gold_burst(self, global_position + Vector2(0, -120), 110.0)
		var tx := target_x()
		var x := StoryManager.wall_right_x - 160.0 if tx < arena_center() else StoryManager.wall_left_x + 160.0
		if not StoryManager.has_walls:
			x = tx + (500.0 if tx < global_position.x else -500.0)
		global_position.x = clamp_arena(x)
		face_target()
		Effects.gold_burst(self, global_position + Vector2(0, -120), 110.0)
		SoundManager.play_sfx("whoosh")


## One falling object (shadow warning first). Explosive ones hit harder and wider.
func _drop(look: String, x: float, delay: float, damage: int, radius: float = 60.0) -> void:
	var d := spawn_projectile()
	d.kind = EnemyProjectile.Kind.DROP
	d.look = look
	d.delay = delay
	d.damage = damage + (1 if look != "relic" else 0)
	d.radius = radius + (20.0 if look != "relic" else 0.0)
	d.knockback = Vector2(240, -320)
	d.fall_height = 700.0
	d.move = "relic_rain"
	launch(d, Vector2(clamp_arena(x, 40.0), _arena_floor()))


func _laser(horizontal: bool, at: float, damage: int, warn: float) -> void:
	var l := EnlightenedFx.Laser.new()
	l.source = self
	l.horizontal = horizontal
	l.at = at
	l.damage = damage
	l.warn = warn
	l.thick = 42.0 if horizontal else 70.0
	get_parent().add_child(l)


## Ambient: something from his hoard falls somewhere near you every few seconds.
func _process(delta: float) -> void:
	super._process(delta)
	if is_dead or is_transforming() or not CombatManager.fight_active:
		return
	_rain_t -= delta
	if _rain_t <= 0.0:
		_rain_t = float(RAIN_EVERY[clampi(form - 1, 0, 1)]) * randf_range(0.8, 1.2)
		var look := "relic_bomb" if randf() < 0.2 else "relic"
		_drop(look, target_x() + randf_range(-500.0, 500.0), 1.1, 3)


func on_form_changed(_new_form: int) -> void:
	Effects.gold_burst(self, global_position + Vector2(0, -140), 220.0)


# ============================================================
# ART: the Enlightened One, floating, halo blazing (facing right, origin = feet)
# ============================================================
func draw_model_on(c: CanvasItem) -> void:
	draw_boss(c, art_state())


static func draw_portrait(c: CanvasItem, t: float) -> void:
	draw_boss(c, {"t": t, "pose": "idle", "form": 1})


static func draw_boss(c: CanvasItem, s: Dictionary) -> void:
	var t: float = s.get("t", 0.0)
	var pose: String = s.get("pose", "idle")
	var form: int = s.get("form", 1)
	var dead: bool = s.get("dead", false)
	var lift := 0.0 if dead else -18.0 - 8.0 * sin(t * 2.0) - (16.0 if form >= 2 else 0.0)
	var glow := 0.5 + 0.5 * sin(t * 3.0)
	# Aura + orbiting treasures
	c.draw_circle(Vector2(0, -70 + lift), 70.0 + 10.0 * glow, Color(1.0, 0.85, 0.35, 0.12 + (0.12 if form >= 2 else 0.0)))
	if not dead:
		for k in 4:
			var a := t * 1.2 + float(k) * TAU / 4.0
			var p := Vector2(cos(a) * 64.0, -80.0 + lift + sin(a) * 18.0)
			c.draw_set_transform(p, sin(t + float(k)), Vector2(0.5, 0.5))
			EnlightenedFx._relic(c, k, t)
			c.draw_set_transform(Vector2.ZERO, 0.0, Vector2.ONE)
	# Shadow on the floor under him
	c.draw_set_transform(Vector2(0, -2), 0.0, Vector2(1.0, 0.25))
	c.draw_circle(Vector2.ZERO, 30.0, Color(0, 0, 0, 0.3))
	c.draw_set_transform(Vector2(0, lift), 0.0, Vector2.ONE)
	var cast := 0.0
	if pose.begins_with("cast"):
		cast = 0.6 if pose.ends_with("_tele") else 1.0
	EnlightenedOneArt._draw_figure(c, {"t": t, "floor": dead, "cast": cast})
	c.draw_set_transform(Vector2.ZERO, 0.0, Vector2.ONE)
	if form >= 2 and not dead:                                         # Ascended: wings of light
		for sd: float in [-1.0, 1.0]:
			for k in 4:
				var base := Vector2(sd * 10.0, -100.0 + lift)
				var tip := base + Vector2(sd * (70.0 + float(k) * 16.0), -40.0 + float(k) * 22.0 + sin(t * 3.0 + float(k)) * 6.0)
				c.draw_line(base, tip, Color(1.0, 0.9, 0.5, 0.55 - float(k) * 0.1), 7.0 - float(k), true)
