extends Node3D
## 3D Caterpillar segment – cute cartoon style inspired by reference art.
## Plump overlapping body, big expressive eyes, antennae, rosy cheeks, tiny feet.

const MouthComponent3DScript: GDScript = preload("res://scripts/mouth_component_3d.gd")

const CELL := 1.0

var _mesh: MeshInstance3D
var _mat: Material
var _foot_left: MeshInstance3D
var _foot_right: MeshInstance3D
var _leg_phase := 0.0
var _base_mesh_y := 0.30
var _crawl_blend := 0.0
var _crawl_phase := 0.0
var _crawl_speed := 0.0

# ── Blink ──
var _eye_nodes: Array[MeshInstance3D] = []
var _blink_timer := 0.0
var _blink_interval := 3.0  # seconds between blinks
var _blink_phase := 0.0  # 0 = open, >0 = blinking
var _is_blinking := false

# ── Face expression ──
var _mouth_node: Node3D
var _mouth_component: Node3D
var _cheek_nodes: Array[MeshInstance3D] = []
var _eyebrow_nodes: Array[MeshInstance3D] = []
var _face_time := 0.0
var _expression := "happy"  # happy, idle, looking, sleeping
var _expression_timer := 0.0
var _mouth_base_scale := Vector3(1.3, 0.6, 0.5)
var _mouth_base_pos := Vector3.ZERO

# ── Idle behavior ──
var _is_idle := false
var _idle_time := 0.0
var _idle_cycle_timer := 0.0
var _idle_phase := 0  # 0=wait, 1=looking, 2=wait, 3=sleeping
var _zzz_nodes: Array[Node3D] = []
const IDLE_LOOK_START := 2.0   # seconds before first look
const IDLE_LOOK_DURATION := 2.5
const IDLE_PAUSE := 1.5
const IDLE_SLEEP_START := 10.0  # seconds of total idle before sleeping

# ── Build ──

func _ready() -> void:
	var seg_type: String = get_meta("seg_type", "body")
	var seg_index: int = get_meta("seg_index", 1)

	# Main body sphere – plump, slightly squashed vertically
	_mesh = MeshInstance3D.new()

	var radius: float
	match seg_type:
		"head":
			radius = 0.34
			_mat = _make_body_gradient_material(0, false)
			_mat.set_shader_parameter("show_stripes", false)
			_mat.set_shader_parameter("pear_shape", 1.0)
			_mat.set_shader_parameter("segment_radius", 0.34)
			# Override head colors to be slightly brighter
			_mat.set_shader_parameter("mid_color", Color(0.68, 0.90, 0.18))
			_mat.set_shader_parameter("specular_amt", 0.55)
			_mat.set_shader_parameter("roughness_amt", 0.35)
		"tail":
			radius = 0.22
			_mat = _make_body_gradient_material(seg_index, true)
		_:
			radius = 0.28
			_mat = _make_body_gradient_material(seg_index)

	var sphere := SphereMesh.new()
	sphere.radius = radius
	# Head is taller (egg-shaped) for pear deformation; body/tail squashed
	if seg_type == "head":
		sphere.height = radius * 2.1
	else:
		sphere.height = radius * 1.75
	sphere.radial_segments = 32
	sphere.rings = 16
	_mesh.mesh = sphere
	_mesh.material_override = _mat
	var head_lift := radius * 0.16 if seg_type == "head" else 0.0
	_mesh.position.y = radius * 0.85 + head_lift
	_base_mesh_y = radius * 0.85 + head_lift
	_mesh.cast_shadow = GeometryInstance3D.SHADOW_CASTING_SETTING_ON
	add_child(_mesh)

	# Darker underbelly stripe (head only – body/tail use gradient shader)
	if seg_type == "head":
		_add_belly_stripe(radius, seg_type)

	# Glossy top highlight — wet/shiny look on top of every segment
	_add_top_shine(radius, seg_type)

	if seg_type == "head":
		_add_neck_connector(radius)

	# (separator rings removed for cleaner look)

	match seg_type:
		"head":
			# Face pivot – tilted upward so features face the overhead camera
			var face_pivot := Node3D.new()
			face_pivot.position = Vector3(0.0, radius * 0.04, -radius * 0.02)
			face_pivot.rotation.x = deg_to_rad(55)  # Positive = tilts front-face features upward
			_mesh.add_child(face_pivot)
			_add_eyes(radius, face_pivot)
			_add_eyebrows(radius, face_pivot)
			_add_cheeks(radius, face_pivot)
			_add_mouth(radius, face_pivot)
			_add_antennae(radius)
			_add_feet(radius, true)
		"tail":
			_add_tail_tip(radius)
			_add_feet(radius, true)
		_:
			_add_feet(radius, false)

# ── Body details ──

