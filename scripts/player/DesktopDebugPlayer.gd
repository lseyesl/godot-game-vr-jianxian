extends CharacterBody3D
class_name DesktopDebugPlayer

@export var walk_speed_mps := 4.0
@export var flight_speed_mps := 6.0
@export var mouse_sensitivity := 0.08
@export var min_pitch_degrees := -80.0
@export var max_pitch_degrees := 80.0
@export var health_component_path: NodePath = ^"HealthComponent"
@export var spell_controller_path: NodePath = ^"PlayerSpellController"
@export var spell_emitter_path: NodePath = ^"Camera3D"
var flight_enabled := false
var mouse_capture_requested := false

@onready var camera: Camera3D = $Camera3D

func _ready() -> void:
	add_to_group("player")
	request_mouse_capture()
	var event_bus := get_node_or_null("/root/EventBus")
	if event_bus != null:
		event_bus.flight_mode_changed.connect(_on_flight_mode_changed)

func _physics_process(delta: float) -> void:
	var input := get_movement_input_vector()
	var speed := flight_speed_mps if flight_enabled else walk_speed_mps
	velocity = get_yaw_relative_direction(input) * speed
	if flight_enabled:
		velocity.y = Input.get_action_strength("ui_accept") * speed
	else:
		velocity.y -= 9.8 * delta
	move_and_slide()
	var controller := get_spell_controller()
	if controller != null and controller.has_method("tick_cooldowns"):
		controller.tick_cooldowns(delta)

func _unhandled_input(event: InputEvent) -> void:
	if event.is_action_pressed("ui_cancel"):
		release_mouse_capture()
		return
	for action in ["spell_primary", "spell_guard", "spell_seal"]:
		if event.is_action_pressed(action):
			if action == "spell_primary" and not mouse_capture_requested:
				request_mouse_capture()
				return
			cast_spell_action(action)
			return
	if event is InputEventMouseButton and event.button_index == MOUSE_BUTTON_LEFT and event.pressed:
		request_mouse_capture()
		return
	if event is InputEventMouseMotion and mouse_capture_requested:
		apply_mouse_look(event.relative)

func request_mouse_capture() -> void:
	mouse_capture_requested = true
	Input.mouse_mode = Input.MOUSE_MODE_CAPTURED

func release_mouse_capture() -> void:
	mouse_capture_requested = false
	Input.mouse_mode = Input.MOUSE_MODE_VISIBLE

func get_movement_input_vector() -> Vector3:
	var input := Vector3.ZERO
	input.x = Input.get_action_strength("move_right") - Input.get_action_strength("move_left")
	input.z = Input.get_action_strength("move_back") - Input.get_action_strength("move_forward")
	return input

func get_yaw_relative_direction(local_input: Vector3) -> Vector3:
	if local_input == Vector3.ZERO:
		return Vector3.ZERO
	var yaw_basis := Basis(Vector3.UP, rotation.y)
	return (yaw_basis * local_input).normalized()

func apply_mouse_look(relative: Vector2) -> void:
	rotation_degrees.y -= relative.x * mouse_sensitivity
	var look_camera := get_camera()
	look_camera.rotation_degrees.x = clampf(look_camera.rotation_degrees.x - relative.y * mouse_sensitivity, min_pitch_degrees, max_pitch_degrees)

func get_camera() -> Camera3D:
	if camera == null:
		camera = get_node_or_null("Camera3D") as Camera3D
	return camera

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

func spell_id_for_action(action_name: String) -> String:
	match action_name:
		"spell_primary":
			return "spirit_bolt"
		"spell_guard":
			return "guard_charm"
		"spell_seal":
			return "seal_break"
		_:
			return ""

func cast_spell_action(action_name: String) -> bool:
	var spell_id := spell_id_for_action(action_name)
	if spell_id == "":
		return false
	return cast_spell_id(spell_id)

func cast_spell_id(spell_id: String) -> bool:
	var controller := get_spell_controller()
	var emitter := get_spell_emitter()
	if controller == null or emitter == null:
		return false
	if controller.has_method("cast_spell_from_node"):
		return controller.cast_spell_from_node(spell_id, emitter)
	return false

func get_spell_controller() -> Node:
	return get_node_or_null(spell_controller_path)

func get_spell_emitter() -> Node3D:
	return get_node_or_null(spell_emitter_path) as Node3D

func _on_flight_mode_changed(enabled: bool) -> void:
	flight_enabled = enabled
