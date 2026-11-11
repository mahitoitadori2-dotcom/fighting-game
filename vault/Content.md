---
class: state
validity: current
type: reference
---

# Game content

Back to [Summary](SUMMARY.md).

## Name

The game is **Universal Beatdown**. Its old name was Universal Showdown. The domain is still universalshowdown.com (see [To-do list](Todo.md)).

The game icon (`icon.png`, 512 px) shows the 4 fighters (Architect, Warrior, Nightmare Lord, Enlightened One), each on a glow in their own colour. It was rendered from their in-game art on 2026-11-08.

## Playable fighters

Versus mode has 6 fighters. Each fighter has an attack, special moves, a CPU opponent and lives; all but one have G-Gauge ultimates. The **APHA Architect** has 7 powers and Flight instead (see below).

| Fighter | Style | Moves 1 / 2 / 3 | Ultimates (G) |
|---|---|---|---|
| The Mighty Architect | Zoner, explosives | Rocket Delivery, HNCT Triangle Bomb, Armaggedon Drill | Void Goo (2 bars), Full Arsenal of the Hexagon (3 bars) |
| Warrior | Shadow swordsman | Clinging Grab, Royal Destiny, Eternal Grasp | Mini Eternal Grasp (1), Shadow Swarm (2), The Fall of the Physic (3, time stop) |
| Nightmare Lord | Fire, bats, pressure | BloodFlame Spit, Bat Escape, Launch O' Spikes | Double Trouble (1), Volatile Nightmare (2), The Ritual of the Troupe (3) |
| The Enlightened One | Light beams, healer | Beam Blast, Lord's Heal, Helpers! | Godly O' Light (1), Throne (2), Enlightened Gorilla Form (3) |

The full list of fighters and moves is in `scripts/CharacterRoster.gd`.

### Anti Architect (added 2026-11-11, Versus + Story + Extensions + Map Catalogue)

The Architect's model and animations with reversed (negative) colours: black armour, orange limbs, orange core. An aggressive rusher built to Onslaught a lot: the flash comes after only 2 punches, and Workflies and Anti Laser can be Onslaughted too. Numbers: `data/AntiArchitectData.gd`; code: `scripts/anti/`.

- **1 Workflies:** 2 flies that home in on the enemy (no target: straight ahead, then back). 3 each.
- **2 Anti Laser:** thin orange laser, long range, pierces every enemy in the line. 9.
- **3 Overcharge:** charges briefly, then explodes around him (11). Costs him 2 HP (never lethal).
- **G1 BattleFlies:** 3 faster flies, each hits twice (4 per hit).
- **G2 Energy Pool:** energy juice spills under him, 2 damage every 0.5 s for 5 s.
- **G3 Never Out Of Plans:** a metal clump forms in front of him and explodes (16): energy pools, battle flies, metal shards and energy shards fly out everywhere.
- **Story Mode:** has a Story-only buff like the other heroes (punch 5, laser 13, Overcharge 15, shorter cooldowns). Same 2 flasks (R), refilled after the boss intro.

### APHA Architect (added 2026-11-09, Versus only)

A dark, very powerful version of the Architect: black helmet, black metal chest, faint dark green, a slimmer athletic build, and black **Creation Gloves** on both hands with sigils glowing in different colours. **2500 HP, no G Gauge**, and **every punch is an Onslaught punch** (18 damage). His powers hit very hard on purpose. All numbers are in `data/AlphaArchitectData.gd`; code in `scripts/alpha/`.

