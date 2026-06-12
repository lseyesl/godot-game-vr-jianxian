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
	_test_player_death_emits_defeat_signal(t, HealthComponent)

func _test_player_death_emits_defeat_signal(t, HealthComponent: Script) -> void:
	var event_bus_path := "res://scripts/autoload/EventBus.gd"
	t.assert_true(FileAccess.file_exists(event_bus_path), "EventBus script exists for defeat test")
	if not FileAccess.file_exists(event_bus_path):
		return
	var EventBusScript := load(event_bus_path)
	var root := Node.new()
	t.root.add_child(root)
	var event_bus = EventBusScript.new()
	event_bus.name = "EventBus"
	root.add_child(event_bus)
	var health = HealthComponent.new()
	health.target_id = "player"
	health.max_health = 1
	health.current_health = 1
	root.add_child(health)
	var defeat_sources: Array[String] = []
	t.assert_true(event_bus.has_signal("player_defeated"), "EventBus exposes player_defeated")
	if event_bus.has_signal("player_defeated"):
		event_bus.player_defeated.connect(func(source_id: String) -> void:
			defeat_sources.append(source_id)
		)
	health.apply_damage(1, "lesser_demon")
	t.assert_equal(defeat_sources.size(), 1, "player health reaching zero emits one defeat signal")
	if defeat_sources.size() >= 1:
		t.assert_equal(defeat_sources[0], "lesser_demon", "player defeat records damage source")
	health.apply_damage(1, "lesser_demon")
	t.assert_equal(defeat_sources.size(), 1, "dead player does not emit duplicate defeat signals")
	root.free()
