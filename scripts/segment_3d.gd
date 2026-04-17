extends Node3D
## 3D Caterpillar segment – cartoon style with big eyes and red shoes.

const CELL := 1.0

var _mesh: MeshInstance3D
var _mat: StandardMaterial3D
var _shoe_left: MeshInstance3D
var _shoe_right: MeshInstance3D
var _leg_phase := 0.0
var _base_mesh_y := 0.35

func _ready() -> void:
	var seg_type: String = get_meta("seg_type", "body")

	_mesh = MeshInstance3D.new()
	_mat = StandardMaterial3D.new()
	_mat.shading_mode = BaseMaterial3D.SHADING_MODE_UNSHADED

	var radius: float
	match seg_type:
		"head":
			radius = 0.28
			_mat.albedo_color = Color(0.45, 0.82, 0.22)
		"tail":
			radius = 0.24
			_mat.albedo_color = Color(0.40, 0.72, 0.20)
		_:
			radius = 0.26
			_mat.albedo_color = Color(0.42, 0.78, 0.18)

	var sphere := SphereMesh.new()
	sphere.radius = radius
	sphere.height = radius * 2.0
	sphere.radial_segments = 24
	sphere.rings = 12
	_mesh.mesh = sphere
	_mesh.material_override = _mat
	_mesh.position.y = radius
	_base_mesh_y = radius
	_mesh.cast_shadow = GeometryInstance3D.SHADOW_CASTING_SETTING_OFF
	add_child(_mesh)

	if seg_type == "head":
		_add_eyes(radius)
		_add_mouth(radius)
		_add_shoes(radius, true)
	else:
		_add_shoes(radius, seg_type == "tail")

func _add_eyes(head_radius: float) -> void:
	var eye_white_mat := StandardMaterial3D.new()
	eye_white_mat.shading_mode = BaseMaterial3D.SHADING_MODE_UNSHADED
	eye_white_mat.albedo_color = Color(1, 1, 1)
	var pupil_mat := StandardMaterial3D.new()
	pupil_mat.shading_mode = BaseMaterial3D.SHADING_MODE_UNSHADED
	pupil_mat.albedo_color = Color(0.05, 0.05, 0.05)

	for side in [-1.0, 1.0]:
		# Big white eye
		var eye := MeshInstance3D.new()
		var eye_s := SphereMesh.new()
		eye_s.radius = 0.11
		eye_s.height = 0.22
		eye.mesh = eye_s
		eye.material_override = eye_white_mat
		eye.position = Vector3(side * 0.14, head_radius * 0.5, -head_radius * 0.7)
		_mesh.add_child(eye)

		# Big black pupil
		var pupil := MeshInstance3D.new()
		var pupil_s := SphereMesh.new()
		pupil_s.radius = 0.06
		pupil_s.height = 0.12
		pupil.mesh = pupil_s
		pupil.material_override = pupil_mat
		pupil.position = Vector3(side * 0.02, 0.0, -0.06)
		eye.add_child(pupil)

		# Tiny white highlight dot
		var highlight := MeshInstance3D.new()
		var hl_s := SphereMesh.new()
		hl_s.radius = 0.02
		hl_s.height = 0.04
		highlight.mesh = hl_s
		highlight.material_override = eye_white_mat
		highlight.position = Vector3(-0.02, 0.03, -0.04)
		pupil.add_child(highlight)

func _add_mouth(head_radius: float) -> void:
	# Simple smiling mouth – a small dark torus-like shape using a flattened sphere
	var mouth_mat := StandardMaterial3D.new()
	mouth_mat.shading_mode = BaseMaterial3D.SHADING_MODE_UNSHADED
	mouth_mat.albedo_color = Color(0.15, 0.08, 0.05)
	var mouth := MeshInstance3D.new()
	var mouth_s := SphereMesh.new()
	mouth_s.radius = 0.08
	mouth_s.height = 0.04
	mouth.mesh = mouth_s
	mouth.material_override = mouth_mat
	mouth.position = Vector3(0.0, -head_radius * 0.15, -head_radius * 0.9)
	mouth.scale = Vector3(1.2, 0.5, 0.5)
	_mesh.add_child(mouth)

