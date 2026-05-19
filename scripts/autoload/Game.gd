extends Node

const SaveStateResource := preload("res://scripts/core/SaveState.gd")
const ComfortSettingsResource := preload("res://scripts/core/ComfortSettings.gd")

var save_state = SaveStateResource.new()
var comfort_settings = ComfortSettingsResource.new()

func reset_demo() -> void:
	save_state.reset()
	comfort_settings.apply_mode("comfort")

func apply_comfort_mode(mode: String) -> void:
	comfort_settings.apply_mode(mode)
	save_state.comfort_mode = comfort_settings.movement_mode
	EventBus.comfort_settings_changed.emit(comfort_settings)
