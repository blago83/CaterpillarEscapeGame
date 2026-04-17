extends Node3D
## 3D Caterpillar segment – cute cartoon style inspired by reference art.
## Plump overlapping body, big expressive eyes, antennae, rosy cheeks, tiny feet.

const CELL := 1.0

var _mesh: MeshInstance3D
var _mat: StandardMaterial3D
var _foot_left: MeshInstance3D
var _foot_right: MeshInstance3D
var _leg_phase := 0.0
var _base_mesh_y := 0.30

# ── Build ──

func _ready() -> void:
	var seg_type: String = get_meta("seg_type", "body")
	var seg_index: int = get_meta("seg_index", 1)

	# Main body sphere – plump, slightly squashed vertically
	_mesh = MeshInstance3D.new()
	_mat = StandardMaterial3D.new()
	_mat.specular = 0.35
	_mat.roughness = 0.65
	_mat.metallic = 0.0

	var radius: float
	match seg_type:
		"head":
			radius = 0.32
			# Lighter, warmer green for the head
			_mat.albedo_color = Color(0.62, 0.85, 0.28)
		"tail":
			radius = 0.22
			# Yellower tail tip
			_mat.albedo_color = Color(0.60, 0.80, 0.22)
		_:
			radius = 0.28
			# Rich green body with subtle per-segment variation
			var g := 0.78 + float(seg_index % 3) * 0.03
			_mat.albedo_color = Color(0.45, g, 0.20)

	var sphere := SphereMesh.new()
	sphere.radius = radius
	# Slightly squashed for that plump caterpillar look
	sphere.height = radius * 1.75
	sphere.radial_segments = 32
	sphere.rings = 16
	_mesh.mesh = sphere
	_mesh.material_override = _mat
	_mesh.position.y = radius * 0.85
	_base_mesh_y = radius * 0.85
	_mesh.cast_shadow = GeometryInstance3D.SHADOW_CASTING_SETTING_ON
	add_child(_mesh)

	# Darker underbelly stripe
	_add_belly_stripe(radius, seg_type)

	match seg_type:
		"head":
			# Face pivot – tilted upward so features face the overhead camera
			var face_pivot := Node3D.new()
			face_pivot.rotation.x = deg_to_rad(-45)  # Tilt face up toward camera
			_mesh.add_child(face_pivot)
			_add_eyes(radius, face_pivot)
			_add_cheeks(radius, face_pivot)
			_add_mouth(radius, face_pivot)
			_add_antennae(radius)
			_add_feet(radius, true)
		"tail":
			_add_tail_tip(radius)
			_add_feet(radius, true)
		_:
			_add_spots(radius)
			_add_feet(radius, false)

# ── Body details ──

func _add_belly_stripe(radius: float, seg_type: String) -> void:
	# A flattened ellipsoid underneath to simulate the lighter yellow-green belly
	var belly := MeshInstance3D.new()
	var belly_s := SphereMesh.new()
	belly_s.radius = radius * 0.7
	belly_s.height = radius * 0.5
	belly_s.radial_segments = 16
	belly_s.rings = 8
	belly.mesh = belly_s
	var belly_mat := StandardMaterial3D.new()
	match seg_type:
		"head":
			belly_mat.albedo_color = Color(0.75, 0.90, 0.40)
		"tail":
			belly_mat.albedo_color = Color(0.72, 0.88, 0.35)
		_:
			belly_mat.albedo_color = Color(0.58, 0.82, 0.30)
	belly_mat.specular = 0.2
	belly_mat.roughness = 0.7
	belly.material_override = belly_mat
	belly.position = Vector3(0.0, -radius * 0.35, 0.0)
	belly.cast_shadow = GeometryInstance3D.SHADOW_CASTING_SETTING_OFF
	_mesh.add_child(belly)

