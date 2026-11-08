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

## Open work

Some projectiles are not pooled yet. They are in the [To-do list](Todo.md).
