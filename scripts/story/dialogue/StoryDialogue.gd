class_name StoryDialogue
extends RefCounted
## WHO SAYS WHAT before the important Story fights (DialogueBox shows it, the game frozen).
##
##   OPENING[level]  plays when the level starts (Colosseum openings, every Enlightened Chase level)
##   BOSS[level]     plays when the boss has arrived, right before "FIGHT!" (mini-bosses + bosses)
##
## Speakers: "H" = the hero you play, "P" = your partner (Colosseum 5; the line is skipped when you
## play SOLO), "enlightened" = The Enlightened One, anything else = an enemy id from StoryLevels.
## DemiLand has no dialogue. THE ENLIGHTENED CHASE lines are placeholders until the real lore.

const OPENING := {
	# ----- Colosseum 1: The Ashen Depths -----
	1: [["H", "...Ash. Nothing but ash, as far as I can see."],
		["H", "Something is breathing under it. Let it come."]],
	# ----- Colosseum 2: The Ascent -----
	7: [["H", "The elevator is rising. Out of hell... finally."],
		["H", "And things are climbing the shaft behind me. Of course they are."]],
	# ----- Colosseum 3: The Burning Crown -----
	16: [["H", "An empty throne. On fire."],
		["H", "Whoever sat here is long gone. Whatever is moving up there... is not."]],
	# ----- Colosseum 4: The Void Below (the Architect) -----
	27: [["H", "I rolled all the way down. Every bone in me counted the rocks."],
		["H", "It's dark here. Darker than it should be. Something black is crawling toward me."]],
	# ----- Colosseum 5: The Final Ascent -----
	35: [["H", "Two of us. One road."],
		["P", "And on top of the mountain, something that shines."],
		["H", "Whatever it is, we climb to it together."],
		["P", "Then let's not keep it waiting."]],
	# ----- THE ENLIGHTENED CHASE -----
	# The Colosseums belong to the Enlightened One's land: he took people and watched them fight for
	# fun; whoever died was cured and became an enemy for the next challenger. The Warrior and the
	# Architect (he trapped them both) were the first to kill every single one, setting them all free
	# to go to heaven or hell. Scared they would come for him, he struck the one you did NOT pick
	# with one of his strongest attacks, and ran. He hides his fear... until the First Prime falls.
	51: [["enlightened", "You two. The first ever to empty my Colosseums."],
		["enlightened", "Every fighter you killed walked free. To heaven, to hell... anywhere but MY arenas."],
		["H", "You trapped us down there. You watched us fight for your entertainment."],
		["enlightened", "And it WAS entertaining. Until you started winning."],
		["H", "You hit {O} with everything you had. And now you run."],
		["enlightened", "Run? A king does not run. A king... relocates. Guards! Keep this one busy."]],
	52: [["enlightened", "Still following? My riders will trample you into the sand."],
		["H", "Your riders. Your guards. People you stole, like us."],
		["enlightened", "They are MINE. Everyone on this planet is mine."]],
	53: [["enlightened", "A whole caravan stands between us. Spears, shields, camels."],
		["H", "Then I go through all of it."],
		["enlightened", "...Fine. FINE. There are always more."]],
	54: [["H", "Statues. Every one of them wears your face."],
		["enlightened", "Admire them. Kneel to them. Just... stop chasing me."],
		["H", "No."]],
	55: [["enlightened", "Do you hear the gongs? My First Prime has never lost. Never."],
		["H", "Neither had your Colosseums."],
		["enlightened", "...Hmph. He will end you. He has to."]],
	57: [["enlightened", "Drink from the oasis. Rest. Turn around. PLEASE turn around."],
		["H", "You sound afraid."],
		["enlightened", "I am NOT afraid! Guards! GUARDS!"]],
	58: [["H", "Are you even here?"],
		["enlightened", "I am everywhere! I am the Light! ...Strike the mirage and see."]],
	59: [["H", "You set your own caravan on fire."],
		["enlightened", "If I cannot have a wall of men, I will have a wall of FIRE!"]],
	60: [["enlightened", "The sky is turning gold. It turns gold for ME. Never for you!"],
		["H", "Your road. Your guards. Your statues. There is nothing left between us."]],
	61: [["enlightened", "My last guards. My gates. My stairway."],
		["enlightened", "If they fall... then I am..."],
		["H", "Alone."],
		["enlightened", "STOP THEM! SOMEBODY STOP THEM!"]],
}

