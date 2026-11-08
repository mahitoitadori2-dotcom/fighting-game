class_name Hurtbox
extends Area2D
## The BODY area: where a fighter can be hit. Same size as the body hitbox.
## Blue box in debug view.

var fighter: Fighter
var box_size := Vector2(64, 128)
var _shape: RectangleShape2D
var _col: CollisionShape2D


func setup(f: Fighter, size_px: Vector2) -> void:
	fighter = f
	box_size = size_px
	collision_layer = CombatManager.HURTBOX_LAYER
	collision_mask = 0
	monitoring = false
	monitorable = true
	z_index = 9
	_shape = RectangleShape2D.new()
	_shape.size = size_px
	_col = CollisionShape2D.new()
	_col.shape = _shape
	_col.position = Vector2(0, -size_px.y / 2.0)
	add_child(_col)


## Change the hurtbox size (feet-anchored). Used by Nightmare Lord's bat form.
func resize(size_px: Vector2) -> void:
	box_size = size_px
	_shape.size = size_px
	_col.position = Vector2(0, -size_px.y / 2.0)
	queue_redraw()


var _drawn_debug := false


## Only redraws when the F1 debug view is toggled (the box itself never moves locally).
func _process(_delta: float) -> void:
	if CombatManager.debug_boxes != _drawn_debug:
		_drawn_debug = CombatManager.debug_boxes
		queue_redraw()


func _draw() -> void:
	if not CombatManager.debug_boxes:
		return
	var r := Rect2(-box_size.x / 2.0, -box_size.y, box_size.x, box_size.y)
	draw_rect(r, Color(0.2, 0.6, 1.0, 0.15))
	draw_rect(r, Color(0.2, 0.6, 1.0, 0.9), false, 2.0)
