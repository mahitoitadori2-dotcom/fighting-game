// Generates PLACEHOLDER sounds for Universal Beatdown (synthesized, royalty-free).
//   node tools/make_placeholder_audio.js            -> writes only files that don't exist yet
//   node tools/make_placeholder_audio.js --force    -> overwrites the placeholders
// Output: audio/sfx/*.wav and audio/music/*.wav (22.05 kHz, mono, 16-bit).
// Replace any of them with your real sounds (same name, .ogg/.wav/.mp3) - SoundManager
// picks .ogg first, then .wav / .mp3.
const fs = require('fs'), path = require('path');
const ROOT = path.resolve(__dirname, '..');
const RATE = 22050;
const force = process.argv.includes('--force');

// ---------- tiny synth ----------
let seed = 12345;
const rnd = () => ((seed = (seed * 1103515245 + 12345) & 0x7fffffff) / 0x7fffffff) * 2 - 1;
const buf = (sec) => new Float32Array(Math.round(sec * RATE));
const env = (t, a, d) => (t < a ? t / a : Math.exp(-(t - a) / d));
const sq = (ph) => (ph % 1 < 0.5 ? 1 : -1);
const saw = (ph) => 2 * (ph % 1) - 1;
const tri = (ph) => 1 - 4 * Math.abs((ph % 1) - 0.5);
function tone(b, start, dur, f0, f1, wave, vol, a = 0.005, d = dur / 3) {
  let ph = 0; const n = Math.round(dur * RATE), s0 = Math.round(start * RATE);
  for (let i = 0; i < n && s0 + i < b.length; i++) {
    const t = i / RATE, f = f0 + (f1 - f0) * (i / n);
    ph += f / RATE; b[s0 + i] += wave(ph) * vol * env(t, a, d);
  }
}
function noise(b, start, dur, vol, a = 0.002, d = dur / 3, lp = 0.5) {
  let y = 0; const n = Math.round(dur * RATE), s0 = Math.round(start * RATE);
  for (let i = 0; i < n && s0 + i < b.length; i++) {
    y += lp * (rnd() - y);                               // one-pole low-pass (lp: 0..1)
    b[s0 + i] += y * vol * env(i / RATE, a, d);
  }
}
function writeWav(file, b) {
  let peak = 0; for (const v of b) peak = Math.max(peak, Math.abs(v));
  const g = peak > 0 ? 0.89 / peak : 1;
  const data = Buffer.alloc(b.length * 2);
  for (let i = 0; i < b.length; i++) data.writeInt16LE(Math.max(-32767, Math.min(32767, Math.round(b[i] * g * 32767))), i * 2);
  const h = Buffer.alloc(44);
  h.write('RIFF', 0); h.writeUInt32LE(36 + data.length, 4); h.write('WAVE', 8); h.write('fmt ', 12);
  h.writeUInt32LE(16, 16); h.writeUInt16LE(1, 20); h.writeUInt16LE(1, 22); h.writeUInt32LE(RATE, 24);
  h.writeUInt32LE(RATE * 2, 28); h.writeUInt16LE(2, 32); h.writeUInt16LE(16, 34); h.write('data', 36); h.writeUInt32LE(data.length, 40);
  fs.mkdirSync(path.dirname(file), { recursive: true });
  fs.writeFileSync(file, Buffer.concat([h, data]));
}

