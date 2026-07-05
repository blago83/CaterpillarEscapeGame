extends Node3D
## Spider hazard in 3D.
## Prefers split Meshy GLB variants; falls back to procedural spider if unavailable.

const SPIDER_VARIANT_DIR := "res://assets/spiders/animated"
const TARGET_WIDTH := 2.16
const TARGET_HEIGHT := 1.38
const SPIDER_SIZE_MULT := 0.7
const TURN_SPEED := 2.0
const TURN_BLEND := 0.18
const BUSH_TOP_OFFSET_Y := 0.62
const LEG_BASE_FREQ := 4.6
const TRACK_DISTANCE := 4.0

var _player_head: Node3D = null
var _anim_time := 0.0
var _turn_motion := 0.0

var _skeleton: Skeleton3D = null
var _skeleton_bones: Array[int] = []
var _skeleton_base_rots: Array[Quaternion] = []
var _skeleton_left_side: Array[bool] = []

var _procedural_legs: Array[MeshInstance3D] = []
var _procedural_leg_base_rot: Array[Vector3] = []
var _variant_paths: Array[String] = []

func _ready() -> void:
	position.y += BUSH_TOP_OFFSET_Y
	if not _spawn_glb_variant():
		_spawn_procedural_fallback()
	set_process(true)

func _process(delta: float) -> void:
	if _player_head == null or not is_instance_valid(_player_head):
		_player_head = _find_player_head()
		if _player_head == null:
			_animate_legs(delta)
			return

	var to_player := _player_head.global_position - global_position
	to_player.y = 0.0
	if to_player.length_squared() < 0.0001:
		_animate_legs(delta)
		return
	var auto_track := to_player.length() <= TRACK_DISTANCE
	var should_track := bool(get_meta("track_player", auto_track))
	if not should_track:
		_turn_motion = lerpf(_turn_motion, 0.0, minf(delta * 5.0, 1.0))
		_animate_legs(delta)
		return

	var target_yaw := atan2(to_player.x, to_player.z)
	var yaw_gap := absf(angle_difference(rotation.y, target_yaw))
	var target_turn_motion := clampf(yaw_gap * 1.2, 0.0, 0.55)
	_turn_motion = lerpf(_turn_motion, target_turn_motion, minf(delta * 4.0, 1.0))
	var t := clampf(delta * TURN_SPEED, 0.0, TURN_BLEND)
	rotation.y = lerp_angle(rotation.y, target_yaw, t)

	_animate_legs(delta)

func _animate_legs(delta: float) -> void:
	_anim_time += delta * (LEG_BASE_FREQ + _turn_motion * 1.4)
	var swing_amp := 0.10 + _turn_motion * 0.14
	var lift_amp := 0.03 + _turn_motion * 0.05

	if _skeleton and not _skeleton_bones.is_empty():
		for i in range(_skeleton_bones.size()):
			var bone_idx := _skeleton_bones[i]
			var phase := _anim_time + float(i) * 0.62
			var side_sign := -1.0 if _skeleton_left_side[i] else 1.0
			var swing := sin(phase) * swing_amp * side_sign
			var lift := cos(phase * 2.0) * lift_amp
			var base_rot := _skeleton_base_rots[i]
			var offset_rot := Quaternion(Vector3.RIGHT, lift * 0.35) * Quaternion(Vector3.FORWARD, swing)
			_skeleton.set_bone_pose_rotation(bone_idx, base_rot * offset_rot)

	if not _procedural_legs.is_empty():
		for i in range(_procedural_legs.size()):
			var leg := _procedural_legs[i]
			if leg == null or not is_instance_valid(leg):
				continue
			var base := _procedural_leg_base_rot[i]
			var phase := _anim_time + float(i) * 0.7
			var side_sign := 1.0 if i % 2 == 0 else -1.0
			leg.rotation = Vector3(
				base.x + cos(phase * 2.0) * lift_amp * 0.2,
				base.y,
				base.z + sin(phase) * swing_amp * 0.45 * side_sign
			)

