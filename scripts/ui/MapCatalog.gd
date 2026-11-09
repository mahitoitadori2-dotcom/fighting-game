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
	for n in range(1, StoryLevels.count() + 1):
		var key := String(StoryLevels.get_level(n).get("map", ""))
		for k in [key, String(StoryLevels.get_level(n).get("boss_map", ""))]:
			if k == "" or seen.has(k) or SKIP.has(k) or not StoryLevels.MAPS.has(k):
				continue
			seen[k] = true
			var m: Dictionary = StoryLevels.MAPS[k]
			_cache.append({"id": "story_" + k, "name": String(m.get("zone", k)).capitalize(), "scene": STORY_SCENE, "map": k,
				"source": "Story Mode - Colosseum %d" % StoryLevels.colosseum_of(n), "desc": String(DESC.get(k, ""))})
	return _cache


static func entry(id: String) -> Dictionary:
	for e in entries():
		if e["id"] == id:
			return e
	return entries()[0]


# ============================================================
# PREVIEWS (thumbnails + the big preview): a SubViewport with the map's backdrop + its island
# ============================================================
## A preview of the map inside `parent`. live = keeps animating (big preview), else drawn once.
static func make_preview(e: Dictionary, size: Vector2i, live: bool) -> SubViewportContainer:
	var box := SubViewportContainer.new()
	box.stretch = true
	box.custom_minimum_size = Vector2(size)
	box.mouse_filter = Control.MOUSE_FILTER_IGNORE
	var vp := SubViewport.new()
	vp.size = size
	vp.disable_3d = true
	vp.transparent_bg = false
	vp.handle_input_locally = false
	vp.own_world_3d = true
	vp.world_2d = World2D.new()                       # Its own physics world: the preview island never touches the game
	vp.render_target_update_mode = SubViewport.UPDATE_ALWAYS if live else SubViewport.UPDATE_ONCE
	box.add_child(vp)
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
	if not live:
		g.set_process(false)
	return box