// ---------- SFX ----------
const SFX = {
  punch:       () => { const b = buf(0.16); noise(b, 0, 0.05, 0.8, 0.001, 0.02, 0.6); tone(b, 0, 0.14, 160, 60, Math.sin.bind(null), 0); tone(b, 0, 0.14, 180, 55, (p) => Math.sin(p * 2 * Math.PI), 0.9, 0.002, 0.05); return b; },
  sword_slash: () => { const b = buf(0.24); noise(b, 0, 0.22, 0.9, 0.03, 0.06, 0.9); tone(b, 0.02, 0.18, 2400, 900, tri, 0.15, 0.01, 0.06); return b; },
  beam:        () => { const b = buf(0.45); tone(b, 0, 0.45, 300, 1200, sq, 0.35, 0.01, 0.25); tone(b, 0, 0.45, 603, 2410, tri, 0.25, 0.01, 0.25); return b; },
  explosion:   () => { const b = buf(0.8); noise(b, 0, 0.8, 1.0, 0.002, 0.22, 0.25); tone(b, 0, 0.5, 90, 30, (p) => Math.sin(p * 2 * Math.PI), 0.9, 0.002, 0.15); return b; },
  jump:        () => { const b = buf(0.14); tone(b, 0, 0.14, 300, 720, sq, 0.4, 0.002, 0.07); return b; },
  dash:        () => { const b = buf(0.3); noise(b, 0, 0.3, 0.8, 0.04, 0.09, 0.35); tone(b, 0, 0.25, 500, 200, tri, 0.2, 0.01, 0.1); return b; },
  heal:        () => { const b = buf(0.55); [523, 659, 784, 1047].forEach((f, i) => tone(b, i * 0.08, 0.3, f, f, tri, 0.4, 0.005, 0.12)); return b; },
  spawn:       () => { const b = buf(0.45); tone(b, 0, 0.45, 400, 1600, tri, 0.35, 0.01, 0.2); noise(b, 0.05, 0.35, 0.15, 0.05, 0.1, 0.9); return b; },
  death:       () => { const b = buf(0.7); tone(b, 0, 0.7, 520, 70, sq, 0.4, 0.005, 0.35); tone(b, 0, 0.7, 260, 40, tri, 0.3, 0.005, 0.35); return b; },
  ultimate:    () => { const b = buf(0.95); [262, 330, 392, 523].forEach((f) => tone(b, 0, 0.95, f * 0.5, f * 1.5, saw, 0.18, 0.05, 0.45)); noise(b, 0.6, 0.35, 0.5, 0.002, 0.12, 0.3); return b; },
  hit:         () => { const b = buf(0.1); noise(b, 0, 0.06, 0.9, 0.001, 0.02, 0.7); tone(b, 0, 0.09, 260, 110, sq, 0.4, 0.001, 0.03); return b; },
  block:       () => { const b = buf(0.22); [1200, 1810, 2650].forEach((f) => tone(b, 0, 0.22, f, f * 0.98, (p) => Math.sin(p * 2 * Math.PI), 0.3, 0.001, 0.06)); noise(b, 0, 0.03, 0.4, 0.001, 0.01, 0.9); return b; },
  drill:       () => { const b = buf(0.6); let ph = 0; for (let i = 0; i < b.length; i++) { const t = i / RATE; ph += (110 + 30 * Math.sin(t * 60)) / RATE; b[i] = saw(ph) * 0.5 * (0.6 + 0.4 * Math.sin(t * 2 * Math.PI * 28)) * env(t, 0.02, 0.4); } noise(b, 0, 0.6, 0.2, 0.02, 0.3, 0.6); return b; },
  void_goo:    () => { const b = buf(0.55); let ph = 0; for (let i = 0; i < b.length; i++) { const t = i / RATE; ph += (180 - 120 * t + 25 * Math.sin(t * 2 * Math.PI * 9)) / RATE; b[i] = Math.sin(ph * 2 * Math.PI) * 0.8 * env(t, 0.02, 0.25); } return b; },
  flame:       () => { const b = buf(0.45); noise(b, 0, 0.45, 0.9, 0.02, 0.18, 0.15); for (let k = 0; k < 6; k++) noise(b, 0.03 + k * 0.06, 0.02, 0.6, 0.001, 0.006, 0.9); return b; },
  bark:        () => { const b = buf(0.32); tone(b, 0, 0.11, 620, 330, saw, 0.6, 0.004, 0.05); tone(b, 0.16, 0.12, 680, 340, saw, 0.6, 0.004, 0.05); return b; },
  croak:       () => { const b = buf(0.5); let ph = 0; for (let i = 0; i < b.length; i++) { const t = i / RATE; ph += (95 + 15 * Math.sin(t * 7)) / RATE; b[i] = saw(ph) * 0.7 * (Math.sin(t * 2 * Math.PI * 22) > 0 ? 1 : 0.25) * env(t, 0.02, 0.25); } return b; },
  laser:       () => { const b = buf(0.3); tone(b, 0, 0.3, 1800, 220, sq, 0.4, 0.002, 0.12); tone(b, 0, 0.3, 1790, 215, saw, 0.2, 0.002, 0.12); return b; },

  // ----- added with the Fights-mode bosses (sounds for every battle + Story) -----
  swing:       () => { const b = buf(0.18); noise(b, 0, 0.18, 0.7, 0.03, 0.05, 0.75); return b; },
  telegraph:   () => { const b = buf(0.22); tone(b, 0, 0.1, 880, 880, sq, 0.25, 0.002, 0.05); tone(b, 0.1, 0.12, 1175, 1175, sq, 0.25, 0.002, 0.06); return b; },
  whoosh:      () => { const b = buf(0.6); noise(b, 0, 0.6, 0.8, 0.25, 0.15, 0.2); tone(b, 0, 0.6, 120, 380, tri, 0.12, 0.25, 0.15); return b; },
  rumble:      () => { const b = buf(1.4); noise(b, 0, 1.4, 1.0, 0.05, 0.5, 0.06); tone(b, 0, 1.2, 55, 35, (p) => Math.sin(p * 2 * Math.PI), 0.8, 0.02, 0.5); return b; },
  roar:        () => { const b = buf(1.1); let ph = 0; for (let i = 0; i < b.length; i++) { const t = i / RATE; ph += (85 + 25 * Math.sin(t * 9) - 30 * t) / RATE; b[i] = saw(ph) * 0.6 * (0.7 + 0.3 * Math.sin(t * 2 * Math.PI * 31)) * env(t, 0.08, 0.45); } noise(b, 0, 1.1, 0.5, 0.08, 0.4, 0.3); return b; },
  dragon_roar: () => { const b = buf(1.5); let ph = 0, ph2 = 0; for (let i = 0; i < b.length; i++) { const t = i / RATE; ph += (180 + 120 * Math.sin(t * 2.5) - 60 * t) / RATE; ph2 += (271 + 90 * Math.sin(t * 3.1)) / RATE; b[i] = (saw(ph) * 0.5 + sq(ph2) * 0.15) * (0.6 + 0.4 * Math.sin(t * 2 * Math.PI * 43)) * env(t, 0.12, 0.6); } noise(b, 0, 1.5, 0.6, 0.1, 0.55, 0.45); return b; },
  slam:        () => { const b = buf(0.9); tone(b, 0, 0.6, 70, 28, (p) => Math.sin(p * 2 * Math.PI), 1.0, 0.001, 0.2); noise(b, 0, 0.9, 0.9, 0.001, 0.25, 0.12); noise(b, 0, 0.05, 0.8, 0.001, 0.02, 0.9); return b; },
  stone:       () => { const b = buf(0.6); for (let k = 0; k < 9; k++) noise(b, k * 0.045 + Math.abs(rnd()) * 0.02, 0.06, 0.8 - k * 0.07, 0.001, 0.02, 0.55); tone(b, 0, 0.3, 140, 60, sq, 0.2, 0.001, 0.08); return b; },
  chain:       () => { const b = buf(0.55); for (let k = 0; k < 7; k++) { tone(b, k * 0.06, 0.12, 2300 + k * 140, 2200 + k * 140, sq, 0.12, 0.001, 0.03); noise(b, k * 0.06, 0.03, 0.4, 0.001, 0.01, 0.95); } return b; },
  holy:        () => { const b = buf(0.8); [784, 988, 1175, 1568].forEach((f, i) => tone(b, i * 0.03, 0.75, f, f * 1.01, (p) => Math.sin(p * 2 * Math.PI), 0.25, 0.04, 0.3)); noise(b, 0, 0.5, 0.15, 0.05, 0.2, 0.97); return b; },
  bite:        () => { const b = buf(0.25); noise(b, 0, 0.04, 1.0, 0.001, 0.01, 0.8); tone(b, 0.01, 0.2, 320, 90, saw, 0.5, 0.001, 0.06); noise(b, 0.08, 0.04, 0.8, 0.001, 0.01, 0.8); return b; },
  chem_spill:  () => { const b = buf(0.55); noise(b, 0, 0.12, 0.8, 0.002, 0.05, 0.35); for (let k = 0; k < 6; k++) tone(b, 0.08 + k * 0.07, 0.06, 300 + Math.abs(rnd()) * 500, 900 + Math.abs(rnd()) * 600, (p) => Math.sin(p * 2 * Math.PI), 0.4, 0.002, 0.03); return b; },
  flask_drink: () => { const b = buf(0.9); for (let k = 0; k < 3; k++) { tone(b, k * 0.17, 0.14, 260, 180, (p) => Math.sin(p * 2 * Math.PI), 0.6, 0.01, 0.05); noise(b, k * 0.17, 0.1, 0.25, 0.01, 0.04, 0.3); } [1047, 1319, 1568].forEach((f, i) => tone(b, 0.55 + i * 0.06, 0.3, f, f, tri, 0.3, 0.005, 0.12)); return b; },
  count_tick:  () => { const b = buf(0.7); tone(b, 0, 0.5, 110, 50, (p) => Math.sin(p * 2 * Math.PI), 1.0, 0.001, 0.15); noise(b, 0, 0.3, 0.6, 0.001, 0.08, 0.3); [440, 660].forEach((f) => tone(b, 0, 0.6, f, f, saw, 0.12, 0.002, 0.25)); return b; },
  count_go:    () => { const b = buf(1.6); tone(b, 0, 0.8, 90, 30, (p) => Math.sin(p * 2 * Math.PI), 1.0, 0.001, 0.3); noise(b, 0, 1.4, 1.0, 0.001, 0.45, 0.2); [262, 330, 392, 523, 659].forEach((f) => tone(b, 0.02, 1.5, f, f, saw, 0.12, 0.005, 0.6)); noise(b, 0, 0.06, 0.9, 0.001, 0.02, 0.95); return b; },

  // ----- added with Story Colosseum 2 -----
  geyser:      () => { const b = buf(0.9); noise(b, 0, 0.9, 1.0, 0.03, 0.3, 0.12); tone(b, 0, 0.7, 60, 140, (p) => Math.sin(p * 2 * Math.PI), 0.7, 0.02, 0.25); for (let k = 0; k < 5; k++) noise(b, 0.2 + k * 0.1, 0.05, 0.5, 0.001, 0.02, 0.6); return b; },
  spark:       () => { const b = buf(0.4); for (let k = 0; k < 8; k++) { noise(b, k * 0.03, 0.03, 0.9 - k * 0.08, 0.001, 0.01, 0.95); tone(b, k * 0.03, 0.05, 3000 + k * 200, 1800, sq, 0.15, 0.001, 0.02); } noise(b, 0.05, 0.3, 0.5, 0.002, 0.1, 0.4); return b; },
  splash:      () => { const b = buf(0.8); noise(b, 0, 0.35, 1.0, 0.002, 0.12, 0.45); for (let k = 0; k < 7; k++) tone(b, 0.15 + k * 0.08, 0.08, 700 + Math.abs(rnd()) * 900, 300 + Math.abs(rnd()) * 300, (p) => Math.sin(p * 2 * Math.PI), 0.35, 0.002, 0.03); return b; },
};

