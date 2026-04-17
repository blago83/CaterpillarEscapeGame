extends Node3D

const CELL := 1.0
const WALL_HEIGHT := 0.85
const CAM_HEIGHT := 20.0
const ORTHO_SIZE := 14.0
const GROUND_COLOR := Color(0.76, 0.70, 0.50)
const BUSH_TOP := Color(0.40, 0.62, 0.10)
const BUSH_BOTTOM := Color(0.12, 0.35, 0.07)

const Segment3DScript := preload("res://scripts/segment_3d.gd")
const Leaf3DScript := preload("res://scripts/leaf_3d.gd")
const Spider3DScript := preload("res://scripts/spider_3d.gd")
const Exit3DScript := preload("res://scripts/exit_portal_3d.gd")

# Large mazes with consistent rectangular bounds.
# Legend: # wall, . path, P player, L leaf, S spider, E exit
const LEVELS := [
[
"#######################",
"#.....#.....#.....#...#",
"###.#.#.###.#.###.#.#.#",
"#...#.#...#...#...#.#.#",
"#.###.###.#####.###.#.#",
"#...#...#.....#...#.#.#",
"#.#.###.#####.###.#.#.#",
"#.#...#...L...#...#...#",
"#.###.###.###.#.#####.#",
"#...#.....#...#.....#.#",
"###.#######.#######.#.#",
"#...#.....#.....#...#.#",
"#.###.###.#####.#.###.#",
"#.....#.#...#...#..L#.#",
"#.#####.###.#.#####.#.#",
"#.#...#.....#...#...#.#",
"#.#.#.#########.#.###.#",
"#...#.....L.....#...#.#",
"#.#######.#########.#.#",
"#...#...#.....#.....#.#",
"###.#.#.#####.#.#####.#",
"#P..#.#...S...#.....E##",
"#######################",
],
[
"###########################",
"#.....#.......#.....#.....#",
"###.#.#.#####.#.###.#.###.#",
"#...#.#.....#.#...#.#...#.#",
"#.###.#####.#.###.#.###.#.#",
"#.#...#...#.#...#.#...#...#",
"#.#.###.#.#.###.#.###.###.#",
"#.#.....#.#.....#...#...#.#",
"#.#######.#########.###.#.#",
"#.....#...#...L...#.....#.#",
"#####.#.###.#####.#######.#",
"#...#.#...#.....#.......#.#",
"#.#.#.###.#####.#######.#.#",
"#.#.#...#.L...#.#.....#.#.#",
"#.#.###.#####.#.#.###.#.#.#",
"#.#...#.....#.#.#.#...#...#",
"#.###.#####.#.#.#.#.#####.#",
"#...#...#...#...#.#.....#.#",
"###.###.#.#######.#####.#.#",
"#...#...#.......#.....#.#.#",
"#.###.#########.#.###.#.#.#",
"#.#...#.....#...#.#...#.#.#",
"#.#.###.###.#.###.#.###.#.#",
"#.#.....#...#...#.#...#.#.#",
"#.#######.#.###.#.###.#.#.#",
"#.......#.#...#.#.#...#...#",
"#####.#.#.###.#.#.#.#####.#",
"#...#.#.#...#.#...#.....#.#",
"#.#.#.#.###.#.#########.#.#",
"#.#.#.#...#.#.....#...#.#.#",
"#.#.#.###.#.#####.#.#.#.#.#",
"#.#.#...#.#.....#.#.#...#.#",
"#.#.###.#.#####.#.#.#####.#",
"#.#...#.#.....#.#.#....S#.#",
"#.###.#.#####.#.#.#####.#.#",
"#...#.#.....#...#.....#...#",
"###.#.#################.###",
"#P..#..............L...E..#",
"###########################",
],
[
"###############################",
"#.....#.......#.......#.......#",
"###.#.#.#####.#.#####.#.#####.#",
"#...#.#.....#...#...#...#...#.#",
"#.###.#####.#####.#.#####.#.#.#",
"#.#...#...#.....#.#.....#.#.#.#",
"#.#.###.#.#####.#.#####.#.#.#.#",
"#.#...#.#.......#.....#.#...#.#",
"#.###.#.###########.#.#.#####.#",
"#...#.#.....#.......#.#.....#.#",
"###.#.#####.#.#######.#####.#.#",
"#...#.....#.#...#...#.....#.#.#",
"#.#######.#.###.#.#.#####.#.#.#",
"#.......#.#...#...#...#...#...#",
"#.#####.#.###.#######.#.#####.#",
"#.#...#.#...#.....#...#.....#.#",
"#.#.#.#.###.#####.#.#######.#.#",
"#.#.#...#...#...#.#.#...#...#.#",
"#.#.#####.###.#.#.#.#.#.#.###.#",
"#.#.....#..L..#.#.#...#.#...#.#",
"#.#####.#######.#.#####.###.#.#",
"#.....#.#.....#.#.....#.#...#.#",
"#####.#.#.###.#.#####.#.#.###.#",
"#...#.#.#.#...#.....#.#.#...#.#",
"#.#.#.#.#.#.#######.#.#.###.#.#",
"#.#...#...#.......#.#...#...#.#",
"#.#########.#####.#.#####.###.#",
"#.....#.....#...#.#.....#...#.#",
"###.#.#.#####.#.#.#####.###.#.#",
"#...#.#.....#.#.#.....#...#.#.#",
"#.###.#####.#.#.#####.###.#.#.#",
"#...#.#...#.#.#.#...#.#...#.#.#",
"###.#.#.#.#.#.#.#.#.#.#.###.#.#",
"#...#...#...#...#.#...#...#.#.#",
"#.###############.#######.#.#.#",
"#.....#.....#.....#.....#.#.#.#",
"#####.#.###.#.#####.###.#.#.#.#",
"#.....#...#...#...#...#...#.#.#",
"#.#######.#####.#.###.#####.#.#",
"#P...S....L.....#.......L...E.#",
"###############################",
],
]

