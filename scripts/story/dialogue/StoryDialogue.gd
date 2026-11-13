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
	# ----- THE ENLIGHTENED CHASE (placeholders) -----
	51: [["enlightened", "You saw. You SAW, didn't you?"],
		["H", "Everything. Stop running."],
		["enlightened", "Running? I am LEAVING. There is a difference, little one."],
		["enlightened", "Guards! Show this creature what devotion looks like."]],
	52: [["enlightened", "Still behind me? How tiresome."],
		["H", "I'll be behind you until there is nowhere left to run."],
		["enlightened", "Riders, turn back. Trample it."]],
	53: [["enlightened", "My caravan. My spears. My camels. All of it, mine."],
		["H", "Then it's all in my way."]],
	54: [["H", "Statues. Every one of them wears your face."],
		["enlightened", "Of course. Who else deserves the stone?"]],
	55: [["enlightened", "Do you hear the gongs? My First Prime is waiting for you."],
		["H", "Then I won't make him wait long."]],
	57: [["enlightened", "Drink from the oasis, little one. The water never lies... mostly."],
		["H", "I'm not thirsty."]],
	58: [["H", "Are you even here?"],
		["enlightened", "Am I? Strike the mirage and find out."]],
	59: [["H", "You set your own caravan on fire."],
		["enlightened", "Things burn. I do not."]],
	60: [["enlightened", "The road ends here. Look up: the sky is turning gold for me."],
		["H", "It will turn red soon enough."]],
	61: [["enlightened", "My last guard. My gates. My stairway into the sky."],
		["enlightened", "You will never touch a single step."],
		["H", "Watch me."]],
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
	# ----- THE ENLIGHTENED CHASE (placeholders) -----
	56: [["first_prime", "Turn back."],
		["H", "Move aside. I'm not here for you."],
		["first_prime", "The Light does not forgive. Neither does my gong."]],
	62: [["H", "No more running."],
		["enlightened", "Running? I was waiting for an audience worthy of me."],
		["enlightened", "You want me? Then CATCH EVERYTHING I OWN."]],
}

const NAMES := {
	"enlightened": "THE ENLIGHTENED ONE", "blinded_lord": "THE BLINDED LORD", "architect_chorus": "ARCHITECT CHORUS",
	"blasphemy_caeser": "BLASPHEMY CAESER", "forge_mother": "THE FORGE MOTHER", "arch_golem": "THE ARCHITECT'S GOLEM",
	"void_massacre": "THE VOID MASSACRE", "needle": "CHILD WIELDING NEEDLE", "brothers": "THE BROTHERS",
	"animal_lord": "ANIMAL LORD", "executor": "EXECUTOR", "mother_nature": "MOTHER NATURE", "false_god": "THE FALSE GOD",
	"satan": "SATAN", "the_sun": "THE SUN", "first_prime": "THE FIRST PRIME", "narrator": "",
}

## Portrait scale (portraits are drawn feet-at-origin; this makes them ~230 px tall).
const SCALE := {"warrior": 1.9, "architect": 1.9, "enlightened": 1.9, "architect_chorus": 0.42, "blasphemy_caeser": 0.78,
	"forge_mother": 0.74, "arch_golem": 0.7, "void_massacre": 0.56, "needle": 1.6, "brothers": 1.5, "first_prime": 1.15}


## The lines for a level ("opening" / "boss"), speakers resolved to real ids. [] = no dialogue.
static func lines_for(n: int, kind: String, hero: String, partner: String) -> Array:
	var src: Dictionary = OPENING if kind == "opening" else BOSS
	if not src.has(n) or StoryLevels.is_open_world(n):
		return []
	var out: Array = []
	for l in src[n]:
		var who := String(l[0])
		if who == "H":
			who = hero
		elif who == "P":
			if partner == "":
				continue                                   # SOLO: the partner isn't here to talk
			who = partner
		out.append([who, String(l[1])])
	return out


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
		_:
			StoryLevels.draw_portrait(c, id, t)
