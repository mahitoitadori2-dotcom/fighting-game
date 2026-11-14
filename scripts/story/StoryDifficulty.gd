class_name StoryDifficulty
extends RefCounted
## STORY MODE DIFFICULTY (EASY / NORMAL / HARD), picked on the Story board, saved in story.cfg.
## It changes the ENEMIES only (every Story enemy and boss, every boss form, DemiLand too):
##   EASY    70% HP, 65% damage      NORMAL  as designed      HARD  130% HP, 125% damage
## The Caves: EASY slides 12% slower, HARD 10% faster.
## Applied in BaseEnemy._ready (StoryManager.active) and StoryManager.buff_boss (later forms).

const NAMES := ["EASY", "NORMAL", "HARD"]
const HP := [0.70, 1.0, 1.30]
const DMG := [0.65, 1.0, 1.25]
const CAVE_SPEED := [0.88, 1.0, 1.10]
const COLORS := [Color(0.55, 1.0, 0.55), Color(1, 1, 1), Color(1.0, 0.45, 0.35)]


static func level() -> int:
	StoryProgress.load_progress()
	return clampi(StoryProgress.difficulty, 0, 2)


static func name_of() -> String:
	return NAMES[level()]


static func hp() -> float:
	return HP[level()]


static func dmg() -> float:
	return DMG[level()]


static func cave_speed() -> float:
	return CAVE_SPEED[level()]


static func is_hard() -> bool:
	return level() == 2


## A Story enemy just spawned: scale its HP (and every later form) and its damage.
static func apply_enemy(e: BaseEnemy) -> void:
	if level() == 1 or e.data == null:
		return
	e.boss_hp_mult *= hp()
	e.data.max_hp = maxi(roundi(float(e.data.max_hp) * hp()), 1)
	e.hp = e.data.max_hp
	e.story_power *= dmg()
	e.health_changed.emit(e.hp, e.data.max_hp)
