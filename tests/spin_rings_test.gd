extends SceneTree

const Level3DScript := preload("res://scripts/level_3d.gd")
const Level3DScene := preload("res://scenes/Level3D.tscn")
const BushShapes := preload("res://scripts/bush_shapes.gd")
const RINGS_LEVEL := 6
const CENTER := Vector2i(10, 15)
const DIRS := [Vector2i.UP, Vector2i.DOWN, Vector2i.LEFT, Vector2i.RIGHT]

var _failures := 0

func _initialize() -> void:
	call_deferred("_run_tests")

func _run_tests() -> void:
	_test_shapes()
	var level := _new_level()
	_check(int(level.get("current_level")) == RINGS_LEVEL, "menu start level opens the rings level")
	_check(int(Level3DScript.start_level) == -1, "start level override is consumed")
	_test_flat_style(level)
	_test_level_layout(level)
	_test_rings_are_barriers(level)
	_test_gaps_let_you_through(level)
	_test_arrows_and_alignment(level)
	_test_blocked_move(level)
	_test_ring_carries_head(level)
	_test_rings_never_stop(level)
	_test_ring_bite_opens_gap(level)
	level.free()
	_test_level_can_be_finished()

	if _failures == 0:
		print("Spinning ring regression checks passed.")
	else:
		printerr("%d spinning ring check(s) failed." % _failures)
	quit(1 if _failures else 0)

func _new_level() -> Node3D:
	Level3DScript.start_level = RINGS_LEVEL
	var level := Level3DScene.instantiate() as Node3D
	root.add_child(level)
	level.set_process(false)
	for snd in ["_snd_move", "_snd_leaf", "_snd_portal", "_snd_bite", "_snd_eat"]:
		level.set(snd, null)
	return level

func _check(condition: bool, message: String) -> bool:
	if not condition:
		_failures += 1
		printerr("FAIL: ", message)
	return condition

func _test_shapes() -> void:
	_check(BushShapes.build({"shape": "line", "at": Vector2i(1, 1), "to": Vector2i(4, 1)}).size() == 4, "line shape")
	_check(BushShapes.build({"shape": "box", "at": Vector2i(0, 0), "size": Vector2i(3, 3)}).size() == 8, "hollow box shape")
	_check(BushShapes.build({"shape": "cross", "at": Vector2i(5, 5), "arm": 2}).size() == 9, "cross shape")
	_check(BushShapes.build({"shape": "diamond", "at": Vector2i(5, 5), "radius": 2}).size() == 8, "diamond shape")
	_check(BushShapes.build({"shape": "pattern", "at": Vector2i(2, 2), "rows": ["#.#", ".#."]}).size() == 3, "pattern shape")
	var sq := BushShapes.square_ring_cells(CENTER, 2)
	_check(sq.size() == 16 and sq[0] == CENTER + Vector2i(-2, -2), "square ring starts at its top-left corner")
	var touching := true
	for i in sq.size():
		var d: Vector2i = sq[(i + 1) % sq.size()] - sq[i]
		touching = touching and absi(d.x) + absi(d.y) == 1
	_check(touching, "square ring cells follow each other edge to edge")

func _test_flat_style(level: Node3D) -> void:
	var ground := level.get("_ground_mat") as StandardMaterial3D
	_check(ground != null and ground.albedo_texture == null, "ground is a flat colour without a background image")
	_check(level.get("_fog_mm_inst") == null, "no fog overlay is built")

func _test_level_layout(level: Node3D) -> void:
	var rings: Array = level.get("_spin_rings")
	_check(rings.size() == 3, "three rings are built")
	var wall_set: Dictionary = level.get("wall_set")
	var rocks: Dictionary = level.get("_rock_wall_cells")
	_check(rocks.has(Vector2i(2, 15)) and rocks.has(Vector2i(18, 15)), "rock dividers are stamped")
	var maze_walls := 0
	for cell in wall_set.keys():
		var cheb := maxi(absi(cell.x - CENTER.x), absi(cell.y - CENTER.y))
		if cheb > 7 and cell.x > 0 and cell.y > 0 and cell.x < 20 and cell.y < 30:
			maze_walls += 1
		elif cheb <= 7 and cell.y != CENTER.y:
			_check(false, "the ring clearing has no walls (%s)" % [cell])
	_check(maze_walls > 80, "a maze surrounds the rings (%d inner walls)" % maze_walls)
	var leaves: Dictionary = level.get("leaves")
	_check(leaves.has(CENTER) and leaves.size() == 4, "four fruits, one in the middle of the rings")
	_check(int(level.get("_required_fruits_left")) == leaves.size(), "fruit goal matches the fruit on the board")
	_check((level.get("hazards") as Dictionary).is_empty(), "no random hazards on the rings level")
	var owner_map: Dictionary = level.get("_spin_cell_owner")
	for cell in owner_map.keys():
		_check(not wall_set.has(cell) and not leaves.has(cell), "ring cell %s is free of walls and fruit" % [cell])
	for cell in level.get("segment_cells"):
		_check(not owner_map.has(cell), "caterpillar does not start on a ring")

