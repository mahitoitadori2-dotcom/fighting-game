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
}


func is_human() -> bool:
	return true


## Called once per physics frame by the fighter, BEFORE it reads any input.
func update(_fighter: Fighter, _delta: float) -> void:
	pass


func pressed(button: String) -> bool:
	return Input.is_action_pressed(ACTIONS[button])


func just_pressed(button: String) -> bool:
	return Input.is_action_just_pressed(ACTIONS[button])


func just_released(button: String) -> bool:
	return Input.is_action_just_released(ACTIONS[button])


func axis() -> float:
	return Input.get_axis(ACTIONS["left"], ACTIONS["right"])


## Any key pressed this frame (used to mash out of grabs).
func any_mash() -> bool:
	for b in ["left", "right", "jump", "crouch", "attack", "block"]:
		if just_pressed(b):
			return true
	return false
