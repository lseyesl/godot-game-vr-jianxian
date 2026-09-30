extends RefCounted

func run(t) -> void:
	var scene_path := "res://scenes/enemies/LesserDemon.tscn"
	t.assert_true(FileAccess.file_exists(scene_path), "LesserDemon scene exists")
	if not FileAccess.file_exists(scene_path):
		return
	var packed_scene := load(scene_path)
	t.assert_true(packed_scene is PackedScene, "LesserDemon scene loads")
	if not packed_scene is PackedScene:
		return
	var scene = packed_scene.instantiate()
	t.assert_true(scene != null, "LesserDemon scene instantiates")
	if scene == null:
		return
	t.assert_true(scene.get_node_or_null("HealthComponent") != null, "LesserDemon has HealthComponent")
	t.assert_true(scene.get_node_or_null("BehaviorTree") != null, "LesserDemon has BeehaveTree")
	t.assert_true(scene.get_node_or_null("BehaviorTree/RootSelector/DefeatedBranch") != null, "LesserDemon has defeated branch")
	t.assert_true(scene.get_node_or_null("BehaviorTree/RootSelector/AttackBranch") != null, "LesserDemon has attack branch")
	t.assert_true(scene.get_node_or_null("BehaviorTree/RootSelector/ChaseBranch") != null, "LesserDemon has chase branch")
	t.assert_true(scene.get_node_or_null("BehaviorTree/RootSelector/IdleBranch") != null, "LesserDemon has idle branch")
	t.assert_true(scene.get_node_or_null("Visual") is MeshInstance3D, "LesserDemon has visible mesh")
	t.assert_true(scene.get_node_or_null("CollisionShape3D") is CollisionShape3D, "LesserDemon has collision shape")
	scene.free()
