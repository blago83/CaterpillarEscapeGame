extends Node2D

const CELL := 64
const GROUND_COLOR := Color(0.55, 0.78, 0.35)

const SegmentScript := preload("res://scripts/segment.gd")
const LeafScript := preload("res://scripts/leaf.gd")
const SpiderScript := preload("res://scripts/spider.gd")
const ExitScript := preload("res://scripts/exit_portal.gd")
const WallScript := preload("res://scripts/wall_tile.gd")

# Horizontal piece textures – placed as full sprites along runs
var _h_textures: Array[Texture2D] = [
	preload("res://assets/tiles/horizontal.png"),
	preload("res://assets/tiles/horizontal_2.png"),
	preload("res://assets/tiles/horizontal_3.png"),
]

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
var segment_nodes: Array[Node2D] = []
var leaves: Dictionary = {}
var hazards: Dictionary = {}
var exit_cell: Vector2i = Vector2i.ZERO
var exit_node: Node2D = null
var leaves_left: int = 0
var is_busy: bool = false
var swipe_start := Vector2.ZERO
var move_timer: float = 0.0
const MOVE_REPEAT_DELAY := 0.15

@onready var cam: Camera2D = $Camera2D
@onready var maze_layer: Node2D = $MazeLayer
@onready var objects_layer: Node2D = $ObjectsLayer
@onready var cat_layer: Node2D = $CaterpillarLayer
@onready var hud_label: Label = $CanvasLayer/HUD/TopBar/InfoLabel
@onready var win_panel: ColorRect = $CanvasLayer/WinPanel

func _ready() -> void:
	RenderingServer.set_default_clear_color(Color(0.12, 0.22, 0.08))
	$CanvasLayer/HUD/TopBar/RetryButton.pressed.connect(_on_retry)
	$CanvasLayer/HUD/TopBar/MenuButton.pressed.connect(_on_menu)
	$CanvasLayer/WinPanel/VBox/NextButton.pressed.connect(_on_next)
	load_level(current_level)

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
	leaves.clear()
	hazards.clear()
	exit_node = null

func load_level(idx: int) -> void:
	_clear()
	current_level = idx % LEVELS.size()
	leaves_left = 0
	var rows: Array = LEVELS[current_level]

	# Tiled background pattern (scaled down for smaller tile repeat)
	var maze_h: int = rows.size()
	var maze_w: int = 0
	for row in rows:
		maze_w = max(maze_w, row.length())
	var bg_tex := preload("res://assets/background_sand.png")
	var tile_scale := 0.25
	var bg := TextureRect.new()
	bg.texture = bg_tex
	bg.stretch_mode = TextureRect.STRETCH_TILE
	bg.position = Vector2.ZERO
	bg.size = Vector2(maze_w * CELL / tile_scale, maze_h * CELL / tile_scale)
	bg.scale = Vector2(tile_scale, tile_scale)
	maze_layer.add_child(bg)

	# Pass 1: collect wall positions
	for y in rows.size():
		var row: String = rows[y]
		for x in row.length():
			if row[x] == "#":
				wall_set[Vector2i(x, y)] = true

	# Pass 2a: place horizontal runs as full piece sprites
	for y in rows.size():
		var row: String = rows[y]
		var run_start := -1
		for x in range(row.length() + 1):
			var is_wall := x < row.length() and row[x] == "#"
			var cell := Vector2i(x, y)
			var in_h_run := false
			if is_wall:
				in_h_run = wall_set.has(cell + Vector2i.LEFT) or wall_set.has(cell + Vector2i.RIGHT)
			if in_h_run and run_start == -1:
				run_start = x
			elif not in_h_run and run_start != -1:
				_place_h_run(y, run_start, x - 1)
				run_start = -1

	# Pass 2b: create wall nodes for vertical and isolated cells
	for y in rows.size():
		var row: String = rows[y]
		for x in row.length():
			if row[x] == "#":
				var cell := Vector2i(x, y)
				var has_t := wall_set.has(cell + Vector2i.UP)
				var has_b := wall_set.has(cell + Vector2i.DOWN)
				var has_l := wall_set.has(cell + Vector2i.LEFT)
				var has_r := wall_set.has(cell + Vector2i.RIGHT)
				if (has_t or has_b) and not (has_l or has_r):
					_make_wall_vert(cell)
				elif not has_t and not has_b and not has_l and not has_r:
					_make_wall_center(cell)

	# Pass 3: non-wall entities
	for y in rows.size():
		var row: String = rows[y]
		for x in row.length():
			var ch := row[x]
			var cell := Vector2i(x, y)
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

	# Camera limits – keep view inside the maze
	cam.limit_left = 0
	cam.limit_top = 0
	cam.limit_right = maze_w * CELL
	cam.limit_bottom = maze_h * CELL

	# Caterpillar (3 segments trailing down from start)
	segment_cells = [player_cell]
	for i in range(1, 3):
		segment_cells.append(player_cell + Vector2i.DOWN * i)
	_rebuild_caterpillar()
	_update_hud()
	cam.position = _pos(player_cell)
	win_panel.visible = false
	is_busy = false

