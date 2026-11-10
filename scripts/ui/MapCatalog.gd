class_name MapCatalog
extends RefCounted
## EVERY MAP in the game, for Versus fights and the Map Catalogue screen:
##   * the 2 Versus arenas (Test Arena, Void Arena)
##   * every Story Mode map from Colosseums 1-5 (StoryLevels.MAPS), played in Versus through
##     one generic scene (StoryMapArena.tscn + VersusMap.gd: backdrop, floor, fog). In Versus
##     they are floating islands (no cave walls), so you can still be knocked off.
## Near-duplicate Story maps (same look, only different music) are left out.
##
## Arena entry: {id, name, scene, desc, source, map (story key or ""), bg, ground}

const STORY_SCENE := "res://scenes/StoryMapArena.tscn"
const SKIP := ["magma_stair", "rune_gallery"]          # Same look as "blasphemy" / "golem_hall"

## Short description of each Story map (shown in the catalogue and on the menu).
const DESC := {
	"wastes": "A burning wasteland: blood-red sky, ash clouds, an erupting volcano.",
	"geode": "A cavern of giant amethyst geodes glowing violet.",
	"hive": "The Kharleming nest: scrap heaps, cables, blinking cyan eyes.",
	"lair": "Deep caves with lava falls and rock pillars.",
	"lab": "The Blinded Lord's laboratory: glass chambers and toxic green tubes.",
	"elevator": "A steel elevator platform rising up a shaft out of hell.",
	"enlightened": "Home of the Enlightened Ones: white marble, gold domes, a huge sun.",
	"sewers": "Brick tunnels, pipes of dirty water and green fog.",
	"blasphemy": "Blasphemy Caeser's volcanic temple, a serpent skeleton coiled around it.",
	"throne": "An empty throne room on fire, smoke under the ceiling.",
	"architectium": "The Minor Architectium: stone workshops, cranes and turning gears.",
	"workshop": "The Blast Workshop: furnaces and molten metal.",
	"golem_hall": "The Architect's runic stone hall.",
	"dark_cave": "An overground dark cave lit by a dim light from its mouth.",
	"void": "Nothing but dark and a floor of bones.",
	"altar": "A glowing altar of light alone in the void.",
	"spider_lair": "Webs everywhere and victims hanging in cocoons.",
	"thornwood": "A dead forest of black thorns under a red sky.",
	"ruins": "Broken temples and aqueducts under a huge pale moon.",
	"foothills": "Snowy mountain slopes, the glowing peak far above.",
	"silk_loom": "The Child Wielding Needle's attic of giant spools and silk.",
	"mirror_hall": "The Brothers' perfectly symmetrical black-and-white hall.",
	"beast_den": "The Animal Lord's den of hides and bones.",
	"gallows": "The Executor's gallows under a blood moon, purple fog.",
	"world_tree": "Mother Nature's giant world tree in four seasons at once.",
	"ash_cathedral": "The False God's black cathedral with a burning altar.",
	"satan_cave": "Satan's mountain cave of lava and a throne of horns.",
	"sun_peak": "The Sun Peak, above the clouds in blinding light.",
	# Boss extensions
	"crypts": "The Caeser's crypts: serpent idols, bone niches and candles under the arena.",
	"caeser_tomb": "The Caeser's Tomb: a broken coffin under a ribcage of serpent bones.",
	"saint_rocks": "The Saint Rocks: a sanctuary of living rock and golden runes high above the Golem's Hall.",
	"saint_sanctum": "The Saint Sanctum: runes and Architect metal, where the Golem was rebuilt.",
	"deep_void": "Deeper into the Void: webs, hanging cocoons and crawling victims.",
	"horrid_nest": "The Horrid Nest: a web cathedral full of white eyes in the dark.",
	"reactor_waste": "The radioactive wasteland around the exploded reactor.",
	"reactor_core": "The Reactor Core: a melted reactor glowing green.",
	"the_forge": "The Forge: catwalks, coal chutes, ovens and rivers of molten metal.",
	"forge_heart": "The Heart of the Forge: a giant crucible of molten metal.",
}

static var _cache: Array = []


## Every playable Versus arena, in order (Versus arenas first, then Colosseum 1 -> 5).
static func entries() -> Array:
	if not _cache.is_empty():
		return _cache
	_cache = [
		{"id": "test", "name": "Test Arena", "scene": "res://Main.tscn", "map": "", "source": "Versus",
			"desc": "Floating stone island under the Hexagon towers"},
		{"id": "void", "name": "Void Arena", "scene": "res://scenes/VoidArena.tscn", "map": "", "source": "Versus",
			"desc": "Black rock, green fog and void tentacles"},
	]
	var seen := {}
	var levels: Array = range(1, StoryLevels.count() + 1)
	for k in StoryLevels.EXT_ORDER:                     # Boss extension arenas (fight + boss arena each)
		var first := int(StoryLevels.EXTENSIONS[k]["first"])
		levels.append_array([first, first + 1, first + 2])
	for n: int in levels:
		var key := String(StoryLevels.get_level(n).get("map", ""))
		for k in [key, String(StoryLevels.get_level(n).get("boss_map", ""))]:
			if k == "" or seen.has(k) or SKIP.has(k) or not StoryLevels.MAPS.has(k):
				continue
			seen[k] = true
			var m: Dictionary = StoryLevels.MAPS[k]
			var src := "Story Mode - Colosseum %d" % StoryLevels.colosseum_of(n)
			if StoryLevels.is_ext(n):
				var ek := StoryLevels.ext_of(n)
				src = "Story Mode - %s Extension (%s)" % [String(StoryLevels.EXTENSIONS[ek]["name"]).capitalize(), ek]
			_cache.append({"id": "story_" + k, "name": String(m.get("zone", k)).capitalize(), "scene": STORY_SCENE, "map": k,
				"source": src, "desc": String(DESC.get(k, ""))})
	return _cache


