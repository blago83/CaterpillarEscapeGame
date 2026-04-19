extends Node3D

const Segment3DScript := preload("res://scripts/segment_3d.gd")
const MouthComponent3DScript: GDScript = preload("res://scripts/mouth_component_3d.gd")
const BASE_CAM_OFFSET := Vector3(0.1, 7.2, 6.2)
const MIN_ZOOM := 0.65
const MAX_ZOOM := 1.6
const ZOOM_STEP := 0.08
const MOVE_SPEED := 4.0
const TURN_SPEED := 8.0

var _zoom := 1.0
var _move_dir := Vector2.ZERO
var _caterpillar_root: Node3D
var _segments: Array[Node3D] = []
var _segment_local_positions: Array[Vector3] = []
var _yaw_target := 0.0
var _body_shadow: MeshInstance3D = null

@onready var cam: Camera3D = $Camera3D
@onready var world_root: Node3D = $World
@onready var player_root: Node3D = $PlayerRoot
@onready var info_label: Label = $CanvasLayer/HUD/Panel/VBox/InfoLabel
@onready var zoom_label: Label = $CanvasLayer/HUD/Panel/VBox/ZoomLabel
@onready var back_button: Button = $CanvasLayer/HUD/Panel/VBox/Buttons/BackButton
@onready var reset_button: Button = $CanvasLayer/HUD/Panel/VBox/Buttons/ResetButton

func _ready() -> void:
	RenderingServer.set_default_clear_color(Color(0.12, 0.18, 0.08))
	_setup_lighting()
	_setup_ground()
	_spawn_player()
	_spawn_mouth_preview()
	_update_camera(true)
	back_button.pressed.connect(_on_back_pressed)
	reset_button.pressed.connect(_on_reset_pressed)
	_update_hud()

func _process(delta: float) -> void:
	_handle_move_input()
	_update_player(delta)
	_update_camera(false)

func _unhandled_input(event: InputEvent) -> void:
	if event.is_action_pressed("ui_cancel"):
		_on_back_pressed()
		return

	if event is InputEventMouseButton and event.pressed:
		var mouse_event := event as InputEventMouseButton
		if mouse_event.button_index == MOUSE_BUTTON_WHEEL_UP:
			_set_zoom(_zoom - ZOOM_STEP)
		elif mouse_event.button_index == MOUSE_BUTTON_WHEEL_DOWN:
			_set_zoom(_zoom + ZOOM_STEP)

	if event is InputEventKey and event.pressed and not event.echo:
		var key_event := event as InputEventKey
		match key_event.keycode:
			KEY_EQUAL, KEY_KP_ADD:
				_set_zoom(_zoom - ZOOM_STEP)
			KEY_MINUS, KEY_KP_SUBTRACT:
				_set_zoom(_zoom + ZOOM_STEP)

func _setup_lighting() -> void:
	var sun := DirectionalLight3D.new()
	sun.rotation_degrees = Vector3(-58.0, 38.0, 0.0)
	sun.light_energy = 0.85
	sun.light_color = Color(1.0, 0.98, 0.92)
	sun.shadow_enabled = true
	sun.directional_shadow_mode = DirectionalLight3D.SHADOW_PARALLEL_2_SPLITS
	sun.directional_shadow_max_distance = 50.0
	add_child(sun)

	var fill := OmniLight3D.new()
	fill.position = Vector3(-5.0, 4.0, 5.0)
	fill.light_energy = 0.18
	fill.omni_range = 20.0
	fill.light_color = Color(0.82, 0.92, 0.86)
	add_child(fill)

	var world_env := WorldEnvironment.new()
	var env := Environment.new()
	env.background_mode = Environment.BG_COLOR
	env.background_color = Color(0.12, 0.18, 0.08)
	env.ambient_light_source = Environment.AMBIENT_SOURCE_COLOR
	env.ambient_light_color = Color(0.75, 0.75, 0.70)
	env.ambient_light_energy = 0.6
	env.sdfgi_enabled = false
	world_env.environment = env
	add_child(world_env)

