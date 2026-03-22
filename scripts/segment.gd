extends Node2D
## Caterpillar segment – head drawn procedurally, body/tail use body_segment.png.
## Set meta "seg_type" = "head" | "body" | "tail"

const S := 64.0 * 0.5
const SHADOW := Vector2(4, 5)
const SHADOW_COL := Color(0, 0, 0, 0.3)
const SHOE_COL := Color(0.85, 0.15, 0.15)
const SHOE_DARK := Color(0.6, 0.08, 0.08)
const SHOE_SHINE := Color(1.0, 0.45, 0.4)
const OVERLAP := 1.7  # draw body sprites 70% larger for visible overlap between segments

var _body_tex: Texture2D = preload("res://assets/player/body_segment.png")

func _draw() -> void:
	var seg_type: String = get_meta("seg_type", "body")
	match seg_type:
		"head": _draw_head()
		"tail": _draw_tail()
		_: _draw_body()

func _draw_head() -> void:
	# Drop shadow
	draw_circle(SHADOW, S * 0.8, SHADOW_COL)
	# Green circle head
	var base := Color(0.3, 0.7, 0.15)
	draw_circle(Vector2.ZERO, S * 0.8, base)
	# Bottom half darker for roundness
	draw_circle(Vector2(0, S * 0.15), S * 0.6, base.darkened(0.12))
	# Top specular highlight
	draw_circle(Vector2(-S * 0.15, -S * 0.25), S * 0.35, base.lightened(0.18))
	# Eyes
	draw_circle(Vector2(S * 0.3, -S * 0.3), S * 0.22, Color.WHITE)
	draw_circle(Vector2(S * 0.3, S * 0.3), S * 0.22, Color.WHITE)
	# Eye shine
	draw_circle(Vector2(S * 0.25, -S * 0.35), S * 0.07, Color(1, 1, 1, 0.6))
	draw_circle(Vector2(S * 0.25, S * 0.25), S * 0.07, Color(1, 1, 1, 0.6))
	# Pupils
	draw_circle(Vector2(S * 0.38, -S * 0.28), S * 0.11, Color(0.1, 0.1, 0.1))
	draw_circle(Vector2(S * 0.38, S * 0.28), S * 0.11, Color(0.1, 0.1, 0.1))
	# Antennae
	draw_line(Vector2(S * 0.2, -S * 0.5), Vector2(S * 0.55, -S * 0.75), Color(0.25, 0.55, 0.1), 2.5)
	draw_line(Vector2(S * 0.2, S * 0.5), Vector2(S * 0.55, S * 0.75), Color(0.25, 0.55, 0.1), 2.5)
	draw_circle(Vector2(S * 0.55, -S * 0.75), 4.0, Color(0.45, 0.75, 0.2))
	draw_circle(Vector2(S * 0.55, S * 0.75), 4.0, Color(0.45, 0.75, 0.2))
	# Smile
	draw_arc(Vector2(S * 0.25, 0), S * 0.2, 0.3, PI - 0.3, 8, Color(0.15, 0.4, 0.05), 2.0)
	# 3D shoes (shadow, base, highlight)
	_draw_shoe(Vector2(-S * 0.55, -S * 0.5), Vector2(S * 0.3, S * 0.2))
	_draw_shoe(Vector2(-S * 0.55, S * 0.3), Vector2(S * 0.3, S * 0.2))

func _draw_tail() -> void:
	_draw_body_sprite()

func _draw_body() -> void:
	_draw_body_sprite()

func _draw_body_sprite() -> void:
	var tex_size := _body_tex.get_size()
	var target_size := S * 2.0 * OVERLAP
	var sc := target_size / tex_size.x
	var draw_sz := tex_size * sc
	# Drop shadow
	draw_circle(SHADOW, draw_sz.x * 0.38, SHADOW_COL)
	# Draw the texture centred
	draw_texture_rect(_body_tex, Rect2(-draw_sz * 0.5, draw_sz), false)

func _draw_shoe(pos: Vector2, sz: Vector2) -> void:
	# Shadow
	draw_rect(Rect2(pos.x + 2, pos.y + 2, sz.x, sz.y), Color(0, 0, 0, 0.25))
	# Base
	draw_rect(Rect2(pos.x, pos.y, sz.x, sz.y), SHOE_COL)
	# Dark bottom edge
	draw_rect(Rect2(pos.x, pos.y + sz.y - 2, sz.x, 2), SHOE_DARK)
	# Shine on top
	draw_rect(Rect2(pos.x + 2, pos.y + 1, sz.x * 0.5, 2), SHOE_SHINE)
