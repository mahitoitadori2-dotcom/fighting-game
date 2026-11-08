---
class: state
validity: current
type: how-to
---

# Audio

Back to [Summary](SUMMARY.md).

## Sound manager

`scripts/audio/SoundManager.gd` plays all sound effects and music. Settings has Music and SFX sliders and a Mute button.

## Sound files

All sounds are generated placeholders:

- 18 sound effects in `audio/sfx/`
- 7 music tracks in `audio/music/`: menu, fight, boss, and one for each Story area (surface, cave, geode, hive)

The list of file names is in `audio/AUDIO_FILES.txt`.

## Replace a placeholder

1. Make or get the new sound.
2. Give it the same name as the placeholder, for example `audio/sfx/punch.wav`.
3. Put it in the same folder. `.ogg`, `.mp3` and `.wav` all work.

To make the placeholders again, run `node tools/make_placeholder_audio.js`.

New bosses get classical or medieval, Souls-like music, not cyber or synth (see [Roadmap](Roadmap.md)).
