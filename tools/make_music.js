// REAL-INSTRUMENT MUSIC for Universal Beatdown (Souls-like / Hollow Knight-like).
//
//   node tools/make_music.js                 -> renders every track into audio/music/<name>.wav
//   node tools/make_music.js boss_sun menu   -> only those tracks
//
// HOW: a small SoundFont (SF2) sample player written here in plain JavaScript (no other
// programs needed) plays REAL INSTRUMENT RECORDINGS - strings, violin, cello, contrabass,
// trombone, French horn, tuba, trumpet, church organ, piano, harp, nylon guitar, harpsichord,
// choir, timpani, taiko, tubular bells, cymbals - then a concert-hall reverb is added.
//
// SOUNDFONT: MuseScore_General.sf2 (MIT licence, by the MuseScore team), NOT in the repo
// (215 MB). Put it at C:/code/audio_tools/MuseScore_General.sf2 or set SF2=<path>.
//   Download: https://ftp.osuosl.org/pub/musescore/soundfont/MuseScore_General/
//
// MUSIC: every track keeps its melody / chords / bass / rhythm from tools/make_placeholder_audio.js
// (read from that file), but is ARRANGED for orchestra with a style per track (STYLES below):
//   boss   - Dark Souls III / Elden Ring: string ensemble + choir (+ organ), cellos & basses,
//            brass or solo strings on the melody, timpani / bass drum / cymbals
//   area   - Hollow Knight: melancholic piano / harp / guitar / solo violin over soft strings
//   ...plus custom ones (violin duel, gong ritual, chaos, waltz, tribal, chase)
// Each loop plays TWICE (the melody passes to a second instrument), rendered seamlessly
// (reverb tails wrap around the loop point).
const fs = require('fs'), path = require('path');
const ROOT = path.resolve(__dirname, '..');
const SR = 32000;                                     // Output: 32 kHz mono 16-bit WAV (Godot compresses it to QOA)
const SF2 = process.env.SF2 || 'C:/code/audio_tools/MuseScore_General.sf2';

// ============================================================
// SF2 READER
// ============================================================
function readSF2(file) {
  const buf = fs.readFileSync(file);
  const id = (o) => buf.toString('ascii', o, o + 4);
  if (id(0) !== 'RIFF' || id(8) !== 'sfbk') throw new Error('not a SoundFont: ' + file);
  const sf = {};
  let o = 12;
  while (o < buf.length - 8) {
    const ckId = id(o), size = buf.readUInt32LE(o + 4);
    if (ckId === 'LIST') {
      const type = id(o + 8);
      let p = o + 12; const end = o + 8 + size;
      while (p < end - 8) {
        const sub = id(p), ss = buf.readUInt32LE(p + 4);
        if (type === 'sdta' && sub === 'smpl') sf.smpl = new Int16Array(buf.buffer, buf.byteOffset + p + 8, ss >> 1);
        if (type === 'pdta') sf[sub] = buf.subarray(p + 8, p + 8 + ss);
        p += 8 + ss + (ss & 1);
      }
    }
    o += 8 + size + (size & 1);
  }
  const recs = (b, n) => { const out = []; for (let i = 0; i + n <= b.length; i += n) out.push(i); return out; };
  const name = (b, at) => b.toString('ascii', at, at + 20).replace(/\0.*$/, '');
  sf.phdr_ = recs(sf.phdr, 38).map((i) => ({ name: name(sf.phdr, i), preset: sf.phdr.readUInt16LE(i + 20), bank: sf.phdr.readUInt16LE(i + 22), bag: sf.phdr.readUInt16LE(i + 24) }));
  sf.pbag_ = recs(sf.pbag, 4).map((i) => sf.pbag.readUInt16LE(i));
  sf.ibag_ = recs(sf.ibag, 4).map((i) => sf.ibag.readUInt16LE(i));
  const gens = (b) => recs(b, 4).map((i) => ({ op: b.readUInt16LE(i), amt: b.readInt16LE(i + 2), lo: b[i + 2], hi: b[i + 3] }));
  sf.pgen_ = gens(sf.pgen); sf.igen_ = gens(sf.igen);
  sf.inst_ = recs(sf.inst, 22).map((i) => ({ name: name(sf.inst, i), bag: sf.inst.readUInt16LE(i + 20) }));
  sf.shdr_ = recs(sf.shdr, 46).map((i) => ({
    name: name(sf.shdr, i), start: sf.shdr.readUInt32LE(i + 20), end: sf.shdr.readUInt32LE(i + 24),
    ls: sf.shdr.readUInt32LE(i + 28), le: sf.shdr.readUInt32LE(i + 32), rate: sf.shdr.readUInt32LE(i + 36),
    pitch: sf.shdr[i + 40], corr: sf.shdr.readInt8(i + 41) }));
  return sf;
}

// Zones of a preset / instrument: [{gens: {op: value | [lo,hi]}, link}] (first zone may be global)
function zones(bagStart, bagEnd, bags, genList, linkOp) {
  const out = [];
  for (let b = bagStart; b < bagEnd; b++) {
    const g = {};
    for (let k = bags[b]; k < bags[b + 1]; k++) {
      const e = genList[k];
      g[e.op] = (e.op === 43 || e.op === 44) ? [e.lo, e.hi] : e.amt;
    }
    out.push(g);
  }
  let glob = {};
  if (out.length && out[0][linkOp] === undefined) glob = out.shift();
  return { glob, list: out.filter((z) => z[linkOp] !== undefined) };
}

const NON_ADD = new Set([41, 43, 44, 53, 54, 57, 58, 0, 1, 2, 3, 4, 12, 45, 50, 46, 47]);
const DEF = { 8: 13500, 9: 0, 33: -12000, 34: -12000, 35: -12000, 36: -12000, 37: 0, 38: -12000, 48: 0, 51: 0, 52: 0, 56: 100, 58: -1 };
const inRange = (r, v) => !r || (v >= r[0] && v <= r[1]);

