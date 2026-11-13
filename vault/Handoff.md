---
class: state
validity: current
type: handoff
updated: 2026-11-13
branch: main
last_commit: 2fe5a91 Enlightened Chase dialogue from the real lore
---

# Handoff

Back to [Summary](SUMMARY.md).

## Current state

The game has Versus (6 fighters, 33 unlockable Story opponents) and Story Mode levels 1-63: 5 Colosseums, the Boss Extensions, the Enlightened Chase and DemiLand. The music is orchestral, 24 of 36 sound effects are real recordings, and Story has typed dialogue with voice blips. CI passes on `main` and the website shows the latest `main`. The last release is v0.2.0 (2026-11-08), so the downloads are old. This session fixed `SUMMARY.md` and added the `handoff` skill and this file.

## Work in progress

None.

## Plan

1. Tag a new release (`v0.3.0`), so the download zips get the work after 2026-11-08. See [Build and release](BuildAndRelease.md).
2. The user plays Colosseum 5, the Enlightened Chase and DemiLand. Tune the bosses from that feedback.
3. The user listens to the music, sound effects and voice blips. Change the tracks and volumes from that feedback.
4. Test the web game on a real iPhone for 5+ minutes.

## Problems to fix

- **Phone page reload** (reported 2026-11-09): the web page reloaded 1-3 minutes after it opened. The 2026-11-10 memory fixes are not confirmed on a real phone. See [Performance](Performance.md).
- **No human test yet:** all balance numbers come from CPU-controlled runs. The CPU did not beat the DemiLand bosses.
- 12 sound effects are still synth placeholders (roar, dragon_roar, bark, croak, bite, flame, holy, ultimate, geyser, splash, rumble, flask_drink).

## Decisions

- Voice: Undertale-style blips, not recorded or AI voices (2026-11-13).
- The Anti Architect is Versus-only in the normal Story, but can play every Story level solo with the board toggle.
- `vault/Handoff.md` holds only the latest session state. Git keeps the history.

## Waiting on the user

- Play tests: Colosseum 5, the Enlightened Chase, DemiLand, the Boss Extensions.
- Listen to the audio and say what to change.
- The iPhone test.
- Decide on the domain: universalshowdown.com or universalbeatdown.com.

## To-dos

The open items are in the [To-do list](Todo.md).

## How to resume

- First action: ask the user whether to tag `v0.3.0` now, or to wait for the play tests.
- Useful commands: `node tools/serve.js web 8060` (local web build), `tools/export_all.sh /path/to/godot` (all exports).
- Check first: `git status`. If HEAD is not `last_commit`, read `git log 2fe5a91..HEAD` before anything else.
- At the end of a session, run the `handoff` skill (`/handoff`).
