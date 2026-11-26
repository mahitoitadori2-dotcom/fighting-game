---
class: state
validity: current
type: summary
updated: 2026-11-25
---

# Universal Beatdown - Summary

Universal Beatdown is a free 2D platform fighter, made in Godot 4.7.

## State

| | |
|---|---|
| **Version** | v0.3.3 (latest GitHub Release; the menu shows v0.3.3). The website (`main`) is ahead of it with everything from 2026-11-21 below - not yet a release. |
| **Play online** | https://mahitoitadori2-dotcom.github.io/fighting-game/ |
| **Downloads** | Windows, macOS, Linux and Web zips on the [Releases page](https://github.com/mahitoitadori2-dotcom/fighting-game/releases) |
| **Builds** | Automatic. Every push builds all platforms. A push to `main` updates the website. A `v*` tag makes a release. |
| **Playable** | Versus (6 fighters incl. the **Anti Architect** - Versus only, never in Story; 7 test enemies, 4 Fights-mode bosses incl. Kokusen, and 33 Story enemies and bosses that unlock when you meet them in Story) and Story Mode, all 5 Colosseums (levels 1-50: 6 / 9 / 11 / 8 / 16 levels). Colosseum 4 is played as the Architect, level 32 The Shining is optional, Colosseum 5 has a hero choice (switchable on the board) + a HARD CPU partner with ultimates and a flask, and ends with The Sun. Plus 5 **Boss Extensions** (BC, AC, FM, AG, VM: 15 levels, 16 new enemies, 5 new bosses, 10 new arenas). After Colosseum 5 comes a new story part, **THE ENLIGHTENED CHASE** (levels 51-62: solo chase, Counselors + Camel Riders, mini-boss The Enlightened First Prime, boss The Enlightened One, ends with the dark cloud), then **DEMILAND** (level 63: an OPEN-WORLD level, 5-15 min, Souls rules, CamTon checkpoints, day / night, a map, 3 bosses whose artifacts open the Ancient Door), then **THE CAVES** (levels 64-66: no-combat cave sliding - W jump, S duck / dive), then **TERRA CRATERUM** (level 67, since 2026-11-15: the second open world, a crater of volcanoes; Lava Melter + Kharleming Lord; drag Kharleming corpses to the Basalt Wall and blow it up with the Technician's Breaker; free the Volcano Slave OR the Kharleming Sacrifice, saved), then **THE MAGMA RUN** (levels 68-70, since 2026-11-15: hunted slides - J smashes walls, a lava flood with Kharlemings chases you; level 70 stops for 3 waves, then the last slide). Every slide level ends at a white wall. Then **TERRA ORDINARIORUM** (level 71, since 2026-11-15: the regular land, an open world of 7 biomes with weak real-life animals; a Town of people who think you're crazy; climb the Mountain for the Lightning Candle; main route: the Storm Finger, the Ticket, the bridge to Orbis Terrarum; secret: the Snow Desert and the Crystal Swarm, which gives the Frozen Expedition skins). A **STORY SKINS** catalogue on the board (Normal / Galaxy / Frozen Expedition). Then **THE ROAD TO PEACE** (levels 72-74, since 2026-11-15: run up the bridge to Orbis Terrarum; W jumps, J hits the Storm's particles, no S; the Architect has a green sword only here). Then **ORBIS TERRARUM** (levels 75-79, since 2026-11-15: pure lore, dialogue only. The Trainer, blue with no eyes, asks the Architect to be his Student; refusing fails the level. Then 4 lessons in any order, and level 80 THE STORM ATTACKS: the table, the breaking bridge, the dead town, a cave slide with the Storm behind you, possessed corpses and the STORM HAND, fought with the other hero and the Trainer). The dialogue box got a new, richer look and choices. **Souls features:** YOU DIED / GREAT ENEMY FELLED banners, a hidden boss stance break, ground messages, lore items + a CODEX, DemiLand's stranger. **Achievements** (250+, with artwork, pop-ups, a grid menu, Story challenge badges, Colosseum 5 SOLO mode and Galaxy skins as the ultimate reward). **Story dialogue** in a typed text box with portraits and voice blips (Colosseum 1-5 openings and bosses, every Enlightened Chase level, lines from the real lore). A **pause menu** in every fight (Esc / Start / the touch MENU button: resume, restart, volume, quit). Story **difficulty** EASY / NORMAL / HARD (board button) |
| **New on 2026-11-21** | **The Abandoned Town** (level 81: lore NPCs, a cave with the sleeping Nightmare Lord, 3 endings, the Strong Wind, own music). **Loading screens** between levels. **Hybrid pixel art** (3 px) + new walk / crouch / jump / attack animations. **Milestone difficulty** (every 10th level harder, every 25th harder still, every 50th a super boss - `StoryDifficulty.gd`). **Secret codes** (Main Menu: CODE button on phones, WASD / arrow orders on PC): Bug Tester, Rotor Mode, 100%, XANXXE. **MADNESS mode** (20 levels, black / red corrupted look, deep-fried sound, boss The XX0XN with voice lines, Assassin skin). **The red console** (F12 in any level; phones: pause > CONSOLE) with #s001-#s003 (each with a deep-fried sound), normalize, rotor (Rotor photos), jumpscare and small talk. **Phone fixes:** a big pause button, the pause menu in Versus, typing through the phone's own input box, a scrolling results screen. Balance: Enlightened One + Anti Architect nerfed. |
| **New on 2026-11-24 / 25 (not pushed yet)** | **THE TRUE HUNT** (levels 111-138, after The Hunt of a Nightmare): both heroes hunt the Nightmare Lord (you + the other hero as a partner, always). Every regular enemy of the game appears; **natural disasters** (quake, meteors, lightning, eruption, rockfall, gale) hit everyone; new maps with **rock ledges**; 2-5 waves per level. Boss (138): **THE NIGHTMARE MONSTROSITY**, a golem that splits in two each time it falls, down to the 6th generation (127 golems, max 14 at once). Then the Nightmare Lord's offer: he **joins** you (freed the Volcano Slave, or you say yes) or **leaves** (fewer than 3 Stranger talks: goblins; freed the Kharleming Sacrifice: it attacks him; or you say no). **The Nightmare Lord is now LOCKED in Versus until he joins you** (stays unlocked after a Story reset). Lore: Terra Patria, the Prime Fragment of Existence and its locks, told by him at the end + short talks on the way + a Codex item. New music, 5 achievements. Also: a **4-hit M1 chain** for every hero (hit 4 = finisher: knockback, CROUCH = uppercut, in the air = downslam), hit / block / turn reactions, model shading, longer attack wind-ups. |
| **Audio** | Music: real orchestral instruments (Souls / Hollow Knight style, since 2026-11-12). Sound effects: 24 of 36 are real Kenney CC0 recordings (since 2026-11-13), the other 12 are designed by `tools/make_sfx.js` (creature voices, fire / water, orchestral samples; since 2026-11-14) |
| **Tested** | By CPU-controlled matches, the headless crash sweep, and an emulated iPhone 13 in headless Chrome with real touch taps (`/phonowebo`). Not tested by a human player or on a real iPhone. |

## Next step

Play Colosseum 5, the Enlightened Chase, DemiLand, The Caves and Terra Craterum yourself and tune them. Listen to the new music, sound effects and voice blips. Test the web game on an iPhone for 5+ minutes (no crash, sound works, silent in the background). Check The Sun after the 2026-11-14 nerf (the user found her "a big difficulty spike"). See [Handoff](Handoff.md) and the [To-do list](Todo.md).

## Details

- [Game content](Content.md): fighters, moves and Versus enemies.
- [Story Mode](StoryMode.md): Colosseums 1-5, the Enlightened Chase, DemiLand, the Boss Extensions, rules, bosses and dialogue.
- [Audio](Audio.md): the sound manager, the orchestral music and the sound effects.
- [Performance](Performance.md): pooling, particle limits, the 4-level Graphics setting and test results.
- [Build and release](BuildAndRelease.md): GitHub Actions, the website, releases and local builds.
- [3D](ThreeD.md): 3D cutscenes (3D heroes + all bosses), 3D backgrounds on the boss maps, 3D menus. Fights stay 2D.
- [Project layout](ProjectLayout.md): where the files are.
- [Roadmap](Roadmap.md): the large future plans.
- [To-do list](Todo.md): small open tasks.
- [Recap](Recap.md): what the last 10 requests changed.
- [Future lore](FutureLore.md): the user's lore for later story parts (Orbis Terrarum, Terra Craterum, Terra Ordinariorum, the Learners). Terra Craterum is built (2026-11-15); the rest is not built yet.
- [Handoff](Handoff.md): the state of the last session: work in progress, problems, decisions and the next steps. Read it at the start of a session.
