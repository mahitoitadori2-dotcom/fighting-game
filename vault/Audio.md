---
class: state
validity: current
type: how-to
---

# Audio

Back to [Summary](SUMMARY.md).

## Sound manager

`scripts/audio/SoundManager.gd` plays all sound effects and music. Settings has Music and SFX sliders and a Mute button.

## Music: real instruments (since 2026-11-12)

All 41 music tracks are played by **real instrument recordings** (orchestra, Souls / Hollow Knight style), no more synth:

- **Bosses** (Dark Souls III / Elden Ring): string orchestra + choir (+ church organ), cellos and double basses, the melody on French horn / trombone / trumpet / violin, timpani, concert bass drum and cymbals. Each loop plays twice, the melody moving to a second instrument (e.g. horn, then trombone).
- **Story areas** (Hollow Knight): quiet piano, harp, nylon guitar, celesta or solo violin / cello over soft slow strings, almost no drums.
- **Specials:** the Needle = a violin duel with pizzicato; the First Prime = gong ritual (cymbals, timpani, low tubular bells, taiko) with a choir chant; the Enlightened One = chaos (organ, choir, brass stabs, violin runs, harpsichord) lurching through keys; the Chase = strings + taiko gallop.
- **How it is made:** `node tools/make_music.js` (or `node tools/make_music.js boss_sun menu` for some tracks). It plays the notes of every track (still written in `tools/make_placeholder_audio.js`) through the free **MuseScore_General** SoundFont (MIT licence, 215 MB, NOT in the repo: kept at `C:/code/audio_tools/MuseScore_General.sf2`, download link at the top of the script), adds a cathedral reverb and writes `audio/music/<name>.wav`. The instrument choice per track is the `STYLES` list in the script. `--check` lists which recording every instrument uses.
- **11 brand-new compositions (2026-11-12, Elden Ring / Silksong inspired, original melodies)** in `tools/music_pieces.js`, written as readable sheet music (chords per bar, note names): `menu` (fallen-kingdom waltz: harp + cello, violin, then choir + horns), `fight` (driving strings + horns), `boss_caeser` (spiccato strings, chanting choir, horns, heavy timpani), `boss_needle` (fast 6/8 dance: harpsichord, violin, flute, castanets), `boss_sun` (organ, choir, harp, trumpets), `boss_consumer` (the Sun's theme collapsing into minor), `boss_satan` (organ, tolling bells, low brass, high choir), `boss_nature` (tragic harp waltz with violin), `story_cave` (mossy 6/8 wander: harp, pizzicato, flute), `story_void` (lonely piano, drones, far voices), `story_chase` (galloping strings, taiko, horns). A track in that file replaces its old notes completely; the other 30 tracks still use their old notes on real instruments.
- **Full-orchestra revamp (2026-11-13):** every track now uses much more of the orchestra.
  - **Strings as real SECTIONS:** every string pad is voiced by range - double basses on the root, celli, violas, violins on top (the solo recordings layered with the string ensemble).
  - **Woodwinds:** flute, piccolo, oboe, English horn, clarinet (also played high = E-flat clarinet, low = bass clarinet), bassoon, and the **crumhorn** (no recording exists in the SoundFont: the bagpipe chanter stands in - also a capped, buzzing reed).
  - **Brass:** French horns, trumpets, trombones, tubas and **euphonium** (no recording: a trombone + horn blend in the euphonium's range).
  - **Keys / percussion:** piano, pipe organ, timpani, concert bass drum, snare (rolls into the crashes), crash cymbals, tubular bells, xylophone, glockenspiel, marimba, castanets, tambourine, triangle.
  - **Plucked:** harp, nylon guitar, mandolin; **folk fiddle** for the "played by characters / merchants" sound.
  - **Voices:** full choir (aah / ooh) + a **solo vocalist** (a real sung "ooh" voice: low register = male, high = female) on the big boss themes, the menu, The Sun, Mother Nature, the Tree Lord... The SoundFont's voices only sing vowels: real Latin / constructed-language WORDS would need recorded singers.
  - **New piece:** `story_architectium` is now a **merchant's jig** (fiddle, mandolin, guitar, crumhorns, tambourine, castanets).
  - Where: `STYLES` (old-melody tracks: `dbl` doublings, `voice` solo singer) in `tools/make_music.js`; `MORE` + the jig at the bottom of `tools/music_pieces.js`.
- **Not listened to by a human yet.** Checked only by numbers (loudness, no clipping, every instrument finds its recording). Listen and say which tracks need a change.

## Sound effects: real recordings (since 2026-11-13)

24 of the 36 sound effects are real recordings from **Kenney**'s CC0 packs (Impact Sounds, RPG Audio, Sci-fi Sounds, Interface Sounds; free for any use, credited in `audio/CREDITS.txt`): punch, hit, sword slash, block, swing, whoosh, jump, dash, explosion, slam, stone, chain, beam, laser, drill, spark, death, spawn, countdown tick / GO, telegraph, heal, void goo, chemical spill. They are `.ogg` files in `audio/sfx/` (the game loads .ogg before .wav).
- The other 12 are **designed** by `node tools/make_sfx.js` (since 2026-11-14, no downloads):
  - Creatures through vowel formant filters on a rough "vocal cord" source: roar (big beast), dragon_roar (Geyron: low growl + screech), bark (Rotor: two barks), croak (King Frog: "rib-bit"), bite (hiss, teeth clacks, crunch, thud).
  - Fire / water synthesis: flame (whoosh + crackles), geyser (gurgle, burst, lava drops), splash (slap + rising droplets).
  - Real orchestral samples from the MuseScore_General SoundFont: holy (choir + tubular bells + glockenspiel), ultimate (reverse cymbal, orchestra hit, brass, timpani, crash), rumble (timpani roll + bass drum), flask_drink (cork pop, gulps, glockenspiel + harp sparkle). These 4 need the SoundFont to be rebuilt.
  - All 12 are about the same loudness (-12 to -15 dB RMS). `make_placeholder_audio.js` never overwrites them. Checked by numbers and spectrograms; **not listened to by a human yet**.
- The downloaded packs live outside the repo in `C:/code/audio_tools/kenney/` (all 355 sounds, for swapping in other variants).
- **Not listened to by a human yet** - volumes may need a tweak.

## Sound files

Older notes (placeholders):

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

To make the placeholder sound effects again, run `node tools/make_placeholder_audio.js` (it no longer touches the music unless you add `--synth-music`).

New bosses get classical or medieval, Souls-like music, not cyber or synth (see [Roadmap](Roadmap.md)).
