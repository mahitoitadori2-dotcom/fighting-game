---
class: state
validity: current
type: reference
updated: 2026-11-09
---

# Story Mode

Back to [Summary](SUMMARY.md).

Story Mode has 50 levels in 5 Colosseums, ending with Level 50: **The Sun**. All 50 levels are playable.

| Colosseum | Levels | Count | Areas (levels each) |
|---|---|---|---|
| 1 The Ashen Depths | 1-6 | 6 | Ashen Wastes 2, Geode Cavern 1, Kharleming Hive 1, Lava Lair 2 |
| 2 The Ascent | 7-15 | 9 | Elevator 2, Enlightened city 3, Sewers 2, Blasphemy 2 |
| 3 The Burning Crown | 16-26 | 11 | Burning Throne 3, Minor Architectium 3, Blast Workshop 3, Golem's Hall 2 |
| 4 The Void Below | 27-34 | 8 | Dark Cave 2, Void 3, Altar 1 (optional), Spider Lair 2 |
| 5 The Final Ascent | 35-50 | 16 | Road levels (Thornwood, Fallen Ruins, Foothills) + 8 boss arenas |

The sizes are set in `COLOSSEUM_SIZES` in `scripts/story/StoryLevels.gd`. All the level and map data is in that file. The full-screen cutscenes are in `scripts/story/StoryCutscene.gd`.

## Level select

The level select is a board game with one page per Colosseum. Bigger Colosseums get a zig-zag path. The area names and tile colours come from each level's map. When you clear a level, your pawn hops forward. After the boss, it moves on to the next page. Switch pages with the fog space (next Colosseum), the "< N" mark (back), or Left / Right.

**ANTI ARCHITECT toggle (added 2026-11-11):** the board's "ANTI ARCHITECT: ON / OFF" button (saved). When ON, every main Story level is played **solo** as the Anti Architect, Colosseum 5 included (no CPU partner and no hero choice). The Boss Extensions menu has him as a third hero next to Warrior and Architect. Tested only by the CPU (level 35 solo and extension BC2 were cleared); not tested by a human.

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
| 24 | The Blast Workshop | Blast Workshop | Mini-boss **Forge Mother** |
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

## Colosseum 5: The Final Ascent (35-50)

**Pick your hero:** the first time you start a Colosseum 5 level the board asks "Warrior or Architect?". **Switch any time** with the **PLAY AS WARRIOR / PLAY AS ARCHITECT** button on the Story board (shown on Colosseum 5 levels; saved). The other one is your **CPU partner** in every Colosseum 5 level.

**The CPU partner (updated 2026-11-10):** a **HARD CPU** (faster reactions, few mistakes, blocks and uses Onslaught more). It follows you and fights enemies near you. It has its own **G Gauge** and uses its ultimates; a Time Stop never freezes its own team, so the Warrior partner's Time Stop does not freeze you (and yours doesn't freeze it). It carries **1 flask** (refilled with yours at the boss) and drinks it below 35% HP. When it falls it **revives next to you after 4 seconds**. Its HP, G bar and flask are on the HUD under yours. With a partner, 3 enemies may attack at once instead of 2. **Fixed 2026-11-10:** your attacks used to stop on the partner without hurting it (rockets exploded on it before reaching the boss). Now every attack and projectile passes THROUGH allies: rockets, Shadow Spikes, fireballs, sword / punch / grab tentacle / drill, and allies don't set off HNCT bombs (`CombatManager.passes_through`). Numbers: `Companion.gd` (`make_strong`, `FLASK_AT`), `StoryManager.gd` (`PARTNER_FLASKS`).

**Coin flip (hidden):** at the start of every Colosseum 5 level (except The Sun) a coin is flipped in the background. Nothing is shown; the extra enemies just join the first wave:
- HEADS: 2 **Ambushers** (shadow stalkers: start nearly invisible, Shadow Pounce, Twin Slash, Vanish behind you)
- TAILS: a **Devilish Grin** (a floating black cloud shaped like a grinning mouth: Grin Bite, Fire Spit, Cackle) and a **Pained One** (huge, slow, suffering: Crushing Fist, Agony Scream that stuns up close). **Both nerfed 2026-11-10:** Grin 40 to 30 HP, less damage, slower attacks, Cackle heals 2 instead of 4. Pained One 70 to 52 HP, Fist 10 to 7 damage with a longer wind-up, Scream 5 to 4 damage, stun 0.7 to 0.4 s, slower attacks.

