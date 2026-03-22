extends Node2D
## Exit portal – closed until all leaves collected, then pulses.

const S := 64.0 * 0.5
var _time := 0.0

func _process(delta: float) -> void:
	_time += delta
	queue_redraw()

const SHADOW := Vector2(4, 5)

func _draw() -> void:
	var is_open: bool = get_meta("open", false)
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
