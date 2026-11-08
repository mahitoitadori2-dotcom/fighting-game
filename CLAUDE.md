# Universal Beatdown

A 2D platform fighter made in Godot 4.7 (GDScript, Compatibility renderer). Exports to Web, Windows, Linux and macOS.

## Project state

Read the summary first. It holds the current state and links to the detail notes (content, Story Mode, audio, performance, build, layout, roadmap, to-dos).

@vault/SUMMARY.md

## Keeping the notes current

- `vault/SUMMARY.md` holds only the main state: version, where the game runs, what is playable, the next step, and links.
- Put details, plans and to-dos into the separate files in `vault/` and link them from the summary. Do not add them to the summary itself.
- When something changes (a feature, a release, a finished to-do), update the matching file in `vault/` and the state table in `SUMMARY.md`.

## Basics

- Godot editor: `C:/code/Godot_v4.7.2-stable_win64.exe`
- Story Mode: `scripts/story/`. Enemies: `scripts/enemies/`. Sound: `scripts/audio/SoundManager.gd`

## Build

- `tools/export_all.sh /path/to/godot` exports every preset (needs Godot 4.7.2 export templates).
- `node tools/serve.js web 8060` serves the website and web build locally.
- CI: `.github/workflows/build.yml`. See `BUILDING.md`.
