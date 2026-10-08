extends RefCounted

const Player = preload("res://scripts/player/DesktopDebugPlayer.gd")
const Health = preload("res://scripts/combat/HealthComponent.gd")
const Controller = preload("res://scripts/player/PlayerSpellController.gd")

func run(t) -> void:
	var player := Player.new()
	var health := Health.new()
	health.name = "HealthComponent"
	health.max_health = 5
	health.current_health = 5
	player.add_child(health)
	var controller := Controller.new()
	controller.name = "PlayerSpellController"
	player.add_child(controller)
	t.assert_true(controller.cast_spell("guard_charm", Vector3.ZERO, Vector3.FORWARD), "guard can cast")
	t.assert_equal(player.receive_damage(2, "demon"), 5, "active guard prevents damage")
	t.assert_true(not controller.cast_spell("guard_charm", Vector3.ZERO, Vector3.FORWARD), "guard obeys cooldown")
	controller.tick_cooldowns(3.1)
	t.assert_equal(player.receive_damage(2, "demon"), 3, "expired guard allows damage")
	t.assert_true(not controller.cast_spell("guard_charm", Vector3.ZERO, Vector3.FORWARD), "guard expiration does not reset cooldown")
	controller.tick_cooldowns(1)
	t.assert_true(controller.cast_spell("guard_charm", Vector3.ZERO, Vector3.FORWARD), "guard becomes available again")
	for action in ["flight_toggle", "flight_ascend", "flight_descend"]:
		t.assert_true(InputMap.has_action(action), "flight input exists: " + action)
	player.free()
