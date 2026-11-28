class_name HollowArchitect
extends C5Boss
## THE HOLLOW ARCHITECT (The Last Stretch, level 147): the boss at the bottom of the Architect's own
## soul - every weakness of his life wearing his face. The Architect's model (ArchitectArt) in a
## washed-out, hollow palette, a little bigger. Each move is one of the weaknesses he fought on the
## way down (levels 143-146):
##
##   Hollow Punch           6 dmg   a quick jab
##   Hollow Laser           7 dmg   a fast grey bolt straight at you
##   OBEY!                  -       two ghosts of Architectian soldiers (OBEDIENCE)
##   The Gift               6 dmg   crates fall from a god that never comes (THE GIFT THAT NEVER CAME)
##   The Dark Below         7 dmg   void tendrils burst out of the floor under you (THE DARK BELOW)
##   The Ones You Lost      6 dmg   pale pillars of light all over the floor (THE ONES YOU COULD NOT SAVE)
##   Drill Rush             8 dmg   leaps at you and drills into the floor
## Enraged (below half): everything faster, and OBEY! calls three.

const ART_K := 1.35
const HOLLOW_PALETTE := {
	"WHITE": Color(0.62, 0.60, 0.70), "WHITE_SHADE": Color(0.44, 0.42, 0.52),
	"GREEN": Color(0.40, 0.36, 0.52), "GREEN_SHADE": Color(0.24, 0.21, 0.34), "GREEN_HI": Color(0.66, 0.62, 0.80),
	"GREEN_FAR": Color(0.30, 0.27, 0.40), "GREEN_FAR_SHADE": Color(0.18, 0.16, 0.26),
	"DARK": Color(0.12, 0.10, 0.16), "DARK_SHADE": Color(0.06, 0.05, 0.09), "DARK_HI": Color(0.30, 0.28, 0.36),
	"VISOR": Color(0.02, 0.02, 0.03), "CORE": Color(0.22, 0.20, 0.30), "CORE_HI": Color(0.52, 0.50, 0.62),
	"DRILL": Color(0.45, 0.43, 0.52), "DRILL_SHADE": Color(0.28, 0.26, 0.34),
}
## The soul's ghostly tint (the memories he fights, LevelsLastStretch "soul").
const SOUL_TINT := Color(0.78, 0.72, 1.0, 0.86)

var _drill_x := 0.0


func boss_forms() -> Array:
	return [{"name": "The Hollow Architect", "title": "THE HOLLOW ARCHITECT", "hp": 360, "body": Vector2(70, 170), "speed": 290.0}]


func setup_boss() -> void:
	keep_min = 110.0
	keep_max = 420.0
	attack_chance = 0.75
	chain_chance = 0.4
	art_scale = ART_K
	max_minions = 3
	tags = {"punch": ["close"], "laser": ["ranged"], "obey": ["ranged"], "gift": ["ranged", "anti_air"],
		"dark": ["ranged"], "lost": ["ranged"], "drill": ["close", "escape"]}
	combos = {"punch": ["drill"], "laser": ["dark"], "gift": ["lost"]}


static func make_patterns() -> Array[EnemyPattern]:
	var list: Array[EnemyPattern] = []
	#                          id       name                     cd    dmg  min    max     anim     tele  active rec   big   weights armored
	list.append(EnemyPattern.make("punch", "HOLLOW PUNCH", 1.5, 6, 0.0, 140.0, "punch", 0.22, 0.15, 0.35, false, [1.8], true))
	list.append(EnemyPattern.make("laser", "HOLLOW LASER!", 2.8, 7, 140.0, 2000.0, "cast", 0.35, 0.2, 0.4, false, [1.6], true))
	list.append(EnemyPattern.make("obey", "OBEY!", 11.0, 0, 0.0, 2000.0, "cast", 0.6, 0.3, 0.5, true, [1.0], true))
	list.append(EnemyPattern.make("gift", "THE GIFT!", 6.0, 6, 0.0, 2000.0, "cast", 0.5, 0.3, 0.45, false, [1.3], true))
	list.append(EnemyPattern.make("dark", "THE DARK BELOW!", 5.5, 7, 0.0, 2000.0, "cast", 0.5, 0.3, 0.45, true, [1.3], true))
	list.append(EnemyPattern.make("lost", "THE ONES YOU LOST", 9.0, 6, 0.0, 2000.0, "cast", 0.6, 0.4, 0.5, true, [1.0], true))
	list.append(EnemyPattern.make("drill", "DRILL RUSH!", 6.5, 8, 0.0, 900.0, "spikes", 0.45, 0.8, 0.6, true, [1.2], true))
	return list


func flavor_lines() -> Array[String]:
	return ["You were never enough.", "Wait for the god. Wait.", "Follow the order.", "You could have saved them."]


