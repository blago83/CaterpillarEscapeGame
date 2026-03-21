extends Node2D
## Exit portal – closed until all leaves collected, then pulses.

const S := 64.0 * 0.5
var _time := 0.0

func _process(delta: float) -> void:
	_time += delta
	queue_redraw()

func _draw() -> void:
	var is_open: bool = get_meta("open", false)
	var base: Color
	if is_open:
		base = Color(0.85, 0.7, 1.0)
	else:
		base = Color(0.5, 0.35, 0.6)
	# Outer portal ring
	draw_circle(Vector2.ZERO, S * 0.7, base)
	# Inner
	draw_circle(Vector2.ZERO, S * 0.4, base.lightened(0.3))
	if is_open:
		# Pulsing glow
		var pulse := (sin(_time * 4.0) + 1.0) * 0.5
		draw_circle(Vector2.ZERO, S * 0.65, Color(1, 1, 1, pulse * 0.3))
		# Arrow
		draw_line(Vector2(0, S * 0.15), Vector2(0, -S * 0.15), Color(1, 1, 1, 0.8), 3.0)
		draw_line(Vector2(-S * 0.1, -S * 0.05), Vector2(0, -S * 0.15), Color(1, 1, 1, 0.8), 3.0)
		draw_line(Vector2(S * 0.1, -S * 0.05), Vector2(0, -S * 0.15), Color(1, 1, 1, 0.8), 3.0)
