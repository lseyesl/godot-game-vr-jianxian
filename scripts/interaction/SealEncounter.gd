extends Node3D
class_name SealEncounter

@export var remaining_hits := 3
var cleansed := false

func receive_spell(spell_id: String) -> void:
	if cleansed:
		return
	if spell_id == "spirit_bolt":
		remaining_hits = max(0, remaining_hits - 1)
	elif spell_id == "seal_break":
		remaining_hits = 0
	else:
		return
	if is_inside_tree():
		var event_bus := get_node_or_null("/root/EventBus")
		if event_bus != null:
			event_bus.seal_weakened.emit(remaining_hits)
	if remaining_hits == 0:
		_cleanse()

func _cleanse() -> void:
	if cleansed:
		return
	cleansed = true
	if not is_inside_tree():
		return
	var event_bus := get_node_or_null("/root/EventBus")
	if event_bus != null:
		event_bus.seal_cleansed.emit()
	var game := get_node_or_null("/root/Game")
	if game != null and game.has_method("advance_quest"):
		game.advance_quest("seal_cleansed")
