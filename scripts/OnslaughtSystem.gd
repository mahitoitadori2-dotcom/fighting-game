class_name OnslaughtSystem
extends RefCounted
## GLOBAL Onslaught logic. Whether a character can use it is decided ONLY by the
## flags in its data (onslaught_melee_enabled / _projectile_enabled / _trap_enabled).
##
## Flow: something starts a FLASH (kind + move id). If the player repeats that
## input while the flash is running, consume_flash() returns true = Onslaught.

signal flash_started(kind: String, duration: float)
signal flash_ended

var data: CharacterData
var flash_timer := 0.0
var flash_duration := 0.4
var flash_kind := ""                 # "melee" / "projectile" / "trap"
var flash_move := ""                 # move id ("" for melee)
var flash_target: Object = null      # Projectile / trap that would be upgraded
var flash_has_target := false
var flash_target_gen := 0           # pool_gen of the target when the flash started

var melee_count := 0
var combo_timer := 0.0
var afterburn_timer := 0.0


func _init(d: CharacterData) -> void:
	data = d


func is_enabled(kind: String) -> bool:
	match kind:
		"melee":
			return data.onslaught_melee_enabled
		"projectile":
			return data.onslaught_projectile_enabled
		"trap":
			return data.onslaught_trap_enabled
	return false


func tick(delta: float) -> void:
	if combo_timer > 0.0:
		combo_timer -= delta
		if combo_timer <= 0.0 and flash_timer <= 0.0:
			melee_count = 0
	if flash_timer > 0.0:
		flash_timer -= delta
		if flash_has_target and not target_alive():
			cancel_flash()               # Rocket / bomb already gone: nothing to upgrade
		elif flash_timer <= 0.0:
			cancel_flash()
	if afterburn_timer > 0.0:
		afterburn_timer = maxf(afterburn_timer - delta, 0.0)


## Call when a NORMAL melee starts. Returns true if this was the Nth in a row.
func register_melee() -> bool:
	if not data.onslaught_melee_enabled:
		return false
	if combo_timer <= 0.0:
		melee_count = 0
	melee_count += 1
	combo_timer = data.onslaught_combo_window
	return melee_count >= data.onslaught_combo_hits


func start_flash(kind: String, move_id: String, target: Object = null) -> void:
	if not is_enabled(kind):
		return
	flash_kind = kind
	flash_move = move_id
	flash_duration = data.onslaught_flash_time
	flash_timer = flash_duration
	flash_target = target
	flash_has_target = target != null
	flash_target_gen = int(target.get("pool_gen")) if target != null and "pool_gen" in target else 0
	flash_started.emit(kind, flash_duration)


## Pooled projectiles are never freed, only recycled: "gone" = out of the tree or reused.
func target_alive() -> bool:
	if not is_instance_valid(flash_target):
		return false
	if flash_target is Node and not (flash_target as Node).is_inside_tree():
		return false
	return not ("pool_gen" in flash_target) or int(flash_target.get("pool_gen")) == flash_target_gen


## True if the player repeated the right input during the flash.
func consume_flash(kind: String, move_id: String) -> bool:
	if flash_timer <= 0.0 or flash_kind != kind or flash_move != move_id:
		return false
	var was_melee := flash_kind == "melee"
	flash_timer = 0.0
	flash_kind = ""
	flash_has_target = false
	flash_target = null
	if was_melee:
		melee_count = 0
		combo_timer = 0.0
	flash_ended.emit()
	return true


func cancel_flash() -> void:
	var was_active := flash_timer > 0.0 or flash_kind != ""
	if flash_kind == "melee":
		melee_count = 0
	flash_timer = 0.0
	flash_kind = ""
	flash_has_target = false
	flash_target = null
	if was_active:
		flash_ended.emit()


func start_afterburn() -> void:
	afterburn_timer = data.afterburn_duration


func clear_afterburn() -> void:
	afterburn_timer = 0.0