var current_level: int = 0
var wall_set: Dictionary = {}
var player_cell: Vector2i = Vector2i.ZERO
var facing: Vector2i = Vector2i.UP
var segment_cells: Array[Vector2i] = []
var segment_nodes: Array[Node3D] = []
var _segment_targets: Array[Vector3] = []
var _segment_target_rots: Array[float] = []
var leaves: Dictionary = {}
var hazards: Dictionary = {}
var exit_cell: Vector2i = Vector2i.ZERO
var exit_node: Node3D = null
var leaves_left: int = 0
var is_busy: bool = false
var swipe_start := Vector2.ZERO
var move_timer: float = 0.0
const MOVE_REPEAT_DELAY := 0.15
const REVERSE_REPEAT_DELAY := 0.3
var _is_reversing: bool = false

var _maze_w: int = 0
var _maze_h: int = 0

# Shared resources for performance
var _wall_mat: ShaderMaterial
var _wall_mesh: BoxMesh
var _ground_mat: StandardMaterial3D
var _cam_target := Vector3.ZERO
var _cam_z_min := -1e9
var _cam_z_max := 1e9
var _wall_cells: Array[Vector2i] = []
var _diag_timer := 0.0
var _move_count := 0
var _frame_count := 0

@onready var cam: Camera3D = $Camera3D
@onready var maze_layer: Node3D = $MazeLayer
@onready var objects_layer: Node3D = $ObjectsLayer
@onready var cat_layer: Node3D = $CaterpillarLayer
@onready var hud_label: Label = $CanvasLayer/HUD/TopBar/InfoLabel
@onready var win_panel: ColorRect = $CanvasLayer/WinPanel

func _ready() -> void:
	RenderingServer.set_default_clear_color(Color(0.12, 0.18, 0.08))
	_init_shared_resources()
	_setup_lighting()
	$CanvasLayer/HUD/TopBar/RetryButton.pressed.connect(_on_retry)
	$CanvasLayer/HUD/TopBar/MenuButton.pressed.connect(_on_menu)
	$CanvasLayer/WinPanel/VBox/NextButton.pressed.connect(_on_next)
	load_level(current_level)

func _init_shared_resources() -> void:
	# Hedge shader – rounded top, gradient from yellow-green top to dark green bottom
	var hedge_shader := Shader.new()
	hedge_shader.code = "
shader_type spatial;
render_mode cull_disabled, unshaded;
uniform vec3 color_top : source_color = vec3(0.55, 0.78, 0.15);
uniform vec3 color_bot : source_color = vec3(0.18, 0.45, 0.10);
uniform sampler2D leaf_tex : hint_default_white, filter_linear_mipmap, repeat_enable;
uniform float tex_scale : hint_range(0.1, 8.0) = 2.0;
uniform float tex_influence : hint_range(0.0, 1.0) = 0.6;

varying vec3 v_world_pos;
varying vec3 v_world_normal;

void vertex() {
    // Capture stable world-space position BEFORE any vertex modification
    v_world_pos = (MODEL_MATRIX * vec4(VERTEX, 1.0)).xyz;
    v_world_normal = normalize((MODEL_MATRIX * vec4(NORMAL, 0.0)).xyz);

    // Rounded-box SDF-style rounding for all edges and corners
    float half_w = 0.5;
    float half_h = 0.425;
    float r = 0.1;

    vec3 local = VERTEX;
    vec3 s = sign(local);
    vec3 a = abs(local);

    vec3 inner = vec3(half_w - r, half_h - r, half_w - r);
    vec3 d = max(a - inner, vec3(0.0));
    float l = length(d);
    if (l > 0.001) {
        vec3 rounded = min(a, inner) + d * (r / l);
        local = s * rounded;
    }
    VERTEX = local;
}