func _make_body_gradient_material(seg_index: int, is_tail := false) -> ShaderMaterial:
	# Rich textured skin: multi-scale spots, bumpy surface, wet glossy look
	var shader := Shader.new()
	shader.code = """
shader_type spatial;
render_mode blend_mix, depth_draw_opaque, cull_back, diffuse_burley, specular_schlick_ggx;

uniform vec3 top_color        : source_color = vec3(0.20, 0.42, 0.08);
uniform vec3 mid_color        : source_color = vec3(0.66, 0.88, 0.14);
uniform vec3 bottom_color     : source_color = vec3(0.24, 0.52, 0.11);
uniform vec3 belly_glow_color : source_color = vec3(0.44, 0.58, 0.12);
uniform vec3 spot_color_light : source_color = vec3(0.82, 0.96, 0.35);
uniform vec3 spot_color_bright: source_color = vec3(0.92, 1.00, 0.55);
uniform float mid_pos         = 0.52;
uniform float specular_amt    = 0.65;
uniform float roughness_amt   = 0.30;
uniform float rim_amt         = 0.38;
uniform float seed            = 0.0;
uniform bool show_stripes      = true;
uniform float segment_radius   = 0.28;
uniform float pear_shape       = 0.0;

varying vec3 v_local_pos;
varying vec3 v_local_normal;

void vertex() {
	// Pear deformation: big round forehead, narrow tapered chin
	if (pear_shape > 0.0) {
		float h = VERTEX.y;
		// Normalize height: 0 at very bottom, 1 at very top of sphere
		float sphere_h = segment_radius * 1.75 * 0.5; // half-height of sphere
		float hn = clamp((h / sphere_h) * 0.5 + 0.5, 0.0, 1.0);
		// Strong pear curve: wide forehead, narrow chin
		float top_scale = 1.30;
		float mid_scale = 1.10;
		float bot_scale = 0.55;
		float s;
		if (hn > 0.5) {
			s = mix(mid_scale, top_scale, smoothstep(0.5, 1.0, hn));
		} else {
			s = mix(bot_scale, mid_scale, smoothstep(0.0, 0.5, hn));
		}
		s = mix(1.0, s, pear_shape);
		VERTEX.x *= s;
		VERTEX.z *= s;
		NORMAL.x *= 1.0 / s;
		NORMAL.z *= 1.0 / s;
		NORMAL = normalize(NORMAL);
	}
	v_local_pos = VERTEX;
	v_local_normal = NORMAL;
}

float hash3(vec3 p) {
	return fract(sin(dot(p, vec3(127.1, 311.7, 74.7))) * 43758.5453);
}

float hash2(vec2 p) {
	return fract(sin(dot(p, vec2(127.1, 311.7))) * 43758.5453);
}

// Voronoi-based circular spots — returns (dist_to_nearest_center, random_id)
vec2 voronoi(vec2 p, float scale) {
	vec2 sp = p * scale;
	vec2 cell = floor(sp);
	vec2 local = fract(sp);
	float min_dist = 10.0;
	float cell_id = 0.0;
	for (int y = -1; y <= 1; y++) {
		for (int x = -1; x <= 1; x++) {
			vec2 neighbor = vec2(float(x), float(y));
			vec2 nc = cell + neighbor;
			vec2 point = neighbor + vec2(hash2(nc), hash2(nc + 99.0)) * 0.8 + 0.1;
			float d = length(local - point);
			if (d < min_dist) {
				min_dist = d;
				cell_id = hash2(nc + 37.0);
			}
		}
	}
	return vec2(min_dist, cell_id);
}

void fragment() {
	float t = clamp(v_local_pos.y * 1.55 + 0.52, 0.0, 1.0);

	// Base gradient: bottom -> mid -> top
	vec3 col;
	if (t < mid_pos) {
		float k = t / mid_pos;
		col = mix(bottom_color, mid_color, smoothstep(0.0, 1.0, k));
	} else {
		float k = (t - mid_pos) / (1.0 - mid_pos);
		col = mix(mid_color, top_color, smoothstep(0.0, 1.0, k));
	}

	// Bright center mass
	float radial = clamp(length(v_local_pos.xz) * 1.25, 0.0, 1.0);
	float center_light = 1.0 - smoothstep(0.10, 0.95, radial);
	col = mix(col, mid_color * 1.12, center_light * 0.22);

	// Belly band
	float belly_mask = smoothstep(0.06, -0.24, v_local_pos.y);
	belly_mask *= 1.0 - smoothstep(0.08, 0.58, length(v_local_pos.xz) * 1.7);
	col = mix(col, belly_glow_color, belly_mask * 0.14);

	// --- Multi-scale voronoi spots (like dewdrops / skin bumps) ---
	vec2 surf_uv = v_local_pos.xz + vec2(seed * 0.013, seed * 0.009);

	// Large spots (like the big bright circles in the reference)
	vec2 v_large = voronoi(surf_uv, 8.0);
	float large_spot = (1.0 - smoothstep(0.08, 0.22, v_large.x)) * step(0.45, v_large.y);
	// Medium spots
	vec2 v_med = voronoi(surf_uv + vec2(seed * 0.007), 15.0);
	float med_spot = (1.0 - smoothstep(0.06, 0.18, v_med.x)) * step(0.40, v_med.y);
	// Small spots (tiny freckles)
	vec2 v_small = voronoi(surf_uv + vec2(seed * 0.019), 28.0);
	float small_spot = (1.0 - smoothstep(0.04, 0.12, v_small.x)) * step(0.50, v_small.y);

	// Combine spots with varying brightness
	float spot_total = large_spot * 0.7 + med_spot * 0.45 + small_spot * 0.25;
	// Spots are brighter on top, subtler on bottom
	spot_total *= smoothstep(0.05, 0.70, t);
	// Mix bright yellow-green spots
	vec3 spot_col = mix(spot_color_light, spot_color_bright, large_spot);
	col = mix(col, spot_col, clamp(spot_total, 0.0, 0.65));

	// --- Subtle surface bump / noise for organic texture ---
	float noise_fine = hash3(v_local_pos * 45.0 + vec3(seed));
	float noise_coarse = hash3(v_local_pos * 12.0 + vec3(seed * 0.5));
	col *= 0.95 + noise_fine * 0.08 + noise_coarse * 0.04;

	// --- Black stripes with yellow spots (swallowtail pattern) ---
	if (show_stripes) {
		// Position-based mapping for clean perpendicular rings
		float z_n = v_local_pos.z / segment_radius;
		float ang = atan(v_local_pos.x, v_local_pos.y);

		// Wide band region — yellow spots will fill most of it
		float wobble = (hash2(vec2(ang * 2.0 + seed, z_n * 3.0)) - 0.5) * 0.04
		            + (hash2(vec2(ang * 5.0 + seed * 1.3, z_n * 7.0)) - 0.5) * 0.025;
		float half_width = 0.28 + wobble;
		float band_mask = 1.0 - smoothstep(half_width - 0.06, half_width + 0.04, abs(z_n));

		// Soften on belly side
		float belly_fade = smoothstep(-0.15, 0.10, v_local_pos.y);
		band_mask *= mix(0.15, 1.0, belly_fade);

		// Shadow at edges of band
		float shadow_zone = 1.0 - smoothstep(half_width - 0.10, half_width + 0.06, abs(z_n));
		float shadow_only = max(shadow_zone - band_mask, 0.0);
		col = mix(col, col * 0.65, shadow_only * 0.4);

		// Yellow spots: huge round blobs filling most of the band
		float n_spots = 7.0;
		float spot_ang = mod(ang + PI + seed * 0.1, TAU);
		float spot_cell = spot_ang / TAU * n_spots;
		float spot_frac = fract(spot_cell);
		float spot_cell_id = floor(spot_cell);
		// Use raw world-space coords scaled to make spots huge
		float circ_span = TAU / n_spots * segment_radius; // world-space width per cell
		float dx_spot = (spot_frac - 0.5) * circ_span;
		float dy_spot = v_local_pos.z; // raw z position in world units
		// Per-spot random properties
		float rnd = hash2(vec2(spot_cell_id, seed));
		float rnd2 = hash2(vec2(spot_cell_id + 7.0, seed + 3.0));
		float rnd3 = hash2(vec2(spot_cell_id + 13.0, seed + 5.0));
		dx_spot += (rnd - 0.5) * 0.02;
		dy_spot += (rnd3 - 0.5) * 0.02;
		// Huge radius in world units
		float spot_r = 0.06 + rnd2 * 0.03; // 0.06 to 0.09 (body radius is 0.28)
		// Gentle wobble for organic feel
		float edge_ang = atan(dx_spot, dy_spot);
		float wobble_spot = 1.0 + (hash2(vec2(edge_ang * 3.0 + spot_cell_id, seed)) - 0.5) * 0.12;
		float spot_dist = length(vec2(dx_spot, dy_spot)) / wobble_spot;
		float yellow_mask = 1.0 - smoothstep(spot_r * 0.3, spot_r, spot_dist);
		yellow_mask *= band_mask;

		// Dark stripe color blends with green
		vec3 stripe_dark = mix(col * 0.15, vec3(0.04, 0.08, 0.02), 0.7);
		vec3 yellow_spot = vec3(0.95, 0.85, 0.12);

		// First paint the whole band dark, then paint yellow spots on top
		col = mix(col, stripe_dark, band_mask * 0.80);
		col = mix(col, yellow_spot, yellow_mask * 0.92);
	}

	// --- Wet/dewy highlights on spot centers ---
	float wet_highlight = large_spot * 0.35 + med_spot * 0.15;
	float wet_spec_boost = wet_highlight * 0.3;

	ALBEDO = col;
	SPECULAR = specular_amt + wet_spec_boost;
	ROUGHNESS = roughness_amt - wet_highlight * 0.12;
	RIM = rim_amt;
	RIM_TINT = 0.22;

	// Subtle normal perturbation for bumpy skin feel
	float bump_str = 0.04;
	float bx = hash3(v_local_pos * 30.0 + vec3(0.1, 0.0, 0.0) + vec3(seed)) - 0.5;
	float by = hash3(v_local_pos * 30.0 + vec3(0.0, 0.1, 0.0) + vec3(seed)) - 0.5;
	NORMAL = normalize(NORMAL + vec3(bx, by, 0.0) * bump_str);
}
"""
	var mat := ShaderMaterial.new()
	mat.shader = shader
	# Per-segment slight variation
	var v := float(seg_index % 3)
	if is_tail:
		mat.set_shader_parameter("top_color", Color(0.19, 0.43, 0.08))
		mat.set_shader_parameter("mid_color", Color(0.66, 0.86, 0.16))
		mat.set_shader_parameter("bottom_color", Color(0.25, 0.50, 0.11))
	else:
		mat.set_shader_parameter("top_color", Color(0.18 + v * 0.015, 0.41 + v * 0.02, 0.07 + v * 0.01))
		mat.set_shader_parameter("mid_color", Color(0.64 + v * 0.02, 0.88, 0.14 + v * 0.015))
		mat.set_shader_parameter("bottom_color", Color(0.24, 0.52, 0.11))
	mat.set_shader_parameter("belly_glow_color", Color(0.44, 0.58, 0.12))
	mat.set_shader_parameter("spot_color_light", Color(0.82, 0.96, 0.35))
	mat.set_shader_parameter("spot_color_bright", Color(0.92, 1.00, 0.55))
	mat.set_shader_parameter("mid_pos", 0.52)
	mat.set_shader_parameter("seed", float(seg_index) * 17.0)
	if is_tail:
		mat.set_shader_parameter("segment_radius", 0.22)
	else:
		mat.set_shader_parameter("segment_radius", 0.28)
	return mat

