class_name C5Boss
extends SimpleEnemy
## BASE FOR THE COLOSSEUM 5 BOSSES (harder than Colosseums 1-4):
##   * FORMS: a boss can have several forms, each with its OWN full HP bar (Mother Nature: 5,
##     The Sun: 2). At 0 HP the boss does not die: StoryManager plays the transform cutscene
##     (transform_started -> finish_transform), like Blasphemy Caeser.
##   * RAGE: below rage_at HP inside a form the boss gets faster, cools down quicker and
##     chains more attacks (the HP bar turns gold, "ENRAGED").
##   * COMBOS: combos[id] = follow-up pattern ids. When a pattern ends the boss may chain
##     straight into a follow-up with almost no recovery (chain_chance, higher when enraged).
##   * SMART BRAIN (BossBrain): anti-air when you jump, evades / counters when you swing,
##     escapes corners, feints, focuses the human player over the CPU partner.
##   * MINIONS: summon() adds helpers that die with the boss.
## A boss subclass overrides boss_forms(), setup_boss(), make_patterns(), _attack(), and the art.

signal transform_started

var forms: Array = []                 # [{name, title, hp, body, speed, banner, subtitle, line, music}]
var form := 1
var transform_banner := ""            # Read by StoryManager._on_boss_transform
var phase2_subtitle := ""
var phase2_line := ""
var form_music := ""                  # Music of the CURRENT form ("" = the level's boss music)
var art_scale := 1.0
var rage_at := 0.5
var raging := false
var combos := {}                      # pattern id -> Array of follow-up ids
var chain_chance := 0.45
var tags := {}                        # pattern id -> Array of "anti_air" / "evade" / "escape" / "ranged" / "close"
var minions: Array = []
var form_t := 99.0                    # Seconds since the current form began
var max_minions := 4

var _transforming := false
var _tf_t := 0.0
var _chain_next := ""
var _base_cd := 1.0
var _base_chain := 0.45


# ----- OVERRIDES -----
func boss_forms() -> Array:
	return [{"name": "Boss", "title": "BOSS", "hp": 300, "body": Vector2(100, 200), "speed": 200.0}]

func setup_boss() -> void:
	pass

func on_form_changed(_new_form: int) -> void:
	pass

func on_rage() -> void:
	pass


func _make_data() -> CharacterData:
	forms = boss_forms()
	var f0: Dictionary = forms[0]
	keep_min = 0.0
	keep_max = 200.0
	attack_chance = 0.8
	phase2_threshold = -1.0                     # Forms + rage are handled here
	knockback_scale = 0.25
	grab_immune = true
	setup_boss()
	_base_chain = chain_chance
	var d := SimpleEnemy.make_data(String(f0.get("name", "Boss")), int(f0["hp"]), f0["body"], float(f0["speed"]))
	d.hitstun_time = 0.06
	d.respawn_delay = 99.0
	d.jump_force = 900.0
	_set_next_banner()
	return d


func _ready() -> void:
	super._ready()
	_base_cd = cooldown_mult
	visuals.scale = Vector2(facing * art_scale, art_scale)


func _make_brain() -> EnemyAI:
	return BossBrain.new()


func boss_title() -> String:
	var t := String(forms[form - 1].get("title", enemy_name.to_upper())) if form - 1 < forms.size() else enemy_name.to_upper()
	return t + ("   -   ENRAGED" if raging else "")


func jump(force_mult: float = 1.0) -> void:
	if is_on_floor() and can_act():
		velocity.y = -data.jump_force * force_mult


# ============================================================
# FORMS
# ============================================================
func take_hit(amount: int, hit: HitData) -> void:
	if _transforming:
		return
	if form < forms.size() and amount >= hp and amount > 0:
		super.take_hit(maxi(hp - 1, 0), hit)     # Never dies here: it CHANGES
		_begin_transform()
		return
	super.take_hit(amount, hit)


func is_transforming() -> bool:
	return _transforming


func _begin_transform() -> void:
	if _transforming or is_dead:
		return
	_transforming = true
	_tf_t = 0.0
	_chain_next = ""
	_cancel_pattern()
	move_dir = 0.0
	velocity = Vector2.ZERO
	hurtbox.set_deferred("monitorable", false)
	_clear_minions()
	if transform_started.get_connections().is_empty():
		finish_transform()                         # No cutscene director (tests): change at once
	else:
		transform_started.emit()