func _pos(cell: Vector2i) -> Vector2:
	return Vector2(cell.x * CELL + CELL * 0.5, cell.y * CELL + CELL * 0.5)

# ── Entity factories ──

## Place full horizontal piece sprites along a run, never cutting any texture.
## Pieces are scaled to exactly fill the run width with no overlap or overshoot.
func _place_h_run(row: int, start_x: int, end_x: int) -> void:
	var run_start_px := float(start_x) * CELL
	var run_end_px := float(end_x + 1) * CELL
	var run_width := run_end_px - run_start_px
	var h := float(CELL)  # piece height = cell height, no overshoot

	# First pass: compute natural widths and total to find scale factor
	var natural_widths: Array[float] = []
	var total_natural := 0.0
	var idx := 0
	var tmp_w := 0.0
	while tmp_w < run_width - 0.1:
		var tex: Texture2D = _h_textures[idx % _h_textures.size()]
		var ratio := float(tex.get_width()) / float(tex.get_height())
		var w := h * ratio
		# Don't overshoot: if this piece would go past the end, stop
		if tmp_w + w > run_width + w * 0.5:
			break
		natural_widths.append(w)
		total_natural += w
		tmp_w += w
		idx += 1

	# If no pieces fit (very short run), place one piece scaled to run width
	if natural_widths.size() == 0:
		var tex: Texture2D = _h_textures[0]
		natural_widths.append(run_width)
		total_natural = run_width

	# Scale factor so pieces fill the run with slight overlap to close gaps
	var h_overlap := 4.0  # px overlap between adjacent pieces
	var total_with_overlap := total_natural - h_overlap * (natural_widths.size() - 1)
	var scale_factor := run_width / total_with_overlap if total_with_overlap > 0.0 else 1.0

	# Second pass: place pieces
	var px := run_start_px
	for i in natural_widths.size():
		var tex: Texture2D = _h_textures[i % _h_textures.size()]
		var w := natural_widths[i] * scale_factor

		var sprite := Sprite2D.new()
		sprite.texture = tex
		sprite.position = Vector2(px + w * 0.5, float(row) * CELL + CELL * 0.5)
		sprite.scale = Vector2(w / float(tex.get_width()), h / float(tex.get_height()))
		sprite.z_index = row
		maze_layer.add_child(sprite)

		px += w - 4.0  # slight overlap to close gaps

## Spawn a wall node that draws only a vertical piece.
func _make_wall_vert(cell: Vector2i) -> void:
	var node := Node2D.new()
	node.set_script(WallScript)
	node.position = _pos(cell)
	node.set_meta("mode", "vertical")
	node.set_meta("cell_size", float(CELL))
	node.z_index = cell.y
	maze_layer.add_child(node)

## Spawn a wall node that draws a center blob (isolated wall).
func _make_wall_center(cell: Vector2i) -> void:
	var node := Node2D.new()
	node.set_script(WallScript)
	node.position = _pos(cell)
	node.set_meta("mode", "center")
	node.set_meta("cell_size", float(CELL))
	node.z_index = cell.y
	maze_layer.add_child(node)

func _make_leaf(cell: Vector2i) -> void:
	var node := Node2D.new()
	node.set_script(LeafScript)
	node.position = _pos(cell)
	objects_layer.add_child(node)
	leaves[cell] = node

