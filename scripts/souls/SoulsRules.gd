class_name SoulsRules
## SOULS RULES - ONLY in the open-world parts of Story Mode (a level with "open_world": true).
## Everywhere else (Versus, normal Story levels) nothing changes: you still BLOCK.
##
##   DODGE ROLL replaces block: the block button (F / RB / LT / BLK) rolls toward the direction you
##     hold, with I-FRAMES (attacks pass through you). No direction = a short BACKSTEP.
##   STAMINA: rolling, attacking, moves and jumping cost stamina. It refills after a short pause.
##     At 0 you are EXHAUSTED: no rolls or attacks until it has refilled a bit (watch the bar).
##   Flasks (R) are your Estus, as before.
## Numbers below. Every hero uses the same values.

static var active := false
## TESTING ONLY: turns the Souls rules on in every Story level.
static var test_force := false

const MAX_STAMINA := 100.0
const REGEN := 42.0                 # Per second
const REGEN_DELAY := 0.55           # Pause after spending stamina before it refills
const EXHAUSTED_DELAY := 1.1        # Longer pause when you hit 0
const EXHAUSTED_UNTIL := 25.0       # Exhausted until it is back to this much

const ROLL_COST := 26.0
const ROLL_TIME := 0.42
const ROLL_SPEED := 720.0
const ROLL_IFRAMES := 0.30          # Invincible for the first 0.30 s of the roll
const BACKSTEP_COST := 16.0
const BACKSTEP_TIME := 0.24
const BACKSTEP_SPEED := 560.0
const BACKSTEP_IFRAMES := 0.14
const ROLL_RECOVERY := 0.08         # Tiny pause after a roll before you can act

const ATTACK_COST := 12.0
const MOVE_COST := 20.0
const JUMP_COST := 7.0