func _setup_ground() -> void:
	var ground := MeshInstance3D.new()
	var plane := PlaneMesh.new()
	plane.size = Vector2(28.0, 28.0)
	plane.subdivide_depth = 4
	plane.subdivide_width = 4
	ground.mesh = plane

	var mat := StandardMaterial3D.new()
	mat.albedo_color = Color(0.76, 0.70, 0.50)
	mat.roughness = 1.0
	mat.specular = 0.05
	ground.material_override = mat
	ground.cast_shadow = GeometryInstance3D.SHADOW_CASTING_SETTING_OFF
	world_root.add_child(ground)

	var patch := MeshInstance3D.new()
	var patch_plane := PlaneMesh.new()
	patch_plane.size = Vector2(10.0, 10.0)
	patch.mesh = patch_plane
	var patch_mat := StandardMaterial3D.new()
	patch_mat.albedo_color = Color(0.66, 0.61, 0.43, 0.40)
	patch_mat.transparency = BaseMaterial3D.TRANSPARENCY_ALPHA
	patch_mat.roughness = 1.0
	patch.material_override = patch_mat
	patch.position.y = 0.01
	world_root.add_child(patch)

func _spawn_player() -> void:
	_caterpillar_root = Node3D.new()
	player_root.add_child(_caterpillar_root)
	_ensure_body_shadow()

	_segment_local_positions.clear()
	_segments.clear()

	for index in range(5):
		var segment := Node3D.new()
		segment.script = Segment3DScript
		segment.set_meta("seg_index", index)
		if index == 0:
			segment.set_meta("seg_type", "head")
		elif index == 4:
			segment.set_meta("seg_type", "tail")
		else:
			segment.set_meta("seg_type", "body")
		var local_pos := Vector3(0.0, 0.0, index * 0.42)
		segment.position = local_pos
		_segment_local_positions.append(local_pos)
		_caterpillar_root.add_child(segment)
		_segments.append(segment)

	player_root.position = Vector3.ZERO
	player_root.rotation.y = 0.0
	_yaw_target = 0.0
	_update_body_shadow()
	if not _segments.is_empty() and _segments[0].has_method("set_idle"):
		_segments[0].set_idle(true)

func _spawn_mouth_preview() -> void:
	var preview_root := Node3D.new()
	preview_root.name = "MouthPreview"
	preview_root.position = Vector3(-2.8, 0.70, 0.2)
	preview_root.rotation_degrees = Vector3(55.0, 0.0, 0.0)
	world_root.add_child(preview_root)

	var face_back := MeshInstance3D.new()
	var face_back_mesh := SphereMesh.new()
	face_back_mesh.radius = 0.40
	face_back_mesh.height = 0.26
	face_back_mesh.radial_segments = 28
	face_back_mesh.rings = 14
	face_back.mesh = face_back_mesh
	var face_back_mat := StandardMaterial3D.new()
	face_back_mat.albedo_color = Color(0.62, 0.85, 0.28)
	face_back_mat.specular = 0.45
	face_back_mat.roughness = 0.50
	face_back.material_override = face_back_mat
	face_back.scale = Vector3(1.9, 1.25, 0.55)
	face_back.cast_shadow = GeometryInstance3D.SHADOW_CASTING_SETTING_OFF
	preview_root.add_child(face_back)

	var chin := MeshInstance3D.new()
	var chin_mesh := SphereMesh.new()
	chin_mesh.radius = 0.30
	chin_mesh.height = 0.18
	chin_mesh.radial_segments = 24
	chin_mesh.rings = 12
	chin.mesh = chin_mesh
	var chin_mat := StandardMaterial3D.new()
	chin_mat.albedo_color = Color(0.86, 0.86, 0.54)
	chin_mat.specular = 0.30
	chin_mat.roughness = 0.62
	chin.material_override = chin_mat
	chin.position = Vector3(0.0, -0.23, 0.07)
	chin.scale = Vector3(1.45, 1.05, 0.45)
	chin.cast_shadow = GeometryInstance3D.SHADOW_CASTING_SETTING_OFF
	preview_root.add_child(chin)

	var mouth: Node3D = MouthComponent3DScript.new()
	mouth.scale = Vector3(1.70, 1.70, 1.70)
	mouth.face_color = Color(0.62, 0.85, 0.28)
	mouth.mouth_cavity_color = Color(0.19, 0.07, 0.04)
	mouth.tongue_color = Color(0.96, 0.67, 0.56)
	mouth.drool_enabled = true
	if mouth.has_method("set_expression"):
		mouth.set_expression("idle")
	preview_root.add_child(mouth)