func _find_player_head() -> Node3D:
	for node in get_tree().get_nodes_in_group("player_head_3d"):
		if node is Node3D:
			return node as Node3D
	for node in get_tree().get_nodes_in_group("caterpillar_segment_3d"):
		if node is Node3D and node.has_meta("seg_index"):
			if int(node.get_meta("seg_index")) == 0:
				return node as Node3D
	return null

func _spawn_glb_variant() -> bool:
	var paths := _get_variant_paths()
	if paths.is_empty():
		return false
	var variant := int(get_meta("spider_variant", -1))
	if variant < 0:
		variant = randi()
	var start_idx := posmod(variant, paths.size())

	var packed: PackedScene = null
	for i in range(paths.size()):
		var path := paths[(start_idx + i) % paths.size()]
		packed = load(path) as PackedScene
		if packed:
			break
	if packed == null:
		return false

	var inst := packed.instantiate() as Node3D
	if inst == null:
		return false

	var mesh_inst := _find_first_mesh_instance(inst)
	if mesh_inst == null or mesh_inst.mesh == null:
		inst.queue_free()
		return false

	var aabb := mesh_inst.mesh.get_aabb()
	var size := aabb.size
	if size.x <= 0.0001 or size.y <= 0.0001 or size.z <= 0.0001:
		inst.queue_free()
		return false

	var sx := TARGET_WIDTH / maxf(size.x, 0.0001)
	var sy := TARGET_HEIGHT / maxf(size.y, 0.0001)
	var sz := TARGET_WIDTH / maxf(size.z, 0.0001)
	var s := minf(sx, minf(sy, sz)) * SPIDER_SIZE_MULT
	inst.scale = Vector3(s, s, s)

	# Center on XZ and place bottom on y = 0 in parent space.
	var center := aabb.position + size * 0.5
	inst.position = Vector3(-center.x * s, -aabb.position.y * s, -center.z * s)
	_set_shadow_mode_recursive(inst, GeometryInstance3D.SHADOW_CASTING_SETTING_OFF)
	add_child(inst)
	_setup_bone_animation(inst)
	return true

func _get_variant_paths() -> Array[String]:
	if not _variant_paths.is_empty():
		return _variant_paths

	var dir := DirAccess.open(SPIDER_VARIANT_DIR)
	if dir == null:
		return _variant_paths

	dir.list_dir_begin()
	while true:
		var file_name := dir.get_next()
		if file_name == "":
			break
		if dir.current_is_dir():
			continue
		if not file_name.to_lower().ends_with(".glb"):
			continue
		_variant_paths.append("%s/%s" % [SPIDER_VARIANT_DIR, file_name])
	dir.list_dir_end()
	_variant_paths.sort()
	return _variant_paths

func _setup_bone_animation(root: Node) -> void:
	_skeleton = _find_first_skeleton(root)
	_skeleton_bones.clear()
	_skeleton_base_rots.clear()
	_skeleton_left_side.clear()
	if _skeleton == null:
		return

	for i in range(_skeleton.get_bone_count()):
		var bone_name := _skeleton.get_bone_name(i).to_lower()
		var is_leg := (
			bone_name.find("leg") != -1
			or bone_name.find("foot") != -1
			or bone_name.find("claw") != -1
			or bone_name.find("arm") != -1
			or bone_name.find("limb") != -1
		)
		if not is_leg:
			continue
		_skeleton_bones.append(i)
		_skeleton_base_rots.append(_skeleton.get_bone_pose_rotation(i))
		_skeleton_left_side.append(_is_left_side_name(bone_name))

	# Fallback: if bones are unnamed, animate non-core bones.
	if _skeleton_bones.is_empty():
		for i in range(_skeleton.get_bone_count()):
			var bone_name := _skeleton.get_bone_name(i).to_lower()
			var is_core := (
				bone_name.find("root") != -1
				or bone_name.find("body") != -1
				or bone_name.find("head") != -1
				or bone_name.find("spine") != -1
				or bone_name.find("pelvis") != -1
			)
			if is_core:
				continue
			_skeleton_bones.append(i)
			_skeleton_base_rots.append(_skeleton.get_bone_pose_rotation(i))
			_skeleton_left_side.append(_is_left_side_name(bone_name))