| Level | Title | Arena | Boss (soundtrack) |
|---|---|---|---|
| 35 | The Crossroads of Ash | Thornwood | (intro cutscene, hero select) |
| 36 | Child Wielding Needle | The Silk Loom | Child Wielding Needle (`boss_needle`, violin) |
| 37 | The Thornwood | Thornwood | |
| 38 | The Weeping Road | Fallen Ruins | |
| 39 | The Brothers | The Mirror Hall | The Brothers (`boss_brothers`) |
| 40 | The Broken Aqueduct | Fallen Ruins | |
| 41 | The Silent Chapel | Fallen Ruins | |
| 42 | Animal Lord | The Stitched Den | Animal Lord (`boss_animal`) |
| 43 | The Howling Pass | Foothills | |
| 44 | The Frozen Stair | Foothills | |
| 45 | Executor | The Execution Ground | Executor (`boss_executor`) |
| 46 | The Roots of the World | Thornwood | |
| 47 | Mother Nature | The Heart of Nature | Mother Nature, 4 forms (`boss_nature`) |
| 48 | The False God | The Ashen Cathedral | The False God (`boss_falsegod`) |
| 49 | Satan | Satan's Mountain Cave | Satan (`boss_satan`); climbing cutscene first |
| 50 | The Sun | The Sun Peak | The Sun, then The Consumer (`boss_sun`, `boss_consumer`); peak cutscene, NO pre-fight |

Every boss has its own arena and its own soundtrack. Mother Nature only opens after the first four bosses (the board path).

**The bosses** (all harder than Colosseums 1-4: they chain combos, enrage, jump on you when you jump, dodge or counter your swings, escape corners and go for you rather than your partner):
- **Child Wielding Needle** (380 HP): small and fast, giant needle on a silk thread. Silk Spear thrust, Lunge, Silk Tornado, Needle Combo, Needle Throw (comes back), Silk Dive, Backstep; enraged: Silk Trap. Says "Shaw!", "Adino!", "Guarana!" and "Get Good" (text-to-speech until recordings are added, see [Audio](Audio.md)).
- **The Brothers** (560 HP shared): two knights, black and white, moving as perfect mirror images. They don't chase you; they run set attacks in random order: Cross Slash, Twin Leap (shockwaves), Mirror Waves (low / high), Pincer, Blade Rain, Twin Spin. Hitting either one hurts the shared bar.
- **Animal Lord** (520 HP): stitched lion / bear / ram / bat / crocodile corpse. Claw Swipe, Bite, Wing Gust (pushes), Horn Charge (dazed when it hits the wall), Tail Whip (behind it, low), Pounce; enraged: Feather Storm, Primal Roar (stun).
- **Executor** (600 HP): phase 1 Cleaver Swing, Execution, Stomp (shockwaves), **Grinding Throw** (grabs you, grinds, throws; mash to escape). Phase 2 (below 50%): **Memory Fog** and Fog Rain **reverse your left / right for 3.5 s**, Saw Sweep, double swings, triple stomps.
- **Mother Nature** (4 bars: 250 / 250 / 270 / 250): Fire (blasts, fire wave, flame pillars, whip), Water (wave, bubbles, spouts, tide slam), Earth (rock throw, ground slam, rock spikes, stone fist), Wind (gusts, tornadoes, air dash, cyclone).
- **The False God** (680 HP, its own boss now): a towering crimson cloak with a burning hem, burning antler crown, void face. Fire Bats, Fire Dash (leaves fire pillars), Pillar Sweep, Cloak Slash, Nightmare Dive (twice when enraged), Flame Spiral; enraged: Firestorm.
- **Satan** (720 HP): Hellfire, Fire Breath, Trident Thrust, Meteor Rain (lava pools), Ground Slam; summons **Imps** (flying demons) and **Parasites**; enraged: Inferno. His minions die with him.
- **The Sun** (760 HP, then The Consumer 860 HP): the hardest boss. Enrages at 60%, attacks more often, reacts fastest. The Sun: Sky Beams, Light Swords, Light Pillars, Wing Slash, Light Orbs, Radiance, Eclipse (teleports behind you), Halo (orbs at four heights), Blinding Light (beams that follow you); enraged: Judgment. The Consumer: Consume, Solar Flare, Solar Columns, Sword Storm, Burning Orbs, Devour (grab), Eclipse; enraged: Supernova (fire everywhere except two gaps).
- **Finale:** at 0 HP The Consumer collapses. Grab the **Solar Bomb**, press ATTACK to throw it into its maw, then **escape** across 12 crumbling platforms while a wall of fire chases you (falling costs 12 HP and puts you back on the last platform). Reach the ledge, then the ending cutscene: you fall back to Earth. **THE END.**

