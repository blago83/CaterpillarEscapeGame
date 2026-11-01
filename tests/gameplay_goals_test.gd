extends SceneTree

const Level3DScene := preload("res://scenes/Level3D.tscn")

var _failures := 0

func _initialize() -> void:
	call_deferred("_run_tests")

func _run_tests() -> void:
	var level := Level3DScene.instantiate() as Node3D
	root.add_child(level)
	level.set_process(false)
	level.set("_snd_move", null)
	level.set("_snd_leaf", null)
	level.set("_snd_portal", null)

	_test_level_setup(level)
	_test_intro_and_timer(level)
	_test_combo(level)
	_test_golden_fruit(level)
	_test_exit_opens(level)
	_test_stars_and_win(level)
	_test_every_level_starts_safely(level)

	level.free()
	if _failures == 0:
		print("Gameplay goal regression checks passed.")
	else:
		printerr("%d gameplay check(s) failed." % _failures)
	quit(1 if _failures else 0)

func _check(condition: bool, message: String) -> bool:
	if not condition:
		_failures += 1
		printerr("FAIL: ", message)
	return condition

func _test_level_setup(level: Node3D) -> void:
	var goal := level.get("_goal_label") as Label
	_check(goal != null and goal.text.begins_with("GOAL:"), "goal banner explains the objective")
	_check((level.get("hud_label") as Label).text.contains("Fruit 0/"), "HUD shows fruit progress")
	_check(int(level.get("_required_total")) > 0, "level has fruit to collect")
	var par: float = level.get("_par_time")
	_check(par > 20.0 and par < 600.0, "star time is reasonable (%.0f s)" % par)
	var guide := level.get("_guide_arrow") as Node3D
	var guide_target: Vector2i = level.get("_guide_target")
	var leaves: Dictionary = level.get("leaves")
	_check(guide != null and leaves.has(guide_target), "guide arrow points at a fruit")
	var buttons := 0
	for node in level.get_node("CanvasLayer/HUD").find_children("*", "Button", true, false):
		if (node as Button).focus_mode == Control.FOCUS_NONE:
			buttons += 1
	_check(buttons >= 5, "on-screen arrow pad and BITE button exist")

func _test_intro_and_timer(level: Node3D) -> void:
	var intro := level.get("_intro_panel") as Control
	_check(bool(level.get("_intro_active")) and intro.visible, "intro card is shown on the first load")
	level.call("_process_dynamics", 1.0)
	_check(is_zero_approx(float(level.get("_level_time"))), "timer waits while the intro is open")
	level.call("_dismiss_intro")
	_check(not intro.visible and not bool(level.get("_intro_active")), "intro card can be dismissed")
	level.call("_process_dynamics", 1.0)
	_check(is_equal_approx(float(level.get("_level_time")), 1.0), "timer runs during play")
	level.call("load_level", level.get("current_level"))
	_check(not bool(level.get("_intro_active")), "retrying the same level skips the intro")

func _test_combo(level: Node3D) -> void:
	level.call("_on_fruit_eaten")
	level.call("_on_fruit_eaten")
	_check(int(level.get("_leaf_combo_count")) == 2, "two quick fruits make a combo")
	_check(int(level.get("_score")) == 300, "combo doubles the second fruit's points")
	_check(float(level.get("_combo_speed_timer")) > 0.0, "combo gives a speed boost")
	level.call("_process_dynamics", 6.0)
	_check(int(level.get("_leaf_combo_count")) == 0, "combo resets after its window")

func _test_golden_fruit(level: Node3D) -> void:
	level.call("load_level", level.get("current_level"))
	level.call("_spawn_golden_fruit")
	var cell: Vector2i = level.get("_golden_cell")
	if not _check(level.get("_golden_node") != null, "golden fruit spawns"):
		return
	var dist: Dictionary = level.call("_bfs_distances", level.get("player_cell"))
	var steps := int(dist.get(cell, -1))
	_check(steps >= 3 and steps <= 7, "golden fruit drops a few steps away (%d)" % steps)
	level.call("_check_golden_fruit", cell)
	_check(level.get("_golden_node") == null and int(level.get("_golden_eaten")) == 1, "golden fruit is collected")
	_check(int(level.get("_score")) == 500, "golden fruit is worth 500")

	level.call("_spawn_golden_fruit")
	level.call("_process_dynamics", 11.0)
	_check(level.get("_golden_node") == null, "uncollected golden fruit fades away")

func _test_exit_opens(level: Node3D) -> void:
	level.call("load_level", level.get("current_level"))
	var exit_node := level.get("exit_node") as Node
	_check(not bool(exit_node.get_meta("open", false)), "portal starts closed")
	level.set("_required_fruits_left", 0)
	level.call("_update_exit_state")
	_check(bool(exit_node.get_meta("open", false)), "portal opens once the fruit goal is done")
	_check(level.get("_guide_target") == level.get("exit_cell"), "guide arrow switches to the portal")
	_check(String(level.call("_objective_status_text")).contains("portal"), "goal banner points to the portal")

func _test_stars_and_win(level: Node3D) -> void:
	level.set("_level_time", 1.0)
	level.set("_hits_taken", 0)
	_check(int(level.call("_star_rating")) == 3, "fast and unhurt earns 3 stars")
	level.set("_hits_taken", 1)
	_check(int(level.call("_star_rating")) == 2, "getting hurt costs a star")
	level.set("_level_time", float(level.get("_par_time")) + 1.0)
	_check(int(level.call("_star_rating")) == 1, "finishing always earns 1 star")
	level.call("_win")
	_check((level.get("win_panel") as Control).visible, "win panel opens")
	var stats := level.get("_win_stats") as Label
	_check(stats != null and stats.text.contains("For 3 stars"), "win panel explains how to get 3 stars")

func _test_every_level_starts_safely(level: Node3D) -> void:
	var levels: Array = level.get("LEVELS")
	for i in levels.size():
		level.call("load_level", i)
		var hazards: Dictionary = level.get("hazards")
		var cells: Array = level.get("segment_cells")
		var spawn: Vector2i = cells[-1]
		for cell in hazards.keys():
			if String(hazards[cell]) == "spider":
				var d := absi(cell.x - spawn.x) + absi(cell.y - spawn.y)
				_check(d > 5, "level %d: no spider right next to the spawn (%s)" % [i + 1, cell])
		for cell in cells:
			_check(not hazards.has(cell), "level %d: caterpillar does not start on a hazard" % (i + 1))
		if i > 0:
			_check(bool(level.get("_intro_active")), "level %d shows its intro card" % (i + 1))
