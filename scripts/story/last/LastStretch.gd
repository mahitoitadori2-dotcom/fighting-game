class_name LastStretch
extends RefCounted
## THE LAST STRETCH's last level (148, "ls_end"): Halcyon is burning. The Architect walks into the
## throne hall; a short talk with THE KING OF HALCYON (Stormism against Frepasm), then the Architect
## drives his hand through the king's chest. Cutscene "ls_free": back to the cells, the Warrior and the
## Nightmare Lord walk out. A last word between the three, then cutscene "ls_bridge": a bridge of light
## builds itself out of the fire up into the Storm, and they walk onto it. The end of this part.
## Await play() from the StoryManager (before LEVEL CLEAR).

const KING_TALK := [
	["narrator", "The fire has reached the throne hall. The king of Halcyon has not moved from his throne."],
	["king", "So the Storm's prisoner comes to the Storm's king."],
	["H", "Your guards are in pieces. Your town is burning. Your god didn't come."],
	["king", "The Storm does not COME, child. It is always here. It watches. It judges. It protects us from things like you."],
	["king", "Grade FTE. We were warned about you two. We did what any faithful town would do."],
	["H", "In the Architectium I waited for a god too. One who would bring us supplies, and knowledge. He never came."],
	["H", "So I found something better. Peace and freedom for the good. Pain and enclosure for the evil."],
	["king", "Frepasm. A rebel's prayer. And which am I, Architect?"],
	["H", "You put three travellers in cages because your god told you to. You were going to hand us to it at dawn."],
	["king", "The Storm will take you the moment you set foot outside these walls."],
	["H", "Then I'll walk into it."],
]
const KING_LAST := [
	["king", "...The Storm... saw that..."],
	["H", "Good. Let it."],
]
const REUNION := [
	["warrior", "The whole town's on fire. What did you DO out there?"],
	["nightmare_lord", "I could smell it from my cell. Smoke, fear, and a king's last breath. You have been busy, Architect."],
	["warrior", "Everything stopped. I felt it. The rain just... hung there."],
	["H", "I went inside myself. Everything I was afraid of was waiting at the bottom. I'm done being afraid."],
	["nightmare_lord", "The ninth lock gives the power of time to ONE person on this world. I used to wonder who."],
	["nightmare_lord", "...I do not wonder any more."],
	["warrior", "No gods, no kings, no cages. Fine by me."],
	["narrator", "Above the burning town the Storm turns, slowly, like an eye. And out of the fire, something begins to build itself."],
	["H", "A bridge. Into the Storm."],
	["warrior", "Then we walk."],
]


static func play(m: StoryManager) -> void:
	CombatManager.fight_active = false
	m.wave_text = ""
	m._clear_hazards()
	m._letterbox(true)
	var px := m.player.global_position.x
	var king := KingActor.new()
	king.position = Vector2(px + 560.0, m._ground_y)
	king.z_index = 2
	m.add_child(king)
	ArenaCamera.focus = king
	ArenaCamera.focus_zoom = 0.95
	await _walk(m, m.player, px + 300.0, 1.6)
	await NightmareOffer._talk(m, KING_TALK)
	# The hand through his chest
	await _walk(m, m.player, king.global_position.x - 62.0, 0.35)
	Engine.time_scale = 0.35
	SoundManager.play_sfx("sword_slash")
	SoundManager.play_sfx("punch", -2.0)
	Effects.shake(m, 14.0)
	Effects.hit_sparks(king, king.global_position + Vector2(0, -70), 18, 1.6)
	var tw := king.create_tween()
	tw.tween_property(king, "hurt", 1.0, 0.5)
	await m._wait(0.6)
	Engine.time_scale = 1.0
	await NightmareOffer._talk(m, KING_LAST)
	var fall := king.create_tween()
	fall.tween_property(king, "rotation", -PI * 0.5, 0.7).set_trans(Tween.TRANS_QUAD).set_ease(Tween.EASE_IN)
	fall.parallel().tween_property(king, "position:y", king.position.y - 10.0, 0.7)
	SoundManager.play_sfx("slam", -4.0)
	await m._wait(1.2)
	if not StoryManager.autoplay:
		Achievements.unlock("ls_king")
	# Back to the cells (cutscene), then the three of them together
	await m._play_cutscene("ls_free")
	king.queue_free()
	var war := NightmareOffer.Actor.spawn(m, "warrior", Vector2(px - 120.0, m._ground_y), 1)
	var nl := NightmareOffer.Actor.spawn(m, "nightmare_lord", Vector2(px - 230.0, m._ground_y), 1)
	m.player.global_position.x = px
	m.player.facing = -1
	ArenaCamera.focus = m.player
	await NightmareOffer._talk(m, REUNION)
	await m._play_cutscene("ls_bridge")
	war.queue_free()
	nl.queue_free()
	ArenaCamera.focus = null
	m._letterbox(false)
	if StoryManager.autoplay:
		print("STORY autoplay: the last stretch ends (king, free, bridge)")


## Walk a fighter to x (a scripted step: the fight is paused).
static func _walk(m: StoryManager, f: Fighter, x: float, time: float) -> void:
	f.facing = 1 if x > f.global_position.x else -1
	var tw := m.create_tween()
	tw.tween_property(f, "global_position:x", x, time)
	await tw.finished


## The king in the scene (HalcyonKing art), with the wound (hurt 0..1).
class KingActor extends Node2D:
	var hurt := 0.0
	var _t := 0.0

	func _process(delta: float) -> void:
		_t += delta
		queue_redraw()

	func _draw() -> void:
		draw_set_transform(Vector2.ZERO, 0.0, Vector2(-1, 1))          # Faces left (towards you)
		HalcyonKing.draw_king(self, _t, hurt)
		draw_set_transform(Vector2.ZERO, 0.0, Vector2.ONE)
