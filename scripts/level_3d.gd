extends Node3D

const CELL := 1.0
const WALL_HEIGHT := 0.45
# Flat garden palette.
const GROUND_COLOR := Color(0.74, 0.87, 0.55)
const OUTER_GROUND_COLOR := Color(0.58, 0.76, 0.42)
const BUSH_TOP := Color(0.36, 0.67, 0.30)
const BUSH_BOTTOM := Color(0.23, 0.49, 0.21)
const ROCK_TOP := Color(0.78, 0.76, 0.70)
const ROCK_BOTTOM := Color(0.58, 0.56, 0.52)
# Fog of war (darkness). Disabled for the flat look: the whole maze is visible.
const FOG_ENABLED := false

# Camera offset from the look-at target.
# Near top-down view (~72° pitch) with a slight forward tilt.
const CAM_OFFSET := Vector3(0.0, 14.0, 7.2)
const CAM_FOV := 50.0
const CAM_LOOK_HEIGHT := 0.8
# How far past the outer fence (in cells) the camera may show.
const CAM_EDGE_MARGIN := 0.6
# Extra room above the top wall so the tall finish gate isn't hidden by the HUD.
const CAM_TOP_EXTRA := 1.4
# Screen space covered by the HUD (pixels of the 1080x1920 base layout).
const HUD_TOP_INSET := 230.0
const HUD_BOTTOM_INSET := 330.0
const REVEAL_RADIUS_BY_LEVEL := [6.0, 5.2, 4.2]

const FOG_HIDDEN := 0
const FOG_DISCOVERED := 1
const FOG_VISIBLE := 2

const LANTERN_BONUS_RADIUS := 2.4
const LANTERN_BONUS_SECONDS := 18.0
const GLOW_LEAF_RADIUS_BONUS := 0.5
const MAP_FLOWER_REVEAL_RADIUS := 4.0
const LEAF_COMBO_WINDOW := 5.0
const LEAF_COMBO_REVEAL_BONUS := 0.8
const LEAF_COMBO_REVEAL_SECONDS := 6.0
const LEAF_COMBO_SPEED_SECONDS := 4.0
const LEAF_COMBO_SPEED_MULT := 1.25
const FOG_TEX_SCALE := 1
const SHOE_SPEED_MULT := 1.45
const FRUIT_VARIANT_DIR := "res://assets/bonuses/meshy_split_fruits"
const FRUIT_VARIANT_COUNT := 5
const ROCK_WALL_RATIO := 0.80
const MIN_BUSH_WALLS := 12
const MUSHROOM_VARIANT_DIR := "res://assets/mushrooms"
const MUSHROOM_SIZE_MULT := 2.45
const SPIDER_MOVE_INTERVAL := 1.2
const SPIDER_CHASE_RADIUS := 4.0
const SPIDER_ROAM_MOVE_CHANCE := 0.5
const SPIDER_CHASE_MOVE_CHANCE := 0.75
const SPIDER_TRAVEL_TIME := 0.85
const SPAWN_SPIDER_CLEAR_STEPS := 5
const EXIT_CLEAR_RADIUS := 1
const EXIT_SAFE_SPAWN_RADIUS := 2
const PLAYER_SAFE_SPAWN_RADIUS := 6
const DOUBLE_WIDE_SIDE_SPIKE_CHANCE := 0.45
const WORMHOLE_PAIR_COUNT := 1
const WORMHOLE_MIN_PAIR_DISTANCE := 8
const WORMHOLE_TELEPORT_COOLDOWN := 0.45
const DIZZY_DURATION := 5.0
const DIZZY_SPEED_MULT := 0.55
const FRUIT_VARIANT_NAMES := ["Apple", "Cherry", "Peach", "Pear", "Grape"]
# Some levels can require specific fruit pickups as a win objective.
const LEVEL_FRUIT_OBJECTIVES := {
	3: {"apple": 1, "pear": 1},
	4: {"cherry": 1, "grape": 1},
	5: {"peach": 1, "grape": 1},
}

const Segment3DScript := preload("res://scripts/segment_3d.gd")
const Leaf3DScript := preload("res://scripts/leaf_3d.gd")
const Spider3DScript := preload("res://scripts/spider_3d.gd")
const Exit3DScript := preload("res://scripts/exit_portal_3d.gd")
const BushShapesScript := preload("res://scripts/bush_shapes.gd")
const SpinRing3DScript := preload("res://scripts/spin_ring_3d.gd")

# Bush formations stamped on top of a level's ASCII map (see scripts/bush_shapes.gd).
# "wall" is "bush" (biteable, default) or "rock"; "carve": true clears the cells instead.
const LEVEL_FORMATIONS := {
	6: [
		# Rock dividers: the top and bottom of the garden only meet through the rings.
		{"shape": "line", "at": Vector2i(1, 15), "to": Vector2i(3, 15), "wall": "rock"},
		{"shape": "line", "at": Vector2i(17, 15), "to": Vector2i(19, 15), "wall": "rock"},
	],
}
# Turning square bush rings. Each group shares a centre cell. `size` is the ring's
# distance from the centre in cells; keep sizes 2 apart (2, 4, 6) so a one-cell
# track runs between rings. Every `step_time` seconds the blocks move one cell
# (dir 1 = clockwise on screen, -1 = anticlockwise). `gaps` are positions along
# the ring, counted clockwise from its top-left corner, each `gap_cells` wide.
const LEVEL_SPINNERS := {
	6: [
		{"at": Vector2i(10, 15), "rings": [
			{"size": 2, "dir": 1, "step_time": 0.5, "gaps": [2, 10], "gap_cells": 2},
			{"size": 4, "dir": -1, "step_time": 0.7, "gaps": [3, 14, 25], "gap_cells": 2},
			{"size": 6, "dir": 1, "step_time": 0.9, "gaps": [4, 16, 28, 40], "gap_cells": 2},
		]},
	],
}
# Per-level switches for the random extras.
const LEVEL_OPTIONS := {
	6: {"random_spikes": false, "wormholes": false, "wide_roads": false, "mushrooms": false},
}
const SPIN_HINT_COOLDOWN := 4.0
const RING_TOP := Color(0.98, 0.78, 0.25)
const RING_SIDE := Color(0.82, 0.52, 0.12)
const NO_CELL := Vector2i(-9999, -9999)
const SPIN_PAR_SECONDS_PER_RING := 8.0

# Large mazes with consistent rectangular bounds.
# Legend: # wall, . path, P player, L leaf, S spider, ^ spike, E exit
const LEVELS := [
[
"#######################",
"#.....#.....#.....#...#",
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
"#P..#.#...S...#.....E.#",
"#######################",
],
[
"###########################",
"#.....#.......#.....#.....#",
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
"#P..#..............L...E..#",
"###########################",
],
[
"###############################",
"#.....#.......#.......#.......#",
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
"#P...S....L.....#.......L...E.#",
"###############################",
],
[
"#######################",
"#.....#.....#.....#...#",
"###.#.#.###.#.###.#.#.#",
"#...#.#...#...#...#.#.#",
"#.###.###.#####.###.#.#",
"#...#...#.....#...#.#.#",
"#.#.###.#####.###.#.#.#",
"#.#...#..^L...#...#...#",
"#.###.###.###.#.#####.#",
"#...#.....#...#.....#.#",
"###.#######.#######.#.#",
"#...#.....#.....#...#.#",
"#.###.###.#####.#.###.#",
"#.....#.#...#...#.^L#.#",
"#.#####.###.#.#####.#.#",
"#.#...#.....#...#...#.#",
"#.#.#.#########.#.###.#",
"#...#.....L.....#...#.#",
"#.#######.#########.#.#",
"#...#...#.....#.....#.#",
"###.#.#.#####.#.#####.#",
"#P..#.#...S..^#.....E##",
"#######################",
],
[
"###########################",
"#.....#.......#.....#.....#",
"###.#.#.#####.#.###.#.###.#",
"#...#.#.....#.#...#.#...#.#",
"#.###.#####.#.###.#.###.#.#",
"#.#...#...#.#...#.#...#...#",
"#.#.###.#.#.###.#.###.###.#",
"#.#.....#.#..^..#...#...#.#",
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
"#.#..S#.#.....#.#.#..^..#.#",
"#.###.#.#####.#.#.#####.#.#",
"#...#.#.....#...#.....#...#",
"###.#.#################.###",
"#P..#......L.......^...E..#",
"###########################",
],
[
"###############################",
"#.....#.......#.......#.......#",
"###.#.#.#####.#.#####.#.#####.#",
"#...#.#.....#...#...#...#...#.#",
"#.###.#####.#####.#.#####.#.#.#",
"#.#...#...#.....#.#.....#.#.#.#",
"#.#.###.#.#####.#.#####.#.#.#.#",
"#.#...#.#...^...#.....#.#...#.#",
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
"#P..S..^..L.....#...^...L..E.#",
"###############################",
],
[
"#####################",
"#.......#...#.......#",
"#.#.#.###.#.#.####..#",
"#L#.#.#...#...#L#...#",
"###.#.#.###.###.#.#.#",
"#.....#...#.....#.#.#",
"#.#.#####.#.###...#.#",
"#...#.....#.#...#.#.#",
"#.#...............###",
"#.#.................#",
"#.#...............#.#",
"#.#.................#",
"#.#...............#.#",
"#.#...............#.#",
"###...............#.#",
"#.........L.........#",
"#.#...............###",
"#...................#",
"#.#...............#.#",
"#.#...............#.#",
"#.#...............#.#",
"#.#.................#",
"#.#...............#.#",
"#...#...#.....#.#...#",
"###.###.#######.#####",
"#.#.....#.....#.....#",
"#.#.#####.###.###.#.#",
"#...#...#.#.#...#L#.#",
"##.##.#.#.#.###.###.#",
"#P....#...#.........#",
"#####################",
],
]

# Set by the main menu to start somewhere other than the first level.
static var start_level := -1

var current_level: int = 0
var wall_set: Dictionary = {}
var player_cell: Vector2i = Vector2i.ZERO
var facing: Vector2i = Vector2i.UP
var segment_cells: Array[Vector2i] = []
var segment_nodes: Array[Node3D] = []
var _segment_targets: Array[Vector3] = []
var _segment_target_rots: Array[float] = []
var leaves: Dictionary = {}
var hazards: Dictionary = {}
var exit_cell: Vector2i = Vector2i.ZERO
var exit_node: Node3D = null
var leaves_left: int = 0
var is_busy: bool = false
var swipe_start := Vector2.ZERO
var move_timer: float = 0.0
const MOVE_REPEAT_DELAY := 0.22
const REVERSE_REPEAT_DELAY := 1.20
const FORWARD_MOVE_DURATION := 0.34
const REVERSE_MOVE_DURATION := 0.68
var _is_reversing: bool = false
var _move_anim_remaining := 0.0
var _allow_busy_release := true
var _crawl_motion_time := 0.0
var _want_move_sound := false

var _maze_w: int = 0
var _maze_h: int = 0

# Shared resources for performance
var _wall_mat: ShaderMaterial
var _rock_mat: ShaderMaterial
var _wall_mesh: BoxMesh
var _ground_mat: StandardMaterial3D
var _cam_look_target := Vector3.ZERO
var _wall_cells: Array[Vector2i] = []
var _diag_timer := 0.0
var _move_count := 0
var _frame_count := 0
var _p_was_pressed := false
var _idle_timer := 0.0
const IDLE_LOOK_DELAY := 3.0  # seconds before caterpillar looks at camera
var _is_looking_at_camera := false
var _body_shadow: MeshInstance3D = null

# ── Bush biting ──
const BITE_DURATION := 6.0       # seconds per bite – matches bite.wav length
const BITES_TO_EAT := 3          # bites needed to destroy a bush
var _bite_target: Vector2i = Vector2i(-999, -999)  # cell being bitten
var _bite_count: Dictionary = {} # cell -> int (accumulated bites)
var _bite_timer := 0.0           # countdown for current bite
var _is_biting := false
var _bite_face_loop_timer := 0.0
var _bite_face_is_biting := true
const BITE_FACE_LOOP_INTERVAL := 0.45
var _wall_mm_inst: MultiMeshInstance3D = null
var _rock_mm_inst: MultiMeshInstance3D = null
var _fog_mm_inst: MeshInstance3D = null
var _bite_marks: Array[Node3D] = []  # legacy bite visual nodes
var _bitten_bush_nodes: Dictionary = {}   # cell -> Node3D (individual bitten bush root)
var _bitten_bush_hscale: Dictionary = {}  # cell -> float (original h_scale)
var _cell_wall_index: Dictionary = {}     # cell -> int index in wall MultiMesh
var _rock_cell_wall_index: Dictionary = {}     # cell -> int index in rock wall MultiMesh
var _cell_wall_scales: Dictionary = {}    # cell -> Vector2 (w_scale, h_scale) from MM build
var _bush_wall_cells: Dictionary = {}      # cell -> true (edible)
var _rock_wall_cells: Dictionary = {}      # cell -> true (non-edible)
var _bite_cavity_mat: StandardMaterial3D = null
var _spider_rng := RandomNumberGenerator.new()
var _fruit_rng := RandomNumberGenerator.new()
var _mushroom_rng := RandomNumberGenerator.new()
var _spike_rng := RandomNumberGenerator.new()
var _mushroom_scene_cache: Dictionary = {}
var _mushroom_variant_paths: Array[String] = []
var _spider_move_timer := 0.0
var _game_over_pending := false
var _all_cells: Array[Vector2i] = []
var _fog_state: Dictionary = {}        # cell -> FOG_* enum
var _fog_image: Image = null
var _fog_texture: ImageTexture = null
var _spin_rings: Array[Node3D] = []
var _spin_cell_owner: Dictionary = {}   # ring cell -> ring node
var _forced_wall_types: Dictionary = {} # formation cell -> "bush" / "rock"
var _spin_hint_cooldown := 0.0
var _carry_ring: Node3D = null         # ring currently carrying the caterpillar
var _aligned_pairs: Dictionary = {}    # "inner_cell|outer_cell" -> true
var _hazard_nodes: Dictionary = {}     # cell -> Node3D
var _bonus_nodes: Dictionary = {}      # cell -> Node3D
var _bonus_types: Dictionary = {}      # cell -> String
var _base_reveal_radius := 5.0
var _glow_leaf_bonus := 0.0
var _lantern_timer := 0.0
var _last_effective_reveal_radius := -1.0
var _leaf_combo_count := 0
var _leaf_combo_timer := 0.0
var _combo_reveal_timer := 0.0
var _combo_speed_timer := 0.0
var _tension_tick_timer := 0.0
var _shoe_speed_active := false
var _dizzy_timer := 0.0
var _wormholes: Dictionary = {}         # cell -> linked cell
var _wormhole_nodes: Dictionary = {}    # cell -> Node3D
var _wormhole_cooldown := 0.0
var _required_fruit_counts: Dictionary = {}
var _required_fruits_left := 0
var _uses_specific_fruit_objective := false

# ── Sounds ──
var _snd_move: AudioStreamPlayer
var _snd_bite: AudioStreamPlayer
var _snd_eat: AudioStreamPlayer
var _snd_leaf: AudioStreamPlayer
var _snd_portal: AudioStreamPlayer
var _snd_spider: AudioStreamPlayer
var _snd_ouch: AudioStreamPlayer
var _snd_tick: AudioStreamPlayer
var _snd_chime: AudioStreamPlayer

@onready var cam: Camera3D = $Camera3D
@onready var maze_layer: Node3D = $MazeLayer
@onready var objects_layer: Node3D = $ObjectsLayer
@onready var cat_layer: Node3D = $CaterpillarLayer
@onready var hud_label: Label = $CanvasLayer/HUD/TopBar/InfoLabel
@onready var win_panel: ColorRect = $CanvasLayer/WinPanel

func _ready() -> void:
	RenderingServer.set_default_clear_color(OUTER_GROUND_COLOR)
	_init_shared_resources()
	_setup_lighting()
	_init_sounds()
	$CanvasLayer/HUD/TopBar/RetryButton.pressed.connect(_on_retry)
	$CanvasLayer/HUD/TopBar/MenuButton.pressed.connect(_on_menu)
	$CanvasLayer/WinPanel/VBox/NextButton.pressed.connect(_on_next)
	_build_game_ui()
	if start_level >= 0:
		current_level = start_level
		start_level = -1
	load_level(current_level)

func _screen_size() -> Vector2:
	var size := Vector2(1080.0, 1920.0)
	if is_inside_tree():
		var rect_size := get_viewport().get_visible_rect().size
		if rect_size.x > 1.0 and rect_size.y > 1.0:
			size = rect_size
	return size

# Ground-plane hit (relative to the look target) of a normalized screen point.
func _ground_offset_for_screen(nx: float, ny: float, aspect: float) -> Vector3:
	var basis := Basis.looking_at(-CAM_OFFSET, Vector3.UP)
	var half_h := tan(deg_to_rad(CAM_FOV) * 0.5)
	var dir := basis * Vector3(nx * half_h * aspect, ny * half_h, -1.0)
	var cam_y := CAM_LOOK_HEIGHT + CAM_OFFSET.y
	if dir.y >= -0.0001:
		return Vector3.ZERO
	var hit := Vector3(0.0, cam_y, 0.0) + Vector3(CAM_OFFSET.x, 0.0, CAM_OFFSET.z) + dir * (-cam_y / dir.y)
	return Vector3(hit.x, 0.0, hit.z)

# Keeps the playfield (between the top HUD and bottom controls) inside the maze.
func _clamp_cam_look_target(target: Vector3) -> Vector3:
	if _maze_w <= 0 or _maze_h <= 0:
		return target
	var screen := _screen_size()
	var aspect := screen.x / screen.y
	var top_ny := 1.0 - 2.0 * clampf(HUD_TOP_INSET / screen.y, 0.0, 0.45)
	var bottom_ny := -1.0 + 2.0 * clampf(HUD_BOTTOM_INSET / screen.y, 0.0, 0.45)
	var far_left := _ground_offset_for_screen(-1.0, top_ny, aspect)
	var far_right := _ground_offset_for_screen(1.0, top_ny, aspect)
	var near_left := _ground_offset_for_screen(-1.0, bottom_ny, aspect)
	var half_w := maxf(maxf(absf(far_left.x), absf(far_right.x)), absf(near_left.x))
	var top_z := far_left.z
	var bottom_z := near_left.z

	var lo_x := -0.5 * CELL - CAM_EDGE_MARGIN
	var hi_x := (float(_maze_w) - 0.5) * CELL + CAM_EDGE_MARGIN
	var lo_z := -0.5 * CELL - CAM_EDGE_MARGIN - CAM_TOP_EXTRA
	var hi_z := (float(_maze_h) - 0.5) * CELL + CAM_EDGE_MARGIN

	var min_x := lo_x + half_w
	var max_x := hi_x - half_w
	if max_x < min_x:
		target.x = (lo_x + hi_x) * 0.5
	else:
		target.x = clampf(target.x, min_x, max_x)
	var min_z := lo_z - top_z
	var max_z := hi_z - bottom_z
	if max_z < min_z:
		target.z = (lo_z + hi_z) * 0.5 - (top_z + bottom_z) * 0.5
	else:
		target.z = clampf(target.z, min_z, max_z)
	return target

func _head_cam_target(cell: Vector2i) -> Vector3:
	var p := _pos(cell)
	return _clamp_cam_look_target(Vector3(p.x, CAM_LOOK_HEIGHT, p.z))

func _level_reveal_radius(level_idx: int) -> float:
	if level_idx >= 0 and level_idx < REVEAL_RADIUS_BY_LEVEL.size():
		return REVEAL_RADIUS_BY_LEVEL[level_idx]
	return REVEAL_RADIUS_BY_LEVEL[-1]

func _effective_reveal_radius() -> float:
	var bonus := _glow_leaf_bonus
	if _lantern_timer > 0.0:
		bonus += LANTERN_BONUS_RADIUS
	if _combo_reveal_timer > 0.0:
		bonus += LEAF_COMBO_REVEAL_BONUS
	return _base_reveal_radius + bonus

func _fog_overlay_alpha(state: int) -> float:
	if state == FOG_VISIBLE:
		return 0.0
	if state == FOG_DISCOVERED:
		return 0.40
	return 0.97

func _fog_wall_brightness(state: int) -> float:
	if state == FOG_VISIBLE:
		return 1.0
	if state == FOG_DISCOVERED:
		return 0.50
	return 0.05

