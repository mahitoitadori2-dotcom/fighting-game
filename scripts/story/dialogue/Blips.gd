class_name Blips
extends RefCounted
## DIALOGUE VOICE BLIPS (Undertale / Deltarune style): every character "talks" with its own tiny
## blip sound while its text types out. The blips are made here in code (no sound files): a short
## tone with its own pitch, wave, brightness, growl and pitch-glide per character.
##
##   Blips.stream("satan")  -> AudioStreamWAV (cached)
##
## PROFILE: f = base pitch (Hz)   wave = "pulse" | "saw" | "tri" | "sine" | "square"
##          dur = seconds   soft = 0..1 (darker = more filtered)   noise = 0..1 (growl / rasp)
##          glide = pitch change over the blip (0.08 = rises 8%: proud / bright)
##          sub = 0..1 (adds the octave below: weight)   vib = pitch wobble 0..1

const RATE := 22050

const PROFILES := {
	# ----- Heroes -----
	"architect": {"f": 150.0, "wave": "pulse", "dur": 0.055, "soft": 0.45, "noise": 0.0, "glide": -0.02, "sub": 0.15},   # Human, regular, a bit deep
	"warrior": {"f": 92.0, "wave": "saw", "dur": 0.07, "soft": 0.75, "noise": 0.06, "glide": -0.04, "sub": 0.45},        # Dark and deep
	"enlightened": {"f": 330.0, "wave": "tri", "dur": 0.06, "soft": 0.2, "noise": 0.0, "glide": 0.09, "sub": 0.0, "vib": 0.4},   # Feminine, proud
	"stranger": {"f": 118.0, "wave": "tri", "dur": 0.075, "soft": 0.55, "noise": 0.12, "glide": 0.10, "sub": 0.3, "vib": 1.0},   # Hollow, wavering, old
	"narrator": {"f": 210.0, "wave": "sine", "dur": 0.04, "soft": 0.3, "noise": 0.0, "glide": 0.0, "sub": 0.0},
	# ----- Story bosses -----
	"blinded_lord": {"f": 175.0, "wave": "saw", "dur": 0.06, "soft": 0.5, "noise": 0.25, "glide": 0.05, "sub": 0.0, "vib": 0.6},     # Raspy, unhinged
	"architect_chorus": {"f": 110.0, "wave": "square", "dur": 0.09, "soft": 0.6, "noise": 0.0, "glide": 0.0, "sub": 0.6},         # Many metal voices
	"blasphemy_caeser": {"f": 85.0, "wave": "saw", "dur": 0.08, "soft": 0.7, "noise": 0.35, "glide": -0.06, "sub": 0.5},          # A hissing serpent god
	"atomic": {"f": 240.0, "wave": "square", "dur": 0.05, "soft": 0.2, "noise": 0.4, "glide": 0.0, "sub": 0.0, "vib": 0.9},        # Crackling, unstable
	"forge_mother": {"f": 130.0, "wave": "square", "dur": 0.07, "soft": 0.5, "noise": 0.15, "glide": -0.03, "sub": 0.3},          # Clanking iron
	"arch_golem": {"f": 70.0, "wave": "square", "dur": 0.1, "soft": 0.8, "noise": 0.05, "glide": 0.0, "sub": 0.7},               # Stone, very low
	"escapist": {"f": 420.0, "wave": "tri", "dur": 0.035, "soft": 0.2, "noise": 0.05, "glide": 0.12, "sub": 0.0},                # Quick, giggly
	"masker": {"f": 160.0, "wave": "sine", "dur": 0.08, "soft": 0.5, "noise": 0.0, "glide": -0.08, "sub": 0.2, "vib": 0.3},       # Hollow
	"shining": {"f": 520.0, "wave": "sine", "dur": 0.09, "soft": 0.1, "noise": 0.0, "glide": 0.02, "sub": 0.0},                  # A bell
	"void_massacre": {"f": 300.0, "wave": "pulse", "dur": 0.025, "soft": 0.3, "noise": 0.5, "glide": 0.0, "sub": 0.0},          # Clicking legs
	"needle": {"f": 460.0, "wave": "tri", "dur": 0.045, "soft": 0.15, "noise": 0.0, "glide": 0.15, "sub": 0.0},                  # A child, squeaky
	"brothers": {"f": 140.0, "wave": "pulse", "dur": 0.06, "soft": 0.4, "noise": 0.0, "glide": 0.0, "sub": 0.0, "duet": 1.5},     # Two voices at once
	"animal_lord": {"f": 80.0, "wave": "saw", "dur": 0.08, "soft": 0.6, "noise": 0.5, "glide": -0.05, "sub": 0.5},               # A growl of a dozen beasts
	"executor": {"f": 62.0, "wave": "saw", "dur": 0.1, "soft": 0.85, "noise": 0.1, "glide": -0.04, "sub": 0.7},                  # Slow, crushing
	"mother_nature": {"f": 260.0, "wave": "sine", "dur": 0.07, "soft": 0.3, "noise": 0.0, "glide": 0.03, "sub": 0.1, "vib": 0.5},  # Warm
	"false_god": {"f": 120.0, "wave": "saw", "dur": 0.06, "soft": 0.4, "noise": 0.45, "glide": 0.06, "sub": 0.3},                # Crackling fire
	"satan": {"f": 58.0, "wave": "saw", "dur": 0.09, "soft": 0.7, "noise": 0.3, "glide": -0.05, "sub": 0.8},                     # A deep growl
	"the_sun": {"f": 560.0, "wave": "sine", "dur": 0.08, "soft": 0.05, "noise": 0.0, "glide": 0.04, "sub": 0.0, "duet": 2.0},      # Bright, bell-like
	"first_prime": {"f": 125.0, "wave": "pulse", "dur": 0.08, "soft": 0.4, "noise": 0.0, "glide": 0.0, "sub": 0.4, "duet": 1.5},  # A gong in the voice
}

