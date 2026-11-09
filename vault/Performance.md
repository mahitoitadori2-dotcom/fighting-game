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

## Open work

Some projectiles are not pooled yet. They are in the [To-do list](Todo.md).
