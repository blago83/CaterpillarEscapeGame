extends Node2D
## Wall tile – draws a green bush block.

const S := 64.0 * 0.5
const BUSH_BASE := Color(0.22, 0.52, 0.15)
const BUSH_DARK := Color(0.15, 0.38, 0.1)
const BUSH_LIGHT := Color(0.35, 0.65, 0.22)
const BUSH_HIGHLIGHT := Color(0.45, 0.72, 0.3)

func _draw() -> void:
	# Solid green base
	draw_rect(Rect2(-S, -S, S * 2, S * 2), BUSH_BASE)

	var has_t: bool = get_meta("has_t", false)
	var has_b: bool = get_meta("has_b", false)
	var has_l: bool = get_meta("has_l", false)
	var has_r: bool = get_meta("has_r", false)

	# Darker inner shading for depth
	draw_rect(Rect2(-S * 0.7, -S * 0.7, S * 1.4, S * 1.4), BUSH_BASE.darkened(0.05))

	# Leafy bush bumps – circles to give organic bush look
	draw_circle(Vector2(-S * 0.35, -S * 0.4), S * 0.38, BUSH_LIGHT)
	draw_circle(Vector2(S * 0.35, -S * 0.3), S * 0.35, BUSH_BASE.lightened(0.08))
	draw_circle(Vector2(-S * 0.3, S * 0.35), S * 0.36, BUSH_BASE.lightened(0.05))
	draw_circle(Vector2(S * 0.4, S * 0.4), S * 0.34, BUSH_LIGHT)
	draw_circle(Vector2(0, 0), S * 0.4, BUSH_BASE.lightened(0.1))

	# Small highlight dots (dew / leaf tips)
	draw_circle(Vector2(-S * 0.2, -S * 0.55), S * 0.12, BUSH_HIGHLIGHT)
	draw_circle(Vector2(S * 0.5, 0), S * 0.1, BUSH_HIGHLIGHT)
	draw_circle(Vector2(-S * 0.1, S * 0.5), S * 0.11, BUSH_HIGHLIGHT)
	draw_circle(Vector2(S * 0.3, -S * 0.55), S * 0.09, BUSH_HIGHLIGHT)

	# Edge shadow where exposed (not adjacent to another wall)
	var edge := 3.0
	if not has_t:
		draw_rect(Rect2(-S, -S, S * 2, edge), BUSH_DARK)
	if not has_b:
		draw_rect(Rect2(-S, S - edge, S * 2, edge), BUSH_DARK)
	if not has_l:
		draw_rect(Rect2(-S, -S, edge, S * 2), BUSH_DARK)
	if not has_r:
		draw_rect(Rect2(S - edge, -S, edge, S * 2), BUSH_DARK)
