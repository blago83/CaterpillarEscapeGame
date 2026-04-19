extends Node3D

class_name MouthComponent3D

@export var face_color := Color(0.62, 0.85, 0.28)
@export var mouth_cavity_color := Color(0.19, 0.07, 0.04)
@export var tongue_color := Color(0.92, 0.30, 0.26)
@export var drool_enabled := false
@export var mouth_size := Vector2(0.52, 0.42)
@export var sphere_radius := 0.22  # tighter than head = more visible curvature

var _mesh: MeshInstance3D
var _textures: Dictionary = {}
var _current_expression := "happy"
var _material: ShaderMaterial

func _ready() -> void:
	_mesh = MeshInstance3D.new()
	var quad := QuadMesh.new()
	quad.size = mouth_size
	quad.subdivide_width = 24
	quad.subdivide_depth = 18
	_mesh.mesh = quad
	_mesh.cast_shadow = GeometryInstance3D.SHADOW_CASTING_SETTING_OFF
	add_child(_mesh)

	_material = ShaderMaterial.new()
	_material.render_priority = 2
	var shader := Shader.new()
	shader.code = _get_shader_code()
	_material.shader = shader
	_material.set_shader_parameter("sphere_radius", sphere_radius)
	_mesh.material_override = _material

	_textures["happy"] = load("res://assets/New/mouth_expressions/happy.png") as Texture2D
	_textures["looking"] = load("res://assets/New/mouth_expressions/looking.png") as Texture2D
	_textures["idle"] = load("res://assets/New/mouth_expressions/idle.png") as Texture2D
	_textures["sleeping"] = load("res://assets/New/mouth_expressions/sleeping.png") as Texture2D
	set_expression("happy")

func set_expression(expr: String) -> void:
	_current_expression = expr if _textures.has(expr) else "happy"
	if _material:
		_material.set_shader_parameter("albedo_tex", _textures[_current_expression])

func _get_shader_code() -> String:
	return """
shader_type spatial;
render_mode blend_mix, depth_draw_always, cull_disabled, unshaded;

uniform sampler2D albedo_tex : source_color;
uniform float sphere_radius = 0.22;

void vertex() {
	// Project flat quad onto sphere surface.
	float r = sphere_radius;
	float angle_h = VERTEX.x / r;
	float angle_v = VERTEX.y / r;

	VERTEX.x = r * sin(angle_h) * cos(angle_v);
	VERTEX.y = r * sin(angle_v) * cos(angle_h);

	float base_z = r * (1.0 - cos(angle_h) * cos(angle_v));

	// Distance from center in UV space (0 at center, 1 at corners)
	float dx = UV.x * 2.0 - 1.0;
	float dy = UV.y * 2.0 - 1.0;

	// Vertical bias: top (UV.y=0) sticks OUT like a nose, bottom (UV.y=1) tucks IN
	float vert_bias = mix(-0.07, 0.13, UV.y * UV.y);
	// Corner bias: corners pushed extra into head
	float corner_bias = 0.04 * dx * dx * dy * dy;
	// Horizontal edge bias: sides pushed in
	float horiz_bias = 0.02 * dx * dx;

	VERTEX.z = base_z + vert_bias + corner_bias + horiz_bias;
}

void fragment() {
	vec4 tex = texture(albedo_tex, UV);
	ALBEDO = tex.rgb;
	ALPHA = tex.a;
	if (ALPHA < 0.01) {
		discard;
	}
}
"""