extends RefCounted

func run(t) -> void:
	var scene := preload("res://scenes/main/Main.tscn").instantiate()
	t.assert_true(scene != null, "Main scene instantiates")
	if scene == null:
		return

	var container := scene.get_node_or_null("TerrainContainer")
	t.assert_true(container != null, "Main scene has TerrainContainer child")
	if container != null:
		t.assert_true(container.get_node_or_null("TownGround") != null, "TerrainContainer has TownGround")
		t.assert_true(container.get_node_or_null("SuburbGround") != null, "TerrainContainer has SuburbGround")
		t.assert_true(container.get_node_or_null("MountainGround") != null, "TerrainContainer has MountainGround")
		t.assert_true(container.get_node_or_null("WorldBoundary") != null, "TerrainContainer has WorldBoundary")

	scene.free()