// All sample voices for (bank, program, key, vel): [{s, g}] g = merged generators
function voicesFor(sf, bank, prog, key, vel) {
  const pi = sf.phdr_.findIndex((p) => p.bank === bank && p.preset === prog);
  if (pi < 0 || pi >= sf.phdr_.length - 1) return [];
  const pz = zones(sf.phdr_[pi].bag, sf.phdr_[pi + 1].bag, sf.pbag_, sf.pgen_, 41);
  const out = [];
  for (const z of pz.list) {
    const pg = Object.assign({}, pz.glob, z);
    if (!inRange(pg[43], key) || !inRange(pg[44], vel)) continue;
    const ii = pg[41];
    const iz = zones(sf.inst_[ii].bag, sf.inst_[ii + 1].bag, sf.ibag_, sf.igen_, 53);
    for (const y of iz.list) {
      const ig = Object.assign({}, DEF, iz.glob, y);
      if (!inRange(ig[43], key) || !inRange(ig[44], vel)) continue;
      const g = Object.assign({}, ig);
      for (const op in pg) if (!NON_ADD.has(+op)) g[op] = (g[op] || 0) + pg[op];   // preset gens ADD
      out.push({ s: sf.shdr_[g[53]], g });
    }
  }
  return out;
}

// ============================================================
// VOICE RENDERING (sample + pitch + loop + volume envelope + low-pass)
// ============================================================
const tc = (v) => Math.pow(2, v / 1200);               // timecents -> seconds
function renderVoice(sf, out, v, key, vel, startSec, durSec, gainMul) {
  const { s, g } = v;
  const root = g[58] >= 0 ? g[58] : s.pitch;
  const cents = (key - root) * g[56] + g[51] * 100 + g[52] + s.corr;
  const step = Math.pow(2, cents / 1200) * s.rate / SR;
  const start = s.start + (g[0] || 0) + (g[4] || 0) * 32768;
  const end = s.end + (g[1] || 0) + (g[12] || 0) * 32768;
  const ls = s.ls + (g[2] || 0) + (g[45] || 0) * 32768;
  const le = s.le + (g[3] || 0) + (g[50] || 0) * 32768;
  const mode = g[54] || 0;
  const loops = (mode === 1 || mode === 3) && le > ls + 8;
  const atten = Math.pow(10, -(g[48] * 0.4) / 200);
  const velGain = Math.pow(vel / 127, 1.6);
  const amp = atten * velGain * gainMul;
  // Envelope (seconds / levels)
  const dly = tc(g[33]), att = Math.max(tc(g[34]), 0.002), hold = tc(g[35]), dec = tc(g[36]);
  const susDb = -Math.min(g[37], 1440) / 10, rel = Math.max(tc(g[38]), 0.03);
  // Low-pass (initialFilterFc, darker at low velocity: the default GM velocity modulator)
  const fcCents = g[8] - 2400 * (1 - vel / 127);
  const fcHz = 8.176 * Math.pow(2, fcCents / 1200);
  const useLp = fcHz < SR * 0.42;
  let b0 = 1, b1 = 0, b2 = 0, a1 = 0, a2 = 0;
  if (useLp) {
    const w = 2 * Math.PI * fcHz / SR, q = 0.75, al = Math.sin(w) / (2 * q), cw = Math.cos(w), a0 = 1 + al;
    b0 = (1 - cw) / 2 / a0; b1 = (1 - cw) / a0; b2 = b0; a1 = -2 * cw / a0; a2 = (1 - al) / a0;
  }
  let x1 = 0, x2 = 0, y1 = 0, y2 = 0;
  let pos = start, t = 0, relLevel = -1, relT = 0;
  const offAt = durSec, n0 = Math.round(startSec * SR);
  const maxN = Math.round((durSec + rel * 2 + 0.05) * SR);
  for (let i = 0; i < maxN; i++) {
    const idx = n0 + i;
    if (idx >= out.length) break;
    // Envelope level (linear) at time t
    let lev;
    if (t < dly) lev = 0;
    else if (t < dly + att) lev = (t - dly) / att;
    else if (t < dly + att + hold) lev = 1;
    else { const dt = t - dly - att - hold; const db = Math.max(-100 * dt / Math.max(dec, 0.001), susDb); lev = Math.pow(10, db / 20); }
    if (t >= offAt) {
      if (relLevel < 0) relLevel = lev;
      relT = t - offAt;
      lev = relLevel * Math.pow(10, (-100 * relT / rel) / 20);
      if (lev < 1e-4) break;
    }
    // Sample (linear interpolation)
    const ip = pos | 0, fr = pos - ip;
    if (ip + 1 >= end) break;
    let x = sf.smpl[ip] + (sf.smpl[ip + 1] - sf.smpl[ip]) * fr;
    if (useLp) { const y = b0 * x + b1 * x1 + b2 * x2 - a1 * y1 - a2 * y2; x2 = x1; x1 = x; y2 = y1; y1 = y; x = y; }
    out[idx] += x / 32768 * lev * amp;
    pos += step;
    if (loops && (mode === 1 || t < offAt) && pos >= le) pos -= (le - ls);
    t += 1 / SR;
  }
}

// One NOTE on a GM instrument (bank 0 program, or drums bank 128)
const voiceCache = new Map();
function note(sf, out, inst, key, vel, at, dur, gain = 1) {
  if (inst.layers) {                                           // A blended "instrument" (euphonium)
    for (const [name, sh, g] of inst.layers) note(sf, out, I[name], key + sh, vel, at, dur, gain * g);
    return;
  }
  key = Math.max(0, Math.min(127, Math.round(key)));
  vel = Math.max(1, Math.min(127, Math.round(vel)));
  const ck = inst.bank + ':' + inst.prog + ':' + key + ':' + (vel >> 4);
  let vs = voiceCache.get(ck);
  if (!vs) { vs = voicesFor(sf, inst.bank, inst.prog, key, vel); voiceCache.set(ck, vs); }
  const g = gain * (inst.gain || 1) / Math.max(1, vs.length * 0.75);
  for (const v of vs) renderVoice(sf, out, v, key, vel, at, dur, g);
}

