class_name HitData
extends RefCounted
## Everything CombatManager needs to resolve one hit.
## move / part are the DAMAGE SOURCE used by DeathManager to pick the death animation.

var source: Fighter                    # null = debug / environment
var damage := 0
var knockback := Vector2.ZERO          # FINAL vector, already directional
var origin := Vector2.ZERO             # World position the attack comes from (block direction)
var blockable := true
var hit_type := "melee"                # melee / sword / projectile / trap / drill / drill_tick / goo / grab / spike / beam / sim / self
var onslaught := false
var causes_hitstun := true
var is_grab := false
var gauge_gain := true
var move := ""                         # Which move: punch, rocket, hnct, drill, void_goo, triple_rocket, faoth, sword, grab, eternal, mini_eternal, shadow_swarm...
var part := ""                         # Sub-part of a combo ultimate (FAOTH: rocket / goo / hnct / arms)
## Damage type: "normal", "explosion" or "void". Leave "" to auto-detect from move/part.
## Characters can be weak to a type (CharacterData.damage_kind_taken).
var damage_kind := ""
## Damage-over-time tick (goo, burning oil, drill): only small sparks, no hitstop / shake.
var is_tick := false

const KIND_NORMAL := "normal"
const KIND_EXPLOSION := "explosion"
const KIND_VOID := "void"


## The damage type of this hit. Explicit damage_kind wins, otherwise detected from the move.
func get_kind() -> String:
	if damage_kind != "":
		return damage_kind
	if onslaught:
		return KIND_EXPLOSION                       # Every Onslaught version explodes
	match move:
		"rocket", "triple_rocket", "hnct", "throne":
			return KIND_EXPLOSION
		"void_goo", "shadow_swarm", "eternal", "mini_eternal", "grab":
			return KIND_VOID
		"faoth":
			match part:
				"rocket", "hnct":
					return KIND_EXPLOSION
				"goo":
					return KIND_VOID
	return KIND_NORMAL
