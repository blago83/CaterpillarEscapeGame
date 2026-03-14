extends Node2D

const TILE_SIZE := 128
const GRID_OFFSET := Vector2(90, 280)

const LEVELS := [
[
"############",
"#P..L......#",
"#.####.###.#",
"#....#...#.#",
"##.#.#.#.#.#",
"#..#...#...#",
"#.###S###.##",
"#....L....E#",
"############",
],
[
"############",
"#P...#.....#",
"#.##.#.###.#",
"#....#..L#.#",
"#.####.#.#.#",
"#....#.#.#.#",
"##M#.#.#...#",
"#L.#...###E#",
"############",
],
[
"############",
"#P..L....L.#",
"#.######.#.#",
"#.....#..#.#",
"###.#.#.##.#",
"#...#.#....#",
"#.###S###M##",
"#.........E#",
"############",
],
]

var current_level: int = 0
var walls: Array = []
var hazards: Dictionary = {}
var collectibles: Dictionary = {}
var exit_cell: Vector2i = Vector2i.ZERO
var exit_sprite: Sprite2D
var player_cell: Vector2i = Vector2i.ZERO
var facing: Vector2i = Vector2i.RIGHT
var segment_cells: Array[Vector2i] = []
var segment_nodes: Array[Sprite2D] = []
var leaves_left: int = 0
var is_busy: bool = false
var swipe_start := Vector2.ZERO

@onready var world: Node2D = $World
@onready var segments_root: Node2D = $Segments
@onready var hud_label: Label = $CanvasLayer/HUD/MarginContainer/Panel/HBoxContainer/InfoLabel

func _ready() -> void:
	$CanvasLayer/HUD/MarginContainer/Panel/HBoxContainer/RetryButton.pressed.connect(_on_retry_pressed)
	$CanvasLayer/HUD/MarginContainer/Panel/HBoxContainer/MenuButton.pressed.connect(_on_menu_pressed)
	$CanvasLayer/WinPanel/Center/VBoxContainer/NextButton.pressed.connect(_on_next_pressed)
	load_level(current_level)

func clear_world() -> void:
	for child in world.get_children():
		child.queue_free()
	for child in segments_root.get_children():
		child.queue_free()
	walls.clear()
	hazards.clear()
	collectibles.clear()
	segment_cells.clear()
	segment_nodes.clear()

func load_level(index: int) -> void:
	clear_world()
	current_level = index % LEVELS.size()
	leaves_left = 0
	var rows: Array = LEVELS[current_level]
	for y in rows.size():
		var row: String = rows[y]
		for x in row.length():
			var c := row[x]
			var cell := Vector2i(x, y)
			_add_ground(cell)
			match c:
				"#":
					_add_wall(cell)
				"P":
					player_cell = cell
				"L":
					leaves_left += 1
					_add_collectible(cell)
				"S":
					_add_hazard(cell, "spider")
				"M":
					_add_hazard(cell, "mushroom")
				"E":
					exit_cell = cell
					_add_exit(cell)
				_:
					pass

	segment_cells = [player_cell, player_cell - Vector2i.LEFT, player_cell - Vector2i.LEFT * 2]
	_rebuild_segments()
	_update_hud()
	$CanvasLayer/WinPanel.visible = false

func _cell_to_pos(cell: Vector2i) -> Vector2:
	return GRID_OFFSET + Vector2(cell.x * TILE_SIZE + TILE_SIZE / 2, cell.y * TILE_SIZE + TILE_SIZE / 2)

func _add_ground(cell: Vector2i) -> void:
	var sprite := Sprite2D.new()
	sprite.texture = load("res://assets/tiles/ground_dirt.png")
	sprite.position = _cell_to_pos(cell)
	world.add_child(sprite)

