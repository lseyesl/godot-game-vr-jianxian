extends Node3D
class_name SealEncounter

@export var remaining_hits := 3
@export var target_id := "seal"
var cleansed := false

func receive_spell(spell_id: String) -> void:
	if cleansed:
		return
	var outcome := ""
	if spell_id == "spirit_bolt":
		remaining_hits = max(0, remaining_hits - 1)
		outcome = "hit"
	elif spell_id == "seal_break":
		remaining_hits = 0
		outcome = "cleanse"
	else:
		return
	if is_inside_tree():
		var event_bus := _get_event_bus()
		if event_bus != null:
			event_bus.seal_weakened.emit(remaining_hits)
	if remaining_hits == 0:
		outcome = "cleanse"
	_emit_combat_feedback(spell_id, outcome)
	if remaining_hits == 0:
		_cleanse()

func _emit_combat_feedback(spell_id: String, outcome: String) -> void:
	var event_bus := _get_event_bus()
	if event_bus != null and event_bus.has_signal("combat_feedback_requested"):
		event_bus.combat_feedback_requested.emit(spell_id, target_id, outcome)

func _get_event_bus() -> Node:
	var local_bus := get_parent().get_node_or_null("EventBus") if get_parent() != null else null
	if local_bus != null:
		return local_bus
	if is_inside_tree():
		return get_node_or_null("/root/EventBus")
	return null

func _cleanse() -> void:
	if cleansed:
		return
	cleansed = true
	if not is_inside_tree():
		return
	var event_bus := _get_event_bus()
	if event_bus != null:
		event_bus.seal_cleansed.emit()
	var game := get_node_or_null("/root/Game")
	if game != null and game.has_method("advance_quest"):
		game.advance_quest("seal_cleansed")

func _on_hit_area_area_entered(area: Area3D) -> void:
	if area.has_method("_on_body_entered"):
		area._on_body_entered(self)
	elif "spell_id" in area:
		receive_spell(area.spell_id)
