extends SceneTree

const Level3DScene := preload("res://scenes/Level3D.tscn")
const WALKING_SOUND := "res://assets/sounds/06_funky_cartoon_steps.wav"

var _failures := 0

func _initialize() -> void:
	call_deferred("_run_tests")

func _check(condition: bool, message: String) -> bool:
	if not condition:
		_failures += 1
		printerr("FAIL: ", message)
	return condition

func _run_tests() -> void:
	var level := Level3DScene.instantiate() as Node3D
	root.add_child(level)
	level.set_process(false)
	var walking := level.get("_snd_move") as AudioStreamPlayer
	if not _check(walking != null and walking.stream != null, "walking audio loads"):
		level.free()
		quit(1)
		return

	_check(walking.stream.resource_path == WALKING_SOUND, "walking uses the supplied WAV")
	_check(not walking.playing, "walking audio is initially stopped")

	var first_cell: Vector2i = level.get("player_cell") + Vector2i.UP
	level.call("_move_to", first_cell)
	_check(walking.playing, "forward movement starts walking audio")
	await create_timer(0.6).timeout
	var previous_position := walking.get_playback_position()
	_check(previous_position > 0.1, "walking audio advances during a step")
	level.call("_move_to", first_cell + Vector2i.UP)
	await create_timer(0.2).timeout
	_check(walking.get_playback_position() > previous_position + 0.03, "consecutive steps do not restart the clip")

	var finished_count := [0]
	walking.finished.connect(func() -> void: finished_count[0] += 1)
	walking.seek(walking.stream.get_length() - 0.08)
	await create_timer(0.35).timeout
	_check(finished_count[0] > 0, "the walking clip reaches its end")
	_check(walking.playing, "the clip repeats while movement continues")

	level.call("_process", 0.5)
	_check(not walking.playing, "walking audio stops when movement finishes")
	var walls: Dictionary = level.get("wall_set")
	var cells: Array[Vector2i] = level.get("segment_cells")
	walls[cells[0] + Vector2i.RIGHT] = true
	level.set("is_busy", false)
	level.set("facing", Vector2i.RIGHT)
	level.call("_try_move", Vector2i.RIGHT)
	_check(not walking.playing, "a blocked movement does not start walking audio")

	cells.clear()
	for x in range(5, 0, -1):
		cells.append(Vector2i(x, 10))
	walls.clear()
	level.call("_rebuild_caterpillar")
	level.set("is_busy", false)
	level.set("facing", Vector2i.RIGHT)
	level.call("_try_move", Vector2i.LEFT)
	_check(walking.playing, "reverse movement starts walking audio")
	if not walking.playing:
		cells = level.get("segment_cells")
		level.call("_move_to", cells[0] + Vector2i.UP)
	level.call("load_level", 0)
	_check(not walking.playing, "restarting the level stops walking audio")
	_check(is_zero_approx(level.get("_move_anim_remaining")), "restarting the level clears movement")

	walking.stop()
	await create_timer(0.2).timeout
	level.free()
	await process_frame
	if _failures == 0:
		print("Walking audio regression checks passed.")
	else:
		printerr("%d walking audio check(s) failed." % _failures)
	quit(1 if _failures else 0)
