extends RefCounted

func run(t) -> void:
	var path := "res://scripts/items/FlyingSword.gd"
	t.assert_true(FileAccess.file_exists(path), "FlyingSword script exists")
	if not FileAccess.file_exists(path):
		return
	var FlyingSword := load(path)
	t.assert_true(FlyingSword.can_instantiate(), "FlyingSword can instantiate")
	if not FlyingSword.can_instantiate():
		return
	var sword = FlyingSword.new()
	t.assert_true(not sword.unlocked, "sword starts locked")
	t.assert_true(not sword.flight_enabled, "flight starts disabled")
	sword.collect()
	t.assert_true(sword.unlocked, "collect unlocks sword")
	t.assert_true(sword.flight_enabled, "collect enables flight")
	sword.set_flight_enabled(false)
	sword.collect()
	t.assert_true(not sword.flight_enabled, "collecting an already unlocked sword does not re-enable flight")
	t.assert_equal(sword.hover_height_m, 0.8, "sword hover height is stable")
	sword.free()