func _add_belly_stripe(radius: float, seg_type: String) -> void:
	# A flattened ellipsoid underneath to simulate the lighter yellow-green belly
	var belly := MeshInstance3D.new()
	var belly_s := SphereMesh.new()
	belly_s.radius = radius * 0.7
	belly_s.height = radius * 0.5
	belly_s.radial_segments = 16
	belly_s.rings = 8
	belly.mesh = belly_s
	var belly_mat := StandardMaterial3D.new()
	match seg_type:
		"head":
			belly_mat.albedo_color = Color(0.75, 0.90, 0.40)
		"tail":
			belly_mat.albedo_color = Color(0.72, 0.88, 0.35)
		_:
			belly_mat.albedo_color = Color(0.58, 0.82, 0.30)
	belly_mat.specular = 0.2
	belly_mat.roughness = 0.7
	belly.material_override = belly_mat
	belly.position = Vector3(0.0, -radius * 0.35, 0.0)
	belly.cast_shadow = GeometryInstance3D.SHADOW_CASTING_SETTING_OFF
	_mesh.add_child(belly)

func _add_top_shine(radius: float, seg_type: String) -> void:
	# Glossy highlight ellipsoid on top of each segment for a wet, plump look
	var shine_mat := StandardMaterial3D.new()
	shine_mat.albedo_color = Color(1.0, 1.0, 0.95, 0.35)
	shine_mat.transparency = BaseMaterial3D.TRANSPARENCY_ALPHA
	shine_mat.specular = 0.9
	shine_mat.roughness = 0.15
	shine_mat.emission_enabled = true
	shine_mat.emission = Color(0.9, 1.0, 0.7)
	shine_mat.emission_energy_multiplier = 0.15

	var shine := MeshInstance3D.new()
	var shine_s := SphereMesh.new()
	shine_s.radius = radius * 0.55
	shine_s.height = radius * 0.30
	shine_s.radial_segments = 16
	shine_s.rings = 8
	shine.mesh = shine_s
	shine.material_override = shine_mat
	# Skewed forward and up for that glossy top-light look
	var z_off := -radius * 0.05 if seg_type == "head" else 0.0
	shine.position = Vector3(0.0, radius * 0.62, z_off)
	shine.cast_shadow = GeometryInstance3D.SHADOW_CASTING_SETTING_OFF
	_mesh.add_child(shine)