// ============================================================
// REVERB (Freeverb, mono) - the big Souls cathedral
// ============================================================
function reverb(x, room = 0.86, damp = 0.35, wet = 0.32, dry = 0.85, predelay = 0.03) {
  const sc = SR / 44100;
  const combs = [1116, 1188, 1277, 1356, 1422, 1491, 1557, 1617].map((d) => ({ b: new Float32Array(Math.round(d * sc)), i: 0, f: 0 }));
  const aps = [556, 441, 341, 225].map((d) => ({ b: new Float32Array(Math.round(d * sc)), i: 0 }));
  const pd = Math.round(predelay * SR), out = new Float32Array(x.length);
  for (let n = 0; n < x.length; n++) {
    const inp = (n >= pd ? x[n - pd] : 0) * 0.015;
    let s = 0;
    for (const c of combs) {
      const y = c.b[c.i];
      c.f = y * (1 - damp) + c.f * damp;
      c.b[c.i] = inp + c.f * room;
      if (++c.i >= c.b.length) c.i = 0;
      s += y;
    }
    for (const a of aps) {
      const bo = a.b[a.i];
      a.b[a.i] = s + bo * 0.5;
      s = bo - s;
      if (++a.i >= a.b.length) a.i = 0;
    }
    out[n] = x[n] * dry + s * wet;
  }
  return out;
}

// ============================================================
// INSTRUMENTS (General MIDI programs in MuseScore_General)
// ============================================================
const I = {
  piano: { bank: 0, prog: 0, gain: 0.9 }, harpsichord: { bank: 0, prog: 6, gain: 0.55 }, celesta: { bank: 0, prog: 8, gain: 0.6 },
  bells: { bank: 0, prog: 14, gain: 0.5 }, organ: { bank: 0, prog: 19, gain: 0.42 }, guitar: { bank: 0, prog: 24, gain: 1.0 },
  violin: { bank: 0, prog: 40, gain: 0.9 }, viola: { bank: 0, prog: 41, gain: 0.8 }, cello: { bank: 0, prog: 42, gain: 0.9 },
  contrabass: { bank: 0, prog: 43, gain: 0.9 }, tremolo: { bank: 0, prog: 44, gain: 0.6 }, pizz: { bank: 0, prog: 45, gain: 0.9 },
  harp: { bank: 0, prog: 46, gain: 0.85 }, timpani: { bank: 0, prog: 47, gain: 1.0 }, strings: { bank: 0, prog: 48, gain: 0.55 },
  slowstrings: { bank: 0, prog: 49, gain: 0.6 }, choir: { bank: 0, prog: 52, gain: 0.5 }, oohs: { bank: 0, prog: 53, gain: 0.55 },
  trumpet: { bank: 0, prog: 56, gain: 0.6 }, trombone: { bank: 0, prog: 57, gain: 0.75 }, tuba: { bank: 0, prog: 58, gain: 0.7 },
  horn: { bank: 0, prog: 60, gain: 0.75 }, brass: { bank: 0, prog: 61, gain: 0.5 }, oboe: { bank: 0, prog: 68, gain: 0.6 },
  bassoon: { bank: 0, prog: 70, gain: 0.7 }, flute: { bank: 0, prog: 73, gain: 0.6 }, taiko: { bank: 0, prog: 116, gain: 0.9 },
  drums: { bank: 128, prog: 48, gain: 0.8 },                  // Orchestra kit
  // ----- The full orchestra (2026-11-13 revamp) -----
  piccolo: { bank: 0, prog: 72, gain: 0.45 }, clarinet: { bank: 0, prog: 71, gain: 0.6 },        // (E-flat / bass clarinet = clarinet high / low)
  englishhorn: { bank: 0, prog: 69, gain: 0.6 },
  crumhorn: { bank: 0, prog: 109, gain: 0.28 },               // No crumhorn recording: the bagpipe chanter (also a capped, buzzing reed)
  fiddle: { bank: 0, prog: 110, gain: 0.85 },                 // Folk fiddle (the "merchant" violin)
  mandolin: { bank: 16, prog: 25, gain: 0.7 }, xylophone: { bank: 0, prog: 13, gain: 0.55 },
  glock: { bank: 0, prog: 9, gain: 0.45 }, marimba: { bank: 0, prog: 12, gain: 0.6 },
  castanets: { bank: 8, prog: 115, gain: 0.6 },
  voice: { bank: 0, prog: 53, gain: 0.75 },                   // SOLO VOICE (a real "ooh" vocal): low = male, high = female
  // No euphonium recording: a trombone + French horn blend in the euphonium's tenor range
  euphonium: { layers: [['trombone', 0, 0.75], ['horn', 0, 0.5]] },
};
// Percussion keys in the (orchestra) drum kit
const BD = 35, SNARE = 38, CRASH = 57, CHINA = 59, TRI = 81, TAMB = 54;   // Orchestra kit: 35 bass drum, 38 snare, 57/59 concert cymbals

// A STRING SECTION playing a chord (tones = the chord, around octave 3): double basses on the
// root, celli on the root (solo cello + ensemble), violas on the middle, violins on top (solo
// violin + ensemble, an octave higher). mode: "slow" | "fast" | "trem".
const STRING_PADS = { strings: 'fast', slowstrings: 'slow', tremolo: 'trem' };
function sectionPad(sf, buf, tones, at, dur, vel, mode) {
  const ens = mode === 'trem' ? I.tremolo : (mode === 'fast' ? I.strings : I.slowstrings);
  const t = [...tones].sort((a, b) => a - b);
  note(sf, buf, I.contrabass, t[0] - 12, vel - 6, at, dur, 0.55);
  note(sf, buf, I.cello, t[0], vel, at, dur, 0.45);
  note(sf, buf, ens, t[0], vel, at, dur, 0.3);
  note(sf, buf, I.viola, t[1] + 12, vel - 4, at, dur, 0.4);
  note(sf, buf, I.violin, t[t.length - 1] + 12, vel, at, dur, 0.4);
  note(sf, buf, ens, t[0] + 24, vel, at, dur, 0.32);
  note(sf, buf, ens, t[1] + 24, vel - 6, at, dur, 0.25);
}

