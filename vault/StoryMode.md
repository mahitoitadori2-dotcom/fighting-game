---
class: state
validity: current
type: reference
updated: 2026-11-09
---

# Story Mode

Back to [Summary](SUMMARY.md).

Story Mode has 50 levels. Level 50 is **The Sun**. The Colosseums have different sizes now. Colosseums 1-4 (levels 1-34) are playable. The plan for the rest is in the [Roadmap](Roadmap.md).

| Colosseum | Levels | Count | Areas (levels each) |
|---|---|---|---|
| 1 The Ashen Depths | 1-6 | 6 | Ashen Wastes 2, Geode Cavern 1, Kharleming Hive 1, Lava Lair 2 |
| 2 The Ascent | 7-15 | 9 | Elevator 2, Enlightened city 3, Sewers 2, Blasphemy 2 |
| 3 The Burning Crown | 16-26 | 11 | Burning Throne 3, Minor Architectium 3, Blast Workshop 3, Golem's Hall 2 |
| 4 The Void Below | 27-34 | 8 | Dark Cave 2, Void 3, Altar 1 (optional), Spider Lair 2 |

The sizes are set in `COLOSSEUM_SIZES` in `scripts/story/StoryLevels.gd`. All the level and map data is in that file. The full-screen cutscenes are in `scripts/story/StoryCutscene.gd`.

## Level select

The level select is a board game with one page per Colosseum. Bigger Colosseums get a zig-zag path. The area names and tile colours come from each level's map. When you clear a level, your pawn hops forward. After the boss, it moves on to the next page. Switch pages with the fog space (next Colosseum), the "< N" mark (back), or Left / Right.

**Old saves** (from when every Colosseum had 6 levels) move to the matching level of the new layout the first time they load.

## Underground floors

Caves and sewers no longer float. Solid rock fills everything under the floor in the Geode Cavern, the Kharleming Hive, the Lava Lair, the Laboratory, the Sewers and the Dark Cave.

## Colosseum 1: The Ashen Depths (1-6)

| Level | Title | Map | Enemies |
|---|---|---|---|
| 1 | The Ashen Gate | Ashen Wastes | Parasites |
| 2 | The Mutant March | Ashen Wastes | Parasites, Demon Brutes, Hydra-Mutant (the old levels 2 and 3 combined) |
| 3 | The Geode Cavern | Geode Cavern | Parasites, then a Rock Golem |
| 4 | The Kharleming Hive | Kharleming Hive | Kharlemings (they climb walls) |
| 5 | The Burning Tunnels (new) | Lava Lair | Kharlemings, Demon Brute, Parasites, Hydra-Mutant |
| 6 | The Blinded Lord | Lava Lair, then the Laboratory | Group waves, then the boss |

**The Blinded Lord** (boss): phase 1 throws chemical pools; phase 2 is CRAZED melee (Jug Smash, Wild Swings, Charge).

## Colosseum 2: The Ascent (7-15)

| Level | Title | Map | What happens |
|---|---|---|---|
| 7 | The Elevator Shaft (new) | Elevator | Elevator cutscene; Kharlemings and Parasites climb after you |
| 8 | The Elevator from Hell | Elevator | Mini-boss **Architect Chorus** |
| 9 | Home of the Enlightened Ones | Enlightened city | Guards, Followers, then Blades (short sword) |
| 10 | The Golden Court | Enlightened city | Smiters (hammer), Archers (bow), Blades |
| 11 | The Hall of Shields (new) | Enlightened city | Bulwarks (great shield) with Archers behind them |
| 12 | The Sewers | Sewers | Fall-into-the-sewers cutscene; God Crawler and Rot Strays |
| 13 | The Rot Channel | Sewers | God Crawlers and Rot Strays |
| 14 | The Magma Stair (new) | Blasphemy temple | Demon Brutes, Hydra-Mutant, Parasites |
| 15 | Blasphemy Caeser | Blasphemy Arena | 2-phase boss, then the corpse-climb cutscene |

- **Architect Chorus** (150 HP): hit the core or the resting hands. Hand Slam, Double Slam, Rock Throw, Elevator Shake. Falls back down the shaft when beaten.
- **Blasphemy Caeser**: phase 1 serpent (280 HP), transform cutscene, phase 2 with the Blasphemy Blade (340 HP). Your sword grows when the fight starts and again in phase 2.

## Colosseum 3: The Burning Crown (16-26)

