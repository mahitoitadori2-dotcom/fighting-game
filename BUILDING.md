# Building and releasing Universal Beatdown

## Automatic builds (GitHub Actions)

The workflow `.github/workflows/build.yml` exports the game with Godot 4.7.2 for:

- Web (WebAssembly, runs in Chrome, Edge, Firefox and Safari)
- Windows (x86_64)
- Linux (x86_64)
- macOS (universal: Intel and Apple Silicon)

| When | What happens |
|---|---|
| Every push or pull request | All four builds are made. Download them from the **Actions** tab: open the run, then **Artifacts**. |
| Push to `main` | The website in `web/` and the web game are published to GitHub Pages. |
| Push a tag `v*` | A GitHub Release is made with four zip files attached. |

### Make a release

```bash
git tag v0.1.0
git push origin v0.1.0
```

The release appears on the **Releases** page of the repository after about 5 minutes.

### Turn on the website (one time only)

1. On GitHub, open **Settings → Pages**.
2. Under **Build and deployment → Source**, select **GitHub Actions**.
3. Push to `main`, or open **Actions → Build and release → Run workflow**.

The game is then at `https://mahitoitadori2-dotcom.github.io/fighting-game/`.
Click **PLAY** on that page.

## Build on your own computer

1. Install the export templates in the Godot editor: **Editor → Manage Export Templates → Download and Install**.
2. Run the script with the path to Godot:

```bash
tools/export_all.sh /path/to/godot
```

3. To test the web build, run `node tools/serve.js web 8060` and open http://localhost:8060.

The builds go to `web/play/` and `build/`. Git ignores these folders, because the workflow makes them again.

## Notes

- The macOS build has no Apple signature. On the first start, right-click the app and select **Open**.
- On Windows, SmartScreen can show a warning. Click **More info → Run anyway**.
- The web build has no threads. Thus it runs on GitHub Pages, which cannot set the COOP/COEP headers.
- To change the Godot version, change `GODOT_VERSION` in the workflow. The editor version must be the same.
