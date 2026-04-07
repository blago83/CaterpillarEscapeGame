extends Node2D
## Exit portal – closed until all leaves collected, then pulses.

const S := 64.0 * 0.5
var _time := 0.0
var _closed_tex: Texture2D = preload("res://assets/New/Intersection_1.png")
var _open_tex: Texture2D = preload("res://assets/New/Intersection_2.png")

func _process(delta: float) -> void:
	_time += delta
	queue_redraw()

const SHADOW := Vector2(4, 5)

func _draw_size_for(tex: Texture2D) -> Vector2:
	if tex == null:
		return Vector2(S * 1.4, S * 1.4)
	var src := tex.get_size()
	if src.x <= 0.0 or src.y <= 0.0:
		return Vector2(S * 1.4, S * 1.4)
	var scale: float = 74.0 / max(src.x, src.y)
	return src * scale

func _draw() -> void:
	var is_open: bool = get_meta("open", false)
	var tex := _open_tex if is_open else _closed_tex
	if tex != null:
		var draw_sz := _draw_size_for(tex)
		draw_circle(SHADOW, min(draw_sz.x, draw_sz.y) * 0.48, Color(0, 0, 0, 0.2))
		draw_texture_rect(tex, Rect2(-draw_sz * 0.5, draw_sz), false)
		if is_open:
			var pulse := (sin(_time * 4.0) + 1.0) * 0.5
			draw_circle(Vector2.ZERO, min(draw_sz.x, draw_sz.y) * 0.46, Color(1, 1, 1, pulse * 0.22))
		return

	var base: Color
	if is_open:
		base = Color(0.85, 0.7, 1.0)
	else:
		base = Color(0.5, 0.35, 0.6)
	# Drop shadow
	draw_circle(SHADOW, S * 0.7, Color(0, 0, 0, 0.25))
	# Outer portal ring
	draw_circle(Vector2.ZERO, S * 0.7, base)
	# Bottom shading for depth
	draw_circle(Vector2(0, S * 0.1), S * 0.5, base.darkened(0.2))
	# Inner (brighter center)
	draw_circle(Vector2.ZERO, S * 0.4, base.lightened(0.3))
	# Top specular
	draw_circle(Vector2(-S * 0.12, -S * 0.18), S * 0.22, base.lightened(0.45))
	if is_open:
		# Pulsing glow
		var pulse := (sin(_time * 4.0) + 1.0) * 0.5
		draw_circle(Vector2.ZERO, S * 0.65, Color(1, 1, 1, pulse * 0.3))
		# Arrow
		draw_line(Vector2(0, S * 0.15), Vector2(0, -S * 0.15), Color(1, 1, 1, 0.8), 3.0)
		draw_line(Vector2(-S * 0.1, -S * 0.05), Vector2(0, -S * 0.15), Color(1, 1, 1, 0.8), 3.0)
		draw_line(Vector2(S * 0.1, -S * 0.05), Vector2(0, -S * 0.15), Color(1, 1, 1, 0.8), 3.0)