Cutscenes: `c5_intro`, `mountain_climb`, `reach_peak`, `fall_to_earth` (painted in `scripts/story/c5/C5Cutscenes.gd`). All Colosseum 5 code is in `scripts/story/c5/`.

## Boss Extension Levels (added 2026-11-10)

After you beat certain bosses, **3 extra levels** open that go DOWN or UP from that boss's arena: 2 enemy levels + 1 final boss. They are named after the boss's initials: **BC2, BC3, BC4**... The Blinded Lord has none.

- **How to play:** on the Story board, press **BOSS EXTENSIONS** (on Colosseum pages 2, 3 and 4), or click the small sign next to a boss (e.g. "BC v"; the three pips show your progress). In the menu, choose **WARRIOR or ARCHITECT** (solo, not duo; duo is only Colosseum 5) and pick a level. Locked until its boss is beaten; each level unlocks the next.
- **Rules:** same as normal levels: 2 flasks (R), refilled after the boss intro; small HP bars over enemies, big bar at the top for bosses (the Story boss buff applies too). **Saved after every level** (also after each extension boss). After a level you return to the board with the extension menu open.
- Every new arena (5 fight arenas + 5 unique boss arenas) is in the **Map Catalogue** and playable in Versus. Each boss has its **own music**.

| Ext | Opens after | Where | Level 2 | Level 3 | Level 4 (boss) |
|---|---|---|---|---|---|
| **BC** | Blasphemy Caeser (15) | down, the Caeser's crypts | Blasphemy Followers: Sword (slash, lunge, shield block) + Wizard (bolts, volley, teleport) | Small Serpents (bite, strike, swarms) + Humane Serpents (spear thrust / rush, tail swipe) | **The Caeser's Grave** (440 HP): rotten body in a broken coffin. Grave Slam (shockwaves), Restless Souls (chase you), Soul Burst, Serpent Swarm (from the floor), Serpents of the Grave (helpers). Arena: the Caeser's Tomb |
| **AC** | Atomic Creation (17) | the exploded nuclear reactor | Mutated Humans: Radiation Punch, Leap Punch, Scream (stun) | Atomic Rocks: Roll, Radiation Burst, **explode when they die** | **Radioactive Giant Metallic Architects Chorus** (520 HP): Radioactive Slam (puddles), Radiation Wave, Atomic Explosion (3 blasts), Chorus Scream (stun + summons Mutated Humans). Arena: the Reactor Core |
| **FM** | Forge Mother (24) | beyond, into The Forge | Forge Workers: Hammer Swing, Hot Metal throw (fire pool) | Coal Throwers (coal, volley, fire pools) + Oven Owners (Oven Blast, Fire Shield -70% dmg + burns, Body Slam) | **The Forge Father** (380 HP): Forge Hammer, Forge Fire Wave, Coal Throw. **Phase 2:** melts himself into the **Metallic Abomination** (new 340 HP bar, much faster): Metal Lash, Liquid Lunge, Metal Spikes, Molten Blast. Arena: the Heart of the Forge |
| **AG** | Architect's Golem (26) | up, the Saint Rocks sanctuary | Saint Rollers (Rock Roll, Bump), Saint Warriors (Hammer, Shield Bash, Rock Guard), Saint Watchers (Rune Shot, Watch laser) | the same three, harder mix | **Saint Architect's Golem** (500 HP): Golem Slam, Rune Blast, Architectian Power (floor wave + pillar), Metal Shards, Rune Shield (-75% dmg). Arena: the Saint Sanctum |
| **VM** | Void Massacre (34) | down, deeper into the Void | Crawling Victims: Claw, Grab (mash to escape) | Spiders: Shooter (web bolts), Biter (bite, lunge), Venomous (poison bite + pools, venom spit) | **3 Void Horrids at once** (170 HP each, own big bar each): small Void Massacres with white eyes and spider legs; one stays close, one mid, one far. Leg Stab, Pounce, Eye Beam, Void Web (slowing puddle). Arena: the Horrid Nest |

