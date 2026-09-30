extends RefCounted

func run(t) -> void:
	var path := "res://scripts/core/EnvironmentState.gd"
	t.assert_true(FileAccess.file_exists(path), "EnvironmentState script exists")
	if not FileAccess.file_exists(path):
		return
	var EnvironmentStateScript := load(path)
	t.assert_true(EnvironmentStateScript.can_instantiate(), "EnvironmentState can instantiate")
	if not EnvironmentStateScript.can_instantiate():
		return
	_test_defaults_to_late_summer_afternoon(t, EnvironmentStateScript)
	_test_clock_setting_and_day_progress(t, EnvironmentStateScript)
	_test_time_advances_and_wraps(t, EnvironmentStateScript)

func _test_defaults_to_late_summer_afternoon(t, EnvironmentStateScript) -> void:
	var state = EnvironmentStateScript.new()
	t.assert_equal(state.time_of_day_hours, 16.0, "environment defaults to 16:00")
	t.assert_equal(state.season, "summer", "environment defaults to summer")
	t.assert_true(state.is_summer(), "summer helper reports true")
	t.assert_equal(state.time_scale, 0.0, "dynamic time system starts paused")

func _test_clock_setting_and_day_progress(t, EnvironmentStateScript) -> void:
	var state = EnvironmentStateScript.new()
	state.set_time_from_clock(6, 30)
	t.assert_equal(state.time_of_day_hours, 6.5, "clock setter stores fractional hour")
	t.assert_equal(state.normalized_day_progress(), 6.5 / 24.0, "day progress normalizes time")
	state.set_time_from_clock(28, 90)
	t.assert_equal(state.time_of_day_hours, 5.5, "clock setter wraps oversized time")

func _test_time_advances_and_wraps(t, EnvironmentStateScript) -> void:
	var state = EnvironmentStateScript.new()
	state.time_scale = 2.0
	state.set_time_from_clock(23, 0)
	state.advance_time(1.5)
	t.assert_equal(state.time_of_day_hours, 2.0, "advance_time wraps after 24 hours")
	state.time_scale = 0.0
	state.advance_time(10.0)
	t.assert_equal(state.time_of_day_hours, 2.0, "paused time scale does not advance")