void fragment() {
    // Use the stable pre-rounding world position from the vertex shader
    vec3 blend_weights = abs(v_world_normal);
    blend_weights = pow(blend_weights, vec3(4.0));
    blend_weights /= (blend_weights.x + blend_weights.y + blend_weights.z);

    // Triplanar sampling using stable coordinates
    vec3 tex_x = texture(leaf_tex, v_world_pos.yz * tex_scale).rgb;
    vec3 tex_y = texture(leaf_tex, v_world_pos.xz * tex_scale).rgb;
    vec3 tex_z = texture(leaf_tex, v_world_pos.xy * tex_scale).rgb;
    vec3 leaf_col = tex_x * blend_weights.x + tex_y * blend_weights.y + tex_z * blend_weights.z;

    // Vertical gradient from bottom to top
    float h = clamp(v_world_pos.y / 0.85, 0.0, 1.0);
    vec3 base = mix(color_bot, color_top, h);

    // Blend the leaf texture pattern with the gradient colour
    base = mix(base, base * leaf_col * 1.3, tex_influence);

    ALBEDO = base;
}
"
	_wall_mat = ShaderMaterial.new()
	_wall_mat.shader = hedge_shader
	_wall_mat.set_shader_parameter("color_top", Vector3(BUSH_TOP.r, BUSH_TOP.g, BUSH_TOP.b))
	_wall_mat.set_shader_parameter("color_bot", Vector3(BUSH_BOTTOM.r, BUSH_BOTTOM.g, BUSH_BOTTOM.b))
	var leaf_tex := load("res://assets/New/leaf_pattern.png") as Texture2D
	if leaf_tex:
		_wall_mat.set_shader_parameter("leaf_tex", leaf_tex)
	_wall_mat.set_shader_parameter("tex_scale", 0.4)
	_wall_mat.set_shader_parameter("tex_influence", 0.6)

	_wall_mesh = BoxMesh.new()
	_wall_mesh.size = Vector3(CELL, WALL_HEIGHT, CELL)
	_wall_mesh.subdivide_width = 8
	_wall_mesh.subdivide_height = 8
	_wall_mesh.subdivide_depth = 8

	_ground_mat = StandardMaterial3D.new()
	_ground_mat.albedo_color = Color(0.93, 0.85, 0.65)
	_ground_mat.shading_mode = BaseMaterial3D.SHADING_MODE_UNSHADED
	var ground_tex := load("res://assets/background_sand.png") as Texture2D
	if ground_tex:
		_ground_mat.albedo_texture = ground_tex
		_ground_mat.texture_filter = BaseMaterial3D.TEXTURE_FILTER_LINEAR_WITH_MIPMAPS_ANISOTROPIC

func _setup_lighting() -> void:
	# Directional light – slightly angled for soft shadows and depth
	var light := DirectionalLight3D.new()
	light.rotation_degrees = Vector3(-70, 30, 0)
	light.shadow_enabled = true
	light.light_energy = 0.8
	light.light_color = Color(1.0, 0.98, 0.92)
	light.directional_shadow_max_distance = 60.0
	light.directional_shadow_mode = DirectionalLight3D.SHADOW_PARALLEL_2_SPLITS
	add_child(light)

	# World environment
	var world_env := WorldEnvironment.new()
	var env := Environment.new()
	env.background_mode = Environment.BG_COLOR
	env.background_color = Color(0.12, 0.18, 0.08)
	env.ambient_light_source = Environment.AMBIENT_SOURCE_COLOR
	env.ambient_light_color = Color(0.75, 0.75, 0.70)
	env.ambient_light_energy = 0.6
	world_env.environment = env
	add_child(world_env)

# ── Coordinate helpers ──

func _pos(cell: Vector2i) -> Vector3:
	return Vector3(float(cell.x) * CELL, 0.0, float(cell.y) * CELL)

func _dir_angle_y(dir: Vector2i) -> float:
	# Camera looks down -Y; model forward is -Z
	if dir == Vector2i.UP: return 0.0           # toward -Z
	if dir == Vector2i.RIGHT: return -PI * 0.5   # toward +X
	if dir == Vector2i.DOWN: return PI            # toward +Z
	if dir == Vector2i.LEFT: return PI * 0.5      # toward -X
	return 0.0

# ── Level loading ──

func _clear() -> void:
	for c in maze_layer.get_children():
		c.queue_free()
	for c in objects_layer.get_children():
		c.queue_free()
	for c in cat_layer.get_children():
		c.queue_free()
	wall_set.clear()
	segment_cells.clear()
	segment_nodes.clear()
	_segment_targets.clear()
	_segment_target_rots.clear()
	leaves.clear()
	hazards.clear()
	exit_node = null