func _add_neck_connector(radius: float) -> void:
	# A short partial body piece behind the head so the head can sit slightly higher
	# without looking detached from the first segment.
	var neck_mat := StandardMaterial3D.new()
	neck_mat.albedo_color = Color(0.58, 0.80, 0.24)
	neck_mat.specular = 0.38
	neck_mat.roughness = 0.52
	neck_mat.rim_enabled = true
	neck_mat.rim = 0.28
	neck_mat.rim_tint = 0.15

	var neck := MeshInstance3D.new()
	var neck_mesh := SphereMesh.new()
	neck_mesh.radius = radius * 0.22
	neck_mesh.height = radius * 0.34
	neck_mesh.radial_segments = 20
	neck_mesh.rings = 10
	neck.mesh = neck_mesh
	neck.material_override = neck_mat
	neck.position = Vector3(0.0, -radius * 0.02, radius * 0.34)
	neck.scale = Vector3(1.10, 0.82, 1.65)
	neck.rotation.x = deg_to_rad(-10)
	neck.cast_shadow = GeometryInstance3D.SHADOW_CASTING_SETTING_OFF
	_mesh.add_child(neck)

	var neck_belly := MeshInstance3D.new()
	var neck_belly_mesh := SphereMesh.new()
	neck_belly_mesh.radius = radius * 0.16
	neck_belly_mesh.height = radius * 0.14
	neck_belly_mesh.radial_segments = 14
	neck_belly_mesh.rings = 8
	neck_belly.mesh = neck_belly_mesh
	var neck_belly_mat := StandardMaterial3D.new()
	neck_belly_mat.albedo_color = Color(0.78, 0.90, 0.42)
	neck_belly_mat.specular = 0.16
	neck_belly_mat.roughness = 0.78
	neck_belly.material_override = neck_belly_mat
	neck_belly.position = Vector3(0.0, -radius * 0.11, radius * 0.35)
	neck_belly.scale = Vector3(1.0, 0.72, 1.25)
	neck_belly.cast_shadow = GeometryInstance3D.SHADOW_CASTING_SETTING_OFF
	_mesh.add_child(neck_belly)

	# (neck ring removed for cleaner look)

func _add_segment_separator(radius: float) -> void:
	# Soft darker green crease where this segment meets the one in front
	var ring_mat := StandardMaterial3D.new()
	ring_mat.albedo_color = Color(0.32, 0.55, 0.16)  # darker green, not black
	ring_mat.specular = 0.2
	ring_mat.roughness = 0.8

	var ring := MeshInstance3D.new()
	var torus := TorusMesh.new()
	torus.inner_radius = radius * 0.92
	torus.outer_radius = radius * 1.0
	torus.ring_segments = 24
	torus.rings = 8
	ring.mesh = torus
	ring.material_override = ring_mat
	ring.position = Vector3(0.0, 0.0, -radius * 0.55)
	ring.rotation.x = deg_to_rad(90)
	ring.scale = Vector3(1.0, 0.25, 1.0)
	ring.cast_shadow = GeometryInstance3D.SHADOW_CASTING_SETTING_OFF
	_mesh.add_child(ring)

func _add_spots(radius: float) -> void:
	# Lighter dappled spots on the body for that cute textured look
	var spot_mat := StandardMaterial3D.new()
	spot_mat.albedo_color = Color(0.78, 0.95, 0.45, 0.85)
	spot_mat.transparency = BaseMaterial3D.TRANSPARENCY_ALPHA
	spot_mat.specular = 0.6
	spot_mat.roughness = 0.4

	var rng := RandomNumberGenerator.new()
	rng.seed = get_meta("seg_index", 0) * 137 + 42

	for i in range(5):
		var spot := MeshInstance3D.new()
		var spot_s := SphereMesh.new()
		var spot_r := rng.randf_range(0.05, 0.09)
		spot_s.radius = spot_r
		spot_s.height = spot_r * 0.5
		spot_s.radial_segments = 10
		spot_s.rings = 5
		spot.mesh = spot_s
		spot.material_override = spot_mat

		# Distribute spots on upper surface
		var angle := rng.randf_range(-1.4, 1.4)
		var height := rng.randf_range(radius * 0.1, radius * 0.7)
		spot.position = Vector3(
			sin(angle) * radius * 0.85,
			height,
			cos(angle) * radius * 0.85
		)
		spot.cast_shadow = GeometryInstance3D.SHADOW_CASTING_SETTING_OFF
		_mesh.add_child(spot)

# ── Head features ──