// ---------- MUSIC (seamless loops: exact bar lengths) ----------
const NOTE = (n) => 440 * Math.pow(2, (n - 69) / 12);       // MIDI -> Hz
function song(bpm, bars, bass, lead, drums, leadWave, bassWave) {
  const beat = 60 / bpm, len = bars * 4 * beat, b = buf(len);
  const step = beat / 2;                                       // 8th notes
  const steps = Math.round(len / step);
  for (let s = 0; s < steps; s++) {
    const t = s * step;
    const bn = bass[s % bass.length]; if (bn) tone(b, t, step * 0.95, NOTE(bn), NOTE(bn), bassWave, 0.32, 0.005, step * 0.6);
    const ln = lead[s % lead.length]; if (ln) tone(b, t, step * 0.9, NOTE(ln), NOTE(ln), leadWave, 0.16, 0.01, step * 0.5);
    const d = drums[s % drums.length];
    if (d === 'k') tone(b, t, 0.12, 120, 45, (p) => Math.sin(p * 2 * Math.PI), 0.7, 0.001, 0.05);
    if (d === 's') noise(b, t, 0.12, 0.35, 0.001, 0.04, 0.8);
    if (d === 'h') noise(b, t, 0.04, 0.12, 0.001, 0.01, 0.95);
    if (d === 't') tone(b, t, 0.25, 85, 40, (p) => Math.sin(p * 2 * Math.PI), 0.8, 0.002, 0.1);        // War drum / tom
    if (d === 'd') tone(b, t + step * 0.37, 0.18, 1900, 1300, (p) => Math.sin(p * 2 * Math.PI), 0.12, 0.001, 0.05);  // Water drip
    if (d === 'c') { noise(b, t, 0.03, 0.25, 0.001, 0.008, 0.95); tone(b, t, 0.08, 2600, 2500, sq, 0.06, 0.001, 0.02); }  // Metal clank
    if (d === 'b') [1568, 2093].forEach((f) => tone(b, t, 0.6, f, f, tri, 0.07, 0.002, 0.25));        // Crystal bell
  }
  return b;
}
// Souls-like boss track: held ORGAN / CHOIR chords (one per bar) + low strings ostinato
// + lead + war drums. organ = additive sines, choir = slow-attack detuned triangles.
const organ = (p) => (Math.sin(p * 2 * Math.PI) + 0.5 * Math.sin(p * 4 * Math.PI) + 0.3 * Math.sin(p * 6 * Math.PI) + 0.2 * Math.sin(p * 8 * Math.PI)) / 2;
function epic(bpm, bars, chords, bass, lead, drums, padWave, leadWave) {
  const beat = 60 / bpm, barLen = 4 * beat, len = bars * barLen, b = buf(len), step = beat / 2;
  for (let bar = 0; bar < bars; bar++) {
    const ch = chords[bar % chords.length];
    for (const n of ch) {
      tone(b, bar * barLen, barLen, NOTE(n), NOTE(n), padWave, 0.09, 0.12, barLen * 2);
      tone(b, bar * barLen, barLen, NOTE(n) * 1.004, NOTE(n) * 1.004, tri, 0.05, 0.3, barLen * 2);   // choir-ish detune
    }
  }
  const steps = Math.round(len / step);
  for (let s = 0; s < steps; s++) {
    const t = s * step;
    const bn = bass[s % bass.length]; if (bn) tone(b, t, step * 0.9, NOTE(bn), NOTE(bn), saw, 0.22, 0.004, step * 0.5);
    const ln = lead[s % lead.length]; if (ln) tone(b, t, step * 1.8, NOTE(ln), NOTE(ln), leadWave, 0.13, 0.02, step);
    const d = drums[s % drums.length];
    if (d === 't') tone(b, t, 0.3, 80, 38, (p) => Math.sin(p * 2 * Math.PI), 0.9, 0.002, 0.12);
    if (d === 'T') { tone(b, t, 0.45, 60, 30, (p) => Math.sin(p * 2 * Math.PI), 1.0, 0.002, 0.2); noise(b, t, 0.3, 0.4, 0.002, 0.1, 0.2); }
    if (d === 's') noise(b, t, 0.14, 0.35, 0.001, 0.05, 0.7);
    if (d === 'c') { noise(b, t, 0.03, 0.25, 0.001, 0.008, 0.95); tone(b, t, 0.1, 2200, 2100, sq, 0.06, 0.001, 0.03); }
    if (d === 'b') [1046, 1568].forEach((f) => tone(b, t, 1.0, f, f, (p) => Math.sin(p * 2 * Math.PI), 0.08, 0.002, 0.5));   // church bell
  }
  return b;
}

// VIOLIN: bowed string = sawtooth with a slow bow attack + 5.5 Hz vibrato, softened by
// mixing in a triangle. Used for the Child Wielding Needle's theme.
function bowed(b, start, dur, f, vol) {
  let ph = 0; const n = Math.round(dur * RATE), s0 = Math.round(start * RATE);
  for (let i = 0; i < n && s0 + i < b.length; i++) {
    const t = i / RATE;
    const vib = 1 + 0.006 * Math.sin(2 * Math.PI * 5.5 * t) * Math.min(1, t / 0.15);   // vibrato grows in
    ph += (f * vib) / RATE;
    const bow = Math.min(1, t / 0.06) * (t > dur - 0.05 ? Math.max(0, (dur - t) / 0.05) : 1);
    b[s0 + i] += (0.7 * saw(ph) + 0.3 * tri(ph)) * vol * bow;
  }
}
// Violin boss: a fast violin melody (16th-note runs), pizzicato bass, harpsichord-ish chords.
function violinBoss(bpm, bars, chords, bass, melody) {
  const beat = 60 / bpm, barLen = 4 * beat, len = bars * barLen, b = buf(len), step = beat / 4;   // 16ths
  for (let bar = 0; bar < bars; bar++) {
    const ch = chords[bar % chords.length];
    for (let k = 0; k < 8; k++)                                                  // Broken-chord harpsichord
      tone(b, bar * barLen + k * beat * 0.5, beat * 0.45, NOTE(ch[k % ch.length]), NOTE(ch[k % ch.length]), sq, 0.05, 0.002, 0.08);
  }
  const steps = Math.round(len / step);
  for (let s = 0; s < steps; s++) {
    const t = s * step;
    const bn = bass[(s >> 1) % bass.length]; if (bn && s % 2 === 0) tone(b, t, step * 1.6, NOTE(bn), NOTE(bn), tri, 0.3, 0.002, 0.08);   // Pizzicato
    const m = melody[s % melody.length];
    if (m) { let d = 1; while (d < 4 && !melody[(s + d) % melody.length] && (s + d) % melody.length !== 0) d++; bowed(b, t, step * d * 0.98, NOTE(m), 0.2); }
    if (s % 8 === 0) tone(b, t, 0.2, 90, 40, (p) => Math.sin(p * 2 * Math.PI), 0.5, 0.002, 0.08);
  }
  return b;
}

