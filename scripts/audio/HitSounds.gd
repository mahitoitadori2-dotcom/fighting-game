class_name HitSounds
extends RefCounted
## WHO HIT WHOM, BY EAR: every attacker has its own impact sound (Kenney CC0 samples, several
## variants each so repeated hits don't sound copy-pasted), and the kind of hit changes it:
##   Warrior: void thuds, sword slices     Architect: metal knocks     Anti Architect: energy clangs
##   Nightmare Lord: heavy fire punches    Enlightened One: bells      Mimic: bone/wood cracks
##   Technician: tin + wrench              enemies / bosses / the Dummy: fist impacts
##   projectiles: light snaps   grabs: cloth   heavy / ultimate hits: an extra plate crash
##   blocks: plate clinks   perfect blocks: a bright glass clang on top

const VARIANTS := {"imp_metal": 3, "imp_void": 3, "imp_sword": 2, "imp_fire": 3, "imp_holy": 2, "imp_bone": 3,
	"imp_energy": 2, "imp_wrench": 3, "imp_punch": 3, "imp_heavy": 2, "imp_grab": 2, "imp_proj": 3, "blk": 3, "blk_perfect": 1}

## Attacker class -> impact family
const FAMILY := {"Warrior": "imp_void", "Player": "imp_metal", "AntiArchitect": "imp_energy", "AlphaArchitect": "imp_energy",
	"FireLord": "imp_fire", "EnlightenedOne": "imp_holy", "Mimic": "imp_bone", "Technician": "imp_wrench"}

const SWORD_MOVES := ["sword", "slash", "shred"]


static func play(hit: HitData, strength: int) -> void:
	var fam := "imp_punch"
	if hit != null and hit.source != null and is_instance_valid(hit.source) and hit.source.get_script() != null:
		fam = String(FAMILY.get(String(hit.source.get_script().get_global_name()), "imp_punch"))
	if hit != null:
		if hit.is_grab or hit.hit_type == "grab":
			fam = "imp_grab"
		elif hit.hit_type == "projectile":
			fam = "imp_proj" if fam in ["imp_punch", "imp_metal"] else fam
		elif hit.hit_type == "sword" or hit.move in SWORD_MOVES:
			fam = "imp_sword"
	var vol: float = [-10.0, -3.0, 0.0, 0.0][clampi(strength, 0, 3)]
	_variant(fam, vol)
	if strength >= 2:
		_variant("imp_heavy", -5.0)                    # Heavy / ultimate: a crash on top
	if strength >= 1:
		SoundManager.play_sfx("hit", -9.0)             # The old punchy body under it


static func play_block(perfect: bool) -> void:
	_variant("blk", -2.0)
	if perfect:
		_variant("blk_perfect", -3.0)
		SoundManager.play_sfx("block", -6.0)


static func _variant(fam: String, vol: float) -> void:
	var n := int(VARIANTS.get(fam, 1))
	SoundManager.play_sfx("%s_%d" % [fam, randi() % n + 1], vol, 0.08)
