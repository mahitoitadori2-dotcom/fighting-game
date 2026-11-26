class_name NightmareOffer
extends RefCounted
## THE TRUE HUNT's ending (level 138, after the last golem of the Nightmare Monstrosity): the Nightmare
## Lord walks out of the dark, tells you what Terra Patria really is - and asks to come with you.
## What happens depends on what you did EARLIER in the Story (checked in this order):
##   1. You heard fewer than 3 of the DemiLand Stranger's talks -> a horde of goblins ambushes him (the
##      Stranger could have told you how they hunt). He runs where you cannot follow.        -> LEFT
##   2. You freed the KHARLEMING SACRIFICE (Terra Craterum) -> it went for his throat. He calls it a trap
##      and escapes.                                                                          -> LEFT
##   3. You freed the VOLCANO SLAVE -> he was one of the Clan; he vouches for you.              -> JOINED
##   4. Anything else -> YOU choose (your Abandoned Town choice colours what he says).     -> JOINED / LEFT
## JOINED unlocks his Versus card (StoryProgress.nl_fate, CharacterRoster).

const STRANGER_TALKS_NEEDED := 3
## TESTING ONLY: force an outcome path ("goblins" / "sacrifice" / "slave" / "choice").
static var test_path := ""

const ARRIVAL := [
	["narrator", "The forge goes quiet. Behind the biggest anvil, someone claps. Slowly."],
	["nightmare_lord", "Six generations. My smiths swore it could never be killed. They were half right."],
	["H", "You ran through half of this planet to get away from us."],
	["nightmare_lord", "Half. Yes. The Storm only ever guards half of Terra Patria at once. I ran where it let me."],
	["P", "Then stop running. Why are you hiding from the Storm?"],
	["nightmare_lord", "I am not hiding from it. Nobody can. Sit, if you like. You have earned the story."],
]
const LORE := [
	["nightmare_lord", "Terra Patria was the first world in the whole universe with air you could breathe. Not the first to grow life - the second. But the first SKY."],
	["nightmare_lord", "Count every world with breathable air today: one million, seven hundred and thirty thousand, four hundred and thirty-eight. Half of them are lived on."],
	["nightmare_lord", "None of them had a head start like ours. A head start that long turns a world into something else. A PRIME FRAGMENT OF EXISTENCE."],
	["nightmare_lord", "A world that could conquer everything. So everything else put LOCKS on it. Nine of them. Six are shut on Terra Patria right now."],
	["H", "And the Storm is one of them."],
	["nightmare_lord", "The third. A SEED, planted in the ground. It waits until the other locks are in place... and then it blooms."],
	["nightmare_lord", "Half the planet under it at once, and it guards BOTH ways. Nothing in. Nothing out."],
	["nightmare_lord", "Before it came the second lock. The Deconstructors of Multiversal Paths. Every road that ever led here - wormholes, teleports, even the slow roads under the speed of light - erased. As if they never existed."],
	["nightmare_lord", "The fourth is one line in the constitution of the Kharlemings' home world. It cuts this planet's gravity off from everyone else's. To leave, you would have to break physics."],
	["nightmare_lord", "The fifth: a ring of electric black holes around the sky. Fly into one and it throws you straight back down. Some call it the Condensat Barrier. Some call it the Shield of Kokusen."],
	["P", "...Kokusen. I know that name from somewhere."],
	["nightmare_lord", "Everyone does. Nobody remembers from where."],
	["nightmare_lord", "And the sixth, the last of the main locks. The CORE IGNITION."],
	["nightmare_lord", "Nobody on Terra Patria truly dies any more. Heaven and Hell shut their gates - with everyone already inside them still inside."],
	["nightmare_lord", "Die here, and you are fused with the Storm. Ten years. Strong enough, and you tear yourself back out, no harm done. Not strong enough..."],
	["H", "...The corpses the Storm moved. In the dead town."],
	["nightmare_lord", "Now you know what it is made of. It was never meant to kill. Only to keep this world growing stronger, without ever letting it out."],
	["nightmare_lord", "There are three more locks. Nobody has ever seen them close. The last one gives the power of TIME itself to ONE person on this world."],
	["H", "Who?"],
	["nightmare_lord", "If I knew that, I would not be living in a cave."],
	["nightmare_lord", "My Clan, the Nightmare Nourmish, came here before the locks. Quietly. Guests nobody invited."],
	["nightmare_lord", "When the Storm woke again we thought: now, before the last lock closes. And we struck."],
	["nightmare_lord", "Enlighteners. Architectians. UnderLords, OverLords. Even Hell and Heaven came out to meet us. We never stood a chance. So: the caves."],
	["P", "And in all of it, you never once tried to hurt either of us. Why?"],
	["nightmare_lord", "Because you two are the first in a very long time who might actually break OUT of here. When you do, I want to be standing next to you."],
	["nightmare_lord", "So. An offer. Let me walk with you."],
]
const GOBLINS := [
	["narrator", "Something chitters in the dark behind the anvils. Then a hundred somethings."],
	["nightmare_lord", "Goblins?! A whole horde - you led them straight to my door!"],
	["H", "We didn't-"],
	["nightmare_lord", "Somebody in DemiLand knew how they hunt. A shame you never stayed to listen."],
]
const GOBLINS_AFTER := [
	["narrator", "He is gone, and the goblins after him. Wherever he ran, you cannot follow."],
]
const SACRIFICE := [
	["narrator", "A shriek from the tunnel behind you. You know that voice."],
	["kharleming_sacrifice", "SKREEEEEEEEEEE!"],
	["nightmare_lord", "The thing from the reactor?! You FREED it - and brought it HERE?"],
	["nightmare_lord", "A trap. Of course it was a trap. Clever. Not clever enough."],
]
const SACRIFICE_AFTER := [
	["H", "It wasn't a trap!"],
	["P", "...He's gone. And so is the Kharleming."],
]
const SLAVE := [
	["narrator", "Slow footsteps. A pickaxe dragging along the stone behind them."],
	["volcano_slave", "...Hello again."],
	["nightmare_lord", "You. You are one of MINE. The lava took you, years ago. We gave you up for dead."],
	["volcano_slave", "These two broke my chain with one swing. I walked all the way here to tell you."],
	["nightmare_lord", "...Then the debt of the whole Clan is theirs."],
	["nightmare_lord", "Very well. The Nightmare walks with the heroes. The universe should be very worried."],
]
const TOWN_MEMORY := {
	"woke": ["nightmare_lord", "You woke me in the dark of that cave. I told you I would not forget your face. I did not."],
	"carried": ["nightmare_lord", "You carried me out of that town without even waking me. A strange kindness. I noticed."],
	"left": ["nightmare_lord", "You left me in those chains. I got out anyway. I do not hold it against you. Much."],
}
const JOIN := [["nightmare_lord", "Then the Nightmare walks with the heroes. The universe should be very worried."]]
const SEND_AWAY := [["nightmare_lord", "As you wish. But one day you will be in a cave again, looking for me."]]