// ============================================================
// STYLES: how each track is arranged
//   pad: chord instruments, bass: bass instruments, lead: [first pass, second pass],
//   oct: lead octave shift, perc: "orch" | "soft" | "taiko" | "none", rev: reverb wet
// ============================================================
// dbl: [instrument, octave shift, gain, pass (-1 both / 0 / 1)] doubling the melody
// voice: [octave shift, gain] = a SOLO VOICE sings the long notes of the 2nd pass (low = male, high = female)
const BOSS = { pad: ['strings', 'choir'], bass: ['cello', 'contrabass'], lead: ['horn', 'trombone'], perc: 'orch', rev: 0.34,
  dbl: [['bassoon', -1, 0.35, 0], ['trumpet', 0, 0.3, 1]] };
const AREA = { pad: ['slowstrings'], bass: ['cello'], lead: ['piano', 'violin'], perc: 'soft', rev: 0.36, dbl: [['flute', 1, 0.3, 1]] };
const STYLES = {
  // ----- menus / Versus -----
  menu:  { ...AREA, lead: ['piano', 'violin'], pad: ['slowstrings', 'oohs'], dbl: [['clarinet', 0, 0.35, 0], ['flute', 1, 0.3, 1]], voice: [1, 0.35] },
  fight: { ...BOSS, lead: ['violin', 'trumpet'], pad: ['strings'], bass: ['cello', 'contrabass'], dbl: [['piccolo', 1, 0.25, 1], ['clarinet', 0, 0.3, 0]] },
  boss:  { ...BOSS, lead: ['trombone', 'horn'], dbl: [['euphonium', -1, 0.45, -1]] },
  // ----- Fights-mode bosses -----
  boss_minos: { ...BOSS, lead: ['horn', 'violin'], pad: ['strings', 'choir', 'organ'], voice: [-1, 0.35] },
  boss_sisyphus: { ...BOSS, lead: ['trombone', 'cello'], bass: ['contrabass', 'tuba'], dbl: [['euphonium', 0, 0.45, -1], ['bassoon', -1, 0.3, -1]] },
  boss_geyron: { ...BOSS, lead: ['trumpet', 'horn'], dbl: [['piccolo', 1, 0.2, -1], ['xylophone', 1, 0.3, 1]] },
  boss_titan: { ...BOSS, lead: ['trombone', 'tuba'], dbl: [['euphonium', 0, 0.5, -1]] },
  // ----- Story areas (Hollow Knight-like) -----
  story_surface: { ...AREA, lead: ['guitar', 'violin'], dbl: [['clarinet', 0, 0.3, 1]] },
  story_cave: { ...AREA, lead: ['harp', 'cello'], oct: -12, dbl: [['clarinet', 0, 0.3, 1]] },
  story_geode: { ...AREA, lead: ['celesta', 'harp'], pad: ['slowstrings', 'oohs'], dbl: [['glock', 1, 0.25, -1], ['flute', 1, 0.3, 1]], voice: [1, 0.3] },
  story_hive: { ...AREA, lead: ['pizz', 'bassoon'], pad: ['strings'], bass: ['pizz', 'contrabass'], perc: 'soft', dbl: [['marimba', 1, 0.35, -1], ['clarinet', 0, 0.3, 1]] },
  story_ascent: { ...AREA, lead: ['violin', 'horn'], pad: ['slowstrings', 'choir'], dbl: [['oboe', 0, 0.3, 0], ['euphonium', -1, 0.35, 1]], voice: [0, 0.3] },
  story_enlightened: { ...AREA, lead: ['harp', 'flute'], pad: ['choir', 'slowstrings'], perc: 'bells', dbl: [['glock', 1, 0.25, -1], ['oboe', 0, 0.25, 1]], voice: [1, 0.4] },
  story_sewers: { ...AREA, lead: ['piano', 'cello'], oct: -12, pad: ['slowstrings'], dbl: [['clarinet', -1, 0.35, -1]] },
  story_throne: { ...AREA, lead: ['organ', 'violin'], pad: ['strings', 'choir'], perc: 'orch', dbl: [['englishhorn', 0, 0.3, 1]], voice: [0, 0.35] },
  story_architectium: { ...AREA, lead: ['mandolin', 'fiddle'], pad: ['strings'], perc: 'soft', dbl: [['crumhorn', 0, 0.35, -1], ['guitar', -1, 0.4, -1]] },
  story_workshop: { ...AREA, lead: ['trombone', 'cello'], pad: ['strings'], bass: ['contrabass', 'tuba'], perc: 'orch', dbl: [['euphonium', 0, 0.4, -1], ['xylophone', 1, 0.25, 0]] },
  story_darkcave: { ...AREA, lead: ['piano', 'guitar'], oct: -12, dbl: [['clarinet', -1, 0.3, 1]] },
  story_void: { ...AREA, lead: ['oohs', 'cello'], pad: ['slowstrings', 'choir'], dbl: [['englishhorn', 0, 0.3, 1]], voice: [1, 0.35] },
  story_altar: { ...AREA, lead: ['harp', 'violin'], pad: ['choir', 'slowstrings'], perc: 'bells', dbl: [['flute', 1, 0.3, -1]], voice: [1, 0.45] },
  story_chase: { ...BOSS, lead: ['violin', 'trombone'], pad: ['strings'], perc: 'taiko', dbl: [['piccolo', 1, 0.22, -1], ['crumhorn', 0, 0.3, 0]] },
  // ----- Story bosses (Dark Souls III / Elden Ring) -----
  boss_architect: { ...BOSS, lead: ['trombone', 'horn'], pad: ['strings', 'choir', 'organ'], dbl: [['euphonium', 0, 0.4, -1]], voice: [-1, 0.4] },
  boss_caeser: { ...BOSS, lead: ['horn', 'trombone'], pad: ['strings', 'choir'], bass: ['contrabass', 'tuba'], voice: [-1, 0.45] },
  boss_golem: { ...BOSS, lead: ['trombone', 'horn'], pad: ['strings', 'organ'], dbl: [['euphonium', 0, 0.45, -1], ['tuba', -1, 0.3, 1]] },
  boss_needle: { ...BOSS, lead: ['violin', 'fiddle'], pad: ['strings'], bass: ['pizz', 'cello'], perc: 'bells', dbl: [['xylophone', 1, 0.3, -1], ['piccolo', 1, 0.2, 1]] },
  boss_massacre: { ...BOSS, lead: ['violin', 'horn'], pad: ['tremolo', 'choir'], dbl: [['clarinet', -1, 0.35, -1]], voice: [0, 0.4] },
  boss_brothers: { ...BOSS, lead: ['violin', 'cello'], pad: ['organ', 'strings'], perc: 'bells', dbl: [['oboe', 0, 0.3, 0], ['bassoon', -1, 0.35, 1]] },
  boss_animal: { ...BOSS, lead: ['horn', 'trombone'], pad: ['strings'], bass: ['contrabass', 'tuba'], perc: 'taiko', dbl: [['marimba', 1, 0.3, -1], ['crumhorn', 0, 0.3, 1]] },
  boss_executor: { ...BOSS, lead: ['trombone', 'tuba'], pad: ['organ', 'choir'], bass: ['contrabass', 'tuba'], dbl: [['euphonium', 0, 0.45, -1]], voice: [-1, 0.45] },
  boss_nature: { ...BOSS, lead: ['flute', 'violin'], pad: ['choir', 'slowstrings'], bass: ['cello', 'harp'], dbl: [['clarinet', 0, 0.3, 0], ['oboe', 0, 0.3, 1]], voice: [1, 0.45] },
  boss_falsegod: { ...BOSS, lead: ['violin', 'trumpet'], pad: ['organ', 'choir'], dbl: [['englishhorn', 0, 0.3, 0], ['xylophone', 1, 0.25, -1]] },
  boss_satan: { ...BOSS, lead: ['trombone', 'horn'], pad: ['choir', 'organ'], bass: ['contrabass', 'tuba'], dbl: [['euphonium', 0, 0.4, -1]], voice: [-1, 0.5] },
  boss_sun: { ...BOSS, lead: ['horn', 'violin'], pad: ['choir', 'strings'], bass: ['cello', 'harp'], perc: 'bells', dbl: [['flute', 1, 0.3, -1]], voice: [1, 0.5] },
  boss_consumer: { ...BOSS, lead: ['trumpet', 'trombone'], pad: ['tremolo', 'choir', 'organ'], dbl: [['euphonium', -1, 0.4, -1]], voice: [0, 0.45] },
  boss_grave: { ...BOSS, lead: ['cello', 'organ'], pad: ['organ', 'oohs'], dbl: [['clarinet', -1, 0.35, -1]], voice: [-1, 0.45] },
  boss_saint_golem: { ...BOSS, lead: ['horn', 'trumpet'], pad: ['organ', 'choir'], dbl: [['euphonium', -1, 0.4, -1]], voice: [1, 0.4] },
  boss_horrids: { ...BOSS, lead: ['violin', 'viola'], pad: ['tremolo'], dbl: [['englishhorn', 0, 0.3, -1]] },
  boss_reactor: { ...BOSS, lead: ['trombone', 'oohs'], pad: ['choir', 'tremolo'], dbl: [['euphonium', 0, 0.4, 0], ['xylophone', 1, 0.25, -1]] },
  boss_forge_father: { ...BOSS, lead: ['trombone', 'horn'], bass: ['contrabass', 'tuba'], dbl: [['euphonium', 0, 0.45, -1], ['xylophone', 1, 0.25, 1]] },
};
// ============================================================
// COMPOSITIONS: read the note data of every track from make_placeholder_audio.js
// ============================================================
function loadScores() {
  const src = fs.readFileSync(path.join(ROOT, 'tools', 'make_placeholder_audio.js'), 'utf8');
  const a = src.indexOf('const MUSIC = {'), b = src.indexOf('\n};', a);
  const body = src.slice(a + 'const MUSIC = '.length, b + 2);
  const rec = (type) => (...args) => ({ type, args });
  const fn = new Function('epic', 'song', 'violinBoss', 'gongRitual', 'chaosBoss', 'organ', 'saw', 'tri', 'sq', 'Math',
    'return ' + body + ';');
  const music = fn(rec('epic'), rec('song'), rec('violinBoss'), rec('gongRitual'), rec('chaosBoss'), 'organ', 'saw', 'tri', 'sq', Math);
  const out = {};
  for (const k in music) out[k] = music[k]();
  return out;
}

