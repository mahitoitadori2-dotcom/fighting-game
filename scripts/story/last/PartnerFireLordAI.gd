class_name PartnerFireLordAI
extends FireLordAI
## THE LAST STRETCH: the NIGHTMARE LORD as your third ally on the road (levels with "nl_ally"): his
## Versus brain on HARD settings (Companion.make_strong) + following you (Companion), like the partner.


func _init() -> void:
	super._init()
	Companion.make_strong(self)


func think() -> void:
	if not Companion.try_ultimate(self):
		super.think()


func update(fighter: Fighter, delta: float) -> void:
	super.update(fighter, delta)
	Companion.steer(self)
