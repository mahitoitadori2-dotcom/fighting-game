---
class: state
validity: current
type: how-to
---

# Build and release

Back to [Summary](SUMMARY.md). The full instructions are in [BUILDING.md](../BUILDING.md).

## Platforms

| Platform | Output | Notes |
|---|---|---|
| Web (WebAssembly) | `web/play/` | Needs WebGL 2. Has no threads, so it runs on GitHub Pages. Works on iPhone with touch controls and Tap to Start. |
| Windows | `build/windows/UniversalBeatdown.exe` | No signature. SmartScreen shows a warning on the first start. |
| Linux | `build/linux/UniversalBeatdown.x86_64` | |
| macOS | `build/macos/UniversalBeatdown.zip` | Universal (Intel and Apple Silicon). No Apple signature: right-click the app, then select Open. |

Git ignores `web/play/` and `build/`, because the workflow makes them again.

## GitHub Actions

The workflow `.github/workflows/build.yml` uses Godot 4.7.2.

| When | What happens |
|---|---|
| Push to `main` | Only the web game is built. The website in `web/` and the web game go to GitHub Pages. |
| Pull request | Only the web game is built. Download it from the **Actions** tab: open the run, then **Artifacts**. |
| Manual run (**Actions → Build and release → Run workflow**) | All four builds are made and kept as Artifacts. On `main`, the website goes to GitHub Pages again. |
| Push a tag `v*` | All four builds are made. A GitHub Release is made with four zip files attached. |

Every push to `main` is exported and published to GitHub Pages, whatever it changes. A pull request that changes only notes (`vault/`, `*.md`) does not start a build.

## Automatic commit and push

- `tools/auto_push.ps1` commits everything `.gitignore` allows and pushes `main`. It first rebases onto newer GitHub commits; on a conflict it stops and keeps the commit locally. It never force-pushes. Files that look like secrets are never committed.
- It runs automatically whenever Claude Code finishes a reply (a Stop hook in the user settings `~/.claude/settings.json`), and on demand with **/push** (an optional commit message can follow).
- Every push to `main` rebuilds the web game and updates the website (see the table above).

Make a release:

```bash
git tag v0.3.0
git push origin v0.3.0
```

## Website

- Address: https://mahitoitadori2-dotcom.github.io/fighting-game/
- The site has a PLAY button, a character list and a controls page.
- `web/netlify.toml` and `web/_headers` are ready for Netlify, if the site moves there with its own domain.

## Build on your computer

1. In Godot, install the export templates: **Editor → Manage Export Templates**.
2. Run `tools/export_all.sh /path/to/godot`.
3. Test the web build: `node tools/serve.js web 8060`, then open http://localhost:8060.

The Godot version in the editor must be the same as `GODOT_VERSION` in the workflow.
