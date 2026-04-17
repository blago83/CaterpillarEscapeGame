extends Node3D
## A spider hazard in 3D – dark body with red eyes.

func _ready() -> void:
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
