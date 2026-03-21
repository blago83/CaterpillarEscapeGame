extends Node2D
## Caterpillar segment – drawn procedurally based on metadata.
## Set meta "seg_type" = "head" | "body" | "tail"

const S := 64.0 * 0.5

func _draw() -> void:
	var seg_type: String = get_meta("seg_type", "body")
	match seg_type:
		"head": _draw_head()
		"tail": _draw_tail()
		_: _draw_body()

func _draw_head() -> void:
	# Green circle head
	draw_circle(Vector2.ZERO, S * 0.8, Color(0.3, 0.7, 0.15))
	# Eyes
	draw_circle(Vector2(S * 0.3, -S * 0.3), S * 0.22, Color.WHITE)
	draw_circle(Vector2(S * 0.3, S * 0.3), S * 0.22, Color.WHITE)
	draw_circle(Vector2(S * 0.38, -S * 0.28), S * 0.11, Color(0.1, 0.1, 0.1))
	draw_circle(Vector2(S * 0.38, S * 0.28), S * 0.11, Color(0.1, 0.1, 0.1))
	# Antennae
	draw_line(Vector2(S * 0.2, -S * 0.5), Vector2(S * 0.55, -S * 0.75), Color(0.25, 0.55, 0.1), 2.0)
	draw_line(Vector2(S * 0.2, S * 0.5), Vector2(S * 0.55, S * 0.75), Color(0.25, 0.55, 0.1), 2.0)
	draw_circle(Vector2(S * 0.55, -S * 0.75), 3.0, Color(0.35, 0.65, 0.15))
	draw_circle(Vector2(S * 0.55, S * 0.75), 3.0, Color(0.35, 0.65, 0.15))
	# Smile
	draw_arc(Vector2(S * 0.25, 0), S * 0.2, 0.3, PI - 0.3, 8, Color(0.15, 0.4, 0.05), 2.0)
	# Tiny red shoes
	draw_rect(Rect2(-S * 0.55, -S * 0.5, S * 0.3, S * 0.2), Color(0.85, 0.15, 0.15))
	draw_rect(Rect2(-S * 0.55, S * 0.3, S * 0.3, S * 0.2), Color(0.85, 0.15, 0.15))

func _draw_tail() -> void:
	var pts := PackedVector2Array([
		Vector2(-S * 0.6, 0),
		Vector2(0, -S * 0.45),
		Vector2(S * 0.4, -S * 0.3),
		Vector2(S * 0.4, S * 0.3),
		Vector2(0, S * 0.45),
	])
	draw_colored_polygon(pts, Color(0.35, 0.68, 0.18))
	# Shoes
	draw_rect(Rect2(-S * 0.25, -S * 0.42, S * 0.25, S * 0.18), Color(0.85, 0.15, 0.15))
	draw_rect(Rect2(-S * 0.25, S * 0.24, S * 0.25, S * 0.18), Color(0.85, 0.15, 0.15))

func _draw_body() -> void:
	# Rounded body segment
	draw_circle(Vector2.ZERO, S * 0.52, Color(0.4, 0.75, 0.2))
	# Stripe
	draw_rect(Rect2(-S * 0.1, -S * 0.5, S * 0.2, S), Color(0.45, 0.8, 0.25))
	# Shoes
	draw_rect(Rect2(-S * 0.35, -S * 0.48, S * 0.22, S * 0.16), Color(0.85, 0.15, 0.15))
	draw_rect(Rect2(-S * 0.35, S * 0.32, S * 0.22, S * 0.16), Color(0.85, 0.15, 0.15))
