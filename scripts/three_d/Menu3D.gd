class_name Menu3D
extends RefCounted
## 3D MENU BACKGROUND (every menu that uses ArenaBackground: Main Menu, Character Select,
## Pre-fight, Settings, Map Catalogue, Achievements): a SLIDESHOW of the game's big arenas in 3D
## (Maps3D), each with its BOSS standing in it (Boss3D), the camera drifting slowly past. Every
## SLIDE_TIME seconds it fades to the next one. Only one slide exists at a time (the old 3D world
## is freed before the next is built), so memory stays flat. No fighters / 2D pictures on it.

const SLIDE_TIME := 8.0
const FADE := 0.7
## [map theme (Maps3D), boss id (Boss3D), boss height]
const SLIDES := [
	["blasphemy", "blasphemy_caeser", 7.5],
	["spider_lair", "void_massacre", 5.0],
	["world_tree", "mother_nature", 6.5],
	["lab", "blinded_lord", 5.5],
	["satan_cave", "satan", 7.0],
	["golem_hall", "arch_golem", 7.5],
	["sun_peak", "the_sun", 7.0],
	["prime_sanctum", "first_prime", 5.5],
	["sky_reliquary", "enlightened_one", 5.0],
]


## Builds the slideshow into `layer` (an ArenaBackground). dim = dark overlay 0..1 under the
## menu buttons. (`_fighters` is no longer used: nobody stands on the menu background now.)
static func build(layer: CanvasLayer, dim: float, _fighters: bool = false) -> Node:
	var show := Slideshow.new()
	show.layer_ref = layer
	show.dim = dim
	layer.add_child(show)
	return show


class Slideshow extends Node:
	var layer_ref: CanvasLayer
	var dim := 0.0
	var _index := 0
	var _t := 0.0
	var _box: Control                     # The current slide's SubViewportContainer
	var _stage: Stage3D
	var _fade: ColorRect
	var _switching := false

	func _ready() -> void:
		var shade := ColorRect.new()                          # Darkens the slide under the menu
		shade.color = Color(0, 0, 0, dim)
		shade.mouse_filter = Control.MOUSE_FILTER_IGNORE
		shade.set_anchors_and_offsets_preset(Control.PRESET_FULL_RECT)
		layer_ref.add_child(shade)
		_fade = ColorRect.new()                               # Black fade between slides
		_fade.color = Color(0, 0, 0, 1)
		_fade.mouse_filter = Control.MOUSE_FILTER_IGNORE
		_fade.set_anchors_and_offsets_preset(Control.PRESET_FULL_RECT)
		layer_ref.add_child(_fade)
		_index = randi() % SLIDES.size()                      # Every visit starts somewhere else
		_show_slide()
		create_tween().tween_property(_fade, "color:a", 0.0, FADE)

	func _process(delta: float) -> void:
		_t += delta
		if _stage != null:
			var k := clampf(_t / SLIDE_TIME, 0.0, 1.0)            # Slow drift past the boss
			_stage.camera.position = Vector3(lerpf(-6.0, 6.0, k), 3.0 + sin(_t * 0.4) * 0.3, 7.0 - k * 1.5)
			_stage.camera.look_at(Vector3(0.0, 3.2, -12.0), Vector3.UP)
		if _t >= SLIDE_TIME and not _switching:
			_next()

	func _next() -> void:
		_switching = true
		var tw := create_tween()
		tw.tween_property(_fade, "color:a", 1.0, FADE)
		await tw.finished
		if not is_inside_tree():
			return
		_index = (_index + 1) % SLIDES.size()
		_show_slide()
		_t = 0.0
		var tw2 := create_tween()
		tw2.tween_property(_fade, "color:a", 0.0, FADE)
		_switching = false

	func _show_slide() -> void:
		if _box != null and is_instance_valid(_box):
			_box.queue_free()                                  # Only one 3D world at a time
		var s: Array = SLIDES[_index]
		_stage = Three.view(layer_ref)
		_box = _stage.get_parent().get_parent() as Control     # Stage3D -> SubViewport -> SubViewportContainer
		layer_ref.move_child(_box, 0)                          # Under the shade + fade
		Maps3D.build(_stage, String(s[0]))
		_stage.camera.fov = 50.0
		var b := Boss3D.make(_stage, String(s[1]), Vector3(0, 0, -12), float(s[2]))
		b.face(Vector3(0, 0, 1))                               # Looking at you
		b.set_pose("menace")
