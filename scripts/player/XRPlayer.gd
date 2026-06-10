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
@export var health_component_path: NodePath = ^"HealthComponent"
@export var spell_controller_path: NodePath = ^"PlayerSpellController"
@export var spell_emitter_path: NodePath = ^"XROrigin3D/RightHand/SpellEmitter"
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

func _physics_process(delta: float) -> void:
	var controller := get_spell_controller()
	if controller != null and controller.has_method("tick_cooldowns"):
		controller.tick_cooldowns(delta)

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

func get_health_component() -> Node:
	return get_node_or_null(health_component_path)

func receive_damage(amount: int, source_id: String = "") -> int:
	var health = get_health_component()
	if health == null:
		return 0
	var current: int = health.apply_damage(amount, source_id)
	if is_inside_tree():
		var event_bus := get_node_or_null("/root/EventBus")
		if event_bus != null and event_bus.has_signal("player_health_changed"):
			event_bus.player_health_changed.emit(current, health.max_health)
	return current

func cast_spell_id(spell_id: String) -> bool:
	return cast_spell_from_emitter(spell_id, spell_emitter_path)

func cast_spell_from_emitter(spell_id: String, emitter_path: NodePath = spell_emitter_path) -> bool:
	var controller := get_spell_controller()
	var emitter := get_node_or_null(emitter_path) as Node3D
	if controller == null or emitter == null:
		return false
	if controller.has_method("cast_spell_from_node"):
		return controller.cast_spell_from_node(spell_id, emitter)
	return false

func get_spell_controller() -> Node:
	return get_node_or_null(spell_controller_path)