func load_level(idx: int) -> void:
	_clear()
	current_level = idx % LEVELS.size()
	leaves_left = 0
	var rows: Array = LEVELS[current_level]

	_maze_h = rows.size()
	_maze_w = 0
	for row in rows:
		_maze_w = max(_maze_w, row.length())

	# Ground plane
	_create_ground(_maze_w, _maze_h)

	# Parse maze – collect wall positions first
	_wall_cells.clear()
	for y in rows.size():
		var row: String = rows[y]
		for x in row.length():
			var ch := row[x]
			var cell := Vector2i(x, y)
			if ch == "#":
				wall_set[cell] = true
				_wall_cells.append(cell)
			match ch:
				"P":
					player_cell = cell
				"L":
					leaves_left += 1
					_make_leaf(cell)
				"S":
					_make_spider(cell)
				"E":
					exit_cell = cell
					_make_exit(cell)

	# Build all walls as a single MultiMesh
	_build_wall_multimesh()

	# Scatter decorations outside the maze
	_spawn_decorations()

	# Camera setup – orthographic for uniform brightness across the screen
	cam.projection = Camera3D.PROJECTION_ORTHOGONAL
	cam.size = ORTHO_SIZE
	cam.near = 0.1
	cam.far = 100.0
	cam.rotation_degrees = Vector3(-50, 0, 0)
	# Compute camera Z bounds so the view stays within the maze
	var cam_offset_z := CAM_HEIGHT / tan(deg_to_rad(50.0))
	# Orthographic: visible Z range on ground = size / sin(tilt), symmetric top/bottom
	var half_view_z := ORTHO_SIZE / (2.0 * sin(deg_to_rad(50.0)))
	var maze_z_top := -0.5 * CELL
	var maze_z_bot := (float(_maze_h) - 0.5) * CELL
	_cam_z_min = maze_z_top + cam_offset_z + half_view_z
	_cam_z_max = maze_z_bot + cam_offset_z - half_view_z
	if _cam_z_min > _cam_z_max:
		var mid := (_cam_z_min + _cam_z_max) * 0.5
		_cam_z_min = mid
		_cam_z_max = mid

	var head_pos := _pos(player_cell)
	_cam_target = Vector3(head_pos.x, CAM_HEIGHT, clampf(head_pos.z + cam_offset_z, _cam_z_min, _cam_z_max))
	cam.position = _cam_target
	cam.current = true
	print("Level loaded: %d walls, cam at %s" % [wall_set.size(), cam.position])

	# Caterpillar – determine initial facing (first open direction)
	for d in [Vector2i.RIGHT, Vector2i.UP, Vector2i.DOWN, Vector2i.LEFT]:
		if not wall_set.has(player_cell + d):
			facing = d
			break
	# Walk the head forward so the body/tail naturally trail behind.
	# segment_cells[0] = head (front), segment_cells[-1] = tail (back)
	var init_path: Array[Vector2i] = [player_cell]
	var walk := player_cell
	for i in range(4):
		var next := walk + facing
		if not wall_set.has(next) and not init_path.has(next):
			init_path.push_front(next)
			walk = next
		else:
			break
	# init_path is [head, body x3, tail]. Pad to at least 5 segments.
	while init_path.size() < 5:
		init_path.append(init_path[-1])
	segment_cells = init_path
	player_cell = segment_cells[0]
	_rebuild_caterpillar()
	_update_hud()
	win_panel.visible = false
	is_busy = false

func _create_ground(w: int, h: int) -> void:
	# Inner maze ground with sand/path texture
	var mesh_inst := MeshInstance3D.new()
	var plane := PlaneMesh.new()
	plane.size = Vector2(float(w) * CELL, float(h) * CELL)
	plane.subdivide_width = 0
	plane.subdivide_depth = 0
	mesh_inst.mesh = plane
	# Tile the texture uniformly (same scale on both axes)
	var tiles := float(max(w, h)) / 4.05
	_ground_mat.uv1_scale = Vector3(tiles, tiles, 1.0)
	mesh_inst.material_override = _ground_mat
	mesh_inst.position = Vector3(
		(float(w) - 1.0) * CELL * 0.5,
		-0.01,
		(float(h) - 1.0) * CELL * 0.5
	)
	maze_layer.add_child(mesh_inst)

	# Outer landscape ground – covers the visible area outside the maze
	var pad := 30.0
	var outer_w := float(w) * CELL + pad * 2.0
	var outer_h := float(h) * CELL + pad * 2.0
	var outer_inst := MeshInstance3D.new()
	var outer_plane := PlaneMesh.new()
	outer_plane.size = Vector2(outer_w, outer_h)
	outer_plane.subdivide_width = 0
	outer_plane.subdivide_depth = 0
	outer_inst.mesh = outer_plane
	var outer_mat := StandardMaterial3D.new()
	outer_mat.albedo_color = Color(0.85, 0.85, 0.85)
	outer_mat.shading_mode = BaseMaterial3D.SHADING_MODE_UNSHADED
	var landscape_tex := load("res://assets/New/landscape-pattern.png") as Texture2D
	if landscape_tex:
		outer_mat.albedo_texture = landscape_tex
		outer_mat.texture_filter = BaseMaterial3D.TEXTURE_FILTER_LINEAR_WITH_MIPMAPS_ANISOTROPIC
	# Tile proportionally to actual plane size so the texture isn't stretched
	var tile_density := 0.15  # tiles per world unit
	outer_mat.uv1_scale = Vector3(outer_w * tile_density, outer_h * tile_density, 1.0)
	outer_inst.material_override = outer_mat
	outer_inst.position = Vector3(
		(float(w) - 1.0) * CELL * 0.5,
		-0.02,
		(float(h) - 1.0) * CELL * 0.5
	)
	maze_layer.add_child(outer_inst)

# ── Entity factories ──

# ── Decorations ──

