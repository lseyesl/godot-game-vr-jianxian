extends Control
class_name ComfortSettingsPanel

func set_comfort_mode() -> void:
	var game := get_node_or_null("/root/Game")
	if game != null:
		game.apply_comfort_mode("comfort")

func set_immersive_mode() -> void:
	var game := get_node_or_null("/root/Game")
	if game != null:
		game.apply_comfort_mode("immersive")
