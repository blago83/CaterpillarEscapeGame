extends Node3D

const CELL := 1.0
const WALL_HEIGHT := 0.8
const CAM_HEIGHT := 20.0
const GROUND_COLOR := Color(0.76, 0.70, 0.50)
const WALL_COLOR := Color(0.55, 0.38, 0.22)

const Segment3DScript := preload("res://scripts/segment_3d.gd")
const Leaf3DScript := preload("res://scripts/leaf_3d.gd")
const Spider3DScript := preload("res://scripts/spider_3d.gd")
const Exit3DScript := preload("res://scripts/exit_portal_3d.gd")

# Large mazes with consistent rectangular bounds.
# Legend: # wall, . path, P player, L leaf, S spider, E exit
const LEVELS := [
[
"#######################",
"#P....#.....#.....#...#",
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
"#...#.#...S...#.....E##",
"#######################",
],
[
"###########################",
"#P....#.......#.....#.....#",
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
"#...#..............L...E..#",
"###########################",
],
[
"###############################",
"#P....#.......#.......#.......#",
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
"#....S....L.....#.......L...E.#",
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
var _move_progress: float = 1.0
var leaves: Dictionary = {}
var hazards: Dictionary = {}
var exit_cell: Vector2i = Vector2i.ZERO
var exit_node: Node3D = null
var leaves_left: int = 0
var is_busy: bool = false
var swipe_start := Vector2.ZERO
var move_timer: float = 0.0
const MOVE_REPEAT_DELAY := 0.15

var _maze_w: int = 0
var _maze_h: int = 0

# Shared resources for performance
var _wall_mat: StandardMaterial3D
var _wall_mesh: BoxMesh
var _ground_mat: StandardMaterial3D
var _cam_target := Vector3.ZERO
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
	RenderingServer.set_default_clear_color(Color(0.35, 0.55, 0.25))
	_init_shared_resources()
	_setup_lighting()
	$CanvasLayer/HUD/TopBar/RetryButton.pressed.connect(_on_retry)
	$CanvasLayer/HUD/TopBar/MenuButton.pressed.connect(_on_menu)
	$CanvasLayer/WinPanel/VBox/NextButton.pressed.connect(_on_next)
	load_level(current_level)

func _init_shared_resources() -> void:
	_wall_mat = StandardMaterial3D.new()
	_wall_mat.albedo_color = WALL_COLOR
	_wall_mesh = BoxMesh.new()
	_wall_mesh.size = Vector3(CELL * 0.95, WALL_HEIGHT, CELL * 0.95)
	_ground_mat = StandardMaterial3D.new()
	_ground_mat.albedo_color = GROUND_COLOR

func _setup_lighting() -> void:
	# Directional light with shadows
	var light := DirectionalLight3D.new()
	light.rotation_degrees = Vector3(-50, -30, 0)
	light.shadow_enabled = true
	light.light_energy = 1.2
	light.light_color = Color(1.0, 0.95, 0.88)
	add_child(light)

	# World environment
	var world_env := WorldEnvironment.new()
	var env := Environment.new()
	env.background_mode = Environment.BG_COLOR
	env.background_color = Color(0.4, 0.6, 0.3)
	env.ambient_light_source = Environment.AMBIENT_SOURCE_COLOR
	env.ambient_light_color = Color(0.5, 0.52, 0.45)
	env.ambient_light_energy = 0.8
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

	# Camera setup – perspective, tilted slightly down for 3D look
	cam.projection = Camera3D.PROJECTION_PERSPECTIVE
	cam.fov = 35.0
	cam.near = 0.1
	cam.far = 100.0
	cam.rotation_degrees = Vector3(-65, 0, 0)
	var head_pos := _pos(player_cell)
	var cam_offset_z := CAM_HEIGHT * tan(deg_to_rad(25.0))  # offset back to keep player centered
	_cam_target = Vector3(head_pos.x, CAM_HEIGHT, head_pos.z + cam_offset_z)
	cam.position = _cam_target
	cam.current = true
	print("Level loaded: %d walls, cam at %s" % [wall_set.size(), cam.position])

	# Caterpillar – trail segments along valid path cells
	segment_cells = [player_cell]
	for i in range(1, 3):
		var placed := false
		for d in [Vector2i.DOWN, Vector2i.RIGHT, Vector2i.UP, Vector2i.LEFT]:
			var candidate: Vector2i = segment_cells[-1] + d
			if not wall_set.has(candidate) and not segment_cells.has(candidate):
				segment_cells.append(candidate)
				placed = true
				break
		if not placed:
			segment_cells.append(segment_cells[-1])
	_rebuild_caterpillar()
	_update_hud()
	win_panel.visible = false
	is_busy = false

func _create_ground(w: int, h: int) -> void:
	var mesh_inst := MeshInstance3D.new()
	var plane := PlaneMesh.new()
	plane.size = Vector2(float(w) * CELL, float(h) * CELL)
	mesh_inst.mesh = plane
	mesh_inst.material_override = _ground_mat
	mesh_inst.position = Vector3(
		(float(w) - 1.0) * CELL * 0.5,
		-0.01,
		(float(h) - 1.0) * CELL * 0.5
	)
	maze_layer.add_child(mesh_inst)

# ── Entity factories ──

func _build_wall_multimesh() -> void:
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
	_move_progress = 1.0
	_update_taper()

func _calc_positions() -> Array[Vector3]:
	var spacing := CELL * 0.55
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

	# Smooth segment interpolation with staggered follow
	_move_progress = minf(_move_progress + delta * 8.0, 1.0)
	for i in segment_nodes.size():
		# Stagger: each segment is slightly behind the previous one
		var seg_t := clampf(_move_progress - float(i) * 0.08, 0.0, 1.0)
		var smooth_t := seg_t * seg_t * (3.0 - 2.0 * seg_t)  # smoothstep
		if i < _segment_targets.size():
			segment_nodes[i].position = segment_nodes[i].position.lerp(_segment_targets[i], minf(smooth_t * 0.5 + delta * 10.0, 1.0))
		if i < _segment_target_rots.size():
			segment_nodes[i].rotation.y = lerp_angle(segment_nodes[i].rotation.y, _segment_target_rots[i], minf(smooth_t * 0.5 + delta * 10.0, 1.0))

	var dir := _get_held_dir()
	if dir == Vector2i.ZERO:
		move_timer = 0.0
		return
	move_timer += delta
	if move_timer >= MOVE_REPEAT_DELAY:
		move_timer -= MOVE_REPEAT_DELAY
		_try_move(dir)

# ── Movement ──

func _try_move(dir: Vector2i) -> void:
	if is_busy:
		return
	var reverse_dir := -facing
	if dir == reverse_dir:
		_move_backward()
		return
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
	is_busy = true
	_move_count += 1
	var prev := segment_cells.duplicate()
	var tail_dir: Vector2i
	if prev.size() > 1:
		tail_dir = prev[-1] - prev[-2]
	else:
		tail_dir = -facing
	var new_tail: Vector2i = prev[-1] + tail_dir
	if wall_set.has(new_tail):
		is_busy = false
		_bump()
		return
	for i in range(0, segment_cells.size() - 1):
		segment_cells[i] = prev[i + 1]
	segment_cells[-1] = new_tail

	_segment_targets = _calc_positions()
	_segment_target_rots = _calc_target_rotations()
	_move_progress = 0.0
	var head3 := _pos(segment_cells[0])
	var cam_offset_z := CAM_HEIGHT * tan(deg_to_rad(25.0))
	_cam_target = Vector3(head3.x, CAM_HEIGHT, head3.z + cam_offset_z)

	# Check for leaf at new head position
	var head_cell := segment_cells[0]
	if leaves.has(head_cell):
		leaves[head_cell].queue_free()
		leaves.erase(head_cell)
		leaves_left -= 1
		var extra_cell: Vector2i = new_tail + tail_dir
		segment_cells.append(extra_cell)
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

	if hazards.has(head_cell):
		await _lose()
		return
	if leaves_left <= 0 and exit_node:
		exit_node.set_meta("open", true)
	if head_cell == exit_cell and leaves_left <= 0:
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
	_move_progress = 0.0
	var tgt3 := _pos(target)
	var cam_offset_z := CAM_HEIGHT * tan(deg_to_rad(25.0))
	_cam_target = Vector3(tgt3.x, CAM_HEIGHT, tgt3.z + cam_offset_z)

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