func _add_wall(cell: Vector2i) -> void:
	var body := StaticBody2D.new()
	body.position = _cell_to_pos(cell)
	var sprite := Sprite2D.new()
	sprite.texture = load("res://assets/tiles/hedge_cross.png")
	body.add_child(sprite)
	var shape := CollisionShape2D.new()
	var rect := RectangleShape2D.new()
	rect.size = Vector2(TILE_SIZE * 0.9, TILE_SIZE * 0.9)
	shape.shape = rect
	body.add_child(shape)
	world.add_child(body)
	walls.append(cell)

func _add_collectible(cell: Vector2i) -> void:
	var sprite := Sprite2D.new()
	sprite.texture = load("res://assets/objects/leaf_food.png")
	sprite.position = _cell_to_pos(cell)
	sprite.scale = Vector2(1.0, 1.0)
	world.add_child(sprite)
	collectibles[cell] = sprite

func _add_hazard(cell: Vector2i, kind: String) -> void:
	var sprite := Sprite2D.new()
	sprite.texture = load("res://assets/objects/%s.png" % ("spider" if kind == "spider" else "poison_mushroom"))
	sprite.position = _cell_to_pos(cell)
	world.add_child(sprite)
	hazards[cell] = kind

func _add_exit(cell: Vector2i) -> void:
	exit_sprite = Sprite2D.new()
	exit_sprite.texture = load("res://assets/objects/exit_closed.png")
	exit_sprite.position = _cell_to_pos(cell)
	world.add_child(exit_sprite)

func _rebuild_segments() -> void:
	for child in segments_root.get_children():
		child.queue_free()
	segment_nodes.clear()
	for i in segment_cells.size():
		var sprite := Sprite2D.new()
		if i == 0:
			sprite.texture = load("res://assets/characters/caterpillar_head.png")
		elif i == segment_cells.size() - 1:
			sprite.texture = load("res://assets/characters/caterpillar_tail.png")
		else:
			sprite.texture = load("res://assets/characters/caterpillar_body.png")
		sprite.position = _cell_to_pos(segment_cells[i])
		sprite.scale = Vector2(0.92, 0.92)
		segments_root.add_child(sprite)
		segment_nodes.append(sprite)
	_refresh_segment_rotations()

func _refresh_segment_rotations() -> void:
	for i in segment_nodes.size():
		if i == 0:
			var dir := facing
			segment_nodes[i].rotation = _dir_to_angle(dir)
		elif i == segment_nodes.size() - 1:
			var prev := segment_cells[i - 1]
			var dir_tail := prev - segment_cells[i]
			segment_nodes[i].rotation = _dir_to_angle(dir_tail)
		else:
			var prev2 := segment_cells[i - 1]
			var dir_body := prev2 - segment_cells[i]
			segment_nodes[i].rotation = _dir_to_angle(dir_body)

func _dir_to_angle(dir: Vector2i) -> float:
	if dir == Vector2i.RIGHT: return 0.0
	if dir == Vector2i.DOWN: return PI / 2.0
	if dir == Vector2i.LEFT: return PI
	if dir == Vector2i.UP: return -PI / 2.0
	return 0.0

func _input(event: InputEvent) -> void:
	if event is InputEventScreenTouch:
		if event.pressed:
			swipe_start = event.position
		else:
			var delta: Vector2 = event.position - swipe_start
			if delta.length() > 40.0:
				if abs(delta.x) > abs(delta.y):
					queue_move(Vector2i.RIGHT if delta.x > 0 else Vector2i.LEFT)
				else:
					queue_move(Vector2i.DOWN if delta.y > 0 else Vector2i.UP)

func _unhandled_input(event: InputEvent) -> void:
	if event.is_action_pressed("move_up"):
		queue_move(Vector2i.UP)
	elif event.is_action_pressed("move_down"):
		queue_move(Vector2i.DOWN)
	elif event.is_action_pressed("move_left"):
		queue_move(Vector2i.LEFT)
	elif event.is_action_pressed("move_right"):
		queue_move(Vector2i.RIGHT)

func queue_move(dir: Vector2i) -> void:
	if is_busy:
		return
	facing = dir
	var target := segment_cells[0] + dir
	if walls.has(target):
		_bump_head()
		return
	if segment_cells.has(target) and target != segment_cells[-1]:
		_bump_head()
		return
	await _move_to(target)

