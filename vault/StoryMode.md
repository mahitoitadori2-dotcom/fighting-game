---
class: state
validity: current
type: reference
---

# Story Mode

Back to [Summary](SUMMARY.md).

Story Mode has 50 levels in 8 Colosseums. Level 50 is **The Sun**. Colosseums 1 and 2 (levels 1-12) are playable. The plan for levels 13-50 is in the [Roadmap](Roadmap.md).

## Level select

The level select is a board game with one page per Colosseum. When you clear a level, your pawn hops forward. After the boss of a Colosseum, the pawn moves on to the next page. Switch pages by clicking the fog space (next Colosseum) or the "< 6" mark (back), or with Left / Right.

A save that already beat Colosseum 1 (from before Colosseum 2 existed) unlocks Level 7 automatically.

## Colosseum 1: The Ashen Depths

| Level | Title | Map | Enemies |
|---|---|---|---|
| 1 | The Ashen Gate | Ashen Wastes | Parasite |
| 2 | Brute March | Ashen Wastes | Parasites, Demon Brute |
| 3 | The Mutant Pit | Ashen Wastes | Demon Brutes, Hydra-Mutant |
| 4 | The Geode Cavern | Geode Cavern | Rock Golem |
| 5 | The Kharleming Hive | Kharleming Hive | Kharlemings (they climb walls) |
| 6 | The Blinded Lord | Lava Lair, then the Blinded Lord's Laboratory | Group waves, then the boss |

**The Blinded Lord** (boss of level 6): intro cutscene, boss fight, death cutscene.

- **Phase 1:** he throws chemical pools.
- **Phase 2:** he becomes CRAZED and fights in melee: Jug Smash, Wild Swings and Charge.

## Colosseum 2: The Ascent

| Level | Title | Map | What happens |
|---|---|---|---|
| 7 | The Elevator from Hell | Elevator (steel platform rising up a shaft) | Intro cutscene of the elevator ride, then the mini-boss **Architect Chorus** |
| 8 | Home of the Enlightened Ones | Enlightened city (white marble, gold domes) | 2 rounds: Enlightened Guards (spear, sun shield) and Followers (Halo Wave, Radiant Palm) |
| 9 | The Golden Court | Enlightened city | 2 rounds of Guards and Followers |
| 10 | The Sewers | Sewers (bricks, pipes, green fog) | Cutscene of falling into the sewers; 1 round of only God Crawlers and Rot Strays |
| 11 | The Rot Channel | Sewers | 1 round of only God Crawlers and Rot Strays |
| 12 | Blasphemy Caeser | Blasphemy Arena (volcanic temple, serpent skeleton) | Pre-fight intro, 2-phase boss **Blasphemy Caeser**, then the corpse-climb ending cutscene |

**Architect Chorus** (mini-boss, 150 HP): a giant robot in The Mighty Architect's colours (white plates, green hands and trim, dark visor, blue core). It towers behind the elevator and grabs it.

- Hit its glowing core, or its hands while they rest on the platform after a slam.
- Attacks: Hand Slam, Double Hand Slam (both send shockwaves along the floor), Rock Throw (block or dodge), Elevator Shake (be in the air on each jolt; rocks fall from above).
- It overheats below 50% HP. When beaten, it lets go and falls back down the shaft.

**Blasphemy Caeser** (boss): a huge gray-scaled serpent with magma between its scales. Each phase has its own full HP bar.

- **Phase 1, The God-Devouring Serpent** (280 HP, no crown): Fire Breath, Serpent Bite, Tail Swipe (jump it), Magma Spit (leaves lava pools).
- **Transform:** at 0 HP a cutscene plays. He grows arms, a face with a burning laurel crown pushes out of his neck, and he pulls a giant flesh-covered **Blasphemy Blade** out of his throat.
- **Phase 2, The Blasphemy Blade** (340 HP): Blade Slash, Serpent Head Bite, Magma Geysers, Magma Spit, Lava Pools, Ground Slam, Lava Wave (jump it).
- When beaten, he sinks into the magma. Then you climb his corpse to a glowing shrine.
- **Your sword grows during this fight:** bigger and stronger when the fight starts (7 damage) and again in phase 2 (8 damage).

The level and map data is in `scripts/story/StoryLevels.gd`. The full-screen cutscenes are in `scripts/story/StoryCutscene.gd`.

## Rules

- Enemies come in group battles (waves). Normal enemies only have small HP bars above them; bosses also get a big HP bar at the top.
- You get 2 flasks for each level. Press **R** to drink one. A flask heals 50% of your max HP. Flasks refill after each boss intro.
- At most 2 enemies attack at the same time.
- Progress saves after each level.
- Only Warrior is playable in Story Mode.

## Testing

All levels 1-12 were cleared by a CPU-controlled Warrior (autoplay; it takes only 25% damage). Every Colosseum 2 map and both Caeser forms were checked in screenshots. Nobody has played Colosseum 2 by hand, and the cutscenes and music were not watched or heard in real time. Difficulty settings are in the [To-do list](Todo.md).
