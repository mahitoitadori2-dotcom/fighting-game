class_name PartnerArchitectAI
extends ArchitectAI
## Colosseum 5 CPU partner: the Architect's normal MEDIUM brain + following you (Companion).


func update(fighter: Fighter, delta: float) -> void:
	super.update(fighter, delta)
	Companion.steer(self)
