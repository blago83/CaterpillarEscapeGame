extends Node3D
## 3D Caterpillar segment – sphere-based rendering with eyes and legs.

const CELL := 1.0

var _mesh: MeshInstance3D
var _mat: StandardMaterial3D
var _leg_left: Node3D
var _leg_right: Node3D
var _leg_phase := 0.0
var _base_mesh_y := 0.35

func _ready() -> void:
	var seg_type: String = get_meta("seg_type", "body")

	_mesh = MeshInstance3D.new()
	_mat = StandardMaterial3D.new()

	var radius: float
	match seg_type:
		"head":
			radius = 0.3
			_mat.albedo_color = Color(0.3, 0.8, 0.2)
		"tail":
			radius = 0.18
			_mat.albedo_color = Color(0.35, 0.65, 0.25)
		_:
			radius = 0.25
			_mat.albedo_color = Color(0.25, 0.72, 0.15)

	var sphere := SphereMesh.new()
	sphere.radius = radius
	sphere.height = radius * 2.0
	_mesh.mesh = sphere
	_mesh.material_override = _mat
	_mesh.position.y = radius
	_base_mesh_y = radius
	_mesh.cast_shadow = GeometryInstance3D.SHADOW_CASTING_SETTING_ON
	add_child(_mesh)

	if seg_type == "head":
		_add_eyes(radius)
	elif seg_type == "body" or seg_type == "tail":
		_add_legs(seg_type == "tail")

func _add_eyes(head_radius: float) -> void:
	var eye_white_mat := StandardMaterial3D.new()
	eye_white_mat.albedo_color = Color(1, 1, 1)
	var pupil_mat := StandardMaterial3D.new()
	pupil_mat.albedo_color = Color(0.05, 0.05, 0.05)

	for side in [-1.0, 1.0]:
		var eye := MeshInstance3D.new()
		var eye_s := SphereMesh.new()
		eye_s.radius = 0.07
		eye_s.height = 0.14
		eye.mesh = eye_s
		eye.material_override = eye_white_mat
		eye.position = Vector3(side * 0.12, head_radius * 0.3, -head_radius * 0.75)
		_mesh.add_child(eye)

		var pupil := MeshInstance3D.new()
		var pupil_s := SphereMesh.new()
		pupil_s.radius = 0.04
		pupil_s.height = 0.08
		pupil.mesh = pupil_s
		pupil.material_override = pupil_mat
		pupil.position = Vector3(0, 0, -0.05)
		eye.add_child(pupil)

func _add_legs(is_tail: bool) -> void:
	var leg_mat := StandardMaterial3D.new()
	leg_mat.albedo_color = Color(0.2, 0.55, 0.1)

	var leg_len := 0.25
	var leg_radius := 0.035
	var y_pos := 0.08
	var z_offset := 0.1 if is_tail else 0.0

	# Left leg
	_leg_left = Node3D.new()
	_leg_left.position = Vector3(-0.25, y_pos, z_offset)
	var left_mesh := MeshInstance3D.new()
	var left_cyl := CylinderMesh.new()
	left_cyl.top_radius = leg_radius
	left_cyl.bottom_radius = leg_radius * 1.3
	left_cyl.height = leg_len
	left_mesh.mesh = left_cyl
	left_mesh.material_override = leg_mat
	left_mesh.rotation.z = PI / 2.0
	left_mesh.position.x = -leg_len * 0.5
	left_mesh.cast_shadow = GeometryInstance3D.SHADOW_CASTING_SETTING_OFF
	_leg_left.add_child(left_mesh)
	add_child(_leg_left)

	# Right leg
	_leg_right = Node3D.new()
	_leg_right.position = Vector3(0.25, y_pos, z_offset)
	var right_mesh := MeshInstance3D.new()
	var right_cyl := CylinderMesh.new()
	right_cyl.top_radius = leg_radius
	right_cyl.bottom_radius = leg_radius * 1.3
	right_cyl.height = leg_len
	right_mesh.mesh = right_cyl
	right_mesh.material_override = leg_mat
	right_mesh.rotation.z = PI / 2.0
	right_mesh.position.x = leg_len * 0.5
	right_mesh.cast_shadow = GeometryInstance3D.SHADOW_CASTING_SETTING_OFF
	_leg_right.add_child(right_mesh)
	add_child(_leg_right)

	_leg_phase = float(get_meta("seg_index", 0)) * 0.5 * PI

func wiggle_legs() -> void:
	if not _leg_left or not _leg_right:
		return
	_leg_phase += 1.0
	var angle := deg_to_rad(25.0)
	var dir := 1.0 if fmod(_leg_phase, 2.0) < 1.0 else -1.0
	_leg_left.rotation.y = dir * angle
	_leg_right.rotation.y = -dir * angle
	# Subtle bob - direct set
	if _mesh:
		_mesh.position.y = _base_mesh_y + 0.03 * dir

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
			sphere.radius = 0.3
			sphere.height = 0.6
			_mat.albedo_color = Color(0.3, 0.8, 0.2)
			_base_mesh_y = 0.3
			_mesh.position.y = 0.3
			_remove_legs()
		"tail":
			sphere.radius = 0.18
			sphere.height = 0.36
			_mat.albedo_color = Color(0.35, 0.65, 0.25)
			_base_mesh_y = 0.18
			_mesh.position.y = 0.18
			if not _leg_left:
				_add_legs(true)
		_:
			sphere.radius = 0.25
			sphere.height = 0.5
			_mat.albedo_color = Color(0.25, 0.72, 0.15)
			_base_mesh_y = 0.25
			_mesh.position.y = 0.25
			if not _leg_left:
				_add_legs(false)

func flash_red() -> void:
	if _mat:
		_mat.albedo_color = Color(1, 0.5, 0.5)

func set_head_direction(_vertical: bool) -> void:
	pass

func _remove_legs() -> void:
	if _leg_left:
		_leg_left.queue_free()
		_leg_left = null
	if _leg_right:
		_leg_right.queue_free()
		_leg_right = null