## After the boss is dead (after its death scene / before the finale cutscene).
const AFTER := {
	# The First Prime falls: he finally SHOWS that he is scared
	56: [["enlightened", "No... no, no, NO. He was my strongest!"],
		["enlightened", "Who is left?! Who stands between me and YOU?"],
		["H", "Nobody."],
		["enlightened", "Stay away from me! STAY AWAY!"]],
	# The Enlightened One beaten: he was meant to die... and is spared
	62: [["enlightened", "...So this is how it ends."],
		["enlightened", "So many champions thrown into my arenas to die... and in the end, it was me who was meant to die."],
		["H", "Maybe. But I'm not you."],
		["H", "You kept people in cages and watched them die. I won't do the same to you."],
		["enlightened", "...You are sparing me?"],
		["H", "Go. Before I change my mind."]],
}

## THE STORM: right after the "enl_end" cutscene (the dark cloud forms), the last talk of the Chase.
const STORM := {
	62: [["enlightened", "Wait. Look. The debris... everything I threw at you is rising."],
		["H", "You're pulling it up there?"],
		["enlightened", "No! I never send anything up there. That is not me..."],
		["enlightened", "It's the Storm. The legend was TRUE."],
		["O", "...I could hear the thunder from the dunes. What is that thing?"],
		["enlightened", "When I was a child they told us the legend. The Storm sees everything. It lives, it breathes... like one giant organism."],
		["enlightened", "It appears when there is a chance that creatures will leave this planet. It guards the sky. Nothing gets out."],
		["enlightened", "I was so afraid it would come and kill everyone I knew. So when I became king, I made it a royal rule for the entire planet: no one leaves."],
		["enlightened", "My guards kept everyone in. But now I have no guards left..."],
		["enlightened", "The Storm thinks nothing stops anyone from leaving anymore. It is waking up. Fully."],
		["H", "...I won't lie. That scares me a little."],
		["H", "But I faced everything in your arenas. I'll face this head on. I want to know more about the Storm."],
		["enlightened", "Then go to Orbis Terrarum. If anyone knows the Storm, it is there."],
		["enlightened", "But no one simply walks in. You will have to travel through every land of this planet to earn a ticket."],
		["H", "Then that's what I'll do."],
		["H", "But first: heal {O}. You did that. Fix it."],
		["enlightened", "...That is the least a fallen king can do."],
		["O", "Don't get used to being forgiven."]],
}

const BOSS := {
	# ----- Colosseum 1 -----
	6: [["blinded_lord", "Who dares crawl into MY pit...?"],
		["H", "Someone who has been crawling for too long."],
		["blinded_lord", "I cannot see you. I do not NEED to see you!"]],
	# ----- Colosseum 2 -----
	8: [["architect_chorus", "WE... ARE... THE CHORUS."],
		["H", "Get off my elevator."],
		["architect_chorus", "YOU... DO NOT... LEAVE."]],
	15: [["blasphemy_caeser", "I have devoured GODS."],
		["H", "Then you know what it feels like when something bigger bites back."],
		["blasphemy_caeser", "You are barely a morsel."]],
	# ----- Colosseum 3 -----
	24: [["forge_mother", "THE FORGE...  NEVER...  COOLS."],
		["H", "Everything cools. Eventually."]],
	26: [["arch_golem", "...INTRUDER."],
		["H", "The Architect built you. Let's see how well."],
		["arch_golem", "...DISMANTLE."]],
	# ----- Colosseum 4 -----
	34: [["void_massacre", "*the clicking of sixteen legs*"],
		["H", "Sixteen eyes. And every one of them is on me."],
		["void_massacre", "*click. click. click.*"]],
	# ----- Colosseum 5 -----
	36: [["needle", "Will you play with me?"],
		["H", "...A child? Here?"],
		["P", "Careful. Look at what she is holding."],
		["needle", "Hold still..."]],
	39: [["brothers", "One blade."],
		["H", "...Two hands."],
		["brothers", "As one."]],
	42: [["animal_lord", "*a roar in a dozen voices*"],
		["H", "It's stitched together from everything that ever lived down here."],
		["P", "Then we cut the stitches."]],
	45: [["executor", "The court is in session."],
		["H", "What is the charge?"],
		["executor", "You came this far. The sentence... is DEATH."]],
	47: [["mother_nature", "You walked all this way to kill your MOTHER?"],
		["H", "You stand between us and the peak."],
		["mother_nature", "Then come, children. Fire, water, earth and wind... all at once."]],
	48: [["false_god", "You prayed to her."],
		["H", "We never prayed to anyone."],
		["false_god", "Then you will BURN for ME."]],
	49: [["satan", "So. The little heroes came to my door."],
		["P", "Move, or be moved."],
		["satan", "Heh. The lava rises... and so do I."]],
	50: [["the_sun", "Little moth..."],
		["H", "We came all this way for you."],
		["the_sun", "Then fly to the light."]],
	# ----- THE ENLIGHTENED CHASE -----
	56: [["first_prime", "Turn back. The Light does not forgive."],
		["H", "Your king is hiding behind you."],
		["first_prime", "Then I will be the wall he hides behind."]],
	# The last level: he goes CRAZY for his life
	62: [["H", "No more running."],
		["enlightened", "Running? HA! HAHAHA! I'm not running... I'm SURVIVING!"],
		["enlightened", "No guards, no Prime, no walls... FINE! I'll do it MYSELF!"],
		["enlightened", "You want me? Then CATCH EVERYTHING I OWN! EVERYTHING!"]],
}

