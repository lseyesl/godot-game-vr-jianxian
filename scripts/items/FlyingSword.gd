extends Node3D
class_name FlyingSword

@export var hover_height_m := 0.8
var unlocked := false
var flight_enabled := false

func collect() -> void:
	if unlocked:
		return
	unlocked = true
	set_flight_enabled(true)
	if not is_inside_tree():
		return
	var event_bus := get_node_or_null("/root/EventBus")
	if event_bus != null:
		event_bus.sword_unlocked.emit()
	var game := get_node_or_null("/root/Game")
	if game != null:
		game.save_state.sword_unlocked = true
		if game.has_method("advance_quest"):
			game.advance_quest("sword_collected")

func set_flight_enabled(enabled: bool) -> void:
	flight_enabled = enabled and unlocked
	if not is_inside_tree():
		return
	var event_bus := get_node_or_null("/root/EventBus")
	if event_bus != null:
		event_bus.flight_mode_changed.emit(flight_enabled)

func recall_to_hand(hand_position: Vector3) -> void:
	if not unlocked:
		return
	global_position = hand_position + Vector3.UP * hover_height_m

func _on_collect_area_body_entered(body: Node3D) -> void:
	if body.is_in_group("player"):
		collect()
