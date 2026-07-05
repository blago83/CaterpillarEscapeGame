extends Node3D
## Spike hazard for maze cells.

const VARIANT_DIR := "res://assets/spikes"
const TARGET_WIDTH := 0.56
const TARGET_HEIGHT := 0.44
const SPIKE_SIZE_MULT := 1.96

var _pulse_time := 0.0
var _spike_meshes: Array[MeshInstance3D] = []
var _variant_paths: Array[String] = []

func _ready() -> void:
	if _spawn_split_variant():
		return

	_spawn_fallback_spikes()

func _spawn_split_variant() -> bool:
	var paths := _get_variant_paths()
	if paths.is_empty():
		return false

	var variant := int(get_meta("spike_variant", -1))
	if variant < 0:
		variant = randi()
	variant = posmod(variant, paths.size())

	var path := paths[variant]
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
	var s := minf(sx, minf(sy, sz)) * SPIKE_SIZE_MULT
	inst.scale = Vector3(s, s, s)

	var center := aabb.position + size * 0.5
	inst.position = Vector3(-center.x * s, -aabb.position.y * s, -center.z * s)
	_set_shadow_mode_recursive(inst, GeometryInstance3D.SHADOW_CASTING_SETTING_OFF)
	add_child(inst)
	set_process(false)
	return true

func _get_variant_paths() -> Array[String]:
	if not _variant_paths.is_empty():
		return _variant_paths

	var dir := DirAccess.open(VARIANT_DIR)
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
		if file_name.to_lower().find("spike") == -1:
			continue
		_variant_paths.append("%s/%s" % [VARIANT_DIR, file_name])
	dir.list_dir_end()
	_variant_paths.sort()
	return _variant_paths

func _spawn_fallback_spikes() -> void:
	var mat := StandardMaterial3D.new()
	mat.albedo_color = Color(0.78, 0.78, 0.82)
	mat.roughness = 0.45
	mat.metallic = 0.15
	mat.emission_enabled = true
	mat.emission = Color(1.0, 0.25, 0.12)
	mat.emission_energy_multiplier = 1.1

	var rng := RandomNumberGenerator.new()
	rng.randomize()

	for i in range(4):
		var spike := MeshInstance3D.new()
		var mesh := CylinderMesh.new()
		mesh.top_radius = 0.01 * SPIKE_SIZE_MULT
		mesh.bottom_radius = 0.06 * SPIKE_SIZE_MULT
		mesh.height = (0.34 + float(i) * 0.02) * SPIKE_SIZE_MULT
		spike.mesh = mesh
		spike.material_override = mat
		var ang := float(i) * TAU * 0.25 + rng.randf_range(-0.18, 0.18)
		var r := rng.randf_range(0.02, 0.12) * SPIKE_SIZE_MULT
		spike.position = Vector3(cos(ang) * r, mesh.height * 0.5, sin(ang) * r)
		spike.cast_shadow = GeometryInstance3D.SHADOW_CASTING_SETTING_OFF
		add_child(spike)
		_spike_meshes.append(spike)
	set_process(true)

func _find_first_mesh_instance(node: Node) -> MeshInstance3D:
	if node is MeshInstance3D:
		return node as MeshInstance3D
	for child in node.get_children():
		var found := _find_first_mesh_instance(child)
		if found:
			return found
	return null

func _set_shadow_mode_recursive(node: Node, mode: int) -> void:
	if node is GeometryInstance3D:
		(node as GeometryInstance3D).cast_shadow = mode as GeometryInstance3D.ShadowCastingSetting
	for child in node.get_children():
		_set_shadow_mode_recursive(child, mode)

func _process(delta: float) -> void:
	_pulse_time += delta
	var pulse := 1.0 + 0.45 * (0.5 + 0.5 * sin(_pulse_time * 4.0))
	for spike in _spike_meshes:
		var mat := spike.material_override as StandardMaterial3D
		if mat:
			mat.emission_energy_multiplier = pulse
