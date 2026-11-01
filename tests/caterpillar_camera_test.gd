extends SceneTree

const Segment3DScript := preload("res://scripts/segment_3d.gd")
const Level3DScene := preload("res://scenes/Level3D.tscn")

var _failures := 0

func _initialize() -> void:
	call_deferred("_run_tests")

func _run_tests() -> void:
	_test_foot_motion("body", 1.0 / 60.0)
	_test_foot_motion("body", 1.0 / 30.0)
	_test_foot_motion("tail", 1.0 / 60.0)
	_test_segment_type_changes()
	_test_campaign_camera()
	if _failures == 0:
		print("Caterpillar and camera regression checks passed.")
	else:
		printerr("%d regression check(s) failed." % _failures)
	quit(1 if _failures else 0)

func _check(condition: bool, message: String) -> bool:
	if not condition:
		_failures += 1
		printerr("FAIL: ", message)
	return condition

func _make_segment(seg_type: String) -> Node3D:
	var segment: Node3D = Segment3DScript.new()
	segment.set_meta("seg_type", seg_type)
	segment.set_meta("seg_index", 1)
	root.add_child(segment)
	segment.set_process(false)
	return segment

func _test_foot_motion(seg_type: String, delta: float) -> void:
	var segment := _make_segment(seg_type)
	var left := segment.get("_foot_left") as MeshInstance3D
	var right := segment.get("_foot_right") as MeshInstance3D
	if not _check(left != null and right != null, "%s has both feet" % seg_type):
		segment.free()
		return

	var left_rest := left.position
	var right_rest := right.position
	var max_sideways := 0.0
	var min_lift := 0.0
	var max_lift := 0.0
	var max_stride := 0.0
	var saw_left_step := false
	var saw_right_step := false
	var frames := int(20.0 / delta)
	var frames_per_step := int(0.2 / delta)
	for frame in range(frames):
		if frame % frames_per_step == 0:
			segment.call("wiggle_legs")
		if frame == frames / 2:
			segment.rotation.y = PI / 2.0
		segment.call("_process", delta)
		for offset in [left.position - left_rest, right.position - right_rest]:
			max_sideways = maxf(max_sideways, absf(offset.x))
			min_lift = minf(min_lift, offset.y)
			max_lift = maxf(max_lift, offset.y)
			max_stride = maxf(max_stride, absf(offset.z))
		var left_stride := left.position.z - left_rest.z
		var right_stride := right.position.z - right_rest.z
		saw_left_step = saw_left_step or (left_stride > 0.01 and right_stride < -0.01)
		saw_right_step = saw_right_step or (right_stride > 0.01 and left_stride < -0.01)

	var context := "%s at %.0f FPS" % [seg_type, 1.0 / delta]
	_check(max_sideways <= 0.017, "%s feet stay attached laterally (%.3f)" % [context, max_sideways])
	_check(min_lift >= -0.001 and max_lift <= 0.031, "%s feet stay at their own resting height" % context)
	_check(max_stride <= 0.046, "%s feet stay within their stride" % context)
	_check(saw_left_step and saw_right_step and max_lift > 0.005, "%s feet retain their alternating walk" % context)

	for frame in range(int(3.0 / delta)):
		segment.call("_process", delta)
	_check(left.position.distance_to(left_rest) < 0.001, "%s left foot returns to rest" % context)
	_check(right.position.distance_to(right_rest) < 0.001, "%s right foot returns to rest" % context)

	segment.call("wiggle_legs")
	segment.call("_process", 0.25)
	_check(absf(left.position.x - left_rest.x) <= 0.017, "%s foot stays attached after a frame hitch" % context)
	_check(absf(right.position.x - right_rest.x) <= 0.017, "%s other foot stays attached after a frame hitch" % context)
	var mesh := segment.get("_mesh") as MeshInstance3D
	var mesh_rest: float = segment.get("_base_mesh_y")
	_check(absf(mesh.position.y - mesh_rest) <= 0.066, "%s body stays near its resting height after a frame hitch" % context)
	segment.free()

func _shoe_width(shoe: Node3D) -> float:
	var shoe_body := shoe.get_child(0) as MeshInstance3D
	var shoe_mesh := shoe_body.mesh as BoxMesh
	return shoe_mesh.size.x

