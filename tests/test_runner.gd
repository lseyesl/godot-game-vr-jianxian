extends SceneTree

var assertions := 0
var failures: Array[String] = []

func _init() -> void:
	var test_paths := [
		"res://tests/test_comfort_settings.gd",
		"res://tests/test_environment_state.gd",
		"res://tests/test_environment_controller.gd",
		"res://tests/test_quest_state.gd",
		"res://tests/test_dialogue.gd",
		"res://tests/test_spell_caster.gd",
		"res://tests/test_seal_encounter.gd",
		"res://tests/test_flying_sword.gd",
		"res://tests/test_player_mode.gd",
		"res://tests/test_xr_player.gd",
		"res://tests/test_scene_lod_group.gd",
		"res://tests/test_model_prefabs.gd",
		"res://tests/test_main_ground.gd",
		"res://tests/test_town_showcase.gd",
	]
	for path in test_paths:
		if FileAccess.file_exists(path):
			_run_test_script(path)
	if failures.is_empty():
		print("TESTS PASSED: %d assertions" % assertions)
		call_deferred("_finish", 0)
	else:
		for failure in failures:
			printerr(failure)
		printerr("TESTS FAILED: %d failure(s), %d assertion(s)" % [failures.size(), assertions])
		call_deferred("_finish", 1)

func _finish(exit_code: int) -> void:
	quit(exit_code)

func _run_test_script(path: String) -> void:
	var script := load(path)
	if script == null:
		fail(path, "failed to load test script")
		return
	if script is GDScript and not script.can_instantiate():
		fail(path, "test script cannot instantiate")
		return
	var instance: Object = script.new()
	if instance.has_method("run"):
		instance.run(self)
	else:
		fail(path, "missing run(test_runner) method")

func assert_true(value: bool, message: String) -> void:
	assertions += 1
	if not value:
		fail("assert_true", message)

func assert_equal(actual: Variant, expected: Variant, message: String) -> void:
	assertions += 1
	if actual != expected:
		fail("assert_equal", "%s | actual=%s expected=%s" % [message, str(actual), str(expected)])

func fail(source: String, message: String) -> void:
	failures.append("%s: %s" % [source, message])
