extends Node3D
## Exit portal in 3D.
## Uses imported GLB finish portal and scales it up for a clear level goal.

const FINISH_PORTAL_PATH := "res://assets/Meshy_AI_Finish_Portal_in_a_Ma_0704224339_texture.glb"
const TARGET_HEIGHT := 2.1
const BIG_PORTAL_MULT := 1.0

var _time := 0.0
var _portal_root: Node3D = null
var _portal_geo: Array[GeometryInstance3D] = []
var _base_materials: Array[Material] = []
var _portal_base_pos := Vector3.ZERO

func _ready() -> void:
	if not _spawn_finish_portal_model():
		_spawn_fallback_portal()
	set_process(true)

func _process(delta: float) -> void:
	_time += delta
	var is_open: bool = bool(get_meta("open", false))

	if _portal_root:
		var bob := sin(_time * 1.8) * 0.04
		_portal_root.position = _portal_base_pos + Vector3(0.0, bob, 0.0)

	_apply_open_visuals(is_open)

func _spawn_finish_portal_model() -> bool:
	var packed := load(FINISH_PORTAL_PATH) as PackedScene
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

	var s := (TARGET_HEIGHT / maxf(size.y, 0.0001)) * BIG_PORTAL_MULT
	inst.scale = Vector3(s, s, s)
	var center := aabb.position + size * 0.5
	inst.position = Vector3(-center.x * s, -aabb.position.y * s, -center.z * s)

	add_child(inst)
	_portal_root = inst
	_portal_base_pos = inst.position
	_collect_portal_geometry(inst)
	return true

func _collect_portal_geometry(node: Node) -> void:
	if node is GeometryInstance3D:
		var gi := node as GeometryInstance3D
		_portal_geo.append(gi)
		_base_materials.append(gi.material_override)
	for child in node.get_children():
		_collect_portal_geometry(child)

func _apply_open_visuals(is_open: bool) -> void:
	if _portal_geo.is_empty():
		return

	for i in range(_portal_geo.size()):
		var gi := _portal_geo[i]
		if gi == null or not is_instance_valid(gi):
			continue
		var base := _base_materials[i]
		var mat := base.duplicate() as StandardMaterial3D if base is StandardMaterial3D else StandardMaterial3D.new()
		mat.albedo_color = Color(1.0, 0.96, 0.88) if is_open else Color(0.68, 0.68, 0.7)
		mat.emission_enabled = is_open
		mat.emission = Color(1.0, 0.75, 0.32)
		mat.emission_energy_multiplier = 1.7 if is_open else 0.0
		gi.material_override = mat

func _find_first_mesh_instance(node: Node) -> MeshInstance3D:
	if node is MeshInstance3D:
		return node as MeshInstance3D
	for child in node.get_children():
		var found := _find_first_mesh_instance(child)
		if found:
			return found
	return null

func _spawn_fallback_portal() -> void:
	var ring := MeshInstance3D.new()
	var torus := TorusMesh.new()
	torus.inner_radius = 0.18
	torus.outer_radius = 0.48
	ring.mesh = torus
	var mat := StandardMaterial3D.new()
	mat.albedo_color = Color(0.55, 0.42, 0.2)
	ring.material_override = mat
	ring.position.y = 0.08
	add_child(ring)
	_portal_root = ring
	_portal_base_pos = ring.position
	_collect_portal_geometry(ring)