static func entry(id: String) -> Dictionary:
	for e in entries():
		if e["id"] == id:
			return e
	return entries()[0]


# ============================================================
# PREVIEWS (thumbnails + the big preview): STILL PICTURES
# Each map is rendered ONCE, one map at a time, in a hidden SubViewport (backdrop + island),
# copied into a plain ImageTexture and the viewport is freed straight away. Nothing animates
# and no backdrop keeps running while browsing. Thumbnails are cached for the whole session,
# so re-opening the catalogue is instant (big previews are not: they are large).
# ============================================================
static var _shots := {}          # "id@WxH" -> Texture2D
static var _queue: Array = []    # [TextureRect, entry, size, keep]
static var _busy := false


## A still picture of the map. It fills in as soon as it is rendered (instantly if cached).
## big = the large preview: jumps the queue and is NOT kept after it closes (a big
## picture is ~3 MB; keeping one per map would pile up on phones).
static func make_preview(e: Dictionary, size: Vector2i, big: bool = false) -> TextureRect:
	var tr := TextureRect.new()
	tr.custom_minimum_size = Vector2(size)
	tr.expand_mode = TextureRect.EXPAND_IGNORE_SIZE
	tr.stretch_mode = TextureRect.STRETCH_KEEP_ASPECT_COVERED
	tr.mouse_filter = Control.MOUSE_FILTER_IGNORE
	var key := _shot_key(e, size)
	if _shots.has(key):
		tr.texture = _shots[key]
		return tr
	if big:
		_queue.push_front([tr, e, size, false])
	else:
		_queue.append([tr, e, size, true])
	if not _busy:
		_pump()
	return tr


static func _shot_key(e: Dictionary, size: Vector2i) -> String:
	return "%s@%dx%d" % [e["id"], size.x, size.y]


## Renders the queued pictures one after another (only one map exists at any time).
static func _pump() -> void:
	_busy = true
	var tree := Engine.get_main_loop() as SceneTree
	while not _queue.is_empty():
		var job: Array = _queue.pop_front()
		var tr: TextureRect = job[0]
		if not is_instance_valid(tr):                 # Left the catalogue / closed the preview
			continue
		var key := _shot_key(job[1], job[2])
		var tex: Texture2D = _shots.get(key)
		if tex == null:
			tex = await _render(tree, job[1], job[2])
			if bool(job[3]):
				_shots[key] = tex                         # Thumbnails are kept (small)
		if is_instance_valid(tr):
			tr.texture = tex
	_busy = false


static func _render(tree: SceneTree, e: Dictionary, size: Vector2i) -> Texture2D:
	var vp := SubViewport.new()
	vp.size = size
	vp.disable_3d = true
	vp.transparent_bg = false
	vp.handle_input_locally = false
	vp.gui_disable_input = true
	vp.world_2d = World2D.new()                       # Its own physics world: the preview island never touches the game
	vp.render_target_update_mode = SubViewport.UPDATE_ALWAYS
	_fill(vp, e, size)
	tree.root.add_child.call_deferred(vp)            # Deferred: the first request comes while the scene is still setting up
	await tree.process_frame
	await RenderingServer.frame_post_draw
	var img := vp.get_texture().get_image()
	vp.queue_free()
	return ImageTexture.create_from_image(img)


## The map's backdrop + its island, scaled to `size`.
static func _fill(vp: SubViewport, e: Dictionary, size: Vector2i) -> void:
	var key := String(e.get("map", ""))
	var theme := 2
	if key == "":
		var bg: CanvasLayer = VoidBackground.new() if e["id"] == "void" else ArenaBackground.new()
		vp.add_child(bg)
		theme = 1 if e["id"] == "void" else 0
	else:
		var m: Dictionary = StoryLevels.MAPS.get(key, {})
		var hb := HellBackground.new()
		hb.theme = String(m.get("bg", "surface"))
		vp.add_child(hb)
		theme = int(m.get("ground", 2))
	var g := ArenaGround.new()
	g.width = 2400.0
	g.depth = 300.0
	g.ground_theme = theme
	var k := float(size.x) / 2700.0
	g.scale = Vector2(k, k)
	g.position = Vector2(float(size.x) * 0.5, float(size.y) * 0.74)
	vp.add_child(g)
