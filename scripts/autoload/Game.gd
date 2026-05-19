extends Node

const SaveStateResource := preload("res://scripts/core/SaveState.gd")
const ComfortSettingsResource := preload("res://scripts/core/ComfortSettings.gd")
const QuestStateResource := preload("res://scripts/core/QuestState.gd")

var save_state = SaveStateResource.new()
var comfort_settings = ComfortSettingsResource.new()
var quest_state = QuestStateResource.new()

func reset_demo() -> void:
	save_state.reset()
	comfort_settings.apply_mode("comfort")

func apply_comfort_mode(mode: String) -> void:
	comfort_settings.apply_mode(mode)
	save_state.comfort_mode = comfort_settings.movement_mode
	EventBus.comfort_settings_changed.emit(comfort_settings)

func advance_quest(event_id: String) -> bool:
	var advanced: bool = quest_state.advance(event_id)
	if advanced:
		save_state.quest_step = quest_state.current_step
		EventBus.quest_step_changed.emit(quest_state.current_step)
		EventBus.objective_changed.emit(quest_state.current_objective())
	return advanced