func _make_flower(pos: Vector3) -> void:
	var root := Node3D.new()
	root.position = pos
	# Stem
	var stem_mesh := CylinderMesh.new()
	stem_mesh.top_radius = 0.02
	stem_mesh.bottom_radius = 0.03
	stem_mesh.height = 0.3
	var stem_inst := MeshInstance3D.new()
	stem_inst.mesh = stem_mesh
	var stem_mat := StandardMaterial3D.new()
	stem_mat.albedo_color = Color(0.2, 0.55, 0.15)
	stem_inst.material_override = stem_mat
	stem_inst.position.y = 0.15
	stem_inst.cast_shadow = GeometryInstance3D.SHADOW_CASTING_SETTING_OFF
	root.add_child(stem_inst)
	# Petals (a flattened sphere)
	var petal_mesh := SphereMesh.new()
	petal_mesh.radius = 0.1
	petal_mesh.height = 0.08
	var petal_inst := MeshInstance3D.new()
	petal_inst.mesh = petal_mesh
	var petal_mat := StandardMaterial3D.new()
	var petal_colors := [Color(0.9, 0.2, 0.3), Color(0.95, 0.75, 0.2), Color(0.7, 0.3, 0.8), Color(1.0, 0.5, 0.6), Color(0.3, 0.55, 0.95)]
	petal_mat.albedo_color = petal_colors[randi() % petal_colors.size()]
	petal_inst.material_override = petal_mat
	petal_inst.position.y = 0.32
	petal_inst.cast_shadow = GeometryInstance3D.SHADOW_CASTING_SETTING_OFF
	root.add_child(petal_inst)
	# Center
	var center_mesh := SphereMesh.new()
	center_mesh.radius = 0.04
	center_mesh.height = 0.06
	var center_inst := MeshInstance3D.new()
	center_inst.mesh = center_mesh
	var center_mat := StandardMaterial3D.new()
	center_mat.albedo_color = Color(0.95, 0.85, 0.2)
	center_inst.material_override = center_mat
	center_inst.position.y = 0.35
	center_inst.cast_shadow = GeometryInstance3D.SHADOW_CASTING_SETTING_OFF
	root.add_child(center_inst)
	root.rotation.y = randf() * TAU
	var s := randf_range(0.7, 1.3)
	root.scale = Vector3(s, s, s)
	maze_layer.add_child(root)

func _make_mushroom(pos: Vector3) -> void:
	var root := Node3D.new()
	root.position = pos
	# Stem
	var stem_mesh := CylinderMesh.new()
	stem_mesh.top_radius = 0.05
	stem_mesh.bottom_radius = 0.06
	stem_mesh.height = 0.18
	var stem_inst := MeshInstance3D.new()
	stem_inst.mesh = stem_mesh
	var stem_mat := StandardMaterial3D.new()
	stem_mat.albedo_color = Color(0.9, 0.88, 0.78)
	stem_inst.material_override = stem_mat
	stem_inst.position.y = 0.09
	stem_inst.cast_shadow = GeometryInstance3D.SHADOW_CASTING_SETTING_OFF
	root.add_child(stem_inst)
	# Cap (hemisphere)
	var cap_mesh := SphereMesh.new()
	cap_mesh.radius = 0.12
	cap_mesh.height = 0.14
	var cap_inst := MeshInstance3D.new()
	cap_inst.mesh = cap_mesh
	var cap_mat := StandardMaterial3D.new()
	var cap_colors := [Color(0.8, 0.15, 0.12), Color(0.85, 0.55, 0.15), Color(0.6, 0.35, 0.2)]
	cap_mat.albedo_color = cap_colors[randi() % cap_colors.size()]
	cap_inst.material_override = cap_mat
	cap_inst.position.y = 0.2
	cap_inst.cast_shadow = GeometryInstance3D.SHADOW_CASTING_SETTING_OFF
	root.add_child(cap_inst)
	root.rotation.y = randf() * TAU
	var s := randf_range(0.6, 1.4)
	root.scale = Vector3(s, s, s)
	maze_layer.add_child(root)

func _make_rock(pos: Vector3) -> void:
	var root := Node3D.new()
	root.position = pos
	var rock_mesh := SphereMesh.new()
	var rx := randf_range(0.08, 0.18)
	var ry := randf_range(0.06, 0.12)
	rock_mesh.radius = rx
	rock_mesh.height = ry * 2.0
	var rock_inst := MeshInstance3D.new()
	rock_inst.mesh = rock_mesh
	var rock_mat := StandardMaterial3D.new()
	var grey := randf_range(0.35, 0.6)
	rock_mat.albedo_color = Color(grey, grey * 0.95, grey * 0.9)
	rock_mat.roughness = 0.95
	rock_inst.material_override = rock_mat
	rock_inst.position.y = ry * 0.5
	rock_inst.cast_shadow = GeometryInstance3D.SHADOW_CASTING_SETTING_OFF
	root.add_child(rock_inst)
	root.rotation.y = randf() * TAU
	root.rotation.x = randf_range(-0.15, 0.15)
	root.rotation.z = randf_range(-0.15, 0.15)
	maze_layer.add_child(root)

func _make_grass_tuft(pos: Vector3) -> void:
	var root := Node3D.new()
	root.position = pos
	var blade_count := randi_range(3, 6)
	var mat := StandardMaterial3D.new()
	mat.albedo_color = Color(randf_range(0.25, 0.45), randf_range(0.55, 0.75), randf_range(0.1, 0.2))
	mat.cull_mode = BaseMaterial3D.CULL_DISABLED
	for i in blade_count:
		var blade := MeshInstance3D.new()
		var bm := PrismMesh.new()
		bm.size = Vector3(0.03, randf_range(0.15, 0.35), 0.005)
		blade.mesh = bm
		blade.material_override = mat
		blade.position = Vector3(randf_range(-0.06, 0.06), bm.size.y * 0.5, randf_range(-0.06, 0.06))
		blade.rotation.y = randf() * TAU
		blade.rotation.z = randf_range(-0.3, 0.3)
		blade.cast_shadow = GeometryInstance3D.SHADOW_CASTING_SETTING_OFF
		root.add_child(blade)
	maze_layer.add_child(root)