func _build_fog_overlay() -> void:
	if not FOG_ENABLED:
		return
	var tex_w: int = int(max(2, _maze_w * FOG_TEX_SCALE))
	var tex_h: int = int(max(2, _maze_h * FOG_TEX_SCALE))
	_fog_image = Image.create(tex_w, tex_h, false, Image.FORMAT_RGBA8)
	_fog_image.fill(Color(1.0, 1.0, 1.0, 1.0))
	_fog_texture = ImageTexture.create_from_image(_fog_image)

	var fog_mesh := PlaneMesh.new()
	fog_mesh.size = Vector2(float(_maze_w) * CELL, float(_maze_h) * CELL)

	var fog_inst := MeshInstance3D.new()
	fog_inst.mesh = fog_mesh
	fog_inst.position = Vector3(
		(float(_maze_w) - 1.0) * CELL * 0.5,
		0.03,
		(float(_maze_h) - 1.0) * CELL * 0.5
	)
	var fog_shader := Shader.new()
	fog_shader.code = """
shader_type spatial;
render_mode unshaded, cull_disabled, blend_mix, depth_draw_opaque, shadows_disabled;

uniform sampler2D fog_tex : source_color;

void fragment() {
	float fog = texture(fog_tex, UV).r;
	fog = smoothstep(0.02, 0.98, fog);
	ALBEDO = vec3(0.0);
	ALPHA = fog;
}
"""
	var fog_mat := ShaderMaterial.new()
	fog_mat.shader = fog_shader
	fog_mat.set_shader_parameter("fog_tex", _fog_texture)
	fog_inst.material_override = fog_mat
	fog_inst.cast_shadow = GeometryInstance3D.SHADOW_CASTING_SETTING_OFF
	maze_layer.add_child(fog_inst)
	_fog_mm_inst = fog_inst

func _get_fog_alpha_for_cell_index(cx: int, cy: int) -> float:
	if cx < 0 or cy < 0 or cx >= _maze_w or cy >= _maze_h:
		return 1.0
	var cell := Vector2i(cx, cy)
	return _fog_overlay_alpha(int(_fog_state.get(cell, FOG_HIDDEN)))

func _set_wall_fog_cell(cell: Vector2i, state: int) -> void:
	var b := _fog_wall_brightness(state)
	var c := Color(b, b, b, 1.0)
	if _wall_mm_inst and _wall_mm_inst.multimesh and _cell_wall_index.has(cell):
		var wall_idx := int(_cell_wall_index[cell])
		_wall_mm_inst.multimesh.set_instance_color(wall_idx, c)
	if _rock_mm_inst and _rock_mm_inst.multimesh and _rock_cell_wall_index.has(cell):
		var rock_idx := int(_rock_cell_wall_index[cell])
		_rock_mm_inst.multimesh.set_instance_color(rock_idx, c)

func _refresh_fog_visibility(center_cell: Vector2i) -> void:
	if not FOG_ENABLED:
		for cell in _all_cells:
			_fog_state[cell] = FOG_VISIBLE
		_last_effective_reveal_radius = _effective_reveal_radius()
		_apply_fog_visuals()
		return
	for cell in _all_cells:
		if int(_fog_state.get(cell, FOG_HIDDEN)) == FOG_VISIBLE:
			_fog_state[cell] = FOG_DISCOVERED

	var radius := _effective_reveal_radius()
	var r2 := radius * radius
	for cell in _all_cells:
		var dx := float(cell.x - center_cell.x)
		var dz := float(cell.y - center_cell.y)
		if dx * dx + dz * dz <= r2:
			_fog_state[cell] = FOG_VISIBLE
		elif not _fog_state.has(cell):
			_fog_state[cell] = FOG_HIDDEN

	_last_effective_reveal_radius = radius
	_apply_fog_visuals()

func _apply_fog_visuals() -> void:
	if _fog_image and _fog_texture:
		for cell in _all_cells:
			var alpha := _fog_overlay_alpha(int(_fog_state.get(cell, FOG_HIDDEN)))
			var px := clampi(cell.x, 0, _fog_image.get_width() - 1)
			var py := clampi(cell.y, 0, _fog_image.get_height() - 1)
			_fog_image.set_pixel(px, py, Color(alpha, alpha, alpha, 1.0))
		_fog_texture.update(_fog_image)

	for cell in _wall_cells:
		_set_wall_fog_cell(cell, int(_fog_state.get(cell, FOG_HIDDEN)))

	for cell in _bitten_bush_nodes.keys():
		var bush := _bitten_bush_nodes[cell] as Node3D
		if bush:
			bush.visible = int(_fog_state.get(cell, FOG_HIDDEN)) != FOG_HIDDEN

	for cell in leaves.keys():
		var leaf := leaves[cell] as Node3D
		if leaf:
			leaf.visible = int(_fog_state.get(cell, FOG_HIDDEN)) != FOG_HIDDEN

	for cell in _bonus_nodes.keys():
		var bonus := _bonus_nodes[cell] as Node3D
		if bonus:
			bonus.visible = int(_fog_state.get(cell, FOG_HIDDEN)) != FOG_HIDDEN

	for cell in _wormhole_nodes.keys():
		var wormhole := _wormhole_nodes[cell] as Node3D
		if wormhole:
			wormhole.visible = int(_fog_state.get(cell, FOG_HIDDEN)) != FOG_HIDDEN

	for cell in _hazard_nodes.keys():
		var hazard := _hazard_nodes[cell] as Node3D
		if hazard:
			hazard.visible = int(_fog_state.get(cell, FOG_HIDDEN)) == FOG_VISIBLE

	if exit_node:
		exit_node.visible = int(_fog_state.get(exit_cell, FOG_HIDDEN)) != FOG_HIDDEN

func _spawn_bonus_item(cell: Vector2i, bonus_type: String) -> void:
	var root := Node3D.new()
	root.position = _pos(cell) + Vector3(0.0, 0.34, 0.0)
	root.set_meta("bonus_type", bonus_type)

	if bonus_type == "shoe":
		var shoe := MeshInstance3D.new()
		var shoe_mesh := BoxMesh.new()
		shoe_mesh.size = Vector3(0.34, 0.12, 0.54)
		shoe.mesh = shoe_mesh
		var shoe_mat := StandardMaterial3D.new()
		shoe_mat.albedo_color = Color(0.18, 0.32, 0.92)
		shoe_mat.roughness = 0.4
		shoe_mat.emission_enabled = true
		shoe_mat.emission = Color(0.08, 0.14, 0.45)
		shoe_mat.emission_energy_multiplier = 1.2
		shoe.material_override = shoe_mat
		shoe.position.y = 0.04
		shoe.rotation_degrees = Vector3(0.0, 18.0, 0.0)
		shoe.cast_shadow = GeometryInstance3D.SHADOW_CASTING_SETTING_OFF
		root.add_child(shoe)

		var sole := MeshInstance3D.new()
		var sole_mesh := BoxMesh.new()
		sole_mesh.size = Vector3(0.36, 0.04, 0.56)
		sole.mesh = sole_mesh
		var sole_mat := StandardMaterial3D.new()
		sole_mat.albedo_color = Color(0.92, 0.92, 0.96)
		sole.material_override = sole_mat
		sole.position.y = -0.02
		sole.rotation_degrees = shoe.rotation_degrees
		sole.cast_shadow = GeometryInstance3D.SHADOW_CASTING_SETTING_OFF
		root.add_child(sole)

		objects_layer.add_child(root)
		_bonus_nodes[cell] = root
		_bonus_types[cell] = bonus_type
		return

	if not _spawn_bonus_fruit_visual(root):
		root.queue_free()
		return

	objects_layer.add_child(root)
	_bonus_nodes[cell] = root
	_bonus_types[cell] = bonus_type

func _spawn_bonus_fruit_visual(root: Node3D) -> bool:
	if root == null:
		return false
	var start_variant := _fruit_rng.randi_range(0, FRUIT_VARIANT_COUNT - 1)
	for i in range(FRUIT_VARIANT_COUNT):
		var variant := (start_variant + i) % FRUIT_VARIANT_COUNT
		var path := "%s/fruit_%02d.glb" % [FRUIT_VARIANT_DIR, variant + 1]
		var packed := load(path) as PackedScene
		if packed == null:
			continue
		var inst := packed.instantiate() as Node3D
		if inst == null:
			continue
		var mesh_inst := _find_first_mesh_instance(inst)
		if mesh_inst == null or mesh_inst.mesh == null:
			inst.queue_free()
			continue
		var aabb := mesh_inst.mesh.get_aabb()
		var size := aabb.size
		if size.x <= 0.0001 or size.y <= 0.0001 or size.z <= 0.0001:
			inst.queue_free()
			continue
		var target_w := 0.48
		var target_h := 0.52
		var sx := target_w / maxf(size.x, 0.0001)
		var sy := target_h / maxf(size.y, 0.0001)
		var sz := target_w / maxf(size.z, 0.0001)
		var s := minf(sx, minf(sy, sz))
		inst.scale = Vector3(s, s, s)
		var center := aabb.position + size * 0.5
		inst.position = Vector3(-center.x * s, -aabb.position.y * s, -center.z * s)
		_set_shadow_mode_recursive(inst, GeometryInstance3D.SHADOW_CASTING_SETTING_OFF)
		root.add_child(inst)
		return true
	return false

func _place_optional_bonus_items(rows: Array, walkable_cells: Array[Vector2i]) -> void:
	# Lanterns, glow leaves and map flowers only matter when there is fog.
	if not FOG_ENABLED:
		return
	for y in rows.size():
		var row: String = rows[y]
		for x in row.length():
			var ch := row[x]
			var cell := Vector2i(x, y)
			if ch == "N":
				_spawn_bonus_item(cell, "lantern")
			elif ch == "G":
				_spawn_bonus_item(cell, "glow_leaf")
			elif ch == "M":
				_spawn_bonus_item(cell, "map_flower")

	if walkable_cells.is_empty():
		return
	var pool: Array[Vector2i] = []
	for cell in walkable_cells:
		if cell == player_cell or cell == exit_cell:
			continue
		if _is_near_player_start(cell):
			continue
		if _is_near_exit(cell, EXIT_SAFE_SPAWN_RADIUS):
			continue
		if leaves.has(cell) or hazards.has(cell) or _bonus_types.has(cell):
			continue
		pool.append(cell)
	if pool.is_empty():
		return
	pool.shuffle()
	if pool.size() > 0 and randf() < 0.25:
		_spawn_bonus_item(pool.pop_back(), "lantern")
	if pool.size() > 0 and randf() < 0.20:
		_spawn_bonus_item(pool.pop_back(), "glow_leaf")
	if pool.size() > 0 and randf() < 0.20:
		_spawn_bonus_item(pool.pop_back(), "map_flower")

func _make_wormhole(cell: Vector2i, pair_idx: int) -> void:
	var root := Node3D.new()
	root.position = _pos(cell) + Vector3(0.0, 0.01, 0.0)
	root.set_meta("pair_idx", pair_idx)

	var core := MeshInstance3D.new()
	var core_mesh := CylinderMesh.new()
	core_mesh.top_radius = 0.20
	core_mesh.bottom_radius = 0.20
	core_mesh.height = 0.03
	core.mesh = core_mesh
	var core_mat := StandardMaterial3D.new()
	core_mat.albedo_color = Color(0.03, 0.03, 0.05)
	core_mat.roughness = 1.0
	core.material_override = core_mat
	core.cast_shadow = GeometryInstance3D.SHADOW_CASTING_SETTING_OFF
	root.add_child(core)

	var ring := MeshInstance3D.new()
	var ring_mesh := TorusMesh.new()
	ring_mesh.inner_radius = 0.04
	ring_mesh.outer_radius = 0.24
	ring.mesh = ring_mesh
	ring.rotation_degrees = Vector3(90.0, 0.0, 0.0)
	ring.position.y = 0.02
	var hue := 0.56 if pair_idx % 2 == 0 else 0.08
	var ring_mat := StandardMaterial3D.new()
	ring_mat.albedo_color = Color.from_hsv(hue, 0.75, 1.0)
	ring_mat.emission_enabled = true
	ring_mat.emission = Color.from_hsv(hue, 0.70, 1.0)
	ring_mat.emission_energy_multiplier = 0.65
	ring.material_override = ring_mat
	ring.cast_shadow = GeometryInstance3D.SHADOW_CASTING_SETTING_OFF
	root.add_child(ring)

	objects_layer.add_child(root)
	_wormhole_nodes[cell] = root

func _spawn_wormhole_pairs(walkable_cells: Array[Vector2i]) -> void:
	if walkable_cells.is_empty():
		return

	var candidates: Array[Vector2i] = []
	for cell in walkable_cells:
		if cell == player_cell or cell == exit_cell:
			continue
		if _is_near_player_start(cell, 4):
			continue
		if _is_near_exit(cell, EXIT_SAFE_SPAWN_RADIUS + 1):
			continue
		if leaves.has(cell) or hazards.has(cell) or _bonus_types.has(cell):
			continue
		candidates.append(cell)

	if candidates.size() < 2:
		return

	candidates.shuffle()
	var pair_idx := 0
	while pair_idx < WORMHOLE_PAIR_COUNT and candidates.size() >= 2:
		var a: Vector2i = candidates.pop_back()
		var best_idx := -1
		for i in range(candidates.size()):
			var candidate_b: Vector2i = candidates[i]
			var manhattan: int = abs(a.x - candidate_b.x) + abs(a.y - candidate_b.y)
			if manhattan >= WORMHOLE_MIN_PAIR_DISTANCE:
				best_idx = i
				break
		if best_idx == -1:
			continue

		var b: Vector2i = candidates[best_idx]
		candidates.remove_at(best_idx)
		_wormholes[a] = b
		_wormholes[b] = a
		_make_wormhole(a, pair_idx)
		_make_wormhole(b, pair_idx)
		pair_idx += 1

func _place_random_spikes(walkable_cells: Array[Vector2i]) -> void:
	if walkable_cells.is_empty():
		return
	var pool: Array[Vector2i] = []
	for cell in walkable_cells:
		if cell == player_cell or cell == exit_cell:
			continue
		if _is_near_player_start(cell):
			continue
		if _is_near_exit(cell, EXIT_SAFE_SPAWN_RADIUS):
			continue
		if leaves.has(cell) or hazards.has(cell):
			continue
		# Avoid narrow corridors so spikes are naturally avoidable.
		if _non_wall_neighbors(cell).size() < 3:
			continue
		pool.append(cell)
	if pool.is_empty():
		return
	pool.shuffle()
	var spike_by_level := [2, 3, 5, 6, 7, 8, 9, 10]
	var spike_count: int = int(spike_by_level[min(current_level, spike_by_level.size() - 1)])
	for i in range(min(spike_count, pool.size())):
		_make_spike(pool[i])

func _is_inside_maze(cell: Vector2i) -> bool:
	return cell.x >= 0 and cell.x < _maze_w and cell.y >= 0 and cell.y < _maze_h

func _is_near_player_start(cell: Vector2i, radius: int = PLAYER_SAFE_SPAWN_RADIUS) -> bool:
	if radius <= 0:
		return cell == player_cell
	return abs(cell.x - player_cell.x) <= radius and abs(cell.y - player_cell.y) <= radius

func _is_near_exit(cell: Vector2i, radius: int) -> bool:
	if radius <= 0:
		return cell == exit_cell
	return abs(cell.x - exit_cell.x) <= radius and abs(cell.y - exit_cell.y) <= radius

func _force_cell_walkable(cell: Vector2i) -> void:
	if not _is_inside_maze(cell):
		return
	if wall_set.has(cell):
		wall_set.erase(cell)
		_wall_cells.erase(cell)
	if leaves.has(cell):
		var leaf := leaves[cell] as Node3D
		if leaf:
			leaf.queue_free()
		leaves.erase(cell)
		leaves_left = max(leaves_left - 1, 0)
	if _bonus_types.has(cell):
		var bonus := _bonus_nodes.get(cell) as Node3D
		if bonus:
			bonus.queue_free()
		_bonus_nodes.erase(cell)
		_bonus_types.erase(cell)
	if hazards.has(cell):
		var hazard := _hazard_nodes.get(cell) as Node3D
		if hazard:
			hazard.queue_free()
		hazards.erase(cell)
		_hazard_nodes.erase(cell)

func _clear_exit_area(center: Vector2i, radius: int) -> void:
	# The gate sits in the top border wall; carve a small yard in front of it
	# (below and to the left) and keep the rest of the border as a fence.
	var side := radius + 1
	var depth := radius + 2
	for dy in range(1, depth + 1):
		for dx in range(-side - 1, side + 1):
			var cell := center + Vector2i(dx, dy)
			if cell.x <= 0 or cell.x >= _maze_w - 1 or cell.y >= _maze_h - 1:
				continue
			if leaves.has(cell):
				continue
			_force_cell_walkable(cell)

func _place_exit_top_right() -> void:
	if _maze_w <= 0 or _maze_h <= 0:
		return
	if exit_node and is_instance_valid(exit_node):
		exit_node.queue_free()
		exit_node = null

	# A doorway in the top wall, near the right corner.
	var gate := Vector2i(clampi(_maze_w - 4, 1, _maze_w - 2), 0)
	_clear_exit_area(gate, EXIT_CLEAR_RADIUS)
	_force_cell_walkable(gate)
	for side in [Vector2i.LEFT, Vector2i.RIGHT]:
		var post: Vector2i = gate + side
		if _is_inside_maze(post) and not wall_set.has(post):
			wall_set[post] = true
			_wall_cells.append(post)
	exit_cell = gate
	_make_exit(exit_cell)

func _target_double_wide_count() -> int:
	var by_level := [2, 3, 4, 4, 5, 5, 6, 6]
	return int(by_level[min(current_level, by_level.size() - 1)])

func _add_double_wide_roads(walkable_cells: Array[Vector2i]) -> void:
	if walkable_cells.is_empty():
		return

	var candidates: Array[Dictionary] = []
	for cell in walkable_cells:
		if _is_near_player_start(cell, 4):
			continue
		if _is_near_exit(cell, EXIT_SAFE_SPAWN_RADIUS + 1):
			continue

		var up := not wall_set.has(cell + Vector2i.UP)
		var down := not wall_set.has(cell + Vector2i.DOWN)
		var left := not wall_set.has(cell + Vector2i.LEFT)
		var right := not wall_set.has(cell + Vector2i.RIGHT)

		# Straight corridors are safest to widen while preserving route readability.
		if up and down and not left and not right:
			for side: Vector2i in [Vector2i.LEFT, Vector2i.RIGHT]:
				var side_cell := cell + side
				if not _is_inside_maze(side_cell):
					continue
				if side_cell.x <= 0 or side_cell.x >= _maze_w - 1:
					continue
				if side_cell.y <= 0 or side_cell.y >= _maze_h - 1:
					continue
				if not wall_set.has(side_cell):
					continue
				candidates.append({"base": cell, "wide": side_cell})
		elif left and right and not up and not down:
			for side: Vector2i in [Vector2i.UP, Vector2i.DOWN]:
				var side_cell := cell + side
				if not _is_inside_maze(side_cell):
					continue
				if side_cell.x <= 0 or side_cell.x >= _maze_w - 1:
					continue
				if side_cell.y <= 0 or side_cell.y >= _maze_h - 1:
					continue
				if not wall_set.has(side_cell):
					continue
				candidates.append({"base": cell, "wide": side_cell})

	if candidates.is_empty():
		return

	candidates.shuffle()
	var used: Dictionary = {}
	var carved := 0
	var target_count := _target_double_wide_count()
	for item in candidates:
		if carved >= target_count:
			break
		var base_cell := item["base"] as Vector2i
		var wide_cell := item["wide"] as Vector2i
		if used.has(wide_cell):
			continue
		if not wall_set.has(wide_cell):
			continue

		_force_cell_walkable(wide_cell)
		if not walkable_cells.has(wide_cell):
			walkable_cells.append(wide_cell)

		# Put spikes on one side lane only, so players can pass on the original lane.
		if randf() < DOUBLE_WIDE_SIDE_SPIKE_CHANCE:
			if not _is_near_player_start(wide_cell, 5) and not _is_near_exit(wide_cell, EXIT_SAFE_SPAWN_RADIUS + 1):
				if not leaves.has(wide_cell) and not hazards.has(wide_cell):
					_make_spike(wide_cell)

		used[wide_cell] = true
		used[base_cell] = true
		carved += 1

