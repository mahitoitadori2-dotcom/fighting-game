class_name Backdrop3D
extends CanvasLayer
## 3D BACKGROUND behind the (2D) fight on the IMPORTANT maps (Maps3D.IMPORTANT: the boss
## arenas). Replaces the flat HellBackground painting while it is up. The 3D camera slides a
## little with the 2D fight camera (parallax), so the arena has real depth behind you.
##
##   Backdrop3D.apply(scene_node, theme, centre_x)   call whenever a map is applied

const PARALLAX := 0.006                  # 3D units per 2D pixel of camera movement

var theme := ""
var center_x := 576.0
var _stage: Stage3D


## Puts up (or removes) the 3D backdrop for `theme` in `scene` (the arena scene's root).
static func apply(scene: Node, p_theme: String, p_center_x: float = 576.0) -> void:
	if scene == null:
		return
	var old := scene.get_node_or_null("Backdrop3D")
	if old != null:
		old.name = "Backdrop3D_old"                 # Free the name for the new one (same frame)
		old.queue_free()
	var bg := scene.get_node_or_null("Background") as CanvasLayer
	var use := Three.enabled() and Maps3D.important(p_theme)
	if bg != null:
		bg.visible = not use                       # The flat painting only when there is no 3D
	if not use:
		return
	var b := Backdrop3D.new()
	b.name = "Backdrop3D"
	b.theme = p_theme
	b.center_x = p_center_x
	scene.add_child.call_deferred(b)                  # The arena may still be setting itself up


func _ready() -> void:
	layer = -10
	_stage = Three.view(self)
	Maps3D.build(_stage, theme)
	_stage.camera.fov = 50.0


func _process(_delta: float) -> void:
	var cam := get_viewport().get_camera_2d()
	var dx := 0.0
	if cam != null:
		dx = (cam.get_screen_center_position().x - center_x) * PARALLAX
	_stage.camera.position = Vector3(dx, 3.4, 13.0)
	_stage.camera.look_at(Vector3(dx * 0.6, 3.0, -12.0), Vector3.UP)