func _spawn_decorations() -> void:
	# Place decorations in the empty strips to the left and right of the maze
	var margin := 8.0  # how far out from maze edge to scatter
	var maze_left := -0.5 * CELL
	var maze_right := (float(_maze_w) - 0.5) * CELL
	var maze_top := -0.5 * CELL
	var maze_bot := (float(_maze_h) - 0.5) * CELL

	var rng := RandomNumberGenerator.new()
	rng.seed = current_level * 12345 + 42  # deterministic per level

	# Density: number of decorations per side
	var count_per_side := int(_maze_h * 1.5)

	for side in 2:  # 0 = left, 1 = right
		for _i in count_per_side:
			var z := rng.randf_range(maze_top - 1.0, maze_bot + 1.0)
			var x: float
			if side == 0:
				x = rng.randf_range(maze_left - margin, maze_left - 0.8)
			else:
				x = rng.randf_range(maze_right + 0.8, maze_right + margin)
			var pos := Vector3(x, 0.0, z)
			var kind := rng.randi_range(0, 3)
			match kind:
				0: _make_flower(pos)
				1: _make_mushroom(pos)
				2: _make_rock(pos)
				3: _make_grass_tuft(pos)

func _build_wall_multimesh() -> void:
	# Bush body
	var mm := MultiMesh.new()
	mm.transform_format = MultiMesh.TRANSFORM_3D
	mm.mesh = _wall_mesh
	mm.instance_count = _wall_cells.size()
	for i in _wall_cells.size():
		var p := _pos(_wall_cells[i])
		var t := Transform3D.IDENTITY
		t.origin = Vector3(p.x, WALL_HEIGHT * 0.5, p.z)
		mm.set_instance_transform(i, t)
	var mm_inst := MultiMeshInstance3D.new()
	mm_inst.multimesh = mm
	mm_inst.material_override = _wall_mat
	mm_inst.cast_shadow = GeometryInstance3D.SHADOW_CASTING_SETTING_ON
	maze_layer.add_child(mm_inst)

func _make_leaf(cell: Vector2i) -> void:
	var node := Node3D.new()
	node.set_script(Leaf3DScript)
	node.position = _pos(cell)
	objects_layer.add_child(node)
	leaves[cell] = node

func _make_spider(cell: Vector2i) -> void:
	var node := Node3D.new()
	node.set_script(Spider3DScript)
	node.position = _pos(cell)
	objects_layer.add_child(node)
	hazards[cell] = "spider"

func _make_exit(cell: Vector2i) -> void:
	exit_node = Node3D.new()
	exit_node.set_script(Exit3DScript)
	exit_node.position = _pos(cell)
	exit_node.set_meta("open", false)
	objects_layer.add_child(exit_node)

# ── Caterpillar ──

func _rebuild_caterpillar() -> void:
	for c in cat_layer.get_children():
		c.queue_free()
	segment_nodes.clear()
	for i in segment_cells.size():
		var node := Node3D.new()
		node.set_script(Segment3DScript)
		node.set_meta("seg_type", _seg_type(i))
		node.set_meta("seg_index", i)
		cat_layer.add_child(node)
		segment_nodes.append(node)
	_update_positions()
	_segment_targets = _calc_positions()
	_update_rotations_instant()
	_segment_target_rots = _calc_target_rotations()
	_update_taper()

func _calc_positions() -> Array[Vector3]:
	var spacing := CELL * 0.30
	var positions: Array[Vector3] = []

	# Build polyline from grid cell centres
	var path: Array[Vector3] = []
	for cell in segment_cells:
		path.append(_pos(cell))

	positions.append(path[0])

	var total_dist := 0.0
	for seg_i in range(1, segment_cells.size()):
		total_dist += spacing
		# Walk along the polyline to find the point at total_dist
		var walked := 0.0
		var found := false
		for j in range(path.size() - 1):
			var seg_len := path[j].distance_to(path[j + 1])
			if walked + seg_len >= total_dist:
				var t := (total_dist - walked) / seg_len if seg_len > 0.0 else 0.0
				positions.append(path[j].lerp(path[j + 1], t))
				found = true
				break
			walked += seg_len
		if not found:
			positions.append(path[-1])

	return positions

func _update_positions() -> void:
	var positions := _calc_positions()
	for i in segment_nodes.size():
		segment_nodes[i].position = positions[i]

func _seg_type(i: int) -> String:
	if i == 0:
		return "head"
	elif i == segment_cells.size() - 1:
		return "tail"
	return "body"

func _calc_target_rotations() -> Array[float]:
	var rots: Array[float] = []
	for i in segment_cells.size():
		var dir: Vector2i
		if i == 0:
			dir = facing
		else:
			dir = segment_cells[i - 1] - segment_cells[i]
		rots.append(_dir_angle_y(dir))
	return rots

func _update_rotations_instant() -> void:
	for i in segment_nodes.size():
		var dir: Vector2i
		if i == 0:
			dir = facing
		else:
			dir = segment_cells[i - 1] - segment_cells[i]
		segment_nodes[i].rotation.y = _dir_angle_y(dir)
		var is_horizontal := (dir == Vector2i.LEFT or dir == Vector2i.RIGHT)
		segment_nodes[i].update_direction(is_horizontal)

func _update_taper() -> void:
	var n := segment_nodes.size()
	for i in n:
		var s := 1.0
		if i == 0:
			s = 1.0
		elif i == 1:
			s = 0.85
		elif i == n - 1:
			s = 0.7
		else:
			var body_i := i - 2
			if body_i < 3:
				s = 0.95 + 0.05 * float(body_i)
			else:
				s = 1.1
		segment_nodes[i].scale = Vector3(s, s, s)