func _make_spider(cell: Vector2i) -> void:
	var node := Node2D.new()
	node.set_script(SpiderScript)
	node.position = _pos(cell)
	objects_layer.add_child(node)
	hazards[cell] = "spider"

func _make_exit(cell: Vector2i) -> void:
	exit_node = Node2D.new()
	exit_node.set_script(ExitScript)
	exit_node.position = _pos(cell)
	exit_node.set_meta("open", false)
	objects_layer.add_child(exit_node)

# ── Caterpillar ──

func _rebuild_caterpillar() -> void:
	for c in cat_layer.get_children():
		c.queue_free()
	segment_nodes.clear()
	for i in segment_cells.size():
		var node := Node2D.new()
		node.set_script(SegmentScript)
		node.set_meta("seg_type", _seg_type(i))
		node.set_meta("seg_index", i)
		node.z_index = segment_cells.size() - i  # head on top, tail behind
		cat_layer.add_child(node)
		segment_nodes.append(node)
	_update_positions()
	_update_rotations()
	_update_taper()

## Calculate cumulative positions: each segment placed spacing pixels from previous,
## using its own grid-cell direction to handle corners correctly.
func _calc_positions() -> Array[Vector2]:
	var spacing := float(CELL) * 0.55
	var positions: Array[Vector2] = []
	positions.append(_pos(segment_cells[0]))
	for i in range(1, segment_cells.size()):
		var dir := Vector2(segment_cells[i] - segment_cells[i - 1]).normalized()
		positions.append(positions[i - 1] + dir * spacing)
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

func _update_rotations() -> void:
	for i in segment_nodes.size():
		var dir: Vector2i
		if i == 0:
			dir = facing
		else:
			dir = segment_cells[i - 1] - segment_cells[i]
		segment_nodes[i].rotation = _dir_angle(dir)
		var is_horizontal := (dir == Vector2i.LEFT or dir == Vector2i.RIGHT)
		segment_nodes[i].update_direction(is_horizontal)

func _update_taper() -> void:
	var n := segment_nodes.size()
	for i in n:
		var s := 1.0
		if i == 0:
			s = 1.0  # head: full size
		elif i == 1:
			s = 0.85  # first body piece: slightly smaller
		elif i == n - 1:
			s = 0.7  # tail: smallest
		else:
			# Body pieces ramp up over 3 steps then stay large
			var body_i := i - 2  # 0-based index in mid-body
			if body_i < 3:
				s = 0.95 + 0.05 * float(body_i)  # 0.95, 1.0, 1.05
			else:
				s = 1.1
		segment_nodes[i].scale = Vector2(s, s)

func _dir_angle(dir: Vector2i) -> float:
	if dir == Vector2i.RIGHT: return 0.0
	if dir == Vector2i.DOWN: return PI * 0.5
	if dir == Vector2i.LEFT: return PI
	if dir == Vector2i.UP: return -PI * 0.5
	return 0.0

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
	# Detect reverse direction (opposite of current facing) — move backwards slowly
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
	# Move backwards — every segment shifts one cell away from the head
	var prev := segment_cells.duplicate()
	# Last segment moves to the cell beyond it (away from head)
	var tail_dir: Vector2i
	if prev.size() > 1:
		tail_dir = prev[-1] - prev[-2]
	else:
		tail_dir = -facing
	var new_tail: Vector2i = prev[-1] + tail_dir
	# Check wall for the new tail position
	if wall_set.has(new_tail):
		is_busy = false
		_bump()
		return
	# Shift each segment to the next one's old position (away from head)
	for i in range(0, segment_cells.size() - 1):
		segment_cells[i] = prev[i + 1]
	segment_cells[-1] = new_tail

	# Slower animation for reversing — stagger from tail first
	var anim_dur := 0.3
	var seg_delay := 0.01
	var target_positions := _calc_positions()
	var seg_count := segment_nodes.size()
	for i in seg_count:
		var tw := create_tween()
		var delay := seg_delay * float(seg_count - 1 - i)  # tail starts first
		tw.tween_property(segment_nodes[i], "position", target_positions[i], anim_dur) \
			.set_trans(Tween.TRANS_SINE).set_ease(Tween.EASE_IN_OUT).set_delay(delay)
	# Animate camera — follow the head
	var ctw := create_tween()
	ctw.tween_property(cam, "position", _pos(segment_cells[0]), anim_dur) \
		.set_trans(Tween.TRANS_SINE).set_ease(Tween.EASE_IN_OUT)

	# Collect leaf
	# Check for leaf/hazard at new head position
	var head_cell := segment_cells[0]
	if leaves.has(head_cell):
		leaves[head_cell].queue_free()
		leaves.erase(head_cell)
		leaves_left -= 1
		var extra_cell: Vector2i = new_tail + tail_dir
		segment_cells.append(extra_cell)
		var node := Node2D.new()
		node.set_script(SegmentScript)
		var tail_positions := _calc_positions()
		node.position = tail_positions[-1]
		node.set_meta("seg_type", "tail")
		node.set_meta("seg_index", segment_cells.size() - 1)
		node.z_index = 0
		cat_layer.add_child(node)
		segment_nodes.append(node)
		if segment_nodes.size() > 2:
			segment_nodes[-2].update_seg_type("body")
		for zi in segment_nodes.size():
			segment_nodes[zi].z_index = segment_nodes.size() - zi

	_update_rotations()
	_update_taper()
	for n in segment_nodes:
		n.wiggle_legs()
		n.queue_redraw()

	if hazards.has(head_cell):
		await _lose()
		return
	if leaves_left <= 0 and exit_node:
		exit_node.set_meta("open", true)
	if head_cell == exit_cell and leaves_left <= 0:
		await _win()
		return

	_update_hud()
	await get_tree().create_timer(anim_dur + seg_delay * seg_count).timeout
	is_busy = false

