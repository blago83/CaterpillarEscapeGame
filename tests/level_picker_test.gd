extends SceneTree

const Level3DScript := preload("res://scripts/level_3d.gd")

var _failures := 0

func _initialize() -> void:
	call_deferred("_run_tests")

func _check(condition: bool, message: String) -> void:
	if not condition:
		_failures += 1
		printerr("FAIL: ", message)

func _run_tests() -> void:
	var menu := (load("res://scenes/MainMenu.tscn") as PackedScene).instantiate() as Control
	root.add_child(menu)
	var picker := menu.get("_picker") as Control
	_check(picker != null and not picker.visible, "level picker starts hidden")
	menu.get_node("Card/VBox/ChooseLevelButton").emit_signal("pressed")
	_check(picker.visible and not menu.get_node("Card").visible, "Choose Level opens the picker")
	var count := Level3DScript.LEVELS.size()
	for i in count:
		var btn := picker.find_child("Level%d" % (i + 1), true, false) as Button
		_check(btn != null, "picker has a button for level %d" % (i + 1))
	_check(String((picker.find_child("Level7", true, false) as Button).text).contains("Spinning Rings"), "rings level is named")
	picker.find_child("BackButton", true, false).emit_signal("pressed")
	_check(not picker.visible and menu.get_node("Card").visible, "Back returns to the menu")
	menu.call("_on_level_picked", 4)
	_check(Level3DScript.start_level == 4, "picking a level sets the start level")
	Level3DScript.start_level = -1
	menu.free()
	for i in count:
		_check_finish_gate(i)
	if _failures == 0:
		print("Level picker checks passed.")
	else:
		printerr("%d level picker check(s) failed." % _failures)
	quit(1 if _failures else 0)

# Every level's finish gate is a doorway in the top wall that the caterpillar can reach.
func _check_finish_gate(index: int) -> void:
	Level3DScript.start_level = index
	var level := (load("res://scenes/Level3D.tscn") as PackedScene).instantiate() as Node3D
	root.add_child(level)
	level.set_process(false)
	var walls: Dictionary = level.get("wall_set")
	var gate: Vector2i = level.get("exit_cell")
	var name := "level %d gate %s" % [index + 1, gate]
	_check(gate.y == 0, "%s sits in the top wall" % name)
	_check(walls.has(gate + Vector2i.LEFT) and walls.has(gate + Vector2i.RIGHT), "%s has wall on both sides" % name)
	_check(not walls.has(gate) and not walls.has(gate + Vector2i.DOWN), "%s opens into the maze" % name)
	var start: Vector2i = level.get("player_cell")
	var seen := {start: true}
	var queue: Array[Vector2i] = [start]
	var w := int(level.get("_maze_w"))
	var h := int(level.get("_maze_h"))
	while not queue.is_empty():
		var c: Vector2i = queue.pop_front()
		for d in [Vector2i.UP, Vector2i.DOWN, Vector2i.LEFT, Vector2i.RIGHT]:
			var n: Vector2i = c + d
			if n.x < 0 or n.y < 0 or n.x >= w or n.y >= h or seen.has(n) or walls.has(n):
				continue
			seen[n] = true
			queue.append(n)
	_check(seen.has(gate), "%s is reachable (ignoring biting and rings)" % name)
	_check(bool(level.call("_is_exit_locked", gate)), "%s is locked before the goal is met" % name)
	if index == 0:
		# Walk straight at the locked gate: the caterpillar must stop in front of it.
		var body: Array[Vector2i] = []
		for i in 5:
			body.append(gate + Vector2i(0, 1 + i))
			level.call("_force_cell_walkable", gate + Vector2i(0, 1 + i))
		level.set("segment_cells", body)
		level.set("player_cell", body[0])
		level.set("facing", Vector2i.UP)
		level.set("is_busy", false)
		level.set("_intro_active", false)
		level.call("_try_move", Vector2i.UP)
		_check((level.get("segment_cells") as Array)[0] == gate + Vector2i.DOWN, "caterpillar can't crawl into the locked gate")
	level.set("_required_fruits_left", 0)
	if bool(level.call("_objective_complete")):
		_check(not bool(level.call("_is_exit_locked", gate)), "%s unlocks once the goal is met" % name)
	level.free()