- **E = Flight on / off.** Flying: Jump = up, Crouch = down. Punches become **Air Charges** (24). Powers switch to their air variants (shown in the HUD list).
- **1 Thunderclap:** electrified shockwave (30 + stun). Air: compressed wind tornado (45 + stun).
- **2 Godly Touch** (ground only): 25 + 3 random debuffs for 6 s, from Slow, Burn, Poison, Weakened damage, Blind, Stun, Confusion, Defense Down, Life Drain.
- **3 Barrage of Vadis:** 3 clones, 12 fist hits x 7. Air: the clones shoot 9 lasers x 10.
- **4 Portal Manifestation:** a portal throws homing rocks, metal shards, energy orbs and debris (9 each) for 2.6 s.
- **5 Pure Implosion of Decay** (cinematic): flies up, gas gathers into a ball in slow motion, throws it down: implosion 70 + a decay field.
- **6 World Implosion Bomb** (cinematic + cutscene): an energy rod forms and duplicates, he flies up, a cutscene shows him over the Earth throwing the rods through it, then 2 rods crash onto the enemy (130 each).
- **7 World Opening** (cinematic): eyes close, a barrier covers the area, giant hands tear at everything inside (8 x 16, then a final rip of 80).
- During 5-7 everyone else is frozen, he can't be hurt, and the camera zooms with black bars.
- Keys 4-7 and E are new keys; on phones the touch controls add buttons 4-7 (right to left) and FLY.
- Tested by script: every power on the ground and in flight, all 3 cinematics, and a CPU-vs-CPU fight. **Not played by hand yet**, and he is not balanced against anyone (on purpose very strong).

**Story Mode buffs (since 2026-11-10: STORY ONLY, Versus uses the normal numbers).** The Warrior buff from 2026-11-08 used to apply everywhere; now it is only in Story, and the Architect got the same kind of buff. The numbers are in `apply_story_buff()` at the bottom of `data/WarriorData.gd` and `data/ArchitectData.gd`; `StoryManager` applies them to your hero and your Colosseum 5 partner. Checked by script (Story fighters get the buff, Versus keeps the normal numbers); not balanced by hand yet.

| Warrior move | Story (Versus) |
|---|---|
| Sword | 5 dmg (3) |
| Clinging Grab | 7 dmg, Onslaught 10, 3.5 s cd (5 dmg, 7, 5 s) |
| Royal Destiny | 12 s cd (17) |
| Eternal Grasp | 5 per spike, 13 s cd (4, 20 s) |
| Mini Eternal Grasp | 4 per spike (3) |
| Shadow Swarm | 30 (25) |

| Architect move | Story (Versus) |
|---|---|
| Punch | 5 dmg (3) |
| Rocket Delivery / Triple Rocket | 13 dmg, 4.5 s cd (10, 6 s) |
| HNCT Triangle Bomb | 26 dmg, 8.5 s cd (20, 12 s) |
| Armaggedon Drill | 5 + 6 x 5 = 35 dmg, 10 s cd on hit / 14 s on miss (28, 15 / 20 s) |
| Void Goo | 2 dmg per tick (1) |

**Architect look (2026-11-10):** redrawn less bulky and more athletic: broad shoulders, V-shaped chest plate with pecs, visible abs, narrow waist, leaner arms and legs, slightly smaller helmet; the blue core sits on the chest. Only the drawing changed (`ArchitectArt.gd`), not his hitbox.

## Match extras