// GONG: inharmonic metal partials with a long shimmering decay + a soft mallet thump.
function gong(b, start, f, vol, dur = 4.0) {
  [1.0, 1.48, 1.97, 2.43, 3.11, 4.2].forEach((r, i) => {
    let ph = 0; const n = Math.round(dur * RATE), s0 = Math.round(start * RATE);
    for (let j = 0; j < n && s0 + j < b.length; j++) {
      const t = j / RATE;
      ph += f * r * (1 + 0.003 * Math.sin(2 * Math.PI * (0.7 + i * 0.3) * t)) / RATE;   // shimmer
      b[s0 + j] += Math.sin(ph * 2 * Math.PI) * vol / (1 + i * 0.7) * env(t, 0.004 + i * 0.01, dur / (1.2 + i * 0.6));
    }
  });
  noise(b, start, 0.06, vol * 0.5, 0.001, 0.02, 0.15);
}
// CHOIR: slow-attack "aah" chord = several detuned triangle voices per note with vibrato.
function choir(b, start, dur, notes, vol) {
  for (const n of notes) for (const det of [0.996, 1.0, 1.004]) {
    let ph = 0; const f = NOTE(n) * det, s0 = Math.round(start * RATE), len = Math.round(dur * RATE);
    for (let j = 0; j < len && s0 + j < b.length; j++) {
      const t = j / RATE; ph += f * (1 + 0.004 * Math.sin(2 * Math.PI * 5 * t)) / RATE;
      const a = Math.min(1, t / 0.6) * Math.min(1, (dur - t) / 0.4);
      b[s0 + j] += (tri(ph) * 0.8 + Math.sin(ph * 4 * Math.PI) * 0.2) * vol * a;
    }
  }
}
// THE ENLIGHTENED FIRST PRIME: a GONG RITUAL + CHOIR. Slow, heavy: a huge gong on every bar,
// small gongs answering, ritual drums, a chanting choir and a low drone. D phrygian.
function gongRitual(bpm, bars, chords, chant) {
  const beat = 60 / bpm, barLen = 4 * beat, len = bars * barLen, b = buf(len), step = beat / 2;
  for (let bar = 0; bar < bars; bar++) {
    const t0 = bar * barLen;
    gong(b, t0, 55, 0.9, barLen * 1.5);                                           // The great gong
    gong(b, t0 + beat * 2.5, 147 + (bar % 2) * 18, 0.25, 2.0);                    // Small gong answers
    choir(b, t0, barLen, chords[bar % chords.length], 0.05);                     // Choir chord
    tone(b, t0, barLen, NOTE(38), NOTE(38), saw, 0.06, 0.3, barLen);             // Drone
  }
  const steps = Math.round(len / step);
  for (let s = 0; s < steps; s++) {
    const t = s * step;
    if (s % 8 === 0 || s % 8 === 3 || s % 8 === 6) tone(b, t, 0.35, 70, 36, (p) => Math.sin(p * 2 * Math.PI), 0.8, 0.002, 0.14);   // Ritual drum
    if (s % 4 === 2) noise(b, t, 0.05, 0.15, 0.001, 0.02, 0.9);                   // Bells / rattles
    const c = chant[s % chant.length]; if (c) choir(b, t, step * 1.9, [c], 0.07);   // Chant line
  }
  return b;
}
// THE ENLIGHTENED ONE: CHAOS - every instrument at once, clashing: organ, violin runs,
// harpsichord, brass, church bells, gongs, war drums; the key keeps lurching. Fast.
function chaosBoss(bpm, bars) {
  const beat = 60 / bpm, barLen = 4 * beat, len = bars * barLen, b = buf(len), step = beat / 4;
  const keys = [0, 1, 6, 3, 0, 5, 1, 6];                                          // Lurching key changes
  for (let bar = 0; bar < bars; bar++) {
    const k = keys[bar % keys.length], t0 = bar * barLen;
    [50, 53, 56, 59].forEach((n) => tone(b, t0, barLen, NOTE(n + k), NOTE(n + k), organ, 0.06, 0.05, barLen));   // Diminished organ
    choir(b, t0, barLen, [62 + k, 65 + k], 0.03);
    gong(b, t0, 62 + k * 3, 0.35, 2.5);
    [1046, 1397].forEach((f) => tone(b, t0 + beat * 2, 0.9, f * Math.pow(2, k / 12), f * Math.pow(2, k / 12), (p) => Math.sin(p * 2 * Math.PI), 0.07, 0.002, 0.4));   // Bells
    for (let j = 0; j < 4; j++) tone(b, t0 + j * beat + beat * 0.5, beat * 0.4, NOTE(62 + k + j * 3), NOTE(62 + k + j * 3), saw, 0.07, 0.01, 0.1);   // Brass stabs
  }
  const steps = Math.round(len / step);
  for (let s = 0; s < steps; s++) {
    const t = s * step, bar = Math.floor(s / 16), k = keys[bar % keys.length];
    const run = [74, 75, 77, 79, 80, 79, 77, 75, 74, 71, 72, 74, 75, 77, 78, 80][s % 16] + k;
    if (s % 2 === 0) bowed(b, t, step * 1.9, NOTE(run), 0.09);                     // Violin runs
    if (s % 3 === 0) tone(b, t, step * 0.8, NOTE(86 - (s % 7) + k), NOTE(86 - (s % 7) + k), sq, 0.035, 0.002, 0.04);   // Harpsichord (off-grid in 3s)
    if (s % 4 === 0) tone(b, t, 0.25, 85, 38, (p) => Math.sin(p * 2 * Math.PI), 0.7, 0.002, 0.09);   // Drums
    if (s % 16 === 6 || s % 16 === 11 || s % 16 === 14) tone(b, t, 0.2, 110, 50, (p) => Math.sin(p * 2 * Math.PI), 0.6, 0.002, 0.07);
    if (s % 4 === 2) noise(b, t, 0.08, 0.2, 0.001, 0.03, 0.8);                     // Snare / crash
    if (s % 2 === 1) noise(b, t, 0.02, 0.06, 0.001, 0.008, 0.95);                  // Hats
    if (s % 8 === 0) tone(b, t, step * 3, NOTE(38 + k), NOTE(38 + k), saw, 0.16, 0.004, 0.2);   // Bass
  }
  return b;
}

