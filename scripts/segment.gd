extends Node2D
## Caterpillar segment – fully procedural pseudo-3D rendering.
## Set meta "seg_type" = "head" | "body" | "tail"
## Set meta "seg_index" = 0-based index from head

const S := 64.0 * 0.5
const SHADOW := Vector2(3, 4)
const SHADOW_COL := Color(0, 0, 0, 0.25)

# ── Palette ──
const GREEN_LIGHT  := Color(0.45, 0.82, 0.22)
const GREEN_BASE   := Color(0.30, 0.68, 0.12)
const GREEN_DARK   := Color(0.18, 0.48, 0.06)
const GREEN_BELLY  := Color(0.55, 0.88, 0.35)
const YELLOW_SPOT  := Color(0.85, 0.92, 0.25)
const SHOE_COL     := Color(0.85, 0.15, 0.15)
const SHOE_DARK    := Color(0.6, 0.08, 0.08)
const SHOE_SHINE   := Color(1.0, 0.45, 0.4)

func _draw() -> void:
	var seg_type: String = get_meta("seg_type", "body")
	match seg_type:
		"head": _draw_head()
		"tail": _draw_tail()
		_: _draw_body()

# ── HEAD ──────────────────────────────────────────────────────────────────────
func _draw_head() -> void:
	var r := S * 0.78

	# Drop shadow
	draw_circle(SHADOW, r, SHADOW_COL)

	# Base sphere
	draw_circle(Vector2.ZERO, r, GREEN_BASE)
	# Bottom shading (darker hemisphere)
	draw_circle(Vector2(0, r * 0.2), r * 0.75, GREEN_DARK)
	# Top highlight (light dome)
	draw_circle(Vector2(-r * 0.15, -r * 0.22), r * 0.55, GREEN_LIGHT)
	# Specular spot
	draw_circle(Vector2(-r * 0.25, -r * 0.35), r * 0.2, Color(1, 1, 1, 0.3))

	# Eyes – white sclera with 3D shading
	for ey in [-1.0, 1.0]:
		var ep := Vector2(r * 0.35, ey * r * 0.32)
		# Eye shadow
		draw_circle(ep + Vector2(1, 2), r * 0.24, Color(0, 0, 0, 0.15))
		# Sclera
		draw_circle(ep, r * 0.24, Color.WHITE)
		# Iris
		draw_circle(ep + Vector2(r * 0.06, 0), r * 0.15, Color(0.12, 0.12, 0.12))
		# Pupil
		draw_circle(ep + Vector2(r * 0.09, ey * r * 0.02), r * 0.08, Color.BLACK)
		# Eye shine
		draw_circle(ep + Vector2(-r * 0.04, -ey * r * 0.06), r * 0.07, Color(1, 1, 1, 0.8))

	# Antennae
	for ay in [-1.0, 1.0]:
		var a_base := Vector2(r * 0.15, ay * r * 0.55)
		var a_tip := Vector2(r * 0.6, ay * r * 0.9)
		var a_mid := Vector2(r * 0.45, ay * r * 0.8)
		# Stalk
		draw_line(a_base, a_mid, GREEN_DARK, 2.5, true)
		draw_line(a_mid, a_tip, GREEN_DARK, 2.0, true)
		# Bulb
		draw_circle(a_tip, 4.5, GREEN_LIGHT)
		draw_circle(a_tip + Vector2(-1, -1), 2.0, Color(1, 1, 1, 0.4))

	# Smile
	draw_arc(Vector2(r * 0.3, 0), r * 0.18, -0.8, 0.8, 10, Color(0.12, 0.35, 0.04), 2.0, true)

	# Cheeks (blush)
	for cy in [-1.0, 1.0]:
		draw_circle(Vector2(r * 0.15, cy * r * 0.55), r * 0.12, Color(1.0, 0.5, 0.3, 0.2))

	# Shoes
	_draw_shoe(Vector2(-r * 0.85, -r * 0.6), Vector2(r * 0.45, r * 0.3))
	_draw_shoe(Vector2(-r * 0.85, r * 0.3), Vector2(r * 0.45, r * 0.3))