func _add_spots(radius: float) -> void:
	# Small lighter spots on the body for texture detail (like in reference)
	var spot_mat := StandardMaterial3D.new()
	spot_mat.albedo_color = Color(0.55, 0.85, 0.35, 0.7)
	spot_mat.transparency = BaseMaterial3D.TRANSPARENCY_ALPHA
	spot_mat.specular = 0.3
	spot_mat.roughness = 0.6

	var rng := RandomNumberGenerator.new()
	rng.seed = get_meta("seg_index", 0) * 137 + 42

	for i in range(3):
		var spot := MeshInstance3D.new()
		var spot_s := SphereMesh.new()
		var spot_r := rng.randf_range(0.04, 0.07)
		spot_s.radius = spot_r
		spot_s.height = spot_r * 0.6
		spot_s.radial_segments = 8
		spot_s.rings = 4
		spot.mesh = spot_s
		spot.material_override = spot_mat

		# Distribute spots on upper surface
		var angle := rng.randf_range(-1.0, 1.0)
		var height := rng.randf_range(0.0, radius * 0.6)
		spot.position = Vector3(
			sin(angle) * radius * 0.85,
			height,
			cos(angle) * radius * 0.85
		)
		spot.cast_shadow = GeometryInstance3D.SHADOW_CASTING_SETTING_OFF
		_mesh.add_child(spot)

# ── Head features ──

func _add_eyes(head_radius: float, parent: Node3D) -> void:
	# Large expressive eyes – brown iris with big pupil and sparkly highlights
	var eye_white_mat := StandardMaterial3D.new()
	eye_white_mat.albedo_color = Color(1.0, 1.0, 1.0)
	eye_white_mat.specular = 0.4
	eye_white_mat.roughness = 0.3

	var iris_mat := StandardMaterial3D.new()
	iris_mat.albedo_color = Color(0.45, 0.25, 0.10)  # Warm brown
	iris_mat.specular = 0.5
	iris_mat.roughness = 0.3

	var pupil_mat := StandardMaterial3D.new()
	pupil_mat.albedo_color = Color(0.02, 0.02, 0.02)

	var highlight_mat := StandardMaterial3D.new()
	highlight_mat.albedo_color = Color(1.0, 1.0, 1.0)
	highlight_mat.emission_enabled = true
	highlight_mat.emission = Color(0.8, 0.8, 0.8)
	highlight_mat.emission_energy_multiplier = 0.3

	for side in [-1.0, 1.0]:
		# White of the eye – large and round
		var eye := MeshInstance3D.new()
		var eye_s := SphereMesh.new()
		eye_s.radius = 0.13
		eye_s.height = 0.26
		eye_s.radial_segments = 24
		eye_s.rings = 12
		eye.mesh = eye_s
		eye.material_override = eye_white_mat
		eye.position = Vector3(side * 0.15, head_radius * 0.25, -head_radius * 0.78)
		eye.cast_shadow = GeometryInstance3D.SHADOW_CASTING_SETTING_OFF
		parent.add_child(eye)

		# Brown iris
		var iris := MeshInstance3D.new()
		var iris_s := SphereMesh.new()
		iris_s.radius = 0.09
		iris_s.height = 0.10
		iris_s.radial_segments = 20
		iris_s.rings = 10
		iris.mesh = iris_s
		iris.material_override = iris_mat
		iris.position = Vector3(side * 0.01, -0.02, -0.07)
		iris.cast_shadow = GeometryInstance3D.SHADOW_CASTING_SETTING_OFF
		eye.add_child(iris)

		# Black pupil
		var pupil := MeshInstance3D.new()
		var pupil_s := SphereMesh.new()
		pupil_s.radius = 0.05
		pupil_s.height = 0.06
		pupil_s.radial_segments = 16
		pupil_s.rings = 8
		pupil.mesh = pupil_s
		pupil.material_override = pupil_mat
		pupil.position = Vector3(0.0, 0.0, -0.04)
		pupil.cast_shadow = GeometryInstance3D.SHADOW_CASTING_SETTING_OFF
		iris.add_child(pupil)

		# Large highlight – gives that cute sparkly look
		var hl := MeshInstance3D.new()
		var hl_s := SphereMesh.new()
		hl_s.radius = 0.035
		hl_s.height = 0.04
		hl_s.radial_segments = 8
		hl_s.rings = 4
		hl.mesh = hl_s
		hl.material_override = highlight_mat
		hl.position = Vector3(-side * 0.03, 0.035, -0.03)
		hl.cast_shadow = GeometryInstance3D.SHADOW_CASTING_SETTING_OFF
		iris.add_child(hl)

		# Small secondary highlight
		var hl2 := MeshInstance3D.new()
		var hl2_s := SphereMesh.new()
		hl2_s.radius = 0.015
		hl2_s.height = 0.02
		hl2.mesh = hl2_s
		hl2.material_override = highlight_mat
		hl2.position = Vector3(side * 0.02, -0.02, -0.03)
		hl2.cast_shadow = GeometryInstance3D.SHADOW_CASTING_SETTING_OFF
		iris.add_child(hl2)

