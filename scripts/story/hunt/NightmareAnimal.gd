class_name NightmareAnimal
extends Animal
## NIGHTMARE ANIMAL (The Hunt of a Nightmare): the Nightmare version of Terra Ordinariorum's weak
## animals. The real ones never attack - these DO: they bite and charge. Red, with glowing eyes
## (the Nightmare tint: BaseEnemy.nightmare).
##
##   Bite     4 dmg
##   Charge   6 dmg   runs straight at you

func _make_data() -> CharacterData:
	var d := super._make_data()
	d.max_hp = maxi(d.max_hp * 5, 26)
	keep_min = 0.0
	keep_max = 110.0
	attack_chance = 0.7
	phase2_threshold = 0.5
	return d


static func make_patterns() -> Array[EnemyPattern]:
	var list: Array[EnemyPattern] = []
	list.append(EnemyPattern.make("bite", "BITE", 1.4, 4, 0.0, 90.0, "bite", 0.2, 0.15, 0.35, false, [1.8, 1.8]))
	list.append(EnemyPattern.make("charge", "CHARGE!", 3.6, 6, 120.0, 520.0, "charge", 0.45, 0.6, 0.45, false, [1.3, 1.5]))
	return list


func _make_brain() -> EnemyAI:
	return SimpleEnemyAI.new()


func _attack(p: EnemyPattern) -> void:
	match p.id:
		"bite":
			hitbox.activate(make_hit(dmg(p), Vector2(facing * 220.0, -140.0), "nm_bite"), Vector2(facing * 36.0, -data.body_size.y * 0.5), Vector2(60, 50))
			SoundManager.play_sfx("bite", -6.0)
		"charge":
			hitbox.activate(make_hit(dmg(p), Vector2(facing * 380.0, -220.0), "nm_charge"), Vector2(facing * 30.0, -data.body_size.y * 0.5), Vector2(80, 60))
			SoundManager.play_sfx("whoosh", -6.0)


func _on_attack_update(p: EnemyPattern, _delta: float) -> void:
	if p.id == "charge":
		velocity.x = facing * 720.0
		if is_on_wall() or not ground_ahead(50.0):
			velocity.x = 0.0
			state_time = state_len


func _owns_velocity_x() -> bool:
	return estate == EState.ATTACK and current != null and current.id == "charge"


func draw_model_on(c: CanvasItem) -> void:
	super.draw_model_on(c)
	if not is_dead:                                                   # Glowing red eyes
		var ey := Vector2(data.body_size.x * 0.42, -data.body_size.y * 0.72)
		c.draw_circle(ey, 3.0, Color(1.0, 0.15, 0.1, 0.9))
		c.draw_circle(ey, 7.0, Color(1.0, 0.1, 0.05, 0.25))


static func draw_portrait(c: CanvasItem, t: float) -> void:
	OrdArt.animal(c, "boar", {"t": t})
