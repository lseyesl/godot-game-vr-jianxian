extends Node3D
class_name XRPlayer

const TURN_MODE_SNAP := 1
const TURN_MODE_SMOOTH := 2

@export var comfort_settings: Resource
@export var direct_movement_path: NodePath = ^"XROrigin3D/RightHand/MovementDirect"
@export var teleport_path: NodePath = ^"XROrigin3D/LeftHand/FunctionTeleport"
@export var turn_provider_path: NodePath = ^"XROrigin3D/RightHand/MovementTurn"
@export var flight_provider_path: NodePath = ^"XROrigin3D/MovementFlight"
@export var vignette_path: NodePath = ^"XROrigin3D/XRCamera3D/Vignette"
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
	apply_comfort_settings()
	apply_flight_state()

func _on_flight_mode_changed(enabled: bool) -> void:
	flight_enabled = enabled
	apply_flight_state()

func _on_comfort_settings_changed(settings) -> void:
	comfort_settings = settings
	apply_comfort_settings()
	apply_flight_state()

func apply_comfort_settings() -> void:
	if comfort_settings == null:
		return
	var immersive := String(comfort_settings.movement_mode) == "immersive"
	_set_provider_enabled(direct_movement_path, immersive)
	_set_provider_enabled(teleport_path, not immersive)
	_set_provider_property(turn_provider_path, &"turn_mode", TURN_MODE_SMOOTH if immersive else TURN_MODE_SNAP)
	_set_provider_property(direct_movement_path, &"max_speed", float(comfort_settings.flight_speed_limit_mps))
	_set_provider_property(flight_provider_path, &"speed_scale", float(comfort_settings.flight_speed_limit_mps))
	_set_provider_property(vignette_path, &"auto_velocity_limit", float(comfort_settings.flight_speed_limit_mps))

func apply_flight_state() -> void:
	var flight_provider := get_node_or_null(flight_provider_path)
	_set_node_enabled(flight_provider, flight_enabled)
	if not flight_enabled and flight_provider != null and flight_provider.has_method("set_flying"):
		flight_provider.set_flying(false)
	var vignette_enabled := false
	if comfort_settings != null:
		vignette_enabled = flight_enabled and bool(comfort_settings.flight_vignette_enabled)
	_set_provider_property(vignette_path, &"auto_adjust", vignette_enabled)

func _set_provider_enabled(path: NodePath, enabled: bool) -> void:
	_set_node_enabled(get_node_or_null(path), enabled)

func _set_node_enabled(node: Node, enabled: bool) -> void:
	if node != null and &"enabled" in node:
		node.set(&"enabled", enabled)

func _set_provider_property(path: NodePath, property_name: StringName, value: Variant) -> void:
	var node := get_node_or_null(path)
	if node != null and property_name in node:
		node.set(property_name, value)