# ── BODY ──────────────────────────────────────────────────────────────────────
func _draw_body() -> void:
	var seg_idx: int = get_meta("seg_index", 1)
	var r := S * 0.72

	# Drop shadow
	draw_circle(SHADOW, r, SHADOW_COL)

	# Base sphere
	draw_circle(Vector2.ZERO, r, GREEN_BASE)

	# Bottom shading
	draw_circle(Vector2(0, r * 0.2), r * 0.7, GREEN_DARK)

	# Top light dome
	draw_circle(Vector2(-r * 0.12, -r * 0.2), r * 0.52, GREEN_LIGHT)

	# Specular
	draw_circle(Vector2(-r * 0.2, -r * 0.3), r * 0.18, Color(1, 1, 1, 0.25))

	# Belly stripe (lighter band across center)
	draw_circle(Vector2(0, 0), r * 0.35, GREEN_BELLY)

	# Decorative spots (alternate pattern per segment)
	if seg_idx % 2 == 0:
		for sy in [-1.0, 1.0]:
			draw_circle(Vector2(0, sy * r * 0.35), r * 0.12, YELLOW_SPOT)
	else:
		draw_circle(Vector2(r * 0.2, 0), r * 0.1, YELLOW_SPOT)
		draw_circle(Vector2(-r * 0.2, 0), r * 0.1, YELLOW_SPOT)

	# Subtle segment line (ring around the sphere)
	draw_arc(Vector2.ZERO, r * 0.95, 0, TAU, 24, Color(0, 0, 0, 0.08), 1.5, true)

	# Shoes
	_draw_shoe(Vector2(-r * 0.8, -r * 0.55), Vector2(r * 0.4, r * 0.28))
	_draw_shoe(Vector2(-r * 0.8, r * 0.28), Vector2(r * 0.4, r * 0.28))

# ── TAIL ──────────────────────────────────────────────────────────────────────
func _draw_tail() -> void:
	var r := S * 0.6

	# Drop shadow
	draw_circle(SHADOW * 0.8, r, SHADOW_COL)

	# Tapered sphere base
	draw_circle(Vector2.ZERO, r, GREEN_BASE)
	draw_circle(Vector2(0, r * 0.15), r * 0.65, GREEN_DARK)
	draw_circle(Vector2(-r * 0.1, -r * 0.18), r * 0.45, GREEN_LIGHT)
	draw_circle(Vector2(-r * 0.18, -r * 0.28), r * 0.15, Color(1, 1, 1, 0.22))

	# Tail tip (small pointed sphere trailing behind)
	var tip_pos := Vector2(-r * 0.7, 0)
	draw_circle(tip_pos + Vector2(1, 2), r * 0.3, SHADOW_COL)
	draw_circle(tip_pos, r * 0.35, GREEN_BASE)
	draw_circle(tip_pos + Vector2(-r * 0.05, -r * 0.08), r * 0.2, GREEN_LIGHT)

	# Shoes (smaller)
	_draw_shoe(Vector2(-r * 0.5, -r * 0.55), Vector2(r * 0.35, r * 0.25))
	_draw_shoe(Vector2(-r * 0.5, r * 0.3), Vector2(r * 0.35, r * 0.25))

# ── SHOE (pseudo-3D) ─────────────────────────────────────────────────────────
func _draw_shoe(pos: Vector2, sz: Vector2) -> void:
	var cr := sz.y * 0.3  # corner radius feel via layering
	# Shadow
	draw_rect(Rect2(pos.x + 2, pos.y + 2, sz.x, sz.y), Color(0, 0, 0, 0.2))
	# Base
	draw_rect(Rect2(pos.x, pos.y, sz.x, sz.y), SHOE_COL)
	# Sole (dark bottom)
	draw_rect(Rect2(pos.x, pos.y + sz.y - 3, sz.x, 3), SHOE_DARK)
	# Top highlight
	draw_rect(Rect2(pos.x + 2, pos.y + 1, sz.x * 0.55, 2), SHOE_SHINE)
	# Tiny specular dot
	draw_circle(Vector2(pos.x + sz.x * 0.3, pos.y + sz.y * 0.25), 1.5, Color(1, 1, 1, 0.4))
