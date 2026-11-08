class_name Fighter
extends CharacterBody2D
## Shared base for Player, Dummy and every future fighter.
## Owns: body collision, Hurtbox, health, knockback, statuses, death / respawn.
## Origin of this node = the fighter's FEET (center-bottom).

signal health_changed(current: int, maximum: int)
signal died
signal respawned
signal damaged(amount: int, hit: HitData)
signal dealt_damage(amount: int, victim: Fighter)
signal blocked(hit: HitData, perfect: bool)

var data: CharacterData
var gauge: GGauge = null              # Only characters with a G Gauge create one
var hp := 0
var facing := 1                       # 1 = right, -1 = left
var default_facing := 1
var is_dead := false
var is_blocking := false
var is_crouching := false
var spawn_position := Vector2.ZERO
var fall_death_y := 800.0
var knockback_scale := 1.0            # < 1 = knockback resistance
var grab_immune := false              # Giant bosses: grabs still damage them but never move them
var damage_taken_mult := 1.0          # < 1 = damage reduction (Warrior's Royal Destiny)
var grab_hold_distance := 70.0
var slot := 0                         # 1 = you, 2 = opponent (set by ArenaManager)
var respawn_enabled := true           # MatchManager turns this off when lives run out
var team := 0                         # Same team = allies (no damage, shared heals). 0 = no team.
var weakness_carry := 0.0             # Fractional bonus damage from weaknesses, carried to the next hit

# Last damage source (what killed us decides the death animation)
var last_hit: HitData = null
var last_damage_source := {}          # {attacker, move, part, type, onslaught} for debugging / UI
var last_death_type := ""

# Forced movement (pulled by Clinging Grab, etc.)
var _force_target := Vector2.ZERO
var _force_timer := 0.0

# Status effects
var stun_timer := 0.0
var goo_timer := 0.0
var burn_timer := 0.0                 # > 0 right after fire damage (status icon)
var goo_slow := 1.0
var goo_def_down := 0.0
var grabbed_by: Fighter = null
var grab_progress := 0.0
var block_press_time := -10.0

var hurtbox: Hurtbox
var visuals: Node2D
var _flash_tween: Tween


static func now() -> float:
	return Time.get_ticks_msec() / 1000.0


# ===== SETUP =====
func _ready() -> void:
	if data == null:
		data = CharacterData.dummy()
	if spawn_position == Vector2.ZERO:
		spawn_position = global_position
	collision_layer = CombatManager.BODY_LAYER
	collision_mask = CombatManager.WORLD_LAYER
	add_to_group("fighters")

	# Body collision: fixed size from data. Never changes with art.
	var shape := RectangleShape2D.new()
	shape.size = data.body_size
	var col := CollisionShape2D.new()
	col.name = "CollisionShape2D"
	col.shape = shape
	col.position = Vector2(0, -data.body_size.y / 2.0)
	add_child(col)

	hurtbox = Hurtbox.new()
	hurtbox.name = "Hurtbox"
	add_child(hurtbox)
	hurtbox.setup(self, data.body_size)

	visuals = Node2D.new()
	visuals.name = "Visuals"
	add_child(visuals)
	visuals.draw.connect(_draw_model)

	hp = data.max_hp
	health_changed.emit(hp, data.max_hp)


func _draw_model() -> void:
	draw_model_on(visuals)


## Override in subclasses: draw the character onto ANY canvas item.
## Drawn facing RIGHT, origin = feet. Death animations reuse this.
func draw_model_on(_c: CanvasItem) -> void:
	pass


# ===== STATUS =====
func tick_status(delta: float) -> void:
	stun_timer = maxf(stun_timer - delta, 0.0)
	burn_timer = maxf(burn_timer - delta, 0.0)
	if goo_timer > 0.0:
		goo_timer -= delta
		if goo_timer <= 0.0:
			goo_slow = 1.0
			goo_def_down = 0.0
	queue_redraw()


func speed_mult() -> float:
	return goo_slow if goo_timer > 0.0 else 1.0


func apply_goo(duration: float, slow: float, def_down: float) -> void:
	goo_timer = maxf(goo_timer, duration)
	goo_slow = slow
	goo_def_down = def_down


func can_block_now() -> bool:
	return is_blocking and not is_dead


func time_since_block_press() -> float:
	return now() - block_press_time


# ===== GRAB =====
func begin_grab(by: Fighter) -> void:
	grabbed_by = by
	grab_progress = 0.0
	stun_timer = 0.0
	velocity = Vector2.ZERO


func release_grab() -> void:
	grabbed_by = null
	grab_progress = 0.0
	velocity = Vector2.ZERO          # No knockback when a grab ends