func _non_wall_neighbors(cell: Vector2i) -> Array[Vector2i]:
	var neighbors: Array[Vector2i] = []
	for dir: Vector2i in [Vector2i.UP, Vector2i.DOWN, Vector2i.LEFT, Vector2i.RIGHT]:
		var next := cell + dir
		if not _is_inside_maze(next):
			continue
		if wall_set.has(next):
			continue
		neighbors.append(next)
	return neighbors

func _required_progress_cells() -> Array[Vector2i]:
	var targets: Array[Vector2i] = []
	for leaf_cell in leaves.keys():
		targets.append(leaf_cell)
	if exit_node:
		targets.append(exit_cell)
	return targets

func _reachable_cells_avoiding_spikes() -> Dictionary:
	var visited: Dictionary = {}
	if wall_set.has(player_cell):
		return visited
	if String(hazards.get(player_cell, "")) == "spike":
		return visited

	var queue: Array[Vector2i] = [player_cell]
	visited[player_cell] = true
	var head := 0
	while head < queue.size():
		var cur := queue[head]
		head += 1
		for next in _non_wall_neighbors(cur):
			if visited.has(next):
				continue
			if String(hazards.get(next, "")) == "spike":
				continue
			visited[next] = true
			queue.append(next)
	return visited

func _spike_layout_has_workaround() -> bool:
	var reachable := _reachable_cells_avoiding_spikes()
	for target in _required_progress_cells():
		if not reachable.has(target):
			return false
	return true

func _remove_spike(cell: Vector2i) -> void:
	if String(hazards.get(cell, "")) != "spike":
		return
	hazards.erase(cell)
	var node := _hazard_nodes.get(cell) as Node3D
	if node:
		node.queue_free()
	_hazard_nodes.erase(cell)

func _remove_mushroom(cell: Vector2i) -> void:
	if String(hazards.get(cell, "")) != "mushroom":
		return
	hazards.erase(cell)
	var node := _hazard_nodes.get(cell) as Node3D
	if node:
		node.queue_free()
	_hazard_nodes.erase(cell)

func _ensure_spike_workarounds() -> void:
	var spike_cells: Array[Vector2i] = []
	for cell in hazards.keys():
		if String(hazards[cell]) == "spike":
			spike_cells.append(cell)
	if spike_cells.is_empty():
		return

	# Remove the most restrictive spikes first until objectives are reachable without stepping on spikes.
	spike_cells.sort_custom(func(a: Vector2i, b: Vector2i) -> bool:
		return _non_wall_neighbors(a).size() < _non_wall_neighbors(b).size()
	)
	for cell in spike_cells:
		if _spike_layout_has_workaround():
			break
		_remove_spike(cell)

func _collect_bonus(cell: Vector2i) -> void:
	if not _bonus_types.has(cell):
		return
	var btype := String(_bonus_types[cell])
	var node := _bonus_nodes.get(cell) as Node3D
	if node:
		node.queue_free()
	_bonus_nodes.erase(cell)
	_bonus_types.erase(cell)

	if btype == "lantern":
		_lantern_timer = LANTERN_BONUS_SECONDS
		_show_toast("Lantern! You can see further for a while.", Color(1.0, 0.86, 0.35))
	elif btype == "glow_leaf":
		_glow_leaf_bonus += GLOW_LEAF_RADIUS_BONUS
		_show_toast("Glow leaf! Your light grows.", Color(0.65, 1.0, 0.55))
	elif btype == "map_flower":
		for reveal_cell in _all_cells:
			var dx := float(reveal_cell.x - cell.x)
			var dz := float(reveal_cell.y - cell.y)
			if dx * dx + dz * dz <= MAP_FLOWER_REVEAL_RADIUS * MAP_FLOWER_REVEAL_RADIUS:
				if int(_fog_state.get(reveal_cell, FOG_HIDDEN)) == FOG_HIDDEN:
					_fog_state[reveal_cell] = FOG_DISCOVERED
		_show_toast("Map flower! Part of the maze is revealed.", Color(0.95, 0.6, 1.0))
	elif btype == "shoe":
		_shoe_speed_active = true
		_show_toast("Sneakers! Faster crawling until you get hurt.", Color(0.55, 0.75, 1.0))
	_add_score(SCORE_BONUS_ITEM)

	_refresh_fog_visibility(player_cell)
	_update_hud()

func _effective_move_speed_mult() -> float:
	var mult := 1.0
	if _combo_speed_timer > 0.0:
		mult *= LEAF_COMBO_SPEED_MULT
	if _shoe_speed_active:
		mult *= SHOE_SPEED_MULT
	if _dizzy_timer > 0.0:
		mult *= DIZZY_SPEED_MULT
	return mult

func _fruit_name_to_variant(fruit_name: String) -> int:
	var key := fruit_name.strip_edges().to_lower()
	match key:
		"apple":
			return 0
		"cherry":
			return 1
		"peach":
			return 2
		"pear":
			return 3
		"grape":
			return 4
	return -1

func _fruit_variant_display_name(variant: int) -> String:
	if variant >= 0 and variant < FRUIT_VARIANT_NAMES.size():
		return String(FRUIT_VARIANT_NAMES[variant])
	return "Fruit"

func _objective_complete() -> bool:
	return _required_fruits_left <= 0

func _register_collected_fruit(variant: int) -> void:
	if _uses_specific_fruit_objective:
		var remaining := int(_required_fruit_counts.get(variant, 0))
		if remaining > 0:
			_required_fruit_counts[variant] = remaining - 1
			_required_fruits_left = max(_required_fruits_left - 1, 0)
	else:
		_required_fruits_left = max(_required_fruits_left - 1, 0)

func _configure_fruit_objective_for_level() -> void:
	_required_fruit_counts.clear()
	_required_fruits_left = leaves_left
	_uses_specific_fruit_objective = false

	var objective: Dictionary = LEVEL_FRUIT_OBJECTIVES.get(current_level, {}) as Dictionary
	if objective.is_empty():
		return

	var required_variants: Array[int] = []
	for fruit_name in objective.keys():
		var variant := _fruit_name_to_variant(String(fruit_name))
		if variant < 0:
			continue
		var count: int = maxi(0, int(objective[fruit_name]))
		for _i in range(count):
			required_variants.append(variant)

	if required_variants.is_empty() or leaves.is_empty():
		return

	var leaf_cells: Array[Vector2i] = []
	for cell in leaves.keys():
		leaf_cells.append(cell)

	var assign_rng := RandomNumberGenerator.new()
	assign_rng.seed = 8803 + current_level * 97
	for i in range(leaf_cells.size() - 1, 0, -1):
		var j := assign_rng.randi_range(0, i)
		var tmp := leaf_cells[i]
		leaf_cells[i] = leaf_cells[j]
		leaf_cells[j] = tmp

	var assigned := 0
	for i in range(min(required_variants.size(), leaf_cells.size())):
		var cell := leaf_cells[i]
		var variant := required_variants[i]
		var leaf_node := leaves.get(cell) as Node3D
		if leaf_node:
			leaf_node.set_meta("fruit_variant", variant)
			if leaf_node.has_method("set_fruit_variant"):
				leaf_node.call("set_fruit_variant", variant)
			_required_fruit_counts[variant] = int(_required_fruit_counts.get(variant, 0)) + 1
			assigned += 1

	if assigned > 0:
		_uses_specific_fruit_objective = true
		_required_fruits_left = assigned

func _init_sounds() -> void:
	var sound_map := {
		"move": "res://assets/sounds/06_funky_cartoon_steps.wav",
		"bite": "res://assets/sounds/apple-bite.wav",
		"eat":  "res://assets/sounds/eat_wall.wav",
		"leaf": "res://assets/sounds/leaf_pickup.wav",
		"portal": "res://assets/sounds/portal_enter.wav",
		"spider": "res://assets/sounds/spider_alert.wav",
		"ouch": "res://assets/sounds/ouch.wav",
	}
	for key in sound_map:
		var player := AudioStreamPlayer.new()
		var stream := load(sound_map[key]) as AudioStream
		if stream:
			player.stream = stream
		else:
			push_error("Could not load sound: %s" % sound_map[key])
		player.bus = "Master"
		add_child(player)
		set("_snd_" + key, player)
	# Tweak volumes
	_snd_move.volume_db = -4.0
	_snd_bite.volume_db = 0.0
	_snd_eat.volume_db = 2.0
	_snd_leaf.volume_db = 1.0
	_snd_portal.volume_db = 1.0
	_snd_spider.volume_db = 3.0
	_snd_ouch.volume_db = 2.0
	_snd_tick = _make_blip_player(_make_blip(1500.0, 0.035, 0.5), -16.0)
	_snd_chime = _make_blip_player(_make_blip(1046.5, 0.22, 0.6, 1568.0), -8.0)
	if _snd_move and not _snd_move.finished.is_connected(_on_move_sound_finished):
		_snd_move.finished.connect(_on_move_sound_finished)

# Short generated beep (optionally with a second note on top) for ring cues.
func _make_blip(freq: float, duration: float, volume: float, freq2: float = 0.0) -> AudioStreamWAV:
	var rate := 22050
	var count := int(duration * rate)
	var data := PackedByteArray()
	data.resize(count * 2)
	for i in count:
		var t := float(i) / rate
		var env := (1.0 - float(i) / count)
		env *= env
		var v := sin(TAU * freq * t)
		if freq2 > 0.0:
			v = (v + sin(TAU * freq2 * t)) * 0.5
		data.encode_s16(i * 2, int(clampf(v * env * volume, -1.0, 1.0) * 32767.0))
	var wav := AudioStreamWAV.new()
	wav.format = AudioStreamWAV.FORMAT_16_BITS
	wav.mix_rate = rate
	wav.data = data
	return wav

func _make_blip_player(stream: AudioStream, volume_db: float) -> AudioStreamPlayer:
	var player := AudioStreamPlayer.new()
	player.stream = stream
	player.volume_db = volume_db
	player.bus = "Master"
	add_child(player)
	return player

func _set_move_sound_active(active: bool) -> void:
	_want_move_sound = active
	if active and _snd_move and not _snd_move.playing:
		_snd_move.pitch_scale = 1.0
		_snd_move.play()
	elif not active and _snd_move and _snd_move.playing:
		_snd_move.stop()

func _on_move_sound_finished() -> void:
	if _want_move_sound and _snd_move:
		_snd_move.pitch_scale = 1.0
		_snd_move.play()

func _init_shared_resources() -> void:
	# Flat rounded-block wall shader: soft vertical gradient, no textures or noise.
	var block_shader := Shader.new()
	block_shader.code = "
shader_type spatial;
render_mode unshaded, cull_back, shadows_disabled;
uniform vec3 color_top : source_color = vec3(0.40, 0.68, 0.30);
uniform vec3 color_side : source_color = vec3(0.26, 0.52, 0.22);
uniform float corner_roundness : hint_range(0.0, 0.2) = 0.06;
uniform float half_height = 0.225;

varying float v_up;
varying float v_height;

void vertex() {
	float r = corner_roundness;
	vec3 local = VERTEX;
	vec3 s = sign(local);
	vec3 a = abs(local);
	vec3 inner = vec3(0.5 - r, half_height - r, 0.5 - r);
	vec3 d = max(a - inner, vec3(0.0));
	float l = length(d);
	if (l > 0.001) {
		local = s * (min(a, inner) + d * (r / l));
	}
	VERTEX = local;
	v_up = NORMAL.y;
	v_height = (local.y + half_height) / (2.0 * half_height);
}

void fragment() {
	// Flat two-tone block: bright top, darker sides with a soft base shade.
	vec3 side = color_side * mix(0.82, 1.0, clamp(v_height, 0.0, 1.0));
	ALBEDO = mix(side, color_top, step(0.5, v_up)) * COLOR.rgb;
}
"
	_wall_mat = ShaderMaterial.new()
	_wall_mat.shader = block_shader
	_wall_mat.set_shader_parameter("color_top", Vector3(BUSH_TOP.r, BUSH_TOP.g, BUSH_TOP.b))
	_wall_mat.set_shader_parameter("color_side", Vector3(BUSH_BOTTOM.r, BUSH_BOTTOM.g, BUSH_BOTTOM.b))
	_wall_mat.set_shader_parameter("half_height", WALL_HEIGHT * 0.5)

	_rock_mat = ShaderMaterial.new()
	_rock_mat.shader = block_shader
	_rock_mat.set_shader_parameter("color_top", Vector3(ROCK_TOP.r, ROCK_TOP.g, ROCK_TOP.b))
	_rock_mat.set_shader_parameter("color_side", Vector3(ROCK_BOTTOM.r, ROCK_BOTTOM.g, ROCK_BOTTOM.b))
	_rock_mat.set_shader_parameter("half_height", WALL_HEIGHT * 0.5)
	_rock_mat.set_shader_parameter("corner_roundness", 0.04)

	_wall_mesh = BoxMesh.new()
	_wall_mesh.size = Vector3(CELL, WALL_HEIGHT, CELL)
	_wall_mesh.subdivide_width = 2
	_wall_mesh.subdivide_height = 2
	_wall_mesh.subdivide_depth = 2

	_ground_mat = StandardMaterial3D.new()
	_ground_mat.albedo_color = GROUND_COLOR
	_ground_mat.shading_mode = BaseMaterial3D.SHADING_MODE_UNSHADED

func _setup_lighting() -> void:
	# Directional light – slightly angled for soft shadows and depth
	var light := DirectionalLight3D.new()
	light.rotation_degrees = Vector3(-70, 30, 0)
	light.shadow_enabled = true
	light.light_energy = 0.8
	light.light_color = Color(1.0, 0.98, 0.92)
	light.directional_shadow_max_distance = 60.0
	light.directional_shadow_mode = DirectionalLight3D.SHADOW_PARALLEL_2_SPLITS
	add_child(light)

	# World environment
	var world_env := WorldEnvironment.new()
	var env := Environment.new()
	env.background_mode = Environment.BG_COLOR
	env.background_color = OUTER_GROUND_COLOR
	env.ambient_light_source = Environment.AMBIENT_SOURCE_COLOR
	env.ambient_light_color = Color(0.75, 0.75, 0.70)
	env.ambient_light_energy = 0.6
	world_env.environment = env
	add_child(world_env)

# ── Coordinate helpers ──

func _pos(cell: Vector2i) -> Vector3:
	return Vector3(float(cell.x) * CELL, 0.0, float(cell.y) * CELL)

func _dir_angle_y(dir: Vector2i) -> float:
	# Camera looks down -Y; model forward is -Z
	if dir == Vector2i.UP: return 0.0           # toward -Z
	if dir == Vector2i.RIGHT: return -PI * 0.5   # toward +X
	if dir == Vector2i.DOWN: return PI            # toward +Z
	if dir == Vector2i.LEFT: return PI * 0.5      # toward -X
	return 0.0

# ── Level loading ──

func _clear() -> void:
	for c in maze_layer.get_children():
		c.queue_free()
	for c in objects_layer.get_children():
		c.queue_free()
	for c in cat_layer.get_children():
		c.queue_free()
	wall_set.clear()
	_spin_rings.clear()
	_spin_cell_owner.clear()
	_forced_wall_types.clear()
	_spin_hint_cooldown = 0.0
	_carry_ring = null
	segment_cells.clear()
	segment_nodes.clear()
	_move_anim_remaining = 0.0
	_set_move_sound_active(false)
	_reset_dynamic_state()
	_bite_count.clear()
	_is_biting = false
	_wall_mm_inst = null
	_rock_mm_inst = null
	_fog_mm_inst = null
	_bite_marks.clear()
	_segment_targets.clear()
	_bitten_bush_nodes.clear()
	_bitten_bush_hscale.clear()
	_cell_wall_index.clear()
	_rock_cell_wall_index.clear()
	_cell_wall_scales.clear()
	_bush_wall_cells.clear()
	_rock_wall_cells.clear()
	_all_cells.clear()
	_fog_state.clear()
	_fog_image = null
	_fog_texture = null
	_hazard_nodes.clear()
	_bonus_nodes.clear()
	_bonus_types.clear()
	_wormholes.clear()
	_wormhole_nodes.clear()
	_wormhole_cooldown = 0.0
	_glow_leaf_bonus = 0.0
	_lantern_timer = 0.0
	_last_effective_reveal_radius = -1.0
	_leaf_combo_count = 0
	_leaf_combo_timer = 0.0
	_combo_reveal_timer = 0.0
	_combo_speed_timer = 0.0
	_tension_tick_timer = 0.0
	_spider_move_timer = 0.0
	_game_over_pending = false
	_shoe_speed_active = false
	_dizzy_timer = 0.0
	_required_fruit_counts.clear()
	_required_fruits_left = 0
	_uses_specific_fruit_objective = false
	_segment_target_rots.clear()
	leaves.clear()
	hazards.clear()
	exit_node = null

func load_level(idx: int) -> void:
	_clear()
	current_level = idx % LEVELS.size()
	leaves_left = 0
	_spider_rng.randomize()
	_fruit_rng.seed = 10007 + current_level * 977
	_mushroom_rng.randomize()
	_spike_rng.randomize()
	_base_reveal_radius = _level_reveal_radius(current_level)
	var rows: Array = LEVELS[current_level]
	var walkable_cells: Array[Vector2i] = []

	_maze_h = rows.size()
	_maze_w = 0
	for row in rows:
		_maze_w = max(_maze_w, row.length())

	# Ground plane
	_create_ground(_maze_w, _maze_h)

	# Parse maze – collect wall positions first
	_wall_cells.clear()
	_all_cells.clear()
	_fog_state.clear()
	for y in rows.size():
		var row: String = rows[y]
		for x in row.length():
			var ch := row[x]
			var cell := Vector2i(x, y)
			_all_cells.append(cell)
			_fog_state[cell] = FOG_HIDDEN
			if ch == "#":
				wall_set[cell] = true
				_wall_cells.append(cell)
			else:
				walkable_cells.append(cell)
			match ch:
				"P":
					player_cell = cell
				"L":
					leaves_left += 1
					_make_leaf(cell)
				"S":
					_make_spider(cell)
				"^":
					_make_spike(cell)
				"E":
					pass

	_place_exit_top_right()
	_stamp_level_formations(walkable_cells)
	_build_spinners(walkable_cells)
	if _level_option("wide_roads"):
		_add_double_wide_roads(walkable_cells)
	_relocate_spawn_spiders()

	_assign_wall_types()
	_configure_fruit_objective_for_level()

	if _level_option("random_spikes"):
		_place_random_spikes(walkable_cells)
	_ensure_spike_workarounds()
	_place_optional_bonus_items(rows, walkable_cells)

	# Build all walls as a single MultiMesh
	_build_wall_multimesh()
	_build_fog_overlay()

	# Scatter decorations; mushrooms are placed inside walkable maze cells.
	if _level_option("mushrooms"):
		_spawn_decorations(walkable_cells)
	if _level_option("wormholes"):
		_spawn_wormhole_pairs(walkable_cells)

	# Camera setup – perspective with isometric-like offset
	cam.projection = Camera3D.PROJECTION_PERSPECTIVE
	cam.fov = CAM_FOV
	cam.near = 0.1
	cam.far = 100.0

	# Caterpillar – determine initial facing (first open direction)
	for d in [Vector2i.RIGHT, Vector2i.UP, Vector2i.DOWN, Vector2i.LEFT]:
		if not wall_set.has(player_cell + d):
			facing = d
			break
	# Walk the head forward so the body/tail naturally trail behind.
	# segment_cells[0] = head (front), segment_cells[-1] = tail (back)
	var init_path: Array[Vector2i] = [player_cell]
	var walk := player_cell
	for i in range(4):
		var next := walk + facing
		if not wall_set.has(next) and not init_path.has(next) and not hazards.has(next) and not _spin_cell_owner.has(next):
			init_path.push_front(next)
			walk = next
		else:
			break
	# init_path is [head, body x3, tail]. Pad to at least 5 segments.
	while init_path.size() < 5:
		init_path.append(init_path[-1])
	segment_cells = init_path
	player_cell = segment_cells[0]
	# Aim at the actual head (it was walked forward from the spawn cell).
	_cam_look_target = _head_cam_target(player_cell)
	cam.position = _cam_look_target + CAM_OFFSET
	cam.look_at(_cam_look_target, Vector3.UP)
	cam.current = true
	print("Level loaded: %d walls, cam at %s, cam_rot=%s, fov=%.0f" % [wall_set.size(), cam.position, cam.rotation_degrees, cam.fov])
	_rebuild_caterpillar()
	_refresh_fog_visibility(player_cell)
	win_panel.visible = false
	is_busy = false
	_start_level_dynamics()
	_update_hud()

