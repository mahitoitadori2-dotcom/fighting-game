class_name VersusMap
extends Node2D
## Dresses the generic Versus scene (scenes/StoryMapArena.tscn) as the Story map picked in
## the Map Catalogue / Main Menu (ArenaManager.selected_arena = "story_<map key>"):
## the map's backdrop, floor theme and fog. Walls and solid cave rock are left out on purpose:
## Versus is fought on a floating island, so you can still knock each other off.
## Runs before ArenaManager (it is above it in the scene tree).


func _ready() -> void:
	var e := MapCatalog.entry(ArenaManager.selected_arena)
	var key := String(e.get("map", ""))
	if key == "":
		key = "wastes"
	var m: Dictionary = StoryLevels.MAPS.get(key, StoryLevels.MAPS["wastes"])
	var bg := get_parent().get_node_or_null("Background") as HellBackground
	if bg != null:
		bg.theme = String(m.get("bg", "surface"))
	var ground := get_parent().get_node_or_null("ArenaGround") as ArenaGround
	if ground != null:
		ground.ground_theme = int(m.get("ground", 2))
		ground.solid = false
	# IMPORTANT maps (boss arenas) get their 3D background in Versus too
	Backdrop3D.apply.call_deferred(get_parent(), String(m.get("bg", "")), ground.position.x if ground != null else 576.0)
	if bool(m.get("fog", false)) and ground != null:
		var fog := StoryFog.new()
		fog.half_width = ground.width * 0.5
		get_parent().add_child.call_deferred(fog)
		fog.position = ground.position