func grab_mash() -> void:
	if grabbed_by == null:
		return
	grab_progress += 1.0
	if grab_progress >= data.grab_escape_presses:
		release_grab()
		Effects.popup(self, global_position + Vector2(0, -150), "ESCAPED!", Color(1, 0.95, 0.3), 26)


## True while an enemy's Time Stop has this fighter frozen.
func is_time_frozen() -> bool:
	return CombatManager.is_frozen(self)


## Slide this fighter to `target` (feet position) over `duration` seconds.
func force_move_to(target: Vector2, duration: float) -> void:
	if grab_immune:
		return
	_force_target = target
	_force_timer = maxf(duration, 0.01)


## Call near the top of _physics_process. Returns true while being moved (skip normal logic).
func forced_update(delta: float) -> bool:
	if _force_timer <= 0.0:
		return false
	velocity = (_force_target - global_position) / maxf(_force_timer, delta)
	_force_timer -= delta
	move_and_slide()
	if _force_timer <= 0.0:
		velocity = Vector2.ZERO
	return true


## Call at the top of _physics_process. Returns true while held (skip normal logic).
func grabbed_update(delta: float) -> bool:
	if grabbed_by == null or grab_immune:
		return false
	if not is_instance_valid(grabbed_by) or grabbed_by.is_dead:
		grabbed_by = null
		return false
	grab_progress = maxf(grab_progress - data.grab_escape_decay * delta, 0.0)
	velocity = Vector2.ZERO
	# Glide into the grab position (no teleport snap)
	var hold := grabbed_by.global_position + Vector2(grabbed_by.facing * grabbed_by.grab_hold_distance, 0.0)
	global_position = global_position.lerp(hold, 1.0 - exp(-22.0 * delta))
	return true


# ===== HEALTH =====
## Called by CombatManager after block / defense maths.
func take_hit(amount: int, hit: HitData) -> void:
	if is_dead:
		return
	# Remember WHAT hit us last: DeathManager picks the death animation from it.
	if amount > 0:
		last_hit = hit
		last_damage_source = {
			"attacker": hit.source.data.character_name if hit.source != null and is_instance_valid(hit.source) else "",
			"move": hit.move, "part": hit.part, "type": hit.hit_type, "onslaught": hit.onslaught,
		}
	if hit.hit_type == "fire" and amount > 0:
		burn_timer = 1.5
	hp = maxi(hp - amount, 0)
	if MatchSettings.god_mode_active():
		hp = data.max_hp                     # Sandbox God Mode: HP never drops
	health_changed.emit(hp, data.max_hp)
	damaged.emit(amount, hit)
	if amount > 0:
		var col := Color(1.0, 0.55, 0.1) if hit.onslaught else Color.WHITE
		Effects.popup(self, global_position + Vector2(randf_range(-14.0, 14.0), -140), "-%d" % amount, col, 28 if hit.onslaught else 22)
		_flash(Color(1.0, 0.3, 0.3), 0.15)
	if hit.knockback != Vector2.ZERO:
		apply_knockback(hit.knockback, hit.causes_hitstun)
	if hp <= 0:
		die()


## Restore HP (Lord's Heal). Returns how much was actually healed.
func heal(amount: int) -> int:
	if is_dead or amount <= 0:
		return 0
	var before := hp
	hp = mini(hp + amount, data.max_hp)
	var healed := hp - before
	health_changed.emit(hp, data.max_hp)
	if healed > 0:
		SoundManager.play_sfx("heal")
		Effects.popup(self, global_position + Vector2(randf_range(-10.0, 10.0), -150), "+%d HP" % healed, Color(1.0, 0.88, 0.3), 24)
	return healed


## Direct damage (T key, drill miss, etc.). Unblockable, no hitstun.
## Sandbox Damage Multiplier applies here too.
func take_damage(amount: int, knockback: Vector2 = Vector2.ZERO, move: String = "") -> void:
	amount = roundi(amount * MatchSettings.damage_multiplier())
	var h := HitData.new()
	h.move = move
	h.damage = amount
	h.knockback = knockback
	h.blockable = false
	h.causes_hitstun = false
	h.hit_type = "self"
	take_hit(amount, h)


func apply_knockback(kb: Vector2, stun: bool = true) -> void:
	if grabbed_by != null or kb == Vector2.ZERO:
		return
	# Smooth: blend into the new launch instead of snapping (keeps a bit of momentum)
	velocity = velocity.lerp(kb * knockback_scale, 0.85)
	if stun:
		stun_timer = data.hitstun_time


