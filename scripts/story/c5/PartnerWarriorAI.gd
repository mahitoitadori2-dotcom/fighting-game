class_name PartnerWarriorAI
extends WarriorAI
## Colosseum 5 CPU partner: the Warrior's brain on HARD settings (Companion.make_strong)
## + following you (Companion).


func _init() -> void:
	super._init()
	Companion.make_strong(self)


func think() -> void:
	if not Companion.try_ultimate(self):
		super.think()


func update(fighter: Fighter, delta: float) -> void:
	super.update(fighter, delta)
	Companion.steer(self)
