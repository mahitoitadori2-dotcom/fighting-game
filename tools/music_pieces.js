// NEW COMPOSITIONS (Elden Ring / Silksong inspired, all original melodies) for make_music.js.
// A track listed here REPLACES the old notes of that track completely.
//
// Sheet-music format:
//   bpm, meter   beats per minute and beats per bar (6/8 pieces count EIGHTH notes as beats)
//   chords       one chord per bar: "Dm", "Bb", "F#", "C#m", "Gdim", "Esus4", "D7"
//   parts        what every instrument plays:
//     pad   inst, from, to         held chord, one per bar
//     bass  inst, from, to, pat    chord ROOT on [beat, length] pairs
//     arp   inst, from, to, pat    chord TONES: [beat, tone index (0 root,1,2, 3 = root+octave...), length]
//     ost   inst, from, to, rel, step   repeating figure in semitones from the chord root
//     mel   inst, bar, notes       melody: "D5:1.5 E5:0.5 r:1" (note:beats, r = rest)
//     hit   inst, key, from, to, beats, every   one drum / bell note on these beats
//   from / to are bars (to not included); oct shifts octaves; vel = loudness (1-127).
'use strict';

const PIECES = {
  // ---------------- MAIN MENU: a fallen kingdom's waltz (Elden Ring) ----------------
  // D minor 3/4. A: harp + solo cello. A': solo violin over strings. B: choir, horns, timpani.
  menu: { bpm: 72, meter: 3,
    chords: 'Dm F Bb F Gm A Dm A  Dm F Bb F Gm A Dm A  Dm F C Dm Bb Gm A A',
    parts: [
      { t: 'arp', inst: 'harp', from: 0, to: 24, pat: [[0, 0, 1], [1, 1, 1], [2, 2, 1]], oct: 1, vel: 62 },
      { t: 'bass', inst: 'contrabass', from: 0, to: 24, pat: [[0, 3]], vel: 60 },
      { t: 'mel', inst: 'cello', bar: 0, oct: -1, vel: 92, notes: 'D4:1.5 E4:0.5 F4:1 A4:2 G4:1 F4:1.5 E4:0.5 D4:1 F4:3 G4:1.5 F4:0.5 E4:1 D4:1 E4:1 C#4:1 D4:3 r:3' },
      { t: 'pad', inst: 'slowstrings', from: 8, to: 24, vel: 58 },
      { t: 'mel', inst: 'violin', bar: 8, oct: 1, vel: 96, notes: 'D4:1.5 E4:0.5 F4:1 A4:2 G4:1 F4:1.5 E4:0.5 D4:1 F4:3 G4:1.5 F4:0.5 E4:1 D4:1 E4:1 C#4:1 D4:3 E4:1 F4:1 G4:1' },
      { t: 'pad', inst: 'choir', from: 16, to: 24, oct: 1, vel: 72 },
      { t: 'mel', inst: 'horn', bar: 16, vel: 104, notes: 'F5:1.5 G5:0.5 A5:1 C6:2 A5:1 G5:1.5 F5:0.5 E5:1 D5:3 D5:1 E5:1 F5:1 G5:1.5 F5:0.5 E5:1 E5:3 C#5:3' },
      { t: 'mel', inst: 'violin', bar: 16, vel: 84, notes: 'F5:1.5 G5:0.5 A5:1 C6:2 A5:1 G5:1.5 F5:0.5 E5:1 D5:3 D5:1 E5:1 F5:1 G5:1.5 F5:0.5 E5:1 E5:3 C#5:3' },
      { t: 'hit', inst: 'timpani', key: 38, from: 16, to: 24, beats: [0], vel: 90 },
      { t: 'hit', inst: 'drums', key: 57, from: 16, to: 17, beats: [0], vel: 90, dur: 4 },
    ] },

  // ---------------- VERSUS FIGHT: driving strings + horns ----------------
  fight: { bpm: 144, meter: 4,
    chords: 'Em Em C C D D B B  Em Em C C Am B Em Em',
    parts: [
      { t: 'ost', inst: 'strings', from: 0, to: 16, rel: [0, 0, 12, 0, 7, 0, 12, 7], step: 0.5, oct: 0, vel: 82 },
      { t: 'bass', inst: 'contrabass', from: 0, to: 16, pat: [[0, 1], [1.5, 0.5], [2, 1], [3, 1]], vel: 92 },
      { t: 'bass', inst: 'cello', from: 0, to: 16, pat: [[0, 1], [1.5, 0.5], [2, 1], [3, 1]], oct: 1, vel: 80 },
      { t: 'mel', inst: 'horn', bar: 0, vel: 108, notes: 'E5:1.5 B4:0.5 E5:1 F#5:1 G5:3 F#5:1 E5:1 D5:1 C5:1 D5:1 E5:4 F#5:1.5 D5:0.5 F#5:1 A5:1 G5:2 F#5:2 D#5:1 E5:1 F#5:1 B4:1 D#5:4' },
      { t: 'mel', inst: 'violin', bar: 8, oct: 0, vel: 104, notes: 'B5:1.5 A5:0.5 G5:1 F#5:1 E5:3 B4:1 C5:1 E5:1 G5:1 C6:1 B5:4 A5:1 G5:1 F#5:1 E5:1 D#5:2 B4:2 E5:4 E5:4' },
      { t: 'mel', inst: 'trombone', bar: 8, oct: -1, vel: 96, notes: 'B5:1.5 A5:0.5 G5:1 F#5:1 E5:3 B4:1 C5:1 E5:1 G5:1 C6:1 B5:4 A5:1 G5:1 F#5:1 E5:1 D#5:2 B4:2 E5:4 E5:4' },
      { t: 'pad', inst: 'choir', from: 8, to: 16, oct: 1, vel: 70 },
      { t: 'hit', inst: 'timpani', key: 40, from: 0, to: 16, beats: [0, 2.5], vel: 104 },
      { t: 'hit', inst: 'drums', key: 35, from: 0, to: 16, beats: [0, 2], vel: 100 },
      { t: 'hit', inst: 'drums', key: 38, from: 0, to: 16, beats: [1, 3, 3.5], vel: 70 },
      { t: 'hit', inst: 'drums', key: 57, from: 0, to: 16, beats: [0], every: 4, vel: 96, dur: 3 },
    ] },

  // ---------------- BLASPHEMY CAESER: a magma serpent-emperor (Elden Ring) ----------------
  // C phrygian/minor. Spiccato strings, a chanting choir, then horns + trombones; heavy timpani.
  boss_caeser: { bpm: 132, meter: 4,
    chords: 'Cm Cm Ab Ab Fm Fm G G  Cm Cm Ab Ab Fm Fm G G',
    parts: [
      { t: 'ost', inst: 'strings', from: 0, to: 16, rel: [0, 0, 1, 0, 0, 0, -5, -4], step: 0.5, oct: 0, vel: 90 },
      { t: 'bass', inst: 'contrabass', from: 0, to: 16, pat: [[0, 1.5], [1.5, 0.5], [2, 2]], vel: 100 },
      { t: 'bass', inst: 'tuba', from: 0, to: 16, pat: [[0, 2]], vel: 80 },
      { t: 'mel', inst: 'choir', bar: 0, vel: 100, notes: 'C5:2 Db5:2 C5:4 Eb5:2 Db5:2 C5:4 Ab4:2 Bb4:2 C5:3 Db5:1 B4:4 G4:4' },
      { t: 'mel', inst: 'trombone', bar: 0, oct: -1, vel: 90, notes: 'C5:2 Db5:2 C5:4 Eb5:2 Db5:2 C5:4 Ab4:2 Bb4:2 C5:3 Db5:1 B4:4 G4:4' },
      { t: 'pad', inst: 'choir', from: 8, to: 16, oct: 1, vel: 76 },
      { t: 'mel', inst: 'horn', bar: 8, vel: 112, notes: 'G4:1 Ab4:1 G4:1 F4:1 Eb4:3 C4:1 Eb4:1 F4:1 G4:1 Ab4:1 G4:4 Ab4:1 G4:1 F4:1 Eb4:1 F4:2 G4:2 Ab4:2 G4:1 F4:1 G4:4' },
      { t: 'mel', inst: 'trumpet', bar: 8, oct: 1, vel: 92, notes: 'G4:1 Ab4:1 G4:1 F4:1 Eb4:3 C4:1 Eb4:1 F4:1 G4:1 Ab4:1 G4:4 Ab4:1 G4:1 F4:1 Eb4:1 F4:2 G4:2 Ab4:2 G4:1 F4:1 G4:4' },
      { t: 'hit', inst: 'timpani', key: 36, from: 0, to: 16, beats: [0, 1.5, 2], vel: 112 },
      { t: 'hit', inst: 'taiko', key: 45, from: 0, to: 16, beats: [3, 3.5], vel: 96 },
      { t: 'hit', inst: 'drums', key: 57, from: 0, to: 16, beats: [0], every: 4, vel: 104, dur: 3 },
      { t: 'hit', inst: 'drums', key: 38, from: 7, to: 8, beats: [2, 2.5, 3, 3.25, 3.5, 3.75], vel: 80 },
      { t: 'hit', inst: 'drums', key: 38, from: 15, to: 16, beats: [2, 2.5, 3, 3.25, 3.5, 3.75], vel: 80 },
    ] },

  // ---------------- CHILD WIELDING NEEDLE: a quick, deadly dance (Silksong) ----------------
  // B minor with a Phrygian C, 6/8 (eighth = beat). Harpsichord, violin, flute, pizzicato, castanets.
  boss_needle: { bpm: 270, meter: 6,
    chords: 'Bm F# C Bm Em A G F#  Bm Bm C Bm G A C F#',
    parts: [
      { t: 'arp', inst: 'harpsichord', from: 0, to: 16, pat: [[0, 0, 1], [1, 2, 1], [2, 1, 1], [3, 3, 1], [4, 2, 1], [5, 1, 1]], oct: 1, vel: 80 },
      { t: 'bass', inst: 'pizz', from: 0, to: 16, pat: [[0, 1], [3, 1], [5, 1]], vel: 100 },
      { t: 'bass', inst: 'cello', from: 0, to: 16, pat: [[0, 3]], vel: 70 },
      { t: 'mel', inst: 'violin', bar: 0, vel: 108, notes: 'B4:1 C#5:1 D5:1 F#5:2 E5:1 D5:1 C#5:1 B4:1 C#5:3 C5:1 B4:1 C5:1 E5:2 G5:1 F#5:6 B5:1 A5:1 G5:1 F#5:1 E5:1 D5:1 C#5:1 D5:1 E5:1 A4:3 G4:1 A4:1 B4:1 C5:1 B4:1 G4:1 F#4:6' },
      { t: 'mel', inst: 'violin', bar: 8, vel: 110, notes: 'F#5:1 G5:1 F#5:1 E5:1 D5:1 C#5:1 D5:3 B4:3 C5:1 D5:1 E5:1 G5:2 E5:1 F#5:6 B5:2 A5:1 G5:2 F#5:1 E5:2 D5:1 C#5:3 C5:1 B4:1 A#4:1 B4:1 C5:1 C#5:1 A#4:6' },
      { t: 'mel', inst: 'flute', bar: 8, oct: 1, vel: 80, notes: 'F#5:1 G5:1 F#5:1 E5:1 D5:1 C#5:1 D5:3 B4:3 C5:1 D5:1 E5:1 G5:2 E5:1 F#5:6 B5:2 A5:1 G5:2 F#5:1 E5:2 D5:1 C#5:3 C5:1 B4:1 A#4:1 B4:1 C5:1 C#5:1 A#4:6' },
      { t: 'pad', inst: 'tremolo', from: 8, to: 16, vel: 60 },
      { t: 'hit', inst: 'taiko', key: 45, from: 0, to: 16, beats: [0, 3], vel: 100 },
      { t: 'hit', inst: 'drums', key: 39, from: 0, to: 16, beats: [1, 2, 4, 5], vel: 70 },      // Castanets
      { t: 'hit', inst: 'drums', key: 54, from: 8, to: 16, beats: [0, 2, 3, 5], vel: 60 },      // Tambourine
      { t: 'hit', inst: 'drums', key: 57, from: 0, to: 16, beats: [0], every: 8, vel: 90, dur: 3 },
    ] },

  // ---------------- THE SUN: a radiant god (Elden Ring) ----------------
  // E major with borrowed C and D chords, 3/4. Organ, choir, harp, then trumpets + violins.
  boss_sun: { bpm: 84, meter: 3,
    chords: 'E E C#m C#m A A B B  C C D D E E B B',
    parts: [
      { t: 'pad', inst: 'organ', from: 0, to: 16, vel: 70 },
      { t: 'pad', inst: 'choir', from: 0, to: 16, oct: 1, vel: 74 },
      { t: 'arp', inst: 'harp', from: 0, to: 16, pat: [[0, 0, 1], [0.5, 1, 1], [1, 2, 1], [1.5, 3, 1], [2, 4, 1], [2.5, 5, 1]], oct: 1, vel: 66 },
      { t: 'bass', inst: 'contrabass', from: 0, to: 16, pat: [[0, 3]], vel: 84 },
      { t: 'mel', inst: 'horn', bar: 0, vel: 104, notes: 'B4:2 E5:1 G#5:3 F#5:1 E5:1 D#5:1 E5:1.5 C#5:1.5 C#5:2 E5:1 A5:3 B5:1.5 A5:0.5 G#5:1 F#5:3' },
      { t: 'mel', inst: 'trumpet', bar: 8, vel: 108, notes: 'C5:1 E5:1 G5:1 C6:3 D5:1 F#5:1 A5:1 D6:3 E5:1 G#5:1 B5:1 E6:2 D#6:1 B5:3 F#5:3' },
      { t: 'mel', inst: 'violin', bar: 8, vel: 96, notes: 'C5:1 E5:1 G5:1 C6:3 D5:1 F#5:1 A5:1 D6:3 E5:1 G#5:1 B5:1 E6:2 D#6:1 B5:3 F#5:3' },
      { t: 'hit', inst: 'timpani', key: 40, from: 0, to: 16, beats: [0], vel: 100 },
      { t: 'hit', inst: 'timpani', key: 40, from: 8, to: 16, beats: [2, 2.5], vel: 84 },
      { t: 'hit', inst: 'bells', key: 76, from: 0, to: 16, beats: [0], every: 2, vel: 80, dur: 3 },
      { t: 'hit', inst: 'drums', key: 57, from: 0, to: 16, beats: [0], every: 4, vel: 96, dur: 4 },
    ] },

  // ---------------- THE SUN, CONSUMED (phase 2): the theme collapses into C# minor ----------------
  boss_consumer: { bpm: 104, meter: 3,
    chords: 'C#m C#m G# C#m A F#m G# G#  C#m C#m G# C#m A F#m G# G#',
    parts: [
      { t: 'ost', inst: 'strings', from: 0, to: 16, rel: [0, 12, 7, 12, 3, 12], step: 0.5, vel: 88 },
      { t: 'pad', inst: 'organ', from: 0, to: 16, vel: 72 },
      { t: 'bass', inst: 'contrabass', from: 0, to: 16, pat: [[0, 1.5], [1.5, 1.5]], vel: 96 },
      { t: 'bass', inst: 'tuba', from: 0, to: 16, pat: [[0, 3]], vel: 86 },
      { t: 'mel', inst: 'choir', bar: 0, vel: 104, notes: 'G#4:2 C#5:1 E5:3 D#5:1 C#5:1 B#4:1 C#5:3 C#5:2 E5:1 A5:3 G#5:1.5 F#5:0.5 E5:1 D#5:3' },
      { t: 'mel', inst: 'trombone', bar: 0, oct: -1, vel: 96, notes: 'G#4:2 C#5:1 E5:3 D#5:1 C#5:1 B#4:1 C#5:3 C#5:2 E5:1 A5:3 G#5:1.5 F#5:0.5 E5:1 D#5:3' },
      { t: 'mel', inst: 'trumpet', bar: 8, oct: 1, vel: 104, notes: 'G#4:2 C#5:1 E5:3 D#5:1 C#5:1 B#4:1 C#5:3 C#5:2 E5:1 A5:3 G#5:1.5 F#5:0.5 E5:1 D#5:3' },
      { t: 'mel', inst: 'violin', bar: 8, oct: 1, vel: 98, notes: 'G#4:2 C#5:1 E5:3 D#5:1 C#5:1 B#4:1 C#5:3 C#5:2 E5:1 A5:3 G#5:1.5 F#5:0.5 E5:1 D#5:3' },
      { t: 'pad', inst: 'choir', from: 8, to: 16, oct: 1, vel: 80 },
      { t: 'hit', inst: 'timpani', key: 37, from: 0, to: 16, beats: [0, 1, 2], vel: 110 },
      { t: 'hit', inst: 'drums', key: 35, from: 0, to: 16, beats: [0], vel: 110 },
      { t: 'hit', inst: 'drums', key: 59, from: 0, to: 16, beats: [0], every: 2, vel: 100, dur: 3 },
      { t: 'hit', inst: 'bells', key: 73, from: 0, to: 16, beats: [1.5], every: 2, vel: 80, dur: 2 },
    ] },

  // ---------------- SATAN: an infernal cathedral ----------------
  // C minor 4/4, slow and crushing. Church organ, tolling bells, low brass, then a high choir.
  boss_satan: { bpm: 76, meter: 4,
    chords: 'Cm Db Cm Ab Ab Fm G G  Cm Cm Fm Ab Db Fm G G',
    parts: [
      { t: 'pad', inst: 'organ', from: 0, to: 16, vel: 78 },
      { t: 'bass', inst: 'contrabass', from: 0, to: 16, pat: [[0, 2], [2, 1], [3, 1]], vel: 96 },
      { t: 'ost', inst: 'cello', from: 0, to: 16, rel: [0, 0, 0, 1, 0, 0, -1, 0], step: 0.5, oct: 0, vel: 84 },
      { t: 'mel', inst: 'trombone', bar: 0, vel: 108, notes: 'C4:3 Eb4:1 Db4:4 C4:2 G3:2 Ab3:4 Ab3:2 C4:2 F4:3 Eb4:1 D4:4 B3:4' },
      { t: 'mel', inst: 'tuba', bar: 0, oct: -1, vel: 96, notes: 'C4:3 Eb4:1 Db4:4 C4:2 G3:2 Ab3:4 Ab3:2 C4:2 F4:3 Eb4:1 D4:4 B3:4' },
      { t: 'mel', inst: 'choir', bar: 8, vel: 108, notes: 'G5:3 Ab5:1 G5:4 F5:2 Eb5:2 C5:4 Db5:2 C5:2 Ab4:2 F4:2 G4:4 G4:4' },
      { t: 'mel', inst: 'horn', bar: 8, oct: -1, vel: 96, notes: 'G5:3 Ab5:1 G5:4 F5:2 Eb5:2 C5:4 Db5:2 C5:2 Ab4:2 F4:2 G4:4 G4:4' },
      { t: 'pad', inst: 'choir', from: 8, to: 16, vel: 70 },
      { t: 'hit', inst: 'bells', key: 60, from: 0, to: 16, beats: [0], vel: 100, dur: 4 },
      { t: 'hit', inst: 'timpani', key: 36, from: 0, to: 16, beats: [0, 2, 3.5], vel: 112 },
      { t: 'hit', inst: 'drums', key: 35, from: 0, to: 16, beats: [0, 2], vel: 110 },
      { t: 'hit', inst: 'drums', key: 59, from: 0, to: 16, beats: [0], every: 4, vel: 104, dur: 4 },
    ] },

  // ---------------- MOTHER NATURE: a tragic waltz (Elden Ring) ----------------
  // G minor 3/4. Harp waltz + solo violin, then flute, violins and choir.
  boss_nature: { bpm: 96, meter: 3,
    chords: 'Gm Gm Eb Eb Cm Cm D D  Gm Gm Eb Eb Cm D Gm Gm',
    parts: [
      { t: 'bass', inst: 'harp', from: 0, to: 16, pat: [[0, 1]], oct: 1, vel: 84 },
      { t: 'arp', inst: 'harp', from: 0, to: 16, pat: [[1, 3, 1], [1, 4, 1], [2, 3, 1], [2, 4, 1]], oct: 0, vel: 64 },
      { t: 'bass', inst: 'cello', from: 0, to: 16, pat: [[0, 3]], vel: 74 },
      { t: 'pad', inst: 'slowstrings', from: 0, to: 16, vel: 56 },
      { t: 'mel', inst: 'violin', bar: 0, vel: 104, notes: 'D5:2 Bb4:1 G5:2 F5:1 Eb5:1.5 D5:0.5 C5:1 Bb4:3 C5:1 Eb5:1 G5:1 G5:2 F5:1 F#5:1.5 E5:0.5 F#5:1 D5:3' },
      { t: 'mel', inst: 'flute', bar: 8, vel: 96, notes: 'D5:2 Bb4:1 D6:2 C6:1 Bb5:1.5 A5:0.5 G5:1 G5:3 Eb5:1 G5:1 C6:1 A5:1.5 F#5:0.5 A5:1 G5:3 G5:3' },
      { t: 'mel', inst: 'violin', bar: 8, oct: -1, vel: 96, notes: 'D5:2 Bb4:1 D6:2 C6:1 Bb5:1.5 A5:0.5 G5:1 G5:3 Eb5:1 G5:1 C6:1 A5:1.5 F#5:0.5 A5:1 G5:3 G5:3' },
      { t: 'pad', inst: 'choir', from: 8, to: 16, oct: 1, vel: 68 },
      { t: 'hit', inst: 'timpani', key: 43, from: 8, to: 16, beats: [0], vel: 84 },
      { t: 'hit', inst: 'bells', key: 79, from: 0, to: 16, beats: [0], every: 4, vel: 66, dur: 3 },
    ] },

  // ---------------- CAVES: a mossy, curious wander (Silksong) ----------------
  // A dorian 6/8 (eighth = beat). Harp + pizzicato, flute melody, then violin.
  story_cave: { bpm: 200, meter: 6,
    chords: 'Am Am D D Am Am G G  F F G G Am Am E E',
    parts: [
      { t: 'arp', inst: 'harp', from: 0, to: 16, pat: [[0, 0, 2], [2, 1, 1], [3, 2, 2], [5, 1, 1]], oct: 1, vel: 66 },
      { t: 'bass', inst: 'pizz', from: 0, to: 16, pat: [[0, 2], [3, 2]], vel: 86 },
      { t: 'pad', inst: 'slowstrings', from: 0, to: 16, vel: 44 },
      { t: 'mel', inst: 'flute', bar: 0, vel: 92, notes: 'E5:3 D5:1 C5:1 B4:1 A4:6 F#5:3 E5:1 D5:1 E5:1 F#5:6 E5:2 C5:1 A4:2 B4:1 C5:3 B4:3 D5:2 B4:1 G4:2 A4:1 B4:6' },
      { t: 'mel', inst: 'violin', bar: 8, vel: 92, notes: 'C5:2 A4:1 F5:2 E5:1 C5:6 D5:2 B4:1 G5:2 F5:1 D5:6 E5:2 C5:1 A5:2 G5:1 E5:3 C5:3 B4:2 G#4:1 E4:2 G#4:1 B4:6' },
      { t: 'mel', inst: 'celesta', bar: 8, oct: 1, vel: 60, notes: 'C5:2 A4:1 F5:2 E5:1 C5:6 D5:2 B4:1 G5:2 F5:1 D5:6 E5:2 C5:1 A5:2 G5:1 E5:3 C5:3 B4:2 G#4:1 E4:2 G#4:1 B4:6' },
      { t: 'hit', inst: 'drums', key: 82, from: 0, to: 16, beats: [0, 2, 3, 5], vel: 40 },      // Soft shaker
      { t: 'hit', inst: 'drums', key: 77, from: 0, to: 16, beats: [3], every: 2, vel: 56 },     // Woodblock
    ] },

  // ---------------- THE VOID: lost, empty, beautiful ----------------
  // D minor 4/4, slow. Low string drones, a lonely piano, celesta echoes, voices far away.
  story_void: { bpm: 60, meter: 4,
    chords: 'Dm Dm A A Dm Bb Dm Dm Bb Gm A A',
    parts: [
      { t: 'pad', inst: 'slowstrings', from: 0, to: 12, oct: -1, vel: 54 },
      { t: 'pad', inst: 'oohs', from: 0, to: 12, oct: 1, vel: 46 },
      { t: 'bass', inst: 'contrabass', from: 0, to: 12, pat: [[0, 4]], vel: 60 },
      { t: 'mel', inst: 'piano', bar: 0, vel: 74, notes: 'A4:4 r:2 F4:2 E4:4 r:4 D4:2 A4:2 Bb4:4 A4:4 r:4 F4:2 E4:2 D4:4 C#4:4 r:4' },
      { t: 'mel', inst: 'celesta', bar: 0, oct: 1, vel: 40, shift: 0.75, notes: 'A4:4 r:2 F4:2 E4:4 r:4 D4:2 A4:2 Bb4:4 A4:4 r:4 F4:2 E4:2 D4:4 C#4:4 r:4' },
      { t: 'mel', inst: 'cello', bar: 4, oct: -1, vel: 70, notes: 'D5:4 F5:4 A4:8 D5:4 E5:4 C#5:8' },
      { t: 'hit', inst: 'bells', key: 62, from: 0, to: 12, beats: [0], every: 4, vel: 50, dur: 4 },
    ] },

  // ---------------- THE ENLIGHTENED CHASE: a desert pursuit ----------------
  // D phrygian dominant 6/8 (eighth = beat), galloping. Strings gallop, taiko, violins then horns + choir.
  story_chase: { bpm: 330, meter: 6,
    chords: 'D D Eb D Gm D Cm D  D D Eb D Gm D Cm D',
    parts: [
      { t: 'ost', inst: 'strings', from: 0, to: 16, rel: [0, 0, 0, 0, 0, 7], step: 1, oct: 0, vel: 84 },
      { t: 'bass', inst: 'contrabass', from: 0, to: 16, pat: [[0, 2], [3, 2]], vel: 96 },
      { t: 'bass', inst: 'cello', from: 0, to: 16, pat: [[0, 1], [2, 1], [3, 1], [5, 1]], oct: 1, vel: 82 },
      { t: 'mel', inst: 'violin', bar: 0, vel: 108, notes: 'D5:1 Eb5:1 F#5:1 G5:3 A5:2 G5:1 F#5:3 Eb5:1 F#5:1 G5:1 Bb5:3 A5:6 A5:2 Bb5:1 A5:2 G5:1 F#5:3 Eb5:3 G5:1 F#5:1 Eb5:1 D5:3 D5:6' },
      { t: 'mel', inst: 'horn', bar: 8, vel: 112, notes: 'D5:1 Eb5:1 F#5:1 G5:3 A5:2 G5:1 F#5:3 Eb5:1 F#5:1 G5:1 Bb5:3 A5:6 A5:2 Bb5:1 A5:2 G5:1 F#5:3 Eb5:3 G5:1 F#5:1 Eb5:1 D5:3 D5:6' },
      { t: 'mel', inst: 'violin', bar: 8, oct: 1, vel: 96, notes: 'D5:1 Eb5:1 F#5:1 G5:3 A5:2 G5:1 F#5:3 Eb5:1 F#5:1 G5:1 Bb5:3 A5:6 A5:2 Bb5:1 A5:2 G5:1 F#5:3 Eb5:3 G5:1 F#5:1 Eb5:1 D5:3 D5:6' },
      { t: 'pad', inst: 'choir', from: 8, to: 16, oct: 1, vel: 74 },
      { t: 'hit', inst: 'taiko', key: 45, from: 0, to: 16, beats: [0, 2, 3, 5], vel: 108 },
      { t: 'hit', inst: 'drums', key: 54, from: 0, to: 16, beats: [1, 4], vel: 70 },
      { t: 'hit', inst: 'drums', key: 57, from: 0, to: 16, beats: [0], every: 4, vel: 96, dur: 3 },
    ] },
  // ======================= DEMILAND (open world) =======================
  // ---------------- DEMILAND (day): an open field under a dead sky (Elden Ring) ----------------
  // E minor 3/4. A: harp + solo cello. A': solo violin. B: horn + choir swell over the whole land.
  story_demiland: { bpm: 66, meter: 3, rev: 0.4,
    chords: 'Em Em C C G G D D  Em Em C C Am Am B B  C C G G Am B Em Em',
    parts: [
      { t: 'arp', inst: 'harp', from: 0, to: 24, pat: [[0, 0, 1.5], [1, 1, 1], [2, 2, 1]], oct: 1, vel: 58 },
      { t: 'pad', inst: 'slowstrings', from: 0, to: 24, vel: 50 },
      { t: 'bass', inst: 'contrabass', from: 0, to: 24, pat: [[0, 3]], vel: 56 },
      { t: 'mel', inst: 'cello', bar: 0, oct: -1, vel: 90, notes: 'E4:2 B4:1 A4:1.5 G4:0.5 F#4:1 G4:3 E4:3 D4:2 G4:1 F#4:1.5 E4:0.5 D4:1 A4:3 F#4:3' },
      { t: 'mel', inst: 'violin', bar: 8, vel: 94, notes: 'E5:2 B5:1 A5:1.5 G5:0.5 F#5:1 G5:2 E5:1 C5:3 A4:1 C5:1 E5:1 A5:3 B5:1.5 A5:0.5 G5:1 F#5:3' },
      { t: 'mel', inst: 'horn', bar: 16, vel: 100, notes: 'E5:2 G5:1 C6:3 B5:2 G5:1 D5:3 C5:1 E5:1 A5:1 B5:2 D#5:1 E5:3 E5:3' },
      { t: 'pad', inst: 'choir', from: 16, to: 24, oct: 1, vel: 64 },
      { t: 'hit', inst: 'timpani', key: 40, from: 16, to: 24, beats: [0], every: 2, vel: 80 },
      { t: 'hit', inst: 'bells', key: 64, from: 0, to: 24, beats: [0], every: 8, vel: 46, dur: 4 },
    ] },

  // ---------------- DEMILAND (night): darker than dark ----------------
  // D minor 4/4, very slow. Low drones, a lonely piano, far bells, voices in the dark.
  story_demiland_night: { bpm: 54, meter: 4, rev: 0.45,
    chords: 'Dm Dm Bb Bb Gm Gm A A Dm Bb A Dm',
    parts: [
      { t: 'pad', inst: 'slowstrings', from: 0, to: 12, oct: -1, vel: 50 },
      { t: 'pad', inst: 'oohs', from: 0, to: 12, vel: 40 },
      { t: 'bass', inst: 'contrabass', from: 0, to: 12, pat: [[0, 4]], vel: 58 },
      { t: 'mel', inst: 'piano', bar: 0, vel: 70, notes: 'D5:3 r:1 C5:2 A4:2 Bb4:4 r:4 G4:2 Bb4:2 D5:4 C#5:4 r:4 F5:2 E5:2 D5:4 C#5:2 E5:2 D5:4' },
      { t: 'mel', inst: 'celesta', bar: 0, oct: 1, vel: 34, shift: 1.0, notes: 'D5:3 r:1 C5:2 A4:2 Bb4:4 r:4 G4:2 Bb4:2 D5:4 C#5:4 r:4 F5:2 E5:2 D5:4 C#5:2 E5:2 D5:4' },
      { t: 'hit', inst: 'bells', key: 50, from: 0, to: 12, beats: [0], every: 3, vel: 52, dur: 5 },
      { t: 'hit', inst: 'timpani', key: 38, from: 0, to: 12, beats: [0], every: 4, vel: 50 },
    ] },

  // ---------------- THE TRIBE MASTER: a primitive war ritual ----------------
  // A minor 4/4. Taiko + timpani war drums, stabbing low strings, a chanting choir, then horns.
  boss_tribe: { bpm: 126, meter: 4,
    chords: 'Am Am Bb Am Am G F E  Am Am Bb Am F G Bb E',
    parts: [
      { t: 'ost', inst: 'strings', from: 0, to: 16, rel: [0, 0, 12, 0, 1, 0, 12, 0], step: 0.5, oct: -1, vel: 88 },
      { t: 'bass', inst: 'contrabass', from: 0, to: 16, pat: [[0, 1], [0.75, 0.5], [2, 1], [3, 0.5]], vel: 100 },
      { t: 'bass', inst: 'tuba', from: 0, to: 16, pat: [[0, 2]], vel: 76 },
      { t: 'mel', inst: 'choir', bar: 0, vel: 104, notes: 'A4:2 A4:1 C5:1 B4:2 A4:2 Bb4:2 A4:1 G4:1 A4:4 E5:2 D5:1 C5:1 B4:2 G4:2 A4:2 F4:2 E4:4' },
      { t: 'mel', inst: 'trombone', bar: 0, oct: -1, vel: 88, notes: 'A4:2 A4:1 C5:1 B4:2 A4:2 Bb4:2 A4:1 G4:1 A4:4 E5:2 D5:1 C5:1 B4:2 G4:2 A4:2 F4:2 E4:4' },
      { t: 'mel', inst: 'horn', bar: 8, vel: 112, notes: 'E5:1 F5:1 E5:1 D5:1 C5:2 A4:2 D5:1 F5:1 D5:1 Bb4:1 A4:4 A4:1 C5:1 F5:1 A5:1 G5:2 D5:2 F5:2 D5:1 Bb4:1 B4:4' },
      { t: 'mel', inst: 'trumpet', bar: 8, oct: 1, vel: 86, notes: 'E5:1 F5:1 E5:1 D5:1 C5:2 A4:2 D5:1 F5:1 D5:1 Bb4:1 A4:4 A4:1 C5:1 F5:1 A5:1 G5:2 D5:2 F5:2 D5:1 Bb4:1 B4:4' },
      { t: 'pad', inst: 'choir', from: 8, to: 16, vel: 70 },
      { t: 'hit', inst: 'taiko', key: 45, from: 0, to: 16, beats: [0, 0.75, 1.5, 2, 3, 3.5], vel: 112 },
      { t: 'hit', inst: 'timpani', key: 33, from: 0, to: 16, beats: [0, 2], vel: 110 },
      { t: 'hit', inst: 'drums', key: 82, from: 0, to: 16, beats: [0.5, 1, 2.5, 3], vel: 64 },
      { t: 'hit', inst: 'drums', key: 57, from: 0, to: 16, beats: [0], every: 4, vel: 100, dur: 3 },
    ] },

  // ---------------- THE LAST TIGER: a feral, starving hunt ----------------
  // C# minor 6/8 (eighth = beat), fast. Galloping strings, racing violin, then horns + trombones.
  boss_tiger: { bpm: 300, meter: 6,
    chords: 'C#m C#m A A F#m F#m G# G#  C#m C#m A A D D G# G#',
    parts: [
      { t: 'ost', inst: 'strings', from: 0, to: 16, rel: [0, 0, 7, 0, 0, 7], step: 1, oct: -1, vel: 86 },
      { t: 'pad', inst: 'tremolo', from: 0, to: 16, vel: 56 },
      { t: 'bass', inst: 'contrabass', from: 0, to: 16, pat: [[0, 2], [3, 2]], vel: 100 },
      { t: 'bass', inst: 'pizz', from: 0, to: 16, pat: [[0, 1], [2, 1], [3, 1], [5, 1]], oct: 1, vel: 84 },
      { t: 'mel', inst: 'violin', bar: 0, vel: 110, notes: 'C#5:1 D#5:1 E5:1 G#5:3 F#5:1 E5:1 D#5:1 E5:3 E5:1 F#5:1 G#5:1 A5:3 A5:6 F#5:1 G#5:1 A5:1 C#6:3 B5:1 A5:1 G#5:1 F#5:3 D#5:1 E5:1 F#5:1 G#5:3 B#4:3 G#4:3' },
      { t: 'mel', inst: 'horn', bar: 8, vel: 114, notes: 'C#5:3 E5:3 G#5:3 F#5:1 E5:1 D#5:1 E5:3 C#5:3 A4:6 C#5:3 E5:3 A5:3 F#5:3 G#5:3 F#5:1 E5:1 D#5:1 B#4:6' },
      { t: 'mel', inst: 'trombone', bar: 8, oct: -1, vel: 98, notes: 'C#5:3 E5:3 G#5:3 F#5:1 E5:1 D#5:1 E5:3 C#5:3 A4:6 C#5:3 E5:3 A5:3 F#5:3 G#5:3 F#5:1 E5:1 D#5:1 B#4:6' },
      { t: 'hit', inst: 'taiko', key: 45, from: 0, to: 16, beats: [0, 3], vel: 114 },
      { t: 'hit', inst: 'timpani', key: 37, from: 0, to: 16, beats: [0], vel: 104 },
      { t: 'hit', inst: 'drums', key: 38, from: 0, to: 16, beats: [5], vel: 72 },
      { t: 'hit', inst: 'drums', key: 57, from: 0, to: 16, beats: [0], every: 4, vel: 98, dur: 3 },
    ] },

  // ---------------- THE LIVING TREE LORD: the funeral of nature ----------------
  // G minor 3/4, slow and heavy. Organ, low strings, an oboe lament, then horns + a full choir.
  boss_treelord: { bpm: 80, meter: 3, rev: 0.4,
    chords: 'Gm Gm Eb Eb Cm Cm D D  Gm Gm Eb Eb Cm D Gm Gm',
    parts: [
      { t: 'pad', inst: 'organ', from: 0, to: 16, vel: 70 },
      { t: 'pad', inst: 'strings', from: 0, to: 16, oct: -1, vel: 62 },
      { t: 'bass', inst: 'contrabass', from: 0, to: 16, pat: [[0, 1.5], [1.5, 1.5]], vel: 92 },
      { t: 'bass', inst: 'bassoon', from: 0, to: 8, pat: [[0, 3]], oct: 1, vel: 70 },
      { t: 'mel', inst: 'oboe', bar: 0, vel: 98, notes: 'G4:2 A4:1 Bb4:2 D5:1 C5:1.5 Bb4:0.5 A4:1 G4:3 Eb5:2 D5:1 C5:2 Bb4:1 A4:1.5 G4:0.5 F#4:1 D4:3' },
      { t: 'mel', inst: 'cello', bar: 0, oct: -1, vel: 76, notes: 'G4:2 A4:1 Bb4:2 D5:1 C5:1.5 Bb4:0.5 A4:1 G4:3 Eb5:2 D5:1 C5:2 Bb4:1 A4:1.5 G4:0.5 F#4:1 D4:3' },
      { t: 'mel', inst: 'horn', bar: 8, vel: 110, notes: 'D5:2 G5:1 F5:2 D5:1 Eb5:2 G5:1 Bb5:3 C6:2 G5:1 F#5:1.5 E5:0.5 F#5:1 G5:3 G5:3' },
      { t: 'mel', inst: 'choir', bar: 8, vel: 96, notes: 'D5:2 G5:1 F5:2 D5:1 Eb5:2 G5:1 Bb5:3 C6:2 G5:1 F#5:1.5 E5:0.5 F#5:1 G5:3 G5:3' },
      { t: 'pad', inst: 'choir', from: 8, to: 16, vel: 66 },
      { t: 'hit', inst: 'timpani', key: 31, from: 0, to: 16, beats: [0], vel: 108 },
      { t: 'hit', inst: 'timpani', key: 38, from: 8, to: 16, beats: [2, 2.5], vel: 88 },
      { t: 'hit', inst: 'bells', key: 55, from: 0, to: 16, beats: [0], every: 4, vel: 70, dur: 4 },
      { t: 'hit', inst: 'drums', key: 59, from: 0, to: 16, beats: [0], every: 8, vel: 96, dur: 4 },
    ] },
};

