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

- 35 sound effects in `audio/sfx/`
- 15 music tracks in `audio/music/`: menu, fight, boss, one per Fights-mode boss (Minos, Sisyphus, Geyron), one per Colosseum 1 area (surface, cave, geode, hive), and the Colosseum 2 tracks:
  - `story_ascent`: the Elevator from Hell (haunting, melodic: strings, plucked melody, bells)
  - `boss_architect`: Architect Chorus (the same mood but heavier)
  - `story_enlightened`: Home of the Enlightened Ones (bright choir, bells)
  - `story_sewers`: the Sewers (dark, dripping, creepy, slow)
  - `boss_caeser`: Blasphemy Caeser (dark, epic, choir, heavy)
- Boss voice lines: put recordings in `audio/voice/` to replace the text-to-speech (names in `AUDIO_FILES.txt`).

The list of file names is in `audio/AUDIO_FILES.txt`.

## Replace a placeholder

1. Make or get the new sound.
2. Give it the same name as the placeholder, for example `audio/sfx/punch.wav`.
3. Put it in the same folder. `.ogg`, `.mp3` and `.wav` all work.

To make the placeholders again, run `node tools/make_placeholder_audio.js`.

New bosses get classical or medieval, Souls-like music, not cyber or synth (see [Roadmap](Roadmap.md)).