// ============================================================
// ARRANGING + RENDERING one track
// ============================================================
function render(sf, name, score) {
  const st = STYLES[name] || (name.startsWith('boss') ? BOSS : AREA);
  const t = score.type, A = score.args;
  let bpm, bars, chords = null, bass = [], lead = [], drums = [], stepDiv = 2;
  if (t === 'epic') [bpm, bars, chords, bass, lead, drums] = A;
  else if (t === 'song') { [bpm, bars, bass, lead, drums] = A; chords = null; }
  else if (t === 'violinBoss') { [bpm, bars, chords, bass, lead] = A; stepDiv = 4; }
  else if (t === 'gongRitual') { [bpm, bars, chords, lead] = A; bass = [38]; }
  else if (t === 'chaosBoss') { [bpm, bars] = A; }
  const beat = 60 / bpm, barLen = beat * 4, step = beat / stepDiv;
  const loopLen = bars * barLen, passes = 2, total = loopLen * passes;
  // Render 1 extra pass in front: the reverb / release tails of the loop wrap into the start
  const pre = loopLen;
  const buf = new Float32Array(Math.ceil((pre + total + 4) * SR));
  const rnd = (() => { let s = 7 + name.length; return () => ((s = (s * 1103515245 + 12345) & 0x7fffffff) / 0x7fffffff); })();
  const human = () => (rnd() - 0.5) * 0.016;

  for (let pass = -1; pass < passes; pass++) {
    const t0 = pre + pass * loopLen;
    const lp = pass < 0 ? passes - 1 : pass;                 // The extra front pass copies the last pass
    if (t === 'chaosBoss') { chaos(sf, buf, t0, bpm, bars); continue; }
    if (t === 'gongRitual') { ritual(sf, buf, t0, bpm, bars, chords, lead, lp); continue; }
    // --- Chords: sustained, one per bar ---
    if (chords) {
      for (let bar = 0; bar < bars; bar++) {
        const ch = chords[bar % chords.length];
        for (const inst of st.pad) {
          if (STRING_PADS[inst]) {                               // A real string SECTION, voiced by range
            sectionPad(sf, buf, ch, t0 + bar * barLen + human(), barLen * 1.02, 70 + 10 * (bar % 2), STRING_PADS[inst]);
            continue;
          }
          const sh = inst === 'choir' || inst === 'oohs' ? 0 : (inst === 'organ' ? -12 : 0);
          for (const n of ch) note(sf, buf, I[inst], n + 12 + sh, 70 + 10 * (bar % 2), t0 + bar * barLen + human(), barLen * 1.02, 0.55);
        }
      }
    } else if (st.pad.length) {
      // Area tracks without chords: a soft drone on the bass notes
      for (let bar = 0; bar < bars; bar++) {
        const bn = bass[(bar * 8) % bass.length] || bass.find((x) => x) || 45;
        for (const inst of st.pad) for (const iv of [12, 19, 24]) note(sf, buf, I[inst], bn + iv, 58, t0 + bar * barLen, barLen * 1.02, 0.45);
      }
    }
    // --- Bass line ---
    const bsteps = Math.round(loopLen / step);
    for (let s = 0; s < bsteps; s++) {
      const bn = bass[(stepDiv === 4 ? (s >> 1) : s) % bass.length];
      if (!bn || (stepDiv === 4 && s % 2)) continue;
      let d = 1; while (d < 4 && !bass[(s + d) % bass.length]) d++;
      st.bass.forEach((inst, k) => {
        const key = bn + 12 - (k > 0 ? 12 : 0) + (inst === 'harp' ? 12 : 0);
        note(sf, buf, I[inst], key, 78 + (s % 4 === 0 ? 14 : 0), t0 + s * step + human(), step * d * 0.95, k > 0 ? 0.7 : 1);
      });
    }
    // --- Melody: pass 1 / pass 2 on two different instruments ---
    const lead_i = st.lead[Math.min(lp, st.lead.length - 1)];
    const lsteps = Math.round(loopLen / step);
    const oct = (st.oct || 0) + (lead_i === 'cello' || lead_i === 'trombone' || lead_i === 'bassoon' || lead_i === 'tuba' ? -12 : 0);
    for (let s = 0; s < lsteps; s++) {
      const ln = lead[s % lead.length];
      if (!ln) continue;
      let d = 1; while (d < 6 && !lead[(s + d) % lead.length] && (s + d) % lead.length !== 0) d++;
      const plucked = ['piano', 'harp', 'guitar', 'harpsichord', 'celesta', 'pizz', 'mandolin', 'xylophone', 'marimba', 'glock'].includes(lead_i);
      note(sf, buf, I[lead_i], ln + oct, 88 + (s % 8 === 0 ? 14 : 0) + Math.round(rnd() * 8), t0 + s * step + human(), step * d * (plucked ? 1.6 : 1.0), 1.0);
      if (lp === 1 && st.pad.includes('choir') && s % 4 === 0) note(sf, buf, I.choir, ln + oct, 60, t0 + s * step, step * d, 0.3);   // Choir doubles the 2nd pass
      // DOUBLINGS (woodwinds / brass colour the melody): [instrument, octave shift, gain, pass (-1 = both)]
      for (const [di, dsh, dg, dp] of (st.dbl || [])) {
        if (dp === undefined || dp < 0 || dp === lp)
          note(sf, buf, I[di], ln + oct + 12 * dsh, 76, t0 + s * step + human(), step * d, dg);
      }
      // SOLO VOICE on the long notes of the 2nd pass: [octave shift, gain] (low = male, high = female)
      if (st.voice && lp === 1 && d >= 2)
        note(sf, buf, I.voice, ln + oct + 12 * st.voice[0], 80, t0 + s * step, step * d * 1.1, st.voice[1]);
    }
    // --- Percussion ---
    percussion(sf, buf, t0, st.perc, drums, step, Math.round(loopLen / step), bars, barLen, lp);
  }
  // Reverb, then cut out the looped part (after the extra front pass)
  const wet = reverb(buf, 0.86, 0.32, st.rev || 0.32, 0.85);
  const a = Math.round(pre * SR), out = wet.subarray(a, a + Math.round(total * SR));
  // (The extra front pass already put the loop's reverb / release tails into its start: seamless loop)
  return out;
}

