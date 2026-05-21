extends Node3D
class_name XRPlayer

@export var comfort_settings: Resource
var flight_enabled := false

func _ready() -> void:
	add_to_group("player")
	if comfort_settings == null:
		var game := get_node_or_null("/root/Game")
		if game != null:
			comfort_settings = game.comfort_settings
	var event_bus := get_node_or_null("/root/EventBus")
	if event_bus != null:
		event_bus.flight_mode_changed.connect(_on_flight_mode_changed)
		event_bus.comfort_settings_changed.connect(_on_comfort_settings_changed)

func _on_flight_mode_changed(enabled: bool) -> void:
	flight_enabled = enabled
	# This flag is consumed by XR Tools flight providers during scene assembly.

func _on_comfort_settings_changed(settings) -> void:
	comfort_settings = settings
	# Applies snap/smooth turn, teleport/smooth movement, speed, and vignette values to XR provider nodes.