func _attack(p: EnemyPattern) -> void:
	face_target()
	match p.id:
		"punch":
			swing(dmg(p), Vector2(240, -170), Vector2(60, -110), Vector2(100, 80), "hollow_punch")
			SoundManager.play_sfx("punch", -4.0)
		"laser":
			var n := 1 if not raging else 2
			for i in n:
				shoot("light_orb", global_position + Vector2(facing * 50.0, -150.0 + float(i) * 50.0), float(facing), 900.0, 1.6,
					Vector2(46, 20), dmg(p), Vector2(200, -140), Color(0.72, 0.68, 0.86), "hollow_laser")
			SoundManager.play_sfx("beam", -4.0)
		"obey":
			for i in (3 if raging else 2):
				var m := summon(["warrior_a_sword", "warrior_a_spear", "warrior_a"][i % 3], Vector2(clamp_arena(global_position.x + float(i * 2 - 1) * 160.0), floor_y() - 200.0))
				if m != null:
					m.set_deferred("modulate", SOUL_TINT)
			SoundManager.play_sfx("holy", -6.0)
		"gift":
			var x0 := target_x()
			for i in (3 if not raging else 4):
				lob("light_orb", Vector2(x0 + float(i) * 70.0 - 100.0, floor_y() - 700.0), x0 + float(i - 1) * 120.0, 0.9 + 0.12 * float(i),
					dmg(p), Vector2(180, -220), 46.0, Color(1.0, 0.86, 0.45), "hollow_gift")
			SoundManager.play_sfx("whoosh", -4.0)
		"dark":
			var tx := target_x()
			for i in 3:
				hazard("tendril", tx + float(i - 1) * 130.0, 0.5 + 0.1 * float(i), dmg(p))
			SoundManager.play_sfx("void_goo", -4.0)
		"lost":
			var left := clamp_arena(global_position.x - 700.0)
			for i in 6:
				hazard("pillar", left + float(i) * 240.0 + randf_range(-40.0, 40.0), 0.6 + 0.12 * float(i), dmg(p))
			SoundManager.play_sfx("holy", -4.0)
		"drill":
			_drill_x = target_x()
			leap_to(_drill_x, 0.55, 280.0)
			SoundManager.play_sfx("whoosh")


func _on_attack_update(p: EnemyPattern, _delta: float) -> void:
	if p.id == "drill" and is_on_floor() and state_time > 0.3:
		hit_in_radius(global_position + Vector2(0, -50), 150.0, dmg(p), Vector2(280, -300), "hollow_drill")
		hazard("rock", global_position.x - 120.0, 0.15, dmg(p))
		hazard("rock", global_position.x + 120.0, 0.15, dmg(p))
		Effects.shake(self, 10.0)
		SoundManager.play_sfx("slam")
		state_time = state_len


func _on_death() -> void:
	super._on_death()
	if StoryManager.autoplay:
		return
	Achievements.unlock("ls_true_self")
	var m := get_tree().get_first_node_in_group("story_manager") as StoryManager
	if m != null and m.flasks >= m.max_flasks:
		Achievements.unlock("ls_unshaken")                  # Not one flask drunk in the whole level


func _owns_velocity_x() -> bool:
	return estate == EState.ATTACK and current != null and current.id == "drill"


func draw_model_on(c: CanvasItem) -> void:
	var s := art_state()
	var pose_v: String = s.get("pose", "idle")
	var pt: float = s.get("pose_t", 0.0)
	var punch := clampf(pt * 8.0, 0.0, 1.0) if pose_v == "punch" else 0.0
	var drill := 40.0 if pose_v.begins_with("spikes") else 0.0
	draw_hollow(c, float(s.get("t", 0.0)), float(s.get("walk", 0.0)), bool(s.get("floor", true)), punch, drill)


static func draw_portrait(c: CanvasItem, t: float) -> void:
	draw_hollow(c, t, 0.0, true, 0.0, 0.0)


## The Architect's model in the hollow palette, with cracks of dark light across the chest.
static func draw_hollow(c: CanvasItem, t: float, ph: float, on_floor: bool, punch: float, drill: float) -> void:
	c.draw_circle(Vector2(0, -70), 58.0, Color(0.45, 0.40, 0.70, 0.12 + 0.05 * sin(t * 2.0)))
	ArchitectArt.set_palette(HOLLOW_PALETTE)
	ArchitectArt._draw_figure(c, t, ph, on_floor, punch, 0.0, drill, 0.0, false, false)
	ArchitectArt.set_palette(ArchitectArt.NORMAL_PALETTE)
	var crack := Color(0.10, 0.05, 0.20, 0.9)
	c.draw_polyline(PackedVector2Array([Vector2(-8, -96), Vector2(-2, -84), Vector2(-9, -74), Vector2(0, -62)]), crack, 2.0)
	c.draw_polyline(PackedVector2Array([Vector2(8, -100), Vector2(3, -90), Vector2(10, -80)]), crack, 2.0)