func _move_to(target: Vector2i) -> void:
	is_busy = true
	var prev := segment_cells.duplicate()
	segment_cells[0] = target
	for i in range(1, segment_cells.size()):
		segment_cells[i] = prev[i - 1]

	# Animate segments smoothly with tiny stagger for crawl feel
	var anim_dur := 0.15
	var seg_delay := 0.01
	var target_positions := _calc_positions()
	for i in segment_nodes.size():
		var delay := seg_delay * float(i)
		var tw := create_tween()
		tw.tween_property(segment_nodes[i], "position", target_positions[i], anim_dur) \
			.set_trans(Tween.TRANS_SINE).set_ease(Tween.EASE_IN_OUT).set_delay(delay)
	# Animate camera
	var ctw := create_tween()
	ctw.tween_property(cam, "position", _pos(target), anim_dur) \
		.set_trans(Tween.TRANS_SINE).set_ease(Tween.EASE_IN_OUT)

	# Collect leaf
	if leaves.has(target):
		leaves[target].queue_free()
		leaves.erase(target)
		leaves_left -= 1
		var new_cell: Vector2i = prev[-1]
		segment_cells.append(new_cell)
		var node := Node2D.new()
		node.set_script(SegmentScript)
		var tail_positions := _calc_positions()
		node.position = tail_positions[-1]
		node.set_meta("seg_type", "tail")
		node.set_meta("seg_index", segment_cells.size() - 1)
		node.z_index = 0
		cat_layer.add_child(node)
		segment_nodes.append(node)
		if segment_nodes.size() > 2:
			segment_nodes[-2].update_seg_type("body")
		# Refresh z_index so head stays on top
		for zi in segment_nodes.size():
			segment_nodes[zi].z_index = segment_nodes.size() - zi

	_update_rotations()
	_update_taper()
	for n in segment_nodes:
		n.wiggle_legs()
		n.queue_redraw()

	# Check hazard
	if hazards.has(target):
		await _lose()
		return

	# Open exit when all leaves collected
	if leaves_left <= 0 and exit_node:
		exit_node.set_meta("open", true)

	# Win check
	if target == exit_cell and leaves_left <= 0:
		await _win()
		return

	_update_hud()
	is_busy = false

func _bump() -> void:
	if segment_nodes.is_empty():
		return
	var tw := create_tween()
	tw.tween_property(segment_nodes[0], "scale", Vector2(1.1, 1.1), 0.05)
	tw.tween_property(segment_nodes[0], "scale", Vector2(1.0, 1.0), 0.08)

func _lose() -> void:
	hud_label.text = "Ouch! Restarting..."
	for n in segment_nodes:
		var tw := create_tween()
		tw.tween_property(n, "modulate", Color(1, 0.5, 0.5), 0.1)
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
