extends Control

func _ready() -> void:
	$CenterPanel/VBoxContainer/PlayButton.pressed.connect(_on_play_pressed)
	$CenterPanel/VBoxContainer/QuitButton.pressed.connect(_on_quit_pressed)

func _on_play_pressed() -> void:
	get_tree().change_scene_to_file("res://scenes/Level.tscn")

func _on_quit_pressed() -> void:
	get_tree().quit()
