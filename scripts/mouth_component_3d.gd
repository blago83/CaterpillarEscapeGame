extends Node3D

class_name MouthComponent3D

@export var face_color := Color(0.62, 0.85, 0.28)
@export var mouth_cavity_color := Color(0.19, 0.07, 0.04)
@export var tongue_color := Color(0.96, 0.67, 0.56)
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
			_draw_open_smile(image, Vector2(128, 107), Vector2(62, 36), Vector2(128, 80), 1.00, true)
		"looking":
			_draw_open_smile(image, Vector2(128, 108), Vector2(46, 31), Vector2(128, 81), 0.76, false)
		"sleeping":
			_draw_sleeping_mouth(image)
		_:
			_draw_open_smile(image, Vector2(128, 107), Vector2(54, 30), Vector2(128, 80), 0.88, false)

	return ImageTexture.create_from_image(image)

func _draw_open_smile(image: Image, cavity_center: Vector2, cavity_radius: Vector2, lip_center: Vector2, tongue_scale: float, include_drool: bool) -> void:
	var lip_half_width: int = int(round(cavity_radius.x * 0.34))
	var lip_radius: int = int(round(cavity_radius.y * 0.28))
	var lip_rect_height: int = maxi(3, int(round(lip_radius * 0.55)))
	# Dark cavity.
	_fill_ellipse(image, cavity_center, cavity_radius, mouth_cavity_color)
	# Small rounded upper lip cap in the face color.
	_fill_capsule_h(image, lip_center, lip_half_width, lip_radius, face_color)
	_fill_rect(image, Rect2i(int(lip_center.x - lip_half_width), int(lip_center.y - lip_rect_height * 0.5), lip_half_width * 2, lip_rect_height), face_color)
	# Thin dark smile line under the lip.
	_draw_arc_band(image, cavity_center + Vector2(0, -9), Vector2(cavity_radius.x * 0.94, cavity_radius.y * 0.62), 4.0, Color(0.32, 0.10, 0.07, 0.90), 0.08, PI - 0.08)
	# Tongue with two lobes.
	_fill_ellipse(image, cavity_center + Vector2(0, 14), Vector2(29, 15) * tongue_scale, tongue_color)
	_fill_ellipse(image, cavity_center + Vector2(-15, 9), Vector2(16, 13) * tongue_scale, tongue_color)
	_fill_ellipse(image, cavity_center + Vector2(15, 9), Vector2(16, 13) * tongue_scale, tongue_color)
	_fill_ellipse(image, cavity_center + Vector2(0, 6), Vector2(3, 16) * tongue_scale, Color(0.84, 0.50, 0.45, 0.65))
	_fill_ellipse(image, cavity_center + Vector2(15, 6), Vector2(10, 7) * tongue_scale, Color(1.0, 0.96, 0.93, 0.38))
	if include_drool and drool_enabled:
		_fill_ellipse(image, cavity_center + Vector2(-10, -6), Vector2(4, 4), Color(1.0, 0.98, 0.90, 0.50))
		_fill_capsule_v(image, cavity_center + Vector2(-2, 49), 6, 24, Color(1.0, 0.98, 0.90, 0.36))
		_fill_ellipse(image, cavity_center + Vector2(-2, 72), Vector2(7, 11), Color(1.0, 0.98, 0.90, 0.36))

func _draw_sleeping_mouth(image: Image) -> void:
	_draw_arc_band(image, Vector2(128, 106), Vector2(20, 8), 3.0, Color(0.24, 0.08, 0.07, 0.92), 0.10, PI - 0.10)
	_fill_ellipse(image, Vector2(128, 110), Vector2(8, 4), Color(0.80, 0.44, 0.42, 0.55))

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