function percussion(sf, buf, t0, kind, drums, step, steps, bars, barLen, lp) {
  if (kind === 'none') return;
  for (let s = 0; s < steps; s++) {
    const d = drums.length ? drums[s % drums.length] : 0;
    const at = t0 + s * step;
    if (kind === 'soft') {                                       // Hollow Knight: almost no drums
      if (s % 16 === 0) note(sf, buf, I.timpani, 38, 52, at, 1.5, 0.6);
      continue;
    }
    if (kind === 'bells') {
      if (d === 'b' || s % 16 === 0) note(sf, buf, I.bells, 72, 70, at, 2.0, 0.6);
      if (d === 'T' || d === 't') note(sf, buf, I.timpani, 41, 70, at, 1.0, 0.7);
      continue;
    }
    if (kind === 'taiko') {
      if (d === 'T' || d === 't') note(sf, buf, I.taiko, 45, d === 'T' ? 120 : 92, at, 0.8, 1.0);
      if (d === 's') note(sf, buf, I.drums, SNARE, 70, at, 0.3, 0.5);
      continue;
    }
    // orchestra: timpani on the heavy hits, bass drum, cymbal crashes, snare
    if (d === 'T') { note(sf, buf, I.timpani, 38, 118, at, 1.2, 1.0); note(sf, buf, I.drums, BD, 110, at, 1.0, 0.8); }
    if (d === 't') note(sf, buf, I.timpani, 43, 96, at, 0.8, 0.9);
    if (d === 'k') note(sf, buf, I.drums, BD, 95, at, 0.6, 0.7);
    if (d === 's') note(sf, buf, I.drums, SNARE, 78, at, 0.4, 0.55);
    if (d === 'c') { note(sf, buf, I.pizz, 55, 90, at, 0.3, 0.6); note(sf, buf, I.xylophone, 79, 80, at, 0.3, 0.5); }   // Metal clank: pizz + xylophone
    if (d === 'b') { note(sf, buf, I.bells, 76, 80, at, 2.5, 0.6); note(sf, buf, I.glock, 88, 60, at, 1.0, 0.35); }
    if (s % 32 === 31) for (let r = 0; r < 4; r++) note(sf, buf, I.drums, SNARE, 60 + r * 10, at + r * step / 4, 0.1, 0.35);   // Snare roll into the crash
    if (s % 32 === 0) { note(sf, buf, I.drums, CRASH, lp === 1 ? 100 : 82, at, 3.0, 0.5); note(sf, buf, I.drums, BD, 100, at, 1.0, 0.6); }
    if (lp === 1 && s % 8 === 4) note(sf, buf, I.drums, TRI, 50, at, 0.6, 0.3);              // Triangle shimmer on the 2nd pass
  }
}

