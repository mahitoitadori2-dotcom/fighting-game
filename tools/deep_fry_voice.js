// DEEP-FRIED VOICE LINES (2026-11-21): turns a plain spoken WAV (Windows TTS) into a monster yell.
//   node tools/deep_fry_voice.js <in.wav> <out.wav> [pitch=0.62]
// Trim the silence -> pitch DOWN (slower + lower) -> a second layer an extra fifth lower underneath ->
// bass boost -> hard overdrive (tanh) -> BITCRUSH (5 bits, sample-and-hold) -> normalize.
// Output: 22050 Hz mono 16-bit WAV (the SoundManager plays it from res://audio/voice/).
const fs = require('fs');

function readWav(file) {
  const b = fs.readFileSync(file);
  let o = 12, rate = 22050, ch = 1, bits = 16, data = null;
  while (o < b.length - 8) {
    const id = b.toString('ascii', o, o + 4), size = b.readUInt32LE(o + 4);
    if (id === 'fmt ') { ch = b.readUInt16LE(o + 10); rate = b.readUInt32LE(o + 12); bits = b.readUInt16LE(o + 22); }
    if (id === 'data') data = b.subarray(o + 8, o + 8 + size);
    o += 8 + size + (size & 1);
  }
  if (bits !== 16) throw new Error('only 16-bit PCM');
  const n = data.length / 2 / ch, out = new Float32Array(n);
  for (let i = 0; i < n; i++) out[i] = data.readInt16LE(i * 2 * ch) / 32768;
  return { rate, s: out };
}

function writeWav(file, rate, s) {
  const b = Buffer.alloc(44 + s.length * 2);
  b.write('RIFF', 0); b.writeUInt32LE(36 + s.length * 2, 4); b.write('WAVE', 8);
  b.write('fmt ', 12); b.writeUInt32LE(16, 16); b.writeUInt16LE(1, 20); b.writeUInt16LE(1, 22);
  b.writeUInt32LE(rate, 24); b.writeUInt32LE(rate * 2, 28); b.writeUInt16LE(2, 32); b.writeUInt16LE(16, 34);
  b.write('data', 36); b.writeUInt32LE(s.length * 2, 40);
  for (let i = 0; i < s.length; i++) b.writeInt16LE(Math.max(-32767, Math.min(32767, Math.round(s[i] * 32767))), 44 + i * 2);
  fs.writeFileSync(file, b);
}

function trim(s, th = 0.015) {
  let a = 0, z = s.length - 1;
  while (a < s.length && Math.abs(s[a]) < th) a++;
  while (z > a && Math.abs(s[z]) < th) z--;
  return s.subarray(Math.max(0, a - 300), Math.min(s.length, z + 1200));
}

function resample(s, k) {               // k < 1 = lower + slower
  const n = Math.floor(s.length / k), out = new Float32Array(n);
  for (let i = 0; i < n; i++) {
    const x = i * k, j = Math.floor(x), f = x - j;
    out[i] = (s[j] || 0) * (1 - f) + (s[j + 1] || 0) * f;
  }
  return out;
}

const [, , inp, outp, pArg] = process.argv;
const pitch = +(pArg || 0.62);
const { rate, s } = readWav(inp);
const dry = trim(s);
const a = resample(dry, pitch), b = resample(dry, pitch * 0.75);       // + a layer a fifth lower
const n = Math.max(a.length, b.length), mix = new Float32Array(n);
let lp = 0;
for (let i = 0; i < n; i++) {
  let x = (a[i] || 0) * 0.75 + (b[i] || 0) * 0.55;
  lp += (x - lp) * 0.08;                                               // Bass boost (one-pole low-pass mixed back in)
  x = x + lp * 1.8;
  x = Math.tanh(x * 7.0);                                              // DEEP FRIED
  mix[i] = x;
}
let hold = 0;                                                          // BITCRUSH: 5 bits, every 3rd sample held
for (let i = 0; i < n; i++) {
  if (i % 3 === 0) hold = Math.round(mix[i] * 15) / 15;
  mix[i] = hold;
}
let peak = 0;
for (const v of mix) peak = Math.max(peak, Math.abs(v));
for (let i = 0; i < n; i++) mix[i] = mix[i] / (peak || 1) * 0.92;
writeWav(outp, rate, mix);
console.log(`${outp}: ${(n / rate).toFixed(2)} s`);
