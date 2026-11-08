---
class: state
validity: current
type: reference
---

# Project layout

Back to [Summary](SUMMARY.md).

The project is in `C:/code/games/fighting-game` on the main computer. The repository is https://github.com/mahitoitadori2-dotcom/fighting-game.

| Folder or file | What it holds |
|---|---|
| `scenes/` | Godot scenes: menus, arenas, Story Mode |
| `scripts/` | Fighters, combat, HUD, effects, arenas |
| `scripts/ai/` | CPU opponents for each fighter |
| `scripts/enemies/` | The enemy system and the Versus enemies |
| `scripts/story/` | Story Mode: manager, board, levels, maps, HUD, enemies |
| `scripts/ui/` | Menus, character select, touch controls |
| `scripts/audio/SoundManager.gd` | All sound and music |
| `data/` | Fighter data |
| `audio/` | Sound files and `AUDIO_FILES.txt` |
| `web/` | The website. The web build goes to `web/play/`. |
| `web_shell/shell.html` | The HTML page around the web game (loading screen, Tap to Start) |
| `tools/` | Export script, placeholder-audio generator, local test server |
| `addons/godot_ai/` | The Godot AI (MCP) editor plugin. It is not in the exported game. |
| `.github/workflows/` | The build and release workflow |
| `vault/` | These notes |
