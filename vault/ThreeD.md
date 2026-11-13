---
class: state
validity: current
type: reference
---

# 3D (cutscenes, important maps, menus)

Back to [Summary](SUMMARY.md).

Added 2026-11-12. **Fights stay 2D.** 3D is used for the cutscenes, the backgrounds of the important (boss) maps and the menus. Code: `scripts/three_d/`. Everything is built in code from simple shapes with a thick black cartoon outline (no model files). 3D is OFF on the **Potato** graphics level (the old 2D versions run); **Fast** renders the 3D at half resolution.

- **Toolkit** (`Three.gd`, `Stage3D.gd`): shapes + outlines, sky / fog / sun, an animated keyframe camera.
- **Characters** (`Hero3D.gd`): real 3D models of the Warrior, the Architect (+ Anti Architect and the Galaxy skin) and the Enlightened One, with an animated rig (idle, walk, run, fall, lie, climb, roll, kneel + point, menace).
- **Bosses** (`Boss3D.gd`): 3D models of all 21 Story bosses / mini-bosses / extension bosses, each with its own look and a little life (breathing, legs, wings, orbiting orbs). How they ENTER their intro: Blasphemy Caeser **rises** out of the magma; the Blinded Lord, Executor, Forge Father, the Brothers and the Needle **walk in**; the Void Massacre, Forge Mother, Animal Lord, False God, The Sun, the Enlightened One and the Void Horrids **drop from the sky**; the rest are **already there** (revealed by a flash).
- **Cutscenes** (`Scenes3D.gd`, shown by `StoryCutscene`): all 12 Story cutscenes are 3D, plus **level-start intros** for every level without a story cutscene, so level starts look different: boss levels = boss entrance, first level of a new area = a giant **gate** opens, the others alternate **walk in / fly over / fall in**. Captions and fades stay on top. No 2D characters in cutscenes.
- **Map dioramas** (`Maps3D.gd`): every map has a 3D diorama (the 9 important ones built by hand, the rest from their family: cave, lava, holy, void, forest, snow, metal, desert, sewer). **NO CLIPPING:** scenery is never placed where characters walk / stand or the camera flies.
- **Fight backgrounds** (`Backdrop3D.gd`): the important maps (Blinded Lord's lab, Blasphemy temple, Golem's Hall, Spider Lair, World Tree, Satan's cave, Sun Peak, Gong Sanctum, Sky Reliquary) show their 3D diorama behind the 2D fight (Story and Versus), sliding a little with the fight camera. Other maps keep the 2D painting.
- **Menus** (`Menu3D.gd`, through `ArenaBackground`): since 2026-11-13 a **slideshow** of the 9 big boss arenas in 3D, each with its boss in 3D (Blasphemy Caeser in his temple, the Void Massacre in the Spider Lair, Mother Nature at the World Tree, the Blinded Lord in his lab, Satan in his cave, the Architect's Golem in its hall, The Sun on the peak, the First Prime in the Gong Sanctum, the Enlightened One in the Sky Reliquary). The camera drifts past, a new slide every 8 s with a dark fade, starting at a random one. Only one slide exists at a time (memory stays flat). Replaces the old floating-island menu, which showed fighters without a 3D model as flat 2D pictures (bug).

**Fixed the same day:** on the important maps in Story Mode the background was empty (the 3D one failed to load while the arena was being set up). Now added a moment later.

**Tested:** screenshots of every boss intro, the hero cutscenes, menus and fights (by script, on a desktop GPU). Not tested on phones / the web build yet: 3D costs more, check the iPhone memory and FPS (Fast / Potato fall back).
