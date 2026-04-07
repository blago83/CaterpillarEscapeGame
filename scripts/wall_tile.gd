extends Node2D
## Wall tile renderer – draws only vertical or center (isolated) pieces.
## Horizontal runs are placed as full Sprite2D nodes by level.gd.

var _tex_v      := preload("res://assets/tiles/vertical-short.png")
var _tex_center := preload("res://assets/tiles/Center.png")

func _draw() -> void:
	var cell_sz: float = get_meta("cell_size", 64.0)
	var mode: String = get_meta("mode", "center")
	var half := cell_sz * 0.5

	if mode == "vertical":
		var v_pad := cell_sz * 0.10 + 10.0  # extend 10% + 10px to connect with neighbors
		var dest := Rect2(-half, -half - v_pad, cell_sz, cell_sz + v_pad * 2.0)
		draw_texture_rect(_tex_v, dest, false)
	else:
		var dest := Rect2(-half, -half, cell_sz, cell_sz)
		draw_texture_rect(_tex_center, dest, false)
