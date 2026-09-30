extends RefCounted

const EnvironmentStateScript := preload("res://scripts/core/EnvironmentState.gd")

func run(t) -> void:
	var path := "res://scripts/world/EnvironmentController.gd"
	t.assert_true(FileAccess.file_exists(path), "EnvironmentController script exists")
	if not FileAccess.file_exists(path):
		return
	var EnvironmentControllerScript := load(path)
	t.assert_true(EnvironmentControllerScript.can_instantiate(), "EnvironmentController can instantiate")
	if not EnvironmentControllerScript.can_instantiate():
		return
	_test_applies_late_afternoon_summer_light(t, EnvironmentControllerScript)
	_test_process_advances_dynamic_time(t, EnvironmentControllerScript)
	_test_main_scene_wires_environment_controller(t)

func _test_applies_late_afternoon_summer_light(t, EnvironmentControllerScript) -> void:
	var controller = EnvironmentControllerScript.new()
	var light := DirectionalLight3D.new()
	light.name = "SunLight"
	controller.add_child(light)
	controller.directional_light_path = NodePath("SunLight")
	controller.environment_state = EnvironmentStateScript.new()
	controller.apply_environment()
	t.assert_true(light.light_energy > 1.0, "summer afternoon sun uses bright energy")
	t.assert_true(light.light_color.r > light.light_color.b, "late afternoon sun is warmer than blue")
	t.assert_true(light.rotation_degrees.x < 0.0, "sun points downward in afternoon")
	t.assert_true(light.rotation_degrees.y > 0.0, "16:00 sun is westward-positive yaw")
	controller.free()

func _test_process_advances_dynamic_time(t, EnvironmentControllerScript) -> void:
	var controller = EnvironmentControllerScript.new()
	var state = EnvironmentStateScript.new()
	state.time_scale = 1.0
	state.set_time_from_clock(16, 0)
	controller.environment_state = state
	controller._process(0.5)
	t.assert_equal(state.time_of_day_hours, 16.5, "controller process advances dynamic time state")
	controller.free()

func _test_main_scene_wires_environment_controller(t) -> void:
	var file := FileAccess.open("res://scenes/main/Main.tscn", FileAccess.READ)
	t.assert_true(file != null, "Main scene opens")
	if file == null:
		return
	var scene_text := file.get_as_text()
	t.assert_true(scene_text.contains("res://scripts/world/EnvironmentController.gd"), "Main scene references EnvironmentController")
	t.assert_true(scene_text.contains("directional_light_path = NodePath(\"../DirectionalLight3D\")"), "EnvironmentController targets DirectionalLight3D")
	t.assert_true(scene_text.contains("world_environment_path = NodePath(\"../WorldEnvironment\")"), "EnvironmentController targets WorldEnvironment")
