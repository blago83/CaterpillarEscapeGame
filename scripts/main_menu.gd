extends Control

const Level3DScript := preload("res://scripts/level_3d.gd")
const LEVEL_NAMES := [
	"First Steps",
	"Bushes & Spikes",
	"Spider Garden",
	"Wormholes",
	"Fruit Hunt",
	"Big Garden",
	"Spinning Rings",
]

var _picker: Control = null

func _ready() -> void:
	$Card/VBox/PlayCampaignButton.pressed.connect(_on_play_campaign)
	$Card/VBox/ChooseLevelButton.pressed.connect(_on_choose_level)
	$Card/VBox/Level0TestButton.pressed.connect(_on_test_level0)
	$Card/VBox/QuitButton.pressed.connect(_on_quit)
	_build_level_picker()

func _on_play_campaign() -> void:
	if not ResourceLoader.exists("res://scenes/Level3D.tscn"):
		push_error("Level3D.tscn not found.")
		return
	get_tree().change_scene_to_file("res://scenes/Level3D.tscn")

func _on_choose_level() -> void:
	_picker.visible = true
	$Card.visible = false

func _on_picker_back() -> void:
	_picker.visible = false
	$Card.visible = true

func _on_level_picked(index: int) -> void:
	Level3DScript.start_level = index
	_on_play_campaign()

func _level_name(index: int) -> String:
	return String(LEVEL_NAMES[index]) if index < LEVEL_NAMES.size() else "Level %d" % (index + 1)

func _build_level_picker() -> void:
	_picker = PanelContainer.new()
	_picker.set_anchors_and_offsets_preset(Control.PRESET_CENTER)
	_picker.offset_left = -420
	_picker.offset_right = 420
	_picker.offset_top = -560
	_picker.offset_bottom = 560
	_picker.visible = false
	add_child(_picker)

	var box := VBoxContainer.new()
	box.add_theme_constant_override("separation", 22)
	_picker.add_child(box)

	var title := Label.new()
	title.text = "Choose a Level"
	title.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	title.add_theme_font_size_override("font_size", 52)
	box.add_child(title)

	var grid := GridContainer.new()
	grid.columns = 2
	grid.add_theme_constant_override("h_separation", 18)
	grid.add_theme_constant_override("v_separation", 18)
	grid.size_flags_vertical = Control.SIZE_EXPAND_FILL
	box.add_child(grid)

	var levels: Array = Level3DScript.LEVELS
	for i in levels.size():
		var rows: Array = levels[i]
		var btn := Button.new()
		btn.name = "Level%d" % (i + 1)
		btn.text = "%d\n%s\n%dx%d" % [i + 1, _level_name(i), String(rows[0]).length(), rows.size()]
		btn.custom_minimum_size = Vector2(380, 170)
		btn.size_flags_horizontal = Control.SIZE_EXPAND_FILL
		btn.add_theme_font_size_override("font_size", 30)
		btn.pressed.connect(_on_level_picked.bind(i))
		grid.add_child(btn)

	var back := Button.new()
	back.name = "BackButton"
	back.text = "Back"
	back.custom_minimum_size = Vector2(0, 86)
	back.add_theme_font_size_override("font_size", 32)
	back.pressed.connect(_on_picker_back)
	box.add_child(back)

func _on_test_level0() -> void:
	if not ResourceLoader.exists("res://scenes/Level0.tscn"):
		push_error("Level0.tscn not found.")
		return
	get_tree().change_scene_to_file("res://scenes/Level0.tscn")

func _on_quit() -> void:
	get_tree().quit()
