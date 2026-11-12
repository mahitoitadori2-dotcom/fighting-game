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

## Open work

Some projectiles are not pooled yet. They are in the [To-do list](Todo.md).
