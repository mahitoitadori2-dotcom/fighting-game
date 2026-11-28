---
class: state
validity: current
type: reference
---

# Performance

Back to [Summary](SUMMARY.md).

## What the game does

- Projectiles, effects and chemical pools are reused (pooled). The game does not create and destroy them each time.
- At most 200 particles are alive at the same time (110 on phones). Over the limit, the oldest effect goes first.
- The game skips objects that are off the screen.
- Objects redraw only when they change.

The limits are in `scripts/OptimizationManager.gd`.

## Test result

The game runs at 60 FPS with 50 extra projectiles on the screen.

## Web on phones: the page reloaded by itself (2026-11-09)

On phones the web game reloaded 1-3 minutes after opening. Nothing in the page reloads on purpose, so the phone's browser was killing the tab (out of memory or GPU). A 150-second Story test on PC showed the game's own memory stays flat (about 110 MB, no growth), so the fixes target the browser side:

- **Music is released:** on the web every music track that played stayed decoded in the browser's audio memory, and Story Mode plays a new track for every area and boss. Old tracks are now dropped when they fade out and load again when needed (`SoundManager.gd`).
- **Lower render resolution on phones:** iPhones drew the canvas at 3x pixel density (about 2500 x 1170). Touch devices are now capped at about 1400 pixels on the long side (`web_shell/shell.html`).
- **GPU reset message:** if the phone still takes the graphics away, the page shows "The graphics were reset" with a RESTART button instead of a frozen or black screen.

**Status:** not yet confirmed on a real phone (see the [To-do list](Todo.md)).

## Graphics setting (added 2026-11-10)

Main Menu > SETTINGS > GRAPHICS has 4 levels. The choice is saved on the device. REGULAR is the default. The code is in `scripts/GraphicsSettings.gd`, loaded at start as the autoload "Graphics".

| Level | For | What changes |
|---|---|---|
| **Potato** | Really weak devices | Draws at 1280x720 and stretches it, 30 FPS cap, max 40 particles, about a third of the hit sparks, no trails, backgrounds update every 3rd frame, no clouds, lit windows, embers or void fog |
| **Fast** | Phones, old PCs | Draws at 1280x720 and stretches it, 60 FPS cap, max 90 particles, 60% sparks and trails, backgrounds update every 2nd frame, no far clouds or far void tentacles |
| **Regular** | Normal PCs | The original graphics |
| **Real** | Good PCs | Glow on bright things, 1.6x sparks, 1.5x longer trails, max 320 particles, no FPS cap |

- Changes apply at once, also in the middle of a menu.
- Smooth edges (MSAA / FXAA) are not possible: the Compatibility renderer the game uses does not support them, so Real uses glow instead.
- Story backgrounds other than the arena, Void and Hell/Story backdrops (embers) are not changed yet. They are mostly drawn once, so they cost little.
- **Not verified:** the goal of at least 40 FPS on an iPhone 11 with FAST. Checked only on PC (no errors, the visuals change as expected).

## Map Catalogue: crash / 1 FPS fixed (2026-11-10)

Every card in the Map Catalogue used to run its map's full animated backdrop (embers, scrolling and so on) live, about 30 at once. Opening the catalogue crashed the game or dropped it to about 1 FPS. Now each map is drawn once, one at a time, and kept as a still picture. Nothing moves while you browse, and the pictures are kept until you close the game, so opening the catalogue again is instant. The catalogue's background no longer scrolls either. The code is in `scripts/ui/MapCatalog.gd`.

**Status:** checked on PC (all 30 pictures appear, no errors). Not tested on a phone. Big previews are not kept after closing (only the small thumbnails are), so they can't pile up.

## iPhone web: low-memory crash (2026-11-10)

A memory probe visited every screen and Story levels 1-50: the game's own memory stays flat (no leak). The biggest waste was **text**: every font size and outline was cached as its own set of textures, and on hi-DPI screens even bigger copies.

