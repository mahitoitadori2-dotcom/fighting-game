class_name AchievementToast
extends CanvasLayer
## "ACHIEVEMENT UNLOCKED" pop-up on the LEFT side of the screen: the artwork + its name +
## what you did. Slides in, stays SHOW_TIME seconds, slides out; several queue up.
## Lives on the tree ROOT (not in a scene), so it keeps showing through scene changes
## (Story: LEVEL CLEAR -> board).

const SHOW_TIME := 4.0
const ART := 112.0

static var _instance: AchievementToast = null

var _queue: Array[Dictionary] = []
var _busy := false


## Queue an achievement (def from Achievements) for the pop-up.
static func show_achievement(d: Dictionary) -> void:
	var tree := Engine.get_main_loop() as SceneTree
	if tree == null or tree.root == null:
		return
	if _instance == null or not is_instance_valid(_instance):
		_instance = AchievementToast.new()
		_instance.name = "AchievementToast"
		tree.root.add_child.call_deferred(_instance)
	_instance._queue.append(d)
	_instance._next.call_deferred()


func _ready() -> void:
	layer = 90
	process_mode = Node.PROCESS_MODE_ALWAYS


func _next() -> void:
	if _busy or _queue.is_empty() or not is_inside_tree():
		return
	_busy = true
	var d: Dictionary = _queue.pop_front()
	var panel := PanelContainer.new()
	var gold: Color = AchievementArt.FRAMES.get(String(d["art"].get("frame", "gold")), AchievementArt.FRAMES["gold"])[0]
	panel.add_theme_stylebox_override("panel", UiStyle.box(Color(0.06, 0.06, 0.10, 0.94), gold, 4, 14, 12.0))
	panel.position = Vector2(-520, 215)                 # Under the top-left HP bar + move list
	panel.mouse_filter = Control.MOUSE_FILTER_IGNORE
	add_child(panel)
	var row := HBoxContainer.new()
	row.add_theme_constant_override("separation", 14)
	row.mouse_filter = Control.MOUSE_FILTER_IGNORE
	panel.add_child(row)
	var card := AchievementCard.new()
	card.def = d
	card.animate = true
	card.custom_minimum_size = Vector2(ART, ART)
	card.mouse_filter = Control.MOUSE_FILTER_IGNORE
	row.add_child(card)
	var col := VBoxContainer.new()
	col.alignment = BoxContainer.ALIGNMENT_CENTER
	col.custom_minimum_size = Vector2(330, 0)
	row.add_child(col)
	var head := UiStyle.label("ACHIEVEMENT UNLOCKED!" if String(d["id"]) != Achievements.ULTIMATE else "!!! ULTIMATE ACHIEVEMENT !!!", 15, gold, 5)
	head.horizontal_alignment = HORIZONTAL_ALIGNMENT_LEFT
	col.add_child(head)
	var nm := UiStyle.label(String(d["name"]), 22, UiStyle.TEXT, 7)
	nm.horizontal_alignment = HORIZONTAL_ALIGNMENT_LEFT
	nm.autowrap_mode = TextServer.AUTOWRAP_WORD_SMART
	nm.custom_minimum_size = Vector2(330, 0)
	col.add_child(nm)
	var desc := UiStyle.label(String(d["desc"]), 13, UiStyle.TEXT_DIM, 4)
	desc.horizontal_alignment = HORIZONTAL_ALIGNMENT_LEFT
	desc.autowrap_mode = TextServer.AUTOWRAP_WORD_SMART
	desc.custom_minimum_size = Vector2(330, 0)
	col.add_child(desc)
	SoundManager.play_sfx("ultimate", -6.0)
	var tw := create_tween()
	tw.tween_property(panel, "position:x", 16.0, 0.35).set_trans(Tween.TRANS_BACK).set_ease(Tween.EASE_OUT)
	tw.tween_interval(SHOW_TIME)
	tw.tween_property(panel, "position:x", -560.0, 0.3).set_trans(Tween.TRANS_QUAD).set_ease(Tween.EASE_IN)
	tw.tween_callback(func() -> void:
		panel.queue_free()
		_busy = false
		_next())
