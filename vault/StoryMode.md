---
class: state
validity: current
type: reference
updated: 2026-11-09
---

# Story Mode

Back to [Summary](SUMMARY.md).

Story Mode has 62 levels: 5 Colosseums (1-50, up to **The Sun**) and then **THE ENLIGHTENED CHASE** (51-62), its own story part (NOT called a Colosseum). The story is not over: it ends on "TO BE CONTINUED...".

| Colosseum | Levels | Count | Areas (levels each) |
|---|---|---|---|
| 1 The Ashen Depths | 1-6 | 6 | Ashen Wastes 2, Geode Cavern 1, Kharleming Hive 1, Lava Lair 2 |
| 2 The Ascent | 7-15 | 9 | Elevator 2, Enlightened city 3, Sewers 2, Blasphemy 2 |
| 3 The Burning Crown | 16-26 | 11 | Burning Throne 3, Minor Architectium 3, Blast Workshop 3, Golem's Hall 2 |
| 4 The Void Below | 27-34 | 8 | Dark Cave 2, Void 3, Altar 1 (optional), Spider Lair 2 |
| 5 The Final Ascent | 35-50 | 16 | Road levels (Thornwood, Fallen Ruins, Foothills) + 8 boss arenas |
| **The Enlightened Chase** | 51-62 | 12 | Golden Dunes 4, Pilgrim Road 3, Glass Oasis 3 + Gong Sanctum (First Prime) + Sky Reliquary (Enlightened One) |

The sizes are set in `COLOSSEUM_SIZES` in `scripts/story/StoryLevels.gd`. All the level and map data is in that file. The full-screen cutscenes are in `scripts/story/StoryCutscene.gd`.

## Level select

The level select is a board game. The area names and tile colours come from each level's map. When you clear a level, your pawn hops forward.

**ONE MAP (2026-11-11):** the whole story (Colosseums 1-5 + The Enlightened Chase, levels 1-62) is one continuous map: spaces 170 px apart on one slow wave (a curve every ~5 spaces), a stone **gate** with the part's name between two parts (chained + locked until that part is open). **Drag** left / right (mouse or finger; the mouse wheel too) to move along the whole story; it springs back at the two ends. The title, board colours, scenery and the BOSS EXTENSIONS button follow the part in the middle of the view. Clicking a space moves the pawn there (far-off spaces: the map glides there), Left / Right hop space by space. Only what is on screen is drawn. Numbers: `SPACING`, `PART_GAP`, `WAVE_*` at the top of `StoryBoard.gd`. Checked with simulated drags + screenshots, not on a real touch screen.