func _reachable(level: Node3D, from_cell: Vector2i, blocked: Dictionary) -> Dictionary:
	var wall_set: Dictionary = level.get("wall_set")
	var seen := {from_cell: true}
	var queue: Array[Vector2i] = [from_cell]
	while not queue.is_empty():
		var cur: Vector2i = queue.pop_back()
		for dir in DIRS:
			var nxt: Vector2i = cur + dir
			if seen.has(nxt) or wall_set.has(nxt) or blocked.has(nxt) or not level.call("_is_inside_maze", nxt):
				continue
			seen[nxt] = true
			queue.append(nxt)
	return seen

func _test_rings_are_barriers(level: Node3D) -> void:
	var all_ring_cells: Dictionary = level.get("_spin_cell_owner")
	var start: Vector2i = level.get("player_cell")
	var reach := _reachable(level, start, all_ring_cells)
	_check(not reach.has(CENTER), "closed rings guard the middle fruit")
	_check(not reach.has(level.get("exit_cell")), "the portal side is only reachable through the rings")
	var open_reach := _reachable(level, start, {})
	for cell in (level.get("leaves") as Dictionary).keys():
		_check(open_reach.has(cell), "fruit %s is reachable through the rings" % [cell])
	_check(open_reach.has(level.get("exit_cell")), "portal is reachable through the rings")

# Over a full turn, every ring has a gap linking the track inside it to the
# track outside it.
func _test_arrows_and_alignment(level: Node3D) -> void:
	var rings: Array = level.get("_spin_rings")
	for ring in rings:
		var blocks: MultiMesh = ring.get("_mm")
		var arrows: MultiMesh = ring.get("_arrow_mm")
		_check(arrows != null and arrows.instance_count == blocks.instance_count, "ring %d shows an arrow on every block" % ring.size)
		var c: Vector2i = ring.cells[1]
		_check(ring.move_dir(c) == ring.next_cell(c) - c and absi(ring.move_dir(c).x) + absi(ring.move_dir(c).y) == 1, "ring %d arrows point one cell along the ring" % ring.size)
		var open := 0
		for cell in ring.cells:
			if not ring.is_blocked(cell):
				open += 1
		_check((ring.get("_glow_mm") as MultiMesh).instance_count >= open, "ring %d glows under every gap" % ring.size)
	# Turn the rings until two gaps line up, then check the passage is real.
	var found := false
	for t in 400:
		for ring in rings:
			ring.step()
		level.call("_update_ring_alignment", false)
		var pairs: Dictionary = level.get("_aligned_pairs")
		if pairs.is_empty():
			continue
		found = true
		for ring in rings:
			for cell in ring.get("_aligned"):
				if ring.owns(cell):
					_check(not ring.is_blocked(cell), "glowing passage cell %s is open" % [cell])
				else:
					_check(not level.get("_spin_cell_owner").has(cell) and not level.get("wall_set").has(cell), "glowing track cell %s is walkable" % [cell])
		break
	_check(found, "gaps line up and glow as a passage")

func _test_gaps_let_you_through(level: Node3D) -> void:
	for ring in level.get("_spin_rings"):
		var saved: int = ring.offset
		var links := 0
		for off in ring.cells.size():
			for cell in ring.cells:
				if ring.is_blocked(cell, off):
					continue
				var inner := false
				var outer := false
				for dir in DIRS:
					var n: Vector2i = cell + dir
					var cheb := maxi(absi(n.x - CENTER.x), absi(n.y - CENTER.y))
					inner = inner or cheb == ring.size - 1
					outer = outer or cheb == ring.size + 1
				if inner and outer:
					links += 1
		_check(links >= ring.cells.size(), "ring %d regularly opens a way through (%d)" % [ring.size, links])
		ring.offset = saved

func _place_caterpillar(level: Node3D, cells: Array[Vector2i], dir: Vector2i) -> void:
	level.set("segment_cells", cells)
	level.set("player_cell", cells[0])
	level.set("facing", dir)
	level.set("is_busy", false)
	level.set("_is_biting", false)
	level.set("_move_anim_remaining", 0.0)
	level.set("_carry_ring", null)

func _set_bottom_gap(ring: Node3D, cell: Vector2i, open: bool) -> void:
	for off in ring.cells.size():
		if ring.is_blocked(cell, off) != open:
			ring.offset = off
			return

func _test_blocked_move(level: Node3D) -> void:
	level.call("_dismiss_intro")
	var outer: Node3D = (level.get("_spin_rings") as Array)[2]
	var ring_cell := Vector2i(10, 21)
	var body: Array[Vector2i] = [Vector2i(10, 22), Vector2i(11, 22), Vector2i(12, 22), Vector2i(13, 22), Vector2i(14, 22)]
	_set_bottom_gap(outer, ring_cell, false)
	_place_caterpillar(level, body, Vector2i.LEFT)
	level.call("_try_move", Vector2i.UP)
	_check(level.get("player_cell") == Vector2i(10, 22), "cannot crawl into a ring block")
	_set_bottom_gap(outer, ring_cell, true)
	level.set("is_busy", false)
	level.call("_try_move", Vector2i.UP)
	_check(level.get("player_cell") == ring_cell, "can crawl into a gap")