func on_blocked(hit: HitData, perfect: bool) -> void:
	if perfect:
		Effects.popup(self, global_position + Vector2(0, -150), "PERFECT BLOCK!", Color(0.4, 1.0, 1.0), 28)
	else:
		Effects.popup(self, global_position + Vector2(0, -150), "BLOCKED", Color(0.8, 0.85, 0.9), 22)
	blocked.emit(hit, perfect)


# ===== DEATH / RESPAWN =====
func check_fall_death() -> void:
	if global_position.y > fall_death_y:
		if MatchSettings.god_mode_active():
			respawn()                        # God Mode: no death, just put us back
			return
		die(DeathManager.FALL)


## death_type "" = decided by DeathManager from the last hit we took.
func die(death_type: String = "") -> void:
	if is_dead:
		return
	if death_type == "":
		death_type = custom_death_type(last_hit)       # Enemies can have their own death (Rotor: dog K.O.)
	if death_type == "":
		death_type = DeathManager.death_type(last_hit)
	last_death_type = death_type
	is_dead = true
	hp = 0
	velocity = Vector2.ZERO
	grabbed_by = null
	stun_timer = 0.0
	for n in get_tree().get_nodes_in_group("fighters"):
		var f := n as Fighter
		if f != null and f.grabbed_by == self:
			f.release_grab()
	_on_death()
	SoundManager.play_sfx("death")
	visuals.visible = false
	hurtbox.set_deferred("monitorable", false)
	DeathManager.play(self, death_type, last_hit)    # Fall over / split / explode / drown / implode
	queue_redraw()
	health_changed.emit(hp, data.max_hp)
	died.emit()                                       # MatchManager removes a life here
	await get_tree().create_timer(data.respawn_delay).timeout
	if respawn_enabled and is_inside_tree():
		respawn()


func respawn() -> void:
	global_position = spawn_position
	velocity = Vector2.ZERO
	hp = data.max_hp
	is_dead = false
	last_hit = null
	last_damage_source = {}
	facing = default_facing
	stun_timer = 0.0
	goo_timer = 0.0
	goo_slow = 1.0
	goo_def_down = 0.0
	grabbed_by = null
	knockback_scale = 1.0
	damage_taken_mult = 1.0
	_force_timer = 0.0
	visuals.visible = true
	# Fade back in (no instant pop) with a soft light burst
	visuals.modulate = Color(1, 1, 1, 0)
	if _flash_tween:
		_flash_tween.kill()
	_flash_tween = create_tween()
	_flash_tween.tween_property(visuals, "modulate", Color.WHITE, 0.3)
	Effects.hit_sparks(self, global_position + Vector2(0, -64), 8, 0.8)
	SoundManager.play_sfx("spawn")
	hurtbox.set_deferred("monitorable", true)
	_on_respawn()
	health_changed.emit(hp, data.max_hp)
	respawned.emit()


func _on_death() -> void:
	pass


## Override to force a death animation for THIS fighter (empty = normal rules).
func custom_death_type(_hit: HitData) -> String:
	return ""


func _on_respawn() -> void:
	pass


# ===== VISUAL HELPERS =====
func _flash(color: Color, duration: float) -> void:
	if _flash_tween:
		_flash_tween.kill()
	visuals.modulate = color
	_flash_tween = create_tween()
	_flash_tween.tween_property(visuals, "modulate", Color.WHITE, duration)


func _status_text() -> String:
	var parts: PackedStringArray = []
	if is_time_frozen():
		parts.append("TIME STOPPED")
	if goo_timer > 0.0:
		parts.append("VOID GOO: SLOWED, DEF -%d%%" % int(goo_def_down * 100.0))
	if grabbed_by != null:
		parts.append("GRABBED! mash (%d/%d)" % [int(grab_progress), data.grab_escape_presses])
	if stun_timer > 0.0:
		parts.append("STUN")
	return " | ".join(parts)


## Name tag + status text above the head (not flipped, not part of the art).
func _draw() -> void:
	if is_dead or data == null:
		return
	var top := -data.body_size.y - 20.0
	var tag := data.character_name
	var tag_col := Color.WHITE
	if slot == 1:
		tag = "P1  " + tag
		tag_col = Color(0.55, 1.0, 0.55)
	elif slot == 2:
		tag = "CPU  " + tag
		tag_col = Color(1.0, 0.6, 0.55)
	FighterArt.label(self, Vector2(0, top), tag, 14, tag_col)
	var s := _status_text()
	if s != "":
		FighterArt.label(self, Vector2(0, top - 18.0), s, 13, Color(1.0, 0.9, 0.3))
		