func _add_eyes(head_radius: float, parent: Node3D) -> void:
	# Large glossy almond-shaped eyes – golden-brown iris, wet/dewy look
	var eye_white_mat := StandardMaterial3D.new()
	eye_white_mat.albedo_color = Color(1.0, 1.0, 0.98)
	eye_white_mat.specular = 0.7
	eye_white_mat.roughness = 0.15
	eye_white_mat.rim_enabled = true
	eye_white_mat.rim = 0.2
	eye_white_mat.rim_tint = 0.1

	var iris_mat := StandardMaterial3D.new()
	iris_mat.albedo_color = Color(0.12, 0.08, 0.04)  # Dark brown, almost black
	iris_mat.specular = 0.8
	iris_mat.roughness = 0.12
	iris_mat.rim_enabled = true
	iris_mat.rim = 0.25
	iris_mat.rim_tint = 0.15

	var pupil_mat := StandardMaterial3D.new()
	pupil_mat.albedo_color = Color(0.02, 0.02, 0.02)
	pupil_mat.specular = 0.9
	pupil_mat.roughness = 0.05

	var highlight_mat := StandardMaterial3D.new()
	highlight_mat.albedo_color = Color(1.0, 1.0, 1.0)
	highlight_mat.emission_enabled = true
	highlight_mat.emission = Color(1.0, 1.0, 0.95)
	highlight_mat.emission_energy_multiplier = 0.5

	# Outer golden rim around each eye for that warm glow
	var rim_mat := StandardMaterial3D.new()
	rim_mat.albedo_color = Color(0.85, 0.65, 0.10, 0.7)
	rim_mat.transparency = BaseMaterial3D.TRANSPARENCY_ALPHA
	rim_mat.specular = 0.6
	rim_mat.roughness = 0.25

	for side in [-1.0, 1.0]:
		# White of the eye – almond shaped (squashed sphere)
		var eye := MeshInstance3D.new()
		var eye_s := SphereMesh.new()
		eye_s.radius = 0.10
		eye_s.height = 0.18
		eye_s.radial_segments = 24
		eye_s.rings = 12
		eye.mesh = eye_s
		eye.material_override = eye_white_mat
		eye.position = Vector3(side * 0.13, head_radius * 0.10, -head_radius * 0.78)
		# Slightly pointed/almond shape by scaling
		eye.scale = Vector3(0.85, 1.0, 0.9)
		eye.cast_shadow = GeometryInstance3D.SHADOW_CASTING_SETTING_OFF
		parent.add_child(eye)
		_eye_nodes.append(eye)

		# Golden outer rim glow
		var rim_mesh := MeshInstance3D.new()
		var rim_s := SphereMesh.new()
		rim_s.radius = 0.105
		rim_s.height = 0.19
		rim_s.radial_segments = 20
		rim_s.rings = 10
		rim_mesh.mesh = rim_s
		rim_mesh.material_override = rim_mat
		rim_mesh.scale = Vector3(1.0, 1.0, 0.5)
		rim_mesh.cast_shadow = GeometryInstance3D.SHADOW_CASTING_SETTING_OFF
		eye.add_child(rim_mesh)

		# Golden-brown iris – large and prominent
		var iris := MeshInstance3D.new()
		var iris_s := SphereMesh.new()
		iris_s.radius = 0.072
		iris_s.height = 0.08
		iris_s.radial_segments = 20
		iris_s.rings = 10
		iris.mesh = iris_s
		iris.material_override = iris_mat
		iris.position = Vector3(side * 0.005, 0.035, -0.055)
		iris.cast_shadow = GeometryInstance3D.SHADOW_CASTING_SETTING_OFF
		eye.add_child(iris)

		# Black pupil
		var pupil := MeshInstance3D.new()
		var pupil_s := SphereMesh.new()
		pupil_s.radius = 0.035
		pupil_s.height = 0.04
		pupil_s.radial_segments = 16
		pupil_s.rings = 8
		pupil.mesh = pupil_s
		pupil.material_override = pupil_mat
		pupil.position = Vector3(0.0, 0.0, -0.03)
		pupil.cast_shadow = GeometryInstance3D.SHADOW_CASTING_SETTING_OFF
		iris.add_child(pupil)

		# Large glossy highlight – wet/dewy
		var hl := MeshInstance3D.new()
		var hl_s := SphereMesh.new()
		hl_s.radius = 0.028
		hl_s.height = 0.032
		hl_s.radial_segments = 8
		hl_s.rings = 4
		hl.mesh = hl_s
		hl.material_override = highlight_mat
		hl.position = Vector3(-side * 0.02, 0.028, -0.028)
		hl.cast_shadow = GeometryInstance3D.SHADOW_CASTING_SETTING_OFF
		iris.add_child(hl)

		# Small secondary highlight
		var hl2 := MeshInstance3D.new()
		var hl2_s := SphereMesh.new()
		hl2_s.radius = 0.012
		hl2_s.height = 0.016
		hl2.mesh = hl2_s
		hl2.material_override = highlight_mat
		hl2.position = Vector3(side * 0.015, -0.015, -0.028)
		hl2.cast_shadow = GeometryInstance3D.SHADOW_CASTING_SETTING_OFF
		iris.add_child(hl2)

func _add_eyebrows(head_radius: float, parent: Node3D) -> void:
	# Small curved eyebrow arcs above each eye
	var brow_mat := StandardMaterial3D.new()
	brow_mat.albedo_color = Color(0.12, 0.08, 0.04)
	brow_mat.specular = 0.1
	brow_mat.roughness = 0.8

	for side in [-1.0, 1.0]:
		var brow := MeshInstance3D.new()
		var brow_s := SphereMesh.new()
		brow_s.radius = 0.07
		brow_s.height = 0.03
		brow_s.radial_segments = 12
		brow_s.rings = 4
		brow.mesh = brow_s
		brow.material_override = brow_mat
		brow.position = Vector3(side * 0.15, head_radius * 0.40, -head_radius * 0.82)
		brow.scale = Vector3(1.2, 0.7, 0.5)
		brow.rotation.z = side * -0.45  # Stronger arch → happier
		brow.cast_shadow = GeometryInstance3D.SHADOW_CASTING_SETTING_OFF
		parent.add_child(brow)
		_eyebrow_nodes.append(brow)

func _add_cheeks(head_radius: float, parent: Node3D) -> void:
	# Rosy cheeks for that kawaii look
	var cheek_mat := StandardMaterial3D.new()
	cheek_mat.albedo_color = Color(0.95, 0.55, 0.45, 0.6)
	cheek_mat.transparency = BaseMaterial3D.TRANSPARENCY_ALPHA
	cheek_mat.specular = 0.1
	cheek_mat.roughness = 0.9

	for side in [-1.0, 1.0]:
		var cheek := MeshInstance3D.new()
		var cheek_s := SphereMesh.new()
		cheek_s.radius = 0.075
		cheek_s.height = 0.050
		cheek_s.radial_segments = 14
		cheek_s.rings = 8
		cheek.mesh = cheek_s
		cheek.material_override = cheek_mat
		cheek.position = Vector3(side * 0.20, head_radius * -0.08, -head_radius * 0.68)
		cheek.cast_shadow = GeometryInstance3D.SHADOW_CASTING_SETTING_OFF
		parent.add_child(cheek)
		_cheek_nodes.append(cheek)

func _add_mouth(head_radius: float, parent: Node3D) -> void:
	# Reference-style mouth: rounded upper lip, open dark cavity, twin tongue lobes.
	var mouth_pivot := Node3D.new()
	mouth_pivot.position = Vector3(0.0, head_radius * -0.45, -head_radius * 1.18)
	mouth_pivot.scale = Vector3(0.72, 0.72, 0.72)
	parent.add_child(mouth_pivot)

	var mouth: Node3D = MouthComponent3DScript.new()
	mouth.face_color = Color(0.62, 0.85, 0.28)
	mouth.mouth_cavity_color = Color(0.19, 0.07, 0.04)
	mouth.tongue_color = Color(0.96, 0.67, 0.56)
	mouth.drool_enabled = false
	mouth.sphere_radius = head_radius * 1.4
	mouth_pivot.add_child(mouth)

	_mouth_node = mouth_pivot
	_mouth_component = mouth
	_mouth_base_scale = mouth_pivot.scale
	_mouth_base_pos = mouth_pivot.position


