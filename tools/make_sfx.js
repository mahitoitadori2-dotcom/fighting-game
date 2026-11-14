#!/usr/bin/env node
// UNIVERSAL BEATDOWN - the 12 DESIGNED sound effects (the ones the Kenney CC0 packs had no match for).
//   node tools/make_sfx.js            all 12            node tools/make_sfx.js roar bite   only some
// Writes audio/sfx/<name>.wav (32 kHz mono 16-bit). Made two ways:
//   * CREATURES (roar, dragon_roar, bark, croak, bite) + FIRE / WATER (flame, geyser, splash): synthesis
//     shaped like real voices - a rough vocal-cord source (saw + sub-octave + jitter + growl flutter)
//     through vowel FORMANT filters, saturation, air noise and a room.
//   * MAGIC / IMPACT (holy, ultimate, rumble, flask_drink): real orchestral recordings from the
//     MuseScore_General SoundFont (choir, tubular bells, glockenspiel, timpani, orchestra hit, bass drum,
//     reverse cymbal) layered with synthesis. Needs the SoundFont (see tools/make_music.js).
const fs = require('fs'), path = require('path');
const M = require('./make_music.js');
const SR = M.SR;
const ROOT = path.resolve(__dirname, '..');

// ---------------- helpers ----------------
let seed = 12345;
const rnd = () => { seed = (seed * 1664525 + 1013904223) >>> 0; return seed / 4294967296 * 2 - 1; };
const buf = (sec) => new Float32Array(Math.round(sec * SR));
const clamp = (x, a, b) => Math.max(a, Math.min(b, x));
const lerp = (a, b, k) => a + (b - a) * k;
const smooth = (k) => k * k * (3 - 2 * k);

// TPT state-variable filter: per-sample cutoff (fc may be a function of t). Returns {lp, bp, hp}.
function svf(x, fc, q, kind) {
  const out = new Float32Array(x.length);
  let ic1 = 0, ic2 = 0;
  for (let n = 0; n < x.length; n++) {
    const f = typeof fc === 'function' ? fc(n / SR) : fc;
    const g = Math.tan(Math.PI * clamp(f, 20, SR * 0.45) / SR), k = 1 / q;
    const a1 = 1 / (1 + g * (g + k)), a2 = g * a1, a3 = g * a2;
    const v3 = x[n] - ic2, v1 = a1 * ic1 + a2 * v3, v2 = ic2 + a2 * ic1 + a3 * v3;
    ic1 = 2 * v1 - ic1; ic2 = 2 * v2 - ic2;
    out[n] = kind === 'lp' ? v2 : kind === 'bp' ? v1 * k : x[n] - k * v1 - v2;
  }
  return out;
}
// Vowel formants: parallel band-passes. fs = [[freq, q, gain], ...], scale shifts them (bigger beast = lower).
function formants(x, fs, scale = 1, scaleFn = null) {
  const out = new Float32Array(x.length);
  for (const [f, q, g] of fs) {
    const y = svf(x, scaleFn ? (t) => f * scaleFn(t) : f * scale, q, 'bp');
    for (let n = 0; n < x.length; n++) out[n] += y[n] * g;
  }
  return out;
}
// Rough "vocal cords": f0(t) in Hz, with jitter, a sub-octave (growl weight) and flutter (AM rattle).
function voice(sec, f0, { sub = 0.5, jitter = 0.02, flutter = 30, flutterAmt = 0.4, noise = 0.25 } = {}) {
  const b = buf(sec);
  let ph = 0, ph2 = 0, j = 0;
  for (let n = 0; n < b.length; n++) {
    const t = n / SR;
    if (n % 64 === 0) j = rnd() * jitter;
    const f = f0(t) * (1 + j);
    ph = (ph + f / SR) % 1; ph2 = (ph2 + f * 0.5 / SR) % 1;
    const saw = ph * 2 - 1, subw = ph2 < 0.5 ? 1 : -1;
    const am = 1 - flutterAmt * (0.5 + 0.5 * Math.sin(2 * Math.PI * flutter * t + 3 * Math.sin(t * 7)));
    b[n] = (saw + sub * subw * 0.6) * am + noise * rnd();
  }
  return b;
}
function noiseBuf(sec) { const b = buf(sec); for (let n = 0; n < b.length; n++) b[n] = rnd(); return b; }
// Envelope by points [[t, level], ...] (linear in between).
function shape(x, pts) {
  for (let n = 0; n < x.length; n++) {
    const t = n / SR;
    let lev = pts[pts.length - 1][1];
    for (let i = 0; i < pts.length - 1; i++) {
      if (t >= pts[i][0] && t < pts[i + 1][0]) { lev = lerp(pts[i][1], pts[i + 1][1], (t - pts[i][0]) / (pts[i + 1][0] - pts[i][0])); break; }
    }
    if (t < pts[0][0]) lev = pts[0][1];
    x[n] *= lev;
  }
  return x;
}
const sat = (x, drive) => { for (let n = 0; n < x.length; n++) x[n] = Math.tanh(x[n] * drive); return x; };
function mix(out, x, gain = 1, at = 0) {
  const o = Math.round(at * SR);
  for (let n = 0; n < x.length && n + o < out.length; n++) out[n + o] += x[n] * gain;
  return out;
}
function finish(x, peak = 0.89) {
  let m = 0; for (const v of x) m = Math.max(m, Math.abs(v));
  const g = m > 0 ? peak / m : 1;
  // 3 ms fade in / 20 ms fade out: no clicks
  for (let n = 0; n < x.length; n++) {
    const fi = clamp(n / (0.003 * SR), 0, 1), fo = clamp((x.length - n) / (0.02 * SR), 0, 1);
    x[n] *= g * fi * fo;
  }
  return x;
}
function writeWav(file, x) {
  const data = Buffer.alloc(x.length * 2);
  for (let n = 0; n < x.length; n++) data.writeInt16LE(Math.round(clamp(x[n], -1, 1) * 32767), n * 2);
  const h = Buffer.alloc(44);
  h.write('RIFF', 0); h.writeUInt32LE(36 + data.length, 4); h.write('WAVE', 8); h.write('fmt ', 12);
  h.writeUInt32LE(16, 16); h.writeUInt16LE(1, 20); h.writeUInt16LE(1, 22); h.writeUInt32LE(SR, 24);
  h.writeUInt32LE(SR * 2, 28); h.writeUInt16LE(2, 32); h.writeUInt16LE(16, 34); h.write('data', 36); h.writeUInt32LE(data.length, 40);
  fs.writeFileSync(file, Buffer.concat([h, data]));
}

