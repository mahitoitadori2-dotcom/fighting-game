// RED CONSOLE SOUNDS (2026-11-21, user: "Fried sound effects for #s00 commands").
//   node tools/make_console_sfx.js        -> audio/sfx/console_pierce.wav, audio/sfx/console_gunshot.wav
// Made from scratch (no samples), then DEEP FRIED the same way as tools/deep_fry_voice.js:
// hard overdrive (tanh) + bitcrush (few bits, sample-and-hold) + normalize.
//   #s001  console_pierce   a PIERCING stab: metal "shing" + a shrill screech that bends up + ringing
//   #s002  console_gunshot  a fried GUNSHOT: crack + low boom + a short echo tail
//   #s003  uses the XX0XN voice line audio/voice/xx0xn_hank.wav (already deep fried)
const fs = require('fs'), path = require('path');
const RATE = 22050;

function writeWav(file, s) {
  const b = Buffer.alloc(44 + s.length * 2);
  b.write('RIFF', 0); b.writeUInt32LE(36 + s.length * 2, 4); b.write('WAVE', 8);
  b.write('fmt ', 12); b.writeUInt32LE(16, 16); b.writeUInt16LE(1, 20); b.writeUInt16LE(1, 22);
  b.writeUInt32LE(RATE, 24); b.writeUInt32LE(RATE * 2, 28); b.writeUInt16LE(2, 32); b.writeUInt16LE(16, 34);
  b.write('data', 36); b.writeUInt32LE(s.length * 2, 40);
  for (let i = 0; i < s.length; i++) b.writeInt16LE(Math.max(-32767, Math.min(32767, Math.round(s[i] * 32767))), 44 + i * 2);
  fs.writeFileSync(file, b);
}

let seed = 1234567;
const rnd = () => { seed = (seed * 1103515245 + 12345) & 0x7fffffff; return seed / 0x7fffffff * 2 - 1; };

function fry(s, drive, levels, hold) {
  let h = 0;
  for (let i = 0; i < s.length; i++) {
    const x = Math.tanh(s[i] * drive);
    if (i % hold === 0) h = Math.round(x * levels) / levels;
    s[i] = h;
  }
  let peak = 0;
  for (const v of s) peak = Math.max(peak, Math.abs(v));
  for (let i = 0; i < s.length; i++) s[i] = s[i] / (peak || 1) * 0.92;
  // 5 ms fade-out so it never ends in a click
  const f = Math.floor(RATE * 0.005);
  for (let i = 0; i < f; i++) s[s.length - 1 - i] *= i / f;
  return s;
}

// ---- #s001: PIERCING ----
function pierce() {
  const n = Math.floor(RATE * 1.1), s = new Float32Array(n);
  let ph1 = 0, ph2 = 0, ph3 = 0, hp = 0, prev = 0;
  for (let i = 0; i < n; i++) {
    const t = i / RATE;
    // the stab: a bright noise "shing" in the first 60 ms (high-passed noise)
    const nz = rnd(); hp = 0.85 * (hp + nz - prev); prev = nz;
    const stab = hp * Math.exp(-t * 55) * 1.2;
    // the screech: 2.2 kHz bending UP to 3.4 kHz, wobbling (vibrato), swelling then dying
    const f1 = 2200 + 1200 * Math.min(1, t / 0.5) + 90 * Math.sin(2 * Math.PI * 11 * t);
    ph1 += 2 * Math.PI * f1 / RATE;
    const env = Math.min(1, t / 0.03) * Math.exp(-t * 2.6);
    const screech = Math.sin(ph1 + 2.5 * Math.sin(ph1 * 0.5)) * env * 0.7;  // FM: harsh + metallic
    // the ring: two inharmonic metal partials
    ph2 += 2 * Math.PI * 4710 / RATE; ph3 += 2 * Math.PI * 6290 / RATE;
    const ring = (Math.sin(ph2) * 0.35 + Math.sin(ph3) * 0.25) * Math.exp(-t * 4.0);
    s[i] = stab + screech + ring;
  }
  return fry(s, 5.0, 9, 2);
}

// ---- #s002: GUNSHOT ----
function gunshot() {
  const n = Math.floor(RATE * 1.0), dry = new Float32Array(n);
  let lp = 0, ph = 0;
  for (let i = 0; i < n; i++) {
    const t = i / RATE;
    const nz = rnd();
    const crack = nz * Math.exp(-t * 90) * 1.4;                       // the CRACK
    lp += (nz - lp) * 0.06;
    const body = lp * Math.exp(-t * 9) * 3.0;                          // the dark noise body
    const f = 140 * Math.exp(-t * 14) + 45;                            // the BOOM: a pitch drop
    ph += 2 * Math.PI * f / RATE;
    const boom = Math.sin(ph) * Math.exp(-t * 7) * 1.1;
    dry[i] = crack + body + boom;
  }
  const s = new Float32Array(n);                                       // a short echo (a wall nearby)
  const d1 = Math.floor(RATE * 0.11), d2 = Math.floor(RATE * 0.23);
  for (let i = 0; i < n; i++) s[i] = dry[i] + (dry[i - d1] || 0) * 0.35 + (dry[i - d2] || 0) * 0.18;
  return fry(s, 9.0, 7, 3);
}

const dir = path.join(__dirname, '..', 'audio', 'sfx');
writeWav(path.join(dir, 'console_pierce.wav'), pierce());
writeWav(path.join(dir, 'console_gunshot.wav'), gunshot());
console.log('wrote console_pierce.wav + console_gunshot.wav');
