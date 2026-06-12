extends RefCounted

func run(t) -> void:
	var path := "res://scripts/player/PlayerSpellController.gd"
	t.assert_true(FileAccess.file_exists(path), "PlayerSpellController script exists")
	if not FileAccess.file_exists(path):
		return
	var Controller := load(path)
	t.assert_true(Controller.can_instantiate(), "PlayerSpellController can instantiate")
	if not Controller.can_instantiate():
		return
	_test_projectile_spell_spawns_projectile(t, Controller)
	_test_non_projectile_spell_uses_cooldown_without_projectile(t, Controller)
	_test_unknown_spell_does_not_cast(t, Controller)
	_test_cast_spell_from_node_uses_emitter_transform(t, Controller)
	_test_projectile_hits_area_target(t)

func _test_projectile_spell_spawns_projectile(t, Controller: Script) -> void:
	var root := _make_tree_root()
	var controller = Controller.new()
	root.add_child(controller)
	t.assert_true(controller.cast_spell("spirit_bolt", Vector3(1, 2, 3), Vector3.FORWARD), "spirit_bolt casts")
	t.assert_equal(controller.get_spawned_projectile_count(), 1, "spirit_bolt spawns one projectile")
	t.assert_true(controller.last_spawned_projectile != null, "last spawned projectile is tracked")
	if controller.last_spawned_projectile != null:
		t.assert_equal(controller.last_spawned_projectile.spell_id, "spirit_bolt", "projectile keeps spell id")
		t.assert_equal(controller.last_spawned_projectile.position, Vector3(1, 2, 3), "projectile starts at requested origin")
	t.assert_true(not controller.cast_spell("spirit_bolt", Vector3.ZERO, Vector3.FORWARD), "cooldown blocks immediate repeat")
	root.free()

func _test_non_projectile_spell_uses_cooldown_without_projectile(t, Controller: Script) -> void:
	var root := _make_tree_root()
	var controller = Controller.new()
	root.add_child(controller)
	t.assert_true(controller.cast_spell("guard_charm", Vector3.ZERO, Vector3.FORWARD), "guard_charm casts")
	t.assert_equal(controller.last_cast_spell_id, "guard_charm", "guard_charm records last cast")
	t.assert_equal(controller.get_spawned_projectile_count(), 0, "guard_charm does not spawn projectile")
	t.assert_true(not controller.cast_spell("guard_charm", Vector3.ZERO, Vector3.FORWARD), "guard_charm cooldown blocks repeat")
	root.free()

func _test_unknown_spell_does_not_cast(t, Controller: Script) -> void:
	var root := _make_tree_root()
	var controller = Controller.new()
	root.add_child(controller)
	t.assert_true(not controller.cast_spell("unknown_spell", Vector3.ZERO, Vector3.FORWARD), "unknown spell does not cast")
	t.assert_equal(controller.last_cast_spell_id, "", "unknown spell does not record last cast")
	t.assert_equal(controller.get_spawned_projectile_count(), 0, "unknown spell does not spawn projectile")
	root.free()

func _test_cast_spell_from_node_uses_emitter_transform(t, Controller: Script) -> void:
	var root := _make_tree_root()
	var controller = Controller.new()
	var emitter := Node3D.new()
	root.add_child(controller)
	root.add_child(emitter)
	emitter.position = Vector3(4, 5, 6)
	emitter.transform = emitter.transform.looking_at(Vector3(4, 5, 5), Vector3.UP)
	t.assert_true(controller.cast_spell_from_node("seal_break", emitter), "seal_break casts from emitter")
	t.assert_equal(controller.get_spawned_projectile_count(), 1, "seal_break spawns projectile")
	t.assert_equal(controller.last_spawned_projectile.position, emitter.position, "projectile uses emitter position")
	root.free()

func _test_projectile_hits_area_target(t) -> void:
	var projectile_scene := load("res://scenes/spells/SpellProjectile.tscn")
	t.assert_true(projectile_scene is PackedScene, "SpellProjectile scene loads")
	if not projectile_scene is PackedScene:
		return
	var projectile = projectile_scene.instantiate()
	var target := AreaSpellTarget.new()
	projectile.spell_id = "seal_break"
	projectile._on_area_entered(target)
	t.assert_equal(target.received_spell_id, "seal_break", "projectile can deliver spell to Area3D targets")
	t.assert_true(projectile.is_queued_for_deletion(), "projectile queues free after area hit")
	projectile.free()
	target.free()

class AreaSpellTarget:
	extends Area3D

	var received_spell_id := ""

	func receive_spell(spell_id: String) -> void:
		received_spell_id = spell_id

func _make_tree_root() -> Node3D:
	var root := Node3D.new()
	return root