# ── Input ──

func _input(event: InputEvent) -> void:
	if event is InputEventScreenTouch:
		if event.pressed:
			swipe_start = event.position
		else:
			var delta: Vector2 = event.position - swipe_start
			if delta.length() > 40.0:
				if abs(delta.x) > abs(delta.y):
					_try_move(Vector2i.RIGHT if delta.x > 0 else Vector2i.LEFT)
				else:
					_try_move(Vector2i.DOWN if delta.y > 0 else Vector2i.UP)

func _get_held_dir() -> Vector2i:
	if Input.is_action_pressed("move_up"): return Vector2i.UP
	if Input.is_action_pressed("move_down"): return Vector2i.DOWN
	if Input.is_action_pressed("move_left"): return Vector2i.LEFT
	if Input.is_action_pressed("move_right"): return Vector2i.RIGHT
	return Vector2i.ZERO

func _unhandled_input(event: InputEvent) -> void:
	if event.is_action_pressed("move_up"):
		_try_move(Vector2i.UP); move_timer = 0.0
	elif event.is_action_pressed("move_down"):
		_try_move(Vector2i.DOWN); move_timer = 0.0
	elif event.is_action_pressed("move_left"):
		_try_move(Vector2i.LEFT); move_timer = 0.0
	elif event.is_action_pressed("move_right"):
		_try_move(Vector2i.RIGHT); move_timer = 0.0

func _process(delta: float) -> void:
	_frame_count += 1
	# Diagnostic heartbeat every 5 seconds
	_diag_timer += delta
	if _diag_timer >= 5.0:
		var tree := get_tree()
		var node_count := Performance.get_monitor(Performance.OBJECT_NODE_COUNT)
		var obj_count := Performance.get_monitor(Performance.OBJECT_COUNT)
		var mem_static := Performance.get_monitor(Performance.MEMORY_STATIC) / 1048576.0
		var mem_msg := Performance.get_monitor(Performance.MEMORY_MESSAGE_BUFFER_MAX) / 1048576.0
		var fps := Performance.get_monitor(Performance.TIME_FPS)
		var draw_calls := Performance.get_monitor(Performance.RENDER_TOTAL_DRAW_CALLS_IN_FRAME)
		var vram := Performance.get_monitor(Performance.RENDER_VIDEO_MEM_USED) / 1048576.0
		print("[DIAG t=%.0f] FPS=%.0f nodes=%d objs=%d mem=%.1fMB msgbuf=%.1fMB vram=%.1fMB draws=%.0f moves=%d segments=%d catchildren=%d" % [
			_diag_timer + 5.0, fps, node_count, obj_count, mem_static, mem_msg, vram, draw_calls, _move_count, segment_nodes.size(), cat_layer.get_child_count()])
		_diag_timer = 0.0

	# Smooth camera follow
	cam.position = cam.position.lerp(_cam_target, minf(delta * 12.0, 1.0))

	# Smooth segment interpolation
	var lerp_speed: float
	if _is_reversing:
		lerp_speed = minf(delta * 8.0, 1.0)
	else:
		lerp_speed = minf(delta * 14.0, 1.0)
	for i in segment_nodes.size():
		if i < _segment_targets.size():
			segment_nodes[i].position = segment_nodes[i].position.lerp(_segment_targets[i], lerp_speed)
		if i < _segment_target_rots.size():
			segment_nodes[i].rotation.y = lerp_angle(segment_nodes[i].rotation.y, _segment_target_rots[i], lerp_speed)

	var dir := _get_held_dir()
	if dir == Vector2i.ZERO:
		move_timer = 0.0
		return
	var repeat_delay := REVERSE_REPEAT_DELAY if dir == -facing else MOVE_REPEAT_DELAY
	move_timer += delta
	if move_timer >= repeat_delay:
		move_timer -= repeat_delay
		_try_move(dir)

# ── Movement ──

func _try_move(dir: Vector2i) -> void:
	if is_busy:
		return
	var reverse_dir := -facing
	if dir == reverse_dir:
		_move_backward()
		return
	_is_reversing = false
	facing = dir
	var target := segment_cells[0] + dir
	if wall_set.has(target):
		_bump()
		return
	if segment_cells.has(target) and target != segment_cells[-1]:
		_bump()
		return
	_move_to(target)