## Called by StoryManager in the middle of the transform cutscene.
func finish_transform() -> void:
	form = mini(form + 1, forms.size())
	phase = form
	raging = false
	enraged = false
	form_t = 0.0
	chain_chance = _base_chain
	var fd: Dictionary = forms[form - 1]
	form_music = String(fd.get("music", ""))         # StoryManager plays it after the transform
	enemy_name = String(fd.get("name", enemy_name))
	data.character_name = enemy_name
	data.max_hp = int(fd.get("hp", data.max_hp))
	hp = data.max_hp
	var body: Vector2 = fd.get("body", data.body_size)
	data.body_size = body
	hurtbox.resize(body)
	var col := get_node_or_null("CollisionShape2D") as CollisionShape2D
	if col != null and col.shape is RectangleShape2D:
		(col.shape as RectangleShape2D).size = body
		col.position = Vector2(0, -body.y * 0.5)
	if hud != null:
		hud.position = Vector2(0, -body.y - 34.0)
	speed = float(fd.get("speed", speed))
	data.move_speed = speed
	cooldown_mult = _base_cd
	phase_speed_mult = 1.0
	for p in patterns:
		p.cooldown_left = 0.7
	_set_next_banner()
	on_form_changed(form)
	health_changed.emit(hp, data.max_hp)
	hurtbox.set_deferred("monitorable", true)
	_transforming = false
	pose = "idle"


func _set_next_banner() -> void:
	if form < forms.size():
		var nf: Dictionary = forms[form]
		transform_banner = String(nf.get("banner", "IT CHANGES..."))
		phase2_subtitle = String(nf.get("subtitle", "NEXT FORM"))
		phase2_line = String(nf.get("line", ""))


## Rage inside a form (replaces BaseEnemy's single phase 2).
func _check_phase() -> void:
	if raging or _transforming or hp > data.max_hp * rage_at:
		return
	raging = true
	enraged = true
	cooldown_mult = _base_cd * 0.7
	phase_speed_mult = 1.25
	chain_chance = minf(_base_chain + 0.3, 0.9)
	Effects.popup(self, global_position + Vector2(0, -data.body_size.y - 40.0), "ENRAGED!", Color(1.0, 0.85, 0.2), 30)
	SoundManager.play_sfx("roar", -2.0)
	Effects.shake(self, 8.0)
	on_rage()


# ============================================================
# COMBO CHAINS
# ============================================================
func _run_state(delta: float) -> void:
	var was := estate
	var p := current
	super._run_state(delta)
	if was == EState.ATTACK and estate == EState.RECOVER and p != null and combos.has(p.id) and randf() < chain_chance:
		var opts: Array = combos[p.id]
		_chain_next = String(opts[randi() % opts.size()])
	if estate != EState.RECOVER:
		_chain_next = ""
	elif _chain_next != "" and state_time >= 0.1:
		var np := pattern(_chain_next)
		_chain_next = ""
		if np != null and np.weight(phase) > 0.0 and not _transforming and stun_timer <= 0.0:
			estate = EState.IDLE
			current = null
			np.cooldown_left = 0.0
			face_target()
			start_pattern(np)


func face_target() -> void:
	facing = 1 if target_x() >= global_position.x else -1


# ============================================================
# HELPERS FOR ATTACKS
# ============================================================
func floor_y() -> float:
	return global_position.y if is_on_floor() else _arena_floor()


func _arena_floor() -> float:
	var g := get_tree().get_first_node_in_group("arena_ground") as ArenaGround
	return g.global_position.y if g != null else global_position.y


func clamp_arena(x: float, margin: float = 60.0) -> float:
	if StoryManager.has_walls:
		return clampf(x, StoryManager.wall_left_x + margin, StoryManager.wall_right_x - margin)
	return clamp_to_ground(x, margin)


func arena_center() -> float:
	if StoryManager.has_walls:
		return (StoryManager.wall_left_x + StoryManager.wall_right_x) * 0.5
	var g := get_tree().get_first_node_in_group("arena_ground") as ArenaGround
	return g.global_position.x if g != null else global_position.x


