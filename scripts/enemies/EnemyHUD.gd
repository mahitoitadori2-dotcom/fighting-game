class_name EnemyHUD
extends Node2D
## Floating HUD ABOVE an enemy (world space: follows him, scales with the camera).
## Shows: name, HP bar + numbers, the pattern name while telegraphing ("SPIN DASH!"
## with a big "!"), "ENRAGED" in phase 2, and status icons:
##   STUN (yellow star)  SLOW (purple goo)  BURN (red flame)  FROZEN (time stop clock)

var enemy: BaseEnemy

const W := 104.0


func _ready() -> void:
	z_index = 60
	z_as_relative = false
	position = Vector2(0, -enemy.data.body_size.y - 34.0)


var _last_key := ""


## Redraws ONLY when something shown changed, or while something animates
## (ENRAGED pulse, telegraph flash, spinning stun star). Idle HUD = no redraw.
func _process(_delta: float) -> void:
	visible = enemy != null and is_instance_valid(enemy) and not enemy.is_dead
	if not visible:
		return
	var tt := enemy.telegraph_text()
	var animated := enemy.enraged or tt != "" or enemy.stun_timer > 0.0
	var key := "%d/%d|%s|%s%s%s%s" % [enemy.hp, enemy.data.max_hp, tt, "s" if enemy.stun_timer > 0.0 else "",
		"g" if enemy.goo_timer > 0.0 else "", "b" if enemy.burn_timer > 0.0 else "", "f" if enemy.is_time_frozen() else ""]
	if animated or key != _last_key:
		_last_key = key
		queue_redraw()


func _draw() -> void:
	if enemy == null or not is_instance_valid(enemy):
		return
	var t := enemy.anim_time

	# --- Name (+ ENRAGED above it) ---
	FighterArt.label(self, Vector2(0, -16), enemy.enemy_name.to_upper(), 14, Color.WHITE)
	if enemy.enraged:
		var p := 0.6 + 0.4 * sin(t * 8.0)
		FighterArt.label(self, Vector2(0, -34), "ENRAGED", 13, Color(1.0, 0.25 * p, 0.2))

	# --- HP bar (green -> red) + numbers ---
	var k := clampf(float(enemy.hp) / maxf(float(enemy.data.max_hp), 1.0), 0.0, 1.0)
	var bar := Rect2(-W * 0.5, -8, W, 10)
	draw_rect(bar.grow(2.0), Color(0, 0, 0))
	draw_rect(bar, Color(0.18, 0.08, 0.08))
	var col := Color(0.9, 0.15, 0.15).lerp(Color(0.2, 0.85, 0.3), k)
	draw_rect(Rect2(bar.position, Vector2(W * k, 10)), col)
	draw_rect(Rect2(bar.position, Vector2(W * k, 3)), col.lightened(0.35))
	FighterArt.label(self, Vector2(0, 14), "%d / %d" % [enemy.hp, enemy.data.max_hp], 11, Color(1, 1, 1, 0.9))

	# --- Status icons ---
	var icons: Array[String] = []
	if enemy.stun_timer > 0.0:
		icons.append("stun")
	if enemy.goo_timer > 0.0:
		icons.append("slow")
	if enemy.burn_timer > 0.0:
		icons.append("burn")
	if enemy.is_time_frozen():
		icons.append("frozen")
	for i in icons.size():
		_icon(Vector2(W * 0.5 + 12.0 + float(i) * 18.0, -3), icons[i], t)

	# --- Telegraph: pattern name + big "!" ---
	var tt := enemy.telegraph_text()
	if tt != "":
		var flash := Color(1.0, 0.9, 0.2) if fmod(t * 8.0, 1.0) < 0.5 else Color(1.0, 0.3, 0.2)
		FighterArt.label(self, Vector2(0, -54), tt, 18, flash)
		_exclamation(Vector2(0, -78), t)


func _icon(p: Vector2, kind: String, t: float) -> void:
	draw_circle(p, 8.5, Color(0, 0, 0))
	match kind:
		"stun":
			draw_circle(p, 6.5, Color(0.25, 0.22, 0.1))
			var pts := PackedVector2Array()
			for i in 10:
				var a := TAU * float(i) / 10.0 - PI * 0.5 + t * 3.0
				pts.append(p + Vector2.from_angle(a) * (6.0 if i % 2 == 0 else 2.6))
			draw_colored_polygon(pts, Color(1.0, 0.9, 0.2))
		"slow":
			draw_circle(p, 6.5, Color(0.2, 0.08, 0.3))
			draw_circle(p + Vector2(0, 1.5), 3.5, Color(0.6, 0.3, 0.9))
			draw_colored_polygon(PackedVector2Array([p + Vector2(-3, 0.5), p + Vector2(3, 0.5), p + Vector2(0, -5)]), Color(0.6, 0.3, 0.9))
		"burn":
			draw_circle(p, 6.5, Color(0.3, 0.02, 0.02))
			draw_polygon(PackedVector2Array([p + Vector2(-4, 4), p + Vector2(4, 4), p + Vector2(0.5, -6)]),
				PackedColorArray([Color(1, 0, 0), Color(1, 0, 0), Color(0.55, 0, 0)]))
		"frozen":
			draw_circle(p, 6.5, Color(0.75, 0.65, 1.0))
			draw_line(p, p + Vector2(0, -4.5), Color(0, 0, 0), 1.5)
			draw_line(p, p + Vector2(3.5, 0), Color(0, 0, 0), 1.5)


func _exclamation(p: Vector2, t: float) -> void:
	var s := 1.0 + 0.15 * sin(t * 25.0)
	var bar := PackedVector2Array([p + Vector2(-4, -14) * s, p + Vector2(4, -14) * s, p + Vector2(2.5, 4) * s, p + Vector2(-2.5, 4) * s])
	draw_colored_polygon(bar, Color(1.0, 0.85, 0.15))
	FighterArt.outline(self, bar, 3.0)
	draw_circle(p + Vector2(0, 10) * s, 5.0 * s, Color(0, 0, 0))
	draw_circle(p + Vector2(0, 10) * s, 3.4 * s, Color(1.0, 0.85, 0.15))