## The whole scene. Await it from the StoryManager.
static func play(m: StoryManager) -> void:
	CombatManager.fight_active = false
	m.wave_text = ""
	m._clear_hazards()
	m._letterbox(true)
	SoundManager.play_music("story_true_hunt")
	var px := m.player.global_position.x
	var nl := Actor.spawn(m, "nightmare_lord", Vector2(px + 900.0, m._ground_y), -1)
	ArenaCamera.focus = nl
	ArenaCamera.focus_zoom = 0.9
	await nl.walk_to(px + 300.0, 2.2)
	ArenaCamera.focus = null
	await _talk(m, ARRIVAL)
	await _talk(m, LORE)
	var path := _path()
	var joined := false
	match path:
		"goblins":
			var gobs: Array = await _goblins_creep(m, nl)        # They are THERE when he shouts about them
			await _talk(m, GOBLINS)
			await _goblin_ambush(m, nl, gobs)
			await _talk(m, GOBLINS_AFTER)
		"sacrifice":
			var sac := Actor.spawn(m, "kharleming_sacrifice", Vector2(px - 700.0, m._ground_y), 1)
			await sac.walk_to(px - 220.0, 0.9)
			await _talk(m, SACRIFICE)
			await _sacrifice_attack(m, nl, sac)
			await _talk(m, SACRIFICE_AFTER)
		"slave":
			var sl := Actor.spawn(m, "volcano_slave", Vector2(px - 700.0, m._ground_y), 1)
			await sl.walk_to(px + 120.0, 2.4)
			await _talk(m, SLAVE)
			joined = true
		_:
			var lines: Array = []
			StoryProgress.load_progress()
			if TOWN_MEMORY.has(StoryProgress.town_choice):
				lines.append(TOWN_MEMORY[StoryProgress.town_choice])
			lines.append(["H", "...", ["Walk with us. The Storm is the real enemy.", "No. Go, and don't come back."]])
			var pick: int = await _talk(m, lines)
			joined = pick == 0
			await _talk(m, JOIN if joined else SEND_AWAY)
	StoryProgress.set_nl_fate("joined" if joined else "left")
	if not StoryManager.autoplay:
		Achievements.unlock("nl_joined" if joined else "nl_left")
	if joined:
		await nl.walk_to(px + 110.0, 1.2)
		Effects.gold_burst(nl, nl.global_position + Vector2(0, -80), 140.0)
		SoundManager.play_sfx("ultimate")
		m._show_banner("THE NIGHTMARE LORD JOINS YOU", "NEW FIGHTER: THE NIGHTMARE LORD", Color(1.0, 0.35, 0.25))
	else:
		if path == "choice" or path == "":
			nl.vanish()
		SoundManager.play_sfx("whoosh")
		m._show_banner("THE NIGHTMARE LORD IS GONE", "", Color(0.8, 0.55, 0.5))
	await m._wait(3.0)
	m._hide_banner()
	m._letterbox(false)
	if StoryManager.autoplay:
		print("STORY autoplay: nightmare offer path=%s joined=%s" % [path, joined])


