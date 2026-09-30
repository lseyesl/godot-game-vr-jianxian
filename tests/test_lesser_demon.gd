extends RefCounted

class MockTarget:
	extends Node3D
	var damage_received := 0
	var last_source_id := ""

	func receive_damage(amount: int, source_id: String = "") -> int:
		damage_received += amount
		last_source_id = source_id
		return damage_received

func run(t) -> void:
	var path := "res://scripts/enemies/LesserDemon.gd"
	t.assert_true(FileAccess.file_exists(path), "LesserDemon script exists")
	if not FileAccess.file_exists(path):
		return
	var LesserDemon := load(path)
	t.assert_true(LesserDemon.can_instantiate(), "LesserDemon can instantiate")
	if not LesserDemon.can_instantiate():
		return
	_test_spell_damage(t, LesserDemon)
	_test_target_ranges(t, LesserDemon)
	_test_attack_cooldown(t, LesserDemon)

func _test_spell_damage(t, LesserDemon) -> void:
	var demon = _make_demon(LesserDemon)
	t.assert_equal(demon.get_spell_damage("spirit_bolt"), 1, "spirit bolt damages lesser demon")
	t.assert_equal(demon.get_spell_damage("seal_break"), 3, "seal break is lethal to lesser demon")
	t.assert_equal(demon.get_spell_damage("guard_charm"), 0, "guard charm does not damage lesser demon")
	demon.receive_spell("spirit_bolt")
	t.assert_equal(demon.get_health_component().current_health, 2, "spirit bolt reduces lesser demon health")
	demon.receive_spell("guard_charm")
	t.assert_equal(demon.get_health_component().current_health, 2, "guard charm leaves health unchanged")
	demon.receive_spell("seal_break")
	t.assert_true(demon.is_defeated(), "seal break defeats lesser demon")
	demon.free()

func _test_target_ranges(t, LesserDemon) -> void:
	var demon = _make_demon(LesserDemon)
	var target := MockTarget.new()
	target.position = Vector3(1.4, 0, 0)
	demon.set_target(target)
	t.assert_true(demon.has_target(), "lesser demon has explicit target")
	t.assert_true(demon.can_see_target(), "target inside sight range is visible")
	t.assert_true(demon.is_in_attack_range(), "target inside attack range is attackable")
	target.position = Vector3(4, 0, 0)
	t.assert_true(demon.can_see_target(), "target outside attack range but inside sight range is visible")
	t.assert_true(not demon.is_in_attack_range(), "target outside attack range is not attackable")
	target.position = Vector3(12, 0, 0)
	t.assert_true(not demon.can_see_target(), "target outside sight range is not visible")
	target.free()
	demon.free()

func _test_attack_cooldown(t, LesserDemon) -> void:
	var demon = _make_demon(LesserDemon)
	var target := MockTarget.new()
	target.position = Vector3(1, 0, 0)
	demon.set_target(target)
	t.assert_true(demon.try_attack_target(), "first attack succeeds")
	t.assert_equal(target.damage_received, 1, "attack damages target")
	t.assert_true(not demon.try_attack_target(), "cooldown blocks immediate second attack")
	demon.tick_attack_cooldown(2.0)
	t.assert_true(demon.try_attack_target(), "attack succeeds after cooldown")
	t.assert_equal(target.damage_received, 2, "second attack damages target")
	target.free()
	demon.free()

func _make_demon(LesserDemon):
	var demon = LesserDemon.new()
	var HealthComponentScript := load("res://scripts/combat/HealthComponent.gd")
	var health = HealthComponentScript.new()
	health.name = "HealthComponent"
	health.max_health = 3
	health.current_health = 3
	demon.add_child(health)
	return demon