func _assign_wall_types() -> void:
	_bush_wall_cells.clear()
	_rock_wall_cells.clear()
	if _wall_cells.is_empty():
		return

	var interior_candidates: Array[Vector2i] = []
	for cell in _wall_cells:
		var on_border := cell.x <= 0 or cell.y <= 0 or cell.x >= _maze_w - 1 or cell.y >= _maze_h - 1
		if on_border:
			_rock_wall_cells[cell] = true
		else:
			interior_candidates.append(cell)

	var rng := RandomNumberGenerator.new()
	rng.seed = 6137 + current_level * 191
	for cell in interior_candidates:
		if rng.randf() < ROCK_WALL_RATIO:
			_rock_wall_cells[cell] = true
		else:
			_bush_wall_cells[cell] = true

	var target_min_bushes := mini(maxi(MIN_BUSH_WALLS, int(interior_candidates.size() * 0.20)), interior_candidates.size())
	if _bush_wall_cells.size() < target_min_bushes:
		var candidates := interior_candidates.duplicate()
		while _bush_wall_cells.size() < target_min_bushes and not candidates.is_empty():
			var idx := rng.randi_range(0, candidates.size() - 1)
			var cell: Vector2i = candidates[idx]
			candidates.remove_at(idx)
			_rock_wall_cells.erase(cell)
			_bush_wall_cells[cell] = true

	for cell in _forced_wall_types.keys():
		if not wall_set.has(cell):
			continue
		if String(_forced_wall_types[cell]) == "rock":
			_bush_wall_cells.erase(cell)
			_rock_wall_cells[cell] = true
		else:
			_rock_wall_cells.erase(cell)
			_bush_wall_cells[cell] = true

func _create_ground(w: int, h: int) -> void:
	# Inner maze ground: flat solid colour
	var mesh_inst := MeshInstance3D.new()
	var plane := PlaneMesh.new()
	plane.size = Vector2(float(w) * CELL, float(h) * CELL)
	plane.subdivide_width = 0
	plane.subdivide_depth = 0
	mesh_inst.mesh = plane
	mesh_inst.material_override = _ground_mat
	mesh_inst.position = Vector3(
		(float(w) - 1.0) * CELL * 0.5,
		-0.01,
		(float(h) - 1.0) * CELL * 0.5
	)
	maze_layer.add_child(mesh_inst)

	# Outer landscape ground – covers the visible area outside the maze
	var pad := 30.0
	var outer_w := float(w) * CELL + pad * 2.0
	var outer_h := float(h) * CELL + pad * 2.0
	var outer_inst := MeshInstance3D.new()
	var outer_plane := PlaneMesh.new()
	outer_plane.size = Vector2(outer_w, outer_h)
	outer_plane.subdivide_width = 0
	outer_plane.subdivide_depth = 0
	outer_inst.mesh = outer_plane
	var outer_mat := StandardMaterial3D.new()
	outer_mat.albedo_color = OUTER_GROUND_COLOR
	outer_mat.shading_mode = BaseMaterial3D.SHADING_MODE_UNSHADED
	outer_inst.material_override = outer_mat
	outer_inst.position = Vector3(
		(float(w) - 1.0) * CELL * 0.5,
		-0.02,
		(float(h) - 1.0) * CELL * 0.5
	)
	maze_layer.add_child(outer_inst)

# ── Entity factories ──

# ── Decorations ──

func _find_first_mesh_instance(node: Node) -> MeshInstance3D:
	if node is MeshInstance3D:
		return node as MeshInstance3D
	for child in node.get_children():
		var found := _find_first_mesh_instance(child)
		if found:
			return found
	return null

func _set_shadow_mode_recursive(node: Node, mode: int) -> void:
	if node is GeometryInstance3D:
		(node as GeometryInstance3D).cast_shadow = mode as GeometryInstance3D.ShadowCastingSetting
	for child in node.get_children():
		_set_shadow_mode_recursive(child, mode)

func _get_mushroom_variant_paths() -> Array[String]:
	if not _mushroom_variant_paths.is_empty():
		return _mushroom_variant_paths

	var dir := DirAccess.open(MUSHROOM_VARIANT_DIR)
	if dir == null:
		return _mushroom_variant_paths

	dir.list_dir_begin()
	while true:
		var file_name := dir.get_next()
		if file_name == "":
			break
		if dir.current_is_dir():
			continue
		if not file_name.to_lower().ends_with(".glb"):
			continue
		if file_name.to_lower().find("mushroom") == -1:
			continue
		_mushroom_variant_paths.append("%s/%s" % [MUSHROOM_VARIANT_DIR, file_name])
	dir.list_dir_end()
	_mushroom_variant_paths.sort()
	return _mushroom_variant_paths

func _load_mushroom_variant_scene(variant: int) -> PackedScene:
	var paths := _get_mushroom_variant_paths()
	if paths.is_empty():
		return null
	var clamped := posmod(variant, paths.size())
	var path := paths[clamped]
	if _mushroom_scene_cache.has(path):
		return _mushroom_scene_cache[path] as PackedScene
	var packed := load(path) as PackedScene
	if packed:
		_mushroom_scene_cache[path] = packed
	return packed

func _spawn_split_mushroom(root: Node3D) -> bool:
	var paths := _get_mushroom_variant_paths()
	if paths.is_empty():
		return false
	var variant := _mushroom_rng.randi_range(0, paths.size() - 1)
	var packed := _load_mushroom_variant_scene(variant)
	if packed == null:
		return false

	var inst := packed.instantiate() as Node3D
	if inst == null:
		return false

	var mesh_inst := _find_first_mesh_instance(inst)
	if mesh_inst == null or mesh_inst.mesh == null:
		inst.queue_free()
		return false

	var aabb := mesh_inst.mesh.get_aabb()
	var size := aabb.size
	if size.x <= 0.0001 or size.y <= 0.0001 or size.z <= 0.0001:
		inst.queue_free()
		return false

	var target_width := 0.34
	var target_height := 0.44
	var sx := target_width / maxf(size.x, 0.0001)
	var sy := target_height / maxf(size.y, 0.0001)
	var sz := target_width / maxf(size.z, 0.0001)
	var base_scale := minf(sx, minf(sy, sz))
	var random_scale := _mushroom_rng.randf_range(0.85, 1.35)
	var s := base_scale * random_scale * MUSHROOM_SIZE_MULT
	inst.scale = Vector3(s, s, s)

	var center := aabb.position + size * 0.5
	inst.position = Vector3(-center.x * s, -aabb.position.y * s, -center.z * s)
	_set_shadow_mode_recursive(inst, GeometryInstance3D.SHADOW_CASTING_SETTING_OFF)
	root.add_child(inst)
	return true

func _make_mushroom(cell: Vector2i) -> void:
	var root := Node3D.new()
	root.position = _pos(cell)
	if _spawn_split_mushroom(root):
		root.rotation.y = _mushroom_rng.randf_range(0.0, TAU)
		objects_layer.add_child(root)
		hazards[cell] = "mushroom"
		_hazard_nodes[cell] = root
	else:
		root.queue_free()

func _spawn_decorations(walkable_cells: Array[Vector2i] = []) -> void:
	# Mushrooms inside the maze act as hazards.
	if walkable_cells.is_empty():
		return
	var mushroom_candidates: Array[Vector2i] = []
	for cell in walkable_cells:
		if cell == player_cell or cell == exit_cell:
			continue
		if _is_near_player_start(cell):
			continue
		if _is_near_exit(cell, EXIT_SAFE_SPAWN_RADIUS):
			continue
		if leaves.has(cell) or hazards.has(cell) or _bonus_types.has(cell):
			continue
		mushroom_candidates.append(cell)

	if mushroom_candidates.is_empty():
		return
	mushroom_candidates.shuffle()
	var mushroom_by_level := [2, 2, 3, 3, 4, 4, 5, 5]
	var level_target := int(mushroom_by_level[min(current_level, mushroom_by_level.size() - 1)])
	var density_target := int(float(mushroom_candidates.size()) * 0.025)
	var target_count := mini(maxi(level_target, density_target), 7)
	for i in range(mini(target_count, mushroom_candidates.size())):
		var m_cell := mushroom_candidates[i]
		_make_mushroom(m_cell)

func _build_wall_multimesh() -> void:
	if _wall_mm_inst:
		_wall_mm_inst.queue_free()
		_wall_mm_inst = null
	if _rock_mm_inst:
		_rock_mm_inst.queue_free()
		_rock_mm_inst = null

	_cell_wall_index.clear()
	_rock_cell_wall_index.clear()
	_cell_wall_scales.clear()

	var bush_cells: Array[Vector2i] = []
	var rock_cells: Array[Vector2i] = []
	for cell in _wall_cells:
		if _bush_wall_cells.has(cell):
			bush_cells.append(cell)
		else:
			rock_cells.append(cell)

	if not bush_cells.is_empty():
		var bush_mm := MultiMesh.new()
		bush_mm.transform_format = MultiMesh.TRANSFORM_3D
		bush_mm.use_colors = true
		bush_mm.mesh = _wall_mesh
		bush_mm.instance_count = bush_cells.size()
		for i in bush_cells.size():
			var cell_i := bush_cells[i]
			var p := _pos(cell_i)
			var h_scale := 1.0
			var w_scale := 1.0
			_cell_wall_index[cell_i] = i
			_cell_wall_scales[cell_i] = Vector2(w_scale, h_scale)
			var t := Transform3D.IDENTITY
			if not _bitten_bush_nodes.has(cell_i):
				t = t.scaled(Vector3(w_scale, h_scale, w_scale))
				t.origin = Vector3(p.x, WALL_HEIGHT * 0.5 * h_scale, p.z)
			else:
				t.origin = Vector3(0.0, -9999.0, 0.0)  # hide: individual node handles this cell
			bush_mm.set_instance_transform(i, t)
		var bush_inst := MultiMeshInstance3D.new()
		bush_inst.multimesh = bush_mm
		bush_inst.material_override = _wall_mat
		bush_inst.cast_shadow = GeometryInstance3D.SHADOW_CASTING_SETTING_OFF
		maze_layer.add_child(bush_inst)
		_wall_mm_inst = bush_inst

	if not rock_cells.is_empty():
		var rock_mm := MultiMesh.new()
		rock_mm.transform_format = MultiMesh.TRANSFORM_3D
		rock_mm.use_colors = true
		rock_mm.mesh = _wall_mesh
		rock_mm.instance_count = rock_cells.size()
		for i in rock_cells.size():
			var cell_i := rock_cells[i]
			var p := _pos(cell_i)
			var h_scale := 1.0
			var w_scale := 1.0
			_rock_cell_wall_index[cell_i] = i
			var t := Transform3D.IDENTITY
			t = t.scaled(Vector3(w_scale, h_scale, w_scale))
			t.origin = Vector3(p.x, WALL_HEIGHT * 0.5 * h_scale, p.z)
			rock_mm.set_instance_transform(i, t)
		var rock_inst := MultiMeshInstance3D.new()
		rock_inst.multimesh = rock_mm
		rock_inst.material_override = _rock_mat
		rock_inst.cast_shadow = GeometryInstance3D.SHADOW_CASTING_SETTING_OFF
		maze_layer.add_child(rock_inst)
		_rock_mm_inst = rock_inst

func _make_leaf(cell: Vector2i) -> void:
	var node := Node3D.new()
	node.set_meta("fruit_variant", _fruit_rng.randi_range(0, 4))
	node.set_script(Leaf3DScript)
	node.position = _pos(cell)
	objects_layer.add_child(node)
	leaves[cell] = node

func _make_spider(cell: Vector2i) -> void:
	var node := Node3D.new()
	node.set_meta("spider_variant", int(_spider_rng.randi()))
	node.set_meta("spider_heading", Vector2i.ZERO)
	node.set_meta("track_player", false)
	node.set_meta("spider_moving", false)
	node.set_meta("spider_move_t", 0.0)
	node.set_meta("spider_next_cell", cell)
	node.set_script(Spider3DScript)
	node.position = _pos(cell)
	objects_layer.add_child(node)
	hazards[cell] = "spider"
	_hazard_nodes[cell] = node

func _is_spider_destination_reserved(cell: Vector2i) -> bool:
	for spider_node in _hazard_nodes.values():
		var node := spider_node as Node3D
		if node == null or not is_instance_valid(node):
			continue
		if not bool(node.get_meta("spider_moving", false)):
			continue
		var reserved := node.get_meta("spider_next_cell", Vector2i(-9999, -9999)) as Vector2i
		if reserved == cell:
			return true
	return false

func _is_spider_cell_walkable(cell: Vector2i, from_cell: Vector2i) -> bool:
	if not _is_inside_maze(cell):
		return false
	if wall_set.has(cell) or _spin_cell_owner.has(cell):
		return false
	if cell == exit_cell:
		return false
	var h := String(hazards.get(cell, ""))
	if h == "spike" or h == "mushroom":
		return false
	if cell != from_cell and h == "spider":
		return false
	if cell != from_cell and _is_spider_destination_reserved(cell):
		return false
	return true

func _trigger_spider_catch() -> void:
	if _game_over_pending:
		return
	_game_over_pending = true
	is_busy = true
	_allow_busy_release = false
	_set_move_sound_active(false)
	if _snd_spider:
		_snd_spider.pitch_scale = 1.0
		_snd_spider.play()
	call_deferred("_lose")

func _find_spider_path_direction(from_cell: Vector2i, to_cell: Vector2i) -> Vector2i:
	if from_cell == to_cell:
		return Vector2i.ZERO

	var dirs: Array[Vector2i] = [Vector2i.UP, Vector2i.DOWN, Vector2i.LEFT, Vector2i.RIGHT]
	var queue: Array[Vector2i] = [from_cell]
	var visited: Dictionary = {from_cell: true}
	var parent: Dictionary = {}
	var head := 0

	while head < queue.size():
		var cur: Vector2i = queue[head]
		head += 1
		if cur == to_cell:
			break
		for dir in dirs:
			var next := cur + dir
			if visited.has(next):
				continue
			if next != to_cell and not _is_spider_cell_walkable(next, from_cell):
				continue
			visited[next] = true
			parent[next] = cur
			queue.append(next)

	if not visited.has(to_cell):
		return Vector2i.ZERO

	var step := to_cell
	while parent.has(step) and parent[step] != from_cell:
		step = parent[step] as Vector2i
	if not parent.has(step) and step != to_cell:
		return Vector2i.ZERO
	return step - from_cell

func _step_spider(old_cell: Vector2i, node: Node3D) -> void:
	if node == null or not is_instance_valid(node):
		hazards.erase(old_cell)
		_hazard_nodes.erase(old_cell)
		return
	if bool(node.get_meta("spider_moving", false)):
		return

	var to_player := player_cell - old_cell
	var player_dist := sqrt(float(to_player.x * to_player.x + to_player.y * to_player.y))
	var chasing := player_dist <= SPIDER_CHASE_RADIUS
	if chasing and not bool(node.get_meta("track_player", false)):
		_on_spider_started_chasing()
	node.set_meta("track_player", chasing)

	var move_chance := SPIDER_CHASE_MOVE_CHANCE if chasing else SPIDER_ROAM_MOVE_CHANCE
	if randf() > move_chance:
		return

	var dirs: Array[Vector2i] = [Vector2i.UP, Vector2i.DOWN, Vector2i.LEFT, Vector2i.RIGHT]
	var legal_dirs: Array[Vector2i] = []
	for dir in dirs:
		var next := old_cell + dir
		if _is_spider_cell_walkable(next, old_cell):
			legal_dirs.append(dir)
	if legal_dirs.is_empty():
		return

	var chosen_dir := legal_dirs[0]
	if chasing:
		var path_dir := _find_spider_path_direction(old_cell, player_cell)
		if path_dir != Vector2i.ZERO and legal_dirs.has(path_dir):
			chosen_dir = path_dir
		else:
			var best_d2 := INF
			for dir in legal_dirs:
				var next := old_cell + dir
				var to_p := player_cell - next
				var d2 := float(to_p.x * to_p.x + to_p.y * to_p.y)
				if d2 < best_d2:
					best_d2 = d2
					chosen_dir = dir
	else:
		var heading := node.get_meta("spider_heading", Vector2i.ZERO) as Vector2i
		if heading != Vector2i.ZERO and legal_dirs.has(heading) and _spider_rng.randf() < 0.62:
			chosen_dir = heading
		else:
			chosen_dir = legal_dirs[_spider_rng.randi_range(0, legal_dirs.size() - 1)]

	var new_cell := old_cell + chosen_dir
	if not _is_spider_cell_walkable(new_cell, old_cell):
		return

	node.set_meta("spider_heading", chosen_dir)
	node.set_meta("spider_moving", true)
	node.set_meta("spider_move_t", 0.0)
	node.set_meta("spider_next_cell", new_cell)

func _update_spider_motion(delta: float) -> void:
	var spider_cells: Array[Vector2i] = []
	for cell in hazards.keys():
		if String(hazards.get(cell, "")) == "spider":
			spider_cells.append(cell)

	var arrivals: Array[Dictionary] = []
	for from_cell in spider_cells:
		var node := _hazard_nodes.get(from_cell) as Node3D
		if node == null or not is_instance_valid(node):
			continue
		if not bool(node.get_meta("spider_moving", false)):
			continue

		var to_cell := node.get_meta("spider_next_cell", from_cell) as Vector2i
		var t := float(node.get_meta("spider_move_t", 0.0))
		t += delta / maxf(SPIDER_TRAVEL_TIME, 0.001)
		var clamped_t := clampf(t, 0.0, 1.0)
		node.set_meta("spider_move_t", clamped_t)

		var from_pos := _pos(from_cell)
		var to_pos := _pos(to_cell)
		node.position = from_pos.lerp(to_pos, clamped_t)
		if int(_fog_state.get(from_cell, FOG_HIDDEN)) == FOG_VISIBLE or int(_fog_state.get(to_cell, FOG_HIDDEN)) == FOG_VISIBLE:
			node.visible = true

		if clamped_t >= 1.0:
			arrivals.append({"from": from_cell, "to": to_cell, "node": node})

	for item in arrivals:
		if _game_over_pending:
			return
		var from_cell := item["from"] as Vector2i
		var to_cell := item["to"] as Vector2i
		var node := item["node"] as Node3D
		if node == null or not is_instance_valid(node):
			continue
		if String(hazards.get(from_cell, "")) != "spider":
			continue
		hazards.erase(from_cell)
		_hazard_nodes.erase(from_cell)
		hazards[to_cell] = "spider"
		_hazard_nodes[to_cell] = node
		node.set_meta("spider_moving", false)
		node.set_meta("spider_move_t", 0.0)
		node.position = _pos(to_cell)
		node.visible = int(_fog_state.get(to_cell, FOG_HIDDEN)) == FOG_VISIBLE
		if to_cell == player_cell:
			_trigger_spider_catch()

func _process_spiders(delta: float) -> void:
	if _game_over_pending:
		return
	_update_spider_motion(delta)
	if _game_over_pending:
		return
	_spider_move_timer += delta
	if _spider_move_timer < SPIDER_MOVE_INTERVAL:
		return
	_spider_move_timer -= SPIDER_MOVE_INTERVAL

	var spider_cells: Array[Vector2i] = []
	for cell in hazards.keys():
		if String(hazards.get(cell, "")) == "spider":
			spider_cells.append(cell)

	for old_cell in spider_cells:
		if _game_over_pending:
			return
		if String(hazards.get(old_cell, "")) != "spider":
			continue
		var node := _hazard_nodes.get(old_cell) as Node3D
		_step_spider(old_cell, node)

# Spiders written into a layout right next to the spawn would catch the player
# before they can react, so move them somewhere safely away.
func _relocate_spawn_spiders() -> void:
	var too_close: Array[Vector2i] = []
	for cell in hazards.keys():
		if String(hazards[cell]) != "spider":
			continue
		if absi(cell.x - player_cell.x) + absi(cell.y - player_cell.y) <= SPAWN_SPIDER_CLEAR_STEPS:
			too_close.append(cell)
	if too_close.is_empty():
		return
	var pool: Array[Vector2i] = []
	for cell in _all_cells:
		if wall_set.has(cell) or cell == exit_cell or hazards.has(cell) or leaves.has(cell):
			continue
		if _is_near_player_start(cell) or _is_near_exit(cell, EXIT_SAFE_SPAWN_RADIUS):
			continue
		pool.append(cell)
	pool.shuffle()
	for cell in too_close:
		var node := _hazard_nodes.get(cell) as Node3D
		hazards.erase(cell)
		_hazard_nodes.erase(cell)
		if pool.is_empty():
			if node:
				node.queue_free()
			continue
		var dest: Vector2i = pool.pop_back()
		hazards[dest] = "spider"
		_hazard_nodes[dest] = node
		if node:
			node.position = _pos(dest)
			node.set_meta("spider_next_cell", dest)