| Level | Title | Map | What happens |
|---|---|---|---|
| 16 | The Burning Throne | Burning Throne Room | Wake-up cutscene; AMBUSH of Copper Corpses and Sparklings |
| 17 | The Atomic Creation | Burning Throne Room | The Atomic Creation with Sparklings |
| 18 | The Cinder Gallery (new) | Burning Throne Room | Copper Corpses and Sparklings |
| 19 | Minor Architectium | Architectium | Architectian Warriors, then Swordsmen |
| 20 | The Gearworks | Architectium | Lancers (spear), Archers, Swordsmen, Warriors |
| 21 | The Bulwark Line (new) | Architectium | Bulwarks (great shield) with Archers and a Lancer |
| 22 | The Forge Floor (new) | Blast Workshop | Warriors, Sparklings, a Copper Corpse, a Lancer |
| 23 | The Smelter (new) | Blast Workshop | Bulwark, Archers, Swordsman, Sparkling, Copper Corpse |
| 24 | The Blast Workshop | Blast Workshop | Mini-boss **Architectian Titan** |
| 25 | The Rune Gallery (new) | The Golem's Hall | All the Architectian weapon types |
| 26 | The Architect's Golem | The Golem's Hall | Boss **Architect's Golem** |

## Soldier weapon types (new)

Enlightened Guards and Architectian Warriors now come with different weapons. The plain Guard keeps its spear and sun shield, and the plain Warrior keeps its hammer and gear shield.

| Weapon | Enlightened name | Architectian name | How it fights |
|---|---|---|---|
| Short sword | Blade | Swordsman | Fast and fragile: Quick Slash, Lunge (dashes in) |
| Hammer | Smiter | (the plain Warrior) | Slow and heavy: Hammer Smash, Ground Pound (shockwave on the floor: jump it) |
| Great shield | Bulwark | Bulwark | Tanky. Blocks 80% of damage from the FRONT unless it is attacking. Hit it from behind or right after its Shield Bash / Shield Slam |
| Spear | (the plain Guard) | Lancer | Reach: Spear Thrust, Low Sweep (jump it) |
| Bow | Archer | Archer | Keeps away. Arrow, Arrow Volley (3 arrows rain down where you stand), Kick (pushes you off) |

The shared weapon code is in `scripts/story/enemies/ArmedSoldier.gd`.

## Colosseum 4: The Void Below (27-34, you play as the ARCHITECT)

| Level | Title | Map | What happens |
|---|---|---|---|
| 27 | The Dark Cave | Dark Cave | Roll-down cutscene; Black Crawlings |
| 28 | The Void Escapist | Dark Cave | Void Escapists; the floor breaks, fall into the void |
| 29 | The Void | Void | Void Souls and Tentacles |
| 30 | The Bone Sea | Void | Void Souls and Tentacles |
| 31 | The Hollow Masker | Void | The Hollow Masker |
| 32 | The Shining (OPTIONAL) | The Altar | Kill The Shining, or leave through the dark gate |
| 33 | The Web Tunnels (new) | Spider Lair | Crawlings, a Hollow Masker, Tentacle, Void Soul |
| 34 | The Void Massacre | Spider Lair | 2 Hollow Maskers, then the boss **Void Massacre** |

**The Shining is now its own optional level (32).** Beating level 31 unlocks both 32 and 33, so you can walk past it on the board (it has a dashed border and says OPTIONAL). The choice is saved:
- **Kill it:** every void enemy in levels 33-34 has 30% less HP and damage, and the Massacre is slower ("WEAKENED BY THE SHINING").
- **Leave it, or skip the level:** the Void Massacre has 35% more HP and 25% more damage, and is faster and more aggressive ("VIGOROUS").
- Replaying level 32 changes the saved choice.

## Rules

- Enemies come in waves. Normal enemies have small HP bars; bosses also get a big bar at the top.
- 2 flasks per level (R / touch "+"), each heals 50%. They refill after each boss intro.
- At most 2 enemies attack at the same time.
- Progress saves after each level.

## Testing (2026-11-09)

- Headless check: all 34 levels load, and every enemy, including the 8 new weapon types, spawns and fires every attack.
- A CPU-controlled Warrior cleared levels 9-12 (with the new Blades, Smiters, Archers and Bulwarks).
- Screenshots checked: the board pages for all 4 Colosseums, the solid floors in the Geode Cavern and Sewers, and the Enlightened and Architectian Archers and Bulwarks in a fight.
- **Not tested yet:** the other new levels (5, 7, 14, 18, 22-23, 25, 33) played through, the optional Shining flow with a real save, and the difficulty of the new soldiers by a human player.
