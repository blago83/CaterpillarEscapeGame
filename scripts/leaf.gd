extends Node2D
## A collectible leaf – gently sways.

const S := 64.0 * 0.5
const LEAF_DRAW := Vector2(44, 44)
var _time := 0.0
var _leaf_tex: Texture2D = preload("res://assets/New/Center.png")

func _process(delta: float) -> void:
	_time += delta
	rotation = sin(_time * 2.0) * 0.15

const SHADOW := Vector2(3, 4)

func _draw() -> void:
	if _leaf_tex != null:
		# Soft shadow under the sprite so it blends with the scene depth.
		draw_circle(SHADOW, LEAF_DRAW.x * 0.32, Color(0, 0, 0, 0.2))
		draw_texture_rect(_leaf_tex, Rect2(-LEAF_DRAW * 0.5, LEAF_DRAW), false)
		return

	var col := Color(0.2, 0.72, 0.15)
	var pts := PackedVector2Array([
		Vector2(0, -S * 0.55),
		Vector2(S * 0.45, -S * 0.2),
		Vector2(S * 0.35, S * 0.3),
		Vector2(0, S * 0.55),
		Vector2(-S * 0.35, S * 0.3),
		Vector2(-S * 0.45, -S * 0.2),
	])
	# Drop shadow
	var shadow_pts := PackedVector2Array()
	for p in pts:
		shadow_pts.append(p + SHADOW)
	draw_colored_polygon(shadow_pts, Color(0, 0, 0, 0.25))
	# Leaf body
	draw_colored_polygon(pts, col)
	# Bottom darker half for depth
	var bottom := PackedVector2Array([
		Vector2(-S * 0.35, S * 0.3),
		Vector2(S * 0.35, S * 0.3),
		Vector2(0, S * 0.55),
	])
	draw_colored_polygon(bottom, col.darkened(0.15))
	# Top highlight
	draw_circle(Vector2(-S * 0.1, -S * 0.2), S * 0.18, col.lightened(0.22))
	# Veins
	draw_line(Vector2(0, -S * 0.45), Vector2(0, S * 0.45), Color(0.15, 0.55, 0.1), 2.0)
	draw_line(Vector2(0, -S * 0.1), Vector2(S * 0.25, -S * 0.3), Color(0.15, 0.55, 0.1), 1.5)
	draw_line(Vector2(0, S * 0.1), Vector2(-S * 0.25, S * 0.25), Color(0.15, 0.55, 0.1), 1.5)
