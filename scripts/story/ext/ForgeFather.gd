class_name ForgeFather
extends C5Boss
## THE FORGE FATHER - final boss of the Forge Mother extension (FM4, the Heart of the Forge).
## A far stronger Forge Mother: a HUGE forge titan in COAL ARMOR, molten metal glowing through
## the cracks, a furnace for a face, chimneys on its back and a giant forge hammer.
##
## PHASE 1 - THE FORGE FATHER
##   Forge Hammer      9 dmg   slams the hammer down: shockwaves both ways
##   Forge Fire Wave   7 dmg   a wave of fire rolls along the floor (both ways)
##   Coal Throw        5 dmg   hurls burning coal: fire pools where it lands
## PHASE 2 - THE METALLIC ABOMINATION (at 0 HP he melts himself into the other metals:
##   a NEW full HP bar, liquid metal body, much faster and more aggressive)
##   Metal Lash        6 dmg   a whip of liquid metal
##   Liquid Lunge      8 dmg   pours itself forward at you
##   Metal Spikes      7 dmg   spikes of metal erupt from the floor around you
##   Molten Blast      8 dmg   a blob of molten metal: fire pool where it hits

const COAL := Color(0.14, 0.12, 0.12)
const COAL_HI := Color(0.28, 0.25, 0.24)
const MOLTEN := Color(1.0, 0.50, 0.12)
const MOLTEN_HI := Color(1.0, 0.85, 0.40)
const STEEL := Color(0.72, 0.74, 0.80)
const STEEL_SHADE := Color(0.45, 0.47, 0.54)


func boss_forms() -> Array:
	return [
		{"name": "The Forge Father", "title": "THE FORGE FATHER", "hp": 380, "body": Vector2(170, 310), "speed": 100.0},
		{"name": "Metallic Abomination", "title": "THE METALLIC ABOMINATION", "hp": 340, "body": Vector2(150, 240), "speed": 270.0,
			"banner": "HE MELTS HIMSELF INTO THE METAL...", "subtitle": "PHASE 2  -  THE METALLIC ABOMINATION",
			"line": "MORE...  METAL...  MORE...", "music": ""},
	]


func setup_boss() -> void:
	keep_min = 40.0
	keep_max = 300.0
	attack_chance = 0.75
	chain_chance = 0.4
	tags = {"hammer": ["close", "counter"], "fire_wave": ["counter", "anti_air"], "coal": ["ranged"],
		"lash": ["close"], "lunge": ["ranged"], "spikes": ["anti_air", "ranged"], "molten": ["ranged"]}
	combos = {"hammer": ["fire_wave", "coal"], "coal": ["hammer"], "lash": ["lunge", "spikes"], "lunge": ["lash"], "spikes": ["molten"], "molten": ["lunge"]}


static func make_patterns() -> Array[EnemyPattern]:
	var list: Array[EnemyPattern] = []
	#                          id           name                 cd    dmg  min    max     anim      tele  active rec   big   weights [P1, P2]
	list.append(EnemyPattern.make("hammer", "FORGE HAMMER!", 3.0, 9, 0.0, 280.0, "hammer", 0.65, 0.25, 0.55, true, [2.2, 0.0], true))
	list.append(EnemyPattern.make("fire_wave", "FORGE FIRE WAVE!", 5.0, 7, 0.0, 1200.0, "wave", 0.55, 0.3, 0.5, true, [1.6, 0.0], true))
	list.append(EnemyPattern.make("coal", "COAL THROW!", 4.0, 5, 120.0, 1000.0, "throw", 0.5, 0.3, 0.45, true, [1.6, 0.0], true))
	list.append(EnemyPattern.make("lash", "METAL LASH!", 1.4, 6, 0.0, 230.0, "lash", 0.25, 0.2, 0.3, true, [0.0, 2.2]))
	list.append(EnemyPattern.make("lunge", "LIQUID LUNGE!", 2.6, 8, 160.0, 600.0, "lunge", 0.35, 0.45, 0.35, true, [0.0, 1.8], true))
	list.append(EnemyPattern.make("spikes", "METAL SPIKES!", 3.6, 7, 0.0, 1200.0, "spikes", 0.45, 0.4, 0.4, true, [0.0, 1.6]))
	list.append(EnemyPattern.make("molten", "MOLTEN BLAST!", 3.0, 8, 150.0, 1000.0, "throw", 0.35, 0.25, 0.35, true, [0.0, 1.5]))
	list[0].note = "phase 1: shockwaves, jump them"
	list[2].note = "phase 1: fire pools"
	list[3].note = "phase 2 (Metallic Abomination)"
	list[5].note = "phase 2: spikes erupt around you"
	return list