func _move_backward() -> void:
	_is_reversing = true
	is_busy = true
	_move_count += 1

	# Tail leads: find a free cell adjacent to the tail to extend into
	var n := segment_cells.size()
	var tail_dir: Vector2i
	if n > 1:
		tail_dir = segment_cells[n - 1] - segment_cells[n - 2]
	else:
		tail_dir = -facing

	# Try straight first, then perpendicular directions
	var try_dirs: Array[Vector2i] = [tail_dir]
	if tail_dir.x == 0:
		try_dirs.append(Vector2i.LEFT)
		try_dirs.append(Vector2i.RIGHT)
	else:
		try_dirs.append(Vector2i.UP)
		try_dirs.append(Vector2i.DOWN)

	var new_tail := Vector2i.ZERO
	var found_tail := false
	for d in try_dirs:
		var candidate: Vector2i = segment_cells[n - 1] + d
		if not wall_set.has(candidate) and not segment_cells.has(candidate):
			new_tail = candidate
			found_tail = true
			break
		# Also allow if it's the head cell (which will vacate)
		if not wall_set.has(candidate) and candidate == segment_cells[0]:
			new_tail = candidate
			found_tail = true
			break
	if not found_tail:
		is_busy = false
		_bump()
		return

	# Slide every segment toward the tail: seg[i] = old seg[i+1], tail = new cell
	var prev := segment_cells.duplicate()
	for i in range(0, n - 1):
		segment_cells[i] = prev[i + 1]
	segment_cells[n - 1] = new_tail

	_segment_targets = _calc_positions()
	_segment_target_rots = _calc_target_rotations()
	var head3 := _pos(segment_cells[0])
	var cam_offset_z := CAM_HEIGHT * tan(deg_to_rad(25.0))
	_cam_target = Vector3(head3.x, CAM_HEIGHT, clampf(head3.z + cam_offset_z, _cam_z_min, _cam_z_max))

	# When reversing, the tail is the leading end — check it for pickups/hazards
	var lead_cell := new_tail
	if leaves.has(lead_cell):
		leaves[lead_cell].queue_free()
		leaves.erase(lead_cell)
		leaves_left -= 1
		# Grow from the head side (opposite of travel direction)
		var head_dir: Vector2i
		if n > 1:
			head_dir = prev[0] - prev[1]
		else:
			head_dir = facing
		var extra_cell: Vector2i = segment_cells[0] + head_dir
		segment_cells.insert(0, extra_cell)
		var node := Node3D.new()
		node.set_script(Segment3DScript)
		node.set_meta("seg_type", "body")
		node.set_meta("seg_index", 0)
		cat_layer.add_child(node)
		segment_nodes.insert(0, node)
		var positions := _calc_positions()
		node.position = positions[0]
		segment_nodes[0].update_seg_type(_seg_type(0))
		segment_nodes[1].update_seg_type(_seg_type(1))
		_segment_targets = _calc_positions()
		_segment_target_rots = _calc_target_rotations()
	_update_taper()
	for sn in segment_nodes:
		sn.wiggle_legs()

	if hazards.has(lead_cell):
		await _lose()
		return
	if leaves_left <= 0 and exit_node:
		exit_node.set_meta("open", true)
	if lead_cell == exit_cell and leaves_left <= 0:
		await _win()
		return

	_update_hud()
	is_busy = false

func _move_to(target: Vector2i) -> void:
	is_busy = true
	_move_count += 1
	var prev := segment_cells.duplicate()
	segment_cells[0] = target
	for i in range(1, segment_cells.size()):
		segment_cells[i] = prev[i - 1]

	_segment_targets = _calc_positions()
	_segment_target_rots = _calc_target_rotations()
	var tgt3 := _pos(target)
	var cam_offset_z := CAM_HEIGHT * tan(deg_to_rad(25.0))
	_cam_target = Vector3(tgt3.x, CAM_HEIGHT, clampf(tgt3.z + cam_offset_z, _cam_z_min, _cam_z_max))

	# Collect leaf
	if leaves.has(target):
		leaves[target].queue_free()
		leaves.erase(target)
		leaves_left -= 1
		var new_cell: Vector2i = prev[-1]
		segment_cells.append(new_cell)
		var node := Node3D.new()
		node.set_script(Segment3DScript)
		var tail_positions := _calc_positions()
		node.position = tail_positions[-1]
		node.set_meta("seg_type", "tail")
		node.set_meta("seg_index", segment_cells.size() - 1)
		cat_layer.add_child(node)
		segment_nodes.append(node)
		if segment_nodes.size() > 2:
			segment_nodes[-2].update_seg_type("body")
		_segment_targets = _calc_positions()
		_segment_target_rots = _calc_target_rotations()
	_update_taper()
	for n in segment_nodes:
		n.wiggle_legs()

	if hazards.has(target):
		await _lose()
		return
	if leaves_left <= 0 and exit_node:
		exit_node.set_meta("open", true)
	if target == exit_cell and leaves_left <= 0:
		await _win()
		return

	_update_hud()
	is_busy = false

func _bump() -> void:
	pass

func _lose() -> void:
	hud_label.text = "Ouch! Restarting..."
	for n in segment_nodes:
		n.flash_red()
	await get_tree().create_timer(0.7).timeout
	load_level(current_level)

func _win() -> void:
	is_busy = true
	win_panel.visible = true
	var vbox := $CanvasLayer/WinPanel/VBox
	vbox.get_node("Title").text = "Level %d Complete!" % (current_level + 1)
	if current_level >= LEVELS.size() - 1:
		vbox.get_node("SubTitle").text = "You escaped all mazes!"
		vbox.get_node("NextButton").text = "Play Again"
	else:
		vbox.get_node("SubTitle").text = "Your caterpillar escaped!"
		vbox.get_node("NextButton").text = "Next Level"

func _update_hud() -> void:
	hud_label.text = "Level %d   Leaves: %d   Length: %d" % [current_level + 1, leaves_left, segment_cells.size()]

func _on_retry() -> void:
	load_level(current_level)

func _on_menu() -> void:
	get_tree().change_scene_to_file("res://scenes/MainMenu.tscn")

func _on_next() -> void:
	load_level((current_level + 1) % LEVELS.size())
