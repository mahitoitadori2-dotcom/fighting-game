---
class: state
validity: current
type: reference
---

# Game content

Back to [Summary](SUMMARY.md).

## Name

The game is **Universal Beatdown**. Its old name was Universal Showdown. The domain is still universalshowdown.com (see [To-do list](Todo.md)).

## Playable fighters

Versus mode has 4 fighters. Each fighter has an attack, 3 special moves, G-Gauge ultimates, a CPU opponent and lives.

| Fighter | Style | Moves 1 / 2 / 3 | Ultimates (G) |
|---|---|---|---|
| The Mighty Architect | Zoner, explosives | Rocket Delivery, HNCT Triangle Bomb, Armaggedon Drill | Void Goo (2 bars), Full Arsenal of the Hexagon (3 bars) |
| Warrior | Shadow swordsman | ClingingGrab, Royal Destiny, Eternal Grasp | Mini Eternal Grasp (1), Shadow Swarm (2), The Fall of the Physic (3, time stop) |
| Nightmare Lord | Fire, bats, pressure | BloodFlame Spit, Bat Escape, Launch O' Spikes | Double Trouble (1), Volatile Nightmare (2), The Ritual of the Troupe (3) |
| The Enlightened One | Light beams, healer | Beam Blast, Lord's Heal, Helpers! | Godly O' Light (1), Throne (2), Enlightened Gorilla Form (3) |

The full list of fighters and moves is in `scripts/CharacterRoster.gd`.

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
- Touch controls (on by default on phones and tablets).