func _move_to(target: Vector2i) -> void:
	is_busy = true
	var previous_cells := segment_cells.duplicate()
	segment_cells[0] = target
	for i in range(1, segment_cells.size()):
		segment_cells[i] = previous_cells[i - 1]

	var got_leaf := false
	if collectibles.has(target):
		got_leaf = true
		collectibles[target].queue_free()
		collectibles.erase(target)
		leaves_left -= 1

	for i in segment_nodes.size():
		var tween := create_tween()
		tween.tween_property(segment_nodes[i], "position", _cell_to_pos(segment_cells[i]), 0.16).set_trans(Tween.TRANS_SINE).set_ease(Tween.EASE_OUT)
	await get_tree().create_timer(0.17).timeout

	if got_leaf:
		var new_cell: Vector2i = previous_cells[-1]
		segment_cells.append(new_cell)
		var sprite := Sprite2D.new()
		sprite.texture = load("res://assets/characters/caterpillar_tail.png")
		sprite.position = _cell_to_pos(new_cell)
		sprite.scale = Vector2(0.92, 0.92)
		segments_root.add_child(sprite)
		segment_nodes.append(sprite)
		if segment_nodes.size() > 1:
			segment_nodes[segment_nodes.size() - 2].texture = load("res://assets/characters/caterpillar_body.png")
		_pulse_collect()
	_refresh_segment_rotations()

	if hazards.has(target):
		await _lose_level(hazards[target])
		return

	if leaves_left <= 0:
		exit_sprite.texture = load("res://assets/objects/exit_open.png")

	if target == exit_cell and leaves_left <= 0:
		await _win_level()
		return

	_update_hud()
	is_busy = false

func _bump_head() -> void:
	if segment_nodes.is_empty():
		return
	var head := segment_nodes[0]
	var tween := create_tween()
	tween.tween_property(head, "scale", Vector2(1.02, 1.02), 0.05)
	tween.tween_property(head, "scale", Vector2(0.92, 0.92), 0.08)

func _pulse_collect() -> void:
	for node in segment_nodes:
		var tween := create_tween()
		tween.tween_property(node, "scale", Vector2(1.0, 1.0), 0.08)
		tween.tween_property(node, "scale", Vector2(0.92, 0.92), 0.12)

func _lose_level(reason: String) -> void:
	hud_label.text = "Ouch! Hit " + reason + ". Restarting..."
	for node in segment_nodes:
		var tween := create_tween()
		tween.tween_property(node, "modulate", Color(1.0, 0.6, 0.6), 0.08)
	await get_tree().create_timer(0.6).timeout
	load_level(current_level)
	is_busy = false

func _win_level() -> void:
	is_busy = true
	$CanvasLayer/WinPanel.visible = true
	$CanvasLayer/WinPanel/Center/VBoxContainer/Title.text = "Level %d Complete!" % (current_level + 1)
	if current_level >= LEVELS.size() - 1:
		$CanvasLayer/WinPanel/Center/VBoxContainer/SubTitle.text = "You beat the prototype. Add more mazes next!"
		$CanvasLayer/WinPanel/Center/VBoxContainer/NextButton.text = "Play Again"
	else:
		$CanvasLayer/WinPanel/Center/VBoxContainer/SubTitle.text = "Nice work. Your shoe caterpillar escaped!"
		$CanvasLayer/WinPanel/Center/VBoxContainer/NextButton.text = "Next Level"

func _update_hud() -> void:
	hud_label.text = "Level %d    Leaves Left: %d    Length: %d" % [current_level + 1, leaves_left, segment_cells.size()]

func _on_retry_pressed() -> void:
	load_level(current_level)

func _on_menu_pressed() -> void:
	get_tree().change_scene_to_file("res://scenes/MainMenu.tscn")

func _on_next_pressed() -> void:
	load_level((current_level + 1) % LEVELS.size())
	is_busy = false
