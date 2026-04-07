extends Node2D
## A spider hazard – causes restart on contact.

const S := 64.0 * 0.5
const SPIDER_DRAW := Vector2(60, 44)
var _spider_tex: Texture2D = preload("res://assets/New/cross.png")

const SHADOW := Vector2(4, 5)
const SHADOW_COL := Color(0, 0, 0, 0.28)

func _draw() -> void:
	if _spider_tex != null:
		draw_circle(SHADOW, SPIDER_DRAW.y * 0.42, SHADOW_COL)
		draw_texture_rect(_spider_tex, Rect2(-SPIDER_DRAW * 0.5, SPIDER_DRAW), false)
		return

	var body_col := Color(0.15, 0.12, 0.12)
	var head_col := Color(0.2, 0.15, 0.15)
	# Drop shadow
	draw_circle(SHADOW, S * 0.35, SHADOW_COL)
	draw_circle(Vector2(0, -S * 0.25) + SHADOW, S * 0.2, SHADOW_COL)
	# Leg shadows
	var leg_shadow := Color(0, 0, 0, 0.18)
	for side in [-1.0, 1.0]:
		for i in range(4):
			var angle := (i - 1.5) * 0.4
			var start := Vector2(side * S * 0.25, -S * 0.05 + i * S * 0.12)
			var end_pt := start + Vector2(side * S * 0.55, sin(angle) * S * 0.3)
			draw_line(start + SHADOW, end_pt + SHADOW, leg_shadow, 3.0)
	# Legs
	var leg_color := Color(0.12, 0.1, 0.1)
	for side in [-1.0, 1.0]:
		for i in range(4):
			var angle := (i - 1.5) * 0.4
			var start := Vector2(side * S * 0.25, -S * 0.05 + i * S * 0.12)
			var end_pt := start + Vector2(side * S * 0.55, sin(angle) * S * 0.3)
			draw_line(start, end_pt, leg_color, 2.0)
	# Body
	draw_circle(Vector2.ZERO, S * 0.35, body_col)
	draw_circle(Vector2(-S * 0.08, -S * 0.08), S * 0.15, body_col.lightened(0.12))
	# Head
	draw_circle(Vector2(0, -S * 0.25), S * 0.2, head_col)
	draw_circle(Vector2(-S * 0.05, -S * 0.3), S * 0.1, head_col.lightened(0.12))
	# Red eyes with glow
	draw_circle(Vector2(-S * 0.08, -S * 0.32), S * 0.08, Color(0.9, 0.1, 0.1))
	draw_circle(Vector2(S * 0.08, -S * 0.32), S * 0.08, Color(0.9, 0.1, 0.1))
	draw_circle(Vector2(-S * 0.06, -S * 0.34), S * 0.04, Color(1.0, 0.5, 0.4))
