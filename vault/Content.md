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

Versus mode has 5 fighters. Each fighter has an attack, special moves, a CPU opponent and lives; the first four also have G-Gauge ultimates. The 5th, the **APHA Architect**, has 7 powers and Flight instead (see below).

| Fighter | Style | Moves 1 / 2 / 3 | Ultimates (G) |
|---|---|---|---|
| The Mighty Architect | Zoner, explosives | Rocket Delivery, HNCT Triangle Bomb, Armaggedon Drill | Void Goo (2 bars), Full Arsenal of the Hexagon (3 bars) |
| Warrior | Shadow swordsman | Clinging Grab, Royal Destiny, Eternal Grasp | Mini Eternal Grasp (1), Shadow Swarm (2), The Fall of the Physic (3, time stop) |
| Nightmare Lord | Fire, bats, pressure | BloodFlame Spit, Bat Escape, Launch O' Spikes | Double Trouble (1), Volatile Nightmare (2), The Ritual of the Troupe (3) |
| The Enlightened One | Light beams, healer | Beam Blast, Lord's Heal, Helpers! | Godly O' Light (1), Throne (2), Enlightened Gorilla Form (3) |

The full list of fighters and moves is in `scripts/CharacterRoster.gd`.

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

**Warrior buff (2026-11-08, every mode).** The numbers are in `data/WarriorData.gd`. It hasn't been played against the other fighters yet.

| Move | Damage | Cooldown |
|---|---|---|
| Sword | 5 (was 3) | – |
| Clinging Grab | 7 (was 5); Onslaught 10 | 3.5 s (was 5) |
| Royal Destiny | – | 12 s (was 17) |
| Eternal Grasp | 5 per spike (was 4) | 13 s (was 20) |
| Mini Eternal Grasp | 4 per spike (was 3) | – |
| Shadow Swarm | 30 (was 25) | – |

## Match extras

- **Epic countdown** at the start of every Versus match: 3, 2, 1, GO!, with screen shake, flash and drum hits.
- **Move names show big on screen** (yours higher, the opponent's lower), shrunk to fit.
- **Dummy fights:** you and the Dummy have infinite lives.

## Fights-mode bosses (Enemy Test)

Each has its own music. Minos and Sisyphus speak voice lines (text-to-speech for now, also shown on screen). They use mythology names, not ULTRAKILL's.

- **King Minos** (180 HP): Serpent Slam, Judgment Kick, Ghost Serpent, Prime Combo, Ground Eruption.
- **Sisyphus** (200 HP): Boulder Throw, Chain Slam, Sisyphus Punch (breaks guard), Ground Shatter. Rage Mode below 50%.
- **Geyron** (190 HP): white dragon with a light-blade tail: Light Sword Slash, Holy Beam, Wing Dash, Judgment Spears, Angel Flurry. Roars only.

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

The **Map Catalogue** (Main Menu > MAP CATALOGUE, or CHANGE ARENA) shows every map as a card with a live-drawn thumbnail and where it comes from. Click a card to see the map big (animated), with its description and SELECT ARENA / FIGHT HERE / CLOSE.

## Settings and Match Settings (separate screens)

- **Settings** (Main Menu): touch controls AUTO / ON / OFF, **Touch UI Size** (60%-160%, saved on the device), controller help, Music / SFX volume, Mute.
- **Match Settings** (the pre-fight screen, after PLAY): Lives, Enemy Lives, and Sandbox (damage, gauge and cooldown multipliers, God Mode, FPS counter).

On the touch controls, the move buttons sit in a row ordered **1, 2, 3 from right to left** (1 is nearest the right edge), above ATK. JUMP, BLOCK and G sit on the inner ring.

## Keyboard controls

| Action | Main keys | Alternate keys |
|---|---|---|
| Move | A / D | Left / Right arrow |
| Jump | W | Up arrow |
| Crouch | S | Down arrow |
| Attack | Left mouse button | Space |

The alternate keys are added in `CombatManager.register_alt_keys()`. Block (F), the moves (1, 2, 3) and the ultimate (G) have no alternate keys.
