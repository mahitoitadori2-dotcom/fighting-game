# Universal Beatdown

A 2D platform fighter made in Godot 4.7 (GDScript, Compatibility renderer). Exports to Web, Windows, Linux and macOS.

## Project state

Always read these two files at the start of every session, before any other work. They are imported below, so they load automatically.

- `vault/SUMMARY.md`: the main state and links to the detail notes (content, Story Mode, audio, performance, build, layout, roadmap, to-dos).
- `vault/Handoff.md`: the state of the last session: work in progress, plan, problems to fix, decisions, what waits on the user, and how to resume.

@vault/SUMMARY.md

@vault/Handoff.md

## Session start and end

- At the start: run `git status` and compare HEAD with `last_commit` in `vault/Handoff.md`. If they differ, read `git log <last_commit>..HEAD` first: someone else worked since the handoff. Then continue from "How to resume" in the handoff, unless the user asks for something else.
- At the end of a session, when the context runs low, or before `/clear`: run the `handoff` skill (`/handoff`, in `.claude/skills/handoff/`). It rewrites `vault/Handoff.md` and updates the summary and the to-do list.

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
