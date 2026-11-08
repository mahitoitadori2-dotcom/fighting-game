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

const MUSIC = {
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
};

let made = 0, kept = 0;
for (const [name, fn] of Object.entries(SFX)) {
  const f = path.join(ROOT, 'audio', 'sfx', name + '.wav');
  if (!force && fs.existsSync(f)) { kept++; continue; }
  writeWav(f, fn()); made++;
}
for (const [name, fn] of Object.entries(MUSIC)) {
  const f = path.join(ROOT, 'audio', 'music', name + '.wav');
  if (!force && fs.existsSync(f)) { kept++; continue; }
  writeWav(f, fn()); made++;
}
console.log(`placeholders written: ${made}, existing kept: ${kept}`);
