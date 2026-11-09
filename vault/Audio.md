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
- **Colosseum 5 (added 2026-11-09):** every boss has its own theme:
  - `boss_needle`: Child Wielding Needle, a fast **violin** theme (bowed-string synth with vibrato, pizzicato bass, harpsichord)
  - `boss_brothers` (symmetrical organ and bells), `boss_animal` (tribal drums), `boss_executor` (slow, crushing doom organ), `boss_nature` (flowing choir and harp)
  - `boss_falsegod` (twisted carnival waltz of fire), `boss_satan` (infernal choir), `boss_sun` (radiant holy choir), `boss_consumer` (the Sun's theme collapsing, plays in phase 2)
- **Child Wielding Needle voice lines:** "Shaw!", "Adino!", "Guarana!" and "Get Good". They use text-to-speech (high child's voice) until you add recordings to `audio/voice/` named `needle_shaw`, `needle_adino`, `needle_guarana` and `needle_getgood` (.ogg / .wav / .mp3).

The list of file names is in `audio/AUDIO_FILES.txt`.

## Replace a placeholder

1. Make or get the new sound.
2. Give it the same name as the placeholder, for example `audio/sfx/punch.wav`.
3. Put it in the same folder. `.ogg`, `.mp3` and `.wav` all work.

To make the placeholders again, run `node tools/make_placeholder_audio.js`.

New bosses get classical or medieval, Souls-like music, not cyber or synth (see [Roadmap](Roadmap.md)).
