extends Node2D

const CELL := 64
const GROUND_COLOR := Color(0.55, 0.78, 0.35)

const SegmentScript := preload("res://scripts/segment.gd")
const LeafScript := preload("res://scripts/leaf.gd")
const SpiderScript := preload("res://scripts/spider.gd")
const ExitScript := preload("res://scripts/exit_portal.gd")
const WallScript := preload("res://scripts/wall_tile.gd")

# Large mazes – well beyond screen size (screen is ~17x30 cells at 64px on 1080x1920).
# Legend: # wall, . path, P player, L leaf, S spider, E exit
const LEVELS := [
[
"#######################",
"#P..#.....#...........#",
"#.#.#.###.#.#########.#",
"#.#...#.....#.......#.#",
"#.#####.#####.#####.#.#",
"#.#...#.......#L..#...#",
"#.#.#.#########.#.###.#",
"#...#.....L.....#.....#",
"###.#####.#########.###",
"#...#...#.#.......#...#",
"#.###.#.#.#.#####.###.#",
"#.....#...#.#...#.....#",
"#.#######.#.#.#.#####.#",
"#.#.....#.#...#.......#",
"#.#.###.#.#####.#####.#",
"#.#.#...#.......#...#.#",
"#.#.#.###########.#.#.#",
"#.#.#.............#...#",
"#.#.###############.###",
"#.#...............#...#",
"#.###.###########.###.#",
"#.....#.........#.....#",
"#####.#.#######.#.#####",
"#...#.#.#.....#.#.#...#",
"#.#.#.#.#.###.#.#.#.#.#",
"#.#...#...#.L.#...#.#.#",
"#.#####.###.#.###.#.#.#",
"#.......#...#.#...#.#.#",
"#.#######.###.#.###.#.#",
"#.#.......#...#.....#.#",
"#.#.#######.#########.#",
"#.#.......S.......#...#",
"#.###############.###.#",
"#...............#.....E#",
"#######################",
],
[
"###########################",
"#P....#.........#.........#",
"#.###.#.#######.#.#######.#",
"#...#.#.#.......#.......#.#",
"###.#.#.#.#####.#######.#.#",
"#...#...#.#...#.......#.#.#",
"#.#######.#.#.#######.#.#.#",
"#.........#.#.....L.#.#.#.#",
"#.#########.#######.#.#.#.#",
"#.#.......#.......#.#.#...#",
"#.#.#####.#######.#.#.###.#",
"#.#.#...#.........#.#.....#",
"#.#.#.#.###########.#####.#",
"#.#...#...........#.....#.#",
"#.#.#############.#####.#.#",
"#.#.#.............#...#...#",
"#.#.#.###########.#.#.###.#",
"#...#.#.........#...#.....#",
"###.#.#.#######.#########.#",
"#...#.#.......#.........#.#",
"#.###.#######.#.#######.#.#",
"#.#...........#.#.....#.#.#",
"#.#.###########.#.###.#.#.#",
"#.#.............#.#...#...#",
"#.###############.#.#####.#",
"#...........#.....#.......#",
"#.#########.#.###########.#",
"#.#.......#.#.#.........#.#",
"#.#.#####.#.#.#.#######.#.#",
"#.#.#.L...#.#.#.#.....#.#.#",
"#.#.#.#####.#.#.#.###.#.#.#",
"#.#.#.......#...#.#S..#.#.#",
"#.#.#############.#.###.#.#",
"#.#...............#.....#.#",
"#.#.#################.###.#",
"#.#.....L.....#.......#...#",
"#.#############.#########.#",
"#...............#.........E#",
"###########################",
],
[
"###############################",
"#P..#.......#.........#.......#",
"#.#.#.#####.#.#######.#.#####.#",
"#.#.#.....#.#.#.......#.#...#.#",
"#.#.#####.#.#.#.#######.#.#.#.#",
"#.#.......#...#.......#...#.#.#",
"#.#########.#########.#####.#.#",
"#.....L...#.#.......#.......#.#",
"#########.#.#.#####.#.#######.#",
"#.........#.#.....#.#.#.......#",
"#.#########.#####.#.#.#.#####.#",
"#.#.......#.......#.#.#.....#.#",
"#.#.#####.#########.#.#####.#.#",
"#.#.#...#...........#.......#.#",
"#.#.#.#.#####.###########.###.#",
"#.#...#.......#.........#.#...#",
"#.###########.#.#######.#.#.###",
"#.............#.#.....#.#.#...#",
"#.#############.#.###.#.#.###.#",
"#.#...........#.#.#...#.#.....#",
"#.#.#########.#.#.#.###.#.####",
"#.#.........#.#.#.#.....#....#",
"#.#########.#.#.#.#########.#.#",
"#.........#.#.#.#.........#.#.#",
"#########.#.#.#.#########.#.#.#",
"#.........#...#.........#.#.#.#",
"#.#################.###.#.#.#.#",
"#...................#...#...#..#",
"#.#########.#########.#####.#.#",
"#.#.......#.#.......#.......#.#",
"#.#.#####.#.#.#####.#.#######.#",
"#.#.#...#.#.#.#...#.#.#.L....#",
"#.#.#.#.#.#.#.#.#.#.#.#.#####.#",
"#.#...#...#...#.#...#...#.....#",
"#.#######.#####.#######.#.###.#",
"#.......#.......#.....#.#.#...#",
"#######.#########.###.#.#.#.###",
"#.......#.........#.S.#.#.#...#",
"#.#######.#########.###.#.###.#",
"#.................L.#...#.....E#",
"###############################",
],
]

