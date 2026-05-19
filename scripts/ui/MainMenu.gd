extends Control

func _on_start_button_pressed() -> void:
	get_tree().change_scene_to_file("res://scenes/main/Main.tscn")

func _on_reset_button_pressed() -> void:
	var game := get_node_or_null("/root/Game")
	if game != null:
		game.reset_demo()