**SOLO mode (added 2026-11-11):** Colosseum 5 board button "SOLO: ON / OFF" (saved): fight without the CPU partner. Needed for the Solo boss achievements, the SOLO badge and the Multiversal achievement. Anti Architect runs always count as solo. Challenge badges and achievements: see [Game content](Content.md#achievements-added-2026-11-11).

**Blasphemy Caeser nerf (2026-11-11):** the user found him too tanky (~840 HP in total after the Story boss buff). HP 280 + 340 -> **210 + 260** (~635 in total with the buff); Blade Slash 7 -> 6, Ground Slam 10 -> 8, Lava Wave 9 -> 8 (slightly longer cooldowns). The Warrior's growing sword in this fight now adds +45% damage per level (was +30%). Not played by a human yet.

**DEEP FAITH PAYOFF (added 2026-11-11):** ONLY AFTER **Mother Nature**: she (level 47; `DEEP_FAITH_AFTER`) must be beaten, and it only works in the main Story levels AFTER her (48+: The Sun, The Enlightened Chase, the coming open world). Not in levels 1-47 (replays) and not in the Boss Extensions (changed 2026-11-12, `deep_faith_in()`). Beating her shows "DEEP FAITH PAYOFF UNLOCKED!" and unlocks the "Deep Faith" achievement. A small Story-only buff for the Warrior and the Architect (you or the C5 partner, not the Anti Architect): +20% max HP, +1 flask (3 per level, partner 2), move cooldowns 15% shorter. Numbers: `DEEP_FAITH_*` in `StoryManager.gd`. The HUD shows "DEEP FAITH PAYOFF" next to the flasks. Checked by a test run (Warrior 120 HP, 3 flasks); not played by a human.

**No Anti Architect in Story Mode (since 2026-11-13):** the Anti Architect is a VERSUS-only character. His Story toggle, extension hero button, Story buff, pawn, cutscene version and the two Story achievements are removed (old saves with the toggle on just play the normal heroes again). Story Mode is the Warrior and the Architect only.

**Hidden Story buff (since 2026-11-13, `scripts/story/StoryBuff.gd`):** every character you play in Story Mode (and the Colosseum 5 partner) silently gets +10% max HP, +10% damage dealt, -10% damage taken, +5% walk speed, 8% shorter move cooldowns and a 15% faster G Gauge. Never shown in the game, never in Versus. Stacks with the per-hero Story buffs and Deep Faith Payoff.

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
- **The Sun** (540 HP, then The Consumer 620 HP; **nerfed 2026-11-12** from 760 / 860, all her damage x0.7, finale fall 12 -> 9 and fire wall 8 -> 6): the hardest boss. Enrages at 60%, attacks more often, reacts fastest. The Sun: Sky Beams, Light Swords, Light Pillars, Wing Slash, Light Orbs, Radiance, Eclipse (teleports behind you), Halo (orbs at four heights), Blinding Light (beams that follow you); enraged: Judgment. The Consumer: Consume, Solar Flare, Solar Columns, Sword Storm, Burning Orbs, Devour (grab), Eclipse; enraged: Supernova (fire everywhere except two gaps).
- **Finale:** at 0 HP The Consumer collapses. Grab the **Solar Bomb**, press ATTACK to throw it into its maw, then **escape** across 12 crumbling platforms while a wall of fire chases you (falling costs 12 HP and puts you back on the last platform). Reach the ledge, then the ending cutscene: you fall back to Earth. **THE END.**

Cutscenes: `c5_intro`, `mountain_climb`, `reach_peak`, `fall_to_earth` (painted in `scripts/story/c5/C5Cutscenes.gd`). All Colosseum 5 code is in `scripts/story/c5/`.

## The Enlightened Chase (51-62, added 2026-11-11)

Its own story part after Colosseum 5 (the UI always says "THE ENLIGHTENED CHASE", never "Colosseum 6"). Beating The Sun opens it (old saves too). Code: `scripts/story/c6/`.

- **Intro cutscene** ("enl_chase"): the Enlightened One runs away across the dunes, your hero runs after him, the other hero lies injured ("GO...! CATCH HIM!").
- **Solo** with the hero you picked (Colosseum 5 pick, PLAY AS button on the board). Deep Faith Payoff applies.
- **Bombard:** at the start AND end of every level except the last, the Enlightened One flies over the arena throwing explosive barrels and holy hand grenades (`EnlightenedFx.Thrower`, 5 dmg each). You can move and must dodge.
- **Enemies:** Enlightened Guards (all 5 weapon types), **Enlightened Counselor** (holy bolt, light pillar under you, HEALS his allies 10 HP: kill him first), **Enlightened Camel Rider** (camel + spear warrior: Camel Charge 9, Spear Thrust 7, Camel Spit 4, Trample 8 with shockwaves).
- **Mini-boss, Level 56: The Enlightened First Prime** (warrior mage, Gong Sanctum, no pre-fight): Holy Blade, Golden Arc / Triple Arc (golden crescents), Holy Smite pillars, Staff Nova, Blink Strike, enraged Gong of Judgment. 300 HP (x1.35 Story boss buff).
- **Final boss, Level 62: The Enlightened One** (Sky Reliquary, no pre-fight). He never attacks himself and keeps away from you: random objects from his hoard fall on the arena all fight (shadows warn you; some explode), plus Rain of Relics / Explosive Offerings / The Hoard Falls, and Flee (blinks away). **Phase 2 (Ascended):** + Enlightened Lasers (low = jump, high = stay down, one from the sky) and Light Balls. 180 + 210 HP (x1.35). After every spell he stands still for ~1.1-1.5 s: your window to hit him.
- **Ending cutscene** ("enl_end"): he points at the sky, everything he threw rises into a DARK CLOUD. "TO BE CONTINUED..."
- **Music:** `story_chase` (desert chase), `boss_prime` (gong ritual + choir), `boss_enlightened` (chaos: organ, violin, harpsichord, brass, bells, gongs, drums, the key lurching every bar).
- **Bosses nerfed the same day** after CPU tests (the CPU died to both at first): First Prime 420 -> 300 HP, all hits -1/-2, longer cooldowns; Enlightened One 380/420 -> 180/210 HP, fewer / weaker falling objects, flees much less, long openings after each spell. Also fixed: an object still falling could kill you after he died and the level still counted as cleared.
- **Tested (CPU only, it never dodges shadows):** 51, 52, 53 cleared; the First Prime beaten after the nerf; the Enlightened One won about half the time after the nerf. Not played by a human.

## DemiLand (level 63, added 2026-11-12)

The next Story part after The Enlightened Chase: ONE **open-world** level (5-15 minutes instead of 1-3). On the board it is a **rectangle** (a little map of the land), not a square. Scene `scenes/DemiLand.tscn`, code `scripts/story/demi/` (layout + scenery: `DemiWorld.gd`, flow: `DemiLand.gd`).

- **The land:** a dark land with a dark sky by day and an even darker night (day 4 min / night 2 min). Primitive people live here, the trees are dead, everything else is extinct. One long strip, west to east: **Tiger Ravine | Dead Plains | Ancient Door (start) | Tribe Village | Dead Grove**. Each region has its own backdrop and is a Versus map in the Map Catalogue.
- **Hero:** the one who did NOT chase the Enlightened One (the other of your Colosseum 5 pick; Anti Architect run = the Anti Architect). **Souls rules** are on (roll instead of block, stamina). Deep Faith Payoff applies.
- **CamTons (checkpoints):** old rock pillars that make flames around themselves once woken. Walk to one to wake it, press **DOWN** to rest: full HP + flasks, but every enemy camp comes back. When you die ("YOU DIED") you wake at the last CamTon; artifacts are kept. 5 CamTons.
- **Enemies** (9 camps, they wake when you come near, one more at night; they only notice you when you are close): Tribe Hunter (spear throw / stab), Tribe Brute (club, ground pound), Tribe Shaman (curse fire, bone rain, War Drum heals), Tiger Cub (bite, pounce), Pelt Cultist (bone darts, leap slash), Husk (walking dead tree: sweep, root spike), Rot Sapling (hop bite, seed spit).
- **Bosses** (walk into the arena: a **wall of rock + fog** rises on both sides, every other creature goes back to sleep, nothing interrupts): **The Tribe Master** (village; War Club, Spear Volley, Chieftain Leap + shockwaves, Totem Fire, War Cry summons 2 hunters, enraged Drums of War), **The Last Tiger** (ravine; Claw, Maul, Pounce, Charge, Roar stun, enraged The Last Hunt = 3 charges), **The LIVING Tree Lord** (grove; first the Dead Tree Lord, then it wakes up glowing green: Branch Sweep, Root Spikes, Uproot Slam, Seed Rain, Saplings, enraged Thorn Storm). HP 330 / 300 / 240+300 (x1.35 Story buff). Each drops an **artifact**: Bone Crown, Tiger's Fang, Living Heart.
- **Goal:** put the three artifacts into the **Ancient Door** (walk up to it). It opens = level clear. **No mission list.**
- **Map:** M / TAB / R3 / the MAP button. Accurate (drawn from the same layout as the world), fills in as you explore: regions, scenery, CamTons, camps, bosses (crossed out when beaten), the door's sockets, you. The game does not pause.
- **Music:** `story_demiland` (day), `story_demiland_night`, `boss_tribe`, `boss_tiger`, `boss_treelord` (all new compositions, real instruments).
- **Achievements:** The Ancient Door, 3 boss trophies, 3 "Bare Will" (a boss without flasks or Powers), Cartographer of Ash (every region), Never Woke at a CamTon (no deaths), No Rest for the Living (no resting), Through the Blade (25 dodges).
- **Fixed during testing:** the Last Tiger's Charge hit every frame (up to 60 hits a second): now one hit per charge. Camps woke two at a time: now one.
- **Tested** (CPU + scripted): every boss fight starts with both walls and no other enemies, every boss drops its artifact, the door opens with 3, the level saves as cleared and you return to the board. The CPU alone could not beat the bosses (it lost ~8-14 HP per 12 s while taking only 25% damage): **balance not checked by a human.** Progress inside the level IS saved (since 2026-11-13): when a CamTon wakes, when you rest, when a boss falls, when you pick up or place an artifact. Coming back = you wake at the last CamTon with all of it; cleared when the door opens.

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
- **Pause menu (2026-11-14):** Esc / controller Start / the touch MENU button (The Caves: the "II" button) opens it in every fight scene (Story, DemiLand, The Caves, Versus, Map Catalogue fights). The game freezes; the music plays quieter. RESUME, RESTART (asks again first), MUSIC / SOUNDS sliders, QUIT (Story: to the board; Versus: main menu; asks again first). It also opens during a dialogue box (the dialogue stays frozen after it). Before, Esc quit the fight at once. Code: `scripts/ui/PauseMenu.gd`; the key is caught in the `Graphics` autoload. Checked by script (open, close, restart, quit, in dialogue, in The Caves).
- **Pause menu extras (2026-11-14):** GRAPHICS button (cycles POTATO / FAST / REGULAR / REAL, applied at once) and CONTROLS (every key, click one and press the new key; RESET KEYS; same save as Settings). **Auto-pause:** when the window / browser tab loses focus or the phone app goes to the background in a fight, the pause menu opens by itself (not in CPU test runs).
- **Level stats (2026-11-14):** LEVEL CLEAR shows the fight time (only while fighting: not paused, not in talks or intros), damage taken and flasks drunk. The best time per level is saved (`StoryProgress.best_times`) and shown on the board ("Best 1:23") and on LEVEL CLEAR ("NEW BEST TIME!"). The Caves show time + crashes. Achievements: Blink and It's Over (a wave level under 30 s, no flask).
- **Boss checkpoint (2026-11-14):** dying at the boss of a level that has waves adds **RETRY FROM BOSS** to the death screen: the level reloads and starts at the boss (no waves, no opening talk; the boss talk still plays). No best time is saved for that run. Achievement: Second Wind (win after RETRY FROM BOSS). Code: `StoryManager.boss_retry`.
- **Difficulty (2026-11-14):** EASY / NORMAL / HARD, the "DIFFICULTY" button on the board, saved. It changes the enemies only: EASY 70% HP and 65% damage, HARD 130% HP and 125% damage (every Story enemy, every boss and boss form, DemiLand too). The Caves: EASY 12% slower, HARD 10% faster. Achievements: No Mercy Asked (any boss on HARD), Burn Brighter (The Sun on HARD), No More Running, No More Mercy (The Enlightened One on HARD), Fast and Flawless (a cave on HARD with no crash). Code: `scripts/story/StoryDifficulty.gd` (applied in `BaseEnemy._ready` and `StoryManager.buff_boss`). Checked: level 1 Parasite 8 / 12 / 16 HP.
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

## Souls rules (open world, prepared 2026-11-12)

The next Story part will be an open world (Elden Ring-like). Its **mechanics are ready, but there are no open-world levels yet.** A level turns them on with `"open_world": true` in `StoryLevels.gd`; everywhere else (Versus, all current Story levels) nothing changes and you still block. Code: `scripts/souls/SoulsRules.gd` (all numbers), `ControlledFighter.gd`.

- **Dodge roll replaces block:** the block button (F / RB / LT, touch button shows ROLL) rolls toward the direction you hold, with **i-frames** (invincible for 0.30 s: attacks pass through, "DODGED"). No direction = a short **backstep** (0.14 s i-frames). The hero spins and turns see-through while invincible.
- **Stamina** (green bar under your HP): roll 26, backstep 16, attack 12, move / ultimate 20, jump 7 (max 100). Refills at 42/s after a 0.55 s pause. At 0 you are **EXHAUSTED** (bar turns yellow): no rolls / attacks until it is back to 25.
- **Flasks** (R) are the Estus, unchanged.
- The CPU heroes roll through enemy attacks instead of blocking (for tests and the partner).
- **Tested** with the rules forced on in level 48 (CPU Architect): stamina drains / refills, 3 rolls dodged 3 attacks, no errors. Not played by a human. Forcing them on for a test: `SoulsRules.test_force = true`.
- **Ideas for later** (not built): Sites of Grace (checkpoints / respawn points), dropped souls you can pick back up after dying, poise, a lock-on, heavy (charged) attacks.

## Dialogue (Undertale / Deltarune style, since 2026-11-13)

- Before important fights the game FREEZES, a light shade covers the arena, and a black box with an ancient gold frame types out the lines. Name plate top-left, the speaker's portrait above the frame (1st speaker left, 2nd right, 3rd left...; the listener is dimmed). Attack / jump / Enter / click / tap = finish the line, then next.
- Every speaker has a **voice blip** made in code (`scripts/story/dialogue/Blips.gd`): Architect = regular, a bit deep human; Warrior = dark and deep; Enlightened One = feminine, proud; every Story boss its own (Satan a deep growl, the Needle squeaky, the Sun a bell...).
- Where: Colosseum openings (levels 1, 7, 16, 27, 35), every mini-boss and boss of C1-5 (they replace the old floating boss line), every Enlightened Chase level + the First Prime and the Enlightened One. DemiLand: none. In C5 the partner talks too (skipped in SOLO).
- Lines: `scripts/story/dialogue/StoryDialogue.gd`: OPENING (level start), BOSS (before the fight), AFTER (after the boss dies), STORM (after the "enl_end" cutscene).
- **Enlightened Chase lore (user, 2026-11-13):** the Colosseums are part of the Enlightened One's land; he took people and watched them fight for fun, and whoever died was cured and became an enemy for the next challenger. The Warrior and the Architect (both trapped by him) were the first to kill every single one, freeing them all to go to heaven or hell. Scared, he struck the hero you did NOT pick and ran; your hero chases him through his guards. He hides his fear until the **First Prime** falls (AFTER dialogue), then goes crazy for his life in the last level. After the fight he realizes he was meant to die; your hero **spares** him. As he turns to leave, the dark cloud forms (cutscene) - **THE STORM**: an all-seeing living organism that appears when creatures might leave the planet and guards the sky. As a child he feared it would kill everyone he knew, so as king he made "no one leaves the planet" a royal law; with his guards gone, the Storm thinks nothing stops anyone leaving and wakes fully. Your hero faces it head on; the Enlightened One names **Orbis Terrarum** - to get a ticket you must travel through every land. Your hero makes him heal the injured hero (who is in this last talk), and the level ends.
- Checked: screenshots of the box on level 1 and of every portrait; the game unpauses after. Not played through by a human.
## The Caves (levels 64-66, added 2026-11-14)

The Story part after DemiLand: beyond the Ancient Door the floor drops away and you SLIDE down three caves. **No combat**: no enemies, no attacks, A / D do nothing. Same hero as DemiLand.
- **W** = jump (all three). **S** = duck flat under low rock on the ground, or dive down fast in the air (caves 2 and 3). Touch: right half = jump, left half = duck / dive. Esc = back to the board.
- Obstacles: rocks, spike rows, chasms; from cave 2 low rock slabs (duck); cave 3 adds long crawls (hold S) and "chasm then low rock" (jump, then dive). Crash = tumble, restart at the last glowing crystal (3 per cave). The layout is the same every time (seeded) so it can be learned.
- 64 Beyond the Door (brown, 560 px/s), 65 The Crystal Chute (blue, 620), 66 The Deep Throat (red, 690). About 1 minute each.
- Achievements: one per cave, "Not a Scratch" per cave (no crash), The Caves Conquered, secret "Face, Meet Rock" (15 crashes in one cave).
- Code: `scripts/story/slide/CaveSlide.gd`, scene `scenes/CaveSlide.tscn`. Board: page 8 (cave scenery, hero sliding on the tiles).
- Checked: a bot cleared all three with 0 crashes; with no input you crash at the first rock. Not played by a human yet.