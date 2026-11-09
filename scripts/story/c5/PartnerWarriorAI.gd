class_name PartnerWarriorAI
extends WarriorAI
## Colosseum 5 CPU partner: the Warrior's normal MEDIUM brain + following you (Companion).


func update(fighter: Fighter, delta: float) -> void:
	super.update(fighter, delta)
	Companion.steer(self)
