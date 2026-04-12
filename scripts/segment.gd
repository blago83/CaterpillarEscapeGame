extends Node2D
## Caterpillar segment – sprite-based rendering using caterpillar art assets.
## Set meta "seg_type" = "head" | "body" | "tail"
## Set meta "seg_index" = 0-based index from head

const CELL := 64.0

# Preload caterpillar textures
var _head_tex: Texture2D = preload("res://assets/caterpillar/caterpillar_face.png")
var _head_vertical_tex: Texture2D = preload("res://assets/caterpillar/caterpillar_vertical_head_up.png")
var _body_tex: Texture2D = preload("res://assets/caterpillar/Caterpillar_vertical.png")
var _tail_tex: Texture2D = preload("res://assets/caterpillar/caterpillar_vertical_last.png")

var _sprite: Sprite2D
var _inner_shadow: Sprite2D
var _leg_left: Sprite2D
var _leg_right: Sprite2D
var _leg_tex: Texture2D = preload("res://assets/caterpillar/leg.png")
var _leg_phase := 0.0

func _ready() -> void:
	var seg_type: String = get_meta("seg_type", "body")

	_sprite = Sprite2D.new()
	match seg_type:
		"head":
			_sprite.texture = _head_vertical_tex
		_:
			_sprite.texture = _body_tex

	# Sprites are drawn facing UP; rotate PI/2 to align with default RIGHT direction
	_sprite.rotation = PI / 2.0

	# Scale texture to fit within cell
	var tex_w := float(_sprite.texture.get_width())
	var tex_h := float(_sprite.texture.get_height())
	var fit := CELL * 1.0
	var s: float = fit / maxf(tex_w, tex_h)
	_sprite.scale = Vector2(s, s)

	# Drop shadow behind the sprite
	var shadow := Sprite2D.new()
	shadow.texture = _sprite.texture
	shadow.rotation = _sprite.rotation
	shadow.scale = Vector2(s * 1.08, s * 1.08)
	shadow.modulate = Color(0, 0, 0, 0.35)
	shadow.position = Vector2(2, 3)
	shadow.z_index = -2
	add_child(shadow)

	add_child(_sprite)

	# Inner shadow for pseudo-3D effect (hidden by default, shown when horizontal)
	_inner_shadow = Sprite2D.new()
	_inner_shadow.texture = _sprite.texture
	_inner_shadow.rotation = _sprite.rotation
	_inner_shadow.scale = Vector2(s * 0.95, s * 0.5)
	_inner_shadow.modulate = Color(0, 0, 0, 0.25)
	_inner_shadow.position = Vector2(0, CELL * 0.15)
	_inner_shadow.visible = false
	add_child(_inner_shadow)

	# Add legs to body and tail segments
	if seg_type == "body" or seg_type == "tail":
		var leg_offset_x := CELL * 0.3 if seg_type == "tail" else 0.0
		var leg_s := (CELL * 0.35) / maxf(float(_leg_tex.get_width()), float(_leg_tex.get_height()))
		# Left leg
		_leg_left = Sprite2D.new()
		_leg_left.texture = _leg_tex
		_leg_left.scale = Vector2(leg_s, leg_s)
		_leg_left.position = Vector2(-leg_offset_x, -CELL * 0.5)
		_leg_left.z_index = -1
		add_child(_leg_left)
		# Right leg (mirrored)
		_leg_right = Sprite2D.new()
		_leg_right.texture = _leg_tex
		_leg_right.scale = Vector2(leg_s, leg_s)
		_leg_right.position = Vector2(-leg_offset_x, CELL * 0.5)
		_leg_right.z_index = -1
		add_child(_leg_right)
		# Offset phase by segment index for varied motion
		_leg_phase = float(get_meta("seg_index", 0)) * 0.5 * PI

func update_direction(is_horizontal: bool) -> void:
	# Hide top leg and show inner shadow when moving horizontally
	if _leg_left:
		_leg_left.visible = not is_horizontal
	if _inner_shadow:
		_inner_shadow.visible = is_horizontal

func wiggle_legs() -> void:
	if not _leg_left or not _leg_right:
		return
	_leg_phase += 1.0
	var angle := deg_to_rad(30.0)
	var dir := 1.0 if fmod(_leg_phase, 2.0) < 1.0 else -1.0
	_leg_left.rotation = dir * angle
	_leg_right.rotation = -dir * angle
	# Subtle perpendicular bob on the sprite
	if _sprite:
		var bob := 2.0 * dir
		var tw := create_tween()
		tw.tween_property(_sprite, "position:y", bob, 0.1)
		tw.tween_property(_sprite, "position:y", 0.0, 0.1)

func _apply_texture(tex: Texture2D) -> void:
	_sprite.texture = tex
	var tex_w := float(tex.get_width())
	var tex_h := float(tex.get_height())
	var fit := CELL * 1.0
	var s: float = fit / maxf(tex_w, tex_h)
	_sprite.scale = Vector2(s, s)

func set_head_direction(_vertical: bool) -> void:
	pass

func update_seg_type(new_type: String) -> void:
	set_meta("seg_type", new_type)
	if not _sprite:
		return
	match new_type:
		"head":
			_apply_texture(_head_vertical_tex)
		"tail":
			_apply_texture(_body_tex)
			if not _leg_left:
				_add_legs(true)
			else:
				_reposition_legs(true)
		_:
			_apply_texture(_body_tex)
			if not _leg_left:
				_add_legs(false)
			else:
				_reposition_legs(false)

func _add_legs(is_tail: bool) -> void:
	var leg_offset_x := CELL * 0.3 if is_tail else 0.0
	var leg_s := (CELL * 0.35) / maxf(float(_leg_tex.get_width()), float(_leg_tex.get_height()))
	_leg_left = Sprite2D.new()
	_leg_left.texture = _leg_tex
	_leg_left.scale = Vector2(leg_s, leg_s)
	_leg_left.position = Vector2(-leg_offset_x, -CELL * 0.5)
	_leg_left.z_index = -1
	add_child(_leg_left)
	_leg_right = Sprite2D.new()
	_leg_right.texture = _leg_tex
	_leg_right.scale = Vector2(leg_s, leg_s)
	_leg_right.position = Vector2(-leg_offset_x, CELL * 0.5)
	_leg_right.z_index = -1
	add_child(_leg_right)
	_leg_phase = float(get_meta("seg_index", 0)) * 0.5 * PI

func _reposition_legs(is_tail: bool) -> void:
	var leg_offset_x := CELL * 0.3 if is_tail else 0.0
	if _leg_left:
		_leg_left.position = Vector2(-leg_offset_x, -CELL * 0.5)
	if _leg_right:
		_leg_right.position = Vector2(-leg_offset_x, CELL * 0.5)

func _remove_legs() -> void:
	if _leg_left:
		_leg_left.queue_free()
		_leg_left = null
	if _leg_right:
		_leg_right.queue_free()
		_leg_right = null