func _add_antennae(head_radius: float) -> void:
	# Two cute antennae with little balls at the tips
	var stalk_mat := StandardMaterial3D.new()
	stalk_mat.albedo_color = Color(0.45, 0.70, 0.18)
	stalk_mat.specular = 0.2
	stalk_mat.roughness = 0.7

	var tip_mat := StandardMaterial3D.new()
	tip_mat.albedo_color = Color(0.95, 0.85, 0.15)  # Yellow ball tips
	tip_mat.specular = 0.4
	tip_mat.roughness = 0.4

	for side in [-1.0, 1.0]:
		# Build antenna from multiple small segments that curve forward
		# like a fishing rod bending under a heavy fish
		var base := Node3D.new()
		base.position = Vector3(side * 0.10, head_radius * 1.05, head_radius * 0.0)
		base.rotation.z = side * -0.30  # Slight outward angle
		_mesh.add_child(base)

		var segments := 6
		var seg_height := 0.09
		var current_parent := base
		for i in range(segments):
			var seg_node := Node3D.new()
			seg_node.position = Vector3(0.0, seg_height, 0.0)
			# Each segment tilts forward more — accelerating curve like a fishing rod
			var bend := -0.12 - float(i) * 0.08
			seg_node.rotation.x = bend
			current_parent.add_child(seg_node)

			var seg_mesh := MeshInstance3D.new()
			var cyl := CylinderMesh.new()
			# Taper from thick base to thin tip
			var t := float(i) / float(segments)
			cyl.bottom_radius = lerpf(0.04, 0.02, t)
			cyl.top_radius = lerpf(0.035, 0.015, t)
			cyl.height = seg_height
			cyl.radial_segments = 8
			seg_mesh.mesh = cyl
			seg_mesh.material_override = stalk_mat
			seg_mesh.position = Vector3(0.0, -seg_height * 0.5, 0.0)
			seg_mesh.cast_shadow = GeometryInstance3D.SHADOW_CASTING_SETTING_OFF
			seg_node.add_child(seg_mesh)

			current_parent = seg_node

		# Yellow ball tip at the end of the curved antenna
		var tip := MeshInstance3D.new()
		var tip_s := SphereMesh.new()
		tip_s.radius = 0.10
		tip_s.height = 0.20
		tip_s.radial_segments = 16
		tip_s.rings = 8
		tip.mesh = tip_s
		tip.material_override = tip_mat
		tip.position = Vector3(0.0, 0.02, 0.0)
		tip.cast_shadow = GeometryInstance3D.SHADOW_CASTING_SETTING_OFF
		current_parent.add_child(tip)

# ── Tail ──

func _add_tail_tip(radius: float) -> void:
	# A small pointed nub at the back of the tail
	var tip_mat := StandardMaterial3D.new()
	tip_mat.albedo_color = Color(0.28, 0.52, 0.12)
	tip_mat.specular = 0.35
	tip_mat.roughness = 0.5

	var tip := MeshInstance3D.new()
	var cone := CylinderMesh.new()
	cone.top_radius = 0.0
	cone.bottom_radius = radius * 0.4
	cone.height = radius * 0.6
	cone.radial_segments = 12
	tip.mesh = cone
	tip.material_override = tip_mat
	tip.position = Vector3(0.0, radius * 0.3, radius * 0.6)
	tip.rotation.x = deg_to_rad(70)
	tip.cast_shadow = GeometryInstance3D.SHADOW_CASTING_SETTING_OFF
	_mesh.add_child(tip)

# ── Feet ──

func _add_feet(seg_radius: float, is_small: bool) -> void:
	# Cute rounded yellow-green feet
	var foot_mat := StandardMaterial3D.new()
	foot_mat.albedo_color = Color(0.70, 0.82, 0.30)
	foot_mat.specular = 0.2
	foot_mat.roughness = 0.7

	var foot_r := 0.07 if is_small else 0.085
	var spread := seg_radius * 0.75

	var dot_mat := StandardMaterial3D.new()
	dot_mat.albedo_color = Color(0.04, 0.04, 0.02)
	dot_mat.specular = 0.1
	dot_mat.roughness = 0.8

	for side_data in [[-1.0, "_foot_left"], [1.0, "_foot_right"]]:
		var side: float = side_data[0]
		var foot := MeshInstance3D.new()
		var foot_s := SphereMesh.new()
		foot_s.radius = foot_r
		foot_s.height = foot_r * 1.2
		foot_s.radial_segments = 12
		foot_s.rings = 6
		foot.mesh = foot_s
		foot.material_override = foot_mat
		foot.position = Vector3(side * spread, -seg_radius * 0.75, -0.02)
		foot.cast_shadow = GeometryInstance3D.SHADOW_CASTING_SETTING_OFF
		_mesh.add_child(foot)

		# Black spots on each foot
		for d in range(2):
			var dot := MeshInstance3D.new()
			var dot_s := SphereMesh.new()
			var dot_r := 0.055
			dot_s.radius = dot_r
			dot_s.height = dot_r * 0.5
			dot_s.radial_segments = 10
			dot_s.rings = 6
			dot.mesh = dot_s
			dot.material_override = dot_mat
			var dz := -0.01 + float(d) * 0.045
			dot.position = Vector3(side * foot_r * 0.3, foot_r * 0.25, dz)
			dot.cast_shadow = GeometryInstance3D.SHADOW_CASTING_SETTING_OFF
			foot.add_child(dot)

		if side < 0:
			_foot_left = foot
		else:
			_foot_right = foot

	_leg_phase = float(get_meta("seg_index", 0)) * 0.5 * PI

# ── Blink & expression animation ──

