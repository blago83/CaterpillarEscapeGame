extends Node3D
## Spider hazard in 3D.
## Prefers split Meshy GLB variants; falls back to procedural spider if unavailable.

const VARIANT_DIR := "res://assets/spiders/meshy_split_spiders"
const VARIANT_COUNT := 6
const TARGET_WIDTH := 2.16
const TARGET_HEIGHT := 1.38
const TURN_SPEED := 2.0
const TURN_BLEND := 0.18
const BUSH_TOP_OFFSET_Y := 0.62

var _player_head: Node3D = null

func _ready() -> void:
	position.y += BUSH_TOP_OFFSET_Y
	if not _spawn_glb_variant():
		_spawn_procedural_fallback()
	set_process(true)

func _process(delta: float) -> void:
	if _player_head == null or not is_instance_valid(_player_head):
		_player_head = _find_player_head()
		if _player_head == null:
			return

	var to_player := _player_head.global_position - global_position
	to_player.y = 0.0
	if to_player.length_squared() < 0.0001:
		return

	var target_yaw := atan2(to_player.x, to_player.z)
	var t := clampf(delta * TURN_SPEED, 0.0, TURN_BLEND)
	rotation.y = lerp_angle(rotation.y, target_yaw, t)

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
	var variant := int(get_meta("spider_variant", 0))
	variant = posmod(variant, VARIANT_COUNT)
	var path := "%s/spider_%02d.glb" % [VARIANT_DIR, variant + 1]
	var packed := load(path) as PackedScene
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
	var s := minf(sx, minf(sy, sz))
	inst.scale = Vector3(s, s, s)

	# Center on XZ and place bottom on y = 0 in parent space.
	var center := aabb.position + size * 0.5
	inst.position = Vector3(-center.x * s, -aabb.position.y * s, -center.z * s)
	_set_shadow_mode_recursive(inst, GeometryInstance3D.SHADOW_CASTING_SETTING_OFF)
	add_child(inst)
	return true

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