const NAMES := {
	"enlightened": "THE ENLIGHTENED ONE", "blinded_lord": "THE BLINDED LORD", "architect_chorus": "ARCHITECT CHORUS",
	"blasphemy_caeser": "BLASPHEMY CAESER", "forge_mother": "THE FORGE MOTHER", "arch_golem": "THE ARCHITECT'S GOLEM",
	"void_massacre": "THE VOID MASSACRE", "needle": "CHILD WIELDING NEEDLE", "brothers": "THE BROTHERS",
	"animal_lord": "ANIMAL LORD", "executor": "EXECUTOR", "mother_nature": "MOTHER NATURE", "false_god": "THE FALSE GOD",
	"satan": "SATAN", "the_sun": "THE SUN", "first_prime": "THE FIRST PRIME", "narrator": "", "stranger": "THE STRANGER",
}

## Portrait scale (portraits are drawn feet-at-origin; this makes them ~230 px tall).
const SCALE := {"stranger": 1.85, "warrior": 1.9, "architect": 1.9, "enlightened": 1.9, "architect_chorus": 0.42, "blasphemy_caeser": 0.78,
	"forge_mother": 0.74, "arch_golem": 0.7, "void_massacre": 0.56, "needle": 1.6, "brothers": 1.5, "first_prime": 1.15}


## The lines for a level ("opening" / "boss"), speakers resolved to real ids. [] = no dialogue.
## kind: "opening" / "boss" / "after" / "storm". "O" = the OTHER hero (always there: the Chase's
## injured one); "{O}" / "{H}" in a line = that hero's name.
static func lines_for(n: int, kind: String, hero: String, partner: String) -> Array:
	var src: Dictionary = {"opening": OPENING, "boss": BOSS, "after": AFTER, "storm": STORM}.get(kind, {})
	if not src.has(n) or StoryLevels.is_open_world(n):
		return []
	var other := "architect" if hero == "warrior" else "warrior"
	var out: Array = []
	for l in src[n]:
		var who := String(l[0])
		if who == "H":
			who = hero
		elif who == "O":
			who = other
		elif who == "P":
			if partner == "":
				continue                                   # SOLO: the partner isn't here to talk
			who = partner
		var text := String(l[1]).replace("{O}", StoryLevels.hero_name(other).capitalize()).replace("{H}", StoryLevels.hero_name(hero).capitalize())
		out.append([who, text])
	return out


## DEMILAND'S STRANGER (lore by the user, 2026-11-14): the only one in DemiLand who is still SANE.
## DemiLand is the barriered region of the planet: no one can enter or leave. Abandoned and cursed;
## no advancements were ever made inside, so the walls were never broken. He has been stuck here for
## 10 years. The Ancient Door was open, but its artifacts were given to the Lords of DemiLand, who
## were born with genetic mutations that made them strong.
## One set of talks per stage of the journey (0..3 Lords beaten); each talk is one visit, the last
## one repeats. "H" = your hero.
const STRANGER := [
	# Stage 0: the first meeting / asking about the Ancient Door
	[[["stranger", "...You can see me? You can HEAR me? Then you are not one of them."],
		["stranger", "Forgive me. It has been a long time since anyone answered me with words instead of teeth."],
		["H", "Where am I?"],
		["stranger", "DemiLand. The barriered region of this planet. No one can enter it. No one can leave it."],
		["stranger", "It was abandoned long ago, and cursed. And in here, nobody ever made anything new. No tools, no machines. Nothing."],
		["stranger", "So the walls were never broken. Not once."],
		["H", "How long have you been here?"],
		["stranger", "Ten years. I have walked every wall of this land, and I never found a way out."],
		["stranger", "I am the only one left who still... thinks. The others forgot how."]],
	[["H", "What about the Ancient Door?"],
		["stranger", "The Door. It was open, once."],
		["stranger", "But the artifacts that open it were given away. To the Lords of DemiLand."],
		["stranger", "Three Lords. Three artifacts. Bring them back to the Door... and perhaps it remembers how to open."]]],
	# Stage 1: one Lord is dead / asking about the Lords
	[[["stranger", "You... you killed one of them. In ten years I never saw a Lord fall."],
		["H", "Who are the Lords?"],
		["stranger", "They were born here, like everyone else in DemiLand. But they were born... wrong."],
		["stranger", "Mutations. Something in their blood from the day they were born. It made them stronger than anything else in this land."],
		["stranger", "So the people gave them the artifacts. Who else could keep them safe?"]],
	[["stranger", "Two Lords left. Two artifacts. Rest at the CamTons when you can. The flames remember you."]]],
	# Stage 2: two Lords are dead
	[[["stranger", "Two. TWO. Ten years I waited, and you do it in a day."],
		["stranger", "The last Lord will not give up its artifact easily. None of them were ever... kind."],
		["H", "If the Door opens, what then?"],
		["stranger", "Then for the first time in ten years, I will have something to hope for."]],
	[["stranger", "Go. I will wait here. I am very good at waiting."]]],
	# Stage 3: all three artifacts are free
	[[["stranger", "All three. You actually have all three."],
		["stranger", "Put them in the Door. I do not know what is behind it. Nobody does."],
		["stranger", "But whatever it is... it is not this place."],
		["H", "Come with me."],
		["stranger", "...When it opens. Not before. I have stood at that Door too many times to trust it."]],
	[["stranger", "Go on. Open it. I will be right behind you."]]],
]