func _add_cheeks(head_radius: float, parent: Node3D) -> void:
	# Rosy cheeks for that kawaii look
	var cheek_mat := StandardMaterial3D.new()
	cheek_mat.albedo_color = Color(0.95, 0.55, 0.45, 0.6)
	cheek_mat.transparency = BaseMaterial3D.TRANSPARENCY_ALPHA
	cheek_mat.specular = 0.1
	cheek_mat.roughness = 0.9

	for side in [-1.0, 1.0]:
		var cheek := MeshInstance3D.new()
		var cheek_s := SphereMesh.new()
		cheek_s.radius = 0.06
		cheek_s.height = 0.04
		cheek_s.radial_segments = 12
		cheek_s.rings = 6
		cheek.mesh = cheek_s
		cheek.material_override = cheek_mat
		cheek.position = Vector3(side * 0.21, head_radius * 0.0, -head_radius * 0.72)
		cheek.cast_shadow = GeometryInstance3D.SHADOW_CASTING_SETTING_OFF
		parent.add_child(cheek)

func _add_mouth(head_radius: float, parent: Node3D) -> void:
	# Open happy smile
	var mouth_mat := StandardMaterial3D.new()
	mouth_mat.albedo_color = Color(0.20, 0.08, 0.05)
	mouth_mat.specular = 0.0
	mouth_mat.roughness = 1.0

	var mouth := MeshInstance3D.new()
	var mouth_s := SphereMesh.new()
	mouth_s.radius = 0.065
	mouth_s.height = 0.05
	mouth_s.radial_segments = 16
	mouth_s.rings = 8
	mouth.mesh = mouth_s
	mouth.material_override = mouth_mat
	mouth.position = Vector3(0.0, head_radius * -0.10, -head_radius * 0.85)
	mouth.scale = Vector3(1.3, 0.6, 0.5)
	mouth.cast_shadow = GeometryInstance3D.SHADOW_CASTING_SETTING_OFF
	parent.add_child(mouth)

	# Tongue / inner mouth (pinkish)
	var tongue_mat := StandardMaterial3D.new()
	tongue_mat.albedo_color = Color(0.90, 0.45, 0.40)
	var tongue := MeshInstance3D.new()
	var tongue_s := SphereMesh.new()
	tongue_s.radius = 0.03
	tongue_s.height = 0.025
	tongue_s.radial_segments = 8
	tongue_s.rings = 4
	tongue.mesh = tongue_s
	tongue.material_override = tongue_mat
	tongue.position = Vector3(0.0, -0.015, -0.01)
	tongue.cast_shadow = GeometryInstance3D.SHADOW_CASTING_SETTING_OFF
	mouth.add_child(tongue)

func _add_antennae(head_radius: float) -> void:
	# Two cute antennae with little balls at the tips
	var stalk_mat := StandardMaterial3D.new()
	stalk_mat.albedo_color = Color(0.45, 0.70, 0.18)
	stalk_mat.specular = 0.2
	stalk_mat.roughness = 0.7

	var tip_mat := StandardMaterial3D.new()
	tip_mat.albedo_color = Color(0.55, 0.82, 0.25)
	tip_mat.specular = 0.3
	tip_mat.roughness = 0.5

	for side in [-1.0, 1.0]:
		# Stalk (thin cylinder, slightly angled outward)
		var stalk := MeshInstance3D.new()
		var cyl := CylinderMesh.new()
		cyl.top_radius = 0.015
		cyl.bottom_radius = 0.022
		cyl.height = 0.18
		cyl.radial_segments = 8
		stalk.mesh = cyl
		stalk.material_override = stalk_mat
		stalk.position = Vector3(side * 0.08, head_radius * 0.8, -head_radius * 0.25)
		stalk.rotation.z = side * -0.35  # Angle outward
		stalk.rotation.x = -0.2  # Slight forward tilt
		stalk.cast_shadow = GeometryInstance3D.SHADOW_CASTING_SETTING_OFF
		_mesh.add_child(stalk)

		# Ball tip
		var tip := MeshInstance3D.new()
		var tip_s := SphereMesh.new()
		tip_s.radius = 0.04
		tip_s.height = 0.08
		tip_s.radial_segments = 12
		tip_s.rings = 6
		tip.mesh = tip_s
		tip.material_override = tip_mat
		tip.position = Vector3(0.0, 0.11, 0.0)
		tip.cast_shadow = GeometryInstance3D.SHADOW_CASTING_SETTING_OFF
		stalk.add_child(tip)

