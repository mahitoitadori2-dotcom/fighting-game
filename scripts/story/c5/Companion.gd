class_name Companion
extends RefCounted
## CPU PARTNER (Story Mode, Colosseum 5). You pick the Warrior or the Architect; the other
## one fights beside you, played by its normal MEDIUM CPU brain (WarriorAI / ArchitectAI)
## with this follow layer on top:
##   * it only fights enemies that are close to YOU (it never runs off across the arena)
##   * too far from you, or nothing to fight: it runs back to you (and jumps up after you)
##   * it never dies for good: StoryManager revives it beside you after REVIVE_TIME seconds
## Partner CPUs never use ultimates (no G Gauge), so no Time Stop freezes you.

const FOLLOW_FAR := 380.0          # Further than this from you: comes back
const FOLLOW_NEAR := 110.0         # Close enough: stops following
const ENGAGE := 640.0              # Only fights enemies within this distance of YOU
const REVIVE_TIME := 4.0

## The human player the partner follows (set by StoryManager).
static var leader: Fighter = null


## Called after the normal CPU brain decided its buttons this frame: overrides the
## movement when the partner should come back to you.
static func steer(ai: BaseAI) -> void:
	var f := ai.f
	if f == null or f.is_dead or f.grabbed_by != null:
		return
	if leader == null or not is_instance_valid(leader) or leader.is_dead:
		return
	var to_leader := leader.global_position.x - f.global_position.x
	var enemy := ai.enemy
	var enemy_near := enemy != null and not enemy.is_dead \
		and absf(enemy.global_position.x - leader.global_position.x) < ENGAGE
	if absf(to_leader) <= FOLLOW_FAR and enemy_near:
		return                                         # Fighting near you: let the CPU brain work
	if absf(to_leader) > FOLLOW_NEAR:
		ai._cur.erase("left")
		ai._cur.erase("right")
		ai._cur.erase("block")
		ai._cur["right" if to_leader > 0.0 else "left"] = true
	if leader.global_position.y < f.global_position.y - 90.0 and f.is_on_floor():
		ai._cur["jump"] = not ai._prev.get("jump", false)   # Tap (a held key would not jump again)