func _add_shoes(seg_radius: float, is_small: bool) -> void:
	var shoe_mat := StandardMaterial3D.new()
	shoe_mat.shading_mode = BaseMaterial3D.SHADING_MODE_UNSHADED
	shoe_mat.albedo_color = Color(0.85, 0.15, 0.1)  # Red shoes
	var sole_mat := StandardMaterial3D.new()
	sole_mat.shading_mode = BaseMaterial3D.SHADING_MODE_UNSHADED
	sole_mat.albedo_color = Color(0.95, 0.85, 0.5)  # Yellow-ish sole

	var shoe_w := 0.08 if is_small else 0.1
	var shoe_h := 0.08
	var shoe_d := 0.14 if is_small else 0.16
	var spread := seg_radius * 0.9

	for side_data in [[-1.0, "_shoe_left"], [1.0, "_shoe_right"]]:
		var side: float = side_data[0]
		var shoe := MeshInstance3D.new()
		var shoe_box := BoxMesh.new()
		shoe_box.size = Vector3(shoe_w, shoe_h, shoe_d)
		shoe.mesh = shoe_box
		shoe.material_override = shoe_mat
		shoe.position = Vector3(side * spread, -seg_radius + shoe_h * 0.5 + 0.01, -0.02)
		shoe.cast_shadow = GeometryInstance3D.SHADOW_CASTING_SETTING_OFF
		_mesh.add_child(shoe)

		# Sole (bottom)
		var sole := MeshInstance3D.new()
		var sole_box := BoxMesh.new()
		sole_box.size = Vector3(shoe_w * 1.1, 0.02, shoe_d * 1.15)
		sole.mesh = sole_box
		sole.material_override = sole_mat
		sole.position = Vector3(0, -shoe_h * 0.5, 0.01)
		sole.cast_shadow = GeometryInstance3D.SHADOW_CASTING_SETTING_OFF
		shoe.add_child(sole)

		if side < 0:
			_shoe_left = shoe
		else:
			_shoe_right = shoe

	_leg_phase = float(get_meta("seg_index", 0)) * 0.5 * PI

func wiggle_legs() -> void:
	if not _shoe_left or not _shoe_right:
		return
	_leg_phase += 1.0
	var dir := 1.0 if fmod(_leg_phase, 2.0) < 1.0 else -1.0
	# Shoes swing forward/back
	_shoe_left.position.z = -0.02 + dir * 0.04
	_shoe_right.position.z = -0.02 - dir * 0.04
	# Subtle bob
	if _mesh:
		_mesh.position.y = _base_mesh_y + 0.02 * dir

func update_direction(_is_horizontal: bool) -> void:
	pass  # 3D lighting handles depth naturally

func update_seg_type(new_type: String) -> void:
	set_meta("seg_type", new_type)
	if not _mesh or not _mat:
		return
	var sphere := _mesh.mesh as SphereMesh
	if not sphere:
		return
	match new_type:
		"head":
			sphere.radius = 0.28
			sphere.height = 0.56
			_mat.albedo_color = Color(0.45, 0.82, 0.22)
			_base_mesh_y = 0.28
			_mesh.position.y = 0.28
		"tail":
			sphere.radius = 0.24
			sphere.height = 0.48
			_mat.albedo_color = Color(0.40, 0.72, 0.20)
			_base_mesh_y = 0.24
			_mesh.position.y = 0.24
		_:
			sphere.radius = 0.26
			sphere.height = 0.52
			_mat.albedo_color = Color(0.42, 0.78, 0.18)
			_base_mesh_y = 0.26
			_mesh.position.y = 0.26

func flash_red() -> void:
	if _mat:
		_mat.albedo_color = Color(1, 0.5, 0.5)

func set_head_direction(_vertical: bool) -> void:
	pass
