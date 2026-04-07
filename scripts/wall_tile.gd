extends Node2D
## Wall tile renderer – composes walls from individual pieces.
## Horizontal: uses 3 textures at natural aspect ratio, placed side by side.
## Vertical: uses vertical-short.png with 20% overlap.

# ── Textures ─────────────────────────────────────────────────────────────────
var _tex_h      := preload("res://assets/tiles/horizontal.png")
var _tex_h2     := preload("res://assets/tiles/horizontal_2.png")
var _tex_h3     := preload("res://assets/tiles/horizontal_3.png")
var _tex_v      := preload("res://assets/tiles/vertical-short.png")
var _tex_center := preload("res://assets/tiles/Center.png")

const V_OVERLAP := 0.20  # 20% overlap between vertical pieces
const H_SCALE   := 1.4   # horizontal pieces are 40% larger than cell

# ── Draw ──────────────────────────────────────────────────────────────────────
func _draw() -> void:
	var cell_sz: float = get_meta("cell_size", 64.0)
	var t: bool = get_meta("has_t", false)
	var b: bool = get_meta("has_b", false)
	var l: bool = get_meta("has_l", false)
	var r: bool = get_meta("has_r", false)

	var half := cell_sz * 0.5
	var has_horiz := l or r
	var has_vert := t or b

	var v_extra := cell_sz * V_OVERLAP

	# Draw horizontal pieces – laid out across the entire run, this cell
	# only draws the portion that falls within its boundaries
	if has_horiz:
		_draw_horiz(cell_sz, half)

	# Draw vertical arm(s) – full vertical-short piece with overlap
	if has_vert:
		var dest := Rect2(-half, -half - v_extra, cell_sz, cell_sz + v_extra * 2.0)
		draw_texture_rect(_tex_v, dest, false)

	# Isolated wall – center blob
	if not has_horiz and not has_vert:
		var dest := Rect2(-half, -half, cell_sz, cell_sz)
		draw_texture_rect(_tex_center, dest, false)

	# Debug label: run offset for horizontal, "v" or "c" otherwise
	var font := ThemeDB.fallback_font
	var label: String
	if has_horiz:
		label = str(int(get_meta("h_run_offset", 0)))
	elif has_vert:
		label = "v"
	else:
		label = "c"
	var fs := 18
	var y := -cell_sz * 0.55
	draw_string(font, Vector2(-6, y + 1), label, HORIZONTAL_ALIGNMENT_CENTER, -1, fs, Color.BLACK)
	draw_string(font, Vector2(-5, y), label, HORIZONTAL_ALIGNMENT_CENTER, -1, fs, Color.WHITE)

## Lay out h1, h2, h3 pieces sequentially across the horizontal run.
## This cell only draws the slice that falls within its own [-half, +half] x-range.
func _draw_horiz(cell_sz: float, half: float) -> void:
	var pieces: Array[Texture2D] = [_tex_h, _tex_h2, _tex_h3]
	var h := cell_sz * H_SCALE

	# Compute drawn widths at the target height, preserving aspect ratio
	var widths: Array[float] = []
	for tex in pieces:
		var ratio := float(tex.get_width()) / float(tex.get_height())
		widths.append(h * ratio)

	var run_offset: int = int(get_meta("h_run_offset", 0))
	var cell_start := float(run_offset) * cell_sz   # px from run start
	var cell_end := cell_start + cell_sz

	# Walk piece positions from start of run
	var piece_x := 0.0
	var piece_idx := 0
	while piece_x < cell_end:
		var idx := piece_idx % pieces.size()
		var tex := pieces[idx]
		var w := widths[idx]
		var piece_end := piece_x + w

		if piece_end > cell_start:
			# Visible region inside this cell
			var vis_start := maxf(piece_x, cell_start)
			var vis_end := minf(piece_end, cell_end)
			var local_x := vis_start - cell_start          # 0..cell_sz
			var local_w := vis_end - vis_start

			# Source region in texture pixels
			var tex_w := float(tex.get_width())
			var tex_h := float(tex.get_height())
			var src_x := ((vis_start - piece_x) / w) * tex_w
			var src_w := (local_w / w) * tex_w

			var src_rect := Rect2(src_x, 0.0, src_w, tex_h)
			var dest_rect := Rect2(local_x - half, -h * 0.5, local_w, h)
			draw_texture_rect_region(tex, dest_rect, src_rect)

		piece_x = piece_end
		piece_idx += 1
