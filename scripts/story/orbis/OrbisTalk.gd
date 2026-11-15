class_name OrbisTalk
extends Node2D
## ORBIS TERRARUM (Story part 13, levels 75-79): PURE LORE - only dialogue, no fighting.
## Scene: scenes/OrbisTalk.tscn. One island above the Storm: the closed hut (ancient spells keep
## the Storm away), a table with one free seat, and THE TRAINER (fully blue).
##
##   75  THE ARRIVAL   walk off the bridge, sit at the table, meet the Trainer. He asks the
##                     Architect to become his Student: "I Agree" = level clear (he is happy and
##                     promises to help); "I Don't Want That" = he is upset, the level FAILS.
##   76-79 LESSONS     one subject each (the Storm, its Organs, its range, its weak points).
##                     Laid out side by side on the board: any order, all four are needed.
## Both heroes are here (they meet up in Orbis Terrarum); the Architect sits, the Warrior stands.

## LEVEL 80 (THE STORM ATTACKS) runs through several scenes: 0 = the table (the Storm breaks in),
## 1 = the breaking bridge (CaveSlide), 2 = the dead town (here), 3 = the cave slide (CaveSlide),
## 4 = the fight (StoryArena). Set to 0 by the board when the level starts.
static var storm_phase := 0

var level_n := 75
var mood := "calm"
var _dark := 0.0                        # The Storm over the island (0..1)
var _crack := 0.0                       # The hut's spell dome cracking (0..1)
var _town := false                      # Phase 2: draw the dead town instead of the island
var _t := 0.0
var _walk := 1.0                       # 0..1: the heroes walk in from the bridge (level 75)
var _ui: CanvasLayer
var _banner: Label
var _sub: Label
var _white := 0.0


func _ready() -> void:
	StoryProgress.load_progress()
	level_n = clampi(StoryProgress.current_level, StoryLevels.first_of(StoryLevels.ORBIS_PART), StoryLevels.last_of(StoryLevels.ORBIS_PART))
	_build_ui()
	_town = level_n == StoryLevels.STORM_LEVEL and storm_phase == 2
	SoundManager.play_music("story_snow" if _town else "story_orbis")
	_run.call_deferred()


func _run() -> void:
	if level_n == StoryLevels.STORM_LEVEL:
		if storm_phase == 2:
			await _storm_town()
		else:
			await _storm_table()
		return
	if level_n == StoryLevels.first_of(StoryLevels.ORBIS_PART):
		await _arrival()
	else:
		await _lesson()


func _lines(src: Array) -> Array:
	var out: Array = (src as Array).duplicate(true)
	for l in out:
		match String(l[0]):
			"A":
				l[0] = "architect"
			"W":
				l[0] = "warrior"
	return out


func _arrival() -> void:
	_walk = 0.0
	_show("LEVEL %d:  ORBIS TERRARUM" % level_n, "You walk off the bridge... onto an island above the Storm.")
	var tw := create_tween()
	tw.tween_property(self, "_walk", 1.0, 3.2).set_trans(Tween.TRANS_SINE)
	await tw.finished
	_hide()
	await get_tree().create_timer(0.4).timeout
	var box := DialogueBox.play(self, _lines(StoryDialogue.ORBIS_ARRIVAL))
	await box.finished
	if box.choice == 0:
		mood = "happy"
		SoundManager.play_sfx("holy")
		var box2 := DialogueBox.play(self, _lines(StoryDialogue.ORBIS_AGREE))
		await box2.finished
		Achievements.unlock("orbis_student")
		await _clear("THE ARCHITECT IS A STUDENT NOW", "The lessons are open: do them in any order - all of them.")
	else:
		mood = "upset"
		SoundManager.play_sfx("block")
		var box3 := DialogueBox.play(self, _lines(StoryDialogue.ORBIS_REFUSE))
		await box3.finished
		await _fail()


