extends Node3D
## Body-growth collectible shown as a big red apple.

const VARIANT_DIR := "res://assets/bonuses/meshy_split_fruits"
const VARIANT_COUNT := 5
const TARGET_WIDTH := 0.90
const TARGET_HEIGHT := 0.92
const FRUIT_SIZE_MULT := 0.9
const HOVER_BASE_Y := 0.12
const HOVER_BOB_AMPLITUDE := 0.04

var _time := 0.0
var _visual_root: Node3D = null

func _ready() -> void:
	_rebuild_visual()

func set_fruit_variant(variant: int) -> void:
	set_meta("fruit_variant", variant)
	_rebuild_visual()

func _rebuild_visual() -> void:
	for child in get_children():
		child.queue_free()
	_visual_root = null

	if not _spawn_fruit_variant():
		_spawn_any_fruit_variant()
	set_process(_visual_root != null)

func _spawn_fruit_variant() -> bool:
	var variant := int(get_meta("fruit_variant", 0))
	variant = posmod(variant, VARIANT_COUNT)
	var path := "%s/fruit_%02d.glb" % [VARIANT_DIR, variant + 1]
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
	var s := minf(sx, minf(sy, sz)) * FRUIT_SIZE_MULT
	inst.scale = Vector3(s, s, s)

	# Build a dedicated pivot so rotation happens over the fruit center.
	var pivot := Node3D.new()
	pivot.position = Vector3(0.0, HOVER_BASE_Y, 0.0)
	add_child(pivot)
	_visual_root = pivot

	# Align bottom to pickup height and center XZ within the pivot.
	var center := aabb.position + size * 0.5
	inst.position = Vector3(-center.x * s, -aabb.position.y * s, -center.z * s)
	_set_shadow_mode_recursive(inst, GeometryInstance3D.SHADOW_CASTING_SETTING_OFF)
	pivot.add_child(inst)
	set_process(true)
	return true

func _spawn_any_fruit_variant() -> bool:
	for i in range(VARIANT_COUNT):
		set_meta("fruit_variant", i)
		if _spawn_fruit_variant():
			return true
	return false

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
	_time += delta
	var bob := sin(_time * 3.0) * HOVER_BOB_AMPLITUDE
	if _visual_root:
		_visual_root.rotation.y = _time * 2.0
		_visual_root.position.y = HOVER_BASE_Y + bob