func target_y() -> float:
	if brain != null and brain.target != null and is_instance_valid(brain.target):
		return brain.target.global_position.y
	return global_position.y


## Straight shot. dir: -1 / 1.
func shoot(look: String, from: Vector2, dir: float, spd: float, life: float, size: Vector2, damage: int,
		kb: Vector2, tint: Color = Color.WHITE, move: String = "boss_shot", pierce: bool = false) -> EnemyProjectile:
	var s := spawn_projectile()
	s.kind = EnemyProjectile.Kind.LINEAR
	s.look = look
	s.tint = tint
	s.dir = dir
	s.speed = spd
	s.lifetime = life
	s.size = size
	s.damage = damage
	s.knockback = kb
	s.pierce = pierce
	s.move = move
	launch(s, from)
	return s


## Lobbed shot that lands on to_x after `flight` seconds (hits where it lands).
func lob(look: String, from: Vector2, to_x: float, flight: float, damage: int, kb: Vector2, radius: float,
		tint: Color = Color.WHITE, move: String = "boss_lob", on_land: Callable = Callable()) -> EnemyProjectile:
	var g := spawn_projectile()
	g.kind = EnemyProjectile.Kind.ARC
	g.look = look
	g.tint = tint
	g.damage = damage
	g.knockback = kb
	g.radius = radius
	g.pierce = false
	g.size = Vector2(radius, radius)
	g.lifetime = flight + 2.0
	g.move = move
	var drop := _arena_floor() - from.y
	g.arc_velocity = Vector2((to_x - from.x) / flight, (drop - 0.5 * EnemyProjectile.ARC_GRAVITY * flight * flight) / flight)
	if on_land.is_valid():
		g.on_land = on_land
	launch(g, from)
	return g


func hazard(kind: String, x: float, delay: float, damage: int, kb: Vector2 = Vector2(220, -420)) -> void:
	BossHazard.spawn(self, kind, Vector2(clamp_arena(x, 40.0), _arena_floor()), delay, damage, kb)


## Melee box in front (offset x is mirrored by facing).
func swing(damage: int, kb: Vector2, off: Vector2, size: Vector2, move: String) -> void:
	hitbox.activate(make_hit(damage, Vector2(facing * kb.x, kb.y), move), Vector2(facing * off.x, off.y), size)


## Jump to a point on the floor in `time` seconds (arc).
func leap_to(x: float, time: float, height: float = 260.0) -> void:
	var dx := clamp_arena(x) - global_position.x
	velocity = Vector2(dx / maxf(time, 0.1), -sqrt(2.0 * data.gravity * height))


# ============================================================
# MINIONS
# ============================================================
func summon(id: String, pos: Vector2) -> BaseEnemy:
	_prune_minions()
	if minions.size() >= max_minions:
		return null
	var m := StoryLevels.make_enemy(id)
	m.slot = 2
	m.team = team
	m.respawn_enabled = false
	m.position = pos
	m.default_facing = facing
	m.facing = facing
	get_parent().add_child(m)
	Effects.hit_sparks(m, pos + Vector2(0, -30), 8, 1.0)
	minions.append(m)
	return m


func _prune_minions() -> void:
	var keep: Array = []
	for m in minions:
		if m != null and is_instance_valid(m) and not (m as BaseEnemy).is_dead:
			keep.append(m)
	minions = keep


func _clear_minions() -> void:
	for m in minions:
		if m != null and is_instance_valid(m) and not (m as BaseEnemy).is_dead:
			(m as BaseEnemy).die()
	minions.clear()


func _on_death() -> void:
	super._on_death()
	_clear_minions()


# ============================================================
# VISUALS
# ============================================================
func _process(delta: float) -> void:
	form_t += delta
	if _transforming:
		_tf_t += delta
		visuals.queue_redraw()


func _update_visuals(delta: float) -> void:
	if raging:
		anim_time += delta * 0.3
	super._update_visuals(delta)
	visuals.scale = Vector2(facing * art_scale, art_scale)


## Common art state + boss extras.
func art_state() -> Dictionary:
	var s := super.art_state()
	s["form"] = form
	s["raging"] = raging
	s["tf"] = _tf_t if _transforming else -1.0
	s["form_t"] = form_t
	return s