func _is_left_side_name(name_lower: String) -> bool:
	return (
		name_lower.find("left") != -1
		or name_lower.find("_l") != -1
		or name_lower.find(".l") != -1
		or name_lower.begins_with("l_")
	)

func _find_first_skeleton(node: Node) -> Skeleton3D:
	if node is Skeleton3D:
		return node as Skeleton3D
	for child in node.get_children():
		var found := _find_first_skeleton(child)
		if found:
			return found
	return null

func _set_shadow_mode_recursive(node: Node, mode: int) -> void:
	if node is GeometryInstance3D:
		(node as GeometryInstance3D).cast_shadow = mode as GeometryInstance3D.ShadowCastingSetting
	for child in node.get_children():
		_set_shadow_mode_recursive(child, mode)

func _find_first_mesh_instance(node: Node) -> MeshInstance3D:
	if node is MeshInstance3D:
		return node as MeshInstance3D
	for child in node.get_children():
		var found := _find_first_mesh_instance(child)
		if found:
			return found
	return null

func _spawn_procedural_fallback() -> void:
	# Body
	var body := MeshInstance3D.new()
	var body_sphere := SphereMesh.new()
	body_sphere.radius = 0.28
	body_sphere.height = 0.45
	body.mesh = body_sphere
	var body_mat := StandardMaterial3D.new()
	body_mat.albedo_color = Color(0.15, 0.12, 0.12)
	body.material_override = body_mat
	body.position.y = 0.22
	body.cast_shadow = GeometryInstance3D.SHADOW_CASTING_SETTING_OFF
	add_child(body)

	# Head
	var head := MeshInstance3D.new()
	var head_sphere := SphereMesh.new()
	head_sphere.radius = 0.15
	head_sphere.height = 0.28
	head.mesh = head_sphere
	var head_mat := StandardMaterial3D.new()
	head_mat.albedo_color = Color(0.2, 0.15, 0.15)
	head.material_override = head_mat
	head.position = Vector3(0, 0.32, -0.22)
	head.cast_shadow = GeometryInstance3D.SHADOW_CASTING_SETTING_OFF
	add_child(head)

	# Red eyes
	var eye_mat := StandardMaterial3D.new()
	eye_mat.albedo_color = Color(0.9, 0.1, 0.1)
	eye_mat.emission_enabled = true
	eye_mat.emission = Color(0.9, 0.1, 0.1)
	eye_mat.emission_energy_multiplier = 1.0
	for side in [-1.0, 1.0]:
		var eye := MeshInstance3D.new()
		var eye_sphere := SphereMesh.new()
		eye_sphere.radius = 0.05
		eye_sphere.height = 0.1
		eye.mesh = eye_sphere
		eye.material_override = eye_mat
		eye.position = Vector3(side * 0.07, 0.38, -0.32)
		add_child(eye)

	# Legs
	var leg_mat := StandardMaterial3D.new()
	leg_mat.albedo_color = Color(0.12, 0.1, 0.1)
	for side in [-1.0, 1.0]:
		for i in range(4):
			var leg := MeshInstance3D.new()
			var cyl := CylinderMesh.new()
			cyl.top_radius = 0.018
			cyl.bottom_radius = 0.018
			cyl.height = 0.32
			leg.mesh = cyl
			leg.material_override = leg_mat
			var angle := (float(i) - 1.5) * 0.35
			leg.position = Vector3(side * 0.32, 0.12, -0.05 + float(i) * 0.08)
			leg.rotation.z = side * 0.6
			leg.rotation.y = angle
			leg.cast_shadow = GeometryInstance3D.SHADOW_CASTING_SETTING_OFF
			add_child(leg)
			_procedural_legs.append(leg)
			_procedural_leg_base_rot.append(leg.rotation)
