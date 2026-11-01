class_name BushShapes
extends RefCounted
## Library of bush formations for grid levels.
##
## Every generator returns absolute grid cells. Levels describe formations as
## small dictionaries and stamp them with `build(spec)`, for example:
##   {"shape": "ring", "at": Vector2i(10, 15), "radius": 4.2, "gaps": [90.0]}
##   {"shape": "cross", "at": Vector2i(5, 25), "arm": 2, "wall": "rock"}
##   {"shape": "pattern", "at": Vector2i(2, 3), "rows": ["#.#", ".#.", "#.#"]}
## Angles are in degrees, measured from +x (right) towards +y (down the map).

const SHAPES := ["line", "rect", "box", "disc", "ring", "arc", "cross", "diamond", "spiral", "zigzag", "pattern"]

static func build(spec: Dictionary) -> Array[Vector2i]:
	var at: Vector2i = spec.get("at", Vector2i.ZERO)
	var shape := String(spec.get("shape", ""))
	match shape:
		"line":
			return line(at, spec.get("to", at))
		"rect":
			return rect(at, spec.get("size", Vector2i(3, 3)), true)
		"box":
			return rect(at, spec.get("size", Vector2i(3, 3)), false)
		"disc":
			return disc(at, float(spec.get("radius", 2.0)))
		"ring":
			return ring(at, float(spec.get("radius", 3.0)), spec.get("gaps", []), float(spec.get("gap_cells", 2.0)))
		"arc":
			return arc(at, float(spec.get("radius", 3.0)), float(spec.get("from_deg", 0.0)), float(spec.get("to_deg", 180.0)))
		"cross":
			return cross(at, int(spec.get("arm", 2)))
		"diamond":
			return diamond(at, int(spec.get("radius", 2)), bool(spec.get("filled", false)))
		"spiral":
			return spiral(at, int(spec.get("turns", 2)))
		"zigzag":
			return zigzag(at, int(spec.get("length", 6)), int(spec.get("amplitude", 2)), bool(spec.get("vertical", false)))
		"pattern":
			return pattern(at, spec.get("rows", []), String(spec.get("char", "#")))
	push_error("BushShapes: unknown shape '%s' (known: %s)" % [shape, ", ".join(SHAPES)])
	return []

## Straight or diagonal line between two cells (inclusive).
static func line(from_cell: Vector2i, to_cell: Vector2i) -> Array[Vector2i]:
	var out: Array[Vector2i] = []
	var steps := maxi(absi(to_cell.x - from_cell.x), absi(to_cell.y - from_cell.y))
	for i in range(steps + 1):
		var t := 0.0 if steps == 0 else float(i) / float(steps)
		var cell := Vector2i(roundi(lerpf(from_cell.x, to_cell.x, t)), roundi(lerpf(from_cell.y, to_cell.y, t)))
		if not out.has(cell):
			out.append(cell)
	return out

## Rectangle with its top-left corner at `origin`; hollow when `filled` is false.
static func rect(origin: Vector2i, size: Vector2i, filled: bool = true) -> Array[Vector2i]:
	var out: Array[Vector2i] = []
	for y in range(size.y):
		for x in range(size.x):
			var edge := x == 0 or y == 0 or x == size.x - 1 or y == size.y - 1
			if filled or edge:
				out.append(origin + Vector2i(x, y))
	return out

static func disc(center: Vector2i, radius: float) -> Array[Vector2i]:
	var out: Array[Vector2i] = []
	var r := ceili(radius)
	for y in range(-r, r + 1):
		for x in range(-r, r + 1):
			if Vector2(x, y).length() <= radius + 0.01:
				out.append(center + Vector2i(x, y))
	return out

## Cells within half a cell of the circle. The band is always a closed barrier
## for 4-direction movement. Keep neighbouring rings about 2.2 cells apart
## (e.g. 2.0, 4.2, 6.4) so the walking track between them stays connected.
static func ring_cells(center: Vector2i, radius: float) -> Array[Vector2i]:
	var out: Array[Vector2i] = []
	var r := ceili(radius + 0.5)
	for y in range(-r, r + 1):
		for x in range(-r, r + 1):
			if absf(Vector2(x, y).length() - radius) < 0.5:
				out.append(center + Vector2i(x, y))
	return out