func flavor_lines() -> Array[String]:
	if form == 2:
		return ["*liquid metal bubbles*", "MORE... METAL...", "*hissing steel*"]
	return ["THE MOTHER... WAS WEAK.", "*the furnace roars*", "I AM THE FORGE."]


func on_form_changed(_new_form: int) -> void:
	art_scale = 1.0
	Effects.explosion(self, global_position + Vector2(0, -120), 180.0, true, true)


func _attack(p: EnemyPattern) -> void:
	match p.id:
		"hammer":
			hit_in_radius(global_position + Vector2(facing * 140.0, -30.0), 150.0, dmg(p), Vector2(380, -360), "forge_hammer")
			for d: float in [-1.0, 1.0]:
				shoot("shock", Vector2(global_position.x + facing * 140.0 + d * 60.0, floor_y() - 20.0), d, 540.0, 1.0, Vector2(54, 42), dmg(p) - 3, Vector2(260, -320), MOLTEN, "hammer_wave", true)
			Effects.shake(self, 16.0)
			Effects.hit_sparks(self, global_position + Vector2(facing * 140.0, -10.0), 16, 1.6)
			SoundManager.play_sfx("slam")
		"fire_wave":
			for d: float in [-1.0, 1.0]:
				shoot("lava_wave", Vector2(global_position.x + d * 110.0, floor_y() - 26.0), d, 460.0, 1.8, Vector2(80, 60), dmg(p), Vector2(260, -360), MOLTEN, "forge_fire_wave", true)
			SoundManager.play_sfx("flame")
		"coal":
			var tx := target_x()
			for k in (4 if raging else 3):
				lob("magma", global_position + Vector2(facing * 50.0, -260.0), clamp_arena(tx + float(k - 1) * 130.0), 0.7 + 0.12 * float(k), dmg(p), Vector2(180, -180), 46.0,
					COAL, "forge_coal", _fire_pool)
			SoundManager.play_sfx("swing")
		"lash":
			swing(dmg(p), Vector2(320, -220), Vector2(120, -90), Vector2(200, 90), "metal_lash")
			SoundManager.play_sfx("sword_slash", -2.0)
		"lunge":
			swing(dmg(p), Vector2(380, -260), Vector2(60, -80), Vector2(150, 150), "liquid_lunge")
			SoundManager.play_sfx("dash")
		"spikes":
			var tx2 := target_x()
			for k in (5 if raging else 4):
				hazard("geyser", tx2 + float(k) * 110.0 - 165.0 + randf_range(-15.0, 15.0), 0.45 + float(k) * 0.08, dmg(p), Vector2(160, -460))
			SoundManager.play_sfx("stone")
		"molten":
			shoot("fireball", global_position + Vector2(facing * 80.0, -120.0), float(facing), 620.0, 1.6, Vector2(56, 56), dmg(p), Vector2(300, -240), STEEL, "molten_blast", false)
			var g: Variant = Effects.ground_below(self, Vector2(clamp_arena(target_x()), global_position.y - 40.0), 300.0)
			if g != null:
				ChemicalPool.spawn_lava(self, g as Vector2, 110.0, 3.0)
			SoundManager.play_sfx("flame", -2.0)