func _lesson() -> void:
	var data: Array = StoryDialogue.ORBIS_LESSONS[level_n]
	_show("LESSON:  %s" % String(data[0]), "At the Trainer's table.")
	await get_tree().create_timer(2.0).timeout
	_hide()
	var box := DialogueBox.play(self, _lines(data[1]))
	await box.finished
	var before := _count_done()
	StoryProgress.complete_level(level_n)
	var done := _count_done()
	var total := StoryDialogue.ORBIS_LESSONS.size()
	if done >= total and before < total:                     # The LAST lesson: the Storm stirs
		var box2 := DialogueBox.play(self, _lines(StoryDialogue.ORBIS_ALL_LEARNED))
		await box2.finished
	await _clear("LESSON LEARNED", "All lessons learned!" if done >= total else "%d of %d lessons learned." % [done, total])


## LEVEL 80, phase 0: the last talk at the table - cut off. The Storm breaks into Orbis Terrarum.
func _storm_table() -> void:
	storm_phase = 0
	_show("LEVEL %d:  THE STORM ATTACKS" % level_n, "Back at the Trainer's table. One last thing to learn.")
	await get_tree().create_timer(2.2).timeout
	_hide()
	var box := DialogueBox.play(self, _lines(StoryDialogue.STORM_TABLE))
	await box.finished
	# CUT OFF: thunder, the sky goes black, the spell dome cracks
	SoundManager.stop_music()
	SoundManager.play_sfx("slam")
	SoundManager.play_sfx("roar")
	mood = "upset"
	var tw := create_tween()
	tw.tween_property(self, "_dark", 1.0, 1.2)
	tw.parallel().tween_property(self, "_crack", 1.0, 1.6)
	_show("THE STORM BREAKS INTO ORBIS TERRARUM", "")
	for i in 6:
		SoundManager.play_sfx("beam" if i % 2 == 0 else "rumble", -4.0)
		await get_tree().create_timer(0.3).timeout
	_hide()
	SoundManager.play_music("boss_storm_finger")
	var box2 := DialogueBox.play(self, _lines(StoryDialogue.STORM_RUN))
	await box2.finished
	_next_phase(1, "res://scenes/CaveSlide.tscn")


## LEVEL 80, phase 2: the bottom of the bridge - the dead villagers - the ground opens.
func _storm_town() -> void:
	_dark = 1.0
	_walk = 0.0
	_show("THE TOWN", "At the foot of the bridge.")
	var tw := create_tween()
	tw.tween_property(self, "_walk", 1.0, 3.0).set_trans(Tween.TRANS_SINE)
	await tw.finished
	_hide()
	var box := DialogueBox.play(self, _lines(StoryDialogue.STORM_TOWN))
	await box.finished
	SoundManager.play_sfx("rumble")
	SoundManager.play_sfx("slam", -2.0)
	_show("THE GROUND GIVES WAY", "You fall into the mountain...")
	var tw2 := create_tween()
	tw2.tween_property(self, "_white", 1.0, 1.0)
	await tw2.finished
	_next_phase(3, "res://scenes/CaveSlide.tscn")


## Go on to the next scene of level 80.
func _next_phase(phase: int, scene: String) -> void:
	storm_phase = phase
	StoryProgress.current_level = level_n
	if StoryManager.autoplay:
		print("ORBIS autoplay: level 80 -> phase %d" % phase)
	get_tree().change_scene_to_file(scene)


func _count_done() -> int:
	var k := 0
	for n in StoryDialogue.ORBIS_LESSONS:
		if StoryProgress.level_cleared(int(n)):
			k += 1
	return k


func _clear(title: String, sub: String) -> void:
	StoryProgress.complete_level(level_n)
	Achievements.unlock("orbis_%d" % level_n)
	var done := true
	for n in StoryDialogue.ORBIS_LESSONS:
		if not StoryProgress.level_cleared(int(n)):
			done = false
	if done:
		Achievements.unlock("orbis_lessons")
	SoundManager.play_sfx("count_go")
	_show(title, sub + "\nProgress saved")
	if StoryManager.autoplay:
		print("ORBIS autoplay: level %d CLEAR (choice ok)" % level_n)
	await get_tree().create_timer(2.6).timeout
	StoryBoard.advance_from = level_n
	if level_n < StoryProgress.AVAILABLE_LEVELS:
		StoryProgress.current_level = level_n + 1
	get_tree().change_scene_to_file(StoryManager.STORY_MENU)


