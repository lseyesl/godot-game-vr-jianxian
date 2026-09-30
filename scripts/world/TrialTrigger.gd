extends Area3D

func _on_body_entered(body: Node3D) -> void:
	if body.is_in_group("player"):
		var game := get_node_or_null("/root/Game")
		if game != null:
			game.advance_quest("entered_trial")
