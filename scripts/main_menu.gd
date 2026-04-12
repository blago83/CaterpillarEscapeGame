extends Control

func _ready() -> void:
	$VBox/PlayButton.pressed.connect(_on_play)
	$VBox/QuitButton.pressed.connect(_on_quit)

func _on_play() -> void:
	print("Play button pressed!")
	if not ResourceLoader.exists("res://scenes/Level3D.tscn"):
		print("ERROR: Level3D.tscn not found by ResourceLoader. Restart Godot editor to detect new files.")
		return
	print("Scene exists, loading...")
	get_tree().change_scene_to_file("res://scenes/Level3D.tscn")

func _on_quit() -> void:
	get_tree().quit()