func _make_spike(cell: Vector2i) -> void:
	var node := Node3D.new()
	node.set_meta("spike_variant", int(_spike_rng.randi()))
	var spike_script := load("res://scripts/spike_3d.gd") as Script
	if spike_script == null:
		return
	node.set_script(spike_script)
	node.position = _pos(cell)
	objects_layer.add_child(node)
	hazards[cell] = "spike"
	_hazard_nodes[cell] = node

func _make_exit(cell: Vector2i) -> void:
	exit_node = Node3D.new()
	exit_node.set_script(Exit3DScript)
	exit_node.position = _pos(cell)
	exit_node.set_meta("open", false)
	objects_layer.add_child(exit_node)

# ── Caterpillar ──

func _rebuild_caterpillar() -> void:
	for c in cat_layer.get_children():
		c.queue_free()
	segment_nodes.clear()
	_body_shadow = null
	for i in segment_cells.size():
		var node := Node3D.new()
		node.set_script(Segment3DScript)
		node.set_meta("seg_type", _seg_type(i))
		node.set_meta("seg_index", i)
		node.add_to_group("caterpillar_segment_3d")
		if i == 0:
			node.add_to_group("player_head_3d")
		cat_layer.add_child(node)
		segment_nodes.append(node)
	_update_positions()
	_segment_targets = _calc_positions()
	_update_rotations_instant()
	_segment_target_rots = _calc_target_rotations()
	_update_taper()
	_ensure_body_shadow()
	_update_body_shadow()

func _ensure_body_shadow() -> void:
	if _body_shadow:
		return
	_body_shadow = MeshInstance3D.new()
	var mesh := QuadMesh.new()
	mesh.size = Vector2(1.0, 1.0)
	_body_shadow.mesh = mesh
	_body_shadow.rotation.x = -PI * 0.5  # lay flat on ground
	var shadow_mat := ShaderMaterial.new()
	shadow_mat.render_priority = -1
	var shader := Shader.new()
	shader.code = """
shader_type spatial;
render_mode blend_mix, depth_draw_opaque, cull_disabled, unshaded, shadows_disabled;

uniform float corner_radius = 0.15;

void fragment() {
	// UV 0..1 -> centered -0.5..0.5
	vec2 p = UV - 0.5;
	// Rounded rectangle SDF
	vec2 d = abs(p) - (vec2(0.5) - vec2(corner_radius));
	float sdf = length(max(d, vec2(0.0))) + min(max(d.x, d.y), 0.0) - corner_radius;
	// Soft edge falloff
	float alpha = 1.0 - smoothstep(-0.06, 0.02, sdf);
	// Fade at edges for natural look
	alpha *= 0.16;
	ALBEDO = vec3(0.0);
	ALPHA = alpha;
}
"""
	shadow_mat.shader = shader
	_body_shadow.material_override = shadow_mat
	_body_shadow.cast_shadow = GeometryInstance3D.SHADOW_CASTING_SETTING_OFF
	cat_layer.add_child(_body_shadow)

func _update_body_shadow() -> void:
	if not _body_shadow:
		return
	if segment_nodes.is_empty():
		_body_shadow.visible = false
		return
	_body_shadow.visible = true
	var center := Vector3.ZERO
	for segment in segment_nodes:
		center += segment.position
	center /= float(segment_nodes.size())
	var head_pos := segment_nodes[0].position
	var tail_pos := segment_nodes[-1].position
	var spine := head_pos - tail_pos
	var length := maxf(spine.length() + 0.8, 2.0)
	var width := 0.75
	var yaw := atan2(spine.x, spine.z)
	_body_shadow.position = Vector3(center.x, 0.03, center.z)
	# Quad is rotated flat (-90 on X), so we scale X=width, Y=length
	_body_shadow.rotation = Vector3(-PI * 0.5, 0.0, -yaw)
	_body_shadow.scale = Vector3(width, length, 1.0)

func _calc_positions() -> Array[Vector3]:
	var spacing := CELL * 0.30
	var positions: Array[Vector3] = []

	# Build polyline from grid cell centres
	var path: Array[Vector3] = []
	for cell in segment_cells:
		path.append(_pos(cell))

	positions.append(path[0])

	var total_dist := 0.0
	for seg_i in range(1, segment_cells.size()):
		total_dist += spacing
		# Walk along the polyline to find the point at total_dist
		var walked := 0.0
		var found := false
		for j in range(path.size() - 1):
			var seg_len := path[j].distance_to(path[j + 1])
			if walked + seg_len >= total_dist:
				var t := (total_dist - walked) / seg_len if seg_len > 0.0 else 0.0
				positions.append(path[j].lerp(path[j + 1], t))
				found = true
				break
			walked += seg_len
		if not found:
			positions.append(path[-1])

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

func _seg_dir(i: int) -> Vector2i:
	## Return the direction segment i should face.
	## Falls back to the segment ahead or `facing` when cells overlap.
	if i == 0:
		return facing
	var dir := segment_cells[i - 1] - segment_cells[i]
	if dir != Vector2i.ZERO:
		return dir
	# Overlapping cells – inherit direction from the segment ahead
	for j in range(i - 1, -1, -1):
		var d: Vector2i
		if j == 0:
			d = facing
		else:
			d = segment_cells[j - 1] - segment_cells[j]
		if d != Vector2i.ZERO:
			return d
	return facing

func _yaw_from_path_tangent(tangent: Vector3) -> float:
	if tangent.length_squared() <= 0.000001:
		return _dir_angle_y(facing)
	return atan2(-tangent.x, -tangent.z)

func _calc_target_rotations(positions: Array[Vector3] = []) -> Array[float]:
	var path_positions := positions
	if path_positions.is_empty():
		path_positions = _calc_positions()
	var rots: Array[float] = []
	for i in path_positions.size():
		if i == 0:
			rots.append(_dir_angle_y(facing))
			continue

		var tangent := Vector3.ZERO
		if i < path_positions.size() - 1:
			tangent = path_positions[i - 1] - path_positions[i + 1]
		if tangent.length_squared() <= 0.000001:
			tangent = path_positions[i - 1] - path_positions[i]

		rots.append(_yaw_from_path_tangent(tangent))
	return rots

func _update_rotations_instant() -> void:
	var positions := _calc_positions()
	var target_rots := _calc_target_rotations(positions)
	for i in segment_nodes.size():
		if i < target_rots.size():
			segment_nodes[i].rotation.y = target_rots[i]
		var dir := _seg_dir(i)
		var is_horizontal := (dir == Vector2i.LEFT or dir == Vector2i.RIGHT)
		segment_nodes[i].update_direction(is_horizontal)

func _update_taper() -> void:
	var n := segment_nodes.size()
	for i in n:
		var s := 1.0
		if i == 0:
			s = 1.0
		elif i == n - 1:
			s = 0.7
		else:
			s = 1.0
		segment_nodes[i].scale = Vector3(s, s, s)

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
	elif event is InputEventKey and event.keycode == KEY_SPACE and event.pressed and not event.echo:
		if _intro_active:
			_dismiss_intro()
		_start_bite()
	elif _intro_active and event is InputEventKey and event.pressed and not event.echo:
		_dismiss_intro()

func _process(delta: float) -> void:
	_frame_count += 1
	# Diagnostic heartbeat every 5 seconds
	_diag_timer += delta
	if _diag_timer >= 5.0:
		var node_count := Performance.get_monitor(Performance.OBJECT_NODE_COUNT)
		var obj_count := Performance.get_monitor(Performance.OBJECT_COUNT)
		var mem_static := Performance.get_monitor(Performance.MEMORY_STATIC) / 1048576.0
		var mem_msg := Performance.get_monitor(Performance.MEMORY_MESSAGE_BUFFER_MAX) / 1048576.0
		var fps := Performance.get_monitor(Performance.TIME_FPS)
		var draw_calls := Performance.get_monitor(Performance.RENDER_TOTAL_DRAW_CALLS_IN_FRAME)
		var vram := Performance.get_monitor(Performance.RENDER_VIDEO_MEM_USED) / 1048576.0
		print("[DIAG t=%.0f] FPS=%.0f nodes=%d objs=%d mem=%.1fMB msgbuf=%.1fMB vram=%.1fMB draws=%.0f moves=%d segments=%d catchildren=%d" % [
			_diag_timer + 5.0, fps, node_count, obj_count, mem_static, mem_msg, vram, draw_calls, _move_count, segment_nodes.size(), cat_layer.get_child_count()])
		_diag_timer = 0.0

	# ── Bush biting ──
	_process_bite(delta)
	if _lantern_timer > 0.0:
		_lantern_timer = maxf(0.0, _lantern_timer - delta)
		var current_radius := _effective_reveal_radius()
		if absf(current_radius - _last_effective_reveal_radius) > 0.001:
			_refresh_fog_visibility(player_cell)
		_update_hud()
	if _dizzy_timer > 0.0:
		_dizzy_timer = maxf(0.0, _dizzy_timer - delta)
		_update_hud()
	if _wormhole_cooldown > 0.0:
		_wormhole_cooldown = maxf(0.0, _wormhole_cooldown - delta)
	for wormhole in _wormhole_nodes.values():
		var node := wormhole as Node3D
		if node:
			node.rotation.y += delta * 1.6
	if not _intro_active:
		_process_spiders(delta)
	_process_spinners(delta)
	_process_dynamics(delta)

	# ── Debug camera controls ──
	# ROTATION:  Q/E = tilt (X), Z/C = yaw (Y), R/T = roll (Z)
	# POSITION:  I/K = forward/back, J/L = left/right, U/O = up/down
	# ZOOM:      N/M = zoom out/in (ortho size)
	# PRINT:     P = print all camera values
	# Hold Shift for finer control
	var rot_speed := 30.0 * delta
	var move_speed := 10.0 * delta
	var zoom_speed := 5.0 * delta
	if Input.is_key_pressed(KEY_SHIFT):
		rot_speed *= 0.2
		move_speed *= 0.2
		zoom_speed *= 0.2
	# Rotation
	if Input.is_key_pressed(KEY_Q):
		cam.rotation_degrees.x -= rot_speed
	if Input.is_key_pressed(KEY_E):
		cam.rotation_degrees.x += rot_speed
	if Input.is_key_pressed(KEY_Z):
		cam.rotation_degrees.y -= rot_speed
	if Input.is_key_pressed(KEY_C):
		cam.rotation_degrees.y += rot_speed
	if Input.is_key_pressed(KEY_R):
		cam.rotation_degrees.z -= rot_speed
	if Input.is_key_pressed(KEY_T):
		cam.rotation_degrees.z += rot_speed
	# Position
	if Input.is_key_pressed(KEY_J):
		cam.position.x -= move_speed
	if Input.is_key_pressed(KEY_L):
		cam.position.x += move_speed
	if Input.is_key_pressed(KEY_I):
		cam.position.z -= move_speed
	if Input.is_key_pressed(KEY_K):
		cam.position.z += move_speed
	if Input.is_key_pressed(KEY_U):
		cam.position.y += move_speed
	if Input.is_key_pressed(KEY_O):
		cam.position.y -= move_speed
	# Zoom (FOV)
	if Input.is_key_pressed(KEY_N):
		cam.fov = minf(cam.fov + zoom_speed * 5.0, 90.0)
	if Input.is_key_pressed(KEY_M):
		cam.fov = maxf(cam.fov - zoom_speed * 5.0, 10.0)
	# Print
	if Input.is_key_pressed(KEY_P):
		if not _p_was_pressed:
			print(">>> CAM rotation=%s  position=%s  fov=%.1f" % [cam.rotation_degrees, cam.position, cam.fov])
		_p_was_pressed = true
	else:
		_p_was_pressed = false

	# Smooth camera follow – lerp look target, recompute position + look_at
	var new_look := _clamp_cam_look_target(_cam_look_target)
	var current_look := cam.position - CAM_OFFSET
	current_look = current_look.lerp(new_look, minf(delta * 12.0, 1.0))
	cam.position = current_look + CAM_OFFSET
	cam.look_at(current_look, Vector3.UP)

	# Smooth segment interpolation
	var lerp_speed: float
	if _is_reversing:
		lerp_speed = minf(delta * 5.0, 1.0)
	else:
		lerp_speed = minf(delta * 8.0, 1.0)
	var crawl_alpha := 0.0
	if _move_anim_remaining > 0.0:
		_crawl_motion_time += delta * (5.0 if _is_reversing else 7.0)
		var anim_duration := (REVERSE_MOVE_DURATION if _is_reversing else FORWARD_MOVE_DURATION) / _effective_move_speed_mult()
		crawl_alpha = sin(clampf((1.0 - (_move_anim_remaining / anim_duration)) * PI, 0.0, PI))
	for i in segment_nodes.size():
		if i < _segment_targets.size():
			var target_pos := _segment_targets[i]
			if crawl_alpha > 0.0:
				var phase := _crawl_motion_time - float(i) * 0.85
				var amp := 0.13 if i > 0 and i < segment_nodes.size() - 1 else 0.08
				target_pos.y += sin(phase) * amp * crawl_alpha
			segment_nodes[i].position = segment_nodes[i].position.lerp(target_pos, lerp_speed)
	var live_positions: Array[Vector3] = []
	for segment in segment_nodes:
		live_positions.append(segment.position)
	var live_rots := _calc_target_rotations(live_positions)
	for i in segment_nodes.size():
		if i < live_rots.size():
			segment_nodes[i].rotation.y = lerp_angle(segment_nodes[i].rotation.y, live_rots[i], lerp_speed)
	_update_body_shadow()

	if _move_anim_remaining > 0.0:
		_move_anim_remaining = maxf(_move_anim_remaining - delta, 0.0)
		if _move_anim_remaining <= 0.0:
			if _allow_busy_release:
				is_busy = false

	if _move_anim_remaining <= 0.0 and (not is_busy or not _allow_busy_release):
		_set_move_sound_active(false)

	# Keep bite mood authoritative: no idle look/sleep while chewing/biting.
	if _is_biting:
		_idle_timer = 0.0
		if _is_looking_at_camera:
			_is_looking_at_camera = false
			if segment_nodes.size() > 0 and segment_nodes[0].has_method("set_idle"):
				segment_nodes[0].set_idle(false)

	# ── Idle detection: tell head segment it's idle ──
	if not _is_biting:
		_idle_timer += delta
		if _idle_timer >= IDLE_LOOK_DELAY and not _is_looking_at_camera:
			_is_looking_at_camera = true
			if segment_nodes.size() > 0 and segment_nodes[0].has_method("set_idle"):
				segment_nodes[0].set_idle(true)

	var dir := _get_held_dir()
	if dir == Vector2i.ZERO:
		move_timer = 0.0
		return
	var repeat_delay := (REVERSE_REPEAT_DELAY if dir == -facing else MOVE_REPEAT_DELAY) / _effective_move_speed_mult()
	move_timer += delta
	if move_timer >= repeat_delay:
		move_timer -= repeat_delay
		_try_move(dir)

# ── Movement ──

func _try_move(dir: Vector2i) -> void:
	if _intro_active:
		_dismiss_intro()
	if is_busy:
		if not _allow_busy_release:
			return
		# Allow smooth continuous crawling only when continuing forward in the same direction.
		if _move_anim_remaining > 0.0 and (_is_reversing or dir != facing):
			return
	# Reset idle on any movement
	_idle_timer = 0.0
	if _is_looking_at_camera:
		_is_looking_at_camera = false
		if segment_nodes.size() > 0 and segment_nodes[0].has_method("set_idle"):
			segment_nodes[0].set_idle(false)
	var reverse_dir := -facing
	if dir == reverse_dir:
		_move_backward()
		return
	_is_reversing = false
	facing = dir
	var target := segment_cells[0] + dir
	if wall_set.has(target):
		_on_blocked_by_wall(target)
		_bump()
		return
	if _is_spin_blocked(target):
		_on_blocked_by_spinner()
		_bump()
		return
	if _is_exit_locked(target):
		_on_reached_locked_exit()
		_bump()
		return
	if segment_cells.has(target) and target != segment_cells[-1]:
		_bump()
		return
	_move_to(target)

func _move_backward() -> void:
	_is_reversing = true
	is_busy = true
	_allow_busy_release = true
	_move_count += 1

	# Tail leads: find a free cell adjacent to the tail to extend into
	var n := segment_cells.size()
	var tail_dir: Vector2i
	if n > 1:
		tail_dir = segment_cells[n - 1] - segment_cells[n - 2]
	else:
		tail_dir = -facing

	# Try straight first, then perpendicular directions
	var try_dirs: Array[Vector2i] = [tail_dir]
	if tail_dir.x == 0:
		try_dirs.append(Vector2i.LEFT)
		try_dirs.append(Vector2i.RIGHT)
	else:
		try_dirs.append(Vector2i.UP)
		try_dirs.append(Vector2i.DOWN)

	var new_tail := Vector2i.ZERO
	var found_tail := false
	for d in try_dirs:
		var candidate: Vector2i = segment_cells[n - 1] + d
		if _is_spin_blocked(candidate) or _is_exit_locked(candidate):
			continue
		if not wall_set.has(candidate) and not segment_cells.has(candidate):
			new_tail = candidate
			found_tail = true
			break
		# Also allow if it's the head cell (which will vacate)
		if not wall_set.has(candidate) and candidate == segment_cells[0]:
			new_tail = candidate
			found_tail = true
			break
	if not found_tail:
		is_busy = false
		_bump()
		return

	# Slide every segment toward the tail: seg[i] = old seg[i+1], tail = new cell
	var prev := segment_cells.duplicate()
	for i in range(0, n - 1):
		segment_cells[i] = prev[i + 1]
	segment_cells[n - 1] = new_tail

	_segment_targets = _calc_positions()
	_segment_target_rots = _calc_target_rotations()
	player_cell = segment_cells[0]
	_cam_look_target = _head_cam_target(segment_cells[0])
	_refresh_fog_visibility(player_cell)

	# When reversing, the tail is the leading end — check it for pickups/hazards
	var lead_cell := new_tail
	_collect_bonus(lead_cell)
	var teleported_lead := _try_wormhole_teleport(lead_cell)
	if teleported_lead != lead_cell:
		lead_cell = teleported_lead
		segment_cells[0] = lead_cell
		player_cell = lead_cell
		_segment_targets = _calc_positions()
		_segment_target_rots = _calc_target_rotations()
		_cam_look_target = _head_cam_target(lead_cell)
		_collect_bonus(lead_cell)
		_refresh_fog_visibility(player_cell)
	if leaves.has(lead_cell):
		var collected_variant := int((leaves[lead_cell] as Node).get_meta("fruit_variant", -1))
		leaves[lead_cell].queue_free()
		leaves.erase(lead_cell)
		leaves_left -= 1
		_register_collected_fruit(collected_variant)
		_on_fruit_eaten()
		if segment_nodes.size() > 0 and segment_nodes[0].has_method("set_expression"):
			segment_nodes[0].set_expression("happy", 1.2)
		# Grow from the head side (opposite of travel direction)
		var head_dir: Vector2i
		if n > 1:
			head_dir = prev[0] - prev[1]
		else:
			head_dir = facing
		var extra_cell: Vector2i = segment_cells[0] + head_dir
		segment_cells.insert(0, extra_cell)
		var node := Node3D.new()
		node.set_script(Segment3DScript)
		node.set_meta("seg_type", "body")
		node.set_meta("seg_index", 0)
		cat_layer.add_child(node)
		segment_nodes.insert(0, node)
		var positions := _calc_positions()
		node.position = positions[0]
		segment_nodes[0].update_seg_type(_seg_type(0))
		segment_nodes[1].update_seg_type(_seg_type(1))
		_segment_targets = _calc_positions()
		_segment_target_rots = _calc_target_rotations()
		player_cell = segment_cells[0]
		_cam_look_target = _head_cam_target(segment_cells[0])
	_check_golden_fruit(lead_cell)
	_update_taper()
	for sn in segment_nodes:
		sn.wiggle_legs(0.65)
	_move_anim_remaining = REVERSE_MOVE_DURATION / _effective_move_speed_mult()
	_set_move_sound_active(true)

	if hazards.has(lead_cell):
		var hazard_type := String(hazards[lead_cell])
		if hazard_type == "spider":
			_game_over_pending = true
			_allow_busy_release = false
			await _lose()
			return
		elif hazard_type == "spike":
			if _snd_ouch:
				_snd_ouch.pitch_scale = randf_range(0.95, 1.08)
				_snd_ouch.play()
			if not _apply_spike_damage():
				_allow_busy_release = false
				await _lose()
				return
			_on_hurt("Ouch! Spikes cost you a segment.")
			_update_hud()
		elif hazard_type == "mushroom":
			_remove_mushroom(lead_cell)
			if _snd_spider:
				_snd_spider.pitch_scale = 0.85
				_snd_spider.play()
			if not _apply_mushroom_debuff():
				_allow_busy_release = false
				await _lose()
				return
			_on_hurt("Yuck! A dizzy mushroom - you are slow for a bit.")
			_update_hud()
	_update_exit_state()
	if lead_cell == exit_cell and _objective_complete():
		_allow_busy_release = false
		if _snd_portal:
			_snd_portal.play()
		_win()
		return
	if lead_cell == exit_cell:
		_on_reached_locked_exit()

	_refresh_guide()
	_update_hud()

