extends RefCounted

func run(t) -> void:
	var path := "res://scripts/combat/HealthComponent.gd"
	t.assert_true(FileAccess.file_exists(path), "HealthComponent script exists")
	if not FileAccess.file_exists(path):
		return
	var HealthComponent := load(path)
	t.assert_true(HealthComponent.can_instantiate(), "HealthComponent can instantiate")
	if not HealthComponent.can_instantiate():
		return
	var health = HealthComponent.new()
	health.max_health = 5
	health.minimum_health = 0
	health.reset()
	t.assert_equal(health.current_health, 5, "health resets to max")
	t.assert_true(health.is_alive(), "health starts alive")
	t.assert_equal(health.apply_damage(2, "test"), 3, "damage lowers health")
	t.assert_equal(health.current_health, 3, "current health tracks damage")
	t.assert_equal(health.apply_damage(99, "test"), 0, "damage clamps at minimum")
	t.assert_true(not health.is_alive(), "zero health is not alive")
	t.assert_equal(health.heal(2), 2, "heal restores from minimum")
	t.assert_true(health.is_alive(), "positive health is alive")
	health.free()
