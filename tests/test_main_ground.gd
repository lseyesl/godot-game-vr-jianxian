extends RefCounted

func run(t) -> void:
	var scene := preload("res://scenes/main/Main.tscn").instantiate()
	t.assert_true(scene != null, "Main scene instantiates")
	if scene == null:
		return

	var container := scene.get_node_or_null("TerrainContainer")
	t.assert_true(container != null, "Main scene has TerrainContainer child")
	if container != null:
		t.assert_true(container.get_node_or_null("Terrain3D") != null, "TerrainContainer has Terrain3D")
		t.assert_true(container.get_node_or_null("WorldBoundary") != null, "TerrainContainer has WorldBoundary")
		t.assert_true(container.get_node_or_null("TownGround") == null, "TerrainContainer does not instance old TownGround")
		t.assert_true(container.get_node_or_null("SuburbGround") == null, "TerrainContainer does not instance old SuburbGround")
		t.assert_true(container.get_node_or_null("MountainGround") == null, "TerrainContainer does not instance old MountainGround")

	var concept_layout := scene.get_node_or_null("ConceptLayout")
	t.assert_true(concept_layout != null, "Main scene has ConceptLayout")
	if concept_layout != null:
		t.assert_true(concept_layout.get_node_or_null("TownWallPlaceholders") != null, "ConceptLayout has town wall placeholder group")
		t.assert_true(concept_layout.get_node_or_null("RiverbankAndBedPlaceholders") != null, "ConceptLayout has riverbank and bed placeholder group")
		t.assert_true(concept_layout.get_node_or_null("MountainBackdropPlaceholders") != null, "ConceptLayout has mountain backdrop placeholder group")

	scene.free()
