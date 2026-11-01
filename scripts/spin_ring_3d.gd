extends Node3D
## A square ring of bush blocks around a grid cell that turns like a conveyor.
##
## The ring's cells are listed clockwise (BushShapes.square_ring_cells). The
## block pattern moves one cell along that list every `step_time` seconds, so
## the gaps travel around the ring. Blocks slide smoothly between cells. Biting
## holds the ring still, and enough bites on one block remove it for good.
## Blocks over cells the caterpillar's body is squeezing through are hidden.
## Each block shows an arrow for the way it moves, and the floor under every gap
## glows (brighter and pulsing while it lines up with a gap in the next ring).

const BushShapesScript := preload("res://scripts/bush_shapes.gd")

const BITES_FOR_GAP := 3
const SLIDE_TIME := 0.18
const BLOCK_SCALE := 0.9
const GAP_GLOW := Color(1.0, 0.97, 0.78, 0.7)
const ALIGNED_GLOW := Color(0.1, 0.75, 1.0, 0.95)
const ARROW_COLOR := Color(0.55, 0.3, 0.05)

var center_cell := Vector2i.ZERO
var size := 2
var dir := 1              # +1 turns clockwise on screen, -1 the other way
var step_time := 0.6      # seconds per one-cell step
var step_timer := 0.0
var hold_timer := 0.0     # > 0 while a bite holds the ring still
var offset := 0           # how many cells the pattern has moved
var cells: Array[Vector2i] = []
var pattern: Array[bool] = []          # true = block, in the ring's own frame
var bite_counts: Dictionary = {}       # pattern index -> bites so far

var _index: Dictionary = {}            # cell -> position in `cells`
var _hidden: Dictionary = {}           # cell -> true
var _slide := 0.0                      # 1 right after a step, eases to 0
var _cell_size := 1.0
var _height := 0.45
var _mm: MultiMesh = null
var _arrow_mm: MultiMesh = null
var _glow_mm: MultiMesh = null
var _aligned: Dictionary = {}          # cell -> true while its gap lines up
var _time := 0.0

func setup(p_center: Vector2i, spec: Dictionary, cell_size: float) -> void:
	center_cell = p_center
	size = int(spec.get("size", 2))
	dir = 1 if int(spec.get("dir", 1)) >= 0 else -1
	step_time = maxf(float(spec.get("step_time", 0.6)), 0.1)
	offset = int(spec.get("start", 0))
	_cell_size = cell_size
	cells = BushShapesScript.square_ring_cells(center_cell, size)
	_index.clear()
	for i in cells.size():
		_index[cells[i]] = i
	pattern.clear()
	pattern.resize(cells.size())
	pattern.fill(true)
	var width := maxi(int(spec.get("gap_cells", 2)), 1)
	for g in spec.get("gaps", [0]):
		for w in width:
			pattern[posmod(int(g) + w, cells.size())] = false
	bite_counts.clear()

func owns(cell: Vector2i) -> bool:
	return _index.has(cell)

func _pattern_index(cell: Vector2i, at_offset: int) -> int:
	return posmod(int(_index[cell]) - at_offset, cells.size())

func is_blocked(cell: Vector2i, at_offset: int = -2147483648) -> bool:
	if not _index.has(cell):
		return false
	var off := offset if at_offset == -2147483648 else at_offset
	return pattern[_pattern_index(cell, off)]

func next_offset() -> int:
	return offset + dir

## The cell a gap at `cell` moves into on the next step.
func next_cell(cell: Vector2i) -> Vector2i:
	return cells[posmod(int(_index[cell]) + dir, cells.size())]

func step() -> void:
	offset = next_offset()
	_slide = 1.0
	_update_blocks()

func animate(delta: float) -> void:
	_time += delta
	if _slide <= 0.0:
		if not _aligned.is_empty():
			_update_glow()
		return
	_slide = maxf(_slide - delta / SLIDE_TIME, 0.0)
	_update_blocks()

## Open cells whose gap currently lines up with a gap in a neighbouring ring.
## Cells that are not part of this ring (the track in between) light up too.
func set_aligned_cells(aligned: Array[Vector2i]) -> void:
	var next := {}
	for cell in aligned:
		next[cell] = true
	if next.hash() == _aligned.hash():
		return
	_aligned = next
	_update_glow()

func is_aligned(cell: Vector2i) -> bool:
	return _aligned.has(cell)

## Direction a block on `cell` moves on the next step.
func move_dir(cell: Vector2i) -> Vector2i:
	return next_cell(cell) - cell

## Registers a bite on the block in front of the caterpillar.
## Returns true when the bites removed the block.
func add_bite(cell: Vector2i) -> bool:
	if not is_blocked(cell):
		return false
	var idx := _pattern_index(cell, offset)
	var bites := int(bite_counts.get(idx, 0)) + 1
	if bites >= BITES_FOR_GAP:
		pattern[idx] = false
		bite_counts.erase(idx)
		_update_blocks()
		return true
	bite_counts[idx] = bites
	_update_blocks()
	return false

func set_hidden_cells(hidden: Array[Vector2i]) -> void:
	var next := {}
	for cell in hidden:
		next[cell] = true
	if next.hash() == _hidden.hash():
		return
	_hidden = next
	_update_blocks()

func build_visual(body_mesh: Mesh, body_mat: Material, height: float) -> void:
	_height = height
	for child in get_children():
		child.queue_free()
	_mm = MultiMesh.new()
	_mm.transform_format = MultiMesh.TRANSFORM_3D
	_mm.use_colors = true
	_mm.mesh = body_mesh
	var inst := MultiMeshInstance3D.new()
	inst.multimesh = _mm
	inst.material_override = body_mat
	inst.cast_shadow = GeometryInstance3D.SHADOW_CASTING_SETTING_OFF
	add_child(inst)
	_arrow_mm = _make_overlay(_arrow_mesh(), false)
	_glow_mm = _make_overlay(_glow_mesh(), true)
	_update_blocks()

