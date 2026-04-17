extends Node3D
## Exit portal in 3D – torus ring, glows when open.

var _time := 0.0
var _ring: MeshInstance3D
var _glow: MeshInstance3D
var _ring_mat: StandardMaterial3D
var _glow_mat: StandardMaterial3D

func _ready() -> void:
	# Portal ring (torus laid flat)
	_ring = MeshInstance3D.new()
	var torus := TorusMesh.new()
	torus.inner_radius = 0.15
	torus.outer_radius = 0.4
	_ring.mesh = torus
	_ring_mat = StandardMaterial3D.new()
	_ring_mat.albedo_color = Color(0.5, 0.35, 0.6)
	_ring.material_override = _ring_mat
	_ring.position.y = 0.05
	_ring.cast_shadow = GeometryInstance3D.SHADOW_CASTING_SETTING_OFF
	add_child(_ring)

	# Inner glow disc
	_glow = MeshInstance3D.new()
	var cyl := CylinderMesh.new()
	cyl.top_radius = 0.2
	cyl.bottom_radius = 0.2
	cyl.height = 0.02
	_glow.mesh = cyl
	_glow_mat = StandardMaterial3D.new()
	_glow_mat.albedo_color = Color(0.7, 0.5, 0.9, 0.5)
	_glow_mat.transparency = BaseMaterial3D.TRANSPARENCY_ALPHA
	_glow_mat.emission_enabled = true
	_glow_mat.emission = Color(0.6, 0.4, 0.8)
	_glow_mat.emission_energy_multiplier = 0.3
	_glow.material_override = _glow_mat
	_glow.position.y = 0.06
	_glow.visible = false
	add_child(_glow)

func _process(delta: float) -> void:
	_time += delta
	var is_open: bool = get_meta("open", false)
	if is_open:
		_ring_mat.albedo_color = Color(0.85, 0.7, 1.0)
		_ring_mat.emission_enabled = true
		_ring_mat.emission = Color(0.6, 0.4, 0.8)
		_ring_mat.emission_energy_multiplier = 0.5
		_glow.visible = true
		var pulse := (sin(_time * 4.0) + 1.0) * 0.5
		_glow_mat.albedo_color = Color(1, 1, 1, pulse * 0.4)
		_ring.rotation.y = _time * 1.5
	else:
		_ring_mat.albedo_color = Color(0.5, 0.35, 0.6)
		_ring_mat.emission_enabled = false
		_glow.visible = false