## "I Don't Want That": the Trainer turns away - the level fails and starts again.
func _fail() -> void:
	_show("LEVEL FAILED", "The Trainer will not help you.  Try again.")
	if StoryManager.autoplay:
		print("ORBIS autoplay: level %d FAILED (refused)" % level_n)
	await get_tree().create_timer(2.8).timeout
	get_tree().reload_current_scene()


func _process(delta: float) -> void:
	_t += delta
	queue_redraw()


# ============================================================
# DRAWING (screen space: one still island)
# ============================================================
func _draw() -> void:
	var vs := get_viewport_rect().size
	if _town:
		_draw_town(vs)
		_draw_overlays(vs)
		return
	_draw_island(vs)
	if _dark > 0.0:                                              # The Storm breaking in
		draw_rect(Rect2(Vector2.ZERO, vs), Color(0.05, 0.06, 0.12, 0.55 * _dark))
		for i in 14:
			var x := vs.x * float(i) / 13.0
			draw_circle(Vector2(x + 30.0 * sin(_t + float(i)), vs.y * 0.08 + 30.0 * sin(float(i) * 1.7)), 110.0 * _dark, Color(0.14, 0.15, 0.24, 0.9 * _dark))
		if fmod(_t * 1.7, 1.0) < 0.12 * _dark:
			var lx := vs.x * fmod(_t * 0.43, 1.0)
			draw_polyline(PackedVector2Array([Vector2(lx, 0), Vector2(lx + 40, vs.y * 0.2), Vector2(lx - 10, vs.y * 0.4), Vector2(lx + 30, vs.y * 0.62)]), Color(0.9, 0.95, 1.0), 4.0)
	if _crack > 0.0:                                             # The spell dome over the hut cracks
		var hc := Vector2(vs.x * 0.78, vs.y * 0.70 - 14.0 - 114.0)
		for k in 6:
			var a := PI + PI * float(k) / 5.0
			var p0 := hc + Vector2.from_angle(a) * 230.0
			var p1 := p0.lerp(hc, 0.4 * _crack)
			draw_polyline(PackedVector2Array([p0, p0.lerp(p1, 0.5) + Vector2(10, -8), p1]), Color(0.8, 0.95, 1.0, 0.9), 3.0)
	_draw_overlays(vs)


func _draw_overlays(vs: Vector2) -> void:
	if _white > 0.0:
		draw_rect(Rect2(Vector2.ZERO, vs), Color(1, 1, 1, _white))