func _test_segment_type_changes() -> void:
	var segment := _make_segment("tail")
	segment.call("set_shoes_active", true)
	var left := segment.get("_foot_left") as MeshInstance3D
	var right := segment.get("_foot_right") as MeshInstance3D
	var shoe := segment.get("_shoe_left") as Node3D
	var right_shoe := segment.get("_shoe_right") as Node3D
	if _check(shoe != null and right_shoe != null, "both tail shoes are created"):
		_check(is_equal_approx(_shoe_width(shoe), 0.16 * 0.9), "tail shoe uses the smaller size")
		_check(shoe.position.is_equal_approx(left.position + Vector3(0.0, 0.01, 0.01)), "new shoe starts at the foot")
		_check(right_shoe.position.is_equal_approx(right.position + Vector3(0.0, 0.01, 0.01)), "other new shoe starts at the foot")
		segment.call("wiggle_legs")
		segment.call("_process", 1.0 / 30.0)
		_check(shoe.position.is_equal_approx(left.position + Vector3(0.0, 0.01, 0.01)), "shoe follows the animated foot")
		_check(right_shoe.rotation.is_equal_approx(right.rotation), "other shoe follows the animated foot's rotation")
		segment.call("set_shoes_active", false)
		_check(not shoe.visible and not right_shoe.visible, "shoes can be hidden")
		segment.call("set_shoes_active", true)
		_check(shoe.visible and right_shoe.visible, "shoes can be shown again")

	segment.call("update_seg_type", "body")
	left = segment.get("_foot_left") as MeshInstance3D
	shoe = segment.get("_shoe_left") as Node3D
	if _check(left != null and shoe != null and shoe.visible, "tail-to-body keeps both feet and active shoes"):
		_check(left.position.is_equal_approx(Vector3(-0.21, -0.21, -0.02)), "tail-to-body resets foot attachment")
		_check(is_equal_approx((left.mesh as SphereMesh).radius, 0.085), "tail-to-body resizes foot")
		_check(is_equal_approx(_shoe_width(shoe), 0.18 * 0.9), "tail-to-body resizes shoe")

	segment.call("update_seg_type", "head")
	_check(segment.get("_foot_left") == null and segment.get("_foot_right") == null, "head has no body feet")
	segment.call("update_seg_type", "body")
	left = segment.get("_foot_left") as MeshInstance3D
	shoe = segment.get("_shoe_left") as Node3D
	_check(left != null and shoe != null and shoe.visible, "head-to-body restores feet and active shoes")
	segment.free()

func _test_campaign_camera() -> void:
	var level := Level3DScene.instantiate() as Node3D
	root.add_child(level)
	level.set_process(false)
	var segments: Array = level.get("segment_nodes")
	var head := segments[0] as Node3D
	var cam := level.get_node("Camera3D") as Camera3D
	var target: Vector3 = level.get("_cam_look_target")
	var head_cell: Vector2i = level.get("player_cell")
	_check(head.position.is_equal_approx(level.call("_pos", head_cell)), "player_cell is the actual head")
	var head_target: Vector3 = level.call("_head_cam_target", head_cell)
	_check(target.is_equal_approx(head_target), "campaign camera initially aims at the actual head (clamped to the maze)")
	var maze_w: int = level.get("_maze_w")
	var maze_h: int = level.get("_maze_h")
	_check(target.x >= -0.01 and target.x <= maze_w - 0.99 and target.z >= -0.01 and target.z <= maze_h - 0.99, "camera target stays inside the maze")
	# Far corners must clamp so no void outside the maze is shown.
	var corner: Vector3 = level.call("_head_cam_target", Vector2i(0, maze_h - 1))
	_check(corner.x > 0.5 and corner.z < maze_h - 1.5, "camera clamps at the maze corner")

	var to_cam := cam.position - target
	var pitch := rad_to_deg(atan2(to_cam.y, Vector2(to_cam.x, to_cam.z).length()))
	_check(pitch >= 58.0 and pitch <= 66.0, "campaign camera looks down with a clear tilt")
	_check(absf(to_cam.x) < 0.001, "campaign camera is vertically aligned (no sideways skew)")
	_check(is_equal_approx(cam.fov, 50.0), "campaign camera uses the near top-down field of view")
	var camera_offset := Vector3(0.0, 14.0, 7.2)

	var next_cell: Vector2i = level.get("player_cell") + Vector2i.UP
	var leaves: Dictionary = level.get("leaves")
	var forward_leaf := Node3D.new()
	level.add_child(forward_leaf)
	leaves[next_cell] = forward_leaf
	# Audio playback is unrelated to the camera fixture and can outlive it.
	level.set("_snd_move", null)
	level.set("_snd_leaf", null)
	level.call("_move_to", next_cell)
	target = level.get("_cam_look_target")
	_check(target.is_equal_approx(level.call("_head_cam_target", next_cell)), "campaign camera follows the moving head")
	for frame in range(30):
		level.call("_process", 1.0 / 60.0)
	_check((cam.position - target).distance_to(camera_offset) < 0.01, "campaign camera smoothly approaches its moving target")
	segments = level.get("segment_nodes")
	var former_tail := segments[-2] as Node3D
	var body_foot := former_tail.get("_foot_left") as MeshInstance3D
	if _check(body_foot != null, "forward growth keeps feet on the former tail"):
		_check(is_equal_approx((body_foot.mesh as SphereMesh).radius, 0.085), "forward growth gives the former tail body-sized feet")

	var cells: Array[Vector2i] = []
	for x in range(6, 0, -1):
		cells.append(Vector2i(x, 10))
	level.set("segment_cells", cells)
	var walls: Dictionary = level.get("wall_set")
	walls.clear()
	level.call("_rebuild_caterpillar")
	var reverse_leaf := Node3D.new()
	level.add_child(reverse_leaf)
	leaves[Vector2i(0, 10)] = reverse_leaf
	level.call("_move_backward")
	segments = level.get("segment_nodes")
	var former_head := segments[1] as Node3D
	_check(former_head.get("_foot_left") != null and former_head.get("_foot_right") != null, "reverse growth adds feet to the former head")
	cells = level.get("segment_cells")
	target = level.get("_cam_look_target")
	_check(level.get("player_cell") == cells[0], "player_cell follows the new head after reverse growth")
	_check(target.is_equal_approx(level.call("_head_cam_target", cells[0])), "camera follows the new head after reverse growth")
	level.call("_process", 0.1)
	_check((cam.position - target).distance_to(camera_offset) < 0.01, "camera approaches the new head after reverse growth")
	level.free()
