extends Node3D

class_name MouthComponent3D

@export var face_color := Color(0.62, 0.85, 0.28)
@export var mouth_cavity_color := Color(0.19, 0.07, 0.04)
@export var tongue_color := Color(0.92, 0.30, 0.26)
@export var drool_enabled := false
@export var pixel_size := 0.0038

var _sprite: Sprite3D
var _textures: Dictionary = {}
var _current_expression := "idle"

func _ready() -> void:
	_sprite = Sprite3D.new()
	_sprite.centered = true
	_sprite.pixel_size = pixel_size
	_sprite.double_sided = true
	_sprite.shaded = false
	_sprite.cast_shadow = GeometryInstance3D.SHADOW_CASTING_SETTING_OFF
	add_child(_sprite)

	_textures["idle"] = _make_mouth_texture("idle")
	_textures["happy"] = _make_mouth_texture("happy")
	_textures["looking"] = _make_mouth_texture("looking")
	_textures["sleeping"] = _make_mouth_texture("sleeping")
	set_expression("idle")

func set_expression(expr: String) -> void:
	_current_expression = expr if _textures.has(expr) else "idle"
	if _sprite:
		_sprite.texture = _textures[_current_expression]

func _make_mouth_texture(expr: String) -> Texture2D:
	var image := Image.create(256, 192, false, Image.FORMAT_RGBA8)
	image.fill(Color(0.0, 0.0, 0.0, 0.0))

	match expr:
		"happy":
			_draw_open_smile(image, Vector2(128, 113), Vector2(46, 34), Vector2(128, 81), 0.96, true)
		"looking":
			_draw_open_smile(image, Vector2(128, 113), Vector2(38, 26), Vector2(128, 82), 0.76, false)
		"sleeping":
			_draw_sleeping_mouth(image)
		_:
			_draw_open_smile(image, Vector2(128, 113), Vector2(40, 28), Vector2(128, 82), 0.82, false)

	return ImageTexture.create_from_image(image)

func _draw_open_smile(image: Image, cavity_center: Vector2, cavity_radius: Vector2, lip_center: Vector2, tongue_scale: float, include_drool: bool) -> void:
	var half_width: int = int(round(cavity_radius.x))
	var flat_top_y: int = int(round(cavity_center.y - cavity_radius.y * 0.78))
	var side_height: int = int(round(cavity_radius.y * 0.90))
	var bottom_radius_y: float = cavity_radius.y * 0.72
	var bottom_center := Vector2(cavity_center.x, float(flat_top_y + side_height))
	# True D-shaped cavity: flat top and vertical-ish sides, rounded bottom.
	_fill_rect(
		image,
		Rect2i(
			int(round(cavity_center.x)) - half_width,
			flat_top_y,
			half_width * 2,
			side_height
		),
		mouth_cavity_color
	)
	_fill_ellipse(image, bottom_center, Vector2(cavity_radius.x, bottom_radius_y), mouth_cavity_color)
	# Keep the upper lip as a separate painted shape over the cavity.
	_fill_ellipse(image, lip_center + Vector2(0, -2), Vector2(cavity_radius.x * 0.34, cavity_radius.y * 0.21), face_color)
	_fill_ellipse(image, lip_center + Vector2(-cavity_radius.x * 0.30, 1), Vector2(cavity_radius.x * 0.15, cavity_radius.y * 0.17), face_color)
	_fill_ellipse(image, lip_center + Vector2(cavity_radius.x * 0.30, 1), Vector2(cavity_radius.x * 0.15, cavity_radius.y * 0.17), face_color)
	_fill_ellipse(image, lip_center + Vector2(0, 7), Vector2(cavity_radius.x * 0.15, cavity_radius.y * 0.14), face_color)
	_fill_rect(
		image,
		Rect2i(
			int(round(lip_center.x - cavity_radius.x * 0.44)),
			int(round(lip_center.y - cavity_radius.y * 0.13)),
			int(round(cavity_radius.x * 0.88)),
			maxi(3, int(round(cavity_radius.y * 0.13)))
		),
		face_color
	)
	# Thin dark inner rim just below the upper lip.
	_fill_rect(
		image,
		Rect2i(
			int(round(cavity_center.x - cavity_radius.x * 0.88)),
			int(round(flat_top_y + 2)),
			int(round(cavity_radius.x * 1.76)),
			3
		),
		Color(0.30, 0.10, 0.07, 0.92)
	)
	# Red tongue lower in the cavity.
	_fill_ellipse(image, cavity_center + Vector2(0, cavity_radius.y * 0.42), Vector2(18, 9) * tongue_scale, tongue_color)
	_fill_ellipse(image, cavity_center + Vector2(-10, cavity_radius.y * 0.26), Vector2(11, 9) * tongue_scale, tongue_color)
	_fill_ellipse(image, cavity_center + Vector2(10, cavity_radius.y * 0.26), Vector2(11, 9) * tongue_scale, tongue_color)
	_fill_ellipse(image, cavity_center + Vector2(0, cavity_radius.y * 0.16), Vector2(2.2, 9) * tongue_scale, Color(0.70, 0.16, 0.15, 0.56))
	_fill_ellipse(image, cavity_center + Vector2(8, cavity_radius.y * 0.18), Vector2(6, 4) * tongue_scale, Color(1.0, 0.90, 0.88, 0.24))
	if include_drool and drool_enabled:
		_fill_ellipse(image, cavity_center + Vector2(-8, -3), Vector2(4, 4), Color(1.0, 0.98, 0.90, 0.50))
		_fill_capsule_v(image, cavity_center + Vector2(0, 44), 5, 20, Color(1.0, 0.98, 0.90, 0.34))
		_fill_ellipse(image, cavity_center + Vector2(0, 64), Vector2(6, 10), Color(1.0, 0.98, 0.90, 0.34))