const MUSIC = {
  // ----- THE ENLIGHTENED CHASE -----
  // The road (regular fights): an urgent desert CHASE - galloping drums, hijaz-like lead, bright choir. D phrygian dominant.
  story_chase: () => epic(150, 8,
    [[50, 54, 57, 62], [51, 55, 58, 63], [50, 54, 57, 62], [48, 51, 55, 60]],
    [38, 0, 38, 45, 38, 0, 38, 45, 39, 0, 39, 46, 39, 0, 39, 46, 38, 0, 38, 45, 38, 0, 38, 45, 36, 0, 36, 43, 37, 38, 39, 38],
    [74, 75, 78, 0, 79, 78, 75, 74, 75, 0, 74, 0, 72, 0, 74, 0, 78, 79, 81, 0, 79, 78, 75, 74, 72, 0, 75, 74, 0, 0, 0, 0],
    ['T', 't', 't', 's', 'T', 't', 's', 't', 'T', 't', 't', 's', 'T', 's', 't', 's'], organ, saw),
  // The Enlightened First Prime: GONGS + CHOIR, a slow ritual. D phrygian.
  boss_prime: () => gongRitual(72, 8,
    [[50, 53, 57, 62], [51, 55, 58, 63], [48, 53, 57, 60], [46, 50, 53, 58]],
    [74, 0, 0, 0, 75, 0, 74, 0, 72, 0, 0, 0, 70, 0, 0, 0, 69, 0, 70, 0, 72, 0, 74, 0, 75, 0, 0, 0, 74, 0, 0, 0]),
  // The Enlightened One: CHAOS - all the instruments at once, the key lurching every bar.
  boss_enlightened: () => chaosBoss(168, 8),

  // ----- STORY MODE (Colosseum 5): every boss has its own theme -----
  // Child Wielding Needle: a frantic VIOLIN theme, D minor, fast 16th-note runs
  boss_needle: () => violinBoss(150, 8,
    [[62, 65, 69], [58, 62, 65], [60, 64, 67], [57, 61, 64]],
    [38, 50, 38, 45, 34, 46, 34, 41, 36, 48, 36, 43, 33, 45, 33, 40],
    [74, 76, 77, 79, 81, 0, 79, 77, 76, 77, 74, 0, 73, 74, 76, 0, 77, 0, 74, 0, 70, 72, 74, 76, 77, 76, 74, 72, 70, 0, 0, 0,
     72, 74, 76, 77, 79, 0, 76, 0, 72, 74, 72, 70, 69, 0, 0, 0, 69, 71, 73, 74, 76, 77, 79, 81, 82, 81, 79, 77, 76, 0, 73, 0]),
  // The Brothers: two mirrored voices (organ + bells), strict and symmetrical, A minor
  boss_brothers: () => epic(126, 8,
    [[45, 52, 57, 60], [45, 52, 57, 60], [41, 48, 53, 57], [43, 50, 55, 59]],
    [33, 45, 33, 45, 33, 45, 33, 45, 33, 45, 33, 45, 33, 45, 33, 45, 29, 41, 29, 41, 29, 41, 29, 41, 31, 43, 31, 43, 31, 43, 31, 43],
    [69, 0, 72, 0, 76, 0, 72, 0, 81, 0, 76, 0, 72, 0, 69, 0, 77, 0, 72, 0, 69, 0, 72, 0, 74, 0, 79, 0, 74, 0, 71, 0],
    ['T', 'b', 's', 'b', 'T', 'b', 's', 'b', 'T', 'c', 's', 'c', 'T', 'c', 's', 's'], organ, tri),
  // Animal Lord: primal, tribal drums, low growling brass, F# phrygian
  boss_animal: () => epic(136, 8,
    [[42, 49, 54], [43, 50, 55], [42, 49, 54], [40, 47, 52]],
    [30, 30, 0, 30, 42, 0, 30, 31, 30, 30, 0, 30, 42, 0, 31, 30, 30, 30, 0, 30, 42, 0, 30, 31, 28, 28, 0, 28, 40, 0, 28, 31],
    [66, 0, 67, 66, 0, 0, 64, 0, 66, 0, 69, 0, 67, 0, 66, 0, 66, 0, 67, 66, 64, 0, 62, 0, 61, 0, 0, 0, 0, 0, 0, 0],
    ['T', 't', 't', 's', 'T', 't', 's', 't', 'T', 't', 't', 's', 'T', 's', 't', 's'], saw, saw),
  // Executor: slow, crushing, grinding - doom organ, metal clanks, G minor
  boss_executor: () => epic(96, 8,
    [[43, 50, 55, 58], [39, 46, 51, 55], [41, 48, 53, 56], [38, 45, 50, 54]],
    [31, 0, 31, 0, 31, 30, 31, 0, 27, 0, 27, 0, 27, 26, 27, 0, 29, 0, 29, 0, 29, 28, 29, 0, 26, 0, 26, 0, 26, 25, 26, 0],
    [67, 0, 0, 0, 70, 0, 69, 0, 67, 0, 0, 0, 63, 0, 0, 0, 65, 0, 0, 0, 68, 0, 67, 0, 66, 0, 0, 0, 0, 0, 0, 0],
    ['T', 'c', 'c', 0, 'T', 'c', 's', 'c', 'T', 'c', 'c', 0, 'T', 'c', 's', 's'], organ, saw),
  // Mother Nature: majestic, flowing, four moods in one - choir + harp-like arps, E major / minor
  boss_nature: () => epic(112, 8,
    [[52, 56, 59, 64], [49, 52, 56, 61], [45, 49, 52, 57], [47, 51, 54, 59]],
    [40, 0, 47, 0, 52, 0, 47, 0, 37, 0, 44, 0, 49, 0, 44, 0, 33, 0, 40, 0, 45, 0, 40, 0, 35, 0, 42, 0, 47, 0, 42, 0],
    [76, 80, 83, 80, 81, 0, 80, 78, 76, 0, 73, 76, 80, 0, 78, 76, 73, 76, 81, 76, 78, 0, 76, 73, 75, 0, 78, 0, 83, 0, 0, 0],
    ['b', 0, 's', 0, 't', 0, 's', 0, 'b', 0, 's', 0, 't', 't', 's', 's'], organ, tri),
  // The False God: a twisted carnival of fire - waltz-like 3/4 feel in a 4/4 loop, B minor, choir
  boss_falsegod: () => epic(144, 8,
    [[47, 54, 59, 62], [43, 50, 55, 59], [45, 52, 57, 61], [42, 49, 54, 58]],
    [35, 0, 47, 50, 0, 47, 31, 0, 43, 47, 0, 43, 33, 0, 45, 49, 0, 45, 30, 0, 42, 46, 0, 42, 35, 0, 47, 50, 0, 47, 34, 0],
    [71, 74, 78, 0, 76, 74, 71, 0, 67, 0, 71, 74, 79, 0, 78, 76, 73, 76, 81, 0, 79, 78, 76, 0, 78, 0, 73, 0, 70, 0, 0, 0],
    ['T', 0, 's', 'T', 0, 's', 'T', 'c', 0, 's', 'T', 0, 's', 'T', 's', 's'], organ, saw),
  // Satan: infernal choir, tritone bass, pounding drums, C minor
  boss_satan: () => epic(132, 8,
    [[36, 43, 48, 51], [42, 49, 54, 57], [36, 43, 48, 51], [41, 48, 53, 56]],
    [24, 24, 36, 24, 30, 30, 42, 30, 24, 24, 36, 24, 29, 29, 41, 29, 24, 24, 36, 24, 30, 30, 42, 30, 23, 23, 35, 23, 26, 29, 30, 24],
    [72, 0, 75, 0, 78, 0, 75, 72, 71, 0, 0, 0, 66, 0, 0, 0, 72, 0, 75, 77, 78, 0, 77, 75, 74, 0, 72, 0, 71, 0, 0, 0],
    ['T', 'T', 's', 'c', 'T', 'T', 's', 'b', 'T', 'T', 's', 'c', 'T', 't', 's', 's'], organ, saw),
  // The Sun: radiant, holy, enormous - bright choir, bells, soaring lead, D major
  boss_sun: () => epic(120, 8,
    [[50, 54, 57, 62], [55, 59, 62, 67], [57, 61, 64, 69], [47, 50, 54, 59]],
    [38, 0, 45, 0, 50, 0, 45, 0, 43, 0, 50, 0, 55, 0, 50, 0, 45, 0, 52, 0, 57, 0, 52, 0, 35, 0, 42, 0, 47, 0, 42, 0],
    [78, 0, 81, 0, 86, 0, 83, 81, 79, 0, 83, 0, 86, 0, 0, 0, 81, 0, 85, 0, 88, 0, 86, 85, 83, 0, 81, 0, 78, 0, 0, 0],
    ['b', 0, 's', 0, 'T', 0, 's', 'b', 'b', 0, 's', 0, 'T', 't', 's', 's'], organ, tri),
  // The Consumer: the Sun's theme collapsing - same key twisted to D minor, faster, distorted
  boss_consumer: () => epic(160, 8,
    [[50, 53, 57, 62], [46, 50, 53, 58], [45, 49, 52, 57], [44, 50, 53, 56]],
    [38, 38, 50, 38, 37, 37, 49, 37, 34, 34, 46, 34, 33, 33, 45, 33, 38, 38, 50, 38, 37, 37, 49, 37, 32, 32, 44, 32, 33, 37, 38, 39],
    [74, 77, 74, 0, 81, 0, 77, 74, 73, 0, 74, 0, 70, 0, 0, 0, 74, 77, 81, 0, 82, 0, 81, 77, 76, 0, 74, 0, 73, 0, 0, 0],
    ['T', 'c', 's', 'c', 'T', 't', 's', 'c', 'T', 'c', 's', 'c', 'T', 't', 's', 's'], saw, saw),

  // ----- BOSS EXTENSIONS (Story Mode): one unique theme per extension boss -----
  // The Caeser's Grave (BC4): a slow funeral dirge that keeps hissing - E phrygian, organ
  boss_grave: () => epic(88, 8,
    [[40, 47, 52, 53], [41, 48, 53, 57], [40, 47, 52, 55], [38, 45, 50, 53]],
    [28, 0, 28, 0, 29, 0, 28, 0, 29, 0, 29, 0, 33, 0, 29, 0, 28, 0, 28, 0, 31, 0, 28, 0, 26, 0, 26, 0, 29, 28, 26, 0],
    [64, 0, 65, 0, 64, 0, 0, 0, 65, 0, 69, 0, 67, 0, 65, 0, 64, 0, 67, 0, 71, 0, 69, 67, 65, 0, 64, 0, 0, 0, 0, 0],
    ['T', 0, 0, 's', 'T', 0, 'c', 0, 'T', 0, 0, 's', 'T', 0, 's', 'c'], organ, tri),
  // Saint Architect's Golem (AG4): holy and mechanical - bright organ, marching drums, A major
  boss_saint_golem: () => epic(116, 8,
    [[45, 49, 52, 57], [50, 54, 57, 62], [52, 56, 59, 64], [49, 52, 56, 61]],
    [33, 0, 45, 33, 33, 0, 45, 33, 38, 0, 50, 38, 38, 0, 50, 38, 40, 0, 52, 40, 40, 0, 52, 40, 37, 0, 49, 37, 40, 38, 37, 33],
    [76, 0, 81, 0, 80, 0, 76, 0, 78, 0, 81, 0, 86, 0, 0, 0, 83, 0, 80, 0, 76, 0, 78, 80, 81, 0, 76, 0, 73, 0, 0, 0],
    ['T', 'c', 's', 'c', 'T', 'c', 's', 'c', 'T', 'c', 's', 'c', 'T', 't', 's', 's'], organ, saw),
  // The Void Horrids (VM4): skittering, frantic, three voices - B minor, fast
  boss_horrids: () => epic(168, 8,
    [[47, 50, 54, 59], [43, 47, 50, 55], [45, 48, 52, 57], [42, 46, 49, 54]],
    [35, 35, 47, 35, 35, 47, 35, 36, 31, 31, 43, 31, 31, 43, 31, 32, 33, 33, 45, 33, 33, 45, 33, 34, 30, 30, 42, 30, 34, 33, 31, 30],
    [71, 74, 71, 0, 78, 0, 74, 71, 67, 71, 67, 0, 74, 0, 71, 67, 69, 72, 69, 0, 76, 0, 72, 69, 66, 70, 73, 0, 78, 0, 0, 0],
    ['T', 't', 's', 't', 'T', 't', 's', 't', 'T', 't', 's', 't', 'T', 't', 's', 's'], saw, saw),
  // Radioactive Chorus (AC4): industrial choir, buzzing synth, a crushing pulse - F# minor
  boss_reactor: () => epic(122, 8,
    [[42, 49, 54, 57], [38, 45, 50, 54], [40, 47, 52, 56], [37, 44, 49, 53]],
    [30, 30, 30, 0, 30, 30, 42, 0, 26, 26, 26, 0, 26, 26, 38, 0, 28, 28, 28, 0, 28, 28, 40, 0, 25, 25, 25, 0, 25, 28, 30, 31],
    [66, 0, 0, 69, 0, 0, 73, 0, 74, 0, 73, 0, 69, 0, 0, 0, 68, 0, 0, 71, 0, 0, 76, 0, 73, 0, 71, 0, 69, 0, 0, 0],
    ['T', 'c', 'T', 's', 'T', 'c', 'T', 's', 'T', 'c', 'T', 's', 'T', 'c', 's', 's'], organ, saw),
  // The Forge Father (FM4): anvils and war drums, brass-like saw lead, C minor, heavy
  boss_forge_father: () => epic(132, 8,
    [[36, 43, 48, 51], [32, 39, 44, 48], [34, 41, 46, 50], [31, 38, 43, 47]],
    [24, 0, 24, 36, 24, 0, 24, 36, 20, 0, 20, 32, 20, 0, 20, 32, 22, 0, 22, 34, 22, 0, 22, 34, 19, 0, 19, 31, 23, 0, 24, 26],
    [72, 0, 75, 0, 79, 0, 75, 72, 68, 0, 0, 0, 72, 0, 70, 68, 70, 0, 74, 0, 77, 0, 74, 70, 71, 0, 67, 0, 74, 0, 0, 0],
    ['T', 'c', 's', 'c', 'T', 'c', 's', 'b', 'T', 'c', 's', 'c', 'T', 'T', 's', 's'], saw, saw),

  // ----- FIGHTS-MODE BOSSES (classical / Souls-like, per the plan for new bosses) -----
  // Minos: cathedral organ + choir, D minor, judging and regal
  boss_minos: () => epic(116, 8,
    [[50, 57, 62, 65], [46, 53, 58, 62], [48, 55, 60, 64], [45, 52, 57, 61]],
    [38, 0, 38, 50, 38, 0, 38, 50, 34, 0, 34, 46, 34, 0, 34, 46, 36, 0, 36, 48, 36, 0, 36, 48, 33, 0, 33, 45, 33, 0, 33, 45],
    [74, 0, 0, 0, 77, 0, 76, 0, 74, 0, 0, 0, 70, 0, 0, 0, 72, 0, 0, 0, 76, 0, 74, 0, 73, 0, 0, 0, 0, 0, 0, 0],
    ['T', 0, 's', 0, 't', 't', 's', 'b', 'T', 0, 's', 0, 't', 0, 's', 0], organ, organ),
  // Sisyphus: heavy war drums + brass-like saws, C minor, relentless
  boss_sisyphus: () => epic(138, 8,
    [[48, 55, 60, 63], [44, 51, 56, 60], [46, 53, 58, 62], [43, 50, 55, 59]],
    [36, 36, 48, 36, 36, 48, 36, 47, 32, 32, 44, 32, 32, 44, 32, 43, 34, 34, 46, 34, 34, 46, 34, 45, 31, 31, 43, 31, 31, 43, 35, 38],
    [72, 0, 75, 0, 79, 0, 77, 75, 74, 0, 72, 0, 68, 0, 0, 0, 70, 0, 74, 0, 77, 0, 75, 74, 71, 0, 0, 0, 67, 0, 71, 0],
    ['T', 'c', 't', 'c', 'T', 't', 's', 'c', 'T', 'c', 't', 'c', 'T', 't', 's', 's'], saw, saw),
  // Geyron (dragon): fast strings ostinato, E phrygian, wild
  boss_geyron: () => epic(152, 8,
    [[52, 59, 64, 67], [53, 60, 65, 69], [50, 57, 62, 65], [53, 60, 65, 68]],
    [40, 52, 40, 52, 41, 53, 40, 52, 40, 52, 40, 52, 41, 53, 43, 41, 38, 50, 38, 50, 41, 53, 38, 50, 41, 53, 41, 53, 40, 52, 41, 40],
    [76, 77, 76, 0, 79, 0, 77, 76, 74, 0, 76, 0, 0, 0, 0, 0, 77, 0, 76, 74, 72, 0, 74, 76, 77, 0, 79, 0, 76, 0, 0, 0],
    ['T', 'c', 's', 'c', 't', 'c', 's', 't', 'T', 'c', 's', 'c', 't', 't', 's', 's'], tri, saw),

  // Menu: relaxed, major
  menu: () => song(96, 8,
    [48, 0, 55, 0, 57, 0, 55, 0, 53, 0, 60, 0, 55, 0, 52, 0],
    [72, 0, 76, 79, 0, 76, 74, 0, 72, 0, 69, 72, 0, 74, 76, 0, 77, 0, 76, 74, 0, 72, 71, 0, 72, 0, 0, 0, 74, 0, 0, 0],
    ['k', 'h', 'h', 'h', 's', 'h', 'h', 'h'], tri, tri),
  // Fight: fast, driving minor
  fight: () => song(144, 8,
    [45, 45, 57, 45, 45, 57, 43, 55, 41, 41, 53, 41, 43, 43, 55, 43],
    [69, 0, 72, 0, 76, 74, 72, 0, 71, 0, 72, 74, 76, 0, 79, 0, 77, 76, 74, 0, 72, 0, 74, 0, 76, 0, 0, 74, 72, 71, 69, 0],
    ['k', 'h', 's', 'h', 'k', 'k', 's', 'h'], sq, saw),
  // Boss: heavy, darker, faster
  boss: () => song(156, 8,
    [40, 40, 52, 40, 41, 41, 53, 41, 38, 38, 50, 38, 39, 39, 51, 39],
    [64, 0, 67, 70, 0, 67, 64, 0, 63, 0, 0, 62, 63, 0, 70, 0, 71, 0, 70, 67, 0, 64, 63, 0, 62, 0, 63, 0, 64, 0, 0, 0],
    ['k', 'k', 's', 'h', 'k', 'h', 's', 's'], saw, sq),

  // ----- STORY MODE (Colosseum 1) -----
  // Ashen wasteland (levels 1-3): slow war drums, low phrygian drone, ominous lead
  story_surface: () => song(84, 8,
    [40, 40, 40, 41, 40, 40, 38, 40, 40, 40, 40, 41, 43, 41, 40, 0],
    [0, 0, 64, 0, 65, 0, 64, 0, 0, 0, 0, 0, 62, 0, 64, 0, 0, 0, 67, 0, 65, 0, 64, 0, 0, 0, 65, 64, 0, 0, 0, 0],
    ['t', 0, 'h', 0, 't', 't', 's', 0], saw, sq),
  // Deep caves (level 6 waves): dark, slow pulses, dripping water, echoing notes
  story_cave: () => song(72, 8,
    [36, 0, 0, 0, 36, 0, 0, 0, 34, 0, 0, 0, 31, 0, 0, 0],
    [0, 0, 0, 0, 60, 0, 0, 0, 0, 0, 63, 0, 0, 0, 0, 0, 0, 0, 0, 0, 58, 0, 0, 0, 0, 0, 62, 0, 0, 0, 0, 0],
    ['k', 0, 'd', 0, 0, 'd', 0, 0], tri, tri),
  // Geode cavern (level 4, Rock Golem): crystal bell arpeggios over a heavy rumble
  story_geode: () => song(96, 8,
    [33, 0, 33, 0, 36, 0, 33, 0, 31, 0, 31, 0, 28, 0, 31, 0],
    [69, 72, 76, 72, 69, 72, 76, 79, 67, 71, 74, 71, 67, 71, 74, 77, 65, 69, 72, 69, 65, 69, 72, 76, 64, 68, 71, 68, 64, 68, 71, 74],
    ['t', 'b', 0, 0, 't', 0, 'b', 0], tri, saw),
  // Kharleming hive (level 5): mechanical ticking, metallic bass, nervous robot lead
  story_hive: () => song(132, 8,
    [38, 38, 50, 38, 38, 50, 38, 49, 36, 36, 48, 36, 37, 37, 49, 37],
    [74, 0, 74, 75, 0, 74, 0, 0, 71, 0, 71, 72, 0, 71, 0, 0, 74, 0, 77, 0, 75, 0, 74, 0, 72, 0, 71, 0, 70, 0, 0, 0],
    ['k', 'c', 'c', 'c', 's', 'c', 'c', 'c'], sq, sq),
  // Bosses use music/boss (the Blinded Lord). FUTURE bosses: classical / ancient /
  // medieval, Souls-like (choir, strings, organ, war drums) - not cyber / synth.

  // ----- STORY MODE (Colosseum 2) -----
  // The Elevator from Hell (intro cutscene + level 7 before the boss): haunting and melodic,
  // soft string pads, a lonely plucked melody and distant bells. D minor, slow.
  story_ascent: () => epic(76, 8,
    [[50, 57, 62, 65], [46, 53, 58, 62], [43, 50, 55, 58], [45, 52, 57, 61]],
    [38, 0, 0, 0, 0, 0, 45, 0, 34, 0, 0, 0, 0, 0, 41, 0, 31, 0, 0, 0, 0, 0, 38, 0, 33, 0, 0, 0, 40, 0, 0, 0],
    [74, 0, 77, 76, 74, 0, 72, 0, 70, 0, 0, 69, 70, 0, 0, 0, 67, 0, 70, 0, 74, 0, 72, 70, 69, 0, 0, 0, 73, 0, 0, 0],
    ['b', 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 'b', 0, 0, 0], tri, tri),
  // Architect Chorus (mini-boss): the same haunting world but HEAVIER - organ chorus,
  // driving low strings, metal clanks and bells, war drums. C minor.
  boss_architect: () => epic(132, 8,
    [[48, 55, 60, 63], [44, 51, 56, 60], [43, 50, 55, 59], [46, 53, 58, 62]],
    [36, 36, 48, 36, 36, 48, 43, 48, 32, 32, 44, 32, 32, 44, 39, 44, 31, 31, 43, 31, 31, 43, 38, 43, 34, 34, 46, 34, 34, 46, 41, 46],
    [72, 0, 75, 77, 79, 0, 77, 75, 74, 0, 72, 0, 68, 0, 72, 0, 71, 0, 74, 0, 79, 0, 77, 74, 70, 0, 74, 0, 77, 0, 0, 0],
    ['T', 'c', 's', 'c', 't', 'b', 's', 'c', 'T', 'c', 's', 'c', 't', 't', 's', 's'], organ, saw),
  // Home of the Enlightened Ones: bright and holy - choir pads in C major, harp-like line, bells.
  story_enlightened: () => epic(96, 8,
    [[48, 55, 60, 64], [53, 57, 60, 65], [55, 59, 62, 67], [45, 52, 57, 60]],
    [36, 0, 43, 0, 48, 0, 43, 0, 41, 0, 48, 0, 53, 0, 48, 0, 43, 0, 50, 0, 55, 0, 50, 0, 45, 0, 52, 0, 57, 0, 52, 0],
    [72, 76, 79, 76, 77, 0, 76, 74, 72, 0, 77, 81, 79, 0, 77, 76, 74, 79, 83, 79, 81, 0, 79, 77, 76, 0, 72, 0, 74, 0, 0, 0],
    ['b', 0, 's', 0, 0, 0, 's', 0, 'b', 0, 's', 0, 0, 0, 's', 's'], organ, tri),
  // The Sewers: dark, dripping, creepy, slow. Low pulses, water drips, a sparse wrong-sounding lead.
  story_sewers: () => song(64, 8,
    [33, 0, 0, 0, 0, 0, 0, 0, 32, 0, 0, 0, 0, 0, 0, 0],
    [0, 0, 0, 0, 57, 0, 0, 0, 0, 0, 0, 56, 0, 0, 0, 0, 0, 0, 0, 0, 60, 0, 0, 59, 0, 0, 0, 0, 0, 0, 51, 0],
    ['k', 0, 'd', 0, 0, 'd', 0, 'd'], tri, tri),
  // Blasphemy Caeser: dark, epic, CHOIR, heavy. E phrygian organ choir, brass, war drums, bells.
  boss_caeser: () => epic(120, 8,
    [[40, 47, 52, 55], [41, 48, 53, 57], [38, 45, 50, 53], [41, 48, 53, 56]],
    [28, 28, 40, 28, 29, 29, 41, 29, 28, 28, 40, 28, 26, 26, 38, 26, 29, 29, 41, 29, 28, 28, 40, 28, 29, 29, 41, 29, 31, 29, 28, 0],
    [76, 0, 77, 0, 76, 0, 74, 72, 71, 0, 0, 0, 72, 0, 74, 0, 76, 0, 79, 0, 77, 76, 74, 0, 72, 0, 71, 0, 76, 0, 0, 0],
    ['T', 0, 't', 's', 'T', 't', 's', 'b', 'T', 0, 't', 's', 'T', 't', 's', 's'], organ, saw),

  // ----- STORY MODE (Colosseum 3) -----
  // Burning Throne Room: dark, burning, dramatic - low brass chords, crackling drums. C# minor.
  story_throne: () => epic(92, 8,
    [[49, 56, 61, 64], [45, 52, 57, 61], [47, 54, 59, 62], [44, 51, 56, 60]],
    [37, 0, 37, 49, 37, 0, 44, 0, 33, 0, 33, 45, 33, 0, 40, 0, 35, 0, 35, 47, 35, 0, 42, 0, 32, 0, 32, 44, 32, 0, 39, 0],
    [73, 0, 0, 76, 75, 0, 73, 0, 69, 0, 0, 0, 71, 0, 73, 0, 74, 0, 76, 0, 78, 0, 76, 74, 72, 0, 0, 0, 68, 0, 0, 0],
    ['T', 0, 's', 0, 't', 's', 0, 's', 'T', 0, 's', 0, 't', 's', 's', 's'], saw, saw),
  // Minor Architectium: proud, mechanical march - clanks, bright strings. G major-ish.
  story_architectium: () => song(118, 8,
    [43, 0, 50, 0, 43, 0, 50, 0, 48, 0, 55, 0, 50, 0, 57, 0],
    [67, 0, 71, 74, 0, 71, 72, 0, 74, 0, 72, 71, 0, 69, 67, 0, 69, 0, 72, 76, 0, 74, 72, 0, 71, 0, 69, 0, 67, 0, 0, 0],
    ['k', 'c', 's', 'c', 'k', 'c', 's', 'c'], tri, sq),
  // Blast Workshop: hammering anvils, furnace drone.
  story_workshop: () => song(104, 8,
    [36, 36, 0, 36, 39, 0, 36, 0, 34, 34, 0, 34, 38, 0, 34, 0],
    [0, 0, 60, 0, 63, 0, 0, 0, 62, 0, 60, 0, 0, 0, 58, 0, 0, 0, 60, 0, 63, 0, 65, 0, 63, 0, 62, 0, 60, 0, 0, 0],
    ['t', 'c', 'c', 0, 't', 'c', 's', 'c'], saw, tri),
  // Forge Mother (mini-boss): heavy hammer-strike drums and brass.
  boss_titan: () => epic(126, 8,
    [[45, 52, 57, 60], [41, 48, 53, 57], [43, 50, 55, 59], [40, 47, 52, 56]],
    [33, 33, 45, 33, 33, 45, 40, 45, 29, 29, 41, 29, 29, 41, 36, 41, 31, 31, 43, 31, 31, 43, 38, 43, 28, 28, 40, 28, 28, 40, 35, 40],
    [69, 0, 72, 0, 76, 0, 74, 72, 77, 0, 76, 0, 72, 0, 0, 0, 71, 0, 74, 0, 79, 0, 77, 76, 76, 0, 74, 0, 72, 0, 0, 0],
    ['T', 'c', 't', 'c', 'T', 't', 's', 'c', 'T', 'c', 't', 'c', 'T', 't', 's', 's'], saw, saw),
  // Architect's Golem: heavy, epic, mechanical, POUNDING drums. D minor organ + war drums.
  boss_golem: () => epic(112, 8,
    [[38, 45, 50, 53], [34, 41, 46, 50], [36, 43, 48, 52], [33, 40, 45, 49]],
    [26, 26, 38, 26, 26, 38, 26, 38, 22, 22, 34, 22, 22, 34, 22, 34, 24, 24, 36, 24, 24, 36, 24, 36, 21, 21, 33, 21, 21, 33, 25, 28],
    [74, 0, 0, 77, 76, 0, 74, 0, 70, 0, 0, 0, 69, 0, 0, 0, 72, 0, 0, 76, 74, 0, 72, 0, 73, 0, 0, 0, 0, 0, 0, 0],
    ['T', 'T', 'c', 't', 'T', 'T', 's', 'c', 'T', 'T', 'c', 't', 'T', 't', 's', 's'], organ, saw),

  // ----- STORY MODE (Colosseum 4) -----
  // Overground Dark Cave: sparse, hollow, drips and low pulses.
  story_darkcave: () => song(70, 8,
    [31, 0, 0, 0, 0, 0, 0, 0, 34, 0, 0, 0, 30, 0, 0, 0],
    [0, 0, 0, 0, 55, 0, 0, 0, 0, 0, 58, 0, 0, 0, 0, 0, 0, 0, 0, 0, 54, 0, 0, 0, 0, 0, 0, 0, 51, 0, 0, 0],
    ['k', 0, 'd', 0, 0, 0, 'd', 0], tri, tri),
  // The Void: eerie choir pads, detuned bells, no rhythm to hold on to.
  story_void: () => epic(60, 8,
    [[36, 43, 46, 51], [35, 42, 45, 50], [37, 44, 47, 52], [34, 41, 44, 49]],
    [24, 0, 0, 0, 0, 0, 0, 0, 23, 0, 0, 0, 0, 0, 0, 0, 25, 0, 0, 0, 0, 0, 0, 0, 22, 0, 0, 0, 0, 0, 0, 0],
    [0, 0, 63, 0, 0, 0, 62, 0, 0, 0, 0, 0, 58, 0, 0, 0, 0, 0, 64, 0, 0, 0, 63, 0, 0, 0, 0, 0, 57, 0, 0, 0],
    ['b', 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 'b', 0, 0, 0], tri, tri),
  // The Altar: soft holy light in the dark - gentle choir and bells.
  story_altar: () => epic(66, 8,
    [[48, 55, 60, 64], [45, 52, 57, 60], [53, 57, 60, 65], [55, 59, 62, 67]],
    [36, 0, 0, 0, 0, 0, 0, 0, 33, 0, 0, 0, 0, 0, 0, 0, 41, 0, 0, 0, 0, 0, 0, 0, 43, 0, 0, 0, 0, 0, 0, 0],
    [76, 0, 0, 0, 79, 0, 0, 0, 77, 0, 76, 0, 72, 0, 0, 0, 77, 0, 0, 0, 81, 0, 79, 0, 79, 0, 0, 0, 74, 0, 0, 0],
    ['b', 0, 0, 0, 0, 0, 0, 0, 'b', 0, 0, 0, 0, 0, 0, 0], tri, tri),
  // Void Massacre: frantic skittering strings, choir, pounding drums. B phrygian.
  boss_massacre: () => epic(150, 8,
    [[47, 54, 59, 62], [48, 55, 60, 64], [45, 52, 57, 60], [48, 55, 60, 63]],
    [35, 47, 35, 47, 36, 48, 35, 47, 35, 47, 35, 47, 36, 48, 38, 36, 33, 45, 33, 45, 36, 48, 33, 45, 36, 48, 36, 48, 35, 47, 36, 35],
    [71, 72, 71, 0, 74, 0, 72, 71, 69, 0, 71, 0, 0, 0, 0, 0, 72, 0, 71, 69, 67, 0, 69, 71, 72, 0, 74, 0, 71, 0, 0, 0],
    ['T', 'c', 's', 'c', 't', 'c', 's', 't', 'T', 'c', 's', 'c', 't', 't', 's', 's'], organ, saw),
};

