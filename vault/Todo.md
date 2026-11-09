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
- [ ] **Play Colosseum 2 yourself**, especially the Architect Chorus's Elevator Shake and Blasphemy Caeser's phase 2.
  - In `BlasphemyCaeser.gd`: `P1_HP` / `P2_HP`, pattern cooldowns and damage.
  - In `ArchitectChorus.gd`: HP, `JOLT_EVERY` and the slam numbers.
  - In `ChemicalPool.gd`: `LAVA_TICK_DAMAGE`.
  - In `WarriorData.gd`: the Warrior buff numbers and the sword growth (`sword_power_damage`, `sword_power_size`).
- [ ] **Play Colosseums 3 and 4 yourself.** Check the Architectian Titan, the Architect's Golem, both Shining choices, and the Void Massacre (VIGOROUS may still be too hard).
  - Boss numbers: HP / patterns in `ArchitectianTitan.gd`, `ArchitectsGolem.gd`, `VoidMassacre.gd`.
  - The Shining choice: `_apply_void_mod` in `StoryManager.gd` (weak 0.7x, strong 1.35x HP and 1.25x damage).
- [ ] Play Versus with the buffed Warrior and check he isn't too strong now.
- [ ] Play the 3 Fights-mode bosses yourself and tune them (`HP`, pattern cooldowns and damage, `phase2_*` in `scripts/enemies/bosses/`).
- [ ] Check whether Kharlemings can still stand on top of each other on level 5 (their name tags overlap).
- [ ] Test on a real iPhone 13: loading, touch controls, and audio after the tap.
- [ ] **Web on phones: check the page no longer reloads by itself** (reported 2026-11-09: it reloaded 1-3 minutes after opening). Play 5+ minutes on a phone, through several Story areas. See [Performance](Performance.md).
- [ ] Play the new Story levels (5, 7, 11, 14, 18, 21-23, 25, 33) and tune the new soldier weapons (`ArmedSoldier.gd`: HP per weapon, `FRONT_GUARD` of the great shield, arrow damage).
- [ ] Check the optional Shining level (32) both ways and by skipping it, then play level 34.
- [ ] Try the new **Touch UI Size** slider (Settings) on a phone and pick a good default.

## Website

- [ ] Decide on the domain: keep universalshowdown.com or register universalbeatdown.com.

## Game

- [ ] More playable fighters in Story Mode (only Warrior now).
- [ ] Add the Story enemies to the Enemy Test list in Versus.
- [ ] Real sprite or texture art, to replace the art that the code draws.
- [ ] Record real voice lines for Minos and Sisyphus (`audio/voice/`).
- [ ] Nicer art for Geyron's wings (they read a bit like a fan of spikes).
- [ ] Story Mode extras: difficulty settings, a level timer or score, unlockables.

## Performance

- [ ] Pool the other projectiles: Triangle Bomb, Void Goo, Oil Puddle, Throne, Nightmare Heart, Helper Minion.
