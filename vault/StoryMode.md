---
class: state
validity: current
type: reference
---

# Story Mode

Back to [Summary](SUMMARY.md).

Story Mode has 50 levels in 8 Colosseums. Level 50 is **The Sun**. Colosseum 1 (levels 1-6) is playable. The plan for levels 7-50 is in the [Roadmap](Roadmap.md).

## Level select

The level select is a board game. When you clear a level, your pawn hops forward. Then you fall through the caves to the next level.

## Colosseum 1

| Level | Title | Map | Enemies |
|---|---|---|---|
| 1 | The Ashen Gate | Ashen Wastes | Parasite |
| 2 | Brute March | Ashen Wastes | Parasites, Demon Brute |
| 3 | The Mutant Pit | Ashen Wastes | Demon Brutes, Hydra-Mutant |
| 4 | The Geode Cavern | Geode Cavern | Rock Golem |
| 5 | The Kharleming Hive | Kharleming Hive | Kharlemings (they climb walls) |
| 6 | The Blinded Lord | Lava Lair, then the Blinded Lord's Laboratory | Group waves, then the boss |

The level data is in `scripts/story/StoryLevels.gd`.

## Rules

- Enemies come in group battles (waves).
- You get 2 flasks for each level. Press **R** to drink one. A flask heals 50% of your max HP.
- At most 2 enemies attack at the same time.
- Progress saves after each level.
- Only Warrior is playable in Story Mode.

## The Blinded Lord (boss of level 6)

The boss level has an intro cutscene, the boss fight and a death cutscene.

- **Phase 1:** he throws chemical pools.
- **Phase 2:** he becomes CRAZED and fights in melee: Jug Smash, Wild Swings and Charge.

Difficulty settings for the boss are in the [To-do list](Todo.md).
