extends Node3D

const CELL := 1.0
const WALL_HEIGHT := 0.60
const GROUND_COLOR := Color(0.76, 0.70, 0.50)
const BUSH_TOP := Color(0.48, 0.70, 0.15)
const BUSH_BOTTOM := Color(0.22, 0.48, 0.12)

# Camera offset from the look-at target (gives that ~-52°, -32° perspective feel)
const CAM_OFFSET := Vector3(0.1, 9.0, 7.5)
const CAM_FOV := 54.0
const CAM_EDGE_PAD_LEFT := 1.6
const CAM_EDGE_PAD_RIGHT := 0.0
const CAM_EDGE_PAD_TOP := 0.0
const CAM_EDGE_PAD_BOTTOM := 4.8
const CAM_TOP_FOLLOW_PIN_Z := 6.0

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
const MOVE_REPEAT_DELAY := 0.22
const REVERSE_REPEAT_DELAY := 1.20
const FORWARD_MOVE_DURATION := 0.34
const REVERSE_MOVE_DURATION := 0.68
var _is_reversing: bool = false
var _move_anim_remaining := 0.0
var _allow_busy_release := true
var _crawl_motion_time := 0.0
var _want_move_sound := false

var _maze_w: int = 0
var _maze_h: int = 0

# Shared resources for performance
var _wall_mat: ShaderMaterial
var _wall_mesh: BoxMesh
var _ground_mat: StandardMaterial3D
var _cam_look_target := Vector3.ZERO
var _wall_cells: Array[Vector2i] = []
var _diag_timer := 0.0
var _move_count := 0
var _frame_count := 0
var _p_was_pressed := false
var _idle_timer := 0.0
const IDLE_LOOK_DELAY := 3.0  # seconds before caterpillar looks at camera
var _is_looking_at_camera := false
var _body_shadow: MeshInstance3D = null

# ── Bush biting ──
const BITE_DURATION := 6.0       # seconds per bite – matches bite.wav length
const BITES_TO_EAT := 3          # bites needed to destroy a bush
var _bite_target: Vector2i = Vector2i(-999, -999)  # cell being bitten
var _bite_count: Dictionary = {} # cell -> int (accumulated bites)
var _bite_timer := 0.0           # countdown for current bite
var _is_biting := false
var _bite_face_loop_timer := 0.0
var _bite_face_is_biting := true
const BITE_FACE_LOOP_INTERVAL := 0.45
var _wall_mm_inst: MultiMeshInstance3D = null
var _lump_mm_inst: MultiMeshInstance3D = null
var _bite_marks: Array[Node3D] = []  # legacy bite visual nodes
var _bitten_bush_nodes: Dictionary = {}   # cell -> Node3D (individual bitten bush root)
var _bitten_bush_hscale: Dictionary = {}  # cell -> float (original h_scale)
var _cell_wall_index: Dictionary = {}     # cell -> int index in wall MultiMesh
var _cell_wall_scales: Dictionary = {}    # cell -> Vector2 (w_scale, h_scale) from MM build
var _cell_lump_range: Dictionary = {}     # cell -> Vector2i (lump start, end) in lump MultiMesh
var _bite_cavity_mat: StandardMaterial3D = null
var _spider_rng := RandomNumberGenerator.new()

# ── Sounds ──
var _snd_move: AudioStreamPlayer
var _snd_bite: AudioStreamPlayer
var _snd_eat: AudioStreamPlayer
var _snd_leaf: AudioStreamPlayer
var _snd_portal: AudioStreamPlayer
var _snd_spider: AudioStreamPlayer

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
	_init_sounds()
	$CanvasLayer/HUD/TopBar/RetryButton.pressed.connect(_on_retry)
	$CanvasLayer/HUD/TopBar/MenuButton.pressed.connect(_on_menu)
	$CanvasLayer/WinPanel/VBox/NextButton.pressed.connect(_on_next)
	load_level(current_level)

func _clamp_cam_look_target(target: Vector3) -> Vector3:
	var min_x := CAM_EDGE_PAD_LEFT * CELL
	var max_x := (float(_maze_w) - 1.0 - CAM_EDGE_PAD_RIGHT) * CELL
	var min_z := CAM_EDGE_PAD_TOP * CELL
	var max_z := (float(_maze_h) - 1.0 - CAM_EDGE_PAD_BOTTOM) * CELL
	var pinned_min_z := maxf(min_z, CAM_TOP_FOLLOW_PIN_Z * CELL)

	if max_x < min_x:
		var cx := (float(_maze_w) - 1.0) * CELL * 0.5
		min_x = cx
		max_x = cx
	if max_z < min_z:
		var cz := (float(_maze_h) - 1.0) * CELL * 0.5
		min_z = cz
		max_z = cz
		pinned_min_z = cz
	elif pinned_min_z > max_z:
		pinned_min_z = max_z

	target.x = clampf(target.x, min_x, max_x)
	target.z = clampf(target.z, pinned_min_z, max_z)
	return target

