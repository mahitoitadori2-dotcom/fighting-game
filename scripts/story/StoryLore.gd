class_name StoryLore
extends RefCounted
## LORE ITEMS (Souls style): every Story boss leaves an item behind; its short, cryptic text tells a
## piece of the story. Found items are saved (StoryProgress.lore) and read in the CODEX (Story
## board). Order = the order they are found in the story.
##   StoryLore.collect("blinded_lord")  -> the item's name ("" if it was found before / unknown)

const ITEMS := [
	["blinded_lord", "Cracked Lens of the Blinded Lord",
		"A lens ground from the glass of a broken chamber. The first keeper of the first Colosseum once watched the fights through it, and wrote down how each challenger died.\n\nIn the end he looked too long at what the cure had made of the others, and asked for his eyes to be taken."],
	["architect_chorus", "Rusted Hymn-Plate",
		"An iron plate stamped with notes no throat can sing. The Chorus were builders who climbed the shaft before you, and fell.\n\nThey were cured, as all the fallen are. Now they sing the only hymn left to them: no one leaves."],
	["blasphemy_caeser", "Serpent Fang of the Devourer",
		"A fang as long as a sword, still warm. Caeser swallowed gods because gods were the only things in the arena larger than itself.\n\nIt did not know that each god it ate had been a challenger once, cured and crowned for the crowd."],
	["forge_mother", "Ember of the Ever-Forge",
		"A coal that has not cooled in a hundred years. The Forge Mother hammered the cages of the Colosseums, and the chains of the cured.\n\nShe was proud of her work. That is the saddest thing written of her."],
	["arch_golem", "Rune-Stone of the Golem",
		"A fist of carved stone, its rune gone dark. The Architect built the Golem to guard his hall while he was away.\n\nHe never came back for it. It never stopped guarding."],
	["void_massacre", "Sixteenth Eye",
		"A single black eye, still wet. The Massacre spun webs from the threads of every soul that fell into the Void.\n\nThe Shining was the only light it ever feared. Whether that light still burns depends on you."],
	["needle", "Needle of Silver Thread",
		"A sewing needle the size of a spear. The child sewed shut the wounds of the cured so they could fight again, and hummed so they would not scream.\n\nNobody ever asked the child's name. Nobody ever told the child it could stop."],
	["brothers", "Half of a Broken Hilt",
		"Half of one sword's hilt. The Brothers entered the arena together and swore to leave it together.\n\nThe cure kept that promise for them, in its own way."],
	["animal_lord", "Stitched Hide",
		"A patch of fur, scale and feather sewn into one. When the beasts of this world died out, the crowd still wanted beasts.\n\nSo the Colosseum made one out of all of them."],
	["executor", "Grey Hood of Forgetting",
		"A hood that smells of the purple fog. The Executor carried out every sentence the crowd shouted, and forgot each face at once.\n\nHe was the only one in the Colosseums who slept well."],
	["mother_nature", "Seed of the First Tree",
		"A seed that will not grow on this world any more. She was not a challenger. She was the land itself, and she was tired.\n\nWhat crawled out of her ashes wore her face. She would not have wanted that."],
	["false_god", "Ash Mask",
		"The face the False God wore when it called itself Nature. Under it there was only fire, and fire only wants more.\n\nIts prayers were stolen. Its believers were not."],
	["satan", "Horn of the Last Gate",
		"A broken horn, black as the cave. Satan kept the way to the peak, and laughed at every hero who climbed this far.\n\nHe was not evil. He was the last test, and he was bored."],
	["the_sun", "Wing-Scale of the Sun",
		"A dust of light rubbed off a great wing. The Sun was a moth that grew too large to ever reach the light it loved, so it became the light.\n\nLittle moths still fly to it. It still burns them, gently."],
	["first_prime", "Holy Gong Shard",
		"A shard of the First Prime's gong. Every strike of it called the faithful to the stands.\n\nThe First Prime was the Enlightened One's oldest shield. When it broke, the king finally understood he was afraid."],
	["enlightened_one", "Crown of the Enlightened One",
		"A golden crown, lighter than it looks. The king made it a royal law that no one may ever leave this planet, and built the Colosseums to keep the people busy and afraid.\n\nHe told everyone it was to keep them safe from the Storm. That part was true."],
	["tribe_master", "Bone Crown",
		"The crown of the Tribe Master, made of the bones of the last beasts. In DemiLand the primitive people still wait for a hero who never came.\n\nOne of the two heroes did come. Just not the one they prayed for."],
	["last_tiger", "Tiger's Fang",
		"The fang of the Last Tiger. When everything else died out, it kept hunting, because nobody told it the hunt was over.\n\nThe Ancient Door hungers for it. Nobody knows why."],
	["tree_lord", "Living Heart",
		"A heart of wood that still beats. The Tree Lord was the last thing in DemiLand that grew.\n\nIt did not want the Door opened. It knew what was behind it."],
	# ----- Terra Craterum -----
	["lava_melter", "Melter's Eye",
		"A rock that was an eye of the Lava Melter. It is still hot - it will be hot for a hundred years.\n\nThe pillar did not hate the Kharlemings. It only stood where the lava told it to stand: in front of the wall."],
	["kharleming_lord", "Lord's Feather",
		"A feather of steel from the Kharleming Lord. Horns, wings, a tail with a sting: it carried a piece of every Kharleming that ever lived.\n\nThe ship it was born in never flew again. It never stopped trying to make it fly."],
	["technician_breaker", "The Technician's Breaker",
		"An ancient device of the Kharlemings. One click, and every Kharleming nearby begins to glow... and then a whole colony is gone.\n\nThey built it for the day the lava wins. That day comes often in Terra Craterum."],
	# ----- Terra Ordinariorum -----
	["lightning_candle", "The Lightning Candle",
		"A candle of grey stone with a flame of living lightning. It was made on the mountain by the crystals of the Great Freezing.\n\nIt has one purpose: to open an entrance to the Storm."],
	["crystal_swarm", "The Frozen Scroll",
		"A scroll of ice that never melts. It tells of THE GREAT FREEZING: a time when the Storm was at its highest and could not control itself. It threw crystals everywhere, and where they fell came ice and snow.\n\nThe crystals were sentient. They climbed the mountains, made the Lightning Candle, and used it on the Storm to open its main entrance. That is the candle's purpose.\n\nIt is a reminder. Go to the town. Light the candle."],
	["storm_finger", "The Ordinariorum Ticket",
		"An old paper ticket with a gold seal, torn from the Storm's own hand. No one leaves Terra Ordinariorum without one.\n\nThe townsfolk never needed one. They never wanted to leave. They never even looked up."],
	# ----- Boss Extensions -----
	["caeser_grave", "Grave-Dust of the Devourer",
		"A pinch of dust from the Caeser's crypt. Even dead, the serpent kept its followers: they carried its bones below the arena and prayed to them.\n\nIt devoured gods. In the end it could not devour the one thing that always wins: the cure."],
	["saint_golem", "Sanctified Rune",
		"A rune the saints of the Rocks carved into the Golem when they found it waiting in the empty hall. They rebuilt it, blessed it, and called it holy.\n\nThe Golem did not notice. It was still guarding a hall for an Architect who was never coming back."],
	["void_horrid", "Three-Eyed Shard",
		"A shard of black glass with three reflections in it, though only one hand holds it. The Horrids were challengers who fell into the Void together.\n\nThe cure stitched them into one hunger. They still argue about whose turn it is to eat."],
	["rad_chorus", "Glowing Hymn-Plate",
		"A hymn-plate that will not stop glowing. When the reactor broke, the Chorus did not run. They sang louder.\n\nWhat is left of them sings the meltdown, note by note, to anyone who comes down to listen."],
	["forge_father", "Hammer-Head of the First Forge",
		"The head of a hammer older than the Colosseums. The Forge Father built the Forge Mother, and called her weak when she cooled.\n\nHe forged the first cage the Enlightened One ever ordered. He never asked who it was for."],
	# ----- The True Hunt -----
	["nightmare_monstrosity", "Smith's Tally of the Nine Locks",
		"A slate from the Clan's forge, scratched with nine marks. Six are crossed out: the Alert, the Deconstructors, the Storm Seed, the Kharleming Constitution, Einstein's Theorem, the Core Ignition.\n\nThe last three are circled again and again: THE GREAT DEACCELERATOR. DECOMPOSITION. FULL TIME REVERSAL. Under them, in a shaking hand: \"if the seventh shuts, we stop growing. if the eighth, they come. if the ninth... pray it is one of us.\""],
]

static func count() -> int:
	return ITEMS.size()


static func item(id: String) -> Array:
	for it in ITEMS:
		if String(it[0]) == id:
			return it
	return []


static func has(id: String) -> bool:
	StoryProgress.load_progress()
	return StoryProgress.lore.has(id)


## The boss `id` fell: its lore item is found (saved). Returns its name, or "" (unknown / old).
static func collect(id: String) -> String:
	var it := item(id)
	if it.is_empty() or has(id):
		return ""
	StoryProgress.lore.append(id)
	StoryProgress.save_progress()
	if StoryProgress.lore.size() >= count():
		Achievements.unlock("lore_all")
	elif StoryProgress.lore.size() >= 5:
		Achievements.unlock("lore_5")
	return String(it[1])