func _process(delta: float) -> void:
	_face_time += delta

	# Smooth crawl bob on every segment while moving.
	if _crawl_blend > 0.001:
		_crawl_phase += delta * _crawl_speed
		_crawl_blend = maxf(_crawl_blend - delta * 1.35, 0.0)
	else:
		_crawl_speed = 0.0
	var crawl_wave := sin(_crawl_phase)
	var crawl_lift := crawl_wave * 0.065 * _crawl_blend
	if _mesh:
		_mesh.position.y = lerpf(_mesh.position.y, _base_mesh_y + crawl_lift, delta * 10.0)
	if _foot_left and _foot_right:
		var foot_slide := crawl_wave * 0.06 * _crawl_blend
		_foot_left.position.z = lerpf(_foot_left.position.z, -0.02 + foot_slide, delta * 10.0)
		_foot_right.position.z = lerpf(_foot_right.position.z, -0.02 - foot_slide, delta * 10.0)

	# ── Idle behavior state machine ──
	if _is_idle:
		_idle_time += delta
		_idle_cycle_timer += delta
		
		# Sleep after being idle long enough
		if _idle_time >= IDLE_SLEEP_START and _expression != "sleeping":
			_expression = "sleeping"
			_spawn_zzz()
		elif _idle_time < IDLE_SLEEP_START:
			# Cycle: wait -> look at camera -> wait -> look again
			match _idle_phase:
				0:  # Waiting before first look
					if _idle_cycle_timer >= IDLE_LOOK_START:
						_idle_phase = 1
						_idle_cycle_timer = 0.0
						_expression = "looking"
				1:  # Looking at camera
					if _idle_cycle_timer >= IDLE_LOOK_DURATION:
						_idle_phase = 2
						_idle_cycle_timer = 0.0
						_expression = "happy"
				2:  # Pause between looks
					if _idle_cycle_timer >= IDLE_PAUSE:
						_idle_phase = 1
						_idle_cycle_timer = 0.0
						_expression = "looking"

	# ── Blink (not while sleeping) ──
	if not _eye_nodes.is_empty() and _expression != "sleeping":
		if _is_blinking:
			_blink_phase += delta * 8.0
			var t: float
			if _blink_phase < 1.0:
				t = _blink_phase
			elif _blink_phase < 2.0:
				t = 2.0 - _blink_phase
			else:
				t = 0.0
				_is_blinking = false
				_blink_timer = 0.0
				_blink_interval = randf_range(2.5, 5.0)
			var y_scale := lerpf(1.0, 0.05, t)
			for eye in _eye_nodes:
				eye.scale.y = y_scale
		else:
			_blink_timer += delta
			if _blink_timer >= _blink_interval:
				_is_blinking = true
				_blink_phase = 0.0
	elif not _eye_nodes.is_empty():
		# Eyes closed while sleeping
		for eye in _eye_nodes:
			eye.scale.y = lerpf(eye.scale.y, 0.05, delta * 3.0)

	# ── Expression timer (extra-happy fades back to default happy) ──
	# No longer needed since happy IS the default — remove fade-out.

	# ── Mouth animation ──
	if _mouth_node:
		if _mouth_component and _mouth_component.has_method("set_expression"):
			_mouth_component.set_expression(_expression)
		match _expression:
			"idle":
				var breath := sin(_face_time * 1.5) * 0.03
				var s := 1.0 + breath
				var idle_scale := _mouth_base_scale * s
				_mouth_node.scale = _mouth_node.scale.lerp(idle_scale, delta * 5.0)
			"happy":
				var t := clampf(_expression_timer, 0.0, 1.0)
				var happy_scale := _mouth_base_scale * lerpf(1.0, 1.4, t)
				_mouth_node.scale = _mouth_node.scale.lerp(happy_scale, delta * 8.0)
			"looking":
				var pulse := sin(_face_time * 2.0) * 0.03
				var look_scale := _mouth_base_scale * (0.85 + pulse)
				_mouth_node.scale = _mouth_node.scale.lerp(look_scale, delta * 4.0)
			"sleeping":
				var sleep_breath := sin(_face_time * 0.8) * 0.04
				var sleep_scale := _mouth_base_scale * (0.7 + sleep_breath)
				_mouth_node.scale = _mouth_node.scale.lerp(sleep_scale, delta * 2.0)

	# ── Eyebrow animation ──
	for i in _eyebrow_nodes.size():
		var brow := _eyebrow_nodes[i]
		var side := -1.0 if i == 0 else 1.0
		match _expression:
			"idle":
				brow.rotation.z = lerpf(brow.rotation.z, side * -0.45, delta * 3.0)
			"happy":
				brow.rotation.z = lerpf(brow.rotation.z, side * -0.25, delta * 6.0)
			"looking":
				var raise := 0.02 if i == 0 else 0.01
				brow.rotation.z = lerpf(brow.rotation.z, side * (-0.20 - raise), delta * 4.0)
			"sleeping":
				# Relaxed / slightly lowered
				brow.rotation.z = lerpf(brow.rotation.z, side * -0.05, delta * 2.0)

	# ── Cheek animation ──
	for cheek in _cheek_nodes:
		match _expression:
			"happy":
				cheek.scale = cheek.scale.lerp(Vector3(1.3, 1.3, 1.3), delta * 5.0)
			_:
				cheek.scale = cheek.scale.lerp(Vector3.ONE, delta * 3.0)

	# ── Head tilt ──
	if _expression == "looking":
		if _mesh:
			_mesh.rotation.x = lerpf(_mesh.rotation.x, -0.35, delta * 2.5)
			_mesh.rotation.z = lerpf(_mesh.rotation.z, sin(_face_time * 0.8) * 0.1, delta * 2.0)
		for eye in _eye_nodes:
			if eye.get_child_count() > 0:
				var iris := eye.get_child(0)
				iris.position.y = lerpf(iris.position.y, 0.06, delta * 3.0)
	elif _expression == "sleeping":
		# Head droops slightly forward
		if _mesh:
			var nod := sin(_face_time * 0.6) * 0.03
			_mesh.rotation.x = lerpf(_mesh.rotation.x, 0.15 + nod, delta * 1.5)
			_mesh.rotation.z = lerpf(_mesh.rotation.z, 0.0, delta * 2.0)
		# Animate zzZ floating upward
		_animate_zzz(delta)
	else:
		# Return head to normal
		if _mesh:
			_mesh.rotation.x = lerpf(_mesh.rotation.x, 0.0, delta * 3.0)
			_mesh.rotation.z = lerpf(_mesh.rotation.z, 0.0, delta * 3.0)
		for eye in _eye_nodes:
			if eye.get_child_count() > 0:
				var iris := eye.get_child(0)
				iris.position.y = lerpf(iris.position.y, -0.02, delta * 2.0)

func _spawn_zzz() -> void:
	_clear_zzz()
	_zzz_spawn_timer = 0.0

func _spawn_single_z() -> void:
	if not _mesh:
		return
	var z_node := Node3D.new()
	var label := Label3D.new()
	# Alternate between small 'z' and big 'Z'
	var is_big := _zzz_nodes.size() % 2 == 1
	label.text = "Z" if is_big else "z"
	label.font_size = 48 if is_big else 32
	label.modulate = Color(0.15, 0.15, 0.45, 0.0)  # start invisible, dark blue
	label.outline_modulate = Color(0.05, 0.05, 0.25, 0.9)
	label.outline_size = 10
	label.billboard = BaseMaterial3D.BILLBOARD_ENABLED
	label.no_depth_test = true
	z_node.add_child(label)
	# Start near the head, slightly to the right
	z_node.position = Vector3(0.2, 0.55, -0.15)
	z_node.set_meta("zzz_age", 0.0)
	z_node.set_meta("zzz_lifetime", 3.0)
	z_node.set_meta("zzz_drift_x", randf_range(-0.06, 0.12))
	_mesh.add_child(z_node)
	_zzz_nodes.append(z_node)