static var _cache := {}


static func stream(id: String) -> AudioStreamWAV:
	if not PROFILES.has(id):
		id = "narrator"
	if _cache.has(id):
		return _cache[id]
	var p: Dictionary = PROFILES[id]
	var f0: float = p.get("f", 200.0)
	var dur: float = p.get("dur", 0.06)
	var soft: float = p.get("soft", 0.3)
	var noise: float = p.get("noise", 0.0)
	var glide: float = p.get("glide", 0.0)
	var sub: float = p.get("sub", 0.0)
	var vib: float = p.get("vib", 0.0)
	var duet: float = p.get("duet", 0.0)
	var wave := String(p.get("wave", "sine"))
	var n := int(dur * RATE)
	var data := PackedByteArray()
	data.resize(n * 2)
	var ph := 0.0
	var ph2 := 0.0
	var ph3 := 0.0
	var lp := 0.0
	var rng := RandomNumberGenerator.new()
	rng.seed = id.hash()
	for i in n:
		var t := float(i) / float(RATE)
		var k := float(i) / float(n)
		var f := f0 * (1.0 + glide * k) * (1.0 + vib * 0.03 * sin(t * 60.0))
		ph = fmod(ph + f / RATE, 1.0)
		ph2 = fmod(ph2 + f * 0.5 / RATE, 1.0)
		ph3 = fmod(ph3 + f * maxf(duet, 1.0) / RATE, 1.0)
		var s := _wave(wave, ph)
		s += sub * _wave("sine", ph2)
		if duet > 0.0:
			s = s * 0.6 + 0.5 * _wave(wave, ph3)
		s += noise * (rng.randf() * 2.0 - 1.0)
		lp += (s - lp) * (1.0 - soft * 0.9)                   # Darker = smoother
		var env := minf(t / 0.004, 1.0) * pow(1.0 - k, 1.6)       # Quick attack, falling tail
		var v := clampi(int(lp * env * 0.55 * 32767.0), -32767, 32767)
		data.encode_s16(i * 2, v)
	var w := AudioStreamWAV.new()
	w.format = AudioStreamWAV.FORMAT_16_BITS
	w.mix_rate = RATE
	w.stereo = false
	w.data = data
	_cache[id] = w
	return w


static func _wave(kind: String, ph: float) -> float:
	match kind:
		"saw":
			return ph * 2.0 - 1.0
		"square":
			return 1.0 if ph < 0.5 else -1.0
		"pulse":
			return 1.0 if ph < 0.25 else -0.35
		"tri":
			return 4.0 * absf(ph - 0.5) - 1.0
	return sin(ph * TAU)