HP above is before the Story boss buff (x1.35). **Architectian Titan was renamed Forge Mother** everywhere (same stats and look).

Code: levels / maps in `StoryLevels.gd` (`EXTENSIONS`, `EXT_LEVELS`, internal level numbers 101-115), enemies + bosses in `scripts/story/ext/`, menu `ExtensionMenu.gd`, backdrops `ext/ExtBackdrops.gd`, saves `StoryProgress.ext_done` / `ext_hero`. Group bosses: a boss with `spawn_group()` (StoryManager `boss_group`).

**Tested by script only** (2026-11-10): all 15 levels played start to finish by a CPU hero (Warrior and Architect alternating). Every enemy appeared and attacked, every boss intro, the Forge Father's phase 2, the 3-Horrid group with 3 bars, every level clear + save, and the return to the board with the menu. The probe ended fights early, so **difficulty is not tuned yet** (the Horrids were already softened once: three at once hit too hard).

## Rules

- Enemies come in waves. Normal enemies have small HP bars; bosses also get a big bar at the top.
- 2 flasks per level (R / touch "+"), each heals 50%. They refill after each boss intro.
- At most 2 enemies attack at the same time.
- Progress saves after each level.
- **Boss buff (2026-11-10, to balance the Story-only hero buffs):** every level boss (all Colosseums, including The Sun) has **1.35x HP**, attacks **25% more often** (cooldowns x0.8) and moves **12% faster**. Damage is **not** changed. It also applies to later forms (Blasphemy Caeser phase 2, Colosseum 5 bosses' forms) and stacks with phase 2 / rage. Example: The Sun 760 to 1026 HP, The Consumer 860 to 1161. Numbers: `BOSS_HP_MULT`, `BOSS_CD_MULT`, `BOSS_SPEED_MULT` in `StoryManager.gd`. Mini-bosses inside waves and the Versus Fights-mode bosses are not changed. Checked by script; not played by hand yet.

## Testing (2026-11-09)

- Headless check: all 34 levels load, and every enemy, including the 8 new weapon types, spawns and fires every attack.
- A CPU-controlled Warrior cleared levels 9-12 (with the new Blades, Smiters, Archers and Bulwarks).
- Screenshots checked: the board pages for all 4 Colosseums, the solid floors in the Geode Cavern and Sewers, and the Enlightened and Architectian Archers and Bulwarks in a fight.
- **Not tested yet:** the other new levels (5, 7, 14, 18, 22-23, 25, 33) played through, the optional Shining flow with a real save, and the difficulty of the new soldiers by a human player.

## Testing Colosseum 5 (2026-11-09)

- Headless check: all 50 levels load; all 8 bosses and 4 new enemies spawn and fire every attack in every form (Mother Nature 4 forms, The Sun 2 forms) with no errors.
- Screenshots with a CPU player + CPU partner: the board page, every arena (road and boss), coin-flip enemies, the partner fighting and its HUD line, the Executor enraged with the confusion status, Mother Nature, The False God's cathedral, The Sun, The Consumer and the solar bomb pick-up.
- **Not tested yet:** no Colosseum 5 boss was beaten by a CPU or a human. The escape platforms were built but never jumped across by a player. The hero select screen, the voice lines, the new music and the cutscenes were not watched / heard. Difficulty is untuned.
