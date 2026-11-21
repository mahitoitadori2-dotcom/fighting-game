class_name PixelSprite
extends RefCounted
## HAND-PIXELLED PARTS (2026-11-21): the important parts of the 7 playable fighters (heads,
## helmets, masks, weapons) are drawn pixel by pixel on the same 3-unit grid as the PixelArt shader.
## A sprite = rows of characters; each character is looked up in a palette {char: Color} passed at
## draw time (so skins / palette swaps and glowing eyes keep working). '.' = empty.
## Rows are merged into runs of the same colour: one rect per run, not per pixel.

const PX := 3.0


## Upright sprite, top-left corner at `top_left` (art units).
static func draw(c: CanvasItem, rows: PackedStringArray, pal: Dictionary, top_left: Vector2) -> void:
	for y in rows.size():
		var row := rows[y]
		var x := 0
		var n := row.length()
		while x < n:
			var ch := row[x]
			var run := 1
			while x + run < n and row[x + run] == ch:
				run += 1
			if ch != "." and pal.has(ch):
				c.draw_rect(Rect2(top_left + Vector2(float(x) * PX, float(y) * PX), Vector2(float(run) * PX, PX)), pal[ch])
			x += run


## Rotated sprite (weapons): `pivot_cell` (in cells) sits at `origin`, the sprite turns by `ang`.
## Each run is one rotated quad.
static func draw_rotated(c: CanvasItem, rows: PackedStringArray, pal: Dictionary, origin: Vector2,
		pivot_cell: Vector2, ang: float, scale: float = 1.0) -> void:
	var px := PX * scale
	var ax := Vector2.from_angle(ang)
	var ay := Vector2(-ax.y, ax.x)
	for y in rows.size():
		var row := rows[y]
		var x := 0
		var n := row.length()
		while x < n:
			var ch := row[x]
			var run := 1
			while x + run < n and row[x + run] == ch:
				run += 1
			if ch != "." and pal.has(ch):
				var lx := (float(x) - pivot_cell.x) * px
				var ly := (float(y) - pivot_cell.y) * px
				var w := float(run) * px
				var p0 := origin + ax * lx + ay * ly
				c.draw_colored_polygon(PackedVector2Array([p0, p0 + ax * w, p0 + ax * w + ay * px, p0 + ay * px]), pal[ch])
			x += run
