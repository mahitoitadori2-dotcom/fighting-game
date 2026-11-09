class_name Ambusher
extends SimpleEnemy
## AMBUSHER (Colosseum 5 coin flip: HEADS = 2 of them). A lean shadow-stalker in a ragged black
## cloak, two curved claw-blades and glowing amber eyes. It waits HIDDEN in the shadows (barely
## visible, half damage taken from nothing - it simply is not there), then LEAPS out at you.
##
##   Shadow Pounce  7 dmg, 3.2 s - jumps out of the shadows onto you and slashes on landing
##   Twin Slash     5 dmg, 1.4 s - two quick claw slashes
##   Vanish         -     5.0 s - melts into the shadows and comes back out BEHIND you

const BLACK := Color(0.08, 0.07, 0.10)
const CLOAK := Color(0.16, 0.14, 0.19)
const CLOAK_HI := Color(0.28, 0.25, 0.32)
const BLADE := Color(0.78, 0.80, 0.86)
const EYE := Color(1.0, 0.72, 0.15)

var _hidden := 1.0                      # 1 = in the shadows (spawns hidden), 0 = out
var _pounce_air := false


func _make_data() -> CharacterData:
	keep_min = 140.0
	keep_max = 320.0
	attack_chance = 0.65
	phase2_threshold = -1.0
	var d := SimpleEnemy.make_data("Ambusher", 30, Vector2(54, 120), 290.0)
	d.jump_force = 760.0
	return d


static func make_patterns() -> Array[EnemyPattern]:
	var list: Array[EnemyPattern] = []
	#                          id        name              cd    dmg  min    max    anim      tele  active rec   big    weights
	list.append(EnemyPattern.make("pounce", "SHADOW POUNCE!", 3.2, 7, 120.0, 520.0, "pounce", 0.35, 0.90, 0.40, true, [2.0, 2.0]))
	list.append(EnemyPattern.make("slash", "TWIN SLASH", 1.4, 5, 0.0, 100.0, "slash", 0.22, 0.30, 0.35, false, [2.0, 2.0]))
	list.append(EnemyPattern.make("vanish", "VANISH", 5.0, 0, 0.0, 300.0, "vanish", 0.30, 0.50, 0.20, false, [1.0, 1.0]))
	return list


func flavor_lines() -> Array[String]:
	return ["*a breath behind you*", "...", "*claws scrape stone*"]


func _attack(p: EnemyPattern) -> void:
	match p.id:
		"pounce":
			_hidden = 0.0
			var dx := clampf(target_x() - global_position.x, -480.0, 480.0)
			velocity = Vector2(dx / 0.55, -620.0)
			_pounce_air = false
			SoundManager.play_sfx("dash", -4.0)
		"slash":
			_hidden = 0.0
			hitbox.activate(make_hit(dmg(p), Vector2(facing * 260.0, -160.0), "ambusher_slash"), Vector2(facing * 52.0, -64.0), Vector2(84, 80))
			SoundManager.play_sfx("sword_slash", -5.0)
		"vanish":
			_hidden = 1.0
			Effects.void_burst(self, global_position + Vector2(0, -50), 50.0)
			var behind := target_x() - float(facing) * 110.0
			global_position.x = clamp_to_ground(behind)
			if StoryManager.has_walls:
				global_position.x = clampf(global_position.x, StoryManager.wall_left_x + 50.0, StoryManager.wall_right_x - 50.0)
			facing = -facing
			SoundManager.play_sfx("whoosh", -6.0)


func _on_attack_update(p: EnemyPattern, _delta: float) -> void:
	if p.id == "pounce":
		if not is_on_floor():
			_pounce_air = true
		elif _pounce_air:
			hit_in_radius(global_position + Vector2(facing * 30.0, -50.0), 70.0, dmg(p), Vector2(300, -260), "shadow_pounce")
			Effects.hit_sparks(self, global_position + Vector2(facing * 30.0, -40.0), 6, 1.0)
			velocity.x = 0.0
			state_time = state_len
	elif p.id == "slash" and state_time > 0.15 and state_time - get_physics_process_delta_time() <= 0.15:
		hitbox.activate(make_hit(dmg(p), Vector2(facing * 300.0, -200.0), "ambusher_slash"), Vector2(facing * 52.0, -64.0), Vector2(84, 80))


