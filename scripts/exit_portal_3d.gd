extends Node3D
## Exit portal in 3D.
## Uses imported GLB finish portal and scales it up for a clear level goal.

const FINISH_PORTAL_PATH := "res://assets/Meshy_AI_Finish_Portal_in_a_Ma_0704224339_texture.glb"
const TARGET_HEIGHT := 2.1
const BIG_PORTAL_MULT := 0.9
# The gate stands in the top wall facing down into the maze.
const PORTAL_YAW_DEG := 0.0

var _time := 0.0
var _portal_root: Node3D = null
var _portal_geo: Array[GeometryInstance3D] = []
var _base_materials: Array[Material] = []
var _portal_base_pos := Vector3.ZERO
var _shown_open := -1          # -1 until the first visual update
var _bars: Node3D = null
var _bars_lift := 0.0          # 0 = bars down (closed), 1 = fully raised

const BAR_COUNT := 4
const BAR_HEIGHT := 1.5
const BAR_LIFT := 1.9
const CLOSED_TINT := Color(0.45, 0.45, 0.5)

func _ready() -> void:
	if not _spawn_finish_portal_model():
		_spawn_fallback_portal()
	_build_bars()
	set_process(true)

func _process(delta: float) -> void:
	_time += delta
	var is_open: bool = bool(get_meta("open", false))

	if _portal_root:
		var bob := sin(_time * 1.8) * 0.04 if is_open else 0.0
		_portal_root.position = _portal_base_pos + Vector3(0.0, bob, 0.0)

	if int(is_open) != _shown_open:
		_shown_open = int(is_open)
		_apply_open_visuals(is_open)
	_animate_bars(delta, is_open)

# Wooden bars across the doorway while the gate is locked; they lift away
# once it opens.
func _build_bars() -> void:
	_bars = Node3D.new()
	add_child(_bars)
	var mat := StandardMaterial3D.new()
	mat.albedo_color = Color(0.5, 0.3, 0.14)
	mat.roughness = 0.9
	var bar_mesh := BoxMesh.new()
	bar_mesh.size = Vector3(0.11, BAR_HEIGHT, 0.11)
	var span := 0.62
	for i in BAR_COUNT:
		var bar := MeshInstance3D.new()
		bar.mesh = bar_mesh
		bar.material_override = mat
		bar.position = Vector3(lerpf(-span * 0.5, span * 0.5, float(i) / float(BAR_COUNT - 1)), BAR_HEIGHT * 0.5, 0.15)
		_bars.add_child(bar)
	var rail_mesh := BoxMesh.new()
	rail_mesh.size = Vector3(span + 0.2, 0.1, 0.13)
	for y in [0.45, 1.1]:
		var rail := MeshInstance3D.new()
		rail.mesh = rail_mesh
		rail.material_override = mat
		rail.position = Vector3(0.0, y, 0.15)
		_bars.add_child(rail)

func _animate_bars(delta: float, is_open: bool) -> void:
	if _bars == null:
		return
	_bars_lift = move_toward(_bars_lift, 1.0 if is_open else 0.0, delta * 1.5)
	var t := _bars_lift * _bars_lift
	_bars.position.y = t * BAR_LIFT
	_bars.scale = Vector3.ONE * (1.0 - t * 0.6)
	_bars.visible = _bars_lift < 0.999

func is_shut() -> bool:
	return _bars != null and _bars.visible and _bars_lift < 0.5

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
	inst.rotation_degrees.y = PORTAL_YAW_DEG
	var center := aabb.position + size * 0.5
	# Rotate the centring offset too, so the model stays on its cell.
	var offset := inst.basis * Vector3(-center.x, -aabb.position.y, -center.z)
	inst.position = offset

	add_child(inst)
	_portal_root = inst
	_portal_base_pos = inst.position
	_collect_portal_geometry(inst)
	return true

func _collect_portal_geometry(node: Node) -> void:
	if node is MeshInstance3D:
		var mi := node as MeshInstance3D
		_portal_geo.append(mi)
		# GLB models store materials on mesh surfaces, not as material_override.
		var mat: Material = mi.material_override
		if mat == null and mi.mesh != null and mi.mesh.get_surface_count() > 0:
			mat = mi.mesh.surface_get_material(0)
		_base_materials.append(mat)
	for child in node.get_children():
		_collect_portal_geometry(child)

func _apply_open_visuals(is_open: bool) -> void:
	if _portal_geo.is_empty():
		return
	for i in range(_portal_geo.size()):
		var gi := _portal_geo[i] as MeshInstance3D
		if gi == null or not is_instance_valid(gi):
			continue
		if is_open:
			# Duplicate the original material and layer emission on top.
			var base := _base_materials[i]
			var mat: StandardMaterial3D
			if base is StandardMaterial3D:
				mat = (base as StandardMaterial3D).duplicate() as StandardMaterial3D
			else:
				mat = StandardMaterial3D.new()
			mat.emission_enabled = true
			mat.emission = Color(1.0, 0.75, 0.32)
			mat.emission_energy_multiplier = 1.7
			gi.material_override = mat
		else:
			# Locked: dim and grey out the gate so it reads as switched off.
			var base := _base_materials[i]
			var mat: StandardMaterial3D
			if base is StandardMaterial3D:
				mat = (base as StandardMaterial3D).duplicate() as StandardMaterial3D
			else:
				mat = StandardMaterial3D.new()
			mat.albedo_color = mat.albedo_color * CLOSED_TINT
			mat.emission_enabled = false
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