- **Epic countdown** at the start of every Versus match: 3, 2, 1, GO!, with screen shake, flash and drum hits.
- **Move names show big on screen** (yours higher, the opponent's lower), shrunk to fit.
- **Dummy fights:** you and the Dummy have infinite lives.

## Fights-mode bosses (Enemy Test)

Each has its own music. Minos and Sisyphus speak voice lines (text-to-speech for now, also shown on screen). They use mythology names, not ULTRAKILL's.

- **King Minos** (180 HP): Serpent Slam, Judgment Kick, Ghost Serpent, Prime Combo, Ground Eruption.
- **Sisyphus** (200 HP): Boulder Throw, Chain Slam, Sisyphus Punch (breaks guard), Ground Shatter. Rage Mode below 50%.
- **Geyron** (190 HP): white dragon with a light-blade tail: Light Sword Slash, Holy Beam, Wing Dash, Judgment Spears, Angel Flurry. Roars only.
- **Kokusen** (2500 HP, added 2026-11-10, Versus / Enemy Test only, not in Story): a towering sorcerer with a dark crimson head, **four glowing eyes**, a cruel grin and a long flowing black robe. He **flies** (switches between ground and air by himself, and follows you up if you go high). Every melee hit is an **Onslaught**. Music: `boss_satan`. Code: `Kokusen.gd` + `KokusenFx.gd`.
  - **Sorcerer Strike** (melee, 5, Onslaught)
  - **1 Cut**: tens of slashes forward (aimed at you in the air), 2 each, at most 4 can hit you
  - **2 Underground Flame**: ground = 5 giant rolling fireballs that set the floor on fire; air = many smaller, faster fireballs at you
  - **3 Greatest One** (ground only, grab): hand slammed into his chest, lunge, grab, 6 slow rips (3 each) - he always fails to tear you apart, you break loose and he staggers; mash to escape early
  - **4 Unknown Force**: ground = pulls you in (short stun); air = repels you far away (6 damage)
  - **5 Meteor Rain** (cinematic): you freeze while he flies up; a cutscene shows him above the Earth summoning a meteor shower that burns up in the atmosphere, only one survives; back in the arena you can move again: debris falls first, then the giant meteor (20, unblockable) on a red warning mark
  - **6 No Fear In Sight**: barrage of flame slashes, 3 each, at most 4 can hit you
  - **7 Closed World** (cinematic): close-up as his four eyes open wide; then a circle of fire surrounds the arena and sends flame slashes, fire pillars (warning on the floor) and debris for ~3.5 s (at most 6 hits), ending in a blast that hits everyone inside (8)
  - He cannot be hurt during his two cinematics. The cinematics never come in the first 14 / 26 s of a fight. Phase 2 below 50% HP: faster, attacks more often, more slashes.
  - **Balance:** in a CPU Warrior test he dealt about 100 damage in 30 s, including both cinematics (forced early for the test). With 2500 HP the fight is very long on purpose; tune `HP`, the volley caps (`CUT_CAP`...) and pattern damage in `Kokusen.gd`. Not played by hand yet.

They were only tested CPU vs boss. The code is in `scripts/enemies/bosses/`.

## Story Mode enemies

Colosseum 1: Parasite, Demon Brute, Hydra-Mutant, Rock Golem, Kharleming, the Blinded Lord (boss). Colosseum 2: Enlightened Guard, Enlightened Follower, God Crawler, Rot Stray, Architect Chorus (mini-boss), Blasphemy Caeser (boss). See [Story Mode](StoryMode.md).

## Versus enemies (Enemy Test)

You can fight any of these 7 enemies with any fighter:

- Rotor (boss: bark waves, fetch balls, enraged below 50% HP)
- King Frog
- Frost Jarl Hrimgar (stands in for Kratos)
- Archangel Raphael
- Elton John
- Abraham Lincoln
- Cyber T-Rex

Enemies have 60-70 HP and 2-3 telegraphed attacks.

## Enemy system

All enemies, in Versus and in Story Mode, use the same system: `BaseEnemy` + `EnemyPattern` + `EnemyHUD`. Thus a new enemy is easy to add.

- Each enemy has a small HP bar above it.
- Attacks are telegraphed before they hit.
- In a group, at most 2 enemies attack at the same time.

## Arenas and the Map Catalogue

Versus has **30 arenas**: the Test Arena, the Void Arena, and **every Story Mode map** from Colosseums 1-5 (near-duplicates left out). Story maps are fought as floating islands with their backdrop, floor and fog (no cave walls, so you can still knock each other off). They all use one scene, `scenes/StoryMapArena.tscn`, dressed by `scripts/VersusMap.gd`; the list is in `scripts/ui/MapCatalog.gd`.

The **Map Catalogue** (Main Menu > MAP CATALOGUE, or CHANGE ARENA) shows every map as a card with a still picture and where it comes from. Click a card to see the map big (also a still picture), with its description and SELECT ARENA / FIGHT HERE / CLOSE.

## Settings and Match Settings (separate screens)

- **Settings** (Main Menu): graphics, **FPS Counter** (moved here from Sandbox on 2026-11-11, saved, works in Versus AND Story), touch controls AUTO / ON / OFF, **Touch UI Size** (60%-160%, saved on the device), controller help, Music / SFX volume, Mute.
- **Match Settings** (the pre-fight screen, after PLAY): Lives, Enemy Lives, and Sandbox (damage, gauge and cooldown multipliers, God Mode).

## Main Menu (2026-11-11)

Buttons in two columns next to each other: PLAY / STORY MODE / SWITCH CHARACTERS (left) and MAP CATALOGUE / ACHIEVEMENTS / SETTINGS (right), with **EXIT** under them (hidden on the Web build, where a game can't close the browser tab).

## Achievements (added 2026-11-11)

**139 achievements**, all in one list in `scripts/achievements/Achievements.gd` (saved to `user://achievements.cfg`). Each has its own code-drawn artwork (`AchievementArt.gd`): a framed card with the real portrait of the boss / character / enemy, or a big icon, plus a corner emblem. Unlocking one slides a pop-up in on the left (`AchievementToast.gd`). **Main Menu > ACHIEVEMENTS** shows a grid (unlocked = coloured, locked = almost black); hover or focus a card to see what you did / have to do. Tabs: All / Versus / Story / Challenges / Secret.

- **Versus** (never in Sandbox): First Blood; win without Powers / Blocking / G Gauge; for EVERY character and enemy: *Trophy* (beat them) and *Bare Hands* (beat them without Powers, Blocking AND G Gauge); *Main* (win as each character); Roster Breaker; Monster Hunter.
- **Story**: a *Trophy* for every boss, mini-boss and extension boss (e.g. "Blinded Lord Trophy"); *Pure Faith* (beat that boss level without Blocks, Healing, G Gauge AND Powers); *Solo* for every Colosseum 5 boss; 6 hard levels; both Shining choices; Colosseum 1-5 Conquered; per Colosseum x 4 challenges (e.g. "Colosseum 1: Powerless" = the No Powers badge on every level); One Hero, One Road (all of C5 solo); Deep Explorer; badge counts; 2 Anti Architect ones.
- **Multi-Multi-Multiversal Level Of Power** (secret): every Colosseum 5 level cleared SOLO with each of the four challenges (separate runs allowed). Reward: **Galaxy skins** for the Architect and the Warrior (deep-space colours + twinkling stars, `GalaxySkin.gd`), worn in Versus and Story, switch on / off in the Achievements menu.
- **Badges** (Story): every cleared level gives one badge per challenge kept (No Powers, No Blocks, No Healing, No G Gauge) + SOLO in Colosseum 5. Shown as small coloured icons on the board tiles and on the LEVEL CLEAR banner. Saved in `story.cfg` (Story RESET clears them; achievements stay).
- What counts is tracked on the fighter (`Fighter.used`): a power = a move 1/2/3 that actually went off (or an Onslaught upgrade), a block = holding block, G Gauge = any ultimate, healing = any HP healed (flasks too).
- **Adding new ones:** one `_add(...)` line + an `unlock("id")` where it's earned. New Versus characters / enemies get theirs automatically; a new Story boss only needs a line in `BOSSES`.

On the touch controls, the move buttons sit in a row ordered **1, 2, 3 from right to left** (1 is nearest the right edge), above ATK. JUMP, BLOCK and G sit on the inner ring.

## Keyboard controls

| Action | Main keys | Alternate keys |
|---|---|---|
| Move | A / D | Left / Right arrow |
| Jump | W | Up arrow |
| Crouch | S | Down arrow |
| Attack | Left mouse button | Space |

The alternate keys are added in `CombatManager.register_alt_keys()`. Block (F), the moves (1, 2, 3) and the ultimate (G) have no alternate keys.
