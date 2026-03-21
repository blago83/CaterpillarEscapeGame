extends Node2D
## A spider hazard – causes restart on contact.

const S := 64.0 * 0.5

func _draw() -> void:
	# Body
	draw_circle(Vector2.ZERO, S * 0.35, Color(0.15, 0.12, 0.12))
	# Head
	draw_circle(Vector2(0, -S * 0.25), S * 0.2, Color(0.2, 0.15, 0.15))
	# Red eyes
	draw_circle(Vector2(-S * 0.08, -S * 0.32), S * 0.08, Color(0.9, 0.1, 0.1))
	draw_circle(Vector2(S * 0.08, -S * 0.32), S * 0.08, Color(0.9, 0.1, 0.1))
	# Legs
	var leg_color := Color(0.12, 0.1, 0.1)
	for side in [-1.0, 1.0]:
		for i in range(4):
			var angle := (i - 1.5) * 0.4
			var start := Vector2(side * S * 0.25, -S * 0.05 + i * S * 0.12)
			var end_pt := start + Vector2(side * S * 0.55, sin(angle) * S * 0.3)
			draw_line(start, end_pt, leg_color, 2.0)
