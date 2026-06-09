extends CharacterBody3D
class_name DesktopDebugPlayer

@export var walk_speed_mps := 4.0
@export var flight_speed_mps := 6.0
@export var mouse_sensitivity := 0.08
@export var min_pitch_degrees := -80.0
@export var max_pitch_degrees := 80.0
@export var health_component_path: NodePath = ^"HealthComponent"
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

func _unhandled_input(event: InputEvent) -> void:
	if event.is_action_pressed("ui_cancel"):
		release_mouse_capture()
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

func _on_flight_mode_changed(enabled: bool) -> void:
	flight_enabled = enabled