// THE ENLIGHTENED FIRST PRIME: gong ritual + choir (low tubular bells + cymbals + timpani for the gong)
function ritual(sf, buf, t0, bpm, bars, chords, chant, lp) {
  const beat = 60 / bpm, barLen = beat * 4, step = beat / 2;
  for (let bar = 0; bar < bars; bar++) {
    const at = t0 + bar * barLen;
    note(sf, buf, I.drums, CHINA, 115, at, 4.0, 0.7);             // The great gong (cymbal + timpani + low bell)
    note(sf, buf, I.timpani, 33, 120, at, 3.0, 1.0);
    note(sf, buf, I.bells, 48, 100, at, 4.0, 0.7);
    note(sf, buf, I.bells, 60 + (bar % 2) * 3, 70, at + beat * 2.5, 2.5, 0.5);   // Small gong answers
    for (const n of chords[bar % chords.length]) { note(sf, buf, I.choir, n + 12, 78, at, barLen * 1.02, 0.5); note(sf, buf, I.slowstrings, n, 60, at, barLen * 1.02, 0.4); }
    note(sf, buf, I.contrabass, 38, 80, at, barLen, 0.8);
    note(sf, buf, I.euphonium, 50, 70, at, barLen, 0.35);                  // Euphonium drone under the chant
    note(sf, buf, I.organ, 26, 60, at, barLen, 0.5);
  }
  const steps = bars * 8;
  for (let s = 0; s < steps; s++) {
    const at = t0 + s * step;
    if (s % 8 === 0 || s % 8 === 3 || s % 8 === 6) note(sf, buf, I.taiko, 43, s % 8 === 0 ? 118 : 90, at, 0.8, 0.9);
    const c = chant[s % chant.length];
    if (c) { let d = 1; while (d < 4 && !chant[(s + d) % chant.length]) d++; note(sf, buf, lp === 0 ? I.oohs : I.choir, c, 90, at, step * d, 0.9); if (lp === 1) note(sf, buf, I.cello, c - 12, 80, at, step * d, 0.6); note(sf, buf, I.voice, c - 12, 84, at, step * d, 0.45); }   // + a MALE solo voice
  }
}

// THE ENLIGHTENED ONE: chaos - every instrument, the key lurching every bar
function chaos(sf, buf, t0, bpm, bars) {
  const beat = 60 / bpm, barLen = beat * 4, step = beat / 4;
  const keys = [0, 1, 6, 3, 0, 5, 1, 6];
  for (let bar = 0; bar < bars; bar++) {
    const k = keys[bar % keys.length], at = t0 + bar * barLen;
    for (const n of [50, 53, 56, 59]) note(sf, buf, I.organ, n + k, 80, at, barLen, 0.6);
    for (const n of [62, 65]) note(sf, buf, I.choir, n + k, 75, at, barLen, 0.5);
    note(sf, buf, I.drums, CHINA, 105, at, 3.0, 0.6);
    note(sf, buf, I.bells, 84 + k, 85, at + beat * 2, 2.0, 0.5);
    for (let j = 0; j < 4; j++) note(sf, buf, I.brass, 62 + k + j * 3, 105, at + j * beat + beat * 0.5, beat * 0.4, 0.8);
    note(sf, buf, I.tuba, 38 + k, 100, at, beat * 2, 0.8);
  }
  for (let s = 0; s < bars * 16; s++) {
    const bar = Math.floor(s / 16), k = keys[bar % keys.length], at = t0 + s * step;
    const run = [74, 75, 77, 79, 80, 79, 77, 75, 74, 71, 72, 74, 75, 77, 78, 80][s % 16] + k;
    if (s % 2 === 0) note(sf, buf, I.violin, run, 95, at, step * 1.9, 0.9);
    if (s % 3 === 0) note(sf, buf, I.harpsichord, 86 - (s % 7) + k, 85, at, step, 0.6);
    if (s % 2 === 0) note(sf, buf, I.piccolo, [74, 75, 77, 79, 80, 79, 77, 75][(s / 2) % 8] + 12 + k, 80, at, step * 1.9, 0.18);   // Piccolo over the violins
    if (s % 4 === 1) note(sf, buf, I.xylophone, 79 + (s % 5) + k, 85, at, step, 0.3);
    if (s % 16 === 8) note(sf, buf, I.crumhorn, 62 + k, 95, at, step * 4, 0.35);                  // A mad crumhorn blast
    if (s % 4 === 0) note(sf, buf, I.timpani, 38 + (s % 8 === 0 ? 0 : 5), 110, at, 0.6, 0.9);
    if (s % 16 === 6 || s % 16 === 11 || s % 16 === 14) note(sf, buf, I.taiko, 45, 100, at, 0.5, 0.8);
    if (s % 4 === 2) note(sf, buf, I.drums, SNARE, 85, at, 0.3, 0.5);
    if (s % 8 === 0) note(sf, buf, I.cello, 38 + k, 100, at, step * 3, 0.9);
  }
}