func _init_sounds() -> void:
	var sound_map := {
		"move": "res://assets/sounds/caterpillar_goofy_footsteps.wav",
		"bite": "res://assets/sounds/apple-bite.wav",
		"eat":  "res://assets/sounds/eat_wall.wav",
		"leaf": "res://assets/sounds/leaf_pickup.wav",
		"portal": "res://assets/sounds/portal_enter.wav",
		"spider": "res://assets/sounds/spider_alert.wav",
	}
	for key in sound_map:
		var player := AudioStreamPlayer.new()
		var stream := load(sound_map[key]) as AudioStream
		if stream:
			player.stream = stream
		player.bus = "Master"
		add_child(player)
		set("_snd_" + key, player)
	# Tweak volumes
	_snd_move.volume_db = -10.0
	_snd_bite.volume_db = 0.0
	_snd_eat.volume_db = 2.0
	_snd_leaf.volume_db = 1.0
	_snd_portal.volume_db = 1.0
	_snd_spider.volume_db = 3.0
	if _snd_move and not _snd_move.finished.is_connected(_on_move_sound_finished):
		_snd_move.finished.connect(_on_move_sound_finished)

func _set_move_sound_active(active: bool) -> void:
	_want_move_sound = active
	if active and _snd_move and not _snd_move.playing:
		_snd_move.pitch_scale = 1.0
		_snd_move.play()
	elif not active and _snd_move and _snd_move.playing:
		_snd_move.stop()

func _on_move_sound_finished() -> void:
	if _want_move_sound and _snd_move:
		_snd_move.pitch_scale = 1.0
		_snd_move.play()

func _init_shared_resources() -> void:
	# Hedge shader – lit, lumpy top, gradient with leaf detail
	var hedge_shader := Shader.new()
	hedge_shader.code = "
shader_type spatial;
render_mode blend_mix, depth_draw_opaque, cull_back, diffuse_burley, specular_schlick_ggx;
uniform vec3 color_top : source_color = vec3(0.55, 0.78, 0.15);
uniform vec3 color_bot : source_color = vec3(0.18, 0.45, 0.10);
uniform sampler2D leaf_tex : hint_default_white, filter_linear_mipmap, repeat_enable;
uniform float tex_scale : hint_range(0.1, 8.0) = 2.0;
uniform float tex_influence : hint_range(0.0, 1.0) = 0.6;

varying vec3 v_world_pos;
varying vec3 v_world_normal;
varying float v_height;

float hash3(vec3 p) {
    return fract(sin(dot(p, vec3(127.1, 311.7, 74.7))) * 43758.5453);
}

void vertex() {
    vec3 world = (MODEL_MATRIX * vec4(VERTEX, 1.0)).xyz;
    v_world_pos = world;

    // Rounded-box SDF rounding for edges
    float half_w = 0.5;
    float half_h = 0.425;
    float r = 0.12;

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

    // Lumpy displacement on upper half for organic bush look
    float top_mask = smoothstep(0.15, 0.40, local.y);
    float lump1 = hash3(floor(world * 3.5)) * 0.08;
    float lump2 = hash3(floor(world * 7.0 + vec3(33.0))) * 0.04;
    float lump3 = sin(world.x * 12.0 + world.z * 9.0) * 0.015;
    vec3 bump_dir = normalize(local);
    bump_dir.y = max(bump_dir.y, 0.3);
    bump_dir = normalize(bump_dir);
    local += bump_dir * (lump1 + lump2 + lump3) * top_mask;

    VERTEX = local;
    v_height = local.y;
    v_world_normal = normalize((MODEL_MATRIX * vec4(NORMAL, 0.0)).xyz);
}

