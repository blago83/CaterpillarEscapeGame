extends Control

func _ready() -> void:
	$Card/VBox/PlayCampaignButton.pressed.connect(_on_play_campaign)
	$Card/VBox/Level0TestButton.pressed.connect(_on_test_level0)
	$Card/VBox/QuitButton.pressed.connect(_on_quit)

func _on_play_campaign() -> void:
	if not ResourceLoader.exists("res://scenes/Level3D.tscn"):
		push_error("Level3D.tscn not found.")
		return
	get_tree().change_scene_to_file("res://scenes/Level3D.tscn")

func _on_test_level0() -> void:
	if not ResourceLoader.exists("res://scenes/Level0.tscn"):
		push_error("Level0.tscn not found.")
		return
	get_tree().change_scene_to_file("res://scenes/Level0.tscn")

func _on_quit() -> void:
	get_tree().quit()