func _move_to(target: Vector2i) -> void:
	is_busy = true
	_allow_busy_release = true
	_move_count += 1
	var prev := segment_cells.duplicate()
	segment_cells[0] = target
	for i in range(1, segment_cells.size()):
		segment_cells[i] = prev[i - 1]

	_segment_targets = _calc_positions()
	_segment_target_rots = _calc_target_rotations()
	_cam_look_target = _head_cam_target(target)
	player_cell = target
	_collect_bonus(target)
	_refresh_fog_visibility(player_cell)
	var teleported_target := _try_wormhole_teleport(target)
	if teleported_target != target:
		target = teleported_target
		segment_cells[0] = target
		player_cell = target
		_segment_targets = _calc_positions()
		_segment_target_rots = _calc_target_rotations()
		_cam_look_target = _head_cam_target(target)
		_collect_bonus(target)
		_refresh_fog_visibility(player_cell)

	# Collect leaf
	if leaves.has(target):
		var collected_variant := int((leaves[target] as Node).get_meta("fruit_variant", -1))
		leaves[target].queue_free()
		leaves.erase(target)
		leaves_left -= 1
		_register_collected_fruit(collected_variant)
		_on_fruit_eaten()
		# Happy sparkle leaf sound
		if _snd_leaf:
			_snd_leaf.pitch_scale = randf_range(0.9, 1.15)
			_snd_leaf.play()
		if segment_nodes.size() > 0 and segment_nodes[0].has_method("set_expression"):
			segment_nodes[0].set_expression("happy", 1.2)
		var new_cell: Vector2i = prev[-1]
		segment_cells.append(new_cell)
		var node := Node3D.new()
		node.set_script(Segment3DScript)
		var tail_positions := _calc_positions()
		node.position = tail_positions[-1]
		node.set_meta("seg_type", "tail")
		node.set_meta("seg_index", segment_cells.size() - 1)
		cat_layer.add_child(node)
		segment_nodes.append(node)
		if segment_nodes.size() > 2:
			segment_nodes[-2].update_seg_type("body")
		_segment_targets = _calc_positions()
		_segment_target_rots = _calc_target_rotations()
	_check_golden_fruit(target)
	_update_taper()
	for n in segment_nodes:
		n.wiggle_legs(1.0)
	_move_anim_remaining = FORWARD_MOVE_DURATION / _effective_move_speed_mult()
	_set_move_sound_active(true)

	if hazards.has(target):
		var hazard_type := String(hazards[target])
		if hazard_type == "spider":
			_game_over_pending = true
			_allow_busy_release = false
			if _snd_spider:
				_snd_spider.play()
			await _lose()
			return
		elif hazard_type == "spike":
			if _snd_ouch:
				_snd_ouch.pitch_scale = randf_range(0.95, 1.08)
				_snd_ouch.play()
			if not _apply_spike_damage():
				_allow_busy_release = false
				await _lose()
				return
			_on_hurt("Ouch! Spikes cost you a segment.")
			_update_hud()
		elif hazard_type == "mushroom":
			_remove_mushroom(target)
			if _snd_spider:
				_snd_spider.pitch_scale = 0.85
				_snd_spider.play()
			if not _apply_mushroom_debuff():
				_allow_busy_release = false
				await _lose()
				return
			_on_hurt("Yuck! A dizzy mushroom - you are slow for a bit.")
			_update_hud()
	_update_exit_state()
	if target == exit_cell and _objective_complete():
		_allow_busy_release = false
		if _snd_portal:
			_snd_portal.play()
		_win()
		return
	if target == exit_cell:
		_on_reached_locked_exit()

	_refresh_guide()
	_update_hud()

func _bump() -> void:
	pass

func _try_wormhole_teleport(entry_cell: Vector2i) -> Vector2i:
	if _wormhole_cooldown > 0.0:
		return entry_cell
	if not _wormholes.has(entry_cell):
		return entry_cell
	var dest := _wormholes[entry_cell] as Vector2i
	if not _is_inside_maze(dest) or wall_set.has(dest):
		return entry_cell

	_wormhole_cooldown = WORMHOLE_TELEPORT_COOLDOWN
	if _snd_portal:
		_snd_portal.pitch_scale = 1.12
		_snd_portal.play()
	if segment_nodes.size() > 0 and segment_nodes[0].has_method("set_expression"):
		segment_nodes[0].set_expression("surprised", 0.35)
	return dest

func _apply_spike_damage() -> bool:
	_shoe_speed_active = false
	# Keep at least head + one segment alive; otherwise the hit is fatal.
	if segment_cells.size() <= 2:
		return false

	segment_cells.pop_back()
	if not segment_nodes.is_empty():
		var removed: Node3D = segment_nodes.pop_back()
		if removed:
			removed.queue_free()

	for i in segment_nodes.size():
		segment_nodes[i].set_meta("seg_index", i)
		if segment_nodes[i].has_method("update_seg_type"):
			segment_nodes[i].update_seg_type(_seg_type(i))

	_segment_targets = _calc_positions()
	_segment_target_rots = _calc_target_rotations()
	_update_taper()
	_update_body_shadow()
	if segment_nodes.size() > 0 and segment_nodes[0].has_method("set_expression"):
		segment_nodes[0].set_expression("surprised", 0.7)
	return true

func _apply_mushroom_debuff() -> bool:
	_dizzy_timer = maxf(_dizzy_timer, DIZZY_DURATION)
	return _apply_spike_damage()

func _bite_duration_for_length() -> float:
	# Longer caterpillar chews faster.
	var extra_len := maxi(segment_cells.size() - 5, 0)
	var speed_mult := 1.0 + float(extra_len) * 0.08
	return maxf(2.2, BITE_DURATION / speed_mult)

# ── Bush biting ──

func _start_bite() -> void:
	if _is_biting or is_busy:
		return
	# Check if there's a wall in front of the head
	var target_cell := segment_cells[0] + facing
	if _is_spin_blocked(target_cell):
		_start_ring_bite(_spin_cell_owner[target_cell] as Node3D, target_cell)
		return
	if not wall_set.has(target_cell):
		return
	if not _bush_wall_cells.has(target_cell):
		return
	# Can't bite border walls (edges of the maze)
	if target_cell.x <= 0 or target_cell.x >= _maze_w - 1:
		return
	if target_cell.y <= 0 or target_cell.y >= _maze_h - 1:
		return
	_bite_target = target_cell
	_is_biting = true
	_bite_timer = _bite_duration_for_length()
	_bite_face_loop_timer = BITE_FACE_LOOP_INTERVAL
	_bite_face_is_biting = true
	is_busy = true

	# Apply the bite immediately on press, then keep chewing animation/sound.
	if not _bite_count.has(_bite_target):
		_bite_count[_bite_target] = 0
	_bite_count[_bite_target] += 1
	_apply_bush_bite_visual(_bite_target, _bite_count[_bite_target])
	if _bite_count[_bite_target] >= BITES_TO_EAT:
		if _snd_eat:
			_snd_eat.play()
		_eat_wall(_bite_target)
		_bite_count.erase(_bite_target)

	# Chomp! Faster bite when caterpillar is longer.
	if _snd_bite:
		_snd_bite.pitch_scale = clampf(BITE_DURATION / maxf(_bite_timer, 0.01), 1.0, 2.2)
		_snd_bite.play()
	# Start with biting, then alternate biting/chewing until bite ends.
	if segment_nodes.size() > 0 and segment_nodes[0].has_method("set_expression"):
		segment_nodes[0].set_expression("biting", BITE_FACE_LOOP_INTERVAL)

func _process_bite(delta: float) -> void:
	if not _is_biting:
		return
	_bite_face_loop_timer -= delta
	if _bite_face_loop_timer <= 0.0:
		_bite_face_loop_timer += BITE_FACE_LOOP_INTERVAL
		_bite_face_is_biting = not _bite_face_is_biting
		if segment_nodes.size() > 0 and segment_nodes[0].has_method("set_expression"):
			segment_nodes[0].set_expression("biting" if _bite_face_is_biting else "chewing", BITE_FACE_LOOP_INTERVAL)
	_bite_timer -= delta
	# Head wiggle while biting
	if segment_nodes.size() > 0:
		var wiggle := sin(_bite_timer * 18.0) * 0.008
		segment_nodes[0].position.x += wiggle
	if _bite_timer <= 0.0:
		_finish_bite()

func _finish_bite() -> void:
	_is_biting = false
	_bite_face_loop_timer = 0.0
	_bite_face_is_biting = true
	if segment_nodes.size() > 0 and segment_nodes[0].has_method("set_expression"):
		segment_nodes[0].set_expression("happy", 0.6)
	is_busy = false

func _ensure_bite_cavity_material() -> StandardMaterial3D:
	if _bite_cavity_mat:
		return _bite_cavity_mat
	var mat := StandardMaterial3D.new()
	mat.albedo_color = Color(0.30, 0.19, 0.10)
	mat.roughness = 0.96
	mat.specular = 0.02
	_bite_cavity_mat = mat
	return _bite_cavity_mat

func _make_bitten_bush(cell: Vector2i) -> Node3D:
	var wall_pos := _pos(cell)
	var scales: Vector2 = _cell_wall_scales.get(cell, Vector2(1.0, 1.0))
	var root := CSGCombiner3D.new()
	root.position = Vector3(wall_pos.x, WALL_HEIGHT * 0.5 * scales.y, wall_pos.z)
	root.scale = Vector3(scales.x, scales.y, scales.x)
	root.use_collision = false

	var body := CSGBox3D.new()
	body.size = Vector3(CELL, WALL_HEIGHT, CELL)
	body.material = _wall_mat
	root.add_child(body)

	maze_layer.add_child(root)
	return root


func _add_bite_cut_sphere(parent: Node3D, cut_pos: Vector3, radius: float, scale_vec: Vector3) -> void:
	var cut := CSGSphere3D.new()
	cut.operation = CSGShape3D.OPERATION_SUBTRACTION
	cut.radius = radius
	cut.position = cut_pos
	cut.scale = scale_vec
	cut.material = _ensure_bite_cavity_material()
	parent.add_child(cut)

func _add_bite_cutout(bush_root: Node3D, dir_to_head: Vector3, side_dir: Vector3, bite_num: int, cell: Vector2i) -> void:
	var rng := RandomNumberGenerator.new()
	rng.seed = cell.x * 1013 + cell.y * 379 + bite_num * 53
	var base_forward := 0.34 - float(bite_num - 1) * 0.03
	var base_center := dir_to_head * base_forward + Vector3(0.0, 0.16 - float(bite_num - 1) * 0.01, 0.0)
	base_center += side_dir * rng.randf_range(-0.03, 0.03)

	# Large 3-circle "apple bite" silhouette. One stage should read as roughly one third removed.
	var stage_scale := 1.0 + float(bite_num - 1) * 0.22
	_add_bite_cut_sphere(
		bush_root,
		base_center + side_dir * -0.15 + Vector3(0.0, 0.10, 0.0),
		0.23 * stage_scale,
		Vector3(1.18, 1.02, 1.30))
	_add_bite_cut_sphere(
		bush_root,
		base_center + side_dir * 0.15 + Vector3(0.0, 0.10, 0.0),
		0.23 * stage_scale,
		Vector3(1.18, 1.02, 1.30))
	_add_bite_cut_sphere(
		bush_root,
		base_center + Vector3(0.0, -0.05, 0.0),
		0.28 * stage_scale,
		Vector3(1.22, 0.98, 1.38))

	# Extra interior scoop makes the bite look deeper and more visible from the camera.
	_add_bite_cut_sphere(
		bush_root,
		base_center - dir_to_head * (0.03 + float(bite_num - 1) * 0.02) + Vector3(0.0, 0.02, 0.0),
		0.20 * stage_scale,
		Vector3(0.95, 0.85, 1.35))

	# Slight irregularity so it is not a perfect cookie-cutter bite.
	var jag_count := 2 + bite_num
	for _i in jag_count:
		_add_bite_cut_sphere(
			bush_root,
			base_center \
				+ side_dir * rng.randf_range(-0.18, 0.18) \
				+ Vector3(0.0, rng.randf_range(-0.10, 0.12), 0.0) \
				+ dir_to_head * rng.randf_range(-0.02, 0.08),
			rng.randf_range(0.05, 0.09) * stage_scale,
			Vector3(
				rng.randf_range(0.8, 1.25),
				rng.randf_range(0.75, 1.10),
				rng.randf_range(0.9, 1.35)))

func _apply_bush_bite_visual(cell: Vector2i, bite_num: int) -> void:
	var old_bush: Node3D = _bitten_bush_nodes.get(cell)
	var head_pos := _pos(segment_cells[0])
	var dir_to_head := (head_pos - _pos(cell)).normalized()
	var side_dir := Vector3(-dir_to_head.z, 0.0, dir_to_head.x)

	# First bite: detach cell from MultiMesh, spawn a standalone bush we can carve.
	if bite_num == 1 and not _bitten_bush_nodes.has(cell):
		var wall_idx: int = _cell_wall_index.get(cell, -1)
		if wall_idx >= 0 and _wall_mm_inst and _wall_mm_inst.multimesh:
			_wall_mm_inst.multimesh.set_instance_transform(wall_idx,
				Transform3D(Basis.IDENTITY, Vector3(0.0, -9999.0, 0.0)))
		_bitten_bush_hscale[cell] = _cell_wall_scales.get(cell, Vector2(1.0, 1.0)).y

	if old_bush and is_instance_valid(old_bush):
		old_bush.queue_free()

	var bush_node := _make_bitten_bush(cell)
	_bitten_bush_nodes[cell] = bush_node
	for stage in range(1, bite_num + 1):
		_add_bite_cutout(bush_node, dir_to_head, side_dir, stage, cell)

func _eat_wall(cell: Vector2i) -> void:
	# Remove from game logic
	wall_set.erase(cell)
	_wall_cells.erase(cell)
	_bush_wall_cells.erase(cell)
	_rock_wall_cells.erase(cell)
	# Remove old multimesh instances and rebuild without this cell
	if _wall_mm_inst:
		_wall_mm_inst.queue_free()
		_wall_mm_inst = null
	if _rock_mm_inst:
		_rock_mm_inst.queue_free()
		_rock_mm_inst = null
	# Remove the standalone bitten bush completely once eaten.
	var bush_node: Node3D = _bitten_bush_nodes.get(cell)
	if bush_node and is_instance_valid(bush_node):
		bush_node.queue_free()
	_bitten_bush_nodes.erase(cell)
	_bitten_bush_hscale.erase(cell)
	# Legacy bite-mark nodes are no longer used for the primary effect.
	_bite_marks.clear()
	# Rebuild wall meshes
	_build_wall_multimesh()
	# Happy munch expression
	if segment_nodes.size() > 0 and segment_nodes[0].has_method("set_expression"):
		segment_nodes[0].set_expression("biting", 1.5)

func _lose() -> void:
	_set_move_sound_active(false)
	if _guide_arrow:
		_guide_arrow.visible = false
	_show_toast("Caught! Let's try that again...", Color(1.0, 0.45, 0.4), 1.0)
	for n in segment_nodes:
		n.flash_red()
	await get_tree().create_timer(0.7).timeout
	load_level(current_level)

func _win() -> void:
	is_busy = true
	_set_move_sound_active(false)
	if _guide_arrow:
		_guide_arrow.visible = false
	_remove_golden_fruit()
	_toast_timer = 0.0
	if _toast_label:
		_toast_label.modulate.a = 0.0
	var time_bonus := maxi(0, int(round((_par_time - _level_time) * SCORE_TIME_BONUS_PER_SEC)))
	var length_bonus := segment_cells.size() * SCORE_PER_SEGMENT
	_add_score(time_bonus + length_bonus)
	var stars := _star_rating()
	win_panel.visible = true
	var vbox := $CanvasLayer/WinPanel/VBox
	vbox.get_node("Title").text = "Level %d Complete!" % (current_level + 1)
	if current_level >= LEVELS.size() - 1:
		vbox.get_node("SubTitle").text = "You escaped every garden!"
		vbox.get_node("NextButton").text = "Play Again"
	else:
		vbox.get_node("SubTitle").text = "Your caterpillar escaped!"
		vbox.get_node("NextButton").text = "Next Level"
	if _win_stars:
		for i in _win_stars.get_child_count():
			var star := _win_stars.get_child(i) as TextureRect
			star.texture = _star_full_tex if i < stars else _star_empty_tex
	if _win_stats:
		var lines := PackedStringArray()
		lines.append("Time %s  (star goal %s)" % [_format_time(_level_time), _format_time(_par_time)])
		lines.append("Score %d   (time +%d, length +%d)" % [_score, time_bonus, length_bonus])
		if _golden_eaten > 0:
			lines.append("Golden fruits: %d" % _golden_eaten)
		if stars < 3:
			var tips := PackedStringArray()
			if _level_time > _par_time:
				tips.append("be faster")
			if _hits_taken > 0:
				tips.append("avoid spikes and mushrooms")
			lines.append("For 3 stars: " + " and ".join(tips) + ".")
		_win_stats.text = "\n".join(lines)

func _update_hud() -> void:
	if hud_label == null:
		return
	var collected := maxi(_required_total - _required_fruits_left, 0)
	hud_label.text = "Level %d    Fruit %d/%d    %s    Score %d" % [
		current_level + 1, collected, _required_total, _format_time(_level_time), _score]
	if _goal_label:
		_goal_label.text = _objective_status_text()
		var goal_color := Color(0.62, 1.0, 0.55) if _objective_complete() else Color(1.0, 0.93, 0.55)
		_goal_label.add_theme_color_override("font_color", goal_color)
	if _status_label:
		var parts := PackedStringArray()
		parts.append("Length %d" % segment_cells.size())
		if FOG_ENABLED:
			parts.append("Light %.1f" % _effective_reveal_radius())
		if _lantern_timer > 0.0:
			parts.append("Lantern %ds" % int(ceil(_lantern_timer)))
		if _shoe_speed_active:
			parts.append("Sneakers")
		if _combo_speed_timer > 0.0:
			parts.append("Speed boost %ds" % int(ceil(_combo_speed_timer)))
		if _dizzy_timer > 0.0:
			parts.append("Dizzy %ds" % int(ceil(_dizzy_timer)))
		if _golden_node:
			parts.append("Golden fruit %ds!" % int(ceil(_golden_timer)))
		_status_label.text = "   ".join(parts)

func _on_retry() -> void:
	load_level(current_level)

func _on_menu() -> void:
	get_tree().change_scene_to_file("res://scenes/MainMenu.tscn")

func _on_next() -> void:
	load_level((current_level + 1) % LEVELS.size())

# ── Goals, feedback and dynamic events ──

