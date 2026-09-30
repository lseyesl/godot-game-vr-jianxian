extends Node

const SaveStateResource := preload("res://scripts/core/SaveState.gd")
const ComfortSettingsResource := preload("res://scripts/core/ComfortSettings.gd")
const QuestStateResource := preload("res://scripts/core/QuestState.gd")

const COMPLETION_TITLE := "试炼完成"
const COMPLETION_MESSAGE := "飞剑归鞘，山谷封印已净。你已完成剑修试炼。"

var save_state = SaveStateResource.new()
var comfort_settings = ComfortSettingsResource.new()
var quest_state = QuestStateResource.new()
var completion_feedback_emitted := false

func reset_demo() -> void:
	save_state.reset()
	quest_state.current_step = save_state.quest_step
	completion_feedback_emitted = false
	comfort_settings.apply_mode("comfort")

func apply_comfort_mode(mode: String) -> void:
	comfort_settings.apply_mode(mode)
	save_state.comfort_mode = comfort_settings.movement_mode
	var event_bus := _get_event_bus()
	if event_bus != null and event_bus.has_signal("comfort_settings_changed"):
		event_bus.comfort_settings_changed.emit(comfort_settings)

func advance_quest(event_id: String) -> bool:
	var advanced: bool = quest_state.advance(event_id)
	if advanced:
		save_state.quest_step = quest_state.current_step
		var event_bus := _get_event_bus()
		if event_bus != null:
			if event_bus.has_signal("quest_step_changed"):
				event_bus.quest_step_changed.emit(quest_state.current_step)
			if event_bus.has_signal("objective_changed"):
				event_bus.objective_changed.emit(quest_state.current_objective())
			if quest_state.current_step == "complete" and not completion_feedback_emitted:
				completion_feedback_emitted = true
				if event_bus.has_signal("quest_completed"):
					event_bus.quest_completed.emit()
				if event_bus.has_signal("completion_feedback_requested"):
					event_bus.completion_feedback_requested.emit(COMPLETION_TITLE, COMPLETION_MESSAGE)
	return advanced

func _get_event_bus() -> Node:
	var local_bus := get_parent().get_node_or_null("EventBus") if get_parent() != null else null
	if local_bus != null:
		return local_bus
	if is_inside_tree():
		return get_node_or_null("/root/EventBus")
	return null