## A ring with optional openings. `gaps_deg` lists gap centres in degrees and
## `gap_cells` is the opening width measured along the ring.
static func ring(center: Vector2i, radius: float, gaps_deg: Array = [], gap_cells: float = 2.0) -> Array[Vector2i]:
	var out: Array[Vector2i] = []
	var half := gap_cells * 0.5 / maxf(radius, 0.5)
	for cell in ring_cells(center, radius):
		var a := cell_angle(center, cell)
		var in_gap := false
		for g in gaps_deg:
			if absf(angle_difference(deg_to_rad(float(g)), a)) <= half:
				in_gap = true
				break
		if not in_gap:
			out.append(cell)
	return out

## Part of a ring going clockwise on screen from `from_deg` to `to_deg`.
static func arc(center: Vector2i, radius: float, from_deg: float, to_deg: float) -> Array[Vector2i]:
	var out: Array[Vector2i] = []
	var start := deg_to_rad(from_deg)
	var span := fposmod(deg_to_rad(to_deg) - start, TAU)
	for cell in ring_cells(center, radius):
		if fposmod(cell_angle(center, cell) - start, TAU) <= span:
			out.append(cell)
	return out

static func cross(center: Vector2i, arm: int) -> Array[Vector2i]:
	var out: Array[Vector2i] = [center]
	for i in range(1, arm + 1):
		for d in [Vector2i.UP, Vector2i.DOWN, Vector2i.LEFT, Vector2i.RIGHT]:
			out.append(center + d * i)
	return out

static func diamond(center: Vector2i, radius: int, filled: bool = false) -> Array[Vector2i]:
	var out: Array[Vector2i] = []
	for y in range(-radius, radius + 1):
		for x in range(-radius, radius + 1):
			var d := absi(x) + absi(y)
			if d == radius or (filled and d < radius):
				out.append(center + Vector2i(x, y))
	return out

## Square spiral wall with a one-cell corridor between its arms.
static func spiral(center: Vector2i, turns: int) -> Array[Vector2i]:
	var out: Array[Vector2i] = []
	var pos := center
	var dir := Vector2i.RIGHT
	var length := 2
	for i in range(turns * 4):
		for _s in range(length):
			if not out.has(pos):
				out.append(pos)
			pos += dir
		dir = Vector2i(-dir.y, dir.x)
		if i % 2 == 1:
			length += 2
	return out

static func zigzag(start: Vector2i, length: int, amplitude: int, vertical: bool = false) -> Array[Vector2i]:
	var out: Array[Vector2i] = []
	var period := maxi(amplitude, 1) * 2
	for i in range(length):
		var phase := i % period
		var offset := phase if phase <= amplitude else period - phase
		var cell := start + (Vector2i(offset, i) if vertical else Vector2i(i, offset))
		out.append(cell)
	return out

## ASCII stamp: every `wall_char` becomes a cell, anything else is skipped.
static func pattern(origin: Vector2i, rows: Array, wall_char: String = "#") -> Array[Vector2i]:
	var out: Array[Vector2i] = []
	for y in rows.size():
		var row := String(rows[y])
		for x in row.length():
			if row[x] == wall_char:
				out.append(origin + Vector2i(x, y))
	return out

## Cells of a square ring `size` cells from the centre, in clockwise order on
## screen starting at the top-left corner. Neighbouring entries share an edge.
static func square_ring_cells(center: Vector2i, size: int) -> Array[Vector2i]:
	var out: Array[Vector2i] = []
	var k := maxi(size, 1)
	for j in 2 * k:
		out.append(center + Vector2i(-k + j, -k))
	for j in 2 * k:
		out.append(center + Vector2i(k, -k + j))
	for j in 2 * k:
		out.append(center + Vector2i(k - j, k))
	for j in 2 * k:
		out.append(center + Vector2i(-k, k - j))
	return out

static func cell_angle(center: Vector2i, cell: Vector2i) -> float:
	return atan2(float(cell.y - center.y), float(cell.x - center.x))

static func translate(cells: Array[Vector2i], offset: Vector2i) -> Array[Vector2i]:
	var out: Array[Vector2i] = []
	for cell in cells:
		out.append(cell + offset)
	return out

## Mirror horizontally around column `axis_x` (useful for symmetric gardens).
static func mirror_x(cells: Array[Vector2i], axis_x: int) -> Array[Vector2i]:
	var out: Array[Vector2i] = []
	for cell in cells:
		out.append(Vector2i(2 * axis_x - cell.x, cell.y))
	return out
