class_name Hitbox
extends Area2D
## The ATTACK area. Activate it with a HitData and it hits every Hurtbox it
## overlaps (once each per activation). Red box in debug view.

signal hit_landed(victim: Fighter, hit: HitData, result: String)

var owner_fighter: Fighter
var hit_data: HitData
var active := false
var box_size := Vector2(56, 32)

var _hit_list: Array[Fighter] = []
var _shape: RectangleShape2D
var _ghost := 0.0


func setup(f: Fighter) -> void:
	owner_fighter = f
	collision_layer = 0
	collision_mask = CombatManager.HURTBOX_LAYER
	monitoring = false
	monitorable = false
	z_index = 10
	_shape = RectangleShape2D.new()
	var col := CollisionShape2D.new()
	col.shape = _shape
	add_child(col)


## center is relative to the fighter's feet (already multiplied by facing).
func activate(hd: HitData, center: Vector2, size_px: Vector2) -> void:
	hit_data = hd
	box_size = size_px
	_shape.size = size_px
	position = center
	_hit_list.clear()
	active = true
	monitoring = true


func deactivate() -> void:
	if active:
		_ghost = 0.12
	active = false
	monitoring = false


func _physics_process(_delta: float) -> void:
	if not active:
		return
	if owner_fighter != null and owner_fighter.is_time_frozen():
		return                # Frozen by Time Stop: attacks hang in place
	for area in get_overlapping_areas():
		var hb := area as Hurtbox
		if hb == null or hb.fighter == owner_fighter or hb.fighter.is_dead \
				or CombatManager.passes_through(owner_fighter, hb.fighter):    # Allies: swing / grab passes through
			continue
		if _hit_list.has(hb.fighter):
			continue
		_hit_list.append(hb.fighter)
		var result := CombatManager.apply_hit(hit_data, hb.fighter)
		hit_landed.emit(hb.fighter, hit_data, result)
		if not active:      # A listener (e.g. drill grab) may have deactivated us
			return


var _drawn_debug := false


## Redraws only while the F1 debug view is on (plus once when it is turned off).
func _process(delta: float) -> void:
	_ghost = maxf(_ghost - delta, 0.0)
	if CombatManager.debug_boxes or _drawn_debug:
		_drawn_debug = CombatManager.debug_boxes
		queue_redraw()


func _draw() -> void:
	if not CombatManager.debug_boxes:
		return
	var r := Rect2(-box_size / 2.0, box_size)
	if active:
		draw_rect(r, Color(1.0, 0.1, 0.1, 0.40))
		draw_rect(r, Color(1.0, 0.2, 0.2, 1.0), false, 2.0)
	elif _ghost > 0.0:
		draw_rect(r, Color(1.0, 0.1, 0.1, 0.12))