// Vowels (Hz, Q, gain) - adult-human values, scaled per creature
const AH = [[700, 5, 1.0], [1150, 6, 0.6], [2500, 8, 0.25]];
const AW = [[600, 5, 1.0], [950, 6, 0.7], [2400, 8, 0.2]];
const OO = [[350, 5, 1.0], [800, 6, 0.4], [2300, 8, 0.12]];
const EE = [[300, 5, 0.8], [2200, 8, 0.6], [2900, 9, 0.35]];

// SoundFont instruments (GM program numbers, 0-based)
const GM = (prog, gain = 1) => ({ bank: 0, prog, gain });
const DRUMS = { bank: 128, prog: 0, gain: 1 };
const INST = { glock: GM(9), bells: GM(14), timpani: GM(47), choir: GM(52), voice_oohs: GM(53), orch_hit: GM(55),
  trumpet: GM(56), trombone: GM(57), horn: GM(60), brass: GM(61), harp: GM(46), rev_cymbal: GM(119), seashore: GM(122) };
let sf = null;
const play = (out, inst, key, vel, at, dur, gain = 1) => M.note(sf, out, inst, key, vel, at, dur, gain);

// ---------------- the 12 sounds ----------------
const SFX = {
  // A big beast: falling growl through an open "AW", rattling, with breath
  roar: () => {
    const len = 1.35;
    const v = voice(len, (t) => lerp(150, 92, smooth(clamp(t / 1.1, 0, 1))) + 12 * Math.sin(t * 9), { sub: 0.8, jitter: 0.04, flutter: 28, flutterAmt: 0.55, noise: 0.35 });
    let y = formants(v, AW, 0.72, (t) => 0.78 - 0.1 * t);
    y = svf(sat(y, 2.6), 3800, 0.7, 'lp');
    const breath = svf(noiseBuf(len), (t) => 900 + 500 * Math.sin(t * 3), 1.2, 'bp');
    mix(y, breath, 0.35);
    shape(y, [[0, 0], [0.1, 1], [0.85, 0.85], [len, 0]]);
    return M.reverb(y, 0.7, 0.4, 0.18, 0.95, 0.02);
  },
  // Geyron: a huge low growl + a screech on top, breath like a furnace, in a cave
  dragon_roar: () => {
    const len = 1.9;
    const low = voice(len, (t) => lerp(95, 62, clamp(t / 1.6, 0, 1)), { sub: 1.0, jitter: 0.05, flutter: 22, flutterAmt: 0.6, noise: 0.4 });
    let y = formants(low, AW, 0.55);
    const hi = voice(len, (t) => lerp(330, 470, smooth(clamp(t / 0.5, 0, 1))) - 140 * clamp((t - 0.6) / 1.2, 0, 1), { sub: 0.2, jitter: 0.03, flutter: 41, flutterAmt: 0.45, noise: 0.3 });
    const scr = formants(hi, EE, 0.85);
    shape(scr, [[0, 0], [0.18, 0.5], [0.5, 1], [1.4, 0.6], [len, 0]]);
    mix(y, scr, 0.55);
    y = svf(sat(y, 3.0), 4500, 0.7, 'lp');
    mix(y, shape(svf(noiseBuf(len), (t) => 400 + 1600 * clamp(t, 0, 1), 0.8, 'bp'), [[0, 0], [0.2, 0.6], [len, 0]]), 0.5);
    shape(y, [[0, 0], [0.15, 1], [1.3, 0.9], [len, 0]]);
    return M.reverb(y, 0.84, 0.35, 0.35, 0.9, 0.04);
  },
  // Rotor: two short barks - a sharp "WUF", the second a bit higher
  bark: () => {
    const out = buf(0.42);
    for (const [at, f, sc] of [[0, 520, 1.0], [0.19, 580, 1.06]]) {
      const len = 0.13;
      const v = voice(len, (t) => f * (1 - 0.45 * clamp(t / len, 0, 1)), { sub: 0.3, jitter: 0.03, flutter: 60, flutterAmt: 0.2, noise: 0.5 });
      let y = formants(v, AW, 1.25 * sc);
      y = sat(y, 3.0);
      shape(y, [[0, 0], [0.008, 1], [0.05, 0.7], [len, 0]]);
      mix(out, y, 1, at);
    }
    return M.reverb(out, 0.5, 0.5, 0.12, 1.0, 0.01);
  },
  // King Frog: "RIB-BIT" - a buzzing pulse train through a throat resonance, two syllables
  croak: () => {
    const len = 0.62, out = buf(len);
    for (const [at, dur, f, rate] of [[0, 0.22, 120, 34], [0.3, 0.26, 95, 28]]) {
      const b = buf(dur);
      let ph = 0;
      for (let n = 0; n < b.length; n++) {
        const t = n / SR;
        ph = (ph + rate / SR) % 1;
        const pulse = Math.exp(-ph * 9);                                 // A burst per vocal-sac pulse
        b[n] = Math.sin(2 * Math.PI * f * t + 2 * Math.sin(2 * Math.PI * f * 2 * t)) * pulse + 0.2 * rnd() * pulse;
      }
      let y = formants(b, OO, 1.1);
      y = svf(y, 260, 2.5, 'bp');
      mix(y, b, 0.25);
      shape(y, [[0, 0], [0.02, 1], [dur * 0.7, 0.8], [dur, 0]]);
      mix(out, sat(y, 2.0), 1, at);
    }
    return M.reverb(out, 0.55, 0.45, 0.14, 1.0, 0.01);
  },
  // Minos' serpent bite: a hiss, two teeth CLACKS, a wet crunch and a thud
  bite: () => {
    const len = 0.32, out = buf(len);
    mix(out, shape(svf(noiseBuf(0.08), 5000, 1.0, 'hp'), [[0, 0], [0.02, 0.5], [0.08, 0]]), 0.6);
    for (const at of [0.06, 0.085]) {
      const c = buf(0.03);
      for (let n = 0; n < c.length; n++) { const t = n / SR; c[n] = (Math.sin(2 * Math.PI * 2600 * t) + 0.7 * Math.sin(2 * Math.PI * 4100 * t)) * Math.exp(-t * 260) + rnd() * Math.exp(-t * 400); }
      mix(out, c, 0.9, at);
    }
    const crunch = svf(noiseBuf(0.16), (t) => 2600 - 9000 * t, 1.4, 'bp');
    for (let n = 0; n < crunch.length; n++) crunch[n] *= (0.5 + 0.5 * Math.sign(Math.sin(n / SR * 2 * Math.PI * 70))) * Math.exp(-n / SR * 18);
    mix(out, crunch, 1.2, 0.09);
    const thud = buf(0.18);
    for (let n = 0; n < thud.length; n++) { const t = n / SR; thud[n] = Math.sin(2 * Math.PI * (90 - 120 * t) * t) * Math.exp(-t * 22); }
    mix(out, thud, 0.9, 0.08);
    return out;
  },
  // Fire breath: a whoosh that opens up, a low roar under it, crackles and pops
  flame: () => {
    const len = 0.75, out = buf(len);
    mix(out, shape(svf(noiseBuf(len), (t) => 300 + 2200 * Math.sin(Math.PI * clamp(t / len, 0, 1)), 0.9, 'bp'), [[0, 0], [0.08, 1], [0.45, 0.8], [len, 0]]), 1.0);
    mix(out, shape(svf(noiseBuf(len), 180, 0.8, 'lp'), [[0, 0], [0.1, 1], [len, 0]]), 1.4);
    const cr = buf(len);
    for (let n = 0; n < cr.length; n++) if (rnd() > 0.9965) for (let k = 0; k < 90 && n + k < cr.length; k++) cr[n + k] += rnd() * Math.exp(-k / 14);
    mix(out, svf(cr, 2200, 1.2, 'bp'), 1.6);
    return M.reverb(sat(out, 1.4), 0.6, 0.5, 0.15, 1.0, 0.01);
  },
  // Magma geyser: the ground gurgles, then a jet BURSTS up (hiss opening up), lava drops fall back
  geyser: () => {
    const len = 1.2, out = buf(len);
    const g = buf(0.35);
    for (let n = 0; n < g.length; n++) { const t = n / SR; g[n] = Math.sin(2 * Math.PI * (55 + 25 * Math.sin(t * 40)) * t) * (0.6 + 0.4 * Math.sin(t * 2 * Math.PI * 13)); }
    mix(out, shape(g, [[0, 0], [0.1, 0.8], [0.35, 0.3]]), 0.9);
    mix(out, shape(svf(noiseBuf(0.9), (t) => 500 + 5500 * clamp(t / 0.25, 0, 1) - 3000 * clamp((t - 0.4) / 0.5, 0, 1), 0.7, 'lp'), [[0, 0], [0.04, 1], [0.5, 0.7], [0.9, 0]]), 1.2, 0.25);
    mix(out, shape(svf(noiseBuf(0.8), 110, 0.7, 'lp'), [[0, 0], [0.05, 1], [0.8, 0]]), 1.6, 0.25);
    for (let k = 0; k < 7; k++) {
      const d = buf(0.06), f0 = 500 + Math.abs(rnd()) * 700;
      for (let n = 0; n < d.length; n++) { const t = n / SR; d[n] = Math.sin(2 * Math.PI * (f0 + 4000 * t) * t) * Math.exp(-t * 60); }
      mix(out, d, 0.35, 0.6 + k * 0.07);
    }
    return M.reverb(out, 0.7, 0.45, 0.18, 1.0, 0.02);
  },
  // Into water: a heavy slap, a body of spray, then rising "bloop" droplets
  splash: () => {
    const len = 0.95, out = buf(len);
    mix(out, shape(svf(noiseBuf(0.4), (t) => 1800 - 1500 * clamp(t / 0.4, 0, 1), 0.8, 'lp'), [[0, 0], [0.005, 1], [0.12, 0.5], [0.4, 0]]), 1.4);
    const slap = buf(0.1);
    for (let n = 0; n < slap.length; n++) { const t = n / SR; slap[n] = Math.sin(2 * Math.PI * (140 - 300 * t) * t) * Math.exp(-t * 35); }
    mix(out, slap, 1.0);
    for (let k = 0; k < 12; k++) {
      const d = buf(0.05), f0 = 400 + Math.abs(rnd()) * 900;
      for (let n = 0; n < d.length; n++) { const t = n / SR; d[n] = Math.sin(2 * Math.PI * (f0 * (1 + 9 * t)) * t) * Math.exp(-t * 70); }
      mix(out, d, 0.3 + 0.2 * Math.abs(rnd()), 0.12 + k * 0.05 + 0.02 * rnd());
    }
    mix(out, shape(svf(noiseBuf(len), 4000, 0.7, 'hp'), [[0, 0], [0.05, 0.25], [len, 0]]), 0.4);
    return M.reverb(out, 0.6, 0.5, 0.14, 1.0, 0.01);
  },
  // The ground shaking: a timpani roll on low D, concert bass drum hits, a deep earth growl
  rumble: () => {
    const len = 1.8, out = buf(len);
    for (let k = 0; k < 22; k++) play(out, INST.timpani, 38 + (k % 2), 60 + Math.round(40 * Math.sin(Math.PI * k / 22)), k * 0.055, 0.2, 0.9);
    play(out, DRUMS, 35, 120, 0.0, 0.8, 1.2);
    play(out, DRUMS, 35, 110, 0.55, 0.8, 1.0);
    mix(out, shape(svf(noiseBuf(len), 70, 0.7, 'lp'), [[0, 0], [0.25, 1], [1.2, 0.8], [len, 0]]), 3.0);
    return M.reverb(out, 0.8, 0.4, 0.22, 1.0, 0.02);
  },
  // Light magic: a choir swells on a bright chord, tubular bells and glockenspiel sparkle, shimmer
  holy: () => {
    const len = 1.4, out = buf(len);
    for (const k of [72, 76, 79, 84]) play(out, INST.choir, k, 95, 0.0, 1.0, 0.9);
    play(out, INST.bells, 84, 100, 0.0, 1.0, 0.8);
    [96, 100, 103, 108].forEach((k, i) => play(out, INST.glock, k, 90, 0.05 + i * 0.06, 0.4, 0.5));
    mix(out, shape(svf(noiseBuf(len), 7000, 0.7, 'hp'), [[0, 0], [0.3, 0.12], [len, 0]]), 1.0);
    return M.reverb(out, 0.9, 0.3, 0.45, 0.8, 0.03);
  },
  // An ULTIMATE: a reversed cymbal sucks in, then an orchestra HIT + brass chord + timpani + crash
  ultimate: () => {
    const len = 1.6, out = buf(len);
    play(out, INST.rev_cymbal, 60, 110, 0.0, 0.62, 1.2);
    const hit = 0.55;
    for (const k of [48, 55, 60, 64]) play(out, INST.orch_hit, k, 120, hit, 0.4, 1.0);
    for (const k of [48, 55, 60, 67]) play(out, INST.brass, k, 115, hit, 0.6, 0.7);
    play(out, INST.timpani, 40, 127, hit, 0.6, 1.4);
    play(out, DRUMS, 49, 120, hit, 1.0, 1.0);
    play(out, DRUMS, 35, 127, hit, 0.6, 1.2);
    return M.reverb(out, 0.86, 0.35, 0.32, 0.9, 0.02);
  },
  // Drinking a flask: the cork POPS, three gulps, then a healing sparkle (glockenspiel + harp)
  flask_drink: () => {
    const len = 1.15, out = buf(len);
    const pop = buf(0.08);
    for (let n = 0; n < pop.length; n++) { const t = n / SR; pop[n] = Math.sin(2 * Math.PI * (1100 - 5000 * t) * t) * Math.exp(-t * 70) + 0.5 * rnd() * Math.exp(-t * 300); }
    mix(out, pop, 0.9, 0.01);
    for (let k = 0; k < 3; k++) {
      const gl = buf(0.16);
      for (let n = 0; n < gl.length; n++) { const t = n / SR; gl[n] = Math.sin(2 * Math.PI * (190 - 260 * t) * t) * Math.sin(Math.PI * clamp(t / 0.16, 0, 1)) + 0.15 * rnd(); }
      mix(out, svf(formants(gl, OO, 0.9), 900, 0.7, 'lp'), 2.2, 0.16 + k * 0.17);
    }
    [84, 88, 91, 96].forEach((k, i) => play(out, INST.glock, k, 90, 0.72 + i * 0.05, 0.3, 0.6));
    play(out, INST.harp, 72, 90, 0.72, 0.4, 0.6);
    return M.reverb(out, 0.7, 0.4, 0.22, 0.95, 0.02);
  },
};

// ---------------- main ----------------
const LOUDER = { croak: 2.2, bite: 2.0, splash: 2.4, flask_drink: 2.2, ultimate: 1.6 };
const only = process.argv.slice(2).filter((a) => !a.startsWith('-'));
const names = only.length ? only : Object.keys(SFX);
if (names.some((n) => ['holy', 'ultimate', 'rumble', 'flask_drink'].includes(n))) {
  if (!fs.existsSync(M.SF2)) { console.error('SoundFont not found: ' + M.SF2 + ' (see tools/make_music.js)'); process.exit(1); }
  sf = M.readSF2(M.SF2);
}
for (const n of names) {
  if (!SFX[n]) { console.error('unknown sound: ' + n); continue; }
  seed = 12345 + n.length * 977;
  let x = finish(SFX[n](), 1.0);
  if (LOUDER[n]) x = sat(x, LOUDER[n]);                       // Short / spiky sounds: squeeze up to the others' loudness
  x = finish(x);
  writeWav(path.join(ROOT, 'audio', 'sfx', n + '.wav'), x);
  console.log(n.padEnd(12) + (x.length / SR).toFixed(2) + ' s');
}
