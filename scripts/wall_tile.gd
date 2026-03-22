extends Node2D
## Wall tile – bush sprites for maze walls.
## Horizontal walls use a random bush_horizontal (1-7).
## Vertical walls use bush_vertical.
## Corners/junctions draw both overlaid.

const CELL := 64.0
const HALF := CELL * 0.5

# Content regions inside the 128x128 canvases (skip transparent padding)
const H_SRC := Rect2(0.0, 16.0, 128.0, 96.0)   # horizontal: 128x96 content
const V_SRC := Rect2(16.0, 0.0, 96.0, 128.0)    # vertical:   96x128 content

# Draw size: scale content to fill the cell + 73% bigger (1.44 * 1.2)
const H_DRAW := Vector2(CELL, CELL * 96.0 / 128.0) * 1.728
const V_DRAW := Vector2(CELL * 96.0 / 128.0, CELL) * 1.728

var _h_textures: Array[Texture2D] = [
	preload("res://assets/landscape/bush_horizontal_1.png"),
	preload("res://assets/landscape/bush_horizontal_2.png"),
	preload("res://assets/landscape/bush_horizontal_3.png"),
	preload("res://assets/landscape/bush_horizontal_4.png"),
	preload("res://assets/landscape/bush_horizontal_5.png"),
	preload("res://assets/landscape/bush_horizontal_6.png"),
	preload("res://assets/landscape/bush_horizontal_7.png"),
]
var _v_texture: Texture2D = preload("res://assets/landscape/bush_vertical.png")

func _draw() -> void:
	var has_t: bool = get_meta("has_t", false)
	var has_b: bool = get_meta("has_b", false)
	var has_l: bool = get_meta("has_l", false)
	var has_r: bool = get_meta("has_r", false)
	var idx: int = get_meta("variant", 0) % _h_textures.size()

	var needs_h := has_l or has_r
	var needs_v := has_t or has_b
	var isolated := not needs_h and not needs_v

	# Draw horizontal bush (or isolated fallback)
	if needs_h or isolated:
		var tex := _h_textures[idx]
		var dest := Rect2(-H_DRAW * 0.5, H_DRAW)
		draw_texture_rect_region(tex, dest, H_SRC)

	# Draw vertical bush
	if needs_v:
		var dest := Rect2(-V_DRAW * 0.5, V_DRAW)
		draw_texture_rect_region(_v_texture, dest, V_SRC)

	# Debug label
	var font := ThemeDB.fallback_font
	var label := str(idx + 1)
	draw_string(font, Vector2(-5, 5), label, HORIZONTAL_ALIGNMENT_CENTER, -1, 16, Color.BLACK)
	draw_string(font, Vector2(-4, 6), label, HORIZONTAL_ALIGNMENT_CENTER, -1, 16, Color.WHITE)
