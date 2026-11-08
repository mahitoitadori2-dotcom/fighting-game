---
class: state
validity: current
type: guide
---

# To-do list

Back to [Summary](SUMMARY.md). Large plans are in the [Roadmap](Roadmap.md).

## Testing

- [ ] **Play Colosseum 1 yourself.** The tests used a CPU-controlled Warrior, so a human must tune the difficulty, especially the Blinded Lord.
  - In `BlindedLord.gd`: boss HP, `phase2_speed_mult` and `phase2_cooldown_mult`.
  - In `ChemicalPool.gd`: `TICK` and `TICK_DAMAGE`.
  - In `StoryManager.gd`: `MAX_ATTACKERS`.
- [ ] Test on a real iPhone 13: loading, touch controls, and audio after the tap.

## Website

- [ ] Decide on the domain: keep universalshowdown.com or register universalbeatdown.com.

## Game

- [ ] More playable fighters in Story Mode (only Warrior now).
- [ ] Add the Story enemies to the Enemy Test list in Versus.
- [ ] Real sprite or texture art, to replace the art that the code draws.
- [ ] Story Mode extras: difficulty settings, a level timer or score, unlockables.

## Performance

- [ ] Pool the other projectiles: Triangle Bomb, Void Goo, Oil Puddle, Throne, Nightmare Heart, Helper Minion.
