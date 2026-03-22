extends Node2D
## Wall tile – draws a green bush block with pseudo-3D depth.

const S := 64.0 * 0.5
const DEPTH := 8.0  # pixels of vertical extrusion
const BUSH_BASE := Color(0.22, 0.52, 0.15)
const BUSH_DARK := Color(0.12, 0.3, 0.06)
const BUSH_SIDE := Color(0.14, 0.35, 0.08)
const BUSH_LIGHT := Color(0.35, 0.65, 0.22)
const BUSH_HIGHLIGHT := Color(0.55, 0.82, 0.38)
const SHADOW_COLOR := Color(0, 0, 0, 0.25)

func _draw() -> void:
	var has_t: bool = get_meta("has_t", false)
	var has_b: bool = get_meta("has_b", false)
	var has_l: bool = get_meta("has_l", false)
	var has_r: bool = get_meta("has_r", false)

	# Drop shadow behind the block (offset down-right)
	if not has_b:
		draw_rect(Rect2(-S + 3, S, S * 2, DEPTH), SHADOW_COLOR)
	if not has_r:
		draw_rect(Rect2(S, -S + 3, DEPTH, S * 2), SHADOW_COLOR)

	# Bottom side face (extrusion) – visible when no wall below
	if not has_b:
		draw_rect(Rect2(-S, S - 1, S * 2, DEPTH + 1), BUSH_SIDE)
	# Right side face – visible when no wall to the right
	if not has_r:
		draw_rect(Rect2(S - 1, -S, DEPTH + 1, S * 2), BUSH_SIDE.darkened(0.1))

	# Main top face
	draw_rect(Rect2(-S, -S, S * 2, S * 2), BUSH_BASE)

	# Leafy bush bumps – circles for organic look
	draw_circle(Vector2(-S * 0.35, -S * 0.4), S * 0.38, BUSH_LIGHT)
	draw_circle(Vector2(S * 0.35, -S * 0.3), S * 0.35, BUSH_BASE.lightened(0.08))
	draw_circle(Vector2(-S * 0.3, S * 0.35), S * 0.36, BUSH_BASE.lightened(0.05))
	draw_circle(Vector2(S * 0.4, S * 0.4), S * 0.34, BUSH_LIGHT)
	draw_circle(Vector2(0, 0), S * 0.4, BUSH_BASE.lightened(0.1))

	# Highlight dots (dew / leaf tips)
	draw_circle(Vector2(-S * 0.2, -S * 0.55), S * 0.12, BUSH_HIGHLIGHT)
	draw_circle(Vector2(S * 0.5, -S * 0.1), S * 0.1, BUSH_HIGHLIGHT)
	draw_circle(Vector2(-S * 0.1, S * 0.4), S * 0.11, BUSH_HIGHLIGHT)
	draw_circle(Vector2(S * 0.3, -S * 0.55), S * 0.09, BUSH_HIGHLIGHT)

	# Top bevel – bright edge along top and left for light direction
	if not has_t:
		draw_rect(Rect2(-S, -S, S * 2, 3), BUSH_LIGHT.lightened(0.15))
	if not has_l:
		draw_rect(Rect2(-S, -S, 3, S * 2), BUSH_LIGHT.lightened(0.08))

	# Dark inner edge on bottom and right for depth
	if not has_b:
		draw_rect(Rect2(-S, S - 2, S * 2, 2), BUSH_DARK)
	if not has_r:
		draw_rect(Rect2(S - 2, -S, 2, S * 2), BUSH_DARK)