## LEVEL 80, phase 2: the town of Terra Ordinariorum under the Storm - the villagers lie dead.
func _draw_town(vs: Vector2) -> void:
	for i in 10:
		var k := float(i) / 9.0
		draw_rect(Rect2(0, vs.y * 0.1 * float(i), vs.x, vs.y * 0.1 + 1.0), Color(0.08, 0.09, 0.15).lerp(Color(0.30, 0.32, 0.42), k))
	for i in 16:
		draw_circle(Vector2(vs.x * float(i) / 15.0, vs.y * 0.1 + 20.0 * sin(float(i) * 2.0 + _t * 0.4)), 120.0, Color(0.12, 0.13, 0.22))
	if fmod(_t, 2.3) < 0.1:
		draw_rect(Rect2(Vector2.ZERO, vs), Color(0.8, 0.85, 1.0, 0.12))
	var ground := vs.y * 0.56                                   # (High enough to see over the dialogue box)
	for k in 5:                                                  # Broken houses
		var hx := vs.x * (0.08 + 0.2 * float(k))
		draw_rect(Rect2(hx, ground - 120.0, 140.0, 120.0), Color(0.42, 0.38, 0.34))
		draw_colored_polygon(PackedVector2Array([Vector2(hx - 10, ground - 120), Vector2(hx + 40, ground - 170 + float(k % 2) * 30.0), Vector2(hx + 90, ground - 120)]), Color(0.30, 0.16, 0.12))
		draw_rect(Rect2(hx + 50, ground - 50, 34, 50), Color(0.12, 0.10, 0.09))
	draw_rect(Rect2(0, ground, vs.x, vs.y - ground), Color(0.28, 0.27, 0.27))
	draw_line(Vector2(0, ground), Vector2(vs.x, ground), Color(0, 0, 0), 3.0)
	# The villagers, lying in the street (grey, still)
	var spots := [0.18, 0.31, 0.45, 0.58, 0.70, 0.84]
	for i in spots.size():
		draw_set_transform(Vector2(vs.x * float(spots[i]), ground + 4.0), -PI * 0.5 * (1.0 if i % 2 == 0 else -1.0), Vector2(0.9, 0.9))
		modulate_town_corpse(i)
		draw_set_transform(Vector2.ZERO, 0.0, Vector2.ONE)
	# The three of you walk in from the left
	var k2 := clampf(_walk, 0.0, 1.0)
	var bob := absf(sin(_t * 10.0)) * 4.0 if k2 < 1.0 else 0.0
	var base := Vector2(vs.x * (0.02 + 0.36 * k2), ground - bob)
	draw_set_transform(base + Vector2(-120, 0), 0.0, Vector2(1.1, 1.1))
	OrbisArt.trainer(self, _t, "upset")
	draw_set_transform(base + Vector2(-60, 0), 0.0, Vector2(1.1, 1.1))
	WarriorArt.draw_portrait(self, _t)
	draw_set_transform(base, 0.0, Vector2(1.1, 1.1))
	ArchitectArt.draw_portrait(self, _t)
	draw_set_transform(Vector2.ZERO, 0.0, Vector2.ONE)


func modulate_town_corpse(i: int) -> void:
	OrdArt.villager(self, i, 0.0)
	draw_circle(Vector2(0, -60), 70.0, Color(0.25, 0.27, 0.35, 0.35))              # Greyed by the Storm


