class_name Replay
extends RefCounted
## REPLAYS: record a fight as the fighters' visual STATE (not inputs - the CPUs and many moves are
## random, so re-simulating inputs would drift). 30 snapshots per second; each snapshot stores only
## what CHANGED since the last one, so files stay small.
## Playback (ReplayPlayer) spawns frozen "puppet" copies of the same fighters and pours the recorded
## state into them every tick: bodies, poses, facing, HP bars, cooldown text. Projectiles, sparks and
## popups are not part of the recording.
## Saved replays: user://replays/*.ubr (compressed). Also used for the Boss Rush GHOST.

const HZ := 30.0
const DIR := "user://replays"
const VERSION := 1
const SIMPLE := [TYPE_BOOL, TYPE_INT, TYPE_FLOAT, TYPE_STRING, TYPE_STRING_NAME, TYPE_VECTOR2, TYPE_VECTOR2I, TYPE_COLOR, TYPE_RECT2]

static var last: Dictionary = {}          # The fight that just ended (Watch Replay on the winner screen)
static var pending: Dictionary = {}       # ArenaManager plays this instead of a match


## Every simple script variable of a fighter + its transform / visuals (the snapshot).
static func capture(f: Fighter) -> Dictionary:
	var out := {}
	for p in f.get_property_list():
		if not (int(p["usage"]) & PROPERTY_USAGE_SCRIPT_VARIABLE):
			continue
		var n := String(p["name"])
		var v: Variant = f.get(n)
		if _plain(v, 0):
			out[n] = v.duplicate(true) if (v is Dictionary or v is Array) else v
	out["@pos"] = f.global_position
	out["@vel"] = f.velocity
	out["@vis"] = f.visible
	if f.visuals != null:
		out["@vscale"] = f.visuals.scale
		out["@vmod"] = f.visuals.modulate
		out["@vrot"] = f.visuals.rotation
		out["@vpos"] = f.visuals.position
	return out


## Only values that survive saving and can't point at nodes of the old fight.
static func _plain(v: Variant, depth: int) -> bool:
	var t := typeof(v)
	if t in SIMPLE:
		return true
	if depth > 2:
		return false
	if t == TYPE_DICTIONARY:
		var d: Dictionary = v
		if d.size() > 40:
			return false
		for k in d:
			if not _plain(k, depth + 1) or not _plain(d[k], depth + 1):
				return false
		return true
	if t == TYPE_ARRAY:
		var a: Array = v
		if a.size() > 40:
			return false
		for x in a:
			if not _plain(x, depth + 1):
				return false
		return true
	return false


## Pour a snapshot (or a delta) into a puppet fighter.
static func apply(f: Fighter, snap: Dictionary) -> void:
	for k in snap:
		var key := String(k)
		match key:
			"@pos":
				f.global_position = snap[k]
			"@vel":
				f.velocity = snap[k]
			"@vis":
				f.visible = snap[k]
			"@vscale":
				if f.visuals:
					f.visuals.scale = snap[k]
			"@vmod":
				if f.visuals:
					f.visuals.modulate = snap[k]
			"@vrot":
				if f.visuals:
					f.visuals.rotation = snap[k]
			"@vpos":
				if f.visuals:
					f.visuals.position = snap[k]
			_:
				f.set(key, snap[k])
	if f.visuals:
		f.visuals.queue_redraw()
	f.queue_redraw()


## Turn a fighter into a puppet: no thinking, no physics, can't hit or be hit.
static func make_puppet(f: Fighter) -> void:
	f.process_mode = Node.PROCESS_MODE_DISABLED
	if f.visuals:
		f.visuals.process_mode = Node.PROCESS_MODE_ALWAYS     # Keeps redrawing
	if f.hurtbox:
		f.hurtbox.monitorable = false
	f.collision_layer = 0
	f.collision_mask = 0


# ===== Files =====
static func save(data: Dictionary, title: String) -> String:
	DirAccess.make_dir_recursive_absolute(DIR)
	var stamp := Time.get_datetime_string_from_system().replace(":", "-").replace("T", "_")
	var path := DIR.path_join("%s_%s.ubr" % [stamp, title.to_lower().replace(" ", "_").left(40)])
	var d := data.duplicate()
	d["title"] = title
	d["date"] = Time.get_datetime_string_from_system().replace("T", " ")
	var f := FileAccess.open_compressed(path, FileAccess.WRITE, FileAccess.COMPRESSION_ZSTD)
	if f == null:
		return ""
	f.store_var(d)
	f.close()
	return path


static func load_file(path: String) -> Dictionary:
	var f := FileAccess.open_compressed(path, FileAccess.READ, FileAccess.COMPRESSION_ZSTD)
	if f == null:
		return {}
	var v: Variant = f.get_var()
	f.close()
	return v if v is Dictionary and int((v as Dictionary).get("version", 0)) == VERSION else {}


static func list_files() -> Array[String]:
	var out: Array[String] = []
	var d := DirAccess.open(DIR)
	if d == null:
		return out
	for fn in d.get_files():
		if fn.ends_with(".ubr"):
			out.append(DIR.path_join(fn))
	out.sort()
	out.reverse()                                   # Newest first
	return out


## Header only (title, date, length) without keeping the frames.
static func info(path: String) -> Dictionary:
	var d := load_file(path)
	if d.is_empty():
		return {}
	return {"title": d.get("title", "?"), "date": d.get("date", ""), "seconds": float((d["frames"] as Array).size()) / HZ, "path": path}
