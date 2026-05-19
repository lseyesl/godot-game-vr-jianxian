extends RefCounted

func run(t) -> void:
	var path := "res://scripts/core/ComfortSettings.gd"
	t.assert_true(ResourceLoader.exists(path), "ComfortSettings script exists")
	if not ResourceLoader.exists(path):
		return
	var ComfortSettings := load(path)
	t.assert_true(ComfortSettings != null, "ComfortSettings script exists")
	if ComfortSettings == null:
		return
	var settings = ComfortSettings.new()
	t.assert_equal(settings.movement_mode, "comfort", "default movement mode is comfort")
	t.assert_equal(settings.turn_mode, "snap", "default turn mode is snap")
	t.assert_true(settings.flight_vignette_enabled, "flight vignette is enabled by default")
	settings.apply_mode("immersive")
	t.assert_equal(settings.movement_mode, "immersive", "immersive mode changes movement mode")
	t.assert_equal(settings.turn_mode, "smooth", "immersive mode changes turn mode")
	t.assert_true(settings.flight_speed_limit_mps > 0.0, "speed limit remains positive")
	settings.apply_mode("unknown")
	t.assert_equal(settings.movement_mode, "comfort", "unknown mode falls back to comfort")
