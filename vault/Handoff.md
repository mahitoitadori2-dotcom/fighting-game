---
class: state
validity: current
type: handoff
updated: 2026-11-14
branch: main
last_commit: 448b7d0 Vault: The Caves in the summary
---

# Handoff

Back to [Summary](SUMMARY.md).

## Current state

The game has Versus (6 fighters, 33 Story opponents that unlock when met) and Story Mode levels 1-66: 5 Colosseums, the Boss Extensions, the Enlightened Chase, DemiLand and **The Caves** (new). The music is orchestral, 24 of 36 sound effects are real recordings, and Story has typed Undertale-style dialogue with voice blips. Everything is committed and pushed to `main`. The last release is still v0.2.0 (2026-11-08), so the download zips are old. GitHub CLI is not logged in, so CI status was not checked in this handoff.

This session added:
- **Story dialogue** (`scripts/story/dialogue/`): the game freezes, a light shade covers the screen, and a framed text box types the lines with a portrait and a voice blip per speaker. It plays at C1-5 openings, before every mini-boss and boss, and on every Enlightened Chase level.
- **Enlightened Chase lines from the user's lore**: the fear builds level by level, he breaks after the First Prime dies, he is spared after the last fight, then the Storm talk (Orbis Terrarum, heal the injured hero). The `enl_end` cutscene captions now lead into that talk.
- **The Caves** (levels 64-66, `scripts/story/slide/CaveSlide.gd`, `scenes/CaveSlide.tscn`): no combat. You slide down a cave; W jumps, S ducks / dives (caves 2-3). Crystals are checkpoints. 6 new achievements.
- DemiLand saves the run at CamTons; the Brothers twin copies the Versus scaling; 24 Kenney CC0 sound effects.

## Work in progress

None.

## Plan

1. Ask the user whether to fix the stale Anti Architect sentence in `vault/SUMMARY.md` (see Problems).
2. Tag a new release (`v0.3.0`) so the download zips get the work after 2026-11-08. See [Build and release](BuildAndRelease.md).
3. The user plays The Caves, the Enlightened Chase (with the new dialogue) and DemiLand. Tune from that feedback.
4. The user listens to the music, sound effects and voice blips.
5. Test the web game on a real iPhone for 5+ minutes.

## Problems to fix

- **Stale sentence in `vault/SUMMARY.md`** (state table, "Playable" row): it says the Anti Architect "can play every Story level and extension solo (board toggle)". That is false: the user asked for NO Anti Architect in Story (2026-11-13) and the toggle was removed. The same row also says "never in Story". The summary was edited outside this session; the user was asked and has not answered yet.
- **Phone page reload** (reported 2026-11-09): not confirmed fixed on a real phone. See [Performance](Performance.md).
- **No human test yet**: balance comes from CPU runs. The CPU did not beat the DemiLand bosses. The Caves were cleared only by a bot (0 crashes) and checked with no input (crashes at the first rock).
- 12 sound effects are still synth placeholders (roar, dragon_roar, bark, croak, bite, flame, holy, ultimate, geyser, splash, rumble, flask_drink): the Kenney packs have no matching sounds.
- Voice blips were not listened to: all test runs were silent.

## Decisions

- Voice: Undertale-style blips made in code (`Blips.gd`). (Rejected: recorded / AI / offline TTS voices.)
- Dialogue speaker sides: 1st speaker left, 2nd right, 3rd left. The shade is light (38%) so the arena shows through.
- The Caves are their own Story part after DemiLand, so no existing level is renumbered. (Rejected: inside the Chase, or spread over the Colosseums.)
- The Anti Architect is Versus-only. No trace in Story Mode.
- Test runs always use `--audio-driver Dummy` (user request: no sound during tests).
- Tests back up and restore the user's saves in `%APPDATA%\Godot\app_userdata\Universal Beatdown`.
- The user's own save was set to "The Sun beaten" on request (backup in `backup_before_sun_2026-11-13\` in that folder).

## Waiting on the user

- Answer: fix the Anti Architect sentence in the summary?
- Play tests: The Caves, the Enlightened Chase dialogue, DemiLand, Colosseum 5.
- Listen to the audio and the blips.
- The iPhone test.
- Decide on the domain: universalshowdown.com or universalbeatdown.com.

## To-dos

The open items are in the [To-do list](Todo.md).

## How to resume

- First action: ask the user about the Anti Architect sentence in the summary, then about tagging `v0.3.0`.
- Compile check: `godot --headless --path . --import`, then `godot --headless --path . res://tools/check_scripts.tscn` (prints `SCRIPT CHECK: N failed of M`).
- Push: `powershell -File tools/auto_push.ps1 -Message "..."` (refuses to push when a script fails).
- Probes: put test scenes in `_memprobe/`, run with `--audio-driver Dummy`, delete them afterwards.
- Check first: `git status`. If HEAD is not `last_commit`, read `git log 448b7d0..HEAD` before anything else.
- At the end of a session, run the `handoff` skill (`/handoff`).