# ── Tail ──

func _add_tail_tip(radius: float) -> void:
	# A small pointed nub at the back of the tail
	var tip_mat := StandardMaterial3D.new()
	tip_mat.albedo_color = Color(0.55, 0.78, 0.22)
	tip_mat.specular = 0.2
	tip_mat.roughness = 0.7

	var tip := MeshInstance3D.new()
	var cone := CylinderMesh.new()
	cone.top_radius = 0.0
	cone.bottom_radius = radius * 0.4
	cone.height = radius * 0.6
	cone.radial_segments = 12
	tip.mesh = cone
	tip.material_override = tip_mat
	tip.position = Vector3(0.0, radius * 0.3, radius * 0.6)
	tip.rotation.x = deg_to_rad(70)
	tip.cast_shadow = GeometryInstance3D.SHADOW_CASTING_SETTING_OFF
	_mesh.add_child(tip)

# ── Feet ──

func _add_feet(seg_radius: float, is_small: bool) -> void:
	# Cute rounded yellow-green feet
	var foot_mat := StandardMaterial3D.new()
	foot_mat.albedo_color = Color(0.70, 0.82, 0.30)
	foot_mat.specular = 0.2
	foot_mat.roughness = 0.7

	var foot_r := 0.05 if is_small else 0.06
	var spread := seg_radius * 0.75

	for side_data in [[-1.0, "_foot_left"], [1.0, "_foot_right"]]:
		var side: float = side_data[0]
		var foot := MeshInstance3D.new()
		var foot_s := SphereMesh.new()
		foot_s.radius = foot_r
		foot_s.height = foot_r * 1.2
		foot_s.radial_segments = 12
		foot_s.rings = 6
		foot.mesh = foot_s
		foot.material_override = foot_mat
		foot.position = Vector3(side * spread, -seg_radius * 0.75, -0.02)
		foot.cast_shadow = GeometryInstance3D.SHADOW_CASTING_SETTING_OFF
		_mesh.add_child(foot)

		if side < 0:
			_foot_left = foot
		else:
			_foot_right = foot

	_leg_phase = float(get_meta("seg_index", 0)) * 0.5 * PI

# ── Animation callbacks (API kept for level_3d.gd) ──

func wiggle_legs() -> void:
	if not _foot_left or not _foot_right:
		return
	_leg_phase += 1.0
	var dir := 1.0 if fmod(_leg_phase, 2.0) < 1.0 else -1.0
	_foot_left.position.z = -0.02 + dir * 0.03
	_foot_right.position.z = -0.02 - dir * 0.03
	if _mesh:
		_mesh.position.y = _base_mesh_y + 0.015 * dir

func update_direction(_is_horizontal: bool) -> void:
	pass

func update_seg_type(new_type: String) -> void:
	set_meta("seg_type", new_type)
	if not _mesh or not _mat:
		return
	var sphere := _mesh.mesh as SphereMesh
	if not sphere:
		return
	match new_type:
		"head":
			sphere.radius = 0.32
			sphere.height = 0.56
			_mat.albedo_color = Color(0.62, 0.85, 0.28)
			_base_mesh_y = 0.32 * 0.85
			_mesh.position.y = _base_mesh_y
		"tail":
			sphere.radius = 0.22
			sphere.height = 0.385
			_mat.albedo_color = Color(0.60, 0.80, 0.22)
			_base_mesh_y = 0.22 * 0.85
			_mesh.position.y = _base_mesh_y
		_:
			sphere.radius = 0.28
			sphere.height = 0.49
			_mat.albedo_color = Color(0.45, 0.78, 0.20)
			_base_mesh_y = 0.28 * 0.85
			_mesh.position.y = _base_mesh_y

func flash_red() -> void:
	if _mat:
		_mat.albedo_color = Color(1, 0.5, 0.5)

func set_head_direction(_vertical: bool) -> void:
	pass