// ============================================================
// WAV OUT
// ============================================================
function writeWav(file, b) {
  // Same loudness for every track (RMS), peaks softly limited
  let peak = 0, e = 0; for (const v of b) { peak = Math.max(peak, Math.abs(v)); e += v * v; }
  const rms = Math.sqrt(e / Math.max(1, b.length));
  const g = rms > 0 ? Math.min(0.17 / rms, 1.5 / peak) : 1;
  const data = Buffer.alloc(b.length * 2);
  for (let i = 0; i < b.length; i++) {
    let v = b[i] * g;
    if (Math.abs(v) > 0.75) v = Math.sign(v) * (0.75 + 0.22 * Math.tanh((Math.abs(v) - 0.75) / 0.22));   // Soft limiter (max 0.97)
    data.writeInt16LE(Math.max(-32767, Math.min(32767, Math.round(v * 32767))), i * 2);
  }
  const h = Buffer.alloc(44);
  h.write('RIFF', 0); h.writeUInt32LE(36 + data.length, 4); h.write('WAVE', 8); h.write('fmt ', 12);
  h.writeUInt32LE(16, 16); h.writeUInt16LE(1, 20); h.writeUInt16LE(1, 22); h.writeUInt32LE(SR, 24);
  h.writeUInt32LE(SR * 2, 28); h.writeUInt16LE(2, 32); h.writeUInt16LE(16, 34); h.write('data', 36); h.writeUInt32LE(data.length, 40);
  fs.writeFileSync(file, Buffer.concat([h, data]));
}

// ============================================================
if (!fs.existsSync(SF2)) { console.error('SoundFont not found: ' + SF2 + '\nDownload MuseScore_General.sf2 (see the top of this file).'); process.exit(1); }
console.log('loading ' + SF2 + ' ...');
const sf = readSF2(SF2);
console.log('presets: ' + sf.phdr_.length + ', samples: ' + sf.shdr_.length);
if (process.argv.includes('--check')) {                // List which recording every instrument uses
  for (const k in I) {
    const i = I[k], key = k === 'drums' ? CRASH : (k === 'contrabass' || k === 'tuba' ? 40 : 62);
    const p = sf.phdr_.find((x) => x.bank === i.bank && x.preset === i.prog);
    const v = voicesFor(sf, i.bank, i.prog, key, 100);
    console.log(k.padEnd(12), (p ? p.name : 'MISSING').padEnd(24), 'voices ' + v.length, v.map((x) => x.s.name).slice(0, 2).join(', '));
  }
  for (const [b, pr] of [[0, 85], [0, 53], [0, 54], [0, 52], [0, 109], [0, 110], [16, 25], [0, 13], [0, 71], [0, 72], [20, 49], [40, 49], [50, 49], [8, 115]]) {
    const lo = voicesFor(sf, b, pr, 48, 100).map((x) => x.s.name), hi = voicesFor(sf, b, pr, 76, 100).map((x) => x.s.name);
    console.log(`  preset ${b}:${pr}  low: ${lo.slice(0, 2).join(', ')}   high: ${hi.slice(0, 2).join(', ')}`);
  }
  for (let key = 27; key <= 82; key++) {
    const v = voicesFor(sf, 128, I.drums.prog, key, 100);
    if (v.length) console.log('  kit key ' + key + ': ' + v.map((x) => x.s.name).slice(0, 2).join(', '));
  }
  process.exit(0);
}
// NEW COMPOSITIONS (tools/music_pieces.js): rendered twice back to back, the second copy is
// kept, so the first copy's reverb / release tails flow into its start (seamless loop).
const { PIECES, build } = require('./music_pieces.js');
const DRUMS = new Set(['drums']);
function renderPiece(p) {
  const { notes, beats } = build(p);
  const spb = 60 / p.bpm, L = beats * spb;
  const buf = new Float32Array(Math.ceil((L * 2 + 4) * SR));
  let s = 11;
  const rnd = () => ((s = (s * 1103515245 + 12345) & 0x7fffffff) / 0x7fffffff);
  for (let copy = 0; copy < 2; copy++) {
    for (const n of notes) {
      const at = copy * L + n.at * spb + (DRUMS.has(n.inst) ? 0 : (rnd() - 0.5) * 0.014);
      note(sf, buf, I[n.inst], n.key, n.vel + Math.round((rnd() - 0.5) * 8), Math.max(0, at), n.dur * spb, n.g || 1.0);
    }
  }
  const wet = reverb(buf, 0.88, 0.3, p.rev || 0.34, 0.85);
  const a = Math.round(L * SR);
  return wet.slice(a, a + Math.round(L * SR));
}

const scores = loadScores();
const only = process.argv.slice(2).filter((x) => !x.startsWith('--'));
const names = [...new Set([...Object.keys(scores), ...Object.keys(PIECES)])];   // Tracks that exist ONLY as new pieces too
for (const name of names) {
  if (only.length && !only.includes(name)) continue;
  const t = Date.now();
  const out = PIECES[name] ? renderPiece(PIECES[name]) : render(sf, name, scores[name]);
  writeWav(path.join(ROOT, 'audio', 'music', name + '.wav'), out);
  console.log(`${name}: ${(out.length / SR).toFixed(1)} s  (${((Date.now() - t) / 1000).toFixed(1)} s)`);
}