func _draw_island(vs: Vector2) -> void:
	# Sky: warm gold above a calm blue
	for i in 10:
		var k := float(i) / 9.0
		draw_rect(Rect2(0, vs.y * 0.1 * float(i), vs.x, vs.y * 0.1 + 1.0), Color(0.98, 0.86, 0.60).lerp(Color(0.55, 0.72, 0.95), k))
	draw_circle(Vector2(vs.x * 0.82, vs.y * 0.16), 60.0, Color(1.0, 0.97, 0.85))
	draw_circle(Vector2(vs.x * 0.82, vs.y * 0.16), 110.0, Color(1.0, 0.95, 0.75, 0.2))
	# The Storm far BELOW the island: a ring of dark clouds, lightning inside
	for i in 22:
		var x := vs.x * float(i) / 21.0
		var y := vs.y * 0.86 + 20.0 * sin(float(i) * 1.7 + _t * 0.3)
		draw_circle(Vector2(x, y), 90.0 + 20.0 * sin(float(i) * 2.3), Color(0.17, 0.18, 0.27))
	if fmod(_t, 3.7) < 0.12:
		var lx := vs.x * fmod(_t * 0.31, 1.0)
		draw_polyline(PackedVector2Array([Vector2(lx, vs.y * 0.82), Vector2(lx + 20, vs.y * 0.9), Vector2(lx - 8, vs.y)]), Color(0.85, 0.92, 1.0), 3.0)
	# The island: grass on top of floating rock
	var ground := vs.y * 0.70
	var rock := PackedVector2Array([Vector2(vs.x * 0.04, ground), Vector2(vs.x * 0.96, ground), Vector2(vs.x * 0.80, ground + 120.0),
		Vector2(vs.x * 0.55, ground + 190.0), Vector2(vs.x * 0.30, ground + 150.0), Vector2(vs.x * 0.14, ground + 90.0)])
	draw_colored_polygon(rock, Color(0.40, 0.31, 0.25))
	draw_polyline(rock + PackedVector2Array([rock[0]]), Color(0, 0, 0), 3.0)
	draw_rect(Rect2(vs.x * 0.04, ground - 18.0, vs.x * 0.92, 22.0), Color(0.40, 0.68, 0.32))
	for k in 30:
		var gx := vs.x * (0.06 + 0.03 * float(k))
		draw_line(Vector2(gx, ground - 16.0), Vector2(gx + 4.0, ground - 30.0 - float(k % 3) * 5.0), Color(0.32, 0.6, 0.26), 3.0)
	# The bridge's end on the left, glowing
	draw_line(Vector2(-20, vs.y * 0.92), Vector2(vs.x * 0.08, ground - 6.0), Color(1.0, 0.95, 0.75, 0.4), 30.0)
	draw_line(Vector2(-20, vs.y * 0.92), Vector2(vs.x * 0.08, ground - 6.0), Color(0.95, 0.88, 0.62), 12.0)
	# The hut (right) and the table (middle)
	OrbisArt.hut(self, Vector2(vs.x * 0.78, ground - 14.0), _t)
	var tx := vs.x * 0.47
	var ty := ground - 14.0
	draw_set_transform(Vector2(tx - 120.0, ty), 0.0, Vector2(1.15, 1.15))
	OrbisArt.trainer(self, _t, mood, true)
	draw_set_transform(Vector2.ZERO, 0.0, Vector2.ONE)
	# The heroes: walk in from the bridge; the Architect sits in the free seat, the Warrior stands by
	var arch_end := Vector2(tx + 120.0, ty - 8.0)
	var war_end := Vector2(tx + 220.0, ty)
	var start := Vector2(vs.x * 0.06, ty)
	var k2 := clampf(_walk, 0.0, 1.0)
	var bob := absf(sin(_t * 10.0)) * 4.0 if k2 < 1.0 else 0.0
	var ap := start.lerp(arch_end, k2) - Vector2(0, bob)
	var wp := (start - Vector2(60, 0)).lerp(war_end, k2) - Vector2(0, bob)
	draw_set_transform(wp, 0.0, Vector2(-1.15, 1.15) if k2 >= 1.0 else Vector2(1.15, 1.15))
	WarriorArt.draw_portrait(self, _t)
	draw_set_transform(ap, 0.0, Vector2(-1.15, 1.15) if k2 >= 1.0 else Vector2(1.15, 1.15))
	ArchitectArt.draw_portrait(self, _t)
	draw_set_transform(Vector2.ZERO, 0.0, Vector2.ONE)
	draw_set_transform(Vector2(tx, ty), 0.0, Vector2(1.15, 1.15))
	OrbisArt.table(self, Vector2.ZERO)
	draw_set_transform(Vector2.ZERO, 0.0, Vector2.ONE)


# ============================================================
# UI
# ============================================================
func _build_ui() -> void:
	_ui = CanvasLayer.new()
	_ui.layer = 10
	add_child(_ui)
	var box := VBoxContainer.new()
	box.set_anchors_and_offsets_preset(Control.PRESET_CENTER_TOP)
	box.offset_left = -600
	box.offset_right = 600
	box.offset_top = 40
	box.offset_bottom = 180
	box.mouse_filter = Control.MOUSE_FILTER_IGNORE
	_ui.add_child(box)
	_banner = UiStyle.label("", 44, Color(1.0, 0.86, 0.5), 10)
	box.add_child(_banner)
	_sub = UiStyle.label("", 21, Color(0.98, 0.96, 0.9), 4)
	box.add_child(_sub)
	var pause := UiStyle.make_button("II", Vector2(64, 56), 22)
	pause.set_anchors_and_offsets_preset(Control.PRESET_TOP_RIGHT)
	pause.offset_left = -80
	pause.offset_right = -16
	pause.offset_top = 12
	pause.offset_bottom = 68
	pause.focus_mode = Control.FOCUS_NONE
	pause.pressed.connect(func() -> void: PauseMenu.toggle(get_tree()))
	_ui.add_child(pause)


func _show(a: String, b: String) -> void:
	_banner.text = a
	_sub.text = b
	for l in [_banner, _sub]:
		l.modulate.a = 0.0
		create_tween().tween_property(l, "modulate:a", 1.0, 0.3)


func _hide() -> void:
	for l in [_banner, _sub]:
		create_tween().tween_property(l, "modulate:a", 0.0, 0.3)
