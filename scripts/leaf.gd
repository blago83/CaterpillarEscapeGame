extends Node2D
## A collectible leaf – gently sways.

const S := 64.0 * 0.5
var _time := 0.0

func _process(delta: float) -> void:
	_time += delta
	rotation = sin(_time * 2.0) * 0.15

func _draw() -> void:
	var pts := PackedVector2Array([
		Vector2(0, -S * 0.55),
		Vector2(S * 0.45, -S * 0.2),
		Vector2(S * 0.35, S * 0.3),
		Vector2(0, S * 0.55),
		Vector2(-S * 0.35, S * 0.3),
		Vector2(-S * 0.45, -S * 0.2),
	])
	draw_colored_polygon(pts, Color(0.2, 0.72, 0.15))
	# Veins
	draw_line(Vector2(0, -S * 0.45), Vector2(0, S * 0.45), Color(0.15, 0.55, 0.1), 2.0)
	draw_line(Vector2(0, -S * 0.1), Vector2(S * 0.25, -S * 0.3), Color(0.15, 0.55, 0.1), 1.5)
	draw_line(Vector2(0, S * 0.1), Vector2(-S * 0.25, S * 0.25), Color(0.15, 0.55, 0.1), 1.5)
