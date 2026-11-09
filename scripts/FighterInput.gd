class_name FighterInput
extends RefCounted
## Where a fighter's commands come from. This base class = the HUMAN keyboard/mouse.
## AIInput extends it and fakes the same buttons, so every character works
## as Player OR Opponent without any extra code.
##
## Logical buttons: left, right, jump, crouch, attack, block, move1, move2, move3, ultimate

const ACTIONS := {
	"left": "move_left",
	"right": "move_right",
	"jump": "jump",
	"crouch": "crouch",
	"attack": "punch",
	"block": "block",
	"move1": "move_rocket",
	"move2": "move_hnct",
	"move3": "move_drill",
	"ultimate": "ultimate",
	"move4": "move_4",                 # APHA Architect only (keys 4-7 + E)
	"move5": "move_5",
	"move6": "move_6",
	"move7": "move_7",
	"fly": "flight",
}


var _owner: Fighter                  # Set every frame by update() (memory fog reverses left / right)


func is_human() -> bool:
	return true


## Called once per physics frame by the fighter, BEFORE it reads any input.
func update(fighter: Fighter, _delta: float) -> void:
	_owner = fighter


func _confused() -> bool:
	return _owner != null and is_instance_valid(_owner) and _owner.confuse_timer > 0.0


func pressed(button: String) -> bool:
	return Input.is_action_pressed(ACTIONS[_swap(button)])


func just_pressed(button: String) -> bool:
	return Input.is_action_just_pressed(ACTIONS[_swap(button)])


func just_released(button: String) -> bool:
	return Input.is_action_just_released(ACTIONS[_swap(button)])


func axis() -> float:
	var a := Input.get_axis(ACTIONS["left"], ACTIONS["right"])
	return -a if _confused() else a


## Confused (memory fog): left and right swap places.
func _swap(button: String) -> String:
	if _confused():
		if button == "left":
			return "right"
		if button == "right":
			return "left"
	return button


## Any key pressed this frame (used to mash out of grabs).
func any_mash() -> bool:
	for b in ["left", "right", "jump", "crouch", "attack", "block"]:
		if just_pressed(b):
			return true
	return false
