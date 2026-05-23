extends RefCounted

func run(t) -> void:
	var scene := preload("res://scenes/main/Main.tscn").instantiate()
	t.assert_true(scene != null, "Main scene instantiates")
	if scene == null:
		return

	var ground := scene.get_node_or_null("Ground")
	t.assert_true(ground != null, "Main scene has direct Ground child")
	if ground != null:
		t.assert_true(ground is StaticBody3D, "Ground is StaticBody3D")
		t.assert_true(ground.get_node_or_null("MeshInstance3D") != null, "Ground has MeshInstance3D child")
		t.assert_true(ground.get_node_or_null("CollisionShape3D") != null, "Ground has CollisionShape3D child")

	scene.free()
