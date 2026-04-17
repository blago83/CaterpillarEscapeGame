extends Node3D
## A collectible leaf – spinning and bobbing in 3D.

var _time := 0.0
var _mesh: MeshInstance3D

func _ready() -> void:
	_mesh = MeshInstance3D.new()
	var sphere := SphereMesh.new()
	sphere.radius = 0.2
	sphere.height = 0.35
	_mesh.mesh = sphere
	var mat := StandardMaterial3D.new()
	mat.shading_mode = BaseMaterial3D.SHADING_MODE_UNSHADED
	mat.albedo_color = Color(0.2, 0.72, 0.15)
	mat.emission_enabled = true
	mat.emission = Color(0.1, 0.3, 0.05)
	mat.emission_energy_multiplier = 0.5
	_mesh.material_override = mat
	_mesh.position.y = 0.3
	_mesh.cast_shadow = GeometryInstance3D.SHADOW_CASTING_SETTING_OFF
	add_child(_mesh)

func _process(delta: float) -> void:
	_time += delta
	_mesh.rotation.y = _time * 2.0
	_mesh.position.y = 0.3 + sin(_time * 3.0) * 0.05