## Which way it goes (see the header).
static func _path() -> String:
	if test_path != "":
		return test_path
	StoryProgress.load_progress()
	var talks := 0
	for b in 8:
		if StoryProgress.npc_talks & (1 << b):
			talks += 1
	if talks < STRANGER_TALKS_NEEDED:
		return "goblins"
	if StoryProgress.crater_choice == "sacrifice":
		return "sacrifice"
	if StoryProgress.crater_choice == "slave":
		return "slave"
	return "choice"


## Plays lines ("H" = you, "P" = your partner). Returns the picked option (-1 = none).
static func _talk(m: StoryManager, src: Array) -> int:
	var other := "architect" if m.hero == "warrior" else "warrior"
	var lines: Array = []
	for l: Array in src:
		var who := String(l[0])
		if who == "H":
			who = m.hero
		elif who == "P":
			if m.partner == null:
				continue
			who = other
		var out := [who, String(l[1])]
		if l.size() > 2:
			out.append(l[2])
		lines.append(out)
	for lbl in [m._banner, m._sub]:
		(lbl as CanvasItem).modulate.a = 0.0
	var box := DialogueBox.play(m, lines)
	await box.finished
	return box.choice


## A dozen goblins creep out of the dark on both sides and stop, watching.
static func _goblins_creep(m: StoryManager, nl: Actor) -> Array:
	SoundManager.play_sfx("roar", -8.0)
	var gobs: Array = []
	var cx := (m.player.global_position.x + nl.global_position.x) * 0.5
	for i in 12:
		var from_right := i % 2 == 0
		var side := 1.0 if from_right else -1.0
		var g := Actor.spawn(m, "lava_goblin", Vector2(cx + side * (1000.0 + float(i) * 30.0), m._ground_y), -1 if from_right else 1)
		gobs.append(g)
		g.walk_to(cx + side * (560.0 + floorf(float(i) / 2.0) * 45.0), 1.4 + randf() * 0.4)
	await m._wait(1.9)
	return gobs