const SCORE_FRUIT := 100
const SCORE_GOLDEN := 500
const SCORE_BONUS_ITEM := 50
const SCORE_PER_SEGMENT := 20
const SCORE_TIME_BONUS_PER_SEC := 10
const PAR_BASE_SECONDS := 20.0
const PAR_SECONDS_PER_STEP := 0.6
const GOLDEN_FIRST_DELAY := 8.0
const GOLDEN_INTERVAL := 14.0
const GOLDEN_LIFETIME := 10.0
const GOLDEN_DROP_HEIGHT := 3.0
const GOLDEN_MIN_STEPS := 3
const GOLDEN_MAX_STEPS := 7
const GOLDEN_SPEED_SECONDS := 5.0
const TOAST_DURATION := 2.6
const SPIDER_ALERT_COOLDOWN := 8.0
const BUSH_HINT_COOLDOWN := 10.0
const LOCKED_EXIT_HINT_COOLDOWN := 3.0
const GUIDE_FRUIT_COLOR := Color(1.0, 0.84, 0.12)
const GUIDE_EXIT_COLOR := Color(0.35, 1.0, 0.55)
const CONTROL_ACTIONS := {
	"move_up": Vector2i.UP,
	"move_down": Vector2i.DOWN,
	"move_left": Vector2i.LEFT,
	"move_right": Vector2i.RIGHT,
}
const LEVEL_TIPS := [
	["Swipe or tap the arrows to crawl.", "Eat fruit to grow longer.", "The yellow arrow points to the nearest fruit."],
	["Spikes and mushrooms cost one body segment.", "Bushes are edible: face one and tap BITE three times."],
	["Spiders hunt you when you get close - keep moving!", "Golden fruit drops from the sky. Grab it before it fades!"],
	["Swirly holes are wormholes - they teleport you.", "Eat fruit quickly in a row for a COMBO speed boost."],
	["This garden wants special fruits - check the goal at the top."],
	["The biggest garden yet. Stay calm and follow the arrow!"],
	["The bush rings turn! Wait until a gap lines up, then crawl through.", "The middle fruit is behind three rings. Bite a ring to hold it still."],
]

static var _texture_cache: Dictionary = {}

var _score := 0
var _level_time := 0.0
var _par_time := 60.0
var _hits_taken := 0
var _required_total := 0
var _intro_active := false
var _intro_shown_level := -1
var _exit_was_open := false
var _guide_arrow: Node3D = null
var _guide_mat: StandardMaterial3D = null
var _guide_target := Vector2i(-1, -1)
var _guide_time := 0.0
var _golden_cell := Vector2i(-1, -1)
var _golden_node: Node3D = null
var _golden_timer := 0.0
var _golden_spawn_timer := GOLDEN_FIRST_DELAY
var _golden_eaten := 0
var _spider_alert_cooldown := 0.0
var _bush_hint_cooldown := 0.0
var _locked_exit_hint_cooldown := 0.0
var _toast_timer := 0.0
var _hud_refresh_timer := 0.0

var _goal_label: Label = null
var _status_label: Label = null
var _toast_label: Label = null
var _intro_panel: Control = null
var _intro_title: Label = null
var _intro_goal: Label = null
var _intro_tips: Label = null
var _win_stars: HBoxContainer = null
var _win_stats: Label = null
var _star_full_tex: Texture2D = null
var _star_empty_tex: Texture2D = null

func _reset_dynamic_state() -> void:
	_score = 0
	_level_time = 0.0
	_hits_taken = 0
	_required_total = 0
	_exit_was_open = false
	_guide_arrow = null
	_guide_mat = null
	_guide_target = Vector2i(-1, -1)
	_golden_cell = Vector2i(-1, -1)
	_golden_node = null
	_golden_timer = 0.0
	_golden_spawn_timer = GOLDEN_FIRST_DELAY
	_golden_eaten = 0
	_spider_alert_cooldown = 0.0
	_bush_hint_cooldown = 0.0
	_locked_exit_hint_cooldown = 0.0
	_toast_timer = 0.0
	if _toast_label:
		_toast_label.modulate.a = 0.0

func _start_level_dynamics() -> void:
	_required_total = _required_fruits_left
	_par_time = _compute_par_time()
	_build_guide_arrow()
	_refresh_guide()
	if _intro_shown_level != current_level:
		_intro_shown_level = current_level
		_show_intro()
	else:
		_intro_active = false
		if _intro_panel:
			_intro_panel.visible = false

func _is_play_active() -> bool:
	return not _intro_active and not _game_over_pending and not win_panel.visible

func _process_dynamics(delta: float) -> void:
	if _toast_timer > 0.0 and _toast_label:
		_toast_timer = maxf(_toast_timer - delta, 0.0)
		_toast_label.modulate.a = clampf(_toast_timer / 0.4, 0.0, 1.0)
	_update_guide_arrow(delta)
	_animate_golden_fruit(delta)
	if not _is_play_active():
		return

	_level_time += delta
	_spider_alert_cooldown = maxf(_spider_alert_cooldown - delta, 0.0)
	_bush_hint_cooldown = maxf(_bush_hint_cooldown - delta, 0.0)
	_locked_exit_hint_cooldown = maxf(_locked_exit_hint_cooldown - delta, 0.0)
	if _leaf_combo_timer > 0.0:
		_leaf_combo_timer = maxf(_leaf_combo_timer - delta, 0.0)
		if _leaf_combo_timer <= 0.0:
			_leaf_combo_count = 0
	if _combo_speed_timer > 0.0:
		_combo_speed_timer = maxf(_combo_speed_timer - delta, 0.0)
	if _combo_reveal_timer > 0.0:
		_combo_reveal_timer = maxf(_combo_reveal_timer - delta, 0.0)
		if _combo_reveal_timer <= 0.0:
			_refresh_fog_visibility(player_cell)

	if _golden_node:
		_golden_timer -= delta
		if _golden_timer <= 0.0:
			_remove_golden_fruit()
			_show_toast("The golden fruit faded away...", Color(0.9, 0.85, 0.7))
	else:
		_golden_spawn_timer -= delta
		if _golden_spawn_timer <= 0.0:
			_golden_spawn_timer = GOLDEN_INTERVAL
			_spawn_golden_fruit()

	_hud_refresh_timer -= delta
	if _hud_refresh_timer <= 0.0:
		_hud_refresh_timer = 0.25
		_update_hud()

func _add_score(points: int) -> void:
	_score += maxi(points, 0)

func _format_time(seconds: float) -> String:
	var total := int(floor(maxf(seconds, 0.0)))
	return "%d:%02d" % [total / 60, total % 60]

func _star_rating() -> int:
	var stars := 1
	if _level_time <= _par_time:
		stars += 1
	if _hits_taken == 0:
		stars += 1
	return stars

func _bfs_distances(from_cell: Vector2i) -> Dictionary:
	var dist := {from_cell: 0}
	var queue: Array[Vector2i] = [from_cell]
	var head := 0
	var dirs: Array[Vector2i] = [Vector2i.UP, Vector2i.DOWN, Vector2i.LEFT, Vector2i.RIGHT]
	while head < queue.size():
		var cur := queue[head]
		head += 1
		var d := int(dist[cur])
		for dir in dirs:
			var nxt := cur + dir
			if dist.has(nxt) or wall_set.has(nxt) or not _is_inside_maze(nxt):
				continue
			dist[nxt] = d + 1
			queue.append(nxt)
	return dist

func _goal_fruit_cells() -> Array[Vector2i]:
	var out: Array[Vector2i] = []
	for cell in leaves.keys():
		if _uses_specific_fruit_objective:
			var node := leaves[cell] as Node
			var variant := int(node.get_meta("fruit_variant", -1)) if node else -1
			if int(_required_fruit_counts.get(variant, 0)) <= 0:
				continue
		out.append(cell)
	return out

# Rough route length (nearest fruit first, then the portal) turned into a star time.
func _compute_par_time() -> float:
	var remaining := _goal_fruit_cells()
	var cur := player_cell
	var steps := 0
	while not remaining.is_empty():
		var dist := _bfs_distances(cur)
		var best_idx := 0
		var best_d := 1 << 30
		for i in remaining.size():
			var d := int(dist.get(remaining[i], 1 << 30))
			if d < best_d:
				best_d = d
				best_idx = i
		if best_d >= (1 << 30):
			best_d = absi(remaining[best_idx].x - cur.x) + absi(remaining[best_idx].y - cur.y)
		steps += best_d
		cur = remaining[best_idx]
		remaining.remove_at(best_idx)
	var to_exit := _bfs_distances(cur)
	steps += int(to_exit.get(exit_cell, absi(exit_cell.x - cur.x) + absi(exit_cell.y - cur.y)))
	return ceilf(PAR_BASE_SECONDS + float(steps) * PAR_SECONDS_PER_STEP + float(_spin_rings.size()) * SPIN_PAR_SECONDS_PER_RING)

func _objective_status_text() -> String:
	if _objective_complete():
		return "GOAL: Crawl into the glowing portal!"
	if _uses_specific_fruit_objective:
		var parts := PackedStringArray()
		for variant in range(FRUIT_VARIANT_NAMES.size()):
			var left := int(_required_fruit_counts.get(variant, 0))
			if left > 0:
				parts.append("%s x%d" % [_fruit_variant_display_name(variant), left])
		return "GOAL: Find %s" % ", ".join(parts)
	return "GOAL: Eat %d more fruit%s" % [_required_fruits_left, "" if _required_fruits_left == 1 else "s"]

func _intro_goal_text() -> String:
	var fruit_part := "Eat all %d fruits" % _required_total
	if _uses_specific_fruit_objective:
		var parts := PackedStringArray()
		for variant in range(FRUIT_VARIANT_NAMES.size()):
			var left := int(_required_fruit_counts.get(variant, 0))
			if left > 0:
				parts.append("%s x%d" % [_fruit_variant_display_name(variant), left])
		fruit_part = "Find and eat: %s" % ", ".join(parts)
	return "%s.\nThen crawl into the glowing portal in the top-right corner.\nFinish within %s and never get hurt for 3 stars!" % [fruit_part, _format_time(_par_time)]

# ── Feedback hooks ──

func _show_toast(text: String, color: Color = Color.WHITE, duration: float = TOAST_DURATION) -> void:
	if _toast_label == null:
		return
	_toast_label.text = text
	_toast_label.add_theme_color_override("font_color", color)
	_toast_label.modulate.a = 1.0
	_toast_timer = duration

func _on_fruit_eaten() -> void:
	if _leaf_combo_timer > 0.0:
		_leaf_combo_count += 1
	else:
		_leaf_combo_count = 1
	_leaf_combo_timer = LEAF_COMBO_WINDOW
	var points := SCORE_FRUIT * maxi(_leaf_combo_count, 1)
	_add_score(points)
	if _leaf_combo_count >= 2:
		_combo_reveal_timer = LEAF_COMBO_REVEAL_SECONDS
		_combo_speed_timer = maxf(_combo_speed_timer, LEAF_COMBO_SPEED_SECONDS)
		_refresh_fog_visibility(player_cell)
		_show_toast("COMBO x%d!  +%d  Speed boost!" % [_leaf_combo_count, points], Color(1.0, 0.7, 0.25))
	elif _required_fruits_left > 0:
		_show_toast("Yum! +%d   %d to go." % [points, _required_fruits_left], Color(1.0, 0.95, 0.6))

func _update_exit_state() -> void:
	var open := _objective_complete()
	if exit_node:
		exit_node.set_meta("open", open)
	if open and not _exit_was_open:
		_exit_was_open = true
		_show_toast("All fruit eaten! The portal is open - go!", GUIDE_EXIT_COLOR, 3.5)
		if _snd_portal:
			_snd_portal.pitch_scale = 0.8
			_snd_portal.play()
		_refresh_guide()

# The finish gate is shut (like a wall) until the goal is met.
func _is_exit_locked(cell: Vector2i) -> bool:
	return cell == exit_cell and not _objective_complete()

func _on_reached_locked_exit() -> void:
	if _locked_exit_hint_cooldown > 0.0:
		return
	_locked_exit_hint_cooldown = LOCKED_EXIT_HINT_COOLDOWN
	_show_toast("The portal is closed. %s first!" % _objective_status_text().trim_prefix("GOAL: "), Color(1.0, 0.8, 0.5))

func _on_blocked_by_wall(cell: Vector2i) -> void:
	if not _bush_wall_cells.has(cell) or _bush_hint_cooldown > 0.0:
		return
	if cell.x <= 0 or cell.y <= 0 or cell.x >= _maze_w - 1 or cell.y >= _maze_h - 1:
		return
	_bush_hint_cooldown = BUSH_HINT_COOLDOWN
	_show_toast("Tap BITE (or Space) 3 times to chew through this bush.", Color(0.7, 1.0, 0.6), 3.0)

func _on_hurt(message: String) -> void:
	_hits_taken += 1
	_show_toast(message, Color(1.0, 0.5, 0.45))

func _on_spider_started_chasing() -> void:
	if _spider_alert_cooldown > 0.0 or not _is_play_active():
		return
	_spider_alert_cooldown = SPIDER_ALERT_COOLDOWN
	_show_toast("A spider spotted you! Crawl away!", Color(1.0, 0.55, 0.35))

# ── Golden fruit: a timed bonus that drops near the caterpillar ──

func _spawn_golden_fruit() -> void:
	var dist := _bfs_distances(player_cell)
	var pool: Array[Vector2i] = []
	for cell in dist.keys():
		var d := int(dist[cell])
		if d < GOLDEN_MIN_STEPS or d > GOLDEN_MAX_STEPS:
			continue
		if cell == exit_cell or segment_cells.has(cell) or leaves.has(cell) or hazards.has(cell):
			continue
		if _bonus_types.has(cell) or _wormholes.has(cell) or _spin_cell_owner.has(cell):
			continue
		pool.append(cell)
	if pool.is_empty():
		return
	var cell: Vector2i = pool[randi() % pool.size()]

	var root := Node3D.new()
	root.position = _pos(cell)
	var fruit := Node3D.new()
	fruit.name = "Fruit"
	fruit.set_meta("fruit_variant", randi_range(0, FRUIT_VARIANT_COUNT - 1))
	fruit.set_script(Leaf3DScript)
	fruit.position.y = GOLDEN_DROP_HEIGHT
	fruit.scale = Vector3.ONE * 1.15
	root.add_child(fruit)

	var ring := MeshInstance3D.new()
	ring.name = "Ring"
	var ring_mesh := TorusMesh.new()
	ring_mesh.inner_radius = 0.34
	ring_mesh.outer_radius = 0.46
	ring.mesh = ring_mesh
	ring.position.y = 0.04
	var ring_mat := StandardMaterial3D.new()
	ring_mat.shading_mode = BaseMaterial3D.SHADING_MODE_UNSHADED
	ring_mat.albedo_color = Color(1.0, 0.82, 0.2)
	ring.material_override = ring_mat
	ring.cast_shadow = GeometryInstance3D.SHADOW_CASTING_SETTING_OFF
	root.add_child(ring)

	objects_layer.add_child(root)
	_golden_node = root
	_golden_cell = cell
	_golden_timer = GOLDEN_LIFETIME
	if _snd_leaf:
		_snd_leaf.pitch_scale = 1.5
		_snd_leaf.play()
	_show_toast("A golden fruit dropped nearby! Grab it fast!", Color(1.0, 0.85, 0.25))

func _animate_golden_fruit(delta: float) -> void:
	if _golden_node == null or not is_instance_valid(_golden_node):
		return
	var fruit := _golden_node.get_node_or_null("Fruit") as Node3D
	if fruit:
		fruit.position.y = maxf(fruit.position.y - delta * 7.0, 0.0)
	var ring := _golden_node.get_node_or_null("Ring") as Node3D
	if ring:
		ring.rotation.y += delta * 2.0
		var pulse := 1.0 + sin(_guide_time * 6.0) * 0.08
		ring.scale = Vector3(pulse, 1.0, pulse)
	# Blink during the last three seconds so kids know it is about to vanish.
	_golden_node.visible = _golden_timer > 3.0 or fmod(_golden_timer, 0.4) > 0.15

func _remove_golden_fruit() -> void:
	if _golden_node and is_instance_valid(_golden_node):
		_golden_node.queue_free()
	_golden_node = null
	_golden_cell = Vector2i(-1, -1)
	_golden_timer = 0.0

func _check_golden_fruit(cell: Vector2i) -> void:
	if _golden_node == null or cell != _golden_cell:
		return
	_remove_golden_fruit()
	_golden_eaten += 1
	_add_score(SCORE_GOLDEN)
	_combo_speed_timer = maxf(_combo_speed_timer, GOLDEN_SPEED_SECONDS)
	if _snd_leaf:
		_snd_leaf.pitch_scale = 1.35
		_snd_leaf.play()
	if segment_nodes.size() > 0 and segment_nodes[0].has_method("set_expression"):
		segment_nodes[0].set_expression("happy", 1.5)
	_show_toast("Golden fruit! +%d and a speed boost!" % SCORE_GOLDEN, Color(1.0, 0.85, 0.25))

# ── Guide arrow: a floating compass over the head ──

func _build_guide_arrow() -> void:
	var root := Node3D.new()
	root.name = "GuideArrow"
	_guide_mat = StandardMaterial3D.new()
	_guide_mat.shading_mode = BaseMaterial3D.SHADING_MODE_UNSHADED
	_guide_mat.albedo_color = GUIDE_FRUIT_COLOR
	_guide_mat.no_depth_test = true
	_guide_mat.render_priority = 10

	var shaft := MeshInstance3D.new()
	var shaft_mesh := BoxMesh.new()
	shaft_mesh.size = Vector3(0.13, 0.04, 0.34)
	shaft.mesh = shaft_mesh
	shaft.position = Vector3(0.0, 0.0, 0.02)
	shaft.material_override = _guide_mat
	shaft.cast_shadow = GeometryInstance3D.SHADOW_CASTING_SETTING_OFF
	root.add_child(shaft)

	var tip := MeshInstance3D.new()
	var tip_mesh := PrismMesh.new()
	tip_mesh.size = Vector3(0.38, 0.3, 0.04)
	tip.mesh = tip_mesh
	# Lay the prism flat so its apex points along -Z.
	tip.rotation_degrees = Vector3(-90.0, 0.0, 0.0)
	tip.position = Vector3(0.0, 0.0, -0.3)
	tip.material_override = _guide_mat
	tip.cast_shadow = GeometryInstance3D.SHADOW_CASTING_SETTING_OFF
	root.add_child(tip)

	root.visible = false
	objects_layer.add_child(root)
	_guide_arrow = root

func _refresh_guide() -> void:
	var targets: Array[Vector2i] = []
	if _objective_complete():
		targets.append(exit_cell)
	else:
		targets = _goal_fruit_cells()
	if targets.is_empty() or segment_cells.is_empty():
		_guide_target = Vector2i(-1, -1)
		return
	var head := segment_cells[0]
	var dist := _bfs_distances(head)
	var best := targets[0]
	var best_score := INF
	for cell in targets:
		var straight := float(absi(cell.x - head.x) + absi(cell.y - head.y))
		var score := float(dist.get(cell, 1000 + straight))
		if score < best_score:
			best_score = score
			best = cell
	_guide_target = best
	if _guide_mat:
		_guide_mat.albedo_color = GUIDE_EXIT_COLOR if _objective_complete() else GUIDE_FRUIT_COLOR

func _update_guide_arrow(delta: float) -> void:
	_guide_time += delta
	if _guide_arrow == null or not is_instance_valid(_guide_arrow):
		return
	if segment_nodes.is_empty() or _guide_target.x < 0 or _game_over_pending or win_panel.visible:
		_guide_arrow.visible = false
		return
	var head_pos := segment_nodes[0].position
	var to_target := _pos(_guide_target) - head_pos
	to_target.y = 0.0
	if to_target.length() < 0.75:
		_guide_arrow.visible = false
		return
	var dir := to_target.normalized()
	var bob := sin(_guide_time * 4.0) * 0.06
	_guide_arrow.visible = true
	_guide_arrow.position = head_pos + dir * 0.95 + Vector3(0.0, 0.75 + bob, 0.0)
	_guide_arrow.rotation = Vector3(0.0, atan2(-dir.x, -dir.z), 0.0)
	var pulse := 1.0 + sin(_guide_time * 5.0) * 0.1
	_guide_arrow.scale = Vector3.ONE * pulse

# ── Intro card ──

func _show_intro() -> void:
	if _intro_panel == null:
		return
	_intro_active = true
	_intro_title.text = "Level %d" % (current_level + 1)
	_intro_goal.text = _intro_goal_text()
	var tips: Array = LEVEL_TIPS[mini(current_level, LEVEL_TIPS.size() - 1)]
	var lines := PackedStringArray()
	for tip in tips:
		lines.append("- " + String(tip))
	_intro_tips.text = "\n".join(lines)
	_intro_panel.visible = true