func _test_ring_carries_head(level: Node3D) -> void:
	var outer: Node3D = (level.get("_spin_rings") as Array)[2]
	var head := Vector2i(10, 21)
	# Put the head on the trailing edge of a gap so the next step closes it.
	var found := false
	for off in outer.cells.size():
		if not outer.is_blocked(head, off) and outer.is_blocked(head, off + outer.dir):
			outer.offset = off
			found = true
			break
	if not _check(found, "outer ring has a gap edge at the bottom"):
		return
	var body: Array[Vector2i] = [head, Vector2i(10, 22), Vector2i(10, 23), Vector2i(10, 24), Vector2i(10, 25)]
	_place_caterpillar(level, body, Vector2i.UP)
	var expected: Vector2i = outer.next_cell(head)
	outer.step_timer = outer.step_time
	level.call("_process_spinners", 0.0)
	_check(level.get("player_cell") == expected, "a closing gap carries the head one cell along")
	_check(not outer.is_blocked(expected), "the carried head is still in the gap")
	_check(level.get("_carry_ring") == outer, "the caterpillar is riding the ring")

func _test_rings_never_stop(level: Node3D) -> void:
	var rings: Array = level.get("_spin_rings")
	var outer: Node3D = rings[2]
	# Body lies across the bottom gap while the head is already through.
	var body: Array[Vector2i] = [Vector2i(10, 19), Vector2i(10, 20), Vector2i(10, 21), Vector2i(10, 22), Vector2i(10, 23)]
	_set_bottom_gap(outer, Vector2i(10, 21), true)
	_place_caterpillar(level, body, Vector2i.UP)
	var before: int = outer.offset
	for _i in 60:
		level.set("_move_anim_remaining", 0.0)
		level.call("_process_spinners", 0.05)
	_check(outer.offset != before, "rings keep turning while the body is in a gap")
	_check(level.get("player_cell") == Vector2i(10, 19), "a crossing caterpillar is not moved")
	if outer.is_blocked(Vector2i(10, 21)):
		var hidden: Dictionary = outer.get("_hidden")
		_check(hidden.has(Vector2i(10, 21)), "blocks under the body are hidden")

func _test_ring_bite_opens_gap(level: Node3D) -> void:
	var outer: Node3D = (level.get("_spin_rings") as Array)[2]
	var ring_cell := Vector2i(10, 21)
	_set_bottom_gap(outer, ring_cell, false)
	var body: Array[Vector2i] = [Vector2i(10, 22), Vector2i(11, 22), Vector2i(12, 22), Vector2i(13, 22), Vector2i(14, 22)]
	_place_caterpillar(level, body, Vector2i.UP)
	for _i in 3:
		level.set("_is_biting", false)
		level.set("is_busy", false)
		level.call("_start_bite")
		_check(float(outer.hold_timer) > 0.0, "biting holds the ring still")
	_check(not outer.is_blocked(ring_cell), "three bites remove the block in front")
	var held: int = outer.offset
	outer.step_timer = outer.step_time
	level.call("_process_spinners", 0.1)
	_check(outer.offset == held, "held ring does not turn")

# A simple bot plays the level with the real controls: it must eat every fruit
# and reach the portal.
func _test_level_can_be_finished() -> void:
	var level := _new_level()
	level.call("_dismiss_intro")
	var walls: Dictionary = level.get("wall_set")
	var t := 0.0
	while t < 300.0 and not (level.get("win_panel") as Control).visible:
		var leaves: Dictionary = level.get("leaves")
		var targets: Array = leaves.keys() if int(level.get("_required_fruits_left")) > 0 else [level.get("exit_cell")]
		var cells: Array = level.get("segment_cells")
		var head: Vector2i = cells[0]
		var prev := {head: head}
		var queue: Array = [head]
		var found = null
		while not queue.is_empty():
			var c: Vector2i = queue.pop_front()
			if targets.has(c):
				found = c
				break
			for d in DIRS:
				var n: Vector2i = c + d
				if prev.has(n) or walls.has(n) or not level.call("_is_inside_maze", n):
					continue
				if cells.has(n) and n != cells[-1]:
					continue
				prev[n] = c
				queue.append(n)
		if not bool(level.get("is_busy")):
			if found != null:
				var step: Vector2i = found
				while prev[step] != head:
					step = prev[step]
				if not level.call("_is_spin_blocked", step):
					level.call("_try_move", step - head)
			else:
				level.call("_try_move", -(level.get("facing") as Vector2i))
		level.call("_process", 0.05)
		t += 0.05
	_check((level.get("win_panel") as Control).visible, "the rings level can be finished (fruit left: %d)" % int(level.get("_required_fruits_left")))
	level.free()