## The stranger's talk for this stage of the journey and this visit.
static func stranger_talk(stage: int, visit: int) -> Array:
	var talks: Array = STRANGER[clampi(stage, 0, STRANGER.size() - 1)]
	return talks[clampi(visit, 0, talks.size() - 1)]


## The stranger: a tall hood, a ragged cloak, two pale eyes and a swinging lantern (feet at 0, 0).
static func draw_stranger(c: CanvasItem, t: float) -> void:
	var sway := sin(t * 1.3) * 2.0
	var cloak := PackedVector2Array([Vector2(-26, 0), Vector2(-20, -52), Vector2(-16 + sway * 0.3, -96), Vector2(0 + sway * 0.5, -118),
		Vector2(16 + sway * 0.3, -96), Vector2(22, -50), Vector2(28, 0), Vector2(14, -6), Vector2(4, 0), Vector2(-8, -5)])
	c.draw_colored_polygon(cloak, Color(0.13, 0.11, 0.12))
	c.draw_polyline(cloak + PackedVector2Array([cloak[0]]), Color(0, 0, 0), 3.0)
	c.draw_colored_polygon(EnemyArt.ellipse_points(Vector2(sway * 0.5, -100), 11, 10, 16), Color(0.02, 0.02, 0.03))   # The dark inside of the hood
	var blink := fmod(t, 4.0) < 0.12
	if not blink:
		for ex in [-4.0, 4.0]:
			c.draw_circle(Vector2(sway * 0.5 + ex, -101), 2.2, Color(0.85, 0.9, 1.0))
	# Staff and lantern
	c.draw_line(Vector2(20, 0), Vector2(22, -86), Color(0.30, 0.20, 0.12), 4.0)
	var lp := Vector2(22, -86) + Vector2(sin(t * 2.0) * 4.0, 14.0)
	c.draw_line(Vector2(22, -86), lp, Color(0.2, 0.2, 0.2), 1.5)
	c.draw_circle(lp + Vector2(0, 6), 14.0, Color(1.0, 0.6, 0.25, 0.18))
	c.draw_rect(Rect2(lp + Vector2(-5, 0), Vector2(10, 12)), Color(1.0, 0.72, 0.35))
	c.draw_rect(Rect2(lp + Vector2(-5, 0), Vector2(10, 12)), Color(0.1, 0.08, 0.06), false, 1.5)


static func name_of(id: String) -> String:
	if id == "warrior" or id == "architect":
		return StoryLevels.hero_name(id)
	return String(NAMES.get(id, id.to_upper().replace("_", " ")))


## Which voice blip a speaker uses (Blips.PROFILES).
static func blip_of(id: String) -> String:
	return id if Blips.PROFILES.has(id) else "narrator"


static func portrait_scale(id: String) -> float:
	if SCALE.has(id):
		return float(SCALE[id])
	return float(StoryBoard.FIGURE_SCALE.get(id, 0.3)) * 6.0      # The board's tile size, made big


static func draw_portrait(c: CanvasItem, id: String, t: float) -> void:
	match id:
		"warrior", "architect":
			StoryLevels.hero_art(id).call("draw_portrait", c, t)
		"enlightened":
			EnlightenedOneArt.draw_portrait(c, t)
		"stranger":
			draw_stranger(c, t)
		_:
			StoryLevels.draw_portrait(c, id, t)
