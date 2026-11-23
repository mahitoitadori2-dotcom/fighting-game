class_name NetInput
extends FighterInput
## The GUEST's buttons on the HOST: whatever the guest pressed (sent every frame over the network)
## drives the guest's fighter like a keyboard would.

var _axis := 0.0
var _bits := 0                         # Latest from the network
var _cur := 0                          # This physics frame
var _prev := 0                         # Last physics frame
var _latched := 0                      # Presses that came AND went between two host frames still count


func feed(a: float, bits: int) -> void:
	_axis = clampf(a, -1.0, 1.0)
	_latched |= bits & ~_bits
	_bits = bits


func update(fighter: Fighter, _delta: float) -> void:
	_owner = fighter
	_prev = _cur
	_cur = _bits | _latched
	_latched = 0


func _bit(button: String) -> int:
	var i := NetLink.BUTTONS.find(_swap(button))
	return 1 << i if i >= 0 else 0


func pressed(button: String) -> bool:
	return (_cur & _bit(button)) != 0


func just_pressed(button: String) -> bool:
	var b := _bit(button)
	return (_cur & b) != 0 and (_prev & b) == 0


func just_released(button: String) -> bool:
	var b := _bit(button)
	return (_cur & b) == 0 and (_prev & b) != 0


func axis() -> float:
	return -_axis if _confused() else _axis


## Packs the LOCAL player's buttons (keyboard / touch / pad) for sending: [axis, bits].
static func read_local(local: FighterInput) -> Array:
	var bits := 0
	for i in NetLink.BUTTONS.size():
		if local.pressed(String(NetLink.BUTTONS[i])):
			bits |= 1 << i
	return [local.axis(), bits]
