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

Versus mode has 4 fighters. Each fighter has an attack, 3 special moves, G-Gauge ultimates, a CPU opponent and lives.

| Fighter | Style | Moves 1 / 2 / 3 | Ultimates (G) |
|---|---|---|---|
| The Mighty Architect | Zoner, explosives | Rocket Delivery, HNCT Triangle Bomb, Armaggedon Drill | Void Goo (2 bars), Full Arsenal of the Hexagon (3 bars) |
| Warrior | Shadow swordsman | Clinging Grab, Royal Destiny, Eternal Grasp | Mini Eternal Grasp (1), Shadow Swarm (2), The Fall of the Physic (3, time stop) |
| Nightmare Lord | Fire, bats, pressure | BloodFlame Spit, Bat Escape, Launch O' Spikes | Double Trouble (1), Volatile Nightmare (2), The Ritual of the Troupe (3) |
| The Enlightened One | Light beams, healer | Beam Blast, Lord's Heal, Helpers! | Godly O' Light (1), Throne (2), Enlightened Gorilla Form (3) |

The full list of fighters and moves is in `scripts/CharacterRoster.gd`.

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

## Match Settings

- Sandbox options: damage, gauge and cooldown multipliers, and God Mode.
- An FPS counter.
- Touch controls (on by default on phones and tablets), with a **Touch UI Size** slider (60%-160%, saved on the device) that makes the buttons and joystick bigger or smaller.

On the touch controls, the move buttons sit in a row ordered **1, 2, 3 from right to left** (1 is nearest the right edge), above ATK. JUMP, BLOCK and G sit on the inner ring.

## Keyboard controls

| Action | Main keys | Alternate keys |
|---|---|---|
| Move | A / D | Left / Right arrow |
| Jump | W | Up arrow |
| Crouch | S | Down arrow |
| Attack | Left mouse button | Space |

The alternate keys are added in `CombatManager.register_alt_keys()`. Block (F), the moves (1, 2, 3) and the ultimate (G) have no alternate keys.
