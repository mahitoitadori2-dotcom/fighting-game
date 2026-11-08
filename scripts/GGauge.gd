class_name GGauge
extends RefCounted
## G Gauge: 3 segments of 100 points each.
## Gains are scaled by the Sandbox G Gauge Multiplier (0x = never fills).

signal changed(value: float)

var segment_size := 100.0
var segment_count := 3
var value := 0.0


func max_value() -> float:
	return segment_size * segment_count


## Normal gain (damage dealt, perfect block, auto-fill). Sandbox multiplier applies.
func add(amount: float) -> void:
	if amount > 0.0:
		amount *= MatchSettings.gauge_multiplier()
	add_raw(amount)


## Gain that ignores the Sandbox multiplier (debug K key).
func add_raw(amount: float) -> void:
	value = clampf(value + amount, 0.0, max_value())
	changed.emit(value)


func segments() -> int:
	return mini(int(floor(value / segment_size + 0.0001)), segment_count)


## Every ultimate in the game spends bars here, so this is the one "ultimate" sound hook.
func consume_segments(n: int) -> void:
	SoundManager.play_sfx("ultimate")
	value = maxf(value - n * segment_size, 0.0)
	if MatchSettings.gauge_instant():
		value = max_value()                  # Sandbox INSTANT: refills right after use
	changed.emit(value)