var _zzz_spawn_timer := 0.0
const ZZZ_SPAWN_INTERVAL := 0.7  # new z every 0.7 seconds

func _animate_zzz(delta: float) -> void:
	# Spawn new z characters periodically
	_zzz_spawn_timer += delta
	if _zzz_spawn_timer >= ZZZ_SPAWN_INTERVAL:
		_zzz_spawn_timer -= ZZZ_SPAWN_INTERVAL
		_spawn_single_z()

	# Animate each z: float up, drift sideways, fade in then out
	var to_remove: Array[int] = []
	for i in _zzz_nodes.size():
		var z_node := _zzz_nodes[i]
		var age: float = z_node.get_meta("zzz_age", 0.0) + delta
		var lifetime: float = z_node.get_meta("zzz_lifetime", 3.0)
		var drift_x: float = z_node.get_meta("zzz_drift_x", 0.05)
		z_node.set_meta("zzz_age", age)

		var t := age / lifetime  # 0 → 1
		# Float upward
		z_node.position.y = 0.55 + age * 0.25
		# Drift sideways with sine wave
		z_node.position.x = 0.2 + drift_x * age + sin(age * 2.5) * 0.06
		# Scale up slightly as it rises
		var s := 0.6 + t * 0.6
		z_node.scale = Vector3(s, s, s)
		# Rotate gently
		z_node.rotation.z = sin(age * 1.8) * 0.3

		# Fade: quick fade in, then gradual fade out
		var alpha: float
		if t < 0.15:
			alpha = t / 0.15  # fade in
		elif t < 0.7:
			alpha = 1.0  # fully visible
		else:
			alpha = (1.0 - t) / 0.3  # fade out
		alpha = clampf(alpha, 0.0, 1.0) * 0.85

		var label := z_node.get_child(0) as Label3D
		if label:
			label.modulate.a = alpha

		if age >= lifetime:
			to_remove.append(i)

	# Remove expired z nodes (iterate in reverse)
	for i in range(to_remove.size() - 1, -1, -1):
		var idx := to_remove[i]
		_zzz_nodes[idx].queue_free()
		_zzz_nodes.remove_at(idx)

func _clear_zzz() -> void:
	for z_node in _zzz_nodes:
		z_node.queue_free()
	_zzz_nodes.clear()

# ── Expression API (called from level_3d.gd) ──

func set_expression(expr: String, duration := 1.0) -> void:
	if _expression == "sleeping":
		_clear_zzz()
	_expression = expr
	_expression_timer = duration

func set_idle(idle: bool) -> void:
	if idle and not _is_idle:
		_is_idle = true
		_idle_time = 0.0
		_idle_cycle_timer = 0.0
		_idle_phase = 0
	elif not idle and _is_idle:
		_is_idle = false
		_idle_time = 0.0
		_idle_cycle_timer = 0.0
		_idle_phase = 0
		if _expression == "looking" or _expression == "sleeping":
			_clear_zzz()
			_expression = "happy"

func look_at_camera() -> void:
	_expression = "looking"

func stop_looking() -> void:
	if _expression == "looking" or _expression == "sleeping":
		_clear_zzz()
		_expression = "happy"

# ── Animation callbacks (API kept for level_3d.gd) ──

func wiggle_legs(speed_scale := 1.0) -> void:
	_leg_phase += 1.0
	_crawl_phase += PI * 0.55
	_crawl_speed = 9.0 * speed_scale
	_crawl_blend = 1.0

func update_direction(_is_horizontal: bool) -> void:
	pass

func _make_head_material() -> StandardMaterial3D:
	var head_mat := StandardMaterial3D.new()
	head_mat.specular = 0.55
	head_mat.roughness = 0.45
	head_mat.metallic = 0.0
	head_mat.rim_enabled = true
	head_mat.rim = 0.5
	head_mat.rim_tint = 0.3
	head_mat.albedo_color = Color(0.62, 0.85, 0.28)
	return head_mat

func update_seg_type(new_type: String) -> void:
	set_meta("seg_type", new_type)
	if not _mesh or not _mat:
		return
	var sphere := _mesh.mesh as SphereMesh
	if not sphere:
		return
	match new_type:
		"head":
			sphere.radius = 0.34
			sphere.height = 0.34 * 2.1
			_mat = _make_body_gradient_material(0, false)
			_mat.set_shader_parameter("show_stripes", false)
			_mat.set_shader_parameter("pear_shape", 1.0)
			_mat.set_shader_parameter("segment_radius", 0.34)
			_mat.set_shader_parameter("mid_color", Color(0.68, 0.90, 0.18))
			_mat.set_shader_parameter("specular_amt", 0.55)
			_mat.set_shader_parameter("roughness_amt", 0.35)
			_base_mesh_y = 0.34 * 0.85 + 0.34 * 0.16
			_mesh.position.y = _base_mesh_y
		"tail":
			sphere.radius = 0.22
			sphere.height = 0.385
			_mat = _make_body_gradient_material(int(get_meta("seg_index", 0)), true)
			_base_mesh_y = 0.22 * 0.85
			_mesh.position.y = _base_mesh_y
		_:
			sphere.radius = 0.28
			sphere.height = 0.49
			_mat = _make_body_gradient_material(int(get_meta("seg_index", 0)))
			_base_mesh_y = 0.28 * 0.85
			_mesh.position.y = _base_mesh_y
	_mesh.material_override = _mat

func flash_red() -> void:
	if _mat is StandardMaterial3D:
		(_mat as StandardMaterial3D).albedo_color = Color(1.0, 0.5, 0.5)
	elif _mat is ShaderMaterial:
		var shader_mat := _mat as ShaderMaterial
		shader_mat.set_shader_parameter("top_color", Color(0.70, 0.24, 0.24))
		shader_mat.set_shader_parameter("mid_color", Color(0.95, 0.40, 0.38))
		shader_mat.set_shader_parameter("bottom_color", Color(0.72, 0.26, 0.24))
		shader_mat.set_shader_parameter("belly_glow_color", Color(0.78, 0.32, 0.28))

func set_head_direction(_vertical: bool) -> void:
	pass