// ------------------------------------------------------------------------------------------
const NN ={ C: 0, D: 2, E: 4, F: 5, G: 7, A: 9, B: 11 };
function midi(s) {                                       // "C#4" -> 61 (B#4 = C5, Cb4 = B3)
  const m = /^([A-G])([#b]?)(-?\d)$/.exec(s);
  if (!m) throw new Error('bad note: ' + s);
  return 12 * (+m[3] + 1) + NN[m[1]] + (m[2] === '#' ? 1 : (m[2] === 'b' ? -1 : 0));
}
function chord(name) {                                   // "Dm" -> {root, tones (from octave 3), bass}
  const m = /^([A-G][#b]?)(m|dim|aug|sus4|sus2)?(7)?$/.exec(name);
  if (!m) throw new Error('bad chord: ' + name);
  const root = midi(m[1] + '3');
  let iv = { m: [0, 3, 7], dim: [0, 3, 6], aug: [0, 4, 8], sus4: [0, 5, 7], sus2: [0, 2, 7] }[m[2]] || [0, 4, 7];
  if (m[3]) iv = iv.concat([10]);
  return { root, tones: iv.map((x) => root + x) };
}
const tone = (c, i) => c.tones[i % c.tones.length] + 12 * Math.floor(i / c.tones.length);

// Turns a piece into notes: [{inst, key, vel, at (beats), dur (beats)}] + its length in beats.
// A string pad becomes a real STRING SECTION voiced by range (double basses, celli, violas,
// violins: the solo recordings layered with the string ensemble).
const STRING_PADS = { strings: 'strings', slowstrings: 'slowstrings', tremolo: 'tremolo' };

function build(p) {
  const chords = p.chords.trim().split(/\s+/).map(chord);
  const bars = chords.length, M = p.meter, E = [];
  const add = (inst, key, vel, at, dur, g = 1) => E.push({ inst, key, vel, at, dur, g });
  for (const q of p.parts) {
    const oct = 12 * (q.oct || 0), vel = q.vel || 90;
    const from = q.from || 0, to = q.to === undefined ? bars : q.to;
    if (q.t === 'mel') {
      let t = q.bar * M + (q.shift || 0);
      for (const tok of q.notes.trim().split(/\s+/)) {
        const [n, d] = tok.split(':'); const dd = d === undefined ? 1 : +d;
        if (n !== 'r') {
          add(q.inst, midi(n) + oct, vel, t, dd);
          for (const [di, dsh, dg] of (q.dbl || [])) add(di, midi(n) + oct + 12 * dsh, vel - 10, t, dd, dg);   // Doublings
        }
        t += dd;
      }
      continue;
    }
    for (let bar = from; bar < to; bar++) {
      const c = chords[bar], b0 = bar * M;
      if (q.every && (bar - from) % q.every) continue;
      if (q.t === 'pad' && STRING_PADS[q.inst]) {
        const ens = STRING_PADS[q.inst], tn = [...c.tones].sort((a, b) => a - b);
        add('contrabass', tn[0] - 12 + oct, vel - 6, b0, M, 0.55);
        add('cello', tn[0] + oct, vel, b0, M, 0.45);
        add(ens, tn[0] + oct, vel, b0, M, 0.3);
        add('viola', tn[1] + 12 + oct, vel - 4, b0, M, 0.4);
        add('violin', tn[tn.length - 1] + 12 + oct, vel, b0, M, 0.4);
        add(ens, tn[0] + 24 + oct, vel, b0, M, 0.32);
        add(ens, tn[1] + 24 + oct, vel - 6, b0, M, 0.25);
        continue;
      }
      if (q.t === 'pad') for (const k of c.tones) add(q.inst, k + 12 + oct, vel, b0, M);
      if (q.t === 'bass') for (const [bt, d] of q.pat) add(q.inst, c.root - 12 + oct, vel + (bt === 0 ? 8 : 0), b0 + bt, d);
      if (q.t === 'arp') for (const [bt, i, d] of q.pat) add(q.inst, tone(c, i) + oct, vel, b0 + bt, d);
      if (q.t === 'ost') for (let s = 0; s * q.step < M; s++) add(q.inst, c.root + q.rel[s % q.rel.length] + oct, vel + (s === 0 ? 14 : 0), b0 + s * q.step, q.step);
      if (q.t === 'hit') for (const bt of q.beats) add(q.inst, q.key, vel, b0 + bt, q.dur || 1);
    }
  }
  return { notes: E, beats: bars * M };
}

// ==========================================================================================
// FULL-ORCHESTRA REVAMP (2026-11-13): every piece gets more of the orchestra. Melodies stay the
// same; `dbl` adds instruments that double a melody part (by its instrument): [instrument,
// octave shift, gain]. "voice" = a SOLO VOCALIST (low = male, high = female). `parts` = new lines.
// Instruments without a real recording: crumhorn (= bagpipe chanter, also a capped buzzing reed),
// euphonium (= trombone + horn blend), E-flat / bass clarinet (= the clarinet high / low).
// ==========================================================================================
const MORE = {
  menu: { dbl: { cello: [['clarinet', 1, 0.3]], violin: [['flute', 0, 0.3], ['voice', 0, 0.3]], horn: [['euphonium', -1, 0.4], ['trumpet', 0, 0.22]] },
    parts: [{ t: 'arp', inst: 'piano', from: 8, to: 16, pat: [[0, 0, 1], [1, 2, 1], [2, 4, 1]], oct: 1, vel: 46 },
      { t: 'hit', inst: 'drums', key: 38, from: 15, to: 16, beats: [2, 2.25, 2.5, 2.75], vel: 64 }] },
  fight: { dbl: { violin: [['piccolo', 1, 0.2], ['xylophone', 1, 0.22]], horn: [['clarinet', 0, 0.3], ['euphonium', -1, 0.35]], trombone: [['tuba', -1, 0.3]] },
    parts: [{ t: 'hit', inst: 'drums', key: 38, from: 0, to: 16, beats: [0.5, 1.5, 2.5, 3.5], vel: 44 }] },
  boss_caeser: { dbl: { choir: [['voice', -1, 0.45]], trombone: [['euphonium', 0, 0.4]], horn: [['trumpet', 0, 0.28], ['englishhorn', 0, 0.22]] },
    parts: [{ t: 'pad', inst: 'organ', from: 8, to: 16, oct: -1, vel: 58 },
      { t: 'ost', inst: 'bassoon', from: 0, to: 16, rel: [0, 0, 1, 0, 0, 0, -5, -4], step: 0.5, oct: -1, vel: 66 }] },
  boss_needle: { dbl: { violin: [['xylophone', 1, 0.28]], flute: [['piccolo', 0, 0.22]] },
    parts: [{ t: 'arp', inst: 'clarinet', from: 8, to: 16, pat: [[0, 0, 3], [3, 2, 3]], oct: 1, vel: 58 }] },
  boss_sun: { dbl: { horn: [['voice', 1, 0.4], ['flute', 1, 0.22]], trumpet: [['piccolo', 1, 0.18], ['euphonium', -1, 0.35]], violin: [['oboe', 0, 0.28]] },
    parts: [{ t: 'hit', inst: 'glock', key: 88, from: 0, to: 16, beats: [0, 1.5], vel: 52, dur: 1 }] },
  boss_consumer: { dbl: { choir: [['voice', -1, 0.45]], trombone: [['euphonium', 0, 0.45]], trumpet: [['clarinet', 0, 0.25]], violin: [['xylophone', 0, 0.22]] },
    parts: [{ t: 'hit', inst: 'drums', key: 38, from: 0, to: 16, beats: [2, 2.25, 2.5, 2.75], every: 4, vel: 70 }] },
  boss_satan: { dbl: { trombone: [['euphonium', 0, 0.5]], choir: [['voice', -1, 0.5]], horn: [['bassoon', 0, 0.35]] } },
  boss_nature: { dbl: { violin: [['clarinet', 0, 0.3]], flute: [['voice', 0, 0.45]] },
    parts: [{ t: 'arp', inst: 'guitar', from: 8, to: 16, pat: [[0, 0, 1], [1, 1, 1], [2, 2, 1]], vel: 50 }] },
  story_cave: { dbl: { flute: [['clarinet', -1, 0.3]], violin: [['oboe', 0, 0.25]] },
    parts: [{ t: 'arp', inst: 'marimba', from: 8, to: 16, pat: [[0, 0, 1], [3, 2, 1]], oct: 1, vel: 48 }] },
  story_void: { dbl: { cello: [['clarinet', 0, 0.3], ['voice', 1, 0.28]] } },
  story_chase: { dbl: { violin: [['piccolo', 1, 0.2], ['crumhorn', 0, 0.28]], horn: [['euphonium', -1, 0.4], ['trumpet', 0, 0.3]] },
    parts: [{ t: 'hit', inst: 'drums', key: 38, from: 0, to: 16, beats: [1, 4], vel: 58 }] },
  story_demiland: { dbl: { cello: [['clarinet', 1, 0.25], ['crumhorn', 1, 0.18]], violin: [['flute', 0, 0.25]], horn: [['euphonium', -1, 0.35], ['voice', -1, 0.35]] },
    parts: [{ t: 'arp', inst: 'guitar', from: 8, to: 16, pat: [[0, 0, 1], [1, 1, 1], [2, 2, 1]], vel: 46 }] },
  story_demiland_night: { dbl: { piano: [['voice', 0, 0.25]] } },
  boss_tribe: { dbl: { choir: [['voice', -1, 0.5]], trombone: [['euphonium', 0, 0.4]], horn: [['crumhorn', 0, 0.3], ['trumpet', 0, 0.22]], trumpet: [['piccolo', 0, 0.18]] },
    parts: [{ t: 'ost', inst: 'marimba', from: 0, to: 16, rel: [0, 7, 12, 7], step: 1, oct: 1, vel: 58 },
      { t: 'hit', inst: 'castanets', key: 60, from: 8, to: 16, beats: [0.5, 1.5, 2.5, 3.5], vel: 70 }] },
  boss_tiger: { dbl: { violin: [['piccolo', 1, 0.2], ['xylophone', 1, 0.22]], horn: [['euphonium', -1, 0.4]], trombone: [['tuba', -1, 0.3]] },
    parts: [{ t: 'hit', inst: 'drums', key: 38, from: 0, to: 16, beats: [2, 5], vel: 58 }] },
  boss_treelord: { dbl: { oboe: [['englishhorn', -1, 0.35]], cello: [['clarinet', 0, 0.3]], horn: [['euphonium', -1, 0.4], ['trumpet', 0, 0.22]], choir: [['voice', 0, 0.45]] },
    parts: [{ t: 'arp', inst: 'harp', from: 0, to: 16, pat: [[0, 0, 1], [1, 2, 1], [2, 4, 1]], oct: 1, vel: 52 }] },
};
for (const [k, m] of Object.entries(MORE)) {
  const p = PIECES[k];
  if (!p) continue;
  for (const q of p.parts) if (q.t === 'mel' && m.dbl && m.dbl[q.inst] && !q.dbl) q.dbl = m.dbl[q.inst];
  if (m.parts) p.parts.push(...m.parts);
}

// ---------------- THE MINOR ARCHITECTIUM: a merchant's jig ----------------
// The workshop town's market: D major 6/8 (eighth = beat). The tune the town's fiddlers and
// merchants play - folk fiddle, mandolin, nylon guitar (oom-pah), crumhorns, tambourine, castanets.
PIECES.story_architectium = { bpm: 300, meter: 6, rev: 0.28,
  chords: 'D D G D D G A D  G D D A G A D D',
  parts: [
    { t: 'bass', inst: 'guitar', from: 0, to: 16, pat: [[0, 1], [3, 1]], oct: 1, vel: 70 },
    { t: 'arp', inst: 'guitar', from: 0, to: 16, pat: [[1, 1, 1], [2, 2, 1], [4, 1, 1], [5, 2, 1]], oct: 1, vel: 56 },
    { t: 'bass', inst: 'pizz', from: 0, to: 16, pat: [[0, 2], [3, 2]], vel: 80 },
    { t: 'mel', inst: 'fiddle', bar: 0, vel: 104, dbl: [['mandolin', 0, 0.4]],
      notes: 'A4:1 D5:1 F#5:1 A5:2 F#5:1 G5:1 F#5:1 E5:1 D5:2 B4:1 A4:1 B4:1 D5:1 G5:2 B4:1 A4:2 F#4:1 D4:3 A4:1 D5:1 F#5:1 A5:2 F#5:1 G5:1 B5:1 A5:1 G5:1 F#5:1 E5:1 F#5:1 A5:1 F#5:1 E5:1 C#5:1 E5:1 D5:3 D5:3' },
    { t: 'mel', inst: 'crumhorn', bar: 8, vel: 96, dbl: [['mandolin', 0, 0.4], ['fiddle', -1, 0.45]],
      notes: 'B4:1 D5:1 G5:1 B5:2 G5:1 A5:1 G5:1 F#5:1 E5:2 D5:1 F#5:1 A5:1 D6:1 A5:2 F#5:1 E5:3 A4:3 B4:1 D5:1 G5:1 B5:2 D6:1 C#6:1 A5:1 E5:1 C#5:2 E5:1 D5:1 F#5:1 A5:1 F#5:1 E5:1 C#5:1 D5:6' },
    { t: 'hit', inst: 'drums', key: 54, from: 0, to: 16, beats: [0, 3], vel: 72 },            // Tambourine
    { t: 'hit', inst: 'castanets', key: 60, from: 8, to: 16, beats: [2, 5], vel: 66 },
    { t: 'hit', inst: 'drums', key: 35, from: 0, to: 16, beats: [0], vel: 70 },
  ] };

module.exports = { PIECES, build };
