extends CharacterBody3D
class_name DesktopDebugPlayer

@export var walk_speed_mps := 4.0
@export var flight_speed_mps := 6.0
var flight_enabled := false

func _ready() -> void:
	add_to_group("player")
	var event_bus := get_node_or_null("/root/EventBus")
	if event_bus != null:
		event_bus.flight_mode_changed.connect(_on_flight_mode_changed)

func _physics_process(delta: float) -> void:
	var input := Vector3.ZERO
	input.x = Input.get_action_strength("ui_right") - Input.get_action_strength("ui_left")
	input.z = Input.get_action_strength("ui_down") - Input.get_action_strength("ui_up")
	var speed := flight_speed_mps if flight_enabled else walk_speed_mps
	velocity = input.normalized() * speed
	if flight_enabled:
		velocity.y = Input.get_action_strength("ui_accept") * speed
	else:
		velocity.y -= 9.8 * delta
	move_and_slide()

func _on_flight_mode_changed(enabled: bool) -> void:
	flight_enabled = enabled
