class_name CrystalSwarm
extends C5Boss
## THE CRYSTAL SWARM - the SECRET boss of Terra Ordinariorum (the Snow Desert). A floating crystal,
## one of the sentient crystals the Storm threw everywhere in the Great Freezing.
## The user's rules: you CANNOT DIE in this fight (OrdLand keeps you above 1 HP). It shoots 10
## crystals (dodge them); after the 10th it is STANCE BROKEN - hit it then and it dies.
## Before that every hit is turned away by its shards. If the stagger runs out, it starts again.

const SHOTS := 10
var shots_left := SHOTS


func boss_forms() -> Array:
	return [{"name": "The Crystal Swarm", "title": "THE CRYSTAL SWARM", "hp": 60, "body": Vector2(120, 240), "speed": 0.0}]


func setup_boss() -> void:
	keep_min = 0.0
	keep_max = 3000.0
	attack_chance = 0.9
	chain_chance = 0.0
	grab_immune = true
	knockback_scale = 0.0
	tags = {"crystal": ["ranged"], "rain": ["ranged", "anti_air"]}


static func make_patterns() -> Array[EnemyPattern]:
	var list: Array[EnemyPattern] = []
	list.append(EnemyPattern.make("crystal", "CRYSTAL!", 1.3, 6, 0.0, 3000.0, "shoot", 0.5, 0.2, 0.3, false, [2.0], true))
	list.append(EnemyPattern.make("rain", "CRYSTAL RAIN!", 2.2, 6, 0.0, 3000.0, "shoot", 0.6, 0.3, 0.4, false, [1.0], true))
	return list


func wants_pattern(_p: EnemyPattern) -> bool:
	return shots_left > 0 and stance_broken <= 0.0


func flavor_lines() -> Array[String]:
	return ["*a high, glassy hum*", "*the shards turn to face you*"]


func _attack(p: EnemyPattern) -> void:
	if shots_left <= 0:
		return
	shots_left -= 1
	var core := global_position + Vector2(0, -150)
	match p.id:
		"crystal":
			face_target()
			shoot("frost", core, float(facing), 560.0, 3.0, Vector2(34, 34), dmg(p), Vector2(240, -200), Color(0.7, 0.9, 1.0), "crystal_shot")
		"rain":
			hazard("pillar", target_x(), 0.7, dmg(p))
	SoundManager.play_sfx("holy", -8.0)
	if shots_left <= 0:
		_shatter_guard.call_deferred()


## The 10th crystal is gone: it staggers, open to ONE blow.
func _shatter_guard() -> void:
	await get_tree().create_timer(0.9).timeout
	if is_dead:
		return
	poise_max = maxf(poise_max, 1.0)
	_break_stance()
	stance_broken = 6.0
	Effects.popup(self, global_position + Vector2(0, -320), "*it cracks - and sinks*", Color(0.8, 0.95, 1.0), 22)


func take_hit(amount: int, hit: HitData) -> void:
	if stance_broken <= 0.0:
		if amount > 0:
			Effects.popup(self, global_position + Vector2(0, -300), "THE SHARDS TURN IT AWAY", Color(0.7, 0.9, 1.0), 18)
			Effects.hit_sparks(self, global_position + Vector2(0, -150), 6, 0.9)
			SoundManager.play_sfx("block", -6.0)
		return
	super.take_hit(hp + 999, hit)                                   # One hit while staggered: it shatters


func _process(delta: float) -> void:
	super._process(delta)
	if not is_dead and shots_left <= 0 and stance_broken <= 0.0 and _poise_lock > 0.0:
		shots_left = SHOTS                                          # It recovered: 10 more


func _owns_velocity_x() -> bool:
	return true


func _physics_process(delta: float) -> void:
	velocity = Vector2.ZERO
	super._physics_process(delta)


func art_state() -> Dictionary:
	var s := super.art_state()
	s["broken"] = stance_broken > 0.0
	s["shards"] = shots_left
	return s


func draw_model_on(c: CanvasItem) -> void:
	OrdArt.crystal_swarm(c, art_state())


static func draw_portrait(c: CanvasItem, t: float) -> void:
	OrdArt.crystal_swarm(c, {"t": t, "shards": 10})
