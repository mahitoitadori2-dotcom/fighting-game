class_name TextEntry
extends RefCounted
## TYPING ON PHONES (2026-11-21, user: "you can't text in the code menu" on mobile).
## In the WEB build on a phone / tablet, Godot's own text boxes can't reliably open the phone's
## keyboard (iPhones especially). So there, a text field is filled through the BROWSER's input dialog
## (window.prompt): it always brings up the keyboard. Everywhere else the normal LineEdit is used.

## Should text be asked with the browser dialog here?
static func use_prompt() -> bool:
	if not OS.has_feature("web"):
		return false
	return OS.has_feature("web_android") or OS.has_feature("web_ios") or DisplayServer.is_touchscreen_available()


static var _last_ask := -10000                           # One tap = a touch AND a mouse click: ask once


## True while / just after the browser's input box was up: it takes the focus from the game, and that
## must NOT count as "the player left" (the auto-pause in GraphicsSettings would open the pause menu).
static func just_asked() -> bool:
	return Time.get_ticks_msec() - _last_ask < 2000


## Ask for a line of text (blocks until the player answers). "" = cancelled / empty.
static func ask(question: String, current: String = "") -> String:
	if not OS.has_feature("web"):
		return ""
	var js := "(function(){ var r = window.prompt(%s, %s); return r === null ? '' : String(r); })()" % [JSON.stringify(question), JSON.stringify(current)]
	_last_ask = Time.get_ticks_msec()
	var r: Variant = JavaScriptBridge.eval(js, true)
	_last_ask = Time.get_ticks_msec()
	return String(r) if r != null else ""


## A LineEdit that, on a web phone, opens the browser dialog when tapped and then calls `on_done(text)`.
static func hook(edit: LineEdit, question: String, on_done: Callable) -> void:
	if not use_prompt():
		return
	edit.editable = false                                    # (So Godot does not try its own keyboard)
	edit.placeholder_text = "tap here to type"
	edit.gui_input.connect(func(ev: InputEvent) -> void:
		var tap := (ev is InputEventMouseButton and (ev as InputEventMouseButton).pressed) or (ev is InputEventScreenTouch and (ev as InputEventScreenTouch).pressed)
		if not tap:
			return
		edit.accept_event()
		if Time.get_ticks_msec() - _last_ask < 700:
			return
		var t := ask(question, edit.text)
		_last_ask = Time.get_ticks_msec()
		if t != "":
			edit.text = t
			on_done.call(t))