var current_level: int = 0
var wall_set: Dictionary = {}
var player_cell: Vector2i = Vector2i.ZERO
var facing: Vector2i = Vector2i.RIGHT
var segment_cells: Array[Vector2i] = []
var segment_nodes: Array[Node2D] = []
var leaves: Dictionary = {}
var hazards: Dictionary = {}
var exit_cell: Vector2i = Vector2i.ZERO
var exit_node: Node2D = null
var leaves_left: int = 0
var is_busy: bool = false
var swipe_start := Vector2.ZERO

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

	# Background with tiling pattern
	var maze_h: int = rows.size()
	var maze_w: int = 0
	for row in rows:
		maze_w = max(maze_w, row.length())
	var bg := TextureRect.new()
	bg.texture = load("res://assets/background_pattern.png")
	bg.position = Vector2.ZERO
	bg.size = Vector2(maze_w * CELL, maze_h * CELL)
	bg.stretch_mode = TextureRect.STRETCH_TILE
	maze_layer.add_child(bg)

	# Pass 1: collect wall positions
	for y in rows.size():
		var row: String = rows[y]
		for x in row.length():
			if row[x] == "#":
				wall_set[Vector2i(x, y)] = true

	# Pass 2: create entities
	for y in rows.size():
		var row: String = rows[y]
		for x in row.length():
			var ch := row[x]
			var cell := Vector2i(x, y)
			match ch:
				"#":
					_make_wall(cell)
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

	# Caterpillar (3 segments trailing left)
	segment_cells = [player_cell]
	for i in range(1, 3):
		segment_cells.append(player_cell + Vector2i.LEFT * i)
	_rebuild_caterpillar()
	_update_hud()
	cam.position = _pos(player_cell)
	win_panel.visible = false
	is_busy = false

func _pos(cell: Vector2i) -> Vector2:
	return Vector2(cell.x * CELL + CELL * 0.5, cell.y * CELL + CELL * 0.5)

# ── Entity factories ──

func _make_wall(cell: Vector2i) -> void:
	var node := Node2D.new()
	node.set_script(WallScript)
	node.position = _pos(cell)
	node.set_meta("has_t", wall_set.has(cell + Vector2i.UP))
	node.set_meta("has_b", wall_set.has(cell + Vector2i.DOWN))
	node.set_meta("has_l", wall_set.has(cell + Vector2i.LEFT))
	node.set_meta("has_r", wall_set.has(cell + Vector2i.RIGHT))
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
		node.position = _pos(segment_cells[i])
		node.set_meta("seg_type", _seg_type(i))
		cat_layer.add_child(node)
		segment_nodes.append(node)
	_update_rotations()

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

func _unhandled_input(event: InputEvent) -> void:
	if event.is_action_pressed("move_up"):
		_try_move(Vector2i.UP)
	elif event.is_action_pressed("move_down"):
		_try_move(Vector2i.DOWN)
	elif event.is_action_pressed("move_left"):
		_try_move(Vector2i.LEFT)
	elif event.is_action_pressed("move_right"):
		_try_move(Vector2i.RIGHT)

# ── Movement ──

func _try_move(dir: Vector2i) -> void:
	if is_busy:
		return
	facing = dir
	var target := segment_cells[0] + dir
	if wall_set.has(target):
		_bump()
		return
	if segment_cells.has(target) and target != segment_cells[-1]:
		_bump()
		return
	await _move_to(target)

func _move_to(target: Vector2i) -> void:
	is_busy = true
	var prev := segment_cells.duplicate()
	segment_cells[0] = target
	for i in range(1, segment_cells.size()):
		segment_cells[i] = prev[i - 1]

	# Animate segments
	for i in segment_nodes.size():
		var tw := create_tween()
		tw.tween_property(segment_nodes[i], "position", _pos(segment_cells[i]), 0.12) \
			.set_trans(Tween.TRANS_SINE).set_ease(Tween.EASE_OUT)
	# Animate camera
	var ctw := create_tween()
	ctw.tween_property(cam, "position", _pos(target), 0.12) \
		.set_trans(Tween.TRANS_SINE).set_ease(Tween.EASE_OUT)
	await get_tree().create_timer(0.13).timeout

	# Collect leaf
	if leaves.has(target):
		leaves[target].queue_free()
		leaves.erase(target)
		leaves_left -= 1
		var new_cell: Vector2i = prev[-1]
		segment_cells.append(new_cell)
		var node := Node2D.new()
		node.set_script(SegmentScript)
		node.position = _pos(new_cell)
		node.set_meta("seg_type", "tail")
		cat_layer.add_child(node)
		segment_nodes.append(node)
		if segment_nodes.size() > 2:
			segment_nodes[-2].set_meta("seg_type", "body")
			segment_nodes[-2].queue_redraw()

	_update_rotations()
	for n in segment_nodes:
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