func _ensure_body_shadow() -> void:
	if _body_shadow:
		return
	_body_shadow = MeshInstance3D.new()
	var mesh := SphereMesh.new()
	mesh.radius = 0.55
	mesh.height = 0.08
	mesh.radial_segments = 24
	mesh.rings = 8
	_body_shadow.mesh = mesh
	var shadow_mat := StandardMaterial3D.new()
	shadow_mat.albedo_color = Color(0.0, 0.0, 0.0, 0.14)
	shadow_mat.transparency = BaseMaterial3D.TRANSPARENCY_ALPHA
	shadow_mat.shading_mode = BaseMaterial3D.SHADING_MODE_UNSHADED
	shadow_mat.specular_mode = BaseMaterial3D.SPECULAR_DISABLED
	shadow_mat.cull_mode = BaseMaterial3D.CULL_DISABLED
	shadow_mat.render_priority = -1
	_body_shadow.material_override = shadow_mat
	_body_shadow.cast_shadow = GeometryInstance3D.SHADOW_CASTING_SETTING_OFF
	player_root.add_child(_body_shadow)

func _update_body_shadow() -> void:
	if not _body_shadow:
		return
	if _segments.is_empty():
		_body_shadow.visible = false
		return
	_body_shadow.visible = true
	var center := Vector3.ZERO
	for segment in _segments:
		center += segment.position
	center /= float(_segments.size())
	var head_pos := _segments[0].position
	var tail_pos := _segments[-1].position
	var spine := head_pos - tail_pos
	var length := maxf(spine.length() + 1.0, 2.4)
	var yaw := atan2(spine.x, spine.z)
	_body_shadow.position = Vector3(center.x, 0.03, center.z)
	_body_shadow.rotation = Vector3(0.0, yaw, 0.0)
	_body_shadow.scale = Vector3(1.2, 0.18, length)

func _handle_move_input() -> void:
	_move_dir = Input.get_vector("ui_left", "ui_right", "ui_up", "ui_down")

func _update_player(delta: float) -> void:
	if _move_dir.length() > 0.001:
		var world_dir := Vector3(_move_dir.x, 0.0, _move_dir.y).normalized()
		player_root.position += world_dir * MOVE_SPEED * delta
		_yaw_target = atan2(world_dir.x, world_dir.z)
		if not _segments.is_empty() and _segments[0].has_method("set_idle"):
			_segments[0].set_idle(false)
	else:
		if not _segments.is_empty() and _segments[0].has_method("set_idle"):
			_segments[0].set_idle(true)

	player_root.rotation.y = lerp_angle(player_root.rotation.y, _yaw_target, delta * TURN_SPEED)
	_update_body_shadow()

func _update_camera(force_snap: bool) -> void:
	var offset := BASE_CAM_OFFSET * _zoom
	var look_target := player_root.global_position + Vector3(0.0, 0.85, 0.0)
	var target_pos := look_target + offset
	if force_snap:
		cam.position = target_pos
	else:
		cam.position = cam.position.lerp(target_pos, 0.12)
	cam.look_at(look_target, Vector3.UP)
	cam.projection = Camera3D.PROJECTION_PERSPECTIVE
	cam.fov = lerpf(46.0, 62.0, (_zoom - MIN_ZOOM) / (MAX_ZOOM - MIN_ZOOM))
	cam.current = true

func _set_zoom(value: float) -> void:
	_zoom = clampf(value, MIN_ZOOM, MAX_ZOOM)
	_update_hud()

func _update_hud() -> void:
	info_label.text = "Level 0 Test Ground\nMove: arrows/WASD | Zoom: mouse wheel or +/-\nMouth preview: left of the caterpillar"
	zoom_label.text = "Zoom: %d%%" % int(round(_zoom * 100.0))

func _on_back_pressed() -> void:
	get_tree().change_scene_to_file("res://scenes/MainMenu.tscn")

func _on_reset_pressed() -> void:
	player_root.position = Vector3.ZERO
	player_root.rotation.y = 0.0
	_yaw_target = 0.0
	_set_zoom(1.0)