func _fire_pool(pos: Vector2) -> void:
	var g: Variant = Effects.ground_below(self, pos + Vector2(0, -30), 200.0)
	if g != null:
		ChemicalPool.spawn_lava(self, g as Vector2, 100.0, 3.0)


func _on_attack_update(p: EnemyPattern, _delta: float) -> void:
	if p.id == "lunge":
		velocity.x = facing * 900.0
		if is_on_wall() or not ground_ahead(70.0):
			velocity.x = 0.0
			state_time = state_len


func _owns_velocity_x() -> bool:
	return estate == EState.ATTACK and current != null and current.id == "lunge"


# ============================================================
# ART (facing right, origin = feet)
# ============================================================
func draw_model_on(c: CanvasItem) -> void:
	var s := art_state()
	if form == 2:
		draw_abomination(c, s)
	else:
		draw_father(c, s)


static func draw_portrait(c: CanvasItem, t: float) -> void:
	draw_father(c, {"t": t, "pose": "idle"})


## PHASE 1: the forge titan in coal armor.
static func draw_father(c: CanvasItem, s: Dictionary) -> void:
	var t: float = s.get("t", 0.0)
	var pose: String = s.get("pose", "idle")
	var dead: bool = s.get("dead", false)
	var rage: bool = s.get("raging", false)
	var tf: float = s.get("tf", -1.0)
	var heat := 0.65 + 0.35 * sin(t * (9.0 if rage else 3.5))
	var molten := Color(MOLTEN.r, MOLTEN.g, MOLTEN.b, heat)
	if tf >= 0.0:                                       # Melting during the transform
		molten = MOLTEN_HI
	c.draw_circle(Vector2(0, -170), 160.0, Color(MOLTEN.r, MOLTEN.g, MOLTEN.b, 0.06 + 0.05 * heat))
	# Chimneys on the back, smoking
	for k in 2:
		var cx := -70.0 + float(k) * 30.0
		FighterArt.rrect(c, Rect2(cx - 12, -370 - float(k) * 20.0, 24, 80), COAL_HI, COAL, COAL_HI.lightened(0.1), 4.0, 3.5)
		for j in 3:
			var u := fmod(t * 0.6 + float(j) * 0.33 + float(k) * 0.2, 1.0)
			c.draw_circle(Vector2(cx + sin(t + float(j)) * 10.0, -380.0 - float(k) * 20.0 - u * 70.0), 10.0 + u * 14.0, Color(0.3, 0.3, 0.3, 0.4 * (1.0 - u)))
	# Legs: coal-armored pillars
	for i in 2:
		var x := -48.0 if i == 0 else 38.0
		FighterArt.rrect(c, Rect2(x - 26, -126, 52, 124), COAL if i == 0 else COAL_HI, COAL.darkened(0.3), COAL_HI.lightened(0.1), 8.0, 4.5)
		c.draw_line(Vector2(x - 10, -110), Vector2(x + 6, -60), molten, 4.0)
	# Far arm
	var lh := Vector2(-110, -130)
	var rh := Vector2(110, -150)
	match pose:
		"hammer_tele":
			rh = Vector2(40, -400)
		"hammer":
			rh = Vector2(170, -40)
		"wave_tele", "wave":
			lh = Vector2(-130, -40)
			rh = Vector2(140, -40)
		"throw_tele":
			rh = Vector2(-40, -300)
		"throw":
			rh = Vector2(150, -260)
	FighterArt.limb(c, Vector2(-84, -280), lh, 36.0, COAL, COAL.darkened(0.3), COAL_HI)
	FighterArt.ball(c, lh, 26.0, COAL, COAL.darkened(0.3), COAL_HI)
	# Torso: coal plates, molten cracks
	var torso := PackedVector2Array([Vector2(-100, -300), Vector2(104, -304), Vector2(86, -124), Vector2(-84, -122)])
	c.draw_colored_polygon(torso, COAL_HI)
	for k in 6:                                          # Coal armor plates
		var px := -80.0 + float(k % 3) * 60.0
		var py := -290.0 + float(k / 3) * 80.0
		var plate := PackedVector2Array([Vector2(px, py), Vector2(px + 52, py + 4), Vector2(px + 46, py + 70), Vector2(px + 4, py + 66)])
		c.draw_colored_polygon(plate, COAL)
	c.draw_polyline(PackedVector2Array([Vector2(-60, -296), Vector2(-40, -240), Vector2(-56, -190), Vector2(-30, -130)]), molten, 5.0)
	c.draw_polyline(PackedVector2Array([Vector2(40, -300), Vector2(24, -230), Vector2(50, -170), Vector2(30, -126)]), molten, 5.0)
	c.draw_polyline(PackedVector2Array([Vector2(-20, -220), Vector2(20, -210), Vector2(60, -220)]), molten, 4.0)
	FighterArt.outline(c, torso, 5.0)
	# Head: a furnace with a glowing grate for a face
	var head := Vector2(10, -340)
	FighterArt.rrect(c, Rect2(head.x - 44, head.y - 40, 88, 76), COAL, COAL.darkened(0.3), COAL_HI, 10.0, 4.5)
	c.draw_rect(Rect2(head.x - 30, head.y - 16, 60, 34), Color(0.05, 0.03, 0.02))
	if dead:
		EnemyArt.ko_eye(c, head + Vector2(-10, 0), 6.0, t)
		EnemyArt.ko_eye(c, head + Vector2(14, 0), 6.0, t)
	else:
		c.draw_rect(Rect2(head.x - 26, head.y - 12, 52, 26), Color(MOLTEN.r, MOLTEN.g * heat, MOLTEN.b, 1.0))
		for k in 4:
			c.draw_line(Vector2(head.x - 24 + float(k) * 16.0, head.y - 14), Vector2(head.x - 24 + float(k) * 16.0, head.y + 16), COAL, 4.0)
	# Front arm + the GIANT FORGE HAMMER
	FighterArt.limb(c, Vector2(88, -284), rh, 40.0, COAL_HI, COAL, COAL_HI.lightened(0.1))
	FighterArt.ball(c, rh, 26.0, COAL_HI, COAL, COAL_HI.lightened(0.1))
	var aim := Vector2(0.4, -1).normalized()
	if pose == "hammer":
		aim = Vector2(1, 0.3).normalized()
	elif pose == "hammer_tele":
		aim = Vector2(-0.6, -1).normalized()
	var top := rh + aim * 120.0
	c.draw_line(rh, top, EnemyArt.BLACK, 16.0, FighterArt.AA)
	c.draw_line(rh, top, Color(0.35, 0.25, 0.18), 10.0, FighterArt.AA)
	var n := aim.orthogonal()
	var hd := PackedVector2Array([top + n * 50.0 - aim * 26.0, top + n * 50.0 + aim * 30.0, top - n * 50.0 + aim * 30.0, top - n * 50.0 - aim * 26.0])
	c.draw_colored_polygon(hd, STEEL_SHADE)
	c.draw_line(top + n * 46.0, top - n * 46.0, molten, 6.0)
	FighterArt.outline(c, hd, 4.5)