func _dismiss_intro() -> void:
	if not _intro_active:
		return
	_intro_active = false
	if _intro_panel:
		_intro_panel.visible = false
	_show_toast(_objective_status_text().replace("GOAL: ", "") + "!", Color(1.0, 0.93, 0.55))

func _on_intro_gui_input(event: InputEvent) -> void:
	if (event is InputEventMouseButton and event.pressed) or (event is InputEventScreenTouch and event.pressed):
		_dismiss_intro()

# ── On-screen UI ──

func _style_label(label: Label, size: int, color: Color, outline: int = 6) -> void:
	label.add_theme_font_size_override("font_size", size)
	label.add_theme_color_override("font_color", color)
	label.add_theme_color_override("font_outline_color", Color(0.08, 0.12, 0.04))
	label.add_theme_constant_override("outline_size", outline)

func _panel_style(bg: Color, border: Color, radius: int = 22) -> StyleBoxFlat:
	var sb := StyleBoxFlat.new()
	sb.bg_color = bg
	sb.border_color = border
	sb.set_border_width_all(4)
	sb.set_corner_radius_all(radius)
	sb.content_margin_left = 22
	sb.content_margin_right = 22
	sb.content_margin_top = 12
	sb.content_margin_bottom = 12
	sb.shadow_color = Color(0, 0, 0, 0.35)
	sb.shadow_size = 6
	return sb

func _polygon_texture(key: String, points: PackedVector2Array, size: int, color: Color) -> Texture2D:
	if _texture_cache.has(key):
		return _texture_cache[key]
	var img := Image.create(size, size, false, Image.FORMAT_RGBA8)
	img.fill(Color(0, 0, 0, 0))
	for y in size:
		for x in size:
			var cover := 0
			for sy in 2:
				for sx in 2:
					if Geometry2D.is_point_in_polygon(Vector2(x + 0.25 + sx * 0.5, y + 0.25 + sy * 0.5), points):
						cover += 1
			if cover > 0:
				img.set_pixel(x, y, Color(color.r, color.g, color.b, color.a * float(cover) / 4.0))
	var tex := ImageTexture.create_from_image(img)
	_texture_cache[key] = tex
	return tex

func _arrow_texture(dir: Vector2i) -> Texture2D:
	var s := 72.0
	var up := PackedVector2Array([
		Vector2(0.5, 0.1), Vector2(0.9, 0.52), Vector2(0.65, 0.52), Vector2(0.65, 0.9),
		Vector2(0.35, 0.9), Vector2(0.35, 0.52), Vector2(0.1, 0.52)])
	var angle := Vector2(dir).angle() - Vector2(Vector2i.UP).angle()
	var pts := PackedVector2Array()
	for p in up:
		pts.append(((p - Vector2(0.5, 0.5)).rotated(angle) + Vector2(0.5, 0.5)) * s)
	return _polygon_texture("arrow_%d_%d" % [dir.x, dir.y], pts, int(s), Color(0.32, 0.22, 0.12))

func _star_texture(filled: bool) -> Texture2D:
	var s := 96.0
	var pts := PackedVector2Array()
	for i in 10:
		var r := 0.48 if i % 2 == 0 else 0.2
		var a := -PI * 0.5 + float(i) * PI / 5.0
		pts.append((Vector2(cos(a), sin(a)) * r + Vector2(0.5, 0.52)) * s)
	var color := Color(1.0, 0.8, 0.15) if filled else Color(0.45, 0.42, 0.38, 0.85)
	return _polygon_texture("star_full" if filled else "star_empty", pts, int(s), color)

func _make_control_button(text: String, icon: Texture2D, size: Vector2, bg: Color) -> Button:
	var b := Button.new()
	b.text = text
	b.icon = icon
	b.expand_icon = icon != null
	b.icon_alignment = HORIZONTAL_ALIGNMENT_CENTER
	b.custom_minimum_size = size
	b.size = size
	b.focus_mode = Control.FOCUS_NONE
	b.add_theme_font_size_override("font_size", 40)
	b.add_theme_color_override("font_color", Color(0.3, 0.12, 0.05))
	b.add_theme_color_override("font_pressed_color", Color(0.3, 0.12, 0.05))
	b.add_theme_color_override("font_hover_color", Color(0.3, 0.12, 0.05))
	var normal := _panel_style(bg, bg.darkened(0.35), 28)
	normal.content_margin_left = 18
	normal.content_margin_right = 18
	normal.content_margin_top = 18
	normal.content_margin_bottom = 18
	var pressed := normal.duplicate() as StyleBoxFlat
	pressed.bg_color = bg.darkened(0.2)
	pressed.shadow_size = 2
	b.add_theme_stylebox_override("normal", normal)
	b.add_theme_stylebox_override("hover", normal)
	b.add_theme_stylebox_override("pressed", pressed)
	b.add_theme_stylebox_override("focus", StyleBoxEmpty.new())
	return b

func _on_control_down(action: String) -> void:
	Input.action_press(action)
	move_timer = 0.0
	_try_move(CONTROL_ACTIONS[action])

func _on_control_up(action: String) -> void:
	Input.action_release(action)

func _on_bite_pressed() -> void:
	if _intro_active:
		_dismiss_intro()
	_start_bite()

func _build_game_ui() -> void:
	var hud := $CanvasLayer/HUD as Control
	_style_label(hud_label, 30, Color(1, 1, 1), 6)

	var goal_panel := PanelContainer.new()
	goal_panel.add_theme_stylebox_override("panel", _panel_style(Color(0.12, 0.26, 0.08, 0.86), Color(0.95, 0.8, 0.3)))
	goal_panel.set_anchors_and_offsets_preset(Control.PRESET_TOP_WIDE)
	goal_panel.offset_left = 20
	goal_panel.offset_right = -20
	goal_panel.offset_top = 96
	goal_panel.offset_bottom = 210
	goal_panel.mouse_filter = Control.MOUSE_FILTER_IGNORE
	var goal_box := VBoxContainer.new()
	goal_box.add_theme_constant_override("separation", 2)
	goal_panel.add_child(goal_box)
	_goal_label = Label.new()
	_goal_label.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	_goal_label.autowrap_mode = TextServer.AUTOWRAP_WORD_SMART
	_style_label(_goal_label, 38, Color(1.0, 0.93, 0.55), 7)
	goal_box.add_child(_goal_label)
	_status_label = Label.new()
	_status_label.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	_style_label(_status_label, 24, Color(0.88, 0.95, 0.85), 4)
	goal_box.add_child(_status_label)
	hud.add_child(goal_panel)

	_toast_label = Label.new()
	_toast_label.set_anchors_and_offsets_preset(Control.PRESET_TOP_WIDE)
	_toast_label.offset_top = 240
	_toast_label.offset_bottom = 340
	_toast_label.offset_left = 40
	_toast_label.offset_right = -40
	_toast_label.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	_toast_label.autowrap_mode = TextServer.AUTOWRAP_WORD_SMART
	_toast_label.mouse_filter = Control.MOUSE_FILTER_IGNORE
	_style_label(_toast_label, 38, Color.WHITE, 10)
	_toast_label.modulate.a = 0.0
	hud.add_child(_toast_label)

	# Arrow pad (bottom-left) and BITE button (bottom-right).
	var pad := Control.new()
	pad.set_anchors_and_offsets_preset(Control.PRESET_BOTTOM_LEFT)
	pad.offset_left = 36
	pad.offset_top = -316
	pad.offset_right = 36 + 396
	pad.offset_bottom = -36
	pad.mouse_filter = Control.MOUSE_FILTER_IGNORE
	hud.add_child(pad)
	var stone := Color(0.86, 0.8, 0.66)
	var layout := {
		"move_up": Vector2(136, 0),
		"move_left": Vector2(0, 144),
		"move_down": Vector2(136, 144),
		"move_right": Vector2(272, 144),
	}
	for action in layout.keys():
		var btn := _make_control_button("", _arrow_texture(CONTROL_ACTIONS[action]), Vector2(124, 124), stone)
		btn.position = layout[action]
		btn.button_down.connect(_on_control_down.bind(action))
		btn.button_up.connect(_on_control_up.bind(action))
		pad.add_child(btn)

	var bite := _make_control_button("BITE", null, Vector2(240, 200), Color(1.0, 0.62, 0.25))
	bite.set_anchors_and_offsets_preset(Control.PRESET_BOTTOM_RIGHT)
	bite.offset_left = -276
	bite.offset_top = -256
	bite.offset_right = -36
	bite.offset_bottom = -56
	bite.add_theme_font_size_override("font_size", 52)
	bite.button_down.connect(_on_bite_pressed)
	hud.add_child(bite)

	_build_intro_panel()
	_build_win_extras()

func _build_intro_panel() -> void:
	var overlay := ColorRect.new()
	overlay.color = Color(0.0, 0.0, 0.0, 0.55)
	overlay.set_anchors_and_offsets_preset(Control.PRESET_FULL_RECT)
	overlay.mouse_filter = Control.MOUSE_FILTER_STOP
	overlay.gui_input.connect(_on_intro_gui_input)
	overlay.visible = false

	var card := PanelContainer.new()
	card.add_theme_stylebox_override("panel", _panel_style(Color(0.98, 0.95, 0.84), Color(0.35, 0.62, 0.18), 30))
	card.set_anchors_and_offsets_preset(Control.PRESET_CENTER)
	card.offset_left = -440
	card.offset_right = 440
	card.offset_top = -420
	card.offset_bottom = 420
	card.mouse_filter = Control.MOUSE_FILTER_IGNORE
	overlay.add_child(card)

	var box := VBoxContainer.new()
	box.add_theme_constant_override("separation", 26)
	box.alignment = BoxContainer.ALIGNMENT_CENTER
	card.add_child(box)

	_intro_title = Label.new()
	_intro_title.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	_style_label(_intro_title, 72, Color(0.98, 0.78, 0.15), 10)
	box.add_child(_intro_title)

	_intro_goal = Label.new()
	_intro_goal.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	_intro_goal.autowrap_mode = TextServer.AUTOWRAP_WORD_SMART
	_style_label(_intro_goal, 36, Color(0.18, 0.32, 0.08), 0)
	box.add_child(_intro_goal)

	_intro_tips = Label.new()
	_intro_tips.autowrap_mode = TextServer.AUTOWRAP_WORD_SMART
	_style_label(_intro_tips, 30, Color(0.32, 0.24, 0.14), 0)
	box.add_child(_intro_tips)

	var start := Label.new()
	start.text = "Tap anywhere to start"
	start.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	_style_label(start, 34, Color(0.95, 0.5, 0.15), 0)
	box.add_child(start)

	$CanvasLayer.add_child(overlay)
	_intro_panel = overlay

func _build_win_extras() -> void:
	var vbox := $CanvasLayer/WinPanel/VBox as VBoxContainer
	vbox.offset_left = -360
	vbox.offset_right = 360
	vbox.offset_top = -330
	vbox.offset_bottom = 330
	_star_full_tex = _star_texture(true)
	_star_empty_tex = _star_texture(false)
	_win_stars = HBoxContainer.new()
	_win_stars.alignment = BoxContainer.ALIGNMENT_CENTER
	_win_stars.add_theme_constant_override("separation", 18)
	for i in 3:
		var star := TextureRect.new()
		star.custom_minimum_size = Vector2(120, 120)
		star.expand_mode = TextureRect.EXPAND_IGNORE_SIZE
		star.stretch_mode = TextureRect.STRETCH_KEEP_ASPECT_CENTERED
		star.texture = _star_empty_tex
		_win_stars.add_child(star)
	vbox.add_child(_win_stars)
	_win_stats = Label.new()
	_win_stats.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	_win_stats.autowrap_mode = TextServer.AUTOWRAP_WORD_SMART
	_style_label(_win_stats, 30, Color.WHITE, 5)
	vbox.add_child(_win_stats)
	var next_button := vbox.get_node("NextButton")
	vbox.move_child(next_button, vbox.get_child_count() - 1)

# ── Bush formations and spinning rings ──

func _level_option(key: String, default_value: bool = true) -> bool:
	var opts: Dictionary = LEVEL_OPTIONS.get(current_level, {})
	return bool(opts.get(key, default_value))

func _is_formation_protected(cell: Vector2i) -> bool:
	if cell == player_cell or leaves.has(cell) or hazards.has(cell):
		return true
	if _is_near_player_start(cell, 1):
		return true
	return _is_near_exit(cell, EXIT_CLEAR_RADIUS + 2)

func _stamp_level_formations(walkable_cells: Array[Vector2i]) -> void:
	for spec in LEVEL_FORMATIONS.get(current_level, []):
		var carve := bool(spec.get("carve", false))
		var wall_type := String(spec.get("wall", "bush"))
		for cell in BushShapesScript.build(spec):
			if cell.x <= 0 or cell.y <= 0 or cell.x >= _maze_w - 1 or cell.y >= _maze_h - 1:
				continue
			if carve:
				_force_cell_walkable(cell)
				if not walkable_cells.has(cell):
					walkable_cells.append(cell)
				continue
			if wall_set.has(cell) or _is_formation_protected(cell):
				continue
			wall_set[cell] = true
			_wall_cells.append(cell)
			walkable_cells.erase(cell)
			_forced_wall_types[cell] = wall_type

func _build_spinners(walkable_cells: Array[Vector2i]) -> void:
	# Moving blocks get their own colour so they stand out from the fixed bushes.
	var ring_mat := ShaderMaterial.new()
	ring_mat.shader = _wall_mat.shader
	ring_mat.set_shader_parameter("half_height", WALL_HEIGHT * 0.5)
	ring_mat.set_shader_parameter("color_top", Vector3(RING_TOP.r, RING_TOP.g, RING_TOP.b))
	ring_mat.set_shader_parameter("color_side", Vector3(RING_SIDE.r, RING_SIDE.g, RING_SIDE.b))
	for group in LEVEL_SPINNERS.get(current_level, []):
		var center: Vector2i = group.get("at", Vector2i.ZERO)
		for ring_spec in group.get("rings", []):
			var ring := Node3D.new()
			ring.set_script(SpinRing3DScript)
			ring.setup(center, ring_spec, CELL)
			maze_layer.add_child(ring)
			ring.build_visual(_wall_mesh, ring_mat, WALL_HEIGHT)
			_spin_rings.append(ring)
			for cell in ring.cells:
				_force_cell_walkable(cell)
				walkable_cells.erase(cell)
				_spin_cell_owner[cell] = ring

func _is_spin_blocked(cell: Vector2i) -> bool:
	var ring := _spin_cell_owner.get(cell) as Node3D
	return ring != null and ring.is_blocked(cell)

func _on_blocked_by_spinner() -> void:
	if _spin_hint_cooldown > 0.0:
		return
	_spin_hint_cooldown = SPIN_HINT_COOLDOWN
	_show_toast("Wait for a gap in the ring - or BITE it to hold it still.", Color(0.7, 1.0, 0.6), 3.0)

func _process_spinners(delta: float) -> void:
	if _spin_rings.is_empty():
		return
	_spin_hint_cooldown = maxf(_spin_hint_cooldown - delta, 0.0)
	var active := _is_play_active()
	for ring in _spin_rings:
		ring.animate(delta)
		if ring.hold_timer > 0.0:
			ring.hold_timer = maxf(ring.hold_timer - delta, 0.0)
			continue
		ring.step_timer += delta
		if ring.step_timer < ring.step_time:
			continue
		if active:
			_before_ring_step(ring)
		ring.step_timer = 0.0
		ring.step()
		if active and _snd_tick and _is_near_ring(ring):
			_snd_tick.play()
	_update_ring_riding()
	_update_ring_alignment(active)

func _is_near_ring(ring: Node3D) -> bool:
	if segment_cells.is_empty():
		return false
	var d: Vector2i = segment_cells[0] - ring.center_cell
	return absi(maxi(absi(d.x), absi(d.y)) - ring.size) <= 1

# A gap lines up when a gap in one ring sits straight across the 1-cell track
# from a gap in the next ring out, so the caterpillar can crawl right through.
func _update_ring_alignment(active: bool) -> void:
	var per_ring: Dictionary = {}
	var pairs: Dictionary = {}
	var chime := false
	for inner in _spin_rings:
		per_ring[inner] = per_ring.get(inner, [] as Array[Vector2i])
		for outer in _spin_rings:
			if outer.center_cell != inner.center_cell or outer.size != inner.size + 2:
				continue
			per_ring[outer] = per_ring.get(outer, [] as Array[Vector2i])
			for cell in inner.cells:
				var out := _ring_outward(cell, inner)
				if out == Vector2i.ZERO or inner.is_blocked(cell):
					continue
				var across: Vector2i = cell + out * 2
				if not outer.owns(across) or outer.is_blocked(across):
					continue
				per_ring[inner].append(cell)
				per_ring[inner].append(cell + out)
				per_ring[outer].append(across)
				var key := "%s|%s" % [cell, across]
				pairs[key] = true
				if not _aligned_pairs.has(key) and (_is_near_ring(inner) or _is_near_ring(outer)):
					chime = true
	for ring in _spin_rings:
		ring.set_aligned_cells(per_ring.get(ring, [] as Array[Vector2i]))
	_aligned_pairs = pairs
	if chime and active and _snd_chime:
		_snd_chime.play()

# Outward step from a side cell of a ring; corners have none.
func _ring_outward(cell: Vector2i, ring: Node3D) -> Vector2i:
	var d: Vector2i = cell - ring.center_cell
	if absi(d.x) == ring.size and absi(d.y) < ring.size:
		return Vector2i(signi(d.x), 0)
	if absi(d.y) == ring.size and absi(d.x) < ring.size:
		return Vector2i(0, signi(d.y))
	return Vector2i.ZERO

# Rings never stop. If the gap under the head is about to move on, the head is
# carried one cell along with it. Otherwise blocks just slide under the
# caterpillar (they are hidden there), so it can never be trapped.
func _before_ring_step(ring: Node3D) -> void:
	if segment_cells.is_empty():
		return
	var head := segment_cells[0]
	if ring.owns(head) and not ring.is_blocked(head) and ring.is_blocked(head, ring.next_offset()):
		_ring_carry(ring)

func _ring_carry(ring: Node3D) -> bool:
	if _is_biting or _game_over_pending or _move_anim_remaining > 0.0:
		return false
	var head := segment_cells[0]
	var target: Vector2i = ring.next_cell(head)
	if not _carry_step_ok(target, ring):
		return false
	if _carry_ring != ring:
		_show_toast("Wheee! The ring is carrying you!", Color(0.7, 1.0, 0.6), 2.0)
	_carry_ring = ring
	_is_reversing = false
	facing = target - head
	_move_to(target)
	return true

func _carry_step_ok(cell: Vector2i, ring: Node3D) -> bool:
	if not _is_inside_maze(cell) or wall_set.has(cell) or cell == exit_cell:
		return false
	if hazards.has(cell) or _wormholes.has(cell):
		return false
	if segment_cells.has(cell) and cell != segment_cells[-1]:
		return false
	var owner := _spin_cell_owner.get(cell) as Node3D
	if owner and owner != ring and owner.is_blocked(cell):
		return false
	return true

func _update_ring_riding() -> void:
	if _carry_ring != null and (segment_cells.is_empty() or not _carry_ring.owns(segment_cells[0])):
		_carry_ring = null
	for ring in _spin_rings:
		var covered: Array[Vector2i] = []
		for cell in segment_cells:
			if ring.owns(cell) and ring.is_blocked(cell):
				covered.append(cell)
		ring.set_hidden_cells(covered)

func _start_ring_bite(ring: Node3D, cell: Vector2i) -> void:
	_bite_target = cell
	_is_biting = true
	_bite_timer = _bite_duration_for_length()
	_bite_face_loop_timer = BITE_FACE_LOOP_INTERVAL
	_bite_face_is_biting = true
	is_busy = true
	ring.hold_timer = maxf(ring.hold_timer, _bite_timer)
	if ring.add_bite(cell):
		if _snd_eat:
			_snd_eat.play()
		_show_toast("You chewed a new gap in the ring!", Color(0.7, 1.0, 0.6))
	if _snd_bite:
		_snd_bite.pitch_scale = clampf(BITE_DURATION / maxf(_bite_timer, 0.01), 1.0, 2.2)
		_snd_bite.play()
	if segment_nodes.size() > 0 and segment_nodes[0].has_method("set_expression"):
		segment_nodes[0].set_expression("biting", BITE_FACE_LOOP_INTERVAL)
