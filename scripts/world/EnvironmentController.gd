extends Node
class_name EnvironmentController

const EnvironmentStateResource := preload("res://scripts/core/EnvironmentState.gd")

@export var environment_state: Resource = EnvironmentStateResource.new()
@export var directional_light_path: NodePath
@export var world_environment_path: NodePath
@export var summer_light_energy := 1.35
@export var summer_sky_color := Color(0.48, 0.58, 0.68, 1.0)
@export var late_afternoon_light_color := Color(1.0, 0.78, 0.52, 1.0)

func _ready() -> void:
	apply_environment()

func _process(delta: float) -> void:
	if environment_state == null:
		return
	environment_state.advance_time(delta)
	apply_environment()

func apply_environment() -> void:
	if environment_state == null:
		return
	_apply_directional_light()
	_apply_world_environment()

func _apply_directional_light() -> void:
	var light := get_node_or_null(directional_light_path)
	if not light is DirectionalLight3D:
		return
	var day_progress := float(environment_state.normalized_day_progress())
	var sun_pitch := -lerpf(12.0, 68.0, _daylight_height_factor(day_progress))
	var sun_yaw := lerpf(-120.0, 120.0, day_progress)
	light.rotation_degrees = Vector3(sun_pitch, sun_yaw, 0.0)
	light.light_color = late_afternoon_light_color
	light.light_energy = summer_light_energy if environment_state.is_summer() else 1.0

func _apply_world_environment() -> void:
	var world_environment := get_node_or_null(world_environment_path)
	if not world_environment is WorldEnvironment:
		return
	if world_environment.environment == null:
		world_environment.environment = Environment.new()
	world_environment.environment.background_mode = Environment.BG_COLOR
	world_environment.environment.background_color = summer_sky_color
	world_environment.environment.ambient_light_source = Environment.AMBIENT_SOURCE_COLOR
	world_environment.environment.ambient_light_color = summer_sky_color.lightened(0.25)
	world_environment.environment.ambient_light_energy = 0.55 if environment_state.is_summer() else 0.45

func _daylight_height_factor(day_progress: float) -> float:
	var angle := day_progress * TAU - PI * 0.5
	return clamp((sin(angle) + 1.0) * 0.5, 0.0, 1.0)
