extends Control

func _ready() -> void:
	$VBox/PlayButton.pressed.connect(_on_play)
	$VBox/QuitButton.pressed.connect(_on_quit)

func _on_play() -> void:
	get_tree().change_scene_to_file("res://scenes/Level.tscn")

func _on_quit() -> void:
	get_tree().quit()