func _draw_cute_closed_smile(image: Image, center: Vector2) -> void:
	var line_color := Color(0.24, 0.08, 0.07, 0.92)
	_draw_arc_band(image, center + Vector2(-10, 0), Vector2(11, 7), 2.6, line_color, 0.10, PI - 0.28)
	_draw_arc_band(image, center + Vector2(10, 0), Vector2(11, 7), 2.6, line_color, 0.28, PI - 0.10)
	_draw_arc_band(image, center + Vector2(0, -1), Vector2(6, 4), 2.4, line_color, 0.18, PI - 0.18)
	_fill_ellipse(image, center + Vector2(0, 6), Vector2(6, 2), Color(0.86, 0.70, 0.54, 0.45))

func _draw_sleeping_mouth(image: Image) -> void:
	_draw_arc_band(image, Vector2(128, 109), Vector2(18, 7), 2.8, Color(0.24, 0.08, 0.07, 0.88), 0.10, PI - 0.10)
	_fill_ellipse(image, Vector2(128, 113), Vector2(7, 3), Color(0.80, 0.44, 0.42, 0.42))

func _fill_rect(image: Image, rect: Rect2i, color: Color) -> void:
	for y in range(rect.position.y, rect.position.y + rect.size.y):
		for x in range(rect.position.x, rect.position.x + rect.size.x):
			_blend_pixel(image, x, y, color)

func _fill_capsule_h(image: Image, center: Vector2, half_width: int, radius: int, color: Color) -> void:
	_fill_rect(image, Rect2i(int(center.x) - half_width, int(center.y) - radius, half_width * 2, radius * 2), color)
	_fill_ellipse(image, center + Vector2(-half_width, 0), Vector2(radius, radius), color)
	_fill_ellipse(image, center + Vector2(half_width, 0), Vector2(radius, radius), color)

func _fill_capsule_v(image: Image, center: Vector2, radius: int, half_height: int, color: Color) -> void:
	_fill_rect(image, Rect2i(int(center.x) - radius, int(center.y) - half_height, radius * 2, half_height * 2), color)
	_fill_ellipse(image, center + Vector2(0, -half_height), Vector2(radius, radius), color)
	_fill_ellipse(image, center + Vector2(0, half_height), Vector2(radius, radius), color)

func _fill_ellipse(image: Image, center: Vector2, radius: Vector2, color: Color) -> void:
	var min_x := int(floor(center.x - radius.x))
	var max_x := int(ceil(center.x + radius.x))
	var min_y := int(floor(center.y - radius.y))
	var max_y := int(ceil(center.y + radius.y))
	for y in range(min_y, max_y + 1):
		for x in range(min_x, max_x + 1):
			var nx := (float(x) - center.x) / maxf(radius.x, 0.001)
			var ny := (float(y) - center.y) / maxf(radius.y, 0.001)
			if nx * nx + ny * ny <= 1.0:
				_blend_pixel(image, x, y, color)

func _draw_arc_band(image: Image, center: Vector2, radius: Vector2, thickness: float, color: Color, start_angle: float, end_angle: float) -> void:
	var min_x := int(floor(center.x - radius.x - thickness - 1.0))
	var max_x := int(ceil(center.x + radius.x + thickness + 1.0))
	var min_y := int(floor(center.y - radius.y - thickness - 1.0))
	var max_y := int(ceil(center.y + radius.y + thickness + 1.0))
	for y in range(min_y, max_y + 1):
		for x in range(min_x, max_x + 1):
			var nx := (float(x) - center.x) / maxf(radius.x, 0.001)
			var ny := (float(y) - center.y) / maxf(radius.y, 0.001)
			var dist := sqrt(nx * nx + ny * ny)
			var angle := atan2(ny, nx)
			if angle < 0.0:
				angle += TAU
			if angle >= start_angle and angle <= end_angle and absf(dist - 1.0) <= thickness / maxf(radius.x, radius.y):
				_blend_pixel(image, x, y, color)

func _blend_pixel(image: Image, x: int, y: int, color: Color) -> void:
	if x < 0 or y < 0 or x >= image.get_width() or y >= image.get_height():
		return
	var dst := image.get_pixel(x, y)
	var src_a := color.a
	var out_a := src_a + dst.a * (1.0 - src_a)
	var out_r := color.r * src_a + dst.r * (1.0 - src_a)
	var out_g := color.g * src_a + dst.g * (1.0 - src_a)
	var out_b := color.b * src_a + dst.b * (1.0 - src_a)
	image.set_pixel(x, y, Color(out_r, out_g, out_b, out_a))