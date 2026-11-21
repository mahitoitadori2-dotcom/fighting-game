class_name StoryDifficulty
extends RefCounted
## STORY MODE DIFFICULTY (EASY / NORMAL / HARD), picked on the Story board, saved in story.cfg.
## It changes the ENEMIES only (every Story enemy and boss, every boss form, DemiLand too):
##   EASY    70% HP, 65% damage      NORMAL  as designed      HARD  130% HP, 125% damage
## The Caves: EASY slides 12% slower, HARD 10% faster.
## Applied in BaseEnemy._ready (StoryManager.active) and StoryManager.buff_boss (later forms).
##
## ==== MILESTONE LEVEL RULE (the user's design rule, 2026-11-21 - keep it for EVERY new level) ====
##   every 10th level (10, 20, 30, 40, 60, 70, 80, 90 ...)  HARDER        enemies +20% HP, +15% damage
##   every 25th level (25, 75, 125 ...)                     EVEN HARDER   enemies +40% HP, +30% damage
##   every 50th level (50, 100, 150 ...)                    SUPER BOSS    enemies as every 25th, and the
##                                                          level's BOSS gets x1.8 HP, x1.4 damage and
##                                                          attacks ~15% more often (super duper strong)
##   The biggest tier wins (50 beats 25 beats 10). It stacks with EASY / NORMAL / HARD.
##   WHEN ADDING LEVELS: every level number divisible by 50 MUST have a boss ("boss": "..." in StoryLevels).
##   Boss Extensions (StoryLevels.is_ext) are not numbered levels and never count as milestones.
##   The level intro banner shows the tier (milestone_tag). Boss Rush uses the same numbers.

const NAMES := ["EASY", "NORMAL", "HARD"]
const HP := [0.70, 1.0, 1.30]
const DMG := [0.65, 1.0, 1.25]
const CAVE_SPEED := [0.88, 1.0, 1.10]
const COLORS := [Color(0.55, 1.0, 0.55), Color(1, 1, 1), Color(1.0, 0.45, 0.35)]

# Milestone tiers: 0 none, 1 every 10th, 2 every 25th, 3 every 50th (see the rule above)
const MILESTONE_HP := [1.0, 1.20, 1.40, 1.40]
const MILESTONE_DMG := [1.0, 1.15, 1.30, 1.30]
const MILESTONE_TAGS := ["", "HARDER LEVEL", "EVEN HARDER LEVEL", "SUPER BOSS LEVEL"]
const SUPER_BOSS_HP := 1.8
const SUPER_BOSS_DMG := 1.4
const SUPER_BOSS_CD := 0.85                     # Cooldowns x0.85 = attacks ~15% more often


## Milestone tier of Story level n (0 = a normal level).
static func milestone(n: int) -> int:
	if Madness.is_madness(n):
		n = Madness.local(n)                            # MADNESS counts its own levels 1-20 (10 and 20 = harder)
	if n <= 0 or StoryLevels.is_ext(n):
		return 0
	if n % 50 == 0:
		return 3
	if n % 25 == 0:
		return 2
	if n % 10 == 0:
		return 1
	return 0


## "HARDER LEVEL" / "EVEN HARDER LEVEL" / "SUPER BOSS LEVEL" / "" for the intro banner.
static func milestone_tag(n: int) -> String:
	return MILESTONE_TAGS[milestone(n)]


static func _current_milestone() -> int:
	return milestone(StoryProgress.current_level)


static func level() -> int:
	StoryProgress.load_progress()
	return clampi(StoryProgress.difficulty, 0, 2)


static func name_of() -> String:
	return NAMES[level()]


## Enemy HP / damage multiplier: EASY / NORMAL / HARD x the milestone tier of the current level.
static func hp() -> float:
	return HP[level()] * MILESTONE_HP[_current_milestone()]


static func dmg() -> float:
	return DMG[level()] * MILESTONE_DMG[_current_milestone()]


static func cave_speed() -> float:
	return CAVE_SPEED[level()]


static func is_hard() -> bool:
	return level() == 2


## A Story enemy just spawned (difficulty x milestone tier): scale its HP (and every later form) and its damage.
static func apply_enemy(e: BaseEnemy) -> void:
	if e.data == null or (is_equal_approx(hp(), 1.0) and is_equal_approx(dmg(), 1.0)):
		return
	e.boss_hp_mult *= hp()
	e.data.max_hp = maxi(roundi(float(e.data.max_hp) * hp()), 1)
	e.hp = e.data.max_hp
	e.story_power *= dmg()
	e.health_changed.emit(e.hp, e.data.max_hp)


## SUPER BOSS (every 50th level): called by StoryManager.buff_boss after the normal boss buff.
static func apply_super_boss(e: BaseEnemy) -> void:
	if e == null or e.data == null or _current_milestone() != 3:
		return
	e.boss_hp_mult *= SUPER_BOSS_HP
	e.boss_cd_mult *= SUPER_BOSS_CD
	e.story_power *= SUPER_BOSS_DMG
	e.data.max_hp = roundi(float(e.data.max_hp) * SUPER_BOSS_HP)
	e.hp = e.data.max_hp
	e.poise_max = maxf(e.poise_max * SUPER_BOSS_HP, 40.0)
	e.health_changed.emit(e.hp, e.data.max_hp)