- **One shared font atlas (MSDF)** for all sizes and outlines (`project.godot`, `gui/theme/default_font_multichannel_signed_distance_field`). Text looks the same. In a Story level, texture memory went from 40 MB to 9 MB, graphics memory from 51 MB to 21 MB, game memory from 148 MB to 122 MB (measured on PC).
- **Phones start on FAST graphics** (base-resolution render) instead of REGULAR. A choice saved in Settings still wins.
- **Sound in the background:** the web page now pauses the game's audio when the tab is hidden or the phone is locked, so iPhone no longer shows it "playing" in the background. It comes back when you return (`web_shell/shell.html`).
- **No sound in the browser:** the page now wakes the game's audio on every tap, click or key. Browsers can leave it paused because the engine starts its audio just after the Start tap. In Chrome on PC the sound worked both before and after the fix, so the original no-sound problem could not be reproduced here.

**Status:** not tested on a real iPhone yet. The web engine file itself is about 40 MB. If iPhones still crash, the next step is a slimmed custom web engine (3D and unused parts removed), built by GitHub Actions.

## iPhone 11 optimization pass (2026-11-12)

Measured on PC with FAST graphics (what phones use), FPS without a cap. The big cost on phones is **GPU draw calls** (each one is expensive in Safari's WebGL).

**What the engine batches:** 300 rectangles / plain lines / small triangles = 1 draw call. 300 circles or polygons = 300 calls. 300 SMOOTHED (antialiased) lines = **900** calls.

| Scene | Before | After | Draw calls |
|---|---|---|---|
| DemiLand | 28 FPS | 231 FPS | 10 890 -> 1 325 |
| DemiLand, camp fight | 21 FPS | 147 FPS | 11 622 -> 1 609 |
| Story fight (2D backdrop) | 121 FPS | 209 FPS | 1 947 -> 1 183 |
| Boss fight with 3D backdrop | 248 FPS | 475 FPS | 1 450 -> 786 |
| Main menu (3D) | 424 FPS | 475 FPS | 383 -> 358 |

- **The floor (`ArenaGround.gd`):** a very wide floor (DemiLand, 18 000 px) sent every grain, pebble and crack to the GPU every frame. Its details are now in 1200 px chunks; off-screen chunks are skipped. FAST / POTATO also drop the faint rock grain and pebble highlights.
- **Smooth lines only on REGULAR / REAL:** every art script now passes `FighterArt.AA` instead of `true` for line smoothing (436 calls in 91 files). FAST / POTATO draw plain lines (1 draw call instead of 3). The thick black outlines look almost the same.
- **Music at 22 kHz in the game package** (import setting `force/max_rate_hz=22050`): music 20.6 -> 14.3 MB, web package (`index.pck`, kept in the phone's memory) 22.6 -> 16.2 MB.
- **Still the biggest:** the web engine itself (`index.wasm`, 37.7 MB) - only a custom slimmed engine build would shrink it (3D is now used, so it can't simply be removed). Characters (~100+ draw calls each, made of circles and polygons) are the next cost if phones still lag.
- **Not tested on a real iPhone.**

## Whole-game sweep (2026-11-14)

`tools/game_sweep.tscn` plays EVERYTHING by itself (CPU): 7 menus, 50 Versus maps, 50 opponents + 6 fighters, Story 1-62 (boss levels also from the boss checkpoint), 15 Boss Extension levels, DemiLand, The Caves = 197 tests, ~35 min. One RESULT line per test (FPS, 1% low, worst frame, draw calls, nodes, memory); errors are logged per test. Back up the saves first. Run: `godot --audio-driver Dummy --path . --log-file sweep.log res://tools/game_sweep.tscn` (one part: `UB_SWEEP=menus|maps|versus|story|ext|demi`).

Result (PC, REGULAR, uncapped):
- **0 script errors** in all 197 tests. **No memory leak:** 155 MB after the menus, 158 MB at the end.
- **Fixed lag spots:** Character Select 23 -> 244 FPS (every portrait was redrawn every frame; now only the hovered / picked ones animate). Achievements 44 -> 1300 FPS, 6565 -> ~840 draw calls (each card's art is baked once into a texture). Test Arena 76 -> ~120-148 FPS and Void Arena 63 -> ~130-141 (the far backdrop layers are drawn once and slide; clouds / sparks / fog use batched textured dots: `scripts/Dots.gd`). Story board 72 -> ~160-180 FPS (idle redraw at 30 Hz).
- **FAST (phones):** every checked scene 212-358 FPS on this PC.
- **Still the heaviest:** DemiLand (~80 FPS REGULAR, ~210 FAST, ~3700 draw calls on REGULAR) and the C5 thorn / foothill levels (~150 FPS). Not measured on a real iPhone.

## Sweep + ground baking (2026-11-16)

**The full sweep: 235 tests, no crashes, memory flat** (166 → 168 MB). The newest parts were added to it: Orbis Terrarum and every scene of level 80.
- **The only error**, a "grab_focus while not in the tree", is fixed. Every screen now uses `UiStyle.focus_later()` instead of `grab_focus.call_deferred()`.

**The big cost was the GROUND** (`ArenaGround.gd`), in every arena and every open world.
- **The problem:** its tiny details (~430 grain dots per 1200 px, 3 circles per pebble, every crack, slab joint and chip) were one draw call each. The strata and paved-top pieces spanning the whole floor were also drawn one by one.
- **The fix:** the details are now **baked into one mesh per chunk**, and the strata + paved top into **one mesh for the whole floor**. The meshes are built once and rebuilt when the theme or graphics level changes. It looks the same (checked on screenshots).
- **Biome changes:** changing the ground look in an open world now redraws the chunks on screen at once and the rest 2 per frame. That removed the 150 ms hitch in Terra Ordinariorum.

**Before → after** (Windows PC, REGULAR graphics, CPU playing):

| Scene | Avg FPS | Worst 1% | Frames > 33 ms | Draw calls |
|---|---|---|---|---|
| DemiLand | 72 → 115 | 30 → 60 | 34 → 0 | 4302 → 1473 |
| Terra Craterum | 67 → 123 | 38 → 75 | 0 → 0 | 3940 → 1047 |
| Terra Ordinariorum | 50 → 72 | 29 → 40 | 84 → 0 | 3933 → 1364 |
| Storm Attacks fight | 79 → 144 | 27 → 34 | 37 → 2 | 3151 → 2272 |
| Versus / Story arenas | ~80-130 → ~250-380 | | | ~2100 → ~650 |

**Left as they are:**
- **Map Catalogue:** its slow frames are the one-time thumbnail renders.
- **Achievements menu:** a spike when it builds ~300 cards.
- **"No frames":** the first test of every sweep run shows it; that's the tool, not the game.

**Not measured yet:** on a real phone.

## Open work

Some projectiles are not pooled yet. They are in the [To-do list](Todo.md).

## iPhone memory reloads FIXED (2026-11-19)
User report: iPhone 13 50-60 FPS / iPhone 11 30-40 FPS on FAST; "the biggest problems are lags and THE MEMORY" (Safari reloads the tab).

**Measured** with the real web build in headless Chrome emulating an iPhone 13 (844x390, DPR 3, iPhone UA, muted), the hidden `?soak=1` mode (`scripts/debug/WebSoak.gd`: plays menus, Versus, Story levels, the open worlds, Boss Rush by itself) and a CDP script (process memory + WebAssembly / AudioBuffer / object breakdown, audio-output level):

| | before | after |
|---|---|---|
| page process | 637 -> 2005 MB in 6 min, climbing | 680-780 MB, flat (peak 856) over 8+ min |
| decoded audio (AudioBuffers) | 44 -> 636 MB, climbing | 18 MB, flat |
| JS heap after GC | climbing | 213 MB, flat after ~5 min |

**Cause:** on the web, Godot plays sounds as browser "samples": every MUSIC change decoded the track into a ~20 MB stereo WebAudio buffer that was never freed (not even after unregistering).
**Fixes:**
- Web music players use `PLAYBACK_TYPE_STREAM` (decoded a bit at a time inside the engine; `SoundManager._make_music_player`). Web audio latency 50 -> 100 ms (`audio/driver/output_latency.web`) against crackles. Sound effects stay samples (fixed set, cached once).
- Old music unregistered explicitly; achievement card pictures and Map Catalogue thumbnails freed when those screens close; web replays capped at 120 s.
- Phones: `display/window/dpi/allow_hidpi.web_ios / .web_android = false` (canvas at normal resolution, ~2.8x fewer pixels than the shell's 1.66x cap) and phones draw straight at screen size (no fixed 1280x720 target).
- Phones on FAST / POTATO: no 3D views (`Three.enabled`): no extra render targets, no shader-compile freezes.
- Phones: automatic LITE mode (`GraphicsSettings._process`): FPS < 45 for 2.5 s -> half the sparks / particles, backgrounds redrawn less; back above 56.
- Not yet confirmed on a real iPhone.
## 2026-11-20 - /nolags quick pass
- Measured (iPhone 13 web emulation, ?soak=perf): biggest per-frame game-code cost was the Achievements screen
  (50 ms "proc" while cards bake). Versus physics: the fighters' own scripts are only ~0.13 ms/frame (AI, actions,
  movement, move_and_slide all tiny) - the 9-14 ms "phys" on web is engine stepping, no script hotspot.
- Fix: AchievementCard and CharacterPortrait now bake a whole batch (12 / 8) on ONE hidden viewport with ONE
  get_image() readback, then cut it into pieces (before: one viewport + readback per card). Cells clip_contents.
- Achievements: proc 50.2 -> 39.3 ms, draws 208 -> 162. Its big frame spikes (~120 ms) are still there and are
  browser/render time - not fixed. Other screens: unchanged within noise.
- Checked: compile 0/290 failed; Character Select + Achievements render correctly (headless Chrome screenshot).
## /nolags 2026-11-22: The Hunt of a Nightmare backdrops baked into one mesh

The Hunt's backdrops (`HuntBackdrops.gd`: ~70 red lanterns, each 6 shapes, plus tents and ridges) were replayed as
hundreds of canvas commands every frame. `HellBackground` now records them ONCE per theme + screen size into a
`MeshCanvas` and draws one mesh. Same look (checked by screenshot). Web build, emulated iPhone 13 (headless Chrome):

| Scene | Draw calls | Game code | FPS |
|---|---|---|---|
| hunt 82 (waves) | 909 -> 350 | 23.6 -> 12.5 ms | 35 -> 48 |
| hunt 86 (Jester) | 839 -> 357 | 21.9 -> 12.2 ms | 49 -> 60 |
| hunt 95 (Guards) | 576 -> 509 | 14.3 -> 10.6 ms | 48 -> 48 |
| hunt 100 (Nightmare Lord) | 832 -> 350 | 21.9 -> 9.2 ms | 38 -> 48 |
| hunt 110 (Troupe's Heart) | 835 -> 354 | 22.8 -> 8.6 ms | 49 -> 57 |

Other backdrops (`HellBackground` themes, C5 / Ext / Demi / Crater / Ord) still replay their shapes each frame: the
same trick would help them too (e.g. DemiLand 658 draw calls, boss level 6 752).
## /nolags 2026-11-23: EVERY Story backdrop baked into one mesh

`HellBackground` now records the landscape of EVERY theme (65: Colosseums, Chase, extensions, open worlds,
Madness, the Hunt) ONCE per theme + screen size into a `MeshCanvas` and draws one mesh; the painting code draws
on `_p` (a MeshCanvas while baking). `MeshCanvas` gained `draw_arc` + `draw_set_transform`; a few shared
helpers (`FighterArt.outline` / `ball`, `StormArt.draw`, `EnlightenedFx._relic`) take any canvas now. Only the
embers still animate. Same look (screenshots of levels 6, 26, 48, 62 and DemiLand). Web, emulated iPhone 13:

| Scene | Draw calls | FPS |
|---|---|---|
| boss level 6 | 743 -> 591 | 44.8 -> 49.2 |
| boss level 34 | 477 -> 383 | (noise) |
| boss level 15 | 506 -> 427 | 44 -> 44 |
| Terra Ordinariorum | 561 -> 447 | 56.5 -> 58.4 |
| DemiLand | 646 -> 632 | 48 -> 52 |

Next biggest: Versus fights (~450-550 draw calls, ~11-14 ms physics with 2 fighters) and the Achievements grid
(773 nodes, 45-53 ms game code).
## /nolags 2026-11-25: The True Hunt

New hidden mode `?soak=perfth` (WebSoak `_run_perf_th`): an old Hunt level for comparison, four True Hunt levels
(disasters + ledges + partner) and the Nightmare Monstrosity at a full crowd (14 golems). Web, emulated iPhone 13,
**measured while the /speedtest crash sweep ran on the same PC** (all numbers a bit slow; compare rows, not absolutes).

| Scene | Before | After |
|---|---|---|
| Monstrosity crowd: nodes | 740-825 (grew to 1078: dead golems kept) | 281-394 |
| Monstrosity crowd: FPS | 11.5-11.9 | 12.0-12.2 (unchanged - see below) |
| Edge shading A/B (crowd) | on 11.5 | off 17.3 |
| Hunt 82 / True Hunt 113-122 FPS | 47.7 / 31-36 | 44-49 / 30-37 (noise) |

Kept:
- **Dead golems are freed** 2 s after they fall (the last one stays for the death cutscene). Blood / scorch marks
  leave with their fighter. Before: every one of the 127 golems stayed as a corpse with its own render group.
- **Model edge shading only on REGULAR / REAL graphics** (8 extra screen reads per pixel; phones start on FAST).
Tried and reverted (no measured gain): no pixel pass on small golems; fewer details on small golems.
**Still open:** the 14-golem crowd is ~12 FPS in SwiftShader - mostly RENDER time (one canvas group per fighter).
Real iPhone GPUs are much faster than SwiftShader, so test on a phone; if it is slow there too, lowering
`NightmareMonstrosity.MAX_ALIVE` (14) is the gameplay knob (the user's call).
## /nolags 2026-11-26: where the draw calls go (HUD + touch buttons batched)

New hidden mode `?soak=perfsplit` (WebSoak `_run_perf_split`): FREEZES a Story level (82 and 116) and hides one
kind of thing at a time, so every row sees the same frame (unfrozen windows were too noisy: +-100 draws).
Draw calls per frame, web, emulated iPhone 13:

| Piece | Draw calls |
|---|---|
| One HERO model (player or True Hunt partner) | ~172-180 (7 000 prims) |
| 3 regular enemies | ~132 (~44 each) |
| Story HUD (bars, flasks, texts) | 74-86 -> 58-70 |
| Touch buttons | 42 -> 9-13 |
| Backdrop embers layer | ~36 |
| True Hunt ledges / disaster strikes | ~9 each (cheap) |

So the True Hunt costs more than older levels ONLY because of the partner (one more hero).

Kept:
- **Story HUD** (`StoryHUD.gd`): all bars / gauge / flask shapes are recorded into ONE `MeshCanvas` mesh, the texts
  are drawn after it (no text sits on a shape: same look).
- **Touch buttons** (`TouchControls.gd`): shapes into meshes, texts after them, the 3 smooth rings keep their own
  antialiased draws; and they are only redrawn when something changes (press, stick, cooldown, ult glow).
  The cooldown sweep is now a clean pie slice (was a thick arc).
- **Bug found + documented in `MeshCanvas.gd`:** keep the built mesh in a member var. A mesh made inside `_draw`
  and dropped at the end renders NOTHING ("Parameter mesh is null" every frame).
Tried and reverted (no measured gain): sorting the HUD texts by font size.

Full `?soak=perf` before -> after (draw calls; FPS in SwiftShader is noisy): boss 15 442->416, 26 385->360,
45 658->623, 48 552->533, 50 680->645, 56 547->498, hunt 82 455->432, DemiLand 639->615, Ordinariorum 829->812.
Versus fights unchanged (~470-540). Checked by phone screenshot (True Hunt 113: HUD + buttons look right).

**Biggest cost left: the hero models** (~175 draw calls each, every polygon / outline its own draw call). The
fix would be recording each model into a MeshCanvas every frame: ~120 `draw_model_on(c: CanvasItem)` scripts +
art helpers would need to accept a MeshCanvas, and the per-frame GDScript cost must be measured first. A
project of its own, not a /nolags round.