static func _goblin_ambush(m: StoryManager, nl: Actor, gobs: Array) -> void:
	SoundManager.play_sfx("roar", -4.0)
	for g: Actor in gobs:
		g.walk_to(nl.global_position.x + randf_range(-140.0, 140.0), 0.7 + randf() * 0.4)
	await m._wait(0.7)
	Effects.shake(m, 10.0)
	SoundManager.play_sfx("whoosh")
	await nl.leap_away(1)                          # Over their heads and into the dark
	for g: Actor in gobs:
		g.walk_to(g.global_position.x + 1500.0, 1.6)
	await m._wait(1.7)
	for g: Actor in gobs:
		g.queue_free()


static func _sacrifice_attack(m: StoryManager, nl: Actor, sac: Actor) -> void:
	await sac.leap_to(nl.global_position.x - 40.0, 0.6)
	Effects.explosion(m, nl.global_position + Vector2(0, -90), 120.0, true, true)
	Effects.shake(m, 14.0)
	SoundManager.play_sfx("flame")
	nl.vanish()
	await m._wait(0.6)
	await sac.walk_to(sac.global_position.x + 1200.0, 1.6)
	sac.queue_free()


# ============================================================
# A figure in the scene, drawn with its dialogue portrait (feet at 0, 0).
# ============================================================
class Actor extends Node2D:
	var id := ""
	var face := 1
	var _t := 0.0
	var _walking := false

	static func spawn(host: Node, p_id: String, pos: Vector2, p_face: int) -> Actor:
		var a := Actor.new()
		a.id = p_id
		a.face = p_face
		a.position = pos
		a.z_index = 2
		host.add_child(a)
		return a

	func _process(delta: float) -> void:
		_t += delta
		queue_redraw()

	## Size in the world: enemy portraits are drawn life-size, the others are scaled like the hero art.
	func _world_scale() -> float:
		if id in ["nightmare_lord", "volcano_slave", "kharleming_sacrifice"]:
			return StoryDialogue.portrait_scale(id) / 1.9
		return 1.0

	func _draw() -> void:
		var s := _world_scale()
		var bob := absf(sin(_t * 12.0)) * 4.0 if _walking else 0.0
		draw_set_transform(Vector2(0, -bob), 0.0, Vector2(float(face) * s, s))
		StoryDialogue.draw_portrait(self, id, _t)
		draw_set_transform(Vector2.ZERO, 0.0, Vector2.ONE)

	func walk_to(x: float, time: float) -> void:
		face = 1 if x > global_position.x else -1
		_walking = true
		var tw := create_tween()
		tw.tween_property(self, "global_position:x", x, time)
		await tw.finished
		_walking = false

	func leap_to(x: float, time: float) -> void:
		face = 1 if x > global_position.x else -1
		var tw := create_tween()
		tw.tween_property(self, "global_position:x", x, time)
		tw.parallel().tween_method(func(k: float) -> void: position.y = get_parent().get("_ground_y") - sin(k * PI) * 160.0, 0.0, 1.0, time)
		await tw.finished

	## Up and away over everything (dir: +1 right), fading out.
	func leap_away(dir: int) -> void:
		face = dir
		var tw := create_tween()
		tw.tween_property(self, "global_position", global_position + Vector2(float(dir) * 900.0, -420.0), 1.0).set_trans(Tween.TRANS_QUAD).set_ease(Tween.EASE_OUT)
		tw.parallel().tween_property(self, "modulate:a", 0.0, 1.0)
		await tw.finished

	## Gone in a puff of red smoke.
	func vanish() -> void:
		Effects.explosion(self, global_position + Vector2(0, -80), 90.0, true, true)
		var tw := create_tween()
		tw.tween_property(self, "modulate:a", 0.0, 0.4)
