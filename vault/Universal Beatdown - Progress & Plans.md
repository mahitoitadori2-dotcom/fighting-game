# Universal Beatdown - Progress & Plans

*Last updated: 2026-11-08*

## Done so far

### Core game (Godot 4.7, `C:/code/games/fighting-game`)
- Renamed from Universal Showdown to **Universal Beatdown** (the domain is still universalshowdown.com).
- Versus mode with 4 playable characters:
  - The Mighty Architect
  - Warrior
  - Nightmare Lord
  - The Enlightened One
- Each character has 3 moves and G-Gauge ultimates, plus a CPU opponent and lives.
- Match Settings has Sandbox options (damage, gauge and cooldown multipliers; God Mode) and an FPS counter.
- **Epic countdown** at the start of every Versus match: 3 → 2 → 1 → GO!, with zooming numbers, screen shake, flash, shockwaves and drum hits.
- **Move names show BIG on screen** (yours higher, the opponent's lower). The font shrinks to fit, so names are never cut off. The move list in the top corners also fits now; the right side used to run off the screen.
- **Dummy fights:** both you and the Dummy have INFINITE lives (HUD shows "LIVES INF."), so nobody ever wins or loses.
- Fixed the name "ClingingGrab" → **Clinging Grab** everywhere, including the website.

### Enemies
- **Versus / Enemy Test** (7): Rotor, King Frog, Frost Jarl (stands in for Kratos), Archangel Raphael, Elton John, Abraham Lincoln, Cyber T-Rex.
- **Fights-mode bosses** (3, in Enemy Test, each with its own music):
  - **King Minos** (180 HP): pale serpent-bodied corpse king. Moves: Serpent Slam, Judgment Kick, Ghost Serpent, Prime Combo, Ground Eruption.
  - **Sisyphus** (200 HP): stone titan with a boulder. Moves: Boulder Throw, Chain Slam, Sisyphus Punch (breaks guard), Ground Shatter. Goes into Rage Mode below 50% HP.
  - **Geyron** (190 HP): white, blood-soaked dragon with a light-blade tail. Moves: Light Sword Slash, Holy Beam, Wing Dash, Judgment Spears, Angel Flurry. He has no voice lines, only roars.
  - Minos and Sisyphus speak voice lines on the intro, some attacks, rage and death. The voice is text-to-speech for now, and the words also appear on screen.
  - They use mythology names (no "Prime"), because the ULTRAKILL characters and names belong to that game.
- **Story Mode** (6): Parasite, Demon Brute, Hydra-Mutant, Rock Golem, Kharleming, and the Blinded Lord (boss).
- All of them run on the same enemy system (BaseEnemy + EnemyPattern + EnemyHUD), so new enemies are easy to add.
- Enemies have small hovering HP bars, telegraphed attacks, and group behavior (at most 2 attack at once).

### Story Mode: Colosseum 1 (levels 1-6 of 50)
- A board-game level select where your pawn hops forward when you clear a level, then you fall into the caves to the next one.
- **Maps:**

| Level | Map | Enemies |
|---|---|---|
| 1-3 | Ashen Wastes | Parasite, Demon Brute, Hydra-Mutant |
| 4 | Geode Cavern | Rock Golem |
| 5 | Kharleming Hive | Kharlemings (climb walls) |
| 6 | Lava Lair → the Blinded Lord's Laboratory | Group waves, then the boss |

- **Rules:** group battles, 2 flasks per level (R heals 50%), and a boss level with an intro cutscene, boss fight and death cutscene.
- Progress saves after every level.
- **Blinded Lord:** throws chemical pools in phase 1; in phase 2 he becomes CRAZED and fights in melee (Jug Smash, Wild Swings, Charge).

### Performance
- Projectiles, effects and chemical pools are reused instead of created and destroyed each time.
- At most 200 particles at once (110 on phones).
- Off-screen things are skipped, and per-frame redraws were removed where they weren't needed.
- Tested at 60 FPS with 50 extra projectiles on screen.

### Audio
- A sound manager plays every effect and music track, with Music and SFX sliders and Mute in Settings.
- All sounds are generated placeholders: 33 effects and 10 music tracks, including one per Story area and one per Fights-mode boss.
- Sound in every battle: enemy attack whooshes, warning beeps before big attacks, boss roars, slams, rocks, chains and countdown hits.
- Sound in Story Mode: chemical spills, flask drinking, and cutscene sounds (letterbox whoosh, rumble before the boss drops, roar, death rumble).
- Boss voice lines: drop recordings into `audio/voice/` (names in `AUDIO_FILES.txt`) to replace the text-to-speech.
- Swap in real files with the same names (listed in `audio/AUDIO_FILES.txt`).
- Regenerate the placeholders with `node tools/make_placeholder_audio.js`.

### Web and mobile
- The web build in `web/` is ready to upload (re-exported 2026-11-08 with the bosses; the site's character list includes them). It runs in a browser and works on iPhone with touch controls and Tap to Start.
- The site has a PLAY button, a character list and a controls page.
- Test locally: `node tools/serve.js web 8060`, then open http://localhost:8060
- **Not online yet**, and not yet tested on a real iPhone.

## Known bugs
- Some Kharlemings can stand on top of each other, so their name tags overlap (level 5). Spacing was tightened; check whether it still happens. *open*
- In Godot's command-line script check, every script that uses `SoundManager` reports "not found". This is only a quirk of that check mode (it doesn't load autoloads); the game itself runs fine. *not a game bug*

## Problems & risks
- Nobody has played Story Mode with a keyboard yet; all tests used a CPU-controlled Warrior, so the difficulty is unverified (especially the Blinded Lord's enraged phase).
- The website isn't online yet, so the iPhone 13 support (loading, touch, audio after the tap) is untested on a real phone.
- All sounds and music are generated placeholders.
- **New bosses only tested CPU vs boss** (they won 2 of 3, and Minos and Geyron reached rage). The difficulty is not human-tested.
- **Voice lines (text-to-speech)** depend on the device. They are untested on Web and iPhone, so a browser without voices simply stays silent. The voice was not listened to in testing (headless runs).
- The countdown, big move names and boss art were checked with screenshots. Nobody has heard all the new sounds together in a real match.
- The game is named Universal Beatdown, but the domain you own is universalshowdown.com.

## Future plans
1. **Story Mode Colosseums 2-8** (levels 7-50): new enemies, maps and a boss every 6 levels, ending at **Level 50: The Sun**. New bosses should get classical / medieval, Souls-like music (not cyber / synth).
2. **Put the website online:** upload `web/` to Netlify (temporary link), then connect universalshowdown.com.
3. **Real audio:** replace the placeholder sounds and music.

## Optional to-dos
- [ ] **Playtest Colosseum 1 with your own hands.** Tests used a CPU-controlled Warrior, so the difficulty, especially the Blinded Lord, still needs tuning by a human.
  - Knobs: boss HP and `phase2_speed_mult` / `phase2_cooldown_mult` in `BlindedLord.gd`, `TICK` / `TICK_DAMAGE` in `ChemicalPool.gd`, `MAX_ATTACKERS` in `StoryManager.gd`.
- [ ] Test on a real iPhone 13 (loading, touch controls, audio after the tap).
- [ ] Play the 3 Fights-mode bosses yourself and tune them. Knobs: `HP`, pattern cooldowns and damage, and `phase2_*` in `scripts/enemies/bosses/`.
- [ ] Record real voice lines for Minos / Sisyphus (`audio/voice/`).
- [ ] Geyron's wings could use nicer art (they read a bit like a fan of spikes).
- [ ] Decide on the domain: keep universalshowdown.com or register universalbeatdown.com to match the new name.
- [ ] More playable characters in Story Mode (it's Warrior only for now).
- [ ] Optionally add the Story enemies to the Enemy Test roster in Versus.
- [ ] Real sprite or texture art, if you ever want to move past the drawn-in-code style.
- [ ] Pooling for the remaining projectiles (Triangle Bomb, Void Goo, Oil Puddle, Throne, Nightmare Heart, Helper Minion).
- [ ] Story Mode extras: difficulty settings, a level timer or score, unlockables.

## Where things live
- `scripts/story/`: Story Mode (manager, board, levels, maps, HUD, enemies)
- `scripts/enemies/`: enemy system + Versus enemies
- `scripts/enemies/bosses/`: Fights-mode bosses (FightBoss base, KingMinos, Sisyphus, Geyron, BossHazard)
- `scripts/ui/EpicCountdown.gd`: the 3-2-1-GO! countdown
- `scripts/audio/SoundManager.gd`: all sound and music
- `audio/`: sound files (+ `AUDIO_FILES.txt`)
- `web/`: website + web build (`web/play/`)
- `tools/`: placeholder-audio generator, local test server