func _make_overlay(mesh: Mesh, transparent: bool) -> MultiMesh:
	var mm := MultiMesh.new()
	mm.transform_format = MultiMesh.TRANSFORM_3D
	mm.use_colors = true
	mm.mesh = mesh
	var mat := StandardMaterial3D.new()
	mat.shading_mode = BaseMaterial3D.SHADING_MODE_UNSHADED
	mat.vertex_color_use_as_albedo = true
	mat.cull_mode = BaseMaterial3D.CULL_DISABLED
	if transparent:
		mat.transparency = BaseMaterial3D.TRANSPARENCY_ALPHA
	var inst := MultiMeshInstance3D.new()
	inst.multimesh = mm
	inst.material_override = mat
	inst.cast_shadow = GeometryInstance3D.SHADOW_CASTING_SETTING_OFF
	add_child(inst)
	return mm

# Flat chevron pointing along +Z, sized for the top of a block.
func _arrow_mesh() -> Mesh:
	var w := _cell_size * 0.3
	var l := _cell_size * 0.32
	var t := _cell_size * 0.12
	var pts := [
		Vector3(-w, 0, -l * 0.5), Vector3(0, 0, l * 0.5), Vector3(0, 0, l * 0.5 - t * 1.6),
		Vector3(-w, 0, -l * 0.5), Vector3(0, 0, l * 0.5 - t * 1.6), Vector3(-w, 0, -l * 0.5 - t * 1.6),
		Vector3(w, 0, -l * 0.5), Vector3(0, 0, l * 0.5 - t * 1.6), Vector3(0, 0, l * 0.5),
		Vector3(w, 0, -l * 0.5), Vector3(w, 0, -l * 0.5 - t * 1.6), Vector3(0, 0, l * 0.5 - t * 1.6),
	]
	var st := SurfaceTool.new()
	st.begin(Mesh.PRIMITIVE_TRIANGLES)
	for p in pts:
		st.set_normal(Vector3.UP)
		st.add_vertex(p)
	return st.commit()

func _glow_mesh() -> Mesh:
	var plane := PlaneMesh.new()
	plane.size = Vector2(_cell_size * 0.92, _cell_size * 0.92)
	return plane

func _dir_basis(d: Vector2i) -> Basis:
	return Basis(Vector3.UP, atan2(float(d.x), float(d.y)))

# Where the thing drawn on ring position `i` sits right now (it slides in
# from the previous cell just after a step).
func _slot_pos(i: int, ease_t: float) -> Vector3:
	var pos := _cell_pos(cells[i])
	if ease_t > 0.0:
		pos = pos.lerp(_cell_pos(cells[posmod(i - dir, cells.size())]), ease_t)
	return pos

func _cell_pos(cell: Vector2i) -> Vector3:
	return Vector3(float(cell.x) * _cell_size, 0.0, float(cell.y) * _cell_size)

func _update_blocks() -> void:
	if _mm == null:
		return
	var n := cells.size()
	var xforms: Array[Transform3D] = []
	var arrows: Array[Transform3D] = []
	var ease_t := _slide * _slide
	for i in n:
		var cell := cells[i]
		var idx := posmod(i - offset, n)
		if not pattern[idx] or _hidden.has(cell):
			continue
		var pos := _slot_pos(i, ease_t)
		var shrink := 1.0 - 0.22 * float(bite_counts.get(idx, 0))
		var basis := Basis.IDENTITY.scaled(Vector3(BLOCK_SCALE, shrink, BLOCK_SCALE))
		pos.y = _height * 0.5 * shrink
		xforms.append(Transform3D(basis, pos))
		pos.y = _height * shrink + 0.012
		arrows.append(Transform3D(_dir_basis(move_dir(cell)), pos))
	_mm.instance_count = xforms.size()
	for i in xforms.size():
		_mm.set_instance_transform(i, xforms[i])
		_mm.set_instance_color(i, Color.WHITE)
	if _arrow_mm:
		_arrow_mm.instance_count = arrows.size()
		for i in arrows.size():
			_arrow_mm.set_instance_transform(i, arrows[i])
			_arrow_mm.set_instance_color(i, ARROW_COLOR)
	_update_glow()

func _aligned_color(pulse: float) -> Color:
	var c := ALIGNED_GLOW.lerp(Color(1, 1, 1, 1), 0.35 * (1.0 - pulse))
	c.a *= pulse
	return c

func _update_glow() -> void:
	if _glow_mm == null:
		return
	var n := cells.size()
	var ease_t := _slide * _slide
	var pulse := 0.75 + 0.25 * sin(_time * 9.0)
	var xforms: Array[Transform3D] = []
	var colors: Array[Color] = []
	for i in n:
		if pattern[posmod(i - offset, n)]:
			continue
		var pos := _slot_pos(i, ease_t)
		pos.y = 0.02
		xforms.append(Transform3D(Basis.IDENTITY, pos))
		if _aligned.has(cells[i]):
			colors.append(_aligned_color(pulse))
		else:
			colors.append(GAP_GLOW)
	for cell in _aligned:
		if not _index.has(cell):
			var pos := _cell_pos(cell)
			pos.y = 0.02
			xforms.append(Transform3D(Basis.IDENTITY, pos))
			colors.append(_aligned_color(pulse))
	_glow_mm.instance_count = xforms.size()
	for i in xforms.size():
		_glow_mm.set_instance_transform(i, xforms[i])
		_glow_mm.set_instance_color(i, colors[i])
