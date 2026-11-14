class_name GroundMessage
extends Node2D
## A glowing MESSAGE written on the ground (Souls style). Walk over it and it lights up and shows its
## text. Written by "other travellers" (fixed text, not online). Read messages are saved
## (StoryProgress.messages_read); reading 10 different ones unlocks an achievement.
##   GroundMessage.place(parent, pos, level_number, index)

const POOL := [
	"Try jumping", "Be wary of left", "Liar ahead", "Praise the CamTon!", "Visions of flask...",
	"Didn't expect boss...", "Time for block", "If only I had a flask...", "Amazing chest ahead",
	"Could this be a dead end?", "Weakness: back", "Don't give up, warrior!", "Hidden path ahead",
	"Be wary of ambush", "Seek stance break", "Gorgeous view ahead", "Hurrah for the Architect!",
	"I can't take this...", "Treasure... no.", "Visions of ultimate...", "Fort, night",
	"Ahh, the Storm...", "Enemy ahead, therefore run", "Strong foe ahead", "Behold, a pit!",
	"Hesitation is defeat", "Seek grass... nope, all dead", "Rest... if you can",
]
## Messages that only fit one level (written there instead of a random one)
const SPECIAL := {
	6: "Chemicals ahead, therefore try holding breath", 8: "Elevator ahead, therefore hold on",
	15: "Lava ahead, therefore jump", 24: "Hot... so hot...", 26: "Runes ahead",
	34: "Spider ahead, therefore cry", 36: "Child ahead. Be kind?", 39: "Two-handed foe ahead",
	45: "Fog ahead... what was I saying?", 47: "Mother ahead...", 49: "Liar ahead. Horns too.",
	50: "Praise the Sun!", 56: "Gong ahead, therefore cover ears", 62: "Catch him!",
	63: "Try rolling",
}
const AUTHORS := ["Pilgrim of Ash", "a fallen Warrior", "Nameless Builder", "the Cured", "a tired moth", "Someone"]

var text := ""
var key := ""
var author := ""
var player: Node2D
var _show := 0.0
var _t := 0.0
var _read := false


static func place(parent: Node, pos: Vector2, level_n: int, index: int, who: Node2D) -> GroundMessage:
	var m := GroundMessage.new()
	var rng := RandomNumberGenerator.new()
	rng.seed = level_n * 1000 + index * 37
	if index == 0 and SPECIAL.has(level_n):
		m.text = String(SPECIAL[level_n])
	else:
		m.text = String(POOL[rng.randi() % POOL.size()])
	m.key = "%d:%d" % [level_n, index]
	m.author = "- %s" % AUTHORS[rng.randi() % AUTHORS.size()]
	m.player = who
	m.position = pos
	m.z_index = -1                                   # On the floor, behind the fighters
	parent.add_child(m)
	return m


func _process(delta: float) -> void:
	_t += delta
	var near := player != null and is_instance_valid(player) and absf(player.global_position.x - global_position.x) < 110.0 \
		and absf(player.global_position.y - global_position.y) < 200.0
	_show = move_toward(_show, 1.0 if near else 0.0, delta * 3.0)
	if near and not _read:
		_read = true
		SoundManager.play_sfx("holy", -14.0)
		StoryProgress.load_progress()
		if not StoryProgress.messages_read.has(key):
			StoryProgress.messages_read.append(key)
			StoryProgress.save_progress()
			if StoryProgress.messages_read.size() >= 10 and not StoryManager.autoplay:
				Achievements.unlock("messages_10")
	queue_redraw()


func _draw() -> void:
	# The glowing scrawl on the ground
	var glow := 0.45 + 0.2 * sin(_t * 2.0) + 0.35 * _show
	draw_colored_polygon(EnemyArt.ellipse_points(Vector2(0, -2), 46, 7, 18), Color(1.0, 0.55, 0.2, 0.16 * glow))
	var c := Color(1.0, 0.72, 0.35, 0.75 * glow)
	for i in 5:
		var x := -34.0 + float(i) * 15.0
		draw_line(Vector2(x, -2 + sin(float(i) * 2.1) * 2.0), Vector2(x + 9.0, -4 + cos(float(i) * 1.7) * 2.0), c, 2.0)
	if _show > 0.02:
		var a := _show
		FighterArt.label(self, Vector2(0, -232), text, 20, Color(1.0, 0.88, 0.6, a))      # Above the name tags
		FighterArt.label(self, Vector2(0, -210), author, 13, Color(0.85, 0.8, 0.72, 0.7 * a))