void fragment() {
    // Triplanar leaf texture
    vec3 blend_weights = abs(v_world_normal);
    blend_weights = pow(blend_weights, vec3(4.0));
    blend_weights /= (blend_weights.x + blend_weights.y + blend_weights.z);
    vec3 tex_x = texture(leaf_tex, v_world_pos.yz * tex_scale).rgb;
    vec3 tex_y = texture(leaf_tex, v_world_pos.xz * tex_scale).rgb;
    vec3 tex_z = texture(leaf_tex, v_world_pos.xy * tex_scale).rgb;
    vec3 leaf_col = tex_x * blend_weights.x + tex_y * blend_weights.y + tex_z * blend_weights.z;

    // Vertical gradient
    float h = clamp(v_height / 0.85, 0.0, 1.0);
    vec3 base = mix(color_bot, color_top, smoothstep(0.0, 1.0, h));

    // Leaf texture blend
    base = mix(base, base * leaf_col * 1.3, tex_influence);

    // Subtle color variation using world pos hash
    float var1 = hash3(floor(v_world_pos * 2.0)) * 0.08 - 0.04;
    base += vec3(var1 * 0.5, var1, var1 * 0.3);

    // Darken crevices at bottom (gentle)
    float ao = smoothstep(0.0, 0.20, h);
    base *= mix(0.78, 1.0, ao);

    ALBEDO = base;
    ROUGHNESS = 0.75;
    SPECULAR = 0.2;
    // Slight normal perturbation for leafy feel
    float nx = hash3(v_world_pos * 20.0) - 0.5;
    float nz = hash3(v_world_pos * 20.0 + vec3(77.0)) - 0.5;
    NORMAL_MAP = vec3(0.5 + nx * 0.15, 0.5 + nz * 0.15, 1.0);
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
	_bite_count.clear()
	_is_biting = false
	_wall_mm_inst = null
	_lump_mm_inst = null
	_bite_marks.clear()
	_segment_targets.clear()
	_bitten_bush_nodes.clear()
	_bitten_bush_hscale.clear()
	_cell_wall_index.clear()
	_cell_wall_scales.clear()
	_cell_lump_range.clear()
	_segment_target_rots.clear()
	leaves.clear()
	hazards.clear()
	exit_node = null

func load_level(idx: int) -> void:
	_clear()
	current_level = idx % LEVELS.size()
	leaves_left = 0
	_spider_rng.randomize()
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

	# Camera setup – perspective with isometric-like offset
	cam.projection = Camera3D.PROJECTION_PERSPECTIVE
	cam.fov = CAM_FOV
	cam.near = 0.1
	cam.far = 100.0

	# Compute maze center for initial camera placement
	var maze_center := Vector3(
		(float(_maze_w) - 1.0) * CELL * 0.5,
		0.0,
		(float(_maze_h) - 1.0) * CELL * 0.5
	)

	var head_pos := _pos(player_cell)
	_cam_look_target = _clamp_cam_look_target(Vector3(head_pos.x, 0.8, head_pos.z))
	cam.position = _cam_look_target + CAM_OFFSET
	cam.look_at(_cam_look_target, Vector3.UP)
	cam.current = true
	print("Level loaded: %d walls, cam at %s, cam_rot=%s, fov=%.0f" % [wall_set.size(), cam.position, cam.rotation_degrees, cam.fov])

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
	# Bush body boxes with per-cell random height/scale variation
	var mm := MultiMesh.new()
	mm.transform_format = MultiMesh.TRANSFORM_3D
	mm.mesh = _wall_mesh
	mm.instance_count = _wall_cells.size()
	var body_rng := RandomNumberGenerator.new()
	body_rng.seed = 5432
	for i in _wall_cells.size():
		var cell_i := _wall_cells[i]
		var p := _pos(cell_i)
		var h_scale := body_rng.randf_range(0.80, 1.10)
		var w_scale := body_rng.randf_range(0.92, 1.06)
		_cell_wall_index[cell_i] = i
		_cell_wall_scales[cell_i] = Vector2(w_scale, h_scale)
		var t := Transform3D.IDENTITY
		if not _bitten_bush_nodes.has(cell_i):
			t = t.scaled(Vector3(w_scale, h_scale, w_scale))
			t.origin = Vector3(p.x, WALL_HEIGHT * 0.5 * h_scale, p.z)
		else:
			t.origin = Vector3(0.0, -9999.0, 0.0)  # hide: individual node handles this cell
		mm.set_instance_transform(i, t)
	var mm_inst := MultiMeshInstance3D.new()
	mm_inst.multimesh = mm
	mm_inst.material_override = _wall_mat
	mm_inst.cast_shadow = GeometryInstance3D.SHADOW_CASTING_SETTING_ON
	maze_layer.add_child(mm_inst)
	_wall_mm_inst = mm_inst

	# Bush canopy lumps – bigger, more varied clusters
	var lump_mesh := SphereMesh.new()
	lump_mesh.radius = 0.24
	lump_mesh.height = 0.30
	lump_mesh.radial_segments = 10
	lump_mesh.rings = 6

	var lump_mat := ShaderMaterial.new()
	lump_mat.shader = _wall_mat.shader
	lump_mat.set_shader_parameter("color_top", Vector3(BUSH_TOP.r * 1.15, BUSH_TOP.g * 1.1, BUSH_TOP.b * 1.05))
	lump_mat.set_shader_parameter("color_bot", Vector3(BUSH_TOP.r * 0.9, BUSH_TOP.g * 0.9, BUSH_TOP.b * 0.85))
	var leaf_tex := load("res://assets/New/leaf_pattern.png") as Texture2D
	if leaf_tex:
		lump_mat.set_shader_parameter("leaf_tex", leaf_tex)
	lump_mat.set_shader_parameter("tex_scale", 0.6)
	lump_mat.set_shader_parameter("tex_influence", 0.5)

	# Place 3-6 lumps per bush cell, with large variation
	var lump_transforms: Array[Transform3D] = []
	var rng := RandomNumberGenerator.new()
	rng.seed = 9876
	_cell_lump_range.clear()
	for i in _wall_cells.size():
		var lump_cell_i := _wall_cells[i]
		var lp := _pos(lump_cell_i)
		var cell_h := body_rng.randf_range(0.85, 1.25)  # reseeded, but deterministic
		var base_y := WALL_HEIGHT * cell_h
		var n_lumps := rng.randi_range(3, 6)
		var lump_start := lump_transforms.size()
		for _j in n_lumps:
			var ox := rng.randf_range(-0.35, 0.35)
			var oz := rng.randf_range(-0.35, 0.35)
			var oy := rng.randf_range(-0.06, 0.10)
			var s := rng.randf_range(0.5, 1.2)
			var sy := s * rng.randf_range(0.5, 0.9)
			var lt := Transform3D.IDENTITY
			if not _bitten_bush_nodes.has(lump_cell_i):
				lt = lt.scaled(Vector3(s, sy, s))
				lt.origin = Vector3(lp.x + ox, base_y + oy, lp.z + oz)
			else:
				lt.origin = Vector3(0.0, -9999.0, 0.0)  # hide
			lump_transforms.append(lt)
		_cell_lump_range[lump_cell_i] = Vector2i(lump_start, lump_transforms.size())

	var lump_mm := MultiMesh.new()
	lump_mm.transform_format = MultiMesh.TRANSFORM_3D
	lump_mm.mesh = lump_mesh
	lump_mm.instance_count = lump_transforms.size()
	for i in lump_transforms.size():
		lump_mm.set_instance_transform(i, lump_transforms[i])
	var lump_inst := MultiMeshInstance3D.new()
	lump_inst.multimesh = lump_mm
	lump_inst.material_override = lump_mat
	lump_inst.cast_shadow = GeometryInstance3D.SHADOW_CASTING_SETTING_ON
	maze_layer.add_child(lump_inst)
	_lump_mm_inst = lump_inst

func _make_leaf(cell: Vector2i) -> void:
	var node := Node3D.new()
	node.set_script(Leaf3DScript)
	node.position = _pos(cell)
	objects_layer.add_child(node)
	leaves[cell] = node

func _make_spider(cell: Vector2i) -> void:
	var node := Node3D.new()
	node.set_meta("spider_variant", _spider_rng.randi_range(0, 5))
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
	_body_shadow = null
	for i in segment_cells.size():
		var node := Node3D.new()
		node.set_script(Segment3DScript)
		node.set_meta("seg_type", _seg_type(i))
		node.set_meta("seg_index", i)
		node.add_to_group("caterpillar_segment_3d")
		if i == 0:
			node.add_to_group("player_head_3d")
		cat_layer.add_child(node)
		segment_nodes.append(node)
	_update_positions()
	_segment_targets = _calc_positions()
	_update_rotations_instant()
	_segment_target_rots = _calc_target_rotations()
	_update_taper()
	_ensure_body_shadow()
	_update_body_shadow()

func _ensure_body_shadow() -> void:
	if _body_shadow:
		return
	_body_shadow = MeshInstance3D.new()
	var mesh := QuadMesh.new()
	mesh.size = Vector2(1.0, 1.0)
	_body_shadow.mesh = mesh
	_body_shadow.rotation.x = -PI * 0.5  # lay flat on ground
	var shadow_mat := ShaderMaterial.new()
	shadow_mat.render_priority = -1
	var shader := Shader.new()
	shader.code = """
shader_type spatial;
render_mode blend_mix, depth_draw_opaque, cull_disabled, unshaded, shadows_disabled;

uniform float corner_radius = 0.15;

void fragment() {
	// UV 0..1 -> centered -0.5..0.5
	vec2 p = UV - 0.5;
	// Rounded rectangle SDF
	vec2 d = abs(p) - (vec2(0.5) - vec2(corner_radius));
	float sdf = length(max(d, vec2(0.0))) + min(max(d.x, d.y), 0.0) - corner_radius;
	// Soft edge falloff
	float alpha = 1.0 - smoothstep(-0.06, 0.02, sdf);
	// Fade at edges for natural look
	alpha *= 0.16;
	ALBEDO = vec3(0.0);
	ALPHA = alpha;
}
"""
	shadow_mat.shader = shader
	_body_shadow.material_override = shadow_mat
	_body_shadow.cast_shadow = GeometryInstance3D.SHADOW_CASTING_SETTING_OFF
	cat_layer.add_child(_body_shadow)

func _update_body_shadow() -> void:
	if not _body_shadow:
		return
	if segment_nodes.is_empty():
		_body_shadow.visible = false
		return
	_body_shadow.visible = true
	var center := Vector3.ZERO
	for segment in segment_nodes:
		center += segment.position
	center /= float(segment_nodes.size())
	var head_pos := segment_nodes[0].position
	var tail_pos := segment_nodes[-1].position
	var spine := head_pos - tail_pos
	var length := maxf(spine.length() + 0.8, 2.0)
	var width := 0.75
	var yaw := atan2(spine.x, spine.z)
	_body_shadow.position = Vector3(center.x, 0.03, center.z)
	# Quad is rotated flat (-90 on X), so we scale X=width, Y=length
	_body_shadow.rotation = Vector3(-PI * 0.5, 0.0, -yaw)
	_body_shadow.scale = Vector3(width, length, 1.0)

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

func _seg_dir(i: int) -> Vector2i:
	## Return the direction segment i should face.
	## Falls back to the segment ahead or `facing` when cells overlap.
	if i == 0:
		return facing
	var dir := segment_cells[i - 1] - segment_cells[i]
	if dir != Vector2i.ZERO:
		return dir
	# Overlapping cells – inherit direction from the segment ahead
	for j in range(i - 1, -1, -1):
		var d: Vector2i
		if j == 0:
			d = facing
		else:
			d = segment_cells[j - 1] - segment_cells[j]
		if d != Vector2i.ZERO:
			return d
	return facing

func _yaw_from_path_tangent(tangent: Vector3) -> float:
	if tangent.length_squared() <= 0.000001:
		return _dir_angle_y(facing)
	return atan2(-tangent.x, -tangent.z)

func _calc_target_rotations(positions: Array[Vector3] = []) -> Array[float]:
	var path_positions := positions
	if path_positions.is_empty():
		path_positions = _calc_positions()
	var rots: Array[float] = []
	for i in path_positions.size():
		if i == 0:
			rots.append(_dir_angle_y(facing))
			continue

		var tangent := Vector3.ZERO
		if i < path_positions.size() - 1:
			tangent = path_positions[i - 1] - path_positions[i + 1]
		if tangent.length_squared() <= 0.000001:
			tangent = path_positions[i - 1] - path_positions[i]

		rots.append(_yaw_from_path_tangent(tangent))
	return rots

func _update_rotations_instant() -> void:
	var positions := _calc_positions()
	var target_rots := _calc_target_rotations(positions)
	for i in segment_nodes.size():
		if i < target_rots.size():
			segment_nodes[i].rotation.y = target_rots[i]
		var dir := _seg_dir(i)
		var is_horizontal := (dir == Vector2i.LEFT or dir == Vector2i.RIGHT)
		segment_nodes[i].update_direction(is_horizontal)

func _update_taper() -> void:
	var n := segment_nodes.size()
	for i in n:
		var s := 1.0
		if i == 0:
			s = 1.0
		elif i == n - 1:
			s = 0.7
		else:
			s = 1.0
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
	elif event is InputEventKey and event.keycode == KEY_SPACE and event.pressed and not event.echo:
		_start_bite()

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

	# ── Bush biting ──
	_process_bite(delta)

	# ── Debug camera controls ──
	# ROTATION:  Q/E = tilt (X), Z/C = yaw (Y), R/T = roll (Z)
	# POSITION:  I/K = forward/back, J/L = left/right, U/O = up/down
	# ZOOM:      N/M = zoom out/in (ortho size)
	# PRINT:     P = print all camera values
	# Hold Shift for finer control
	var rot_speed := 30.0 * delta
	var move_speed := 10.0 * delta
	var zoom_speed := 5.0 * delta
	if Input.is_key_pressed(KEY_SHIFT):
		rot_speed *= 0.2
		move_speed *= 0.2
		zoom_speed *= 0.2
	# Rotation
	if Input.is_key_pressed(KEY_Q):
		cam.rotation_degrees.x -= rot_speed
	if Input.is_key_pressed(KEY_E):
		cam.rotation_degrees.x += rot_speed
	if Input.is_key_pressed(KEY_Z):
		cam.rotation_degrees.y -= rot_speed
	if Input.is_key_pressed(KEY_C):
		cam.rotation_degrees.y += rot_speed
	if Input.is_key_pressed(KEY_R):
		cam.rotation_degrees.z -= rot_speed
	if Input.is_key_pressed(KEY_T):
		cam.rotation_degrees.z += rot_speed
	# Position
	if Input.is_key_pressed(KEY_J):
		cam.position.x -= move_speed
	if Input.is_key_pressed(KEY_L):
		cam.position.x += move_speed
	if Input.is_key_pressed(KEY_I):
		cam.position.z -= move_speed
	if Input.is_key_pressed(KEY_K):
		cam.position.z += move_speed
	if Input.is_key_pressed(KEY_U):
		cam.position.y += move_speed
	if Input.is_key_pressed(KEY_O):
		cam.position.y -= move_speed
	# Zoom (FOV)
	if Input.is_key_pressed(KEY_N):
		cam.fov = minf(cam.fov + zoom_speed * 5.0, 90.0)
	if Input.is_key_pressed(KEY_M):
		cam.fov = maxf(cam.fov - zoom_speed * 5.0, 10.0)
	# Print
	if Input.is_key_pressed(KEY_P):
		if not _p_was_pressed:
			print(">>> CAM rotation=%s  position=%s  fov=%.1f" % [cam.rotation_degrees, cam.position, cam.fov])
		_p_was_pressed = true
	else:
		_p_was_pressed = false

	# Smooth camera follow – lerp look target, recompute position + look_at
	var new_look := _clamp_cam_look_target(_cam_look_target)
	var current_look := cam.position - CAM_OFFSET
	current_look = current_look.lerp(new_look, minf(delta * 12.0, 1.0))
	cam.position = current_look + CAM_OFFSET
	cam.look_at(current_look, Vector3.UP)

	# Smooth segment interpolation
	var lerp_speed: float
	if _is_reversing:
		lerp_speed = minf(delta * 5.0, 1.0)
	else:
		lerp_speed = minf(delta * 8.0, 1.0)
	var crawl_alpha := 0.0
	if _move_anim_remaining > 0.0:
		_crawl_motion_time += delta * (5.0 if _is_reversing else 7.0)
		var anim_duration := REVERSE_MOVE_DURATION if _is_reversing else FORWARD_MOVE_DURATION
		crawl_alpha = sin(clampf((1.0 - (_move_anim_remaining / anim_duration)) * PI, 0.0, PI))
	for i in segment_nodes.size():
		if i < _segment_targets.size():
			var target_pos := _segment_targets[i]
			if crawl_alpha > 0.0:
				var phase := _crawl_motion_time - float(i) * 0.85
				var amp := 0.13 if i > 0 and i < segment_nodes.size() - 1 else 0.08
				target_pos.y += sin(phase) * amp * crawl_alpha
			segment_nodes[i].position = segment_nodes[i].position.lerp(target_pos, lerp_speed)
	var live_positions: Array[Vector3] = []
	for segment in segment_nodes:
		live_positions.append(segment.position)
	var live_rots := _calc_target_rotations(live_positions)
	for i in segment_nodes.size():
		if i < live_rots.size():
			segment_nodes[i].rotation.y = lerp_angle(segment_nodes[i].rotation.y, live_rots[i], lerp_speed)
	_update_body_shadow()

	if _move_anim_remaining > 0.0:
		_move_anim_remaining = maxf(_move_anim_remaining - delta, 0.0)
		if _move_anim_remaining <= 0.0:
			if _allow_busy_release:
				is_busy = false

	if _move_anim_remaining <= 0.0 and (not is_busy or not _allow_busy_release):
		_set_move_sound_active(false)

	# Keep bite mood authoritative: no idle look/sleep while chewing/biting.
	if _is_biting:
		_idle_timer = 0.0
		if _is_looking_at_camera:
			_is_looking_at_camera = false
			if segment_nodes.size() > 0 and segment_nodes[0].has_method("set_idle"):
				segment_nodes[0].set_idle(false)

	# ── Idle detection: tell head segment it's idle ──
	if not _is_biting:
		_idle_timer += delta
		if _idle_timer >= IDLE_LOOK_DELAY and not _is_looking_at_camera:
			_is_looking_at_camera = true
			if segment_nodes.size() > 0 and segment_nodes[0].has_method("set_idle"):
				segment_nodes[0].set_idle(true)

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
		if not _allow_busy_release:
			return
		# Allow smooth continuous crawling only when continuing forward in the same direction.
		if _move_anim_remaining > 0.0 and (_is_reversing or dir != facing):
			return
	# Reset idle on any movement
	_idle_timer = 0.0
	if _is_looking_at_camera:
		_is_looking_at_camera = false
		if segment_nodes.size() > 0 and segment_nodes[0].has_method("set_idle"):
			segment_nodes[0].set_idle(false)
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
	_allow_busy_release = true
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
	_cam_look_target = _clamp_cam_look_target(Vector3(head3.x, 0.8, head3.z))

	# When reversing, the tail is the leading end — check it for pickups/hazards
	var lead_cell := new_tail
	if leaves.has(lead_cell):
		leaves[lead_cell].queue_free()
		leaves.erase(lead_cell)
		leaves_left -= 1
		if segment_nodes.size() > 0 and segment_nodes[0].has_method("set_expression"):
			segment_nodes[0].set_expression("happy", 1.2)
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
		sn.wiggle_legs(0.65)
	_move_anim_remaining = REVERSE_MOVE_DURATION
	_set_move_sound_active(true)

	if hazards.has(lead_cell):
		_allow_busy_release = false
		await _lose()
		return
	if leaves_left <= 0 and exit_node:
		exit_node.set_meta("open", true)
	if lead_cell == exit_cell and leaves_left <= 0:
		_allow_busy_release = false
		await _win()
		return

	_update_hud()

func _move_to(target: Vector2i) -> void:
	is_busy = true
	_allow_busy_release = true
	_move_count += 1
	var prev := segment_cells.duplicate()
	segment_cells[0] = target
	for i in range(1, segment_cells.size()):
		segment_cells[i] = prev[i - 1]

	_segment_targets = _calc_positions()
	_segment_target_rots = _calc_target_rotations()
	var tgt3 := _pos(target)
	_cam_look_target = _clamp_cam_look_target(Vector3(tgt3.x, 0.8, tgt3.z))

	# Collect leaf
	if leaves.has(target):
		leaves[target].queue_free()
		leaves.erase(target)
		leaves_left -= 1
		# Happy sparkle leaf sound
		if _snd_leaf:
			_snd_leaf.pitch_scale = randf_range(0.9, 1.15)
			_snd_leaf.play()
		if segment_nodes.size() > 0 and segment_nodes[0].has_method("set_expression"):
			segment_nodes[0].set_expression("happy", 1.2)
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
		n.wiggle_legs(1.0)
	_move_anim_remaining = FORWARD_MOVE_DURATION
	_set_move_sound_active(true)

	if hazards.has(target):
		_allow_busy_release = false
		if _snd_spider:
			_snd_spider.play()
		await _lose()
		return
	if leaves_left <= 0 and exit_node:
		exit_node.set_meta("open", true)
	if target == exit_cell and leaves_left <= 0:
		_allow_busy_release = false
		if _snd_portal:
			_snd_portal.play()
		await _win()
		return

	_update_hud()

func _bump() -> void:
	pass

# ── Bush biting ──

func _start_bite() -> void:
	if _is_biting or is_busy:
		return
	# Check if there's a wall in front of the head
	var target_cell := segment_cells[0] + facing
	if not wall_set.has(target_cell):
		return
	# Can't bite border walls (edges of the maze)
	if target_cell.x <= 0 or target_cell.x >= _maze_w - 1:
		return
	if target_cell.y <= 0 or target_cell.y >= _maze_h - 1:
		return
	_bite_target = target_cell
	_is_biting = true
	_bite_timer = BITE_DURATION
	_bite_face_loop_timer = BITE_FACE_LOOP_INTERVAL
	_bite_face_is_biting = true
	is_busy = true

	# Apply the bite immediately on press, then keep chewing animation/sound.
	if not _bite_count.has(_bite_target):
		_bite_count[_bite_target] = 0
	_bite_count[_bite_target] += 1
	_apply_bush_bite_visual(_bite_target, _bite_count[_bite_target])
	if _bite_count[_bite_target] >= BITES_TO_EAT:
		if _snd_eat:
			_snd_eat.play()
		_eat_wall(_bite_target)
		_bite_count.erase(_bite_target)

	# Chomp! – play the full bite.wav (pitch fixed so duration stays ~6 s)
	if _snd_bite:
		_snd_bite.pitch_scale = 1.0
		_snd_bite.play()
	# Start with biting, then alternate biting/chewing until bite ends.
	if segment_nodes.size() > 0 and segment_nodes[0].has_method("set_expression"):
		segment_nodes[0].set_expression("biting", BITE_FACE_LOOP_INTERVAL)

func _process_bite(delta: float) -> void:
	if not _is_biting:
		return
	_bite_face_loop_timer -= delta
	if _bite_face_loop_timer <= 0.0:
		_bite_face_loop_timer += BITE_FACE_LOOP_INTERVAL
		_bite_face_is_biting = not _bite_face_is_biting
		if segment_nodes.size() > 0 and segment_nodes[0].has_method("set_expression"):
			segment_nodes[0].set_expression("biting" if _bite_face_is_biting else "chewing", BITE_FACE_LOOP_INTERVAL)
	_bite_timer -= delta
	# Head wiggle while biting
	if segment_nodes.size() > 0:
		var wiggle := sin(_bite_timer * 18.0) * 0.008
		segment_nodes[0].position.x += wiggle
	if _bite_timer <= 0.0:
		_finish_bite()

func _finish_bite() -> void:
	_is_biting = false
	_bite_face_loop_timer = 0.0
	_bite_face_is_biting = true
	if segment_nodes.size() > 0 and segment_nodes[0].has_method("set_expression"):
		segment_nodes[0].set_expression("happy", 0.6)
	is_busy = false

func _ensure_bite_cavity_material() -> StandardMaterial3D:
	if _bite_cavity_mat:
		return _bite_cavity_mat
	var mat := StandardMaterial3D.new()
	mat.albedo_color = Color(0.30, 0.19, 0.10)
	mat.roughness = 0.96
	mat.specular = 0.02
	_bite_cavity_mat = mat
	return _bite_cavity_mat

func _make_bitten_bush(cell: Vector2i) -> Node3D:
	var wall_pos := _pos(cell)
	var scales: Vector2 = _cell_wall_scales.get(cell, Vector2(1.0, 1.0))
	var root := CSGCombiner3D.new()
	root.position = Vector3(wall_pos.x, WALL_HEIGHT * 0.5 * scales.y, wall_pos.z)
	root.scale = Vector3(scales.x, scales.y, scales.x)
	root.use_collision = false

	var body := CSGBox3D.new()
	body.size = Vector3(CELL, WALL_HEIGHT, CELL)
	body.material = _wall_mat
	root.add_child(body)

	var rng := RandomNumberGenerator.new()
	rng.seed = cell.x * 2003 + cell.y * 917
	var top_lumps := rng.randi_range(3, 5)
	for _i in top_lumps:
		var lump := CSGSphere3D.new()
		lump.radius = rng.randf_range(0.16, 0.24)
		lump.material = _wall_mat
		lump.position = Vector3(
			rng.randf_range(-0.28, 0.28),
			WALL_HEIGHT * 0.42 + rng.randf_range(-0.05, 0.10),
			rng.randf_range(-0.28, 0.28))
		lump.scale = Vector3(
			rng.randf_range(0.9, 1.2),
			rng.randf_range(0.75, 1.05),
			rng.randf_range(0.9, 1.2))
		root.add_child(lump)

	maze_layer.add_child(root)
	return root


func _add_bite_cut_sphere(parent: Node3D, cut_pos: Vector3, radius: float, scale_vec: Vector3) -> void:
	var cut := CSGSphere3D.new()
	cut.operation = CSGShape3D.OPERATION_SUBTRACTION
	cut.radius = radius
	cut.position = cut_pos
	cut.scale = scale_vec
	cut.material = _ensure_bite_cavity_material()
	parent.add_child(cut)

func _add_bite_cutout(bush_root: Node3D, dir_to_head: Vector3, side_dir: Vector3, bite_num: int, cell: Vector2i) -> void:
	var rng := RandomNumberGenerator.new()
	rng.seed = cell.x * 1013 + cell.y * 379 + bite_num * 53
	var base_forward := 0.34 - float(bite_num - 1) * 0.03
	var base_center := dir_to_head * base_forward + Vector3(0.0, 0.16 - float(bite_num - 1) * 0.01, 0.0)
	base_center += side_dir * rng.randf_range(-0.03, 0.03)

	# Large 3-circle "apple bite" silhouette. One stage should read as roughly one third removed.
	var stage_scale := 1.0 + float(bite_num - 1) * 0.22
	_add_bite_cut_sphere(
		bush_root,
		base_center + side_dir * -0.15 + Vector3(0.0, 0.10, 0.0),
		0.23 * stage_scale,
		Vector3(1.18, 1.02, 1.30))
	_add_bite_cut_sphere(
		bush_root,
		base_center + side_dir * 0.15 + Vector3(0.0, 0.10, 0.0),
		0.23 * stage_scale,
		Vector3(1.18, 1.02, 1.30))
	_add_bite_cut_sphere(
		bush_root,
		base_center + Vector3(0.0, -0.05, 0.0),
		0.28 * stage_scale,
		Vector3(1.22, 0.98, 1.38))

	# Extra interior scoop makes the bite look deeper and more visible from the camera.
	_add_bite_cut_sphere(
		bush_root,
		base_center - dir_to_head * (0.03 + float(bite_num - 1) * 0.02) + Vector3(0.0, 0.02, 0.0),
		0.20 * stage_scale,
		Vector3(0.95, 0.85, 1.35))

	# Slight irregularity so it is not a perfect cookie-cutter bite.
	var jag_count := 2 + bite_num
	for _i in jag_count:
		_add_bite_cut_sphere(
			bush_root,
			base_center \
				+ side_dir * rng.randf_range(-0.18, 0.18) \
				+ Vector3(0.0, rng.randf_range(-0.10, 0.12), 0.0) \
				+ dir_to_head * rng.randf_range(-0.02, 0.08),
			rng.randf_range(0.05, 0.09) * stage_scale,
			Vector3(
				rng.randf_range(0.8, 1.25),
				rng.randf_range(0.75, 1.10),
				rng.randf_range(0.9, 1.35)))

func _apply_bush_bite_visual(cell: Vector2i, bite_num: int) -> void:
	var old_bush: Node3D = _bitten_bush_nodes.get(cell)
	var head_pos := _pos(segment_cells[0])
	var dir_to_head := (head_pos - _pos(cell)).normalized()
	var side_dir := Vector3(-dir_to_head.z, 0.0, dir_to_head.x)

	# First bite: detach cell from MultiMesh, spawn a standalone bush we can carve.
	if bite_num == 1 and not _bitten_bush_nodes.has(cell):
		var wall_idx: int = _cell_wall_index.get(cell, -1)
		if wall_idx >= 0 and _wall_mm_inst and _wall_mm_inst.multimesh:
			_wall_mm_inst.multimesh.set_instance_transform(wall_idx,
				Transform3D(Basis.IDENTITY, Vector3(0.0, -9999.0, 0.0)))
		if _cell_lump_range.has(cell) and _lump_mm_inst and _lump_mm_inst.multimesh:
			var lr: Vector2i = _cell_lump_range[cell]
			for li in range(lr.x, lr.y):
				_lump_mm_inst.multimesh.set_instance_transform(li,
					Transform3D(Basis.IDENTITY, Vector3(0.0, -9999.0, 0.0)))
		_bitten_bush_hscale[cell] = _cell_wall_scales.get(cell, Vector2(1.0, 1.0)).y

	if old_bush and is_instance_valid(old_bush):
		old_bush.queue_free()

	var bush_node := _make_bitten_bush(cell)
	_bitten_bush_nodes[cell] = bush_node
	for stage in range(1, bite_num + 1):
		_add_bite_cutout(bush_node, dir_to_head, side_dir, stage, cell)

func _eat_wall(cell: Vector2i) -> void:
	# Remove from game logic
	wall_set.erase(cell)
	_wall_cells.erase(cell)
	# Remove old multimesh instances and rebuild without this cell
	if _wall_mm_inst:
		_wall_mm_inst.queue_free()
		_wall_mm_inst = null
	if _lump_mm_inst:
		_lump_mm_inst.queue_free()
		_lump_mm_inst = null
	# Remove the standalone bitten bush completely once eaten.
	var bush_node: Node3D = _bitten_bush_nodes.get(cell)
	if bush_node and is_instance_valid(bush_node):
		bush_node.queue_free()
	_bitten_bush_nodes.erase(cell)
	_bitten_bush_hscale.erase(cell)
	# Legacy bite-mark nodes are no longer used for the primary effect.
	_bite_marks.clear()
	# Rebuild wall meshes
	_build_wall_multimesh()
	# Happy munch expression
	if segment_nodes.size() > 0 and segment_nodes[0].has_method("set_expression"):
		segment_nodes[0].set_expression("biting", 1.5)

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