func _owns_velocity_x() -> bool:
	return estate == EState.ATTACK and current != null and current.id == "pounce"


func _update_visuals(delta: float) -> void:
	# Out in the open after a while; back in the shadows when it vanishes
	if estate == EState.IDLE or estate == EState.MOVE:
		_hidden = move_toward(_hidden, 0.0, delta * 0.35)
	super._update_visuals(delta)
	visuals.modulate.a = lerpf(1.0, 0.18, _hidden)


func take_hit(amount: int, hit: HitData) -> void:
	_hidden = 0.0                                      # Hit = dragged out of the shadows
	super.take_hit(amount, hit)


# ============================================================
# ART (facing right, origin = feet, ~70 x 130)
# ============================================================
func draw_model_on(c: CanvasItem) -> void:
	draw_ambusher(c, art_state())


static func draw_portrait(c: CanvasItem, t: float) -> void:
	draw_ambusher(c, {"t": t, "pose": "idle"})


static func draw_ambusher(c: CanvasItem, s: Dictionary) -> void:
	var t: float = s.get("t", 0.0)
	var pose: String = s.get("pose", "idle")
	var dead: bool = s.get("dead", false)
	var crouch := 10.0 if pose.begins_with("pounce") or pose == "idle" else 0.0
	EnemyArt.legs(c, s, -50.0 + crouch, 9.0, 9.0, CLOAK, BLACK, CLOAK_HI, BLACK, 16.0)
	var chest := Vector2(6, -84 + crouch + sin(t * 3.0) * 1.5)
	# Ragged cloak (tattered hem flutters)
	var cloak := PackedVector2Array([chest + Vector2(-20, -24), chest + Vector2(18, -26), chest + Vector2(26, 30)])
	for i in 5:
		cloak.append(chest + Vector2(24.0 - float(i) * 12.0, 30.0 + (10.0 if i % 2 == 0 else 0.0) + sin(t * 6.0 + float(i)) * 3.0))
	cloak.append(chest + Vector2(-28, 22))
	c.draw_colored_polygon(cloak, CLOAK)
	FighterArt.outline(c, cloak, 3.5)
	# Claw-blades on both hands
	var reach := 0.0
	if pose == "slash" or pose == "pounce":
		reach = 26.0
	for i in 2:
		var hand := chest + Vector2(14.0 + reach - float(i) * 22.0, 8.0 - float(i) * 6.0)
		EnemyArt.arm(c, chest + Vector2(-4.0 + float(i) * 8.0, -16), hand, 7.0, CLOAK_HI, BLACK, CLOAK_HI, BLACK, 5.0)
		for k in 3:
			var tip := hand + Vector2(28.0 - float(k) * 4.0, -16.0 + float(k) * 12.0)
			FighterArt.curved_spike(c, hand + Vector2(0, float(k) * 4.0 - 4.0), tip, 3.0, BLADE, Color.WHITE, 0.3, 2.0)
	# Hood + glowing eyes
	var head := chest + Vector2(6, -36)
	var hood := PackedVector2Array([head + Vector2(-20, 14), head + Vector2(-16, -12), head + Vector2(4, -24), head + Vector2(20, -6), head + Vector2(18, 14)])
	c.draw_colored_polygon(hood, BLACK)
	FighterArt.outline(c, hood, 3.0)
	if dead:
		EnemyArt.ko_eye(c, head + Vector2(8, 0), 3.0, t)
	else:
		for ex: float in [2.0, 12.0]:
			c.draw_circle(head + Vector2(ex, 0), 5.0, Color(EYE.r, EYE.g, EYE.b, 0.3))
			c.draw_circle(head + Vector2(ex, 0), 2.6, EYE)
	if pose == "slash":
		c.draw_arc(chest + Vector2(30, 0), 54.0, -1.2, 1.0, 12, Color(1, 1, 1, 0.5), 3.0, true)