// These 12 are DESIGNED by tools/make_sfx.js now (never overwritten here, even with --force)
const DESIGNED = ['roar', 'dragon_roar', 'bark', 'croak', 'bite', 'flame', 'holy', 'ultimate', 'geyser', 'splash', 'rumble', 'flask_drink'];
let made = 0, kept = 0;
for (const [name, fn] of Object.entries(SFX)) {
  const f = path.join(ROOT, 'audio', 'sfx', name + '.wav');
  if (fs.existsSync(path.join(ROOT, 'audio', 'sfx', name + '.ogg'))) { kept++; continue; }   // A real recording (audio/CREDITS.txt) wins
  if (DESIGNED.includes(name)) { kept++; continue; }                                          // Made by tools/make_sfx.js
  if (!force && fs.existsSync(f)) { kept++; continue; }
  writeWav(f, fn()); made++;
}
// MUSIC is now rendered with real instruments by tools/make_music.js (it reads the notes from
// MUSIC above). The old synth versions are only written with --synth-music.
for (const [name, fn] of Object.entries(MUSIC)) {
  const f = path.join(ROOT, 'audio', 'music', name + '.wav');
  if (!process.argv.includes('--synth-music')) continue;
  if (!force && fs.existsSync(f)) { kept++; continue; }
  writeWav(f, fn()); made++;
}
console.log(`placeholders written: ${made}, existing kept: ${kept}`);