## PHASE 2: the Metallic Abomination - a body of liquid metal, spikes, dripping.
static func draw_abomination(c: CanvasItem, s: Dictionary) -> void:
	var t: float = s.get("t", 0.0)
	var pose: String = s.get("pose", "idle")
	var dead: bool = s.get("dead", false)
	var rage: bool = s.get("raging", false)
	var wob := sin(t * (12.0 if rage else 6.0))
	c.draw_circle(Vector2(0, -120), 140.0, Color(MOLTEN.r, MOLTEN.g, MOLTEN.b, 0.08))
	# Puddle base: it flows instead of walking
	var base := EnemyArt.ellipse_points(Vector2(0, -12), 90.0 + wob * 6.0, 18.0, 20)
	c.draw_colored_polygon(base, STEEL_SHADE)
	FighterArt.outline(c, base, 4.0)
	# Body: a melting mass, wider at the bottom
	var lean := 22.0 if pose == "lunge" else (-14.0 if pose.ends_with("_tele") else 0.0)
	var body := PackedVector2Array()
	for i in 14:
		var a := PI + float(i) / 13.0 * PI
		var r := 92.0 + sin(t * 5.0 + float(i) * 1.7) * 7.0
		body.append(Vector2(lean * (1.0 - sin(a) * -1.0) * 0.5, -120) + Vector2(cos(a) * r * 0.8, sin(a) * r * 1.25))
	body.append(Vector2(70, -16))
	body.append(Vector2(-70, -16))
	c.draw_colored_polygon(body, STEEL)
	c.draw_colored_polygon(EnemyArt.ellipse_points(Vector2(-26 + lean * 0.3, -150), 26.0, 60.0, 14), STEEL_SHADE)
	for k in 5:                                          # Molten veins + drips
		var x := -50.0 + float(k) * 24.0
		var drip := fmod(t * 0.8 + float(k) * 0.37, 1.0)
		c.draw_line(Vector2(x + lean * 0.4, -200), Vector2(x + lean * 0.2, -60), Color(MOLTEN.r, MOLTEN.g, MOLTEN.b, 0.7), 3.0)
		c.draw_circle(Vector2(x, -60 + drip * 40.0), 4.0, MOLTEN)
	FighterArt.outline(c, body, 4.5)
	# Spikes jutting out of the back and shoulders
	for k in 5:
		var a := PI * 1.15 + float(k) * 0.28
		var root := Vector2(lean * 0.5, -130) + Vector2.from_angle(a) * 80.0
		var tip := root + Vector2.from_angle(a) * (40.0 + 10.0 * sin(t * 3.0 + float(k)))
		FighterArt.curved_spike(c, root, tip, 9.0, STEEL_SHADE, STEEL, 0.2)
	# Lashing metal arm
	var hand := Vector2(110 + lean, -150 + wob * 10.0)
	match pose:
		"lash_tele":
			hand = Vector2(-40, -260)
		"lash":
			hand = Vector2(210, -100)
		"throw_tele", "throw":
			hand = Vector2(130, -230)
		"spikes_tele", "spikes":
			hand = Vector2(80, -20)
	var arm := PackedVector2Array()
	for i in 7:
		var u := float(i) / 6.0
		arm.append(Vector2(50 + lean * 0.5, -170).lerp(hand, u) + Vector2(0, sin(t * 10.0 + u * 5.0) * 8.0 * (1.0 - u)))
	c.draw_polyline(arm, EnemyArt.BLACK, 24.0, FighterArt.AA)
	c.draw_polyline(arm, STEEL, 16.0, FighterArt.AA)
	c.draw_polyline(arm, Color(MOLTEN.r, MOLTEN.g, MOLTEN.b, 0.6), 4.0, FighterArt.AA)
	FighterArt.curved_spike(c, hand, hand + (hand - arm[5]).normalized() * 34.0, 10.0, STEEL, Color.WHITE, 0.15)
	# Face: two molten eyes in the metal and a gaping mouth
	var face := Vector2(36 + lean * 0.6, -200)
	if dead:
		EnemyArt.ko_eye(c, face, 6.0, t)
	else:
		for ex: float in [-14.0, 10.0]:
			c.draw_circle(face + Vector2(ex, 0), 9.0, EnemyArt.BLACK)
			c.draw_circle(face + Vector2(ex, 0), 6.0, MOLTEN_HI)
		c.draw_colored_polygon(EnemyArt.ellipse_points(face + Vector2(-2, 24), 16.0, 8.0 + absf(wob) * 6.0, 12), Color(MOLTEN.r * 0.6, 0.15, 0.05))
